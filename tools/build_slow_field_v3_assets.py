#!/usr/bin/env python3
"""Build the non-radial slow-zone surface and full-width threshold.

V3 deliberately avoids any ellipse/semicircle silhouette. Runtime range growth
reveals more of a fixed-density interior tile while a fixed-size horizontal
threshold moves to the same data-driven y_min used by enemy movement.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone, timedelta
from pathlib import Path

import numpy as np
from PIL import Image, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets/production/source_refs/generated/slow_field_v3_2026_08_10"
BOUNDARY_SOURCE = SOURCE_DIR / "vfx_slow_field_boundary_master_black.png"
SURFACE_SOURCE = SOURCE_DIR / "vfx_slow_field_surface_master_black.png"
VFX_DIR = ROOT / "assets/production/sprites/vfx"
BOUNDARY_OUT = VFX_DIR / "vfx_slow_field_boundary_v3.png"
SURFACE_OUT = VFX_DIR / "vfx_slow_field_surface_v3.png"
INDEX_PATH = ROOT / "assets/production/OUTSOURCER_ASSET_INDEX.json"

BOUNDARY_SIZE = (1080, 240)
BOUNDARY_ANCHOR_Y = 96
SURFACE_SIZE = 512


def _smoothstep(edge0: float, edge1: float, x: np.ndarray) -> np.ndarray:
    t = np.clip((x - edge0) / max(edge1 - edge0, 0.001), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def black_to_alpha(source: Image.Image, alpha_scale: float = 1.0) -> Image.Image:
    rgb = np.asarray(source.convert("RGB"), dtype=np.float32)
    brightness = rgb.max(axis=2)
    saturation = rgb.max(axis=2) - rgb.min(axis=2)
    alpha = _smoothstep(16.0, 104.0, brightness) * 255.0
    chroma = _smoothstep(16.0, 94.0, saturation) * _smoothstep(14.0, 62.0, brightness) * 220.0
    alpha = np.maximum(alpha, chroma) * alpha_scale
    alpha = np.where((brightness < 14.0) | ((brightness < 24.0) & (saturation < 13.0)), 0.0, alpha)
    lifted = np.clip(rgb * 1.06 + 1.5, 0.0, 255.0).astype(np.uint8)
    rgba = np.dstack((lifted, np.clip(alpha, 0.0, 255.0).astype(np.uint8)))
    image = Image.fromarray(rgba)
    image.putalpha(image.getchannel("A").filter(ImageFilter.GaussianBlur(0.32)))
    return image


def alpha_bbox(image: Image.Image, threshold: int = 8) -> tuple[int, int, int, int]:
    mask = image.getchannel("A").point(lambda value: 255 if value > threshold else 0)
    return mask.getbbox() or (0, 0, image.width, image.height)


def build_boundary() -> None:
    transparent = black_to_alpha(Image.open(BOUNDARY_SOURCE), 1.0)
    x0, y0, x1, y1 = alpha_bbox(transparent)
    crop = transparent.crop((0, max(0, y0 - 42), transparent.width, min(transparent.height, y1 + 70)))
    scale = BOUNDARY_SIZE[0] / max(crop.width, 1)
    resized = crop.resize(
        (BOUNDARY_SIZE[0], max(1, int(round(crop.height * scale)))),
        Image.Resampling.LANCZOS,
    )
    resized = ImageEnhance.Sharpness(resized).enhance(1.12)

    # Align the brightest authored frost ridge to y=96. Runtime can then place
    # the texture at y_min-96 and the visible threshold matches gameplay.
    rgba = np.asarray(resized, dtype=np.float32)
    row_energy = (rgba[:, :, :3].max(axis=2) * (rgba[:, :, 3] / 255.0)).mean(axis=1)
    ridge_y = int(np.argmax(row_energy)) if row_energy.size else resized.height // 2
    top = BOUNDARY_ANCHOR_Y - ridge_y
    canvas = Image.new("RGBA", BOUNDARY_SIZE, (0, 0, 0, 0))
    canvas.alpha_composite(resized, (0, top))

    alpha = np.asarray(canvas.getchannel("A"), dtype=np.float32)
    edge_fade = np.ones((BOUNDARY_SIZE[1], 1), dtype=np.float32)
    edge_fade[:20, 0] = np.linspace(0.0, 1.0, 20, dtype=np.float32)
    edge_fade[-44:, 0] = np.linspace(1.0, 0.0, 44, dtype=np.float32)
    alpha *= edge_fade
    canvas.putalpha(Image.fromarray(np.clip(alpha, 0.0, 255.0).astype(np.uint8)))
    BOUNDARY_OUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(BOUNDARY_OUT, optimize=True)


def build_seamless_surface() -> None:
    transparent = black_to_alpha(Image.open(SURFACE_SOURCE), 0.64)
    tile = transparent.resize((SURFACE_SIZE, SURFACE_SIZE), Image.Resampling.LANCZOS)
    pixels = np.asarray(tile, dtype=np.float32).copy()

    # Feather opposite edges into the same authored average. This makes the
    # texture periodic without mirroring the whole image into a kaleidoscope.
    feather = 72
    for distance in range(feather):
        influence = float((1.0 - distance / float(feather)) ** 2)
        left = pixels[:, distance, :].copy()
        right = pixels[:, -1 - distance, :].copy()
        average = (left + right) * 0.5
        pixels[:, distance, :] = left * (1.0 - influence) + average * influence
        pixels[:, -1 - distance, :] = right * (1.0 - influence) + average * influence
    for distance in range(feather):
        influence = float((1.0 - distance / float(feather)) ** 2)
        top = pixels[distance, :, :].copy()
        bottom = pixels[-1 - distance, :, :].copy()
        average = (top + bottom) * 0.5
        pixels[distance, :, :] = top * (1.0 - influence) + average * influence
        pixels[-1 - distance, :, :] = bottom * (1.0 - influence) + average * influence
    tile = Image.fromarray(np.clip(pixels, 0.0, 255.0).astype(np.uint8))
    tile = ImageEnhance.Sharpness(tile).enhance(1.06)
    tile.save(SURFACE_OUT, optimize=True)


def register_assets() -> None:
    data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
    rows = data.setdefault("owner_directed_generated_overrides", [])
    task = "Non-radial slow-zone V3 with full-width threshold and fixed-density area fill"
    rows[:] = [row for row in rows if row.get("task") != task]
    rows.append(
        {
            "path": "sprites/vfx/{vfx_slow_field_surface_v3,vfx_slow_field_boundary_v3}.png",
            "source": "source_refs/generated/slow_field_v3_2026_08_10/prompt_log.md",
            "derived": [
                "source_refs/generated/slow_field_v3_2026_08_10/vfx_slow_field_boundary_master_black.png",
                "source_refs/generated/slow_field_v3_2026_08_10/vfx_slow_field_surface_master_black.png",
            ],
            "reason": (
                "V2 used an elliptical upper arc, which read as an ice dome rather than an affected ground area "
                "once coverage exceeded 60%. V3 replaces it with a full-width non-radial threshold plus a quiet "
                "fixed-density interior; range changes move the threshold and reveal more area without scaling art."
            ),
            "count": 2,
            "task": task,
            "created_at": datetime.now(timezone(timedelta(hours=8))).isoformat(timespec="seconds"),
        }
    )
    INDEX_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    for source in (BOUNDARY_SOURCE, SURFACE_SOURCE):
        if not source.exists():
            raise SystemExit(f"missing approved source: {source}")
    build_boundary()
    build_seamless_surface()
    register_assets()
    print(BOUNDARY_OUT.relative_to(ROOT))
    print(SURFACE_OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
