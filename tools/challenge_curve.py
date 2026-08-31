#!/usr/bin/env python3
"""Single-source evaluator and structural gates for data/challenges.json."""

from __future__ import annotations

import math


def budget_for_level(level_number: int, challenges: dict) -> float:
    curve = challenges["curve"]
    anchors = curve["anchors"]
    if level_number <= int(anchors[0]["level"]):
        return float(anchors[0]["k"])
    for left, right in zip(anchors, anchors[1:]):
        if level_number > int(right["level"]):
            continue
        t = (level_number - int(left["level"])) / max(int(right["level"]) - int(left["level"]), 1)
        if curve["shape"] == "piecewise_smoothstep":
            t = 3.0 * t * t - 2.0 * t * t * t
        return float(left["k"]) + (float(right["k"]) - float(left["k"])) * t
    return float(anchors[-1]["k"])


def fixture_for_level(level_number: int, challenges: dict) -> str:
    for route in challenges["curve"]["reference_routes"]:
        if int(route["from"]) <= level_number <= int(route["to"]):
            return str(route["fixture"])
    return ""


def exponents_for_level(level_number: int, challenges: dict) -> dict[str, float]:
    anchors = challenges["curve"]["line_pressure_exponents"]["anchors"]
    if level_number <= int(anchors[0]["level"]):
        return {key: float(anchors[0][key]) for key in ("speed", "breach", "mechanic")}
    for left, right in zip(anchors, anchors[1:]):
        if level_number > int(right["level"]):
            continue
        t = (level_number - int(left["level"])) / max(int(right["level"]) - int(left["level"]), 1)
        return {key: float(left[key]) + (float(right[key]) - float(left[key])) * t
                for key in ("speed", "breach", "mechanic")}
    return {key: float(anchors[-1][key]) for key in ("speed", "breach", "mechanic")}


def rule_for_level(level_number: int, challenges: dict) -> dict:
    chapter = min(max((level_number - 1) // 10 + 1, 1), 10)
    result = dict(challenges["chapters"][f"chapter_{chapter:02d}"])
    budget = budget_for_level(level_number, challenges)
    exponents = exponents_for_level(level_number, challenges)
    result.update({
        "hp_mult": budget,
        "speed_mult": budget ** float(exponents["speed"]),
        "breach_damage_mult": budget ** float(exponents["breach"]),
        "mechanic_rate_mult": budget ** float(exponents["mechanic"]),
        "recommended_power_mult": budget,
        "reference_fixture": fixture_for_level(level_number, challenges),
    })
    return result


def validate(challenges: dict) -> list[str]:
    errors: list[str] = []
    curve = challenges.get("curve", {})
    chapters = challenges.get("chapters", {})
    expected_curve = {"shape": "piecewise_smoothstep"}
    for key, expected in expected_curve.items():
        actual = curve.get(key)
        if isinstance(expected, float):
            if not isinstance(actual, (int, float)) or not math.isclose(float(actual), expected, abs_tol=1e-12):
                errors.append(f"challenges.curve.{key} must be {expected}, got {actual}")
        elif actual != expected:
            errors.append(f"challenges.curve.{key} must be {expected!r}, got {actual!r}")
    expected_chapters = {f"chapter_{number:02d}" for number in range(1, 11)}
    if set(chapters) != expected_chapters:
        errors.append("challenges.chapters must define chapter_01 through chapter_10 exactly")
    exponents = curve.get("line_pressure_exponents", {})
    anchors = curve.get("anchors", [])
    if not isinstance(anchors, list) or len(anchors) < 2:
        errors.append("challenge curve must provide at least two anchors")
    else:
        anchor_levels = [int(row.get("level", 0)) for row in anchors]
        anchor_values = [float(row.get("k", 0.0)) for row in anchors]
        if anchor_levels[0] != 1 or anchor_levels[-1] != 99 or anchor_levels != sorted(set(anchor_levels)):
            errors.append(f"challenge anchors must uniquely cover ordered endpoints 1..99: {anchor_levels}")
        if not math.isclose(anchor_values[0], 1.25, abs_tol=1e-12):
            errors.append(f"challenge K(1) anchor must be 1.25, got {anchor_values[0]}")
        if not math.isclose(anchor_values[-1], 5.0, abs_tol=1e-12):
            errors.append(f"challenge K(99) runtime anchor must be 5.0, got {anchor_values[-1]}")
        if any(right <= left for left, right in zip(anchor_values, anchor_values[1:])):
            errors.append(f"challenge anchor K values must strictly increase: {anchor_values}")
    finale = curve.get("finale_anchor", {})
    expected_finale = {"fixture": "golden_law_tier_1_max", "seeds": 10,
                       "win_rate": [0.6, 0.9], "boss_phase_median_seconds": [150.0, 220.0]}
    if finale != expected_finale:
        errors.append(f"challenge finale runtime anchor drifted: {finale}")
    exponent_anchors = exponents.get("anchors", [])
    if not isinstance(exponent_anchors, list) or len(exponent_anchors) < 2:
        errors.append("challenge line-pressure curve must provide at least two anchors")
    else:
        exponent_levels = [int(row.get("level", 0)) for row in exponent_anchors]
        if exponent_levels[0] != 1 or exponent_levels[-1] != 99 or exponent_levels != sorted(set(exponent_levels)):
            errors.append(f"challenge exponent anchors must uniquely cover ordered endpoints 1..99: {exponent_levels}")
        for row in exponent_anchors:
            values = [float(row.get(key, -1.0)) for key in ("speed", "breach", "mechanic")]
            if any(value < 0.0 or value > 1.0 for value in values):
                errors.append(f"challenge exponent anchor at {row.get('level')} leaves [0,1]: {values}")
            if not math.isclose(sum(values), 1.0, abs_tol=1e-12):
                errors.append(f"challenge exponent anchor at {row.get('level')} must sum to 1")
        first = exponent_anchors[0]
        last = exponent_anchors[-1]
        if [float(first[key]) for key in ("speed", "breach", "mechanic")] != [0.2, 0.4, 0.4]:
            errors.append("challenge line-pressure start split must remain 0.2/0.4/0.4")
        if [float(last[key]) for key in ("speed", "breach", "mechanic")] != [1.0, 0.0, 0.0]:
            errors.append("challenge L099 line-pressure split must remain 1/0/0")
    expected_runtime_contract = {
        "representative_offsets": [1, 5, 10],
        "chapter_win_rate_bands": {"1-6": [0.7, 1.0], "7-8": [0.6, 0.9], "9-10": [0.6, 0.9]},
        "semantics": "chapter_aggregate_band",
    }
    if curve.get("chapter_runtime_contract") != expected_runtime_contract:
        errors.append(f"challenge chapter runtime contract drifted: {curve.get('chapter_runtime_contract')}")
    expected_routes = [(1, 60, "paced_plus_10"), (61, 80, "maxed_free_matchup_aware_v1"),
                       (81, 99, "golden_law_tier_1_max")]
    routes = curve.get("reference_routes", [])
    actual_routes = [(int(row.get("from", 0)), int(row.get("to", 0)), str(row.get("fixture", ""))) for row in routes]
    if actual_routes != expected_routes:
        errors.append(f"challenge reference routes drifted: {actual_routes}")
    if errors:
        return errors
    budgets = [budget_for_level(level, challenges) for level in range(1, 100)]
    if not math.isclose(budgets[0], 1.25, abs_tol=1e-12):
        errors.append(f"challenge K(1) drifted: {budgets[0]}")
    if not math.isclose(budgets[-1], 5.0, abs_tol=1e-12):
        errors.append(f"challenge K(99) must be runtime-derived 5.0, got {budgets[-1]:.12f}")
    for index, (left, right) in enumerate(zip(budgets, budgets[1:]), start=1):
        if right < left:
            errors.append(f"challenge K is not monotonic at {index:03d}->{index + 1:03d}")
        if right / max(left, 1e-12) - 1.0 > 0.18 + 1e-12:
            errors.append(f"challenge K relative delta exceeds 18% at {index:03d}->{index + 1:03d}: {right/left-1.0:.3%}")
    chapter_stats = []
    for chapter in range(1, 11):
        values = sorted(budgets[(chapter - 1) * 10:min(chapter * 10, 99)])
        middle = len(values) // 2
        median = values[middle] if len(values) % 2 else (values[middle - 1] + values[middle]) / 2.0
        chapter_stats.append((min(values), max(values), sum(values) / len(values), median))
    for index in range(1, len(chapter_stats)):
        for metric, previous, current in zip(("min", "max", "mean", "median"), chapter_stats[index - 1], chapter_stats[index]):
            if current <= previous:
                errors.append(f"challenge chapter {index + 1} {metric} must increase: {previous}->{current}")
    for level in range(81, 100):
        if 1.0 / budgets[level - 1] >= 0.85:
            errors.append(f"challenge {level:03d} free reference must be severely underpowered")
    return errors
