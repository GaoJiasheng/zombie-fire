#!/usr/bin/env python3
"""Build Polar Aurora / Absolute Zero runtime art from accepted source boards.

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
SOURCE = ROOT / "assets/production/source_refs/generated/premium_polar_aurora_absolute_zero_phase3_2026_08_01"
THEME = ROOT / "assets/production/sprites/themes/polar_aurora"
PREMIUM = ROOT / "assets/production/sprites/premium/polar_aurora"
MANIFEST = SOURCE / "polar_aurora_runtime_manifest_v1.json"
CONTACT = SOURCE / "polar_aurora_runtime_contact_sheet_v1.png"
TRUE_GRIP_CONTACT = SOURCE / "absolute_zero_true_grip_contact_sheet_v1.png"
BUTTON_PRIMARY_MASTER = SOURCE / "polar_aurora_button_primary_transparent_v2.png"
BUTTON_SECONDARY_MASTER = SOURCE / "polar_aurora_button_secondary_transparent_v2.png"
BUTTON_MANIFEST = SOURCE / "polar_aurora_button_runtime_manifest_v2.json"
BUTTON_CONTACT = SOURCE / "polar_aurora_button_runtime_contact_sheet_v2.png"

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
    rgba = np.dstack((red, green, blue, alpha)).clip(0, 255).astype(np.uint8)
    return keep_components(Image.fromarray(rgba), 120)


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
    front = Image.open(SOURCE / "polar_aurora_hero_outfit_contact_sheet_v1.png").convert("RGBA")
    for index, hero in enumerate(HEROES):
        front_panel = remove_dark(panel(front, 2, 2, index % 2, index // 2, 8), 5)
        alpha_path = SOURCE / f"{hero}_polar_alpha.png"
        front_panel.save(alpha_path, optimize=True)
        portrait_path = THEME / "characters" / f"{hero}_portrait_frameless.png"
        portrait_path.parent.mkdir(parents=True, exist_ok=True)
        fit_alpha(front_panel, (720, 980), 0.94).save(portrait_path, optimize=True)
        entries.append(record(portrait_path, "hero_portrait"))

        rear_sheet = remove_green(Image.open(SOURCE / f"{hero}_polar_absolute_zero_battle_back_sheet_chroma.png"))
        cleaned_path = SOURCE / f"{hero}_polar_absolute_zero_battle_back_sheet.png"
        rear_sheet.save(cleaned_path, optimize=True)
        idle = panel(rear_sheet, 4, 1, 0, 0, 2)
        out = THEME / "characters/animations" / hero
        out.mkdir(parents=True, exist_ok=True)
        for state, count in (("idle", 4), ("attack", 4), ("hurt", 3)):
            for frame_index in range(count):
                path = out / f"{hero}_{state}_{frame_index + 1:02d}.png"
                hero_frame(idle, state, frame_index).save(path, optimize=True)
                entries.append(record(path, f"hero_{state}"))


def button_master(path: Path) -> Image.Image:
    """Load a reviewed physical-material render and trim only matte residue."""
    if not path.exists():
        raise FileNotFoundError(f"missing reviewed Polar Aurora button master: {path}")
    master = Image.open(path).convert("RGBA")
    alpha = np.asarray(master.getchannel("A"), dtype=np.uint8).copy()
    alpha[alpha <= 12] = 0
    master.putalpha(Image.fromarray(alpha))
    bbox = master.getbbox()
    if bbox is None:
        raise RuntimeError(f"empty reviewed Polar Aurora button master: {path}")
    master = master.crop(bbox)
    if master.width / master.height < 2.8:
        raise RuntimeError(f"Polar Aurora button master is not a wide bezel: {path}")
    return master


def button_asset(master: Image.Image, width: int, height: int) -> Image.Image:
    """Preserve rendered cryogenic end armor and resize only a quiet center lane."""
    canvas = Image.new("RGBA", (width, height))
    padding = max(1, round(min(width, height) * 0.025))
    target_width = width - padding * 2
    target_height = height - padding * 2

    source_cap = round(master.width * 0.255)
    center_x0 = round(master.width * 0.30)
    center_x1 = round(master.width * 0.38)
    left = master.crop((0, 0, source_cap, master.height))
    center = master.crop((center_x0, 0, center_x1, master.height))
    right = master.crop((master.width - source_cap, 0, master.width, master.height))

    min_center = max(12, round(target_height * 0.38))
    cap_width = min(round(target_height * 1.05), (target_width - min_center) // 2)
    cap_width = max(1, cap_width)
    center_width = target_width - cap_width * 2
    if center_width < 1:
        raise RuntimeError(f"Polar Aurora button target is too narrow: {width}x{height}")

    left = left.resize((cap_width, target_height), Image.Resampling.LANCZOS)
    right = right.resize((cap_width, target_height), Image.Resampling.LANCZOS)
    strip = Image.new("RGBA", (target_width, target_height))
    strip.alpha_composite(left, (0, 0))
    strip.alpha_composite(right, (cap_width + center_width, 0))

    overlap = min(max(3, round(target_height * 0.18)), cap_width // 2)
    center = center.resize((center_width + overlap * 2, target_height), Image.Resampling.LANCZOS)
    center_alpha = np.asarray(center.getchannel("A"), dtype=np.float32)
    blend = np.ones(center.width, dtype=np.float32)
    blend[:overlap] = np.linspace(0.0, 1.0, overlap, endpoint=False)
    blend[-overlap:] = np.linspace(1.0, 0.0, overlap, endpoint=False)
    center.putalpha(Image.fromarray(np.clip(center_alpha * blend[None, :], 0, 255).astype(np.uint8)))
    strip.alpha_composite(center, (cap_width - overlap, 0))
    canvas.alpha_composite(strip, (padding, padding))
    return canvas


def validate_button_asset(image: Image.Image, width: int, height: int, kind: str) -> None:
    if image.size != (width, height):
        raise RuntimeError(f"{kind} Polar Aurora button size drift: {image.size} != {(width, height)}")
    alpha = np.asarray(image.getchannel("A"), dtype=np.uint8)
    if alpha.max() < 220:
        raise RuntimeError(f"{kind} Polar Aurora button lost its opaque material body")
    corners = ((0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1))
    if any(alpha[y, x] > 12 for x, y in corners):
        raise RuntimeError(f"{kind} Polar Aurora button touches a transparent canvas corner")
    visible = np.asarray(image.convert("RGB"), dtype=np.uint8)[alpha > 96]
    if visible.size == 0 or np.std(visible.astype(np.float32)) < 18.0:
        raise RuntimeError(f"{kind} Polar Aurora button lost rendered material variation")


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
    sheet = Image.new("RGB", (1200, 780), (6, 12, 22))
    draw = ImageDraw.Draw(sheet)
    y = 24
    for width, height in samples:
        draw.text((24, y), f"{width} x {height}", fill=(210, 238, 255))
        for x, kind in ((180, "primary"), (690, "secondary")):
            path = THEME / "ui" / f"ui_button_{kind}_native_{width}x{height}.png"
            image = Image.open(path).convert("RGBA")
            preview_scale = min(0.82, 460 / width, 104 / height)
            preview = image.resize(
                (round(width * preview_scale), round(height * preview_scale)),
                Image.Resampling.LANCZOS,
            )
            sheet.paste(preview, (x, y + 20), preview)
            draw.text((x + 8, y + 24 + preview.height), kind, fill=(150, 190, 220))
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
        "composition": "native three-slice; rendered cryogenic end armor preserved; quiet center lane resized",
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
        raise RuntimeError(f"Polar Aurora runtime manifest button coverage drift: {replaced} != {len(entries)}")
    runtime["count"] = len(runtime.get("assets", []))
    MANIFEST.write_text(json.dumps(runtime, ensure_ascii=False, indent=2) + "\n")


def polar_grade(image: Image.Image, functional: tuple[int, int, int]) -> Image.Image:
    image = image.convert("RGBA")
    alpha = np.asarray(image.getchannel("A"), dtype=np.uint8)
    rgb = np.asarray(image.convert("RGB"), dtype=np.float32)
    luma = rgb.mean(axis=2)
    saturation = rgb.max(axis=2) - rgb.min(axis=2)
    shell = np.stack((luma * 0.70 + 36, luma * 0.78 + 40, luma * 0.90 + 52), axis=2)
    keep = saturation > 48
    out = np.where(keep[:, :, None], rgb * 0.76 + np.array(functional)[None, None, :] * 0.24, shell)
    edge = ImageChops.subtract(Image.fromarray(alpha), Image.fromarray(alpha).filter(ImageFilter.MinFilter(7)))
    edge_amount = np.asarray(edge, dtype=np.float32)[:, :, None] / 255.0
    out = out * (1.0 - edge_amount * 0.26) + np.array([152, 226, 255])[None, None, :] * edge_amount * 0.48
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
            fit_alpha(polar_grade(source, FUNCTIONAL[weapon_id]), size, 0.90).save(path, optimize=True)
            entries.append(record(path, f"weapon_{kind}"))


def build_premium(entries: list[dict]) -> None:
    board = Image.open(SOURCE / "absolute_zero_equipment_selection_board_v1.png").convert("RGBA")
    cells = {
        "weapon_apocalypse_absolute_zero_master.png": (1, 0),
        "armor_apocalypse_permafrost_master.png": (0, 1),
        "chip_apocalypse_entropy_master.png": (1, 1),
        "pet_apocalypse_aurora_master.png": (2, 1),
    }
    masters: dict[str, Image.Image] = {}
    for name, (col, row) in cells.items():
        master = keep_largest(remove_dark(panel(board, 3, 2, col, row, 30), 5))
        master.save(SOURCE / name, optimize=True)
        masters[name] = master
    outputs = {
        "weapon_apocalypse_absolute_zero_master.png": (("weapon_apocalypse_absolute_zero_icon.png", (384, 384), False), ("weapon_apocalypse_absolute_zero_handheld.png", (720, 420), True), ("weapon_apocalypse_absolute_zero_turret.png", (520, 520), False)),
        "armor_apocalypse_permafrost_master.png": (("armor_apocalypse_permafrost_icon.png", (384, 384), False),),
        "chip_apocalypse_entropy_master.png": (("chip_apocalypse_entropy_icon.png", (384, 384), False),),
        "pet_apocalypse_aurora_master.png": (("pet_apocalypse_aurora_icon.png", (384, 384), False), ("pet_apocalypse_aurora_prototype.png", (360, 360), False)),
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
    directions = ((1, "left", "_left"), (2, "center", ""), (3, "right", "_right"))
    for hero in HEROES:
        sheet = Image.open(SOURCE / f"{hero}_polar_absolute_zero_battle_back_sheet.png").convert("RGBA")
        for panel_index, direction, suffix in directions:
            sprite = fit_alpha(keep_largest(panel(sheet, 4, 1, panel_index, 0, 6)), (380, 520), 0.94)
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
        draw.text((x + 10, 552), f"{hero} + Absolute Zero (battle rear)", fill=(210, 238, 255))
    sheet.save(TRUE_GRIP_CONTACT, quality=94)


def build_signature(entries: list[dict]) -> None:
    source = remove_green(Image.open(SOURCE / "polar_aurora_character_fire_signature_master_chroma.png"))
    source.save(SOURCE / "polar_aurora_character_fire_signature_master.png", optimize=True)
    base = fit_alpha(source, (768, 768), 0.90)
    out = THEME / "vfx"
    out.mkdir(parents=True, exist_ok=True)
    for index, (scale, alpha, angle) in enumerate(((0.74, 0.34, -1.2), (0.88, 0.58, -0.4), (1.0, 0.80, 0.4), (1.06, 0.0, 1.1)), 1):
        layer = base.rotate(angle, Image.Resampling.BICUBIC, expand=False)
        if scale != 1.0:
            resized = layer.resize((round(768 * scale), round(768 * scale)), Image.Resampling.LANCZOS)
            canvas = Image.new("RGBA", (768, 768))
            canvas.alpha_composite(resized, ((768 - resized.width) // 2, (768 - resized.height) // 2))
            layer = canvas
        layer.putalpha(layer.getchannel("A").point(lambda value, factor=alpha: round(value * factor)))
        path = out / f"vfx_polar_aurora_fire_aura_{index:02d}.png"
        layer.save(path, optimize=True)
        entries.append(record(path, "theme_fire_signature"))


def build_logo(entries: list[dict]) -> None:
    board = Image.open(SOURCE / "polar_aurora_ui_world_style_board_v1.png").convert("RGBA")
    # Isolate the upper Zombie Fire wordmark.  The old full-panel crop included
    # the standalone lower crest and the board divider at the right edge, which
    # read as broken artwork after the menu logo was enlarged.
    logo = remove_dark(board.crop((22, 18, 574, 348)), 5)
    path = THEME / "ui/ui_menu_title_zombie_fire.png"
    fit_alpha(logo, (1040, 340), 0.92).save(path, optimize=True)
    entries.append(record(path, "theme_logo"))


def build_contact(entries: list[dict]) -> None:
    samples = [THEME / f"characters/{hero}_portrait_frameless.png" for hero in HEROES]
    samples += [
        THEME / "weapons/weapon_cryocannon_icon.png",
        PREMIUM / "weapon_apocalypse_absolute_zero_icon.png",
        PREMIUM / "armor_apocalypse_permafrost_icon.png",
        PREMIUM / "chip_apocalypse_entropy_icon.png",
        PREMIUM / "pet_apocalypse_aurora_icon.png",
        THEME / "vfx/vfx_polar_aurora_fire_aura_03.png",
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
        help="rebuild reviewed Polar Aurora button natives without touching other accepted runtime art",
    )
    args = parser.parse_args()
    entries: list[dict] = []
    if args.buttons_only:
        build_buttons(entries)
        build_button_contact()
        refresh_button_manifest(entries)
        print(f"Polar Aurora rendered button assets built: {len(entries)} files")
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
    print(f"Polar Aurora runtime assets built: {len(entries)} files")


if __name__ == "__main__":
    main()
