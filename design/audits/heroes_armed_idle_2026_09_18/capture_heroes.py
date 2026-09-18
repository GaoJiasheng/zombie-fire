"""Capture three newly corrected heroes, with a preserved before-source seal."""
import argparse,copy,hashlib,importlib.util,json,os,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
BASE=Path(__file__).resolve().parent
ap=argparse.ArgumentParser();ap.add_argument('--phase',choices=('before','after'),default='after')
args,remaining=ap.parse_known_args()
AUDIT=BASE/args.phase;AUDIT.mkdir(exist_ok=True)
spec=importlib.util.spec_from_file_location('capture_audit',ROOT/'design/audits/ui_full_review_2026_09_08/verification/capture_audit.py')
capture=importlib.util.module_from_spec(spec);spec.loader.exec_module(capture)
visual=capture.visual
(AUDIT/'verification').mkdir(exist_ok=True)
(AUDIT/'screenshots').mkdir(exist_ok=True)
(AUDIT/'screenshots/.gdignore').touch()
weapons=json.loads((ROOT/'data/weapons.json').read_text())
cases=[]
for hero in ('vanguard','blaze','frost','volt'):
    for theme in visual.THEME_IDS:
        for weapon,row in weapons.items():
            if row.get('presentation',{}).get('true_grip'):continue
            if hero=='volt' and (theme!='default' or weapon!='weapon_scattergun'):continue
            if theme!='default' and weapon!='weapon_scattergun':continue
            if args.phase=='before' and (hero=='volt' or theme!='default' or weapon!='weapon_scattergun'):continue
            for pose in (('idle',) if args.phase=='before' else ('idle','fire')):
                sizes=[[1080,1920]]
                if hero!='volt' and theme=='default' and weapon=='weapon_scattergun' and args.phase=='after':sizes += [[1320,2868],[750,1334]]
                for size in sizes:
                    p=dict(level_id='level_001',language='zh',viewport_size=size,save_override=copy.deepcopy(visual.PREMIUM_CROSS_SAVE_OVERRIDES[theme]),equipment={'selected_character':hero,'selected_weapon':weapon,hero:18,weapon:18},_visual_safe_insets=visual.DEBUG_SAFE_INSETS)
                    if pose=='idle':p['debug_character_idle_frame']=1
                    else:p.update(debug_character_shooting_frame=4,debug_character_shooting_aim='center',debug_character_shooting_muzzle=True)
                    cases.append(dict(group='final',route='battle',payload=p,label=f'{hero}_{theme}_{weapon}_{pose}_{size[0]}x{size[1]}'))
cases.sort(key=lambda c: ('weapon_scattergun' not in c['label'],c['label']))
path=AUDIT/'cases.json';path.write_text(json.dumps(cases,ensure_ascii=False,indent=2))
sources=['gameplay/battle/battle.gd','tools/m1_smoke_test.gd','tools/_shot.gd']
hashes={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}
seal=AUDIT/'verification/source.json'
if seal.exists():assert json.loads(seal.read_text())==hashes,'Mixed-source resume refused'
seal.write_text(json.dumps(hashes,indent=2))
(AUDIT/'verification/runtime.patch').write_bytes(subprocess.check_output(['git','diff','--binary','--',*sources],cwd=ROOT))
os.environ['ZOMBIE_FIRE_ALLOW_WINDOW_CAPTURE']='1';os.environ['ZOMBIE_FIRE_CAPTURE_READONLY']='1'
capture.AUDIT=AUDIT;sys.argv=[__file__,'--case-file',str(path)]+remaining
code=capture.main()
assert hashes=={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}
raise SystemExit(code)
