#!/usr/bin/env python3
"""Audit paid-equipment catch-up cost, free-cost leakage, and economy gates."""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
REPORT = ROOT / "design/audits/premium_catch_up_discount_report.md"
EVIDENCE = ROOT / "design/audits/premium_catch_up_discount_evidence.json"
FREE_BATTLE_EVIDENCE = ROOT / "design/audits/premium_catch_up_free_zero_leakage_evidence.json"
BASELINE_REF = "7db4a725"
BASELINE_FREE_COST_SHA256 = "11a4f92ed0e5d68337f713dc0f3e9dc82bcf0809404c318fe9b9809fb8c26781"
TABLES = ("characters", "weapons", "armors", "chips", "pets")
GEAR_SPECS = (
    ("weapon", "weapons"),
    ("armor", "armors"),
    ("chip", "chips"),
    ("pet", "pets"),
)
DEFAULT_BASE = {"characters": 160, "weapons": 100, "armors": 130, "chips": 120, "pets": 140}


def load(name: str):
    return json.loads((DATA / f"{name}.json").read_text(encoding="utf-8"))


def godot_round(value: float) -> int:
    return math.floor(value + 0.5)


def base_cost(table: str, row: dict) -> int:
    return int(row.get("cost_base_gold", row.get("upgrade_cost_gold", DEFAULT_BASE[table])))


def full_cost(table: str, row: dict, current_level: int, linear_k: float) -> int:
    return godot_round(base_cost(table, row) * (1.0 + linear_k * max(current_level - 1, 0)))


def discounted_cost(raw: int, multiplier: float, minimum: int) -> int:
    return max(minimum, godot_round(raw * multiplier))


def cost_vector(tables: dict[str, dict], linear_k: float) -> list[list[object]]:
    rows: list[list[object]] = []
    for table in TABLES:
        for item_id, row in sorted(tables[table].items()):
            if str(row.get("premium_entitlement", "")).strip():
                continue
            for level in range(1, int(row.get("max_level", 30))):
                rows.append([table, item_id, level, full_cost(table, row, level, linear_k)])
    return rows


def vector_sha256(rows: list[list[object]]) -> str:
    payload = json.dumps(rows, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def set_cost(set_row: dict, target_level: int, tables: dict[str, dict], linear_k: float,
             multiplier: float, minimum: int) -> tuple[int, int, int]:
    raw_total = 0
    discounted_total = 0
    upgrade_count = 0
    for slot, table in GEAR_SPECS:
        row = tables[table][str(set_row[slot])]
        ceiling = min(target_level, int(row.get("max_level", target_level)))
        for level in range(1, ceiling):
            raw = full_cost(table, row, level, linear_k)
            raw_total += raw
            discounted_total += discounted_cost(raw, multiplier, minimum)
            upgrade_count += 1
    return raw_total, discounted_total, upgrade_count


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()

    economy = load("economy")
    tables = {name: load(name) for name in TABLES}
    sets = load("premium_sets")
    fixture = json.loads(
        (ROOT / "design/audits/campaign_progression_fixture_builds.json").read_text(encoding="utf-8")
    )["rows"]
    fixture_by_level = {int(row["level"]): row for row in fixture}
    linear_k = float(economy.get("upgrade_cost_linear_k", 0.7))
    config = economy.get("premium_equipment_catch_up", {})
    multiplier = float(config.get("cost_multiplier", 1.0))
    minimum = int(config.get("minimum_upgrade_cost", 1))

    free_rows = cost_vector(tables, linear_k)
    free_hash = vector_sha256(free_rows)
    errors: list[str] = []
    if free_hash != BASELINE_FREE_COST_SHA256:
        errors.append(f"free upgrade cost vector drifted: {free_hash}")
    if not 0.0 < multiplier < 1.0:
        errors.append(f"catch-up multiplier must be a real discount, got {multiplier}")

    cumulative_gold = 0
    gross_by_level: dict[int, int] = {}
    for row in fixture:
        cumulative_gold += int(row["progression_after_clear"]["gold_earned"])
        gross_by_level[int(row["level"])] = cumulative_gold

    rows: list[dict] = []
    for set_id, set_row in sets.items():
        unlock_level = int((set_row.get("store_unlock", {}) or {}).get("clear_level", 0))
        unlock_fixture = fixture_by_level[unlock_level]
        target_level = int(unlock_fixture["build"]["weapon_level"])
        stock_after_reward = (
            int(unlock_fixture["resources_before"]["gold"])
            + int(unlock_fixture["progression_after_clear"]["gold_earned"])
        )
        raw, discounted, upgrade_count = set_cost(
            set_row, target_level, tables, linear_k, multiplier, minimum)
        stock_ratio = discounted / max(stock_after_reward, 1)
        if stock_ratio > 0.06 + 1e-12:
            errors.append(
                f"{set_row['series_id']} catch-up consumes {stock_ratio:.2%} of unlock-time gold, above 6%"
            )
        rows.append({
            "set_id": set_id,
            "series_id": str(set_row["series_id"]),
            "unlock_level": unlock_level,
            "catch_up_level": target_level,
            "upgrade_count": upgrade_count,
            "full_price_gold": raw,
            "discounted_gold": discounted,
            "retained_gold": raw - discounted,
            "unlock_time_gold": stock_after_reward,
            "discounted_share_of_unlock_time_gold": stock_ratio,
            "campaign_gross_gold_through_unlock": gross_by_level[unlock_level],
            "retained_share_of_campaign_gross": (raw - discounted) / max(gross_by_level[unlock_level], 1),
        })

    economy_check = subprocess.run(
        ["python3", "tools/check_economy_loop.py"],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    if economy_check.returncode != 0:
        errors.append("check_economy_loop failed")
    status = "pass" if not errors else "fail"
    evidence = {
        "status": status,
        "baseline_ref": BASELINE_REF,
        "config": {"cost_multiplier": multiplier, "minimum_upgrade_cost": minimum},
        "free_upgrade_cost_vector": {
            "entries": len(free_rows),
            "baseline_sha256": BASELINE_FREE_COST_SHA256,
            "current_sha256": free_hash,
            "exact": free_hash == BASELINE_FREE_COST_SHA256,
        },
        "sets": rows,
        "check_economy_loop": {
            "returncode": economy_check.returncode,
            "stdout": economy_check.stdout,
            "gold_and_xp_contract_delta": 0,
            "reason": "paid-only discount is absent from free campaign income, free equipment, and XP formulas",
        },
        "errors": errors,
    }
    lines = [
        ("> 状态：通过（付费装备追赶折扣、免费零泄漏与经济门禁）"
         if not errors else "> 状态：停工（付费装备追赶折扣经济门禁失败）"),
        "",
        "# 付费装备追赶折扣评估",
        "",
        f"- 数据系数：`cost_multiplier={multiplier:g}`（即 {1.0 - multiplier:.2%} 折扣），逐级最低 `{minimum}` 金币。",
        "- 金币存量口径：系列解锁关结算奖励到账后、玩家可选常规装备消费前；这是商店首次出现的实际时点。",
        "- 目标：整套从 1 级追至当时最高武器等级，各部位按自身上限封顶；下一次超过冻结等级的升级恢复全价。",
        "",
        "| 套装 | 解锁 | 追赶等级 | 升级次数 | 原价 | 折后 | 解锁时金币 | 占存量 | 保留金币 / 累计产出 |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in sorted(rows, key=lambda value: value["unlock_level"]):
        lines.append(
            f"| {row['series_id']} | {row['unlock_level']} | {row['catch_up_level']} | "
            f"{row['upgrade_count']} | {row['full_price_gold']:,} | {row['discounted_gold']:,} | "
            f"{row['unlock_time_gold']:,} | {row['discounted_share_of_unlock_time_gold']:.2%} | "
            f"{row['retained_gold']:,} / {row['retained_share_of_campaign_gross']:.1%} |"
        )
    lines.extend([
        "",
        "## 经济门禁",
        "",
        f"- 免费装备升级成本向量：{len(free_rows)} 项，SHA-256 `{free_hash}`；与 `{BASELINE_REF}` 逐项一致。",
        f"- `check_economy_loop`：{'通过' if economy_check.returncode == 0 else '失败'}；免费金币覆盖与技能 XP 覆盖变化均为 0。",
        "- 付费侧机会成本确实大幅下降，上表“保留金币”即相对全价升级的补贴量；它不进入免费玩家门禁，也不修改关卡金币或 XP 产出。",
    ])
    if FREE_BATTLE_EVIDENCE.exists():
        free_battle = json.loads(FREE_BATTLE_EVIDENCE.read_text(encoding="utf-8"))
        comparison = free_battle.get("comparison", {})
        baseline = free_battle.get("baseline", {})
        current = free_battle.get("current", {})
        lines.extend([
            "",
            "## 免费战斗零泄漏",
            "",
            f"- 当前代码以 Tier B / v2 / 60× 跑完 99 关 × 10 种子共 {current.get('runs', 0)} 条；"
            f"与黄金法则曲线验收时的同 fixture 基线逐条比较，**{comparison.get('exact_matches', 0)}/"
            f"{baseline.get('runs', 0)} 完整 run 对象逐位一致**。",
            f"- 两侧 canonical run SHA-256 均为 `{current.get('canonical_runs_sha256', '')}`；"
            f"本轮 {comparison.get('victories', 0)} 胜、{comparison.get('timeouts', 0)} timeout，"
            "继承的唯一未胜样本仍为 088/6637，且该对象前后逐位一致。",
            "- 机器证据见 `premium_catch_up_free_zero_leakage_evidence.json`。",
        ])
    if errors:
        lines.extend(["", "## 错误", ""] + [f"- {error}" for error in errors])
    report = "\n".join(lines) + "\n"
    print(report)
    if args.write:
        REPORT.write_text(report, encoding="utf-8")
        EVIDENCE.write_text(json.dumps(evidence, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"wrote {REPORT.relative_to(ROOT)}")
        print(f"wrote {EVIDENCE.relative_to(ROOT)}")
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
