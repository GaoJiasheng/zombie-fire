# -*- coding: utf-8 -*-
"""Verify native captures and publish a five-theme original-weapon review."""
import hashlib,html,json,re,shutil
from pathlib import Path
from PIL import Image
A=Path(__file__).resolve().parent
D=Path('/Users/gavin/Desktop/zombiefire_screenshots/23_武器保持原貌_2026_09_18')
gate=(A/'release_candidate.log').read_text()
assert 'Release candidate check OK' in gate and 'M1 smoke test passed' in gate
assert not re.search(r'ERROR:|check failed',gate,re.I)
cases=json.loads((A/'cases.json').read_text());assert len(cases)==66,len(cases)
rows=[]
for c in cases:
    p=A/'screenshots'/c['group']/(c['label']+'.png')
    r=json.loads(p.with_suffix('.json').read_text())
    assert r['capture_exit']==0 and not r['runtime_issues'] and not r['image_issues'],c['label']
    assert not re.search(r'ERROR:',p.with_suffix('.log').read_text()),c['label']
    assert hashlib.sha256(p.read_bytes()).hexdigest()==r['sha256']
    with Image.open(p) as im:assert list(im.size)==c['payload']['viewport_size']
    target=D/'after'/p.name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,target)
    rows.append(dict(label=c['label'],image=str(target.relative_to(D)),sha256=r['sha256']))
themes=[('default','默认'),('neon_tempest','霓虹'),('infernal_dominion','炼狱'),('polar_aurora','极光'),('gilded_eclipse','黄金')]
# Same unscaled first-weapon interior, away from themed UI borders/text.
# Inspection only: do not save or alter any screenshot pixels.
icon_hashes={}
for theme,_ in themes:
    with Image.open(D/'after'/f'weapons_{theme}_en_1080x1920.png') as im:
        icon_hashes[theme]=hashlib.sha256(im.convert('RGBA').crop((132,450,305,615)).tobytes()).hexdigest()
assert len(set(icon_hashes.values()))==1,icon_hashes
cards=[]
for theme,name in themes:
    src=Path('/Users/gavin/Desktop/zombiefire_screenshots/16_全量UI人肉预览_2026_09_14/原图/收藏与详情')/f'core_1080x1920_en_{theme}_collection_weapons.png'
    dst=D/'before'/src.name;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
    path=f'after/weapons_{theme}_en_1080x1920.png'
    cards.append(f'<section><h3>{name}</h3><a href="{path}"><img src="{path}"></a><p><a href="before/{src.name}">旧全量包参考图</a></p></section>')
links=''.join('<li><a href="'+r['image']+'">'+html.escape(r['label'])+'</a></li>' for r in rows)
page='''<!doctype html><html lang="zh"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>武器保持原貌 · 五主题对照</title><style>body{margin:24px;background:#101820;color:#eee;font:17px/1.7 system-ui}a{color:#94e3ef}.grid{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:12px}img{width:100%}li{overflow-wrap:anywhere}@media(max-width:900px){.grid{grid-template-columns:1fr 1fr}}</style><h1>武器保持原貌 · 五主题对照</h1><p>每把武器仍用自己的原始素材：只换界面主题，不换武器皮肤，也不额外染色。四把不同终焉武器各自保留身份，并非合为一把。锁定状态仍会统一变暗。</p><p>收藏列表/详情、快捷栏、配装和商店预览共用原始资源；保留人物战衣及既有角色特效。旧主题涂装文件未删除。66张静默离屏原生截图，中英、三主尺寸代表组合；不是全量UI重新渲染。</p><p>下方点击可看原图；修前引用9月14日旧全量包，仅比较武器外观，不比较不同存档数值。新截图全部零审计问题，完整非窗口发布门禁与m1通过。</p><div class="grid">'''+''.join(cards)+'</div><h2>全部新截图</h2><ul>'+links+'</ul></html>'
page=page.replace('<h2>全部新截图</h2>', '<p>人工补充：商店详情在左右各44px安全区压力配置下仍有既有横向压边，本轮未改布局，不能把自动零提示理解为全UI零缺陷。详见<a href="修补说明.md">修补说明</a>。</p><h2>全部新截图</h2>')
(D/'00_五主题武器原貌.html').write_text(page,encoding='utf-8')
(D/'截图清单.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2))
shutil.copy2(A/'修补说明.md',D/'修补说明.md')
for r in rows:assert hashlib.sha256((D/r['image']).read_bytes()).hexdigest()==r['sha256']
result=dict(screenshots=len(rows),audit_issues=0,release_candidate='passed',m1='passed',desktop=str(D),desktop_hashes_verified=True,first_weapon_pixel_hashes=icon_hashes)
(A/'result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
print(json.dumps(result,ensure_ascii=False))
