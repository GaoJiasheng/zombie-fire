"""Replay affected accepted cases through the existing quiet/read-only pipeline."""
import argparse, hashlib, importlib.util, json, os, re, shutil, subprocess, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
AUDIT=Path(__file__).resolve().parent
OLD=ROOT/'design/audits/ui_finish_2026_09_08'
spec=importlib.util.spec_from_file_location('capture_audit',ROOT/'design/audits/ui_full_review_2026_09_08/verification/capture_audit.py')
capture=importlib.util.module_from_spec(spec);spec.loader.exec_module(capture)
parser=argparse.ArgumentParser();parser.add_argument('batch',choices=['pilot','after']);parser.add_argument('--retry-exit-cleanup',action='store_true');args=parser.parse_args()
target=AUDIT/args.batch;target.mkdir(exist_ok=True)
(target/'verification').mkdir(exist_ok=True);(target/'screenshots').mkdir(exist_ok=True)
(target/'screenshots/.gdignore').touch()
cases=[]
for record in json.loads((OLD/'verification/accepted_screenshots.json').read_text()):
    src=OLD/record['file'];row=json.loads(src.with_suffix('.json').read_text());p=row['payload']
    if row['route']!='battle' or not (p.get('card_offer') or p.get('card_detail')):continue
    if args.batch=='pilot' and not (row['label'].startswith('core_') and '_default_card_offer' in row['label']):continue
    cases.append(dict(group='after',route='battle',payload=p,label=row['label'],before=str(src)))
assert cases
path=target/'cases.json';path.write_text(json.dumps(cases,ensure_ascii=False,indent=2))
snapshot=subprocess.check_output(['git','diff','--binary','--','gameplay','tools/m1_smoke_test.gd'],cwd=ROOT)
sources={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in ['gameplay/battle/battle.gd','tools/m1_smoke_test.gd']}
if (target/'verification/source.json').exists():
    assert json.loads((target/'verification/source.json').read_text())==sources,'Refuse mixed-source resume'
if args.retry_exit_cleanup:
    for record in (target/'screenshots').rglob('*.json'):
        errors=re.findall(r'^.*(?:ERROR:|SCRIPT ERROR:|Parse Error:).*$',record.with_suffix('.log').read_text(),re.M)
        if not errors:continue
        assert all(re.fullmatch(r'ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.',e) for e in errors),errors
        archive=target/'verification/rejected_exit_cleanup'/record.stem
        assert not archive.exists(),'Repeated cleanup failure requires diagnosis'
        archive.mkdir(parents=True)
        for ext in ['.json','.log','.png']:shutil.move(record.with_suffix(ext),archive/(record.stem+ext))
        print('Preserved exit-cleanup failure for identical-source retry: '+record.stem,flush=True)
(target/'verification/runtime.patch').write_bytes(snapshot)
(target/'verification/source.json').write_text(json.dumps(sources,indent=2))
os.environ['ZOMBIE_FIRE_ALLOW_WINDOW_CAPTURE']='1';os.environ['ZOMBIE_FIRE_CAPTURE_READONLY']='1'
capture.AUDIT=target;sys.argv=[__file__,'--case-file',str(path)]
result=capture.main()
assert subprocess.check_output(['git','diff','--binary','--','gameplay','tools/m1_smoke_test.gd'],cwd=ROOT)==snapshot
raise SystemExit(result)
