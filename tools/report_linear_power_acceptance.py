#!/usr/bin/env python3
"""Report actual §41 native evidence, keeping integrity and contract verdicts separate."""
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


def commands_table():
    sources = [P2/f'acceptance_main_command_{DATE}.json', P2/f'acceptance_static_verification_{DATE}.json', follow.JOURNAL,
               P4/f'acceptance_final_verification_{DATE}.json']
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
            prediction.append({**r, 'target_R': target, 'actual_R': construction['actual_R'],
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
    paid = [{**r, 'at_least_9_wins': r['wins']>=9} for r in evidence['paid_gates']['rows']]
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
          f"已批星表差异关：{star['changed_levels']}；新表仅供Fable核验，不自动采用。", '',
          '### 新旧星表全99行', '', '|关|旧星|新星|胜/10|基地中位%|P/rec|R|失败种子|', '|---|---:|---:|---:|---:|---|---:|---|']
    for r in main_rows:
        p2.append(f"|{r['level']:03d}|{r['approved_star']}|{r['derived_star']}|{r['wins']}|{r['base_median_pct']:.4f}|{r['power']}/{r['recommended']}|{r['R']:.4f}|{r['failed_seeds']}|")
    p2 += ['', '### G3：目标与实际R必须分开', '',
           '按统一缩放参考构筑的T1射线，枚举整数台阶，选最小达到目标的档位；不发明半级，不改技能上限。未精确命中R的样本不能作为精确R合同通过证据。',
           '0.85的原3–7/10阈值不变；悬崖0–2/10按B点决议照实记录。', '',
           '|关|目标R|实际R|档位超额|胜/10|请求带|胜数偏差|精确命中|失败种子|', '|---|---:|---:|---:|---:|---|---:|---|---|']
    for r in prediction:
        p2.append(f"|{r['level']:03d}|{r['target_R']:.2f}|{r['actual_R']:.6f}|{r['overshoot']:.6f}|{r['wins']}|{r['contract_wins']}|{r['deviation_wins']}|{r['target_exact']}|{r['failed_seeds']}|")
    p2 += ['', '## Changed files', '', '仅tools审计工具/审计构筑/结果JSON、新旧星表对照和报告。data、gameplay/core、玩家尺子、export均未改。当前资源表没有写入，已批星CSV没有替换。', '',
           '## Verification', '', *commands_table(), '',
           '每个native组的完整性与每关失败种子见acceptance_runtime_integrity及contract_conclusions；native完整性PASS不等于胜率合同PASS。', '',
           '## Risks', '', '方向A保留锯齿，原单调/G2偏差不以改敌方解决。T1射线存在同战力异构筑、离散技能台阶；未命中精确R的点是覆盖缺口而非通过。星级变化须Fable/Owner另核。',
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
           '|关|胜/10|至少9胜|失败种子|', '|---|---:|---|---|']
    for r in paid:
        p4.append(f"|{r['level']:03d}|{r['wins']}|{r['at_least_9_wins']}|{r['failed_seeds']}|")
    p4 += ['', '### 全部代表关失败种子', '', '|关|胜/10|失败种子|', '|---|---:|---|']
    for r in reps:
        p4.append(f"|{r['level']:03d}|{r['wins']}|{r['failed_seeds']}|")
    p4 += ['', '## Changed files', '', '审计构筑/原始结果汇总/报告；没有更改资源或付费价格权益。挑战推荐值仍为普通×1.5；推荐重标只改显示分母，不推导实际胜率。', '',
           '## Verification', '', *commands_table(), '', '## Risks', '',
           '若本首轮挑战带失败，仅允许按Owner授权调整challenges.json.curve并复验；本报告没有称未执行的调参与复验已通过。付费路线若失败不私改军械属性。',
           'T3挑战收入是条件假设，不由满级参考路线的胜率直接证明。Boss100%余血不说明无威胁，逐敌20秒损血预算与完整探针战报需一并看。']
    (P4/'首轮运行时验收报告.md').write_text('\n'.join(p4)+'\n')
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
    main()
