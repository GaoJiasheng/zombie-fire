#!/usr/bin/env python3
"""Deliver only final evidence; hash every copy; never delete destination files."""
import hashlib
import json
import os
import shutil
from pathlib import Path

SOURCE = Path(__file__).resolve().parents[1]
DEST = Path('/Users/gavin/Desktop/zombiefire_screenshots/15_UI收尾_2026_09_13')
SKIP = {'capture_home', 'test_home', '__pycache__', 'pilot01', 'pilot02', 'pilot03', 'pilot04', 'pilot05', 'pilot06', 'pilot07', 'pilot08', 'final01'}
RECEIPT = Path('verification/desktop_copy_verification.json')

def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()

def main():
    stats = json.loads((SOURCE / 'verification/final_statistics.json').read_text())
    assert stats['total'] == 2234 and stats['logical_cases'] == 2236 and not stats['issues']
    accepted = json.loads((SOURCE / 'verification/accepted_screenshots.json').read_text())
    accepted_stems = {str(Path(r['file']).with_suffix('')) for r in accepted}
    for name in ['UI收尾对比报告.html', '看图说明.md', '人工复核.md', '交付记录.md']:
        assert (SOURCE / name).is_file(), name
    qa = json.loads((SOURCE / 'verification/report_layout_qa.json').read_text())
    assert len(qa) == 2 and all(not r['missingImages'] and r['document'] <= r['width'] for r in qa)
    if DEST.exists():
        marker = DEST / RECEIPT
        assert marker.is_file() and json.loads(marker.read_text()).get('source') == str(SOURCE), 'Destination is not this audit’s prior delivery; do not overwrite'
    DEST.mkdir(parents=True, exist_ok=True)
    copied, size = [], 0
    for directory, children, names in os.walk(SOURCE):
        children[:] = [n for n in children if n not in SKIP]
        for name in sorted(names):
            source = Path(directory) / name
            relative = source.relative_to(SOURCE)
            if relative == RECEIPT or name.endswith(('.import', '.pyc')) or name == '.gdignore':
                continue
            if relative.parts[0] in ['final02', 'supplement01'] and 'screenshots' in relative.parts and str(relative.with_suffix('')) not in accepted_stems:
                continue
            target = DEST / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
            hash_value = digest(source)
            assert hash_value == digest(target), relative
            copied.append(dict(file=str(relative), sha256=hash_value))
            size += source.stat().st_size
    result = dict(source=str(SOURCE), destination=str(DEST), copied_files=len(copied), copied_bytes=size, excluded=sorted(SKIP), excluded_unaccepted_captures=True, accepted_screenshots=len(accepted), hash_mismatches=0, passed=True, files=copied)
    (SOURCE / RECEIPT).write_text(json.dumps(result, ensure_ascii=False, indent=2))
    shutil.copy2(SOURCE / RECEIPT, DEST / RECEIPT)
    print(json.dumps({k: v for k, v in result.items() if k != 'files'}, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    main()
