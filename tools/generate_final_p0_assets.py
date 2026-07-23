#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import math
import random
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / "assets" / "production"
UI_DIR = PROD / "sprites" / "ui"
APP_DIR = ROOT / "assets" / "app"
STORE_DIR = ROOT / "assets" / "appstore" / "screenshots"
VIDEO_DIR = PROD / "video"
SOURCE_DIR = PROD / "source_refs" / "generated"
OUT_DIR = ROOT / "tmp" / "final_p0_store"

RNG = random.Random(20260701)


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    paths = [
        "/System/Library/Fonts/PingFang.ttc",
        "/System/Library/Fonts/STHeiti Light.ttc",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
    ]
    for path in paths:
        p = Path(path)
        if p.exists():
            try:
                return ImageFont.truetype(str(p), size)
            except Exception:
                continue
    return ImageFont.load_default()


def ensure_dirs() -> None:
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    VIDEO_DIR.mkdir(parents=True, exist_ok=True)


def gradient(size: tuple[int, int], top: tuple[int, int, int, int], bottom: tuple[int, int, int, int]) -> Image.Image:
    w, h = size
    img = Image.new("RGBA", size)
    px = img.load()
    for y in range(h):
        t = y / max(1, h - 1)
        c = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(4))
        for x in range(w):
            px[x, y] = c
    return img


def radial_glow(size: tuple[int, int], center: tuple[float, float], color: tuple[int, int, int, int], radius: float) -> Image.Image:
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    px = img.load()
    cx, cy = center
    for y in range(h):
        for x in range(w):
            d = math.hypot((x - cx) / radius, (y - cy) / radius)
            a = max(0.0, 1.0 - d)
            a = a * a
            if a > 0:
                px[x, y] = (color[0], color[1], color[2], int(color[3] * a))
    return img


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def paste_alpha(dst: Image.Image, src: Image.Image, xy: tuple[int, int] = (0, 0)) -> None:
    dst.alpha_composite(src.convert("RGBA"), xy)


def cover_image(path: Path, size: tuple[int, int]) -> Image.Image:
    im = Image.open(path).convert("RGB")
    return ImageOps.fit(im, size, method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))


def add_noise(img: Image.Image, amount: int = 18) -> Image.Image:
    base = img.convert("RGBA")
    noise = Image.new("RGBA", base.size, (0, 0, 0, 0))
    px = noise.load()
    w, h = base.size
    for y in range(h):
        for x in range(w):
            v = RNG.randint(-amount, amount)
            a = RNG.randint(7, 18)
            if v >= 0:
                px[x, y] = (v, v, v, a)
            else:
                px[x, y] = (0, 0, 0, min(24, -v + a))
    return Image.alpha_composite(base, noise)


def save_png(path: Path, image: Image.Image, mode: str | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    out = image
    if mode:
        out = out.convert(mode)
    out.save(path)


def mix(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(a[i] * (1.0 - t) + b[i] * t) for i in range(3))


def adjust(color: tuple[int, int, int], amount: int) -> tuple[int, int, int]:
    return tuple(max(0, min(255, c + amount)) for c in color)


def metal_texture(size: tuple[int, int], top: tuple[int, int, int, int], bottom: tuple[int, int, int, int], scratches: bool = True) -> Image.Image:
    img = gradient(size, top, bottom)
    img = add_noise(img, 10)
    if scratches:
        d = ImageDraw.Draw(img)
        w, h = size
        for _ in range(max(8, (w * h) // 42000)):
            x = RNG.randint(0, max(0, w - 1))
            y = RNG.randint(0, max(0, h - 1))
            ln = RNG.randint(max(8, w // 28), max(14, w // 9))
            col = (255, 255, 245, RNG.randint(3, 10)) if RNG.random() > 0.48 else (0, 0, 0, RNG.randint(4, 12))
            d.line((x, y, min(w, x + ln), max(0, y + RNG.randint(-2, 2))), fill=col, width=1)
    return img


def stroke_from_mask(mask: Image.Image, width: int) -> Image.Image:
    grown = mask.filter(ImageFilter.MaxFilter(max(3, width * 2 + 1)))
    inner = mask.filter(ImageFilter.MinFilter(max(3, width * 2 + 1)))
    return ImageChops.subtract(grown, inner)


def apply_mask_color(size: tuple[int, int], mask: Image.Image, color: tuple[int, int, int, int]) -> Image.Image:
    layer = Image.new("RGBA", size, color)
    alpha = mask.point(lambda p: int(p * (color[3] / 255.0)))
    layer.putalpha(alpha)
    return layer


def fill_mask_gradient(size: tuple[int, int], mask: Image.Image, top: tuple[int, int, int, int], bottom: tuple[int, int, int, int]) -> Image.Image:
    layer = gradient(size, top, bottom)
    alpha = mask.point(lambda p: int(p * (top[3] / 255.0)))
    layer.putalpha(alpha)
    return layer


def rounded_rect_mask(canvas_size: tuple[int, int], box: tuple[int, int, int, int], radius: int) -> Image.Image:
    mask = Image.new("L", canvas_size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle(box, radius=radius, fill=255)
    return mask


def alpha_composite_masked(dst: Image.Image, layer: Image.Image, mask: Image.Image, xy: tuple[int, int] = (0, 0)) -> None:
    out = layer.convert("RGBA")
    out.putalpha(mask)
    dst.alpha_composite(out, xy)


def draw_beveled_rect(size: tuple[int, int], accent: tuple[int, int, int], secondary: tuple[int, int, int] | None = None, radius: int = 28) -> Image.Image:
    w, h = size
    if secondary is None:
        secondary = (90, 225, 255)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    outer = (10, 8, w - 10, h - 12)
    mid = (18, 16, w - 18, h - 22)
    inner = (30, 28, w - 30, h - 36)

    shadow_mask = rounded_rect_mask(size, outer, radius)
    shadow = apply_mask_color(size, shadow_mask, (0, 0, 0, 168)).filter(ImageFilter.GaussianBlur(15))
    img.alpha_composite(shadow, (0, 8))

    outer_mask = rounded_rect_mask(size, outer, radius)
    metal = metal_texture(size, (74, 78, 76, 255), (13, 17, 22, 255))
    alpha_composite_masked(img, metal, outer_mask)

    mid_mask = rounded_rect_mask(size, mid, max(4, radius - 7))
    mid_fill = metal_texture(size, (38, 47, 52, 248), (7, 11, 16, 250), False)
    alpha_composite_masked(img, mid_fill, mid_mask)

    glass_mask = rounded_rect_mask(size, inner, max(4, radius - 16))
    glass = metal_texture(size, (47, 42, 34, 242), (7, 16, 23, 244), False)
    paste_alpha(glass, radial_glow(size, (w * 0.22, h * 0.08), (255, 176, 82, 56), max(w, h) * 0.54))
    paste_alpha(glass, radial_glow(size, (w * 0.82, h * 0.20), (62, 226, 255, 62), max(w, h) * 0.44))
    alpha_composite_masked(img, glass, glass_mask)

    d = ImageDraw.Draw(img)
    d.rounded_rectangle(outer, radius=radius, outline=(190, 198, 202, 178), width=3)
    d.rounded_rectangle(mid, radius=max(4, radius - 7), outline=(accent[0], accent[1], accent[2], 230), width=4)
    d.rounded_rectangle(inner, radius=max(4, radius - 16), outline=(secondary[0], secondary[1], secondary[2], 130), width=2)
    d.line((inner[0] + 16, inner[1] + 2, inner[2] - 16, inner[1] + 2), fill=(255, 248, 224, 114), width=2)
    d.line((inner[0] + 16, inner[3] - 2, inner[2] - 16, inner[3] - 2), fill=(0, 0, 0, 130), width=2)
    cap = max(16, min(w, h) // 4)
    for sx, sy, ex, ey in [
        (mid[0], mid[1], mid[0] + cap, mid[1]),
        (mid[2] - cap, mid[1], mid[2], mid[1]),
        (mid[0], mid[3], mid[0] + cap, mid[3]),
        (mid[2] - cap, mid[3], mid[2], mid[3]),
    ]:
        d.line((sx, sy, ex, ey), fill=(255, 154, 54, 185), width=3)
    if w > 260 and h > 110:
        for x in range(w // 2 - 34, w // 2 + 35, 17):
            d.rounded_rectangle((x, h - 25, x + 9, h - 20), radius=2, fill=(255, 183, 58, 160))
    return img


def make_button(path: Path, primary: bool) -> None:
    if primary:
        img = draw_beveled_rect((512, 160), (255, 154, 48), (73, 232, 242), 34)
        paste_alpha(img, radial_glow((512, 160), (252, 76), (64, 220, 214, 80), 210))
    else:
        img = draw_beveled_rect((512, 160), (146, 156, 156), (79, 199, 228), 34)
        paste_alpha(img, gradient((512, 160), (0, 0, 0, 18), (0, 0, 0, 54)))
    d = ImageDraw.Draw(img)
    d.line((72, 50, 440, 50), fill=(255, 255, 230, 34 if primary else 24), width=1)
    d.line((72, 110, 440, 110), fill=(0, 0, 0, 54), width=1)
    save_png(path, img, "RGBA")


def make_panel(path: Path) -> None:
    img = draw_beveled_rect((640, 420), (230, 150, 58), (68, 220, 245), 26)
    d = ImageDraw.Draw(img)
    for i in range(7):
        y = 72 + i * 42
        d.line((64, y, 576, y), fill=(130, 180, 200, 22), width=1)
    for x, y in [(34, 34), (576, 34), (34, 352), (576, 352)]:
        d.ellipse((x, y, x + 10, y + 10), fill=(190, 196, 196, 80))
    save_png(path, img, "RGBA")


def make_bar(path: Path, accent: tuple[int, int, int]) -> None:
    w, h = 640, 96
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    mask = rounded_rect_mask((w, h), (10, 18, w - 10, h - 16), 24)
    shadow = apply_mask_color((w, h), mask, (0, 0, 0, 170)).filter(ImageFilter.GaussianBlur(10))
    img.alpha_composite(shadow, (0, 6))
    metal = metal_texture((w, h), (48, 52, 52, 255), (8, 11, 15, 255))
    alpha_composite_masked(img, metal, mask)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((10, 18, w - 10, h - 16), radius=24, outline=(188, 196, 198, 142), width=3)
    d.rounded_rectangle((30, 30, w - 30, h - 28), radius=16, fill=(2, 6, 10, 232), outline=(*accent, 210), width=3)
    d.rounded_rectangle((46, 39, w - 46, h - 39), radius=9, fill=(0, 2, 5, 245), outline=(255, 255, 240, 34), width=1)
    d.line((56, 41, w - 56, 41), fill=(255, 255, 255, 42), width=1)
    for i in range(8):
        x = 70 + i * 20
        d.polygon([(x, 35), (x + 13, 35), (x + 8, 46), (x - 5, 46)], fill=(*accent, 130 if i < 5 else 42))
    paste_alpha(img, radial_glow((w, h), (w * 0.2, h * 0.5), (*accent, 70), 220))
    save_png(path, img, "RGBA")


def make_badge_base(size: int = 256, accent: tuple[int, int, int] = (255, 145, 45)) -> Image.Image:
    img = draw_beveled_rect((size, size), accent, (74, 214, 238), max(18, size // 5))
    paste_alpha(img, radial_glow((size, size), (size * 0.50, size * 0.52), (*accent, 38), size * 0.48))
    d = ImageDraw.Draw(img)
    inset = int(size * 0.18)
    d.rounded_rectangle((inset, inset, size - inset, size - inset), radius=max(10, size // 8), fill=(4, 8, 12, 72), outline=(255, 245, 214, 28), width=max(1, size // 128))
    return img


def symbol_mask(name: str, size: int = 256) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    cx, cy = 128, 128
    if name in {"gold", "talent"}:
        d.ellipse((70, 70, 186, 186), fill=255)
        d.ellipse((92, 92, 164, 164), fill=0)
        d.ellipse((106, 106, 150, 150), fill=255)
        d.line((128, 82, 128, 174), fill=255, width=5)
    elif name == "xp":
        d.polygon([(128, 48), (207, 128), (128, 208), (49, 128)], fill=255)
        d.ellipse((103, 103, 153, 153), fill=0)
        d.ellipse((114, 114, 142, 142), fill=255)
    elif name == "star" or name == "star_filled":
        pts = []
        for i in range(10):
            a = -math.pi / 2 + i * math.pi / 5
            r = 78 if i % 2 == 0 else 34
            pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
        if name == "star_filled":
            d.polygon(pts, fill=255)
        else:
            d.line(pts + [pts[0]], fill=255, width=12, joint="curve")
    elif name == "pause":
        d.rounded_rectangle((80, 62, 112, 194), radius=9, fill=255)
        d.rounded_rectangle((144, 62, 176, 194), radius=9, fill=255)
    elif name == "settings":
        for i in range(8):
            a = i * math.pi / 4
            d.line((cx + math.cos(a) * 36, cy + math.sin(a) * 36, cx + math.cos(a) * 78, cy + math.sin(a) * 78), fill=255, width=14)
        d.ellipse((74, 74, 182, 182), fill=255)
        d.ellipse((106, 106, 150, 150), fill=0)
    elif name == "lock":
        d.rounded_rectangle((66, 112, 190, 192), radius=15, fill=255)
        d.arc((82, 54, 174, 150), 190, 350, fill=255, width=20)
        d.rectangle((102, 100, 154, 126), fill=255)
    elif name == "warning":
        d.polygon([(128, 44), (215, 200), (41, 200)], fill=255)
        d.rounded_rectangle((118, 94, 138, 150), radius=6, fill=0)
        d.ellipse((117, 164, 139, 186), fill=0)
    elif name == "fire":
        d.polygon([(132, 50), (188, 130), (148, 207), (76, 178), (66, 118)], fill=255)
        d.polygon([(118, 112), (150, 150), (126, 190), (94, 166)], fill=0)
    elif name == "ice":
        for i in range(6):
            a = i * math.pi / 3
            d.line((cx, cy, cx + math.cos(a) * 80, cy + math.sin(a) * 80), fill=255, width=10)
        d.ellipse((110, 110, 146, 146), fill=255)
    elif name == "lightning":
        d.polygon([(148, 40), (88, 132), (132, 132), (108, 216), (181, 103), (136, 103)], fill=255)
    elif name == "poison":
        d.ellipse((72, 96, 194, 178), fill=255)
        d.ellipse((116, 108, 148, 140), fill=0)
        d.ellipse((154, 94, 174, 114), fill=0)
    elif name == "physical":
        d.polygon([(72, 82), (144, 52), (190, 120), (112, 207)], fill=255)
        d.polygon([(104, 104), (142, 88), (166, 123), (124, 168)], fill=0)
    elif name == "card_projectile":
        d.line((60, 128, 194, 128), fill=255, width=18)
        d.polygon([(198, 128), (154, 96), (154, 160)], fill=255)
    elif name == "card_control":
        d.line((76, 76, 180, 180), fill=255, width=10)
        d.line((180, 76, 76, 180), fill=255, width=10)
        d.ellipse((98, 98, 158, 158), outline=255, width=7)
    elif name == "card_economy":
        d.ellipse((68, 82, 156, 170), fill=255)
        d.rectangle((122, 104, 190, 176), fill=255)
        d.polygon([(122, 104), (156, 70), (190, 104)], fill=255)
    elif name == "strategy_breach":
        d.ellipse((70, 70, 186, 186), outline=255, width=12)
        d.ellipse((106, 106, 150, 150), fill=255)
        d.line((128, 40, 128, 76), fill=255, width=8)
        d.line((128, 180, 128, 216), fill=255, width=8)
        d.line((40, 128, 76, 128), fill=255, width=8)
        d.line((180, 128, 216, 128), fill=255, width=8)
    elif name == "strategy_nearest":
        d.line((60, 128, 194, 128), fill=255, width=13)
        d.polygon([(198, 128), (158, 98), (158, 158)], fill=255)
    elif name == "strategy_elite":
        d.polygon([(128, 56), (176, 176), (128, 148), (80, 176)], fill=255)
        d.polygon([(86, 84), (170, 84), (148, 128), (108, 128)], fill=0)
    elif name == "strategy_low_hp":
        d.ellipse((62, 72, 136, 146), fill=255)
        d.ellipse((120, 72, 194, 146), fill=255)
        d.polygon([(62, 118), (194, 118), (128, 210)], fill=255)
        d.line((70, 142, 112, 142, 128, 104, 152, 166, 186, 166), fill=0, width=8)
    elif name == "reroll":
        d.arc((66, 68, 190, 192), 30, 315, fill=255, width=14)
        d.polygon([(172, 68), (207, 72), (184, 104)], fill=255)
    elif name == "skip":
        d.polygon([(76, 62), (144, 128), (76, 194)], fill=255)
        d.polygon([(136, 62), (204, 128), (136, 194)], fill=255)
    elif name == "pin":
        d.polygon([(96, 52), (178, 52), (158, 128), (138, 128), (128, 208), (118, 128), (96, 128)], fill=255)
    else:
        d.ellipse((82, 82, 174, 174), fill=255)
    return mask


def render_symbol(mask: Image.Image, accent: tuple[int, int, int]) -> Image.Image:
    size = mask.size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    glow = apply_mask_color(size, mask.filter(ImageFilter.GaussianBlur(9)), (*accent, 72))
    img.alpha_composite(glow)
    shadow = apply_mask_color(size, mask, (0, 0, 0, 170)).filter(ImageFilter.GaussianBlur(4))
    img.alpha_composite(shadow, (5, 7))
    fill = fill_mask_gradient(size, mask, (*adjust(accent, 46), 255), (*adjust(accent, -34), 255))
    img.alpha_composite(fill)
    edge = mask.filter(ImageFilter.FIND_EDGES).filter(ImageFilter.GaussianBlur(0.4))
    img.alpha_composite(apply_mask_color(size, edge, (255, 255, 242, 118)))
    img.alpha_composite(apply_mask_color(size, edge, (0, 0, 0, 118)), (2, 3))
    paste_alpha(img, radial_glow(size, (size[0] * 0.38, size[1] * 0.22), (255, 255, 230, 58), size[0] * 0.34))
    return img


def draw_symbol(name: str, accent: tuple[int, int, int]) -> Image.Image:
    size = 256
    img = make_badge_base(size, accent)
    img.alpha_composite(render_symbol(symbol_mask(name, size), accent))
    detail = Image.new("L", (size, size), 0)
    dd = ImageDraw.Draw(detail)
    detail_accent: tuple[int, int, int] | None = None
    if name == "fire":
        dd.polygon([(118, 112), (150, 150), (126, 190), (94, 166)], fill=255)
        detail_accent = (255, 225, 72)
    elif name == "xp":
        dd.ellipse((112, 112, 144, 144), fill=255)
        detail_accent = (215, 244, 255)
    elif name == "poison":
        dd.ellipse((116, 108, 148, 140), fill=255)
        dd.ellipse((154, 94, 174, 114), fill=220)
        detail_accent = (230, 255, 150)
    elif name == "physical":
        dd.polygon([(104, 104), (142, 88), (166, 123), (124, 168)], fill=255)
        detail_accent = (245, 250, 255)
    elif name == "strategy_elite":
        dd.polygon([(86, 84), (170, 84), (148, 128), (108, 128)], fill=255)
        detail_accent = (255, 118, 74)
    elif name == "strategy_low_hp":
        dd.line((70, 142, 112, 142, 128, 104, 152, 166, 186, 166), fill=255, width=8)
        detail_accent = (255, 245, 118)
    if detail_accent is not None:
        img.alpha_composite(render_symbol(detail, detail_accent))
    return img


def make_card_frame(path: Path, accent: tuple[int, int, int]) -> None:
    w, h = 360, 500
    img = draw_beveled_rect((w, h), accent, (70, 210, 235), 30)
    paste_alpha(img, radial_glow((w, h), (w * 0.5, h * 0.35), (*accent, 42), 220))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((42, 58, w - 42, h - 74), radius=14, fill=(2, 7, 12, 118), outline=(255, 255, 232, 26), width=1)
    d.line((54, 66, w - 54, 66), fill=(*accent, 140), width=3)
    d.line((54, h - 82, w - 54, h - 82), fill=(*accent, 105), width=3)
    for x, y in [(34, 34), (w - 54, 34), (34, h - 54), (w - 54, h - 54)]:
        d.rounded_rectangle((x, y, x + 20, y + 20), radius=4, fill=(0, 0, 0, 74), outline=(*accent, 130), width=2)
    save_png(path, img, "RGBA")


def make_skill_slot(path: Path, active: bool) -> None:
    accent = (255, 162, 54) if active else (86, 202, 238)
    img = draw_beveled_rect((220, 220), accent, (72, 220, 238), 42)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((48, 48, 172, 172), radius=24, fill=(4, 8, 12, 190), outline=(*accent, 128), width=3)
    d.rounded_rectangle((63, 63, 157, 157), radius=18, outline=(255, 245, 220, 34), width=1)
    if active:
        paste_alpha(img, radial_glow((220, 220), (110, 110), (255, 122, 38, 112), 96))
    save_png(path, img, "RGBA")


def make_target_lock(path: Path) -> None:
    size = 256
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    accent = (122, 248, 238)
    paste_alpha(img, radial_glow((size, size), (128, 128), (*accent, 94), 126))
    for radius, alpha, width in [(190, 210, 8), (142, 125, 4), (92, 78, 3)]:
        box = ((size - radius) // 2, (size - radius) // 2, (size + radius) // 2, (size + radius) // 2)
        for start in [0, 90, 180, 270]:
            d.arc(box, start + 10, start + 70, fill=(*accent, alpha), width=width)
    d.ellipse((112, 112, 144, 144), fill=(*accent, 42))
    for x1, y1, x2, y2 in [
        (128, 28, 128, 72),
        (128, 184, 128, 228),
        (28, 128, 72, 128),
        (184, 128, 228, 128),
    ]:
        d.line((x1, y1, x2, y2), fill=(*accent, 230), width=6)
        d.line((x1, y1, x2, y2), fill=(255, 255, 255, 80), width=2)
    save_png(path, img, "RGBA")


def generate_ui_assets() -> None:
    make_button(UI_DIR / "ui_button_primary.png", True)
    make_button(UI_DIR / "ui_button_secondary.png", False)
    make_panel(UI_DIR / "ui_panel.png")
    make_bar(UI_DIR / "ui_base_hp_bar.png", (255, 82, 72))
    make_bar(UI_DIR / "ui_wave_progress.png", (255, 174, 64))
    make_bar(UI_DIR / "ui_run_xp_bar.png", (78, 170, 255))
    make_bar(UI_DIR / "ui_shield_bar.png", (82, 226, 245))
    make_card_frame(UI_DIR / "ui_card_frame.png", (228, 164, 82))
    make_card_frame(UI_DIR / "ui_card_frame_fire.png", (255, 88, 42))
    make_card_frame(UI_DIR / "ui_card_frame_ice.png", (70, 198, 255))
    make_card_frame(UI_DIR / "ui_card_frame_lightning.png", (255, 225, 74))
    make_card_frame(UI_DIR / "ui_card_frame_physical.png", (218, 226, 235))
    make_card_frame(UI_DIR / "ui_card_frame_poison.png", (139, 224, 78))
    make_skill_slot(UI_DIR / "ui_skill_slot.png", False)
    make_skill_slot(UI_DIR / "ui_skill_slot_active.png", True)
    make_target_lock(UI_DIR / "ui_target_lock.png")
    make_target_lock(PROD / "sprites" / "vfx" / "vfx_target_lock.png")
    overlay = Image.new("RGBA", (220, 220), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    d.ellipse((10, 10, 210, 210), fill=(0, 0, 0, 142), outline=(92, 210, 240, 145), width=4)
    save_png(UI_DIR / "ui_cd_overlay.png", overlay, "RGBA")

    icon_specs = {
        "icon_currency_gold.png": ("gold", (255, 194, 64)),
        "icon_currency_xp.png": ("xp", (74, 164, 255)),
        "icon_currency_star.png": ("star", (255, 210, 72)),
        "icon_talent_point.png": ("talent", (255, 150, 58)),
        "icon_pause.png": ("pause", (220, 232, 245)),
        "icon_settings.png": ("settings", (220, 232, 245)),
        "icon_lock.png": ("lock", (220, 232, 245)),
        "icon_reroll_charge.png": ("reroll", (86, 226, 245)),
        "icon_warning.png": ("warning", (255, 210, 72)),
        "icon_element_fire.png": ("fire", (255, 87, 34)),
        "icon_element_ice.png": ("ice", (70, 198, 255)),
        "icon_element_lightning.png": ("lightning", (255, 225, 74)),
        "icon_element_physical.png": ("physical", (217, 222, 229)),
        "icon_element_poison.png": ("poison", (139, 224, 78)),
        "ui_star_filled.png": ("star_filled", (255, 211, 72)),
        "ui_star_empty.png": ("star", (130, 142, 154)),
        "ui_card_tag_projectile.png": ("card_projectile", (90, 190, 255)),
        "ui_card_tag_control.png": ("card_control", (86, 226, 245)),
        "ui_card_tag_element.png": ("lightning", (255, 225, 74)),
        "ui_card_tag_economy.png": ("card_economy", (255, 190, 62)),
        "ui_target_strategy_breach.png": ("strategy_breach", (255, 194, 64)),
        "ui_target_strategy_nearest.png": ("strategy_nearest", (220, 232, 245)),
        "ui_target_strategy_elite.png": ("strategy_elite", (255, 108, 68)),
        "ui_target_strategy_low_hp.png": ("strategy_low_hp", (255, 82, 86)),
        "ui_card_reroll.png": ("reroll", (86, 226, 245)),
        "ui_card_skip.png": ("skip", (220, 232, 245)),
        "ui_card_pin.png": ("pin", (255, 194, 64)),
    }
    for filename, (symbol, accent) in icon_specs.items():
        save_png(UI_DIR / filename, draw_symbol(symbol, accent), "RGBA")


def copy_launch_source(imagegen_source: Path | None) -> Path | None:
    prompt_path = SOURCE_DIR / "final_p0_launch_source_prompt_2026_07_01.txt"
    prompt_path.write_text(
        "\n".join(
            [
                "High-end 3D rendered vertical launch poster for Zombie Fire.",
                "Fixed bottom autocannon defending a ruined cyberpunk city from a zombie horde.",
                "Orange fire, cyan tech accents, green zombie eyes, 2.5D cartoon-realistic mobile game key art.",
                "No text, no watermark, no UI panels, no app-store badges.",
            ]
        ),
        encoding="utf-8",
    )
    if imagegen_source and imagegen_source.exists():
        dest = SOURCE_DIR / "final_p0_launch_source_2026_07_01.png"
        if imagegen_source.resolve() != dest.resolve():
            shutil.copy2(imagegen_source, dest)
        return dest
    fallback = SOURCE_DIR / "final_p0_launch_source_2026_07_01.png"
    return fallback if fallback.exists() else None


def generate_launch(source: Path | None) -> None:
    if source and source.exists():
        bg = cover_image(source, (1080, 1920)).convert("RGBA")
    else:
        bg = cover_image(PROD / "sprites" / "backgrounds" / "bg_lava_foundry.png", (1080, 1920)).convert("RGBA")
    paste_alpha(bg, gradient((1080, 1920), (0, 0, 0, 70), (0, 0, 0, 168)))
    paste_alpha(bg, radial_glow((1080, 1920), (540, 1510), (255, 116, 28, 70), 520))
    paste_alpha(bg, radial_glow((1080, 1920), (820, 300), (70, 220, 255, 32), 520))
    d = ImageDraw.Draw(bg)
    d.rounded_rectangle((214, 1622, 866, 1642), radius=10, fill=(8, 14, 18, 190), outline=(255, 138, 42, 150), width=2)
    d.rounded_rectangle((254, 1628, 826, 1636), radius=4, fill=(255, 138, 42, 180))
    save_png(APP_DIR / "launch_1080x1920.png", bg, "RGB")


def fit_inside(path: Path, size: tuple[int, int]) -> Image.Image:
    im = Image.open(path).convert("RGBA")
    im.thumbnail(size, Image.Resampling.LANCZOS)
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    out.alpha_composite(im, ((size[0] - im.width) // 2, (size[1] - im.height) // 2))
    return out


def make_runtime_skill_cards(size: tuple[int, int]) -> Image.Image:
    w, h = size
    img = cover_image(PROD / "sprites" / "backgrounds" / "bg_lava_foundry.png", size).convert("RGBA")
    paste_alpha(img, gradient(size, (0, 0, 0, 115), (0, 0, 0, 178)))
    d = ImageDraw.Draw(img)
    title_font = load_font(max(38, w // 28), True)
    d.text((w // 2, int(h * 0.16)), "局内三选一", anchor="mm", fill=(255, 238, 210), font=title_font, stroke_width=4, stroke_fill=(0, 0, 0))
    icons = ["skill_split_shot_icon.png", "skill_pierce_icon.png", "skill_slow_field_icon.png"]
    card_w = int(w * 0.255)
    card_h = int(card_w * 1.38)
    start_x = (w - card_w * 3 - int(w * 0.035) * 2) // 2
    y = int(h * 0.33)
    names = ["分裂弹", "穿透强化", "减速场"]
    for i, icon in enumerate(icons):
        x = start_x + i * (card_w + int(w * 0.035))
        frame = Image.open(UI_DIR / "ui_card_frame.png").convert("RGBA").resize((card_w, card_h), Image.Resampling.LANCZOS)
        img.alpha_composite(frame, (x, y))
        ic = fit_inside(UI_DIR / icon, (int(card_w * 0.48), int(card_w * 0.48)))
        img.alpha_composite(ic, (x + int(card_w * 0.26), y + int(card_h * 0.16)))
        name_font = load_font(max(22, w // 44), True)
        small_font = load_font(max(16, w // 64))
        d.text((x + card_w // 2, y + int(card_h * 0.66)), names[i], anchor="mm", fill=(246, 236, 210), font=name_font, stroke_width=2, stroke_fill=(0, 0, 0))
        d.text((x + card_w // 2, y + int(card_h * 0.77)), "升级后立刻改变弹幕", anchor="mm", fill=(178, 219, 226), font=small_font, stroke_width=1, stroke_fill=(0, 0, 0))
    return img.convert("RGB")


def screenshot_source(route: str, screens_dir: Path) -> Path | None:
    candidates = {
        "battle": ["battle.png", "01_battle.png"],
        "map": ["map.png", "02_map.png"],
        "skills": ["skills.png", "03_skills.png"],
        "loadout": ["loadout.png", "04_loadout.png"],
        "boss": ["05_boss.png", "boss.png"],
    }
    for name in candidates.get(route, []):
        p = screens_dir / name
        if p.exists():
            return p
    legacy = ROOT / "tmp" / "art_audit" / "current_screens" / (route if route != "boss" else "battle")
    legacy = legacy.with_suffix(".png")
    return legacy if legacy.exists() else None


def draw_store_art(screen: Image.Image, target_size: tuple[int, int], headline: str, sub: str, badge: str) -> Image.Image:
    w, h = target_size
    bg_source = SOURCE_DIR / "final_p0_launch_source_2026_07_01.png"
    if bg_source.exists():
        bg = cover_image(bg_source, target_size).convert("RGBA")
    else:
        bg = cover_image(PROD / "sprites" / "backgrounds" / "bg_lava_foundry.png", target_size).convert("RGBA")
    paste_alpha(bg, gradient(target_size, (0, 0, 0, 112), (0, 0, 0, 210)))
    d = ImageDraw.Draw(bg)
    title_font = load_font(int(w * 0.066), True)
    sub_font = load_font(int(w * 0.031))
    badge_font = load_font(int(w * 0.026), True)
    top = int(h * 0.075)
    d.text((int(w * 0.08), top), headline, fill=(255, 238, 215), font=title_font, stroke_width=max(2, w // 380), stroke_fill=(0, 0, 0))
    d.text((int(w * 0.08), top + int(w * 0.086)), sub, fill=(174, 225, 232), font=sub_font, stroke_width=max(1, w // 720), stroke_fill=(0, 0, 0))
    bx, by = int(w * 0.08), top + int(w * 0.145)
    badge_box = d.textbbox((0, 0), badge, font=badge_font)
    badge_text_w = badge_box[2] - badge_box[0]
    badge_h = int(w * 0.057)
    badge_pad_x = int(w * 0.026)
    badge_w = badge_text_w + badge_pad_x * 2
    d.rounded_rectangle(
        (bx, by, bx + badge_w, by + badge_h),
        radius=int(badge_h * 0.48),
        fill=(10, 20, 28, 232),
        outline=(255, 139, 45, 210),
        width=max(2, w // 430),
    )
    d.rounded_rectangle(
        (bx + 5, by + 5, bx + int(w * 0.011), by + badge_h - 5),
        radius=max(2, w // 900),
        fill=(255, 143, 47, 245),
    )
    d.text(
        (bx + badge_pad_x + int(w * 0.006), by + badge_h // 2),
        badge,
        anchor="lm",
        fill=(255, 205, 112),
        font=badge_font,
    )

    phone_w = int(w * (0.72 if w < 1600 else 0.58))
    source_aspect = screen.height / max(screen.width, 1)
    phone_h = int(phone_w * source_aspect)
    if phone_h > int(h * 0.67):
        phone_h = int(h * 0.67)
        phone_w = int(phone_h / source_aspect)
    phone_x = (w - phone_w) // 2
    phone_y = int(h * 0.29)
    shadow = Image.new("RGBA", target_size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((phone_x + 16, phone_y + 24, phone_x + phone_w + 16, phone_y + phone_h + 24), radius=int(phone_w * 0.06), fill=(0, 0, 0, 180))
    shadow = shadow.filter(ImageFilter.GaussianBlur(int(w * 0.018)))
    paste_alpha(bg, shadow)
    frame = Image.new("RGBA", (phone_w, phone_h), (0, 0, 0, 0))
    mask = rounded_mask((phone_w, phone_h), int(phone_w * 0.055))
    shot = ImageOps.fit(screen.convert("RGB"), (phone_w, phone_h), method=Image.Resampling.LANCZOS).convert("RGBA")
    shot.putalpha(mask)
    frame.alpha_composite(shot, (0, 0))
    fd = ImageDraw.Draw(frame)
    fd.rounded_rectangle((0, 0, phone_w - 1, phone_h - 1), radius=int(phone_w * 0.055), outline=(255, 145, 50, 230), width=max(5, w // 180))
    fd.rounded_rectangle((12, 12, phone_w - 13, phone_h - 13), radius=int(phone_w * 0.045), outline=(95, 220, 255, 90), width=max(2, w // 600))
    bg.alpha_composite(frame, (phone_x, phone_y))
    return bg.convert("RGB")


def generate_store_screens(screens_dir: Path) -> None:
    routes = [
        ("battle", "尸潮压境，一炮清场", "固定防线自动开火，手动锁定关键目标", "战斗核心"),
        ("map", "99关防线，逐章推进", "章节路线、星级目标、长期成长一屏掌握", "关卡推进"),
        ("skills", "三选一成型，局内质变", "分裂、穿透、减速场组合成你的弹幕流派", "肉鸽选卡"),
        ("loadout", "角色武器配装，开局定流派", "角色、主炮、护甲、芯片、宠物共同影响战局", "战前构筑"),
        ("boss", "Boss机制压迫，破甲反击", "高威胁目标清晰提示，打出关键破局", "Boss战"),
    ]
    sizes = {
        "ios_65": (1242, 2688),
        "ios_67": (1290, 2796),
    }
    route_images: dict[str, Image.Image] = {}
    for route, *_ in routes:
        src = screenshot_source(route, screens_dir)
        if src is None:
            route_images[route] = (
                make_runtime_skill_cards((1080, 1920))
                if route == "skills"
                else cover_image(APP_DIR / "launch_1080x1920.png", (1080, 1920))
            )
        else:
            route_images[route] = Image.open(src).convert("RGB")
    for folder, size in sizes.items():
        out_dir = STORE_DIR / folder
        out_dir.mkdir(parents=True, exist_ok=True)
        for idx, (route, headline, sub, badge) in enumerate(routes, start=1):
            out = draw_store_art(route_images[route], size, headline, sub, badge)
            out.save(out_dir / f"{idx:02d}_{'skills' if route == 'skills' else route}.png")
    root_map = [
        ("battle", "01_core_loop_1290x2796.png", "尸潮压境，一炮清场", "固定防线自动开火，手动锁定关键目标", "战斗核心"),
        ("map", "02_chapter_map_1290x2796.png", "99关防线，逐章推进", "章节路线、星级目标、长期成长一屏掌握", "关卡推进"),
        ("skills", "03_skill_cards_1290x2796.png", "三选一成型，局内质变", "分裂、穿透、减速场组合成你的弹幕流派", "肉鸽选卡"),
    ]
    for route, filename, headline, sub, badge in root_map:
        draw_store_art(route_images[route], (1080, 1920), headline, sub, badge).save(STORE_DIR / filename)


def make_preview_video(screens_dir: Path) -> None:
    _ = screens_dir
    subprocess.run([sys.executable, str(ROOT / "tools/build_app_preview.py")], cwd=ROOT, check=True)


def make_contact_sheet() -> None:
    paths = [
        APP_DIR / "launch_1080x1920.png",
        UI_DIR / "ui_button_primary.png",
        UI_DIR / "ui_button_secondary.png",
        UI_DIR / "ui_panel.png",
        UI_DIR / "ui_base_hp_bar.png",
        UI_DIR / "ui_wave_progress.png",
        UI_DIR / "icon_currency_gold.png",
        UI_DIR / "icon_pause.png",
        UI_DIR / "icon_settings.png",
        UI_DIR / "icon_warning.png",
        UI_DIR / "icon_reroll_charge.png",
        UI_DIR / "icon_element_fire.png",
        UI_DIR / "ui_card_frame.png",
        UI_DIR / "ui_target_strategy_breach.png",
        UI_DIR / "ui_skill_slot_active.png",
        PROD / "sprites" / "vfx" / "vfx_target_lock.png",
        STORE_DIR / "ios_67" / "01_battle.png",
        STORE_DIR / "ios_67" / "03_skills.png",
    ]
    cols, tw, th, gap = 4, 260, 210, 18
    rows = math.ceil(len(paths) / cols)
    sheet = Image.new("RGB", (32 * 2 + cols * tw + (cols - 1) * gap, 72 + rows * (th + 46 + gap)), (16, 20, 26))
    d = ImageDraw.Draw(sheet)
    d.text((32, 24), "Top-Tier P0 HUD / Store Art Contact Sheet", fill=(238, 242, 248), font=load_font(28, True))
    for i, p in enumerate(paths):
        x = 32 + (i % cols) * (tw + gap)
        y = 72 + (i // cols) * (th + 46 + gap)
        d.rounded_rectangle((x - 1, y - 1, x + tw + 1, y + th + 43), radius=8, fill=(28, 34, 42), outline=(84, 96, 112))
        if p.exists():
            im = Image.open(p).convert("RGBA")
            im.thumbnail((tw - 16, th - 16), Image.Resampling.LANCZOS)
            temp = Image.new("RGBA", (tw, th), (20, 25, 32, 255))
            temp.alpha_composite(im, ((tw - im.width) // 2, (th - im.height) // 2))
            sheet.paste(temp.convert("RGB"), (x, y))
        d.text((x + 8, y + th + 8), str(p.relative_to(ROOT))[:42], fill=(184, 194, 206), font=load_font(12))
    sheet.save(SOURCE_DIR / "final_p0_replacement_contact_sheet_2026_07_01.png")


def update_index() -> None:
    path = PROD / "OUTSOURCER_ASSET_INDEX.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    overrides = data.setdefault("owner_directed_generated_overrides", [])
    entries = [
        {
            "path": "../app/launch_1080x1920.png",
            "source": "source_refs/generated/final_p0_launch_source_prompt_2026_07_01.txt",
            "derived": "source_refs/generated/final_p0_launch_source_2026_07_01.png",
            "reason": "Owner approved P0 final-art replacement for launch image to match the high-end rendered app icon and App Store presentation bar.",
        },
        {
            "path": "sprites/ui",
            "source": "source_refs/generated/final_p0_ui_store_spec_2026_07_01.json",
            "derived": "source_refs/generated/final_p0_replacement_contact_sheet_2026_07_01.png",
            "reason": "Owner approved P0 final-art replacement for flat UI kit assets with premium dark-metal HUD controls, icons, panels, bars, card frames, and strategy badges.",
        },
        {
            "path": "sprites/vfx/vfx_target_lock.png",
            "source": "source_refs/generated/final_p0_ui_store_spec_2026_07_01.json",
            "derived": "source_refs/generated/final_p0_replacement_contact_sheet_2026_07_01.png",
            "reason": "Owner approved P0 replacement for the visible runtime target-lock ring after legacy references were migrated to production assets.",
        },
        {
            "path": "../appstore/screenshots",
            "source": "source_refs/generated/final_p0_ui_store_spec_2026_07_01.json",
            "derived": "source_refs/generated/final_p0_replacement_contact_sheet_2026_07_01.png",
            "reason": "Owner approved P0 App Store screenshot draft regeneration after UI final-art pass.",
        },
		{
			"path": "video/vid_app_preview.mp4",
			"source": "video/vid_app_preview_provenance.json",
			"derived": "video/vid_app_preview.mp4",
			"reason": "Launch App Preview rebuilt as a curated 22-second live Godot runtime capture with clear auto-fire, manual lock, card choice, boss phase, active skill, adaptive combat-label density, and game audio.",
		},
    ]
    existing = {entry.get("path") for entry in overrides}
    for entry in entries:
        if entry["path"] not in existing:
            overrides.append(entry)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def write_spec() -> None:
    spec = {
        "date": "2026-07-01",
        "scope": "P0 top-tier polish pass for launch image, App Store screenshots, app preview, flat UI kit, visible target lock, and legacy visible asset integration.",
        "style": "2.5D cartoon-realistic, premium 3D-rendered dark gunmetal HUD, beveled glass, orange warning edge lights, cyan tech rim lights, ruined-city/cyberpunk presentation.",
        "reference_sources": [
            "source_refs/generated/final_p0_launch_source_2026_07_01.png",
            "source_refs/generated/final_p0_hud_reference_source_2026_07_01.png"
        ],
        "generated_with": [
            "built-in image_gen for launch key art source",
            "built-in image_gen for top-tier HUD material reference source",
            "local Pillow rendering for exact-size UI/store composites",
            "ffmpeg for app preview mp4"
        ],
        "constraints": ["keep existing IDs and integration paths", "do not change gameplay scope", "do not alter data/*.json content lists"],
    }
    (SOURCE_DIR / "final_p0_ui_store_spec_2026_07_01.json").write_text(json.dumps(spec, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--imagegen-source", type=Path)
    parser.add_argument("--screens-dir", type=Path, default=ROOT / "tmp" / "final_p0_runtime_screens")
    parser.add_argument("--skip-store", action="store_true")
    args = parser.parse_args()

    ensure_dirs()
    source = copy_launch_source(args.imagegen_source)
    generate_ui_assets()
    generate_launch(source)
    write_spec()
    if not args.skip_store:
        generate_store_screens(args.screens_dir)
        make_preview_video(args.screens_dir)
    make_contact_sheet()
    update_index()
    print("Final P0 assets generated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
