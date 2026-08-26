#!/usr/bin/env python3
"""Generate the design/40 B1 chapter-six pilot from frozen authored shapes.

The generator owns no gameplay coefficients.  It restores the frozen 051-060
baseline, applies the absolute solution stored in campaign_pacing_targets.json,
and validates the Owner-approved within-level durability shape.  Runtime
frontline bands and card timing remain the responsibility of the fixed-frame
probe; this file deliberately does not pretend that a static model can prove
those experience contracts.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / "tools"
sys.path.insert(0, str(TOOLS))

import simulate_balance as sim  # noqa: E402

LEVELS_PATH = ROOT / "data" / "levels.json"
TARGETS_PATH = ROOT / "data" / "campaign_pacing_targets.json"
ZOMBIES_PATH = ROOT / "data" / "zombies.json"
BOSSES_PATH = ROOT / "data" / "bosses.json"
ECONOMY_PATH = ROOT / "data" / "economy.json"
BASELINE_PATH = TOOLS / "campaign_pacing_chapter6_baseline.json"


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, value) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")


def canonical_hash(value) -> str:
    payload = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def authored_projection(level: dict) -> dict:
    return {key: copy.deepcopy(value) for key, value in level.items() if key != "clear_requirement"}


def parse_levels(text: str) -> set[int]:
    if not text.strip():
        return set(range(51, 61))
    result = {int(token) for token in text.split(",") if token.strip()}
    if not result or any(number < 51 or number > 60 for number in result):
        raise ValueError("--levels must be a comma-separated subset of 51..60")
    return result


def capture_baseline(levels: list[dict]) -> dict:
    rows = [authored_projection(row) for row in levels if 51 <= sim.level_number(row) <= 60]
    if len(rows) != 10:
        raise ValueError("chapter-six baseline must contain exactly levels 051-060")
    return {
        "schema_version": 1,
        "source": "data/levels.json before design/40 B1 chapter-six generation",
        "authored_sha256": canonical_hash(rows),
        "levels": rows,
    }


def existing_lane_values(levels: list[dict]) -> set[str]:
    result: set[str] = set()
    for level in levels:
        for wave in level.get("waves", []):
            for group in list(wave.get("spawns", [])) + list(wave.get("support", [])):
                result.add(str(group.get("lane", "spread")))
    return result


def assert_frozen_wave(level_id: str, baseline: dict, generated: dict, wave_no: int) -> None:
    left = baseline.get("waves", [])[wave_no - 1]
    right = generated.get("waves", [])[wave_no - 1]
    if left != right:
        raise AssertionError(f"{level_id} W{wave_no}: Owner-frozen tutorial wave changed")


def assert_frozen_boss_shape(baseline: dict, generated: dict,
                             allow_runtime_roster_change: bool = False) -> None:
    left_waves = baseline.get("waves", [])
    right_waves = generated.get("waves", [])
    if len(left_waves) != len(right_waves):
        raise AssertionError(f"{generated['id']}: wave topology changed")
    for wave_index, (left, right) in enumerate(zip(left_waves, right_waves), 1):
        if left.get("boss") != right.get("boss"):
            raise AssertionError(f"{generated['id']} W{wave_index}: Boss identity changed")
        if left.get("runtime_bosses", []) != right.get("runtime_bosses", []):
            raise AssertionError(f"{generated['id']} W{wave_index}: Boss roster changed")
    if allow_runtime_roster_change:
        return
    left_runtime = baseline.get("runtime_bosses", [])
    right_runtime = generated.get("runtime_bosses", [])
    if len(left_runtime) != len(right_runtime):
        raise AssertionError(f"{generated['id']}: runtime Boss count changed")
    for boss_index, (left, right) in enumerate(zip(left_runtime, right_runtime), 1):
        for key in ("wave", "type", "lane"):
            if left.get(key) != right.get(key):
                raise AssertionError(
                    f"{generated['id']} runtime Boss {boss_index}: {key} changed"
                )


def normalized_group(level_id: str, wave_no: int, key: str, index: int, raw: dict,
                     zombies: dict, lanes: set[str]) -> dict:
    if not isinstance(raw, dict):
        raise AssertionError(f"{level_id} W{wave_no} {key}[{index}] must be an object")
    enemy_id = str(raw.get("type", ""))
    if enemy_id not in zombies:
        raise AssertionError(f"{level_id} W{wave_no} {key}[{index}]: unknown enemy type {enemy_id}")
    lane = str(raw.get("lane", ""))
    if lane not in lanes:
        raise AssertionError(f"{level_id} W{wave_no} {key}[{index}]: non-existing lane {lane}")
    count = int(raw.get("count", 0))
    interval = float(raw.get("interval", 0.0))
    if count <= 0 or interval <= 0.0:
        raise AssertionError(f"{level_id} W{wave_no} {key}[{index}]: count/interval must be positive")
    return {"type": enemy_id, "count": count, "interval": interval, "lane": lane}


def normalized_runtime_boss(level_id: str, index: int, raw: dict,
                            bosses: dict, lanes: set[str]) -> dict:
    if not isinstance(raw, dict):
        raise AssertionError(f"{level_id} runtime_bosses[{index}] must be an object")
    boss_id = str(raw.get("type", ""))
    if boss_id not in bosses:
        raise AssertionError(f"{level_id} runtime_bosses[{index}]: unknown Boss {boss_id}")
    wave = int(raw.get("wave", 0))
    interval = float(raw.get("interval", 0.0))
    spawn_delay = float(raw.get("spawn_delay", 0.0))
    lane = str(raw.get("lane", ""))
    if wave < 1 or wave > 5 or interval <= 0.0 or spawn_delay < 0.0 or lane not in lanes:
        raise AssertionError(
            f"{level_id} runtime_bosses[{index}]: invalid wave/interval/spawn_delay/lane"
        )
    result = {"wave": wave, "type": boss_id, "interval": interval, "lane": lane}
    if spawn_delay > 0.0:
        result["spawn_delay"] = spawn_delay
    return result


def baseline_interval_floor(baseline_wave: dict, key: str, group_index: int, multiplier: float) -> float:
    groups = baseline_wave.get(key, [])
    if not groups:
        groups = baseline_wave.get("spawns", []) or baseline_wave.get("support", [])
    source = groups[min(group_index, len(groups) - 1)] if groups else {"interval": 0.8}
    return float(source.get("interval", 0.8)) * multiplier


def apply_wave_solution(level_id: str, wave: dict, solution: dict, baseline_wave: dict,
                        wave_no: int, min_interval_mult: float, zombies: dict,
                        lanes: set[str]) -> None:
    hp_coef = float(solution.get("hp_coef", 1.0))
    if abs(hp_coef - 1.0) < 1e-12:
        wave.pop("hp_coef", None)
    else:
        wave["hp_coef"] = hp_coef
    for key in ("spawns", "support"):
        if key not in solution:
            continue
        groups = solution[key]
        if not isinstance(groups, list):
            raise AssertionError(f"{level_id} W{wave_no}: {key} must be an array")
        normalized = [
            normalized_group(level_id, wave_no, key, index, raw, zombies, lanes)
            for index, raw in enumerate(groups, 1)
        ]
        if normalized:
            wave[key] = normalized
        else:
            wave.pop(key, None)
    for key, solution_key in (("spawns", "spawn_counts"), ("support", "support_counts")):
        if solution_key not in solution:
            continue
        counts = solution[solution_key]
        groups = wave.get(key, [])
        if not isinstance(counts, list) or len(counts) != len(groups):
            raise AssertionError(f"{level_id} W{wave_no}: {solution_key} length mismatch")
        for group, count in zip(groups, counts):
            group["count"] = int(count)
    for key, solution_key in (("spawns", "spawn_intervals"), ("support", "support_intervals")):
        if solution_key not in solution:
            continue
        intervals = solution[solution_key]
        groups = wave.get(key, [])
        baseline_groups = baseline_wave.get(key, [])
        if not isinstance(intervals, list) or len(intervals) != len(groups):
            raise AssertionError(f"{level_id} W{wave_no}: {solution_key} length mismatch")
        for group_index, (group, baseline_group, interval) in enumerate(zip(groups, baseline_groups, intervals), 1):
            floor = baseline_interval_floor(baseline_wave, key, group_index - 1, min_interval_mult)
            if float(interval) + 1e-9 < floor:
                raise AssertionError(
                    f"{level_id} W{wave_no} {key}[{group_index}]: interval {interval} below {floor:.4f}"
                )
            group["interval"] = float(interval)


def build_expected(levels: list[dict], targets: dict, baseline_fixture: dict,
                   selected: set[int], zombies: dict, bosses: dict) -> list[dict]:
    generated = copy.deepcopy(levels)
    by_id = {row["id"]: row for row in generated}
    baseline_by_id = {row["id"]: row for row in baseline_fixture["levels"]}
    solutions = targets.get("pilot_chapter6", {}).get("levels", {})
    shape_rule = targets["pacing_rules"]["within_level_shape"]
    owner_envelope = targets["pacing_rules"]["owner_authorized_topology_envelope"]
    allowed_levels = set(range(int(owner_envelope["allowed_levels"][0]), int(owner_envelope["allowed_levels"][1]) + 1))
    if not selected.issubset(allowed_levels):
        raise AssertionError("enemy-topology generator escaped the Owner-authorized chapter-six scope")
    lanes = existing_lane_values(baseline_fixture["levels"])
    for number in sorted(selected):
        level_id = f"level_{number:03d}"
        if level_id not in solutions:
            raise AssertionError(f"{level_id}: no pilot solution in campaign_pacing_targets.json")
        baseline = copy.deepcopy(baseline_by_id[level_id])
        current_contract = by_id[level_id].get("clear_requirement")
        solution = solutions[level_id]
        usage = solution.get("envelope_usage", {})
        min_interval_mult = float(usage.get("min_interval_vs_baseline", shape_rule["min_interval_vs_baseline"]))
        if min_interval_mult + 1e-9 < float(owner_envelope["min_interval_vs_baseline"]):
            raise AssertionError(f"{level_id}: interval envelope exceeds Owner authorization")
        baseline["difficulty_coef"] = float(solution["difficulty_coef"])
        run_xp_budget = int(solution.get("run_xp_budget", 0))
        if run_xp_budget > 0:
            baseline["run_xp_budget"] = run_xp_budget
        else:
            baseline.pop("run_xp_budget", None)
        floor = str(solution.get("offer_category_floor", "")).strip()
        if floor:
            baseline["offer_category_floor"] = floor
        else:
            baseline.pop("offer_category_floor", None)
        wave_solutions = solution.get("waves", [])
        if len(wave_solutions) != len(baseline.get("waves", [])):
            raise AssertionError(f"{level_id}: wave solution count mismatch")
        original = baseline_by_id[level_id]
        for wave_no, (wave, wave_solution, baseline_wave) in enumerate(
            zip(baseline["waves"], wave_solutions, original["waves"]), 1
        ):
            apply_wave_solution(
                level_id, wave, wave_solution, baseline_wave, wave_no,
                min_interval_mult, zombies, lanes,
            )
        allow_runtime_roster_change = "runtime_bosses" in solution
        if allow_runtime_roster_change:
            runtime_bosses = solution["runtime_bosses"]
            if not isinstance(runtime_bosses, list):
                raise AssertionError(f"{level_id}: runtime_bosses must be an array")
            normalized_bosses = [
                normalized_runtime_boss(level_id, index, raw, bosses, lanes)
                for index, raw in enumerate(runtime_bosses, 1)
            ]
            if normalized_bosses:
                baseline["runtime_bosses"] = normalized_bosses
            else:
                baseline.pop("runtime_bosses", None)
        elif "runtime_boss_intervals" in solution:
            intervals = solution["runtime_boss_intervals"]
            runtime_bosses = baseline.get("runtime_bosses", [])
            if not isinstance(intervals, list) or len(intervals) != len(runtime_bosses):
                raise AssertionError(f"{level_id}: runtime_boss_intervals length mismatch")
            for boss_index, (runtime_boss, interval) in enumerate(zip(runtime_bosses, intervals), 1):
                value = float(interval)
                if value <= 0.0:
                    raise AssertionError(
                        f"{level_id} runtime Boss {boss_index}: interval must be positive"
                    )
                runtime_boss["interval"] = value
        if current_contract is not None:
            baseline["clear_requirement"] = current_contract
        assert_frozen_boss_shape(original, baseline, allow_runtime_roster_change)
        if level_id == "level_051" and bool(owner_envelope["freeze_level_051_wave_1"]):
            assert_frozen_wave(level_id, original, baseline, 1)
        by_id[level_id].clear()
        by_id[level_id].update(baseline)
    return generated


def wave_composite(level: dict, wave: dict, economy: dict) -> float:
    return (
        float(level.get("difficulty_coef", 1.0))
        * sim.wave_hp_coef(wave)
        * sim.late_wave_hp_bonus(
            economy,
            sim.wave_number(wave),
            level_no=sim.level_number(level),
            card_picks=int(level.get("target_card_picks", 4)),
        )
    )


def effective_count(level: dict, wave: dict, economy: dict) -> int:
    count_mult = sim.late_wave_count_mult(economy, sim.wave_number(wave), sim.level_number(level))
    return sum(
        int(round(int(group.get("count", 0)) * count_mult))
        for group in list(wave.get("spawns", [])) + list(wave.get("support", []))
    )


def wave_effective_durability(level: dict, wave: dict, zombies: dict, economy: dict) -> float:
    count_mult = sim.late_wave_count_mult(economy, sim.wave_number(wave), sim.level_number(level))
    hp_weight = 0.0
    for group in list(wave.get("spawns", [])) + list(wave.get("support", [])):
        count = int(round(int(group.get("count", 0)) * count_mult))
        hp_weight += count * float(zombies[str(group.get("type", ""))].get("hp_coef", 1.0))
    return hp_weight * wave_composite(level, wave, economy)


def weighted_average_composite(level: dict, economy: dict) -> float:
    weighted = [(effective_count(level, wave, economy), wave_composite(level, wave, economy)) for wave in level["waves"]]
    denominator = sum(count for count, _ in weighted)
    return sum(count * composite for count, composite in weighted) / max(denominator, 1)


def spawn_duration(level: dict, economy: dict) -> float:
    duration = 0.0
    for wave in level.get("waves", []):
        count_mult = sim.late_wave_count_mult(economy, sim.wave_number(wave), sim.level_number(level))
        for group in list(wave.get("spawns", [])) + list(wave.get("support", [])):
            count = int(round(int(group.get("count", 0)) * count_mult))
            duration += count * float(group.get("interval", 0.8))
    return duration


def validate_static(levels: list[dict], targets: dict, baseline_fixture: dict,
                    zombies: dict, economy: dict, selected: set[int]) -> list[dict]:
    rules = targets["pacing_rules"]
    hp_rule = rules["wave_hp_coef"]
    shape_rule = rules["within_level_shape"]
    continuity = rules["between_level_continuity"]
    envelope = rules["owner_authorized_topology_envelope"]
    solutions = targets["pilot_chapter6"]["levels"]
    by_number = {sim.level_number(row): row for row in levels}
    baseline_by_number = {sim.level_number(row): row for row in baseline_fixture["levels"]}
    report = []
    for number in sorted(selected):
        level = by_number[number]
        baseline_level = baseline_by_number[number]
        findings: list[str] = []
        usage = solutions[level["id"]].get("envelope_usage", {})
        max_final_ratio = float(usage.get(
            "max_final_to_first_composite_ratio", hp_rule["max_final_to_first_composite_ratio"]))
        if max_final_ratio > float(envelope["max_final_to_first_composite_ratio"]) + 1e-9:
            findings.append("W5/W1 envelope exceeds the original topology guardrail")
        max_wave_share = float(usage.get("max_wave_share", shape_rule["max_wave_share"]))
        max_adjacent_share = float(usage.get("max_adjacent_share_ratio", shape_rule["max_adjacent_share_ratio"]))
        if max_wave_share > float(envelope["max_wave_share"]) + 1e-9:
            findings.append("wave-share envelope exceeds the original topology guardrail")
        if max_adjacent_share > float(envelope["max_adjacent_share_ratio"]) + 1e-9:
            findings.append("adjacent-share envelope exceeds the original topology guardrail")
        waves = level.get("waves", [])
        hp_values = [sim.wave_hp_coef(wave) for wave in waves]
        if any(value < float(hp_rule["minimum"]) - 1e-9 for value in hp_values):
            findings.append(f"hp_coef below the original {hp_rule['minimum']} guardrail")
        composites = [wave_composite(level, wave, economy) for wave in waves]
        if bool(hp_rule["composite_nondecreasing"]) and any(
            right + 1e-9 < left for left, right in zip(composites, composites[1:])
        ):
            findings.append("composite durability is not nondecreasing")
        adjacent_composite = [right / max(left, 1e-9) for left, right in zip(composites, composites[1:])]
        if any(value > float(hp_rule["max_adjacent_composite_ratio"]) + 1e-9 for value in adjacent_composite):
            findings.append("adjacent composite durability exceeds the original ratio guardrail")
        final_first = composites[-1] / max(composites[0], 1e-9)
        if final_first > max_final_ratio + 1e-9:
            findings.append("W5/W1 composite durability exceeds the recorded envelope")
        durability = [wave_effective_durability(level, wave, zombies, economy) for wave in waves]
        total = sum(durability)
        shares = [value / max(total, 1e-9) for value in durability]
        if bool(shape_rule["effective_durability_share_nondecreasing"]) and any(
            right + 1e-9 < left for left, right in zip(shares, shares[1:])
        ):
            findings.append("effective durability shares are not nondecreasing")
        if max(shares, default=0.0) > max_wave_share + 1e-9:
            findings.append("a wave exceeds the recorded durability-share guardrail")
        adjacent_shares = [right / max(left, 1e-9) for left, right in zip(shares, shares[1:])]
        if any(value > max_adjacent_share + 1e-9 for value in adjacent_shares):
            findings.append("adjacent durability shares exceed the recorded ratio guardrail")
        baseline_late_bodies = sum(
            effective_count(baseline_level, wave, economy) for wave in baseline_level.get("waves", [])[3:]
        )
        late_bodies = sum(effective_count(level, wave, economy) for wave in waves[3:])
        baseline_durability = sum(
            wave_effective_durability(baseline_level, wave, zombies, economy)
            for wave in baseline_level.get("waves", [])
        )
        if final_first > float(hp_rule["max_final_to_first_composite_ratio"]) + 1e-9:
            if bool(envelope["final_ratio_above_base_requires_fewer_late_bodies"]) and late_bodies >= baseline_late_bodies:
                findings.append("relaxed W5/W1 ratio does not use fewer W4/W5 bodies")
            prior_budget = float(usage.get("prior_proposal_total_durability_budget", baseline_durability))
            if bool(envelope["final_ratio_above_base_requires_no_total_durability_growth"]) and total > prior_budget + 1e-9:
                findings.append(
                    "relaxed W5/W1 ratio exceeds the prior proposal durability budget "
                    f"({total:.4f} > {prior_budget:.4f})"
                )
        duration = spawn_duration(level, economy)
        duration_cap = float(envelope[
            "static_duration_max_boss_seconds" if any(wave.get("boss") for wave in waves)
            else "static_duration_max_normal_seconds"
        ])
        if duration > duration_cap + 1e-9:
            findings.append(f"spawn duration {duration:.2f}s exceeds the original {duration_cap:.2f}s guardrail")
        report.append({
            "level": number,
            "hp_coef": hp_values,
            "composite": [round(value, 6) for value in composites],
            "global_w2_to_w3_jump": round(
                sim.late_wave_hp_bonus(
                    economy,
                    3,
                    level_no=number,
                    card_picks=int(level.get("target_card_picks", 4)),
                )
                / max(
                    sim.late_wave_hp_bonus(
                        economy,
                        2,
                        level_no=number,
                        card_picks=int(level.get("target_card_picks", 4)),
                    ),
                    1e-9,
                ),
                6,
            ),
            "effective_durability_share": [round(value, 6) for value in shares],
            "weighted_average_composite": round(weighted_average_composite(level, economy), 6),
            "effective_durability_total": round(total, 6),
            "late_body_count": late_bodies,
            "baseline_late_body_count": baseline_late_bodies,
            "spawn_duration_seconds": round(duration, 3),
            "envelope_usage": usage,
            "guardrail_findings": findings,
        })
    start, end = (int(value) for value in continuity["internal_levels"])
    max_growth = float(continuity["max_weighted_average_composite_increase"])
    for number in range(start, end + 1):
        if number not in selected or number + 1 not in selected:
            continue
        left = weighted_average_composite(by_number[number], economy)
        right = weighted_average_composite(by_number[number + 1], economy)
        if right > left * (1.0 + max_growth) + 1e-9:
            next(row for row in report if row["level"] == number + 1)["guardrail_findings"].append(
                f"weighted composite {right:.6f} rises more than the original {max_growth:.0%} "
                f"continuity guardrail from {left:.6f}"
            )
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--capture-baseline", action="store_true")
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--levels", default="")
    args = parser.parse_args()
    if sum((args.capture_baseline, args.write, args.check)) != 1:
        parser.error("choose exactly one of --capture-baseline, --write, or --check")
    levels = load_json(LEVELS_PATH)
    if args.capture_baseline:
        if BASELINE_PATH.exists():
            raise SystemExit(f"refusing to overwrite existing {BASELINE_PATH}")
        write_json(BASELINE_PATH, capture_baseline(levels))
        print(f"Captured {BASELINE_PATH.relative_to(ROOT)}")
        return 0
    if not BASELINE_PATH.exists():
        raise SystemExit(f"missing {BASELINE_PATH}; capture the clean B1 baseline first")
    selected = parse_levels(args.levels)
    targets = load_json(TARGETS_PATH)
    baseline = load_json(BASELINE_PATH)
    zombies = load_json(ZOMBIES_PATH)
    bosses = load_json(BOSSES_PATH)
    economy = load_json(ECONOMY_PATH)
    expected = build_expected(levels, targets, baseline, selected, zombies, bosses)
    report = validate_static(expected, targets, baseline, zombies, economy, selected)
    if args.check:
        actual_by_id = {row["id"]: authored_projection(row) for row in levels}
        expected_by_id = {row["id"]: authored_projection(row) for row in expected}
        stale = [f"level_{number:03d}" for number in sorted(selected) if actual_by_id[f"level_{number:03d}"] != expected_by_id[f"level_{number:03d}"]]
        if stale:
            raise SystemExit(f"campaign pacing output stale: {', '.join(stale)}")
        print(f"Campaign pacing fresh for {len(selected)} level(s)")
    else:
        write_json(LEVELS_PATH, expected)
        print(f"Wrote campaign pacing for {len(selected)} level(s)")
    for row in report:
        print(
            f"level_{row['level']:03d} hp={row['hp_coef']} "
            f"shares={[round(value * 100.0, 2) for value in row['effective_durability_share']]} "
            f"global_w2_w3={row['global_w2_to_w3_jump']:.4f} "
            f"avg={row['weighted_average_composite']:.4f} "
            f"duration={row['spawn_duration_seconds']:.1f}s bodies={row['late_body_count']}"
        )
        for finding in row["guardrail_findings"]:
            print(f"  report-only guardrail: {finding}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
