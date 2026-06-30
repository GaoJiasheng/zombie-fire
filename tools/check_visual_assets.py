#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]

SPRITE_DIRS = [
    ROOT / "assets/production/sprites/animations/characters",
    ROOT / "assets/production/sprites/animations/character_weapon_combos",
    ROOT / "assets/production/sprites/weapons/handheld",
]

# These thresholds are intentionally lenient enough for stylized element glows,
# but strict enough to catch the old green-screen fringe / baked square backing
# failures that made battle sprites look like raw cutouts.
MAX_GREEN_EDGE_RATIO = 0.32
MAX_ALPHA_FILL_RATIO = 0.72
MAX_BORDER_ALPHA_RATIO = 0.02
MIN_SUBJECT_MARGIN = 2
COMBO_FRAME_COUNTS = {"idle": 4, "attack_left": 4, "attack": 4, "attack_right": 4, "hurt": 3}
MIN_ATTACK_POSE_CHANGED_PIXELS = 900
CHARACTER_ASSET_IDS = {
    "vanguard": "char_vanguard",
    "blaze": "char_blaze",
    "frost": "char_frost",
    "volt": "char_volt",
}


def is_green_key_pixel(r: int, g: int, b: int, a: int) -> bool:
    if a <= 24:
        return False
    return g > 150 and r < 110 and b < 130 and g > max(r, b) * 1.45


def analyze_image(path: Path) -> list[str]:
    errors: list[str] = []
    with Image.open(path) as source:
        image = source.convert("RGBA")
    width, height = image.size
    pixels = image.load()
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    rel = path.relative_to(ROOT)
    if bbox is None:
        return [f"{rel} has no visible pixels"]

    left, top, right, bottom = bbox
    min_margin = min(left, top, width - right, height - bottom)
    if min_margin < MIN_SUBJECT_MARGIN:
        errors.append(f"{rel} subject touches canvas edge; margin={min_margin}px")

    opaque = 0
    edge = 0
    green_edge = 0
    border_opaque = 0
    border_count = width * 2 + max(0, height - 2) * 2
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if (x == 0 or y == 0 or x == width - 1 or y == height - 1) and a > 24:
                border_opaque += 1
            if a <= 24:
                continue
            opaque += 1
            edge_pixel = False
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if nx < 0 or nx >= width or ny < 0 or ny >= height or pixels[nx, ny][3] <= 24:
                    edge_pixel = True
                    break
            if not edge_pixel:
                continue
            edge += 1
            if is_green_key_pixel(r, g, b, a):
                green_edge += 1

    bbox_area = max(1, (right - left) * (bottom - top))
    alpha_fill_ratio = opaque / bbox_area
    if alpha_fill_ratio > MAX_ALPHA_FILL_RATIO:
        errors.append(f"{rel} looks like a baked rectangular plate; alpha_fill={alpha_fill_ratio:.2f}")

    if border_count > 0:
        border_ratio = border_opaque / border_count
        if border_ratio > MAX_BORDER_ALPHA_RATIO:
            errors.append(f"{rel} has visible pixels on image border; border_alpha={border_ratio:.2f}")

    if edge > 0:
        green_edge_ratio = green_edge / edge
        if green_edge_ratio > MAX_GREEN_EDGE_RATIO:
            errors.append(f"{rel} has likely chroma-key fringe; green_edge={green_edge_ratio:.2f}")

    return errors


def check_combo_coverage() -> list[str]:
    errors: list[str] = []
    characters = json.loads((ROOT / "data/characters.json").read_text(encoding="utf-8"))
    weapons = json.loads((ROOT / "data/weapons.json").read_text(encoding="utf-8"))
    combo_root = ROOT / "assets/production/sprites/animations/character_weapon_combos"
    for character_id in sorted(characters.keys()):
        asset_id = CHARACTER_ASSET_IDS.get(character_id, f"char_{character_id}")
        for weapon_id in sorted(weapons.keys()):
            for action, count in COMBO_FRAME_COUNTS.items():
                for index in range(1, count + 1):
                    path = combo_root / asset_id / f"{asset_id}_{weapon_id}_{action}_{index:02d}.png"
                    if not path.exists():
                        errors.append(f"missing fused character/weapon frame: {path.relative_to(ROOT)}")
            idle_path = combo_root / asset_id / f"{asset_id}_{weapon_id}_idle_01.png"
            attack_path = combo_root / asset_id / f"{asset_id}_{weapon_id}_attack_01.png"
            if idle_path.exists() and attack_path.exists():
                with Image.open(idle_path) as idle_source, Image.open(attack_path) as attack_source:
                    idle = idle_source.convert("RGBA")
                    attack = attack_source.convert("RGBA")
                diff = ImageChops.difference(idle, attack)
                changed = sum(1 for pixel in diff.getdata() if max(pixel) > 24)
                if changed < MIN_ATTACK_POSE_CHANGED_PIXELS:
                    errors.append(
                        "fused attack pose is too close to idle for "
                        f"{asset_id}/{weapon_id}; changed_pixels={changed}"
                    )
    manifest = ROOT / "assets/production/source_refs/generated/character_weapon_combo_generation_manifest.json"
    matrix = ROOT / "assets/production/source_refs/generated/character_weapon_combo_matrix.png"
    if not manifest.exists():
        errors.append(f"missing character/weapon combo generation manifest: {manifest.relative_to(ROOT)}")
    if not matrix.exists():
        errors.append(f"missing character/weapon combo visual matrix: {matrix.relative_to(ROOT)}")
    return errors


def main() -> int:
    errors: list[str] = []
    checked = 0
    for directory in SPRITE_DIRS:
        if not directory.exists():
            errors.append(f"missing visual asset directory: {directory.relative_to(ROOT)}")
            continue
        for path in sorted(directory.rglob("*.png")):
            checked += 1
            errors.extend(analyze_image(path))

    for source_ref in ["hero_battle_pose_sheet.png", "handheld_weapon_sheet.png"]:
        path = ROOT / "assets/production/source_refs" / source_ref
        if not path.exists():
            errors.append(f"missing battle visual source reference: {path.relative_to(ROOT)}")
    errors.extend(check_combo_coverage())

    if errors:
        print("Visual asset check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(f"Visual asset check OK: {checked} battle sprite files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
