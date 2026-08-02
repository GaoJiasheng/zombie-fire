# 26 · 极地极光 / 终焉·绝对零度 Phase 3 实施清单

> 状态：2026-08-01 已完成源码、本地演示购买、战斗机制、双语和自动化回归。
> 上位约束：`design/21_premium_themes_and_apocalypse_arsenal_plan.md`。
> 复用基线：`design/22_neon_tempest_thunder_phase1_inventory.md`、`design/25_infernal_dominion_inferno_phase2_inventory.md`。
> 商业边界：本阶段不连接 Apple、不扣款、不伪造 verified entitlement；正式 IAP 仍须 StoreKit 2、Sandbox、退款撤权和 App Store Connect 元数据。

## 0. 冻结身份

| 类型 | 中文 | 英文 | ID |
|---|---|---|---|
| 主题 | 极地极光 | Polar Aurora | `polar_aurora` |
| 主题权益 | 极地极光主题权益 | Polar Aurora Theme Entitlement | `ent_theme_polar_aurora` |
| 套装 | 终焉·绝对零度军械 | Absolute Zero Apocalypse | `set_apocalypse_absolute_zero` |
| 军械权益 | 绝对零度军械权益 | Absolute Zero Arsenal Entitlement | `ent_arsenal_absolute_zero` |
| 武器 | 绝对零度炮 | Absolute Zero Cannon | `weapon_apocalypse_absolute_zero` |
| 护甲 | 永冻晶壁 | Permafrost Aegis | `armor_apocalypse_permafrost` |
| 芯片 | 熵减核心 | Entropy Reduction Core | `chip_apocalypse_entropy` |
| 宠物 | 极光冰灵 | Aurora Wisp | `pet_apocalypse_aurora` |

三个本地演示商品：

| 商品 | 参考价 | 授予 | Product ID |
|---|---:|---|---|
| 主题 | `US$1.99` | 主题 | `com.gaojiasheng.zombiefire.theme.polar_aurora` |
| 完整军械 | `US$6.99` | 主题 + 军械 | `com.gaojiasheng.zombiefire.arsenal.absolute_zero_complete` |
| 主题拥有者升级 | `US$4.99` | 军械 | `com.gaojiasheng.zombiefire.arsenal.absolute_zero_upgrade` |

## 1. 视觉锁

- 主色：磨砂银白、冰蓝、深海蓝、极光紫；少量白色高能核心。
- 材质：低温陶瓷、透明冰晶、拉丝银、极光折射层。
- 四角色身份必须保留：钢铁先锋体型、火焰少年年龄、冰霜少女成熟冷峻、电弧少女轻快高速；不得统一成四名同款重甲。
- 战斗相机固定从背后看角色。角色头、脚、枪口不得裁切；枪托抵肩、后手握扳机、前手托护木。
- 开火招牌是**人物背后**的对称极光冰翼，角色处在中央负空间；不得挡住身体、枪械、血条和经验条。
- UI 长短按钮使用独立原生尺寸渲染，不拉伸；极光亮度服务于文字，不压过文字。
- 免费武器只换极地涂装；终焉武器保留自身模型身份，不能被主题免费涂装覆盖。

## 2. 生产素材

源母版与提示词：

`assets/production/source_refs/generated/premium_polar_aurora_absolute_zero_phase3_2026_08_01/`

运行时：

- `assets/production/sprites/themes/polar_aurora/`
  - 4 张无框立绘。
  - 44 张角色战斗帧。
  - 72 张原生尺寸主 / 次按钮。
  - 8 把免费武器 × icon / handheld / turret。
  - 4 帧背挂极光冰翼。
  - 主题英文标题。
- `assets/production/sprites/premium/polar_aurora/`
  - 武器 icon / handheld / turret。
  - 护甲、芯片、宠物 icon 与宠物战斗原型。
  - 四角色 × 左 / 中 / 右共 12 张 380×520 后视真实握持母版。
- `assets/production/sprites/vfx_sequences/`
  - 6 帧脆化状态。
  - 8 帧碎冰。
  - 7 帧冰晶波。
  - 8 帧极光冻原。
  - 8 帧永冻反击。
  - 8 帧满级觉醒。
- `assets/production/audio/sfx/`
  - 开火、碎冰、冻原、反击、觉醒 5 个独立反馈声。

确定性构建器：

- `tools/build_polar_runtime_assets.py`：168 个主题 / 装备运行时文件。
- `tools/build_absolute_zero_vfx_assets.py`：52 帧 VFX + 5 个 SFX，共 57 个追踪输出。

## 3. 战斗机制

### 3.1 绝对零度炮

- 普通命中施加寒冷并积累独立的“脆化”层数。
- 满配普通敌人 4 次命中触发碎冰；Boss 为 5 次，Boss 不被硬冻结。
- 碎冰在真实命中点释放，按距离衰减，最多 5 个目标。
- 碎冰事件有目标独立冷却，避免高射速 / 多弹道同帧重复爆炸。
- 所有初级子弹仍不自带弹射或溅射；特殊范围效果只来自已拥有的终焉武器与套装机制。

### 3.2 永冻晶壁

- 提高基地生命并保留冰抗 / 缺口护盾。
- 基地累计 3 次有效受击并满足 9 秒冷却时向上释放永冻反击。
- 反击对近防线敌人造成衰减冰伤、减速并恢复少量基地生命。
- 护甲伤害与恢复均计入套装预算，不靠提高敌方攻击制造价值。

### 3.3 熵减核心与极光冰灵

- 芯片分别提高冰伤、减速强度、脆化效率和碎冰倍率。
- 极光冰灵按现有目标管理器选择最危险目标；手动锁定仍优先。
- 周期性极光冻原为有限半径的一次性区域技能，不生成永久地面节点。

### 3.4 套装协同

- 2 件：脆化积累更快，碎冰更强。
- 4 件：一次碎冰向最密集区域释放一代冰晶波。
- 冰晶波使用独立 5.5 秒冷却、最多 5 目标、逐目标衰减。
- `generation_limit = 1`；冰晶波伤害源不会再次触发碎冰或新冰晶波。

## 4. 满级强度

`tools/audit_absolute_zero_premium_dps.py` 使用与四角色终局审计相同的满级永久属性、主动技、散射、多弹道、穿透和射速公式，并额外计入碎冰、宠物冻原、护甲反击与冰晶波。

相对冰属性最强免费满配：

- Boss：`1.342x`。
- 密集尸群：`1.752x`。
- 60% Boss / 40% 尸群混合：`1.550x`。
- 40 / 40 / 20 加权：`1.547x`，位于锁定 `1.52x–1.58x` 带宽。

定位是“控制和尸群碎裂”，因此 Boss 倍率低于尸群倍率；免费战役难度不按付费强度反向提高。

## 5. 本地购买与换装

- 新存档显示主题和完整包。
- 买主题后，该系列隐藏完整包并显示升级包。
- 完整包授予主题 + 军械，解锁四件装备，从 1 级用普通金币升级。
- 购买完成可“立即应用整套”或进入四角色逐人换装。
- 全局主题在设置 / 主题与外观切换；角色单独覆盖在收藏详情和配装页切换。
- 三主题可混搭到不同角色；主题权益撤销只清理对应外观，不影响仍拥有的其他主题。
- 单系列清空只撤销该系列；全局清空安全回到默认主题和免费装备，保留休眠等级。

## 6. 永久验收矩阵

- ThemeManager：三种付费主题、4 角色动作、72 按钮、8 免费武器涂装、shader、背后开火翼、撤权回退。
- M1 smoke：三系列目录顺序、购买 / 升级 / 完整包、全套装备、混搭、恢复、单系列撤销和总撤销。
- True grip：4 角色 × 3 终焉武器 × 左 / 中 / 右，完整头脚枪口、无浮枪图层。
- 主题预览：菜单、设置、收藏、4 配装、4×8 免费武器开火、4 主动技。
- 交叉矩阵：3 主题 × 3 终焉武器 × 4 角色，共 36 路真实战斗截图。
- 绝对零度专项：中英文商店 / 确认 / 完成；脆化、中央 / 边缘 / Boss 碎冰、冰晶波、冻原、反击、觉醒。
- 方向语义：冰晶波按真实源到目标向量旋转；反击由基地向上；极光冰翼在人物背后。
- 减弱特效：保留状态、方向、命中和危险半径，只减少外围粒子与光晕。

## 7. 完成与剩余边界

- [x] 视觉母版、运行时、后视真实握持、极光冰翼。
- [x] 数据、机制、套装协同、SFX、双语。
- [x] 本地演示购买、恢复、系列撤权、装备、换装。
- [x] 满级输出审计与三主题交叉回归。
- [x] 资产 provenance、manifest 和重建工具。
- [ ] Owner 真机观感、持续 FPS、温升和扬声器 / 耳机实听。
- [ ] Apple StoreKit 2、已验证交易、pending / cancel / failure、退款撤权、Sandbox、TestFlight 实购和 App Store Connect 商品元数据。
