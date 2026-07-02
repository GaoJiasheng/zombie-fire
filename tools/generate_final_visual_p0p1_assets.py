#!/usr/bin/env python3
from __future__ import annotations

import json
import math
import shutil
import subprocess
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

from generate_map_ui_line_polish import (
    CONTACT_DIR,
    INDEX_PATH,
    PROD,
    ROOT,
    SOURCE_DIR,
    UI_DIR,
    accent_strip,
    add_noise,
    coin_badge,
    gradient,
    masked,
    pill,
    premium_button,
    radial,
    rounded_mask,
    save,
    soft_panel,
    star_badge,
    star_currency_badge,
)


STAMP = "2026_07_02"
REFERENCE_SOURCE = Path(
    "/Users/gavin/.codex/generated_images/019f1c90-6388-7e23-89ec-5759e03c6022/"
    "ig_099cbf466c26cc2e016a46233b134081918208fbd6863fed5d.png"
)
SOURCE_ROOT = PROD / "source_refs"
GENERATED_SOURCE_DIR = SOURCE_ROOT / "generated"
VFX_ROOT = PROD / "sprites" / "vfx_sequences"
VIDEO_DIR = PROD / "video"
FFMPEG = "/opt/homebrew/bin/ffmpeg"
FFPROBE = "/opt/homebrew/bin/ffprobe"


def _alpha_paste(base: Image.Image, layer: Image.Image, pos: tuple[int, int] = (0, 0)) -> None:
    base.alpha_composite(layer.convert("RGBA"), pos)


def _rail(size: tuple[int, int], accent: tuple[int, int, int], warn: bool = False) -> Image.Image:
    w, h = size
    img = soft_panel(size, max(14, h // 3), "orange" if warn else "cyan")
    draw = ImageDraw.Draw(img, "RGBA")
    groove = (24, max(12, h // 3), w - 25, h - max(13, h // 4))
    draw.rounded_rectangle(groove, radius=max(8, (groove[3] - groove[1]) // 2), fill=(3, 7, 11, 215))
    draw.rounded_rectangle(groove, radius=max(8, (groove[3] - groove[1]) // 2), outline=(*accent, 120), width=2)
    for i in range(7):
        x = groove[0] + 32 + i * max(28, (groove[2] - groove[0] - 64) // 7)
        draw.line((x, groove[1] + 3, x + 18, groove[3] - 3), fill=(255, 255, 255, 12), width=1)
    _alpha_paste(img, radial(size, (w * 0.78, h * 0.22), (*accent, 54), max(w, h) * 0.42))
    return add_noise(img, 4, 8)


def _fill(size: tuple[int, int], left: tuple[int, int, int], right: tuple[int, int, int]) -> Image.Image:
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    mask = rounded_mask(size, (8, 8, w - 9, h - 9), max(7, h // 3))
    body = gradient(size, (*left, 245), (*right, 238))
    _alpha_paste(body, radial(size, (w * 0.18, h * 0.25), (255, 255, 255, 64), max(w, h) * 0.24))
    _alpha_paste(body, radial(size, (w * 0.84, h * 0.55), (*right, 70), max(w, h) * 0.32))
    img.alpha_composite(masked(size, mask, add_noise(body, 5, 12)))
    glow = img.filter(ImageFilter.GaussianBlur(5))
    glow.putalpha(glow.getchannel("A").point(lambda v: int(v * 0.32)))
    out = Image.alpha_composite(glow, img)
    draw = ImageDraw.Draw(out, "RGBA")
    draw.line((18, h * 0.35, w - 20, h * 0.35), fill=(255, 255, 255, 80), width=2)
    return out


def _square_slot(size: tuple[int, int], active: bool = False, empty: bool = False) -> Image.Image:
    glow = "orange" if active else "cyan"
    img = soft_panel(size, max(20, size[0] // 7), glow, locked=empty)
    w, h = size
    draw = ImageDraw.Draw(img, "RGBA")
    inner = (w * 0.24, h * 0.24, w * 0.76, h * 0.76)
    if empty:
        draw.rounded_rectangle(inner, radius=18, outline=(88, 114, 126, 72), width=3)
        draw.rounded_rectangle((inner[0] + 18, inner[1] + 18, inner[2] - 18, inner[3] - 18), radius=12, fill=(0, 0, 0, 44))
    else:
        _alpha_paste(img, radial(size, (w * 0.50, h * 0.50), (255, 164, 50, 54) if active else (78, 214, 232, 48), w * 0.36))
    return img


def _panel_skin(size: tuple[int, int], accent: str = "cyan") -> Image.Image:
    img = soft_panel(size, 22, accent)
    w, h = size
    draw = ImageDraw.Draw(img, "RGBA")
    for y in range(54, h - 40, 48):
        draw.line((44, y, w - 48, y), fill=(255, 255, 255, 10), width=1)
    _alpha_paste(img, radial(size, (w * 0.78, h * 0.20), (60, 218, 236, 34), w * 0.32))
    _alpha_paste(img, radial(size, (w * 0.18, h * 0.82), (248, 142, 34, 30), w * 0.34))
    return img


def _reward_card(size: tuple[int, int], gold: bool) -> Image.Image:
    img = soft_panel(size, 20, "orange" if gold else "cyan")
    w, h = size
    color = (246, 158, 44) if gold else (76, 210, 232)
    _alpha_paste(img, radial(size, (w * 0.22, h * 0.36), (*color, 74), w * 0.34))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.rounded_rectangle((22, 22, w - 23, h - 24), radius=16, outline=(*color, 86), width=2)
    return img


def _contact_sheet(paths: list[Path], out: Path, title: str, thumb: tuple[int, int] = (260, 130), cols: int = 3) -> Path:
    out.parent.mkdir(parents=True, exist_ok=True)
    rows = math.ceil(len(paths) / cols)
    card_w, card_h = thumb[0] + 42, thumb[1] + 72
    gap = 18
    margin = 28
    header = 52
    sheet = Image.new("RGBA", (margin * 2 + cols * card_w + (cols - 1) * gap, header + margin * 2 + rows * card_h + max(0, rows - 1) * gap), (9, 14, 20, 255))
    draw = ImageDraw.Draw(sheet, "RGBA")
    draw.text((margin, 20), title, fill=(230, 236, 240, 255))
    for idx, path in enumerate(paths):
        x = margin + (idx % cols) * (card_w + gap)
        y = header + margin + (idx // cols) * (card_h + gap)
        draw.rounded_rectangle((x, y, x + card_w, y + card_h), radius=10, fill=(15, 23, 31, 255), outline=(80, 105, 118, 210), width=1)
        try:
            img = Image.open(path).convert("RGBA")
        except Exception:
            continue
        img.thumbnail(thumb, Image.Resampling.LANCZOS)
        px = x + (card_w - img.width) // 2
        py = y + 18 + (thumb[1] - img.height) // 2
        sheet.alpha_composite(img, (px, py))
        rel = str(path.relative_to(ROOT)) if path.is_relative_to(ROOT) else path.name
        if len(rel) > 42:
            rel = "..." + rel[-39:]
        draw.text((x + 16, y + thumb[1] + 34), rel, fill=(190, 205, 214, 255))
    sheet.convert("RGB").save(out)
    return out


def _write_ui_skins() -> list[str]:
    outputs: dict[str, Image.Image] = {
        "ui_base_hp_bar.png": _rail((720, 110), (235, 62, 54), True),
        "ui_wave_progress.png": _rail((720, 110), (74, 206, 232), False),
        "ui_run_xp_bar.png": _rail((720, 110), (86, 224, 164), False),
        "ui_boss_hp_bar.png": _rail((900, 92), (235, 62, 54), True),
        "ui_bar_fill_hp.png": _fill((720, 58), (255, 76, 58), (172, 18, 22)),
        "ui_bar_fill_xp.png": _fill((720, 58), (88, 228, 178), (24, 124, 204)),
        "ui_bar_fill_wave.png": _fill((720, 58), (76, 210, 232), (38, 112, 226)),
        "ui_button_primary.png": premium_button((512, 160), True),
        "ui_button_secondary.png": premium_button((512, 160), False),
        "ui_modal_button_primary.png": premium_button((512, 160), True),
        "ui_modal_button_secondary.png": premium_button((512, 160), False),
        "ui_panel.png": _panel_skin((640, 420), "orange"),
        "ui_panel_skin.png": _panel_skin((512, 512), "cyan"),
        "ui_resource_chip_skin.png": soft_panel((512, 150), 22, "orange"),
        "ui_map_level_card_skin.png": soft_panel((1024, 156), 22, "cyan"),
        "ui_map_level_card_locked_skin.png": soft_panel((1024, 156), 22, "cyan", True),
        "ui_map_nav_card_skin.png": soft_panel((320, 142), 18, "cyan"),
        "ui_map_resource_chip_skin.png": soft_panel((512, 150), 22, "orange"),
        "ui_map_pill_skin.png": pill((320, 74)),
        "ui_map_index_plate_skin.png": soft_panel((140, 104), 18, "cyan"),
        "ui_map_deploy_pill_skin.png": pill((300, 72)),
        "ui_map_accent_strip.png": accent_strip((26, 118)),
        "ui_icon_frame.png": _square_slot((220, 220)),
        "ui_icon_frame_active.png": _square_slot((220, 220), True),
        "ui_skill_slot.png": _square_slot((220, 220)),
        "ui_skill_slot_active.png": _square_slot((220, 220), True),
        "ui_empty_equipment_socket.png": _square_slot((220, 220), False, True),
        "ui_hint_strip.png": soft_panel((840, 112), 18, "cyan"),
        "ui_warning_strip.png": soft_panel((840, 112), 18, "orange"),
        "ui_collection_card_skin.png": soft_panel((900, 236), 22, "cyan"),
        "ui_collection_skill_card_skin.png": soft_panel((900, 190), 20, "cyan"),
        "ui_result_panel_final.png": _panel_skin((920, 380), "orange"),
        "ui_result_reward_card_gold.png": _reward_card((512, 160), True),
        "ui_result_reward_card_xp.png": _reward_card((512, 160), False),
        "ui_cd_overlay.png": _fill((220, 220), (80, 160, 196), (14, 35, 54)).filter(ImageFilter.GaussianBlur(0.6)),
        "icon_currency_gold.png": coin_badge(),
        "icon_currency_star.png": star_currency_badge(),
        "ui_star_filled.png": star_badge(True),
        "ui_star_empty.png": star_badge(False),
    }
    written: list[str] = []
    paths: list[Path] = []
    for name, img in outputs.items():
        path = UI_DIR / name
        written.append(save(path, img))
        paths.append(path)
    _contact_sheet(paths, CONTACT_DIR / f"contact_final_visual_p0p1_ui_{STAMP}.png", "Final P0/P1 Raster UI Skins", (260, 130), 3)
    return written


def _copy_model_reference() -> str | None:
    GENERATED_SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    if not REFERENCE_SOURCE.exists():
        return None
    dest = GENERATED_SOURCE_DIR / f"final_visual_p0p1_reference_{STAMP}.png"
    shutil.copyfile(REFERENCE_SOURCE, dest)
    return str(dest.relative_to(PROD))


def _source_reference_sheets() -> list[str]:
    SOURCE_ROOT.mkdir(parents=True, exist_ok=True)
    hero_paths = sorted((PROD / "sprites/animations/characters_weaponless").glob("*/**/*_attack_01.png"))
    weapon_paths = sorted((PROD / "sprites/weapons/handheld").glob("*.png"))
    combo_paths = sorted((PROD / "sprites/animations/character_weapon_combos").glob("*/**/*_attack_01.png"))
    hero_sheet = _contact_sheet(hero_paths, SOURCE_ROOT / "hero_battle_pose_sheet.png", "Hero Battle Pose Source Sheet", (210, 210), 4)
    weapon_sheet = _contact_sheet(weapon_paths, SOURCE_ROOT / "handheld_weapon_sheet.png", "Handheld Weapon Source Sheet", (250, 150), 4)
    matrix = _contact_sheet(combo_paths, GENERATED_SOURCE_DIR / "character_weapon_combo_matrix.png", "Character Weapon Combo Matrix", (170, 170), 8)

    manifest = {
        "stamp": STAMP,
        "intent": "Source traceability manifest for fused character/weapon animation frames used by battle firing poses.",
        "combo_frame_count": len(sorted((PROD / "sprites/animations/character_weapon_combos").glob("*/**/*.png"))),
        "characters": sorted(p.name for p in (PROD / "sprites/animations/character_weapon_combos").iterdir() if p.is_dir()),
        "sample_matrix": str(matrix.relative_to(PROD)),
        "source_sheets": [
            str(hero_sheet.relative_to(PROD)),
            str(weapon_sheet.relative_to(PROD)),
        ],
    }
    manifest_path = GENERATED_SOURCE_DIR / "character_weapon_combo_generation_manifest.json"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return [
        str(hero_sheet.relative_to(ROOT)),
        str(weapon_sheet.relative_to(ROOT)),
        str(matrix.relative_to(ROOT)),
        str(manifest_path.relative_to(ROOT)),
    ]


def _repair_empty_vfx_frames() -> list[str]:
    repaired: list[str] = []
    if not VFX_ROOT.exists():
        return repaired
    for directory in sorted(path for path in VFX_ROOT.iterdir() if path.is_dir()):
        frames = sorted(directory.glob("*.png"))
        if not frames:
            continue
        visible_cache: dict[Path, Image.Image] = {}
        for path in frames:
            with Image.open(path) as src:
                img = src.convert("RGBA")
            if img.getchannel("A").getbbox() is not None:
                visible_cache[path] = img
        if not visible_cache:
            continue
        visible_paths = list(visible_cache.keys())
        for index, path in enumerate(frames):
            with Image.open(path) as src:
                current = src.convert("RGBA")
            if current.getchannel("A").getbbox() is not None:
                continue
            donor: Image.Image | None = None
            for prev in reversed(frames[:index]):
                if prev in visible_cache:
                    donor = visible_cache[prev]
                    break
            if donor is None:
                for nxt in frames[index + 1 :]:
                    if nxt in visible_cache:
                        donor = visible_cache[nxt]
                        break
            if donor is None:
                donor = visible_cache[visible_paths[0]]
            residue = donor.copy().filter(ImageFilter.GaussianBlur(1.8))
            alpha = residue.getchannel("A").point(lambda value: int(value * 0.20))
            residue.putalpha(alpha)
            spark = Image.new("RGBA", residue.size, (0, 0, 0, 0))
            draw = ImageDraw.Draw(spark, "RGBA")
            w, h = residue.size
            for n in range(18):
                x = int(w * (0.18 + 0.64 * ((n * 37) % 100) / 100.0))
                y = int(h * (0.20 + 0.58 * ((n * 53) % 100) / 100.0))
                draw.ellipse((x - 1, y - 1, x + 2, y + 2), fill=(255, 176, 64, 36))
            residue.alpha_composite(spark.filter(ImageFilter.GaussianBlur(0.4)))
            residue.save(path)
            repaired.append(str(path.relative_to(ROOT)))
    return repaired


def _duration(path: Path) -> float:
    try:
        out = subprocess.check_output(
            [FFPROBE, "-v", "error", "-show_entries", "format=duration", "-of", "default=nk=1:nw=1", str(path)],
            text=True,
        ).strip()
        return float(out)
    except Exception:
        return 0.0


def _video_source(path: Path) -> Path:
    name = path.stem
    if "boss_intro_" in name:
        boss_id = name.replace("vid_boss_intro_", "boss_")
        candidate = PROD / "sprites/bosses" / f"{boss_id}_portrait.png"
        if candidate.exists():
            return candidate
    chapter_map = {
        "vid_chapter_city_ruins": "bg_city_ruins_portrait.png",
        "vid_chapter_biolab": "bg_toxic_biolab_portrait.png",
        "vid_chapter_military": "bg_military_portrait.png",
        "vid_chapter_subway": "bg_flooded_subway_portrait.png",
    }
    if name in chapter_map:
        candidate = PROD / "environment" / chapter_map[name]
        if candidate.exists():
            return candidate
    if name == "vid_intro_opening":
        return ROOT / "assets/app/launch_1080x1920.png"
    if name == "vid_ending":
        candidate = PROD / "environment/bg_apex_core_portrait.png"
        if candidate.exists():
            return candidate
    return ROOT / "assets/app/launch_1080x1920.png"


def _refresh_short_videos() -> list[str]:
    touched: list[str] = []
    if not Path(FFMPEG).exists() or not Path(FFPROBE).exists():
        return touched
    for path in sorted(VIDEO_DIR.glob("*.mp4")):
        if path.name == "vid_app_preview.mp4":
            continue
        if _duration(path) > 2.25:
            continue
        source = _video_source(path)
        if not source.exists():
            continue
        filt = (
            "scale=1242:2208:force_original_aspect_ratio=increase,"
            "crop=1080:1920,setsar=1,format=yuv420p,"
            "fade=t=in:st=0:d=0.35,fade=t=out:st=5.65:d=0.35"
        )
        cmd = [
            FFMPEG,
            "-y",
            "-loop",
            "1",
            "-i",
            str(source),
            "-t",
            "6",
            "-vf",
            filt,
            "-c:v",
            "libx264",
            "-preset",
            "medium",
            "-crf",
            "18",
            "-pix_fmt",
            "yuv420p",
            "-movflags",
            "+faststart",
            str(path),
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        touched.append(str(path.relative_to(ROOT)))
    return touched


def _write_spec(ui_paths: list[str], source_paths: list[str], ref_path: str | None, repaired_vfx: list[str], videos: list[str]) -> Path:
    spec = {
        "stamp": STAMP,
        "intent": "P0/P1 final visual pass: replace primitive UI linework with raster skins, restore source traceability, remove empty VFX tail frames, and replace 2-second placeholder videos.",
        "model_reference": ref_path,
        "outputs": {
            "ui": ui_paths,
            "source_refs": source_paths,
            "repaired_vfx_empty_frames": repaired_vfx,
            "refreshed_videos": videos,
        },
        "quality_bar": [
            "No SVG/vector assets emitted.",
            "Generated skins are raster PNG with metal/glass texture, bevels, light bloom, and noise.",
            "Gameplay IDs, JSON data, scene flow, and asset paths are preserved.",
        ],
    }
    spec_path = GENERATED_SOURCE_DIR / f"final_visual_p0p1_asset_spec_{STAMP}.json"
    spec_path.write_text(json.dumps(spec, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return spec_path


def _update_index(spec_path: Path, ui_paths: list[str], videos: list[str], repaired_vfx: list[str]) -> None:
    data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
    overrides = data.setdefault("owner_directed_generated_overrides", [])
    entry = {
        "path": "sprites/ui + sprites/vfx_sequences + video",
        "source": str(spec_path.relative_to(PROD)),
        "derived": f"contact_sheets/contact_final_visual_p0p1_ui_{STAMP}.png",
        "reason": "Owner approved simultaneous P0/P1 final visual pass to remove remaining primitive UI geometry, empty VFX frames, and 2-second placeholder videos while preserving runtime paths.",
    }
    if entry not in overrides:
        overrides.append(entry)
    data[f"final_visual_p0p1_{STAMP}"] = {
        "status": "integrated",
        "paths": ui_paths,
        "videos": videos,
        "repaired_vfx_empty_frames": repaired_vfx,
        "quality_bar": "Raster PNG/MP4 replacements only; no SVG/vector outputs; existing IDs and paths preserved.",
    }
    data.setdefault("counts", {})["total_files"] = sum(1 for p in PROD.rglob("*") if p.is_file())
    data["counts"]["video_files"] = sum(1 for p in VIDEO_DIR.glob("*.mp4") if p.is_file())
    INDEX_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    GENERATED_SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    CONTACT_DIR.mkdir(parents=True, exist_ok=True)
    ui_paths = _write_ui_skins()
    ref_path = _copy_model_reference()
    source_paths = _source_reference_sheets()
    repaired_vfx = _repair_empty_vfx_frames()
    videos = _refresh_short_videos()
    spec_path = _write_spec(ui_paths, source_paths, ref_path, repaired_vfx, videos)
    _update_index(spec_path, ui_paths, videos, repaired_vfx)
    print(f"Generated/updated UI skins: {len(ui_paths)}")
    print(f"Source refs: {len(source_paths)}")
    print(f"Repaired empty VFX frames: {len(repaired_vfx)}")
    print(f"Refreshed short videos: {len(videos)}")
    print(spec_path.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
