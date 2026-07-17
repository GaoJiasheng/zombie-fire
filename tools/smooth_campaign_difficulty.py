#!/usr/bin/env python3
"""Recalibrate campaign HP coefficients around consistent combat pacing.

Only ``difficulty_coef`` changes. Enemy rosters, wave counts, late-wave
multipliers, boss rules, rewards, story, and recommended levels stay intact.
"""
from __future__ import annotations

import argparse
import copy
import json
from pathlib import Path

import simulate_balance as balance


ROOT = Path(__file__).resolve().parents[1]
LEVELS_PATH = ROOT / "data" / "levels.json"


def target_clear_ratio(level_no: int, boss_level: bool) -> float:
    if level_no <= 5:
        base = [0.32, 0.48, 0.52, 0.58, 0.40][level_no - 1]
    elif level_no <= 20:
        base = 0.64 + (level_no - 6) * (0.08 / 14.0)
    elif level_no <= 50:
        base = 0.72 + (level_no - 20) * (0.04 / 30.0)
    elif level_no <= 80:
        base = 0.76 + (level_no - 50) * (0.04 / 30.0)
    else:
        base = 0.80 + (level_no - 80) * (0.06 / 19.0)
    return min(0.94, base + (0.06 if boss_level else 0.0))


def recommended_dps(level: dict) -> float:
    recommended = int(level.get("recommend_level", 1))
    return balance.estimate_player_dps(
        "vanguard",
        "weapon_autocannon",
        recommended,
        recommended,
        balance.estimate_skill_mult(level),
    )


def total_hp(level: dict, zombies: dict, bosses: dict, economy: dict) -> float:
    return balance.level_enemy_hp(level, zombies, bosses, economy)[0]


def recalibrate(levels: list[dict], zombies: dict, bosses: dict, economy: dict) -> list[dict]:
    result = copy.deepcopy(levels)
    for level in result:
        level_no = balance.level_number(level)
        boss_level = balance.is_boss_level(level)
        current_time = total_hp(level, zombies, bosses, economy) / max(recommended_dps(level), 1.0)
        target_time = balance.level_spawn_time(level, economy) * target_clear_ratio(level_no, boss_level)
        level["difficulty_coef"] = round(
            float(level.get("difficulty_coef", 1.0)) * target_time / max(current_time, 0.001),
            4,
        )

    # Boss and non-boss levels are separate pacing streams. Keep each stream
    # gently increasing without erasing the intended post-boss breathing room.
    previous_hp: dict[bool, float | None] = {False: None, True: None}
    for level in result:
        boss_level = balance.is_boss_level(level)
        current_hp = total_hp(level, zombies, bosses, economy)
        prior = previous_hp[boss_level]
        required_hp = current_hp if prior is None else prior * 1.005
        if current_hp < required_hp:
            level["difficulty_coef"] = round(
                float(level["difficulty_coef"]) * required_hp / max(current_hp, 0.001),
                4,
            )
            current_hp = total_hp(level, zombies, bosses, economy)
        previous_hp[boss_level] = current_hp

    # The level-99 boss rush must remain the campaign's absolute HP peak.
    previous_peak = max(total_hp(level, zombies, bosses, economy) for level in result[:-1])
    finale_hp = total_hp(result[-1], zombies, bosses, economy)
    if finale_hp < previous_peak * 1.03:
        result[-1]["difficulty_coef"] = round(
            float(result[-1]["difficulty_coef"]) * previous_peak * 1.03 / max(finale_hp, 0.001),
            4,
        )
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true", help="write calibrated coefficients to data/levels.json")
    args = parser.parse_args()

    levels: list[dict] = json.loads(LEVELS_PATH.read_text(encoding="utf-8"))
    zombies: dict = json.loads(balance.ZOMBIES_PATH.read_text(encoding="utf-8"))
    bosses: dict = json.loads(balance.BOSSES_PATH.read_text(encoding="utf-8"))
    economy: dict = json.loads(balance.ECONOMY_PATH.read_text(encoding="utf-8"))
    calibrated = recalibrate(levels, zombies, bosses, economy)
    clear_times = [
        total_hp(level, zombies, bosses, economy) / max(recommended_dps(level), 1.0)
        for level in calibrated
    ]
    changed = sum(
        abs(float(before.get("difficulty_coef", 1.0)) - float(after.get("difficulty_coef", 1.0))) > 0.00005
        for before, after in zip(levels, calibrated)
    )
    print(
        f"campaign smoothing: {changed} coefficients; "
        f"clear-time avg={sum(clear_times) / len(clear_times):.1f}s "
        f"min={min(clear_times):.1f}s max={max(clear_times):.1f}s"
    )
    if args.apply:
        LEVELS_PATH.write_text(
            json.dumps(calibrated, ensure_ascii=False, indent="\t") + "\n",
            encoding="utf-8",
        )
        print(f"updated {LEVELS_PATH.relative_to(ROOT)}")
    else:
        print("dry run only; pass --apply to write")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
