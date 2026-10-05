#!/usr/bin/env python3
"""Actual final §9 static/smoke/RC commands, isolated HOME, no asset waiver."""
import argparse
import json
import os
from pathlib import Path
import site
import subprocess
import sys
import tempfile
import time

from check_godot_log import find_godot_log_issues
import run_linear_power_s9 as s9
import solve_runtime_clear_lines as t1


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--label',default='',help='distinct retry suffix; never overwrite earlier verification')
    parser.add_argument('--review-root',default='/Users/gavin/work/zombie-fire/assets/production/source_refs',
                        choices=['/Users/gavin/work/zombie-fire/assets/production/source_refs','/Users/gavin/work/zombie-fire'],
                        help='read-only historical review root as interpreted by validate_asset_pack')
    args=parser.parse_args()
    assert not args.label or args.label.isidentifier()
    prefix='verification'+('_'+args.label if args.label else '')
    log_prefix='/tmp/zf_linear_s9_final_'+(args.label+'_' if args.label else '')
    frozen=s9.guard()
    assert not (s9.OUT/(prefix+'.json')).exists(), 'preserve prior verification; use a distinct retry label'
    home=tempfile.mkdtemp(prefix='zf_linear_s9_final_home_2026_10_05_')
    env=os.environ.copy()
    env.update(HOME=home,XDG_DATA_HOME=home+'/xdg_data',ZOMBIE_FIRE_TEST_HOME=home,
               ZOMBIE_FIRE_SOURCE_REFS_ROOT=args.review_root,
               ZOMBIE_FIRE_SKIP_WINDOWED_VISUALS='1',
               PYTHONPATH=os.pathsep.join(filter(None,[site.getusersitepackages(),env.get('PYTHONPATH','')])) )
    commands=[('s9_unit',[sys.executable,'-m','unittest','discover','-s','tools','-p','test_linear_power_s9.py','-v'],None),
              ('linear_unit',[sys.executable,'-m','unittest','discover','-s','tools','-p','test_linear_power_program.py','-v'],None),
              ('resource_unit',[sys.executable,'-m','unittest','discover','-s','tools','-p','test_resource_curves.py','-v'],None),
              ('ray_unit',[sys.executable,'-m','unittest','discover','-s','tools','-p','test_linear_power_acceptance.py','-v'],None),
              ('validate_data',[sys.executable,'tools/validate_data.py'],None),
              ('refs',[sys.executable,'tools/check_res_refs.py'],None),
              ('pressure',[sys.executable,'tools/check_level_pressure.py'],None),
              ('cards',[sys.executable,'tools/simulate_card_director.py'],None),
              ('boot',['/opt/homebrew/bin/godot','--headless','--path','.','--quit'],None),
              ('smoke',['/opt/homebrew/bin/godot','--headless','--path','.','--script','res://tools/m1_smoke_test.gd'],'M1 smoke test passed'),
              ('release_candidate',[sys.executable,'tools/check_release_candidate.py'],'Release candidate check OK')]
    records=[]
    for label,cmd,marker in commands:
        log=Path(log_prefix+label+'_2026_10_05.log')
        assert not log.exists(),log
        start=time.time()
        with log.open('w') as f: proc=subprocess.run(cmd,cwd=s9.ROOT,env=env,stdout=f,stderr=subprocess.STDOUT)
        output=log.read_text()
        issues=find_godot_log_issues(output) if Path(cmd[0]).name=='godot' else []
        ok=proc.returncode==0 and not issues and (not marker or marker in output)
        record={'command':cmd,'exit':proc.returncode,'pass':ok,'log':str(log),'issues':issues,
                'required_marker':marker,'independent_HOME':home,'started_unix':start,'ended_unix':time.time(),
                'source_refs_root':env['ZOMBIE_FIRE_SOURCE_REFS_ROOT'],'asset_gate_skipped':False,
                'input_sha256':frozen}
        records.append(record)
        t1.atomic_write(s9.OUT/(prefix+'.json'),records)
        print(label+': '+('PASS' if ok else 'FAIL')+' '+str(log),flush=True)
        assert s9.guard()==frozen, 'combat inputs changed during final verification'
    return 0 if all(r['pass'] for r in records) else 1


if __name__=='__main__':raise SystemExit(main())
