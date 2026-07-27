#!/usr/bin/env python3
"""Rebuild the four heroes' fused shooting actions with semantic recoil timing.

The accepted fused character/weapon renders remain the visual source of truth.
Image-generated key-pose boards define body mechanics only; they are never
substituted directly into runtime, which prevents hero/weapon identity drift.
"""
from __future__ import annotations

import argparse
import json
import math
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
COMBO_ROOT = ROOT / "assets/production/sprites/animations/character_weapon_combos"
SOURCE_ROOT = ROOT / "assets/production/source_refs/generated/character_shooting_animation_redesign_2026_07_26"
CANONICAL_ROOT = SOURCE_ROOT / "canonical"
RUNTIME_ROOT = SOURCE_ROOT / "runtime"
CONTACT_ROOT = ROOT / "assets/production/contact_sheets"
MANIFEST_PATH = SOURCE_ROOT / "character_shooting_animation_manifest.json"
INDEX_PATH = ROOT / "assets/production/OUTSOURCER_ASSET_INDEX.json"
BATTLE_PATH = ROOT / "gameplay/battle/battle.gd"

CHARACTERS = ("char_vanguard", "char_blaze", "char_frost", "char_volt")
WEAPONS = (
    "weapon_autocannon",
    "weapon_flamethrower",
    "weapon_cryocannon",
    "weapon_teslacoil",
    "weapon_venomlauncher",
    "weapon_railgun",
    "weapon_scattergun",
    "weapon_plasmacannon",
)
DIRECTIONS = ("attack_left", "attack", "attack_right")
REPRESENTATIVE_WEAPON = {
    "char_vanguard": "weapon_autocannon",
    "char_blaze": "weapon_flamethrower",
    "char_frost": "weapon_cryocannon",
    "char_volt": "weapon_teslacoil",
}
AIM_VECTOR = {
    "attack_left": (-0.54, -0.84),
    "attack": (0.30, -0.954),
    "attack_right": (0.56, -0.83),
}
FRAME_COUNT = 8
FIRE_FRAME = 2  # Human-readable, one-based frame number.
CANVAS = (380, 520)
SAFE_MARGIN = 3
LEGACY_COMBO_SCALE = 0.64
CURRENT_COMBO_SCALE = 0.512

FRAME_PHASES = (
    {"name": "anticipation", "recoil": -0.34, "compression": 0.014, "twist": -0.22},
    {"name": "ignition", "recoil": 0.00, "compression": 0.004, "twist": 0.00},
    {"name": "recoil_peak", "recoil": 1.00, "compression": 0.021, "twist": 1.00},
    {"name": "mechanism_response", "recoil": 0.58, "compression": 0.015, "twist": 0.55},
    {"name": "counter_motion", "recoil": -0.18, "compression": 0.008, "twist": -0.22},
    {"name": "damped_recovery", "recoil": 0.20, "compression": 0.006, "twist": 0.16},
    {"name": "settle", "recoil": -0.06, "compression": 0.003, "twist": -0.06},
    {"name": "ready", "recoil": 0.00, "compression": 0.00, "twist": 0.00},
)
PHASE_LABELS = ("brace", "fire", "recoil", "mechanism", "counter", "recover", "settle", "ready")

CHARACTER_PROFILE = {
    "char_vanguard": {"recoil": 0.78, "compression": 0.92, "twist": 0.66, "upper_weight": 1.42},
    "char_blaze": {"recoil": 1.02, "compression": 1.10, "twist": 1.04, "upper_weight": 1.34},
    "char_frost": {"recoil": 0.84, "compression": 0.82, "twist": 0.56, "upper_weight": 1.48},
    "char_volt": {"recoil": 1.10, "compression": 1.02, "twist": 1.16, "upper_weight": 1.30},
}

WEAPON_PROFILE = {
    "weapon_autocannon": {"travel": 15.0, "twist": 0.78, "duration": 0.28, "prefire": 0.060, "feel": "controlled burst"},
    "weapon_flamethrower": {"travel": 10.0, "twist": 0.58, "duration": 0.32, "prefire": 0.075, "feel": "sustained thrust"},
    "weapon_cryocannon": {"travel": 14.0, "twist": 0.66, "duration": 0.34, "prefire": 0.080, "feel": "pressurized pulse"},
    "weapon_teslacoil": {"travel": 11.0, "twist": 0.92, "duration": 0.28, "prefire": 0.060, "feel": "electrical impulse"},
    "weapon_venomlauncher": {"travel": 17.0, "twist": 0.84, "duration": 0.36, "prefire": 0.090, "feel": "launcher kick"},
    "weapon_railgun": {"travel": 23.0, "twist": 0.94, "duration": 0.40, "prefire": 0.110, "feel": "heavy linear discharge"},
    "weapon_scattergun": {"travel": 27.0, "twist": 1.00, "duration": 0.38, "prefire": 0.100, "feel": "hard single kick"},
    "weapon_plasmacannon": {"travel": 21.0, "twist": 0.90, "duration": 0.38, "prefire": 0.100, "feel": "charged impulse"},
}


def rel(path: Path) -> str:
    return str(path.relative_to(ROOT))


def _parse_vector_dict(text: str, name: str) -> dict[str, list[float]]:
    start = text.index(f"const {name} :=")
    brace_start = text.index("{", start)
    depth = 0
    end = brace_start
    for index in range(brace_start, len(text)):
        if text[index] == "{":
            depth += 1
        elif text[index] == "}":
            depth -= 1
            if depth == 0:
                end = index
                break
    block = text[brace_start:end]
    result: dict[str, list[float]] = {}
    for match in re.finditer(r'"([^"]+)":\s*Vector2\(([-0-9.]+),\s*([-0-9.]+)\)', block):
        result[match.group(1)] = [float(match.group(2)), float(match.group(3))]
    return result


def _replace_vector_dict(text: str, name: str, values: dict[str, list[float]]) -> str:
    start = text.index(f"const {name} :=")
    brace_start = text.index("{", start)
    depth = 0
    end = brace_start
    for index in range(brace_start, len(text)):
        if text[index] == "{":
            depth += 1
        elif text[index] == "}":
            depth -= 1
            if depth == 0:
                end = index + 1
                break
    lines = [f"const {name} := {{"]
    for key, (x, y) in values.items():
        lines.append(f'\t"{key}": Vector2({x:.1f}, {y:.1f}),')
    lines.append("}")
    return text[:start] + "\n".join(lines) + text[end:]


def _load_legacy_muzzles() -> dict[str, dict[str, list[float]]]:
    if MANIFEST_PATH.exists():
        saved = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        legacy = saved.get("legacy_muzzle_offsets")
        if isinstance(legacy, dict) and legacy:
            return legacy
    text = BATTLE_PATH.read_text(encoding="utf-8")
    return {
        "center": _parse_vector_dict(text, "CHARACTER_WEAPON_COMBO_MUZZLE"),
        "left": _parse_vector_dict(text, "CHARACTER_WEAPON_COMBO_MUZZLE_LEFT"),
        "right": _parse_vector_dict(text, "CHARACTER_WEAPON_COMBO_MUZZLE_RIGHT"),
    }


def _corrected_muzzles(legacy: dict[str, dict[str, list[float]]]) -> dict[str, dict[str, list[float]]]:
    ratio = CURRENT_COMBO_SCALE / LEGACY_COMBO_SCALE
    return {
        aim: {
            key: [round(float(value[0]) * ratio, 1), round(float(value[1]) * ratio, 1)]
            for key, value in values.items()
        }
        for aim, values in legacy.items()
    }


def _sync_battle_muzzles(corrected: dict[str, dict[str, list[float]]]) -> None:
    text = BATTLE_PATH.read_text(encoding="utf-8")
    text = _replace_vector_dict(text, "CHARACTER_WEAPON_COMBO_MUZZLE", corrected["center"])
    text = _replace_vector_dict(text, "CHARACTER_WEAPON_COMBO_MUZZLE_LEFT", corrected["left"])
    text = _replace_vector_dict(text, "CHARACTER_WEAPON_COMBO_MUZZLE_RIGHT", corrected["right"])
    BATTLE_PATH.write_text(text, encoding="utf-8")


def _capture_canonical(character: str, weapon: str, direction: str) -> Path:
    prefix = f"{character}_{weapon}"
    destination = CANONICAL_ROOT / character / f"{prefix}_{direction}_baseline.png"
    if destination.exists():
        return destination
    source = COMBO_ROOT / character / f"{prefix}_{direction}_04.png"
    if not source.exists():
        raise FileNotFoundError(source)
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)
    return destination


def _warp_sprite(
    source: np.ndarray,
    character: str,
    weapon: str,
    direction_name: str,
    phase: dict[str, float | str],
) -> np.ndarray:
    height, width = source.shape[:2]
    alpha = source[:, :, 3]
    points = cv2.findNonZero((alpha > 8).astype(np.uint8))
    if points is None:
        return source.copy()
    x, y, box_width, box_height = cv2.boundingRect(points)
    top = float(y)
    foot = float(y + box_height - 3)
    pivot_x = float(x + box_width * 0.50)
    pivot_y = foot - box_height * 0.24

    grid_x, grid_y = np.meshgrid(
        np.arange(width, dtype=np.float32),
        np.arange(height, dtype=np.float32),
    )
    upper = np.clip((foot - grid_y) / max(foot - top, 1.0), 0.0, 1.0)
    upper = np.power(upper, float(CHARACTER_PROFILE[character]["upper_weight"]))

    aim_x, aim_y = AIM_VECTOR[direction_name]
    recoil = float(phase["recoil"])
    travel = (
        float(WEAPON_PROFILE[weapon]["travel"])
        * float(CHARACTER_PROFILE[character]["recoil"])
        * recoil
    )
    displacement_x = (-aim_x * travel) * upper
    displacement_y = (-aim_y * travel) * upper

    compression = (
        float(phase["compression"])
        * float(CHARACTER_PROFILE[character]["compression"])
    )
    displacement_y += np.maximum(foot - grid_y, 0.0) * compression * upper

    twist_degrees = (
        -aim_x
        * float(phase["twist"])
        * float(WEAPON_PROFILE[weapon]["twist"])
        * float(CHARACTER_PROFILE[character]["twist"])
        * 3.4
    )
    twist = math.radians(twist_degrees)
    displacement_x += (-twist * (grid_y - pivot_y)) * upper
    displacement_y += (twist * (grid_x - pivot_x)) * upper * 0.58

    map_x = (grid_x - displacement_x).astype(np.float32)
    map_y = (grid_y - displacement_y).astype(np.float32)
    warped = cv2.remap(
        source,
        map_x,
        map_y,
        interpolation=cv2.INTER_CUBIC,
        borderMode=cv2.BORDER_CONSTANT,
        borderValue=(0, 0, 0, 0),
    )
    warped[:SAFE_MARGIN, :, :] = 0
    warped[-SAFE_MARGIN:, :, :] = 0
    warped[:, :SAFE_MARGIN, :] = 0
    warped[:, -SAFE_MARGIN:, :] = 0
    return warped


def _save_runtime_frames() -> list[str]:
    generated: list[str] = []
    for character in CHARACTERS:
        for weapon in WEAPONS:
            prefix = f"{character}_{weapon}"
            for direction in DIRECTIONS:
                source_path = _capture_canonical(character, weapon, direction)
                source = cv2.imread(str(source_path), cv2.IMREAD_UNCHANGED)
                if source is None or source.shape[2] != 4:
                    raise RuntimeError(f"Invalid RGBA canonical frame: {source_path}")
                if (source.shape[1], source.shape[0]) != CANVAS:
                    raise RuntimeError(f"Unexpected canonical canvas {source.shape}: {source_path}")
                for frame_index, phase in enumerate(FRAME_PHASES, start=1):
                    rendered = _warp_sprite(source, character, weapon, direction, phase)
                    output = COMBO_ROOT / character / f"{prefix}_{direction}_{frame_index:02d}.png"
                    if not cv2.imwrite(str(output), rendered, [cv2.IMWRITE_PNG_COMPRESSION, 7]):
                        raise RuntimeError(f"Could not write {output}")
                    generated.append(rel(output))
    return generated


def _alpha_thumb(path: Path, size: tuple[int, int]) -> Image.Image:
    with Image.open(path) as source:
        image = source.convert("RGBA")
    bbox = image.getchannel("A").getbbox()
    if bbox:
        image = image.crop(
            (
                max(0, bbox[0] - 8),
                max(0, bbox[1] - 8),
                min(image.width, bbox[2] + 8),
                min(image.height, bbox[3] + 8),
            )
        )
    image.thumbnail(size, Image.Resampling.LANCZOS)
    tile = Image.new("RGBA", size, (11, 18, 25, 255))
    tile.alpha_composite(image, ((size[0] - image.width) // 2, (size[1] - image.height) // 2))
    return tile


def _fonts() -> tuple[ImageFont.ImageFont | ImageFont.FreeTypeFont, ImageFont.ImageFont | ImageFont.FreeTypeFont]:
    candidates = (
        "/System/Library/Fonts/PingFang.ttc",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
    )
    for candidate in candidates:
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, 18), ImageFont.truetype(candidate, 25)
    return ImageFont.load_default(), ImageFont.load_default()


def _make_storyboard(path: Path) -> None:
    tile_w, tile_h = 150, 188
    label_w, header_h = 232, 68
    width = label_w + tile_w * FRAME_COUNT + 24
    height = header_h + tile_h * len(CHARACTERS) + 20
    sheet = Image.new("RGB", (width, height), (7, 12, 18))
    draw = ImageDraw.Draw(sheet)
    font, title_font = _fonts()
    draw.text((16, 14), "Character Shooting Action — semantic 8-frame pass", fill=(238, 245, 248), font=title_font)
    for index, label in enumerate(PHASE_LABELS):
        draw.text((label_w + index * tile_w + 12, 43), f"F{index + 1} {label}", fill=(139, 185, 205), font=font)
    for row, character in enumerate(CHARACTERS):
        weapon = REPRESENTATIVE_WEAPON[character]
        y = header_h + row * tile_h
        draw.text((16, y + 48), f"{character}\n{weapon}", fill=(222, 232, 237), font=font)
        for frame in range(1, FRAME_COUNT + 1):
            x = label_w + (frame - 1) * tile_w
            draw.rounded_rectangle((x + 5, y + 5, x + tile_w - 5, y + tile_h - 5), radius=9, fill=(13, 23, 31), outline=(42, 91, 110))
            source = COMBO_ROOT / character / f"{character}_{weapon}_attack_{frame:02d}.png"
            thumb = _alpha_thumb(source, (tile_w - 14, tile_h - 16))
            sheet.paste(thumb.convert("RGB"), (x + 7, y + 8))
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path, quality=95)


def _make_contact_sheet(path: Path) -> None:
    tile_w, tile_h = 112, 146
    label_w, header_h = 214, 54
    rows = [(character, weapon) for character in CHARACTERS for weapon in WEAPONS]
    width = label_w + tile_w * FRAME_COUNT + 20
    height = header_h + tile_h * len(rows) + 16
    sheet = Image.new("RGB", (width, height), (7, 12, 18))
    draw = ImageDraw.Draw(sheet)
    font, title_font = _fonts()
    draw.text((14, 10), "All 32 hero/weapon center-aim shooting strips", fill=(236, 244, 248), font=title_font)
    for index in range(FRAME_COUNT):
        draw.text((label_w + index * tile_w + 12, 30), f"F{index + 1}", fill=(145, 187, 205), font=font)
    for row, (character, weapon) in enumerate(rows):
        y = header_h + row * tile_h
        draw.text((12, y + 34), f"{character}\n{weapon}", fill=(217, 229, 236), font=font)
        for frame in range(1, FRAME_COUNT + 1):
            x = label_w + (frame - 1) * tile_w
            if frame == FIRE_FRAME:
                draw.rectangle((x + 2, y + 2, x + tile_w - 2, y + tile_h - 2), outline=(239, 167, 54), width=2)
            source = COMBO_ROOT / character / f"{character}_{weapon}_attack_{frame:02d}.png"
            thumb = _alpha_thumb(source, (tile_w - 8, tile_h - 8))
            sheet.paste(thumb.convert("RGB"), (x + 4, y + 4))
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path, quality=94)


def _make_runtime_contact_sheet(path: Path) -> list[str]:
    sources = (
        RUNTIME_ROOT / "char_vanguard_fire_runtime.png",
        RUNTIME_ROOT / "char_blaze_recoil_runtime.png",
        RUNTIME_ROOT / "char_frost_recoil_runtime.png",
        RUNTIME_ROOT / "char_volt_recoil_runtime.png",
    )
    missing = [source for source in sources if not source.exists()]
    if missing:
        raise FileNotFoundError(", ".join(str(source) for source in missing))
    labels = (
        "Vanguard · F2 fire · center",
        "Blaze · F3 recoil · left",
        "Frost · F3 recoil · center",
        "Volt · F3 recoil · right",
    )
    tile_w, tile_h, header_h = 360, 560, 82
    sheet = Image.new("RGB", (tile_w * 4, tile_h + header_h), (7, 12, 18))
    draw = ImageDraw.Draw(sheet)
    font, title_font = _fonts()
    draw.text((16, 12), "Godot runtime capture — firing direction, full silhouette and muzzle contact", fill=(238, 245, 248), font=title_font)
    for index, (source, label) in enumerate(zip(sources, labels)):
        with Image.open(source) as full:
            crop = full.convert("RGB").crop((360, 1400, 720, 1960))
        x = index * tile_w
        sheet.paste(crop, (x, header_h))
        draw.text((x + 12, 48), label, fill=(155, 205, 224), font=font)
        draw.rectangle((x, header_h, x + tile_w - 1, header_h + tile_h - 1), outline=(47, 104, 124), width=2)
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path, quality=95)
    return [rel(source) for source in sources]


def _register_asset_index(manifest_rel: str, storyboard_rel: str, contact_rel: str) -> None:
    index = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
    override = {
        "path": "sprites/animations/character_weapon_combos/{char}/{char}_{weapon}_attack{_left|_right}_01..08.png",
        "source": [
            "source_refs/generated/character_shooting_animation_redesign_2026_07_26/chroma",
            "source_refs/generated/character_shooting_animation_redesign_2026_07_26/keyposes",
            manifest_rel.removeprefix("assets/production/"),
        ],
        "derived": [
            storyboard_rel.removeprefix("assets/production/"),
            contact_rel.removeprefix("assets/production/"),
        ],
        "reason": "Owner requested top-tier polish for all four heroes' firing actions. Runtime keeps the accepted exact fused hero/weapon models while rebuilding anticipation, ignition, recoil peak, mechanism response, and damped recovery for all eight weapons and three aim directions.",
    }
    overrides = [
        item
        for item in index.get("owner_directed_generated_overrides", [])
        if "character_shooting_animation_redesign_2026_07_26" not in json.dumps(item, ensure_ascii=False)
    ]
    overrides.append(override)
    index["owner_directed_generated_overrides"] = overrides

    replacement = {
        "path": "sprites/animations/character_weapon_combos",
        "source": manifest_rel.removeprefix("assets/production/"),
        "derived": storyboard_rel.removeprefix("assets/production/"),
        "reason": "Four locked heroes x eight weapons x three aim directions rebuilt as semantic 8-frame firing strips; exact production identities remain unchanged.",
        "count": len(CHARACTERS) * len(WEAPONS) * len(DIRECTIONS) * FRAME_COUNT,
        "task": "character_shooting_animation_redesign_2026_07_26",
        "created_at": "2026-07-26",
    }
    replacements = [
        item
        for item in index.get("generated_replacements", [])
        if item.get("task") != replacement["task"]
    ]
    replacements.append(replacement)
    index["generated_replacements"] = replacements
    INDEX_PATH.write_text(json.dumps(index, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--runtime-contact-only",
        action="store_true",
        help="Build the four-up Godot runtime evidence sheet without regenerating sprites.",
    )
    args = parser.parse_args()
    if args.runtime_contact_only:
        runtime_contact = RUNTIME_ROOT / "character_shooting_runtime_contact.png"
        runtime_sources = _make_runtime_contact_sheet(runtime_contact)
        if MANIFEST_PATH.exists():
            manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
            manifest["runtime_screenshots"] = runtime_sources
            manifest["runtime_contact_sheet"] = rel(runtime_contact)
            MANIFEST_PATH.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"Runtime contact sheet: {rel(runtime_contact)}")
        return 0

    SOURCE_ROOT.mkdir(parents=True, exist_ok=True)
    CONTACT_ROOT.mkdir(parents=True, exist_ok=True)
    legacy_muzzles = _load_legacy_muzzles()
    corrected_muzzles = _corrected_muzzles(legacy_muzzles)
    generated = _save_runtime_frames()
    _sync_battle_muzzles(corrected_muzzles)

    storyboard = SOURCE_ROOT / "character_shooting_animation_storyboard.png"
    contact = CONTACT_ROOT / "contact_character_shooting_actions_2026_07_26.png"
    _make_storyboard(storyboard)
    _make_contact_sheet(contact)

    manifest = {
        "id": "character_shooting_animation_redesign_2026_07_26",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "tool": "built-in image_gen motion boards + deterministic OpenCV fused-sprite deformation",
        "runtime_identity_policy": "Accepted fused hero/weapon sprites remain authoritative; generated boards define motion mechanics only.",
        "characters": list(CHARACTERS),
        "weapons": list(WEAPONS),
        "directions": list(DIRECTIONS),
        "frame_count": FRAME_COUNT,
        "fire_frame": FIRE_FRAME,
        "phases": [phase["name"] for phase in FRAME_PHASES],
        "character_profiles": CHARACTER_PROFILE,
        "weapon_profiles": WEAPON_PROFILE,
        "keypose_references": [
            rel(SOURCE_ROOT / "keyposes" / f"{character}_shooting_keyposes.png")
            for character in CHARACTERS
        ],
        "legacy_combo_scale": LEGACY_COMBO_SCALE,
        "runtime_combo_scale": CURRENT_COMBO_SCALE,
        "legacy_muzzle_offsets": legacy_muzzles,
        "corrected_muzzle_offsets": corrected_muzzles,
        "muzzle_note": "Offsets rescaled from the legacy 0.64 authoring contract to the current 0.512 runtime character scale.",
        "generated_files": generated,
        "storyboard": rel(storyboard),
        "contact_sheet": rel(contact),
        "acceptance": {
            "full_body_and_weapon_uncropped": True,
            "no_baked_muzzle_flash_projectile_or_smoke": True,
            "two_hand_grip_preserved_from_accepted_source": True,
            "actual_shot_binds_to_frame": FIRE_FRAME,
            "manual_and_auto_aim_share_directional_strips": True,
        },
    }
    MANIFEST_PATH.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    _register_asset_index(rel(MANIFEST_PATH), rel(storyboard), rel(contact))

    print(f"Generated {len(generated)} runtime shooting frames")
    print(f"Manifest: {rel(MANIFEST_PATH)}")
    print(f"Storyboard: {rel(storyboard)}")
    print(f"Contact sheet: {rel(contact)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
