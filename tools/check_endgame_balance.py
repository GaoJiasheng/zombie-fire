#!/usr/bin/env python3
"""Guard the level-50+ crowd ramp plus fixed-identity Boss pacing.

Every Boss model owns one stable total durability in bosses.json. Campaign
pressure rises through explicit reinforcement rows, not hidden per-stage Boss
HP multipliers. The complete level-99 matrix reads that authored roster and the
generated power contract's mechanic-adjusted effective HP.

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
import campaign_runtime_contracts
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
FINALE_PHASE_CAP_SECONDS = 460.0
CONTRACT_TIME_FLOAT_TOLERANCE_SECONDS = 0.1


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
    economy: dict,
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
    boss_damage_factor = power_ruler.boss_element_factor(
        bosses[FINAL_BOSS_ID], str(weapon.get("element", "physical")), economy)
    special = weapon.get("special", {})
    pellets = max(1, int(special.get("pellets", 1)))
    crowd_mult = 1.0 + 0.18 * float(special.get("pierce", 0))
    if pellets > 1:
        crowd_mult *= 1.0 + float(pellets - 1) * 0.62
    return mob_hp / max(raw_dps * crowd_mult, 1.0) + boss_hp / max(raw_dps * boss_damage_factor, 1.0)


def corridor_boss_stage_seconds(
    level: dict,
    effective_boss_hp: float,
    family_context: power_ruler.FamilyContext,
    runtime_builds: dict,
) -> tuple[str, float]:
    """Return the design/35 milestone-Boss phase time for its legal family."""
    level_no = balance.level_number(level)
    weapon_id = "weapon_autocannon" if level_no <= 80 else "weapon_scattergun"
    recommend = float(level.get("recommend_level", level_no))
    char_level, weapon_level = family_context.family_levels(recommend)
    raw = power_ruler._player_dps_cont(
        balance,
        family_context.characters,
        family_context.weapons,
        char_level,
        weapon_level,
        1.0,
    )
    permanent = raw / max(family_context.max_raw_autocannon, 1.0)
    card_progress = (
        balance.estimate_skill_mult(level)
        / max(family_context.max_card_throughput, 1.0)
    )
    boss_dps = float(runtime_builds[weapon_id]["boss_dps"]) * permanent * card_progress
    return weapon_id, effective_boss_hp / max(boss_dps, 1.0)


def main() -> int:
    levels = load("levels")
    zombies = load("zombies")
    bosses = load("bosses")
    characters = load("characters")
    weapons = load("weapons")
    armors = load("armors")
    chips = load("chips")
    pets = load("pets")
    skills = load("skills")
    economy = load("economy")
    runtime_benchmark = load_runtime_benchmark()
    runtime_builds = runtime_benchmark["best_same_loadout"]
    runtime_levels, runtime_contract, runtime_errors = campaign_runtime_contracts.load()
    family_context = power_ruler.FamilyContext(balance, characters, weapons, economy)
    errors: list[str] = list(runtime_errors)

    by_id = {level["id"]: level for level in levels}
    finale = by_id[FINAL_LEVEL_ID]
    mob_hp, boss_hp = level_hp_split(finale, zombies, bosses, economy)
    boss_effective_hp = float(
        finale.get("clear_requirement", {}).get("power_contract", {}).get("boss_effective_hp", boss_hp))

    checkpoints = (50, 60, 70, 80, 90, 97, 98, 99)
    hp_curve = [balance.late_wave_level_ramp(economy, level_no) for level_no in checkpoints]
    damage_curve = [balance.late_wave_damage_ramp(economy, level_no, 3) for level_no in checkpoints]
    count_curve = [balance.late_wave_count_level_ramp(economy, level_no, 3) for level_no in checkpoints]
    if any(b <= a for a, b in zip(hp_curve, hp_curve[1:])):
        errors.append(f"level-50+ HP ramp must rise strictly: {hp_curve}")
    if any(abs(value - 1.0) > 1e-6 for value in damage_curve):
        errors.append(f"late-game attack ramp must stay disabled at 1.0x: {damage_curve}")
    if any(b < a for a, b in zip(count_curve, count_curve[1:])):
        errors.append(f"level-50+ crowd count ramp must not regress: {count_curve}")
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
    for boss_id, boss in bosses.items():
        if float(boss.get("fixed_hp", 0.0)) <= 0.0:
            errors.append(f"{boss_id} must own positive fixed_hp")
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

    # Keep the design/25 theoretical single-body Apex phase contract separate
    # from the current fixed-identity roster. This remains the frozen 116.6s
    # phase audit even while authored copy counts and stack multipliers evolve.
    apex_phase_windows: list[tuple[int, float, float, int]] = []
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
    frozen_apex = runtime_benchmark.get("frozen_phase_contracts", {}).get(
        "apex_single_body", {})
    phase_time_weight = float(frozen_apex.get("phase_time_weight", 0.0))
    for row in frozen_apex.get("rows", []):
        level_no = int(row.get("level", 0))
        checkpoint_boss_hp = float(row.get("effective_hp", 0.0))
        ttk = checkpoint_boss_hp / max(counter_dps, 1.0) * phase_time_weight
        casts = max(0, 1 + int((ttk - first_skill_seconds) // 4.8)) if ttk >= first_skill_seconds else 0
        apex_phase_windows.append((level_no, checkpoint_boss_hp, ttk, casts))
        target_seconds = float(row.get("target_seconds", ttk))
        if abs(ttk - target_seconds) > CONTRACT_TIME_FLOAT_TOLERANCE_SECONDS:
            errors.append(
                f"design/25 Apex L{level_no} single-phase contract must remain "
                f"{target_seconds:.1f}s, got {ttk:.1f}s")
    if not apex_phase_windows or abs(apex_phase_windows[-1][2] - 116.6) > 0.1:
        errors.append(
            "design/25 Apex single-phase contract must remain 116.6s, "
            f"got {apex_phase_windows[-1][2]:.1f}s" if apex_phase_windows else "missing")

    # Contract effective HP contains phase/armor mechanics and literal authored
    # copies. Stage 198 replaces the old cross-family time bands with explicit
    # roster checkpoints: within each free-family segment, durability and phase
    # time must rise; the L80→L85 family graduation may reset the time scale.
    boss_stage_rows: list[tuple[int, str, float, float, float, float, str]] = []
    for level_no in (45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95):
        level = by_id[f"level_{level_no:03d}"]
        contract = level.get("clear_requirement", {}).get("power_contract", {})
        effective_hp = float(contract.get("boss_effective_hp", 0.0))
        weapon_id = "weapon_autocannon" if level_no <= 80 else "weapon_scattergun"
        runtime_band = campaign_runtime_contracts.boss_phase_band(level_no)
        if level_no in runtime_levels and runtime_band is not None:
            seconds = float(runtime_contract[level_no]["median_boss_phase_seconds"])
            lower, upper = runtime_band
            tolerance = campaign_runtime_contracts.boss_phase_tolerance_seconds(level_no)
            source = "fixed-frame"
        else:
            weapon_id, seconds = corridor_boss_stage_seconds(
                level, effective_hp, family_context, runtime_builds)
            lower, upper = (0.0, 60.0) if level_no <= 70 else (60.0, 100.0)
            tolerance = 0.0
            source = "analytical"
        boss_stage_rows.append(
            (level_no, weapon_id, effective_hp, seconds, lower, upper, source))
        if not lower - tolerance <= seconds <= upper + tolerance:
            errors.append(
                f"level_{level_no:03d} Boss stage {seconds:.1f}s outside "
                f"design/35 band [{lower:.0f},{upper:.0f}]s")

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

    full_roster_rows: list[tuple[str, float, bool]] = []
    for weapon_id in MAXED_PHYSICAL_WEAPONS:
        seconds = runtime_finale_seconds(mob_hp, boss_effective_hp, weapon_id, runtime_builds)
        full_roster_rows.append((weapon_id, seconds, seconds <= FINALE_PHASE_CAP_SECONDS))
    fastest_weapon, fastest_seconds, _ = min(full_roster_rows, key=lambda row: row[1])
    if fastest_weapon != "weapon_scattergun":
        errors.append(
            f"graduation family must remain scattergun, got fastest={fastest_weapon}")
    boss_pacing = economy.get("boss_pacing", {}) or {}
    finale_band = boss_pacing.get("finale_time_band", [150.0, 185.0])
    finale_min_seconds = float(finale_band[0])
    finale_max_seconds = float(finale_band[1])
    runtime_finale_boss_seconds = float(
        runtime_contract.get(99, {}).get("median_boss_phase_seconds", 0.0))
    runtime_finale_tolerance = campaign_runtime_contracts.boss_phase_tolerance_seconds(99)
    if not (
        finale_min_seconds - runtime_finale_tolerance
        <= runtime_finale_boss_seconds
        <= finale_max_seconds + runtime_finale_tolerance
    ):
        errors.append(
            "strongest free max build must clear the complete authored Boss phase "
            f"inside [{finale_min_seconds:.0f},{finale_max_seconds:.0f}]s, "
            f"got fixed-frame={runtime_finale_boss_seconds:.1f}s")

    observed_like_seconds = estimated_mismatched_finale_seconds(
        finale,
        mob_hp,
        boss_hp,
        characters,
        weapons,
        bosses,
        economy,
        "weapon_plasmacannon",
        41,
        modern_dps_scale,
    )
    if observed_like_seconds < 300.0:
        errors.append(
            "level-41 mismatched plasma build must not remain a comfortable finale clear: "
            f"estimated {observed_like_seconds:.1f}s"
        )

    final_contract = finale.get("clear_requirement", {}).get("power_contract", {})
    final_recommended = int(final_contract.get("recommended_power", 0))
    all_max_skills = {
        skill_id: power_ruler.skill_max_level(row) for skill_id, row in skills.items()
    }
    finale_build = {
        "character": "vanguard", "character_level": 40,
        "weapon": "weapon_scattergun", "weapon_level": 50,
        "armor": "armor_kevlar", "armor_level": 35,
        "chip": "chip_attack", "chip_level": 35,
        "pet": "pet_turret_drone", "pet_level": 30,
        "signature_level": 5, "skill_base_levels": all_max_skills,
    }
    finale_power = power_ruler.power_for_build(
        finale, final_contract, finale_build, characters, weapons,
        armors, chips, pets, skills, bosses, economy)
    finale_ratio = min(float(value) for value in finale_power["ratios"].values())
    if not 1.15 <= finale_ratio <= 1.19:
        errors.append(
            "max free graduation build must remain modestly above the level-99 line, "
            f"got R={finale_ratio:.4f}")
    contract_reference_seconds = balance.runtime_boss_contract_clear_time(
        finale, mob_hp, 1.0, economy)

    print("Endgame balance matrix")
    print("  HP ramp:     " + ", ".join(f"L{n}={v:.3f}x" for n, v in zip(checkpoints, hp_curve)))
    print("  damage ramp: " + ", ".join(f"L{n}={v:.3f}x" for n, v in zip(checkpoints, damage_curve)))
    print("  count ramp:  " + ", ".join(f"L{n}={v:.3f}x" for n, v in zip(checkpoints, count_curve)))
    _, finale_bosses, _ = balance.level_enemy_hp_profile(finale, zombies, bosses, economy)
    boss_detail = ", ".join(f"{boss_id}={hp / 1_000_000:.2f}M" for boss_id, hp in finale_bosses.items())
    print(f"  level_099 HP: mobs={mob_hp / 1_000_000:.2f}M bosses={boss_hp / 1_000_000:.2f}M ({boss_detail})")
    print(f"  modern DPS calibration: {modern_dps_scale:.3f}x (vanguard rail={modern_reference_dps:.0f})")
    print("  physical throughput: Godot runtime benchmark (all 8 max offensive skills)")
    print("  Apex single-phase audit (design/25 116.6s theoretical contract)")
    for level_no, checkpoint_boss_hp, ttk, casts in apex_phase_windows:
        print(
            f"    Apex L{level_no}: hp={checkpoint_boss_hp / 1_000_000:.2f}M "
            f"counter-TTK={ttk:.1f}s skill-windows={casts}")
    print("  Boss milestone phase audit (design/35 corridor families)")
    for level_no, weapon_id, effective_hp, seconds, lower, upper, source in boss_stage_rows:
        print(
            f"    L{level_no}: {weapon_id} effective={effective_hp / 1_000_000:.2f}M "
            f"phase={seconds:.1f}s band=[{lower:.0f},{upper:.0f}]s source={source}")
    print(
        "  Four-Boss full-encounter audit "
        f"(authored={','.join(sorted(authored_boss_ids))}; "
        f"effective={boss_effective_hp / 1_000_000:.2f}M; cap={FINALE_PHASE_CAP_SECONDS:.0f}s)")
    for weapon_id, seconds, within_cap in full_roster_rows:
        status = "within cap" if within_cap else "over cap"
        graduation = "; graduation family" if weapon_id == "weapon_scattergun" else ""
        print(f"    {weapon_id}: {seconds:.1f}s ({status}{graduation})")
    print(
        f"    authoritative fixed-frame Boss phase={runtime_finale_boss_seconds:.1f}s "
        f"band=[{finale_min_seconds:.0f},{finale_max_seconds:.0f}]s")
    autocannon_seconds = next(row[1] for row in full_roster_rows if row[0] == "weapon_autocannon")
    if autocannon_seconds > FINALE_PHASE_CAP_SECONDS:
        print("    decision: autocannon exceeds cap; graduation build = scattergun family")
    else:
        print("    decision: graduation build = scattergun family; autocannon remains inside cap")
    print(f"  mismatched plasma L41 estimated={observed_like_seconds:.1f}s")
    print(f"  level_099 power={finale_power['power']} recommended={final_recommended} R={finale_ratio:.4f}")
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
