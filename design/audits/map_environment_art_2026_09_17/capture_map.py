"""Replay all map themes and capture the owner's early-campaign composition."""
import copy, hashlib, importlib.util, json, os, subprocess, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
AUDIT=Path(__file__).resolve().parent
PREVIOUS=ROOT/'design/audits/map_boss_badges_2026_09_17'
spec=importlib.util.spec_from_file_location('capture_audit',ROOT/'design/audits/ui_full_review_2026_09_08/verification/capture_audit.py')
capture=importlib.util.module_from_spec(spec);spec.loader.exec_module(capture)
(AUDIT/'verification').mkdir(exist_ok=True)
(AUDIT/'screenshots').mkdir(exist_ok=True)
(AUDIT/'screenshots/.gdignore').touch()
cases=[]
for row in json.loads((PREVIOUS/'cases.json').read_text()):
    if row['group']!='after':continue
    case=copy.deepcopy(row)
    case['before']=str(PREVIOUS/'screenshots/after'/(row['label']+'.png'))
    cases.append(case)
    if '_default_map' in row['label']:
        p=copy.deepcopy(row['payload'])
        p['debug_scroll_y']=0
        p['save_override']['levels_progress']={f'level_{i:03d}':(3 if i%2 else 2) for i in range(1,21)}
        p['save_override']['unlocks']['levels']=[f'level_{i:03d}' for i in range(1,22)]
        cases.append(dict(group='featured',route='map',payload=p,label=row['label']+'_early_campaign'))
assert len(cases)==36
cases.sort(key=lambda r: (r['group']!='featured',r['label']))
path=AUDIT/'cases.json';path.write_text(json.dumps(cases,ensure_ascii=False,indent=2))
sources=['meta/map/map.gd','meta/map/chapter_boss_badge.gd','tools/m1_smoke_test.gd','tools/_shot.gd']
hashes={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}
seal=AUDIT/'verification/source.json'
if seal.exists():assert json.loads(seal.read_text())==hashes,'Mixed-source resume refused'
seal.write_text(json.dumps(hashes,indent=2))
(AUDIT/'verification/runtime.patch').write_bytes(subprocess.check_output(['git','diff','--binary','--',*sources],cwd=ROOT))
os.environ['ZOMBIE_FIRE_ALLOW_WINDOW_CAPTURE']='1';os.environ['ZOMBIE_FIRE_CAPTURE_READONLY']='1'
capture.AUDIT=AUDIT;sys.argv=[__file__,'--case-file',str(path)]
code=capture.main()
assert hashes=={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}
raise SystemExit(code)
