# -*- coding: utf-8 -*-
"""Verify source-sealed chapter screenshots and publish unchanged native PNGs."""
import hashlib,html,json,re,shutil
from pathlib import Path
from PIL import Image
A=Path(__file__).resolve().parent
ROOT=A.parents[2]
D=Path('/Users/gavin/Desktop/zombiefire_screenshots/25_战区布局复查_2026_09_18')
gate=(A/'release_candidate.log').read_text()
assert 'Release candidate check OK' in gate and 'M1 smoke test passed' in gate
assert not re.search(r'ERROR:|check failed',gate,re.I)
assert 'Chapter layout regression: 2970 stages, 0 failures' in (A/'layout02.log').read_text()
rows=[]
for phase in ('before','after'):
    cases=json.loads((A/phase/'cases.json').read_text());assert len(cases)==48
    for c in cases:
        p=A/phase/'screenshots'/c['group']/(c['label']+'.png')
        r=json.loads(p.with_suffix('.json').read_text())
        assert r['capture_exit']==0 and not r['runtime_issues'] and not r['image_issues'],p
        assert not re.search(r'ERROR:|SCRIPT ERROR:',p.with_suffix('.log').read_text()),p
        assert hashlib.sha256(p.read_bytes()).hexdigest()==r['sha256'],p
        with Image.open(p) as im:assert list(im.size)==c['payload']['viewport_size'],p
        target=D/phase/(c['label']+'.png');target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,target)
        rows.append(dict(phase=phase,label=c['label'],image=str(target.relative_to(D)),sha256=r['sha256']))
for path,sha in json.loads((A/'after/verification/source.json').read_text()).items():
    assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==sha,path
themes=[('gilded_eclipse','黄金（Owner指出的主题）'),('default','默认'),('neon_tempest','霓虹'),('infernal_dominion','炼狱'),('polar_aurora','极光')]
sections=[]
for size in ('1080x1920','750x1334','1320x2868'):
    for lang,cn in (('zh','中文'),('en','英文')):
        file=f'core_{size}_{lang}_gilded_eclipse_map_chapter1.png'
        sections.append(f'<h2>黄金 · {cn} · {size}</h2><div class="pair"><figure><figcaption>本轮修前（已含此前优化）</figcaption><a href="before/{file}"><img loading="lazy" src="before/{file}"></a></figure><figure><figcaption>本轮最终版</figcaption><a href="after/{file}"><img loading="lazy" src="after/{file}"></a></figure></div>')
overview=[]
for theme,cn in themes:
    file=f'after/core_1080x1920_zh_{theme}_map_chapter1.png'
    overview.append(f'<figure><figcaption>{cn}</figcaption><a href="{file}"><img loading="lazy" src="{file}"></a></figure>')
links=''.join(f'<li><a href="{r["image"]}">{html.escape(r["label"])}</a></li>' for r in rows if r['phase']=='after')
page='''<!doctype html><html lang="zh"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>第一战区 · 最新排布复查</title><style>body{max-width:1100px;margin:auto;padding:24px;background:#111d25;color:#e7eded;font:17px/1.75 system-ui}a{color:#95e0ed}.pair{display:grid;grid-template-columns:1fr 1fr;gap:18px}figure{margin:0}img{width:100%}.overview{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:10px}figcaption{color:#aebbc2}li{overflow-wrap:anywhere}</style><h1>第一战区 · 最新排布复查</h1><p>你看到的是9月14日旧全量包。隔离分支此前已加大关卡标题、合并推荐/弱点、加左上返回；但新版仍有介绍卡留白和英文按钮下沉，所以本轮继续修补，并用同一测试存档重拍前后对照。</p><p>介绍/目标改为整宽连贯阅读，去掉卡片内重复的战区标题；进度和返回同排。第一战区介绍卡从400压到310画布像素。英文保留原文字号：关卡名与模式按钮并排，长推荐/弱点占完整底行。普通/挑战触控尺寸、286×80返回按钮和既有间隔门槛不变。</p><p>修前48张＋修后48张：五主题×三尺寸×中英第一战区30张，以及默认主题第十战区/未通关/总览18张。截图审计为空、原始日志零ERROR；99关×五主题×三尺寸×中英共2970项布局专项通过，完整60项非窗口门禁及m1通过。均为离屏原生截图，不是真机拍照。</p><p>左图是本轮开始时的最新代码，不是9月14日旧图。请点击图片看原图，尤其检查英文SE和黄金边框内侧。页底露出下一张卡的一部分是滚动视口边界，可继续下滑，并非卡片内裁字。</p><p><a href="复看说明.md">中文复看说明</a> · <a href="截图清单.json">96张原图与哈希清单</a></p>'''+''.join(sections)+'<h2>五主题最新中文标准屏</h2><div class="overview">'+''.join(overview)+'</div><h2>全部48张最终截图</h2><ul>'+links+'</ul></html>'
(D/'00_第一战区前后对照.html').write_text(page,encoding='utf-8')
(D/'截图清单.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
for name in ('复看说明.md','layout02.log','release_candidate.log'):
    shutil.copy2(A/name,D/name)
for r in rows:assert hashlib.sha256((D/r['image']).read_bytes()).hexdigest()==r['sha256']
result=dict(before=48,after=48,issues=0,layout_checks=2970,release_checks=60,m1='passed',desktop=str(D),desktop_hashes_verified=True)
(A/'result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
shutil.copy2(A/'result.json',D/'result.json')
print(json.dumps(result,ensure_ascii=False))
