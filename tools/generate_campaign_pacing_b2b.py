#!/usr/bin/env python3
"""Apply the design/40 B2b chapter 1-5 solutions from a frozen baseline.

The B2b rebuild is intentionally isolated from the accepted Chapter 6 pilot
and the B2a Chapter 7-10 data.  This generator restores Levels 001-050 from a
frozen authored baseline, applies absolute overrides from a single solution
file, and verifies that Levels 051-099 remain byte-for-byte unchanged.
"""
from __future__ import annotations

import argparse
import copy
import json
from pathlib import Path

import generate_campaign_pacing_b2 as pacing


ROOT = Path(__file__).resolve().parents[1]
LEVELS_PATH = ROOT / "data" / "levels.json"
TARGETS_PATH = ROOT / "data" / "campaign_pacing_targets.json"
BASELINE_PATH = ROOT / "tools" / "campaign_pacing_b2b_baseline.json"
SOLUTIONS_PATH = ROOT / "data" / "campaign_pacing_b2b_solutions.json"


def parse_levels(text: str) -> set[int]:
    if not text.strip():
        return set(range(1, 51))
    result = {int(token) for token in text.split(",") if token.strip()}
    if not result or any(number < 1 or number > 50 for number in result):
        raise ValueError("--levels must be a comma-separated subset of 1..50")
    return result


def tail_hash(levels: list[dict]) -> str:
    return pacing.canonical_hash([pacing.authored_projection(row) for row in levels[50:99]])


def capture_baseline(levels: list[dict]) -> dict:
    rows = [pacing.authored_projection(row) for row in levels[:50]]
    if len(rows) != 50:
        raise AssertionError("B2b baseline must contain levels 001-050")
    return {
        "schema_version": 1,
        "source": "data/levels.json before design/40 B2b generation",
        "authored_sha256": pacing.canonical_hash(rows),
        "frozen_tail_sha256": tail_hash(levels),
        "levels": rows,
    }


def initial_solutions(levels: list[dict], targets: dict, baseline: dict) -> dict:
    chapter_targets = targets["chapter_level_targets"]
    rows: dict[str, dict] = {}
    for level in levels[:50]:
        number = int(str(level["id"]).split("_")[-1])
        chapter = (number - 1) // 10 + 1
        index = (number - 1) % 10
        rows[level["id"]] = {
            "target_grade": chapter_targets[str(chapter)][index],
            "difficulty_coef": float(level.get("difficulty_coef", 1.0)),
            "waves": [
                ({"hp_coef": float(wave["hp_coef"])} if "hp_coef" in wave else {})
                for wave in level.get("waves", [])
            ],
        }
    return {
        "schema_version": 1,
        "status": "b2b_tuning",
        "authoritative_profile": "tier_b",
        "scope": [1, 50],
        "baseline_sha256": str(baseline["authored_sha256"]),
        "frozen_tail_sha256": str(baseline["frozen_tail_sha256"]),
        "levels": rows,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--levels", default="")
    parser.add_argument("--capture-baseline", action="store_true")
    parser.add_argument("--capture-solutions", action="store_true")
    parser.add_argument("--check", action="store_true")
    options = parser.parse_args()

    levels = pacing.load_json(LEVELS_PATH)
    targets = pacing.load_json(TARGETS_PATH)
    if options.capture_baseline:
        pacing.write_json(BASELINE_PATH, capture_baseline(levels))
    if not BASELINE_PATH.exists():
        raise FileNotFoundError("capture the B2b baseline first")
    baseline = pacing.load_json(BASELINE_PATH)
    if options.capture_solutions:
        pacing.write_json(SOLUTIONS_PATH, initial_solutions(levels, targets, baseline))
    if not SOLUTIONS_PATH.exists():
        raise FileNotFoundError("capture the B2b solutions first")
    solutions = pacing.load_json(SOLUTIONS_PATH)

    frozen_tail = str(baseline["frozen_tail_sha256"])
    if tail_hash(levels) != frozen_tail:
        raise AssertionError("Levels 051-099 drifted before B2b generation")
    if str(solutions.get("frozen_tail_sha256", "")) != frozen_tail:
        raise AssertionError("B2b solution tail hash does not match its baseline")

    selected = parse_levels(options.levels)
    baseline_by_id = {row["id"]: row for row in baseline["levels"]}
    current_by_id = {row["id"]: row for row in levels}
    generated = copy.deepcopy(levels)
    for index, current in enumerate(generated):
        number = int(str(current["id"]).split("_")[-1])
        if number not in selected:
            continue
        level_id = current["id"]
        if level_id not in baseline_by_id or level_id not in solutions["levels"]:
            raise AssertionError(f"{level_id}: missing B2b baseline or solution")
        current_contract = current_by_id[level_id].get("clear_requirement")
        generated[index] = pacing.apply_solution(
            baseline_by_id[level_id], solutions["levels"][level_id], current_contract
        )

    if tail_hash(generated) != frozen_tail:
        raise AssertionError("B2b generator changed frozen Levels 051-099")
    rendered = json.dumps(generated, ensure_ascii=False, indent="\t") + "\n"
    current_rendered = LEVELS_PATH.read_text(encoding="utf-8")
    if options.check:
        if rendered != current_rendered:
            print("B2b campaign pacing is stale; run tools/generate_campaign_pacing_b2b.py")
            return 1
        print("B2b campaign pacing generator: fresh; Levels 051-099 frozen")
        return 0
    LEVELS_PATH.write_text(rendered, encoding="utf-8")
    print(f"Generated B2b pacing for {len(selected)} levels; Levels 051-099 unchanged")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
