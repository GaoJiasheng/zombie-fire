#!/usr/bin/env python3
"""Verify §9 scope and every completed native group, not victory contracts."""
import hashlib
import json
from pathlib import Path
import subprocess

import challenge_curve as curve
import run_linear_power_s9 as s9
import solve_runtime_clear_lines as t1


def main():
    s9.guard()
    base=json.loads(s9.BASE.read_text())
    previous=json.loads((s9.ROOT/'design/audits/linear_power_p2_2026_10_04/final_acceptance_baseline_guard_2026_10_04.json').read_text())
    assert base['input_sha256']==previous['frozen_input_sha256'], '§9 baseline must match accepted first-round input'
    now=json.loads((s9.ROOT/'data/challenges.json').read_text())
    journal=json.loads(s9.JOURNAL.read_text()) if s9.JOURNAL.exists() else []
    results=[]
    total=0
    incomplete=[]
    for r in journal:
        assert r['exit']==0, r
        path=s9.OUT/(r['label']+'.json')
        data=json.loads(path.read_text())
        cmd=r['command'];fixture=cmd[cmd.index('--fixture')+1]
        levels=list(map(int,cmd[cmd.index('--levels')+1].split(',')))
        checked=s9.validate(path,levels,fixture,'--challenge' in cmd,Path(r['log']).with_suffix(''))
        summary=json.loads((s9.OUT/(r['label']+'_summary.json')).read_text())
        assert checked==summary
        for run in data['runs']:
            if run.get('timeout'):
                continue
            if data['challenge']:
                expected=curve.rule_for_level(run['level'],{**now,'curve':r['curve']})
                actual=run['battle_report']['challenge_rule']
                for key in ('hp_mult','speed_mult','breach_damage_mult','mechanic_rate_mult','recommended_power_mult'):
                    assert abs(actual[key]-expected[key])<1e-10, (r['label'],run['level'],key)
        total+=checked['runs']-checked['timeouts']
        incomplete.extend({'group':r['label'],**item} for item in checked['incomplete'])
        results.append({'group':r['label'],'runs':checked['runs'],'raw_logs':checked['raw_logs'] if 'raw_logs' in checked else str(Path(r['log']).with_suffix('')),
                        'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'integrity':checked['integrity']})
    result={'scope':'PASS','native_integrity':'INCOMPLETE' if incomplete else 'PASS','completed_new_runs':total,
            'script_errors':0,'timeouts':len(incomplete),'incomplete_seed_sets':incomplete,
            'all_non_challenge_inputs_unchanged':True,'first_sixty_rules_unchanged':True,
            'resource_candidate_unadopted':True,'approved_stars_unchanged':True,'groups':results}
    t1.atomic_write(s9.OUT/'integrity.json',result)
    print(json.dumps(result,ensure_ascii=False,indent=2))


if __name__=='__main__': main()
