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


def endless_gold_audit(economy: dict, levels: list[dict], zombies: dict,
                       bosses: dict, errors: list[str]) -> list[dict]:
    """Audit runtime-equivalent endless gold pacing through the budget table.

    Runtime rounds every kill independently, so this intentionally does not
    multiply an aggregate reward. Boss target time is added to the authored
    template's spawn schedule to produce a stable per-loop gold/minute metric.
    Milestone rewards are included in their completion loop: this makes the
    strict monotonic assertion strong enough to catch an oversized milestone
    that would create a reward spike followed by a worse next loop.
    """
    loop_bonus = float(economy.get("endless_gold_loop_bonus", -1.0))
    if not math.isclose(loop_bonus, 0.12, rel_tol=0.0, abs_tol=1e-9):
        errors.append(
            f"endless_gold_loop_bonus must remain the approved linear 0.12, got {loop_bonus}"
        )
    milestone = economy.get("endless_gold_milestone", {})
    if not isinstance(milestone, dict):
        errors.append("endless_gold_milestone must be a dictionary")
        milestone = {}
    milestone_interval = int(milestone.get("interval", 0))
    milestone_base = int(milestone.get("gold_per_milestone", 0))
    if milestone_interval <= 0 or milestone_base <= 0:
        errors.append("endless gold milestone interval and base reward must be positive")

    template_id = str(economy.get("endless_template_level", ""))
    template = next((row for row in levels if row.get("id") == template_id), None)
    if template is None:
        errors.append(f"endless gold audit cannot resolve template {template_id!r}")
        return []
    template_level = level_number(template)
    gold_per_kill = (
        float(economy.get("gold_drop_base", 5.0))
        + float(economy.get("gold_drop_per_level", 0.6)) * template_level
    )
    reward_mult = float(template.get("reward_gold_mult", 1.0))
    mob_groups: list[tuple[int, float]] = []
    spawn_seconds = 0.0
    for wave in template.get("waves", []):
        wave_no = int(wave.get("wave", 0))
        count_mult = late_wave_count_mult(economy, wave_no, template_level)
        for group in wave.get("spawns", []) + wave.get("support", []):
            count = godot_round_positive(int(group.get("count", 0)) * count_mult)
            zombie = zombies.get(str(group.get("type", "")), {})
            mob_groups.append((count, float(zombie.get("gold_coef", 1.0))))
            spawn_seconds += count * max(float(group.get("interval", 0.0)), 0.0)

    pacing = economy.get("endless_boss_pacing", {})
    budget_rows = pacing.get("budgets", []) if isinstance(pacing, dict) else []
    if not isinstance(budget_rows, list) or len(budget_rows) < 10:
        errors.append("endless gold audit requires at least ten Boss budget rows")
        return []

    audit_rows: list[dict] = []
    previous_rate = 0.0
    cumulative_gold = 0
    cumulative_seconds = 0.0
    for row in budget_rows:
        if not isinstance(row, dict):
            continue
        loop = int(row.get("loop", 0))
        if loop <= 0:
            continue
        multiplier = 1.0 + max(loop_bonus, 0.0) * (loop - 1)
        combat_gold = sum(
            count * godot_round_positive(coef * gold_per_kill * reward_mult * multiplier)
            for count, coef in mob_groups
        )
        boss_ids = row.get("boss_ids", [])
        if not isinstance(boss_ids, list) or not boss_ids:
            errors.append(f"endless Boss budget loop {loop} has no reward roster")
            boss_ids = []
        combat_gold += sum(
            godot_round_positive(
                float(bosses.get(str(boss_id), {}).get("gold_coef", 1.0))
                * gold_per_kill * reward_mult * multiplier
            )
            for boss_id in boss_ids
        )
        milestone_gold = 0
        if milestone_interval > 0 and loop % milestone_interval == 0:
            milestone_gold = milestone_base * (loop // milestone_interval)
        total_gold = combat_gold + milestone_gold
        # Pending Boss spawns are serialized by the battle queue: the authored
        # first Boss waits 1.0s and extra copies wait 1.6s each.
        boss_spawn_seconds = 1.0 + max(len(boss_ids) - 1, 0) * 1.6
        loop_seconds = (
            spawn_seconds + boss_spawn_seconds
            + max(float(row.get("target_seconds", 0.0)), 0.0)
        )
        gold_per_minute = total_gold * 60.0 / max(loop_seconds, 1.0)
        if gold_per_minute <= previous_rate + 1e-9:
            errors.append(
                "endless gold/min must rise every loop: "
                f"loop {loop - 1}={previous_rate:.1f}, loop {loop}={gold_per_minute:.1f}"
            )
        previous_rate = gold_per_minute
        cumulative_gold += total_gold
        cumulative_seconds += loop_seconds
        audit_rows.append({
            "loop": loop,
            "combat_gold": combat_gold,
            "milestone_gold": milestone_gold,
            "total_gold": total_gold,
            "seconds": loop_seconds,
            "gold_per_minute": gold_per_minute,
            "cumulative_gold_per_minute": cumulative_gold * 60.0 / cumulative_seconds,
        })

    if len(audit_rows) >= 10:
        ratio = audit_rows[9]["gold_per_minute"] / max(audit_rows[0]["gold_per_minute"], 1.0)
        if ratio > 3.0 + 1e-9:
            errors.append(
                f"endless loop 10 gold/min exceeds 3x loop 1: ratio={ratio:.3f}"
            )
    return audit_rows


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

    endless_gold_rows = endless_gold_audit(economy, levels, zombies, bosses, errors)

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
    if endless_gold_rows:
        print("endless_gold loop combat milestone total seconds gold/min cumulative_gold/min")
        for row in endless_gold_rows:
            print(
                "  {loop:02d} {combat_gold:5d} {milestone_gold:4d} {total_gold:5d} "
                "{seconds:6.1f} {gold_per_minute:8.1f} {cumulative_gold_per_minute:8.1f}".format(**row)
            )
        loop1 = endless_gold_rows[0]
        loop10 = endless_gold_rows[9]
        print(
            "endless_vs_campaign_repeat template={template} campaign_repeat={campaign:.1f}/min "
            "loop1={loop1:.1f}/min loop10={loop10:.1f}/min ratio={ratio:.3f} (print-only comparison)".format(
                template=economy.get("endless_template_level", ""),
                campaign=loop1["gold_per_minute"],
                loop1=loop1["gold_per_minute"],
                loop10=loop10["gold_per_minute"],
                ratio=loop10["gold_per_minute"] / max(loop1["gold_per_minute"], 1.0),
            )
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
