#!/usr/bin/env python3
"""Single-source loader for fixed-frame campaign pacing evidence.

Design/40 makes deterministic fixed-frame sweeps authoritative for rebuilt
campaign ranges.  All offline gates import this module so a range cannot be
runtime-owned in one checker and analytical in another.
"""
from __future__ import annotations

import json
import statistics
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGETS_PATH = ROOT / "data" / "campaign_pacing_targets.json"


def _scope_numbers(raw: object) -> set[int]:
    if isinstance(raw, list) and len(raw) == 2 and all(isinstance(value, int) for value in raw):
        return set(range(int(raw[0]), int(raw[1]) + 1))
    if isinstance(raw, list):
        return {int(value) for value in raw}
    return set()


def specs() -> list[dict]:
    if not TARGETS_PATH.exists():
        return []
    payload = json.loads(TARGETS_PATH.read_text(encoding="utf-8"))
    return [row for row in payload.get("runtime_contracts", []) if isinstance(row, dict)]


def spec_for_level(level_no: int) -> dict:
    for spec in specs():
        if int(level_no) in _scope_numbers(spec.get("scope", [])):
            return spec
    return {}


def clear_requirement_mode(level_no: int) -> str:
    return str(spec_for_level(level_no).get("clear_requirement_mode", "analytical_v5"))


def boss_phase_band(level_no: int) -> tuple[float, float] | None:
    spec = spec_for_level(level_no)
    for row in spec.get("boss_phase_bands", []):
        if not isinstance(row, dict) or level_no not in _scope_numbers(row.get("scope", [])):
            continue
        seconds = row.get("seconds", [])
        if isinstance(seconds, list) and len(seconds) == 2:
            return float(seconds[0]), float(seconds[1])
    return None


def boss_phase_tolerance_seconds(level_no: int) -> float:
    return float(spec_for_level(level_no).get("boss_phase_tolerance_seconds", 0.0))


def preserve_v5_requirement(
    level_no: int,
    stored: dict,
    mob_hp: float,
    boss_hp: float,
    boss_id: str | None,
) -> dict:
    """Refresh rebuilt runtime axes without inventing a new display ruler.

    B2a is still on the v5 player-facing ruler (design/40 defers the ruler
    replacement to phase C).  Fixed-frame evidence is authoritative for
    clearability, while the checked-in v5 scalar remains the stable display
    scale.  Rebuilt HP topology therefore refreshes shares and the three-axis
    contract, but does not let the retired analytical solver manufacture a
    new headline scale for these levels.
    """
    if clear_requirement_mode(level_no) != "preserve_v5_scale":
        raise ValueError(f"level_{level_no:03d} is not preserve_v5_scale")
    min_output = float(stored.get("min_output", 0.0))
    if min_output <= 0.0:
        raise ValueError(f"level_{level_no:03d}: missing v5 min_output to preserve")
    total = max(float(mob_hp) + float(boss_hp), 0.000001)
    return {
        "min_output": round(min_output, 4),
        "mob_hp_share": round(float(mob_hp) / total, 4),
        "boss_hp_share": round(float(boss_hp) / total, 4),
        "boss_id": boss_id,
    }


def load() -> tuple[set[int], dict[int, dict], list[str]]:
    runtime_levels: set[int] = set()
    contract: dict[int, dict] = {}
    errors: list[str] = []
    for spec in specs():
        name = str(spec.get("id", "runtime_contract"))
        scope = _scope_numbers(spec.get("scope", []))
        overlap = runtime_levels.intersection(scope)
        if overlap:
            errors.append(f"{name}: runtime scope overlaps {sorted(overlap)}")
        runtime_levels.update(scope)
        evidence_ref = str(spec.get("runtime_evidence", "")).strip()
        evidence_path = ROOT / evidence_ref
        if not evidence_ref or not evidence_path.exists():
            errors.append(f"{name}: runtime evidence is missing: {evidence_ref}")
            continue
        evidence = json.loads(evidence_path.read_text(encoding="utf-8"))
        expected_profile = str(spec.get("authoritative_profile", "tier_b"))
        if str(evidence.get("profile", "")) != expected_profile:
            errors.append(
                f"{name}: evidence profile {evidence.get('profile')} != {expected_profile}"
            )
        grouped: dict[int, list[dict]] = {level_no: [] for level_no in scope}
        for run in evidence.get("runs", []):
            level_no = int(run.get("level", 0))
            if level_no in grouped:
                grouped[level_no].append(run)
        expected_runs = int(spec.get("runs_per_level", 10))
        for level_no in sorted(scope):
            runs = grouped.get(level_no, [])
            if len(runs) != expected_runs:
                errors.append(
                    f"{name}: level_{level_no:03d} evidence has {len(runs)} runs, "
                    f"want {expected_runs}"
                )
                continue
            wins = sum(1 for run in runs if bool(run.get("victory", False)))
            timeouts = sum(1 for run in runs if bool(run.get("timeout", False)))
            elapsed = [float(run.get("elapsed_seconds", 0.0)) for run in runs]
            base = [float(run.get("base_ratio", 0.0)) for run in runs]
            progress = [float(run.get("max_progress", 0.0)) for run in runs]
            boss_phase = [float(run.get("boss_phase_seconds", 0.0)) for run in runs]
            contract[level_no] = {
                "contract_id": name,
                "wins": wins,
                "runs": len(runs),
                "timeouts": timeouts,
                "median_seconds": statistics.median(elapsed),
                "median_base_ratio": statistics.median(base),
                "min_base_ratio": min(base),
                "median_max_progress": statistics.median(progress),
                "median_boss_phase_seconds": statistics.median(boss_phase),
                "max_duration_seconds": float(spec.get("max_duration_seconds", 460.0)),
            }
            if wins != len(runs):
                errors.append(
                    f"{name}: level_{level_no:03d} runtime wins {wins}/{len(runs)}, "
                    f"want {len(runs)}/{len(runs)}"
                )
            if timeouts:
                errors.append(f"{name}: level_{level_no:03d} has {timeouts} timeouts")
    return runtime_levels, contract, errors


def ids() -> set[str]:
    numbers, _contract, _errors = load()
    return {f"level_{number:03d}" for number in numbers}
