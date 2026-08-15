# 30 · 上线前走查整改方案（2026-08-15）

> 来源：2026-08-15 全量回归 + 1080×1920 真机分辨率逐屏走查（基线 `main @ 6c903db3`，
> 工作树含未提交改动）。本文只收本次走查确认为**真实缺陷**的条目，每条附实测证据与定位。
> Owner 已逐条确认，其中顶部战力位为 Owner 明确要求移除。
>
> 走查手段说明：本项目 Godot iOS 导出模板的模拟器切片为 **x86_64-only**
> （`lipo -info build/ios/ZombieFire.xcframework/ios-arm64_x86_64-simulator/libgodot.a`），
> Apple Silicon 上的 iPhone 模拟器需要 arm64，链接报 `_main` 未定义。故改用
> `tools/_shot.gd` 1080×1920 真机分辨率渲染走查（与本仓库既有 UI 验收同一手段）。
> 若后续要恢复真模拟器链路，需要重新编译带 arm64 模拟器切片的 Godot iOS 模板，属独立任务。

---

## P0-1 · 商店在未解锁时是完全空白页（主菜单直通，无门控）

**证据**：新号进入商店 → 页面只剩标题、「本地演示商店」副标题和底部三按钮，
中间**整片空白**，无任何解释。

**根因**：
- 入口无门控：`meta/menu/menu.gd` `_on_store_pressed()` 直接 `router.change_scene("store")`
- 内容全隐藏：`core/commerce/purchase_manager.gd` `_series_is_visible()` 按
  `premium_sets.json` 的 `store_unlock` 过滤；实际门槛为
  炼狱=通关 30 关、雷霆=50 关、绝对零度=80 关、黄金法则=99 关且任一角色 40 级
- 空态无渲染：`meta/store/store.gd` `_rebuild()` 中 `revealed_series` 为空时
  不产生任何子节点（连状态标签都跳过，见 `if not revealed_series.is_empty()` 分支）

**第二条同样路径**：图鉴里付费装备以「可见但锁定」展示，锁定态动作按钮
`collection.gd` `_open_premium_store()` 同样直达该空白页。

**风险**：这是每个新玩家和 App Review 审核员都会走的主路径，观感等同于「功能坏了」，
有被判定功能不完整而打回的实际风险。

**改法**（只加空态，不动门控规则、不动定价）：
1. `store.gd _rebuild()`：`revealed_series` 为空时渲染一张空态卡片，说明
   **精品军械库尚未解密** + 最近一档解锁条件（从 `premium_sets.json` 的
   `store_unlock` 动态取**最小** `clear_level` 的那一档，禁止硬编码 30/50/80/99）
2. 同时列出后续档位（可折叠或一行摘要），让玩家知道后面还有内容
3. 「恢复购买」按钮保留可用（已购用户换设备后必须能恢复）
4. 中英文案同时入库

**验收**：
- 空存档进商店：看到解锁条件文案，无空白页；截图中英各一张
- 通关 30 关的存档进商店：炼狱系列正常出现，空态文案消失
- 已购存档（含 `is_theme_owned`/`is_arsenal_owned`）：即使进度回滚也仍可见可恢复
  （`_series_is_visible` 现有的 owned 短路逻辑不许动）
- `python3 tools/check_localization.py` 绿

---

## P0-2 + P1-1 · 顶部「战力」资源位移除（Owner 决策）＋ 本地化门禁转绿

> **Owner 决策**：「有效战力」这个概念放在关卡里没问题、算法认可；但**顶部那个「战力」没用，取消**。

**现状**：`ui/ui_kit.gd standard_resource_bar(gold, star, xp, power, …)` 渲染四格
（金币/星星/经验/有效战力），被三处共用：
`meta/map/map.gd:103`、`meta/loadout/loadout.gd:270`、`meta/collection/collection.gd:196`。

**为什么该删**（走查实证，非主观）：
- 它被摆成第 4 种货币（与金币/星星/经验并排、无标签、只有一个数字），读起来像新货币
- 其 tooltip 写「针对**所选关卡**的预计通关能力」，但地图/图鉴根本没有选中关卡；
  代码实际用 `get_highest_unlocked_level_id()`（`map.gd _refresh_header()`），**文案与行为不符**
- 配装页的「战术摘要」已经有「有效战力 13 / 推荐 11」并且带关卡上下文，顶部那格纯属重复

**顺带解决本次 RC 红灯**。当前 `check_localization` 失败（阻断其后所有检查），两条串：
1. `ui/ui_kit.gd` 资源条第 4 格的 tip「有效战力：当前阵容针对所选关卡的预计通关能力」
   —— 真实漏译（同一资源条另外三条 tip 都有英文）。**随该格删除而消失**
2. `meta/map/map.gd` `_resource_chip_name()` 中的 `"有效战力", "战力"` 分支
   —— **死代码**：其唯一调用方 `_make_resource_chip()`（`map.gd:153`）在地图改用
   `UiKit.standard_resource_bar` 后已无任何调用点。**直接删除整个死代码块**，
   不要加检查器豁免（豁免会把死代码永久留在仓库里）

**改法**：
1. `ui_kit.gd`：`standard_resource_bar` 去掉 `power` 参数与第 4 格（保留金币/星星/经验三格）
2. 三处调用点同步去掉传参：`map.gd:103`、`loadout.gd:270`、`collection.gd:196`
3. `map.gd`：删除死代码 `_make_resource_chip()` 与 `_resource_chip_name()`；
   若删后 `_resource_chip_style()` / `_resource_tip_style()` 也失去调用方则一并删
   （注意 `_resource_tip_style` 在 `map.gd:141` 与 `:211` 仍被引用，**不要误删**）
4. `tools/m1_smoke_test.gd:5078` 的 `standard_resource_bar(31612, 37, 12172, 38, …)`
   同步去掉第 4 个实参
5. 配装页「战术摘要」里的「有效战力 / 推荐」**保持不动**——Owner 认可这里的口径与算法

**验收**：
- 地图 / 配装 / 图鉴三页顶部均为三格，中英各截一张图核对间距与居中未塌
- `_assert_resource_chip_geometry` 是逐 chip 断言（不依赖数量），应自然通过；
  若有隐藏的数量假设需一并修正
- `python3 tools/check_localization.py` **转绿**
- `python3 tools/check_release_candidate.py` 非视觉部分全绿
  （`check_visual_screens.py` 因缺 `ZOMBIE_FIRE_ALLOW_WINDOW_CAPTURE=1` 报退出码 125 属已知授权保护，非回归）

---

## P1-2 · 图鉴卡片信息重复与零值噪声

**证据**（武器图鉴实截）：每张卡的元素与特殊属性各渲染两遍——
标签行 `[物理] [扩散 0]`，正文又写「元素：物理 射速：4.0」+「扩散 0」。

**定位**：
- 标签：`collection.gd` `_item_tag_specs(row, true)` → `UiKit.semantic_tag_pill`（约 `:1228`）
- 正文：`collection.gd` `_item_stat_summary()` 的 `"weapons"` 分支（约 `:709`／`:734`），
  返回「元素：%s 射速：%s\n%s」，其中 %s 元素与特殊文本与标签完全重复

**附带问题**：
- `扩散 0`：数值为 0 的属性仍占一个高亮 pill，是纯噪声
- 单位缺失：`扩散 10` / `毒云 120` / `自带连锁 +2` 三种量纲混排且无任何解释

**改法**：
1. 标签行保留为「一眼识别」层（元素 + 特殊机制），正文只保留标签里**没有**的数值（射速等），
   消除重复；具体保留哪层由实现者按截图观感定，但同一信息不得出现两次
2. `_item_tag_specs`：数值为 0 / 空的属性不生成 pill
3. 给这三类特殊属性补可读单位或后缀（如「扩散 10°」「毒云 120 范围」「连锁 +2 目标」），
   以数据实际含义为准，需先确认字段语义再定文案，**不许臆造单位**
4. 中英文案同步

**验收**：武器/护甲/芯片/宠物四类图鉴中英各截一张；同一属性不重复出现；
无零值 pill；`check_localization` 绿

---

## P2 · 雷霆套合同带余量仅 0.001（风险登记，暂不改数值）

`tools/audit_character_endgame_dps.py` 实测：Thunder Apocalypse 完整套 = **1.579x** 免费 Volt，
合同带锁定 `[1.52, 1.58]`——距上限仅 **0.001**。

当前合规，但任何后续付费数值微调都会破带。**本轮不改数值**，仅登记：
后续若要调雷霆套任何一件，必须先复跑该审计并确认仍在带内；
若 Owner 认为该带过窄，可另行决策放宽到 `[1.52, 1.60]`（属数值决策，不在本方案范围）。

---

## 走查通过项（本次确认无需改动，供回归对照）

| 维度 | 实测 |
|---|---|
| 难度平衡与战力 | 星级 13×3★/86×2★/0×1★ **未变**；Apex L99 counter-TTK **116.6s 未变**；平均通关 92.2s；角色单体 DPS 离散 1.143x |
| 技能特效 | 101 序列 / 850 有效帧；状态特效 5 独立态 54 帧；16 组卡牌施法；8 个 Boss 攻击档案 —— 全过 |
| 模型完整性 | 8 个僵尸家族 264 帧；1092 个战斗精灵；144 组攻击动画（最弱相邻位移 4040px）—— 全过 |
| 购买体验（解锁后） | 系列分组清晰、$1.99 主题 / $6.99 完整包分层合理、消费者披露完整；design/25 的「主宰区间」预期管理文案已落地 |
| 可玩性 | 第 1 关 有效战力 13 / 通关线 11 →「可通关」；早期经济 3297 金币 vs 首次升级 879，闭环正常 |
| Godot 侧测试 | `_battle_boot_probe` / `save_integrity_test` / `localization_smoke_test` / `theme_manager_test` / `m1_smoke_test` **全过** |

---

## 红线

- 不动真实难度引擎（`battle.gd` 伤害/敌方 HP/波次、`economy.json` 压力曲线、星级阈值）
- 不动战力算法本身与配装页「有效战力 / 推荐」口径（Owner 已认可）
- 不动商店门控规则与定价，只补空态表达
- 所有解锁条件从 `premium_sets.json` 动态读取，禁止硬编码关卡号
- 每个改动的中英文案同时入库，`check_localization` 必须绿
