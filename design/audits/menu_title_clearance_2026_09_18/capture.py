"""Capture all five menu themes in both languages at native device sizes."""
import argparse,copy,hashlib,importlib.util,json,os,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
BASE=Path(__file__).resolve().parent
ap=argparse.ArgumentParser();ap.add_argument('--phase',choices=['before','after'],default='after');args,rest=ap.parse_known_args()
A=BASE/args.phase;A.mkdir(exist_ok=True)
spec=importlib.util.spec_from_file_location('capture_audit',ROOT/'design/audits/ui_full_review_2026_09_08/verification/capture_audit.py')
c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c)
cases=[]
for theme in c.visual.THEME_IDS:
    for lang in ('zh','en'):
        for w,h in ((1080,1920),(1320,2868),(750,1334)):
            p=dict(language=lang,viewport_size=[w,h],_visual_safe_insets=c.visual.DEBUG_SAFE_INSETS,save_override=copy.deepcopy(c.visual.PREMIUM_CROSS_SAVE_OVERRIDES[theme]))
            cases.append(dict(group='final',route='menu',payload=p,label=f'menu_{theme}_{lang}_{w}x{h}'))
(A/'verification').mkdir(exist_ok=True);(A/'screenshots').mkdir(exist_ok=True);(A/'screenshots/.gdignore').touch()
sources=['meta/menu/menu.gd','data/themes.json']
for theme in c.visual.THEME_IDS:
    if theme=='default':continue
    sources += [f'assets/production/sprites/themes/{theme}/ui/ui_menu_title_{name}.png' for name in ('shichao_fangxian','zombie_fire')]
hashes={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}
seal=A/'verification/source.json'
if seal.exists():assert json.loads(seal.read_text())==hashes,'Mixed-source capture refused'
seal.write_text(json.dumps(hashes,indent=2));(A/'cases.json').write_text(json.dumps(cases,ensure_ascii=False,indent=2))
os.environ['ZOMBIE_FIRE_ALLOW_WINDOW_CAPTURE']='1';os.environ['ZOMBIE_FIRE_CAPTURE_READONLY']='1'
c.AUDIT=A;sys.argv=[__file__,'--case-file',str(A/'cases.json')]+rest
code=c.main()
assert hashes=={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}
raise SystemExit(code)
