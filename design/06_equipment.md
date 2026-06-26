# 06 · 装备系统（主炮 / 护甲 / 芯片 / 宝宝）

> 4 个装备槽：**主炮 ×1、护甲 ×1、芯片 ×2、宝宝 ×1**。
> 装备靠**金币强化已有**、靠**星/掉落解锁新的**（见 `02`）。不做随机词条/洗练，保持透明。
> 稀有度 5 档：白 `common` < 绿 `uncommon` < 蓝 `rare` < 紫 `epic` < 橙 `legendary`，决定基础数值与可强化上限。
> 数据见 `data/schema.md`（weapons/armors/chips/pets.json）。

---

## 1. 主炮 `weapon`（8）—— 决定 ATK 主体与弹道形态

主炮字段：`base_atk_coef, fire_rate, element, projectile_type, special, rarity, max_level`。

| ID | 名称 | 元素 | 弹道/特性 | 适配角色 | 解锁 |
|---|---|---|---|---|---|
| `weapon_autocannon` | 速射机炮 | 物理 | 高攻速单发，均衡入门 | 全 | 默认 |
| `weapon_railgun` | 磁轨炮 | 物理 | 低攻速高单发 + 自带穿透 | vanguard/frost | 金币商店 |
| `weapon_scattergun` | 散射霰弹 | 物理 | 一次多弹扇射，近距强 | vanguard/volt | 金币商店 |
| `weapon_flamethrower` | 烈焰喷射器 | 火 | 短射程持续火舌，自带灼烧 | blaze | 星解锁 |
| `weapon_cryocannon` | 寒冰炮 | 冰 | 命中减速，自带冰霜 | frost | 星解锁 |
| `weapon_teslacoil` | 特斯拉线圈 | 雷 | 命中自带短链电弧 | volt | 星解锁 |
| `weapon_venomlauncher` | 毒液发射器 | 毒 | 抛射落地成毒池 | blaze | 星解锁 |
| `weapon_plasmacannon` | 等离子炮 | 物理 | **过热机制**：连续开火升温，过热前伤害递增 | vanguard | 星解锁（高价，后期） |

设计要点：
- 主炮的 `element` 与 `projectile_type` 是流派的"地基"，技能在其上叠加（如 `skill_split_shot` 让任何主炮都能分裂）。
- 过热/蓄能类主炮（plasmacannon）制造"控制开火节奏"的操作深度，但**不强制**——其余主炮纯顺滑自动。
- 强化主炮提升 `base_atk_coef`，不改变弹道形态（形态靠换炮/技能改变）。
- 每个章节至少给 1 把"能补当前章节主抗性"的可获得主炮或元素技能，避免玩家因为星不够/没练角色被硬卡。
- M1 阶段优先把 `weapon_autocannon` 做到手感扎实：后坐、炮口火光、命中闪、击杀节奏都要验证。

---

## 2. 护甲 `armor`（6）—— 决定 base_hp 与减伤/抗性

护甲字段：`base_hp_add, dmg_reduce, resist_element, special, rarity, max_level`。

| ID | 名称 | 侧重 | 特性 |
|---|---|---|---|
| `armor_kevlar` | 凯夫拉护甲 | 高 base_hp | 纯堆基地血，通用 |
| `armor_reactive` | 反应装甲 | 减伤% | 越线伤害整体减免 |
| `armor_thermal` | 隔热护甲 | 抗火 | 对火属性越线伤害大幅减免（克 inferno_maw） |
| `armor_cryo` | 防冻护甲 | 抗冰 | 减少被冻类机制影响 + 抗冰伤（克 frost_warden 的冻塔） |
| `armor_faraday` | 法拉第护甲 | 抗雷 | 抗雷伤 + 减少麻痹（克 storm_caller） |
| `armor_hazmat` | 防化护甲 | 抗毒 | 抗毒伤 + 免疫毒池减益（克 plague_mother） |

设计要点：
- 抗性护甲与 Boss 免疫机制对应（见 `07`/`08`）——玩家可针对性换甲，体现"准备"乐趣。
- 强化护甲主要提升 `base_hp_add` 与 `dmg_reduce`。
- 护甲不是"必须穿对否则失败"的钥匙，而是容错和满星工具。普通关不要求特定护甲，Boss 关才明显奖励针对性准备。

---

## 3. 芯片 `chip`（8）—— 2 槽，自由组合派生属性

芯片字段：`stat_type, value_per_level, rarity, max_level`。纯数值模块，无弹道改变。

| ID | 名称 | 加成 |
|---|---|---|
| `chip_attack` | 攻击芯片 | +ATK% |
| `chip_health` | 生命芯片 | +base_hp% |
| `chip_crit` | 暴击芯片 | +暴击率 / +爆伤 |
| `chip_haste` | 急速芯片 | +攻速 |
| `chip_pierce` | 穿甲芯片 | +穿透 + 无视部分护甲怪减免 |
| `chip_element` | 元素芯片 | +指定元素增伤（安装时选元素） |
| `chip_greed` | 贪婪芯片 | +金币掉落（经济向，不进战力平衡） |
| `chip_guardian` | 守护芯片 | +减伤 / 基地越线伤害延迟结算 |

设计要点：
- 2 个芯片槽 = 玩家微调流派的"调料"（如雷流配 chip_element(雷) + chip_haste）。
- 经济芯片 `chip_greed` 与战力芯片二选一，制造"刷钱 vs 战力"的取舍。
- `chip_pierce`、`chip_guardian` 也是反挫败工具：当玩家卡在装甲/漏怪关时，不必只靠换角色解决。

---

## 4. 宝宝 `pet`（6，辅助槽）—— 有自己的攻击与技能

> 这就是你说的"辅助 = 宝宝/宠物"：独立 AI，自动攻击 + 自带技能，跟随炮塔作战。
> 宝宝字段：`atk_coef, attack_type, element, pet_skill, rarity, max_level`。

| ID | 名称 | 攻击 | 自带技能 | 元素 |
|---|---|---|---|---|
| `pet_turret_drone` | 机枪无人机 | 自动点射最近敌人 | 过热爆发：周期性高速扫射 | 物理 |
| `pet_fire_imp` | 火灵 | 抛火球 | 引燃：命中区域留小火海 | 火 |
| `pet_frost_wisp` | 霜灵 | 冰锥点射 | 寒域：周期对前方群体减速 | 冰 |
| `pet_volt_orb` | 电球 | 随机电击场上敌人 | 过载：短时连锁电全场 | 雷 |
| `pet_medic_drone` | 医疗无人机 | 无直接攻击 | 修复：缓慢回复基地血量 | — |
| `pet_collector` | 拾荒机器人 | 弱点射 | 磁吸：自动收集全场金币 | 物理 |

设计要点：
- 宝宝提供"第二输出源 + 功能位"，与主流派**互补**（如火流配 frost_wisp 补控、肉龟流配 medic_drone 补血、刷钱配 collector）。
- 宝宝元素可独立于主炮，给"双元素覆盖"的搭配空间（应对部分免疫怪）。
- 强化宝宝提升 `atk_coef` 与技能效果（冷却/范围）。
- 宝宝遵循目标策略，但保留少量自主 AI：默认补刀越线威胁和低血怪，玩家锁定目标时优先协同集火。

---

## 5. 强化曲线（概览，绝对数值见 `09`）

- 每件装备 `level` 从 1 到 `max_level`（白30 / 绿40 / 蓝50 / 紫60 / 橙70 量级，可调）。
- 强化消耗金币随等级**分段递增**（每 10 级一个台阶，台阶处消耗跳升）。
- 效果提升以"线性为主、关键里程碑（每10级）小跳"为辅，保证可预期。
- **建议等级对齐**：每关的"建议等级"对应一套"核心装备应强化到的大致档位"，`09` 给出对照表，确保按节奏养成即可推进。

## 6. 获取与解锁汇总

| 来源 | 给什么 |
|---|---|
| 默认 | autocannon + kevlar + 基础芯片 + turret_drone |
| 金币商店 | 物理系主炮、基础护甲/芯片（直接买，再用金币强化） |
| 星解锁 | 元素主炮、抗性护甲、稀有芯片、稀有宝宝 |
| 关卡掉落 | 首通/三星掉落装备或强化材料（`skill_gold_rush` Y / `chip` 可提升掉率） |
| 皮肤 | 纯外观，星盈余消费（见 `02`/`11`） |
