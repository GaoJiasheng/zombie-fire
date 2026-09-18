"""Publish native before/after menu captures without changing image pixels."""
import hashlib, html, json, re, shutil
from pathlib import Path
from PIL import Image

A=Path(__file__).resolve().parent
ROOT=A.parents[2]
D=Path('/Users/gavin/Desktop/zombiefire_screenshots/24_主菜单标题留白_2026_09_18')
gate=(A/'release_candidate.log').read_text()
assert 'Release candidate check OK' in gate and 'M1 smoke test passed' in gate
assert not re.search(r'ERROR:|check failed',gate,re.I)
rows=[]
for phase in ('before','after'):
    cases=json.loads((A/phase/'cases.json').read_text());assert len(cases)==30
    for c in cases:
        p=A/phase/'screenshots'/c['group']/(c['label']+'.png')
        r=json.loads(p.with_suffix('.json').read_text())
        assert r['capture_exit']==0 and not r['runtime_issues'] and not r['image_issues'],p
        assert not re.search(r'ERROR:',p.with_suffix('.log').read_text()),p
        assert hashlib.sha256(p.read_bytes()).hexdigest()==r['sha256'],p
        with Image.open(p) as im:assert list(im.size)==c['payload']['viewport_size'],p
        target=D/phase/p.name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,target)
        rows.append(dict(phase=phase,label=c['label'],image=str(target.relative_to(D)),sha256=r['sha256']))
before=json.loads((A/'before/verification/source.json').read_text())
after=json.loads((A/'after/verification/source.json').read_text())
for path,sha in after.items():assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==sha,path
changed=[p for p in before if before[p]!=after[p]]
assert len(changed)==7 and 'data/themes.json' in changed,changed
assert not any('infernal_dominion' in p or 'menu.gd' in p for p in changed)
themes=[('neon_tempest','霓虹'),('polar_aurora','极光'),('gilded_eclipse','黄金'),('default','默认（未改）'),('infernal_dominion','炼狱（未改）')]
sections=[]
for size in ('750x1334','1080x1920','1320x2868'):
    for lang,name in (('zh','中文'),('en','英文')):
        cells=[]
        for theme,cn in themes:
            file=f'menu_{theme}_{lang}_{size}.png'
            cells.append(f'<section><h3>{cn}</h3><div class="pair"><figure><figcaption>修改前</figcaption><a href="before/{file}"><img loading="lazy" src="before/{file}"></a></figure><figure><figcaption>修改后</figcaption><a href="after/{file}"><img loading="lazy" src="after/{file}"></a></figure></div></section>')
        sections.append(f'<h2>{name} · {size}</h2>'+''.join(cells))
page='''<!doctype html><html lang="zh"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>主菜单标题留白 · 中英前后对照</title><style>body{max-width:1100px;margin:28px auto;padding:0 20px;background:#101820;color:#eee;font:17px/1.7 system-ui}a{color:#98dce9}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:0}img{width:100%;max-width:430px}section{padding-bottom:28px;border-bottom:1px solid #36505c}figcaption{color:#abc}h2{margin-top:60px}</style><h1>主菜单标题留白 · 中英前后对照</h1><p>本轮只处理霓虹、极光、黄金三套标题素材内的文字压边：扩大暗色牌面和文字与装饰之间的空间，中英文各一张。菜单布局、全局字号和按钮完全未动；默认/炼狱作为未改对照。</p><p>先看下面750×1334小屏，再看标准屏与高屏。左为修改前，右为最终版；点击可打开原生分辨率原图。标题是烘焙文字的图像编辑，不是把全局字号调小；保留原标题内容与材质方向，但不是逐像素保留旧字形。</p><p>全部60张为本轮同一路由的静默离屏截图；修改前30张、修改后30张，五主题×中英×三尺寸。自动审计均为空，另已人工复看标题四周间距、中央装饰、完整字形。完整非窗口聚合门禁及m1通过，不代表全游戏重跑截图。</p><p><a href="看图说明.md">中文看图说明</a> · <a href="截图清单.json">完整清单与校验值</a></p>'''+''.join(sections)+'</html>'
overview=[]
for lang,cn in (('zh','中文最终版'),('en','英文最终版')):
    cards=[]
    for theme,name in themes[:3]:
        src=f'after/menu_{theme}_{lang}_750x1334.png'
        cards.append(f'<figure><figcaption>{name}</figcaption><a href="{src}"><img src="{src}"></a></figure>')
    overview.append(f'<h2>{cn} · 三主题速览</h2><div style="display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px">'+''.join(cards)+'</div>')
page=page.replace('<p><a href="看图说明.md">',''.join(overview)+'<p><a href="看图说明.md">')
(D/'00_主菜单标题前后对照.html').write_text(page,encoding='utf-8')
(D/'截图清单.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
shutil.copy2(A/'看图说明.md',D/'看图说明.md')
for r in rows:assert hashlib.sha256((D/r['image']).read_bytes()).hexdigest()==r['sha256']
result=dict(before=30,after=30,issues=0,release_candidate='passed',m1='passed',changed_runtime_sources=changed,desktop=str(D),desktop_hashes_verified=True)
(A/'result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
for name in ('result.json','asset_verification.json','release_candidate.log'):
    shutil.copy2(A/name,D/name)
print(json.dumps(result,ensure_ascii=False))
