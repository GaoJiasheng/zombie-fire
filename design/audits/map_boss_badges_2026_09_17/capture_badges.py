"""Map-only screenshot replay; isolated read-only GodotQuiet, serial captures."""
import copy, hashlib, importlib.util, json, os, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
AUDIT = Path(__file__).resolve().parent
OLD = ROOT / 'design/audits/ui_finish_2026_09_08'
spec = importlib.util.spec_from_file_location('capture_audit', ROOT / 'design/audits/ui_full_review_2026_09_08/verification/capture_audit.py')
capture = importlib.util.module_from_spec(spec); spec.loader.exec_module(capture)
(AUDIT/'verification').mkdir(exist_ok=True)
(AUDIT/'screenshots').mkdir(exist_ok=True)
(AUDIT/'screenshots/.gdignore').touch()
sources = ['meta/map/map.gd','meta/map/chapter_boss_badge.gd','data/localization_ui_en.json','tools/_shot.gd']
hashes = {p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}
seal = AUDIT/'verification/source.json'
if seal.exists(): assert json.loads(seal.read_text()) == hashes, 'Mixed-source capture refused'
seal.write_text(json.dumps(hashes, indent=2))
(AUDIT/'verification/runtime.patch').write_bytes(subprocess.check_output(['git','diff','--binary','--',*sources],cwd=ROOT))
cases=[]
for record in json.loads((OLD/'verification/accepted_screenshots.json').read_text()):
    if not (record['label'].startswith('core_') and record['label'].endswith('_map')): continue
    src=OLD/record['file']; row=json.loads(src.with_suffix('.json').read_text())
    cases.append(dict(group='after', route='map', payload=row['payload'], label=row['label'], before=str(src)))
    if '_default_map' in row['label']:
        for kind in ('minor','major'):
            p=copy.deepcopy(row['payload']); p['debug_map_boss_hint']=kind
            cases.append(dict(group='hints', route='map', payload=p, label=row['label']+'_'+kind))
assert len(cases)==42,len(cases)
cases.sort(key=lambda r: ('_default_' not in r['label'],r['label']))
path=AUDIT/'cases.json';path.write_text(json.dumps(cases,ensure_ascii=False,indent=2))
os.environ['ZOMBIE_FIRE_ALLOW_WINDOW_CAPTURE']='1';os.environ['ZOMBIE_FIRE_CAPTURE_READONLY']='1'
capture.AUDIT=AUDIT
sys.argv=[__file__,'--case-file',str(path),*sys.argv[1:]]
result=capture.main()
assert hashes == {p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}
raise SystemExit(result)
