#!/usr/bin/env python3
from __future__ import annotations

import json
import math
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
EXPECTED_SIZE = (1080, 1920)
TALL_SCREEN_LABEL_PREFIXES = (
    "typography_tall",
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
    "store_tall",
    "armor_prototypes",
    "character_detail_readability_owner_tall",
    "character_detail_readability_compact_tall",
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
HUD_SKILL_REVIEW_SKILLS = [
    "skill_split_shot",
    "skill_pierce",
    "skill_multishot",
    "skill_slow_field",
    "skill_homing",
    "skill_critical",
    "skill_barrier",
    "skill_gold_rush",
    "skill_ricochet",
    "skill_salvo",
    "skill_incendiary",
    "skill_cryo",
    "skill_tesla",
    "skill_venom",
    "skill_charge_shot",
    "skill_recycle",
]


def _data_ids(table: str) -> list[str]:
    parsed = json.loads((ROOT / "data" / f"{table}.json").read_text(encoding="utf-8"))
    if not isinstance(parsed, dict):
        raise ValueError(f"data/{table}.json must be an id-keyed object")
    return [str(value) for value in parsed.keys()]


def _theme_ids() -> list[str]:
    parsed = json.loads((ROOT / "data" / "themes.json").read_text(encoding="utf-8"))
    rows = parsed.get("themes", []) if isinstance(parsed, dict) else []
    if not isinstance(rows, list):
        raise ValueError("data/themes.json themes must be a list")
    return [str(row.get("id", "")) for row in rows if isinstance(row, dict) and str(row.get("id", ""))]


SKILL_IDS = _data_ids("skills")
CHARACTER_IDS = _data_ids("characters")
WEAPON_IDS = _data_ids("weapons")
STANDARD_WEAPON_IDS = [weapon_id for weapon_id in WEAPON_IDS if not weapon_id.startswith("weapon_apocalypse_")]
THEME_IDS = _theme_ids()
COLLECTION_IDS = {
    mode: _data_ids(table)
    for mode, table in {
        "characters": "characters",
        "weapons": "weapons",
        "armors": "armors",
        "chips": "chips",
        "pets": "pets",
        "skills": "skills",
    }.items()
}
STORE_PRODUCT_IDS = _data_ids("store_products")
LATE_MAP_SAVE_OVERRIDE = {
    "levels_progress": {f"level_{level_no:03d}": 1 for level_no in range(1, 89)},
    "unlocks": {"levels": [f"level_{level_no:03d}" for level_no in range(1, 90)]},
}
FULL_STORE_SAVE_OVERRIDE = {
    "levels_progress": {f"level_{level_no:03d}": 1 for level_no in range(1, 100)},
    "unlocks": {"levels": [f"level_{level_no:03d}" for level_no in range(1, 100)]},
    "commerce": {"mock_receipts": [], "mock_last_transaction_unix": 0},
    "entitlements": {"verified": [], "last_sync_unix": 0},
    "cosmetics": {"selected_theme": "default"},
    "equipment": {
        "vanguard": 40,
        "blaze": 40,
        "frost": 40,
        "volt": 40,
    },
}
NEON_THEME_OWNED_OVERRIDE = {
    "commerce": {
        "mock_receipts": ["com.gaojiasheng.zombiefire.theme.neon_tempest"],
        "mock_last_transaction_unix": 0,
    },
    "cosmetics": {"selected_theme": "default"},
}
NEON_THEME_ACTIVE_OVERRIDE = {
    "commerce": {
        "mock_receipts": ["com.gaojiasheng.zombiefire.theme.neon_tempest"],
        "mock_last_transaction_unix": 0,
    },
    "cosmetics": {
        "selected_theme": "neon_tempest",
        "character_outfits": {
            "vanguard": "follow_theme",
            "blaze": "follow_theme",
            "frost": "follow_theme",
            "volt": "follow_theme",
        },
    },
}
INFERNAL_THEME_ACTIVE_OVERRIDE = {
    "commerce": {
        "mock_receipts": ["com.gaojiasheng.zombiefire.theme.infernal_dominion"],
        "mock_last_transaction_unix": 0,
    },
    "cosmetics": {
        "selected_theme": "infernal_dominion",
        "character_outfits": {
            "vanguard": "follow_theme",
            "blaze": "follow_theme",
            "frost": "follow_theme",
            "volt": "follow_theme",
        },
    },
}
POLAR_THEME_ACTIVE_OVERRIDE = {
    "commerce": {
        "mock_receipts": ["com.gaojiasheng.zombiefire.theme.polar_aurora"],
        "mock_last_transaction_unix": 0,
    },
    "cosmetics": {
        "selected_theme": "polar_aurora",
        "character_outfits": {
            "vanguard": "follow_theme",
            "blaze": "follow_theme",
            "frost": "follow_theme",
            "volt": "follow_theme",
        },
    },
}
GILDED_THEME_ACTIVE_OVERRIDE = {
    "commerce": {
        "mock_receipts": ["com.gaojiasheng.zombiefire.theme.gilded_eclipse"],
        "mock_last_transaction_unix": 0,
    },
    "cosmetics": {
        "selected_theme": "gilded_eclipse",
        "character_outfits": {
            "vanguard": "follow_theme",
            "blaze": "follow_theme",
            "frost": "follow_theme",
            "volt": "follow_theme",
        },
    },
}
INFERNO_COMPLETE_OWNED_OVERRIDE = {
    "commerce": {
        "mock_receipts": ["com.gaojiasheng.zombiefire.arsenal.inferno_complete"],
        "mock_last_transaction_unix": 0,
    },
    "cosmetics": {
        "selected_theme": "infernal_dominion",
        "character_outfits": {
            "vanguard": "follow_theme",
            "blaze": "follow_theme",
            "frost": "follow_theme",
            "volt": "follow_theme",
        },
    },
    "equipment": {
        "weapon_apocalypse_inferno": 50,
        "armor_apocalypse_molten": 50,
        "chip_apocalypse_stellar": 50,
        "pet_apocalypse_phoenix": 50,
    },
}
INFERNO_EQUIPMENT = {
    "selected_character": "vanguard",
    "selected_weapon": "weapon_apocalypse_inferno",
    "selected_armor": "armor_apocalypse_molten",
    "selected_chip": "chip_apocalypse_stellar",
    "selected_pet": "pet_apocalypse_phoenix",
}
ABSOLUTE_ZERO_COMPLETE_OWNED_OVERRIDE = {
    "commerce": {
        "mock_receipts": ["com.gaojiasheng.zombiefire.arsenal.absolute_zero_complete"],
        "mock_last_transaction_unix": 0,
    },
    "cosmetics": {
        "selected_theme": "polar_aurora",
        "character_outfits": {
            "vanguard": "follow_theme",
            "blaze": "follow_theme",
            "frost": "follow_theme",
            "volt": "follow_theme",
        },
    },
    "equipment": {
        "weapon_apocalypse_absolute_zero": 50,
        "armor_apocalypse_permafrost": 35,
        "chip_apocalypse_entropy": 35,
        "pet_apocalypse_aurora": 30,
    },
}
ABSOLUTE_ZERO_EQUIPMENT = {
    "selected_character": "frost",
    "selected_weapon": "weapon_apocalypse_absolute_zero",
    "selected_armor": "armor_apocalypse_permafrost",
    "selected_chip": "chip_apocalypse_entropy",
    "selected_pet": "pet_apocalypse_aurora",
}
GOLDEN_LAW_COMPLETE_OWNED_OVERRIDE = {
    "commerce": {
        "mock_receipts": ["com.gaojiasheng.zombiefire.arsenal.golden_law_complete"],
        "mock_last_transaction_unix": 0,
    },
    "cosmetics": {
        "selected_theme": "gilded_eclipse",
        "character_outfits": {
            "vanguard": "follow_theme",
            "blaze": "follow_theme",
            "frost": "follow_theme",
            "volt": "follow_theme",
        },
    },
    "equipment": {
        "vanguard": 40,
        "weapon_apocalypse_golden_law": 50,
        "armor_apocalypse_eternal_night": 35,
        "chip_apocalypse_golden_law": 35,
        "pet_apocalypse_skyfalcon": 30,
    },
}
GOLDEN_LAW_EQUIPMENT = {
    "selected_character": "vanguard",
    "selected_weapon": "weapon_apocalypse_golden_law",
    "selected_armor": "armor_apocalypse_eternal_night",
    "selected_chip": "chip_apocalypse_golden_law",
    "selected_pet": "pet_apocalypse_skyfalcon",
}
PREMIUM_CROSS_SAVE_OVERRIDES = {
    theme_id: {
        "commerce": {
            "mock_receipts": [
                "com.gaojiasheng.zombiefire.arsenal.thunder_complete",
                "com.gaojiasheng.zombiefire.arsenal.inferno_complete",
                "com.gaojiasheng.zombiefire.arsenal.absolute_zero_complete",
                "com.gaojiasheng.zombiefire.arsenal.golden_law_complete",
            ],
            "mock_last_transaction_unix": 0,
        },
        "cosmetics": {
            "selected_theme": theme_id,
            "character_outfits": {
                "vanguard": "follow_theme",
                "blaze": "follow_theme",
                "frost": "follow_theme",
                "volt": "follow_theme",
            },
        },
        "equipment": {
            "weapon_apocalypse_thunder": 50,
            "armor_apocalypse_conductor": 35,
            "chip_apocalypse_superconductive": 35,
            "pet_apocalypse_tempest": 30,
            "weapon_apocalypse_inferno": 50,
            "armor_apocalypse_molten": 35,
            "chip_apocalypse_stellar": 35,
            "pet_apocalypse_phoenix": 30,
            "weapon_apocalypse_absolute_zero": 50,
            "armor_apocalypse_permafrost": 35,
            "chip_apocalypse_entropy": 35,
            "pet_apocalypse_aurora": 30,
            "weapon_apocalypse_golden_law": 50,
            "armor_apocalypse_eternal_night": 35,
            "chip_apocalypse_golden_law": 35,
            "pet_apocalypse_skyfalcon": 30,
        },
    }
    for theme_id in ["default", "neon_tempest", "infernal_dominion", "polar_aurora", "gilded_eclipse"]
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
    (
        "settings",
        {
            "debug_theme_appearance": True,
            "save_override": NEON_THEME_OWNED_OVERRIDE,
        },
        "settings_theme_appearance",
    ),
    (
        "collection",
        {
            "mode": "characters",
            "debug_character_appearance": "vanguard",
            "save_override": NEON_THEME_OWNED_OVERRIDE,
        },
        "collection_character_appearance",
    ),
    (
        "store",
        {
            "debug_complete_store_purchase": "com.gaojiasheng.zombiefire.theme.neon_tempest",
            "save_override": {
                "commerce": {"mock_receipts": [], "mock_last_transaction_unix": 0},
                "cosmetics": {"selected_theme": "default"},
            },
        },
        "store_purchase_complete",
    ),
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
    (
        "settings",
        {
            "language": "en",
            "debug_theme_appearance": True,
            "save_override": NEON_THEME_OWNED_OVERRIDE,
        },
        "settings_theme_appearance_en",
    ),
    (
        "collection",
        {
            "language": "en",
            "mode": "characters",
            "debug_character_appearance": "vanguard",
            "save_override": NEON_THEME_OWNED_OVERRIDE,
        },
        "collection_character_appearance_en",
    ),
    (
        "store",
        {
            "language": "en",
            "debug_complete_store_purchase": "com.gaojiasheng.zombiefire.theme.neon_tempest",
            "save_override": {
                "commerce": {"mock_receipts": [], "mock_last_transaction_unix": 0},
                "cosmetics": {"selected_theme": "default"},
            },
        },
        "store_purchase_complete_en",
    ),
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

BATTLE_SKILL_HUD_SCREENS: list[tuple[str, dict, str]] = [
    (
        "battle",
        {
            "level_id": "level_001",
            "debug_hud_skills": HUD_SKILL_REVIEW_SKILLS[:6],
        },
        "battle_skill_dock_zh_two_rows",
    ),
    (
        "battle",
        {
            "language": "en",
            "level_id": "level_001",
            "debug_hud_skills": HUD_SKILL_REVIEW_SKILLS,
        },
        "battle_skill_dock_en_four_rows",
    ),
    (
        "battle",
        {
            "level_id": "level_001",
            "debug_hud_skills": HUD_SKILL_REVIEW_SKILLS[:6],
            "debug_character_skill_cooldown": 18.0,
            "debug_character_skill_hint": True,
        },
        "battle_active_skill_cooldown_detail_zh",
    ),
    (
        "battle",
        {
            "language": "en",
            "level_id": "level_001",
            "debug_hud_skills": HUD_SKILL_REVIEW_SKILLS[:6],
        },
        "battle_active_skill_ready_en",
    ),
    (
        "battle",
        {
            "level_id": "level_001",
            "debug_hud_skills": HUD_SKILL_REVIEW_SKILLS,
            "save_override": GILDED_THEME_ACTIVE_OVERRIDE,
        },
        "battle_skill_dock_gilded_four_rows_zh",
    ),
]

NEON_PREVIEW_SCREENS: list[tuple[str, dict, str]] = [
    (
        "menu",
        {"save_override": NEON_THEME_ACTIVE_OVERRIDE},
        "menu_neon_preview",
    ),
    (
        "settings",
        {"save_override": NEON_THEME_ACTIVE_OVERRIDE},
        "settings_neon_preview",
    ),
    (
        "collection",
        {
            "mode": "characters",
            "save_override": NEON_THEME_ACTIVE_OVERRIDE,
        },
        "collection_characters_neon_preview",
    ),
    *[
        (
            "loadout",
            {
                "level_id": "level_003",
                "save_override": NEON_THEME_ACTIVE_OVERRIDE,
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
                "save_override": NEON_THEME_ACTIVE_OVERRIDE,
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
            "weapon_venomlauncher",
            "weapon_railgun",
            "weapon_scattergun",
            "weapon_plasmacannon",
        ]
    ],
    *[
        (
            "battle",
            {
                "level_id": "level_001",
                "save_override": NEON_THEME_ACTIVE_OVERRIDE,
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

INFERNAL_PREVIEW_SCREENS: list[tuple[str, dict, str]] = [
    (
        "menu",
        {"save_override": INFERNAL_THEME_ACTIVE_OVERRIDE},
        "menu_infernal_preview",
    ),
    (
        "settings",
        {"save_override": INFERNAL_THEME_ACTIVE_OVERRIDE},
        "settings_infernal_preview",
    ),
    (
        "collection",
        {
            "mode": "characters",
            "save_override": INFERNAL_THEME_ACTIVE_OVERRIDE,
        },
        "collection_characters_infernal_preview",
    ),
    *[
        (
            "loadout",
            {
                "level_id": "level_003",
                "save_override": INFERNAL_THEME_ACTIVE_OVERRIDE,
                "equipment": {
                    "selected_character": character_id,
                    "selected_weapon": weapon_id,
                },
            },
            f"loadout_infernal_{character_id}",
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
                "save_override": INFERNAL_THEME_ACTIVE_OVERRIDE,
                "equipment": {
                    "selected_character": character_id,
                    "selected_weapon": weapon_id,
                },
                "debug_character_shooting_frame": 4,
                "debug_character_shooting_aim": "center",
                "debug_character_shooting_muzzle": True,
            },
            f"battle_infernal_shooting_{character_id}_{weapon_id.removeprefix('weapon_')}",
        )
        for character_id in ["vanguard", "blaze", "frost", "volt"]
        for weapon_id in [
            "weapon_autocannon",
            "weapon_flamethrower",
            "weapon_cryocannon",
            "weapon_teslacoil",
            "weapon_venomlauncher",
            "weapon_railgun",
            "weapon_scattergun",
            "weapon_plasmacannon",
        ]
    ],
    *[
        (
            "battle",
            {
                "level_id": "level_001",
                "save_override": INFERNAL_THEME_ACTIVE_OVERRIDE,
                "equipment": {
                    "selected_character": character_id,
                    "selected_weapon": weapon_id,
                },
                "debug_cast_active": True,
                "warmup_frames": 3,
            },
            f"battle_infernal_active_{character_id}",
        )
        for character_id, weapon_id in [
            ("vanguard", "weapon_autocannon"),
            ("blaze", "weapon_flamethrower"),
            ("frost", "weapon_cryocannon"),
            ("volt", "weapon_teslacoil"),
        ]
    ],
]

POLAR_PREVIEW_SCREENS: list[tuple[str, dict, str]] = [
    ("menu", {"save_override": POLAR_THEME_ACTIVE_OVERRIDE}, "menu_polar_preview"),
    ("settings", {"save_override": POLAR_THEME_ACTIVE_OVERRIDE}, "settings_polar_preview"),
    (
        "collection",
        {"mode": "characters", "save_override": POLAR_THEME_ACTIVE_OVERRIDE},
        "collection_characters_polar_preview",
    ),
    *[
        (
            "loadout",
            {
                "level_id": "level_003",
                "save_override": POLAR_THEME_ACTIVE_OVERRIDE,
                "equipment": {"selected_character": character_id, "selected_weapon": weapon_id},
            },
            f"loadout_polar_{character_id}",
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
                "save_override": POLAR_THEME_ACTIVE_OVERRIDE,
                "equipment": {"selected_character": character_id, "selected_weapon": weapon_id},
                "debug_character_shooting_frame": 4,
                "debug_character_shooting_aim": "center",
                "debug_character_shooting_muzzle": True,
            },
            f"battle_polar_shooting_{character_id}_{weapon_id.removeprefix('weapon_')}",
        )
        for character_id in ["vanguard", "blaze", "frost", "volt"]
        for weapon_id in [
            "weapon_autocannon",
            "weapon_flamethrower",
            "weapon_cryocannon",
            "weapon_teslacoil",
            "weapon_venomlauncher",
            "weapon_railgun",
            "weapon_scattergun",
            "weapon_plasmacannon",
        ]
    ],
    *[
        (
            "battle",
            {
                "level_id": "level_001",
                "save_override": POLAR_THEME_ACTIVE_OVERRIDE,
                "equipment": {"selected_character": character_id, "selected_weapon": weapon_id},
                "debug_cast_active": True,
                "warmup_frames": 3,
            },
            f"battle_polar_active_{character_id}",
        )
        for character_id, weapon_id in [
            ("vanguard", "weapon_autocannon"),
            ("blaze", "weapon_flamethrower"),
            ("frost", "weapon_cryocannon"),
            ("volt", "weapon_teslacoil"),
        ]
    ],
]

GILDED_ECLIPSE_SCREENS: list[tuple[str, dict, str]] = [
    ("menu", {"save_override": GILDED_THEME_ACTIVE_OVERRIDE}, "menu_gilded_preview"),
    ("settings", {"save_override": GILDED_THEME_ACTIVE_OVERRIDE}, "settings_gilded_preview"),
    (
        "collection",
        {"mode": "characters", "save_override": GILDED_THEME_ACTIVE_OVERRIDE},
        "collection_characters_gilded_preview",
    ),
    *[
        (
            "loadout",
            {
                "level_id": "level_099",
                "save_override": GOLDEN_LAW_COMPLETE_OWNED_OVERRIDE,
                "equipment": GOLDEN_LAW_EQUIPMENT | {"selected_character": character_id},
            },
            f"loadout_gilded_{character_id}",
        )
        for character_id in ["vanguard", "blaze", "frost", "volt"]
    ],
    *[
        (
            "battle",
            {
                "level_id": "level_091",
                "save_override": GOLDEN_LAW_COMPLETE_OWNED_OVERRIDE,
                "equipment": GOLDEN_LAW_EQUIPMENT | {"selected_character": character_id},
                "debug_character_shooting_frame": 4,
                "debug_character_shooting_aim": aim,
                "debug_character_shooting_muzzle": True,
            },
            f"battle_gilded_golden_law_{character_id}_{aim}",
        )
        for character_id in ["vanguard", "blaze", "frost", "volt"]
        for aim in ["left", "center", "right"]
    ],
    *[
        (
            "battle",
            {
                "level_id": "level_091",
                "viewport_size": [1080, 2340],
                "save_override": GOLDEN_LAW_COMPLETE_OWNED_OVERRIDE,
                "equipment": GOLDEN_LAW_EQUIPMENT,
                "debug_golden_law_vfx_showcase": mode,
            },
            f"battle_tall_golden_law_{mode}",
        )
        for mode in ["judgment", "verdict", "decree", "falcon", "counter", "awakening"]
    ],
    (
        "store",
        {
            "language": "en",
            "viewport_size": [1080, 2340],
            "debug_scroll_y": 2180,
            "debug_store_confirm_product": "com.gaojiasheng.zombiefire.arsenal.golden_law_complete",
            "save_override": {
                "levels_progress": {"level_099": 3},
                "equipment": {"vanguard": 40},
                "commerce": {"mock_receipts": []},
                "cosmetics": {"selected_theme": "default"},
            },
        },
        "store_tall_golden_law_confirm_en",
    ),
]

THEME_MENU_SCREENS: list[tuple[str, dict, str]] = [
    (
        "menu",
        {
            "save_override": {
                "commerce": {"mock_receipts": []},
                "cosmetics": {"selected_theme": "default"},
            }
        },
        "menu_logo_default",
    ),
    ("menu", {"save_override": NEON_THEME_ACTIVE_OVERRIDE}, "menu_logo_neon"),
    ("menu", {"save_override": INFERNAL_THEME_ACTIVE_OVERRIDE}, "menu_logo_infernal"),
    ("menu", {"save_override": POLAR_THEME_ACTIVE_OVERRIDE}, "menu_logo_polar"),
    ("menu", {"save_override": GILDED_THEME_ACTIVE_OVERRIDE}, "menu_logo_gilded"),
]

SKILL_TAG_THEME_SCREENS: list[tuple[str, dict, str]] = [
    (
        "collection",
        {
            **({"language": language} if language == "en" else {}),
            "mode": "skills",
            "save_override": save_override,
        },
        f"collection_skill_tags_{theme_id}_{language}",
    )
    for theme_id, save_override in [
        (
            "default",
            {
                "commerce": {"mock_receipts": []},
                "cosmetics": {"selected_theme": "default"},
            },
        ),
        ("neon", NEON_THEME_ACTIVE_OVERRIDE),
        ("infernal", INFERNAL_THEME_ACTIVE_OVERRIDE),
        ("polar", POLAR_THEME_ACTIVE_OVERRIDE),
        ("gilded", GILDED_THEME_ACTIVE_OVERRIDE),
    ]
    for language in ["zh", "en"]
]

APP_STORE_VFX_SCREENS: list[tuple[str, dict, str]] = [
    (
        "battle",
        {
            "level_id": "level_001",
            "viewport_size": [1080, 2340],
            "debug_app_store_vfx_showcase": mode,
        },
        f"battle_tall_app_store_vfx_{mode}",
    )
    for mode in ["enrage", "levelup"]
]

PREMIUM_CROSS_THEME_SCREENS: list[tuple[str, dict, str]] = [
    (
        "battle",
        {
            "level_id": "level_001",
            "save_override": PREMIUM_CROSS_SAVE_OVERRIDES[theme_id],
            "equipment": {
                "selected_character": character_id,
                "selected_weapon": weapon_id,
            },
            "debug_character_shooting_frame": 4,
            "debug_character_shooting_aim": "center",
            "debug_character_shooting_muzzle": True,
        },
        (
            f"battle_cross_{theme_id}_{character_id}_"
            f"{weapon_id.removeprefix('weapon_')}"
        ),
    )
    for theme_id in ["neon_tempest", "infernal_dominion", "polar_aurora", "gilded_eclipse"]
    for weapon_id in ["weapon_apocalypse_thunder", "weapon_apocalypse_inferno", "weapon_apocalypse_absolute_zero", "weapon_apocalypse_golden_law"]
    for character_id in ["vanguard", "blaze", "frost", "volt"]
]

INFERNO_STEP45_SCREENS: list[tuple[str, dict, str]] = [
    (
        "store",
        {
            "viewport_size": [1080, 2340],
            "debug_scroll_y": 920,
            "save_override": {
                "commerce": {"mock_receipts": [], "mock_last_transaction_unix": 0},
                "cosmetics": {"selected_theme": "default"},
            },
        },
        "store_tall_inferno_fresh_zh",
    ),
    (
        "store",
        {
            "language": "en",
            "viewport_size": [1080, 2340],
            "debug_scroll_y": 920,
            "save_override": {
                "commerce": {
                    "mock_receipts": ["com.gaojiasheng.zombiefire.theme.infernal_dominion"],
                    "mock_last_transaction_unix": 0,
                },
                "cosmetics": {"selected_theme": "infernal_dominion"},
            },
        },
        "store_tall_inferno_theme_upgrade_en",
    ),
    (
        "store",
        {
            "language": "en",
            "viewport_size": [1080, 2340],
            "debug_scroll_y": 920,
            "debug_store_confirm_product": "com.gaojiasheng.zombiefire.arsenal.inferno_complete",
            "save_override": {
                "commerce": {"mock_receipts": [], "mock_last_transaction_unix": 0},
                "cosmetics": {"selected_theme": "default"},
            },
        },
        "store_tall_inferno_confirm_en",
    ),
    (
        "store",
        {
            "viewport_size": [1080, 2340],
            "debug_scroll_y": 920,
            "save_override": INFERNO_COMPLETE_OWNED_OVERRIDE,
        },
        "store_tall_inferno_complete_owned_zh",
    ),
    (
        "store",
        {
            "language": "en",
            "viewport_size": [1080, 2340],
            "debug_complete_store_purchase": "com.gaojiasheng.zombiefire.arsenal.inferno_complete",
            "save_override": {
                "commerce": {"mock_receipts": [], "mock_last_transaction_unix": 0},
                "cosmetics": {"selected_theme": "default"},
            },
        },
        "store_tall_inferno_purchase_complete_en",
    ),
    *[
        (
            "battle",
            {
                "level_id": "level_001",
                "viewport_size": [1080, 2340],
                "save_override": INFERNO_COMPLETE_OWNED_OVERRIDE,
                "equipment": INFERNO_EQUIPMENT,
                "debug_inferno_vfx_showcase": mode,
            },
            f"battle_tall_inferno_{mode}",
        )
        for mode in [
            "burn",
            "combustion_center",
            "combustion_left",
            "combustion_boss",
            "spread",
            "phoenix",
            "counter",
            "awakening",
        ]
    ],
    (
        "battle",
        {
            "level_id": "level_001",
            "viewport_size": [1080, 2340],
            "settings_override": {"reduced_effects": True},
            "save_override": INFERNO_COMPLETE_OWNED_OVERRIDE,
            "equipment": INFERNO_EQUIPMENT,
            "debug_inferno_vfx_showcase": "combustion_center",
        },
        "battle_tall_inferno_combustion_reduced",
    ),
]

ABSOLUTE_ZERO_SCREENS: list[tuple[str, dict, str]] = [
    (
        "store",
        {
            "viewport_size": [1080, 2340],
            "debug_scroll_y": 1540,
            "save_override": {"commerce": {"mock_receipts": []}, "cosmetics": {"selected_theme": "default"}},
        },
        "store_tall_absolute_zero_fresh_zh",
    ),
    (
        "store",
        {
            "language": "en",
            "viewport_size": [1080, 2340],
            "debug_scroll_y": 1540,
            "debug_store_confirm_product": "com.gaojiasheng.zombiefire.arsenal.absolute_zero_complete",
            "save_override": {"commerce": {"mock_receipts": []}, "cosmetics": {"selected_theme": "default"}},
        },
        "store_tall_absolute_zero_confirm_en",
    ),
    (
        "store",
        {
            "language": "en",
            "viewport_size": [1080, 2340],
            "debug_complete_store_purchase": "com.gaojiasheng.zombiefire.arsenal.absolute_zero_complete",
            "save_override": {"commerce": {"mock_receipts": []}, "cosmetics": {"selected_theme": "default"}},
        },
        "store_tall_absolute_zero_purchase_complete_en",
    ),
    *[
        (
            "battle",
            {
                "level_id": "level_011",
                "viewport_size": [1080, 2340],
                "save_override": ABSOLUTE_ZERO_COMPLETE_OWNED_OVERRIDE,
                "equipment": ABSOLUTE_ZERO_EQUIPMENT,
                "debug_absolute_zero_vfx_showcase": mode,
            },
            f"battle_tall_absolute_zero_{mode}",
        )
        for mode in [
            "brittle",
            "shatter_center",
            "shatter_left",
            "shatter_boss",
            "wave",
            "field",
            "counter",
            "awakening",
        ]
    ],
]


def _file_label(value: str) -> str:
    return "".join(character if character.isalnum() or character in "_-" else "_" for character in value)


TYPOGRAPHY_SCREENS: list[tuple[str, dict, str]] = []
for language in ("zh", "en"):
    lang_payload = {"language": language}
    TYPOGRAPHY_SCREENS.extend(
        [
            ("menu", {**lang_payload, "viewport_size": [1080, 2340]}, f"typography_tall_{language}_menu"),
            ("map", {**lang_payload, "chapter": 9, "save_override": LATE_MAP_SAVE_OVERRIDE, "viewport_size": [1080, 2340]}, f"typography_tall_{language}_map_late"),
            (
                "loadout",
                {
                    **lang_payload,
                    "level_id": "level_099",
                    "equipment": {"selected_armor": "", "selected_chip": "", "selected_pet": ""},
                    "viewport_size": [1080, 2340],
                },
                f"typography_tall_{language}_loadout_worst_case",
            ),
            ("settings", {**lang_payload, "viewport_size": [1080, 2340]}, f"typography_tall_{language}_settings"),
            ("store", {**lang_payload, "viewport_size": [1080, 2340]}, f"typography_tall_{language}_store"),
            (
                "result",
                {
                    **lang_payload,
                    "level_id": "level_099",
                    "victory": True,
                    "challenge": True,
                    "stars": 3,
                    "gold": 987654,
                    "xp": 123456,
                    "viewport_size": [1080, 2340],
                },
                f"typography_tall_{language}_result",
            ),
            (
                "battle",
                {
                    **lang_payload,
                    "level_id": "level_099",
                    "debug_spawn_boss": "boss_apex_overlord",
                    "debug_clean_boss_stage": True,
                    "debug_typography_hud": True,
                    "viewport_size": [1080, 2340],
                },
                f"typography_tall_{language}_battle_hud",
            ),
            (
                "battle",
                {**lang_payload, "level_id": "level_099", "pause": True, "viewport_size": [1080, 2340]},
                f"typography_tall_{language}_pause",
            ),
        ]
    )
    for mode in COLLECTION_IDS:
        TYPOGRAPHY_SCREENS.append(
            (
                "collection",
                {**lang_payload, "mode": mode, "viewport_size": [1080, 2340]},
                f"typography_tall_{language}_collection_{mode}",
            )
        )
        for item_id in COLLECTION_IDS[mode]:
            TYPOGRAPHY_SCREENS.append(
                (
                    "collection",
                    {
                        **lang_payload,
                        "mode": mode,
                        "detail_item": item_id,
                        "viewport_size": [1080, 2340],
                    },
                    f"typography_tall_{language}_{mode}_detail_{_file_label(item_id)}",
                )
            )
    for skill_id in SKILL_IDS:
        TYPOGRAPHY_SCREENS.extend(
            [
                (
                    "battle",
                    {
                        **lang_payload,
                        "level_id": "level_001",
                        "debug_skill_hint": skill_id,
                        "viewport_size": [1080, 2340],
                    },
                    f"typography_tall_{language}_skill_hint_{skill_id}",
                ),
                (
                    "battle",
                    {
                        **lang_payload,
                        "level_id": "level_001",
                        "card_detail": skill_id,
                        "viewport_size": [1080, 2340],
                    },
                    f"typography_tall_{language}_card_detail_{skill_id}",
                ),
            ]
        )
    for batch_start in range(0, len(SKILL_IDS), 3):
        batch = SKILL_IDS[batch_start : batch_start + 3]
        TYPOGRAPHY_SCREENS.append(
            (
                "battle",
                {
                    **lang_payload,
                    "level_id": "level_001",
                    "card_offer": True,
                    "debug_card_offer_skills": batch,
                    "viewport_size": [1080, 2340],
                },
                f"typography_tall_{language}_card_offer_{batch_start // 3 + 1}",
            )
        )
    for character_id, weapon_id in [
        ("vanguard", "weapon_autocannon"),
        ("blaze", "weapon_flamethrower"),
        ("frost", "weapon_cryocannon"),
        ("volt", "weapon_teslacoil"),
    ]:
        TYPOGRAPHY_SCREENS.append(
            (
                "battle",
                {
                    **lang_payload,
                    "level_id": "level_001",
                    "equipment": {"selected_character": character_id, "selected_weapon": weapon_id},
                    "debug_character_skill_hint": True,
                    "viewport_size": [1080, 2340],
                },
                f"typography_tall_{language}_character_hint_{character_id}",
            )
        )
    for product_id in STORE_PRODUCT_IDS:
        TYPOGRAPHY_SCREENS.append(
            (
                "store",
                {
                    **lang_payload,
                    "viewport_size": [1080, 2340],
                    "debug_store_confirm_product": product_id,
                },
                f"typography_tall_{language}_store_confirm_{_file_label(product_id)}",
            )
        )

SCREENS: list[tuple[str, dict, str]] = (
    BASE_SCREENS[:-1]
    + BATTLE_SKILL_HUD_SCREENS
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
    + INFERNO_STEP45_SCREENS
    + ABSOLUTE_ZERO_SCREENS
    + GILDED_ECLIPSE_SCREENS
    + BASE_SCREENS[-1:]
)


THEME_MATCHING_WEAPONS = {
    "default": "weapon_autocannon",
    "neon_tempest": "weapon_apocalypse_thunder",
    "infernal_dominion": "weapon_apocalypse_inferno",
    "polar_aurora": "weapon_apocalypse_absolute_zero",
    "gilded_eclipse": "weapon_apocalypse_golden_law",
}
CHARACTER_MATCHING_WEAPONS = {
    "vanguard": "weapon_autocannon",
    "blaze": "weapon_flamethrower",
    "frost": "weapon_cryocannon",
    "volt": "weapon_teslacoil",
}

# Final App Store screenshot coverage is intentionally broader than the normal
# release-candidate gate. It proves the complete Cartesian runtime surface:
# every shipped theme, hero and weapon at the real center firing pose, plus both
# diagonal corridors for every theme/hero identity. Static atlas validators
# still own every animation frame; these routes own the actual in-app assembly.
FINAL_THEME_COMBAT_SCREENS: list[tuple[str, dict, str]] = [
    (
        "battle",
        {
            "level_id": "level_091" if theme_id == "gilded_eclipse" else "level_001",
            "save_override": PREMIUM_CROSS_SAVE_OVERRIDES[theme_id],
            "equipment": {"selected_character": character_id, "selected_weapon": weapon_id},
            "debug_character_shooting_frame": 4,
            "debug_character_shooting_aim": "center",
            "debug_character_shooting_muzzle": True,
        },
        f"final_combat_{theme_id}_{character_id}_{weapon_id.removeprefix('weapon_')}_center",
    )
    for theme_id in THEME_IDS
    for character_id in CHARACTER_IDS
    for weapon_id in WEAPON_IDS
]
FINAL_THEME_COMBAT_SCREENS.extend(
    (
        "battle",
        {
            "level_id": "level_091" if theme_id == "gilded_eclipse" else "level_001",
            "save_override": PREMIUM_CROSS_SAVE_OVERRIDES[theme_id],
            "equipment": {
                "selected_character": character_id,
                "selected_weapon": THEME_MATCHING_WEAPONS[theme_id],
            },
            "debug_character_shooting_frame": 4,
            "debug_character_shooting_aim": aim,
            "debug_character_shooting_muzzle": True,
        },
        f"final_combat_{theme_id}_{character_id}_{THEME_MATCHING_WEAPONS[theme_id].removeprefix('weapon_')}_{aim}",
    )
    for theme_id in THEME_IDS
    for character_id in CHARACTER_IDS
    for aim in ("left", "right")
)

# Focused body-ruler regression: one matching weapon per theme, all four heroes
# and all three firing corridors. This is the fast visual gate for confirming
# that guns, coats and signature VFX no longer alter anatomical body size.
CHARACTER_BODY_NORMALIZATION_SCREENS: list[tuple[str, dict, str]] = [
    (
        "battle",
        {
            "level_id": "level_091" if theme_id == "gilded_eclipse" else "level_001",
            "save_override": PREMIUM_CROSS_SAVE_OVERRIDES[theme_id],
            "equipment": {
                "selected_character": character_id,
                "selected_weapon": THEME_MATCHING_WEAPONS[theme_id],
            },
            "debug_character_shooting_frame": 4,
            "debug_character_shooting_aim": aim,
            "debug_character_shooting_muzzle": True,
        },
        f"body_scale_{theme_id}_{character_id}_{aim}",
    )
    for theme_id in THEME_IDS
    for character_id in CHARACTER_IDS
    for aim in ("left", "center", "right")
]
FINAL_THEME_COMBAT_SCREENS.extend(
    (
        "battle",
        {
            "level_id": "level_091" if theme_id == "gilded_eclipse" else "level_001",
            "save_override": PREMIUM_CROSS_SAVE_OVERRIDES[theme_id],
            "equipment": {
                "selected_character": character_id,
                "selected_weapon": THEME_MATCHING_WEAPONS[theme_id],
            },
            "debug_cast_active": True,
            "warmup_frames": 2,
        },
        f"final_active_{theme_id}_{character_id}",
    )
    for theme_id in THEME_IDS
    for character_id in CHARACTER_IDS
)


FINAL_THEME_INTERFACE_SCREENS: list[tuple[str, dict, str]] = []
for theme_id in THEME_IDS:
    theme_save = PREMIUM_CROSS_SAVE_OVERRIDES[theme_id]
    for language in ("zh", "en"):
        locale = {"language": language}
        FINAL_THEME_INTERFACE_SCREENS.extend(
            [
                ("menu", {**locale, "save_override": theme_save}, f"final_{language}_{theme_id}_menu"),
                ("settings", {**locale, "save_override": theme_save}, f"final_{language}_{theme_id}_settings"),
                (
                    "collection",
                    {**locale, "mode": "characters", "save_override": theme_save},
                    f"final_{language}_{theme_id}_characters",
                ),
                (
                    "settings",
                    {**locale, "debug_theme_appearance": True, "save_override": theme_save},
                    f"final_{language}_{theme_id}_theme_appearance",
                ),
            ]
        )
        for character_id in CHARACTER_IDS:
            FINAL_THEME_INTERFACE_SCREENS.extend(
                [
                    (
                        "loadout",
                        {
                            **locale,
                            "level_id": "level_099",
                            "save_override": theme_save,
                            "equipment": {
                                "selected_character": character_id,
                                "selected_weapon": THEME_MATCHING_WEAPONS[theme_id],
                            },
                        },
                        f"final_{language}_{theme_id}_loadout_{character_id}",
                    ),
                    (
                        "collection",
                        {
                            **locale,
                            "mode": "characters",
                            "debug_character_appearance": character_id,
                            "save_override": theme_save,
                        },
                        f"final_{language}_{theme_id}_appearance_{character_id}",
                    ),
                ]
            )


# A focused one-time App Store presentation gate. It keeps the regular final
# matrix lean, while allowing a 5-theme × 12-weapon sweep that also cycles all
# four heroes three times per theme. Every capture exercises the exact loadout
# card rather than judging raw source canvases in isolation.
LOADOUT_PRESENTATION_SCREENS: list[tuple[str, dict, str]] = [
    (
        "loadout",
        {
            "language": "en",
            "level_id": "level_099",
            "save_override": PREMIUM_CROSS_SAVE_OVERRIDES[theme_id],
            "equipment": {
                "selected_character": CHARACTER_IDS[weapon_index % len(CHARACTER_IDS)],
                "selected_weapon": weapon_id,
            },
        },
        f"loadout_presentation_{theme_id}_{CHARACTER_IDS[weapon_index % len(CHARACTER_IDS)]}_{weapon_id}",
    )
    for theme_id in THEME_IDS
    for weapon_index, weapon_id in enumerate(WEAPON_IDS)
]


RESULT_PORTRAIT_SCREENS: list[tuple[str, dict, str]] = [
    (
        "result",
        {
            "language": language,
            "level_id": "level_004",
            "victory": True,
            "challenge": True,
            "stars": 3,
            "gold": 686,
            "xp": 458,
            "save_override": PREMIUM_CROSS_SAVE_OVERRIDES[theme_id],
            "equipment": {"selected_character": character_id},
            "battle_report": {
                "kills": 128,
                "max_kill_streak": 27,
                "duration_seconds": 132.0,
            },
        },
        f"result_portrait_{language}_{theme_id}_{character_id}",
    )
    for language in ("zh", "en")
    for theme_id in THEME_IDS
    for character_id in CHARACTER_IDS
]


# Mobile-readability matrix for the complete four-hero detail surface. Each
# hero carries different affinity and skill-copy lengths, so both languages
# must survive the enlarged secondary type instead of validating one short row.
CHARACTER_DETAIL_VIEWPORTS = (
    ("owner_tall", [1080, 2340]),
    ("compact_tall", [1080, 2046]),
    ("standard", [1080, 1920]),
)

CHARACTER_DETAIL_READABILITY_SCREENS: list[tuple[str, dict, str]] = [
    (
        "collection",
        {
            "language": language,
            "mode": "characters",
            "detail_item": character_id,
            "viewport_size": viewport_size,
        },
        f"character_detail_readability_{viewport_label}_{language}_{character_id}",
    )
    for viewport_label, viewport_size in CHARACTER_DETAIL_VIEWPORTS
    for language in ("zh", "en")
    for character_id in CHARACTER_IDS
]


# Release gate for the complete armor catalog. Both collection rows and every
# detail modal are captured in Chinese and English with all premium sets owned,
# so a headless/cropped source, accidental duplicate inset, or inconsistent
# item framing cannot hide behind a locked-state veil.
ARMOR_PROTOTYPE_SCREENS: list[tuple[str, dict, str]] = [
    (
        "collection",
        {
            "language": language,
            "mode": "armors",
            "viewport_size": [1080, 2340],
            "save_override": PREMIUM_CROSS_SAVE_OVERRIDES["default"],
        },
        f"armor_prototypes_{language}_catalog",
    )
    for language in ("zh", "en")
] + [
    (
        "collection",
        {
            "language": language,
            "mode": "armors",
            "detail_item": armor_id,
            "viewport_size": [1080, 2340],
            "save_override": PREMIUM_CROSS_SAVE_OVERRIDES["default"],
        },
        f"armor_prototypes_{language}_detail_{armor_id}",
    )
    for language in ("zh", "en")
    for armor_id in COLLECTION_IDS["armors"]
]


# The catalog intentionally uses the same four-slot merchandising grammar for
# every series: outfit rosters for themes and real item grids for arsenals. Four
# scroll stops expose all eight fresh-purchase cards in both languages.
STORE_PREVIEW_SCREENS: list[tuple[str, dict, str]] = [
    (
        "store",
        {
            "language": language,
            "viewport_size": [1080, 2340],
            "debug_scroll_y": scroll_y,
            "save_override": FULL_STORE_SAVE_OVERRIDE,
        },
        f"store_tall_preview_{language}_{scroll_index + 1}",
    )
    for language in ("zh", "en")
    for scroll_index, scroll_y in enumerate((0, 880, 1760, 2640))
]


FINAL_COPY_STATE_SCREENS: list[tuple[str, dict, str]] = []
for language in ("zh", "en"):
    locale = {"language": language}
    for chapter in range(1, 11):
        FINAL_COPY_STATE_SCREENS.append(
            (
                "map",
                {**locale, "chapter": chapter, "save_override": LATE_MAP_SAVE_OVERRIDE},
                f"final_{language}_map_chapter_{chapter:02d}",
            )
        )
    for info_mode in ("help", "privacy", "support"):
        FINAL_COPY_STATE_SCREENS.append(
            (
                "settings",
                {**locale, "debug_settings_info": info_mode},
                f"final_{language}_settings_info_{info_mode}",
            )
        )
    FINAL_COPY_STATE_SCREENS.append(
        (
            "settings",
            {**locale, "debug_settings_reset_armed": True},
            f"final_{language}_settings_reset_confirmation",
        )
    )
    for scroll_index, scroll_y in enumerate((0, 880, 1760, 2640)):
        FINAL_COPY_STATE_SCREENS.append(
            (
                "store",
                {
                    **locale,
                    "viewport_size": [1080, 2340],
                    "debug_scroll_y": scroll_y,
                    "save_override": FULL_STORE_SAVE_OVERRIDE,
                },
                f"store_tall_final_{language}_catalog_{scroll_index + 1}",
            )
        )
    FINAL_COPY_STATE_SCREENS.append(
        (
            "result",
            {
                **locale,
                "level_id": "level_099",
                "victory": False,
                "challenge": True,
                "stars": 0,
                "gold": 987654,
                "xp": 123456,
                "viewport_size": [1080, 2340],
            },
            f"result_tall_final_{language}_defeat",
        )
    )

# English boss/zombie proof complements the already exhaustive Chinese combat
# rows in SCREENS, so every dynamic combat name and weakness line is visible in
# both locales rather than only statically present in the translation catalog.
FINAL_COPY_STATE_SCREENS.extend(
    (
        "battle",
        {
            "language": "en",
            "level_id": "level_091",
            "viewport_size": [1080, 2340],
            "debug_spawn_boss": boss_id,
            "debug_clean_boss_stage": True,
            "debug_boss_showcase": True,
            "warmup_frames": 30,
        },
        f"battle_tall_final_en_boss_{boss_id}",
    )
    for boss_id in ALL_BOSSES
)
FINAL_COPY_STATE_SCREENS.extend(
    (
        "battle",
        {
            "language": "en",
            "level_id": "level_001",
            "debug_zombie_attack_showcase": group,
            "warmup_frames": 4,
        },
        f"final_en_zombie_attack_group_{group + 1}",
    )
    for group in range(4)
)
FINAL_COPY_STATE_SCREENS.extend(
    (
        "battle",
        {
            "language": "en",
            "level_id": "level_001",
            "debug_zombie_model_showcase": mode,
            "warmup_frames": 6,
        },
        f"final_en_zombie_models_{mode}",
    )
    for mode in ("redesigned", "roster", "dense")
)


FINAL_VFX_SCREENS: list[tuple[str, dict, str]] = [
    (
        "battle",
        {
            "level_id": "level_001",
            "debug_clean_death_stage": True,
            "debug_skill_pick_vfx": skill_id,
            "warmup_frames": 1,
        },
        f"final_vfx_skill_pick_{skill_id}",
    )
    for skill_id in SKILL_IDS
]
FINAL_VFX_SCREENS.extend(
    (
        "battle",
        {"level_id": "level_001", "debug_status_vfx_showcase": mode, "warmup_frames": 1},
        f"final_vfx_status_{mode}",
    )
    for mode in ("single", "stacked", "dense")
)
for element in ("physical", "fire", "ice", "lightning", "poison"):
    FINAL_VFX_SCREENS.extend(
        [
            (
                "battle",
                {
                    "level_id": "level_001",
                    "debug_clean_hit_stage": True,
                    "debug_hit_showcase": {"element": element, "kind": "normal"},
                    "warmup_frames": 1,
                },
                f"final_vfx_hit_{element}",
            ),
            (
                "battle",
                {
                    "level_id": "level_001",
                    "debug_clean_death_stage": True,
                    "debug_death_showcase": element,
                    "warmup_frames": 1,
                },
                f"final_vfx_death_{element}",
            ),
        ]
    )
FINAL_VFX_SCREENS.extend(
    [
        (
            "battle",
            {
                "level_id": "level_001",
                "debug_clean_hit_stage": True,
                "debug_hit_showcase": {"element": "physical", "kind": "crit"},
                "warmup_frames": 1,
            },
            "final_vfx_hit_critical",
        ),
        (
            "battle",
            {
                "level_id": "level_001",
                "debug_clean_hit_stage": True,
                "debug_hit_showcase": {"element": "physical", "kind": "starter_autocannon"},
                "warmup_frames": 1,
            },
            "final_vfx_hit_starter_autocannon",
        ),
        ("battle", {"level_id": "level_001", "debug_projectile_showcase": "acid_spit"}, "final_vfx_projectile_acid_spit"),
        ("battle", {"level_id": "level_001", "debug_projectile_showcase": "split_mini"}, "final_vfx_projectile_split"),
        ("battle", {"level_id": "level_001", "debug_barrier": True}, "final_vfx_barrier"),
        (
            "battle",
            {"level_id": "level_001", "debug_pet_repair": True, "debug_pet_hp_ratio": 0.3},
            "final_vfx_pet_repair",
        ),
        (
            "battle",
            {
                "level_id": "level_001",
                "save_override": PREMIUM_CROSS_SAVE_OVERRIDES["neon_tempest"],
                "equipment": {"selected_character": "volt", "selected_weapon": "weapon_apocalypse_thunder"},
                "debug_dense_combat": True,
                "debug_apocalypse_overload": True,
            },
            "final_vfx_thunder_overload",
        ),
    ]
)


def _dedupe_screens(screens: list[tuple[str, dict, str]]) -> list[tuple[str, dict, str]]:
    result: list[tuple[str, dict, str]] = []
    labels: set[str] = set()
    for screen in screens:
        if screen[2] in labels:
            continue
        labels.add(screen[2])
        result.append(screen)
    return result


FINAL_REGRESSION_SCREENS = _dedupe_screens(
    SCREENS
    + TYPOGRAPHY_SCREENS
    + FINAL_THEME_COMBAT_SCREENS
    + FINAL_THEME_INTERFACE_SCREENS
    + FINAL_COPY_STATE_SCREENS
    + FINAL_VFX_SCREENS
    + THEME_MENU_SCREENS
    + SKILL_TAG_THEME_SCREENS
    + APP_STORE_VFX_SCREENS
)

# Owner-facing pre-release review pack. The final regression already owns all
# data-driven item details, skills, environments, bosses, zombie groups and the
# complete theme/hero/weapon battle product. Add the three presentation sweeps
# that are intentionally too large or device-specific for the ordinary gate:
# multi-height character details, every loadout weapon presentation, and every
# themed result portrait.
FULL_REVIEW_SCREENS = _dedupe_screens(
    FINAL_REGRESSION_SCREENS
    + CHARACTER_DETAIL_READABILITY_SCREENS
    + LOADOUT_PRESENTATION_SCREENS
    + RESULT_PORTRAIT_SCREENS
)


def capture(route: str, payload: dict, out_path: Path) -> tuple[int, list[str], str]:
    if sys.platform == "darwin" and os.environ.get("ZOMBIE_FIRE_ALLOW_WINDOW_CAPTURE", "0") != "1":
        return (
            125,
            [],
            "macOS viewport capture is disabled because Godot may steal keyboard focus; "
            "run only with explicit owner permission and ZOMBIE_FIRE_ALLOW_WINDOW_CAPTURE=1",
        )
    runtime_payload = dict(payload)
    # Keep the baseline matrix deterministic on non-Chinese developer machines.
    # English routes opt in explicitly; every other route is the Chinese proof.
    runtime_payload.setdefault("language", "zh")
    safe_insets = runtime_payload.pop("_visual_safe_insets", None)
    godot_args = [
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
    # CI/sandbox captures must never read or overwrite the developer's real
    # Godot user:// save. Keep Python's HOME intact for its installed modules,
    # but allow only the child Godot process to use an isolated home.
    visual_home = os.environ.get("ZOMBIE_FIRE_VISUAL_HOME", "")
    if visual_home:
        env["HOME"] = visual_home
    if safe_insets:
        env["ZOMBIE_FIRE_DEBUG_SAFE_INSETS"] = ",".join(str(value) for value in safe_insets)
    else:
        env.pop("ZOMBIE_FIRE_DEBUG_SAFE_INSETS", None)
    command = godot_args
    capture_log: Path | None = None
    # Directly launching Godot activates its window on macOS. Use LaunchServices
    # hidden/background mode instead; _shot.gd also marks the utility window as
    # NO_FOCUS. Metal still renders the real viewport without interrupting the
    # owner's active application.
    if sys.platform == "darwin" and os.environ.get("ZOMBIE_FIRE_FOREGROUND_CAPTURE", "0") != "1":
        handle = tempfile.NamedTemporaryFile(prefix="zf_visual_capture_", suffix=".log", delete=False)
        handle.close()
        capture_log = Path(handle.name)
        command = [
            "open",
            "-gjW",
            "-n",
            "-a",
            "Godot",
            "-o",
            str(capture_log),
            "--stderr",
            str(capture_log),
            "--env",
            f"HOME={env.get('HOME', '')}",
            "--env",
            "ZOMBIE_FIRE_UI_AUDIT=1",
        ]
        if safe_insets:
            command.extend(["--env", f"ZOMBIE_FIRE_DEBUG_SAFE_INSETS={env['ZOMBIE_FIRE_DEBUG_SAFE_INSETS']}"])
        command.extend(
            [
                "--args",
                "--path",
                str(ROOT),
                "--script",
                "res://tools/_shot.gd",
                "--",
                route,
                json.dumps(runtime_payload, ensure_ascii=False),
                str(out_path),
            ]
        )
    try:
        result = subprocess.run(command, cwd=ROOT, timeout=25, env=env, capture_output=True, text=True)
    except subprocess.TimeoutExpired:
        return 124, [], "capture timed out"
    captured_stdout = result.stdout
    if capture_log is not None:
        try:
            captured_stdout = capture_log.read_text(encoding="utf-8", errors="replace") + captured_stdout
        finally:
            capture_log.unlink(missing_ok=True)
    audit_issues: list[str] = []
    audit_seen = route == "battle"
    for line in captured_stdout.splitlines():
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
    combined_output = "\n".join(part for part in [captured_stdout.strip(), result.stderr.strip()] if part)
    effective_code = result.returncode
    fatal_markers = (
        "SCRIPT ERROR:",
        "Failed to load script",
        "Compile Error:",
        "Parse Error:",
        "Character shooting capture rejected a floating-weapon model",
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
    shard_index = 0
    shard_count = 1
    for argument in sys.argv[1:]:
        if not argument.startswith("--final-shard="):
            continue
        shard_value = argument.removeprefix("--final-shard=")
        try:
            shard_index, shard_count = (int(value) for value in shard_value.split("/", 1))
        except (ValueError, TypeError):
            print(f"Invalid --final-shard value: {shard_value}; expected zero-based INDEX/COUNT")
            return 2
        if shard_count <= 0 or shard_index < 0 or shard_index >= shard_count:
            print(f"Invalid --final-shard range: {shard_value}; expected 0 <= INDEX < COUNT")
            return 2
    if "--full-review" in sys.argv[1:]:
        active_screens = FULL_REVIEW_SCREENS
    elif "--final-regression" in sys.argv[1:]:
        active_screens = FINAL_REGRESSION_SCREENS
    elif "--english-only" in sys.argv[1:]:
        active_screens = ENGLISH_SCREENS
    elif "--typography-only" in sys.argv[1:]:
        active_screens = TYPOGRAPHY_SCREENS
    elif "--neon-only" in sys.argv[1:]:
        active_screens = NEON_PREVIEW_SCREENS
    elif "--infernal-theme-only" in sys.argv[1:]:
        active_screens = INFERNAL_PREVIEW_SCREENS
    elif "--polar-theme-only" in sys.argv[1:]:
        active_screens = POLAR_PREVIEW_SCREENS
    elif "--gilded-only" in sys.argv[1:]:
        active_screens = GILDED_ECLIPSE_SCREENS
    elif "--gilded-vfx-only" in sys.argv[1:]:
        active_screens = [
            screen
            for screen in GILDED_ECLIPSE_SCREENS
            if screen[2].startswith("battle_tall_golden_law_")
        ]
    elif "--menus-only" in sys.argv[1:]:
        active_screens = THEME_MENU_SCREENS
    elif "--skill-tags-only" in sys.argv[1:]:
        active_screens = SKILL_TAG_THEME_SCREENS
    elif "--app-store-vfx-only" in sys.argv[1:]:
        active_screens = APP_STORE_VFX_SCREENS
    elif "--premium-cross-only" in sys.argv[1:]:
        active_screens = PREMIUM_CROSS_THEME_SCREENS
    elif "--inferno-only" in sys.argv[1:]:
        active_screens = INFERNO_STEP45_SCREENS
    elif "--absolute-zero-only" in sys.argv[1:]:
        active_screens = ABSOLUTE_ZERO_SCREENS
    elif "--character-detail-only" in sys.argv[1:]:
        active_screens = CHARACTER_DETAIL_READABILITY_SCREENS
    elif "--character-body-only" in sys.argv[1:]:
        active_screens = CHARACTER_BODY_NORMALIZATION_SCREENS
    elif "--appearance-only" in sys.argv[1:]:
        active_screens = [
            screen
            for screen in SCREENS
            if "appearance" in screen[2] or "purchase_complete" in screen[2]
        ]
    elif "--loadout-presentation-only" in sys.argv[1:]:
        active_screens = LOADOUT_PRESENTATION_SCREENS
    elif "--result-portrait-only" in sys.argv[1:]:
        active_screens = RESULT_PORTRAIT_SCREENS
    elif "--armor-prototypes-only" in sys.argv[1:]:
        active_screens = ARMOR_PROTOTYPE_SCREENS
    elif "--store-preview-only" in sys.argv[1:]:
        active_screens = STORE_PREVIEW_SCREENS
    else:
        active_screens = SCREENS
    requested_labels: set[str] = set()
    for argument in sys.argv[1:]:
        if argument.startswith("--labels="):
            requested_labels.update(
                label.strip()
                for label in argument.removeprefix("--labels=").split(",")
                if label.strip()
            )
    if requested_labels:
        available = {screen[2] for screen in active_screens}
        missing_labels = sorted(requested_labels - available)
        if missing_labels:
            print("Unknown screenshot labels: " + ", ".join(missing_labels))
            return 2
        active_screens = [screen for screen in active_screens if screen[2] in requested_labels]
    if shard_count > 1:
        active_screens = active_screens[shard_index::shard_count]
    manifest: list[dict] = []
    visual_output = os.environ.get("ZOMBIE_FIRE_VISUAL_OUTPUT", "").strip()
    with tempfile.TemporaryDirectory(prefix="zombie_fire_screens_") as tmp:
        tmp_dir = Path(tmp)
        for screen_index, (route, payload, label) in enumerate(active_screens, start=1):
            print(
                f"[{screen_index}/{len(active_screens)}] capture {label}"
                + (f" (shard {shard_index + 1}/{shard_count})" if shard_count > 1 else ""),
                flush=True,
            )
            out_path = tmp_dir / f"{label}.png"
            code, audit_issues, output = capture(route, payload, out_path)
            image_issues: list[str] = []
            if code != 0:
                errors.append(f"{label} capture failed with exit code {code}")
                if output:
                    errors.append(f"{label} capture output: {output[-1200:]}")
            else:
                errors.extend(f"{label} runtime audit: {issue}" for issue in audit_issues)
                image_issues = analyze(out_path, label)
                errors.extend(image_issues)
            if visual_output and out_path.exists():
                destination = Path(visual_output)
                destination.mkdir(parents=True, exist_ok=True)
                shutil.copy2(out_path, destination / out_path.name)
            manifest.append(
                {
                    "label": label,
                    "route": route,
                    "payload": payload,
                    "file": f"{label}.png",
                    "capture_code": code,
                    "runtime_audit_issues": audit_issues,
                    "image_analysis_issues": image_issues,
                }
            )

    if visual_output:
        destination = Path(visual_output)
        destination.mkdir(parents=True, exist_ok=True)
        manifest_name = (
            f"regression_manifest_{shard_index + 1:02d}_of_{shard_count:02d}.json"
            if shard_count > 1
            else "regression_manifest.json"
        )
        (destination / manifest_name).write_text(
            json.dumps(
                {
                    "screen_count": len(active_screens),
                    "error_count": len(errors),
                    "screens": manifest,
                },
                ensure_ascii=False,
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )

    if errors:
        print("Visual screen check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(f"Visual screen check OK: {len(active_screens)} routed screenshots")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
