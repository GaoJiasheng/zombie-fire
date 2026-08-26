#!/usr/bin/env python3
from __future__ import annotations

import copy
import json
from pathlib import Path

import simulate_balance as sim

from combat_power_model import run_skill_hp_pressure
from generate_wave_pressure import (
    FIXTURE_PATH as WAVE_PRESSURE_FIXTURE_PATH,
    config as wave_pressure_config,
    pilot_scope_ids,
    restore_target_rows as restore_wave_pressure_target_rows,
)

ROOT = Path(__file__).resolve().parents[1]


def load(name: str):
    return json.loads((ROOT / "data" / f"{name}.json").read_text(encoding="utf-8"))


DEFAULT_LATE_WAVE_HP_BONUS = {"3": 1.45, "4": 1.85, "5": 2.30}
DEFAULT_LATE_WAVE_COUNT_MULT = {"4": 2.0, "5": 3.0}
DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP = {"start_level": 55, "full_level": 90, "start_wave": 3, "max_mult": 1.25, "curve_power": 1.0, "final_level": 99, "final_mult": 1.08}
DEFAULT_LATE_WAVE_BOSS_HP_BONUS = {"3": 1.30, "4": 1.50, "5": 1.75}
DEFAULT_LATE_WAVE_LEVEL_RAMP = {"start_level": 50, "full_level": 98, "max_mult": 2.05, "curve_power": 1.0, "final_level": 99, "final_mult": 1.12}
DEFAULT_LATE_WAVE_DAMAGE_RAMP = {"start_level": 50, "full_level": 98, "start_wave": 3, "max_mult": 1.0, "curve_power": 1.0, "final_level": 99, "final_mult": 1.0}
DEFAULT_BOSS_HP_LEVEL_BONUS = {"start_level": 20, "multiplier": 2.0}
DEFAULT_BOSS_SURVIVAL_HP_RAMP = {"start_level": 50, "full_level": 98, "max_mult": 56.0, "curve_power": 1.15, "final_level": 99, "final_mult": 1.08}
NORMAL_DURATION_MAX = 180.0
BOSS_DURATION_MAX = 215.0


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


def late_wave_count_mult(economy: dict, wave_no: int, level_no: int = 0) -> float:
    table = economy.get("late_wave_count_mult", DEFAULT_LATE_WAVE_COUNT_MULT)
    if not isinstance(table, dict):
        table = DEFAULT_LATE_WAVE_COUNT_MULT
    base = max(1.0, float(table.get(str(wave_no), table.get(wave_no, DEFAULT_LATE_WAVE_COUNT_MULT.get(str(wave_no), 1.0)))))
    rule = economy.get("late_wave_count_level_ramp", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP)
    if not isinstance(rule, dict) or wave_no < int(rule.get("start_wave", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP["start_wave"])):
        return base
    start_level = float(rule.get("start_level", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP["start_level"]))
    if float(level_no) < start_level:
        return base
    full_level = float(rule.get("full_level", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP["full_level"]))
    max_mult = max(1.0, float(rule.get("max_mult", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP["max_mult"])))
    ramp = max_mult
    if full_level > start_level:
        t = max(0.0, min(1.0, (float(level_no) - start_level) / (full_level - start_level)))
        ramp = 1.0 + (max_mult - 1.0) * (t ** max(0.01, float(rule.get("curve_power", 1.0))))
    if level_no >= int(rule.get("final_level", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP["final_level"])):
        ramp *= max(1.0, float(rule.get("final_mult", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP["final_mult"])))
    return base * ramp


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
    if float(level_no) < start_level:
        return 1.0
    full_level = float(rule.get("full_level", DEFAULT_BOSS_SURVIVAL_HP_RAMP["full_level"]))
    max_mult = max(1.0, float(rule.get("max_mult", DEFAULT_BOSS_SURVIVAL_HP_RAMP["max_mult"])))
    ramp = max_mult
    if full_level > start_level:
        t = max(0.0, min(1.0, (float(level_no) - start_level) / (full_level - start_level)))
        ramp = 1.0 + (max_mult - 1.0) * (t ** max(0.01, float(rule.get("curve_power", 1.15))))
    if level_no >= int(rule.get("final_level", DEFAULT_BOSS_SURVIVAL_HP_RAMP["final_level"])):
        ramp *= max(1.0, float(rule.get("final_mult", DEFAULT_BOSS_SURVIVAL_HP_RAMP["final_mult"])))
    return ramp


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
        mob_bonus = sim.wave_hp_coef(wave) * late_wave_hp_bonus(
            economy, wave_no, level_no=level_no, card_picks=card_picks
        )
        damage_bonus = late_wave_damage_ramp(economy, level_no, wave_no)
        count_mult = late_wave_count_mult(economy, wave_no, level_no)
        for group in wave.get("spawns", []):
            row = zombies[group["type"]]
            count = int(round(int(group.get("count", 1)) * count_mult))
            pressure += count * float(row.get("hp_coef", 1.0)) * mob_bonus * float(row.get("bd_coef", 1.0)) * damage_bonus
            duration += count * float(group.get("interval", 0.8))
        if "boss" in wave:
            boss_count += 1
            pressure += float(bosses[wave["boss"]].get("hp_coef", 1.0)) * late_wave_hp_bonus(economy, wave_no, True, level_no, card_picks) * boss_level_bonus * boss_survival_hp_ramp(economy, level_no) * 8.0 * damage_bonus
        for group in wave.get("support", []):
            row = zombies[group["type"]]
            count = int(round(int(group.get("count", 1)) * count_mult))
            pressure += count * float(row.get("hp_coef", 1.0)) * mob_bonus * float(row.get("bd_coef", 1.0)) * damage_bonus
            duration += count * float(group.get("interval", 0.8))
    return pressure * hp_base * float(level.get("difficulty_coef", 1.0)), duration, boss_count


def level_xp_total(level: dict, zombies: dict, bosses: dict, economy: dict) -> int:
    authored_budget = int(level.get("run_xp_budget", 0))
    if authored_budget > 0:
        return authored_budget
    total = 0
    for wave in level.get("waves", []):
        count_mult = late_wave_count_mult(economy, wave_number(wave), level_number(level))
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


def is_premium_collection_row(row: dict) -> bool:
    return bool(str(row.get("premium_entitlement", "")).strip())


def unlock_costs(*tables: dict) -> list[int]:
    costs: list[int] = []
    for table in tables:
        for row in table.values():
            # Permanent IAP equipment is not bought with campaign stars. Its
            # sentinel keeps legacy UI from exposing a star purchase path and
            # must never distort the free collection economy.
            if is_premium_collection_row(row):
                continue
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
    baseline_durations: dict[str, float] = {}
    pilot_ids = pilot_scope_ids()
    _pilot_numbers, pilot_runtime, pilot_errors = sim.pilot_runtime_contract()
    errors.extend(pilot_errors)
    wave_pressure_rule = economy.get("wave_pressure", {})
    if wave_pressure_rule:
        if not WAVE_PRESSURE_FIXTURE_PATH.exists():
            errors.append(f"missing wave-pressure fixture: {WAVE_PRESSURE_FIXTURE_PATH}")
        else:
            fixture = json.loads(WAVE_PRESSURE_FIXTURE_PATH.read_text(encoding="utf-8"))
            rule = wave_pressure_config(economy)
            for level in levels:
                baseline_level = copy.deepcopy(level)
                fixture_row = fixture.get("levels", {}).get(level["id"], {})
                if fixture_row.get("target_rows") and level["id"] not in pilot_ids:
                    restore_wave_pressure_target_rows(baseline_level, fixture_row, rule)
                _pressure, baseline_duration, _boss_count = level_pressure(
                    baseline_level, zombies, bosses, economy)
                baseline_durations[level["id"]] = baseline_duration
    pressures = [level_pressure(level, zombies, bosses, economy)[0] for level in levels]
    for i in range(1, len(pressures)):
        prev = pressures[i - 1]
        cur = pressures[i]
        level_id = levels[i]["id"]
        _, _, boss_count = level_pressure(levels[i], zombies, bosses, economy)
        # Late Bosses intentionally concentrate much more HP than the
        # preceding non-Boss stage so their mechanics have time to play out.
        # This is a durability spike only; the separate damage-ramp contract
        # remains fixed at 1.0x.
        level_no = level_number(levels[i])
        # The chapter-6 pilot deliberately changes spawn topology. Its checked
        # fixed-frame evidence owns progression; this scalar remains a screen
        # for every non-pilot level only.
        if level_id in pilot_ids:
            continue
        # The exact runtime endgame audit owns late-Boss clearability. Raw
        # pressure intentionally jumps because Boss HP is concentrated into a
        # long mechanic window while attack remains flat.
        spike_limit = 64.0 if boss_count and level_no >= 50 else (8.0 if boss_count else 3.2)
        if cur > prev * spike_limit:
            errors.append(f"{level_id} pressure spikes too hard: {prev:.1f} -> {cur:.1f}")
        if cur < prev * 0.18 and (i + 1) % 10 not in (1, 6):
            errors.append(f"{level_id} pressure drops too hard: {prev:.1f} -> {cur:.1f}")

    for level in levels:
        pressure, duration, boss_count = level_pressure(level, zombies, bosses, economy)
        runtime_row = pilot_runtime.get(level_number(level))
        if runtime_row is not None:
            duration = float(runtime_row["median_seconds"])
        # Late waves intentionally spawn more enemies now: wave 4 uses x2 count
        # and wave 5 uses x3 count. Keep the old lower bounds, but validate
        # against the current long-form pacing envelope instead of the pre-ramp
        # 105s/140s caps.
        authored_duration_max = BOSS_DURATION_MAX if boss_count else NORMAL_DURATION_MAX
        duration_max = authored_duration_max
        if runtime_row is not None:
            # Deterministic fixed-frame sweeps own rebuilt ranges, including
            # their checked duration envelope.  Do not reapply the retired
            # analytical normal/Boss buckets to measured runs.
            duration_max = float(runtime_row["max_duration_seconds"])
        if level["id"] in baseline_durations and wave_pressure_rule:
            # Preserve the authored pre-bump pacing envelope while allowing the
            # generated target waves to consume their configured count increase.
            # Exact count generation is checked separately, so this cannot hide
            # an arbitrary manual extension of a level.
            duration_max = max(
                authored_duration_max,
                baseline_durations[level["id"]]
                * (1.0 + float(wave_pressure_rule["target_count_increase"])),
            ) if runtime_row is None else duration_max
        if duration > duration_max + 1e-6:
            kind = "boss" if boss_count else "normal"
            errors.append(
                f"{level['id']} {kind} duration too long: "
                f"{duration:.1f}s > {duration_max:.1f}s"
            )
        if not boss_count and duration < 45.0:
            errors.append(f"{level['id']} normal duration too short: {duration:.1f}s")
        if boss_count and duration < 70.0:
            errors.append(f"{level['id']} boss duration too short: {duration:.1f}s")
        if pressure <= 0.0:
            errors.append(f"{level['id']} has non-positive pressure")
        xp_total = level_xp_total(level, zombies, bosses, economy)
        validate_card_budget(level, xp_total, errors)

    collection_tables = {
        "characters": characters,
        "weapons": weapons,
        "armors": armors,
        "chips": chips,
        "pets": pets,
    }
    costs = unlock_costs(*collection_tables.values())
    paid_costs = [cost for cost in costs if cost > 0]
    collection_total = sum(paid_costs)
    if not paid_costs or min(paid_costs) < 8 or max(paid_costs) > 16:
        errors.append("paid collection unlocks must stay in the 8-16 star comfort band")
    for table_name, table in collection_tables.items():
        category_costs = [
            int(row.get("unlock_cost_star", 0))
            for row in table.values()
            if not is_premium_collection_row(row)
            and int(row.get("unlock_cost_star", 0)) > 0
        ]
        if category_costs and max(category_costs) > min(category_costs) * 2:
            errors.append(f"{table_name} unlock curve exceeds the 2x same-category limit")
        for item_id, row in table.items():
            if is_premium_collection_row(row) and int(row.get("unlock_cost_star", 0)) < 999999:
                errors.append(
                    f"{table_name}.{item_id} premium item must keep the disabled star-price sentinel"
                )
    normal_campaign_stars = len(levels) * 3
    if not 300 <= collection_total <= normal_campaign_stars + 30:
        errors.append(
            f"collection total should be nearly completable from normal campaign stars: "
            f"total={collection_total}, normal={normal_campaign_stars}"
        )

    if len(skills) < 16:
        errors.append("skill pool should contain at least 16 skills")
    if len(characters) < 4:
        errors.append("character roster should contain 4 archetypes")

    free_weapons = {
        weapon_id: row
        for weapon_id, row in weapons.items()
        if not is_premium_collection_row(row)
    }
    weapon_ranking = check_weapon_dps(free_weapons, errors)

    if errors:
        print("Balance profile check failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Balance profile OK")
    print(f"pressure range: {min(pressures):.1f} -> {max(pressures):.1f}")
    print(f"paid unlock star range: {min(paid_costs)} -> {max(paid_costs)}; total={collection_total}")
    print("weapon effective DPS (relative):")
    for weapon_id, rarity, dps in weapon_ranking:
        print(f"  {dps:6.2f}  [{rarity:9}] {weapon_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
