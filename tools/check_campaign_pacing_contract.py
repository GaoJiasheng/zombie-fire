#!/usr/bin/env python3
"""Validate the owner-frozen campaign pacing contract.

The B2 rebuild is staged.  Contract checks are safe from the first B2 commit;
the graduation clearability assertion is enabled in release CI only after all
99 levels have been rebuilt.  Running with ``--enforce-graduation`` performs
the permanent, full analytical gate for the matchup-aware maxed free family.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
sys.path.insert(0, str(ROOT / "tools"))

import audit_campaign_frontline as frontline  # noqa: E402
from challenge_curve import rule_for_level as challenge_rule_for_level, validate as validate_challenge_curve  # noqa: E402
from power_ruler_model import maxed_free_build_for_level  # noqa: E402


def load(name: str):
    return json.loads((DATA / f"{name}.json").read_text(encoding="utf-8"))


def chapter6_hash(levels: list[dict]) -> str:
    # C-stage power contracts are derived data and are explicitly allowed to be
    # regenerated. Freeze only authored gameplay rows so a recommendation-scale
    # rebuild cannot masquerade as a wave/Boss/economy mutation (or vice versa).
    authored_rows = [
        {key: value for key, value in row.items() if key != "clear_requirement"}
        for row in levels[50:60]
    ]
    canonical = json.dumps(
        authored_rows, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")
    return hashlib.sha256(canonical).hexdigest()


def validate_frozen_contract(targets: dict, fixture: dict, levels: list[dict]) -> list[str]:
    errors: list[str] = []
    frozen = targets.get("frozen_contract", {}) or {}
    if targets.get("frozen") is not True:
        errors.append("campaign pacing targets must be owner-frozen for B2")
    if str(targets.get("status", "")) != "b2_owner_frozen":
        errors.append("campaign pacing status must be b2_owner_frozen")
    if str(frozen.get("authoritative_fire_rate_profile", "")) != "tier_b":
        errors.append("B2 authoritative fire-rate profile must be tier_b")

    grade_order = list(targets.get("grade_order", []))
    expected_counts = {
        str(key): int(value)
        for key, value in (frozen.get("target_grade_counts", {}) or {}).items()
    }
    actual_counts: Counter[str] = Counter()
    chapter_targets = targets.get("chapter_level_targets", {}) or {}
    chapter_quotas = targets.get("chapter_quotas", {}) or {}
    for chapter in range(1, 11):
        sequence = [str(value) for value in chapter_targets.get(str(chapter), [])]
        expected_length = 9 if chapter == 10 else 10
        if len(sequence) != expected_length:
            errors.append(
                f"chapter {chapter} target sequence has {len(sequence)} rows, expected {expected_length}"
            )
            continue
        actual_counts.update(sequence)
        quota = chapter_quotas.get(str(chapter), {}) or {}
        for grade in grade_order:
            if sequence.count(grade) != int(quota.get(grade, -1)):
                errors.append(
                    f"chapter {chapter} {grade} quota drift: sequence={sequence.count(grade)} "
                    f"quota={quota.get(grade)}"
                )
    actual_distribution = {
        grade: int(actual_counts.get(grade, 0))
        for grade in expected_counts
    }
    if actual_distribution != expected_counts:
        errors.append(
            f"campaign grade distribution drift: actual={actual_distribution} expected={expected_counts}"
        )
    if int(actual_counts.get("unwinnable", 0)) != 0:
        errors.append("owner-frozen target distribution must contain zero unwinnable levels")

    expected_hash = str(frozen.get("chapter6_levels_sha256", ""))
    actual_hash = chapter6_hash(levels)
    if actual_hash != expected_hash:
        errors.append(
            f"owner-approved chapter 6 changed: actual={actual_hash} expected={expected_hash}"
        )

    graduation_contract = frozen.get("max_free_graduation", {}) or {}
    graduation_fixture = fixture.get("max_free_graduation", {}) or {}
    if str(graduation_contract.get("fixture_id", "")) != str(graduation_fixture.get("id", "")):
        errors.append("max-free graduation fixture id does not match the frozen pacing contract")
    if str(graduation_fixture.get("fire_rate_profile", "")) != "tier_b":
        errors.append("max-free graduation fixture must use tier_b")
    if str(graduation_fixture.get("selection", "")) != "highest_power_for_build":
        errors.append("max-free graduation fixture must use matchup-aware power_for_build selection")
    return errors


def validate_challenge_contract(targets: dict, challenges: dict) -> list[str]:
    errors = validate_challenge_curve(challenges)
    level_count = sum(len(targets["chapter_level_targets"][str(chapter)]) for chapter in range(1, 11))
    for level_number in range(1, level_count + 1):
        fixture = challenge_rule_for_level(level_number, challenges)["reference_fixture"]
        expected_fixture = "paced_plus_10" if level_number <= 60 else ("maxed_free_matchup_aware_v1" if level_number <= 80 else "golden_law_tier_1_max")
        if fixture != expected_fixture:
            errors.append(f"challenge level_{level_number:03d} fixture route is {fixture}, expected {expected_fixture}")
    if level_count != 99 or level_count * 3 > 297:
        errors.append(f"challenge star supply exceeds 297★ or level coverage drifted: levels={level_count}")
    return errors


def graduation_results(levels: list[dict]) -> tuple[list[dict], list[dict]]:
    tables = frontline.TABLES
    rows: list[dict] = []
    failures: list[dict] = []
    for level in levels:
        contract = level.get("clear_requirement", {}).get("power_contract", {})
        build, power = maxed_free_build_for_level(
            level,
            contract,
            tables["characters"],
            tables["weapons"],
            tables["armors"],
            tables["chips"],
            tables["pets"],
            tables["skills"],
            tables["bosses"],
            tables["economy"],
            "tier_b",
        )
        result = frontline.simulate_build(level, build, power)
        row = {
            "level": int(result["level"]),
            "cleared": bool(result["cleared"]),
            "grade": str(result["grade"]),
            "time": round(float(result["clear_time_seconds"]), 3),
            "cap": round(float(result["clear_time_cap_seconds"]), 3),
            "base_hp_pct": round(float(result["base_hp_ratio"]) * 100.0, 2),
            "power": int(power["power"]),
            "bottleneck": str(power["bottleneck"]),
            "weapon": str(build["weapon"]),
        }
        rows.append(row)
        if not row["cleared"] or row["time"] > row["cap"]:
            failures.append(row)
    return rows, failures


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--enforce-graduation",
        action="store_true",
        help="fail if any campaign level is not clearable by the maxed free graduation family",
    )
    args = parser.parse_args()
    targets = load("campaign_pacing_targets")
    fixture = load("campaign_progression_fixture")
    levels = load("levels")
    challenges = load("challenges")
    errors = validate_frozen_contract(targets, fixture, levels)
    errors.extend(validate_challenge_contract(targets, challenges))
    if errors:
        print("Campaign pacing contract failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    rows, failures = graduation_results(levels)
    slowest = sorted(rows, key=lambda row: row["time"] / max(row["cap"], 0.001), reverse=True)[:5]
    print(
        "Campaign pacing contract: frozen tier_b, target distribution 16/43/33/7/0, "
        f"chapter 6 hash {chapter6_hash(levels)[:12]}"
    )
    print("Max-free graduation slowest cap ratios:")
    for row in slowest:
        print(
            f"  L{row['level']:03d} {row['time']:.3f}/{row['cap']:.0f}s "
            f"base={row['base_hp_pct']:.2f}% power={row['power']} "
            f"{row['weapon']} {row['grade']}"
        )
    if failures:
        print(f"Max-free graduation failures: {len(failures)}")
        for row in failures:
            print(f"  {json.dumps(row, ensure_ascii=False, sort_keys=True)}")
        if args.enforce_graduation:
            return 1
        print("Graduation enforcement is staged until the B2 all-level rebuild is complete.")
    else:
        print("Max-free graduation: 99/99 clearable within authored time caps")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
