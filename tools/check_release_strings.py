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
    for set_id, row in premium_sets.items():
        for key in ("unlock_hint_zh", "unlock_hint_en", "unlock_cta_zh", "unlock_cta_en"):
            if not str(row.get(key, "")).strip():
                errors.append(f"{set_id}.{key} must provide the locked-catalog copy")
        dominance_zh = str(row.get("dominance_zh", "")).strip()
        dominance_en = str(row.get("dominance_en", "")).strip()
        if not dominance_zh.startswith("主宰区间："):
            errors.append(f"{set_id}.dominance_zh must start with 主宰区间：")
        if not dominance_en.startswith("Dominance Range:"):
            errors.append(f"{set_id}.dominance_en must start with Dominance Range:")
        is_endgame_set = str(row.get("series_id", "")) == "golden_law"
        if is_endgame_set:
            if "终局" not in dominance_zh or "物理" not in dominance_zh:
                errors.append(f"{set_id}.dominance_zh must disclose endgame Physical positioning")
            if "Endgame" not in dominance_en or "Physical" not in dominance_en:
                errors.append(f"{set_id}.dominance_en must disclose endgame Physical positioning")
        elif "终局" in dominance_zh or "endgame" in dominance_en.lower():
            errors.append(f"{set_id} must not imply elemental arsenal endgame dominance")
    if errors:
        print("Release string check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("Release string check OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
