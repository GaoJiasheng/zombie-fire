#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
SCAN = ["meta", "gameplay", "core", "data", "main.gd", "main.tscn", "project.godot", "docs/app_store_metadata_zh.md"]
UI_SCAN = ["meta", "gameplay", "core", "data", "main.gd", "main.tscn"]
FORBIDDEN = [
    "F3",
    "调试信息",
    "待配置",
    "support@example",
    "Temporary placeholder",
    "replace this draft",
    "10 关第一章",
    "第一章 10",
]
VISIBLE_UI_FORBIDDEN = [
    "HERO UNIT",
    "MAIN WEAPON",
    "MAIN CANNON",
    "TACTICAL LOADOUT",
    "FRONTLINE DEPLOY",
    "BREACH",
    "BOSS",
    "ELITE",
    "TANK",
    "FAST",
    "SUPPORT",
    "DEBUG",
    "Lv.",
]
VISIBLE_UI_LITERAL_ALLOWLIST = {
    "BOSS_SPEED_MULT",
}


def _collect_files(items: list[str]) -> list[Path]:
    files: list[Path] = []
    for item in items:
        path = ROOT / item
        if path.is_dir():
            files.extend(p for p in path.rglob("*") if p.suffix in {".gd", ".tscn", ".md", ".json"})
        elif path.exists():
            files.append(path)
    return files


def _string_literals(text: str) -> list[str]:
    return [match.group(1) for match in re.finditer(r'"([^"\\]*(?:\\.[^"\\]*)*)"', text)]


def main() -> int:
    errors: list[str] = []
    files = _collect_files(SCAN)
    for path in files:
        text = path.read_text(errors="ignore")
        for token in FORBIDDEN:
            if token in text:
                errors.append(f"{path.relative_to(ROOT)} contains forbidden release string: {token}")
    for path in _collect_files(UI_SCAN):
        # English is forbidden in the Chinese source UI, but is the intended
        # payload of the explicit English localization catalogs.
        if path.name == "localization_en.json" or (
            path.name.startswith("localization_") and path.name.endswith("_en.json")
        ):
            continue
        text = path.read_text(errors="ignore")
        for literal in _string_literals(text):
            if literal in VISIBLE_UI_LITERAL_ALLOWLIST:
                continue
            for token in VISIBLE_UI_FORBIDDEN:
                if token in literal:
                    errors.append(f"{path.relative_to(ROOT)} contains visible English UI string: {literal}")
    premium_sets = json.loads((ROOT / "data" / "premium_sets.json").read_text(encoding="utf-8"))
    expected_unlocks = {
        "inferno": 30,
        "thunder": 50,
        "absolute_zero": 70,
        "golden_law": 90,
    }
    mechanism_copy = {
        "inferno": ("燃爆扩散", "Combustion spread"),
        "thunder": ("过载连锁", "Overload chains"),
        "absolute_zero": ("碎冰连爆", "Shatter chains"),
        "golden_law": ("裁决敕令", "Judgment and Golden Decree"),
    }
    forbidden_positioning = (
        "元素主宰",
        "枪械涂装",
        "火弱关",
        "雷弱关",
        "主宰区间",
        "Dominance Range",
        "elemental dominance",
        "weapon skin",
        "Fire-weak",
        "Lightning-weak",
        "only yield to Physical",
    )
    for set_id, row in premium_sets.items():
        for key in ("unlock_hint_zh", "unlock_hint_en", "unlock_cta_zh", "unlock_cta_en"):
            if not str(row.get(key, "")).strip():
                errors.append(f"{set_id}.{key} must provide the locked-catalog copy")
        dominance_zh = str(row.get("dominance_zh", "")).strip()
        dominance_en = str(row.get("dominance_en", "")).strip()
        series_id = str(row.get("series_id", ""))
        is_endgame_set = series_id == "golden_law"
        expected_zh_prefix = "Lv65 满配优势：" if is_endgame_set else "满配优势："
        expected_en_prefix = "Lv65 full-set edge:" if is_endgame_set else "Full-set edge:"
        if not dominance_zh.startswith(expected_zh_prefix):
            errors.append(f"{set_id}.dominance_zh must start with {expected_zh_prefix}")
        if not dominance_en.startswith(expected_en_prefix):
            errors.append(f"{set_id}.dominance_en must start with {expected_en_prefix}")
        expected_ratio = f'{float(row.get("target_full_set_ratio_center", 0)):g}×'
        for key, value in (("dominance_zh", dominance_zh), ("dominance_en", dominance_en)):
            if expected_ratio not in value:
                errors.append(f"{set_id}.{key} must disclose exact full-set ratio {expected_ratio}")
        if "纯物理输出" not in dominance_zh or "Physical DPS" not in dominance_en:
            errors.append(f"{set_id} must disclose stage-neutral Physical DPS positioning")
        if "全元素弹药适配" not in dominance_zh or "Any-element ammo" not in dominance_en:
            errors.append(f"{set_id} must disclose any-element ammo compatibility")
        if "追赶期升级半价" not in dominance_zh or "Half-price catch-up upgrades" not in dominance_en:
            errors.append(f"{set_id} must disclose the data-backed catch-up discount")
        expected_mechanism = mechanism_copy.get(series_id, ("", ""))
        if expected_mechanism[0] not in dominance_zh or expected_mechanism[1] not in dominance_en:
            errors.append(f"{set_id} must lead with its authored exclusive mechanic")
        store_unlock = row.get("store_unlock", {})
        expected_unlock = expected_unlocks.get(series_id)
        if not isinstance(store_unlock, dict) or int(store_unlock.get("clear_level", 0)) != expected_unlock:
            errors.append(f"{set_id}.store_unlock must reveal after Stage {expected_unlock}")
        if "any_character_level" in store_unlock:
            errors.append(f"{set_id}.store_unlock must not add a character-level requirement")
        authored_copy = "\n".join(
            str(value) for key, value in row.items()
            if isinstance(key, str) and (key.endswith("_zh") or key.endswith("_en"))
        )
        for token in forbidden_positioning:
            if token.lower() in authored_copy.lower():
                errors.append(f"{set_id} contains retired premium positioning: {token}")
        if is_endgame_set:
            if "Lv1–50 标准曲线" not in dominance_zh or "Lv51–65 独享超频区" not in dominance_zh:
                errors.append(f"{set_id}.dominance_zh must disclose the standard and exclusive level ranges")
            if "Standard Lv1–50 curve" not in dominance_en or "exclusive Lv51–65 overclock range" not in dominance_en:
                errors.append(f"{set_id}.dominance_en must disclose the standard and exclusive level ranges")
    if errors:
        print("Release string check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("Release string check OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
