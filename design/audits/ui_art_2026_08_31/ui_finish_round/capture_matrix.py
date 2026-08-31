#!/usr/bin/env python3
"""Capture the bilingual UI-finish review matrix, one Godot process at a time."""

from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

from tools.check_visual_screens import DEBUG_SAFE_INSETS, analyze, capture  # noqa: E402


SCREENS = [
    ("menu", {}),
    ("map", {}),
    (
        "loadout",
        {
            "level_id": "level_003",
            "equipment": {"selected_armor": "", "selected_chip": "", "selected_pet": ""},
        },
    ),
    ("collection", {"mode": "chips", "equipment": {"selected_chip": "chip_attack"}}),
    ("settings", {}),
]


def main() -> int:
    failures: list[str] = []
    root = Path(__file__).resolve().parent
    for width, height in ((1320, 2868), (750, 1334)):
        output = root / f"after_{width}x{height}"
        output.mkdir(parents=True, exist_ok=True)
        for language in ("zh", "en"):
            for route, base_payload in SCREENS:
                payload = dict(base_payload)
                payload.update(
                    {
                        "language": language,
                        "viewport_size": [width, height],
                        "_visual_safe_insets": DEBUG_SAFE_INSETS,
                        "save_override": {"player": {"gold": 0, "star": 0, "xp": 0}},
                    }
                )
                label = f"finish_{width}x{height}_{language}_{route}"
                destination = output / f"{language}_{route}.png"
                code, runtime_issues, runtime_output = capture(route, payload, destination)
                if code != 0:
                    failures.append(f"{label}: capture exit {code}: {runtime_output[-400:]}")
                    continue
                failures.extend(f"{label}: {issue}" for issue in runtime_issues)
                failures.extend(analyze(destination, label, (width, height)))
                print(f"captured {label}", flush=True)

    zero_output = root / "after_1080x1920_zero_resources"
    zero_output.mkdir(parents=True, exist_ok=True)
    for language in ("zh", "en"):
        for route, base_payload in SCREENS[1:4]:
            payload = dict(base_payload)
            payload.update(
                {
                    "language": language,
                    "save_override": {"player": {"gold": 0, "star": 0, "xp": 0}},
                }
            )
            label = f"finish_zero_{language}_{route}"
            destination = zero_output / f"{language}_{route}.png"
            code, runtime_issues, runtime_output = capture(route, payload, destination)
            if code != 0:
                failures.append(f"{label}: capture exit {code}: {runtime_output[-400:]}")
                continue
            failures.extend(f"{label}: {issue}" for issue in runtime_issues)
            failures.extend(analyze(destination, label, (1080, 1920)))
            print(f"captured {label}", flush=True)

    if failures:
        print("UI finish matrix failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1
    print("UI finish matrix OK: 26 screenshots")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
