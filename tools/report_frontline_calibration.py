#!/usr/bin/env python3
"""Render the phase-A runtime calibration report from checked-in audit artifacts.

The analytical queue model remains useful as a fast 99-level diagnostic, but it
does not simulate target acquisition, projectile travel, overkill, or card-path
variance.  The fixed-step Godot probe is therefore the calibration authority
until a compact surrogate is accepted by the owner after B1.
"""

from __future__ import annotations

import argparse
import csv
import json
import statistics
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BASELINE_PATH = ROOT / "design/audits/campaign_frontline_baseline.csv"
RUNTIME_PATH = ROOT / "design/audits/frontline_runtime_probe.json"
FIXTURE_PATH = ROOT / "data/campaign_progression_fixture.json"
REPORT_PATH = ROOT / "design/audits/frontline_calibration_report.md"

GRADE_ZH = {
    "easy": "轻松",
    "light_pressure": "略有压力",
    "pressure": "压力",
    "high": "难度高但可过",
    "unwinnable": "不可胜",
}


def _pct(value: float) -> float:
    return round(value * 100.0, 2)


def _runtime_grade(progress_pct: float, base_pct: float, victories: int, run_count: int) -> str:
    if victories * 2 < run_count:
        return "unwinnable"
    if progress_pct >= 99.5:
        return "high"
    if progress_pct >= 80.0 or base_pct < 99.5:
        return "pressure"
    if progress_pct >= 50.0:
        return "light_pressure"
    return "easy"


def _range(values: list[float]) -> str:
    return f"{min(values):.2f}–{max(values):.2f}"


def build_report() -> str:
    baseline = {
        int(row["level"]): row
        for row in csv.DictReader(BASELINE_PATH.open(encoding="utf-8"))
    }
    runtime = json.loads(RUNTIME_PATH.read_text(encoding="utf-8"))
    fixture = json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))
    grouped: dict[int, list[dict]] = defaultdict(list)
    for run in runtime["runs"]:
        grouped[int(run["level"])].append(run)

    rows: list[dict] = []
    for level in runtime["levels"]:
        runs = grouped[int(level)]
        progresses = [_pct(float(run["max_progress"])) for run in runs]
        bases = [_pct(float(run["base_ratio"])) for run in runs]
        elapsed = [float(run["elapsed_seconds"]) for run in runs]
        victories = sum(bool(run["victory"]) for run in runs)
        model = baseline[int(level)]
        median_progress = statistics.median(progresses)
        median_base = statistics.median(bases)
        grade = _runtime_grade(median_progress, median_base, victories, len(runs))
        rows.append(
            {
                "level": int(level),
                "model_progress": float(model["max_progress_pct"]),
                "model_base": float(model["base_hp_pct"]),
                "model_grade": model["grade"],
                "progress": median_progress,
                "progress_range": _range(progresses),
                "base": median_base,
                "base_range": _range(bases),
                "elapsed": statistics.median(elapsed),
                "victories": victories,
                "runs": len(runs),
                "grade": grade,
            }
        )

    lines = [
        "# 战线模型运行时校准报告（阶段 A）",
        "",
        "> 状态：**待 Owner 认可**。本报告只校准工具口径，不修改 `data/levels.json`，",
        "> 也不冻结 16/43/33/7 目标分布。B1 试点获认可前，战线输出不得作为关卡改数验收依据。",
        "",
        "## 1. 校准目的与裁判口径",
        "",
        "旧 `audit_campaign_frontline.py` 使用串行队列，把抽象 crowd/boss capacity 直接换算成持续 DPS。",
        "它没有逐帧复现锁敌、弹道飞行、散弹覆盖、过量伤害、同屏目标竞争和卡牌路线，",
        "因此会同时出现两种相反误差：早期把真实推进压到接近 0%，Boss 关又把基地承伤推到极端。",
        "",
        "本轮新增 `frontline_runtime_probe.gd`，使用与 99 关审计完全相同的资源约束成长构筑，",
        "在真实 `Battle` 场景中以固定 1/60 秒物理步、固定卡牌种子自动选卡和自动施放主动技能。",
        "每关记录最深推进、基地剩余、通关、用时；每关三种子取中位数，并保留范围表达路线方差。",
        "",
        "复跑命令：",
        "",
        "```bash",
        "python3 tools/audit_campaign_frontline.py --write",
        "godot --headless --fixed-fps 60 --path . --script res://tools/frontline_runtime_probe.gd",
        "python3 tools/report_frontline_calibration.py --write",
        "python3 tools/report_frontline_calibration.py --check",
        "```",
        "",
        f"固定种子：`{fixture['runtime_probe']['fixed_card_seeds']}`；固定步长：`{runtime['simulation_step_seconds']:.8f}s`。",
        "",
        "## 2. 旧解析模型 vs 真实运行时",
        "",
        "| 关卡 | 旧模型推进 / 基地 | 运行时推进中位（范围） | 运行时基地中位（范围） | 通关 | 旧档位 → 实测档位 | 推进绝对误差 | 基地绝对误差 |",
        "|---:|---:|---:|---:|---:|---|---:|---:|",
    ]
    for row in rows:
        lines.append(
            f"| {row['level']:03d} | {row['model_progress']:.2f}% / {row['model_base']:.2f}% | "
            f"{row['progress']:.2f}%（{row['progress_range']}%） | "
            f"{row['base']:.2f}%（{row['base_range']}%） | "
            f"{row['victories']}/{row['runs']} | {GRADE_ZH[row['model_grade']]} → "
            f"{GRADE_ZH[row['grade']]} | "
            f"{abs(row['progress'] - row['model_progress']):.2f}pp | "
            f"{abs(row['base'] - row['model_base']):.2f}pp |"
        )

    grade_matches = sum(row["model_grade"] == row["grade"] for row in rows)
    median_progress_error = statistics.median(
        abs(row["progress"] - row["model_progress"]) for row in rows
    )
    median_base_error = statistics.median(
        abs(row["base"] - row["model_base"]) for row in rows
    )
    lines += [
        "",
        f"旧模型档位一致 `{grade_matches}/{len(rows)}`；推进误差中位 `{median_progress_error:.2f}pp`，"
        f"基地误差中位 `{median_base_error:.2f}pp`。这不是可通过扩大门禁容忍度解决的小误差。",
        "",
        "## 3. 003 / 008 / 013 矛盾裁决",
        "",
        "- 旧战线模型分别给出 `0.75% / 0.85% / 0.44%`，看起来所有敌人都死在出生点。",
        "- 真实运行时中位推进分别为 `24.55% / 30.65% / 26.40%`，三关均 `3/3` 满血通关。",
        "- `simulate_balance` 的 Top5 压力与旧战线模型不是同一物理量：前者基于总耐久/输出预算，",
        "  后者又把抽象 capacity 当成逐帧 DPS。二者的排名冲突来自口径混用，不是前三章关卡数据异常。",
        "",
        "结论：这三关当前属于真实运行时的“轻松”，但绝不是推进低于 1.2% 的出生点蒸发。",
        "运行时探针解释了矛盾，禁止为了对齐旧模型去改关卡。",
        "",
        "## 4. 修正提案与修正后残差",
        "",
        "### 4.1 提案",
        "",
        "阶段 A 不再把旧串行容量模型包装成战线真值。修正后的战线权威口径为：",
        "",
        "1. 资源成长构筑只来自 `campaign_progression_fixture.json`；",
        "2. 真实 Godot 战斗以固定帧执行，三固定卡牌种子取中位数；",
        "3. 档位读取中位推进与中位基地，种子最小/最大值作为方差带；",
        "4. 旧解析模型继续保留为快速筛查器，只报告与运行时的差值，不再单独判定关卡是否达标；",
        "5. 若后续需要快速 99 关代理模型，必须以更多运行时样本训练并交叉验证，",
        "   不允许用逐关补丁或逐关乘数把残差拟合为零。",
        "",
        "这项修正改变的是**折算层级**：从“抽象容量 → 单服务器持续 DPS”改为",
        "“抽象成长构筑 → 真实逐帧战斗结果”，没有修改门禁容忍度，也没有修改难度数据。",
        "",
        "### 4.2 修正后校准残差",
        "",
        "固定帧运行时既是校准观测，也是当前权威模型，所以样本中位残差为 `0pp`；",
        "仍然保留的不是拟合残差，而是卡牌路径导致的真实范围：",
        "",
        "| 关卡 | 推进范围宽度 | 基地范围宽度 | 结论 |",
        "|---:|---:|---:|---|",
    ]
    for row in rows:
        progress_values = [float(v) for v in row["progress_range"].split("–")]
        base_values = [float(v) for v in row["base_range"].split("–")]
        width_progress = progress_values[1] - progress_values[0]
        width_base = base_values[1] - base_values[0]
        conclusion = "稳定" if row["victories"] in (0, row["runs"]) else "跨通关边界，需保留方差"
        lines.append(
            f"| {row['level']:03d} | {width_progress:.2f}pp | {width_base:.2f}pp | {conclusion} |"
        )

    lines += [
        "",
        "040 的推进范围和 055/075 的胜负分叉说明卡牌路线是一级变量。后续档位报告必须同时给中位与范围，",
        "不能再把单个串行 DPS 数字当成确定性体验。095 三种子均失败，仍如实归类为不可胜。",
        "",
        "## 5. Owner 审核点与后续约束",
        "",
        "- 请确认固定帧真实战斗中位数作为 B1 前的战线权威口径。",
        "- 请确认保留三种子范围、而不是把卡牌随机性压成单点。",
        "- 本报告获认可前，`campaign_pacing_targets.json` 继续为 `frozen: false`；",
        "  16/43/33/7 只作目标差值报告，不作红绿断言。",
        "- 阶段 A2 的攻速档位对照可以使用该探针做观察，但不能据此改任何战役关卡。",
        "",
    ]
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--write", action="store_true")
    group.add_argument("--check", action="store_true")
    args = parser.parse_args()
    rendered = build_report()
    if args.write:
        REPORT_PATH.write_text(rendered, encoding="utf-8")
        print(f"Wrote {REPORT_PATH.relative_to(ROOT)}")
        return 0
    current = REPORT_PATH.read_text(encoding="utf-8") if REPORT_PATH.exists() else ""
    if current != rendered:
        print(f"STALE: {REPORT_PATH.relative_to(ROOT)}")
        return 1
    print(f"OK: {REPORT_PATH.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
