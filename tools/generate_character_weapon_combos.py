#!/usr/bin/env python3
from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
CHAR_ROOT = ROOT / "assets/production/sprites/animations/characters_weaponless"
WEAPON_ROOT = ROOT / "assets/production/sprites/weapons/handheld"
OUT_ROOT = ROOT / "assets/production/sprites/animations/character_weapon_combos"
SOURCE_ROOT = ROOT / "assets/production/source_refs/generated"

CHARACTERS = ["char_vanguard", "char_blaze", "char_frost", "char_volt"]
WEAPONS = [
    "weapon_autocannon",
    "weapon_flamethrower",
    "weapon_cryocannon",
    "weapon_teslacoil",
    "weapon_venomlauncher",
    "weapon_railgun",
    "weapon_scattergun",
    "weapon_plasmacannon",
]
ACTIONS = {"idle": 4, "attack_left": 4, "attack": 4, "attack_right": 4, "hurt": 3}
CHARACTER_VISUAL_BASE_SCALE = 0.64
ATTACK_VARIANTS = {
    "attack_left": {"angle": 116.0, "center_shift": (-68, 5), "strap_shift": (-28, -2)},
    "attack": {"angle": 88.0, "center_shift": (-31, 16), "strap_shift": (-8, 12)},
    "attack_right": {"angle": 44.0, "center_shift": (0, 0), "strap_shift": (0, 0)},
}

CHAR_SCALE = {
    "char_vanguard": 1.04,
    "char_blaze": 1.00,
    "char_frost": 0.98,
    "char_volt": 0.98,
}
CHAR_POSES = {
    "char_vanguard": {
        "idle": {"center": (226, 214), "angle": 70, "strap": (216, 213)},
        "attack": {"center": (266, 165), "angle": 46, "strap": (230, 188)},
        "hurt": {"center": (220, 224), "angle": 66, "strap": (210, 218)},
    },
    "char_blaze": {
        "idle": {"center": (228, 213), "angle": 70, "strap": (216, 213)},
        "attack": {"center": (268, 163), "angle": 45, "strap": (232, 187)},
        "hurt": {"center": (222, 223), "angle": 66, "strap": (210, 218)},
    },
    "char_frost": {
        "idle": {"center": (232, 210), "angle": 68, "strap": (220, 210)},
        "attack": {"center": (270, 164), "angle": 44, "strap": (235, 184)},
        "hurt": {"center": (225, 220), "angle": 64, "strap": (214, 216)},
    },
    "char_volt": {
        "idle": {"center": (228, 210), "angle": 68, "strap": (218, 211)},
        "attack": {"center": (268, 162), "angle": 44, "strap": (233, 184)},
        "hurt": {"center": (222, 221), "angle": 64, "strap": (212, 216)},
    },
}
WEAPON_SCALE = {
    "weapon_autocannon": 0.96,
    "weapon_flamethrower": 0.98,
    "weapon_cryocannon": 0.98,
    "weapon_teslacoil": 0.96,
    "weapon_venomlauncher": 0.98,
    "weapon_railgun": 1.04,
    "weapon_scattergun": 0.95,
    "weapon_plasmacannon": 1.00,
}
WEAPON_RECOIL_POWER = {
    "weapon_autocannon": 9.0,
    "weapon_flamethrower": 7.0,
    "weapon_cryocannon": 8.5,
    "weapon_teslacoil": 8.0,
    "weapon_venomlauncher": 8.0,
    "weapon_railgun": 13.5,
    "weapon_scattergun": 12.5,
    "weapon_plasmacannon": 10.5,
}
WEAPON_FLASH_POWER = {
    "weapon_autocannon": 1.18,
    "weapon_flamethrower": 1.05,
    "weapon_cryocannon": 0.98,
    "weapon_teslacoil": 1.08,
    "weapon_venomlauncher": 0.92,
    "weapon_railgun": 1.30,
    "weapon_scattergun": 1.26,
    "weapon_plasmacannon": 1.18,
}


def crop_visible(image: Image.Image, pad: int = 8) -> Image.Image:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return image
    left, top, right, bottom = bbox
    return image.crop((
        max(0, left - pad),
        max(0, top - pad),
        min(image.width, right + pad),
        min(image.height, bottom + pad),
    ))


def crop_weapon_with_muzzle(image: Image.Image, pad: int = 8) -> tuple[Image.Image, tuple[float, float]]:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return image, (image.width - 1, image.height * 0.5)
    left, top, right, bottom = bbox
    crop_box = (
        max(0, left - pad),
        max(0, top - pad),
        min(image.width, right + pad),
        min(image.height, bottom + pad),
    )
    crop = image.crop(crop_box)
    crop_alpha = crop.getchannel("A")
    pixels = crop_alpha.load()
    right_edge = 0
    ys: list[int] = []
    for y in range(crop.height):
        for x in range(crop.width):
            if pixels[x, y] <= 32:
                continue
            if x > right_edge:
                right_edge = x
                ys = [y]
            elif x >= right_edge - 3:
                ys.append(y)
    muzzle_y = sum(ys) / len(ys) if ys else crop.height * 0.5
    return crop, (float(right_edge), float(muzzle_y))


def weapon_accent(weapon_id: str) -> tuple[int, int, int, int]:
    if "flame" in weapon_id or "plasma" in weapon_id:
        return (255, 132, 40, 230)
    if "cryo" in weapon_id or "rail" in weapon_id:
        return (80, 210, 255, 230)
    if "tesla" in weapon_id:
        return (176, 92, 255, 230)
    if "venom" in weapon_id:
        return (92, 255, 90, 220)
    return (255, 178, 65, 210)


def weapon_glow(weapon_id: str) -> tuple[int, int, int, int]:
    r, g, b, _ = weapon_accent(weapon_id)
    alpha = 115
    if "venom" in weapon_id:
        alpha = 105
    if weapon_id == "weapon_autocannon":
        alpha = 80
    return (r, g, b, alpha)


def angle_forward(angle: float) -> tuple[float, float]:
    radians = math.radians(angle)
    return math.cos(radians), -math.sin(radians)


def alpha(value: float) -> int:
    return int(max(0, min(255, round(value))))


def paste_shifted(source: Image.Image, dx: int, dy: int) -> Image.Image:
    if dx == 0 and dy == 0:
        return source
    output = Image.new("RGBA", source.size, (0, 0, 0, 0))
    src_left = max(0, -dx)
    src_top = max(0, -dy)
    src_right = min(source.width, source.width - dx) if dx > 0 else source.width
    src_bottom = min(source.height, source.height - dy) if dy > 0 else source.height
    if src_right <= src_left or src_bottom <= src_top:
        return output
    crop = source.crop((src_left, src_top, src_right, src_bottom))
    output.alpha_composite(crop, (max(0, dx), max(0, dy)))
    return output


def fit_to_canvas_margin(source: Image.Image, margin: int = 3) -> tuple[Image.Image, tuple[int, int]]:
    alpha_channel = source.getchannel("A")
    bbox = alpha_channel.getbbox()
    if bbox is None:
        return source, (0, 0)
    left, top, right, bottom = bbox
    dx = 0
    dy = 0
    right_margin = source.width - right
    bottom_margin = source.height - bottom
    if right_margin < margin:
        dx -= margin - right_margin
    if left + dx < margin:
        dx += margin - (left + dx)
    if bottom_margin < margin:
        dy -= margin - bottom_margin
    if top + dy < margin:
        dy += margin - (top + dy)
    if dx == 0 and dy == 0:
        return source, (0, 0)
    return paste_shifted(source, dx, dy), (dx, dy)


def load_weapon(weapon_id: str, scale: float, angle: float) -> tuple[Image.Image, tuple[float, float]]:
    path = WEAPON_ROOT / f"{weapon_id}_rifle.png"
    weapon, muzzle = crop_weapon_with_muzzle(Image.open(path).convert("RGBA"))
    marker = Image.new("L", weapon.size, 0)
    marker_draw = ImageDraw.Draw(marker)
    marker_draw.ellipse((muzzle[0] - 3, muzzle[1] - 3, muzzle[0] + 3, muzzle[1] + 3), fill=255)
    width = max(1, int(weapon.width * scale))
    height = max(1, int(weapon.height * scale))
    weapon = weapon.resize((width, height), Image.Resampling.LANCZOS)
    marker = marker.resize((width, height), Image.Resampling.LANCZOS)
    weapon = weapon.rotate(angle, expand=True, resample=Image.Resampling.BICUBIC)
    marker = marker.rotate(angle, expand=True, resample=Image.Resampling.BICUBIC)
    bbox = marker.getbbox()
    if bbox is None:
        return weapon, (weapon.width - 1, weapon.height * 0.5)
    return weapon, ((bbox[0] + bbox[2]) * 0.5, (bbox[1] + bbox[3]) * 0.5)


def source_action(action: str) -> str:
    return "attack" if action.startswith("attack") else action


def transform_character_frame(base: Image.Image, action: str, index: int) -> Image.Image:
    if action.startswith("attack"):
        variant = ATTACK_VARIANTS.get(action, ATTACK_VARIANTS["attack"])
        forward = angle_forward(float(variant["angle"]))
        side_bias = -1.0 if action == "attack_left" else (1.0 if action == "attack_right" else 0.0)
        # Fire frames need to read at runtime scale: impact, heavy recoil, recover, settle.
        frame_offsets = {
            1: (forward[0] * 3.0 + side_bias * 1.0, forward[1] * 3.0 - 3.0, -1.6 * side_bias),
            2: (-forward[0] * 9.0 + side_bias * 2.0, -forward[1] * 9.0 + 4.0, 2.4 * side_bias),
            3: (-forward[0] * 4.0, -forward[1] * 4.0 + 1.0, 1.0 * side_bias),
            4: (forward[0] * 1.0, forward[1] * 1.0 - 1.0, -0.4 * side_bias),
        }
        dx_f, dy_f, rot = frame_offsets.get(index, (0.0, 0.0, 0.0))
        dx, dy = int(round(dx_f)), int(round(dy_f))
        frame = base.rotate(rot, resample=Image.Resampling.BICUBIC, expand=False)
        return paste_shifted(frame, dx, dy)
    if action == "hurt":
        offsets = {1: (-4, 3, -2.0), 2: (4, 4, 1.4), 3: (-2, 1, -0.8)}
        dx, dy, rot = offsets.get(index, (0, 0, 0.0))
        frame = base.rotate(rot, resample=Image.Resampling.BICUBIC, expand=False)
        return paste_shifted(frame, dx, dy)
    offsets = {1: (0, 0), 2: (0, -1), 3: (0, 0), 4: (0, 1)}
    dx, dy = offsets.get(index, (0, 0))
    return paste_shifted(base, dx, dy)


def frame_pose(character_id: str, weapon_id: str, action: str, index: int) -> tuple[tuple[int, int], float, tuple[int, int], float]:
    base_action = source_action(action)
    pose = CHAR_POSES[character_id][base_action]
    center = pose["center"]
    angle = float(pose["angle"])
    strap = pose["strap"]
    flash = 0.0
    if action.startswith("attack"):
        variant = ATTACK_VARIANTS.get(action, ATTACK_VARIANTS["attack"])
        center = (center[0] + int(variant["center_shift"][0]), center[1] + int(variant["center_shift"][1]))
        strap = (strap[0] + int(variant["strap_shift"][0]), strap[1] + int(variant["strap_shift"][1]))
        angle = float(variant["angle"])
        recoil_power = float(WEAPON_RECOIL_POWER.get(weapon_id, 9.0))
        flash_power = float(WEAPON_FLASH_POWER.get(weapon_id, 1.0))
        sequence = {
            1: ((0.0, 0.0), 0.0, 1.0, 0.0),
            2: ((-2.0, 3.0), 4.4, 0.34, recoil_power),
            3: ((2.0, 1.0), 1.8, 0.14, recoil_power * 0.44),
            4: ((1.0, -1.0), -1.0, 0.0, -recoil_power * 0.10),
        }
        shift, angle_delta, flash, recoil = sequence.get(index, ((0.0, 0.0), 0.0, 0.0, 0.0))
        forward = angle_forward(angle)
        center = (
            int(round(center[0] + shift[0] - forward[0] * recoil)),
            int(round(center[1] + shift[1] - forward[1] * recoil)),
        )
        strap = (
            int(round(strap[0] + shift[0] - forward[0] * recoil * 0.55)),
            int(round(strap[1] + shift[1] - forward[1] * recoil * 0.55)),
        )
        if weapon_id == "weapon_railgun" and action == "attack_right":
            center = (center[0] - 16, center[1] + 5)
            strap = (strap[0] - 10, strap[1] + 3)
        angle += angle_delta
        flash *= flash_power
    elif action == "hurt":
        center = (center[0] - (2 if index == 1 else 0), center[1] + index)
        angle -= 2.0
    else:
        angle += {1: 0.0, 2: 1.0, 3: -0.7, 4: 0.4}.get(index, 0.0)
    return center, angle, strap, flash


def draw_weapon_grip(output: Image.Image, strap: tuple[int, int], weapon_id: str, action: str, index: int) -> None:
    if not action.startswith("attack"):
        return
    draw = ImageDraw.Draw(output, "RGBA")
    strap_x, strap_y = strap
    accent = weapon_accent(weapon_id)
    main = (strap_x - 6, strap_y - 4, strap_x + 16, strap_y + 4)
    draw.rounded_rectangle(main, radius=3, fill=(8, 12, 16, 48), outline=(accent[0], accent[1], accent[2], 72), width=1)


def draw_muzzle_flash(output: Image.Image, muzzle_pixel: tuple[float, float], angle: float, weapon_id: str, intensity: float) -> None:
    if intensity <= 0.0:
        return
    accent = weapon_accent(weapon_id)
    fx = Image.new("RGBA", output.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(fx, "RGBA")
    forward = angle_forward(angle)
    perp = (-forward[1], forward[0])
    x, y = muzzle_pixel
    length = 26.0 + 30.0 * intensity
    width = 7.0 + 12.0 * intensity
    tip = (x + forward[0] * length, y + forward[1] * length)
    left = (x + perp[0] * width, y + perp[1] * width)
    right = (x - perp[0] * width, y - perp[1] * width)
    draw.polygon([left, tip, right], fill=(accent[0], accent[1], accent[2], alpha(160 * intensity)))
    side_width = width * 0.62
    side_length = length * 0.62
    for side in (-1.0, 1.0):
        shoulder = (
            x + perp[0] * side_width * side - forward[0] * 4.0,
            y + perp[1] * side_width * side - forward[1] * 4.0,
        )
        spark_tip = (
            x + forward[0] * side_length + perp[0] * width * 0.35 * side,
            y + forward[1] * side_length + perp[1] * width * 0.35 * side,
        )
        draw.polygon([shoulder, spark_tip, (x, y)], fill=(accent[0], accent[1], accent[2], alpha(72 * intensity)))
    inner_length = length * 0.55
    inner_width = max(2.0, width * 0.38)
    inner_tip = (x + forward[0] * inner_length, y + forward[1] * inner_length)
    inner_left = (x + perp[0] * inner_width, y + perp[1] * inner_width)
    inner_right = (x - perp[0] * inner_width, y - perp[1] * inner_width)
    draw.polygon([inner_left, inner_tip, inner_right], fill=(255, 246, 190, alpha(210 * intensity)))
    radius = 8.0 + 11.0 * intensity
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(255, 238, 166, alpha(100 * intensity)))
    ring_radius = radius * 1.45
    draw.ellipse(
        (x - ring_radius, y - ring_radius, x + ring_radius, y + ring_radius),
        outline=(accent[0], accent[1], accent[2], alpha(70 * intensity)),
        width=2,
    )
    smoke_color = (180, 205, 210, alpha(38 * intensity))
    smoke_center = (x - forward[0] * radius * 0.45, y - forward[1] * radius * 0.45)
    draw.ellipse(
        (
            smoke_center[0] - radius * 1.25,
            smoke_center[1] - radius * 0.82,
            smoke_center[0] + radius * 1.25,
            smoke_center[1] + radius * 0.82,
        ),
        fill=smoke_color,
    )
    for offset in (-0.55, -0.25, 0.32, 0.58):
        spark_dir = (forward[0] * math.cos(offset) - forward[1] * math.sin(offset), forward[0] * math.sin(offset) + forward[1] * math.cos(offset))
        spark_len = length * (0.32 + abs(offset) * 0.28)
        sx = x + spark_dir[0] * spark_len
        sy = y + spark_dir[1] * spark_len
        draw.line((x, y, sx, sy), fill=(accent[0], accent[1], accent[2], alpha(120 * intensity)), width=2)
    glow = fx.filter(ImageFilter.GaussianBlur(5))
    output.alpha_composite(glow)
    output.alpha_composite(fx)


def compose_frame(character_id: str, weapon_id: str, action: str, index: int) -> tuple[Image.Image, tuple[float, float]]:
    base_action = source_action(action)
    base_path = CHAR_ROOT / character_id / f"{character_id}_{base_action}_{index:02d}.png"
    base = transform_character_frame(Image.open(base_path).convert("RGBA"), action, index)
    center, angle, strap, flash = frame_pose(character_id, weapon_id, action, index)
    weapon_scale = float(CHAR_SCALE[character_id]) * float(WEAPON_SCALE[weapon_id])
    weapon, muzzle = load_weapon(weapon_id, weapon_scale, angle)
    pos = (int(center[0] - weapon.width / 2), int(center[1] - weapon.height / 2))
    muzzle_pixel = (pos[0] + muzzle[0], pos[1] + muzzle[1])

    back_layer = Image.new("RGBA", base.size, (0, 0, 0, 0))

    glow_mask = weapon.getchannel("A").filter(ImageFilter.GaussianBlur(7))
    glow = Image.new("RGBA", weapon.size, weapon_glow(weapon_id))
    glow.putalpha(glow_mask)
    back_layer.alpha_composite(glow, pos)

    shadow_mask = weapon.getchannel("A").filter(ImageFilter.GaussianBlur(4))
    shadow = Image.new("RGBA", weapon.size, (0, 0, 0, 0))
    shadow.putalpha(shadow_mask.point(lambda alpha: int(alpha * 0.38)))
    back_layer.alpha_composite(shadow, (pos[0] + 4, pos[1] + 7))
    back_layer.alpha_composite(weapon, pos)

    output = Image.alpha_composite(back_layer, base)
    draw_weapon_grip(output, strap, weapon_id, action, index)
    draw_muzzle_flash(output, muzzle_pixel, angle, weapon_id, flash)
    frame_shift = (0, 0)
    if action.startswith("attack"):
        output, frame_shift = fit_to_canvas_margin(output)
    muzzle_offset = (
        (muzzle_pixel[0] + frame_shift[0] - base.width * 0.5) * CHARACTER_VISUAL_BASE_SCALE,
        (muzzle_pixel[1] + frame_shift[1] - base.height * 0.5) * CHARACTER_VISUAL_BASE_SCALE,
    )
    return output, muzzle_offset


def save_matrix_preview() -> Path:
    cell = (190, 260)
    preview_actions = ("idle", "attack_left", "attack", "attack_right")
    canvas = Image.new("RGBA", (len(WEAPONS) * cell[0], len(CHARACTERS) * len(preview_actions) * cell[1]), (15, 18, 22, 255))
    draw = ImageDraw.Draw(canvas)
    for row, character_id in enumerate(CHARACTERS):
        for col, weapon_id in enumerate(WEAPONS):
            for pose_index, action in enumerate(preview_actions):
                image, _ = compose_frame(character_id, weapon_id, action, 1)
                thumb = image.copy()
                thumb.thumbnail((170, 220), Image.Resampling.LANCZOS)
                x = col * cell[0] + 10
                y = (row * len(preview_actions) + pose_index) * cell[1] + 8
                canvas.alpha_composite(thumb, (x + (170 - thumb.width) // 2, y))
                label = f"{character_id.removeprefix('char_')} {weapon_id.removeprefix('weapon_')[:7]} {action}"
                draw.text((x, y + 222), label, fill=(225, 230, 235, 255))
    SOURCE_ROOT.mkdir(parents=True, exist_ok=True)
    path = SOURCE_ROOT / "character_weapon_combo_matrix.png"
    canvas.save(path)
    return path


def save_shooting_preview() -> Path:
    cell = (360, 220)
    frame_box = (82, 116)
    canvas = Image.new("RGBA", (len(WEAPONS) * cell[0], len(CHARACTERS) * cell[1]), (12, 15, 19, 255))
    draw = ImageDraw.Draw(canvas)
    for row, character_id in enumerate(CHARACTERS):
        for col, weapon_id in enumerate(WEAPONS):
            x0 = col * cell[0]
            y0 = row * cell[1]
            draw.rounded_rectangle(
                (x0 + 8, y0 + 8, x0 + cell[0] - 8, y0 + cell[1] - 8),
                radius=12,
                fill=(18, 24, 31, 255),
                outline=(58, 72, 88, 255),
                width=1,
            )
            label = f"{character_id.removeprefix('char_')} + {weapon_id.removeprefix('weapon_')}"
            draw.text((x0 + 18, y0 + 16), label, fill=(232, 236, 238, 255))
            for index in range(1, 5):
                image, _ = compose_frame(character_id, weapon_id, "attack", index)
                thumb = image.copy()
                thumb.thumbnail(frame_box, Image.Resampling.LANCZOS)
                fx = x0 + 18 + (index - 1) * 84
                fy = y0 + 54
                draw.rounded_rectangle(
                    (fx, fy, fx + frame_box[0], fy + frame_box[1]),
                    radius=7,
                    fill=(8, 11, 15, 255),
                    outline=(52, 63, 76, 255),
                    width=1,
                )
                canvas.alpha_composite(thumb, (fx + (frame_box[0] - thumb.width) // 2, fy + (frame_box[1] - thumb.height) // 2))
                draw.text((fx + 28, fy + frame_box[1] + 8), f"F{index}", fill=(158, 171, 184, 255))
    SOURCE_ROOT.mkdir(parents=True, exist_ok=True)
    path = SOURCE_ROOT / "character_weapon_combo_shooting_polish_contact_sheet_2026_07_01.png"
    canvas.save(path)
    return path


def save_shooting_focus_preview() -> Path:
    combos = [
        ("char_vanguard", "weapon_autocannon"),
        ("char_blaze", "weapon_flamethrower"),
        ("char_frost", "weapon_cryocannon"),
        ("char_volt", "weapon_teslacoil"),
        ("char_volt", "weapon_plasmacannon"),
    ]
    actions = ("attack_left", "attack", "attack_right")
    frame_box = (118, 156)
    cell_w = 128
    row_h = 218
    label_w = 210
    canvas = Image.new("RGBA", (label_w + len(actions) * 4 * cell_w + 32, len(combos) * row_h + 54), (12, 15, 19, 255))
    draw = ImageDraw.Draw(canvas)
    draw.text((18, 18), "Shooting action polish: left / center / right aim, frames 1-4", fill=(235, 238, 240, 255))
    for row, (character_id, weapon_id) in enumerate(combos):
        y0 = 48 + row * row_h
        draw.rounded_rectangle((8, y0, canvas.width - 8, y0 + row_h - 12), radius=12, fill=(18, 24, 31, 255), outline=(58, 72, 88, 255), width=1)
        label = f"{character_id.removeprefix('char_')}\n{weapon_id.removeprefix('weapon_')}"
        draw.multiline_text((24, y0 + 64), label, fill=(232, 236, 238, 255), spacing=8)
        for action_index, action in enumerate(actions):
            action_x = label_w + action_index * 4 * cell_w
            draw.text((action_x + 12, y0 + 12), action.replace("attack", "aim").replace("_", " "), fill=(148, 190, 210, 255))
            for frame_index in range(1, 5):
                image, _ = compose_frame(character_id, weapon_id, action, frame_index)
                thumb = image.copy()
                thumb.thumbnail(frame_box, Image.Resampling.LANCZOS)
                x = action_x + (frame_index - 1) * cell_w + 6
                y = y0 + 40
                draw.rounded_rectangle((x, y, x + frame_box[0], y + frame_box[1]), radius=8, fill=(8, 11, 15, 255), outline=(52, 63, 76, 255), width=1)
                canvas.alpha_composite(thumb, (x + (frame_box[0] - thumb.width) // 2, y + (frame_box[1] - thumb.height) // 2))
                draw.text((x + 44, y + frame_box[1] + 5), f"F{frame_index}", fill=(158, 171, 184, 255))
    SOURCE_ROOT.mkdir(parents=True, exist_ok=True)
    path = SOURCE_ROOT / "character_weapon_combo_shooting_focus_sheet_2026_07_01.png"
    canvas.save(path)
    return path


def main() -> int:
    generated: list[str] = []
    muzzle_offsets: dict[str, list[float]] = {}
    muzzle_offsets_by_aim: dict[str, dict[str, list[float]]] = {"left": {}, "center": {}, "right": {}}
    for character_id in CHARACTERS:
        out_dir = OUT_ROOT / character_id
        out_dir.mkdir(parents=True, exist_ok=True)
        for weapon_id in WEAPONS:
            _, muzzle_offset = compose_frame(character_id, weapon_id, "attack", 1)
            combo_key = f"{character_id}/{weapon_id}"
            muzzle_offsets[combo_key] = [round(muzzle_offset[0], 1), round(muzzle_offset[1], 1)]
            for aim_key, action in (("left", "attack_left"), ("center", "attack"), ("right", "attack_right")):
                _, aim_muzzle = compose_frame(character_id, weapon_id, action, 1)
                muzzle_offsets_by_aim[aim_key][combo_key] = [round(aim_muzzle[0], 1), round(aim_muzzle[1], 1)]
            for action, count in ACTIONS.items():
                for index in range(1, count + 1):
                    out_path = out_dir / f"{character_id}_{weapon_id}_{action}_{index:02d}.png"
                    frame, _ = compose_frame(character_id, weapon_id, action, index)
                    frame.save(out_path)
                    generated.append(str(out_path.relative_to(ROOT)))

    matrix_path = save_matrix_preview()
    shooting_preview_path = save_shooting_preview()
    shooting_focus_path = save_shooting_focus_preview()
    manifest = {
        "characters": CHARACTERS,
        "weapons": WEAPONS,
        "actions": ACTIONS,
        "frame_count": len(generated),
        "source_characters": str(CHAR_ROOT.relative_to(ROOT)),
        "source_weapons": str(WEAPON_ROOT.relative_to(ROOT)),
        "preview": str(matrix_path.relative_to(ROOT)),
        "shooting_preview": str(shooting_preview_path.relative_to(ROOT)),
        "shooting_focus_preview": str(shooting_focus_path.relative_to(ROOT)),
        "pose_policy": {
            "idle_hurt_layering": "weapon is rendered behind the character body; no floating front-mounted gun layer",
            "attack_layering": "weapon is raised toward the battlefield with left/center/right aim variants, frame-1 shot flash, heavy frame-2 recoil, visible settle, and recovered frame-4 stance",
            "muzzle_reference": "attack_01",
            "runtime_sync": "projectiles spawn from attack_01 muzzle offsets; battle.gd locks aim during the attack window",
        },
        "muzzle_offsets": muzzle_offsets,
        "muzzle_offsets_by_aim": muzzle_offsets_by_aim,
        "generated": generated,
    }
    manifest_path = SOURCE_ROOT / "character_weapon_combo_generation_manifest.json"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"generated {len(generated)} character/weapon combo frames")
    print(matrix_path.relative_to(ROOT))
    print(shooting_preview_path.relative_to(ROOT))
    print(shooting_focus_path.relative_to(ROOT))
    print(manifest_path.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
