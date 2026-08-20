#!/usr/bin/env python3
"""Generate the design/37 endless Boss HP budget table.

The endless Boss *species* still follows the runtime pool (virtual level
25 + five levels per completed loop). Durability is deliberately separate:
each displayed loop owns one total raw-HP budget. The budget is solved from a
Boss-phase target and the conservative player fixture for that loop.

Loops 1-6 use the approved level_080 Owner anchor's Boss-axis DPS. Loops 7-10
use a deliberately tiny 2% graduation bridge, which is just enough to keep the
generated raw-HP budget monotonic when the roster changes. From loop 11 through
20 the reference cross-fades linearly to the measured max-free scattergun
graduation DPS used by check_endgame_balance. The same cross-fade is applied to
attack-element matchup
so the generated raw HP accounts for each loop's actual Boss roster without
silently importing any campaign fixed_hp value.

Power v5 replaces panel-DPS estimates with checked-in collider throughput. A
full early cross-fade would make the level_080 fixture fail before its approved
10-14 survival band; the small bridge preserves both that band and the existing
68/78/89/100-second loop targets, so the approved +12% endless-gold contract
remains strictly increasing instead of being diluted by longer loop times.

Run normally to update data/economy.json. Run with --check in CI to prove the
checked-in table is current. Repeated normal runs are byte-idempotent.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
ECONOMY_PATH = DATA / "economy.json"
RUNTIME_BENCHMARK_PATH = ROOT / "tools" / "physical_endgame_runtime_benchmark.json"
sys.path.insert(0, str(ROOT / "tools"))

import power_ruler_model as prm  # noqa: E402


DEFAULT_MAX_LOOP = 20
DEFAULT_COUNT_STEP = 4
DEFAULT_COUNT_CAP = 6
DEFAULT_BANDS = [
    {"until_loop": 3, "min_seconds": 0.0, "max_seconds": 30.0},
    {"until_loop": 6, "min_seconds": 30.0, "max_seconds": 60.0},
    {"until_loop": 10, "min_seconds": 60.0, "max_seconds": 100.0},
    {"min_seconds": 100.0, "max_seconds": 150.0},
]
DEFAULT_TARGET_SECONDS = [
    18.0, 24.0, 30.0,
    36.0, 48.0, 60.0,
    68.0, 78.0, 89.0, 100.0,
    108.0, 116.0, 124.0, 132.0, 140.0, 146.0,
    150.0, 150.0, 150.0, 150.0,
]
MID_TRANSITION_START_LOOP = 7
GRADUATION_TRANSITION_FULL_LOOP = 20
MID_BRIDGE_END_LOOP = 10
MID_BRIDGE_RATIO = 0.02


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def owner_mid_reference_dps(economy: dict) -> tuple[float, str]:
    levels = prm.load_table("levels")
    level = next(row for row in levels if row.get("id") == "level_080")
    contract = level["clear_requirement"]["power_contract"]
    characters = prm.load_table("characters")
    weapons = prm.load_table("weapons")
    armors = prm.load_table("armors")
    chips = prm.load_table("chips")
    pets = prm.load_table("pets")
    skills = prm.load_table("skills")
    bosses = prm.load_table("bosses")
    build = prm.owner_anchor_fixture("level_080", skills)
    result = prm.power_for_build(
        level, contract, build, characters, weapons, armors, chips, pets,
        skills, bosses, economy,
    )
    per_capacity = float(economy["power_ruler"]["boss_dps_per_capacity"])
    dps = float(result["capacities"]["boss"]) * per_capacity
    element = str(weapons[build["weapon"]].get("element", "physical"))
    return dps, element


def graduation_reference_dps() -> tuple[float, str]:
    benchmark = load_json(RUNTIME_BENCHMARK_PATH)
    row = benchmark["best_same_loadout"]["weapon_scattergun"]
    return float(row["boss_dps"]), "physical"


def boss_count(loop: int, economy: dict) -> int:
    step = max(int(economy.get("endless_boss_count_step", DEFAULT_COUNT_STEP)), 1)
    cap = max(int(economy.get("endless_boss_count_cap", DEFAULT_COUNT_CAP)), 1)
    return min(1 + (loop - 1) // step, cap)


def boss_roster(loop: int, economy: dict, bosses: dict) -> list[str]:
    template_id = str(economy.get("endless_template_level", "level_025"))
    template_level = int(template_id.removeprefix("level_"))
    total = boss_count(loop, economy)
    # level_025 authors Frost Warden in its final wave. Keep that runtime
    # identity, then append the strongest distinct pool entries exactly like GD.
    roster = ["boss_frost_warden"]
    virtual_level = template_level + (loop - 1) * 5
    eligible = sorted(
        (
            (int(row.get("appear_level", 1)), boss_id)
            for boss_id, row in bosses.items()
            if int(row.get("appear_level", 1)) <= virtual_level
        ),
        key=lambda item: (item[0], item[1]),
    )
    for offset in range(max(total - 1, 0)):
        roster.append(eligible[-1 - offset][1])
    return roster


def stack_weights(roster: list[str], economy: dict) -> list[float]:
    pacing = economy.get("boss_pacing", {}) or {}
    values = pacing.get("same_type_hp_multipliers", [1.0]) or [1.0]
    counts: dict[str, int] = {}
    result: list[float] = []
    for boss_id in roster:
        copy_index = counts.get(boss_id, 0)
        counts[boss_id] = copy_index + 1
        result.append(max(float(values[min(copy_index, len(values) - 1)]), 0.01))
    return result


def transition_ratio(loop: int) -> float:
    if loop < MID_TRANSITION_START_LOOP:
        return 0.0
    if loop <= MID_BRIDGE_END_LOOP:
        return MID_BRIDGE_RATIO
    span = GRADUATION_TRANSITION_FULL_LOOP - MID_BRIDGE_END_LOOP
    return min(max((loop - MID_BRIDGE_END_LOOP) / span, 0.0), 1.0)


def element_time_factor(boss: dict, element: str, economy: dict, grace: bool) -> float:
    mechanic_mult = prm.boss_effective_hp_multiplier(boss, economy)
    if grace:
        # Opening grace removes resistances/immunities but intentionally keeps
        # weaknesses and the Boss's readable mechanic identity.
        damage_factor = (
            max(float(economy.get("weakness_mult", 1.5)), 1.0)
            if str(boss.get("weakness", "")) == element else 1.0
        )
    else:
        damage_factor = prm.boss_element_factor(boss, element, economy)
    return mechanic_mult / max(damage_factor, 0.05)


def target_seconds(loop: int, pacing: dict) -> float:
    configured = pacing.get("target_seconds_by_loop", DEFAULT_TARGET_SECONDS)
    values = [float(value) for value in configured]
    if not values:
        values = DEFAULT_TARGET_SECONDS
    return values[min(loop - 1, len(values) - 1)]


def phase_band(loop: int, pacing: dict) -> tuple[float, float]:
    bands = pacing.get("phase_time_bands", DEFAULT_BANDS)
    for row in bands:
        if "until_loop" not in row or loop <= int(row["until_loop"]):
            return float(row["min_seconds"]), float(row["max_seconds"])
    raise AssertionError(f"no endless Boss phase band covers loop {loop}")


def generate_pacing(economy: dict, bosses: dict) -> dict:
    existing = economy.get("endless_boss_pacing", {}) or {}
    max_loop = max(int(existing.get("max_loop", DEFAULT_MAX_LOOP)), 1)
    bands = existing.get("phase_time_bands", DEFAULT_BANDS)
    targets = existing.get("target_seconds_by_loop", DEFAULT_TARGET_SECONDS)
    mid_dps, mid_element = owner_mid_reference_dps(economy)
    graduation_dps, graduation_element = graduation_reference_dps()
    grace_loops = max(int(economy.get("endless_boss_resistance_grace_loops", 1)), 0)
    rows = []
    pacing_for_lookup = {
        "phase_time_bands": bands,
        "target_seconds_by_loop": targets,
    }
    previous_budget = 0
    for loop in range(1, max_loop + 1):
        mix = transition_ratio(loop)
        reference_dps = mid_dps * (1.0 - mix) + graduation_dps * mix
        roster = boss_roster(loop, economy, bosses)
        weights = stack_weights(roster, economy)
        weight_total = max(sum(weights), 0.01)
        mid_factor = sum(
            weight * element_time_factor(
                bosses[boss_id], mid_element, economy, loop <= grace_loops)
            for boss_id, weight in zip(roster, weights)
        ) / weight_total
        graduation_factor = sum(
            weight * element_time_factor(
                bosses[boss_id], graduation_element, economy, loop <= grace_loops)
            for boss_id, weight in zip(roster, weights)
        ) / weight_total
        time_factor = mid_factor * (1.0 - mix) + graduation_factor * mix
        seconds = target_seconds(loop, pacing_for_lookup)
        lower, upper = phase_band(loop, pacing_for_lookup)
        if not lower <= seconds <= upper:
            raise AssertionError(
                f"loop {loop}: target {seconds:.1f}s outside [{lower:.1f},{upper:.1f}]s")
        budget = max(int(round(reference_dps * seconds / max(time_factor, 0.05))), 1)
        if budget < previous_budget:
            raise AssertionError(
                f"loop {loop}: generated Boss budget {budget} regressed below {previous_budget}")
        previous_budget = budget
        rows.append({
            "loop": loop,
            "total_hp": budget,
            "target_seconds": seconds,
            "reference_dps": round(reference_dps, 2),
            "reference_mix": round(mix, 4),
            "boss_ids": roster,
        })
    return {
        "max_loop": max_loop,
        "phase_time_bands": bands,
        "target_seconds_by_loop": targets,
        "reference_transition": {
            "mid_level_id": "level_080",
            "mid_dps": round(mid_dps, 2),
            "mid_element": mid_element,
            "graduation_weapon": "weapon_scattergun",
            "graduation_dps": round(graduation_dps, 2),
            "graduation_element": graduation_element,
            "start_loop": MID_TRANSITION_START_LOOP,
            "bridge_end_loop": MID_BRIDGE_END_LOOP,
            "bridge_ratio": MID_BRIDGE_RATIO,
            "full_loop": GRADUATION_TRANSITION_FULL_LOOP,
        },
        "budgets": rows,
    }


def rendered_economy(economy: dict, bosses: dict) -> str:
    economy["endless_boss_pacing"] = generate_pacing(economy, bosses)
    return json.dumps(economy, ensure_ascii=False, indent="\t") + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    economy = load_json(ECONOMY_PATH)
    bosses = load_json(DATA / "bosses.json")
    rendered = rendered_economy(economy, bosses)
    current = ECONOMY_PATH.read_text(encoding="utf-8")
    if args.check:
        if rendered != current:
            print("endless Boss budgets are stale; run tools/generate_endless_boss_budgets.py")
            return 1
        print("Endless Boss budget table is current")
        return 0
    if rendered != current:
        ECONOMY_PATH.write_text(rendered, encoding="utf-8")
        print("Updated data/economy.json endless Boss budgets")
    else:
        print("Endless Boss budgets already current")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
