"""Capture the current chapter layout with source-sealed before/after evidence."""
import argparse,hashlib,importlib.util,json,os,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
BASE=Path(__file__).resolve().parent
ap=argparse.ArgumentParser();ap.add_argument('--phase',choices=('before','after'),required=True);args,rest=ap.parse_known_args()
A=BASE/args.phase;A.mkdir(exist_ok=True)
spec=importlib.util.spec_from_file_location('capture_audit',ROOT/'design/audits/ui_full_review_2026_09_08/verification/capture_audit.py')
c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c)
cases=json.loads((ROOT/'design/audits/map_level_layout_2026_09_18/cases.json').read_text())
(A/'verification').mkdir(exist_ok=True);(A/'screenshots').mkdir(exist_ok=True);(A/'screenshots/.gdignore').touch()
sources=['meta/map/map.gd','meta/map/map.tscn','ui/ui_kit.gd','data/themes.json','tools/_shot.gd']
hashes={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}
seal=A/'verification/source.json'
if seal.exists():assert json.loads(seal.read_text())==hashes,'Mixed-source resume refused'
seal.write_text(json.dumps(hashes,indent=2));(A/'cases.json').write_text(json.dumps(cases,ensure_ascii=False,indent=2))
os.environ['ZOMBIE_FIRE_ALLOW_WINDOW_CAPTURE']='1';os.environ['ZOMBIE_FIRE_CAPTURE_READONLY']='1'
c.AUDIT=A;sys.argv=[__file__,'--case-file',str(A/'cases.json')]+rest
code=c.main()
assert hashes=={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}
raise SystemExit(code)
