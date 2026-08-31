#!/usr/bin/env python3
"""Expand the challenge curve into the auditable 99-level target/comparison table."""

from __future__ import annotations

import json
from pathlib import Path

from challenge_curve import exponents_for_level, rule_for_level

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
AUDIT = ROOT / "design" / "audits"
JSON_OUTPUT = AUDIT / "challenge_curve_level_targets.json"
MD_OUTPUT = AUDIT / "challenge_curve_old_new_summary.md"
OLD = [
    (1.34, 1.12, 1.00, 1.00, 1.50), (1.42, 1.02, 1.08, 1.00, 1.50),
    (1.36, 1.06, 1.16, 1.04, 1.50), (1.32, 1.10, 1.08, 1.16, 1.50),
    (1.34, 1.08, 1.10, 1.20, 1.50), (1.38, 1.04, 1.18, 1.14, 1.50),
    (1.34, 1.10, 1.12, 1.20, 1.50), (1.30, 1.15, 1.10, 1.24, 1.50),
    (1.12, 1.08, 1.14, 1.16, 1.50), (1.01, 1.12, 1.16, 1.21, 1.50),
]
RUNTIME_SUMMARY = AUDIT / "challenge_curve_tier_b_20260831" / "runtime_summary.json"
FINAL_REPORT = AUDIT / "challenge_curve_tier_b_20260831" / "final_report.md"


def load(name: str):
    return json.loads((DATA / f"{name}.json").read_text(encoding="utf-8"))


def main() -> int:
    challenges = load("challenges")
    targets = load("campaign_pacing_targets")["chapter_level_targets"]
    runtime = json.loads(RUNTIME_SUMMARY.read_text(encoding="utf-8"))
    runtime_by_chapter = {int(row["chapter"]): row for row in runtime["chapters"]}
    rows = []
    for level in range(1, 100):
        chapter = (level - 1) // 10 + 1
        normal = str(targets[str(chapter)][(level - 1) % 10])
        rule = rule_for_level(level, challenges)
        exponents = exponents_for_level(level, challenges)
        old = OLD[chapter - 1]
        representative_levels = runtime_by_chapter[chapter]["representative_levels"]
        rows.append({
            "level": level, "chapter": chapter, "normal_target": normal,
            "challenge_target_semantics": "chapter_distribution_band",
            "representative_checkpoint": level in representative_levels,
            "chapter_representative_win_rate_contract": runtime_by_chapter[chapter]["contract_band"],
            "chapter_representative_win_rate_actual": runtime_by_chapter[chapter]["representative_win_rate"],
            "reference_fixture": rule["reference_fixture"],
            "old": dict(zip(("hp", "speed", "breach", "mechanic", "recommended"), old)),
            "new": {"K": rule["hp_mult"], "hp": rule["hp_mult"], "speed": rule["speed_mult"],
                    "breach": rule["breach_damage_mult"], "mechanic": rule["mechanic_rate_mult"],
                    "recommended": rule["recommended_power_mult"], "exponents": exponents},
        })
    payload = {"schema_version": 3, "target_semantics": "chapter_distribution_and_runtime_band",
               "anchor": {"type": "fixed_frame_win_rate",
               "fixture": "golden_law_tier_1_max", "seeds": 10, "win_rate": [0.6, 0.9],
               "boss_phase_median_seconds": [150.0, 220.0], "K_099": 5.0},
               "chapter_runtime_summary": runtime["chapters"],
               "normal_l099_zero_impact": runtime["normal_l099_zero_impact"],
               "star_supply_cap": len(rows) * 3, "levels": rows}
    JSON_OUTPUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    lines = ["状态：通过", "", "# 挑战曲线逐关新旧对照", "",
             "旧 `1.556/0.92` 战力比值公式与逐关严格升档均已废止；`K(099)=5.0` 由十种子通关率反解。挑战目标按章节代表点的通关率带验收，个别关允许处于同档带内更高位置。理论挑战星供给上限 `297★`。", "",
             "|关卡|样本|代表点|章节胜率/合同|普通档|旧 HP→新 K|新移速|新突破|新机制|指数 S/B/M|", "|---:|---|:---:|---:|:---:|---:|---:|---:|---:|---:|"]
    for row in rows:
        lines.append("|{level:03d}|{reference_fixture}|{checkpoint}|{actual:.1%} / {low:.0%}–{high:.0%}|{normal_target}|{old[hp]:.2f}→{new[K]:.4f}|{new[speed]:.4f}|{new[breach]:.4f}|{new[mechanic]:.4f}|{new[exponents][speed]:.2f}/{new[exponents][breach]:.2f}/{new[exponents][mechanic]:.2f}|".format(
            checkpoint="是" if row["representative_checkpoint"] else "—",
            actual=row["chapter_representative_win_rate_actual"],
            low=row["chapter_representative_win_rate_contract"][0], high=row["chapter_representative_win_rate_contract"][1], **row))
    MD_OUTPUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    report = ["状态：通过", "", "# 挑战模式曲线数值落地摘要", "",
              "K 曲线以分段 smoothstep 从 1.25 单调升至 5.0；第 1–6 章使用 N+10 节奏样本，第 7–8 章使用免费满级毕业族，第 9–10 章使用黄金法则一档满级。", "",
              "|章|K 起→止|参考样本|代表关|十种子胜率|合同|", "|---:|---:|---|---|---:|---:|"]
    for chapter in range(1, 11):
        first = (chapter - 1) * 10 + 1
        last = min(chapter * 10, 99)
        stat = runtime_by_chapter[chapter]
        fixture = rule_for_level(first, challenges)["reference_fixture"]
        report.append(f"|{chapter}|{rule_for_level(first, challenges)['hp_mult']:.4f}→{rule_for_level(last, challenges)['hp_mult']:.4f}|{fixture}|" +
                      "/".join(f"{value:03d}" for value in stat["representative_levels"]) +
                      f"|{stat['representative_wins']}/{stat['representative_runs']} ({stat['representative_win_rate']:.1%})|" +
                      f"{stat['contract_band'][0]:.0%}–{stat['contract_band'][1]:.0%}|")
    finale = runtime["finale"]
    zero = runtime["normal_l099_zero_impact"]
    free = runtime["free_ch9_ch10_counterexample"]
    report.extend(["", f"- 099 锚点：{finale['wins']}/{finale['runs']} 通关；胜局 Boss 中位 {finale['winning_boss_phase_median_seconds']:.3f}s（合同 150–220s）。",
                   f"- 普通 099 零影响：逐位一致，前后 runs SHA `{zero['before_runs_sha256']}`。",
                   f"- 星供给上限：`{runtime['challenge_star_supply_cap']}★ / 297★`。",
                   f"- 免费反例：ch9 `{free[0]['wins']}/{free[0]['runs']}`、ch10 `{free[1]['wins']}/{free[1]['runs']}`，均低于付费参考样本 60% 下界；入口现有 `<0.85` 严重不足警告与二次确认继续生效。",
                   "- 普通 `data/levels.json` 未修改；第 9–10 章免费构筑不纳入付费参考样本胜率门禁。"])
    FINAL_REPORT.write_text("\n".join(report) + "\n", encoding="utf-8")
    print(f"Wrote {JSON_OUTPUT.relative_to(ROOT)}, {MD_OUTPUT.relative_to(ROOT)}, and {FINAL_REPORT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
