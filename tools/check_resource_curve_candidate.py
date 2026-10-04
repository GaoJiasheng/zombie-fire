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
    assert payload['contract'] == 'design/41 section 8.4', 'stale resource contract'
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
        assert .5 <= change['factor'] <= 2, '§8.4 factor out of bounds'
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
    verify_curve_application(payload, tables)
    assert closure.generate(include_recovery=True) == payload['before'], 'baseline replay differs'
    with closure.candidate_tables(tables):
        after = closure.generate(include_recovery=True)
    assert after == payload['after'], 'candidate replay differs'
    assert [r['level'] for r in after['rows']] == list(range(1, 100))
    verify_farming(after, tables)
    assert input_hashes() == payload['frozen_input_sha256']
    return after


def verify_curve_application(payload, tables):
    """Independently reconstruct every allowed field, including unchanged rows.

    A declared common factor must actually apply to ALL eight free weapons.
    The price ratio can differ slightly due to integer rounding, not because
    separate factors were smuggled into field changes.
    """
    curves = {c['name']: c for c in payload['curves']}
    assert len(curves) == len(payload['curves']) == 6
    assert set(curves) == {'first_clear_gold', 'kill_gold_mult', 'free_unlock_star',
                           'skill_base_xp_costs', 'sig_skill_xp_costs', 'free_weapon_cost'}
    base = campaign.TABLES
    weapons = [key for key, row in base['weapons'].items()
               if not row.get('premium_set') and not row.get('premium_entitlement')]
    common = curves['free_weapon_cost']
    assert common['members'] == weapons and len(weapons) == 8
    expected_factors = {}
    for key in weapons:
        assert tables['weapons'][key]['cost_base_gold'] == max(1, round(base['weapons'][key]['cost_base_gold'] * common['factor']))
        expected_factors[('data/weapons.json', '/'+key+'/cost_base_gold')] = common['factor']
    star = curves['free_unlock_star']['factor']
    for slot in ('weapons', 'armors', 'chips', 'pets'):
        for key, original in base[slot].items():
            if original.get('premium_set') or original.get('premium_entitlement'):
                assert tables[slot][key] == original
                continue
            cost = original.get('unlock_cost_star', 0)
            assert tables[slot][key].get('unlock_cost_star', 0) == (max(1, round(cost*star)) if cost else cost)
            expected_factors[(f'data/{slot}.json', '/'+key+'/unlock_cost_star')] = star
    for field in ('skill_base_xp_costs', 'sig_skill_xp_costs'):
        factors = curves[field]['factors']
        assert len(factors) == 5
        assert tables['economy'][field] == [max(1, round(old*f)) for old, f in zip(base['economy'][field], factors)]
        for i, factor in enumerate(factors):
            expected_factors[('data/economy.json', f'/{field}/{i}')] = factor
    for name, field in (('first_clear_gold', 'first_clear_reward/gold'), ('kill_gold_mult', 'reward_gold_mult')):
        curve, factors = curves[name], curves[name]['factors']
        assert len(factors) == 99
        assert all(abs(f-math.exp(curve['log_scale']+curve['log_slope']*i/98)) < 1e-12 for i, f in enumerate(factors))
        for i, (old, new, factor) in enumerate(zip(base['levels'], tables['levels'], factors)):
            if name == 'first_clear_gold':
                assert new['first_clear_reward']['gold'] == max(0, round(old['first_clear_reward']['gold']*factor))
            else:
                assert new[field] == round(old[field]*factor, 8)
            expected_factors[('data/levels.json', f'/{i}/{field}')] = factor
    for change in payload['changes']:
        assert change['factor'] == expected_factors[(change['file'], change['pointer'])], 'individual field factor differs from its ONE curve'


def verify_farming(after, tables):
    """Independent ledger checks, not just equality with generator output."""
    chapter_runs, claimed, normal_counts = {}, set(), {}
    gates, heights, total_gate_runs, total_runs = [], [], 0, 0
    earned = {'gold':0, 'xp':0, 'stars':0}
    envelope, passed_gates = 65, []
    account = campaign.Account.from_fixture()
    with closure.candidate_tables(tables):
        for row in after['rows']:
            chapter = (row['level']-1)//10+1
            used = chapter_runs.get(chapter,0)
            farm = row['farming']
            level = tables['levels'][row['level']-1]
            _, pre = campaign.build_for(account,level)
            rec = int(level['clear_requirement']['power_contract']['recommended_power'])
            envelope = max(envelope, rec)
            # Integer independent proof of the 2026-10-04 1.20E contract.
            assert row['E'] == envelope and row['recommended'] == rec
            assert row['G1_power_upper'] == (120*envelope)//100
            target = rec if farm['is_gate'] or closure.g1_constrained(level) else (95*rec+99)//100
            assert farm['lower'] == row['clear_target_power_lower'] == target
            assert row['conditional_on_passed_gates'] == passed_gates
            assert pre['power'] == farm['power_before']
            assert farm['budget_available'] == 6-used
            assert farm['runs'] == len(farm['events'])
            for event in farm['events']:
                assert campaign.build_for(account,level)[1]['power'] < row['clear_target_power_lower'], 'farming continued after threshold met'
                eligible = [n for n in range(1,row['level']) if n not in claimed]
                source = max(eligible) if eligible else row['level']-1
                challenge = bool(eligible)
                assert source >= 1 and event['farm_level'] == source
                assert event['mode'] == ('challenge_first_clear' if challenge else 'normal_repeat')
                count = 0 if challenge else normal_counts.get(source,0)+1
                assert event['clear_count_before'] == count
                full = closure.rewards(tables['levels'][source-1],first_clear=False)
                expected = {**full, 'stars':3 if challenge else 0}
                multipliers = tables['economy']['repeat_clear_xp_mult']
                multiplier = float(multipliers[min(count,len(multipliers)-1)])
                expected['xp'] = math.floor(expected['xp']*multiplier+.5)
                assert event['income'] == expected and event['xp_multiplier'] == multiplier
                assert event['income']['first_clear_gold'] == 0
                if challenge:
                    assert source not in claimed
                    claimed.add(source)
                else:
                    normal_counts[source] = count
                advanced = closure.advance(account,tables['levels'][source-1],level,expected)
                assert advanced == {k:v for k,v in event.items() if k not in ('mode','farm_level','clear_count_before','xp_multiplier','power_after')}
                assert campaign.build_for(account,level)[1]['power'] == event['power_after']
                for key in earned:
                    earned[key] += expected[key]
            lower_met = campaign.build_for(account,level)[1]['power'] >= row['clear_target_power_lower']
            assert farm['lower_met'] == lower_met
            promoted = row['level'] not in closure.FIXED_GATE_LEVELS and farm['is_gate']
            if promoted:
                assert farm['runs'] > 6-used or (not lower_met and farm['runs'] == 6-used)
            assert farm['is_gate'] == (row['level'] in closure.FIXED_GATE_LEVELS or promoted)
            assert row['G1_lower_exempt'] == farm['is_gate']
            assert farm['non_gate_runs'] == (0 if farm['is_gate'] else farm['runs'])
            assert farm['gate_runs'] == (farm['runs'] if farm['is_gate'] else 0)
            chapter_runs[chapter] = used+farm['non_gate_runs']
            assert chapter_runs[chapter] == farm['chapter_runs_after'] <= 6
            total_runs += farm['runs']
            total_gate_runs += farm['gate_runs']
            if farm['is_gate']:
                gates.append(row['level'])
                assert farm['gate_height'] == (farm['runs'] if lower_met else None)
                assert farm['gate_resolved'] == lower_met
                if lower_met:
                    assert row['power'] >= rec, 'passed gate must reach R>=1'
                    passed_gates.append(row['level'])
            assert row['cumulative_earned_before'] == earned
            assert closure.account_state(account) == row['account_before']
            assert campaign.build_for(account,level)[1]['power'] == row['power']
            assert farm['lower_met'] or farm['unresolved_reason'] is not None
            assert row['farm_route_before_clear']['challenge_cleared'] == [e['farm_level'] for r in after['rows'][:row['level']] for e in r['farming']['events'] if e['mode']=='challenge_first_clear']
            assert row['farm_route_before_clear']['normal_repeats'] == {str(k):v for k,v in normal_counts.items()}
            assert row['G1_power_lower'] == (0 if farm['is_gate'] else row['clear_target_power_lower'])
            assert row['within_G1_corridor'] == (lower_met and row['power'] <= row['G1_power_upper'])
            advanced = closure.advance(account,level,tables['levels'][min(row['level'],98)],closure.rewards(level))
            assert advanced == row['progression_after_clear']
            for key in earned:
                earned[key] += row['progression_after_clear']['income'][key]
    assert total_runs == after['total_farm_runs']
    assert total_gate_runs == after['gate_farm_runs']
    assert sum(chapter_runs.values()) == after['non_gate_farm_runs']
    assert {str(k):v for k,v in chapter_runs.items()} == after['chapter_farm_runs']
    assert gates == after['gate_levels']
    assert sorted(claimed) == sorted(after['challenge_first_clears'])
    assert after['walls_too_high'] == [n for n in gates if n not in closure.FIXED_GATE_LEVELS]
    assert after['unresolved_gate_levels'] == [r['level'] for r in after['rows'] if r['G1_lower_exempt'] and not r['farming']['gate_resolved']]
    assert after['non_gate_failure_levels'] == [r['level'] for r in after['rows'] if not r['G1_lower_exempt'] and not r['within_G1_corridor']]


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
