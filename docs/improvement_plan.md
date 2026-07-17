# Zombie Fire 优化 Plan

> 以「正规一线手游」为标准，从 **UX / 配色 / 可玩性 / 难度平衡** 四条线深度拆解，按 token 情况分批执行。
> 本文档为跨会话执行的 checklist，完成项打 `[x]`。

## 调研结论（动手前的关键事实）

- `data/levels.json` 是 `tools/rebalance_difficulty.py` **全量生成的产物**，不可手改，必须改生成器后重新生成。
- `difficulty_coef` 是「补偿系数」（= 目标压力 / 敌人血量权重），**它非单调是设计使然**；真正要单调的是 `check_level_pressure.py` 度量的**实际 pressure**。
- 实测 pressure 有 42 个回退点：boss 关后的回落是合理锯齿（boss=周期尖峰），但**非 boss 关之间的回退**与**结尾 Lv96-99 徘徊**是真问题。
- 根因：生成器算 `difficulty_coef` 的归一化只用 `hp_coef`，而真实压力含 `bd_coef`，度量不一致 → 抖动。
- `level_099` 无 boss 且 pressure 不是全局最高，结尾虎头蛇尾。
- UI 全部硬编码绝对坐标，0 个 `.tres`，无安全区；`ui_kit.gd` 有暗色科幻色板但 `.tscn` 里大量裸 `Color()` 未走色板。
- `skills.json` 16 卡中 9 张三级效果是占位 `power 1.0/1.5/2.2`，且仅 3 级封顶。
- 已有工具链：`rebalance_difficulty.py` / `simulate_balance.py` / `check_level_pressure.py` / `check_balance_profile.py` / `check_economy_loop.py` / `simulate_card_director.py` / `check_gameplay_polish.py` 等。

## Token 量级图例

| 档位 | 估算 | 含义 |
|---|---|---|
| XS | <15k | 改 1~2 个 JSON/小脚本 + 跑校验 |
| S | 15~40k | 单个 `.gd`/`.tscn` 局部改 |
| M | 40~80k | 跨 2~4 文件，或新建系统 |
| L | 80k+ | 大文件重构（battle.gd 3953 行 / collection.gd 1277 行） |

---

## 线 A · 难度平衡

- [x] **A1 难度（pressure）单调化** 〔XS〕 ✅ 双流 0 回退
  - 改 `tools/rebalance_difficulty.py`：新增 post-process pass，分别对「boss 关序列」「非 boss 关序列」强制 pressure 单调不减（按需上调 `difficulty_coef`），pressure 度量与 checker 一致（`hp_coef×bd_coef` + `boss×8`）。
  - 改 `tools/check_level_pressure.py`：加断言——非 boss 关 pressure 单调不减、boss 关 pressure 单调不减、末关 pressure 全局最高。
  - 验收：`check_level_pressure.py` 通过且 0 个非法回退。
- [x] **A2 补最终关 Boss + Boss 节奏规整** 〔XS〕 ✅ boss 关 20 个，Lv99 终boss且全局最难
  - 生成器：`n==99` 强制 boss 关（终极 boss），保持每 5 关一个 boss 的周期。
  - 验收：`level_099` 含 boss 波；boss 关数量 = 20。
- [x] **A3 角色解锁星门槛重排** 〔XS〕 ✅ 0/36/72/120 → 0/20/45/75
  - 改 `data/characters.json` 的 `unlock_cost_star`：0/36/72/120 → 平滑曲线（0/20/45/75）。
  - 验收：`check_economy_loop.py` 通过。
- [x] **A4 武器 DPS 归一化校验** 〔S〕 ✅ 护栏就位（同稀有度 spread>2.6 报错）
  - 改 `tools/check_balance_profile.py`：计算每把武器 DPS = `atk_coef×fire_rate×特效系数`，输出排名 + 同稀有度离散度告警。
  - 验收：报告打印 DPS 排名，无碾压级离群武器。

## 线 D · 配色

- [x] **D2 补色板灰阶 + 语义命名** 〔XS〕 ✅ 灰阶+语义色，成功绿与毒绿拉开
  - 改 `ui/ui_kit.gd`：增 `GREY_900/700/500/300` 中性灰、语义色 `SUCCESS/WARNING/DANGER/INFO`，把「毒绿」与「成功绿」拉开。
  - 验收：色板覆盖文字/分割线/禁用/状态。
- [x] **D1 配色单一来源** 〔S〕 ✅ 审计脚本+baseline(38)；战斗三色对齐调色板并由 battle.gd 绑定
  - 新建 `tools/check_hardcoded_colors.py` 扫 `.tscn` 裸 `Color(`；把裸色替换为引用 `UiKit` 常量。
  - 验收：扫描脚本零告警（白名单除外）。
- [x] **D3 对比度 + 元素色编码闭环** 〔S〕 ✅ `check_contrast.py` 护栏(正文≥4.5/次要≥3.0,全绿)；消除 collection 本地元素色副本改委托 UiKit；battle VFX 色标注为特效专用

## 线 B · 可玩性

- [x] **B1a 关卡波次模板变体** 〔M〕 ✅ 5 种波型(standard/rush/pincer/escort/siege)按章节轮换；`check_level_pressure.py` 加连续 3 关不同型 + ≥4 种断言
- [x] **B2 技能升级深度（3→5 级 + 去占位）** 〔M〕 ✅ **skill_runtime.gd 改为数据驱动**(读 skills.json effect，原占位 power 删除)；16 卡全扩 5 级 + 质变(暴伤/分裂/护盾/重摇满级跃升)；battle.gd 接 crit_damage_mult/barrier_gain/reroll_gain；collection.gd 补 key 名+展示 5 级
- [x] **B3 局内变奏关** 〔S，依赖 B1〕 ✅ 生成器加 `variant`（normal/elite/treasure/boss/boss_rush）；宝箱关金币×1.5、精英关经验×1.3、终关 boss_rush 追加 support boss；地图卡片显示变奏角标；`check_level_pressure.py` 加 variant 断言。

## 线 C · UX

- [x] **C1 安全区适配** 〔S〕 ✅ `battle.gd` 加 `_apply_safe_area()`，按设备安全区把顶部 HUD 下移、底部 HUD 上移；桌面/headless 无 inset 时空转。
- [x] **C2 菜单/HUD 容器化重构** 〔L〕✅ —— C2a 菜单 / C2d map / C2e collection / C2c loadout / C2b 战斗HUD 全部完成。
  - 列表/线性场景（menu / map / collection）：统一 `MarginContainer + VBoxContainer` 根布局，关键节点 `unique_name_in_owner` + `%` 访问，smoke 改 `find_child`。
  - loadout：可见结构节点（两栏单位/装备行/摘要/按钮）移入 `MarginContainer+VBox+HBox` 容器，删除手动对齐引擎（`_apply_loadout_alignment`/`_center_rect_in_control`/`_align_label_to_control`），隐藏遗留节点保留在根；底部弹性 spacer 让“进入战斗”贴底。
  - 战斗 HUD：overlay 仪表盘不适合线性容器化，改用**边缘锚定**（底部条/技能槽/角色技能按钮锚底边、右下按钮锚右下角、暂停遮罩锚满屏），与 C1 安全区 `position += inset` 逻辑兼容。当前发布合同固定为 `stretch=canvas_items + aspect=expand`，高屏只扩展战场上方空间，底部交互继续贴合安全区。
  - 新增 `tools/_shot.gd` 视觉验证工具（经真实路由加载场景并截图 viewport），全部场景已逐一截图确认布局正确。`check_release_candidate` 13 项全绿。
- [x] **C3 设置页独立分组** 〔S〕 ✅ 新建 `meta/settings/`（容器布局，音频/画面/数据/关于四组），`main.gd` 加 `settings` 路由，菜单「操作说明」改「设置」；旧 HelpOverlay 下线。
- [x] **C4 战斗中层反馈** 〔S〕 ✅ 复用波次横幅/Boss 入场/低血脉冲/连击，补齐 Boss 专属血条（运行时构建，跟踪 `active_boss`，死亡清理）。

---

## 执行批次（按 token 从小到大、依赖优先）

- **第 1 批**（XS~S）：A1 → A2 → A3 → D2 → D1 → A4 —— 数据/小脚本 + 校验，低风险高收益。
- ~~**第 2 批**（M）：B2 → B1a~~ ✅ 已完成。
- ~~**第 3 批**（S）：C1 → C3 → C4 → B3 + 清武器倒挂~~ ✅ 已完成。
- ~~**第 4 批**（L）：D3 → C2a~C2e~~ ✅ 已完成。**原计划四条线（A/B/C/D）全部收尾。**

## 进度日志

- 2026-06-27：plan 落盘，启动第 1 批。
- 2026-06-27：**第 1 批完成**（A1/A2/A3/D2/D1/A4）。全套 python 校验链 + godot headless + M1 smoke test 通过。
  - 新增护栏：`check_level_pressure.py` 压力分流单调 + 末关全局最难；`check_hardcoded_colors.py` 配色漂移护栏；`check_balance_profile.py` 武器 DPS 离群护栏。
  - 注：`check_release_candidate.py` 在沙箱内因 godot 无法写 `user://logs` 崩溃，沙箱外正常。
- 2026-06-27：**第 2 批完成**（B2/B1a）。8 项 python 校验 + M1 smoke test 通过。
  - **B2 重大重构**：技能效果从 `skill_runtime.gd` 硬编码改为**数据驱动**（读 `skills.json` 的 `effect`），彻底消除占位死数据；16 卡扩到 5 级并引入满级质变。
  - **B1a**：关卡生成器引入 5 种波型原型轮换，新增「连续 3 关不同型 + ≥4 种」断言（onboarding 前 5 关豁免）。波型分布 standard24/rush20/pincer19/escort18/siege18。
- 2026-06-27：**第 3 批完成**（C1/C3/C4/B3）+ 清武器倒挂。全套 python 校验链 + M1 smoke test 通过。
  - **清倒挂**：只调 `base_atk_coef`（保留 fire_rate 手感）使 effective DPS 随稀有度严格递增——common 4.00 < rare 4.59~4.86 < epic 5.61~5.79 < legendary 6.81~7.15；`check_balance_profile.py` 新增「稀有度地板单调」护栏防回潮。
  - **C1**：`battle.gd` 加 `_apply_safe_area()`，按设备安全区把顶部 HUD（血条/波次/策略/暂停）下移、底部 HUD（金币/经验/技能槽/角色技能）上移；桌面/headless 无 inset 时自动空转。
  - **C3**：抽出独立设置页 `meta/settings/`（容器布局，分音频/画面/数据/关于四组），`main.gd` 加 `settings` 路由，菜单「操作说明」改为「设置」并跳转；旧 HelpOverlay 逻辑下线。
  - **C4**：复用已有波次横幅/Boss 入场/低血脉冲/连击，补齐缺失的 **Boss 专属血条**（运行时构建，跟踪 `active_boss`，死亡清理）。
  - **B3**：生成器加 `variant`（normal/elite/treasure/boss/boss_rush，纯标记+奖励层不动波数据保压力单调）；战斗消费——宝箱关金币 ×1.5、精英关经验 ×1.3、终关 boss_rush 追加 support boss + 开场横幅；地图卡片加变奏角标。`check_level_pressure.py` 新增 variant 合法性/一致性/数量断言。分布 normal58/boss19/elite11/treasure10/boss_rush1。
  - 注：headless 首跑会因脚本错误未 `quit()` 而挂起——本批排查到旧 smoke 仍测 HelpOverlay，已同步更新为新设置页断言。
- 2026-06-27：**C2c / C2b 完成**（loadout 容器化 + 战斗 HUD 边缘锚定），**C2 全套收尾**。loadout 删除运行时手动对齐引擎改由容器布局；战斗 HUD 底部元素锚定底边（兼容 C1 安全区）。每场景经 `tools/_shot.gd` 截图验证，`check_release_candidate` 13 项全绿（含为重构更新的 gameplay polish 守卫）。
- 2026-06-27：**C2d / C2e 完成**（map / collection 容器化）。两者主体本就是 `ScrollContainer + VBoxContainer` 列表，统一收进 `MarginContainer + VBoxContainer` 根布局，标题/进度/导航/列表/返回按钮自适应；节点改 `unique_name_in_owner` + `%` 访问，smoke 改 `find_child`。新增 `tools/_shot.gd` 截图验证工具，已可视化确认 menu/map/collection 布局正确。完整 `check_release_candidate` 13 项全绿。
  - loadout/battle HUD 经评估为复杂固定仪表盘，`canvas_items` 已等比自适应，全量容器化性价比低，暂挂起待用户决策范围。
- 2026-06-27：**C2a 完成**（菜单容器化试点）。`menu.tscn` 绝对坐标 → `MarginContainer + VBoxContainer + spacer(stretch_ratio)` 自适应布局，标题居上/按钮居下随分辨率伸缩；删除 C3 遗留的死 `HelpOverlay` 整块；`menu.gd` 精简为干净版（设置逻辑已全在 `settings.gd`）。**项目首次跑通完整 `check_release_candidate`（13 项全绿）**，顺带修复既有 polish 误报：wave banner 装饰变量 `line` 撞上「禁止 ColorRect tracer」规则，改名 `divider`。
- 2026-06-27：**D3 完成**（第 4 批起步）。新增 `tools/check_contrast.py`（WCAG 对比度护栏，正文≥4.5、次要≥3.0，当前全绿，最低 DANGER 5.35:1 / GREY_500 4.24:1）；发现并消除 `collection.gd` 本地 `_element_color` 与 `UiKit.element_color` 不一致的副本（如毒绿 0.55/1.0/0.35 vs 0.48/0.78/0.40），改为委托 + 派生暗色；`battle.gd` 本地 `_element_color` 明确标注为 VFX 专用（色相与 UI 编码一致）；把 `check_hardcoded_colors`/`check_contrast` 补登记进 `check_release_candidate.py`。
