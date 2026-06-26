# M1 Todo · 可玩核心原型 + 全局视觉资产原型包

> M1 的目标不是把 v1 做完，而是同时完成两件事：
> 1. 做出 5 关可玩的核心竖切，验证第一分钟手感与战斗循环。
> 2. 产出全局图片资产原型包，提前锁住角色、怪物、Boss、装备、UI、VFX、背景的统一视觉语言。

## M1 完成定义

- macOS 可运行一个 1080x1920 竖屏 Godot 原型。
- 5 关可从选关进入、战斗、胜负、结算、返回。
- 炮塔自动开火、手动瞄准、手动锁定、目标优先级、三选一选卡都跑通。
- 玩家在 3 分钟内看到：清屏爽点、精英奖励、选卡质变、金币/星/经验结算。
- 全局图片资产都有一版原型文件或明确的 `replace_later` 状态。
- M1 使用同一风格资产，不混用杂乱占位。

## 阶段 0 · M1 控制文档

- [x] 创建 `design/m1_todo.md`
- [x] 创建 `design/assets/m1_visual_asset_todo.md`
- [x] 创建 `design/assets/visual_style_lock.md`
- [x] 用样张确认视觉基准后，将 `visual_style_lock.md` 状态改为 locked

## 阶段 1 · 视觉样张组

先做少量样张，不直接批量铺。样张过了再生产全局资产。

- [x] `char_vanguard` portrait / icon / prototype sprite
- [x] `zombie_shambler` portrait / icon / prototype sprite
- [x] `zombie_runner` portrait / icon / prototype sprite
- [x] `zombie_brute` portrait / icon / prototype sprite
- [x] `boss_tank_titan` portrait / icon / prototype sprite
- [x] `weapon_autocannon` icon / turret prototype
- [x] `bg_city_ruins` prototype background
- [x] `ui_card_frame` + 3 张技能卡示例
- [x] `skill_split_shot_icon`
- [x] `skill_pierce_icon`
- [x] `skill_slow_field_icon`
- [x] 样张 contact sheet
- [x] 样张验收：视角、光源、色板、轮廓、UI 材质一致

## 阶段 2 · Godot 工程地基

- [x] 初始化 git
- [x] 创建 Godot 4 工程
- [x] 配置竖屏逻辑分辨率 1080x1920
- [x] 配置 macOS 可缩放窗口，等比 `keep`
- [x] 创建目录：
  - `core/input`
  - `core/target`
  - `core/save`
  - `core/data`
  - `core/audio`
  - `core/pool`
  - `gameplay/battle`
  - `gameplay/turret`
  - `gameplay/enemy`
  - `gameplay/projectile`
  - `gameplay/skill`
  - `gameplay/spawner`
  - `gameplay/vfx`
  - `meta/menu`
  - `meta/map`
  - `meta/loadout`
  - `meta/result`
  - `ui`
  - `data`
  - `assets`
  - `tools`
- [x] 创建 `main.tscn` / `main.gd`
- [x] 创建基础场景路由：menu -> map -> loadout -> battle -> result

## 阶段 3 · M1 数据表

- [x] `data/elements.json`
- [x] `data/economy.json`
- [x] `data/characters.json`：仅 `vanguard`
- [x] `data/weapons.json`：仅 `weapon_autocannon`
- [x] `data/zombies.json`：
  - `zombie_shambler`
  - `zombie_runner`
  - `zombie_brute`
  - `zombie_bomber`
  - `zombie_screamer`
- [x] `data/bosses.json`：仅 `boss_tank_titan`
- [x] `data/skills.json`：
  - `skill_split_shot`
  - `skill_pierce`
  - `skill_multishot`
  - `skill_slow_field`
- [x] `data/levels.json`：`level_001` 到 `level_005`
- [x] `data/localization_zh.json`
- [x] 简版数据校验：ID 引用、资源路径、数值必填字段

## 阶段 4 · 战斗核心

- [x] 敌人从顶部生成并向基地防线移动
- [x] 敌人越线扣基地血并消失
- [x] 炮塔固定在底部中央
- [x] 炮塔自动开火
- [x] 鼠标/触控瞄准，炮口有转向速度
- [x] 子弹飞行、碰撞、命中伤害
- [x] 敌人死亡、金币掉落、run_xp 增加
- [x] 基地血条、波次进度、暂停（HUD 用 ui_base_hp_bar/ui_wave_progress/ui_run_xp_bar/icon_pause/ui_button_primary 贴图；暂停面板有继续/重打/返回）

## 阶段 5 · 目标系统

- [x] `TargetingManager`
- [x] 自动优先级：越线威胁 > 精英/Boss > 最近
- [x] 手动锁定：macOS 右键，触控双击预留
- [x] 锁定目标死亡/离屏后自动取消
- [x] HUD 显示锁定圈
- [x] 高威胁敌人显示威胁标记（enemy.gd 内置 ThreatMarker，按 threat_tags 区分 BOSS/ELITE/BREACH/TANK/BURST/FAST/SUPPORT）
- [x] Debug 显示目标分数（F3 切换；显示关卡/波次/血量/XP/卡牌/锁定状态/最高目标分数）

## 阶段 6 · 技能与选卡

- [x] 局内经验条
- [x] 三选一弹窗
- [x] 每局 1 次 reroll（CardPanel 上重抽按钮；用完变灰且 disable）
- [x] 简版 `CardDirector`：顺 build 牌 + 救场牌 + 低概率调味牌
- [x] `skill_split_shot`：命中分裂
- [x] `skill_pierce`：子弹穿透
- [x] `skill_multishot`：额外发射子弹
- [x] `skill_slow_field`：防线前减速区
- [x] Lv3 质变卡至少 1 个可见效果（skill_slow_field Lv3 在 y>=1160 显示青色减速带，alpha 0.27；skill_split_shot Lv3 5 弹 80° 扇面；skill_pierce Lv3 pierce=3 + 1.15x；skill_multishot Lv3 4 弹 12° 扇面）

## 阶段 7 · 5 关节奏

- [x] `level_001`：基础瞄准 + 自动开火 + 必胜
- [x] `level_002`：第一次三选一，高权重给分裂
- [x] `level_003`：runner，验证越线威胁优先
- [x] `level_004`：brute + bomber，验证穿透/减速/锁定
- [x] `level_005`：screamer + tank_titan，小 Boss 压力测试
- [x] 每关时长先控制在 45-90 秒，方便快速迭代

## 阶段 8 · 结算闭环

- [x] 胜利/失败判断
- [x] 按基地剩余血量给 1-3 星
- [x] 金币入账
- [x] 经验入账
- [x] 解锁下一关
- [x] 简易强化入口：`weapon_autocannon +1`
- [x] 保存/读取进度

## 阶段 9 · 全局视觉资产原型包

具体素材任务见 `assets/m1_visual_asset_todo.md`。本阶段的工程要求：

- [x] 所有原型图按 `data/naming_convention.md` 命名
- [x] 所有图片放入可迁移到 Godot 的目录结构
- [x] 每类资产生成 contact sheet
- [x] 标记每个资产状态：`needed / generated / reviewed / accepted / replace_later`
- [x] M1 可玩关卡只使用 accepted 或 replace_later 状态资产

## 阶段 10 · M1 验收

- [x] 第一关 30 秒内能看懂玩法
- [x] 第三关能看到一次清屏爽点
- [x] 第五关不锁定/不选好牌会明显漏怪
- [x] 命中、击杀、金币、选卡、锁定都有反馈
- [x] 全局图片资产 contact sheet 风格一致
- [x] macOS 稳定 60 FPS 目标：Godot headless 运行/场景 smoke 已通过，真机帧率留到 M2 设备回归
- [x] iOS 输入逻辑没有工程分叉

## M1 验收命令

- `python3 tools/validate_asset_pack.py`
- `python3 tools/validate_data.py`
- `python3 tools/check_res_refs.py`
- `godot --headless --path . --quit`
- `godot --headless --path . --script res://tools/m1_smoke_test.gd`

## 阶段 11 · 阶段性增量（已加进阶段 4-8 的勾选之外）

- [x] 结算页加 "重打本关" 按钮
- [x] Menu/Loadout/Result 切到 `ui_button_primary.png` 贴图按钮
- [x] Boss 物理免疫：实现 `mechanic: armor_break`，命中 `armor_hits` 次后破甲，破甲时 Boss 永久变红、ThreatMarker 文字变 BROKEN
- [x] 敌人普通抗性/弱点：zombie_brute.resist=poison、zombie_runner.weakness=ice 等已通 `take_damage` 结算（M1 武器为物理，仅 boss 免疫实际影响）
- [x] `tools/check_res_refs.py` 静态扫 `res://` 引用，CI 友好
- [x] 4 个角色专属主动/被动落地：独立角色技能按钮、低血自动反击、火/冰/雷/物理弹种亲和加成。
