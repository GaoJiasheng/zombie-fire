#!/usr/bin/env python3
"""Capture the UI round-2 owned-screen matrix through the production shot helper."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
CHECKER_PATH = ROOT / "tools" / "check_visual_screens.py"
SPEC = importlib.util.spec_from_file_location("zf_visual_checker", CHECKER_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"Unable to load {CHECKER_PATH}")
VISUAL = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VISUAL)

SIZES = [
    ("1080x1920", [1080, 1920]),
    ("1320x2868", [1320, 2868]),
    ("750x1334", [750, 1334]),
]
LANGUAGES = ["zh", "en"]
ROUTES = [
    ("menu", "menu", {}),
    ("map", "map", {}),
    ("map_chapter", "map", {"chapter": 1}),
    ("store_empty", "store", {}),
    ("settings", "settings", {}),
    ("collection", "collection", {"mode": "characters"}),
]
SAFE_INSETS = [44, 132, 44, 102]
FRESH_SAVE = {
    "player": {"gold": 0, "xp": 0, "star": 0},
    "levels_progress": {f"level_{number:03d}": 0 for number in range(1, 100)},
    "challenge_progress": {},
    "entitlements": {"verified": [], "last_sync_unix": 0},
    "commerce": {"mock_receipts": [], "mock_last_transaction_unix": 0},
    "cosmetics": {
        "selected_theme": "default",
        "character_outfits": {
            "vanguard": "follow_theme",
            "blaze": "follow_theme",
            "frost": "follow_theme",
            "volt": "follow_theme",
        },
    },
    "unlocks": {
        "levels": ["level_001"],
        "characters": ["vanguard"],
        "weapons": ["weapon_autocannon"],
        "armors": [],
        "chips": [],
        "pets": [],
    },
}


def main() -> int:
    errors: list[str] = []
    screens: list[dict] = []
    for size_label, viewport_size in SIZES:
        for language in LANGUAGES:
            for screen_label, route, route_payload in ROUTES:
                label = f"round2_{size_label}_{language}_{screen_label}"
                payload = {
                    "viewport_size": viewport_size,
                    "_visual_safe_insets": SAFE_INSETS,
                    "language": language,
                    "save_override": FRESH_SAVE,
                    **route_payload,
                }
                out_path = OUT / f"{label}.png"
                print(f"capture {label}", flush=True)
                code, audit_issues, output = VISUAL.capture(route, payload, out_path)
                image_issues = VISUAL.analyze(out_path, label, tuple(viewport_size)) if code == 0 else []
                warning_issues = [
                    line.strip()
                    for line in output.splitlines()
                    if "!is_inside_tree()" in line
                ]
                if code != 0:
                    errors.append(f"{label}: capture exit {code}")
                errors.extend(f"{label}: {issue}" for issue in audit_issues)
                errors.extend(f"{label}: {issue}" for issue in image_issues)
                errors.extend(f"{label}: runtime warning {issue}" for issue in warning_issues)
                screens.append(
                    {
                        "label": label,
                        "route": route,
                        "payload": payload,
                        "file": out_path.name,
                        "capture_code": code,
                        "runtime_audit_issues": audit_issues,
                        "image_analysis_issues": image_issues,
                        "tree_warning_issues": warning_issues,
                        "output_tail": output[-1200:] if code != 0 or warning_issues else "",
                    }
                )
    manifest = {
        "screen_count": len(screens),
        "error_count": len(errors),
        "font_scale": 1.5,
        "screens": screens,
        "errors": errors,
    }
    (OUT / "capture_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    if errors:
        print("Round-2 capture failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(f"Round-2 capture OK: {len(screens)} screens")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
