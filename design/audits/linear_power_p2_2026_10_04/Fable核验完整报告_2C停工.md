状态：合同冲突停工，等待 Fable/Owner 核定 G1；B 修订完成、2C 静态管线完成但运行时验收未完成，资源与阶段四未实施。

# 给 Fable 的完整交接报告 · 2026-10-04

- 分支：codex/linear-power；worktree：/Users/gavin/work/zf-linear。
- 本轮源码/数据/停工证据 commit：b8b4c31abfbc477dba1bdfd19f5015bbe39014c9。
- 随后的交接提交只修正文档尾部空行并补本报告/commit记录；最终分支哈希由Owner收到的chat回复提供，不用报告自引用哈希。
- 基准：65adca4c58a73ecd380293714d985f112ff015f4。未 push、未打包、未上传。
- 需核定的关键矛盾：005必须≥76，007必须≤58.3；初始战力65也已超007上限。全表21处必要条件矛盾，不能靠合法单调资源成长满足。
- 未运行的新验收：990局与G3；没有把既有6640局算成本轮新数据。
- 建议先核定不可逆成长下的G1上限口径，再放行完成2C新运行时验收、生成资源候选表C；表C仍须独立签字后才能写入。

## 附件一：阶段二 B 修订与 2C 全部记录

状态：停工交 Fable——B 修订完成，2C 静态管线已落地；2C 新运行时验收未完成；发现 §41 G1 资源合同硬冲突，未生成或写入资源候选表 C。

# design/41 · B 核定后 2C 交接报告（2026-10-04）

## Completed

### 工具与管线

- 本轮基于 codex/linear-power 的 65adca4c58a73ecd380293714d985f112ff015f4，仅在 /Users/gavin/work/zf-linear 工作。最终源码提交见同目录 commit 记录；没有 push、打包或 TestFlight。
- B 采用全部 92 个数值 P* 的同时 OLS：章节哑变量 + log 敌方总 HP + Boss 血量份额；不使用已废止的 Fable v0 近似。
- 加入核定 clamp：rec = clamp(round(sqrt(model × P*)), P*, round(1.35 × P*))，逐行记录 lower/upper/none。下界删失仍按 max(50, round(model))；上界删失保留 s=1.8 端点规则。
- 7 项 B 单测通过。以 /tmp/wip_gate/tableB_fixed.json 的原内容建立仓库内固定核验副本。重出同名 JSON/CSV，99 行与修正表精确一致，取整差异也为零。
- 2C 全章 runtime_solved：配置指向核定 B，生成器仅重标推荐值及需求侧派生字段；旧模式代码路径保留。本轮旧模式未单独做新运行时复验，不宣称已覆盖。
- P(g)、F(g)、构筑三轴换算、整个 economy.power_scale_v6 配置保持不变；需求侧通过原 F(g) 反解容量，绝不回写玩家尺子。
- 生成器最终连续运行两次，三份相关数据文件逐 SHA 相同；随后检查全部关卡推荐值 99/99 对表 B 一致。
- 推荐值检查/黄金测试中的旧推荐单调、相邻增幅及同档推荐 R 校准走廊，在新模式下由核定 B 真值边界检查取代；旧路径保留。玩家能力成长单调断言没有废止。
- M1 仅改推荐值/Owner R 数字并补“2026-10 runtime_solved 方向 A”注释。旧 B2 十种子样本检查明确标为历史证据，不再冒称新 G3 运行。
- 参考夹具 --write 已执行：构筑 rows 与 B 修订前逐字段一致，只刷新元数据/来源清单。四类派生报表已刷新并 --check 通过。
- design/41 §8 第2条追加“2026-10-04 停工点 B 核定”；design/40 仅追加 §14，记录 min_output 解冻、旧单调合同废止、锚点及 ch6/095/080/059 的重钉口径；schema 同步。
- T3 审计按方向 A 正确判定：Boss/x7–x9 使用 [1,1.10]，其余仅下限 .95；没有将章首高 R 当失败。新增审计口径测试，T1/T2/T3 离线回归共17项通过。
- B 工具新增显式 --source-commit 历史复现：逐文件验证 T1 冻结输入和夹具 SHA，再读取该 commit 的数据。默认当前输入守卫仍拒绝过期 T1；不拿已重标的 levels 去冒充原探针输入。

### 数据结论（与工具完成分开）

- 本轮 **没有新增真实探针对局**。历史 T1 总量仍为6640局（一期6210 + 八墙关430）；零脚本错误等历史结论见已签收报告，不算本轮新990局。
- B：92个数值 P*、7个下界删失；真实性边界违规0；与 Fable 修正表不一致0；clamp lower48 / upper1 / none50。
- 073：P*=606，model=1172.141825，推荐从843修正至818，上限 clamp 命中。
- 原48个低于通过端、29个不高于失败端的 B 风险列表均归零。这是数值关系结论，**不是 G3 已通过**。
- 八墙关推荐为015=147、017=165、018=185、019=188、020=291、040=574、044=757、076=2758；均不低于各自 P*。
- 7个下界删失关无数值 P*，其模型推荐不是实测通关保证，尤其007=53构成当前 G1 冲突的一部分。
- 新推荐锚点001/050/080/099分别50/868/2067/3094。
- Owner 构筑战力仍为080=4467、099=10800；R因分母变为2.161103和3.490627，不代表输出或伤害变强。
- 当前资源不变的 T3：49个约束关，G1失败40/99，首次 R<.95 为018，099战力4403、R=1.423077。它是假定所有首通3★的条件模拟，不是实际胜率或星级。

## Changed files

### 数据写入依据

- data/campaign_pacing_targets.json：仅新增根模式/表路径及切换七个章节范围的 clear_requirement_mode；99关范围未扩展。
- data/levels.json：逐关 clear_requirement.power_contract.recommended_power 对应 recommended_power_table_2026_10_04.json/.csv 的同一 level 行；其余 clear_requirement 派生字段由该模式和现有模型重算。
- 例如001对应表行001=50，050行050=868，080行080=2067，099行099=3094；**全99行映射**由幂等/红线日志中的逐行断言核对，无手调推荐值。
- v5 min_output 按授权解冻重算；013旧“雷电L1 / v5 min_output”生成器断言只在新模式废止，旧模式保留。记录在 design/40 §14，不把它解释成新实战平衡通过。
- **未改** economy.json、weapons/skills/characters/armors/chips/pets、zombies/bosses、waves/difficulty_coef/base_hp_ref、翻卡节奏、付费价格权益、gameplay/core、export_presets.cfg。levels 除 clear_requirement 外的所有字段逐关一致。

### 文件范围

- 工具：derive_recommended_power.py、test_derive_recommended_power.py、runtime_power_contracts.py、campaign_runtime_contracts.py、power_scale_v6.py（仅需求侧分支）、generate_clear_requirements.py、check_clear_requirements.py、test_power_scale_v6.py、m1_smoke_test.gd（数字/注释）、progression_closure.py、test_linear_power_program.py。
- B：recommended_power_table_2026_10_04.json/.csv；固定Fable修正表副本 recommended_power_table_fixed_fable_2026_10_04.json。
- 夹具：campaign_progression_fixture_builds.json、campaign_frontline_audit_manifest.json（来源元数据，不改构筑rows）。
- 记录：design/40 §14、design/41 §8修订行、design/data/schema.md、m1_todo/m1_implementation_progress。
- 审计：本报告、ruler_config_before_runtime_solved.json、progression_closure_runtime_solved_2026_10_04.json/.md，以及 p3 停工证据。四类报表刷新后内容无变化，不强行制造diff。

## Verification

下列都是实际执行结果。日志前缀为 /tmp/zf_linear_，没有用未执行项目填 PASS。初次与最终复核的日志分别保留。

|实际命令/检查|结果|日志|
|---|---|---|
|python3 tools/test_derive_recommended_power.py|PASS，7项|/tmp/zf_linear_p2c_tableB_unit_2026_10_04.log；最终 /tmp/zf_linear_p2c_tableB_unit_final_2026_10_04.log|
|python3 tools/derive_recommended_power.py --output design/audits/recommended_power_table_2026_10_04|PASS，写入前输入未漂移时执行|/tmp/zf_linear_p2c_tableB_derive_2026_10_04.log|
|同上 --check|PASS，写入前执行|/tmp/zf_linear_p2c_tableB_check_2026_10_04.log|
|python3 tools/derive_recommended_power.py --source-commit 65adca4c58a73ecd380293714d985f112ff015f4 --output design/audits/recommended_power_table_2026_10_04|PASS，逐文件冻结SHA验证后复现|/tmp/zf_linear_p2c_tableB_historical_reproduce_2026_10_04.log|
|同上 --check|PASS，99行一致|/tmp/zf_linear_p2c_tableB_historical_check_2026_10_04.log|
|python3 tools/generate_clear_requirements.py，连续两次|PASS，生成两次均exit0|/tmp/zf_linear_p2c_generate_1_2026_10_04.log；/tmp/zf_linear_p2c_generate_2_2026_10_04.log|
|初次字节幂等断言|PASS|/tmp/zf_linear_p2c_idempotence_2026_10_04.log|
|初次玩家尺子/红线断言|PASS|/tmp/zf_linear_p2c_ruler_and_redline_2026_10_04.log|
|最终内联断言：再连续生成两次、比较SHA、99行对表、所有原始关卡字段/其他data/gameplay/core/export/玩家配置/夹具rows对65adca4|PASS|/tmp/zf_linear_p2c_close_idempotence_redlines_2026_10_04.log|
|python3 tools/audit_campaign_frontline.py --write|PASS，仅元数据变动|/tmp/zf_linear_p2c_frontline_write_2026_10_04.log|
|python3 tools/generate_weapon_power_profiles.py|PASS|/tmp/zf_linear_p2c_profiles_2026_10_04.log|
|python3 tools/report_fire_rate_tier_comparison.py --write|PASS|/tmp/zf_linear_p2c_rates_write_2026_10_04.log|
|python3 tools/report_frontline_calibration.py --write|PASS|/tmp/zf_linear_p2c_calibration_write_2026_10_04.log|
|python3 tools/audit_free_elemental_weapons.py --write|PASS|/tmp/zf_linear_p2c_elemental_write_2026_10_04.log|
|python3 tools/check_clear_requirements.py|PASS|/tmp/zf_linear_p2c_close_clear_2026_10_04.log|
|python3 tools/test_power_scale_v6.py|PASS，15个黄金测试；历史B2证据不当新G3|/tmp/zf_linear_p2c_close_power_2026_10_04.log|
|python3 tools/check_campaign_pacing_contract.py|PASS|/tmp/zf_linear_p2c_close_pacing_2026_10_04.log|
|python3 tools/audit_campaign_frontline.py --check|PASS|/tmp/zf_linear_p2c_close_frontline_2026_10_04.log|
|python3 tools/report_fire_rate_tier_comparison.py --check|PASS|/tmp/zf_linear_p2c_close_rates_2026_10_04.log|
|python3 tools/report_frontline_calibration.py --check|PASS|/tmp/zf_linear_p2c_close_calibration_2026_10_04.log|
|python3 tools/generate_weapon_power_profiles.py --check|PASS|/tmp/zf_linear_p2c_close_profiles_2026_10_04.log|
|python3 tools/audit_free_elemental_weapons.py --check|PASS|/tmp/zf_linear_p2c_close_elemental_2026_10_04.log|
|python3 tools/test_linear_power_program.py|PASS，17项，无真实Godot探针对局|/tmp/zf_linear_p2c_linear_unit_final_2026_10_04.log|
|python3 -m py_compile tools/derive_recommended_power.py tools/runtime_power_contracts.py tools/progression_closure.py tools/campaign_runtime_contracts.py tools/check_clear_requirements.py tools/generate_clear_requirements.py tools/power_scale_v6.py tools/test_power_scale_v6.py tools/test_derive_recommended_power.py tools/test_linear_power_program.py design/audits/linear_power_p3_2026_10_04/verify_g1_feasibility.py|PASS|/tmp/zf_linear_p2c_close_pycompile_2026_10_04.log|
|python3 tools/validate_asset_pack.py|FAIL，已知历史源素材缺失|/tmp/zf_linear_p2c_close_assets_2026_10_04.log|
|python3 tools/validate_data.py|PASS|/tmp/zf_linear_p2c_close_data_2026_10_04.log|
|python3 tools/check_res_refs.py|PASS|/tmp/zf_linear_p2c_close_refs_2026_10_04.log|
|python3 tools/check_level_pressure.py|PASS|/tmp/zf_linear_p2c_close_pressure_2026_10_04.log|
|python3 tools/simulate_card_director.py|PASS|/tmp/zf_linear_p2c_close_cards_2026_10_04.log|
|python3 tools/check_localization.py|PASS|/tmp/zf_linear_p2c_close_localization_2026_10_04.log|
|独立临时HOME /opt/homebrew/bin/godot --headless --path /Users/gavin/work/zf-linear --quit|PASS|/tmp/zf_linear_p2c_close_godot_boot_2026_10_04.log|
|独立临时HOME /opt/homebrew/bin/godot --headless --path /Users/gavin/work/zf-linear --script res://tools/m1_smoke_test.gd|PASS，出现M1 smoke test passed，SCRIPT ERROR/ERROR 0|/tmp/zf_linear_p2c_smoke_2026_10_04.log|
|ZOMBIE_FIRE_SKIP_WINDOWED_VISUALS=1 python3 tools/check_release_candidate.py|FAIL，停在第一项历史素材检查；不是全绿，也不代表其余聚合项目都执行过|/tmp/zf_linear_p2c_rc_2026_10_04.log|
|python3 tools/audit_campaign_frontline.py --closure-report --closure-output design/audits/progression_closure_runtime_solved_2026_10_04（初次）|PASS生成；当时审计仍旧走廊，后续新口径结果取代|/tmp/zf_linear_p3_closure_before_2026_10_04.log|
|同上，新方向A口径|PASS生成；G1数据结论FAIL40/99|/tmp/zf_linear_p3_closure_directionA_2026_10_04.log|
|python3 design/audits/linear_power_p3_2026_10_04/verify_g1_feasibility.py|FAIL，exit1确认21个合同不可行点；不是程序崩溃|/tmp/zf_linear_p3_G1_feasibility_2026_10_04.log|
|git diff --cached --check；随后git show --format= --check源码提交复核|FAIL，仅p3报告EOF多一空行；交接文档提交中删除该空行，不改代码/数据|/tmp/zf_linear_p2c_commit_whitespace_initial_2026_10_04.log|
|git diff 65adca4c58a73ecd380293714d985f112ff015f4 --check（修正文档后）|PASS|/tmp/zf_linear_p2c_delivery_whitespace_final_2026_10_04.log|

前述8项静态管线检查也在初次实施、报表刷新后执行通过，日志为 /tmp/zf_linear_p2c_check_clear_2026_10_04.log、test_power、clear_final、power_final、pacing_final、frontline_check_final、rates_check_final、calibration_check_final、profiles_check_final、elemental_check_final 同前缀日期。最终验收以 close 系列为准，未覆盖旧日志。

### 未执行 / 未验收

- 新夹具99×10运行时扫关（b2c_main_runtime_solved_001_099_ten_seed_2026_10_04.json）：NOT RUN，没有该产出。
- 新表下G3 R=.85/1/1.15各10关×10种子：NOT RUN，不能拿T1既有通过端或离线预测代替。
- 当前--check通过不证明上述新运行时合同。R=.85可能0–2/10的核定说明已记录，未来要如实报，不放宽阈值。
- derive_resource_curves.py/达标候选资源表C/写入资源/优化后T3/T2新资源门禁：NOT RUN，遇合同硬冲突后停工。
- 阶段四099普通/挑战及章节代表点复验：NOT RUN；challenges.json 未改。
- 已知挑战推荐仍普通×1.5，普通推荐重标会连带挑战显示；新099理论分母3094×1.5=4641，未做新挑战实测。

## Risks / blockers

**真正停工原因是 §41 G1 与核定锯齿 B + 不降级的成长模型不相容，不是历史素材缺失。**

005是Boss约束关，rec=76，要求power≥76。007是x7约束关，rec=53，要求power≤58.3（整数读数最大58）。玩家成长/永久技能/最强已拥有武器选择不会丢失已获战力，因此005之后无法在007降到58；即使不给任何资源，初始角色+武器的固定战力65也超过007上限。

全表21个不可行点与复核方法在 ../linear_power_p3_2026_10_04/报告.md 和 g1_feasibility_evidence.json。按唯一停工规则停止，不自行改敌方、推荐表、角色Lv1、尺子、成长选择策略或G1阈值。

需要Fable/Owner明确G1上限如何适配不可逆成长。可讨论“上限按累计必要战力包络，而真实性R仍按本关rec显示”，或“上限改诊断项，仅保留约束关≥1/全程≥.95”；这些都属于**待决合同修订，未实施**。

已知素材缺失示例：assets/production/source_refs/generated/weapon_autocannon_icon_v2_raw_2026_07_21.png、weapon_autocannon_icon_v2_prompt_2026_07_21.json，完整列表在资产日志。不补造、不改索引。

此前B报告中的073/v0 FAIL是历史事实；本轮核定修订已解决，不倒改历史报告。当前尚不能宣称阶段二整体验收通过、阶段三完成或阶段四完成。

## 附件二：资源合同冲突的完整证据与停工说明

状态：BLOCKED_CONTRACT——资源表 C 尚未生成，资源数值零写入；已按停工规则交 Fable 判定。

# design/41 · 资源闭环可行性停工报告（2026-10-04）

## Completed

### 审计完成

- B点已核定并按修订写入2C需求侧；本报告使用2026_10_04核定表，不使用已废止的v0。
- 按§41 §8最新G1，重新生成未调资源的T3条件闭环。Boss关与x7–x9要求R∈[1,1.10]；所有其他关只要求R≥.95；章首高R不记失败。
- 新G1审计分支保留旧模式。该口径新增离线单测，17项T1/T2/T3回归通过。
- 完成只读可行性检查，并保存99行证据JSON与可复核脚本。本脚本是停工证据，不是资源曲线优化器。
- 未创建derive_resource_curves.py，未生成resource_curve_table候选，未写first_clear_reward/reward_gold_mult/星门槛/武器成长成本/技能经验成本；不把“无法产生满足合同的表”包装成已完成表C。
- 不自行推送给其他chat；本报告供Owner转交Fable。

### 数据结论

- 当前T3失败40/99；首次低于.95是018，099 power4403 / rec3094 = R1.423077。
- 约束关49个。账户战力在当前99行基线中确实不降；但这里的不可行性不是只因为当前奖励方案不好，而是上下限在单调成长下没有交集。
- 存在21个必要条件无法满足的点：007、025、027、028、029、035、037、058、059、067、069、077、078、079、080、085、087、088、089、097、098。
- 初始免费账户战力65（vanguard Lv1 / autocannon Lv1 / 无护甲芯片宠物 / 无永久技能或专属等级）。该Lv1构筑与P(g)、F(g)不能通过资源奖励或升级成本调整变弱。
- 本报告中的T3仍假定全部首通3★；没有证明该账户实际上能拿3★。没有新增真实运行时对局。

## 为什么不能靠合法资源调参修好

1. 005有boss_tank_titan，是硬约束关；核定rec76，因此G1要求power≥76。
2. 007是章尾x7，核定rec53，因此G1要求power≤1.10×53=58.3；整数战力最大58。
3. 当前策略在所有已拥有武器中选择power_for_build最高者，已拥有项不会丢失；等级/永久技能不降，允许的资源与成长曲线也是单调缩放。已有能力不能在005→007期间降到58。
4. 因此无论给多少金币/经验、何时解锁、怎样调整升级成本，005的下限与007的上限都冲突。即便未达005，固定初始战力65已经高于007上限。
5. 不只下界删失007：057 rec990要求至少990，而058 rec503上限553.3；两关均有数值P*。单纯给删失关例外也无法解决全局问题。

“Boss包络调资源”不足以修正逐关上限——包络可以满足前面墙关的最低能力，但该能力在后续低推荐的约束关会保留。禁止改变敌方/核定表、禁止损失永久成长的前提下，需先澄清G1合同。

## 全表必要条件证据

对每关取 lower(L)=rec(L)（约束关）或ceil(.95×rec(L))（其余关）。
从初始65开始维护E(L)=max(65, lower(1),…,lower(L))。
约束关upper(L)=floor(1.10×rec(L))。若E(L)>upper(L)，任何不降战力的参考进度都不可能达标。
这是**必要条件检查**，即使没有这些矛盾，也不代表实际金币/星/等级离散闭环一定可行。

|不可行关|本关rec|必须已拥有的最低战力E|下限来源关|本关最大整数战力|
|---|---:|---:|---|---:|
|007|53|76|005|58|
|025|260|291|020|286|
|027|195|291|020|214|
|028|231|291|020|254|
|029|206|291|020|226|
|035|219|332|030|240|
|037|232|332|030|255|
|058|503|990|057|553|
|059|562|990|057|618|
|067|955|1125|066|1050|
|069|978|1125|066|1075|
|077|1652|2621|076|1817|
|078|2226|2621|076|2448|
|079|2030|2621|076|2233|
|080|2067|2621|076|2273|
|085|2204|2621|076|2424|
|087|1857|2621|076|2042|
|088|1857|2621|076|2042|
|089|1994|2621|076|2193|
|097|1863|3370|095|2049|
|098|2720|3370|095|2992|

## Changed files

- tools/progression_closure.py：仅审计G1判定口径/报告元信息，旧模式保留；不改账户购买/成长策略或奖励计算。
- tools/test_linear_power_program.py：新增方向A G1边界测试。
- design/audits/progression_closure_runtime_solved_2026_10_04.json/.md：未调资源的基线闭环。
- 本目录verify_g1_feasibility.py、g1_feasibility_evidence.json、本报告：停工证据。
- m1_todo、m1_implementation_progress：记录B修订/2C部分完成及新的合同停工状态。
- **资源游戏数据零变更。** 2C的推荐字段写入范围见阶段二2C报告，不算资源表C写入。

## Verification

|实际命令|结果|日志|
|---|---|---|
|python3 tools/audit_campaign_frontline.py --closure-report --closure-output design/audits/progression_closure_runtime_solved_2026_10_04|PASS生成；新G1数据结论FAIL40/99|/tmp/zf_linear_p3_closure_directionA_2026_10_04.log|
|python3 design/audits/linear_power_p3_2026_10_04/verify_g1_feasibility.py|FAIL，exit1为21处不可行的预期报告，不是异常|/tmp/zf_linear_p3_G1_feasibility_2026_10_04.log|
|python3 tools/test_linear_power_program.py|PASS，17项|/tmp/zf_linear_p2c_linear_unit_final_2026_10_04.log|
|python3 -m py_compile（包括本目录证据脚本和T3）|PASS|/tmp/zf_linear_p2c_close_pycompile_2026_10_04.log|

证据JSON内容从上述只读脚本实际stdout保存，不人为编造优化后数值；其输入SHA可复核核定B和当前闭环。全部项目检查及已知资产/聚合门禁FAIL详见../linear_power_p2_2026_10_04/2C报告.md，不重复宣称全绿。

未执行：资源曲线优化、资源候选新旧对照、优化后闭环、资源写入、T2资源新门禁、新990局/G3、阶段四挑战复验。

## Risks / blockers / 需 Fable 核定

- **唯一新增停工原因：最新G1上限与不可逆成长、核定锯齿推荐表冲突。** 不擅改合同以通过测试，也不调敌方或强迫玩家降装。
- 建议Fable明确资源约束采用何种口径：
  - 上限改用累计必要战力包络E(L)（或另一个签字后的包络），而本关真实性推荐rec/R继续原样显示；或者
  - 保留约束关R≥1和全程R≥.95，把逐关上限改为诊断项。
- 上述是需要Owner签字的选择，**均未实施**，不推定已允许放宽阈值。
- 如坚持现有每个Boss/x7–x9都R≤1.10，则必须重开推荐表/敌方/永久成长等冻结项之一，超出本轮授权。
- 2C运行时验收仍欠990局及G3专项；即使合同修订，也应继续这些验收，不因静态通过而跳过。
- 历史validate_asset_pack缺源素材照实FAIL，未补造或改索引。无push、无游戏包、无上传。

提交：与阶段二2C管线一并保存在codex/linear-power；完整提交哈希见阶段二commit记录。
