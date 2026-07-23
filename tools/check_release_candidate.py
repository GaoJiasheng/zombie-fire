#!/usr/bin/env python3
from __future__ import annotations

import os
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

from check_godot_log import find_godot_log_issues

ROOT = Path(__file__).resolve().parents[1]


def godot_executable() -> str:
    configured = os.environ.get("GODOT_BIN")
    if configured:
        return configured
    discovered = shutil.which("godot")
    if discovered:
        return discovered
    homebrew = Path("/opt/homebrew/bin/godot")
    if homebrew.is_file():
        return str(homebrew)
    return "godot"


GODOT = godot_executable()


@dataclass(frozen=True)
class Check:
    command: tuple[str, ...]
    required_output: str | None = None


CHECKS = [
    Check(("python3", "tools/validate_asset_pack.py")),
    Check(("python3", "tools/check_font_license.py")),
    Check(("python3", "tools/validate_data.py")),
    Check(("python3", "tools/check_res_refs.py")),
    Check(("python3", "tools/sync_release_export_excludes.py")),
    Check(("python3", "tools/check_release_package.py", "--preset-only")),
    Check(("python3", "tools/check_level_pressure.py")),
    Check(("python3", "tools/check_balance_profile.py")),
    Check(("python3", "tools/simulate_balance.py")),
    Check(("python3", "tools/check_endgame_balance.py")),
    Check(("python3", "tools/check_economy_loop.py")),
    Check(("python3", "tools/check_hardcoded_colors.py")),
    Check(("python3", "tools/check_contrast.py")),
    Check(("python3", "tools/check_runtime_ui_primitives.py")),
    Check(("python3", "tools/check_visual_assets.py")),
    Check(("python3", "tools/check_attack_animation_motion.py")),
    Check(("python3", "tools/check_gameplay_polish.py")),
    Check(("python3", "tools/check_audio_overlap.py")),
    Check(("python3", "tools/check_weapon_sfx_quality.py")),
    Check(("python3", "tools/check_hit_sfx_quality.py")),
    Check(("python3", "tools/check_active_skill_media.py")),
    Check(("python3", "tools/check_tall_battle_layout.py")),
    Check(("python3", "tools/check_battle_line_alignment.py")),
    Check(("python3", "tools/check_battle_hud_overlap.py")),
    Check(("python3", "tools/check_app_store_assets.py")),
    Check(("python3", "tools/check_release_strings.py")),
    Check(("python3", "tools/simulate_card_director.py")),
    Check((GODOT, "--headless", "--path", ".", "--quit")),
    Check(
        (GODOT, "--headless", "--path", ".", "--script", "res://tools/_battle_boot_probe.gd"),
        required_output="BATTLE_BOOT_PROBE_OK",
    ),
    Check(
        (GODOT, "--headless", "--path", ".", "--script", "res://tools/save_integrity_test.gd"),
        required_output="SAVE INTEGRITY TEST PASSED",
    ),
    Check((GODOT, "--headless", "--path", ".", "--script", "res://tools/m1_smoke_test.gd")),
    Check(("python3", "tools/check_visual_screens.py")),
]


def run_check(check: Check) -> int:
    command = check.command
    print(f"$ {' '.join(command)}", flush=True)
    try:
        process = subprocess.Popen(
            command,
            cwd=ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
            bufsize=1,
        )
    except OSError as exc:
        print(f"Release candidate check could not start: {' '.join(command)}: {exc}", file=sys.stderr)
        return 1

    output_parts: list[str] = []
    assert process.stdout is not None
    for line in process.stdout:
        print(line, end="", flush=True)
        output_parts.append(line)
    return_code = process.wait()
    output = "".join(output_parts)

    if return_code != 0:
        print(f"Release candidate check failed: {' '.join(command)}", file=sys.stderr)
        return return_code
    if Path(command[0]).name == "godot":
        issues = find_godot_log_issues(output)
        if issues:
            print(f"Release candidate Godot log failed: {' '.join(command)}", file=sys.stderr)
            for issue in issues:
                print(f"- {issue}", file=sys.stderr)
            return 1
    if check.required_output and check.required_output not in output:
        print(
            f"Release candidate check did not prove success: {' '.join(command)} "
            f"(missing marker {check.required_output})",
            file=sys.stderr,
        )
        return 1
    return 0


def main() -> int:
    for check in CHECKS:
        return_code = run_check(check)
        if return_code != 0:
            return return_code
    print("Release candidate check OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
