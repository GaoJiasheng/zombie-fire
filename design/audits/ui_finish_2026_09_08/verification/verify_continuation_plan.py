#!/usr/bin/env python3
"""Prove full coverage and a UI-only delta before resuming captures."""
import json
from pathlib import Path
import capture_finish as capture

audit = capture.AUDIT
base = audit / 'final02'
seal = json.loads((base / 'verification/stopped_source_seal.json').read_text())
plan = json.loads((base / 'cases_plan.json').read_text())['cases']
continuation = json.loads((audit / 'verification/final_continuation_cases.json').read_text())
planned = {r['label']: r for r in plan}
resumed = {r['label']: r for r in continuation}
reused = set(seal['reusable_labels'])
assert len(planned) == 2234 and len(resumed) == 1441 and len(reused) == 793
assert not reused.intersection(resumed) and reused | resumed.keys() == planned.keys()
assert all(row == planned[label] for label, row in resumed.items())
affected = {label for label, row in planned.items() if row['route'] in ['store', 'loadout'] or (row['route'] == 'collection' and row['payload'].get('mode') == 'pets')}
assert len(affected) == 495 and affected <= resumed.keys()
before = json.loads((base / 'verification/source_manifest.json').read_text())
after = capture.source_manifest()
delta = {p for p in before.keys() | after.keys() if before.get(p) != after.get(p)}
expected = {'meta/store/store.gd', 'meta/collection/collection.gd', 'meta/loadout/loadout.gd', 'ui/weapon_showcase_theme.gdshader', 'ui/weapon_showcase_theme.gdshader.uid', 'tools/check_res_refs.py'}
assert delta == expected, delta
result = dict(passed=True, reusable=793, continuation=1441, total=2234, all_affected_cases=495, source_delta=sorted(delta))
(audit / 'verification/continuation_preflight.json').write_text(json.dumps(result, ensure_ascii=False, indent=2))
print(json.dumps(result, ensure_ascii=False, indent=2))
