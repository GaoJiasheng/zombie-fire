# 17 · Asset / Audio Generation Plan

> 目标：图片、音乐、音效、视频/镜头素材由我们生成并验收，外包只负责接入。
> 注：用户提到的“肠镜素材”先按“场景/镜头素材”理解；若实际另有所指，再单独建类目。

## 1. 资产生产原则

- 先锁风格，再批量生成。
- 所有素材必须遵守 `design/assets/visual_style_lock.md`。
- 所有文件名必须遵守 `design/data/naming_convention.md`。
- 原型素材可以粗，但不能风格漂移。
- 正式接入前必须有 contact sheet 或试听表。
- 外包不能自行替换素材。

## 2. 图片资产阶段

### Stage A · M1 Prototype Assets

状态：已完成。

关键 contact sheets：

- `assets/m1_visual/contact_sheets/contact_characters.png`
- `assets/m1_visual/contact_sheets/contact_zombies_t1_t2.png`
- `assets/m1_visual/contact_sheets/contact_zombies_t3_t4.png`
- `assets/m1_visual/contact_sheets/contact_bosses.png`
- `assets/m1_visual/contact_sheets/contact_skills.png`
- `assets/m1_visual/contact_sheets/contact_weapons_equipment.png`
- `assets/m1_visual/contact_sheets/contact_ui.png`
- `assets/m1_visual/contact_sheets/contact_vfx.png`
- `assets/m1_visual/contact_sheets/contact_backgrounds.png`
- `assets/m1_visual/contact_sheets/contact_battle_mock.png`

### Stage A2 · Full Prototype Production Pack

状态：已完成。

交付目录：

- `assets/production/`
- `assets/production/ASSET_PACK_STATUS.md`
- `design/assets/full_asset_pack_status.md`

内容：

- 全量 v1 视觉原型整理为外包可接入目录结构。
- 角色/怪/Boss 补齐 `prototype / portrait / icon`。
- 主炮/护甲/芯片/宝宝/技能/UI/VFX/背景复制到 production pack。
- 生成 9 个 BGM placeholder WAV。
- 生成 15 个 SFX placeholder WAV。
- contact sheets 复制到 `assets/production/contact_sheets/`。
- 生成单位动画 placeholder 帧。
- 生成 VFX sequence placeholder 帧。
- 生成流程参考图。
- 生成环境竖屏图与战斗布局 guide。
- 生成 15 个 MP4 placeholder 视频。
- 生成 `OUTSOURCER_ASSET_INDEX.json`，明确外包不得自行生成素材。
- 一次性补齐 placeholder 骨骼分件、扩展 SFX、字体文件，并纳入强校验。

校验：

```bash
python3 tools/validate_asset_pack.py
```

### Stage B · Production Unit Parts

目标：把原型整图转为可动画分件。

范围：

- 4 角色分件。
- 20 普通僵尸分件。
- 8 Boss 分件。
- 6 宝宝分件。
- 8 主炮炮塔分件。

交付格式：

```text
{id}_portrait.png
{id}_icon.png
{id}_head.png
{id}_body.png
{id}_arm_l.png
{id}_arm_r.png
{id}_hand_l.png
{id}_hand_r.png
{id}_leg_l.png
{id}_leg_r.png
{id}_weapon.png
```

验收：

- 分件可在 Godot 中重组。
- 角色比例不漂移。
- Boss 明显大于普通怪。
- 不出现四主角同质化。

### Stage C · UI Production Assets

目标：把 M1 程序化 UI 升级为可九宫格/可组件化正式 UI。

范围：

- 按钮。
- 面板。
- 卡框。
- 血条/进度条。
- 技能槽。
- 星级。
- 货币。
- 元素。
- 系统图标。

验收：

- 在 1080x1920 下清晰。
- 在 macOS 缩放窗口下不糊。
- 不遮挡战斗中心。
- 卡牌内容与 UI 框可分层。

### Stage D · VFX Production

目标：从单帧原型升级为序列帧/粒子贴图。

优先级：

1. 炮口火光。
2. 命中特效。
3. 暴击。
4. 死亡溶解。
5. 分裂/穿透/多重强化反馈。
6. 减速场。
7. Boss 登场/阶段。
8. 免疫/弱点提示。

验收：

- 不挡住目标。
- 元素颜色一致。
- 低端画质可降级。
- 同屏大量 VFX 不掉帧。

### Stage E · Background / Scene / Shot Assets

目标：章节背景、菜单、地图、镜头素材。

范围：

- `bg_city_ruins`
- `bg_subway`
- `bg_military`
- `bg_biolab`
- `bg_main_menu`
- `bg_level_map`
- Boss 登场镜头参考图。
- App Store 截图构图图。
- 预览视频镜头板。

验收：

- 战斗背景中间留空。
- 顶部生成区和底部防线清楚。
- 菜单和地图预留 UI 空间。
- 不使用过暗、过花、过写实恐怖的背景。

## 3. 音乐计划

音频格式：

- BGM：`.ogg`，循环版。
- SFX：`.wav` 或 `.ogg`。
- 采样率：44.1k 或 48k。

### BGM 清单

| ID | 用途 | 情绪 |
|---|---|---|
| `bgm_menu` | 主菜单 | 末日、希望、低压迫 |
| `bgm_map` | 关卡地图 | 战术、推进 |
| `bgm_battle_city` | 城市废墟 | 紧张、节奏清楚 |
| `bgm_battle_subway` | 地铁 | 低频、幽闭 |
| `bgm_battle_military` | 军区 | 鼓点、机械 |
| `bgm_battle_biolab` | 生化实验室 | 冷色、电子、危险 |
| `bgm_boss` | Boss 战 | 压迫、爆发 |
| `bgm_result_victory` | 胜利结算 | 短促奖励 |
| `bgm_result_defeat` | 失败 | 不挫败、可重试 |

### SFX 清单

优先级 P0：

- `sfx_ui_click`
- `sfx_ui_confirm`
- `sfx_ui_card_offer`
- `sfx_ui_card_pick`
- `sfx_shot_autocannon`
- `sfx_hit_physical`
- `sfx_enemy_death_small`
- `sfx_enemy_breach`
- `sfx_gold_pickup`
- `sfx_level_up`
- `sfx_victory`
- `sfx_defeat`

优先级 P1：

- 各元素命中。
- 各主炮开火。
- Boss 登场。
- 锁定目标。
- 威胁警告。
- 免疫提示。

验收：

- 自动机炮连续开火不刺耳。
- 命中/死亡/金币可形成反馈节奏。
- UI 音不抢战斗音。
- BGM 可循环无明显断点。

## 4. 视频/镜头素材计划

视频不是 M1 必需，M3/M4 前补。

范围：

- `vid_intro_opening.mp4`
- `vid_boss_intro_{boss}.mp4` × 8
- `vid_chapter_{env}.mp4` × 4
- `vid_ending.mp4`
- App Store preview video

优先级：

1. App Store preview video。
2. `boss_tank_titan` 登场。
3. 开场短片。
4. 其余 Boss。
5. 章节过场。

验收：

- 竖屏 1080x1920。
- 3-8 秒，节奏快。
- 不强依赖剧情。
- 可跳过。
- 包体可控。

## 5. 资产交付目录

正式资产建议放：

```text
assets/production/
  sprites/
    characters/
    zombies/
    bosses/
    weapons/
    equipment/
    pets/
    projectiles/
    vfx/
    ui/
    backgrounds/
  audio/
    bgm/
    sfx/
  video/
  contact_sheets/
```

运行接入资产继续复制或导入到：

```text
assets/sprites/
```

## 6. 我方生成工作流

每批素材：

1. 从设计文档确认 ID 和用途。
2. 写 prompt。
3. 生成 2-4 个候选。
4. 做 contact sheet。
5. 按 accepted / replace_later 标记。
6. 输出到 production 目录。
7. 给外包接入清单。

## 7. 外包接入要求

外包接入资产时必须：

- 不改文件名。
- 不拉伸变形。
- 不擅自换图。
- 大图按 Godot import 设置压缩。
- VFX 同屏过多时做降级策略。
- UI 尽量组件化，而不是整张截图贴上去。
