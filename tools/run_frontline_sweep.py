#!/usr/bin/env python3
"""Run deterministic frontline probes in parallel and merge their JSON output."""

from __future__ import annotations

import argparse
import concurrent.futures
import json
import os
import subprocess
import tempfile
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GODOT = os.environ.get("GODOT_BIN", "/opt/homebrew/bin/godot")
PROBE = "res://tools/frontline_runtime_probe.gd"
DEFAULT_SEEDS = (1103, 2207, 3301)


def csv_ints(value: str) -> list[int]:
    values = sorted({int(token) for token in value.split(",") if token.strip()})
    if not values or any(number <= 0 for number in values):
        raise argparse.ArgumentTypeError("expected comma-separated positive integers")
    return values


def run_one(
    level: int,
    seed: int,
    profile: str,
    card_policy: str,
    accel: float,
    ignore_level_guarantees: bool,
    ignore_offer_category_floor: bool,
    temp_dir: Path,
) -> tuple[dict, float]:
    output = temp_dir / f"level_{level:03d}_seed_{seed}.json"
    home_dir = temp_dir / f"home_level_{level:03d}_seed_{seed}"
    home_dir.mkdir(parents=True, exist_ok=True)
    args = [
        GODOT,
        "--headless",
        "--fixed-fps",
        "60",
        "--path",
        str(ROOT),
        "--script",
        PROBE,
        "--",
        f"--levels={level}",
        f"--seeds={seed}",
        f"--profile={profile}",
        f"--card-policy={card_policy}",
        f"--accel={accel:g}",
        f"--output={output}",
    ]
    if ignore_level_guarantees:
        args.append("--ignore-level-guarantees")
    if ignore_offer_category_floor:
        args.append("--ignore-offer-category-floor")
    started = time.monotonic()
    environment = os.environ.copy()
    environment["HOME"] = str(home_dir)
    environment["XDG_DATA_HOME"] = str(home_dir / "xdg_data")
    completed = subprocess.run(
        args,
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
        env=environment,
    )
    wall_seconds = time.monotonic() - started
    if completed.returncode != 0:
        raise RuntimeError(
            f"frontline probe failed for level {level:03d} seed {seed}:\n"
            f"{completed.stdout[-6000:]}"
        )
    payload = json.loads(output.read_text(encoding="utf-8"))
    runs = payload.get("runs", [])
    if len(runs) != 1:
        raise RuntimeError(
            f"frontline probe returned {len(runs)} runs for level {level:03d} seed {seed}"
        )
    return runs[0], wall_seconds


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--levels", type=csv_ints, required=True)
    parser.add_argument(
        "--seeds", type=csv_ints, default=list(DEFAULT_SEEDS), help="default: 1103,2207,3301"
    )
    parser.add_argument("--profile", choices=("control", "tier_a", "tier_b"), default="tier_b")
    parser.add_argument("--card-policy", choices=("v2", "legacy"), default="v2")
    parser.add_argument("--accel", type=float, default=1.0)
    parser.add_argument("--jobs", type=int, default=10)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--ignore-level-guarantees", action="store_true")
    parser.add_argument("--ignore-offer-category-floor", action="store_true")
    options = parser.parse_args()
    if not 1.0 <= options.accel <= 50.0:
        parser.error("--accel must be between 1 and 50")
    if options.jobs < 1:
        parser.error("--jobs must be positive")

    started = time.monotonic()
    runs: list[dict] = []
    run_wall_seconds: list[float] = []
    with tempfile.TemporaryDirectory(prefix="frontline_sweep_") as temp_name:
        temp_dir = Path(temp_name)
        with concurrent.futures.ThreadPoolExecutor(max_workers=options.jobs) as executor:
            futures = [
                executor.submit(
                    run_one,
                    level,
                    seed,
                    options.profile,
                    options.card_policy,
                    options.accel,
                    options.ignore_level_guarantees,
                    options.ignore_offer_category_floor,
                    temp_dir,
                )
                for level in options.levels
                for seed in options.seeds
            ]
            for future in concurrent.futures.as_completed(futures):
                run, wall_seconds = future.result()
                runs.append(run)
                run_wall_seconds.append(wall_seconds)

    runs.sort(key=lambda row: (int(row.get("level", 0)), int(row.get("seed", 0))))
    elapsed = time.monotonic() - started
    payload = {
        "schema_version": 1,
        "fixture_source": "design/audits/campaign_progression_fixture_builds.json",
        "levels": options.levels,
        "profile": options.profile,
        "card_policy": options.card_policy,
        "ignore_level_guarantees": options.ignore_level_guarantees,
        "ignore_offer_category_floor": options.ignore_offer_category_floor,
        "seeds_per_level": len(options.seeds),
        "simulation_step_seconds": 1.0 / 60.0,
        "wall_acceleration": options.accel,
        "runs": runs,
        "sweep": {
            "jobs": options.jobs,
            "wall_seconds": round(elapsed, 3),
            "max_process_seconds": round(max(run_wall_seconds, default=0.0), 3),
        },
    }
    output = options.output if options.output.is_absolute() else ROOT / options.output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        f"Frontline sweep complete: {len(runs)} runs, {elapsed:.2f}s wall, output={output}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
