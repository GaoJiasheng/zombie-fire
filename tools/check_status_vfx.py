#!/usr/bin/env python3
from __future__ import annotations

import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIG_PATH = ROOT / "data/status_vfx.json"
SEQUENCE_ROOT = ROOT / "assets/production/sprites/vfx_sequences"
REQUIRED = ("fire", "ice", "glacier", "poison", "lightning")


def rgb(hex_value: str) -> tuple[int, int, int]:
    value = hex_value.strip().removeprefix("#")
    return tuple(int(value[index : index + 2], 16) for index in (0, 2, 4))


def color_distance(a: tuple[int, int, int], b: tuple[int, int, int]) -> float:
    return math.sqrt(sum((x - y) ** 2 for x, y in zip(a, b)))


def main() -> int:
    errors: list[str] = []
    try:
        config = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"Status VFX check failed to load config: {exc}")
        return 1

    global_row = config.get("global", {})
    if float(global_row.get("fade_out", 0.0)) < 0.2:
        errors.append("status VFX fade_out must preserve at least a 0.2s readable release")
    if int(global_row.get("condensed_density_max", 0)) <= int(
        global_row.get("full_density_max", 0)
    ):
        errors.append("status VFX density thresholds are not ordered")

    sequences: dict[str, str] = {}
    colors: dict[str, tuple[int, int, int]] = {}
    total_frames = 0
    for status_id in REQUIRED:
        row = config.get(status_id)
        if not isinstance(row, dict):
            errors.append(f"missing status VFX row: {status_id}")
            continue
        sequence_id = str(row.get("sequence", "")).strip()
        sequence_path = SEQUENCE_ROOT / sequence_id / f"{sequence_id}_sequence.json"
        if not sequence_path.exists():
            errors.append(f"{status_id} missing sequence JSON: {sequence_path}")
        else:
            try:
                sequence = json.loads(sequence_path.read_text(encoding="utf-8"))
            except Exception as exc:
                errors.append(f"{status_id} invalid sequence JSON: {exc}")
                sequence = {}
            frames = sequence.get("frames", [])
            if len(frames) < 6:
                errors.append(f"{status_id} persistent sequence needs at least 6 frames")
            for frame in frames:
                frame_path = ROOT / "assets/production" / str(frame)
                if not frame_path.exists():
                    errors.append(f"{status_id} missing sequence frame: {frame}")
            total_frames += len(frames)
        sequences[status_id] = sequence_id
        try:
            colors[status_id] = rgb(str(row.get("ground_tint", "")))
        except Exception:
            errors.append(f"{status_id} invalid ground_tint")
        if float(row.get("boss_scale", 0.0)) <= float(row.get("normal_scale", 0.0)):
            errors.append(f"{status_id} boss_scale must exceed normal_scale")
        if float(row.get("alpha", 0.0)) > 0.95:
            errors.append(f"{status_id} body alpha is too high for multi-status additive stacking")
        if float(row.get("loop_gap", 0.0)) > 0.25:
            errors.append(f"{status_id} loop gap is long enough to look like a missing state")

    if len(set(sequences.values())) != len(REQUIRED):
        errors.append("persistent status states must use distinct authored sequence silhouettes")
    primary_statuses = ("fire", "ice", "poison", "lightning")
    for index, left in enumerate(primary_statuses):
        for right in primary_statuses[index + 1 :]:
            if left in colors and right in colors:
                if color_distance(colors[left], colors[right]) < 70.0:
                    errors.append(
                        f"{left}/{right} status ground colors are not semantically distinct"
                    )

    controller = (
        ROOT / "gameplay/vfx/status_vfx_controller.gd"
    ).read_text(encoding="utf-8")
    enemy = (ROOT / "gameplay/enemy/enemy.gd").read_text(encoding="utf-8")
    battle = (ROOT / "gameplay/battle/battle.gd").read_text(encoding="utf-8")
    for needle in (
        "sync_statuses",
        "stack_alpha_two",
        "stack_alpha_many",
        "set_density_lod",
        "presentation_allowed",
        "fade_out",
    ):
        if needle not in controller:
            errors.append(f"status VFX controller missing contract: {needle}")
    for needle in (
        "StatusVfxController",
        '"fire": _burn_time',
        '"poison": _poison_time',
        '"lightning": _shock_time',
        "set_combat_effect_density",
    ):
        if needle not in enemy:
            errors.append(f"enemy missing status VFX integration: {needle}")
    if "StatusAura" in enemy:
        errors.append("legacy single recolored StatusAura must not return")
    if 'lod = "full" if priority.has(enemy) else "minimal"' not in battle:
        errors.append("battle missing high-density semantic status VFX LOD")

    if errors:
        print("Status VFX check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(
        "Status VFX check passed: "
        f"{len(REQUIRED)} independent states, {total_frames} authored frames, "
        "stack brightness + dense-wave LOD guarded"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
