#!/usr/bin/env python3
"""Build Infernal Dominion Step-2 runtime assets from approved alpha masters.

The generated masters freeze identity and hard-surface design.  This builder is
deterministic: it fits those masters into the runtime canvases, derives the
minimal 4/4/3 theme animation set, paints every button at its native size, and
creates cosmetic weapon variants without changing gameplay data or geometry.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
import cv2
from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/production/source_refs/generated/premium_infernal_dominion_inferno_phase2_2026_07_31"
THEME = ROOT / "assets/production/sprites/themes/infernal_dominion"
PREMIUM = ROOT / "assets/production/sprites/premium/infernal_dominion"
MANIFEST = SOURCE / "infernal_runtime_manifest_v1.json"
CONTACT = SOURCE / "infernal_runtime_contact_sheet_v1.png"
TRUE_GRIP_CONTACT = SOURCE / "inferno_true_grip_contact_sheet_v1.png"
BUTTON_PRIMARY_MASTER = SOURCE / "infernal_dominion_button_primary_transparent_v2.png"
BUTTON_SECONDARY_MASTER = SOURCE / "infernal_dominion_button_secondary_transparent_v2.png"
BUTTON_MANIFEST = SOURCE / "infernal_dominion_button_runtime_manifest_v2.json"
BUTTON_CONTACT = SOURCE / "infernal_dominion_button_runtime_contact_sheet_v2.png"

HEROES = ("char_vanguard", "char_blaze", "char_frost", "char_volt")
WEAPONS = (
    "weapon_autocannon", "weapon_flamethrower", "weapon_cryocannon",
    "weapon_teslacoil", "weapon_venomlauncher", "weapon_railgun",
    "weapon_scattergun", "weapon_plasmacannon",
)
FUNCTIONAL = {
    "weapon_autocannon": (222, 166, 68), "weapon_flamethrower": (255, 82, 24),
    "weapon_cryocannon": (76, 218, 255), "weapon_teslacoil": (126, 112, 255),
    "weapon_venomlauncher": (112, 232, 70), "weapon_railgun": (164, 244, 255),
    "weapon_scattergun": (255, 190, 70), "weapon_plasmacannon": (225, 92, 255),
}
BUTTON_SIZES = (
    (154, 44), (166, 58), (170, 84), (172, 44), (174, 72), (176, 76),
    (236, 96), (260, 112), (268, 48), (286, 72), (286, 80), (286, 112),
    (320, 74), (320, 80), (412, 88), (432, 88), (440, 80), (440, 88),
    (444, 88), (452, 88), (484, 102), (512, 160), (560, 104), (600, 120),
    (760, 88), (760, 112), (780, 148), (784, 96), (840, 88), (880, 88),
    (880, 96), (904, 88), (920, 88), (980, 58), (980, 96), (980, 100),
)


def fit_alpha(image: Image.Image, size: tuple[int, int], fill: float = 0.92) -> Image.Image:
    image = image.convert("RGBA")
    box = image.getbbox()
    if box is None:
        raise RuntimeError("empty alpha master")
    image = image.crop(box)
    scale = min(size[0] * fill / image.width, size[1] * fill / image.height)
    image = image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", size)
    canvas.alpha_composite(image, ((size[0] - image.width) // 2, (size[1] - image.height) // 2))
    return canvas


def keep_largest_alpha_component(image: Image.Image) -> Image.Image:
    """Drop neighboring-panel fragments left by a wide triptych silhouette."""
    rgba = np.asarray(image.convert("RGBA")).copy()
    mask = (rgba[:, :, 3] > 18).astype(np.uint8)
    count, labels, stats, _centroids = cv2.connectedComponentsWithStats(mask, 8)
    if count <= 1:
        return image.convert("RGBA")
    largest = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
    keep = labels == largest
    rgba[~keep, 3] = 0
    return Image.fromarray(rgba)


def battle_back_panel(hero: str, panel_index: int) -> Image.Image:
    """Return one authored rear-view panel from the 4-pose battle sheet.

    Panel 0 is weaponless idle; panels 1/2/3 are upper-left, forward and
    upper-right true-grip poses.  Store/collection portraits deliberately keep
    using the front master while every battlefield sprite uses this rear view.
    """
    sheet = Image.open(SOURCE / f"{hero}_infernal_battle_back_sheet.png").convert("RGBA")
    x0 = round(sheet.width * panel_index / 4.0)
    x1 = round(sheet.width * (panel_index + 1) / 4.0)
    return keep_largest_alpha_component(sheet.crop((x0, 0, x1, sheet.height)))


def hero_frame(master: Image.Image, state: str, index: int) -> Image.Image:
    # Deliberately subtle theme-only motion.  Weapon-specific semantic firing
    # remains in the existing combo system and Step 4 true-grip production.
    base = fit_alpha(master, (512, 512), 0.92)
    if state == "idle":
        dy = (-2, 0, 2, 0)[index]
        scale = (0.995, 1.0, 1.006, 1.0)[index]
        angle = (-0.35, 0.0, 0.35, 0.0)[index]
    elif state == "attack":
        dy = (2, -4, -7, -2)[index]
        scale = (1.0, 1.012, 1.025, 1.008)[index]
        angle = (-0.5, 0.8, 1.6, 0.2)[index]
    else:
        dy = (2, 6, 1)[index]
        scale = (0.995, 0.982, 1.0)[index]
        angle = (-1.5, 1.8, -0.4)[index]
    transformed = base.rotate(angle, resample=Image.Resampling.BICUBIC, expand=False)
    if scale != 1.0:
        resized = transformed.resize((round(512 * scale), round(512 * scale)), Image.Resampling.LANCZOS)
        transformed = Image.new("RGBA", (512, 512))
        transformed.alpha_composite(resized, ((512 - resized.width) // 2, (512 - resized.height) // 2 + dy))
    else:
        shifted = Image.new("RGBA", (512, 512))
        shifted.alpha_composite(transformed, (0, dy))
        transformed = shifted
    return transformed


def build_heroes(entries: list[dict]) -> None:
    for hero in HEROES:
        display_master = Image.open(SOURCE / f"{hero}_infernal_alpha.png").convert("RGBA")
        portrait = fit_alpha(display_master, (720, 980), 0.94)
        portrait_path = THEME / "characters" / f"{hero}_portrait_frameless.png"
        portrait_path.parent.mkdir(parents=True, exist_ok=True)
        portrait.save(portrait_path, optimize=True)
        entries.append(record(portrait_path, "hero_portrait"))
        battle_master = battle_back_panel(hero, 0)
        out = THEME / "characters/animations" / hero
        out.mkdir(parents=True, exist_ok=True)
        for state, count in (("idle", 4), ("attack", 4), ("hurt", 3)):
            for idx in range(count):
                path = out / f"{hero}_{state}_{idx + 1:02d}.png"
                hero_frame(battle_master, state, idx).save(path, optimize=True)
                entries.append(record(path, f"hero_{state}"))


def button_master(path: Path) -> Image.Image:
    """Load one reviewed render and discard only sub-visible matte residue."""
    if not path.exists():
        raise FileNotFoundError(f"missing reviewed Infernal Dominion button master: {path}")
    master = Image.open(path).convert("RGBA")
    alpha = np.asarray(master.getchannel("A"), dtype=np.uint8).copy()
    alpha[alpha <= 12] = 0
    master.putalpha(Image.fromarray(alpha))
    bbox = master.getbbox()
    if bbox is None:
        raise RuntimeError(f"empty reviewed Infernal Dominion button master: {path}")
    master = master.crop(bbox)
    if master.width / master.height < 2.8:
        raise RuntimeError(f"Infernal button master is not a wide bezel: {path}")
    return master


def button_asset(master: Image.Image, width: int, height: int) -> Image.Image:
    """Compose one native-size control without stretching the rendered end caps.

    The old Infernal family drew polygon outlines, dots and rails at runtime
    build time.  This production path preserves the reviewed forged end armor
    and resizes only a quiet central text lane, so compact purchase buttons and
    long navigation buttons share one material identity without distortion.
    """
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
        raise RuntimeError(f"Infernal button target is too narrow: {width}x{height}")

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
        raise RuntimeError(f"{kind} Infernal button size drift: {image.size} != {(width, height)}")
    alpha = np.asarray(image.getchannel("A"), dtype=np.uint8)
    if alpha.max() < 220:
        raise RuntimeError(f"{kind} Infernal button lost its opaque material body")
    corners = ((0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1))
    if any(alpha[y, x] > 12 for x, y in corners):
        raise RuntimeError(f"{kind} Infernal button touches a transparent canvas corner")
    visible = np.asarray(image.convert("RGB"), dtype=np.uint8)[alpha > 96]
    if visible.size == 0 or np.std(visible.astype(np.float32)) < 18.0:
        raise RuntimeError(f"{kind} Infernal button lost rendered material variation")


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
        draw.text((24, y), f"{width} x {height}", fill=(232, 184, 126))
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
        "composition": "native three-slice; rendered forged end armor preserved; quiet center lane resized",
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
        raise RuntimeError(f"Infernal runtime manifest button coverage drift: {replaced} != {len(entries)}")
    runtime["count"] = len(runtime.get("assets", []))
    MANIFEST.write_text(json.dumps(runtime, ensure_ascii=False, indent=2) + "\n")


def infernal_grade(image: Image.Image, functional: tuple[int, int, int]) -> Image.Image:
    image = image.convert("RGBA")
    a = np.asarray(image.getchannel("A"), dtype=np.uint8)
    rgb = np.asarray(image.convert("RGB"), dtype=np.float32)
    luma = rgb.mean(axis=2)
    saturation = rgb.max(axis=2) - rgb.min(axis=2)
    keep_color = saturation > 48
    shell = np.stack((luma * 0.52 + 20, luma * 0.34 + 13, luma * 0.24 + 10), axis=2)
    out = np.where(keep_color[:, :, None], rgb * 0.82 + np.array(functional)[None, None, :] * 0.18, shell)
    alpha_image = Image.fromarray(a)
    edge = ImageChops.subtract(alpha_image, alpha_image.filter(ImageFilter.MinFilter(7)))
    edge_arr = np.asarray(edge, dtype=np.float32)[:, :, None] / 255.0
    out = out * (1.0 - edge_arr * 0.32) + np.array([255, 94, 22])[None, None, :] * edge_arr * 0.42
    rgba = np.dstack((np.clip(out, 0, 255).astype(np.uint8), a))
    return Image.fromarray(rgba)


def build_weapon_coatings(entries: list[dict]) -> None:
    data = json.loads((ROOT / "data/weapons.json").read_text())
    out = THEME / "weapons"
    out.mkdir(parents=True, exist_ok=True)
    for weapon_id in WEAPONS:
        row = data[weapon_id]
        for kind, size, flip in (("icon", (384, 384), False), ("handheld", (720, 420), True), ("turret", (520, 520), False)):
            source_key = kind if kind in row else "turret" if kind == "handheld" else "icon"
            source_path = ROOT / str(row[source_key]).removeprefix("res://")
            source = Image.open(source_path).convert("RGBA")
            if flip:
                source = source.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            source = infernal_grade(source, FUNCTIONAL[weapon_id])
            path = out / f"{weapon_id}_{kind}.png"
            fit_alpha(source, size, 0.90).save(path, optimize=True)
            entries.append(record(path, f"weapon_{kind}"))


def build_premium(entries: list[dict]) -> None:
    variants = {
        "weapon_apocalypse_inferno_master.png": (("weapon_apocalypse_inferno_icon.png", (384, 384), False), ("weapon_apocalypse_inferno_handheld.png", (720, 420), True), ("weapon_apocalypse_inferno_turret.png", (520, 520), False)),
        "armor_apocalypse_molten_master.png": (("armor_apocalypse_molten_icon.png", (384, 384), False),),
        "chip_apocalypse_stellar_master.png": (("chip_apocalypse_stellar_icon.png", (384, 384), False),),
        "pet_apocalypse_phoenix_master.png": (("pet_apocalypse_phoenix_icon.png", (384, 384), False), ("pet_apocalypse_phoenix_prototype.png", (360, 360), False)),
    }
    PREMIUM.mkdir(parents=True, exist_ok=True)
    for master_name, outputs in variants.items():
        source = Image.open(SOURCE / master_name).convert("RGBA")
        for name, size, flip in outputs:
            variant = source.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if flip else source
            path = PREMIUM / name
            fit_alpha(variant, size, 0.90).save(path, optimize=True)
            entries.append(record(path, "premium_item"))


def build_true_grip(entries: list[dict]) -> None:
    """Split the approved rear-view four-pose sheets into battle sprites.

    Panels 1/2/3 already contain correct two-hand contact and shoulder bracing.
    Runtime animation adds the 8-frame timing/recoil, so each direction stays a
    single identity-stable master.  Front triptychs remain display-only source.
    """
    out = PREMIUM / "true_grip"
    out.mkdir(parents=True, exist_ok=True)
    directions = (("left", "_left"), ("center", ""), ("right", "_right"))
    previews: list[tuple[str, Image.Image]] = []
    for hero in HEROES:
        for index, (direction, suffix) in enumerate(directions):
            panel = battle_back_panel(hero, index + 1)
            sprite = fit_alpha(panel, (380, 520), 0.94)
            path = out / f"{hero}_apocalypse_attack{suffix}.png"
            sprite.save(path, optimize=True)
            entries.append(record(path, f"true_grip_{direction}"))
            if direction == "center":
                previews.append((hero, sprite))
    sheet = Image.new("RGB", (1600, 620), (7, 10, 14))
    draw = ImageDraw.Draw(sheet)
    for index, (hero, sprite) in enumerate(previews):
        thumb = fit_alpha(sprite, (370, 520), 0.94)
        x = index * 400 + 15
        sheet.paste(thumb, (x, 18), thumb)
        draw.text((x + 10, 552), f"{hero} + Apocalypse Inferno (battle rear)", fill=(242, 219, 194))
    sheet.save(TRUE_GRIP_CONTACT, quality=94)


def build_signature(entries: list[dict]) -> None:
    master = Image.open(SOURCE / "infernal_character_fire_signature_master.png").convert("RGBA")
    master = fit_alpha(master, (768, 768), 0.94)
    # The authored silhouette is accepted, but its concept master contains a
    # yellow-green energy fringe.  Runtime Infernal Dominion must read as one
    # coherent heat system, so preserve all mechanical detail/alpha while
    # grading it through dark copper -> molten orange -> white-hot metal.
    pixels = np.asarray(master).copy()
    rgb = pixels[:, :, :3].astype(np.float32) / 255.0
    luminance = np.clip(np.max(rgb, axis=2), 0.0, 1.0)
    hot = np.clip((luminance - 0.55) / 0.45, 0.0, 1.0)
    pixels[:, :, 0] = np.clip(92.0 + 163.0 * luminance, 0.0, 255.0).astype(np.uint8)
    pixels[:, :, 1] = np.clip(12.0 + 82.0 * luminance + 112.0 * hot, 0.0, 255.0).astype(np.uint8)
    pixels[:, :, 2] = np.clip(2.0 + 22.0 * luminance + 64.0 * hot, 0.0, 255.0).astype(np.uint8)
    master = Image.fromarray(pixels)
    out = THEME / "vfx"
    out.mkdir(parents=True, exist_ok=True)
    for i, (scale, alpha, angle) in enumerate(((0.72, 0.38, -2.5), (0.86, 0.62, -0.8), (1.0, 0.82, 0.8), (1.08, 0.0, 2.2)), 1):
        layer = master.rotate(angle, Image.Resampling.BICUBIC, expand=False)
        if scale != 1.0:
            resized = layer.resize((round(768 * scale), round(768 * scale)), Image.Resampling.LANCZOS)
            canvas = Image.new("RGBA", (768, 768))
            canvas.alpha_composite(resized, ((768 - resized.width) // 2, (768 - resized.height) // 2))
            layer = canvas
        channel = layer.getchannel("A").point(lambda p, a=alpha: round(p * a))
        layer.putalpha(channel)
        path = out / f"vfx_infernal_dominion_fire_aura_{i:02d}.png"
        layer.save(path, optimize=True)
        entries.append(record(path, "theme_fire_signature"))


def build_logo(entries: list[dict]) -> None:
    board = Image.open(SOURCE / "infernal_dominion_ui_world_style_board_v1.png").convert("RGBA")
    # The title lives inside the upper-left style-board panel.  Crop the
    # wordmark itself, not the panel: the former broad crop also captured the
    # red panel rule, the neighbouring control column and the crest below it.
    # Those fragments became very obvious once the App Store menu treatment
    # enlarged the title close to full viewport width.
    crop = board.crop((22, 20, 574, 348))
    rgb = np.asarray(crop.convert("RGB"), dtype=np.uint8)
    luma = rgb.max(axis=2)
    alpha = np.clip((luma.astype(np.int16) - 8) * 11, 0, 255).astype(np.uint8)
    rgba = np.dstack((rgb, alpha))
    logo = fit_alpha(Image.fromarray(rgba), (1040, 340), 0.92)
    path = THEME / "ui/ui_menu_title_zombie_fire.png"
    logo.save(path, optimize=True)
    entries.append(record(path, "theme_logo"))


def record(path: Path, kind: str) -> dict:
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    with Image.open(path) as im:
        size = list(im.size)
    return {"path": str(path.relative_to(ROOT)), "kind": kind, "size": size, "sha256": digest}


def build_contact(entries: list[dict]) -> None:
    samples = [
        THEME / "characters/char_vanguard_portrait_frameless.png",
        THEME / "characters/char_blaze_portrait_frameless.png",
        THEME / "characters/char_frost_portrait_frameless.png",
        THEME / "characters/char_volt_portrait_frameless.png",
        THEME / "weapons/weapon_flamethrower_icon.png",
        PREMIUM / "weapon_apocalypse_inferno_icon.png",
        PREMIUM / "armor_apocalypse_molten_icon.png",
        PREMIUM / "chip_apocalypse_stellar_icon.png",
        PREMIUM / "pet_apocalypse_phoenix_icon.png",
        THEME / "vfx/vfx_infernal_dominion_fire_aura_03.png",
    ]
    sheet = Image.new("RGB", (1600, 1000), (7, 10, 14))
    draw = ImageDraw.Draw(sheet)
    for i, path in enumerate(samples):
        thumb = fit_alpha(Image.open(path), (300, 400 if i < 4 else 300), 0.90)
        x = (i % 5) * 320 + 10
        y = (i // 5) * 500 + 20
        sheet.paste(thumb, (x, y), thumb)
        draw.text((x + 8, y + 410), path.stem[:34], fill=(232, 222, 210))
    sheet.save(CONTACT, quality=94)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--buttons-only",
        action="store_true",
        help="rebuild reviewed Infernal Dominion button natives without touching other accepted runtime art",
    )
    args = parser.parse_args()
    entries: list[dict] = []
    if args.buttons_only:
        build_buttons(entries)
        build_button_contact()
        refresh_button_manifest(entries)
        print(f"Infernal Dominion rendered button assets built: {len(entries)} files")
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
    print(f"Infernal runtime assets built: {len(entries)} files")


if __name__ == "__main__":
    main()
