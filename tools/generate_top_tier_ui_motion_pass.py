#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import math
import random
import shutil
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / "assets" / "production"
UI_DIR = PROD / "sprites" / "ui"
VFX_DIR = PROD / "sprites" / "vfx"
VFX_SEQ_DIR = PROD / "sprites" / "vfx_sequences"
ANIM_DIR = PROD / "sprites" / "animations"
SOURCE_DIR = PROD / "source_refs" / "generated"
CONTACT_DIR = PROD / "contact_sheets"
INDEX_PATH = PROD / "OUTSOURCER_ASSET_INDEX.json"

STAMP = "2026_07_02"
RNG = random.Random(2026070201)

SKILLS = [
    "skill_split_shot",
    "skill_pierce",
    "skill_multishot",
    "skill_slow_field",
    "skill_homing",
    "skill_critical",
    "skill_barrier",
    "skill_gold_rush",
    "skill_ricochet",
    "skill_salvo",
    "skill_incendiary",
    "skill_cryo",
    "skill_tesla",
    "skill_venom",
    "skill_charge_shot",
    "skill_recycle",
]

SKILL_COLORS = {
    "skill_incendiary": (255, 86, 22),
    "skill_cryo": (100, 222, 255),
    "skill_slow_field": (96, 220, 255),
    "skill_tesla": (255, 232, 72),
    "skill_ricochet": (120, 236, 255),
    "skill_homing": (110, 224, 255),
    "skill_venom": (102, 255, 50),
    "skill_barrier": (132, 224, 255),
    "skill_split_shot": (255, 166, 48),
    "skill_multishot": (255, 188, 62),
    "skill_salvo": (255, 155, 42),
    "skill_pierce": (255, 220, 92),
    "skill_charge_shot": (255, 230, 112),
    "skill_critical": (255, 208, 58),
    "skill_gold_rush": (255, 190, 48),
    "skill_recycle": (116, 255, 174),
}

ELEMENT_COLORS = {
    "physical": (236, 210, 156),
    "fire": (255, 84, 20),
    "ice": (92, 220, 255),
    "lightning": (255, 228, 58),
    "poison": (104, 255, 56),
    "immune": (126, 206, 255),
    "void": (184, 96, 255),
    "armor": (236, 176, 76),
}

VFX_CAST_MAP = {
    "skill_incendiary": "fire",
    "skill_cryo": "ice",
    "skill_slow_field": "ice",
    "skill_tesla": "lightning",
    "skill_ricochet": "lightning",
    "skill_homing": "target",
    "skill_venom": "poison",
    "skill_barrier": "barrier",
    "skill_split_shot": "fan",
    "skill_multishot": "fan",
    "skill_salvo": "salvo",
    "skill_pierce": "pierce",
    "skill_charge_shot": "charge",
    "skill_critical": "crit",
    "skill_gold_rush": "gold",
    "skill_recycle": "recycle",
}

ENEMY_SKILL_SEQUENCE_KIND = {
    "runner_dash": "dash",
    "charge": "charge",
    "leap_strike": "dash",
    "juggernaut": "slam",
    "armor": "armor",
    "armor_break": "armor",
    "shield_aura": "armor",
    "ward": "armor",
    "toxic_cloud": "toxic",
    "ranged_spit": "toxic",
    "corrosion": "toxic",
    "regen": "toxic",
    "regenerate": "toxic",
    "buff_aura": "aura",
    "support_strike": "aura",
    "summon": "summon",
    "spawn_minions": "summon",
    "phase": "phase",
    "phase_shift": "phase",
    "multi_phase": "phase",
    "mutate": "mutate",
    "enrage": "enrage",
    "explode_on_death": "fire",
    "phase_burn": "fire",
    "blast": "fire",
    "freeze_field": "frost",
    "storm_chain": "storm",
}

ACTIVE_SKILLS = [
    "sig_vanguard_railvolley",
    "sig_vanguard_overload",
    "sig_blaze_meltdown",
    "sig_frost_glacier",
    "sig_volt_storm",
]


def clamp(v: int) -> int:
    return max(0, min(255, v))


def shift(color: tuple[int, int, int], amount: int) -> tuple[int, int, int]:
    return tuple(clamp(c + amount) for c in color)


def rgba(color: tuple[int, int, int], alpha: int = 255) -> tuple[int, int, int, int]:
    return color[0], color[1], color[2], alpha


def gradient(size: tuple[int, int], top: tuple[int, int, int, int], bottom: tuple[int, int, int, int]) -> Image.Image:
    w, h = size
    img = Image.new("RGBA", size)
    px = img.load()
    for y in range(h):
        t = y / max(1, h - 1)
        row = tuple(int(top[i] * (1.0 - t) + bottom[i] * t) for i in range(4))
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
            dx = (x - cx) / max(radius, 1.0)
            dy = (y - cy) / max(radius, 1.0)
            d = math.hypot(dx, dy)
            a = max(0.0, 1.0 - d) ** power
            if a > 0.0:
                px[x, y] = (color[0], color[1], color[2], int(color[3] * a))
    return img


def rounded_mask(size: tuple[int, int], box: tuple[int, int, int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle(box, radius=radius, fill=255)
    return mask


def mask_layer(size: tuple[int, int], mask: Image.Image, fill: Image.Image | tuple[int, int, int, int]) -> Image.Image:
    layer = fill.copy().convert("RGBA") if isinstance(fill, Image.Image) else Image.new("RGBA", size, fill)
    layer.putalpha(ImageChops.multiply(layer.getchannel("A"), mask))
    return layer


def add_noise(img: Image.Image, strength: int = 7, lines: int = 12) -> Image.Image:
    out = img.convert("RGBA").copy()
    px = out.load()
    w, h = out.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            n = RNG.randint(-strength, strength)
            px[x, y] = (clamp(r + n), clamp(g + n), clamp(b + n), a)
    d = ImageDraw.Draw(out, "RGBA")
    for _ in range(lines):
        x = RNG.randint(0, max(0, w - 1))
        y = RNG.randint(0, max(0, h - 1))
        length = RNG.randint(max(6, w // 18), max(10, w // 5))
        alpha = RNG.randint(10, 36)
        d.line((x, y, min(w - 1, x + length), y + RNG.randint(-2, 2)), fill=(255, 245, 205, alpha), width=1)
    return out


def alpha_glow(src: Image.Image, color: tuple[int, int, int], blur: float, alpha_mult: float) -> Image.Image:
    alpha = src.getchannel("A").filter(ImageFilter.GaussianBlur(blur)).point(lambda v: int(v * alpha_mult))
    glow = Image.new("RGBA", src.size, rgba(color, 0))
    glow.putalpha(alpha)
    return glow


def strip_flat_backplate(src: Image.Image) -> Image.Image:
    im = src.convert("RGBA").copy()
    w, h = im.size
    pix = im.load()
    margin = max(18, min(w, h) // 32)
    inner_samples: list[tuple[int, int, int]] = []
    for x in range(margin, w - margin, max(1, w // 48)):
        for y in (margin, h - margin - 1):
            r, g, b, a = pix[x, y]
            if a > 24:
                inner_samples.append((r, g, b))
    for y in range(margin, h - margin, max(1, h // 48)):
        for x in (margin, w - margin - 1):
            r, g, b, a = pix[x, y]
            if a > 24:
                inner_samples.append((r, g, b))
    edge_samples: list[tuple[int, int, int]] = []
    for x in range(0, w, max(1, w // 64)):
        for y in (0, min(h - 1, 4), max(0, h - 5), h - 1):
            r, g, b, a = pix[x, y]
            if a > 24:
                edge_samples.append((r, g, b))
    for y in range(0, h, max(1, h // 64)):
        for x in (0, min(w - 1, 4), max(0, w - 5), w - 1):
            r, g, b, a = pix[x, y]
            if a > 24:
                edge_samples.append((r, g, b))
    samples = inner_samples if inner_samples else edge_samples
    if not samples:
        return im
    bg = tuple(sorted(sample[i] for sample in samples)[len(samples) // 2] for i in range(3))

    def dist(a: tuple[int, int, int], b: tuple[int, int, int]) -> float:
        return math.sqrt(sum((a[i] - b[i]) ** 2 for i in range(3)))

    def removable(x: int, y: int) -> bool:
        r, g, b, a = pix[x, y]
        if a <= 8:
            return True
        if dist((r, g, b), bg) < 86:
            return True
        # Remove the bright magenta/blue proofing rim while preserving painted armor highlights.
        if r > 120 and b > 170 and g < 180 and (x < 16 or y < 16 or x > w - 17 or y > h - 17):
            return True
        return False

    from collections import deque

    q: deque[tuple[int, int]] = deque()
    seen = bytearray(w * h)
    for x in range(w):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(h):
        q.append((0, y))
        q.append((w - 1, y))

    while q:
        x, y = q.popleft()
        if x < 0 or x >= w or y < 0 or y >= h:
            continue
        idx = y * w + x
        if seen[idx] or not removable(x, y):
            continue
        seen[idx] = 1
        r, g, b, _a = pix[x, y]
        pix[x, y] = (r, g, b, 0)
        q.append((x + 1, y))
        q.append((x - 1, y))
        q.append((x, y + 1))
        q.append((x, y - 1))

    alpha = im.getchannel("A").filter(ImageFilter.GaussianBlur(0.45))
    im.putalpha(alpha)
    return im


def paste_center(dst: Image.Image, src: Image.Image, box: tuple[int, int, int, int]) -> None:
    target_w = box[2] - box[0]
    target_h = box[3] - box[1]
    im = src.convert("RGBA").copy()
    im.thumbnail((target_w, target_h), Image.Resampling.LANCZOS)
    dst.alpha_composite(im, (box[0] + (target_w - im.width) // 2, box[1] + (target_h - im.height) // 2))


def save(path: Path, image: Image.Image, written: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGBA").save(path)
    written.append(str(path.relative_to(ROOT)))


def premium_panel(size: tuple[int, int], accent: tuple[int, int, int], radius: int, frame_width: float = 1.0) -> Image.Image:
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    inset = max(4, int(min(w, h) * 0.035 * frame_width))
    outer = (inset, inset, w - inset - 1, h - inset - 2)
    mid = (inset + 10, inset + 10, w - inset - 11, h - inset - 14)
    inner = (inset + 24, inset + 24, w - inset - 25, h - inset - 30)
    cyan = (76, 226, 238)

    shadow_mask = rounded_mask(size, outer, radius)
    shadow = Image.new("RGBA", size, (0, 0, 0, 170))
    shadow.putalpha(shadow_mask.filter(ImageFilter.GaussianBlur(max(4, min(w, h) // 24))))
    img.alpha_composite(shadow, (0, max(2, h // 90)))

    metal = gradient(size, (72, 78, 80, 248), (6, 9, 14, 252))
    metal.alpha_composite(radial(size, (w * 0.18, h * 0.1), rgba(accent, 58), max(w, h) * 0.42))
    metal.alpha_composite(radial(size, (w * 0.82, h * 0.18), rgba(cyan, 64), max(w, h) * 0.34))
    img.alpha_composite(mask_layer(size, shadow_mask, add_noise(metal, 7, max(8, w * h // 26000))))

    for box, rad, col, width in [
        (outer, radius, (220, 230, 230, 135), max(1, int(min(w, h) * 0.010))),
        (mid, max(5, radius - 8), (*accent, 230), max(2, int(min(w, h) * 0.015))),
        (inner, max(4, radius - 17), (*cyan, 150), max(1, int(min(w, h) * 0.008))),
    ]:
        ImageDraw.Draw(img, "RGBA").rounded_rectangle(box, radius=rad, outline=col, width=width)

    glass_mask = rounded_mask(size, inner, max(4, radius - 17))
    glass = gradient(size, (24, 34, 40, 218), (3, 7, 13, 232))
    glass.alpha_composite(radial(size, (w * 0.72, h * 0.17), (120, 245, 255, 74), max(w, h) * 0.24))
    img.alpha_composite(mask_layer(size, glass_mask, glass))

    d = ImageDraw.Draw(img, "RGBA")
    notch = max(18, min(w, h) // 5)
    for y, alpha in [(mid[1], 196), (mid[3], 136)]:
        d.line((mid[0] + 12, y, mid[0] + notch, y), fill=(*cyan, alpha), width=max(1, min(w, h) // 60))
        d.line((mid[2] - notch, y, mid[2] - 12, y), fill=(*accent, alpha), width=max(1, min(w, h) // 60))
    d.line((inner[0] + 18, inner[1] + 1, inner[2] - 18, inner[1] + 1), fill=(255, 248, 220, 74), width=max(1, h // 80))
    d.line((inner[0] + 18, inner[3] - 1, inner[2] - 18, inner[3] - 1), fill=(0, 0, 0, 128), width=max(1, h // 80))
    return img


def premium_button(size: tuple[int, int], primary: bool) -> Image.Image:
    accent = (236, 151, 46) if primary else (96, 210, 232)
    img = premium_panel(size, accent, max(16, min(size) // 4), 0.82)
    w, h = size
    d = ImageDraw.Draw(img, "RGBA")
    fill = gradient(size, (52, 120, 110, 185), (18, 36, 42, 195)) if primary else gradient(size, (54, 62, 62, 175), (10, 18, 24, 205))
    mask = rounded_mask(size, (36, 34, w - 36, h - 40), max(8, h // 5))
    fill.alpha_composite(radial(size, (w * 0.72, h * 0.25), (92, 238, 248, 72), max(w, h) * 0.30))
    img.alpha_composite(mask_layer(size, mask, fill))
    d.line((w * 0.20, h * 0.47, w * 0.80, h * 0.47), fill=(245, 250, 255, 42), width=max(1, h // 64))
    d.line((w * 0.20, h * 0.63, w * 0.80, h * 0.63), fill=(0, 0, 0, 90), width=max(1, h // 80))
    return img


def premium_bar(size: tuple[int, int], accent: tuple[int, int, int], fill_color: tuple[int, int, int]) -> Image.Image:
    w, h = size
    img = premium_panel(size, accent, max(12, h // 4), 0.55)
    track = (max(22, w // 12), max(16, h // 3), w - max(22, w // 12), h - max(16, h // 3))
    d = ImageDraw.Draw(img, "RGBA")
    d.rounded_rectangle(track, radius=max(5, h // 10), fill=(1, 4, 8, 225), outline=(*accent, 170), width=max(1, h // 40))
    fill_box = (track[0] + 10, track[1] + 7, int(track[0] + (track[2] - track[0]) * 0.78), track[3] - 7)
    mask = rounded_mask(size, fill_box, max(4, h // 12))
    fill = gradient(size, (*shift(fill_color, 54), 245), (*shift(fill_color, -58), 230))
    fill.alpha_composite(radial(size, (w * 0.22, h * 0.52), (255, 255, 220, 80), w * 0.36))
    img.alpha_composite(mask_layer(size, mask, fill))
    for x in range(fill_box[0] + 24, fill_box[2], max(18, w // 26)):
        d.line((x, fill_box[1] + 1, x + max(8, w // 60), fill_box[3] - 1), fill=(255, 255, 255, 28), width=1)
    return img


def crop_visible(im: Image.Image) -> Image.Image:
    bbox = im.getbbox()
    if not bbox:
        return im
    return im.crop(bbox)


def polish_icon(path: Path, accent: tuple[int, int, int], written: list[str]) -> None:
    src = Image.open(path).convert("RGBA")
    w, h = src.size
    content = crop_visible(src)
    content = ImageEnhance.Contrast(content).enhance(1.12)
    content = ImageEnhance.Sharpness(content).enhance(1.18)
    if path.name.startswith(("skill_", "sig_")):
        bg = premium_panel((w, h), accent, max(18, min(w, h) // 8), 0.65)
        target = (int(w * 0.16), int(h * 0.16), int(w * 0.84), int(h * 0.84))
    else:
        bg = premium_panel((w, h), accent, max(16, min(w, h) // 7), 0.58)
        target = (int(w * 0.18), int(h * 0.18), int(w * 0.82), int(h * 0.82))
    glow_source = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    paste_center(glow_source, content, target)
    bg.alpha_composite(alpha_glow(glow_source, accent, max(6, w // 22), 0.46))
    bg.alpha_composite(glow_source)
    d = ImageDraw.Draw(bg, "RGBA")
    d.arc((w * 0.18, h * 0.18, w * 0.82, h * 0.82), 205, 330, fill=(255, 255, 230, 80), width=max(2, w // 80))
    save(path, bg, written)


def generate_ui(reference: Path | None, written: list[str]) -> None:
    structural = {
        "ui_button_primary.png": lambda size: premium_button(size, True),
        "ui_button_secondary.png": lambda size: premium_button(size, False),
        "ui_base_hp_bar.png": lambda size: premium_bar(size, (236, 76, 58), (230, 36, 34)),
        "ui_wave_progress.png": lambda size: premium_bar(size, (82, 220, 238), (46, 168, 230)),
        "ui_run_xp_bar.png": lambda size: premium_bar(size, (246, 190, 60), (255, 180, 34)),
        "ui_shield_bar.png": lambda size: premium_bar(size, (92, 178, 255), (52, 150, 255)),
        "ui_panel.png": lambda size: premium_panel(size, (226, 150, 50), max(18, min(size) // 9), 1.0),
        "ui_panel_skin.png": lambda size: premium_panel(size, (226, 150, 50), max(18, min(size) // 9), 1.0),
        "ui_plate_skin.png": lambda size: premium_panel(size, (80, 218, 236), max(14, min(size) // 6), 0.78),
        "ui_pill_skin.png": lambda size: premium_panel(size, (80, 218, 236), max(12, min(size) // 4), 0.62),
        "ui_resource_chip_skin.png": lambda size: premium_panel(size, (232, 168, 54), max(14, min(size) // 5), 0.72),
        "ui_damage_number_badge.png": lambda size: premium_panel(size, (255, 78, 38), max(12, min(size) // 5), 0.74),
        "ui_combo_panel.png": lambda size: premium_panel(size, (255, 176, 48), max(14, min(size) // 5), 0.78),
        "ui_cd_overlay.png": lambda size: premium_panel(size, (90, 220, 240), max(20, min(size) // 7), 0.48),
        "ui_skill_slot.png": lambda size: premium_panel(size, (82, 218, 238), max(20, min(size) // 6), 0.72),
        "ui_skill_slot_active.png": lambda size: premium_panel(size, (255, 156, 36), max(20, min(size) // 6), 0.84),
    }
    for path in sorted(UI_DIR.glob("*.png")):
        size = Image.open(path).size
        name = path.name
        if name in structural:
            save(path, structural[name](size), written)
        elif name.startswith("ui_card_frame"):
            if "fire" in name:
                accent = (255, 92, 26)
            elif "ice" in name:
                accent = (88, 218, 255)
            elif "lightning" in name:
                accent = (255, 220, 60)
            elif "poison" in name:
                accent = (112, 255, 54)
            elif "physical" in name:
                accent = (210, 222, 232)
            else:
                accent = (230, 170, 56)
            save(path, premium_panel(size, accent, max(18, min(size) // 7), 0.82), written)
        elif name.startswith(("ui_card_", "ui_target_", "ui_star_")):
            polish_icon(path, (236, 178, 54), written)
        elif name.startswith("icon_element_fire"):
            polish_icon(path, (255, 92, 26), written)
        elif name.startswith("icon_element_ice"):
            polish_icon(path, (88, 218, 255), written)
        elif name.startswith("icon_element_lightning"):
            polish_icon(path, (255, 220, 60), written)
        elif name.startswith("icon_element_poison"):
            polish_icon(path, (112, 255, 54), written)
        elif name.startswith("icon_element_physical"):
            polish_icon(path, (210, 222, 232), written)
        elif name.startswith(("skill_", "sig_")):
            sid = name.removesuffix("_icon.png")
            polish_icon(path, SKILL_COLORS.get(sid, (236, 178, 54)), written)
        elif name.startswith("icon_currency"):
            accent = (255, 196, 54) if "gold" in name or "star" in name else (88, 218, 255)
            polish_icon(path, accent, written)
        elif name.startswith("icon_"):
            polish_icon(path, (190, 210, 230), written)

    # Extra bitmap skins used by the second runtime hookup pass.
    extras = {
        "ui_hint_strip.png": premium_panel((840, 112), (112, 226, 142), 24, 0.58),
        "ui_warning_strip.png": premium_panel((840, 112), (255, 88, 42), 24, 0.58),
        "ui_icon_frame.png": premium_panel((220, 220), (90, 222, 238), 28, 0.72),
        "ui_icon_frame_active.png": premium_panel((220, 220), (255, 166, 42), 28, 0.84),
        "ui_level_card_skin.png": premium_panel((1024, 148), (224, 154, 48), 26, 0.66),
        "ui_modal_button_primary.png": premium_button((512, 160), True),
        "ui_modal_button_secondary.png": premium_button((512, 160), False),
        "ui_bar_fill_hp.png": premium_bar((720, 110), (236, 76, 58), (230, 36, 34)),
        "ui_bar_fill_xp.png": premium_bar((720, 110), (78, 225, 160), (52, 205, 120)),
    }
    for filename, img in extras.items():
        save(UI_DIR / filename, img, written)


def movement_variant(base: Image.Image, index: int, total: int, boss: bool) -> Image.Image:
    p = index / max(1, total - 1)
    w, h = base.size
    src = strip_flat_backplate(base) if boss else base.convert("RGBA")
    src = ImageEnhance.Contrast(src).enhance(1.08)
    src = ImageEnhance.Sharpness(src).enhance(1.12)
    bbox = src.getbbox()
    if not bbox:
        return src
    cx = (bbox[0] + bbox[2]) * 0.5
    cy = (bbox[1] + bbox[3]) * 0.5
    dx = math.sin(p * math.pi) * (18 if boss else 10)
    dy = -math.sin(p * math.pi) * (10 if boss else 6)
    scale_x = 1.0 + math.sin(p * math.pi) * (0.045 if boss else 0.035)
    scale_y = 1.0 - math.sin(p * math.pi) * (0.030 if boss else 0.018)
    transformed = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    crop = src.crop(bbox)
    new_size = (max(1, int(crop.width * scale_x)), max(1, int(crop.height * scale_y)))
    crop = crop.resize(new_size, Image.Resampling.BICUBIC)
    x = int(cx - new_size[0] * 0.5 + dx)
    y = int(cy - new_size[1] * 0.5 + dy)
    transformed.alpha_composite(crop, (x, y))
    return transformed


def slash_overlay(size: tuple[int, int], accent: tuple[int, int, int], index: int, total: int, boss: bool) -> Image.Image:
    w, h = size
    p = index / max(1, total - 1)
    pulse = math.sin(p * math.pi)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    if pulse <= 0.05:
        return img
    base_y = h * (0.44 if boss else 0.50)
    spread = 58 if boss else 42
    for i in range(4 if boss else 3):
        yy = base_y + (i - 1.5) * spread * 0.36
        x0 = w * (0.18 + 0.04 * i)
        x1 = w * (0.82 - 0.02 * i)
        alpha = int((130 if boss else 105) * pulse)
        width = max(3, int((12 if boss else 8) * pulse))
        d.arc((x0, yy - spread, x1, yy + spread), 200, 338, fill=(*accent, alpha), width=width)
        d.arc((x0 + 8, yy - spread + 8, x1 - 8, yy + spread - 8), 205, 328, fill=(255, 250, 220, max(0, alpha - 36)), width=max(1, width // 3))
    if boss:
        r = int(75 + 120 * pulse)
        d.ellipse((w / 2 - r, h * 0.55 - r, w / 2 + r, h * 0.55 + r), outline=(*accent, int(70 * pulse)), width=8)
    return img.filter(ImageFilter.GaussianBlur(0.45))


def polish_attack_sequence(folder: Path, entity_id: str, action: str, accent: tuple[int, int, int], boss: bool, written: list[str]) -> None:
    frames = sorted(folder.glob(f"{entity_id}_{action}_*.png"))
    if not frames:
        return
    total = len(frames)
    for idx, path in enumerate(frames):
        base = Image.open(path).convert("RGBA")
        moved = movement_variant(base, idx, total, boss)
        img = Image.new("RGBA", base.size, (0, 0, 0, 0))
        if idx > 0:
            smear = movement_variant(base, max(0, idx - 1), total, boss)
            smear = alpha_glow(smear, accent, 7 if boss else 5, 0.32 if boss else 0.24)
            img.alpha_composite(smear)
        img.alpha_composite(alpha_glow(moved, accent, 5 if boss else 3.5, 0.22))
        img.alpha_composite(moved)
        if action in {"attack", "special"}:
            img.alpha_composite(slash_overlay(base.size, accent, idx, total, boss))
        # Keep transparent edge contract intact.
        save(path, img, written)


def generate_attack_motion(written: list[str]) -> None:
    zombie_dir = ANIM_DIR / "zombies"
    for folder in sorted(p for p in zombie_dir.iterdir() if p.is_dir()):
        name = folder.name
        if "toxic" in name or "spitter" in name:
            accent = (112, 255, 54)
        elif "phantom" in name or "necromancer" in name:
            accent = (180, 108, 255)
        elif "bomber" in name or "berserker" in name:
            accent = (255, 92, 28)
        elif "armored" in name or "juggernaut" in name or "warden" in name:
            accent = (236, 176, 76)
        else:
            accent = (255, 210, 86)
        polish_attack_sequence(folder, name, "attack", accent, False, written)

    boss_dir = ANIM_DIR / "bosses"
    for folder in sorted(p for p in boss_dir.iterdir() if p.is_dir()):
        name = folder.name
        if "frost" in name:
            accent = (96, 222, 255)
        elif "inferno" in name:
            accent = (255, 82, 22)
        elif "storm" in name:
            accent = (255, 230, 72)
        elif "plague" in name:
            accent = (112, 255, 54)
        elif "void" in name or "necro" in name or "apex" in name:
            accent = (188, 104, 255)
        else:
            accent = (238, 178, 74)
        polish_attack_sequence(folder, name, "attack", accent, True, written)
        polish_attack_sequence(folder, name, "special", accent, True, written)


def make_skill_cast_frame(skill_id: str, frame_index: int, total: int) -> Image.Image:
    size = (512, 512)
    p = frame_index / max(1, total - 1)
    pulse = math.sin(p * math.pi)
    color = SKILL_COLORS.get(skill_id, (255, 190, 60))
    hot = shift(color, 54)
    mode = VFX_CAST_MAP.get(skill_id, "crit")
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy = 256, 256
    img.alpha_composite(radial(size, (cx, cy), (*color, int(150 * pulse)), 190 + 40 * pulse, 2.2))
    img.alpha_composite(radial(size, (cx, cy), (*hot, int(170 * pulse)), 78 + 38 * pulse, 1.5))

    if mode in {"fan", "salvo"}:
        rays = 7 if mode == "salvo" else 5
        spread = math.radians(70 if mode == "salvo" else 52)
        length = 98 + 170 * pulse
        for i in range(rays):
            t = 0.5 if rays == 1 else i / (rays - 1)
            ang = -math.pi / 2 + (t - 0.5) * spread
            end = (cx + math.cos(ang) * length, cy + math.sin(ang) * length)
            d.line((cx, cy, end[0], end[1]), fill=(*color, int(92 + 120 * pulse)), width=max(3, int(9 * pulse)))
            d.ellipse((end[0] - 8, end[1] - 8, end[0] + 8, end[1] + 8), fill=(*hot, int(130 * pulse)))
    elif mode == "pierce":
        length = 130 + 190 * pulse
        d.line((cx - length * 0.55, cy, cx + length * 0.65, cy), fill=(*color, int(160 * pulse)), width=max(5, int(18 * pulse)))
        d.line((cx - length * 0.48, cy, cx + length * 0.55, cy), fill=(255, 255, 230, int(150 * pulse)), width=max(2, int(5 * pulse)))
        for off in [-48, 48]:
            d.arc((cx - 120, cy + off - 60, cx + 120, cy + off + 60), 190, 350, fill=(*color, int(70 * pulse)), width=4)
    elif mode in {"ice", "barrier"}:
        radius = 46 + 130 * pulse
        sides = 7 if mode == "barrier" else 12
        for i in range(sides):
            a = i * math.tau / sides + p * 0.6
            p1 = (cx + math.cos(a) * radius * 0.45, cy + math.sin(a) * radius * 0.45)
            p2 = (cx + math.cos(a + 0.07) * radius * 1.08, cy + math.sin(a + 0.07) * radius * 1.08)
            p3 = (cx + math.cos(a - 0.07) * radius * 0.82, cy + math.sin(a - 0.07) * radius * 0.82)
            d.polygon([p1, p2, p3], fill=(*color, int(74 * pulse)), outline=(220, 255, 255, int(92 * pulse)))
        d.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), outline=(*hot, int(130 * pulse)), width=5)
    elif mode == "lightning":
        RNG.seed(skill_id + str(frame_index))
        for b in range(5):
            pts = []
            for k in range(7):
                a = -math.pi / 2 + (b - 2) * 0.32
                r = 28 + k * (30 + 14 * pulse)
                pts.append((cx + math.cos(a) * r + RNG.randint(-16, 16), cy + math.sin(a) * r + RNG.randint(-18, 18)))
            d.line(pts, fill=(*color, int(140 * pulse)), width=7, joint="curve")
            d.line(pts, fill=(245, 255, 255, int(150 * pulse)), width=2, joint="curve")
    elif mode == "poison":
        RNG.seed(skill_id + str(frame_index))
        for _ in range(34):
            a = RNG.random() * math.tau
            r = RNG.uniform(8, 142 + 40 * pulse)
            rr = RNG.uniform(10, 34) * (0.6 + pulse)
            x = cx + math.cos(a) * r
            y = cy + math.sin(a) * r
            d.ellipse((x - rr, y - rr, x + rr, y + rr), fill=(*color, RNG.randint(28, int(80 + 54 * pulse))), outline=(*hot, RNG.randint(18, 80)))
    elif mode in {"target", "recycle", "gold", "crit", "charge"}:
        rings = 4 if mode == "charge" else 3
        for i in range(rings):
            rr = (48 + i * 42) + 62 * pulse
            start = int(30 + p * 220 + i * 52)
            d.arc((cx - rr, cy - rr, cx + rr, cy + rr), start, start + 245, fill=(*color, int((150 - i * 28) * pulse)), width=max(3, 8 - i))
        if mode == "gold":
            for i in range(10):
                a = i * math.tau / 10 + p
                x = cx + math.cos(a) * (72 + 74 * pulse)
                y = cy + math.sin(a) * (72 + 74 * pulse)
                d.rounded_rectangle((x - 8, y - 8, x + 8, y + 8), radius=4, fill=(*hot, int(130 * pulse)), outline=(*color, int(180 * pulse)))
    else:
        radius = 42 + 140 * pulse
        d.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), outline=(*color, int(150 * pulse)), width=8)
    return Image.alpha_composite(img.filter(ImageFilter.GaussianBlur(3.2)), img)


def sequence_id_for_skill(skill_id: str) -> str:
    return "vfx_skill_cast_" + skill_id.replace("skill_", "")


def generate_skill_cast_sequences(written: list[str]) -> None:
    for skill_id in SKILLS:
        sequence_id = sequence_id_for_skill(skill_id)
        folder = VFX_SEQ_DIR / sequence_id
        folder.mkdir(parents=True, exist_ok=True)
        frames = []
        total = 12
        for idx in range(1, total + 1):
            frame_path = folder / f"{sequence_id}_{idx:02d}.png"
            frame = make_skill_cast_frame(skill_id, idx - 1, total)
            save(frame_path, frame, written)
            frames.append(f"sprites/vfx_sequences/{sequence_id}/{sequence_id}_{idx:02d}.png")
        peak = make_skill_cast_frame(skill_id, 5, total)
        save(VFX_DIR / f"{sequence_id}.png", peak, written)
        seq_json = {
            "id": sequence_id,
            "fps": 18,
            "frames": frames,
        }
        json_path = folder / f"{sequence_id}_sequence.json"
        json_path.write_text(json.dumps(seq_json, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        written.append(str(json_path.relative_to(ROOT)))


def write_sequence(sequence_id: str, total: int, fps: int, maker, written: list[str], peak_index: int | None = None) -> None:
    folder = VFX_SEQ_DIR / sequence_id
    folder.mkdir(parents=True, exist_ok=True)
    frames = []
    for idx in range(total):
        frame_path = folder / f"{sequence_id}_{idx + 1:02d}.png"
        frame = maker(idx, total)
        save(frame_path, frame, written)
        frames.append(f"sprites/vfx_sequences/{sequence_id}/{sequence_id}_{idx + 1:02d}.png")
    peak_idx = total // 2 if peak_index is None else clampi(peak_index, 0, total - 1)
    save(VFX_DIR / f"{sequence_id}.png", maker(peak_idx, total), written)
    seq_json = {
        "id": sequence_id,
        "fps": fps,
        "frames": frames,
    }
    json_path = folder / f"{sequence_id}_sequence.json"
    json_path.write_text(json.dumps(seq_json, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    written.append(str(json_path.relative_to(ROOT)))


def clampi(v: int, lo: int, hi: int) -> int:
    return max(lo, min(hi, v))


def element_color(element: str) -> tuple[int, int, int]:
    return ELEMENT_COLORS.get(element, ELEMENT_COLORS["physical"])


def draw_energy_rays(d: ImageDraw.ImageDraw, center: tuple[float, float], color: tuple[int, int, int], count: int, length: float, width: int, alpha: int, spread: float = math.tau, rotation: float = -math.pi / 2) -> None:
    cx, cy = center
    for i in range(count):
        t = 0.5 if count <= 1 else float(i) / float(count - 1)
        angle = rotation + (t - 0.5) * spread
        end = (cx + math.cos(angle) * length, cy + math.sin(angle) * length)
        d.line((cx, cy, end[0], end[1]), fill=(*color, alpha), width=max(1, width))
        d.line((cx, cy, end[0], end[1]), fill=(255, 255, 230, max(0, alpha - 55)), width=max(1, width // 3))


def draw_lightning_path(d: ImageDraw.ImageDraw, start: tuple[float, float], end: tuple[float, float], color: tuple[int, int, int], alpha: int, width: int, seed: str) -> None:
    rng = random.Random(seed)
    sx, sy = start
    ex, ey = end
    dx, dy = ex - sx, ey - sy
    length = math.hypot(dx, dy)
    if length <= 1:
        return
    nx, ny = -dy / length, dx / length
    pts = []
    segments = 7
    for i in range(segments + 1):
        t = i / segments
        jitter = rng.uniform(-22.0, 22.0) * (1.0 - abs(t - 0.5) * 0.9)
        pts.append((sx + dx * t + nx * jitter, sy + dy * t + ny * jitter))
    d.line(pts, fill=(*color, alpha), width=width, joint="curve")
    d.line(pts, fill=(240, 255, 255, min(255, alpha + 30)), width=max(1, width // 3), joint="curve")


def make_hit_vfx_frame(element: str, idx: int, total: int) -> Image.Image:
    size = (512, 512)
    p = idx / max(1, total - 1)
    pulse = math.sin(p * math.pi)
    fade = max(0.0, 1.0 - p)
    color = element_color(element)
    hot = shift(color, 54)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy = 256, 258
    img.alpha_composite(radial(size, (cx, cy), (*color, int(130 * pulse)), 160 + 44 * pulse, 2.0))
    img.alpha_composite(radial(size, (cx, cy), (*hot, int(185 * pulse)), 58 + 44 * pulse, 1.4))
    if element == "fire":
        for i in range(14):
            a = -math.pi * 0.95 + i * math.pi * 1.9 / 13.0 + p * 0.35
            r = 34 + 128 * pulse + (i % 3) * 10
            tip = (cx + math.cos(a) * r, cy + math.sin(a) * r)
            base_l = (cx + math.cos(a - 0.18) * r * 0.36, cy + math.sin(a - 0.18) * r * 0.36)
            base_r = (cx + math.cos(a + 0.18) * r * 0.36, cy + math.sin(a + 0.18) * r * 0.36)
            d.polygon([base_l, tip, base_r], fill=(*color, int(82 * pulse)), outline=(255, 225, 120, int(78 * pulse)))
    elif element == "ice":
        for i in range(12):
            a = i * math.tau / 12.0 + p * 0.18
            r = 45 + 118 * pulse
            p1 = (cx + math.cos(a) * 30, cy + math.sin(a) * 30)
            p2 = (cx + math.cos(a + 0.05) * r, cy + math.sin(a + 0.05) * r)
            p3 = (cx + math.cos(a - 0.05) * r * 0.78, cy + math.sin(a - 0.05) * r * 0.78)
            d.polygon([p1, p2, p3], fill=(*color, int(68 * pulse)), outline=(230, 255, 255, int(105 * pulse)))
    elif element == "lightning":
        for i in range(7):
            a = -math.pi / 2 + (i - 3) * 0.34
            start = (cx + math.cos(a) * 20, cy + math.sin(a) * 18)
            end = (cx + math.cos(a) * (80 + 120 * pulse), cy + math.sin(a) * (80 + 120 * pulse))
            draw_lightning_path(d, start, end, color, int(148 * pulse), max(3, int(8 * pulse)), f"hit-{element}-{idx}-{i}")
    elif element == "poison":
        rng = random.Random(f"poison-hit-{idx}")
        for _ in range(28):
            a = rng.random() * math.tau
            r = rng.uniform(8, 142 + 36 * pulse)
            rr = rng.uniform(7, 24) * (0.5 + pulse)
            x = cx + math.cos(a) * r
            y = cy + math.sin(a) * r
            d.ellipse((x - rr, y - rr, x + rr, y + rr), fill=(*color, rng.randint(24, int(70 + 70 * pulse))), outline=(*hot, int(72 * pulse)))
    elif element == "immune":
        rr = 62 + 112 * pulse
        d.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), outline=(*color, int(160 * pulse)), width=max(4, int(12 * pulse)))
        for i in range(6):
            a = i * math.tau / 6.0 + p * 0.45
            x = cx + math.cos(a) * rr * 0.82
            y = cy + math.sin(a) * rr * 0.82
            d.rounded_rectangle((x - 12, y - 12, x + 12, y + 12), radius=4, fill=(225, 250, 255, int(92 * pulse)), outline=(*color, int(120 * pulse)))
    else:
        draw_energy_rays(d, (cx, cy), color, 12, 92 + 112 * pulse, max(3, int(9 * pulse)), int(130 * pulse), math.tau, p * 0.7)
        for i in range(3):
            rr = 44 + i * 46 + 80 * pulse
            d.arc((cx - rr, cy - rr, cx + rr, cy + rr), 205 + int(p * 100), 345 + int(p * 120), fill=(*color, int((110 - i * 22) * pulse)), width=max(2, 7 - i))
    d.ellipse((cx - 26, cy - 18, cx + 26, cy + 18), fill=(255, 252, 220, int(145 * pulse * fade)))
    return Image.alpha_composite(img.filter(ImageFilter.GaussianBlur(2.2)), img)


def make_enemy_skill_frame(kind: str, idx: int, total: int) -> Image.Image:
    size = (640, 640)
    p = idx / max(1, total - 1)
    pulse = math.sin(p * math.pi)
    mode = ENEMY_SKILL_SEQUENCE_KIND.get(kind, kind)
    palette = {
        "dash": ELEMENT_COLORS["lightning"],
        "charge": (255, 112, 36),
        "slam": ELEMENT_COLORS["armor"],
        "armor": ELEMENT_COLORS["armor"],
        "toxic": ELEMENT_COLORS["poison"],
        "aura": ELEMENT_COLORS["void"],
        "summon": ELEMENT_COLORS["void"],
        "phase": (138, 176, 255),
        "mutate": (220, 86, 255),
        "enrage": ELEMENT_COLORS["fire"],
        "fire": ELEMENT_COLORS["fire"],
        "frost": ELEMENT_COLORS["ice"],
        "storm": ELEMENT_COLORS["lightning"],
    }
    color = palette.get(mode, ELEMENT_COLORS["fire"])
    hot = shift(color, 52)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy = 320, 326
    img.alpha_composite(radial(size, (cx, cy), (*color, int(142 * pulse)), 220 + 58 * pulse, 2.0))
    if mode in {"dash", "charge"}:
        for i in range(5 if mode == "dash" else 7):
            y = cy - 72 + i * 34
            x0 = 96 + p * 54 + i * 12
            x1 = 500 + p * 72
            width = max(4, int((18 if mode == "charge" else 12) * pulse))
            d.line((x0, y, x1, y - 72 * pulse), fill=(*color, int(150 * pulse)), width=width)
            d.line((x0 + 28, y, x1 - 34, y - 56 * pulse), fill=(255, 250, 210, int(125 * pulse)), width=max(1, width // 3))
    elif mode == "slam":
        for i in range(5):
            rr = 54 + i * 38 + 100 * pulse
            d.arc((cx - rr, cy - rr * 0.45, cx + rr, cy + rr * 0.45), 185, 355, fill=(*color, int((142 - i * 18) * pulse)), width=max(3, 12 - i))
        for i in range(16):
            a = math.pi + i * math.pi / 15.0
            r = 90 + 180 * pulse
            d.line((cx, cy + 38, cx + math.cos(a) * r, cy + 38 + math.sin(a) * r * 0.45), fill=(*hot, int(72 * pulse)), width=4)
    elif mode == "armor":
        rr = 92 + 126 * pulse
        d.rounded_rectangle((cx - rr, cy - rr, cx + rr, cy + rr), radius=42, outline=(*color, int(165 * pulse)), width=10)
        for i in range(8):
            a = i * math.tau / 8.0 + p
            d.line((cx + math.cos(a) * 58, cy + math.sin(a) * 58, cx + math.cos(a) * rr, cy + math.sin(a) * rr), fill=(255, 245, 210, int(95 * pulse)), width=3)
    elif mode == "toxic":
        rng = random.Random(f"enemy-toxic-{kind}-{idx}")
        for _ in range(42):
            a = rng.random() * math.tau
            r = rng.uniform(8, 190 + 54 * pulse)
            rr = rng.uniform(10, 36) * (0.55 + pulse)
            x = cx + math.cos(a) * r
            y = cy + math.sin(a) * r * 0.78
            d.ellipse((x - rr, y - rr, x + rr, y + rr), fill=(*color, rng.randint(28, int(82 + 66 * pulse))), outline=(*hot, int(76 * pulse)))
    elif mode in {"aura", "summon", "phase", "mutate"}:
        sides = 7 if mode == "summon" else 10
        for i in range(4):
            rr = 70 + i * 42 + 86 * pulse
            start = 30 + i * 58 + int(p * 210)
            d.arc((cx - rr, cy - rr, cx + rr, cy + rr), start, start + 250, fill=(*color, int((150 - i * 22) * pulse)), width=max(3, 9 - i))
        pts = []
        rr = 74 + 126 * pulse
        for i in range(sides):
            a = i * math.tau / sides + p * 0.9
            pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
        d.polygon(pts, outline=(235, 210, 255, int(86 * pulse)), fill=(*color, int(28 * pulse)))
    elif mode in {"enrage", "fire"}:
        for i in range(18):
            a = i * math.tau / 18.0 + p * 0.3
            r = 68 + 180 * pulse + (i % 4) * 10
            d.polygon([
                (cx + math.cos(a - 0.08) * 54, cy + math.sin(a - 0.08) * 54),
                (cx + math.cos(a) * r, cy + math.sin(a) * r),
                (cx + math.cos(a + 0.08) * 54, cy + math.sin(a + 0.08) * 54),
            ], fill=(*color, int(76 * pulse)), outline=(255, 225, 120, int(76 * pulse)))
    elif mode == "frost":
        for i in range(16):
            a = i * math.tau / 16.0 + p * 0.2
            r = 82 + 160 * pulse
            d.polygon([
                (cx + math.cos(a) * 42, cy + math.sin(a) * 42),
                (cx + math.cos(a + 0.04) * r, cy + math.sin(a + 0.04) * r),
                (cx + math.cos(a - 0.04) * r * 0.72, cy + math.sin(a - 0.04) * r * 0.72),
            ], fill=(*color, int(66 * pulse)), outline=(235, 255, 255, int(106 * pulse)))
    elif mode == "storm":
        for i in range(9):
            a = -math.pi / 2 + (i - 4) * 0.25
            start = (cx + math.cos(a) * 36, cy + math.sin(a) * 32)
            end = (cx + math.cos(a) * (140 + 160 * pulse), cy + math.sin(a) * (140 + 160 * pulse))
            draw_lightning_path(d, start, end, color, int(156 * pulse), max(3, int(9 * pulse)), f"enemy-storm-{idx}-{i}")
    img.alpha_composite(radial(size, (cx, cy), (*hot, int(170 * pulse)), 86 + 38 * pulse, 1.35))
    return Image.alpha_composite(img.filter(ImageFilter.GaussianBlur(2.6)), img)


def make_active_skill_frame(active_id: str, idx: int, total: int) -> Image.Image:
    size = (768, 768)
    p = idx / max(1, total - 1)
    pulse = math.sin(p * math.pi)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy = 384, 390
    if active_id in {"sig_vanguard_railvolley", "sig_vanguard_overload"}:
        color = ELEMENT_COLORS["lightning"] if active_id == "sig_vanguard_railvolley" else ELEMENT_COLORS["fire"]
        img.alpha_composite(radial(size, (cx, cy), (*color, int(138 * pulse)), 250 + 80 * pulse, 1.7))
        draw_energy_rays(d, (cx, cy + 70), color, 13, 170 + 240 * pulse, max(5, int(13 * pulse)), int(160 * pulse), math.radians(72), -math.pi / 2)
        for i in range(6):
            x = cx + (i - 2.5) * 50
            d.rounded_rectangle((x - 8, cy + 74 - 24 * pulse, x + 8, cy + 116 + 40 * pulse), radius=5, fill=(255, 245, 190, int(110 * pulse)))
    elif active_id == "sig_blaze_meltdown":
        color = ELEMENT_COLORS["fire"]
        img.alpha_composite(radial(size, (cx, cy), (*color, int(172 * pulse)), 260 + 110 * pulse, 1.5))
        for i in range(22):
            a = i * math.tau / 22.0 + p * 0.4
            r = 92 + 250 * pulse + (i % 5) * 12
            d.polygon([
                (cx + math.cos(a - 0.07) * 64, cy + math.sin(a - 0.07) * 64),
                (cx + math.cos(a) * r, cy + math.sin(a) * r),
                (cx + math.cos(a + 0.07) * 64, cy + math.sin(a + 0.07) * 64),
            ], fill=(*color, int(80 * pulse)), outline=(255, 232, 128, int(90 * pulse)))
        for i in range(4):
            rr = 94 + i * 60 + 92 * pulse
            d.ellipse((cx - rr, cy - rr * 0.62, cx + rr, cy + rr * 0.62), outline=(255, 178, 70, int((120 - i * 20) * pulse)), width=max(4, 12 - i))
    elif active_id == "sig_frost_glacier":
        color = ELEMENT_COLORS["ice"]
        img.alpha_composite(radial(size, (cx, cy), (*color, int(150 * pulse)), 270 + 96 * pulse, 1.8))
        for i in range(24):
            a = i * math.tau / 24.0 + p * 0.16
            r = 90 + 230 * pulse
            d.polygon([
                (cx + math.cos(a) * 48, cy + math.sin(a) * 32),
                (cx + math.cos(a + 0.035) * r, cy + math.sin(a + 0.035) * r * 0.78),
                (cx + math.cos(a - 0.035) * r * 0.72, cy + math.sin(a - 0.035) * r * 0.72),
            ], fill=(*color, int(58 * pulse)), outline=(235, 255, 255, int(115 * pulse)))
        for i in range(5):
            rr = 70 + i * 52 + 70 * pulse
            d.arc((cx - rr, cy - rr * 0.5, cx + rr, cy + rr * 0.5), 175, 365, fill=(210, 250, 255, int((126 - i * 18) * pulse)), width=max(3, 9 - i))
    elif active_id == "sig_volt_storm":
        color = ELEMENT_COLORS["lightning"]
        img.alpha_composite(radial(size, (cx, cy), (*color, int(148 * pulse)), 280 + 108 * pulse, 1.6))
        for i in range(13):
            a = -math.pi / 2 + (i - 6) * 0.21
            start = (cx + math.cos(a) * 40, cy + math.sin(a) * 34)
            end = (cx + math.cos(a) * (150 + 235 * pulse), cy + math.sin(a) * (150 + 235 * pulse))
            draw_lightning_path(d, start, end, color, int(165 * pulse), max(3, int(10 * pulse)), f"active-volt-{idx}-{i}")
        for i in range(4):
            rr = 70 + i * 58 + 80 * pulse
            d.arc((cx - rr, cy - rr, cx + rr, cy + rr), 25 + int(p * 160) + i * 42, 295 + int(p * 180) + i * 42, fill=(*color, int((120 - i * 20) * pulse)), width=max(3, 9 - i))
    return Image.alpha_composite(img.filter(ImageFilter.GaussianBlur(2.8)), img)


def generate_hit_vfx_sequences(written: list[str]) -> None:
    for element in ["physical", "fire", "ice", "lightning", "poison", "immune"]:
        sequence_id = f"vfx_hit_{element}"
        write_sequence(sequence_id, 12, 20, lambda idx, total, e=element: make_hit_vfx_frame(e, idx, total), written)


def generate_enemy_skill_sequences(written: list[str]) -> None:
    for kind in sorted(ENEMY_SKILL_SEQUENCE_KIND.keys()):
        sequence_id = "vfx_enemy_skill_" + kind
        write_sequence(sequence_id, 12, 18, lambda idx, total, k=kind: make_enemy_skill_frame(k, idx, total), written)


def generate_character_active_sequences(written: list[str]) -> None:
    for active_id in ACTIVE_SKILLS:
        sequence_id = "vfx_active_" + active_id
        write_sequence(sequence_id, 14, 20, lambda idx, total, a=active_id: make_active_skill_frame(a, idx, total), written)


def make_contact_sheet(paths: list[str], out: Path, title: str, max_items: int = 120) -> str:
    selected = [ROOT / p for p in paths if p.endswith(".png") and (ROOT / p).exists()]
    selected = selected[:max_items]
    cols = 6
    cell_w, cell_h = 240, 216
    rows = max(1, math.ceil(len(selected) / cols))
    header = 54
    sheet = Image.new("RGBA", (cols * cell_w, header + rows * cell_h), (8, 12, 18, 255))
    d = ImageDraw.Draw(sheet, "RGBA")
    d.text((18, 17), title, fill=(232, 240, 246, 255))
    for i, path in enumerate(selected):
        x = (i % cols) * cell_w
        y = header + (i // cols) * cell_h
        d.rounded_rectangle((x + 10, y + 10, x + cell_w - 10, y + cell_h - 10), radius=9, fill=(14, 20, 29, 255), outline=(74, 98, 118, 180), width=1)
        im = Image.open(path).convert("RGBA")
        im.thumbnail((168, 140), Image.Resampling.LANCZOS)
        sheet.alpha_composite(im, (x + (cell_w - im.width) // 2, y + 20))
        label = path.stem
        if len(label) > 27:
            label = label[:26] + "..."
        d.text((x + 16, y + 172), label, fill=(214, 228, 236, 255))
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    return str(out.relative_to(ROOT))


def make_motion_sheet(out: Path) -> str:
    samples: list[tuple[str, list[Path]]] = []
    for folder in sorted((ANIM_DIR / "zombies").iterdir()):
        if folder.is_dir():
            samples.append((folder.name, sorted(folder.glob(f"{folder.name}_attack_*.png"))))
    for folder in sorted((ANIM_DIR / "bosses").iterdir()):
        if folder.is_dir():
            samples.append((folder.name + " attack", sorted(folder.glob(f"{folder.name}_attack_*.png"))))
            samples.append((folder.name + " special", sorted(folder.glob(f"{folder.name}_special_*.png"))))
    cols = 3
    cell_w, cell_h = 470, 190
    header = 54
    rows = max(1, math.ceil(len(samples) / cols))
    sheet = Image.new("RGBA", (cols * cell_w, header + rows * cell_h), (8, 12, 18, 255))
    d = ImageDraw.Draw(sheet, "RGBA")
    d.text((18, 17), "Top-tier attack motion polish strips", fill=(232, 240, 246, 255))
    for i, (label, frames) in enumerate(samples):
        x = (i % cols) * cell_w
        y = header + (i // cols) * cell_h
        d.rounded_rectangle((x + 10, y + 10, x + cell_w - 10, y + cell_h - 10), radius=9, fill=(14, 20, 29, 255), outline=(108, 76, 76, 180), width=1)
        max_frames = 8
        if len(frames) > max_frames:
            idxs = [round(k * (len(frames) - 1) / (max_frames - 1)) for k in range(max_frames)]
            frames = [frames[k] for k in idxs]
        for j, frame in enumerate(frames):
            im = Image.open(frame).convert("RGBA")
            bbox = im.getbbox()
            if bbox:
                im = im.crop(bbox)
            im.thumbnail((50, 112), Image.Resampling.LANCZOS)
            px = x + 24 + j * 52 + (50 - im.width) // 2
            py = y + 24 + (112 - im.height) // 2
            sheet.alpha_composite(im, (px, py))
        d.text((x + 18, y + 150), label[:48], fill=(214, 228, 236, 255))
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    return str(out.relative_to(ROOT))


def copy_reference(path: str | None, label: str = "ui_motion_top_tier_reference") -> str | None:
    if not path:
        return None
    src = Path(path)
    if not src.exists():
        return None
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    dest = SOURCE_DIR / f"{label}_{STAMP}.png"
    shutil.copy2(src, dest)
    return str(dest.relative_to(ROOT))


def write_spec(written: list[str], reference: str | None, contact_sheets: list[str]) -> str:
    spec = {
        "id": "top_tier_ui_motion_second_pass",
        "generated_by": "tools/generate_top_tier_ui_motion_pass.py",
        "built_in_image_gen_reference": reference,
        "quality_target": "Top-tier App Store-grade raster-rendered UI components, attack motion frames, and skill cast VFX; no SVG or vector source assets.",
        "runtime_policy": "Visual-only pass. Existing IDs, paths, gameplay data, damage, collision, waves, economy, and scope are preserved.",
        "scope": [
            "all production UI PNGs plus extra bitmap skins for hints, icon frames, modal buttons, level cards, and bar fills",
            "zombie attack animation frames",
            "boss attack and special animation frames",
            "per-skill cast VFX sequences and peak sprites",
            "elemental hit VFX sequences and peak sprites",
            "enemy mechanic/skill VFX sequences and peak sprites",
            "character active skill VFX sequences and peak sprites",
        ],
        "contact_sheets": contact_sheets,
        "written_count": len(written),
        "written": written,
    }
    path = SOURCE_DIR / f"top_tier_ui_motion_second_pass_spec_{STAMP}.json"
    path.write_text(json.dumps(spec, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return str(path.relative_to(ROOT))


def update_asset_index(spec_path: str, contact_sheets: list[str]) -> None:
    data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
    data["counts"]["total_files"] = sum(1 for path in PROD.rglob("*") if path.is_file())
    overrides = data.setdefault("owner_directed_generated_overrides", [])
    paths = {
        "sprites/ui/full_component_skin_pass",
        "sprites/animations/zombies/attack_motion",
        "sprites/animations/bosses/attack_special_motion",
        "sprites/vfx_sequences/skill_cast",
        "sprites/vfx/skill_cast_peaks",
        "sprites/vfx_sequences/hit_vfx",
        "sprites/vfx_sequences/enemy_skill_vfx",
        "sprites/vfx_sequences/character_active_vfx",
        "sprites/vfx/combat_vfx_peaks",
    }
    overrides = [item for item in overrides if item.get("path") not in paths]
    derived = ", ".join(p.replace("assets/production/", "") for p in contact_sheets)
    for path in sorted(paths):
        overrides.append(
            {
                "path": path,
                "source": spec_path.replace("assets/production/", ""),
                "derived": derived,
                "reason": "Owner requested all remaining UI borders, hints, bars, buttons, zombie attacks, and skill motion to be raised to top-tier rendered App Store raster quality with no SVG/vector treatment.",
            }
        )
    data["owner_directed_generated_overrides"] = overrides
    INDEX_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--reference", default="")
    parser.add_argument("--combat-vfx-only", action="store_true")
    args = parser.parse_args()

    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    CONTACT_DIR.mkdir(parents=True, exist_ok=True)
    written: list[str] = []
    reference = copy_reference(args.reference, "combat_vfx_top_tier_reference" if args.combat_vfx_only else "ui_motion_top_tier_reference")
    contact_sheets: list[str] = []
    if not args.combat_vfx_only:
        generate_ui(Path(args.reference) if args.reference else None, written)
        generate_attack_motion(written)
        generate_skill_cast_sequences(written)
        ui_sheet = make_contact_sheet(
            [p for p in written if p.startswith("assets/production/sprites/ui/")],
            CONTACT_DIR / f"contact_ui_component_polish_{STAMP}.png",
            "Top-tier UI component polish",
            110,
        )
        motion_sheet = make_motion_sheet(CONTACT_DIR / f"contact_attack_motion_polish_{STAMP}.png")
        skill_sheet = make_contact_sheet(
            [p for p in written if f"vfx_skill_cast_" in p and p.endswith(".png")],
            CONTACT_DIR / f"contact_skill_cast_vfx_{STAMP}.png",
            "Top-tier skill cast VFX",
            120,
        )
        contact_sheets += [ui_sheet, motion_sheet, skill_sheet]
    generate_hit_vfx_sequences(written)
    generate_enemy_skill_sequences(written)
    generate_character_active_sequences(written)
    hit_sheet = make_contact_sheet(
        [p for p in written if "/vfx_hit_" in p and p.endswith(".png")],
        CONTACT_DIR / f"contact_hit_vfx_polish_{STAMP}.png",
        "Top-tier zombie hit VFX",
        90,
    )
    enemy_skill_sheet = make_contact_sheet(
        [p for p in written if "/vfx_enemy_skill_" in p and p.endswith(".png")],
        CONTACT_DIR / f"contact_enemy_skill_vfx_{STAMP}.png",
        "Top-tier zombie skill VFX",
        120,
    )
    active_sheet = make_contact_sheet(
        [p for p in written if "/vfx_active_" in p and p.endswith(".png")],
        CONTACT_DIR / f"contact_character_active_vfx_{STAMP}.png",
        "Top-tier character active skill VFX",
        110,
    )
    contact_sheets += [hit_sheet, enemy_skill_sheet, active_sheet]
    spec_path = write_spec(written, reference, contact_sheets)
    update_asset_index(spec_path, contact_sheets)
    print(f"Top-tier UI/motion pass wrote {len(written)} files")
    for sheet in contact_sheets:
        print(sheet)
    print(spec_path)
    if reference:
        print(reference)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
