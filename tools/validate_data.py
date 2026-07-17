#!/usr/bin/env python3
from __future__ import annotations

import json
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
        check_asset(errors, pet_id, row, ["icon", "sprite"])

    for enemy_id, row in tables["zombies"].items():
        for key in ["weakness", "resist"]:
            value = row.get(key)
            if value != "none" and value not in elements:
                errors.append(f"{enemy_id}.{key} unknown: {value}")
        check_asset(errors, enemy_id, row, ["sprite"])

    for boss_id, row in tables["bosses"].items():
        if row.get("weakness") not in elements:
            errors.append(f"{boss_id}.weakness unknown: {row.get('weakness')}")
        for immune in row.get("immune", []):
            if immune not in elements:
                errors.append(f"{boss_id}.immune unknown: {immune}")
        check_asset(errors, boss_id, row, ["sprite"])

    for skill_id, row in tables["skills"].items():
        check_asset(errors, skill_id, row, ["icon"])
        ammo_element = row.get("ammo_element", "")
        if ammo_element and ammo_element not in elements:
            errors.append(f"{skill_id}.ammo_element unknown: {ammo_element}")
        if ammo_element and row.get("exclusive_group") != "projectile_element":
            errors.append(f"{skill_id}.ammo_element must declare exclusive_group projectile_element")

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
