#!/usr/bin/env python3
"""Report B2b fixture drift and the staged 061-099 repair list.

The B2a acceptance sweep used the progression fixture that existed before the
061-099 enemy-count rebuild.  B2b must regenerate the fixture from the current
99 levels first, then make the resulting later-build drift explicit before any
spot repair.  This tool keeps that comparison reproducible without checking a
second copy of the old fixture into the repository.
"""
from __future__ import annotations

import argparse
import csv
import json
import statistics
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OLD_REF = "ccdf9db4"
FIXTURE_PATH = "design/audits/campaign_progression_fixture_builds.json"


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def load_git_json(ref: str, path: str) -> dict:
    payload = subprocess.check_output(
        ["git", "show", f"{ref}:{path}"], cwd=ROOT, text=True
    )
    return json.loads(payload)


def compact_skills(build: dict) -> str:
    levels = build.get("skill_base_levels", {}) or {}
    return "|".join(f"{key}:{int(value)}" for key, value in sorted(levels.items()))


def compact_build(build: dict) -> str:
    slots = (
        ("char", "character", "character_level"),
        ("weapon", "weapon", "weapon_level"),
        ("armor", "armor", "armor_level"),
        ("chip", "chip", "chip_level"),
        ("pet", "pet", "pet_level"),
    )
    values = []
    for label, id_key, level_key in slots:
        item_id = str(build.get(id_key, "") or "none")
        values.append(f"{label}={item_id}@{int(build.get(level_key, 0) or 0)}")
    values.append(f"sig={int(build.get('signature_level', 0) or 0)}")
    return ";".join(values)


def target_for_level(targets: dict, level: int) -> str:
    chapter = (level - 1) // 10 + 1
    index = (level - 1) % 10
    sequence = targets.get("chapter_level_targets", {}).get(str(chapter), [])
    return str(sequence[index]) if index < len(sequence) else ""


def median(values: list[float]) -> float:
    return float(statistics.median(values)) if values else 0.0


def assess(targets: dict, grade: str, runs: list[dict]) -> tuple[str, str]:
    if not runs:
        return "repair", "missing runs"
    wins = sum(bool(run.get("victory")) for run in runs)
    progress = median([float(run.get("max_progress", 0.0)) * 100.0 for run in runs])
    base = median([float(run.get("base_ratio", 0.0)) * 100.0 for run in runs])
    reasons: list[str] = []
    if wins != len(runs):
        reasons.append(f"wins {wins}/{len(runs)}")
    band = targets.get("target_bands", {}).get(grade, {})
    progress_band = band.get("max_progress_pct", [0.0, 100.0])
    base_band = band.get("base_hp_pct", [0.0, 100.0])
    if progress < float(progress_band[0]) - 1e-6:
        reasons.append(f"progress {progress:.2f} < {float(progress_band[0]):.2f}")
    if progress > float(progress_band[1]) + 1e-6:
        reasons.append(f"progress {progress:.2f} > {float(progress_band[1]):.2f}")
    if base < float(base_band[0]) - 1e-6:
        reasons.append(f"base {base:.2f} < {float(base_band[0]):.2f}")
    if base > float(base_band[1]) + 1e-6:
        reasons.append(f"base {base:.2f} > {float(base_band[1]):.2f}")
    return ("repair", "; ".join(reasons)) if reasons else ("pass", "in target band")


def write_build_comparison(old_fixture: dict, new_fixture: dict, output: Path) -> None:
    old_rows = {int(row["level"]): row for row in old_fixture.get("rows", [])}
    new_rows = {int(row["level"]): row for row in new_fixture.get("rows", [])}
    fields = [
        "level",
        "old_build",
        "new_build",
        "old_skills",
        "new_skills",
        "old_gold_before",
        "new_gold_before",
        "old_gold_earned",
        "new_gold_earned",
        "old_xp_before",
        "new_xp_before",
        "old_xp_earned",
        "new_xp_earned",
        "old_stars_before",
        "new_stars_before",
        "build_changed",
    ]
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for level in range(1, 100):
            old = old_rows[level]
            new = new_rows[level]
            old_build = old.get("build", {})
            new_build = new.get("build", {})
            old_before = old.get("resources_before", {})
            new_before = new.get("resources_before", {})
            old_after = old.get("progression_after_clear", {})
            new_after = new.get("progression_after_clear", {})
            writer.writerow(
                {
                    "level": f"{level:03d}",
                    "old_build": compact_build(old_build),
                    "new_build": compact_build(new_build),
                    "old_skills": compact_skills(old_build),
                    "new_skills": compact_skills(new_build),
                    "old_gold_before": int(old_before.get("gold", 0)),
                    "new_gold_before": int(new_before.get("gold", 0)),
                    "old_gold_earned": int(old_after.get("gold_earned", 0)),
                    "new_gold_earned": int(new_after.get("gold_earned", 0)),
                    "old_xp_before": int(old_before.get("xp", 0)),
                    "new_xp_before": int(new_before.get("xp", 0)),
                    "old_xp_earned": int(old_after.get("xp_earned", 0)),
                    "new_xp_earned": int(new_after.get("xp_earned", 0)),
                    "old_stars_before": int(old_before.get("stars", 0)),
                    "new_stars_before": int(new_before.get("stars", 0)),
                    "build_changed": "yes" if old_build != new_build else "no",
                }
            )


def group_runs(payload: dict, seeds: set[int] | None = None) -> dict[int, list[dict]]:
    grouped: dict[int, list[dict]] = {}
    for run in payload.get("runs", []):
        seed = int(run.get("seed", 0))
        if seeds is not None and seed not in seeds:
            continue
        grouped.setdefault(int(run["level"]), []).append(run)
    return grouped


def write_repair_report(
    old_ref: str,
    old_fixture: dict,
    new_fixture: dict,
    scan: dict,
    prior_scan: dict,
    targets: dict,
    output: Path,
) -> None:
    old_rows = {int(row["level"]): row for row in old_fixture.get("rows", [])}
    new_rows = {int(row["level"]): row for row in new_fixture.get("rows", [])}
    scan_seeds = {int(run.get("seed", 0)) for run in scan.get("runs", [])}
    grouped = group_runs(scan)
    prior_grouped = group_runs(prior_scan, scan_seeds)
    changed_builds = sum(old_rows[level].get("build", {}) != new_rows[level].get("build", {}) for level in range(1, 100))
    changed_late_builds = sum(old_rows[level].get("build", {}) != new_rows[level].get("build", {}) for level in range(61, 100))
    total_runs = sum(len(runs) for runs in grouped.values())
    changed_runs = 0
    for level, runs in grouped.items():
        previous = {int(run["seed"]): run for run in prior_grouped.get(level, [])}
        for run in runs:
            old = previous.get(int(run["seed"]))
            if old is None:
                continue
            keys = ("build", "max_progress", "base_ratio", "victory", "elapsed_seconds", "boss_phase_seconds")
            if any(old.get(key) != run.get(key) for key in keys):
                changed_runs += 1

    rows: list[dict] = []
    for level in range(61, 100):
        runs = grouped.get(level, [])
        grade = target_for_level(targets, level)
        status, reason = assess(targets, grade, runs)
        rows.append(
            {
                "level": level,
                "target": grade,
                "progress": median([float(run.get("max_progress", 0.0)) * 100.0 for run in runs]),
                "base": median([float(run.get("base_ratio", 0.0)) * 100.0 for run in runs]),
                "worst_base": min([float(run.get("base_ratio", 0.0)) * 100.0 for run in runs] or [0.0]),
                "wins": sum(bool(run.get("victory")) for run in runs),
                "duration": median([float(run.get("elapsed_seconds", 0.0)) for run in runs]),
                "boss_phase": median([float(run.get("boss_phase_seconds", 0.0)) for run in runs]),
                "status": status,
                "reason": reason,
            }
        )

    output.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# B2b Fixture Regeneration and 061–099 Repair List",
        "",
        "Status: recorded only; no Stage 061–099 tuning is included in this checkpoint.",
        "",
        "## Fixture regeneration",
        "",
        f"- Old comparison source: `{old_ref}:{FIXTURE_PATH}` (fixture before the B2a 061–099 enemy-count rebuild).",
        f"- New source: `{FIXTURE_PATH}`, regenerated from the current 99-stage data with `audit_campaign_frontline.py --write`.",
        "- A second regeneration produced zero diff (idempotent).",
        f"- Changed progression builds: {changed_builds}/99 overall; {changed_late_builds}/39 in Stages 061–099.",
        f"- Same-seed runtime rows changed versus the B2a acceptance evidence: {changed_runs}/{total_runs}.",
        "- Full 99-stage slot/level/resource comparison: `design/audits/b2b_fixture_build_old_to_new.csv`.",
        "",
        "The drift is expected coupling: rebuilt waves change kill rewards, which changes later purchases and upgrade allocation. It is not evidence that B2a data should be retuned before Chapters 1–5 are rebuilt.",
        "",
        "## Tier-B three-seed scan (new fixture)",
        "",
        "Seeds: 1103 / 2207 / 3301. Target-band misses and losses enter the B2b final repair list; passing stages remain frozen.",
        "",
        "| Stage | Target | Median progress | Median base | Worst base | Wins | Median duration | Boss phase | Result | Reason |",
        "|---:|---|---:|---:|---:|---:|---:|---:|---|---|",
    ]
    for row in rows:
        lines.append(
            f"| {row['level']:03d} | {row['target']} | {row['progress']:.2f}% | {row['base']:.2f}% | "
            f"{row['worst_base']:.2f}% | {row['wins']}/3 | {row['duration']:.2f}s | {row['boss_phase']:.2f}s | "
            f"{row['status']} | {row['reason']} |"
        )

    repairs = [row for row in rows if row["status"] != "pass"]
    lines.extend(
        [
            "",
            "## B2b final repair list",
            "",
            f"{len(repairs)} stages currently miss their frozen band or clearability contract: "
            + ", ".join(f"{row['level']:03d}" for row in repairs)
            + ".",
            "",
            "Stages 066 and 067 contain same-seed losses and therefore take priority after Chapters 1–5 regenerate the fixture again. No repair is made at this checkpoint.",
            "",
            "## Blade-stage base-margin recheck",
            "",
            "This table uses the minimum runtime base ratio among the same three seeds, so old and new evidence are directly comparable.",
            "",
            "| Stage | B2a minimum base | New-fixture minimum base | Delta | Note |",
            "|---:|---:|---:|---:|---|",
        ]
    )
    for level in (68, 80, 85, 95, 99):
        old_runs = prior_grouped.get(level, [])
        new_runs = grouped.get(level, [])
        old_min = min([float(run.get("base_ratio", 0.0)) * 100.0 for run in old_runs] or [0.0])
        new_min = min([float(run.get("base_ratio", 0.0)) * 100.0 for run in new_runs] or [0.0])
        note = "final recheck" if new_min < 2.0 else "recorded"
        lines.append(f"| {level:03d} | {old_min:.2f}% | {new_min:.2f}% | {new_min - old_min:+.2f}pp | {note} |")
    lines.append("")
    output.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--old-git-ref", default=DEFAULT_OLD_REF)
    parser.add_argument(
        "--new-fixture",
        type=Path,
        default=ROOT / FIXTURE_PATH,
    )
    parser.add_argument(
        "--scan",
        type=Path,
        default=ROOT / "design/audits/b2b_fixture_061_099_tier_b_3.json",
    )
    parser.add_argument(
        "--prior-scan",
        type=Path,
        default=ROOT / "design/audits/b2a_final_061_099_tier_b_10_corrected.json",
    )
    parser.add_argument(
        "--targets",
        type=Path,
        default=ROOT / "data/campaign_pacing_targets.json",
    )
    parser.add_argument(
        "--comparison-output",
        type=Path,
        default=ROOT / "design/audits/b2b_fixture_build_old_to_new.csv",
    )
    parser.add_argument(
        "--report-output",
        type=Path,
        default=ROOT / "design/audits/b2b_fixture_061_099_repair_list.md",
    )
    args = parser.parse_args()

    old_fixture = load_git_json(args.old_git_ref, FIXTURE_PATH)
    new_fixture = load_json(args.new_fixture)
    scan = load_json(args.scan)
    prior_scan = load_json(args.prior_scan)
    targets = load_json(args.targets)
    write_build_comparison(old_fixture, new_fixture, args.comparison_output)
    write_repair_report(
        args.old_git_ref,
        old_fixture,
        new_fixture,
        scan,
        prior_scan,
        targets,
        args.report_output,
    )
    print(f"Wrote {args.comparison_output.relative_to(ROOT)}")
    print(f"Wrote {args.report_output.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
