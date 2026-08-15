#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
CHARACTER_IDS = ["char_vanguard", "char_blaze", "char_frost", "char_volt"]
FRAME_MODES = ["idle", "attack", "attack_left", "attack_right", "hurt"]
FRAME_RANGE = range(1, 8)
# Keep this in sync with gameplay/battle/battle.gd.
CHARACTER_BASE_X = 540.0
CHARACTER_BASE_Y = 1652.0
CHARACTER_VISUAL_BASE_SCALE = 0.512
CHARACTER_PRESENTATION_SCALE = 1.20

HUD_RECTS = {
    "wave_bar": (124.0, 18.0, 956.0, 66.0),
    "boss_label": (160.0, 130.0, 920.0, 186.0),
    "boss_track": (160.0, 196.0, 920.0, 218.0),
    "skill_grid": (10.0, 1590.0, 316.0, 1784.0),
    "active_skill": (926.0, 1688.0, 1046.0, 1808.0),
    "gold_icon": (36.0, 1814.0, 90.0, 1868.0),
    "gold_label": (92.0, 1808.0, 204.0, 1870.0),
    "xp_icon": (212.0, 1819.0, 256.0, 1863.0),
    "xp_bar": (260.0, 1813.0, 646.0, 1867.0),
    "hp_bar": (660.0, 1813.0, 1044.0, 1867.0),
}

MUST_NOT_OVERLAP = [
    ("wave_bar", "boss_label"),
    ("boss_label", "boss_track"),
    ("skill_grid", "active_skill"),
    ("skill_grid", "gold_icon"),
    ("skill_grid", "gold_label"),
    ("skill_grid", "xp_icon"),
    ("skill_grid", "xp_bar"),
    ("skill_grid", "hp_bar"),
    ("active_skill", "hp_bar"),
    ("xp_bar", "hp_bar"),
]


def _load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def _weapons() -> dict[str, dict]:
    table = _load_json(ROOT / "data/weapons.json")
    if isinstance(table, dict):
        return {str(key): value for key, value in table.items() if isinstance(value, dict)}
    return {
        str(row.get("id", "")): row
        for row in table
        if isinstance(row, dict) and row.get("id")
    }


def _skill_count() -> int:
    table = _load_json(ROOT / "data/skills.json")
    if isinstance(table, dict):
        return len(table)
    return sum(1 for row in table if isinstance(row, dict))


def _intersects(a: tuple[float, float, float, float], b: tuple[float, float, float, float]) -> bool:
    return min(a[2], b[2]) > max(a[0], b[0]) and min(a[3], b[3]) > max(a[1], b[1])


def _gap(a: tuple[float, float, float, float], b: tuple[float, float, float, float]) -> float:
    dx = max(max(b[0] - a[2], a[0] - b[2]), 0.0)
    dy = max(max(b[1] - a[3], a[1] - b[3]), 0.0)
    return (dx * dx + dy * dy) ** 0.5


def _visible_metrics(path: Path) -> tuple[int, int, tuple[int, int, int, int]] | None:
    with Image.open(path) as image:
        rgba = image.convert("RGBA")
        bbox = rgba.getchannel("A").getbbox()
        if bbox is None:
            return None
        width, height = rgba.size
    return width, height, bbox


def _pose_for_path(path: Path) -> str:
    name = path.name
    if "_attack_left" in name:
        return "left"
    if "_attack_right" in name:
        return "right"
    if "_attack" in name:
        return "center"
    if "_hurt" in name:
        return "hurt"
    return "idle"


def _body_metric(body_metrics: dict, profile_id: str, character_id: str, pose: str) -> dict:
    profiles = body_metrics.get("profiles", {})
    profile = profiles.get(profile_id, profiles.get("standard", {}))
    poses = profile.get(character_id, {})
    fallback = "center" if profile_id != "standard" else "idle"
    return poses.get(pose, poses.get(fallback, {}))


def _visible_rect(
    path: Path,
    metric: dict,
    body_metrics: dict,
    profile_id: str,
    character_id: str,
) -> tuple[float, float, float, float] | None:
    metrics = _visible_metrics(path)
    if metrics is None:
        return None
    width, height, bbox = metrics
    left, top, right, bottom = bbox
    target_height = float(body_metrics.get("target_body_height_px", 420.0))
    target_foot = float(body_metrics.get("target_foot_offset_px", 116.0))
    reference_pose = str(body_metrics.get("scale_reference_pose", "center"))
    scale_metric = _body_metric(body_metrics, profile_id, character_id, reference_pose)
    source_height = max(1.0, float(scale_metric.get("body_height_px", target_height)))
    body_scale = CHARACTER_VISUAL_BASE_SCALE * target_height / source_height
    center_x = float(metric.get("body_center_x_px", width * 0.5))
    foot_y = float(metric.get("foot_y_px", height * 0.5))
    anchor_x = (width * 0.5 - center_x) * body_scale
    anchor_y = target_foot - (foot_y - height * 0.5) * body_scale
    rig_foot_lift = target_foot * (CHARACTER_PRESENTATION_SCALE - 1.0)
    return (
        CHARACTER_BASE_X + (anchor_x + (float(left) - float(width) * 0.5) * body_scale) * CHARACTER_PRESENTATION_SCALE,
        CHARACTER_BASE_Y - rig_foot_lift + (anchor_y + (float(top) - float(height) * 0.5) * body_scale) * CHARACTER_PRESENTATION_SCALE,
        CHARACTER_BASE_X + (anchor_x + (float(right) - float(width) * 0.5) * body_scale) * CHARACTER_PRESENTATION_SCALE,
        CHARACTER_BASE_Y - rig_foot_lift + (anchor_y + (float(bottom) - float(height) * 0.5) * body_scale) * CHARACTER_PRESENTATION_SCALE,
    )


def main() -> int:
    errors: list[str] = []
    for a_name, b_name in MUST_NOT_OVERLAP:
        if _intersects(HUD_RECTS[a_name], HUD_RECTS[b_name]):
            errors.append(f"HUD controls overlap: {a_name} {HUD_RECTS[a_name]} vs {b_name} {HUD_RECTS[b_name]}")

    # Authored 24 px is globally scaled to 36 px; authored outline 4 becomes
    # 6 px. The label box must contain the face plus both outline edges, and
    # retain a visible gap before the rail. This locks the regression that
    # previously clipped CJK bottoms and covered them with the red bar.
    boss_label_height = HUD_RECTS["boss_label"][3] - HUD_RECTS["boss_label"][1]
    boss_effective_font = round(24 * 1.4) + 2
    boss_effective_outline = round(4 * 1.4)
    boss_required_height = boss_effective_font + boss_effective_outline * 2
    boss_label_track_gap = HUD_RECTS["boss_track"][1] - HUD_RECTS["boss_label"][3]
    if boss_label_height < boss_required_height:
        errors.append(
            f"Boss label height {boss_label_height:.1f}px cannot contain "
            f"{boss_effective_font}px text + {boss_effective_outline}px outline"
        )
    if boss_label_track_gap < 10.0:
        errors.append(f"Boss label-to-track gap is only {boss_label_track_gap:.1f}px; need >= 10px")

    skill_capacity = 16
    if _skill_count() > skill_capacity:
        errors.append(f"skill grid capacity is {skill_capacity}, but data/skills.json has {_skill_count()} skills")

    checked_frames = 0
    min_skill_gap = 9999.0
    min_bottom_gap = 9999.0
    weapons = _weapons()
    body_metrics = _load_json(ROOT / "data/character_body_metrics.json")
    for character_id in CHARACTER_IDS:
        for weapon_id, weapon in weapons.items():
            true_grip = weapon.get("presentation", {}).get("true_grip", {})
            if true_grip:
                true_grip_root = ROOT / str(true_grip.get("root", "")).removeprefix("res://")
                paths = [
                    true_grip_root
                    / str(true_grip.get(pattern_key, "")).replace("{character_id}", character_id)
                    for pattern_key in ("left_pattern", "center_pattern", "right_pattern")
                ]
                profile_id = weapon_id
            else:
                base_dir = (
                    ROOT
                    / "assets/production/sprites/animations/character_weapon_combos"
                    / character_id
                )
                paths = [
                    base_dir
                    / f"{character_id}_{weapon_id}_{mode}_{frame:02d}.png"
                    for mode in FRAME_MODES
                    for frame in FRAME_RANGE
                ]
                profile_id = "standard"
            for path in paths:
                if not path.exists():
                    continue
                pose = _pose_for_path(path)
                metric = _body_metric(body_metrics, profile_id, character_id, pose)
                rect = _visible_rect(path, metric, body_metrics, profile_id, character_id)
                if rect is None:
                    continue
                checked_frames += 1
                min_skill_gap = min(
                    min_skill_gap, _gap(rect, HUD_RECTS["skill_grid"])
                )
                min_bottom_gap = min(
                    min_bottom_gap,
                    _gap(rect, HUD_RECTS["xp_bar"]),
                    _gap(rect, HUD_RECTS["hp_bar"]),
                )
                for hud_name, hud_rect in HUD_RECTS.items():
                    if _intersects(rect, hud_rect):
                        errors.append(
                            f"character frame overlaps {hud_name}: "
                            f"{path.relative_to(ROOT)} "
                            f"rect={tuple(round(v, 1) for v in rect)} hud={hud_rect}"
                        )
                        if len(errors) >= 20:
                            break
                if len(errors) >= 20:
                    break
            if len(errors) >= 20:
                break
        if len(errors) >= 20:
            break

    if checked_frames <= 0:
        errors.append("no character/weapon combo frames were checked")

    if errors:
        print("Battle HUD overlap check failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print(
        "Battle HUD overlap OK: "
        f"{checked_frames} character/weapon frames, "
        f"hero presentation={CHARACTER_PRESENTATION_SCALE:.2f}x, "
        f"normalized body={float(body_metrics.get('target_body_height_px', 420.0)):.0f}px source ruler, "
        f"min skill gap={min_skill_gap:.1f}px, min bottom-resource gap={min_bottom_gap:.1f}px"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
