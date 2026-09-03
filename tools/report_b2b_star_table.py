#!/usr/bin/env python3
"""Derive/check B2b stars from a sweep, rejecting stale combat inputs by default.

Examples:
  python3 tools/report_b2b_star_table.py --sweep sweep.json --output /tmp/stars.csv
  python3 tools/report_b2b_star_table.py --sweep sweep.json --check-approved

Use ``--allow-fingerprint-mismatch`` only for an intentional forensic read of old
evidence. It never changes the approved star table.
"""

from __future__ import annotations

import argparse
import csv
import json
import statistics
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

from run_frontline_sweep import (  # noqa: E402
    FINGERPRINT_SEGMENTS,
    collect_run_provenance,
)

DEFAULT_FIXTURE = "res://design/audits/campaign_progression_fixture_builds.json"
DEFAULT_APPROVED = ROOT / "design/audits/b2b_star_table_old_to_new.csv"


def provenance_differences(
    sweep: dict,
    current: dict[str, object],
) -> list[str]:
    differences: list[str] = []
    archived = sweep.get("combat_input_fingerprint")
    if not isinstance(archived, dict):
        archived = {}
    current_fingerprint = current["combat_input_fingerprint"]
    assert isinstance(current_fingerprint, dict)
    for segment in FINGERPRINT_SEGMENTS:
        old_value = archived.get(segment, "<missing>")
        new_value = current_fingerprint[segment]
        if old_value != new_value:
            differences.append(f"{segment}: sweep={old_value} current={new_value}")
    old_fixture_sha = sweep.get("fixture_sha256", "<missing>")
    new_fixture_sha = current["fixture_sha256"]
    if old_fixture_sha != new_fixture_sha:
        differences.append(
            f"fixture_sha256: sweep={old_fixture_sha} current={new_fixture_sha}"
        )
    return differences


def star_for_runs(runs: list[dict]) -> tuple[int, float, int]:
    if not runs:
        raise ValueError("cannot derive a star result without runs")
    median_base_pct = statistics.median(
        float(run.get("base_ratio", 0.0)) * 100.0 for run in runs
    )
    wins = sum(bool(run.get("victory", False)) for run in runs)
    if wins * 2 <= len(runs):
        return 0, median_base_pct, wins
    if median_base_pct >= 70.0:
        return 3, median_base_pct, wins
    if median_base_pct >= 35.0:
        return 2, median_base_pct, wins
    return 1, median_base_pct, wins


def derived_rows(sweep: dict) -> list[dict[str, object]]:
    grouped: dict[int, list[dict]] = defaultdict(list)
    for run in sweep.get("runs", []):
        grouped[int(run["level"])].append(run)
    rows: list[dict[str, object]] = []
    for level in sorted(grouped):
        star, median_base_pct, wins = star_for_runs(grouped[level])
        rows.append(
            {
                "level": f"{level:03d}",
                "new_star": star,
                "new_median_base_pct": f"{median_base_pct:.4f}",
                "wins": wins,
                "runs": len(grouped[level]),
            }
        )
    return rows


def check_approved(rows: list[dict[str, object]], approved_path: Path) -> list[str]:
    with approved_path.open(newline="", encoding="utf-8") as handle:
        approved = {row["level"]: row for row in csv.DictReader(handle)}
    failures: list[str] = []
    for row in rows:
        level = str(row["level"])
        expected = approved.get(level)
        if expected is None:
            failures.append(f"L{level}: missing from approved star table")
            continue
        if int(row["new_star"]) != int(expected["new_star"]):
            failures.append(
                f"L{level}: derived {row['new_star']}★, approved {expected['new_star']}★"
            )
    return failures


def write_rows(path: Path, rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=("level", "new_star", "new_median_base_pct", "wins", "runs"),
        )
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sweep", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--check-approved", action="store_true")
    parser.add_argument("--approved-table", type=Path, default=DEFAULT_APPROVED)
    parser.add_argument("--allow-fingerprint-mismatch", action="store_true")
    parser.add_argument("--project-root", type=Path, default=ROOT, help=argparse.SUPPRESS)
    options = parser.parse_args()

    project_root = options.project_root.resolve()
    sweep = json.loads(options.sweep.read_text(encoding="utf-8"))
    fixture = str(sweep.get("fixture_source", DEFAULT_FIXTURE))
    current = collect_run_provenance(project_root, fixture)
    differences = provenance_differences(sweep, current)
    if differences:
        print("Combat input fingerprint mismatch:", file=sys.stderr)
        for difference in differences:
            print(f"- {difference}", file=sys.stderr)
        if not options.allow_fingerprint_mismatch:
            print(
                "Refusing to derive or compare stars. Use "
                "--allow-fingerprint-mismatch for an intentional forensic read.",
                file=sys.stderr,
            )
            return 2
        print("WARNING: fingerprint mismatch explicitly allowed.", file=sys.stderr)

    rows = derived_rows(sweep)
    if not rows:
        print("Sweep contains no runs; no star table can be derived.", file=sys.stderr)
        return 2
    if options.output:
        write_rows(options.output, rows)
        print(f"Derived star table: {options.output}")
    if options.check_approved:
        failures = check_approved(rows, options.approved_table)
        if failures:
            print("Approved star table comparison failed:", file=sys.stderr)
            for failure in failures:
                print(f"- {failure}", file=sys.stderr)
            return 1
        print(f"Approved star table comparison OK: {len(rows)} levels")
    elif not options.output:
        parser.error("choose --output and/or --check-approved")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
