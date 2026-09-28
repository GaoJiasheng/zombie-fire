状态：已完成；双语、全目录布局、完整 M1 冒烟与截图抽查通过，待 Owner 真机阅读确认。未提交、未打包。

# 全目录战术说明审计（2026-09-27）

## 范围与交付

| 类别 | 数量 | 说明 |
|---|---:|---|
| 局内强化技能 | 16 | 机制、加点收益、搭配、作用边界 |
| 人物 | 4 | 属性定位、成长、亲和与主动技玩法 |
| 武器 | 12 | 原生属性、弹道、节奏、成长、配装取舍 |
| 护甲 | 10 | 生命、防护匹配、护盾/反击/修复区别 |
| 芯片 | 12 | 主副属性、成长方式、生效条件 |
| 宠物 | 10 | 独立攻击、协战技能、团队词条与局限 |
| 人物能力 | 12 | 4 被动、8 专属能力的独立建议 |
| 共享模型说明 | 5 | 技能成长、弹药覆盖、武器参数、护甲防护、人物属性 |

全部中英对照正文以 `data/tactical_guides.json` 为唯一展示源。已有各级数值仍直接从装备和技能表读取，避免把伤害数字抄进散落文案后漂移。

## 发现与纠正

1. 技能战术区原先全部返回一段图鉴使用提示；现在逐项解释，并前置在数值等级表之前。永久等级是首次选牌的起点，不是自动装配；同名再选使用下一等级效果，不累加每一行。
2. `projectile.gd::_hit` 的分裂伤害为主弹乘 `split_falloff`，原“衰减55%”容易被理解成只保留45%。改成“小弹伤害比例55%”。数量增加、单颗比例下降，文案不伪称每颗更强；不改数值。
3. 贯穿是穿过目标，护甲穿透是将部分伤害送入本体；纠正穿透短描述暗示单体厚血收益的说法。
4. `battle.gd::_apply_base_survivability` 中先锋被动实际乘漏怪伤害系数，旧文案却说赠送护盾。现在按减伤事实描述；专属过载标为自动而非弹种。
5. 冰霜 `amplify_character_status` 强化减速并配合受控目标碎冰，不保证冻结。纠正被动短说明；首领减速上限保留清楚提示。
6. 弹药卡支持物理武器和已开放适配的付费武器；免费原生元素武器不被异元素覆盖。四卡互斥；付费过载/爆燃/碎冰/裁决仅在最终元素等于原生元素时触发。
7. 护甲防护在当前模型中与关卡 `primary_weakness` 匹配，影响漏怪伤害，不是逐次读取来袭攻击元素。解释现有模型，不擅自更改计算。
8. 元素芯片的主炮加成按武器原生元素接入：物理枪装元素弹不能假定享受同样加成。天隼标记的附加伤害由黄金律命中消费，不宣称全武器通用增伤。两项均属于实际边界，不在文案任务中偷偷改机制。
9. 新文案沿用上一轮角色调整后的事实：冰霜控制为主、电系同次施法同目标递减、火焰局部范围；没有回退此前调优。

## 证据入口

- `gameplay/skill/skill_runtime.gd`：等级读取、弹药互斥与最终元素、控制上限。
- `gameplay/projectile/projectile.gd::_hit`：分裂保留比例、贯穿。
- `gameplay/battle/battle.gd`：`_chip_value`、`_apply_base_survivability`、`_apply_turret_modifiers`、`_apply_premium_weapon_on_hit`、`_apply_apocalypse_golden_law_on_hit`、宠物协战与角色主动技。
- `core/data/character_skill_text.gd`：共享人物能力短说明，保留上一轮数值成长口径。

## 验收

- `check_tactical_guides.py`：PASS，64 条目+12 能力+5 模型；双语完整、同类不重复、无孤立 ID。
- `audit_tactical_guides.gd`：PASS，64×2语言×2比例=256，正文接入、换行、尺寸与尾行可达检查零失败。
- `validate_asset_pack.py`、`validate_data.py`、`check_res_refs.py`、`check_level_pressure.py`、`simulate_card_director.py`：PASS（资产检查保留原有生成缓存豁免）。
- `check_localization.py`、`check_release_strings.py`、Godot headless startup：PASS。
- `godot --headless --script res://tools/m1_smoke_test.gd`：PASS，最终日志 `M1 smoke test passed`，零 ERROR；首轮发现英文人物长段整块无法停在页尾后拆分为战术/模型两块，修复后重跑通过，未删除或放宽原布局断言。
- OpenGL 实际渲染：8 个代表条目×中英×顶/底=32 张；渲染检查 16 页面零失败，人工抽查分裂弹、火焰弹药、黄金律武器、永冻护甲、人物和天隼的长文本。最后一轮增加正文左右 12px、底部 20px 安全留白，缩短分裂弹头部摘要，避免悬空尾字。
- 测试采用 `/tmp/zf-signature-after.G09iKx` 隔离项目与专用 user 目录，软链接读取当前源码；没有修改真实玩家存档。最终日志：`/tmp/zf-tactical-smoke-final.log`、`/tmp/zf-tactical-layout-final.log`、`/tmp/zf-tactical-capture-final.log`；截图：`/tmp/zf-tactical-captures-final/`。
- `git diff --check`：PASS。本轮没有实际关卡探针；已有角色调优的关卡结果仍以其独立报告为准。

## 本轮改动文件

- 文案：`data/tactical_guides.json`、`data/localization_gameplay_en.json`。
- 展示接入：`core/data/data_loader.gd`、`core/data/character_skill_text.gd`、`core/data/skill_effect_text.gd`、`ui/skill_description.gd`、`meta/collection/collection.gd`。
- 回归：`tools/check_tactical_guides.py`、`tools/audit_tactical_guides.gd`、`tools/m1_smoke_test.gd`。
- 文档：本报告、`design/data/schema.md`、`design/data/naming_convention.md`、`design/m1_todo.md`、`design/m1_implementation_progress.md`。

## 实施边界

无新增伤害、等级、解锁、价格、掉落改动。保留本轮之前尚未提交的角色调优。未跑战役性能/通关探针，未打包、上传、推送或修改玩家存档。真机触摸滚动与阅读节奏仍由 Owner 验收。
