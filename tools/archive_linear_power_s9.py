#!/usr/bin/env python3
"""Preserve §9 native evidence outside /tmp; not an application package."""
import hashlib
import json
from pathlib import Path
import tarfile

import run_linear_power_s9 as s9
import solve_runtime_clear_lines as t1


def main():
    s9.guard()
    destination=Path('/Users/gavin/Desktop/zombiefire_evidence/linear_power_s9_2026_10_05.tar.gz')
    assert destination.parent.is_dir() and not destination.exists(), 'never overwrite an archive'
    records=json.loads(s9.JOURNAL.read_text())
    paths={s9.BASE,s9.JOURNAL,s9.OUT/'integrity.json',s9.OUT/'current_contracts.json'}
    for record in records:
        label=record['label']
        paths.update(s9.OUT/(label+suffix) for suffix in ('.json','_inputs.json','_summary.json'))
        log=Path(record['log'])
        assert log.parent==Path('/tmp') and log.name.startswith('zf_linear_s9_')
        paths.add(log)
        raw=log.with_suffix('')
        assert raw.is_dir()
        paths.update(p for p in raw.iterdir() if p.suffix in ('.json','.log'))
    paths.update(Path('/tmp').glob('zf_linear_s9_*_2026_10_05.log'))
    # The archive command's own stdout is still open and cannot hash itself.
    paths.discard(Path('/tmp/zf_linear_s9_archive_continue_2026_10_05.log'))
    manifest=[]
    for path in sorted(paths):
        assert path.is_file()
        arcname=('repository/'+str(path.relative_to(s9.ROOT)) if path.is_relative_to(s9.ROOT)
                 else 'logs/'+str(path.relative_to('/tmp')))
        manifest.append({'source':str(path),'member':arcname,
                         'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    manifest_path=s9.OUT/'s9_archive_manifest.json'
    t1.atomic_write(manifest_path,{'native_groups':len(records),'files':manifest})
    with tarfile.open(destination,'x:gz') as archive:
        for item in manifest:archive.add(item['source'],arcname=item['member'],recursive=False)
        archive.add(manifest_path,arcname='manifest.json',recursive=False)
    with tarfile.open(destination,'r:gz') as archive:
        for item in manifest:
            stream=archive.extractfile(item['member'])
            assert stream and hashlib.sha256(stream.read()).hexdigest()==item['sha256'],item['member']
    result={'path':str(destination),'sha256':hashlib.sha256(destination.read_bytes()).hexdigest(),
            'files_verified':len(manifest),'native_groups':len(records),'status':'PASS',
            'application_package':False,'git_included':False}
    t1.atomic_write(s9.OUT/'s9_archive_record.json',result)
    print(json.dumps(result,ensure_ascii=False,indent=2))


if __name__=='__main__':main()
