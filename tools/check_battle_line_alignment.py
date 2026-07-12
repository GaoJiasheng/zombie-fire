#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BATTLE = ROOT / "gameplay/battle/battle.gd"
ENEMY = ROOT / "gameplay/enemy/enemy.gd"
SKILL_RUNTIME = ROOT / "gameplay/skill/skill_runtime.gd"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _func_body(source: str, name: str) -> str:
    match = re.search(rf"^func\s+{re.escape(name)}\s*\([^)]*\)\s*(?:->\s*[^:]+)?:", source, re.M)
    if not match:
        return ""
    start = match.start()
    next_match = re.search(r"^func\s+\w+\s*\(", source[match.end() :], re.M)
    if next_match:
        return source[start : match.end() + next_match.start()]
    return source[start:]


def main() -> int:
    errors: list[str] = []
    battle = _read(BATTLE)
    enemy = _read(ENEMY)
    skill_runtime = _read(SKILL_RUNTIME)

    required_battle_snippets = [
        'enemy.call("configure_attack_line", BREACH_Y)',
        "func _base_line_y() -> float:",
        "return BREACH_Y",
        "func _pet_anchor_position() -> Vector2:",
        "return Vector2(PET_BASE_X_DESIGN, _base_line_y() + PET_BASE_LINE_OFFSET)",
        "func _base_damage_impact_position(x: float) -> Vector2:",
        "Vector2(clampf(x, 96.0, 984.0), _base_line_y())",
        "func _slow_field_min_y_for_level(slow_level: int) -> float:",
        "return _base_line_inner_y(_slow_field_inner_offset_for_level(slow_level))",
    ]
    for snippet in required_battle_snippets:
        if snippet not in battle:
            errors.append(f"battle.gd missing line-alignment snippet: {snippet}")

    if "func configure_attack_line(base_line_y: float) -> void:" not in enemy:
        errors.append("enemy.gd missing configure_attack_line(base_line_y: float)")
    if "attack_line_y = base_line_y" not in enemy:
        errors.append("enemy.gd attack_line_y is not derived from base_line_y")

    if "func slow_mult_for_y(y: float, base_line_y: float = SLOW_FIELD_DESIGN_BASE_LINE_Y) -> float:" not in skill_runtime:
        errors.append("SkillRuntime.slow_mult_for_y must accept runtime base_line_y")
    if "y_min = base_line_y - design_offset" not in skill_runtime:
        errors.append("SkillRuntime slow field y_min must derive from runtime base_line_y")

    body_expectations = {
        "_spawn_breach_attack_vfx": [
            "var target := _base_damage_impact_position(enemy.global_position.x)",
        ],
        "_apply_enemy_skill_base_damage": [
            "var impact_position := _base_damage_impact_position(target_position.x)",
            "_spawn_barrier_break_vfx(impact_position)",
            '_spawn_float_text(impact_position, "格挡"',
        ],
        "_apply_slow_field": [
            "skills.slow_mult_for_y(enemy.global_position.y, _base_line_y())",
        ],
        "_update_slow_field_visual": [
            "var y_min := _slow_field_min_y_for_level(slow_level)",
            "var field_height := maxf(_base_line_y() - y_min, 60.0)",
        ],
        "_update_slow_field_edges": [
            "var bottom_y := _base_line_y()",
        ],
        "_spawn_barrier_visual": [
            "barrier_visual.position = Vector2(540, _base_line_y())",
        ],
        "_spawn_pet": [
            "pet_sprite.position = _pet_anchor_position()",
        ],
        "_update_pet_animation": [
            "pet_sprite.position.y = _pet_anchor_position().y",
            "PET_IDLE_FLOAT_AMPLITUDE",
        ],
    }
    for func_name, snippets in body_expectations.items():
        body = _func_body(battle, func_name)
        if not body:
            errors.append(f"battle.gd missing function {func_name}")
            continue
        for snippet in snippets:
            if snippet not in body:
                errors.append(f"{func_name} missing line-alignment snippet: {snippet}")

    forbidden_battle_patterns = [
        (r"Vector2\([^,\n]+,\s*1360(?:\.0)?\)", "old hardcoded base impact y=1360"),
        (r"Vector2\([^,\n]+,\s*1370(?:\.0)?\)", "old hardcoded base impact y=1370"),
        (r"Vector2\([^,\n]+,\s*1440\.0\s*\+\s*bottom_dock_shift", "old hardcoded base impact y=1440+bottom_dock_shift"),
        (r"BREACH_Y\s*-\s*30\.0", "old shield offset BREACH_Y-30"),
        (r"BREACH_Y\s*\+\s*10\.0", "old breach impact offset BREACH_Y+10"),
        (r"slow_mult_for_y\(enemy\.global_position\.y\)", "slow field called without runtime base_line_y"),
        (r"pet_sprite\.position\s*=\s*Vector2\(725,\s*1625\)", "old hardcoded pet anchor y=1625"),
        (r"pet_sprite\.position\.y\s*=\s*1625\.0", "old hardcoded pet animation y=1625"),
    ]
    for pattern, label in forbidden_battle_patterns:
        if re.search(pattern, battle):
            errors.append(f"battle.gd still contains {label}")

    if errors:
        print("Battle line alignment check failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Battle line alignment OK: attack line, base impact, barrier, and slow field all derive from BREACH_Y")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
