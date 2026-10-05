#!/usr/bin/env python3
"""Independently recount §41 §9.1 from raw runs; never trust summary victories."""
import hashlib
import json
import math
from pathlib import Path
import statistics

import challenge_curve as curve
import run_linear_power_s9 as previous
import solve_runtime_clear_lines as t1

ROOT=previous.ROOT
OUT=ROOT/'design/audits/linear_power_p4_s91_2026_10_05'


def recount(rs):
    assert len(rs)==10 and sorted(r['seed'] for r in rs)==t1.SEEDS
    horizons=[]
    for r in rs:
        assert isinstance(r.get('victory'),bool)
        assert not r.get('error') and not r.get('probe_status'),'process failure is not a nonclear'
        assert all(isinstance(r.get(k),(int,float)) and math.isfinite(r[k]) for k in ('elapsed_seconds','base_ratio'))
        assert r['elapsed_seconds']>=0 and 0<=r['base_ratio']<=1
        if r.get('timeout'):
            assert r.get('logic_limit_seconds')==720 and r['elapsed_seconds']>=720 and not r['victory']
            horizons.append(r['seed'])
    win=[r for r in rs if r['victory']]
    return {'wins':len(win),'nonclear_seeds':[r['seed'] for r in rs if not r['victory']],
            'horizon_nonclear_seeds':horizons,
            'boss_median_seconds':statistics.median(r.get('boss_phase_seconds',0) for r in win) if win else None}


def check(path, output=None):
    frozen=previous.guard()
    report=json.loads(path.read_text())
    data=json.loads((ROOT/'data/challenges.json').read_text())
    base=json.loads(previous.BASE.read_text())
    assert report['authority']=='2026-10-05 §41 §9.1'
    assert report['curve_sha256']==hashlib.sha256((ROOT/'data/challenges.json').read_bytes()).hexdigest()
    assert report['curve']==data['curve'] and not curve.validate(data)
    assert all(curve.rule_for_level(n,data)==curve.rule_for_level(n,base['challenges']) for n in range(1,61))
    records={}
    for directory in (previous.OUT,OUT):
        if (directory/'commands.json').exists():
            for record in json.loads((directory/'commands.json').read_text()):records[record['label']]=record
    authority=json.loads((OUT/'probe_authority.json').read_text())
    errors=[];rows=[]

    def raw_result(n, source, group, sha=None, free=False):
        source_path=(ROOT/source).resolve()
        assert source_path.is_relative_to(ROOT/'design/audits')
        if sha:assert hashlib.sha256(source_path.read_bytes()).hexdigest()==sha
        payload=json.loads(source_path.read_text())
        assert payload['challenge'] and not payload.get('fail_fast',False)
        assert payload['profile']=='tier_b' and payload['card_policy']=='v2'
        assert payload['simulation_step_seconds']==1/60
        fixture=previous.FREE if free else previous.REP
        assert payload['fixture_sha256']==hashlib.sha256((ROOT/fixture.removeprefix('res://')).read_bytes()).hexdigest()
        if group.startswith('first-round immutable'):
            config=base['challenges']['curve']
            assert source_path.parent==ROOT/'design/audits/linear_power_p4_2026_10_04'
        else:
            record=records[group];assert record['exit']==0
            config=record['curve']
            for p,h in base['input_sha256'].items():
                if p not in ('data/challenges.json','tools/frontline_runtime_probe.gd'):
                    assert record['input_sha256'][p]==h
            assert record['input_sha256']['tools/frontline_runtime_probe.gd'] in (authority['before_sha256'],authority['after_sha256'])
            assert '--fail-fast' not in record['command']
            assert int(record['command'][record['command'].index('--jobs')+1])<=6
            if group.startswith('s91_'):
                assert payload['logic_limit_seconds']==720
                assert record['command'][record['command'].index('--logic-limit')+1]=='720'
            raw_logs=Path(record['log']).with_suffix('')
            assert raw_logs.is_dir()
            assert len(list(raw_logs.glob('*.log')))==len(payload['runs'])
            assert sum(p.read_text().count('SCRIPT ERROR') for p in raw_logs.glob('*.log'))==0
        assert curve.rule_for_level(n,{**data,'curve':config})==curve.rule_for_level(n,data),'stale expanded rule'
        rs=[r for r in payload['runs'] if r['level']==n]
        builds={r['level']:r['build'] for r in json.loads((ROOT/fixture.removeprefix('res://')).read_text())['rows']}
        assert all(r['build']==builds[n] for r in rs)
        result=recount(rs)
        expected_rule=curve.rule_for_level(n,data)
        for raw in rs:
            if raw.get('timeout'):continue
            actual_rule=raw['battle_report']['challenge_rule']
            for key in ('hp_mult','speed_mult','breach_damage_mult','mechanic_rate_mult','recommended_power_mult'):
                assert abs(actual_rule[key]-expected_rule[key])<1e-10,(n,raw['seed'],key,'runtime rule mismatch')
        return {'level':n,**result,'source':source,'source_sha256':hashlib.sha256(source_path.read_bytes()).hexdigest(),
                'group':group,'reuse':'exact expanded rule; terminal historical runs allowed; unfinished 540s forbidden'}

    expected=[n for first in range(1,100,10) for n in (first,first+4,min(first+9,99))]
    assert sorted(r['level'] for r in report['rows'])==expected
    for row in report['rows']:
        if row['status']!='MEASURED':errors.append(f"{row['level']:03d}: incomplete");continue
        result=raw_result(row['level'],row['source'],row['selected_group'],row['source_sha256'])
        assert result['wins']==row['wins']
        rows.append(result)
    chapters=[]
    for ch in range(1,11):
        rs=[r for r in rows if (r['level']-1)//10+1==ch]
        wins=sum(r['wins'] for r in rs);lo,hi=(21,30) if ch<=6 else (18,27)
        passed=len(rs)==3 and lo<=wins<=hi
        chapters.append({'chapter':ch,'wins':wins,'runs':len(rs)*10,'band_wins':[lo,hi],'pass':passed})
        if not passed:errors.append(f'chapter {ch}: {wins}/{len(rs)*10}, expected {lo}..{hi}/30')
    gold=next((r for r in rows if r['level']==99),None)
    if not gold or gold['wins']<6:errors.append('099 Golden Law requires >=6/10')
    free_manifest=report['free099'];free=None
    if free_manifest:
        free=raw_result(99,free_manifest['source'],free_manifest['group'],free=True)
        if free['wins']>3:errors.append('099 free requires <=3/10')
    else:errors.append('099 free incomplete')
    assert previous.guard()==frozen
    result={'authority':'2026-10-05 §41 §9.1','status':'FAIL' if errors else 'PASS',
            'input_sha256':frozen,'chapters':chapters,'rows':rows,'golden099':gold,'free099':free,
            'boss_phase_role':'information','boss_information_band_seconds':[150,220],
            'normal_product_inputs_unchanged':True,'first_sixty_unchanged':True,
            'coverage':'30 chapter representatives x10 + free finale x10; not a new 99x10 challenge sweep',
            'horizon_nonclears':[{'level':r['level'],'seed':s,'group':r['group']} for r in rows for s in r['horizon_nonclear_seeds']],
            'errors':errors}
    if output:t1.atomic_write(output,result)
    print(json.dumps(result,ensure_ascii=False,indent=2))
    return 1 if errors else 0
