#!/usr/bin/env python3
from __future__ import annotations

import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(name: str):
    return json.loads((ROOT / "data" / f"{name}.json").read_text(encoding="utf-8"))


def upgrade_cost(base: int, level: int, growth: float) -> int:
    tier_step = 1.0 + 0.08 * ((max(level, 1) - 1) // 10)
    return round(base * math.pow(growth, max(level - 1, 0)) * tier_step)


def level_gold(level: dict, zombies: dict, bosses: dict) -> int:
	gold = int(level.get("first_clear_reward", {}).get("gold", 0))
	reward_mult = float(level.get("reward_gold_mult", 1.0))
	combat_gold = 0
	for wave in level.get("waves", []):
		for group in wave.get("spawns", []) + wave.get("support", []):
			row = zombies[group["type"]]
			combat_gold += int(group.get("count", 1)) * int(10 * float(row.get("gold_coef", 1.0)))
		if "boss" in wave:
			combat_gold += int(10 * float(bosses[wave["boss"]].get("gold_coef", 1.0)))
	gold += int(round(combat_gold * reward_mult))
	return gold


def main() -> int:
    economy = load("economy")
    levels = load("levels")
    zombies = load("zombies")
    bosses = load("bosses")
    weapons = load("weapons")
    characters = load("characters")
    armors = load("armors")
    chips = load("chips")
    pets = load("pets")
    growth = float(economy.get("upgrade_cost_growth", 1.15))
    errors: list[str] = []

    early_gold = sum(level_gold(level, zombies, bosses) for level in levels[:5])
    starter_plan = [
        ("weapon_autocannon", weapons["weapon_autocannon"], 4),
        ("vanguard", characters["vanguard"], 3),
        ("armor_kevlar", armors["armor_kevlar"], 2),
        ("chip_attack", chips["chip_attack"], 2),
    ]
    starter_cost = 0
    for _, row, target_level in starter_plan:
        base = int(row.get("cost_base_gold", 100))
        starter_cost += sum(upgrade_cost(base, level, growth) for level in range(1, target_level))
    if starter_cost > early_gold * 0.92:
        errors.append(f"early upgrade plan too expensive: cost={starter_cost}, gold={early_gold}")

    campaign_gold = sum(level_gold(level, zombies, bosses) for level in levels)
    midline_items = [
        weapons["weapon_autocannon"],
        characters["vanguard"],
        armors["armor_kevlar"],
        chips["chip_attack"],
    ]
    midline_cost = 0
    for row in midline_items:
        base = int(row.get("cost_base_gold", 100))
        midline_cost += sum(upgrade_cost(base, level, growth) for level in range(1, 26))
    if midline_cost > campaign_gold * 0.82:
        errors.append(f"core level-25 path consumes too much campaign gold: cost={midline_cost}, gold={campaign_gold}")
    if midline_cost < campaign_gold * 0.18:
        errors.append(f"core level-25 path too cheap; gold loses value: cost={midline_cost}, gold={campaign_gold}")

    max_star_unlock = max(int(row.get("unlock_cost_star", 0)) for table in [characters, weapons, armors, chips, pets] for row in table.values())
    if max_star_unlock < 220:
        errors.append("late star unlock target is too low")

    if errors:
        print("Economy loop check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("Economy loop OK")
    print(f"early_gold={early_gold} starter_cost={starter_cost}")
    print(f"campaign_gold={campaign_gold} core_level25_cost={midline_cost}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
