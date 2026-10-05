#!/usr/bin/env python3
"""Current §9 contracts from verified groups; reuse only identical per-level rules.

Selection is latest completed matching-input group, never highest-win seed or
group. Historic first-round evidence stays immutable; fresh probes retain full
candidate fingerprints. Expanded challenge rules must match at each reuse.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import statistics

import challenge_curve as curve
import run_linear_power_s9 as s9
import solve_runtime_clear_lines as t1


def complete_seed_set(runs):
    """Incomplete evidence cannot satisfy either finale victory contract."""
    return (len(runs)==len(t1.SEEDS)
            and sorted(r.get('seed') for r in runs)==t1.SEEDS
            and not any(r.get('timeout') or r.get('error') or r.get('probe_status') for r in runs))


def main(check=False, prefix=None):
    s9.guard()
    assert prefix is None or prefix.isidentifier(), 'audit prefix must be a safe identifier'
    out = s9.OUT
    base = json.loads(s9.BASE.read_text())
    current = json.loads((s9.ROOT/'data/challenges.json').read_text())
    old_path = s9.ROOT/'design/audits/linear_power_p4_2026_10_04/challenge_representatives_2026_10_04.json'
    old = json.loads(old_path.read_text())
    sources = [(old_path,old,base['challenges']['curve'],'first-round immutable evidence')]
    old_free_path=s9.ROOT/'design/audits/linear_power_p4_2026_10_04/challenge_099_free_max_2026_10_04.json'
    free_sources = [(old_free_path,json.loads(old_free_path.read_text()),
                     base['challenges']['curve'],'first-round immutable free finale')]
    journal = json.loads(s9.JOURNAL.read_text()) if s9.JOURNAL.exists() else []
    for record in journal:
        if record['exit'] != 0: continue
        path = out/(record['label']+'.json')
        if not (out/(record['label']+'_summary.json')).exists(): continue
        payload = json.loads(path.read_text())
        assert {p:h for p,h in record['input_sha256'].items() if p!='data/challenges.json'} == {p:h for p,h in base['input_sha256'].items() if p!='data/challenges.json'}
        if not payload['challenge']: continue
        target = free_sources if 'free_counterexample' in payload['fixture_source'] else sources
        target.append((path,payload,record['curve'],record['label']))
    rows = []
    for n in [n for first in range(1,100,10) for n in (first,first+4,min(first+9,99))]:
        matches = []
        for path,payload,config,label in sources:
            if curve.rule_for_level(n,{**current,'curve':config}) != curve.rule_for_level(n,current): continue
            rs = [r for r in payload['runs'] if r['level']==n]
            if complete_seed_set(rs):
                matches.append((path,rs,label))
        if not matches: rows.append({'level':n,'status':'PENDING'});continue
        path,rs,label = matches[-1]
        assert sorted(r['seed'] for r in rs)==t1.SEEDS
        win = [r for r in rs if r['victory']]
        rows.append({'level':n,'status':'MEASURED','wins':len(win),'failed_seeds':[r['seed'] for r in rs if not r['victory']],
                     'boss_median':statistics.median(r.get('boss_phase_seconds',0) for r in win) if win else None,
                     'source':str(path.relative_to(s9.ROOT)),'source_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
                     'selected_group':label,'reuse_rule':'latest completed exact expanded-rule match'})
    chapters=[]
    for ch in range(1,11):
        group=[r for r in rows if (r['level']-1)//10+1==ch]
        complete=all(r['status']=='MEASURED' for r in group)
        wins=sum(r.get('wins',0) for r in group)
        lo,hi=(21,30) if ch<=6 else (18,27)
        chapters.append({'chapter':ch,'wins':wins if complete else None,'runs':30 if complete else None,
                         'contract':[lo,hi],'pass':lo<=wins<=hi if complete else None})
    finale = next(r for r in rows if r['level']==99)
    free=None
    for path,payload,config,label in free_sources:
        if curve.rule_for_level(99,{**current,'curve':config}) != curve.rule_for_level(99,current):continue
        rs=payload['runs']
        if not complete_seed_set(rs):continue
        free={'wins':sum(r['victory'] for r in rs),'failed_seeds':[r['seed'] for r in rs if not r['victory']],
              'source':str(path.relative_to(s9.ROOT)),'group':label}
    hard_fail=[r['chapter'] for r in chapters if r['pass'] is False]
    gold_pass=6<=finale['wins']<=9 and 150<=finale['boss_median']<=220 if finale['status']=='MEASURED' else None
    free_pass=free['wins']<=3 if free else None
    # Known failures stay failures even when another seed set is incomplete.
    # Unknown points are reported separately, never counted as victories/losses.
    known_fail=bool(hard_fail) or gold_pass is False or free_pass is False
    status='FAIL' if known_fail else 'PENDING' if any(r['pass'] is None for r in chapters) or gold_pass is None or free_pass is None else 'PASS'
    report={'authority':'2026-10-05 §41 §9','status':status,
            'curve_sha256':hashlib.sha256((s9.ROOT/'data/challenges.json').read_bytes()).hexdigest(),
            'curve':current['curve'],'chapter_failures':hard_fail,'chapters':chapters,
            'unverified_representatives':[r['level'] for r in rows if r['status']!='MEASURED'],
            'rows':rows,'golden099':finale,'golden099_pass':gold_pass,'free099':free,'free099_pass':free_pass,
            'first_sixty_unchanged':True,'paid_attributes_unchanged':True,'selection_method':__doc__}
    t1.atomic_write(out/(prefix+'_contracts.json' if prefix else 'current_contracts.json'),report)
    k_rows=[{'level':n,'old_K':curve.budget_for_level(n,base['challenges']), 'new_K':curve.budget_for_level(n,current),
             'delta_K':curve.budget_for_level(n,current)-curve.budget_for_level(n,base['challenges']),
             'old_rule':curve.rule_for_level(n,base['challenges']),'new_rule':curve.rule_for_level(n,current)} for n in range(1,100)]
    table_name=prefix+'_K_old_new' if prefix else 'challenge_K_old_new_2026_10_05'
    t1.atomic_write(out/(table_name+'.json'),{'status':'candidate' if status!='PASS' else 'runtime_verified','rows':k_rows})
    with (out/(table_name+'.csv')).open('w') as f:
        writer=csv.DictWriter(f,fieldnames=['level','old_K','new_K','delta_K']);writer.writeheader()
        writer.writerows({k:r[k] for k in writer.fieldnames} for r in k_rows)
    print(json.dumps({k:v for k,v in report.items() if k not in ('rows','selection_method')},ensure_ascii=False,indent=2))
    return 0 if not check or status == 'PASS' else 1


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check',action='store_true',help='fail unless all current runtime contracts pass')
    parser.add_argument('--prefix',help='distinct audit filenames; preserve a tested candidate before restoration')
    args=parser.parse_args()
    raise SystemExit(main(args.check,args.prefix))
