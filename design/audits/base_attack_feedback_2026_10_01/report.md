状态：代码修复与本地验证完成；5142项专项、82项GPU检查及62项非视觉RC全绿；iPhone真机待复核。

# 全僵尸 / 全首领攻击基地反馈修复 · 2026-10-01

## 原因与边界

- 普通喷吐弹原先受普通装饰特效预算限制，满载直接返回；弹体未显式设置图层，亦可能被角色/防线覆盖。Boss投射物、预警、光束、落点、备用序列均受同一预算限制，所谓优先特效也有上限，因此整条攻击演出可能同时消失。
- 有攻城profile的Boss会跳过通用基地受击特效。这个判断不能代替远程技能的独立命中反馈；更不能假设被限流的Boss专用演出已经播放。
- 冰霜远程场域当前 `bd_coef=0`，不凭空恢复伤害或伪造基地命中。其实际攻城“冰牢坠击”整轮28点仍由原有攻城序列结算。本次不改任何20僵尸/8首领数据、血量、攻击间隔、波次、数量、减伤、护盾消耗或RNG。

## 实现

- `gameplay/vfx/base_attack_feedback.gd`：一个独立Node2D承担关键战斗反馈，起手、路径、命中各最多12条；邻近重复反馈刷新、超限淘汰最旧项，不创建无界粒子或节点。空闲不持续重绘。
- 起手提示依照普通攻击的真实contact_ratio与Boss windup；普通僵尸只给源头小提示，Boss另有基地落点圈。
- 所有真实基地扣血/格挡事件显示位于运行时 `BREACH_Y` 的命中反馈；绝对z76避免被英雄、护盾边界或玩家冰霜击中特效遮挡。冰霜碎片、酸液滴、火焰和电弧区分元素，近战不冒充发射子弹。
- Boss逐发/逐击视觉事件有独立有界路径和落点反馈；仍保留每位Boss已有素材、施法序列、投射物、光束、冲刺残影、震动与音效，不用统一闪光替代原有演出。最终整轮结算取消尚未触发的保底落点，避免延迟特效把正确的护盾格挡覆盖成受伤。
- 命中保留0.46秒真实时间、路径残留0.30秒真实时间，5倍速不会压缩到难以辨认；飞行/起手仍跟随原有游戏时间。省电/减弱效果减少碎片数量，保留必要信息。
- 腐蚀喷吐原有弹体升为优先预算、z28；即使优先预算也耗尽，关键路径和命中仍可见。死亡爆炸以真实半径命中与否触发；元素读取机制ID，避免英文文案造成火焰/毒雾错误显示成物理。
- 确定性战斗探针跳过新的纯表现节点，不增加抽样或改变战斗时间。旧喷吐即时扣血/0.22秒视觉飞行的时间安排原样保留，本次不以调整伤害时间换取效果。

## 验证与证据

- `tools/audit_base_attack_feedback.gd` 已接入非视觉RC。全20僵尸＋8Boss × 标准/省电(减弱效果) × 1/2/5倍速 × 正常/320个特效节点耗尽预算，共12组；检查实际攻城信号链、原始整轮伤害、护盾只扣一次、真实基地线、图层、起手不提前伪造命中、寿命与容量。
- 附加8种远程路线（含零伤害契约）、爆炸/毒雾中英文及命中/未命中半径分支；共5142项、零失败。不是全99关难度扫测，不据此宣称全关胜率变化。
- 原生Compatibility GPU离屏截图为1080×2340，使用独立合成存档（冰霜Lv20、散弹Lv10、冰霜精灵Lv1），不读写用户真实存档。基地生命人为设为10000以隔离观察反馈，不代表实际玩家血量。
- `*_contact.png`：28种敌人各一张公共特效预算完全耗尽后的基地命中；`boss_*_authored.png`：8位Boss正常预算、逐渲染帧推进的原有演出；`*_route.png`：腐蚀远程路径与冰霜攻城弹中途。GPU测试比较隐藏/显示关键节点后的基地区域像素差，防止只检查节点存在但实际上不可见。
- `zombies_inspection.png` / `bosses_inspection.png` 为原生截图裁切索引，非新游戏美术。按data表顺序，从左到右、从上到下：
  - 普通：shambler、runner、brute、bomber / screamer、spitter、crawler、armored / shielder、hopper、juggernaut、phantom / necromancer、toxic、charger、regenerator / splitter、warden、mutant、berserker。
  - Boss：tank_titan、inferno_maw、frost_warden、storm_caller / plague_mother、void_phantom、necrotitan、apex_overlord。

最终日志：

- `feedback_matrix.log`：5142项、零失败；`release_checks.log`：62项非视觉发布门禁全部通过，包括asset/data/res引用/level pressure/card director/Godot启动/M1七项必需验证。
- `render_checks.log`：82项、零失败，28个满载基地命中与8个正常演出的可见像素差均通过，生成38张截图及两张索引。
- 首次正常演出截图发现HUD仍是前一位Boss/上一轮生命值（截图未让UI刷新后再读取）；已只修改截图脚本等待帧顺序，用 `--authored-only` 补拍八位并覆盖候选图片，`render_hud_checks.log` 26项零失败。最终图片的标题、生命与敌人对应；未修改游戏HUD。
- 最终专项/GPU/RC日志无ERROR、SCRIPT ERROR或资源泄漏警告。早期捕获尝试的frame_post_draw等待与矩阵残余浮字不作为通过证据；截图脚本已改为显式绘制与独立新场景，避免重演或混入前序样本。

Changed files：`gameplay/battle/battle.gd`、新增 `gameplay/vfx/base_attack_feedback.gd`、新增 `tools/audit_base_attack_feedback.gd`、`tools/check_release_candidate.py`、两份M1进展文档与本证据目录。既有loadout排版修改与审计仍保留，未在本任务重做。

## 待确认

- iPhone真机的密集尸潮、开启减弱效果及1/2/5倍速观感仍需Owner复核；本轮实际运行030战斗场景的合成全敌人攻城测试，未新增1/5/10/20/50/99整关实战或99关难度扫测。
- 本次不打包、不上传TestFlight、不push。既有出战配置排版等未提交内容保留，没有混入本次战斗机制修改。
