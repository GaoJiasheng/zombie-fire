#!/usr/bin/env python3
from __future__ import annotations

import json
import math
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / "assets" / "production"
SOURCE_DIR = PROD / "source_refs" / "generated" / "boss_model_redo_2026_07_25"
BOSS_DIR = PROD / "sprites" / "bosses"
ANIM_DIR = PROD / "sprites" / "animations" / "bosses"
VIDEO_DIR = PROD / "video"
CONTACT_DIR = PROD / "contact_sheets"
INDEX_PATH = PROD / "OUTSOURCER_ASSET_INDEX.json"

CHANGED_BOSSES = (
    "boss_tank_titan",
    "boss_inferno_maw",
    "boss_frost_warden",
    "boss_necrotitan",
    "boss_apex_overlord",
)
ALL_BOSSES = (
    "boss_tank_titan",
    "boss_inferno_maw",
    "boss_frost_warden",
    "boss_storm_caller",
    "boss_plague_mother",
    "boss_void_phantom",
    "boss_necrotitan",
    "boss_apex_overlord",
)

ACCENTS = {
    "boss_tank_titan": (255, 143, 52),
    "boss_inferno_maw": (255, 91, 26),
    "boss_frost_warden": (96, 218, 255),
    "boss_storm_caller": (255, 220, 72),
    "boss_plague_mother": (120, 238, 62),
    "boss_void_phantom": (164, 114, 255),
    "boss_necrotitan": (138, 230, 78),
    "boss_apex_overlord": (255, 167, 54),
}

PROMPTS = {
    "boss_tank_titan": (
        "Armored Colossus: a gorilla-like infected siege ram with a recessed head, "
        "asymmetric detachable slab armor, one shield-plow forearm and one piston fist; "
        "no upright knight silhouette or circular chest core."
    ),
    "boss_inferno_maw": (
        "Inferno Maw: a low-slung quadrupedal industrial furnace beast with a locomotive "
        "boiler back and a huge horizontal iron-toothed fire chamber; no humanoid torso."
    ),
    "boss_frost_warden": (
        "Frost Warden: a four-legged glacial prison walker with a suspended undead head "
        "inside an iron cage torso, execution bell and hooked restraint arm; no ice knight."
    ),
    "boss_necrotitan": (
        "Necrotitan: an asymmetric walking ossuary made from fused corpses, ribcage, "
        "graveyard obelisk arm, corpse-stitching claws and a vulnerable suspended heart."
    ),
    "boss_apex_overlord": (
        "Apex Overlord: a tripod six-armed command organism with a five-pylon crown and "
        "four compact elemental phase chambers; no enlarged armored humanoid silhouette."
    ),
}

ACTION_COUNTS = {
    "idle": 4,
    "walk": 6,
    "attack": 4,
    "special": 6,
    "hurt": 3,
    "death": 6,
}


def load_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def alpha_crop(image: Image.Image, padding: int = 0) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("image has no visible pixels")
    left, top, right, bottom = bbox
    return image.crop(
        (
            max(0, left - padding),
            max(0, top - padding),
            min(image.width, right + padding),
            min(image.height, bottom + padding),
        )
    )


def enhance_master(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    rgb = ImageEnhance.Contrast(image.convert("RGB")).enhance(1.05)
    rgb = ImageEnhance.Color(rgb).enhance(1.04)
    rgb = ImageEnhance.Sharpness(rgb).enhance(1.08)
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    return out


def fitted_subject(
    subject: Image.Image,
    canvas_size: tuple[int, int],
    max_size: tuple[int, int],
    bottom: int,
    x_shift: int = 0,
) -> Image.Image:
    subject = alpha_crop(subject, 8)
    scale = min(max_size[0] / subject.width, max_size[1] / subject.height)
    size = (max(1, round(subject.width * scale)), max(1, round(subject.height * scale)))
    subject = subject.resize(size, Image.Resampling.LANCZOS)
    out = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    x = (canvas_size[0] - subject.width) // 2 + x_shift
    y = bottom - subject.height
    out.alpha_composite(subject, (x, y))
    return out


def glow_layer(image: Image.Image, color: tuple[int, int, int], strength: int = 42) -> Image.Image:
    alpha = image.getchannel("A").filter(ImageFilter.GaussianBlur(8))
    glow = Image.new("RGBA", image.size, (*color, 0))
    glow.putalpha(alpha.point(lambda value: min(255, int(value * strength / 255))))
    return glow


def floor_shadow(size: tuple[int, int], width: int, bottom: int) -> Image.Image:
    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow, "RGBA")
    cx = size[0] // 2
    draw.ellipse(
        (cx - width // 2, bottom - 20, cx + width // 2, bottom + 20),
        fill=(0, 0, 0, 80),
    )
    return shadow.filter(ImageFilter.GaussianBlur(12))


def transform_subject(
    base: Image.Image,
    scale_x: float,
    scale_y: float,
    shift_x: int,
    shift_y: int,
    angle: float,
    anchor_bottom: int = 728,
) -> Image.Image:
    subject = alpha_crop(base, 14)
    size = (
        max(1, round(subject.width * scale_x)),
        max(1, round(subject.height * scale_y)),
    )
    subject = subject.resize(size, Image.Resampling.BICUBIC)
    if abs(angle) > 0.01:
        subject = subject.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
    out = Image.new("RGBA", base.size, (0, 0, 0, 0))
    x = (base.width - subject.width) // 2 + shift_x
    y = anchor_bottom - subject.height + shift_y
    out.alpha_composite(subject, (x, y))
    return out


def tint_visible(image: Image.Image, color: tuple[int, int, int], amount: float) -> Image.Image:
    if amount <= 0.0:
        return image
    alpha = image.getchannel("A")
    overlay = Image.new("RGBA", image.size, (*color, 0))
    overlay.putalpha(alpha.point(lambda value: int(value * amount)))
    return Image.alpha_composite(image, overlay)


def special_aura(
    size: tuple[int, int],
    accent: tuple[int, int, int],
    progress: float,
) -> Image.Image:
    pulse = math.sin(progress * math.pi)
    aura = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(aura, "RGBA")
    cx, cy = size[0] // 2, 410
    radius = int(118 + 86 * pulse)
    draw.ellipse(
        (cx - radius, cy - radius, cx + radius, cy + radius),
        outline=(*accent, int(70 + 70 * pulse)),
        width=max(3, int(7 * pulse)),
    )
    for index in range(8):
        angle = index * math.tau / 8 + progress * 0.45
        inner = radius * 0.62
        outer = radius * (1.0 + 0.15 * pulse)
        draw.line(
            (
                cx + math.cos(angle) * inner,
                cy + math.sin(angle) * inner,
                cx + math.cos(angle) * outer,
                cy + math.sin(angle) * outer,
            ),
            fill=(*accent, int(58 + 86 * pulse)),
            width=4,
        )
    return aura.filter(ImageFilter.GaussianBlur(2.5))


def animation_pose(
    base: Image.Image,
    boss_id: str,
    action: str,
    frame_index: int,
    total: int,
) -> Image.Image:
    accent = ACCENTS[boss_id]
    t = frame_index / max(1, total - 1)
    scale_x = 1.0
    scale_y = 1.0
    shift_x = 0
    shift_y = 0
    angle = 0.0
    opacity = 1.0
    tint = 0.0

    if action == "idle":
        phase = math.sin(t * math.tau)
        scale_x = 1.0 - phase * 0.006
        scale_y = 1.0 + phase * 0.009
        shift_y = round(-phase * 3)
    elif action == "walk":
        phase = math.sin(t * math.tau)
        shift_x = round(phase * 7)
        shift_y = round(-abs(phase) * 8)
        angle = phase * 1.15
        scale_y = 1.0 - abs(phase) * 0.012
    elif action == "attack":
        pulse = (0.0, 0.58, 1.0, 0.32)[frame_index]
        scale_x = 1.0 + pulse * 0.045
        scale_y = 1.0 + pulse * 0.055
        shift_y = round(pulse * 14)
        angle = (0.0, -1.4, 1.2, 0.2)[frame_index]
    elif action == "special":
        pulse = math.sin(t * math.pi)
        scale_x = 1.0 + pulse * 0.035
        scale_y = 1.0 + pulse * 0.045
        shift_y = round(-pulse * 10)
        angle = math.sin(t * math.tau) * 1.0
        tint = pulse * 0.10
    elif action == "hurt":
        recoil = (0.78, 1.0, 0.42)[frame_index]
        shift_x = round(-20 * recoil)
        shift_y = round(-12 * recoil)
        angle = -2.8 * recoil
        scale_y = 1.0 - recoil * 0.025
        tint = 0.18 * recoil
    elif action == "death":
        ease = t * t
        angle = -42.0 * ease
        shift_x = round(-46 * ease)
        shift_y = round(48 * ease)
        scale_x = 1.0 - 0.13 * ease
        scale_y = 1.0 - 0.18 * ease
        opacity = max(0.1, 1.0 - 0.88 * ease)

    moved = transform_subject(base, scale_x, scale_y, shift_x, shift_y, angle)
    if action == "hurt":
        moved = tint_visible(moved, (255, 66, 42), tint)
    elif action == "special":
        moved = tint_visible(moved, accent, tint)

    if opacity < 1.0:
        alpha = moved.getchannel("A").point(lambda value: int(value * opacity))
        moved.putalpha(alpha)

    frame = Image.new("RGBA", base.size, (0, 0, 0, 0))
    if action == "special":
        frame.alpha_composite(special_aura(base.size, accent, t))
    frame.alpha_composite(glow_layer(moved, accent, 34 if action != "special" else 54))
    frame.alpha_composite(moved)
    return frame


def make_runtime_base(master: Image.Image) -> Image.Image:
    return fitted_subject(master, (768, 768), (650, 660), 728)


def make_prototype(master: Image.Image, accent: tuple[int, int, int]) -> Image.Image:
    base = fitted_subject(master, (1024, 1536), (950, 1370), 1470)
    out = Image.new("RGBA", base.size, (0, 0, 0, 0))
    bbox = base.getchannel("A").getbbox()
    width = 620 if bbox is None else max(440, min(760, bbox[2] - bbox[0]))
    out.alpha_composite(floor_shadow(base.size, width, 1460))
    out.alpha_composite(glow_layer(base, accent, 38))
    out.alpha_composite(base)
    return out


def make_portrait(master: Image.Image, accent: tuple[int, int, int]) -> Image.Image:
    size = (720, 1080)
    card = Image.new("RGBA", size, (0, 0, 0, 255))
    draw = ImageDraw.Draw(card, "RGBA")
    for y in range(size[1]):
        t = y / max(1, size[1] - 1)
        color = (
            int(12 + accent[0] * 0.018 + t * 2),
            int(17 + accent[1] * 0.016 + t * 3),
            int(24 + accent[2] * 0.014 + t * 5),
            255,
        )
        draw.line((0, y, size[0], y), fill=color)
    draw.rounded_rectangle(
        (28, 28, size[0] - 28, size[1] - 28),
        radius=28,
        fill=(8, 13, 20, 238),
        outline=(*accent, 176),
        width=4,
    )
    draw.rounded_rectangle(
        (46, 46, size[0] - 46, size[1] - 46),
        radius=20,
        outline=(210, 226, 234, 74),
        width=2,
    )
    subject = fitted_subject(master, size, (610, 920), 1010)
    card.alpha_composite(glow_layer(subject, accent, 54))
    card.alpha_composite(subject)
    return card


def make_icon(master: Image.Image, accent: tuple[int, int, int]) -> Image.Image:
    size = (256, 256)
    icon = Image.new("RGBA", size, (7, 12, 18, 255))
    draw = ImageDraw.Draw(icon, "RGBA")
    for y in range(size[1]):
        t = y / max(1, size[1] - 1)
        draw.line(
            (0, y, size[0], y),
            fill=(
                int(8 + accent[0] * 0.035 * (1.0 - t)),
                int(13 + accent[1] * 0.03 * (1.0 - t)),
                int(19 + accent[2] * 0.025 * (1.0 - t)),
                255,
            ),
        )
    draw.rounded_rectangle((7, 7, 249, 249), radius=19, outline=(*accent, 220), width=3)
    draw.rounded_rectangle((17, 17, 239, 239), radius=13, outline=(225, 235, 240, 74), width=2)
    subject = fitted_subject(master, size, (224, 218), 239)
    icon.alpha_composite(glow_layer(subject, accent, 46))
    icon.alpha_composite(subject)
    return icon


def save_animation_set(boss_id: str, master: Image.Image) -> list[str]:
    written: list[str] = []
    folder = ANIM_DIR / boss_id
    folder.mkdir(parents=True, exist_ok=True)
    base = make_runtime_base(master)
    for action, count in ACTION_COUNTS.items():
        for index in range(count):
            path = folder / f"{boss_id}_{action}_{index + 1:02d}.png"
            animation_pose(base, boss_id, action, index, count).save(path)
            written.append(str(path.relative_to(ROOT)))
    return written


def refresh_boss_video(boss_id: str, portrait: Path) -> str | None:
    ffmpeg = shutil.which("ffmpeg") or "/opt/homebrew/bin/ffmpeg"
    if not Path(ffmpeg).exists():
        return None
    output = VIDEO_DIR / f"vid_{boss_id.replace('boss_', 'boss_intro_')}.mp4"
    command = [
        ffmpeg,
        "-y",
        "-loop",
        "1",
        "-i",
        str(portrait),
        "-t",
        "6",
        "-vf",
        (
            "scale=1242:2208:force_original_aspect_ratio=increase,"
            "crop=1080:1920,setsar=1,format=yuv420p,"
            "fade=t=in:st=0:d=0.35,fade=t=out:st=5.65:d=0.35"
        ),
        "-an",
        "-c:v",
        "libx264",
        "-preset",
        "medium",
        "-crf",
        "20",
        "-pix_fmt",
        "yuv420p",
        str(output),
    ]
    subprocess.run(command, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return str(output.relative_to(ROOT))


def font(size: int) -> ImageFont.ImageFont:
    candidates = (
        ROOT / "assets" / "production" / "fonts" / "font_main.ttf",
        Path("/System/Library/Fonts/STHeiti Medium.ttc"),
    )
    for path in candidates:
        try:
            return ImageFont.truetype(str(path), size)
        except OSError:
            pass
    return ImageFont.load_default()


def make_after_contact_sheet() -> str:
    cols = 4
    cell_w, cell_h = 330, 460
    rows = math.ceil(len(ALL_BOSSES) / cols)
    sheet = Image.new("RGBA", (cols * cell_w, 64 + rows * cell_h), (8, 12, 18, 255))
    draw = ImageDraw.Draw(sheet, "RGBA")
    draw.text((18, 16), "Boss silhouette differentiation · 2026-07-25", font=font(25), fill=(235, 241, 244, 255))
    for index, boss_id in enumerate(ALL_BOSSES):
        x = index % cols * cell_w
        y = 64 + index // cols * cell_h
        accent = ACCENTS[boss_id]
        changed = boss_id in CHANGED_BOSSES
        draw.rounded_rectangle(
            (x + 8, y + 8, x + cell_w - 8, y + cell_h - 8),
            radius=14,
            fill=(15, 21, 29, 255),
            outline=(*accent, 230 if changed else 120),
            width=3 if changed else 2,
        )
        image = load_rgba(BOSS_DIR / f"{boss_id}_prototype.png")
        image = alpha_crop(image, 4)
        image.thumbnail((286, 352), Image.Resampling.LANCZOS)
        sheet.alpha_composite(image, (x + (cell_w - image.width) // 2, y + 38 + (352 - image.height) // 2))
        draw.text((x + 16, y + 402), boss_id, font=font(18), fill=(224, 233, 238, 255))
        draw.text(
            (x + 16, y + 428),
            "REDESIGNED" if changed else "PRESERVED",
            font=font(14),
            fill=(*accent, 255),
        )
    CONTACT_DIR.mkdir(parents=True, exist_ok=True)
    output = CONTACT_DIR / "contact_boss_model_redo_2026_07_25.png"
    sheet.save(output)
    return str(output.relative_to(ROOT))


def make_before_after_sheet() -> str:
    cell_w, cell_h = 350, 480
    sheet = Image.new("RGBA", (len(CHANGED_BOSSES) * cell_w, cell_h * 2 + 62), (8, 12, 18, 255))
    draw = ImageDraw.Draw(sheet, "RGBA")
    draw.text((18, 15), "Boss model silhouette upgrade · before / after", font=font(25), fill=(235, 241, 244, 255))
    for column, boss_id in enumerate(CHANGED_BOSSES):
        for row, state in enumerate(("before", "after")):
            x = column * cell_w
            y = 62 + row * cell_h
            path = (
                SOURCE_DIR / "before" / f"{boss_id}_prototype.png"
                if state == "before"
                else BOSS_DIR / f"{boss_id}_prototype.png"
            )
            image = load_rgba(path)
            image = alpha_crop(image, 4)
            image.thumbnail((300, 372), Image.Resampling.LANCZOS)
            draw.rounded_rectangle(
                (x + 8, y + 8, x + cell_w - 8, y + cell_h - 8),
                radius=14,
                fill=(15, 21, 29, 255),
                outline=(*ACCENTS[boss_id], 190),
                width=2,
            )
            sheet.alpha_composite(image, (x + (cell_w - image.width) // 2, y + 38 + (372 - image.height) // 2))
            draw.text((x + 14, y + 416), f"{state.upper()} · {boss_id}", font=font(15), fill=(226, 234, 238, 255))
    output = SOURCE_DIR / "boss_model_before_after_contact_sheet.png"
    sheet.save(output)
    return str(output.relative_to(ROOT))


def write_manifest(written: list[str], contact_sheet: str, before_after: str) -> str:
    manifest = {
        "id": "boss_model_silhouette_redo_2026_07_25",
        "created_at": datetime.now(timezone.utc).astimezone().isoformat(),
        "generated_with": "built-in image_gen; flat chroma-key source; local alpha extraction",
        "scope": (
            "Five visually overlapping boss models were redesigned. Existing boss IDs, data paths, "
            "mechanics, stats, weaknesses, collision radius and spawn logic remain unchanged."
        ),
        "changed_bosses": list(CHANGED_BOSSES),
        "preserved_bosses": [boss_id for boss_id in ALL_BOSSES if boss_id not in CHANGED_BOSSES],
        "prompts": PROMPTS,
        "outputs": {
            "prototype": "1024x1536 RGBA",
            "portrait": "720x1080 RGBA",
            "icon": "256x256 RGBA",
            "animation_frames": "768x768 RGBA; idle/walk/attack/special/hurt/death",
            "intro_video": "1080x1920 H.264, 6 seconds",
        },
        "contact_sheet": contact_sheet,
        "before_after_sheet": before_after,
        "written_count": len(written),
        "written": written,
    }
    path = SOURCE_DIR / "boss_model_redo_manifest.json"
    path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return str(path.relative_to(ROOT))


def update_asset_index(manifest: str, contact_sheet: str, count: int) -> None:
    data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
    replacements = data.setdefault("generated_replacements", [])
    replacements = [
        item
        for item in replacements
        if item.get("task") != "boss model silhouette differentiation pass"
    ]
    replacements.append(
        {
            "path": (
                "sprites/bosses/{tank_titan,inferno_maw,frost_warden,necrotitan,apex_overlord} "
                "+ matching animations/bosses and vid_boss_intro files"
            ),
            "source": manifest,
            "derived": contact_sheet,
            "reason": (
                "Owner observed that several bosses read as the same armored humanoid with different "
                "colors. Rebuilt five overlapping silhouettes around their actual mechanics while "
                "preserving all IDs, paths and gameplay behavior."
            ),
            "count": count,
            "task": "boss model silhouette differentiation pass",
            "created_at": datetime.now(timezone.utc).astimezone().isoformat(),
        }
    )
    data["generated_replacements"] = replacements
    if "counts" in data:
        data["counts"]["total_files"] = sum(1 for path in PROD.rglob("*") if path.is_file())
    INDEX_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    missing = [
        str(SOURCE_DIR / f"{boss_id}_master.png")
        for boss_id in CHANGED_BOSSES
        if not (SOURCE_DIR / f"{boss_id}_master.png").exists()
    ]
    if missing:
        raise FileNotFoundError("missing generated masters: " + ", ".join(missing))

    written: list[str] = []
    for boss_id in CHANGED_BOSSES:
        accent = ACCENTS[boss_id]
        master = enhance_master(load_rgba(SOURCE_DIR / f"{boss_id}_master.png"))

        prototype_path = BOSS_DIR / f"{boss_id}_prototype.png"
        portrait_path = BOSS_DIR / f"{boss_id}_portrait.png"
        icon_path = BOSS_DIR / f"{boss_id}_icon.png"
        make_prototype(master, accent).save(prototype_path)
        make_portrait(master, accent).save(portrait_path)
        make_icon(master, accent).save(icon_path)
        written.extend(
            [
                str(prototype_path.relative_to(ROOT)),
                str(portrait_path.relative_to(ROOT)),
                str(icon_path.relative_to(ROOT)),
            ]
        )
        written.extend(save_animation_set(boss_id, master))
        video = refresh_boss_video(boss_id, portrait_path)
        if video is not None:
            written.append(video)

    contact_sheet = make_after_contact_sheet()
    before_after = make_before_after_sheet()
    written.extend([contact_sheet, before_after])
    manifest = write_manifest(written, contact_sheet, before_after)
    update_asset_index(manifest, contact_sheet, len(written))
    print(f"Regenerated {len(CHANGED_BOSSES)} boss model families")
    print(f"Wrote {len(written)} derived assets")
    print(contact_sheet)
    print(before_after)
    print(manifest)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
