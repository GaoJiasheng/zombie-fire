#!/usr/bin/env python3
"""单一战力口径 4.0 的 Python 镜像与通关线求解器。

玩家仍只看到一个“战力”，但内部不再把输出与生存做几何平均。每关先离线生成
清群、Boss、防线三份容量合同；运行时按当前装备、永久技能等级与本关确定能拿到
的卡牌预算计算三条比值，最终只取最短板。4.0 将防线门槛改为同一战斗模拟器
估出的漏怪伤害与二星剩余血量边界，并只允许有限的清场速度修正：

    power = recommended_power * min(crowd_ratio, boss_ratio, line_ratio)

旧 required_t 继续作为战役节奏/推荐数字的校准输入，不再直接冒充玩家战力。

模型只存在于这里和 simulate_balance;GDScript 只查表映射。改任何一侧公式必须
同步另一侧,check_clear_requirements.py 会在 RC 中抓不同步。
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"

# --- GDScript 常量镜像(save_manager.gd) ---
POWER_SCALE_K = 11.0
POWER_SCALE_GAMMA = 1.0
OFFENSE_WEIGHT = 0.82
SURVIVAL_WEIGHT = 0.28
SKILL_THROUGHPUT_CAP = 13.5
SKILL_SCORE_EXPONENT = 0.5
AFFINITY_PIERCE_COVERAGE = 0.065
AFFINITY_CHAIN_COVERAGE = 0.09
AFFINITY_STATUS_THROUGHPUT = 0.28
AFFINITY_SLOW_SURVIVAL = 0.40
AFFINITY_SPLASH_RADIUS = 0.0001
AFFINITY_SHATTER_CYCLE = 6.0

# Runtime DPS -> static capacity calibration. The checked-in Godot benchmark
# measures the max free physical finale build against real colliders. These two
# conversion constants deliberately live in economy.power_ruler at runtime; the
# Python defaults keep tooling explicit if a legacy data file is inspected.
DEFAULT_BOSS_DPS_PER_CAPACITY = 207.20
DEFAULT_CROWD_DPS_PER_CAPACITY = 75.0
DEFAULT_BOSS_CLEAR_WINDOW = 180.0
DEFAULT_LINE_REQUIREMENT_FLOOR = 0.25
DEFAULT_LINE_EXPOSURE_CREDIT_MIN = 0.85
DEFAULT_LINE_EXPOSURE_CREDIT_MAX = 1.15
ARMOR_BREAK_EFFECTIVE_FACTOR = 0.94

# design/32 display-contract corridor. These bounds never feed battle damage,
# enemy HP, waves, economy pressure, or star thresholds.
PACE_CORRIDOR_MIN = 1.00
LATE_CORRIDOR_MIN = 0.95
CORRIDOR_MAX = 1.40
CORRIDOR_MARGIN = 0.02
OWNER_ANCHOR_RATIOS = {
    "level_080": 1.7558,
    "level_099": 1.1706,
}

# --- simulate_balance 模型常量镜像 ---
ARMOR_HP_MULT = 1.20      # 通关线求解与 S_ref 使用同一生存基线(典型护甲)
BOSS_LEAK = 0.12
NORMAL_LEAK = 0.05
GLOBAL_DMG_BASE = 10.0
BASE_WEAPON_DAMAGE = 28.0


def load_table(name: str):
    return json.loads((DATA / f"{name}.json").read_text(encoding="utf-8"))


# ---------------------------------------------------------------- GD 镜像:输出倍率 O

def weapon_effective_dps(weapon: dict) -> float:
    """save_manager.gd _weapon_effective_dps 的逐行镜像。"""
    if not weapon:
        return 4.0
    effective = float(weapon.get("base_atk_coef", 1.0)) * float(weapon.get("fire_rate", 4.0))
    sp = weapon.get("special", {}) or {}
    pellets = max(1, int(sp.get("pellets", 1)))
    if pellets > 1:
        effective *= 1.0 + (pellets - 1) * 0.62
    effective *= 1.0 + 0.18 * float(sp.get("pierce", 0))
    effective *= 1.0 + 0.36 * float(sp.get("chain", 0))
    if float(sp.get("splash", 0.0)) > 0.0 or float(sp.get("cloud", 0.0)) > 0.0:
        effective *= 1.28
    effective *= 1.0 + 0.65 * (float(sp.get("burn", 0.0)) + float(sp.get("burn_ratio", 0.0)) + float(sp.get("poison", 0.0)))
    oh = float(sp.get("overload_hits", 0.0))
    om = float(sp.get("overload_damage_mult", 1.0))
    if oh > 0.0 and om > 1.0:
        effective *= 1.0 + (om - 1.0) / oh
    cs = float(sp.get("combustion_max_stacks", 0.0))
    cm = float(sp.get("combustion_damage_mult", 1.0))
    if cs > 0.0 and cm > 1.0:
        effective *= 1.0 + (cm - 1.0) / cs
        effective *= 1.28
    bh = float(sp.get("brittle_hits", 0.0))
    sm = float(sp.get("shatter_damage_mult", 0.0))
    if bh > 0.0 and sm > 0.0:
        effective *= 1.0 + sm / bh
        effective *= 1.28
    jh = float(sp.get("judgment_hits", 0.0))
    jm = float(sp.get("judgment_damage_mult", 1.0))
    if jh > 0.0 and jm > 1.0:
        effective *= 1.0 + (jm - 1.0) / jh
    effective *= 1.0 + 0.22 * float(sp.get("judgment_armor_penetration", 0.0))
    effective *= 1.0 + 0.30 * float(sp.get("slow", 0.0))
    return effective


def char_atk_multiplier(character: dict, char_level: int) -> float:
    mult = float(character.get("base_atk", 100.0)) / 100.0 * float(character.get("fire_rate_mod", 1.0))
    mult *= 1.0 + float(character.get("atk_growth", 0.08)) * 0.45 * max(char_level - 1, 0)
    return mult


def weapon_dps_multiplier(weapon: dict, weapon_level: int) -> float:
    mult = max(weapon_effective_dps(weapon) / 4.0, 0.35)
    mult *= 1.0 + 0.08 * max(weapon_level - 1, 0)
    mult *= 1.0 + 0.025 * max(weapon_level - 1, 0)
    return mult


def active_skill_multiplier(character: dict, char_level: int, sig_level: int) -> float:
    active = character.get("active_skill", {}) or {}
    if not active:
        return 1.0
    cooldown = max(float(active.get("cooldown", 18.0)) * (1.0 - min(max(float(active.get("sig_level_cooldown_reduction", 0.0)) * sig_level, 0.0), 0.35)), 1.0)
    duration = float(active.get("duration", 6.0)) + float(active.get("sig_level_duration_bonus", 0.0)) * sig_level
    uptime = min(max(duration / cooldown, 0.0), 1.0)
    damage_mult = float(active.get("damage_mult", 1.0)) + float(active.get("sig_level_damage_bonus", 0.0)) * sig_level
    damage_mult *= 1.0 + float(character.get("atk_growth", 0.08)) * 0.52 * max(char_level - 1, 0)
    burst = damage_mult * float(active.get("barrage_fire_rate_mult", 1.0))
    return 1.0 + uptime * max(burst - 1.0, 0.0)




def growth_rank(level: float) -> int:
    if level >= 25:
        return 3
    if level >= 15:
        return 2
    if level >= 8:
        return 1
    return 0


def bullet_affinity_multiplier(character: dict, weapon: dict, char_level: float) -> float:
    affinity = character.get("bullet_affinity", {}) or {}
    if not affinity:
        return 1.0
    if str(weapon.get("element", "physical")) != str(affinity.get("element", character.get("element_focus", "physical"))):
        return 1.0
    rank = growth_rank(char_level)
    direct = 1.0 + max(
        float(affinity.get("damage_bonus", 0.0))
        + float(affinity.get("rank_damage_bonus", 0.0)) * rank,
        0.0,
    )
    pierce = int(affinity.get("pierce_bonus", 0))
    chain = int(affinity.get("chain_bonus", 0))
    if rank >= 2:
        pierce += int(affinity.get("rank_pierce_bonus", 0))
        chain += int(affinity.get("rank_chain_bonus", 0))
    chain_retention = min(max(float(affinity.get("chain_target_falloff", 1.0)), 0.72), 1.0)
    coverage = 1.0
    coverage += max(pierce, 0) * AFFINITY_PIERCE_COVERAGE
    coverage += max(chain, 0) * AFFINITY_CHAIN_COVERAGE * chain_retention
    status = 1.0 + max(float(affinity.get("status_bonus", 0.0)), 0.0) * AFFINITY_STATUS_THROUGHPUT
    splash_radius = max(
        float(affinity.get("splash_bonus", 0.0))
        + float(affinity.get("rank_splash_bonus", 0.0)) * rank,
        0.0,
    )
    splash = 1.0 + splash_radius * AFFINITY_SPLASH_RADIUS
    shatter_strength = 0.0
    if "shatter_bonus" in affinity:
        shatter_strength = max(float(affinity.get("shatter_bonus", 0.0)) + 0.04 * rank, 0.0)
    shatter = 1.0 + shatter_strength * AFFINITY_SHATTER_CYCLE
    overflow_window = max(int(affinity.get("chain_overflow_reference", 0)) + max(chain, 0), 0)
    overflow = 1.0 + max(float(affinity.get("chain_overflow_damage_bonus", 0.0)), 0.0) * overflow_window
    return max(direct * coverage * status * splash * shatter * overflow, 1.0)


def legacy_bullet_affinity_multiplier(character: dict, weapon: dict) -> float:
    affinity = character.get("bullet_affinity", {}) or {}
    if not affinity:
        return 1.0
    if str(weapon.get("element", "physical")) != str(affinity.get("element", character.get("element_focus", "physical"))):
        return 1.0
    return 1.0 + max(float(affinity.get("damage_bonus", 0.0)), 0.0)


def bullet_affinity_survival_multiplier(character: dict, weapon: dict, char_level: float) -> float:
    affinity = character.get("bullet_affinity", {}) or {}
    if not affinity:
        return 1.0
    if str(weapon.get("element", "physical")) != str(affinity.get("element", character.get("element_focus", "physical"))):
        return 1.0
    rank = growth_rank(char_level)
    slow = max(
        float(affinity.get("slow_bonus", 0.0))
        + float(affinity.get("rank_slow_bonus", 0.0)) * rank,
        0.0,
    )
    return 1.0 + slow * AFFINITY_SLOW_SURVIVAL


def offense_stat_factor(stat: str, value: float) -> float:
    if stat in ("damage_mult", "fire_rate_mult", "element_damage_mult"):
        return 1.0 + max(value, 0.0)
    if stat == "crit_rate":
        return 1.0 + max(value, 0.0) * 0.85
    if stat == "pierce_bonus":
        return 1.0 + max(value, 0.0) * 0.065
    if stat == "chain_bonus":
        return 1.0 + max(value, 0.0) * 0.09
    if stat == "chain_retention":
        return 1.0 + max(value, 0.0) * 0.2
    if stat == "overload_efficiency":
        return 1.0 + max(value, 0.0) * 0.3
    return 1.0


def offense_multiplier(character: dict, weapon: dict, char_level: int, weapon_level: int,
                       sig_level: int = 0, chip: dict | None = None, chip_level: int = 1,
                       pet: dict | None = None, pet_level: int = 1) -> float:
    mult = char_atk_multiplier(character, char_level) * weapon_dps_multiplier(weapon, weapon_level)
    mult *= bullet_affinity_multiplier(character, weapon, char_level)
    if chip:
        offset = max(chip_level - 1, 0)
        value = float(chip.get("value", 0.0)) + float(chip.get("level_value_growth", 0.0)) * offset
        mult *= offense_stat_factor(str(chip.get("stat", "")), value)
        secondary = chip.get("secondary_stats", {}) or {}
        secondary_growth = chip.get("secondary_level_growth", {}) or {}
        for stat, base in secondary.items():
            sec_value = float(base) + float(secondary_growth.get(stat, 0.0)) * offset
            mult *= offense_stat_factor(str(stat), sec_value)
    if pet:
        base_map = pet.get("stat_bonus", {}) or {}
        growth_map = pet.get("level_stat_growth", {}) or {}
        for stat, base in base_map.items():
            value = float(base) + float(growth_map.get(stat, 0.0)) * max(pet_level - 1, 0)
            mult *= offense_stat_factor(str(stat), value)
        pet_damage = float(pet.get("damage", 0.0))
        if pet_damage > 0.0:
            pet_dps = pet_damage * (1.0 + float(pet.get("level_damage_growth", 0.0)) * max(pet_level - 1, 0)) * float(pet.get("fire_rate", 1.0))
            main_output = 40.0 * char_atk_multiplier(character, char_level) * weapon_dps_multiplier(weapon, weapon_level)
            mult *= 1.0 + pet_dps / max(main_output, 1.0)
        mult *= pet_skill_offense_multiplier(pet, pet_level)
    mult *= active_skill_multiplier(character, char_level, sig_level)
    return max(mult, 0.05)


def pet_skill_offense_multiplier(pet: dict, pet_level: int) -> float:
    skill = pet.get("pet_skill", {}) or {}
    offset = max(pet_level - 1, 0)
    kind = str(skill.get("kind", ""))
    if kind == "overclock":
        duration = float(skill.get("duration", 0.0)) + float(skill.get("level_duration_growth", 0.0)) * offset
        cooldown = max(1.0, float(skill.get("cooldown", 12.0)))
        fire_rate = float(skill.get("fire_rate_mult", 1.0)) + float(skill.get("level_fire_rate_growth", 0.0)) * offset
        damage = float(skill.get("damage_mult", 1.0)) + float(skill.get("level_damage_mult_growth", 0.0)) * offset
        return 1.0 + max(fire_rate * damage - 1.0, 0.0) * min(max(duration / cooldown, 0.0), 1.0)
    if kind == "golden_mark":
        duration = float(skill.get("mark_duration", 0.0)) + float(skill.get("level_mark_duration_growth", 0.0)) * offset
        cooldown = max(1.0, float(skill.get("cooldown", 12.0)))
        amp = float(skill.get("mark_damage_amp", 0.0)) + float(skill.get("level_mark_amp_growth", 0.0)) * offset
        return 1.0 + max(amp, 0.0) * min(max(duration / cooldown, 0.0), 1.0)
    if kind in ("area_blast", "multi_strike"):
        cooldown = max(1.0, float(skill.get("cooldown", 12.0)))
        damage = float(skill.get("damage_mult", 1.0)) + float(skill.get("level_damage_mult_growth", 0.0)) * offset
        return 1.0 + min(max(damage / cooldown, 0.0), 0.5) * 0.5
    return 1.0


def survival_stat_factor(stat: str, value: float) -> float:
    if stat == "base_hp_mult":
        return 1.0 + max(value, 0.0)
    if stat == "breach_damage_reduction":
        return 1.0 / max(1.0 - min(max(value, 0.0), 0.65), 0.35)
    if stat == "slow_strength_mult":
        return 1.0 + max(value, 0.0) * 0.20
    return 1.0


def survival_multiplier(character: dict | None = None, char_level: int = 1,
                        weapon: dict | None = None,
                        armor: dict | None = None, armor_level: int = 1,
                        chip: dict | None = None, chip_level: int = 1,
                        pet: dict | None = None, pet_level: int = 1) -> float:
    mult = 1.0
    if character:
        mult *= max(float(character.get("base_hp", 100.0)) / 100.0, 0.5)
        mult *= 1.0 + float(character.get("hp_growth", 0.06)) * 0.45 * max(char_level - 1, 0)
        if weapon:
            mult *= bullet_affinity_survival_multiplier(character, weapon, char_level)
    if armor:
        mult *= max(float(armor.get("hp_mult", 1.0)), 0.5)
        mult *= 1.0 + float(armor.get("level_hp_growth", 0.0)) * max(armor_level - 1, 0)
        mult *= 1.0 + 0.10 * float(armor.get("breach_shield", 0))
        if float(armor.get("counter_damage_mult", 0.0)) > 0.0:
            mult *= 1.10
    if chip:
        value = float(chip.get("value", 0.0)) + float(chip.get("level_value_growth", 0.0)) * max(chip_level - 1, 0)
        mult *= survival_stat_factor(str(chip.get("stat", "")), value)
    if pet:
        base_map = pet.get("stat_bonus", {}) or {}
        growth_map = pet.get("level_stat_growth", {}) or {}
        for stat, base in base_map.items():
            value = float(base) + float(growth_map.get(stat, 0.0)) * max(pet_level - 1, 0)
            mult *= survival_stat_factor(str(stat), value)
        mult *= pet_repair_survival_multiplier(pet, pet_level)
    return max(mult, 0.5)


def pet_repair_survival_multiplier(pet: dict, pet_level: int) -> float:
    offset = max(pet_level - 1, 0)
    mult = 1.0
    if str(pet.get("role", "")) == "repair":
        wave_ratio = float(pet.get("heal_per_wave_ratio", 0.0)) + float(pet.get("level_wave_heal_ratio_growth", 0.0)) * offset
        repair_ratio = float(pet.get("repair_ratio", 0.0)) + float(pet.get("level_repair_ratio_growth", 0.0)) * offset
        emergency = float(pet.get("emergency_heal_ratio", 0.0)) + float(pet.get("level_emergency_heal_growth", 0.0)) * offset
        interval = max(1.0, float(pet.get("repair_interval", 18.0)))
        mult *= 1.0 + min(max(wave_ratio * 4.0 + repair_ratio * (60.0 / interval) + emergency, 0.0), 1.5)
    skill = pet.get("pet_skill", {}) or {}
    if str(skill.get("kind", "")) == "golden_mark":
        repair = float(skill.get("repair_ratio", 0.0)) + float(skill.get("level_repair_growth", 0.0)) * offset
        cooldown = max(1.0, float(skill.get("cooldown", 12.0)))
        mult *= 1.0 + min(max(repair * (60.0 / cooldown), 0.0), 0.75)
    return mult


def core_power(offense: float, survival: float) -> float:
    combined = (offense ** OFFENSE_WEIGHT) * (survival ** SURVIVAL_WEIGHT)
    return max(POWER_SCALE_K * (combined ** POWER_SCALE_GAMMA), 1.0)


def skill_effect_for_level(skill: dict, level: int) -> dict:
    chosen: dict = {}
    for entry in skill.get("levels", []):
        if int(entry.get("lv", 0)) <= level:
            chosen = entry.get("effect", {}) or {}
    return chosen


def skill_max_level(skill: dict) -> int:
    return max([int(entry.get("lv", 1)) for entry in skill.get("levels", [])] or [1])


def slow_caps(economy: dict) -> tuple[float, float]:
    pacing = economy.get("boss_pacing", {}) or {}
    mob = min(max(float(pacing.get("mob_slow_cap", 0.80)), 0.0), 0.95)
    boss = min(max(float(pacing.get("boss_slow_cap", 0.40)), 0.0), 0.95)
    return mob, boss


def weighted_slow_amount(slow: float, boss_share: float, economy: dict) -> float:
    mob_cap, boss_cap = slow_caps(economy)
    boss_weight = min(max(float(boss_share), 0.0), 1.0)
    mob_weight = 1.0 - boss_weight
    return (
        mob_weight * min(max(slow, 0.0), mob_cap)
        + boss_weight * min(max(slow, 0.0), boss_cap)
    )


def skill_capacity_profile(run_skill_levels: dict[str, int], skills: dict,
                           economy: dict | None = None,
                           boss_share: float = 0.0) -> dict[str, float]:
    """Return independent crowd, single-target and line capacity multipliers."""
    damage_add = fire_rate_add = crit_add = crit_damage_add = 0.0
    homing = burn = poison = slow = barrier_hp = armor_penetration = 0.0
    multishot_lane_damage_bonus = 0.0
    extra_projectiles = pierce = split = chain = 0
    split_falloff = 0.55
    for skill_id, level in run_skill_levels.items():
        effect = skill_effect_for_level(skills.get(skill_id, {}), int(level))
        damage_add += float(effect.get("dmg_mult", 0.0))
        fire_rate_add += float(effect.get("fire_rate_mult", 0.0))
        crit_add += float(effect.get("crit_add", 0.0))
        crit_damage_add += float(effect.get("crit_dmg", 0.0))
        extra_projectiles = max(extra_projectiles, int(effect.get("extra_projectiles", 0)))
        multishot_lane_damage_bonus = max(
            multishot_lane_damage_bonus,
            float(effect.get("lane_damage_bonus", 0.0)),
        )
        pierce += int(effect.get("pierce", 0))
        split = max(split, int(effect.get("split", 0)))
        if "falloff" in effect:
            split_falloff = float(effect["falloff"])
        chain += int(effect.get("chain", 0))
        homing += float(effect.get("homing", 0.0))
        burn += float(effect.get("burn", 0.0))
        poison += float(effect.get("poison", 0.0))
        slow += float(effect.get("slow", 0.0))
        barrier_hp += float(effect.get("base_hp_mult", 0.0))
        armor_penetration += float(effect.get("armor_penetration", 0.0))

    direct = max(1.0, 1.0 + damage_add)
    cadence = max(1.0, 1.0 + fire_rate_add)
    base_crit = 1.0 + 0.08 * 0.85
    upgraded_crit = 1.0 + min(max(0.08 + crit_add, 0.0), 0.85) * (0.85 + crit_damage_add)
    crit = max(1.0, upgraded_crit / base_crit)
    lane_count = min(max(1 + extra_projectiles, 1), 5)
    lane_damage = min(
        (1.0, 1.0, 0.85, 0.80, 0.75, 0.70)[lane_count]
        + multishot_lane_damage_bonus,
        1.0,
    )
    lane = 1.0 + max(lane_count * lane_damage - 1.0, 0.0) * 0.55
    secondary = pierce * 0.065 + split * min(max(split_falloff, 0.0), 1.0) * 0.11
    secondary += chain * 0.09 + homing * 0.03
    coverage = 1.0 + min(1.75, secondary)
    status = 1.0 + burn * 0.28 + poison * 0.32
    penetration = 1.0 + min(max(armor_penetration, 0.0), 0.95) * 0.22
    common = direct * cadence * crit * status * penetration
    crowd = common * lane * coverage
    # Extra lanes and coverage can overlap a large target, but not at their
    # saturated-crowd value. This mirrors the measured boss/crowd separation.
    boss_lane = 1.0 + max(lane_count * lane_damage - 1.0, 0.0) * 0.10
    boss_coverage = 1.0 + min(0.35, pierce * 0.025 + homing * 0.01)
    boss = common * boss_lane * boss_coverage
    # Barrier is literal extra base HP. Slow extends the approach/attack window;
    # cap it before inversion so a control card can never imply immortality.
    effective_slow = weighted_slow_amount(slow, boss_share, economy or {})
    line = (1.0 + max(barrier_hp, 0.0)) / (1.0 - effective_slow)
    return {
        "crowd": max(crowd, 1.0),
        "boss": max(boss, 1.0),
        "line": max(line, 1.0),
    }


def combat_skill_effect_multiplier(run_skill_levels: dict[str, int], skills: dict) -> float:
    """Legacy scalar kept for compatibility; never used as the final ruler."""
    profile = skill_capacity_profile(run_skill_levels, skills)
    offense = profile["crowd"]
    survival = profile["line"]
    combined = 1.0 + max(offense - 1.0, 0.0) * OFFENSE_WEIGHT
    combined += max(survival - 1.0, 0.0) * SURVIVAL_WEIGHT
    return min(max(combined, 1.0), SKILL_THROUGHPUT_CAP)


def _projection_score(levels: dict[str, int], skills: dict) -> float:
    profile = skill_capacity_profile(levels, skills)
    # A normal deterministic draft values both the crowded waves and the boss.
    # Defence is counted only when a level explicitly guarantees its offer.
    import math
    return math.log(profile["crowd"]) * 0.70 + math.log(profile["boss"]) * 0.30


def _conservative_guaranteed_skill(skill_ids: list[str], base_skill_levels: dict[str, int],
                                   skills: dict, economy: dict,
                                   boss_share: float) -> str:
    candidates: list[tuple[float, str]] = []
    for skill_id in skill_ids:
        row = skills.get(skill_id, {})
        if not row:
            continue
        level = min(max(int(base_skill_levels.get(skill_id, 0)), 1), skill_max_level(row))
        line = skill_capacity_profile(
            {skill_id: level}, skills, economy, boss_share)["line"]
        candidates.append((line, skill_id))
    return min(candidates)[1] if candidates else ""


def projected_skill_levels(card_picks: int, weakness: str, weapon_id: str,
                           base_skill_levels: dict[str, int], skills: dict,
                           weapons: dict,
                           guaranteed_skill_ids: list[str] | None = None,
                           economy: dict | None = None,
                           boss_share: float = 0.0) -> dict[str, int]:
    projected: dict[str, int] = {}
    weapon_element = str(weapons[weapon_id].get("element", "physical"))
    if weapon_element not in ("", "physical"):
        for skill_id, row in skills.items():
            if row.get("exclusive_group", "") == "projectile_element" and row.get("ammo_element", "") == weapon_element:
                projected[skill_id] = min(max(int(base_skill_levels.get(skill_id, 0)), 1), skill_max_level(row))
                break

    guaranteed_id = _conservative_guaranteed_skill(
        list(guaranteed_skill_ids or []), base_skill_levels, skills,
        economy or {}, boss_share)
    consumed_picks = 0
    if guaranteed_id and guaranteed_id not in projected:
        row = skills[guaranteed_id]
        projected[guaranteed_id] = min(
            max(int(base_skill_levels.get(guaranteed_id, 0)), 1),
            skill_max_level(row),
        )
        consumed_picks = 1

    # A physical weapon on a non-physical-weakness stage needs one matching
    # ammo conversion before the remaining offers are stage-compatible. It
    # consumes a real card slot and uses the same permanent-rank floor.
    if weapon_element in ("", "physical") and weakness not in ("", "physical"):
        for skill_id in sorted(skills):
            row = skills[skill_id]
            if str(row.get("exclusive_group", "")) != "projectile_element":
                continue
            if str(row.get("ammo_element", "")) != weakness:
                continue
            if skill_id not in projected and consumed_picks < card_picks:
                projected[skill_id] = min(
                    max(int(base_skill_levels.get(skill_id, 0)), 1),
                    skill_max_level(row),
                )
                consumed_picks += 1
            break

    # Guaranteed offers stay exact. Every remaining slot is filled with the
    # weakest positive, weapon-compatible card at the player's permanent rank.
    # This is a conservative expectation, not an optimal draft or synergy plan.
    for _ in range(max(card_picks - consumed_picks, 0)):
        current_score = _projection_score(projected, skills)
        weakest_score = float("inf")
        weakest_id = ""
        weakest_levels: dict[str, int] | None = None
        for skill_id in sorted(skills):
            row = skills[skill_id]
            group = str(row.get("exclusive_group", ""))
            if group == "projectile_element":
                ammo_element = str(row.get("ammo_element", ""))
                if weapon_element not in ("", "physical") and ammo_element != weapon_element:
                    continue
                if weapon_element in ("", "physical") and ammo_element != weakness:
                    continue
            current_level = int(projected.get(skill_id, 0))
            maximum = skill_max_level(row)
            if current_level >= maximum:
                continue
            candidate = dict(projected)
            if group:
                for peer_id, peer in skills.items():
                    if peer_id != skill_id and str(peer.get("exclusive_group", "")) == group:
                        candidate.pop(peer_id, None)
            candidate[skill_id] = (
                min(maximum, current_level + 1)
                if current_level > 0
                else min(max(int(base_skill_levels.get(skill_id, 0)), 1), maximum)
            )
            candidate_score = _projection_score(candidate, skills)
            if candidate_score <= current_score + 0.000001:
                continue
            selection_score = candidate_score
            if str(row.get("ammo_element", "")) == weakness:
                selection_score += 0.015
            if (
                selection_score < weakest_score - 0.000001
                or (
                    abs(selection_score - weakest_score) <= 0.000001
                    and (not weakest_id or skill_id < weakest_id)
                )
            ):
                weakest_score = selection_score
                weakest_id = skill_id
                weakest_levels = candidate
        if weakest_levels is None:
            break
        projected = weakest_levels
    return projected


def card_scale(card_picks: int, skills: dict, weapons: dict,
               weakness: str = "physical", weapon_id: str = "weapon_autocannon",
               base_skill_levels: dict[str, int] | None = None) -> float:
    """Mirror the shared GD projection with an explicit, save-independent profile."""
    levels = projected_skill_levels(
        card_picks,
        weakness,
        weapon_id,
        base_skill_levels or {},
        skills,
        weapons,
    )
    return combat_skill_effect_multiplier(levels, skills) ** SKILL_SCORE_EXPONENT


def offense_baseline_l1(characters: dict, weapons: dict) -> float:
    """免费裸装 L1(vanguard + autocannon,零专属技)的 O——required_t 的归一基准。"""
    return offense_multiplier(characters["vanguard"], weapons["weapon_autocannon"], 1, 1, 0)


def recommended_power(required_t: float, card_picks: int, recommend_level: int,
                      characters: dict, weapons: dict, skills: dict,
                      weakness: str = "physical") -> int:
    """Return the level's fixed recommendation, independent of player save state."""
    reference_level = min(max(int(recommend_level), 1), 40)
    character = characters["vanguard"]
    weapon = weapons["weapon_autocannon"]
    affinity_delta = bullet_affinity_multiplier(character, weapon, reference_level)
    affinity_delta /= max(legacy_bullet_affinity_multiplier(character, weapon), 0.01)
    character_survival = survival_multiplier(character, reference_level, weapon)
    o_ref = required_t * offense_baseline_l1(characters, weapons) * affinity_delta
    return int(round(core_power(o_ref, ARMOR_HP_MULT * character_survival) * card_scale(
        card_picks, skills, weapons, weakness, "weapon_autocannon", {}
    )))


def guaranteed_skill_ids(level: dict) -> list[str]:
    result: list[str] = []
    for rule in level.get("guaranteed_card_offers", []):
        if not isinstance(rule, dict):
            continue
        for skill_id in rule.get("skill_ids", []):
            skill_id = str(skill_id)
            if skill_id and skill_id not in result:
                result.append(skill_id)
    return result


def campaign_ordinal(level: dict) -> int:
    try:
        return max(int(str(level.get("id", "level_001")).split("_")[-1]), 1)
    except ValueError:
        return 1


def campaign_skill_rank(level: dict) -> int:
    """Permanent-skill rank affordable from cumulative campaign XP."""
    ordinal = campaign_ordinal(level)
    if ordinal <= 25:
        return 1
    if ordinal <= 50:
        return 2
    if ordinal <= 70:
        return 3
    return 4


def expected_permanent_skill_levels(level: dict, skills: dict) -> dict[str, int]:
    """Permanent skill rank expected at this campaign graduation point.

    design/32 freezes this against cumulative campaign XP rather than hero
    recommend_level: levels 1-25 use L1, 26-50 L2, 51-70 L3, and 71+ L4.
    """
    rank = campaign_skill_rank(level)
    return {skill_id: min(rank, skill_max_level(row)) for skill_id, row in skills.items()}


def effective_projectile_element(weapon_id: str, projected_levels: dict[str, int],
                                 skills: dict, weapons: dict) -> str:
    element = str(weapons.get(weapon_id, {}).get("element", "physical"))
    for skill_id, level in projected_levels.items():
        if int(level) <= 0:
            continue
        row = skills.get(skill_id, {})
        if str(row.get("exclusive_group", "")) == "projectile_element":
            return str(row.get("ammo_element", element))
    return element


def boss_effective_hp_multiplier(boss: dict, economy: dict) -> float:
    mechanic = str(boss.get("mechanic", ""))
    ruler = economy.get("power_ruler", {}) or {}
    table = ruler.get("boss_mechanic_time_mult", {}) or {}
    return max(float(table.get(mechanic, 1.0)), 1.0)


def boss_element_factor(boss: dict, element: str, economy: dict) -> float:
    weakness_mult = max(float(economy.get("weakness_mult", 1.5)), 1.0)
    if str(boss.get("weakness", "")) == element:
        return weakness_mult
    resistances = boss.get("resistances", {}) or {}
    if element in resistances:
        params = boss.get("mechanic_params", {}) or {}
        if (str(boss.get("mechanic", "")) == "armor_break"
                and bool(params.get("resistance_until_armor_break", False))):
            ruler = economy.get("power_ruler", {}) or {}
            return float(ruler.get("armor_break_effective_factor", ARMOR_BREAK_EFFECTIVE_FACTOR))
        reduction = min(max(float(resistances.get(element, 0.0)), 0.0), 0.95)
        return 1.0 - reduction
    # Compatibility only: Boss validation rejects new hard-immunity rows, but
    # a legacy input must still project non-zero damage just like the runtime.
    if element in boss.get("immune", []):
        return min(max(float(economy.get("resist_mult", 0.5)), 0.05), 1.0)
    return 1.0


def _boss_contract_profile(level: dict, bosses: dict, economy: dict, sim) -> tuple[dict[str, float], float, float]:
    zombies = load_table("zombies")
    _, boss_hp_by_id, _ = sim.level_enemy_hp_profile(level, zombies, bosses, economy)
    effective: dict[str, float] = {}
    for boss_id, hp in boss_hp_by_id.items():
        effective[boss_id] = float(hp) * boss_effective_hp_multiplier(bosses.get(boss_id, {}), economy)
    total = sum(effective.values())
    # Do not derive the primary amount by Boss id: authored reinforcement rows
    # intentionally repeat the same model.  Grouping by id made four Apexes
    # look like one primary Apex and hid the quantity pressure from the fixed
    # recommendation.  Count only the actual wave-row primary entries here.
    primary = 0.0
    primary_copy_counts: dict[str, int] = {}
    for wave in level.get("waves", []):
        if "boss" not in wave:
            continue
        boss_id = str(wave["boss"])
        boss_row = bosses.get(boss_id, {})
        copy_index = primary_copy_counts.get(boss_id, 0)
        primary_copy_counts[boss_id] = copy_index + 1
        primary += (
            sim.boss_hp_for_entry(level, boss_row, economy, sim.wave_number(wave))
            * sim.boss_hp_scale_for_index(level, economy, copy_index)
            * boss_effective_hp_multiplier(boss_row, economy)
        )
    weights = {
        boss_id: value / max(total, 1.0) for boss_id, value in effective.items()
    }
    return weights, total, primary


def weighted_boss_element_factor(weights: dict[str, float], bosses: dict,
                                 element: str, economy: dict) -> float:
    if not weights:
        return 1.0
    return sum(
        float(weight) * boss_element_factor(bosses.get(boss_id, {}), element, economy)
        for boss_id, weight in weights.items()
    )


def line_exposure_credit(crowd_ratio: float, boss_ratio: float,
                         contract: dict, economy: dict) -> float:
    """Bounded TTK credit applied to the defence-line ratio.

    The offline leak model already represents a normal on-pace fight. Faster
    clearing therefore earns only a small contact-time credit, while an
    underpowered offence receives the symmetric penalty. This prevents the old
    failure mode where a high-output build was forever capped by a stage-level
    line curve that did not know whether enemies ever reached the base.
    """
    weights = contract.get("line_exposure_weights", {}) or {}
    crowd_weight = min(max(float(weights.get("crowd", 1.0)), 0.0), 1.0)
    boss_weight = min(max(float(weights.get("boss", 0.0)), 0.0), 1.0)
    total = crowd_weight + boss_weight
    if total <= 0.0:
        crowd_weight, boss_weight, total = 1.0, 0.0, 1.0
    crowd_weight /= total
    boss_weight /= total
    pressure = crowd_weight / max(float(crowd_ratio), 0.35)
    pressure += boss_weight / max(float(boss_ratio), 0.35)
    ruler = economy.get("power_ruler", {}) or {}
    lower = min(max(float(ruler.get(
        "line_exposure_credit_min", DEFAULT_LINE_EXPOSURE_CREDIT_MIN)), 0.5), 1.0)
    upper = max(float(ruler.get(
        "line_exposure_credit_max", DEFAULT_LINE_EXPOSURE_CREDIT_MAX)), 1.0)
    return min(max(pressure ** -0.5, lower), upper)


def build_power_contract(level: dict, requirement: dict, characters: dict,
                         weapons: dict, skills: dict, bosses: dict,
                         economy: dict, sim) -> dict:
    """Build the fixed three-axis contract consumed by SaveManager."""
    ruler = economy.get("power_ruler", {}) or {}
    card_picks = max(int(level.get("target_card_picks", 4)), 1)
    weakness = str(level.get("primary_weakness", "physical"))
    recommend_level = min(max(int(level.get("recommend_level", 1)), 1), 40)
    required_t = max(float(requirement.get("min_output", 1.0)), 0.05)

    reference_character = characters["vanguard"]
    reference_weapon = weapons["weapon_autocannon"]
    affinity_delta = bullet_affinity_multiplier(reference_character, reference_weapon, recommend_level)
    affinity_delta /= max(legacy_bullet_affinity_multiplier(reference_character, reference_weapon), 0.01)
    reference_offense = required_t * offense_baseline_l1(characters, weapons) * affinity_delta
    base_levels = expected_permanent_skill_levels(level, skills)
    guarantees = guaranteed_skill_ids(level)
    mob_share = max(float(requirement.get("mob_hp_share", 1.0)), 0.0)
    boss_share = max(float(requirement.get("boss_hp_share", 0.0)), 0.0)
    share_total = max(mob_share + boss_share, 0.000001)
    normalized_boss_share = boss_share / share_total
    projected = projected_skill_levels(
        card_picks, weakness, "weapon_autocannon", base_levels, skills, weapons,
        guarantees, economy, normalized_boss_share)
    axes = skill_capacity_profile(projected, skills, economy, normalized_boss_share)
    element = effective_projectile_element("weapon_autocannon", projected, skills, weapons)
    weakness_mult = max(float(economy.get("weakness_mult", 1.5)), 1.0)
    mob_element = weakness_mult if element == weakness else 1.0
    crowd_required = max(reference_offense * axes["crowd"] * mob_element, 0.01)

    boss_weights, boss_effective_hp, primary_effective_hp = _boss_contract_profile(
        level, bosses, economy, sim)
    boss_element = weighted_boss_element_factor(boss_weights, bosses, element, economy)
    reference_boss = reference_offense * axes["boss"] * boss_element if boss_weights else 0.0
    boss_window = max(float(ruler.get("boss_clear_window_seconds", DEFAULT_BOSS_CLEAR_WINDOW)), 1.0)
    boss_dps_per_capacity = max(float(ruler.get("boss_dps_per_capacity", DEFAULT_BOSS_DPS_PER_CAPACITY)), 1.0)
    runtime_boss_required = boss_effective_hp / boss_window / boss_dps_per_capacity
    boss_required = max(reference_boss, runtime_boss_required) if boss_weights else 0.0

    # v4 defence line: derive the requirement from the same per-wave breach
    # damage estimator and star thresholds used by simulate_balance instead of
    # an unrelated recommend-level cubic. R=1 on this axis means the build has
    # enough effective base HP to finish at the two-star survival boundary.
    expected_breach = max(float(sim.leak_damage(
        level, load_table("zombies"), bosses, economy, bool(boss_weights))), 0.0)
    base_hp_cushion = (
        float(sim.boss_base_hp_cushion(economy, campaign_ordinal(level)))
        if boss_weights else 1.0
    )
    base_line_hp = max(float(level.get("base_hp_ref", 100.0)) * base_hp_cushion, 1.0)
    star_thresholds = economy.get("star_thresholds", {}) or {}
    target_hp_ratio = min(max(float(star_thresholds.get("two_star_hp_ratio", 0.35)), 0.0), 0.95)
    damage_budget = max(1.0 - target_hp_ratio, 0.05)
    line_floor = max(float(ruler.get(
        "line_requirement_floor", DEFAULT_LINE_REQUIREMENT_FLOOR)), 0.05)
    line_required = max(expected_breach / (base_line_hp * damage_budget), line_floor)
    base_recommended = recommended_power(
        required_t, card_picks, recommend_level, characters, weapons, skills, weakness)
    omitted_boss_mult = (
        boss_effective_hp / max(primary_effective_hp, 1.0)
        if primary_effective_hp > 0.0 else 1.0
    )
    runtime_calibration = (
        max(float(ruler.get("runtime_boss_recommendation_calibration", 1.0)), 0.1)
        if omitted_boss_mult > 1.000001 else 1.0
    )
    fixed_recommended = int(round(
        base_recommended * (omitted_boss_mult ** OFFENSE_WEIGHT) * runtime_calibration))
    contract = {
        "model": "bottleneck_v4",
        "recommended_power": max(fixed_recommended, 1),
        "crowd_capacity": round(crowd_required, 4),
        "boss_capacity": round(boss_required, 4),
        "line_capacity": round(line_required, 4),
        "line_expected_breach": round(expected_breach, 4),
        "line_base_hp": round(base_line_hp, 4),
        "line_target_hp_ratio": round(target_hp_ratio, 4),
        "line_exposure_weights": {
            "crowd": round(mob_share / share_total, 6),
            "boss": round(boss_share / share_total, 6),
        },
        "boss_effective_hp": round(boss_effective_hp, 2),
        "boss_weights": {key: round(value, 6) for key, value in boss_weights.items()},
        "runtime_boss_pressure_mult": round(omitted_boss_mult, 6),
        "guaranteed_skill_ids": guarantees,
        "reference_skill_rank": campaign_skill_rank(level),
    }
    contract = calibrate_power_contract_corridor(
        level, contract, characters, weapons, skills, bosses, economy)
    return calibrate_owner_anchor(
        level, contract, characters, weapons, skills, bosses, economy)


def power_for_build(level: dict, contract: dict, build: dict, characters: dict,
                    weapons: dict, armors: dict, chips: dict, pets: dict,
                    skills: dict, bosses: dict, economy: dict) -> dict:
    """Python mirror of SaveManager's player-side bottleneck calculation."""
    character_id = str(build.get("character", "vanguard"))
    weapon_id = str(build.get("weapon", "weapon_autocannon"))
    armor_id = str(build.get("armor", ""))
    chip_id = str(build.get("chip", ""))
    pet_id = str(build.get("pet", ""))
    character_level = int(build.get("character_level", 1))
    weapon_level = int(build.get("weapon_level", 1))
    armor_level = int(build.get("armor_level", 1))
    chip_level = int(build.get("chip_level", 1))
    pet_level = int(build.get("pet_level", 1))
    sig_level = int(build.get("signature_level", 0))
    base_levels = dict(build.get("skill_base_levels", {}) or {})
    line_weights = contract.get("line_exposure_weights", {}) or {}
    mob_weight = max(float(line_weights.get("crowd", 1.0)), 0.0)
    boss_weight = max(float(line_weights.get("boss", 0.0)), 0.0)
    boss_share = boss_weight / max(mob_weight + boss_weight, 0.000001)
    projected = projected_skill_levels(
        max(int(level.get("target_card_picks", 4)), 1),
        str(level.get("primary_weakness", "physical")),
        weapon_id, base_levels, skills, weapons,
        list(contract.get("guaranteed_skill_ids", [])), economy, boss_share,
    )
    offense = offense_multiplier(
        characters[character_id], weapons[weapon_id], character_level, weapon_level, sig_level,
        chip=chips.get(chip_id), chip_level=chip_level,
        pet=pets.get(pet_id), pet_level=pet_level,
    )
    survival = survival_multiplier(
        characters[character_id], character_level, weapons[weapon_id],
        armors.get(armor_id), armor_level, chips.get(chip_id), chip_level,
        pets.get(pet_id), pet_level,
    )
    axes = skill_capacity_profile(projected, skills, economy, boss_share)
    element = effective_projectile_element(weapon_id, projected, skills, weapons)
    weakness_mult = max(float(economy.get("weakness_mult", 1.5)), 1.0)
    mob_element = weakness_mult if element == str(level.get("primary_weakness", "physical")) else 1.0
    crowd_capacity = offense * axes["crowd"] * mob_element
    boss_factor = weighted_boss_element_factor(
        dict(contract.get("boss_weights", {})), bosses, element, economy)
    boss_capacity = offense * axes["boss"] * boss_factor
    line_capacity = survival * axes["line"]
    armor = armors.get(armor_id, {})
    if str(armor.get("resist", "none")) == str(level.get("primary_weakness", "physical")):
        line_capacity /= 0.88
    if str(characters[character_id].get("passive", "")) == "breach_guard":
        line_capacity /= 0.82
        if growth_rank(character_level) >= 2:
            line_capacity /= 0.88

    crowd_ratio = crowd_capacity / max(float(contract.get("crowd_capacity", 1.0)), 0.01)
    boss_ratio = (
            boss_capacity / max(float(contract.get("boss_capacity", 1.0)), 0.01)
            if float(contract.get("boss_capacity", 0.0)) > 0.0 else 99.0
        )
    raw_line_ratio = line_capacity / max(float(contract.get("line_capacity", 1.0)), 0.01)
    exposure_credit = line_exposure_credit(crowd_ratio, boss_ratio, contract, economy)
    ratios = {
        "crowd": crowd_ratio,
        "boss": boss_ratio,
        "line": raw_line_ratio * exposure_credit,
    }
    bottleneck = min(ratios.values())
    power = int(round(float(contract.get("recommended_power", 1)) * bottleneck))
    return {
        "power": max(power, 1),
        "recommended": int(contract.get("recommended_power", 1)),
        "ratios": ratios,
        "bottleneck": min(ratios, key=ratios.get),
        "projected_skills": projected,
        "capacities": {
            "crowd": crowd_capacity,
            "boss": boss_capacity,
            "line": line_capacity,
        },
        "line_raw_ratio": raw_line_ratio,
        "line_exposure_credit": exposure_credit,
    }


def corridor_calibration_fixture(level: dict, characters: dict, weapons: dict,
                                 armors: dict, chips: dict, pets: dict,
                                 skills: dict) -> tuple[dict, dict]:
    """Return design/32's single canonical progression fixture and its manifest."""
    ordinal = campaign_ordinal(level)
    recommend = max(int(level.get("recommend_level", 1)), 1)
    strongest = ordinal >= 71
    character_id = "vanguard"
    weapon_id = "weapon_scattergun" if strongest else "weapon_autocannon"
    armor_id = "armor_kevlar"
    chip_id = "chip_attack"
    pet_id = "pet_turret_drone" if strongest else ""
    skill_rank = campaign_skill_rank(level)

    def capped_level(rows: dict, item_id: str, fallback: int) -> int:
        if not item_id:
            return 1
        return min(recommend, max(int(rows.get(item_id, {}).get("max_level", fallback)), 1))

    build = {
        "character": character_id,
        "character_level": capped_level(characters, character_id, 40),
        "weapon": weapon_id,
        "weapon_level": capped_level(weapons, weapon_id, 50),
        "armor": armor_id,
        "armor_level": capped_level(armors, armor_id, 35),
        "chip": chip_id,
        "chip_level": capped_level(chips, chip_id, 35),
        "pet": pet_id,
        "pet_level": capped_level(pets, pet_id, 30),
        "signature_level": min(recommend // 8, 5),
        "skill_base_levels": {
            skill_id: min(skill_rank, skill_max_level(row))
            for skill_id, row in skills.items()
        },
    }
    manifest = {
        "family": "strongest_free" if strongest else "paced_free",
        "character": character_id,
        "character_level": build["character_level"],
        "weapon": weapon_id,
        "weapon_level": build["weapon_level"],
        "armor": armor_id,
        "armor_level": build["armor_level"],
        "chip": chip_id,
        "chip_level": build["chip_level"],
        "pet": pet_id,
        "pet_level": build["pet_level"],
        "signature_level": build["signature_level"],
        "skill_rank": skill_rank,
    }
    return build, manifest


def calibrate_power_contract_corridor(level: dict, contract: dict,
                                      characters: dict, weapons: dict,
                                      skills: dict, bosses: dict,
                                      economy: dict) -> dict:
    """Keep the display contract inside design/32's free-progression corridor.

    Calibration adjusts only the checked-in three-axis display contract. The
    physical clear requirement and every runtime difficulty input remain intact.
    """
    ordinal = campaign_ordinal(level)
    if ordinal < 2 or ordinal > 98:
        return contract

    armors = load_table("armors")
    chips = load_table("chips")
    pets = load_table("pets")
    build, manifest = corridor_calibration_fixture(
        level, characters, weapons, armors, chips, pets, skills)
    lower = PACE_CORRIDOR_MIN if ordinal <= 70 else LATE_CORRIDOR_MIN
    upper = CORRIDOR_MAX
    raw = power_for_build(
        level, contract, build, characters, weapons, armors, chips, pets,
        skills, bosses, economy)
    raw_ratios = dict(raw["ratios"])
    raw_ratio = min(raw_ratios.values())
    adjusted_axes: list[str] = []

    if raw_ratio < lower:
        target = lower + CORRIDOR_MARGIN
        for axis in ("crowd", "boss", "line"):
            key = f"{axis}_capacity"
            if axis == "boss" and float(contract.get(key, 0.0)) <= 0.0:
                continue
            if float(raw_ratios[axis]) >= target:
                continue
            contract[key] = round(
                float(contract.get(key, 1.0)) * float(raw_ratios[axis]) / target,
                4,
            )
            adjusted_axes.append(axis)
    elif raw_ratio > upper:
        target = upper - CORRIDOR_MARGIN
        candidates = ["crowd", "boss", "line"]
        if str(level.get("id", "")) == "level_055":
            # The Owner replay freezes the defence-line axis and bottleneck.
            candidates.remove("line")
        candidates = [
            axis for axis in candidates
            if axis != "boss" or float(contract.get("boss_capacity", 0.0)) > 0.0
        ]
        axis = min(candidates, key=lambda name: float(raw_ratios[name]))
        key = f"{axis}_capacity"
        contract[key] = round(
            float(contract.get(key, 1.0)) * float(raw_ratios[axis]) / target,
            4,
        )
        adjusted_axes.append(axis)

    calibrated = power_for_build(
        level, contract, build, characters, weapons, armors, chips, pets,
        skills, bosses, economy)
    contract["corridor_calibration"] = {
        "band": [lower, upper],
        "raw_ratio": round(raw_ratio, 6),
        "ratio": round(min(calibrated["ratios"].values()), 6),
        "raw_bottleneck": str(raw["bottleneck"]),
        "bottleneck": str(calibrated["bottleneck"]),
        "adjusted_axes": adjusted_axes,
        "fixture": manifest,
    }
    return contract


def owner_anchor_fixture(level_id: str, skills: dict) -> dict:
    """Return the two Owner replay builds whose ratio and bottleneck are frozen.

    The fixture lives here so generation, validation and reporting all consume
    one definition. Absolute display numbers may move when the ruler scale is
    regenerated; the replay ratio and Boss bottleneck may not.
    """
    if level_id == "level_099":
        return {
            "character": "vanguard", "character_level": 40,
            "weapon": "weapon_scattergun", "weapon_level": 50,
            "armor": "armor_kevlar", "armor_level": 35,
            "chip": "chip_attack", "chip_level": 35,
            "pet": "pet_turret_drone", "pet_level": 30,
            "signature_level": 5,
            "skill_base_levels": {
                skill_id: skill_max_level(row)
                for skill_id, row in skills.items()
            },
        }
    if level_id == "level_080":
        return {
            "character": "blaze", "character_level": 40,
            "weapon": "weapon_apocalypse_inferno", "weapon_level": 36,
            "armor": "armor_apocalypse_molten", "armor_level": 21,
            "chip": "chip_apocalypse_stellar", "chip_level": 21,
            "pet": "pet_apocalypse_phoenix", "pet_level": 15,
            "signature_level": 5,
            "skill_base_levels": {
                skill_id: min(4, skill_max_level(row))
                for skill_id, row in skills.items()
            },
        }
    raise KeyError(f"No Owner replay fixture for {level_id}")


def calibrate_owner_anchor(level: dict, contract: dict,
                           characters: dict, weapons: dict, skills: dict,
                           bosses: dict, economy: dict) -> dict:
    """Re-pin approved replay ratios after a legitimate contract rescale."""
    level_id = str(level.get("id", ""))
    target = OWNER_ANCHOR_RATIOS.get(level_id)
    if target is None:
        return contract

    armors = load_table("armors")
    chips = load_table("chips")
    pets = load_table("pets")
    build = owner_anchor_fixture(level_id, skills)
    raw = power_for_build(
        level, contract, build, characters, weapons, armors, chips, pets,
        skills, bosses, economy)
    raw_boss_ratio = float(raw["ratios"]["boss"])
    contract["boss_capacity"] = round(
        float(contract["boss_capacity"]) * raw_boss_ratio / float(target), 4)
    calibrated = power_for_build(
        level, contract, build, characters, weapons, armors, chips, pets,
        skills, bosses, economy)
    ratio = min(float(value) for value in calibrated["ratios"].values())
    if str(calibrated["bottleneck"]) != "boss" or abs(ratio - target) > 0.0002:
        raise AssertionError(
            f"{level_id} Owner replay drifted: R={ratio:.4f} "
            f"bottleneck={calibrated['bottleneck']} target={target:.4f}")
    contract["owner_anchor_calibration"] = {
        "ratio": target,
        "bottleneck": "boss",
        "fixture": "design32_34_owner_replay",
    }
    return contract


# ---------------------------------------------------------------- 通关线求解
#
# 操作性定义:required_t = 沿"按节奏免费构筑族"(vanguard + autocannon + 攻击芯片,
# 等级连续参数 ℓ)二分搜索出的最小可通关成员,其 GD 侧输出倍率 O(ℓ*) / O(L1裸装)。
# 可通关判定完全复用 simulate_balance 各分支自己的口径(含 ≥50 Boss 关的实测基准
# 分支与 modern DPS 混合),再叠加 DPS 依赖的漏怪约束——避免两套 DPS 量纲互算。

FAMILY_MAX_INDEX = 60.0
LEAK_TIME_EXPONENT = 2.0


class FamilyContext:
    """把 simulate_balance 主循环里散落的标定数据收拢成可复用的求解上下文。"""

    def __init__(self, sim, characters: dict, weapons: dict, economy: dict):
        self.sim = sim
        self.characters = characters
        self.weapons = weapons
        self.economy = economy
        self.char_max = int(characters["vanguard"].get("max_level", 40))
        self.weapon_max = int(weapons["weapon_autocannon"].get("max_level", 50))
        benchmark = json.loads((ROOT / "tools" / "physical_endgame_runtime_benchmark.json").read_text(encoding="utf-8"))
        self.bench = benchmark["best_same_loadout"]["weapon_autocannon"]
        import audit_character_endgame_dps as character_dps
        max_reference_dps = character_dps.best_result("vanguard").total_dps
        levels = load_table("levels")
        legacy_reference = sim.estimate_player_dps(
            "vanguard", "weapon_railgun", self.char_max,
            int(weapons["weapon_railgun"].get("max_level", 50)),
            sim.estimate_skill_mult(levels[-1]))
        self.max_modern_scale = max_reference_dps / max(legacy_reference, 1.0)
        self.max_raw_autocannon = sim.estimate_player_dps(
            "vanguard", "weapon_autocannon", self.char_max, self.weapon_max, 1.0)
        self.max_card_throughput = sim.estimate_skill_mult(levels[-1])

    def family_levels(self, index: float) -> tuple[float, float]:
        return min(index, float(self.char_max)), min(index, float(self.weapon_max))

    def clear_time_ws(self, level: dict, zombies: dict, bosses: dict, index: float) -> float:
        """成员 ℓ=index 的预计清场时间——镜像 simulate_balance 主循环各分支。"""
        sim = self.sim
        economy = self.economy
        char_level, weapon_level = self.family_levels(index)
        mob_hp, boss_hp, _ = sim.level_enemy_hp_split(level, zombies, bosses, economy)
        hp_total = mob_hp + boss_hp
        level_no = sim.level_number(level)
        boss_lvl = sim.is_boss_level(level)
        raw = _player_dps_cont(sim, self.characters, self.weapons, char_level, weapon_level, 1.0)
        skill_mult = sim.estimate_skill_mult(level)
        dps_ws = _player_dps_cont(sim, self.characters, self.weapons, char_level, weapon_level, skill_mult)
        progression = min(max((char_level - 1.0) / 39.0, 0.0), 1.0)
        modern = 1.0 + (self.max_modern_scale - 1.0) * progression
        dps_ws *= modern
        if boss_lvl and level_no >= 50:
            permanent = raw / max(self.max_raw_autocannon, 1.0)
            card_progress = skill_mult / max(self.max_card_throughput, 1.0)
            crowd = min(float(self.bench["crowd_dps"]) * permanent * card_progress, dps_ws)
            boss_dps = float(self.bench["boss_dps"]) * permanent * card_progress
            return mob_hp / max(crowd, 1.0) + boss_hp / max(boss_dps, 1.0) * 1.11
        return hp_total / max(dps_ws, 1.0)

    def model_clears(self, level: dict, zombies: dict, bosses: dict, index: float) -> bool:
        """成员 ℓ=index 是否能通关本关。

        漏怪模型:simulate_balance 的固定漏怪率(5%/12%)定义在按节奏参考构筑上;
        清场更慢则漏怪按时间比值平方放大(Owner 实测标定:雷霆L1构筑清场比按节奏慢
        约11%,漏怪伤害 57.7%→~71%,基地剩~29% = 1★,与 (1.11)^2 吻合)。
        """
        sim = self.sim
        level_no = sim.level_number(level)
        time_ws = self.clear_time_ws(level, zombies, bosses, index)
        if time_ws > clear_time_cap(level_no):
            return False
        rec = float(level.get("recommend_level", level_no))
        t_ref = max(self.clear_time_ws(level, zombies, bosses, rec), 1.0)
        boss_lvl = sim.is_boss_level(level)
        baseline = sim.leak_damage(level, zombies, bosses, self.economy, boss_lvl)
        base_hp = float(level.get("base_hp_ref", 100)) * ARMOR_HP_MULT
        base_hp *= sim.boss_base_hp_cushion(self.economy, level_no) if boss_lvl else 1.0
        breach = baseline * (max(time_ws / t_ref, 0.25) ** LEAK_TIME_EXPONENT)
        return breach <= base_hp

    def family_offense_t(self, characters: dict, weapons: dict, chips: dict, index: float) -> float:
        char_level, weapon_level = self.family_levels(index)
        chip = chips.get("chip_attack", {})
        chip_level = min(index, float(chip.get("max_level", 35)))
        sig_level = min(index / 8.0, 5.0)
        o = offense_multiplier_cont(
            characters["vanguard"], weapons["weapon_autocannon"], char_level, weapon_level,
            sig_level, chip=chip, chip_level=chip_level)
        # clear_requirement 是难度模拟器的归一输出，不应随显示战力新增的角色身份
        # 折算漂移；剥离 design/29 新增项，保留 design/28 原有 damage_bonus 语义。
        full_affinity = bullet_affinity_multiplier(characters["vanguard"], weapons["weapon_autocannon"], char_level)
        legacy_affinity = legacy_bullet_affinity_multiplier(characters["vanguard"], weapons["weapon_autocannon"])
        o *= legacy_affinity / max(full_affinity, 0.01)
        return o / offense_baseline_l1(characters, weapons)


def solve_required_t(level: dict, zombies: dict, bosses: dict, chips: dict,
                     characters: dict, weapons: dict, ctx: FamilyContext) -> dict:
    # required_t is the historical progression-family calibration for the
    # authored primary encounter. Runtime-added bosses are represented by the
    # v3 Boss contract and fixed recommendation correction below; feeding them
    # back into this legacy scalar would double-charge the same pressure and can
    # make the autocannon-only calibration family falsely appear unwinnable.
    calibration_level = dict(level)
    calibration_level.pop("runtime_bosses", None)
    mob_hp, boss_hp, _ = ctx.sim.level_enemy_hp_split(level, zombies, bosses, ctx.economy)
    hp_total = max(mob_hp + boss_hp, 1.0)
    if not ctx.model_clears(calibration_level, zombies, bosses, FAMILY_MAX_INDEX):
        raise AssertionError(f"{level.get('id')}: not clearable even by maxed family - model/data inconsistency")
    lo, hi = 1.0, FAMILY_MAX_INDEX
    if ctx.model_clears(calibration_level, zombies, bosses, lo):
        # 族下界(ℓ=1)就能通关的早期关:在 t 空间连续外推真实下限,否则第 1 关的
        # 通关线会高于新号裸装战力,onboarding 观感反掉(实测:required 1.087 > 裸装 1.0)。
        required_t = ctx.family_offense_t(characters, weapons, chips, 1.0) * _sub_family_scale(calibration_level, zombies, bosses, ctx)
    else:
        for _ in range(40):
            mid = (lo + hi) / 2.0
            if ctx.model_clears(calibration_level, zombies, bosses, mid):
                hi = mid
            else:
                lo = mid
        required_t = ctx.family_offense_t(characters, weapons, chips, hi)
    return {
        "min_output": round(required_t, 4),
        "mob_hp_share": round(mob_hp / hp_total, 4),
        "boss_hp_share": round(boss_hp / hp_total, 4),
        "boss_id": _boss_id(level),
    }


def _sub_family_scale(level: dict, zombies: dict, bosses: dict, ctx: FamilyContext) -> float:
    """ℓ=1 已可通关时,按 时间∝1/输出 解出低于族下界的真实通关线缩放(∈(0,1])。"""
    sim = ctx.sim
    level_no = sim.level_number(level)
    t1_time = ctx.clear_time_ws(level, zombies, bosses, 1.0)
    rec = float(level.get("recommend_level", level_no))
    t_ref = max(ctx.clear_time_ws(level, zombies, bosses, rec), 1.0)
    boss_lvl = sim.is_boss_level(level)
    baseline = sim.leak_damage(level, zombies, bosses, ctx.economy, boss_lvl)
    base_hp = float(level.get("base_hp_ref", 100)) * ARMOR_HP_MULT
    base_hp *= sim.boss_base_hp_cushion(ctx.economy, level_no) if boss_lvl else 1.0
    s_timeout = t1_time / clear_time_cap(level_no)
    max_time = t_ref * (base_hp / max(baseline, 1.0)) ** (1.0 / LEAK_TIME_EXPONENT)
    s_leak = t1_time / max(max_time, 1.0)
    return min(max(s_timeout, s_leak, 0.15), 1.0)


def _player_dps_cont(sim, characters: dict, weapons: dict, char_level: float, weapon_level: float, skill_mult: float) -> float:
    """estimate_player_dps 的连续等级版(镜像其公式,允许非整数等级用于二分)。"""
    char = characters["vanguard"]
    weapon = weapons["weapon_autocannon"]
    economy = load_table("economy")
    char_atk = (float(char["base_atk"]) / 100.0) * (1.0 + float(char["atk_growth"]) * 0.45 * (char_level - 1.0))
    weapon_dmg = 1.0 + 0.08 * (weapon_level - 1.0)
    weapon_fr = 1.0 + 0.025 * (weapon_level - 1.0)
    damage = BASE_WEAPON_DAMAGE * float(weapon.get("base_atk_coef", 1.0)) * char_atk * weapon_dmg * 1.20 * float(economy.get("PLAYER_SHOT_DAMAGE_MULT", 1.0))
    fr = float(weapon.get("fire_rate", 4.0)) * weapon_fr * float(economy.get("PLAYER_FIRE_RATE_MULT", 0.25)) * float(char.get("fire_rate_mod", 1.0))
    affinity = 1.10 if weapon.get("element", "physical") == char.get("element_focus", "") else 1.0
    return damage * fr * skill_mult * affinity * 1.18


def offense_multiplier_cont(character: dict, weapon: dict, char_level: float, weapon_level: float,
                            sig_level: float, chip: dict | None = None, chip_level: float = 1.0) -> float:
    """offense_multiplier 的连续等级版(用于构筑族二分;整数路径与 GD 完全一致)。"""
    mult = float(character.get("base_atk", 100.0)) / 100.0 * float(character.get("fire_rate_mod", 1.0))
    mult *= 1.0 + float(character.get("atk_growth", 0.08)) * 0.45 * max(char_level - 1.0, 0.0)
    wq = max(weapon_effective_dps(weapon) / 4.0, 0.35)
    wq *= 1.0 + 0.08 * max(weapon_level - 1.0, 0.0)
    wq *= 1.0 + 0.025 * max(weapon_level - 1.0, 0.0)
    mult *= wq
    mult *= bullet_affinity_multiplier(character, weapon, char_level)
    if chip:
        value = float(chip.get("value", 0.0)) + float(chip.get("level_value_growth", 0.0)) * max(chip_level - 1.0, 0.0)
        mult *= offense_stat_factor(str(chip.get("stat", "")), value)
    active = character.get("active_skill", {}) or {}
    if active:
        cooldown = max(float(active.get("cooldown", 18.0)) * (1.0 - min(max(float(active.get("sig_level_cooldown_reduction", 0.0)) * sig_level, 0.0), 0.35)), 1.0)
        duration = float(active.get("duration", 6.0)) + float(active.get("sig_level_duration_bonus", 0.0)) * sig_level
        uptime = min(max(duration / cooldown, 0.0), 1.0)
        damage_mult = float(active.get("damage_mult", 1.0)) + float(active.get("sig_level_damage_bonus", 0.0)) * sig_level
        damage_mult *= 1.0 + float(character.get("atk_growth", 0.08)) * 0.52 * max(char_level - 1.0, 0.0)
        burst = damage_mult * float(active.get("barrage_fire_rate_mult", 1.0))
        mult *= 1.0 + uptime * max(burst - 1.0, 0.0)
    return max(mult, 0.05)


def _potential_breach(level: dict, zombies: dict, bosses: dict, economy: dict, sim) -> float:
    total = 0.0
    level_no = sim.level_number(level)
    for wave in level.get("waves", []):
        wave_no = sim.wave_number(wave)
        damage_mult = sim.late_wave_damage_ramp(economy, level_no, wave_no)
        count_mult = sim.late_wave_count_mult(economy, wave_no, level_no)
        for spawn in wave.get("spawns", []) + wave.get("support", []):
            z = zombies.get(spawn.get("type", ""), {})
            bd = GLOBAL_DMG_BASE * float(z.get("bd_coef", 1.0)) * damage_mult
            total += bd * int(round(int(spawn.get("count", 0)) * count_mult))
        if "boss" in wave:
            boss_row = bosses.get(wave["boss"], {})
            total += GLOBAL_DMG_BASE * float(boss_row.get("bd_coef", 4.0)) * damage_mult
    return total


def _boss_id(level: dict):
    for wave in level.get("waves", []):
        if "boss" in wave:
            return wave["boss"]
    return None


def clear_time_cap(level_no: int) -> float:
    """simulate_balance.main 内嵌 cap 的镜像(那边是闭包,无法 import)。"""
    if level_no >= 99:
        return 460.0
    if level_no >= 90:
        return 350.0
    if level_no >= 80:
        return 310.0
    if level_no >= 70:
        return 245.0
    if level_no >= 60:
        return 190.0
    return 180.0
