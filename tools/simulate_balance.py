#!/usr/bin/env python3
"""Balance simulator.

For each level, estimate:
  - Total enemy HP, including the boss wave's HP and boss support.
  - Player DPS at the level's recommended progression level (clamped to each
    item's real max), with vanguard + autocannon, base chips/armor, current
    economy pacing knobs, and the skill-card multiplier implied by card budget.
  - Predicted clear time + estimated leak damage (5% leak on non-boss
    levels, 12% leak on boss levels because the boss can't be ignored).
  - Two scenarios: no_skill (very early game) and with_skill (mid-run).

The ordinary campaign path keeps the historical progression estimator so its
longitudinal pacing signal remains comparable.  Encounters that add bosses
through ``runtime_bosses`` use the same bottleneck-v3 contract as the player
power ruler; a generic single-boss autocannon estimate cannot represent that
encounter without recreating the exact desynchronisation this tool should
catch.

Outputs a table sorted by level so we can spot trivially-easy and
impossibly-hard levels at a glance.
"""
from __future__ import annotations
import argparse
import json
import math
from pathlib import Path

from combat_power_model import estimate_skill_throughput, run_skill_hp_pressure
import audit_character_endgame_dps as character_dps
import fire_rate_profiles as fire_rate_lab

ROOT = Path(__file__).resolve().parent.parent
LEVELS_PATH = ROOT / "data" / "levels.json"
ZOMBIES_PATH = ROOT / "data" / "zombies.json"
BOSSES_PATH = ROOT / "data" / "bosses.json"
CHARS_PATH = ROOT / "data" / "characters.json"
WEAPONS_PATH = ROOT / "data" / "weapons.json"
ECONOMY_PATH = ROOT / "data" / "economy.json"
CHALLENGES_PATH = ROOT / "data" / "challenges.json"
PHYSICAL_RUNTIME_BENCHMARK_PATH = ROOT / "tools" / "physical_endgame_runtime_benchmark.json"

GLOBAL_DMG_BASE = 10.0
BASE_WEAPON_DAMAGE = 28.0

CHIP_DAMAGE_MULT = 1.20   # chip_attack at moderate level
ARMOR_HP_MULT = 1.20      # armor_kevlar (typical)
BOSS_LEAK = 0.12
NORMAL_LEAK = 0.05

DEFAULT_LATE_WAVE_HP_BONUS = {"3": 1.45, "4": 1.85, "5": 2.30}
DEFAULT_LATE_WAVE_COUNT_MULT = {"4": 2.0, "5": 3.0}
DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP = {"start_level": 55, "full_level": 90, "start_wave": 3, "max_mult": 1.25, "curve_power": 1.0, "final_level": 99, "final_mult": 1.08}
DEFAULT_LATE_WAVE_BOSS_HP_BONUS = {"3": 1.30, "4": 1.50, "5": 1.75}
DEFAULT_LATE_WAVE_LEVEL_RAMP = {"start_level": 50, "full_level": 98, "max_mult": 2.05, "curve_power": 1.0, "final_level": 99, "final_mult": 1.12}
DEFAULT_LATE_WAVE_DAMAGE_RAMP = {"start_level": 50, "full_level": 98, "start_wave": 3, "max_mult": 1.0, "curve_power": 1.0, "final_level": 99, "final_mult": 1.0}
DEFAULT_BOSS_HP_LEVEL_BONUS = {"start_level": 20, "multiplier": 2.0}
DEFAULT_BOSS_SURVIVAL_HP_RAMP = {"start_level": 50, "full_level": 98, "max_mult": 56.0, "curve_power": 1.15, "final_level": 99, "final_mult": 1.08}
DEFAULT_STAR_THRESHOLDS = {"three_star_hp_ratio": 0.70, "two_star_hp_ratio": 0.35}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Simulate campaign balance pressure.")
    parser.add_argument(
        "--challenge",
        action="store_true",
        help="apply the chapter challenge variants from data/challenges.json",
    )
    parser.add_argument(
        "--star-boundary-audit",
        action="store_true",
        help="list levels within the audit window of either data-owned star boundary",
    )
    parser.add_argument(
        "--star-boundary-window",
        type=float,
        default=2.0,
        metavar="PERCENT",
        help="absolute leak-percentage window used by --star-boundary-audit (default: 2.0)",
    )
    parser.add_argument(
        "--fire-rate-profile",
        default=fire_rate_lab.DEFAULT_PROFILE_ID,
        metavar="PROFILE",
        help="data-owned fire-rate laboratory profile (default: control)",
    )
    return parser.parse_args()


def challenge_rule_for_level(level: dict, challenges: dict) -> dict:
    """Mirror ChallengeRules.for_level without duplicating authored values."""
    chapter = max(1, min(10, int(level.get("chapter", 1))))
    row = challenges.get(f"chapter_{chapter:02d}", {})
    if not isinstance(row, dict):
        row = {}
    return {
        "hp_mult": max(0.1, float(row.get("hp_mult", 1.0))),
        "speed_mult": max(0.1, float(row.get("speed_mult", 1.0))),
        "breach_damage_mult": max(0.1, float(row.get("breach_damage_mult", 1.0))),
        "mechanic_rate_mult": max(0.1, float(row.get("mechanic_rate_mult", 1.0))),
    }


def boss_base_hp_cushion(economy: dict, level_no: int) -> float:
    """Boss-level base-HP cushion, mirroring battle.gd._boss_level_base_hp_mult.

    design/24 Phase 8: boss pressure is U-shaped - levels 5-20 and 65-99 both
    read 46-57% leak while the 25-60 middle sits at 33-46% - so the flat 1.25
    cushion left the first three boss levels a player meets among the hardest
    in the campaign. The early arm now gets a larger cushion that decays to the
    base value; the late arm stays hardest on purpose.
    """
    rule = economy.get("boss_level_base_hp_mult", 1.0)
    if not isinstance(rule, dict):
        return max(1.0, float(rule))
    base = max(1.0, float(rule.get("base", 1.0)))
    early = max(base, float(rule.get("early_mult", base)))
    full_level = float(rule.get("early_full_level", 0))
    end_level = float(rule.get("early_end_level", full_level))
    if level_no <= full_level:
        return early
    if level_no >= end_level or end_level <= full_level:
        return base
    t = (float(level_no) - full_level) / (end_level - full_level)
    return early + (base - early) * t


def star_leak_caps(economy: dict) -> tuple[float, float]:
    """Return the (3-star, 2-star) leak% caps implied by economy.json.

    The runtime rates surviving base HP (core/data/star_rules.gd); this module
    works in leak%, which is the same quantity inverted. Keeping the numbers in
    one file is what design/24 Phase 1 is about - do not re-hardcode them.
    """
    rule = economy.get("star_thresholds", DEFAULT_STAR_THRESHOLDS)
    if not isinstance(rule, dict):
        rule = DEFAULT_STAR_THRESHOLDS
    three = float(rule.get("three_star_hp_ratio", DEFAULT_STAR_THRESHOLDS["three_star_hp_ratio"]))
    two = float(rule.get("two_star_hp_ratio", DEFAULT_STAR_THRESHOLDS["two_star_hp_ratio"]))
    two = min(two, three)
    return (1.0 - three) * 100.0, (1.0 - two) * 100.0


def print_star_boundary_audit(
    rows: list[tuple],
    three_star_leak_pct: float,
    two_star_leak_pct: float,
    window_pct: float,
) -> None:
    """Print exact near-boundary levels without owning either threshold.

    The two boundary values are already derived from economy.json by
    star_leak_caps().  This helper owns only the requested inspection window,
    so future rating changes cannot leave a stale 30/65 duplicate here.
    """
    window_pct = max(0.0, float(window_pct))
    boundaries = (
        ("3-star", three_star_leak_pct),
        ("2-star", two_star_leak_pct),
    )
    hits: list[tuple[int, str, float, float, float]] = []
    for row in rows:
        level_no = int(row[0])
        leak_pct = float(row[11])
        for label, threshold in boundaries:
            distance = leak_pct - threshold
            if abs(distance) <= window_pct + 1e-9:
                hits.append((level_no, label, threshold, leak_pct, distance))

    print()
    print(
        "Star-boundary audit "
        f"(window=±{window_pct:.2f} leak points; thresholds from economy.json):"
    )
    if not hits:
        print("- none")
        return
    for level_no, label, threshold, leak_pct, distance in hits:
        sign = "+" if distance >= 0.0 else ""
        print(
            f"- level_{level_no:03d}: leak={leak_pct:.4f}% "
            f"near {label} boundary={threshold:.4f}% "
            f"(distance={sign}{distance:.4f}pp)"
        )


def wave_number(wave: dict) -> int:
    try:
        return int(wave.get("wave", 0))
    except (TypeError, ValueError):
        return 0


def late_wave_level_ramp(economy: dict, level_no: int) -> float:
    rule = economy.get("late_wave_level_ramp", DEFAULT_LATE_WAVE_LEVEL_RAMP)
    if not isinstance(rule, dict):
        rule = DEFAULT_LATE_WAVE_LEVEL_RAMP
    start_level = float(rule.get("start_level", DEFAULT_LATE_WAVE_LEVEL_RAMP["start_level"]))
    full_level = float(rule.get("full_level", DEFAULT_LATE_WAVE_LEVEL_RAMP["full_level"]))
    max_mult = float(rule.get("max_mult", DEFAULT_LATE_WAVE_LEVEL_RAMP["max_mult"]))
    if float(level_no) < start_level:
        return 1.0
    ramp_mult = max_mult
    if full_level > start_level:
        t = max(0.0, min(1.0, (float(level_no) - start_level) / (full_level - start_level)))
        curve_power = max(0.01, float(rule.get("curve_power", DEFAULT_LATE_WAVE_LEVEL_RAMP["curve_power"])))
        ramp_mult = 1.0 + (max_mult - 1.0) * (t ** curve_power)
    final_level = int(rule.get("final_level", DEFAULT_LATE_WAVE_LEVEL_RAMP["final_level"]))
    if level_no >= final_level:
        ramp_mult *= max(1.0, float(rule.get("final_mult", DEFAULT_LATE_WAVE_LEVEL_RAMP["final_mult"])))
    return ramp_mult


def late_wave_damage_ramp(economy: dict, level_no: int, wave_no: int) -> float:
    rule = economy.get("late_wave_damage_ramp", DEFAULT_LATE_WAVE_DAMAGE_RAMP)
    if not isinstance(rule, dict):
        rule = DEFAULT_LATE_WAVE_DAMAGE_RAMP
    if wave_no < int(rule.get("start_wave", DEFAULT_LATE_WAVE_DAMAGE_RAMP["start_wave"])):
        return 1.0
    start_level = float(rule.get("start_level", DEFAULT_LATE_WAVE_DAMAGE_RAMP["start_level"]))
    full_level = float(rule.get("full_level", DEFAULT_LATE_WAVE_DAMAGE_RAMP["full_level"]))
    max_mult = float(rule.get("max_mult", DEFAULT_LATE_WAVE_DAMAGE_RAMP["max_mult"]))
    if float(level_no) < start_level:
        return 1.0
    ramp_mult = max_mult
    if full_level > start_level:
        t = max(0.0, min(1.0, (float(level_no) - start_level) / (full_level - start_level)))
        curve_power = max(0.01, float(rule.get("curve_power", DEFAULT_LATE_WAVE_DAMAGE_RAMP["curve_power"])))
        ramp_mult = 1.0 + (max_mult - 1.0) * (t ** curve_power)
    final_level = int(rule.get("final_level", DEFAULT_LATE_WAVE_DAMAGE_RAMP["final_level"]))
    if level_no >= final_level:
        ramp_mult *= max(1.0, float(rule.get("final_mult", DEFAULT_LATE_WAVE_DAMAGE_RAMP["final_mult"])))
    return ramp_mult


def late_wave_hp_bonus(economy: dict, wave_no: int, boss: bool = False, level_no: int = 0, card_picks: int = 4) -> float:
    key = "late_wave_boss_hp_bonus" if boss else "late_wave_hp_bonus"
    defaults = DEFAULT_LATE_WAVE_BOSS_HP_BONUS if boss else DEFAULT_LATE_WAVE_HP_BONUS
    table = economy.get(key, defaults)
    if not isinstance(table, dict):
        table = defaults
    base = float(table.get(str(wave_no), table.get(wave_no, defaults.get(str(wave_no), 1.0))))
    if wave_no >= 3:
        base *= late_wave_level_ramp(economy, level_no)
        base *= run_skill_hp_pressure(card_picks, economy)
    return base


def late_wave_count_level_ramp(economy: dict, level_no: int, wave_no: int) -> float:
    rule = economy.get("late_wave_count_level_ramp", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP)
    if not isinstance(rule, dict):
        rule = DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP
    if wave_no < int(rule.get("start_wave", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP["start_wave"])):
        return 1.0
    start_level = float(rule.get("start_level", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP["start_level"]))
    full_level = float(rule.get("full_level", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP["full_level"]))
    max_mult = max(1.0, float(rule.get("max_mult", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP["max_mult"])))
    if float(level_no) < start_level:
        return 1.0
    ramp_mult = max_mult
    if full_level > start_level:
        t = max(0.0, min(1.0, (float(level_no) - start_level) / (full_level - start_level)))
        curve_power = max(0.01, float(rule.get("curve_power", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP["curve_power"])))
        ramp_mult = 1.0 + (max_mult - 1.0) * (t ** curve_power)
    final_level = int(rule.get("final_level", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP["final_level"]))
    if level_no >= final_level:
        ramp_mult *= max(1.0, float(rule.get("final_mult", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP["final_mult"])))
    return ramp_mult


def late_wave_count_mult(economy: dict, wave_no: int, level_no: int = 0) -> float:
    table = economy.get("late_wave_count_mult", DEFAULT_LATE_WAVE_COUNT_MULT)
    if not isinstance(table, dict):
        table = DEFAULT_LATE_WAVE_COUNT_MULT
    base = max(1.0, float(table.get(str(wave_no), table.get(wave_no, DEFAULT_LATE_WAVE_COUNT_MULT.get(str(wave_no), 1.0)))))
    return base * late_wave_count_level_ramp(economy, level_no, wave_no)


def level_number(level: dict) -> int:
    try:
        return int(str(level.get("id", "level_000")).split("_")[-1])
    except (TypeError, ValueError):
        return 0


def boss_hp_level_bonus(economy: dict, level: dict) -> float:
    rule = economy.get("boss_hp_level_bonus", DEFAULT_BOSS_HP_LEVEL_BONUS)
    if not isinstance(rule, dict):
        rule = DEFAULT_BOSS_HP_LEVEL_BONUS
    start_level = int(rule.get("start_level", DEFAULT_BOSS_HP_LEVEL_BONUS["start_level"]))
    multiplier = float(rule.get("multiplier", DEFAULT_BOSS_HP_LEVEL_BONUS["multiplier"]))
    return multiplier if level_number(level) >= start_level else 1.0


def boss_survival_hp_ramp(economy: dict, level_no: int) -> float:
    rule = economy.get("boss_survival_hp_ramp", DEFAULT_BOSS_SURVIVAL_HP_RAMP)
    if not isinstance(rule, dict):
        rule = DEFAULT_BOSS_SURVIVAL_HP_RAMP
    start_level = float(rule.get("start_level", DEFAULT_BOSS_SURVIVAL_HP_RAMP["start_level"]))
    full_level = float(rule.get("full_level", DEFAULT_BOSS_SURVIVAL_HP_RAMP["full_level"]))
    max_mult = max(1.0, float(rule.get("max_mult", DEFAULT_BOSS_SURVIVAL_HP_RAMP["max_mult"])))
    if float(level_no) < start_level:
        return 1.0
    ramp_mult = max_mult
    if full_level > start_level:
        t = max(0.0, min(1.0, (float(level_no) - start_level) / (full_level - start_level)))
        curve_power = max(0.01, float(rule.get("curve_power", DEFAULT_BOSS_SURVIVAL_HP_RAMP["curve_power"])))
        ramp_mult = 1.0 + (max_mult - 1.0) * (t ** curve_power)
    final_level = int(rule.get("final_level", DEFAULT_BOSS_SURVIVAL_HP_RAMP["final_level"]))
    if level_no >= final_level:
        ramp_mult *= max(1.0, float(rule.get("final_mult", DEFAULT_BOSS_SURVIVAL_HP_RAMP["final_mult"])))
    return ramp_mult


def estimate_player_dps(
    char_id: str,
    weapon_id: str,
    char_level: int,
    weapon_level: int,
    skill_mult: float,
    fire_rate_profile_id: str = fire_rate_lab.DEFAULT_PROFILE_ID,
) -> float:
    chars = json.loads(CHARS_PATH.read_text(encoding="utf-8"))
    weapons = json.loads(WEAPONS_PATH.read_text(encoding="utf-8"))
    economy = json.loads(ECONOMY_PATH.read_text(encoding="utf-8"))
    char = chars[char_id]
    weapon = weapons[weapon_id]
    base_atk = float(char["base_atk"])
    atk_growth = float(char["atk_growth"])
    fire_rate_mod = float(char.get("fire_rate_mod", 1.0))
    base_atk_coef = float(weapon.get("base_atk_coef", 1.0))
    fire_rate = float(weapon.get("fire_rate", 4.0))
    char_atk_mult = (base_atk / 100.0) * (1.0 + atk_growth * 0.45 * (char_level - 1))
    weapon_dmg_mult = 1.0 + 0.08 * (weapon_level - 1)
    weapon_fr_mult = 1.0 + 0.025 * (weapon_level - 1)
    base_damage = BASE_WEAPON_DAMAGE * base_atk_coef
    damage = base_damage * char_atk_mult * weapon_dmg_mult * CHIP_DAMAGE_MULT * float(economy.get("PLAYER_SHOT_DAMAGE_MULT", 1.0))
    authored_fire_rate = fire_rate * weapon_fr_mult * float(economy.get("PLAYER_FIRE_RATE_MULT", 0.25))
    control_fr = authored_fire_rate * fire_rate_mod
    fr = fire_rate_lab.capped_fire_rate(
        economy,
        fire_rate_profile_id,
        control_fr,
        authored_fire_rate,
    )
    damage *= fire_rate_lab.shot_damage_compensation(
        economy,
        fire_rate_profile_id,
        control_fr,
        fr,
    )
    affinity_mult = 1.10 if weapon.get("element", "physical") == char.get("element_focus", "") else 1.0
    pierce_throughput = 1.18 if char_id == "vanguard" else 1.0
    return damage * fr * skill_mult * affinity_mult * pierce_throughput


def runtime_boss_entries(level: dict, wave: dict) -> list[dict]:
    """Return every boss the runtime queues for this authored wave.

    The primary boss remains on the wave row for backwards compatibility.
    Additional bosses live on ``level.runtime_bosses``; battle.gd consumes the
    same rows. Keeping the expansion here prevents finale-only runtime content
    from disappearing from HP, leak and power-contract calculations again.
    """
    entries: list[dict] = []
    if "boss" in wave:
        entries.append({"type": str(wave["boss"]), "primary": True})
    wave_no = wave_number(wave)
    for extra in level.get("runtime_bosses", []):
        if not isinstance(extra, dict) or int(extra.get("wave", wave_no)) != wave_no:
            continue
        boss_id = str(extra.get("type", ""))
        if boss_id:
            entries.append({**extra, "type": boss_id, "primary": False})
    return entries


def boss_hp_for_entry(level: dict, boss_row: dict, economy: dict, wave_no: int) -> float:
    """Return one authored Boss model's campaign durability.

    Current Bosses own a fixed total durability in bosses.json.  The legacy
    coefficient path remains only for backwards-compatible tooling inputs;
    normal campaign difficulty is expressed by authored Boss quantity.
    """
    fixed_hp = float(boss_row.get("fixed_hp", 0.0))
    if fixed_hp > 0.0:
        return fixed_hp
    level_no = level_number(level)
    card_picks = int(level.get("target_card_picks", 4))
    return (
        float(level.get("base_hp_ref", 50.0))
        * float(boss_row.get("hp_coef", 18.0))
        * float(level.get("difficulty_coef", 1.0))
        * late_wave_hp_bonus(economy, wave_no, True, level_no, card_picks)
        * boss_hp_level_bonus(economy, level)
        * boss_survival_hp_ramp(economy, level_no)
    )


def boss_hp_scale_for_index(level: dict, economy: dict, copy_index: int) -> float:
    """Campaign copies preserve the Boss model's literal authored durability.

    Endless mode owns an independent generated budget table and uses the
    same-type sequence only as an internal split weight. Campaign progression
    is therefore visible in the roster count instead of a hidden copy discount.
    """
    return 1.0


def level_enemy_hp_profile(level: dict, zombies: dict, bosses: dict, economy: dict) -> tuple[float, dict[str, float], int]:
    diff = float(level["difficulty_coef"])
    hp_base = float(level.get("base_hp_ref", 50.0))
    mob_hp = 0.0
    boss_hp_by_id: dict[str, float] = {}
    count = 0
    level_no = level_number(level)
    card_picks = int(level.get("target_card_picks", 4))
    boss_copy_counts: dict[str, int] = {}
    for wave in level.get("waves", []):
        wave_no = wave_number(wave)
        mob_bonus = wave_hp_coef(wave) * late_wave_hp_bonus(
            economy, wave_no, level_no=level_no, card_picks=card_picks
        )
        count_mult = late_wave_count_mult(economy, wave_no, level_no)
        # Normal spawns
        for spawn in wave.get("spawns", []):
            t = spawn.get("type", "")
            z = zombies.get(t, {})
            hp = hp_base * float(z.get("hp_coef", 1.0)) * diff * mob_bonus
            c = int(round(int(spawn.get("count", 0)) * count_mult))
            mob_hp += hp * c
            count += c
        # Primary + data-authored runtime bosses (last wave typically).
        for boss_entry in runtime_boss_entries(level, wave):
            boss_id = boss_entry["type"]
            boss_row = bosses.get(boss_id, {})
            # Boss durability is an identity-level stat. Repeated copies use
            # the authored pacing sequence shared with battle.gd; the first
            # ten onboarding stages remain exempt by the same data rule.
            copy_index = boss_copy_counts.get(boss_id, 0)
            boss_copy_counts[boss_id] = copy_index + 1
            boss_hp = (
                boss_hp_for_entry(level, boss_row, economy, wave_no)
                * boss_hp_scale_for_index(level, economy, copy_index)
            )
            boss_hp_by_id[boss_id] = boss_hp_by_id.get(boss_id, 0.0) + boss_hp
            count += 1
        # Boss support mobs
        for spawn in wave.get("support", []):
            t = spawn.get("type", "")
            z = zombies.get(t, {})
            hp = hp_base * float(z.get("hp_coef", 1.0)) * diff * mob_bonus
            c = int(round(int(spawn.get("count", 0)) * count_mult))
            mob_hp += hp * c
            count += c
    return mob_hp, boss_hp_by_id, count


def wave_hp_coef(wave: dict) -> float:
    """Optional per-wave mob durability; absent is exactly neutral.

    Fixed-HP campaign Bosses deliberately do not consume this coefficient,
    matching battle.gd's authored Boss identity path.
    """
    return max(0.01, float(wave.get("hp_coef", 1.0)))


def level_enemy_hp_split(level: dict, zombies: dict, bosses: dict, economy: dict) -> tuple[float, float, int]:
    mob_hp, boss_hp_by_id, count = level_enemy_hp_profile(level, zombies, bosses, economy)
    return mob_hp, sum(boss_hp_by_id.values()), count


def level_enemy_hp(level: dict, zombies: dict, bosses: dict, economy: dict) -> tuple[float, int]:
    mob_hp, boss_hp, count = level_enemy_hp_split(level, zombies, bosses, economy)
    return mob_hp + boss_hp, count


def level_spawn_time(level: dict, economy: dict) -> float:
    duration = 0.0
    for wave in level.get("waves", []):
        count_mult = late_wave_count_mult(economy, wave_number(wave), level_number(level))
        for spawn in wave.get("spawns", []) + wave.get("support", []):
            duration += int(round(int(spawn.get("count", 0)) * count_mult)) * float(spawn.get("interval", 0.8))
    return duration


def estimate_skill_mult(level: dict) -> float:
    cards = int(level.get("target_card_picks", 4))
    # This is effective crowd throughput, not only character-sheet single-target
    # DPS. Later card budgets combine lanes, pierce, chain/splash, status damage
    # and cadence, so their contribution compounds while remaining below a
    # perfect all-DPS draft.
    return estimate_skill_throughput(cards)


def leak_damage(level: dict, zombies: dict, bosses: dict, economy: dict, _is_boss_level: bool) -> float:
    """Expected breach damage given a leak rate.

    The elevated boss leak rate applies per wave, not per level (design/24
    Phase 2). Waves 1-4 of a boss level are ordinary mob waves with no boss on
    the field, and nothing about wave 5 makes them leak 2.4x harder; charging
    the whole level the boss rate is what pushed every boss level to 66-121%
    leak - 60-79% of that damage came from waves that have no boss in them.
    """
    total = 0.0
    level_no = level_number(level)
    for wave in level.get("waves", []):
        wave_no = wave_number(wave)
        leak = BOSS_LEAK if "boss" in wave else NORMAL_LEAK
        damage_mult = late_wave_damage_ramp(economy, level_no, wave_no)
        count_mult = late_wave_count_mult(economy, wave_no, level_no)
        wave_damage = 0.0
        for spawn in wave.get("spawns", []):
            t = spawn.get("type", "")
            z = zombies.get(t, {})
            # Breach damage is configured from bd_coef only at runtime; enemy
            # HP/difficulty/late-wave multipliers must not inflate it here.
            bd = GLOBAL_DMG_BASE * float(z.get("bd_coef", 1.0)) * damage_mult
            wave_damage += bd * int(round(int(spawn.get("count", 0)) * count_mult))
        for boss_entry in runtime_boss_entries(level, wave):
            boss_id = boss_entry["type"]
            boss_row = bosses.get(boss_id, {})
            bd = GLOBAL_DMG_BASE * float(boss_row.get("bd_coef", 4.0)) * damage_mult
            wave_damage += bd
        for spawn in wave.get("support", []):
            t = spawn.get("type", "")
            z = zombies.get(t, {})
            bd = GLOBAL_DMG_BASE * float(z.get("bd_coef", 1.0)) * damage_mult
            wave_damage += bd * int(round(int(spawn.get("count", 0)) * count_mult))
        total += wave_damage * leak
    return total


def is_boss_level(level: dict) -> bool:
    return any("boss" in w for w in level.get("waves", []))


def runtime_boss_contract_clear_time(
    level: dict,
    challenge_mob_hp: float,
    challenge_hp_mult: float,
    economy: dict,
) -> float | None:
    """Return the equal-recommendation clear time for a runtime multi-Boss.

    ``power_contract`` already owns the effective HP of every authored Boss,
    including mechanic time and immunity/weakness handling.  Translating its
    crowd/Boss capacities with the ruler's calibration constants gives the
    reference encounter time at exactly 1.0 power ratio.  This is intentionally
    limited to runtime-added Bosses: ordinary levels retain the historical
    campaign trend estimator above, while the finale cannot silently fall back
    to a single-Boss model again.
    """
    if not level.get("runtime_bosses"):
        return None
    requirement = level.get("clear_requirement", {})
    contract = requirement.get("power_contract", {}) if isinstance(requirement, dict) else {}
    if not isinstance(contract, dict) or contract.get("model") != "bottleneck_v5":
        return None
    ruler = economy.get("power_ruler", {})
    if not isinstance(ruler, dict):
        return None
    crowd_capacity = max(float(contract.get("crowd_capacity", 0.0)), 0.0)
    boss_capacity = max(float(contract.get("boss_capacity", 0.0)), 0.0)
    boss_effective_hp = max(float(contract.get("boss_effective_hp", 0.0)), 0.0)
    crowd_dps_per_capacity = max(float(ruler.get("crowd_dps_per_capacity", 0.0)), 0.0)
    boss_dps_per_capacity = max(float(ruler.get("boss_dps_per_capacity", 0.0)), 0.0)
    if crowd_capacity <= 0.0 or crowd_dps_per_capacity <= 0.0:
        return None
    crowd_time = challenge_mob_hp / (crowd_capacity * crowd_dps_per_capacity)
    boss_time = 0.0
    if boss_effective_hp > 0.0:
        if boss_capacity <= 0.0 or boss_dps_per_capacity <= 0.0:
            return None
        boss_time = (
            boss_effective_hp * max(challenge_hp_mult, 0.1)
            / (boss_capacity * boss_dps_per_capacity)
        )
    return crowd_time + boss_time


def main() -> int:
    args = parse_args()
    levels: list[dict] = json.loads(LEVELS_PATH.read_text(encoding="utf-8"))
    zombies: dict[str, dict] = json.loads(ZOMBIES_PATH.read_text(encoding="utf-8"))
    bosses: dict[str, dict] = json.loads(BOSSES_PATH.read_text(encoding="utf-8"))
    characters: dict[str, dict] = json.loads(CHARS_PATH.read_text(encoding="utf-8"))
    weapons: dict[str, dict] = json.loads(WEAPONS_PATH.read_text(encoding="utf-8"))
    economy: dict = json.loads(ECONOMY_PATH.read_text(encoding="utf-8"))
    challenges: dict = json.loads(CHALLENGES_PATH.read_text(encoding="utf-8"))
    runtime_benchmark: dict = json.loads(PHYSICAL_RUNTIME_BENCHMARK_PATH.read_text(encoding="utf-8"))
    runtime_builds: dict = runtime_benchmark["best_same_loadout"]
    profile_id = str(args.fire_rate_profile)
    if profile_id not in fire_rate_lab.profile_ids(economy):
        available = ", ".join(fire_rate_lab.profile_ids(economy))
        print(f"Unknown fire-rate profile '{profile_id}'. Available: {available}")
        return 2
    max_reference_dps = character_dps.best_result(
        "vanguard", fire_rate_profile_id=profile_id).total_dps
    legacy_reference_dps = estimate_player_dps(
        "vanguard",
        "weapon_railgun",
        int(characters["vanguard"].get("max_level", 40)),
        int(weapons["weapon_railgun"].get("max_level", 50)),
        estimate_skill_mult(levels[-1]),
        profile_id,
    )
    max_modern_dps_scale = max_reference_dps / max(legacy_reference_dps, 1.0)
    max_raw_autocannon_dps = estimate_player_dps(
        "vanguard",
        "weapon_autocannon",
        int(characters["vanguard"].get("max_level", 40)),
        int(weapons["weapon_autocannon"].get("max_level", 50)),
        1.0,
        profile_id,
    )
    max_card_throughput = estimate_skill_mult(levels[-1])

    mode_name = "challenge" if args.challenge else "normal"
    print(f"Simulation mode: {mode_name}")
    print(f"Fire-rate profile: {profile_id}")
    print(f"{'level':<11} {'ch':<3} {'recom':<5} {'coef':<6} {'cards':>5} {'spawn':>6} {'hp_total':>9} {'dps_ns':>6} {'dps_ws':>6} {'t_ns':>6} {'t_ws':>6} {'leak%':>6}  notes")
    print("-" * 110)

    rows = []
    for lv in levels:
        n = int(lv["id"].split("_")[1])
        mob_hp, boss_hp, count = level_enemy_hp_split(lv, zombies, bosses, economy)
        challenge_rule = challenge_rule_for_level(lv, challenges) if args.challenge else challenge_rule_for_level(lv, {})
        challenge_hp_mult = challenge_rule["hp_mult"]
        mob_hp *= challenge_hp_mult
        boss_hp *= challenge_hp_mult
        hp_total = mob_hp + boss_hp
        recommended_level = int(lv.get("recommend_level", n))
        char_level = min(recommended_level, int(characters["vanguard"].get("max_level", 40)))
        weapon_level = min(recommended_level, int(weapons["weapon_autocannon"].get("max_level", 50)))
        raw_progression_dps = estimate_player_dps(
            "vanguard", "weapon_autocannon", char_level, weapon_level, 1.0, profile_id)
        dps_ns = raw_progression_dps
        skill_mult = estimate_skill_mult(lv)
        dps_ws = estimate_player_dps(
            "vanguard", "weapon_autocannon", char_level, weapon_level, skill_mult, profile_id)
        # The original campaign estimator predates armor/chip/pet/signature
        # growth and active-skill DPS. Blend toward the current measured max
        # calibration with progression level instead of treating late builds
        # as bare character + weapon loadouts.
        progression_t = max(0.0, min(1.0, float(char_level - 1) / 39.0))
        modern_dps_scale = 1.0 + (max_modern_dps_scale - 1.0) * progression_t
        dps_ns *= modern_dps_scale
        dps_ws *= modern_dps_scale
        time_ns = hp_total / max(dps_ns, 1.0)
        time_ws = hp_total / max(dps_ws, 1.0)
        spawn_time = level_spawn_time(lv, economy)
        boss_lvl = is_boss_level(lv)
        if boss_lvl and n >= 50:
            # Boss 50+ durability is calibrated against the real all-skill
            # projectile benchmark. Scale its measured max throughput back to
            # the level's recommended permanent progression and card budget.
            # Chapter 8+ is the authored free graduation corridor.  Keep the
            # historical autocannon curve for ordinary-wave comparability, but
            # judge its Boss phase with the measured scattergun graduation
            # family rather than pretending a deliberately weaker Boss weapon
            # is still the recommended endgame loadout.
            runtime_weapon_id = "weapon_scattergun" if n >= 71 else "weapon_autocannon"
            runtime_profile = runtime_builds[runtime_weapon_id]
            permanent_progress = raw_progression_dps / max(
                max_raw_autocannon_dps, 1.0)
            card_progress = skill_mult / max(max_card_throughput, 1.0)
            crowd_dps = float(runtime_profile["crowd_dps"]) * permanent_progress * card_progress
            boss_dps = float(runtime_profile["boss_dps"]) * permanent_progress * card_progress
            phase_weight = 1.11
            # Lower-bound protection (design/24 Phase 0). The benchmark's
            # crowd_dps is peak throughput measured against a saturated 45-enemy
            # formation, so scaling it down by progression alone still makes mob
            # HP effectively free (0.1-1.3s to clear millions of HP). Bound the
            # mob phase by the same campaign-wide crowd model every non-boss
            # level uses - estimate_skill_mult is documented as effective crowd
            # throughput, so dps_ws is the comparable clear rate. Without this
            # the 50/55/60/65 boss levels reported 2.0/10.1/16.0/19.2s and were
            # tuned against those bogus numbers.
            # The boss phase is deliberately NOT bounded the same way: dps_ws
            # folds in crowd-throughput multipliers and is not a valid
            # single-target rate, while boss_dps is the measured single-target
            # authority the endgame matrix is calibrated on.
            effective_crowd_dps = min(crowd_dps, dps_ws)
            time_ws = mob_hp / max(effective_crowd_dps, 1.0) + boss_hp / max(boss_dps, 1.0) * phase_weight
        # Runtime Boss rows are now the normal campaign quantity authoring
        # mechanism, not a finale-only exception. Their fixed HP is already in
        # `boss_hp`; replacing the physical estimate with a display-contract
        # reference time here would make the simulator judge its own label
        # instead of the encounter. Keep the real HP/DPS path authoritative.
        leak = leak_damage(lv, zombies, bosses, economy, boss_lvl)
        if args.challenge:
            # HP pressure is represented exactly in clear time above. Faster
            # enemies and more frequent mechanics reduce the control window,
            # while breach_damage_mult is the exact runtime damage multiplier.
            # Together they scale the normal model's expected breach pressure
            # without inventing an additional global challenge constant.
            leak *= challenge_rule["speed_mult"]
            leak *= challenge_rule["breach_damage_mult"]
            leak *= challenge_rule["mechanic_rate_mult"]
        # base_hp_ref * armor_mult is the real starting HP. Boss levels add the
        # design/24 Phase 2 base-line cushion, exactly as battle.gd does.
        boss_base_hp_mult = boss_base_hp_cushion(economy, n) if boss_lvl else 1.0
        leak_pct = min(100.0, leak / max(float(lv.get("base_hp_ref", 100)) * ARMOR_HP_MULT * boss_base_hp_mult, 1.0) * 100.0)
        rows.append((n, lv.get("chapter", 0), char_level, float(lv["difficulty_coef"]),
                     int(lv.get("target_card_picks", 0)), spawn_time, hp_total, dps_ns, dps_ws, time_ns, time_ws, leak_pct, boss_lvl))

    rows.sort(key=lambda r: r[0])
    three_star_leak_pct, two_star_leak_pct = star_leak_caps(economy)
    chapter_star_totals = {chapter: 0 for chapter in range(1, 11)}
    chapter_min_stars = {chapter: 3 for chapter in range(1, 11)}
    for n, ch, recom, coef, cards, spawn_time, hp, dps_ns, dps_ws, t_ns, t_ws, leak_pct, boss_lvl in rows:
        notes = []
        if boss_lvl:
            notes.append("BOSS")
        if t_ns < spawn_time * 0.72 and not boss_lvl:
            notes.append("LOW_PRESSURE")
        if t_ns > spawn_time * 1.18:
            notes.append("BUILD_CHECK")
        if t_ws > spawn_time * 0.85:
            notes.append("HARD")
        # Predicted star rating, converted from the single source of truth in
        # data/economy.json.star_thresholds (design/24 Phase 1). The runtime
        # rates surviving base HP; leak% is the same quantity inverted.
        if leak_pct > two_star_leak_pct:
            notes.append("1★")
            stars = 1
        elif leak_pct > three_star_leak_pct:
            notes.append("2★")
            stars = 2
        else:
            notes.append("3★")
            stars = 3
        chapter_star_totals[int(ch)] += stars
        chapter_min_stars[int(ch)] = min(chapter_min_stars[int(ch)], stars)
        line = f"level_{n:03d}  ch{ch:<2} {recom:<5} {coef:<6.2f} {cards:>5} {spawn_time:>6.1f} {hp:>9.0f} {dps_ns:>6.0f} {dps_ws:>6.0f} {t_ns:>6.1f} {t_ws:>6.1f} {leak_pct:>5.0f}%  {' '.join(notes)}"
        print(line)

    times_ws = [r[10] for r in rows]
    print()
    print(f"With-skill avg clear time: {sum(times_ws)/len(times_ws):.1f}s")
    print(f"With-skill min/max: {min(times_ws):.1f}s / {max(times_ws):.1f}s")
    too_easy = sum(1 for r in rows if r[10] < 30)
    def clear_time_cap(level_no: int) -> float:
        if level_no >= 99:
            # The finale is intentionally a graduation spike. The dedicated
            # endgame matrix proves maxed counter-builds remain viable; this
            # generic autocannon model deliberately represents the slow clear.
            return 460.0
        if level_no >= 90:
            # Recalibrated by design/24 Phase 0: the 330s guard was set while the
            # boss branch understated 50-95 clear times (level_095 read 188.6s).
            # With the mob phase bounded by the campaign crowd model it reads
            # 334.4s, which is consistent with the 460s finale allowance below.
            return 350.0
        if level_no >= 80:
            return 310.0
        if level_no >= 70:
            return 245.0
        if level_no >= 60:
            return 190.0
        return 180.0

    too_hard_rows = [r for r in rows if r[10] > clear_time_cap(r[0])]
    print(f"Levels < 30s (with skill): {too_easy}")
    print(f"Levels above phase-specific clear-time cap: {len(too_hard_rows)}")
    if args.star_boundary_audit:
        print_star_boundary_audit(
            rows,
            three_star_leak_pct,
            two_star_leak_pct,
            args.star_boundary_window,
        )
    errors: list[str] = []
    if too_hard_rows:
        details = ", ".join(f"level_{row[0]:03d}={row[10]:.1f}s>{clear_time_cap(row[0]):.0f}s" for row in too_hard_rows)
        errors.append(f"campaign contains an HP wall above its phase cap: {details}")
    finale_hp = rows[-1][6]
    prior_peak = max(row[6] for row in rows[:-1])
    if finale_hp < prior_peak * 1.02:
        errors.append(f"final boss HP {finale_hp:.0f} must exceed prior peak {prior_peak:.0f}")
    if args.challenge:
        fully_breached = [row for row in rows if row[11] >= 100.0]
        if fully_breached:
            details = ", ".join(f"level_{row[0]:03d}" for row in fully_breached)
            errors.append(f"challenge contains a 100% breach failure: {details}")
        total_challenge_stars = sum(chapter_star_totals.values())
        print("Challenge chapter summary:")
        for chapter in range(1, 11):
            print(
                f"- chapter_{chapter:02d}: stars={chapter_star_totals[chapter]} "
                f"min_level_stars={chapter_min_stars[chapter]}★"
            )
            if chapter_min_stars[chapter] < 1:
                errors.append(f"chapter_{chapter:02d} has no winnable challenge star")
        print(f"Challenge obtainable stars: {total_challenge_stars}")
        if total_challenge_stars < 19:
            errors.append(f"challenge obtainable stars {total_challenge_stars} must be at least 19")
    if errors:
        print("Balance simulation failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("Balance simulation OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
