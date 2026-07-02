#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import math
import random
import shutil
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / "assets" / "production"
UI_DIR = PROD / "sprites" / "ui"
PROJECTILE_DIR = PROD / "sprites" / "projectiles"
VFX_DIR = PROD / "sprites" / "vfx"
VFX_SEQ_DIR = PROD / "sprites" / "vfx_sequences"
SOURCE_DIR = PROD / "source_refs" / "generated"
INDEX_PATH = PROD / "OUTSOURCER_ASSET_INDEX.json"

STAMP = "2026_07_01"
RNG = random.Random(2026070121)


def rgba(value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = value.lstrip("#")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), alpha)


def mix(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(a[i] * (1.0 - t) + b[i] * t) for i in range(3))


def clamp(v: int) -> int:
    return max(0, min(255, v))


def shift(color: tuple[int, int, int], amount: int) -> tuple[int, int, int]:
    return tuple(clamp(c + amount) for c in color)


def gradient(size: tuple[int, int], top: tuple[int, int, int, int], bottom: tuple[int, int, int, int]) -> Image.Image:
    w, h = size
    img = Image.new("RGBA", size)
    px = img.load()
    for y in range(h):
        t = y / max(1, h - 1)
        row = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(4))
        for x in range(w):
            px[x, y] = row
    return img


def radial(size: tuple[int, int], center: tuple[float, float], color: tuple[int, int, int, int], radius: float, power: float = 2.0) -> Image.Image:
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    px = img.load()
    cx, cy = center
    for y in range(h):
        for x in range(w):
            d = math.hypot((x - cx) / max(radius, 1), (y - cy) / max(radius, 1))
            a = max(0.0, 1.0 - d) ** power
            if a > 0:
                px[x, y] = (color[0], color[1], color[2], int(color[3] * a))
    return img


def rounded_mask(size: tuple[int, int], box: tuple[int, int, int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle(box, radius=radius, fill=255)
    return mask


def paste(dst: Image.Image, src: Image.Image, xy: tuple[int, int] = (0, 0)) -> None:
    dst.alpha_composite(src.convert("RGBA"), xy)


def add_noise(img: Image.Image, strength: int = 12, alpha: int = 16) -> Image.Image:
    out = img.copy().convert("RGBA")
    px = out.load()
    w, h = out.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            n = RNG.randint(-strength, strength)
            px[x, y] = (clamp(r + n), clamp(g + n), clamp(b + n), a)
    specks = Image.new("RGBA", out.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(specks, "RGBA")
    for _ in range(max(12, (w * h) // 16000)):
        x = RNG.randint(0, w - 1)
        y = RNG.randint(0, h - 1)
        col = (255, 255, 235, RNG.randint(2, alpha)) if RNG.random() > 0.5 else (0, 0, 0, RNG.randint(3, alpha + 4))
        d.line((x, y, min(w, x + RNG.randint(8, 44)), y + RNG.randint(-2, 2)), fill=col, width=1)
    return Image.alpha_composite(out, specks)


def masked_layer(size: tuple[int, int], mask: Image.Image, fill: Image.Image | tuple[int, int, int, int]) -> Image.Image:
    layer = fill.copy().convert("RGBA") if isinstance(fill, Image.Image) else Image.new("RGBA", size, fill)
    layer.putalpha(ImageChops.multiply(layer.getchannel("A"), mask))
    return layer


def save_png(path: Path, image: Image.Image) -> str:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGBA").save(path)
    return str(path.relative_to(ROOT))


def load_font(size: int) -> ImageFont.ImageFont:
    for path in [
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/PingFang.ttc",
    ]:
        p = Path(path)
        if p.exists():
            try:
                return ImageFont.truetype(str(p), size)
            except OSError:
                continue
    return ImageFont.load_default()


def premium_frame(size: tuple[int, int], accent: tuple[int, int, int], radius: int, variant: str = "panel") -> Image.Image:
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    outer = (8, 8, w - 9, h - 12)
    mid = (18, 18, w - 19, h - 24)
    inner = (34, 32, w - 35, h - 40)
    secondary = (70, 220, 240)

    shadow_mask = rounded_mask(size, outer, radius)
    shadow = Image.new("RGBA", size, (0, 0, 0, 170))
    shadow.putalpha(shadow_mask.filter(ImageFilter.GaussianBlur(12)))
    paste(img, shadow, (0, 8))

    metal = gradient(size, (68, 75, 78, 255), (8, 11, 16, 252))
    paste(metal, radial(size, (w * 0.12, h * 0.10), (*secondary, 58), max(w, h) * 0.42))
    paste(metal, radial(size, (w * 0.88, h * 0.18), (*accent, 70), max(w, h) * 0.45))
    metal = add_noise(metal, 10, 14)
    paste(img, masked_layer(size, shadow_mask, metal))

    mid_mask = rounded_mask(size, mid, max(6, radius - 8))
    smoky = gradient(size, (42, 45, 45, 244), (4, 8, 14, 248))
    paste(smoky, radial(size, (w * 0.28, h * 0.10), (255, 160, 70, 46), max(w, h) * 0.36))
    paste(smoky, radial(size, (w * 0.80, h * 0.18), (62, 230, 248, 54), max(w, h) * 0.33))
    paste(img, masked_layer(size, mid_mask, smoky))

    inner_mask = rounded_mask(size, inner, max(4, radius - 18))
    glass = gradient(size, (26, 36, 42, 222), (5, 10, 16, 230))
    paste(glass, radial(size, (w * 0.72, h * 0.16), (*secondary, 82), max(w, h) * 0.30))
    paste(img, masked_layer(size, inner_mask, add_noise(glass, 6, 10)))

    d = ImageDraw.Draw(img, "RGBA")
    d.rounded_rectangle(outer, radius=radius, outline=(218, 230, 232, 126), width=2)
    d.rounded_rectangle(mid, radius=max(6, radius - 8), outline=(*accent, 230), width=4)
    d.rounded_rectangle(inner, radius=max(4, radius - 18), outline=(*secondary, 128), width=2)
    d.line((inner[0] + 18, inner[1] + 2, inner[2] - 18, inner[1] + 2), fill=(255, 248, 230, 80), width=2)
    d.line((inner[0] + 18, inner[3] - 2, inner[2] - 18, inner[3] - 2), fill=(0, 0, 0, 130), width=2)

    notch = max(28, min(w, h) // 4)
    for sx, sy, ex, ey, col in [
        (mid[0] + 2, mid[1], mid[0] + notch, mid[1], (62, 230, 248, 190)),
        (mid[2] - notch, mid[1], mid[2] - 2, mid[1], (*accent, 205)),
        (mid[0] + 2, mid[3], mid[0] + notch, mid[3], (*accent, 150)),
        (mid[2] - notch, mid[3], mid[2] - 2, mid[3], (62, 230, 248, 150)),
    ]:
        d.line((sx, sy, ex, ey), fill=col, width=3)

    if variant == "danger":
        paste(img, radial(size, (w * 0.50, h * 0.85), (255, 64, 24, 70), max(w, h) * 0.42))
    elif variant == "chip":
        for x in range(58, w - 58, 28):
            d.rounded_rectangle((x, h - 26, x + 12, h - 20), radius=3, fill=(*accent, 100))
    return img


def make_bar_skin(accent: tuple[int, int, int], fill: tuple[int, int, int]) -> Image.Image:
    w, h = 720, 110
    img = premium_frame((w, h), accent, 28, "chip")
    d = ImageDraw.Draw(img, "RGBA")
    track = (58, 42, w - 58, h - 42)
    d.rounded_rectangle(track, radius=14, fill=(1, 4, 8, 230), outline=(*accent, 180), width=2)
    fill_mask = rounded_mask((w, h), (70, 50, w - 130, h - 50), 10)
    fill_layer = gradient((w, h), (*shift(fill, 44), 245), (*shift(fill, -45), 230))
    paste(fill_layer, radial((w, h), (w * 0.20, h * 0.52), (255, 255, 220, 70), 220))
    paste(img, masked_layer((w, h), fill_mask, fill_layer))
    for x in range(90, w - 145, 29):
        d.line((x, 51, x + 14, h - 52), fill=(255, 255, 255, 26), width=1)
    return img


def generate_ui_skins() -> list[str]:
    written: list[str] = []
    skins = {
        "ui_panel_skin.png": premium_frame((512, 512), (224, 148, 52), 40, "panel"),
        "ui_plate_skin.png": premium_frame((420, 150), (80, 210, 230), 30, "chip"),
        "ui_pill_skin.png": premium_frame((512, 128), (78, 218, 234), 34, "chip"),
        "ui_resource_chip_skin.png": premium_frame((512, 160), (224, 164, 60), 34, "chip"),
        "ui_damage_number_badge.png": premium_frame((260, 100), (255, 90, 36), 26, "danger"),
        "ui_combo_panel.png": premium_frame((390, 128), (255, 178, 54), 26, "chip"),
        "ui_base_hp_bar.png": make_bar_skin((232, 70, 54), (224, 34, 30)),
        "ui_wave_progress.png": make_bar_skin((62, 214, 238), (42, 168, 224)),
        "ui_run_xp_bar.png": make_bar_skin((246, 188, 62), (255, 184, 38)),
        "ui_shield_bar.png": make_bar_skin((90, 180, 255), (50, 156, 255)),
    }
    for filename, image in skins.items():
        written.append(save_png(UI_DIR / filename, image))
    return written


PROJECTILE_SPECS = {
    "proj_bullet_physical.png": ("physical", (222, 228, 232), (255, 150, 42)),
    "proj_bullet_fire.png": ("fire", (255, 104, 28), (255, 218, 92)),
    "proj_bullet_ice.png": ("ice", (88, 218, 255), (220, 255, 255)),
    "proj_bullet_lightning.png": ("lightning", (216, 142, 255), (255, 232, 70)),
    "proj_bullet_poison.png": ("poison", (108, 255, 56), (204, 255, 112)),
    "proj_heavy_charge.png": ("heavy", (255, 178, 46), (255, 250, 190)),
    "proj_acid_spit.png": ("acid", (120, 255, 42), (232, 255, 92)),
    "proj_split_mini.png": ("split", (255, 196, 84), (255, 242, 180)),
    "proj_rail_slug.png": ("rail", (112, 246, 255), (238, 255, 255)),
    "proj_scatter_pellet.png": ("scatter", (255, 208, 118), (232, 238, 244)),
    "proj_plasma_orb.png": ("plasma", (204, 96, 255), (255, 158, 58)),
}


def projectile_canvas() -> Image.Image:
    return Image.new("RGBA", (256, 256), (0, 0, 0, 0))


def draw_capsule_projectile(kind: str, main: tuple[int, int, int], hot: tuple[int, int, int]) -> Image.Image:
    img = projectile_canvas()
    d = ImageDraw.Draw(img, "RGBA")
    paste(img, radial((256, 256), (132, 128), (*main, 120), 92, 2.2))
    paste(img, radial((256, 256), (64, 128), (*hot, 95), 70, 1.8))

    if kind in {"ice", "split", "rail"}:
        pts = [(38, 132), (92, 88), (192, 104), (234, 128), (190, 154), (92, 168)]
        if kind == "rail":
            pts = [(24, 128), (82, 106), (214, 112), (244, 128), (214, 144), (82, 150)]
        d.polygon(pts, fill=(*shift(main, -8), 238), outline=(238, 252, 255, 190))
        d.polygon([pts[1], (138, 126), pts[2]], fill=(*shift(hot, 35), 132))
        d.polygon([pts[-1], (138, 130), pts[-2]], fill=(10, 18, 25, 120))
        d.line((pts[0][0] + 16, 128, pts[3][0] - 8, 126), fill=(*hot, 210), width=3)
        if kind == "rail":
            d.line((15, 128, 236, 128), fill=(225, 255, 255, 220), width=2)
            d.line((38, 119, 210, 119), fill=(*main, 180), width=5)
    elif kind in {"acid", "poison"}:
        for cx, cy, r, col, a in [(102, 126, 42, main, 230), (142, 116, 34, hot, 165), (168, 142, 37, shift(main, -45), 188)]:
            d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(*col, a), outline=(*hot, 120), width=2)
        d.polygon(((174, 92), (232, 128), (174, 166)), fill=(*main, 128), outline=(*hot, 118))
        for cx, cy, r in [(68, 95, 8), (48, 138, 7), (106, 88, 5), (140, 138, 5)]:
            d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(*hot, 160))
    elif kind in {"plasma", "heavy"}:
        core = (128, 128)
        for r, a in [(62, 80), (45, 140), (28, 220)]:
            d.ellipse((core[0] - r, core[1] - r, core[0] + r, core[1] + r), fill=(*main, a), outline=(*hot, max(60, a - 80)), width=2)
        d.ellipse((108, 108, 148, 148), fill=(*hot, 230))
        for angle in range(0, 360, 60):
            x = 128 + math.cos(math.radians(angle)) * 78
            y = 128 + math.sin(math.radians(angle)) * 44
            d.arc((44, 70, 212, 186), angle - 16, angle + 36, fill=(*hot, 160), width=4)
            d.line((128, 128, x, y), fill=(*main, 72), width=3)
    elif kind == "scatter":
        d.ellipse((72, 92, 184, 164), fill=(198, 210, 220, 235), outline=(*hot, 165), width=3)
        d.pieslice((70, 92, 186, 166), 24, 154, fill=(255, 248, 214, 88))
        d.pieslice((70, 92, 186, 166), 200, 335, fill=(16, 22, 30, 118))
        d.line((36, 128, 82, 128), fill=(*main, 150), width=10)
    else:
        body = (60, 92, 180, 164)
        nose = ((172, 88), (234, 128), (172, 168))
        shell = gradient((256, 256), (*shift(hot, 30), 242), (*shift(main, -70), 246))
        mask = Image.new("L", (256, 256), 0)
        md = ImageDraw.Draw(mask)
        md.rounded_rectangle(body, radius=28, fill=255)
        md.polygon(nose, fill=255)
        paste(img, masked_layer((256, 256), mask, shell))
        d.rounded_rectangle(body, radius=28, outline=(245, 250, 255, 180), width=2)
        d.polygon(nose, outline=(255, 255, 236, 170))
        d.line((78, 104, 164, 100), fill=(255, 255, 244, 90), width=4)
        d.line((78, 152, 166, 158), fill=(0, 0, 0, 110), width=4)
        for x in (90, 146):
            d.rounded_rectangle((x, 100, x + 8, 156), radius=3, fill=(*hot, 170))

    d.line((18, 128, 72, 128), fill=(*hot, 135), width=8)
    d.line((22, 128, 110, 128), fill=(255, 248, 210, 120), width=2)
    out = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    alpha = img.getchannel("A")
    glow = Image.new("RGBA", (256, 256), (*main, 70))
    glow.putalpha(alpha.filter(ImageFilter.GaussianBlur(12)).point(lambda v: int(v * 0.38)))
    paste(out, glow)
    paste(out, img)
    edge = alpha.filter(ImageFilter.FIND_EDGES).point(lambda v: min(120, int(v * 0.55)))
    edge_layer = Image.new("RGBA", (256, 256), (242, 252, 255, 0))
    edge_layer.putalpha(edge)
    paste(out, edge_layer)
    return out


def generate_projectiles() -> list[str]:
    written: list[str] = []
    PROJECTILE_DIR.mkdir(parents=True, exist_ok=True)
    for filename, (kind, main, hot) in PROJECTILE_SPECS.items():
        written.append(save_png(PROJECTILE_DIR / filename, draw_capsule_projectile(kind, main, hot)))
    return written


def vfx_color(name: str) -> tuple[int, int, int]:
    if "fire" in name or "explosion" in name:
        return (255, 92, 26)
    if "ice" in name or "freeze" in name:
        return (88, 218, 255)
    if "lightning" in name or "chain" in name:
        return (138, 232, 255)
    if "poison" in name:
        return (112, 255, 54)
    if "crit" in name or "levelup" in name:
        return (255, 202, 70)
    if "immune" in name or "threat" in name:
        return (255, 78, 42)
    if "boss" in name or "phase" in name:
        return (194, 110, 255)
    return (96, 224, 242)


def make_vfx_frame(name: str, idx: int, total: int) -> Image.Image:
    size = (512, 512)
    p = (idx - 1) / max(1, total - 1)
    pulse = math.sin(p * math.pi)
    accent = vfx_color(name)
    hot = shift(accent, 56)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy = 256, 256

    paste(img, radial(size, (cx, cy), (*accent, int(135 * pulse)), 170 + 70 * p, 2.1))
    paste(img, radial(size, (cx, cy), (*hot, int(160 * pulse)), 70 + 30 * pulse, 1.6))

    if "muzzle" in name:
        length = 155 + 95 * pulse
        spread = 26 + 18 * pulse
        for i in range(11):
            a = -spread + i * (spread * 2 / 10)
            end = (cx + math.cos(math.radians(a)) * length, cy + math.sin(math.radians(a)) * length * 0.42)
            d.line((cx - 58, cy, end[0], end[1]), fill=(*accent, int(80 + 120 * pulse)), width=max(3, int(8 * (1 - abs(i - 5) / 6))))
        d.ellipse((cx - 32, cy - 28, cx + 34, cy + 28), fill=(*hot, int(130 + 100 * pulse)))
    elif "hit" in name or "explosion" in name or "crit" in name or "death" in name:
        radius = 38 + 170 * p
        for rr, alpha, width in [(radius, 190, 7), (radius * 0.62, 130, 5), (radius * 1.22, 75, 3)]:
            d.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), outline=(*accent, int(alpha * (1 - p * 0.45))), width=width)
        RNG.seed(name + str(idx))
        for _ in range(42):
            a = RNG.random() * math.tau
            dist = RNG.uniform(24, radius * 1.05)
            x = cx + math.cos(a) * dist
            y = cy + math.sin(a) * dist
            rr = RNG.uniform(2, 8) * (1.1 - p * 0.45)
            d.ellipse((x - rr, y - rr, x + rr, y + rr), fill=(*hot, int((1 - p * 0.25) * RNG.randint(72, 188))))
            if RNG.random() > 0.68:
                x2 = cx + math.cos(a) * (dist + 36)
                y2 = cy + math.sin(a) * (dist + 36)
                d.line((x, y, x2, y2), fill=(*accent, int(88 * pulse)), width=3)
    elif "chain" in name or "lightning" in name:
        RNG.seed(name + str(idx))
        for branch in range(5):
            pts = []
            start_x = 66
            for k in range(7):
                x = start_x + k * 64
                y = cy + (branch - 2) * 30 + RNG.randint(-24, 24)
                pts.append((x, y))
            d.line(pts, fill=(*accent, int(110 + 110 * pulse)), width=8, joint="curve")
            d.line(pts, fill=(245, 255, 255, int(120 + 90 * pulse)), width=3, joint="curve")
    elif "target" in name or "threat" in name:
        radius = 84 + 30 * pulse
        for rr, width, alpha in [(radius, 5, 210), (radius * 1.28, 3, 110), (radius * 0.62, 2, 125)]:
            d.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), outline=(*accent, int(alpha * (1 - p * 0.18))), width=width)
        for i in range(4):
            a = i * math.pi / 2 + p * math.pi
            d.line(
                (
                    cx + math.cos(a) * radius * 0.30,
                    cy + math.sin(a) * radius * 0.30,
                    cx + math.cos(a) * radius * 1.18,
                    cy + math.sin(a) * radius * 1.18,
                ),
                fill=(*hot, int(130 + 80 * pulse)),
                width=4,
            )
    elif "boss" in name or "phase" in name:
        radius = 46 + 134 * pulse
        for ring_idx, rr in enumerate([radius * 0.62, radius, radius * 1.34]):
            d.arc(
                (cx - rr, cy - rr, cx + rr, cy + rr),
                int(40 + p * 220 + ring_idx * 55),
                int(228 + p * 220 + ring_idx * 55),
                fill=(*accent, int((150 - ring_idx * 36) * (0.58 + pulse * 0.42))),
                width=max(2, 8 - ring_idx * 2),
            )
        RNG.seed(name + "boss" + str(idx))
        for _ in range(34):
            a = RNG.random() * math.tau
            dist = RNG.uniform(radius * 0.18, radius * 1.08)
            blade_len = RNG.uniform(10, 38) * (0.55 + pulse)
            x = cx + math.cos(a) * dist
            y = cy + math.sin(a) * dist
            pts = [
                (x, y),
                (x + math.cos(a + 0.75) * blade_len, y + math.sin(a + 0.75) * blade_len),
                (x + math.cos(a - 0.75) * blade_len * 0.55, y + math.sin(a - 0.75) * blade_len * 0.55),
            ]
            d.polygon(pts, fill=(*accent, RNG.randint(38, 128)), outline=(*hot, RNG.randint(24, 82)))
        d.ellipse((cx - 34, cy - 34, cx + 34, cy + 34), fill=(*hot, int(100 + pulse * 130)))
    elif "freeze" in name or "ice" in name:
        radius = 38 + 122 * pulse
        RNG.seed(name + "freeze" + str(idx))
        for shard in range(18):
            a = shard * math.tau / 18.0 + RNG.uniform(-0.07, 0.07)
            inner = radius * RNG.uniform(0.18, 0.48)
            outer = radius * RNG.uniform(0.76, 1.18)
            width = RNG.uniform(8, 24)
            p1 = (cx + math.cos(a) * inner, cy + math.sin(a) * inner)
            p2 = (cx + math.cos(a + 0.08) * outer, cy + math.sin(a + 0.08) * outer)
            p3 = (cx + math.cos(a - 0.08) * (outer - width), cy + math.sin(a - 0.08) * (outer - width))
            d.polygon([p1, p2, p3], fill=(*accent, RNG.randint(42, 128)), outline=(220, 255, 255, RNG.randint(42, 140)))
        d.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), outline=(*accent, int(138 * (1 - p * 0.35))), width=4)
        d.ellipse((cx - 28, cy - 28, cx + 28, cy + 28), fill=(220, 255, 255, int(120 + 90 * pulse)))
    elif "poison_cloud" in name or "poison" in name:
        RNG.seed(name + "poison" + str(idx))
        for _ in range(32):
            a = RNG.random() * math.tau
            dist = RNG.uniform(8, 118 + 52 * pulse)
            rr = RNG.uniform(12, 44) * (0.75 + pulse * 0.55)
            x = cx + math.cos(a) * dist
            y = cy + math.sin(a) * dist
            d.ellipse((x - rr, y - rr, x + rr, y + rr), fill=(*accent, RNG.randint(28, 96)), outline=(*hot, RNG.randint(16, 70)))
        for _ in range(15):
            x = RNG.randint(120, 392)
            y = RNG.randint(120, 392)
            rr = RNG.randint(3, 9)
            d.ellipse((x - rr, y - rr, x + rr, y + rr), fill=(*hot, RNG.randint(70, 160)))
    elif "levelup" in name:
        radius = 42 + 140 * pulse
        for rr, width, alpha in [(radius, 6, 170), (radius * 0.72, 4, 145), (radius * 1.24, 3, 90)]:
            d.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), outline=(*accent, int(alpha * (0.45 + pulse * 0.55))), width=width)
        RNG.seed(name + "level" + str(idx))
        for _ in range(42):
            x = RNG.uniform(cx - radius, cx + radius)
            y = RNG.uniform(cy + radius * 0.42, cy + radius * 1.10) - p * 180
            if abs(x - cx) > radius:
                continue
            d.line((x, y, x + RNG.uniform(-8, 8), y - RNG.uniform(18, 48)), fill=(*hot, RNG.randint(48, 160)), width=2)
    else:
        radius = 58 + 100 * pulse
        d.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), outline=(*accent, int(120 + 80 * pulse)), width=8)
        d.ellipse((cx - 28, cy - 28, cx + 28, cy + 28), fill=(*hot, int(120 + 80 * pulse)))

    return Image.alpha_composite(img.filter(ImageFilter.GaussianBlur(4)), img)


def generate_vfx() -> list[str]:
    written: list[str] = []
    for folder in sorted(p for p in VFX_SEQ_DIR.iterdir() if p.is_dir()):
        frames = sorted(folder.glob(f"{folder.name}_*.png"))
        if not frames:
            continue
        peak: Image.Image | None = None
        for idx, path in enumerate(frames, start=1):
            frame = make_vfx_frame(folder.name, idx, len(frames))
            written.append(save_png(path, frame))
            if idx == max(1, round(len(frames) * 0.52)):
                peak = frame
        if peak is not None:
            written.append(save_png(VFX_DIR / f"{folder.name}.png", peak))

    written.append(save_png(VFX_DIR / "vfx_slow_field_band.png", make_slow_field_band()))
    written.append(save_png(VFX_DIR / "vfx_barrier_glass.png", make_barrier_glass()))
    return written


def make_slow_field_band() -> Image.Image:
    w, h = 1080, 360
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    paste(img, radial((w, h), (w * 0.5, h * 0.5), (80, 220, 255, 92), 520, 2.4))
    d = ImageDraw.Draw(img, "RGBA")
    for y, alpha in [(62, 92), (106, 55), (254, 55), (298, 92)]:
        d.line((60, y, w - 60, y), fill=(170, 250, 255, alpha), width=3)
    for x in range(90, w, 96):
        d.line((x, 70, x + 42, h - 76), fill=(88, 220, 255, 34), width=2)
        d.ellipse((x - 5, h // 2 - 5, x + 5, h // 2 + 5), fill=(190, 255, 255, 110))
    for i in range(52):
        x = RNG.randint(50, w - 50)
        y = RNG.randint(62, h - 62)
        r = RNG.randint(2, 8)
        d.ellipse((x - r, y - r, x + r, y + r), fill=(210, 255, 255, RNG.randint(40, 120)))
    return img.filter(ImageFilter.GaussianBlur(0.35))


def make_barrier_glass() -> Image.Image:
    w, h = 960, 260
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    pts = [(50, 156), (148, 52), (812, 52), (910, 156), (760, 216), (200, 216)]
    mask = Image.new("L", (w, h), 0)
    md = ImageDraw.Draw(mask)
    md.polygon(pts, fill=255)
    glass = gradient((w, h), (120, 230, 255, 58), (10, 70, 96, 35))
    paste(glass, radial((w, h), (w * 0.5, h * 0.35), (190, 255, 255, 76), 360))
    paste(img, masked_layer((w, h), mask, glass))
    for offset, alpha, width in [(0, 210, 6), (12, 120, 3)]:
        shifted = [(x, y + offset) for x, y in pts]
        d.line(shifted + [shifted[0]], fill=(160, 246, 255, alpha), width=width, joint="curve")
    for x in [230, 480, 730]:
        d.line((x, 74, x + 40, 196), fill=(220, 255, 255, 92), width=2)
    return Image.alpha_composite(img.filter(ImageFilter.GaussianBlur(1.2)), img)


def save_contact_sheet(paths: list[str]) -> str:
    selected: list[Path] = []
    for rel in paths:
        p = ROOT / rel
        if p.suffix == ".png" and p.exists():
            selected.append(p)
    selected = selected[:96]
    cols = 6
    cell_w, cell_h = 240, 220
    rows = math.ceil(len(selected) / cols)
    sheet = Image.new("RGBA", (cols * cell_w, max(1, rows) * cell_h), (8, 11, 16, 255))
    d = ImageDraw.Draw(sheet, "RGBA")
    font = load_font(16)
    for i, path in enumerate(selected):
        x = (i % cols) * cell_w
        y = (i // cols) * cell_h
        d.rounded_rectangle((x + 10, y + 10, x + cell_w - 10, y + cell_h - 10), radius=10, fill=(13, 18, 25, 255), outline=(82, 132, 150, 180), width=2)
        im = Image.open(path).convert("RGBA")
        im.thumbnail((168, 144), Image.Resampling.LANCZOS)
        sheet.alpha_composite(im, (x + (cell_w - im.width) // 2, y + 22))
        label = path.stem
        if len(label) > 25:
            label = label[:24] + "..."
        d.text((x + 16, y + 174), label, font=font, fill=(220, 232, 238, 255))
    out = SOURCE_DIR / f"runtime_top_tier_polish_contact_sheet_{STAMP}.png"
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    return str(out.relative_to(ROOT))


def write_spec(written: list[str], contact_sheet: str, reference_dest: str | None) -> str:
    spec = {
        "id": "runtime_top_tier_polish_pass",
        "generated_by": "tools/generate_top_tier_runtime_art.py",
        "built_in_image_gen_reference": reference_dest,
        "scope": [
            "texture-backed runtime UI skins",
            "premium projectile sprites",
            "premium VFX single sprites and sequence frames",
            "slow-field and barrier bitmap overlays",
        ],
        "style_prompt": (
            "Top-tier App Store-grade 3D rendered cyberpunk ruined-city shooter assets: dark gunmetal, smoked glass, "
            "cyan/orange rim lights, volumetric elemental projectiles, PBR bevels, no vector or flat placeholder look."
        ),
        "runtime_policy": "No gameplay values, data IDs, waves, damage, collision, or economy fields changed.",
        "contact_sheet": contact_sheet,
        "written_count": len(written),
        "written": written,
    }
    path = SOURCE_DIR / f"runtime_top_tier_polish_spec_{STAMP}.json"
    path.write_text(json.dumps(spec, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return str(path.relative_to(ROOT))


def update_asset_index(spec_path: str, contact_sheet: str) -> None:
    data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
    data["counts"]["total_files"] = sum(1 for path in PROD.rglob("*") if path.is_file())
    overrides = data.setdefault("owner_directed_generated_overrides", [])
    paths = {
        "sprites/ui/runtime_skins",
        "sprites/projectiles",
        "sprites/vfx",
        "sprites/vfx_sequences",
    }
    overrides = [item for item in overrides if item.get("path") not in paths]
    for path in sorted(paths):
        overrides.append(
            {
                "path": path,
                "source": spec_path.replace("assets/production/", ""),
                "derived": contact_sheet.replace("assets/production/", ""),
                "reason": "Owner requested remaining prototype-feeling UI, projectile, and VFX assets to be raised toward top-tier App Store rendered quality without vector placeholders.",
            }
        )
    data["owner_directed_generated_overrides"] = overrides
    INDEX_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def copy_reference(path: str | None) -> str | None:
    if not path:
        return None
    src = Path(path)
    if not src.exists():
        return None
    dest = SOURCE_DIR / f"runtime_top_tier_imagegen_reference_{STAMP}.png"
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dest)
    return str(dest.relative_to(ROOT))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--reference", default="")
    args = parser.parse_args()

    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    written: list[str] = []
    reference_dest = copy_reference(args.reference)
    written.extend(generate_ui_skins())
    written.extend(generate_projectiles())
    written.extend(generate_vfx())
    contact_sheet = save_contact_sheet(written)
    spec_path = write_spec(written, contact_sheet, reference_dest)
    update_asset_index(spec_path, contact_sheet)
    print(f"Runtime top-tier polish wrote {len(written)} PNG files")
    print(contact_sheet)
    print(spec_path)
    if reference_dest:
        print(reference_dest)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
