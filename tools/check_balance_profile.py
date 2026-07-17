#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

from combat_power_model import run_skill_hp_pressure

ROOT = Path(__file__).resolve().parents[1]


def load(name: str):
    return json.loads((ROOT / "data" / f"{name}.json").read_text(encoding="utf-8"))


DEFAULT_LATE_WAVE_HP_BONUS = {"3": 1.45, "4": 1.85, "5": 2.30}
DEFAULT_LATE_WAVE_COUNT_MULT = {"4": 2.0, "5": 3.0}
DEFAULT_LATE_WAVE_BOSS_HP_BONUS = {"3": 1.30, "4": 1.50, "5": 1.75}
DEFAULT_LATE_WAVE_LEVEL_RAMP = {"start_level": 50, "full_level": 98, "max_mult": 1.80, "curve_power": 1.0, "final_level": 99, "final_mult": 1.20}
DEFAULT_LATE_WAVE_DAMAGE_RAMP = {"start_level": 50, "full_level": 98, "start_wave": 3, "max_mult": 2.0, "curve_power": 1.0, "final_level": 99, "final_mult": 1.15}
DEFAULT_BOSS_HP_LEVEL_BONUS = {"start_level": 20, "multiplier": 2.0}
NORMAL_DURATION_MAX = 155.0
BOSS_DURATION_MAX = 190.0


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


def late_wave_count_mult(economy: dict, wave_no: int) -> float:
    table = economy.get("late_wave_count_mult", DEFAULT_LATE_WAVE_COUNT_MULT)
    if not isinstance(table, dict):
        table = DEFAULT_LATE_WAVE_COUNT_MULT
    return max(1.0, float(table.get(str(wave_no), table.get(wave_no, DEFAULT_LATE_WAVE_COUNT_MULT.get(str(wave_no), 1.0)))))


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


def level_pressure(level: dict, zombies: dict, bosses: dict, economy: dict) -> tuple[float, float, int]:
    pressure = 0.0
    duration = 0.0
    boss_count = 0
    hp_base = float(level.get("base_hp_ref", 50.0)) / 50.0
    boss_level_bonus = boss_hp_level_bonus(economy, level)
    level_no = level_number(level)
    card_picks = int(level.get("target_card_picks", 4))
    for wave in level.get("waves", []):
        wave_no = wave_number(wave)
        mob_bonus = late_wave_hp_bonus(economy, wave_no, level_no=level_no, card_picks=card_picks)
        damage_bonus = late_wave_damage_ramp(economy, level_no, wave_no)
        count_mult = late_wave_count_mult(economy, wave_no)
        for group in wave.get("spawns", []):
            row = zombies[group["type"]]
            count = int(round(int(group.get("count", 1)) * count_mult))
            pressure += count * float(row.get("hp_coef", 1.0)) * mob_bonus * float(row.get("bd_coef", 1.0)) * damage_bonus
            duration += count * float(group.get("interval", 0.8))
        if "boss" in wave:
            boss_count += 1
            pressure += float(bosses[wave["boss"]].get("hp_coef", 1.0)) * late_wave_hp_bonus(economy, wave_no, True, level_no, card_picks) * boss_level_bonus * 8.0 * damage_bonus
        for group in wave.get("support", []):
            row = zombies[group["type"]]
            count = int(round(int(group.get("count", 1)) * count_mult))
            pressure += count * float(row.get("hp_coef", 1.0)) * mob_bonus * float(row.get("bd_coef", 1.0)) * damage_bonus
            duration += count * float(group.get("interval", 0.8))
    return pressure * hp_base * float(level.get("difficulty_coef", 1.0)), duration, boss_count


def level_xp_total(level: dict, zombies: dict, bosses: dict, economy: dict) -> int:
    total = 0
    for wave in level.get("waves", []):
        count_mult = late_wave_count_mult(economy, wave_number(wave))
        for group in wave.get("spawns", []) + wave.get("support", []):
            row = zombies[group["type"]]
            total += int(round(int(group.get("count", 1)) * count_mult)) * int(row.get("run_xp", 1))
        if "boss" in wave:
            total += int(bosses[wave["boss"]].get("run_xp", 20))
    return total


def predicted_card_picks(level: dict, xp_total: int) -> int:
    threshold = int(level.get("xp_first_offer", 16))
    growth = float(level.get("xp_offer_growth", 18))
    ramp = float(level.get("xp_offer_ramp", 4))
    cards = 0
    while threshold <= xp_total and cards < 16:
        cards += 1
        threshold += int(round(growth + float(cards) * ramp))
    return cards


def validate_card_budget(level: dict, xp_total: int, errors: list[str]) -> None:
    target_cards = int(level.get("target_card_picks", 0))
    if target_cards < 1:
        errors.append(f"{level['id']} target_card_picks must be positive")
        return
    if target_cards > 12:
        errors.append(f"{level['id']} target_card_picks too high for mobile pacing: {target_cards}")
    if xp_total <= target_cards:
        errors.append(f"{level['id']} XP budget too small for {target_cards} card picks: xp={xp_total}")
        return
    thresholds = [round(float(xp_total) * float(k) / float(target_cards + 1)) for k in range(1, target_cards + 1)]
    if any(thresholds[i] <= thresholds[i - 1] for i in range(1, len(thresholds))):
        errors.append(f"{level['id']} card thresholds are not strictly increasing: {thresholds}")


def weapon_effective_dps(weapon: dict) -> float:
    # Rough effective DPS: raw cadence x special-effect multipliers. Meant for
    # relative comparison between weapons, not absolute combat numbers.
    dps = float(weapon.get("base_atk_coef", 1.0)) * float(weapon.get("fire_rate", 1.0))
    special = weapon.get("special", {})
    pellets = int(special.get("pellets", 1))
    if pellets > 1:
        dps *= pellets * 0.62  # spread shots rarely all connect
    dps *= 1.0 + 0.18 * int(special.get("pierce", 0))
    dps *= 1.0 + 0.45 * int(special.get("chain", 0))
    if special.get("splash") or special.get("cloud"):
        dps *= 1.3
    dps *= 1.0 + 0.8 * (float(special.get("burn", 0.0)) + float(special.get("poison", 0.0)))
    dps *= 1.0 + 0.4 * float(special.get("slow", 0.0))
    return dps


def check_weapon_dps(weapons: dict, errors: list[str]) -> list[tuple[str, str, float]]:
    by_rarity: dict[str, list[tuple[str, float]]] = {}
    ranking: list[tuple[str, str, float]] = []
    for weapon_id, row in weapons.items():
        rarity = str(row.get("rarity", "common"))
        dps = weapon_effective_dps(row)
        by_rarity.setdefault(rarity, []).append((weapon_id, dps))
        ranking.append((weapon_id, rarity, dps))
    # Same-rarity spread must stay bounded so no weapon is a clear "graduation" pick.
    for rarity, entries in by_rarity.items():
        if len(entries) < 2:
            continue
        values = [dps for _, dps in entries]
        spread = max(values) / max(min(values), 1e-6)
        if spread > 2.6:
            top = max(entries, key=lambda e: e[1])[0]
            bottom = min(entries, key=lambda e: e[1])[0]
            errors.append(
                f"weapon DPS spread too wide within '{rarity}': {spread:.2f}x "
                f"({top} >> {bottom})"
            )
    # Rarity must mean power: each tier's weakest weapon should be at least as
    # strong as the previous tier's, so legendaries are never outclassed by commons.
    rarity_order = ["common", "rare", "epic", "legendary"]
    tier_min: list[tuple[str, float]] = []
    for rarity in rarity_order:
        entries = by_rarity.get(rarity)
        if entries:
            tier_min.append((rarity, min(dps for _, dps in entries)))
    for i in range(1, len(tier_min)):
        prev_rarity, prev_min = tier_min[i - 1]
        cur_rarity, cur_min = tier_min[i]
        if cur_min < prev_min * 0.98:
            errors.append(
                f"weapon rarity power inverted: '{cur_rarity}' floor {cur_min:.2f} "
                f"< '{prev_rarity}' floor {prev_min:.2f}"
            )
    ranking.sort(key=lambda e: e[2], reverse=True)
    return ranking


def unlock_costs(*tables: dict) -> list[int]:
    costs: list[int] = []
    for table in tables:
        for row in table.values():
            costs.append(int(row.get("unlock_cost_star", 0)))
    return sorted(costs)


def main() -> int:
    zombies = load("zombies")
    bosses = load("bosses")
    economy = load("economy")
    levels = load("levels")
    characters = load("characters")
    weapons = load("weapons")
    armors = load("armors")
    chips = load("chips")
    pets = load("pets")
    skills = load("skills")

    errors: list[str] = []
    pressures = [level_pressure(level, zombies, bosses, economy)[0] for level in levels]
    for i in range(1, len(pressures)):
        prev = pressures[i - 1]
        cur = pressures[i]
        level_id = levels[i]["id"]
        _, _, boss_count = level_pressure(levels[i], zombies, bosses, economy)
        spike_limit = 4.25 if boss_count else 3.2
        if cur > prev * spike_limit:
            errors.append(f"{level_id} pressure spikes too hard: {prev:.1f} -> {cur:.1f}")
        if cur < prev * 0.18 and (i + 1) % 10 not in (1, 6):
            errors.append(f"{level_id} pressure drops too hard: {prev:.1f} -> {cur:.1f}")

    for level in levels:
        pressure, duration, boss_count = level_pressure(level, zombies, bosses, economy)
        # Late waves intentionally spawn more enemies now: wave 4 uses x2 count
        # and wave 5 uses x3 count. Keep the old lower bounds, but validate
        # against the current long-form pacing envelope instead of the pre-ramp
        # 105s/140s caps.
        if boss_count and duration > BOSS_DURATION_MAX:
            errors.append(f"{level['id']} boss duration too long: {duration:.1f}s")
        if not boss_count and duration > NORMAL_DURATION_MAX:
            errors.append(f"{level['id']} normal duration too long: {duration:.1f}s")
        if not boss_count and duration < 45.0:
            errors.append(f"{level['id']} normal duration too short: {duration:.1f}s")
        if boss_count and duration < 70.0:
            errors.append(f"{level['id']} boss duration too short: {duration:.1f}s")
        if pressure <= 0.0:
            errors.append(f"{level['id']} has non-positive pressure")
        xp_total = level_xp_total(level, zombies, bosses, economy)
        validate_card_budget(level, xp_total, errors)

    costs = unlock_costs(characters, weapons, armors, chips, pets)
    if max(costs) < 200:
        errors.append("collection unlocks end too early; max star cost should reach late campaign")
    for milestone in (30, 90, 150, 210):
        if not any(milestone - 12 <= cost <= milestone + 12 for cost in costs):
            errors.append(f"no collection unlock near {milestone} stars")

    if len(skills) < 16:
        errors.append("skill pool should contain at least 16 skills")
    if len(characters) < 4:
        errors.append("character roster should contain 4 archetypes")

    weapon_ranking = check_weapon_dps(weapons, errors)

    if errors:
        print("Balance profile check failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Balance profile OK")
    print(f"pressure range: {min(pressures):.1f} -> {max(pressures):.1f}")
    print(f"unlock star range: {min(costs)} -> {max(costs)}")
    print("weapon effective DPS (relative):")
    for weapon_id, rarity, dps in weapon_ranking:
        print(f"  {dps:6.2f}  [{rarity:9}] {weapon_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
