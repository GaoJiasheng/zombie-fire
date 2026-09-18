"""Read-only chapter-list captures; refuse resuming across changed source files."""
import copy, hashlib, importlib.util, json, os, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
AUDIT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('capture_audit', ROOT/'design/audits/ui_full_review_2026_09_08/verification/capture_audit.py')
capture = importlib.util.module_from_spec(spec); spec.loader.exec_module(capture)
(AUDIT/'verification').mkdir(exist_ok=True)
(AUDIT/'screenshots').mkdir(exist_ok=True)
(AUDIT/'screenshots/.gdignore').touch()
cases = []
for old in json.loads((ROOT/'design/audits/map_environment_art_2026_09_17/cases.json').read_text()):
    if old['group'] != 'after': continue
    p = copy.deepcopy(old['payload'])
    p.update(chapter=1, debug_scroll_y=0)
    p['save_override']['levels_progress'] = {f'level_{i:03d}':3 for i in range(1,100)}
    p['save_override']['unlocks']['levels'] = [f'level_{i:03d}' for i in range(1,100)]
    label = old['label']+'_chapter1'
    cases.append(dict(group='after', route='map', payload=p, label=label))
    if '_default_map' in label:
        q = copy.deepcopy(p); q['chapter'] = 0
        cases.append(dict(group='overview', route='map', payload=q, label=label.replace('chapter1','overview')))
        for chapter in (10,):
            q = copy.deepcopy(p); q['chapter'] = chapter
            cases.append(dict(group='edge', route='map', payload=q, label=label.replace('chapter1','chapter10')))
        q = copy.deepcopy(p)
        q['save_override']['levels_progress'] = {}
        q['save_override']['unlocks']['levels'] = ['level_001']
        cases.append(dict(group='edge', route='map', payload=q, label=label+'_unplayed'))
cases.sort(key=lambda r: ('_default_map' not in r['label'], r['group']!='after', r['label']))
path = AUDIT/'cases.json'; path.write_text(json.dumps(cases, ensure_ascii=False, indent=2))
sources = ['meta/map/map.gd','tools/m1_smoke_test.gd','tools/_shot.gd']
hashes = {p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}
seal = AUDIT/'verification/source.json'
if seal.exists(): assert json.loads(seal.read_text()) == hashes, 'Mixed-source resume refused'
seal.write_text(json.dumps(hashes,indent=2))
(AUDIT/'verification/runtime.patch').write_bytes(subprocess.check_output(['git','diff','--binary','--',*sources],cwd=ROOT))
os.environ['ZOMBIE_FIRE_ALLOW_WINDOW_CAPTURE']='1'
os.environ['ZOMBIE_FIRE_CAPTURE_READONLY']='1'
capture.AUDIT = AUDIT
sys.argv = [__file__,'--case-file',str(path)] + sys.argv[1:]
code = capture.main()
assert hashes == {p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}
raise SystemExit(code)
