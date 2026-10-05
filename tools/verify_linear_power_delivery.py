#!/usr/bin/env python3
"""Final read-only provenance/freeze guard, not a win-rate acceptance waiver."""
import dataclasses
import json
from pathlib import Path
import subprocess

from power_scale_v6 import PowerScaleV6
import run_linear_power_acceptance_followon as follow
import solve_runtime_clear_lines as t1


def git(*args):
    return subprocess.check_output(['git', *args], cwd=follow.ROOT, text=True)


def main():
    branch = git('branch', '--show-current').strip()
    assert branch == 'codex/linear-power'
    follow.check_frozen()
    guard = json.loads(follow.GUARD.read_text())
    # Re-evaluate the existing frozen function for equality only; never save
    # a refit, change its samples, or change player->power conversion.
    actual_F = {a: dataclasses.asdict(c) for a, c in PowerScaleV6.build_from_fixture().curves.items()}
    assert actual_F == guard['F_g'], 'frozen F(g) changed'
    protected = git('diff', '--name-only', 'd916fca40a329528bcf9b96d3e5350bfa2b50326', '--',
                    'data', 'gameplay', 'core', 'export_presets.cfg',
                    'assets/production/OUTSOURCER_ASSET_INDEX.json').splitlines()
    assert not protected, f'product/redline changes since §8.5 merge: {protected}'
    old_md = git('show', f'd916fca40a329528bcf9b96d3e5350bfa2b50326:design/audits/resource_curve_table_{follow.DATE}.md')
    new_md = (follow.AUDIT/f'resource_curve_table_{follow.DATE}.md').read_text()
    assert new_md == '未采用(Owner 2026-10-04):紧缩方案,留待线上数据再议\n' + old_md
    state = json.loads(follow.STATE.read_text())
    evidence = json.loads((follow.P2/f'acceptance_runtime_integrity_{follow.DATE}.json').read_text())
    assert state['status'] == 'ALL_GROUPS_COMPLETE_AWAITING_CONTRACT_REVIEW'
    assert state['runs'] == sum(r['runs'] for r in evidence.values()) == 1630
    assert all(r['probe_integrity'] == 'PASS' and r['script_errors'] == 0
               and r['timeouts'] == 0 and not r['incomplete_seed_sets'] for r in evidence.values())
    final = json.loads((follow.P4/f'acceptance_final_verification_{follow.DATE}.json').read_text())
    assert len(final) == 3
    for label, row in zip(('boot', 'm1_smoke', 'release_candidate'), final):
        if label == 'm1_smoke' and row['exit'] == 0:
            assert 'M1 smoke test passed' in Path(row['log']).read_text()
    recheck = json.loads((follow.P4/'acceptance_release_environment_recheck_2026_10_05.json').read_text())
    assert len(recheck) == 1 and recheck[0]['installed_dependencies'] is False and recheck[0]['asset_gate_skipped'] is False
    conclusions = json.loads((follow.P2/f'acceptance_contract_conclusions_{follow.DATE}.json').read_text())
    assert conclusions['native_runs'] == 1630 and len(conclusions['main']) == 99 and len(conclusions['g3']) == 30
    assert conclusions['all_product_data_unchanged'] and not conclusions['challenge_curve_written']
    old_report = git('show', '1777945e293e4fa0bf8882ba7137ffd1989753fb:design/audits/linear_power_p2_2026_10_04/报告.md')
    assert (follow.P2/'报告_2AB历史.md').read_text() == old_report
    for path in (follow.P2/'报告.md', follow.P2/'Fable最终完整报告_2026_10_05.md', follow.P4/'报告.md'):
        body = path.read_text()
        assert body.startswith('状态：') and all(s in body for s in ('Completed', 'Changed files', 'Verification', 'Risks'))
        assert 'Pillow' in body, 'do not hide first RC environment failure'
    subprocess.run(['git', 'diff', '--check'], cwd=follow.ROOT, check=True)
    result = {'status': 'PROVENANCE_AND_FREEZE_PASS_NOT_ALL_CONTRACTS_PASS',
              'branch': branch, 'input_checkpoint': git('rev-parse', 'HEAD').strip(),
              'frozen_inputs': len(guard['frozen_input_sha256']), 'F_g_equal': True,
              'protected_product_diff': protected, 'unadopted_resource_md_only_prefix': True,
              'native_runs': state['runs'], 'native_script_errors': 0,
              'native_timeouts': 0, 'native_incomplete_seed_sets': [],
              'historical_report_exactly_preserved': True, 'current_report_structure_verified': True,
              'final_verification': [{'command': r['command'], 'exit': r['exit'], 'log': r['log']} for r in final + recheck],
              'note': 'Asset/RC failures and win-rate deviations stay failures/diagnostics. '
                      'This guard does not approve stars or a curve, and does not claim phase-four completion.'}
    t1.atomic_write(follow.P4/'delivery_guard_2026_10_05.json', result)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
