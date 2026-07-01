#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import math
import random
import shutil
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps


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


def draw_beveled_rect(size: tuple[int, int], accent: tuple[int, int, int], secondary: tuple[int, int, int] | None = None, radius: int = 28) -> Image.Image:
    w, h = size
    if secondary is None:
        secondary = (90, 225, 255)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((18, 18, w - 18, h - 14), radius=radius, fill=(0, 0, 0, 145))
    shadow = shadow.filter(ImageFilter.GaussianBlur(14))
    paste_alpha(img, shadow)

    body = gradient(size, (30, 39, 48, 245), (9, 13, 19, 246))
    body = add_noise(body, 9)
    mask = rounded_mask((w - 28, h - 30), radius)
    clipped = body.crop((14, 10, w - 14, h - 20))
    clipped.putalpha(mask)
    img.alpha_composite(clipped, (14, 10))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((14, 10, w - 14, h - 20), radius=radius, outline=(accent[0], accent[1], accent[2], 220), width=5)
    d.rounded_rectangle((22, 18, w - 22, h - 28), radius=max(4, radius - 8), outline=(secondary[0], secondary[1], secondary[2], 95), width=2)
    d.line((34, 22, w - 34, 22), fill=(255, 230, 178, 120), width=2)
    paste_alpha(img, radial_glow(size, (w * 0.25, h * 0.1), (255, 170, 70, 90), max(w, h) * 0.55))
    paste_alpha(img, radial_glow(size, (w * 0.8, h * 0.25), (65, 220, 255, 65), max(w, h) * 0.5))
    return img


def make_button(path: Path, primary: bool) -> None:
    size = (512, 160)
    w, h = size
    radius = 34
    img = Image.new("RGBA", size, (0, 0, 0, 0))

    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((20, 22, w - 20, h - 14), radius=radius, fill=(0, 0, 0, 170))
    shadow = shadow.filter(ImageFilter.GaussianBlur(15))
    paste_alpha(img, shadow)

    if primary:
        body_top = (38, 132, 124, 250)
        body_bottom = (20, 72, 82, 252)
        cyan_edge = (96, 232, 226, 235)
        warm_edge = (255, 188, 96, 160)
        highlight_alpha = 120
    else:
        body_top = (31, 47, 53, 246)
        body_bottom = (13, 20, 28, 248)
        cyan_edge = (100, 194, 218, 210)
        warm_edge = (214, 150, 76, 112)
        highlight_alpha = 72

    body = gradient(size, body_top, body_bottom)
    body = add_noise(body, 8)
    mask = rounded_mask((w - 28, h - 30), radius)
    clipped = body.crop((14, 10, w - 14, h - 20))
    clipped.putalpha(mask)
    img.alpha_composite(clipped, (14, 10))

    paste_alpha(img, radial_glow(size, (w * 0.22, h * 0.08), (255, 196, 106, 80 if primary else 45), max(w, h) * 0.55))
    paste_alpha(img, radial_glow(size, (w * 0.80, h * 0.26), (72, 230, 255, 90 if primary else 60), max(w, h) * 0.48))

    d = ImageDraw.Draw(img)
    d.rounded_rectangle((14, 10, w - 14, h - 20), radius=radius, outline=warm_edge, width=6)
    d.rounded_rectangle((20, 16, w - 20, h - 26), radius=max(4, radius - 6), outline=cyan_edge, width=4)
    d.rounded_rectangle((27, 24, w - 27, h - 34), radius=max(4, radius - 13), outline=(255, 245, 210, 58 if primary else 42), width=2)
    d.line((48, 26, w - 48, 26), fill=(255, 255, 230, highlight_alpha), width=2)
    d.line((54, h - 36, w - 54, h - 36), fill=(28, 10, 4, 84), width=2)
    save_png(path, img, "RGBA")


def make_panel(path: Path) -> None:
    img = draw_beveled_rect((640, 420), (224, 156, 74), (80, 220, 255), 22)
    d = ImageDraw.Draw(img)
    for i in range(6):
        y = 80 + i * 44
        d.line((52, y, 588, y), fill=(130, 180, 200, 25), width=1)
    d.rectangle((42, 38, 598, 382), outline=(255, 158, 62, 58), width=2)
    save_png(path, img, "RGBA")


def make_bar(path: Path, accent: tuple[int, int, int]) -> None:
    w, h = 640, 96
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((14, 20, w - 14, h - 18), radius=24, fill=(0, 0, 0, 165))
    shadow = shadow.filter(ImageFilter.GaussianBlur(8))
    paste_alpha(img, shadow)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((18, 18, w - 18, h - 20), radius=24, fill=(12, 18, 24, 238), outline=(accent[0], accent[1], accent[2], 210), width=4)
    d.rounded_rectangle((42, 34, w - 42, h - 38), radius=12, fill=(3, 7, 11, 245), outline=(138, 158, 174, 90), width=2)
    d.line((52, 37, w - 52, 37), fill=(255, 255, 255, 50), width=1)
    d.rectangle((68, 25, 120, 30), fill=(accent[0], accent[1], accent[2], 150))
    save_png(path, img, "RGBA")


def make_badge_base(size: int = 256, accent: tuple[int, int, int] = (255, 145, 45)) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    paste_alpha(img, radial_glow((size, size), (size * 0.5, size * 0.5), (*accent, 80), size * 0.52))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((24, 24, size - 24, size - 24), radius=44, fill=(13, 18, 25, 238), outline=(*accent, 230), width=6)
    d.rounded_rectangle((34, 34, size - 34, size - 34), radius=34, outline=(255, 235, 190, 62), width=2)
    return img


def draw_symbol(name: str, accent: tuple[int, int, int]) -> Image.Image:
    size = 256
    img = make_badge_base(size, accent)
    d = ImageDraw.Draw(img)
    cx, cy = 128, 128
    fill = (*accent, 245)
    white = (230, 240, 246, 235)
    dark = (26, 16, 10, 180)
    if name in {"gold", "talent"}:
        d.ellipse((72, 72, 184, 184), fill=fill, outline=(255, 230, 150, 250), width=8)
        d.ellipse((96, 96, 160, 160), outline=dark, width=10)
        d.line((128, 82, 128, 174), fill=(255, 245, 180, 90), width=3)
    elif name == "xp":
        d.polygon([(128, 50), (204, 128), (128, 206), (52, 128)], fill=fill, outline=white)
        d.ellipse((104, 104, 152, 152), fill=(206, 238, 255, 220))
    elif name == "star" or name == "star_filled":
        pts = []
        for i in range(10):
            a = -math.pi / 2 + i * math.pi / 5
            r = 78 if i % 2 == 0 else 34
            pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
        d.polygon(pts, fill=fill if name == "star_filled" else (0, 0, 0, 0), outline=fill)
        d.line((78, 122, 178, 122), fill=(255, 255, 210, 95), width=3)
    elif name == "pause":
        d.rounded_rectangle((80, 64, 110, 192), radius=8, fill=white)
        d.rounded_rectangle((146, 64, 176, 192), radius=8, fill=white)
    elif name == "settings":
        for i in range(8):
            a = i * math.pi / 4
            d.line((cx + math.cos(a) * 34, cy + math.sin(a) * 34, cx + math.cos(a) * 76, cy + math.sin(a) * 76), fill=white, width=12)
        d.ellipse((76, 76, 180, 180), fill=white)
        d.ellipse((108, 108, 148, 148), fill=(15, 20, 27, 255))
    elif name == "lock":
        d.rounded_rectangle((68, 112, 188, 190), radius=14, fill=white)
        d.arc((82, 56, 174, 150), 190, 350, fill=white, width=18)
        d.rectangle((102, 100, 154, 126), fill=white)
    elif name == "warning":
        d.polygon([(128, 46), (212, 198), (44, 198)], fill=fill, outline=(255, 232, 120, 245))
        d.rounded_rectangle((119, 96, 137, 148), radius=6, fill=(31, 24, 16, 230))
        d.ellipse((118, 164, 138, 184), fill=(31, 24, 16, 230))
    elif name == "fire":
        d.polygon([(132, 54), (184, 130), (146, 204), (78, 176), (68, 118)], fill=fill)
        d.polygon([(118, 112), (148, 150), (126, 188), (96, 166)], fill=(255, 232, 95, 230))
    elif name == "ice":
        for i in range(6):
            a = i * math.pi / 3
            d.line((cx, cy, cx + math.cos(a) * 78, cy + math.sin(a) * 78), fill=fill, width=8)
        d.ellipse((112, 112, 144, 144), fill=white)
    elif name == "lightning":
        d.polygon([(146, 42), (90, 130), (132, 130), (110, 214), (178, 106), (136, 106)], fill=fill)
    elif name == "poison":
        d.ellipse((76, 98, 190, 176), fill=fill)
        d.ellipse((116, 108, 148, 140), fill=(235, 255, 180, 220))
        d.ellipse((154, 94, 174, 114), fill=(235, 255, 180, 180))
    elif name == "physical":
        d.polygon([(74, 82), (142, 54), (188, 120), (112, 204)], fill=fill, outline=white)
    elif name == "card_projectile":
        d.line((62, 128, 194, 128), fill=fill, width=18)
        d.polygon([(194, 128), (154, 98), (154, 158)], fill=fill)
    elif name == "card_control":
        d.line((78, 78, 178, 178), fill=fill, width=9)
        d.line((178, 78, 78, 178), fill=fill, width=9)
        d.ellipse((98, 98, 158, 158), outline=white, width=6)
    elif name == "card_economy":
        d.ellipse((70, 82, 154, 166), fill=fill)
        d.rectangle((122, 104, 188, 174), fill=(255, 128, 74, 235))
        d.polygon([(122, 104), (154, 70), (188, 104)], fill=(255, 220, 92, 235))
    elif name == "strategy_breach":
        d.ellipse((72, 72, 184, 184), outline=fill, width=10)
        d.ellipse((108, 108, 148, 148), fill=(255, 225, 70, 240))
        d.line((128, 42, 128, 74), fill=fill, width=8)
    elif name == "strategy_nearest":
        d.line((62, 128, 194, 128), fill=white, width=12)
        d.polygon([(194, 128), (158, 100), (158, 156)], fill=white)
    elif name == "strategy_elite":
        d.polygon([(128, 58), (174, 174), (128, 146), (82, 174)], fill=fill)
        d.polygon([(88, 84), (168, 84), (148, 126), (108, 126)], fill=(255, 122, 88, 230))
    elif name == "strategy_low_hp":
        d.ellipse((64, 72, 136, 144), fill=(255, 80, 86, 235))
        d.ellipse((120, 72, 192, 144), fill=(255, 80, 86, 235))
        d.polygon([(64, 118), (192, 118), (128, 206)], fill=(255, 80, 86, 235))
        d.line((70, 142, 112, 142, 128, 104, 152, 166, 184, 166), fill=(255, 245, 120, 245), width=8)
    elif name == "reroll":
        d.arc((68, 70, 188, 190), 30, 310, fill=fill, width=12)
        d.polygon([(172, 70), (205, 74), (184, 102)], fill=fill)
    elif name == "skip":
        d.polygon([(78, 64), (142, 128), (78, 192)], fill=fill)
        d.polygon([(138, 64), (202, 128), (138, 192)], fill=fill)
    elif name == "pin":
        d.polygon([(98, 54), (176, 54), (158, 128), (136, 128), (128, 206), (120, 128), (98, 128)], fill=fill)
    else:
        d.ellipse((82, 82, 174, 174), fill=fill)
    return img


def make_card_frame(path: Path, accent: tuple[int, int, int]) -> None:
    w, h = 360, 500
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    paste_alpha(img, radial_glow((w, h), (w * 0.5, h * 0.35), (*accent, 76), 240))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((16, 16, w - 16, h - 16), radius=26, fill=(12, 17, 24, 238), outline=(*accent, 228), width=6)
    d.rounded_rectangle((28, 30, w - 28, h - 30), radius=18, outline=(255, 230, 190, 64), width=2)
    d.rectangle((44, 58, w - 44, 64), fill=(*accent, 165))
    d.rectangle((44, h - 70, w - 44, h - 64), fill=(*accent, 105))
    save_png(path, img, "RGBA")


def make_skill_slot(path: Path, active: bool) -> None:
    accent = (255, 162, 54) if active else (86, 202, 238)
    img = make_badge_base(220, accent)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((48, 48, 172, 172), radius=24, fill=(7, 12, 18, 215), outline=(*accent, 140), width=3)
    if active:
        paste_alpha(img, radial_glow((220, 220), (110, 110), (255, 122, 38, 80), 90))
    save_png(path, img, "RGBA")


def make_target_lock(path: Path) -> None:
    size = 256
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    accent = (122, 248, 238)
    for start in [0, 90, 180, 270]:
        d.arc((42, 42, 214, 214), start + 12, start + 68, fill=(*accent, 230), width=8)
    d.line((128, 34, 128, 68), fill=(*accent, 220), width=6)
    d.line((128, 188, 128, 222), fill=(*accent, 220), width=6)
    d.line((34, 128, 68, 128), fill=(*accent, 220), width=6)
    d.line((188, 128, 222, 128), fill=(*accent, 220), width=6)
    paste_alpha(img, radial_glow((size, size), (128, 128), (*accent, 60), 126))
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
        "skills": [],
        "loadout": ["loadout.png", "04_loadout.png"],
        "boss": ["battle.png", "05_boss.png"],
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
    d.rounded_rectangle((bx, by, bx + int(w * 0.38), by + int(w * 0.062)), radius=int(w * 0.02), fill=(11, 18, 25, 210), outline=(255, 139, 45, 180), width=max(2, w // 500))
    d.text((bx + int(w * 0.028), by + int(w * 0.013)), badge, fill=(255, 198, 98), font=badge_font)

    phone_w = int(w * (0.72 if w < 1600 else 0.58))
    phone_h = int(phone_w * 1920 / 1080)
    if phone_h > int(h * 0.67):
        phone_h = int(h * 0.67)
        phone_w = int(phone_h * 1080 / 1920)
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
        "ipad_129": (2048, 2732),
    }
    route_images: dict[str, Image.Image] = {}
    for route, *_ in routes:
        if route == "skills":
            route_images[route] = make_runtime_skill_cards((1080, 1920))
        else:
            src = screenshot_source(route, screens_dir)
            if src is None:
                route_images[route] = cover_image(APP_DIR / "launch_1080x1920.png", (1080, 1920))
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
    frame_dir = OUT_DIR / "preview_frames"
    if frame_dir.exists():
        shutil.rmtree(frame_dir)
    frame_dir.mkdir(parents=True)
    frames: list[Image.Image] = []
    sources = [
        APP_DIR / "launch_1080x1920.png",
        screenshot_source("battle", screens_dir),
        screenshot_source("map", screens_dir),
        None,
        screenshot_source("loadout", screens_dir),
        screenshot_source("boss", screens_dir),
    ]
    for src in sources:
        if src is None:
            frames.append(make_runtime_skill_cards((1080, 1920)))
        else:
            frames.append(cover_image(Path(src), (1080, 1920)))
    fps = 24
    total_per = fps * 3
    idx = 0
    for i, im in enumerate(frames):
        for f in range(total_per):
            t = f / max(1, total_per - 1)
            zoom = 1.0 + 0.025 * t
            sw, sh = int(1080 / zoom), int(1920 / zoom)
            crop = im.crop(((1080 - sw) // 2, (1920 - sh) // 2, (1080 + sw) // 2, (1920 + sh) // 2)).resize((1080, 1920), Image.Resampling.LANCZOS).convert("RGBA")
            if i > 0 and f < 10:
                prev = frames[i - 1].resize((1080, 1920), Image.Resampling.LANCZOS).convert("RGBA")
                crop = Image.blend(prev, crop, f / 10)
            crop.convert("RGB").save(frame_dir / f"frame_{idx:04d}.png")
            idx += 1
    output = VIDEO_DIR / "vid_app_preview.mp4"
    cmd = [
        "ffmpeg",
        "-y",
        "-framerate",
        str(fps),
        "-i",
        str(frame_dir / "frame_%04d.png"),
        "-vf",
        "format=yuv420p",
        "-movflags",
        "+faststart",
        str(output),
    ]
    subprocess.run(cmd, cwd=ROOT, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


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
    d.text((32, 24), "Final P0 Art Replacement Contact Sheet", fill=(238, 242, 248), font=load_font(28, True))
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
            "source": "source_refs/generated/final_p0_ui_store_spec_2026_07_01.json",
            "derived": "video/vid_app_preview.mp4",
            "reason": "Owner approved replacing the 2-second placeholder app preview with a rendered 18-second vertical preview draft from current game screens.",
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
        "scope": "P0 final-art replacement for launch image, App Store screenshots, app preview, flat UI kit, and legacy visible asset integration.",
        "style": "2.5D cartoon-realistic, premium 3D-rendered dark metal HUD, warning orange edges, cyan tech accents, ruined-city/cyberpunk presentation.",
        "generated_with": ["built-in image_gen for launch key art source", "local Pillow rendering for UI/store composites", "ffmpeg for app preview mp4"],
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
