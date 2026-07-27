#!/usr/bin/env python3
"""Reproducible endgame DPS comparison for the four launch characters.

This is a deterministic design audit, not a frame-timing benchmark. It mirrors
the live battle formulas at max permanent levels and max compatible run skills,
then evaluates a neutral large Boss at 1000 px:

- the center three of five multishot lanes overlap the 130 px Boss collider;
- no weakness, resistance, armor, adds, breach damage or execute threshold;
- signature skills are used on cooldown;
- every chip/pet combination is evaluated and the highest single-target result
  is reported for the character's matching-element weapon.
"""

from __future__ import annotations

import json
import math
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
CHARACTER_LEVEL = 40
WEAPON_LEVEL = 50
CHIP_LEVEL = 35
PET_LEVEL = 30
SIGNATURE_LEVEL = 5
GROWTH_RANK = 3
CONNECTED_LANES = 3
TOTAL_LANES = 5
LANE_DAMAGE_MULT = 0.70
CRIT_DAMAGE_MULT = 2.40
FULL_SKILL_DAMAGE_MULT = 1.0 + 0.48 + 0.42 + 0.32 + 0.36
FULL_SKILL_FIRE_RATE_MULT = 2.20
FULL_RICOCHET_COUNT = 5
FULL_TESLA_CHAIN_COUNT = 4
FROST_TICK_INTERVAL = 0.56
TARGET_Y = 1000.0

MATCHING_WEAPON = {
    "vanguard": "weapon_railgun",
    "blaze": "weapon_plasmacannon",
    "frost": "weapon_cryocannon",
    "volt": "weapon_teslacoil",
}


def load(name: str) -> dict:
    return json.loads((DATA / name).read_text(encoding="utf-8"))


CHARACTERS = load("characters.json")
WEAPONS = load("weapons.json")
CHIPS = load("chips.json")
PETS = load("pets.json")
ECONOMY = load("economy.json")


@dataclass(frozen=True)
class DpsResult:
    character_id: str
    weapon_id: str
    chip_id: str
    pet_id: str
    weapon_dps: float
    status_dps: float
    active_dps: float
    pet_dps: float
    total_dps: float
    all_lanes_dps: float
    chain_count: int


def chip_value(chip: dict, stat: str) -> float:
    if chip.get("stat") != stat:
        return 0.0
    value = float(chip.get("value", 0.0))
    if stat == "pierce_bonus":
        return value + GROWTH_RANK
    growth = float(chip.get("level_value_growth", 0.035))
    return value * (1.0 + growth * (CHIP_LEVEL - 1))


def pet_stat(pet: dict, stat: str) -> float:
    base = float(pet.get("stat_bonus", {}).get(stat, 0.0))
    growth = float(pet.get("level_stat_growth", {}).get(stat, 0.0))
    return base + growth * (PET_LEVEL - 1)


def character_growth(character: dict, coefficient: float) -> float:
    return 1.0 + float(character["atk_growth"]) * coefficient * (CHARACTER_LEVEL - 1)


def active_power_scale(active: dict) -> float:
    return (
        1.0
        + float(active.get("level_damage_growth", 0.0)) * (CHARACTER_LEVEL - 1)
        + float(active.get("rank_damage_bonus", 0.0)) * GROWTH_RANK
        + float(active.get("sig_level_damage_bonus", 0.0)) * SIGNATURE_LEVEL
    )


def active_cooldown(active: dict) -> float:
    reduction = min(
        float(active.get("sig_level_cooldown_reduction", 0.0)) * SIGNATURE_LEVEL,
        0.35,
    )
    return max(4.0, float(active.get("cooldown", 16.0)) * (1.0 - reduction))


def blaze_pulse_factor(active: dict) -> float:
    base_radius = float(active.get("radius", 260.0))
    radius = (
        base_radius
        * (
            1.0
            + float(active.get("level_radius_growth", 0.0)) * (CHARACTER_LEVEL - 1)
            + float(active.get("sig_level_radius_bonus", 0.0)) * SIGNATURE_LEVEL
        )
        + float(active.get("rank_radius_bonus", 0.0)) * GROWTH_RANK
    )
    thresholds = active.get("sig_level_extra_pulse_levels", [])
    pulse_count = min(
        int(active.get("base_pulses", 4))
        + int(active.get("rank_extra_pulses", 0)) * GROWTH_RANK
        + sum(SIGNATURE_LEVEL >= int(level) for level in thresholds),
        9,
    )
    weights = [0.18, 0.22, 0.26, 0.30, 0.24, 0.20, 0.16]
    total = 0.0
    for index in range(pulse_count):
        if index == 0:
            dx, dy = 0.0, 0.0
        elif index == 1:
            dx, dy = -radius * 0.24, -70.0
        elif index == 2:
            dx, dy = radius * 0.26, 24.0
        elif index == 3:
            dx, dy = 0.0, -128.0
        else:
            angle = math.tau * float(index - 4) / 3.0 + 0.35
            dx = math.cos(angle) * radius * 0.34
            dy = math.sin(angle) * radius * 0.34 - 62.0
        local_radius = radius * (0.48 + 0.12 * index)
        distance = math.hypot(dx, dy)
        if distance > local_radius:
            continue
        falloff = 1.0 - min(distance / local_radius, 1.0)
        total += weights[min(index, len(weights) - 1)] * (0.58 + falloff * 0.42)
    return total


def frost_active_hit_factor(active: dict) -> float:
    thresholds = active.get("sig_level_extra_wave_levels", [])
    wave_count = min(
        int(active.get("base_waves", 4))
        + int(active.get("rank_extra_waves", 0)) * GROWTH_RANK
        + sum(SIGNATURE_LEVEL >= int(level) for level in thresholds),
        9,
    )
    wave_factor = 0.0
    for index in range(wave_count):
        wave_y = 1220.0 + (120.0 - 1220.0) * index / max(wave_count - 1, 1)
        radius = 390.0 + index * 48.0
        if abs(TARGET_Y - wave_y) <= radius:
            wave_factor += 0.90 + index * 0.08
    duration = (
        float(active.get("duration", 5.0))
        + float(active.get("rank_duration_bonus", 0.0)) * GROWTH_RANK
        + float(active.get("sig_level_duration_bonus", 0.0)) * SIGNATURE_LEVEL
    )
    return wave_factor + math.ceil(duration / FROST_TICK_INTERVAL)


def evaluate(character_id: str, chip_id: str, pet_id: str) -> DpsResult:
    character = CHARACTERS[character_id]
    weapon_id = MATCHING_WEAPON[character_id]
    weapon = WEAPONS[weapon_id]
    chip = CHIPS[chip_id]
    pet = PETS[pet_id]
    active = character["active_skill"]
    affinity = character["bullet_affinity"]
    element = str(weapon["element"])

    weapon_damage_mult = 1.0 + 0.08 * (WEAPON_LEVEL - 1)
    weapon_fire_rate_mult = 1.0 + 0.025 * (WEAPON_LEVEL - 1)
    attack_mult = (
        float(character["base_atk"])
        / 100.0
        * character_growth(character, 0.45)
        * (1.0 + chip_value(chip, "damage_mult"))
        * (1.0 + pet_stat(pet, "damage_mult"))
    )
    if element != "physical":
        attack_mult *= 1.0 + chip_value(chip, "element_damage_mult")
    if element != "physical" or str(pet.get("element", "")) == element:
        attack_mult *= 1.0 + pet_stat(pet, "element_damage_mult")
    turret_damage_mult = weapon_damage_mult * attack_mult

    fire_rate = (
        float(weapon["fire_rate"])
        * weapon_fire_rate_mult
        * float(ECONOMY["PLAYER_FIRE_RATE_MULT"])
        * float(character.get("fire_rate_mod", 1.0))
        * (1.0 + chip_value(chip, "fire_rate_mult"))
        * (1.0 + 0.01 * (CHIP_LEVEL - 1))
        * (1.0 + pet_stat(pet, "fire_rate_mult"))
        * FULL_SKILL_FIRE_RATE_MULT
    )
    crit_rate = (
        float(character.get("crit_rate_base", 0.0))
        + chip_value(chip, "crit_rate")
        + pet_stat(pet, "crit_rate")
        + 0.24
    )
    crit_expectation = 1.0 + crit_rate * (CRIT_DAMAGE_MULT - 1.0)
    affinity_mult = (
        1.0
        + float(affinity.get("damage_bonus", 0.0))
        + float(affinity.get("rank_damage_bonus", 0.0)) * GROWTH_RANK
    )

    pet_chain = round(pet_stat(pet, "chain_bonus"))
    chain_count = FULL_RICOCHET_COUNT + int(weapon.get("special", {}).get("chain", 0))
    if element == "lightning":
        chain_count += FULL_TESLA_CHAIN_COUNT
    chain_count += pet_chain
    if str(affinity.get("element", "")) == element:
        chain_count += int(affinity.get("chain_bonus", 0))
        if GROWTH_RANK >= 2:
            chain_count += int(affinity.get("rank_chain_bonus", 0))
    overflow_mult = 1.0
    if str(affinity.get("element", "")) == element:
        reference = int(affinity.get("chain_overflow_reference", 999))
        overflow_mult += max(chain_count - reference, 0) * float(
            affinity.get("chain_overflow_damage_bonus", 0.0)
        )

    primary_damage = (
        28.0
        * float(weapon["base_atk_coef"])
        * float(ECONOMY["PLAYER_SHOT_DAMAGE_MULT"])
        * turret_damage_mult
        * FULL_SKILL_DAMAGE_MULT
        * affinity_mult
        * overflow_mult
    )
    connected_lane_mult = CONNECTED_LANES * LANE_DAMAGE_MULT
    all_lane_mult = TOTAL_LANES * LANE_DAMAGE_MULT
    weapon_dps = primary_damage * fire_rate * connected_lane_mult * crit_expectation
    all_lanes_weapon_dps = primary_damage * fire_rate * all_lane_mult * crit_expectation

    if character_id == "frost":
        shatter_mult = 1.0 + float(affinity.get("shatter_bonus", 0.0)) + 0.04 * GROWTH_RANK
        weapon_dps *= shatter_mult
        all_lanes_weapon_dps *= shatter_mult

    # The new burn refresh is a convergent filter. Under a sustained mixed
    # crit stream its mean settles between the base 55% burn and Blaze's 77%
    # amplified burn, instead of latching the historical maximum forever.
    status_dps = primary_damage * crit_expectation * 0.66 if character_id == "blaze" else 0.0

    pet_shot_damage = float(pet.get("damage", 0.0)) * (
        1.0 + float(pet.get("level_damage_growth", 0.0)) * (PET_LEVEL - 1)
    )
    pet_dps = pet_shot_damage * float(pet.get("fire_rate", 0.0))
    if character_id != "blaze" and str(pet.get("element", "")) == "fire":
        pet_dps += pet_shot_damage * 0.22

    if str(active.get("scaling_basis", "weapon")) == "weapon":
        active_base_damage = primary_damage / overflow_mult
    else:
        active_base_damage = (
            28.0
            * float(ECONOMY["PLAYER_SHOT_DAMAGE_MULT"])
            * float(character["base_atk"])
            / 100.0
            * character_growth(character, 0.52)
        )
        inherit = float(active.get("weapon_level_inherit", 0.0))
        active_base_damage *= 1.0 + inherit * (weapon_damage_mult - 1.0)
        active_base_damage *= 1.0 + chip_value(chip, "damage_mult")
        if element != "physical":
            active_base_damage *= 1.0 + chip_value(chip, "element_damage_mult")
        active_base_damage *= FULL_SKILL_DAMAGE_MULT * affinity_mult

    active_hit_damage = (
        active_base_damage
        * float(active.get("damage_mult", 1.0))
        * active_power_scale(active)
    )
    cooldown = active_cooldown(active)
    active_dps = 0.0
    if character_id == "vanguard":
        rank_volleys = int(active.get("rank_extra_volleys", 0)) * GROWTH_RANK
        volley_count = (
            int(active.get("base_volleys", 5))
            + min(rank_volleys, int(active.get("max_extra_volleys", rank_volleys)))
            + SIGNATURE_LEVEL // int(active.get("sig_level_extra_volley_every", 999))
        )
        active_dps = volley_count * active_hit_damage * 1.06 / cooldown
        duration = (
            float(active.get("duration", 6.0))
            + float(active.get("rank_duration_bonus", 0.0)) * GROWTH_RANK
            + float(active.get("sig_level_duration_bonus", 0.0)) * SIGNATURE_LEVEL
        )
        barrage_rate_bonus = (
            float(active.get("barrage_fire_rate_mult", 1.0))
            + float(active.get("rank_fire_rate_bonus", 0.0)) * GROWTH_RANK
            - 1.0
        )
        active_dps += weapon_dps * barrage_rate_bonus * min(duration / cooldown, 1.0)
    elif character_id == "blaze":
        active_dps = active_hit_damage * blaze_pulse_factor(active) / cooldown
    elif character_id == "frost":
        active_dps = active_hit_damage * frost_active_hit_factor(active) / cooldown
    elif character_id == "volt":
        targets = (
            int(active.get("max_targets", 6))
            + int(active.get("rank_target_bonus", 0)) * GROWTH_RANK
            + SIGNATURE_LEVEL // int(active.get("sig_level_extra_target_every", 999))
        )
        strikes = (
            targets
            + 2
            + int(active.get("rank_extra_strikes", 0)) * GROWTH_RANK
            + SIGNATURE_LEVEL // int(active.get("sig_level_extra_strike_every", 999))
        )
        active_dps = active_hit_damage * 0.62 * strikes / cooldown

    total_dps = weapon_dps + status_dps + active_dps + pet_dps
    all_lanes_dps = (
        all_lanes_weapon_dps + status_dps + active_dps + pet_dps
    )
    return DpsResult(
        character_id,
        weapon_id,
        chip_id,
        pet_id,
        weapon_dps,
        status_dps,
        active_dps,
        pet_dps,
        total_dps,
        all_lanes_dps,
        chain_count,
    )


def best_result(character_id: str) -> DpsResult:
    candidates = [
        evaluate(character_id, chip_id, pet_id)
        for chip_id in CHIPS
        for pet_id in PETS
    ]
    return max(candidates, key=lambda result: result.total_dps)


def main() -> int:
    results = [best_result(character_id) for character_id in MATCHING_WEAPON]
    print(
        "Endgame single-Boss DPS audit "
        f"(Lv{CHARACTER_LEVEL}/W{WEAPON_LEVEL}/A35/C{CHIP_LEVEL}/P{PET_LEVEL}/Sig{SIGNATURE_LEVEL}, "
        f"{CONNECTED_LANES}/{TOTAL_LANES} multishot lanes connect)"
    )
    print(
        f"{'character':10} {'weapon':21} {'chip':14} {'pet':18} "
        f"{'weapon':>10} {'status':>9} {'active':>9} {'pet':>7} {'total':>10} {'5 lanes':>10} {'chain':>6}"
    )
    for result in results:
        print(
            f"{result.character_id:10} {result.weapon_id:21} {result.chip_id:14} {result.pet_id:18} "
            f"{result.weapon_dps:10.0f} {result.status_dps:9.0f} {result.active_dps:9.0f} "
            f"{result.pet_dps:7.0f} {result.total_dps:10.0f} {result.all_lanes_dps:10.0f} "
            f"{result.chain_count:6d}"
        )
    totals = [result.total_dps for result in results]
    spread = max(totals) / min(totals)
    print(f"single-Boss max/min spread: {spread:.3f}x ({(spread - 1.0) * 100.0:.1f}%)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
