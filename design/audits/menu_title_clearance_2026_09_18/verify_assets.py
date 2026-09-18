"""Validate replacement identity, transparency and unchanged menu controls."""
import hashlib,json,subprocess
from pathlib import Path
from PIL import Image

A=Path(__file__).resolve().parent
ROOT=A.parents[2]
S=ROOT/'assets/production/source_refs/generated/menu_title_clearance_2026_09_18'
manifest=json.loads((S/'selected_manifest.json').read_text())
checks=[]
for e in manifest['entries']:
    name='ui_menu_title_'+('shichao_fangxian' if e['language']=='zh' else 'zombie_fire')+'.png'
    relative=Path('assets/production/sprites/themes')/e['theme']/'ui'/name
    p=ROOT/relative
    generated=S/(e['theme']+'_'+e['language']+'.png')
    assert p.read_bytes()==generated.read_bytes(),p
    archived=ROOT/'assets/production/source_refs/rejected_menu_title_clearance_2026_09_18'/e['theme']/name
    original=subprocess.check_output(['git','show','4a0423aa:'+relative.as_posix()],cwd=ROOT)
    assert archived.read_bytes()==original,archived
    with Image.open(p) as im:
        assert im.mode=='RGBA' and im.size==(1536,1024),(p,im.mode,im.size)
        a=im.getchannel('A');assert a.getextrema()[0]==0 and a.getextrema()[1]>=250,p
        assert all(a.getpixel(pos)==0 for pos in ((0,0),(1535,0),(0,1023),(1535,1023))),p
    checks.append(dict(theme=e['theme'],language=e['language'],runtime=relative.as_posix(),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),original_archived=True,rgba=True))
for p in ('meta/menu/menu.gd','meta/menu/menu.tscn','ui/ui_kit.gd','gameplay/battle/battle.gd'):
    assert (ROOT/p).read_bytes()==subprocess.check_output(['git','show','4a0423aa:'+p],cwd=ROOT),p
current=json.loads((ROOT/'data/themes.json').read_text())
baseline=json.loads(subprocess.check_output(['git','show','4a0423aa:data/themes.json'],cwd=ROOT))
# Only replace stale Gilded title crop dimensions; no content/numeric gameplay edits.
def remove_gilded_regions(v):
    if isinstance(v,dict):
        if v.get('id')=='gilded_eclipse':
            for key in ('menu_title','menu_title_zh'):
                v['ui']['asset_presentations'][key]['region']=[]
        for c in v.values():remove_gilded_regions(c)
    elif isinstance(v,list):
        for c in v:remove_gilded_regions(c)
remove_gilded_regions(current);remove_gilded_regions(baseline)
assert current==baseline,'Unexpected theme edits'
(A/'asset_verification.json').write_text(json.dumps(dict(assets=checks,unchanged_menu_controls=True,unchanged_global_font=True,unchanged_battle=True),indent=2))
print('TITLE ASSET CHECK PASSED: 6 RGBA replacements; old originals archived; menu controls, FONT_SCALE and battle unchanged.')
