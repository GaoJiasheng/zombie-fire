#!/usr/bin/env python3
"""Audit the B2 free elemental-weapon catalogue under Power Scale 6.0.

The v6 player number is a pure neutral-build function: weakness/resistance may
not be folded into it. This report records neutral display values and the
separately quantified weakness badge instead of reviving matchup-aware power.
"""
from __future__ import annotations

import argparse
import difflib
import json
from pathlib import Path

from power_ruler_model import load_table, maxed_free_build_for_level


ROOT = Path(__file__).resolve().parents[1]
REPORT_PATH = ROOT / "design" / "audits" / "free_elemental_weapon_availability.md"
CASES = (
    ("ice", "level_020", "weapon_cryocannon", "set_apocalypse_absolute_zero"),
    ("poison", "level_040", "weapon_venomlauncher", ""),
    ("lightning", "level_065", "weapon_teslacoil", "set_apocalypse_thunder"),
    ("fire", "level_075", "weapon_flamethrower", "set_apocalypse_inferno"),
)


def _measure(level: dict, contract: dict, weapon_id: str, tables: tuple[dict, ...]) -> dict:
    build, result = maxed_free_build_for_level(
        level,
        contract,
        *tables,
        fire_rate_profile_id="tier_b",
        allowed_weapon_ids={weapon_id},
    )
    return {
        "weapon": weapon_id,
        "power": int(result["power"]),
        "bottleneck": str(result["bottleneck"]),
        "character": str(build["character"]),
    }


def render_report() -> str:
    levels = {row["id"]: row for row in load_table("levels")}
    tables = tuple(load_table(name) for name in (
        "characters", "weapons", "armors", "chips", "pets", "skills", "bosses", "economy"
    ))
    premium_sets = json.loads((ROOT / "data" / "premium_sets.json").read_text(encoding="utf-8"))
    lines = [
        "# B2 免费元素武器可用性审计",
        "",
        "口径：Tier B、免费装备全满级、永久技能全满；每把武器分别调用同一套",
        "`maxed_free_build_for_level → power_for_build` 管线，在已编写的对应弱点关卡上",
        "选择其余免费槽位的最优组合。战力 6.0 的玩家数字是纯构筑中性值，属性克制",
        "不再进入该数字；代表关只验证已编写弱点，实战增益单列 `伤害×1.50` 徽章。",
        "完整付费套的专属",
        "触发、套装联动与主动技能不属于通用战力管线，因此付费对照直接引用各套装独立",
        "DPS 审计锁定的完整套装倍率带，避免用缺少套装机制的通用战力数字误判。",
        "",
        "| 元素 | 代表关 | 原生元素枪 | 中性战力 | 最强免费物理枪 | 中性战力 | 中性比值 | 克制徽章 | 同元素完整付费套 DPS 合同 | 结论 |",
        "|---|---:|---|---:|---|---:|---:|---:|---:|---|",
    ]
    failures: list[str] = []
    characters, weapons, armors, chips, pets, skills, bosses, economy = tables
    physical_weapon_ids = {
        weapon_id for weapon_id, row in weapons.items()
        if str(row.get("element", "physical")) == "physical"
        and not row.get("premium_entitlement")
    }
    for element, level_id, weapon_id, premium_set_id in CASES:
        level = levels[level_id]
        if str(level.get("primary_weakness", "")) != element:
            raise AssertionError(
                f"{level_id} weakness drifted: expected {element}, got {level.get('primary_weakness')}"
            )
        contract = dict(level["clear_requirement"]["power_contract"])
        native = _measure(level, contract, weapon_id, tables)
        physical_candidates = [
            _measure(level, contract, physical_id, tables)
            for physical_id in sorted(physical_weapon_ids)
        ]
        strongest_physical = max(physical_candidates, key=lambda row: row["power"])
        ratio = native["power"] / max(strongest_physical["power"], 1)
        paid_cell = "—"
        paid_ok = True
        if premium_set_id:
            set_row = premium_sets[premium_set_id]
            target_min = float(set_row["target_full_set_ratio_min"])
            target_max = float(set_row["target_full_set_ratio_max"])
            paid_cell = f"`{premium_set_id}` {target_min:.2f}–{target_max:.2f}×"
            paid_ok = target_min >= 1.10
        passed = native["power"] > 0 and strongest_physical["power"] > 0 and paid_ok
        if not passed:
            failures.append(
                f"{weapon_id}@{level_id}: native={native['power']}, "
                f"physical={strongest_physical['weapon']}:{strongest_physical['power']}, "
                f"paid_contract={premium_set_id or 'n/a'}:{paid_cell}"
            )
        lines.append(
            f"| {element} | {int(level_id[-3:])} | `{weapon_id}` | {native['power']:,} | "
            f"`{strongest_physical['weapon']}` | {strongest_physical['power']:,} | {ratio:.3f}× | "
            f"伤害×{float(economy.get('weakness_mult', 1.5)):.2f} | {paid_cell} | "
            f"{'通过' if passed else '失败'} |"
        )
    lines.extend((
        "",
        "说明：绝对零度、雷霆、炼狱完整套分别继续由",
        "`audit_absolute_zero_premium_dps.py`、`audit_character_endgame_dps.py`、",
        "`audit_inferno_premium_dps.py` 实算并守住数据源里的发布合同。本表不再伪造一个",
        "忽略套装机制的“付费有效战力”。战役与正式运行时默认冻结为 Tier B；",
        "属性弹覆盖与元素单通道行为由 m1 smoke 验证，不能用中性显示值替代伤害审计。",
        "",
    ))
    if failures:
        raise AssertionError("free elemental weapon contract failed: " + "; ".join(failures))
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write", action="store_true", help="write the checked-in report")
    parser.add_argument("--check", action="store_true", help="fail if the checked-in report is stale")
    args = parser.parse_args()
    rendered = render_report()
    if args.write:
        REPORT_PATH.write_text(rendered, encoding="utf-8")
    if args.check:
        current = REPORT_PATH.read_text(encoding="utf-8") if REPORT_PATH.exists() else ""
        if current != rendered:
            print("".join(difflib.unified_diff(
                current.splitlines(True), rendered.splitlines(True),
                fromfile=str(REPORT_PATH), tofile="regenerated",
            )))
            raise SystemExit("free elemental weapon report is stale; run with --write")
    print(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
