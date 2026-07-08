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


def rendered_projectile_metrics(path: Path) -> dict[str, float]:
    image = Image.open(path).convert("RGBA")
    visible = []
    edge_alpha = 0
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = image.getpixel((x, y))
            if x == 0 or y == 0 or x == image.width - 1 or y == image.height - 1:
                edge_alpha = max(edge_alpha, a)
            if a > 32:
                visible.append((r // 8, g // 8, b // 8))
    coverage = len(visible) / max(1, image.width * image.height)
    return {
        "coverage": coverage,
        "unique_q8": float(len(set(visible))),
        "edge_alpha": float(edge_alpha),
    }


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
    if localization.get("weapon_autocannon") != "自动机枪":
        errors.append("weapon_autocannon must display as 自动机枪")
    if weapons["weapon_autocannon"].get("turret") != "res://assets/production/sprites/weapons/weapon_autocannon_turret.png":
        errors.append("weapon_autocannon must not use the old base-cannon prototype path")
    if "homing_strength" not in projectile or "_apply_homing" not in projectile:
        errors.append("projectile must keep homing runtime support")
    for runtime_key in [
        "HOMING_ACTIVATION_DELAY := 1.0",
        "HOMING_MIN_TURN_RADIUS",
        "_homing_turn_rate_limit",
        "PROJECTILE_MAX_LIFETIME := 5.0",
        "PROJECTILE_OFFSCREEN_MARGIN := 0.0",
    ]:
        if runtime_key not in projectile:
            errors.append(f"projectile homing/lifetime guard missing: {runtime_key}")
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
    for projectile_name in ["proj_heavy_charge.png", "proj_scatter_pellet.png"]:
        projectile_path = ROOT / "assets/production/sprites/projectiles" / projectile_name
        if not projectile_path.exists():
            errors.append(f"missing rendered projectile replacement: {projectile_name}")
            continue
        metrics = rendered_projectile_metrics(projectile_path)
        if not (0.055 <= metrics["coverage"] <= 0.32):
            errors.append(f"{projectile_name} alpha coverage looks wrong for a rendered projectile: {metrics['coverage']:.3f}")
        if metrics["unique_q8"] < 900:
            errors.append(f"{projectile_name} has too little raster color variation; likely reverted to flat geometry ({metrics['unique_q8']:.0f})")
        if metrics["edge_alpha"] > 4.0:
            errors.append(f"{projectile_name} alpha touches canvas edge; check matte/crop ({metrics['edge_alpha']:.0f})")
    if "button.clip_contents = true" not in collection:
        errors.append("collection rows must clip dynamic portraits")
    if "SaveManager.get_skill_base_level(item_id)" not in collection:
        errors.append("collection skill rows must display permanent skill_base_levels, not generic item levels")
    skill_button_match = re.search(r"func _build_skill_item_button[\s\S]*?\nfunc ", collection)
    skill_button_body = skill_button_match.group(0) if skill_button_match else ""
    if "SaveManager.get_item_level(item_id)" in skill_button_body:
        errors.append("collection skill list must not force skill cards through SaveManager.get_item_level(item_id)")
    if 'max_label.text = "上限"' in collection and "_build_skill_item_button" in collection:
        errors.append("collection skill list must label the right-side value as current level, not 上限")
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
    if 'enemy.set_meta("death_element", str(reward.get("death_element", "physical")))' not in battle:
        errors.append("enemy deaths must preserve the final hit element for elemental death readability")
    if 'if not bool(reward.get("weak_kill", false)) and not bool(reward.get("boss", false)):' in battle:
        errors.append("ordinary non-weak enemy deaths must not be normalized to physical; polish the element VFX instead")
    if 'stack_element := "physical" if element == "fire" and not is_boss else element' in battle:
        errors.append("ordinary fire deaths must not hide their element by routing through physical impact stacks")
    if "_spawn_centered_fire_death_vfx(position)" not in battle:
        errors.append("ordinary fire deaths must use the centered burn-out VFX path, not projectile-like spray")
    if '_spawn_vfx_sequence("vfx_explosion_fire", position + Vector2(0, -38 if not is_boss else -82)' in battle:
        errors.append("ordinary enemy fire deaths must not use the large vfx_explosion_fire plume")
    if '_spawn_vfx_sequence("vfx_hit_fire", position + Vector2(0, -38)' in battle:
        errors.append("ordinary enemy fire deaths must not call hit-fire directly from the generic death branch; use centered fire death VFX")
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
    else:
        skill_slots_block = battle_scene[skill_slots_idx:skill_slots_idx + 400]
        if "anchor_bottom = 1.0" in skill_slots_block:
            # anchor_bottom=1.0 锚定"屏幕真实底部"，在比 1080x1920 更高宽比的设备
            # (如 iPhone 16 Pro Max) 上会让技能槽脱离下方 HUD 群组、悬空进黑色空白区。
            errors.append("battle skill slots must not anchor to the real screen bottom edge (breaks on taller aspect ratios); use a fixed absolute offset within the 1920 design height instead")
        else:
            offset_top_match = re.search(r"offset_top = ([\d.]+)", skill_slots_block)
            if not offset_top_match or float(offset_top_match.group(1)) < 1400.0:
                errors.append("battle skill slots must sit in the lower portion of the HUD near the bottom bar cluster")
    for runtime_key in ["BarrierGlass", "_spawn_barrier_break_vfx", "_spawn_barrier_gain_vfx", "_barrier_charge_count"]:
        if runtime_key not in battle:
            errors.append(f"barrier glass runtime missing: {runtime_key}")
    for runtime_key in ["hit_target_ids", "chain_depth", "proj_split_mini.png", "_split_target_directions", "_spawn_chain_projectiles", "_apply_pierce_sweep", "_spawn_pierce_trace"]:
        if runtime_key not in battle and runtime_key not in projectile:
            errors.append(f"projectile chaining/pierce runtime missing: {runtime_key}")
    for runtime_key in ["_active_skill_fallback_point", "_active_skill_fallback_chain_points", "_spawn_element_impact_vfx", "_spawn_skill_to_slot_vfx"]:
        if runtime_key not in battle:
            errors.append(f"active skill or element impact polish missing: {runtime_key}")
    for runtime_key in ["scaling_basis", "_character_active_character_damage", "_character_active_power_scale", "_vanguard_railvolley_count", "_blaze_meltdown_pulse_count", "_frost_glacier_wave_count", "_volt_storm_strike_count"]:
        if runtime_key not in battle:
            errors.append(f"character active skill level-scaling runtime missing: {runtime_key}")
    for runtime_key in [
        "WEAPON_VISUAL_PROFILES",
        '"weapon_railgun": "rail"',
        '"weapon_scattergun": "scatter"',
        '"weapon_plasmacannon": "plasma"',
        '"weapon_flamethrower": "flame"',
        "_weapon_visual_profile",
        "_spawn_weapon_muzzle_profile_vfx",
        "_spawn_rail_impact_vfx",
        "_spawn_scatter_impact_vfx",
        "_spawn_plasma_impact_vfx",
    ]:
        if runtime_key not in battle:
            errors.append(f"weapon-specific projectile VFX missing: {runtime_key}")
    for runtime_key in [
        "visual_profile",
        'profile := ""',
        '_projectile_texture_path(element, visual_profile)',
        '_projectile_sprite_scale(visual_profile)',
        '_projectile_color(element, visual_profile)',
        '"fire_round"',
        '"flame"',
        '"rail"',
        '"scatter"',
        '"plasma"',
    ]:
        if runtime_key not in projectile:
            errors.append(f"projectile-specific visual profile missing: {runtime_key}")
    if "if element == \"fire\" and profile == \"\":\n\t\tprofile = \"fire_round\"" not in battle:
        errors.append("ordinary fire bullets must use compact fire_round visual profile instead of the flamethrower plume")
    if "if element == \"fire\" and visual_profile == \"\":\n\t\tvisual_profile = \"fire_round\"" not in projectile:
        errors.append("projectile fire fallback must resolve to compact fire_round profile")
    if "暂无可释放目标" in battle:
        errors.append("character active skills must not fail silently or require targets; use fallback cast VFX instead")
    if 'icon.global_position = Vector2(512, 1420)' in battle:
        errors.append("skill acquisition must not leave a duplicate floating skill icon over the combat model")
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
    for runtime_key in ["_on_next_pressed", "_campaign_next_level", "_resolve_level_id", '"return_to": "result"', '"return_payload": _result_return_payload']:
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
