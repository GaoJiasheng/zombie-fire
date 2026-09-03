#!/usr/bin/env python3
"""Combine unaltered before/after captures; originals retain native pixels."""
from pathlib import Path
from PIL import Image, ImageDraw

AUDIT = Path(__file__).resolve().parents[1]


def main():
    for group in ("x1", "x2", "x3", "x4"):
        destination = AUDIT / group / "comparisons"
        destination.mkdir(parents=True, exist_ok=True)
        for after in sorted((AUDIT / group / "after").glob("*.png")):
            before = AUDIT / group / "before" / after.name
            if not before.exists():
                continue
            comparison = destination / after.name
            if comparison.exists() and comparison.stat().st_mtime >= max(before.stat().st_mtime, after.stat().st_mtime):
                continue
            frames = [Image.open(path).convert("RGB") for path in (before, after)]
            width, height = frames[0].size
            board = Image.new("RGB", (width * 2 + 24, height + 48), "#111820")
            draw = ImageDraw.Draw(board)
            draw.text((16, 16), "BEFORE", fill="white")
            draw.text((width + 40, 16), "AFTER", fill="white")
            for index, frame in enumerate(frames):
                board.paste(frame, (index * (width + 24), 48))
            board.save(comparison)

    review = AUDIT / "review_sheets"
    review.mkdir(exist_ok=True)
    groups = {
        "settings": sorted((AUDIT / "x1/after").glob("*.png")),
        "weapon_en": sorted((AUDIT / "x2/after").glob("*_en_premium.png")),
        "weapon_zh": sorted((AUDIT / "x2/after").glob("*_zh_premium.png")),
        "character_en": sorted((AUDIT / "x3/after").glob("*_1080x1920_en.png")),
        "character_zh": sorted((AUDIT / "x3/after").glob("*_1080x1920_zh.png")),
        "character_tall_en": sorted((AUDIT / "x3/after").glob("*_1320x2868_en.png")),
        "loadout": sorted((AUDIT / "x4/after").glob("*.png")),
        "modal": sorted((AUDIT / "modal_order/after").glob("*.png")),
    }
    for label, paths in groups.items():
        if not paths:
            continue
        board = Image.new("RGB", (1080, 1200 * ((len(paths) + 1) // 2)), "#111820")
        draw = ImageDraw.Draw(board)
        for index, path in enumerate(paths):
            frame = Image.open(path).convert("RGB")
            frame.thumbnail((532, 1158), Image.Resampling.LANCZOS)
            x, y = (index % 2) * 540, (index // 2) * 1200
            draw.text((x + 4, y + 8), path.stem, fill="white")
            board.paste(frame, (x + (540 - frame.width) // 2, y + 32))
        board.save(review / (label + ".jpg"), quality=92)


if __name__ == "__main__":
    main()
