# 22 · 第一阶段盘点：霓虹雷暴主题 + 终焉·雷霆军械

> 状态：盘点、Phase 1A-1 / 1A-2 和 Phase 1B-1 主题运行骨架均已完成。Owner 已确认整体渲染方向，并以继续执行确认中案三线圈电弧炮。ThemeManager、精确尺寸霓虹按钮和运行时衣装虹彩已接入；StoreKit 与数值修改仍未开始。
> Owner 决策：第一套从原计划的黑曜 / 动能改为 **霓虹雷暴 / 雷霆**。
> 总方案：`design/21_premium_themes_and_apocalypse_arsenal_plan.md`。
> 当前生产提交基线：`1.0.0 (38)`，无 IAP、无主题系统、无终焉装备；最新 TestFlight `1.0.0 (40)` 是强制启用霓虹主题并包含完整中英文运行时的联合视觉验收包，不可直接用于 App Review。
> 本文回答“第一套具体有什么要搞、现状缺什么、按什么顺序做、每一步怎么验收”。

---

## 0. 盘点结论

这套可以做，而且现有项目已经有较好的雷电战斗基础，但不能直接开始批量出图。第一阶段实际包含六条工作线：

1. **模块化角色 / 武器战斗表现**
   - 解决四角色 × 多武器主题动画重复导致的包体爆炸。
2. **全局主题资源路由**
   - 让菜单、地图、收藏、配装、设置、结算、HUD、基地和 Logo 能按主题切换并安全回退。
3. **雷霆军械四件套**
   - 天罚电弧炮、雷暴导体甲、超导风暴核心、风暴球体及 2 / 4 件套。
4. **StoreKit 与永久权益**
   - 主题 `1.99`、完整军械 `6.99`、主题拥有者升级 `4.99`。
5. **中英文商店和收藏体验**
   - 商品、装备、套装、购买状态和 App Store 素材全双语。
6. **数值、视觉、性能和购买验收**
   - 免费基线不变，终焉满级真实输出目标 `1.52x~1.58x`。

当前最需要先解决的不是数值，而是两个视觉架构门禁：

- **角色和武器必须模块化**，不能为每个主题重复全部合成开火帧。
- **基地必须使用独立底部覆盖层**，不能为每个主题复制全部 14 张战场大背景。

如果这两个门禁不先通过，四套主题会让包体、制作量和维护成本失控。

---

## 1. 现有内容基线

### 1.1 数据规模

| 分类 | 当前数量 | 雷电参考内容 |
|---|---:|---|
| 角色 | 4 | `volt` |
| 武器 | 8 | `weapon_teslacoil` |
| 护甲 | 6 | `armor_faraday` |
| 芯片 | 8 | `chip_element` |
| 宠物 | 6 | `pet_volt_orb` |
| 局内技能 | 16 | `skill_tesla` 等 |
| 角色主动技 | 4 | `sig_volt_storm` |
| 关卡 | 99 | 完整免费战役 |

### 1.2 当前雷电构筑

#### 电弧少女

- 角色 ID：`volt`
- 属性：`lightning`
- 满级：40
- 基础攻速倍率：`1.08`
- 主动技：`sig_volt_storm`
- 子弹亲和：
  - 连锁加成。
  - 超出参考连锁数后转化为主目标伤害。
  - 连锁逐目标衰减。
- 当前逻辑已经支持“连锁不靠生硬小上限结束”，适合终焉雷霆继续扩展。

#### 特斯拉线圈

- ID：`weapon_teslacoil`
- 满级：50
- 属性：雷。
- 弹道：`chain`
- 当前基础连锁：2。
- 已有图标、手持枪、炮台和角色组合动画。

#### 法拉第护甲

- ID：`armor_faraday`
- 满级：35。
- 当前定位：雷抗和基地生存。

#### 元素芯片

- ID：`chip_element`
- 满级：35。
- 当前定位：元素伤害提升。

#### 电弧球

- ID：`pet_volt_orb`
- 满级：30。
- 当前技能：`arc_overload`。
- 已有多目标攻击、逐目标衰减和随等级增加目标数。

### 1.3 当前免费雷电 DPS 基线

最新 `tools/audit_character_endgame_dps.py` 结果：

| 项目 | 当前值 |
|---|---:|
| 角色 | `volt` |
| 最优武器 | `weapon_teslacoil` |
| 最优芯片 | `chip_element` |
| 当前审计最优宠物 | `pet_fire_imp` |
| 单 Boss 总 DPS | `137,219` |
| 五弹道全部有效时总 DPS | `200,506` |
| 审计连锁数 | `13` |

终焉·雷霆满级初始目标：

| 口径 | `1.52x` 下限 | `1.55x` 中心 | `1.58x` 一般上限 |
|---|---:|---:|---:|
| 单 Boss 总 DPS | 208,573 | 212,689 | 216,806 |
| 五弹道全有效总 DPS | 304,769 | 310,784 | 316,799 |

这些只是基于当前审计的第一版基线。正式接入后必须使用真实新装备数据和运行时命中重新计算，不能把表中数字硬编码为最终结果。

---

## 2. 现有素材盘点

### 2.1 静态素材

当前目录规模包含 Godot `.import` 记录，实际源 PNG 约为其一半：

| 目录 | 当前文件项 | 目录体积 |
|---|---:|---:|
| `sprites/characters` | 32 | 7.1 MiB |
| `sprites/weapons` | 48 | 5.6 MiB |
| `sprites/equipment` | 28 | 5.9 MiB |
| `sprites/pets` | 36 | 2.9 MiB |
| `sprites/backgrounds` | 32 | 55 MiB |
| `sprites/ui` | 346 | 17 MiB |
| `sprites/projectiles` | 22 | 348 KiB |

### 2.2 角色和武器动画

| 动画形态 | 实际 PNG | 目录体积 | 说明 |
|---|---:|---:|---|
| 角色 × 武器合成动画 | 992 | 184 MiB | 4 角色 × 8 武器，每个组合约 31 帧 |
| 无武器角色动画 | 44 | 6.3 MiB | 4 角色，每人约 11 帧 |
| 独立武器动画 | 56 | 2.1 MiB | 8 武器，每把约 7 帧 |

`battle.gd` 当前优先加载合成动画；如果找不到合成动画，已经可以回退到：

```text
角色无武器动画 + 独立手持武器 / 武器动画
```

这条 fallback 是主题系统最重要的现成基础。

### 2.3 不可接受的直接复制方案

如果霓虹主题复制全部角色 × 武器合成帧：

- 单主题约再增加 992 张运行时 PNG。
- 按当前素材约增加 184 MiB。
- 四主题可能增加约 736 MiB。
- 还没有计算终焉武器、VFX、UI、基地和营销素材。

因此禁止为每个主题完整复制所有合成动画。

### 2.4 第一阶段采用的模块化方案

霓虹主题战斗角色改走模块化表现：

1. 主题化无武器角色动画。
2. 主题化独立武器层。
3. 每角色的武器 socket、缩放和前后遮挡数据。
4. 枪口位置和左右瞄准偏移。
5. 必要时增加少量“前臂 / 手掌前景层”，解决握枪穿帮。
6. 终焉武器使用同一模块化接口。

第一阶段预计主体动画量：

- 4 名角色：44 张左右。
- 8 把免费武器：56 张左右。
- 1 把天罚电弧炮：约 7~12 张主体帧。
- 少量前臂 / 遮挡覆盖层。

目标是用约 110~130 张主体 PNG 完成第一主题战斗覆盖，而不是 1,100 张以上合成帧。

### 2.5 模块化方案必须验证的组合

完整霓虹主题最终需要验证：

- 4 名角色 × 8 把免费武器。
- 4 名角色 × 天罚电弧炮。
- 合计 36 个角色 / 武器组合。

Phase 1A 先验证四个代表组合：

1. 电弧少女 + 特斯拉线圈：同属性、最重要展示位。
2. 钢铁先锋 + 自动机枪：壮硕角色与短枪械基准。
3. 火焰少年 + 火焰喷射器：年轻角色与长枪械。
4. 冰霜少女 + 磁轨炮：女性角色与大型武器。

四个代表组合必须无：

- 枪穿身体。
- 手掌漂浮。
- 头顶裁切。
- 左右攻击反向。
- 枪口与弹体起点错位。
- 开火时角色、武器不同步。

如果代表组合失败，停止主题批量素材，先修模块化渲染。

---

## 3. 现有雷电特效基础

当前已有七组主要雷电视觉：

| 序列 | 当前目录体积 | 用途 |
|---|---:|---|
| `vfx_active_sig_volt_storm` | 3.1 MiB | 电弧少女主动技 |
| `vfx_chain_lightning` | 2.0 MiB | 连锁电弧 |
| `vfx_hit_lightning` | 680 KiB | 雷电命中 |
| `vfx_muzzle_lightning` | 408 KiB | 雷电枪口 |
| `vfx_skill_cast_tesla` | 2.7 MiB | 雷系技能 |
| `vfx_enemy_skill_storm_chain` | 2.2 MiB | 敌方风暴链 |
| `vfx_boss_attack_storm` | 2.5 MiB | Boss 雷击 |

现有雷柱品质得到 Owner 认可，可以作为光照、能量密度、边缘衰减和命中重量的质量参考。

但终焉军械不能直接把现有序列改名复用。需要新建独立 premium VFX ID：

- `vfx_apocalypse_thunder_charge`
- `vfx_apocalypse_thunder_muzzle`
- `vfx_apocalypse_thunder_arc`
- `vfx_apocalypse_thunder_chain`
- `vfx_apocalypse_thunder_overload_mark`
- `vfx_apocalypse_thunder_overload_burst`
- `vfx_apocalypse_thunder_armor_counter`
- `vfx_apocalypse_thunder_pet_cast`
- `vfx_apocalypse_thunder_pillar`
- `vfx_apocalypse_thunder_kill`
- `vfx_apocalypse_thunder_awaken`

现有序列可以作为：

- 光色和亮度参考。
- 降级模式 fallback。
- 非终焉雷系技能继续使用的默认资源。

不得覆盖现有已验收雷电序列。

---

## 4. 主题 UI 与场景触点

### 4.1 Phase 1B-1 运行时现状

- `ThemeManager` 已通过 `data/themes.json` 解析 `default / neon_tempest`。
- Save v2 保存主题选择和已验证永久 entitlement；无权益或资源缺失会回退默认主题。
- 开发 fixture：Debug 构建设置 `ZOMBIE_FIRE_THEME_PREVIEW=neon_tempest`，不伪造生产购买。
- `UiKit` 已把所有标准装甲按钮语义路由至主题资源。
- 短、紧凑、标准、长、超长和 `17:1` HUD 丝带六类模型生成 72 张精确尺寸 PNG，运行时使用 keep-aspect，禁止 `STRETCH_SCALE`。
- 战斗角色和结算肖像使用轻量衣装虹彩 shader；头脸保护带排除上部，减弱特效时停止流动并降亮。

### 4.2 原始硬编码盘点

仓库中当前约有：

- 95 处直接 UI 资源路径引用。
- 分布在 17 个 `.gd` / `.tscn` 文件。
- 约 40 个唯一 UI 资源路径。
- 8 处直接背景引用。

主要触点：

- `ui/ui_kit.gd`
- `meta/menu/`
- `meta/map/`
- `meta/loadout/`
- `meta/collection/`
- `meta/settings/`
- `meta/result/`
- `gameplay/battle/`
- `gameplay/hud/`
- `gameplay/enemy/`

目前不存在 `ThemeManager`，场景中的 `.tscn` ext_resource 也都是默认纹理。

### 4.2 哪些 UI 应主题化

霓虹主题需要替换的结构性资源：

- 主 / 次按钮。
- 通用面板和弹窗底板。
- 地图卡片、装饰条和 pill。
- 角色 / 武器 / 装备卡框。
- 经验、波次、基地生命、Boss 生命的外框。
- HUD 技能槽、暂停框和组合计数框。
- 菜单标题 Logo。
- 结算和战报框。
- 商品卡和拥有状态框。

### 4.3 哪些 UI 不应被主题覆盖

保持功能语义的资源：

- 金币、经验、星星图标。
- 火、冰、雷、毒、物理元素图标。
- 危险、警告、免疫、弱点、锁定标记。
- 红色生命填充。
- 绿色成功 / 治疗。
- 毒绿色持续状态。
- 无障碍和降低特效提示。

主题可以改变外框、材质和微光，不能改变功能含义。

### 4.4 ThemeManager 需要提供的能力

计划新增：

```text
ThemeManager.get_active_theme_id()
ThemeManager.is_theme_owned(theme_id)
ThemeManager.equip_theme(theme_id)
ThemeManager.resolve_asset(default_path, semantic_role)
ThemeManager.resolve_character_asset(character_id, usage)
ThemeManager.resolve_weapon_asset(weapon_id, usage)
ThemeManager.resolve_ui_asset(asset_id)
ThemeManager.resolve_base_overlay(environment_id)
ThemeManager.get_palette(role)
```

规则：

- 没有主题或找不到主题资源时，100% 回退默认路径。
- 主题切换后重载当前局外场景，不要求在一个已打开页面里热替换所有 Control。
- 一场战斗开始后锁定主题，战斗中不允许切换。
- `UiKit` 缓存 key 必须包含主题 ID，切换后清理主题相关缓存。
- `.tscn` 的默认 ext_resource 保留为安全 fallback，主题资源在 `_ready` 后通过统一函数覆盖。

---

## 5. 基地与战场背景问题

### 5.1 当前事实

- 主要战场背景为 `1080×2622`。
- 当前约 14 个环境。
- 炮台防线、路障和底部基地视觉已经画进每张大背景。
- 当前背景目录约 55 MiB。
- 长屏适配按背景底部锚定，角色、宠物和 HUD 与防线一起下移。

### 5.2 不采用的方案

不为霓虹主题重新生成全部 14 张完整战场背景：

- 会重复环境主体。
- 显著增加包体。
- 可能改变关卡辨识和敌人对比度。
- 后续四主题将变为 56 张大背景。

### 5.3 建议方案：底部基地覆盖层

增加一张或少量霓虹基地覆盖层：

- 透明或局部不透明。
- 1080 宽。
- 只覆盖底部防线和基地区域。
- 与当前 `bottom_dock_shift` 使用相同底部锚点。
- 上缘使用烟雾、暗部、线缆或能量雾柔和融合。
- 保留环境上半部和道路。

Phase 1A 至少合成验证：

1. 熔岩铸厂。
2. 冰川通道。
3. 风暴变电站。
4. 终焉核心。

如果一个覆盖层不能在四种明暗环境中成立，再考虑：

- 明 / 暗两版覆盖层。
- 环境色调参数。
- 最后才考虑少量环境专版。

### 5.4 霓虹基地内容

- 高压防线。
- 紫蓝能量护墙。
- 特斯拉导轨。
- 中央脉冲核心。
- 左右放电塔。
- 与角色、宠物和底部 HUD 不冲突的低位光源。
- 基地受击时只增强局部电流，不做全屏闪白。

---

## 6. 霓虹雷暴主题素材清单

### 6.1 四角色服装

每名角色需要：

- 图标。
- 半身像。
- 无框半身像。
- 收藏 / 配装展示图。
- 无武器战斗动画。
- 必要的前臂 / 手掌遮挡层。

角色身份要求：

#### 钢铁先锋

- 壮硕成熟男性。
- 黑色复合重甲。
- 青蓝主能量管。
- 紫色辅助电路。
- 不做成轻薄赛博忍者。

#### 火焰少年

- 年轻男性。
- 高机动短夹克和轻甲。
- 紫黑主体，保留少量橙红个人识别。
- 不改成与先锋相同的厚重装甲。

#### 冰霜少女

- 成熟冷峻女性。
- 银黑长线条战衣。
- 冰蓝与极光紫结合。
- 保留冰系身份，不被霓虹紫完全吞没。

#### 电弧少女

- 雷系主题主展示角色。
- 深蓝黑高机动战衣。
- 发光电路、悬浮线圈和不对称电能模块。
- 轮廓必须比默认服装明显更高级。

### 6.2 八把免费武器涂装

每把需要：

- 收藏图标。
- 手持静态图。
- 炮台图。
- 独立武器动画。

统一语言：

- 深色枪体。
- 紫蓝导电槽。
- 亮青边缘读数。
- 少量粉红高能警示。
- 不改变武器原有类别轮廓。

特殊要求：

- 火焰喷射器仍能一眼读成火。
- 冰霜炮仍能一眼读成冰。
- 毒液发射器仍保留毒绿功能色。
- 物理武器使用霓虹结构，但弹道不变成雷电。

### 6.3 局外和 HUD

- 主题菜单背景。
- 游戏内霓虹 Logo。
- 主 / 次按钮。
- 面板、卡片、资源框。
- 地图章节卡、关卡卡和导航底座。
- 收藏和详情框。
- 配装卡。
- 设置页。
- 结算 / 战报。
- HUD 波次、经验、生命、金币、主动技能和暂停。
- 商店主题卡、完整军械卡和升级卡。

### 6.4 品牌素材

- 主题 Key Art。
- 中英文主题 Logo。
- 商品图。
- IAP 审核图。
- App Store 截图用组合版。
- 可选 Alternate App Icon。

App Store 主图标不随用户购买动态变化；霓虹图标只作为可选桌面图标或营销图。

---

## 7. 终焉·雷霆军械四件套

### 7.1 数据 ID

- `weapon_apocalypse_thunder`
- `armor_apocalypse_conductor`
- `chip_apocalypse_superconductive`
- `pet_apocalypse_tempest`
- `set_apocalypse_thunder`

### 7.2 天罚电弧炮

核心体验：

- 枪身由悬浮线圈、分段导轨和中心能量核构成。
- 开火前线圈相位对齐。
- 主电弧从底部枪口明确指向首要目标。
- 从主目标继续向有效邻近目标跳跃。
- 不设低数字硬上限；使用距离、目标去重、逐跳衰减和每次结算性能预算。
- 重复击中同一目标积累过载。
- 过载爆发不是普通圆形闪光，而是贴合目标身体的电荷塌缩与垂直回击。

需要的新表现：

- 待机线圈运动。
- 蓄能。
- 主电弧。
- 分支连锁。
- 过载标记。
- 过载爆发。
- 命中。
- 暴击。
- 满级觉醒。

### 7.3 雷暴导体甲

核心体验：

- 提高基地生命和护盾恢复。
- 连续越线攻击积累导体充能。
- 达到阈值后对最近威胁释放防线反击雷击。
- 每次反击有明确冷却，不能形成永久控制或无限雷击。

视觉：

- 基地防线出现导电网格。
- 护盾受击时电流沿防线扩散。
- 反击从基地导轨向上发射，方向必须正确。

### 7.4 超导风暴核心

核心体验：

- 提高雷伤、射速和连锁伤害保留。
- 增强过载积累效率。
- 不直接无限增加连锁目标。
- 使用衰减和目标去重保持性能可控。

视觉：

- 收藏页核心持续低频旋转。
- 升级阶段逐步增加环数、亮度和放电频率。
- 满级不得只是图标外框变金。

### 7.5 风暴球体

核心体验：

- 寻找敌人密集区域。
- 普通攻击释放可读的短链。
- 技能周期性标记多个高威胁目标。
- 满级技能召唤 Owner 已认可标准的终结雷柱。
- 玩家手动锁定时，优先协同主目标，再寻找邻近链路。

视觉：

- 球体本体不沿用现有电弧球简单换色。
- 使用多环悬浮、中心雷核和动态极性变化。
- 雷柱必须有预警、落点、主柱、地面接触和衰减。

### 7.6 套装

2 件套：

- 过载积累更快。
- 连锁衰减略降低。

4 件套：

- 过载爆发时风暴球体同步寻找最佳密集点。
- 满足冷却条件后召唤终结雷柱。
- 雷柱只对同一批目标结算一次，避免重复触发套装自身。

所有套装伤害都计入 `1.52x~1.58x` 总预算。

---

## 8. 升级和视觉阶段

| 阶段 | 武器 | 护甲 | 芯片 | 宠物 | 主要变化 |
|---|---:|---:|---:|---:|---|
| 原型 | 1 | 1 | 1 | 1 | 完整高级轮廓和基础专属攻击 |
| 激活 | 13 | 9 | 9 | 8 | 第一层电路点亮、核心机制开启 |
| 强化 | 25 | 18 | 18 | 15 | 2件套、连锁和命中表现升级 |
| 过载 | 38 | 26 | 26 | 23 | 机械展开、过载爆发和击杀反馈 |
| 觉醒 | 50 | 35 | 35 | 30 | 4件套、满级形态和终结雷柱 |

技术上不为每一级生成新主体：

- 主体使用少量视觉 tier。
- 中间等级使用覆盖层、粒子、材质和数值变化。
- 满级才切换觉醒主体 / 关键动画。

---

## 9. StoreKit 盘点

### 9.1 当前状态

- 仓库不存在 StoreKit 实现。
- 不存在 `PurchaseManager`。
- 不存在 `.storekit` 本地配置。
- 不存在 `res://ios/plugins` 下的 IAP 插件。
- `project.godot` 当前只有 DataLoader、SaveManager、SettingsManager、InputManager、AudioManager 五个 autoload。
- 当前收藏“购买”只消耗游戏内星星，与 Apple IAP 无关。

### 9.2 第一阶段需要三个商品

- `com.gaojiasheng.zombiefire.theme.neon_tempest`
- `com.gaojiasheng.zombiefire.arsenal.thunder_complete`
- `com.gaojiasheng.zombiefire.arsenal.thunder_upgrade`

逻辑 entitlement：

- `ent_theme_neon_tempest`
- `ent_arsenal_thunder`

### 9.3 技术路线

- 使用 Godot iOS plugin 暴露 StoreKit 2 能力给 GDScript。
- 插件文件进入 `res://ios/plugins` 并由 iOS export preset 启用。
- GDScript `PurchaseManager` 只接收已经验证的交易结果。
- 使用 `Transaction.currentEntitlements` 恢复非消耗型商品当前权益。
- 监听交易更新和退款 / 撤销。
- 设置页提供显式“恢复购买”。
- 正式商品前先使用 Xcode StoreKit Configuration。

官方参考：

- Godot iOS plugin：<https://docs.godotengine.org/en/stable/tutorials/platform/ios/ios_plugin.html>
- Apple current entitlements：<https://developer.apple.com/documentation/storekit/transaction/currententitlements>
- Apple IAP 完成与恢复：<https://developer.apple.com/documentation/storekit/offering-completing-and-restoring-in-app-purchases>

### 9.4 当前存档缺口

`SaveManager` 当前：

- `CURRENT_SAVE_VERSION = 1`。
- `unlocks` 只表示游戏内拥有。
- `purchase_item()` 只扣星星。
- `equipment` 保存等级和已装备项。

需要：

- 存档版本迁移。
- premium entitlement 缓存。
- 主题装备状态。
- 终焉装备休眠等级。
- 退款后的合法装备回退。
- 存档重置与 Apple 权益分离。

不能把 Apple 付费装备直接塞进星星 `purchase_item()`，否则购买真源和退款逻辑会混在一起。

---

## 10. 中英文缺口

### 10.1 当前事实

- 目前只有 `data/localization_zh.json`。
- `DataLoader.tr_key()` 固定读取中文表。
- 没有 locale manager。
- 没有系统语言跟随或语言设置。
- 代码和场景仍存在大量中文直写。

### 10.2 第一阶段需要

- `localization_en.json`。
- locale manager / 当前语言状态。
- 商店和终焉内容全部使用 key。
- 中英文商品标题、描述和 App Store IAP 元数据。
- 中文、英文分别跑标准屏和长屏。
- 英文不通过缩小字号解决溢出。

由于 Owner 已要求完整中英文版本，商业化接入前必须至少完成商店和新内容双语；全 App 双语仍按此前国际化计划推进。

---

## 11. 预计代码和数据触点

### 11.1 新增

- `core/theme/theme_manager.gd`
- `core/store/purchase_manager.gd`
- `data/themes.json`
- `data/store_products.json`
- `data/premium_sets.json`
- `data/localization_en.json`
- `ios/plugins/zombie_fire_storekit/`
- Xcode StoreKit Configuration。
- 主题和终焉素材目录。
- 主题覆盖与 premium DPS 检查工具。

### 11.2 修改

- `project.godot`
- `core/data/data_loader.gd`
- `core/save/save_manager.gd`
- `ui/ui_kit.gd`
- `gameplay/battle/battle.gd`
- `gameplay/projectile/projectile.gd`
- `gameplay/enemy/enemy.gd`
- 宠物运行时。
- `meta/menu/`
- `meta/map/`
- `meta/loadout/`
- `meta/collection/`
- `meta/settings/`
- `meta/result/`
- `data/characters.json`
- `data/weapons.json`
- `data/armors.json`
- `data/chips.json`
- `data/pets.json`
- `design/data/schema.md`
- `design/data/naming_convention.md`
- `tools/validate_data.py`
- `tools/m1_smoke_test.gd`
- `tools/check_visual_screens.py`
- iOS export preset / 发布脚本。

### 11.3 新素材建议路径

正式创建前同步 naming convention，建议：

```text
assets/production/sprites/themes/theme_neon_tempest/
  characters/
  animations/characters_weaponless/
  animations/weapons/
  weapons/
  ui/
  backgrounds/
  branding/

assets/production/sprites/premium/arsenal_thunder/
  weapons/
  equipment/
  pets/
  animations/
  projectiles/
  vfx_sequences/
  branding/
```

源文件：

```text
assets/production/source_refs/generated/neon_tempest_thunder_phase1_<date>/
```

所有最终素材仍需登记 `assets/production/OUTSOURCER_ASSET_INDEX.json`。

---

## 12. 第一阶段工作分解

### Phase 1A · 视觉与模块化可行性

只做候选和证明，不替换运行时：

1. 霓虹综合色板。
2. 四角色服装联系表。
3. 三把代表免费武器霓虹涂装：
   - 自动机枪。
   - 特斯拉线圈。
   - 火焰喷射器或毒液发射器。
4. 菜单、地图卡、HUD、基地覆盖层和 Logo 样例。
5. 天罚电弧炮三种全新轮廓。
6. 雷暴导体甲、超导核心和风暴球体方向。
7. 六段雷霆攻击分镜。
8. 四组模块化角色 / 武器合成样例。
9. 四环境基地覆盖层合成。
10. 一张 `1080×2340` 真实战场综合图。

通过条件：

- Owner 认可主题和终焉层级。
- 模块化角色 / 武器无穿帮。
- 基地覆盖层在四环境成立。
- 终焉武器明显不是特斯拉线圈换色。

### Phase 1B · 最小主题运行时

1. ThemeManager。
2. 主题数据和 fallback。
3. 霓虹模块化角色 / 武器路径。
4. 菜单、地图、配装、收藏和战斗五个代表场景。
5. 默认 / 霓虹主题切换。
6. 无权益 debug fixture。
7. 主题缓存清理和场景重载。

通过条件：

- 默认视觉完全不变。
- 霓虹主题无资源缺失。
- 代表场景切换无崩溃、无混搭。
- 包体增量符合预算。

### Phase 1C · 雷霆军械数据和战斗

1. 四件装备数据。
2. 等级和金币曲线。
3. 天罚电弧炮。
4. 过载状态。
5. 雷暴导体甲。
6. 超导核心。
7. 风暴球体。
8. 2 / 4 件套。
9. 五阶段视觉。
10. 战斗报告计入全部新伤害。

通过条件：

- 目标选择尊重手动锁定。
- 连锁无硬上限但有衰减、去重和性能预算。
- 不出现无限递归或同目标重复结算。
- 免费雷电基线不变。

### Phase 1D · 商店和 StoreKit

1. 三商品本地 StoreKit 配置。
2. iOS plugin 技术验证。
3. PurchaseManager。
4. entitlement 状态。
5. 主题补差显示。
6. 购买、取消、pending、失败。
7. 恢复、退款、换机。
8. 收藏 / 设置商店入口。
9. 中英文商品详情。

通过条件：

- 主题拥有者只看到升级商品。
- 完整包一次授予两个 entitlement。
- 非法 / 未验证交易不授予内容。
- 退款后安全回退。

### Phase 1E · 完整素材

1. 四角色全部展示与战斗素材。
2. 八把免费武器全部霓虹涂装。
3. 雷霆四件套完整模型。
4. 全链路 VFX。
5. 音频与触感。
6. UI、基地、Logo 和营销图。
7. 中英文 App Store IAP 图。

通过条件：

- 所有素材索引和来源齐全。
- 不覆盖默认素材。
- 没有候选 / source refs 进入发布包。

### Phase 1F · 数值、视觉、性能和发布验收

1. 免费构筑全回归。
2. 雷霆三类 DPS 基准场。
3. `1.52x~1.58x` 综合输出。
4. Boss 展示窗口。
5. 36 个角色 / 武器组合。
6. 91 路现有视觉矩阵加 premium 路由。
7. 标准屏 / 长屏。
8. 高 / 中 / 低 / 减少特效。
9. IPA / PCK / 内存 / 帧率。
10. Sandbox / TestFlight。

---

## 13. 新增自动化

计划新增：

- `tools/check_theme_coverage.py`
  - 检查所有主题必需资源。
  - 检查 4×9 组合可解析。
  - 检查默认 fallback。

- `tools/check_store_catalog.py`
  - 商品 ID 唯一。
  - entitlement 映射正确。
  - 完整包和升级包关系正确。
  - 运行时不写死价格。

- `tools/check_premium_entitlements.py`
  - 四种拥有状态。
  - 退款和恢复。
  - 存档迁移。

- `tools/audit_thunder_premium_dps.py`
  - 单 Boss。
  - 密集尸群。
  - 混合精英。
  - 免费 / 终焉双基线。

- 视觉路由：
  - 霓虹菜单。
  - 霓虹地图。
  - 霓虹配装。
  - 霓虹收藏。
  - 霓虹战斗。
  - 雷霆 Lv1。
  - 雷霆满级。
  - 雷柱。
  - 商店三种拥有状态。

---

## 14. 包体和性能预算

当前：

- Build 38 IPA：约 `603.8 MiB`。
- 全 VFX sequences：约 `192 MiB`。
- 合成角色 / 武器动画：约 `184 MiB`。

第一阶段目标：

- 霓虹主题运行时新增不超过约 `30 MiB`。
- 雷霆军械新增不超过约 `60 MiB`。
- 总新增目标不超过约 `90 MiB`。
- 不复制 992 张合成组合帧。
- 不复制 14 张完整战场大背景。
- 不把联系表、原图、提示词、视频、失败候选和尾帧带入 PCK。

性能策略：

- 连锁使用空间半径和目标去重。
- 每次连锁结算有内部性能预算，但玩家体验不显示生硬的“最多 N 个”文案。
- 雷柱外围粒子按画质降级，主柱和命中点保留。
- 大量敌人时合并次级电弧。
- VFX、弹体和伤害数字继续走对象池。

---

## 15. 当前风险排序

### P0

1. 主题动画若继续使用完整组合帧，包体不可接受。
2. 基地已烘焙进战场背景，必须证明底部覆盖层成立。
3. StoreKit iOS plugin 尚不存在，需要先做技术 spike。
4. 当前只有中文，商品和装备双语链路未完成。
5. 付费装备不能进入星星购买 API，必须分离权益。

### P1

1. 95 处 UI 路径需要统一解析或代表场景覆盖，避免主题漏网。
2. ThemeManager 切换时 UiKit 缓存可能残留默认纹理。
3. 雷电连锁、主动技、宠物和套装之间可能产生重复结算。
4. 付费 VFX 可能遮挡锁定、血条和弱点提示。
5. 新设备恢复购买只能恢复拥有权，装备等级仍依赖本地存档备份。

### P2

1. Alternate App Icon 是否首发。
2. 主题部件混搭是否后续开放。
3. 是否提供四套合集。
4. 其余三套具体生产顺序。

---

## 16. 当前不需要 Owner 决定的事项

以下已按现有决策直接确定：

- 第一套是霓虹雷暴 + 终焉·雷霆。
- 主题 `US$1.99`。
- 完整军械 `US$6.99`。
- 主题拥有者升级约 `US$4.99`。
- 装备从 1 级开始。
- 使用普通金币升级。
- 满级总输出中心 `1.55x`。
- 第一阶段不覆盖默认素材。
- 第一阶段先做视觉和模块化证明。

下一次需要 Owner 选择的内容只应是：

- 三版天罚电弧炮中选一版。
- 四角色霓虹服装方向是否通过。
- 基地 / UI / Logo 是否达到付费主题质感。
- 雷霆六段攻击分镜是否足够拉风且可读。

---

## 17. Phase 1A-1 首批视觉候选（2026-07-27）

仓库位置：

`assets/production/source_refs/generated/premium_neon_tempest_phase1a_2026_07_27/`

已生成：

1. `neon_tempest_hero_outfit_contact_sheet_v1.png`
   - 四名角色完整全身服装方向。
   - 保留钢铁先锋、火焰少年、冰霜少女、电弧少女的体型和性格差异。
2. `heavenfall_arc_cannon_silhouette_candidates_v1.png`
   - 左：长身双环冠轨炮。
   - 中：三线圈重型旋转雷暴炮。
   - 右：悬浮电容教堂式无托炮。
3. `thunder_apocalypse_vfx_storyboard_v1.png`
   - 蓄能、主射、连锁、过载标记、风暴球体、满级雷柱六段。
   - 所有攻击方向固定为基地向上，源头和目标连通。
4. `neon_tempest_ui_world_style_board_v1.png`
   - 菜单 / Logo 氛围、收藏卡、战斗 HUD / 基地、结算面板四个代表触点。
5. `neon_tempest_battle_composite_v1.png`
   - 电弧少女、天罚电弧炮中案、风暴球体、基地和 HUD 的一体化战场验证。
   - 第一稿出现 7 只僵尸且电弧过强，已拒绝并重做；最终稿为 6 只，主目标最亮，次级连锁减细减亮。
6. `neon_tempest_phase1a_prompt_log.md`
   - 完整提示词、输入参考、首轮拒绝原因、修正版约束和当前未完成项。

第一轮视觉自检：

- [x] 四角色头部、四肢和脚部均未裁切。
- [x] 四角色服装不是同一套衣服换颜色。
- [x] 三版武器不是现有特斯拉线圈换色。
- [x] 六段特效均可识别来源、目标和方向。
- [x] 综合战斗图为一名角色、六只僵尸，锁定目标和主电弧层级清楚。
- [x] UI 样板没有生成文字或乱码。
- [x] 主题色保持石墨黑 / 青白 / 紫，洋红只作点缀。
- [x] Owner 以继续执行确认中案三线圈重型旋转雷暴炮；Phase 1A-2 已将枪身缩短约 20%。
- [x] Owner 确认四角色、UI / 基地和特效整体渲染方向满意。
- [ ] 运行时尺寸、透明切图、模块化握枪和四环境基地叠层尚未制作。

这些文件仅位于 `source_refs/generated`，没有覆盖任何免费角色、武器、UI、背景或 VFX，也不会进入当前 Build 38 的运行时包。

---

## 18. Phase 1A-2 运行时尺度和模块化证明（2026-07-27）

仓库位置：

`assets/production/source_refs/generated/premium_neon_tempest_phase1a2_2026_07_27/`

已交付：

1. `thunder_apocalypse_locked_equipment_set_v1.png`
   - 中案三线圈天罚电弧炮缩短约 20%。
   - 雷暴导体甲、超导风暴核心、风暴球体完成同套方向。
2. `neon_tempest_free_weapon_coatings_v2.png`
   - 自动机枪、手持特斯拉线圈、火焰喷射器三把免费武器涂装。
   - 第一稿把特斯拉误画为独立装置，已拒绝；第二稿改用运行时手持帧作参考。
3. `neon_tempest_modular_mounting_proof_v1.png`
   - 电弧少女 + 天罚电弧炮。
   - 钢铁先锋 + 自动机枪。
   - 火焰少年 + 火焰喷射器。
   - 冰霜少女 + 磁轨炮。
4. `neon_tempest_base_overlay_four_environment_v1.png`
   - 熔岩、冰川、雷暴、终局四环境共用同一基地语言。
5. `neon_tempest_phone_scale_proof_v2.png`
   - 四个窄屏 9:16 战场按约 14%~17% 角色高度验证手机阅读。
   - 第一稿漏掉冰川完整基地，已拒绝；第二稿只修冰川面板并通过。
6. `neon_tempest_phase1a2_prompt_log.md`
   - 完整提示词、输入路径、首稿拒绝原因、修正约束和验收状态。

验收结果：

- [x] 终焉武器保留三线圈识别点，明显高于免费特斯拉线圈。
- [x] 护甲、芯片、宠物均有独立功能轮廓。
- [x] 三把免费枪保持弹道 / 雷电 / 火焰三种功能差异。
- [x] 四角色头顶、脚部、枪托和枪口均完整。
- [x] 四组握枪均有两手接触，枪口向上偏右且无遮挡。
- [x] 四环境保留原色温，没有全部染紫。
- [x] 基地覆盖层高度稳定，未占用中央战斗通道。
- [x] 手机尺度角色和枪械仍可辨认。
- [x] 所有入选图无文字、数字或乱码。
- [ ] 这些仍是合成证明，不是透明运行时切图；确定性 socket / 遮挡 / recoil 需要 Phase 1B 在 Godot 内实现。

Phase 1A 视觉和合成证明通过后仍保持：

- 不创建 App Store Connect 正式商品。
- 不修改现有免费装备数值。
- 不覆盖默认角色、武器、UI 或 VFX。
- 不开始其余三个系列。

---

## 19. 下一工作包

下一工作包固定为：

**Phase 1B-2 · 霓虹主题完整运行时外观**

Phase 1B-1 已经完成 ThemeManager、Save v2、安全回退、精确尺寸按钮和衣装动态虹彩。下一包继续补齐视觉主题，但仍不接真实购买：

1. 把菜单、地图、收藏、配装、设置、战斗和结算的面板、标题框、资源条、选中态和 HUD 框统一成霓虹雷暴语言。
2. 制作独立基地覆盖层并在熔岩、冰川、雷暴和终局四类环境验证，不复制 14 张全尺寸背景。
3. 接入免费武器的霓虹涂装、角色模块化挂载、枪口 socket 和必要的前臂遮挡层。
4. 保持所有短 / 长控件使用对应原生模型；禁止复用纹理后非等比拉伸。
5. 保持默认主题完全不变；霓虹仍通过开发 fixture 开启。
6. 复跑标准屏 / 长屏、完整 91 路视觉矩阵、包体和性能门禁。

Phase 1B-2 明确不做：

- 不接 App Store Connect 正式商品。
- 不实现真实 StoreKit 购买。
- 不新增终焉数值或改变免费构筑。
