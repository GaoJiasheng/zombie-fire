#!/usr/bin/env python3
"""§8.3: separate abstract envelope consistency from a real resource witness."""
import argparse
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))
import audit_campaign_frontline as campaign
import progression_closure as closure
import check_resource_curve_candidate as checker
from solve_runtime_clear_lines import input_hashes


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--closure", type=Path, default=ROOT / "design/audits/progression_closure_gates_before_2026_10_04.json")
    parser.add_argument("--candidate", type=Path, help="independently replay an actual bounded resource witness")
    options = parser.parse_args()
    for name in ('closure','candidate'):
        path = getattr(options,name)
        if path:
            path = (path if path.is_absolute() else ROOT / path).resolve()
            if not path.is_relative_to(ROOT / 'design/audits'):
                parser.error('feasibility inputs must stay in this worktree audits')
            setattr(options,name,path)
    table_path = ROOT / "design/audits/recommended_power_table_2026_10_04.json"
    closure_path = options.closure
    table = json.loads(table_path.read_text())
    baseline = json.loads(closure_path.read_text())
    assert baseline['frozen_input_sha256'] == input_hashes(), 'baseline inputs stale'
    assert {k:v for k,v in baseline.items() if k != 'frozen_input_sha256'} == closure.generate(), 'current-resource witness differs from fresh replay'
    candidate = checker.replay(json.loads(options.candidate.read_text())) if options.candidate else None
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
        lower = current['G1_power_lower']
        upper = (110 * envelope) // 100
        if lower > running:
            running, origin = lower, n
        conflict = running > upper
        assert lower <= envelope <= upper
        assert n == 1 or envelope >= rows[-1]["E"]
        result = {"level": n, "recommended": rec, "min_R": minimum, "max_R": maximum,
                  "E": envelope, "monotone_witness_power": envelope, "constrained": constrained,
                  "power_lower": lower, "power_upper": upper, "is_gate":current['G1_lower_exempt'],
                  "monotonic_required_power": running, "origin": origin,
                  "infeasible": conflict, "current_power": current["power"], "current_R": current["R"]}
        rows.append(result)
        if conflict:
            conflicts.append(result)
        if not current["within_G1_corridor"]:
            failures.append(n)
    witness = candidate or baseline
    feasible = not conflicts and not witness['failures']
    result = {"status": "FEASIBLE_GATE_RESOURCE_WITNESS" if feasible else "RESOURCE_WITNESS_NOT_YET_FEASIBLE", "schema_version": 4,
              "abstract_envelope_consistent": not conflicts,
              "bounded_resource_witness_proven": feasible,
              "gate_resource_witness_proven": feasible,
              "current_resource_farms": baseline['farm_gates'],
              "current_total_farms": baseline['total_farm_runs'],
              "current_walls_too_high": baseline['walls_too_high'],
              "current_gate_levels": baseline['gate_levels'],
              "current_gate_heights": baseline['gate_heights'],
              "current_non_gate_failure_levels": baseline['non_gate_failure_levels'],
              "current_non_gate_failure_count": len(baseline['non_gate_failure_levels']),
              "candidate_gate_levels": candidate['gate_levels'] if candidate else None,
              "candidate_gate_heights": candidate['gate_heights'] if candidate else None,
              "witness_non_gate_failure_count":len(witness['non_gate_failure_levels']),
              "witness_unresolved_gate_levels":witness['unresolved_gate_levels'],
              "witness_failure_levels": witness['failures'],
              "assumptions": ["existing strongest-owned-weapon policy; owned equipment is not lost",
                              "authorized monotone growth/cost/reward scaling cannot reduce acquired power",
                              "unchanged P(g), F(g), starter Lv1 attributes and account policy",
                              "T3 assumes 3-star clears; these are not runtime win results"],
              "starter_power": starter_power,
              "constrained_levels": [r["level"] for r in rows if r["constrained"]],
              "current_G1_failure_levels": failures,
              "infeasible_levels": [r["level"] for r in conflicts],
              "resources_changed": False, "resource_table_C": str(options.candidate) if options.candidate else None,
              "input_sha256": {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                               for p in (table_path, closure_path, *([options.candidate] if options.candidate else []))}, "rows": rows}
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if feasible else 1


if __name__ == "__main__":
    raise SystemExit(main())
