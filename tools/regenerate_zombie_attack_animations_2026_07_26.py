#!/usr/bin/env python3
"""Build the 20-zombie attack animation set from approved three-pose renders.

The source sheet for every zombie contains three authored silhouettes:
anticipation, contact, and recovery.  This builder keeps those real poses intact,
normalises their scale/grounding, and derives eight deterministic runtime frames.
It intentionally does not manufacture attacks by warping an idle sprite.
"""

from __future__ import annotations

import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = (
    ROOT
    / "assets/production/source_refs/generated/"
    "zombie_attack_animation_redesign_2026_07_26/keyposes"
)
ANIMATION_ROOT = ROOT / "assets/production/sprites/animations/zombies"
AUDIT_PATH = (
    ROOT
    / "assets/production/source_refs/generated/"
    "zombie_attack_animation_redesign_2026_07_26/"
    "zombie_attack_animation_storyboard.png"
)

CANVAS = 512
GROUND_Y = 488
SIDE_MARGIN = 18
TOP_MARGIN = 18

# Runtime scale is shared, so these heights preserve the established size
# hierarchy while allowing an attacking silhouette to open wider than idle.
TARGET_HEIGHTS = {
    "zombie_shambler": 446,
    "zombie_runner": 444,
    "zombie_brute": 455,
    "zombie_bomber": 444,
    "zombie_screamer": 447,
    "zombie_spitter": 415,
    "zombie_crawler": 410,
    "zombie_armored": 451,
    "zombie_shielder": 449,
    "zombie_hopper": 430,
    "zombie_juggernaut": 390,
    "zombie_phantom": 454,
    "zombie_necromancer": 459,
    "zombie_toxic": 449,
    "zombie_charger": 416,
    "zombie_regenerator": 455,
    "zombie_splitter": 330,
    "zombie_warden": 457,
    "zombie_mutant": 449,
    "zombie_berserker": 454,
}


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("transparent key pose")
    return bbox


def keep_primary_component(image: Image.Image) -> Image.Image:
    """Drop small fragments that crossed a triptych divider from a neighbour."""
    rgba = np.array(image.convert("RGBA"))
    binary = (rgba[:, :, 3] > 20).astype(np.uint8)
    count, labels, stats, _ = cv2.connectedComponentsWithStats(binary, 8)
    if count <= 1:
        return image
    primary = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
    keep = labels == primary
    rgba[~keep] = 0
    return Image.fromarray(rgba)


def split_keyposes(sheet: Image.Image) -> list[Image.Image]:
    """Split a horizontal triptych without allowing neighbouring poses to leak."""
    sheet = sheet.convert("RGBA")
    width, height = sheet.size
    cuts = [round(width * i / 3.0) for i in range(4)]
    poses: list[Image.Image] = []
    for index in range(3):
        pose = sheet.crop((cuts[index], 0, cuts[index + 1], height))
        pose = keep_primary_component(pose)
        pose = pose.crop(alpha_bbox(pose))
        poses.append(pose)
    return poses


def normalise_poses(entity_id: str, poses: list[Image.Image]) -> list[Image.Image]:
    target_height = TARGET_HEIGHTS[entity_id]
    max_width = CANVAS - SIDE_MARGIN * 2
    scales = [
        min(target_height / pose.height, max_width / pose.width) for pose in poses
    ]
    # A common scale prevents a character from growing or shrinking between poses.
    scale = min(scales)
    output: list[Image.Image] = []
    for pose in poses:
        size = (
            max(1, round(pose.width * scale)),
            max(1, round(pose.height * scale)),
        )
        resized = pose.resize(size, Image.Resampling.LANCZOS)
        frame = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
        x = (CANVAS - resized.width) // 2
        y = min(GROUND_Y - resized.height, CANVAS - TOP_MARGIN - resized.height)
        y = max(TOP_MARGIN, y)
        frame.alpha_composite(resized, (x, y))
        output.append(frame)
    return output


def transform_pose(
    pose: Image.Image, scale: float = 1.0, dx: int = 0, dy: int = 0
) -> Image.Image:
    bbox = alpha_bbox(pose)
    cropped = pose.crop(bbox)
    size = (
        max(1, round(cropped.width * scale)),
        max(1, round(cropped.height * scale)),
    )
    resized = cropped.resize(size, Image.Resampling.LANCZOS)
    result = Image.new("RGBA", pose.size, (0, 0, 0, 0))
    anchor_x = (pose.width - resized.width) // 2 + dx
    anchor_y = GROUND_Y - resized.height + dy
    anchor_x = max(2, min(pose.width - resized.width - 2, anchor_x))
    anchor_y = max(2, min(pose.height - resized.height - 2, anchor_y))
    result.alpha_composite(resized, (anchor_x, anchor_y))
    return result


def build_frames(poses: list[Image.Image]) -> list[Image.Image]:
    anticipation, contact, recovery = poses
    return [
        transform_pose(anticipation, 0.975, dy=-5),
        transform_pose(anticipation, 1.0),
        transform_pose(anticipation, 1.012, dy=3),
        transform_pose(contact, 1.0),
        transform_pose(contact, 1.018, dy=5),
        transform_pose(recovery, 1.0),
        transform_pose(recovery, 0.992, dy=-2),
        transform_pose(recovery, 0.978, dy=-5),
    ]


def update_manifest(entity_id: str, frame_paths: list[Path]) -> None:
    manifest_path = ANIMATION_ROOT / entity_id / f"{entity_id}_animation.json"
    payload = json.loads(manifest_path.read_text(encoding="utf-8"))
    # Animation pack manifests use the production-root-relative `actions`
    # schema. Runtime Enemy discovers the same files by canonical filename.
    payload.pop("animations", None)
    attack = payload.setdefault("actions", {}).setdefault("attack", {})
    attack["fps"] = 16
    attack["frames"] = [
        path.relative_to(ROOT / "assets/production").as_posix() for path in frame_paths
    ]
    manifest_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent="\t") + "\n",
        encoding="utf-8",
    )


def frame_card(
    frame: Image.Image, label: str, width: int = 246, height: int = 284
) -> Image.Image:
    card = Image.new("RGB", (width, height), (12, 18, 20))
    checker = Image.new("RGBA", (width, height - 34), (0, 0, 0, 0))
    draw = ImageDraw.Draw(checker)
    tile = 16
    for y in range(0, checker.height, tile):
        for x in range(0, checker.width, tile):
            shade = 34 if (x // tile + y // tile) % 2 == 0 else 44
            draw.rectangle((x, y, x + tile, y + tile), fill=(shade, shade, shade, 255))
    preview = frame.copy()
    preview.thumbnail((width - 12, height - 46), Image.Resampling.LANCZOS)
    checker.alpha_composite(
        preview, ((width - preview.width) // 2, checker.height - preview.height - 4)
    )
    card.paste(checker.convert("RGB"), (0, 0))
    ImageDraw.Draw(card).text((8, height - 28), label, fill=(225, 238, 240))
    return card


def build_storyboard(all_frames: dict[str, list[Image.Image]]) -> None:
    columns = 4
    rows_per_entity = 4
    card_w, card_h = 246, 284
    header_h = 44
    entity_h = header_h + rows_per_entity * card_h
    sheet = Image.new(
        "RGB",
        (columns * card_w, 5 * entity_h),
        (5, 9, 11),
    )
    draw = ImageDraw.Draw(sheet)
    for entity_index, (entity_id, frames) in enumerate(all_frames.items()):
        column = entity_index % columns
        block_row = entity_index // columns
        ox = column * card_w
        oy = block_row * entity_h
        draw.rectangle(
            (ox, oy, ox + card_w - 2, oy + header_h - 2),
            fill=(11, 38, 43),
        )
        draw.text((ox + 8, oy + 13), entity_id, fill=(130, 232, 240))
        # The four acceptance frames expose anticipation, contact and recovery.
        for local, frame_index in enumerate((0, 2, 3, 5)):
            card = frame_card(
                frames[frame_index],
                ("ANTICIPATION 1", "ANTICIPATION 3", "CONTACT 4", "RECOVERY 6")[
                    local
                ],
                card_w,
                card_h,
            )
            sheet.paste(card, (ox, oy + header_h + local * card_h))
    AUDIT_PATH.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(AUDIT_PATH, optimize=True)


def main() -> None:
    all_frames: dict[str, list[Image.Image]] = {}
    for entity_id in TARGET_HEIGHTS:
        source = SOURCE_DIR / f"{entity_id}_attack_keyposes.png"
        if not source.exists():
            raise FileNotFoundError(source)
        poses = normalise_poses(entity_id, split_keyposes(Image.open(source)))
        frames = build_frames(poses)
        output_dir = ANIMATION_ROOT / entity_id
        output_dir.mkdir(parents=True, exist_ok=True)
        paths: list[Path] = []
        for index, frame in enumerate(frames, start=1):
            path = output_dir / f"{entity_id}_attack_{index:02d}.png"
            frame.save(path, optimize=True)
            paths.append(path)
        update_manifest(entity_id, paths)
        all_frames[entity_id] = frames
    build_storyboard(all_frames)
    print(f"Built {len(all_frames)} zombies × 8 attack frames")
    print(f"Storyboard: {AUDIT_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
