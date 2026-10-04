#!/usr/bin/env python3
"""Gate C candidate only: smooth multiplicative resources, frozen ruler/enemies.

All evaluations are in-memory T3 simulations. No data/ writer exists here.
Continuous log-linear factors are monotone; original data types, tier count,
item caps, currency types and account spending policy are retained.
"""
from __future__ import annotations

import argparse
import copy
import datetime as dt
from functools import lru_cache
import hashlib
import json
import math
from pathlib import Path
import time

import numpy as np
from scipy.optimize import differential_evolution

import audit_campaign_frontline as campaign
import progression_closure as closure
import power_ruler_model as ruler
from power_scale_v6 import PowerScaleV6
from solve_runtime_clear_lines import atomic_write, input_hashes

ROOT = campaign.ROOT
DATE = dt.datetime.now(dt.timezone(dt.timedelta(hours=8))).strftime('%Y_%m_%d')


def smooth_factors(length: int, log_scale: float, log_slope: float) -> list[float]:
    return [math.exp(log_scale + log_slope * i / max(length - 1, 1)) for i in range(length)]


def parameters(tables: dict, xp_directions: dict | None = None) -> list[dict]:
    specs = [
        {'name': 'first_clear_gold.log_scale', 'bounds': [-3, 2]},
        {'name': 'first_clear_gold.log_slope', 'bounds': [-3, 3]},
        {'name': 'kill_gold_mult.log_scale', 'bounds': [-3, 2]},
        {'name': 'kill_gold_mult.log_slope', 'bounds': [-3, 3]},
        {'name': 'free_unlock_star.log_scale', 'bounds': [-1, 1]},
        {'name': 'skill_base_xp_costs.log_scale', 'bounds': [-2, 2]},
        {'name': 'skill_base_xp_costs.log_slope', 'bounds': [-2, 3]},
        {'name': 'sig_skill_xp_costs.log_scale', 'bounds': [-2, 2]},
        {'name': 'sig_skill_xp_costs.log_slope', 'bounds': [-2, 3]},
    ]
    specs += [{'name': f'weapon_cost.{key}.log_scale', 'bounds': [-3, 3]}
              for key, row in tables['weapons'].items() if not row.get('premium_set') and not row.get('premium_entitlement')]
    if xp_directions:
        specs = [s for s in specs if not s['name'].startswith(('skill_base_xp_costs.', 'sig_skill_xp_costs.'))]
        specs += [{'name': f'{f}.knot_{i}', 'bounds': [-4, 3], 'direction': direction}
                  for f, direction in xp_directions.items() for i in range(5)]
    return specs


def candidate(base: dict, specs: list[dict], vector) -> tuple[dict, list[dict], list[dict]]:
    tables = copy.deepcopy(base)
    if len(vector) != len(specs) or any(not math.isfinite(float(v)) or not s['bounds'][0] <= float(v) <= s['bounds'][1] for s,v in zip(specs,vector)):
        raise ValueError('vector must match this curve family and its finite bounds')
    values = dict(zip((s['name'] for s in specs), map(float, vector)))
    changes, curves = [], []
    def patch(file, pointer, old, new, factor):
        if old != new:
            changes.append({'file': file, 'pointer': pointer, 'old': old, 'new': new, 'factor': factor})
    for family, field in [('first_clear_gold', 'gold'), ('kill_gold_mult', 'reward_gold_mult')]:
        a, b = values[family+'.log_scale'], values[family+'.log_slope']
        factors = smooth_factors(len(tables['levels']), a, b)
        curves.append({'name': family, 'shape': 'existing authored per-level values × exp(a+b*(L-1)/98)',
                       'log_scale': a, 'log_slope': b, 'factors': factors,
                       'factor_direction': 'nondecreasing' if b >= 0 else 'nonincreasing'})
        for i, (old, new, factor) in enumerate(zip(base['levels'], tables['levels'], factors)):
            if field == 'gold':
                value = max(0, round(old['first_clear_reward']['gold'] * factor))
                new['first_clear_reward']['gold'] = value
                patch('data/levels.json', f'/{i}/first_clear_reward/gold', old['first_clear_reward']['gold'], value, factor)
            else:
                value = round(old[field] * factor, 8)
                new[field] = value
                patch('data/levels.json', f'/{i}/{field}', old[field], value, factor)
    star_factor = math.exp(values['free_unlock_star.log_scale'])
    curves.append({'name': 'free_unlock_star', 'shape': 'existing free star tiers × constant', 'factor': star_factor})
    for slot in ('weapons', 'armors', 'chips', 'pets'):
        for key, old in base[slot].items():
            if old.get('premium_set') or old.get('premium_entitlement'):
                continue
            cost = int(old.get('unlock_cost_star', 0))
            if cost:
                new = max(1, round(cost * star_factor))
                tables[slot][key]['unlock_cost_star'] = new
                patch(f'data/{slot}.json', '/'+key+'/unlock_cost_star', cost, new, star_factor)
    for field in ('skill_base_xp_costs', 'sig_skill_xp_costs'):
        if field+'.knot_0' in values:
            direction = next(s['direction'] for s in specs if s['name'] == field+'.knot_0')
            logs = sorted([values[f'{field}.knot_{i}'] for i in range(5)], reverse=direction < 0)
            factors = [math.exp(v) for v in logs]
            curve = {'name':field, 'shape':'same five authored cost tiers times positive monotone factors',
                     'interpolation':'five rank knots admit C1 monotone log-factor interpolation; runtime still directly indexes the same five tiers',
                     'factors':factors, 'direction':direction}
        else:
            a, b = values[field+'.log_scale'], values[field+'.log_slope']
            factors = smooth_factors(len(base['economy'][field]), a, b)
            curve = {'name': field, 'shape': 'existing 5 cost tiers × exp(a+b*(rank-1)/4)',
                     'log_scale': a, 'log_slope': b, 'factors': factors}
        costs = [max(1, round(cost * factor)) for cost, factor in zip(base['economy'][field], factors)]
        if any(right < left for left, right in zip(costs, costs[1:])):
            raise ValueError('scaled XP tiers must remain nondecreasing')
        curves.append(curve)
        for i, (old, new, factor) in enumerate(zip(base['economy'][field], costs, factors)):
            patch('data/economy.json', f'/{field}/{i}', old, new, factor)
        tables['economy'][field] = costs
    for key, old in base['weapons'].items():
        name = f'weapon_cost.{key}.log_scale'
        if name not in values:
            continue
        factor = math.exp(values[name])
        cost = max(1, round(old['cost_base_gold'] * factor))
        tables['weapons'][key]['cost_base_gold'] = cost
        curves.append({'name': 'weapon_cost.'+key, 'shape': 'same existing linear upgrade formula × constant base cost', 'factor': factor})
        patch('data/weapons.json', '/'+key+'/cost_base_gold', old['cost_base_gold'], cost, factor)
    # Preserve the authored monotone direction after scaling as well as the
    # factor's own monotonicity. Rounding may create plateaus, not reversals.
    for field in ('gold','reward_gold_mult'):
        old = [r['first_clear_reward']['gold'] if field=='gold' else r[field] for r in base['levels']]
        new = [r['first_clear_reward']['gold'] if field=='gold' else r[field] for r in tables['levels']]
        if all(b >= a for a,b in zip(old,old[1:])) and any(b < a for a,b in zip(new,new[1:])):
            raise ValueError('scaled reward curve reverses authored increasing direction')
        if all(b <= a for a,b in zip(old,old[1:])) and any(b > a for a,b in zip(new,new[1:])):
            raise ValueError('scaled reward curve reverses authored decreasing direction')
    return tables, changes, curves


def metrics(payload: dict) -> dict:
    violations = []
    for row in payload['rows']:
        lo, hi, power, envelope = row['G1_power_lower'], row['G1_power_upper'], row['power'], row['E']
        residual = max(lo-power, power-hi, 0) / envelope
        if residual:
            violations.append({'level': row['level'], 'power': power, 'lower': lo, 'upper': hi, 'residual': residual})
    return {'objective': payload['envelope_objective'], 'violation_count': len(violations),
            'violation_l1': sum(v['residual'] for v in violations),
            'violation_l2_squared': sum(v['residual']**2 for v in violations),
            'max_violation': max((v['residual'] for v in violations), default=0), 'violations': violations}


class Search:
    def __init__(self, base, specs, checkpoint):
        self.base, self.specs, self.checkpoint = base, specs, checkpoint
        self.evaluations = 0
        self.best = None
        self.started = time.monotonic()
        self.fingerprint = hashlib.sha256(json.dumps({'inputs':input_hashes(),'parameters':specs},sort_keys=True).encode()).hexdigest()
        # Resource-price changes cannot alter pure-build axes. Cache the exact
        # frozen model calculation, not a regression or surrogate prediction.
        model = PowerScaleV6.build_from_fixture()
        original = model.effective_power_for_build
        @lru_cache(maxsize=150000)
        def cached(key):
            return original(json.loads(key))
        model.effective_power_for_build = lambda build: cached(json.dumps(build, sort_keys=True))
        ruler._POWER_SCALE_V6_CACHE = model

    def evaluate(self, vector):
        self.evaluations += 1
        try:
            tables, _, _ = candidate(self.base, self.specs, vector)
            with closure.candidate_tables(tables):
                payload = closure.generate(include_recovery=False)
            result = metrics(payload)
        except ValueError:
            return 1e12
        # Constraints dominate objective; both are reported separately.
        score = (1e5 * result['violation_l2_squared'] + 1e4 * result['max_violation']
                 + 100 * result['violation_l1'] + result['violation_count'] + .01 * result['objective'])
        if self.best is None or score < self.best['score']:
            self.best = {'score': score, 'vector': list(map(float, vector)), 'metrics': result,
                         'evaluation': self.evaluations, 'fingerprint':self.fingerprint}
            atomic_write(self.checkpoint, self.best)
            print(f"best eval={self.evaluations} violations={result['violation_count']} l1={result['violation_l1']:.6f} objective={result['objective']:.6f} wall={time.monotonic()-self.started:.1f}s", flush=True)
        return score

    def polish(self, rounds):
        """Deterministic coordinate refinement on the exact discrete simulator."""
        for _ in range(rounds):
            for step in (.25, .08, .02, .005):
                for i,spec in enumerate(self.specs):
                    for sign in (-1,1):
                        vector = list(self.best['vector'])
                        vector[i] = min(max(vector[i] + sign*step,spec['bounds'][0]),spec['bounds'][1])
                        self.evaluate(vector)


def render(payload):
    lines = [f"状态：{payload['status']}；待Fable签字，游戏数据未写入。", '', '# 资源表 C 候选', '',
             '离线假定3★首通、不刷关；不是新运行时胜率。既有账户策略与P(g)/F(g)冻结。',
             f"优化前：{len(payload['before']['failures'])}/99失败，目标{payload['before_metrics']['objective']:.6f}。",
             f"优化后：{len(payload['after']['failures'])}/99失败，目标{payload['after_metrics']['objective']:.6f}。", '',
             '缩放系数与逐字段旧/新对照完整列于同名JSON；所有候选仅在内存模拟。', '',
             '|曲线|缩放系数/形式|', '|---|---|']
    for curve in payload['curves']:
        coefficient = curve.get('factor', curve.get('factors') if 'direction' in curve else [curve.get('log_scale'),curve.get('log_slope')])
        lines.append(f"|{curve['name']}|{coefficient}；{curve['shape']}|")
    lines += ['', '|文件/字段|旧值|候选新值|系数|', '|---|---:|---:|---:|']
    for c in payload['changes']:
        lines.append(f"|{c['file']}{c['pointer']}|{c['old']}|{c['new']}|{c['factor']:.8g}|")
    lines += ['', '|关卡|rec|E|旧P|新P|新R|新P/E|下限|上限|达标|', '|---|---:|---:|---:|---:|---:|---:|---:|---:|---|']
    for old, new in zip(payload['before']['rows'], payload['after']['rows']):
        lines.append(f"|{new['level']:03d}|{new['recommended']}|{new['E']}|{old['power']}|{new['power']}|{new['R']:.4f}|{new['power_over_E']:.4f}|{new['G1_power_lower']}|{new['G1_power_upper']}|{new['within_G1_corridor']}|")
    return '\n'.join(lines)+'\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--iterations', type=int, default=80)
    parser.add_argument('--population', type=int, default=5)
    parser.add_argument('--seed', type=int, default=41004)
    parser.add_argument('--resume', action='store_true')
    parser.add_argument('--output', type=Path, default=ROOT / f'design/audits/resource_curve_table_{DATE}')
    parser.add_argument('--checkpoint', type=Path, default=Path(f'/tmp/zf_linear_resource_search_{DATE}.json'))
    parser.add_argument('--vector', type=Path, help='evaluate saved vector/checkpoint only; no search')
    parser.add_argument('--xp-base-direction', choices=('up','down'))
    parser.add_argument('--xp-sig-direction', choices=('up','down'))
    parser.add_argument('--polish-rounds', type=int, default=0)
    args = parser.parse_args()
    if not args.output.resolve().is_relative_to(ROOT / 'design/audits'):
        parser.error('candidate outputs must remain in this worktree design/audits')
    if bool(args.xp_base_direction) != bool(args.xp_sig_direction):
        parser.error('both XP directions are required for the five-knot family')
    frozen = input_hashes()
    tool_hash = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    base = copy.deepcopy(campaign.TABLES)
    directions = {'skill_base_xp_costs':1 if args.xp_base_direction=='up' else -1,
                  'sig_skill_xp_costs':1 if args.xp_sig_direction=='up' else -1} if args.xp_base_direction else None
    specs = parameters(base,directions)
    before = closure.generate(include_recovery=False)
    search = Search(base, specs, args.checkpoint)
    initial = np.zeros(len(specs))
    if args.vector or (args.resume and args.checkpoint.exists()):
        saved = json.loads((args.vector or args.checkpoint).read_text())
        if args.vector and saved.get('frozen_input_sha256',frozen) != frozen:
            parser.error('vector source was derived against different game inputs')
        if args.resume and not args.vector and saved.get('fingerprint') != search.fingerprint:
            parser.error('resume checkpoint has stale inputs or a different/unsealed curve family; use explicit --vector for a fresh replay')
        initial = np.array(saved['vector'])
    search.evaluate(initial)
    if args.vector and search.best is None:
        parser.error('explicit vector violates curve shape, length or bounds')
    if not args.vector:
        differential_evolution(search.evaluate, [s['bounds'] for s in specs], seed=args.seed,
                               maxiter=args.iterations, popsize=args.population, x0=initial,
                               workers=1, updating='immediate', polish=False, tol=0, atol=0)
    if args.polish_rounds:
        search.polish(args.polish_rounds)
    tables, changes, curves = candidate(base, specs, search.best['vector'])
    with closure.candidate_tables(tables):
        after = closure.generate(include_recovery=False)
    after_metrics = metrics(after)
    assert frozen == input_hashes(), 'candidate evaluation changed frozen disk inputs'
    payload = {'schema_version': 1, 'status': 'CANDIDATE_FEASIBLE_AWAITING_GATE_C' if not after_metrics['violation_count'] else 'SEARCH_CANDIDATE_NOT_YET_FEASIBLE',
               'contract': 'design/41 section 8.1', 'game_data_written': False,
               'before_metrics': metrics(before), 'after_metrics': after_metrics,
               'before': before, 'after': after, 'curves': curves, 'changes': changes,
               'parameters': specs, 'vector': search.best['vector'],
               'search': {'seed': args.seed if not args.vector else None, 'iterations': args.iterations if not args.vector else 0, 'population_multiplier': args.population if not args.vector else 0,
                          'evaluations': search.evaluations, 'method': 'explicit vector replay and optional coordinate refinement' if args.vector else 'serial deterministic differential evolution; constraints first, then envelope L1 objective',
                          'vector_origin':str(args.vector) if args.vector else None,
                          'vector_origin_sha256':hashlib.sha256(args.vector.read_bytes()).hexdigest() if args.vector else None,
                          'source_search_provenance':saved.get('search') if args.vector else None,
                          'coordinate_polish_rounds':args.polish_rounds,
                          'optimality': 'best found candidate; no claim of global optimum'},
               'frozen_input_sha256': frozen,
               'tool_sha256': tool_hash}
    atomic_write(args.output.with_suffix('.json'), payload)
    args.output.with_suffix('.md').write_text(render(payload))
    print(f"FINAL {payload['status']} metrics={after_metrics} output={args.output}", flush=True)
    return int(bool(after_metrics['violation_count']))


if __name__ == '__main__':
    raise SystemExit(main())
