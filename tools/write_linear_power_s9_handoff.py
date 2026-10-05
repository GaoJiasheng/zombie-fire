#!/usr/bin/env python3
"""Generate a self-contained §9 handoff from preserved, actual audit records."""
import argparse
import hashlib
import json
from pathlib import Path
import shlex
import subprocess

import run_linear_power_s9 as s9
import solve_runtime_clear_lines as t1


def load(name):
    return json.loads((s9.OUT/name).read_text())


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--stopped-for-clarification',action='store_true')
    args=parser.parse_args()
    live=s9.guard()
    baseline=load('s9_baseline.json')
    current=load('current_contracts.json')
    integrity=load('integrity.json')
    journal=load('commands.json')
    verification_initial=load('verification.json')
    verification_paths=sorted(s9.OUT.glob('verification*.json'),key=lambda p:p.stat().st_mtime)
    verification=load(verification_paths[-1].name)
    assert len(verification)==11 and verification[-1]['command'][-1]=='tools/check_release_candidate.py'
    g3=load('g3_s9_verdict.json')
    k=load('challenge_K_old_new_2026_10_05.json')
    current_sha=hashlib.sha256((s9.ROOT/'data/challenges.json').read_bytes()).hexdigest()
    restored=current_sha==baseline['input_sha256']['data/challenges.json']
    assert restored or current_sha==current['curve_sha256'], 'unreported active curve'
    adopted=not restored and current['status']=='PASS'
    head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=s9.ROOT,text=True).strip()
    changes=subprocess.check_output(['git','status','--short'],cwd=s9.ROOT,text=True).splitlines()
    records=[]
    total=0
    for r in journal:
        summary=load(r['label']+'_summary.json')
        total+=summary['runs']
        records.append({**r,'summary':summary})
    state={'authority':'2026-10-05 §41 §9','challenge_adopted':adopted,
           'challenge_data_restored':restored,'tested_curve_sha256':current['curve_sha256'],
           'active_curve_sha256':current_sha,'challenge_contracts':current['status'],
           'G3_hard_pass':g3['hard_pass'],'native_attempts':total,
           'native_completed':integrity['completed_new_runs'],'historical_incomplete':integrity['incomplete_seed_sets'],
           'static_smoke_rc_pass':all(r['pass'] for r in verification),
           'static_smoke_rc_matches_active_inputs':all(r.get('input_sha256')==live for r in verification),
           'initial_source_refs_invocation_pass':all(r['pass'] for r in verification_initial),
           'final_review_root':verification[-1]['source_refs_root'],
           'only_changed_combat_input':[p for p in live if live[p]!=baseline['input_sha256'][p]],
           'input_sha256':live,'report_base_commit':head,'no_push':True,'no_package':True}
    state['status']=('COMPLETE_AWAITING_FABLE' if adopted and state['static_smoke_rc_pass'] and state['static_smoke_rc_matches_active_inputs']
                     else 'STOPPED_FOR_PRESSURE_SCOPE_CLARIFICATION' if args.stopped_for_clarification
                     else 'IN_PROGRESS_NOT_ADOPTED')
    t1.atomic_write(s9.OUT/'handoff_state.json',state)
    lines=[f'状态：{state["status"]}；G3硬合同PASS；挑战重解未采用。' if not adopted else '状态：§9运行时合同及门禁已通过，待Fable核验。',
           '', '# design/41 §9 完整交接报告（2026-10-05）', '',
           f'- 分支：`codex/linear-power`，工作树：`{s9.ROOT}`。本报告生成基准commit：`{head}`；交付commit另见交付记录及chat。',
           '- 合并main并完整读取§9后执行；不push、不导出、不打包、不上传TestFlight。', '',
           '## Completed · 工具与执行', '',
           '- G3唯一硬合同为R=1.00→≥9/10；另两点为INFO。使用既有300局，不换种子、不重复已完成组。',
           '- 挑战K终点固定5与倍率上限5已按授权解冻到上限8，改动处注明“2026-10-05 §41 §9 重钉”。原单调、smoothstep、相邻18%、指数和1、固定种子与终点胜率/时长阈值保留。',
           '- 新局部运行器保全完整64项输入哈希、候选curve、实际命令与原始日志；仅按最新完整、逐关展开规则完全相同的组复用，不挑最佳种子/最佳组。',
           f'- 已结束入账组的原生尝试{total}局，完整{integrity["completed_new_runs"]}局；SCRIPT ERROR {integrity["script_errors"]}。历史逻辑上限{integrity["timeouts"]}局，未计为战败；进行中组不纳入已完成汇总，最终所选组的完整性需与历史未完成组分别看。',
           '- 076按指定炼狱整套重测固定10种子（参考等级保留）；095既有普通黄金律10/10、099普通免费满级10/10复用，普通数据与构筑输入均未变。',
           '- 阶段三资源紧缩表未采用，数值原样保存；当前资源G1下限0失败/10次回刷（018非门2、020门8），上限仅诊断。', '',
           '## Completed · 数据结论（不与工具通过混淆）', '',
           f'- G3硬合同：{"PASS" if g3["hard_pass"] else "FAIL"}。R=1.00十关均≥9/10，共94/100；R=.85为61/100、R=1.15为99/100，只作INFO。',
           '- 076炼狱：9/10 PASS，失败4409；095黄金律：既有10/10 PASS。炼狱测试人物16/武器41/护甲12/芯片13/宠物9/专属4；不是“新购买1级即可过门”或支付成本证明。',
           f'- 最后受测曲线合同：{current["status"]}；当前正式挑战数据{"已恢复本轮基线，失败候选仅在审计目录存档" if restored else "仍为受测曲线（是否采用见上述状态）"}。',
           '- 主线961/990、候选星表292★与已批294★的差异仍仅019/025从3→2，未替换已批表；需要Owner另行签字。', '',
           '### 各章最后受测参考胜率', '', '|章|代表点|胜/30|合同胜数|结论|', '|---|---|---:|---|---|']
    for r in current['chapters']:
        levels=[row['level'] for row in current['rows'] if (row['level']-1)//10+1==r['chapter']]
        verdict='PENDING' if r['pass'] is None else 'PASS' if r['pass'] else 'FAIL'
        lines.append(f'|{r["chapter"]}|{levels}|{r["wins"]}|{r["contract"]}|{verdict}|')
    lines+=['',f'- 099挑战免费：{current["free099"]["wins"] if current["free099"] else "PENDING"}/10（≤3）；黄金律：{current["golden099"].get("wins","PENDING")}/10（6–9），胜局Boss中位{current["golden099"].get("boss_median","PENDING")}s（150–220）。',
            '- `active_baseline_contracts.json`保全基线曲线的原首轮结论：免费5/10、黄金律10/10、Boss202.88秒；此记录只对应基线，不代表当前候选。恢复基线也不等于挑战问题已修好。',
            '', '### 全部迭代与原始命令', '', '|组|K99|局数|完整性|逐关胜数/未完成|原始stdout日志|', '|---|---:|---:|---|---|---|']
    for r in records:
        rows='；'.join(f'{row["level"]:03d}: '+(str(row["wins"])+"/10" if row.get('wins') is not None else '未完成'+str(row['unfinished_seeds'])) for row in r['summary']['rows'])
        lines.append(f'|{r["label"]}|{r["curve"]["anchors"][-1]["k"]}|{r["summary"]["runs"]}|{r["summary"]["integrity"]}|{rows}|`{r["log"]}`|')
    lines+=['','### 历史未完成组：真实败局与逻辑删失分开','',
            '|组/关|已完成胜数/完成数（非十种子合同）|真实败局种子|未完成种子|',
            '|---|---|---|---|']
    for record in records:
        if record['summary']['integrity']!='INCOMPLETE':continue
        raw=load(record['label']+'.json')['runs']
        for row in record['summary']['rows']:
            if row.get('status')!='INCOMPLETE':continue
            done=[r for r in raw if r['level']==row['level'] and not r.get('timeout')]
            lost=[r['seed'] for r in done if not r['victory']]
            lines.append(f'|{record["label"]}/{row["level"]:03d}|{sum(r["victory"] for r in done)}/{len(done)}|{lost}|{row["unfinished_seeds"]}|')
    lines+=['', '- 第二轮初稿K65=3.5触发相邻18%门禁FAIL：061→062为21.327%、062→063为20.981%；未启动原生局。改为3.15后结构PASS；阈值未改。',
            '- 第三轮原生CLI退出0，但原完整性包装器退出1（095三个逻辑超时）；原失败host日志保留。修正汇总器以明确INCOMPLETE而非伪战败，未改540秒探针/未重跑完成种子。',
            '- 第四轮同候选额外071十种子：邻接70压力分配变化，使071展开突破倍率相差一个浮点末位（1.8874965047533119/1.8874965047533120）。不放宽“完全匹配”复用检查，仅补该点；本轮合计110局，不重复099两条线或其他完整点。',
            '- 第三轮未完成095：2207/4409/7741，540.0167秒，Boss阶段493.03/481.52/493.93秒，剩余Boss比例84.91%/64.79%/70.93%；不是SCRIPT ERROR或墙钟360秒超时。未复跑同参数，后续曲线不同会单独测受影响点。', '',
            '- 第五轮仅改变K：删除65倍率锚点、60→70平滑爬升到5.1，80/90/99=5.3/5.7/6.1；压力分配均为基线。此前只读草案K70=5.2触发18.245%结构失败，未写入/未启动原生；5.1结构通过。额度恢复后继续明确授权范围内的搜索；涉及压力分配的补丁被权限审核拒绝且没有写入，不绕过审核。', '',
            '- 第五轮095未完成1103/3301，均触及540.0167秒逻辑上限；冻结时限不变，既不计战败，也不计通过。第六轮仅K99=5.8，受影响点091/095/099，40局；不同候选的新证据不覆盖历史未完成记录。', '',
            '- 第六轮095未完成4409/8849/9901，其余7完成均胜；全部历史8局逻辑删失逐条在integrity.json中列出。最新已知ch7/ch9/黄金律099失败明确报FAIL；095未核定单列，不用PENDING遮盖已知失败。', '',
            '### 最后受测逐点证据与失败种子', '', '|关|胜/10|胜局Boss中位s|失败种子|选择组|', '|---|---:|---:|---|---|']
    for r in current['rows']:
        lines.append(f'|{r["level"]:03d}|{r.get("wins","PENDING")}|{r.get("boss_median","PENDING")}|{r.get("failed_seeds",[])}|{r.get("selected_group","PENDING")}|')
    lines+=['', '## Changed files', '']
    lines += ['- `'+item+'`' for item in changes]
    lines+=['', '- 数据改动依据：每轮challenge候选仅对应§41 §9授权及各组`*_inputs.json`完整curve；下表是最后受测候选与基线的全99对照，不是未经验收的正式采用表。资源/普通敌方/付费军械/F(g)/翻卡/已批星表无改动。',
            '', '### 新旧K逐关对照（最后受测候选；未采用则不写回正式数据）', '', '|关|旧K|受测新K|差值|', '|---|---:|---:|---:|']
    for r in k['rows']:
        lines.append(f'|{r["level"]:03d}|{r["old_K"]:.6f}|{r["new_K"]:.6f}|{r["delta_K"]:+.6f}|')
    lines+=['', '- 挑战界面推荐值始终为普通推荐×1.5；K作用于实际挑战耐久/压力，不把K当显示倍率。表B方向A推荐值未改。', '',
            '## Verification · 每条实际命令及日志', '', '|命令|退出/结果|日志|', '|---|---|---|']
    for r in records:
        cmd=shlex.join(r['command'])
        lines.append(f'|`{cmd}`|exit {r["exit"]}；证据{r["summary"]["integrity"]}，胜率另按合同判|`{r["log"]}`|')
    for r in [item for path in verification_paths for item in load(path.name)]:
        invocation=shlex.join(r['command'])
        if r['command'][-1]=='tools/check_release_candidate.py':
            invocation='ZOMBIE_FIRE_SOURCE_REFS_ROOT='+r['source_refs_root']+' ZOMBIE_FIRE_SKIP_WINDOWED_VISUALS=1 '+invocation
        lines.append(f'|`{invocation}`|exit {r["exit"]} {"PASS" if r["pass"] else "FAIL"}|`{r["log"]}`|')
    lines+=['|`python3 tools/report_linear_power_acceptance.py --g3-s9`|PASS：十关硬点/其余INFO|`/tmp/zf_linear_s9_g3_2026_10_05.log`|',
            '|`python3 tools/validate_data.py`（r02初稿）|FAIL：18%相邻门禁，不掩盖|`/tmp/zf_linear_s9_validate_r02_2026_10_05.log`|',
            '|`python3 tools/validate_data.py`（r02修正）|PASS|`/tmp/zf_linear_s9_validate_r02_fixed_2026_10_05.log`|',
            '|`python3 tools/validate_data.py`（r03/r04）|PASS结构，不等于运行时胜率通过|`/tmp/zf_linear_s9_validate_r03_2026_10_05.log` / `/tmp/zf_linear_s9_validate_r04_2026_10_05.log`|',
            '|`python3 tools/verify_linear_power_s9.py`（全部组）|exit 0：范围PASS；历史INCOMPLETE 3局单列，不能写全局完整性全绿|`/tmp/zf_linear_s9_integrity_all_2026_10_05.log`|',
            '|`python3 tools/report_linear_power_s9.py --check`（r04补071前）|exit 1：PENDING/FAIL，071未匹配，不假称完整|`/tmp/zf_linear_s9_contracts_r04_full_2026_10_05.log`|',
            '|`python3 tools/report_linear_power_s9.py --check`（r04补071后）|exit 1 FAIL：ch7/9/10及黄金律终点|`/tmp/zf_linear_s9_contracts_r04_anchor_full_2026_10_05.log`|',
            '|`python3 tools/report_linear_power_s9.py --check --prefix active_baseline`|exit 1 FAIL：恢复后的正式曲线仍有原首轮挑战失败|`/tmp/zf_linear_s9_active_baseline_contracts_2026_10_05.log`|',
            '|`python3 -c … s9.guard()==baseline input_sha256 …`|exit 0 PASS：64项战斗输入逐字节恢复|`/tmp/zf_linear_s9_restore_guard_2026_10_05.log`|',
            '|`python3 -m unittest discover -s tools -p test_linear_power_s9.py -v`（补超时单测）|exit 0 PASS：6 tests，stdout/stderr均保全|`/tmp/zf_linear_s9_unit_r04_logged_2026_10_05.log`|',
            '|`python3 -m unittest discover -s tools -p test_linear_power_s9.py -v`（完整种子集回归）|exit 0 PASS：7 tests|`/tmp/zf_linear_s9_unit_continue_final_2026_10_05.log`|',
            '|`python3 tools/report_linear_power_s9.py --check --prefix r05`|exit 1 FAIL：ch7/ch9/黄金律099失败；095未完成单列|`/tmp/zf_linear_s9_contracts_r05_full_2026_10_05.log`|',
            '|`python3 tools/verify_linear_power_s9.py`（r05收齐）|exit 0 范围PASS；500尝试/495完整/5历史逻辑删失|`/tmp/zf_linear_s9_integrity_r05_full_2026_10_05.log`|',
            '|`python3 tools/report_linear_power_s9.py --check`（r06收齐）|exit 1 FAIL：ch7/ch9/黄金律099；095未完整单列|`/tmp/zf_linear_s9_contracts_r06_full_2026_10_05.log`|',
            '|`python3 tools/verify_linear_power_s9.py`（续跑收齐）|exit 0 范围PASS；540尝试/532完整/8历史逻辑删失，SCRIPT ERROR 0；全局原生完整性INCOMPLETE|`/tmp/zf_linear_s9_integrity_continue_full_2026_10_05.log`|',
            '|`python3 -c … s9.guard()==baseline input_sha256 …`（续跑后）|exit 0 PASS：64项战斗输入逐字节恢复，候选未采用|`/tmp/zf_linear_s9_restore_continue_2026_10_05.log`|',
            '|`python3 -m py_compile …`（续跑全部审计工具）|exit 0 PASS|`/tmp/zf_linear_s9_compile_continue_full_2026_10_05.log`|',
            '|`python3 -m py_compile tools/archive_linear_power_s9.py`|exit 0 PASS|`/tmp/zf_linear_s9_compile_archive_2026_10_05.log`|',
            '|`git diff --check`|exit 0 PASS|`/tmp/zf_linear_s9_git_diff_continue_2026_10_05.log`|',
            '|`python3 -m py_compile tools/run_linear_power_s9.py tools/report_linear_power_s9.py tools/verify_linear_power_s9.py tools/write_linear_power_s9_handoff.py tools/test_linear_power_s9.py tools/check_linear_power_s9.py tools/report_linear_power_acceptance.py tools/challenge_curve.py`|exit 0 PASS|`/tmp/zf_linear_s9_compile_r04_2026_10_05.log`|',
            '', '- 最终检查使用独立HOME/XDG/测试HOME；首次按Owner给定source_refs文件夹设置环境变量实际FAIL并保留日志。校验器文档要求变量为仓库根，该传法会重复拼接assets/production/source_refs；抽查指定源图实际存在。复跑采用文档支持的只读主仓根 `/Users/gavin/work/zombie-fire`，仅解析索引中source_refs/contact_sheets/tmp历史资料前缀；运行时资产仍查zf-linear。未改主仓、补造素材、改索引或跳过资产门禁。',
            '- 使用已有用户site-packages路径解决隔离HOME后Pillow不可见，不安装依赖。原失败结果与正确路径复跑结果均列在表中，不能删去前者。',
            '- 完整RC子项输出见上述release_candidate日志；静态RC通过不等于挑战实测合同通过，聚合器本身不含`check_challenge_curve_runtime.py`。窗口视觉矩阵按Owner指定skip，不宣称真机/视觉复验。',
            f'- 已完成的静态/RC验证是否匹配当前完整输入：{state["static_smoke_rc_matches_active_inputs"]}。基线恢复时PASS不自动沿用到后续候选；最终采用曲线须再跑独立门禁。',
            '', '## Risks / blockers 与需Fable核定', '',
            '- 当前未发现同时满足全部挑战胜率和Boss时长合同的已测候选；不把有限候选搜索声称为数学不可行证明。',
            '- 旧`challenge_curve.validate()`仍硬钉099压力指数S/B/M=1/0/0，而§9明确解冻K终点及旧上限5（新上限8）。需要核定“重解终点”是否也解除该指数锁；未擅自取消旧断言、改变指数和1、玩家军械、敌方数据或验收阈值。当前按合同范围待核停工；若明确要求仅调K，可继续更细的K-only采样，但不冒充本轮已证明不可行。',
            '- 续跑时权限审核也把61–98压力分配视为未授权，相关补丁被拒且未写入；已单独请求Owner明确这部分是否属于§9 curve重解。第5/6轮采用更窄的K-only替代，不绕过拒绝、不改099锁。',
            '- 若放行压力指数终点重解，将在同一曲线预算/固定种子下继续；这不是请求扩大到敌方或付费属性调整。既有完整组只按相同展开规则复用，95历史逻辑删失始终保留。',
            '- 先前G3宽带失败按§9已转INFO；先前source_refs门禁失败为隔离worktree不含gitignored素材，不是源素材真正缺失。新本轮RC结果以实际日志为准。',
            '- 资源紧缩表未采用；主线星表候选尚未签字；076换装为同参考等级过门证据，不等于购买即获相同等级。',
            '- 不push、不打包、不改主工作树。当前交付是已完成项+完整未收敛证据，不标记阶段四整体验收通过。', '',
            '## 文件与证据索引', '',
            '- `current_contracts.json`：最后受测候选逐关/逐章合同、选中来源及SHA。',
            '- `commands.json` / `*_inputs.json`：全部真实命令、完整输入、开始结束时间。',
            '- `integrity.json`：完整局与历史逻辑删失分列。',
            '- `verification.json`：独立HOME/显式source_refs全部实际验证。',
            '- `challenge_K_old_new_2026_10_05.json/.csv`：最后受测全99新旧K与压力规则。',
            '- `g3_s9_verdict.json`：三点全部数值与单点硬合同判定。',
            '- `s9_baseline.json`、`handoff_state.json`：冻结输入/当前正式数据是否恢复/未采用说明。',
            '- 原1630局完整交接：`../linear_power_p2_2026_10_04/Fable最终完整报告_2026_10_05.md`；原报告和证据不覆盖。',
            '- 原raw日志目录 `/tmp/zf_linear_s9_<组>_2026_10_05/`；失败host日志与所有历史尝试保留。证据归档路径/校验另见交付记录。', '']
    if (s9.OUT/'s9_archive_record.json').exists():
        archive=load('s9_archive_record.json')
        lines+=['## 证据保全（非应用打包）','',
                f'- 桌面归档：`{archive["path"]}`，不进git，不覆盖此前P1/墙关归档。',
                f'- SHA256：`{archive["sha256"]}`；{archive["native_groups"]}原生组、{archive["files_verified"]}文件逐字节SHA核对{archive["status"]}。',
                '- `s9_archive_manifest.json`逐文件列来源路径、成员名与SHA；`s9_archive_record.json`为整包校验。归档保留原生JSON/输入/汇总与实际日志，最终MD交接报告由仓库保存。',
                '- 实际命令：`python3 tools/archive_linear_power_s9.py`，exit 0 PASS；日志 `/tmp/zf_linear_s9_archive_continue_2026_10_05.log`。', '']
    (s9.OUT/'报告.md').write_text('\n'.join(lines))
    (s9.OUT/'Fable_§9完整交接报告_2026_10_05.md').write_text('\n'.join(lines))
    print(json.dumps(state,ensure_ascii=False,indent=2))


if __name__=='__main__': main()
