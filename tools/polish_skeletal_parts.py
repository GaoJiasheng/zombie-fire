#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / "assets" / "production"
PARTS_DIR = PROD / "sprites" / "parts"
SOURCE_DIR = PROD / "source_refs" / "generated"
CONTACT_DIR = PROD / "contact_sheets"
SPEC_PATH = SOURCE_DIR / "skeletal_parts_polish_spec_2026_07_01.json"
CONTACT_PATH = CONTACT_DIR / "contact_skeletal_parts_polish_2026_07_01.png"

CANVAS = (256, 256)
PART_TARGET = {
    "head": 214,
    "body": 232,
    "arm_l": 224,
    "arm_r": 224,
    "hand_l": 218,
    "hand_r": 218,
    "leg_l": 224,
    "leg_r": 224,
    "weapon": 238,
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


def part_key(path: Path) -> str:
    stem = path.stem
    for key in sorted(PART_TARGET, key=len, reverse=True):
        if stem.endswith(f"_{key}"):
            return key
    return "body"


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    return image.getchannel("A").getbbox()


def visible_fill_ratio(image: Image.Image) -> float:
    alpha = image.getchannel("A")
    pixels = alpha.getdata()
    return sum(1 for value in pixels if value > 18) / float(image.width * image.height)


def polish_part(image: Image.Image, key: str) -> tuple[Image.Image, dict[str, object]]:
    source = image.convert("RGBA")
    bbox = alpha_bbox(source)
    if bbox is None:
        return source, {"empty": True}

    cropped = source.crop(bbox)
    bbox_w, bbox_h = cropped.size
    target_max = PART_TARGET.get(key, 224)
    scale = min(target_max / max(1, bbox_w), target_max / max(1, bbox_h), 1.0)
    new_size = (max(1, int(round(bbox_w * scale))), max(1, int(round(bbox_h * scale))))
    if new_size != cropped.size:
        cropped = cropped.resize(new_size, Image.Resampling.LANCZOS)

    rgb = cropped.convert("RGB")
    alpha = cropped.getchannel("A")
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.22))
    rgb = ImageEnhance.Contrast(rgb).enhance(1.07)
    rgb = ImageEnhance.Color(rgb).enhance(1.05)
    rgb = ImageEnhance.Sharpness(rgb).enhance(1.16)
    cropped = Image.merge("RGBA", (*rgb.split(), alpha))

    canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    x = (CANVAS[0] - new_size[0]) // 2
    y = (CANVAS[1] - new_size[1]) // 2
    canvas.alpha_composite(cropped, (x, y))

    # Add a very light internal bevel from the alpha silhouette. It stays inside
    # the cutout, so the files remain rig-friendly transparent body parts.
    alpha_canvas = canvas.getchannel("A")
    expanded = alpha_canvas.filter(ImageFilter.MaxFilter(5))
    contracted = alpha_canvas.filter(ImageFilter.MinFilter(5))
    edge = ImageChops.subtract(expanded, contracted).filter(ImageFilter.GaussianBlur(0.9))
    edge = ImageChops.multiply(edge, alpha_canvas)
    edge_rgba = Image.new("RGBA", CANVAS, (255, 236, 198, 0))
    edge_rgba.putalpha(edge.point(lambda v: min(36, int(v * 0.18))))
    canvas = Image.alpha_composite(canvas, edge_rgba)

    return canvas, {
        "empty": False,
        "source_bbox": bbox,
        "source_size": (bbox_w, bbox_h),
        "output_size": new_size,
        "scale": round(scale, 4),
        "fill_before": round(visible_fill_ratio(source), 4),
        "fill_after": round(visible_fill_ratio(canvas), 4),
    }


def update_parts_json(path: Path) -> None:
    data = json.loads(path.read_text(encoding="utf-8"))
    data["note"] = (
        "Top-tier raster cutout polish pass applied 2026-07-01: derived from existing rendered production art, "
        "recentered with safe transparent margins, softened alpha edges, and boosted material contrast. "
        "No SVG/vector placeholder treatment."
    )
    data["polish_source"] = "assets/production/source_refs/generated/skeletal_parts_polish_spec_2026_07_01.json"
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def build_contact(rows: list[dict[str, object]]) -> None:
    picks: list[Path] = []
    for group in ("characters", "zombies", "bosses", "pets", "weapons"):
        picks.extend(sorted((PARTS_DIR / group).rglob("*.png"))[:24])
    thumb = 112
    label_h = 28
    cols = 12
    rows_count = (len(picks) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * thumb, rows_count * (thumb + label_h)), (13, 18, 24))
    draw = ImageDraw.Draw(sheet)
    font = load_font(10)
    for i, path in enumerate(picks):
        image = Image.open(path).convert("RGBA")
        tile = Image.new("RGBA", CANVAS, (28, 34, 42, 255))
        tile.alpha_composite(image)
        tile = ImageOps.contain(tile.convert("RGB"), (thumb, thumb), Image.Resampling.LANCZOS)
        base_x = (i % cols) * thumb
        base_y = (i // cols) * (thumb + label_h)
        x = base_x + (thumb - tile.width) // 2
        y = base_y + (thumb - tile.height) // 2
        sheet.paste(tile, (x, y))
        draw.text((base_x + 4, base_y + thumb + 3), path.stem[-20:], fill=(225, 231, 237), font=font)
    CONTACT_DIR.mkdir(parents=True, exist_ok=True)
    sheet.save(CONTACT_PATH, quality=95)


def update_index() -> None:
    index_path = PROD / "OUTSOURCER_ASSET_INDEX.json"
    data = json.loads(index_path.read_text(encoding="utf-8"))
    source_ref = "source_refs/generated/skeletal_parts_polish_spec_2026_07_01.json"
    data.setdefault("owner_directed_generated_overrides", [])
    data["owner_directed_generated_overrides"] = [
        item
        for item in data["owner_directed_generated_overrides"]
        if not (item.get("path") == "sprites/parts" and item.get("source") == source_ref)
    ]
    data["owner_directed_generated_overrides"].append(
        {
            "path": "sprites/parts",
            "source": source_ref,
            "derived": "contact_sheets/contact_skeletal_parts_polish_2026_07_01.png",
            "reason": "Owner requested all remaining prototype-feeling assets to be raised toward top-tier rendered App Store quality with no SVG/vector placeholders; skeletal parts were recentered, edge-cleaned, and material-polished while preserving IDs and 256x256 PNG contracts.",
        }
    )
    counts = data.setdefault("counts", {})
    counts["parts_files"] = len(list(PARTS_DIR.rglob("*.png")))
    counts["total_files"] = len([p for p in PROD.rglob("*") if p.is_file() and not p.name.endswith(".import")])
    index_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    rows: list[dict[str, object]] = []
    for path in sorted(PARTS_DIR.rglob("*.png")):
        key = part_key(path)
        before = Image.open(path).convert("RGBA")
        after, metrics = polish_part(before, key)
        after.save(path, optimize=True)
        rows.append({"path": str(path.relative_to(ROOT)), "part": key, **metrics})

    for path in sorted(PARTS_DIR.rglob("*_parts.json")):
        update_parts_json(path)

    build_contact(rows)
    spec = {
        "id": "skeletal_parts_polish_2026_07_01",
        "generated_by": "tools/polish_skeletal_parts.py",
        "quality_target": "Top-tier raster cutout cleanup for production skeletal/body parts; no SVG/vector placeholder treatment.",
        "preserved_contracts": [
            "All part filenames and directory structure are unchanged.",
            "All part PNG canvases remain 256x256 with transparency.",
            "No data/*.json gameplay content, runtime logic, IDs, stats, level mapping, or battle behavior changed.",
        ],
        "operation": "Recenters visible pixels with safe transparent margins, cleans alpha edges, boosts rendered material contrast, and records the non-placeholder provenance in *_parts.json.",
        "contact_sheet": str(CONTACT_PATH.relative_to(ROOT)),
        "outputs": rows,
    }
    SPEC_PATH.parent.mkdir(parents=True, exist_ok=True)
    SPEC_PATH.write_text(json.dumps(spec, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    update_index()
    print(f"Polished {len(rows)} skeletal/body part PNGs")
    print(CONTACT_PATH.relative_to(ROOT))
    print(SPEC_PATH.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
