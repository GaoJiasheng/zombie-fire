#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(name: str):
    return json.loads((ROOT / "data" / f"{name}.json").read_text(encoding="utf-8"))


def level_pressure(level: dict, zombies: dict, bosses: dict) -> tuple[float, float, int]:
    pressure = 0.0
    duration = 0.0
    boss_count = 0
    hp_base = float(level.get("base_hp_ref", 50.0)) / 50.0
    for wave in level.get("waves", []):
        for group in wave.get("spawns", []):
            row = zombies[group["type"]]
            count = int(group.get("count", 1))
            pressure += count * float(row.get("hp_coef", 1.0)) * float(row.get("bd_coef", 1.0))
            duration += count * float(group.get("interval", 0.8))
        if "boss" in wave:
            boss_count += 1
            pressure += float(bosses[wave["boss"]].get("hp_coef", 1.0)) * 8.0
        for group in wave.get("support", []):
            row = zombies[group["type"]]
            count = int(group.get("count", 1))
            pressure += count * float(row.get("hp_coef", 1.0)) * float(row.get("bd_coef", 1.0))
            duration += count * float(group.get("interval", 0.8))
    return pressure * hp_base * float(level.get("difficulty_coef", 1.0)), duration, boss_count


def level_xp_total(level: dict, zombies: dict, bosses: dict) -> int:
    total = 0
    for wave in level.get("waves", []):
        for group in wave.get("spawns", []) + wave.get("support", []):
            row = zombies[group["type"]]
            total += int(group.get("count", 1)) * int(row.get("run_xp", 1))
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


def unlock_costs(*tables: dict) -> list[int]:
    costs: list[int] = []
    for table in tables:
        for row in table.values():
            costs.append(int(row.get("unlock_cost_star", 0)))
    return sorted(costs)


def main() -> int:
    zombies = load("zombies")
    bosses = load("bosses")
    levels = load("levels")
    characters = load("characters")
    weapons = load("weapons")
    armors = load("armors")
    chips = load("chips")
    pets = load("pets")
    skills = load("skills")

    errors: list[str] = []
    pressures = [level_pressure(level, zombies, bosses)[0] for level in levels]
    for i in range(1, len(pressures)):
        prev = pressures[i - 1]
        cur = pressures[i]
        level_id = levels[i]["id"]
        _, _, boss_count = level_pressure(levels[i], zombies, bosses)
        spike_limit = 4.25 if boss_count else 3.2
        if cur > prev * spike_limit:
            errors.append(f"{level_id} pressure spikes too hard: {prev:.1f} -> {cur:.1f}")
        if cur < prev * 0.18 and (i + 1) % 10 not in (1, 6):
            errors.append(f"{level_id} pressure drops too hard: {prev:.1f} -> {cur:.1f}")

    for level in levels:
        pressure, duration, boss_count = level_pressure(level, zombies, bosses)
        if boss_count and duration > 140.0:
            errors.append(f"{level['id']} boss duration too long: {duration:.1f}s")
        if not boss_count and duration > 105.0:
            errors.append(f"{level['id']} normal duration too long: {duration:.1f}s")
        if not boss_count and duration < 45.0:
            errors.append(f"{level['id']} normal duration too short: {duration:.1f}s")
        if boss_count and duration < 70.0:
            errors.append(f"{level['id']} boss duration too short: {duration:.1f}s")
        if pressure <= 0.0:
            errors.append(f"{level['id']} has non-positive pressure")
        xp_total = level_xp_total(level, zombies, bosses)
        predicted_cards = predicted_card_picks(level, xp_total)
        target_cards = int(level.get("target_card_picks", predicted_cards))
        if abs(predicted_cards - target_cards) > 1:
            errors.append(f"{level['id']} card budget drift: predicted={predicted_cards}, target={target_cards}, xp={xp_total}")

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

    if errors:
        print("Balance profile check failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Balance profile OK")
    print(f"pressure range: {min(pressures):.1f} -> {max(pressures):.1f}")
    print(f"unlock star range: {min(costs)} -> {max(costs)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
