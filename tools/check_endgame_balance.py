#!/usr/bin/env python3
"""Guard the level-50+ ramp plus both finale Boss audit scopes.

The Apex single-phase matrix preserves the design/25 116.6-second contract.
The complete level-99 matrix reads the authored primary/runtime Boss roster and
the generated power contract's mechanic-adjusted effective HP.

All three physical finale builds use a checked-in Godot runtime benchmark
produced by ``res://tools/audit_physical_endgame_runtime.gd``. Scatter pellets,
five-lane multishot, pierce sweeps, split children, ricochet, homing, crit,
Vanguard's active/barrage uptime, chips and pets are therefore based on real
projectile collisions rather than heuristic throughput multipliers.
"""
from __future__ import annotations

import json
from pathlib import Path

import simulate_balance as balance
import audit_character_endgame_dps as character_dps
import power_ruler_model as power_ruler


ROOT = Path(__file__).resolve().parents[1]
FINAL_LEVEL_ID = "level_099"
FINAL_BOSS_ID = "boss_apex_overlord"
MAXED_PHYSICAL_WEAPONS = (
    "weapon_autocannon",
    "weapon_railgun",
    "weapon_scattergun",
)
RUNTIME_BENCHMARK_PATH = ROOT / "tools" / "physical_endgame_runtime_benchmark.json"
DOUBLE_BOSS_FASTEST_MIN_SECONDS = 150.0
DOUBLE_BOSS_FASTEST_MAX_SECONDS = 185.0
FINALE_PHASE_CAP_SECONDS = 460.0


def load(name: str):
    return json.loads((ROOT / "data" / f"{name}.json").read_text(encoding="utf-8"))


def load_runtime_benchmark() -> dict:
    return json.loads(RUNTIME_BENCHMARK_PATH.read_text(encoding="utf-8"))


def level_hp_split(level: dict, zombies: dict, bosses: dict, economy: dict) -> tuple[float, float]:
    mob_hp, boss_hp, _ = balance.level_enemy_hp_split(level, zombies, bosses, economy)
    return mob_hp, boss_hp


def runtime_finale_seconds(
    mob_hp: float,
    boss_effective_hp: float,
    weapon_id: str,
    runtime_builds: dict,
) -> float:
    build = runtime_builds[weapon_id]
    crowd_dps = float(build["crowd_dps"])
    boss_dps = float(build["boss_dps"])
    return mob_hp / max(crowd_dps, 1.0) + boss_effective_hp / max(boss_dps, 1.0)


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


def main() -> int:
    levels = load("levels")
    zombies = load("zombies")
    bosses = load("bosses")
    characters = load("characters")
    weapons = load("weapons")
    skills = load("skills")
    economy = load("economy")
    runtime_benchmark = load_runtime_benchmark()
    runtime_builds = runtime_benchmark["best_same_loadout"]
    errors: list[str] = []

    by_id = {level["id"]: level for level in levels}
    finale = by_id[FINAL_LEVEL_ID]
    mob_hp, boss_hp = level_hp_split(finale, zombies, bosses, economy)
    boss_effective_hp = float(
        finale.get("clear_requirement", {}).get("power_contract", {}).get("boss_effective_hp", boss_hp))

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
        _, checkpoint_bosses, _ = balance.level_enemy_hp_profile(level, zombies, bosses, economy)
        checkpoint_boss_hp = float(checkpoint_bosses.get(FINAL_BOSS_ID, 0.0))
        ttk = checkpoint_boss_hp / max(counter_dps, 1.0) * phase_time_weight
        casts = max(0, 1 + int((ttk - first_skill_seconds) // 4.8)) if ttk >= first_skill_seconds else 0
        boss_windows.append((level_no, checkpoint_boss_hp, ttk, casts))
    if boss_windows[0][2] < 50.0 or boss_windows[0][3] < 8:
        errors.append(f"level-90 Apex must survive for at least 50s / 8 skill windows: {boss_windows[0]}")
    if boss_windows[-1][2] < 105.0 or boss_windows[-1][3] < 18:
        errors.append(f"level-99 Apex must survive for at least 105s / 18 skill windows: {boss_windows[-1]}")
    if boss_windows[-1][2] > 125.0:
        errors.append(f"level-99 fastest counter-build TTK must stay below 125s: {boss_windows[-1][2]:.1f}s")

    # Complete runtime encounter: primary Apex + every levels.json runtime Boss,
    # using the power contract's mechanic-adjusted combined effective HP.
    primary_boss_ids = {
        str(wave["boss"]) for wave in finale.get("waves", []) if "boss" in wave
    }
    runtime_boss_ids = {
        str(row.get("type", "")) for row in finale.get("runtime_bosses", [])
        if str(row.get("type", ""))
    }
    authored_boss_ids = primary_boss_ids | runtime_boss_ids
    contract_boss_ids = set(
        finale.get("clear_requirement", {}).get("power_contract", {}).get("boss_weights", {}))
    if not runtime_boss_ids:
        errors.append("level_099 must author at least one runtime Boss for the full-encounter audit")
    if authored_boss_ids != contract_boss_ids:
        errors.append(
            f"level_099 authored Bosses {sorted(authored_boss_ids)} must match "
            f"power-contract weights {sorted(contract_boss_ids)}")

    double_boss_rows: list[tuple[str, float, bool]] = []
    for weapon_id in MAXED_PHYSICAL_WEAPONS:
        seconds = runtime_finale_seconds(mob_hp, boss_effective_hp, weapon_id, runtime_builds)
        double_boss_rows.append((weapon_id, seconds, seconds <= FINALE_PHASE_CAP_SECONDS))
    fastest_weapon, fastest_seconds, _ = min(double_boss_rows, key=lambda row: row[1])
    if fastest_weapon != "weapon_scattergun":
        errors.append(
            f"graduation family must remain scattergun, got fastest={fastest_weapon}")
    if not DOUBLE_BOSS_FASTEST_MIN_SECONDS <= fastest_seconds <= DOUBLE_BOSS_FASTEST_MAX_SECONDS:
        errors.append(
            "strongest free max build must clear the complete double-Boss encounter "
            f"inside [{DOUBLE_BOSS_FASTEST_MIN_SECONDS:.0f},{DOUBLE_BOSS_FASTEST_MAX_SECONDS:.0f}]s, "
            f"got {fastest_weapon}={fastest_seconds:.1f}s")

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

    final_recommended = int(
        finale.get("clear_requirement", {}).get("power_contract", {}).get("recommended_power", 0))
    if not 2330 <= final_recommended <= 2350:
        errors.append(
            "final fixed recommendation must stay on the regenerated v3 corridor scale "
            f"near 2340, got {final_recommended}")
    contract_reference_seconds = balance.runtime_boss_contract_clear_time(
        finale, mob_hp, 1.0, economy)
    if contract_reference_seconds is None or not 350.0 <= contract_reference_seconds <= 380.0:
        errors.append(
            "level-99 equal-recommendation display contract should remain within the authored "
            f"460s phase cap, expected [350,380]s after corridor calibration, got {contract_reference_seconds}"
        )

    print("Endgame balance matrix")
    print("  HP ramp:     " + ", ".join(f"L{n}={v:.3f}x" for n, v in zip(checkpoints, hp_curve)))
    print("  damage ramp: " + ", ".join(f"L{n}={v:.3f}x" for n, v in zip(checkpoints, damage_curve)))
    print("  count ramp:  " + ", ".join(f"L{n}={v:.3f}x" for n, v in zip(checkpoints, count_curve)))
    print("  boss HP:     " + ", ".join(f"L{n}={v:.3f}x" for n, v in zip(checkpoints, boss_curve)))
    _, finale_bosses, _ = balance.level_enemy_hp_profile(finale, zombies, bosses, economy)
    boss_detail = ", ".join(f"{boss_id}={hp / 1_000_000:.2f}M" for boss_id, hp in finale_bosses.items())
    print(f"  level_099 HP: mobs={mob_hp / 1_000_000:.2f}M bosses={boss_hp / 1_000_000:.2f}M ({boss_detail})")
    print(f"  modern DPS calibration: {modern_dps_scale:.3f}x (vanguard rail={modern_reference_dps:.0f})")
    print("  physical throughput: Godot runtime benchmark (all 8 max offensive skills)")
    print("  Apex single-phase audit (design/25 116.6s contract)")
    for level_no, checkpoint_boss_hp, ttk, casts in boss_windows:
        print(f"    Apex L{level_no}: hp={checkpoint_boss_hp / 1_000_000:.2f}M counter-TTK={ttk:.1f}s skill-windows={casts}")
    print(
        "  Double-Boss full-encounter audit "
        f"(authored={','.join(sorted(authored_boss_ids))}; "
        f"effective={boss_effective_hp / 1_000_000:.2f}M; cap={FINALE_PHASE_CAP_SECONDS:.0f}s)")
    for weapon_id, seconds, within_cap in double_boss_rows:
        status = "within cap" if within_cap else "over cap"
        graduation = "; graduation family" if weapon_id == "weapon_scattergun" else ""
        print(f"    {weapon_id}: {seconds:.1f}s ({status}{graduation})")
    autocannon_seconds = next(row[1] for row in double_boss_rows if row[0] == "weapon_autocannon")
    if autocannon_seconds > FINALE_PHASE_CAP_SECONDS:
        print("    decision: autocannon exceeds cap; graduation build = scattergun family")
    else:
        print("    decision: graduation build = scattergun family; autocannon remains inside cap")
    print(f"  mismatched plasma L41 estimated={observed_like_seconds:.1f}s")
    print(f"  level_099 recommended power={final_recommended}")
    contract_seconds_text = (
        f"{contract_reference_seconds:.1f}s"
        if contract_reference_seconds is not None else "missing"
    )
    print(f"  level_099 equal-recommendation contract={contract_seconds_text}")

    if errors:
        print("Endgame balance check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("Endgame balance check OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
