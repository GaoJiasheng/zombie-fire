#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(name: str):
    return json.loads((ROOT / "data" / f"{name}.json").read_text(encoding="utf-8"))


DEFAULT_LATE_WAVE_HP_BONUS = {"3": 1.20, "4": 1.44, "5": 1.62}
DEFAULT_LATE_WAVE_BOSS_HP_BONUS = {"3": 1.20, "4": 1.20, "5": 1.20}
DEFAULT_BOSS_HP_LEVEL_BONUS = {"start_level": 20, "multiplier": 2.0}


def wave_number(wave: dict) -> int:
    try:
        return int(wave.get("wave", 0))
    except (TypeError, ValueError):
        return 0


def late_wave_hp_bonus(economy: dict, wave_no: int, boss: bool = False) -> float:
    key = "late_wave_boss_hp_bonus" if boss else "late_wave_hp_bonus"
    defaults = DEFAULT_LATE_WAVE_BOSS_HP_BONUS if boss else DEFAULT_LATE_WAVE_HP_BONUS
    table = economy.get(key, defaults)
    if not isinstance(table, dict):
        table = defaults
    return float(table.get(str(wave_no), table.get(wave_no, defaults.get(str(wave_no), 1.0))))


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


def main() -> int:
    zombies = load("zombies")
    bosses = load("bosses")
    economy = load("economy")
    levels = load("levels")
    errors: list[str] = []
    print("Level pressure estimate")
    series: list[tuple[str, float, bool]] = []
    for level in levels:
        pressure = 0.0
        duration = 0.0
        boss_count = 0
        boss_level_bonus = boss_hp_level_bonus(economy, level)
        for wave in level.get("waves", []):
            wave_no = wave_number(wave)
            mob_bonus = late_wave_hp_bonus(economy, wave_no)
            for group in wave.get("spawns", []):
                row = zombies[group["type"]]
                count = int(group.get("count", 1))
                pressure += count * float(row.get("hp_coef", 1.0)) * mob_bonus * float(row.get("bd_coef", 1.0))
                duration += count * float(group.get("interval", 0.8))
            if "boss" in wave:
                boss_count += 1
                pressure += float(bosses[wave["boss"]].get("hp_coef", 1.0)) * late_wave_hp_bonus(economy, wave_no, True) * boss_level_bonus * 8.0
            for group in wave.get("support", []):
                row = zombies[group["type"]]
                count = int(group.get("count", 1))
                pressure += count * float(row.get("hp_coef", 1.0)) * mob_bonus * float(row.get("bd_coef", 1.0))
                duration += count * float(group.get("interval", 0.8))
        pressure *= float(level.get("difficulty_coef", 1.0))
        series.append((level["id"], pressure, boss_count > 0))
        print(f"{level['id']}: pressure={pressure:.1f}, spawn_time={duration:.1f}s, boss={boss_count}")
        min_duration = 40.0 if boss_count else 36.0
        if level["id"] == "level_001":
            min_duration = 38.0
        if duration < min_duration:
            errors.append(f"{level['id']} spawn duration too short: {duration:.1f}s")
        if pressure <= 0.0:
            errors.append(f"{level['id']} pressure must be positive")

    # Difficulty must ramp smoothly. Boss levels are intentional periodic spikes,
    # so each stream (boss / non-boss) is checked for monotonic non-decreasing
    # pressure independently rather than the raw interleaved series.
    for stream_name, want_boss in (("non-boss", False), ("boss", True)):
        prev_id = ""
        prev_pressure = -1.0
        for level_id, pressure, is_boss in series:
            if is_boss != want_boss:
                continue
            if prev_pressure >= 0.0 and pressure < prev_pressure - 1e-6:
                errors.append(
                    f"{stream_name} difficulty regresses: {level_id} pressure "
                    f"{pressure:.1f} < {prev_id} {prev_pressure:.1f}"
                )
            prev_id, prev_pressure = level_id, pressure

    # The campaign must finish on a boss, and the finale must be the hardest fight.
    if series:
        last_id, last_pressure, last_is_boss = series[-1]
        if not last_is_boss:
            errors.append(f"final level {last_id} must end on a boss wave")
        peak_id, peak_pressure, _ = max(series, key=lambda item: item[1])
        if peak_id != last_id:
            errors.append(
                f"final level {last_id} ({last_pressure:.1f}) must be the peak; "
                f"{peak_id} is higher ({peak_pressure:.1f})"
            )

    # Layout variety: no three consecutive levels may share the same wave pattern,
    # so the campaign never feels like the same fight on repeat.
    patterns = [str(level.get("wave_pattern", "")) for level in levels]
    if all(patterns):
        # Levels 1-5 are the onboarding stretch and intentionally stay "standard".
        for i in range(max(2, 5), len(patterns)):
            if patterns[i] == patterns[i - 1] == patterns[i - 2]:
                errors.append(
                    f"wave pattern '{patterns[i]}' repeats 3x at levels {i - 1}-{i + 1}"
                )
        distinct = len(set(patterns))
        if distinct < 4:
            errors.append(f"too few distinct wave patterns: {distinct} (want >= 4)")

    # Variant levels are reward/flavour tags layered on the wave data without
    # changing pressure. Keep boss/non-boss tagging consistent and ensure the
    # campaign actually contains a healthy spread of special levels.
    valid_variants = {"normal", "elite", "treasure", "boss", "boss_rush"}
    boss_ids = {sid for sid, _pressure, is_boss in series if is_boss}
    variant_counts: dict[str, int] = {}
    for level in levels:
        variant = str(level.get("variant", ""))
        if variant not in valid_variants:
            errors.append(f"{level['id']} has invalid variant '{variant}'")
            continue
        variant_counts[variant] = variant_counts.get(variant, 0) + 1
        level_is_boss = level["id"] in boss_ids
        if level_is_boss and variant not in ("boss", "boss_rush"):
            errors.append(f"{level['id']} is a boss level but variant is '{variant}'")
        if not level_is_boss and variant in ("boss", "boss_rush"):
            errors.append(f"{level['id']} is not a boss level but variant is '{variant}'")
    if levels and str(levels[-1].get("variant", "")) != "boss_rush":
        errors.append("final level must use the boss_rush variant")
    for needed in ("elite", "treasure"):
        if variant_counts.get(needed, 0) < 3:
            errors.append(f"too few '{needed}' variant levels: {variant_counts.get(needed, 0)} (want >= 3)")

    if errors:
        print("Pressure check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
