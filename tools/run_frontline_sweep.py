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
DEFAULT_ACCELERATION = 60.0


def csv_ints(value: str) -> list[int]:
    values = sorted({int(token) for token in value.split(",") if token.strip()})
    if not values or any(number <= 0 for number in values):
        raise argparse.ArgumentTypeError("expected comma-separated positive integers")
    return values


def batches(values: list[int], size: int) -> list[list[int]]:
    return [values[index : index + size] for index in range(0, len(values), size)]


def run_batch(
    level: int,
    seeds: list[int],
    profile: str,
    card_policy: str,
    accel: float,
    ignore_level_guarantees: bool,
    ignore_offer_category_floor: bool,
    challenge: bool,
    fail_fast: bool,
    process_timeout: float,
    temp_dir: Path,
    project_root: Path,
    fixture: str,
) -> tuple[list[dict], float]:
    seed_label = "_".join(str(seed) for seed in seeds)
    output = temp_dir / f"level_{level:03d}_seeds_{seed_label}.json"
    home_dir = temp_dir / f"home_level_{level:03d}_seeds_{seed_label}"
    home_dir.mkdir(parents=True, exist_ok=True)
    args = [
        GODOT,
        "--headless",
        "--fixed-fps",
        "60",
        "--path",
        str(project_root),
        "--script",
        PROBE,
        "--",
        f"--levels={level}",
        f"--seeds={','.join(str(seed) for seed in seeds)}",
        f"--profile={profile}",
        f"--card-policy={card_policy}",
        f"--accel={accel:g}",
        f"--output={output}",
        f"--fixture={fixture}",
    ]
    if ignore_level_guarantees:
        args.append("--ignore-level-guarantees")
    if ignore_offer_category_floor:
        args.append("--ignore-offer-category-floor")
    if challenge:
        args.append("--challenge")
    if fail_fast:
        args.append("--fail-fast")
    started = time.monotonic()
    environment = os.environ.copy()
    environment["HOME"] = str(home_dir)
    environment["XDG_DATA_HOME"] = str(home_dir / "xdg_data")
    try:
        completed = subprocess.run(
            args,
            cwd=project_root,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
            env=environment,
            timeout=process_timeout,
        )
    except subprocess.TimeoutExpired as error:
        wall_seconds = time.monotonic() - started
        raw_output = error.stdout or ""
        if isinstance(raw_output, bytes):
            raw_output = raw_output.decode("utf-8", errors="replace")
        timeout_runs = [
            {
                "level": level,
                "seed": seed,
                "victory": False,
                "timeout": True,
                "probe_status": "process_timeout",
                "process_timeout_seconds": process_timeout,
                "diagnostic_tail": raw_output[-2000:],
            }
            for seed in seeds
        ]
        return timeout_runs, wall_seconds
    wall_seconds = time.monotonic() - started
    if completed.returncode != 0:
        raise RuntimeError(
            f"frontline probe failed for level {level:03d} seeds {seed_label}:\n"
            f"{completed.stdout[-6000:]}"
        )
    payload = json.loads(output.read_text(encoding="utf-8"))
    runs = payload.get("runs", [])
    if not runs or len(runs) > len(seeds) or (not fail_fast and len(runs) != len(seeds)):
        raise RuntimeError(
            f"frontline probe returned {len(runs)} runs for level {level:03d} "
            f"seeds {seed_label}"
        )
    returned_seeds = [int(run.get("seed", 0)) for run in runs]
    if returned_seeds != seeds[: len(returned_seeds)]:
        raise RuntimeError(
            f"frontline probe returned unexpected seed order {returned_seeds} "
            f"for requested {seeds}"
        )
    return runs, wall_seconds


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--levels", type=csv_ints, required=True)
    parser.add_argument(
        "--seeds", type=csv_ints, default=list(DEFAULT_SEEDS), help="default: 1103,2207,3301"
    )
    parser.add_argument("--profile", choices=("control", "tier_a", "tier_b"), default="tier_b")
    parser.add_argument("--card-policy", choices=("v2", "legacy"), default="v2")
    parser.add_argument("--accel", type=float, default=DEFAULT_ACCELERATION)
    parser.add_argument("--jobs", type=int, default=16)
    parser.add_argument(
        "--batch-size",
        type=int,
        default=1,
        help=(
            "seeds to run per Godot process (default: 1; local benchmark showed "
            "multi-battle batches preserve results but reduce throughput; ignored by --fail-fast)"
        ),
    )
    parser.add_argument(
        "--fail-fast",
        action="store_true",
        help="stop each level at its first losing seed; final evidence must omit this flag",
    )
    parser.add_argument(
        "--project-root",
        type=Path,
        default=ROOT,
        help=argparse.SUPPRESS,
    )
    parser.add_argument(
        "--process-timeout",
        type=float,
        default=240.0,
        help="maximum wall seconds for one Godot probe process (default: 240)",
    )
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--ignore-level-guarantees", action="store_true")
    parser.add_argument("--ignore-offer-category-floor", action="store_true")
    parser.add_argument("--challenge", action="store_true")
    parser.add_argument(
        "--fixture",
        default="res://design/audits/campaign_progression_fixture_builds.json",
        help="res:// fixture build export consumed by the Godot probe",
    )
    options = parser.parse_args()
    if not 1.0 <= options.accel <= 60.0:
        parser.error("--accel must be between 1 and 60")
    if options.jobs < 1:
        parser.error("--jobs must be positive")
    if options.batch_size < 1:
        parser.error("--batch-size must be positive")
    if options.process_timeout <= 0.0:
        parser.error("--process-timeout must be positive")

    started = time.monotonic()
    runs: list[dict] = []
    run_wall_seconds: list[float] = []
    with tempfile.TemporaryDirectory(prefix="frontline_sweep_") as temp_name:
        temp_dir = Path(temp_name)
        with concurrent.futures.ThreadPoolExecutor(max_workers=options.jobs) as executor:
            seed_batches = (
                [list(options.seeds)]
                if options.fail_fast
                else batches(list(options.seeds), options.batch_size)
            )
            futures = [
                executor.submit(
                    run_batch,
                    level,
                    seed_batch,
                    options.profile,
                    options.card_policy,
                    options.accel,
                    options.ignore_level_guarantees,
                    options.ignore_offer_category_floor,
                    options.challenge,
                    options.fail_fast,
                    options.process_timeout,
                    temp_dir,
                    options.project_root.resolve(),
                    options.fixture,
                )
                for level in options.levels
                for seed_batch in seed_batches
            ]
            for future in concurrent.futures.as_completed(futures):
                batch_runs, wall_seconds = future.result()
                runs.extend(batch_runs)
                run_wall_seconds.append(wall_seconds)

    runs.sort(key=lambda row: (int(row.get("level", 0)), int(row.get("seed", 0))))
    elapsed = time.monotonic() - started
    payload = {
        "schema_version": 1,
        "fixture_source": options.fixture,
        "levels": options.levels,
        "profile": options.profile,
        "card_policy": options.card_policy,
        "ignore_level_guarantees": options.ignore_level_guarantees,
        "ignore_offer_category_floor": options.ignore_offer_category_floor,
        "challenge": options.challenge,
        "fail_fast": options.fail_fast,
        "seeds_per_level": len(options.seeds),
        "simulation_step_seconds": 1.0 / 60.0,
        "wall_acceleration": options.accel,
        "runs": runs,
        "sweep": {
            "jobs": options.jobs,
            "batch_size": len(options.seeds) if options.fail_fast else options.batch_size,
            "process_count": len(run_wall_seconds),
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
