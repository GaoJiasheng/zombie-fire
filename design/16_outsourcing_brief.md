# 16 · Outsourcing Brief

> 给外包 Godot 开发团队的执行说明。外包团队只需要实现与修 bug，不负责重新设计产品方向。

## 1. 项目简介

Zombie Fire 是一个 1080x1920 竖屏 Godot 4 Roguelike 塔防自动射击游戏。

玩家控制底部固定炮塔：

- 自动开火。
- 手动瞄准。
- 手动锁定高威胁目标。
- 击杀僵尸获得局内 XP。
- XP 满触发三选一强化。
- 清完波次/Boss 后按基地剩余血量结算 1-3 星。

## 2. 开发环境

- Godot 4.x
- GDScript
- macOS + iOS 首发
- 预留 Web/Windows/Android
- 数据文件：`data/*.json`
- 运行素材：`assets/sprites/`
- 设计文档：`design/`

## 3. 必读文件

外包每次开工前必须读：

1. `design/15_app_production_plan.md`
2. `design/m1_todo.md`
3. `design/m1_implementation_progress.md`
4. `design/13_tech_architecture.md`
5. `design/01_core_gameplay.md`
6. `design/10_ui_ux.md`
7. `design/data/schema.md`
8. `design/data/naming_convention.md`

## 4. 当前工程结构

```text
project.godot
main.tscn
main.gd
core/
  data/
  input/
  save/
  target/
gameplay/
  battle/
  enemy/
  projectile/
  skill/
  turret/
meta/
  menu/
  map/
  loadout/
  result/
data/
assets/sprites/
tools/
```

## 5. 外包任务包

### Task A · M1 修通与 HUD

目标：M1 能在 Godot 编辑器中运行，并有可用 HUD。

交付：

- 修复 Godot 打开/运行错误。
- HUD 显示基地血条、波次进度、局内 XP。
- 暂停按钮和 ESC 暂停。
- 战斗中 UI 不遮挡关键目标。
- 更新 `design/m1_todo.md`。

验收：

- macOS 可运行。
- Level 001 可通关。
- `python3 tools/validate_data.py` 通过。

### Task B · 卡牌与技能完整 M1

目标：三选一体验达到 M1 完成定义。

交付：

- 一局 1 次 reroll。
- CardDirector 权重可读、可调。
- 分裂/穿透/多重/减速有明显效果。
- 至少一个 Lv3 质变可见。
- 卡牌 UI 使用现有素材。

验收：

- Level 002 可以稳定看到第一次三选一。
- Level 003 能看到清屏爽点。
- 选牌时暂停，选完继续。

### Task C · 目标系统与威胁提示

目标：玩家相信炮塔在打该打的东西。

交付：

- 高威胁敌人标记。
- 锁定圈稳定跟随目标。
- 锁定目标死亡/离屏后取消。
- Debug overlay 显示 target score 或当前策略。
- 目标策略按钮/快捷键。

验收：

- Level 003 runner 优先级明显。
- Level 004 bomber/brute 可右键锁定。
- Debug overlay 可开关。

### Task D · 5 关节奏修通

目标：5 个 M1 关卡全部可玩、可输、可赢。

交付：

- Level 001 必胜基础教学。
- Level 002 第一次三选一。
- Level 003 runner 压力。
- Level 004 brute + bomber 压力。
- Level 005 screamer + tank_titan 小 Boss。
- Boss 不因物理免疫导致无解。

验收：

- 5 关均可进入、结算、返回地图。
- 每关时长 45-90 秒。
- Level 005 不选好牌会明显漏怪，但可通过。

### Task E · M2 内容框架

目标：外包可在 M1 稳定后批量铺量。

交付：

- 全量数据表结构。
- 4 角色、8 主炮、6 护甲、8 芯片、6 宝宝装备入口。
- 20 普通僵尸、8 Boss 行为接口。
- 99 关生成/校验工具。
- 地图解锁与星级展示。

验收：

- 全量内容可配置、可进入。
- 未实现机制必须有明确 fallback 或 `replace_later` 标记。

## 6. 代码要求

- 保持数据驱动。
- 不把关卡、怪物、技能写死在战斗脚本里。
- 每个系统尽量单一职责：
  - `battle.gd` 编排单局。
  - `enemy.gd` 管通用敌人状态。
  - `projectile.gd` 管弹体。
  - `skill_runtime.gd` 管局内技能状态。
  - `card_director.gd` 管出牌。
  - `targeting_manager.gd` 管目标选择。
- 所有新资源路径使用 `res://assets/sprites/...`。
- 不新增第三方插件，除非先说明必要性。

## 7. 禁止事项

- 禁止换引擎。
- 禁止改成横屏。
- 禁止改成玩家角色自由移动。
- 禁止加氪金/广告/体力。
- 禁止无说明大规模重写已能工作的代码。
- 禁止删除设计文档。
- 禁止替换已 accepted 的素材。
- 禁止绕过 `data/*.json` 直接在代码里塞全量内容。

## 8. 每次交付格式

外包每次提交必须附：

```text
Completed:
- ...

Changed files:
- ...

Verification:
- python3 tools/validate_data.py: pass/fail
- Godot editor run: pass/fail/not available
- Manual playtest: level ids tested

Remaining risks:
- ...
```

## 9. 偏差处理

发现外包跑偏时，按以下顺序纠正：

1. 回到 `design/15_app_production_plan.md` 的产品边界。
2. 回到 `design/m1_todo.md` 的 M1 范围。
3. 回到 `design/01_core_gameplay.md` 的固定炮塔玩法。
4. 回到 `design/data/naming_convention.md` 的 ID/素材命名。
5. 回到 `design/assets/visual_style_lock.md` 的美术风格。

