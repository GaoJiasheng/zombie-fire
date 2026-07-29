# 24 · 难度与成长曲线 UX 调优方案

> 状态：分析完成，待实施。本文是"难度/成长/星级经济"专项调优的唯一主方案。
> 分析基线：`main @ 49af2558`（Build 38 之后），`python3 tools/check_release_candidate.py` 全绿。
> 实施要求：每个 Phase 内的"游戏改动 + 模拟器同步 + 校验同步 + UI 同步"必须在**同一个提交**里完成，
> 禁止只改游戏不改模拟器（本次分析发现的最大问题正是两者各自为政）。

---

## 0. 分析结论摘要（按 UX 影响排序）

| # | 问题 | 量化证据 | 严重度 |
|---|------|---------|--------|
| A | **游戏的星级判定与整个平衡管线用的判定不是同一套**：游戏要求"结算时基地满血"才给3星，而调参用的模拟器认为"漏怪伤害≤40%"就算3星。全部99关都是照模拟器的口径调的 | battle.gd:8161 vs tools/simulate_balance.py:377-383 | P0 |
| B | Boss 关按"生存海绵"设计（HP 最高 56 倍 ramp），模型自己算出的最优构筑漏怪也高达 66–100%——叠加 A，**每5关一个的 Boss 关几乎永远只有1星** | simulate_balance 输出：所有 Boss 关 leak 66–100%，标注1★ | P0 |
| C | **星级经济供需倒挂**：全图鉴解锁需 318 星；当前判定下战役+挑战的现实可得星约 250 上下（模型估算），全收集在数学上接近不可能 | 解锁总价：角色38+武器75+护甲60+芯片80+宠物65=318；战役理论上限297 | P0 |
| D | 模拟器 Boss 关"带技能通关时间"在 50–65 关区间输出退化值（2.0s/10.1s/16.0s/19.2s），**50–70 关的 Boss 数值实际上是对着坏数字调出来的** | simulate_balance 输出 t_ws 列；"Levels < 30s: 5" | P0（工具） |
| E | 星级规则对玩家完全不可见：没有任何 UI 告诉玩家 2★/3★ 的条件是什么 | result.gd / loadout.gd 无相关文案 | P1 |
| F | 章节开局难度毛刺：61 关 coef 4.13（前后 2.85/2.68），89 关 5.13——刚打完 Boss 进新章节反而挨一记闷棍 | data/levels.json | P2 |
| G | 后期金币收入与升级成本的节奏偏紧：reward_gold_mult 一路衰减到 0.20，单套满配总成本约 38 万金币 | data/levels.json + upgrade_cost_linear_k=0.7 | P2 |

不需要动的（分析过、判定健康）：
- 敌人HP/玩家DPS的宏观差值由局内技能补齐、通关时间随进度拉长（28s→230s）——符合"越往后越史诗"的设计意图，模拟器 cap 内。
- 升级边际收益递减 + 线性成本——同类游戏惯例，配合 G 的小幅平滑即可。
- 永久技能 XP 成长线（全技能满级约 10.3 万 XP + 专属技能 3.4 万）——中后期节奏合理。
- 无限尸潮 1.5^loop 增压——金币燃烧器定位，符合预期。

---

## 1. 关键机制现状（实施者必读）

- **星级判定（游戏侧）**：`gameplay/battle/battle.gd:8158-8161`
  `hp_ratio = base_hp / base_hp_max`；胜利时 `stars = 3 if hp_ratio >= 1.0 else 2 if hp_ratio >= 0.5 else 1`。
  基地可被"基地维修"回满（battle.gd:5088、9620 均 clamp 到 max），所以 3星 = "结算时满血"，不是"从未受伤"。
  注意：`data/levels.json` 里 99 关都写了 `"star_rule": "base_hp_percent"`，但 battle.gd **从来没读过这个字段**——判定是硬编码的。
- **星级判定（调参侧）**：`tools/simulate_balance.py:377-383`
  按 leak%（预估漏怪伤害/基地血量）判：≤40% → 3★，≤70% → 2★，否则 1★。全 99 关的 difficulty_coef、
  boss ramp、晚波倍率都是对着这套口径迭代的。
- **挑战模式**：与普通关走同一条 `_finish` 星级判定；星星记在独立的 `challenge_progress`（save_manager.gd:468-486），
  每关最多再供 3 星（理论供给 = 战役 297 + 挑战 297）。
- **Boss 生存 ramp**：`data/economy.json` `boss_survival_hp_ramp: {start 50, full 98, max_mult 56.0, power 1.15}`，
  Boss 波 HP 相对邻关放大 10–20 倍（85 关 Boss 波 1.03 亿 vs 84 关全关 845 万）。
- **升级成本**：线性 `base_cost × (1 + 0.7×(level-1))`（save_manager.gd:1083-1087，k 来自 economy.json `upgrade_cost_linear_k`）。
- **升级收益**：武器 `1+0.08×(L-1)` 伤害、`1+0.025×(L-1)` 射速（save_manager.gd:634-638）；角色 atk_growth 同为线性 8%。

---

## 2. Phase 0 —— 修模拟器，再谈调参（必须最先做）

**目标**：让 simulate_balance.py 的 Boss 关 t_ws 输出可信。在此之前禁止改任何数值旋钮。

**症状**（当前输出）：Boss 关 t_ws 序列 50→99 为 `2.0, 10.1, 16.0, 19.2, 46.4, 62.6, 91.7, 143.5, 148.4, 188.6, 230.8`。
前四个（50/55/60/65 关）低到荒谬（2–19 秒清 120 万–800 万 HP，而按 hp/dps 直算应为 83s+）。
形态高度怀疑是 Boss 生存窗口模型在 ramp 起点（t≈0 → mult≈1）处退化，把"生存窗口时间"当成了通关时间。

**改法**：
1. 定位 simulate_balance.py 里 Boss 关 time_ws 的计算分支（搜 `boss_survival` / `survival` 相关时间模型）。
2. 修正为 `t_ws = max(生存窗口模型, hp_total / dps_ws)` 或等价的下界保护；不许出现 t_ws < hp_total/dps_ws 的输出。
3. 修完后重跑，把 50–99 的 Boss 关 t_ws 重新记录进本文档附录（实施时补），确认单调合理、无 <45s 的 Boss 关。
4. **重新审视 50–70 关 Boss 数值**：修完工具后如果这几关的真实预测时间越界（超过该阶段 cap），
   只允许微调 `boss_survival_hp_ramp` 的 `curve_power`（1.15 → 最多 1.3，让 ramp 前段更平缓），不许动 max_mult。

**验收**：`python3 tools/simulate_balance.py` 中 "Levels < 30s (with skill)" 只剩 level_001（新手关允许）；
所有 Boss 关 t_ws ≥ 45s 且随关卡号大体单调；`check_release_candidate.py` 全绿。

---

## 3. Phase 1 —— 星级判定统一 + 单一事实来源（核心改动）

**目标**：把星级阈值改到人类可达的水平，并让游戏、模拟器、（未来的任何工具）读同一份数据。

### 3.1 新增数据旋钮（单一事实来源）

`data/economy.json` 新增：
```json
"star_thresholds": {
  "three_star_hp_ratio": 0.70,
  "two_star_hp_ratio": 0.35
}
```
取值依据：模拟器口径 leak≤30%→3★ 与 hp_ratio≥0.70 等价（同一个量的两侧表述），
比原模拟器的 40% 口径略严——因为模拟器算的是"最优构筑"，给真人留余量。

### 3.2 游戏侧接入

`gameplay/battle/battle.gd:8158-8161` 改为从 `DataLoader.get_table("economy").get("star_thresholds", {...})` 读阈值，
默认值与 economy.json 相同（防数据缺失）。判定逻辑不变，只换阈值来源：
`stars = 3 if hp_ratio >= three else 2 if hp_ratio >= two else 1`。

### 3.3 模拟器同步

`tools/simulate_balance.py:377-383` 改为读同一份 economy.json 的 `star_thresholds`，
换算成 leak 口径：`3★: leak_pct <= (1-0.70)*100`，`2★: leak_pct <= (1-0.35)*100`。
删除硬编码的 40/70。

### 3.4 UI 同步（Phase 1 内必做，不许拆出去）

- `meta/result/result.gd`：星星行下加一行小字，例如
  `三星 剩余防线 ≥70% ｜ 两星 ≥35%`（阈值从 economy.json 读，不许硬编码文案数字）。
- `meta/loadout/loadout.gd` 战术摘要：追加同一提示（同样动态读取）。
- 文案风格对齐现有 UiKit 小字规范（参考战术摘要现有行的字号/颜色）。

### 3.5 存档兼容

无需迁移：`apply_level_result`/`apply_challenge_result` 只按 `max(new - old, 0)` 补差额，
阈值放宽后玩家重打只会多拿星，不会回收。

**验收**：
- headless 打一局 level_001 故意漏 20% 血 → 结算 3★（旧规则会是 2★）。
- `python3 tools/simulate_balance.py` 星级分布重跑后记录到附录：预期普通关 3★≈25 关、2★≈48 关；
- grep 确认 `0.70`/`0.35` 只存在于 economy.json（battle.gd/simulate_balance.py/result.gd 全部动态读取）；
- 55 路由截图回归通过（结算页多了一行字，需要重点看 result 相关截图不溢出）。

---

## 4. Phase 2 —— Boss 关公平性包（让 Boss 关星级"难而可得"）

**目标**：Boss 关从"必定1星"变成"2星常态、3星挑战"。不削 Boss 的戏剧性（HP 海绵保留）。

**改法**（两个旋钮，都做）：
1. `data/economy.json` 新增 `"boss_level_base_hp_mult": 1.25`。
   `battle.gd` 里 `base_hp_max = int(level.get("base_hp_ref", 100))` 处（约 :527 附近初始化路径）：
   若该关任一 wave 含 `boss` 字段，则 `base_hp_max = int(round(base_hp_ref * mult))`。
   模拟器 leak_pct 分母同步乘同一旋钮（simulate_balance.py:362 处 `base_hp_ref * ARMOR_HP_MULT` → 再乘 boss 旋钮）。
   推荐战力公式（save_manager.gd `_recommended_power_late_wave_bonus`）不用动——基地血量变化不影响敌方压力。
2. Boss 关的漏怪目标带：改完 1 后重跑模拟器，目标是 Boss 关 leak_pct 大体落在 55–85% 区间
   （即 2★ 可得、3★ 罕见）。若个别 Boss 关仍 >90%（预计 85/90/95/99），
   微调该关 `late_wave_count_mult` 的作用（economy 全局不动，改该关 waves 的 count 本身，单关 -10% 幅度内），
   并说明在提交信息里逐关列出。99 关是毕业考，允许留在 85–95%。

**明确不做**：不给 Boss 关加保底维修事件（改动面大、影响关卡叙事节奏）；不动 `boss_survival_hp_ramp.max_mult`。

**验收**：模拟器 Boss 关星级分布：≥12 个 Boss 关达到 2★ 口径，前三章 Boss（5/10/15）达到 3★ 口径；
`check_endgame_balance.py`、`check_level_pressure.py`、`check_balance_profile.py` 全绿
（若 check 内基线数字需要更新，必须在提交信息里引用本文档编号作为依据，禁止静默改基线）。

---

## 5. Phase 3 —— 星级经济复核（改完 1、2 之后做）

**目标**：确认"全收集"在新规则下是紧凑但可达的长线目标。

**步骤**：
1. 用 Phase 1/2 之后的模拟器星级分布，计算战役现实可得星总数 S_campaign（3★关×3 + 2★关×2 + 1★关×1）。
2. 挑战模式按"普通关星级 -1 档"估算 S_challenge（挑战倍率 hp 1.34–1.5 大约抵一档）。
3. 判定标准：`S_campaign + S_challenge ≥ 318 × 1.10`（10% 余量）。
   - 若不足：优先下调最贵一档解锁（volt 16★ / plasmacannon 16★ / railgun 14★ / element 芯片 14★ /
     collector 宠物 14★ / reactive 护甲 14★，每个 -2★），不改星级判定本身。
   - 若充裕（>1.4×）：不动，保留长线目标感。
4. 把最终的供需表写进本文档附录。

**验收**：`check_economy_loop.py` 全绿；附录表格完成。

---

## 6. Phase 4 —— 低风险平滑项（可与 Phase 3 并行）

### 6.1 章节开局毛刺

`data/levels.json`：
- level_061 `difficulty_coef: 4.13 → 3.10`（介于 60 关 2.85 与 62 关 2.68 的上方一点，保留"新章节略升压"）
- level_089 `difficulty_coef: 5.13 → 4.40`（与 88 关 4.16 平滑衔接）
改完必须重跑 `tools/check_level_pressure.py` 与 simulate_balance，确认两关星级口径不变差。
97/98 关的 6.62/8.24 **保留**——毕业考前哨是有意设计（design/m1_todo.md 阶段 21 已确认）。

### 6.2 后期金币收入平滑

`data/levels.json`：85 关及以后的 `reward_gold_mult` 下限从 0.20 抬到 0.26
（具体：对 85–99 关，`mult = max(mult, 0.26)`，用脚本批量改，别手改 15 个值）。
不动 `upgrade_cost_linear_k`（改成本会牵动全期，收入端只影响后期，风险小）。
**验收**：`check_economy_loop.py` 的后期目标区间若需更新基线，同样引用本文档；
粗算后期单局收入提升约 +20–30%，满配总成本 38 万金币的收尾段落从"百余局"缩到明显更短。

---

## 7. 实施顺序与提交切分（给 Sonnet 的执行清单）

按顺序，每步一个提交，每步跑完整验证再进下一步：

1. **Phase 0**：修 simulate_balance.py Boss 时间模型（工具修复，不动游戏数据）。
2. **Phase 1**：star_thresholds 三端接入（economy.json + battle.gd + simulate_balance.py + result/loadout UI）。
3. **Phase 2**：Boss 基地血量旋钮 + Boss 关漏怪目标带校准。
4. **Phase 3**：星级供需复核（纯分析 + 可能的解锁价微调 + 本文档附录）。
5. **Phase 4**：61/89 关平滑 + 后期金币下限（两个独立小提交也可）。

每步的通用验证协议：
```bash
python3 tools/validate_data.py
python3 tools/simulate_balance.py        # 人工读输出，星级分布/时间列贴进提交信息
python3 tools/check_release_candidate.py # 全绿才许提交
```
涉及 UI 文案的步骤（Phase 1）额外用 `tools/_shot.gd` 截 result 和 loadout 两张图人工核对。

**红线**（继承本项目已踩过的坑）：
- 校验脚本基线与游戏行为冲突时，先判断哪边是对的，禁止把游戏 bug 写进校验基线（先例：check_tall_battle_layout 两次返工）。
- 改 battle.gd 时注意 Codex 可能并行在改同一文件——提交前 `git diff` 逐 hunk 确认只包含本任务改动，
  必要时用 patch 切分（本项目已有两次先例，做法见 m1_implementation_progress 相关记录）。
- 所有阈值/倍率只存 economy.json 一处，代码读数据，工具读同一份数据。

---

## 附录（实施时填写）

- [ ] Phase 0 修复后的 Boss 关 t_ws 序列
- [ ] Phase 1/2 之后的 99 关星级分布表
- [ ] Phase 3 星级供需表（S_campaign / S_challenge / 318 需求 / 结论）
- [ ] Phase 4 改动前后 61/89 关与 85+ 关金币对比
