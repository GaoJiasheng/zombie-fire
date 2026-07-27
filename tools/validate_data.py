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
    "weapons",
    "armors",
    "chips",
    "pets",
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
        allowed_skill_kinds = {"overclock", "area_blast", "multi_strike", "repair", "wave_salvage"}
        if skill_kind not in allowed_skill_kinds:
            errors.append(f"{pet_id}.pet_skill.kind unknown: {skill_kind}")
        if not str(pet_skill.get("id", "")).strip() or not str(pet_skill.get("name", "")).strip():
            errors.append(f"{pet_id}.pet_skill requires non-empty id and name")
        if skill_kind in {"overclock", "area_blast", "multi_strike"}:
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
        if row.get("weakness") not in elements:
            errors.append(f"{boss_id}.weakness unknown: {row.get('weakness')}")
        for immune in row.get("immune", []):
            if immune not in elements:
                errors.append(f"{boss_id}.immune unknown: {immune}")
        check_asset(errors, boss_id, row, ["sprite"])
        mechanic_params = row.get("mechanic_params", {})
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
