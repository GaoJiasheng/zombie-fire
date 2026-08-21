#!/usr/bin/env python3
"""Generate the Stage A2 parallel fire-rate profile audit pack.

This tool deliberately leaves ``campaign_frontline_baseline.csv`` untouched.
All three profiles reuse the progression fixture and analytical front-line
model owned by ``audit_campaign_frontline.py``; only the profile id changes.
The Stage A runtime calibration report remains the authority for B1 decisions.
"""
from __future__ import annotations

import argparse
import csv
import io
import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import audit_campaign_frontline as frontline  # noqa: E402
import fire_rate_profiles as fire_rate_lab  # noqa: E402

AUDITS = ROOT / "design" / "audits"
TIER_PATHS = {
    "tier_a": AUDITS / "campaign_frontline_tier_a.csv",
    "tier_b": AUDITS / "campaign_frontline_tier_b.csv",
}
REPORT = AUDITS / "fire_rate_profile_comparison_report.md"
PROFILE_IDS = ("control", "tier_a", "tier_b")
PROFILE_LABELS = {
    "control": "Control（现状）",
    "tier_a": "Tier A（1.8×）",
    "tier_b": "Tier B（2.2×）",
}
GRADE_ORDER = ("easy", "light_pressure", "pressure", "high", "unwinnable")
CHECKPOINTS = (55, 75, 95)


def _rows() -> dict[str, list[dict]]:
    result: dict[str, list[dict]] = {}
    for profile_id in PROFILE_IDS:
        rows, _builds = frontline.generate_rows(profile_id)
        if len(rows) != 99 or [row["level"] for row in rows] != list(range(1, 100)):
            raise SystemExit(f"{profile_id} front-line comparison must cover 99 levels")
        result[profile_id] = rows
    return result


def _render_tier_csv(profile_id: str, rows: list[dict]) -> str:
    stream = io.StringIO(newline="")
    fields = ("fire_rate_profile",) + frontline.FIELDS
    writer = csv.DictWriter(stream, fieldnames=fields, lineterminator="\n")
    writer.writeheader()
    for row in rows:
        writer.writerow({
            "fire_rate_profile": profile_id,
            **{key: row.get(key, "") for key in frontline.FIELDS},
        })
    return stream.getvalue()


def _profile_contract(profile_id: str) -> dict:
    return fire_rate_lab.profile(frontline.TABLES["economy"], profile_id)


def _render_report(rows_by_profile: dict[str, list[dict]]) -> str:
    lines = [
        "# 攻速重整三档并列对照（阶段 A2）",
        "",
        "> 生成命令：`python3 tools/report_fire_rate_tier_comparison.py --write`",
        "> 校验命令：`python3 tools/report_fire_rate_tier_comparison.py --check`",
        "",
        "## 口径",
        "",
        "- 三档共用 `data/campaign_progression_fixture.json` 的逐关资源约束构筑；没有另写一份成长 fixture。",
        "- Control 是正式包唯一行为；Tier A/B 只用于 TestFlight 攻速实验室。",
        "- 本表沿用旧战线解析器，只用于三档相对变化。B1 的绝对档位判定必须以 `frontline_calibration_report.md` 的运行时探针为准。",
        "- 现有 `campaign_frontline_baseline.csv` 继续作为 RC 新鲜度基线，本阶段未替换。",
        "",
        "## 档位合同",
        "",
        "| 档位 | 总射速上限（相对武器基础） | 被削 DPS 折回单发 | 用途 |",
        "|---|---:|---:|---|",
    ]
    for profile_id in PROFILE_IDS:
        row = _profile_contract(profile_id)
        cap = float(row.get("global_weapon_base_cap", 0.0))
        cap_text = "∞" if cap <= 0.0 else f"{cap:.1f}×"
        refund = float(row.get("removed_dps_compensation", 0.0)) * 100.0
        usage = "正式默认 / 黄金基线" if profile_id == "control" else "TestFlight 实验"
        lines.append(f"| {PROFILE_LABELS[profile_id]} | {cap_text} | {refund:.0f}% | {usage} |")

    lines.extend([
        "",
        "## 战线档位分布（解析模型，仅作相对对照）",
        "",
        "| 档位 | 轻松 | 略有压力 | 压力 | 难度高 | 不可胜 |",
        "|---|---:|---:|---:|---:|---:|",
    ])
    for profile_id in PROFILE_IDS:
        counts = Counter(row["grade"] for row in rows_by_profile[profile_id])
        lines.append(
            f"| {PROFILE_LABELS[profile_id]} | "
            + " | ".join(str(counts.get(grade, 0)) for grade in GRADE_ORDER)
            + " |"
        )

    lines.extend([
        "",
        "## 关键节点",
        "",
        "| 关卡 | 档位 | 武器 | 群体 DPS | Boss DPS | 最深推进 | 基地剩余 | 判定 |",
        "|---:|---|---|---:|---:|---:|---:|---|",
    ])
    for level_no in CHECKPOINTS:
        for profile_id in PROFILE_IDS:
            row = rows_by_profile[profile_id][level_no - 1]
            lines.append(
                f"| {level_no:03d} | {PROFILE_LABELS[profile_id]} | {row['weapon']} | "
                f"{float(row['crowd_dps']):.2f} | {float(row['boss_dps']):.2f} | "
                f"{float(row['max_progress_pct']):.2f}% | {float(row['base_hp_pct']):.2f}% | "
                f"{row['grade_zh']} |"
            )

    lines.extend([
        "",
        "## 99 关 DPS 成长曲线",
        "",
        "| 关卡 | Control 群体 | A 群体 | B 群体 | Control Boss | A Boss | B Boss |",
        "|---:|---:|---:|---:|---:|---:|---:|",
    ])
    for index in range(99):
        control = rows_by_profile["control"][index]
        tier_a = rows_by_profile["tier_a"][index]
        tier_b = rows_by_profile["tier_b"][index]
        lines.append(
            f"| {index + 1:03d} | {float(control['crowd_dps']):.2f} | "
            f"{float(tier_a['crowd_dps']):.2f} | {float(tier_b['crowd_dps']):.2f} | "
            f"{float(control['boss_dps']):.2f} | {float(tier_a['boss_dps']):.2f} | "
            f"{float(tier_b['boss_dps']):.2f} |"
        )

    lines.extend([
        "",
        "## 阶段结论",
        "",
        "- Control 的 CSV 与既有黄金基线继续由 `audit_campaign_frontline.py --check` 守护；A/B 不接管 RC 基线。",
        "- A/B 的射速压缩会降低极端叠速构筑的理论吞吐，50% 单发补偿只返还被削部分的一半，符合 A2 的取样目的。",
        "- Tier A 在现有离线 `simulate_balance` 口径下，level_099 的预计清场时间会超过当前 460 秒上限；这是 B1 冻结档位前必须处理的实验结果，不通过修改正式关卡或放宽门禁掩盖。",
        "- 003/008/013 的旧解析模型仍显著低估实际推进，故以上档位数量不能冻结；运行时校准报告仍是绝对判断依据。",
        "",
    ])
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    rows_by_profile = _rows()
    outputs = {
        TIER_PATHS[profile_id]: _render_tier_csv(profile_id, rows_by_profile[profile_id])
        for profile_id in TIER_PATHS
    }
    outputs[REPORT] = _render_report(rows_by_profile)

    if args.write:
        AUDITS.mkdir(parents=True, exist_ok=True)
        for path, content in outputs.items():
            path.write_text(content, encoding="utf-8")
    if args.check:
        for path, content in outputs.items():
            if not path.is_file() or path.read_text(encoding="utf-8") != content:
                raise SystemExit(
                    f"{path.relative_to(ROOT)} is stale; run "
                    "tools/report_fire_rate_tier_comparison.py --write"
                )

    summary = {
        profile_id: dict(Counter(row["grade"] for row in rows))
        for profile_id, rows in rows_by_profile.items()
    }
    print(json.dumps(summary, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
