状态：材质特效重做与动作打磨完成，最终自动验证全部通过；iPhone 真机观感待 Owner 确认。

# 战斗特效材质化重做 · 2026-10-02

## 本轮纠正

上一轮验证了“基地扣血时有可见反馈”，但圆圈、辐射线、三角尖角和折线不满足 Owner 的美术要求；功能通过不等于美术验收。本轮删除这些战斗占位绘制，使用生成工具制作并二次精修透明材质图集，再接入真实 Godot 渲染验证。没有更改难度、伤害、攻击间隔、敌人数量、控制效果或付费倍率。

## 素材与替换覆盖

- 三张新透明图集，12 组材质、48 个不同阶段：金属/碎石、燃烧、冰晶、酸液、电浆、虚空裂隙、护盾折射碎片、起手烟尘，以及四种定向流动拖尾。
- 共六次图像生成/精修。首版存在贴近格子边缘的问题而被弃用；最终原始 PNG 不经裁切修改直接保存，分帧读取真实尺寸，加入虚拟透明留白和滤波裁剪。实际源图最小留白约 17px，不虚称生成结果完全满足提示中的 20%；运行时另加每侧 10% 透明留白，守住有效安全边距。
- 四阶段交叉渐变；持续烟尘使用往返播放，不硬切首尾帧。拖尾方向按源图“亮端在左”校准。
- 20 种普通僵尸和 8 位 Boss 的独立关键通道：起手、近战接触、酸液弹道、光束、基地命中、格挡全部材质化；预算耗尽、减弱效果与倍速仍保留信息。
- 同步替换共用枪口叉线/气泡、连锁折线、穿透线、规则冲击圈、死亡几何碎片、护盾破裂、角色/宠物旋转线圈，以及四套主题的纯色长条拖尾。现有已采用正式素材的人物、敌人、技能和 Boss 序列保留，不重绘为另一套风格。
- 主题枪口显式指定材质：雷霆为电、炼狱为火、绝对零度为冰、黄金律为金属火花。不用旧“叉线条数”推断材质；冰霜、护盾、电系命中同样显式区分。
- `gameplay/` 当前没有直接绘制圆、弧、多边形或纯色折线的战斗代码。剩余四个 `Line2D` 是四套主题连续曲线材质的承载网格，不是几何线条贴图；连续拖尾网格也保留，渲染内容已换成有纹理的流动材质。

源提示词：`assets/production/source_refs/generated/combat_vfx_2026_10_02/prompt_log.md`；登记：`assets/production/OUTSOURCER_ASSET_INDEX.json`。新素材仅位于 `assets/production/sprites/vfx_polish/`，没有覆盖已接受的旧图片。

## 动作节奏

普通攻击的身体位移改为“短促后收蓄力 → 快速向防线触及 → 平顺回收”，取消左右漂移。Boss 攻城的首次动作触及点对应原有起手时间，保留原有正式攻击帧、弹体飞行和多段演出。只是调整可视姿态，原有实际扣血时刻、整轮预算、控制/护盾结算均不变。

## 验证与证据

最终版本：完整 63 项非视觉 RC 全部 PASS；全敌人专项 5421 项零失败；原生基地反馈 361 项零失败；原生材质/辅助路径/动作补验 326 项零失败。最终三个执行进程均 exit 0，日志无 ERROR/资源泄漏告警。对应 `release_final.log`、`render_final.log`、`polish_native.log`；材质分类修正前的日志另留档，不冒充最终结果。

必需七项包含：`validate_asset_pack.py`、`validate_data.py`、`check_res_refs.py`、`check_level_pressure.py`、`simulate_card_director.py`、Godot headless startup、`m1_smoke_test.gd`。其余门禁包括本地化/release strings、动画与动作、音效、四套主题、资源与预算，以及新增 `check_combat_material_art.py`。

| 必需命令 | 最终结果 |
|---|---|
| `python3 tools/validate_asset_pack.py` | PASS |
| `python3 tools/validate_data.py` | PASS |
| `python3 tools/check_res_refs.py` | PASS |
| `python3 tools/check_level_pressure.py` | PASS |
| `python3 tools/simulate_card_director.py` | PASS |
| `godot --headless --path . --quit` | PASS（隔离 HOME 启动器） |
| `godot --headless --path . --script res://tools/m1_smoke_test.gd` | PASS（同一隔离启动器） |

只使用 030 的独立合成战场拍照和专项验证；不是 99 关通关实测，也不是用户的真实存档。RC 内的静态模型检查不能表述为全量实战通过。

- `audit_base_attack_feedback.gd`：标准/省电减弱 × 1/2/5 倍速 × 正常/预算饱和；全敌人攻城、格挡、远程、死亡爆炸、容量和寿命；增加材质与动作姿态断言。
- 原生 OpenGL 1080×2340：28 种敌人预算耗尽的命中、8 位 Boss 正常预算真实攻击周期、腐蚀喷吐与冰霜攻城飞行路径；隐藏/显示关键节点进行真实像素差检查，不以“节点存在”代替可见性。
- `capture_combat_vfx_polish.gd`：八类材质四阶段、九条实际枪口/命中/连锁/护盾辅助路径，以及全部 28 种敌人的休止/蓄力/触及/回收分帧。是原生游戏渲染截图，不是生成的游戏画面。
- 补拍脚本首轮因没有等待 Godot 重绘队列，七个辅助路径被误拍为空；加实际帧等待后重验。原始失败日志保留在 `polish_native_initial.log`，不修改游戏规则绕过断言。

截图：

- `bosses_inspection.png`：8 位 Boss 关键命中。
- `zombies_inspection.png`：20 种普通僵尸关键命中。
- `materials_native_phases.png`：各行依次为物理、火、冰、毒、电、虚空、格挡、蓄力，左至右为动画进展。
- `*_contact.png` / `*_authored.png`：全屏原生截图。
- `*_motion.png`：各敌人的四点身体姿态；不是整段攻击视频，也不替代 Boss 实际演出检查。
- `chain_native.png`、`muzzle_*_native.png`、`impact_*_native.png`、`shield_native.png`：实际辅助路径。

## 交付边界

未改任何战斗数据表；未重跑 99×10 难度探针；未修改用户存档；未打包、上传 TestFlight、commit 或 push。现有未提交的出战摘要布局修改保留。

桌面真实渲染与自动门禁不能替代 iPhone 16 Pro Max 的密集尸潮帧率、触感和最终美术认可；这些仍待真机复核。减弱效果维持克制的可读反馈，不承诺完整装饰层在饱和预算下都出现。
