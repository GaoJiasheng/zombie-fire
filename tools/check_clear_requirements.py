#!/usr/bin/env python3
"""校验 99 关三轴战力合同与运行时关卡数据保持同步。"""
from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import power_ruler_model as prm  # noqa: E402


def main() -> int:
    spec = importlib.util.spec_from_file_location("simulate_balance", ROOT / "tools" / "simulate_balance.py")
    sim = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(sim)

    levels = prm.load_table("levels")
    zombies = prm.load_table("zombies")
    bosses = prm.load_table("bosses")
    economy = prm.load_table("economy")
    characters = prm.load_table("characters")
    weapons = prm.load_table("weapons")
    chips = prm.load_table("chips")
    armors = prm.load_table("armors")
    pets = prm.load_table("pets")
    skills = prm.load_table("skills")
    ctx = prm.FamilyContext(sim, characters, weapons, economy)

    errors = []
    for level in levels:
        stored = level.get("clear_requirement")
        if not isinstance(stored, dict):
            errors.append(f"{level['id']}: missing clear_requirement (run generate_clear_requirements.py)")
            continue
        derived = prm.solve_required_t(level, zombies, bosses, chips, characters, weapons, ctx)
        for key in ("min_output", "mob_hp_share", "boss_hp_share"):
            got = float(stored.get(key, -1.0))
            want = float(derived[key])
            if abs(got - want) > max(abs(want) * 0.005, 0.0005):
                errors.append(f"{level['id']}.{key}: stored {got} != derived {want}")
        if stored.get("boss_id") != derived["boss_id"]:
            errors.append(f"{level['id']}.boss_id: stored {stored.get('boss_id')} != derived {derived['boss_id']}")
        stored_contract = stored.get("power_contract")
        if not isinstance(stored_contract, dict):
            errors.append(f"{level['id']}: missing bottleneck_v3 power_contract")
            continue
        derived_contract = prm.build_power_contract(
            level, derived, characters, weapons, skills, bosses, economy, sim)
        for key in (
            "model", "recommended_power", "crowd_capacity", "boss_capacity",
            "line_capacity", "boss_effective_hp", "runtime_boss_pressure_mult",
            "guaranteed_skill_ids", "reference_skill_rank", "boss_weights",
        ):
            if stored_contract.get(key) != derived_contract.get(key):
                errors.append(
                    f"{level['id']}.power_contract.{key}: stored "
                    f"{stored_contract.get(key)} != derived {derived_contract.get(key)}")

    # Owner-approved replay anchors. These are not cosmetic output snapshots:
    # the first is the max-free level_099 graduation build, the second is the
    # exact level_055 configuration whose 4096-vs-425 display contradicted a
    # real 53-second breach failure.
    by_id = {level["id"]: level for level in levels}
    all_max_skills = {skill_id: prm.skill_max_level(row) for skill_id, row in skills.items()}
    fixtures = (
        (
            "level_099", 4770, 4097, "boss",
            {
                "character": "vanguard", "character_level": 40,
                "weapon": "weapon_scattergun", "weapon_level": 50,
                "armor": "armor_kevlar", "armor_level": 35,
                "chip": "chip_attack", "chip_level": 35,
                "pet": "pet_turret_drone", "pet_level": 30,
                "signature_level": 5, "skill_base_levels": all_max_skills,
            },
        ),
        (
            "level_055", 401, 425, "line",
            {
                "character": "blaze", "character_level": 40,
                "weapon": "weapon_apocalypse_inferno", "weapon_level": 17,
                "armor": "armor_apocalypse_molten", "armor_level": 4,
                "chip": "chip_apocalypse_stellar", "chip_level": 21,
                "pet": "pet_apocalypse_phoenix", "pet_level": 15,
                "signature_level": 5, "skill_base_levels": all_max_skills,
            },
        ),
    )
    for level_id, expected_power, expected_recommended, expected_bottleneck, build in fixtures:
        level = by_id[level_id]
        outcome = prm.power_for_build(
            level, level["clear_requirement"]["power_contract"], build,
            characters, weapons, armors, chips, pets, skills, bosses, economy)
        if outcome["power"] != expected_power or outcome["recommended"] != expected_recommended:
            errors.append(
                f"{level_id} anchor: got {outcome['power']}/{outcome['recommended']} "
                f"expected {expected_power}/{expected_recommended}")
        if outcome["bottleneck"] != expected_bottleneck:
            errors.append(
                f"{level_id} anchor bottleneck: got {outcome['bottleneck']} "
                f"expected {expected_bottleneck}")

    if errors:
        print("Clear requirement check failed:")
        for e in errors:
            print(f"- {e}")
        return 1
    print(
        f"Power contract check OK: {len(levels)} levels in sync; "
        "level_099=4770/4097 (Boss), level_055=401/425 (line)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
