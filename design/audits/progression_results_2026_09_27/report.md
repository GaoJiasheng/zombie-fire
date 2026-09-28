状态：已实现并完成本地回归；截图待 Owner 审阅，iPhone 真机与真实支付未验证。

# 统一升级与购买结果 · 2026-09-27

## 覆盖范围

- 人物等级、人物专属技能、永久技能、免费及付费武器/护甲/芯片/宠物。
- 收藏列表、详情、出战武器升级及商店已拥有装备入口；现有升级成功后弹出结果，不增加升级前确认。
- 普通星星购买显示初始能力；付费完整包与升级包显示全部军械实际等级及主题，单独主题购买明确不解锁人物/属性装备。
- 成功后可继续升级，显示本次消耗与下级成本；资金不足/满级不会出现假成功。购买仍由原有成功回调触发，不改商品、价格、权益或发货。

## 真实数值原则

属性前后快照读取同一次事务前后状态。人物攻击/生命使用当前战斗成长公式；武器分段成长、芯片和宠物成长、专属技能冷却/持续/波次等复用现有实际方法。只显示发生改变的项，不把静态属性重复列成收益。

- 黄金律 Lv50→51 显示伤害系数变化，不凭空增加基础射速。
- 永久技能 Lv0→1 按当前规则首次选卡仍是 Lv1，明确说明本次无额外直接战斗数值变化，不在 UI 修复中擅改养成模型。
- 冷却缩短标为收益；分裂小弹保留伤害下降使用琥珀色，不用绿色掩盖取舍。
- 付费新装备从 Lv1 开始，已有等级保留；追赶成本说明读取当前经济数据，并受各装备等级上限限制。
- 英文/中文特殊属性均有可读名称，不显示内部字段名。

## 验证

使用 `/tmp/zf-signature-after.G09iKx` 隔离测试项目及禁止持久化的测试存档；未触碰玩家正式进度。

| 检查 | 结果 |
| --- | --- |
| `python3 tools/validate_asset_pack.py` | 通过；保留检查器已登记的生成缓存例外 |
| `python3 tools/validate_data.py` | 通过 |
| `python3 tools/check_res_refs.py` | 通过，492 引用 |
| `python3 tools/check_level_pressure.py` | 通过；既有拓扑提示未改写 |
| `python3 tools/simulate_card_director.py` | 通过 |
| `python3 tools/check_localization.py` | 通过 |
| `python3 tools/check_release_strings.py` | 通过 |
| Godot headless 启动 | 通过，最终日志无 ERROR |
| `res://tools/m1_smoke_test.gd` | 通过，最终日志无 ERROR |
| `res://tools/audit_progression_results.gd` | 2121 项检查、0 失败；验证真实扣费、等级、重复升级、失败无改动、字段名称、文本和按钮边界、尾行滚动可达 |

截图矩阵为 12 场景 × 中英两语言，共 24 张（1080×2340）；另外审计 1080×1920 布局。检查覆盖 64 个收藏条目与 4 项专属技能；付费购买排版重点截取黄金律完整包、升级包和主题三个分支。

GPU 截图运行所有断言通过，但退出时仍出现 2 个 ObjectDB 实例/1 个资源未释放的清理提示（含 ERROR）；不将截图进程宣称为无 ERROR。headless 完整审计与正式冒烟独立检查。此退出清理差异作为已知测试限制保留，不隐去日志。

## 截图索引

- `characters_frost_zh_2340.png`：人物等级 20→21。
- `signature_frost_zh_2340.png`：冰川领域 2→3，包含寒潮波次变化。
- `skills_skill_split_shot_zh_2340.png`：永久分裂弹 2→3。
- `weapons_weapon_apocalypse_golden_law_zh_2340.png`：付费武器 50→51。
- `armors_armor_apocalypse_permafrost_zh_2340.png`、`chips_chip_apocalypse_golden_law_zh_2340.png`、`pets_pet_apocalypse_skyfalcon_zh_2340.png`：付费护甲、芯片、宠物。
- `new_weapon_zh_2340.png`：新武器星星购买。
- `arsenal.golden_law_complete_zh_2340.png`：完整包成功、四件军械及应用入口。
- `arsenal.golden_law_upgrade_zh_2340.png`、`theme.gilded_eclipse_zh_2340.png`：升级包与纯主题分支。
- 对应 `_en_2340.png` 为英文实拍，另有散弹枪升级截图。

## 交付边界

本轮未提交、未 push、未打包或上传 TestFlight；未跑完整 99 关扫测。屏幕图片是 Godot 实际离屏渲染，不是概念图或 iPhone 真机截图。既有未提交平衡与战术文案改动保留；本轮只调整成长展示与入口反馈。
