#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(name: str):
    return json.loads((ROOT / "data" / f"{name}.json").read_text(encoding="utf-8"))


def main() -> int:
    zombies = load("zombies")
    bosses = load("bosses")
    levels = load("levels")
    errors: list[str] = []
    print("Level pressure estimate")
    for level in levels:
        pressure = 0.0
        duration = 0.0
        boss_count = 0
        for wave in level.get("waves", []):
            for group in wave.get("spawns", []):
                row = zombies[group["type"]]
                count = int(group.get("count", 1))
                pressure += count * float(row.get("hp_coef", 1.0)) * float(row.get("bd_coef", 1.0))
                duration += count * float(group.get("interval", 0.8))
            if "boss" in wave:
                boss_count += 1
                pressure += float(bosses[wave["boss"]].get("hp_coef", 1.0)) * 8.0
            for group in wave.get("support", []):
                row = zombies[group["type"]]
                count = int(group.get("count", 1))
                pressure += count * float(row.get("hp_coef", 1.0)) * float(row.get("bd_coef", 1.0))
                duration += count * float(group.get("interval", 0.8))
        pressure *= float(level.get("difficulty_coef", 1.0))
        print(f"{level['id']}: pressure={pressure:.1f}, spawn_time={duration:.1f}s, boss={boss_count}")
        min_duration = 40.0 if boss_count else 36.0
        if level["id"] == "level_001":
            min_duration = 38.0
        if duration < min_duration:
            errors.append(f"{level['id']} spawn duration too short: {duration:.1f}s")
        if pressure <= 0.0:
            errors.append(f"{level['id']} pressure must be positive")
    if errors:
        print("Pressure check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
