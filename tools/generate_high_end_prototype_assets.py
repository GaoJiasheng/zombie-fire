#!/usr/bin/env python3
from __future__ import annotations

import json
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / "assets" / "production"
SOURCE_DIR = PROD / "source_refs" / "generated"
INDEX_PATH = PROD / "OUTSOURCER_ASSET_INDEX.json"

CHAR_ASSET_IDS = {
    "vanguard": "char_vanguard",
    "blaze": "char_blaze",
    "frost": "char_frost",
    "volt": "char_volt",
}

ACTION_FRAME_HINTS = {
    "idle": (1, 4),
    "walk": (1, 6),
    "attack": (1, 4),
    "special": (1, 6),
    "hurt": (1, 3),
    "death": (1, 6),
}


def rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = hex_color.lstrip("#")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), alpha)


def accent_for_id(asset_id: str) -> tuple[int, int, int]:
    key = asset_id.lower()
    if any(token in key for token in ("fire", "flame", "blaze", "inferno", "burn", "magma")):
        return (255, 134, 46)
    if any(token in key for token in ("ice", "frost", "cryo", "glacier")):
        return (90, 211, 255)
    if any(token in key for token in ("volt", "storm", "tesla", "lightning", "chain")):
        return (190, 126, 255)
    if any(token in key for token in ("poison", "venom", "toxic", "plague", "acid")):
        return (105, 245, 80)
    if any(token in key for token in ("boss", "tank", "apex", "juggernaut", "armored", "warden")):
        return (219, 169, 94)
    if any(token in key for token in ("rail", "physical", "vanguard", "autocannon", "scatter")):
        return (245, 177, 78)
    return (98, 213, 232)


def load_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def alpha_bbox(image: Image.Image, pad: int = 0) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return (0, 0, image.width, image.height)
    left, top, right, bottom = bbox
    return (
        max(0, left - pad),
        max(0, top - pad),
        min(image.width, right + pad),
        min(image.height, bottom + pad),
    )


def crop_visible(image: Image.Image, pad: int = 10) -> Image.Image:
    return image.crop(alpha_bbox(image, pad))


def enhance(image: Image.Image, contrast: float = 1.08, color: float = 1.06, sharpness: float = 1.12) -> Image.Image:
    alpha = image.getchannel("A")
    rgb = image.convert("RGB")
    rgb = ImageEnhance.Contrast(rgb).enhance(contrast)
    rgb = ImageEnhance.Color(rgb).enhance(color)
    rgb = ImageEnhance.Sharpness(rgb).enhance(sharpness)
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    return out


def enforce_transparent_margin(image: Image.Image, margin: int = 3) -> Image.Image:
    if margin <= 0:
        return image
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    for y in range(height):
        for x in range(width):
            if x < margin or y < margin or x >= width - margin or y >= height - margin:
                r, g, b, _a = pixels[x, y]
                pixels[x, y] = (r, g, b, 0)
    return image


def fit_subject(
    image: Image.Image,
    canvas: tuple[int, int],
    target_h: int,
    target_w: int | None = None,
    bottom: int | None = None,
    x_shift: int = 0,
) -> Image.Image:
    subject = crop_visible(image, 14)
    target_w = target_w or canvas[0]
    scale = min(target_w / max(subject.width, 1), target_h / max(subject.height, 1))
    size = (max(1, round(subject.width * scale)), max(1, round(subject.height * scale)))
    subject = subject.resize(size, Image.Resampling.LANCZOS)
    out = Image.new("RGBA", canvas, (0, 0, 0, 0))
    bottom = bottom if bottom is not None else canvas[1] - 22
    pos = ((canvas[0] - subject.width) // 2 + x_shift, bottom - subject.height)
    out.alpha_composite(subject, pos)
    return out


def add_shadow(base: Image.Image, bbox: tuple[int, int, int, int], opacity: int = 72) -> Image.Image:
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow, "RGBA")
    left, top, right, bottom = bbox
    width = max(18, right - left)
    height = max(8, int(width * 0.16))
    cx = (left + right) * 0.5
    y = bottom - height * 0.18
    draw.ellipse((cx - width * 0.42, y - height * 0.5, cx + width * 0.42, y + height * 0.5), fill=(0, 0, 0, opacity))
    return Image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(6)), base)


def polish_transparent_sprite(
    image: Image.Image,
    asset_id: str,
    add_floor_shadow: bool = True,
    action: str = "",
    frame_index: int = 1,
) -> Image.Image:
    image = image.convert("RGBA")
    accent = accent_for_id(asset_id)
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return image
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    glow_mask = alpha.filter(ImageFilter.GaussianBlur(8))
    glow = Image.new("RGBA", image.size, (*accent, 58))
    glow.putalpha(glow_mask.point(lambda a: int(a * 0.42)))
    out.alpha_composite(glow)
    outline_mask = alpha.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(1.2))
    outline = Image.new("RGBA", image.size, (230, 238, 244, 90))
    outline.putalpha(outline_mask.point(lambda a: min(82, int(a * 0.26))))
    out.alpha_composite(outline)
    if add_floor_shadow:
        out = add_shadow(out, bbox, 58)
    out.alpha_composite(enhance(image))
    if action == "attack":
        out.alpha_composite(make_action_flash(image.size, bbox, asset_id, frame_index))
    elif action == "hurt":
        out.alpha_composite(make_hurt_sparks(image.size, bbox, asset_id, frame_index))
    elif action == "death":
        out.alpha_composite(make_death_particles(image.size, bbox, asset_id, frame_index))
    return enforce_transparent_margin(out, 3)


def make_action_flash(size: tuple[int, int], bbox: tuple[int, int, int, int], asset_id: str, frame_index: int) -> Image.Image:
    accent = accent_for_id(asset_id)
    fx = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(fx, "RGBA")
    left, top, right, bottom = bbox
    cx = (left + right) * 0.5
    cy = top + (bottom - top) * 0.52
    radius = max(right - left, bottom - top) * (0.36 + 0.03 * frame_index)
    for i in range(3):
        angle = -46 + i * 31 + frame_index * 4
        rad = math.radians(angle)
        x1 = cx + math.cos(rad) * radius * 0.16
        y1 = cy + math.sin(rad) * radius * 0.16
        x2 = cx + math.cos(rad) * radius
        y2 = cy + math.sin(rad) * radius
        draw.line((x1, y1, x2, y2), fill=(*accent, 70), width=max(2, int(radius * 0.035)))
    return fx.filter(ImageFilter.GaussianBlur(1.0))


def make_hurt_sparks(size: tuple[int, int], bbox: tuple[int, int, int, int], asset_id: str, frame_index: int) -> Image.Image:
    random.seed(f"{asset_id}:hurt:{frame_index}")
    fx = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(fx, "RGBA")
    left, top, right, bottom = bbox
    for _ in range(9):
        x = random.uniform(left + (right - left) * 0.2, right - (right - left) * 0.12)
        y = random.uniform(top + (bottom - top) * 0.18, bottom - (bottom - top) * 0.18)
        length = random.uniform(8, 24)
        angle = random.uniform(-2.8, -0.4)
        draw.line((x, y, x + math.cos(angle) * length, y + math.sin(angle) * length), fill=(255, 92, 46, 118), width=2)
    return fx.filter(ImageFilter.GaussianBlur(0.6))


def make_death_particles(size: tuple[int, int], bbox: tuple[int, int, int, int], asset_id: str, frame_index: int) -> Image.Image:
    random.seed(f"{asset_id}:death:{frame_index}")
    accent = accent_for_id(asset_id)
    fx = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(fx, "RGBA")
    left, top, right, bottom = bbox
    progress = min(1.0, frame_index / 6.0)
    for _ in range(22):
        x = random.uniform(left, right)
        y = random.uniform(top, bottom)
        r = random.uniform(1.6, 5.0) * (0.8 + progress)
        draw.ellipse((x - r, y - r, x + r, y + r), fill=(*accent, int(42 + progress * 76)))
    return fx.filter(ImageFilter.GaussianBlur(1.2))


def make_card_icon(subject: Image.Image, asset_id: str, size: int = 256, crop_top_ratio: float | None = None) -> Image.Image:
    accent = accent_for_id(asset_id)
    if crop_top_ratio is not None:
        bbox = alpha_bbox(subject, 8)
        h = bbox[3] - bbox[1]
        subject = subject.crop((bbox[0], bbox[1], bbox[2], min(bbox[3], int(bbox[1] + h * crop_top_ratio))))
    subject = crop_visible(subject, 8)
    scale = min((size - 52) / max(subject.width, 1), (size - 48) / max(subject.height, 1))
    subject = subject.resize((max(1, round(subject.width * scale)), max(1, round(subject.height * scale))), Image.Resampling.LANCZOS)

    card = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(card, "RGBA")
    for y in range(size):
        t = y / max(1, size - 1)
        bg = (
            int(8 + accent[0] * 0.035 + t * 4),
            int(13 + accent[1] * 0.03 + t * 5),
            int(18 + accent[2] * 0.025 + t * 7),
            232,
        )
        draw.line((0, y, size, y), fill=bg)
    draw.rounded_rectangle((8, 8, size - 8, size - 8), radius=18, outline=(*accent, 210), width=3)
    draw.rounded_rectangle((18, 18, size - 18, size - 18), radius=12, outline=(220, 230, 238, 82), width=2)
    for corner in ((18, 18), (size - 18, 18), (18, size - 18), (size - 18, size - 18)):
        x, y = corner
        draw.ellipse((x - 5, y - 5, x + 5, y + 5), fill=(*accent, 185))
    glow_mask = subject.getchannel("A").filter(ImageFilter.GaussianBlur(9))
    glow = Image.new("RGBA", subject.size, (*accent, 95))
    glow.putalpha(glow_mask)
    x = (size - subject.width) // 2
    y = (size - subject.height) // 2 + 6
    card.alpha_composite(glow, (x, y))
    card.alpha_composite(enhance(subject, 1.07, 1.06, 1.12), (x, y))
    return card


def make_character_bust(character_id: str) -> Image.Image:
    source = load_rgba(PROD / "sprites" / "animations" / "characters_weaponless" / character_id / f"{character_id}_idle_01.png")
    source = polish_transparent_sprite(source, character_id, False)
    bbox = alpha_bbox(source, 10)
    left, top, right, bottom = bbox
    height = bottom - top
    bust = source.crop((left, top, right, min(bottom, int(top + height * 0.70))))
    return fit_subject(bust, (768, 960), 880, 690, 928)


def generate_character_prototypes() -> list[str]:
    written: list[str] = []
    char_dir = PROD / "sprites" / "characters"
    for character_id in CHAR_ASSET_IDS.values():
        bust = make_character_bust(character_id)
        proto_path = char_dir / f"{character_id}_prototype.png"
        icon_path = char_dir / f"{character_id}_icon.png"
        bust.save(proto_path)
        make_card_icon(bust, character_id, 256).save(icon_path)
        written.extend([str(proto_path.relative_to(ROOT)), str(icon_path.relative_to(ROOT))])
    return written


def representative_frame(folder: Path, asset_id: str, preferred: str = "idle") -> Image.Image:
    candidates = [
        folder / f"{asset_id}_{preferred}_01.png",
        folder / f"{asset_id}_walk_03.png",
        folder / f"{asset_id}_idle_01.png",
        folder / f"{asset_id}_attack_01.png",
    ]
    for path in candidates:
        if path.exists():
            return load_rgba(path)
    files = sorted(folder.glob("*.png"))
    if not files:
        raise FileNotFoundError(folder)
    return load_rgba(files[0])


def make_entity_prototype(asset_id: str, family: str, boss: bool = False) -> Image.Image:
    folder = PROD / "sprites" / "animations" / family / asset_id
    source = representative_frame(folder, asset_id, "idle")
    polished = polish_transparent_sprite(source, asset_id, True)
    if boss:
        return fit_subject(polished, (1024, 1536), 1380, 960, 1470)
    return fit_subject(polished, (1024, 1536), 1280, 820, 1458)


def generate_enemy_and_boss_prototypes() -> list[str]:
    written: list[str] = []
    zombies = json.loads((ROOT / "data" / "zombies.json").read_text(encoding="utf-8"))
    bosses = json.loads((ROOT / "data" / "bosses.json").read_text(encoding="utf-8"))
    for zombie_id in zombies:
        proto = make_entity_prototype(zombie_id, "zombies", False)
        proto_path = PROD / "sprites" / "zombies" / f"{zombie_id}_prototype.png"
        icon_path = PROD / "sprites" / "zombies" / f"{zombie_id}_icon.png"
        proto.save(proto_path)
        make_card_icon(proto, zombie_id, 256).save(icon_path)
        legacy_path = ROOT / "assets" / "sprites" / "zombies" / f"{zombie_id}_prototype.png"
        if legacy_path.exists():
            proto.save(legacy_path)
            written.append(str(legacy_path.relative_to(ROOT)))
        written.extend([str(proto_path.relative_to(ROOT)), str(icon_path.relative_to(ROOT))])
    for boss_id in bosses:
        proto = make_entity_prototype(boss_id, "bosses", True)
        proto_path = PROD / "sprites" / "bosses" / f"{boss_id}_prototype.png"
        icon_path = PROD / "sprites" / "bosses" / f"{boss_id}_icon.png"
        proto.save(proto_path)
        make_card_icon(proto, boss_id, 256).save(icon_path)
        legacy_path = ROOT / "assets" / "sprites" / "bosses" / f"{boss_id}_prototype.png"
        if legacy_path.exists():
            proto.save(legacy_path)
            written.append(str(legacy_path.relative_to(ROOT)))
        written.extend([str(proto_path.relative_to(ROOT)), str(icon_path.relative_to(ROOT))])
    return written


def generate_pet_prototypes() -> list[str]:
    written: list[str] = []
    pets = json.loads((ROOT / "data" / "pets.json").read_text(encoding="utf-8"))
    for pet_id in pets:
        path = PROD / "sprites" / "pets" / f"{pet_id}_prototype.png"
        source = load_rgba(path)
        polished = polish_transparent_sprite(fit_subject(source, (512, 512), 430, 430, 472), pet_id, True)
        polished.save(path)
        make_card_icon(polished, pet_id, 256).save(PROD / "sprites" / "pets" / f"{pet_id}_icon.png")
        written.extend([str(path.relative_to(ROOT)), str((PROD / "sprites" / "pets" / f"{pet_id}_icon.png").relative_to(ROOT))])
    return written


def polish_animation_tree(root: Path, asset_ids: list[str], family: str) -> list[str]:
    written: list[str] = []
    for asset_id in asset_ids:
        folder = root / asset_id
        if not folder.exists():
            continue
        for path in sorted(folder.glob("*.png")):
            stem = path.stem
            action = ""
            frame_index = 1
            parts = stem.split("_")
            if len(parts) >= 2 and parts[-1].isdigit():
                frame_index = int(parts[-1])
                action = parts[-2]
            img = load_rgba(path)
            polished = polish_transparent_sprite(img, asset_id, family != "character_weapon_combos", action, frame_index)
            polished.save(path)
            written.append(str(path.relative_to(ROOT)))
    return written


def make_vfx_frame(seq_id: str, index: int, total: int, size: int = 384) -> Image.Image:
    random.seed(f"{seq_id}:{index}")
    accent = accent_for_id(seq_id)
    progress = (index - 1) / max(1, total - 1)
    pulse = math.sin(progress * math.pi)
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    cx = cy = size * 0.5
    radius = 26 + pulse * 122

    def ring(color: tuple[int, int, int], width: int, alpha: int, scale: float = 1.0) -> None:
        r = radius * scale
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(*color, alpha), width=width)

    if "lightning" in seq_id or "chain" in seq_id or "tesla" in seq_id:
        for branch in range(7):
            angle = -1.35 + branch * 0.45 + progress * 0.7
            points = [(cx, cy)]
            for step in range(1, 6):
                dist = (24 + step * 24) * (0.58 + pulse * 0.55)
                jitter = random.uniform(-16, 16)
                points.append((cx + math.cos(angle) * dist + jitter, cy + math.sin(angle) * dist + random.uniform(-10, 10)))
            draw.line(points, fill=(*accent, int(130 + pulse * 105)), width=5, joint="curve")
            draw.line(points, fill=(255, 248, 160, int(110 + pulse * 110)), width=2, joint="curve")
        ring((255, 230, 86), 4, int(90 + 120 * pulse), 0.58)
    elif "ice" in seq_id or "freeze" in seq_id or "cryo" in seq_id:
        for shard in range(12):
            angle = shard * math.tau / 12 + progress * 0.18
            r1 = 20 + radius * 0.38
            r2 = 46 + radius * 0.95
            p1 = (cx + math.cos(angle) * r1, cy + math.sin(angle) * r1)
            p2 = (cx + math.cos(angle + 0.09) * r2, cy + math.sin(angle + 0.09) * r2)
            p3 = (cx + math.cos(angle - 0.09) * (r2 * 0.72), cy + math.sin(angle - 0.09) * (r2 * 0.72))
            draw.polygon((p1, p2, p3), fill=(*accent, int(72 + pulse * 90)), outline=(220, 250, 255, int(80 + pulse * 120)))
        ring(accent, 5, int(80 + pulse * 120), 0.7)
    elif "poison" in seq_id or "venom" in seq_id or "acid" in seq_id:
        for _ in range(26):
            angle = random.random() * math.tau
            dist = random.uniform(8, radius)
            x = cx + math.cos(angle) * dist
            y = cy + math.sin(angle) * dist
            rr = random.uniform(4, 18) * (0.7 + pulse * 0.8)
            draw.ellipse((x - rr, y - rr, x + rr, y + rr), fill=(*accent, int(42 + pulse * 110)))
        ring(accent, 8, int(78 + pulse * 92), 0.9)
    elif "fire" in seq_id or "explosion" in seq_id or "muzzle" in seq_id and "physical" not in seq_id:
        for flame in range(18):
            angle = flame * math.tau / 18 + random.uniform(-0.12, 0.12)
            inner = radius * random.uniform(0.16, 0.35)
            outer = radius * random.uniform(0.72, 1.12)
            p1 = (cx + math.cos(angle - 0.08) * inner, cy + math.sin(angle - 0.08) * inner)
            p2 = (cx + math.cos(angle) * outer, cy + math.sin(angle) * outer)
            p3 = (cx + math.cos(angle + 0.08) * inner, cy + math.sin(angle + 0.08) * inner)
            draw.polygon((p1, p2, p3), fill=(255, 94, 28, int(60 + pulse * 145)))
            draw.line((cx, cy, p2[0], p2[1]), fill=(255, 206, 94, int(50 + pulse * 105)), width=3)
        ring((255, 154, 44), 6, int(75 + pulse * 120), 0.76)
    elif "death" in seq_id:
        for _ in range(38):
            angle = random.random() * math.tau
            dist = random.uniform(12, radius * 1.2)
            x = cx + math.cos(angle) * dist
            y = cy + math.sin(angle) * dist
            rr = random.uniform(2, 7)
            draw.ellipse((x - rr, y - rr, x + rr, y + rr), fill=(*accent, int((1.0 - progress) * 130)))
    elif "target" in seq_id or "threat" in seq_id:
        ring(accent, 5, int(100 + pulse * 130), 0.8)
        for i in range(4):
            angle = i * math.pi * 0.5 + progress * math.pi
            p1 = (cx + math.cos(angle) * (radius * 0.34), cy + math.sin(angle) * (radius * 0.34))
            p2 = (cx + math.cos(angle) * (radius * 0.95), cy + math.sin(angle) * (radius * 0.95))
            draw.line((p1, p2), fill=(*accent, int(120 + pulse * 100)), width=5)
    else:
        ring(accent, 8, int(80 + pulse * 110), 0.8)
        ring((255, 245, 180), 3, int(70 + pulse * 130), 0.42)
        for _ in range(20):
            angle = random.random() * math.tau
            dist = random.uniform(radius * 0.15, radius)
            x = cx + math.cos(angle) * dist
            y = cy + math.sin(angle) * dist
            rr = random.uniform(2, 5)
            draw.ellipse((x - rr, y - rr, x + rr, y + rr), fill=(*accent, int(65 + pulse * 112)))
    glow = img.filter(ImageFilter.GaussianBlur(8))
    return Image.alpha_composite(glow, img)


def generate_vfx_sequences() -> list[str]:
    written: list[str] = []
    seq_root = PROD / "sprites" / "vfx_sequences"
    single_root = PROD / "sprites" / "vfx"
    for folder in sorted(p for p in seq_root.iterdir() if p.is_dir()):
        frames = sorted(folder.glob("*.png"))
        total = len(frames) or 8
        if not frames:
            frames = [folder / f"{folder.name}_{i:02d}.png" for i in range(1, total + 1)]
        peak: Image.Image | None = None
        for idx, path in enumerate(frames, start=1):
            img = make_vfx_frame(folder.name, idx, total)
            path.parent.mkdir(parents=True, exist_ok=True)
            img.save(path)
            if idx == max(1, round(total * 0.55)):
                peak = img
            written.append(str(path.relative_to(ROOT)))
        if peak is not None:
            single = single_root / f"{folder.name}.png"
            peak.save(single)
            written.append(str(single.relative_to(ROOT)))
    return written


def generate_skill_icons() -> list[str]:
    written: list[str] = []
    skills = json.loads((ROOT / "data" / "skills.json").read_text(encoding="utf-8"))
    for skill_id, row in skills.items():
        prod_icon = PROD / "sprites" / "ui" / f"{skill_id}_icon.png"
        icon_path = row.get("icon", "")
        source_path = ROOT / icon_path.replace("res://", "") if icon_path.startswith("res://") else prod_icon
        if not source_path.exists():
            source_path = prod_icon
        if not source_path.exists():
            continue
        source = load_rgba(source_path)
        source.thumbnail((204, 204), Image.Resampling.LANCZOS)
        icon = make_card_icon(source, skill_id, 256)
        icon.save(prod_icon)
        legacy_path = ROOT / "assets" / "sprites" / "ui" / f"{skill_id}_icon.png"
        if legacy_path.exists():
            icon.save(legacy_path)
            written.append(str(legacy_path.relative_to(ROOT)))
        written.append(str(prod_icon.relative_to(ROOT)))
    return written


def rel_res(path: Path) -> str:
    return "res://" + str(path.relative_to(ROOT))


def update_data_refs() -> list[str]:
    changed: list[str] = []
    zombies_path = ROOT / "data" / "zombies.json"
    bosses_path = ROOT / "data" / "bosses.json"
    skills_path = ROOT / "data" / "skills.json"
    zombies = json.loads(zombies_path.read_text(encoding="utf-8"))
    for zombie_id, row in zombies.items():
        desired = rel_res(PROD / "sprites" / "zombies" / f"{zombie_id}_prototype.png")
        if row.get("sprite") != desired:
            row["sprite"] = desired
            changed.append(f"data/zombies.json:{zombie_id}.sprite")
    zombies_path.write_text(json.dumps(zombies, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")

    bosses = json.loads(bosses_path.read_text(encoding="utf-8"))
    for boss_id, row in bosses.items():
        desired = rel_res(PROD / "sprites" / "bosses" / f"{boss_id}_prototype.png")
        if row.get("sprite") != desired:
            row["sprite"] = desired
            changed.append(f"data/bosses.json:{boss_id}.sprite")
    bosses_path.write_text(json.dumps(bosses, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")

    skills = json.loads(skills_path.read_text(encoding="utf-8"))
    for skill_id, row in skills.items():
        desired = rel_res(PROD / "sprites" / "ui" / f"{skill_id}_icon.png")
        if (PROD / "sprites" / "ui" / f"{skill_id}_icon.png").exists() and row.get("icon") != desired:
            row["icon"] = desired
            changed.append(f"data/skills.json:{skill_id}.icon")
    skills_path.write_text(json.dumps(skills, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")
    return changed


def save_contact_sheet(paths: list[str]) -> str:
    selected: list[Path] = []
    for pattern in [
        "assets/production/sprites/characters/*_prototype.png",
        "assets/production/sprites/weapons/*_icon.png",
        "assets/production/sprites/zombies/*_prototype.png",
        "assets/production/sprites/bosses/*_prototype.png",
        "assets/production/sprites/pets/*_prototype.png",
        "assets/production/sprites/projectiles/*.png",
        "assets/production/sprites/ui/skill_*_icon.png",
    ]:
        selected.extend(sorted(ROOT.glob(pattern)))
    selected = selected[:96]
    cell_w, cell_h = 180, 210
    cols = 8
    rows = math.ceil(len(selected) / cols)
    sheet = Image.new("RGBA", (cols * cell_w, rows * cell_h), (8, 11, 15, 255))
    draw = ImageDraw.Draw(sheet, "RGBA")
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 14)
    except OSError:
        font = ImageFont.load_default()
    for idx, path in enumerate(selected):
        img = load_rgba(path)
        img.thumbnail((144, 144), Image.Resampling.LANCZOS)
        x = (idx % cols) * cell_w
        y = (idx // cols) * cell_h
        accent = accent_for_id(path.stem)
        draw.rounded_rectangle((x + 8, y + 8, x + cell_w - 8, y + cell_h - 8), radius=10, fill=(13, 18, 24, 255), outline=(*accent, 165), width=2)
        sheet.alpha_composite(img, (x + (cell_w - img.width) // 2, y + 18))
        label = path.stem.replace("_prototype", "").replace("_icon", "")
        if len(label) > 22:
            label = label[:21] + "..."
        draw.text((x + 12, y + 168), label, fill=(222, 230, 232, 255), font=font)
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    out = SOURCE_DIR / "high_end_prototype_contact_sheet.png"
    sheet.save(out)
    return str(out.relative_to(ROOT))


def update_asset_index(written: list[str], contact_sheet: str) -> None:
    data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
    data["counts"]["total_files"] = sum(1 for path in PROD.rglob("*") if path.is_file())
    overrides = data.setdefault("owner_directed_generated_overrides", [])
    paths_to_replace = {
        "sprites/characters",
        "sprites/zombies",
        "sprites/bosses",
        "sprites/pets",
        "sprites/ui/skill_icons",
        "sprites/vfx",
        "sprites/vfx_sequences",
        "sprites/animations/zombies",
        "sprites/animations/bosses",
        "sprites/animations/character_weapon_combos",
    }
    overrides = [item for item in overrides if item.get("path") not in paths_to_replace]
    for path in sorted(paths_to_replace):
        overrides.append(
            {
                "path": path,
                "source": "source_refs/generated/high_end_prototype_asset_spec.json",
                "derived": contact_sheet,
                "reason": "Owner requested all low-end prototype models, UI-facing prototypes, and simple VFX to be remade to a higher-end 3D mobile-game presentation without changing gameplay logic.",
            }
        )
    data["owner_directed_generated_overrides"] = overrides
    INDEX_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def save_spec(written: list[str], data_changes: list[str], contact_sheet: str) -> None:
    spec = {
        "id": "high_end_prototype_asset_rebuild",
        "generated_by": "tools/generate_high_end_prototype_assets.py",
        "scope": "visual prototypes, icons, animation-frame polish, and VFX sequence frames only; no gameplay logic, stats, waves, or economy tuning changed",
        "style_prompt": (
            "First-tier 3D mobile roguelite zombie defense presentation: ruined-city cyberpunk military sci-fi, "
            "transparent cutout sprites, realistic armor and weapon materials, strong rim light, readable silhouettes, "
            "elemental fire/ice/lightning/poison/physical VFX, premium icon cards, no flat placeholder bars, no raw vector boxes."
        ),
        "data_reference_policy": "Content IDs are preserved. Legacy res://assets/sprites references were moved to res://assets/production where production equivalents exist.",
        "contact_sheet": contact_sheet,
        "data_changes": data_changes,
        "written_count": len(written),
        "written_sample": written[:120],
    }
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    (SOURCE_DIR / "high_end_prototype_asset_spec.json").write_text(json.dumps(spec, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    written: list[str] = []
    data_changes: list[str] = []

    characters = list(CHAR_ASSET_IDS.values())
    zombies = list(json.loads((ROOT / "data" / "zombies.json").read_text(encoding="utf-8")).keys())
    bosses = list(json.loads((ROOT / "data" / "bosses.json").read_text(encoding="utf-8")).keys())

    written.extend(polish_animation_tree(PROD / "sprites" / "animations" / "characters_weaponless", characters, "characters"))
    written.extend(polish_animation_tree(PROD / "sprites" / "animations" / "character_weapon_combos", characters, "character_weapon_combos"))
    written.extend(polish_animation_tree(PROD / "sprites" / "animations" / "zombies", zombies, "zombies"))
    written.extend(polish_animation_tree(PROD / "sprites" / "animations" / "bosses", bosses, "bosses"))
    written.extend(generate_character_prototypes())
    written.extend(generate_enemy_and_boss_prototypes())
    written.extend(generate_pet_prototypes())
    written.extend(generate_vfx_sequences())
    written.extend(generate_skill_icons())
    data_changes.extend(update_data_refs())
    contact_sheet = save_contact_sheet(written)
    save_spec(written, data_changes, contact_sheet)
    update_asset_index(written, contact_sheet)

    print(f"High-end prototype rebuild wrote {len(written)} assets")
    print(f"Data refs updated: {len(data_changes)}")
    print(contact_sheet)
    print("assets/production/source_refs/generated/high_end_prototype_asset_spec.json")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
