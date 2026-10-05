#!/usr/bin/env python3
"""Bounded §41 §9.1 challenge iterations; preserve every candidate and native log."""
import argparse
import copy
import hashlib
import json
import math
from pathlib import Path
import statistics
import subprocess
import sys
import time

import challenge_curve as curve
import report_linear_power_s9 as report
import run_frontline_sweep as sweep
import run_linear_power_s9 as previous
import solve_runtime_clear_lines as t1

ROOT = previous.ROOT
OUT = ROOT/'design/audits/linear_power_p4_s91_2026_10_05'
AXES = ('speed','breach','mechanic')


def authorize_probe():
    """Pin the reviewed probe-only change separately from frozen product inputs."""
    OUT.mkdir(parents=True,exist_ok=True)
    base=json.loads(previous.BASE.read_text())
    path='tools/frontline_runtime_probe.gd'
    before=subprocess.check_output(['git','show',base['head']+':'+path],cwd=ROOT)
    assert hashlib.sha256(before).hexdigest()==base['input_sha256'][path]
    after=(ROOT/path).read_bytes()
    record={'authority':'2026-10-05 §41 §9.1','before_sha256':hashlib.sha256(before).hexdigest(),
            'after_sha256':hashlib.sha256(after).hexdigest(),
            'scope':'probe parameter and horizon provenance only; gameplay/core unchanged',
            'diff':subprocess.check_output(['git','diff',base['head'],'--',path],cwd=ROOT,text=True)}
    authority=OUT/'probe_authority.json'
    if authority.exists():assert json.loads(authority.read_text())==record
    else:t1.atomic_write(authority,record)


def candidate(args):
    data = json.loads((ROOT/'data/challenges.json').read_text())
    changed = copy.deepcopy(data)
    for assignment in args.set_k:
        level, value = assignment.split('=')
        level = int(level)
        assert 61 <= level <= 99
        anchors = changed['curve']['anchors']
        anchors[:] = [row for row in anchors if row['level'] != level]
        if value != 'remove': anchors.append({'level':level,'k':float(value)})
        anchors.sort(key=lambda row:row['level'])
    for assignment in args.set_exponent:
        level, values = assignment.split('=')
        level = int(level)
        assert 61 <= level <= 99
        anchors = changed['curve']['line_pressure_exponents']['anchors']
        anchors[:] = [row for row in anchors if row['level'] != level]
        if values != 'remove':
            numbers = list(map(float,values.split(',')))
            assert len(numbers)==3
            anchors.append({'level':level,**dict(zip(AXES,numbers))})
        anchors.sort(key=lambda row:row['level'])
    changed['curve']['finale_anchor'].update(win_rate=[.6,1.],boss_phase_role='information')
    errors = curve.validate(changed)
    assert not errors, errors
    base = json.loads(previous.BASE.read_text())['challenges']
    assert all(curve.rule_for_level(n,changed)==curve.rule_for_level(n,base) for n in range(1,61))
    return changed


def validate_native(path, fixture, levels, inputs, logs):
    payload = json.loads(path.read_text())
    provenance = sweep.collect_run_provenance(ROOT,fixture)
    assert payload['fixture_sha256']==provenance['fixture_sha256']
    assert payload['combat_input_fingerprint']==provenance['combat_input_fingerprint']
    assert payload['logic_limit_seconds']==720 and payload['challenge'] and not payload['fail_fast']
    assert payload['profile']=='tier_b' and payload['card_policy']=='v2'
    assert payload['simulation_step_seconds']==1/60 and payload['wall_acceleration']==60
    assert payload['sweep']['jobs']==6
    builds={r['level']:r['build'] for r in json.loads((ROOT/fixture.removeprefix('res://')).read_text())['rows']}
    assert len(payload['runs'])==10*len(levels)
    rows=[]
    for n in levels:
        rs=[r for r in payload['runs'] if r['level']==n]
        assert report.complete_seed_set(rs,True), (n,'missing/process-error seed, not authorized logical nonclear')
        for run in rs:
            assert run['build']==builds[n] and run['logic_limit_seconds']==720
            assert isinstance(run['victory'],bool)
            assert all(math.isfinite(run[k]) for k in ('base_ratio','elapsed_seconds'))
            assert 0 <= run['base_ratio'] <= 1 and run['elapsed_seconds']>=0
            if not run.get('timeout'):
                expected=curve.rule_for_level(n,inputs)
                actual=run['battle_report']['challenge_rule']
                for key in ('hp_mult','speed_mult','breach_damage_mult','mechanic_rate_mult','recommended_power_mult'):
                    assert abs(actual[key]-expected[key])<1e-10,(n,key)
        win=[r for r in rs if r['victory']]
        rows.append({'level':n,'wins':len(win),'failed_seeds':[r['seed'] for r in rs if not r['victory']],
                     'horizon_nonclear_seeds':[r['seed'] for r in rs if r.get('timeout')],
                     'winning_boss_median':statistics.median(r['boss_phase_seconds'] for r in win) if win else None})
    raw=list(logs.glob('*.log'))
    assert len(raw)==len(levels)*10
    assert sum(p.read_text().count('SCRIPT ERROR') for p in raw)==0
    return {'integrity':'PASS','runs':len(payload['runs']),'script_errors':0,
            'horizon_nonclears':sum(bool(r.get('timeout')) for r in payload['runs']),
            'horizon_policy':'§9.1 logical 720s nonclear counts as nonclear, not process error','rows':rows}


def run_group(label, levels, free, data, round_number):
    frozen=previous.guard()
    output=OUT/(label+'.json')
    logs=Path('/tmp/zf_linear_s91_'+label+'_2026_10_05')
    log=logs.with_suffix('.log')
    assert not output.exists() and not log.exists(), 'immutable evidence'
    fixture=previous.FREE if free else previous.REP
    cmd=[sys.executable,'-u','tools/run_frontline_sweep.py','--levels',','.join(map(str,levels)),
         '--seeds',','.join(map(str,t1.SEEDS)),'--profile','tier_b','--card-policy','v2',
         '--accel','60','--jobs','6','--logic-limit','720','--process-timeout','720',
         '--fixture',fixture,'--output',str(output),'--log-dir',str(logs),'--challenge']
    record={'label':label,'round':round_number,'command':cmd,'log':str(log),'input_sha256':frozen,
            'curve':data['curve'],'started_unix':time.time(),'authority':'2026-10-05 §41 §9.1'}
    t1.atomic_write(OUT/(label+'_inputs.json'),record)
    print('START '+label+' levels='+','.join(map(str,levels)),flush=True)
    with log.open('w') as f: proc=subprocess.run(cmd,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT)
    record.update(exit=proc.returncode,ended_unix=time.time())
    journal=json.loads((OUT/'commands.json').read_text()) if (OUT/'commands.json').exists() else []
    journal.append(record);t1.atomic_write(OUT/'commands.json',journal)
    assert proc.returncode==0,log
    assert previous.guard()==frozen,'combat input changed during probe'
    summary=validate_native(output,fixture,levels,data,logs)
    t1.atomic_write(OUT/(label+'_summary.json'),summary)
    print(json.dumps(summary,ensure_ascii=False),flush=True)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--round',type=int,required=True)
    parser.add_argument('--set-k',action='append',default=[],help='level=value or level=remove; 61..99 only')
    parser.add_argument('--set-exponent',action='append',default=[],help='level=speed,breach,mechanic or level=remove')
    args=parser.parse_args()
    assert 1 <= args.round <= 10,'Owner iteration limit'
    authorize_probe();previous.guard();OUT.mkdir(parents=True,exist_ok=True)
    start=OUT/f'round_{args.round:02d}_candidate.json'
    assert not start.exists(),'do not restart completed/started round; inspect gaps explicitly'
    data=candidate(args)
    t1.atomic_write(start,{'authority':'2026-10-05 §41 §9.1','argv':sys.argv,'data':data,
                         'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
                         'started_unix':time.time(),'base_commit':json.loads(previous.BASE.read_text())['head']})
    # Scoped generator output: only the signed challenge curve product file.
    t1.atomic_write(ROOT/'data/challenges.json',data)
    previous.guard()
    prefix=f'round_{args.round:02d}_before'
    report.main(False,prefix,True)
    before=json.loads((OUT/(prefix+'_contracts.json')).read_text())
    levels=before['unverified_representatives']
    free_needed=before['free099'] is None
    assert len(levels)*10+10*free_needed<=320
    t1.atomic_write(OUT/f'round_{args.round:02d}_plan.json',{'new_reference_levels':levels,
                         'new_free099':free_needed,'new_attempts':10*(len(levels)+free_needed),
                         'reused_rows':[r for r in before['rows'] if r['status']=='MEASURED'],
                         'reused_free099':before['free099']})
    if levels:run_group(f's91_r{args.round:02d}_reps',levels,False,data,args.round)
    if free_needed:run_group(f's91_r{args.round:02d}_free099',[99],True,data,args.round)
    code=report.main(True,f'round_{args.round:02d}',True)
    final=json.loads((OUT/f'round_{args.round:02d}_contracts.json').read_text())
    score=sum(max(18-r['wins'],r['wins']-27,0) for r in final['chapters'][6:] if r['wins'] is not None)
    score+=max(final['free099']['wins']-3,0) if final['free099'] else 100
    score+=max(6-final['golden099'].get('wins',0),0)
    t1.atomic_write(OUT/f'round_{args.round:02d}_result.json',{'status':final['status'],
                         'deviation_wins':score,'new_attempts':10*(len(levels)+free_needed),
                         'chapters':final['chapters'],'free099':final['free099'],
                         'golden099':final['golden099'],'exit_contract':code,'ended_unix':time.time()})
    print('ROUND_RESULT '+json.dumps({'round':args.round,'status':final['status'],'deviation_wins':score}),flush=True)
    # Completed search rounds with contract FAIL are observations, not crashes.
    return 0


if __name__=='__main__':raise SystemExit(main())
