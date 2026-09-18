"""Assert the follow-up changes only the existing armed-rest eligibility."""
import hashlib,json,re,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
BASE='663618d722ebacb0131eefd3061b5381088e65ac'
path='gameplay/battle/battle.gd'
old=subprocess.check_output(['git','show',BASE+':'+path],cwd=ROOT,text=True)
new=(ROOT/path).read_text()
def funcs(s):return {m.group(1):m.group(0) for m in re.finditer(r'^func (\w+)\([^\n]*\n(?:(?!^func ).*\n?)*',s,re.M)}
a,b=funcs(old),funcs(new)
changed=[k for k in a if a[k]!=b.get(k)]
protected=[k for k,v in a.items() if any(t in v for t in ('_audit_combat_rng','_gameplay_now_seconds','audit_spawn_index'))]
assert all(a[k]==b[k] for k in protected)
assert changed==['_load_character_animation_frames'],changed
assert not subprocess.check_output(['git','diff','--name-only',BASE,'--','data/','assets/'],cwd=ROOT,text=True).strip()
fingerprints=subprocess.check_output(['python3','tools/free_side_fingerprint.py','.','main'],cwd=ROOT,text=True).strip()
report=dict(base=BASE,changed_functions=changed,protected_function_count=len(protected),protected_unchanged=True,data_and_assets_unchanged=True,free_fingerprints=fingerprints,battle_sha256=hashlib.sha256(new.encode()).hexdigest())
Path(__file__).with_name('scope.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
print(json.dumps(report,ensure_ascii=False))
