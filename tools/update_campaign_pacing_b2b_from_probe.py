#!/usr/bin/env python3
"""Update B2b difficulty coefficients from an authoritative probe sweep.

This helper intentionally handles only the monotonic, full-base cases where
enemy durability is the safe first lever.  Levels with base damage, losses,
or the protected 001-003 onboarding contract are reported for manual wave
shape work instead of being force-fitted by one scalar.
"""
from __future__ import annotations

import argparse
import json
import math
import statistics
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOLUTIONS_PATH = ROOT / "data" / "campaign_pacing_b2b_solutions.json"
TARGETS_PATH = ROOT / "data" / "campaign_pacing_targets.json"


def csv_ints(value: str) -> set[int]:
    values = {int(token) for token in value.split(",") if token.strip()}
    if any(number < 1 or number > 50 for number in values):
        raise argparse.ArgumentTypeError("expected a comma-separated subset of 1..50")
    return values


def level_number(level_id: str) -> int:
    return int(level_id.rsplit("_", 1)[-1])


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--probe", type=Path, required=True)
    parser.add_argument("--levels", type=csv_ints, default=set(range(4, 51)))
    parser.add_argument("--exclude", type=csv_ints, default=set())
    parser.add_argument("--elasticity", type=float, default=0.72)
    parser.add_argument("--min-step", type=float, default=0.70)
    parser.add_argument("--max-step", type=float, default=2.00)
    parser.add_argument("--apply", action="store_true")
    options = parser.parse_args()

    probe_path = options.probe if options.probe.is_absolute() else ROOT / options.probe
    probe = json.loads(probe_path.read_text(encoding="utf-8"))
    solutions = json.loads(SOLUTIONS_PATH.read_text(encoding="utf-8"))
    targets = json.loads(TARGETS_PATH.read_text(encoding="utf-8"))
    grouped: dict[int, list[dict]] = defaultdict(list)
    for run in probe.get("runs", []):
        grouped[int(run["level"])].append(run)

    updates: list[tuple[int, float, float, float, float]] = []
    manual: list[tuple[int, str]] = []
    for number in sorted(options.levels - options.exclude):
        runs = grouped.get(number, [])
        if not runs:
            manual.append((number, "missing probe runs"))
            continue
        if any(not bool(run.get("victory", False)) for run in runs):
            manual.append((number, "contains a loss"))
            continue
        base = statistics.median(float(run["base_ratio"]) for run in runs)
        if base < 0.995:
            manual.append((number, f"base damaged ({base * 100:.1f}%)"))
            continue
        level_id = f"level_{number:03d}"
        row = solutions["levels"][level_id]
        band = targets["target_bands"][row["target_grade"]]
        progress = statistics.median(float(run["max_progress"]) for run in runs)
        lower, upper = (float(value) / 100.0 for value in band["max_progress_pct"])
        if lower <= progress <= upper:
            continue
        center = float(band["center"]["progress_pct"]) / 100.0
        ratio = center / max(progress, 0.01)
        step = min(options.max_step, max(options.min_step, math.pow(ratio, options.elasticity)))
        old = float(row["difficulty_coef"])
        new = round(old * step, 4)
        updates.append((number, old, new, progress, base))

    for number, old, new, progress, base in updates:
        print(
            f"level_{number:03d}: coef {old:.4f} -> {new:.4f}; "
            f"progress={progress * 100:.2f}% base={base * 100:.2f}%"
        )
        if options.apply:
            solutions["levels"][f"level_{number:03d}"]["difficulty_coef"] = new
    for number, reason in manual:
        print(f"level_{number:03d}: MANUAL ({reason})")
    if options.apply:
        SOLUTIONS_PATH.write_text(
            json.dumps(solutions, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8"
        )
        print(f"Applied {len(updates)} safe coefficient updates")
    else:
        print(f"Dry run: {len(updates)} safe updates; pass --apply to write")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
