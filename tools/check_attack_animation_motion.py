#!/usr/bin/env python3
"""Validate temporal motion in every rendered character/weapon attack strip."""
from __future__ import annotations

import json
import os
import re
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]
SOURCE_REFS_ROOT = Path(os.environ["ZOMBIE_FIRE_SOURCE_REFS_ROOT"]).expanduser().resolve() if os.environ.get("ZOMBIE_FIRE_SOURCE_REFS_ROOT", "").strip() else ROOT
COMBO_ROOT = ROOT / "assets" / "production" / "sprites" / "animations" / "character_weapon_combos"
BATTLE_SCRIPT = ROOT / "gameplay" / "battle" / "battle.gd"
MANIFEST_PATH = (
    SOURCE_REFS_ROOT
    / "assets"
    / "production"
    / "source_refs"
    / "generated"
    / "character_shooting_animation_redesign_2026_07_26"
    / "character_shooting_animation_manifest.json"
)
ACTIONS = ("attack", "attack_left", "attack_right")
FRAME_COUNT = 8
PIXEL_THRESHOLD = 18
MIN_ADJACENT_CHANGED_PIXELS = 3_500
MIN_IGNITION_TO_RECOIL_PIXELS = 32_000
MIN_BACKWARD_RECOIL_PIXELS = 5.0
MAX_SEQUENCE_ALPHA_AREA_RATIO = 1.10
SAFE_MARGIN = 3
RUNTIME_SPRITE_SCALE = 0.512
MAX_MUZZLE_TO_ALPHA_DISTANCE = 4.0
AIM_VECTORS = {
    "attack_left": (-0.54, -0.84),
    "attack": (0.30, -0.954),
    "attack_right": (0.56, -0.83),
}
TRUE_GRIP_PATTERN_KEY = {
    "attack_left": "left_pattern",
    "attack": "center_pattern",
    "attack_right": "right_pattern",
}


def changed_pixels(left: Image.Image, right: Image.Image) -> int:
    difference = ImageChops.difference(left, right)
    return sum(1 for pixel in difference.getdata() if max(pixel) > PIXEL_THRESHOLD)


def alpha_metrics(image: Image.Image) -> tuple[float, float, int, tuple[int, int, int, int] | None]:
    alpha = np.asarray(image.getchannel("A"))
    ys, xs = np.where(alpha > 16)
    if len(xs) == 0:
        return 0.0, 0.0, 0, None
    return float(xs.mean()), float(ys.mean()), int(len(xs)), image.getchannel("A").getbbox()


def check_premium_runtime_motion(errors: list[str], weapons: dict) -> None:
    """Guard the rig-driven temporal motion used by the three true-grip masters."""
    text = BATTLE_SCRIPT.read_text(encoding="utf-8")
    curve_match = re.search(
        r"CHARACTER_WEAPON_ACTION_RECOIL_CURVE\s*:=\s*\[([^\]]+)\]", text
    )
    if curve_match is None:
        errors.append("premium runtime recoil curve is missing")
    else:
        try:
            curve = [
                float(value.strip())
                for value in curve_match.group(1).split(",")
                if value.strip()
            ]
        except ValueError:
            curve = []
        if len(curve) != FRAME_COUNT:
            errors.append(f"premium runtime recoil curve must have {FRAME_COUNT} beats")
        elif min(curve) > -0.30 or max(curve) < 0.95:
            errors.append(
                f"premium runtime recoil curve lacks anticipation/peak motion: {curve}"
            )
    for weapon_id, weapon in weapons.items():
        presentation = weapon.get("presentation", {})
        if not presentation.get("true_grip"):
            continue
        for key, minimum in (("recoil_accent", 0.40), ("recoil_twist", 1.0)):
            value = float(presentation.get(key, 0.0))
            if value < minimum:
                errors.append(
                    f"{weapon_id}.presentation.{key} must remain >= {minimum:.2f}"
                )


def main() -> int:
    characters = json.loads((ROOT / "data" / "characters.json").read_text(encoding="utf-8"))
    weapons = json.loads((ROOT / "data" / "weapons.json").read_text(encoding="utf-8"))
    errors: list[str] = []
    if not MANIFEST_PATH.exists():
        print(f"Attack animation motion check failed:\n- missing semantic manifest: {MANIFEST_PATH}")
        return 1
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    if int(manifest.get("frame_count", 0)) != FRAME_COUNT:
        errors.append(f"semantic manifest frame_count must be {FRAME_COUNT}")
    if int(manifest.get("fire_frame", 0)) != 2:
        errors.append("semantic manifest must bind the real shot to F2 ignition")
    muzzle_offsets = manifest.get("corrected_muzzle_offsets", {})
    action_aim = {"attack_left": "left", "attack": "center", "attack_right": "right"}
    checked = 0
    weakest_motion: tuple[int, str] | None = None
    check_premium_runtime_motion(errors, weapons)

    for character_id in sorted(characters):
        asset_id = f"char_{character_id}"
        directory = COMBO_ROOT / asset_id
        for weapon_id in sorted(weapons):
            grip = weapons[weapon_id].get("presentation", {}).get("true_grip", {})
            if grip:
                direction_frames: dict[str, Image.Image] = {}
                root = ROOT / str(grip.get("root", "")).removeprefix("res://")
                for action in ACTIONS:
                    filename = str(grip.get(TRUE_GRIP_PATTERN_KEY[action], "")).replace(
                        "{character_id}", asset_id
                    )
                    path = root / filename
                    sequence_name = f"{asset_id}/{weapon_id}/{action}"
                    if not path.exists():
                        errors.append(
                            "missing premium true-grip master: "
                            f"{path.relative_to(ROOT)}"
                        )
                        continue
                    with Image.open(path) as source:
                        frame = source.convert("RGBA")
                    metric = alpha_metrics(frame)
                    bbox = metric[3]
                    if bbox is None:
                        errors.append(f"{sequence_name} true-grip master is empty")
                    else:
                        left, top, right, bottom = bbox
                        margin = min(
                            left,
                            top,
                            frame.width - right,
                            frame.height - bottom,
                        )
                        if margin < SAFE_MARGIN:
                            errors.append(
                                f"{sequence_name} violates {SAFE_MARGIN}px alpha "
                                f"safe margin: bbox={bbox}"
                            )
                    direction_frames[action] = frame
                    checked += 1
                if len(direction_frames) == len(ACTIONS):
                    for first, second in (
                        ("attack_left", "attack"),
                        ("attack", "attack_right"),
                    ):
                        changed = changed_pixels(
                            direction_frames[first], direction_frames[second]
                        )
                        sequence_name = (
                            f"{asset_id}/{weapon_id}/{first}->{second}"
                        )
                        if weakest_motion is None or changed < weakest_motion[0]:
                            weakest_motion = (changed, sequence_name)
                        if changed < MIN_ADJACENT_CHANGED_PIXELS:
                            errors.append(
                                f"{sequence_name} directional masters are too "
                                f"similar: {changed} changed pixels"
                            )
                # One approved raster master per direction preserves exact
                # two-hand contact. Temporal anticipation/recoil/recovery is
                # applied by the guarded eight-beat runtime rig above.
                continue
            for action in ACTIONS:
                paths = [
                    directory / f"{asset_id}_{weapon_id}_{action}_{index:02d}.png"
                    for index in range(1, FRAME_COUNT + 1)
                ]
                if any(not path.exists() for path in paths):
                    missing = [str(path.relative_to(ROOT)) for path in paths if not path.exists()]
                    errors.append(f"missing attack strip frames: {', '.join(missing)}")
                    continue
                frames: list[Image.Image] = []
                for path in paths:
                    with Image.open(path) as source:
                        frames.append(source.convert("RGBA"))
                adjacent = [changed_pixels(left, right) for left, right in zip(frames, frames[1:])]
                sequence_name = f"{asset_id}/{weapon_id}/{action}"
                minimum = min(adjacent)
                if weakest_motion is None or minimum < weakest_motion[0]:
                    weakest_motion = (minimum, sequence_name)
                if minimum < MIN_ADJACENT_CHANGED_PIXELS:
                    errors.append(f"{sequence_name} has a near-static adjacent frame: {minimum} changed pixels")
                ignition_to_peak = adjacent[1]
                if ignition_to_peak < MIN_IGNITION_TO_RECOIL_PIXELS:
                    errors.append(
                        f"{sequence_name} lacks a readable ignition-to-recoil change: "
                        f"{ignition_to_peak} changed pixels"
                    )
                metrics = [alpha_metrics(frame) for frame in frames]
                areas = [metric[2] for metric in metrics]
                if min(areas) <= 0:
                    errors.append(f"{sequence_name} contains an empty frame")
                elif max(areas) / min(areas) > MAX_SEQUENCE_ALPHA_AREA_RATIO:
                    errors.append(
                        f"{sequence_name} alpha area drifts too much during recoil: "
                        f"{max(areas) / min(areas):.3f}x"
                    )
                ignition_x, ignition_y = metrics[1][0], metrics[1][1]
                recoil_x, recoil_y = metrics[2][0], metrics[2][1]
                aim_x, aim_y = AIM_VECTORS[action]
                backward_projection = (
                    (recoil_x - ignition_x) * -aim_x
                    + (recoil_y - ignition_y) * -aim_y
                )
                if backward_projection < MIN_BACKWARD_RECOIL_PIXELS:
                    errors.append(
                        f"{sequence_name} recoil peak moves in the wrong/weak direction: "
                        f"{backward_projection:.2f}px"
                    )
                for index, metric in enumerate(metrics, start=1):
                    bbox = metric[3]
                    if bbox is None:
                        continue
                    left, top, right, bottom = bbox
                    margin = min(left, top, frames[index - 1].width - right, frames[index - 1].height - bottom)
                    if margin < SAFE_MARGIN:
                        errors.append(
                            f"{sequence_name} frame {index} violates {SAFE_MARGIN}px alpha safe margin: "
                            f"bbox={bbox}"
                        )
                aim_name = action_aim[action]
                muzzle = muzzle_offsets.get(aim_name, {}).get(f"{asset_id}/{weapon_id}")
                if not isinstance(muzzle, list) or len(muzzle) < 2:
                    errors.append(f"{sequence_name} is missing its {aim_name} ignition muzzle coordinate")
                else:
                    muzzle_x = frames[1].width * 0.5 + float(muzzle[0]) / RUNTIME_SPRITE_SCALE
                    muzzle_y = frames[1].height * 0.5 + float(muzzle[1]) / RUNTIME_SPRITE_SCALE
                    ignition_alpha = np.asarray(frames[1].getchannel("A"))
                    opaque_y, opaque_x = np.where(ignition_alpha > 16)
                    nearest = float(
                        np.sqrt((opaque_x - muzzle_x) ** 2 + (opaque_y - muzzle_y) ** 2).min()
                    )
                    if nearest > MAX_MUZZLE_TO_ALPHA_DISTANCE:
                        errors.append(
                            f"{sequence_name} ignition muzzle is detached from the barrel: "
                            f"{nearest:.2f}px"
                        )
                    if aim_name == "left" and muzzle_x >= frames[1].width * 0.33:
                        errors.append(f"{sequence_name} visually labeled left but its muzzle is not on the left")
                    elif aim_name == "center" and not (
                        frames[1].width * 0.52 <= muzzle_x <= frames[1].width * 0.76
                    ):
                        errors.append(f"{sequence_name} center muzzle falls outside the authored center corridor")
                    elif aim_name == "right" and muzzle_x <= frames[1].width * 0.74:
                        errors.append(f"{sequence_name} visually labeled right but its muzzle is not on the right")
                checked += 1

    if errors:
        print("Attack animation motion check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    weakest_text = "none" if weakest_motion is None else f"{weakest_motion[1]} ({weakest_motion[0]} px)"
    print(f"Attack animation motion OK: {checked} sequences; weakest adjacent motion {weakest_text}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
