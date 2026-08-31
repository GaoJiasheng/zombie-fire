#!/usr/bin/env python3
"""Gate the Tier B challenge curve against its ten-seed runtime evidence."""

from __future__ import annotations

import argparse
import hashlib
import json
import statistics
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_EVIDENCE = ROOT / "design/audits/challenge_curve_tier_b_20260831/all99_final_10.json"
DEFAULT_BEFORE = ROOT / "design/audits/challenge_curve_tier_b_20260831/normal_l099_before_10.json"
DEFAULT_AFTER = ROOT / "design/audits/challenge_curve_tier_b_20260831/normal_l099_after_10.json"
DEFAULT_FREE = ROOT / "design/audits/challenge_curve_tier_b_20260831/free_ch9_ch10_representatives_10.json"
EXPECTED_SEEDS = [1103, 2207, 3301, 4409, 5513, 6637, 7741, 8849, 9901, 10903]


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def canonical_runs_sha(payload: dict) -> str:
    encoded = json.dumps(payload["runs"], ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(encoded).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", type=Path, default=DEFAULT_EVIDENCE)
    parser.add_argument("--normal-before", type=Path, default=DEFAULT_BEFORE)
    parser.add_argument("--normal-after", type=Path, default=DEFAULT_AFTER)
    parser.add_argument("--free-evidence", type=Path, default=DEFAULT_FREE)
    parser.add_argument("--output", type=Path, help="optional path for the derived JSON summary")
    args = parser.parse_args()

    challenges = load(ROOT / "data/challenges.json")
    contract = challenges["curve"]["chapter_runtime_contract"]
    evidence = load(args.evidence)
    rows = evidence.get("runs", [])
    errors: list[str] = []
    if evidence.get("profile") != "tier_b" or evidence.get("card_policy") != "v2" or evidence.get("challenge") is not True:
        errors.append("challenge evidence must use tier_b, card policy v2, and challenge=true")
    actual_seeds = sorted({int(row.get("seed", 0)) for row in rows})
    if evidence.get("seeds_per_level") != len(EXPECTED_SEEDS) or actual_seeds != EXPECTED_SEEDS:
        errors.append(f"challenge evidence seeds drifted: count={evidence.get('seeds_per_level')} seeds={actual_seeds}")
    counts = Counter(int(row.get("level", 0)) for row in rows)
    if len(rows) != 990 or set(counts) != set(range(1, 100)) or set(counts.values()) != {10}:
        errors.append(f"challenge evidence must contain 99x10 complete runs: rows={len(rows)} coverage={len(counts)}")

    bands = contract["chapter_win_rate_bands"]
    chapter_rows = []
    for chapter in range(1, 11):
        offsets = contract["representative_offsets"]
        levels = [min((chapter - 1) * 10 + int(offset), 99) for offset in offsets]
        representative = [row for row in rows if int(row["level"]) in levels]
        all_chapter = [row for row in rows if (int(row["level"]) - 1) // 10 + 1 == chapter]
        band_key = "1-6" if chapter <= 6 else ("7-8" if chapter <= 8 else "9-10")
        low, high = (float(value) for value in bands[band_key])
        wins = sum(bool(row["victory"]) for row in representative)
        rate = wins / len(representative) if representative else 0.0
        if not low <= rate <= high:
            errors.append(f"chapter {chapter} representative win rate {rate:.3%} leaves [{low:.0%}, {high:.0%}]")
        chapter_rows.append({
            "chapter": chapter,
            "representative_levels": levels,
            "representative_wins": wins,
            "representative_runs": len(representative),
            "representative_win_rate": rate,
            "contract_band": [low, high],
            "all_level_wins": sum(bool(row["victory"]) for row in all_chapter),
            "all_level_runs": len(all_chapter),
            "all_level_win_rate": sum(bool(row["victory"]) for row in all_chapter) / len(all_chapter),
        })

    finale_contract = challenges["curve"]["finale_anchor"]
    finale = [row for row in rows if int(row["level"]) == 99]
    finale_wins = [row for row in finale if bool(row["victory"])]
    finale_rate = len(finale_wins) / len(finale) if finale else 0.0
    finale_boss_median = statistics.median(float(row["boss_phase_seconds"]) for row in finale_wins) if finale_wins else 0.0
    win_low, win_high = (float(value) for value in finale_contract["win_rate"])
    boss_low, boss_high = (float(value) for value in finale_contract["boss_phase_median_seconds"])
    if not win_low <= finale_rate <= win_high:
        errors.append(f"L099 win rate {finale_rate:.3%} leaves [{win_low:.0%}, {win_high:.0%}]")
    if not boss_low <= finale_boss_median <= boss_high:
        errors.append(f"L099 Boss median {finale_boss_median:.3f}s leaves [{boss_low:.0f}, {boss_high:.0f}]s")

    normal_before = load(args.normal_before)
    normal_after = load(args.normal_after)
    normal_before_sha = canonical_runs_sha(normal_before)
    normal_after_sha = canonical_runs_sha(normal_after)
    if normal_before.get("runs") != normal_after.get("runs"):
        errors.append("normal L099 ten-seed runs changed byte-for-byte after challenge tuning")

    free_rows = load(args.free_evidence).get("runs", [])
    free_summary = []
    for chapter in (9, 10):
        representative = [row for row in free_rows if (int(row["level"]) - 1) // 10 + 1 == chapter]
        wins = sum(bool(row["victory"]) for row in representative)
        rate = wins / len(representative) if representative else 1.0
        if len(representative) != 30 or rate >= 0.6:
            errors.append(f"chapter {chapter} free counterexample must stay below paid reference band: {wins}/{len(representative)}")
        free_summary.append({"chapter": chapter, "wins": wins, "runs": len(representative), "win_rate": rate})

    star_supply = len(counts) * 3
    if star_supply != 297:
        errors.append(f"challenge theoretical star supply must equal 297★, got {star_supply}")
    summary = {
        "status": "pass" if not errors else "fail",
        "evidence": str(args.evidence.relative_to(ROOT)) if args.evidence.is_relative_to(ROOT) else str(args.evidence),
        "evidence_sha256": hashlib.sha256(args.evidence.read_bytes()).hexdigest(),
        "seeds": EXPECTED_SEEDS,
        "chapters": chapter_rows,
        "finale": {
            "level": 99,
            "wins": len(finale_wins),
            "runs": len(finale),
            "win_rate": finale_rate,
            "win_rate_contract": [win_low, win_high],
            "winning_boss_phase_median_seconds": finale_boss_median,
            "boss_phase_median_contract_seconds": [boss_low, boss_high],
        },
        "normal_l099_zero_impact": {
            "runs_equal": normal_before.get("runs") == normal_after.get("runs"),
            "before_runs_sha256": normal_before_sha,
            "after_runs_sha256": normal_after_sha,
        },
        "free_ch9_ch10_counterexample": free_summary,
        "challenge_star_supply_cap": star_supply,
        "errors": errors,
    }
    if args.output is not None:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    if errors:
        print("Challenge runtime contract failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("Challenge runtime contract passed: 10/10 chapter bands, L099 9/10, Boss median "
          f"{finale_boss_median:.3f}s, normal L099 runs identical, stars={star_supply}/297")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
