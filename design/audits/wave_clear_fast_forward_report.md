状态：通过（PASS）

# 清场快进（wave_clear_fast_forward）实现与验证报告

Owner 痛点复现：输出（DPS）越高，多首领波里前一个首领死得越快，后一个首领却仍按 `levels.json` `runtime_bosses[].spawn_delay` 这份**固定于波次开始时刻、与清场状态无关**的时间表出场（部分关卡权重高达 65~73 秒），玩家在场上无敌可打，尬等到时间表兑现。本次改动只针对这一具体机制做"清场快进"：场上确实打空、且已过 `breather_seconds` 缓冲后，允许下一只已进入等待阶段的首领提前出场；从未提前于原定时间表，关闭开关时逐帧行为与改动前逐位一致。

---

## 1. 实现要点

**数据开关**（`data/economy.json`，新增顶层键，默认关闭）：

```json
"wave_clear_fast_forward": {
    "enabled": false,
    "breather_seconds": 3.0
}
```

**逻辑**（`gameplay/battle/battle.gd`）：

- 新增三个状态：`wave_clear_fast_forward_enabled`、`wave_clear_fast_forward_breather`（`_ready()` 时从 `economy.json` 读取，键缺失时退回禁用+3.0 秒默认值）、`_wave_clear_fast_forward_clear_at`（"场上最近一次变空"的时间戳，-1.0 表示"当前非空或尚未变空过"）。
- `_spawn_enemy_instance`：新增敌人挂到 `$EnemyLayer` 后立即把 `_wave_clear_fast_forward_clear_at` 置回 `-1.0`——只要场上有东西，"清场"状态就作废，避免用一个过期的"很久以前清过场"时间戳误判当前仍在清场。
- `_on_enemy_died`：在 `_resolve_death_mechanic` / `_apply_inferno_death_spread`（可能在死亡时再刷出新敌人，例如"split"机制）**之后**判断 `_has_live_enemies()`，为空则记录 `_wave_clear_fast_forward_clear_at = _gameplay_now_seconds()`。用的是既有的 `_gameplay_now_seconds()`（审计模式下走确定性的 `battle_elapsed_seconds`，生产环境走真实墙钟），这是本仓库对"影响战斗结果的计时"的既定规范（同一函数已用于付费套装冷却等）。
- `_process_spawns`：在原有 `spawn_timer -= delta` 之后、`if spawn_timer > 0: return` 之前插入一支新分支，只在开关打开、场上确认清空过、`pending_spawns` 非空时调用 `_apply_wave_clear_fast_forward(pending_spawns[0])`。
- `_apply_wave_clear_fast_forward(front_item)`：只处理"正处在 `spawn_delay` 等待阶段的首领"（`boss == true` 且 `_spawn_delay_consumed == true`，即 `runtime_bosses` 里那颗仍在倒计时的下一只首领）。计算 `earliest_remaining = max((clear_at + breather) - now, 0)`，若比原定剩余时间更短才生效（`spawn_timer = min(spawn_timer, earliest_remaining)`，用提前 return 实现，结构上不可能增大 `spawn_timer`）。首次真正提前时打一条一次性 HUD 短提示。
- `_start_next_wave`：波次切换时把 `_wave_clear_fast_forward_clear_at` 复位为 `-1.0`（防御性；实际上敌人刷新钩子已经覆盖了这个情形，这里是双保险，避免"上一波清场时间戳"串到下一波的等待判断里）。

**任务简报公式的偏差说明（需要向 owner 说明的判断）**：任务简报写的是"改为 `max(原定时间, 前一只死亡时刻 + breather_seconds)`"。按字面在绝对时间上取 `max`，会得到"越晚越保留"的结果——对快速清场的情况完全不会提前（`max(65, 13) = 65`），对慢速清场反而会把首领推迟到比原计划更晚（`max(65, 83) = 83`），这与同一段话里的硬约束"**只提前不推迟，慢构筑的行为必须逐位不变**"直接矛盾。已按这条硬约束反推出唯一自洽的公式并按其实现：`新出场时间 = min(原定时间, 前一只清场时刻 + breather_seconds)`，用代码里的 `spawn_timer = min(spawn_timer, earliest_remaining)` 落地。第 2、3 节的逐位等价与全量影响面数据均据此验证通过；如果 owner 确实是想要字面的 `max`，请回头指出，我可以按更正后的公式重新实现和重新验证。

**HUD 提示**：快进真正生效时（首次把等待时间钳到比原计划更短）弹一条短横幅"首领提前来袭"，走本地化，不写死中文——`data/localization_gameplay_en.json` 新增 `"首领提前来袭": "Boss Incoming Early"`，复用项目既有的"中文源串 + `TranslationServer` 反查模板"机制（`tools/check_localization.py` 校验通过：589→590 条精确消息，1136→1137 条运行时中文源串）。

**红线自查**：只改了 `data/economy.json`（新增键）、`gameplay/battle/battle.gd`、`data/localization_gameplay_en.json`、`tools/m1_smoke_test.gd`；未碰任何关卡/经济平衡数值、`tools/` 下的探针与合同工具、meta/loadout、meta/result；未引入对象池/贴花/VFX 相关代码；未改任何门禁阈值。

---

## 2. 关闭态逐位等价证据（硬门槛）

方法：在本 worktree 里用 `git stash` 把改动的四个文件（`economy.json` / `battle.gd` / `localization_gameplay_en.json` / `m1_smoke_test.gd`）临时移出，对纯净基线（commit `f8361dfb`）跑一遍探针，`stash pop` 恢复改动后（开关仍是出厂默认 `false`）再跑一遍，逐字段 diff（不止任务列出的字段，而是结果行里的**全部**字段）。

```
python3 tools/run_frontline_sweep.py --levels 86,90 --seeds 2207,1103 --profile tier_b --card-policy v2 --accel 60 --jobs 2 --output before_closed_state.json   # git stash 状态（纯净基线）
python3 tools/run_frontline_sweep.py --levels 86,90 --seeds 2207,1103 --profile tier_b --card-policy v2 --accel 60 --jobs 2 --output after_closed_state.json    # stash pop 后（本改动，开关默认关闭）
```

结果（同一会话、同一机器背靠背跑出，覆盖任务要求的 level_086/seed 2207、level_090/seed 1103，外加 level_086/seed 1103、level_090/seed 2207 两组加测）：

```
level=086 seed=1103: OK (bit-exact) victory=True elapsed=157.250000000017
level=086 seed=2207: OK (bit-exact) victory=True elapsed=155.850000000016
level=090 seed=1103: OK (bit-exact) victory=True elapsed=214.266666666729
level=090 seed=2207: OK (bit-exact) victory=True elapsed=149.150000000011

ALL BIT-EXACT
```

`victory` / `max_progress` / `base_ratio` / `wave_timeline` / `card_timeline` / `boss_phase_seconds` / `elapsed_seconds` 及其余全部字段，四组全部逐位相同——关闭态代码路径没有泄漏任何新分支的影响。

**附带发现（未纳入门槛判定，仅记录）**：同参数、同两关同种子拿去与仓库里更早归档的 `design/audits/determinism_v22_full99x3_postfix.json` 比对时，`elapsed_seconds` 等字段**不**逐位相同（例如 level_090/seed_2207：本次两次背靠背运行都是 149.15，归档文件是 162.08）。由于本次的 before/after 是同一会话临时用 `git stash` 切换出来的、环境和 Godot 二进制完全一致，因此这不影响第 2 节的结论；但如果 owner 关心"探针结果能否跨会话/跨时间复现"，这个差异值得单独排查（很可能是归档文件生成时的环境/引擎版本差异，本次未深入，超出本任务范围）。

---

## 3. 开启态影响面（全 99 关 × 3 种子）

方法：把 `data/economy.json` 的 `wave_clear_fast_forward.enabled` 临时改成 `true`，用同一命令跑满 99 关 × 3 种子（`1103/2207/3301`），与关闭态（第 2 节同一份 297 组基线）逐组对比后，把开关改回 `false` 提交。

```
python3 tools/run_frontline_sweep.py --levels 1,2,...,99 --profile tier_b --card-policy v2 --accel 60 --jobs 10 --output off_full99x3.json   # enabled=false（出厂默认）
python3 tools/run_frontline_sweep.py --levels 1,2,...,99 --profile tier_b --card-policy v2 --accel 60 --jobs 10 --output on_full99x3.json    # enabled=true
```

（第一次 `on` 跑批在 level_011/seed_1103 处进程异常退出——单独用同一命令重放这一关/种子立即成功，且失败点是台无 `runtime_bosses` 的普通关，逻辑上不会命中本功能的任何新分支；判断为并行 10 个 Godot 进程时的一次性资源/环境抖动，重跑整批后 297 组全部正常完成，未再复现。）

对比结果（297 组，逐组四项）：

1. **胜负翻转：0** —— 无任何一组 `victory` 发生变化。
2. **超时变化：0** —— 无任何一组 `timeout` 发生变化。
3. **关卡时长缩短分布**：
   - 297 组胜利对局里，只有 8 组（都在 level_085 / 095 / 099）出现 >0.05 秒的可观测缩短，其余 289 组缩短为 0（这些关卡要么没有 `runtime_bosses`，要么其 `spawn_delay` 相对该档位的清怪速度本就不构成尬等）。
   - 全部 297 组的中位数缩短 = **0.00 秒**（多数关卡无影响）；受影响的 8 组中位数缩短 = **28.42 秒**；**最大缩短 = 49.47 秒**（level_095 / seed 1103，该关唯一一颗 `runtime_bosses` 的 `spawn_delay` 原authored 65 秒，正是 owner 描述的"尬等半分钟"级别的关卡）。
   - 受影响关卡明细：
     | 关卡 | 种子 | 缩短(秒) |
     |---|---|---|
     | level_085 | 2207 | 7.72 |
     | level_085 | 3301 | 11.90 |
     | level_095 | 1103 | 49.47 |
     | level_095 | 2207 | 35.20 |
     | level_095 | 3301 | 30.72 |
     | level_099 | 1103 | 19.27 |
     | level_099 | 2207 | 26.12 |
     | level_099 | 3301 | 31.40 |
   - **没有一组出现时长增加**（哪怕是浮点噪声级别的极小增加），与"只提前不推迟"的设计约束在全量数据上吻合。
   - level_090（唯一延迟仅 10 秒的单首领关）三个种子缩短全为 0——tier_b 档位清 boss1 本身就要 10 秒以上，说明该关在这个战力档位原本就不构成尬等，快进功能没有"多管闲事"。
4. **档位（三星门槛）跌档清单：0 关** —— 用 `base_ratio` 按 `StarRules`（三星 ≥0.7，两星 ≥0.35）复算，297 组里没有任何一组开启后的档位低于关闭态。

**验证脚本**：`tools/run_frontline_sweep.py` 逐位输出，比对脚本为本次任务临时编写、未纳入仓库（`compare_closed_state.py` / `compare_open_state.py`，只读关闭/开启两份 JSON 求 diff，不改变探针本身）。

---

## 4. `tools/m1_smoke_test.gd` 新增断言

新增 `_verify_wave_clear_fast_forward(data_loader, save_manager)`，紧跟在 `_verify_endgame_pressure_ramp` 之后调用，覆盖：

1. 数据键存在性 + 出厂默认值（`enabled == false`、`breather_seconds > 0`）；
2. 一个刚 `setup()` 完的 `battle` 实例确实从 `economy.json` 解析出禁用默认值；
3. **关闭态等价护栏**：给一个"正在等待 `spawn_delay` 倒计时"的首领队列项挂上清场时间戳，开关关闭时 `spawn_timer` 严格只按 `delta` 递减、队列项完全不受影响——与第 2 节的整局证据互为交叉验证，但粒度精确到单次 `_process_spawns` 调用；
4. **开启态生效**：同样场景开关打开后，等待时间被钳到 `breather_seconds` 附近而非原定的约 10 秒，且时间耗尽后确实触发真实出怪（`pending_spawns` 清空）；
5. **"慢构筑不变"护栏**：开关打开但从未记录过清场（场上仍占着）时，等待时间与关闭态完全一致；
6. 敌人刷新会让过期的清场时间戳失效（`_wave_clear_fast_forward_clear_at` 变回 `-1.0`），`_has_live_enemies()` 如实反映场上状态。

用 `godot --headless --script res://tools/m1_smoke_test.gd --` 单独跑通，本函数无任何 `_expect` 失败。

**观察到但未处理的既有问题（超出本任务范围，未改动）**：`m1_smoke_test.gd` 在本函数之后的 `_verify_character_active_skill_controls`（"frost signature levels must strengthen slow"）会失败；已用 `git stash` 确认这在改动前的纯净基线上同样失败，与本功能无关，未做任何改动。

---

## 5. 默认开 / 默认关 建议

**本次交付：默认关闭**（`enabled: false`），这是任务的硬性要求，也已在第 2 节验证"关闭态与改动前逐位一致"。

**后续建议：条件成熟后默认打开**，理由：

- 全量 99×3 数据显示这是一次严格意义上的正向改动——零胜负翻转、零超时变化、零档位跌档、且从未让任何一局变慢（第 3 节）。数学上 `min(原定时间, 清场时刻+breather)` 结构性地保证了这一点，不依赖抽样运气。
- 影响面精确收敛到 owner 抱怨的那三关（085/095/099，恰是 `runtime_bosses[].spawn_delay` authored 最大的几关），其余 96 关行为不受任何影响——功能没有"顺手"波及不该管的关卡。
- 唯一保留意见：本次验证只覆盖了 `tier_b` / `card-policy v2` 这一组合（任务模板指定的组合）。`min(...)` 公式本身与档位无关（纯粹取决于实际清场时刻），理论上对 `control`/`tier_a` 档位或 legacy 卡池同样只会提前不会推迟，但没有实测数据支撑，建议正式切换默认值前补一轮其他档位的抽样复核，或者先以远程开关小流量验证一版再全量打开。
