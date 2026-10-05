状态：2A 完成、2B 候选表及工具交付；停工点 B 待 Fable 核验。表 B 验收 FAIL（073 +39.11% 超35%；v0方法不一致）；未写游戏数据，2C、阶段三、阶段四未开工。

# design/41 方向 A · Fable 完整交接报告（停工点 B）

工作树：`/Users/gavin/work/zf-linear`。分支：`codex/linear-power`。不 push、不打包、不上传 TestFlight。

本轮本地时间10月3日启动、10月4日完成。原T1汇总/证据/日志沿用指定的2026_10_03命名；候选表和交付报告以完成日期2026_10_04命名。

交付物：[表 B JSON](/Users/gavin/work/zf-linear/design/audits/recommended_power_table_2026_10_04.json) · [逐关 CSV](/Users/gavin/work/zf-linear/design/audits/recommended_power_table_2026_10_04.csv) · [完整证据核验汇总](/Users/gavin/work/zf-linear/design/audits/linear_power_p2_2026_10_04/wall_evidence_summary_2026_10_03.json) · [桌面新证据归档](/Users/gavin/Desktop/zombiefire_evidence/runtime_clear_lines_2026_10_03_walls.tar.gz)。


## Fable 交接摘要与核验入口

本报告以已提交交付版本 `39dfe1f0dec5893c1c1c1d3ce0c10f7b0132755b` 为工具/数据基准；本次只整理交接文档并读回核验既有产物，不新增采样、不重新跑关、不修改候选表或配置。下方的 PASS/FAIL 均对应真实历史命令；未跑项单独列明。

### 本次希望 Fable 给出的决议

1. **确认表 B 推导的权威算法**：是否采用明文的 HP、Boss份额、章节偏移同时 OLS（本工具已实现），或提供 v0 原推导代码及经 Owner 批准的方法修订。当前差异不能解释为单纯取整，不能把新增墙关引起的全局重拟合与原方法不一致混为一谈。
2. **解决 073 的明文公式与35%门禁冲突**：P*=606、模型1172.141825、候选843，+39.1089%；v0=838，也超限。需要明确经批准的表/公式调整或合同例外；Codex不代签、不裁到818、不改阈值。
3. **确认后续 G3 验收风险与处置边界**：48关rec低于已测通过端，29关不高于已测失败端；这些是旧参考构筑缩放射线的证据，不是候选推荐值的全新R=1抽验。特别是017/040/044的rec低于旧推荐，与“墙关如实上调”的预期有张力。不能仅凭±35%验收就宣称R=1≥9/10；若后续G3不达标且不能在授权范围处理，应再次停工，不动敌方数据。
4. 核过并解决上述冲突后，明确放行2C；表C仍须单独停工核验，不因本轮授权阶段二至四而跳过C点。

### 审核建议（只读）

- 核候选表99行：`design/audits/recommended_power_table_2026_10_04.json/.csv`，重点看 `violations`、`fit`、`baseline_84_fit`、`v0_reproduction_mismatches_over_rounding`、逐关 `difference_explanation` 与 G3 风险列。
- 核真实运行：`wall_evidence_summary_2026_10_03.json` 中 `wall_rows`、`censored`、`passing_endpoint_exactly_9_of_10`、`seven_step_limit_without_precision`，各失败种子均有原始证据引用。
- 查归档凭据：`wall_evidence_archive_2026_10_03.json`；旧、新桌面tar不在Git，新包不覆盖旧包。
- 红线差异：`git diff f055c7b4073aa5e45a916f3f4c49929d3fb2877a 39dfe1f0dec5893c1c1c1d3ce0c10f7b0132755b -- data gameplay core export_presets.cfg` 应为空。
- 表B确定性检查：`python3 tools/derive_recommended_power.py --output design/audits/recommended_power_table_2026_10_04 --check` 当前预期exit1；产物确定性已通过，exit1保留的是073真实性及v0一致性失败，不能当成已验收PASS。

### 本次交接文档复核

- 2026-10-04 只读核验：分支/交付commit、干净起点、99行/92数值P*、073 FAIL、6640总局/430新增局、零脚本错误与不完整集、桌面新包SHA、红线diff及既有22项测试日志：**PASS**。
- 日志：`/tmp/zf_linear_p2b_fable_handoff_readcheck_2026_10_04.log`。
- 本次新增文件：`design/audits/linear_power_p2_2026_10_04/Fable完整交接报告.md`；不把文档核验冒称为重跑全部门禁。

## Completed

### 工具与执行

- 阶段一已获 Fable/Owner 验收；`git merge main` 成功，合并提交 `7c59ff55`，同步 §8 与 Fable v0 CSV。
- 墙关扩区工具提交 `085dd413`：仅 015/017/018/019/020/040/044/076，s∈[1.0,1.8]、现行等级上限、固定十种子、≥9/10、七步或 R 宽≤0.02、jobs=6。
- 长跑采用 nohup；宿主会话11058/PID12229自然结束exit0。证据沿用`/tmp/zf_linear_t1_2026_10_03`，旧采样复用，其余91关不重跑。缓存续跑命令仅清理已过时的原删失说明，八关全skip，新增探针0。
- 表 B 工具按明文同时 OLS 拟合 log P* 的 HP、Boss 血量份额与章节偏移；QR 求解、无正则化、无逐关手改，不单调化、不施加相邻增幅约束。

### 数据结论

- **新增43个独立采样×10种子=430局**，与旧6210局合计**6640局/664独立采样**。99关全有bracket，92个数值P*、7个下界删失（001/002/003/004/006/007/011），没有上界删失。SCRIPT ERROR=0、超时/异常/不完整种子集=0，checkpoint errors=[]。
- 其余91关与阶段一commit逐字段相同；八墙关旧steps前缀原样复用。旧桌面包SHA不变，旧包清单中的13717文件逐SHA/大小不变。没有完成组重跑。

|关卡|旧推荐|P*通过端|旧尺子R*|胜数/失败种子|表B候选rec|rec/P*−1|R宽≤.02|
|---|---:|---:|---:|---|---:|---:|---|
|015|126|147|1.166667|9/10，7741|130|−11.56%|否，七步|
|017|133|165|1.240602|9/10，5513|128|−22.42%|否，七步|
|018|149|185|1.241611|9/10，5513|172|−7.03%|否，七步|
|019|157|188|1.197452|10/10|177|−5.85%|是|
|020|167|291|1.742515|10/10|235|−19.24%|否，七步|
|040|540|574|1.062963|9/10，1103|534|−6.97%|是|
|044|632|757|1.197785|9/10，1103|611|−19.29%|否，七步|
|076|2273|2758|1.213374|9/10，6637|2433|−11.78%|是|

全部92个数值边界中37个达到R宽≤0.02，55个在七步上限停止；未额外增加二分次数。全量恰9/10的55关及各自失败种子在核验JSON单列，关卡如下：

`008,010,012,013,014,015,016,017,018,026,028,031,032,033,034,036,038,039,040,041,042,043,044,045,047,048,049,051,052,054,055,056,057,058,059,063,065,070,072,073,074,076,077,078,079,081,084,086,089,091,092,094,096,097,099`。

- 表B使用**92个数值P***同时OLS拟合：a=−0.8242840671，b=0.4590179511，c=0.7146793579；第1章作为偏移基准，章2–10偏移与全部完整系数见JSON。log R²=0.93693158，残差人口σ=0.26542801。无权重、无正则、无单调处理。
- 候选表99行、显示下限50全部符合；数值P*的真实性检查91/92通过。**唯一失败073：P*=606，model=1172.141825，rec=round(sqrt(model×606))=843，偏差+39.1089%>35%。**保持公式原结果，不自动裁剪到818，也不放宽35%。Fable v0该行rec=838，同样+38.2838%，已超35%；问题并非墙关补测新造。
- 复算原 84 点发现 Fable v0 模型不符合明文同时拟合结果。原84点同时OLS系数 a=-0.8552869、b=0.4619851、c=0.6673878、R²=0.945688；不含章节偏移的三列OLS系数 a=-2.2912950、b=0.5885216、c=0.7175452，与§8括号中的a/b/c一致。
- 对 CSV 整数 hp_model 作逆向诊断，b≈0.60020、c≈−0.00027，模型整数残差最多1。推断 CSV 更接近“HP 指数0.6+章节校正、几乎不含Boss份额”；这是从输出反拟合的证据，不是对 Fable 未提供源代码的断言。日志见 Verification。
- 不为贴合 v0 偷换算法。最终表逐关解释新增墙关对全局拟合的影响、原84点方法差异和取整；表 B 交 Fable 核源方法。
- 当前候选rec有93行不同于v0；原84点明文复算的模型/rec有95行超出取整一致性范围（含仅有模型比较的原墙关）。逐关`baseline_84_model / baseline_84_rec / delta_vs_fable_v0 / difference_explanation`区分“新增8点导致全局重拟合”与“在原84点上就存在的方法差异”，不把全部差异归因于墙关。
- **G3尚未验收**：48关候选rec低于已测通过端，其中29关不高于该构筑射线已测失败端：`015,017,018,019,020,024,038,039,040,043,044,045,046,053,055,057,060,061,066,069,072,074,076,078,079,083,087,088,098`。这不是新R=1运行测试，也不证明其他构筑必败；但不能据±35%通过就宣称R=1≥9/10。017/040/044的候选rec甚至低于旧推荐，尽管补测P*高于旧推荐；是指定几何平均公式的结果，未擅自加逐关保底。

### 证据归档

- 新包：`/Users/gavin/Desktop/zombiefire_evidence/runtime_clear_lines_2026_10_03_walls.tar.gz`，**8,595,157 bytes**，**14705 regular files**逐SHA/大小核验，SHA256：`b96672b3defac37c7844e67b979bb7dd3bc9404c79325160f8039d288f32ef23`。
- 旧包保持：`runtime_clear_lines_2026_10_03.tar.gz`，SHA256：`fb6db5387887673ee6f33a32d3aaf0201b1eea224b1304a4ccb71cc0c1da6722`。
- 原始采样、完整证据清单及归档时的管理日志快照已保全；归档之后完成的最终冒烟日志检查、表B换行修复重验与本报告不冒称包含在这个tar内，其真实最终日志路径列在下表。两个包都不入Git，原/tmp工作证据保留。

## Changed files

- `tools/solve_runtime_clear_lines.py`、`tools/test_linear_power_program.py`：墙关扩区、等级封顶、守卫与断点复用测试。
- `tools/derive_recommended_power.py`、`tools/test_derive_recommended_power.py`：表 B 明文拟合、推荐公式、v0差异与真实性检查。
- `tools/archive_runtime_clear_line_evidence.py`：旧证据逐SHA保持检查、完整十种子核验与新档案无覆盖发布。
- `design/audits/runtime_clear_lines_2026_10_03.json`：只续写八墙关审计结果；不是游戏配置数据。
- `design/audits/recommended_power_table_2026_10_04.json/.csv`：99行候选、拟合系数、逐关v0解释、073失败、G3风险列；不是已批准或已写入的配置。
- `design/audits/linear_power_p2_2026_10_04/wall_evidence_summary_2026_10_03.json`、`wall_evidence_archive_2026_10_03.json`：核验汇总与桌面归档凭据。
- 本报告与 `design/m1_todo.md`、`design/m1_implementation_progress.md`：阶段签收与进度。
- 产品数据写入：无。表 B 未批准，无“按表写入”映射；2C及表C未执行。

## Verification

所有实际命令均在 zf-linear 执行；日志放 /tmp。以下只记录已执行项。

|命令|结果|日志|
|---|---|---|
|`git merge main`|PASS，无冲突，仅design/41与v0 CSV|`/tmp/zf_linear_p2ab_merge_2026_10_03.log`；提交7c59ff55|
|`nohup python3 -u tools/solve_runtime_clear_lines.py --levels 15,17,18,19,20,40,44,76 --resume --wall-extension --jobs 6 --output design/audits/runtime_clear_lines_2026_10_03.json --evidence-dir /tmp/zf_linear_t1_2026_10_03`|PASS，exit0；430新增局，八关complete|`/tmp/zf_linear_p2a_walls_2026_10_03.log`|
|同参数缓存续跑（去除旧删失reason）|PASS，exit0，八关全部skip，新增探针0|`/tmp/zf_linear_p2a_resume_metadata_2026_10_03.log`|
|`python3 tools/test_linear_power_program.py`（首轮）|FAIL：新测试发现空装备槽识别；修正后重验，保留原日志|`/tmp/zf_linear_p2a_unit_2026_10_03.log`|
|同上（修正后）|PASS：16项；包括扩区/删失/复用/封顶/守卫|`/tmp/zf_linear_p2a_unit_retry_2026_10_03.log`|
|同上（最终代码）|PASS：16项|`/tmp/zf_linear_p2a_unit_final_2026_10_03.log`|
|`python3 tools/test_derive_recommended_power.py`|PASS：最终6项，含CSV稳定换行|`/tmp/zf_linear_p2b_unit_last_2026_10_03.log`；前5项通过日志`/tmp/zf_linear_p2b_unit_final2_2026_10_03.log`|
|12列QR合成系数核验|PASS：误差<1e-10|`/tmp/zf_linear_p2b_qr_chapter_test_2026_10_03.log`|
|`python3 -m py_compile tools/solve_runtime_clear_lines.py tools/derive_recommended_power.py tools/archive_runtime_clear_line_evidence.py tools/test_derive_recommended_power.py tools/test_linear_power_program.py`|PASS；最终收尾日志另列|`/tmp/zf_linear_p2ab_compile_last_2026_10_03.log`|
|T1 / 表B / 归档工具 `--help`|PASS|`/tmp/zf_linear_p2a_help_2026_10_03.log`、`/tmp/zf_linear_p2b_help_2026_10_03.log`、`/tmp/zf_linear_p2a_archive_help_2026_10_03.log`|
|原84点按明文同时OLS复算v0|FAIL：不是取整误差；待Fable核方法|`/tmp/zf_linear_p2b_v0_fit_2026_10_03.log`|
|全局3列OLS后逐章平均残差诊断|FAIL：也无法逐行复现v0；不作为候选方法|`/tmp/zf_linear_p2b_v0_method_2026_10_03.log`|
|v0 CSV逆向模型诊断|PASS：逆拟合整数模型最大残差1；非批准推导方法|`/tmp/zf_linear_p2b_v0_diagnostic_2026_10_03.log`|
|八墙关s=1.8封顶构筑清单|PASS|`/tmp/zf_linear_p2a_cap_inventory_2026_10_03.log`|
|冻结哈希/夹具哈希/分支/受保护路径diff|PASS：全部不变|`/tmp/zf_linear_p2ab_frozen_2026_10_03.log`|
|旧桌面包SHA、旧清单13717文件逐SHA核对|PASS|`/tmp/zf_linear_p2a_original_archive_2026_10_03.log`、`/tmp/zf_linear_p2a_prior_files_2026_10_03.log`|
|`python3 tools/archive_runtime_clear_line_evidence.py --report-dir design/audits/linear_power_p2_2026_10_04`（首轮）|FAIL：/tmp与/private/tmp路径别名造成误报“未引用”；不是探针损坏|`/tmp/zf_linear_p2a_evidence_verify_2026_10_03.log`|
|同上（路径归一化修正后）|PASS，issues=[]；6640局全部证据有效|`/tmp/zf_linear_p2a_evidence_verify_retry_2026_10_03.log`|
|同上加`--archive`|PASS，exit0，14705文件逐SHA校验，原包未覆盖|`/tmp/zf_linear_p2a_walls_archive_2026_10_03.log`|
|`python3 tools/derive_recommended_power.py --output design/audits/recommended_power_table_2026_10_04`|FAIL(exit1)的合同结果；工具成功产出99行候选，073超35%及95行v0一致性失败如实保留|`/tmp/zf_linear_p2b_derive_2026_10_03.log`、修复换行后`/tmp/zf_linear_p2b_derive_retry_2026_10_03.log`|
|同上加`--check`（首轮）|FAIL：CSV CRLF与文本读取LF不一致；工具修为固定LF，补回归测试，数字未改|`/tmp/zf_linear_p2b_check_2026_10_03.log`|
|同上加`--check`（最终）|FAIL(exit1)：确定性比较通过，仅保留073与v0合同失败|`/tmp/zf_linear_p2b_check_retry_2026_10_03.log`|
|输入/工具SHA与最终表B确定性诊断|首轮FAIL依赖旧CRLF检查结果；重验PASS（不把总体合同FAIL改成PASS）|`/tmp/zf_linear_p2b_deterministic_2026_10_03.log`、`/tmp/zf_linear_p2b_deterministic_retry_2026_10_03.log`|
|`python3 tools/validate_asset_pack.py`|FAIL：已知历史源素材缺失，不补造、不改索引|`/tmp/zf_linear_p2ab_validate_asset_pack_2026_10_03.log`|
|`python3 tools/validate_data.py`|PASS|`/tmp/zf_linear_p2ab_validate_data_2026_10_03.log`|
|`python3 tools/check_res_refs.py`|PASS|`/tmp/zf_linear_p2ab_check_res_refs_2026_10_03.log`|
|`python3 tools/check_level_pressure.py`|PASS|`/tmp/zf_linear_p2ab_check_level_pressure_2026_10_03.log`|
|`python3 tools/simulate_card_director.py`|PASS|`/tmp/zf_linear_p2ab_simulate_card_director_2026_10_03.log`|
|独立HOME `/opt/homebrew/bin/godot --headless --path /Users/gavin/work/zf-linear --quit`|PASS，exit0，SCRIPT ERROR/ERROR=0|`/tmp/zf_linear_p2ab_boot_2026_10_03.log`|
|独立HOME同上加`--script res://tools/m1_smoke_test.gd`|PASS，exit0，M1 smoke test passed，SCRIPT ERROR/ERROR=0|`/tmp/zf_linear_p2ab_smoke_2026_10_03.log`|
|Godot日志终态检查|首轮FAIL：smoke尚运行，未提前记通过；进程exit0后重验PASS|`/tmp/zf_linear_p2ab_godot_log_check_2026_10_03.log`、`/tmp/zf_linear_p2ab_godot_log_check_retry_2026_10_03.log`|
|最终冻结输入/夹具/受保护diff/临时夹具清理/新tar SHA|PASS|`/tmp/zf_linear_p2ab_frozen_final_2026_10_03.log`|
|交付版本 `python3 -m py_compile`（以上五个工具/测试文件）|PASS；固定LF修复后的最终版本|`/tmp/zf_linear_p2ab_compile_delivery_2026_10_04.log`|
|交付版本 `python3 tools/test_linear_power_program.py`|PASS，16项|`/tmp/zf_linear_p2a_unit_delivery_2026_10_04.log`|
|交付版本 `python3 tools/test_derive_recommended_power.py`|PASS，6项|`/tmp/zf_linear_p2b_unit_delivery_2026_10_04.log`|
|交付前 `git diff --check`|PASS；求解器自然退出后删除其空锁文件，不提交运行锁|`/tmp/zf_linear_p2ab_diff_delivery_2026_10_04.log`|
|交付最终守卫：分支、冻结数据/夹具SHA、阶段一至今全部data/gameplay/core/export preset diff、表B来源及旧/新tar SHA|PASS，红线零改动；073 FAIL原样保留|`/tmp/zf_linear_p2ab_delivery_guard_2026_10_04.log`|

本轮真实运行关卡：八墙关补测430局；其余91关只复用阶段一证据，不重跑。部分运行健康检查日志`/tmp/zf_linear_p2a_live_health_2026_10_03.log`、`/tmp/zf_linear_p2a_live_health_final_partial_2026_10_03.log`为PASS，但不代替最终证据核验。

**尚未执行（停工点B之前无权开工）**：2C生成器和游戏数据写入、相关新黄金锚点/派生夹具/报表/§40附录、990局新夹具、G3三点抽验、表C与资源写入、099普通/挑战及章节挑战复验、聚合RC/本地化门禁。旧数据冒烟PASS不代表这些新合同通过。

## Risks / 待 Fable 判定

1. **停工点B已到，表不能按“验收通过”写入**：请Fable核对拟合源方法，并明确处理073公式结果843与35%上限818.1之间的冲突（v0自身838也超限）。不自动裁到818、不改P*、不选有利种子、不偷偷改拟合权重或阈值。经核定表/合同后才能继续2C。
2. v0 CSV与明文同时拟合存在系统性差异，已经逐关解释及逆向诊断；仍需Fable确认原代码，不能把推断说成已证实源算法。
3. ±35%真实性合同不等于G3。48个低于通过端、29个不高于失败端的候选是风险，不是新运行结论；没有用改敌方数据来掩盖它们。
4. 七步上限、整数等级台阶、恰9/10端点保留；不宣称连续精确P*或所有构筑的全局最小战力。删失关不伪造P*。
5. validate_asset_pack历史素材缺失路径详见日志。未生成资产、未改资产索引。
6. 资源表C、终局挑战未执行；付费价格/权益、敌方数据、翻卡、gameplay/core、显示函数及三轴换算均不改。
