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
        assert .5 <= change['factor'] <= 2, '§8.2 factor out of bounds'
        expected = (round(change['old']*change['factor'],8) if parts[-1] == 'reward_gold_mult'
                    else max(0 if parts[-1] == 'gold' else 1,round(change['old']*change['factor'])))
        assert change['new'] == expected, 'declared scale factor does not derive proposed value'
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
        assert all(isinstance(x, (int, float)) and math.isfinite(x) and .5 <= x <= 2 for x in factors)
        assert all(b >= a - 1e-12 for a, b in zip(factors, factors[1:])) or all(b <= a + 1e-12 for a, b in zip(factors, factors[1:]))
    assert closure.generate(include_recovery=True) == payload['before'], 'baseline replay differs'
    with closure.candidate_tables(tables):
        after = closure.generate(include_recovery=True)
    assert after == payload['after'], 'candidate replay differs'
    assert [r['level'] for r in after['rows']] == list(range(1, 100))
    verify_farming(after, tables)
    assert input_hashes() == payload['frozen_input_sha256']
    return after


def verify_farming(after, tables):
    """Independent ledger checks, not just equality with generator output."""
    chapter_runs = {}
    earned = {'gold':0, 'xp':0, 'stars':0}
    account = campaign.Account.from_fixture()
    with closure.candidate_tables(tables):
        for row in after['rows']:
            chapter = (row['level']-1)//10+1
            used = chapter_runs.get(chapter,0)
            farm = row['farming']
            level = tables['levels'][row['level']-1]
            _, pre = campaign.build_for(account,level)
            assert pre['power'] == farm['power_before']
            assert farm['budget_available'] == 6-used
            assert farm['runs'] == len(farm['events'])
            for i,event in enumerate(farm['events'],1):
                assert campaign.build_for(account,level)[1]['power'] < row['G1_power_lower'], 'farming continued after threshold met'
                expected = closure.rewards(tables['levels'][row['level']-2],first_clear=False)
                assert event['repeat_index'] == i
                multiplier = .5 if i == 1 else .25
                expected['xp'] = math.floor(expected['xp']*multiplier+.5)
                assert event['income'] == expected and event['xp_multiplier'] == multiplier
                assert event['income']['first_clear_gold'] == event['income']['stars'] == 0
                advanced = closure.advance(account,tables['levels'][row['level']-2],level,expected)
                assert advanced == {k:v for k,v in event.items() if k not in ('repeat_index','xp_multiplier','power_after')}
                assert campaign.build_for(account,level)[1]['power'] == event['power_after']
                for key in earned:
                    earned[key] += expected[key]
            chapter_runs[chapter] = used+farm['runs']
            assert chapter_runs[chapter] == farm['chapter_runs_after'] <= 6
            assert row['cumulative_earned_before'] == earned
            assert closure.account_state(account) == row['account_before']
            assert campaign.build_for(account,level)[1]['power'] == row['power']
            assert farm['lower_met'] or chapter_runs[chapter] == 6 or row['level'] == 1
            advanced = closure.advance(account,level,tables['levels'][min(row['level'],98)],closure.rewards(level))
            assert advanced == row['progression_after_clear']
            for key in earned:
                earned[key] += row['progression_after_clear']['income'][key]
    assert sum(chapter_runs.values()) == after['total_farm_runs']
    assert {str(k):v for k,v in chapter_runs.items()} == after['chapter_farm_runs']
    assert after['walls_too_high'] == [r['level'] for r in after['rows'] if r['power'] < r['G1_power_lower']]


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
