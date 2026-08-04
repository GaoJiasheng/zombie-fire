#!/usr/bin/env python3
"""design/28 战力口径 2.0 的 Python 镜像与通关线求解器。

镜像 SaveManager 的乘法战力公式(输出倍率 O / 生存倍率 S / K·γ 映射),并基于
simulate_balance 的敌方 HP/刷怪/漏怪模型解出每关"恰好能通关"所需的最小装备侧
输出 required_t(归一到免费裸装 L1 的 O 基准)。

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




def bullet_affinity_multiplier(character: dict, weapon: dict) -> float:
    affinity = character.get("bullet_affinity", {}) or {}
    if not affinity:
        return 1.0
    if str(weapon.get("element", "physical")) != str(affinity.get("element", character.get("element_focus", "physical"))):
        return 1.0
    return 1.0 + max(float(affinity.get("damage_bonus", 0.0)), 0.0)


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
    mult *= bullet_affinity_multiplier(character, weapon)
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


def survival_multiplier(armor: dict | None = None, armor_level: int = 1,
                        chip: dict | None = None, chip_level: int = 1,
                        pet: dict | None = None, pet_level: int = 1) -> float:
    mult = 1.0
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


def generic_card_throughput(card_picks: int) -> float:
    picks = float(max(0, card_picks))
    return min(SKILL_THROUGHPUT_CAP, 1.0 + 0.42 * picks + 0.08 * picks * picks)


def card_scale(card_picks: int) -> float:
    """推荐战力使用的标准选卡缩放(与 _skill_power_scale 的 ^0.5 同构)。"""
    return generic_card_throughput(card_picks) ** 0.5


def offense_baseline_l1(characters: dict, weapons: dict) -> float:
    """免费裸装 L1(vanguard + autocannon,零专属技)的 O——required_t 的归一基准。"""
    return offense_multiplier(characters["vanguard"], weapons["weapon_autocannon"], 1, 1, 0)


def recommended_power(required_t: float, card_picks: int, characters: dict, weapons: dict) -> int:
    o_ref = required_t * offense_baseline_l1(characters, weapons)
    return int(round(core_power(o_ref, ARMOR_HP_MULT) * card_scale(card_picks)))


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
        return o / offense_baseline_l1(characters, weapons)


def solve_required_t(level: dict, zombies: dict, bosses: dict, chips: dict,
                     characters: dict, weapons: dict, ctx: FamilyContext) -> dict:
    mob_hp, boss_hp, _ = ctx.sim.level_enemy_hp_split(level, zombies, bosses, ctx.economy)
    hp_total = max(mob_hp + boss_hp, 1.0)
    if not ctx.model_clears(level, zombies, bosses, FAMILY_MAX_INDEX):
        raise AssertionError(f"{level.get('id')}: not clearable even by maxed family - model/data inconsistency")
    lo, hi = 1.0, FAMILY_MAX_INDEX
    if ctx.model_clears(level, zombies, bosses, lo):
        # 族下界(ℓ=1)就能通关的早期关:在 t 空间连续外推真实下限,否则第 1 关的
        # 通关线会高于新号裸装战力,onboarding 观感反掉(实测:required 1.087 > 裸装 1.0)。
        required_t = ctx.family_offense_t(characters, weapons, chips, 1.0) * _sub_family_scale(level, zombies, bosses, ctx)
    else:
        for _ in range(40):
            mid = (lo + hi) / 2.0
            if ctx.model_clears(level, zombies, bosses, mid):
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
    mult *= bullet_affinity_multiplier(character, weapon)
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
