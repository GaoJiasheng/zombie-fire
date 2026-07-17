#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
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
        text = path.read_text(errors="ignore")
        for literal in _string_literals(text):
            if literal in VISIBLE_UI_LITERAL_ALLOWLIST:
                continue
            for token in VISIBLE_UI_FORBIDDEN:
                if token in literal:
                    errors.append(f"{path.relative_to(ROOT)} contains visible English UI string: {literal}")
    if errors:
        print("Release string check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("Release string check OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
