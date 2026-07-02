#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import math
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
COMBO_ROOT = ROOT / "assets/production/sprites/animations/character_weapon_combos"
SOURCE_DIR = ROOT / "assets/production/source_refs/generated"
CONTACT_DIR = ROOT / "assets/production/contact_sheets"
INDEX_PATH = ROOT / "assets/production/OUTSOURCER_ASSET_INDEX.json"
BATTLE_PATH = ROOT / "gameplay/battle/battle.gd"

STAMP = "2026_07_02"
FRAME_COUNT = 7
SPRITE_SCALE = 0.64
SAFE_CANVAS_MARGIN = 3

WEAPON_PROFILE = {
    "weapon_autocannon": {
        "element": "physical",
        "color": (255, 186, 64),
        "core": (255, 248, 194),
        "recoil": 18.0,
        "flash": 1.05,
        "trail": 0.85,
    },
    "weapon_flamethrower": {
        "element": "fire",
        "color": (255, 92, 28),
        "core": (255, 236, 140),
        "recoil": 14.0,
        "flash": 1.35,
        "trail": 1.25,
    },
    "weapon_cryocannon": {
        "element": "ice",
        "color": (112, 222, 255),
        "core": (232, 252, 255),
        "recoil": 16.0,
        "flash": 1.0,
        "trail": 1.0,
    },
    "weapon_teslacoil": {
        "element": "lightning",
        "color": (255, 222, 62),
        "core": (255, 255, 210),
        "recoil": 13.0,
        "flash": 1.15,
        "trail": 1.15,
    },
    "weapon_venomlauncher": {
        "element": "poison",
        "color": (124, 255, 54),
        "core": (230, 255, 142),
        "recoil": 17.0,
        "flash": 1.05,
        "trail": 1.2,
    },
    "weapon_railgun": {
        "element": "rail",
        "color": (96, 214, 255),
        "core": (238, 252, 255),
        "recoil": 23.0,
        "flash": 1.42,
        "trail": 1.45,
    },
    "weapon_scattergun": {
        "element": "physical",
        "color": (255, 164, 58),
        "core": (255, 246, 182),
        "recoil": 26.0,
        "flash": 1.28,
        "trail": 1.0,
    },
    "weapon_plasmacannon": {
        "element": "plasma",
        "color": (190, 92, 255),
        "core": (255, 208, 118),
        "recoil": 22.0,
        "flash": 1.35,
        "trail": 1.35,
    },
}

CHAR_PROFILE = {
    "char_vanguard": {"mass": 1.18, "lean": 0.75, "stance": 1.2},
    "char_blaze": {"mass": 0.96, "lean": 1.18, "stance": 1.05},
    "char_frost": {"mass": 0.88, "lean": 0.92, "stance": 0.92},
    "char_volt": {"mass": 0.78, "lean": 1.26, "stance": 0.86},
}

AIM_DIR = {
    "attack_left": (-0.52, -0.86),
    "attack": (0.0, -1.0),
    "attack_right": (0.52, -0.86),
}

KEYFRAMES = [
    {"name": "ready", "phase": 0.00, "recoil": -0.18, "flash": 0.00, "vent": 0.00, "scale": 1.000},
    {"name": "ignition", "phase": 0.16, "recoil": -0.28, "flash": 1.00, "vent": 0.18, "scale": 1.012},
    {"name": "max_recoil", "phase": 0.34, "recoil": 1.00, "flash": 0.72, "vent": 0.56, "scale": 1.020},
    {"name": "vent", "phase": 0.52, "recoil": 0.54, "flash": 0.34, "vent": 1.00, "scale": 1.008},
    {"name": "settle", "phase": 0.68, "recoil": -0.10, "flash": 0.12, "vent": 0.58, "scale": 0.998},
    {"name": "recover", "phase": 0.84, "recoil": 0.10, "flash": 0.04, "vent": 0.26, "scale": 1.000},
    {"name": "return", "phase": 1.00, "recoil": 0.00, "flash": 0.00, "vent": 0.00, "scale": 1.000},
]


def _load_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def _alpha_bbox(img: Image.Image) -> tuple[int, int, int, int] | None:
    return img.getchannel("A").getbbox()


def _apply_safe_canvas_margin(img: Image.Image, margin: int = SAFE_CANVAS_MARGIN) -> Image.Image:
    if margin <= 0:
        return img
    result = img.copy()
    alpha = result.getchannel("A")
    draw = ImageDraw.Draw(alpha)
    draw.rectangle((0, 0, result.width - 1, margin - 1), fill=0)
    draw.rectangle((0, result.height - margin, result.width - 1, result.height - 1), fill=0)
    draw.rectangle((0, 0, margin - 1, result.height - 1), fill=0)
    draw.rectangle((result.width - margin, 0, result.width - 1, result.height - 1), fill=0)
    result.putalpha(alpha)
    return result


def _parse_muzzle_dict(name: str) -> dict[str, tuple[float, float]]:
    text = BATTLE_PATH.read_text()
    start = text.index(f"const {name} :=")
    brace_start = text.index("{", start)
    depth = 0
    end = brace_start
    for i in range(brace_start, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                end = i
                break
    block = text[brace_start:end]
    result: dict[str, tuple[float, float]] = {}
    for match in re.finditer(r'"([^"]+)":\s*Vector2\(([-0-9.]+),\s*([-0-9.]+)\)', block):
        result[match.group(1)] = (float(match.group(2)), float(match.group(3)))
    return result


def _combo_entries() -> list[tuple[str, str, str]]:
    entries: list[tuple[str, str, str]] = []
    for char_dir in sorted(p for p in COMBO_ROOT.iterdir() if p.is_dir()):
        char = char_dir.name
        for idle_path in sorted(char_dir.glob(f"{char}_weapon_*_idle_01.png")):
            prefix = idle_path.stem.removesuffix("_idle_01")
            weapon = prefix.removeprefix(f"{char}_")
            entries.append((char, weapon, prefix))
    return entries


def _direction_name(anim: str) -> str:
    if anim == "attack_left":
        return "left"
    if anim == "attack_right":
        return "right"
    return "center"


def _muzzle_pixel(
    char: str,
    weapon: str,
    anim: str,
    size: tuple[int, int],
    muzzle_maps: dict[str, dict[str, tuple[float, float]]],
) -> tuple[float, float]:
    key = f"{char}/{weapon}"
    map_name = {
        "attack_left": "left",
        "attack_right": "right",
        "attack": "center",
    }[anim]
    pos = muzzle_maps.get(map_name, {}).get(key)
    if pos is None:
        if anim == "attack_left":
            return (size[0] * 0.38, size[1] * 0.18)
        if anim == "attack_right":
            return (size[0] * 0.78, size[1] * 0.18)
        return (size[0] * 0.58, size[1] * 0.18)
    return (size[0] * 0.5 + pos[0] / SPRITE_SCALE, size[1] * 0.5 + pos[1] / SPRITE_SCALE)


def _transform_character(
    img: Image.Image,
    direction: tuple[float, float],
    recoil: float,
    weapon: str,
    char: str,
    scale: float,
) -> Image.Image:
    profile = WEAPON_PROFILE[weapon]
    char_profile = CHAR_PROFILE[char]
    recoil_px = float(profile["recoil"]) * float(char_profile["mass"]) * recoil
    lean = float(char_profile["lean"])
    # Recoil moves opposite to muzzle direction. Negative recoil is anticipation.
    dx = -direction[0] * recoil_px
    dy = -direction[1] * recoil_px * 0.78
    angle = -direction[0] * recoil * (3.8 + float(profile["recoil"]) * 0.05) * lean
    if char == "char_frost":
        angle *= 0.72
    if char == "char_volt":
        angle *= 1.15
    center = (img.width * 0.50, img.height * 0.60)
    transformed = img.rotate(
        angle,
        resample=Image.Resampling.BICUBIC,
        center=center,
        translate=(dx, dy),
        fillcolor=(0, 0, 0, 0),
    )
    if abs(scale - 1.0) > 0.001:
        scaled = Image.new("RGBA", img.size, (0, 0, 0, 0))
        w = max(1, int(round(img.width * scale)))
        h = max(1, int(round(img.height * scale)))
        tmp = transformed.resize((w, h), Image.Resampling.BICUBIC)
        scaled.alpha_composite(tmp, ((img.width - w) // 2, int((img.height - h) * 0.58)))
        transformed = scaled
    return transformed


def _line(draw: ImageDraw.ImageDraw, points: list[tuple[float, float]], fill: tuple[int, int, int, int], width: int = 2) -> None:
    draw.line([(round(x), round(y)) for x, y in points], fill=fill, width=width)


def _add_motion_streaks(
    layer: Image.Image,
    muzzle: tuple[float, float],
    direction: tuple[float, float],
    color: tuple[int, int, int],
    amount: float,
    weapon: str,
) -> None:
    if amount <= 0.0:
        return
    draw = ImageDraw.Draw(layer, "RGBA")
    mx, my = muzzle
    back = (-direction[0], -direction[1])
    side = (-direction[1], direction[0])
    length = (48.0 + 38.0 * amount) * float(WEAPON_PROFILE[weapon]["trail"])
    for i in range(6):
        spread = (i - 2.5) * (5.0 + 7.0 * amount)
        start = (mx + side[0] * spread - direction[0] * 8.0, my + side[1] * spread - direction[1] * 8.0)
        end = (start[0] + back[0] * length * (0.56 + 0.08 * i), start[1] + back[1] * length * (0.56 + 0.08 * i))
        alpha = int(72 * amount * (1.0 - i * 0.08))
        _line(draw, [start, end], (color[0], color[1], color[2], max(0, alpha)), 2 if i < 3 else 1)


def _add_muzzle_flash(
    layer: Image.Image,
    muzzle: tuple[float, float],
    direction: tuple[float, float],
    weapon: str,
    amount: float,
) -> None:
    if amount <= 0.0:
        return
    profile = WEAPON_PROFILE[weapon]
    color = tuple(profile["color"])  # type: ignore[arg-type]
    core = tuple(profile["core"])  # type: ignore[arg-type]
    scale = amount * float(profile["flash"])
    draw = ImageDraw.Draw(layer, "RGBA")
    mx, my = muzzle
    side = (-direction[1], direction[0])
    length = 72.0 * scale
    width = 26.0 * scale
    tip = (mx + direction[0] * length, my + direction[1] * length)
    left = (mx + side[0] * width, my + side[1] * width)
    right = (mx - side[0] * width, my - side[1] * width)
    draw.polygon([left, tip, right], fill=(color[0], color[1], color[2], int(150 * amount)))
    draw.polygon([
        (mx + side[0] * width * 0.45, my + side[1] * width * 0.45),
        (mx + direction[0] * length * 0.58, my + direction[1] * length * 0.58),
        (mx - side[0] * width * 0.45, my - side[1] * width * 0.45),
    ], fill=(core[0], core[1], core[2], int(190 * amount)))
    radius = 22.0 * scale
    for r_mult, alpha in [(2.4, 42), (1.45, 72), (0.72, 170)]:
        r = radius * r_mult
        draw.ellipse((mx - r, my - r, mx + r, my + r), fill=(color[0], color[1], color[2], int(alpha * amount)))
    if weapon == "weapon_railgun":
        rail_len = 118.0 * scale
        for offset in [-7, 0, 7]:
            start = (mx + side[0] * offset, my + side[1] * offset)
            end = (mx + direction[0] * rail_len + side[0] * offset * 0.35, my + direction[1] * rail_len + side[1] * offset * 0.35)
            _line(draw, [start, end], (core[0], core[1], core[2], int(180 * amount)), 3 if offset == 0 else 1)
    elif weapon == "weapon_teslacoil":
        for i in range(4):
            offset = (i - 1.5) * 14.0
            zig = [
                (mx + side[0] * offset, my + side[1] * offset),
                (mx + direction[0] * 28.0 + side[0] * (offset + (-1) ** i * 18.0), my + direction[1] * 28.0 + side[1] * (offset + (-1) ** i * 18.0)),
                (mx + direction[0] * 62.0 + side[0] * (offset - (-1) ** i * 11.0), my + direction[1] * 62.0 + side[1] * (offset - (-1) ** i * 11.0)),
            ]
            _line(draw, zig, (core[0], core[1], core[2], int(130 * amount)), 2)
    elif weapon == "weapon_scattergun":
        for i in range(7):
            spread = (i - 3) * 0.09
            dx = direction[0] + side[0] * spread
            dy = direction[1] + side[1] * spread
            _line(draw, [(mx, my), (mx + dx * length * 0.75, my + dy * length * 0.75)], (core[0], core[1], core[2], int(130 * amount)), 2)


def _add_venting(
    layer: Image.Image,
    muzzle: tuple[float, float],
    direction: tuple[float, float],
    weapon: str,
    amount: float,
) -> None:
    if amount <= 0.0:
        return
    profile = WEAPON_PROFILE[weapon]
    color = tuple(profile["color"])  # type: ignore[arg-type]
    draw = ImageDraw.Draw(layer, "RGBA")
    mx, my = muzzle
    side = (-direction[1], direction[0])
    back = (-direction[0], -direction[1])
    for i in range(11):
        t = (i + 1) / 11.0
        spread = math.sin(i * 1.7) * 26.0 * amount
        dist = (20.0 + 62.0 * t) * amount
        x = mx + back[0] * dist + side[0] * spread
        y = my + back[1] * dist + side[1] * spread
        r = 3.0 + 9.0 * amount * (1.0 - t)
        alpha = int((58 + 80 * (1.0 - t)) * amount)
        if weapon == "weapon_cryocannon":
            fill = (164, 238, 255, alpha)
        elif weapon == "weapon_venomlauncher":
            fill = (120, 255, 70, alpha)
        else:
            fill = (color[0], color[1], color[2], alpha)
        draw.ellipse((x - r, y - r, x + r, y + r), fill=fill)


def _add_ground_pulse(img: Image.Image, bbox: tuple[int, int, int, int] | None, color: tuple[int, int, int], amount: float) -> None:
    if bbox is None or amount <= 0.0:
        return
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer, "RGBA")
    cx = (bbox[0] + bbox[2]) * 0.5
    cy = bbox[3] - 10
    rx = (bbox[2] - bbox[0]) * (0.36 + 0.08 * amount)
    ry = 15 + 12 * amount
    draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=(color[0], color[1], color[2], int(30 * amount)))
    img.alpha_composite(layer)


def _grade_frame(img: Image.Image, element_color: tuple[int, int, int], intensity: float) -> Image.Image:
    alpha = img.getchannel("A")
    rgb = Image.new("RGBA", img.size, (0, 0, 0, 0))
    base = ImageEnhance.Contrast(img).enhance(1.05 + intensity * 0.05)
    base = ImageEnhance.Sharpness(base).enhance(1.05)
    glow = alpha.filter(ImageFilter.GaussianBlur(3.0 + intensity * 2.2))
    glow_rgba = Image.new("RGBA", img.size, (element_color[0], element_color[1], element_color[2], int(58 * intensity)))
    glow_rgba.putalpha(glow.point(lambda v: int(v * 0.30 * intensity)))
    rgb.alpha_composite(glow_rgba)
    rgb.alpha_composite(base)
    return rgb


def _render_action_frame(
    src: Image.Image,
    char: str,
    weapon: str,
    anim: str,
    frame_idx: int,
    muzzle_maps: dict[str, dict[str, tuple[float, float]]],
) -> Image.Image:
    key = KEYFRAMES[frame_idx]
    direction = AIM_DIR[anim]
    profile = WEAPON_PROFILE[weapon]
    color = tuple(profile["color"])  # type: ignore[arg-type]
    amount = float(key["flash"])
    vent = float(key["vent"])
    transformed = _transform_character(src, direction, float(key["recoil"]), weapon, char, float(key["scale"]))
    result = _grade_frame(transformed, color, 0.15 + 0.45 * max(amount, vent))
    muzzle = _muzzle_pixel(char, weapon, anim, src.size, muzzle_maps)
    # Approximate post-transform muzzle movement; enough to keep flash glued to the barrel.
    recoil_px = float(profile["recoil"]) * float(CHAR_PROFILE[char]["mass"]) * float(key["recoil"])
    muzzle = (
        muzzle[0] - direction[0] * recoil_px,
        muzzle[1] - direction[1] * recoil_px * 0.78,
    )
    fx = Image.new("RGBA", src.size, (0, 0, 0, 0))
    _add_motion_streaks(fx, muzzle, direction, color, max(amount, vent * 0.7), weapon)
    _add_muzzle_flash(fx, muzzle, direction, weapon, amount)
    _add_venting(fx, muzzle, direction, weapon, vent)
    if max(amount, vent) > 0.01:
        fx = fx.filter(ImageFilter.GaussianBlur(0.25))
    result.alpha_composite(fx)
    _add_ground_pulse(result, _alpha_bbox(transformed), color, max(amount, vent) * 0.7)
    return _apply_safe_canvas_margin(result)


def _fit_thumb(img: Image.Image, size: tuple[int, int]) -> Image.Image:
    bbox = _alpha_bbox(img)
    if bbox:
        img = img.crop((max(0, bbox[0] - 8), max(0, bbox[1] - 8), min(img.width, bbox[2] + 8), min(img.height, bbox[3] + 8)))
    thumb = Image.new("RGBA", size, (0, 0, 0, 0))
    tmp = img.copy()
    tmp.thumbnail(size, Image.Resampling.LANCZOS)
    thumb.alpha_composite(tmp, ((size[0] - tmp.width) // 2, (size[1] - tmp.height) // 2))
    return thumb


def _make_contact_sheet(entries: list[tuple[str, str, str]], path: Path) -> None:
    selected_weapons = ["weapon_autocannon", "weapon_scattergun", "weapon_railgun", "weapon_plasmacannon"]
    selected = [entry for entry in entries if entry[1] in selected_weapons]
    tile_w, tile_h = 124, 150
    left_w = 190
    row_h = tile_h + 26
    width = left_w + FRAME_COUNT * tile_w + 28
    height = 74 + len(selected) * row_h
    sheet = Image.new("RGB", (width, height), (8, 13, 18))
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 14)
        title_font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 18)
    except Exception:
        font = title_font = None
    draw.text((18, 16), "Top-Tier Character Weapon Action Pass - 7 frame sample", fill=(236, 242, 246), font=title_font)
    for i in range(FRAME_COUNT):
        draw.text((left_w + i * tile_w + 12, 46), f"F{i + 1}", fill=(168, 190, 205), font=font)
    y = 70
    for char, weapon, prefix in selected:
        draw.text((18, y + 38), f"{char}\n{weapon}", fill=(218, 228, 236), font=font)
        cdir = COMBO_ROOT / char
        for i in range(FRAME_COUNT):
            p = cdir / f"{prefix}_attack_{i + 1:02d}.png"
            x = left_w + i * tile_w
            draw.rounded_rectangle((x + 4, y + 4, x + tile_w - 4, y + tile_h - 4), radius=8, outline=(58, 90, 108), fill=(14, 22, 30))
            if p.exists():
                thumb = _fit_thumb(_load_rgba(p), (tile_w - 12, tile_h - 18))
                sheet.paste(thumb, (x + 6, y + 8), thumb)
        y += row_h
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path)


def _action_frame_paths(entries: list[tuple[str, str, str]]) -> list[Path]:
    paths: list[Path] = []
    for char, _weapon, prefix in entries:
        cdir = COMBO_ROOT / char
        for anim in ["attack_left", "attack", "attack_right"]:
            for frame_idx in range(FRAME_COUNT):
                paths.append(cdir / f"{prefix}_{anim}_{frame_idx + 1:02d}.png")
    return paths


def _update_index(spec_rel: str, contact_rel: str, reference_rel: str | None) -> None:
    index = json.loads(INDEX_PATH.read_text())
    entry = {
        "id": "final_character_weapon_action_pass_2026_07_02",
        "category": "animation_polish",
        "status": "accepted",
        "description": "Top-tier raster action pass for fused character/weapon firing frames: 7-frame anticipation, muzzle ignition, recoil, venting, recovery.",
        "source": spec_rel,
        "derived": contact_rel,
    }
    if reference_rel:
        entry["reference"] = reference_rel
    items = index.get("items", [])
    items = [it for it in items if it.get("id") != entry["id"]]
    items.append(entry)
    index["items"] = items
    INDEX_PATH.write_text(json.dumps(index, ensure_ascii=False, indent=2) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--reference", default="", help="Optional image_gen reference board to copy into source refs.")
    parser.add_argument("--sanitize-existing", action="store_true", help="Only enforce transparent canvas margins on existing action frames.")
    args = parser.parse_args()

    entries = _combo_entries()
    if not entries:
        raise SystemExit("No character weapon combo entries found.")

    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    CONTACT_DIR.mkdir(parents=True, exist_ok=True)

    reference_rel = None
    if args.reference:
        src = Path(args.reference)
        if src.exists():
            dst = SOURCE_DIR / f"top_tier_character_weapon_action_reference_{STAMP}.png"
            shutil.copy2(src, dst)
            reference_rel = str(dst.relative_to(ROOT))
    if reference_rel is None:
        existing_reference = SOURCE_DIR / f"top_tier_character_weapon_action_reference_{STAMP}.png"
        if existing_reference.exists():
            reference_rel = str(existing_reference.relative_to(ROOT))

    if args.sanitize_existing:
        sanitized: list[str] = []
        for path in _action_frame_paths(entries):
            if not path.exists():
                continue
            frame = _apply_safe_canvas_margin(_load_rgba(path))
            frame.save(path)
            sanitized.append(str(path.relative_to(ROOT)))
        contact = CONTACT_DIR / f"contact_character_weapon_action_top_tier_{STAMP}.png"
        _make_contact_sheet(entries, contact)
        spec = {
            "id": "final_character_weapon_action_pass_2026_07_02",
            "created_at": datetime.now(timezone.utc).isoformat(),
            "tool": "built-in image_gen reference + local raster PIL action generator",
            "operation": "sanitize_existing_safe_canvas_margin",
            "reference": reference_rel,
            "safe_canvas_margin_px": SAFE_CANVAS_MARGIN,
            "frame_contract": {
                "canvas": "380x520 RGBA preserved",
                "directions": ["attack_left", "attack", "attack_right"],
                "frames_per_direction": FRAME_COUNT,
                "keyframes": [k["name"] for k in KEYFRAMES],
            },
            "entries": len(entries),
            "generated_files": sanitized,
            "contact_sheet": str(contact.relative_to(ROOT)),
        }
        spec_path = SOURCE_DIR / f"top_tier_character_weapon_action_spec_{STAMP}.json"
        spec_path.write_text(json.dumps(spec, ensure_ascii=False, indent=2) + "\n")
        _update_index(str(spec_path.relative_to(ROOT)), str(contact.relative_to(ROOT)), reference_rel)
        print(f"Sanitized {len(sanitized)} character weapon action frames")
        print(f"Spec: {spec_path.relative_to(ROOT)}")
        print(f"Contact sheet: {contact.relative_to(ROOT)}")
        return 0

    muzzle_maps = {
        "center": _parse_muzzle_dict("CHARACTER_WEAPON_COMBO_MUZZLE"),
        "left": _parse_muzzle_dict("CHARACTER_WEAPON_COMBO_MUZZLE_LEFT"),
        "right": _parse_muzzle_dict("CHARACTER_WEAPON_COMBO_MUZZLE_RIGHT"),
    }

    generated: list[str] = []
    for char, weapon, prefix in entries:
        cdir = COMBO_ROOT / char
        for anim in ["attack_left", "attack", "attack_right"]:
            source_path = cdir / f"{prefix}_{anim}_02.png"
            if not source_path.exists():
                source_path = cdir / f"{prefix}_attack_02.png"
            if not source_path.exists():
                source_path = cdir / f"{prefix}_idle_01.png"
            source = _load_rgba(source_path)
            for frame_idx in range(FRAME_COUNT):
                frame = _render_action_frame(source, char, weapon, anim, frame_idx, muzzle_maps)
                out_path = cdir / f"{prefix}_{anim}_{frame_idx + 1:02d}.png"
                frame.save(out_path)
                generated.append(str(out_path.relative_to(ROOT)))

    contact = CONTACT_DIR / f"contact_character_weapon_action_top_tier_{STAMP}.png"
    _make_contact_sheet(entries, contact)

    spec = {
        "id": "final_character_weapon_action_pass_2026_07_02",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "tool": "built-in image_gen reference + local raster PIL action generator",
        "reference": reference_rel,
        "safe_canvas_margin_px": SAFE_CANVAS_MARGIN,
        "frame_contract": {
            "canvas": "380x520 RGBA preserved",
            "directions": ["attack_left", "attack", "attack_right"],
            "frames_per_direction": FRAME_COUNT,
            "keyframes": [k["name"] for k in KEYFRAMES],
        },
        "entries": len(entries),
        "generated_files": generated,
        "contact_sheet": str(contact.relative_to(ROOT)),
    }
    spec_path = SOURCE_DIR / f"top_tier_character_weapon_action_spec_{STAMP}.json"
    spec_path.write_text(json.dumps(spec, ensure_ascii=False, indent=2) + "\n")
    _update_index(str(spec_path.relative_to(ROOT)), str(contact.relative_to(ROOT)), reference_rel)
    print(f"Generated {len(generated)} character weapon action frames")
    print(f"Spec: {spec_path.relative_to(ROOT)}")
    print(f"Contact sheet: {contact.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
