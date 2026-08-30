#!/usr/bin/env python3
"""Deterministic max-level audit for Polar Aurora + Absolute Zero Apocalypse.

The common evaluator includes every permanent progression bonus and every
maxed in-run projectile skill. This pass adds the premium-only Brittle/Shatter,
Aurora field, Permafrost counter and one-generation crystal wave. Boss, dense
and mixed ratios are checked separately so crowd payoff cannot hide weak or
excessive single-target performance.
"""

from __future__ import annotations

import json
import runpy
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
COMMON = runpy.run_path(
    str(ROOT / "tools/audit_character_endgame_dps.py"),
    run_name="absolute_zero_common",
)
DATA = ROOT / "data"


def load(name: str) -> dict:
    return json.loads((DATA / name).read_text(encoding="utf-8"))


def pet_skill_dps(pet: dict, target_equivalents: float) -> float:
    skill = pet["pet_skill"]
    level = COMMON["PET_LEVEL"]
    damage = float(pet["damage"]) * (
        1.0 + float(pet["level_damage_growth"]) * (level - 1)
    )
    damage *= float(skill["damage_mult"]) + float(
        skill["level_damage_mult_growth"]
    ) * (level - 1)
    return damage * target_equivalents / float(skill["cooldown"])


def linear_equivalents(count: int, edge_scale: float) -> float:
    return sum(
        1.0 + (edge_scale - 1.0) * index / max(count - 1, 1)
        for index in range(count)
    )


def main() -> int:
    weapons = COMMON["WEAPONS"]
    characters = COMMON["CHARACTERS"]
    chips = COMMON["CHIPS"]
    pets = COMMON["PETS"]
    economy = COMMON["ECONOMY"]
    armor = load("armors.json")["armor_apocalypse_permafrost"]
    set_row = load("premium_sets.json")["set_apocalypse_absolute_zero"]

    free = COMMON["best_result"](
        "frost", fire_rate_profile_id=COMMON["fire_rate_lab"].SHIPPING_PROFILE_ID
    )
    premium = COMMON["evaluate"](
        "frost",
        "chip_apocalypse_entropy",
        "pet_apocalypse_aurora",
        "weapon_apocalypse_absolute_zero",
        COMMON["fire_rate_lab"].SHIPPING_PROFILE_ID,
    )
    weapon = weapons["weapon_apocalypse_absolute_zero"]
    chip = chips["chip_apocalypse_entropy"]
    pet = pets["pet_apocalypse_aurora"]
    special = weapon["special"]

    _, fire_rate = COMMON["resolved_fire_rates"](
        characters["frost"], weapon, chip, pet,
        COMMON["fire_rate_lab"].SHIPPING_PROFILE_ID)
    hit_damage = premium.weapon_dps / max(
        fire_rate * COMMON["CONNECTED_LANES"], 0.001
    )

    efficiency = COMMON["chip_value"](chip, "brittle_efficiency")
    efficiency += float(set_row["two_piece"]["brittle_efficiency"])
    normal_threshold = max(
        3,
        round(float(special["brittle_hits"]) * (1.0 - min(efficiency, 0.44))),
    )
    boss_threshold = normal_threshold + int(special["boss_threshold_bonus"])
    shatter_multiplier = float(special["shatter_damage_mult"]) * (
        1.0
        + COMMON["chip_value"](chip, "shatter_damage_mult")
        + float(set_row["two_piece"]["shatter_damage_mult"])
    )

    free_pet = pets[free.pet_id]
    free_boss = free.total_dps + pet_skill_dps(free_pet, 1.0)
    free_dense = free.all_lanes_dps + pet_skill_dps(free_pet, 3.2)

    shatter_boss = premium.weapon_dps * shatter_multiplier / boss_threshold
    shatter_dense = (
        premium.all_lanes_dps
        * shatter_multiplier
        / normal_threshold
        * linear_equivalents(
            int(special["shatter_max_targets"]),
            float(special["shatter_falloff"]),
        )
    )

    counter_boss = (
        hit_damage
        * float(armor["counter_damage_mult"])
        / float(armor["counter_cooldown"])
    )
    counter_dense = counter_boss * linear_equivalents(
        int(armor["counter_max_targets"]), 0.56
    )

    four_piece = set_row["four_piece"]
    crystal_boss = (
        hit_damage
        * float(four_piece["crystal_wave_damage_mult"])
        / float(four_piece["crystal_wave_cooldown"])
    )
    crystal_equivalents = sum(
        float(four_piece["crystal_wave_falloff"]) ** index
        for index in range(int(four_piece["crystal_wave_max_targets"]))
    )
    crystal_dense = crystal_boss * crystal_equivalents

    premium_boss = (
        premium.total_dps
        + pet_skill_dps(pet, 1.0)
        + shatter_boss
        + counter_boss
        + crystal_boss
    )
    premium_dense = (
        premium.all_lanes_dps
        + pet_skill_dps(pet, 5.0)
        + shatter_dense
        + counter_dense
        + crystal_dense
    )
    free_mixed = 0.60 * free_boss + 0.40 * free_dense
    premium_mixed = 0.60 * premium_boss + 0.40 * premium_dense
    ratios = {
        "boss": premium_boss / free_boss,
        "dense": premium_dense / free_dense,
        "mixed": premium_mixed / free_mixed,
    }
    weighted = (
        0.40 * ratios["boss"]
        + 0.40 * ratios["dense"]
        + 0.20 * ratios["mixed"]
    )

    print("Absolute Zero Apocalypse max-level DPS audit (all skills maxed)")
    print(
        f"Brittle trigger: normal {normal_threshold} hits / boss {boss_threshold} hits; "
        "crystal wave generation 1"
    )
    print(f"Boss:  free {free_boss:,.0f} -> absolute zero {premium_boss:,.0f} = {ratios['boss']:.3f}x")
    print(f"Dense: free {free_dense:,.0f} -> absolute zero {premium_dense:,.0f} = {ratios['dense']:.3f}x")
    print(f"Mixed: free {free_mixed:,.0f} -> absolute zero {premium_mixed:,.0f} = {ratios['mixed']:.3f}x")
    print(
        f"Weighted 40/40/20: {weighted:.3f}x "
        f"(locked {set_row['target_full_set_ratio_min']:.2f}-"
        f"{set_row['target_full_set_ratio_max']:.2f}x)"
    )

    errors = []
    if not float(set_row["target_full_set_ratio_min"]) <= weighted <= float(
        set_row["target_full_set_ratio_max"]
    ):
        errors.append("weighted ratio outside locked paid-set band")
    if int(four_piece["generation_limit"]) != 1:
        errors.append("crystal wave must stay one generation")
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
