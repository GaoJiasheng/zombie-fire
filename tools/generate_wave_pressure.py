#!/usr/bin/env python3
"""Generate design/35's adaptive late-wave count pressure.

The authored pre-bump counts live in a tool fixture so this generator remains
idempotent: every run restores the frozen baseline, solves the largest allowed
scale, and writes the same integer counts.  Runtime tuning values are owned by
``data/economy.json.wave_pressure``; this tool does not duplicate them.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import math
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / "tools"
sys.path.insert(0, str(TOOLS))

import simulate_balance as sim  # noqa: E402

LEVELS_PATH = ROOT / "data" / "levels.json"
FIXTURE_PATH = TOOLS / "wave_pressure_baseline.json"

# Owner-approved design/35 acceptance contract.  These are expected outcomes,
# not a second copy of any runtime coefficient.
EXPECTED_STARS = {1: 0, 2: 86, 3: 13}
EXPECTED_FULL_COUNT = 77
EXPECTED_PARTIAL = {
    "level_013": 11,
    "level_018": 10,
    "level_026": 3,
    "level_028": 18,
    "level_049": 15,
    "level_061": 15,
    "level_099": 18,
}
EXPECTED_UNCHANGED = {
    "level_033",
    "level_036",
    "level_063",
    "level_067",
    "level_091",
}


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def canonical_hash(value) -> str:
    payload = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def predicted_star(leak_pct: float, three_cap: float, two_cap: float) -> int:
    if leak_pct > two_cap:
        return 1
    if leak_pct > three_cap:
        return 2
    return 3


def leak_pct(level: dict, zombies: dict, bosses: dict, economy: dict) -> float:
    boss_level = sim.is_boss_level(level)
    leak = sim.leak_damage(level, zombies, bosses, economy, boss_level)
    cushion = sim.boss_base_hp_cushion(economy, sim.level_number(level)) if boss_level else 1.0
    base_hp = float(level.get("base_hp_ref", 100.0)) * sim.ARMOR_HP_MULT * cushion
    return min(100.0, leak / max(base_hp, 1.0) * 100.0)


def config(economy: dict) -> dict:
    rule = economy.get("wave_pressure", {})
    required = (
        "start_level",
        "target_count_increase",
        "scale_step",
        "star_boundary_margin_pct",
        "boss_target_waves",
        "non_boss_target_waves",
    )
    missing = [key for key in required if key not in rule]
    if missing:
        raise ValueError(f"economy.wave_pressure missing: {', '.join(missing)}")
    return rule


def target_wave_numbers(level: dict, rule: dict) -> set[int]:
    key = "boss_target_waves" if sim.is_boss_level(level) else "non_boss_target_waves"
    return {int(value) for value in rule[key]}


def target_rows(level: dict, rule: dict) -> dict[str, list[dict]]:
    wanted = target_wave_numbers(level, rule)
    return {
        str(sim.wave_number(wave)): [
            {"type": str(spawn.get("type", "")), "count": int(spawn.get("count", 0))}
            for spawn in wave.get("spawns", [])
        ]
        for wave in level.get("waves", [])
        if sim.wave_number(wave) in wanted
    }


def restore_target_rows(level: dict, fixture_row: dict, rule: dict) -> None:
    frozen = fixture_row.get("target_rows", {})
    wanted = target_wave_numbers(level, rule)
    for wave in level.get("waves", []):
        wave_no = sim.wave_number(wave)
        if wave_no not in wanted:
            continue
        key = str(wave_no)
        expected = frozen.get(key)
        spawns = wave.get("spawns", [])
        if not isinstance(expected, list) or len(expected) != len(spawns):
            raise ValueError(f"{level['id']} wave {wave_no}: baseline spawn shape changed")
        for spawn, baseline in zip(spawns, expected):
            if str(spawn.get("type", "")) != str(baseline.get("type", "")):
                raise ValueError(f"{level['id']} wave {wave_no}: baseline spawn type changed")
            spawn["count"] = int(baseline["count"])


def apply_scale(level: dict, fixture_row: dict, rule: dict, scale: float) -> None:
    restore_target_rows(level, fixture_row, rule)
    wanted = target_wave_numbers(level, rule)
    for wave in level.get("waves", []):
        if sim.wave_number(wave) not in wanted:
            continue
        for spawn in wave.get("spawns", []):
            baseline = int(spawn.get("count", 0))
            spawn["count"] = int(round(baseline * (1.0 + scale)))


def capture_fixture(levels: list[dict], zombies: dict, bosses: dict, economy: dict, rule: dict) -> dict:
    start_level = int(rule["start_level"])
    three_cap, two_cap = sim.star_leak_caps(economy)
    rows = {}
    for level in levels:
        number = sim.level_number(level)
        base_leak = leak_pct(level, zombies, bosses, economy)
        row = {
            "baseline_star": predicted_star(base_leak, three_cap, two_cap),
            "baseline_leak_pct": round(base_leak, 8),
        }
        if number >= start_level:
            row["target_rows"] = target_rows(level, rule)
        rows[level["id"]] = row
    return {
        "schema_version": 1,
        "first_ten_sha256": canonical_hash(levels[:start_level - 1]),
        "levels": rows,
    }


def solve_level(
    level: dict,
    fixture_row: dict,
    rule: dict,
    zombies: dict,
    bosses: dict,
    economy: dict,
) -> tuple[dict, float, float, int]:
    baseline = copy.deepcopy(level)
    restore_target_rows(baseline, fixture_row, rule)
    three_cap, two_cap = sim.star_leak_caps(economy)
    baseline_star = int(fixture_row["baseline_star"])
    margin = float(rule["star_boundary_margin_pct"])
    worsening_boundary = {3: three_cap, 2: two_cap, 1: 100.0}[baseline_star]
    allowed_leak = worsening_boundary - margin
    max_scale = float(rule["target_count_increase"])
    step = float(rule["scale_step"])
    step_count = int(math.floor(max_scale / step + 1e-9))

    best = copy.deepcopy(baseline)
    best_scale = 0.0
    for index in range(step_count + 1):
        scale = min(max_scale, index * step)
        candidate = copy.deepcopy(baseline)
        apply_scale(candidate, fixture_row, rule, scale)
        if leak_pct(candidate, zombies, bosses, economy) <= allowed_leak + 1e-9:
            best = candidate
            best_scale = scale
    final_leak = leak_pct(best, zombies, bosses, economy)
    final_star = predicted_star(final_leak, three_cap, two_cap)
    return best, best_scale, final_leak, final_star


def target_counts_equal(left: dict, right: dict, rule: dict) -> bool:
    return target_rows(left, rule) == target_rows(right, rule)


def build_expected(
    levels: list[dict],
    fixture: dict,
    rule: dict,
    zombies: dict,
    bosses: dict,
    economy: dict,
) -> tuple[list[dict], list[dict]]:
    start_level = int(rule["start_level"])
    generated = copy.deepcopy(levels)
    report = []
    for index, level in enumerate(generated):
        if sim.level_number(level) < start_level:
            continue
        fixture_row = fixture["levels"].get(level["id"], {})
        solved, scale, final_leak, final_star = solve_level(
            level, fixture_row, rule, zombies, bosses, economy)
        baseline = copy.deepcopy(level)
        restore_target_rows(baseline, fixture_row, rule)
        full = copy.deepcopy(baseline)
        apply_scale(full, fixture_row, rule, float(rule["target_count_increase"]))
        status = "full" if target_counts_equal(solved, full, rule) else (
            "unchanged" if target_counts_equal(solved, baseline, rule) else "partial"
        )
        generated[index] = solved
        report.append({
            "id": level["id"],
            "status": status,
            "scale": scale,
            "display_pct": int(round(scale * 100.0)),
            "leak_pct": final_leak,
            "star": final_star,
        })
    return generated, report


def validate(
    current: list[dict],
    generated: list[dict],
    report: list[dict],
    fixture: dict,
    rule: dict,
) -> list[str]:
    errors: list[str] = []
    start_level = int(rule["start_level"])
    if canonical_hash(current[:start_level - 1]) != fixture.get("first_ten_sha256"):
        errors.append(f"levels 001-{start_level - 1:03d} changed from the frozen pre-bump baseline")

    current_by_id = {level["id"]: level for level in current}
    for expected in generated[start_level - 1:]:
        actual = current_by_id.get(expected["id"], {})
        if not target_counts_equal(actual, expected, rule):
            errors.append(f"{expected['id']}: target-wave counts differ from generated output")

    stars = Counter(int(row["star"]) for row in report)
    for level in current[:start_level - 1]:
        baseline = fixture["levels"][level["id"]]
        stars[int(baseline["baseline_star"])] += 1
    star_distribution = {rating: int(stars.get(rating, 0)) for rating in (1, 2, 3)}
    if star_distribution != EXPECTED_STARS:
        errors.append(f"star distribution {star_distribution} != {EXPECTED_STARS}")
    for row in report:
        baseline_star = int(fixture["levels"][row["id"]]["baseline_star"])
        if int(row["star"]) < baseline_star:
            errors.append(f"{row['id']}: star regression {baseline_star} -> {row['star']}")

    full = [row["id"] for row in report if row["status"] == "full"]
    partial = {row["id"]: row["display_pct"] for row in report if row["status"] == "partial"}
    unchanged = {row["id"] for row in report if row["status"] == "unchanged"}
    if len(full) != EXPECTED_FULL_COUNT:
        errors.append(f"full-bump levels {len(full)} != {EXPECTED_FULL_COUNT}")
    if partial != EXPECTED_PARTIAL:
        errors.append(f"partial-bump levels {partial} != {EXPECTED_PARTIAL}")
    if unchanged != EXPECTED_UNCHANGED:
        errors.append(f"unchanged levels {sorted(unchanged)} != {sorted(EXPECTED_UNCHANGED)}")
    return errors


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate design/35 wave pressure counts")
    parser.add_argument("--check", action="store_true", help="validate generated counts without writing")
    parser.add_argument(
        "--capture-baseline",
        action="store_true",
        help="capture the pre-bump authored count fixture; refuses to overwrite",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    levels = load_json(LEVELS_PATH)
    economy = load_json(ROOT / "data" / "economy.json")
    zombies = load_json(ROOT / "data" / "zombies.json")
    bosses = load_json(ROOT / "data" / "bosses.json")
    rule = config(economy)

    if args.capture_baseline:
        if FIXTURE_PATH.exists():
            print(f"Refusing to overwrite existing baseline: {FIXTURE_PATH}", file=sys.stderr)
            return 1
        fixture = capture_fixture(levels, zombies, bosses, economy, rule)
        FIXTURE_PATH.write_text(json.dumps(fixture, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"Captured wave-pressure baseline for {len(levels)} levels")
        return 0

    if not FIXTURE_PATH.exists():
        print("Missing wave-pressure baseline; capture it before applying the bump", file=sys.stderr)
        return 1
    fixture = load_json(FIXTURE_PATH)
    generated, report = build_expected(levels, fixture, rule, zombies, bosses, economy)

    if args.check:
        errors = validate(levels, generated, report, fixture, rule)
        if errors:
            print("Wave-pressure check failed:")
            for error in errors:
                print(f"- {error}")
            return 1
        counts = Counter(row["status"] for row in report)
        partial = ", ".join(
            f"{row['id']}:+{row['display_pct']}%" for row in report if row["status"] == "partial"
        )
        print(
            "Wave-pressure check OK: "
            f"full={counts['full']} partial={counts['partial']} unchanged={counts['unchanged']}"
        )
        print(f"partial: {partial}")
        print("stars: 13x3-star / 86x2-star / 0x1-star; per-level regressions=0")
        return 0

    LEVELS_PATH.write_text(json.dumps(generated, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")
    counts = Counter(row["status"] for row in report)
    print(
        f"Wrote adaptive wave counts: full={counts['full']} "
        f"partial={counts['partial']} unchanged={counts['unchanged']}"
    )
    for row in report:
        print(
            f"{row['id']} {row['status']:<9} +{row['display_pct']:>2}% "
            f"leak={row['leak_pct']:.4f}% star={row['star']}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
