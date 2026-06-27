#!/usr/bin/env python3
from __future__ import annotations

import json
import math
import re
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]


def load_json(path: str) -> dict:
    return json.loads((ROOT / path).read_text())


def projectile_axis_degrees(path: Path) -> float:
    image = Image.open(path).convert("RGBA")
    pixels = image.load()
    points: list[tuple[int, int]] = []
    weights: list[float] = []
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a <= 16:
                continue
            brightness = (r + g + b) / (3 * 255)
            points.append((x, y))
            weights.append((a / 255) * (0.35 + 0.65 * brightness))
    total_weight = sum(weights)
    if total_weight <= 0:
        return 0.0
    mean_x = sum(x * weight for (x, _), weight in zip(points, weights)) / total_weight
    mean_y = sum(y * weight for (_, y), weight in zip(points, weights)) / total_weight
    sxx = sum(((x - mean_x) ** 2) * weight for (x, _), weight in zip(points, weights)) / total_weight
    syy = sum(((y - mean_y) ** 2) * weight for (_, y), weight in zip(points, weights)) / total_weight
    sxy = sum((x - mean_x) * (y - mean_y) * weight for (x, y), weight in zip(points, weights)) / total_weight
    return math.degrees(0.5 * math.atan2(2 * sxy, sxx - syy))


def main() -> int:
    skills = load_json("data/skills.json")
    weapons = load_json("data/weapons.json")
    zombies = load_json("data/zombies.json")
    bosses = load_json("data/bosses.json")
    localization = load_json("data/localization_zh.json")
    battle = (ROOT / "gameplay/battle/battle.gd").read_text()
    main_scene = (ROOT / "main.gd").read_text()
    loadout_scene = (ROOT / "meta/loadout/loadout.tscn").read_text()
    loadout = (ROOT / "meta/loadout/loadout.gd").read_text()
    result = (ROOT / "meta/result/result.gd").read_text()
    collection = (ROOT / "meta/collection/collection.gd").read_text()
    projectile = (ROOT / "gameplay/projectile/projectile.gd").read_text()
    enemy = (ROOT / "gameplay/enemy/enemy.gd").read_text()
    turret = (ROOT / "gameplay/turret/turret.gd").read_text()
    save = (ROOT / "core/save/save_manager.gd").read_text()
    errors: list[str] = []

    if len(skills) < 16:
        errors.append(f"skill pool too small: {len(skills)}")

    for skill_id in skills:
        name = str(localization.get(skill_id, ""))
        if not name or re.fullmatch(r"[A-Za-z0-9 _-]+", name):
            errors.append(f"{skill_id} must have a localized Chinese display name")
        if f'"{skill_id}":' not in battle:
            errors.append(f"{skill_id} missing authored card description in battle.gd")
        tags = skills[skill_id].get("card_tags", [])
        if len(tags) != len(set(tags)):
            errors.append(f"{skill_id} has duplicate card_tags")

    for table_name, table in [("zombie", zombies), ("boss", bosses)]:
        for item_id, row in table.items():
            key = str(row.get("name_key", item_id))
            name = str(localization.get(key, ""))
            if not name or re.fullmatch(r"[A-Za-z0-9 _-]+", name):
                errors.append(f"{table_name} {item_id} must have a localized Chinese display name")

    limit_match = re.search(r"SKILL_SLOT_LIMIT\s*:=\s*(\d+)", battle)
    if not limit_match:
        errors.append("battle HUD must define SKILL_SLOT_LIMIT")
    elif int(limit_match.group(1)) > 8:
        errors.append("battle HUD skill slots must stay at 8 or fewer to avoid overflow")

    for element in ["fire", "ice", "lightning", "poison", "physical"]:
        if f"proj_bullet_{element}.png" not in projectile:
            errors.append(f"projectile missing {element} element texture mapping")
    if "homing_strength" not in projectile or "_apply_homing" not in projectile:
        errors.append("projectile must keep homing runtime support")
    if "SPRITE_FORWARD_ANGLE := 0.0" not in projectile:
        errors.append("projectile runtime must assume right-facing sprites as the zero-angle baseline")
    if "PROJECTILE_SPEED_MULTIPLIER := 0.5" not in projectile:
        errors.append("projectile runtime must apply the requested half-speed pacing")
    if "spit.rotation = (target_position - spit.global_position).angle() + PI / 4.0" in battle:
        errors.append("acid spit projectile must not add a stale 45 degree rotation offset")
    for path in (ROOT / "assets/production/sprites/projectiles").glob("proj_*.png"):
        axis = projectile_axis_degrees(path)
        if abs(axis) > 8.0:
            errors.append(f"{path.name} must be authored right-facing; axis is {axis:.1f} degrees")
    if "button.clip_contents = true" not in collection:
        errors.append("collection rows must clip dynamic portraits")
    for required_clip in ["card.clip_contents = true"]:
        if required_clip not in battle:
            errors.append(f"battle dynamic icon container missing: {required_clip}")
    if '"未取"' in battle:
        errors.append("battle HUD must not fill combat space with unowned skill placeholders")
    if "+%d 金币  +%d XP" in battle:
        errors.append("battle HUD must not spawn large reward text over enemies")
    for stale_reward in ["_spawn_reward_flyouts", "_spawn_reward_chip"]:
        if stale_reward in battle:
            errors.append(f"battle must not drop reward chips on the combat field: {stale_reward}")
    if "_spawn_zombie_blood_pool" not in battle:
        errors.append("enemy deaths must leave a short-lived zombie blood cleanup effect")
    if "$Hud.add_child(ring)" in battle:
        errors.append("battle attack rings must render in the combat layer, not as HUD rectangles")
    for stale_tracer in ["var ray := ColorRect.new()", "var line := ColorRect.new()", "var flare := ColorRect.new()"]:
        if stale_tracer in battle:
            errors.append(f"battle cannon VFX must not use HUD ColorRect tracers: {stale_tracer}")
    if "$Hud/ObjectivePanel.visible = false" not in battle:
        errors.append("battle objective panel must stay hidden during live combat")
    if "character_weapon_sprite.rotation = character_weapon_direction.angle()" not in battle:
        errors.append("character-held guns must use right-facing weapon sprites as the rotation baseline")
    if "_spawn_loadout_badge(Vector2" in battle:
        errors.append("battle intro must not spawn oversized character/weapon level text over the model")
    for source_ref in ["hero_battle_pose_sheet.png", "handheld_weapon_sheet.png"]:
        if not (ROOT / "assets/production/source_refs" / source_ref).exists():
            errors.append(f"battle visual source sheet missing: {source_ref}")
    battle_scene = (ROOT / "gameplay/battle/battle.tscn").read_text()
    skill_slots_idx = battle_scene.find('[node name="SkillSlots"')
    if skill_slots_idx == -1:
        errors.append("battle skill slots node missing")
    elif "anchor_top = 1.0" not in battle_scene[skill_slots_idx:skill_slots_idx + 400]:
        errors.append("battle skill slots must be anchored to the bottom edge of the HUD")
    for runtime_key in ["BarrierGlass", "_spawn_barrier_break_vfx", "_spawn_barrier_gain_vfx", "_barrier_charge_count"]:
        if runtime_key not in battle:
            errors.append(f"barrier glass runtime missing: {runtime_key}")
    for runtime_key in ["hit_target_ids", "chain_depth", "proj_split_mini.png", "_split_target_directions", "_spawn_chain_projectiles", "_apply_pierce_sweep", "_spawn_pierce_trace"]:
        if runtime_key not in battle and runtime_key not in projectile:
            errors.append(f"projectile chaining/pierce runtime missing: {runtime_key}")
    for runtime_key in ["_primary_shot_directions", "_multi_shot_target_candidates", "skills.fire_rate_multiplier()", "skill_fire_rate_mult"]:
        if runtime_key not in battle:
            errors.append(f"multi-lane targeting or fire-rate skill runtime missing: {runtime_key}")

    for key in ["base_atk_coef", "pellets", "spread", "pierce", "chain", "splash", "cloud"]:
        if key not in battle:
            errors.append(f"battle must consume weapon special/base field: {key}")

    for runtime_key in ["_spawn_character", "_process_character_animation", "_load_pet_animation_frames", "_spawn_levelup_vfx", "_visual_level_scale"]:
        if runtime_key not in battle:
            errors.append(f"battle visual runtime missing: {runtime_key}")
    for runtime_key in ["CharacterPanel", "WeaponPanel", "DetailsPanel"]:
        if runtime_key not in loadout_scene:
            errors.append(f"loadout cyber frame missing: {runtime_key}")
    for runtime_key in ["CharacterSelectBar", "GearIconRow"]:
        if runtime_key not in loadout_scene:
            errors.append(f"loadout direct icon layout missing: {runtime_key}")
    for runtime_key in ["_nav_button_style", "CharacterName", "WeaponName", "_rebuild_character_bar", "_rebuild_gear_icon_row", "_try_upgrade_weapon"]:
        if runtime_key not in loadout:
            errors.append(f"loadout premium UI runtime missing: {runtime_key}")
    for runtime_key in ["idle_frames", "recoil_frames", "_play_recoil"]:
        if runtime_key not in turret:
            errors.append(f"turret animation runtime missing: {runtime_key}")
    for runtime_key in ["DEFAULT_FIRE_RATE_MULTIPLIER := 0.25", "PLAYER_FIRE_RATE_MULT", "_player_fire_rate_multiplier"]:
        if runtime_key not in turret:
            errors.append(f"turret fire-rate pacing missing: {runtime_key}")
    for runtime_key in ["PLAYER_SHOT_DAMAGE_MULT", "_player_shot_damage_multiplier"]:
        if runtime_key not in battle:
            errors.append(f"primary shot damage compensation missing: {runtime_key}")
    for runtime_key in ["MUZZLE_LOCAL_OFFSETS", "_update_muzzle_position", "muzzle_local_position.angle()"]:
        if runtime_key not in turret:
            errors.append(f"turret muzzle runtime missing: {runtime_key}")
    if "position = Vector2(0, -120)" in (ROOT / "gameplay/turret/turret.tscn").read_text():
        errors.append("turret scene must not use the stale fixed muzzle marker")
    for runtime_key in ["get_item_level", "upgrade_item", "can_upgrade_item"]:
        if runtime_key not in save:
            errors.append(f"generic equipment upgrade API missing: {runtime_key}")
    for runtime_key in ["repair_progression_unlocks", "_refresh_level_unlocks_from_progress", "victory and next_level"]:
        if runtime_key not in save:
            errors.append(f"level progression repair missing: {runtime_key}")
    for runtime_key in ["_on_next_pressed", "_campaign_next_level", "_resolve_level_id", "router.change_scene(\"loadout\", {\"level_id\": next_level})"]:
        if runtime_key not in result:
            errors.append(f"result next-level routing missing: {runtime_key}")
    for runtime_key in ["_campaign_next_level", "_normalize_route_payload", "normalized[\"next_level\"]", "result_level_id == \"\""]:
        if runtime_key not in main_scene:
            errors.append(f"main finish-level normalization missing: {runtime_key}")
    if "result.get(\"level_id\", \"level_001\")" in save:
        errors.append("save result application must not silently default missing level_id to level_001")

    for mechanic in ["phase_burn", "freeze_field", "storm_chain", "spawn_minions", "phase_shift", "regenerate", "multi_phase"]:
        if mechanic not in battle and mechanic not in enemy:
            errors.append(f"boss/enemy mechanic not consumed: {mechanic}")

    animation_roots = {
        "character": ROOT / "assets/production/sprites/animations/characters",
        "weapon": ROOT / "assets/production/sprites/animations/weapons",
        "pet": ROOT / "assets/production/sprites/animations/pets",
        "boss": ROOT / "assets/production/sprites/animations/bosses",
    }
    for kind, path in animation_roots.items():
        if not path.exists() or not any(path.rglob("*.png")):
            errors.append(f"{kind} animation frames missing under {path.relative_to(ROOT)}")

    if errors:
        print("Gameplay polish check failed:")
        for error in errors:
            print(f"  - {error}")
        return 1
    print(f"Gameplay polish OK: {len(skills)} skills, {len(weapons)} weapons, {len(zombies) + len(bosses)} enemies covered")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
