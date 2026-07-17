#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
VISIBLE_UI_ROOTS = (ROOT / "gameplay", ROOT / "meta", ROOT / "ui")
FLAT_UI_PRIMITIVE = re.compile(r"\b(?:ColorRect|StyleBoxFlat)\b")


def main() -> int:
    violations: list[str] = []
    for root in VISIBLE_UI_ROOTS:
        for path in sorted(root.rglob("*")):
            if path.suffix not in {".gd", ".tscn", ".tres"}:
                continue
            for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                if FLAT_UI_PRIMITIVE.search(line):
                    violations.append(f"{path.relative_to(ROOT)}:{line_number}: {line.strip()}")

    if violations:
        print("Runtime UI primitive check failed: visible UI must use texture-backed styles.")
        for violation in violations:
            print(f"- {violation}")
        return 1

    print("Runtime UI primitive check passed: no ColorRect/StyleBoxFlat in gameplay/meta/ui.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
