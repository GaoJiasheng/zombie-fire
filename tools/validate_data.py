#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"

TABLES = [
    "elements",
    "economy",
    "challenges",
    "characters",
    "character_body_metrics",
    "weapons",
    "armors",
    "chips",
    "pets",
    "store_products",
    "premium_sets",
    "zombies",
    "bosses",
    "skills",
    "status_vfx",
    "environments",
    "levels",
    "localization_zh",
]


def load(name: str):
    path = DATA / f"{name}.json"
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def res_exists(res_path: str) -> bool:
    if not res_path.startswith("res://"):
        return False
    return (ROOT / res_path.removeprefix("res://")).exists()


def check_asset(errors: list[str], owner: str, row: dict, keys: list[str]) -> None:
    for key in keys:
        value = row.get(key)
        if value and not res_exists(value):
            errors.append(f"{owner}.{key} missing asset: {value}")


def main() -> int:
    errors: list[str] = []
    tables = {}
    for table in TABLES:
        try:
            tables[table] = load(table)
        except Exception as exc:
            errors.append(f"{table}.json failed to load: {exc}")

    if errors:
        print("\n".join(errors))
        return 1

    elements = set(tables["elements"].keys())
    zombies = set(tables["zombies"].keys())
    bosses = set(tables["bosses"].keys())
    environments = set(tables["environments"].keys())

    challenges = tables["challenges"]
    expected_chapters = {f"chapter_{index:02d}" for index in range(1, 11)}
    if set(challenges.keys()) != expected_chapters:
        errors.append("challenges.json must define chapter_01 through chapter_10 exactly")
    for challenge_id, row in challenges.items():
        for key in ("id", "name", "summary", "counter_hint"):
            if not str(row.get(key, "")).strip():
                errors.append(f"{challenge_id}.{key} missing")
        for key, low, high in (
            ("hp_mult", 1.0, 1.6),
            ("speed_mult", 1.0, 1.25),
            ("breach_damage_mult", 1.0, 1.25),
            ("mechanic_rate_mult", 1.0, 1.3),
            ("recommended_power_mult", 1.0, 2.0),
        ):
            value = float(row.get(key, 0.0))
            if not low <= value <= high:
                errors.append(f"{challenge_id}.{key} must be in [{low}, {high}], got {value}")

    skill_pressure = tables["economy"].get("run_skill_pressure")
    if not isinstance(skill_pressure, dict):
        errors.append("economy.run_skill_pressure must be an object")
    else:
        reference_picks = int(skill_pressure.get("reference_card_picks", 0))
        hp_conversion = float(skill_pressure.get("hp_conversion", -1.0))
        max_hp_mult = float(skill_pressure.get("max_hp_mult", 0.0))
        speed_conversion = float(skill_pressure.get("speed_conversion", -1.0))
        max_speed_mult = float(skill_pressure.get("max_speed_mult", 0.0))
        if reference_picks < 1:
            errors.append("economy.run_skill_pressure.reference_card_picks must be >= 1")
        if not 0.0 <= hp_conversion <= 1.0:
            errors.append("economy.run_skill_pressure.hp_conversion must be in [0, 1]")
        if not 1.0 <= max_hp_mult <= 2.0:
            errors.append("economy.run_skill_pressure.max_hp_mult must be in [1, 2]")
        if not 0.0 <= speed_conversion <= 0.5:
            errors.append("economy.run_skill_pressure.speed_conversion must be in [0, 0.5]")
        if not 1.0 <= max_speed_mult <= 1.5:
            errors.append("economy.run_skill_pressure.max_speed_mult must be in [1, 1.5]")

    economy = tables["economy"]
    fire_rate_profiles = economy.get("fire_rate_profiles")
    if not isinstance(fire_rate_profiles, dict):
        errors.append("economy.fire_rate_profiles must be an object")
    else:
        default_profile = str(fire_rate_profiles.get("default", ""))
        profile_order = fire_rate_profiles.get("order", [])
        profiles = fire_rate_profiles.get("profiles", {})
        if default_profile != "control":
            errors.append("economy.fire_rate_profiles.default must remain control")
        if profile_order != ["control", "tier_a", "tier_b"]:
            errors.append("economy.fire_rate_profiles.order must be control/tier_a/tier_b")
        if not isinstance(profiles, dict) or set(profiles) != {"control", "tier_a", "tier_b"}:
            errors.append("economy.fire_rate_profiles.profiles must define exactly control/tier_a/tier_b")
        else:
            control = profiles["control"]
            expected_control_salvo = [0.22, 0.44, 0.66, 0.9, 1.2]
            if control.get("salvo_fire_rate_mult") != expected_control_salvo:
                errors.append("economy.fire_rate_profiles.control must mirror authored skill_salvo values")
            if float(control.get("global_weapon_base_cap", -1.0)) != 0.0:
                errors.append("economy.fire_rate_profiles.control cap must remain infinite (0)")
            if float(control.get("removed_dps_compensation", -1.0)) != 0.0:
                errors.append("economy.fire_rate_profiles.control compensation must remain zero")
            for profile_id, cap in (("tier_a", 1.8), ("tier_b", 2.2)):
                profile = profiles[profile_id]
                if abs(float(profile.get("global_weapon_base_cap", 0.0)) - cap) > 1e-9:
                    errors.append(f"economy.fire_rate_profiles.{profile_id} cap must be {cap}")
                if abs(float(profile.get("removed_dps_compensation", 0.0)) - 0.5) > 1e-9:
                    errors.append(f"economy.fire_rate_profiles.{profile_id} compensation must be 0.5")
                if len(profile.get("salvo_fire_rate_mult", [])) != 5:
                    errors.append(f"economy.fire_rate_profiles.{profile_id} must define five salvo ranks")
    for table_key in ("late_wave_hp_bonus", "late_wave_count_mult", "late_wave_boss_hp_bonus"):
        value = economy.get(table_key)
        if not isinstance(value, dict) or not value:
            errors.append(f"economy.{table_key} must be a non-empty object")
        elif any(float(mult) < 1.0 for mult in value.values()):
            errors.append(f"economy.{table_key} multipliers must be >= 1.0")

    for rule_key in ("late_wave_level_ramp", "late_wave_count_level_ramp", "boss_survival_hp_ramp"):
        rule = economy.get(rule_key)
        if not isinstance(rule, dict):
            errors.append(f"economy.{rule_key} must be an object")
            continue
        start_level = int(rule.get("start_level", 0))
        full_level = int(rule.get("full_level", 0))
        final_level = int(rule.get("final_level", 0))
        max_mult = float(rule.get("max_mult", 0.0))
        final_mult = float(rule.get("final_mult", 0.0))
        curve_power = float(rule.get("curve_power", 0.0))
        if not 1 <= start_level < full_level <= final_level <= 99:
            errors.append(f"economy.{rule_key} levels must satisfy 1 <= start < full <= final <= 99")
        if max_mult < 1.0 or final_mult < 1.0 or curve_power <= 0.0:
            errors.append(f"economy.{rule_key} multipliers/curve must be positive and >= 1 where applicable")

    count_ramp = economy.get("late_wave_count_level_ramp", {})
    if isinstance(count_ramp, dict):
        if int(count_ramp.get("start_wave", 0)) < 3:
            errors.append("economy.late_wave_count_level_ramp.start_wave must be >= 3")
        if float(count_ramp.get("max_mult", 0.0)) > 1.5 or float(count_ramp.get("final_mult", 0.0)) > 1.2:
            errors.append("economy.late_wave_count_level_ramp exceeds the mobile crowd-density safety envelope")

    boss_survival = economy.get("boss_survival_hp_ramp", {})
    if isinstance(boss_survival, dict):
        if not 3.0 <= float(boss_survival.get("max_mult", 0.0)) <= 64.0:
            errors.append("economy.boss_survival_hp_ramp.max_mult must stay in [3, 64]")
        if float(boss_survival.get("final_mult", 0.0)) > 1.2:
            errors.append("economy.boss_survival_hp_ramp.final_mult must be <= 1.2")

    damage_ramp = economy.get("late_wave_damage_ramp")
    if not isinstance(damage_ramp, dict):
        errors.append("economy.late_wave_damage_ramp must be an object")
    else:
        if int(damage_ramp.get("start_wave", 0)) < 3:
            errors.append("economy.late_wave_damage_ramp.start_wave must be >= 3")
        if abs(float(damage_ramp.get("max_mult", 0.0)) - 1.0) > 1e-6:
            errors.append("economy.late_wave_damage_ramp.max_mult must stay at 1.0; late difficulty comes from HP/count")
        if abs(float(damage_ramp.get("final_mult", 0.0)) - 1.0) > 1e-6:
            errors.append("economy.late_wave_damage_ramp.final_mult must stay at 1.0; late difficulty comes from HP/count")

    for char_id, row in tables["characters"].items():
        if row.get("element_focus") not in elements:
            errors.append(f"{char_id}.element_focus unknown: {row.get('element_focus')}")
        active = row.get("active_skill", {})
        if not isinstance(active, dict):
            errors.append(f"{char_id}.active_skill must be an object")
        else:
            active_id = str(active.get("id", "")).strip()
            if not active_id:
                errors.append(f"{char_id}.active_skill.id missing")
            basis = str(active.get("scaling_basis", "")).strip()
            if basis not in {"weapon", "character"}:
                errors.append(f"{char_id}.active_skill.scaling_basis must be weapon or character, got: {basis}")
            coverage_mode = str(active.get("coverage_mode", "local")).strip()
            if coverage_mode not in {"local", "battlefield"}:
                errors.append(f"{char_id}.active_skill.coverage_mode must be local or battlefield, got: {coverage_mode}")
            if basis == "weapon" and float(active.get("level_damage_growth", 0.0)) > 0.01:
                errors.append(f"{char_id}.weapon-scaling active skill growth is too high: {active.get('level_damage_growth')}")
            if basis == "character" and float(active.get("level_damage_growth", 0.0)) <= 0.0:
                errors.append(f"{char_id}.character-scaling active skill must define positive level_damage_growth")
            weapon_level_inherit = float(active.get("weapon_level_inherit", 0.0))
            if not 0.0 <= weapon_level_inherit <= 1.0:
                errors.append(f"{char_id}.active_skill.weapon_level_inherit must be in [0, 1]")
            if basis == "weapon" and weapon_level_inherit > 0.0:
                errors.append(f"{char_id}.weapon-scaling active skill cannot also inherit weapon level")
            sig_damage = float(active.get("sig_level_damage_bonus", 0.0))
            sig_cooldown = float(active.get("sig_level_cooldown_reduction", 0.0))
            if not 0.0 < sig_damage <= 0.25:
                errors.append(f"{char_id}.active_skill.sig_level_damage_bonus must be in (0, 0.25]")
            if not 0.0 < sig_cooldown <= 0.08:
                errors.append(f"{char_id}.active_skill.sig_level_cooldown_reduction must be in (0, 0.08]")
            for threshold_key in ("sig_level_extra_pulse_levels", "sig_level_extra_wave_levels"):
                thresholds = active.get(threshold_key, [])
                if thresholds and (not isinstance(thresholds, list) or any(int(value) < 1 or int(value) > 5 for value in thresholds)):
                    errors.append(f"{char_id}.active_skill.{threshold_key} must contain levels in [1, 5]")
        affinity = row.get("bullet_affinity", {})
        if not isinstance(affinity, dict):
            errors.append(f"{char_id}.bullet_affinity must be an object")
        else:
            chain_overflow_bonus = float(affinity.get("chain_overflow_damage_bonus", 0.0))
            chain_falloff = float(affinity.get("chain_target_falloff", 1.0))
            chain_reference = int(affinity.get("chain_overflow_reference", 0))
            if not 0.0 <= chain_overflow_bonus <= 0.1:
                errors.append(f"{char_id}.bullet_affinity.chain_overflow_damage_bonus must be in [0, 0.1]")
            if not 0.72 <= chain_falloff <= 1.0:
                errors.append(f"{char_id}.bullet_affinity.chain_target_falloff must be in [0.72, 1]")
            if chain_reference < 0:
                errors.append(f"{char_id}.bullet_affinity.chain_overflow_reference must be >= 0")
        check_asset(errors, char_id, row, ["portrait"])

    body_metrics = tables["character_body_metrics"]
    if not isinstance(body_metrics, dict):
        errors.append("character_body_metrics.json must be an object")
    else:
        if body_metrics.get("canvas_size") != [380, 520]:
            errors.append("character_body_metrics.canvas_size must stay [380, 520]")
        target_height = float(body_metrics.get("target_body_height_px", 0.0))
        target_foot = float(body_metrics.get("target_foot_offset_px", 0.0))
        scale_reference_pose = str(body_metrics.get("scale_reference_pose", ""))
        if not 360.0 <= target_height <= 460.0:
            errors.append("character_body_metrics.target_body_height_px must stay in [360, 460]")
        if not 90.0 <= target_foot <= 140.0:
            errors.append("character_body_metrics.target_foot_offset_px must stay in [90, 140]")
        if scale_reference_pose != "center":
            errors.append("character_body_metrics.scale_reference_pose must stay center so static and firing frames share one model scale")
        profiles = body_metrics.get("profiles", {})
        if not isinstance(profiles, dict):
            errors.append("character_body_metrics.profiles must be an object")
            profiles = {}
        expected_characters = {f"char_{character_id}" for character_id in tables["characters"]}
        expected_profiles = {"standard"}
        expected_profiles.update(
            weapon_id
            for weapon_id, weapon in tables["weapons"].items()
            if weapon.get("presentation", {}).get("true_grip")
        )
        if set(profiles) != expected_profiles:
            errors.append(
                "character_body_metrics.profiles must match standard + every true-grip weapon: "
                f"got={sorted(profiles)} expected={sorted(expected_profiles)}"
            )
        for profile_id, profile in profiles.items():
            if not isinstance(profile, dict):
                errors.append(f"character_body_metrics.{profile_id} must be an object")
                continue
            if set(profile) != expected_characters:
                errors.append(
                    f"character_body_metrics.{profile_id} must cover all characters exactly"
                )
            required_poses = {"idle", "hurt", "left", "center", "right"} if profile_id == "standard" else {"left", "center", "right"}
            for character_asset_id, poses in profile.items():
                if not isinstance(poses, dict) or not required_poses.issubset(poses):
                    errors.append(
                        f"character_body_metrics.{profile_id}.{character_asset_id} missing poses: "
                        f"{sorted(required_poses - set(poses if isinstance(poses, dict) else {}))}"
                    )
                    continue
                for pose, metric in poses.items():
                    if not isinstance(metric, dict):
                        errors.append(f"character_body_metrics.{profile_id}.{character_asset_id}.{pose} must be an object")
                        continue
                    height = float(metric.get("body_height_px", 0.0))
                    foot_y = float(metric.get("foot_y_px", -1.0))
                    center_x = float(metric.get("body_center_x_px", -1.0))
                    if not 280.0 <= height <= 480.0:
                        errors.append(f"character body height out of range: {profile_id}/{character_asset_id}/{pose}={height}")
                    if not 400.0 <= foot_y <= 515.0:
                        errors.append(f"character foot anchor out of range: {profile_id}/{character_asset_id}/{pose}={foot_y}")
                    if not 130.0 <= center_x <= 250.0:
                        errors.append(f"character center anchor out of range: {profile_id}/{character_asset_id}/{pose}={center_x}")

    for weapon_id, row in tables["weapons"].items():
        if row.get("element") not in elements:
            errors.append(f"{weapon_id}.element unknown: {row.get('element')}")
        check_asset(errors, weapon_id, row, ["icon", "turret"])

    for armor_id, row in tables["armors"].items():
        resist = row.get("resist", "none")
        if resist != "none" and resist not in elements:
            errors.append(f"{armor_id}.resist unknown: {resist}")
        check_asset(errors, armor_id, row, ["icon"])

    for chip_id, row in tables["chips"].items():
        check_asset(errors, chip_id, row, ["icon"])

    for pet_id, row in tables["pets"].items():
        element = row.get("element")
        if element and element not in elements:
            errors.append(f"{pet_id}.element unknown: {element}")
        pet_skill = row.get("pet_skill")
        if not isinstance(pet_skill, dict) or not pet_skill:
            errors.append(f"{pet_id}.pet_skill missing")
            pet_skill = {}
        skill_kind = str(pet_skill.get("kind", ""))
        allowed_skill_kinds = {"overclock", "area_blast", "multi_strike", "fire_flyby", "golden_mark", "repair", "wave_salvage"}
        if skill_kind not in allowed_skill_kinds:
            errors.append(f"{pet_id}.pet_skill.kind unknown: {skill_kind}")
        if not str(pet_skill.get("id", "")).strip() or not str(pet_skill.get("name", "")).strip():
            errors.append(f"{pet_id}.pet_skill requires non-empty id and name")
        if skill_kind in {"overclock", "area_blast", "multi_strike", "fire_flyby", "golden_mark"}:
            cooldown = float(pet_skill.get("cooldown", 0.0))
            if not 8.0 <= cooldown <= 30.0:
                errors.append(f"{pet_id}.pet_skill.cooldown must be in [8, 30]")
            if not str(pet_skill.get("sequence", "")).strip() or not str(pet_skill.get("sfx", "")).strip():
                errors.append(f"{pet_id}.pet_skill requires sequence and sfx")
        if skill_kind == "overclock":
            if float(pet_skill.get("duration", 0.0)) <= 0.0:
                errors.append(f"{pet_id}.pet_skill.duration must be positive")
            if float(pet_skill.get("fire_rate_mult", 0.0)) < 1.0 or float(pet_skill.get("damage_mult", 0.0)) < 1.0:
                errors.append(f"{pet_id}.pet_skill overclock multipliers must be >= 1")
        elif skill_kind == "area_blast":
            if not 90.0 <= float(pet_skill.get("radius", 0.0)) <= 360.0:
                errors.append(f"{pet_id}.pet_skill.radius must be in [90, 360]")
            if float(pet_skill.get("damage_mult", 0.0)) <= 0.0:
                errors.append(f"{pet_id}.pet_skill.damage_mult must be positive")
        elif skill_kind == "multi_strike":
            if int(pet_skill.get("target_count", 0)) < 2:
                errors.append(f"{pet_id}.pet_skill.target_count must be >= 2")
            if int(pet_skill.get("extra_target_every", 0)) < 1:
                errors.append(f"{pet_id}.pet_skill.extra_target_every must be >= 1")
            if not 0.55 <= float(pet_skill.get("target_falloff", 0.0)) <= 1.0:
                errors.append(f"{pet_id}.pet_skill.target_falloff must be in [0.55, 1]")
        elif skill_kind == "golden_mark":
            if float(pet_skill.get("damage_mult", 0.0)) <= 0.0:
                errors.append(f"{pet_id}.pet_skill.damage_mult must be positive")
            if float(pet_skill.get("mark_duration", 0.0)) <= 0.0:
                errors.append(f"{pet_id}.pet_skill.mark_duration must be positive")
            if not 0.0 < float(pet_skill.get("mark_damage_amp", 0.0)) <= 0.5:
                errors.append(f"{pet_id}.pet_skill.mark_damage_amp must be in (0, 0.5]")
            if not 0.0 < float(pet_skill.get("repair_ratio", 0.0)) <= 0.1:
                errors.append(f"{pet_id}.pet_skill.repair_ratio must be in (0, 0.1]")
        elif skill_kind == "wave_salvage":
            if float(pet_skill.get("kill_equivalent", 0.0)) <= 0.0:
                errors.append(f"{pet_id}.pet_skill.kill_equivalent must be positive")
        if row.get("role") == "repair":
            required_repair_fields = [
                "heal_per_wave",
                "heal_per_wave_ratio",
                "repair_interval",
                "repair_ratio",
                "emergency_threshold",
                "emergency_heal_ratio",
                "emergency_cooldown",
            ]
            for field in required_repair_fields:
                if field not in row:
                    errors.append(f"{pet_id}.{field} missing for repair role")
            repair_bounds = {
                "heal_per_wave_ratio": (0.01, 0.12),
                "level_wave_heal_ratio_growth": (0.0, 0.005),
                "repair_interval": (10.0, 40.0),
                "repair_ratio": (0.003, 0.04),
                "level_repair_ratio_growth": (0.0, 0.002),
                "emergency_threshold": (0.2, 0.5),
                "emergency_heal_ratio": (0.04, 0.2),
                "level_emergency_heal_growth": (0.0, 0.006),
                "emergency_cooldown": (30.0, 120.0),
            }
            for field, bounds in repair_bounds.items():
                value = float(row.get(field, bounds[0] - 1.0))
                if not bounds[0] <= value <= bounds[1]:
                    errors.append(
                        f"{pet_id}.{field} must be in [{bounds[0]}, {bounds[1]}]"
                    )
        check_asset(errors, pet_id, row, ["icon", "sprite"])

    collection_tables = {
        "characters": tables["characters"],
        "weapons": tables["weapons"],
        "armors": tables["armors"],
        "chips": tables["chips"],
        "pets": tables["pets"],
    }
    paid_collection_total = 0
    for table_name, table in collection_tables.items():
        paid_prices = []
        for item_id, row in table.items():
            store_region = row.get("store_preview_region")
            if store_region is not None:
                if (
                    not isinstance(store_region, list)
                    or len(store_region) != 4
                    or any(not isinstance(value, (int, float)) for value in store_region)
                    or store_region[0] < 0
                    or store_region[1] < 0
                    or store_region[2] <= 0
                    or store_region[3] <= 0
                ):
                    errors.append(
                        f"{item_id}.store_preview_region must be [x,y,w,h] with a non-negative origin and positive size"
                    )
            if str(row.get("premium_entitlement", "")).strip():
                if int(row.get("unlock_cost_star", -1)) < 999999:
                    errors.append(f"{item_id} premium item must not be star-purchasable")
                continue
            price = int(row.get("unlock_cost_star", -1))
            if price < 0:
                errors.append(f"{item_id}.unlock_cost_star missing")
                continue
            if price > 0:
                paid_prices.append(price)
                paid_collection_total += price
            if table_name == "weapons":
                legacy_unlock = row.get("unlock", {})
                if isinstance(legacy_unlock, dict) and int(legacy_unlock.get("price", price)) != price:
                    errors.append(f"{item_id}.unlock.price must match unlock_cost_star")
        if paid_prices:
            if min(paid_prices) < 8 or max(paid_prices) > 16:
                errors.append(f"{table_name} paid star prices must stay in [8, 16]")
            if max(paid_prices) > min(paid_prices) * 2:
                errors.append(f"{table_name} star price curve exceeds 2x")
    if not 300 <= paid_collection_total <= 330:
        errors.append(f"paid collection total must stay in [300, 330], got {paid_collection_total}")

    premium_sets = tables["premium_sets"]
    store_products = tables["store_products"]
    themes = load("themes").get("themes", [])
    theme_by_id = {
        str(row.get("id", "")): row for row in themes if isinstance(row, dict)
    }
    theme_ids = set(theme_by_id)
    for theme_id, theme in theme_by_id.items():
        for key in ("name_zh", "name_en", "description_zh", "description_en", "ui", "effects"):
            if not theme.get(key):
                errors.append(f"theme {theme_id}.{key} missing")
        ui = theme.get("ui", {})
        button_root = str(ui.get("button_root", ""))
        if not button_root.startswith("res://") or not res_exists(button_root):
            errors.append(f"theme {theme_id}.ui.button_root missing: {button_root}")
        tag_palette = ui.get("tag_palette", {})
        required_tag_colors = (
            "border", "kind_border", "fill", "kind_fill", "text", "kind_text"
        )
        for color_key in required_tag_colors:
            color = tag_palette.get(color_key, []) if isinstance(tag_palette, dict) else []
            if (
                not isinstance(color, list)
                or len(color) != 4
                or any(not isinstance(channel, (int, float)) or channel < 0 or channel > 1 for channel in color)
            ):
                errors.append(
                    f"theme {theme_id}.ui.tag_palette.{color_key} must be four normalized RGBA channels"
                )
        for material_kind, material in theme.get("materials", {}).items():
            shader = str(material.get("shader", ""))
            if not res_exists(shader):
                errors.append(f"theme {theme_id}.materials.{material_kind}.shader missing: {shader}")
            if not isinstance(material.get("full"), dict) or not isinstance(material.get("reduced"), dict):
                errors.append(f"theme {theme_id}.materials.{material_kind} needs full/reduced parameter maps")
    premium_series: dict[str, tuple[str, dict]] = {}
    for set_id, set_row in premium_sets.items():
        series_id = str(set_row.get("series_id", "")).strip()
        entitlement = str(set_row.get("entitlement", "")).strip()
        theme_id = str(set_row.get("theme", "")).strip()
        theme_entitlement = str(set_row.get("theme_entitlement", "")).strip()
        if not series_id:
            errors.append(f"{set_id}.series_id missing")
        elif series_id in premium_series:
            errors.append(f"premium series_id duplicated: {series_id}")
        else:
            premium_series[series_id] = (set_id, set_row)
        if not entitlement:
            errors.append(f"{set_id}.entitlement missing")
        if theme_id not in theme_ids:
            errors.append(f"{set_id}.theme unknown: {theme_id}")
        if not theme_entitlement:
            errors.append(f"{set_id}.theme_entitlement missing")
        elif theme_id in theme_by_id and theme_by_id[theme_id].get("entitlement") != theme_entitlement:
            errors.append(f"{set_id}.theme_entitlement must match theme {theme_id}")
        for key in (
            "store_title_zh", "store_title_en", "owned_status_zh", "owned_status_en",
            "theme_status_zh", "theme_status_en", "theme_owned_description_zh",
            "theme_owned_description_en", "owned_title_zh", "owned_title_en",
            "dominance_zh", "dominance_en", "unlock_hint_zh", "unlock_hint_en",
            "unlock_cta_zh", "unlock_cta_en",
            "two_piece_description_zh", "two_piece_description_en",
        ):
            if not str(set_row.get(key, "")).strip():
                errors.append(f"{set_id}.{key} missing")
        contract_keys = (
            "target_full_set_ratio_min",
            "target_full_set_ratio_center",
            "target_full_set_ratio_max",
        )
        contract_values: list[float] = []
        for key in contract_keys:
            value = set_row.get(key)
            if not isinstance(value, (int, float)) or isinstance(value, bool) or float(value) <= 0.0:
                errors.append(f"{set_id}.{key} must be a positive number")
                contract_values = []
                break
            contract_values.append(float(value))
        if contract_values and not contract_values[0] <= contract_values[1] <= contract_values[2]:
            errors.append(f"{set_id} full-set contract must satisfy min <= center <= max")
        if series_id == "golden_law":
            opening_keys = (
                "target_level_one_ratio_min",
                "target_level_one_ratio_center",
                "target_level_one_ratio_max",
            )
            opening_values: list[float] = []
            for key in opening_keys:
                value = set_row.get(key)
                if not isinstance(value, (int, float)) or isinstance(value, bool) or float(value) <= 0.0:
                    errors.append(f"{set_id}.{key} must be a positive number")
                    opening_values = []
                    break
                opening_values.append(float(value))
            if opening_values and not opening_values[0] <= opening_values[1] <= opening_values[2]:
                errors.append(f"{set_id} opening contract must satisfy min <= center <= max")
        for slot, table_name in (
            ("weapon", "weapons"),
            ("armor", "armors"),
            ("chip", "chips"),
            ("pet", "pets"),
        ):
            item_id = str(set_row.get(slot, ""))
            if item_id not in tables[table_name]:
                errors.append(f"{set_id}.{slot} unknown: {item_id}")
                continue
            item_row = tables[table_name][item_id]
            if item_row.get("premium_entitlement") != entitlement:
                errors.append(f"{item_id} must require {entitlement}")
            if item_row.get("premium_set") != set_id:
                errors.append(f"{item_id}.premium_set must be {set_id}")

    for weapon_id, weapon in tables["weapons"].items():
        grip = weapon.get("presentation", {}).get("true_grip", {})
        if not grip:
            continue
        root = str(grip.get("root", "")).rstrip("/")
        size = grip.get("size", [])
        if not isinstance(size, list) or len(size) != 2 or min(map(int, size)) <= 0:
            errors.append(f"{weapon_id}.presentation.true_grip.size invalid")
        muzzle_by_character = grip.get("muzzle_by_character", {})
        for character_id in tables["characters"]:
            asset_id = f"char_{character_id}"
            for aim, pattern_key in (("center", "center_pattern"), ("left", "left_pattern"), ("right", "right_pattern")):
                pattern = str(grip.get(pattern_key, ""))
                candidate = f"{root}/{pattern.replace('{character_id}', asset_id)}"
                if not res_exists(candidate):
                    errors.append(f"{weapon_id} true-grip asset missing: {candidate}")
                muzzle = muzzle_by_character.get(asset_id, {}).get(aim, [])
                if not isinstance(muzzle, list) or len(muzzle) != 2:
                    errors.append(f"{weapon_id} true-grip muzzle missing: {asset_id}.{aim}")

    product_roles: dict[str, set[str]] = {series_id: set() for series_id in premium_series}
    for product_id, row in store_products.items():
        for key in (
            "series_id", "theme_id", "arsenal_set_id", "kind", "offer_role", "name_zh", "name_en",
            "mock_price_zh", "mock_price_en", "grants", "art", "preview_layout",
        ):
            if not row.get(key):
                errors.append(f"{product_id}.{key} missing")
        check_asset(errors, product_id, row, ["art"])
        series_id = str(row.get("series_id", ""))
        role = str(row.get("offer_role", ""))
        if series_id not in premium_series:
            errors.append(f"{product_id}.series_id unknown: {series_id}")
            continue
        if role not in {"theme", "arsenal_complete", "arsenal_upgrade"}:
            errors.append(f"{product_id}.offer_role invalid: {role}")
            continue
        if row.get("kind") != role:
            errors.append(f"{product_id}.kind must match offer_role")
        expected_preview_layout = "theme_roster" if role == "theme" else "arsenal_grid"
        if row.get("preview_layout") != expected_preview_layout:
            errors.append(
                f"{product_id}.preview_layout must be {expected_preview_layout} for {role}"
            )
        if role in product_roles[series_id]:
            errors.append(f"{series_id} has duplicate {role} offer")
        product_roles[series_id].add(role)
        set_id, set_row = premium_series[series_id]
        if row.get("theme_id") != set_row.get("theme"):
            errors.append(f"{product_id}.theme_id must be {set_row.get('theme')}")
        if row.get("arsenal_set_id") != set_id:
            errors.append(f"{product_id}.arsenal_set_id must be {set_id}")
        theme_entitlement = str(set_row.get("theme_entitlement", ""))
        arsenal_entitlement = str(set_row.get("entitlement", ""))
        expected_grants = {
            "theme": {theme_entitlement},
            "arsenal_complete": {theme_entitlement, arsenal_entitlement},
            "arsenal_upgrade": {arsenal_entitlement},
        }[role]
        if set(map(str, row.get("grants", []))) != expected_grants:
            errors.append(f"{product_id}.grants must be {sorted(expected_grants)}")
    for series_id, roles in product_roles.items():
        expected_roles = {"theme", "arsenal_complete", "arsenal_upgrade"}
        if roles != expected_roles:
            errors.append(f"{series_id} offers must define {sorted(expected_roles)}, got {sorted(roles)}")

    for enemy_id, row in tables["zombies"].items():
        for key in ["weakness", "resist"]:
            value = row.get(key)
            if value != "none" and value not in elements:
                errors.append(f"{enemy_id}.{key} unknown: {value}")
        check_asset(errors, enemy_id, row, ["sprite"])
        attack = row.get("attack_animation", {})
        if not isinstance(attack, dict) or not attack:
            errors.append(f"{enemy_id}.attack_animation missing")
            continue
        if not str(attack.get("mode", "")).strip():
            errors.append(f"{enemy_id}.attack_animation.mode missing")
        duration = float(attack.get("duration", 0.0))
        contact_ratio = float(attack.get("contact_ratio", 0.0))
        contact_frame = int(attack.get("contact_frame", 0))
        lunge = float(attack.get("lunge", -1.0))
        if not 0.32 <= duration <= 0.8:
            errors.append(
                f"{enemy_id}.attack_animation.duration must be in [0.32, 0.8]"
            )
        if not 0.35 <= contact_ratio <= 0.68:
            errors.append(
                f"{enemy_id}.attack_animation.contact_ratio must be in [0.35, 0.68]"
            )
        if contact_frame != 4:
            errors.append(
                f"{enemy_id}.attack_animation.contact_frame must be authored frame 4"
            )
        if not 0.0 <= lunge <= 40.0:
            errors.append(
                f"{enemy_id}.attack_animation.lunge must be in [0, 40]"
            )

    boss_base_attack_profiles: set[str] = set()
    for boss_id, row in tables["bosses"].items():
        fixed_hp = row.get("fixed_hp", 0)
        if not isinstance(fixed_hp, (int, float)) or float(fixed_hp) <= 0.0:
            errors.append(f"{boss_id}.fixed_hp must be a positive, model-stable durability budget")
        if row.get("weakness") not in elements:
            errors.append(f"{boss_id}.weakness unknown: {row.get('weakness')}")
        if row.get("immune"):
            errors.append(f"{boss_id}.immune is retired; use bounded resistances instead")
        resistances = row.get("resistances", {})
        if not isinstance(resistances, dict):
            errors.append(f"{boss_id}.resistances must be an element -> reduction dictionary")
            resistances = {}
        for element, reduction in resistances.items():
            if element not in elements:
                errors.append(f"{boss_id}.resistances unknown element: {element}")
                continue
            if not isinstance(reduction, (int, float)) or not 0.0 < float(reduction) < 1.0:
                errors.append(f"{boss_id}.resistances.{element} must be a reduction in (0, 1)")
        armor_hp_ratio = row.get("armor_hp_ratio", 0.0)
        if not isinstance(armor_hp_ratio, (int, float)) or not 0.0 <= float(armor_hp_ratio) <= 0.6:
            errors.append(f"{boss_id}.armor_hp_ratio must be a total-durability share in [0, 0.6]")
        check_asset(errors, boss_id, row, ["sprite"])
        mechanic_params = row.get("mechanic_params", {})
        if row.get("mechanic") in {"regen", "regenerate"}:
            for field in (
                "regen_pct_per_sec",
                "damage_regen_suppress_seconds",
                "weakness_regen_suppress_seconds",
            ):
                if not isinstance(mechanic_params, dict) or float(mechanic_params.get(field, 0.0)) <= 0.0:
                    errors.append(f"{boss_id}.mechanic_params.{field} must be explicit and positive")
        profile = mechanic_params.get("base_attack_profile", {}) if isinstance(mechanic_params, dict) else {}
        if not isinstance(profile, dict) or not profile:
            errors.append(f"{boss_id}.mechanic_params.base_attack_profile missing")
            continue
        profile_id = str(profile.get("id", "")).strip()
        if not profile_id:
            errors.append(f"{boss_id}.base_attack_profile.id missing")
        elif profile_id in boss_base_attack_profiles:
            errors.append(f"{boss_id}.base_attack_profile.id duplicated: {profile_id}")
        else:
            boss_base_attack_profiles.add(profile_id)
        if profile.get("mode") not in {"melee_heavy", "ranged_volley", "channel", "dash_combo"}:
            errors.append(f"{boss_id}.base_attack_profile.mode unknown: {profile.get('mode')}")
        if profile.get("element") not in elements:
            errors.append(f"{boss_id}.base_attack_profile.element unknown: {profile.get('element')}")
        for element in profile.get("hit_elements", []):
            if element not in elements:
                errors.append(f"{boss_id}.base_attack_profile.hit_elements unknown: {element}")
        hits = int(profile.get("hits", 0))
        if not 1 <= hits <= 6:
            errors.append(f"{boss_id}.base_attack_profile.hits must be in [1, 6], got {hits}")
        hit_colors = profile.get("hit_colors", [])
        if hit_colors and (
            not isinstance(hit_colors, list)
            or len(hit_colors) != hits
            or any(not re.fullmatch(r"[0-9a-fA-F]{6}", str(color)) for color in hit_colors)
        ):
            errors.append(
                f"{boss_id}.base_attack_profile.hit_colors must contain one RRGGBB value per hit"
            )
        if not 0.15 <= float(profile.get("windup", 0.0)) <= 1.2:
            errors.append(f"{boss_id}.base_attack_profile.windup must be in [0.15, 1.2]")
        if not 0.0 <= float(profile.get("travel_time", -1.0)) <= 0.5:
            errors.append(f"{boss_id}.base_attack_profile.travel_time must be in [0, 0.5]")
        if not -340.0 <= float(profile.get("line_offset", 0.0)) <= -40.0:
            errors.append(f"{boss_id}.base_attack_profile.line_offset must be in [-340, -40]")
        if not str(profile.get("label", "")).strip():
            errors.append(f"{boss_id}.base_attack_profile.label missing")
        for sequence_key in ("cast_sequence", "impact_sequence"):
            sequence_id = str(profile.get(sequence_key, "")).strip()
            sequence_path = (
                ROOT
                / "assets"
                / "production"
                / "sprites"
                / "vfx_sequences"
                / sequence_id
                / f"{sequence_id}_sequence.json"
            )
            if not sequence_id or not sequence_path.exists():
                errors.append(
                    f"{boss_id}.base_attack_profile.{sequence_key} missing sequence: {sequence_id}"
                )
        if profile.get("mode") == "channel":
            for texture_key in ("beam_texture", "impact_texture"):
                texture_path = str(profile.get(texture_key, "")).strip()
                if not texture_path.startswith("res://"):
                    errors.append(
                        f"{boss_id}.base_attack_profile.{texture_key} must be a res:// path"
                    )
                    continue
                local_path = ROOT / texture_path.removeprefix("res://")
                if not local_path.exists():
                    errors.append(
                        f"{boss_id}.base_attack_profile.{texture_key} missing: {texture_path}"
                    )

    for skill_id, row in tables["skills"].items():
        check_asset(errors, skill_id, row, ["icon"])
        ammo_element = row.get("ammo_element", "")
        if ammo_element and ammo_element not in elements:
            errors.append(f"{skill_id}.ammo_element unknown: {ammo_element}")
        if ammo_element and row.get("exclusive_group") != "projectile_element":
            errors.append(f"{skill_id}.ammo_element must declare exclusive_group projectile_element")

    status_vfx = tables["status_vfx"]
    required_statuses = {"fire", "ice", "glacier", "poison", "lightning"}
    if not isinstance(status_vfx, dict):
        errors.append("status_vfx.json must be an object")
    else:
        global_row = status_vfx.get("global", {})
        if not isinstance(global_row, dict):
            errors.append("status_vfx.global must be an object")
        else:
            if not 0.03 <= float(global_row.get("fade_in", 0.0)) <= 0.3:
                errors.append("status_vfx.global.fade_in must be in [0.03, 0.3]")
            if not 0.1 <= float(global_row.get("fade_out", 0.0)) <= 0.5:
                errors.append("status_vfx.global.fade_out must be in [0.1, 0.5]")
            full_max = int(global_row.get("full_density_max", 0))
            condensed_max = int(global_row.get("condensed_density_max", 0))
            if full_max < 8 or condensed_max <= full_max:
                errors.append(
                    "status_vfx density thresholds must satisfy full_density_max >= 8 "
                    "and condensed_density_max > full_density_max"
                )
        missing_statuses = required_statuses - set(status_vfx.keys())
        if missing_statuses:
            errors.append(
                f"status_vfx missing required states: {', '.join(sorted(missing_statuses))}"
            )
        for status_id in sorted(required_statuses & set(status_vfx.keys())):
            row = status_vfx[status_id]
            if not isinstance(row, dict):
                errors.append(f"status_vfx.{status_id} must be an object")
                continue
            sequence_id = str(row.get("sequence", "")).strip()
            sequence_json = (
                ROOT
                / "assets"
                / "production"
                / "sprites"
                / "vfx_sequences"
                / sequence_id
                / f"{sequence_id}_sequence.json"
            )
            if not sequence_id or not sequence_json.exists():
                errors.append(
                    f"status_vfx.{status_id}.sequence missing: {sequence_id}"
                )
            ground_texture = str(row.get("ground_texture", "")).strip()
            if not res_exists(ground_texture):
                errors.append(
                    f"status_vfx.{status_id}.ground_texture missing: {ground_texture}"
                )
            for color_key in ("tint", "ground_tint"):
                if not re.fullmatch(r"[0-9a-fA-F]{6}", str(row.get(color_key, ""))):
                    errors.append(
                        f"status_vfx.{status_id}.{color_key} must be RRGGBB"
                    )
            for scale_key in ("normal_scale", "boss_scale", "alpha", "ground_alpha"):
                if float(row.get(scale_key, 0.0)) <= 0.0:
                    errors.append(f"status_vfx.{status_id}.{scale_key} must be > 0")
            for vector_key in (
                "normal_offset",
                "boss_offset",
                "ground_normal_scale",
                "ground_boss_scale",
                "ground_normal_offset",
                "ground_boss_offset",
                "secondary_offset",
            ):
                value = row.get(vector_key)
                if not isinstance(value, list) or len(value) != 2:
                    errors.append(
                        f"status_vfx.{status_id}.{vector_key} must contain two numbers"
                    )

    for env_id, row in tables["environments"].items():
        if not str(row.get("name", "")).strip():
            errors.append(f"{env_id}.name missing")
        if str(row.get("bgm", "")).strip() == "":
            errors.append(f"{env_id}.bgm missing")
        check_asset(errors, env_id, row, ["battle_background", "portrait", "layout_guide"])

    seen_levels = set()
    for level in tables["levels"]:
        level_id = level.get("id")
        if not level_id:
            errors.append("level row missing id")
            continue
        seen_levels.add(level_id)
        level_name = str(level.get("name", "")).strip()
        if len(level_name) != 4:
            errors.append(f"{level_id} must define a four-character display name, got: {level_name}")
        elif any(ord(char) < 128 for char in level_name):
            errors.append(f"{level_id} display name must not contain ASCII characters: {level_name}")
        if len(level.get("waves", [])) != 5:
            errors.append(f"{level_id} must define exactly 5 waves")
        env_id = level.get("env", "")
        if env_id not in environments:
            errors.append(f"{level_id} unknown env: {env_id}")
        for wave in level.get("waves", []):
            wave_hp_coef = wave.get("hp_coef", 1.0)
            if not isinstance(wave_hp_coef, (int, float)) or float(wave_hp_coef) <= 0.0:
                errors.append(f"{level_id} wave {wave.get('wave')} hp_coef must be a positive number")
            if "boss" in wave and wave["boss"] not in bosses:
                errors.append(f"{level_id} unknown boss: {wave['boss']}")
            for group in wave.get("spawns", []) + wave.get("support", []):
                if group.get("type") not in zombies:
                    errors.append(f"{level_id} unknown zombie: {group.get('type')}")

    for level in tables["levels"]:
        next_level = level.get("next_level", "")
        if next_level and next_level not in seen_levels:
            errors.append(f"{level['id']} next_level unknown: {next_level}")
    for idx, level in enumerate(tables["levels"][:-1]):
        expected_next = tables["levels"][idx + 1].get("id", "")
        if level.get("next_level", "") != expected_next:
            errors.append(f"{level['id']} next_level must progress to {expected_next}, got {level.get('next_level', '')}")
    if tables["levels"] and tables["levels"][-1].get("next_level", "") != "":
        errors.append(f"{tables['levels'][-1]['id']} final next_level must be empty")

    if errors:
        print("Data validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print(f"Data validation passed: {len(tables['levels'])} levels, {len(zombies)} zombies, {len(bosses)} boss, {len(tables['skills'])} skills, {len(environments)} environments, {len(challenges)} challenge rules")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
