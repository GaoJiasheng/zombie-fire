# -*- coding: utf-8 -*-
"""Verify every capture, deliver unmodified images and an HTML review lens."""
import hashlib, html, json, re, shutil
from pathlib import Path
from PIL import Image
A=Path(__file__).resolve().parent
D=Path('/Users/gavin/Desktop/zombiefire_screenshots/21_闪电少女持枪待机_2026_09_18')
gate=(A/'release_candidate.log').read_text()
assert 'Release candidate check OK' in gate and 'M1 smoke test passed' in gate
assert not re.search(r'ERROR:|check failed',gate,re.I)
assert 'Volt armed-rest transition regression: 0 failures' in (A/'transitions.log').read_text()
rows=[]
for c in json.loads((A/'cases.json').read_text()):
    p=A/'screenshots'/c['group']/(c['label']+'.png')
    r=json.loads(p.with_suffix('.json').read_text())
    assert r['capture_exit']==0 and not r['runtime_issues'] and not r['image_issues'],c['label']
    assert not re.search(r'ERROR:',p.with_suffix('.log').read_text())
    assert hashlib.sha256(p.read_bytes()).hexdigest()==r['sha256']
    with Image.open(p) as im:assert list(im.size)==c['payload']['viewport_size']
    target=D/c['group']/p.name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,target)
    rows.append(dict(label=c['label'],image=str(target.relative_to(D)),sha256=r['sha256']))
assert len(rows)==84
idle='featured/default_weapon_scattergun_idle_1320x2868.png'
fire='featured/default_weapon_scattergun_fire_1320x2868.png'
links=''.join('<li><a href="'+r['image']+'">'+html.escape(r['label'])+'</a></li>' for r in rows)
page='''<!doctype html><html lang="zh"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>闪电少女持枪待机复看</title><style>body{max-width:1080px;margin:auto;padding:24px;background:#101b24;color:#e8eeee;font:17px/1.8 system-ui}a{color:#8ed8e8}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}.lens{position:relative;overflow:hidden;height:400px;background:#070b0f}.lens img{position:absolute;width:220%;max-width:none;left:-60%;bottom:-80px}.full{max-width:100%;height:auto}li{overflow-wrap:anywhere}@media(max-width:700px){.pair{grid-template-columns:1fr}}</style><h1>通过：待机也双手持枪</h1><p>原因是旧待机/受击序列使用空手放电姿势，而射击序列已经是双手握枪。现在复用对应武器的第一张准备姿势（没有枪口火焰），呼吸和受击位移动作仍由原骨架驱动。无需新画角色，不覆盖原图。</p><p>八把普通武器全部适配；五套外观共80张待机/开火图，加散弹枪小屏与高屏4张，共84张实拍自动检查零问题。连续开火→停火→受击专项、完整非窗口发布检查和m1通过。枪口三方向坐标、战斗数值、弹道与44个确定性相关函数均未改。</p><h2>散弹枪实际画面局部放大</h2><p>这里只用网页放大查看原图，没有重绘截图。点击可打开完整原生图。</p><div class="pair"><section><h3>待机 / 双手持枪，无枪口火焰</h3><a href="'''+idle+'''"><div class="lens"><img src="'''+idle+'''"></div></a></section><section><h3>开火 / 保留原射击动作</h3><a href="'''+fire+'''"><div class="lens"><img src="'''+fire+'''"></div></a></section></div><h2>完整待机截图</h2><img class="full" src="'''+idle+'''"><h2>全部外观与武器</h2><p>截图为静默离屏模拟，并非手机实测；使用隔离只读存档，没有接触Owner存档。未push、未打TestFlight。</p><ul>'''+links+'</ul></html>'
(D/'00_持枪待机复看.html').write_text(page,encoding='utf-8')
(D/'截图清单.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2))
shutil.copy2(A/'修补说明.md',D/'修补说明.md')
for r in rows:assert hashlib.sha256((D/r['image']).read_bytes()).hexdigest()==r['sha256']
result=dict(screenshots=84,audit_issues=0,transition_cycles=72,release_candidate='passed',m1='passed',desktop=str(D),desktop_hashes_verified=True)
(A/'result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
print(json.dumps(result,ensure_ascii=False))
