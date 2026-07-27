#!/usr/bin/env python3
"""Acceptance gate for the 20 ordinary-zombie attack animation contracts."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ANIMATION_ROOT = ROOT / "assets/production/sprites/animations/zombies"


def resolve_frame_ref(reference: object) -> Path:
    value = str(reference)
    if value.startswith("res://"):
        return ROOT / value.removeprefix("res://")
    if value.startswith("assets/production/"):
        return ROOT / value
    return ROOT / "assets/production" / value


def alpha_mask(path: Path) -> np.ndarray:
    with Image.open(path) as source:
        image = source.convert("RGBA")
        if image.size != (512, 512):
            raise ValueError(f"{path.relative_to(ROOT)} must be 512x512, got {image.size}")
        return np.asarray(image)[:, :, 3] > 20


def mask_iou(left: np.ndarray, right: np.ndarray) -> float:
    union = np.logical_or(left, right).sum()
    return float(np.logical_and(left, right).sum()) / float(max(1, union))


def largest_component_ratio(mask: np.ndarray) -> float:
    """Return the largest 8-connected component ratio without an OpenCV dependency."""
    remaining = mask.copy()
    total = int(remaining.sum())
    largest = 0
    height, width = remaining.shape

    while remaining.any():
        seed_y, seed_x = np.argwhere(remaining)[0]
        remaining[seed_y, seed_x] = False
        stack = [(int(seed_y), int(seed_x))]
        size = 0
        while stack:
            y, x = stack.pop()
            size += 1
            y_min = max(0, y - 1)
            y_max = min(height, y + 2)
            x_min = max(0, x - 1)
            x_max = min(width, x + 2)
            neighbours = np.argwhere(remaining[y_min:y_max, x_min:x_max])
            for local_y, local_x in neighbours:
                next_y = y_min + int(local_y)
                next_x = x_min + int(local_x)
                remaining[next_y, next_x] = False
                stack.append((next_y, next_x))
        largest = max(largest, size)

    return float(largest) / float(max(1, total))


def main() -> int:
    zombies = json.loads((ROOT / "data/zombies.json").read_text(encoding="utf-8"))
    errors: list[str] = []
    checked_frames = 0
    weakest_pose_delta = (1.0, "")

    for entity_id, row in zombies.items():
        directory = ANIMATION_ROOT / entity_id
        manifest_path = directory / f"{entity_id}_animation.json"
        if not manifest_path.exists():
            errors.append(f"{entity_id}: animation manifest missing")
            continue
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        attack_row = manifest.get("actions", {}).get("attack", {})
        frame_refs = attack_row.get("frames", [])
        if len(frame_refs) != 8:
            errors.append(f"{entity_id}: manifest must expose exactly 8 attack frames")
            continue
        profile = row.get("attack_animation", {})
        if int(profile.get("contact_frame", 0)) != 4:
            errors.append(f"{entity_id}: contact contract must point to frame 4")

        paths = [resolve_frame_ref(ref) for ref in frame_refs]
        if any(not path.exists() for path in paths):
            errors.append(f"{entity_id}: referenced attack frame missing")
            continue
        if any(
            path.name != f"{entity_id}_attack_{index:02d}.png"
            for index, path in enumerate(paths, start=1)
        ):
            errors.append(f"{entity_id}: attack frame order/path is not canonical")

        masks: list[np.ndarray] = []
        hashes: set[str] = set()
        for path in paths:
            try:
                mask = alpha_mask(path)
            except ValueError as exc:
                errors.append(str(exc))
                continue
            masks.append(mask)
            if int(mask.sum()) < 10_000:
                errors.append(f"{entity_id}: {path.name} silhouette is too sparse")
            ys, xs = np.where(mask)
            if len(xs) and (
                int(xs.min()) <= 0
                or int(ys.min()) <= 0
                or int(xs.max()) >= 511
                or int(ys.max()) >= 511
            ):
                errors.append(f"{entity_id}: {path.name} touches the canvas edge")
            if largest_component_ratio(mask) < 0.985:
                errors.append(
                    f"{entity_id}: {path.name} has detached/cross-cell fragments"
                )
            hashes.add(hashlib.sha256(path.read_bytes()).hexdigest())
            checked_frames += 1
        if len(hashes) < 8:
            errors.append(f"{entity_id}: all 8 runtime frames must be distinct")
        if len(masks) == 8:
            anticipation_contact_iou = mask_iou(masks[0], masks[3])
            contact_recovery_iou = mask_iou(masks[3], masks[5])
            strongest = max(anticipation_contact_iou, contact_recovery_iou)
            if strongest < weakest_pose_delta[0]:
                weakest_pose_delta = (strongest, entity_id)
            if anticipation_contact_iou >= 0.84:
                errors.append(
                    f"{entity_id}: anticipation/contact poses are too similar "
                    f"(IoU {anticipation_contact_iou:.3f})"
                )
            if contact_recovery_iou >= 0.84:
                errors.append(
                    f"{entity_id}: contact/recovery poses are too similar "
                    f"(IoU {contact_recovery_iou:.3f})"
                )

    enemy_source = (ROOT / "gameplay/enemy/enemy.gd").read_text(encoding="utf-8")
    if "_process_normal_base_attack_sequence" not in enemy_source:
        errors.append("runtime contact-timed normal attack state machine missing")
    if '_load_frame_set(base, "attack", 8)' not in enemy_source:
        errors.append("runtime does not load all 8 ordinary-zombie attack frames")
    if "_advance_profiled_attack_frames" not in enemy_source:
        errors.append("runtime does not bind frame playback to contact_ratio")
    battle_source = (ROOT / "gameplay/battle/battle.gd").read_text(encoding="utf-8")
    for function_name in (
        "_process_summoner",
        "_process_ranged_pressure",
        "_process_regen_feedback",
    ):
        start = battle_source.find(f"func {function_name}")
        end = battle_source.find("\nfunc ", start + 1)
        block = battle_source[start:end]
        if "play_special" not in block:
            errors.append(f"{function_name}: special pose hook missing")

    if errors:
        print("Zombie attack animation check failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(
        "Zombie attack animation OK: "
        f"{len(zombies)} identities, {checked_frames} frames, "
        f"8-frame contact-timed state machine; "
        f"tightest key-pose IoU {weakest_pose_delta[1]} "
        f"{weakest_pose_delta[0]:.3f}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
