#!/usr/bin/env python3
"""Shared card-budget power and late-wave pressure model.

Keep this numerically aligned with SaveManager's power model. Runtime pressure
is authored from the level's card budget, never from live player performance,
so the game remains deterministic and does not rubber-band successful builds.
"""
from __future__ import annotations

import math


SKILL_THROUGHPUT_CAP = 13.5
POWER_SCORE_EXPONENT = 0.5
DEFAULT_RUN_SKILL_PRESSURE = {
    "reference_card_picks": 4,
    "hp_conversion": 0.65,
    "max_hp_mult": 1.60,
    "speed_conversion": 0.15,
    "max_speed_mult": 1.15,
}


def estimate_skill_throughput(card_picks: int) -> float:
    picks = float(max(0, card_picks))
    return min(SKILL_THROUGHPUT_CAP, 1.0 + 0.42 * picks + 0.08 * picks * picks)


def card_budget_power_factor(card_picks: int, economy: dict) -> float:
    rule = economy.get("run_skill_pressure", DEFAULT_RUN_SKILL_PRESSURE)
    if not isinstance(rule, dict):
        rule = DEFAULT_RUN_SKILL_PRESSURE
    reference_picks = max(1, int(rule.get("reference_card_picks", 4)))
    reference = estimate_skill_throughput(reference_picks)
    current = estimate_skill_throughput(max(1, card_picks))
    return max(1.0, (current / max(reference, 0.01)) ** POWER_SCORE_EXPONENT)


def _pressure_multiplier(card_picks: int, economy: dict, conversion_key: str, cap_key: str) -> float:
    rule = economy.get("run_skill_pressure", DEFAULT_RUN_SKILL_PRESSURE)
    if not isinstance(rule, dict):
        rule = DEFAULT_RUN_SKILL_PRESSURE
    factor = card_budget_power_factor(card_picks, economy)
    conversion = max(0.0, float(rule.get(conversion_key, DEFAULT_RUN_SKILL_PRESSURE[conversion_key])))
    cap = max(1.0, float(rule.get(cap_key, DEFAULT_RUN_SKILL_PRESSURE[cap_key])))
    return min(cap, 1.0 + max(0.0, factor - 1.0) * conversion)


def run_skill_hp_pressure(card_picks: int, economy: dict) -> float:
    return _pressure_multiplier(card_picks, economy, "hp_conversion", "max_hp_mult")


def run_skill_speed_pressure(card_picks: int, economy: dict) -> float:
    return _pressure_multiplier(card_picks, economy, "speed_conversion", "max_speed_mult")
