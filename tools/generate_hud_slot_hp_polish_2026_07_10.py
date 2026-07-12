#!/usr/bin/env python3
"""Regenerate combat HUD skill slot and HP bar assets.

The output is intentionally raster-first: high resolution transparent PNGs with
painted bevels, soft glows, grime, and compact details that survive the small
in-game HUD sizes without protruding horizontal line artifacts.
"""

from __future__ import annotations

import json
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
UI_DIR = ROOT / "assets/production/sprites/ui"
SRC_DIR = ROOT / "assets/production/source_refs/generated/hud_slot_hp_polish_2026_07_10"
CONTACT_DIR = ROOT / "assets/production/contact_sheets"
RNG = random.Random(20260710)


def rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    hex_color = hex_color.strip("#")
    return (
        int(hex_color[0:2], 16),
        int(hex_color[2:4], 16),
        int(hex_color[4:6], 16),
        alpha,
    )


def poly_chamfer(box: tuple[int, int, int, int], cut: int) -> list[tuple[int, int]]:
    x0, y0, x1, y1 = box
    return [
        (x0 + cut, y0),
        (x1 - cut, y0),
        (x1, y0 + cut),
        (x1, y1 - cut),
        (x1 - cut, y1),
        (x0 + cut, y1),
        (x0, y1 - cut),
        (x0, y0 + cut),
    ]


def alpha_composite_layer(base: Image.Image, layer: Image.Image) -> None:
    base.alpha_composite(layer)


def add_shadow(base: Image.Image, mask_points: list[tuple[int, int]], blur: int, offset: tuple[int, int], opacity: int) -> None:
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    ox, oy = offset
    sd.polygon([(x + ox, y + oy) for x, y in mask_points], fill=(0, 0, 0, opacity))
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    alpha_composite_layer(base, shadow)


def add_noise_clip(base: Image.Image, mask: Image.Image, strength: int = 22) -> None:
    pix = Image.new("RGBA", base.size, (0, 0, 0, 0))
    p = pix.load()
    m = mask.load()
    w, h = base.size
    for y in range(h):
        for x in range(w):
            if m[x, y] > 0 and RNG.random() < 0.11:
                v = RNG.randint(-strength, strength)
                if v >= 0:
                    p[x, y] = (255, 255, 255, min(26, v))
                else:
                    p[x, y] = (0, 0, 0, min(30, -v))
    alpha_composite_layer(base, pix.filter(ImageFilter.GaussianBlur(0.45)))


def draw_beveled_panel(
    size: tuple[int, int],
    outer: tuple[int, int, int, int],
    cut: int,
    accent: tuple[int, int, int, int],
    fill_a: tuple[int, int, int, int],
    fill_b: tuple[int, int, int, int],
    active: bool,
) -> Image.Image:
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    outer_poly = poly_chamfer(outer, cut)
    add_shadow(img, outer_poly, 12, (0, 8), 110)

    glow = Image.new("RGBA", size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.polygon(outer_poly, outline=accent[:3] + (80 if active else 48,), width=9)
    alpha_composite_layer(img, glow.filter(ImageFilter.GaussianBlur(7)))

    d = ImageDraw.Draw(img)
    d.polygon(outer_poly, fill=rgba("16191b", 250))
    d.line(outer_poly + [outer_poly[0]], fill=rgba("59646b", 230), width=3)
    d.line([(outer[0] + cut, outer[1] + 3), (outer[2] - cut, outer[1] + 3)], fill=rgba("b9c4c8", 90), width=2)
    d.line([(outer[0] + 4, outer[1] + cut), (outer[0] + 4, outer[3] - cut)], fill=accent[:3] + (128,), width=2)
    d.line([(outer[2] - 4, outer[1] + cut), (outer[2] - 4, outer[3] - cut)], fill=rgba("70d4de", 110), width=2)

    inset1 = (outer[0] + 12, outer[1] + 12, outer[2] - 12, outer[3] - 12)
    inset2 = (outer[0] + 24, outer[1] + 24, outer[2] - 24, outer[3] - 24)
    d.polygon(poly_chamfer(inset1, max(4, cut - 8)), fill=rgba("242b2d", 238))

    body = Image.new("RGBA", size, (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    body_poly = poly_chamfer(inset2, max(4, cut - 14))
    for yy in range(inset2[1], inset2[3] + 1):
        t = (yy - inset2[1]) / max(1, inset2[3] - inset2[1])
        rr = int(fill_a[0] * (1 - t) + fill_b[0] * t)
        gg = int(fill_a[1] * (1 - t) + fill_b[1] * t)
        bb = int(fill_a[2] * (1 - t) + fill_b[2] * t)
        bd.line((inset2[0], yy, inset2[2], yy), fill=(rr, gg, bb, 246))
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).polygon(body_poly, fill=255)
    body.putalpha(mask)
    alpha_composite_layer(img, body)
    add_noise_clip(img, mask, 18)

    d = ImageDraw.Draw(img)
    d.line(body_poly + [body_poly[0]], fill=accent[:3] + (170 if active else 120,), width=3)
    inner = (inset2[0] + 20, inset2[1] + 20, inset2[2] - 20, inset2[3] - 20)
    d.polygon(poly_chamfer(inner, max(3, cut - 24)), fill=rgba("06090b", 140))
    d.line(poly_chamfer(inner, max(3, cut - 24)) + [poly_chamfer(inner, max(3, cut - 24))[0]], fill=accent[:3] + (95,), width=2)

    for cx, cy, sx, sy in [
        (outer[0] + 26, outer[1] + 26, 20, 8),
        (outer[2] - 46, outer[1] + 26, 20, 8),
        (outer[0] + 26, outer[3] - 34, 20, 8),
        (outer[2] - 46, outer[3] - 34, 20, 8),
    ]:
        plate = (cx, cy, cx + sx, cy + sy)
        d.rounded_rectangle(plate, radius=2, fill=rgba("0b0e10", 210), outline=accent[:3] + (95,), width=1)

    for _ in range(28):
        x = RNG.randint(outer[0] + 24, outer[2] - 24)
        y = RNG.randint(outer[1] + 20, outer[3] - 20)
        length = RNG.randint(4, 15)
        a = RNG.random() * math.pi
        d.line((x, y, x + math.cos(a) * length, y + math.sin(a) * length), fill=(255, 255, 255, RNG.randint(14, 34)), width=1)

    return img


def supersample_slot(active: bool) -> Image.Image:
	scale = 4
	size = (220 * scale, 220 * scale)
	accent = rgba("ff9a2a") if active else rgba("58d3df")
	fill_a = rgba("3b3123") if active else rgba("1b343a")
	fill_b = rgba("081014") if active else rgba("071216")
	img = draw_beveled_panel(
		size,
		(14 * scale, 16 * scale, 206 * scale, 206 * scale),
		28 * scale,
		accent,
        fill_a,
		fill_b,
		active,
	)
	out = img.resize((220, 220), Image.Resampling.LANCZOS)
	# Remove any colored glow specks near the transparent canvas boundary. These
	# become the visible "thin line" artifact when the HUD button is small.
	pixels = out.load()
	for y in range(out.height):
		for x in range(out.width):
			if x < 10 or x >= out.width - 10 or y < 10 or y >= out.height - 10:
				r, g, b, a = pixels[x, y]
				if a < 64 or r > 70 or g > 70 or b > 70:
					pixels[x, y] = (0, 0, 0, 0)
	return out


def make_hp_track() -> Image.Image:
    scale = 3
    w, h = 768 * scale, 108 * scale
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    outer = (18 * scale, 18 * scale, (768 - 18) * scale, (108 - 18) * scale)
    cut = 26 * scale
    poly = poly_chamfer(outer, cut)
    add_shadow(img, poly, 14 * scale, (0, 4 * scale), 95)

    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.polygon(poly, outline=rgba("bc3640", 75), width=6 * scale)
    alpha_composite_layer(img, glow.filter(ImageFilter.GaussianBlur(5 * scale)))

    d.polygon(poly, fill=rgba("15191b", 252))
    d.line(poly + [poly[0]], fill=rgba("8e9aa0", 210), width=2 * scale)
    d.line([(outer[0] + cut, outer[1] + 3 * scale), (outer[2] - cut, outer[1] + 3 * scale)], fill=rgba("d5dde0", 78), width=2 * scale)
    d.line([(outer[0] + 8 * scale, outer[1] + cut), (outer[0] + 8 * scale, outer[3] - cut)], fill=rgba("ef4b4d", 120), width=2 * scale)

    slot = (54 * scale, 35 * scale, (768 - 54) * scale, 73 * scale)
    d.rounded_rectangle(slot, radius=18 * scale, fill=rgba("030407", 245), outline=rgba("81262d", 210), width=3 * scale)
    d.rounded_rectangle((slot[0] + 8 * scale, slot[1] + 7 * scale, slot[2] - 8 * scale, slot[3] - 7 * scale), radius=10 * scale, fill=rgba("14080a", 218))

    for x in range(slot[0] + 18 * scale, slot[2] - 18 * scale, 28 * scale):
        d.line((x, slot[1] + 9 * scale, x + 10 * scale, slot[1] + 9 * scale), fill=rgba("d94747", 48), width=2 * scale)

    for x, y in [(34, 30), (708, 30), (34, 64), (708, 64)]:
        d.rounded_rectangle((x * scale, y * scale, (x + 28) * scale, (y + 9) * scale), radius=3 * scale, fill=rgba("0c0e10", 220), outline=rgba("bf5960", 90), width=1 * scale)

    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).polygon(poly, fill=255)
    add_noise_clip(img, mask, 14)
    return img.resize((768, 108), Image.Resampling.LANCZOS)


def make_hp_fill() -> Image.Image:
    scale = 3
    w, h = 744 * scale, 32 * scale
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    box = (4 * scale, 4 * scale, w - 4 * scale, h - 4 * scale)
    for yy in range(box[1], box[3] + 1):
        t = (yy - box[1]) / max(1, box[3] - box[1])
        r = int(235 * (1 - t) + 116 * t)
        g = int(62 * (1 - t) + 10 * t)
        b = int(62 * (1 - t) + 18 * t)
        d.rounded_rectangle((box[0], yy, box[2], yy), radius=12 * scale, fill=(r, g, b, 255))
    d.rounded_rectangle(box, radius=12 * scale, outline=rgba("ff8a78", 180), width=2 * scale)
    d.line((30 * scale, 8 * scale, (w - 34 * scale), 8 * scale), fill=rgba("ffd0bd", 120), width=2 * scale)
    d.line((28 * scale, 23 * scale, (w - 38 * scale), 23 * scale), fill=rgba("430307", 115), width=2 * scale)
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.rounded_rectangle(box, radius=12 * scale, fill=rgba("ff332e", 80))
    alpha_composite_layer(img, glow.filter(ImageFilter.GaussianBlur(3 * scale)))
    return img.resize((744, 32), Image.Resampling.LANCZOS)


def make_contact(paths: list[Path]) -> None:
    CONTACT_DIR.mkdir(parents=True, exist_ok=True)
    rows = []
    for p in paths:
        im = Image.open(p).convert("RGBA")
        max_w, max_h = 330, 110
        s = min(max_w / im.width, max_h / im.height)
        thumb = im.resize((max(1, int(im.width * s)), max(1, int(im.height * s))), Image.Resampling.LANCZOS)
        rows.append((p.name, thumb))
    sheet = Image.new("RGBA", (760, 160 * len(rows) + 24), rgba("0b1218"))
    d = ImageDraw.Draw(sheet)
    y = 12
    for name, thumb in rows:
        d.rectangle((12, y, 748, y + 136), outline=rgba("4d6370"), width=1)
        sheet.alpha_composite(thumb, (32, y + (136 - thumb.height) // 2))
        d.text((395, y + 56), name, fill=rgba("d9e2e5"))
        y += 160
    sheet.save(CONTACT_DIR / "hud_slot_hp_polish_2026_07_10.png")


def main() -> None:
    UI_DIR.mkdir(parents=True, exist_ok=True)
    SRC_DIR.mkdir(parents=True, exist_ok=True)
    outputs = {
        "ui_skill_slot.png": supersample_slot(False),
        "ui_skill_slot_active.png": supersample_slot(True),
        "ui_base_hp_bar.png": make_hp_track(),
        "ui_bar_fill_hp.png": make_hp_fill(),
    }
    written = []
    for name, image in outputs.items():
        path = UI_DIR / name
        image.save(path)
        written.append(path)
    make_contact(written)
    manifest = {
        "generated_at": "2026-07-10",
        "purpose": "Remove active skill slot horizontal-line artifact and rebuild the battle HP track/fill as empty high-quality raster HUD pieces.",
        "outputs": [str(p.relative_to(ROOT)) for p in written],
        "contact_sheet": "assets/production/contact_sheets/hud_slot_hp_polish_2026_07_10.png",
        "notes": [
            "Skill slots avoid protruding top/bottom line decorations.",
            "HP track is now an empty armored slot; red health is only drawn by the fill texture.",
            "HP fill is designed for a fixed full texture clipped by runtime code instead of being repeatedly squashed by current health ratio.",
        ],
    }
    (SRC_DIR / "hud_slot_hp_polish_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    main()
