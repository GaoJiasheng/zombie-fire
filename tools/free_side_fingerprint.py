#!/usr/bin/env python3
"""免费侧战斗输入指纹。用法: free_fingerprint.py <repo_dir> [<git_ref>]
覆盖 levels(波次/系数/Boss)、weapons(数值+整个 special 子表+成长段)、economy(非付费键)。"""
import json, hashlib, subprocess, sys
repo=sys.argv[1]; ref=sys.argv[2] if len(sys.argv)>2 else None
def load(rel):
    if ref: return json.loads(subprocess.run(['git','-C',repo,'show',f'{ref}:{rel}'],capture_output=True,text=True).stdout)
    return json.load(open(f'{repo}/{rel}'))
def rows(d): 
    r=d['levels'] if isinstance(d,dict) and 'levels' in d else (list(d.values()) if isinstance(d,dict) else d)
    return [x for x in r if isinstance(x,dict)]
def h(obj): return hashlib.sha256(json.dumps(obj,sort_keys=True,ensure_ascii=False).encode()).hexdigest()[:16]
lv=[(r.get('id'),{k:r.get(k) for k in ['difficulty_coef','waves','primary_weakness','base_hp_ref','runtime_bosses','offer_category_floor','wave_pattern'] if k in r}) for r in rows(load('data/levels.json'))]
wp=[(r.get('name_key'),{k:r.get(k) for k in ['base_atk_coef','fire_interval','max_level','element','projectile_type','level_growth_segments','endgame_damage_growth_bonus','endgame_growth_curve','special'] if k in r}) for r in rows(load('data/weapons.json'))]
ec={k:v for k,v in load('data/economy.json').items() if 'premium' not in k.lower()}
print(f"levels={h(sorted(lv))} weapons={h(sorted(wp))} economy={h(ec)}")
