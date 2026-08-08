# 29 · 角色战力口径与元素身份调优（星星装备锚点版）

> 状态：方案定稿，待实施。本文是"角色间战力离散 / 元素身份不可见 / frost 定价倒挂"专项的唯一主方案。
> 实测基线：`main @ ee00cb33`（2026-08-08 全部探针数据在此基线上测得），`check_release_candidate.py` 全绿。
> 本文取代 2026-08-08 会话中的 v1（压主动技倍率）与 v2（元素加成+survival_reference 手调）两版口头方案；
> §2 记录了对 v2 的复审结论与修正，实施者不需要再翻会话记录。
> 实施要求：每个 Phase 内"模型改动 + power_ruler_model.py 镜像 + generate_clear_requirements 重生成 + 校验基线"
> 必须在**同一个提交**里完成。本项目已三次踩过"两套口径各自为政"的坑（design/24 问题 A、`wave_pattern`、
> 阶段 67 的 leak 口径），不允许再造第四次。

## 冷启动执行须知（新 session 从这里开始）

1. 先读仓库根目录 `AGENTS.md`；再读 `design/28_power_score_v2_multiplicative_reform.md`——本方案的 Phase A
   是 design/28 同源管线的**延伸**，不是新机制；不读 28 会把"同源抵消"做成第二套旁路。
2. 开工第一步：`git status` 必须干净。当前仓库有商店原型线（Codex）在并行施工
   （`meta/store/`、`core/commerce/`、`data/premium_sets.json` 等）；若工作树不干净，先停下与 Owner 确认，
   **禁止**在别人的未提交改动之上施工。然后 `python3 tools/check_release_candidate.py` 确认全绿。
3. 本文行号与数值以 commit `ee00cb33` 为锚点，并行提交会导致漂移——定位一律用函数名/字段名
   （如搜 `_bullet_affinity_multiplier`、`_active_skill_offense_multiplier`、`survival_reference`），
   数值对不上时先重跑 §7 的探针重新测量，不许沿用本文数字凭猜施工。
4. **fixture 纪律**：推荐战力是存档相关的（选卡投影读永久技能等级，见 design/28），
   同一关在不同存档下推荐值不同（实测 level_099 在开发存档=2263、全技能满级 fixture=3503）。
   所有前后对比必须用 §7 定义的同一 fixture，禁止拿两个存档的数字互比。
5. 一次性验证脚本放 scratchpad（模板在附录 A），验完删除，不许提交进 tools/。
6. 每完成一个 Phase：更新 `design/m1_todo.md`、`design/m1_implementation_progress.md`，在本文附录填实测数据。

---

## 0. Owner 锚点（决策记录，2026-08-08）

> **非特殊装备（星星可购的普通装备）满级，能"将将"打过 99 关挑战模式即可；不需要满星。**

把它形式化为三条验收不变量（本方案一切改动都不许破坏前两条）：

- **I1 锚点**：vanguard + autocannon（全免费）满级 + 全技能满级，99 关挑战比值 ∈ **[1.05, 1.20]**。
  实测现状 1.11x——锚点**已经成立**，本方案是"守住它并把其他角色收进带宽"，不是"造出它"。
- **I2 星耗**：达成 I1 所需星星 ≤ 60（最强星星套 railgun+reactive+chip_element+collector 共 56★，
  供给 376★）——"不需要满星"已成立，不许通过抬解锁价来平衡。
- **I3 带宽**：付费角色的 99 关挑战比值全部落在 **[1.05, 1.65]**，任何付费角色 ≥ 免费锚点，
  最强/最弱付费角色 ≤ **1.45×**。现状：blaze 1.99 / volt 1.81 / frost 0.77，带宽 2.58×，**不成立**。

## 1. 实测现状（全部数字在 `ee00cb33` + §7 fixture 下测得）

### 1.1 角色离散是全程恒定的，且与关卡免疫无关

同一套星星最强装备（railgun/reactive/chip_element/collector 满级 + 全技能满级）：

| 挑战比值 | vanguard(0★) | blaze(10★) | frost(12★) | volt(16★) |
|---|---|---|---|---|
| level_050 | 4.34x | 7.67x | 2.97x | 6.99x |
| level_075 | 1.78x | 3.15x | 1.22x | 2.87x |
| level_090 | 1.46x | 2.58x | 1.00x | 2.35x |
| level_099 | **1.13x** | **1.99x** | **0.77x** | **1.81x** |

- 最便宜的 blaze 最强，中价的 frost 比免费角色还弱 32%——与 venomlauncher 同型的**反向定价**。
- 离散来源是主动技进攻倍率（同口径探针：vanguard 1.786 / blaze 2.669 / frost 1.734 / volt 2.305），
  基础属性合计只差约 16%。

### 1.2 战力模型的三处漏读（问题的另一半）

| 数据里写了 | 运行时（battle.gd） | 战力（save_manager + power_ruler_model.py） |
|---|---|---|
| `bullet_affinity.damage_bonus` | 生效 | **唯一被读的字段** |
| `rank_damage_bonus / splash / chain / slow / shatter / status / pierce` 全套 | 25 处生效 | **全部不读** |
| 角色 `base_hp` × `hp_growth`（battle.gd 按 `×0.45` 阻尼生效） | 生效 | **生存倍率完全不读角色**（只读护甲/芯片/宠物） |

后果：frost 的有效血量是 blaze 的 **1.71×**（2.69 vs 1.575，含 0.45 阻尼），战力里价值为零；
每个角色的元素身份（溅射/连锁/减速碎冰/异常强度）在数字上也是零。frost 的 0.77x 有相当一部分是
"整套设计在模型里不可见"，不全是真弱。

### 1.3 "调高元素加成"的定位（Owner 提问的直接回答）

`_bullet_affinity_multiplier` 第一行是元素匹配门：武器元素 ≠ 角色亲和元素 → 返回 1.0。
99 关 `boss_apex_overlord` 免疫火/冰/雷/毒（`immune_damage_floor` 0.08），四个角色在锚点关**必须带物理武器**，
元素亲和恒等于 1.0。**因此调高元素加成对锚点(I1/I3)无效**；它是中期"带对元素"的身份杠杆，
且要等 Phase A 修完漏读之后，调了玩家才能在战力数字上看见。blaze 的直伤亲和 0.04 异常低
（其余角色 0.08–0.10），Phase B 允许顺带修正。

## 2. 对 v2 方案的复审修正（五条，实施者必读）

1. **"重标 `survival_reference`" 废弃 → 改走 design/28 同源抵消。** 手调常量只能在一个点上对齐，
   角色 HP 随等级成长而常量不动，比值会沿战役漂移。正确做法是把新增的"角色侧项"同时算进推荐侧的
   参考构筑（vanguard@recommend_level），与 `card_scale` 的抵消模式完全同构——vanguard 的比值
   **由构造保证**不动，不需要手调任何常量。
2. **"只是修漏读、不新增数值"不成立，改为"新常量必须拟合真实 DPS"。** `splash_bonus 70.0` 是**像素半径**
   不是比例，塞进任何现成系数都是编数字。修正：`tools/audit_character_endgame_dps.py` 的 `best_result()`
   支持任意角色（真实弹道基准），先跑四角色实测 DPS，把折算常量**拟合**到"模型进攻比 ≈ 实测 DPS 比（±12%）"，
   而不是拍脑袋。能复用 `_combat_skill_effect_multiplier` 既有系数的（pierce 0.065 / chain 0.09 /
   status 0.28~0.32 / slow→survival 0.40）直接复用，不另造。
3. **v2 漏了一个会打破锚点的陷阱：vanguard 自己的 `rank_pierce_bonus 2`。** 修漏读后 vanguard 玩家侧
   会多出 ~+13% coverage，而推荐侧的 L1 基线里它是 0——锚点会从 1.13 涨到 ~1.28，I1 被自己人打破。
   同源抵消（第 1 条）顺带解决：参考构筑取 vanguard@recommend_level，rank 加成两侧同增同消。
4. **角色 HP 必须镜像 battle.gd 的 `hp_growth × 0.45` 阻尼**，v2 没写；不阻尼会把 frost 高估约 40%。
5. **v2 的"路线乙"（apex Boss 分阶段轮换弱点）从平级选项降级为独立提案（§5）。** 它需要新的运行时能力
   （战斗中按阶段切换免疫表）、动终局真实 DPS 矩阵（`check_endgame_balance.py` 的 ≤180s/≤260s 基线）、
   动"毕业考回归起始武器"的既定设计、动 Boss 血条弱点显示与双语文案——是一个完整设计阶段，
   不是本次调优的旋钮。**本方案 Phase A+B 不动 99 关的任何免疫配置。**

## 3. Phase A —— 战力模型诚实化 + 同源抵消（必须最先做）

**目标**：数据里已写、运行时已生效的角色能力全部进入战力口径；vanguard 全程比值零漂移。

改法（同一提交内完成）：

1. `save_manager.gd` `_bullet_affinity_multiplier` → 读全套亲和字段：
   `damage_bonus + rank_damage_bonus×成长档`；`pierce/chain` 类计数字段并入 coverage（复用技能侧系数）；
   `status/slow/shatter/splash` 按第 2 步拟合出的常量折算（slow 入生存，其余入进攻）。
2. **拟合**：跑 `audit_character_endgame_dps.best_result()` 四角色（各自最优同元素配装），
   调折算常量直到"模型进攻倍率之比"与"实测 DPS 之比"误差 ≤ ±12%。拟合脚本放 scratchpad，
   拟合结果（常量值 + 四角色误差）写进本文附录 B。
3. `_loadout_survival_multiplier` → 计入角色 `base_hp/100 × (1 + hp_growth × 0.45 × (L-1))`，
   与 battle.gd `_apply_base_survivability` 逐项同式。
4. **同源抵消**：`get_recommended_power_for_level()` 增加参考角色项——按 vanguard + autocannon
   @ 该关 `recommend_level` 计算第 1/3 步新增的全部乘子，乘进推荐值（与 `card_scale` 的注释和
   实现模式并排，写清"两侧同一估计器，比值里抵消"）。`tools/power_ruler_model.py` 全程镜像。
5. 跑 `python3 tools/generate_clear_requirements.py` 重生成（预期：`min_output` 语义是模拟器口径、
   不依赖显示模型，diff 应为零或极小；若 diff 大说明第 4 步做错了，停下排查而不是提交 diff）。

**验收**：
- §7 fixture 下，vanguard 在 1/25/50/75/99 五关的挑战比值与改前差 ≤ ±0.02（同源抵消的构造性证明）；
- frost 与 blaze 的生存倍率之比 ≈ 1.7×（HP 差可见）；四角色模型/实测 DPS 比误差 ≤ ±12%；
- `check_clear_requirements.py`、`check_endgame_balance.py`（vanguard 基准，应零变化）、
  `check_release_candidate.py` 全绿；`m1_smoke_test.gd` 的战力相关断言若需更新基线，提交信息引用本文。

**预估落点**（估算值，实施后以实测为准）：frost 0.77→~0.86、blaze 1.99→~1.85、volt 1.81→~1.72、
vanguard 1.13 不动。带宽 2.58×→~2.15×——**Phase A 只解决一半，Phase B 才是主刀。**

## 4. Phase B —— 主动技带宽压缩 + 亲和微调（依赖 Phase A）

**目标**：I3 成立。只动 `data/characters.json`，不动任何代码。

**禁动项**：vanguard 的一切字段——它在 `_offense_baseline_l1()`、`generate_clear_requirements`、
`physical_endgame_runtime_benchmark.json`、`simulate_balance` 四条管线里都是基准，动它等于重标全游戏。
这也是 Phase B 对终局矩阵零冲击的原因（矩阵只测 vanguard 物理构筑）。

**旋钮**（每角色在自己的 `active_skill` 块内迭代，用附录 A 探针闭环）：
`damage_mult` / `sig_level_damage_bonus` / `cooldown` / `duration` 族字段。
目标带（99 关挑战，Phase A 之后测）：

| 角色 | 现状(A 后预估) | 目标带 | 主刀方向 |
|---|---|---|---|
| blaze | ~1.85 | **1.40–1.60** | `damage_mult 3.6` 与 `rank_damage_bonus 0.12` 下压 |
| volt | ~1.72 | **1.45–1.65** | 小幅下压；16★ 最贵，允许压后仍为最强 |
| frost | ~0.86 | **1.05–1.25** | `damage_mult 1.6`/`sig_level_damage_bonus 0.12` 上抬；配合 A 步已可见的坦度 |

**顺带修正**：blaze `bullet_affinity.damage_bonus 0.04 → 0.08~0.10`（对齐其他角色；只影响火武配装的
中期身份，对锚点无效，见 §1.3）。其余角色元素加成本次**不**普调——先让 Phase A 把已有的读进来，
中期身份是否还需要加码，等真机数据。

**明确接受的残余不对齐**：frost（12★）压完仍会低于 blaze（10★）。这是"进攻权重 0.82 的尺子量坦克"
的固有结果，不追平——frost 的验收是"≥ 免费锚点 + 坦度在数字上可见"，不是进攻排序。
若 Owner 认为仍不可接受，备选项是 frost 12★→10★ 调价（会动 316★ 总价与 m1_smoke 基线，需单独拍板）。

**验收**：I1/I2/I3 三条全部实测通过（表格进附录 C）；50/75/90 关抽查无角色 < 1.0；
重跑四角色 DPS 审计确认实测差距同步收窄（模型没有与现实脱钩）；全量 RC 绿。

## 5. Phase C（独立提案，本次不做）—— apex Boss 分阶段弱点轮换

要点存档：99 关 Boss 本就 3 阶段（0.67/0.34 相变），可改为 P1 物理窗口 → P2 火/冰窗口 → P3 雷/毒窗口、
物理全程中性、`immune_damage_floor 0.08→0.18`。收益：四角色在毕业考各有段落，元素加成成为终局真实杠杆，
frost/volt/blaze 获得终局存在理由。代价：见 §2 第 5 条清单。
**若 Owner 拍板做，另立 design 文档走完整流程；先决条件是本方案 Phase A+B 已落地**（否则元素窗口
在战力上仍然不可见，做了玩家也读不到）。

## 6. 红线

- vanguard 与 weapon_autocannon 是全管线归一基准，**禁动**（§4）。
- 99 关免疫配置、`boss_survival_hp_ramp`、星级阈值、挑战 `recommended_power_mult 1.5` 本方案一律不碰。
- design/24 §10"克制不进模拟器基线"红线继续有效：本方案动的是**角色-武器亲和**（模型里本就有 damage_bonus
  先例），不是**关卡弱点克制**；实施中若发现两者边界模糊，停下问 Owner，不许顺手把 `weakness_mult` 掺进战力。
- 所有折算常量只存 `save_manager.gd` 常量区 + `power_ruler_model.py` 镜像各一份，两处必须同 diff 同提交。
- **design/21 军械基准联动**：军械"比免费同属性最强满配高 50%（1.52–1.58×）"的基准中，火系=blaze 满配、
  雷系=volt 满配——Phase B 压完基准即变。落地后必须在 design/21 附录追加"基准于 <commit> 重冻结"条目，
  并通知 1C 数值线（当前商店线只做原型不做 1C 数值，时间窗是安全的；若 1C 已开工则先协调再动 Phase B）。

## 7. 验证协议与 fixture

**fixture 定义**（探针脚本自建，不落盘到真实存档）：全部星星装备解锁并满级
（角色 40 / 武器 50 / 护甲芯片 35 / 宠物 30）、16 永久技能 Lv5、全专属技 Lv5；
apocalypse（999999★）系全部排除。对比表全部基于此 fixture。

**每 Phase 通用协议**：
```bash
python3 tools/validate_data.py
python3 tools/generate_clear_requirements.py   # Phase A 必跑；diff 进提交或说明为零
python3 tools/check_clear_requirements.py
python3 tools/simulate_balance.py              # 星级分布必须与 ee00cb33 一致（12/86/1）
python3 tools/check_endgame_balance.py         # vanguard 基准，Phase A/B 均应零变化
python3 tools/check_release_candidate.py       # 全绿才许提交
```
加角色专项：附录 A 探针跑 1/25/50/75/90/99 六关 × 4 角色矩阵，贴进提交信息。

## 8. 与其他工作线的衔接

- **商店原型线（Codex，进行中）**：文件集不相交（本方案：save_manager 战力区 + characters.json +
  power_ruler_model.py；商店线：store/commerce/premium_sets）。唯一共享文件是 save_manager.gd——
  开工前工作树必须干净（须知第 2 条），提交前逐 hunk 确认。
- **design/25（难度回归 2026-08-02）**：本文实测全部晚于它，以本文为准；若实施时发现与 25 冲突，
  按 design/24 红线先判对错再动基线。
- Build 42 及以前的真机数据基于旧角色数值，Phase B 落地后早期关体感不变（早期主动技等级低、差异小），
  终局差异需要新 TestFlight 验证——纳入下一个构建的验收重点。

---

## 附录（实施时填写）

- [ ] A. 探针模板（实施首日把 2026-08-08 会话用的 challenge-table 探针整理进来，含 fixture 构建段）
- [ ] B. Phase A 拟合结果：折算常量表 + 四角色 模型/实测 DPS 对照（±12% 判定）
- [ ] C. Phase B 前后对照：六关 × 四角色挑战比值矩阵 + I1/I2/I3 判定
- [ ] D. design/21 军械基准重冻结记录（新的免费最强满配数值 + commit）
