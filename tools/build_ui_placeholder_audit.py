#!/usr/bin/env python3
"""Build labeled sheets for the App Store runtime UI placeholder audit."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
UI_ROOT = ROOT / "assets/production/sprites/ui"
OUTPUT_ROOT = ROOT / "assets/production/contact_sheets/ui_placeholder_audit_2026_08_01"
COLS = 5
ROWS = 5
CELL = 260
ART = 208
HEADER = 42


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in (
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
    ):
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def _fit(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    rgba = image.convert("RGBA")
    box = rgba.getbbox()
    if box is None:
        return Image.new("RGBA", size)
    rgba = rgba.crop(box)
    scale = min(size[0] / rgba.width, size[1] / rgba.height)
    rgba = rgba.resize(
        (max(1, round(rgba.width * scale)), max(1, round(rgba.height * scale))),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", size)
    canvas.alpha_composite(rgba, ((size[0] - rgba.width) // 2, (size[1] - rgba.height) // 2))
    return canvas


def _checker(size: int) -> Image.Image:
    image = Image.new("RGB", (size, size), (12, 18, 25))
    draw = ImageDraw.Draw(image)
    tile = 20
    for y in range(0, size, tile):
        for x in range(0, size, tile):
            if (x // tile + y // tile) % 2:
                draw.rectangle((x, y, x + tile - 1, y + tile - 1), fill=(19, 29, 39))
    return image


def _is_redundant_native_button(path: Path) -> bool:
    return "_native_" in path.stem


def main() -> None:
    paths = [
        path
        for path in sorted(UI_ROOT.glob("*.png"))
        if not _is_redundant_native_button(path)
    ]
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    label_font = _font(13)
    size_font = _font(11)
    per_sheet = COLS * ROWS
    for page, start in enumerate(range(0, len(paths), per_sheet), 1):
        subset = paths[start:start + per_sheet]
        sheet = Image.new("RGB", (COLS * CELL, ROWS * CELL), (6, 10, 16))
        draw = ImageDraw.Draw(sheet)
        for index, path in enumerate(subset):
            column, row = index % COLS, index // COLS
            x, y = column * CELL, row * CELL
            source = Image.open(path).convert("RGBA")
            checker = _checker(ART)
            artwork = _fit(source, (ART - 14, ART - 14))
            checker.paste(artwork, (7, 7), artwork)
            sheet.paste(checker, (x + (CELL - ART) // 2, y + HEADER))
            draw.text((x + 8, y + 7), path.name[:34], fill=(226, 238, 245), font=label_font)
            draw.text(
                (x + 8, y + 24),
                f"{source.width}x{source.height}",
                fill=(111, 164, 184),
                font=size_font,
            )
        output = OUTPUT_ROOT / f"ui_placeholder_audit_{page:02d}.png"
        sheet.save(output, optimize=True)
        print(output.relative_to(ROOT))
    print(f"Audited {len(paths)} unique runtime UI rasters across {(len(paths) + per_sheet - 1) // per_sheet} sheets")


if __name__ == "__main__":
    main()
