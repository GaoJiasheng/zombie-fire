# -*- coding: utf-8 -*-
"""Package validated map screenshots for human review, never failed attempts."""
import hashlib, html, json, re, shutil
from pathlib import Path
from PIL import Image
AUDIT=Path(__file__).resolve().parent
DEST=Path('/Users/gavin/Desktop/zombiefire_screenshots/18_战区首领徽章_2026_09_17')
OUT=AUDIT/'delivery'
cases=json.loads((AUDIT/'cases.json').read_text())
assert len(cases)==42
gate=(AUDIT/'release_candidate.log').read_text()
assert 'Release candidate check OK' in gate and not re.search(r'ERROR:|check failed',gate,re.I)
assert 'Boss badge regression: 0 failures' in (AUDIT/'geometry06_interaction.log').read_text()
manifest=[]
for case in cases:
    source=AUDIT/'screenshots'/case['group']/(case['label']+'.png')
    record=json.loads(source.with_suffix('.json').read_text())
    assert record['capture_exit']==0 and not record['runtime_issues'] and not record['image_issues'],record['label']
    assert not re.search(r'ERROR:|SCRIPT ERROR:|Parse Error:',source.with_suffix('.log').read_text()),source
    assert hashlib.sha256(source.read_bytes()).hexdigest()==record['sha256']
    with Image.open(source) as im: assert list(im.size)==case['payload']['viewport_size']
    after=Path('after')/source.name;(OUT/after.parent).mkdir(parents=True,exist_ok=True)
    shutil.copy2(source,OUT/after)
    before=None
    if 'before' in case:
        before=Path('before')/source.name;(OUT/before.parent).mkdir(exist_ok=True)
        shutil.copy2(case['before'],OUT/before)
    manifest.append(dict(label=case['label'],before=str(before) if before else None,after=str(after),sha256=record['sha256'],payload=case['payload']))
sections=[]
for r in manifest:
    if '_default_' not in r['label']: continue
    if r['before']:
        figures=''.join('<figure><figcaption>'+caption+'</figcaption><a href="'+r[key]+'"><img loading="lazy" src="'+r[key]+'"></a></figure>' for key,caption in [('before','调整前'),('after','调整后')])
        sections.append('<section><h2>'+html.escape(r['label'])+'</h2><div class="pair">'+figures+'</div></section>')
    elif '750x1334' in r['label']:
        sections.append('<section><h2>长按说明 · '+html.escape(r['label'])+'</h2><img class="hint" loading="lazy" src="'+r['after']+'"></section>')
links=''.join('<li>'+html.escape(r['label'])+' · '+('<a href="'+r['before']+'">调整前</a> · ' if r['before'] else '')+'<a href="'+r['after']+'">最终原图</a></li>' for r in manifest)
page='''<!doctype html><html lang="zh"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>战区首领徽章 · 人工复看</title><style>body{background:#101b22;color:#e8eded;font:17px/1.7 system-ui;max-width:1200px;margin:auto;padding:24px}a{color:#89d7e8}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:0}img{max-width:100%;height:auto}.hint{max-height:1050px}section{border-top:1px solid #48616d;padding:20px 0}h2,li{overflow-wrap:anywhere}h2{font-size:19px}@media(max-width:650px){.pair{grid-template-columns:1fr}}</style><h1>通过：战区徽章更宽，长按可解释</h1><p>“回顾战区／继续推进”向右调整；两枚徽章扩大为112×80，数字字号不变、图标保持比例，主按钮仍为286×80。借用缩略图未用的右侧空位，保留卡片右侧安全距离。</p><p>按住徽章半秒：显示小首领／大首领及具体关卡，说明数字是关卡编号。松手后短暂保留；短按不误开，拖动即取消，未解锁战区也可查看。</p><p>30张地图（五主题×三尺寸×中英）＋12张说明实拍；42张均无自动审计问题。三尺寸双语触摸、布局回归通过；完整非视觉发布门禁通过。截图为离屏原生尺寸模拟，尚非手机实测。</p>'''+''.join(sections)+'<h2>全部42张最终图与30张历史对照</h2><ul>'+links+'</ul></html>'
(OUT/'00_前后对比.html').write_text(page,encoding='utf-8')
(OUT/'交付清单.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
shutil.copy2(AUDIT/'看图说明.md',OUT/'看图说明.md')
shutil.copy2(AUDIT/'five_themes.jpg',OUT/'五主题对照.jpg')
for name in ['geometry06_interaction.log','release_candidate.log']:
    shutil.copy2(AUDIT/name,OUT/name)
(OUT/'verification').mkdir(exist_ok=True)
for name in ['source.json','runtime.patch']:
    shutil.copy2(AUDIT/'verification'/name,OUT/'verification'/name)
result=dict(captures=42,maps=30,hints=12,runtime_issues=0,image_issues=0,desktop=str(DEST),copied_hashes_verified=True)
(OUT/'result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
if DEST.exists(): assert (DEST/'交付清单.json').exists(),'Refuse unrelated overwrite'
shutil.copytree(OUT,DEST,dirs_exist_ok=True)
for p in OUT.rglob('*'):
    if p.is_file(): assert hashlib.sha256(p.read_bytes()).digest()==hashlib.sha256((DEST/p.relative_to(OUT)).read_bytes()).digest()
(AUDIT/'result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(DEST/'00_前后对比.html')
