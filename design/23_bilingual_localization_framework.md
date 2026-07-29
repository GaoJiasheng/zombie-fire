# 中英双语运行时与英文文案规范

> 状态：已实现。支持 `简体中文 / English`，覆盖菜单、地图、章节、配装、收藏、设置、战斗 HUD、暂停、三选一、详情弹层与结算。本文是后续新增内容和 App Store 本地化的接手入口。

## 1. 用户侧行为

- 设置页提供即时语言切换；切换后重建当前设置页，后续路由全部使用新语言。
- 全新安装按系统语言选择：`zh*` 使用简体中文，其余语言暂回退 English。
- 老存档没有 `language` 字段时迁移为简体中文，避免已有玩家升级后界面突然变为英文。
- 语言写入本机设置，不需要账号或网络。

## 2. 运行时结构

| 文件 | 职责 |
|---|---|
| `core/localization/localization_manager.gd` | 加载英文目录、切换 locale、发出 `language_changed` |
| `core/localization/dynamic_translation.gd` | 支持 Godot 精确翻译、格式化字符串模板与可复用术语 |
| `core/settings/settings_manager.gd` | 语言默认值、旧设置迁移与持久化 |
| `data/localization_zh.json` | 角色、武器、装备、僵尸、Boss、技能等稳定 ID 的中文名称 |
| `data/localization_en.json` | 与中文 ID 一一对应的英文名称 |
| `data/localization_ui_en.json` | 通用界面、动态格式模板和 `__terms` 术语表 |
| `data/localization_gameplay_en.json` | 战斗、技能说明、配装与结算文案 |
| `data/localization_story_en.json` | 十战区剧情、目标、挑战规则和 Boss 机制文案 |

中文仍是代码与数据中的源文案。Godot 在显示 `Label/Button` 时自动翻译；对已经完成 `%` 格式化的运行时字符串，`DynamicTranslation` 会按占位符模板匹配。不要在业务代码里写英文分支。

## 3. 新增文案的规则

1. 新内容名称继续使用稳定 `name_key`，同时补齐 `localization_zh.json` 与 `localization_en.json`。
2. 新增短 UI 源文案时，把完整句子放入 `localization_ui_en.json`；不要只依赖零散术语拼接。
3. 战斗数值、技能说明和结果文案放入 `localization_gameplay_en.json`。
4. 章节、目标、挑战和 Boss 叙事放入 `localization_story_en.json`。
5. 动态文案必须保持源/目标占位符数量与类型一致，例如：

   ```json
   "等级%d": "Lv.%d"
   ```

6. 英文手机文案优先传达信息，不逐字直译。按钮尽量 1–3 个词；徽章尽量不超过 14 个字符；章节摘要控制在三行、目标控制在两行。
7. `__terms` 只放可以安全复用的完整术语。容易与格式模板冲突的句子必须写完整模板。

## 4. 版式约束

- 中文与英文共用未来荧黑字体和同一视觉主题，不单独替换字体资产。
- 英文允许按控件单独降低字号或增加高度，但不得整体缩小到影响手机阅读。
- 长段落按英文单词边界换行，不能按 Unicode 字符数硬切。
- 章节、技能卡、配装摘要和结算标题必须在标准 `1080×1920` 与长屏 `1080×2340` 同时通过。
- 视觉审计同时检查单行横向溢出、显式多行高度、自动换行高度、按钮文字、触控尺寸和安全区。

## 5. 发布门禁

```bash
python3 tools/check_localization.py
godot --headless --path . --script res://tools/localization_smoke_test.gd
python3 tools/check_visual_screens.py --english-only
python3 tools/check_release_candidate.py
```

`check_localization.py` 会检查：

- 中英文稳定 ID 完全一致；
- 英文目标无中文残留；
- 格式占位符完全一致；
- 所有运行时中文源文案都有精确翻译或完整术语覆盖；
- Autoload、设置项和语言入口仍存在。

英文截图矩阵当前包含 26 个代表路由，额外覆盖购买确认、角色 / 技能详情、四角色主动技长按说明、Boss 阶段提示、严重欠战力配装，以及标准屏 / 长屏暂停和三选一。完整发布矩阵同时覆盖中文与英文代表界面。人工验收仍需要查看地图、配装、收藏、强化卡、设置和结算，因为语义拥挤不一定等同于像素裁切。

## 6. 还未包含的外部本地化

运行时双语不等于 App Store Connect 已完成本地化。正式海外上架时仍需分别提交英文 App 名称、副标题、关键词、描述、宣传文案、截图标题、支持页与隐私政策入口；未来 StoreKit 商品也要在 App Store Connect 配置中英文显示名称和说明。不得把运行时 JSON 当作商店元数据的自动发布源。
