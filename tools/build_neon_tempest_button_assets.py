#!/usr/bin/env python3
"""Build exact-size Neon Tempest buttons without horizontal texture stretching.

Each length family has its own generated source model. Runtime variants are
uniformly scaled and centered inside the exact control dimensions. Transparent
letterboxing absorbs the small ratio differences. No source pixel is
anisotropically resized, cropped through its frame, or repeated.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = (
    ROOT
    / "assets"
    / "production"
    / "source_refs"
    / "generated"
    / "premium_neon_tempest_phase1b1_2026_07_27"
)
OUTPUT_DIR = ROOT / "assets" / "production" / "sprites" / "themes" / "neon_tempest" / "ui"
CONTACT_SHEET = SOURCE_DIR / "neon_tempest_button_runtime_contact_sheet_v1.png"
MANIFEST = SOURCE_DIR / "neon_tempest_button_runtime_manifest_v1.json"

NATIVE_SIZES = [
    (154, 44),
    (166, 58),
    (170, 84),
    (172, 44),
    (174, 72),
    (176, 76),
    (236, 96),
    (260, 112),
    (268, 48),
    (286, 72),
    (286, 80),
    (286, 112),
    (320, 74),
    (320, 80),
    (412, 88),
    (432, 88),
    (440, 80),
    (440, 88),
    (444, 88),
    (452, 88),
    (484, 102),
    (512, 160),
    (560, 104),
    (600, 120),
    (760, 88),
    (760, 112),
    (780, 148),
    (784, 96),
    (840, 88),
    (880, 88),
    (880, 96),
    (904, 88),
    (920, 88),
    (980, 58),
    (980, 96),
    (980, 100),
]

FAMILY_SOURCES = {
    "short": (
        SOURCE_DIR / "neon_button_short_primary_source_v3.png",
        SOURCE_DIR / "neon_button_short_secondary_source_v3.png",
    ),
    "compact": (
        SOURCE_DIR / "neon_button_compact_source_v1.png",
        SOURCE_DIR / "neon_button_compact_source_v1.png",
    ),
    "standard": (
        SOURCE_DIR / "neon_button_standard_source_v1.png",
        SOURCE_DIR / "neon_button_standard_source_v1.png",
    ),
    "long": (
        SOURCE_DIR / "neon_button_long_source_v1.png",
        SOURCE_DIR / "neon_button_long_source_v1.png",
    ),
    "ultra": (
        SOURCE_DIR / "neon_button_ultra_primary_source_v2.png",
        SOURCE_DIR / "neon_button_ultra_secondary_source_v2.png",
    ),
    "ribbon": (
        SOURCE_DIR / "neon_button_ribbon_primary_source_v1.png",
        SOURCE_DIR / "neon_button_ribbon_secondary_source_v1.png",
    ),
}


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _remove_green(image: Image.Image) -> Image.Image:
    rgb = np.asarray(image.convert("RGB"), dtype=np.float32)
    red = rgb[:, :, 0]
    green = rgb[:, :, 1]
    blue = rgb[:, :, 2]
    strongest_other = np.maximum(red, blue)
    green_excess = green - strongest_other
    key_candidate = (green > 88.0) & (green > red * 1.28) & (green > blue * 1.16)
    keyed_alpha = 255.0 - np.clip((green_excess - 24.0) / 92.0, 0.0, 1.0) * 255.0
    alpha = np.where(key_candidate, keyed_alpha, 255.0)
    alpha = np.where((green > 180.0) & (green_excess > 105.0), 0.0, alpha)

    # Remove green spill from antialiased edge pixels without touching cyan light.
    partial = (alpha > 0.0) & (alpha < 255.0)
    green[partial] = np.minimum(green[partial], strongest_other[partial] * 1.04)
    rgba = np.dstack((red, green, blue, alpha)).clip(0, 255).astype(np.uint8)
    return Image.fromarray(rgba)


def _button_crops(source: Path) -> tuple[Image.Image, Image.Image]:
    keyed = _remove_green(Image.open(source))
    alpha = np.asarray(keyed.getchannel("A"))
    row_counts = (alpha > 32).sum(axis=1)
    active_rows = np.flatnonzero(row_counts > max(20, keyed.width // 100))
    if active_rows.size == 0:
        raise RuntimeError(f"{source}: no keyed button pixels found")

    spans: list[tuple[int, int]] = []
    start = previous = int(active_rows[0])
    for raw_y in active_rows[1:]:
        y = int(raw_y)
        if y > previous + 1:
            spans.append((start, previous))
            start = y
        previous = y
    spans.append((start, previous))
    spans.sort(key=lambda item: item[1] - item[0], reverse=True)
    spans = sorted(spans[:2])
    if len(spans) != 2:
        raise RuntimeError(f"{source}: expected two button rows, found {spans}")

    crops: list[Image.Image] = []
    for y0, y1 in spans:
        row_alpha = alpha[y0 : y1 + 1]
        columns = np.flatnonzero((row_alpha > 32).sum(axis=0) > 4)
        x0 = max(0, int(columns[0]) - 2)
        x1 = min(keyed.width - 1, int(columns[-1]) + 2)
        y0 = max(0, y0 - 2)
        y1 = min(keyed.height - 1, y1 + 2)
        crops.append(keyed.crop((x0, y0, x1 + 1, y1 + 1)))
    return crops[0], crops[1]


def _single_button_crop(source: Path) -> Image.Image:
    keyed = _remove_green(Image.open(source))
    alpha = np.asarray(keyed.getchannel("A"))
    rows = np.flatnonzero((alpha > 32).sum(axis=1) > max(20, keyed.width // 100))
    columns = np.flatnonzero((alpha > 32).sum(axis=0) > max(4, keyed.height // 180))
    if rows.size == 0 or columns.size == 0:
        raise RuntimeError(f"{source}: no keyed button pixels found")
    x0 = max(0, int(columns[0]) - 2)
    x1 = min(keyed.width - 1, int(columns[-1]) + 2)
    y0 = max(0, int(rows[0]) - 2)
    y1 = min(keyed.height - 1, int(rows[-1]) + 2)
    return keyed.crop((x0, y0, x1 + 1, y1 + 1))


def _extract_family(family: str, sources: tuple[Path, Path]) -> tuple[Image.Image, Image.Image]:
    primary_source, secondary_source = sources
    if primary_source == secondary_source:
        return _button_crops(primary_source)
    return _single_button_crop(primary_source), _single_button_crop(secondary_source)


def _family_for_size(width: int, height: int) -> str:
    ratio = width / max(height, 1)
    if ratio <= 2.90:
        return "short"
    if ratio <= 4.35:
        return "compact"
    if ratio <= 5.65:
        return "standard"
    if ratio <= 7.45:
        return "long"
    if ratio >= 13.5:
        return "ribbon"
    return "ultra"


def _assemble_exact(source_button: Image.Image, width: int, height: int) -> Image.Image:
    padding = max(1, min(4, height // 22))
    inner_width = width - padding * 2
    inner_height = height - padding * 2
    scale = min(
        inner_width / source_button.width,
        inner_height / source_button.height,
    )
    scaled_width = max(1, int(round(source_button.width * scale)))
    scaled_height = max(1, int(round(source_button.height * scale)))
    scaled = source_button.resize(
        (scaled_width, scaled_height),
        Image.Resampling.LANCZOS,
    )
    assembled = Image.new("RGBA", (width, height))
    assembled.alpha_composite(
        scaled,
        ((width - scaled_width) // 2, (height - scaled_height) // 2),
    )
    return _restrain_neon_frame(assembled)


def _restrain_neon_frame(image: Image.Image) -> Image.Image:
    """Keep the punk color split while stopping the frame from overpowering copy."""
    rgba = np.asarray(image.convert("RGBA"), dtype=np.float32).copy()
    alpha = rgba[:, :, 3]
    visible_y, visible_x = np.nonzero(alpha > 10.0)
    if visible_x.size == 0:
        return image.convert("RGBA")
    left, right = int(visible_x.min()), int(visible_x.max())
    top, bottom = int(visible_y.min()), int(visible_y.max())
    yy, xx = np.indices(alpha.shape)
    edge_distance = np.minimum.reduce((xx - left, right - xx, yy - top, bottom - yy))
    frame_depth = max(3.0, (bottom - top + 1) * 0.24)
    border = (alpha > 10.0) & (edge_distance <= frame_depth)

    rgb = rgba[:, :, :3]
    maximum = rgb.max(axis=2)
    minimum = rgb.min(axis=2)
    luminous = (alpha > 10.0) & (maximum > 78.0)
    chromatic = luminous & ((maximum - minimum) > 24.0)

    # Lower border luminance more than the calm text bed. Saturation remains
    # recognisably cyan/magenta, but no longer blooms into the label strokes.
    border_light = border & luminous
    rgb[border_light] *= 0.74
    center_light = (~border) & luminous
    rgb[center_light] *= 0.90
    gray = (
        rgb[:, :, 0] * 0.2126
        + rgb[:, :, 1] * 0.7152
        + rgb[:, :, 2] * 0.0722
    )[:, :, None]
    soften = border & chromatic
    rgb[soften] = gray[soften] + (rgb[soften] - gray[soften]) * 0.82

    # Partial-alpha pixels are the optical bloom, not the metal edge itself.
    bloom = border & (alpha > 0.0) & (alpha < 220.0)
    alpha[bloom] *= 0.78
    rgba[:, :, :3] = np.clip(rgb, 0.0, 255.0)
    rgba[:, :, 3] = np.clip(alpha, 0.0, 255.0)
    return Image.fromarray(rgba.astype(np.uint8)).convert("RGBA")


def _build_contact_sheet(entries: list[dict[str, object]]) -> None:
    previews = [
        entry
        for entry in entries
        if entry["size"] in {
            "170x84",
            "286x112",
            "600x120",
            "760x112",
            "980x96",
            "980x58",
        }
    ]
    cell_width = 1020
    cell_height = 190
    sheet = Image.new("RGBA", (cell_width, cell_height * len(previews)), (8, 10, 17, 255))
    draw = ImageDraw.Draw(sheet)
    for row, entry in enumerate(previews):
        image = Image.open(ROOT / str(entry["path"])).convert("RGBA")
        y = row * cell_height
        checker = Image.new("RGBA", (cell_width, cell_height), (12, 15, 24, 255))
        sheet.alpha_composite(checker, (0, y))
        sheet.alpha_composite(image, ((cell_width - image.width) // 2, y + 18))
        draw.text((16, y + 8), f"{entry['kind']} · {entry['size']} · {entry['family']}", fill=(220, 232, 245, 255))
    CONTACT_SHEET.parent.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGB").save(CONTACT_SHEET, quality=94)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    extracted = {
        family: _extract_family(family, sources)
        for family, sources in FAMILY_SOURCES.items()
    }
    entries: list[dict[str, object]] = []
    for width, height in NATIVE_SIZES:
        family = _family_for_size(width, height)
        for index, kind in enumerate(("primary", "secondary")):
            output = OUTPUT_DIR / f"ui_button_{kind}_native_{width}x{height}.png"
            runtime = _assemble_exact(extracted[family][index], width, height)
            runtime.save(output, optimize=True)
            entries.append(
                {
                    "kind": kind,
                    "family": family,
                    "size": f"{width}x{height}",
                    "path": output.relative_to(ROOT).as_posix(),
                    "sha256": _sha256(output),
                }
            )

    _build_contact_sheet(entries)
    manifest = {
        "version": 2,
        "method": (
            "independent structural families, uniform contain scaling and "
            "transparent letterboxing; no anisotropic scaling, frame crop or repetition"
        ),
        "visual_treatment": (
            "runtime-only luminance restraint: border 0.74, center highlights 0.90, "
            "border chroma 0.82 and partial-alpha bloom 0.78; geometry and copy unchanged"
        ),
        "sources": {
            family: [
                {
                    "path": path.relative_to(ROOT).as_posix(),
                    "sha256": _sha256(path),
                }
                for path in sources
            ]
            for family, sources in FAMILY_SOURCES.items()
        },
        "outputs": entries,
        "contact_sheet": CONTACT_SHEET.relative_to(ROOT).as_posix(),
    }
    MANIFEST.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Built {len(entries)} exact-size Neon Tempest buttons")
    print(f"Contact sheet: {CONTACT_SHEET.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
