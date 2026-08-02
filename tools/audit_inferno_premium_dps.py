#!/usr/bin/env python3
"""Deterministic three-scenario audit for the complete Inferno Apocalypse set.

The common max-level weapon/skill/character formulas are imported from the
existing four-hero endgame audit.  This pass adds every Inferno-only damage
source: enhanced burn, independently cooled combustion centers, Phoenix flyby,
Molten Armor counter-wave, and the one-generation four-piece death spread.

Scenario assumptions intentionally match the locked design matrix:
- Boss: three of five multishot lanes connect one large target.
- Dense: five lanes maintain five independent combustion centers; each burst
  reaches five ordered neighbors using the live radial falloff.
- Mixed: 60% Boss pressure plus 40% dense pressure.
- Dense free Plasma receives 0.55 extra splash-target equivalents per lane so
  the paid set is compared against its actual strongest free crowd advantage.
"""

from __future__ import annotations

import json
import runpy
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
COMMON = runpy.run_path(str(ROOT / "tools/audit_character_endgame_dps.py"), run_name="inferno_common")
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


def main() -> int:
    weapons = COMMON["WEAPONS"]
    characters = COMMON["CHARACTERS"]
    chips = COMMON["CHIPS"]
    pets = COMMON["PETS"]
    economy = COMMON["ECONOMY"]
    armors = load("armors.json")
    sets = load("premium_sets.json")

    free = COMMON["best_result"]("blaze")
    premium = COMMON["evaluate"](
        "blaze",
        "chip_apocalypse_stellar",
        "pet_apocalypse_phoenix",
        "weapon_apocalypse_inferno",
    )
    weapon = weapons["weapon_apocalypse_inferno"]
    chip = chips["chip_apocalypse_stellar"]
    phoenix = pets["pet_apocalypse_phoenix"]
    armor = armors["armor_apocalypse_molten"]
    set_row = sets["set_apocalypse_inferno"]
    special = weapon["special"]

    fire_rate = (
        float(weapon["fire_rate"])
        * (1.0 + 0.025 * (COMMON["WEAPON_LEVEL"] - 1))
        * float(economy["PLAYER_FIRE_RATE_MULT"])
        * float(characters["blaze"].get("fire_rate_mod", 1.0))
        * (1.0 + 0.01 * (COMMON["CHIP_LEVEL"] - 1))
        * (1.0 + COMMON["pet_stat"](phoenix, "fire_rate_mult"))
        * COMMON["FULL_SKILL_FIRE_RATE_MULT"]
    )
    hit_damage = premium.weapon_dps / max(
        fire_rate * COMMON["CONNECTED_LANES"], 0.001
    )

    burn_ratio = float(special["burn_ratio"])
    burn_ratio *= 1.0 + COMMON["chip_value"](chip, "burn_efficiency")
    burn_ratio *= 1.0 + float(set_row["two_piece"]["burn_efficiency"])
    burn_dps = hit_damage * burn_ratio

    combustion_efficiency = COMMON["chip_value"](
        chip, "combustion_stack_efficiency"
    ) + float(set_row["two_piece"]["combustion_stack_efficiency"])
    stack_cap = int(special["combustion_max_stacks"])
    trigger_stacks = max(
        3, round(stack_cap * (1.0 - min(combustion_efficiency, 0.42)))
    )
    combustion_unit = (
        hit_damage
        * float(special["combustion_damage_mult"])
        * (1.0 + COMMON["chip_value"](chip, "combustion_damage_mult"))
        / float(special["combustion_trigger_cooldown"])
    )

    free_pet = pets[free.pet_id]
    free_boss = free.total_dps + pet_skill_dps(free_pet, 1.0)
    free_dense = (
        free.all_lanes_dps
        + free.weapon_dps / COMMON["CONNECTED_LANES"] * 5.0 * 0.55
        + pet_skill_dps(free_pet, 3.2)
    )

    phoenix_target_count = int(phoenix["pet_skill"]["target_count"]) + int(
        (COMMON["PET_LEVEL"] - 1)
        / int(phoenix["pet_skill"]["extra_target_every"])
    )
    phoenix_falloff = float(phoenix["pet_skill"]["target_falloff"])
    phoenix_dense_equivalents = sum(
        phoenix_falloff**index for index in range(phoenix_target_count)
    )

    armor_boss = (
        hit_damage
        * float(armor["counter_damage_mult"])
        / float(armor["counter_cooldown"])
    )
    armor_dense_scales = sum(
        1.0
        + (0.54 - 1.0)
        * index
        / max(int(armor["counter_max_targets"]) - 1, 1)
        for index in range(int(armor["counter_max_targets"]))
    )
    armor_dense = armor_boss * armor_dense_scales

    burst_falloff = float(special["combustion_spread_falloff"])
    burst_equivalents = sum(
        1.0 + (burst_falloff - 1.0) * index / 4.0 for index in range(5)
    )
    spread = set_row["four_piece"]
    spread_equivalents = sum(
        float(spread["death_spread_falloff"]) ** index
        for index in range(int(spread["death_spread_max_targets"]))
    )
    # Normalized from the 20-second dense encounter fixture: only combustion
    # kills qualify, and the generation marker prevents child spread.
    dense_spread_dps = hit_damage * 0.12 * spread_equivalents * 0.55

    premium_boss = (
        premium.weapon_dps
        + burn_dps
        + premium.active_dps
        + premium.pet_dps
        + combustion_unit
        + pet_skill_dps(phoenix, 1.0)
        + armor_boss
    )
    premium_dense = (
        premium.all_lanes_dps
        - premium.status_dps
        + burn_dps
        + combustion_unit * 5.0 * burst_equivalents
        + pet_skill_dps(phoenix, phoenix_dense_equivalents)
        + armor_dense
        + dense_spread_dps
    )

    free_mixed = 0.60 * free_boss + 0.40 * free_dense
    premium_mixed = 0.60 * premium_boss + 0.40 * premium_dense
    ratios = {
        "boss": premium_boss / free_boss,
        "dense": premium_dense / free_dense,
        "mixed": premium_mixed / free_mixed,
    }
    weighted = 0.40 * ratios["boss"] + 0.40 * ratios["dense"] + 0.20 * ratios["mixed"]

    print("Inferno Apocalypse max-level DPS audit (all permanent/run skills maxed)")
    print(f"combustion trigger: {trigger_stacks}/{stack_cap} hits; no recursive spread")
    print(f"Boss:  free {free_boss:,.0f} -> inferno {premium_boss:,.0f} = {ratios['boss']:.3f}x")
    print(f"Dense: free {free_dense:,.0f} -> inferno {premium_dense:,.0f} = {ratios['dense']:.3f}x")
    print(f"Mixed: free {free_mixed:,.0f} -> inferno {premium_mixed:,.0f} = {ratios['mixed']:.3f}x")
    print(f"Weighted 40/40/20: {weighted:.3f}x (locked {set_row['target_full_set_ratio_min']:.2f}-{set_row['target_full_set_ratio_max']:.2f}x)")

    errors = []
    if not 1.35 <= ratios["boss"] <= 1.50:
        errors.append("Boss ratio outside 1.35-1.50x role band")
    if not 1.65 <= ratios["dense"] <= 1.80:
        errors.append("dense ratio outside 1.65-1.80x role band")
    if not 1.50 <= ratios["mixed"] <= 1.65:
        errors.append("mixed ratio outside 1.50-1.65x role band")
    if not float(set_row["target_full_set_ratio_min"]) <= weighted <= float(
        set_row["target_full_set_ratio_max"]
    ):
        errors.append("weighted ratio outside locked paid-set band")
    if int(spread["generation_limit"]) != 1:
        errors.append("four-piece spread must stay one generation")
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
