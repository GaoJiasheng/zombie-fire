#!/usr/bin/env python3
"""T1: solve ten-seed runtime clear lines along a scaled reference-build ray.

Only audit fixtures/results are written. Bounds that do not bracket a 9/10
transition are explicitly censored/errors, never invented P* measurements.
"""
from __future__ import annotations

import argparse
import copy
import datetime as dt
import hashlib
import json
import math
import os
from pathlib import Path
import statistics
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import power_ruler_model as ruler
import run_frontline_sweep as sweep

SEEDS = [1103, 2207, 3301, 4409, 5513, 6637, 7741, 8849, 9901, 10903]
MAX_BISECTIONS = 7
R_TOLERANCE = 0.02
LEVEL_FIELDS = ("character_level", "weapon_level", "armor_level", "chip_level", "pet_level")
DATE = dt.datetime.now(dt.timezone(dt.timedelta(hours=8))).strftime("%Y_%m_%d")
FIXTURE = ROOT / "design/audits/campaign_progression_fixture_builds.json"
WALL_LEVELS = {15, 17, 18, 19, 20, 40, 44, 76}


def scaled_build(build: dict, scale: float, tables: dict | None = None) -> dict:
    result = copy.deepcopy(build)
    for key in LEVEL_FIELDS:
        result[key] = max(1, round(float(build.get(key, 1)) * scale))
    result["signature_level"] = max(0, round(float(build.get("signature_level", 0)) * scale))
    result["skill_base_levels"] = {
        key: max(0, round(float(value) * scale))
        for key, value in build.get("skill_base_levels", {}).items()
    }
    if tables is not None:
        # 2026-10 direction A: extension follows the same build ray, but never
        # creates unattainable item/skill ranks. All caps come from live data.
        for field, table, identity in (
                ("character_level", "characters", "character"),
                ("weapon_level", "weapons", "weapon"),
                ("armor_level", "armors", "armor"),
                ("chip_level", "chips", "chip"),
                ("pet_level", "pets", "pet")):
            if not build.get(identity):
                result[field] = 1  # an empty slot stays empty; no item is created
                continue
            item = tables[table].get(build[identity])
            if item is None:
                raise ValueError(f"unknown {identity}: {build.get(identity)}")
            result[field] = min(result[field], int(item["max_level"]))
        result["signature_level"] = min(result["signature_level"], len(tables["economy"]["sig_skill_xp_costs"]))
        for identity in result["skill_base_levels"]:
            result["skill_base_levels"][identity] = min(
                result["skill_base_levels"][identity], ruler.skill_max_level(tables["skills"][identity]))
    return result


def load_tables() -> dict:
    return {name: json.loads((ROOT / "data" / f"{name}.json").read_text()) for name in
            ("levels", "characters", "weapons", "armors", "chips", "pets", "skills", "bosses", "zombies", "economy")}


def power(level: dict, build: dict, tables: dict) -> dict:
    return ruler.power_for_build(level, level["clear_requirement"]["power_contract"], build,
                                 *(tables[key] for key in ("characters", "weapons", "armors", "chips", "pets", "skills", "bosses", "economy")))


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def input_hashes() -> dict:
    # The five-segment combat fingerprint deliberately excludes some content;
    # full frozen-data/runtime hashes additionally protect interrupted resumes.
    paths = sorted((ROOT / "data").glob("*.json"))
    paths += sorted((ROOT / "gameplay").rglob("*.gd")) + sorted((ROOT / "core").rglob("*.gd"))
    paths += [ROOT / "tools/frontline_runtime_probe.gd", ROOT / "tools/power_ruler_model.py", ROOT / "tools/power_scale_v6.py"]
    return {str(path.relative_to(ROOT)): sha(path) for path in paths}


def atomic_write(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(path.suffix + ".pending")
    temp.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    os.replace(temp, path)


def validate_runs(payload: dict, number: int, expected_build: dict) -> list[dict]:
    runs = payload.get("runs", [])
    if len(runs) != 10 or sorted(int(row.get("seed", -1)) for row in runs) != SEEDS:
        raise RuntimeError("expected exactly ten distinct fixed-seed results")
    if payload.get("profile") != "tier_b" or payload.get("card_policy") != "v2" or payload.get("simulation_step_seconds") != 1 / 60:
        raise RuntimeError("runtime profile/policy/fixed-step provenance mismatch")
    for row in runs:
        if int(row.get("level", 0)) != number or row.get("build") != expected_build:
            raise RuntimeError("runtime returned a different level/build")
        if row.get("probe_status") or row.get("error") or row.get("timeout"):
            raise RuntimeError(f"incomplete probe seed {row.get('seed')}: timeout/error is not a combat loss")
        if not isinstance(row.get("victory"), bool):
            raise RuntimeError("missing boolean victory")
        for key in ("base_ratio", "elapsed_seconds"):
            if key not in row or not isinstance(row[key], (int, float)) or not math.isfinite(row[key]):
                raise RuntimeError(f"missing {key}")
        if not 0 <= row["base_ratio"] <= 1 or row["elapsed_seconds"] < 0:
            raise RuntimeError("invalid runtime base ratio/elapsed time")
    return runs


def derive_bracket(steps: list[dict]) -> tuple[dict | None, dict | None]:
    failed = [step for step in steps if step["wins"] < 9]
    passed = [step for step in steps if step["wins"] >= 9]
    lo = max(failed, key=lambda step: step["scale"], default=None)
    hi = min(passed, key=lambda step: step["scale"], default=None)
    if lo and hi and lo["scale"] >= hi["scale"]:
        raise RuntimeError("observed non-monotonic pass/fail samples; binary search is not justified")
    if lo and hi and lo["R"] > hi["R"]:
        raise RuntimeError("display power is not monotone across the runtime bracket")
    return lo, hi


def solve_level(row: dict, state: dict, payload: dict, options, tables: dict, checkpoint: Path) -> None:
    number = int(row["level"])
    level = next(item for item in tables["levels"] if sweep_level_number(item) == number)
    recommended = int(level["clear_requirement"]["power_contract"]["recommended_power"])
    state.setdefault("steps", [])
    state.update(level=number, recommended=recommended, status="running")
    wall_extension = getattr(options, "wall_extension", False)
    lower_scale, upper_scale = (1.0, 1.8) if wall_extension else (0.3, 1.0)
    if wall_extension:
        state["extension_method"] = {"scale_bounds": [1.0, 1.8], "max_bisections": MAX_BISECTIONS,
                                     "R_tolerance": R_TOLERANCE, "level_caps": "data max_level / skill levels / signature XP ranks"}

    def evaluate(scale: float) -> dict:
        build = scaled_build(row["build"], scale, tables if wall_extension else None)
        model = power(level, build, tables)
        # Rounded plateaus reuse identical ten-seed evidence rather than rerun it.
        for previous in state["steps"]:
            if previous["build"] == build:
                return {**previous, "scale": scale, "reused_from_scale": previous["scale"]}
        step_no = len(state["steps"])
        fixture = ROOT / f"design/audits/_tmp_clear_line_{number:03d}_{step_no}.json"
        evidence_dir = options.evidence_dir / f"level_{number:03d}" / f"step_{step_no}"
        evidence_dir.mkdir(parents=True, exist_ok=True)
        output = evidence_dir / "sweep.json"
        log = evidence_dir / "sweep.log"
        if fixture.exists():
            # Only recover our own exact interrupted fixture, never overwrite a
            # foreign audit with a coincidentally matching filename.
            existing = json.loads(fixture.read_text())
            if existing.get("solver_id") != "linear_power_p1_t1":
                raise RuntimeError(f"unowned temporary fixture exists: {fixture}")
        atomic_write(fixture, {"schema_version": 1, "solver_id": "linear_power_p1_t1",
                               "rows": [{"level": number, "level_id": row["level_id"], "build": build, "card_seeds": SEEDS}]})
        command = [sys.executable, str(ROOT / "tools/run_frontline_sweep.py"), "--levels", str(number),
                   "--seeds", ",".join(map(str, SEEDS)), "--profile", "tier_b", "--card-policy", "v2",
                   "--accel", "60", "--jobs", str(options.jobs), "--process-timeout", "360",
                   "--fixture", "res://" + str(fixture.relative_to(ROOT)), "--output", str(output),
                   "--log-dir", str(evidence_dir / "godot_logs")]
        start = time.monotonic()
        try:
            with log.open("w") as handle:
                completed = subprocess.run(command, cwd=ROOT, stdout=handle, stderr=subprocess.STDOUT, check=False)
            if completed.returncode:
                raise RuntimeError(f"sweep exit {completed.returncode}; log={log}")
            archived = json.loads(output.read_text())
            if archived["combat_input_fingerprint"] != payload["combat_input_fingerprint"]:
                raise RuntimeError("combat inputs changed while probing")
            runs = validate_runs(archived, number, build)
            logs = list((evidence_dir / "godot_logs").glob("*.log"))
            if len(logs) != 10 or any("SCRIPT ERROR" in path.read_text() for path in logs):
                raise RuntimeError("ten raw Godot logs required, with zero SCRIPT ERROR")
            result = {"scale": scale, "power": model["power"], "R": model["power"] / recommended,
                      "wins": sum(item["victory"] for item in runs),
                      "base_median": statistics.median(item["base_ratio"] for item in runs),
                      "elapsed_median": statistics.median(item["elapsed_seconds"] for item in runs),
                      "wall_seconds": time.monotonic() - start, "build": build,
                      "evidence": str(output), "log": str(log), "script_error_count": 0}
            print(f"L{number:03d} scale={scale:.6f} R={result['R']:.4f} wins={result['wins']}/10 wall={result['wall_seconds']:.1f}s", flush=True)
            return result
        finally:
            fixture.unlink(missing_ok=True)

    def sample(scale: float):
        result = evaluate(scale)
        if not any(abs(step["scale"] - scale) < 1e-12 for step in state["steps"]):
            state["steps"].append(result)
            atomic_write(checkpoint, payload)
        return result

    upper = next((step for step in state["steps"] if step["scale"] == upper_scale), None) or sample(upper_scale)
    if upper["wins"] < 9:
        state.update(status="upper_bound_fails", p_star=None, r_star=None, build_star=None,
                     bracket=[upper["R"], None], reason=f"capped reference at scale {upper_scale} does not clear >=9/10; no extrapolation")
        return
    lower = next((step for step in state["steps"] if step["scale"] == lower_scale), None) or sample(lower_scale)
    if lower["wins"] >= 9:
        state.update(status="lower_bound_passes", p_star=None, r_star=None, build_star=None,
                     bracket=[None, lower["R"]], reason="transition lies below search interval; passing bound is not P*")
        return
    lo, hi = derive_bracket(state["steps"])
    bisections = sum(lower_scale < step["scale"] < upper_scale for step in state["steps"])
    while hi["R"] - lo["R"] > R_TOLERANCE and bisections < MAX_BISECTIONS:
        sample((lo["scale"] + hi["scale"]) / 2)
        bisections += 1
        lo, hi = derive_bracket(state["steps"])
    state.update(status="complete", p_star=hi["power"], r_star=hi["R"], build_star=hi["build"],
                 bracket=[lo["R"], hi["R"]], scale_bracket=[lo["scale"], hi["scale"]],
                 stop_reason="R_width" if hi["R"] - lo["R"] <= R_TOLERANCE else "seven_bisections",
                 precision_met=hi["R"] - lo["R"] <= R_TOLERANCE)
    state.pop("reason", None)  # remove the obsolete stage-one upper-censor reason


def sweep_level_number(level: dict) -> int:
    return int(str(level["id"]).rsplit("_", 1)[1])


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--levels", type=sweep.csv_ints, default=list(range(1, 100)))
    parser.add_argument("--resume", action="store_true", help="reuse completed levels and valid completed steps; frozen input hashes must match")
    parser.add_argument("--wall-extension", action="store_true", help="Owner-approved eight wall levels only: resume with capped scale bounds [1.0, 1.8]")
    parser.add_argument("--jobs", type=int, default=6, help="1..6 concurrent Godot probes by default; no per-level parallelism")
    parser.add_argument("--allow-concurrency-trial", action="store_true",
                        help="explicit Owner-approved trial only: permit --jobs 7 or 8; default cap remains 6")
    parser.add_argument("--output", type=Path, default=ROOT / f"design/audits/runtime_clear_lines_{DATE}.json")
    parser.add_argument("--evidence-dir", type=Path, default=Path(f"/tmp/zf_linear_t1_{DATE}"))
    options = parser.parse_args()
    job_limit = 8 if options.allow_concurrency_trial else 6
    if not 1 <= options.jobs <= job_limit or any(not 1 <= number <= 99 for number in options.levels):
        parser.error(f"--jobs must be 1..{job_limit}; --levels must be 1..99")
    if options.wall_extension and (not options.resume or not set(options.levels) <= WALL_LEVELS or options.jobs > 6):
        parser.error("--wall-extension requires --resume, only 015/017/018/019/020/040/044/076 and --jobs <=6")
    options.output = options.output.resolve()
    options.evidence_dir = options.evidence_dir.resolve()
    if not options.output.is_relative_to(ROOT / "design/audits"):
        parser.error("T1 output must be inside this worktree's design/audits")
    lock = options.output.with_suffix(".lock")
    # advisory lock survives no process crash and prevents concurrent checkpoint writers
    import fcntl
    options.output.parent.mkdir(parents=True, exist_ok=True)
    with lock.open("a+") as handle:
        try:
            fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            parser.error("another solver holds this output lock")
        tables = load_tables()
        provenance = {"combat_input_fingerprint": sweep.combat_input_fingerprint(ROOT), "fixture_sha256": sha(FIXTURE),
                      "frozen_input_sha256": input_hashes(), "seeds": SEEDS}
        if options.resume and options.output.exists():
            payload = json.loads(options.output.read_text())
            for key, value in provenance.items():
                if payload.get(key) != value:
                    parser.error(f"resume refused: {key} changed")
        else:
            if options.output.exists():
                parser.error("output already exists; use --resume or a fresh output")
            payload = {"schema_version": 1, **provenance,
                       "git_head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
                       "godot_version": subprocess.check_output([sweep.GODOT, "--version"], text=True).strip(),
                       "method": {"scale_bounds": [0.3, 1.0], "max_bisections": 7, "R_tolerance": 0.02,
                                  "rounding": "Python round, item minimum 1 / signature and permanent skill minimum 0",
                                  "scope": "minimum observed passing build along the reference scaling ray, not all possible loadouts",
                                  "profile": "tier_b", "card_policy": "v2", "simulation_step_seconds": 1 / 60},
                       "rows": [], "errors": []}
        payload["requested_levels"] = sorted(set(payload.get("requested_levels", [])) | set(options.levels))
        fixtures = {int(row["level"]): row for row in json.loads(FIXTURE.read_text())["rows"]}
        by_level = {row["level"]: row for row in payload["rows"]}
        for number in options.levels:
            state = by_level.get(number)
            extend_wall = (options.wall_extension and state and state.get("status") == "upper_bound_fails"
                           and state.get("extension_method", {}).get("scale_bounds") != [1.0, 1.8])
            if state and state.get("status") in {"complete", "lower_bound_passes", "upper_bound_fails"} and not extend_wall:
                if options.wall_extension and state["status"] == "complete" and "reason" in state:
                    # Metadata-only migration for resumed extension checkpoints;
                    # no completed sample is rerun or rewritten.
                    state.pop("reason")
                    atomic_write(options.output, payload)
                print(f"L{number:03d} resume skip: {state['status']}", flush=True)
                continue
            if state is None:
                state = {"level": number, "steps": []}
                payload["rows"].append(state)
                by_level[number] = state
            payload["errors"] = [error for error in payload["errors"] if error["level"] != number]
            try:
                solve_level(fixtures[number], state, payload, options, tables, options.output)
            except Exception as error:
                state.update(status="error", p_star=None, r_star=None, build_star=None)
                payload["errors"].append({"level": number, "message": str(error)})
                print(f"L{number:03d} ERROR: {error}", flush=True)
            payload["rows"].sort(key=lambda row: row["level"])
            payload["updated_at"] = dt.datetime.now(dt.timezone.utc).isoformat()
            atomic_write(options.output, payload)
        if input_hashes() != payload["frozen_input_sha256"]:
            payload["errors"].append({"level": 0, "message": "frozen inputs changed during run"})
            atomic_write(options.output, payload)
        incomplete = [row["level"] for row in payload["rows"] if row["level"] in options.levels and row.get("status") != "complete"]
        print(f"T1 finished requested={len(options.levels)}, unresolved={incomplete}; output={options.output}", flush=True)
        return 1 if incomplete or payload["errors"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
