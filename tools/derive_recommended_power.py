#!/usr/bin/env python3
"""Derive direction-A Table B, never mutate game data (design/41 section 8).

OLS log P* ~ intercept + log enemy HP + Boss HP share + chapter dummies.
All measured passing endpoints participate equally; no midpoint, monotonic
repair, adjacent-growth constraint, or hand-tuned anchors. Gate B's approved
clamp adds headroom only after fitting; it does not alter OLS observations.
"""
from __future__ import annotations

import argparse
import csv
import datetime as dt
import io
import hashlib
import json
import math
from pathlib import Path
import subprocess

import simulate_balance as sim
import solve_runtime_clear_lines as solver

ROOT = Path(__file__).resolve().parents[1]
DATE = dt.datetime.now(dt.timezone(dt.timedelta(hours=8))).strftime("%Y_%m_%d")
TRUTH_TOLERANCE = .35
MINIMUM_RECOMMENDED = 50
BASELINE_COMMIT = "f055c7b4073aa5e45a916f3f4c49929d3fb2877a"
FIXED_REFERENCE = ROOT / "design/audits/recommended_power_table_fixed_fable_2026_10_04.json"


def least_squares(xs: list[list[float]], ys: list[float]) -> list[float]:
    """Reorthogonalized modified Gram-Schmidt QR; stdlib only, no ridge fit."""
    columns = [list(column) for column in zip(*xs)]
    width = len(columns)
    q = []
    r = [[0.0] * width for _ in range(width)]
    for j, column in enumerate(columns):
        v = list(column)
        for _ in range(2):
            for i, direction in enumerate(q):
                projection = math.fsum(a * b for a, b in zip(direction, v))
                r[i][j] += projection
                v = [a - projection * b for a, b in zip(v, direction)]
        r[j][j] = math.sqrt(math.fsum(a * a for a in v))
        if r[j][j] < 1e-10:
            raise ValueError("rank-deficient HP/chapter fit; no arbitrary fallback")
        q.append([a / r[j][j] for a in v])
    rhs = [math.fsum(a * b for a, b in zip(direction, ys)) for direction in q]
    beta = [0.0] * width
    for j in reversed(range(width)):
        beta[j] = (rhs[j] - math.fsum(r[j][k] * beta[k] for k in range(j + 1, width))) / r[j][j]
    return beta


def features(level: int, hp: float, boss_share: float) -> list[float]:
    chapter = (level - 1) // 10 + 1
    return [1.0, math.log(hp), boss_share] + [float(chapter == c) for c in range(2, 11)]


def fit(rows: list[dict], hp_rows: dict[int, dict]) -> dict:
    measured = [row for row in rows if row["status"] == "complete" and row.get("p_star") is not None]
    if len(measured) < 13:
        raise ValueError("insufficient numeric P* rows for 12-column fit")
    xs = [features(row["level"], hp_rows[row["level"]]["enemy_total_hp"], hp_rows[row["level"]]["boss_hp_share"]) for row in measured]
    ys = [math.log(row["p_star"]) for row in measured]
    beta = least_squares(xs, ys)
    fitted = [math.fsum(a * b for a, b in zip(x, beta)) for x in xs]
    sse = math.fsum((y - yhat) ** 2 for y, yhat in zip(ys, fitted))
    mean = math.fsum(ys) / len(ys)
    sst = math.fsum((y - mean) ** 2 for y in ys)
    return {"sample_count": len(measured), "levels": [row["level"] for row in measured],
            "coefficient_order": ["intercept", "log_enemy_total_hp", "boss_hp_share"] + [f"chapter_{c}_offset" for c in range(2, 11)],
            "coefficients": beta, "log_R_squared": 1 - sse / sst,
            "residual_log_sigma_population": math.sqrt(sse / len(ys)),
            "estimator": "unweighted OLS; reorthogonalized QR; chapter 1 baseline; no regularization"}


def prediction(model: dict, level: int, hp_row: dict) -> float:
    return math.exp(math.fsum(a * b for a, b in zip(model["coefficients"], features(level, hp_row["enemy_total_hp"], hp_row["boss_hp_share"]))))


def recommendation(row: dict, model_power: float) -> int:
    if row["status"] == "complete":
        # 2026-10-04 停工点 B 核定: the model adds headroom only.
        p_star = int(row["p_star"])
        return max(MINIMUM_RECOMMENDED, min(max(round(math.sqrt(model_power * p_star)), p_star), round(1.35 * p_star)))
    if row["status"] == "lower_bound_passes":
        return max(MINIMUM_RECOMMENDED, round(model_power))
    if row["status"] == "upper_bound_fails":
        endpoint = next((step for step in row["steps"] if step["scale"] == 1.8), None)
        if not endpoint or row.get("extension_method", {}).get("scale_bounds") != [1.0, 1.8]:
            raise ValueError(f"L{row['level']:03d}: wall extension not complete")
        return max(MINIMUM_RECOMMENDED, int(endpoint["power"]))
    raise ValueError(f"L{row['level']:03d}: unfinished status {row['status']}")


def derive(runtime: dict, fixed: dict[int, dict], tables: dict) -> dict:
    if sorted(row["level"] for row in runtime["rows"]) != list(range(1, 100)):
        raise ValueError("Table B requires exactly levels 001..099")
    if runtime.get("errors"):
        raise ValueError("T1 checkpoint still has errors")
    hp_rows = {}
    for level in tables["levels"]:
        mob_hp, boss_hp, _ = sim.level_enemy_hp_split(level, tables["zombies"], tables["bosses"], tables["economy"])
        hp_rows[solver.sweep_level_number(level)] = {"enemy_total_hp": mob_hp + boss_hp, "boss_hp_share": boss_hp / (mob_hp + boss_hp)}
    model = fit(runtime["rows"], hp_rows)
    rows, violations, mismatches = [], [], []
    for row in runtime["rows"]:
        number = row["level"]
        estimate = prediction(model, number, hp_rows[number])
        rec = recommendation(row, estimate)
        p_star = row.get("p_star")
        raw = round(math.sqrt(estimate * p_star)) if p_star is not None else None
        direction = "lower" if raw is not None and raw < p_star else ("upper" if raw is not None and raw > round(1.35 * p_star) else "none")
        lo, hi = solver.derive_bracket(row["steps"])
        error = rec / p_star - 1 if p_star is not None else None
        # Integer-rounded upper bound is the explicit gate-B contract.
        if p_star is not None and not p_star <= rec <= round(1.35 * p_star):
            violations.append({"level": number, "kind": "clamped_truth_bounds", "recommended": rec, "p_star": p_star})
        if rec < MINIMUM_RECOMMENDED:
            violations.append({"level": number, "kind": "display_floor", "value": rec})
        reference = fixed[number]
        if reference["p_star"] != p_star or int(reference["fixed"]) != rec:
            mismatches.append({"level": number, "reference": reference["fixed"], "recommended": rec, "p_star_match": reference["p_star"] == p_star})
        rows.append({"level": number, "level_id": f"level_{number:03d}", "old_recommended": row["recommended"],
                     "p_star": p_star, "model": estimate, "raw_geometric_recommendation": raw,
                     "recommended_power": rec, "clamp_direction": direction,
                     "clamp_lower": p_star, "clamp_upper": round(1.35 * p_star) if p_star is not None else None,
                     "edge_9_of_10": bool(hi and hi["wins"] == 9), "passing_wins": hi["wins"] if hi else None,
                     "measured_fail_power": lo["power"] if lo else None,
                     "rec_below_measured_passing_power": bool(p_star is not None and rec < p_star),
                     "rec_at_or_below_measured_fail_power": bool(p_star is not None and lo and rec <= lo["power"]),
                     "censored": p_star is None, "censor_status": row["status"] if p_star is None else None,
                     "truth_deviation": error, "truth_check": "unverifiable_censored" if error is None else "pass",
                     "bracket": row["bracket"], **hp_rows[number],
                     "fable_fixed_rec": reference["fixed"], "delta_vs_fable_fixed": rec - int(reference["fixed"]),
                     "difference_explanation": f"2026-10-04 停工点 B 核定；clamp={direction}；v0作废，不再对照"})
    return {"schema_version": 2, "status": "gate_B_ratified_2026_10_04", "contract": "design/41 section 8 direction A; 2026-10-04 gate B ratification",
            "method": "clamp(round(sqrt(model * passing P*)), P*, round(1.35 * P*)); lower-censored round(model), min50; upper-censored power(s=1.8)",
            "fit": model, "truth_tolerance": TRUTH_TOLERANCE, "minimum_recommended": MINIMUM_RECOMMENDED,
            "violations": violations, "fable_fixed_mismatches": mismatches, "rows": rows,
            "clamp_counts": {direction: sum(row["clamp_direction"] == direction for row in rows) for direction in ("lower", "upper", "none")},
            "G3_R1_risk_levels_below_observed_passing_power": [row["level"] for row in rows if row["rec_below_measured_passing_power"]],
            "G3_R1_risk_levels_at_or_below_observed_fail_power": [row["level"] for row in rows if row["rec_at_or_below_measured_fail_power"]],
            "censored_note": "No numeric P*: authorized model fallback, not a measured truth pass.",
            "prediction_note": "G3 still requires new runtime tests. R=.85 may yield 0-2/10 on cliffs; report without changing enemy data or thresholds."}


def csv_text(payload: dict) -> str:
    output = io.StringIO()
    rows = payload["rows"]
    writer = csv.DictWriter(output, fieldnames=list(rows[0]), lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    return output.getvalue()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime-lines", type=Path, default=ROOT / "design/audits/runtime_clear_lines_2026_10_03.json")
    parser.add_argument("--output", type=Path, default=ROOT / f"design/audits/recommended_power_table_{DATE}")
    parser.add_argument("--check", action="store_true", help="compare saved JSON/CSV with deterministic regeneration; no writes")
    parser.add_argument("--source-commit", help="reproduce from immutable T1 source commit after authorized requirement-side regeneration; every frozen hash must match")
    options = parser.parse_args()
    if not options.output.resolve().is_relative_to(ROOT / "design/audits"):
        parser.error("output must remain inside this worktree's design/audits")
    runtime = json.loads(options.runtime_lines.read_text())
    source_commit = None
    if options.source_commit:
        source_commit = subprocess.check_output(["git", "rev-parse", "--verify", options.source_commit + "^{commit}"], cwd=ROOT, text=True).strip()
        source = {}
        expected = {**runtime["frozen_input_sha256"], str(solver.FIXTURE.relative_to(ROOT)): runtime["fixture_sha256"]}
        for path, digest in expected.items():
            data = subprocess.check_output(["git", "show", f"{source_commit}:{path}"], cwd=ROOT)
            if hashlib.sha256(data).hexdigest() != digest:
                raise ValueError(f"historical T1 source hash mismatch: {path}")
            source[path] = data
        tables = {name: json.loads(source[f"data/{name}.json"]) for name in solver.load_tables()}
    else:
        tables = solver.load_tables()
        if runtime["frozen_input_sha256"] != solver.input_hashes() or runtime["fixture_sha256"] != solver.sha(solver.FIXTURE):
            raise ValueError("T1 frozen inputs/fixture changed; refusing stale table; use a hash-verified --source-commit for historical reproduction")
    fixed = {int(row["level"]): row for row in json.loads(FIXED_REFERENCE.read_text())}
    if set(fixed) != set(range(1, 100)):
        raise ValueError("Fable fixed reference must contain exactly 99 levels")
    payload = derive(runtime, fixed, tables)
    payload["provenance"] = {"runtime_lines": str(options.runtime_lines.resolve().relative_to(ROOT)),
                             "runtime_sha256": solver.sha(options.runtime_lines), "fixture_sha256": runtime["fixture_sha256"],
                             "combat_input_fingerprint": runtime["combat_input_fingerprint"], "frozen_input_sha256": runtime["frozen_input_sha256"],
                             "fable_fixed_sha256": solver.sha(FIXED_REFERENCE), "baseline_commit": BASELINE_COMMIT,
                             "tool_sha256": solver.sha(Path(__file__))}
    payload["provenance"]["source_commit"] = source_commit
    json_path, csv_path = options.output.with_suffix(".json"), options.output.with_suffix(".csv")
    if options.check:
        if json.loads(json_path.read_text()) != payload or csv_path.read_text() != csv_text(payload):
            print("FAIL: saved Table B is not the deterministic current-input result")
            return 1
    else:
        solver.atomic_write(json_path, payload)
        csv_path.write_text(csv_text(payload))
    print(json.dumps({key: payload[key] for key in ("status", "violations", "fable_fixed_mismatches", "clamp_counts")}, ensure_ascii=False))
    print(f"rows=99 numeric_P*={payload['fit']['sample_count']} fit_R2={payload['fit']['log_R_squared']:.8f} output={json_path}")
    return int(bool(payload["violations"] or payload["fable_fixed_mismatches"]))


if __name__ == "__main__":
    raise SystemExit(main())
