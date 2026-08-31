#!/usr/bin/env python3
"""Generate fixed-frame challenge builds from the owner-approved fixture routes."""

from __future__ import annotations

import json
from pathlib import Path

from power_ruler_model import maxed_free_build_for_level, skill_max_level

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
AUDIT = ROOT / "design" / "audits"
CAMPAIGN_FIXTURE = AUDIT / "campaign_progression_fixture_builds.json"
REFERENCE_OUTPUT = AUDIT / "challenge_reference_fixture_builds.json"
FREE_OUTPUT = AUDIT / "challenge_free_counterexample_fixture_builds.json"
SEEDS = [1103, 2207, 3301, 4409, 5513, 6637, 7741, 8849, 9901, 10903]


def load(name: str):
    return json.loads((DATA / f"{name}.json").read_text(encoding="utf-8"))


def clone_row(level: dict, build: dict, source: str) -> dict:
    return {
        "level": int(level["id"].split("_")[-1]),
        "level_id": level["id"],
        "fixture_source": source,
        "resources_before": {"gold": 0, "xp": 0, "stars": 0},
        "card_seeds": SEEDS,
        "build": build,
    }


def main() -> int:
    levels = load("levels")
    tables = [load(name) for name in ("characters", "weapons", "armors", "chips", "pets", "skills", "bosses", "economy")]
    campaign_rows = {int(row["level"]): row for row in json.loads(CAMPAIGN_FIXTURE.read_text(encoding="utf-8"))["rows"]}
    all_skills = {skill_id: skill_max_level(row) for skill_id, row in tables[5].items()}
    paid_build = {
        "character": "vanguard", "character_level": 40,
        "weapon": "weapon_apocalypse_golden_law", "weapon_level": 65,
        "armor": "armor_apocalypse_eternal_night", "armor_level": 35,
        "chip": "chip_apocalypse_golden_law", "chip_level": 35,
        "pet": "pet_apocalypse_skyfalcon", "pet_level": 30,
        "signature_level": 5, "skill_base_levels": all_skills,
        "fire_rate_profile": "tier_b",
    }
    reference_rows = []
    free_rows = []
    for level_number, level in enumerate(levels, start=1):
        contract = level.get("clear_requirement", {}).get("power_contract", {})
        free_build, _ = maxed_free_build_for_level(level, contract, *tables, fire_rate_profile_id="tier_b")
        free_rows.append(clone_row(level, free_build, "maxed_free_matchup_aware_v1"))
        if level_number <= 60:
            source = campaign_rows[level_number + 10]
            reference_rows.append(clone_row(level, dict(source["build"]), f"paced_plus_10:level_{level_number + 10:03d}"))
        elif level_number <= 80:
            reference_rows.append(clone_row(level, free_build, "maxed_free_matchup_aware_v1"))
        else:
            reference_rows.append(clone_row(level, dict(paid_build), "golden_law_tier_1_max:1.556x"))
    common = {"schema_version": 1, "fire_rate_profile": "tier_b", "card_policy": "v2", "seeds": SEEDS}
    REFERENCE_OUTPUT.write_text(json.dumps({**common, "rows": reference_rows}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    FREE_OUTPUT.write_text(json.dumps({**common, "rows": free_rows}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Generated {len(reference_rows)} challenge reference rows and {len(free_rows)} free counterexamples")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
