#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


COMMANDS = [
    ["python3", "tools/validate_asset_pack.py"],
    ["python3", "tools/validate_data.py"],
    ["python3", "tools/check_res_refs.py"],
    ["python3", "tools/check_level_pressure.py"],
    ["python3", "tools/check_balance_profile.py"],
    ["python3", "tools/check_economy_loop.py"],
    ["python3", "tools/check_hardcoded_colors.py"],
    ["python3", "tools/check_contrast.py"],
    ["python3", "tools/check_visual_assets.py"],
    ["python3", "tools/check_gameplay_polish.py"],
    ["python3", "tools/check_app_store_assets.py"],
    ["python3", "tools/check_release_strings.py"],
    ["python3", "tools/simulate_card_director.py"],
    ["godot", "--headless", "--path", ".", "--quit"],
    ["godot", "--headless", "--path", ".", "--script", "res://tools/_battle_boot_probe.gd"],
    ["godot", "--headless", "--path", ".", "--script", "res://tools/m1_smoke_test.gd"],
    ["python3", "tools/check_visual_screens.py"],
]


def main() -> int:
    for command in COMMANDS:
        print(f"$ {' '.join(command)}", flush=True)
        result = subprocess.run(command, cwd=ROOT)
        if result.returncode != 0:
            print(f"Release candidate check failed: {' '.join(command)}", file=sys.stderr)
            return result.returncode
    print("Release candidate check OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
