#!/usr/bin/env python3
"""Shared Python mirror of the data-owned fire-rate laboratory profiles.

The shipping game remains hard-locked to ``control``.  Tier A/B are analysis
profiles exposed only by the TestFlight custom feature.  Keep arithmetic in
this module aligned with ``core/combat/fire_rate_profiles.gd`` so audits and
runtime never invent separate caps or compensation rules.
"""

from __future__ import annotations


DEFAULT_PROFILE_ID = "control"


def table(economy: dict) -> dict:
    value = economy.get("fire_rate_profiles", {})
    return value if isinstance(value, dict) else {}


def profile_ids(economy: dict) -> list[str]:
    rows = table(economy)
    profiles = rows.get("profiles", {})
    result = [
        str(profile_id)
        for profile_id in rows.get("order", [])
        if str(profile_id) in profiles
    ]
    return result or [DEFAULT_PROFILE_ID]


def profile(economy: dict, profile_id: str) -> dict:
    rows = table(economy)
    profiles = rows.get("profiles", {})
    default_id = str(rows.get("default", DEFAULT_PROFILE_ID))
    resolved = profile_id if profile_id in profiles else default_id
    value = profiles.get(resolved, profiles.get(DEFAULT_PROFILE_ID, {}))
    return value if isinstance(value, dict) else {}


def salvo_multiplier(
    economy: dict,
    profile_id: str,
    level: int,
    fallback: float = 1.0,
) -> float:
    if level <= 0:
        return 1.0
    values = profile(economy, profile_id).get("salvo_fire_rate_mult", [])
    if not values:
        return fallback
    index = max(0, min(level - 1, len(values) - 1))
    return 1.0 + float(values[index])


def chip_multiplier(
    economy: dict,
    profile_id: str,
    intrinsic_value: float,
    level: int,
) -> float:
    row = profile(economy, profile_id)
    intrinsic_scale = float(row.get("chip_intrinsic_scale", 1.0))
    level_bonus = float(row.get("chip_level_bonus_per_level", 0.01))
    return (1.0 + intrinsic_value * intrinsic_scale) * (
        1.0 + level_bonus * max(level - 1, 0)
    )


def pet_multiplier(economy: dict, profile_id: str, stat_value: float) -> float:
    scale = float(profile(economy, profile_id).get("pet_fire_rate_scale", 1.0))
    return 1.0 + stat_value * scale


def barrage_multiplier(
    economy: dict,
    profile_id: str,
    active: dict,
    character_level: int,
    growth_rank: int,
    signature_level: int,
) -> float:
    row = profile(economy, profile_id)
    authored_base = float(active.get("barrage_fire_rate_mult", 1.0))
    base = float(row.get("barrage_fire_rate_mult", authored_base))
    rank_bonus = float(
        row.get("barrage_rank_bonus", active.get("rank_fire_rate_bonus", 0.0))
    ) * growth_rank
    level_scale = float(row.get("barrage_level_growth_scale", 1.0))
    level_bonus = (
        float(active.get("level_fire_rate_growth", 0.0))
        * max(character_level - 1, 0)
        * level_scale
    )
    signature_bonus = (
        float(active.get("sig_level_fire_rate_bonus", 0.0))
        * signature_level
        * level_scale
    )
    return max(1.0, base + rank_bonus + level_bonus + signature_bonus)


def overload_multiplier(economy: dict, profile_id: str) -> float:
    return max(
        1.0,
        float(profile(economy, profile_id).get("overload_fire_rate_mult", 1.5)),
    )


def capped_fire_rate(
    economy: dict,
    profile_id: str,
    raw_fire_rate: float,
    authored_weapon_base: float,
) -> float:
    cap_ratio = float(profile(economy, profile_id).get("global_weapon_base_cap", 0.0))
    if cap_ratio <= 0.0:
        return raw_fire_rate
    return min(raw_fire_rate, max(authored_weapon_base, 0.01) * cap_ratio)


def shot_damage_compensation(
    economy: dict,
    profile_id: str,
    control_fire_rate: float,
    actual_fire_rate: float,
) -> float:
    share = float(profile(economy, profile_id).get("removed_dps_compensation", 0.0))
    if share <= 0.0 or actual_fire_rate <= 0.0 or control_fire_rate <= actual_fire_rate:
        return 1.0
    return 1.0 + (control_fire_rate / actual_fire_rate - 1.0) * share


def per_shot_status_normalization(
    control_fire_rate: float,
    actual_fire_rate: float,
) -> float:
    if actual_fire_rate <= 0.0:
        return 1.0
    return control_fire_rate / actual_fire_rate
