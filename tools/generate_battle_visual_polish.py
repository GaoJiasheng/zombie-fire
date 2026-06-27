#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets/production/source_refs"
HERO_SHEET = SOURCE_DIR / "hero_battle_pose_sheet.png"
WEAPON_SHEET = SOURCE_DIR / "handheld_weapon_sheet.png"

CHARACTER_ORDER = [
    ("char_vanguard", 0, 0),
    ("char_blaze", 1, 0),
    ("char_frost", 0, 1),
    ("char_volt", 1, 1),
]

WEAPON_ORDER = [
    ("weapon_autocannon", 0, 0),
    ("weapon_flamethrower", 1, 0),
    ("weapon_cryocannon", 2, 0),
    ("weapon_teslacoil", 3, 0),
    ("weapon_venomlauncher", 0, 1),
    ("weapon_railgun", 1, 1),
    ("weapon_scattergun", 2, 1),
    ("weapon_plasmacannon", 3, 1),
]

CHARACTER_HEIGHTS = {
    "char_vanguard": 438,
    "char_blaze": 432,
    "char_frost": 454,
    "char_volt": 440,
}


def remove_chroma_key(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            strong_key = g > 185 and r < 95 and b < 95
            edge_key = g > 150 and r < 70 and b < 70 and g > max(r, b) * 2.0
            if strong_key or edge_key:
                pixels[x, y] = (r, g, b, 0)
            elif a < 255 and g > max(r, b) * 1.25:
                pixels[x, y] = (r, int((r + b) * 0.42), b, a)
    return image


def remove_small_alpha_components(image: Image.Image, min_area: int) -> Image.Image:
    image = image.convert("RGBA")
    alpha = image.getchannel("A")
    width, height = image.size
    alpha_pixels = alpha.load()
    visited = bytearray(width * height)
    keep = bytearray(width * height)
    for start_y in range(height):
        row_offset = start_y * width
        for start_x in range(width):
            start_index = row_offset + start_x
            if visited[start_index] or alpha_pixels[start_x, start_y] <= 12:
                continue
            stack = [(start_x, start_y)]
            visited[start_index] = 1
            component: list[tuple[int, int]] = []
            while stack:
                x, y = stack.pop()
                component.append((x, y))
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if nx < 0 or nx >= width or ny < 0 or ny >= height:
                        continue
                    index = ny * width + nx
                    if visited[index] or alpha_pixels[nx, ny] <= 12:
                        continue
                    visited[index] = 1
                    stack.append((nx, ny))
            if len(component) >= min_area:
                for x, y in component:
                    keep[y * width + x] = 1
    pixels = image.load()
    for y in range(height):
        for x in range(width):
            if not keep[y * width + x]:
                r, g, b, _ = pixels[x, y]
                pixels[x, y] = (r, g, b, 0)
    return image


def keep_largest_alpha_component(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    alpha = image.getchannel("A")
    width, height = image.size
    alpha_pixels = alpha.load()
    visited = bytearray(width * height)
    largest: list[tuple[int, int]] = []
    for start_y in range(height):
        row_offset = start_y * width
        for start_x in range(width):
            start_index = row_offset + start_x
            if visited[start_index] or alpha_pixels[start_x, start_y] <= 12:
                continue
            stack = [(start_x, start_y)]
            visited[start_index] = 1
            component: list[tuple[int, int]] = []
            while stack:
                x, y = stack.pop()
                component.append((x, y))
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if nx < 0 or nx >= width or ny < 0 or ny >= height:
                        continue
                    index = ny * width + nx
                    if visited[index] or alpha_pixels[nx, ny] <= 12:
                        continue
                    visited[index] = 1
                    stack.append((nx, ny))
            if len(component) > len(largest):
                largest = component
    keep = bytearray(width * height)
    for x, y in largest:
        keep[y * width + x] = 1
    pixels = image.load()
    for y in range(height):
        for x in range(width):
            if not keep[y * width + x]:
                r, g, b, _ = pixels[x, y]
                pixels[x, y] = (r, g, b, 0)
    return image


def cell(image: Image.Image, cols: int, rows: int, col: int, row: int) -> Image.Image:
    width, height = image.size
    cell_w = width // cols
    cell_h = height // rows
    return image.crop((col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h))


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return (0, 0, image.width, image.height)
    left, top, right, bottom = bbox
    pad = 12
    return (
        max(0, left - pad),
        max(0, top - pad),
        min(image.width, right + pad),
        min(image.height, bottom + pad),
    )


def fit_subject(image: Image.Image, canvas_size: int, target_height: int, target_width: int | None = None, bottom: int | None = None) -> Image.Image:
    image = image.crop(alpha_bbox(image))
    target_width = target_width or canvas_size
    scale = min(target_width / image.width, target_height / image.height)
    resized = image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    bottom = bottom if bottom is not None else canvas_size - 28
    x = (canvas_size - resized.width) // 2
    y = bottom - resized.height
    canvas.alpha_composite(resized, (x, y))
    return canvas


def transform_sprite(base: Image.Image, scale: float = 1.0, rotate: float = 0.0, offset: tuple[int, int] = (0, 0), tint: tuple[int, int, int, int] | None = None) -> Image.Image:
    sprite = base
    if scale != 1.0:
        sprite = sprite.resize((round(sprite.width * scale), round(sprite.height * scale)), Image.Resampling.LANCZOS)
    if rotate != 0.0:
        sprite = sprite.rotate(rotate, expand=True, resample=Image.Resampling.BICUBIC)
    if tint is not None:
        overlay = Image.new("RGBA", sprite.size, tint)
        overlay.putalpha(sprite.getchannel("A").point(lambda a: min(a, tint[3])))
        sprite = Image.alpha_composite(sprite, overlay)
    canvas = Image.new("RGBA", base.size, (0, 0, 0, 0))
    x = (canvas.width - sprite.width) // 2 + offset[0]
    y = (canvas.height - sprite.height) // 2 + offset[1]
    canvas.alpha_composite(sprite, (x, y))
    return canvas


def sharpen(image: Image.Image, contrast: float = 1.04) -> Image.Image:
    image = ImageEnhance.Contrast(image).enhance(contrast)
    image = ImageEnhance.Sharpness(image).enhance(1.08)
    return image


def export_character_frames() -> None:
    sheet = Image.open(HERO_SHEET)
    for asset_id, col, row in CHARACTER_ORDER:
        cutout = keep_largest_alpha_component(remove_small_alpha_components(remove_chroma_key(cell(sheet, 2, 2, col, row)), 220))
        base = fit_subject(cutout, 512, CHARACTER_HEIGHTS[asset_id], 380, 474)
        base = sharpen(base, 1.05)
        folder = ROOT / "assets/production/sprites/animations/characters" / asset_id
        folder.mkdir(parents=True, exist_ok=True)

        idle_variants = [
            transform_sprite(base, 1.0, 0.0, (0, 0)),
            transform_sprite(base, 1.006, -0.35, (0, -2)),
            transform_sprite(base, 1.0, 0.0, (0, 1)),
            transform_sprite(base, 0.996, 0.35, (0, -1)),
        ]
        attack_variants = [
            transform_sprite(base, 1.0, 0.0, (0, 0)),
            transform_sprite(base, 1.018, -1.25, (4, -10)),
            transform_sprite(base, 1.012, -0.7, (3, -5)),
            transform_sprite(base, 1.0, 0.2, (0, -1)),
        ]
        hurt_variants = [
            transform_sprite(base, 0.996, 1.8, (-7, 9), (255, 48, 36, 42)),
            transform_sprite(base, 0.99, -1.1, (6, 5), (255, 48, 36, 28)),
            transform_sprite(base, 1.0, 0.0, (0, 0)),
        ]

        for index, frame in enumerate(idle_variants, start=1):
            frame.save(folder / f"{asset_id}_idle_{index:02d}.png")
        for index, frame in enumerate(attack_variants, start=1):
            frame.save(folder / f"{asset_id}_attack_{index:02d}.png")
        for index, frame in enumerate(hurt_variants, start=1):
            frame.save(folder / f"{asset_id}_hurt_{index:02d}.png")


def export_weapon_sprites() -> None:
    sheet = Image.open(WEAPON_SHEET)
    output = ROOT / "assets/production/sprites/weapons/handheld"
    output.mkdir(parents=True, exist_ok=True)
    anim_root = ROOT / "assets/production/sprites/animations/weapons"
    for weapon_id, col, row in WEAPON_ORDER:
        cutout = remove_small_alpha_components(remove_chroma_key(cell(sheet, 4, 2, col, row)), 180)
        cutout = cutout.crop(alpha_bbox(cutout))
        cutout = cutout.rotate(-43, expand=True, resample=Image.Resampling.BICUBIC)
        cutout = keep_largest_alpha_component(remove_chroma_key(cutout))
        # Battle rotates the right-facing rifle around the texture center. Keep
        # the opaque gun body centered on the canvas; bottom-aligning it makes
        # the muzzle swing like a detached UI icon when the character aims.
        sprite = fit_subject(cutout, 256, 226, 226, 174)
        sprite = sharpen(sprite, 1.08)
        sprite.save(output / f"{weapon_id}_rifle.png")

        folder = anim_root / weapon_id
        folder.mkdir(parents=True, exist_ok=True)
        variants = [
            transform_sprite(sprite, 1.0, 0.0, (0, 0)),
            transform_sprite(sprite, 1.003, -0.2, (0, -1)),
            transform_sprite(sprite, 0.998, 0.2, (0, 1)),
        ]
        recoils = [
            transform_sprite(sprite, 1.0, 0.0, (0, 0)),
            transform_sprite(sprite, 0.995, 0.0, (0, 8)),
            transform_sprite(sprite, 1.004, 0.0, (0, 4)),
            transform_sprite(sprite, 1.0, 0.0, (0, 0)),
        ]
        for index, frame in enumerate(variants, start=1):
            frame.save(folder / f"{weapon_id}_idle_{index:02d}.png")
        for index, frame in enumerate(recoils, start=1):
            frame.save(folder / f"{weapon_id}_recoil_{index:02d}.png")


def main() -> int:
    if not HERO_SHEET.exists():
        raise FileNotFoundError(HERO_SHEET)
    if not WEAPON_SHEET.exists():
        raise FileNotFoundError(WEAPON_SHEET)
    export_character_frames()
    export_weapon_sprites()
    print("Imported generated battle-facing heroes and realistic handheld guns.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
