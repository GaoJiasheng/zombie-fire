#!/usr/bin/env python3
"""Guard the level-50+ campaign ramp and the level-99 build check.

This is intentionally a conservative throughput model. It does not try to
replay every projectile; it separates crowd HP from final-boss HP, applies the
runtime weakness/immunity rules, and verifies that several maxed physical
builds remain viable while a mismatched elemental primary cannot grind through
the finale on the generic boss damage floor.
"""
from __future__ import annotations

import json
import math
from pathlib import Path

import simulate_balance as balance
from combat_power_model import card_budget_power_factor


ROOT = Path(__file__).resolve().parents[1]
FINAL_LEVEL_ID = "level_099"
FINAL_BOSS_ID = "boss_apex_overlord"
MAXED_PHYSICAL_WEAPONS = (
    "weapon_autocannon",
    "weapon_railgun",
    "weapon_scattergun",
)


def load(name: str):
    return json.loads((ROOT / "data" / f"{name}.json").read_text(encoding="utf-8"))


def level_hp_split(level: dict, zombies: dict, bosses: dict, economy: dict) -> tuple[float, float]:
    level_no = balance.level_number(level)
    base_hp = float(level.get("base_hp_ref", 50.0))
    difficulty = float(level.get("difficulty_coef", 1.0))
    boss_level_mult = balance.boss_hp_level_bonus(economy, level)
    card_picks = int(level.get("target_card_picks", 4))
    mob_hp = 0.0
    boss_hp = 0.0
    for wave in level.get("waves", []):
        wave_no = balance.wave_number(wave)
        count_mult = balance.late_wave_count_mult(economy, wave_no)
        mob_mult = balance.late_wave_hp_bonus(economy, wave_no, level_no=level_no, card_picks=card_picks)
        for group in wave.get("spawns", []) + wave.get("support", []):
            row = zombies[group["type"]]
            count = int(round(int(group.get("count", 0)) * count_mult))
            mob_hp += base_hp * difficulty * float(row.get("hp_coef", 1.0)) * mob_mult * count
        if "boss" in wave:
            row = bosses[wave["boss"]]
            boss_hp += (
                base_hp
                * difficulty
                * float(row.get("hp_coef", 1.0))
                * balance.late_wave_hp_bonus(economy, wave_no, True, level_no, card_picks)
                * boss_level_mult
            )
    return mob_hp, boss_hp


def weapon_throughput(weapon: dict) -> tuple[float, float]:
    """Return crowd and single-target throughput beyond raw cadence/DPS."""
    special = weapon.get("special", {})
    crowd = 1.0 + 0.18 * float(special.get("pierce", 0))
    pellets = max(1, int(special.get("pellets", 1)))
    single = 1.0
    if pellets > 1:
        crowd *= 1.0 + float(pellets - 1) * 0.62
        # Large bosses catch several pellets, but never grant perfect five-pellet
        # throughput at spread range.
        single = min(float(pellets), 2.2)
    if float(special.get("splash", 0.0)) > 0.0 or float(special.get("cloud", 0.0)) > 0.0:
        crowd *= 1.28
    return crowd, single


def estimated_finale_seconds(
    level: dict,
    mob_hp: float,
    boss_hp: float,
    characters: dict,
    weapons: dict,
    bosses: dict,
    weapon_id: str,
    weapon_level: int,
) -> float:
    character = characters["vanguard"]
    weapon = weapons[weapon_id]
    char_level = int(character.get("max_level", 40))
    skill_mult = balance.estimate_skill_mult(level)
    raw_dps = balance.estimate_player_dps("vanguard", weapon_id, char_level, weapon_level, skill_mult)
    crowd_mult, single_mult = weapon_throughput(weapon)
    weapon_element = str(weapon.get("element", "physical"))
    boss_row = bosses[FINAL_BOSS_ID]

    if weapon_element == str(level.get("primary_weakness", "physical")):
        # Runtime applies 1.15 in the shot builder and 1.5 in enemy.take_damage.
        element_mult = 1.15 * 1.5
        mob_dps = raw_dps * element_mult * crowd_mult
        boss_dps = raw_dps * element_mult * single_mult
    else:
        # Remove the simulator's vanguard physical-pierce throughput from a
        # non-physical weapon, then apply the final boss's authored floor.
        raw_dps /= 1.18
        floor = float(boss_row.get("mechanic_params", {}).get("immune_damage_floor", 0.18))
        mob_dps = raw_dps * crowd_mult
        boss_dps = raw_dps * floor * single_mult

    return mob_hp / max(mob_dps, 1.0) + boss_hp / max(boss_dps, 1.0)


def recommended_power(level: dict, economy: dict) -> int:
    boss_bonus = 6 if any("boss" in wave for wave in level.get("waves", [])) else 0
    level_no = balance.level_number(level)
    ramp = balance.late_wave_level_ramp(economy, level_no)
    late_score = 0.0
    for wave in level.get("waves", []):
        wave_no = balance.wave_number(wave)
        if wave_no < 3:
            continue
        late_score += max(0.0, float(economy["late_wave_hp_bonus"].get(str(wave_no), 1.0)) * ramp - 1.0)
        late_score += max(0.0, balance.late_wave_count_mult(economy, wave_no) - 1.0) * 0.9
        if "boss" in wave:
            late_score += max(0.0, float(economy["late_wave_boss_hp_bonus"].get(str(wave_no), 1.0)) * ramp - 1.0) * 0.85
    late_bonus = round(late_score * 4.0)
    base = float(level.get("recommend_level", 1)) * 6.25 + boss_bonus + late_bonus
    total = base * card_budget_power_factor(int(level.get("target_card_picks", 4)), economy)
    return int(math.floor(total + 0.5))


def main() -> int:
    levels = load("levels")
    zombies = load("zombies")
    bosses = load("bosses")
    characters = load("characters")
    weapons = load("weapons")
    economy = load("economy")
    errors: list[str] = []

    by_id = {level["id"]: level for level in levels}
    finale = by_id[FINAL_LEVEL_ID]
    mob_hp, boss_hp = level_hp_split(finale, zombies, bosses, economy)

    checkpoints = (50, 60, 70, 80, 90, 97, 98, 99)
    hp_curve = [balance.late_wave_level_ramp(economy, level_no) for level_no in checkpoints]
    damage_curve = [balance.late_wave_damage_ramp(economy, level_no, 3) for level_no in checkpoints]
    if any(b <= a for a, b in zip(hp_curve, hp_curve[1:])):
        errors.append(f"level-50+ HP ramp must rise strictly: {hp_curve}")
    if any(b <= a for a, b in zip(damage_curve, damage_curve[1:])):
        errors.append(f"level-50+ damage ramp must rise strictly: {damage_curve}")
    pre_final_levels = range(50, 99)
    pre_final_hp = [balance.late_wave_level_ramp(economy, level_no) for level_no in pre_final_levels]
    pre_final_damage = [balance.late_wave_damage_ramp(economy, level_no, 3) for level_no in pre_final_levels]
    hp_steps = [b - a for a, b in zip(pre_final_hp, pre_final_hp[1:])]
    damage_steps = [b - a for a, b in zip(pre_final_damage, pre_final_damage[1:])]
    if max(hp_steps) - min(hp_steps) > 1e-6:
        errors.append("level-50..98 HP ramp must stay linear")
    if max(damage_steps) - min(damage_steps) > 1e-6:
        errors.append("level-50..98 damage ramp must stay linear")
    if abs(balance.late_wave_level_ramp(economy, 98) - 1.8) > 1e-6:
        errors.append("level-98 late-wave HP ramp must already reach 1.8x")
    if abs(balance.late_wave_damage_ramp(economy, 98, 3) - 2.0) > 1e-6:
        errors.append("level-98 late-wave damage ramp must already reach 2.0x")
    if abs(hp_curve[-1] - 2.16) > 1e-6:
        errors.append(f"level-99 late-wave HP ramp must reach 2.16x, got {hp_curve[-1]:.3f}")
    if abs(damage_curve[-1] - 2.30) > 1e-6:
        errors.append(f"level-99 late-wave damage ramp must reach 2.30x, got {damage_curve[-1]:.3f}")

    viable_fast: list[tuple[str, float]] = []
    viable_clear: list[tuple[str, float]] = []
    for weapon_id in MAXED_PHYSICAL_WEAPONS:
        weapon_level = int(weapons[weapon_id].get("max_level", 50))
        seconds = estimated_finale_seconds(finale, mob_hp, boss_hp, characters, weapons, bosses, weapon_id, weapon_level)
        if seconds <= 180.0:
            viable_fast.append((weapon_id, seconds))
        if seconds <= 260.0:
            viable_clear.append((weapon_id, seconds))
    if len(viable_fast) < 1:
        errors.append(f"finale must retain at least 1 maxed physical clear <=180s, got {viable_fast}")
    if len(viable_clear) < 3:
        errors.append(f"finale must retain all 3 maxed physical clears <=260s, got {viable_clear}")

    observed_like_seconds = estimated_finale_seconds(
        finale,
        mob_hp,
        boss_hp,
        characters,
        weapons,
        bosses,
        "weapon_plasmacannon",
        41,
    )
    if observed_like_seconds < 300.0:
        errors.append(
            "level-41 mismatched plasma build must not remain a comfortable finale clear: "
            f"estimated {observed_like_seconds:.1f}s"
        )

    final_recommended = recommended_power(finale, economy)
    if not 660 <= final_recommended <= 720:
        errors.append(f"final recommended power should sit in the skill-aware graduation band 660-720, got {final_recommended}")

    print("Endgame balance matrix")
    print("  HP ramp:     " + ", ".join(f"L{n}={v:.3f}x" for n, v in zip(checkpoints, hp_curve)))
    print("  damage ramp: " + ", ".join(f"L{n}={v:.3f}x" for n, v in zip(checkpoints, damage_curve)))
    print(f"  level_099 HP: mobs={mob_hp / 1_000_000:.2f}M boss={boss_hp / 1_000_000:.2f}M")
    for weapon_id, seconds in viable_clear:
        pace = "fast" if seconds <= 180.0 else "clear"
        print(f"  viable max build ({pace}): {weapon_id} estimated={seconds:.1f}s")
    print(f"  mismatched plasma L41 estimated={observed_like_seconds:.1f}s")
    print(f"  level_099 recommended power={final_recommended}")

    if errors:
        print("Endgame balance check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("Endgame balance check OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
