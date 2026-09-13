#!/usr/bin/env python3
"""Seal the interrupted fixed-source batch before owner-directed UI changes."""
import hashlib
import json
import re
import subprocess
from pathlib import Path
import capture_finish as capture

root, audit = capture.ROOT, capture.AUDIT
base = audit / 'final02'
assert capture.runtime_diff() == (base / 'verification/runtime.patch').read_bytes()
assert capture.source_manifest() == json.loads((base / 'verification/source_manifest.json').read_text())
head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip()
assert head == json.loads((base / 'verification/provenance.json').read_text())['head']
plan = json.loads((base / 'cases_plan.json').read_text())
valid, rejected, reuse, recapture = [], [], [], []
for row in plan['cases']:
    record = base / 'screenshots/after' / (row['label'] + '.json')
    accepted = False
    if record.exists():
        saved = json.loads(record.read_text())
        shot = base / saved['file']
        accepted = saved['capture_exit'] == 0 and not saved['runtime_issues'] and not saved['image_issues'] and saved['git_head'] == head and shot.exists() and hashlib.sha256(shot.read_bytes()).hexdigest() == saved['sha256'] and not re.search(r'ERROR:|SCRIPT ERROR:|Parse Error:', shot.with_suffix('.log').read_text())
        (valid if accepted else rejected).append(row['label'])
    affected = row['route'] in ['store', 'loadout'] or (row['route'] == 'collection' and row['payload'].get('mode') == 'pets')
    if accepted and not affected:
        reuse.append(row['label'])
    else:
        recapture.append(row)
result = dict(head=head, reason='Owner requests original weapon presentation, cancel new theme recoloring', planned_total=plan['total'], complete=False, source_hashes_unchanged=True, completed_valid=len(valid), completed_labels=valid, rejected_labels=rejected, reusable_labels=reuse, reusable_count=len(reuse), next_capture_count=len(recapture))
(base / 'verification/stopped_source_seal.json').write_text(json.dumps(result, ensure_ascii=False, indent=2))
(audit / 'verification/final_continuation_cases.json').write_text(json.dumps(recapture, ensure_ascii=False, indent=2))
print(json.dumps({k:v for k,v in result.items() if not isinstance(v,list)}, ensure_ascii=False, indent=2))
