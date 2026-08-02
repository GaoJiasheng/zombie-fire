#!/usr/bin/env python3
"""Build final rendered UI icons/surfaces from the App Store placeholder audit masters."""

from __future__ import annotations

import json
from pathlib import Path
from collections import deque

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "assets/production/source_refs/generated/app_store_ui_placeholder_replacements_2026_08_01"
UI_ROOT = ROOT / "assets/production/sprites/ui"
CONTACT_ROOT = ROOT / "assets/production/contact_sheets/ui_placeholder_audit_2026_08_01"

CORE_MASTER = SOURCE_ROOT / "core_hud_icons_chroma.png"
TACTICAL_MASTER = SOURCE_ROOT / "tactical_icons_chroma.png"
SURFACE_MASTER = SOURCE_ROOT / "hud_surfaces_chroma.png"

CORE_NAMES = [
    "icon_currency_gold.png",
    "icon_currency_star.png",
    "icon_currency_xp.png",
    "icon_element_fire.png",
    "icon_element_ice.png",
    "icon_element_lightning.png",
    "icon_element_physical.png",
    "icon_element_poison.png",
    "icon_lock.png",
    "icon_pause.png",
    "icon_reroll_charge.png",
    "icon_settings.png",
    "icon_talent_point.png",
    "icon_warning.png",
    "_unused_core_pin.png",
]

TACTICAL_NAMES = [
    "ui_card_pin.png",
    "ui_card_reroll.png",
    "ui_card_skip.png",
    "ui_card_tag_projectile.png",
    "ui_card_tag_control.png",
    "ui_card_tag_element.png",
    "ui_card_tag_economy.png",
    "ui_target_strategy_breach.png",
    "ui_target_strategy_elite.png",
    "ui_target_strategy_low_hp.png",
    "ui_target_strategy_nearest.png",
    "ui_star_filled.png",
    "ui_star_empty.png",
    "_unused_information.png",
    "_unused_upgrade.png",
]

SURFACES = [
    ("ui_level_card_skin.png", (1024, 148), (45, 85, 835, 285)),
    ("ui_combo_panel.png", (390, 128), (70, 410, 795, 700)),
    ("ui_pill_skin.png", (512, 128), (120, 795, 745, 1075)),
    ("ui_plate_skin.png", (420, 150), (120, 1110, 745, 1470)),
    ("ui_damage_number_badge.png", (260, 100), (180, 1480, 680, 1815)),
]


def _green_key(image: Image.Image) -> Image.Image:
    """Remove the extraction green while suppressing edge spill."""
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    transparent = bytearray(width * height)
    for y in range(height):
        for x in range(width):
            r, g, b, _ = pixels[x, y]
            if g >= 135 and g > r * 1.55 and g > b * 1.55 and g - max(r, b) >= 72:
                pixels[x, y] = (r, g, b, 0)
                transparent[y * width + x] = 1
            else:
                pixels[x, y] = (r, g, b, 255)

    # Generated extraction plates can carry a thin green antialias fringe. Only
    # desaturate pixels touching keyed background so legitimate poison artwork is
    # preserved inside the silhouette.
    for y in range(1, height - 1):
        for x in range(1, width - 1):
            r, g, b, a = pixels[x, y]
            if a == 0 or g <= max(r, b) * 1.12:
                continue
            touches_key = any(
                transparent[(y + dy) * width + (x + dx)]
                for dy in (-1, 0, 1)
                for dx in (-1, 0, 1)
                if dx != 0 or dy != 0
            )
            if touches_key:
                edge = max(r, b)
                pixels[x, y] = (r, min(g, edge), b, min(a, 210))
    return rgba


def _contained(image: Image.Image, size: tuple[int, int], padding: int) -> Image.Image:
    box = image.getbbox()
    if box is None:
        raise RuntimeError("Rendered source cell has no visible subject")
    subject = image.crop(box)
    inner = (size[0] - padding * 2, size[1] - padding * 2)
    scale = min(inner[0] / subject.width, inner[1] / subject.height)
    subject = subject.resize(
        (max(1, round(subject.width * scale)), max(1, round(subject.height * scale))),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", size)
    canvas.alpha_composite(subject, ((size[0] - subject.width) // 2, (size[1] - subject.height) // 2))
    return canvas


def _clean_icon_cell(image: Image.Image, preserve_green: bool = False) -> Image.Image:
    """Drop atlas bleed/specks and remove chroma spill without flattening poison art."""
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    if not preserve_green:
        for y in range(height):
            for x in range(width):
                r, g, b, a = pixels[x, y]
                edge = max(r, b)
                if a > 0 and g > 80 and g > edge * 1.18:
                    if g > edge * 1.65:
                        pixels[x, y] = (r, g, b, 0)
                    else:
                        pixels[x, y] = (r, edge, b, a)

    visited = bytearray(width * height)
    components: list[list[tuple[int, int]]] = []
    for y in range(height):
        for x in range(width):
            offset = y * width + x
            if visited[offset] or pixels[x, y][3] < 20:
                continue
            visited[offset] = 1
            queue = deque([(x, y)])
            component: list[tuple[int, int]] = []
            while queue:
                px, py = queue.popleft()
                component.append((px, py))
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if nx < 0 or ny < 0 or nx >= width or ny >= height:
                        continue
                    neighbour = ny * width + nx
                    if visited[neighbour] or pixels[nx, ny][3] < 20:
                        continue
                    visited[neighbour] = 1
                    queue.append((nx, ny))
            components.append(component)
    if not components:
        return rgba
    largest = max(len(component) for component in components)
    minimum = max(20, round(largest * 0.006))
    for component in components:
        if len(component) >= minimum:
            continue
        for x, y in component:
            r, g, b, _ = pixels[x, y]
            pixels[x, y] = (r, g, b, 0)
    return rgba


def _native_surface(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    """Extend the calm center while keeping corners/edge hardware undistorted."""
    box = image.getbbox()
    if box is None:
        raise RuntimeError("Rendered surface source has no visible subject")
    subject = image.crop(box)
    scale = (size[1] - 4) / subject.height
    scaled = subject.resize(
        (max(1, round(subject.width * scale)), size[1] - 4),
        Image.Resampling.LANCZOS,
    )
    if scaled.width > size[0] - 4:
        scale = (size[0] - 4) / scaled.width
        scaled = scaled.resize(
            (size[0] - 4, max(1, round(scaled.height * scale))),
            Image.Resampling.LANCZOS,
        )
    if scaled.width < size[0] - 4:
        target_width = size[0] - 4
        cap = max(18, min(scaled.width // 3, round(scaled.height * 0.72)))
        middle_width = max(1, target_width - cap * 2)
        left = scaled.crop((0, 0, cap, scaled.height))
        middle = scaled.crop((cap, 0, scaled.width - cap, scaled.height)).resize(
            (middle_width, scaled.height), Image.Resampling.LANCZOS
        )
        right = scaled.crop((scaled.width - cap, 0, scaled.width, scaled.height))
        extended = Image.new("RGBA", (target_width, scaled.height))
        extended.alpha_composite(left, (0, 0))
        extended.alpha_composite(middle, (cap, 0))
        extended.alpha_composite(right, (target_width - cap, 0))
        scaled = extended
    canvas = Image.new("RGBA", size)
    canvas.alpha_composite(scaled, ((size[0] - scaled.width) // 2, (size[1] - scaled.height) // 2))
    return canvas


def _build_atlas(master_path: Path, names: list[str], written: list[str]) -> None:
    master = _green_key(Image.open(master_path))
    width, height = master.size
    for index, name in enumerate(names):
        if name.startswith("_unused"):
            continue
        column, row = index % 5, index // 5
        box = (
            round(column * width / 5),
            round(row * height / 3),
            round((column + 1) * width / 5),
            round((row + 1) * height / 3),
        )
        preserve_green = name == "icon_element_poison.png"
        cell = _clean_icon_cell(master.crop(box), preserve_green)
        result = _contained(cell, (256, 256), 18)
        output = UI_ROOT / name
        result.save(output, optimize=True)
        written.append(str(output.relative_to(ROOT)))


def _build_surfaces(written: list[str]) -> None:
    master = _green_key(Image.open(SURFACE_MASTER))
    for name, size, source_box in SURFACES:
        result = _native_surface(master.crop(source_box), size)
        output = UI_ROOT / name
        result.save(output, optimize=True)
        written.append(str(output.relative_to(ROOT)))


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    path = Path("/System/Library/Fonts/Helvetica.ttc")
    return ImageFont.truetype(path, size) if path.exists() else ImageFont.load_default()


def _contact_sheet(paths: list[Path]) -> Path:
    columns = 5
    cell = 260
    rows = (len(paths) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * cell, rows * cell), (7, 12, 18))
    draw = ImageDraw.Draw(sheet)
    font = _font(13)
    for index, path in enumerate(paths):
        x, y = index % columns * cell, index // columns * cell
        artwork = _contained(Image.open(path).convert("RGBA"), (210, 210), 4)
        checker = Image.new("RGB", (210, 210), (14, 23, 31))
        checker.paste(artwork, (0, 0), artwork)
        sheet.paste(checker, (x + 25, y + 38))
        draw.text((x + 8, y + 10), path.name[:34], fill=(225, 239, 246), font=font)
    CONTACT_ROOT.mkdir(parents=True, exist_ok=True)
    output = CONTACT_ROOT / "ui_replacements_final_contact_sheet.png"
    sheet.save(output, optimize=True)
    return output


def main() -> None:
    for required in (CORE_MASTER, TACTICAL_MASTER, SURFACE_MASTER):
        if not required.exists():
            raise FileNotFoundError(required)
    written: list[str] = []
    _build_atlas(CORE_MASTER, CORE_NAMES, written)
    _build_atlas(TACTICAL_MASTER, TACTICAL_NAMES, written)
    _build_surfaces(written)
    output_paths = [ROOT / path for path in written]
    contact = _contact_sheet(output_paths)
    manifest = {
        "task": "App Store runtime UI placeholder replacement",
        "sources": [str(path.relative_to(ROOT)) for path in (CORE_MASTER, TACTICAL_MASTER, SURFACE_MASTER)],
        "outputs": written,
        "contact_sheet": str(contact.relative_to(ROOT)),
        "rules": [
            "deep-rendered raster objects instead of flat procedural symbols",
            "transparent background and 18px minimum icon guard band",
            "native surface corners retained; only calm center spans are extended",
            "semantic masks and targeting geometry are not decorative placeholders",
        ],
    }
    (SOURCE_ROOT / "runtime_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n"
    )
    print(f"Built {len(written)} runtime UI replacements")
    print(contact.relative_to(ROOT))


if __name__ == "__main__":
    main()
