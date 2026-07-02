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
- [x] `weapon_autocannon` icon / machine-gun prototype
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
- [x] 选卡时机收口：最终波清场后不再弹无意义技能卡；进入最终波前会检查一次接近达标的首张卡补给
- [x] 每局 1 次 reroll（CardPanel 上重抽按钮；用完变灰且 disable）
- [x] 简版 `CardDirector`：顺 build 牌 + 救场牌 + 低概率调味牌
- [x] `skill_split_shot`：命中分裂
- [x] `skill_pierce`：子弹穿透
- [x] `skill_multishot`：额外发射子弹
- [x] `skill_slow_field`：防线前减速区
- [x] 主动技能按钮：4 个角色主动技能均可释放并进入冷却；火/雷在无目标时使用战线 fallback 特效，不再表现为按钮失效
- [x] 元素命中特效：火焰弹燃烧/爆裂、冰霜弹冻结、闪电弹电击、毒素弹毒雾命中反馈
- [x] 全枪械弹道/命中特效：自动、火焰、冰霜、电、毒保留元素特效；磁轨炮有穿甲光轨，散弹炮有多 pellet 碎片命中，等离子炮有紫橙能量核和冲击波。
- [x] 分裂弹可视化：命中后有爆裂环、小弹飞散、追踪 mini projectile，能明确看到分裂行为
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
- [x] 10 张新战斗背景按每十关一段落替换，并通过 `data/environments.json` 数据化加载；背景源图已按 iPhone 17 竖屏全屏比例 `1206x2622` 重出，包含 portrait、battle layout guide、contact sheet 和 source spec。

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
- `python3 tools/check_visual_assets.py`
- `python3 tools/check_level_pressure.py`
- `python3 tools/simulate_card_director.py`
- `godot --headless --path . --quit`
- `godot --headless --path . --script res://tools/_battle_boot_probe.gd`
- `godot --headless --path . --script res://tools/m1_smoke_test.gd`
- `python3 tools/check_visual_screens.py`
- `python3 tools/check_release_candidate.py`

## 阶段 11 · 阶段性增量（已加进阶段 4-8 的勾选之外）

- [x] 结算页加 "重打本关" 按钮
- [x] Menu/Loadout/Result 切到 `ui_button_primary.png` 贴图按钮
- [x] Boss 物理免疫：实现 `mechanic: armor_break`，命中 `armor_hits` 次后破甲，破甲时 Boss 永久变红、ThreatMarker 文字变 BROKEN
- [x] 敌人普通抗性/弱点：zombie_brute.resist=poison、zombie_runner.weakness=ice 等已通 `take_damage` 结算（M1 武器为物理，仅 boss 免疫实际影响）
- [x] `tools/check_res_refs.py` 静态扫 `res://` 引用，CI 友好
- [x] 4 个角色专属主动/被动落地：独立角色技能按钮、低血自动反击、火/冰/雷/物理弹种亲和加成。
- [x] 局内选中技能 HUD 去重：只保留底部带等级的技能槽，选卡后用槽位 pulse 反馈，不再生成额外悬浮小 logo。
- [x] 角色 + 武器融合模型通路：战斗优先加载 `character_weapon_combos/{角色}/{角色}_{武器}_idle_01.png`，已覆盖 4 个角色 x 8 把武器的 idle/attack_left/attack/attack_right/hurt 原型帧；站立/受击帧使用枪在后、人压前的层级，开火帧按弹道方向切换左/中/右举枪、枪口闪光和后坐序列，避免枪械像独立贴图硬盖在人身上。

## 阶段 12 · 回归护栏（外包后补齐）

- [x] `tools/_battle_boot_probe.gd`：通过真实路由进入战斗，检查暂停状态、时间倍率、波次、出怪、角色 rig 和逻辑炮塔。
- [x] `tools/check_visual_assets.py`：检查战斗角色/手持武器素材的方块底、透明边界和严重绿幕残留。
- [x] `tools/check_visual_assets.py`：纳入 `character_weapon_combos`，后续每个角色/武器融合模型都会被同一套透明边界与绿幕残留规则检查。
- [x] 全量高规格原型替换：`tools/generate_high_end_prototype_assets.py` 已覆盖角色半身原型、角色/武器融合帧、僵尸、Boss、宠物、技能图标、VFX 单帧/序列与 projectile polish；数据中僵尸、Boss、技能图标引用已迁到 `assets/production/`，并输出 `high_end_prototype_asset_spec.json` 与 `high_end_prototype_contact_sheet.png` 供追溯。
- [x] `tools/check_visual_screens.py`：真实渲染 6 个关键界面截图，检查 1080x1920、非空白、无大面积纯黑边。
- [x] `tools/check_release_candidate.py`：把新增 battle probe、视觉素材检查、截图检查纳入候选发布检查。
- [x] `tools/check_gameplay_polish.py`：新增主动技能 fallback、元素命中强化、技能 HUD 去重 guardrail。
- [x] `tools/m1_smoke_test.gd`：主动技能按下必须进入冷却，避免再次出现“主动技能不可用”。
- [x] Godot 沙箱启动：`project.godot` 使用项目内隐藏 user data 目录，headless 下 AudioManager 不加载/播放音频流；`godot --headless --path . --quit` 当前 exit 0。
- [x] VFX B2 子弹/投射物：`projectile.gd` 使用 B1 `VfxLib` 加法拖尾、shader 能量核、radial glow 光晕和预算门控粒子；未改碰撞半径/速度/伤害/穿透/命中逻辑，未触碰 `data/*.json` 或渲染方向。
- [x] VFX B3 枪口闪光全套：`battle.gd` 枪口开火函数使用 B1/B2 `VfxLib`、加法光锥、glow shader 核心、火星/烟雾/毒雾粒子和元素分叉/气泡；未改开火时机、伤害、命中、碰撞、数据、角色/武器/敌人/Boss 图或渲染方向。
- [x] VFX B4 命中/爆裂/死亡：`projectile.gd` 与 `battle.gd` 的命中、免疫、连锁、范围爆裂和死亡爆裂视觉改用 `VfxLib` glow/particles、加法 streak/ring、glow shader 核心与预算门控 `screen_shake`；未改命中判定、`take_damage`、伤害数值、数据、角色/武器/僵尸/Boss 图或渲染方向。
- [x] VFX B5 技能光效：穿透、分裂、连锁、减速场、护盾、暴击、蓄能/强化、升级和选卡技能签名改用 `VfxLib`、glow shader、加法 streak/ring、粒子、slow-field shader 与 B4 impact helpers；未改技能触发、命中/伤害/数值、数据、形象 PNG 或 `project.godot` 渲染方向。
- [x] App logo 高规格重做：`assets/app/app_icon_1024.png` 已替换为 1024×1024 RGB 的高端 3D 渲染图标，保留旧版备份；生成源图和 prompt 已放入 `assets/production/source_refs/generated/` 并登记到 `OUTSOURCER_ASSET_INDEX.json`。
- [x] 全项目最终美术水准筛查：新增 `design/assets/final_art_quality_audit_2026_07_01.md`，按“3D 渲染 / 顶级美术 / App Store / 最终图”口径标出 P0/P1/P2 资产问题；本轮只审计，不批量替换素材。
- [x] 最终美术 P0 替换（资产与集成）：启动图、App Store 截图草案、App Preview 草案、扁平 UI kit、运行时锁定圈和 legacy runtime refs 已完成专项替换；生成源图、spec 和 contact sheet 已放入 `assets/production/source_refs/generated/` 并登记到 `OUTSOURCER_ASSET_INDEX.json`。
- [x] 结算页按钮风格统一：`ui_button_primary.png` / `ui_button_secondary.png` 改为同一 bevel / 描边 / 光源模型，`meta/result/result.gd` 不再给动作按钮额外染色；已截图到 `tmp/final_p0_runtime_screens/result_button_unified.png`。
- [x] 最终美术 P0 顶级材质拔高：基于 `image_gen` 顶级 HUD 材质参考重新打磨按钮、面板、图标底座、卡槽、进度条和准星，统一为暗金属 / 玻璃 / 青橙边缘光的 3D 渲染体系；已重跑运行截图、App Store 截图、18 秒 App Preview 和最终 contact sheet。
- [x] 角色开枪动作 P0 手感拔高：全量重生成 4 角色 x 8 武器的融合开火帧，改为 F1 枪口爆发、F2 强后坐、F3 回稳、F4 归位；战斗运行时在开火窗口锁定本次 aim / 枪口 / 攻击帧，避免目标切换导致枪口、子弹和角色动作不同步。
- [x] P0 商店截图空背景修复：`main._apply_safe_area()` 忽略桌面/截图进程返回的全局 display safe rect，避免 map/loadout 内容 Root 被推到屏幕外；已重新捕获 `tmp/final_p0_runtime_screens/`，重生成 App Store 截图和 App Preview，并加严 `tools/check_visual_screens.py` 的 UI 层截图阈值。
- [x] 最终美术运行时第一批拔高：用 `image_gen` 顶级参考板 + 本地生成脚本重做 runtime UI skins、11 个投射物、VFX 单帧/序列、慢速场带和护盾玻璃贴图；`UiKit` 通用 panel/pill/resource chip、伤害数字、连击框、慢速场 shader、护盾显示已接入贴图化皮肤，并登记到 `OUTSOURCER_ASSET_INDEX.json`。
- [x] 最终美术背景第二批拔高：用 built-in `image_gen` 独立生成 10 张主线环境顶级 3D 渲染源图，拒绝 SVG/矢量/扁平占位；已按现有 `data/environments.json` 路径覆盖 `bg_*`、portrait、layout guide，输出 source spec 与 contact sheet，并登记到 `OUTSOURCER_ASSET_INDEX.json`。
- [x] 最终美术骨骼分件清理：414 张 `assets/production/sprites/parts/**` 分件保持 256×256 透明 PNG 合同，完成重新居中、安全边、alpha 边缘和材质对比清理；修复 `zombie_crawler_hand_r.png` 空 alpha，输出 source spec/contact sheet，并登记到 `OUTSOURCER_ASSET_INDEX.json`。
- [x] 最终美术非开枪动画清理：902 张非融合开枪动画帧完成 alpha 边界、裁切保护和材质对比清理，明确跳过 `character_weapon_combos`；额外清理 102 张 hurt 帧的半透明红色矩形底，输出 source spec/contact sheet，并登记到 `OUTSOURCER_ASSET_INDEX.json`。
- [x] 最终美术 UI / 战斗动效二轮：基于 built-in `image_gen` 顶级参考图和本地位图生成器，重做按钮、边框、提示、血条/经验条、技能卡/图标底座等 runtime skins；新增 6 套受击、27 套僵尸技能、5 套主角主动技能、16 套卡牌技能施法 PNG 帧序列，并在 `battle.gd` 接入受击、基地攻击、酸液、Boss 施法、选卡和主动技能播放路径；拒绝 SVG/矢量，输出 source refs/spec/contact sheets 并登记到 `OUTSOURCER_ASSET_INDEX.json`。
- [x] Owner 参考表 UI/VFX 直切与运行时接入：将 owner 提供的两张顶级 UI/VFX 参考表复制到 `assets/production/source_refs/generated/`，直接裁切成 runtime UI PNG、VFX 单帧和 `vfx_sequences/**` 序列帧；修正卡框相邻素材混入与枪口行上方 UI 混入问题；`battle.gd` / `projectile.gd` 默认开启 authored bitmap VFX only，枪口、命中、死亡、连锁、范围、敌方技能、Boss 施法、护盾获得/破裂、选卡与 projectile 穿透主路径均优先播放 PNG 序列，不再叠加旧 `VfxLib` / `Line2D` 程序化特效。
- [x] 最终美术 P0 战斗代码级余量（三轮）：战斗 VFX 主路径已切到 owner 参考表 PNG 序列；齐射、追踪、蓄力、暴击、减速场和护盾常驻显示在 `AUTHORED_BITMAP_VFX_ONLY` 下不再生成额外 `Line2D` / `Polygon2D` / 粒子几何叠层。
- [x] 最终美术 P0 可见 UI 线条贴图化：地图、出战、图鉴、结算和战斗 HUD 中玩家可见的剩余直线框、按钮框、关卡卡片、资源 chip、星级/金币图标、血条/经验条主路径改为透明 PNG / `StyleBoxTexture` 皮肤；桌面截图 safe-area 推屏问题同步修复，运行截图输出到 `tmp/ui_line_polish_2026_07_02/screens/`。
- [x] P2 源码级 UI primitive 清理：`gameplay/`、`meta/`、`ui/` 的 `.gd/.tscn` 中已清零 `ColorRect` / `StyleBoxFlat`；功能性 dim、闪白、冷却遮罩、血条/经验条和 panel fallback 改为 `TextureRect` / `StyleBoxTexture` / `StyleBoxEmpty`。剩余 `Line2D` / `Polygon2D` / `GPUParticles2D` 命中都位于 projectile/battle/vfx 战斗特效路径，不是 UI 线框皮肤。
- [x] P2 App Store 截图重捕：重新捕获 `tmp/final_p0_runtime_screens/`，重生成 `assets/appstore/screenshots/**` 与 `assets/production/video/vid_app_preview.mp4`；`python3 tools/check_app_store_assets.py` 与 `python3 tools/check_visual_screens.py` 当前通过。
- [ ] Godot smoke 退出清理：`godot --headless --path . --script res://tools/m1_smoke_test.gd` 功能回归通过，但 Godot 4.7 headless 退出仍输出 Canvas/TextServer/RID cleanup warnings；已修复 screenshot helper teardown，smoke 仍需后续专项 teardown，不影响 release candidate exit 0。

## 阶段 13 · 最终视觉验收开放 TODO（2026-07-02 复扫）

详单与截图证据见 `design/assets/final_visual_todo_2026_07_02.md`。

- [x] P0：战斗顶部 HUD、底部 HUD、教学提示主路径已贴图化；HP/波次/XP/Boss HP 填充、技能按钮冷却遮罩和波次提示改为 PNG / `StyleBoxTexture`。
- [x] P0：地图关卡卡片、顶部资源/tab、关卡编号、弱点/状态 chip 和出战按钮已切到同一套暗金属/玻璃 PNG 皮肤，移除主要可见裸 `ColorRect` 线条。
- [x] P0：已重新生成 `assets/production/source_refs/`、`assets/production/contact_sheets/`、角色武器组合 manifest/matrix；`python3 tools/check_visual_assets.py` 当前通过。
- [x] P1：出战空槽、图鉴列表、结算页奖励/提示/主面板已接入贴图皮肤，空装备槽不再使用裸 “＋” 占位。
- [x] P1：41 个 VFX 透明尾帧已补为淡出残影；14 个 2 秒 production video 已保留原路径重制为 6 秒版本。
- [x] 发布候选闭环：修正中后期 `xp_first_offer` / `xp_offer_growth` / `xp_offer_ramp` 元数据，使预测卡牌数与现有 `target_card_picks` 对齐；拉开 collection 星级解锁成本到 62/90/120/150/210/230；`meta/collection/collection.gd` 可见等级文案已去掉 `Lv.` 英文残留；`python3 tools/check_release_candidate.py` 当前通过。
- [x] P0：角色持枪开火动作升级为 4 角色 x 8 武器 x 3 方向 x 7 帧融合 PNG 序列；开火窗口锁定 aim / muzzle / frame，同时允许下一发和 smoke 显式方向更新；动作帧保留 3px 透明安全边，`python3 tools/check_visual_assets.py` 与 `python3 tools/check_release_candidate.py` 当前通过。
- [x] P2：源码级 UI primitive 清理完成；`rg -n "ColorRect|StyleBoxFlat" gameplay meta ui -g '*.gd' -g '*.tscn'` 当前无命中。剩余几何节点仅在战斗 VFX / projectile 路径，且 release candidate 通过。
