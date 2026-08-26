#!/usr/bin/env python3
"""校验 99 关三轴战力合同与运行时关卡数据保持同步。"""
from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import power_ruler_model as prm  # noqa: E402
import campaign_runtime_contracts as runtime_contracts  # noqa: E402


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
        level_no = int(str(level["id"]).split("_")[-1])
        if runtime_contracts.clear_requirement_mode(level_no) == "preserve_v5_scale":
            mob_hp, boss_hp, _count = sim.level_enemy_hp_split(level, zombies, bosses, economy)
            derived = runtime_contracts.preserve_v5_requirement(
                level_no, stored, mob_hp, boss_hp, prm._boss_id(level))
        else:
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
            errors.append(f"{level['id']}: missing bottleneck_v5 power_contract")
            continue
        derived_contract = prm.build_power_contract(
            level, derived, characters, weapons, skills, bosses, economy, sim)
        for key in (
            "model", "recommended_power", "crowd_capacity", "boss_capacity",
            "line_capacity", "line_expected_breach", "line_base_hp",
            "line_target_hp_ratio", "line_exposure_weights",
            "boss_effective_hp", "runtime_boss_pressure_mult",
            "guaranteed_skill_ids", "reference_skill_rank", "boss_weights",
            "corridor_calibration", "runtime_replay_calibration",
            "post_replay_corridor_guard",
        ):
            if stored_contract.get(key) != derived_contract.get(key):
                errors.append(
                    f"{level['id']}.power_contract.{key}: stored "
                    f"{stored_contract.get(key)} != derived {derived_contract.get(key)}")

    # Outcome-backed replay fixtures. Absolute display numbers may change when
    # the runtime collider profile or authored roster changes; the checked-in
    # ratio and bottleneck are the durable player-facing contract.
    by_id = {level["id"]: level for level in levels}
    fixtures = (
        (
            "level_099", 1667, 1437, 1.1600, "boss",
        ),
        (
            "level_080", 1038, 989, 1.0500, "boss",
        ),
    )
    anchor_summaries = []
    for level_id, expected_power, expected_recommended, expected_ratio, expected_bottleneck in fixtures:
        level = by_id[level_id]
        build = prm.owner_anchor_fixture(level_id, skills)
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
        ratio = min(float(value) for value in outcome["ratios"].values())
        if abs(ratio - expected_ratio) > 0.02:
            errors.append(
                f"{level_id} anchor ratio: got {ratio:.4f}, "
                f"expected {expected_ratio:.4f}±0.02")
        anchor_summaries.append(
            f"{level_id}={outcome['power']}/{outcome['recommended']} "
            f"R={ratio:.4f} ({outcome['bottleneck']})")

    # design/32 full-campaign corridor. The fixture is defined once in
    # power_ruler_model.py and also serialized into each generated contract so
    # the Godot smoke test consumes the same manifest instead of cloning it.
    corridor_rows = []
    for level in levels:
        ordinal = prm.campaign_ordinal(level)
        if ordinal < 2 or ordinal > 98:
            continue
        contract = level["clear_requirement"]["power_contract"]
        build, manifest = prm.corridor_calibration_fixture(
            level, characters, weapons, armors, chips, pets, skills)
        outcome = prm.power_for_build(
            level, contract, build, characters, weapons, armors, chips, pets,
            skills, bosses, economy)
        ratio = min(float(value) for value in outcome["ratios"].values())
        lower = prm.PACE_CORRIDOR_MIN if ordinal <= 70 else prm.LATE_CORRIDOR_MIN
        if not (lower - 0.0001 <= ratio <= prm.CORRIDOR_MAX + 0.0001):
            errors.append(
                f"{level['id']} corridor {manifest['family']}: R={ratio:.4f} "
                f"outside [{lower:.2f},{prm.CORRIDOR_MAX:.2f}]")
        corridor_rows.append((level["id"], ratio, outcome["bottleneck"]))

    # Resistance case A: the retired level_055 hard immunity is now a bounded
    # 25% physical reduction. A maxed free build may clear it, but the model
    # must still preserve the authored 0.75x / 1.5x matchup identity instead of
    # silently treating both elements as neutral.
    physical_offense = prm.offense_multiplier(
        characters["vanguard"], weapons["weapon_autocannon"], 40, 50, 5,
        chip=chips["chip_attack"], chip_level=35,
        pet=pets["pet_turret_drone"], pet_level=30)
    physical_survival = prm.survival_multiplier(
        characters["vanguard"], 40, weapons["weapon_autocannon"],
        armors["armor_kevlar"], 35, chips["chip_attack"], 35,
        pets["pet_turret_drone"], 30)
    contract55 = by_id["level_055"]["clear_requirement"]["power_contract"]
    physical55_ratios = {
        "crowd": physical_offense * prm.weapon_axis_calibration(
            economy, "weapon_autocannon", "crowd") / float(contract55["crowd_capacity"]),
        "boss": physical_offense * prm.weapon_axis_calibration(
            economy, "weapon_autocannon", "boss") * prm.weighted_boss_element_factor(
            contract55["boss_weights"], bosses, "physical", economy
        ) / float(contract55["boss_capacity"]),
    }
    physical55_raw_line = physical_survival / float(contract55["line_capacity"])
    physical55_ratios["line"] = physical55_raw_line * prm.line_exposure_credit(
        physical55_ratios["crowd"], physical55_ratios["boss"], contract55, economy)
    physical55_ratio = min(physical55_ratios.values())
    physical55_factor = prm.weighted_boss_element_factor(
        contract55["boss_weights"], bosses, "physical", economy)
    lightning55_factor = prm.weighted_boss_element_factor(
        contract55["boss_weights"], bosses, "lightning", economy)
    if abs(physical55_factor - 0.75) > 1e-6:
        errors.append(
            f"level_055 physical resistance must leave a 0.75 damage factor, "
            f"got {physical55_factor:.4f}")
    if abs(lightning55_factor - 1.5) > 1e-6:
        errors.append(
            f"level_055 lightning weakness must provide a 1.5 damage factor, "
            f"got {lightning55_factor:.4f}")
    if abs(physical55_factor * 2.0 - lightning55_factor) > 1e-6:
        errors.append(
            "level_055 resistance/weakness spread must remain a readable 0.75x/1.5x")

    # Reverse case B: halving the offensive cadence at level_085 must remain
    # visibly under the clear line even though survival is unchanged.
    level85 = by_id["level_085"]
    contract85 = level85["clear_requirement"]["power_contract"]
    build85, _ = prm.corridor_calibration_fixture(
        level85, characters, weapons, armors, chips, pets, skills)
    full85 = prm.power_for_build(
        level85, contract85, build85, characters, weapons, armors, chips, pets,
        skills, bosses, economy)
    half85_ratios = {
        "crowd": float(full85["capacities"]["crowd"]) * 0.5 / float(contract85["crowd_capacity"]),
        "boss": float(full85["capacities"]["boss"]) * 0.5 / float(contract85["boss_capacity"]),
    }
    half85_raw_line = float(full85["capacities"]["line"]) / float(contract85["line_capacity"])
    half85_ratios["line"] = half85_raw_line * prm.line_exposure_credit(
        half85_ratios["crowd"], half85_ratios["boss"], contract85, economy)
    half85_ratio = min(half85_ratios.values())
    if half85_ratio >= 1.0:
        errors.append(f"level_085 half-speed reverse case must stay <1.0, got {half85_ratio:.4f}")

    thunder_l1 = {
        "character": "vanguard", "character_level": 1,
        "weapon": "weapon_apocalypse_thunder", "weapon_level": 1,
        "armor": "armor_apocalypse_conductor", "armor_level": 1,
        "chip": "chip_apocalypse_superconductive", "chip_level": 1,
        "pet": "pet_apocalypse_tempest", "pet_level": 1,
        "signature_level": 0, "skill_base_levels": {},
    }
    level13 = by_id["level_013"]
    thunder13 = prm.power_for_build(
        level13, level13["clear_requirement"]["power_contract"], thunder_l1,
        characters, weapons, armors, chips, pets, skills, bosses, economy)
    thunder13_ratio = min(float(value) for value in thunder13["ratios"].values())
    if thunder13_ratio > 1.8:
        errors.append(
            f"level_013 Thunder L1 optimism R={thunder13_ratio:.4f} exceeds Owner review gate 1.8")

    if errors:
        print("Clear requirement check failed:")
        for e in errors:
            print(f"- {e}")
        return 1
    print(f"Power contract check OK: {len(levels)} levels in sync")
    print("anchors: " + " | ".join(anchor_summaries))
    print(
        f"corridor: {len(corridor_rows)} levels in band; "
        f"R=[{min(row[1] for row in corridor_rows):.4f},"
        f"{max(row[1] for row in corridor_rows):.4f}]")
    print(
        f"resistance: physical@055={physical55_ratio:.4f} "
        f"(factor={physical55_factor:.2f}, weak={lightning55_factor:.2f}); "
        f"half-speed@085={half85_ratio:.4f}; "
        f"Thunder-L1@013={thunder13_ratio:.4f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
