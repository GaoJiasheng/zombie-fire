#!/usr/bin/env python3
"""Preserve §9.1 native evidence on Desktop and verify each archived byte."""
import hashlib
import json
from pathlib import Path
import tarfile

import run_linear_power_s91 as run
import solve_runtime_clear_lines as t1


def main():
    run.previous.guard()
    output=Path('/Users/gavin/Desktop/zombiefire_evidence/linear_power_s91_2026_10_05.tar.gz')
    assert not output.exists(), 'preserve earlier archives'
    sources={}
    def add(path, name):
        assert path.is_file(), path
        assert name not in sources or sources[name]==path
        sources[name]=path
    for path in run.OUT.rglob('*'):
        if path.is_file() and path.name!='archive_record.json':
            add(path,'audit/'+str(path.relative_to(run.OUT)))
    for path in Path('/tmp').glob('zf_linear_s91*2026_10_05.log'):
        add(path,'logs/'+path.name)
    for record in json.loads((run.OUT/'commands.json').read_text()):
        directory=Path(record['log']).with_suffix('')
        assert directory.is_dir()
        for path in directory.rglob('*'):
            if path.is_file():add(path,'raw/'+directory.name+'/'+str(path.relative_to(directory)))
    # Historical groups are reused, not rerun; preserve their immutable archive
    # and source JSON alongside the new evidence. Do not replace old archives.
    old=Path('/Users/gavin/Desktop/zombiefire_evidence/linear_power_s9_2026_10_05.tar.gz')
    assert hashlib.sha256(old.read_bytes()).hexdigest()=='4b89dfed481ee9b7508bf80d1add029302d68db49d7856e6632e5bbb57df3a9b'
    add(old,'historical/'+old.name)
    for directory in (run.previous.OUT,run.ROOT/'design/audits/linear_power_p4_2026_10_04'):
        for path in directory.glob('*.json'):
            add(path,'historical/'+directory.name+'/'+path.name)
    hashes={name:hashlib.sha256(path.read_bytes()).hexdigest() for name,path in sources.items()}
    manifest=run.OUT/'archive_manifest.json'
    t1.atomic_write(manifest,{'source_count':len(hashes),'sha256':hashes,
                             'source_paths':{name:str(path) for name,path in sources.items()},
                             'historical_reuse':'unchanged complete raw groups, same expanded rules'})
    add(manifest,'audit/archive_manifest.json')
    hashes['audit/archive_manifest.json']=hashlib.sha256(manifest.read_bytes()).hexdigest()
    output.parent.mkdir(parents=True,exist_ok=True)
    with tarfile.open(output,'x:gz') as archive:
        for name,path in sorted(sources.items()):archive.add(path,arcname=name,recursive=False)
    with tarfile.open(output,'r:gz') as archive:
        names={m.name for m in archive.getmembers() if m.isfile()}
        assert names==set(hashes)
        for name,expected in hashes.items():
            assert hashlib.sha256(archive.extractfile(name).read()).hexdigest()==expected,name
    record={'archive':str(output),'files':len(hashes),'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),
            'verification':'PASS; every file independently SHA256 checked; old archive unchanged',
            'snapshot':'reports and logs at archive time; final delivery record may follow'}
    t1.atomic_write(run.OUT/'archive_record.json',record)
    print(json.dumps(record,ensure_ascii=False,indent=2))


if __name__=='__main__':main()
