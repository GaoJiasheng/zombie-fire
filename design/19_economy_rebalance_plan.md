# 19 · 经济·难度·经验技能 三轴重平衡 PLAN(待执行)

> 决策已锁定(见 §0)。系数为校准后的建议起点,最终由 `check_level_pressure.py` + 新增"经济/经验比"检查微调。
> ⚠️ 执行需改 `data/*.json` 与 `core/`、`gameplay/`、`meta/` 多处代码——**等 codex 空闲再做,避免并发冲突**。本文是规格,不是已实现状态。

## 0. 已锁定决策
1. 金币、经验、星 **获取随关卡线性增长**;武器/装备/角色 **升级费随等级线性**(取代 1.15 指数)。
2. 金币 **线性但仍有压力**(收紧系数,见 §2.1)。
3. 星 = **消费货币**(购买扣除),商品**总价 890★ ≈ 3×全战役星(297)**,**整齐档位**(§2.3)。
4. 经验 = **专职永久升技能 base_level(1→5)**;角色等级 **仍吃金币**(改动最小)。
5. **默认免费仅 2 件**:角色 `vanguard` + 主炮 `weapon_autocannon`。**护甲/芯片/宝宝全部不免费、开局没有**;要求 **前 5 关裸装(仅角色+主炮)可通**。
6. **挑战模式补星**:本次只写思路(§4.4),不实现。

---

## 1. 三货币,各司其职
| 货币 | 来源(线性) | 花在哪 |
|---|---|---|
| 金币 gold | 打怪掉落 | 装备 + 角色等级 升级 |
| 星 star | 通关质量(3/关) | 解锁新物品(消费扣除) |
| 经验 xp | 打怪掉落 | **永久升技能 base_level(1→5)** |

修掉的根因:现状角色升级吃金币、**持久经验空转**、技能只能局内升且关束清零(Lv4/5 死内容)、早期只能点 2 次卡。

---

## 2. 轴一 · 经济

### 2.1 金币(线性 + 压力)—— 校准系数
```
per_kill_gold = (GB + GP*n) * gold_coef     # GB=5, GP=0.6, n=关序
first_clear   = FB + FP*n                    # FB=100, FP=20
reward_gold_mult = 1.0
```
校准结果:一周目≈119万;重刷 L50≈11,478 ≈ 给 6 件主力各升一级(L25 档≈12,460)→ **约每档重刷 1-2 遍**;练满主力到 Lv30≈219k(一周目的~18%,有压力但可达);全物品全满=多周目长尾。
- 改 `gameplay/enemy/enemy.gd:92`(单怪 gold)+ `data/economy.json` + 各关 `reward_gold_mult`→1.0。

### 2.2 升级费(线性,取代指数)
```
upgrade_cost(L→L+1) = round(base_cost * (1 + K*(L-1)))   # K=0.7
```
- 改 `core/save/save_manager.gd:278 _scaled_upgrade_cost`。

### 2.3 星:消费制 + 整齐档位(总 890★)
解锁逻辑改为**购买扣星**(去掉 `save_manager.gd:168-188 _refresh_star_unlocks` 的"阈值自动解锁",新增 `purchase_item()`)。**默认免费仅 vanguard + autocannon**;其余全部按下表:

| 类 | 物品:★ |
|---|---|
| 主炮(autocannon免费) | flamethrower 5 · cryocannon 5 · scattergun 10 · teslacoil 10 · venomlauncher 15 · plasmacannon 20 · railgun 45 |
| 角色(vanguard免费) | blaze 15 · frost 25 · volt 40 |
| 护甲(全付费) | kevlar 5 · thermal 10 · cryo 20 · faraday 30 · hazmat 40 · reactive 60 |
| 芯片(全付费) | chip_attack 5 · haste 10 · crit 15 · health 25 · pierce 35 · guardian 45 · greed 55 · element 80 |
| 宝宝(全付费) | turret_drone 15 · fire_imp 25 · frost_wisp 35 · volt_orb 50 · medic_drone 60 · collector 80 |

合计 **890★**(主炮110+角色80+护甲165+芯片270+宝宝265),最贵 80★。
- 战役上限 297★ → **够买"专精一套"**(如火流一套≈150★),**买齐全 890★ 需≈3×战役星 → 靠后续挑战模式补**。
- 第一件护甲+芯片仅 kevlar5+chip_attack5=10★ → 开局清几关即可入手。
- 改 5 个 JSON 的 `unlock_cost_star`;给 kevlar/chip_attack 也加上(它们不再免费)。

---

## 3. 轴二 · 难度:线性成长 + 对齐

- 敌人 HP/伤害随关卡线性(核对 `difficulty_coef` 曲线);怪种/机制按梯队递增。
- 玩家战力来源(全线性):角色等级(金币)+ 装备(金币)+ **技能 base_level(经验)** + 局内选卡(临时)+ **角色主动技能(见 §3.1)**。
- 对齐:达 `recommend_level` + 主力按档 → 2-3 星;低于建议等级更吃操作。
- **硬要求**:护甲/芯片/宝宝开局没有的前提下,**前 5 关必须裸装(仅 vanguard+autocannon)可通**;改完用 `check_level_pressure.py` + 实测核 1-5 关。
- 前期更轻松来自:线性升级费(前段便宜)+ 技能永久成长(不再每关从零)。

### 3.1 角色主动技能(必须纳入难度/可过性模型)
每个角色有 1 个**手动触发、带 CD** 的主动技(=其 2 个专属技之一),是关键的"操作输出 / 救场"杠杆,4 个各异:
| 角色 | 主动技 | 类型 | CD | 缩放基准 |
|---|---|---|---|---|
| vanguard | railvolley 齐射 | 持续 DPS(+齐射数/攻速) | 18s | **主炮**等级 |
| blaze | meltdown 范围灼烧脉冲 | 爆发清群(×3.6, 4脉冲) | 16s | 角色等级 |
| frost | glacier 减速冰原 | **控制为主(降漏怪)**, ×0.34 | 18s | 角色等级 |
| volt | storm 范围连锁落雷 | 多目标爆发(×2.1, 6目标) | 14s | 角色等级 |

纳入 `09 §6` 可过性模型的要点:
1. **有效 DPS 要加上主动技**:`effective_dps += 单次爆发 / 冷却`;frost 计为"控制/降漏怪值",不是直伤。
2. **同时吃两轴缩放**(平衡时不能漏算):`level_damage_growth × scaling_basis 等级`(主炮或角色,**金币轴**)+ `rank_* 加成`(其专属技 base_level/run_level,**经验+局内轴**)。
3. **CD 缩短**(如 `skill_recycle`)提升主动技在场率 → 计入有效 DPS。
4. **元素免疫交互**:火系 meltdown 对火免疫 Boss 无效 → 强化"换角色/带物理";vanguard 物理 railvolley 是全免疫 Boss 的稳解。
5. **裸装前 5 关**:护甲/芯片/宝宝开局没有时,主动技 + 主炮是核心输出/救场;调"前 5 关可过"时**必须把 vanguard railvolley 算进有效 DPS**,否则会误判过不去。

---

## 4. 轴三 · 经验 ↔ 技能对齐(本次重点)

### 4.1 XP 永久升技能 base_level
- 每技能加持久 `base_level(0→5)`,用 **XP** 在养成界面升,**线性费 cheap→贵**(`skills.json` 加 `xp_cost_table`)。
- 战斗里技能**从 base_level 起步**;局内选卡叠 run_level,上限仍 5。
- 改:`save_manager` 加 `skill_base_levels{}` + `upgrade_skill_base()`;`skill_runtime` 初始 run_level=base_level;`meta/collection` 技能页加"花经验升级"按钮。
- **专属技(含主动技)同走此系统**:角色 2 个专属技也有 base_level,用经验升;主动技的 `rank_*` 加成 = 该专属技等级 → **主动技强度的"经验轴"就来自这里**(金币轴见 §3.1)。所以升专属技 = 同时强化"出场被动 + 手动主动技"。

### 4.2 XP 获取线性 + 对齐比例
```
per_kill_xp = XB + XP*n        # 线性, n=关序
char_level_xp(L) = coef*L      # economy.level_xp_pow 1.5 → 1.0(线性)
```
对齐目标(系数由求解器定):**练满"主力 5 技能" ≈ 一周目战役经验**;**练满全 24 技能 ≈ 3-4 周目**(重刷/挑战补)。前期 XP 便宜点得起,后期递增有追求。

### 4.3 局内选卡手感
- `target_card_picks` 设**下限 3**(终结"只能点两下");中后期维持 6-7。
- 有了持久 base_level,选卡从"唯一来源"变"临时强化",节奏更顺。

### 4.4 挑战模式补星(仅思路,不实现)
- 战役星(297)够"一套";要集齐全部 890★ 需额外 ~593★。
- 后续开 **远征/挑战/无限尸潮** 等可重复、不耗体力的模式,产出**星(+少量金币/皮肤)**,**不给必须战力**(无氪长线、不制造压力)。
- 数据预留:`data/challenges.json`(见 `design/data/schema.md`),`save.challenge_progress`。本期不做实现。

---

## 5. 平衡稳态
| 轴 | 目标 | 结论 |
|---|---|---|
| 金币 | 每档重刷1-2遍;练满主力≈一周目18%;全满=长尾 | ✅ 线性且有压力 |
| 星 | 专精一套≤297;全收890=3×战役→挑战补 | ✅ "先做一套"成立 |
| 经验/技能 | 主力技能满≈1周目;全技能满≈3-4周目;前期点得起 | ✅ 经验有用、技能可升满 |
| 难度 | 达建议等级2-3星;**前5关裸装可通(含主动技)**;前期偏易 | ✅ 平滑,需脚本+实测核 |
| 主动技 | 占有效DPS有感(~15-30%)、是Boss/救场杠杆,不auto-win | ✅ 吃金币+经验双轴,纳入可过性模型 |

---

## 6. 执行清单(codex 空闲再做)
1. `data/economy.json`:GB5/GP0.6/FB100/FP20、K0.7(替换 upgrade_cost_growth 用法)、XB/XP、`level_xp_pow`→1.0。
2. `gameplay/enemy/enemy.gd:92`:单怪 gold/xp 线性 `(base+per*n)*coef`。
3. `core/save/save_manager.gd`:`_scaled_upgrade_cost`→线性;解锁→购买扣星 + `purchase_item()`;加 `skill_base_levels`+`upgrade_skill_base()`。
4. `data/skills.json`:每技能加 `xp_cost_table`(线性递增)。
5. 5 个装备 JSON:`unlock_cost_star` 改为 §2.3 整齐档(含 kevlar/chip_attack 不再免费)。
6. `gameplay/skill/skill_runtime.gd`:run_level 初始 = 持久 base_level。
7. `gameplay/battle/battle.gd` + `data/levels.json`:`target_card_picks` 下限 3。
8. `meta/collection`/`shop`:花星购买、花金升级、花经验升技能 三种交互 + 扣款。
9. 校验:`validate_data` + `check_level_pressure`(**有效 DPS 须含角色主动技,见 §3.1**;重点核前5关裸装可通)+ 新增经济/经验比检查;真机点商店/升级/技能。
10. `tools/check_level_pressure.py`:把**角色主动技爆发/CD**(按 scaling_basis 等级 + 专属技 rank)计入玩家有效 DPS;按角色分别跑。
11. 同步 `design/02_stats_economy.md`、`03_progression.md`、`09_balance.md`(09 §6 模型补主动技项)。

## 7. 仍可微调(非阻塞)
- GB/GP/K/XB/XP/技能费表的最终值 → 求解器对齐 §5 比例后定稿。
- 整齐星档可再±5 微调(保持总≈890、最贵≤80)。
- 主动技 `damage_mult / cooldown / rank_*` 微调,使其在有效 DPS 占比 ~15-30%(Boss/救场有感、不碾压);frost 以"降漏怪%"等效折算。
