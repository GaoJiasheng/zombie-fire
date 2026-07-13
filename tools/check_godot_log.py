#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
from pathlib import Path

ERROR_RE = re.compile(r"^(?:SCRIPT ERROR|ERROR):", re.MULTILINE)
LEAK_RE = re.compile(
    r"^(?:WARNING|ERROR):.*(?:"
    r"(?:RID|ObjectDB).*leak|"
    r"leak.*(?:RID|ObjectDB)|"
    r"resources? still in use"
    r")",
    re.IGNORECASE | re.MULTILINE,
)


def find_godot_log_issues(output: str) -> list[str]:
    issues: list[str] = []
    for line in output.splitlines():
        stripped = line.strip()
        if ERROR_RE.match(stripped) or LEAK_RE.match(stripped):
            if stripped not in issues:
                issues.append(stripped)
    return issues


def main() -> int:
    parser = argparse.ArgumentParser(description="Fail on critical Godot errors or shutdown leaks.")
    parser.add_argument("log", type=Path)
    args = parser.parse_args()

    if not args.log.is_file():
        parser.error(f"log file not found: {args.log}")
    issues = find_godot_log_issues(args.log.read_text(encoding="utf-8", errors="replace"))
    if issues:
        print("Godot log validation failed:")
        for issue in issues:
            print(f"- {issue}")
        return 1
    print(f"Godot log validation passed: {args.log}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
