#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
LOGICAL_WIDTH = 1080.0
DESIGN_HEIGHT = 1920.0
TALL_VIEWPORT_HEIGHTS = (1920.0, 2046.0, 2340.0, 2622.0)
NORMAL_ATTACK_OFFSET_RANGE = (-18.0, 26.0)
BOSS_ATTACK_OFFSET_RANGE = (-94.0, -62.0)


def _load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def _rows(table) -> list[dict]:
    if isinstance(table, list):
        return [row for row in table if isinstance(row, dict)]
    if isinstance(table, dict):
        result: list[dict] = []
        for key, value in table.items():
            if isinstance(value, dict):
                row = dict(value)
                row.setdefault("id", str(key))
                result.append(row)
        return result
    return []


def _res_path(path: str) -> Path:
    if path.startswith("res://"):
        return ROOT / path[len("res://") :]
    return ROOT / path


def _background_cover_errors(label: str, image_size: tuple[int, int]) -> list[str]:
    # 背景固定按设计尺寸(1080x1920)算 cover_scale、只做整体平移(bottom_dock_shift)，
    # 不随可见高度整体缩放——这样背景里画的护栏/基座和玩法坐标系里实际的动态
    # breach 线才能保证严格对齐:同一个 shift 同时用在人物/护栏(玩法坐标)和背景
    # 平移量上。之前踩过的坑：如果背景改成按可见高度整体 cover 缩放，画面里的
    # 护栏就会和实际 breach 线产生随设备高度增长而扩大的错位(验证过 iPhone 16
    # Pro Max 尺寸下能到 90px+)，等价于历史上那次"人物位置对齐"回归——这里直接
    # 验证"设计画布内 y=1500(护栏/barricade 美术参考线)经平移后是否精确落在
    # 动态 breach_y 上"这个真正要保的不变量，而不是去断言某种缩放公式本身。
    errors: list[str] = []
    width, height = image_size
    if width <= 0 or height <= 0:
        return [f"{label}: invalid background size {image_size}"]
    cover_scale = max(LOGICAL_WIDTH / float(width), DESIGN_HEIGHT / float(height))
    for visible_height in TALL_VIEWPORT_HEIGHTS:
        bottom_shift = max(0.0, visible_height - DESIGN_HEIGHT)
        background_center_y = 960.0 + bottom_shift
        design_breach_y = 1500.0
        screen_y_of_barricade_art = background_center_y + (design_breach_y - float(height) / 2.0) * cover_scale
        expected_breach_y = design_breach_y + bottom_shift
        if abs(screen_y_of_barricade_art - expected_breach_y) > 0.5:
            errors.append(
                f"{label}: background barricade art misaligned with dynamic breach line at height "
                f"{visible_height:.0f} (art={screen_y_of_barricade_art:.1f}px, breach_y={expected_breach_y:.1f}px)"
            )
    return errors


def _collect_spawn_refs(level: dict) -> list[tuple[str, bool]]:
    refs: list[tuple[str, bool]] = []
    for wave in level.get("waves", []):
        if not isinstance(wave, dict):
            continue
        boss_id = str(wave.get("boss", ""))
        if boss_id:
            refs.append((boss_id, True))
        for spawn in wave.get("spawns", []):
            if not isinstance(spawn, dict):
                continue
            spawn_id = str(spawn.get("type", ""))
            if spawn_id:
                refs.append((spawn_id, bool(spawn.get("boss", False))))
        for group in wave.get("groups", []):
            if not isinstance(group, dict):
                continue
            group_id = str(group.get("type", ""))
            if group_id:
                refs.append((group_id, bool(group.get("boss", False))))
    return refs


def _source_guard_errors() -> list[str]:
    errors: list[str] = []
    battle_source = (ROOT / "gameplay/battle/battle.gd").read_text(encoding="utf-8")
    enemy_source = (ROOT / "gameplay/enemy/enemy.gd").read_text(encoding="utf-8")
    required_battle_snippets = [
        "background.position = Vector2(540, 960.0 + bottom_dock_shift)",
        "var cover_scale := maxf(1080.0 / texture_size.x, 1920.0 / texture_size.y)",
        'enemy.call("configure_attack_line", BREACH_Y)',
    ]
    for snippet in required_battle_snippets:
        if snippet not in battle_source:
            errors.append(f"battle.gd missing global tall-layout guard snippet: {snippet}")
    if not re.search(r"func\s+configure_attack_line\s*\(\s*base_line_y\s*:\s*float\s*\)", enemy_source):
        errors.append("enemy.gd missing configure_attack_line(base_line_y: float)")
    if "attack_line_y = base_line_y" not in enemy_source:
        errors.append("enemy.gd attack line no longer derives from the injected base_line_y")
    return errors


def main() -> int:
    errors: list[str] = []
    levels = _rows(_load_json(ROOT / "data/levels.json"))
    environments = _load_json(ROOT / "data/environments.json")
    zombies = _load_json(ROOT / "data/zombies.json")
    bosses = _load_json(ROOT / "data/bosses.json")

    if len(levels) != 99:
        errors.append(f"expected 99 levels, found {len(levels)}")

    # Check every environment referenced by levels, plus legacy environment rows,
    # because all battle backgrounds share the same runtime placement function.
    for env_id, env in environments.items():
        if not isinstance(env, dict):
            errors.append(f"{env_id}: environment row must be an object")
            continue
        background_path = str(env.get("battle_background", ""))
        if not background_path:
            errors.append(f"{env_id}: missing battle_background")
            continue
        full_path = _res_path(background_path)
        if not full_path.exists():
            errors.append(f"{env_id}: background does not exist: {background_path}")
            continue
        with Image.open(full_path) as image:
            errors.extend(_background_cover_errors(env_id, image.size))

    for level in levels:
        level_id = str(level.get("id", "<missing>"))
        env_id = str(level.get("env", ""))
        if env_id not in environments:
            errors.append(f"{level_id}: unknown env {env_id}")
        for enemy_id, is_boss in _collect_spawn_refs(level):
            table = bosses if is_boss else zombies
            if enemy_id not in table:
                kind = "boss" if is_boss else "zombie"
                errors.append(f"{level_id}: unknown {kind} spawn id {enemy_id}")

    for visible_height in TALL_VIEWPORT_HEIGHTS:
        bottom_shift = max(0.0, visible_height - DESIGN_HEIGHT)
        breach_y = 1500.0 + bottom_shift
        normal_min = breach_y + NORMAL_ATTACK_OFFSET_RANGE[0]
        normal_max = breach_y + NORMAL_ATTACK_OFFSET_RANGE[1]
        boss_min = breach_y + BOSS_ATTACK_OFFSET_RANGE[0]
        boss_max = breach_y + BOSS_ATTACK_OFFSET_RANGE[1]
        if normal_min < breach_y - 25.0 or normal_max > breach_y + 32.0:
            errors.append(f"normal attack line out of defense range at height {visible_height:.0f}: {normal_min:.1f}-{normal_max:.1f}")
        if boss_min < breach_y - 105.0 or boss_max > breach_y - 50.0:
            errors.append(f"boss attack line out of defense range at height {visible_height:.0f}: {boss_min:.1f}-{boss_max:.1f}")

    errors.extend(_source_guard_errors())

    if errors:
        print("Tall battle layout check failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    used_envs = sorted({str(level.get("env", "")) for level in levels})
    print(
        "Tall battle layout OK: "
        f"{len(levels)} levels, {len(used_envs)} campaign envs, "
        f"{len(environments)} total env rows, heights={','.join(str(int(v)) for v in TALL_VIEWPORT_HEIGHTS)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
