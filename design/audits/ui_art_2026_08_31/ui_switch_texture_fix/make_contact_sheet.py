#!/usr/bin/env python3
"""Build an owner-facing contact sheet for the settings switch texture fix."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps


HERE = Path(__file__).resolve().parent


def font(size: int):
    for path in ("/System/Library/Fonts/PingFang.ttc", "/System/Library/Fonts/STHeiti Medium.ttc"):
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def main() -> None:
    rows = [
        ("1080×1920", 1080, 1920),
        ("1320×2868 · 16 Pro Max", 1320, 2868),
        ("750×1334 · SE", 750, 1334),
    ]
    thumb = (270, 480)
    gap = 18
    header = 54
    label_width = 245
    canvas = Image.new(
        "RGB",
        (label_width + 2 * (thumb[0] + gap) + gap, header + len(rows) * (thumb[1] + gap) + gap),
        "#0b1014",
    )
    draw = ImageDraw.Draw(canvas)
    draw.text((label_width, 12), "中文", fill="#f1b35d", font=font(22))
    draw.text((label_width + thumb[0] + gap, 12), "English", fill="#f1b35d", font=font(22))
    for row_index, (label, width, height) in enumerate(rows):
        y = header + row_index * (thumb[1] + gap)
        draw.text((14, y + 16), label, fill="#d8e1e1", font=font(20))
        for column, language in enumerate(("zh", "en")):
            path = HERE / "screenshots" / f"settings_switch_{width}x{height}_{language}.png"
            with Image.open(path) as source:
                image = ImageOps.fit(source.convert("RGB"), thumb, method=Image.Resampling.LANCZOS)
            canvas.paste(image, (label_width + column * (thumb[0] + gap), y))
    canvas.save(HERE / "settings_switch_three_size_bilingual.png", optimize=True)


if __name__ == "__main__":
    main()
