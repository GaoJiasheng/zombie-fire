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
            frames = [Image.open(path).convert("RGB") for path in (before, after)]
            width, height = frames[0].size
            board = Image.new("RGB", (width * 2 + 24, height + 48), "#111820")
            draw = ImageDraw.Draw(board)
            draw.text((16, 16), "BEFORE", fill="white")
            draw.text((width + 40, 16), "AFTER", fill="white")
            for index, frame in enumerate(frames):
                board.paste(frame, (index * (width + 24), 48))
            board.save(destination / after.name)


if __name__ == "__main__":
    main()
