"""Verify this presentation-only change does not affect combat contracts."""
import hashlib,json,re,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
BASE='3ce33b29'
def git(*args):return subprocess.check_output(['git',*args],cwd=ROOT,text=True)
path='gameplay/battle/battle.gd'
old=git('show',BASE+':'+path);new=(ROOT/path).read_text()
def funcs(s):return {m.group(1):m.group(0) for m in re.finditer(r'^func (\w+)\([^\n]*\n(?:(?!^func ).*\n?)*',s,re.M)}
a,b=funcs(old),funcs(new)
changed=[k for k in a if a[k]!=b.get(k)]
assert changed==['_spawn_character_weapon_visual'],changed
protected=[k for k,v in a.items() if any(t in v for t in ('_audit_combat_rng','_gameplay_now_seconds','audit_spawn_index'))]
assert all(a[k]==b[k] for k in protected)
assert git('diff','--name-only',BASE,'--','data/').strip()=='data/themes.json'
before=json.loads(git('show',BASE+':data/themes.json'));after=json.loads((ROOT/'data/themes.json').read_text())
for catalog in (before,after):
    for t in catalog['themes']:
        t.pop('description_zh',None);t.pop('description_en',None)
assert before==after,'Non-copy theme change'
assert not git('diff','--name-only',BASE,'--','assets/').strip()
fingerprints=subprocess.check_output(['python3','tools/free_side_fingerprint.py','.','main'],cwd=ROOT,text=True).strip()
result=dict(base=BASE,changed_battle_functions=changed,protected_functions_unchanged=len(protected),theme_changes='description_zh/en only',assets_unchanged=True,free_fingerprints=fingerprints)
Path(__file__).with_name('scope.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
print(json.dumps(result,ensure_ascii=False))
