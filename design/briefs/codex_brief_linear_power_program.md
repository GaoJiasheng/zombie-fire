# Codex 执行文案 · 难度线性化与战力真实化(design/41,Owner 2026-10-03 批准)

## 0. 你要做什么,一句话

把"推荐战力"从模型推导改成**按真实运行结果反解**,再把金币/星/成长资源对齐到这条真实曲线;**不改敌方数据,不改翻卡节奏**。分四步交付,每步末停工交 Fable 核验,Owner 签字后再进下一步。

必读:`design/41_linear_progression_and_power_truth_plan.md`(目标与合同,§7 是 Owner 决议)、`design/40_campaign_difficulty_rebuild_and_power_ruler_v6_plan.md` §4.7/§8/§13(现行冻结项与门禁)、`design/audits/b2c_card_pacing_reconciliation_2026_10_02.md`(翻卡节奏现状)。

## 1. 工作方式与红线

- 在 worktree `/Users/gavin/work/zf-linear`、分支 `codex/linear-power` 上做;先 `cp -R /Users/gavin/work/zombie-fire/.godot /Users/gavin/work/zf-linear/`。不要在主工作树 `zombie-fire` 里改任何文件。
- **不改**:`gameplay/`、`core/`、`data/levels.json` 的 `waves/difficulty_coef/base_hp_ref`、`data/zombies.json`、`data/bosses.json`、`data/economy.json` 的 `card_offer_pacing`、任何 `design/4x_*.md` 正文(可追加附录)。
- **可改**(按阶段、按 Owner 签字表):`data/levels.json` 的 `clear_requirement`(经生成器)、`first_clear_reward`、`reward_gold_mult`;`data/economy.json` 的 `power_scale_v6`、`skill_base_xp_costs`、`sig_skill_xp_costs`、首通金币公式;`data/weapons.json` 升级成本/成长段;`data/campaign_pacing_targets.json` 的 `clear_requirement_mode`;`tools/`;`design/audits/`;`design/data/schema.md`、`naming_convention.md` 同步。
- 探针 `--jobs ≤ 6`;长跑用 `nohup`,日志到 `/tmp/zf_linear_*.log`;机器上没有 `timeout` 命令,别用。
- 每次 Godot 跑完检查日志 `SCRIPT ERROR`,数 0 才算过;冒烟用独立 HOME:`HOME=$(mktemp -d) godot --headless --path . --script res://tools/m1_smoke_test.gd`。
- 不 push、不打包、不上传 TestFlight、不改 `export_presets.cfg`。
- 报告格式固定:`Completed / Changed files / Verification(每条命令 pass/fail + 日志路径)/ Risks`。没跑过的不要写"通过";数据结论和工具产出分开写。

**唯一停工条件**:为了继续必须触碰红线里的东西,或某阶段结果与 §41 合同冲突无法自行判定——停下写清楚,交 Fable。

## 2. 阶段一 · 工具与真实通关线(交付物:T1/T2/T3 + 全量 P* 数据)

### T1 `tools/solve_runtime_clear_lines.py`
目的:每关找"十种子固定帧下仍 ≥9/10 通关的最弱构筑",得到真实通关线 P*(L)、R*(L)。

- 起点:`design/audits/campaign_progression_fixture_builds.json` 各关 `build`。
- 削弱:对 `character_level / weapon_level / armor_level / chip_level / pet_level / signature_level / skill_base_levels` 统一乘比例 s(round,最小 1/0)。战力用 `tools/power_ruler_model.power_for_build(level, contract, build, characters, weapons, armors, chips, pets, skills, bosses, economy)`(用法见 `tools/check_clear_requirements.py` 的 anchors 段),R(s)=power/recommended。对 s 二分:初始 [0.3, 1.0],直到 R 区间宽 ≤0.02 或 7 步。
- 每步生成只含该关的临时夹具 `design/audits/_tmp_clear_line_<level>_<step>.json`,调用:
  `python3 tools/run_frontline_sweep.py --levels <L> --seeds 1103,2207,3301,4409,5513,6637,7741,8849,9901,10903 --profile tier_b --card-policy v2 --accel 60 --jobs <N> --process-timeout 360 --fixture res://design/audits/_tmp_clear_line_<L>_<step>.json --output /tmp/…json`
  判据 `victory` ≥9/10。结束后删除临时夹具。
- 输出 `design/audits/runtime_clear_lines_<YYYY_MM_DD>.json`:顶层 `combat_input_fingerprint`(调 `tools/free_side_fingerprint.py`,五段)、`fixture_sha256`、`git_head`、`seeds`;每关 `level, recommended, p_star, r_star, build_star, bracket:[r_fail, r_pass], steps:[{scale, power, R, wins, base_median, elapsed_median}]`。
- 功能:`--levels` 逗号列表、`--resume`(跳过已完成关,中途断电可续)、`--jobs`。单关异常不拖垮全体,记录到 `errors`。
- 验收顺序:先 `--levels 5,30,65,99`,对照 Fable 2026-10-02 手工探底(R* ≈ 1.06 / 0.92 / 0.82 / 0.61,允许 ±0.1;原始数据 `/tmp/wip_gate/weak_*.json` 若已不在,以本次为准并注明)。一致后全量 1–99 过夜跑(约 6000 局、9 小时)。

### T2 `tools/audit_progression_linearity.py`
目的:design/41 §1 四条合同的度量与门禁。输入:levels/economy/weapons/skills、T1 JSON、`design/audits/b2b_star_table_old_to_new.csv`。
输出 `design/audits/progression_linearity_<date>.md`(+同名 JSON):
1. 逐关增幅表:推荐值、P*、`difficulty_coef`、敌方总血量(用 `tools/simulate_balance.level_enemy_hp_split`)。**按章节(每 10 关)拟合几何斜率**,列出各章斜率、章内偏离 >3pp 的关、Boss 关台阶幅度。
2. 资源曲线:首通金币(`first_clear_gold_base + per_level×L` 与 `first_clear_reward`)、`reward_gold_mult`、星星解锁门槛(在 `data/` 里 grep `star` 找到实际门槛字段,写明来源)、武器升级成本/成长、技能经验成本;各曲线对 P* 曲线的相关系数与逐关增幅差。
3. R→通关率:用 T1 全部 steps 拟合(按章节分组)R 与通过率的关系;给出 R=0.85/1.00/1.15 的预测通过率及与合同(3–7/≥9/10)的偏差。
4. 悬崖:相邻关 P* 增幅 >15%(Boss 边 >25%)或"上关 10/10、下关 ≤3/10"。
`--check` 模式阈值放文件顶部常量(章节斜率偏离 3pp、相关 ≥0.98、Boss 台阶 ≤+10pp 之外另记)。验收:对当前数据必须复现已知事实——ch2 推荐值偏低、035 偏高、060–099 偏高 12–40%。

### T3 进度闭环模拟(扩展 `tools/audit_campaign_frontline.py --closure-report`)
只拿 3★ 首通奖励、不刷关、按现有升级优先级花钱、技能经验按 `skill_base_xp_costs`、武器 50 级封顶;逐关输出累计金币/已购升级/构筑战力/推荐值/R(L),以及首次 R<0.95 的关、要重复刷几次 3★ 才回到 R≥1。输出 `design/audits/progression_closure_<date>.md`+JSON。不得改数据让曲线好看。

**阶段一停工交付**:T1 全量 JSON、T2/T3 报告、三份工具的 `--help`、`python3 -m py_compile` 结果。Fable 据此与 Owner 定两张表:章节斜率/推荐值表(签字点 B)、资源曲线表(签字点 C)。

## 3. 阶段二 · 推荐值重标管线(签字点 B 后开工)

- `data/campaign_pacing_targets.json`:新增 `clear_requirement_mode = "runtime_solved"`,所有章节切到该模式;保留旧模式代码路径。
- `tools/generate_clear_requirements.py`:`runtime_solved` 读取 Fable 提供的批准表 `design/audits/recommended_power_table_<date>.json`(逐关推荐值,已按章节斜率与 Boss 台阶平滑),写 `clear_requirement.power_contract.recommended_power` 及派生字段;`economy.power_scale_v6` 显示函数 P(g) 不变。生成器连跑两次 `git diff` 必须为零。
- 同步黄金值:`tools/check_clear_requirements.py`、`tools/test_power_scale_v6.py`(080/099 锚点、R 走廊断言)、`tools/m1_smoke_test.gd` 的 `_verify_recommended_power_calibration`(L001/050/080/099 推荐值与 Owner 构筑 R)。只改数字,不删断言;每处改动注释写明"2026-10 runtime_solved 重标"。
- 重生成参考夹具:`python3 tools/audit_campaign_frontline.py --write`;刷新派生报表:`report_fire_rate_tier_comparison.py --write`、`report_frontline_calibration.py --write`、`generate_weapon_power_profiles.py`、`audit_free_elemental_weapons.py --write`。
- 验收:`check_clear_requirements.py`、`test_power_scale_v6.py`、`check_campaign_pacing_contract.py`、全部 `--check` 派生报表、独立 HOME 冒烟、`ZOMBIE_FIRE_SKIP_WINDOWED_VISUALS=1 python3 tools/check_release_candidate.py` 全绿;再跑新夹具 99×10(`run_frontline_sweep.py`,输出到 `design/audits/b2c_main_runtime_solved_001_099_ten_seed_<date>.json`),并按 T1 方法在 R=0.85/1.00/1.15 各抽 10 关验证预测合同。
- design/40 追加 §14:解冻 v5 `min_output` 的原因、新模式、锚点变化;ch6 哈希、095/080/059 例外逐条写明"重钉"或"废止"。

## 4. 阶段三 · 资源线性化(签字点 C 后开工)

按 Fable 提供的批准表 `design/audits/resource_curve_table_<date>.json` 改:`first_clear_reward`/`reward_gold_mult`、星星解锁门槛、武器升级成本或成长段、`skill_base_xp_costs`/`sig_skill_xp_costs`。不新增货币,不改任何付费商品价格、权益、`premium_*`。改完跑 T3 闭环:全程 R(L) ∈ [0.95, 1.10];跑 T2 `--check`;`validate_data.py`、`check_localization.py`(若有文案)、冒烟、聚合门禁;`design/data/schema.md` 同步字段说明。

## 5. 阶段四 · 终局与挑战复验

- 099 普通:免费满级参考构筑 ≥9/10;099 挑战:免费满级 ≤3/10,黄金法则满级 6–9/10(用 `design/audits/challenge_reference_fixture_builds.json` 与 `challenge_free_counterexample_fixture_builds.json`,`run_frontline_sweep.py --challenge`)。
- 挑战章节代表点胜率带(ch1–6 70–100%,ch7–10 60–90%)按 `design/audits/challenge_curve_redesign_plan.md` 的口径复验;不达标只调 `data/challenges.json.curve`,并出新旧对照表交 Fable。

## 6. 交付清单(每阶段)

1. 分支最新 commit 哈希(不 push)。
2. `Completed / Changed files / Verification / Risks` 报告,放 `design/audits/linear_power_<阶段>_<date>/报告.md`,所有日志路径可查。
3. 数据改动附"按哪张批准表、哪一行"的对应关系。
4. 任何与 design/41 合同冲突的发现,单独列"待 Owner 判定",不要自行放宽阈值。
