#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"

TABLES = [
    "elements",
    "economy",
    "characters",
    "weapons",
    "armors",
    "chips",
    "pets",
    "zombies",
    "bosses",
    "skills",
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

    for char_id, row in tables["characters"].items():
        if row.get("element_focus") not in elements:
            errors.append(f"{char_id}.element_focus unknown: {row.get('element_focus')}")
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

    print(f"Data validation passed: {len(tables['levels'])} levels, {len(zombies)} zombies, {len(bosses)} boss, {len(tables['skills'])} skills")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
