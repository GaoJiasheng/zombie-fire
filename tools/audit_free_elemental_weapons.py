#!/usr/bin/env python3
"""Audit the B2 free elemental-weapon availability contract.

The Owner contract compares each native free elemental weapon with the free
generic physical starter (autocannon) on an authored counter-matchup.  A
scattergun whose projectile element has been converted by a permanent ammo
skill is printed as useful context, but is deliberately not the generic
physical baseline: treating converted ammunition as "physical" would compare
two elemental builds and would silently invalidate the premium-set bands.

All values come from power_for_build through maxed_free_build_for_level; this
tool has no parallel damage formula.
"""
from __future__ import annotations

import argparse
import difflib
from pathlib import Path

from power_ruler_model import load_table, maxed_free_build_for_level


ROOT = Path(__file__).resolve().parents[1]
REPORT_PATH = ROOT / "design" / "audits" / "free_elemental_weapon_availability.md"
GENERIC_PHYSICAL_WEAPON = "weapon_autocannon"
INFORMATIONAL_SCATTER_WEAPON = "weapon_scattergun"
CASES = (
    ("ice", "level_020", "weapon_cryocannon"),
    ("poison", "level_040", "weapon_venomlauncher"),
    ("lightning", "level_065", "weapon_teslacoil"),
    ("fire", "level_075", "weapon_flamethrower"),
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
    lines = [
        "# B2 免费元素武器可用性审计",
        "",
        "口径：Tier B、免费装备全满级、永久技能全满；每把武器分别调用同一套",
        "`maxed_free_build_for_level → power_for_build` 管线，在已编写的对应弱点关卡上",
        "选择其余免费槽位的最优组合。硬门槛是原生元素枪的 matchup 感知战力必须高于",
        "通用物理入门枪 `weapon_autocannon`。属性弹转化后的散弹枪只作信息项。",
        "",
        "| 元素 | 代表关 | 原生元素枪 | 有效战力 | 自动机枪 | 相对值 | 属性散弹信息项 | 结论 |",
        "|---|---:|---|---:|---:|---:|---:|---|",
    ]
    failures: list[str] = []
    for element, level_id, weapon_id in CASES:
        level = levels[level_id]
        if str(level.get("primary_weakness", "")) != element:
            raise AssertionError(
                f"{level_id} weakness drifted: expected {element}, got {level.get('primary_weakness')}"
            )
        contract = dict(level["clear_requirement"]["power_contract"])
        native = _measure(level, contract, weapon_id, tables)
        generic = _measure(level, contract, GENERIC_PHYSICAL_WEAPON, tables)
        scatter = _measure(level, contract, INFORMATIONAL_SCATTER_WEAPON, tables)
        ratio = native["power"] / max(generic["power"], 1)
        passed = native["power"] > generic["power"]
        if not passed:
            failures.append(
                f"{weapon_id}@{level_id}: {native['power']} <= {generic['power']}"
            )
        lines.append(
            f"| {element} | {int(level_id[-3:])} | `{weapon_id}` | {native['power']:,} | "
            f"{generic['power']:,} | {ratio:.3f}× | {scatter['power']:,} | "
            f"{'通过' if passed else '失败'} |"
        )
    lines.extend((
        "",
        "说明：本表不承诺原生元素枪在每一种清群/单体组合上都压过已完成属性转化的散弹枪；",
        "它锁定的是免费玩家在对应克制关至少拥有一个优于通用物理入门枪的原生元素选择。",
        "付费同元素套装的优势继续由各系列独立 DPS 合同审计，不在本门槛中重复定义。",
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
