#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / "assets" / "production"

CHARACTERS = ["char_vanguard", "char_blaze", "char_frost", "char_volt"]
ZOMBIES = [
    "zombie_shambler", "zombie_runner", "zombie_brute", "zombie_spitter", "zombie_crawler",
    "zombie_armored", "zombie_bomber", "zombie_shielder", "zombie_hopper", "zombie_screamer",
    "zombie_juggernaut", "zombie_phantom", "zombie_necromancer", "zombie_toxic", "zombie_charger",
    "zombie_regenerator", "zombie_splitter", "zombie_warden", "zombie_mutant", "zombie_berserker",
]
BOSSES = [
    "boss_tank_titan", "boss_inferno_maw", "boss_frost_warden", "boss_storm_caller",
    "boss_plague_mother", "boss_void_phantom", "boss_necrotitan", "boss_apex_overlord",
]
WEAPONS = [
    "weapon_autocannon", "weapon_railgun", "weapon_scattergun", "weapon_flamethrower",
    "weapon_cryocannon", "weapon_teslacoil", "weapon_venomlauncher", "weapon_plasmacannon",
]
ARMORS = ["armor_kevlar", "armor_reactive", "armor_thermal", "armor_cryo", "armor_faraday", "armor_hazmat"]
CHIPS = ["chip_attack", "chip_health", "chip_crit", "chip_haste", "chip_pierce", "chip_element", "chip_greed", "chip_guardian"]
PETS = ["pet_turret_drone", "pet_fire_imp", "pet_frost_wisp", "pet_volt_orb", "pet_medic_drone", "pet_collector"]
PROJECTILES = [
    "proj_bullet_physical", "proj_bullet_fire", "proj_bullet_ice", "proj_bullet_lightning",
    "proj_bullet_poison", "proj_heavy_charge", "proj_acid_spit", "proj_split_mini",
]
VFX = [
    "vfx_hit_physical", "vfx_hit_fire", "vfx_hit_ice", "vfx_hit_lightning", "vfx_hit_poison",
    "vfx_crit", "vfx_explosion_fire", "vfx_freeze", "vfx_chain_lightning", "vfx_poison_cloud",
    "vfx_levelup_glow", "vfx_death_dissolve", "vfx_boss_phase", "vfx_muzzle_physical",
    "vfx_muzzle_fire", "vfx_muzzle_ice", "vfx_muzzle_lightning", "vfx_muzzle_poison",
    "vfx_target_lock", "vfx_threat_warning", "vfx_hit_immune",
]
BACKGROUNDS = ["bg_city_ruins", "bg_subway", "bg_military", "bg_biolab", "bg_main_menu", "bg_level_map"]
SFX = [
    "sfx_ui_click", "sfx_ui_confirm", "sfx_ui_card_offer", "sfx_ui_card_pick", "sfx_shot_autocannon",
    "sfx_hit_physical", "sfx_enemy_death_small", "sfx_enemy_breach", "sfx_gold_pickup", "sfx_level_up",
    "sfx_victory", "sfx_defeat", "sfx_lock_target", "sfx_threat_warning", "sfx_hit_immune",
    "sfx_hit_fire", "sfx_hit_ice", "sfx_hit_lightning", "sfx_hit_poison",
    "sfx_muzzle_fire", "sfx_muzzle_ice", "sfx_muzzle_lightning", "sfx_muzzle_poison",
    "sfx_shot_railgun", "sfx_shot_scattergun", "sfx_shot_flamethrower", "sfx_shot_cryocannon",
    "sfx_shot_teslacoil", "sfx_shot_venomlauncher", "sfx_shot_plasmacannon",
    "sfx_boss_intro_tank_titan", "sfx_boss_intro_inferno_maw", "sfx_boss_intro_frost_warden",
    "sfx_boss_intro_storm_caller", "sfx_boss_intro_plague_mother", "sfx_boss_intro_void_phantom",
    "sfx_boss_intro_necrotitan", "sfx_boss_intro_apex_overlord",
    "sfx_pause", "sfx_resume", "sfx_reroll", "sfx_star_gain", "sfx_upgrade_weapon",
]
BGM = [
    "bgm_menu", "bgm_map", "bgm_battle_city", "bgm_battle_subway", "bgm_battle_military",
    "bgm_battle_biolab", "bgm_boss", "bgm_result_victory", "bgm_result_defeat",
]
ANIM_ACTIONS = {
    "characters": ["idle", "attack", "hurt"],
    "zombies": ["idle", "walk", "attack", "hurt", "death"],
    "bosses": ["idle", "walk", "attack", "hurt", "death", "special"],
    "pets": ["idle", "attack", "hurt"],
    "weapons": ["idle", "recoil"],
}
VFX_COUNTS = {
    "vfx_hit_physical": 8, "vfx_hit_fire": 8, "vfx_hit_ice": 8, "vfx_hit_lightning": 8,
    "vfx_hit_poison": 8, "vfx_crit": 8, "vfx_explosion_fire": 16, "vfx_freeze": 12,
    "vfx_chain_lightning": 10, "vfx_poison_cloud": 12, "vfx_levelup_glow": 12,
    "vfx_death_dissolve": 10, "vfx_boss_phase": 12, "vfx_muzzle_physical": 6,
    "vfx_muzzle_fire": 6, "vfx_muzzle_ice": 6, "vfx_muzzle_lightning": 6,
    "vfx_muzzle_poison": 6, "vfx_target_lock": 8, "vfx_threat_warning": 8,
    "vfx_hit_immune": 8,
}
FLOW = [
    "flow_01_main_menu", "flow_02_level_map", "flow_03_loadout", "flow_04_battle",
    "flow_05_card_pick", "flow_06_result",
]
VIDEOS = [
    "vid_intro_opening", "vid_chapter_city_ruins", "vid_chapter_subway", "vid_chapter_military",
    "vid_chapter_biolab", "vid_boss_intro_tank_titan", "vid_boss_intro_inferno_maw",
    "vid_boss_intro_frost_warden", "vid_boss_intro_storm_caller", "vid_boss_intro_plague_mother",
    "vid_boss_intro_void_phantom", "vid_boss_intro_necrotitan", "vid_boss_intro_apex_overlord",
    "vid_ending", "vid_app_preview",
]
PARTS = ["head", "body", "arm_l", "arm_r", "hand_l", "hand_r", "leg_l", "leg_r", "weapon"]


def expect(missing: list[Path], path: Path) -> None:
    if not path.exists():
        missing.append(path)


def main() -> int:
    missing: list[Path] = []
    for item in CHARACTERS:
        for suffix in ["prototype", "portrait", "icon"]:
            expect(missing, PROD / "sprites/characters" / f"{item}_{suffix}.png")
    for item in ZOMBIES:
        for suffix in ["prototype", "portrait", "icon"]:
            expect(missing, PROD / "sprites/zombies" / f"{item}_{suffix}.png")
    for item in BOSSES:
        for suffix in ["prototype", "portrait", "icon"]:
            expect(missing, PROD / "sprites/bosses" / f"{item}_{suffix}.png")
    for item in PETS:
        for suffix in ["prototype", "portrait", "icon"]:
            expect(missing, PROD / "sprites/pets" / f"{item}_{suffix}.png")
    for item in WEAPONS:
        expect(missing, PROD / "sprites/weapons" / f"{item}_icon.png")
        expect(missing, PROD / "sprites/weapons" / f"{item}_turret.png")
    for item in ARMORS + CHIPS:
        expect(missing, PROD / "sprites/equipment" / f"{item}_icon.png")
    for item in PROJECTILES:
        expect(missing, PROD / "sprites/projectiles" / f"{item}.png")
    for item in VFX:
        expect(missing, PROD / "sprites/vfx" / f"{item}.png")
    for item in BACKGROUNDS:
        expect(missing, PROD / "sprites/backgrounds" / f"{item}.png")
    for item in SFX:
        expect(missing, PROD / "audio/sfx" / f"{item}.wav")
    for item in BGM:
        expect(missing, PROD / "audio/bgm" / f"{item}.wav")
    for item in CHARACTERS:
        for action in ANIM_ACTIONS["characters"]:
            expect(missing, PROD / "sprites/animations/characters" / item / f"{item}_{action}_01.png")
    for item in ZOMBIES:
        for action in ANIM_ACTIONS["zombies"]:
            expect(missing, PROD / "sprites/animations/zombies" / item / f"{item}_{action}_01.png")
    for item in BOSSES:
        for action in ANIM_ACTIONS["bosses"]:
            expect(missing, PROD / "sprites/animations/bosses" / item / f"{item}_{action}_01.png")
    for item in PETS:
        for action in ANIM_ACTIONS["pets"]:
            expect(missing, PROD / "sprites/animations/pets" / item / f"{item}_{action}_01.png")
    for item in WEAPONS:
        for action in ANIM_ACTIONS["weapons"]:
            expect(missing, PROD / "sprites/animations/weapons" / item / f"{item}_{action}_01.png")
    for item, count in VFX_COUNTS.items():
        expect(missing, PROD / "sprites/vfx_sequences" / item / f"{item}_{count:02d}.png")
    for item in BACKGROUNDS:
        expect(missing, PROD / "environment" / f"{item}_portrait.png")
        expect(missing, PROD / "environment" / f"{item}_battle_layout_guide.png")
    for item in FLOW:
        expect(missing, PROD / "flow" / f"{item}.png")
    for item in VIDEOS:
        expect(missing, PROD / "video" / f"{item}.mp4")
    for kind, items in {
        "characters": CHARACTERS,
        "zombies": ZOMBIES,
        "bosses": BOSSES,
        "pets": PETS,
        "weapons": WEAPONS,
    }.items():
        for item in items:
            for part in PARTS:
                expect(missing, PROD / "sprites/parts" / kind / item / f"{item}_{part}.png")
            expect(missing, PROD / "sprites/parts" / kind / item / f"{item}_parts.json")
    expect(missing, PROD / "fonts/font_main.ttf")
    expect(missing, PROD / "INTEGRATION_ASSET_MANIFEST.json")
    expect(missing, PROD / "OUTSOURCER_ASSET_INDEX.json")
    if missing:
        print("Asset pack validation failed:")
        for path in missing:
            print("-", path.relative_to(ROOT))
        return 1
    count = sum(1 for _ in PROD.rglob("*") if _.is_file())
    print(f"Asset pack validation passed: {count} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
