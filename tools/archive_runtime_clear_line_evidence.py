#!/usr/bin/env python3
"""Verify stage-2A resumed T1 and publish a new, never-overwritten walls archive.

Writes audit summaries/raw manifests only; no product/fixture data edits.
"""
from __future__ import annotations
import argparse
import collections
import hashlib
import json
import os
from pathlib import Path
import shutil
import statistics
import subprocess
import tarfile
import tempfile

import solve_runtime_clear_lines as solver

ROOT = solver.ROOT
BASELINE = "f055c7b4073aa5e45a916f3f4c49929d3fb2877a"
OLD_ARCHIVE = Path("/Users/gavin/Desktop/zombiefire_evidence/runtime_clear_lines_2026_10_03.tar.gz")
OLD_ARCHIVE_SHA = "fb6db5387887673ee6f33a32d3aaf0201b1eea224b1304a4ccb71cc0c1da6722"


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def verify(payload: dict, baseline: dict, evidence_root: Path) -> dict:
    issues, exact_nine, censored, wide, wall_rows = [], [], [], [], []
    rows = payload["rows"]
    original = {row["level"]: row for row in baseline["rows"]}
    if sorted(row["level"] for row in rows) != list(range(1, 100)):
        issues.append("missing/duplicate levels")
    if payload["frozen_input_sha256"] != solver.input_hashes() or payload["fixture_sha256"] != solver.sha(solver.FIXTURE):
        issues.append("frozen data/runtime or fixture drift")
    tables = solver.load_tables()
    prior_files_checked = 0
    if digest(OLD_ARCHIVE) != OLD_ARCHIVE_SHA:
        issues.append("stage-one Desktop archive changed")
    else:
        with tarfile.open(OLD_ARCHIVE, "r:gz") as tar:
            manifest_entry = tar.getmember(evidence_root.name + "/evidence_manifest.json")
            prior_manifest = json.load(tar.extractfile(manifest_entry))
        for relative, expected in prior_manifest.items():
            path = evidence_root / relative
            if not path.resolve().is_relative_to(evidence_root.resolve()) or not path.is_file() or path.stat().st_size != expected["bytes"] or digest(path) != expected["sha256"]:
                issues.append("prior evidence changed/missing: " + relative)
            prior_files_checked += 1
    fixtures = {row["level"]: row["build"] for row in json.loads(solver.FIXTURE.read_text())["rows"]}
    paths, unchanged, reused_original_paths = set(), [], set()
    for row in rows:
        n = row["level"]
        if n not in solver.WALL_LEVELS:
            if row != original[n]:
                issues.append(f"non-wall row L{n:03d} changed")
            else:
                unchanged.append(n)
        else:
            old_steps = original[n]["steps"]
            if row["steps"][:len(old_steps)] != old_steps:
                issues.append(f"L{n:03d}: original samples changed/rerun")
            reused_original_paths.update(s["evidence"] for s in old_steps)
            if row.get("extension_method", {}).get("scale_bounds") != [1.0, 1.8]:
                issues.append(f"L{n:03d}: extension not performed")
            if not any(s["scale"] == 1.8 for s in row["steps"]):
                issues.append(f"L{n:03d}: missing authorized upper bound")
            for step in row["steps"]:
                if step["scale"] >= 1 and step["build"] != solver.scaled_build(fixtures[n], step["scale"], tables):
                    issues.append(f"L{n:03d}: capped scaling mismatch")
        bracket = row.get("bracket")
        if not isinstance(bracket, list) or len(bracket) != 2:
            issues.append(f"L{n:03d}: no bracket")
        lo, hi = solver.derive_bracket(row["steps"])
        if row["status"] == "complete":
            if not lo or not hi or row["p_star"] != hi["power"] or row["build_star"] != hi["build"] or bracket != [lo["R"], hi["R"]]:
                issues.append(f"L{n:03d}: chosen passing bracket inconsistent")
            if not row.get("precision_met"):
                wide.append({"level": n, "bracket": bracket, "stop_reason": row.get("stop_reason")})
        elif row["status"] in ("lower_bound_passes", "upper_bound_fails"):
            if row.get("p_star") is not None:
                issues.append(f"L{n:03d}: invented censored P*")
            censored.append({"level": n, "status": row["status"], "bracket": bracket})
        else:
            issues.append(f"L{n:03d}: unfinished {row['status']}")
        if hi and hi["wins"] == 9:
            runs = json.loads(Path(hi["evidence"]).read_text())["runs"]
            exact_nine.append({"level": n, "p_star": row.get("p_star"), "R": hi["R"], "scale": hi["scale"],
                               "losing_seeds": [r["seed"] for r in runs if not r["victory"]], "evidence": hi["evidence"]})
        if n in solver.WALL_LEVELS:
            upper = next(s for s in row["steps"] if s["scale"] == 1.8)
            wall_rows.append({"level": n, "status": row["status"], "old_recommended": row["recommended"],
                              "p_star": row.get("p_star"), "r_star": row.get("r_star"), "scale_bracket": row.get("scale_bracket"),
                              "bracket": bracket, "upper_1_8_power": upper["power"], "upper_1_8_wins": upper["wins"],
                              "passing_wins": hi["wins"] if hi else None, "precision_met": row.get("precision_met"),
                              "new_unique_samples": len({s["evidence"] for s in row["steps"]} - {s["evidence"] for s in original[n]["steps"]})})
        for step in row["steps"]:
            path = Path(step["evidence"])
            if not path.resolve().is_relative_to(evidence_root.resolve()):
                issues.append(f"out-of-scope evidence {path}")
                continue
            if path in paths:
                continue
            paths.add(path.resolve())
            try:
                raw = json.loads(path.read_text())
                runs = solver.validate_runs(raw, n, step["build"])
                if raw["combat_input_fingerprint"] != payload["combat_input_fingerprint"]:
                    raise ValueError("combat fingerprint mismatch")
                if sum(r["victory"] for r in runs) != step["wins"] or statistics.median(r["base_ratio"] for r in runs) != step["base_median"]:
                    raise ValueError("checkpoint summary mismatch")
                if statistics.median(r["elapsed_seconds"] for r in runs) != step["elapsed_median"]:
                    raise ValueError("elapsed median mismatch")
                level = next(l for l in tables["levels"] if solver.sweep_level_number(l) == n)
                if solver.power(level, step["build"], tables)["power"] != step["power"] or step["R"] != step["power"] / row["recommended"]:
                    raise ValueError("display power/R differs from frozen reference ruler")
                if len(list((path.parent / "godot_logs").glob("*.log"))) != 10:
                    raise ValueError("missing raw logs")
            except Exception as error:
                issues.append(f"{path}: {error}")
    # macOS /tmp aliases /private/tmp. Checkpoints store canonical paths, so
    # normalize both sides before looking for truly unreferenced samples.
    all_sweeps = {path.resolve() for path in evidence_root.glob("level_*/step_*/sweep.json")}
    if all_sweeps - paths:
        issues.append("unreferenced raw sweep evidence; must account for interrupted samples")
    incomplete = []
    for path in all_sweeps:
        raw = json.loads(path.read_text())
        if sorted(r.get("seed", -1) for r in raw.get("runs", [])) != solver.SEEDS or any(r.get("error") or r.get("timeout") or r.get("probe_status") for r in raw.get("runs", [])):
            incomplete.append(str(path))
    script_error_logs = [str(p) for p in evidence_root.glob("level_*/step_*/**/*.log") if "SCRIPT ERROR" in p.read_text(errors="replace")]
    if incomplete or script_error_logs or payload.get("errors"):
        issues.append("incomplete/error/script-error evidence")
    return {"schema_version": 1, "full_99_rows": len(rows) == 99, "status_counts": dict(collections.Counter(r["status"] for r in rows)),
            "unchanged_non_wall_levels": unchanged, "original_wall_samples_reused": len(reused_original_paths),
            "original_archived_files_sha_checked": prior_files_checked,
            "unique_sample_count": len(paths), "unique_runtime_runs": len(paths) * 10,
            "new_wall_unique_samples": sum(r["new_unique_samples"] for r in wall_rows),
            "new_wall_runtime_runs": sum(r["new_unique_samples"] for r in wall_rows) * 10,
            "unreferenced_raw_sweeps": sorted(str(p) for p in all_sweeps - paths),
            "wall_rows": sorted(wall_rows, key=lambda r: r["level"]), "censored": censored,
            "passing_endpoint_exactly_9_of_10": exact_nine, "seven_step_limit_without_precision": wide,
            "script_error_logs": script_error_logs, "incomplete_or_timeout_sweeps": incomplete,
            "checkpoint_errors": payload.get("errors", []), "issues": issues}


def archive(source: Path, destination: Path, summary_path: Path, runtime_path: Path) -> dict:
    if destination.exists():
        raise ValueError("refuse to overwrite evidence archive")
    if digest(OLD_ARCHIVE) != OLD_ARCHIVE_SHA:
        raise ValueError("original stage-one archive SHA changed")
    admin = source / "audit_admin_walls"
    admin.mkdir(exist_ok=True)
    for path in (summary_path, runtime_path, Path(__file__)):
        shutil.copy2(path, admin / path.name)
    for path in sorted(Path("/tmp").glob("zf_linear_p2*_2026_10_03.log")):
        if "archive" not in path.name:
            shutil.copy2(path, admin / path.name)
    manifest = {}
    for path in sorted(source.rglob("*")):
        if path.is_symlink():
            raise ValueError(f"symlink in evidence {path}")
        if path.is_file() and path.name != "evidence_manifest_walls.json":
            manifest[str(path.relative_to(source))] = {"bytes": path.stat().st_size, "sha256": digest(path)}
    solver.atomic_write(source / "evidence_manifest_walls.json", manifest)
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".zf_linear_walls_archive_", dir=destination.parent) as directory:
        staged = Path(directory) / destination.name
        subprocess.run(["tar", "-czf", str(staged), "-C", str(source.parent), source.name], env=dict(os.environ, COPYFILE_DISABLE="1"), check=True)
        seen = set()
        with tarfile.open(staged, "r:gz") as tar:
            for entry in tar:
                if not entry.isfile():
                    continue
                relative = str(Path(entry.name).relative_to(source.name))
                if relative == "evidence_manifest_walls.json":
                    continue
                if relative in seen:
                    raise ValueError("duplicate archive path")
                expected = manifest[relative]
                h = hashlib.sha256()
                with tar.extractfile(entry) as stream:
                    for block in iter(lambda: stream.read(1024 * 1024), b""):
                        h.update(block)
                if entry.size != expected["bytes"] or h.hexdigest() != expected["sha256"]:
                    raise ValueError("archive bytes differ: " + relative)
                seen.add(relative)
        if seen != set(manifest):
            raise ValueError("missing archive members")
        os.link(staged, destination)
    return {"path": str(destination), "sha256": digest(destination), "bytes": destination.stat().st_size,
            "verified_files": len(manifest), "old_archive": str(OLD_ARCHIVE), "old_archive_sha256_unchanged": OLD_ARCHIVE_SHA,
            "raw_source": str(source), "in_git": False, "tar_integrity": "all regular file SHA256/size verified; no overwrite"}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime-lines", type=Path, default=ROOT / "design/audits/runtime_clear_lines_2026_10_03.json")
    parser.add_argument("--evidence-dir", type=Path, default=Path("/tmp/zf_linear_t1_2026_10_03"))
    parser.add_argument("--report-dir", type=Path, default=ROOT / "design/audits/linear_power_p2_2026_10_03")
    parser.add_argument("--archive", action="store_true")
    parser.add_argument("--destination", type=Path, default=Path("/Users/gavin/Desktop/zombiefire_evidence/runtime_clear_lines_2026_10_03_walls.tar.gz"))
    options = parser.parse_args()
    if not options.report_dir.resolve().is_relative_to(ROOT / "design/audits") or options.evidence_dir.resolve() != Path("/tmp/zf_linear_t1_2026_10_03").resolve():
        parser.error("only this worktree's audit directory and the authorized raw evidence directory are allowed")
    if options.archive and options.destination != Path("/Users/gavin/Desktop/zombiefire_evidence/runtime_clear_lines_2026_10_03_walls.tar.gz"):
        parser.error("archive publication is restricted to the Owner-approved walls path")
    baseline = json.loads(subprocess.check_output(["git", "show", f"{BASELINE}:design/audits/runtime_clear_lines_2026_10_03.json"], cwd=ROOT))
    payload = json.loads(options.runtime_lines.read_text())
    result = verify(payload, baseline, options.evidence_dir)
    summary_path = options.report_dir / "wall_evidence_summary_2026_10_03.json"
    solver.atomic_write(summary_path, result)
    print(json.dumps(result, indent=2, ensure_ascii=False))
    if result["issues"]:
        return 1
    if options.archive:
        metadata = archive(options.evidence_dir, options.destination, summary_path, options.runtime_lines)
        solver.atomic_write(options.report_dir / "wall_evidence_archive_2026_10_03.json", metadata)
        print(json.dumps(metadata, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
