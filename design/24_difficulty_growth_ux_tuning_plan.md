# 24 · 难度与成长曲线 UX 调优方案（v2 — 含人物/技能/武器成长联动分析）

> 状态：分析完成，待实施。本文是"难度/成长/星级经济/武器技能生态"专项调优的唯一主方案。
> 分析基线：`main @ 49af2558`（Build 38 之后），`python3 tools/check_release_candidate.py` 全绿。
> v2 变更：新增第 1.5 节"难度到底是对着什么成长基线调的"、第 8-10 节（元素武器经济 / 技能生态 / 战力口径显示），
> 并给出 Phase 之间的依赖顺序。
> 实施要求：每个 Phase 内的"游戏改动 + 模拟器同步 + 校验同步 + UI 同步"必须在**同一个提交**里完成，
> 禁止只改游戏不改模拟器（本次分析发现的最大问题正是两者各自为政）。

## 冷启动执行须知（新 session 从这里开始）

1. 先读仓库根目录 `AGENTS.md`（黄金规则、数据驱动约定、文档更新义务都在那里，本文不重复）。
2. 开工第一步：`python3 tools/check_release_candidate.py` 确认基线全绿，绿了才动手；不绿先停下报告。
3. **本文所有行号以 commit `ba4164fc` 为锚点**，Codex 会并行提交、行号必然漂移——
   永远用文中引用的代码片段/函数名重新定位（如搜 `hp_ratio >= 1.0`、`func get_loadout_power`、
   `offense - 1.0) * 0.82`），行号只当导航提示。定位结果与文中描述对不上时，先停下来对照
   `git log` 确认该处是否已被并行改动，不许凭猜施工。
4. headless 验证脚本的写法模板：抄 `tools/m1_smoke_test.gd` 的 Router stub 模式
   （自建 stub router 接住 `finish_level` 的 result payload），或抄其中直接 instantiate
   `battle.tscn` + `setup()` 的段落。一次性验证脚本放 scratchpad，验完删除，不许提交进 tools/。
5. 每完成一个 Phase：按 AGENTS.md 义务更新 `design/m1_todo.md` 和 `design/m1_implementation_progress.md`，
   并在本文附录填上该 Phase 的实测数据。

---

## 0. 分析结论摘要（按 UX 影响排序）

| # | 问题 | 量化证据 | 严重度 |
|---|------|---------|--------|
| A | **游戏的星级判定与整个平衡管线用的判定不是同一套**：游戏要求"结算时基地满血"才给3星，而调参用的模拟器认为"漏怪伤害≤40%"就算3星。全部99关都是照模拟器的口径调的 | battle.gd:8161 vs tools/simulate_balance.py:377-383 | P0 |
| B | Boss 关按"生存海绵"设计（HP 最高 56 倍 ramp），模型自己算出的最优构筑漏怪也高达 66–100%——叠加 A，**每5关一个的 Boss 关几乎永远只有1星** | simulate_balance 输出：所有 Boss 关 leak 66–100%，标注1★ | P0 |
| C | **星级经济供需倒挂**：全图鉴解锁需 318 星；当前判定下战役+挑战的现实可得星约 250 上下（模型估算），全收集在数学上接近不可能 | 解锁总价：角色38+武器75+护甲60+芯片80+宠物65=318；战役理论上限297 | P0 |
| D | 模拟器 Boss 关"带技能通关时间"在 50–65 关区间输出退化值（2.0s/10.1s/16.0s/19.2s），**50–70 关的 Boss 数值实际上是对着坏数字调出来的** | simulate_balance 输出 t_ws 列；"Levels < 30s: 5" | P0（工具） |
| E | 星级规则对玩家完全不可见：没有任何 UI 告诉玩家 2★/3★ 的条件是什么 | result.gd / loadout.gd 无相关文案 | P1 |
| I | **元素克制是隐藏的 3 倍难度摆幅**（克制×1.5 / 抗性×0.5），远大于相邻关卡的难度步进；且 **毒抗武器是陷阱商品**：venomlauncher 卖 10★，全战役只有 2 关毒弱点（都在第4章），同价的 teslacoil 覆盖 12 关且 DPS 更高 | weakness 分布：物理39/火34/冰12/雷12/毒2；weapons.json | P1 |
| J | **技能生态失衡**：穿透弹在全部 99 关都是第一选择（26-35% 选取率），防线屏障/淘金弹链全程垫底（6-13%）；战力模型防御权重仅 0.18——而 Phase 1 星级修复后防御技能价值会上升，两者必须联动调 | simulate_card_director 全量输出；save_manager.gd:839-841 | P1 |
| F | 章节开局难度毛刺：61 关 coef 4.13（前后 2.85/2.68），89 关 5.13——刚打完 Boss 进新章节反而挨一记闷棍 | data/levels.json | P2 |
| G | 后期金币收入与升级成本的节奏偏紧：reward_gold_mult 一路衰减到 0.20，单套满配总成本约 38 万金币 | data/levels.json + upgrade_cost_linear_k=0.7 | P2 |
| K | **战力三口径显示会倒挂**：结算页出现过"战前 12 → 终局 10"——因为"战前"内含 4 次选卡的预估加成，实际选卡少于 4 张时"终局"反而更低，读起来像"越打越弱" | save_manager.gd:640-642（get_loadout_power 内嵌 4 picks 投影）；结算页实测截图 | P2 |

不需要动的（分析过、判定健康）：
- **金币节奏总体健康**（见 1.5 节配平表）：全程"累计收入 ÷ 维持人物+起始武器在推荐等级的累计成本"稳定在 2.0–2.7 倍。
- 敌人HP/玩家DPS的宏观差值由局内技能补齐、通关时间随进度拉长（28s→230s）——符合设计意图。
- 升级边际收益递减 + 线性成本——同类游戏惯例，配合 G 的小幅平滑即可。
- 人物成长实际有效系数：主炮伤害按 `atk_growth × 0.45`（≈3.6%/级）生效（battle.gd:2056），角色详情页显示的 +3.6%/级 与模拟器口径一致，**三端已对齐，别再叠加或去掉这个 0.45**；角色主动技走独立的 0.52 系数（battle.gd:1773），是有意的双轨。
- 永久技能 XP 线（16 技能满级 10.3 万 XP + 4 角色专属技 3.4 万）——量级合理，Phase 3 顺带复核收入即可。
- 无限尸潮 1.5^loop 增压——金币燃烧器定位，符合预期。

---

## 1. 关键机制现状（实施者必读）

- **星级判定（游戏侧）**：`gameplay/battle/battle.gd:8158-8161`
  `hp_ratio = base_hp / base_hp_max`；胜利时 `stars = 3 if hp_ratio >= 1.0 else 2 if hp_ratio >= 0.5 else 1`。
  基地可被"基地维修"回满（battle.gd:5088、9620 均 clamp 到 max），所以 3星 = "结算时满血"，不是"从未受伤"。
  注意：`data/levels.json` 里 99 关都写了 `"star_rule": "base_hp_percent"`，但 battle.gd **从来没读过这个字段**——判定是硬编码的。
- **星级判定（调参侧）**：`tools/simulate_balance.py:377-383`
  按 leak%（预估漏怪伤害/基地血量）判：≤40% → 3★，≤70% → 2★，否则 1★。
- **挑战模式**：与普通关走同一条 `_finish` 星级判定；星星记在独立的 `challenge_progress`（save_manager.gd:468-486），
  每关最多再供 3 星（理论供给 = 战役 297 + 挑战 297）。
- **Boss 生存 ramp**：`data/economy.json` `boss_survival_hp_ramp: {start 50, full 98, max_mult 56.0, power 1.15}`。
- **升级成本**：线性 `base_cost × (1 + 0.7×(level-1))`（save_manager.gd:1083-1087）。
- **升级收益**：武器 `1+0.08×(L-1)` 伤害、`1+0.025×(L-1)` 射速（save_manager.gd:634-638）；
  人物主炮有效成长 `1 + atk_growth×0.45×(L-1)`（battle.gd:2056）。
- **元素倍率**：`economy.json` `weakness_mult: 1.5`，`resist_mult: 0.5`。
- **战力模型技能评分**：`save_manager.gd:786-841` `_combat_skill_effect_multiplier`——
  进攻侧连乘后按 0.82 权重、生存侧（barrier×0.22 + slow×0.30）按 0.18 权重合成。

### 1.5 难度到底是对着什么成长基线调的（v2 新增，实施者必须先读懂这节）

`tools/simulate_balance.py:326-340` 的玩家模型是：**免费初始组合 vanguard + autocannon**，
人物和武器等级都等于该关 `recommend_level`，凯夫拉护甲（基地HP×1.2），芯片伤害系数，
**不含任何元素克制加成**（物理弹打一切，×1.0）。

这个基线的含义：
1. 元素克制（×1.5）、更高档武器（railgun 6.81 / plasmacannon 7.15 vs autocannon 4.00 相对DPS）、
   角色亲和加成，全部是**玩家侧的纯上行空间**——难度没有假设你拥有它们。这是合理的保守设计，保留。
2. 金币配平实测（按每关只打一遍、击杀金×reward_gold_mult+首通奖励累计）：

| 关卡 | 推荐等级 | 累计收入 | 维持人物+初始武器成本 | 收入/成本 |
|-----|---------|---------|---------------------|----------|
| 10 | 6 | 6,792 | 2,940 | 2.31 |
| 30 | 16 | 43,435 | 21,682 | 2.00 |
| 50 | 26 | 116,755 | 57,575 | 2.03 |
| 70 | 36 | 231,372 | 110,618 | 2.09 |
| 99 | 50 | 455,373 | 168,086 | 2.71 |

   全程 2.0–2.7 倍余量，用于护甲/芯片/宠物（三槽全部跟到推荐级约再花一倍）和第二把元素武器。
   **结论：数学是通的，但玩家不知道**——把金币平摊到 8 把武器 4 个角色的玩家必然全面落后于推荐级，
   然后把锅甩给"难度太高"。这就是为什么 Phase 5/7 的"引导"改动和数值改动同等重要。
3. 人物、武器双轨的定位：满级时人物贡献 ≈2.4×（3.6%/级×39），武器贡献 ≈8.1×（伤害4.12×射速1.975），
   武器是主要金币去向，单级也更便宜（base 100 vs 145）——定位清晰，不改。

---

## 2. Phase 0 —— 修模拟器，再谈调参（必须最先做）

**目标**：让 simulate_balance.py 的 Boss 关 t_ws 输出可信。在此之前禁止改任何数值旋钮。

**症状**（当前输出）：Boss 关 t_ws 序列 50→99 为 `2.0, 10.1, 16.0, 19.2, 46.4, 62.6, 91.7, 143.5, 148.4, 188.6, 230.8`。
前四个（50/55/60/65 关）低到荒谬（2–19 秒清 120 万–800 万 HP，而按 hp/dps 直算应为 83s+）。
形态高度怀疑是 Boss 生存窗口模型在 ramp 起点（t≈0 → mult≈1）处退化，把"生存窗口时间"当成了通关时间。

**改法**：
1. 定位 simulate_balance.py 里 Boss 关 time_ws 的计算分支（搜 `boss_survival` / `survival` 相关时间模型）。
2. 修正为 `t_ws = max(生存窗口模型, hp_total / dps_ws)` 或等价的下界保护。
3. 修完后重跑，把 50–99 的 Boss 关 t_ws 重新记录进附录，确认单调合理、无 <45s 的 Boss 关。
4. 修完工具后如果 50–70 关 Boss 的真实预测时间越界，只允许微调 `boss_survival_hp_ramp` 的
   `curve_power`（1.15 → 最多 1.3），不许动 max_mult。

**验收**：`python3 tools/simulate_balance.py` 中 "Levels < 30s (with skill)" 只剩 level_001；
所有 Boss 关 t_ws ≥ 45s 且随关卡号大体单调；`check_release_candidate.py` 全绿。

---

## 3. Phase 1 —— 星级判定统一 + 单一事实来源（核心改动）

### 3.1 新增数据旋钮（单一事实来源）

`data/economy.json` 新增：
```json
"star_thresholds": {
  "three_star_hp_ratio": 0.70,
  "two_star_hp_ratio": 0.35
}
```
取值依据：与模拟器 leak≤30% 口径等价，比原模拟器 40% 略严——模型算的是最优构筑，给真人留余量。

### 3.2 游戏侧接入

`gameplay/battle/battle.gd:8158-8161` 改为从 `DataLoader.get_table("economy")` 读阈值，
默认值与 economy.json 相同（防数据缺失）。

### 3.3 模拟器同步

`tools/simulate_balance.py:377-383` 改为读同一份 economy.json，换算成 leak 口径。删除硬编码 40/70。

### 3.4 UI 同步（Phase 1 内必做）

- `meta/result/result.gd`：星星行下加小字 `三星 剩余防线 ≥70% ｜ 两星 ≥35%`（动态读 economy.json）。
- `meta/loadout/loadout.gd` 战术摘要：追加同一提示（动态读取）。

### 3.5 存档兼容

无需迁移：星级只按 `max(new - old, 0)` 补差额，放宽后只会多拿星。

**验收**：
- headless 打一局 level_001 故意漏 20% 血 → 结算 3★。
  （做法：按"冷启动执行须知"第 4 条的 stub router 模式进 battle 后，直接
  `battle.base_hp = int(battle.base_hp_max * 0.8)`，再调 `battle._finish(true)`，
  断言 stub 收到的 result `stars == 3`；旧规则下同样输入应为 2。）
- 星级分布重跑记录到附录（预期普通关 3★≈25、2★≈48）。
- grep 确认 `0.70`/`0.35` 只存在于 economy.json。
- 55 路由截图回归通过（重点看 result 不溢出）。

---

## 4. Phase 2 —— Boss 关公平性包

**目标**：Boss 关从"必定1星"变成"2星常态、3星挑战"。不削 Boss 的 HP 海绵戏剧性。

1. `data/economy.json` 新增 `"boss_level_base_hp_mult": 1.25`。
   battle.gd 基地血量初始化处：若该关任一 wave 含 `boss`，`base_hp_max = round(base_hp_ref × mult)`。
   模拟器 leak 分母同步（simulate_balance.py:362 `base_hp_ref * ARMOR_HP_MULT` 处）。
   推荐战力公式不动（基地血量不影响敌方压力）。
2. 重跑后目标：Boss 关 leak 大体落在 55–85%（2★ 可得、3★ 罕见）。个别仍 >90% 的
   （预计 85/90/95/99），单关微调 waves 的 count（-10% 内），提交信息逐关列出。99 关允许留 85–95%。

**明确不做**：不加保底维修事件；不动 `boss_survival_hp_ramp.max_mult`。

**验收**：≥12 个 Boss 关达到 2★ 口径，5/10/15 关达到 3★ 口径；
`check_endgame_balance.py`、`check_level_pressure.py`、`check_balance_profile.py` 全绿
（基线更新必须在提交信息里引用本文档，禁止静默改基线）。

---

## 5. Phase 3 —— 星级经济复核（改完 1、2 之后做）

1. 用新星级分布算战役现实可得星 S_campaign。
2. 挑战按"普通关星级 -1 档"估算 S_challenge。
3. 判定：`S_campaign + S_challenge ≥ 318 × 1.10`。
   不足 → 最贵一档解锁各 -2★（volt/plasmacannon 16★、railgun/element芯片/collector/reactive 14★）；
   充裕（>1.4×）→ 不动。
4. **顺带复核 XP 经济**：全部永久技能+专属技满级共需约 13.7 万 XP；抽 10/30/50/70/90 五关按模拟击杀数
   ×`xp_per_kill_growth` 估算单局 XP 收入，确认"打完战役+适度重复"能满足 60–80% 总需求即可，不追求全满。
5. 供需表写进附录。

**验收**：`check_economy_loop.py` 全绿；附录表格完成。

---

## 6. Phase 4 —— 低风险平滑项（可与 Phase 3 并行）

### 6.1 章节开局毛刺
- level_061 `difficulty_coef: 4.13 → 3.10`；level_089 `5.13 → 4.40`。
- 97/98 的 6.62/8.24 **保留**（毕业考前哨，阶段 21 已确认）。
- 重跑 check_level_pressure + simulate_balance 确认两关星级口径不变差。

### 6.2 后期金币收入平滑
- 85–99 关 `reward_gold_mult = max(mult, 0.26)`（脚本批量改）。
- 不动 `upgrade_cost_linear_k`。
- 后期单局收入约 +20–30%；`check_economy_loop.py` 基线更新须引用本文档。

---

## 7. Phase 5 —— 元素与武器经济（v2 新增；依赖 Phase 0，可与 1/2 并行）

**背景数据**：99 关主弱点分布 = 物理 39 / 火 34 / 冰 12 / 雷 12 / **毒 2**（毒仅在第 4 章）。
克制 ×1.5、抗性 ×0.5，武器选错元素的实际难度摆幅最大 3 倍，远超相邻关卡步进。

### 7.1 修掉陷阱商品 venomlauncher（数值 + 数据两条腿）

1. `data/weapons.json` `weapon_venomlauncher.unlock_cost_star: 10 → 6`（与其 2 关的克制覆盖面匹配，
   保留其 5.61 相对 DPS 和毒 DoT 的特色定位）。
2. `data/levels.json`：把第 8/9 章 `env_toxic_biolab` 环境、当前主弱点为 fire 的关卡中挑 **4 关**改为
   `primary_weakness: "poison"`（毒液实验室环境配火弱点本来就主题错位）。改完毒弱点关数 2 → 6。
   同步检查这些关的 `card_bias` 若含 fire 倾向则改为 poison 倾向。
3. 重跑 simulate_balance / check_level_pressure / simulate_card_director，确认改弱点的 4 关
   星级口径不劣化（弱点只影响玩家上行空间，模型基线不含克制，预期零变化——若有变化说明改错了字段）。

### 7.2 配装页"本关克制"从提示升级为可行动建议

`meta/loadout/loadout.gd` 战术摘要已有"弱点：XX"和克制徽章；追加一行：
当玩家**已拥有**与本关弱点同元素的武器且未装备时，显示
`建议武器：{武器名}（克制本关，伤害×1.5）`；点击文案直接跳武器图鉴（复用现有 `_open_collection` 导航）。
不自动换装，只建议。文案数字 1.5 动态读 economy.json `weakness_mult`。

**验收**：截图核对 loadout 在"已拥有克制武器但未装备"存档下显示建议行；
`check_release_strings.py`、55 路由截图回归全绿。

---

## 8. Phase 6 —— 技能生态再平衡（v2 新增；**必须在 Phase 1+2 落地后做**）

**背景数据**（simulate_card_director 1000 次/关全量输出）：
- skill_pierce 在全部 99 关都是第一梯队（26–35%），从未跌出前二。
- skill_barrier（6–13%）、skill_gold_rush（7–10%）全程垫底；slow_field 9–18%。
- 战力模型 `_combat_skill_effect_multiplier`（save_manager.gd:839-841）：
  `combined = 1 + (offense-1)×0.82 + (survival-1)×0.18`，其中 survival = 1 + barrier×0.22 + slow×0.30。

**为什么必须等 Phase 1/2**：星级修复后"保住基地血量"直接等于"保住星星"，防御技能的真实价值上升；
先改星级再调评分，才能用同一口径验证。

**改法**（全部只动数值，不动结构）：
1. `save_manager.gd` 评分权重：survival 权重 `0.18 → 0.28`；barrier 系数 `0.22 → 0.35`；slow `0.30 → 0.40`。
2. pierce 的 secondary_gain 系数 `0.075 → 0.065`（save_manager.gd:830），压一点常青王者。
3. gold_rush 不动数值——它是经济卡，选取率低是卡牌导演"每次至多 1 张经济卡"规则的预期结果，
   不要为了拉平选取率而改经济卡强度。
4. 重跑 `python3 tools/simulate_card_director.py` 全量：
   目标 = 没有技能在超过 80 关里进前二；barrier 在高压关（Boss 关+90 后）选取率进入 15%+；
   任何技能全程 <8% 需要单独说明原因（gold_rush 豁免）。
5. 战力显示联动：评分权重变化会整体轻微抬高防御向构筑的"成型战力"数字，
   `RECOMMENDED_POWER_COEF` 不需要动（同一把尺子两端同时变），但必须重跑 simulate_balance
   确认星级分布相对 Phase 2 附录的漂移 ≤ ±3 关，超了就回调权重步长。

**验收**：上述 4/5 两条的量化目标 + `check_release_candidate.py` 全绿。

---

## 9. Phase 7 —— 战力口径显示修正（v2 新增；独立，随时可做）

**问题**：`get_loadout_power()`（save_manager.gd:640-642）返回的"战前"战力内含 4 次选卡的投影
（`_projected_run_skill_levels(POWER_REFERENCE_CARD_PICKS)`），结算页的"终局"用的是实际选到的技能。
实际选卡 < 4 张时终局 < 战前（实测截图：战前 12 → 终局 10），读起来像"越打越弱"。

**改法**（只改显示，不改量纲——推荐值是按这把尺子标定的，动尺子要重标 RECOMMENDED_POWER_COEF，不值得）：
1. `meta/result/result.gd`：当 `终局 < 战前` 时，终局数字后追加灰色小字 `（选卡未满）`。
2. `meta/loadout/loadout.gd` 与 result 的战力行统一改名：`战前 → 基准`（含标准选卡预估）、
   `成型 → 预计成型`、`终局` 不变。同一名词全局 grep 替换，别留混用。
3. 长按战力数字弹的说明（若现有 tooltip/详情）同步解释三口径含义；没有就不加交互，只改文案。

**验收**：headless 打一局早退（选卡 1 张）→ 结算显示"（选卡未满）"；截图回归；
`check_release_strings.py` 全绿。
（做法：stub router 进 battle 后不选卡直接 `battle._finish(true)`，检查 result payload 里
`combat_power < standing_power`，再用 `tools/_shot.gd` 的 result 路由带该 payload 截图核对文案。）

---

## 10. 实施顺序与提交切分（给 Sonnet 的执行清单）

依赖关系：
```
Phase 0（修模拟器）
  ├─→ Phase 1（星级统一）→ Phase 2（Boss公平）→ Phase 3（星级经济复核）→ Phase 6（技能生态）
  ├─→ Phase 5（元素武器经济，可与 1/2 并行）
  └─→ Phase 4（平滑项，可与 3 并行）
Phase 7（战力显示）独立，随时可插。
```

每步一个提交，通用验证协议：
```bash
python3 tools/validate_data.py
python3 tools/simulate_balance.py          # 星级分布/时间列贴进提交信息
python3 tools/simulate_card_director.py    # Phase 5/6 必跑
python3 tools/check_release_candidate.py   # 全绿才许提交
```
涉及 UI 的步骤（Phase 1/5/7）额外用 `tools/_shot.gd` 截图人工核对。

**红线**（继承本项目已踩过的坑）：
- 校验基线与游戏行为冲突时先判断哪边是对的，禁止把 bug 写进校验基线（先例：check_tall_battle_layout 两次返工）。
- 改 battle.gd / save_manager.gd 时注意 Codex 可能并行改同一文件——提交前逐 hunk 确认，必要时 patch 切分。
- 所有阈值/倍率/权重只存一处（economy.json 或 save_manager 常量），工具读同一份，UI 动态读取不许硬编码数字。
- 人物成长的 0.45/0.52 双系数是有意设计（1.5 节），不许"顺手统一"。
- 模拟器基线 = 免费组合无克制（1.5 节），任何"把克制加进基线"的想法都需要 Owner 拍板，本方案禁止。

---

## 附录（实施时填写）

- [x] **Phase 0 修复后的 Boss 关 t_ws 序列**（`min(crowd_dps, dps_ws)` 下界保护后）

| 关卡 | 5 | 10 | 15 | 20 | 25 | 30 | 35 | 40 | 45 | 50 |
|-----|---|----|----|----|----|----|----|----|----|----|
| 修复前 | 51.6 | 87.7 | 83.3 | 81.4 | 80.4 | 87.8 | 82.9 | 72.9 | 76.7 | **2.0** |
| 修复后 | 51.6 | 87.7 | 83.3 | 81.4 | 80.4 | 87.8 | 82.9 | 72.9 | 76.7 | **67.2** |

| 关卡 | 55 | 60 | 65 | 70 | 75 | 80 | 85 | 90 | 95 | 99 |
|-----|----|----|----|----|----|----|----|----|----|----|
| 修复前 | **10.1** | **16.0** | **19.2** | 46.4 | 62.6 | 91.7 | 143.5 | 148.4 | 188.6 | 230.8 |
| 修复后 | **83.4** | **96.9** | **104.2** | 134.5 | 165.7 | 202.0 | 271.2 | 281.1 | 334.4 | 446.6 |

  真因不是"生存窗口模型退化"，而是 **benchmark 的 `crowd_dps`（1,862 万）是 45 只敌人满编队形的峰值吞吐**，
  按进度缩放后杂兵段仍近乎免费（0.1–1.3s）；`boss_survival_hp_ramp` 在 50 关起点倍率恰为 1.0，两者叠加把
  50–65 关压成个位数秒。方案原文建议的 `max(模型, hp_total/dps_ws)` **不可直接采用**——`dps_ws` 比实测
  `boss_dps` 弱约 10 倍，全量套用会把 99 关判成 2,197s（实测 230s），等于把更差的模型写进基线。
  实际采用：杂兵段 `min(crowd_dps, dps_ws)` 下界保护，Boss 单体段保留实测 `boss_dps`。
  `boss_survival_hp_ramp` 未动（`max_mult` 56.0 / `curve_power` 1.15）。
  唯一基线更新：`clear_time_cap(90+)` 330s → 350s（原值在 level_095 被低估为 188.6s 时定的）。
  验收：`Levels < 30s (with skill)` 仅剩 level_001（28.1s）；无 Boss 关 < 45s。
- [ ] Phase 1/2 之后的 99 关星级分布表
- [ ] Phase 3 星级供需表 + XP 经济抽查表
- [ ] Phase 4 改动前后 61/89 关与 85+ 关金币对比
- [ ] Phase 5 改弱点的 4 个关卡 ID 与前后对比
- [ ] Phase 6 调权重后的 pierce/barrier 选取率对比（各阶段抽样）
