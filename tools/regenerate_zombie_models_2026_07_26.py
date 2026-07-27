#!/usr/bin/env python3
from __future__ import annotations

import json
import math
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / "assets" / "production"
SOURCE_DIR = PROD / "source_refs" / "generated" / "zombie_model_redo_2026_07_26"
ZOMBIE_DIR = PROD / "sprites" / "zombies"
ANIM_DIR = PROD / "sprites" / "animations" / "zombies"
CONTACT_DIR = PROD / "contact_sheets"
INDEX_PATH = PROD / "OUTSOURCER_ASSET_INDEX.json"

CHANGED_ZOMBIES = (
    "zombie_bomber",
    "zombie_spitter",
    "zombie_juggernaut",
    "zombie_necromancer",
    "zombie_charger",
    "zombie_regenerator",
    "zombie_splitter",
    "zombie_warden",
)

ALL_ZOMBIES = (
    "zombie_shambler",
    "zombie_runner",
    "zombie_brute",
    "zombie_bomber",
    "zombie_screamer",
    "zombie_spitter",
    "zombie_crawler",
    "zombie_armored",
    "zombie_shielder",
    "zombie_hopper",
    "zombie_juggernaut",
    "zombie_phantom",
    "zombie_necromancer",
    "zombie_toxic",
    "zombie_charger",
    "zombie_regenerator",
    "zombie_splitter",
    "zombie_warden",
    "zombie_mutant",
    "zombie_berserker",
)

ACCENTS = {
    "zombie_bomber": (255, 92, 35),
    "zombie_spitter": (173, 244, 64),
    "zombie_juggernaut": (255, 146, 48),
    "zombie_necromancer": (133, 235, 86),
    "zombie_charger": (255, 148, 45),
    "zombie_regenerator": (190, 232, 78),
    "zombie_splitter": (178, 238, 66),
    "zombie_warden": (101, 221, 255),
}

RUNTIME_MAX = {
    "zombie_bomber": (380, 430),
    "zombie_spitter": (442, 404),
    "zombie_juggernaut": (454, 388),
    "zombie_necromancer": (344, 452),
    "zombie_charger": (444, 400),
    "zombie_regenerator": (354, 438),
    "zombie_splitter": (456, 326),
    "zombie_warden": (448, 440),
}

PROMPTS = {
    "zombie_bomber": (
        "Barrel-shaped infected demolition carrier with an exposed red-orange detonation "
        "core, cracked steel ribs and unstable canisters; no normal thin humanoid silhouette."
    ),
    "zombie_spitter": (
        "Low triangular corrosive predator with an asymmetric acid throat sac, split nozzle "
        "jaw and long supporting forelimbs; no upright human proportions."
    ),
    "zombie_juggernaut": (
        "Low broad industrial siege breaker with a recessed head, rectangular shoulder "
        "housings and piston slab forearms; no upright armored knight."
    ),
    "zombie_necromancer": (
        "Extremely gaunt corpse conductor with a crooked bone staff and tall asymmetric "
        "corpse-cage reliquary; unmistakable vertical summoner silhouette."
    ),
    "zombie_charger": (
        "Bull-like biological battering ram with a steel shoulder wedge, short bone horns "
        "and low four-point charging posture; no standing brute silhouette."
    ),
    "zombie_regenerator": (
        "Asymmetric self-healing organism with an open ribcage bioreactor, one pale newly "
        "regrown arm and compact nutrient sacs."
    ),
    "zombie_splitter": (
        "Low horizontal three-lobed fusion organism with shared segmented abdomen, six "
        "supporting limbs and bright separation seams; no separate babies."
    ),
    "zombie_warden": (
        "Mobile shield-projector support unit integrated into a tall rectangular generator "
        "frame with lateral emitter crossbar and compact cyan lens; no police baton or shield."
    ),
}

COMMON_PROMPT = (
    "Top-tier stylized semi-realistic 3D-rendered 2D mobile-game sprite; clean large shapes, "
    "premium readable materials, upper-right key light, soft global illumination, restrained "
    "rim light, three-quarter slightly top-down gameplay view, full body with generous padding, "
    "flat #ff00ff chroma-key background, no shadow/floor/text/watermark/cropping."
)

ACTION_COUNTS = {
    "idle": 4,
    "walk": 6,
    "attack": 4,
    "special": 6,
    "hurt": 3,
    "death": 6,
}

ACTION_FPS = {
    "idle": 8,
    "walk": 8,
    "attack": 12,
    "special": 12,
    "hurt": 12,
    "death": 12,
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


def enhanced_master(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    rgb = ImageEnhance.Contrast(image.convert("RGB")).enhance(1.045)
    rgb = ImageEnhance.Color(rgb).enhance(1.035)
    rgb = ImageEnhance.Sharpness(rgb).enhance(1.08)
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    return out


def glow_layer(image: Image.Image, color: tuple[int, int, int], strength: int) -> Image.Image:
    alpha = image.getchannel("A").filter(ImageFilter.GaussianBlur(7))
    glow = Image.new("RGBA", image.size, (*color, 0))
    glow.putalpha(alpha.point(lambda value: min(255, int(value * strength / 255))))
    return glow


def floor_shadow(size: tuple[int, int], width: int, bottom: int) -> Image.Image:
    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow, "RGBA")
    cx = size[0] // 2
    draw.ellipse(
        (cx - width // 2, bottom - 16, cx + width // 2, bottom + 18),
        fill=(0, 0, 0, 76),
    )
    return shadow.filter(ImageFilter.GaussianBlur(11))


def transform_subject(
    base: Image.Image,
    scale_x: float,
    scale_y: float,
    shift_x: int,
    shift_y: int,
    angle: float,
    anchor_bottom: int = 486,
) -> Image.Image:
    subject = alpha_crop(base, 10)
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


def mechanic_pulse(
    size: tuple[int, int],
    zombie_id: str,
    progress: float,
) -> Image.Image:
    accent = ACCENTS[zombie_id]
    pulse = math.sin(progress * math.pi)
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer, "RGBA")
    center_y = 255
    if zombie_id == "zombie_splitter":
        center_y = 320
    elif zombie_id == "zombie_necromancer":
        center_y = 235
    elif zombie_id == "zombie_warden":
        center_y = 250
    radius = int(52 + pulse * 62)
    draw.ellipse(
        (
            size[0] // 2 - radius,
            center_y - radius,
            size[0] // 2 + radius,
            center_y + radius,
        ),
        outline=(*accent, int(45 + pulse * 82)),
        width=max(2, int(3 + pulse * 3)),
    )
    if zombie_id in {"zombie_warden", "zombie_necromancer"}:
        for index in range(4):
            angle = index * math.pi * 0.5 + progress * 0.3
            draw.line(
                (
                    size[0] // 2 + math.cos(angle) * radius * 0.65,
                    center_y + math.sin(angle) * radius * 0.65,
                    size[0] // 2 + math.cos(angle) * radius * 1.18,
                    center_y + math.sin(angle) * radius * 1.18,
                ),
                fill=(*accent, int(50 + pulse * 90)),
                width=3,
            )
    return layer.filter(ImageFilter.GaussianBlur(2.0))


def animation_pose(
    base: Image.Image,
    zombie_id: str,
    action: str,
    frame_index: int,
    total: int,
) -> Image.Image:
    accent = ACCENTS[zombie_id]
    t = frame_index / max(1, total - 1)
    scale_x = 1.0
    scale_y = 1.0
    shift_x = 0
    shift_y = 0
    angle = 0.0
    tint = 0.0
    opacity = 1.0

    if action == "idle":
        phase = math.sin(t * math.tau)
        scale_x = 1.0 - phase * 0.006
        scale_y = 1.0 + phase * 0.010
        shift_y = round(-phase * 3)
    elif action == "walk":
        phase = math.sin(t * math.tau)
        shift_x = round(phase * (5 if zombie_id == "zombie_necromancer" else 7))
        shift_y = round(-abs(phase) * 7)
        angle = phase * (0.7 if zombie_id in {"zombie_juggernaut", "zombie_splitter"} else 1.1)
        scale_y = 1.0 - abs(phase) * 0.012
    elif action == "attack":
        pulse = (0.0, 0.62, 1.0, 0.28)[frame_index]
        scale_x = 1.0 + pulse * 0.040
        scale_y = 1.0 + pulse * 0.055
        shift_y = round(pulse * (18 if zombie_id == "zombie_charger" else 12))
        angle = (0.0, -1.2, 1.0, 0.15)[frame_index]
    elif action == "special":
        pulse = math.sin(t * math.pi)
        scale_x = 1.0 + pulse * 0.014
        scale_y = 1.0 + pulse * 0.017
        shift_y = round(-pulse * 2)
        angle = math.sin(t * math.tau) * 0.35
        tint = pulse * 0.075
    elif action == "hurt":
        recoil = (0.78, 1.0, 0.38)[frame_index]
        shift_x = round(-7 * recoil)
        shift_y = round(-6 * recoil)
        angle = -1.5 * recoil
        scale_y = 1.0 - recoil * 0.02
        tint = 0.17 * recoil
    elif action == "death":
        ease = t * t
        angle = -21.0 * ease
        shift_x = round(-15 * ease)
        shift_y = round(24 * ease)
        scale_x = 1.0 - 0.12 * ease
        scale_y = 1.0 - 0.17 * ease
        opacity = max(0.1, 1.0 - 0.88 * ease)

    moved = transform_subject(base, scale_x, scale_y, shift_x, shift_y, angle)
    if action == "hurt":
        moved = tint_visible(moved, (255, 62, 38), tint)
    elif action == "special":
        moved = tint_visible(moved, accent, tint)
    if opacity < 1.0:
        moved.putalpha(moved.getchannel("A").point(lambda value: int(value * opacity)))

    frame = Image.new("RGBA", base.size, (0, 0, 0, 0))
    if action == "special":
        frame.alpha_composite(mechanic_pulse(base.size, zombie_id, t))
    frame.alpha_composite(glow_layer(moved, accent, 24 if action != "special" else 38))
    frame.alpha_composite(moved)
    return frame


def make_runtime_base(master: Image.Image, zombie_id: str) -> Image.Image:
    return fitted_subject(master, (512, 512), RUNTIME_MAX[zombie_id], 486)


def make_prototype(master: Image.Image, accent: tuple[int, int, int]) -> Image.Image:
    base = fitted_subject(master, (1024, 1536), (920, 1320), 1458)
    out = Image.new("RGBA", base.size, (0, 0, 0, 0))
    bbox = base.getchannel("A").getbbox()
    width = 600 if bbox is None else max(380, min(780, bbox[2] - bbox[0]))
    out.alpha_composite(floor_shadow(base.size, width, 1450))
    out.alpha_composite(glow_layer(base, accent, 30))
    out.alpha_composite(base)
    return out


def make_portrait(master: Image.Image, accent: tuple[int, int, int]) -> Image.Image:
    size = (720, 1080)
    card = Image.new("RGBA", size, (8, 13, 19, 255))
    draw = ImageDraw.Draw(card, "RGBA")
    for y in range(size[1]):
        t = y / max(1, size[1] - 1)
        draw.line(
            (0, y, size[0], y),
            fill=(
                int(10 + accent[0] * 0.02 + t * 3),
                int(15 + accent[1] * 0.018 + t * 4),
                int(22 + accent[2] * 0.016 + t * 5),
                255,
            ),
        )
    draw.rounded_rectangle(
        (26, 26, size[0] - 26, size[1] - 26),
        radius=28,
        fill=(7, 12, 18, 238),
        outline=(*accent, 178),
        width=4,
    )
    draw.rounded_rectangle(
        (44, 44, size[0] - 44, size[1] - 44),
        radius=20,
        outline=(216, 229, 236, 72),
        width=2,
    )
    subject = fitted_subject(master, size, (634, 918), 1014)
    card.alpha_composite(glow_layer(subject, accent, 44))
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
                int(13 + accent[1] * 0.030 * (1.0 - t)),
                int(19 + accent[2] * 0.025 * (1.0 - t)),
                255,
            ),
        )
    draw.rounded_rectangle((7, 7, 249, 249), radius=19, outline=(*accent, 220), width=3)
    draw.rounded_rectangle((17, 17, 239, 239), radius=13, outline=(225, 235, 240, 74), width=2)
    subject = fitted_subject(master, size, (224, 218), 239)
    icon.alpha_composite(glow_layer(subject, accent, 42))
    icon.alpha_composite(subject)
    return icon


def save_animation_set(zombie_id: str, master: Image.Image) -> list[str]:
    written: list[str] = []
    folder = ANIM_DIR / zombie_id
    folder.mkdir(parents=True, exist_ok=True)
    base = make_runtime_base(master, zombie_id)
    actions: dict[str, dict[str, object]] = {}
    for action, count in ACTION_COUNTS.items():
        frame_paths: list[str] = []
        for index in range(count):
            path = folder / f"{zombie_id}_{action}_{index + 1:02d}.png"
            animation_pose(base, zombie_id, action, index, count).save(path)
            written.append(str(path.relative_to(ROOT)))
            frame_paths.append(str(path.relative_to(PROD)))
        actions[action] = {"fps": ACTION_FPS[action], "frames": frame_paths}
    manifest_path = folder / f"{zombie_id}_animation.json"
    manifest_path.write_text(
        json.dumps(
            {"id": zombie_id, "kind": "zombies", "actions": actions},
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    written.append(str(manifest_path.relative_to(ROOT)))
    return written


def font(size: int) -> ImageFont.ImageFont:
    for path in (
        PROD / "fonts" / "font_main.ttf",
        Path("/System/Library/Fonts/STHeiti Medium.ttc"),
    ):
        try:
            return ImageFont.truetype(str(path), size)
        except OSError:
            pass
    return ImageFont.load_default()


def make_roster_contact_sheet() -> str:
    cols = 5
    cell_w, cell_h = 320, 270
    sheet = Image.new("RGBA", (cols * cell_w, 60 + 4 * cell_h), (8, 13, 19, 255))
    draw = ImageDraw.Draw(sheet, "RGBA")
    draw.text(
        (18, 14),
        "Zombie silhouette roster · runtime-scale source frames · 2026-07-26",
        font=font(24),
        fill=(235, 241, 244, 255),
    )
    for index, zombie_id in enumerate(ALL_ZOMBIES):
        x = index % cols * cell_w
        y = 60 + index // cols * cell_h
        changed = zombie_id in CHANGED_ZOMBIES
        accent = ACCENTS.get(zombie_id, (70, 191, 208))
        draw.rounded_rectangle(
            (x + 7, y + 7, x + cell_w - 7, y + cell_h - 7),
            radius=13,
            fill=(24, 34, 44, 255),
            outline=(*accent, 230 if changed else 100),
            width=3 if changed else 2,
        )
        path = ANIM_DIR / zombie_id / f"{zombie_id}_walk_01.png"
        image = load_rgba(path).resize((164, 164), Image.Resampling.LANCZOS)
        sheet.alpha_composite(image, (x + (cell_w - 164) // 2, y + 20))
        label = zombie_id.replace("zombie_", "")
        draw.text((x + 16, y + 195), label, font=font(22), fill=(232, 239, 243, 255))
        draw.text(
            (x + 16, y + 230),
            "REDESIGNED" if changed else "PRESERVED",
            font=font(14),
            fill=(*accent, 255),
        )
    CONTACT_DIR.mkdir(parents=True, exist_ok=True)
    output = CONTACT_DIR / "contact_zombie_model_redo_2026_07_26.png"
    sheet.save(output)
    return str(output.relative_to(ROOT))


def make_before_after_sheet() -> str:
    cols = 4
    cell_w, cell_h = 400, 520
    sheet = Image.new("RGBA", (cols * cell_w, 60 + 2 * cell_h), (8, 13, 19, 255))
    draw = ImageDraw.Draw(sheet, "RGBA")
    draw.text(
        (18, 14),
        "Zombie model redesign · before / after",
        font=font(25),
        fill=(235, 241, 244, 255),
    )
    for index, zombie_id in enumerate(CHANGED_ZOMBIES):
        x = index % cols * cell_w
        y = 60 + index // cols * cell_h
        accent = ACCENTS[zombie_id]
        draw.rounded_rectangle(
            (x + 7, y + 7, x + cell_w - 7, y + cell_h - 7),
            radius=14,
            fill=(20, 29, 38, 255),
            outline=(*accent, 205),
            width=2,
        )
        for column, state in enumerate(("before", "after")):
            path = (
                SOURCE_DIR / "before" / f"{zombie_id}_prototype.png"
                if state == "before"
                else ZOMBIE_DIR / f"{zombie_id}_prototype.png"
            )
            image = alpha_crop(load_rgba(path), 4)
            image.thumbnail((176, 370), Image.Resampling.LANCZOS)
            px = x + 10 + column * 190 + (180 - image.width) // 2
            py = y + 40 + (370 - image.height) // 2
            sheet.alpha_composite(image, (px, py))
            draw.text(
                (x + 20 + column * 190, y + 420),
                state.upper(),
                font=font(15),
                fill=(*accent, 255) if state == "after" else (157, 170, 179, 255),
            )
        draw.text((x + 18, y + 460), zombie_id, font=font(17), fill=(229, 237, 241, 255))
    output = SOURCE_DIR / "zombie_model_before_after_contact_sheet.png"
    sheet.save(output)
    return str(output.relative_to(ROOT))


def make_animation_contact_sheet() -> str:
    actions = ("idle", "walk", "attack", "special", "hurt", "death")
    peak_frames = {
        "idle": 2,
        "walk": 4,
        "attack": 3,
        "special": 4,
        "hurt": 2,
        "death": 5,
    }
    label_w = 190
    cell_w, cell_h = 248, 250
    header_h = 76
    sheet = Image.new(
        "RGBA",
        (label_w + len(actions) * cell_w, header_h + len(CHANGED_ZOMBIES) * cell_h),
        (8, 13, 19, 255),
    )
    draw = ImageDraw.Draw(sheet, "RGBA")
    draw.text(
        (18, 14),
        "Zombie animation peak-frame review · imported 512×512 RGBA",
        font=font(25),
        fill=(235, 241, 244, 255),
    )
    for column, action in enumerate(actions):
        draw.text(
            (label_w + column * cell_w + 16, 49),
            action.upper(),
            font=font(15),
            fill=(159, 218, 229, 255),
        )
    for row, zombie_id in enumerate(CHANGED_ZOMBIES):
        y = header_h + row * cell_h
        accent = ACCENTS[zombie_id]
        draw.rounded_rectangle(
            (8, y + 8, sheet.width - 8, y + cell_h - 8),
            radius=14,
            fill=(19, 29, 38, 255),
            outline=(*accent, 104),
            width=2,
        )
        draw.text(
            (18, y + 82),
            zombie_id.replace("zombie_", ""),
            font=font(20),
            fill=(234, 240, 243, 255),
        )
        draw.text(
            (18, y + 117),
            "REDESIGNED",
            font=font(13),
            fill=(*accent, 255),
        )
        for column, action in enumerate(actions):
            frame = peak_frames[action]
            path = (
                ANIM_DIR
                / zombie_id
                / f"{zombie_id}_{action}_{frame:02d}.png"
            )
            image = load_rgba(path)
            image.thumbnail((214, 214), Image.Resampling.LANCZOS)
            x = label_w + column * cell_w + (cell_w - image.width) // 2
            py = y + 18 + (214 - image.height) // 2
            sheet.alpha_composite(image, (x, py))
    output = SOURCE_DIR / "zombie_model_animation_contact_sheet.png"
    sheet.save(output)
    return str(output.relative_to(ROOT))


def validate_master_alpha(zombie_id: str, image: Image.Image) -> None:
    alpha = image.getchannel("A")
    if alpha.getbbox() is None:
        raise ValueError(f"{zombie_id}: transparent master has no subject")
    corners = (
        alpha.getpixel((0, 0)),
        alpha.getpixel((image.width - 1, 0)),
        alpha.getpixel((0, image.height - 1)),
        alpha.getpixel((image.width - 1, image.height - 1)),
    )
    if any(value != 0 for value in corners):
        raise ValueError(f"{zombie_id}: chroma removal left non-transparent corners")


def write_manifest(
    written: list[str],
    contact_sheet: str,
    before_after: str,
    animation_contact: str,
) -> str:
    manifest = {
        "id": "zombie_model_silhouette_redo_2026_07_26",
        "created_at": datetime.now(timezone.utc).astimezone().isoformat(),
        "generated_with": "built-in image_gen; flat magenta chroma-key source; local alpha extraction",
        "scope": (
            "Eight visually overlapping or mechanic-ambiguous ordinary zombies were redesigned. "
            "All zombie IDs, data paths, mechanics, stats, weaknesses, collisions and level usage remain unchanged."
        ),
        "changed_zombies": list(CHANGED_ZOMBIES),
        "preserved_zombies": [
            zombie_id for zombie_id in ALL_ZOMBIES if zombie_id not in CHANGED_ZOMBIES
        ],
        "prompts": {
            zombie_id: f"{PROMPTS[zombie_id]} {COMMON_PROMPT}"
            for zombie_id in CHANGED_ZOMBIES
        },
        "outputs": {
            "prototype": "1024x1536 RGBA",
            "portrait": "720x1080 RGBA",
            "icon": "256x256 RGBA",
            "animation_frames": "512x512 RGBA; idle/walk/attack/special/hurt/death",
        },
        "contact_sheet": contact_sheet,
        "before_after_sheet": before_after,
        "animation_contact_sheet": animation_contact,
        "written_count": len(written),
        "written": written,
    }
    path = SOURCE_DIR / "zombie_model_redo_manifest.json"
    path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return str(path.relative_to(ROOT))


def update_asset_index(manifest: str, contact_sheet: str, count: int) -> None:
    data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
    overrides = data.setdefault("owner_directed_generated_overrides", [])
    overrides = [
        item
        for item in overrides
        if item.get("task") != "ordinary zombie silhouette differentiation pass"
    ]
    overrides.append(
        {
            "path": (
                "sprites/zombies/{bomber,spitter,juggernaut,necromancer,charger,"
                "regenerator,splitter,warden} + matching animations/zombies"
            ),
            "source": manifest,
            "derived": contact_sheet,
            "reason": (
                "Owner approved the full ordinary-zombie silhouette audit and requested a top-tier "
                "render pass. Eight high-priority enemies were rebuilt around their actual mechanics "
                "while preserving every gameplay ID, path and balance value."
            ),
            "count": count,
            "task": "ordinary zombie silhouette differentiation pass",
            "created_at": datetime.now(timezone.utc).astimezone().isoformat(),
        }
    )
    data["owner_directed_generated_overrides"] = overrides
    if "counts" in data:
        data["counts"]["total_files"] = sum(1 for path in PROD.rglob("*") if path.is_file())
    INDEX_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    missing = [
        str(SOURCE_DIR / f"{zombie_id}_master.png")
        for zombie_id in CHANGED_ZOMBIES
        if not (SOURCE_DIR / f"{zombie_id}_master.png").exists()
    ]
    if missing:
        raise FileNotFoundError("missing generated masters: " + ", ".join(missing))

    written: list[str] = []
    for zombie_id in CHANGED_ZOMBIES:
        accent = ACCENTS[zombie_id]
        master = enhanced_master(load_rgba(SOURCE_DIR / f"{zombie_id}_master.png"))
        validate_master_alpha(zombie_id, master)

        prototype_path = ZOMBIE_DIR / f"{zombie_id}_prototype.png"
        portrait_path = ZOMBIE_DIR / f"{zombie_id}_portrait.png"
        icon_path = ZOMBIE_DIR / f"{zombie_id}_icon.png"
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
        written.extend(save_animation_set(zombie_id, master))

    contact_sheet = make_roster_contact_sheet()
    before_after = make_before_after_sheet()
    animation_contact = make_animation_contact_sheet()
    written.extend([contact_sheet, before_after, animation_contact])
    manifest = write_manifest(written, contact_sheet, before_after, animation_contact)
    update_asset_index(manifest, contact_sheet, len(written))
    print(f"Regenerated {len(CHANGED_ZOMBIES)} ordinary zombie model families")
    print(f"Wrote {len(written)} derived assets")
    print(contact_sheet)
    print(before_after)
    print(animation_contact)
    print(manifest)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
