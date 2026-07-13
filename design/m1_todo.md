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
- [x] Lv3 质变卡至少 1 个可见效果（skill_slow_field Lv3 在 y>=820 显示青色减速带，alpha 0.27；skill_split_shot Lv3 5 弹 80° 扇面；skill_pierce Lv3 pierce=3 + 1.15x；skill_multishot Lv3 4 弹 12° 扇面）
- [x] `skill_slow_field` 范围翻倍：Lv1-Lv5 覆盖高度从 220/280/340/400/460px 扩到 440/560/680/800/920px；数据判定 `y_min` 与战斗可视 offset 同步，减速强度不变。
- [x] 宠物/机器人战斗位置贴近防线：宠物出生与待机浮动改为基于 `BREACH_Y` 的防线锚点，并随高屏 `bottom_dock_shift` 一起下移，避免真机上悬在旧 1920 画布高度。
- [x] 无尽模式选卡后经验清管：无尽模式成功升级/跳过技能后会清零当前局内 XP 条，并重新等待下一管经验，避免 XP 溢出导致连续重复弹三选一。

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
- [x] 角色开枪动作真实握把二次修复：按 owner 指出的“手必须握在枪把上”标准重写融合姿势生成器；枪身使用 gunstock / trigger grip / foregrip / muzzle 锚点，后手锁在扳机握把、前手托护木，重新生成 4 角色 x 8 武器 x 3 方向 x 7 帧正式开火 PNG，并同步 battle muzzle 常量与 2026_07_03 contact sheet。
- [x] 角色开枪动作 true-grip 三次修复：针对 `char_vanguard + weapon_autocannon` 的“单手端枪 / 站姿呆板 / 武器和手脱节”问题，使用 built-in `image_gen` 生成背视双手重武器参考图，抠透明后接入正式 7 帧攻击序列；同时全量角色攻击帧移除 baked muzzle flash / smoke / tracer，枪口 VFX 保持 runtime-only。
- [x] 角色开枪动作 true-grip 全量覆盖：按 owner 确认的 `char_vanguard + weapon_autocannon` 标准，为 Blaze / Frost / Volt 补充同规格 built-in `image_gen` 背视双手重武器参考图，抠透明后把生成器升级为角色级 true-grip 基准；已重生成 4 角色 x 8 武器 x 3 方向 x 7 帧，共 672 张正式 attack PNG，完整 contact sheet 覆盖 32 个组合。
- [x] 全关卡挑战模式：地图关卡卡片从整卡点击改为“进入关卡 / 挑战模式”两个明确按钮；挑战战斗敌人血量与推荐战力均为普通模式 1.5 倍；挑战结算独立记录 `challenge_progress`，同样最多 3 星，重复通关只按最高星级补差额，不重复发星，也不推进普通关卡解锁。
- [x] 全战斗背景底部堡垒对齐：以第三张环境 `env_abandoned_factory` 的横向堡垒高度为基准，重新平移 10 张 1080×1920 战斗背景 PNG，保持原环境 ID / 路径不变，并输出 before/after contact sheet。
- [x] 全武器握持原型对齐：8 把 `handheld/*_rifle.png` 建立逐枪 `stock / trigger / foregrip / muzzle` 锚点，清掉火焰/冰雾/闪电/毒雾手持源图的 baked muzzle VFX，左/中/右 aim 都按同一握持标准重新生成；最终 672 张 attack PNG 改回逐枪原型驱动，保留每把枪自己的外形而不是同一重炮换色。
- [x] 全人物 / 全枪支 full-model 开火动作最终覆盖：按 `design/ui_firing_pose_task.md` owner 验收标准，使用 built-in `image_gen` 全模型渲染参考表重建 4 角色 x 8 武器 x 3 方向 x 7 帧，共 672 张正式 attack PNG；所有帧保持双手握持、宽站姿、重心前压、无 baked muzzle flash/smoke/tracer，`battle.gd` 三向 muzzle 常量同步按最终 PNG 重算并通过 32/32 方向偏移检查。
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
- [x] VFX 全量返工铺开：按 `design/vfx_full_redo_task.md` 通过的 6 个样本标准，重做 4 个主动技、15 个技能触发、21 个未验收僵尸技能、5 个 projectile 本体；20 只僵尸的 80 张 attack 帧改用同僵尸 clean idle/walk 高质量源重建，彻底移除烘焙直线动作条；已保留 frost/venom/corrosion/storm-chain 等验收通过素材不动。
- [x] Godot smoke 退出清理：补齐 Battle/TargetManager、Enemy threat marker、UiKit/SequenceVfx 缓存与 AudioManager 测试销毁路径；`godot --headless --path . --script res://tools/m1_smoke_test.gd` 现在功能通过且退出无 Canvas/TextServer/RID 泄漏告警。

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
- [x] P1/P2：运行时 UI 深度自查修复完成；战斗 HUD/Toast、地图资源与关卡行、出战空槽、图鉴列表/详情、结算按钮、设置页背景与按钮层级已按顶级渲染 UI 标准收敛，最新总览截图见 `tmp/ui_polish_after_2026_07_04/contact_sheet_latest.png`；`python3 tools/check_release_candidate.py` 当前通过。
- [x] P1：技能图鉴 16 张图标全量重绘；按 `design/skill_icon_regen_prompts_2026_07_04.md` 使用 built-in `image_gen` 逐张生成顶级渲染 PNG，修复 8 组 byte 级重复和元素/机制错配，生产图标均为 256x256 RGBA 且 hash 唯一；证据见 `assets/production/source_refs/generated/skill_icon_regen_2026_07_04/skill_icon_regen_contact_sheet_2026_07_04.png`。
- [x] P1：SFX 全量差异化扩展；按 `design/sfx_expansion_prompts_2026_07_05.md` 本地渲染 45 条顶级 WAV（技能、角色 intro/主动技、20 种僵尸机制），接入 `AudioManager`、选卡/子弹触发/主动技/僵尸机制运行时路径，并登记 manifest 与波形总览。
- [x] P1：暂停层与图鉴/芯片页拥挤感修复；暂停面板加宽加高、信息卡/按钮字号重新排版并在暂停态隐藏顶部 toast，图鉴资源条和装备/芯片/宠物/武器列表行距放开，验证截图见 `tmp/ui_layout_polish_2026_07_05/`；`python3 tools/check_release_candidate.py` 当前通过。
- [x] P1：全选择界面购买/装备按钮放大并装甲化；图鉴角色/武器/护甲/芯片/宠物列表卡片改为持续显示大号购买/装备/已装备按钮，详情页和购买确认弹窗按钮同步放大，不可点击态统一灰化；验证截图见 `tmp/selection_button_polish_2026_07_05/`。
- [x] P1：图鉴购买态层级修复；未拥有但星星足够购买的条目保持整行暗态，只让“购买”按钮保持亮态；购买成功后解锁并自动装备，整行切换为拥有亮态，按钮切为装备/已装备。验证截图见 `tmp/collection_weapon_purchase_state_2026_07_12_v2.png`。
- [x] P1：局内三选一强化弹窗长屏布局二次修复；弹窗整体加高、在高屏设备上自适应下移并轻微增高，三张技能卡与底部按钮区重新拉开，小 badge / 标签 chip 内缩到装甲卡片框内，长按详情层同步跟随新面板尺寸。验证截图见 `tmp/card_offer_badge_inset_2026_07_12_v2.png` 与 `tmp/card_offer_badge_inset_2340_2026_07_12_v2.png`。
- [x] P1：战斗 HUD / Endless / 宠物成长 / 子弹生命周期打磨；生命条移到底部与经验条并排，金币超过 999 使用 `k` 缩写，波次条拉长且暖金填充，Toast 避开上下 HUD 并节流；无尽模式中途退出保留金币收益、每轮最终波保证 Boss，后续已改为复利升压；宠物增加可成长全局属性；追踪/分裂弹 5 秒或出屏即销毁。验证截图见 `tmp/hud_endless_pet_projectile_polish_2026_07_05/`，`python3 tools/check_release_candidate.py` 当前通过。
- [x] P1：子弹弹道规则细化；追踪弹出膛后先按枪管方向直飞 `1.0s`，再按最小转弯半径 `460px` 的角速度上限导引，避免原地掉头；所有子弹离开当前可见 1080x1920/高屏视口立即清除，飞行 `5.0s` 强制清除。`tools/m1_smoke_test.gd` 与 `tools/check_gameplay_polish.py` 已加回归护栏。
- [x] P1：多重射击/追踪叠加数值收口；多重射击最多 5 条弹道，按 2/3/4/5 条分别每发 `0.85/0.80/0.75/0.70` 伤害倍率衰减，避免追踪弹叠加后变成全额伤害弹幕；多重射击默认不附带弹射或分裂，跳弹技能只提供 `chain`，仍可和追踪、穿透、分裂等正常叠加。
- [x] P1：全关卡高屏战斗背景与防线触发修复；战斗背景改为底边固定的 cover 缩放，保留底部构图并向上补满高屏设备，99 关 / 10 个主线环境 / 14 个环境行均不再出现顶部缺口；僵尸攻击线改为按运行时 `BREACH_Y` 注入，普通怪、Boss、召唤怪都接近人物/基地模型后才开始攻击；威胁提示阈值同步按动态防线计算。新增 `tools/check_tall_battle_layout.py` 并接入 release candidate，验证截图见 `tmp/battle_safe_area_breach_fix_2026_07_06/battle_tall_after.png` 与 `tmp/battle_safe_area_breach_fix_2026_07_06/all_campaign_env_tall_cover_sheet.png`。
- [x] P1：高屏战斗背景黑区二次修复；10 张主线 battle background 从 `1080x1920` 扩展为 `1080x2622`，原底部防线构图保持在画布底部，运行时按真实可见高度底边锚定并禁用 `BackgroundExtension` 黑色渐变补区；`tools/check_tall_battle_layout.py` 加严主线背景尺寸/顶部暗空检测，`tools/check_visual_screens.py` 已覆盖全部 10 个主线环境的高屏 battle 真截图。验证截图见 `tmp/battle_storm_substation_tall_2340_fix_2026_07_07.png`，10 环境运行时总览见 `tmp/tall_battle_all_env_confirm_2026_07_07/all_campaign_tall_battle_runtime_sheet.png`，资产总览见 `assets/production/contact_sheets/contact_tall_battle_backgrounds_2026_07_07.png`。
- [x] P1：战斗人物 / HUD 遮挡复查修复；技能槽从底部居中横条改为左下两行紧凑 `GridContainer`，避开 4 角色 x 8 武器全套 idle/attack/hurt 可见包围盒；新增 `tools/check_battle_hud_overlap.py` 扫描 896 个角色武器动作帧，并验证人物、血条、经验条、主动技能按钮、技能槽和金币资源不互挡，已接入 `tools/check_release_candidate.py`。验证截图见 `tmp/hud_overlap_check_2026_07_06/battle_level_003.png`。
- [x] P1：防线内外侧对齐复查修复；普通僵尸/Boss 基地攻击线、远程腐蚀/毒雾/震地/寒潮/Boss 压制等基地受击爆点、基地护罩中心与破盾点、减速力场底边和实际减速判定全部改为从同一条运行时 `BREACH_Y` 派生；新增 `tools/check_battle_line_alignment.py` 并接入 release candidate，防止回退到旧固定 y 坐标。
- [x] P1：音乐/长音效叠播排查修复；BGM 保持全局单播放器，角色主动技长音效与胜败 stinger 纳入 `AudioManager.MUSIC_LIKE_SFX` 互斥组，切 BGM 时清理音乐型长音效；结算胜败音效只由 `meta/result` 单点触发，`loadout` / `collection` 进入时恢复地图 BGM，防止结算音乐串到装备/图鉴界面；新增 `tools/check_audio_overlap.py` 并接入 release candidate。
- [x] P1：开火音效仿真化；owner 反馈枪声像“青蛙叫”，已重建 8 个 `sfx_shot_*.wav` 和 4 个 `sfx_muzzle_*.wav` 为短促宽频枪口爆音 / 机械机件 / 能量尾音组合，机炮低频占比从约 `0.90` 降到约 `0.20`，火系 muzzle 低频占比从约 `0.80` 降到约 `0.01`；新增 `tools/check_weapon_sfx_quality.py` 并接入 release candidate。波形与指标见 `assets/production/source_refs/generated/weapon_sfx_realism_2026_07_07/weapon_sfx_realism_waveform_sheet_2026_07_07.png`。
- [x] P1：子弹命中音效差异化；owner 反馈子弹打到僵尸身上的受击声音怪，已重建 `sfx_hit_physical/fire/ice/lightning/poison/immune.wav`：物理为金属/肉体撞击，火焰为短促爆燃 + 灼烧尾音，冰霜为冰晶碎裂，闪电为明亮电击，毒素为腐蚀液体溅射，免疫为护盾金属 ping；新增 `tools/check_hit_sfx_quality.py` 并接入 release candidate。波形与指标见 `assets/production/source_refs/generated/hit_sfx_impact_2026_07_08/hit_sfx_impact_waveform_sheet_2026_07_08.png`。
- [x] P1：火焰命中与主动技能 VFX/SFX 重审修复；用 built-in `image_gen` 生成顶级渲染参考板并以本地脚本重建 `vfx_hit_fire`、`vfx_explosion_fire` 和 5 套角色主动技能 PNG 序列，火焰命中改为中心爆燃并去除抠图硬边/相邻帧串格；`battle.gd`/`projectile.gd` 取消火焰命中旧方向性粒子叠层，主动技能 intro 不再重复叠通用 muzzle；新增 `tools/check_active_skill_media.py` 并接入 release candidate，检查火焰中心性、alpha 边界、序列帧数和主动技 SFX 时长/响度。
- [x] P1：几何 projectile 原型重渲染；owner 指出 `proj_heavy_charge.png` / `proj_scatter_pellet.png` 仍像几何线条图标，已用 built-in `image_gen` 重新生成非几何渲染弹体并本地抠成 256x256 RGBA；普通 `skill_incendiary` 火焰弹拆为紧凑 `fire_round` 视觉，不再复用火焰喷射器大火球贴图。对比图见 `tmp/projectile_regen_2026_07_07/projectile_regen_contact_sheet.png`。
- [x] P1：关卡选择页对齐重构；顶部“角色/武器/护甲/芯片/宠物/技能”入口角标改为内嵌徽标，不再出框；关卡卡片右侧固定为两行星级区 + 横排“进入 / 挑战模式”按钮，星级上下间距、按钮高度和点击面积统一。验证截图见 `tmp/map_ui_alignment_polish_2026_07_06_v2.png`。
- [x] P1：战区地图顶部入口条尺寸二次打磨；`无限尸潮` 改用 980x96 原生装甲按钮，顶部六个入口卡片整体加高，图标可视区域和角色头像裁切框放大，状态角标改为短格式 `LvN / 未装 / 图鉴`，避免大字压住图标；四名角色头像统一上移并逐一截图确认。验证截图见 `tmp/map_nav_icon_endless_size_2026_07_12.png` 与 `tmp/map_nav_char_after_offset_sheet_2026_07_12.png`。
- [x] P1：大战区外层列表排版打磨；外层章节卡片统一 64px 左侧安全边距、300px 右侧操作列，标题/关卡范围/故事/目标不再贴边，右侧战区进度、双 Boss 节点和“进入战区”按钮统一对齐。后续按 owner 反馈把章节卡片高度从 `294` 提到 `344`，扩大故事/目标文字区，避免大字号裁字；验证截图见 `tmp/map_chapter_overview_spacious_2026_07_12.png`。
- [x] P1：战区详情页文字贴边修复；章节详情头卡统一安全内边距，左侧标题/故事/目标不再贴卡片边线，右侧“战区进度”和“返回战区地图”按钮内收，顶部装备入口角标也向内留边。验证截图见 `tmp/map_chapter_layout_polish_2026_07_07.png`。
- [x] P1：大战区章节地图落地；地图首屏从 99 个关卡直列表改为 10 个每十关一组的大战区卡片，数据化展示章节标题、故事、目标、进度、小 Boss（每 5 关）和大 Boss（每 10 关 / 终局），肃清上一战区后展开下一战区；进入大战区后再显示原分关卡列表，并保留“进入 / 挑战模式”横排按钮。验证截图见 `tmp/chapter_map_overview_2026_07_06.png` 与 `tmp/chapter_map_detail_2026_07_06.png`。
- [x] P1：第 3/4/5 波全局难度 +20%；通过 `economy.json` 后半段波次 HP 旋钮实现，普通/支援怪第 3 波 `1.20x`、第 4 波 `1.44x`、第 5 波 `1.62x`，Boss 独立 `1.20x`；同步运行时、压力检查与模拟工具口径，并对出现同类型压力回落的关卡做最小上调。
- [x] P1：第 20 关起 Boss 血量翻倍；新增 `economy.json.boss_hp_level_bonus`，运行时所有 `is_boss` 敌人在 `level_020+` 额外乘 `2.0` HP，挑战模式继续叠加挑战 HP 系数；压力/平衡/模拟工具已同步，只调 boss HP 不调 boss 伤害；为避免翻倍后 Boss 流压力回落，最小上调 `level_035/040/060/065/090/095/099` 的 `difficulty_coef` 下限。
- [x] P1：近线·冰普通小怪死亡火焰喷射感修复；死亡仍保留最后一击元素语义，但普通火系死亡改为尸体中心的短促燃尽、上升烟尘和径向冲击，不再归一成物理，也不再播放横向喷射感或大号 `vfx_explosion_fire`。
- [x] P1：敌人狂暴/火焰兜底横喷修复；定位到截图中的右侧火焰来自 `enrage` 敌人技能反馈兜底与旧火焰序列的横向火舌读法，已新增 `vfx_enemy_skill_enrage.png` 专用居中狂暴脉冲，并重建 `vfx_enemy_skill_enrage` / `vfx_hit_fire` / `vfx_explosion_fire` 序列为居中爆燃/热浪效果；`tools/check_gameplay_polish.py` 已加防回归，禁止 `enrage` 再退回大号横喷火焰。
- [x] P1：10 张主线高屏战斗背景无缝重建；从已生成的全高顶级环境源图重新裁切/平滑重映射到 `1080x2622`，保留第三关基准防线底部对齐，去掉顶部突兀补片感；运行时总览见 `tmp/seamless_tall_backgrounds_runtime_2026_07_08/all_campaign_tall_battle_runtime_sheet.png`。
- [x] P1：局内三选一强化弹窗文字排版修复；弹窗高度、标题、卡片、描述、标签和底部按钮重新留白，标题改为更清晰的 `选择强化 · 优先 X / Y`，避免卡片文案贴边、行距怪和按钮挤压；截图见 `tmp/card_offer_layout_polish_2026_07_08.png`。
- [x] P1：技能图鉴永久等级显示根因修复；技能列表、详情和升级刷新统一读取 `SaveManager.get_skill_base_level()`，不再通过通用装备 `get_item_level()` 显示成等级 1；`tools/m1_smoke_test.gd` 加入 4/2/0 多等级断言，截图见 `tmp/collection_skills_mixed_levels_fix_2026_07_08.png`。
- [x] P1：第 3 波以后难度再平衡；普通怪第 3/4/5 波 HP 旋钮提高到 `1.45/1.85/2.30`，Boss 波提高到 `1.30/1.50/1.75`，并从第 45-85 关线性叠到额外 `1.22x`，重点修复第 68 关低战力仍能通关的问题。战力显示同步提高通用技能永久等级与角色主动技等级权重，`level_068` 推荐战力 smoke 下限提高到 230+。
- [x] P1：Boss 走路速度 +50%；新增 `economy.json.BOSS_SPEED_MULT = 1.5`，运行时只对 `is_boss` 敌人在共享 `ENEMY_SPEED_MULT` 之后追加倍率，普通僵尸速度不变；`tools/m1_smoke_test.gd` 已断言经济旋钮与真实 boss spawn speed。
- [x] P1：冰子弹/冰技能减速可读性提升；被冰弹、冰主动技能或减速力场影响的僵尸会在减速期间叠加冰蓝色 sprite tint，视觉计时与数值减速分离，不额外改变减速倍率。
- [x] P1：全局按钮按 owner 指定厚装甲参考重做；撤回几何线条按钮方向，基于 `native_button_reference_owner_2026_07_09.jpg` 直接生成 72 张 runtime native 尺寸 PNG，并刷新 `ui_button_primary.png` / `ui_button_secondary.png` fallback；后续已把红/蓝分区改为柔和的暖/冷边缘光 + 中性 gunmetal 过渡；`UiKit` 按按钮尺寸解析 `ui_button_*_native_WxH.png`，结果、暂停、三选一、出战和设置页截图见 `tmp/button_runtime_native_review_2026_07_09.png`，smoke 回归断言禁止回到旧几何按钮批次。
- [x] P1：局内技能详情弹层排版修复；三选一长按/右键详情从旧的单个 `Body` 长文本改为本级数值、全部等级、长描述、标签和关闭按钮分区布局，打开详情时隐藏底层卡片/重抽/跳过按钮，避免文字溢出、关闭按钮压住等级列表和底层按钮透出。验证截图见 `tmp/card_detail_layout_polish_2026_07_08_v2.png`，`tools/m1_smoke_test.gd` 已加入详情弹层不重叠断言。
- [x] P1：所有模式第 4/5 波刷怪数量加强；新增 `economy.json.late_wave_count_mult = {"4":2,"5":3}`，运行时 `_queue_spawn_group()` 统一应用到普通、挑战和无尽模式的普通/支援怪，第 4 波数量翻倍、第 5 波数量三倍；`_compute_level_total_run_xp()`、压力检查、平衡档案、模拟和重建关卡工具已同步同一口径，smoke test 覆盖三种模式。
- [x] P1：防线屏障原型重渲染；用 built-in `image_gen` 生成高质感能量玻璃屏障源图，本地抠透明/适配为 `assets/production/sprites/vfx/vfx_barrier_glass.png`，运行时删除 `Polygon2D/Line2D` 原型屏障，改为普通 alpha 混合 Sprite，保留获得/破碎粒子反馈；来源和对比见 `assets/production/contact_sheets/barrier_glass_redo_2026_07_09.png`。
- [x] P1：结算页移动端布局修复；无限模式长标题拆成主标题 `无限尸潮` + 副标题 `坚持 N 轮 · 关卡名`，奖励数字改为 `k/m` 缩写，Hero/奖励/提示/按钮统一 920px 内安全宽度并联动装甲按钮尺寸，避免标题出框、按钮撑破容器和奖励卡拥挤。截图见 `tmp/result_layout_after_2026_07_08.png` 与 `tmp/result_layout_victory_after_2026_07_08.png`，`tools/m1_smoke_test.gd` 已加无限结算标题和大数字格式断言。
- [x] P1：无尽模式难度曲线加陡；新增 `economy.json.endless_loop_hp_growth = 0.50`，完成整轮后的 HP 倍率从旧线性 `1.0 + 0.22 * loop` 改为复利 `pow(1.5, loop)`，普通怪和 Boss 都走同一无尽 HP 系数，smoke test 断言每轮至少比上一轮提高 50%。
- [x] P1：无尽模式奖励口径收口；无尽结算只发金币，不发账号经验和星星，最高轮数仍记录；`battle.gd` 无尽 payload 固定 `xp=0/stars=0`，`SaveManager.apply_endless_result()` 即使收到旧 `xp/stars` 字段也忽略，结算页隐藏经验卡和星星行，smoke test 覆盖存档、payload 和 UI 三层。
- [x] P1：主菜单标题霸气化；`尸潮防线` 从普通 Label 换成透明 PNG 标题模型 `assets/production/sprites/ui/ui_menu_title_shichao_fangxian.png`，按 owner 反馈放弃本地字体特效方向，改用 image_gen 直接渲染裂纹钢石 3D 大字并本地抠透明/适配到 runtime；副标题文案改为 `火力封锁，寸土不让`，来源说明登记到 `assets/production/source_refs/generated/menu_title_logo_2026_07_10/` 与 `OUTSOURCER_ASSET_INDEX.json`。
- [x] P1：关卡入口锁定规则修复；地图关卡卡片普通入口只按关卡解锁启用，挑战入口必须同关普通模式已拿 3 星才可点击；未达成时按钮灰化且 `_open_challenge_level()` 路由防护会阻止绕过，smoke test 覆盖未通关 / 普通 2 星 / 普通 3 星三种状态。
- [x] P1：所有敌人行进速度全局 +20%；`economy.json.ENEMY_SPEED_MULT` 从 `0.41` 提高到 `0.492`，运行时普通僵尸和 Boss 都走同一全局速度旋钮，Boss 仍额外叠加既有 `BOSS_SPEED_MULT = 1.5`；smoke test 已同步断言新倍率。
- [x] P1：无尽模式首轮曲线独立化；无论从哪一关进入，无尽都使用 `economy.json.endless_template_level = level_025` 作为首轮波次、HP、金币等级和推荐强度模板，目标是 20-30 关战力可完成第一轮；后续轮次仍按 `endless_loop_hp_growth = 0.50` 复利升压。第一轮 Boss 移除硬免疫墙，避免出现“开局不掉血”的体验，smoke test 覆盖 `level_001` 与 `level_076` 入口一致性。
- [x] P1：战斗 HUD 主动技能横线与 HP 槽修复；重生成 `ui_skill_slot*.png`，去掉右下主动技能按钮的外伸黄色横线；重建 `ui_base_hp_bar.png` / `ui_bar_fill_hp.png` 为独立空槽 + 红色填充，并在 `battle.gd` 用 `FillClip` 裁切 HP 填充，避免拉伸和出槽。
- [x] P1：顶部波次条原生重渲染与 Boss 规则反馈；owner 确认问题是顶部黄色波次条，已把 `ui_wave_progress.png` 重建为 720x46 原生槽体，并新增 `ui_wave_progress_fill_native.png`，运行时用 `FillClip` 裁切进度而不是拉伸黄条；后续移除黄条填充里的内描边/分段细线，改成厚实金色胶囊填充；Boss 免疫/护盾/相位/破甲命中增加高优先级弱点提示浮字；追踪弹在近距离 Boss 压线时跳过 1 秒出膛延迟但继续遵守最小转向半径。
- [x] P1：高屏结算/弹框垂直位置统一修复；结算页、暂停页、三选一强化页、强化详情页和通用确认弹框都接入同一套高屏下移公式，1080x1920 保持原布局，高屏 iPhone 按额外高度下沉，避免弹框整体偏上。验证截图见 `tmp/result_modal_tall_shift_2026_07_12.png`、`tmp/pause_modal_tall_shift_2026_07_12.png`、`tmp/card_offer_modal_tall_shift_2026_07_12.png`、`tmp/card_detail_modal_tall_shift_2026_07_12.png`。
- [x] P1：暂停弹框可读性重排；暂停页面板改为更宽高的舒展版，标题、战场状态、出战配置、已带技能和底部三枚操作按钮整体字号上调，技能 chip 改为三列大卡，按钮切到 760x112 原生装甲尺寸，避免小字堆叠和按钮拉伸。验证截图见 `tmp/pause_readability_layout_default_2026_07_12.png` 与 `tmp/pause_readability_layout_tall_2026_07_12.png`。
- [x] P1：技能规则二次平衡；减速力场覆盖改为 30%/40%/50%/60%/70%，减速强度保留原曲线；防线屏障改为增加基地生命上限 +20%/+40%/+60%/+80%/+120% 并即时补满新增血量；“弱点暴击”重命名为“蓄能重击”；原“蓄能重击”改为“伤害穿透”，提供直接伤害和护甲/护盾本体穿透；战术回收收口为单级 +1 重抽。
- [x] P1：冰川领域主动技改为全屏控制；触发后几乎覆盖全战场，持续减速并周期造成冰霜伤害，被影响僵尸在控制期间保持冰蓝冻结覆盖效果，避免只靠瞬时波纹导致控制状态不可读。

## 阶段 14 · App Store 上线级加固（2026-07-13）

- [x] P0：存档改为临时文件写入 + 校验 + 原子替换，保留上一份可恢复备份；损坏主存档会自动回退备份，新增独立故障注入测试覆盖截断 JSON、写入失败与恢复路径。
- [x] P0：战斗结算与终局规则收口；召唤/分裂子单位不再重复发金币经验，终局/无尽 Boss 选择按 `appear_level` 取当前可用最强项，Boss 硬免疫保留规则提示同时提供最低伤害通路，避免错误配装造成绝对软锁。
- [x] P0：弹道与技能组合一致化；手动锁定目标会传给追踪弹，近距离 Boss 可立即导引，连锁/范围伤害继续携带破甲与元素状态，武器原生 pellet 与多重射击 lane 分层计算且只对 lane 使用既定衰减。
- [x] P0：应用生命周期加固；切后台/失焦时立即落盘、取消残留触控与瞄准输入、暂停音频，恢复前台时统一恢复音频状态；数据表加载失败会阻止进入不完整运行态。
- [x] P1：战斗 VFX 以 authored PNG 序列为主路径，程序化圆环仅保留缺图兜底；低电量或高敌人数时主动收紧粒子预算，避免第 4/5 波密集尸潮出现移动端掉帧和视觉噪声。
- [x] P1：音频总线、BGM 循环、优先级与并发上限建立自动检查，测试销毁后播放器零残留；导入设置统一关闭不必要的长音频常驻内存。
- [x] P1：全局移动端 UI 统一安全区与最小触控面积，修复战区详情正文/任务目标重叠；31 个路由截图覆盖 10 张高屏战斗背景、暂停、三选一、技能详情、结算与 debug safe-area。
- [x] P1：发布门禁补充导出预设、Godot 日志告警、包内容/体积和战斗启动检查；候选包脚本只有在静态数据、真实渲染截图、smoke 与日志检查全部通过后才允许进入上传阶段；本轮 `python3 tools/check_release_candidate.py` 已完整通过。
