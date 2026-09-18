"""Original-weapon regression: native screenshots, isolated read-only saves."""
import copy,hashlib,importlib.util,json,os,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
A=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('capture_audit',ROOT/'design/audits/ui_full_review_2026_09_08/verification/capture_audit.py')
capture=importlib.util.module_from_spec(spec);spec.loader.exec_module(capture)
v=capture.visual
cases=[]
def add(route,label,p):
    p.setdefault('viewport_size',[1080,1920]);p['_visual_safe_insets']=v.DEBUG_SAFE_INSETS
    cases.append(dict(group='final',route=route,label=label,payload=p))
for theme in v.THEME_IDS:
    for lang in ('zh','en'):
        for w,h in ((1080,1920),(1320,2868),(750,1334)):
            add('collection',f'weapons_{theme}_{lang}_{w}x{h}',dict(mode='weapons',language=lang,viewport_size=[w,h],save_override=copy.deepcopy(v.PREMIUM_CROSS_SAVE_OVERRIDES[theme])))
        add('loadout',f'loadout_{theme}_{lang}',dict(language=lang,level_id='level_003',save_override=copy.deepcopy(v.PREMIUM_CROSS_SAVE_OVERRIDES[theme]),equipment={'selected_character':'vanguard','selected_weapon':'weapon_autocannon'}))
    for scroll in (1000,2000):
        add('collection',f'weapons_{theme}_en_scroll{scroll}',dict(mode='weapons',language='en',debug_scroll_y=scroll,save_override=copy.deepcopy(v.PREMIUM_CROSS_SAVE_OVERRIDES[theme])))
for route,p,label in v.STORE_PRODUCT_DETAIL_SCREENS:
    if '.theme.' not in p.get('debug_store_detail_product',''):continue
    for scroll in (0,10000):
        q=copy.deepcopy(p);q.update(debug_scroll_y=scroll,viewport_size=[1080,1920])
        add(route,label.replace('store_tall_', 'store_')+f'_scroll{scroll}',q)
(A/'verification').mkdir(exist_ok=True)
(A/'screenshots').mkdir(exist_ok=True);(A/'screenshots/.gdignore').touch()
paths=['core/theme/theme_manager.gd','ui/ui_kit.gd','meta/collection/collection.gd','meta/loadout/loadout.gd','meta/store/store.gd','gameplay/battle/battle.gd','data/themes.json']
hashes={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in paths}
seal=A/'verification/source.json'
if seal.exists():assert json.loads(seal.read_text())==hashes,'Mixed-source captures refused'
seal.write_text(json.dumps(hashes,indent=2))
(A/'cases.json').write_text(json.dumps(cases,ensure_ascii=False,indent=2))
os.environ['ZOMBIE_FIRE_ALLOW_WINDOW_CAPTURE']='1';os.environ['ZOMBIE_FIRE_CAPTURE_READONLY']='1'
capture.AUDIT=A;sys.argv=[__file__,'--case-file',str(A/'cases.json')]+sys.argv[1:]
code=capture.main()
assert hashes=={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in paths}
raise SystemExit(code)
