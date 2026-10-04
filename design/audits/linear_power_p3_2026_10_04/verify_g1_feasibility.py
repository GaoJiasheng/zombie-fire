#!/usr/bin/env python3
"""Read-only §8.1 monotone-envelope feasibility; NOT resource sufficiency."""
import argparse
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))
import audit_campaign_frontline as campaign
import progression_closure as closure


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--closure", type=Path, default=ROOT / "design/audits/progression_closure_envelope_before_2026_10_04.json")
    options = parser.parse_args()
    table_path = ROOT / "design/audits/recommended_power_table_2026_10_04.json"
    closure_path = options.closure
    table = json.loads(table_path.read_text())
    baseline = json.loads(closure_path.read_text())
    levels = campaign.TABLES["levels"]
    assert len(levels) == len(table["rows"]) == len(baseline["rows"]) == 99
    account = campaign.Account.from_fixture()
    starter_power = campaign.build_for(account, levels[0])[1]["power"]
    selection = campaign.weapon_strategy(campaign.ACTIVE_WEAPON_STRATEGY)["selection"]
    assert selection["method"] == "power_for_build" and selection["candidates"] == "all_owned_weapons"
    running, origin = starter_power, "starter"
    envelopes = closure.g1_envelopes(levels)
    rows, conflicts, failures = [], [], []
    previous_power = 0
    for level, row, current in zip(levels, table["rows"], baseline["rows"]):
        n = row["level"]
        assert current["level"] == n and current["recommended"] == row["recommended_power"]
        assert current["power"] >= previous_power
        previous_power = current["power"]
        envelope = envelopes[n]
        constrained = closure.g1_constrained(level)
        minimum, maximum = closure.g1_bounds(level, True, envelope)
        rec = row["recommended_power"]
        # Exact integer arithmetic: displayed effective power is integer.
        lower = rec if constrained else (95 * rec + 99) // 100
        upper = (110 * envelope) // 100
        if lower > running:
            running, origin = lower, n
        conflict = running > upper
        assert lower <= envelope <= upper
        assert n == 1 or envelope >= rows[-1]["E"]
        result = {"level": n, "recommended": rec, "min_R": minimum, "max_R": maximum,
                  "E": envelope, "monotone_witness_power": envelope, "constrained": constrained,
                  "power_lower": lower, "power_upper": upper,
                  "monotonic_required_power": running, "origin": origin,
                  "infeasible": conflict, "current_power": current["power"], "current_R": current["R"]}
        rows.append(result)
        if conflict:
            conflicts.append(result)
        if not current["within_G1_corridor"]:
            failures.append(n)
    result = {"status": "FEASIBLE_MONOTONE_ENVELOPE" if not conflicts else "CONTRACT_CONFLICT", "schema_version": 2,
              "assumptions": ["existing strongest-owned-weapon policy; owned equipment is not lost",
                              "authorized monotone growth/cost/reward scaling cannot reduce acquired power",
                              "unchanged P(g), F(g), starter Lv1 attributes and account policy",
                              "T3 assumes 3-star clears; these are not runtime win results"],
              "starter_power": starter_power,
              "constrained_levels": [r["level"] for r in rows if r["constrained"]],
              "current_G1_failure_levels": failures,
              "infeasible_levels": [r["level"] for r in conflicts],
              "resources_changed": False, "resource_table_C": None,
              "input_sha256": {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                               for p in (table_path, closure_path)}, "rows": rows}
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 1 if conflicts else 0


if __name__ == "__main__":
    raise SystemExit(main())
