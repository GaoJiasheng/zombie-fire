# 09 · 数值平衡

> 这里给出**具体公式与示例数值**，作为首版配表的基准。所有数字都是"可调初值"，上线前用真机刷关回归微调。
> 全部数字最终落进 `economy.json` 与各内容表，程序读表、设计师调表。

## 1. 设计目标（量化）

- **建议等级达标 + 核心装备按档** → 标准关 2~3 星、Boss 关 1~3 星。
- **欠 5 级或装备欠 1 档** → 标准关勉强 1~2 星、Boss 关需极限操作。
- **重刷 2~4 遍**某关 → 攒够金币把核心装备升 1 档。
- **天赋点总产出** ≈ 升满"任意 2 个完整角色全技能"所需 + 富余（鼓励专精，不强制全练）。
- **星总产出 297** ＞ **解锁全玩法内容 ≈220** ＞ 0（皮肤吃盈余）。
- **非推荐元素** → 普通关可首通但较难三星；Boss 硬免疫需要明确准备路径。
- **前 20 关** → 每 2~3 关给一次质变体验（新技能、精英奖励、清屏关、首次 Boss 准备），不能只给线性数值。

## 2. 角色等级与属性

```
level_xp(L)      = round( 50 * L^1.5 )          // 升到 L 级所需总经验近似阈值/级
base_atk(L)      = char.base_atk * (1 + 0.08*(L-1))    // 每级约 +8% 攻
base_hp(L)       = char.base_hp * (1 + 0.06*(L-1))     // 每级约 +6% 基地血
talent_per_level = (L <= 40) ? 1 : 2                    // 前40级1点/级，之后2点/级
```

到 Lv80（终局建议）累计天赋点 ≈ `40*1 + 40*2 = 120` 点/角色。
全技能升满成本（见 §5）约 100~110 点/角色 → **够升满本角色主力技能并有取舍空间**。

## 3. 怪物数值缩放（按关卡）

```
enemy_hp(level_n, type)   = type.hp_coef   * GLOBAL_HP_BASE   * scale(n)
enemy_dmg(level_n, type)  = type.bd_coef   * GLOBAL_DMG_BASE  * scale(n)
scale(n) = 1 + 0.10*(n-1) + 0.004*(n-1)^2     // 线性为主、后段轻微加速
```

- `GLOBAL_HP_BASE / GLOBAL_DMG_BASE` 是全局旋钮，统一调难度松紧。
- Boss：`hp_coef` 取 25~60（巨血），并按 `phases` 分段。
- 与"建议等级玩家的 DPS 曲线"对照（§6）确保关卡时长落在目标区间（标准关 90~150s）。

## 4. 伤害与派生（接 `02` 公式，给系数）

```
最终单发 = base_atk(L) * weapon.base_atk_coef * Π(skill_mods)
         * (1 + Σ elem_dmg) * weakness_mult * (crit ? crit_dmg : 1)

crit_dmg 基础 = 1.5（可被 critical/chip 提升到 2.0+）
weakness_mult ∈ {1.5 弱点, 1.0, 0.5 抗性, 0 免疫}
DoT 单跳 = 快照最终伤害 * dot_coef（火≈0.25/跳、毒≈按层 0.05*最大生命 等，见各技能表）
```

## 5. 技能成长成本（天赋点）

每个技能 base_level Lv1→Lv5 的天赋点成本（统一基准，可个别微调）：

| 升到 | 单步成本 | 累计 |
|---|---|---|
| Lv1（学会） | 2 | 2 |
| Lv2 | 3 | 5 |
| Lv3（解锁分支） | 5 | 10 |
| Lv4 | 6 | 16 |
| Lv5（解锁终极） | 8 | 24 |

- 单技能满级 24 点。一套主力 = 2 专属 + 约 3 常用通用 ≈ 5 个满级 ≈ 120 点 → 与 Lv80 产出基本持平，留少量富余但需取舍（专精乐趣）。
- 角色独立计点（见 `03`）。练第 2 个角色相当于重新规划一套（提供新鲜感而非纯重复，因为元素流派不同）。

## 6. 玩家 DPS vs 关卡血量（可过性验证模型）

用一个简化模型在配表阶段自检每关"是否可过、几星可达"：

```
player_dps(L, gear, build) ≈ base_atk(L)*weapon_coef*fire_rate
                              *(1+crit_rate*(crit_dmg-1))
                              *avg_skill_multiplier(build)
                              *avg_weakness_mult(本关)

wave_total_hp(n)  = Σ enemy_hp(n, type)*count
required_clear_time = wave_total_hp / player_dps
leak = f(漏怪率, breach_damage)   // 漏怪导致基地掉血

预测星级 = 100% - 预测基地掉血%  → 映射 ★/★★/★★★
```

- 配表脚本（见 `13` 工具）对 99 关 × {欠级/达标/超级} × {欠档/达标} 跑一遍，输出"预测星级矩阵"。
- 验收线：**达标玩家每关预测 ≥2 星，无任何关预测 <1 星（即必可过）**；不达标则调 `scale/GLOBAL_*` 或波次。
- 额外跑两组 build：`recommended_build` 与 `off_recommend_build`。普通关中，非推荐 build 应预测 ≥1 星；Boss 关允许非推荐 build 失败，但必须在前置关卡和选关 UI 中提示。

## 7. 卡牌导演平衡

三选一不是纯随机，也不是完全点菜。基础权重模型：

```
card_weight = base
  * role_affinity(skill, character)
  * build_synergy(skill, owned_run_skills)
  * level_need(skill, level_threat_tags, primary_weakness)
  * emergency_mod(skill, leak_risk, elite_alive, boss_phase)
  * pity_mod(skill, recent_misses)
```

约束：
- 每次三选一至少 1 张 `build_synergy` 高的牌。
- 漏怪风险高时，`control/defense` 提权，`economy` 降权。
- 前 5 关人为提高 `split_shot/pierce/multishot/incendiary` 等爽感牌权重。
- 连续 2 次没有出现玩家核心 tag，第 3 次触发保底。
- 每局基础 1 次 reroll；精英击杀/`skill_recycle` 可额外给，避免烂牌挫败。

## 8. 金币经济曲线

```
gold_drop(type, n) = type.gold_coef * (10 + 2*n)        // 随关卡线性增长
first_clear_gold(n) = 100 + 20*n
强化成本(equip, lvl) = equip.cost_base * 1.15^lvl       // 指数，每10级一个台阶感
```

- 自检：在第 n 关重刷一遍的净金币产出，对照"把核心装备从档位 k 升到 k+1 的成本"，使**重刷 2~4 遍可升 1 档**。
- 经济技能/芯片（gold_rush / chip_greed）可把"刷"的效率提升约 30~60%，缩短肝度但不进战力平衡。

## 9. 星经济曲线（解锁定价，总 ≤220）

| 解锁项 | 星价 | 小计 |
|---|---|---|
| 第 2 角色 | 30 | 30 |
| 第 3 角色 | 50 | 80 |
| 第 4 角色 | 70 | 150 |
| 元素主炮 ×4（火/冰/雷/毒） | 各 8 = 32 | 182 |
| plasmacannon（终极物理炮） | 18 | 200 |
| 抗性护甲/稀有芯片/稀有宝宝（打包若干） | ≈18 | 218 |
| 皮肤（纯外观，可选） | 盈余 | — |

- 总刚需 ≈218 < 上限 297，留约 79 星给皮肤/容错（玩家不必关关三星也能解锁全玩法）。

## 10. 挑战与长期经济

无氪版本的长期内容不能给过强战力，否则会变成新的压力源：

| 内容 | 主奖励 | 平衡规则 |
|---|---|---|
| 变异尸潮 | 金币、皮肤碎片、图鉴标记 | 不掉唯一装备 |
| 无限尸潮 | 记录、排行榜、称号 | 不影响主线数值 |
| 章节挑战 | 章节徽章、外观 | 可给少量金币，不给必须战力 |
| 全三星 | 星盈余、皮肤 | 不要求全三星才能通主线 |

## 11. 平衡维护流程

1. 改表 → 跑 §6 自检脚本 → 看预测星级矩阵。
2. 跑 §7 卡牌导演模拟，检查核心 build 成型率、烂牌连续次数、经济牌危机误出率。
3. 真机/导出包刷代表关（前 5 关、每章首关、爽感关、狂潮关、各 Boss）。
4. 记录实际星级 vs 预测，偏差 >1 星的关卡回调。
5. 全局松紧只动 `GLOBAL_HP_BASE/GLOBAL_DMG_BASE`，局部动单关 `difficulty_coef`、波次或卡牌权重。
6. 所有改动进 git，配表版本与游戏版本对齐。
