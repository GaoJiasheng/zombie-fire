"""Summarize actual search evidence; no production table writer."""
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path('/Users/gavin/work/zf-linear')
sys.path.insert(0, str(ROOT/'tools'))
from solve_runtime_clear_lines import atomic_write, input_hashes

audits = ROOT/'design/audits'
official = audits/'resource_curve_table_2026_10_04.json'
p = json.loads(official.read_text())
old = json.loads((audits/'resource_curve_table_8_3_historical_2026_10_04.json').read_text())
rows = {r['level']:r for r in p['after']['rows']}
oldgates = {r['level']:r for r in old['after']['gate_heights']}
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

runs = []
for name, exit_code, log in [('seed',1,'seed_search'),('corner',1,'corner_search'),
                              ('upper_seed',1,'upper_seed_search'),('search',1,'search'),('down_up',0,'down_up_search')]:
    path = audits/f'resource_curve_table_c3_{name}_2026_10_04.json'
    trial = json.loads(path.read_text())
    runs.append({'name':name, 'table':str(path.relative_to(ROOT)), 'table_sha256':sha(path),
                 'search':trial['search'], 'parameters':trial['parameters'], 'vector':trial['vector'],
                 'metrics':trial['after_metrics'], 'exit_code':exit_code,
                 'log':f'/tmp/zf_linear_c3_{log}_2026_10_04.log'})
comparison=[]
for n in sorted(set(oldgates)|set(p['after']['gate_levels'])):
    r=rows[n]
    comparison.append({'level':n, 'previous_8_3_is_gate':n in oldgates,
                        'previous_8_3_height':oldgates.get(n,{}).get('gate_height'),
                        'current_is_gate':r['G1_lower_exempt'],
                        'current_farm_runs':r['farming']['runs'], 'current_height':r['farming']['gate_height'],
                        'current_reason':r['farming']['gate_reason'], 'current_route':r['farming']['route_annotation'],
                        'rec':r['recommended'], 'power':r['power'], 'R':r['R'],
                        'G1_upper':r['G1_power_upper'], 'target':r['clear_target_power_lower']})
protected = [ROOT/'design/audits/campaign_progression_fixture_builds.json',
             ROOT/'design/audits/recommended_power_table_2026_10_04.json',
             ROOT/'design/audits/recommended_power_table_2026_10_04.csv',
             ROOT/'design/audits/runtime_clear_lines_2026_10_03.json',
             ROOT/'export_presets.cfg', ROOT/'assets/production/OUTSOURCER_ASSET_INDEX.json']
assert input_hashes()==p['frozen_input_sha256']
assert p['after']['failures']==[] and all(r['power']>=r['recommended'] for r in rows.values() if r['G1_lower_exempt'])
assert all(b['power']>=a['power'] for a,b in zip(p['after']['rows'],p['after']['rows'][1:]))
summary={'contract':'design/41 section 8.4', 'merge_commit':'88eff2ee',
         'tool_commit':'e65ca063201b4f8ca307847af801ffb516b1d5d1',
         'game_data_written':False, 'new_runtime_battle_runs':0,
         'official_table':str(official.relative_to(ROOT)), 'official_table_sha256':sha(official),
         'official_markdown_sha256':sha(official.with_suffix('.md')), 'before_metrics':p['before_metrics'],
         'after_metrics':p['after_metrics'], 'curves':p['curves'], 'changed_candidate_fields':len(p['changes']),
         'search_runs':runs, 'total_search_evaluations_including_final_replay':sum(r['search']['evaluations'] for r in runs)+p['search']['evaluations'],
         'objective_priority':p['objective_priority'], 'gate_comparison_to_8_3':comparison,
         'eight_wall_rows':[rows[n] for n in (15,17,18,19,20,40,44,76)],
         'non_gate_farms':[{'level':r['level'],'runs':r['runs']} for r in p['after']['farm_gates'] if not r['is_gate']],
         'chapter_farm_runs':p['after']['chapter_farm_runs'],
         'challenge_first_clears':len(p['after']['challenge_first_clears']),
         'candidate_truthful_R_range':[min(r['R'] for r in rows.values()),max(r['R'] for r in rows.values())],
         'candidate_power_over_E_range':[min(r['power_over_E'] for r in rows.values()),max(r['power_over_E'] for r in rows.values())],
         'candidate_monotone_power_verified':True,
         'protected_audit_files_sha256':{str(path.relative_to(ROOT)):sha(path) for path in protected},
         'frozen_input_sha256':input_hashes()}
atomic_write(audits/'linear_power_p3_2026_10_04/c3_search_and_gate_reconciliation_2026_10_04.json',summary)
print('PASS',len(rows),'G1 rows; evaluations',summary['total_search_evaluations_including_final_replay'])
print('R range',summary['candidate_truthful_R_range'],'P/E range',summary['candidate_power_over_E_range'])
print('six previous gates comparison',json.dumps([c for c in comparison if c['previous_8_3_is_gate']],ensure_ascii=False))
print('free unlock rows',json.dumps([c for c in p['changes'] if c['pointer'].endswith('unlock_cost_star')],ensure_ascii=False))
