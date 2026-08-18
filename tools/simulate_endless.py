#!/usr/bin/env python3
"""Offline design/37 endless-mode survival and pacing audit.

This is deliberately a contract model rather than a second battle engine. It
consumes the runtime's generated Boss budgets, staged mob curve, Boss roster,
matchup rules, and the two already-approved power fixtures:

* ``level_080`` Owner anchor for the mid-game build;
* the checked-in max-free scattergun runtime benchmark for graduation.

Boss pressure starts only after a roster's weighted approach time. Each full
approach window spent alive at the base consumes one unit of unmitigated line
pressure, divided by the fixture's existing line capacity. Pressure carries
between endless loops, matching the runtime's persistent base HP. Mob pressure
uses the same rule only when scaled template HP can no longer be cleared inside
the authored spawn schedule. The first loop whose cumulative pressure reaches
one is reported as the fixture's terminal loop.

The generated ``target_seconds`` rows are the cross-faded pacing reference and
are what design/37's per-loop experience bands constrain. Per-fixture phase
times are printed separately; they intentionally differ before/after the
level_080-to-graduation transition and must not be confused with the pacing
reference used to solve the budgets.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import generate_endless_boss_budgets as boss_budgets  # noqa: E402
import power_ruler_model as power_ruler  # noqa: E402
import simulate_balance as balance  # noqa: E402
from check_level_pressure import late_wave_count_mult, level_number  # noqa: E402


MID_SURVIVAL_BAND = (10, 14)
GRADUATION_SURVIVAL_BAND = (16, 20)
BASE_ATTACK_Y = 1500.0
ENEMY_SPAWN_Y = 190.0


def load(name: str):
    return json.loads((ROOT / "data" / f"{name}.json").read_text(encoding="utf-8"))


def staged_mob_multiplier(display_loop: int, economy: dict) -> float:
    """Mirror battle.gd's staged compound curve from its JSON single source."""
    stages = economy.get("endless_hp_growth_stages", [])
    if not isinstance(stages, list) or not stages:
        raise AssertionError("endless_hp_growth_stages must be a non-empty array")
    multiplier = 1.0
    for current_loop in range(2, max(display_loop, 1) + 1):
        growth = None
        for stage in stages:
            if not isinstance(stage, dict):
                continue
            if "until_loop" not in stage or current_loop <= int(stage["until_loop"]):
                growth = max(float(stage.get("growth", 0.0)), 0.0)
                break
        if growth is None:
            raise AssertionError(f"no endless HP growth stage covers loop {current_loop}")
        multiplier *= 1.0 + growth
    return multiplier


def template_spawn_seconds(level: dict, economy: dict) -> float:
    """Mirror the authored spawn schedule used by the economy audit."""
    total = 0.0
    template_level = level_number(level)
    for wave in level.get("waves", []):
        wave_no = int(wave.get("wave", 0))
        count_mult = late_wave_count_mult(economy, wave_no, template_level)
        for group in wave.get("spawns", []) + wave.get("support", []):
            count = math.floor(int(group.get("count", 0)) * count_mult + 0.5)
            total += count * max(float(group.get("interval", 0.0)), 0.0)
    return total


def fixture_power(level_id: str, economy: dict, tables: dict) -> dict:
    level = next(row for row in tables["levels"] if row.get("id") == level_id)
    contract = level["clear_requirement"]["power_contract"]
    build = power_ruler.owner_anchor_fixture(level_id, tables["skills"])
    result = power_ruler.power_for_build(
        level,
        contract,
        build,
        tables["characters"],
        tables["weapons"],
        tables["armors"],
        tables["chips"],
        tables["pets"],
        tables["skills"],
        tables["bosses"],
        economy,
    )
    weapon = tables["weapons"][build["weapon"]]
    return {
        "build": build,
        "element": str(weapon.get("element", "physical")),
        "crowd_dps": (
            float(result["capacities"]["crowd"])
            * float(economy["power_ruler"]["crowd_dps_per_capacity"])
        ),
        "boss_dps": (
            float(result["capacities"]["boss"])
            * float(economy["power_ruler"]["boss_dps_per_capacity"])
        ),
        "line_capacity": float(result["capacities"]["line"]),
    }


def fixtures(economy: dict, tables: dict) -> list[dict]:
    mid = fixture_power("level_080", economy, tables)
    mid.update({"id": "mid_owner", "label": "level_080 Owner"})

    graduation = fixture_power("level_099", economy, tables)
    runtime = json.loads(
        (ROOT / "tools" / "physical_endgame_runtime_benchmark.json").read_text(
            encoding="utf-8"
        )
    )["best_same_loadout"]["weapon_scattergun"]
    # The endgame contract is grounded in measured Godot projectile collisions,
    # so both attack axes use that benchmark instead of the ruler's display
    # calibration. Line capacity still comes from the canonical build pipeline.
    graduation["crowd_dps"] = float(runtime["crowd_dps"])
    graduation["boss_dps"] = float(runtime["boss_dps"])
    graduation.update({"id": "graduation", "label": "max-free scattergun"})
    return [mid, graduation]


def weighted_boss_values(loop: int, economy: dict, bosses: dict) -> tuple[list[str], list[float]]:
    roster = boss_budgets.boss_roster(loop, economy, bosses)
    weights = boss_budgets.stack_weights(roster, economy)
    return roster, weights


def weighted_approach_seconds(roster: list[str], weights: list[float], bosses: dict,
                              economy: dict) -> float:
    total_weight = max(sum(weights), 0.01)
    enemy_speed = float(economy.get("ENEMY_SPEED_MULT", 1.0))
    boss_speed = float(economy.get("BOSS_SPEED_MULT", 1.0))
    weighted = 0.0
    for boss_id, weight in zip(roster, weights):
        boss = bosses[boss_id]
        profile = boss.get("mechanic_params", {}).get("base_attack_profile", {}) or {}
        line_y = BASE_ATTACK_Y + float(profile.get("line_offset", -80.0))
        distance = max(line_y - ENEMY_SPAWN_Y, 1.0)
        speed = max(float(boss.get("speed", 1.0)) * enemy_speed * boss_speed, 1.0)
        weighted += weight * distance / speed
    return weighted / total_weight


def boss_phase_seconds(row: dict, fixture: dict, economy: dict, bosses: dict) -> tuple[float, float]:
    loop = int(row["loop"])
    roster, weights = weighted_boss_values(loop, economy, bosses)
    total_weight = max(sum(weights), 0.01)
    grace_loops = max(int(economy.get("endless_boss_resistance_grace_loops", 1)), 0)
    time_factor = sum(
        weight * boss_budgets.element_time_factor(
            bosses[boss_id], fixture["element"], economy, loop <= grace_loops
        )
        for boss_id, weight in zip(roster, weights)
    ) / total_weight
    seconds = float(row["total_hp"]) * time_factor / max(float(fixture["boss_dps"]), 1.0)
    approach = weighted_approach_seconds(roster, weights, bosses, economy)
    return seconds, approach


def simulate_fixture(fixture: dict, economy: dict, tables: dict,
                     template_mob_hp: float, spawn_seconds: float) -> dict:
    rows = []
    cumulative_pressure = 0.0
    terminal_loop = None
    pacing_rows = economy["endless_boss_pacing"]["budgets"]
    for pacing_row in pacing_rows:
        loop = int(pacing_row["loop"])
        mob_multiplier = staged_mob_multiplier(loop, economy)
        mob_clear_seconds = (
            template_mob_hp * mob_multiplier / max(float(fixture["crowd_dps"]), 1.0)
        )
        mob_load = mob_clear_seconds / max(spawn_seconds, 1.0)
        mob_pressure = max(mob_load - 1.0, 0.0) / max(float(fixture["line_capacity"]), 0.01)
        phase_seconds, approach_seconds = boss_phase_seconds(
            pacing_row, fixture, economy, tables["bosses"]
        )
        boss_exposure = max(phase_seconds / max(approach_seconds, 1.0) - 1.0, 0.0)
        boss_pressure = boss_exposure / max(float(fixture["line_capacity"]), 0.01)
        cumulative_pressure += mob_pressure + boss_pressure
        rows.append({
            "loop": loop,
            "mob_hp_multiplier": mob_multiplier,
            "mob_clear_seconds": mob_clear_seconds,
            "mob_load": mob_load,
            "boss_target_seconds": float(pacing_row["target_seconds"]),
            "boss_phase_seconds": phase_seconds,
            "boss_approach_seconds": approach_seconds,
            "loop_pressure": mob_pressure + boss_pressure,
            "cumulative_pressure": cumulative_pressure,
        })
        if terminal_loop is None and cumulative_pressure >= 1.0:
            terminal_loop = loop
    if terminal_loop is None:
        terminal_loop = int(rows[-1]["loop"])
    return {
        "id": fixture["id"],
        "label": fixture["label"],
        "element": fixture["element"],
        "crowd_dps": fixture["crowd_dps"],
        "boss_dps": fixture["boss_dps"],
        "line_capacity": fixture["line_capacity"],
        "terminal_loop": terminal_loop,
        "rows": rows,
    }


def reference_phase_rows(economy: dict, bosses: dict, errors: list[str]) -> list[dict]:
    """Recompute the generated cross-faded pacing reference from source data."""
    pacing = economy.get("endless_boss_pacing", {})
    rows = pacing.get("budgets", []) if isinstance(pacing, dict) else []
    max_loop = int(pacing.get("max_loop", 0)) if isinstance(pacing, dict) else 0
    if len(rows) != max_loop or max_loop < GRADUATION_SURVIVAL_BAND[1]:
        errors.append(
            f"endless Boss budget coverage must be exactly max_loop and at least 20, "
            f"got rows={len(rows)} max_loop={max_loop}"
        )
        return []
    transition = pacing.get("reference_transition", {}) or {}
    mid_element = str(transition.get("mid_element", "physical"))
    graduation_element = str(transition.get("graduation_element", "physical"))
    grace_loops = max(int(economy.get("endless_boss_resistance_grace_loops", 1)), 0)
    result = []
    previous_mob = 0.0
    for row in rows:
        loop = int(row.get("loop", 0))
        target = float(row.get("target_seconds", -1.0))
        mix = float(row.get("reference_mix", 0.0))
        reference_dps = max(float(row.get("reference_dps", 0.0)), 1.0)
        roster, weights = weighted_boss_values(loop, economy, bosses)
        total_weight = max(sum(weights), 0.01)
        mid_factor = sum(
            weight * boss_budgets.element_time_factor(
                bosses[boss_id], mid_element, economy, loop <= grace_loops
            )
            for boss_id, weight in zip(roster, weights)
        ) / total_weight
        graduation_factor = sum(
            weight * boss_budgets.element_time_factor(
                bosses[boss_id], graduation_element, economy, loop <= grace_loops
            )
            for boss_id, weight in zip(roster, weights)
        ) / total_weight
        time_factor = mid_factor * (1.0 - mix) + graduation_factor * mix
        reference_seconds = float(row.get("total_hp", 0.0)) * time_factor / reference_dps
        lower, upper = boss_budgets.phase_band(loop, pacing)
        if reference_seconds < lower - 0.05 or reference_seconds > upper + 0.05:
            errors.append(
                f"loop {loop} recomputed pacing reference {reference_seconds:.1f}s outside "
                f"[{lower:.1f},{upper:.1f}]s"
            )
        if not math.isclose(reference_seconds, target, abs_tol=0.05):
            errors.append(
                f"loop {loop} pacing reference drifted: generated={target:.1f}s "
                f"recomputed={reference_seconds:.2f}s"
            )
        mob = staged_mob_multiplier(loop, economy)
        if mob <= previous_mob:
            errors.append(
                f"endless mob multiplier must rise strictly: loop {loop}={mob:.4f} "
                f"after {previous_mob:.4f}"
            )
        previous_mob = mob
        result.append({
            "loop": loop,
            "boss_ids": roster,
            "reference_mix": mix,
            "reference_dps": reference_dps,
            "target_seconds": target,
            "recomputed_seconds": reference_seconds,
            "band": [lower, upper],
        })
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true", help="emit machine-readable audit output")
    args = parser.parse_args()

    economy = load("economy")
    tables = {
        "levels": load("levels"),
        "zombies": load("zombies"),
        "bosses": load("bosses"),
        "characters": load("characters"),
        "weapons": load("weapons"),
        "armors": load("armors"),
        "chips": load("chips"),
        "pets": load("pets"),
        "skills": load("skills"),
    }
    template_id = str(economy.get("endless_template_level", ""))
    template = next(
        (row for row in tables["levels"] if row.get("id") == template_id), None
    )
    if template is None:
        print(f"ERROR: endless template {template_id!r} is missing")
        return 1
    template_mob_hp, _, _ = balance.level_enemy_hp_split(
        template, tables["zombies"], tables["bosses"], economy
    )
    spawn_seconds = template_spawn_seconds(template, economy)
    errors: list[str] = []
    reference_rows = reference_phase_rows(economy, tables["bosses"], errors)
    results = [
        simulate_fixture(row, economy, tables, template_mob_hp, spawn_seconds)
        for row in fixtures(economy, tables)
    ]
    result_by_id = {row["id"]: row for row in results}
    mid_loop = int(result_by_id["mid_owner"]["terminal_loop"])
    graduation_loop = int(result_by_id["graduation"]["terminal_loop"])
    if not MID_SURVIVAL_BAND[0] <= mid_loop <= MID_SURVIVAL_BAND[1]:
        errors.append(
            f"mid Owner terminal loop {mid_loop} outside {MID_SURVIVAL_BAND}"
        )
    if not GRADUATION_SURVIVAL_BAND[0] <= graduation_loop <= GRADUATION_SURVIVAL_BAND[1]:
        errors.append(
            f"graduation terminal loop {graduation_loop} outside "
            f"{GRADUATION_SURVIVAL_BAND}"
        )

    payload = {
        "template": template_id,
        "template_mob_hp": template_mob_hp,
        "template_spawn_seconds": spawn_seconds,
        "pacing_reference": reference_rows,
        "fixtures": results,
        "errors": errors,
    }
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print(
            f"Endless template {template_id}: mob_hp={template_mob_hp:.1f} "
            f"spawn_schedule={spawn_seconds:.1f}s"
        )
        print("\nCross-faded Boss pacing reference")
        print("loop mix reference_dps target recomputed band")
        for row in reference_rows:
            print(
                f"{row['loop']:>4} {row['reference_mix']:>4.2f} "
                f"{row['reference_dps']:>13.1f} {row['target_seconds']:>6.1f}s "
                f"{row['recomputed_seconds']:>10.1f}s "
                f"[{row['band'][0]:.0f},{row['band'][1]:.0f}]"
            )
        for fixture in results:
            print(
                f"\n{fixture['label']} ({fixture['element']}): "
                f"crowd_dps={fixture['crowd_dps']:.1f} "
                f"boss_dps={fixture['boss_dps']:.1f} "
                f"line={fixture['line_capacity']:.3f} "
                f"terminal_loop={fixture['terminal_loop']}"
            )
            print("loop mob_x mob_load boss_target boss_fixture pressure cumulative")
            for row in fixture["rows"]:
                print(
                    f"{row['loop']:>4} {row['mob_hp_multiplier']:>5.2f} "
                    f"{row['mob_load']:>8.3f} {row['boss_target_seconds']:>11.1f}s "
                    f"{row['boss_phase_seconds']:>11.1f}s "
                    f"{row['loop_pressure']:>8.3f} {row['cumulative_pressure']:>10.3f}"
                )
        print(
            f"\nSurvival bands: mid={MID_SURVIVAL_BAND} got={mid_loop}; "
            f"graduation={GRADUATION_SURVIVAL_BAND} got={graduation_loop}"
        )
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("Endless simulation checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
