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
    "card_detail_tall",
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
CARD_OFFER_REGRESSION_SKILLS = [
    "skill_incendiary",
    "skill_critical",
    "skill_slow_field",
]
LATE_MAP_SAVE_OVERRIDE = {
    "levels_progress": {f"level_{level_no:03d}": 1 for level_no in range(1, 89)},
    "unlocks": {"levels": [f"level_{level_no:03d}" for level_no in range(1, 90)]},
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

ALL_BOSSES = [
    "boss_tank_titan",
    "boss_inferno_maw",
    "boss_frost_warden",
    "boss_storm_caller",
    "boss_plague_mother",
    "boss_void_phantom",
    "boss_necrotitan",
    "boss_apex_overlord",
]

BOSS_ATTACK_CAPTURE_FRAMES = {
    "boss_tank_titan": 45,
    "boss_inferno_maw": 58,
    "boss_frost_warden": 65,
    "boss_storm_caller": 50,
    "boss_plague_mother": 55,
    "boss_void_phantom": 30,
    "boss_necrotitan": 60,
    "boss_apex_overlord": 60,
}

PET_SKILL_PETS = [
    "pet_turret_drone",
    "pet_fire_imp",
    "pet_frost_wisp",
    "pet_volt_orb",
    "pet_collector",
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
    (
        "collection",
        {"mode": "armors", "equipment": {"selected_armor": "armor_kevlar"}},
        "collection_armors",
    ),
    (
        "collection",
        {"mode": "chips", "equipment": {"selected_chip": "chip_attack"}},
        "collection_chips",
    ),
    (
        "collection",
        {"mode": "pets", "equipment": {"selected_pet": "pet_turret_drone"}},
        "collection_pets",
    ),
    ("collection", {"mode": "skills"}, "collection_skills_info"),
    ("settings", {}, "settings"),
    ("battle", {"level_id": "level_001"}, "battle"),
    (
        "result",
        {"level_id": "level_003", "victory": True, "stars": 2, "gold": 120, "xp": 20, "next_level": "level_004"},
        "result",
    ),
]

ENGLISH_SCREENS: list[tuple[str, dict, str]] = [
    ("menu", {"language": "en"}, "menu_en"),
    ("map", {"language": "en"}, "map_en"),
    ("map", {"language": "en", "chapter": 1}, "map_chapter_en"),
    ("loadout", {"language": "en", "level_id": "level_003"}, "loadout_en"),
    (
        "loadout",
        {
            "language": "en",
            "level_id": "level_099",
            "equipment": {"selected_armor": "", "selected_chip": "", "selected_pet": ""},
        },
        "loadout_severe_empty_en",
    ),
    ("collection", {"language": "en", "mode": "characters"}, "collection_characters_en"),
    ("collection", {"language": "en", "mode": "weapons"}, "collection_weapons_en"),
    ("collection", {"language": "en", "mode": "armors"}, "collection_armors_en"),
    ("collection", {"language": "en", "mode": "chips"}, "collection_chips_en"),
    ("collection", {"language": "en", "mode": "pets"}, "collection_pets_en"),
    ("collection", {"language": "en", "mode": "skills"}, "collection_skills_en"),
    (
        "collection",
        {
            "language": "en",
            "mode": "characters",
            "purchase_item": "blaze",
            "save_override": {"player": {"star": 99}},
        },
        "collection_character_purchase_en",
    ),
    (
        "collection",
        {
            "language": "en",
            "mode": "characters",
            "detail_item": "vanguard",
            "viewport_size": [1080, 2340],
        },
        "collection_tall_en_character_detail",
    ),
    (
        "collection",
        {
            "language": "en",
            "mode": "skills",
            "detail_item": "skill_split_shot",
            "viewport_size": [1080, 2340],
        },
        "collection_tall_en_skill_detail",
    ),
    ("settings", {"language": "en"}, "settings_en"),
    *[
        (
            "battle",
            {
                "language": "en",
                "level_id": "level_001",
                "equipment": {"selected_character": character_id, "selected_weapon": weapon_id},
                "debug_character_skill_hint": True,
            },
            f"battle_character_skill_hint_{character_id}_en",
        )
        for character_id, weapon_id in [
            ("vanguard", "weapon_autocannon"),
            ("blaze", "weapon_flamethrower"),
            ("frost", "weapon_cryocannon"),
            ("volt", "weapon_teslacoil"),
        ]
    ],
    (
        "battle",
        {
            "language": "en",
            "level_id": "level_005",
            "debug_spawn_boss": "boss_tank_titan",
            "debug_clean_boss_stage": True,
            "debug_boss_phase": True,
        },
        "battle_boss_phase_en",
    ),
    ("battle", {"language": "en", "level_id": "level_075", "pause": True}, "pause_en"),
    (
        "battle",
        {
            "language": "en",
            "level_id": "level_001",
            "card_offer": True,
            "debug_card_offer_skills": CARD_OFFER_REGRESSION_SKILLS,
        },
        "card_offer_en",
    ),
    (
        "battle",
        {"language": "en", "level_id": "level_075", "pause": True, "viewport_size": [1080, 2340]},
        "pause_tall_en",
    ),
    (
        "battle",
        {
            "language": "en",
            "level_id": "level_001",
            "card_offer": True,
            "debug_card_offer_skills": CARD_OFFER_REGRESSION_SKILLS,
            "viewport_size": [1080, 2340],
        },
        "card_offer_tall_en",
    ),
    (
        "battle",
        {
            "language": "en",
            "level_id": "level_001",
            "card_detail": "skill_split_shot",
            "viewport_size": [1080, 2340],
        },
        "card_detail_tall_en",
    ),
    (
        "result",
        {
            "language": "en",
            "level_id": "level_004",
            "victory": True,
            "challenge": True,
            "stars": 3,
            "gold": 686,
            "xp": 458,
            "viewport_size": [1080, 2340],
        },
        "result_tall_en",
    ),
]

NEON_PREVIEW_SCREENS: list[tuple[str, dict, str]] = [
    (
        "menu",
        {"save_override": {"cosmetics": {"selected_theme": "neon_tempest"}}},
        "menu_neon_preview",
    ),
    (
        "settings",
        {"save_override": {"cosmetics": {"selected_theme": "neon_tempest"}}},
        "settings_neon_preview",
    ),
    (
        "collection",
        {
            "mode": "characters",
            "save_override": {"cosmetics": {"selected_theme": "neon_tempest"}},
        },
        "collection_characters_neon_preview",
    ),
    *[
        (
            "loadout",
            {
                "level_id": "level_003",
                "save_override": {"cosmetics": {"selected_theme": "neon_tempest"}},
                "equipment": {"selected_character": character_id, "selected_weapon": weapon_id},
            },
            f"loadout_neon_{character_id}",
        )
        for character_id, weapon_id in [
            ("vanguard", "weapon_autocannon"),
            ("blaze", "weapon_flamethrower"),
            ("frost", "weapon_cryocannon"),
            ("volt", "weapon_teslacoil"),
        ]
    ],
    *[
        (
            "battle",
            {
                "level_id": "level_001",
                "save_override": {"cosmetics": {"selected_theme": "neon_tempest"}},
                "equipment": {"selected_character": character_id, "selected_weapon": weapon_id},
                "debug_character_shooting_frame": 4,
                "debug_character_shooting_aim": "center",
                "debug_character_shooting_muzzle": True,
            },
            f"battle_neon_shooting_{character_id}_{weapon_id.removeprefix('weapon_')}",
        )
        for character_id in ["vanguard", "blaze", "frost", "volt"]
        for weapon_id in [
            "weapon_autocannon",
            "weapon_flamethrower",
            "weapon_cryocannon",
            "weapon_teslacoil",
            "weapon_toxic_launcher",
            "weapon_railgun",
            "weapon_shotgun",
            "weapon_plasma_cannon",
        ]
    ],
    *[
        (
            "battle",
            {
                "level_id": "level_001",
                "save_override": {"cosmetics": {"selected_theme": "neon_tempest"}},
                "equipment": {"selected_character": character_id, "selected_weapon": weapon_id},
                "debug_cast_active": True,
                "warmup_frames": 3,
            },
            f"battle_neon_active_{character_id}",
        )
        for character_id, weapon_id in [
            ("vanguard", "weapon_autocannon"),
            ("blaze", "weapon_flamethrower"),
            ("frost", "weapon_cryocannon"),
            ("volt", "weapon_teslacoil"),
        ]
    ],
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
        (
            "battle",
            {
                "level_id": "level_001",
                "card_offer": True,
                "debug_card_offer_skills": CARD_OFFER_REGRESSION_SKILLS,
                "viewport_size": [1080, 2340],
            },
            "card_offer_tall",
        ),
        (
            "battle",
            {"level_id": "level_001", "card_detail": "skill_split_shot", "viewport_size": [1080, 2340]},
            "card_detail_tall",
        ),
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
            "battle",
            {
                "level_id": "level_075",
                "viewport_size": [1080, 2340],
                "debug_dense_combat": True,
                "warmup_frames": 12,
            },
            "battle_tall_dense_information",
        ),
        (
            "battle",
            {
                "level_id": "level_001",
                "debug_zombie_model_showcase": "redesigned",
                "warmup_frames": 6,
            },
            "battle_zombie_models_redesigned",
        ),
        (
            "battle",
            {
                "level_id": "level_001",
                "debug_zombie_model_showcase": "roster",
                "warmup_frames": 6,
            },
            "battle_zombie_models_roster",
        ),
        (
            "battle",
            {
                "level_id": "level_001",
                "debug_zombie_model_showcase": "dense",
                "warmup_frames": 6,
            },
            "battle_zombie_models_dense",
        ),
        (
            "battle",
            {
                "level_id": "level_001",
                "viewport_size": [1080, 2340],
                "debug_zombie_model_showcase": "redesigned",
                "warmup_frames": 6,
            },
            "battle_tall_zombie_models_redesigned",
        ),
        *[
            (
                "battle",
                {
                    "level_id": "level_001",
                    "debug_zombie_attack_showcase": group,
                    "warmup_frames": 4,
                },
                f"battle_zombie_attack_group_{group + 1}",
            )
            for group in range(4)
        ],
        *[
            (
                "battle",
                {
                    "level_id": "level_050",
                    "equipment": {"selected_pet": pet_id, pet_id: 30},
                    "debug_pet_skill": True,
                },
                f"battle_pet_skill_{pet_id}",
            )
            for pet_id in PET_SKILL_PETS
        ],
        *[
            (
                "battle",
                {
                    "level_id": "level_091",
                    "viewport_size": [1080, 2340],
                    "debug_spawn_boss": boss_id,
                    "debug_clean_boss_stage": True,
                    "debug_boss_showcase": True,
                    "warmup_frames": 30,
                },
                f"battle_tall_boss_showcase_{boss_id}",
            )
            for boss_id in ALL_BOSSES
        ],
        *[
            (
                "battle",
                {
                    "level_id": "level_091",
                    "viewport_size": [1080, 2340],
                    "debug_spawn_boss": boss_id,
                    "debug_clean_boss_stage": True,
                    "debug_boss_base_attack": True,
                    "warmup_frames": BOSS_ATTACK_CAPTURE_FRAMES[boss_id],
                },
                f"battle_tall_boss_base_attack_{boss_id}",
            )
            for boss_id in ALL_BOSSES
        ],
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
            "map",
            {
                "viewport_size": [1080, 2340],
                "_visual_safe_insets": DEBUG_SAFE_INSETS,
                "save_override": LATE_MAP_SAVE_OVERRIDE,
            },
            "map_tall_current_chapter_focus",
        ),
        (
            "map",
            {
                "chapter": 9,
                "viewport_size": [1080, 2340],
                "_visual_safe_insets": DEBUG_SAFE_INSETS,
                "save_override": LATE_MAP_SAVE_OVERRIDE,
            },
            "map_tall_current_level_focus",
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
            "collection",
            {
                "mode": "weapons",
                "detail_item": "weapon_autocannon",
                "viewport_size": [1080, 2340],
                "_visual_safe_insets": DEBUG_SAFE_INSETS,
            },
            "collection_detail_tall_weapon_safe_area",
        ),
        (
            "collection",
            {
                "mode": "armors",
                "detail_item": "armor_kevlar",
                "equipment": {"selected_armor": "armor_kevlar"},
                "viewport_size": [1080, 2340],
                "_visual_safe_insets": DEBUG_SAFE_INSETS,
            },
            "collection_detail_tall_armor_safe_area",
        ),
        (
            "collection",
            {
                "mode": "chips",
                "detail_item": "chip_attack",
                "equipment": {"selected_chip": "chip_attack"},
                "viewport_size": [1080, 2340],
                "_visual_safe_insets": DEBUG_SAFE_INSETS,
            },
            "collection_detail_tall_chip_safe_area",
        ),
        (
            "collection",
            {
                "mode": "pets",
                "detail_item": "pet_medic_drone",
                "equipment": {"selected_pet": "pet_medic_drone", "pet_medic_drone": 30},
                "viewport_size": [1080, 2340],
                "_visual_safe_insets": DEBUG_SAFE_INSETS,
            },
            "collection_detail_tall_medic_pet_safe_area",
        ),
        *[
            (
                "collection",
                {
                    "mode": "pets",
                    "detail_item": pet_id,
                    "equipment": {"selected_pet": pet_id, pet_id: 30},
                    "viewport_size": [1080, 2340],
                    "_visual_safe_insets": DEBUG_SAFE_INSETS,
                },
                f"collection_detail_tall_{pet_id}_safe_area",
            )
            for pet_id in PET_SKILL_PETS
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
    + ENGLISH_SCREENS
    + BASE_SCREENS[-1:]
)


def capture(route: str, payload: dict, out_path: Path) -> tuple[int, list[str], str]:
    runtime_payload = dict(payload)
    # Keep the baseline matrix deterministic on non-Chinese developer machines.
    # English routes opt in explicitly; every other route is the Chinese proof.
    runtime_payload.setdefault("language", "zh")
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
    effective_code = result.returncode
    fatal_markers = (
        "SCRIPT ERROR:",
        "Failed to load script",
        "Compile Error:",
        "Parse Error:",
    )
    if effective_code == 0 and any(marker in combined_output for marker in fatal_markers):
        effective_code = 3
    return effective_code, audit_issues, combined_output


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
    if "--english-only" in sys.argv[1:]:
        active_screens = ENGLISH_SCREENS
    elif "--neon-only" in sys.argv[1:]:
        active_screens = NEON_PREVIEW_SCREENS
    else:
        active_screens = SCREENS
    with tempfile.TemporaryDirectory(prefix="zombie_fire_screens_") as tmp:
        tmp_dir = Path(tmp)
        for route, payload, label in active_screens:
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
    print(f"Visual screen check OK: {len(active_screens)} routed screenshots")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
