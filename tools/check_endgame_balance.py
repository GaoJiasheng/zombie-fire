#!/usr/bin/env python3
"""Guard the level-50+ campaign ramp and the level-99 build check.

The three physical finale builds use a checked-in Godot runtime benchmark
produced by ``res://tools/audit_physical_endgame_runtime.gd``. Scatter pellets,
five-lane multishot, pierce sweeps, split children, ricochet, homing, crit,
Vanguard's active/barrage uptime, chips and pets are therefore based on real
projectile collisions rather than heuristic throughput multipliers.
"""
from __future__ import annotations

import json
import math
from pathlib import Path

import simulate_balance as balance
import audit_character_endgame_dps as character_dps
from combat_power_model import card_budget_power_factor


ROOT = Path(__file__).resolve().parents[1]
FINAL_LEVEL_ID = "level_099"
FINAL_BOSS_ID = "boss_apex_overlord"
MAXED_PHYSICAL_WEAPONS = (
    "weapon_autocannon",
    "weapon_railgun",
    "weapon_scattergun",
)
RUNTIME_BENCHMARK_PATH = ROOT / "tools" / "physical_endgame_runtime_benchmark.json"


def load(name: str):
    return json.loads((ROOT / "data" / f"{name}.json").read_text(encoding="utf-8"))


def load_runtime_benchmark() -> dict:
    return json.loads(RUNTIME_BENCHMARK_PATH.read_text(encoding="utf-8"))


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
        count_mult = balance.late_wave_count_mult(economy, wave_no, level_no)
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
                * balance.boss_survival_hp_ramp(economy, level_no)
            )
    return mob_hp, boss_hp


def runtime_finale_seconds(
    mob_hp: float,
    boss_hp: float,
    weapon_id: str,
    runtime_builds: dict,
) -> float:
    build = runtime_builds[weapon_id]
    crowd_dps = float(build["crowd_dps"])
    boss_dps = float(build["boss_dps"])
    # Apex takes full damage above 67%, then 0.90x and 0.82x in phases 2/3.
    phase_time_weight = 0.33 + 0.33 / 0.90 + 0.34 / 0.82
    return mob_hp / max(crowd_dps, 1.0) + boss_hp / max(boss_dps, 1.0) * phase_time_weight


def estimated_mismatched_finale_seconds(
    level: dict,
    mob_hp: float,
    boss_hp: float,
    characters: dict,
    weapons: dict,
    bosses: dict,
    weapon_id: str,
    weapon_level: int,
    modern_dps_scale: float,
) -> float:
    """Conservative legacy estimate for an intentionally invalid element build."""
    character = characters["vanguard"]
    weapon = weapons[weapon_id]
    skill_mult = balance.estimate_skill_mult(level)
    raw_dps = balance.estimate_player_dps(
        "vanguard",
        weapon_id,
        int(character.get("max_level", 40)),
        weapon_level,
        skill_mult,
    ) * modern_dps_scale
    raw_dps /= 1.18
    floor = float(bosses[FINAL_BOSS_ID].get("mechanic_params", {}).get("immune_damage_floor", 0.18))
    special = weapon.get("special", {})
    pellets = max(1, int(special.get("pellets", 1)))
    crowd_mult = 1.0 + 0.18 * float(special.get("pierce", 0))
    if pellets > 1:
        crowd_mult *= 1.0 + float(pellets - 1) * 0.62
    return mob_hp / max(raw_dps * crowd_mult, 1.0) + boss_hp / max(raw_dps * floor, 1.0)


def recommended_power(level: dict, economy: dict) -> int:
    boss_bonus = 6 if any("boss" in wave for wave in level.get("waves", [])) else 0
    level_no = balance.level_number(level)
    ramp = balance.late_wave_level_ramp(economy, level_no)
    boss_survival = balance.boss_survival_hp_ramp(economy, level_no)
    late_score = 0.0
    for wave in level.get("waves", []):
        wave_no = balance.wave_number(wave)
        if wave_no < 3:
            continue
        late_score += max(0.0, float(economy["late_wave_hp_bonus"].get(str(wave_no), 1.0)) * ramp - 1.0)
        late_score += max(0.0, balance.late_wave_count_mult(economy, wave_no, level_no) - 1.0) * 0.9
        if "boss" in wave:
            late_score += max(0.0, float(economy["late_wave_boss_hp_bonus"].get(str(wave_no), 1.0)) * ramp - 1.0) * 0.85
            late_score += math.log2(max(1.0, boss_survival)) * 1.2
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
    runtime_benchmark = load_runtime_benchmark()
    runtime_builds = runtime_benchmark["best_same_loadout"]
    errors: list[str] = []

    by_id = {level["id"]: level for level in levels}
    finale = by_id[FINAL_LEVEL_ID]
    mob_hp, boss_hp = level_hp_split(finale, zombies, bosses, economy)

    checkpoints = (50, 60, 70, 80, 90, 97, 98, 99)
    hp_curve = [balance.late_wave_level_ramp(economy, level_no) for level_no in checkpoints]
    damage_curve = [balance.late_wave_damage_ramp(economy, level_no, 3) for level_no in checkpoints]
    count_curve = [balance.late_wave_count_level_ramp(economy, level_no, 3) for level_no in checkpoints]
    boss_curve = [balance.boss_survival_hp_ramp(economy, level_no) for level_no in checkpoints]
    if any(b <= a for a, b in zip(hp_curve, hp_curve[1:])):
        errors.append(f"level-50+ HP ramp must rise strictly: {hp_curve}")
    if any(abs(value - 1.0) > 1e-6 for value in damage_curve):
        errors.append(f"late-game attack ramp must stay disabled at 1.0x: {damage_curve}")
    if any(b < a for a, b in zip(count_curve, count_curve[1:])):
        errors.append(f"level-50+ crowd count ramp must not regress: {count_curve}")
    if any(b < a for a, b in zip(boss_curve, boss_curve[1:])):
        errors.append(f"level-50+ boss survival ramp must not regress: {boss_curve}")
    pre_final_levels = range(50, 99)
    pre_final_hp = [balance.late_wave_level_ramp(economy, level_no) for level_no in pre_final_levels]
    hp_steps = [b - a for a, b in zip(pre_final_hp, pre_final_hp[1:])]
    if max(hp_steps) - min(hp_steps) > 1e-6:
        errors.append("level-50..98 HP ramp must stay linear")
    if abs(balance.late_wave_level_ramp(economy, 98) - 2.05) > 1e-6:
        errors.append("level-98 late-wave HP ramp must already reach 2.05x")
    if abs(hp_curve[-1] - 2.296) > 1e-6:
        errors.append(f"level-99 late-wave HP ramp must reach 2.296x, got {hp_curve[-1]:.3f}")
    if abs(count_curve[-1] - 1.35) > 1e-6:
        errors.append(f"level-99 crowd count ramp must reach 1.35x, got {count_curve[-1]:.3f}")
    if abs(balance.boss_survival_hp_ramp(economy, 98) - 56.0) > 1e-6:
        errors.append("level-98 boss survival ramp must reach 56.0x")
    if abs(boss_curve[-1] - 60.48) > 1e-6:
        errors.append(f"level-99 boss survival ramp must reach 60.48x, got {boss_curve[-1]:.3f}")
    required_skills = {
        "skill_split_shot",
        "skill_pierce",
        "skill_multishot",
        "skill_homing",
        "skill_critical",
        "skill_ricochet",
        "skill_salvo",
        "skill_charge_shot",
    }
    if set(runtime_benchmark.get("skills", [])) != required_skills:
        errors.append("runtime benchmark must include every max physical offensive skill")
    if set(runtime_builds) != set(MAXED_PHYSICAL_WEAPONS):
        errors.append("runtime benchmark must cover all three maxed physical weapons")

    modern_reference_dps = character_dps.best_result("vanguard").total_dps
    legacy_reference_dps = balance.estimate_player_dps(
        "vanguard",
        "weapon_railgun",
        int(characters["vanguard"].get("max_level", 40)),
        int(weapons["weapon_railgun"].get("max_level", 50)),
        balance.estimate_skill_mult(finale),
    )
    modern_dps_scale = modern_reference_dps / max(legacy_reference_dps, 1.0)

    boss_windows: list[tuple[int, float, float, int]] = []
    apex = bosses[FINAL_BOSS_ID]
    apex_speed = (
        float(apex.get("speed", 22.5))
        * float(economy.get("ENEMY_SPEED_MULT", 1.0))
        * float(economy.get("BOSS_SPEED_MULT", 1.0))
        * 1.15
    )
    first_skill_seconds = (560.0 - 190.0) / max(apex_speed, 1.0)
    # The scattergun is the fastest measured single-Boss physical counter.
    # Guard against that strongest legal build, not the old raw-DPS proxy.
    counter_dps = max(float(row["boss_dps"]) for row in runtime_builds.values())
    # Apex takes full damage above 67%, then 0.90x and 0.82x in phases 2/3.
    phase_time_weight = 0.33 + 0.33 / 0.90 + 0.34 / 0.82
    for level_no in (90, 95, 99):
        level = by_id[f"level_{level_no:03d}"]
        _, checkpoint_boss_hp = level_hp_split(level, zombies, bosses, economy)
        ttk = checkpoint_boss_hp / max(counter_dps, 1.0) * phase_time_weight
        casts = max(0, 1 + int((ttk - first_skill_seconds) // 4.8)) if ttk >= first_skill_seconds else 0
        boss_windows.append((level_no, checkpoint_boss_hp, ttk, casts))
    if boss_windows[0][2] < 50.0 or boss_windows[0][3] < 8:
        errors.append(f"level-90 Apex must survive for at least 50s / 8 skill windows: {boss_windows[0]}")
    if boss_windows[-1][2] < 105.0 or boss_windows[-1][3] < 18:
        errors.append(f"level-99 Apex must survive for at least 105s / 18 skill windows: {boss_windows[-1]}")
    if boss_windows[-1][2] > 125.0:
        errors.append(f"level-99 fastest counter-build TTK must stay below 125s: {boss_windows[-1][2]:.1f}s")

    viable_fast: list[tuple[str, float]] = []
    viable_clear: list[tuple[str, float]] = []
    for weapon_id in MAXED_PHYSICAL_WEAPONS:
        seconds = runtime_finale_seconds(mob_hp, boss_hp, weapon_id, runtime_builds)
        if seconds <= 180.0:
            viable_fast.append((weapon_id, seconds))
        if seconds <= 260.0:
            viable_clear.append((weapon_id, seconds))
    if len(viable_fast) < 1:
        errors.append(f"finale must retain at least 1 maxed physical clear <=180s, got {viable_fast}")
    if len(viable_clear) < 3:
        errors.append(f"finale must retain all 3 maxed physical clears <=260s, got {viable_clear}")

    observed_like_seconds = estimated_mismatched_finale_seconds(
        finale,
        mob_hp,
        boss_hp,
        characters,
        weapons,
        bosses,
        "weapon_plasmacannon",
        41,
        modern_dps_scale,
    )
    if observed_like_seconds < 300.0:
        errors.append(
            "level-41 mismatched plasma build must not remain a comfortable finale clear: "
            f"estimated {observed_like_seconds:.1f}s"
        )

    final_recommended = recommended_power(finale, economy)
    if not 700 <= final_recommended <= 780:
        errors.append(f"final recommended power should sit in the endurance-aware graduation band 700-780, got {final_recommended}")

    print("Endgame balance matrix")
    print("  HP ramp:     " + ", ".join(f"L{n}={v:.3f}x" for n, v in zip(checkpoints, hp_curve)))
    print("  damage ramp: " + ", ".join(f"L{n}={v:.3f}x" for n, v in zip(checkpoints, damage_curve)))
    print("  count ramp:  " + ", ".join(f"L{n}={v:.3f}x" for n, v in zip(checkpoints, count_curve)))
    print("  boss HP:     " + ", ".join(f"L{n}={v:.3f}x" for n, v in zip(checkpoints, boss_curve)))
    print(f"  level_099 HP: mobs={mob_hp / 1_000_000:.2f}M boss={boss_hp / 1_000_000:.2f}M")
    print(f"  modern DPS calibration: {modern_dps_scale:.3f}x (vanguard rail={modern_reference_dps:.0f})")
    print("  physical throughput: Godot runtime benchmark (all 8 max offensive skills)")
    for level_no, checkpoint_boss_hp, ttk, casts in boss_windows:
        print(f"  Apex L{level_no}: hp={checkpoint_boss_hp / 1_000_000:.2f}M counter-TTK={ttk:.1f}s skill-windows={casts}")
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
