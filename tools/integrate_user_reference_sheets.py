#!/usr/bin/env python3
from __future__ import annotations

import json
import math
import shutil
from collections import deque
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageChops, ImageDraw, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
STAMP = "2026_07_02"
SOURCE_DIR = ROOT / "assets/production/source_refs/generated"
UI_DIR = ROOT / "assets/production/sprites/ui"
VFX_DIR = ROOT / "assets/production/sprites/vfx"
SEQ_DIR = ROOT / "assets/production/sprites/vfx_sequences"
CONTACT_DIR = ROOT / "assets/production/contact_sheets"
INDEX_PATH = ROOT / "assets/production/OUTSOURCER_ASSET_INDEX.json"

UI_CLIPBOARD = Path("/var/folders/qp/xhqbxltd5630c3_f8c0tymf40000gn/T/codex-clipboard-938cc479-1394-4924-9b0a-433a6c20ada9.png")
COMBAT_CLIPBOARD = Path("/var/folders/qp/xhqbxltd5630c3_f8c0tymf40000gn/T/codex-clipboard-a50650d9-ea97-47fd-a719-699584fd929c.png")
UI_REF = SOURCE_DIR / f"user_ui_vfx_reference_sheet_{STAMP}.png"
COMBAT_REF = SOURCE_DIR / f"user_combat_vfx_reference_sheet_{STAMP}.png"


def ensure_dirs() -> None:
    for path in [SOURCE_DIR, UI_DIR, VFX_DIR, SEQ_DIR, CONTACT_DIR]:
        path.mkdir(parents=True, exist_ok=True)


def copy_refs() -> tuple[Path, Path]:
    ensure_dirs()
    if UI_CLIPBOARD.exists():
        shutil.copy2(UI_CLIPBOARD, UI_REF)
    if COMBAT_CLIPBOARD.exists():
        shutil.copy2(COMBAT_CLIPBOARD, COMBAT_REF)
    if not UI_REF.exists():
        fallback = SOURCE_DIR / "ui_motion_top_tier_reference_2026_07_02.png"
        if fallback.exists():
            shutil.copy2(fallback, UI_REF)
    if not COMBAT_REF.exists():
        fallback = SOURCE_DIR / "combat_vfx_top_tier_reference_2026_07_02.png"
        if fallback.exists():
            shutil.copy2(fallback, COMBAT_REF)
    if not UI_REF.exists() or not COMBAT_REF.exists():
        raise FileNotFoundError("Missing user reference sheets")
    return UI_REF, COMBAT_REF


def enhance_crop(im: Image.Image, contrast: float = 1.08, sharpness: float = 1.08) -> Image.Image:
    im = ImageEnhance.Contrast(im).enhance(contrast)
    im = ImageEnhance.Sharpness(im).enhance(sharpness)
    return im


def bg_like(r: int, g: int, b: int) -> bool:
    mx = max(r, g, b)
    mn = min(r, g, b)
    return mx < 24 and (mx - mn) < 10


def flood_alpha(im: Image.Image) -> Image.Image:
    rgba = im.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    seen = [[False] * h for _ in range(w)]
    q: deque[tuple[int, int]] = deque()
    for x in range(w):
        for y in [0, h - 1]:
            r, g, b, _ = px[x, y]
            if bg_like(r, g, b):
                q.append((x, y))
                seen[x][y] = True
    for y in range(h):
        for x in [0, w - 1]:
            if seen[x][y]:
                continue
            r, g, b, _ = px[x, y]
            if bg_like(r, g, b):
                q.append((x, y))
                seen[x][y] = True
    while q:
        x, y = q.popleft()
        r, g, b, _ = px[x, y]
        px[x, y] = (r, g, b, 0)
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if nx < 0 or ny < 0 or nx >= w or ny >= h or seen[nx][ny]:
                continue
            nr, ng, nb, _ = px[nx, ny]
            if bg_like(nr, ng, nb):
                seen[nx][ny] = True
                q.append((nx, ny))
    return rgba


def vfx_alpha(im: Image.Image) -> Image.Image:
    rgb = im.convert("RGB")
    rgba = Image.new("RGBA", rgb.size)
    out = rgba.load()
    for y in range(rgb.height):
        for x in range(rgb.width):
            r, g, b = rgb.getpixel((x, y))
            mx = max(r, g, b)
            mn = min(r, g, b)
            sat = mx - mn
            alpha = int(max(0, min(255, (mx - 12) * 2.2 + sat * 0.45)))
            if mx < 20 and sat < 20:
                alpha = 0
            out[x, y] = (r, g, b, alpha)
    return rgba


def trim_alpha(im: Image.Image, pad: int = 6) -> Image.Image:
    bbox = im.getbbox()
    if bbox is None:
        return im
    left = max(0, bbox[0] - pad)
    top = max(0, bbox[1] - pad)
    right = min(im.width, bbox[2] + pad)
    bottom = min(im.height, bbox[3] + pad)
    return im.crop((left, top, right, bottom))


def fit_canvas(im: Image.Image, size: tuple[int, int], pad: int = 0) -> Image.Image:
    im = trim_alpha(im.convert("RGBA"), pad=4)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    max_w = max(1, size[0] - pad * 2)
    max_h = max(1, size[1] - pad * 2)
    scale = min(max_w / im.width, max_h / im.height)
    resized = im.resize((max(1, int(im.width * scale)), max(1, int(im.height * scale))), Image.Resampling.LANCZOS)
    x = (size[0] - resized.width) // 2
    y = (size[1] - resized.height) // 2
    canvas.alpha_composite(resized, (x, y))
    return canvas


def crop_ui(sheet: Image.Image, box: tuple[int, int, int, int], size: tuple[int, int], pad: int = 0) -> Image.Image:
    crop = enhance_crop(sheet.crop(box), 1.08, 1.15)
    return fit_canvas(flood_alpha(crop), size, pad)


def crop_vfx(sheet: Image.Image, box: tuple[int, int, int, int], size: tuple[int, int], pad: int = 0) -> Image.Image:
    crop = enhance_crop(sheet.crop(box), 1.18, 1.22)
    return fit_canvas(vfx_alpha(crop), size, pad)


def save_png(path: Path, image: Image.Image, written: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    written.append(str(path.relative_to(ROOT)))


def frame_boxes(x1: int, y1: int, x2: int, y2: int, count: int, skip_left: int = 0) -> list[tuple[int, int, int, int]]:
    width = (x2 - x1 - skip_left) / count
    boxes = []
    for i in range(count):
        left = int(x1 + skip_left + width * i)
        right = int(x1 + skip_left + width * (i + 1))
        boxes.append((left, y1, right, y2))
    return boxes


def write_sequence(seq_id: str, sheet: Image.Image, boxes: Iterable[tuple[int, int, int, int]], size: int, written: list[str], fps: int = 20, pad: int = 8) -> None:
    seq_path = SEQ_DIR / seq_id
    seq_path.mkdir(parents=True, exist_ok=True)
    frames = []
    images = []
    for idx, box in enumerate(boxes, 1):
        img = crop_vfx(sheet, box, (size, size), pad)
        frame_path = seq_path / f"{seq_id}_{idx:02d}.png"
        save_png(frame_path, img, written)
        frames.append(str(frame_path.relative_to(ROOT / "assets/production")))
        images.append(img)
    data = {
        "id": seq_id,
        "fps": fps,
        "frames": frames,
        "source": str((COMBAT_REF if sheet.size[0] == 1024 else UI_REF).relative_to(ROOT)),
        "integration": "cropped from owner-provided top-tier reference sheet; PNG bitmap sequence, no SVG/vector",
    }
    json_path = seq_path / f"{seq_id}_sequence.json"
    json_path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    written.append(str(json_path.relative_to(ROOT)))
    if images:
        save_png(VFX_DIR / f"{seq_id}.png", images[min(len(images) - 1, len(images) // 2)], written)


def write_ui_assets(ui_sheet: Image.Image, written: list[str]) -> None:
    assets: list[tuple[str, tuple[int, int, int, int], tuple[int, int], int]] = [
        ("ui_button_primary.png", (16, 15, 282, 88), (512, 160), 8),
        ("ui_modal_button_primary.png", (16, 15, 282, 88), (512, 160), 8),
        ("ui_button_secondary.png", (287, 15, 523, 88), (512, 160), 8),
        ("ui_modal_button_secondary.png", (287, 15, 523, 88), (512, 160), 8),
        ("ui_panel.png", (16, 14, 282, 88), (640, 420), 12),
        ("ui_panel_skin.png", (16, 14, 282, 88), (512, 512), 18),
        ("ui_plate_skin.png", (456, 105, 586, 184), (420, 150), 6),
        ("ui_pill_skin.png", (618, 286, 841, 342), (512, 128), 8),
        ("ui_resource_chip_skin.png", (457, 105, 585, 184), (512, 160), 6),
        ("ui_hint_strip.png", (334, 828, 590, 886), (840, 112), 6),
        ("ui_warning_strip.png", (590, 828, 854, 886), (840, 112), 6),
        ("ui_level_card_skin.png", (18, 828, 326, 886), (1024, 148), 6),
        ("ui_base_hp_bar.png", (42, 101, 402, 142), (720, 110), 4),
        ("ui_bar_fill_hp.png", (68, 110, 353, 134), (720, 110), 0),
        ("ui_shield_bar.png", (42, 151, 402, 192), (720, 110), 4),
        ("ui_run_xp_bar.png", (20, 253, 432, 302), (720, 110), 4),
        ("ui_wave_progress.png", (20, 253, 432, 302), (720, 110), 4),
        ("ui_bar_fill_xp.png", (35, 267, 390, 291), (720, 110), 0),
        ("ui_icon_frame.png", (570, 16, 640, 88), (220, 220), 8),
        ("ui_icon_frame_active.png", (674, 16, 746, 88), (220, 220), 8),
        ("ui_skill_slot.png", (496, 285, 554, 344), (220, 220), 6),
        ("ui_skill_slot_active.png", (557, 285, 617, 344), (220, 220), 6),
        ("ui_target_lock.png", (786, 323, 844, 382), (256, 256), 6),
        ("icon_pause.png", (458, 324, 516, 382), (256, 256), 6),
        ("icon_settings.png", (521, 324, 579, 382), (256, 256), 6),
        ("icon_currency_gold.png", (18, 287, 78, 348), (256, 256), 8),
        ("icon_currency_star.png", (607, 289, 666, 348), (256, 256), 8),
        ("icon_warning.png", (710, 326, 768, 384), (256, 256), 8),
        ("icon_lock.png", (654, 326, 712, 384), (256, 256), 8),
        ("ui_cd_overlay.png", (736, 1001, 806, 1075), (220, 220), 8),
        ("ui_combo_panel.png", (18, 828, 326, 886), (390, 128), 4),
        ("ui_damage_number_badge.png", (457, 215, 585, 270), (260, 100), 4),
        ("ui_star_filled.png", (610, 286, 670, 346), (256, 256), 8),
        ("ui_star_empty.png", (667, 286, 728, 346), (256, 256), 8),
    ]
    for name, box, size, pad in assets:
        save_png(UI_DIR / name, crop_ui(ui_sheet, box, size, pad), written)

    skill_boxes = [
        (17, 392, 113, 488),
        (127, 392, 223, 488),
        (238, 392, 334, 488),
        (349, 392, 445, 488),
        (459, 392, 555, 488),
        (570, 392, 666, 488),
        (681, 392, 777, 488),
        (789, 392, 858, 488),
    ]
    skill_names = [
        "skill_pierce_icon.png",
        "skill_tesla_icon.png",
        "skill_cryo_icon.png",
        "skill_venom_icon.png",
        "skill_ricochet_icon.png",
        "skill_homing_icon.png",
        "skill_barrier_icon.png",
        "skill_critical_icon.png",
        "skill_split_shot_icon.png",
        "skill_multishot_icon.png",
        "skill_salvo_icon.png",
        "skill_incendiary_icon.png",
        "skill_slow_field_icon.png",
        "skill_charge_shot_icon.png",
        "skill_recycle_icon.png",
        "skill_gold_rush_icon.png",
    ]
    for idx, name in enumerate(skill_names):
        box = skill_boxes[idx % len(skill_boxes)]
        save_png(UI_DIR / name, crop_ui(ui_sheet, box, (256, 256), 10), written)

    card_boxes = [
        (14, 504, 130, 690),
        (136, 504, 236, 690),
        (256, 504, 366, 690),
        (374, 504, 486, 690),
        (492, 504, 604, 690),
        (612, 504, 724, 690),
        (728, 504, 850, 690),
    ]
    card_name_boxes = {
        "ui_card_frame.png": card_boxes[0],
        "ui_card_frame_ice.png": card_boxes[1],
        "ui_card_frame_physical.png": card_boxes[2],
        "ui_card_frame_lightning.png": card_boxes[3],
        "ui_card_frame_poison.png": card_boxes[5],
        "ui_card_frame_fire.png": card_boxes[6],
    }
    for name, box in card_name_boxes.items():
        save_png(UI_DIR / name, crop_ui(ui_sheet, box, (360, 500), 6), written)


def write_sequences(ui_sheet: Image.Image, combat_sheet: Image.Image, written: list[str]) -> None:
    rows = {
        "ui_fire_muzzle": (ui_sheet, frame_boxes(0, 1052, 864, 1118, 6, 132), 512),
        "ui_lightning": (ui_sheet, frame_boxes(0, 1128, 864, 1206, 6, 132), 512),
        "ui_explosion": (ui_sheet, frame_boxes(0, 1245, 864, 1323, 6, 132), 512),
        "ui_ice": (ui_sheet, frame_boxes(0, 1350, 864, 1420, 6, 132), 512),
        "ui_poison": (ui_sheet, frame_boxes(0, 1458, 864, 1535, 6, 132), 512),
        "ui_target": (ui_sheet, frame_boxes(0, 1548, 864, 1608, 5, 90), 512),
        "ui_zombie_slash": (ui_sheet, frame_boxes(0, 1612, 864, 1700, 4, 0), 640),
        "ui_void": (ui_sheet, frame_boxes(0, 1708, 864, 1810, 4, 0), 512),
        "combat_fire": (combat_sheet, frame_boxes(0, 8, 1024, 300, 7, 0), 512),
        "combat_ice": (combat_sheet, frame_boxes(0, 320, 1024, 495, 7, 0), 512),
        "combat_lightning": (combat_sheet, frame_boxes(0, 500, 1024, 660, 7, 0), 512),
        "combat_poison": (combat_sheet, frame_boxes(0, 680, 1024, 835, 7, 0), 512),
        "combat_void": (combat_sheet, frame_boxes(0, 845, 1024, 995, 7, 0), 512),
        "combat_shield": (combat_sheet, frame_boxes(0, 990, 1024, 1110, 8, 0), 512),
        "combat_enemy": (combat_sheet, frame_boxes(0, 1115, 1024, 1295, 8, 0), 640),
        "combat_projectile": (combat_sheet, frame_boxes(0, 1298, 1024, 1518, 6, 0), 512),
    }
    mapping = {
        "vfx_muzzle_physical": "ui_fire_muzzle",
        "vfx_muzzle_fire": "ui_fire_muzzle",
        "vfx_muzzle_ice": "ui_ice",
        "vfx_muzzle_lightning": "ui_lightning",
        "vfx_muzzle_poison": "ui_poison",
        "vfx_hit_physical": "combat_fire",
        "vfx_hit_fire": "ui_explosion",
        "vfx_hit_ice": "combat_ice",
        "vfx_hit_lightning": "combat_lightning",
        "vfx_hit_poison": "combat_poison",
        "vfx_hit_immune": "combat_shield",
        "vfx_explosion_fire": "ui_explosion",
        "vfx_freeze": "ui_ice",
        "vfx_chain_lightning": "ui_lightning",
        "vfx_poison_cloud": "ui_poison",
        "vfx_crit": "ui_target",
        "vfx_target_lock": "ui_target",
        "vfx_threat_warning": "ui_target",
        "vfx_levelup_glow": "combat_fire",
        "vfx_boss_phase": "ui_void",
        "vfx_death_dissolve": "combat_enemy",
        "vfx_enemy_skill_runner_dash": "ui_zombie_slash",
        "vfx_enemy_skill_leap_strike": "ui_zombie_slash",
        "vfx_enemy_skill_charge": "combat_enemy",
        "vfx_enemy_skill_juggernaut": "combat_enemy",
        "vfx_enemy_skill_armor": "combat_shield",
        "vfx_enemy_skill_armor_break": "combat_shield",
        "vfx_enemy_skill_shield_aura": "combat_shield",
        "vfx_enemy_skill_ward": "combat_shield",
        "vfx_enemy_skill_toxic_cloud": "ui_poison",
        "vfx_enemy_skill_ranged_spit": "ui_poison",
        "vfx_enemy_skill_corrosion": "combat_poison",
        "vfx_enemy_skill_regenerate": "combat_poison",
        "vfx_enemy_skill_regen": "combat_poison",
        "vfx_enemy_skill_buff_aura": "combat_void",
        "vfx_enemy_skill_mutate": "combat_void",
        "vfx_enemy_skill_enrage": "ui_explosion",
        "vfx_enemy_skill_summon": "combat_void",
        "vfx_enemy_skill_spawn_minions": "combat_enemy",
        "vfx_enemy_skill_phase": "ui_void",
        "vfx_enemy_skill_phase_shift": "ui_void",
        "vfx_enemy_skill_multi_phase": "ui_void",
        "vfx_enemy_skill_explode_on_death": "ui_explosion",
        "vfx_enemy_skill_blast": "ui_explosion",
        "vfx_enemy_skill_phase_burn": "ui_explosion",
        "vfx_enemy_skill_freeze_field": "combat_ice",
        "vfx_enemy_skill_storm_chain": "ui_lightning",
        "vfx_enemy_skill_support_strike": "ui_target",
        "vfx_active_sig_vanguard_railvolley": "ui_fire_muzzle",
        "vfx_active_sig_vanguard_overload": "combat_fire",
        "vfx_active_sig_blaze_meltdown": "ui_explosion",
        "vfx_active_sig_frost_glacier": "combat_ice",
        "vfx_active_sig_volt_storm": "ui_lightning",
        "vfx_skill_cast_split_shot": "ui_fire_muzzle",
        "vfx_skill_cast_pierce": "ui_fire_muzzle",
        "vfx_skill_cast_multishot": "ui_fire_muzzle",
        "vfx_skill_cast_slow_field": "combat_ice",
        "vfx_skill_cast_homing": "ui_target",
        "vfx_skill_cast_critical": "ui_target",
        "vfx_skill_cast_barrier": "combat_shield",
        "vfx_skill_cast_gold_rush": "combat_fire",
        "vfx_skill_cast_ricochet": "ui_lightning",
        "vfx_skill_cast_salvo": "ui_fire_muzzle",
        "vfx_skill_cast_incendiary": "ui_explosion",
        "vfx_skill_cast_cryo": "ui_ice",
        "vfx_skill_cast_tesla": "ui_lightning",
        "vfx_skill_cast_venom": "ui_poison",
        "vfx_skill_cast_charge_shot": "ui_fire_muzzle",
        "vfx_skill_cast_recycle": "ui_target",
    }
    for seq_id, row_key in mapping.items():
        sheet, boxes, base_size = rows[row_key]
        size = 768 if seq_id.startswith("vfx_active_") else 640 if seq_id.startswith("vfx_enemy_skill_") else base_size
        write_sequence(seq_id, sheet, boxes, size, written, fps=20, pad=10)

    save_png(VFX_DIR / "vfx_slow_field_band.png", crop_vfx(ui_sheet, (0, 1332, 864, 1418), (1080, 360), 8), written)
    save_png(VFX_DIR / "vfx_barrier_glass.png", crop_ui(ui_sheet, (18, 828, 326, 886), (960, 260), 6), written)


def contact_sheet(paths: list[Path], out_path: Path, title: str, thumb: tuple[int, int] = (120, 120), cols: int = 6) -> None:
    rows = math.ceil(len(paths) / cols)
    header_h = 44
    cell_w = thumb[0] + 18
    cell_h = thumb[1] + 38
    sheet = Image.new("RGB", (cols * cell_w + 18, rows * cell_h + header_h + 18), (12, 16, 21))
    draw = ImageDraw.Draw(sheet)
    draw.text((16, 14), title, fill=(236, 240, 230))
    for i, path in enumerate(paths):
        try:
            im = Image.open(path).convert("RGBA")
        except Exception:
            continue
        preview = fit_canvas(im, thumb, 4)
        x = 12 + (i % cols) * cell_w
        y = header_h + (i // cols) * cell_h
        bg = Image.new("RGBA", (thumb[0], thumb[1]), (20, 25, 32, 255))
        bg.alpha_composite(preview)
        sheet.paste(bg.convert("RGB"), (x, y))
        draw.text((x, y + thumb[1] + 4), path.name[:22], fill=(190, 198, 206))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_path)


def update_index(written: list[str]) -> None:
    index = {}
    if INDEX_PATH.exists():
        index = json.loads(INDEX_PATH.read_text())
    index["owner_reference_sheet_final_ui_vfx_pass_2026_07_02"] = {
        "status": "accepted",
        "source": [
            str(UI_REF.relative_to(ROOT)),
            str(COMBAT_REF.relative_to(ROOT)),
        ],
        "paths": written,
        "quality_bar": "owner-provided top-tier rendered UI/VFX reference sheets; PNG bitmap assets only; no SVG/vector",
        "notes": "Directly cropped and integrated from the two owner reference sheets after review feedback that previous generated assets still read as vector/procedural in runtime.",
    }
    INDEX_PATH.write_text(json.dumps(index, indent=2, ensure_ascii=False) + "\n")


def main() -> None:
    ui_ref, combat_ref = copy_refs()
    ui_sheet = Image.open(ui_ref).convert("RGB")
    combat_sheet = Image.open(combat_ref).convert("RGB")
    written: list[str] = []
    write_ui_assets(ui_sheet, written)
    write_sequences(ui_sheet, combat_sheet, written)

    ui_preview_paths = [
        UI_DIR / "ui_button_primary.png",
        UI_DIR / "ui_base_hp_bar.png",
        UI_DIR / "ui_run_xp_bar.png",
        UI_DIR / "skill_tesla_icon.png",
        UI_DIR / "skill_cryo_icon.png",
        UI_DIR / "skill_venom_icon.png",
        UI_DIR / "ui_card_frame_fire.png",
        UI_DIR / "ui_card_frame_ice.png",
        UI_DIR / "ui_target_lock.png",
        UI_DIR / "icon_pause.png",
    ]
    vfx_preview_paths = [
        VFX_DIR / "vfx_muzzle_fire.png",
        VFX_DIR / "vfx_hit_fire.png",
        VFX_DIR / "vfx_hit_ice.png",
        VFX_DIR / "vfx_hit_lightning.png",
        VFX_DIR / "vfx_hit_poison.png",
        VFX_DIR / "vfx_enemy_skill_runner_dash.png",
        VFX_DIR / "vfx_enemy_skill_juggernaut.png",
        VFX_DIR / "vfx_active_sig_blaze_meltdown.png",
        VFX_DIR / "vfx_active_sig_frost_glacier.png",
        VFX_DIR / "vfx_active_sig_volt_storm.png",
    ]
    contact_sheet(ui_preview_paths, CONTACT_DIR / f"contact_owner_reference_ui_actual_{STAMP}.png", "Owner Reference UI Assets")
    contact_sheet(vfx_preview_paths, CONTACT_DIR / f"contact_owner_reference_vfx_actual_{STAMP}.png", "Owner Reference VFX Assets")
    written.extend([
        str((CONTACT_DIR / f"contact_owner_reference_ui_actual_{STAMP}.png").relative_to(ROOT)),
        str((CONTACT_DIR / f"contact_owner_reference_vfx_actual_{STAMP}.png").relative_to(ROOT)),
        str(UI_REF.relative_to(ROOT)),
        str(COMBAT_REF.relative_to(ROOT)),
    ])
    spec_path = SOURCE_DIR / f"owner_reference_sheet_final_ui_vfx_spec_{STAMP}.json"
    spec_path.write_text(json.dumps({
        "id": "owner_reference_sheet_final_ui_vfx_pass",
        "source_refs": [str(UI_REF.relative_to(ROOT)), str(COMBAT_REF.relative_to(ROOT))],
        "written_count": len(written),
        "written": written,
    }, indent=2, ensure_ascii=False) + "\n")
    written.append(str(spec_path.relative_to(ROOT)))
    update_index(written)
    print(f"Integrated owner reference sheets: {len(written)} files")


if __name__ == "__main__":
    main()
