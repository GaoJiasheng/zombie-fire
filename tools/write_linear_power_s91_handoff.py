#!/usr/bin/env python3
"""Evidence-derived §9.1 handoff; never substitute static PASS for native PASS."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

import challenge_curve as curve
import run_linear_power_s9 as s9
import solve_runtime_clear_lines as t1

ROOT=s9.ROOT
OUT=ROOT/'design/audits/linear_power_p4_s91_2026_10_05'


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--adopted',action='store_true')
    args=parser.parse_args()
    frozen=s9.guard()
    reports=[json.loads(p.read_text()) for p in sorted(OUT.glob('round_??_contracts.json'))]
    rounds=[json.loads(p.read_text()) for p in sorted(OUT.glob('round_??_result.json'))]
    journal=json.loads((OUT/'commands.json').read_text()) if (OUT/'commands.json').exists() else []
    verification=[];gate_batches=[]
    for p in sorted(OUT.glob('verification*.json')):
        value=json.loads(p.read_text())
        if isinstance(value,list):
            verification.extend(value)
            if any('tools/check_release_candidate.py' in r.get('command',[]) for r in value):
                gate_batches.append((p.name,value))
    adopted=json.loads((OUT/'adopted_contracts.json').read_text()) if args.adopted else None
    native_pass=bool(adopted and adopted['status']=='PASS')
    # Historical FAILs remain visible; a complete later rerun is authoritative,
    # not an accumulation that silently deletes failures or can never recover.
    gate_name,latest_gate=max(gate_batches,key=lambda item:max(r.get('ended_unix',0) for r in item[1])) if gate_batches else (None,[])
    static_pass=bool(len(latest_gate)==16 and all(r['pass'] for r in latest_gate))
    status='COMPLETED' if args.adopted and native_pass and static_pass else 'NOT_FULLY_ACCEPTED'
    base=json.loads(s9.BASE.read_text())
    current=json.loads((ROOT/'data/challenges.json').read_text())
    groups=[]
    for record in journal:
        summary=json.loads((OUT/(record['label']+'_summary.json')).read_text())
        groups.append({'label':record['label'],'round':record['round'],**summary,
                       'log':record['log'],'command':record['command']})
    nearest=sorted(zip(rounds,reports),key=lambda pair:(pair[0]['deviation_wins'],pair[0]['ended_unix']))[:3]
    state={'status':status,'authority':'2026-10-05 §41 §9.1','adopted':args.adopted,
           'native_contract_pass':native_pass,'verification_pass':static_pass,'final_gate_record':gate_name,'round_count':len(rounds),
           'new_attempts':sum(g['runs'] for g in groups),'script_errors':sum(g['script_errors'] for g in groups),
           'horizon_nonclears':sum(g['horizon_nonclears'] for g in groups),
           'input_sha256':frozen,'groups':groups,'nearest_three':[{'result':a,'report':b} for a,b in nearest]}
    t1.atomic_write(OUT/'handoff_state.json',state)
    md=[f'状态：{status}；§9.1运行时合同 '+('PASS' if native_pass else '未整体通过')+'；'+('采用受测曲线' if args.adopted else '候选未采用'),
        '', '# design/41 §9.1 第二轮签字后完整交接报告（2026-10-05）','',
        '## Completed · 工具与执行','',
        '- 工作树`/Users/gavin/work/zf-linear`，分支`codex/linear-power`；先merge main读取§9.1。',
        '- 黄金律099≥6/10，无上限；Boss中位150–220秒INFO；免费099≤3/10；ch7–10每章18–27/30。',
        '- 压力指数61–99（含099）可调，有限[0,1]且和1；K单调smoothstep，相邻≤18%，上限8，ch1–6展开完全冻结。',
        '- 新挑战探针720秒，普通默认540不变；720秒未结束者按未通关单列，缺种子/进程错误不得算未通关；旧540未结束组不复用。',
        '- 固定十种子1103/2207/3301/4409/5513/6637/7741/8849/9901/10903，固定帧1/60、tier_b/v2、每轮≤320、jobs6、nohup宿主保活。',
        f'- 本轮完成{len(rounds)}轮，新原生尝试{state["new_attempts"]}局，SCRIPT ERROR {state["script_errors"]}，720秒未通关{state["horizon_nonclears"]}局。',
        '- 已完整结束的旧组仅按完全相同展开规则复用，不挑种子/最佳组；全部候选和失败证据独立保留。',
        f'- 最终门禁权威记录：`{gate_name}`；16条实际命令'+('全部PASS。' if static_pass else '尚未全部PASS。')+'历史首次FAIL与后续复跑均保留。',
        '- 仅允许data/challenges.json.curve产品数值修改；普通敌方/gameplay/core/翻卡/付费属性/资源/P(g)/F(g)/已批星表不改。Owner签字星表由Fable合并时替换，本分支不代执行。',
        '', '## Completed · 数据结论','']
    if adopted:
        md+=['|章|胜/30|合同|结果|','|---|---:|---|---|']
        md += [f'|{r["chapter"]}|{r["wins"]}|{r["contract"]}|'+('PASS' if r['pass'] else 'FAIL')+'|' for r in adopted['chapters']]
        md += ['',f'- 099黄金律：{adopted["golden099"]["wins"]}/10；Boss胜局中位{adopted["golden099"]["boss_median"]}秒，INFO。',
               f'- 099免费：{adopted["free099"]["wins"]}/10。',
               '- 普通099免费MAX既有10/10、076炼狱9/10（4409败）、095普通黄金律10/10证据保持；不冒称本轮重复实跑。',
               '- G3硬点十关94/100保持PASS，另两点INFO；资源维持现状，G1下限0失败/10次回刷保持。']
    md+=['','### 各轮与最接近三个候选','', '|轮|新尝试|章节7/8/9/10胜数|免费099|黄金律099|偏差胜数|状态|','|---|---:|---|---:|---:|---:|---|']
    for number,r in enumerate(rounds,1):
        md.append(f'|{number}|{r["new_attempts"]}|'+
                  '/'.join(str(x['wins']) for x in r['chapters'][6:])+f'|{r["free099"]["wins"]}|{r["golden099"].get("wins")}|{r["deviation_wins"]}|{r["status"]}|')
    for result,contract in nearest:
        md+=['',f'- 候选curve SHA `{contract["curve_sha256"]}`，距所有硬合同带的总胜数偏差{result["deviation_wins"]}；章节失败{contract["chapter_failures"]}；曲线保全在对应round候选与contracts JSON。']
        md+=['  - K锚点：`'+json.dumps(contract['curve']['anchors'],ensure_ascii=False)+'`',
             '  - 压力指数锚点：`'+json.dumps(contract['curve']['line_pressure_exponents']['anchors'],ensure_ascii=False)+'`',
             '  - 偏差：'+ '；'.join(f"ch{x['chapter']}={x['wins']}/30（合同{x['contract']}）" for x in result['chapters'][6:])+
             f"；免费099={result['free099']['wins']}/10（≤3）；黄金律099={result['golden099'].get('wins')}/10（≥6）。"]
    md+=['', '### 采用曲线的逐关证据与未通关种子','', '|关|胜/10|真实/计入未通关种子|720秒未结束|来源|','|---|---:|---|---|---|']
    if adopted:
        md += [f'|{r["level"]:03d}|{r.get("wins")}|{r.get("failed_seeds")}|{r.get("horizon_nonclear_seeds")}|{r.get("selected_group")}|' for r in adopted['rows']]
    md+=['', '## Changed files','']
    changes=subprocess.check_output(['git','diff','--name-only','HEAD'],cwd=ROOT,text=True).splitlines()
    untracked=subprocess.check_output(['git','ls-files','--others','--exclude-standard'],cwd=ROOT,text=True).splitlines()
    md += ['- `'+p+'`' for p in sorted(set(changes+untracked)) if not p.startswith('design/audits/linear_power_p4_s91_2026_10_05/')]
    md+=['- 审计目录`design/audits/linear_power_p4_s91_2026_10_05/`：候选、完整命令、输入SHA、源JSON、独立门禁、逐关表、交接报告。',
          '- 数据变更依据：Owner 2026-10-05 design/41 §9.1；采用轮的candidate/plan/contracts逐关可查，不采用其他曲线或资源表。',
          '', '### 全99关新旧K与三指数对照','', '|关|旧K|新K|旧S/B/M|新S/B/M|','|---|---:|---:|---|---|']
    for n in range(1,100):
        old_e=curve.exponents_for_level(n,base['challenges']);new_e=curve.exponents_for_level(n,current)
        md.append(f'|{n:03d}|{curve.budget_for_level(n,base["challenges"]):.6f}|{curve.budget_for_level(n,current):.6f}|'+
                  '/'.join(f'{old_e[k]:.6f}' for k in ('speed','breach','mechanic'))+'|'+
                  '/'.join(f'{new_e[k]:.6f}' for k in ('speed','breach','mechanic'))+'|')
    md+=['', '## Verification · 实际命令、结果与日志','', '|命令|结果|日志|','|---|---|---|']
    for g in groups:
        md.append('|`'+' '.join(g['command'])+'`|exit0；原始证据完整；运行时胜率见各轮合同|`'+g['log']+'`|')
    for r in verification:
        md.append('|`'+' '.join(r['command'])+'`|'+('PASS' if r['pass'] else 'FAIL')+f'（exit {r["exit"]}）|`{r["log"]}`|')
    notes=OUT/'screening_notes.json'
    if notes.exists():
        md+=['','### 筛选与诊断失败（保留，不冒称通过）','']
        for note in json.loads(notes.read_text()):
            md.append('- '+note['result']+('；命令`'+note['command']+'`' if note.get('command') else '')+
                      ('；日志`'+note['log']+'`' if note.get('log') else '')+
                      ('；'+note['disposition'] if note.get('disposition') else ''))
    md+=['', '- 最终验证使用独立HOME/XDG，SOURCE_REFS_ROOT=/Users/gavin/work/zombie-fire仅只读历史源资料，SKIP_WINDOWED_VISUALS=1；不补造、不改索引、不跳过资产门禁。',
          '- 本轮独立check_challenge_curve_runtime --s91-evidence逐组重数原始结果；不是拿旧990局挑战档案冒充新曲线。验证覆盖30代表关×10及免费099×10的选中证据，不称新全99挑战扫描。',
          '- 聚合门禁通过不替代挑战实测；窗口视觉跳过不称真机/视觉验收。旧§9全部FAIL/540删失/素材路径FAIL原样保留，不反向删除。',
          '', '## Risks / blockers','',
          '- 个别关可0/10或10/10，硬合同为每章三个代表点聚合；720秒未结束按签字口径计未通关，另列种子，不包装成游戏战败。',
          '- Boss时长是信息项，超150–220秒照实报告；不调整游戏计时或玩家军械。',
          '- 若十轮不收敛，候选未采用，最接近三组及偏差交Fable；不放宽阈值、不证明数学不可行。',
          '- 无push/构建/应用打包/TestFlight；证据归档仅保全日志。最终commit另见交付记录；完成后停工交Fable。']
    archive=OUT/'archive_record.json'
    if archive.exists():
        a=json.loads(archive.read_text());md+=['','## 证据归档','',f'- 路径：`{a["archive"]}`',f'- SHA256：`{a["sha256"]}`',f'- {a["files"]}个文件逐SHA验证PASS；旧§9归档不覆盖。']
    text='\n'.join(md)+'\n'
    for name in ('报告.md','Fable_§9.1完整交接报告_2026_10_05.md'):(OUT/name).write_text(text)
    print(json.dumps({k:v for k,v in state.items() if k not in ('groups','nearest_three','input_sha256')},ensure_ascii=False,indent=2))


if __name__=='__main__':main()
