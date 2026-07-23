#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import os
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "tmp" / "app_store_current_iphone_2026_07_14"
GODOT = shutil.which("godot") or "/opt/homebrew/bin/godot"


def table_ids(filename: str) -> list[str]:
    return list(json.loads((ROOT / "data" / filename).read_text(encoding="utf-8")).keys())


def showcase_save() -> dict:
    completed = {f"level_{index:03d}": 3 for index in range(1, 76)}
    challenges = {f"level_{index:03d}": 3 for index in range(1, 51)}
    skill_levels = {skill_id: 3 for skill_id in table_ids("skills.json")}
    return {
        "player": {"gold": 184321, "xp": 32752, "star": 171},
        "levels_progress": completed,
        "challenge_progress": challenges,
        "skill_base_levels": skill_levels,
        "sig_skill_levels": {"blaze": 4},
        "endless_best_loops": 4,
        "unlocks": {
            "levels": [f"level_{index:03d}" for index in range(1, 77)],
            "characters": table_ids("characters.json"),
            "weapons": table_ids("weapons.json"),
            "armors": table_ids("armors.json"),
            "chips": table_ids("chips.json"),
            "pets": table_ids("pets.json"),
        },
        "equipment": {
            "blaze": 40,
            "weapon_flamethrower": 41,
            "armor_thermal": 20,
            "chip_attack": 18,
            "pet_fire_imp": 18,
            "selected_character": "blaze",
            "selected_weapon": "weapon_flamethrower",
            "selected_armor": "armor_thermal",
            "selected_chip": "chip_attack",
            "selected_pet": "pet_fire_imp",
        },
    }


def capture(route: str, payload: dict, filename: str) -> None:
    out_path = RAW_DIR / filename
    command = [
        GODOT,
        "--path",
        ".",
        "--script",
        "res://tools/_shot.gd",
        "--",
        route,
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")),
        str(out_path),
    ]
    env = os.environ.copy()
    env["ZOMBIE_FIRE_UI_AUDIT"] = "1"
    subprocess.run(command, cwd=ROOT, env=env, check=True, timeout=90)


def load_store_generator():
    module_path = ROOT / "tools" / "generate_final_p0_assets.py"
    spec = importlib.util.spec_from_file_location("generate_final_p0_assets", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"unable to load {module_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> int:
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    save = showcase_save()
    base = {"viewport_size": [1080, 2340], "save_override": save}
    capture(
        "battle",
        base
        | {
            "level_id": "level_045",
            "debug_store_combat": True,
            "warmup_frames": 32,
        },
        "battle.png",
    )
    capture("map", base, "map.png")
    capture(
        "battle",
        base | {"level_id": "level_045", "card_offer": True},
        "skills.png",
    )
    capture("loadout", base | {"level_id": "level_045"}, "loadout.png")
    capture(
        "battle",
        base
        | {
            "level_id": "level_050",
            "debug_spawn_boss": "boss_inferno_maw",
            "debug_clean_boss_stage": True,
            "warmup_frames": 90,
        },
        "05_boss.png",
    )

    generator = load_store_generator()
    generator.ensure_dirs()
    generator.generate_store_screens(RAW_DIR)
    generator.make_preview_video(RAW_DIR)
    print(f"Refreshed current iPhone store captures from {RAW_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
