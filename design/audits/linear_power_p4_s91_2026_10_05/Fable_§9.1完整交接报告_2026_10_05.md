状态：COMPLETED；§9.1运行时合同 PASS；采用受测曲线

# design/41 §9.1 第二轮签字后完整交接报告（2026-10-05）

## Completed · 工具与执行

- 工作树`/Users/gavin/work/zf-linear`，分支`codex/linear-power`；先merge main读取§9.1。
- 黄金律099≥6/10，无上限；Boss中位150–220秒INFO；免费099≤3/10；ch7–10每章18–27/30。
- 压力指数61–99（含099）可调，有限[0,1]且和1；K单调smoothstep，相邻≤18%，上限8，ch1–6展开完全冻结。
- 新挑战探针720秒，普通默认540不变；720秒未结束者按未通关单列，缺种子/进程错误不得算未通关；旧540未结束组不复用。
- 固定十种子1103/2207/3301/4409/5513/6637/7741/8849/9901/10903，固定帧1/60、tier_b/v2、每轮≤320、jobs6、nohup宿主保活。
- 本轮完成5轮，新原生尝试370局，SCRIPT ERROR 0，720秒未通关3局。
- 已完整结束的旧组仅按完全相同展开规则复用，不挑种子/最佳组；全部候选和失败证据独立保留。
- 最终门禁权威记录：`verification_accepted_retry.json`；16条实际命令全部PASS。历史首次FAIL与后续复跑均保留。
- 仅允许data/challenges.json.curve产品数值修改；普通敌方/gameplay/core/翻卡/付费属性/资源/P(g)/F(g)/已批星表不改。Owner签字星表由Fable合并时替换，本分支不代执行。

## Completed · 数据结论

|章|胜/30|合同|结果|
|---|---:|---|---|
|1|30|[21, 30]|PASS|
|2|30|[21, 30]|PASS|
|3|30|[21, 30]|PASS|
|4|30|[21, 30]|PASS|
|5|30|[21, 30]|PASS|
|6|29|[21, 30]|PASS|
|7|27|[18, 27]|PASS|
|8|20|[18, 27]|PASS|
|9|27|[18, 27]|PASS|
|10|26|[18, 27]|PASS|

- 099黄金律：9/10；Boss胜局中位282.35秒，INFO。
- 099免费：0/10。
- 普通099免费MAX既有10/10、076炼狱9/10（4409败）、095普通黄金律10/10证据保持；不冒称本轮重复实跑。
- G3硬点十关94/100保持PASS，另两点INFO；资源维持现状，G1下限0失败/10次回刷保持。

### 各轮与最接近三个候选

|轮|新尝试|章节7/8/9/10胜数|免费099|黄金律099|偏差胜数|状态|
|---|---:|---|---:|---:|---:|---|
|1|90|29/20/30/25|0|9|5|FAIL|
|2|50|29/20/30/25|0|9|5|FAIL|
|3|50|29/20/29/25|0|9|4|FAIL|
|4|100|27/20/30/27|0|9|3|FAIL|
|5|80|27/20/27/26|0|9|0|PASS|

- 候选curve SHA `b4ff54f41deee9cc14519a8c3067ebb6dfdf26fea90e13e778bc5c62b7f325fb`，距所有硬合同带的总胜数偏差0；章节失败[]；曲线保全在对应round候选与contracts JSON。
  - K锚点：`[{"level": 1, "k": 1.25}, {"level": 55, "k": 1.35}, {"level": 60, "k": 1.8}, {"level": 62, "k": 2.44}, {"level": 66, "k": 3.8}, {"level": 70, "k": 5.2}, {"level": 80, "k": 5.21}, {"level": 83, "k": 6.8}, {"level": 90, "k": 7.99}, {"level": 99, "k": 8.0}]`
  - 压力指数锚点：`[{"level": 1, "speed": 0.2, "breach": 0.4, "mechanic": 0.4}, {"level": 60, "speed": 0.2, "breach": 0.4, "mechanic": 0.4}, {"level": 65, "speed": 0.1, "breach": 0.15, "mechanic": 0.75}, {"level": 70, "speed": 0.7, "breach": 0.3, "mechanic": 0.0}, {"level": 71, "speed": 0.1, "breach": 0.45, "mechanic": 0.45}, {"level": 80, "speed": 0.1, "breach": 0.45, "mechanic": 0.45}, {"level": 81, "speed": 0.0, "breach": 0.9, "mechanic": 0.1}, {"level": 90, "speed": 0.0, "breach": 0.9, "mechanic": 0.1}, {"level": 91, "speed": 0.9, "breach": 0.05, "mechanic": 0.05}, {"level": 99, "speed": 1.0, "breach": 0.0, "mechanic": 0.0}]`
  - 偏差：ch7=27/30（合同[18, 27]）；ch8=20/30（合同[18, 27]）；ch9=27/30（合同[18, 27]）；ch10=26/30（合同[18, 27]）；免费099=0/10（≤3）；黄金律099=9/10（≥6）。

- 候选curve SHA `5ac69467339ab32bdf2497fdf62aaf8c4c05f60367687e5c655610c71c723268`，距所有硬合同带的总胜数偏差3；章节失败[9]；曲线保全在对应round候选与contracts JSON。
  - K锚点：`[{"level": 1, "k": 1.25}, {"level": 55, "k": 1.35}, {"level": 60, "k": 1.8}, {"level": 62, "k": 2.44}, {"level": 66, "k": 3.8}, {"level": 70, "k": 5.2}, {"level": 80, "k": 5.3}, {"level": 90, "k": 7.8}, {"level": 99, "k": 8.0}]`
  - 压力指数锚点：`[{"level": 1, "speed": 0.2, "breach": 0.4, "mechanic": 0.4}, {"level": 60, "speed": 0.2, "breach": 0.4, "mechanic": 0.4}, {"level": 65, "speed": 0.1, "breach": 0.15, "mechanic": 0.75}, {"level": 70, "speed": 0.7, "breach": 0.3, "mechanic": 0.0}, {"level": 71, "speed": 0.1, "breach": 0.45, "mechanic": 0.45}, {"level": 80, "speed": 0.1, "breach": 0.45, "mechanic": 0.45}, {"level": 81, "speed": 0.0, "breach": 0.9, "mechanic": 0.1}, {"level": 90, "speed": 0.5, "breach": 0.5, "mechanic": 0.0}, {"level": 91, "speed": 0.9, "breach": 0.05, "mechanic": 0.05}, {"level": 99, "speed": 1.0, "breach": 0.0, "mechanic": 0.0}]`
  - 偏差：ch7=27/30（合同[18, 27]）；ch8=20/30（合同[18, 27]）；ch9=30/30（合同[18, 27]）；ch10=27/30（合同[18, 27]）；免费099=0/10（≤3）；黄金律099=9/10（≥6）。

- 候选curve SHA `fbd825489d7183756fb2fa7aad375d3cbd56c92c18f74bf0bfae188eec58856b`，距所有硬合同带的总胜数偏差4；章节失败[7, 9]；曲线保全在对应round候选与contracts JSON。
  - K锚点：`[{"level": 1, "k": 1.25}, {"level": 55, "k": 1.35}, {"level": 60, "k": 1.8}, {"level": 70, "k": 5.1}, {"level": 80, "k": 5.3}, {"level": 90, "k": 6.5}, {"level": 99, "k": 8.0}]`
  - 压力指数锚点：`[{"level": 1, "speed": 0.2, "breach": 0.4, "mechanic": 0.4}, {"level": 60, "speed": 0.2, "breach": 0.4, "mechanic": 0.4}, {"level": 65, "speed": 0.1, "breach": 0.15, "mechanic": 0.75}, {"level": 70, "speed": 0.0, "breach": 0.9, "mechanic": 0.1}, {"level": 71, "speed": 0.1, "breach": 0.45, "mechanic": 0.45}, {"level": 80, "speed": 0.1, "breach": 0.45, "mechanic": 0.45}, {"level": 81, "speed": 0.0, "breach": 0.9, "mechanic": 0.1}, {"level": 90, "speed": 0.0, "breach": 0.9, "mechanic": 0.1}, {"level": 91, "speed": 0.9, "breach": 0.05, "mechanic": 0.05}, {"level": 99, "speed": 1.0, "breach": 0.0, "mechanic": 0.0}]`
  - 偏差：ch7=29/30（合同[18, 27]）；ch8=20/30（合同[18, 27]）；ch9=29/30（合同[18, 27]）；ch10=25/30（合同[18, 27]）；免费099=0/10（≤3）；黄金律099=9/10（≥6）。

### 采用曲线的逐关证据与未通关种子

|关|胜/10|真实/计入未通关种子|720秒未结束|来源|
|---|---:|---|---|---|
|001|10|[]|[]|first-round immutable evidence|
|005|10|[]|[]|first-round immutable evidence|
|010|10|[]|[]|first-round immutable evidence|
|011|10|[]|[]|first-round immutable evidence|
|015|10|[]|[]|first-round immutable evidence|
|020|10|[]|[]|first-round immutable evidence|
|021|10|[]|[]|first-round immutable evidence|
|025|10|[]|[]|first-round immutable evidence|
|030|10|[]|[]|first-round immutable evidence|
|031|10|[]|[]|first-round immutable evidence|
|035|10|[]|[]|first-round immutable evidence|
|040|10|[]|[]|first-round immutable evidence|
|041|10|[]|[]|first-round immutable evidence|
|045|10|[]|[]|first-round immutable evidence|
|050|10|[]|[]|first-round immutable evidence|
|051|10|[]|[]|first-round immutable evidence|
|055|10|[]|[]|first-round immutable evidence|
|060|9|[10903]|[]|first-round immutable evidence|
|061|10|[]|[]|s91_r04_reps|
|065|10|[]|[]|s91_r04_reps|
|070|7|[3301, 4409, 7741]|[]|s91_r04_reps|
|071|10|[]|[]|s91_r05_reps|
|075|3|[3301, 4409, 5513, 6637, 7741, 9901, 10903]|[]|s91_r05_reps|
|080|7|[3301, 4409, 7741]|[]|s91_r05_reps|
|081|10|[]|[]|s91_r05_reps|
|085|10|[]|[]|s91_r05_reps|
|090|7|[1103, 3301, 4409]|[]|s91_r05_reps|
|091|10|[]|[]|s91_r05_reps|
|095|7|[6637, 8849, 9901]|[9901]|s91_r05_reps|
|099|9|[9901]|[]|r03_gold099|

## Changed files

- `"design/audits/linear_power_p4_s91_2026_10_05/Fable_\302\2479.1\345\256\214\346\225\264\344\272\244\346\216\245\346\212\245\345\221\212_2026_10_05.md"`
- `"design/audits/linear_power_p4_s91_2026_10_05/\346\212\245\345\221\212.md"`
- `data/challenges.json`
- `design/data/schema.md`
- `design/m1_implementation_progress.md`
- `design/m1_todo.md`
- `tools/archive_linear_power_s91.py`
- `tools/challenge_curve.py`
- `tools/check_challenge_curve_runtime.py`
- `tools/check_linear_power_s9.py`
- `tools/check_linear_power_s91_runtime.py`
- `tools/frontline_runtime_probe.gd`
- `tools/report_linear_power_s9.py`
- `tools/run_frontline_sweep.py`
- `tools/run_linear_power_s9.py`
- `tools/run_linear_power_s91.py`
- `tools/test_linear_power_s9.py`
- `tools/test_linear_power_s91.py`
- `tools/validate_data.py`
- `tools/write_linear_power_s91_handoff.py`
- 审计目录`design/audits/linear_power_p4_s91_2026_10_05/`：候选、完整命令、输入SHA、源JSON、独立门禁、逐关表、交接报告。
- 数据变更依据：Owner 2026-10-05 design/41 §9.1；采用轮的candidate/plan/contracts逐关可查，不采用其他曲线或资源表。

### 全99关新旧K与三指数对照

|关|旧K|新K|旧S/B/M|新S/B/M|
|---|---:|---:|---|---|
|001|1.250000|1.250000|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|002|1.250102|1.250102|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|003|1.250401|1.250401|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|004|1.250892|1.250892|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|005|1.251565|1.251565|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|006|1.252413|1.252413|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|007|1.253429|1.253429|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|008|1.254605|1.254605|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|009|1.255934|1.255934|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|010|1.257407|1.257407|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|011|1.259018|1.259018|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|012|1.260758|1.260758|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|013|1.262620|1.262620|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|014|1.264596|1.264596|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|015|1.266679|1.266679|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|016|1.268861|1.268861|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|017|1.271135|1.271135|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|018|1.273492|1.273492|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|019|1.275926|1.275926|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|020|1.278428|1.278428|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|021|1.280991|1.280991|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|022|1.283608|1.283608|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|023|1.286270|1.286270|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|024|1.288970|1.288970|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|025|1.291701|1.291701|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|026|1.294455|1.294455|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|027|1.297223|1.297223|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|028|1.300000|1.300000|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|029|1.302777|1.302777|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|030|1.305545|1.305545|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|031|1.308299|1.308299|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|032|1.311030|1.311030|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|033|1.313730|1.313730|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|034|1.316392|1.316392|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|035|1.319009|1.319009|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|036|1.321572|1.321572|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|037|1.324074|1.324074|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|038|1.326508|1.326508|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|039|1.328865|1.328865|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|040|1.331139|1.331139|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|041|1.333321|1.333321|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|042|1.335404|1.335404|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|043|1.337380|1.337380|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|044|1.339242|1.339242|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|045|1.340982|1.340982|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|046|1.342593|1.342593|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|047|1.344066|1.344066|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|048|1.345395|1.345395|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|049|1.346571|1.346571|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|050|1.347587|1.347587|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|051|1.348435|1.348435|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|052|1.349108|1.349108|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|053|1.349599|1.349599|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|054|1.349898|1.349898|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|055|1.350000|1.350000|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|056|1.396800|1.396800|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|057|1.508400|1.508400|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|058|1.641600|1.641600|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|059|1.753200|1.753200|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|060|1.800000|1.800000|0.200000/0.400000/0.400000|0.200000/0.400000/0.400000|
|061|1.924800|2.120000|0.260000/0.370000/0.370000|0.180000/0.350000/0.470000|
|062|2.222400|2.440000|0.320000/0.340000/0.340000|0.160000/0.300000/0.540000|
|063|2.577600|2.652500|0.380000/0.310000/0.310000|0.140000/0.250000/0.610000|
|064|2.875200|3.120000|0.440000/0.280000/0.280000|0.120000/0.200000/0.680000|
|065|3.000000|3.587500|0.500000/0.250000/0.250000|0.100000/0.150000/0.750000|
|066|3.104000|3.800000|0.560000/0.220000/0.220000|0.220000/0.180000/0.600000|
|067|3.352000|4.018750|0.620000/0.190000/0.190000|0.340000/0.210000/0.450000|
|068|3.648000|4.500000|0.680000/0.160000/0.160000|0.460000/0.240000/0.300000|
|069|3.896000|4.981250|0.740000/0.130000/0.130000|0.580000/0.270000/0.150000|
|070|4.000000|5.200000|0.800000/0.100000/0.100000|0.700000/0.300000/0.000000|
|071|4.005600|5.200280|0.100000/0.450000/0.450000|0.100000/0.450000/0.450000|
|072|4.020800|5.201040|0.100000/0.450000/0.450000|0.100000/0.450000/0.450000|
|073|4.043200|5.202160|0.100000/0.450000/0.450000|0.100000/0.450000/0.450000|
|074|4.070400|5.203520|0.100000/0.450000/0.450000|0.100000/0.450000/0.450000|
|075|4.100000|5.205000|0.100000/0.450000/0.450000|0.100000/0.450000/0.450000|
|076|4.129600|5.206480|0.100000/0.450000/0.450000|0.100000/0.450000/0.450000|
|077|4.156800|5.207840|0.100000/0.450000/0.450000|0.100000/0.450000/0.450000|
|078|4.179200|5.208960|0.100000/0.450000/0.450000|0.100000/0.450000/0.450000|
|079|4.194400|5.209720|0.100000/0.450000/0.450000|0.100000/0.450000/0.450000|
|080|4.200000|5.210000|0.100000/0.450000/0.450000|0.100000/0.450000/0.450000|
|081|4.219600|5.622222|0.000000/0.800000/0.200000|0.000000/0.900000/0.100000|
|082|4.272800|6.387778|0.000000/0.800000/0.200000|0.000000/0.900000/0.100000|
|083|4.351200|6.800000|0.000000/0.800000/0.200000|0.000000/0.900000/0.100000|
|084|4.446400|6.865918|0.000000/0.800000/0.200000|0.000000/0.900000/0.100000|
|085|4.550000|7.035918|0.000000/0.800000/0.200000|0.000000/0.900000/0.100000|
|086|4.653600|7.268367|0.000000/0.800000/0.200000|0.000000/0.900000/0.100000|
|087|4.748800|7.521633|0.000000/0.800000/0.200000|0.000000/0.900000/0.100000|
|088|4.827200|7.754082|0.000000/0.800000/0.200000|0.000000/0.900000/0.100000|
|089|4.880400|7.924082|0.000000/0.800000/0.200000|0.000000/0.900000/0.100000|
|090|4.900000|7.990000|0.000000/0.800000/0.200000|0.000000/0.900000/0.100000|
|091|4.903429|7.990343|0.900000/0.050000/0.050000|0.900000/0.050000/0.050000|
|092|4.912620|7.991262|0.912500/0.043750/0.043750|0.912500/0.043750/0.043750|
|093|4.925926|7.992593|0.925000/0.037500/0.037500|0.925000/0.037500/0.037500|
|094|4.941701|7.994170|0.937500/0.031250/0.031250|0.937500/0.031250/0.031250|
|095|4.958299|7.995830|0.950000/0.025000/0.025000|0.950000/0.025000/0.025000|
|096|4.974074|7.997407|0.962500/0.018750/0.018750|0.962500/0.018750/0.018750|
|097|4.987380|7.998738|0.975000/0.012500/0.012500|0.975000/0.012500/0.012500|
|098|4.996571|7.999657|0.987500/0.006250/0.006250|0.987500/0.006250/0.006250|
|099|5.000000|8.000000|1.000000/0.000000/0.000000|1.000000/0.000000/0.000000|

## Verification · 实际命令、结果与日志

|命令|结果|日志|
|---|---|---|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 -u tools/run_frontline_sweep.py --levels 61,65,70,71,81,85,90,91,95 --seeds 1103,2207,3301,4409,5513,6637,7741,8849,9901,10903 --profile tier_b --card-policy v2 --accel 60 --jobs 6 --logic-limit 720 --process-timeout 720 --fixture res://design/audits/challenge_reference_fixture_builds.json --output /Users/gavin/work/zf-linear/design/audits/linear_power_p4_s91_2026_10_05/s91_r01_reps.json --log-dir /tmp/zf_linear_s91_s91_r01_reps_2026_10_05 --challenge`|exit0；原始证据完整；运行时胜率见各轮合同|`/tmp/zf_linear_s91_s91_r01_reps_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 -u tools/run_frontline_sweep.py --levels 61,65,81,85,90 --seeds 1103,2207,3301,4409,5513,6637,7741,8849,9901,10903 --profile tier_b --card-policy v2 --accel 60 --jobs 6 --logic-limit 720 --process-timeout 720 --fixture res://design/audits/challenge_reference_fixture_builds.json --output /Users/gavin/work/zf-linear/design/audits/linear_power_p4_s91_2026_10_05/s91_r02_reps.json --log-dir /tmp/zf_linear_s91_s91_r02_reps_2026_10_05 --challenge`|exit0；原始证据完整；运行时胜率见各轮合同|`/tmp/zf_linear_s91_s91_r02_reps_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 -u tools/run_frontline_sweep.py --levels 70,71,81,85,90 --seeds 1103,2207,3301,4409,5513,6637,7741,8849,9901,10903 --profile tier_b --card-policy v2 --accel 60 --jobs 6 --logic-limit 720 --process-timeout 720 --fixture res://design/audits/challenge_reference_fixture_builds.json --output /Users/gavin/work/zf-linear/design/audits/linear_power_p4_s91_2026_10_05/s91_r03_reps.json --log-dir /tmp/zf_linear_s91_s91_r03_reps_2026_10_05 --challenge`|exit0；原始证据完整；运行时胜率见各轮合同|`/tmp/zf_linear_s91_s91_r03_reps_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 -u tools/run_frontline_sweep.py --levels 61,65,70,71,75,81,85,90,91,95 --seeds 1103,2207,3301,4409,5513,6637,7741,8849,9901,10903 --profile tier_b --card-policy v2 --accel 60 --jobs 6 --logic-limit 720 --process-timeout 720 --fixture res://design/audits/challenge_reference_fixture_builds.json --output /Users/gavin/work/zf-linear/design/audits/linear_power_p4_s91_2026_10_05/s91_r04_reps.json --log-dir /tmp/zf_linear_s91_s91_r04_reps_2026_10_05 --challenge`|exit0；原始证据完整；运行时胜率见各轮合同|`/tmp/zf_linear_s91_s91_r04_reps_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 -u tools/run_frontline_sweep.py --levels 71,75,80,81,85,90,91,95 --seeds 1103,2207,3301,4409,5513,6637,7741,8849,9901,10903 --profile tier_b --card-policy v2 --accel 60 --jobs 6 --logic-limit 720 --process-timeout 720 --fixture res://design/audits/challenge_reference_fixture_builds.json --output /Users/gavin/work/zf-linear/design/audits/linear_power_p4_s91_2026_10_05/s91_r05_reps.json --log-dir /tmp/zf_linear_s91_s91_r05_reps_2026_10_05 --challenge`|exit0；原始证据完整；运行时胜率见各轮合同|`/tmp/zf_linear_s91_s91_r05_reps_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 -m py_compile tools/run_linear_power_s91.py tools/check_linear_power_s91_runtime.py tools/write_linear_power_s91_handoff.py tools/archive_linear_power_s91.py tools/challenge_curve.py tools/report_linear_power_s9.py tools/run_frontline_sweep.py tools/check_challenge_curve_runtime.py`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_compile_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 -m unittest discover -s tools -p test_linear_power_s91.py -v`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_s91_unit_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 tools/test_frontline_sweep_metadata.py`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_sweep_metadata_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 tools/check_challenge_curve_runtime.py --output /Users/gavin/work/zf-linear/design/audits/linear_power_p4_s91_2026_10_05/verification_accepted_challenge_runtime.json`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_challenge_runtime_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 tools/validate_asset_pack.py`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_assets_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 -m unittest discover -s tools -p test_linear_power_s9.py -v`|FAIL（exit 1）|`/tmp/zf_linear_s91_final_accepted_s9_unit_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 -m unittest discover -s tools -p test_linear_power_program.py -v`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_linear_unit_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 -m unittest discover -s tools -p test_resource_curves.py -v`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_resource_unit_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 -m unittest discover -s tools -p test_linear_power_acceptance.py -v`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_ray_unit_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 tools/validate_data.py`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_validate_data_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 tools/check_res_refs.py`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_refs_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 tools/check_level_pressure.py`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_pressure_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 tools/simulate_card_director.py`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_cards_2026_10_05.log`|
|`/opt/homebrew/bin/godot --headless --path . --quit`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_boot_2026_10_05.log`|
|`/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_smoke_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 tools/check_release_candidate.py`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_release_candidate_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 -m py_compile tools/run_linear_power_s91.py tools/check_linear_power_s91_runtime.py tools/write_linear_power_s91_handoff.py tools/archive_linear_power_s91.py tools/challenge_curve.py tools/report_linear_power_s9.py tools/run_frontline_sweep.py tools/check_challenge_curve_runtime.py`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_retry_compile_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 -m unittest discover -s tools -p test_linear_power_s91.py -v`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_retry_s91_unit_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 tools/test_frontline_sweep_metadata.py`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_retry_sweep_metadata_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 tools/check_challenge_curve_runtime.py --output /Users/gavin/work/zf-linear/design/audits/linear_power_p4_s91_2026_10_05/verification_accepted_retry_challenge_runtime.json`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_retry_challenge_runtime_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 tools/validate_asset_pack.py`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_retry_assets_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 -m unittest discover -s tools -p test_linear_power_s9.py -v`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_retry_s9_unit_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 -m unittest discover -s tools -p test_linear_power_program.py -v`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_retry_linear_unit_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 -m unittest discover -s tools -p test_resource_curves.py -v`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_retry_resource_unit_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 -m unittest discover -s tools -p test_linear_power_acceptance.py -v`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_retry_ray_unit_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 tools/validate_data.py`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_retry_validate_data_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 tools/check_res_refs.py`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_retry_refs_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 tools/check_level_pressure.py`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_retry_pressure_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 tools/simulate_card_director.py`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_retry_cards_2026_10_05.log`|
|`/opt/homebrew/bin/godot --headless --path . --quit`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_retry_boot_2026_10_05.log`|
|`/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_retry_smoke_2026_10_05.log`|
|`/Applications/Xcode-26.4.1.app/Contents/Developer/usr/bin/python3 tools/check_release_candidate.py`|PASS（exit 0）|`/tmp/zf_linear_s91_final_accepted_retry_release_candidate_2026_10_05.log`|
|`python3 tools/report_linear_power_s9.py --s91 --check --prefix adopted`|PASS（exit 0）|`/tmp/zf_linear_s91_adopted_contracts_2026_10_05.log`|
|`python3 tools/check_challenge_curve_runtime.py --s91-evidence design/audits/linear_power_p4_s91_2026_10_05/adopted_contracts.json --output design/audits/linear_power_p4_s91_2026_10_05/runtime_independent.json`|PASS（exit 0）|`/tmp/zf_linear_s91_runtime_independent_2026_10_05.log`|
|`python3 -c import json,hashlib,sys,subprocess;sys.path.insert(0,"tools");import run_linear_power_s9 as s;old=json.load(open(s.BASE));now=s.guard();a=json.load(open("design/audits/linear_power_p4_s91_2026_10_05/archive_record.json"));actual=hashlib.sha256(open(a["archive"],"rb").read()).hexdigest();assert actual==a["sha256"];branch=subprocess.check_output(["git","branch","--show-current"],text=True).strip();assert branch=="codex/linear-power";products=subprocess.check_output(["git","diff","--name-only","HEAD","--","data"],text=True).splitlines();assert products==["data/challenges.json"];assert subprocess.run(["git","diff","--check"]).returncode==0;print(json.dumps({"status":"PASS","branch":branch,"frozen_inputs":len(now),"changed_inputs":[p for p in now if old["input_sha256"][p]!=now[p]],"unchanged_protected_files":len(old["protected_sha256"]),"changed_product_files":products,"archive_sha256":actual,"archive_files":a["files"]},indent=2))`|PASS（exit 0）|`/tmp/zf_linear_s91_final_scope_2026_10_05.log`|
|`python3 tools/archive_linear_power_s91.py`|PASS（exit 0）|`/tmp/zf_linear_s91_archive_2026_10_05.log`|

### 筛选与诊断失败（保留，不冒称通过）

- FAIL in first final gate: the old prefix-invariance test unconditionally replaces K99 with 7, below the accepted K90=7.99, so its own fixture violates monotonicity. The test now varies K99 within the valid interval (K90,K99), retaining validate==[] and all 60 equality assertions. No product curve or contract threshold changed; a complete final rerun is required.；命令`python3 -m unittest discover -s tools -p test_linear_power_s9.py -v`；日志`/tmp/zf_linear_s91_final_accepted_s9_unit_2026_10_05.log`
- PASS: round 5 K080=5.21 static screen. Round 4 FAIL remains archived; no simulator assertion was removed or relaxed.；命令`python3 tools/simulate_balance.py --challenge`；日志`/tmp/zf_linear_s91_round05_static_screen_2026_10_05.log`
- FAIL: round 4 static screen reports L080 100% breach; native exact L080 at K=5.3 remains 7/10. Static leak product equals K because the exponents sum to 1. Read-only model calculation gives K080<1026/196.8=5.213414634146341 to pass. Preserve gate and test a permitted lower K080 instead of waiving the failure.；命令`python3 tools/simulate_balance.py --challenge`；日志`/tmp/zf_linear_s91_round04_static_screen_2026_10_05.log`
- FAIL: structural screen, L063→064 growth 18.245% exceeds 18%; candidate not written, zero native attempts；命令`python3 -u tools/run_linear_power_s91.py --round 4 --set-k 70=5.2 --set-k 90=7.8 --set-exponent 70=0.7,0.3,0 --set-exponent 90=0.5,0.5,0`；日志`/tmp/zf_linear_s91_round04_host_2026_10_05.log`；Preserved rejection, not a completed native iteration. Corrected round 4 adds smooth interpolation anchors L062/L066; no threshold changed.
- Safety review initially refused round 3 launch until round 2 exit was confirmed. Session 93680 returned exit 0; read-only ps showed no solver/probe; ROUND_RESULT and round_02_result.json were present. Only then started round 3. No duplicate launch.
- FAIL: sandbox blocked bytecode write to system cache; compilation retried successfully with PYTHONPYCACHEPREFIX=/tmp/zf_linear_s91_pycache. No product change.；命令`python3 -m py_compile tools/write_linear_power_s91_handoff.py tools/check_linear_power_s91_runtime.py tools/run_linear_power_s91.py`
- Exit 0 with zero discovered tests; NOT evidence of test PASS. Actual script python3 tools/test_frontline_sweep_metadata.py subsequently PASS.；命令`python3 -m unittest discover -s tools -p test_frontline_sweep_metadata.py -v`；日志`/tmp/zf_linear_s91_sweep_unit_initial_2026_10_05.log`

- 最终验证使用独立HOME/XDG，SOURCE_REFS_ROOT=/Users/gavin/work/zombie-fire仅只读历史源资料，SKIP_WINDOWED_VISUALS=1；不补造、不改索引、不跳过资产门禁。
- 本轮独立check_challenge_curve_runtime --s91-evidence逐组重数原始结果；不是拿旧990局挑战档案冒充新曲线。验证覆盖30代表关×10及免费099×10的选中证据，不称新全99挑战扫描。
- 聚合门禁通过不替代挑战实测；窗口视觉跳过不称真机/视觉验收。旧§9全部FAIL/540删失/素材路径FAIL原样保留，不反向删除。

## Risks / blockers

- 个别关可0/10或10/10，硬合同为每章三个代表点聚合；720秒未结束按签字口径计未通关，另列种子，不包装成游戏战败。
- Boss时长是信息项，超150–220秒照实报告；不调整游戏计时或玩家军械。
- 若十轮不收敛，候选未采用，最接近三组及偏差交Fable；不放宽阈值、不证明数学不可行。
- 无push/构建/应用打包/TestFlight；证据归档仅保全日志。最终commit另见交付记录；完成后停工交Fable。

## 证据归档

- 路径：`/Users/gavin/Desktop/zombiefire_evidence/linear_power_s91_2026_10_05.tar.gz`
- SHA256：`9ad50ec107bf52a3c6d78c291d30472065b5326128aee516adeb5d97bf778177`
- 966个文件逐SHA验证PASS；旧§9归档不覆盖。
