"""Project historical search coordinates into §8.4; never resume old prices."""
import json
import math
import sys
from pathlib import Path

ROOT = Path('/Users/gavin/work/zf-linear')
sys.path.insert(0, str(ROOT/'tools'))
import audit_campaign_frontline as campaign
import derive_resource_curves as resource
from solve_runtime_clear_lines import atomic_write, input_hashes

oldpath = ROOT/'design/audits/resource_curve_table_8_3_historical_2026_10_04.json'
old = json.loads(oldpath.read_text())
values = dict(zip([s['name'] for s in old['parameters']], old['vector']))
specs = resource.parameters(campaign.TABLES, {'skill_base_xp_costs':1, 'sig_skill_xp_costs':1})
for factor in (1.0, 1.2, 1.6):
    vector = [math.log(factor) if s['name']=='free_weapon_cost.log_scale' else values[s['name']] for s in specs]
    payload = {'vector': vector, 'parameters': specs, 'frozen_input_sha256': input_hashes(),
               'projection': 'retain historical gold/star/XP coordinates, discard ALL eight individual prices and use one specified common factor',
               'common_weapon_factor': factor, 'source_table': str(oldpath)}
    path = Path(f'/tmp/zf_linear_c3_seed_{factor}_2026_10_04.json')
    atomic_write(path, payload)
    print(path, 'parameters', len(vector), 'common factor', factor)
