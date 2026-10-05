#!/usr/bin/env python3
"""Wait for six-job native groups, then independent-HOME smoke and real RC.

Never change product files, skip an asset failure, or turn a contract failure
into a pass. Curve tuning and the final branch commit remain agent-reviewed.
"""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time

from check_godot_log import find_godot_log_issues
import run_linear_power_acceptance_followon as follow
import solve_runtime_clear_lines as t1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--followon-pid', type=int, required=True)
    args = parser.parse_args()
    while True:
        try:
            state = json.loads(follow.STATE.read_text())
        except (FileNotFoundError, json.JSONDecodeError):
            state = {}
        if state.get('status') == 'ALL_GROUPS_COMPLETE_AWAITING_CONTRACT_REVIEW':
            break
        try:
            os.kill(args.followon_pid, 0)
        except ProcessLookupError:
            raise RuntimeError('follow-on exited before verified completion; inspect its log, no duplicate runs')
        time.sleep(15)
    follow.check_frozen()
    commands = [
        ('boot', [follow.sweep.GODOT, '--headless', '--path', '.', '--quit'], None),
        ('m1_smoke', [follow.sweep.GODOT, '--headless', '--path', '.', '--script', 'res://tools/m1_smoke_test.gd'], 'M1'),
        ('release_candidate', [sys.executable, 'tools/check_release_candidate.py'], None),
    ]
    records = []
    for label, command, required in commands:
        log = Path(f'/tmp/zf_linear_acceptance_final_{label}_{follow.DATE}.log')
        assert not log.exists(), f'refuse prior log overwrite: {log}'
        home = tempfile.mkdtemp(prefix=f'zf_linear_acceptance_final_{label}_home_{follow.DATE}_')
        environment = os.environ.copy()
        environment.update(HOME=home, XDG_DATA_HOME=home+'/xdg_data', ZOMBIE_FIRE_SKIP_WINDOWED_VISUALS='1')
        with log.open('w') as handle:
            proc = subprocess.run(command, cwd=follow.ROOT, env=environment, stdout=handle, stderr=subprocess.STDOUT)
        body = log.read_text()
        issues = find_godot_log_issues(body)
        status = proc.returncode if proc.returncode else int(bool(issues))
        records.append({'command': command, 'exit': status, 'process_exit': proc.returncode,
                        'result': 'PASS' if status == 0 else 'FAIL', 'log': str(log),
                        'independent_HOME': home, 'godot_log_issues': issues,
                        'script_error_count': body.count('SCRIPT ERROR')})
        print(f"{label}: {'PASS' if status==0 else 'FAIL'} exit={status} log={log}", flush=True)
    follow.check_frozen()
    t1.atomic_write(follow.P4/f'acceptance_final_verification_{follow.DATE}.json', records)
    report_log = Path(f'/tmp/zf_linear_acceptance_contract_report_{follow.DATE}.log')
    assert not report_log.exists()
    with report_log.open('w') as handle:
        proc = subprocess.run([sys.executable, 'tools/report_linear_power_acceptance.py'], cwd=follow.ROOT,
                              stdout=handle, stderr=subprocess.STDOUT)
    t1.atomic_write(follow.P4/f'acceptance_final_state_{follow.DATE}.json',
                    {'status': 'READY_FOR_AGENT_CONTRACT_REVIEW' if proc.returncode==0 else 'REPORT_ERROR',
                     'report_exit': proc.returncode, 'report_log': str(report_log),
                     'product_data_written': False, 'push': False, 'package': False})
    return proc.returncode


if __name__ == '__main__':
    raise SystemExit(main())
