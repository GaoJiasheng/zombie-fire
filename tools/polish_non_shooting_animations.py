#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / "assets" / "production"
ANIM_ROOT = PROD / "sprites" / "animations"
SOURCE_DIR = PROD / "source_refs" / "generated"
CONTACT_DIR = PROD / "contact_sheets"
SPEC_PATH = SOURCE_DIR / "non_shooting_animation_polish_spec_2026_07_01.json"
CONTACT_PATH = CONTACT_DIR / "contact_non_shooting_animation_polish_2026_07_01.png"

TARGET_ROOTS = [
    ANIM_ROOT / "characters",
    ANIM_ROOT / "characters_weaponless",
    ANIM_ROOT / "zombies",
    ANIM_ROOT / "bosses",
    ANIM_ROOT / "pets",
    ANIM_ROOT / "weapons",
]

LOW_ALPHA_THRESHOLD = {
    "hurt": 18,
    "death": 12,
    "special": 10,
    "attack": 10,
    "walk": 8,
    "idle": 8,
    "recoil": 8,
}


def load_font(size: int) -> ImageFont.ImageFont:
    for path in (
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
    ):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def action_from_path(path: Path) -> str:
    parts = path.stem.split("_")
    if len(parts) >= 2 and parts[-1].isdigit():
        return parts[-2]
    return "unknown"


def asset_id_from_path(path: Path) -> str:
    return path.parent.name


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    return image.getchannel("A").getbbox()


def clear_border(image: Image.Image, margin: int) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    for y in range(height):
        for x in range(width):
            if x < margin or y < margin or x >= width - margin or y >= height - margin:
                r, g, b, _a = pixels[x, y]
                pixels[x, y] = (r, g, b, 0)
    return image


def trim_low_alpha(image: Image.Image, threshold: int) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a < threshold:
                pixels[x, y] = (r, g, b, 0)
    return image


def fit_if_clipped(image: Image.Image, min_margin: int = 8) -> Image.Image:
    bbox = alpha_bbox(image)
    if bbox is None:
        return image
    width, height = image.size
    left, top, right, bottom = bbox
    current_margin = min(left, top, width - right, height - bottom)
    if current_margin >= min_margin:
        return image

    crop_pad = 4
    cropped = image.crop(
        (
            max(0, left - crop_pad),
            max(0, top - crop_pad),
            min(width, right + crop_pad),
            min(height, bottom + crop_pad),
        )
    )
    scale = min((width - min_margin * 2) / max(1, cropped.width), (height - min_margin * 2) / max(1, cropped.height), 1.0)
    resized = cropped.resize((max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale))), Image.Resampling.LANCZOS)
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    target_bottom = min(height - min_margin, max(min_margin + resized.height, bottom))
    x = max(min_margin, min(width - resized.width - min_margin, (width - resized.width) // 2))
    y = max(min_margin, min(height - resized.height - min_margin, target_bottom - resized.height))
    out.alpha_composite(resized, (x, y))
    return out


def enhance_material(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    rgb = image.convert("RGB")
    rgb = ImageEnhance.Contrast(rgb).enhance(1.045)
    rgb = ImageEnhance.Color(rgb).enhance(1.025)
    rgb = ImageEnhance.Sharpness(rgb).enhance(1.10)
    image = Image.merge("RGBA", (*rgb.split(), alpha))

    contracted = alpha.filter(ImageFilter.MinFilter(3))
    edge = ImageChops.subtract(alpha, contracted).filter(ImageFilter.GaussianBlur(0.8))
    edge_rgba = Image.new("RGBA", image.size, (255, 235, 198, 0))
    edge_rgba.putalpha(edge.point(lambda v: min(24, int(v * 0.16))))
    return Image.alpha_composite(image, edge_rgba)


def polish_frame(path: Path) -> dict[str, object]:
    action = action_from_path(path)
    before = Image.open(path).convert("RGBA")
    before_bbox = alpha_bbox(before)
    threshold = LOW_ALPHA_THRESHOLD.get(action, 8)

    after = trim_low_alpha(before, threshold)
    after = clear_border(after, 4)
    after = fit_if_clipped(after, 8)
    after = enhance_material(after)
    after = clear_border(after, 4)
    after.save(path, optimize=True)

    after_bbox = alpha_bbox(after)
    return {
        "path": str(path.relative_to(ROOT)),
        "asset_id": asset_id_from_path(path),
        "action": action,
        "size": list(after.size),
        "low_alpha_threshold": threshold,
        "before_bbox": list(before_bbox) if before_bbox else None,
        "after_bbox": list(after_bbox) if after_bbox else None,
    }


def build_contact(rows: list[dict[str, object]]) -> None:
    picks: list[Path] = []
    for root in TARGET_ROOTS:
        files = sorted(root.rglob("*.png"))
        by_action: dict[str, list[Path]] = {}
        for path in files:
            by_action.setdefault(action_from_path(path), []).append(path)
        for action in ("idle", "walk", "attack", "special", "hurt", "death", "recoil"):
            picks.extend(by_action.get(action, [])[:8])
    picks = picks[:96]

    thumb = 112
    label_h = 30
    cols = 12
    rows_count = (len(picks) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * thumb, rows_count * (thumb + label_h)), (13, 18, 24))
    draw = ImageDraw.Draw(sheet)
    font = load_font(10)
    for i, path in enumerate(picks):
        image = Image.open(path).convert("RGBA")
        tile = Image.new("RGBA", image.size, (28, 34, 42, 255))
        tile.alpha_composite(image)
        tile = ImageOps.contain(tile.convert("RGB"), (thumb, thumb), Image.Resampling.LANCZOS)
        base_x = (i % cols) * thumb
        base_y = (i // cols) * (thumb + label_h)
        x = base_x + (thumb - tile.width) // 2
        y = base_y + (thumb - tile.height) // 2
        sheet.paste(tile, (x, y))
        label = f"{path.parent.name[-8:]}_{action_from_path(path)}"
        draw.text((base_x + 4, base_y + thumb + 4), label[:20], fill=(225, 231, 237), font=font)
    CONTACT_DIR.mkdir(parents=True, exist_ok=True)
    sheet.save(CONTACT_PATH, quality=95)


def update_index() -> None:
    index_path = PROD / "OUTSOURCER_ASSET_INDEX.json"
    data = json.loads(index_path.read_text(encoding="utf-8"))
    source_ref = "source_refs/generated/non_shooting_animation_polish_spec_2026_07_01.json"
    data.setdefault("owner_directed_generated_overrides", [])
    data["owner_directed_generated_overrides"] = [
        item
        for item in data["owner_directed_generated_overrides"]
        if not (item.get("path") == "sprites/animations/non_shooting" and item.get("source") == source_ref)
    ]
    data["owner_directed_generated_overrides"].append(
        {
            "path": "sprites/animations/non_shooting",
            "source": source_ref,
            "derived": "contact_sheets/contact_non_shooting_animation_polish_2026_07_01.png",
            "reason": "Owner requested remaining prototype-feeling assets to be raised toward top-tier rendered App Store quality with no SVG/vector placeholders; non-shooting animation frames were alpha-cleaned, clipped-frame guarded, and material-polished while skipping the already regenerated character/weapon firing combos.",
        }
    )
    counts = data.setdefault("counts", {})
    counts["animation_files"] = len(list((PROD / "sprites" / "animations").rglob("*.png")))
    counts["total_files"] = len([p for p in PROD.rglob("*") if p.is_file() and not p.name.endswith(".import")])
    index_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    rows: list[dict[str, object]] = []
    for root in TARGET_ROOTS:
        if not root.exists():
            continue
        for path in sorted(root.rglob("*.png")):
            rows.append(polish_frame(path))

    build_contact(rows)
    spec = {
        "id": "non_shooting_animation_polish_2026_07_01",
        "generated_by": "tools/polish_non_shooting_animations.py",
        "quality_target": "Top-tier raster cleanup for non-shooting animation frames; no SVG/vector placeholder treatment.",
        "excluded": [
            "assets/production/sprites/animations/character_weapon_combos/**",
        ],
        "preserved_contracts": [
            "Animation filenames, directories, frame counts, and canvas sizes are unchanged.",
            "No data/*.json gameplay content, runtime logic, stats, level mapping, fire timing, damage, or targeting changed.",
        ],
        "operation": "Trim low-alpha full-canvas haze, enforce transparent border, refit clipped frames within canvas, boost existing rendered material contrast, and emit a review contact sheet.",
        "contact_sheet": str(CONTACT_PATH.relative_to(ROOT)),
        "outputs": rows,
    }
    SPEC_PATH.parent.mkdir(parents=True, exist_ok=True)
    SPEC_PATH.write_text(json.dumps(spec, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    update_index()
    print(f"Polished {len(rows)} non-shooting animation PNGs")
    print(CONTACT_PATH.relative_to(ROOT))
    print(SPEC_PATH.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
