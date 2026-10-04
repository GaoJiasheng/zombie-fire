#!/usr/bin/env python3
"""Audit-only §41 acceptance fixtures: capped T1 rays and disclosed paid swaps.

No product writer, no fitted ruler, no combat result inference. Integer build
ranks cannot always hit an exact R; take the first attainable rank at/above
the target and report the failed-side neighbour and overshoot explicitly.
"""
import copy
import json
from pathlib import Path

import progression_closure as closure
import solve_runtime_clear_lines as t1

ROOT = t1.ROOT
AUDIT = ROOT / 'design/audits'
DATE = '2026_10_04'
# Selected before any G3 battles, solely for chapter/Boss/wall coverage and
# smaller rank-quantization gaps. Finale 099 has its own phase-four full tests.
SAMPLE_LEVELS = [5, 15, 30, 40, 44, 54, 68, 74, 90, 96]
RATIOS = [('085', .85), ('100', 1.), ('115', 1.15)]


def ray_candidates(build, level, tables):
    """Enumerate all constant-rank intervals, not approximate level scaling."""
    bounds = {0.0}
    for field, table, identity in (
            ('character_level', 'characters', 'character'),
            ('weapon_level', 'weapons', 'weapon'),
            ('armor_level', 'armors', 'armor'),
            ('chip_level', 'chips', 'chip'), ('pet_level', 'pets', 'pet')):
        if build.get(identity):
            value = int(build[field])
            cap = int(tables[table][build[identity]]['max_level'])
            bounds.update((i+.5)/value for i in range(cap) if value > 0)
    for value, cap in [(build.get('signature_level', 0), len(tables['economy']['sig_skill_xp_costs']))] + [
            (value, t1.ruler.skill_max_level(tables['skills'][key]))
            for key, value in build.get('skill_base_levels', {}).items()]:
        if value:
            bounds.update((i+.5)/value for i in range(cap))
    points = sorted(bounds)
    points.append(points[-1]+1)
    result, seen = [], set()
    for lo, hi in zip(points, points[1:]):
        scale = (lo+hi)/2
        candidate = t1.scaled_build(build, scale, tables)
        identity = json.dumps(candidate, sort_keys=True)
        if identity in seen:
            continue
        seen.add(identity)
        result.append({'scale': scale, 'build': candidate,
                       'power': t1.power(level, candidate, tables)['power']})
    assert all(b['power'] >= a['power'] for a, b in zip(result, result[1:])), 'nonmonotone T1 ray'
    return result


def select_target(candidates, target):
    for index, candidate in enumerate(candidates):
        if candidate['power'] >= target:
            return candidate, candidates[index-1] if index else None
    raise ValueError(f'target power {target} exceeds capped reference ray {candidates[-1]["power"]}')


def fixture(rows, **metadata):
    return {'schema_version': 1, 'fire_rate_profile': 'tier_b', 'card_policy': 'v2',
            'seeds': t1.SEEDS, 'rows': rows, **metadata}


def row(number, build, source):
    return {'level': number, 'level_id': f'level_{number:03d}', 'build': build,
            'fixture_source': source, 'card_seeds': t1.SEEDS,
            'resources_before': {'gold': 0, 'xp': 0, 'stars': 0}}


def main():
    tables = t1.load_tables()
    source = json.loads(t1.FIXTURE.read_text())
    current = closure.generate(False)
    assert set(SAMPLE_LEVELS) & set(current['gate_levels']) == set()
    assert {(n-1)//10+1 for n in SAMPLE_LEVELS} == set(range(1, 11))
    rays = {n: ray_candidates(source['rows'][n-1]['build'], tables['levels'][n-1], tables) for n in SAMPLE_LEVELS}
    inventory = []
    for label, ratio in RATIOS:
        rows = []
        for n in SAMPLE_LEVELS:
            rec = int(tables['levels'][n-1]['clear_requirement']['power_contract']['recommended_power'])
            selected, previous = select_target(rays[n], rec*ratio)
            rows.append(row(n, selected['build'], 'capped T1 reference ray; first attainable P>=target'))
            inventory.append({'level': n, 'chapter': (n-1)//10+1, 'target_R': ratio,
                              'recommended': rec, 'actual_R': selected['power']/rec,
                              'R_overshoot': selected['power']/rec-ratio,
                              'non_gate_wall': n in t1.WALL_LEVELS,
                              'boss': closure.g1_constrained({**tables['levels'][n-1], 'id': 'level_001'}),
                              **selected, 'lower_neighbour': previous})
        t1.atomic_write(AUDIT / f'linear_power_p2_{DATE}/g3_fixture_R{label}_{DATE}.json', fixture(rows, target_R=ratio))
    t1.atomic_write(AUDIT / f'linear_power_p2_{DATE}/g3_ray_construction_{DATE}.json',
                    {'method': __doc__, 'frozen_input_sha256': t1.input_hashes(), 'rows': inventory})
    sets = json.loads((ROOT/'data/premium_sets.json').read_text())
    paid_rows, paid_inventory = [], []
    for n, set_id in ((76, 'set_apocalypse_absolute_zero'), (95, 'set_apocalypse_golden_law')):
        build = copy.deepcopy(source['rows'][n-1]['build'])
        definition = sets[set_id]
        assert definition['store_unlock']['clear_level'] < n
        changes = []
        for slot, table in (('weapon', 'weapons'), ('armor', 'armors'), ('chip', 'chips'), ('pet', 'pets')):
            old = build[slot]
            build[slot] = definition[slot]
            build[slot+'_level'] = min(build[slot+'_level'], tables[table][build[slot]]['max_level'])
            changes.append({'slot': slot, 'old': old, 'new': build[slot], 'rank': build[slot+'_level']})
        paid_rows.append(row(n, build, 'reference ranks + corresponding revealed full arsenal; no free rank upgrades'))
        paid_inventory.append({'level': n, 'set': set_id, 'revealed_after_clear': definition['store_unlock']['clear_level'],
                               'before': source['rows'][n-1]['build'], 'after': build, 'swaps': changes,
                               'power_before': t1.power(tables['levels'][n-1], source['rows'][n-1]['build'], tables)['power'],
                               'power_after': t1.power(tables['levels'][n-1], build, tables)['power']})
    t1.atomic_write(AUDIT / f'linear_power_p4_{DATE}/paid_gate_fixture_{DATE}.json', fixture(paid_rows))
    t1.atomic_write(AUDIT / f'linear_power_p4_{DATE}/paid_gate_construction_{DATE}.json', {'rows': paid_inventory})
    print('PASS: 30 capped G3 rays, ten chapters, Boss/non-gate walls; 2 already-revealed paid swaps at reference ranks')
    for r in inventory:
        print(f"L{r['level']:03d} target R={r['target_R']} actual={r['actual_R']:.6f} P={r['power']} s={r['scale']:.6f}")


if __name__ == '__main__':
    main()
