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
MAX_GROWTH_VISUAL_SCALE = 1.16
VISIBLE_SCALE = CHARACTER_VISUAL_BASE_SCALE * MAX_GROWTH_VISUAL_SCALE

HUD_RECTS = {
    "wave_bar": (124.0, 18.0, 956.0, 66.0),
    "skill_grid": (10.0, 1654.0, 420.0, 1784.0),
    "active_skill": (926.0, 1688.0, 1046.0, 1808.0),
    "gold_icon": (36.0, 1814.0, 90.0, 1868.0),
    "gold_label": (92.0, 1808.0, 204.0, 1870.0),
    "xp_icon": (212.0, 1819.0, 256.0, 1863.0),
    "xp_bar": (260.0, 1813.0, 646.0, 1867.0),
    "hp_bar": (660.0, 1813.0, 1044.0, 1867.0),
}

MUST_NOT_OVERLAP = [
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


def _weapon_ids() -> list[str]:
    table = _load_json(ROOT / "data/weapons.json")
    if isinstance(table, dict):
        return [str(key) for key in table.keys()]
    return [str(row.get("id", "")) for row in table if isinstance(row, dict) and row.get("id")]


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


def _visible_rect(path: Path) -> tuple[float, float, float, float] | None:
    with Image.open(path) as image:
        rgba = image.convert("RGBA")
        bbox = rgba.getchannel("A").getbbox()
        if bbox is None:
            return None
        width, height = rgba.size
    left, top, right, bottom = bbox
    return (
        CHARACTER_BASE_X + (float(left) - float(width) * 0.5) * VISIBLE_SCALE,
        CHARACTER_BASE_Y + (float(top) - float(height) * 0.5) * VISIBLE_SCALE,
        CHARACTER_BASE_X + (float(right) - float(width) * 0.5) * VISIBLE_SCALE,
        CHARACTER_BASE_Y + (float(bottom) - float(height) * 0.5) * VISIBLE_SCALE,
    )


def main() -> int:
    errors: list[str] = []
    for a_name, b_name in MUST_NOT_OVERLAP:
        if _intersects(HUD_RECTS[a_name], HUD_RECTS[b_name]):
            errors.append(f"HUD controls overlap: {a_name} {HUD_RECTS[a_name]} vs {b_name} {HUD_RECTS[b_name]}")

    skill_capacity = 16
    if _skill_count() > skill_capacity:
        errors.append(f"skill grid capacity is {skill_capacity}, but data/skills.json has {_skill_count()} skills")

    checked_frames = 0
    min_skill_gap = 9999.0
    min_bottom_gap = 9999.0
    weapons = _weapon_ids()
    for character_id in CHARACTER_IDS:
        for weapon_id in weapons:
            base_dir = ROOT / "assets/production/sprites/animations/character_weapon_combos" / character_id
            for mode in FRAME_MODES:
                for frame in FRAME_RANGE:
                    path = base_dir / f"{character_id}_{weapon_id}_{mode}_{frame:02d}.png"
                    if not path.exists():
                        continue
                    rect = _visible_rect(path)
                    if rect is None:
                        continue
                    checked_frames += 1
                    min_skill_gap = min(min_skill_gap, _gap(rect, HUD_RECTS["skill_grid"]))
                    min_bottom_gap = min(min_bottom_gap, _gap(rect, HUD_RECTS["xp_bar"]), _gap(rect, HUD_RECTS["hp_bar"]))
                    for hud_name, hud_rect in HUD_RECTS.items():
                        if _intersects(rect, hud_rect):
                            errors.append(
                                f"character frame overlaps {hud_name}: {path.relative_to(ROOT)} rect={tuple(round(v, 1) for v in rect)} hud={hud_rect}"
                            )
                            if len(errors) >= 20:
                                break
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
        f"max growth scale={MAX_GROWTH_VISUAL_SCALE:.2f}, "
        f"min skill gap={min_skill_gap:.1f}px, min bottom-resource gap={min_bottom_gap:.1f}px"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
