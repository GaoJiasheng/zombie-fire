# -*- coding: utf-8 -*-
"""Validate final evidence and copy native screenshots to the Owner's desktop."""
import hashlib, html, json, re, shutil
from pathlib import Path
from PIL import Image
A = Path(__file__).resolve().parent
ROOT = A.parents[2]
D = Path('/Users/gavin/Desktop/zombiefire_screenshots/20_关卡列表布局优化_2026_09_18')
gate = (A/'release_candidate.log').read_text()
assert 'Release candidate check OK' in gate and 'M1 smoke test passed' in gate
assert not re.search(r'ERROR:|check failed',gate,re.I)
assert 'Level layout regression: 0 failures' in (A/'layout03.log').read_text()
rows = []
for c in json.loads((A/'cases.json').read_text()):
    p = A/'screenshots'/c['group']/(c['label']+'.png')
    r = json.loads(p.with_suffix('.json').read_text())
    assert r['capture_exit']==0 and not r['runtime_issues'] and not r['image_issues'],c['label']
    assert not re.search(r'ERROR:|SCRIPT ERROR:',p.with_suffix('.log').read_text())
    assert hashlib.sha256(p.read_bytes()).hexdigest()==r['sha256']
    with Image.open(p) as im: assert list(im.size)==c['payload']['viewport_size']
    target = D/c['group']/p.name
    target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,target)
    rows.append(dict(label=c['label'],image=str(target.relative_to(D)),sha256=r['sha256']))
assert len(rows)==48
before = ROOT/'design/audits/ui_finish_2026_09_08/final02/screenshots/after/core_1320x2868_zh_default_map_chapter.png'
shutil.copy2(before,D/'历史布局参考_中文.png')
featured = 'after/core_1320x2868_zh_default_map_chapter1.png'
shutil.copy2(D/featured,D/'最终界面_中文_1320x2868.png')
links = ''.join('<li><a href="'+r['image']+'">'+html.escape(r['label'])+'</a></li>' for r in rows)
page = '''<!doctype html><html lang="zh"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>关卡列表布局优化</title><style>body{max-width:1080px;margin:auto;padding:24px;background:#111c24;color:#e8eeee;font:17px/1.8 system-ui}a{color:#8fdaeb}img{width:100%;height:auto}.pair{display:grid;grid-template-columns:1fr 1fr;gap:16px}li{overflow-wrap:anywhere}@media(max-width:650px){.pair{grid-template-columns:1fr}}</style><h1>通过：关卡标题、信息同行与固定返回</h1><p>关卡标题统一放大到47画布像素，不再缩字。推荐战力与弱点在同一行，徽章宽度随文字收紧。左上角新增返回箭头，列表滚动时仍固定可用；原有返回按钮保留。</p><h2>复看结论</h2><p>中文保留紧凑左右结构。英文原文和字号不变，信息放不下时把模式按钮放到下一行，而不是裁字。首页和第十战区、已通关和未通关状态均复核。标题、徽章、普通/挑战按钮未发现新增相互覆盖。</p><p>48张原生截图全部零审计问题；99关×3尺寸×中英专项通过；完整非窗口发布门禁及m1通过。截图为离屏模拟，不是真机实测。本次未改数值、英文语义，未push或打包。</p><h2>中文前后对照</h2><p>左图为此前归档布局（不同测试存档），仅比较排版，不比较资源余额、进度或星数。右图为本轮最终截图。</p><div class="pair"><div><h3>历史布局</h3><img src="历史布局参考_中文.png"></div><div><h3>最终布局</h3><img src="最终界面_中文_1320x2868.png"></div></div><h2>全部尺寸与语言</h2><ul>'''+links+'</ul></html>'
(D/'00_最终界面与复看.html').write_text(page,encoding='utf-8')
(D/'截图清单.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2))
shutil.copy2(A/'复看说明.md',D/'复看说明.md')
for r in rows: assert hashlib.sha256((D/r['image']).read_bytes()).hexdigest()==r['sha256']
result=dict(screenshots=48,audit_issues=0,stage_language_size_checks=594,release_candidate='passed',m1='passed',desktop=str(D),desktop_hashes_verified=True)
(A/'result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
print(json.dumps(result,ensure_ascii=False))
