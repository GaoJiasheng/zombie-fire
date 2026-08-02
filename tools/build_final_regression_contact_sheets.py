#!/usr/bin/env python3
"""Build paginated human-review sheets for the final App Store screenshot matrix."""

from __future__ import annotations

import argparse
from collections import defaultdict
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
    if name.startswith("final_combat_"):
        for theme in ("default", "neon_tempest", "infernal_dominion", "polar_aurora", "gilded_eclipse"):
            if name.startswith(f"final_combat_{theme}_"):
                return f"combat_{theme}"
        return "combat_other"
    if name.startswith("final_active_"):
        return "active_skills_by_theme"
    if name.startswith("final_vfx_") or "app_store_vfx" in name or "_inferno_" in name or "absolute_zero_" in name or "golden_law_" in name:
        return "combat_vfx"
    if "boss_" in name:
        return "bosses"
    if "zombie_" in name:
        return "zombies"
    if "store" in name:
        return "store"
    if "appearance" in name:
        return "appearance"
    if "skill_hint_" in name or "character_hint_" in name:
        return "copy_skill_hints"
    if "card_detail_" in name or "skills_detail_" in name:
        return "copy_skill_details"
    if "card_offer_" in name:
        return "copy_skill_offers"
    if "_detail_" in name:
        return "copy_collection_details"
    if name.startswith("typography_"):
        return "copy_core"
    if name.startswith("final_zh_") or name.startswith("final_en_"):
        return "bilingual_interfaces"
    if name.startswith(("menu", "map", "loadout", "collection", "settings", "result", "pause", "card_")):
        return "core_interfaces"
    if name.startswith("battle"):
        return "battle_general"
    return "other"


def _wrap(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.ImageFont, width: int, max_lines: int) -> list[str]:
    words = text.replace("_", " ").split()
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = f"{current} {word}".strip()
        if draw.textlength(candidate, font=font) <= width:
            current = candidate
            continue
        if current:
            lines.append(current)
        current = word
    if current:
        lines.append(current)
    return lines[:max_lines]


def _page(paths: list[Path], title: str, output: Path) -> None:
    columns = 5
    cell_w = 246
    image_h = 438
    label_h = 74
    gap = 16
    margin = 20
    header_h = 64
    rows = (len(paths) + columns - 1) // columns
    sheet = Image.new(
        "RGB",
        (margin * 2 + columns * cell_w + (columns - 1) * gap, header_h + margin + rows * (image_h + label_h + gap)),
        (7, 11, 16),
    )
    draw = ImageDraw.Draw(sheet)
    draw.text((margin, 13), title, font=_font(30), fill=(232, 242, 247))
    label_font = _font(15)
    meta_font = _font(12)
    for index, path in enumerate(paths):
        source = Image.open(path).convert("RGB")
        scale = min((cell_w - 12) / source.width, image_h / source.height)
        thumb = source.resize((round(source.width * scale), round(source.height * scale)), Image.Resampling.LANCZOS)
        column = index % columns
        row = index // columns
        x = margin + column * (cell_w + gap)
        y = header_h + row * (image_h + label_h + gap)
        draw.rounded_rectangle(
            (x, y, x + cell_w, y + image_h + label_h),
            radius=12,
            fill=(13, 20, 28),
            outline=(45, 103, 120),
            width=2,
        )
        sheet.paste(thumb, (x + (cell_w - thumb.width) // 2, y + (image_h - thumb.height) // 2))
        for line_index, line in enumerate(_wrap(draw, path.stem, label_font, cell_w - 16, 3)):
            draw.text((x + 8, y + image_h + 5 + line_index * 18), line, font=label_font, fill=(220, 235, 241))
        draw.text(
            (x + 8, y + image_h + label_h - 17),
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
    groups: dict[str, list[Path]] = defaultdict(list)
    for path in sorted(args.input.glob("*.png")):
        groups[_group(path)].append(path)
    generated: list[Path] = []
    for group in sorted(groups):
        paths = groups[group]
        for start in range(0, len(paths), args.per_page):
            page_no = start // args.per_page + 1
            output = args.output / f"{group}_{page_no:02d}.png"
            _page(paths[start : start + args.per_page], f"Zombie Fire Final QA · {group} · {page_no}", output)
            generated.append(output)
            print(output)
    print(f"Contact sheets: {len(generated)} pages for {sum(len(paths) for paths in groups.values())} screenshots")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
