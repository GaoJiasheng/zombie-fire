#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCAN = ["meta", "gameplay", "core", "main.gd", "main.tscn", "project.godot", "docs/app_store_metadata_zh.md"]
FORBIDDEN = [
    "F3",
    "调试信息",
    "support@example",
    "Temporary placeholder",
    "replace this draft",
    "10 关第一章",
    "第一章 10",
]


def main() -> int:
    errors: list[str] = []
    files: list[Path] = []
    for item in SCAN:
        path = ROOT / item
        if path.is_dir():
            files.extend(p for p in path.rglob("*") if p.suffix in {".gd", ".tscn", ".md"})
        elif path.exists():
            files.append(path)
    for path in files:
        text = path.read_text(errors="ignore")
        for token in FORBIDDEN:
            if token in text:
                errors.append(f"{path.relative_to(ROOT)} contains forbidden release string: {token}")
    if errors:
        print("Release string check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("Release string check OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
