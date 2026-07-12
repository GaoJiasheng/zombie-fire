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
TALL_SCREEN_LABEL_PREFIXES = ("battle_tall", "result_tall", "pause_tall", "card_offer_tall")
MIN_LUMA_STDEV = {
    "map": 20.0,
    "map_chapter": 20.0,
    "loadout": 20.0,
    "collection_characters": 18.0,
}

TALL_BATTLE_LEVELS: list[tuple[str, str]] = [
    ("env_lava_foundry", "level_001"),
    ("env_glacier_pass", "level_011"),
    ("env_abandoned_factory", "level_021"),
    ("env_toxic_biolab", "level_031"),
    ("env_storm_substation", "level_041"),
    ("env_flooded_subway", "level_051"),
    ("env_desert_refinery", "level_061"),
    ("env_void_cathedral", "level_071"),
    ("env_orbital_ruins", "level_081"),
    ("env_apex_core", "level_091"),
]

BASE_SCREENS: list[tuple[str, dict, str]] = [
    ("menu", {}, "menu"),
    ("map", {}, "map"),
    ("map", {"chapter": 1}, "map_chapter"),
    ("loadout", {"level_id": "level_003"}, "loadout"),
    ("collection", {"mode": "characters"}, "collection_characters"),
    ("battle", {"level_id": "level_001"}, "battle"),
    (
        "result",
        {"level_id": "level_003", "victory": True, "stars": 2, "gold": 120, "xp": 20, "next_level": "level_004"},
        "result",
    ),
]

SCREENS: list[tuple[str, dict, str]] = (
    BASE_SCREENS[:-1]
    + [
        ("battle", {"level_id": level_id, "viewport_size": [1080, 2340]}, f"battle_tall_{env_id}")
        for env_id, level_id in TALL_BATTLE_LEVELS
    ]
    + [
        (
            "result",
            {
                "level_id": "level_004",
                "victory": True,
                "challenge": True,
                "stars": 3,
                "gold": 686,
                "xp": 458,
                "viewport_size": [1080, 2340],
            },
            "result_tall_challenge",
        ),
        ("battle", {"level_id": "level_075", "pause": True, "viewport_size": [1080, 2340]}, "pause_tall"),
        ("battle", {"level_id": "level_001", "card_offer": True, "viewport_size": [1080, 2340]}, "card_offer_tall"),
    ]
    + BASE_SCREENS[-1:]
)


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
    if label.startswith(TALL_SCREEN_LABEL_PREFIXES):
        if image.size[0] != EXPECTED_SIZE[0] or image.size[1] <= EXPECTED_SIZE[1]:
            errors.append(f"{label} screenshot must exercise a tall viewport wider than 1920px high, got {image.size}")
    elif image.size != EXPECTED_SIZE:
        errors.append(f"{label} screenshot size must be {EXPECTED_SIZE}, got {image.size}")

    pixels = list(image.getdata())
    count = max(1, len(pixels))
    luminance = [(r * 0.2126 + g * 0.7152 + b * 0.0722) for r, g, b in pixels]
    mean = sum(luminance) / count
    variance = sum((value - mean) ** 2 for value in luminance) / count
    stdev = math.sqrt(variance)
    exact_black = sum(1 for r, g, b in pixels if r < 3 and g < 3 and b < 3) / count

    min_stdev = max(5.0, MIN_LUMA_STDEV.get(label, 5.0))
    if mean < 6.0 or stdev < min_stdev:
        errors.append(f"{label} screenshot looks blank or missing UI layers; mean={mean:.1f} stdev={stdev:.1f} min_stdev={min_stdev:.1f}")
    if exact_black > 0.35:
        errors.append(f"{label} screenshot has too much exact black area; black={exact_black:.2%}")
    if label.startswith("battle_tall"):
        top_h = min(320, image.size[1])
        top_pixels = list(image.crop((0, 0, image.size[0], top_h)).getdata())
        top_count = max(1, len(top_pixels))
        top_luma = [(r * 0.2126 + g * 0.7152 + b * 0.0722) for r, g, b in top_pixels]
        top_mean = sum(top_luma) / top_count
        top_variance = sum((value - top_mean) ** 2 for value in top_luma) / top_count
        top_stdev = math.sqrt(top_variance)
        top_dark = sum(1 for value in top_luma if value < 18.0) / top_count
        if top_dark > 0.72 and top_mean < 22.0 and top_stdev < 24.0:
            errors.append(
                f"{label} top band still reads as a dark blank strip; "
                f"mean={top_mean:.1f} stdev={top_stdev:.1f} dark<18={top_dark:.2%}"
            )
        play_band = image.crop((0, min(120, image.size[1] - 1), image.size[0], min(260, image.size[1])))
        play_pixels = list(play_band.getdata())
        play_count = max(1, len(play_pixels))
        play_luma = [(r * 0.2126 + g * 0.7152 + b * 0.0722) for r, g, b in play_pixels]
        play_mean = sum(play_luma) / play_count
        play_variance = sum((value - play_mean) ** 2 for value in play_luma) / play_count
        play_stdev = math.sqrt(play_variance)
        play_dark = sum(1 for value in play_luma if value < 18.0) / play_count
        if play_dark > 0.70 and play_mean < 22.0 and play_stdev < 24.0:
            errors.append(
                f"{label} playable top extension still looks like black filler; "
                f"mean={play_mean:.1f} stdev={play_stdev:.1f} dark<18={play_dark:.2%}"
            )
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
