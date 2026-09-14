# -*- coding: utf-8 -*-
"""Verify the affected routes and deliver a compact before/after review."""
import hashlib, html, json, re, shutil, subprocess
from pathlib import Path
from PIL import Image
AUDIT=Path(__file__).resolve().parent
ROOT=AUDIT.parents[2]
DEST=Path('/Users/gavin/Desktop/zombiefire_screenshots/17_SE选卡名牌补修_2026_09_14')
records=[]
plan=json.loads((AUDIT/'after/cases.json').read_text())
for case in plan:
    src=AUDIT/'after/screenshots/after'/f'{case["label"]}.png'
    row=json.loads(src.with_suffix('.json').read_text())
    assert row['capture_exit']==0 and not row['runtime_issues'] and not row['image_issues'],row['label']
    assert not re.search(r'ERROR:|SCRIPT ERROR:|Parse Error:',src.with_suffix('.log').read_text()),src
    assert hashlib.sha256(src.read_bytes()).hexdigest()==row['sha256']
    with Image.open(src) as im:assert list(im.size)==case['payload']['viewport_size']
    records.append(row)
assert len(records)==78
gate=(AUDIT/'release_candidate.log').read_text()
assert 'Release candidate check OK' in gate and not re.search(r'ERROR:|check failed',gate,re.I)
assert 'UI13 modal regression: 0 failures' in (AUDIT/'after_geometry03.log').read_text()
if DEST.exists():
    assert (DEST/'交付清单.json').exists(),'Do not overwrite another delivery'
DEST.mkdir(parents=True,exist_ok=True)
rows=[]
for case,row in zip(plan,records):
    pair=[]
    for phase,src in [('before',Path(case['before'])),('after',AUDIT/row['file'])]:
        if phase=='after':src=AUDIT/'after'/row['file']
        rel=Path(phase)/f'{case["label"]}.png';(DEST/phase).mkdir(exist_ok=True)
        shutil.copy2(src,DEST/rel)
        assert hashlib.sha256(src.read_bytes()).digest()==hashlib.sha256((DEST/rel).read_bytes()).digest()

        (AUDIT/phase).mkdir(exist_ok=True)
        shutil.copy2(src,AUDIT/rel)
        pair.append(str(rel))
    rows.append(dict(label=case['label'],before=pair[0],after=pair[1],sha256=row['sha256'],payload=row['payload']))
featured=[r for r in rows if r['label'] in ['core_750x1334_en_default_card_offer','core_750x1334_zh_default_card_offer','core_1080x1920_en_default_card_offer','core_1320x2868_en_default_card_offer']]
featured.sort(key=lambda r:('750x1334' not in r['label'],r['label']))
sections=[]
for r in featured:
    figures=''.join(f'<figure><figcaption>{caption}</figcaption><a href="{r[k]}" target="_blank"><img src="{r[k]}" alt="{caption}" loading="lazy"></a></figure>' for k,caption in [('before','修复前'),('after','修复后')])
    sections.append(f'<section><h2>{html.escape(r["label"])}</h2><div class="pair">{figures}</div></section>')
links=''.join(f'<li>{html.escape(r["label"])} · <a href="{r["before"]}">修复前</a> · <a href="{r["after"]}">修复后</a></li>' for r in sorted(rows,key=lambda r:r['label']))
page='''<!doctype html><html lang="zh"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>SE选卡补修</title><style>body{max-width:1200px;margin:auto;padding:24px;background:#111b24;color:#e7f1f3;font:17px/1.7 system-ui}a{color:#8edce5}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:0}img{max-width:100%}section{padding:20px 0;border-top:1px solid #49606e}h2,li{overflow-wrap:anywhere}h2{font-size:19px}@media(max-width:650px){.pair{grid-template-columns:1fr}}</style><h1>通过：SE选卡名牌与顶部留白补修</h1><p>选卡打开时整层隐藏世界名牌，重抽及详情期间保持隐藏；关闭恢复原有可见性。波次条下方至少48个画布像素，SE约33个实际像素。高度吃紧时复用两侧空白、按卡片真实内容分配高度；保留所有字号、说明及卡内间隔。</p><p>78张选卡/详情复拍全部无检查提示；完整发布门禁通过，m1零ERROR，三尺寸中英专项零失败。没有改战斗数值、散弹枪或确定性路径。旧大包保留为审阅版本，本目录是最新补修图。</p>'''+''.join(sections)+'<h2>全部78项前后原图</h2><ul>'+links+'</ul></html>'
(DEST/'00_前后对比.html').write_text(page)
(AUDIT/'报告.html').write_text(page)
result=dict(total=78,runtime_issues=0,image_issues=0,all_copy_hashes_verified=True,head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),battle_sha256=hashlib.sha256((ROOT/'gameplay/battle/battle.gd').read_bytes()).hexdigest(),destination=str(DEST),records=rows)
(DEST/'交付清单.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
(AUDIT/'result.json').write_text(json.dumps({k:v for k,v in result.items() if k!='records'},ensure_ascii=False,indent=2))
print(json.dumps({k:v for k,v in result.items() if k!='records'},ensure_ascii=False,indent=2))
