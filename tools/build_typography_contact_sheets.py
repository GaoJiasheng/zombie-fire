#!/usr/bin/env python3
"""Build paginated review sheets from the bilingual typography screenshot matrix."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for candidate in (
        ROOT / "assets/production/fonts/font_main.ttf",
        Path("/System/Library/Fonts/PingFang.ttc"),
    ):
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size=size)
    return ImageFont.load_default()


def _group(path: Path) -> str:
    name = path.stem
    if "store_confirm_" in name:
        return "store_confirmations"
    if "skill_card_detail_" in name:
        return "skill_details"
    if "skill_hint_" in name or "character_skill_hint_" in name:
        return "skill_hints"
    if "skill_offer_" in name:
        return "skill_offers"
    if "_detail_" in name:
        return "collection_details"
    if "battle_hud" in name or "pause" in name:
        return "battle_text"
    return "core_screens"


def _short_label(path: Path) -> str:
    return path.stem.removeprefix("typography_tall_").replace("_", " ")


def _compose_page(paths: list[Path], title: str, output: Path) -> None:
    columns = 5
    cell_w = 230
    image_h = 470
    label_h = 78
    margin = 20
    header_h = 66
    rows = (len(paths) + columns - 1) // columns
    sheet = Image.new(
        "RGB",
        (margin + columns * (cell_w + margin), header_h + margin + rows * (image_h + label_h + margin)),
        (7, 11, 16),
    )
    draw = ImageDraw.Draw(sheet)
    draw.text((margin, 14), title, font=_font(32), fill=(228, 242, 248))
    label_font = _font(16)
    meta_font = _font(13)
    for index, path in enumerate(paths):
        source = Image.open(path).convert("RGB")
        scale = min((cell_w - 12) / source.width, image_h / source.height)
        thumb = source.resize(
            (round(source.width * scale), round(source.height * scale)),
            Image.Resampling.LANCZOS,
        )
        col = index % columns
        row = index // columns
        x = margin + col * (cell_w + margin)
        y = header_h + row * (image_h + label_h + margin)
        draw.rounded_rectangle(
            (x, y, x + cell_w, y + image_h + label_h),
            radius=12,
            fill=(13, 20, 28),
            outline=(45, 103, 120),
            width=2,
        )
        image_x = x + (cell_w - thumb.width) // 2
        image_y = y + (image_h - thumb.height) // 2
        sheet.paste(thumb, (image_x, image_y))
        label = _short_label(path)
        words = label.split()
        lines: list[str] = []
        current = ""
        for word in words:
            candidate = f"{current} {word}".strip()
            if draw.textlength(candidate, font=label_font) <= cell_w - 16:
                current = candidate
            else:
                if current:
                    lines.append(current)
                current = word
        if current:
            lines.append(current)
        for line_index, line in enumerate(lines[:3]):
            draw.text((x + 8, y + image_h + 5 + line_index * 19), line, font=label_font, fill=(220, 235, 241))
        draw.text(
            (x + 8, y + image_h + label_h - 18),
            f"{source.width}×{source.height}",
            font=meta_font,
            fill=(104, 164, 181),
        )
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, optimize=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--per-page", type=int, default=20)
    args = parser.parse_args()
    grouped: dict[str, list[Path]] = {}
    for path in sorted(args.input.glob("typography_*.png")):
        grouped.setdefault(_group(path), []).append(path)
    for group, paths in grouped.items():
        for start in range(0, len(paths), args.per_page):
            page = start // args.per_page + 1
            chunk = paths[start : start + args.per_page]
            output = args.output / f"{group}_{page:02d}.png"
            _compose_page(chunk, f"Typography QA · {group} · {page}", output)
            print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
