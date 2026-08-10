#!/usr/bin/env python3
"""Guard the slow-zone V3 against radial silhouettes and stretched assets."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
BOUNDARY = ROOT / "assets/production/sprites/vfx/vfx_slow_field_boundary_v3.png"
SURFACE = ROOT / "assets/production/sprites/vfx/vfx_slow_field_surface_v3.png"


def main() -> int:
    errors: list[str] = []
    for path, expected in ((BOUNDARY, (1080, 240)), (SURFACE, (512, 512))):
        if not path.exists():
            errors.append(f"missing {path.relative_to(ROOT)}")
            continue
        image = Image.open(path).convert("RGBA")
        if image.size != expected:
            errors.append(f"{path.name} size {image.size} != {expected}")

    if errors:
        for error in errors:
            print(f"- {error}")
        return 1

    boundary = np.asarray(Image.open(BOUNDARY).convert("RGBA"), dtype=np.uint8)
    alpha = boundary[:, :, 3]
    brightness = boundary[:, :, :3].max(axis=2)
    active_columns = np.count_nonzero((alpha > 10).any(axis=0)) / float(alpha.shape[1])
    if active_columns < 0.96:
        errors.append(f"boundary does not span enough width: {active_columns:.1%}")

    # Measure the strongest frost ridge in 18 horizontal bins. A semicircle has
    # a large center-vs-edge height swing; a zone threshold stays nearly flat.
    ridge_positions: list[float] = []
    energy = brightness.astype(np.float32) * (alpha.astype(np.float32) / 255.0)
    for columns in np.array_split(np.arange(alpha.shape[1]), 18):
        row_energy = energy[:, columns].mean(axis=1)
        ridge_positions.append(float(np.argmax(row_energy)))
    ridge_span = max(ridge_positions) - min(ridge_positions)
    edge_mean = float(np.mean(ridge_positions[:3] + ridge_positions[-3:]))
    center_mean = float(np.mean(ridge_positions[7:11]))
    if ridge_span > 54.0:
        errors.append(f"boundary ridge is too curved/irregular: span={ridge_span:.1f}px")
    if abs(center_mean - edge_mean) > 28.0:
        errors.append(
            f"boundary still reads as a radial arc: center={center_mean:.1f}px edge={edge_mean:.1f}px"
        )

    surface = np.asarray(Image.open(SURFACE).convert("RGBA"), dtype=np.float32)
    horizontal_seam = float(np.abs(surface[:, 0, :] - surface[:, -1, :]).mean())
    vertical_seam = float(np.abs(surface[0, :, :] - surface[-1, :, :]).mean())
    if horizontal_seam > 2.0 or vertical_seam > 2.0:
        errors.append(
            f"surface tile edges do not match: horizontal={horizontal_seam:.2f} vertical={vertical_seam:.2f}"
        )

    if errors:
        print("Slow-field asset check failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print(
        "Slow-field assets OK: full-width non-radial threshold, fixed 1080x240 boundary, "
        "and seamless 512x512 area tile"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
