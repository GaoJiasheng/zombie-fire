#!/usr/bin/env python3
"""Guardrail: keep UiKit text colors readable (WCAG contrast) on dark panels.

The game is an all-dark UI, so bright text generally passes, but this freezes the
guarantee so nobody introduces a low-contrast text color later. Body text must
hit WCAG AA (>=4.5:1); large / secondary / disabled text only needs >=3.0:1.

Backgrounds are the translucent UiKit panels composited over the lightest plausible
backdrop (GREY_900), which is the worst case for bright text.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
UI_KIT = ROOT / "ui" / "ui_kit.gd"

AA_BODY = 4.5
AA_LARGE = 3.0

# Text colors held to the strict body threshold.
BODY_TEXT = [
    "TEXT_MAIN", "TEXT_MUTED", "CYAN", "GOLD", "GREEN", "PURPLE",
    "GREY_300", "SUCCESS", "WARNING", "DANGER", "INFO",
]
# Secondary / disabled text — lower bar is acceptable by WCAG.
LARGE_TEXT = ["GREY_500"]


def _linear(channel: float) -> float:
    return channel / 12.92 if channel <= 0.03928 else ((channel + 0.055) / 1.055) ** 2.4


def luminance(rgb: tuple[float, float, float]) -> float:
    r, g, b = (_linear(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(fg: tuple[float, float, float], bg: tuple[float, float, float]) -> float:
    l1, l2 = luminance(fg), luminance(bg)
    hi, lo = max(l1, l2), min(l1, l2)
    return (hi + 0.05) / (lo + 0.05)


def composite(top: tuple[float, float, float, float], under: tuple[float, float, float]) -> tuple[float, float, float]:
    a = top[3]
    return tuple(a * top[i] + (1.0 - a) * under[i] for i in range(3))


def parse_ui_kit() -> tuple[dict[str, tuple[float, ...]], dict[str, tuple[float, ...]]]:
    text = UI_KIT.read_text(encoding="utf-8")
    consts: dict[str, tuple[float, ...]] = {}
    for name, body in re.findall(r"const (\w+) := Color\(([^)]*)\)", text):
        parts = [float(x) for x in body.split(",")]
        if len(parts) == 3:
            parts.append(1.0)
        consts[name] = tuple(parts)
    elements: dict[str, tuple[float, ...]] = {}
    block = re.search(r"static func element_color.*?(?=\nstatic func )", text, re.S)
    if block:
        pairs = re.findall(r'"(\w+)":\s*\n\s*return Color\(([^)]*)\)', block.group(0))
        for name, body in pairs:
            parts = [float(x) for x in body.split(",")]
            if len(parts) == 3:
                parts.append(1.0)
            elements[name] = tuple(parts)
    return consts, elements


def main() -> int:
    consts, elements = parse_ui_kit()
    if "PANEL_BG" not in consts or "GREY_900" not in consts:
        print("contrast check failed: UiKit palette constants missing")
        return 1
    under = consts["GREY_900"][:3]
    backgrounds = {
        "PANEL_BG": composite(consts["PANEL_BG"], under),
        "PANEL_BG_DARK": composite(consts["PANEL_BG_DARK"], under),
    }
    errors: list[str] = []
    rows: list[tuple[str, str, float, float]] = []

    def check(name: str, rgb: tuple[float, ...], threshold: float) -> None:
        for bg_name, bg in backgrounds.items():
            ratio = contrast(rgb[:3], bg)
            rows.append((name, bg_name, ratio, threshold))
            if ratio < threshold:
                errors.append(
                    f"{name} on {bg_name}: contrast {ratio:.2f}:1 < {threshold:.1f}:1"
                )

    for name in BODY_TEXT:
        if name in consts:
            check(name, consts[name], AA_BODY)
    for name in LARGE_TEXT:
        if name in consts:
            check(name, consts[name], AA_LARGE)
    for name, rgb in elements.items():
        check("element_%s" % name, rgb, AA_BODY)

    print("Text contrast vs dark panels (worst case over GREY_900):")
    for name, bg_name, ratio, threshold in rows:
        flag = "ok" if ratio >= threshold else "LOW"
        print(f"  [{flag}] {ratio:5.2f}:1  {name} / {bg_name}  (need {threshold:.1f})")

    if errors:
        print("\nContrast check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("\nContrast guardrail OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
