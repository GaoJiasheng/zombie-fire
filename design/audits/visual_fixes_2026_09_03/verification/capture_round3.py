#!/usr/bin/env python3
"""Round-three evidence via the unchanged GodotQuiet / _shot.gd capture path.

Run from this worktree: python3 <this file> x1|x2|x3|x4|modal before|after
Required environment: ZOMBIE_FIRE_ALLOW_WINDOW_CAPTURE=1,
ZOMBIE_FIRE_CAPTURE_READONLY=1. No gameplay or save files are modified.
"""
import copy
import json
import os
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[4]
AUDIT = ROOT / "design/audits/visual_fixes_2026_09_03"
sys.path.insert(0, str(ROOT / "tools"))
import check_visual_screens as visual

SIZES = [(1080, 1920), (1080, 2340), (1320, 2868)]
LANGUAGES = ("zh", "en")


def cases(group):
    if group == "x1":
        for size in SIZES:
            for language in LANGUAGES:
                yield "settings", {"language": language, "viewport_size": list(size), "debug_settings_info": "privacy"}, f"privacy_{size[0]}x{size[1]}_{language}"
    elif group == "x2":
        for theme in ("neon_tempest", "infernal_dominion", "polar_aurora", "gilded_eclipse"):
            for language in LANGUAGES:
                for position, scroll in (("top", 0), ("premium", 100000)):
                    yield "collection", {"language": language, "mode": "weapons", "viewport_size": [1080, 1920], "save_override": copy.deepcopy(visual.PREMIUM_CROSS_SAVE_OVERRIDES[theme]), "debug_scroll_y": scroll}, f"weapons_{theme}_{language}_{position}"
    elif group == "x3":
        for size in SIZES + [(1080, 2046)]:
            for language in LANGUAGES:
                for character in visual.CHARACTER_IDS:
                    if size == (1080, 2046) and character != "vanguard":
                        continue
                    yield "collection", {"language": language, "mode": "characters", "detail_item": character, "viewport_size": list(size)}, f"character_{character}_{size[0]}x{size[1]}_{language}"
    elif group == "x4":
        for size in SIZES:
            for language in LANGUAGES:
                yield "loadout", {"language": language, "level_id": "level_099", "viewport_size": list(size), "save_override": copy.deepcopy(visual.PREMIUM_CROSS_SAVE_OVERRIDES["neon_tempest"]), "equipment": {"selected_character": "vanguard", "selected_weapon": "weapon_apocalypse_thunder"}}, f"loadout_neon_{size[0]}x{size[1]}_{language}"
    elif group == "modal":
        for size in SIZES[:2]:
            for language in LANGUAGES:
                yield "store", {"language": language, "viewport_size": list(size), "debug_complete_store_purchase": "com.gaojiasheng.zombiefire.theme.neon_tempest", "save_override": copy.deepcopy(visual.FULL_STORE_SAVE_OVERRIDE)}, f"purchase_complete_{size[0]}x{size[1]}_{language}"
    else:
        raise ValueError(group)


def main():
    group, phase = sys.argv[1:3]
    if os.environ.get("ZOMBIE_FIRE_ALLOW_WINDOW_CAPTURE") != "1" or os.environ.get("ZOMBIE_FIRE_CAPTURE_READONLY") != "1":
        raise RuntimeError("The explicitly authorized quiet, read-only capture environment is required")
    quiet = Path.home() / "Applications/GodotQuiet.app/Contents/MacOS/Godot"
    if not quiet.is_file():
        raise RuntimeError("GodotQuiet is required; no ordinary-window fallback")
    output = AUDIT / ("modal_order" if group == "modal" else group) / phase
    output.mkdir(parents=True, exist_ok=True)
    rows = []
    screens = list(cases(group))
    for index, (route, payload, label) in enumerate(screens, 1):
        path = output / f"{label}.png"
        code, issues, log = visual.capture(route, payload, path)
        if code == 0:
            issues += visual.analyze(path, label, tuple(payload.get("viewport_size", [1080, 1920])))
        (output / f"{label}.log").write_text(log, encoding="utf-8")
        rows.append({"route": route, "label": label, "payload": payload, "capture_exit": code, "issues": issues, "png": path.name})
        (output / "manifest.json").write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"[{index}/{len(screens)}] {label}: exit={code} issues={issues}", flush=True)
    return int(any(row["capture_exit"] or row["issues"] for row in rows))


if __name__ == "__main__":
    raise SystemExit(main())
