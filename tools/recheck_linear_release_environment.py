#!/usr/bin/env python3
"""Repeat RC with isolated HOME and explicitly available existing dependencies.

Keep the earlier missing-Pillow failure. Never install packages, bypass assets,
write game data, or reuse the player's save directory.
"""
import json
import os
from pathlib import Path
import site
import subprocess
import sys
import tempfile

import run_linear_power_acceptance_followon as follow
import solve_runtime_clear_lines as t1


def main():
    follow.check_frozen()
    log = Path('/tmp/zf_linear_acceptance_final_release_candidate_dependencies_2026_10_05.log')
    assert not log.exists(), 'preserve previous logs'
    home = tempfile.mkdtemp(prefix='zf_linear_final_rc_dependencies_home_2026_10_05_')
    dependency_path = site.getusersitepackages()
    env = os.environ.copy()
    env.update(HOME=home, XDG_DATA_HOME=home+'/xdg_data', ZOMBIE_FIRE_SKIP_WINDOWED_VISUALS='1',
               PYTHONPATH=os.pathsep.join(filter(None, [dependency_path, env.get('PYTHONPATH', '')])))
    command = [sys.executable, 'tools/check_release_candidate.py']
    with log.open('w') as handle:
        proc = subprocess.run(command, cwd=follow.ROOT, env=env, stdout=handle, stderr=subprocess.STDOUT)
    follow.check_frozen()
    record = {'command': command, 'exit': proc.returncode, 'log': str(log),
              'independent_HOME': home, 'existing_dependency_path': dependency_path,
              'installed_dependencies': False, 'asset_gate_skipped': False,
              'note': 'Earlier isolated-HOME missing-Pillow failure retained. '
                      'Only existing read-only Python dependency lookup restored; '
                      'RC result is the actual exit code, not a waiver.'}
    t1.atomic_write(follow.P4/'acceptance_release_environment_recheck_2026_10_05.json', [record])
    print(json.dumps(record, ensure_ascii=False, indent=2))
    return proc.returncode


if __name__ == '__main__':
    raise SystemExit(main())
