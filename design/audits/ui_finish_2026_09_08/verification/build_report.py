#!/usr/bin/env python3
"""Human-readable completion report from immutable capture records, not guesses."""
import collections
import hashlib
import html
import importlib.util
import json
import re
import shutil
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

AUDIT = Path(__file__).resolve().parents[1]
BASE = AUDIT.parent / 'ui_full_review_2026_09_08'
REV = AUDIT / 'final02'
SUPPLEMENT_REV = AUDIT / 'supplement01'
FIRST = AUDIT.parent / 'ui_first_fix_2026_09_08'
spec = importlib.util.spec_from_file_location('first_report', FIRST / 'verification/build_fix_report.py')
first = importlib.util.module_from_spec(spec)
spec.loader.exec_module(first)

FIXES = list(first.FIXES) + [
 ('UI-06','隐私说明与内购功能一致','按 Owner 确认，中英仅删去“没有内购”；不增加隐私承诺。','info_privacy_en_750x1334'),
 ('UI-07','武器展示清晰度，保留原样','按 Owner 最新要求撤回本轮新增的主题染色，不为每把武器重做原型；直接复用已有高清展示素材，只保留清晰度和防裁切修复。既有专属套装与战斗武器皮不动。','loadout_presentation_neon_tempest_vanguard_weapon_autocannon'),
 ('UI-08','武器名称与等级对齐','各名称取实际换行高度，等级徽章对齐最后一行；卡片仍保持中英相同高度，长名称不缩字。','core_1080x1920_en_default_collection_weapons'),
 ('UI-09','配装信息层级及长建议','行动建议在前，重复装备摘要在后并弱化颜色；长建议换行且整组居中，等级后缀与所属名称保持关联。','core_1080x1920_en_neon_tempest_loadout'),
 ('UI-10','已购商店状态重复','将四段拥有说明各放到对应系列之下，顶部只保留已有通用状态；未删任何拥有范围信息。','normal_store_owned_en_1080x1920'),
 ('UI-11','霓虹按钮可见面太薄','用同一原生纹理的有效区域呈现九宫格表面，保留原颜色、尺寸与纹理路由契约；禁用状态跟随按钮。','core_750x1334_en_neon_tempest_pause'),
 ('UI-12','结算小指标挤作一行','现有指标改为逐行分组，词句与数值保持不变。','core_1080x1920_en_default_result'),
 ('UI-13','世界名牌进入波次条','世界名牌同时避让波次条和 Boss 血条区域；只改显示避让矩形。','typography_tall_en_battle_hud'),
 ('UI-14','按钮居中与装饰安全边','图标加文字作为整体居中；章节按钮内边距对称；菜单导航采用更宽原生档；服装卡底部留出纹理内边距；选卡标题按真实行高分配空间。','core_1080x1920_en_gilded_eclipse_pause'),
 ('UI-15','菜单 Logo 光学体量','测量可见主体而不是极淡的导出残像，保留已验收的手工裁切区域。','core_1080x1920_en_gilded_eclipse_menu'),
 ('UI-18','短装备详情过量留白','短详情由实际内容撑高并居中；长详情继续保留滚动和固定操作区。','owned_detail_chips_chip_apocalypse_superconductive_en_scroll0'),
 ('UI-20','英文选卡说明偏小','英文正文由原20px提升至26px，正文宽度由584扩到644；完整标题、三张最长卡、标签间距和操作区都保留。','typography_tall_en_card_offer_1'),
 ('UI-21','技能说明讲开发历史','三项中英只描述当前作用，保留全部现有数值、成长和适用场景；Owner 已批准。','typography_tall_en_card_detail_skill_critical'),
 ('UI-22','人物抠图亮绿残边','默认钢铁先锋和冰霜少女的透明轮廓附近去除绿幕杂色；不改 alpha、动作、握枪点、位置或比例，不覆盖付费战衣材质。','final_combat_default_frost_autocannon_center'),
 ('UI-26','黄金图标带预览小图和残字','两张同名图替换为384×384真透明图，天隼全翼收进画布；旧图逐字节归档，附原生深浅背景检查。','owned_detail_pets_pet_apocalypse_skyfalcon_en_scroll0'),
 ('UI-28','技能图鉴重复标签','顶部摘要复用战斗中现成的作用解释，类型栏不再第三次重复标签；完整等级效果与图鉴规则仍可阅读。','typography_tall_en_skills_detail_skill_homing'),
]
FIXES.sort()
FIXES = [(ident, title, change + (' 宠物冷却也保留真实小数，避免10.5秒误显示为10秒。' if ident == 'UI-27' else ' 已拥有装备卡另补18px内边距，末行状态不贴装饰边。' if ident == 'UI-01' else ''), label) for ident, title, change, label in FIXES]
EXTRA = {
    'UI-08': ['collection_metadata_tags_polar_en_weapons', 'catalog_bottom_weapons_en_1320x2868'],
    'UI-11': ['core_1080x1920_zh_neon_tempest_menu'],
    'UI-14': ['core_1080x1920_en_default_map_chapter', 'outfit_options_vanguard_en_scroll0'],
    'UI-20': ['typography_tall_en_card_offer_5', 'core_750x1334_zh_neon_tempest_card_offer'],
    'UI-22': ['final_combat_default_vanguard_autocannon_center'],
    'UI-26': ['owned_detail_chips_chip_apocalypse_golden_law_en_scroll0'],
    'UI-27': ['owned_detail_pets_pet_apocalypse_skyfalcon_en_scroll0'],
}

def records(directory):
    return {r['label']: r for p in directory.rglob('*.json') if isinstance(r := json.loads(p.read_text()), dict) and 'label' in r and 'capture_exit' in r}

def evidence_path(row):
    return Path(row['_revision']) / row['file']

def accepted_records():
    base, supplement = records(REV / 'screenshots'), records(SUPPLEMENT_REV / 'screenshots')
    seal = json.loads((REV / 'verification/stopped_source_seal.json').read_text())
    continuation = json.loads((AUDIT / 'verification/final_continuation_cases.json').read_text())
    assert seal['source_hashes_unchanged'] and not seal['complete']
    assert set(base) == set(seal['completed_labels']) | set(seal['rejected_labels'])
    base = {label: row for label, row in base.items() if label in seal['completed_labels']}
    assert len(base) == seal['completed_valid'] == 1007
    assert len(supplement) == len(continuation) == 1441 and set(supplement) == {r['label'] for r in continuation}
    base = {label: row for label, row in base.items() if label in seal['reusable_labels']}
    assert len(base) == 793 and not set(base).intersection(supplement)
    assert all(row['route'] not in ['store', 'loadout'] and not (row['route'] == 'collection' and row['payload'].get('mode') == 'pets') for row in base.values())
    old_sources = json.loads((REV / 'verification/source_manifest.json').read_text())
    new_sources = json.loads((SUPPLEMENT_REV / 'verification/source_manifest.json').read_text())
    changed = {p for p in old_sources.keys() | new_sources.keys() if old_sources.get(p) != new_sources.get(p)}
    assert changed == {'meta/store/store.gd', 'meta/collection/collection.gd', 'meta/loadout/loadout.gd', 'ui/weapon_showcase_theme.gdshader', 'ui/weapon_showcase_theme.gdshader.uid', 'tools/check_res_refs.py'}, changed
    assert 'ui/weapon_showcase_theme.gdshader' not in new_sources and 'ui/weapon_showcase_theme.gdshader.uid' not in new_sources
    old_head = json.loads((REV / 'verification/provenance.json').read_text())['head']
    new_head = json.loads((SUPPLEMENT_REV / 'verification/provenance.json').read_text())['head']
    root = AUDIT.parents[2]
    checker_before = subprocess.check_output(['git', 'show', old_head + ':tools/check_res_refs.py'], cwd=root, text=True)
    checker_after = subprocess.check_output(['git', 'show', new_head + ':tools/check_res_refs.py'], cwd=root, text=True)
    assert checker_before.replace("root = Path('/Users/gavin/work/zombie-fire').resolve()", 'root = Path(__file__).resolve().parents[1]') == checker_after, 'Checker change must be root resolution only, not a weakened rule'
    def functions_at(head, path):
        source = subprocess.check_output(['git', 'show', head + ':' + path], cwd=root, text=True)
        return {p.split('(', 1)[0][5:] if p.startswith('func ') else '__preamble__': p.rstrip() for p in re.split(r'(?=^func )', source, flags=re.M)}
    changed_functions = {}
    for path, allowed in [('meta/store/store.gd', {'_owned_item_row'}), ('meta/collection/collection.gd', {'_pet_skill_cooldown_text'}), ('meta/loadout/loadout.gd', {'_refresh', '_loadout_weapon_source_path'})]:
        before, after = functions_at(old_head, path), functions_at(new_head, path)
        delta = {k for k in before.keys() | after.keys() if before.get(k) != after.get(k)}
        assert delta == allowed, (path, delta)
        changed_functions[path] = sorted(delta)
        if path.endswith('collection.gd'):
            calls = [name for name, body in after.items() if '_pet_skill_cooldown_text(' in body and name != '_pet_skill_cooldown_text']
            assert calls == ['_detail_stats_for_item'], calls
            detail = after['_detail_stats_for_item']
            pet_branch = detail.split('\n\t\t"pets":', 1)[1].split('\n\t\t"', 1)[0]
            assert '_pet_skill_cooldown_text(' in pet_branch
    for row in base.values():
        row['_revision'] = REV.name
    for row in supplement.values():
        row['_revision'] = SUPPLEMENT_REV.name
    base.update(supplement)
    proof = dict(base_head=old_head, supplement_head=new_head, base_completed=1007, base_accepted=793, continuation_captures=1441, store_cases=203, pet_cases=92, loadout_cases=200, final_unique_cases=len(base), changed_runtime_files=sorted(changed), changed_functions=changed_functions, unaffected_route_and_mode_source_equivalence=True)
    (AUDIT / 'verification/evidence_composition.json').write_text(json.dumps(proof, ensure_ascii=False, indent=2))
    return base

def main():
    before = records(BASE / 'screenshots')
    after = accepted_records()
    # Keep rejected base diagnostics available in the portable report, while
    # excluding their screenshots from the accepted gallery and desktop copy.
    seal = json.loads((REV / 'verification/stopped_source_seal.json').read_text())
    rejected_dir = AUDIT / 'verification/rejected_base_diagnostics'
    rejected_dir.mkdir(exist_ok=True)
    for label in seal['rejected_labels']:
        for extension in ['.json', '.log']:
            shutil.copy2(REV / 'screenshots/after' / (label + extension), rejected_dir / (label + extension))
    plan = json.loads((REV / 'cases_plan.json').read_text())
    assert len(after) == plan['total'], (len(after), plan['total'])
    planned_labels = {r['label'] for r in plan['cases']}
    assert set(after) == planned_labels, 'Capture records must exactly match the accepted plan'
    covered_labels = {label for r in after.values() for label in [r['label']] + r.get('aliases', [])}
    assert covered_labels == set(before), 'Every original screenshot needs a replay or exact-configuration alias'
    issues = []
    for row in after.values():
        path = AUDIT / evidence_path(row)
        assert row['capture_exit'] == 0 and path.exists(), row['label']
        assert hashlib.sha256(path.read_bytes()).hexdigest() == row['sha256'], row['label']
        with Image.open(path) as shot:
            assert shot.size == tuple(row['payload']['viewport_size']), (row['label'], shot.size)
        assert not re.search(r'ERROR:|SCRIPT ERROR:|Parse Error:', path.with_suffix('.log').read_text()), row['label']
        if row['runtime_issues'] or row['image_issues']:
            issues.append(dict(label=row['label'], runtime=row['runtime_issues'], image=row['image_issues']))
    stats = dict(total=len(after), routes=dict(collections.Counter(r['route'] for r in after.values())),
                 logical_cases=sum(1+len(r.get('aliases',[])) for r in after.values()),
                 base_completed=1007, base_accepted=793, continuation_captures=1441,
                 evidence_heads=dict(collections.Counter(r['git_head'] for r in after.values())),
                 runtime_screens=sum(bool(r['runtime_issues']) for r in after.values()),
                 runtime_messages=sum(len(r['runtime_issues']) for r in after.values()),
                 image_messages=sum(len(r['image_issues']) for r in after.values()), issues=issues,
                 baseline_runtime_screens=sum(bool(before[l]['runtime_issues']) for l in after),
                 baseline_runtime_messages=sum(len(before[l]['runtime_issues']) for l in after))
    (AUDIT / 'verification/final_statistics.json').write_text(json.dumps(stats, ensure_ascii=False, indent=2))
    assert not issues, 'Do not claim all visual checks passed while issues remain'
    (AUDIT / 'verification/accepted_screenshots.json').write_text(json.dumps([dict(label=r['label'], file=str(evidence_path(r)), head=r['git_head'], sha256=r['sha256']) for r in after.values()], ensure_ascii=False, indent=2))
    gate = (AUDIT / 'verification/release_candidate_supplement.log').read_text()
    assert 'Release candidate check OK' in gate and not re.search(r'ERROR:|check failed', gate, re.I)
    (AUDIT / 'before').mkdir(exist_ok=True)
    rows, sections = [], []
    for ident, title, change, label in FIXES:
        assert label in after and label in before, label
        target = AUDIT / 'before' / (label + '.png')
        shutil.copy2(BASE / before[label]['file'], target)
        later = evidence_path(after[label])
        period = '首轮' if ident in {f[0] for f in first.FIXES} else '本轮'
        rows.append(f'<tr><td><a href="#{ident}">{ident}</a></td><td>{html.escape(title)}</td><td>{period}已修，本轮复验</td></tr>')
        figures = ''.join(f'<figure><figcaption>{caption}</figcaption><a href="{path}" target="_blank"><img loading="lazy" src="{path}" alt="{html.escape(title)} · {caption}"></a></figure>' for caption,path in [('原审阅版本',target.relative_to(AUDIT)),('修复后原生截图',later)])
        extras = []
        for extra_label in EXTRA.get(ident, []):
            assert extra_label in after and extra_label in before, extra_label
            old_extra = AUDIT / 'before' / (extra_label + '.png')
            shutil.copy2(BASE / before[extra_label]['file'], old_extra)
            new_extra = evidence_path(after[extra_label])
            extra_pair = ''.join(f'<figure><figcaption>{caption}</figcaption><a href="{path}" target="_blank"><img loading="lazy" src="{path}" alt="{html.escape(extra_label)} · {caption}"></a></figure>' for caption, path in [('原审阅版本', old_extra.relative_to(AUDIT)), ('修复后原生截图', new_extra)])
            extras.append(f'<details><summary>补充对比：{html.escape(extra_label)}</summary><div class="pair">{extra_pair}</div></details>')
        sections.append(f'<section id="{ident}"><h2>{ident} · {html.escape(title)}</h2><p>{html.escape(change)}</p><details><summary>展开前后原图（点击图片可看100%尺寸）</summary><div class="pair">{figures}</div></details>{"".join(extras)}</section>')
    (AUDIT / 'UI收尾对比报告.html').write_text(f'''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>UI 收尾 · 逐项对比</title><style>
body{{margin:0;background:#101820;color:#e5edf0;font:17px/1.7 system-ui,"PingFang SC",sans-serif}}main{{max-width:1120px;margin:auto;padding:32px 22px 100px}}h1{{font-size:34px}}h2{{font-size:23px}}a{{color:#8bd9e0}}header,section,.note{{background:#18242e;border:1px solid #3a505d;border-radius:12px;padding:22px;margin:20px 0}}.status{{color:#98e3b6}}.warn{{color:#edc48a}}table{{width:100%;border-collapse:collapse}}td,th{{text-align:left;padding:9px;border-bottom:1px solid #344751}}.pair{{display:grid;grid-template-columns:1fr 1fr;gap:18px}}figure{{margin:0}}img{{max-width:100%;height:auto;display:block}}summary{{cursor:pointer;color:#8bd9e0}}details[open] summary{{margin-bottom:16px}}@media(max-width:640px){{.pair{{grid-template-columns:1fr}}main{{padding:18px 12px}}h1{{font-size:27px}}section,header{{padding:16px}}td{{font-size:14px;padding:7px}}}}
</style><main><header><p class="status">UI 28 项已修 · 全量截图复验通过</p><h1>这次重点：文字站稳，信息看全</h1><p>首轮12项、本轮16项，另外处理了设置页4条压力样本警告及支付反馈的错误兜底。字体标尺仍为1.5，未改战斗数值。</p><p>{len(after):,}张同配置复拍：运行时提示由{stats['baseline_runtime_screens']}张 / {stats['baseline_runtime_messages']}条降至0；原生像素规则0提示。</p><p class="warn">这是桌面离屏渲染验收，不是已安装手机构建。真实 StoreKit 购买、取消、待批准、失败和恢复仍需 iOS 沙盒复核；代码已保留真实消息，不再统一改写成演示失败。</p><p><a href="全部截图索引.html">全部原图索引</a> · <a href="文案与展示变更.md">中英文案清单</a> · <a href="看图说明.md">一页说明</a></p></header>
<div class="note"><h2>关于“没有居中”</h2><p>按钮与徽章居中；带图标的按钮按“图标＋文字”整体居中；段落保持左对齐。武器卡的短标题不再被最长英文名称撑到下方。没有把所有说明段落强制居中。</p><p>先看 UI-08、UI-11、UI-14，再看英文选卡 UI-20 和黄金图标 UI-26。</p></div><table><thead><tr><th>编号</th><th>处理内容</th><th>状态</th></tr></thead><tbody>{''.join(rows)}</tbody></table>{''.join(sections)}
<section id="DEVICE-01"><h2>DEVICE-01 · 真实支付反馈</h2><p>代码已修：真实交易消息原样显示，不套用演示购买失败兜底；新增断言覆盖取消、待批准和错误消息。真实交易结果、系统语言与恢复购买要在 iOS 沙盒确认，未伪造已通过。</p></section></main></html>'''.replace('</style>', 'summary{overflow-wrap:anywhere}</style>', 1).replace('</header>', '<p>版本说明：793张未受影响的基础图＋1441张最新版本续拍，共2234张。配装、商店和宠物页面全部采用新版。每张图保留真实版本，不冒充同一版本整批。<a href="verification/evidence_composition.json">查看版本证明</a>。</p></header>', 1))
    index = []
    for label, row in sorted(after.items()):
        p = row['payload']
        path = evidence_path(row)
        aliases = row.get('aliases', [])
        alias_note = (' · 同配置别名：' + html.escape(' / '.join(aliases))) if aliases else ''
        index.append(f'<li data-search="{html.escape(" ".join([label] + aliases))}"><a href="{path}" target="_blank">{html.escape(label)}</a> · {html.escape(row["route"])} · {p.get("language", "")} · {p.get("viewport_size", "")}{alias_note}</li>')
    (AUDIT / '全部截图索引.html').write_text('''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>全部原生截图</title><style>body{max-width:1100px;margin:30px auto;padding:0 18px;font:16px/1.7 system-ui;overflow-wrap:anywhere;background:#111a22;color:#e4edf1}a{color:#8bd9e0}input{box-sizing:border-box;width:100%;padding:12px;font:inherit;position:sticky;top:0}li{padding:5px}</style><h1>全部原生截图</h1><p>可按主题、人物、武器、语言、尺寸或场景名筛选。每张都保留配置、哈希及机器检查记录。</p><input id="search" placeholder="例如 neon_tempest / frost / 750x1334 / privacy"><ul>''' + ''.join(index) + '''</ul><script>document.querySelector('input').addEventListener('input',e=>{const q=e.target.value.toLowerCase();document.querySelectorAll('li').forEach(x=>x.hidden=!x.dataset.search.toLowerCase().includes(q))})</script></html>''')
    summary = f'''# 通过：UI 收尾验收（真实支付仍待真机）

本轮补完原审阅剩余16项，加上首轮12项，共28项已修并复验。额外修复设置页4条安全区压力警告和真实支付消息误改写路径。

先打开「UI收尾对比报告.html」：每项一段说明，点开看前后原生图。想查任意主题/人物/武器/尺寸，用「全部截图索引.html」。

重点看：武器名称与等级是否顺眼；霓虹按钮是否厚实、文字居中；暂停按钮图标与文字是否成组；英文长选卡说明是否好读；黄金芯片与天隼是否无小预览、残字、棋盘背景。

复拍 {len(after)} 张，覆盖 {stats['logical_cases']} 个原审阅逻辑用例（完全相同配置的别名共用原图）。五主题、四人物/20造型、12武器/44视觉、四套天启装备、核心17状态×中英×三主尺寸及历史高屏/边界专项。不是所有轴的完全笛卡尔积，也不代表全部动画帧或真实机型实拍。

「同屏对照索引.html」提供同界面的五主题并排预览。战斗截图使用相同配置，但不锁死所有动画帧，背景与特效可能不同；前后对比关注 UI 布局、完整性和可读性，不能把背景像素差当作战斗数值变化。

验收采用793张未受影响的合格基础图，加1441张最新版本续拍，共2234张。基础批拍到1007张后，按 Owner 要求暂停并撤回新增武器主题染色，未冒称该批全部完成。续拍覆盖所有商店203张、收藏宠物92张、配装200张及原批尚未拍完的其它场景。源码与调用范围证明保留的793张未受补修影响。每张图保留实际HEAD和哈希，不把组合证据伪称为同一HEAD整批。版本证明见 verification/evidence_composition.json。

机器检查：运行时0条，原生像素0条；聚合非窗口发布门禁通过，含m1零ERROR、纹理样式、资产、本地化及发布文案。旧资源引用脚本曾硬编码主仓库路径，已纠正并在本隔离树重验，详见 verification/validation_root_note.md。真机购买状态仍需 iOS 沙盒确认，不能计作已通过。

不变：FONT_SCALE=1.5；章节按钮286×80；战斗数值、弹道、瞄准、确定性路径。未push、未合并主仓库、未制作TestFlight，手机现装版本没有自动更新。

所有截图与测试均串行、静音离屏、独立测试存档目录，真实用户存档未读取/写入/删除。原始黄金图标已归档可恢复。

黄金图标：内置图像生成工具出图，经 Owner 同意做透明背景与原生尺寸整理。源图、详细 prompt、旧图归档和深浅底检查见「素材说明.md」。人工目视复核的具体样本见「人工复核.md」；机器全量检查与人工抽样范围分开记录。
'''
    (AUDIT / '看图说明.md').write_text(summary)
    source_art = AUDIT.parents[2] / 'assets/production/source_refs/generated/ui_finish_2026_09_08'
    art_review = AUDIT / 'review/golden_icons'
    art_review.mkdir(parents=True, exist_ok=True)
    for name in ['prompt_log.md', 'processing_manifest.json', 'native_dark_light_review.png']:
        shutil.copy2(source_art / name, art_review / name)
    print(json.dumps(stats, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    main()
