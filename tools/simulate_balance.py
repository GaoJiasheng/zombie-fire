#!/usr/bin/env python3
"""Balance simulator.

For each level, estimate:
  - Total enemy HP, including the boss wave's HP and boss support.
  - Player DPS at the level's recommended progression level (clamped to each
    item's real max), with vanguard + autocannon, base chips/armor, current
    economy pacing knobs, and the skill-card multiplier implied by card budget.
  - Predicted clear time + estimated leak damage (5% leak on non-boss
    levels, 12% leak on boss levels because the boss can't be ignored).
  - Two scenarios: no_skill (very early game) and with_skill (mid-run).

Outputs a table sorted by level so we can spot trivially-easy and
impossibly-hard levels at a glance.
"""
from __future__ import annotations
import json
import math
from pathlib import Path

from combat_power_model import estimate_skill_throughput, run_skill_hp_pressure

ROOT = Path(__file__).resolve().parent.parent
LEVELS_PATH = ROOT / "data" / "levels.json"
ZOMBIES_PATH = ROOT / "data" / "zombies.json"
BOSSES_PATH = ROOT / "data" / "bosses.json"
CHARS_PATH = ROOT / "data" / "characters.json"
WEAPONS_PATH = ROOT / "data" / "weapons.json"
ECONOMY_PATH = ROOT / "data" / "economy.json"

GLOBAL_DMG_BASE = 10.0
BASE_WEAPON_DAMAGE = 28.0

CHIP_DAMAGE_MULT = 1.20   # chip_attack at moderate level
ARMOR_HP_MULT = 1.20      # armor_kevlar (typical)
BOSS_LEAK = 0.12
NORMAL_LEAK = 0.05

DEFAULT_LATE_WAVE_HP_BONUS = {"3": 1.45, "4": 1.85, "5": 2.30}
DEFAULT_LATE_WAVE_COUNT_MULT = {"4": 2.0, "5": 3.0}
DEFAULT_LATE_WAVE_BOSS_HP_BONUS = {"3": 1.30, "4": 1.50, "5": 1.75}
DEFAULT_LATE_WAVE_LEVEL_RAMP = {"start_level": 50, "full_level": 98, "max_mult": 1.80, "curve_power": 1.0, "final_level": 99, "final_mult": 1.20}
DEFAULT_LATE_WAVE_DAMAGE_RAMP = {"start_level": 50, "full_level": 98, "start_wave": 3, "max_mult": 2.0, "curve_power": 1.0, "final_level": 99, "final_mult": 1.15}
DEFAULT_BOSS_HP_LEVEL_BONUS = {"start_level": 20, "multiplier": 2.0}


def wave_number(wave: dict) -> int:
    try:
        return int(wave.get("wave", 0))
    except (TypeError, ValueError):
        return 0


def late_wave_level_ramp(economy: dict, level_no: int) -> float:
    rule = economy.get("late_wave_level_ramp", DEFAULT_LATE_WAVE_LEVEL_RAMP)
    if not isinstance(rule, dict):
        rule = DEFAULT_LATE_WAVE_LEVEL_RAMP
    start_level = float(rule.get("start_level", DEFAULT_LATE_WAVE_LEVEL_RAMP["start_level"]))
    full_level = float(rule.get("full_level", DEFAULT_LATE_WAVE_LEVEL_RAMP["full_level"]))
    max_mult = float(rule.get("max_mult", DEFAULT_LATE_WAVE_LEVEL_RAMP["max_mult"]))
    if float(level_no) < start_level:
        return 1.0
    ramp_mult = max_mult
    if full_level > start_level:
        t = max(0.0, min(1.0, (float(level_no) - start_level) / (full_level - start_level)))
        curve_power = max(0.01, float(rule.get("curve_power", DEFAULT_LATE_WAVE_LEVEL_RAMP["curve_power"])))
        ramp_mult = 1.0 + (max_mult - 1.0) * (t ** curve_power)
    final_level = int(rule.get("final_level", DEFAULT_LATE_WAVE_LEVEL_RAMP["final_level"]))
    if level_no >= final_level:
        ramp_mult *= max(1.0, float(rule.get("final_mult", DEFAULT_LATE_WAVE_LEVEL_RAMP["final_mult"])))
    return ramp_mult


def late_wave_damage_ramp(economy: dict, level_no: int, wave_no: int) -> float:
    rule = economy.get("late_wave_damage_ramp", DEFAULT_LATE_WAVE_DAMAGE_RAMP)
    if not isinstance(rule, dict):
        rule = DEFAULT_LATE_WAVE_DAMAGE_RAMP
    if wave_no < int(rule.get("start_wave", DEFAULT_LATE_WAVE_DAMAGE_RAMP["start_wave"])):
        return 1.0
    start_level = float(rule.get("start_level", DEFAULT_LATE_WAVE_DAMAGE_RAMP["start_level"]))
    full_level = float(rule.get("full_level", DEFAULT_LATE_WAVE_DAMAGE_RAMP["full_level"]))
    max_mult = float(rule.get("max_mult", DEFAULT_LATE_WAVE_DAMAGE_RAMP["max_mult"]))
    if float(level_no) < start_level:
        return 1.0
    ramp_mult = max_mult
    if full_level > start_level:
        t = max(0.0, min(1.0, (float(level_no) - start_level) / (full_level - start_level)))
        curve_power = max(0.01, float(rule.get("curve_power", DEFAULT_LATE_WAVE_DAMAGE_RAMP["curve_power"])))
        ramp_mult = 1.0 + (max_mult - 1.0) * (t ** curve_power)
    final_level = int(rule.get("final_level", DEFAULT_LATE_WAVE_DAMAGE_RAMP["final_level"]))
    if level_no >= final_level:
        ramp_mult *= max(1.0, float(rule.get("final_mult", DEFAULT_LATE_WAVE_DAMAGE_RAMP["final_mult"])))
    return ramp_mult


def late_wave_hp_bonus(economy: dict, wave_no: int, boss: bool = False, level_no: int = 0, card_picks: int = 4) -> float:
    key = "late_wave_boss_hp_bonus" if boss else "late_wave_hp_bonus"
    defaults = DEFAULT_LATE_WAVE_BOSS_HP_BONUS if boss else DEFAULT_LATE_WAVE_HP_BONUS
    table = economy.get(key, defaults)
    if not isinstance(table, dict):
        table = defaults
    base = float(table.get(str(wave_no), table.get(wave_no, defaults.get(str(wave_no), 1.0))))
    if wave_no >= 3:
        base *= late_wave_level_ramp(economy, level_no)
        base *= run_skill_hp_pressure(card_picks, economy)
    return base


def late_wave_count_mult(economy: dict, wave_no: int) -> float:
    table = economy.get("late_wave_count_mult", DEFAULT_LATE_WAVE_COUNT_MULT)
    if not isinstance(table, dict):
        table = DEFAULT_LATE_WAVE_COUNT_MULT
    return max(1.0, float(table.get(str(wave_no), table.get(wave_no, DEFAULT_LATE_WAVE_COUNT_MULT.get(str(wave_no), 1.0)))))


def level_number(level: dict) -> int:
    try:
        return int(str(level.get("id", "level_000")).split("_")[-1])
    except (TypeError, ValueError):
        return 0


def boss_hp_level_bonus(economy: dict, level: dict) -> float:
    rule = economy.get("boss_hp_level_bonus", DEFAULT_BOSS_HP_LEVEL_BONUS)
    if not isinstance(rule, dict):
        rule = DEFAULT_BOSS_HP_LEVEL_BONUS
    start_level = int(rule.get("start_level", DEFAULT_BOSS_HP_LEVEL_BONUS["start_level"]))
    multiplier = float(rule.get("multiplier", DEFAULT_BOSS_HP_LEVEL_BONUS["multiplier"]))
    return multiplier if level_number(level) >= start_level else 1.0


def estimate_player_dps(char_id: str, weapon_id: str, char_level: int, weapon_level: int, skill_mult: float) -> float:
    chars = json.loads(CHARS_PATH.read_text(encoding="utf-8"))
    weapons = json.loads(WEAPONS_PATH.read_text(encoding="utf-8"))
    economy = json.loads(ECONOMY_PATH.read_text(encoding="utf-8"))
    char = chars[char_id]
    weapon = weapons[weapon_id]
    base_atk = float(char["base_atk"])
    atk_growth = float(char["atk_growth"])
    fire_rate_mod = float(char.get("fire_rate_mod", 1.0))
    base_atk_coef = float(weapon.get("base_atk_coef", 1.0))
    fire_rate = float(weapon.get("fire_rate", 4.0))
    char_atk_mult = (base_atk / 100.0) * (1.0 + atk_growth * 0.45 * (char_level - 1))
    weapon_dmg_mult = 1.0 + 0.08 * (weapon_level - 1)
    weapon_fr_mult = 1.0 + 0.025 * (weapon_level - 1)
    base_damage = BASE_WEAPON_DAMAGE * base_atk_coef
    damage = base_damage * char_atk_mult * weapon_dmg_mult * CHIP_DAMAGE_MULT * float(economy.get("PLAYER_SHOT_DAMAGE_MULT", 1.0))
    fr = fire_rate * weapon_fr_mult * float(economy.get("PLAYER_FIRE_RATE_MULT", 0.25)) * fire_rate_mod
    affinity_mult = 1.10 if weapon.get("element", "physical") == char.get("element_focus", "") else 1.0
    pierce_throughput = 1.18 if char_id == "vanguard" else 1.0
    return damage * fr * skill_mult * affinity_mult * pierce_throughput


def level_enemy_hp(level: dict, zombies: dict, bosses: dict, economy: dict) -> tuple[float, int]:
    diff = float(level["difficulty_coef"])
    hp_base = float(level.get("base_hp_ref", 50.0))
    total_hp = 0.0
    count = 0
    boss_level_bonus = boss_hp_level_bonus(economy, level)
    level_no = level_number(level)
    card_picks = int(level.get("target_card_picks", 4))
    for wave in level.get("waves", []):
        wave_no = wave_number(wave)
        mob_bonus = late_wave_hp_bonus(economy, wave_no, level_no=level_no, card_picks=card_picks)
        count_mult = late_wave_count_mult(economy, wave_no)
        # Normal spawns
        for spawn in wave.get("spawns", []):
            t = spawn.get("type", "")
            z = zombies.get(t, {})
            hp = hp_base * float(z.get("hp_coef", 1.0)) * diff * mob_bonus
            c = int(round(int(spawn.get("count", 0)) * count_mult))
            total_hp += hp * c
            count += c
        # Boss entry (last wave typically)
        if "boss" in wave:
            boss_id = wave["boss"]
            boss_row = bosses.get(boss_id, {})
            boss_hp = hp_base * float(boss_row.get("hp_coef", 18.0)) * diff * late_wave_hp_bonus(economy, wave_no, True, level_no, card_picks) * boss_level_bonus
            total_hp += boss_hp
            count += 1
        # Boss support mobs
        for spawn in wave.get("support", []):
            t = spawn.get("type", "")
            z = zombies.get(t, {})
            hp = hp_base * float(z.get("hp_coef", 1.0)) * diff * mob_bonus
            c = int(round(int(spawn.get("count", 0)) * count_mult))
            total_hp += hp * c
            count += c
    return total_hp, count


def level_spawn_time(level: dict, economy: dict) -> float:
    duration = 0.0
    for wave in level.get("waves", []):
        count_mult = late_wave_count_mult(economy, wave_number(wave))
        for spawn in wave.get("spawns", []) + wave.get("support", []):
            duration += int(round(int(spawn.get("count", 0)) * count_mult)) * float(spawn.get("interval", 0.8))
    return duration


def estimate_skill_mult(level: dict) -> float:
    cards = int(level.get("target_card_picks", 4))
    # This is effective crowd throughput, not only character-sheet single-target
    # DPS. Later card budgets combine lanes, pierce, chain/splash, status damage
    # and cadence, so their contribution compounds while remaining below a
    # perfect all-DPS draft.
    return estimate_skill_throughput(cards)


def leak_damage(level: dict, zombies: dict, bosses: dict, economy: dict, is_boss_level: bool) -> float:
    """Expected breach damage given a leak rate."""
    leak = BOSS_LEAK if is_boss_level else NORMAL_LEAK
    total = 0.0
    level_no = level_number(level)
    for wave in level.get("waves", []):
        wave_no = wave_number(wave)
        damage_mult = late_wave_damage_ramp(economy, level_no, wave_no)
        count_mult = late_wave_count_mult(economy, wave_no)
        for spawn in wave.get("spawns", []):
            t = spawn.get("type", "")
            z = zombies.get(t, {})
            # Breach damage is configured from bd_coef only at runtime; enemy
            # HP/difficulty/late-wave multipliers must not inflate it here.
            bd = GLOBAL_DMG_BASE * float(z.get("bd_coef", 1.0)) * damage_mult
            total += bd * int(round(int(spawn.get("count", 0)) * count_mult))
        if "boss" in wave:
            boss_id = wave["boss"]
            boss_row = bosses.get(boss_id, {})
            bd = GLOBAL_DMG_BASE * float(boss_row.get("bd_coef", 4.0)) * damage_mult
            total += bd
        for spawn in wave.get("support", []):
            t = spawn.get("type", "")
            z = zombies.get(t, {})
            bd = GLOBAL_DMG_BASE * float(z.get("bd_coef", 1.0)) * damage_mult
            total += bd * int(round(int(spawn.get("count", 0)) * count_mult))
    return total * leak


def is_boss_level(level: dict) -> bool:
    return any("boss" in w for w in level.get("waves", []))


def main() -> int:
    levels: list[dict] = json.loads(LEVELS_PATH.read_text(encoding="utf-8"))
    zombies: dict[str, dict] = json.loads(ZOMBIES_PATH.read_text(encoding="utf-8"))
    bosses: dict[str, dict] = json.loads(BOSSES_PATH.read_text(encoding="utf-8"))
    characters: dict[str, dict] = json.loads(CHARS_PATH.read_text(encoding="utf-8"))
    weapons: dict[str, dict] = json.loads(WEAPONS_PATH.read_text(encoding="utf-8"))
    economy: dict = json.loads(ECONOMY_PATH.read_text(encoding="utf-8"))

    print(f"{'level':<11} {'ch':<3} {'recom':<5} {'coef':<6} {'cards':>5} {'spawn':>6} {'hp_total':>9} {'dps_ns':>6} {'dps_ws':>6} {'t_ns':>6} {'t_ws':>6} {'leak%':>6}  notes")
    print("-" * 110)

    rows = []
    for lv in levels:
        n = int(lv["id"].split("_")[1])
        hp_total, count = level_enemy_hp(lv, zombies, bosses, economy)
        recommended_level = int(lv.get("recommend_level", n))
        char_level = min(recommended_level, int(characters["vanguard"].get("max_level", 40)))
        weapon_level = min(recommended_level, int(weapons["weapon_autocannon"].get("max_level", 50)))
        dps_ns = estimate_player_dps("vanguard", "weapon_autocannon", char_level, weapon_level, 1.0)
        skill_mult = estimate_skill_mult(lv)
        dps_ws = estimate_player_dps("vanguard", "weapon_autocannon", char_level, weapon_level, skill_mult)
        time_ns = hp_total / max(dps_ns, 1.0)
        time_ws = hp_total / max(dps_ws, 1.0)
        spawn_time = level_spawn_time(lv, economy)
        boss_lvl = is_boss_level(lv)
        leak = leak_damage(lv, zombies, bosses, economy, boss_lvl)
        # base_hp_ref * armor_mult is the real starting HP
        leak_pct = min(100.0, leak / max(float(lv.get("base_hp_ref", 100)) * ARMOR_HP_MULT, 1.0) * 100.0)
        rows.append((n, lv.get("chapter", 0), char_level, float(lv["difficulty_coef"]),
                     int(lv.get("target_card_picks", 0)), spawn_time, hp_total, dps_ns, dps_ws, time_ns, time_ws, leak_pct, boss_lvl))

    rows.sort(key=lambda r: r[0])
    for n, ch, recom, coef, cards, spawn_time, hp, dps_ns, dps_ws, t_ns, t_ws, leak_pct, boss_lvl in rows:
        notes = []
        if boss_lvl:
            notes.append("BOSS")
        if t_ns < spawn_time * 0.72 and not boss_lvl:
            notes.append("LOW_PRESSURE")
        if t_ns > spawn_time * 1.18:
            notes.append("BUILD_CHECK")
        if t_ws > spawn_time * 0.85:
            notes.append("HARD")
        # Predicted star rating based on leak%
        if leak_pct > 70:
            notes.append("1★")
        elif leak_pct > 40:
            notes.append("2★")
        else:
            notes.append("3★")
        line = f"level_{n:03d}  ch{ch:<2} {recom:<5} {coef:<6.2f} {cards:>5} {spawn_time:>6.1f} {hp:>9.0f} {dps_ns:>6.0f} {dps_ws:>6.0f} {t_ns:>6.1f} {t_ws:>6.1f} {leak_pct:>5.0f}%  {' '.join(notes)}"
        print(line)

    times_ws = [r[10] for r in rows]
    print()
    print(f"With-skill avg clear time: {sum(times_ws)/len(times_ws):.1f}s")
    print(f"With-skill min/max: {min(times_ws):.1f}s / {max(times_ws):.1f}s")
    too_easy = sum(1 for r in rows if r[10] < 30)
    def clear_time_cap(level_no: int) -> float:
        if level_no >= 99:
            # The finale is intentionally a graduation spike. The dedicated
            # endgame matrix proves maxed counter-builds remain viable; this
            # generic autocannon model deliberately represents the slow clear.
            return 460.0
        if level_no >= 90:
            return 330.0
        if level_no >= 80:
            return 310.0
        if level_no >= 70:
            return 245.0
        if level_no >= 60:
            return 190.0
        return 180.0

    too_hard_rows = [r for r in rows if r[10] > clear_time_cap(r[0])]
    print(f"Levels < 30s (with skill): {too_easy}")
    print(f"Levels above phase-specific clear-time cap: {len(too_hard_rows)}")
    errors: list[str] = []
    if too_hard_rows:
        details = ", ".join(f"level_{row[0]:03d}={row[10]:.1f}s>{clear_time_cap(row[0]):.0f}s" for row in too_hard_rows)
        errors.append(f"campaign contains an HP wall above its phase cap: {details}")
    finale_hp = rows[-1][6]
    prior_peak = max(row[6] for row in rows[:-1])
    if finale_hp < prior_peak * 1.02:
        errors.append(f"final boss HP {finale_hp:.0f} must exceed prior peak {prior_peak:.0f}")
    if errors:
        print("Balance simulation failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("Balance simulation OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
