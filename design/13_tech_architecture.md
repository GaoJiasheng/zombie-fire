# 13 · 技术架构

> 引擎 **Godot 4.x / GDScript**。一套代码导出 iOS + macOS（首发），预留 Web / Windows / Android。
> 原则：数据驱动、输入抽象、对象池、本地存档、可测可调。

## 1. 为什么是 Godot 4 + GDScript（决策记录）

| 候选 | 跨平台 | Web 导出 | 上架 | 结论 |
|---|---|---|---|---|
| Apple SpriteKit | 仅 Apple | ❌ | ✅ | 被"未来要 Web/Win/Android"否决 |
| Unity | 全平台 | ✅ | ✅ | 过重、有许可顾虑，2D 体验不如 Godot |
| Web(TS+Pixi)+套壳 | 全平台 | ✅(原生) | ⚠️ 审核略繁 | 游戏开发体验/原生流畅度不如 Godot |
| **Godot 4** | **全平台** | **✅(WASM)** | **✅** | **选定** |

GDScript 而非 C#：Godot 的 C# 对 **Web 导出**支持不完善，而我们要保留 Web → 用 GDScript 最稳、迭代最快、引擎集成最好。

## 2. 工程目录结构（`res://`）

```
res://
  project.godot
  main.tscn / main.gd                 # 入口、场景路由
  core/                               # 与玩法无关的基础设施
    input/  input_manager.gd          # 输入抽象（point/trigger，见 §4）
    target/ targeting_manager.gd      # 自动目标策略 + 手动锁定
    save/   save_manager.gd           # 本地存档（见 §7）
    data/   data_loader.gd            # 加载校验 res://data/*.json
    audio/  audio_manager.gd          # 三总线、并发上限、去重
    pool/   object_pool.gd            # 子弹/特效/敌人对象池
    scaling/ viewport_scaler.gd       # 窗口缩放/适配（见 §6）
  gameplay/
    battle/ battle.tscn / battle.gd   # 战斗主场景
    turret/ turret.tscn               # 炮塔（自动开火+瞄准）
    enemy/  enemy.tscn / enemy.gd     # 通用敌人（数据驱动行为）
    boss/   boss.tscn                 # Boss（继承 enemy + 阶段机）
    projectile/ projectile.tscn       # 子弹（穿透/分裂/弹射/追踪）
    pet/    pet.tscn                   # 宝宝
    skill/  skill_runtime.gd          # 局内技能/run_level
    skill/  card_director.gd          # 加权三选一/刷新/锁定/保底
    spawner/ wave_spawner.gd          # 读 levels.json 出怪
    vfx/    vfx_player.gd              # 序列帧/粒子
  meta/                               # 局外
    menu/ map/ loadout/ result/ character/ equipment/ shop/ settings/
  ui/                                  # 通用 UI 组件、HUD
  data/   *.json                       # 见 data/schema.md（运行时只读）
  assets/ (sprites/ vfx/ bg/ ui/ audio/ video/ fonts/)  # 见命名规范
  tools/   balance_check.gd / data_validate.gd          # 编辑器工具（见 §9）
```

## 3. 核心运行时模块

- **场景路由 main.gd**：在 menu/map/loadout/battle/result 间切换，持有全局单例（autoload）：`SaveManager / DataLoader / AudioManager / InputManager`。
- **battle.gd**：编排单局——加载关卡数据 → WaveSpawner 出怪 → 炮塔自动开火 → 技能运行时 → 结算。固定 60FPS（`physics_ticks` 60）。
- **enemy.gd 数据驱动**：从 `zombies.json` 读 `mechanic`，用策略表映射到行为脚本（armor/bomber/phantom/regen…），避免每种怪一个大类。
- **projectile**：弹道效果（pierce/split/ricochet/homing）由"主炮基础形态 + 携带技能修饰器"组合，统一在 projectile 上结算。
- **targeting_manager**：统一自动目标选择、手动锁定、策略切换、威胁提权；炮塔、追踪弹和宝宝都从这里拿目标，避免各打各的。
- **skill_runtime + card_director**：管理 5 槽、局内经验条、按节奏触发三选一、`run_level` 升级与分支；`card_director` 独立负责权重、刷新、锁定、保底（见 `03`/`09`）。

## 4. 输入抽象（两端同逻辑，关键）

`input_manager.gd` 把所有平台输入归一化为业务事件：
```
signal aim_point(world_pos: Vector2)   # iOS拖动 / macOS鼠标 → 同一事件
signal skill_pressed(slot: int)        # 点图标 / 数字键1-5
signal target_locked(enemy)            # iOS双击 / macOS右键
signal target_strategy_changed(strategy: String) # breach/elite/low_hp/nearest
signal ui_confirm / ui_cancel / pause
```
- 业务层只监听这些信号，**不关心是触屏还是鼠标** → iOS/macOS 行为完全一致（见 `10 §4`）。
- 平台检测：`OS.get_name()` / `DisplayServer.is_touchscreen_available()` 仅用于"是否显示鼠标 hover 提示、数字键说明"等表层差异。

## 5. 目标选择与卡牌导演

### TargetingManager

输入：敌人位置、速度、到防线距离、`threat_tag`、Boss 阶段、玩家锁定、当前策略。输出：当前优先目标。

```
score = distance_to_line_score
      + threat_tag_score
      + elite_boss_score
      + strategy_bonus
      + lock_bonus
      - immune_or_invalid_penalty
```

- 每 0.1s 更新目标分数，避免每帧全量排序。
- 手动锁定优先级最高，但若目标死亡/离屏/无效则自动取消。
- 追踪弹和宝宝可请求 `get_target(prefer_tag)`，但不能绕过全局锁定。

### CardDirector

输入：角色、已携带技能、空槽状态、关卡 `primary_weakness/threat_tags`、漏怪风险、最近出牌历史。输出：三张卡 + 可刷新/锁定状态。

- 权重计算与保底见 `09 §7`。
- 所有随机用可记录 seed，方便复现测试。
- 工具模式可跑 1000 次模拟，输出核心 build 成型率与连续烂牌次数。

## 6. 窗口缩放与适配（方案 A 等比，见 `10 §5`）

- `project.godot`：`display/window/stretch/mode = "canvas_items"`，`aspect = "expand"`，base 1080×1920；高屏 iPhone 向上扩展可见世界，底部防线保持锚定，禁止恢复会产生黑边的 `keep`。
- macOS：窗口 `resizable=true`，最小尺寸 ~405×720；记忆上次窗口尺寸/位置到存档。
- 等比缩放 = 大屏看到更大更清晰的**同一份**画面（不改游戏区域、不改难度）。
- iOS：全屏，按安全区（刘海/Home 条）内缩 UI；逻辑分辨率不变。
- 性能：渲染分辨率跟随逻辑分辨率，放大由 viewport 拉伸完成，不增加绘制成本。

## 7. 本地存档（持久化，关机重启不丢）

- 路径：`user://`（各平台映射到沙盒可写目录，App Store 合规）。
- 文件：`user://save_main.json`（主存档）+ `user://settings.json`（设置/窗口）+ 自动备份 `save_main.bak`。
- 写时机：每关结算、每次养成/强化/解锁、设置变更；**原子写**（写临时文件→rename）防损坏。
- 存档结构（见 `02 §6`）：
  ```
  { version, player:{gold,star}, characters:{<id>:{level,xp,talent_unspent,skill_base_levels,skill_branches}},
    equipment:{owned,levels,equipped}, unlocks:{characters,weapons,skills,skins},
    levels_progress:{<level_id>:best_stars}, challenge_progress:{...}, settings_ref }
  ```
- `version` 字段做迁移；读档失败回退备份。无云、无跨设备（v1）。

## 8. 性能预算（"不卡顿"是硬指标）

- 目标 **稳定 60 FPS**（iPhone 中端机、Apple Silicon Mac 轻松达标）。
- **对象池**：子弹、敌人、特效、伤害数字全部池化复用，绝不运行时频繁 new/free。
- 上限控制：同屏子弹/敌人/特效设硬上限；超限时合并/降级特效，**宁降特效不掉帧**。
- 伤害数字用单一 MultiMesh/池化 Label，避免节点爆炸。
- DoT/状态用集中式 tick（一个 ticker 批处理），不每怪一个 Timer。
- 纹理图集（atlas）合批，减少 draw call；序列帧用 SpriteFrames。
- 移动端：限制粒子数、关闭高开销后处理；提供"画质档"（高/中/低）在设置里。

## 9. 工具链（呼应数据驱动 / 平衡）

- `tools/data_validate.gd`：校验所有 `*.json` 的 ID 引用、资源文件存在性、孤儿引用（启动时 + 编辑器按钮）。
- `tools/balance_check.gd`：跑 `09 §6` 可过性矩阵，输出 99 关 × 养成档的预测星级表，辅助调表。
- `tools/card_simulate.gd`：跑 `09 §7` 卡牌导演模拟，检查成型率、保底、经济牌误出。
- `tools/targeting_debug.gd`：在编辑器叠加目标分数和威胁标签，用于验证"该打谁"。
- 配表与素材命名 100% 对齐 `naming_convention.md`，工具据此把"数据 ID ↔ 素材文件"自动连接。

## 10. 跨平台导出配置（预留全平台）

| 平台 | 导出 | 关键点 |
|---|---|---|
| iOS | Xcode 项目 → App Store | 触控、安全区、`user://` 沙盒、IAP 关闭 |
| macOS | .app / 公证 notarize | 可变窗口、鼠标、键盘快捷键 |
| Web | HTML5/WASM | GDScript 导出 OK；注意包体与加载、`user://` 用 IndexedDB |
| Windows | .exe | 鼠标键盘，同 macOS 逻辑 |
| Android | .apk/.aab | 触控同 iOS，分辨率适配多机型 |

- 一份代码 + 数据 + 素材，差异只在导出预设与输入层表层。
- v1 只验证 iOS + macOS；Web/Win/Android 在架构上已可导出，留到迁移阶段打磨（见 `14`）。

## 11. 工程规范

- 版本控制：git（含 `design/`、`res://data/`、源码；大素材可用 Git LFS 或单独资源仓）。
- 代码规范见 `naming_convention.md §7`。
- 提交即可玩：保持 `main` 分支随时可运行（占位素材兜底）。
- 自动化（可选）：导出脚本 + JSON 校验进 CI。
