历史状态（§8.1）：以下38/99和极端因子为旧合同探索证据，不是现行表。§8.2有界回刷的完整报告见本目录《报告.md》，当前表已按新口径重出；原候选保全为 resource_curve_table_envelope_historical_2026_10_04.json/.md。

# design/41 §8.1 · 包络合同与资源表C完整交接（2026-10-04）

## Completed

### 来源、范围与提交

- 工作位置：`/Users/gavin/work/zf-linear`，分支 `codex/linear-power`。本轮合并main至 `267211a33a7279b8ba31da82a774e0935053c7b1`，读取Owner转交Fable的§8.1。合并只增加design/41的合同文字。
- **源码、候选和证据提交：`6f0dc621de6d3d13c004f4da6039a98627d8e183`**。本报告是其后的文档交接提交；最终分支HEAD见chat交付，不将文档提交冒称新增模拟或探针。
- 仅在指定worktree工作；没有向主工作树发出文件操作，没有push、打包、上传TestFlight。本轮data、gameplay、core、export设置相对合并后的HEAD均零差异。
- 历史表B和八墙关T1不重做、不改。历史真实对局仍是6640局；本轮新增真实对局为0。以下候选函数调用绝不是Godot对局数。

### 工具完成

1. T3按§8.1判定：每关P≥.95rec，实际Boss与x7–x9的P≥rec；所有关P≤1.10E，E=max(65,rec累计最大值)。R仍为P/本关rec，不改为P/E。整数战力使用下限向上取整、上限向下取整。
2. 更新`verify_g1_feasibility.py`：逐关给出单调见证P=E，99/99成立、必要条件冲突0。原21处矛盾消除；**它仅证明抽象上下限在单调成长下自洽，不能证明资源曲线一定能实现该见证**。
3. 新增`derive_resource_curves.py`，只有审计输出入口，没有data写入入口。所有候选在深复制的内存表中模拟；保留现有账户购买/消费策略、角色Lv1属性、物品/技能上限、P(g)、F(g)、三轴公式与战斗数据。
4. 支持17参数指数/常数缩放族，以及23参数族（同一五档经验成本的单调因子结点）；不新增经验档位。结点可作单调光滑插值，但运行时仍是原五档直接查表，不声称游戏已改成连续插值。
5. 搜索仅涉及首通金币、掉落金币倍率、免费星门槛、免费武器升级基价、基础/专属技能经验成本。免费武器原线性升级公式不变；本轮没有引入武器成长段或改变任何战斗成长数值。
6. 缩放因子必须正且单调；最终首通金币曲线仍上升、掉落倍率曲线仍下降、五档经验成本仍不下降。价格、货币类型、付费商品/权益和premium字段不改。保存输入及参数族指纹，拒绝不匹配的resume；显式向量回放也检查来源输入。
7. 精确战力缓存仅复用相同构筑的原公式结果，不使用拟合代替计算。单测对缓存/未缓存的99关构筑、余额和战力结果作全量相等比较。
8. 新增独立`check_resource_curve_candidate.py`：拒绝过期输入、敌方/付费/越界字段、旧值不匹配、重复指针及曲线反向；逐字段应用到内存副本后独立重算全部99关。最终表的基线和候选与独立回放完全相等，但G1明确失败。

### 数据结论（不与工具通过混写）

当前资源的新合同基线：**64/99失败**，Σ|P−E|/E=**18.733553202969894**，首次R<.95为018。旧报告的40/99是旧方向A口径结果；§8.1把上限应用到所有关，不能把两个数字当同口径回归比较。

正式候选：`design/audits/resource_curve_table_2026_10_04.json/.md`。包含243个字段的旧值/候选值/因子、13条缩放曲线、每条系数，以及99关完整前后账户和闭环曲线。候选**没有写入游戏数据**。

|指标|原资源|当前草案|
|---|---:|---:|
|G1失败关数|64|38|
|Σ\|P−E\|/E|18.733553203|10.420963715|
|归一化越界总量|9.942571778|2.601532836|
|最大归一化越界|0.390202703|0.357388316|

目标下降不等于验收通过：该目标只在满足硬约束后才可作为合同内优化目标；当前仍有硬约束失败，因此不称“最优资源表”或“阶段三完成”。

|关键关|rec|E|候选P|规定整数范围|结果|
|---|---:|---:|---:|---|---|
|005|76|76|71|76–83|FAIL，下限|
|020|291|291|187|291–320|FAIL，下限|
|038|484|484|470|484–532|FAIL，下限|
|076|2758|2758|1844|2621–3033|FAIL，下限|
|095|3370|3370|3332|3370–3707|FAIL，下限|
|099|3094|3370|3339|3094–3707|离线G1 PASS，不是运行时胜率PASS|

失败关：005、009、011、013、014、015、016、018、019、020、025、030、034、037、038、039、040、044、045、050、057、060、066、069、070、071、072、073、074、075、076、078、079、080、090、093、094、095。完整上下限、方向和余额见表JSON同关行。

### 搜索过程与局限

|试验|调用次数（含形状拒绝）|G1失败|目标|结论|
|---|---:|---:|---:|---|
|17参数初轮，seed41004，35×population4|2449|33|13.518503623|历史失败；最终掉落曲线方向守卫还会拒绝，不能作为有效最佳候选|
|17参数第二轮，seed41005，85×population5|7311|39|10.224458052|未找到可行解|
|五结点up/up实验，seed41006，100×population5|11616|36|11.050214854|未找到可行解；由正式工具同方向回放复现|
|五结点down/up，seed41007，60×population4|5613|44|14.086668729|未找到可行解|
|up/up精确坐标细化4轮|737|38|10.420963715|当前草案，仍FAIL|

调用数不包括基线/最终重算，包含形状拒绝，因此不是有效T3次数或真实对局数。没有记录各历史轮有效T3调用数，不补造该统计。以上迭代均已结束，没有仍在后台的资源搜索。

在未找到可行解时，搜索使用越界平方、最大越界、越界总量优先的罚函数；只有零越界时才优化合同目标。36失败的试验与38失败的草案都保留，后者只是罚函数更小，并不声称合同更合格。所有结果不能证明全局最优，也不能用“优化器没找到”证明新G1合同不可行。

## Changed files

- 工具：`tools/progression_closure.py`、`test_linear_power_program.py`；新增`derive_resource_curves.py`、`check_resource_curve_candidate.py`、`test_resource_curves.py`。
- 更新本目录`verify_g1_feasibility.py`，新增`g1_envelope_feasibility_evidence.json`。旧`g1_feasibility_evidence.json`和旧G1停工报告保留作历史，不能当作现行合同结论。
- 基线：`design/audits/progression_closure_envelope_before_2026_10_04.json/.md`。
- 当前表：`design/audits/resource_curve_table_2026_10_04.json/.md`，逐字段候选均带file/pointer/old/new/factor。**本轮没有数据改动，故不存在“已按某表某行写入”的项**。
- 保全第二轮完整JSON/MD、初轮摘要、本目录证据，以及tier/down_up/polish三组完整试验JSON/MD。不把/tmp日志、游戏构建包、运行时素材放入git。
- 更新`design/m1_todo.md`和`design/m1_implementation_progress.md`；本轮没有改schema，因为没有新增或写入产品数据字段。
- main合并所得design/41 §8.1是Fable已核定合同，不是为本轮失败擅自改设计。

## Verification

以下为实际命令和真实结果。PASS生成与G1 FAIL分开；没有执行的项目不填PASS。日志均为`/tmp/zf_linear_*_2026_10_04.log`，搜索原日志不覆盖。

|实际命令/检查|结果|日志|
|---|---|---|
|git merge main；合并提交复核|PASS，合并267211a3；当时输出在会话，无补造历史日志；后续只读复核有日志|/tmp/zf_linear_p3_gateC_merge_verify_2026_10_04.log|
|python3 tools/audit_campaign_frontline.py --closure-report --closure-output design/audits/progression_closure_envelope_before_2026_10_04|PASS生成；G1 FAIL64/99|/tmp/zf_linear_p3_envelope_before_2026_10_04.log|
|python3 design/audits/linear_power_p3_2026_10_04/verify_g1_feasibility.py|PASS，99见证/0冲突；又保存同目录新JSON|/tmp/zf_linear_p3_envelope_feasibility_2026_10_04.log|
|新见证JSON的99行/状态/零冲突断言|PASS|/tmp/zf_linear_p3_gateC_witness_2026_10_04.log|
|python3 tools/test_linear_power_program.py（新包络口径）|PASS，17项|/tmp/zf_linear_p3_envelope_unit_2026_10_04.log；最终 /tmp/zf_linear_p3_gateC_linear_unit_2026_10_04.log|
|python3 tools/test_resource_curves.py（逐次加守卫）|PASS，先6项、8项、9项，最终11项|/tmp/zf_linear_p3_resource_unit_2026_10_04.log；/tmp/zf_linear_p3_resource_unit2_2026_10_04.log；/tmp/zf_linear_p3_resource_unit3_2026_10_04.log；/tmp/zf_linear_p3_resource_unit_final_2026_10_04.log；/tmp/zf_linear_p3_resource_unit_delivery_2026_10_04.log|
|nohup python3 -u tools/derive_resource_curves.py --iterations 35 --population 4 --output design/audits/resource_curve_table_2026_10_04|FAIL exit1，未达标；宿主wait保留|/tmp/zf_linear_p3_resource_search_2026_10_04.log|
|同工具 --resume --iterations 85 --population 5 --seed 41005 --output 同上（旧版checkpoint格式）|FAIL exit1，未达标；后续新增指纹守卫，不宣称旧无指纹checkpoint还能直接resume|/tmp/zf_linear_p3_resource_search2_2026_10_04.log|
|nohup python3 -u /tmp/zf_linear_resource_tier_experiment_2026_10_04.py --resume --checkpoint /tmp/zf_linear_resource_tier_checkpoint_2026_10_04.json --iterations 100 --population 5 --seed 41006 --output design/audits/resource_curve_tier_trial_2026_10_04|FAIL exit1，未达标；临时实验已由正式工具向量回放替代，不作为交付工具入口|/tmp/zf_linear_p3_resource_tier_search_2026_10_04.log|
|python3 tools/derive_resource_curves.py --xp-base-direction up --xp-sig-direction up --vector design/audits/resource_curve_tier_trial_2026_10_04.json --checkpoint /tmp/zf_linear_resource_replay_checkpoint_2026_10_04.json --output design/audits/resource_curve_table_2026_10_04|PASS生成/复现；G1 FAIL exit1|/tmp/zf_linear_p3_resource_primary_replay_2026_10_04.log|
|nohup python3 -u tools/derive_resource_curves.py --xp-base-direction down --xp-sig-direction up --iterations 60 --population 4 --seed 41007 --checkpoint /tmp/zf_linear_resource_down_up_checkpoint_2026_10_04.json --output design/audits/resource_curve_down_up_trial_2026_10_04|FAIL exit1，未达标|/tmp/zf_linear_p3_resource_down_up_search_2026_10_04.log|
|同工具 --xp-base-direction up --xp-sig-direction up --vector design/audits/resource_curve_tier_trial_2026_10_04.json --polish-rounds 4 --checkpoint /tmp/zf_linear_resource_polish_checkpoint_2026_10_04.json --output design/audits/resource_curve_polish_trial_2026_10_04（nohup、宿主wait）|FAIL exit1，未达标|/tmp/zf_linear_p3_resource_polish_2026_10_04.log|
|同工具 --xp-base-direction up --xp-sig-direction up --vector design/audits/resource_curve_polish_trial_2026_10_04.json --checkpoint /tmp/zf_linear_resource_final_checkpoint_2026_10_04.json --output design/audits/resource_curve_table_2026_10_04|PASS最终生成/来源输入守卫；G1 FAIL exit1|/tmp/zf_linear_p3_resource_final_2026_10_04.log|
|python3 tools/check_resource_curve_candidate.py design/audits/resource_curve_table_2026_10_04.json|PASS精确回放/字段白名单/输入/曲线；G1 FAIL exit1，38关|/tmp/zf_linear_p3_resource_final_replay_2026_10_04.log；早期trial2和tableC_replay日志分别保留|
|同工具显式回放trial1_summary的17维旧向量；直接candidate细查|预期拒绝（exit2/1），掉落倍率违反原下降方向；不视为有效候选|/tmp/zf_linear_p3_resource_trial1_shape_2026_10_04.log；/tmp/zf_linear_p3_resource_trial1_shape_detail_2026_10_04.log|
|python3 tools/validate_asset_pack.py|FAIL，已知历史源素材缺失|/tmp/zf_linear_p3_gateC_validate_asset_pack_2026_10_04.log|
|python3 tools/validate_data.py|PASS（磁盘游戏数据，非候选已写入）|/tmp/zf_linear_p3_gateC_validate_data_2026_10_04.log|
|python3 tools/check_res_refs.py|PASS|/tmp/zf_linear_p3_gateC_check_res_refs_2026_10_04.log|
|python3 tools/check_level_pressure.py|PASS|/tmp/zf_linear_p3_gateC_check_level_pressure_2026_10_04.log|
|python3 tools/simulate_card_director.py|PASS|/tmp/zf_linear_p3_gateC_simulate_card_director_2026_10_04.log|
|python3 tools/check_localization.py|PASS|/tmp/zf_linear_p3_gateC_check_localization_2026_10_04.log|
|python3 tools/check_clear_requirements.py|PASS|/tmp/zf_linear_p3_gateC_check_clear_requirements_2026_10_04.log|
|python3 tools/test_power_scale_v6.py|PASS，既有黄金测试；不是新G3|/tmp/zf_linear_p3_gateC_test_power_scale_v6_2026_10_04.log|
|python3 tools/check_campaign_pacing_contract.py|PASS|/tmp/zf_linear_p3_gateC_check_campaign_pacing_contract_2026_10_04.log|
|python3 tools/audit_campaign_frontline.py --check|PASS（既有夹具，未写新资源夹具）|/tmp/zf_linear_p3_gateC_audit_campaign_frontline_2026_10_04.log|
|python3 tools/report_fire_rate_tier_comparison.py --check|PASS|/tmp/zf_linear_p3_gateC_report_fire_rate_tier_comparison_2026_10_04.log|
|python3 tools/report_frontline_calibration.py --check|PASS|/tmp/zf_linear_p3_gateC_report_frontline_calibration_2026_10_04.log|
|python3 tools/generate_weapon_power_profiles.py --check|PASS|/tmp/zf_linear_p3_gateC_generate_weapon_power_profiles_2026_10_04.log|
|python3 tools/audit_free_elemental_weapons.py --check|PASS|/tmp/zf_linear_p3_gateC_audit_free_elemental_weapons_2026_10_04.log|
|独立临时HOME /opt/homebrew/bin/godot --headless --path /Users/gavin/work/zf-linear --quit|PASS|/tmp/zf_linear_p3_gateC_godot_boot_2026_10_04.log|
|同独立HOME Godot --headless --path /Users/gavin/work/zf-linear --script res://tools/m1_smoke_test.gd|PASS，M1通过标记，SCRIPT ERROR/ERROR均0|/tmp/zf_linear_p3_gateC_smoke_2026_10_04.log；HOME=/tmp/zf_linear_p3_gateC_home_2026_10_04.PElHLg|
|ZOMBIE_FIRE_SKIP_WINDOWED_VISUALS=1 python3 tools/check_release_candidate.py|FAIL，停在历史asset检查；未执行完聚合项目，不能称全绿|/tmp/zf_linear_p3_gateC_release_2026_10_04.log|
|python3 -m py_compile tools/progression_closure.py tools/derive_resource_curves.py tools/check_resource_curve_candidate.py tools/test_resource_curves.py design/audits/linear_power_p3_2026_10_04/verify_g1_feasibility.py|PASS|/tmp/zf_linear_p3_gateC_pycompile_final_2026_10_04.log|
|git diff --exit-code HEAD -- data gameplay core export_presets.cfg（提交前）|PASS，零改动|/tmp/zf_linear_p3_gateC_redlines_final_2026_10_04.log；交付复核见delivery_readcheck日志|
|git diff --check；git diff --cached --check（源码提交前）|PASS|/tmp/zf_linear_p3_gateC_whitespace_delivery_2026_10_04.log；cached检查会话输出；交付复核另留日志|

### 未执行 / 未通过

- 可行表C：**NOT ACHIEVED**。目前只有未达标候选，G1不能签成PASS；资源表写入：**NOT RUN**。
- 新资源写入后的T3/T2 --check资源新口径、schema数据变更、参考夹具 --write：**NOT RUN**，不越过C签字。
- 新参考夹具99×10（b2c_main_runtime_solved_001_099_ten_seed_<date>.json）：**NOT RUN**。
- G3 R=.85/1/1.15各10关×10种子：**NOT RUN**，不拿历史T1端点、静态黄金测试或T3替代。
- 阶段四099普通/挑战及章节代表点：**NOT RUN**；challenges.json未改。挑战推荐仍普通×1.5的既有机制，未实测新胜率。

## Risks / 下一步核验

1. **最大风险是资源目标没完成**，不是新G1的抽象合同冲突。包络自洽证明正确，候选失败也是真实结果；不能从搜索失败推断必须改敌方、放宽阈值或改尺子。
2. 当前免费武器价格系数约0.127–15.594，属于探索草案，改变体验的风险很大，绝不建议按此直接上线。paid商品与权益完全未改。
3. 已搜索的族不是全部可能的单调平滑曲线，局部/差分进化不构成全局不可行证明。尚未搜索战斗成长段；不私自加入新形状、新角色基础属性或重拟合F(g)来让报告变绿。
4. 如后续扩大候选族，应先明确“武器成长段”和“形状类型不改”的可执行边界；现有免费武器主要没有分段成长字段，不能默认为可新增任意分段。本轮只提交已明确受控的价格/资源缩放证据。
5. 以后即使批准表C，刷新账户参考夹具时仍须核对F(g)冻结：`PowerScaleV6.build_from_fixture()`会从夹具构筑建立三轴曲线，不能把新资源曲线造成的构筑变化悄悄重拟合成新尺子。本轮使用原模型曲线，未刷新夹具；该后续管线尚未验收。
6. 已知历史素材缺失照实保留，例如`assets/production/source_refs/generated/weapon_autocannon_icon_v2_raw_2026_07_21.png`及同版prompt。完整清单在asset日志；没有补造源文件、修改索引或跳过检查声称全绿。

交Owner转Fable：本轮在预先约定的C核验点交出**草案与失败证据**，不把它当成可写入的批准表。需要继续寻找合法的可行资源方案或核定上述候选族边界；不能先写失败草案再做后续验收。没有发送任何其他chat消息。
