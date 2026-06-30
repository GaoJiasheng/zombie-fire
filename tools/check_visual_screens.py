#!/usr/bin/env python3
from __future__ import annotations

import json
import math
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
EXPECTED_SIZE = (1080, 1920)

SCREENS: list[tuple[str, dict, str]] = [
    ("menu", {}, "menu"),
    ("map", {}, "map"),
    ("loadout", {"level_id": "level_003"}, "loadout"),
    ("collection", {"mode": "characters"}, "collection_characters"),
    ("battle", {"level_id": "level_001"}, "battle"),
    (
        "result",
        {"level_id": "level_003", "victory": True, "stars": 2, "gold": 120, "xp": 20, "next_level": "level_004"},
        "result",
    ),
]


def capture(route: str, payload: dict, out_path: Path) -> int:
    command = [
        "godot",
        "--path",
        ".",
        "--script",
        "res://tools/_shot.gd",
        "--",
        route,
        json.dumps(payload, ensure_ascii=False),
        str(out_path),
    ]
    try:
        result = subprocess.run(command, cwd=ROOT, timeout=25)
    except subprocess.TimeoutExpired:
        return 124
    return result.returncode


def analyze(path: Path, label: str) -> list[str]:
    errors: list[str] = []
    if not path.exists():
        return [f"{label} screenshot was not written"]
    with Image.open(path) as source:
        image = source.convert("RGB")
    if image.size != EXPECTED_SIZE:
        errors.append(f"{label} screenshot size must be {EXPECTED_SIZE}, got {image.size}")

    pixels = list(image.getdata())
    count = max(1, len(pixels))
    luminance = [(r * 0.2126 + g * 0.7152 + b * 0.0722) for r, g, b in pixels]
    mean = sum(luminance) / count
    variance = sum((value - mean) ** 2 for value in luminance) / count
    stdev = math.sqrt(variance)
    exact_black = sum(1 for r, g, b in pixels if r < 3 and g < 3 and b < 3) / count

    if mean < 6.0 or stdev < 5.0:
        errors.append(f"{label} screenshot looks blank; mean={mean:.1f} stdev={stdev:.1f}")
    if exact_black > 0.35:
        errors.append(f"{label} screenshot has too much exact black area; black={exact_black:.2%}")
    return errors


def main() -> int:
    errors: list[str] = []
    with tempfile.TemporaryDirectory(prefix="zombie_fire_screens_") as tmp:
        tmp_dir = Path(tmp)
        for route, payload, label in SCREENS:
            out_path = tmp_dir / f"{label}.png"
            code = capture(route, payload, out_path)
            if code != 0:
                errors.append(f"{label} capture failed with exit code {code}")
                continue
            errors.extend(analyze(out_path, label))

    if errors:
        print("Visual screen check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(f"Visual screen check OK: {len(SCREENS)} routed screenshots")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
