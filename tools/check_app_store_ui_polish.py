#!/usr/bin/env python3
"""Reject regressions to flat/cropped placeholder art in release-facing UI."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "assets/production/source_refs/generated/app_store_ui_placeholder_replacements_2026_08_01"
MANIFEST = SOURCE_ROOT / "runtime_manifest.json"
EXPECTED_SOURCES = {
    "assets/production/source_refs/generated/app_store_ui_placeholder_replacements_2026_08_01/core_hud_icons_chroma.png",
    "assets/production/source_refs/generated/app_store_ui_placeholder_replacements_2026_08_01/tactical_icons_chroma.png",
    "assets/production/source_refs/generated/app_store_ui_placeholder_replacements_2026_08_01/hud_surfaces_chroma.png",
}
SURFACE_SIZES = {
    "ui_level_card_skin.png": (1024, 148),
    "ui_combo_panel.png": (390, 128),
    "ui_pill_skin.png": (512, 128),
    "ui_plate_skin.png": (420, 150),
    "ui_damage_number_badge.png": (260, 100),
}


def _edge_green_ratio(image: Image.Image) -> float:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    edge = green = 0
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a <= 24:
                continue
            if not any(
                nx < 0
                or ny < 0
                or nx >= width
                or ny >= height
                or pixels[nx, ny][3] <= 24
                for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1))
            ):
                continue
            edge += 1
            if g > 150 and g > r * 1.55 and g > b * 1.55:
                green += 1
    return green / max(1, edge)


def main() -> int:
    errors: list[str] = []
    if not MANIFEST.exists():
        print(f"App Store UI polish check failed: missing {MANIFEST.relative_to(ROOT)}")
        return 1
    payload = json.loads(MANIFEST.read_text(encoding="utf-8"))
    sources = set(payload.get("sources", []))
    if sources != EXPECTED_SOURCES:
        errors.append(f"rendered source contract changed: {sorted(sources)}")
    if not (SOURCE_ROOT / "prompt_log.md").exists():
        errors.append("missing prompt/provenance log")

    outputs = payload.get("outputs", [])
    if len(outputs) != 32:
        errors.append(f"expected 32 replacement assets, found {len(outputs)}")
    for raw_path in outputs:
        path = ROOT / raw_path
        if not path.exists():
            errors.append(f"missing replacement asset: {raw_path}")
            continue
        with Image.open(path) as source:
            image = source.convert("RGBA")
        expected_size = SURFACE_SIZES.get(path.name, (256, 256))
        if image.size != expected_size:
            errors.append(f"wrong size {raw_path}: {image.size} != {expected_size}")
        bbox = image.getchannel("A").getbbox()
        if bbox is None:
            errors.append(f"empty replacement asset: {raw_path}")
            continue
        left, top, right, bottom = bbox
        margin = min(left, top, image.width - right, image.height - bottom)
        if margin < 2:
            errors.append(f"unsafe alpha margin {raw_path}: {margin}px")
        colors = image.convert("RGB").getcolors(maxcolors=image.width * image.height)
        if colors is not None and len(colors) < 256:
            errors.append(f"replacement still looks flat/procedural: {raw_path} ({len(colors)} colors)")
        if path.name not in {"icon_element_poison.png", "ui_card_tag_element.png"}:
            green_ratio = _edge_green_ratio(image)
            if green_ratio > 0.03:
                errors.append(f"chroma fringe {raw_path}: {green_ratio:.3f}")

    if errors:
        print("App Store UI polish check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(f"App Store UI polish check OK: {len(outputs)} deeply rendered replacements")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
