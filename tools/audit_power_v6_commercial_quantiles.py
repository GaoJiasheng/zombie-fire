#!/usr/bin/env python3
"""Recalibrate monetization gates by preserving v5 trigger quantiles."""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
import types
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import power_ruler_model as prm  # noqa: E402
import power_scale_v6 as psv6  # noqa: E402

OLD_REF = "f8361dfb"
REPORT = ROOT / "design" / "audits" / "power_scale_v6_commercial_quantiles.md"


def git_text(ref: str, path: str) -> str:
    return subprocess.check_output(
        ["git", "show", f"{ref}:{path}"], cwd=ROOT, text=True)


def old_module(ref: str):
    module = types.ModuleType("power_ruler_model_v5_snapshot")
    module.__file__ = str(ROOT / "tools" / "power_ruler_model.py")
    source = git_text(ref, "tools/power_ruler_model.py")
    exec(compile(source, module.__file__, "exec"), module.__dict__)
    return module


def old_tables(ref: str) -> dict:
    return {
        name: json.loads(git_text(ref, f"data/{name}.json"))
        for name in (
            "characters", "weapons", "armors", "chips", "pets", "skills",
            "bosses", "economy", "premium_sets",
        )
    }


def premium_build(base: dict, set_row: dict, tables: dict) -> dict:
    result = dict(base)
    for slot, table_name in (
        ("weapon", "weapons"), ("armor", "armors"),
        ("chip", "chips"), ("pet", "pets"),
    ):
        item_id = str(set_row[slot])
        current_id = str(base.get(slot, ""))
        current_level = int(base.get(f"{slot}_level", 1)) if current_id else 1
        maximum = int(tables[table_name][item_id].get("max_level", current_level))
        result[slot] = item_id
        result[f"{slot}_level"] = min(max(current_level, 1), maximum)
    return result


def choose_threshold(values: list[float], target_count: int, default: float) -> float:
    if not values or target_count <= 0:
        return default
    ordered = sorted(values, reverse=True)
    if target_count >= len(ordered):
        return max(ordered[-1] - 1e-6, 0.0)
    return (ordered[target_count - 1] + ordered[target_count]) * 0.5


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--old-ref", default=OLD_REF)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()

    old = old_module(args.old_ref)
    historical = old_tables(args.old_ref)
    old_levels = json.loads(git_text(args.old_ref, "data/levels.json"))
    old_by_id = {row["id"]: row for row in old_levels}
    model = psv6.PowerScaleV6.build_from_fixture()
    tables = model.tables
    bosses = prm.load_table("bosses")
    sets = prm.load_table("premium_sets")
    old_rows = []
    new_rows = []
    set_uplifts: dict[str, list[float]] = {}
    for fixture in model.fixture_rows:
        level_no = int(fixture["level"])
        level_id = str(fixture["level_id"])
        level = model.levels_by_id[level_id]
        old_level = old_by_id[level_id]
        weakness = str(level.get("primary_weakness", "physical"))
        base = dict(fixture["build"])
        old_contract = old_level["clear_requirement"]["power_contract"]
        old_current = old.power_for_build(
            old_level, old_contract, base, historical["characters"], historical["weapons"],
            historical["armors"], historical["chips"], historical["pets"], historical["skills"],
            historical["bosses"], historical["economy"])["power"]
        new_current = model.effective_power_for_build(base)["effective_power"]
        old_rec = int(old_contract["recommended_power"])
        new_rec = int(model.requirements[level_id]["recommended_power"])
        best_old = None
        best_new = None
        for set_row in historical["premium_sets"].values():
            unlock = set_row.get("store_unlock", {}) or {}
            if level_no - 1 < int(unlock.get("clear_level", 0)):
                continue
            candidate = premium_build(base, set_row, historical)
            old_projected = old.power_for_build(
                old_level, old_contract, candidate, historical["characters"], historical["weapons"],
                historical["armors"], historical["chips"], historical["pets"], historical["skills"],
                historical["bosses"], historical["economy"])["power"]
            weapon_id = str(set_row.get("weapon", ""))
            native = str(historical["weapons"][weapon_id].get("element", "physical"))
            if native == weakness:
                old_candidate = {
                    "level": level_no,
                    "uplift": old_projected / max(old_current, 1) - 1.0,
                    "ratio": old_projected / max(old_rec, 1),
                    "series": str(set_row.get("series_id", "")),
                    "power": old_projected,
                }
                if best_old is None or old_projected > best_old["power"]:
                    best_old = old_candidate
        for set_row in sets.values():
            unlock = set_row.get("store_unlock", {}) or {}
            if level_no - 1 < int(unlock.get("clear_level", 0)):
                continue
            candidate = premium_build(base, set_row, tables)
            new_projected = model.effective_power_for_build(candidate)["effective_power"]
            new_uplift = new_projected / max(new_current, 1) - 1.0
            series_id = str(set_row.get("series_id", ""))
            set_uplifts.setdefault(series_id, []).append(new_uplift)
            new_candidate = {
                "level": level_no,
                "uplift": new_uplift,
                "ratio": new_projected / max(new_rec, 1),
                "series": series_id,
            }
            if best_new is None or new_projected > best_new["power"]:
                best_new = {**new_candidate, "power": new_projected}
        if best_old is not None:
            old_rows.append(best_old)
        if best_new is not None:
            new_rows.append(best_new)

    old_loadout_count = sum(row["uplift"] + 1e-4 >= 0.15 for row in old_rows)
    old_result_count = sum(
        row["uplift"] + 1e-4 >= 0.0 and row["ratio"] + 1e-4 >= 1.20
        for row in old_rows)
    old_loadout_rate = old_loadout_count / max(len(old_rows), 1)
    old_result_rate = old_result_count / max(len(old_rows), 1)
    target_new_loadout = round(old_loadout_rate * len(new_rows))
    target_new_result = round(old_result_rate * len(new_rows))
    # A paid "uplift" recommendation may never advertise a downgrade. Preserve
    # the existing PurchaseManager minimum_uplift=0 semantic while searching.
    uplift_gate = max(0.0, choose_threshold(
        [row["uplift"] for row in new_rows], target_new_loadout, 0.15))
    eligible_new_results = [row["ratio"] for row in new_rows if row["uplift"] >= -1e-4]
    result_gate = choose_threshold(eligible_new_results, target_new_result, 1.20)
    new_loadout_count = sum(row["uplift"] + 1e-4 >= uplift_gate for row in new_rows)
    new_result_count = sum(
        row["uplift"] + 1e-4 >= 0.0 and row["ratio"] + 1e-4 >= result_gate
        for row in new_rows)
    new_loadout_rate = new_loadout_count / max(len(new_rows), 1)
    new_result_rate = new_result_count / max(len(new_rows), 1)
    loadout_delta = new_loadout_rate / max(old_loadout_rate, 1e-9) - 1.0
    result_delta = new_result_rate / max(old_result_rate, 1e-9) - 1.0
    passed = abs(loadout_delta) <= 0.20 and abs(result_delta) <= 0.20

    lines = [
        ("> 状态：通过（战力 6.0 商业化门槛等价分位重标）"
         if passed else
         "> 状态：部分完成（商业化等价分位未通过，负提升已如实披露）"), "",
        "# 战力 6.0 商业化门槛等价分位", "",
        f"- 旧口径快照：`{args.old_ref}`；B2 按节奏构筑。旧口径只统计已揭示且本命属性匹配的套装；新口径统计已揭示的全套装，因为弹药卡可覆盖本命元素。",
        f"- 配装页旧门槛 `+15%`：触发 {old_loadout_count}/{len(old_rows)}（{old_loadout_rate:.1%}）；新门槛 `{uplift_gate:.4f}` 触发 {new_loadout_count}/{len(new_rows)}（{new_loadout_rate:.1%}）。",
        f"- 结算页旧门槛 `R≥1.20 且提升≥0`：触发 {old_result_count}/{len(old_rows)}（{old_result_rate:.1%}）；新门槛 `R≥{result_gate:.4f} 且提升≥0` 触发 {new_result_count}/{len(new_rows)}（{new_result_rate:.1%}）。",
        f"- 触发率偏差：配装页 {loadout_delta:+.1%}；结算页 {result_delta:+.1%}（门禁 ±20%）。",
        "- 所有推荐继续要求提升非负；属性适配来自战斗中的单通道弹药覆盖，不进入恒定战力数字。",
        "", "## 分套负提升披露", "",
        "| 套装 | 可见样本 | 负提升 | 最差提升 |",
        "|---|---:|---:|---:|",
    ]
    for series_id in sorted(set_uplifts):
        values = set_uplifts[series_id]
        lines.append(
            f"| {series_id} | {len(values)} | {sum(value < -1e-4 for value in values)} | {min(values):+.3f} |")
    lines.extend(["", "## 新口径逐关最优候选", "", "| L | 套装 | 提升 | R |", "|---:|---|---:|---:|"])
    for row in new_rows:
        lines.append(
            f"| {row['level']:03d} | {row['series']} | {row['uplift']:.3f} | {row['ratio']:.3f} |")
    report = "\n".join(lines) + "\n"
    print(report)
    if args.write:
        REPORT.write_text(report, encoding="utf-8")
        print(f"wrote {REPORT.relative_to(ROOT)}")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
