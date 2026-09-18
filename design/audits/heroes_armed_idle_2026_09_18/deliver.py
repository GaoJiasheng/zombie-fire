# -*- coding: utf-8 -*-
"""Deliver exact screenshots with CSS-only before/after detail inspection."""
import hashlib,html,json,re,shutil
from pathlib import Path
from PIL import Image
A=Path(__file__).resolve().parent
D=Path('/Users/gavin/Desktop/zombiefire_screenshots/22_全角色持枪待机_2026_09_18')
gate=(A/'release_candidate.log').read_text()
assert 'Release candidate check OK' in gate and 'M1 smoke test passed' in gate
assert not re.search(r'ERROR:|check failed',gate,re.I)
assert 'All-hero armed-rest transition regression: 0 failures' in (A/'transitions.log').read_text()
rows=[]
for phase,count in (('before',3),('after',86)):
    cases=json.loads((A/phase/'cases.json').read_text());assert len(cases)==count
    for c in cases:
        p=A/phase/'screenshots'/c['group']/(c['label']+'.png')
        r=json.loads(p.with_suffix('.json').read_text())
        assert r['capture_exit']==0 and not r['runtime_issues'] and not r['image_issues'],c['label']
        assert not re.search(r'ERROR:',p.with_suffix('.log').read_text())
        assert hashlib.sha256(p.read_bytes()).hexdigest()==r['sha256']
        with Image.open(p) as im:assert list(im.size)==c['payload']['viewport_size']
        target=D/phase/p.name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,target)
        rows.append(dict(phase=phase,label=c['label'],image=str(target.relative_to(D)),sha256=r['sha256']))
panels=[]
for hero,name in [('vanguard','钢铁先锋'),('blaze','火焰少年'),('frost','冰霜少女')]:
    cells=[]
    for phase,pose,caption in [('before','idle','修复前：双手未持枪'),('after','idle','修复后：持枪待机'),('after','fire','原开火姿势保留')]:
        path=f'{phase}/{hero}_default_weapon_scattergun_{pose}_1080x1920.png'
        cells.append('<section><h3>'+caption+'</h3><a href="'+path+'"><div class="lens"><img src="'+path+'"></div></a></section>')
    panels.append('<h2>'+name+'</h2><div class="triple">'+''.join(cells)+'</div>')
links=''.join('<li><a href="'+r['image']+'">'+r['phase']+' · '+html.escape(r['label'])+'</a></li>' for r in rows)
page='''<!doctype html><html lang="zh"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>全角色持枪待机</title><style>body{max-width:1200px;margin:auto;padding:24px;background:#101b24;color:#e8eeee;font:17px/1.8 system-ui}a{color:#8ed8e8}.triple{display:grid;grid-template-columns:repeat(3,1fr);gap:18px}.lens{position:relative;overflow:hidden;height:380px;background:#070b0f}.lens img{position:absolute;width:230%;max-width:none;left:-65%;bottom:-60px}li{overflow-wrap:anywhere}@media(max-width:800px){.triple{grid-template-columns:1fr}}</style><h1>通过：另外三人也已统一持枪待机</h1><p>钢铁先锋、火焰少年、冰霜少女都存在同类旧待机/受击姿势：双手没有握住当前武器，开枪时才突然切到持枪造型。现与闪电少女共用持枪准备姿势规则，保留每人每把枪原有的射击动作、呼吸与受击运动。</p><p>没有重新出图，没有修改数值、弹道或瞄准。四角色八普通武器共288轮三方向开火/停火/受击切换通过；新增86张最终实拍及3张修前对照，完整非窗口发布门禁与m1通过。四把付费武器原本已持续持枪，不改其素材路径。</p><p>以下仅用网页放大原始截图，不修改图片像素。点击查看完整原图。截图为静默离屏模拟，不是真机实测。</p>'''+''.join(panels)+'''<h2>覆盖说明</h2><p>三角色八武器待机/开火48张；散弹枪四种额外外观24张；散弹枪额外高屏与SE12张；闪电少女2张回归。不是所有外观与武器的全笛卡尔积。其余皮肤沿用同一素材加载规则。</p><h2>全部原图</h2><ul>'''+links+'</ul></html>'
(D/'00_三角色前后对照.html').write_text(page,encoding='utf-8')
(D/'截图清单.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2))
shutil.copy2(A/'修补说明.md',D/'修补说明.md')
for r in rows:assert hashlib.sha256((D/r['image']).read_bytes()).hexdigest()==r['sha256']
result=dict(final_screenshots=86,before_screenshots=3,audit_issues=0,transition_cycles=288,release_candidate='passed',m1='passed',desktop=str(D),desktop_hashes_verified=True)
(A/'result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
print(json.dumps(result,ensure_ascii=False))
