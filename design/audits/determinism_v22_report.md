# 确定性修复报告 v22

**状态：通过（PASS）。** 两个已实锤复现用例（level_086/seed 2207、level_090/seed 1103）串行各跑两次，结果层全字段逐位一致，`damage_total` 差值为 0（严于 ≤1e-9 门槛）；额外抽测 6 关 × 3 种子（51/59/66/80/90/95 × 1103/2207/3301）共 18 组 A/B 全部逐位一致；全 99 关 × 3 种子的确定性修复前后对比中，**victory 与档位（grade）零翻转**。战术语义未改，未触碰任何数值/关卡/经济数据/门禁阈值。

---

## 1. 病根定位

复现命令（按任务模板）：

```
python3 tools/run_frontline_sweep.py --levels 86 --seeds 2207 --profile tier_b --card-policy v2 --accel 60 --jobs 1 --output /tmp/det_a.json
```

同关同种子串行连跑两次，`base_damage_taken` 在 337 与 343 之间摆动，`elapsed_seconds` 相差超过 1 秒（约 66 个物理 tick），`damage_total` 相差约 150（而非浮点噪声级的 1e-9），且从第 4 波结束起两次运行完全一致、只在第 5 波内部某一 tick 开始分叉——说明这不是浮点求和顺序噪声，而是**某个"选目标"决策在两次运行里选出了不同的敌人**，随后战局蝴蝶效应发散。

用一次性调试插桩（对 `frame_enemies` 按 `audit_spawn_index` 排序后逐 tick dump 每个敌人的 hp/position 并 diff 两次运行）精确定位：两次运行从头到 `t=156.150000`（第 5 波）为止逐 tick 完全一致，该 tick 上仅有一只敌人的 hp 不同（多吃了一次范古德"弹幕齐射"主动技能的命中），其余敌人分毫不差。

追到代码：`gameplay/battle/battle.gd` 的 `_active_target_candidates()`（范古德"弹幕齐射"/所有角色主动技能的目标排序）从**未排序**的 `$EnemyLayer.get_children()` 建候选表，按 `score` 用严格 `>` 排序、**没有并列打破规则**。当两只敌人（常见于同一波刷出、处在同一深度线的僵尸群）打分严格相等时，排序结果依赖 `Array.sort_custom` 在未排序输入下的行为——而 `$EnemyLayer` 的原始子节点顺序**不保证**在两次逐位相同种子的运行间保持一致（敌人死亡后代码会在审计模式下立即 `remove_child`，与生产环境的延迟释放语义不同，具体表现为子节点数组的相对顺序在增删过程中并非严格稳定）。于是"打平的两只敌人谁排第一"在两次运行里可能不同，谁排第一谁就被主动技能多命中一次，蝴蝶效应发散出不同战局。

同一类缺陷在审计基础设施里其实早有先例：`gameplay/projectile/projectile.gd` 里几乎所有目标选择（`_nearest_enemy`、`_best_pierce_retarget`、`_enemy_candidates` 等）都已经在打平时显式按 `audit_spawn_index`（敌人出生顺序，赋值发生在確定性的出怪时刻，与内存地址/物理引擎顺序无关）兜底；`battle.gd` 里 `frame_enemies`/`_audit_target_score_less`/`_audit_enemy_precedes` 等也已经做了同样的事。**`_active_target_candidates` 和另外几处是这套基础设施里被漏掉的角落**，本次逐一找出并补齐（见第 2 节）。

任务背景猜想的"物理重叠查询顺序依赖内存地址"并不成立——审计后确认 `gameplay/` 与 `core/` 下没有任何 `get_overlapping_bodies/areas`、`intersect_shape/point/ray` 调用；`projectile.gd` 唯一会用到 Area2D 物理信号的路径（`body_entered`/`area_entered`）在审计模式下会被 `set_audit_deterministic_collisions(true)` 整体旁路，改用显式的线段-圆求交 + `audit_spawn_index` 打平（`_audit_resolve_collision`），这部分本来就是确定性的。真正的病根是**"选目标"环节遗漏的并列打破规则**，以及下面第 1.1 节另一条独立病根。

### 1.1 第二病根：墙钟时间污染确定性时钟（付费"末日"套装专属）

审计过程中在 `battle.gd` 里发现 8 处用 `Time.get_ticks_msec()`（真实操作系统墙钟毫秒数）而非模拟时钟 `battle_elapsed_seconds` 来给**影响真实战斗结果**的冷却计时：

- `_apply_apocalypse_inferno_on_hit`（燃烧引爆 combustion）
- `_apply_apocalypse_absolute_zero_on_hit`（碎裂粉碎 shatter）
- `_apply_apocalypse_golden_law_on_hit`（黄金裁决 verdict，含读取"天隼敕印"标记窗口）
- `_activate_pet_golden_mark`（天隼宠物技能写入"天隼敕印"窗口截止时间）
- `_apply_apocalypse_armor_counter` / `_apply_apocalypse_inferno_armor_counter` / `_apply_apocalypse_absolute_zero_armor_counter` / `_apply_apocalypse_golden_law_armor_counter`（四种护甲流派反击，命中后真实扣血 + 回复 base_hp）

这些函数都是"计数器攒到阈值后，检查一个墙钟绝对截止时间戳，没到就不触发"的模式（`apocalypse_armor_counter_cooldown` 等变量**不在** `_physics_process` 里逐 tick 用 `real_delta` 衰减，而是存一个 `now + authored_cooldown` 的绝对时间戳），与同文件里已经写对的模板（`_process_kill_feedback` 第 10463 行：`battle_elapsed_seconds if _audit_combat_rng != null else Time.get_ticks_msec()...`）形成鲜明对比——后者已经在审计模式下切到模拟时钟，前 8 处没有跟进。

这组 bug 不是本次两个已实锤复现用例的直接病根（详见第 4 节：两个复现用例的装备都不触发付费套装分支），但同属"审计模式下必须用确定性时钟"的同类问题，一并修复。

---

## 2. 修改内容（全部在 `gameplay/battle/battle.gd`；`core/` 未改动）

### 2.1 墙钟时间 → 确定性时钟（8 处 + 1 个新增辅助函数）

新增 `_gameplay_now_seconds()`：审计模式（`_audit_combat_rng != null`）下返回 `battle_elapsed_seconds`（模拟时钟），否则回退到原有 `Time.get_ticks_msec()/1000.0`（生产环境行为完全不变）。替换以下 8 处的 `Time.get_ticks_msec()/1000.0`：

`_apply_apocalypse_inferno_on_hit`、`_apply_apocalypse_absolute_zero_on_hit`、`_apply_apocalypse_golden_law_on_hit`、`_activate_pet_golden_mark`、`_apply_apocalypse_armor_counter`、`_apply_apocalypse_inferno_armor_counter`、`_apply_apocalypse_absolute_zero_armor_counter`、`_apply_apocalypse_golden_law_armor_counter`。

纯表现层的墙钟读取（截图特效节流、音效防抖、浮空字提示、手动锁敌等 UI 输入路径、角度呼吸动画）**未改动**，逐处确认过它们只驱动视觉/音频，不回写任何影响战斗结果的状态（详见第 5 节清单）。

### 2.2 目标选择并列打破规则（本次复现用例的直接病根 + 同类扩查）

对以下每处"从原始 `$EnemyLayer.get_children()` 建候选表 → 按分数/距离/y 坐标严格不等式选最优"的代码，在**分数/距离相等时**（`is_equal_approx`）追加按 `audit_spawn_index`（敌人确定性出生序号）打平，非审计模式下行为不变（保持"数组里先出现的赢"的既有生产语义）：

- `_active_target_candidates`（**范古德"弹幕齐射"等全部角色主动技能的目标排序，本次复现用例的直接病根**）
- `_multi_shot_target_candidates`（多重射击/追踪弹的分道目标打分）
- `_homing_target_assignments`（追踪弹目标指派：候选表建好后按 `audit_spawn_index` 整体排序一次，而非逐处打平，因为下游 `_best_homing_candidate_index` 本身没有打平规则，排一次即可让它的"数组里先出现的赢"变成确定性的）
- `_process_frost_glacier`（冰霜"冰川领域"AOE 遍历顺序，属于第 3 节"伤害累加顺序"一类）
- `_densest_apocalypse_target`（付费套装"冰晶波"取densest目标）
- `_apply_apocalypse_inferno_on_hit` 的 combustion 候选（`_audit_distance_candidate_less` 新辅助函数）
- `_apply_apocalypse_absolute_zero_on_hit` 的 shatter 候选（同上辅助函数）
- `_apply_absolute_zero_crystal_wave` 的候选（同上）
- `_apply_golden_law_decree`（y 坐标排序，新增内联打平）
- `_apply_inferno_death_spread`（距离排序，`_audit_node2d_metric_less` 新辅助函数）
- `_apply_apocalypse_inferno_armor_counter` / `_apply_apocalypse_absolute_zero_armor_counter` 的护甲反击目标（距离平方排序，同上辅助函数）
- `_apply_apocalypse_golden_law_armor_counter`（y 坐标排序，内联打平）

新增两个共享辅助函数（紧邻既有的 `_audit_target_score_less`/`_audit_enemy_precedes` 之后）：`_audit_distance_candidate_less(a, b)`（`{"target":Node,"distance":float}` 字典形状）、`_audit_node2d_metric_less(left, right, left_metric, right_metric)`（裸 `Node2D` 对 + 外部算好的度量值）。两者都遵循既有约定：先按数值比较，`is_equal_approx` 相等时若不在审计模式直接判负（保留生产环境原顺序），审计模式下按 `audit_spawn_index` 兜底。

**战术语义未变**：原来选分最高/最近/y 最深的规则完全保留，打平规则只在"两者严格相等"时才生效，且只在审计探针（`_audit_combat_rng != null`）下启用；生产环境（真实玩家对局）分毫不受影响。

### 2.3 随机源分流审计（结论：无需改动）

`grep -rn "randf\|randi\|randomize\|RandomNumberGenerator" gameplay/ core/` 逐条过了一遍（battle.gd 约 100 处、enemy.gd 约 10 处、projectile.gd/其余 gameplay 文件、core/ 全部）。除了已经走 `_combat_randf()/_combat_randf_range()`（`_audit_combat_rng` 在审计模式下播种、`card_director.gd` 自带 `_audit_rng`）的伤害/暴击/出怪位置/技能触发几率外，所有裸 `randf()/randf_range()` 都逐个确认只喂给了：粒子抖动、贴花角度、受击后精灵回弹偏移、音效音高变化、浮空字/技能环特效的位置扰动、纯 UI 提示的触发几率（如"弱点装填"浮字、武器过载光环——只影响是否弹一条浮字，不影响伤害数值）。这些视觉/音频随机源本身消耗的是 Godot **全局** RNG 流（探针入口 `frontline_runtime_probe.gd` 第 206 行 `seed(seed_value + 17000033)` 已经把它也播了种，同种子下这部分本身也是逐位可复现的），且与 `_audit_combat_rng` 是两条独立流，互不干扰，不会反馈进伤害/命中/出怪等逻辑状态。**未发现"视觉随机污染逻辑随机"的实例，本条无需改动。**

### 2.4 伤害累加顺序（结论：已发现的唯一实例已修复，未做穷举式改造）

`_process_frost_glacier`（冰霜法系"冰川领域"）遍历未排序的 `$EnemyLayer.get_children()` 对范围内全部敌人累加伤害——命中的敌人集合本身由位置阈值决定、与遍历顺序无关，但 `take_damage()` 调用顺序会影响 `battle_report.damage_total` 等累加器的浮点求和顺序（对应任务描述里 level_090 那种"时间线一致但 damage_total 有 1e-5 量级漂移"的症状类别）。已加排序修复（见 2.2）。

**未做的部分，如实说明**：`blaze`（烈焰）meltdown、`volt`（雷霆）storm 等其余三个角色的主动技能 AOE 也有类似"遍历 `$EnemyLayer.get_children()` 对范围内敌人挨个调 `take_damage`"的写法，理论上有同一类量级的浮点顺序噪声风险。**未逐一修改**，原因：①标准回归夹具（`design/audits/campaign_progression_fixture_builds.json`）全 99 关 × 全部 build 的 `character` 字段固定为 `vanguard`，这些函数在现有回归管线里**不可达**，改了也验证不到；②这类顺序噪声在任务本身的描述里就是 1e-9~1e-5 量级的浮点尾数漂移，不改变胜负/档位判定；③避免在验证不到的路径上大改动引入新风险，符合任务"停下来在报告里写明,不要强改"的纪律。如果后续要把 blaze/frost/volt 三个角色纳入回归夹具，建议同一批把这几处也补上 `audit_spawn_index` 排序，模式与本次修复完全一致。

---

## 3. A/B 逐位一致证据

全部使用 `tools/run_frontline_sweep.py`（`--jobs 1` 为串行，其余按任务模板），修复后代码，同关同种子跑两次，对比 `victory / max_progress / base_ratio / wave_timeline / card_timeline / boss_phase_seconds / kills / elapsed_seconds / battle_report`（含 `damage_total`）全字段：

| 用例 | 结果 | 证据文件 |
|---|---|---|
| level_086 / seed 2207，串行 ×2 | **全字段逐位一致**，`damage_total` 差值 = 0 | `design/audits/determinism_v22_det_l86_2207_a.json` / `_b.json` |
| level_090 / seed 1103，串行 ×2 | **全字段逐位一致**，`damage_total` 差值 = 0 | `design/audits/determinism_v22_det_l90_1103_a.json` / `_b.json` |
| 6 关（51/59/66/80/90/95）× 3 种子（1103/2207/3301），共 18 组，×2 | **18/18 组全字段逐位一致** | `design/audits/determinism_v22_spot6x3_a.json` / `_b.json` |

修复前（HEAD，同一套代码栈，仅 `git checkout -- gameplay/battle/battle.gd` 回退本次改动）用同样方式复测 level_086/seed 2207：同一二进制连续多次运行会在两种稳定结果间摆动（`base_damage_taken` 337 或 343，`elapsed_seconds` 相差约 1.1 秒），证实修复前的非确定性是真实存在、可重复触发的，而不是本次验证环境的偶发噪声。

---

## 4. 协调者追加问题：加速档历史平衡数据是否被系统性影响

### ① 受影响系统范围

**结论：截至本次审计，仓库里没有任何一份已生成的平衡/DPS 数据是通过"墙钟冷却 bug"这条代码路径产出的——影响面为零，但风险是真实存在的，仅仅是因为现有工具链从未凑齐触发条件。**

第 1.1 节的 8 处墙钟冷却，全部挂在武器 `visual_profile`/护甲 `effect_profile` 等于 `apocalypse_inferno`/`apocalypse_absolute_zero`/`apocalypse_golden_law`（及对应护甲反击 profile）、或宠物"天隼"金印技能这几个**付费末日套装专属**分支下，普通/免费装备完全走不到这几个函数内部。逐一核对了仓库里所有会真正跑 Godot 战斗运行时的入口：

- **`tools/run_frontline_sweep.py` → `frontline_runtime_probe.gd`**（本次任务用来验证、`design/audits/b2b_final_ch1~ch5_tier_b_*.json`/`campaign_frontline_baseline.csv` 等既有基线背后的同一套探针）：夹具来源 `design/audits/campaign_progression_fixture_builds.json` 全 99 行 `build.weapon` 只有 `weapon_autocannon`/`weapon_scattergun`/`weapon_venomlauncher`，`build.armor` 只有 `armor_kevlar` 或空，`build.pet` 只有 `pet_turret_drone` 或空，`build.character` 全部是 `vanguard`——没有一行触碰任何付费末日套装 ID。**这条管线产出的全部历史数据与本 bug 无关。**
- **`tools/audit_inferno_premium_dps.py`、`audit_absolute_zero_premium_dps.py`、`audit_golden_law_premium_dps.py`**（唯一会评估付费末日套装数值的三份工具）：读代码确认它们是纯 Python 闭式公式计算器（`damage * target_equivalents / skill["cooldown"]` 这类），**完全不调用 Godot、不跑 `battle.gd` 里的任何一行代码**，自然也碰不到这个 bug。
- **`tools/audit_physical_endgame_runtime.gd`**（另一个真正跑 Godot 战斗运行时的 DPS 基准，`SIM_TIME_SCALE=5`，用到 `skill_multishot`/`skill_homing`/`skill_ricochet`）：武器集合固定为 `weapon_autocannon`/`weapon_railgun`/`weapon_scattergun`（免费），同样碰不到付费套装分支；另外它从未调用 `set_audit_combat_seed`，根本没进入 `_audit_combat_rng != null` 的审计确定性路径，因此第 2.2 节的目标排序修复对它也不生效——它是一条完全独立、本次改动既不修也不破的路径（它自带 `BENCHMARK_TOLERANCE := 0.06` 的容差设计，说明作者本就知道这条路径有自己的一套非确定性来源，与本报告的 bug 无关）。

② 提到的 8 处目标排序打平（第 2.2 节）**不是**加速档相关的问题，而是纯粹的"打平规则缺失"，在任意加速倍率（含 1x）下都可能触发。这一类里，`_active_target_candidates`（角色主动技能）、`_multi_shot_target_candidates`（多重射击/追踪）、`_homing_target_assignments`（追踪指派）三处**是**标准免费夹具会走到的路径——这正是第 1 节复现用例（`weapon_scattergun` + `skill_multishot`/`skill_homing` 等技能）实际踩中的病根。它的影响面见第 4③ 节的全量回归结果：本次修复前后对比，297 组里有 69 组（约 23%）的 `base_ratio`/`elapsed_seconds`/`wave_timeline` 有可观测差异（部分 base_ratio 差值达到 5~6 个百分点），但**没有一组跨越档位边界或胜负边界**（见④）。这说明历史上任何一次跑分都可能"恰好"落在这 bimodal（或更多分支）结果里的某一支上，**同一份基线数据用同一套旧代码重新跑一次也未必能逐位复现**，但从设计视角看其危害被限制在噪声量级，未构成已定档关卡的误判。

### ② 影响方向：偏难还是偏易

`Time.get_ticks_msec()` 读的是真实操作系统墙钟毫秒数，**不受** `Engine.time_scale`/`--fixed-fps` 虚拟化——加速档只是让每个渲染帧多塞几个物理 tick，实际执行这些 tick 仍然要吃掉真实 CPU 时间。本次实测：level_086 约 170 个游戏内秒，在负载较轻时用真实墙钟约 80 秒跑完（真实提速比约 2.1×，远低于命令行 `--accel 60` 名义的 60×）；系统负载较重时同一份工作曾超过 120 秒仍未跑完（提速比逼近或低于 1×）。这 8 处 bug 的模式是"计数器攒够后存一个 `墙钟now + 授权冷却秒数` 的绝对截止时间戳，下次 `墙钟now >= 截止时间戳` 才触发"，如果真的有人在加速探针下跑到这些付费套装分支，授权 1.4~9 秒的冷却将对应多得多的游戏内模拟秒数才会真正触发（且具体倍数随当时机器负载浮动，同一种子在忙机和闲机上可能触发次数都不一样）。**方向明确：只会让付费末日套装的爆发机制显得比真实 1x 表现更弱/更少触发，绝不会显得更强。** 由于①已确认历史上没有工具真正踩中这条路径，这是一条面向未来的风险提示，不是对现有数值的修正。

### ③ 修复后 99 关 × 3 种子回归清单

`design/audits/b2b_final_001_099_converged_tier_b_v21_10.json`（任务描述里点名的既有基线）在本 worktree 中**不存在**（已用 `find`/`git log --all` 确认：磁盘上没有、任何历史提交里都没有出现过这个文件名）。隔离要求禁止读取主仓库或其他 worktree，因此无法从别处取到它。作为最接近的替代证据，本次改用"同一套代码，仅 `gameplay/battle/battle.gd` 一个文件切换修复前/修复后"的方式，各跑一遍全 99 关 × 3 种子（`--jobs 10`，`design/audits/determinism_v22_full99x3_prefix_sample.json` 为修复前单样本、`determinism_v22_full99x3_postfix.json` 为修复后），按 `tools/audit_campaign_frontline.py` 里同一套档位阈值（`easy` / `light_pressure`（max_progress≥0.50）/ `pressure`（hp_ratio<0.999 且 max_progress≥0.80）/ `unwinnable`）重新分档对比：

- **胜负（victory）翻转：0 关**
- **档位（grade）翻转：0 关**
- 有可观测数值差异但未跨档位边界的对局：69/297（约 23%，差异集中在 `base_ratio`/`elapsed_seconds`/`wave_timeline`/`card_timeline`，`max_progress` 差值多在 1 个百分点以内，少数 `base_ratio` 差值到 5~6 个百分点）

**关卡清单：为空——本次对比没有发现任何一关的档位或胜负判定发生变化，因此没有清单可列。** 注：修复前样本本身是非确定性代码的单次抽样（同一 seed 理论上可能落在另一个稳定分支），不能 100% 代表"当年生成既有基线时的那一次运行"，且档位阈值里缺了原始 Python 模型的 `edge_reached→high` 分支（探针 JSON 没有等价字段），所以这个对比在"清晰台阶"边界上略保守；但鉴于①②已确认历史基线本就没有暴露在墙钟 bug 之下，②里 69/297 的差异全部来自本节③修复的目标排序 bug 而非墙钟 bug，且没有一次跨越档位边界，**主线判断为：不需要因为本次确定性修复而重验既有基线**。如果主线希望完全排除疑虑，建议保留的下一步是：用主线自己的既有基线文件（若能在正确的仓库位置找到）跑一次同样的分档对比。

---

## 5. 明确保留未改的墙钟读取（逐一确认为纯表现层，不反馈进战斗状态）

`_now_seconds()` 本体及其调用方（手动锁敌宽限期 `manual_aim_until`——探针从不模拟触屏手动瞄准输入，全程死代码；技能提示自动隐藏、卡牌长按检测——同样只在真实触摸输入下触发）、屏幕震动/受击暂停节流 `_trigger_impact_feedback`（`hit_stop.enabled` 在探针里被显式设为 false）、金币拾取音效/弱点击破浮字/威胁警告 toast 的节流、`_show_wave_toast` 节流、呼吸/心跳类 `sin(Time.get_ticks_msec()/...)` 缩放动画（角色贴图呼吸、宠物浮动、状态特效脉冲）、`_recent_impact_vfx_ms` 命中特效去重窗口。逐处读过实现，确认只喂 `VfxLib.screen_shake`/`AudioManager.play_sfx`/浮空字/UI 提示/贴图缩放，不写回 hp、伤害、位置、目标锁定等任何会被 `battle_report`/`wave_timeline` 记录的字段。

---

## 6. 提交

- 链一（确定性修复）：`gameplay/battle/battle.gd` 的第 2 节全部改动。
- 链二（验证证据 + 本报告）：`design/audits/determinism_v22_*.json`（8 份）与本文件。

两链均只涉及 `gameplay/`、`core/`、`design/audits/` 下本次新增的证据/报告文件，未触碰 `data/`、既有 `design/audits/*.csv`/其它 `*.json` 等任何数值或关卡/经济数据文件。
