#!/usr/bin/env python3
from __future__ import annotations

import json
import math
import os
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
EXPECTED_SIZE = (1080, 1920)
TALL_SCREEN_LABEL_PREFIXES = (
    "battle_tall",
    "result_tall",
    "pause_tall",
    "card_offer_tall",
    "collection_detail_tall",
    "menu_tall",
    "map_tall",
    "loadout_tall",
    "collection_tall",
    "settings_tall",
)
DEBUG_SAFE_INSETS = [44, 132, 44, 102]
SPEED_BUTTON_SAVE_OVERRIDE = {
    "unlocks": {"levels": [f"level_{level_no:03d}" for level_no in range(1, 51)]},
}
MIN_LUMA_STDEV = {
    "map": 20.0,
    "map_chapter": 20.0,
    "loadout": 20.0,
    "collection_characters": 18.0,
}

TALL_BATTLE_LEVELS: list[tuple[str, str]] = [
    ("env_lava_foundry", "level_001"),
    ("env_glacier_pass", "level_011"),
    ("env_abandoned_factory", "level_021"),
    ("env_toxic_biolab", "level_031"),
    ("env_storm_substation", "level_041"),
    ("env_flooded_subway", "level_051"),
    ("env_desert_refinery", "level_061"),
    ("env_void_cathedral", "level_071"),
    ("env_orbital_ruins", "level_081"),
    ("env_apex_core", "level_091"),
]

BASE_SCREENS: list[tuple[str, dict, str]] = [
    ("menu", {}, "menu"),
    ("map", {}, "map"),
    ("map", {"chapter": 1}, "map_chapter"),
    ("loadout", {"level_id": "level_003"}, "loadout"),
    (
        "loadout",
        {"level_id": "level_003", "equipment": {"selected_armor": "", "selected_chip": "", "selected_pet": ""}},
        "loadout_empty_slots",
    ),
    *[
        (
            "loadout",
            {"level_id": "level_003", "equipment": {"selected_character": character_id}},
            f"loadout_character_{character_id}",
        )
        for character_id in ["vanguard", "blaze", "frost", "volt"]
    ],
    ("collection", {"mode": "characters"}, "collection_characters"),
    ("collection", {"mode": "weapons"}, "collection_weapons_locked"),
    ("collection", {"mode": "skills"}, "collection_skills_info"),
    ("settings", {}, "settings"),
    ("battle", {"level_id": "level_001"}, "battle"),
    (
        "result",
        {"level_id": "level_003", "victory": True, "stars": 2, "gold": 120, "xp": 20, "next_level": "level_004"},
        "result",
    ),
]

SCREENS: list[tuple[str, dict, str]] = (
    BASE_SCREENS[:-1]
    + [
        ("battle", {"level_id": level_id, "viewport_size": [1080, 2340]}, f"battle_tall_{env_id}")
        for env_id, level_id in TALL_BATTLE_LEVELS
    ]
    + [
        (
            "result",
            {
                "level_id": "level_004",
                "victory": True,
                "challenge": True,
                "stars": 3,
                "gold": 686,
                "xp": 458,
                "viewport_size": [1080, 2340],
            },
            "result_tall_challenge",
        ),
        ("battle", {"level_id": "level_075", "pause": True, "viewport_size": [1080, 2340]}, "pause_tall"),
        ("battle", {"level_id": "level_001", "card_offer": True, "viewport_size": [1080, 2340]}, "card_offer_tall"),
        (
            "battle",
            {
                "level_id": "level_091",
                "viewport_size": [1080, 2340],
                "_visual_safe_insets": DEBUG_SAFE_INSETS,
                "save_override": SPEED_BUTTON_SAVE_OVERRIDE,
            },
            "battle_tall_safe_area",
        ),
        (
            "menu",
            {"viewport_size": [1080, 2340], "_visual_safe_insets": DEBUG_SAFE_INSETS},
            "menu_tall_safe_area",
        ),
        (
            "map",
            {"viewport_size": [1080, 2340], "_visual_safe_insets": DEBUG_SAFE_INSETS},
            "map_tall_safe_area",
        ),
        (
            "map",
            {"chapter": 1, "viewport_size": [1080, 2340], "_visual_safe_insets": DEBUG_SAFE_INSETS},
            "map_tall_chapter_safe_area",
        ),
        (
            "loadout",
            {
                "level_id": "level_003",
                "equipment": {"selected_armor": "", "selected_chip": "", "selected_pet": ""},
                "viewport_size": [1080, 2340],
                "_visual_safe_insets": DEBUG_SAFE_INSETS,
            },
            "loadout_tall_safe_area",
        ),
        (
            "collection",
            {
                "mode": "characters",
                "viewport_size": [1080, 2340],
                "_visual_safe_insets": DEBUG_SAFE_INSETS,
            },
            "collection_tall_characters_safe_area",
        ),
        *[
            (
                "collection",
                {
                    "mode": "characters",
                    "detail_item": character_id,
                    "viewport_size": [1080, 2340],
                    "_visual_safe_insets": DEBUG_SAFE_INSETS,
                },
                f"collection_detail_tall_character_{character_id}_safe_area",
            )
            for character_id in ["vanguard", "blaze", "frost", "volt"]
        ],
        (
            "settings",
            {"viewport_size": [1080, 2340], "_visual_safe_insets": DEBUG_SAFE_INSETS},
            "settings_tall_safe_area",
        ),
        ("menu", {"_visual_safe_insets": DEBUG_SAFE_INSETS}, "menu_safe_area"),
        ("map", {"_visual_safe_insets": DEBUG_SAFE_INSETS}, "map_safe_area"),
        (
            "loadout",
            {
                "level_id": "level_003",
                "equipment": {"selected_armor": "", "selected_chip": "", "selected_pet": ""},
                "_visual_safe_insets": DEBUG_SAFE_INSETS,
            },
            "loadout_safe_area",
        ),
        ("collection", {"mode": "skills", "_visual_safe_insets": DEBUG_SAFE_INSETS}, "collection_skills_safe_area"),
        (
            "collection",
            {
                "mode": "skills",
                "detail_item": "skill_split_shot",
                "viewport_size": [1080, 2340],
                "_visual_safe_insets": DEBUG_SAFE_INSETS,
            },
            "collection_detail_tall_safe_area",
        ),
        ("settings", {"_visual_safe_insets": DEBUG_SAFE_INSETS}, "settings_safe_area"),
        (
            "result",
            {
                "level_id": "level_004",
                "victory": True,
                "challenge": True,
                "stars": 3,
                "gold": 686,
                "xp": 458,
                "viewport_size": [1080, 2340],
                "_visual_safe_insets": DEBUG_SAFE_INSETS,
            },
            "result_tall_safe_area",
        ),
    ]
    + BASE_SCREENS[-1:]
)


def capture(route: str, payload: dict, out_path: Path) -> tuple[int, list[str], str]:
    runtime_payload = dict(payload)
    safe_insets = runtime_payload.pop("_visual_safe_insets", None)
    command = [
        "godot",
        "--path",
        ".",
        "--script",
        "res://tools/_shot.gd",
        "--",
        route,
        json.dumps(runtime_payload, ensure_ascii=False),
        str(out_path),
    ]
    env = os.environ.copy()
    env["ZOMBIE_FIRE_UI_AUDIT"] = "1"
    if safe_insets:
        env["ZOMBIE_FIRE_DEBUG_SAFE_INSETS"] = ",".join(str(value) for value in safe_insets)
    else:
        env.pop("ZOMBIE_FIRE_DEBUG_SAFE_INSETS", None)
    try:
        result = subprocess.run(command, cwd=ROOT, timeout=25, env=env, capture_output=True, text=True)
    except subprocess.TimeoutExpired:
        return 124, [], "capture timed out"
    audit_issues: list[str] = []
    audit_seen = route == "battle"
    for line in result.stdout.splitlines():
        if not line.startswith("UI_AUDIT_JSON:"):
            continue
        try:
            report = json.loads(line.removeprefix("UI_AUDIT_JSON:"))
        except json.JSONDecodeError:
            continue
        if report.get("route") == route:
            audit_seen = True
            audit_issues = [str(issue) for issue in report.get("issues", [])]
    if result.returncode == 0 and not audit_seen:
        audit_issues.append(f"{route} did not emit a runtime UI audit")
    combined_output = "\n".join(part for part in [result.stdout.strip(), result.stderr.strip()] if part)
    return result.returncode, audit_issues, combined_output


def check_layout_contracts() -> list[str]:
    errors: list[str] = []
    project_text = (ROOT / "project.godot").read_text(encoding="utf-8")
    if 'window/stretch/mode="canvas_items"' not in project_text:
        errors.append("project.godot must keep canvas_items stretch mode")
    if 'window/stretch/aspect="expand"' not in project_text:
        errors.append("project.godot must expand the 1080x1920 world to fill tall displays")
    implementation = "\n".join(
        (ROOT / path).read_text(encoding="utf-8")
        for path in ["main.gd", "meta/collection/collection.gd"]
    )
    if "minf(top, 120.0)" in implementation or "minf(maxf(float(safe.position" in implementation:
        errors.append("safe-area handling regressed to the old 120px hard clamp")
    return errors


def analyze(path: Path, label: str) -> list[str]:
    errors: list[str] = []
    if not path.exists():
        return [f"{label} screenshot was not written"]
    with Image.open(path) as source:
        image = source.convert("RGB")
    if label.startswith(TALL_SCREEN_LABEL_PREFIXES):
        if image.size[0] != EXPECTED_SIZE[0] or image.size[1] <= EXPECTED_SIZE[1]:
            errors.append(f"{label} screenshot must exercise a viewport taller than 1920px, got {image.size}")
    elif image.size != EXPECTED_SIZE:
        errors.append(f"{label} screenshot size must be {EXPECTED_SIZE}, got {image.size}")

    pixels = list(image.getdata())
    count = max(1, len(pixels))
    luminance = [(r * 0.2126 + g * 0.7152 + b * 0.0722) for r, g, b in pixels]
    mean = sum(luminance) / count
    variance = sum((value - mean) ** 2 for value in luminance) / count
    stdev = math.sqrt(variance)
    exact_black = sum(1 for r, g, b in pixels if r < 3 and g < 3 and b < 3) / count

    min_stdev = max(5.0, MIN_LUMA_STDEV.get(label, 5.0))
    if mean < 6.0 or stdev < min_stdev:
        errors.append(f"{label} screenshot looks blank or missing UI layers; mean={mean:.1f} stdev={stdev:.1f} min_stdev={min_stdev:.1f}")
    if exact_black > 0.35:
        errors.append(f"{label} screenshot has too much exact black area; black={exact_black:.2%}")
    if label.startswith("battle_tall"):
        top_h = min(320, image.size[1])
        top_pixels = list(image.crop((0, 0, image.size[0], top_h)).getdata())
        top_count = max(1, len(top_pixels))
        top_luma = [(r * 0.2126 + g * 0.7152 + b * 0.0722) for r, g, b in top_pixels]
        top_mean = sum(top_luma) / top_count
        top_variance = sum((value - top_mean) ** 2 for value in top_luma) / top_count
        top_stdev = math.sqrt(top_variance)
        top_dark = sum(1 for value in top_luma if value < 18.0) / top_count
        if top_dark > 0.72 and top_mean < 22.0 and top_stdev < 24.0:
            errors.append(
                f"{label} top band still reads as a dark blank strip; "
                f"mean={top_mean:.1f} stdev={top_stdev:.1f} dark<18={top_dark:.2%}"
            )
        play_band = image.crop((0, min(120, image.size[1] - 1), image.size[0], min(260, image.size[1])))
        play_pixels = list(play_band.getdata())
        play_count = max(1, len(play_pixels))
        play_luma = [(r * 0.2126 + g * 0.7152 + b * 0.0722) for r, g, b in play_pixels]
        play_mean = sum(play_luma) / play_count
        play_variance = sum((value - play_mean) ** 2 for value in play_luma) / play_count
        play_stdev = math.sqrt(play_variance)
        play_dark = sum(1 for value in play_luma if value < 18.0) / play_count
        if play_dark > 0.70 and play_mean < 22.0 and play_stdev < 24.0:
            errors.append(
                f"{label} playable top extension still looks like black filler; "
                f"mean={play_mean:.1f} stdev={play_stdev:.1f} dark<18={play_dark:.2%}"
            )
    return errors


def main() -> int:
    errors: list[str] = check_layout_contracts()
    with tempfile.TemporaryDirectory(prefix="zombie_fire_screens_") as tmp:
        tmp_dir = Path(tmp)
        for route, payload, label in SCREENS:
            out_path = tmp_dir / f"{label}.png"
            code, audit_issues, output = capture(route, payload, out_path)
            if code != 0:
                errors.append(f"{label} capture failed with exit code {code}")
                if output:
                    errors.append(f"{label} capture output: {output[-1200:]}")
                continue
            errors.extend(f"{label} runtime audit: {issue}" for issue in audit_issues)
            errors.extend(analyze(out_path, label))

    if errors:
        print("Visual screen check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(f"Visual screen check OK: {len(SCREENS)} routed screenshots")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
