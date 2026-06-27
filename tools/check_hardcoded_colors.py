#!/usr/bin/env python3
"""Guardrail: keep scene colors aligned to the UiKit palette (single source).

ui/ui_kit.gd is treated as the canonical palette. Every Color() literal found in
*.tscn must either:
  - match a palette color (within tolerance),
  - be a pure neutral (black/white with any alpha, used for shadows/outlines), or
  - be listed in the frozen baseline of known legacy deviations.

New, unlisted deviations fail the check so palette drift cannot creep back in.
Run with --update-baseline after an intentional, reviewed color change.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PALETTE_FILE = ROOT / "ui" / "ui_kit.gd"
BASELINE_FILE = ROOT / "tools" / "color_baseline.json"
TOLERANCE = 0.02

COLOR_RE = re.compile(r"Color\(\s*([0-9.\s,\-]+?)\s*\)")


def parse_colors(text: str) -> list[tuple[float, ...]]:
    colors: list[tuple[float, ...]] = []
    for match in COLOR_RE.finditer(text):
        parts = [p.strip() for p in match.group(1).split(",") if p.strip() != ""]
        try:
            rgba = tuple(round(float(p), 4) for p in parts)
        except ValueError:
            continue
        if len(rgba) >= 3:
            colors.append(rgba[:4])
    return colors


def rgb_key(color: tuple[float, ...]) -> tuple[float, float, float]:
    return (color[0], color[1], color[2])


def is_neutral(color: tuple[float, ...]) -> bool:
    # Pure black / pure white (any alpha) are allowed everywhere (shadows, scrims, outlines).
    return all(component in (0.0, 1.0) for component in color[:3])


def matches_palette(color: tuple[float, ...], palette: list[tuple[float, float, float]]) -> bool:
    key = rgb_key(color)
    for pal in palette:
        if all(abs(key[i] - pal[i]) <= TOLERANCE for i in range(3)):
            return True
    return False


def collect_scene_colors() -> dict[str, list[tuple[float, ...]]]:
    found: dict[str, list[tuple[float, ...]]] = {}
    for scene in sorted(ROOT.rglob("*.tscn")):
        if ".godot" in scene.parts:
            continue
        colors = parse_colors(scene.read_text(encoding="utf-8"))
        if colors:
            found[str(scene.relative_to(ROOT))] = colors
    return found


def deviations() -> tuple[set[str], dict[str, list[str]]]:
    palette = [rgb_key(c) for c in parse_colors(PALETTE_FILE.read_text(encoding="utf-8"))]
    keys: set[str] = set()
    by_file: dict[str, list[str]] = {}
    for rel, colors in collect_scene_colors().items():
        for color in colors:
            if is_neutral(color) or matches_palette(color, palette):
                continue
            key = ",".join(f"{c:.4f}" for c in rgb_key(color))
            keys.add(key)
            by_file.setdefault(rel, []).append(key)
    return keys, by_file


def load_baseline() -> set[str]:
    if not BASELINE_FILE.exists():
        return set()
    return set(json.loads(BASELINE_FILE.read_text(encoding="utf-8")).get("allowed_rgb", []))


def main(argv: list[str]) -> int:
    keys, by_file = deviations()
    if "--update-baseline" in argv:
        BASELINE_FILE.write_text(
            json.dumps({"allowed_rgb": sorted(keys)}, ensure_ascii=False, indent="\t") + "\n",
            encoding="utf-8",
        )
        print(f"Baseline updated: {len(keys)} legacy off-palette colors frozen.")
        return 0

    baseline = load_baseline()
    new_offenders = keys - baseline
    print(f"Scene colors off palette: {len(keys)} (baseline allows {len(baseline)})")
    if new_offenders:
        print("New off-palette colors detected (align to UiKit or review then --update-baseline):")
        for rel, file_keys in sorted(by_file.items()):
            hits = sorted(set(k for k in file_keys if k in new_offenders))
            if hits:
                print(f"- {rel}: {', '.join(hits)}")
        return 1
    print("Color palette guardrail OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
