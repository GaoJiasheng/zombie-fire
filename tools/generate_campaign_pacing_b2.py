#!/usr/bin/env python3
"""Apply the design/40 B2 campaign solutions without touching the B1 pilot.

The authored pre-B2 levels 061-099 are stored in a baseline fixture.  This
generator always restores those rows first, then applies the absolute
overrides in ``data/campaign_pacing_b2_solutions.json``.  That makes tuning
reversible and idempotent while keeping chapter 6 byte-for-byte frozen.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LEVELS_PATH = ROOT / "data" / "levels.json"
SOLUTIONS_PATH = ROOT / "data" / "campaign_pacing_b2_solutions.json"
BASELINE_PATH = ROOT / "tools" / "campaign_pacing_b2a_baseline.json"
TARGETS_PATH = ROOT / "data" / "campaign_pacing_targets.json"


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, value) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")


def canonical_hash(value) -> str:
    raw = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def authored_projection(level: dict) -> dict:
    return {key: copy.deepcopy(value) for key, value in level.items() if key != "clear_requirement"}


def parse_levels(text: str) -> set[int]:
    if not text.strip():
        return set(range(61, 100))
    result = {int(token) for token in text.split(",") if token.strip()}
    if not result or any(number < 61 or number > 99 for number in result):
        raise ValueError("--levels must be a comma-separated subset of 61..99")
    return result


def chapter6_hash(levels: list[dict]) -> str:
    raw = json.dumps(
        levels[50:60], ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()


def capture_baseline(levels: list[dict]) -> dict:
    rows = [authored_projection(row) for row in levels[60:99]]
    if len(rows) != 39:
        raise AssertionError("B2a baseline must contain levels 061-099")
    return {
        "schema_version": 1,
        "source": "data/levels.json before design/40 B2a generation",
        "authored_sha256": canonical_hash(rows),
        "levels": rows,
    }


def initial_solutions(levels: list[dict], targets: dict) -> dict:
    chapter_targets = targets["chapter_level_targets"]
    rows: dict[str, dict] = {}
    for level in levels[60:99]:
        number = int(str(level["id"]).split("_")[-1])
        chapter = (number - 1) // 10 + 1
        index = (number - 1) % 10
        rows[level["id"]] = {
            "target_grade": chapter_targets[str(chapter)][index],
            "difficulty_coef": float(level.get("difficulty_coef", 1.0)),
            "waves": [{} for _wave in level.get("waves", [])],
        }
    return {
        "schema_version": 1,
        "status": "b2a_tuning",
        "authoritative_profile": "tier_b",
        "scope": [61, 99],
        "baseline_sha256": canonical_hash(
            [authored_projection(row) for row in levels[60:99]]
        ),
        "levels": rows,
    }


def apply_group_overrides(wave: dict, wave_solution: dict) -> None:
    for key in ("spawns", "support"):
        if key in wave_solution:
            groups = copy.deepcopy(wave_solution[key])
            if groups:
                wave[key] = groups
            else:
                wave.pop(key, None)
    for key, solution_key in (("spawns", "spawn_counts"), ("support", "support_counts")):
        if solution_key not in wave_solution:
            continue
        groups = wave.get(key, [])
        values = wave_solution[solution_key]
        if len(groups) != len(values):
            raise AssertionError(f"{solution_key} length mismatch")
        for group, count in zip(groups, values):
            group["count"] = int(count)
    for key, solution_key in (("spawns", "spawn_intervals"), ("support", "support_intervals")):
        if solution_key not in wave_solution:
            continue
        groups = wave.get(key, [])
        values = wave_solution[solution_key]
        if len(groups) != len(values):
            raise AssertionError(f"{solution_key} length mismatch")
        for group, interval in zip(groups, values):
            group["interval"] = float(interval)
    for key, solution_key in (("spawns", "spawn_types"), ("support", "support_types")):
        if solution_key not in wave_solution:
            continue
        groups = wave.get(key, [])
        values = wave_solution[solution_key]
        if len(groups) != len(values):
            raise AssertionError(f"{solution_key} length mismatch")
        for group, enemy_type in zip(groups, values):
            group["type"] = str(enemy_type)


def apply_solution(baseline: dict, solution: dict, clear_requirement) -> dict:
    result = copy.deepcopy(baseline)
    if clear_requirement is not None:
        result["clear_requirement"] = copy.deepcopy(clear_requirement)
    result["difficulty_coef"] = float(solution["difficulty_coef"])
    for key in (
        "run_xp_budget",
        "offer_category_floor",
        "xp_first_offer",
        "xp_offer_growth",
        "xp_offer_ramp",
        "target_card_picks",
    ):
        if key not in solution:
            continue
        value = solution[key]
        if value in (None, "", 0):
            result.pop(key, None)
        else:
            result[key] = copy.deepcopy(value)
    wave_solutions = solution.get("waves", [])
    if len(wave_solutions) != len(result.get("waves", [])):
        raise AssertionError(f"{result['id']}: wave solution count mismatch")
    for wave, wave_solution in zip(result["waves"], wave_solutions):
        if "hp_coef" in wave_solution:
            value = float(wave_solution["hp_coef"])
            if abs(value - 1.0) < 1e-12:
                wave.pop("hp_coef", None)
            else:
                wave["hp_coef"] = value
        apply_group_overrides(wave, wave_solution)
    if "runtime_bosses" in solution:
        bosses = copy.deepcopy(solution["runtime_bosses"])
        if bosses:
            result["runtime_bosses"] = bosses
        else:
            result.pop("runtime_bosses", None)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--levels", default="")
    parser.add_argument("--capture-baseline", action="store_true")
    parser.add_argument("--capture-solutions", action="store_true")
    parser.add_argument("--check", action="store_true")
    options = parser.parse_args()

    levels = load_json(LEVELS_PATH)
    targets = load_json(TARGETS_PATH)
    expected_ch6 = str(targets["frozen_contract"]["chapter6_levels_sha256"])
    if chapter6_hash(levels) != expected_ch6:
        raise AssertionError("chapter 6 drifted before B2a generation")
    if options.capture_baseline:
        write_json(BASELINE_PATH, capture_baseline(levels))
    if options.capture_solutions:
        write_json(SOLUTIONS_PATH, initial_solutions(levels, targets))
    if not BASELINE_PATH.exists() or not SOLUTIONS_PATH.exists():
        raise FileNotFoundError("capture the B2a baseline and solutions first")

    selected = parse_levels(options.levels)
    baseline = load_json(BASELINE_PATH)
    solutions = load_json(SOLUTIONS_PATH)
    baseline_by_id = {row["id"]: row for row in baseline["levels"]}
    current_by_id = {row["id"]: row for row in levels}
    generated = copy.deepcopy(levels)
    for index, current in enumerate(generated):
        number = int(str(current["id"]).split("_")[-1])
        if number not in selected:
            continue
        level_id = current["id"]
        if level_id not in baseline_by_id or level_id not in solutions["levels"]:
            raise AssertionError(f"{level_id}: missing B2a baseline or solution")
        current_contract = current_by_id[level_id].get("clear_requirement")
        generated[index] = apply_solution(
            baseline_by_id[level_id], solutions["levels"][level_id], current_contract
        )

    if chapter6_hash(generated) != expected_ch6:
        raise AssertionError("B2a generator changed the frozen chapter 6")
    rendered = json.dumps(generated, ensure_ascii=False, indent="\t") + "\n"
    current_rendered = LEVELS_PATH.read_text(encoding="utf-8")
    if options.check:
        if rendered != current_rendered:
            print("B2a campaign pacing is stale; run tools/generate_campaign_pacing_b2.py")
            return 1
        print("B2a campaign pacing generator: fresh; chapter 6 frozen")
        return 0
    LEVELS_PATH.write_text(rendered, encoding="utf-8")
    print(f"Generated B2a pacing for {len(selected)} levels; chapter 6 unchanged")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
