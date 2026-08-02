#!/usr/bin/env python3
"""Build labeled peak-frame sheets for the App Store VFX placeholder audit."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SEQUENCE_ROOT = ROOT / "assets/production/sprites/vfx_sequences"
OUTPUT_ROOT = ROOT / "assets/production/contact_sheets/vfx_placeholder_audit_2026_08_01"
COLS = 4
ROWS = 5
CELL = 320
ART = 268
HEADER = 44


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


def _alpha_score(path: Path) -> int:
    alpha = Image.open(path).convert("RGBA").getchannel("A")
    histogram = alpha.histogram()
    return sum(count for value, count in enumerate(histogram) if value >= 24)


def _checker(size: int) -> Image.Image:
    image = Image.new("RGB", (size, size), (13, 20, 28))
    draw = ImageDraw.Draw(image)
    tile = 22
    for y in range(0, size, tile):
        for x in range(0, size, tile):
            if (x // tile + y // tile) % 2:
                draw.rectangle((x, y, x + tile - 1, y + tile - 1), fill=(19, 30, 40))
    return image


def main() -> None:
    rows: list[tuple[str, Path, str]] = []
    for sequence_path in sorted(SEQUENCE_ROOT.glob("*/*_sequence.json")):
        payload = json.loads(sequence_path.read_text())
        frame_paths = [ROOT / "assets/production" / path for path in payload.get("frames", [])]
        frame_paths = [path for path in frame_paths if path.exists()]
        if not frame_paths:
            continue
        peak = max(frame_paths, key=_alpha_score)
        source = payload.get("source", "")
        source_text = ", ".join(source) if isinstance(source, list) else str(source)
        rows.append((str(payload.get("id", sequence_path.parent.name)), peak, source_text))

    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    title_font = _font(22)
    label_font = _font(16)
    source_font = _font(12)
    per_sheet = COLS * ROWS
    for page, start in enumerate(range(0, len(rows), per_sheet), 1):
        subset = rows[start:start + per_sheet]
        sheet = Image.new("RGB", (COLS * CELL, ROWS * CELL), (6, 11, 18))
        draw = ImageDraw.Draw(sheet)
        for index, (sequence_id, frame_path, source) in enumerate(subset):
            column, row = index % COLS, index // COLS
            x, y = column * CELL, row * CELL
            checker = _checker(ART)
            frame = _fit(Image.open(frame_path), (ART - 16, ART - 16))
            checker.paste(frame, (8, 8), frame)
            sheet.paste(checker, (x + (CELL - ART) // 2, y + HEADER))
            draw.text((x + 10, y + 8), sequence_id, fill=(224, 239, 247), font=label_font)
            source_leaf = Path(source.split(", ")[0]).name if source else "no source"
            draw.text((x + 10, y + 27), source_leaf[:42], fill=(112, 163, 181), font=source_font)
        draw.text((10, 10), "", font=title_font)
        output = OUTPUT_ROOT / f"vfx_placeholder_audit_{page:02d}.png"
        sheet.save(output, optimize=True)
        print(output.relative_to(ROOT))
    print(f"Audited {len(rows)} runtime VFX sequences across {(len(rows) + per_sheet - 1) // per_sheet} sheets")


if __name__ == "__main__":
    main()
