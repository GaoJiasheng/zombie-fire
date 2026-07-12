#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
LOGICAL_WIDTH = 1080.0
DESIGN_HEIGHT = 1920.0
EXTENDED_HEIGHT = 2622.0
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


def _luminance(image: Image.Image) -> np.ndarray:
    arr = np.asarray(image.convert("RGB"), dtype=np.float32)
    return arr[:, :, 0] * 0.2126 + arr[:, :, 1] * 0.7152 + arr[:, :, 2] * 0.0722


def _background_cover_errors(label: str, image: Image.Image, require_extended: bool) -> list[str]:
    # 主线背景现在是 1080x2622：原 1080x1920 战斗构图贴在画布底部，上方多出的
    # 702px 是真实环境延展。运行时按底边锚定，所以 1920 设备看到原构图，高屏设备
    # 只多看到顶部延展，不再使用黑色/渐变补条。这里验证两个不变量：
    # 1) 主线背景有足够高度覆盖 2622 高屏；
    # 2) 扩展画布底部 1920 区域内的 y=1500 防线，经底边锚定后仍等于 BREACH_Y。
    errors: list[str] = []
    width, height = image.size
    if width <= 0 or height <= 0:
        return [f"{label}: invalid background size {image.size}"]
    if require_extended and (width != int(LOGICAL_WIDTH) or height != int(EXTENDED_HEIGHT)):
        errors.append(f"{label}: campaign battle background must be 1080x2622 after tall-screen extension, got {width}x{height}")
    if require_extended:
        extension_h = float(height) - DESIGN_HEIGHT
        if extension_h < 690.0:
            errors.append(f"{label}: top extension too short ({extension_h:.1f}px), high-screen devices will expose filler")
    else:
        extension_h = max(0.0, float(height) - DESIGN_HEIGHT)
    for visible_height in TALL_VIEWPORT_HEIGHTS:
        bottom_shift = max(0.0, visible_height - DESIGN_HEIGHT)
        cover_scale = max(LOGICAL_WIDTH / float(width), visible_height / float(height))
        background_center_y = visible_height - float(height) * cover_scale * 0.5
        design_breach_y = 1500.0
        screen_y_of_barricade_art = background_center_y + (extension_h + design_breach_y - float(height) / 2.0) * cover_scale
        expected_breach_y = design_breach_y + bottom_shift
        if abs(screen_y_of_barricade_art - expected_breach_y) > 0.5:
            errors.append(
                f"{label}: background barricade art misaligned with dynamic breach line at height "
                f"{visible_height:.0f} (art={screen_y_of_barricade_art:.1f}px, breach_y={expected_breach_y:.1f}px)"
            )
        if require_extended and visible_height > DESIGN_HEIGHT:
            crop_top = max(0, int(round(float(height) - visible_height / cover_scale)))
            visible = image.crop((0, crop_top, width, min(height, crop_top + int(round(visible_height / cover_scale)))))
            top_band = visible.crop((0, 0, visible.width, min(240, visible.height)))
            lum = _luminance(top_band)
            dark_ratio = float((lum < 18.0).mean())
            mean_luma = float(lum.mean())
            std_luma = float(lum.std())
            if dark_ratio > 0.72 and mean_luma < 22.0 and std_luma < 18.0:
                errors.append(
                    f"{label}: high-screen top band still reads as blank dark filler at height {visible_height:.0f} "
                    f"(mean={mean_luma:.1f}, std={std_luma:.1f}, dark<18={dark_ratio:.1%})"
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
    # 只断言和"高屏战斗布局"这个不变量真正相关的片段：背景延伸画布怎么定位、
    # breach 线怎么注入给敌人。wave 进度条填充左右边界的具体公式属于横向 HUD
    # 细节，和竖屏高度无关，且已经从字面量演进成按 bar.size.x 动态计算——放在
    # 这里断言字面量只会在每次合理重构时误报，已移除。
    required_battle_snippets = [
        "func _battle_visible_height() -> float:",
        "var visible_height := _battle_visible_height()",
        "var cover_scale := maxf(1080.0 / texture_size.x, visible_height / texture_size.y)",
        "background.position = Vector2(540, visible_height - texture_size.y * cover_scale * 0.5)",
        "_hide_background_top_fill()",
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

    used_envs = sorted({str(level.get("env", "")) for level in levels})
    # Campaign environments are shown by the 99-level release path and must carry the
    # full tall-screen canvas. Legacy environment rows only need to stay valid refs.
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
            errors.extend(_background_cover_errors(env_id, image, env_id in used_envs))

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

    print(
        "Tall battle layout OK: "
        f"{len(levels)} levels, {len(used_envs)} campaign envs, "
        f"{len(environments)} total env rows, heights={','.join(str(int(v)) for v in TALL_VIEWPORT_HEIGHTS)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
