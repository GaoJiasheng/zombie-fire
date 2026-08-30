#!/usr/bin/env python3
"""Deterministic launch/max audit for Gilded Eclipse + Golden Law.

The opening check compares the Golden Law cannon with the strongest free
physical weapon before permanent growth.  The max check mirrors the live
weapon, chip, pet, Judgment/Verdict, Golden Decree and Eternal Night counter
formulas with every compatible run skill maxed.  Boss and dense pressure are
kept separate so the four-target decree cannot disguise weak single-target
output.
"""

from __future__ import annotations

import argparse
import json
import runpy
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
COMMON = runpy.run_path(
    str(ROOT / "tools/audit_character_endgame_dps.py"),
    run_name="golden_law_common",
)
DATA = ROOT / "data"


def load(name: str) -> dict:
    return json.loads((DATA / name).read_text(encoding="utf-8"))


def linear_equivalents(count: int, edge_scale: float) -> float:
    return sum(
        1.0 + (edge_scale - 1.0) * index / max(count - 1, 1)
        for index in range(count)
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--weapon-level", type=int, choices=(1, 25, 50, 65), default=65)
    args = parser.parse_args()
    weapon_level = int(args.weapon_level)
    weapons = COMMON["WEAPONS"]
    characters = COMMON["CHARACTERS"]
    chips = COMMON["CHIPS"]
    pets = COMMON["PETS"]
    economy = COMMON["ECONOMY"]
    armors = load("armors.json")
    set_row = load("premium_sets.json")["set_apocalypse_golden_law"]

    free = COMMON["best_result"](
        "vanguard", fire_rate_profile_id=COMMON["fire_rate_lab"].SHIPPING_PROFILE_ID
    )
    premium = COMMON["evaluate"](
        "vanguard",
        "chip_apocalypse_golden_law",
        "pet_apocalypse_skyfalcon",
        "weapon_apocalypse_golden_law",
        COMMON["fire_rate_lab"].SHIPPING_PROFILE_ID,
        weapon_level,
    )
    weapon = weapons["weapon_apocalypse_golden_law"]
    free_weapon = weapons["weapon_railgun"]
    chip = chips["chip_apocalypse_golden_law"]
    pet = pets["pet_apocalypse_skyfalcon"]
    armor = armors["armor_apocalypse_eternal_night"]
    free_armor = armors["armor_reactive"]
    special = weapon["special"]

    efficiency = COMMON["chip_value"](chip, "judgment_efficiency")
    efficiency += float(set_row["two_piece"]["judgment_efficiency"])
    threshold = max(
        3,
        round(float(special["judgment_hits"]) * (1.0 - min(efficiency, 0.48))),
    )
    verdict_multiplier = float(special["judgment_damage_mult"]) * (
        1.0
        + COMMON["chip_value"](chip, "verdict_damage_mult")
        + float(set_row["two_piece"]["verdict_damage_mult"])
    )
    verdict_boss = premium.weapon_dps * verdict_multiplier / threshold
    verdict_dense = premium.all_lanes_dps * verdict_multiplier / threshold

    pet_skill = pet["pet_skill"]
    pet_damage = float(pet["damage"]) * (
        1.0 + float(pet["level_damage_growth"]) * (COMMON["PET_LEVEL"] - 1)
    )
    pet_damage *= float(pet_skill["damage_mult"]) + float(
        pet_skill["level_damage_mult_growth"]
    ) * (COMMON["PET_LEVEL"] - 1)
    pet_skill_dps = pet_damage / float(pet_skill["cooldown"])
    mark_duration = float(pet_skill["mark_duration"]) + float(
        pet_skill["level_mark_duration_growth"]
    ) * (COMMON["PET_LEVEL"] - 1)
    mark_amp = float(pet_skill["mark_damage_amp"]) + float(
        pet_skill["level_mark_amp_growth"]
    ) * (COMMON["PET_LEVEL"] - 1)
    mark_uptime = min(mark_duration / float(pet_skill["cooldown"]), 1.0)
    mark_boss = premium.weapon_dps * mark_amp * mark_uptime
    # Skyfalcon marks one real target. Dense output therefore gains one lane,
    # not an invented screen-wide amplification.
    mark_dense = (
        premium.all_lanes_dps / COMMON["TOTAL_LANES"] * mark_amp * mark_uptime
    )

    _, fire_rate = COMMON["resolved_fire_rates"](
        characters["vanguard"], weapon, chip, pet,
        COMMON["fire_rate_lab"].SHIPPING_PROFILE_ID, weapon_level)
    hit_damage = premium.weapon_dps / max(
        fire_rate * COMMON["CONNECTED_LANES"], 0.001
    )
    decree = set_row["four_piece"]
    decree_boss = (
        hit_damage
        * float(decree["decree_damage_mult"])
        / float(decree["decree_cooldown"])
    )
    decree_equivalents = sum(
        float(decree["decree_falloff"]) ** index
        for index in range(int(decree["decree_max_targets"]))
    )
    decree_dense = decree_boss * decree_equivalents

    counter_boss = (
        hit_damage
        * float(armor["counter_damage_mult"])
        / float(armor["counter_cooldown"])
    )
    counter_dense = counter_boss * linear_equivalents(
        int(armor["counter_max_targets"]), 0.62
    )

    free_pet = pets[free.pet_id]
    free_pet_damage = float(free_pet.get("damage", 0.0)) * (
        1.0
        + float(free_pet.get("level_damage_growth", 0.0))
        * (COMMON["PET_LEVEL"] - 1)
    )
    free_boss = free.total_dps
    free_dense = free.all_lanes_dps
    if free_pet.get("pet_skill"):
        # The current best free Vanguard pet has no active skill, but preserve
        # a visible guard if the balance table changes later.
        free_boss += free_pet_damage / max(
            float(free_pet["pet_skill"].get("cooldown", 9999.0)), 1.0
        )

    premium_boss = (
        premium.total_dps
        + verdict_boss
        + mark_boss
        + pet_skill_dps
        + decree_boss
        + counter_boss
    )
    premium_dense = (
        premium.all_lanes_dps
        + verdict_dense
        + mark_dense
        + pet_skill_dps
        + decree_dense
        + counter_dense
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

    max_level = int(armor["max_level"])
    free_armor_max = int(free_armor["max_level"])
    armor_hp = float(armor["hp_mult"]) * (
        1.0 + float(armor["level_hp_growth"]) * (max_level - 1)
    )
    armor_hp *= 1.0 + float(armor["endgame_hp_growth_bonus"])
    free_armor_hp = float(free_armor["hp_mult"]) * (
        1.0 + float(free_armor["level_hp_growth"]) * (free_armor_max - 1)
    )
    armor_hp_ratio = armor_hp / free_armor_hp

    target_prefix = "target_level_50_ratio" if weapon_level <= 50 else "target_full_set_ratio"
    target_min = float(set_row[f"{target_prefix}_min"])
    target_max = float(set_row[f"{target_prefix}_max"])
    print(f"Golden Law Apocalypse Lv{weapon_level} progression audit (all compatible skills maxed)")
    print(
        f"Judgment: {threshold} confirmed hits; mark uptime {mark_uptime:.1%}; "
        f"raw max defense HP {armor_hp_ratio:.3f}x Reactive Armor before the extra breach shield/repair"
    )
    print(
        f"Boss:  free {free_boss:,.0f} -> Golden Law {premium_boss:,.0f} "
        f"= {ratios['boss']:.3f}x"
    )
    print(
        f"Dense: free {free_dense:,.0f} -> Golden Law {premium_dense:,.0f} "
        f"= {ratios['dense']:.3f}x"
    )
    print(
        f"Mixed: free {free_mixed:,.0f} -> Golden Law {premium_mixed:,.0f} "
        f"= {ratios['mixed']:.3f}x"
    )
    print(
        f"Weighted 40/40/20: {weighted:.3f}x "
        f"(locked {target_min:.2f}-{target_max:.2f}x)"
    )
    print(f"PROGRESSION_RATIO={weighted:.9f}")

    errors = []
    if not 1.82 <= armor_hp_ratio <= 1.96:
        errors.append("raw max defense HP outside 1.82-1.96x pre-utility band")
    if weapon_level in (50, 65) and not target_min <= weighted <= target_max:
        errors.append("weighted ratio outside locked paid-set band")
    if int(decree["generation_limit"]) != 1:
        errors.append("Golden Decree must remain one generation")
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
