#!/usr/bin/env python3
from __future__ import annotations

import json
import math
from pathlib import Path

from check_level_pressure import late_wave_count_mult, level_number

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


def godot_round_positive(value: float) -> int:
    """Match Godot's round() for the non-negative reward values used here."""
    return math.floor(value + 0.5)


def level_xp(level: dict, zombies: dict, bosses: dict, economy: dict) -> int:
    total = 0
    level_no = level_number(level)
    for wave in level.get("waves", []):
        wave_no = int(wave.get("wave", 0))
        count_mult = late_wave_count_mult(economy, wave_no, level_no)
        for group in wave.get("spawns", []) + wave.get("support", []):
            count = godot_round_positive(int(group.get("count", 0)) * count_mult)
            total += count * int(zombies[group["type"]].get("run_xp", 0))
        if "boss" in wave:
            total += int(bosses[wave["boss"]].get("run_xp", 0))
    return total


def main() -> int:
    economy = load("economy")
    levels = load("levels")
    zombies = load("zombies")
    bosses = load("bosses")
    weapons = load("weapons")
    skills = load("skills")
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

    collection_tables = [characters, weapons, armors, chips, pets]
    paid_star_unlocks = [
        int(row.get("unlock_cost_star", 0))
        for table in collection_tables
        for row in table.values()
        # Premium permanent entitlements use a disabled star-price sentinel.
        # They belong to the commerce audit, not the free campaign-star loop.
        if not str(row.get("premium_entitlement", "")).strip()
        if int(row.get("unlock_cost_star", 0)) > 0
    ]
    max_star_unlock = max(paid_star_unlocks)
    total_star_unlock = sum(paid_star_unlocks)
    normal_campaign_stars = len(levels) * 3
    if max_star_unlock > 16:
        errors.append(f"single-item star price is too steep: max={max_star_unlock}")
    if total_star_unlock > normal_campaign_stars + 30:
        errors.append(
            f"full collection needs too many challenge stars: "
            f"total={total_star_unlock}, normal={normal_campaign_stars}"
        )
    if total_star_unlock < normal_campaign_stars:
        errors.append(
            f"full collection is too cheap to preserve challenge progression: "
            f"total={total_star_unlock}, normal={normal_campaign_stars}"
        )

    repeat_xp_mult = economy.get("repeat_clear_xp_mult", [])
    skill_xp_costs = economy.get("skill_base_xp_costs", [])
    sig_xp_costs = economy.get("sig_skill_xp_costs", [])
    if not isinstance(repeat_xp_mult, list) or len(repeat_xp_mult) < 3:
        errors.append("repeat_clear_xp_mult must define first clear and two repeat-clear bands")
        repeat_xp_mult = [1.0, 0.5, 0.25]
    if not isinstance(skill_xp_costs, list) or len(skill_xp_costs) < 5:
        errors.append("skill_base_xp_costs must define all five permanent-skill ranks")
        skill_xp_costs = []
    if not isinstance(sig_xp_costs, list) or len(sig_xp_costs) < 5:
        errors.append("sig_skill_xp_costs must define all five signature-skill ranks")
        sig_xp_costs = []

    campaign_xp_by_level = [level_xp(level, zombies, bosses, economy) for level in levels]
    three_clear_xp = sum(
        godot_round_positive(stage_xp * float(multiplier))
        for stage_xp in campaign_xp_by_level
        for multiplier in repeat_xp_mult[:3]
    )
    permanent_skill_cost = len(skills) * sum(int(cost) for cost in skill_xp_costs)
    signature_skill_count = sum(1 for row in characters.values() if row.get("active_skill"))
    signature_skill_cost = signature_skill_count * sum(int(cost) for cost in sig_xp_costs)
    total_xp_cost = permanent_skill_cost + signature_skill_cost
    xp_coverage = three_clear_xp / max(total_xp_cost, 1)
    xp_contract = economy.get("skill_xp_coverage_contract", {})
    xp_target = float(xp_contract.get("target", 0.809))
    xp_tolerance = max(0.0, float(xp_contract.get("tolerance", 0.01)))
    if abs(xp_coverage - xp_target) > xp_tolerance + 1e-9:
        errors.append(
            "permanent + signature skill XP coverage outside contract: "
            f"income={three_clear_xp}, cost={total_xp_cost}, coverage={xp_coverage:.2%}, "
            f"expected={xp_target:.1%}±{xp_tolerance:.1%}"
        )

    if errors:
        print("Economy loop check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("Economy loop OK")
    print(f"early_gold={early_gold} starter_cost={starter_cost}")
    print(f"campaign_gold={campaign_gold} core_level25_cost={midline_cost}")
    print(
        f"star_unlock_total={total_star_unlock} max_item={max_star_unlock} "
        f"normal_campaign={normal_campaign_stars} challenge_needed={total_star_unlock - normal_campaign_stars}"
    )
    print(
        f"xp_first_clear={sum(campaign_xp_by_level)} xp_three_clear={three_clear_xp} "
        f"xp_full_cost={total_xp_cost} xp_coverage={xp_coverage:.2%}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
