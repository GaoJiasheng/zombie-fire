#!/usr/bin/env python3
"""Regression checks for frontline sweep provenance and star-table guards."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import report_b2b_star_table as star_report  # noqa: E402
import run_frontline_sweep as sweep  # noqa: E402


def sample_options() -> argparse.Namespace:
    return argparse.Namespace(
        fixture="res://design/audits/campaign_progression_fixture_builds.json",
        levels=[1],
        profile="tier_b",
        card_policy="v2",
        ignore_level_guarantees=False,
        ignore_offer_category_floor=False,
        challenge=False,
        fail_fast=False,
        seeds=[1103],
        accel=60.0,
        jobs=1,
        batch_size=1,
    )


def test_sweep_payload_has_provenance() -> list[str]:
    failures: list[str] = []
    provenance = sweep.collect_run_provenance(ROOT, sample_options().fixture)
    payload = sweep.build_payload(sample_options(), [], 1.25, [1.0], provenance)
    for key in ("combat_input_fingerprint", "fixture_sha256", "git_head", "godot_version"):
        if not payload.get(key):
            failures.append(f"sweep output is missing {key}")
    fingerprint = payload.get("combat_input_fingerprint", {})
    for segment in sweep.FINGERPRINT_SEGMENTS:
        if not fingerprint.get(segment):
            failures.append(f"combat_input_fingerprint is missing {segment}")
    return failures


def test_stale_archive_is_rejected() -> list[str]:
    failures: list[str] = []
    archived = ROOT / "design/audits/b2b_final_001_099_converged_tier_b_v21_10.json"
    completed = subprocess.run(
        [
            sys.executable,
            str(ROOT / "tools/report_b2b_star_table.py"),
            "--sweep",
            str(archived),
            "--check-approved",
        ],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 2:
        failures.append(f"stale archive returned {completed.returncode}, expected 2")
    for segment in (*sweep.FINGERPRINT_SEGMENTS, "fixture_sha256"):
        if segment not in completed.stderr:
            failures.append(f"stale archive diagnostic omitted {segment}")
    return failures


def test_matching_sweep_can_be_derived() -> list[str]:
    failures: list[str] = []
    provenance = sweep.collect_run_provenance(ROOT, sample_options().fixture)
    payload = sweep.build_payload(
        sample_options(),
        [{"level": 1, "seed": 1103, "victory": True, "base_ratio": 1.0}],
        1.25,
        [1.0],
        provenance,
    )
    with tempfile.TemporaryDirectory(prefix="frontline_metadata_test_") as temp_name:
        temp_dir = Path(temp_name)
        sweep_path = temp_dir / "sweep.json"
        output_path = temp_dir / "stars.csv"
        sweep_path.write_text(json.dumps(payload), encoding="utf-8")
        completed = subprocess.run(
            [
                sys.executable,
                str(ROOT / "tools/report_b2b_star_table.py"),
                "--sweep",
                str(sweep_path),
                "--output",
                str(output_path),
                "--check-approved",
            ],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        if completed.returncode != 0:
            failures.append(
                f"matching sweep was rejected ({completed.returncode}): "
                f"{completed.stdout}{completed.stderr}"
            )
        if not output_path.is_file():
            failures.append("matching sweep did not produce a derived CSV")
    return failures


def main() -> int:
    failures: list[str] = []
    for check in (
        test_sweep_payload_has_provenance,
        test_stale_archive_is_rejected,
        test_matching_sweep_can_be_derived,
    ):
        failures.extend(check())
    if failures:
        print("Frontline sweep metadata check failed:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1
    print("Frontline sweep metadata check OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
