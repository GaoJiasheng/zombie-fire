#!/usr/bin/env python3
"""Build the premium slow-field surface tile and fixed leading edge.

The runtime deliberately uses two independent assets:

* a seamless, fixed-density interior tile whose Control rect grows with range;
* a fixed-size rendered leading edge that only moves with the data-driven y_min.

This prevents level range growth from stretching either rendered prototype.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone, timedelta
from pathlib import Path

import numpy as np
from PIL import Image, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets/production/source_refs/generated/slow_field_v2_2026_08_03"
BOUNDARY_SOURCE = SOURCE_DIR / "vfx_slow_field_boundary_master_black.png"
SURFACE_SOURCE = SOURCE_DIR / "vfx_slow_field_surface_master_black.png"
VFX_DIR = ROOT / "assets/production/sprites/vfx"
FRONT_OUT = VFX_DIR / "vfx_slow_field_front_v2.png"
SURFACE_OUT = VFX_DIR / "vfx_slow_field_surface_v2.png"
INDEX_PATH = ROOT / "assets/production/OUTSOURCER_ASSET_INDEX.json"


def _smoothstep(edge0: float, edge1: float, x: np.ndarray) -> np.ndarray:
    t = np.clip((x - edge0) / max(edge1 - edge0, 0.001), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def black_to_alpha(source: Image.Image, alpha_scale: float = 1.0) -> Image.Image:
    rgb = np.asarray(source.convert("RGB"), dtype=np.float32)
    brightness = rgb.max(axis=2)
    saturation = rgb.max(axis=2) - rgb.min(axis=2)
    alpha = _smoothstep(20.0, 108.0, brightness) * 255.0
    chroma = _smoothstep(18.0, 104.0, saturation) * _smoothstep(18.0, 70.0, brightness) * 225.0
    alpha = np.maximum(alpha, chroma) * alpha_scale
    alpha = np.where((brightness < 18.0) | ((brightness < 29.0) & (saturation < 16.0)), 0.0, alpha)
    lifted = np.clip(rgb * 1.07 + 1.5, 0.0, 255.0).astype(np.uint8)
    rgba = np.dstack((lifted, np.clip(alpha, 0.0, 255.0).astype(np.uint8)))
    image = Image.fromarray(rgba)
    image.putalpha(image.getchannel("A").filter(ImageFilter.GaussianBlur(0.35)))
    return image


def alpha_bbox(image: Image.Image, threshold: int = 8) -> tuple[int, int, int, int]:
    mask = image.getchannel("A").point(lambda value: 255 if value > threshold else 0)
    return mask.getbbox() or (0, 0, image.width, image.height)


def build_fixed_front() -> None:
    transparent = black_to_alpha(Image.open(BOUNDARY_SOURCE), 1.0)
    x0, y0, x1, y1 = alpha_bbox(transparent)
    content_height = max(1, y1 - y0)
    # Only the advancing upper boundary is retained. The open center and rear
    # half are provided by the tiled surface, so the front never becomes a
    # deformable full-field ellipse.
    crop_top = max(0, y0 - 18)
    crop_bottom = min(transparent.height, y0 + int(content_height * 0.48))
    cropped = transparent.crop((max(0, x0 - 24), crop_top, min(transparent.width, x1 + 24), crop_bottom))
    scale = 1080.0 / max(cropped.width, 1)
    resized = cropped.resize(
        (1080, max(1, int(round(cropped.height * scale)))),
        Image.Resampling.LANCZOS,
    )
    resized = ImageEnhance.Sharpness(resized).enhance(1.14)
    canvas = Image.new("RGBA", (1080, 320), (0, 0, 0, 0))
    top = max(0, (320 - resized.height) // 2)
    canvas.alpha_composite(resized, (0, top))
    # Fade only the low mist tail, preserving the authored crystalline front.
    alpha = np.asarray(canvas.getchannel("A"), dtype=np.float32)
    fade_start = int(canvas.height * 0.68)
    fade = np.ones((canvas.height, 1), dtype=np.float32)
    fade[fade_start:, 0] = np.linspace(1.0, 0.0, canvas.height - fade_start, dtype=np.float32)
    alpha *= fade
    canvas.putalpha(Image.fromarray(np.clip(alpha, 0.0, 255.0).astype(np.uint8)))
    FRONT_OUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(FRONT_OUT, optimize=True)


def build_seamless_surface() -> None:
    transparent = black_to_alpha(Image.open(SURFACE_SOURCE), 0.82)
    # A mirrored 2x2 tile has matching opposite edges. Runtime repeats this at
    # native density; increasing range reveals more tiles rather than scaling.
    quadrant = transparent.resize((256, 256), Image.Resampling.LANCZOS)
    tile = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    tile.alpha_composite(quadrant, (0, 0))
    tile.alpha_composite(quadrant.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (256, 0))
    tile.alpha_composite(quadrant.transpose(Image.Transpose.FLIP_TOP_BOTTOM), (0, 256))
    tile.alpha_composite(quadrant.transpose(Image.Transpose.ROTATE_180), (256, 256))
    tile = ImageEnhance.Sharpness(tile).enhance(1.08)
    tile.save(SURFACE_OUT, optimize=True)


def register_assets() -> None:
    data = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
    rows = data.setdefault("owner_directed_generated_overrides", [])
    task = "Rendered slow-field V2 with non-stretched data-driven range architecture"
    rows[:] = [row for row in rows if row.get("task") != task]
    rows.append(
        {
            "path": "sprites/vfx/{vfx_slow_field_surface_v2,vfx_slow_field_front_v2}.png",
            "source": "source_refs/generated/slow_field_v2_2026_08_03/prompt_log.md",
            "derived": [
                "source_refs/generated/slow_field_v2_2026_08_03/vfx_slow_field_boundary_master_black.png",
                "source_refs/generated/slow_field_v2_2026_08_03/vfx_slow_field_surface_master_black.png",
            ],
            "reason": (
                "The previous persistent slow field was a stretched band plus crossed procedural sine lines, "
                "which read as a debug grid. V2 uses a rendered cryogenic/aurora interior at fixed tile density "
                "and a separate fixed-size rendered leading edge; level growth changes coverage and boundary "
                "position without deforming either source asset."
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
    build_fixed_front()
    build_seamless_surface()
    register_assets()
    print(FRONT_OUT.relative_to(ROOT))
    print(SURFACE_OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
