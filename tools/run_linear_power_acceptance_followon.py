#!/usr/bin/env python3
"""Audit-only ordered runtime acceptance; never tune data or adopt star tables.

Wait for the already-running main sweep (do NOT launch a duplicate), validate
it, derive a separate star table, then run G3 and phase-four groups sequentially
at six jobs. Completed verified outputs are reused on an explicit resume.
"""
import argparse
import collections
import csv
import hashlib
import json
import os
from pathlib import Path
import statistics
import subprocess
import sys
import time

import report_b2b_star_table as stars
import run_frontline_sweep as sweep
import solve_runtime_clear_lines as t1

ROOT = t1.ROOT
DATE = '2026_10_04'
AUDIT = ROOT/'design/audits'
P2, P4 = (AUDIT/f'linear_power_p{n}_{DATE}' for n in (2, 4))
MAIN = AUDIT/f'b2c_main_runtime_solved_001_099_ten_seed_{DATE}.json'
REPRESENTATIVES = [n for first in range(1, 100, 10) for n in (first, first+4, min(first+9, 99))]
JOURNAL = P2/f'acceptance_commands_{DATE}.json'
STATE = P2/f'acceptance_runtime_state_{DATE}.json'
GUARD = P2/f'final_acceptance_baseline_guard_{DATE}.json'


def check_frozen():
    guard = json.loads(GUARD.read_text())
    assert guard['frozen_input_sha256'] == t1.input_hashes(), 'product/frozen inputs changed during acceptance'
    for key, path in (('approved_stars_sha256', AUDIT/'b2b_star_table_old_to_new.csv'),
                      ('unadopted_candidate_sha256', AUDIT/f'resource_curve_table_{DATE}.json')):
        assert hashlib.sha256(path.read_bytes()).hexdigest() == guard[key], 'protected approved/historical table changed'


def validate(path, levels, fixture, challenge, log_dir):
    payload = json.loads(path.read_text())
    rows = {int(r['level']): r for r in json.loads((ROOT/fixture.removeprefix('res://')).read_text())['rows']}
    provenance = sweep.collect_run_provenance(ROOT, fixture)
    assert payload['fixture_sha256'] == provenance['fixture_sha256']
    assert payload['combat_input_fingerprint'] == provenance['combat_input_fingerprint']
    assert payload['challenge'] == challenge and payload['fail_fast'] is False
    assert payload['simulation_step_seconds'] == 1/60 and payload['sweep']['jobs'] <= 6
    groups = collections.defaultdict(list)
    for run in payload['runs']:
        groups[int(run['level'])].append(run)
    assert sorted(groups) == sorted(levels)
    results = []
    for n in sorted(groups):
        t1.validate_runs({**payload, 'runs': groups[n]}, n, rows[n]['build'])
        group = groups[n]
        results.append({'level': n, 'wins': sum(r['victory'] for r in group),
                        'failed_seeds': [r['seed'] for r in group if not r['victory']],
                        'base_median_pct': 100*statistics.median(r['base_ratio'] for r in group),
                        'victory_boss_phase_median_seconds': statistics.median([
                            r.get('boss_phase_seconds', 0) for r in group if r['victory']]) if any(r['victory'] for r in group) else None})
    logs = list(log_dir.glob('*.log'))
    assert len(logs) == len(levels)*10, 'one raw log per seed required'
    errors = sum(p.read_text().count('SCRIPT ERROR') for p in logs)
    assert errors == 0, 'raw SCRIPT ERROR; not a combat loss'
    check_frozen()
    return {'probe_integrity': 'PASS', 'runs': len(payload['runs']), 'script_errors': errors,
            'timeouts': 0, 'incomplete_seed_sets': [], 'raw_logs': str(log_dir), 'rows': results}


def command(args, label, expected_exit=None):
    log = Path(f'/tmp/zf_linear_acceptance_{label}_{DATE}.log')
    assert not log.exists(), f'refuse to overwrite prior command log: {log}'
    start = time.time()
    with log.open('w') as handle:
        proc = subprocess.run(args, cwd=ROOT, stdout=handle, stderr=subprocess.STDOUT)
    journal = json.loads(JOURNAL.read_text()) if JOURNAL.exists() else []
    journal.append({'command': args, 'exit': proc.returncode, 'log': str(log),
                    'started_unix': start, 'ended_unix': time.time()})
    t1.atomic_write(JOURNAL, journal)
    if expected_exit is not None:
        assert proc.returncode in expected_exit, f'{label}: exit {proc.returncode}, inspect {log}'
    return proc.returncode


def run_group(label, levels, fixture, challenge=False, output=None):
    output = output or P4/f'{label}_{DATE}.json'
    log_dir = Path(f'/tmp/zf_linear_acceptance_{label}_{DATE}')
    t1.atomic_write(STATE, {'status': 'RUNNING', 'group': label, 'output': str(output), 'jobs': 6})
    if not output.exists():
        args = [sys.executable, '-u', 'tools/run_frontline_sweep.py', '--levels', ','.join(map(str, levels)),
                '--seeds', ','.join(map(str, t1.SEEDS)), '--profile', 'tier_b', '--card-policy', 'v2',
                '--accel', '60', '--jobs', '6', '--process-timeout', '360', '--fixture', fixture,
                '--output', str(output), '--log-dir', str(log_dir)]
        if challenge:
            args.append('--challenge')
        command(args, label, {0})
    return validate(output, levels, fixture, challenge, log_dir)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--main-pid', type=int, required=True)
    args = parser.parse_args()
    check_frozen()
    t1.atomic_write(STATE, {'status': 'WAITING_EXISTING_MAIN', 'main_pid': args.main_pid})
    while not MAIN.exists():
        try:
            os.kill(args.main_pid, 0)
        except ProcessLookupError:
            raise RuntimeError('existing main sweep exited without final output; recover raw evidence, no duplicate launch')
        time.sleep(15)
    result = {'main': validate(MAIN, list(range(1, 100)), 'res://design/audits/campaign_progression_fixture_builds.json',
                               False, Path(f'/tmp/zf_linear_acceptance_main_{DATE}'))}
    star_csv = P2/f'star_table_runtime_solved_{DATE}.csv'
    if not star_csv.exists():
        command([sys.executable, 'tools/report_b2b_star_table.py', '--sweep', str(MAIN), '--output', str(star_csv)], 'stars_derive', {0})
        comparison_exit = command([sys.executable, 'tools/report_b2b_star_table.py', '--sweep', str(MAIN), '--check-approved'], 'stars_check_approved', {0, 1})
    else:
        comparison_exit = None
    approved = {int(r['level']): r for r in csv.DictReader((AUDIT/'b2b_star_table_old_to_new.csv').open())}
    actual = stars.derived_rows(json.loads(MAIN.read_text()))
    comparison = [{'level': int(r['level']), 'approved_star': int(approved[int(r['level'])]['new_star']),
                   'derived_star': r['new_star'], 'delta': int(r['new_star'])-int(approved[int(r['level'])]['new_star']),
                   'new_wins': r['wins'], 'new_median_base_pct': r['new_median_base_pct']} for r in actual]
    t1.atomic_write(P2/f'star_table_comparison_{DATE}.json', {'approved_table_unchanged': True,
                    'check_exit': comparison_exit, 'changed_levels': [r['level'] for r in comparison if r['delta']], 'rows': comparison})
    for label in ('085', '100', '115'):
        fixture = f'res://design/audits/linear_power_p2_{DATE}/g3_fixture_R{label}_{DATE}.json'
        levels = [r['level'] for r in json.loads((ROOT/fixture.removeprefix('res://')).read_text())['rows']]
        result['g3_'+label] = run_group('g3_R'+label, levels, fixture,
                                     output=P2/f'g3_R{label}_ten_seed_{DATE}.json')
    # Regenerate audit-only challenge fixtures via the existing approved route generator.
    command([sys.executable, 'tools/generate_challenge_reference_fixtures.py'], 'challenge_fixtures', {0})
    result['ordinary_099_free_max'] = run_group('ordinary_099_free_max', [99], 'res://design/audits/challenge_free_counterexample_fixture_builds.json')
    result['challenge_099_free_max'] = run_group('challenge_099_free_max', [99], 'res://design/audits/challenge_free_counterexample_fixture_builds.json', True)
    result['challenge_representatives'] = run_group('challenge_representatives', REPRESENTATIVES, 'res://design/audits/challenge_reference_fixture_builds.json', True)
    # Its 099 row is also the Golden Law maxed ten-seed finale, no duplicate group.
    result['paid_gates'] = run_group('paid_gates', [76, 95], f'res://design/audits/linear_power_p4_{DATE}/paid_gate_fixture_{DATE}.json')
    t1.atomic_write(P2/f'acceptance_runtime_integrity_{DATE}.json', result)
    t1.atomic_write(STATE, {'status': 'ALL_GROUPS_COMPLETE_AWAITING_CONTRACT_REVIEW',
                          'runs': sum(r['runs'] for r in result.values()), 'jobs': 6,
                          'script_errors': 0, 'product_data_written': False})
    print('ALL GROUPS COMPLETE; runtime integrity PASS. Win-rate contracts still require review; no automatic curve/data changes.', flush=True)


if __name__ == '__main__':
    main()
