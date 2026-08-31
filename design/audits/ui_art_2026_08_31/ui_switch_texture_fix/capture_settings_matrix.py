#!/usr/bin/env python3
"""Capture the texture-backed settings switches in three device sizes."""

from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

from tools.check_visual_screens import DEBUG_SAFE_INSETS, analyze, capture  # noqa: E402


def main() -> int:
    failures: list[str] = []
    output = Path(__file__).resolve().parent / "screenshots"
    output.mkdir(parents=True, exist_ok=True)
    for width, height in ((1080, 1920), (1320, 2868), (750, 1334)):
        for language in ("zh", "en"):
            payload = {
                "language": language,
                "viewport_size": [width, height],
                "_visual_safe_insets": DEBUG_SAFE_INSETS,
            }
            label = f"settings_switch_{width}x{height}_{language}"
            destination = output / f"{label}.png"
            code, runtime_issues, runtime_output = capture("settings", payload, destination)
            if code != 0:
                failures.append(f"{label}: capture exit {code}: {runtime_output[-500:]}")
                continue
            failures.extend(f"{label}: {issue}" for issue in runtime_issues)
            failures.extend(analyze(destination, label, (width, height)))
            print(f"captured {label}", flush=True)

    if failures:
        print("Settings switch matrix failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1
    print("Settings switch matrix OK: 6 screenshots")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
