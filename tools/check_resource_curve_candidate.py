#!/usr/bin/env python3
"""Replay table C on a memory copy; reject stale inputs and unauthorized writes."""
import argparse
import copy
import json
import math
from pathlib import Path

import audit_campaign_frontline as campaign
import progression_closure as closure
from solve_runtime_clear_lines import input_hashes


def replay(payload):
    assert payload['game_data_written'] is False
    assert payload['frozen_input_sha256'] == input_hashes(), 'candidate inputs are stale'
    tables = copy.deepcopy(campaign.TABLES)
    seen = set()
    allowed = {
        'levels': ('first_clear_reward/gold', 'reward_gold_mult'),
        'economy': ('skill_base_xp_costs', 'sig_skill_xp_costs'),
        'weapons': ('unlock_cost_star', 'cost_base_gold'),
        'armors': ('unlock_cost_star',), 'chips': ('unlock_cost_star',), 'pets': ('unlock_cost_star',),
    }
    for change in payload['changes']:
        table = Path(change['file']).stem
        assert change['file'] == f'data/{table}.json' and table in allowed
        parts = change['pointer'].strip('/').split('/')
        assert parts and (table, change['pointer']) not in seen
        seen.add((table, change['pointer']))
        if table == 'levels':
            assert '/'.join(parts[1:]) in allowed[table]
        elif table == 'economy':
            assert parts[0] in allowed[table] and len(parts) == 2
        else:
            assert len(parts) == 2 and parts[1] in allowed[table]
            original = campaign.TABLES[table][parts[0]]
            assert not original.get('premium_set') and not original.get('premium_entitlement')
        parent = tables[table]
        for part in parts[:-1]:
            parent = parent[int(part)] if isinstance(parent, list) else parent[part]
        key = int(parts[-1]) if isinstance(parent, list) else parts[-1]
        assert parent[key] == change['old'], f'old value mismatch: {change}'
        assert math.isfinite(change['new']) and change['new'] >= 0
        parent[key] = change['new']
    for name in ('skill_base_xp_costs', 'sig_skill_xp_costs'):
        costs = tables['economy'][name]
        assert len(costs) == 5 and all(isinstance(x, int) and x > 0 for x in costs)
        assert all(b >= a for a, b in zip(costs, costs[1:]))
    gold = [r['first_clear_reward']['gold'] for r in tables['levels']]
    multipliers = [r['reward_gold_mult'] for r in tables['levels']]
    assert all(b >= a for a,b in zip(gold,gold[1:])), 'first-clear gold must retain increasing direction'
    assert all(b <= a for a,b in zip(multipliers,multipliers[1:])), 'kill-gold multiplier must retain decreasing direction'
    for curve in payload['curves']:
        factors = curve.get('factors', [curve.get('factor')])
        assert all(isinstance(x, (int, float)) and math.isfinite(x) and x > 0 for x in factors)
        assert all(b >= a - 1e-12 for a, b in zip(factors, factors[1:])) or all(b <= a + 1e-12 for a, b in zip(factors, factors[1:]))
    assert closure.generate(include_recovery=False) == payload['before'], 'baseline replay differs'
    with closure.candidate_tables(tables):
        after = closure.generate(include_recovery=False)
    assert after == payload['after'], 'candidate replay differs'
    assert [r['level'] for r in after['rows']] == list(range(1, 100))
    assert input_hashes() == payload['frozen_input_sha256']
    return after


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('table', type=Path)
    args = parser.parse_args()
    after = replay(json.loads(args.table.read_text()))
    print(f"REPLAY PASS: 99 rows, authorized fields, frozen inputs, exact builds/resources/power; G1 failures={after['failures']}")
    if after['failures']:
        print('G1 FAIL: this candidate must not be written as an approved feasible resource table')
        return 1
    print('G1 PASS: all 99 constraints; still requires Fable gate C approval')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
