#!/usr/bin/env python3
from __future__ import annotations

import json
import re
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
    "proj_rail_slug", "proj_scatter_pellet", "proj_plasma_orb",
]
VFX = [
    "vfx_hit_physical", "vfx_hit_fire", "vfx_hit_ice", "vfx_hit_lightning", "vfx_hit_poison",
    "vfx_crit", "vfx_explosion_fire", "vfx_freeze", "vfx_chain_lightning", "vfx_poison_cloud",
    "vfx_levelup_glow", "vfx_death_dissolve", "vfx_boss_phase", "vfx_muzzle_physical",
    "vfx_muzzle_fire", "vfx_muzzle_ice", "vfx_muzzle_lightning", "vfx_muzzle_poison",
    "vfx_target_lock", "vfx_threat_warning", "vfx_hit_immune",
]
BACKGROUNDS = [
    "bg_city_ruins", "bg_subway", "bg_military", "bg_biolab", "bg_main_menu", "bg_level_map",
    "bg_lava_foundry", "bg_glacier_pass", "bg_abandoned_factory", "bg_toxic_biolab",
    "bg_storm_substation", "bg_flooded_subway", "bg_desert_refinery", "bg_void_cathedral",
    "bg_orbital_ruins", "bg_apex_core",
]
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

# Historical generation inputs and review sheets are intentionally allowed to be pruned.
# This is an exact audited list: new missing index references remain hard failures even
# when they are under a generated/cache directory.
ALLOWED_MISSING_GENERATED_CACHE_REFERENCES = frozenset({
    "assets/production/contact_sheets/contact_character_active_vfx_2026_07_02.png",
    "assets/production/contact_sheets/contact_enemy_skill_vfx_2026_07_02.png",
    "assets/production/contact_sheets/contact_hit_vfx_polish_2026_07_02.png",
    "assets/production/contact_sheets/contact_level_backgrounds_v2.png",
    "assets/production/contact_sheets/contact_map_ui_line_polish_2026_07_02.png",
    "assets/production/contact_sheets/contact_non_shooting_animation_polish_2026_07_01.png",
    "assets/production/contact_sheets/contact_skeletal_parts_polish_2026_07_01.png",
    "assets/production/contact_sheets/contact_top_tier_backgrounds_2026_07_01.png",
    "assets/production/source_refs/generated/app_icon_1024_v2_generated_source.png",
    "assets/production/source_refs/generated/app_icon_1024_v2_prompt.txt",
    "assets/production/source_refs/generated/final_p0_launch_source_2026_07_01.png",
    "assets/production/source_refs/generated/hero_battle_weaponless_sheet.png",
    "assets/production/source_refs/generated/hero_battle_weaponless_sheet_chroma.png",
    "assets/production/source_refs/generated/high_end_prototype_asset_spec.json",
    "assets/production/source_refs/generated/high_end_prototype_contact_sheet.png",
    "assets/production/source_refs/generated/level_backgrounds_v2_spec.json",
    "assets/production/source_refs/generated/map_ui_line_polish_spec_2026_07_02.json",
    "assets/production/source_refs/generated/non_shooting_animation_polish_spec_2026_07_01.json",
    "assets/production/source_refs/generated/runtime_top_tier_polish_contact_sheet_2026_07_01.png",
    "assets/production/source_refs/generated/runtime_top_tier_polish_spec_2026_07_01.json",
    "assets/production/source_refs/generated/skeletal_parts_polish_spec_2026_07_01.json",
    "assets/production/source_refs/generated/top_tier_background_render_spec_2026_07_01.json",
    "assets/production/source_refs/generated/top_tier_ui_motion_second_pass_spec_2026_07_02.json",
    "assets/production/source_refs/generated/user_combat_vfx_reference_sheet_2026_07_02.png",
    "assets/production/source_refs/generated/user_ui_vfx_reference_sheet_2026_07_02.png",
    "assets/production/source_refs/generated/weapon_autocannon_machinegun_cutout.png",
})
SEQUENCE_METADATA_EXCEPTIONS = {
    "assets/production/sprites/animations/character_weapon_combos": (
        "generated fused character/weapon frames are selected by runtime filename convention"
    ),
    "assets/production/sprites/animations/characters_weaponless": (
        "generated weaponless frames are selected by runtime filename convention"
    ),
}


def expect(missing: list[Path], path: Path) -> None:
    if not path.exists():
        missing.append(path)


def split_index_references(value: object) -> list[str]:
    if isinstance(value, list):
        refs: list[str] = []
        for item in value:
            refs.extend(split_index_references(item))
        return refs
    if not isinstance(value, str):
        return []
    return [part.strip() for part in re.split(r"\s+\+\s+|,\s*", value) if part.strip()]


def resolve_index_reference(reference: str) -> Path:
    if reference.startswith("assets/production/") or reference.startswith("tmp/"):
        return ROOT / reference
    return PROD / reference


def validate_index_references(index: object) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    cache_exceptions: list[str] = []

    def walk(value: object, location: str) -> None:
        if isinstance(value, dict):
            for key, child in value.items():
                child_location = f"{location}.{key}"
                if key in {"source", "derived"}:
                    if not isinstance(child, (str, list)):
                        errors.append(f"{child_location}: expected a path string or list")
                    for reference in split_index_references(child):
                        path = resolve_index_reference(reference).resolve()
                        try:
                            relative = path.relative_to(ROOT).as_posix()
                        except ValueError:
                            errors.append(f"{child_location}: path escapes repository: {reference}")
                            continue
                        if path.exists():
                            continue
                        if relative in ALLOWED_MISSING_GENERATED_CACHE_REFERENCES:
                            cache_exceptions.append(relative)
                        else:
                            errors.append(f"{child_location}: missing {relative}")
                walk(child, child_location)
        elif isinstance(value, list):
            for index_number, child in enumerate(value):
                walk(child, f"{location}[{index_number}]")

    walk(index, "index")
    return errors, cache_exceptions


def load_json(path: Path, errors: list[str]) -> object | None:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f"{path.relative_to(ROOT)}: invalid JSON: {exc}")
        return None


def expected_contiguous_frames(numbers: list[int]) -> list[int]:
    if not numbers:
        return []
    return list(range(1, max(numbers) + 1))


def validate_vfx_sequences(errors: list[str]) -> list[str]:
    base = PROD / "sprites/vfx_sequences"
    exceptions: list[str] = []
    for directory in sorted(path for path in base.iterdir() if path.is_dir()):
        relative_dir = directory.relative_to(ROOT)
        frame_pattern = re.compile(rf"^{re.escape(directory.name)}_(\d+)$")
        numbered: dict[int, Path] = {}
        for frame in sorted(directory.glob("*.png")):
            match = frame_pattern.fullmatch(frame.stem)
            if not match:
                errors.append(f"{frame.relative_to(ROOT)}: orphan VFX frame name")
                continue
            number = int(match.group(1))
            if number in numbered:
                errors.append(f"{relative_dir}: duplicate VFX frame number {number}")
            numbered[number] = frame
        if not numbered:
            errors.append(f"{relative_dir}: no VFX frames")
            continue
        numbers = sorted(numbered)
        if numbers != expected_contiguous_frames(numbers):
            errors.append(f"{relative_dir}: non-contiguous VFX frames {numbers}")

        manifest_path = directory / f"{directory.name}_sequence.json"
        manifest = load_json(manifest_path, errors)
        if not isinstance(manifest, dict):
            continue
        if manifest.get("id") != directory.name:
            errors.append(f"{manifest_path.relative_to(ROOT)}: id does not match directory")
        listed = manifest.get("frames")
        if not isinstance(listed, list) or not all(isinstance(item, str) for item in listed):
            errors.append(f"{manifest_path.relative_to(ROOT)}: frames must be a string list")
            continue
        actual = {path.relative_to(PROD).as_posix() for path in numbered.values()}
        listed_set = set(listed)
        if len(listed_set) != len(listed):
            errors.append(f"{manifest_path.relative_to(ROOT)}: duplicate frame references")
        for missing_ref in sorted(listed_set - actual):
            errors.append(f"{manifest_path.relative_to(ROOT)}: missing frame reference {missing_ref}")
        unlisted = actual - listed_set
        if unlisted:
            listed_numbers = sorted(
                int(match.group(1))
                for item in listed_set
                if (match := frame_pattern.fullmatch(Path(item).stem)) is not None
            )
            unlisted_numbers = sorted(
                int(match.group(1))
                for item in unlisted
                if (match := frame_pattern.fullmatch(Path(item).stem)) is not None
            )
            is_generated_tail = (
                bool(listed_numbers)
                and len(listed_numbers) == len(listed_set)
                and len(unlisted_numbers) == len(unlisted)
                and listed_numbers == expected_contiguous_frames(listed_numbers)
                and unlisted_numbers == list(range(max(listed_numbers) + 1, max(numbers) + 1))
            )
            if is_generated_tail:
                exceptions.append(
                    f"{relative_dir}: generated trailing frame cache "
                    f"{unlisted_numbers[0]:02d}-{unlisted_numbers[-1]:02d} is intentionally outside the runtime manifest"
                )
            else:
                for orphan in sorted(unlisted):
                    errors.append(f"{manifest_path.relative_to(ROOT)}: unlisted orphan frame {orphan}")
    return exceptions


def sequence_exception(directory: Path) -> str | None:
    relative = directory.relative_to(ROOT).as_posix()
    for prefix, reason in SEQUENCE_METADATA_EXCEPTIONS.items():
        if relative == prefix or relative.startswith(f"{prefix}/"):
            return reason
    return None


def validate_animation_sequences(errors: list[str]) -> list[str]:
    base = PROD / "sprites/animations"
    exceptions: list[str] = []
    for directory in sorted(path for path in base.rglob("*") if path.is_dir()):
        frames = sorted(directory.glob("*.png"))
        if not frames:
            continue
        relative_dir = directory.relative_to(ROOT)
        frame_pattern = re.compile(rf"^{re.escape(directory.name)}_(.+)_(\d+)$")
        by_action: dict[str, dict[int, Path]] = {}
        for frame in frames:
            match = frame_pattern.fullmatch(frame.stem)
            if not match:
                errors.append(f"{frame.relative_to(ROOT)}: orphan animation frame name")
                continue
            action = match.group(1)
            number = int(match.group(2))
            action_frames = by_action.setdefault(action, {})
            if number in action_frames:
                errors.append(f"{relative_dir}: duplicate {action} frame number {number}")
            action_frames[number] = frame
        for action, action_frames in sorted(by_action.items()):
            numbers = sorted(action_frames)
            if numbers != expected_contiguous_frames(numbers):
                errors.append(f"{relative_dir}: non-contiguous {action} frames {numbers}")

        manifest_path = directory / f"{directory.name}_animation.json"
        if not manifest_path.is_file():
            reason = sequence_exception(directory)
            if reason:
                exceptions.append(f"{relative_dir}: {reason}")
            else:
                errors.append(f"{relative_dir}: missing {manifest_path.name}")
            continue
        manifest = load_json(manifest_path, errors)
        if not isinstance(manifest, dict):
            continue
        if manifest.get("id") != directory.name:
            errors.append(f"{manifest_path.relative_to(ROOT)}: id does not match directory")
        actions = manifest.get("actions")
        if not isinstance(actions, dict):
            errors.append(f"{manifest_path.relative_to(ROOT)}: actions must be an object")
            continue
        listed_by_action: dict[str, set[str]] = {}
        for action, config in actions.items():
            if not isinstance(config, dict) or not isinstance(config.get("frames"), list):
                errors.append(f"{manifest_path.relative_to(ROOT)}: invalid action {action}")
                continue
            listed = config["frames"]
            if not all(isinstance(item, str) for item in listed):
                errors.append(f"{manifest_path.relative_to(ROOT)}: non-string frame in action {action}")
                continue
            listed_by_action[str(action)] = set(listed)
            if len(listed_by_action[str(action)]) != len(listed):
                errors.append(f"{manifest_path.relative_to(ROOT)}: duplicate frame in action {action}")
        actual_by_action = {
            action: {path.relative_to(PROD).as_posix() for path in action_frames.values()}
            for action, action_frames in by_action.items()
        }
        for action in sorted(set(actual_by_action) | set(listed_by_action)):
            actual = actual_by_action.get(action, set())
            listed = listed_by_action.get(action, set())
            for missing_ref in sorted(listed - actual):
                errors.append(f"{manifest_path.relative_to(ROOT)}: missing {action} frame {missing_ref}")
            for orphan in sorted(actual - listed):
                errors.append(f"{manifest_path.relative_to(ROOT)}: unlisted {action} frame {orphan}")
    return exceptions


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
    expect(missing, PROD / "fonts/OFL-GlowSans.txt")
    expect(missing, PROD / "fonts/font_main.provenance.json")
    expect(missing, PROD / "INTEGRATION_ASSET_MANIFEST.json")
    expect(missing, PROD / "OUTSOURCER_ASSET_INDEX.json")
    if missing:
        print("Asset pack validation failed:")
        for path in missing:
            print("-", path.relative_to(ROOT))
        return 1

    errors: list[str] = []
    index_path = PROD / "OUTSOURCER_ASSET_INDEX.json"
    index = load_json(index_path, errors)
    cache_exceptions: list[str] = []
    if index is not None:
        index_errors, cache_exceptions = validate_index_references(index)
        errors.extend(index_errors)
    vfx_sequence_exceptions = validate_vfx_sequences(errors)
    sequence_exceptions = validate_animation_sequences(errors)
    if errors:
        print("Asset pack validation failed:")
        for error in errors:
            print("-", error)
        return 1
    if cache_exceptions:
        print(f"Recorded generated-cache reference exceptions: {len(set(cache_exceptions))}")
        for exception in sorted(set(cache_exceptions)):
            print("-", exception)
    if sequence_exceptions:
        print(f"Recorded generated-sequence metadata exceptions: {len(sequence_exceptions)}")
        for exception in sequence_exceptions:
            print("-", exception)
    if vfx_sequence_exceptions:
        print(f"Recorded generated VFX tail-cache exceptions: {len(vfx_sequence_exceptions)}")
        for exception in vfx_sequence_exceptions:
            print("-", exception)
    count = sum(1 for _ in PROD.rglob("*") if _.is_file())
    print(f"Asset pack validation passed: {count} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
