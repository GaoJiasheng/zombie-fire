#!/usr/bin/env python3
"""Scoped §41 §9 native iterations; fixed seeds, <=6 jobs, immutable evidence."""
import argparse
import collections
import copy
import hashlib
import json
import math
import os
from pathlib import Path
import statistics
import subprocess
import sys
import time

import challenge_curve as curve
import prepare_linear_power_acceptance as prep
import run_frontline_sweep as sweep
import solve_runtime_clear_lines as t1

ROOT = t1.ROOT
OUT = ROOT/'design/audits/linear_power_p4_2026_10_05'
BASE = OUT/'s9_baseline.json'
JOURNAL = OUT/'commands.json'
REP = 'res://design/audits/challenge_reference_fixture_builds.json'
FREE = 'res://design/audits/challenge_free_counterexample_fixture_builds.json'


def guard():
    baseline = json.loads(BASE.read_text())
    now = t1.input_hashes()
    before = baseline['input_sha256']
    changed = [p for p in before if before[p] != now.get(p)]
    assert set(changed) <= {'data/challenges.json'}, changed
    assert set(now) == set(before)
    data = json.loads((ROOT/'data/challenges.json').read_text())
    old = baseline['challenges']
    assert {k:v for k,v in data.items() if k != 'curve'} == {k:v for k,v in old.items() if k != 'curve'}
    assert {k:v for k,v in data['curve'].items() if k not in ('anchors','line_pressure_exponents')} == {k:v for k,v in old['curve'].items() if k not in ('anchors','line_pressure_exponents')}
    assert all(curve.rule_for_level(n, data) == curve.rule_for_level(n, old) for n in range(1,61)), 'ch1-6 drift'
    assert not curve.validate(data), curve.validate(data)
    for p, sha in baseline['protected_sha256'].items():
        assert hashlib.sha256((ROOT/p).read_bytes()).hexdigest() == sha, p
    return now


def initialize():
    OUT.mkdir(parents=True, exist_ok=True)
    assert not BASE.exists(), 'existing baseline must not be overwritten'
    paths = ['export_presets.cfg','assets/production/OUTSOURCER_ASSET_INDEX.json',
             'design/audits/b2b_star_table_old_to_new.csv',
             'design/audits/resource_curve_table_2026_10_04.json',
             'design/audits/challenge_reference_fixture_builds.json',
             'design/audits/challenge_free_counterexample_fixture_builds.json']
    t1.atomic_write(BASE, {'input_sha256': t1.input_hashes(),
                         'challenges': json.loads((ROOT/'data/challenges.json').read_text()),
                         'head': subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
                         'protected_sha256': {p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in paths}})
    tables = t1.load_tables()
    source = json.loads(t1.FIXTURE.read_text())['rows'][75]['build']
    build = copy.deepcopy(source)
    definition = json.loads((ROOT/'data/premium_sets.json').read_text())['set_apocalypse_inferno']
    assert definition['store_unlock']['clear_level'] == 30
    for slot, table in [('weapon','weapons'),('armor','armors'),('chip','chips'),('pet','pets')]:
        build[slot] = definition[slot]
        build[slot+'_level'] = min(build[slot+'_level'], tables[table][build[slot]]['max_level'])
    t1.atomic_write(OUT/'inferno_076_fixture.json', prep.fixture([prep.row(76,build,'§9 reference ranks + disclosed Inferno complete set')]))
    t1.atomic_write(OUT/'inferno_076_construction.json', {'before':source,'after':build,'set':'set_apocalypse_inferno','revealed_after_clear':30})
    print('Initialized §9 baseline and same-rank Inferno 076 fixture')


def validate(path, levels, fixture, challenge, logs):
    payload = json.loads(path.read_text())
    prov = sweep.collect_run_provenance(ROOT,fixture)
    assert payload['fixture_sha256'] == prov['fixture_sha256']
    assert payload['combat_input_fingerprint'] == prov['combat_input_fingerprint']
    assert payload['challenge'] == challenge and not payload['fail_fast']
    assert payload['simulation_step_seconds'] == 1/60 and payload['sweep']['jobs'] <= 6
    rows = {r['level']:r for r in json.loads((ROOT/fixture.removeprefix('res://')).read_text())['rows']}
    grouped = collections.defaultdict(list)
    for r in payload['runs']: grouped[r['level']].append(r)
    assert sorted(grouped) == sorted(levels)
    result = []
    incomplete = []
    for n, rs in sorted(grouped.items()):
        assert sorted(r['seed'] for r in rs) == t1.SEEDS
        unfinished = [r for r in rs if r.get('timeout')]
        if unfinished:
            # A logical probe horizon is not a defeat. Preserve these seeds
            # and do not admit this level to the ten-seed victory contracts.
            assert payload['profile'] == 'tier_b' and payload['card_policy'] == 'v2'
            for r in rs:
                assert r['level'] == n and r['build'] == rows[n]['build']
                assert not r.get('error') and not r.get('probe_status')
                assert isinstance(r['victory'], bool)
                assert all(math.isfinite(r[k]) for k in ('base_ratio','elapsed_seconds'))
                assert 0 <= r['base_ratio'] <= 1 and r['elapsed_seconds'] >= 0
                if r.get('timeout'):
                    assert not r['victory'] and r['elapsed_seconds'] >= 540
                    incomplete.append({'level':n,'seed':r['seed'],'kind':'logical_horizon',
                                       'elapsed_seconds':r['elapsed_seconds']})
            result.append({'level':n,'status':'INCOMPLETE','completed_runs':len(rs)-len(unfinished),
                           'unfinished_seeds':[r['seed'] for r in unfinished],'wins':None,
                           'failed_seeds':None,'winning_boss_median':None})
            continue
        t1.validate_runs({**payload,'runs':rs},n,rows[n]['build'])
        winners = [r for r in rs if r['victory']]
        result.append({'level':n,'wins':len(winners),'failed_seeds':[r['seed'] for r in rs if not r['victory']],
                       'base_median':statistics.median(r['base_ratio'] for r in rs),
                       'winning_boss_median':statistics.median(r.get('boss_phase_seconds',0) for r in winners) if winners else None})
    raw = list(logs.glob('*.log'))
    assert len(raw) == len(levels)*10
    assert sum(p.read_text().count('SCRIPT ERROR') for p in raw) == 0
    return {'integrity':'INCOMPLETE' if incomplete else 'PASS','runs':len(payload['runs']),
            'script_errors':0,'timeouts':len(incomplete),'incomplete':incomplete,'rows':result}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--init',action='store_true')
    parser.add_argument('--label')
    parser.add_argument('--levels',default='99')
    parser.add_argument('--inferno',action='store_true')
    parser.add_argument('--free',action='store_true')
    args = parser.parse_args()
    if args.init: initialize(); return
    assert args.label and all(c.isalnum() or c=='_' for c in args.label)
    levels = list(map(int,args.levels.split(',')))
    assert len(set(levels)) == len(levels) and len(levels)*10 <= 320
    frozen = guard()
    output = OUT/(args.label+'.json')
    logs = Path('/tmp/zf_linear_s9_'+args.label+'_2026_10_05')
    log = logs.with_suffix('.log')
    assert not output.exists() and not log.exists(), 'never overwrite existing evidence'
    fixture = ('res://design/audits/linear_power_p4_2026_10_05/inferno_076_fixture.json' if args.inferno else FREE if args.free else REP)
    challenge = not args.inferno
    assert not args.inferno or levels == [76]
    cmd = [sys.executable,'-u','tools/run_frontline_sweep.py','--levels',args.levels,
           '--seeds',','.join(map(str,t1.SEEDS)),'--profile','tier_b','--card-policy','v2',
           '--accel','60','--jobs','6','--process-timeout','360','--fixture',fixture,
           '--output',str(output),'--log-dir',str(logs)]
    if challenge: cmd.append('--challenge')
    record = {'label':args.label,'command':cmd,'log':str(log),'started_unix':time.time(),
              'input_sha256':frozen,'curve':json.loads((ROOT/'data/challenges.json').read_text())['curve']}
    t1.atomic_write(OUT/(args.label+'_inputs.json'),record)
    print('START '+args.label,flush=True)
    with log.open('w') as f: proc = subprocess.run(cmd,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT)
    record.update(exit=proc.returncode,ended_unix=time.time())
    journal = json.loads(JOURNAL.read_text()) if JOURNAL.exists() else []
    journal.append(record); t1.atomic_write(JOURNAL,journal)
    assert proc.returncode == 0, f'probe process failed: {log}'
    assert frozen == guard(), 'data changed while native probes ran'
    result = validate(output,levels,fixture,challenge,logs)
    t1.atomic_write(OUT/(args.label+'_summary.json'),result)
    print(json.dumps(result,ensure_ascii=False),flush=True)


if __name__ == '__main__': main()
