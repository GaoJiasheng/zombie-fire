#!/usr/bin/env python3
"""Build Gilded Eclipse / Golden Law runtime art from accepted source boards.

The image-generation pass freezes the high-detail identities.  This builder is
deliberately deterministic: it keys/crops the sources, exports phone-scale
sprites, paints every button at its native dimensions, and records hashes for
release review.  It does not alter gameplay values or purchase state.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/production/source_refs/generated/premium_black_gold_golden_law_phase4_2026_08_01"
THEME = ROOT / "assets/production/sprites/themes/gilded_eclipse"
PREMIUM = ROOT / "assets/production/sprites/premium/gilded_eclipse"
MANIFEST = SOURCE / "gilded_eclipse_runtime_manifest_v1.json"
CONTACT = SOURCE / "gilded_eclipse_runtime_contact_sheet_v1.png"
BUTTON_MANIFEST = SOURCE / "gilded_eclipse_button_runtime_manifest_v2.json"
BUTTON_CONTACT = SOURCE / "gilded_eclipse_button_runtime_contact_sheet_v2.png"
BUTTON_PRIMARY_MASTER = SOURCE / "gilded_eclipse_button_primary_transparent_v2.png"
BUTTON_SECONDARY_MASTER = SOURCE / "gilded_eclipse_button_secondary_transparent_v2.png"
TRUE_GRIP_CONTACT = SOURCE / "golden_law_true_grip_contact_sheet_v1.png"
FROST_TRUE_GRIP_CHROMA = SOURCE / "char_frost_gilded_true_grip_three_direction_chroma_v3.png"

HEROES = ("char_vanguard", "char_blaze", "char_frost", "char_volt")
WEAPONS = (
    "weapon_autocannon", "weapon_flamethrower", "weapon_cryocannon",
    "weapon_teslacoil", "weapon_venomlauncher", "weapon_railgun",
    "weapon_scattergun", "weapon_plasmacannon",
)
FUNCTIONAL = {
    "weapon_autocannon": (224, 188, 104), "weapon_flamethrower": (255, 98, 36),
    "weapon_cryocannon": (92, 224, 255), "weapon_teslacoil": (144, 126, 255),
    "weapon_venomlauncher": (116, 232, 82), "weapon_railgun": (190, 246, 255),
    "weapon_scattergun": (255, 204, 92), "weapon_plasmacannon": (220, 112, 255),
}
BUTTON_SIZES = (
    (154, 44), (166, 58), (170, 84), (172, 44), (174, 72), (176, 76),
    (236, 96), (260, 112), (268, 48), (286, 72), (286, 80), (286, 112),
    (320, 74), (320, 80), (412, 88), (432, 88), (440, 80), (440, 88),
    (444, 88), (452, 88), (484, 102), (512, 160), (560, 104), (600, 120),
    (760, 88), (760, 112), (780, 148), (784, 96), (840, 88), (880, 88),
    (880, 96), (904, 88), (920, 88), (980, 58), (980, 96), (980, 100),
)


def record(path: Path, kind: str) -> dict:
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    with Image.open(path) as image:
        size = list(image.size)
    return {"path": str(path.relative_to(ROOT)), "kind": kind, "size": size, "sha256": digest}


def fit_alpha(image: Image.Image, size: tuple[int, int], fill: float = 0.92) -> Image.Image:
    image = image.convert("RGBA")
    box = image.getbbox()
    if box is None:
        raise RuntimeError("empty alpha master")
    image = image.crop(box)
    scale = min(size[0] * fill / image.width, size[1] * fill / image.height)
    image = image.resize(
        (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", size)
    canvas.alpha_composite(image, ((size[0] - image.width) // 2, (size[1] - image.height) // 2))
    return canvas


def keep_components(image: Image.Image, min_area: int = 80) -> Image.Image:
    rgba = np.asarray(image.convert("RGBA")).copy()
    mask = (rgba[:, :, 3] > 18).astype(np.uint8)
    count, labels, stats, _centroids = cv2.connectedComponentsWithStats(mask, 8)
    keep = np.zeros(mask.shape, dtype=bool)
    for label in range(1, count):
        if int(stats[label, cv2.CC_STAT_AREA]) >= min_area:
            keep |= labels == label
    rgba[~keep, 3] = 0
    return Image.fromarray(rgba)


def keep_largest(image: Image.Image) -> Image.Image:
    """Drop neighboring-cell fragments and panel rails from a keyed crop."""
    rgba = np.asarray(image.convert("RGBA")).copy()
    mask = (rgba[:, :, 3] > 18).astype(np.uint8)
    count, labels, stats, _centroids = cv2.connectedComponentsWithStats(mask, 8)
    if count <= 1:
        return image.convert("RGBA")
    largest = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
    rgba[labels != largest, 3] = 0
    return Image.fromarray(rgba)


def remove_green(image: Image.Image) -> Image.Image:
    rgb = np.asarray(image.convert("RGB"), dtype=np.float32)
    red, green, blue = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    strongest = np.maximum(red, blue)
    excess = green - strongest
    candidate = (green > 86.0) & (green > red * 1.25) & (green > blue * 1.14)
    alpha = np.where(candidate, 255.0 - np.clip((excess - 20.0) / 94.0, 0.0, 1.0) * 255.0, 255.0)
    alpha = np.where((green > 178.0) & (excess > 102.0), 0.0, alpha)
    partial = (alpha > 0.0) & (alpha < 255.0)
    green[partial] = np.minimum(green[partial], strongest[partial] * 1.02)
    # Chroma-key antialiasing can leave opaque lime spill on thin gold ribbons,
    # silver hair and weapon highlights.  Gold itself is red-dominant, so this
    # channel clamp removes only pixels whose green channel unnaturally exceeds
    # both neighboring channels and preserves the approved black-gold palette.
    spill = (alpha > 0.0) & (green > strongest * 1.05)
    green[spill] = np.minimum(green[spill], strongest[spill] * 1.02)
    rgba = np.dstack((red, green, blue, alpha)).clip(0, 255).astype(np.uint8)
    rgba[rgba[:, :, 3] == 0, :3] = 0
    return keep_components(Image.fromarray(rgba), 120)


def despill_green(image: Image.Image) -> Image.Image:
    """Remove green resampling fringe from a keyed black-gold sprite."""
    rgba = np.asarray(image.convert("RGBA"), dtype=np.float32).copy()
    red, green, blue, alpha = (rgba[:, :, index] for index in range(4))
    strongest = np.maximum(red, blue)
    spill = (alpha > 4.0) & (green > strongest * 1.045) & (green > blue * 1.12)
    warmed_red = np.minimum(255.0, np.maximum(red, green * 1.04))
    warmed_green = np.minimum(green, warmed_red * 0.82 + blue * 0.08)
    red[spill] = warmed_red[spill]
    green[spill] = warmed_green[spill]
    yellow_spill = (alpha > 4.0) & (red > 110.0) & (green > red * 0.80) & (blue < green * 0.72)
    green[yellow_spill] = np.minimum(green[yellow_spill], red[yellow_spill] * 0.79)
    rgba[alpha <= 4.0, :3] = 0.0
    return Image.fromarray(np.clip(rgba, 0, 255).astype(np.uint8))


def remove_dark(image: Image.Image, border: int = 6) -> Image.Image:
    image = image.convert("RGBA")
    rgb = np.asarray(image.convert("RGB"), dtype=np.float32)
    edge = np.concatenate((rgb[:border].reshape(-1, 3), rgb[-border:].reshape(-1, 3), rgb[:, :border].reshape(-1, 3), rgb[:, -border:].reshape(-1, 3)))
    key = np.median(edge, axis=0)
    dist = np.linalg.norm(rgb - key[None, None, :], axis=2)
    luma = rgb.max(axis=2)
    alpha = np.maximum(np.clip((dist - 5.0) / 42.0, 0.0, 1.0), np.clip((luma - 18.0) / 78.0, 0.0, 1.0)) * 255.0
    alpha[:border, :] = 0
    alpha[-border:, :] = 0
    alpha[:, :border] = 0
    alpha[:, -border:] = 0
    rgba = np.dstack((rgb, alpha)).clip(0, 255).astype(np.uint8)
    return keep_components(Image.fromarray(rgba), 110)


def grabcut_foreground(image: Image.Image) -> Image.Image:
    """Separate accepted character renders from their dark road preview floor."""
    rgb = np.asarray(image.convert("RGB"))
    height, width = rgb.shape[:2]
    mask = np.zeros((height, width), np.uint8)
    bg_model = np.zeros((1, 65), np.float64)
    fg_model = np.zeros((1, 65), np.float64)
    cv2.grabCut(rgb, mask, (8, 8, width - 16, height - 16), bg_model, fg_model, 6, cv2.GC_INIT_WITH_RECT)
    alpha = np.where((mask == cv2.GC_FGD) | (mask == cv2.GC_PR_FGD), 255, 0).astype(np.uint8)
    alpha = np.asarray(Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(1.0)))
    rgba = np.dstack((rgb, alpha))
    return keep_components(Image.fromarray(rgba), 150)


def panel(sheet: Image.Image, cols: int, rows: int, col: int, row: int, inset: int = 4) -> Image.Image:
    x0 = round(sheet.width * col / cols) + inset
    x1 = round(sheet.width * (col + 1) / cols) - inset
    y0 = round(sheet.height * row / rows) + inset
    y1 = round(sheet.height * (row + 1) / rows) - inset
    return sheet.crop((x0, y0, x1, y1))


def hero_frame(master: Image.Image, state: str, index: int) -> Image.Image:
    base = fit_alpha(master, (512, 512), 0.92)
    if state == "idle":
        dy, scale, angle = (-2, 0, 2, 0)[index], (0.995, 1.0, 1.006, 1.0)[index], (-0.3, 0.0, 0.3, 0.0)[index]
    elif state == "attack":
        dy, scale, angle = (2, -4, -7, -2)[index], (1.0, 1.012, 1.025, 1.008)[index], (-0.45, 0.7, 1.4, 0.15)[index]
    else:
        dy, scale, angle = (2, 6, 1)[index], (0.995, 0.982, 1.0)[index], (-1.35, 1.6, -0.35)[index]
    transformed = base.rotate(angle, resample=Image.Resampling.BICUBIC, expand=False)
    resized = transformed.resize((round(512 * scale), round(512 * scale)), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (512, 512))
    canvas.alpha_composite(resized, ((512 - resized.width) // 2, (512 - resized.height) // 2 + dy))
    return canvas


def build_heroes(entries: list[dict]) -> None:
    master = Image.open(SOURCE / "gilded_eclipse_hero_outfits_master_v2.png").convert("RGBA")
    cell_width = master.width / 4.0
    for index, hero in enumerate(HEROES):
        x0 = round(index * cell_width) + 8
        x1 = round((index + 1) * cell_width) - 8
        # The concept sheet's four front-view columns clip the outer shoulders,
        # arms and coat edges. Prefer the reviewed, individually outpainted V2
        # cutouts so a later deterministic rebuild cannot regress the selector
        # portraits to narrow prototype strips.
        reviewed_alpha = SOURCE / f"{hero}_gilded_alpha_v2.png"
        if reviewed_alpha.exists():
            front_panel = Image.open(reviewed_alpha).convert("RGBA")
        else:
            front_panel = keep_largest(remove_dark(master.crop((x0, 8, x1, 850)), 5))
            alpha_path = SOURCE / f"{hero}_gilded_alpha.png"
            front_panel.save(alpha_path, optimize=True)
        portrait_path = THEME / "characters" / f"{hero}_portrait_frameless.png"
        portrait_path.parent.mkdir(parents=True, exist_ok=True)
        fit_alpha(front_panel, (720, 980), 0.90).save(portrait_path, optimize=True)
        entries.append(record(portrait_path, "hero_portrait"))

        rear = keep_largest(remove_dark(master.crop((x0, 865, x1, 1460)), 5))
        cleaned_path = SOURCE / f"{hero}_gilded_battle_back.png"
        rear.save(cleaned_path, optimize=True)
        idle = rear
        out = THEME / "characters/animations" / hero
        out.mkdir(parents=True, exist_ok=True)
        for state, count in (("idle", 4), ("attack", 4), ("hurt", 3)):
            for frame_index in range(count):
                path = out / f"{hero}_{state}_{frame_index + 1:02d}.png"
                hero_frame(idle, state, frame_index).save(path, optimize=True)
                entries.append(record(path, f"hero_{state}"))


def button_master(path: Path) -> Image.Image:
    if not path.exists():
        raise FileNotFoundError(f"missing reviewed Gilded Eclipse button master: {path}")
    master = Image.open(path).convert("RGBA")
    alpha = np.asarray(master.getchannel("A"), dtype=np.uint8).copy()
    # The soft chroma matte deliberately leaves sub-visible fringe pixels.
    # Clear only that near-zero residue before calculating the production crop.
    alpha[alpha <= 12] = 0
    master.putalpha(Image.fromarray(alpha))
    bbox = master.getbbox()
    if bbox is None:
        raise RuntimeError(f"empty reviewed Gilded Eclipse button master: {path}")
    master = master.crop(bbox)
    if master.width / master.height < 2.8:
        raise RuntimeError(f"button master is not a wide bezel: {path}")
    return master


def button_asset(master: Image.Image, width: int, height: int) -> Image.Image:
    """Compose a native-size button while preserving its rendered end armor.

    Only a calm, straight section of the central text lane is resized.  The
    corner armor, bevel profile and material highlights are independently
    scaled from the reviewed render, so long and short controls do not stretch
    one bitmap or fall back to procedural polygon outlines.
    """
    canvas = Image.new("RGBA", (width, height))
    padding = max(1, round(min(width, height) * 0.025))
    target_width = width - padding * 2
    target_height = height - padding * 2

    # The cap boundary sits beyond the corner armor on both reviewed masters.
    source_cap = round(master.width * 0.255)
    center_x0 = round(master.width * 0.30)
    center_x1 = round(master.width * 0.38)
    left = master.crop((0, 0, source_cap, master.height))
    center = master.crop((center_x0, 0, center_x1, master.height))
    right = master.crop((master.width - source_cap, 0, master.width, master.height))

    # Preserve a meaningful text lane even in the shortest 1.8:1 control.
    min_center = max(12, round(target_height * 0.38))
    cap_width = min(round(target_height * 1.05), (target_width - min_center) // 2)
    cap_width = max(1, cap_width)
    center_width = target_width - cap_width * 2
    if center_width < 1:
        raise RuntimeError(f"button target is too narrow: {width}x{height}")

    left = left.resize((cap_width, target_height), Image.Resampling.LANCZOS)
    right = right.resize((cap_width, target_height), Image.Resampling.LANCZOS)
    strip = Image.new("RGBA", (target_width, target_height))
    strip.alpha_composite(left, (0, 0))
    strip.alpha_composite(right, (cap_width + center_width, 0))

    # Cross-fade over the straight rail section.  This removes visible slice
    # seams while keeping the end modules pixel-stable and undistorted.
    overlap = min(max(3, round(target_height * 0.18)), cap_width // 2)
    center = center.resize((center_width + overlap * 2, target_height), Image.Resampling.LANCZOS)
    center_alpha = np.asarray(center.getchannel("A"), dtype=np.float32)
    blend = np.ones(center.width, dtype=np.float32)
    blend[:overlap] = np.linspace(0.0, 1.0, overlap, endpoint=False)
    blend[-overlap:] = np.linspace(1.0, 0.0, overlap, endpoint=False)
    blended_alpha = np.clip(center_alpha * blend[None, :], 0, 255).astype(np.uint8)
    center.putalpha(Image.fromarray(blended_alpha))
    strip.alpha_composite(center, (cap_width - overlap, 0))
    canvas.alpha_composite(strip, (padding, padding))
    return canvas


def validate_button_asset(image: Image.Image, width: int, height: int, kind: str) -> None:
    if image.size != (width, height):
        raise RuntimeError(f"{kind} button size drift: {image.size} != {(width, height)}")
    alpha = np.asarray(image.getchannel("A"), dtype=np.uint8)
    if alpha.max() < 220:
        raise RuntimeError(f"{kind} button lost its opaque material body")
    if any(alpha[y, x] > 12 for x, y in ((0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1))):
        raise RuntimeError(f"{kind} button touches a transparent canvas corner")
    visible = np.asarray(image.convert("RGB"), dtype=np.uint8)[alpha > 96]
    if visible.size == 0 or np.std(visible.astype(np.float32)) < 18.0:
        raise RuntimeError(f"{kind} button lost rendered material variation")


def build_buttons(entries: list[dict]) -> None:
    out = THEME / "ui"
    out.mkdir(parents=True, exist_ok=True)
    masters = {
        "primary": button_master(BUTTON_PRIMARY_MASTER),
        "secondary": button_master(BUTTON_SECONDARY_MASTER),
    }
    for width, height in BUTTON_SIZES:
        for kind, master in masters.items():
            path = out / f"ui_button_{kind}_native_{width}x{height}.png"
            rendered = button_asset(master, width, height)
            validate_button_asset(rendered, width, height, kind)
            rendered.save(path, optimize=True)
            entries.append(record(path, f"button_{kind}"))


def build_button_contact() -> None:
    samples = ((170, 84), (286, 112), (440, 88), (760, 112), (980, 58))
    sheet = Image.new("RGB", (1200, 780), (14, 16, 19))
    draw = ImageDraw.Draw(sheet)
    y = 24
    for width, height in samples:
        draw.text((24, y), f"{width} x {height}", fill=(232, 211, 158))
        for x, kind in ((180, "primary"), (690, "secondary")):
            path = THEME / "ui" / f"ui_button_{kind}_native_{width}x{height}.png"
            image = Image.open(path).convert("RGBA")
            preview_scale = min(0.82, 460 / width, 104 / height)
            preview = image.resize(
                (round(width * preview_scale), round(height * preview_scale)),
                Image.Resampling.LANCZOS,
            )
            sheet.paste(preview, (x, y + 20), preview)
            draw.text((x + 8, y + 24 + preview.height), kind, fill=(180, 196, 207))
        y += 140
    sheet.save(BUTTON_CONTACT, quality=95)


def refresh_button_manifest(entries: list[dict]) -> None:
    payload = {
        "version": 2,
        "count": len(entries),
        "source_masters": [
            str(BUTTON_PRIMARY_MASTER.relative_to(ROOT)),
            str(BUTTON_SECONDARY_MASTER.relative_to(ROOT)),
        ],
        "composition": "native three-slice; rendered end armor preserved; quiet center lane resized",
        "assets": entries,
    }
    BUTTON_MANIFEST.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")

    if not MANIFEST.exists():
        return
    runtime = json.loads(MANIFEST.read_text())
    replacements = {entry["path"]: entry for entry in entries}
    replaced = 0
    for index, entry in enumerate(runtime.get("assets", [])):
        if entry.get("path") in replacements:
            runtime["assets"][index] = replacements[entry["path"]]
            replaced += 1
    if replaced != len(entries):
        raise RuntimeError(f"runtime manifest button coverage drift: {replaced} != {len(entries)}")
    runtime["count"] = len(runtime.get("assets", []))
    MANIFEST.write_text(json.dumps(runtime, ensure_ascii=False, indent=2) + "\n")


def gilded_grade(image: Image.Image, functional: tuple[int, int, int]) -> Image.Image:
    image = image.convert("RGBA")
    alpha = np.asarray(image.getchannel("A"), dtype=np.uint8)
    rgb = np.asarray(image.convert("RGB"), dtype=np.float32)
    luma = rgb.mean(axis=2)
    saturation = rgb.max(axis=2) - rgb.min(axis=2)
    shell = np.stack((luma * 0.32 + 8, luma * 0.29 + 7, luma * 0.27 + 7), axis=2)
    keep = saturation > 48
    out = np.where(keep[:, :, None], rgb * 0.58 + np.array(functional)[None, None, :] * 0.22 + np.array([58, 42, 20])[None, None, :], shell)
    edge = ImageChops.subtract(Image.fromarray(alpha), Image.fromarray(alpha).filter(ImageFilter.MinFilter(7)))
    edge_amount = np.asarray(edge, dtype=np.float32)[:, :, None] / 255.0
    out = out * (1.0 - edge_amount * 0.30) + np.array([255, 207, 94])[None, None, :] * edge_amount * 0.66
    return Image.fromarray(np.dstack((np.clip(out, 0, 255).astype(np.uint8), alpha)))


def build_weapon_coatings(entries: list[dict]) -> None:
    data = json.loads((ROOT / "data/weapons.json").read_text())
    out = THEME / "weapons"
    out.mkdir(parents=True, exist_ok=True)
    for weapon_id in WEAPONS:
        row = data[weapon_id]
        for kind, size, flip in (("icon", (384, 384), False), ("handheld", (720, 420), True), ("turret", (520, 520), False)):
            source_path = ROOT / str(row.get(kind, row.get("turret", row.get("icon", "")))).removeprefix("res://")
            source = Image.open(source_path).convert("RGBA")
            if flip:
                source = source.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            path = out / f"{weapon_id}_{kind}.png"
            fit_alpha(gilded_grade(source, FUNCTIONAL[weapon_id]), size, 0.90).save(path, optimize=True)
            entries.append(record(path, f"weapon_{kind}"))


def build_premium(entries: list[dict]) -> None:
    board = Image.open(SOURCE / "golden_law_equipment_master_v2.png").convert("RGBA").crop((0, 0, 941, 1536))
    cells = {
        "weapon_apocalypse_golden_law_master.png": (0, 0),
        "armor_apocalypse_eternal_night_master.png": (1, 0),
        "chip_apocalypse_golden_law_master.png": (0, 1),
        "pet_apocalypse_skyfalcon_master.png": (1, 1),
    }
    masters: dict[str, Image.Image] = {}
    for name, (col, row) in cells.items():
        master = keep_largest(remove_dark(panel(board, 2, 2, col, row, 38), 5))
        master.save(SOURCE / name, optimize=True)
        masters[name] = master
    outputs = {
        "weapon_apocalypse_golden_law_master.png": (("weapon_apocalypse_golden_law_icon.png", (384, 384), False), ("weapon_apocalypse_golden_law_handheld.png", (720, 420), True), ("weapon_apocalypse_golden_law_turret.png", (520, 520), False)),
        "armor_apocalypse_eternal_night_master.png": (("armor_apocalypse_eternal_night_icon.png", (384, 384), False),),
        "chip_apocalypse_golden_law_master.png": (("chip_apocalypse_golden_law_icon.png", (384, 384), False),),
        "pet_apocalypse_skyfalcon_master.png": (("pet_apocalypse_skyfalcon_icon.png", (384, 384), False), ("pet_apocalypse_skyfalcon_prototype.png", (360, 360), False)),
    }
    PREMIUM.mkdir(parents=True, exist_ok=True)
    for master_name, variants in outputs.items():
        for filename, size, flip in variants:
            source = masters[master_name].transpose(Image.Transpose.FLIP_LEFT_RIGHT) if flip else masters[master_name]
            path = PREMIUM / filename
            fit_alpha(source, size, 0.90).save(path, optimize=True)
            entries.append(record(path, "premium_item"))


def build_true_grip(entries: list[dict]) -> None:
    out = PREMIUM / "true_grip"
    out.mkdir(parents=True, exist_ok=True)
    previews: list[tuple[str, Image.Image]] = []
    master = Image.open(SOURCE / "golden_law_true_grip_three_direction_master_v2.png").convert("RGBA")
    directions = ((0, "left", "_left"), (1, "center", ""), (2, "right", "_right"))
    content_left, content_top = 54, 34
    cell_width = (master.width - content_left) / 3.0
    cell_height = (master.height - content_top) / 4.0
    frost_master = Image.open(FROST_TRUE_GRIP_CHROMA).convert("RGBA") if FROST_TRUE_GRIP_CHROMA.exists() else None
    for hero_index, hero in enumerate(HEROES):
        for panel_index, direction, suffix in directions:
            if hero == "char_frost" and frost_master is not None:
                # The accepted all-hero presentation board uses a dark runway.
                # Frost's black greaves and long coat are visually close to that
                # floor, so generic GrabCut used to delete her lower body as
                # disconnected background.  Use the reviewed chroma extraction
                # source for all three aim directions and preserve every valid
                # body/weapon component instead of keeping only the largest one.
                frost_cell_width = frost_master.width / 3.0
                crop = frost_master.crop((
                    round(panel_index * frost_cell_width) + 6,
                    6,
                    round((panel_index + 1) * frost_cell_width) - 6,
                    frost_master.height - 6,
                ))
                foreground = keep_components(remove_green(crop), 120)
            else:
                crop = master.crop((
                    round(content_left + panel_index * cell_width) + 5,
                    round(content_top + hero_index * cell_height) + 5,
                    round(content_left + (panel_index + 1) * cell_width) - 5,
                    round(content_top + (hero_index + 1) * cell_height) - 5,
                ))
                foreground = keep_largest(grabcut_foreground(crop))
            sprite = fit_alpha(foreground, (380, 520), 0.95)
            if hero == "char_frost" and frost_master is not None:
                sprite = despill_green(sprite)
            validate_true_grip_sprite(sprite, hero, direction)
            path = out / f"{hero}_apocalypse_attack{suffix}.png"
            sprite.save(path, optimize=True)
            entries.append(record(path, f"true_grip_{direction}"))
            if direction == "center":
                previews.append((hero, sprite))
    sheet = Image.new("RGB", (1600, 620), (6, 12, 22))
    draw = ImageDraw.Draw(sheet)
    for index, (hero, sprite) in enumerate(previews):
        x = index * 400 + 15
        thumb = fit_alpha(sprite, (370, 520), 0.94)
        sheet.paste(thumb, (x, 18), thumb)
        draw.text((x + 10, 552), f"{hero} + Golden Law (battle rear)", fill=(210, 238, 255))
    sheet.save(TRUE_GRIP_CONTACT, quality=94)


def validate_true_grip_sprite(sprite: Image.Image, hero: str, direction: str) -> None:
    """Reject cropped true-grip silhouettes before they can reach a build."""
    alpha = np.asarray(sprite.convert("RGBA").getchannel("A"), dtype=np.uint8)
    ys, xs = np.where(alpha > 24)
    if xs.size == 0:
        raise RuntimeError(f"empty true-grip sprite: {hero}/{direction}")
    x0, x1 = int(xs.min()), int(xs.max()) + 1
    y0, y1 = int(ys.min()), int(ys.max()) + 1
    height = y1 - y0
    width = x1 - x0
    if height < 470 or width < 145:
        raise RuntimeError(f"undersized true-grip silhouette: {hero}/{direction} bbox={width}x{height}")
    if hero != "char_frost":
        return
    # Frost's complete battle silhouette must retain two grounded lower-body
    # zones.  The former waist-cropped exports had only a single narrow coat
    # point below 72% of the silhouette; requiring substantial alpha on both
    # sides catches that failure without coupling validation to exact pixels.
    lower = alpha[y0 + round(height * 0.72):y1, x0:x1] > 24
    midpoint = lower.shape[1] // 2
    left_coverage = int(lower[:, :midpoint].sum())
    right_coverage = int(lower[:, midpoint:].sum())
    minimum_side_coverage = max(260, round(height * width * 0.012))
    if left_coverage < minimum_side_coverage or right_coverage < minimum_side_coverage:
        raise RuntimeError(
            f"cropped Frost lower body: {direction} left={left_coverage} right={right_coverage}"
        )


def build_signature(entries: list[dict]) -> None:
    out = THEME / "vfx"
    out.mkdir(parents=True, exist_ok=True)
    for index, phase in enumerate((0.0, 0.22, 0.48, 0.76), 1):
        layer = Image.new("RGBA", (768, 768))
        draw = ImageDraw.Draw(layer)
        opacity = (82, 148, 214, 0)[index - 1]
        for ribbon in range(7):
            points = []
            for step in range(33):
                t = step / 32.0
                y = 670 - t * 520
                x = 384 + np.sin(t * 8.2 + ribbon * 0.78 + phase * 4.0) * (80 + ribbon * 7) + (ribbon - 3) * 17
                points.append((x, y))
            draw.line(points, fill=(255, 218 - ribbon * 5, 118, opacity), width=3 + ribbon % 2)
        draw.ellipse((282, 484, 486, 688), outline=(255, 226, 146, opacity), width=5)
        layer = layer.filter(ImageFilter.GaussianBlur(1.4))
        path = out / f"vfx_gilded_eclipse_fire_aura_{index:02d}.png"
        layer.save(path, optimize=True)
        entries.append(record(path, "theme_fire_signature"))


def build_logo(entries: list[dict]) -> None:
    board = Image.open(SOURCE / "gilded_eclipse_ui_world_style_board_v1.png").convert("RGBA")
    # The accepted board contains two title variants in its top-left panel and
    # UI controls in the right column.  Crop only the primary wordmark; the old
    # broad crop accidentally shipped parts of the emblem/control column and a
    # second-logo fragment into the menu texture.
    logo = remove_dark(board.crop((28, 34, 620, 314)), 5)
    path = THEME / "ui/ui_menu_title_zombie_fire.png"
    fit_alpha(logo, (1040, 340), 0.92).save(path, optimize=True)
    entries.append(record(path, "theme_logo"))


def build_contact(entries: list[dict]) -> None:
    samples = [THEME / f"characters/{hero}_portrait_frameless.png" for hero in HEROES]
    samples += [
        THEME / "weapons/weapon_cryocannon_icon.png",
        PREMIUM / "weapon_apocalypse_golden_law_icon.png",
        PREMIUM / "armor_apocalypse_eternal_night_icon.png",
        PREMIUM / "chip_apocalypse_golden_law_icon.png",
        PREMIUM / "pet_apocalypse_skyfalcon_icon.png",
        THEME / "vfx/vfx_gilded_eclipse_fire_aura_03.png",
    ]
    sheet = Image.new("RGB", (1600, 1000), (5, 11, 21))
    draw = ImageDraw.Draw(sheet)
    for index, path in enumerate(samples):
        thumb = fit_alpha(Image.open(path), (300, 400 if index < 4 else 300), 0.90)
        x, y = (index % 5) * 320 + 10, (index // 5) * 500 + 20
        sheet.paste(thumb, (x, y), thumb)
        draw.text((x + 8, y + 410), path.stem[:34], fill=(210, 238, 255))
    sheet.save(CONTACT, quality=94)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--buttons-only",
        action="store_true",
        help="rebuild reviewed Gilded Eclipse button natives without touching other accepted runtime art",
    )
    args = parser.parse_args()
    entries: list[dict] = []
    if args.buttons_only:
        build_buttons(entries)
        build_button_contact()
        refresh_button_manifest(entries)
        print(f"Gilded Eclipse rendered button assets built: {len(entries)} files")
        return
    build_heroes(entries)
    button_start = len(entries)
    build_buttons(entries)
    button_entries = entries[button_start:]
    build_weapon_coatings(entries)
    build_premium(entries)
    build_true_grip(entries)
    build_signature(entries)
    build_logo(entries)
    build_contact(entries)
    MANIFEST.write_text(json.dumps({"version": 1, "count": len(entries), "assets": entries}, ensure_ascii=False, indent=2) + "\n")
    build_button_contact()
    refresh_button_manifest(button_entries)
    print(f"Gilded Eclipse runtime assets built: {len(entries)} files")


if __name__ == "__main__":
    main()
