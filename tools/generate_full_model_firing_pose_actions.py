#!/usr/bin/env python3
from __future__ import annotations

import json
import math
import re
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SHEET_DIR = ROOT / "assets/production/source_refs/generated/model_grip_fullregen_2026_07_03"
STAGE1_DIR = ROOT / "assets/production/source_refs/generated/firing_pose_stage1_2026_07_03"
SOURCE_OUT = ROOT / "assets/production/source_refs/generated/firing_pose_full_model_2026_07_03"
COMBO_ROOT = ROOT / "assets/production/sprites/animations/character_weapon_combos"
BATTLE_GD = ROOT / "gameplay/battle/battle.gd"
INDEX_PATH = ROOT / "assets/production/OUTSOURCER_ASSET_INDEX.json"

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
DIRECTIONS = ["attack_left", "attack", "attack_right"]
FRAME_COUNT = 7
SPRITE_SIZE = (380, 520)
RUNTIME_SCALE = 0.64
MAX_FIT = (356, 500)
SAFE_MARGIN = 6
CENTER_AIM_ROTATION = 16.0
RIGHT_AIM_ROTATION = 1.8
STAMP = "2026_07_03"

APPROVED_STAGE1 = {
    ("char_vanguard", "weapon_autocannon"): STAGE1_DIR / "candidate_char_vanguard_weapon_autocannon_attack_04.png",
    ("char_blaze", "weapon_flamethrower"): STAGE1_DIR / "candidate_char_blaze_weapon_flamethrower_attack_04.png",
}

AIM = {
    "attack_left": (-0.54, -0.84),
    "attack": (0.34, -0.94),
    "attack_right": (0.56, -0.83),
}

FRAME_ARC = {
    1: {"scale": 0.982, "back": 7.0, "down": 5.5, "rot": -1.05},
    2: {"scale": 0.992, "back": 3.5, "down": 2.0, "rot": -0.45},
    3: {"scale": 1.002, "back": -1.0, "down": -1.0, "rot": 0.25},
    4: {"scale": 1.000, "back": 0.0, "down": 0.0, "rot": 0.0},
    5: {"scale": 1.004, "back": -2.0, "down": -1.5, "rot": 0.45},
    6: {"scale": 0.996, "back": 4.5, "down": 2.5, "rot": -0.7},
    7: {"scale": 0.988, "back": 6.0, "down": 3.5, "rot": -0.35},
}


def rel(path: Path) -> str:
    return str(path.relative_to(ROOT))


def median(values: list[int]) -> int:
    values = sorted(values)
    return values[len(values) // 2]


def border_key(image: Image.Image) -> tuple[int, int, int]:
    rgb = image.convert("RGB")
    w, h = rgb.size
    sample: list[tuple[int, int, int]] = []
    px = rgb.load()
    for x in range(w):
        sample.append(px[x, 0])
        sample.append(px[x, h - 1])
    for y in range(h):
        sample.append(px[0, y])
        sample.append(px[w - 1, y])
    return median([p[0] for p in sample]), median([p[1] for p in sample]), median([p[2] for p in sample])


def chroma_to_alpha(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    kr, kg, kb = border_key(rgba)
    out = Image.new("RGBA", rgba.size, (0, 0, 0, 0))
    src = rgba.load()
    dst = out.load()
    transparent = 24.0
    opaque = 92.0
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = src[x, y]
            dist = math.sqrt((r - kr) ** 2 + (g - kg) ** 2 + (b - kb) ** 2)
            if dist <= transparent:
                continue
            if dist < opaque:
                alpha = int(a * ((dist - transparent) / (opaque - transparent)))
                # Despill the antialiased edge so no green halo survives.
                if g > max(r, b):
                    g = int(max(r, b) + (g - max(r, b)) * 0.24)
                dst[x, y] = (r, g, b, alpha)
            else:
                dst[x, y] = (r, g, b, a)
    return out


def remove_small_alpha_components(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    width, height = rgba.size
    mask = alpha.load()
    visited = bytearray(width * height)
    components: list[list[tuple[int, int]]] = []

    for y in range(height):
        for x in range(width):
            idx = y * width + x
            if visited[idx] or mask[x, y] <= 24:
                continue
            stack = [(x, y)]
            visited[idx] = 1
            points: list[tuple[int, int]] = []
            while stack:
                px, py = stack.pop()
                points.append((px, py))
                for nx, ny in ((px + 1, py), (px - 1, py), (px, py + 1), (px, py - 1)):
                    if nx < 0 or nx >= width or ny < 0 or ny >= height:
                        continue
                    nidx = ny * width + nx
                    if visited[nidx] or mask[nx, ny] <= 24:
                        continue
                    visited[nidx] = 1
                    stack.append((nx, ny))
            components.append(points)

    if not components:
        return rgba
    largest = max(len(component) for component in components)
    keep_threshold = max(1400, int(largest * 0.045))
    keep = {point for component in components if len(component) >= keep_threshold for point in component}
    cleaned_alpha = Image.new("L", rgba.size, 0)
    cleaned_px = cleaned_alpha.load()
    src_alpha = alpha.load()
    for x, y in keep:
        cleaned_px[x, y] = src_alpha[x, y]
    cleaned = rgba.copy()
    cleaned.putalpha(cleaned_alpha.filter(ImageFilter.GaussianBlur(0.15)))
    return cleaned


def ensure_runtime_margin(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    bbox = rgba.getchannel("A").getbbox()
    if bbox is None:
        return Image.new("RGBA", SPRITE_SIZE, (0, 0, 0, 0))

    crop = rgba.crop(bbox)
    max_w = SPRITE_SIZE[0] - SAFE_MARGIN * 2
    max_h = SPRITE_SIZE[1] - SAFE_MARGIN * 2
    scale = min(1.0, max_w / max(1, crop.width), max_h / max(1, crop.height))
    if scale < 0.999:
        crop = crop.resize(
            (max(1, int(crop.width * scale)), max(1, int(crop.height * scale))),
            Image.Resampling.LANCZOS,
        )

    center_x = (bbox[0] + bbox[2]) * 0.5
    x = int(round(center_x - crop.width * 0.5))
    y = int(round(bbox[3] - crop.height))
    x = max(SAFE_MARGIN, min(SPRITE_SIZE[0] - SAFE_MARGIN - crop.width, x))
    y = max(SAFE_MARGIN, min(SPRITE_SIZE[1] - SAFE_MARGIN - crop.height, y))

    out = Image.new("RGBA", SPRITE_SIZE, (0, 0, 0, 0))
    out.alpha_composite(crop, (x, y))
    return out


def fit_to_runtime(source: Image.Image) -> Image.Image:
    image = source.convert("RGBA")
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return Image.new("RGBA", SPRITE_SIZE, (0, 0, 0, 0))
    crop = image.crop((
        max(0, bbox[0] - 12),
        max(0, bbox[1] - 12),
        min(image.width, bbox[2] + 12),
        min(image.height, bbox[3] + 12),
    ))
    scale = min(MAX_FIT[0] / crop.width, MAX_FIT[1] / crop.height)
    fitted = crop.resize((max(1, int(crop.width * scale)), max(1, int(crop.height * scale))), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", SPRITE_SIZE, (0, 0, 0, 0))
    x = (SPRITE_SIZE[0] - fitted.width) // 2
    y = SPRITE_SIZE[1] - SAFE_MARGIN - fitted.height
    canvas.alpha_composite(fitted, (x, y))
    return ensure_runtime_margin(canvas)


def extract_from_sheet(character: str, weapon: str) -> Image.Image:
    sheet_path = SHEET_DIR / f"{character}_8weapon_model_sheet.png"
    sheet = Image.open(sheet_path).convert("RGB")
    weapon_index = WEAPONS.index(weapon)
    x0 = int(round(sheet.width * weapon_index / len(WEAPONS)))
    x1 = int(round(sheet.width * (weapon_index + 1) / len(WEAPONS)))
    column = sheet.crop((x0, 0, x1, sheet.height))
    return fit_to_runtime(remove_small_alpha_components(chroma_to_alpha(column)))


def base_model(character: str, weapon: str) -> Image.Image:
    approved = APPROVED_STAGE1.get((character, weapon))
    if approved and approved.exists():
        return ensure_runtime_margin(Image.open(approved).convert("RGBA"))
    return extract_from_sheet(character, weapon)


def transform_frame(source: Image.Image, direction: str, frame_index: int) -> Image.Image:
    base = source.convert("RGBA")
    if direction == "attack_left":
        base = base.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    elif direction == "attack":
        base = base.rotate(CENTER_AIM_ROTATION, resample=Image.Resampling.BICUBIC, center=(190, 260), fillcolor=(0, 0, 0, 0))
    elif direction == "attack_right":
        base = base.rotate(RIGHT_AIM_ROTATION, resample=Image.Resampling.BICUBIC, center=(190, 260), fillcolor=(0, 0, 0, 0))

    spec = FRAME_ARC[frame_index]
    if frame_index == 4 and direction == "attack":
        return ensure_runtime_margin(base)

    aim = AIM[direction]
    back = float(spec["back"])
    dx = int(round(-aim[0] * back))
    dy = int(round(-aim[1] * back + float(spec["down"])))
    rot = float(spec["rot"])
    if direction == "attack_left":
        rot *= -1.0
    elif direction == "attack_right":
        rot *= 1.15

    transformed = base.rotate(rot, resample=Image.Resampling.BICUBIC, center=(190, 260), translate=(dx, dy), fillcolor=(0, 0, 0, 0))
    scale = float(spec["scale"])
    if abs(scale - 1.0) < 0.001:
        return ensure_runtime_margin(transformed)
    bbox = transformed.getchannel("A").getbbox()
    if bbox is None:
        return transformed
    crop = transformed.crop(bbox)
    resized = crop.resize((max(1, int(crop.width * scale)), max(1, int(crop.height * scale))), Image.Resampling.BICUBIC)
    out = Image.new("RGBA", SPRITE_SIZE, (0, 0, 0, 0))
    cx = (bbox[0] + bbox[2]) * 0.5
    bottom = bbox[3]
    x = int(round(cx - resized.width * 0.5))
    y = int(round(bottom - resized.height))
    out.alpha_composite(resized, (x, y))
    return ensure_runtime_margin(out)


def muzzle_pixel(frame: Image.Image, direction: str) -> tuple[float, float]:
    alpha = frame.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return (190.0, 160.0)
    px = alpha.load()
    aim = AIM[direction]
    best_score = -1e9
    best: list[tuple[int, int]] = []
    for y in range(max(0, bbox[1] - 2), min(frame.height, bbox[3] + 2)):
        for x in range(max(0, bbox[0] - 2), min(frame.width, bbox[2] + 2)):
            if px[x, y] <= 24:
                continue
            score = x * aim[0] + y * aim[1]
            if score > best_score + 0.5:
                best_score = score
                best = [(x, y)]
            elif abs(score - best_score) <= 0.5:
                best.append((x, y))
    if not best:
        return ((bbox[0] + bbox[2]) * 0.5, bbox[1])
    return (sum(p[0] for p in best) / len(best), sum(p[1] for p in best) / len(best))


def muzzle_offset(frame: Image.Image, direction: str) -> tuple[float, float]:
    mx, my = muzzle_pixel(frame, direction)
    return (round((mx - SPRITE_SIZE[0] * 0.5) * RUNTIME_SCALE, 1), round((my - SPRITE_SIZE[1] * 0.5) * RUNTIME_SCALE, 1))


def render_all() -> tuple[dict[str, dict[str, tuple[float, float]]], list[str]]:
    SOURCE_OUT.mkdir(parents=True, exist_ok=True)
    generated: list[str] = []
    muzzle_maps: dict[str, dict[str, tuple[float, float]]] = {"attack": {}, "attack_left": {}, "attack_right": {}}
    for character in CHARACTERS:
        char_dir = COMBO_ROOT / character
        char_dir.mkdir(parents=True, exist_ok=True)
        for weapon in WEAPONS:
            model = base_model(character, weapon)
            model_path = SOURCE_OUT / f"model_{character}_{weapon}_attack_04.png"
            model.save(model_path)
            generated.append(rel(model_path))
            for direction in DIRECTIONS:
                frame_04: Image.Image | None = None
                for frame_index in range(1, FRAME_COUNT + 1):
                    frame = transform_frame(model, direction, frame_index)
                    if frame_index == 4:
                        frame_04 = frame
                    out_path = char_dir / f"{character}_{weapon}_{direction}_{frame_index:02d}.png"
                    frame.save(out_path)
                    generated.append(rel(out_path))
                if frame_04 is None:
                    frame_04 = transform_frame(model, direction, 4)
                key = f"{character}/{weapon}"
                muzzle_maps[direction][key] = muzzle_offset(frame_04, direction)
    return muzzle_maps, generated


def gd_vector(value: tuple[float, float]) -> str:
    return f"Vector2({value[0]:.1f}, {value[1]:.1f})"


def gd_dict(name: str, mapping: dict[str, tuple[float, float]]) -> str:
    lines = [f"const {name} := {{"]
    for character in CHARACTERS:
        for weapon in WEAPONS:
            key = f"{character}/{weapon}"
            lines.append(f'\t"{key}": {gd_vector(mapping[key])},')
    lines.append("}")
    return "\n".join(lines)


def patch_battle(muzzle_maps: dict[str, dict[str, tuple[float, float]]]) -> None:
    text = BATTLE_GD.read_text(encoding="utf-8")
    replacements = {
        "CHARACTER_WEAPON_COMBO_MUZZLE": muzzle_maps["attack"],
        "CHARACTER_WEAPON_COMBO_MUZZLE_LEFT": muzzle_maps["attack_left"],
        "CHARACTER_WEAPON_COMBO_MUZZLE_RIGHT": muzzle_maps["attack_right"],
    }
    for name, mapping in replacements.items():
        pattern = re.compile(rf"const {name} := \{{.*?\n\}}", re.S)
        replacement = gd_dict(name, mapping)
        text, count = pattern.subn(replacement, text, count=1)
        if count != 1:
            raise RuntimeError(f"failed to patch {name}")
    BATTLE_GD.write_text(text, encoding="utf-8")


def make_contact_sheet() -> Path:
    cell = (176, 232)
    label_h = 28
    cols = len(WEAPONS)
    rows = len(CHARACTERS) * len(DIRECTIONS)
    sheet = Image.new("RGBA", (cols * cell[0], rows * (cell[1] + label_h) + 44), (12, 15, 19, 255))
    draw = ImageDraw.Draw(sheet)
    draw.text((14, 14), "Full Model Firing Pose Runtime Sheet - 4 chars x 8 weapons x 3 directions", fill=(230, 238, 244, 255))
    y = 44
    for character in CHARACTERS:
        for direction in DIRECTIONS:
            for col, weapon in enumerate(WEAPONS):
                path = COMBO_ROOT / character / f"{character}_{weapon}_{direction}_04.png"
                img = Image.open(path).convert("RGBA")
                bbox = img.getchannel("A").getbbox()
                crop = img.crop(bbox) if bbox else img
                crop.thumbnail((cell[0] - 14, cell[1] - 8), Image.Resampling.LANCZOS)
                x = col * cell[0] + (cell[0] - crop.width) // 2
                sheet.alpha_composite(crop, (x, y + (cell[1] - crop.height) // 2))
                draw.text((col * cell[0] + 6, y + cell[1] + 4), weapon.replace("weapon_", ""), fill=(154, 178, 194, 255))
            draw.text((8, y + 6), f"{character} {direction}", fill=(255, 204, 96, 255))
            y += cell[1] + label_h
    out = SOURCE_OUT / f"full_model_firing_pose_runtime_sheet_{STAMP}.png"
    sheet.save(out)
    return out


def make_sequence_sheet() -> Path:
    thumb = (86, 118)
    label_w = 260
    direction_gap = 16
    row_h = thumb[1] + 34
    cols_w = len(DIRECTIONS) * FRAME_COUNT * thumb[0] + (len(DIRECTIONS) - 1) * direction_gap
    sheet = Image.new("RGBA", (label_w + cols_w + 24, len(CHARACTERS) * len(WEAPONS) * row_h + 44), (12, 15, 19, 255))
    draw = ImageDraw.Draw(sheet)
    draw.text((14, 14), "Full Model Firing Pose Sequence Check - 32 combos x 21 runtime frames", fill=(230, 238, 244, 255))
    y = 44
    for character in CHARACTERS:
        for weapon in WEAPONS:
            draw.text((12, y + 8), f"{character} / {weapon}", fill=(255, 204, 96, 255))
            x = label_w
            for direction in DIRECTIONS:
                draw.text((x + 4, y + 8), direction, fill=(154, 178, 194, 255))
                for frame_index in range(1, FRAME_COUNT + 1):
                    path = COMBO_ROOT / character / f"{character}_{weapon}_{direction}_{frame_index:02d}.png"
                    img = Image.open(path).convert("RGBA")
                    bbox = img.getchannel("A").getbbox()
                    crop = img.crop(bbox) if bbox else img
                    crop.thumbnail((thumb[0] - 4, thumb[1] - 4), Image.Resampling.LANCZOS)
                    px = x + (frame_index - 1) * thumb[0] + (thumb[0] - crop.width) // 2
                    py = y + 28 + (thumb[1] - crop.height) // 2
                    sheet.alpha_composite(crop, (px, py))
                x += FRAME_COUNT * thumb[0] + direction_gap
            y += row_h
    out = SOURCE_OUT / f"full_model_firing_pose_sequence_sheet_{STAMP}.png"
    sheet.save(out)
    return out


def update_index(contact_sheet: Path, sequence_sheet: Path, generated_count: int) -> None:
    data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
    entries = data.setdefault("owner_directed_generated_overrides", [])
    entry = {
        "path": "sprites/animations/character_weapon_combos",
        "source": "source_refs/generated/model_grip_fullregen_2026_07_03 + source_refs/generated/firing_pose_stage1_2026_07_03",
        "derived": rel(contact_sheet),
        "sequence_sheet": rel(sequence_sheet),
        "reason": "Owner approved the two-frame firing pose standard and requested all remaining characters/weapons be completed: all attack/attack_left/attack_right frames now use full model-rendered two-hand braced firing poses with no baked muzzle VFX.",
        "count": generated_count,
        "task": "design/ui_firing_pose_task.md §1",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    if not any(item.get("task") == entry["task"] and item.get("derived") == entry["derived"] for item in entries if isinstance(item, dict)):
        entries.append(entry)
    INDEX_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_manifest(
    generated: list[str],
    contact_sheet: Path,
    sequence_sheet: Path,
    muzzle_maps: dict[str, dict[str, tuple[float, float]]],
) -> Path:
    manifest = {
        "id": "full_model_firing_pose_actions_2026_07_03",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "task": "design/ui_firing_pose_task.md §1",
        "scope": "4 characters x 8 weapons x attack/attack_left/attack_right x 7 frames",
        "source_mode": "built-in image_gen model-rendered chroma-key sheets + approved stage1 single-frame overrides",
        "constraints": [
            "two-hand weapon grip",
            "wide braced firing stance",
            "3/4 top-down back view",
            "no baked muzzle flash, smoke, projectile, tracer, explosion, or UI",
            "runtime PNG frames only; no gameplay data/balance changes",
        ],
        "characters": CHARACTERS,
        "weapons": WEAPONS,
        "directions": DIRECTIONS,
        "frames_per_direction": FRAME_COUNT,
        "approved_stage1_overrides": {f"{c}/{w}": rel(p) for (c, w), p in APPROVED_STAGE1.items() if p.exists()},
        "model_sheets": {c: rel(SHEET_DIR / f"{c}_8weapon_model_sheet.png") for c in CHARACTERS},
        "contact_sheet": rel(contact_sheet),
        "sequence_sheet": rel(sequence_sheet),
        "generated_count": len(generated),
        "generated_files": generated,
        "muzzle_offsets": {
            direction: {key: [value[0], value[1]] for key, value in mapping.items()}
            for direction, mapping in muzzle_maps.items()
        },
    }
    path = SOURCE_OUT / f"full_model_firing_pose_manifest_{STAMP}.json"
    path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return path


def main() -> int:
    muzzle_maps, generated = render_all()
    patch_battle(muzzle_maps)
    contact_sheet = make_contact_sheet()
    sequence_sheet = make_sequence_sheet()
    manifest = write_manifest(generated, contact_sheet, sequence_sheet, muzzle_maps)
    update_index(contact_sheet, sequence_sheet, len(generated))
    print(f"generated {len(generated)} files")
    print(f"contact_sheet={rel(contact_sheet)}")
    print(f"sequence_sheet={rel(sequence_sheet)}")
    print(f"manifest={rel(manifest)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
