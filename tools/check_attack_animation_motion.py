#!/usr/bin/env python3
"""Validate temporal motion in every rendered character/weapon attack strip."""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]
COMBO_ROOT = ROOT / "assets" / "production" / "sprites" / "animations" / "character_weapon_combos"
ACTIONS = ("attack", "attack_left", "attack_right")
FRAME_COUNT = 7
PIXEL_THRESHOLD = 18
MIN_ADJACENT_CHANGED_PIXELS = 10_000
MIN_PEAK_CHANGED_PIXELS = 24_000


def changed_pixels(left: Image.Image, right: Image.Image) -> int:
    difference = ImageChops.difference(left, right)
    return sum(1 for pixel in difference.getdata() if max(pixel) > PIXEL_THRESHOLD)


def main() -> int:
    characters = json.loads((ROOT / "data" / "characters.json").read_text(encoding="utf-8"))
    weapons = json.loads((ROOT / "data" / "weapons.json").read_text(encoding="utf-8"))
    errors: list[str] = []
    checked = 0
    weakest_motion: tuple[int, str] | None = None

    for character_id in sorted(characters):
        asset_id = f"char_{character_id}"
        directory = COMBO_ROOT / asset_id
        for weapon_id in sorted(weapons):
            for action in ACTIONS:
                paths = [
                    directory / f"{asset_id}_{weapon_id}_{action}_{index:02d}.png"
                    for index in range(1, FRAME_COUNT + 1)
                ]
                if any(not path.exists() for path in paths):
                    missing = [str(path.relative_to(ROOT)) for path in paths if not path.exists()]
                    errors.append(f"missing attack strip frames: {', '.join(missing)}")
                    continue
                frames: list[Image.Image] = []
                for path in paths:
                    with Image.open(path) as source:
                        frames.append(source.convert("RGBA"))
                adjacent = [changed_pixels(left, right) for left, right in zip(frames, frames[1:])]
                sequence_name = f"{asset_id}/{weapon_id}/{action}"
                minimum = min(adjacent)
                peak = max(adjacent)
                if weakest_motion is None or minimum < weakest_motion[0]:
                    weakest_motion = (minimum, sequence_name)
                if minimum < MIN_ADJACENT_CHANGED_PIXELS:
                    errors.append(f"{sequence_name} has a near-static adjacent frame: {minimum} changed pixels")
                if peak < MIN_PEAK_CHANGED_PIXELS:
                    errors.append(f"{sequence_name} lacks a readable recoil peak: {peak} changed pixels")
                checked += 1

    if errors:
        print("Attack animation motion check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    weakest_text = "none" if weakest_motion is None else f"{weakest_motion[1]} ({weakest_motion[0]} px)"
    print(f"Attack animation motion OK: {checked} sequences; weakest adjacent motion {weakest_text}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
