#!/usr/bin/env python3
"""Generate/check the weapon-axis calibration used by the power ruler.

The legacy ruler valued theoretical pellets, pierce, chain and status coverage
twice: once in ``_weapon_effective_dps`` and again in the permanent-skill
capacity axes.  That made a visually large number possible even when real
projectiles could not deliver the advertised Boss damage.

This tool anchors the free physical weapons to the checked-in Godot collider
benchmark, then transfers the audited relative DPS of the elemental and
premium families.  It writes dimensionless per-weapon crowd/Boss multipliers
to ``economy.power_ruler.weapon_runtime_axis_calibration``.  Runtime GDScript
and the Python generator both consume that one table; this file is the only
place where its measured inputs are assembled.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import power_ruler_model as prm  # noqa: E402

ECONOMY_PATH = ROOT / "data" / "economy.json"
BENCHMARK_PATH = ROOT / "tools" / "physical_endgame_runtime_benchmark.json"

# Relative outputs are guarded independently by audit_character_endgame_dps.py
# and the four premium audit tools in release CI.  Keeping these ratios here
# makes regeneration deterministic while those audits prevent their source
# calculations from silently drifting.
FREE_AUDIT = {
    "weapon_railgun": (122_945.0, 187_106.0),
    "weapon_plasmacannon": (140_523.0, 226_605.0),
    "weapon_cryocannon": (134_773.0, 206_673.0),
    "weapon_teslacoil": (133_358.0, 198_453.0),
}
PREMIUM_AUDIT_RATIOS = {
    "weapon_apocalypse_thunder": (1.579, 1.579),
    "weapon_apocalypse_inferno": (1.482, 1.662),
    "weapon_apocalypse_absolute_zero": (1.335, 1.746),
    "weapon_apocalypse_golden_law": (1.997, 2.090),
}

REFERENCE_LOADOUTS = {
    "weapon_autocannon": ("vanguard", "chip_attack", "pet_turret_drone"),
    "weapon_railgun": ("vanguard", "chip_attack", "pet_turret_drone"),
    "weapon_scattergun": ("vanguard", "chip_attack", "pet_turret_drone"),
    "weapon_flamethrower": ("blaze", "chip_element", "pet_fire_imp"),
    "weapon_plasmacannon": ("blaze", "chip_element", "pet_fire_imp"),
    "weapon_cryocannon": ("frost", "chip_element", "pet_fire_imp"),
    "weapon_teslacoil": ("volt", "chip_element", "pet_fire_imp"),
    "weapon_venomlauncher": ("vanguard", "chip_element", "pet_fire_imp"),
    "weapon_apocalypse_thunder": (
        "volt", "chip_apocalypse_superconductive", "pet_apocalypse_tempest"),
    "weapon_apocalypse_inferno": (
        "blaze", "chip_apocalypse_stellar", "pet_apocalypse_phoenix"),
    "weapon_apocalypse_absolute_zero": (
        "frost", "chip_apocalypse_entropy", "pet_apocalypse_aurora"),
    "weapon_apocalypse_golden_law": (
        "vanguard", "chip_apocalypse_golden_law", "pet_apocalypse_skyfalcon"),
}


def max_raw_capacities(weapon_id: str, characters: dict, weapons: dict,
                       chips: dict, pets: dict, skills: dict,
                       economy: dict) -> tuple[float, float]:
    character_id, chip_id, pet_id = REFERENCE_LOADOUTS[weapon_id]
    character = characters[character_id]
    weapon = weapons[weapon_id]
    chip = chips[chip_id]
    pet = pets[pet_id]
    offense = prm.offense_multiplier(
        character, weapon,
        int(character.get("max_level", 40)),
        int(weapon.get("max_level", 50)), 5,
        chip=chip, chip_level=int(chip.get("max_level", 35)),
        pet=pet, pet_level=int(pet.get("max_level", 30)),
    )
    max_skills = {
        skill_id: prm.skill_max_level(row) for skill_id, row in skills.items()
    }
    axes = prm.skill_capacity_profile(max_skills, skills, economy, 0.5)
    return offense * float(axes["crowd"]), offense * float(axes["boss"])


def target_runtime_dps(benchmark: dict) -> dict[str, tuple[float, float]]:
    physical = benchmark["best_same_loadout"]
    result = {
        weapon_id: (float(row["crowd_dps"]), float(row["boss_dps"]))
        for weapon_id, row in physical.items()
    }
    rail_crowd, rail_boss = result["weapon_railgun"]
    rail_audit_boss, rail_audit_crowd = FREE_AUDIT["weapon_railgun"]
    for weapon_id in ("weapon_plasmacannon", "weapon_cryocannon", "weapon_teslacoil"):
        audit_boss, audit_crowd = FREE_AUDIT[weapon_id]
        result[weapon_id] = (
            rail_crowd * audit_crowd / rail_audit_crowd,
            rail_boss * audit_boss / rail_audit_boss,
        )

    # Same-role free weapons without a dedicated collider fixture inherit the
    # measured conversion of their closest audited family. Their distinct raw
    # weapon stats still determine the final result.
    result["weapon_flamethrower"] = result["weapon_plasmacannon"]
    result["weapon_venomlauncher"] = result["weapon_teslacoil"]

    premium_base = {
        "weapon_apocalypse_thunder": "weapon_teslacoil",
        "weapon_apocalypse_inferno": "weapon_plasmacannon",
        "weapon_apocalypse_absolute_zero": "weapon_cryocannon",
        "weapon_apocalypse_golden_law": "weapon_railgun",
    }
    for weapon_id, base_id in premium_base.items():
        boss_ratio, crowd_ratio = PREMIUM_AUDIT_RATIOS[weapon_id]
        base_crowd, base_boss = result[base_id]
        result[weapon_id] = (base_crowd * crowd_ratio, base_boss * boss_ratio)
    return result


def generated_profiles(economy: dict) -> dict[str, dict[str, float]]:
    characters = prm.load_table("characters")
    weapons = prm.load_table("weapons")
    chips = prm.load_table("chips")
    pets = prm.load_table("pets")
    skills = prm.load_table("skills")
    benchmark = json.loads(BENCHMARK_PATH.read_text(encoding="utf-8"))
    targets = target_runtime_dps(benchmark)
    ruler = economy.get("power_ruler", {}) or {}
    crowd_units = max(float(ruler.get(
        "crowd_dps_per_capacity", prm.DEFAULT_CROWD_DPS_PER_CAPACITY)), 1.0)
    boss_units = max(float(ruler.get(
        "boss_dps_per_capacity", prm.DEFAULT_BOSS_DPS_PER_CAPACITY)), 1.0)
    profiles: dict[str, dict[str, float]] = {}
    for weapon_id in weapons:
        raw_crowd, raw_boss = max_raw_capacities(
            weapon_id, characters, weapons, chips, pets, skills, economy)
        target_crowd, target_boss = targets[weapon_id]
        profiles[weapon_id] = {
            "crowd": round(target_crowd / max(raw_crowd * crowd_units, 1.0), 6),
            "boss": round(target_boss / max(raw_boss * boss_units, 1.0), 6),
        }
    return profiles


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    economy = json.loads(ECONOMY_PATH.read_text(encoding="utf-8"))
    expected = generated_profiles(economy)
    ruler = economy.setdefault("power_ruler", {})
    stored = ruler.get("weapon_runtime_axis_calibration")
    if args.check:
        if stored != expected:
            print("weapon power profiles are stale; run generate_weapon_power_profiles.py")
            return 1
        print(f"Weapon power profiles OK: {len(expected)} weapons")
        return 0
    ruler["weapon_runtime_axis_calibration"] = expected
    ECONOMY_PATH.write_text(
        json.dumps(economy, ensure_ascii=False, indent="\t") + "\n",
        encoding="utf-8",
    )
    print(f"Wrote runtime-axis profiles for {len(expected)} weapons")
    for weapon_id, row in expected.items():
        print(f"  {weapon_id}: crowd={row['crowd']:.6f} boss={row['boss']:.6f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
