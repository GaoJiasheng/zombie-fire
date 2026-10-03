#!/usr/bin/env python3
"""Derive direction-A Table B, never mutate game data (design/41 section 8).

OLS log P* ~ intercept + log enemy HP + Boss HP share + chapter dummies.
All measured passing endpoints participate equally; no midpoint, monotonic
repair, adjacent-growth constraint, clipping-to-truth, or hand-tuned anchors.
"""
from __future__ import annotations

import argparse
import csv
import datetime as dt
import io
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
V0 = ROOT / "design/audits/recommended_power_table_v0_fable_2026_10_03.csv"


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
        return max(MINIMUM_RECOMMENDED, round(math.sqrt(model_power * row["p_star"])))
    if row["status"] == "lower_bound_passes":
        return max(MINIMUM_RECOMMENDED, round(model_power))
    if row["status"] == "upper_bound_fails":
        endpoint = next((step for step in row["steps"] if step["scale"] == 1.8), None)
        if not endpoint or row.get("extension_method", {}).get("scale_bounds") != [1.0, 1.8]:
            raise ValueError(f"L{row['level']:03d}: wall extension not complete")
        return max(MINIMUM_RECOMMENDED, int(endpoint["power"]))
    raise ValueError(f"L{row['level']:03d}: unfinished status {row['status']}")


def derive(runtime: dict, baseline: dict, v0: dict[int, dict], tables: dict) -> dict:
    if sorted(row["level"] for row in runtime["rows"]) != list(range(1, 100)):
        raise ValueError("Table B requires exactly levels 001..099")
    if runtime.get("errors"):
        raise ValueError("T1 checkpoint still has errors")
    hp_rows = {}
    for level in tables["levels"]:
        mob_hp, boss_hp, _ = sim.level_enemy_hp_split(level, tables["zombies"], tables["bosses"], tables["economy"])
        hp_rows[solver.sweep_level_number(level)] = {"enemy_total_hp": mob_hp + boss_hp, "boss_hp_share": boss_hp / (mob_hp + boss_hp)}
    model = fit(runtime["rows"], hp_rows)
    old_model = fit(baseline["rows"], hp_rows)
    old_rows = {row["level"]: row for row in baseline["rows"]}
    v0_design = [features(n, hp_rows[n]["enemy_total_hp"], hp_rows[n]["boss_hp_share"]) for n in range(1, 100)]
    v0_coefficients = least_squares(v0_design, [math.log(int(v0[n]["hp_model"])) for n in range(1, 100)])
    v0_diagnostic = {"coefficients": v0_coefficients, "purpose": "reverse fit rounded CSV model only; NOT the approved production fit",
                     "maximum_model_integer_residual": max(abs(round(math.exp(math.fsum(a * b for a, b in zip(x, v0_coefficients)))) - int(v0[n]["hp_model"])) for n, x in enumerate(v0_design, 1)),
                     "interpretation": "v0 CSV is consistent with HP exponent about .6 and negligible Boss-share coefficient; inference from rounded CSV, not Fable source code"}
    result_rows, violations, v0_mismatches = [], [], []
    for row in runtime["rows"]:
        number = row["level"]
        estimate = prediction(model, number, hp_rows[number])
        old_estimate = prediction(old_model, number, hp_rows[number])
        rec = recommendation(row, estimate)
        reference = v0[number]
        p_star = row.get("p_star")
        fail_endpoint, endpoint = solver.derive_bracket(row["steps"])
        edge = bool(endpoint and endpoint["wins"] == 9)
        error = rec / p_star - 1 if p_star is not None else None
        if error is not None and abs(error) > TRUTH_TOLERANCE:
            violations.append({"level": number, "kind": "truth_deviation", "value": error, "maximum": TRUTH_TOLERANCE})
        if rec < MINIMUM_RECOMMENDED:
            violations.append({"level": number, "kind": "display_floor", "value": rec})
        old_rec = recommendation(old_rows[number], old_estimate) if old_rows[number]["status"] != "upper_bound_fails" else None
        old_model_round_delta = round(old_estimate) - int(reference["hp_model"])
        old_rec_delta = old_rec - int(reference["rec_v0"]) if old_rec is not None else None
        # Fable published rounded model values; <=1 rec difference is rounding,
        # not permission to silently replace the published full precision fit.
        if abs(old_model_round_delta) > 1 or (old_rec_delta is not None and abs(old_rec_delta) > 1):
            v0_mismatches.append({"level": number, "model_round_delta": old_model_round_delta, "rec_delta": old_rec_delta})
        explanations = []
        if number in solver.WALL_LEVELS:
            explanations.append("新增[1,1.8]墙关补测；v0未包含该数值P*" if p_star else "s=1.8仍上界删失，按批准规则取封顶构筑战力，不外推P*")
        if abs(estimate - old_estimate) > 1e-9:
            explanations.append(f"全部数值P*重新OLS拟合（{old_model['sample_count']}→{model['sample_count']}点），HP模型{old_estimate:.6f}→{estimate:.6f}")
        if abs(old_model_round_delta) > 1 or (old_rec_delta is not None and abs(old_rec_delta) > 1):
            explanations.append(f"v0方法不一致：原84点按明文同时OLS拟合与v0模型差{old_model_round_delta:+d}、推荐差{old_rec_delta}；v0 CSV反拟合显示HP指数≈0.6、Boss份额系数≈0（推断，待Fable核源代码）")
        elif old_rec_delta:
            explanations.append(f"原84点复算与v0差{old_rec_delta:+d}，在整数取整误差内")
        if not explanations:
            explanations.append("与v0一致，原通过端P*不变" if rec == int(reference["rec_v0"]) else "最终整数取整差异")
        result_rows.append({"level": number, "level_id": f"level_{number:03d}", "old_recommended": row["recommended"],
                            "p_star": p_star, "model": estimate, "recommended_power": rec,
                            "edge_9_of_10": edge, "passing_wins": endpoint["wins"] if endpoint else None,
                            "measured_fail_power": fail_endpoint["power"] if fail_endpoint else None,
                            "rec_below_measured_passing_power": bool(p_star is not None and rec < p_star),
                            "rec_at_or_below_measured_fail_power": bool(p_star is not None and fail_endpoint and rec <= fail_endpoint["power"]),
                            "censored": row["status"] != "complete", "censor_status": row["status"] if row["status"] != "complete" else None,
                            "truth_deviation": error, "truth_check": "unverifiable_censored" if error is None else ("pass" if abs(error) <= TRUTH_TOLERANCE else "fail"),
                            "bracket": row["bracket"], **hp_rows[number],
                            "fable_v0_model": int(reference["hp_model"]), "fable_v0_rec": int(reference["rec_v0"]),
                            "delta_vs_fable_v0": rec - int(reference["rec_v0"]),
                            "baseline_84_model": old_estimate, "baseline_84_rec": old_rec,
                            "baseline_rec_delta_vs_v0": old_rec_delta, "difference_explanation": "；".join(explanations)})
    return {"schema_version": 1, "status": "candidate_pending_Fable_gate_B", "contract": "design/41 section 8 direction A",
            "method": "round(sqrt(model * measured passing P*)); lower-censored round(model), min50; upper-censored power(s=1.8); no monotonic constraints",
            "fit": model, "baseline_84_fit": old_model, "v0_reverse_model_diagnostic": v0_diagnostic,
            "v0_reproduction_mismatches_over_rounding": v0_mismatches,
            "truth_tolerance": TRUTH_TOLERANCE, "minimum_recommended": MINIMUM_RECOMMENDED,
            "violations": violations, "rows": result_rows,
            "G3_R1_risk_levels_below_observed_passing_power": [row["level"] for row in result_rows if row["rec_below_measured_passing_power"]],
            "G3_R1_risk_levels_at_or_below_observed_fail_power": [row["level"] for row in result_rows if row["rec_at_or_below_measured_fail_power"]],
            "censored_note": "no numeric P*: truth tolerance cannot be verified; endpoint fallback is explicitly authorized, not a pass claim",
            "prediction_note": "G3 needs fresh R=.85/1/1.15 runtime probes after gate B; ±35% does not prove ≥9/10 at R=1"}


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
    options = parser.parse_args()
    if not options.output.resolve().is_relative_to(ROOT / "design/audits"):
        parser.error("output must remain inside this worktree's design/audits")
    runtime = json.loads(options.runtime_lines.read_text())
    tables = solver.load_tables()
    if runtime["frozen_input_sha256"] != solver.input_hashes() or runtime["fixture_sha256"] != solver.sha(solver.FIXTURE):
        raise ValueError("T1 frozen inputs/fixture changed; refusing stale table")
    baseline = json.loads(subprocess.check_output(["git", "show", f"{BASELINE_COMMIT}:design/audits/runtime_clear_lines_2026_10_03.json"], cwd=ROOT))
    v0 = {int(row["level"]): row for row in csv.DictReader(V0.open())}
    payload = derive(runtime, baseline, v0, tables)
    payload["provenance"] = {"runtime_lines": str(options.runtime_lines.resolve().relative_to(ROOT)),
                             "runtime_sha256": solver.sha(options.runtime_lines), "fixture_sha256": runtime["fixture_sha256"],
                             "combat_input_fingerprint": runtime["combat_input_fingerprint"], "frozen_input_sha256": runtime["frozen_input_sha256"],
                             "v0_sha256": solver.sha(V0), "baseline_commit": BASELINE_COMMIT,
                             "tool_sha256": solver.sha(Path(__file__))}
    json_path, csv_path = options.output.with_suffix(".json"), options.output.with_suffix(".csv")
    if options.check:
        if json.loads(json_path.read_text()) != payload or csv_path.read_text() != csv_text(payload):
            print("FAIL: saved Table B is not the deterministic current-input result")
            return 1
    else:
        solver.atomic_write(json_path, payload)
        csv_path.write_text(csv_text(payload))
    print(json.dumps({key: payload[key] for key in ("status", "violations", "v0_reproduction_mismatches_over_rounding")}, ensure_ascii=False))
    print(f"rows=99 numeric_P*={payload['fit']['sample_count']} fit_R2={payload['fit']['log_R_squared']:.8f} output={json_path}")
    return int(bool(payload["violations"] or payload["v0_reproduction_mismatches_over_rounding"]))


if __name__ == "__main__":
    raise SystemExit(main())
