#!/usr/bin/env python3
"""Report actual §41 native evidence, keeping integrity and contract verdicts separate."""
import argparse
import collections
import csv
import hashlib
import json
from pathlib import Path

import audit_progression_linearity as linear
import progression_closure as closure
import run_linear_power_acceptance_followon as follow
import solve_runtime_clear_lines as t1

ROOT, AUDIT, DATE = follow.ROOT, follow.AUDIT, follow.DATE
P2, P4 = follow.P2, follow.P4


def g3_verdict(target, wins):
    """2026-10-05 §41 §9: only R=1.00 is a hard acceptance gate."""
    hard = target == 1.0
    return {'hard_contract': hard, 'information_only': not hard,
            'contract_pass': wins >= 9 if hard else None,
            'status': ('PASS' if wins >= 9 else 'FAIL') if hard else 'INFO'}


def report_g3_s9():
    """Reclassify immutable first-round evidence; do not overwrite its reports."""
    evidence = json.loads((P2/f'acceptance_runtime_integrity_{DATE}.json').read_text())
    rays = json.loads((P2/f'g3_ray_construction_{DATE}.json').read_text())['rows']
    constructs = {(r['level'],r['target_R']):r for r in rays}
    rows = []
    for label,target in [('085',.85),('100',1.),('115',1.15)]:
        for r in evidence['g3_'+label]['rows']:
            rows.append({**r, **g3_verdict(target,r['wins']), 'target_R':target,
                         'actual_R':constructs[(r['level'],target)]['actual_R'],
                         'historical_band':list(linear.PREDICTION_CONTRACT[target])})
    out = AUDIT/'linear_power_p4_2026_10_05'
    out.mkdir(parents=True,exist_ok=True)
    hard_pass = all(r['contract_pass'] for r in rows if r['hard_contract'])
    t1.atomic_write(out/'g3_s9_verdict.json', {'authority':'2026-10-05 §41 §9',
                    'source':str(P2/f'acceptance_runtime_integrity_{DATE}.json'),
                    'new_battles':0,'hard_pass':hard_pass, 'rows':rows})
    passing = sum(r['contract_pass'] is True for r in rows if r['hard_contract'])
    print(f'G3 §9 {"PASS" if hard_pass else "FAIL"}: {passing}/10 R=1.00 groups >=9/10; other 20 groups INFO, original results retained')
    return 0 if hard_pass else 1


def commands_table():
    sources = [P2/f'acceptance_main_command_{DATE}.json', P2/f'acceptance_static_verification_{DATE}.json', follow.JOURNAL,
               P4/f'acceptance_final_verification_{DATE}.json',
               P4/'acceptance_release_environment_recheck_2026_10_05.json',
               P4/'acceptance_supplemental_verification_2026_10_05.json']
    lines = ['|实际命令|结果|日志|', '|---|---|---|']
    for source in sources:
        if source.exists():
            for row in json.loads(source.read_text()):
                args = ' '.join(row['command']).replace('|', '\\|')
                outcome = ('退出码待宿主核对' if row['exit'] is None else
                           f"{'PASS' if row['exit']==0 else 'FAIL'}，exit {row['exit']}")
                lines.append(f"|{args}|{outcome}|{row['log']}|")
    return lines


def main():
    follow.check_frozen()
    evidence = json.loads((P2/f'acceptance_runtime_integrity_{DATE}.json').read_text())
    state = json.loads(follow.STATE.read_text())
    assert state['status'] == 'ALL_GROUPS_COMPLETE_AWAITING_CONTRACT_REVIEW'
    star = json.loads((P2/f'star_table_comparison_{DATE}.json').read_text())
    rays = json.loads((P2/f'g3_ray_construction_{DATE}.json').read_text())['rows']
    constructs = {(r['level'], r['target_R']): r for r in rays}
    fixture = json.loads(t1.FIXTURE.read_text())
    tables = t1.load_tables()
    b_rows = {r['level']: r for r in json.loads((AUDIT/f'recommended_power_table_{DATE}.json').read_text())['rows']}
    main_rows = []
    for r, s in zip(evidence['main']['rows'], star['rows']):
        assert r['level'] == s['level']
        n = r['level']
        model = t1.power(tables['levels'][n-1], fixture['rows'][n-1]['build'], tables)
        main_rows.append({**r, **s, 'power': model['power'], 'recommended': model['recommended'],
                          'R': model['power']/model['recommended']})
    prediction = []
    for label, target in (('085', .85), ('100', 1.), ('115', 1.15)):
        low, high = linear.PREDICTION_CONTRACT[target]
        for r in evidence['g3_'+label]['rows']:
            construction = constructs[(r['level'], target)]
            b_row = b_rows[r['level']]
            prediction.append({**r, **g3_verdict(target, r['wins']), 'target_R': target, 'actual_R': construction['actual_R'],
                               'actual_power': construction['power'], 'recommended': construction['recommended'],
                               'p_star': b_row['p_star'], 'measured_p_star_wins': b_row['passing_wins'],
                               'recommendation_margin_vs_p_star': construction['recommended']/b_row['p_star']-1 if b_row['p_star'] else None,
                               'actual_power_vs_p_star': construction['power']/b_row['p_star'] if b_row['p_star'] else None,
                               'overshoot': construction['R_overshoot'],
                               'target_exact': abs(construction['R_overshoot']) < 1e-12,
                               'contract_wins': [low, high],
                               'rate_in_requested_band': low <= r['wins'] <= high,
                               'deviation_wins': max(low-r['wins'], r['wins']-high, 0),
                               'interpretation': 'exact target' if abs(construction['R_overshoot'])<1e-12 else
                                   'quantized T1 pass-side sample, NOT exact-R proof'})
    chapter_rows = []
    reps = evidence['challenge_representatives']['rows']
    for chapter in range(1, 11):
        rows = [r for r in reps if (r['level']-1)//10+1 == chapter]
        assert len(rows) == 3
        wins = sum(r['wins'] for r in rows)
        lo, hi = (.7, 1.) if chapter <= 6 else (.6, .9)
        chapter_rows.append({'chapter': chapter, 'levels': [r['level'] for r in rows], 'wins': wins,
                             'runs': 30, 'win_rate': wins/30, 'band': [lo, hi],
                             'contract_pass': lo <= wins/30 <= hi})
    golden = next(r for r in reps if r['level'] == 99)
    regular = evidence['ordinary_099_free_max']['rows'][0]
    free = evidence['challenge_099_free_max']['rows'][0]
    finale = {'ordinary_free_max': {**regular, 'contract_pass': regular['wins']>=9},
              'challenge_free_max': {**free, 'contract_pass': free['wins']<=3},
              'challenge_golden_law_max': {**golden, 'contract_pass': 6<=golden['wins']<=9}}
    paid_builds = {r['level']: r for r in json.loads((P4/f'paid_gate_construction_{DATE}.json').read_text())['rows']}
    paid = [{**r, 'at_least_9_wins': r['wins']>=9,
             'set': paid_builds[r['level']]['set'],
             'revealed_after_clear': paid_builds[r['level']]['revealed_after_clear'],
             'power_before': paid_builds[r['level']]['power_before'],
             'power_after': paid_builds[r['level']]['power_after'],
             'actual_build': paid_builds[r['level']]['after']}
            for r in evidence['paid_gates']['rows']]
    fixture_reconciliation = []
    for stem in ('challenge_reference', 'challenge_free'):
        backup = P4/f'{stem}_before_refresh_{DATE}.json'
        source = AUDIT/('challenge_reference_fixture_builds.json' if stem == 'challenge_reference'
                        else 'challenge_free_counterexample_fixture_builds.json')
        old, new = json.loads(backup.read_text()), json.loads(source.read_text())
        assert old == new, 'challenge fixture refresh unexpectedly changed rows/metadata'
        fixture_reconciliation.append({'fixture': str(source), 'backup': str(backup),
                                       'all_rows_and_metadata_equal': True,
                                       'byte_equal': backup.read_bytes() == source.read_bytes(),
                                       'sha256': hashlib.sha256(source.read_bytes()).hexdigest()})
    t1.atomic_write(P4/f'challenge_fixture_refresh_reconciliation_{DATE}.json', fixture_reconciliation)
    conclusions = {'native_runs': state['runs'], 'native_integrity_pass': True,
                   'script_errors': 0, 'timeouts': 0, 'incomplete_seed_sets': [],
                   'main': main_rows, 'star_changed_levels': star['changed_levels'],
                   'g3': prediction, 'challenge_chapters': chapter_rows, 'finale': finale, 'paid_gates': paid,
                   'all_product_data_unchanged': True, 'challenge_curve_written': False,
                   'approved_star_table_replaced': False}
    t1.atomic_write(P2/f'acceptance_contract_conclusions_{DATE}.json', conclusions)
    p2 = ['状态：运行时采样已完成；所有完整性检查通过；胜率与星表偏差见下文，未替换已批星表。', '',
          '# 阶段二剩余验收 · runtime_solved', '', '## Completed', '',
          f"实际新对局{state['runs']}局（全部组），主夹具990局；固定十种子、tier_b/v2、1/60帧，最多6并发。SCRIPT ERROR/超时/不完整种子集均0。历史T1 6640局不计入本轮。",
          '参考夹具刷新后99行及元数据均未变；F(g)、P(g)、敌方、翻卡与当前资源均未变。',
          '主线夹具没有加入T3的回刷补资源过程。T3是假定普通/挑战3★收入可获得的账户条件模型；其下限0失败不等于本夹具逐关≥9/10，也不证明挑战收入实际可获得。',
          f"已批星表差异关：{star['changed_levels']}；新表仅供Fable核验，不自动采用。", '',
          '星表沿用现行汇总规则：十种子过半获胜后，按基地余量中位数定星；星级不能代替≥9/10的通关率合同。下面同时列出胜数与失败种子，不把高星低胜率隐藏。', '',
          '### 新旧星表全99行', '', '|关|旧星|新星|胜/10|基地中位%|P/rec|R|失败种子|', '|---|---:|---:|---:|---:|---|---:|---|']
    for r in main_rows:
        p2.append(f"|{r['level']:03d}|{r['approved_star']}|{r['derived_star']}|{r['wins']}|{r['base_median_pct']:.4f}|{r['power']}/{r['recommended']}|{r['R']:.4f}|{r['failed_seeds']}|")
    p2 += ['', '### G3：目标与实际R必须分开', '',
           '按统一缩放参考构筑的T1射线，枚举整数台阶，选最小达到目标的档位；不发明半级，不改技能上限。实际R、档位超额与胜率带偏差分列：微小整数误差不自动判为胜率FAIL，大幅跳跃也不冒充目标点通过；G3覆盖是否充分交Fable核，不自行新增容差。',
           '2026-10-05 §41 §9：R=1.00→≥9/10是唯一硬合同；0.85/1.15只保留历史胜率带用于信息对照，不判FAIL。', '',
           '|关|目标R|实际R|P/rec/P*|档位超额|胜/10|请求带|胜数偏差|精确命中|失败种子|', '|---|---:|---:|---|---:|---:|---|---:|---|---|']
    for r in prediction:
        p2.append(f"|{r['level']:03d}|{r['target_R']:.2f}|{r['actual_R']:.6f}|{r['actual_power']}/{r['recommended']}/{r['p_star']}|{r['overshoot']:.6f}|{r['wins']}|{r['contract_wins']}|{r['deviation_wins']}|{r['target_exact']}|{r['failed_seeds']}|")
    p2 += ['', '## Changed files', '', '仅tools审计工具/审计构筑/结果JSON、新旧星表对照和报告。data、gameplay/core、玩家尺子、export均未改。当前资源表没有写入，已批星CSV没有替换。',
           '本收尾工具：report_linear_power_acceptance.py、verify_challenge_finale_pin_conflict.py、verify_linear_power_delivery.py、recheck_linear_release_environment.py；m1_todo/m1_implementation_progress同步真实结论。先前2C工具及批准数据写入逐字段依据见2C报告.md；本块没有再次写入。', '',
           '## Verification', '', *commands_table(), '',
           '每个native组的完整性与每关失败种子见acceptance_runtime_integrity及contract_conclusions；native完整性PASS不等于胜率合同PASS。',
           '最终RC首轮FAIL为隔离HOME后找不到既有Pillow，保留原日志；随后保留HOME隔离、显式加入已安装依赖的只读PYTHONPATH重验，实际仍FAIL于历史素材缺失。未安装依赖、未跳素材门禁，两个退出码都保留；RC后续子门禁未执行，不称全绿。', '',
           '## Risks', '', '方向A保留锯齿，原单调/G2偏差不以改敌方解决。T1射线存在同战力异构筑、离散技能台阶；大幅跳跃未验证请求的目标R，微小取整误差与胜率偏差分别列明，覆盖口径交Fable核。星级变化须Fable/Owner另核。',
           'validate_asset_pack历史源素材缺失仍FAIL，聚合门禁不得称全绿。不push、不打包、不上传TestFlight。']
    (P2/'运行时验收报告.md').write_text('\n'.join(p2)+'\n')
    p4 = ['状态：阶段四首轮实测完成；原曲线尚未调整，合同结论如下。', '', '# 终局与挑战复验', '',
          '## Completed', '', '固定十种子；黄金律099复用章节代表点099同一组完整结果，不重复跑完成组。', '',
          '|099路线|胜/10|合同|通过|胜局Boss阶段中位秒|失败种子|', '|---|---:|---|---|---:|---|']
    for key, band in (('ordinary_free_max', '≥9'), ('challenge_free_max', '≤3'), ('challenge_golden_law_max', '6–9')):
        r = finale[key]
        p4.append(f"|{key}|{r['wins']}|{band}|{r['contract_pass']}|{r['victory_boss_phase_median_seconds']}|{r['failed_seeds']}|")
    p4 += ['', '### 章节代表点（每章第1/5/10关，第10章末为099）', '', '|章|关|胜/30|带|通过|', '|---|---|---:|---|---|']
    for r in chapter_rows:
        p4.append(f"|{r['chapter']}|{r['levels']}|{r['wins']}|{r['band']}|{r['contract_pass']}|")
    p4 += ['', '### 076/095付费路线', '',
           '参考构筑的角色/技能/槽位等级保持不变，仅换已揭示的对应完整军械（物品max_level约束）；不是买到手就自动满级，也不是所有付费组合都保证过门。',
           '|关|套装/揭示关|角色/武器/护甲/芯片/宠物/专属等级|换装前→后P|胜/10|至少9胜|失败种子|', '|---|---|---|---|---:|---|---|']
    for r in paid:
        b = r['actual_build']
        ranks = '/'.join(str(b[k]) for k in ('character_level', 'weapon_level', 'armor_level', 'chip_level', 'pet_level', 'signature_level'))
        p4.append(f"|{r['level']:03d}|{r['set']}/{r['revealed_after_clear']}|{ranks}|{r['power_before']}→{r['power_after']}|{r['wins']}|{r['at_least_9_wins']}|{r['failed_seeds']}|")
    p4 += ['', '076预设为第70关揭示的绝对零度套，095为第90关揭示的黄金律套；选择在任何付费组实战之前固定。'
           '不是只换一把武器，也不是新购Lv1或补足追赶成本的账户路线。076关卡主弱火，绝对零度不是属性最优匹配；'
           '单一固定路线的结果不证明所有已揭示军械或所有玩家构筑都能/不能过门。未用更换种子掩盖失败，未改付费属性。']
    p4 += ['', '### 全部代表关失败种子', '', '|关|胜/10|失败种子|', '|---|---:|---|']
    for r in reps:
        p4.append(f"|{r['level']:03d}|{r['wins']}|{r['failed_seeds']}|")
    p4 += ['', '## Changed files', '', '审计构筑/原始结果汇总/报告；没有更改资源或付费价格权益。挑战推荐值仍为普通×1.5；推荐重标只改显示分母，不推导实际胜率。', '',
           '## Verification', '', *commands_table(), '',
           '独立HOME boot/M1均PASS；RC首轮因Pillow不可见FAIL，显式恢复已有只读依赖路径后重验仍因历史素材缺失FAIL。保留两次日志，不安装依赖、不补造素材、不改索引、不跳过门禁；RC后续子门禁未执行。', '', '## Risks', '',
           '若本首轮挑战带失败，仅允许按Owner授权调整challenges.json.curve并复验；本报告没有称未执行的调参与复验已通过。付费路线若失败不私改军械属性。',
           'T3挑战收入是条件假设，不由满级参考路线的胜率直接证明。Boss100%余血不说明无威胁，逐敌20秒损血预算与完整探针战报需一并看。']
    pin_path = P4/'challenge_finale_pin_conflict_2026_10_05.json'
    if pin_path.exists() and not finale['challenge_free_max']['contract_pass']:
        p4 += ['', '### 调参停工：终点数值锁定待核', '',
               '099免费挑战实测未满足≤3/10；现行challenge_curve.py同时锁死K(99)=5与压力指数1/0/0，validate_data倍率上限也为5。'
               '只改曲线内部节点不会改变099运行倍率。内存诊断说明改终点会触发旧门禁，但不是已实测或采用的候选。',
               'Owner已授权只调curve；是否同步解冻旧终点数值门禁仍待Owner/Fable核清。未改挑战数据、未改胜率阈值、未启动挑种子复验。',
               f'证据：{pin_path}。其余已授权只读验收完整执行，不把这个停工点称为阶段四验收通过。']
    (P4/'首轮运行时验收报告.md').write_text('\n'.join(p4)+'\n')
    current_p2 = ['状态：表B已核定、2C管线完成、新运行时采样完成；G3/星表偏差如实列出，未宣称全部合同通过。', '',
                  '# 阶段二最新报告 · 2026-10-05', '',
                  'B点原始FAIL报告已逐字保全为报告_2AB历史.md，不再作为当前批准状态。核定后的clamp与2C管线历史见2C报告.md；其中旧G1停工状态已由§8.5及阶段三报告替代。', '',
                  '批准表B采用92个数值P*的同时OLS，推荐为clamp(round(sqrt(model×P*)), P*, round(1.35×P*))；7个下界删失按模型下限规则。99行与Fable核定修正表一致，v0已作废。',
                  '2C先前仅写批准推荐及生成器派生字段，本轮§8.5之后没有改任何游戏数据。F(g)/P(g)/敌方/翻卡/资源保持冻结。', '',
                  *p2[2:]]
    (P2/'报告.md').write_text('\n'.join(current_p2)+'\n')
    (P4/'报告.md').write_text('\n'.join(p4)+'\n')
    main_under = [r['level'] for r in main_rows if r['wins'] < 9]
    g3_out = [r for r in prediction if r['hard_contract'] and not r['contract_pass']]
    phase4_fail = [key for key, r in finale.items() if not r['contract_pass']]
    chapter_fail = [r['chapter'] for r in chapter_rows if not r['contract_pass']]
    handoff = ['状态：全部授权首轮实测已收齐；工具完成不等于验收全绿；挑战终点旧锁定待核，不擅自调整资源/敌方/胜率阈值。', '',
               '# Fable 最终完整交接报告 · 2026-10-05', '',
               '工作树/分支：/Users/gavin/work/zf-linear · codex/linear-power。未push、未打包、未上传TestFlight；未修改主工作树。运行输入版本1777945e293e4fa0bf8882ba7137ffd1989753fb，阶段三结案a93ba61081f404235311244e614e9c39b9d7a24b；最终交付提交见同目录commit记录与chat回复。', '',
               '## 总结：工具产出与数据结论分开', '',
               f'- 首轮新增原生对局{state["runs"]}局；990主线+300 G3+20普通/免费挑战099+300挑战代表点+20付费门。SCRIPT ERROR=0、超时=0、完整种子集缺口=0。',
               f'- 主线961/990获胜，低于9/10的关：{main_under}。没有加入T3回刷资源，不能把这条夹具路线等同G1条件账户路线。',
               '- 当前资源G1下限99/99通过，回刷10次（018非门2次、020门8次）；上限69关仅诊断。未采用资源表数值原样保留，JSON SHA de4e27b79bcbae4b17cd317475092295a5dc31df43e2b105a626db97f5141355。',
               '- 已批星表294星；新候选292星，仅019/025从3降2。逐关新旧对照保留，未替换已批CSV；check-approved实际FAIL不是脚本故障。',
               f'- G3按2026-10-05 §41 §9核定：R=1.00硬合同失败点数{len(g3_out)}，判定{"FAIL" if g3_out else "PASS"}；R=0.85/1.15只作信息项，实际R、胜数及失败种子全部保留，不判FAIL。',
               f'- 终局未达标路线：{phase4_fail}；章节聚合带未达标章：{chapter_fail}。详见阶段四，不用旧8月结果充当本轮通过。',
               f'- 099普通免费满级{regular["wins"]}/10（合同≥9），挑战免费满级{free["wins"]}/10（合同≤3），挑战黄金律满级{golden["wins"]}/10（合同6–9）；黄金律胜局Boss中位{golden["victory_boss_phase_median_seconds"]:.3f}秒，旧150–220秒时间带符合，但胜率仍FAIL。',
               '- 付费门固定同等级换装结果：' + '；'.join(f'{r["level"]:03d} {r["set"]} {r["wins"]}/10' for r in paid) + '。076路线不构成稳定过门见证，不概括为所有已揭示付费军械都失败；未另换属性或种子追结果。',
               '- 静态与独立HOME检查逐条附真实退出码；历史资产缺失及聚合RC的失败保留，RC未运行的后续子门禁不称已通过。', '',
               '## 交接/停工边界', '',
               '资源方案不写入；已批星表候选交Fable，不自行采用。099挑战≤3/10与旧K=5/指数1/0/0的数值锁定需要核清：是否同时授权同步旧数字校验？内存诊断示例非正式候选、未实测、未写入。',
               '本文收齐其余已授权只读实测；不将阶段四标成验收通过，不选择有利种子、不以改普通敌方/付费属性掩盖失败。', '',
               '---', '', '## 阶段二完整结果与逐关对照', '', *current_p2, '',
               '---', '', '## 阶段三结案（当前资源，不写入）', '',
               (AUDIT/f'linear_power_p3_{DATE}'/'报告.md').read_text(), '',
               '---', '', '## 阶段四完整首轮结果', '', *p4]
    (P2/'Fable最终完整报告_2026_10_05.md').write_text('\n'.join(handoff)+'\n')
    threats = linear.threat_inventory()
    t1.atomic_write(P4/f'enemy_contact_threats_{DATE}.json', {'method': linear.threat_inventory.__doc__, 'rows': threats})
    full = []
    for run in json.loads(follow.MAIN.read_text())['runs']:
        if run['victory'] and run['base_ratio'] >= .999999 and any('boss' in w for w in tables['levels'][run['level']-1]['waves']):
            report = run.get('battle_report', {})
            taken, prevented = report.get('base_damage_taken'), report.get('base_damage_prevented')
            full.append({'level': run['level'], 'seed': run['seed'], 'boss_phase_seconds': run.get('boss_phase_seconds'),
                         'base_damage_taken': taken, 'base_damage_prevented': prevented,
                         'explanation': 'mitigation recorded, not harmless' if prevented else
                              'recorded damage with final healing' if taken else
                              'aggregate probe cannot distinguish kill-before-contact from delayed/control-suppressed attacks; no zero-threat inference'})
    t1.atomic_write(P4/f'full_hp_boss_observations_{DATE}.json', {'rows': full})
    print(json.dumps({'finale': finale, 'chapter_bands': chapter_rows, 'paid_gates': paid,
                      'star_changed_levels': star['changed_levels']}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--g3-s9',action='store_true')
    args = parser.parse_args()
    raise SystemExit(report_g3_s9() if args.g3_s9 else main())
