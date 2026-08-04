#!/usr/bin/env python3
"""design/28:校验 levels.json 的 clear_requirement 与模型推导一致(防改波次忘重跑生成器)。"""
from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import power_ruler_model as prm  # noqa: E402


def main() -> int:
    spec = importlib.util.spec_from_file_location("simulate_balance", ROOT / "tools" / "simulate_balance.py")
    sim = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(sim)

    levels = prm.load_table("levels")
    zombies = prm.load_table("zombies")
    bosses = prm.load_table("bosses")
    economy = prm.load_table("economy")
    characters = prm.load_table("characters")
    weapons = prm.load_table("weapons")
    chips = prm.load_table("chips")
    ctx = prm.FamilyContext(sim, characters, weapons, economy)

    errors = []
    for level in levels:
        stored = level.get("clear_requirement")
        if not isinstance(stored, dict):
            errors.append(f"{level['id']}: missing clear_requirement (run generate_clear_requirements.py)")
            continue
        derived = prm.solve_required_t(level, zombies, bosses, chips, characters, weapons, ctx)
        for key in ("min_output", "mob_hp_share", "boss_hp_share"):
            got = float(stored.get(key, -1.0))
            want = float(derived[key])
            if abs(got - want) > max(abs(want) * 0.005, 0.0005):
                errors.append(f"{level['id']}.{key}: stored {got} != derived {want}")
        if stored.get("boss_id") != derived["boss_id"]:
            errors.append(f"{level['id']}.boss_id: stored {stored.get('boss_id')} != derived {derived['boss_id']}")

    if errors:
        print("Clear requirement check failed:")
        for e in errors:
            print(f"- {e}")
        return 1
    print(f"Clear requirement check OK: {len(levels)} levels in sync with the ruler model")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
