# -*- coding: utf-8 -*-
"""Validate and deliver only the final chapter-map screenshots."""
import hashlib, html, json, re, shutil
from pathlib import Path
from PIL import Image
A=Path(__file__).resolve().parent
D=Path('/Users/gavin/Desktop/zombiefire_screenshots/19_战区环境图优化_2026_09_17')
cases=json.loads((A/'cases.json').read_text())
gate=(A/'release_candidate.log').read_text()
assert 'Release candidate check OK' in gate and 'M1 smoke test passed' in gate and not re.search(r'ERROR:|check failed',gate,re.I)
rows=[]
for case in cases:
    path=A/'screenshots'/case['group']/(case['label']+'.png')
    record=json.loads(path.with_suffix('.json').read_text())
    assert record['capture_exit']==0 and not record['runtime_issues'] and not record['image_issues'],case['label']
    assert not re.search(r'ERROR:|SCRIPT ERROR:',path.with_suffix('.log').read_text())
    assert hashlib.sha256(path.read_bytes()).hexdigest()==record['sha256']
    with Image.open(path) as im: assert list(im.size)==case['payload']['viewport_size']
    out=D/case['group']/path.name;out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,out)
    before=None
    if case.get('before'):
        before=D/'before'/path.name;before.parent.mkdir(exist_ok=True);shutil.copy2(case['before'],before)
    rows.append(dict(label=case['label'],image=str(out.relative_to(D)),before=str(before.relative_to(D)) if before else None,sha256=record['sha256']))
assert len(rows)==36
featured='featured/core_1320x2868_zh_default_map_early_campaign.png'
shutil.copy2(D/featured,D/'最终界面_中文_1320x2868.png')
links=''.join('<li>'+html.escape(r['label'])+' · <a href="'+r['image']+'">最终原图</a>'+(' · <a href="'+r['before']+'">调整前</a>' if r['before'] else '')+'</li>' for r in rows)
page='''<!doctype html><html lang="zh"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>战区地图 · 环境图优化</title><style>body{max-width:1000px;margin:auto;padding:24px;background:#111c24;color:#e8eeee;font:17px/1.8 system-ui}a{color:#8fdaeb}img{max-width:100%;height:auto}li{overflow-wrap:anywhere}</style><h1>通过：去掉重复说明，把空间还给环境图</h1><p>移除每个战区左下重复的“击破战区首领，推进防线”。环境图由292×132加高至292×174，保持图片比例，以居中裁切填满，不拉伸。关卡范围、状态、各战区独有说明和进度保留。</p><h2>复看结论</h2><p>信息层级更清楚：环境图 → 关卡范围 → 状态；不再每张卡重复同一行动口号。图像更醒目，卡片没有变高，不减少可见战区数量。首领徽章、长按说明与286×80按钮保留。中英、小屏复看未见新增溢出或压边。</p><p>五主题×三尺寸×中英30张回归图，另加6张前段战役构图；36张自动审计零问题，完整非窗口门禁与m1通过。截图是静音离屏原生尺寸模拟，尚非手机实测。</p><h2>最终界面</h2><a href="最终界面_中文_1320x2868.png"><img alt="最终中文战区地图" src="最终界面_中文_1320x2868.png"></a><h2>其余尺寸、语言与前后对照</h2><ul>'''+links+'</ul></html>'
(D/'00_最终界面与复看.html').write_text(page,encoding='utf-8')
(D/'截图清单.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
shutil.copy2(A/'复看说明.md',D/'复看说明.md')
for r in rows: assert hashlib.sha256((D/r['image']).read_bytes()).hexdigest()==r['sha256']
result=dict(screenshots=36,audit_issues=0,release_candidate='passed',m1='passed',desktop=str(D),desktop_hashes_verified=True)
(A/'result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(result,ensure_ascii=False))
