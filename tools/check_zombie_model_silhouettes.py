#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / "assets" / "production"
SOURCE_REFS_ROOT = Path(os.environ["ZOMBIE_FIRE_SOURCE_REFS_ROOT"]).expanduser().resolve() if os.environ.get("ZOMBIE_FIRE_SOURCE_REFS_ROOT", "").strip() else ROOT
SOURCE_DIR = SOURCE_REFS_ROOT / "assets" / "production" / "source_refs" / "generated" / "zombie_model_redo_2026_07_26"
ANIM_DIR = PROD / "sprites" / "animations" / "zombies"
ZOMBIE_DIR = PROD / "sprites" / "zombies"

CHANGED = (
    "zombie_bomber",
    "zombie_spitter",
    "zombie_juggernaut",
    "zombie_necromancer",
    "zombie_charger",
    "zombie_regenerator",
    "zombie_splitter",
    "zombie_warden",
)

EXPECTED_ACTIONS = {
    "idle": 4,
    "walk": 6,
    "attack": 8,
    "special": 6,
    "hurt": 3,
    "death": 6,
}

RATIO_LIMITS = {
    "zombie_bomber": (0.64, 0.86),
    "zombie_spitter": (0.90, 1.18),
    "zombie_juggernaut": (1.25, 1.75),
    "zombie_necromancer": (0.42, 0.66),
    "zombie_charger": (0.94, 1.22),
    "zombie_regenerator": (0.50, 0.72),
    "zombie_splitter": (1.50, 1.95),
    "zombie_warden": (0.65, 0.86),
}


def fail(message: str) -> None:
    raise SystemExit(f"Zombie model silhouette check failed: {message}")


def load_rgba(path: Path) -> Image.Image:
    if not path.exists():
        try:
            display_path = path.relative_to(ROOT)
        except ValueError:
            display_path = path
        fail(f"missing {display_path}")
    return Image.open(path).convert("RGBA")


def alpha_bbox(image: Image.Image, label: str) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        fail(f"{label} has no visible pixels")
    return bbox


def silhouette_mask(path: Path) -> np.ndarray:
    alpha = load_rgba(path).getchannel("A").resize((128, 128), Image.Resampling.LANCZOS)
    return np.asarray(alpha) > 32


def silhouette_iou(left: np.ndarray, right: np.ndarray) -> float:
    union = np.logical_or(left, right).sum()
    if union <= 0:
        return 0.0
    return float(np.logical_and(left, right).sum() / union)


def main() -> int:
    zombies = json.loads((ROOT / "data" / "zombies.json").read_text(encoding="utf-8"))
    all_ids = tuple(zombies.keys())
    if len(all_ids) != 20:
        fail(f"expected 20 ordinary zombies, found {len(all_ids)}")

    manifest_path = SOURCE_DIR / "zombie_model_redo_manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if tuple(manifest.get("changed_zombies", [])) != CHANGED:
        fail("generated manifest changed_zombies drifted")
    prompts = manifest.get("prompts", {})
    if set(prompts) != set(CHANGED):
        fail("generated prompt provenance is incomplete")

    masks: dict[str, np.ndarray] = {}
    frame_count = 0
    for zombie_id in all_ids:
        walk_path = ANIM_DIR / zombie_id / f"{zombie_id}_walk_01.png"
        masks[zombie_id] = silhouette_mask(walk_path)

    for zombie_id in CHANGED:
        expected_sprite = (
            f"res://assets/production/sprites/zombies/{zombie_id}_prototype.png"
        )
        if zombies[zombie_id].get("sprite") != expected_sprite:
            fail(f"{zombie_id} data sprite path changed")

        chroma = load_rgba(SOURCE_DIR / f"{zombie_id}_chroma.png")
        master = load_rgba(SOURCE_DIR / f"{zombie_id}_master.png")
        before = load_rgba(SOURCE_DIR / "before" / f"{zombie_id}_prototype.png")
        prototype = load_rgba(ZOMBIE_DIR / f"{zombie_id}_prototype.png")
        portrait = load_rgba(ZOMBIE_DIR / f"{zombie_id}_portrait.png")
        icon = load_rgba(ZOMBIE_DIR / f"{zombie_id}_icon.png")
        if chroma.size[0] < 1024 or chroma.size[1] < 1024:
            fail(f"{zombie_id} chroma source is below 1024px")
        if prototype.size != (1024, 1536):
            fail(f"{zombie_id} prototype is {prototype.size}, expected 1024x1536")
        if portrait.size != (720, 1080):
            fail(f"{zombie_id} portrait is {portrait.size}, expected 720x1080")
        if icon.size != (256, 256):
            fail(f"{zombie_id} icon is {icon.size}, expected 256x256")
        corners = (
            master.getchannel("A").getpixel((0, 0)),
            master.getchannel("A").getpixel((master.width - 1, 0)),
            master.getchannel("A").getpixel((0, master.height - 1)),
            master.getchannel("A").getpixel((master.width - 1, master.height - 1)),
        )
        if any(corners):
            fail(f"{zombie_id} master has opaque corners after chroma removal")
        if hashlib.sha256(before.tobytes()).digest() == hashlib.sha256(prototype.tobytes()).digest():
            fail(f"{zombie_id} prototype did not change")

        animation_path = ANIM_DIR / zombie_id / f"{zombie_id}_animation.json"
        animation = json.loads(animation_path.read_text(encoding="utf-8"))
        actions = animation.get("actions", {})
        if set(actions) != set(EXPECTED_ACTIONS):
            fail(f"{zombie_id} animation actions are incomplete")
        for action, expected_count in EXPECTED_ACTIONS.items():
            frames = actions[action].get("frames", [])
            if len(frames) != expected_count:
                fail(
                    f"{zombie_id}/{action} has {len(frames)} frames, "
                    f"expected {expected_count}"
                )
            unique_hashes: set[str] = set()
            for rel_path in frames:
                path = PROD / rel_path
                frame = load_rgba(path)
                if frame.size != (512, 512):
                    fail(f"{rel_path} is {frame.size}, expected 512x512")
                bbox = alpha_bbox(frame, rel_path)
                margin = min(
                    bbox[0],
                    bbox[1],
                    frame.width - bbox[2],
                    frame.height - bbox[3],
                )
                if margin < 6:
                    fail(f"{rel_path} has only {margin}px transparent safety margin")
                unique_hashes.add(hashlib.sha256(frame.tobytes()).hexdigest())
                frame_count += 1
            if len(unique_hashes) < max(2, expected_count - 2):
                fail(f"{zombie_id}/{action} animation has insufficient frame variation")

        walk = load_rgba(ANIM_DIR / zombie_id / f"{zombie_id}_walk_01.png")
        bbox = alpha_bbox(walk, zombie_id)
        ratio = (bbox[2] - bbox[0]) / max(1, bbox[3] - bbox[1])
        low, high = RATIO_LIMITS[zombie_id]
        if not low <= ratio <= high:
            fail(
                f"{zombie_id} silhouette ratio {ratio:.3f} outside "
                f"authored range {low:.2f}-{high:.2f}"
            )

        closest_id = ""
        closest_iou = 0.0
        for other_id, other_mask in masks.items():
            if other_id == zombie_id:
                continue
            overlap = silhouette_iou(masks[zombie_id], other_mask)
            if overlap > closest_iou:
                closest_iou = overlap
                closest_id = other_id
        if closest_iou >= 0.76:
            fail(
                f"{zombie_id} remains too similar to {closest_id} "
                f"(silhouette IoU {closest_iou:.3f})"
            )

    print(
        "Zombie model silhouette check passed: "
        f"{len(CHANGED)} redesigned families, {frame_count} animation frames, "
        "phone-scale silhouette separation guarded"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
