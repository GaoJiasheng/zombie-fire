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

## 付费商品全卡详情与详情内购买（2026-08-13）

- [x] 商店商品四格头像/装备预览、商品文案区与整张卡片均可打开详情；原购买按钮仍保留直接购买路径
- [x] 主题单品详情完整列出 4 套角色战衣、8 把免费武器主题外观、全局界面/基地/HUD/开火特征，并明确纯外观、不增加战力
- [x] 完整包详情同时列出主题全部内容、终焉武器/护甲/芯片/宠物、等级上限、五档外观进化、套装效果、主宰区间与满级强度目标
- [x] 主题拥有者升级包只列出实际补齐的四件军械，明确主题不重复计价；详情底部固定保留真实商品状态与购买按钮
- [x] 详情入口继续遵守 30 / 50 / 80 / 99+Lv.40 的系列揭示门禁，不允许通过隐藏调用查看或购买未解密系列
- [x] M1 smoke 覆盖四套主题的主题/完整/升级共 12 个逻辑商品；中英文 24 张 1080×2340 截图通过运行时与图片审计

## 局外技能等级预载到局内首次选卡（2026-08-13）

- [x] 修复局外已升至 4 级的技能在局内首次三选一仍显示“等级 1”与 1 级数值的问题
- [x] “本次点选后的等级”统一由 `SkillRuntime` 计算：未获得时取永久等级（最低 1），已获得时才在当前局内等级上 `+1`
- [x] 卡牌徽章、卡牌本级数值、详情层、实际生效等级与底部 HUD 共用同一等级结果；永久技能首次拿到即应用其真实等级对应效果（多重射击现行 Lv4 为 3 个额外弹道 + 8% 单弹伤害回补）
- [x] 永久等级只作为首次获得基线，不会在开局时自动赠送所有已升级技能；第二次拿到 4 级技能正常预览并升至 5 级
- [x] M1 smoke 覆盖 `0 → 永久4 → 局内5` 完整链路；固定 `4 / 3 / 2` 级三选一截图通过运行时与图片审计

## 局外养成资源图标统一（2026-08-13）

- [x] 修复通用技能实际消耗经验却显示 `★` 的资源类型串位；技能永久升级与角色专属主动技统一显示经验图标和纯数字成本
- [x] 角色、武器、护甲、芯片、宠物升级统一显示金币图标；免费内容解锁统一显示星星图标
- [x] 收藏列表、收藏详情、角色详情与已拥有终焉军械升级共用“操作 + 资源 Logo + 数量”组件，不再用文字或符号猜资源
- [x] 评分星与法币商店价格保持原语义；天赋点、刷新点已登记对应图标，但未虚构当前不存在的消费规则
- [x] 新增静态发布门禁与 M1 运行时断言，校验真实扣除资源、图标路径和显示数量一致

## 战斗连击文字光学居中（2026-08-13）

- [x] 连击主文案不再仅依赖字体行框的数学居中；根据实机复核把初版 `-8 px` 过度矫正收回到统一 `-4 px`，所有位数共用同一规则
- [x] 截图工具支持精确指定连击数，并固定回归 `2 / 11 / 100 连击`，覆盖一位、两位和三位数字
- [x] 图片门禁直接测量黄色字形与面板的实机光学中心，允许误差不超过 `2 px`；三档 1080×1920 实机截图均通过

## TestFlight Build 48 · iPhone 分辨率与上线前 UI 验收包（2026-08-11）

- [x] 完整 Release Candidate 门禁通过后生成 `1.0.0 (48)`；iOS Archive、App Store IPA 导出与包体审计全部通过
- [x] TestFlight 验收包临时启用 `testflight_speed_unlocked` 与 `testflight_premium_preview`；后者仍遵守最新进度揭示规则，不提前显示未通关对应门槛的主题/军械
- [x] Apple 上传与服务器验证完成：Delivery UUID `01e9553c-79d7-471a-9ecb-6c837a40a800`，`BUILD-STATUS: VALID`、`IMPORT-STATUS: VALID`、`APP_STORE_ELIGIBLE`
- [x] 上传后 iOS 发布预设恢复为普通 `release`，正式版本继续按关卡开放倍速，并保持付费系列的 30 / 50 / 80 / 99+Lv.40 揭示节奏
- [x] 已上传 IPA 复制到 `/Users/gavin/Desktop/ZombieFire.ipa`；交付记录保存在 `build/ios/release/build_48/`
- [x] 10 类 iPhone、菜单/局内共 20 张最终截图保存在 `/Users/gavin/Desktop/ZombieFire_iPhone_Resolution_Regression_2026-08-11/`，不纳入 Git

## iPhone 全屏与安全区分辨率回归（2026-08-11）

- [x] 建立 10 类经典 iPhone 纵向画布回归矩阵，覆盖 SE、Home 键大屏、刘海屏、mini、Dynamic Island 与 Pro Max 长屏比例
- [x] 每类设备完成菜单与局内各一张最终截图，共 20 张；全组保持全屏铺满，无黑边、无背景露底
- [x] 顶部波次条、暂停/倍速、Boss 名称与 Boss 血条按顶部安全区联动；底部金币、经验、基地生命、技能与主动技能按底部安全区联动
- [x] 修复高纵横比 iPhone 上 Boss 名称/血条仍停留在设计坐标、与已下移的波次条重叠的问题
- [x] 10 类设备的运行时 UI 审计均为 `0`；最终截图与设备矩阵说明输出到 Repo 外部，不纳入 Git

## 上线前设置页伪进度横线清理（2026-08-11）

- [x] 设置主面板改用连续底板与仅绘制四周的金属边框，移除标题区及长面板空白区中由纹理拉伸产生的无语义横线
- [x] 标题、按钮、音量滑杆和所有设置交互保持不变
- [x] 中英文设置页各完成一张聚焦截图回归

## 技能详情伪进度横线专项回归（2026-08-11）

- [x] 确认 `Tesla Rounds / 特斯拉弹` 标题下横线同样来自旧详情面板纹理拉伸，不是技能进度、等级进度或可交互控件
- [x] 技能详情纳入收藏详情共用的连续底板与仅绘制四周的金属外框；标题、等级、标签、数值和升级交互保持不变
- [x] M1 smoke 新增技能详情连续底板、无中心绘制外框和生产素材路径断言；中英文 Tesla Rounds 长屏截图完成专项复验

## 难度回归收尾 · level_003 新手期星级断点（2026-08-03）

- [x] 仅将 `level_003` 末波僵尸数从 `17` 调整为 `14`（全关总数 `64 → 61`，`-4.69%`），未改基地血量、敌人攻击、全局难度或星级阈值
- [x] `simulate_balance.py` 实测该关漏怪率由 `65%` 降至 `59%`，评级由全战役唯一 `1★` 提升为 `2★`
- [x] 前后 99 关逐关星级 diff 仅包含 `level_003`；`level_001/002` 与其余 96 关评级不变
- [x] 全战役星级分布更新为 `12 × 3★ / 87 × 2★ / 0 × 1★`
- [x] `check_level_pressure.py` 保持逐关压力单调；提高基地血量的备选方案因会造成 `level_003 > level_004` 而被门禁否决、未保留
- [x] 完整 Release Candidate 门禁通过

## 付费军械购买前定位护栏（2026-08-03）

- [x] 雷霆完整包 / 补差包双语披露“战役中段 · 雷弱关 / 虚空幻影三连 Boss / 全部中立关”，不暗示终局提升
- [x] 炼狱、绝对零度分别披露火弱 / 冰弱主宰区间；黄金律明确“终局毕业 · 终局 Boss 只认物理”
- [x] `premium_sets.json` 作为完整包与补差包的唯一文案源，主题单品不显示军械战力承诺
- [x] 商品卡片与购买确认均在购买动作前展示主宰区间；中英文各完成真实商店截图核对
- [x] `check_release_strings.py` 防止字段缺失、双语前缀错误或前三套误写终局定位
- [x] 完整 Release Candidate 门禁通过

## 付费军械满级合同带发布门禁（2026-08-03）

- [x] 雷霆 `1.550x`、炼狱 `1.571x`、绝对零度 `1.547x` 均以 `premium_sets.json` 的 `1.52–1.58x` 数据合同带进行断言
- [x] 黄金律 `2.043x` 继续以数据中的 `1.90–2.05x` 合同带断言；四套审计全部接入 `check_release_candidate.py`
- [x] `validate_data.py` 校验每套 `min ≤ center ≤ max`，黄金律同时校验一级开局合同，不在审计代码内复制合同阈值
- [x] 负向验证：临时将雷霆 `base_atk_coef 0.584 → 0.700`，发布门禁在 `1.794x` 明确变红；恢复后四套审计与完整门禁全绿
- [ ] 雷弱 HARD 关配装页软推荐：Owner 未明确勾选，按任务简报默认不做

## 减速力场 V2 · 渲染品质与真实减速闭环（2026-08-03）

- [x] 移除旧版“拉伸冰带 + 交叉正弦线”的网格占位表现，换成深渲染冰晶 / 极光 / 冷雾介质
- [x] 将力场拆为固定尺寸前缘与固定密度无缝内部纹理；等级扩大时只移动边界、增加平铺覆盖，不拉伸任何渲染原型
- [x] 前缘位置、内部覆盖与真实减速共同读取 `data/skills.json` 的 `y_min`，继续保持 30% / 40% / 50% / 60% / 70% 范围合同
- [x] 实际移动门禁逐级实例化真实 `enemy.tscn`，验证 Lv1–5 的每秒位移为基础速度的 82% / 74% / 65% / 57% / 48%
- [x] 边界外 1 像素保持 100% 移速；范围内才应用减速，视觉与逻辑没有全屏偷效
- [x] 1080×1920 实机截图分别核对 Lv1 / Lv5，UI 审计均为零问题

## App Store 上架前最终截图回归（2026-08-02）

- [x] 建立 `954` 路最终截图矩阵：全五种主题状态、四名角色、十二把武器、左右/中央射击、主动技能、十六项技能、全装备集合、二十类僵尸、八名 Boss、状态/命中/死亡特效与所有主要界面
- [x] 中英文分别覆盖菜单、地图十章、出战配置、收藏详情、外观、设置说明、结算、暂停、完整本地演示商店与购买确认
- [x] 修复隐私/支持说明截断与文意、`Not Equipped Lv0`、武器内置属性空格、地图章说明贴边、英文长章名与徽章重叠、技能详情裸露 `element` 枚举
- [x] 降低仅霓虹主题按钮表面的亮度与饱和度，保留朋克轮廓和文字层级
- [x] 修复设置页紧凑安全区最小高度向上下溢出 `2px`；长屏与 Dynamic Island 模拟安全区均通过
- [x] 修复最终截图中的技能 VFX 出场时机和商店未解锁空目录，保证验收图真实覆盖可见效果及八个商品卡
- [x] 三分片清单均为 `318/318`、`error_count=0`；合计 `954` 个唯一文件、无缺图，并生成 `55` 张分类 contact sheet
- [x] 最终截图与 contact sheet 输出到 Repo 外部供 Owner 人工复核，不纳入 Git、不提交

## 第二付费系列 · Step 0 / Step 1（2026-07-31）

- [x] 将购买、权益回收、商店系列、主题材质、按钮调制、战斗主题效果、premium 握持与 VFX profile 从霓虹写死逻辑解耦为数据驱动
- [x] 现有霓虹 / 雷霆路径完整回归：43 路霓虹截图通过，雷霆满配综合输出仍为免费 Volt 构筑的 `1.550x`
- [x] 完成炼狱赤焰色板 / 材质、四角色完整战衣、八把免费武器涂装原型
- [x] 完成三种炼狱等离子喷射器机械轮廓、熔火再生甲、恒星燃烧核心与余烬凤凰同页方案
- [x] 完成短 / 标准 / 长三种独立按钮、Logo、UI、基地 / 防线代表稿
- [x] 完成 1080×2340 实战综合图与十段攻击 / 套装 VFX 分镜
- [ ] Owner 选择主武器 A / B / C 轮廓并确认视觉方向；通过前不进入 Step 2 runtime 批量生产

## 上线前 · 四主角射击动作顶级打磨（2026-07-26）

- [x] 四主角 × 八武器 × 左/中/右三方向全部重做为 8 帧动作，共 768 张透明运行时帧
- [x] 统一建立 F1 预备、F2 点火、F3 后坐峰值、F4 机构响应、F5 反向制动、F6 回稳、F7 收束、F8 待命的动作语义
- [x] 钢铁先锋体现重心下沉与承重，火焰少年体现持续压枪，冰霜少女体现精确控制，电弧少女体现弹性回震
- [x] 八种武器分别配置动作速度、预备提前量和后坐曲线，不再共用一种机械晃动
- [x] 射击事件先切到 F2 点火帧再生成枪口焰与子弹；弹道仍即时生效，不引入玩法延迟
- [x] 修复旧枪口坐标按 `0.64` 视觉缩放制作、运行时改为 `0.512` 后产生的枪口漂移；96 个方向全部重新校准
- [x] 手动触控瞄准、手动锁定与自动瞄准逻辑保持不变
- [x] 生成动作参考、提示词、manifest、全 32 套序列 contact sheet 与四主角实机截图；参考图只约束动作，不覆盖已验收角色身份
- [x] 永久回归覆盖 96 套序列的帧数、相邻运动量、F2→F3 后坐、透明安全边距、轮廓面积漂移、枪口贴合和方向走廊
- [x] 最终验证：资源包 `9,222` 文件、`353` 个 `res://` 引用、99 关压力、39 项 Release Candidate 与 79 路全界面截图全部通过

## 上线前 · 普通僵尸攻击动画顶级打磨（2026-07-26）

- [x] 20 类普通僵尸逐一设计专属“预备—命中—收招”动作语义
- [x] 每类从 4 帧通用晃动升级为 8 帧、512×512 透明序列，共 160 帧
- [x] 所有方向统一指向屏幕下方基地，完整肢体与武器不出框
- [x] `data/zombies.json.attack_animation` 驱动时长、命中比例、命中帧与前冲
- [x] 基地伤害由动作开始改为第 4 帧接触时结算；收招不重复扣血
- [x] 僵尸驻足攻击间隔改播 idle，不再循环假挥空
- [x] 受击反馈不再遮掉已经开始的接触姿势
- [x] 召唤、腐蚀远射、再生补齐专属姿势调用
- [x] 静态验收：帧数、透明边距、碎片、关键姿势轮廓差异、manifest
- [x] 运行时验收：20 类命中帧时序冒烟 + 4 组手机尺度实机截图
- [x] 永久回归：攻击专项门禁加入 39 项 Release Candidate；全界面矩阵由 75 路扩展至 79 路
- [x] 最终验证：资源包 `8,805` 文件、`353` 个 `res://` 引用、99 关压力、Godot / battle / save / M1 smoke 与 79 路截图全部通过

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

## 阶段 15 · 战斗倍速进度解锁（2026-07-14）

- [x] P1：最高已解锁关卡低于 30 时隐藏倍速按钮，并把旧存档中的高倍速安全限制为 `1X`。
- [x] P1：解锁第 30 关后开放可见的 `1X / 2X` 切换；解锁第 50 关后才加入 `5X`。
- [x] P1：headless smoke 覆盖第 29、30、50 关三个进度档位及旧 `5X` 设置兼容。

## 阶段 16 · iPhone 上线最终打磨（2026-07-14）

- [x] P0：iOS 发布范围收敛为 iPhone-only；Godot 预设使用 `targeted_device_family=0`，实际导出的 Xcode 四个构建配置均验证为 `TARGETED_DEVICE_FAMILY=1`，发行脚本在归档前强制检查成品工程。
- [x] P0：修复 Blaze 主动技火焰截断；正式替换为 14 帧 768×768 透明 PNG 安全边序列，峰值火焰、余烬和 glow 均留在画布内，`check_active_skill_media.py` 通过。
- [x] P0：四名角色主动技成长从纯数值升级为角色差异化成长；伤害/冷却之外，先锋增加齐射与目标数，Blaze 增加半径/灼烧/脉冲，Frost 增加全屏控制持续/减速/波次，Volt 增加目标与打击数；数据 schema、文案、图鉴与 smoke 同步。
- [x] P1：设置页补齐独立音乐/音效/UI 音量、低特效和触觉开关；屏幕震动、受击闪白、主动技/Boss 触觉均遵守设置，音频与设置持久化回归通过。
- [x] P1：地图锁定态、图鉴技能详情、结算弹层和战斗 Toast 做可读性/留白/高屏位置收口；42 个真实路由截图与 safe-area 检查通过。
- [x] P1：99 关难度曲线重新平滑；保留敌人阵容、波次数量、晚波倍率、Boss 翻倍和奖励，仅校准 `difficulty_coef`，自动估算平均 105.3 秒、最大 154.0 秒、无关卡超过 180 秒，终局为全局 HP 峰值。
- [x] P1：新增 96 组开火序列相邻动作/后坐力检查与真实 5X 战斗 smoke，防止静帧攻击和敌人/子弹/VFX 泄漏。
- [x] P1：基于当前运行版本重新捕获战斗、战区地图、真实三选一、配装与 Boss 战，刷新 iPhone 6.5/6.7 英寸商店截图及 App Preview；App Store 资产检查通过。
- [x] P1：设置页三条音量滑杆改用原生波次装甲槽与青色能量填充纹理，移除默认白色几何手柄；暂停暗幕复用现有纹理层。新增 `tools/check_runtime_ui_primitives.py` 并接入 RC，运行 UI 的 `ColorRect / StyleBoxFlat` 当前零命中。
- [x] P1：出战配置页底部操作区修复；战术摘要高度按完整内容重新计算，摘要与“开始战斗 / 开始挑战”按钮之间保留独立安全间距，标准屏与高屏截图均无边框、文字或按钮重叠，并加入 smoke 几何间距断言。
- [x] P1：出战配置四角色大立绘头顶裁切修复；保持原有 `378px` 放大尺寸，仅按共同源画布重新校准纵向位置。先锋头发、Blaze 护目镜、Frost 发髻和 Volt 发饰均完整显示，并以实际 alpha 边界锁定 `6–20px` 头顶安全留白。
- [x] P0：高屏战斗底部基座复位；恢复 `bottom_dock_shift`，让防线、人物、宠物、主动技能和底部资源条随 `canvas_items + expand` 的额外屏高统一下移，并继续与 1080×2622 背景堡垒底边对齐；倍速按钮补入顶部安全区，与暂停键/波次条保持同一基线。高屏几何 smoke、10 环境布局检查与高屏安全区截图回归均已覆盖。
- [x] P0：iPhone 视口矩阵收口；按 1080 宽归一化验证 `1920 / 2046 / 2337 / 2340 / 2348 / 2622` 六档高度，逐档锁定防线、人物、宠物、底部 HUD、主动技能、暂停与倍速按钮。菜单、地图、配装、图鉴、设置、战斗、卡牌、暂停和结算均纳入高屏安全区截图；战斗长提示改为动态落在波次条下方，不再与顶部控件重叠。
- [x] 发布候选：`python3 tools/check_release_candidate.py` 全量通过；物理 iPhone、App Store Connect、公共 URL 与签名工作仅保留在 `design/iphone_app_store_owner_todo_2026_07_14.md`。
- [x] TestFlight 构建 29：完整 RC 门禁、Godot 导出、iPhone-only IPA 审计、Xcode Archive / App Store Export 与 App Store Connect 上传全部通过；Delivery UUID `bd54b3c7-3cbb-4868-89b0-7f0a853252a3`。

## 阶段 17 · 无损包体精简（2026-07-15）

- [x] P0：发行包排除仅供本地生成/打磨使用、运行时零引用的 414 张骨骼分件；生产源文件和生成工具路径保持不变。
- [x] P0：按每组 VFX 的 runtime sequence JSON 自动排除 307 张清单外尾帧；清单新增引用时自动恢复进包，包审计反向确认所有正式播放帧齐全。
- [x] P0：PCK 从 678.2 MiB 降到 584.9 MiB，签名 App Store IPA 从 706.3 MiB 降到 613.2 MiB；无有损压缩、无素材删除、无运行规则变化。
- [x] P1：`tmp/` 加入忽略规则，阻止后续 QA 截图继续污染仓库；现有 Git 大对象历史保留，待干净工作树和备份完成后单独执行 Git LFS/history 迁移。

## 阶段 18 · 50–99 关毕业压力曲线（2026-07-15）

- [x] P0：第 50–98 关第 3 波以后 HP 与压线伤害改为持续线性增长；第 97/98 关已接近或达到常规曲线顶点，不再把压力集中到最后一关。
- [x] P0：第 99 关在第 98 关顶点之上增加独立终局倍率，晚波 HP 达到 `2.16x`、压线伤害达到 `2.30x`；推荐战力同步提高到约 `400`。
- [x] P0：终局验收锁定至少三套满级物理克制构筑可过；属性错误且未满级的主武器不能靠 Boss 通用伤害下限舒适磨过。
- [x] P1：移除第 50 关后的欠战力基地生命暗补偿，并修正配装页“克制有效”只按主武器元素判断，避免 UI 把角色属性误报为整套主武器克制。
- [x] P1：新增 `tools/check_endgame_balance.py`，并接入发布候选门禁；校验第 50–98 关线性、97/98 压力、99 终局跃升及三套毕业配置。

## 阶段 19 · 防线屏障合成层级（2026-07-16）

- [x] P1：人物、武器和宠物统一置于防线屏障玻璃上方；屏障继续覆盖基地设施，不改变技能数值、碰撞范围、基地线或角色位置。
- [x] P1：M1 smoke 增加人物/宠物与 `BarrierGlass` 的运行时层级断言，截图工具增加 `debug_barrier` 视觉回归入口。

## 阶段 20 · TestFlight 构建 30（2026-07-16）

- [x] 发布候选：完整 RC、42 路由截图、Godot/PCK 双重 smoke、iPhone-only 工程与 `613.2 MiB` IPA 审计全部通过。
- [x] TestFlight：`1.0.0 (30)` 上传成功；Delivery UUID `95403f3f-e921-4fbc-911c-96ae86291287`。

## 阶段 21 · 技能感知战力与一线手游深度打磨（2026-07-16）

- [x] P0：胜利/失败结算不再沿用统一高屏下移偏置；按实际内容高度在 iPhone 安全区内居中，并做 `24px` 视觉上提，避免 099 结算堆栈明显偏下。
- [x] P0：建立“战前 / 预计成型 / 本局终局”三层战力口径；永久技能等级、关卡选卡预算和本局真实技能等级分别进入对应计算，纯金币/重抽技能不虚增战力。
- [x] P0：推荐战力与局内技能量纲对齐；97/98 关十次选卡预算同步抬高推荐值，并只从第 3 波起追加有上限的 HP/移速压力，挑战模式继续额外叠加 `1.5x` 敌人生命。
- [x] P0：平衡脚本、数据校验、配装页、战斗 payload、结算页与 smoke 使用同一模型；禁止按玩家实时表现追赶式加难。
- [x] P0：完整 Release Candidate 门禁通过；资源、数据、引用、平衡、卡牌导演、音效、VFX、攻击动作、Godot boot/smoke 与 42 个真实路由截图均无回归。
- [ ] P0 可玩性：完成新玩家前 10 分钟三人观察测试，记录首次选卡、元素克制、主动技和失败归因是否能在无口头提示下理解。
- [ ] P0 难度设计：用真实设备实测 50/68/90/97/98/99 普通与挑战模式，记录实际选卡、终局战力、通关时间、基地剩余生命和星级；预测与实测偏差超过 15% 时只回调数据旋钮。
- [x] P0 交互体验：战斗结算新增可展开战报，展示用时、总伤害、主力元素、暴击/弱点伤害、击杀、基地承伤、格挡、控制、主动技与最高连杀，并按 Boss/挑战规则给出失败改进提示。
- [x] P0 美术与性能：VFX 与浮字预算现会同时响应低特效、1X/2X/5X、敌人密度与低电量，第四/第五波及高倍速自动收紧；真机连续 30 分钟温升、耗电与透明叠层过绘仍保留为 Owner 验收项。
- [x] P1 可玩性：在现有 16 技能范围内重塑前两次选卡；首轮保证当前配装核心、即时伤害与控制/生存，次轮保证配装核心与威胁反制，并禁止前两轮被纯经济卡占位。
- [ ] P1 耐玩性：复核 99 关 `wave_pattern` 的实际差异，在既有 20 僵尸/8 Boss 范围内增加编队、精英与支援组合变化，避免只靠 HP/数量换皮。
- [x] P1 难度设计：十章挑战模式改为数据化固定变异规则，分别调整生命、移速、漏怪伤害与机制频率；配装页入场前明确显示规则、压力倍率与反制建议，不再统一只叠 `1.5x` 血量。
- [x] P1 机制设计：8 个 Boss 均补齐可执行的反制提示，多阶段 Boss 增加数据化阶段转换播报；Boss 血条持续显示弱点，失败结算会回显本场 Boss/挑战的反制建议。
- [ ] P1 耐玩性：无尽模式在不增加永久付费成长的前提下，评估每轮“强化与代价”二选一，增强重复局差异并维持只结算金币的规则。
- [x] P1 交互体验（上线前首步）：配装页“成型”数值直接显示相对战前的技能卡预算增量，并用紧凑 `Lv` 摘要保证高等级完整可读。
- [ ] P1 交互体验（上线后结合实测）：如玩家仍无法理解成型来源，再拆分 DPS / 控制 / 防线增量预览，避免临送审新增未经验证的复杂信息层。
- [ ] P1 沉浸体验：按环境建立动态音频混音规则，限制同类枪声/受击声并发，Boss、主动技和防线告急拥有清晰优先级；分别用扬声器与耳机验收。
- [ ] P2 沉浸体验：在现有十章与锁定内容范围内补足章节开场、Boss 前后和终局的短叙事节点，并用地图状态变化反馈战线推进。
- [x] P0 商店资产：App Preview 改为 18 秒真实 Godot 运行录制，五张 iPhone 截图按战斗/地图/选卡/配装/Boss 固定去重验收。
- [x] P1 包体：iOS 发布规则额外排除无运行时引用的旧 authoring sprite 库与旧图标源文件；仓库源文件保持不删、不压缩、不改画质，最终收益以新候选 IPA 实测为准。
- [ ] Owner 验收：提供三名首次玩家的观察记录、六个代表关卡真机数据、30 分钟性能记录，以及扬声器/耳机两套音频复核结论。

## 阶段 22 · 上线前顶级打磨候选（2026-07-16）

- [x] 完整 `tools/check_release_candidate.py` 通过：字体授权、资源/数据/引用、压力与终局平衡、真实卡牌导演、音频/VFX、Godot 启动、战斗启动、M1 smoke 与 42 个真实路由截图全部无回归。
- [x] iOS `1.0.0 (31)` 本地候选完成 Godot 导出、573.2 MiB PCK 审计、导出 PCK 双重 smoke、Xcode Archive、App Store 签名导出与 601.5 MiB IPA 同源审计。
- [x] TestFlight Build 31 上传成功；Delivery UUID `47c498c5-a6ae-4f61-8957-3c73518b5d5b`，Apple 最终状态为 `BUILD-STATUS: VALID`、`IMPORT-STATUS: VALID`、`APP_STORE_ELIGIBLE`，已出现在 App Store Connect。

## 阶段 23 · Build 31 真机字体与角色图鉴回归（2026-07-17）

- [x] 按 Owner 真机反馈撤回 Noto Sans SC 全局替换，精确恢复 Build 31 之前的 `font_main.ttf`，不改游戏逻辑、数据、素材 ID 或其他已验收打磨。
- [x] 角色/装备详情弹层固定到 `z_index=64`，彻底压住图鉴列表中 `z=1..3` 的立绘、文字、遮罩和操作按钮，修复看似“乱码”的底层列表穿透。
- [x] 视觉门禁补上此前遗漏的高屏角色详情路由；角色列表与角色详情必须同时经过真机比例截图复核，不能只用空白率和安全区自动判定代替人工看图。

## 阶段 24 · 角色图鉴构图复核（2026-07-17）

- [x] P0：修复角色列表固定宽卡片被宽屏 `VBoxContainer` 左侧拉齐的问题；所有图鉴卡片统一在安全区内容宽度内居中，1080 宽画面左右边距恢复对称。
- [x] P0：重新校准列表与详情共用的四角色立绘取景；先锋头发、Blaze 护目镜、Frost 发髻和 Volt 发饰均保留明确头顶留白，不再贴边或被裁切。
- [x] P1：角色详情视觉路由从只覆盖先锋扩展到四名角色，smoke 同时锁定卡片居中和列表/详情立绘头部安全偏移。

## 阶段 25 · 未来荧黑全局字体与全界面回归（2026-07-17）

- [x] P0：按 Owner 选择，将全局 `font_main.ttf` 替换为官方 Glow Sans SC / 未来荧黑 Normal Medium v0.93 原始二进制；保留既有 Godot 资源路径，不改界面字号体系、素材 ID 或游戏逻辑。
- [x] P0：补齐 SIL OFL 1.1 原文、官方 release/文件哈希/字节数 provenance，并新增 `tools/check_font_license.py`；iOS 导出强制包含授权与来源文件，PCK 审计缺失时直接失败。
- [x] P0：跑通 46 个真实路由截图并人工复核地图、配装、战斗、三选一、暂停、设置、结算、图鉴列表及四角色详情；修短设置页操作说明，消除新字宽导致的末行裁切。同步重捕 iPhone 6.5/6.7 英寸商店截图并通过素材检查；完整 RC 与 568.3 MiB 导出 PCK 审计通过。

## 阶段 26 · 仓库开源授权与发布（2026-07-17）

- [x] P0：根目录加入标准 Apache License 2.0 `LICENSE` 与版权 `NOTICE`；第三方组件和素材继续遵循各自授权，未来荧黑明确保留 SIL OFL 1.1。
- [x] P0：完整发布门禁、iPhone-only 导出、Xcode Archive / App Store Distribution 与 IPA 审计通过；TestFlight `1.0.0 (32)` 上传成功，Delivery UUID `cdc4d138-441a-4a07-bffd-8e4a28bb23e9`，Apple 最终状态为 `BUILD-STATUS: VALID`、`IMPORT-STATUS: VALID`、`APP_STORE_ELIGIBLE`。

## 阶段 27 · App Store 隐私政策公开托管（2026-07-17）

- [x] P0：将隐私政策完善为中英文正式页面，覆盖零数据收集、本地存档、删除方式、第三方服务、儿童隐私和未来变更；同时提供公开支持入口。
- [x] P0：从独立 `gh-pages` 分支发布 GitHub Pages，启用强制 HTTPS；隐私政策、支持页及站点首页均返回 HTTP 200。

## 阶段 28 · App Store 送审资料与隐私入口收口（2026-07-17）

- [x] P0：设置页“隐私政策 / 联系支持”改为可识别的 HTTPS 外链入口，完整政策和支持页可从应用内直接访问；标准屏与高屏安全区截图均无截断、偏移或 UI 审计问题。
- [x] P0：公开支持页和隐私政策加入 `gaojiasheng.him@foxmail.com` 联系邮箱；送审元数据草案登记审核联系人，明确无需登录或测试账号。
- [x] P0：iOS 发布脚本移除未使用的相机、麦克风和相册权限说明；IPA 审计新增反向门禁，最终包若重新声明这些权限将直接失败。
- [x] 发布候选：完整 RC、M1 smoke 与 46 路由视觉截图全部通过。
- [x] TestFlight：`1.0.0 (33)` 已完成发布门禁、签名导出、IPA 审计与上传；Delivery UUID `9ee4857c-f731-4243-9956-ccfd241c5d4c`，Apple 最终状态为 `VALID / APP_STORE_ELIGIBLE`，并已绑定 App Store 版本 `1.0.0`。

## 阶段 29 · 战斗底部资源行真机微调（2026-07-19）

- [x] P1：按 Owner 真机截图反馈，将金币统计、经验条和基地生命条作为同一资源行整体下移 `20px`；角色、宠物、主动技能和底部技能栏位置保持不变。
- [x] P1：M1 smoke 锁定三项的新纵向基线，并覆盖 `1920/2046/2337/2340/2348/2622` 高度，确保资源行始终留在底部 dock 与安全区内。
- [x] 视觉与发布验证：标准屏及高屏安全区截图人工复核通过；完整 RC、HUD 重叠检查与 46 路由视觉截图全部通过。

## 阶段 30 · 角色图鉴按钮文字光学校准（2026-07-21）

- [x] P1：针对未来荧黑字面重心在装甲按钮内显得偏低的问题，将角色图鉴卡片操作按钮、详情操作按钮和底部返回按钮的文字统一上提 `4px`；按钮框、卡片和列表位置不变。
- [x] P1：M1 smoke 锁定数学垂直居中与 `-4px` 光学偏移，防止后续字体或按钮重构重新产生上下不齐。
- [x] 视觉与发布验证：`1080×1920` 标准屏及 `1080×2340` 刘海安全区截图人工复核通过，无裁切、偏移或 UI 审计问题。

## 阶段 31 · 自动机枪全局 UI 模型重制（2026-07-21）

- [x] P1：按 Owner 反馈，以火焰喷射器、磁轨炮和散弹炮为风格基准，重新生成自动机枪 3D 图标；统一为黑钢、橙色能量圆环、机械角框和高密度硬表面细节，不再使用旧扁平小枪图。
- [x] P1：保持 `weapon_autocannon` ID 与生产路径不变，并同步生产、legacy compatibility、M1 sample 三份 UI 图标；地图、图鉴和出战配置自动更新，战斗持枪动画、handheld/turret、弹道、音效和数值不变。
- [x] P1：原始生成图、完整提示词、参考素材、整合方式与最终 SHA-256 已写入 `source_refs/generated` 和 `OUTSOURCER_ASSET_INDEX.json`。
- [x] 视觉验证：标准/长屏武器图鉴、地图 90px 武器入口和出战配置大图人工复核通过；按钮文字沿用统一 `-4px` 光学校正，无裁切或 UI 审计问题。
- [x] 发布验证：完整 Release Candidate、资源/数据/引用检查、Godot boot、M1 smoke 与 46 路由视觉截图全部通过。

## 阶段 32 · 锁定目标与多重射击瞄准优先级（2026-07-21）

- [x] P0：修复多重射击用敌群质心覆盖玩家锁定的问题；存在点名或长按手动瞄准时，至少一条主弹道必须精确指向优先目标，其余弹道才按固定夹角扩散。
- [x] P0：无锁定时继续使用敌群质心和原固定扇形；不修改伤害、射速、弹道数量、追踪强度或自动前线目标评分。
- [x] P0：M1 smoke 新增双弹道点名和双弹道手动瞄准回归，覆盖偶数弹道没有数学中心线、容易跨过目标的边界情况。
- [x] 发布验证：完整 Release Candidate、Godot battle boot、M1 smoke 与 46 路由视觉截图全部通过。

## 阶段 33 · 全局移动端字号 +2 与全界面排版收口（2026-07-22）

- [x] P0：项目默认字号、UiKit 缩放字号、场景显式字号和运行时动态字号统一增加 `2px`；未来荧黑字体、`FONT_SCALE=1.4`、内容层级和战斗逻辑保持不变。
- [x] P0：修复放大后章节 Boss 标签、技能效果摘要和收藏卡片二行说明裁切；锁定条目不再重复显示价格，升级提示、武器特性与装备摘要均完整可读。
- [x] P0：详情弹窗改用符合纹理化 UI 规范的深色纹理遮罩，并在打开期间隐藏底层列表与返回按钮，彻底消除文字透入；角色详情为标题装饰线预留间距，不再穿过职业/元素标签。
- [x] P1：视觉回归从 46 路扩展到 54 路，补齐护甲、芯片、宠物列表，武器/护甲/芯片/宠物详情和战斗卡牌详情；标准屏、高屏与刘海安全区均完成自动审计和人工总览复核。
- [x] 发布验证：完整 `python3 tools/check_release_candidate.py` 通过；字体授权、资源/数据/引用、平衡/经济/卡牌模拟、Godot boot、battle boot、M1 smoke 与 54 路视觉截图均无回归。

## 阶段 34 · TestFlight Build 34（2026-07-22）

- [x] 发布门禁：全量 Release Candidate、54 路界面截图、Godot 导入、iPhone-only PCK 审计及导出 PCK 的 battle boot / M1 smoke 全部通过。
- [x] 签名产物：Xcode Archive、App Store Distribution 导出及 IPA 同源审计通过；生成 `1.0.0 (34)`，IPA 为 `625,832,900` bytes（596.8 MiB），SHA-256 `bbaca11450e32cdf81d4a33b77743d7b6382f2dbed5d5d7857bd492c2ffde6a6`。
- [x] Apple 交付：上传成功，Delivery UUID `9c59677f-f5df-4e86-97e9-96b095ba17df`；最终状态为 `BUILD-STATUS: VALID`、`IMPORT-STATUS: VALID`、`APP_STORE_ELIGIBLE`、`IS-ON-APP-STORE-CONNECT: true`，非豁免加密为 `false`。

## 阶段 35 · App Store 前深度打磨与最终视觉收口（2026-07-23）

- [x] P0：高密度战斗信息自适应；8 个以内敌人完整显示，密集尸潮只保留锁定目标、Boss、最高压精英、当前目标和少量前线高危目标，16 敌测试场景只显示 7 组关键标签，手动锁定提示始终保留。
- [x] P0：收藏长标题与地图等级徽标适配全局大字号；“火焰喷射器 等级41 III”等完整显示，`Lv40/Lv20` 状态徽标不再裁切，标准屏/高屏/刘海安全区均通过运行时 UI 审计。
- [x] P1：iPhone 商店截图重新从当前运行版本捕获；角标改为紧凑实心胶囊，Boss 镜头清理无关怪物并分离血条/模型，iPhone 6.5/6.7 两套十张图片逐张复核完成。
- [x] P1：App Preview 重构为 22 秒真实运行演示，按“锁定射击 → 三选一 → Boss → 主动技”形成完整节奏；录制视口改为 `1080×2340`，成片 `886×1920 / SAR 1:1`，消除旧版非方形像素造成的横向压缩。
- [x] P1：视觉门禁扩展到 55 个真实路由，新增 16 敌高密度信息场景；两轮完整截图回归后零裁切、零安全区、零空白层报警。
- [x] P1：完成 iOS 包体无损审计和干净导出；新 PCK 为约 `569 MiB`。精确重复资源理论空间约 `37 MiB`，主要为动画帧和同义 VFX；临上线不做高风险别名或有损压缩。
- [x] Owner 工作已单独整理到 `design/app_store_owner_todo_2026_07_23.md`，仓库内可完成项不混入 Owner 清单。

## 阶段 36 · 上线前转化、战斗热路径与候选包收口（2026-07-23）

- [x] P0 性能：每个 physics frame 只获取一次敌人快照，并复用于锁定、信息密度、敌人机制、战报与减速场；光环范围比较改为平方距离，减少高密度战斗中的重复数组分配与开方。
- [x] P0 商店首屏：第一张 App Store 战斗图改为真实运行时的中高密度尸潮、清晰手动锁定、弹道和机制同屏；Preview 在前 `0.7s` 内展示锁定，首秒即可看懂核心操作。
- [x] P0 配装可读性：高等级战术摘要改用两行紧凑 `Lv` 记法，修复宠物等级被挤到第三行；“成型”显示相对战前增量，字号不缩小。
- [x] P0 Preview 质量：修复低运动画面导致 ABR 实际码率跌到约 `2.2 Mbps` 的问题；生成器改用 10 Mbps HRD CBR 并在产物阶段强制检查 `>=8 Mbps`，最终成片约 `10.1 Mbps / 27 MiB`。
- [x] P0 测试确定性：技能运行时和底部技能栏烟测不再读取开发机永久技能等级；使用隔离空技能存档并恢复现场，消除高等级真实存档造成的伪回归。
- [x] 最终验证：完整 31 项 Release Candidate 和 55 路视觉矩阵通过；干净导出 PCK 为 `5,770` 文件、`2,772` 导入资源、`568.5 MiB`，包内 battle boot 与 M1 smoke 均通过。

## 阶段 37 · 存档与前后台生命周期发布门禁（2026-07-23）

- [x] P0 存档可靠性：自动覆盖原子写入、备份轮换、主档损坏或缺失时恢复、旧版本迁移、递归默认值合并、手动备份/恢复，以及模拟写入失败时保留既有主档和备份。
- [x] P0 iOS 生命周期：应用暂停时立即持久化最新进度、取消残留触控/瞄准并暂停托管音频；恢复时统一恢复音频状态。
- [x] P0 发布门禁：`save_integrity_test.gd` 接入源代码 Release Candidate 与导出 PCK 双重检查；预期的损坏/写入失败夹具使用仅测试可用的日志降级，不隐藏正式运行时持久化错误。
- [x] 验证：完整 32 项 Release Candidate 与 55 路视觉矩阵通过，Godot 日志零非预期 error/warning。
- [ ] Owner 真机：按 `design/app_store_owner_todo_2026_07_23.md` 完成真实 iPhone 的强退重开、后台恢复、30 分钟性能/音频和首次玩家盲测；当前开发机没有连接物理 iPhone，自动门禁不能替代这部分证据。

## 阶段 38 · TestFlight Build 35（2026-07-23）

- [x] 发布门禁：完整 32 项 Release Candidate、55 路视觉截图、Godot 导入、iPhone-only PCK 审计全部通过。
- [x] 导出包验证：Build 35 PCK 为 `5,770` 文件、`2,772` 导入资源、`596,164,880` bytes（568.5 MiB），battle boot、存档/生命周期完整性和 M1 smoke 三重检查均通过；SHA-256 `ec36df1ed439875f5d9d8e5611fd5908b7576cdad1185fba6b8114315cee45f6`。
- [x] 签名产物：Xcode Archive、App Store Distribution 导出及 IPA 审计通过；`1.0.0 (35)` IPA 为 `625,836,434` bytes（596.8 MiB），SHA-256 `3155029c75a308f44b79ad6501dd98194b02f54632b5c9e059173eb297189f48`。
- [x] Apple 交付：Delivery UUID `a21524ab-a777-453c-af1d-a12d1a86bd68`；最终状态 `BUILD-STATUS: VALID`、`IMPORT-STATUS: VALID`、`APP_STORE_ELIGIBLE`、`IS-ON-APP-STORE-CONNECT: true`，非豁免加密为 `false`。

## 阶段 39 · TestFlight Build 36（2026-07-23）

- [x] 同源重打：以已提交的 Build 35 代码基线递增构建号，不引入新的玩法、数据或资源变更。
- [x] 发布门禁：完整 32 项 Release Candidate、55 路视觉截图、Godot 导入和 iPhone-only PCK 审计再次全部通过。
- [x] 导出包验证：Build 36 PCK 为 `5,770` 文件、`2,772` 导入资源、`596,164,880` bytes（568.5 MiB），battle boot、存档/生命周期完整性和 M1 smoke 均通过；SHA-256 `ec36df1ed439875f5d9d8e5611fd5908b7576cdad1185fba6b8114315cee45f6`。
- [x] 签名产物：`1.0.0 (36)` IPA 为 `625,836,432` bytes（596.8 MiB），SHA-256 `7093bc951b72bdad26cbb80e4b950b42c6aa7c3b7435a974bb6cf73a6e246343`。
- [x] Apple 交付：Delivery UUID `a90cad41-f8b8-4287-8d27-48b679e8d352`；最终状态 `BUILD-STATUS: VALID`、`IMPORT-STATUS: VALID`、`APP_STORE_ELIGIBLE`、`IS-ON-APP-STORE-CONNECT: true`，非豁免加密为 `false`。

## 阶段 40 · TestFlight 发布链路加固（2026-07-25）

- [x] Apple 最终状态门禁：上传成功后自动提取 Delivery UUID，并按 Apple 实际接口要求只用该 UUID 执行 `altool --build-status --wait`；强制验证 `BUILD-STATUS / IMPORT-STATUS / APP_STORE_ELIGIBLE / IS-ON-APP-STORE-CONNECT`，并交叉检查 Apple 回传的 UUID、Build 号和非豁免加密状态。
- [x] 不可复用构建号保护：Apple 接受上传后立即保留已消费的构建号和本地 IPA；即使后续状态查询或导入失败，也不会回滚到一个无法再次上传的版本号。
- [x] 可追溯发布记录：每次成功交付在 `build/ios/release/build_<N>/` 保存上传日志、Apple 状态日志和原子写入的 manifest，记录源码 commit/脏状态、版本、Delivery UUID、IPA/PCK 字节数和 SHA-256，不写入 API 私钥。
- [x] Desktop IPA 诚实校验：改用强制原子替换并逐字节比较；覆盖失败只报 warning，不再出现“旧文件未替换却显示复制成功”。
- [x] 回归门禁：发布候选新增 shell 语法检查和 release record 自测，总检查数由 32 增至 34。
- [x] 最终验证：修改后的完整 34 项 Release Candidate 与 55 路真实界面截图全部通过；用 Build 36 的现有 Delivery UUID 只读验证 Apple 实际接口，修正冗余参数后无 warning，结果仍为 `VALID / APP_STORE_ELIGIBLE / IS-ON-APP-STORE-CONNECT: true`。

## 阶段 41 · Boss 独立轮廓重制与首领战视觉收口（2026-07-25）

- [x] P0：审计 8 个 Boss 的实机轮廓；保留已有独特造型的风暴召唤者、瘟疫之母、虚空幽影，重制同模感明显的装甲巨像、炼狱巨口、冰霜典狱长、亡骸泰坦、终局霸主。
- [x] P0：五个重制 Boss 分别改为猩猩式攻城体、四足熔炉兽、囚笼行刑机、尸骨教堂和多臂三足指挥体；原 Boss ID、JSON 路径、机制、属性、弱点、碰撞半径、生成规则和关卡配置均不变。
- [x] P0：同步替换五组 prototype / portrait / icon、145 张动画帧和 5 段登场视频；生成脚本、提示词、主源图、manifest 和前后对比图保存在 `source_refs/generated/boss_model_redo_2026_07_25/`，并登记 `OUTSOURCER_ASSET_INDEX.json`。
- [x] P1：Boss 实战模型比例由 `0.44` 提至 `0.50`，只改变视觉辨识度，不改变碰撞、瞄准、移速、攻击线或平衡；营销镜头另有隔离的构图放大，不进入正式玩法。
- [x] P1：修复长波次提示与 Boss 全局血条重叠；Boss 血条提高文字对比度，状态缩写扩为“护盾 / 装甲 / 破甲 / 燃烧 / 冻结 / 中毒 / 感电”。
- [x] P1：模型头顶不再重复“首领·弱点”，统一只显示怪兽本名；弱点与生命百分比继续由顶部 Boss 血条单点承担，破甲状态不再覆盖本名。
- [x] P1：重新捕获 iPhone 6.5/6.7 英寸五张商店图并刷新 22 秒真实运行 App Preview；Boss 卖点文案改为“异形 Boss 压境，锁定弱点反击”。
- [x] 最终验证：资源包共 `7,847` 文件，数据 / `res://` 引用 / 压力 / 卡牌模拟、Godot boot、M1 smoke 全部通过；视觉门禁先以五个重制 Boss 的 60 路矩阵两次通过，再扩展到全部八个 Boss 的 63 路并通过；完整 Release Candidate 总门禁通过。

## 阶段 42 · Boss 攻城攻击身份与动画重制（2026-07-25）

- [x] P0：8 个 Boss 分别获得数据驱动的攻城攻击身份：装甲巨像近战裂地重击、炼狱巨口远程熔核三连、冰霜典狱长冰牢双重坠击、风暴召唤者持续雷链、瘟疫之母腐卵齐射、虚空幽影相位连斩、亡骸泰坦亡骸镇压、终局霸主四元素轮击。
- [x] P0：重做 Boss 到达基地后的预警、蓄力、弹道 / 连击、命中和基地反馈；远程、近战、持续压制与突进连击不再复用同一套泛用破口表现。
- [x] P0：连续攻击拆成多段视觉命中，但每轮只结算一次原始 `base_attack_damage`、一次屏障和一次基地受击，保持既有伤害、间隔与关卡平衡。
- [x] P1：新增金属基地破裂特效及透明生产资源，生成源图、提示词与 provenance 保存在 `source_refs/generated/boss_base_attack_redesign_2026_07_25/`，并登记 `OUTSOURCER_ASSET_INDEX.json`。
- [x] P1：数据校验新增攻击模式、元素、命中数、攻击线、颜色和 VFX 引用契约；M1 smoke 覆盖全部 8 个 Boss 的预警数、视觉命中数、单次伤害结算和攻击线差异。
- [x] P1：视觉回归从 63 路扩展到 71 路，新增全部 Boss 的确定性攻城峰值截图；逐个复核模型间距、基地遮挡、特效层级、颜色身份和安全区。
- [x] 最终验证：资源包共 `7,852` 文件，数据 / `res://` 引用 / 99 关压力 / 卡牌模拟、Godot boot、battle boot、存档完整性和 M1 smoke 全部通过；71 路视觉矩阵与完整 Release Candidate 总门禁通过。

## 阶段 43 · 风暴召唤者攻城雷电渲染重制（2026-07-25）

- [x] P0：移除风暴召唤者攻城攻击中的粗黄色 `Line2D` 和带可见矩形边界的旧 `vfx_enemy_skill_storm_chain` 命中贴图。
- [x] P0：生成并接入独立透明的白蓝紫主雷柱与基地电弧冠；主雷柱按 Boss 到基地的实时矢量缩放，五段攻击通过镜像、微旋转、宽度脉冲和交替色温形成连续但不机械重复的雷链。
- [x] P1：落点电弧冠固定对齐运行时 `BREACH_Y`，置于防御角色下层；保留预警圈、基地受击高光、逐段音效与终段震屏，不遮挡人物或底部 HUD。
- [x] P1：两张生成源图、提示词、透明化流程和生产输出登记到 `source_refs/generated/boss_storm_lightning_redesign_2026_07_25/` 与 `OUTSOURCER_ASSET_INDEX.json`；仅替换该 Boss 的 profile 攻城攻击，不影响玩家雷系技能。
- [x] 最终验证：首击 / 中段 / 终击三帧人工复核通过；资源包共 `7,861` 文件，数据 / 引用 / 压力 / 卡牌模拟、Godot boot、battle boot、存档完整性和 M1 smoke 全部通过；71 路视觉矩阵与完整 Release Candidate 总门禁通过。

## 阶段 44 · 全战斗顶级特效重制与裁切收口（2026-07-26）

- [x] P0：以已验收的风暴雷柱为品质基准，统一重制 8 个 Boss 基础攻击、8 个 Boss 机制技能、4 名角色主动技、8 种武器弹体及枪口反馈、元素受击 / 暴击 / 装甲 / 免疫 / 弱点反馈和 5 类死亡终结表现。
- [x] P0：Boss 攻击继续保留近战、远程、连续攻击和重击身份；新表现只升级视觉层级、色彩语言和命中反馈，不改变伤害、射速、技能冷却、碰撞、瞄准或关卡平衡。
- [x] P0：审计全部 `79` 组战斗 VFX 序列，对 `32` 组存在边缘风险的旧卡牌技能、普通僵尸技能和主动技序列做整组等比内缩；同一序列共用一个缩放值，避免逐帧跳动，并保留 ID、路径、帧数、FPS 和时序。
- [x] P0：新增发布级安全边门禁，检查 `701` 张实际引用的非空帧，要求四边至少保留 `7.5%` 透明安全区；允许有意设计的空白起止帧，忽略不进入运行时 manifest 的尾帧缓存。
- [x] P1：完成 `83` 张专项实机截图复核，覆盖 4 主动技、8 Boss 技能、8 Boss 攻击、8 武器、9 受击、5 死亡、16 卡牌技能、19 僵尸技能和 6 张 `1080×2340` 长屏代表场景；未发现残余裁切、矩形底、HUD 遮挡或安全区越界。
- [x] P1：生成源图、完整提示词、整合 manifest、安全边修复报告与综合联系表已保存在 `source_refs/generated/premium_combat_vfx_2026_07_26/`，并登记 `OUTSOURCER_ASSET_INDEX.json`；iOS 导出排除规则同步到 `237` 条，`65.9 MiB` 创作源文件与 `216` 张无用尾帧不进入安装包。
- [x] 最终验证：资源包共 `8,404` 文件；AGENTS 要求的资源 / 数据 / 引用 / 99 关压力 / 卡牌模拟 / Godot boot / M1 smoke 全部通过，安全边门禁、存档完整性、战斗启动、HUD 重叠、长屏、App Store 素材、`71` 路全界面视觉矩阵与完整 Release Candidate 总门禁全部通过。

## 阶段 45 · TestFlight Build 37（2026-07-26）

- [x] 源码基线：顶级 Boss / 全战斗 VFX 候选以提交 `74231425` 入库并推送到 `origin/main`；发布 manifest 确认构建开始前工作树无已跟踪改动。
- [x] 发布门禁：完整 Release Candidate、`71` 路界面截图、Godot 导入、iPhone-only PCK 审计全部通过。
- [x] 导出包验证：Build 37 PCK 包含 `6,472` 个文件、`3,116` 个导入资源，大小 `581,256,680` bytes（554.3 MiB）；battle boot、存档完整性和 M1 smoke 均通过，SHA-256 `4e390d2400b3b6b99e879ade9825955209fcb5ce9fe5bd45bc172cc3a50bdb6c`。
- [x] 签名产物：Xcode Archive、App Store Distribution 导出及 IPA 同源审计通过；`1.0.0 (37)` IPA 为 `610,745,333` bytes（582.5 MiB），SHA-256 `8359580d26c888996d0f689d8c87621b51d4b0771c3ffb18fc9c068684cd20dd`。
- [x] Apple 交付：Delivery UUID `d1839f5a-882c-494e-8485-7419249d27ec`；最终状态为 `BUILD-STATUS: VALID`、`IMPORT-STATUS: VALID`、`APP_STORE_ELIGIBLE`、`IS-ON-APP-STORE-CONNECT: true`，非豁免加密为 `false`。
- [x] 本地产物：已验证 IPA 与发布 manifest 保存在 `build/ios/`；macOS 阻止替换 Desktop 上的旧 IPA 副本，但不影响上传、Apple 处理或 App Store Connect 可用性。

## 阶段 46 · 全战斗特效语义验收与运行时复验（2026-07-26）

- [x] P0：新增 `combat_vfx_semantic_contracts.json` 与永久发布门禁；不再只检查 PNG 是否存在和是否留边，同时检查发射源、移动方向、落点、区域中心、序列完整性、跨机制视觉区分和弹体飞行方向。
- [x] P0：修复跑尸突进、冲锋、跃击、虚空相位和毒液喷吐共 5 组方向契约；运行时按真实移动 / 目标矢量旋转，不再把横向素材原样贴到向下进攻的僵尸身上。
- [x] P0：拒绝并替换 6 组旧图集硬裁边序列和 2 张低质几何弹体；保留全部 ID、路径、帧数、FPS、数据引用和玩法时序。
- [x] P0：新增毒系动作差异门禁；腐蚀爆裂、喷吐毒矢、持续毒区和再生光柱必须保持不同轮廓，不能用同一个绿色爆炸冒充四种机制。
- [x] P1：真实运行截图发现 Godot 仍命中旧导入缓存后，强制重导入并复拍；最终专项矩阵覆盖 11 张 `1080×1920` 与 1 张 `1080×2348`，方向、起点、落点、裁边、HUD 和高屏安全区人工复核通过。
- [x] P1：全量自动验收覆盖 83 组序列 / 710 个非空帧、11 张方向弹体、8 个 Boss 攻城 profile、4 个角色主动技、16 个卡牌施放和 96 组角色武器攻击动画。
- [x] 最终验证：完整 36 项 Release Candidate 通过；资源 / 数据 / 349 个 `res://` 引用 / 99 关压力 / 卡牌模拟 / Godot boot / battle boot / 存档完整性 / M1 smoke / 71 路真实界面截图均通过。

## 阶段 47 · 僵尸持续异常状态顶级打磨（2026-07-26）

- [x] P0：燃烧、冻结、冰川、中毒、感电改为五套独立、数据驱动的持续表现；状态进入、维持、刷新、伤害跳字与退出均有明确生命周期，多个状态可并存，不再通过互斥分支或一张泛用换色光环表达。
- [x] P0：建立手机端空间语言：火焰附着上身与肩侧、冰霜压在脚下并保留身体冷色反馈、毒雾聚集腰腿、感电沿轮廓上窜；普通僵尸与 Boss 分别使用独立锚点和比例，避免遮脸、遮本名或淹没模型。
- [x] P0：叠层状态加入总亮度约束和错相位播放；二层、三层及以上自动降权，状态刷新延长既有循环而不重新闪烁，持续伤害只做短促能量脉冲，不改变任何伤害、持续时间、减速、控制或关卡平衡。
- [x] P1：战场密度按 `24 / 48` 敌阈值分为完整、精简、极简表现；Boss、手动锁定和当前高优先目标始终保留完整层级，36 敌专项场景中普通单位只保留可读的接触/状态线索。
- [x] P1：新增永久 `status_vfx` 数据契约和专项门禁，覆盖 5 个状态、62 帧有效序列、颜色/比例/透明度、资源引用、独立控制器、旧泛用光环移除及高密度 LOD；M1 smoke 覆盖四状态并存、消退、极简降级、优先目标恢复和缓存释放。
- [x] 视觉验收：四张真实运行证据覆盖单状态、Boss 多状态叠加、36 敌高密度和高屏场景；火、冰、毒、电辨识明确，模型与 HUD 可读，无裁切、矩形底、过曝或状态残留。高屏实拍为桌面可用的 `1080×2046`，永久静态门禁继续覆盖 `2337 / 2340 / 2348 / 2622` 高度。
- [x] 最终验证：新增状态专项门禁后完整 37 项 Release Candidate 通过；资源包共 `8,407` 文件，数据 / `res://` 引用 / 99 关压力 / 卡牌模拟 / Godot boot / battle boot / 存档完整性 / M1 smoke / 71 路真实界面截图全部通过。

## 阶段 48 · 普通僵尸模型顶级重制与全阵容辨识收口（2026-07-26）

- [x] P0：完整审计 20 个普通僵尸在手机实际比例、纯轮廓和混编密度下的辨识度；保留 12 个已成立原型，重做 `bomber / spitter / juggernaut / necromancer / charger / regenerator / splitter / warden` 共 8 个高优先级家族。
- [x] P0：每个重做原型都直接表达机制：爆桶核心、低伏酸囊、工业攻城体、竖向尸笼、楔形冲角、非对称再生器官、三瓣分裂体、十字投射器；不再依靠换色、武器小挂件或头顶文字区分。
- [x] P0：保持全部 ID、JSON 数据、关卡引用、碰撞、速度、血量、伤害、弱点及机制不变；按原路径替换 prototype / portrait / icon，并补齐完整动作族。初次模型重制为 `idle 4 / walk 6 / attack 4 / special 6 / hurt 3 / death 6`、共 `232` 张；后续全阵容攻击打磨将这 8 类的 attack 升至 8 帧，当前共 `264` 张。
- [x] P1：生成原图、透明 master、旧版备份、完整提示词、派生 manifest、前后对比表、20 怪联系表及动作峰值表保存在 `source_refs/generated/zombie_model_redo_2026_07_26/`，并登记 `OUTSOURCER_ASSET_INDEX.json`。
- [x] P1：新增永久模型门禁，检查 8 组主图透明角、24 张界面资源尺寸、当前 264 帧动作完整性与透明安全边、逐帧变化、机制比例范围及 20 怪两两轮廓重叠上限；M1 smoke 验证 Godot 实际导入全部动作且没有退回 prototype。
- [x] 视觉验收：真实运行矩阵覆盖 8 个重做模型、20 怪全阵容、24 怪高密度及 `1080×2046` 高屏安全区；第二轮修正验收排布边距后，没有模型裁切、贴边、矩形底或混编辨识问题。4 条模型场景已加入永久全界面截图回归。
- [x] 最终验证：完整 `38` 项 Release Candidate 通过；资源包共 `8,559` 文件，数据 / `353` 个 `res://` 引用 / 99 关压力 / 卡牌模拟 / Godot boot / battle boot / 存档完整性 / M1 smoke 全部通过；全界面视觉矩阵由 `71` 路扩展到 `75` 路并全部通过。

## 阶段 49 · 四角色满配 DPS 收敛与电弧连锁解限（2026-07-26）

- [x] P0：冰霜少女与电弧少女的角色型主动技继承部分永久武器等级伤害成长；同时提高角色等级、成长档位与专属技能等级的主动技收益，避免满级主武器把角色招牌技能稀释成边缘伤害。
- [x] P0：雷暴领域提升至满配 `16` 个可选目标、`26` 次打击；普通电弧连锁移除代码中的 `5` 目标硬上限，完整结算局内技能、武器、角色和宠物连锁，并通过后续目标递减控制尸潮收益。
- [x] P0：电弧超过 `5` 层的连锁成长按每层 `+2%` 转成主目标伤害，保证单 Boss 场景也能兑现连锁投资；修复电弧宠物的 `chain_bonus` 已计算却未进入实际连锁数量的问题。
- [x] P0：燃烧刷新改为向当前来源强度收敛，弱命中可逐步拉低历史峰值；状态结束时同时清空缓存 DPS，不再由一次最高暴击永久续期。火焰少年常驻面板同步收敛，保留范围爆发上限但不再明显压过其他角色。
- [x] P1：新增可复现的 `tools/audit_character_endgame_dps.py`，以角色 40 / 武器 50 / 芯片与护甲 35 / 宠物 30 / 专属技 5 / 全兼容局内技能满级、标准大体型中立 Boss 三条弹道命中为统一口径，自动枚举最佳芯片与宠物。
- [x] 数值结果：先锋 `119,776`、火焰 `134,479`、冰霜 `128,002`、电弧 `137,219` DPS，最高与最低差 `14.6%`；五弹道全重合上限分别为 `182,154 / 215,845 / 197,906 / 200,506`。
- [x] 回归覆盖：数据校验约束主动技武器继承比例、连锁溢出与递减范围；M1 smoke 覆盖电弧解限、宠物连锁、单体补偿、主动技满级武器成长，以及燃烧强度衰减与到期清理。
- [x] 最终验证：资源包 `9,222` 文件、数据、`353` 个 `res://` 引用、99 关压力、卡牌模拟、Godot boot、M1 smoke 和独立满配 DPS 审计全部通过；本次没有 UI / 素材 / 布局变更。

## 阶段 50 · 后期对抗感与 Boss 展示窗口重构（2026-07-26）

- [x] P0：确认后期 Boss 存在被毕业克制配装在核心机制触发前击杀的风险；旧 99 关 Apex 约 `334 万` HP，对标准三弹道满配物理克制输出仅约 `16–20 秒` 生存时间。
- [x] P0：后期难度改为“耐久 + 尸潮数量”，`late_wave_damage_ramp.max_mult / final_mult` 固定为 `1.0`；普通怪、Boss 的压线伤害、技能伤害和攻城伤害不再获得 50+ 关卡倍率。
- [x] P0：把毕业物理方案升级为真实运行时审计：自动机枪 / 磁轨炮 / 散弹炮逐一实测，完整计入满级分裂、穿透、五路多重、追踪、暴击、弹射、齐射、蓄力，及先锋主动技直伤与强化覆盖；结果写入固定 benchmark，并以 6% 漂移门禁回归。
- [x] P0：据真实满技能输出重标 `boss_survival_hp_ramp`；第 50–98 关由 `1.0x` 平滑提高至 `56.0x`，第 99 关为 `60.48x`，只乘 Boss HP。最快合法毕业克制方案下，Apex 90/95/99 关 TTK 约 `57 / 90 / 117 秒`，对应约 `8 / 15 / 21` 次核心技能窗口。
- [x] P0：新增 `late_wave_count_level_ramp`；第 55 关后只提高第 3 波及以后普通 / 支援怪数量，第 90–98 关为 `1.25x`，第 99 关为 `1.35x`。99 关运行时普通怪总量约由 `424` 提高到 `550`，Boss 不会被复制。
- [x] P1：晚波普通怪 HP 曲线第 98 / 99 关保持 `2.05x / 2.296x`；99 关普通怪总耐久约 `2352 万`、Apex 约 `2.145 亿`。真实运行时 benchmark 下，自动机枪 / 磁轨炮 / 散弹炮毕业方案伤害时间约 `231 / 200 / 117 秒`，全部低于 `260 秒`。
- [x] P1：运行时、推荐战力、经验预算、关卡压力、平衡模拟、重建工具、数据 schema 与 smoke 回归使用同一套数量 / HP / 无伤害放大口径；99 关推荐战力约 `757`。
- [x] 最终验证：资源包 `9,222` 文件、数据、`355` 个 `res://` 引用、99 关压力、卡牌模拟、平衡画像、战役模拟、终局矩阵、四角色中立 Boss DPS、Godot boot 与 M1 smoke 全部通过；真实弹道 benchmark 复跑通过 6% 漂移门禁。

## 阶段 51 · 宠物功能审计与医疗无人机三层修复（2026-07-26）

- [x] P0：复核六只宠物的满级功能；炮塔无人机保留物理输出，火焰小鬼保留火系持续伤害，冰霜精灵保留减速与基地生命，电弧球保留连锁，拾荒者保留经济收益。医疗无人机原先每波只有 `8–17` 点固定修复，随基地生命成长后会快速失效，确认为唯一明显缺口。
- [x] P0：医疗无人机改为数据驱动三层修复：每波固定值 + 最大生命百分比的“波次整备”、每 `18` 秒一次的“持续维修”，以及基地生命不高于 `35%` 时、`45` 秒冷却的“应急救援”；所有修复按最大生命计算并严格封顶。
- [x] P0：满级数值为每波 `17 + 7.9%`、持续维修 `1.725% / 18 秒`、应急救援 `12.35%`；原有 `+15.7%` 基地生命和 `10.8%` 防线减伤继续保留。强化生存功能但不增加宠物攻击，也不抬高敌人伤害。
- [x] P1：新增宠物到基地的绿色维修束、落点修复序列、扩散环、回血数字、血条脉冲与医疗宠攻击帧反馈；普通维修和应急救援使用不同视觉权重，且沿用已通过安全边与语义验收的生产 VFX。
- [x] P1：收藏详情完整展示三层修复的当前值、满级值、触发阈值和冷却；战力估算纳入三层修复成长，数据 schema、装备设计文档和数据范围校验同步更新。
- [x] 回归覆盖：M1 smoke 在第 99 关生命池上分别验证周期修复、低血救援、波次整备、冷却和生命上限；截图工具新增确定性医疗修复场景，永久长屏宠物详情路由改为信息量最大的满级医疗无人机。
- [x] 最终验证：资源包 `9,222` 文件、数据、`355` 个 `res://` 引用、99 关压力、卡牌模拟、Godot boot 与 M1 smoke 全部通过；两张专项运行截图人工复核无裁切或 HUD 遮挡，`79` 路完整视觉截图矩阵通过。

## 阶段 52 · 全宠物专属技能与收藏星价平滑（2026-07-27）

- [x] P0：六只宠物统一使用数据驱动 `pet_skill`。炮塔无人机新增“过热爆发”，火焰小鬼新增“熔火爆发”，冰霜精灵新增“寒霜领域”，电弧球新增“电弧过载”，拾荒者新增“战场回收”；医疗无人机继续使用已验收的“防线维生”三层修复。
- [x] P0：宠物技能全部进入真实战斗逻辑并随宠物等级成长；范围技优先当前锁定/首要威胁，电弧过载由 3 目标成长到满级 5 目标且没有额外运行时硬上限，拾荒者每波直接结算随等级成长的等效击杀金币。
- [x] P1：宠物详情、列表摘要、升级预览和战力估算读取同一份技能数据；满级技能当前为炮塔 `4.2 秒 / 1.90x 射速 / 1.22x 伤害`、火宠 `175` 半径、冰宠 `328` 半径、电宠 `5` 目标、拾荒者每波约 `5.2` 只击杀收益。
- [x] P0：角色、武器、护甲、芯片、宠物的单件星价统一压到 `8–16`；同品类最高价不超过最低付费价 2 倍。全部付费收藏总价为 `318` 星，普通 99 关共 `297` 星，再取得 `21` 颗挑战星即可收齐。
- [x] P1：重写数据、平衡和经济门禁，永久拒绝上百星单件价格、超过 2 倍的品类曲线、异常总价及武器双价格字段不一致；设计经济、进度、装备、平衡、商店和 schema 文档同步到现行口径。
- [x] 回归覆盖：M1 smoke 逐项验证炮塔持续强化、火/冰范围受击、冰控强度、电弧 5 目标成长、拾荒金币结算和 `318 / 16 / 21` 星经济；截图工具新增 5 个宠物技能确定性场景和 5 个非医疗宠物满级详情。
- [x] 视觉验收：火焰范围、寒霜领域、电弧连锁和全部满级宠物详情经过两轮真实 Godot 截图复核；电弧连线补入高亮能量主干，完整视觉矩阵由 `79` 路扩展到 `89` 路并通过。

## 阶段 53 · TestFlight Build 38（2026-07-27）

- [x] 源码基线：角色 / 僵尸动作、全战斗特效、后期对抗、宠物技能与收藏价格候选以提交 `ae47d333` 入库并推送到 `origin/main`；发布 manifest 确认构建开始前无已跟踪工作树改动。
- [x] 发布门禁：完整 Release Candidate、`89` 路界面截图、Godot 导入、iPhone-only PCK 审计全部通过。
- [x] 导出包验证：Build 38 PCK 包含 `6,923` 个文件、`3,340` 个导入资源，大小 `603,709,648` bytes（575.7 MiB）；battle boot、存档完整性和 M1 smoke 均通过，SHA-256 `37dfac7f33c9e7fd02185cb7fba66167a153ba20d60fc6a31a67487e59f9bed0`。
- [x] 签名产物：Xcode Archive、App Store Distribution 导出及 IPA 同源审计通过；`1.0.0 (38)` IPA 为 `633,091,255` bytes（603.8 MiB），SHA-256 `4043afa9e93a96a8976c5ce3b76d8dbc1fb5b72626d8632aa05ba33326f1f96a`。
- [x] Apple 交付：Delivery UUID `14646ccd-e6e3-456f-9bd2-7f27b233e7f6`；最终状态为 `BUILD-STATUS: VALID`、`IMPORT-STATUS: VALID`、`APP_STORE_ELIGIBLE`、`IS-ON-APP-STORE-CONNECT: true`，非豁免加密为 `false`。
- [x] 本地产物：已验证 IPA 与发布 manifest 保存在 `build/ios/`；macOS 阻止替换 Desktop 上的旧 IPA 副本，但不影响上传、Apple 处理或 App Store Connect 可用性。

## 阶段 54 · 发布前素材 / 交互 / 体验收口（2026-07-27）

- [x] P0：三选一卡片出现时立即清掉正在显示和排队中的波次 / 教学横幅，避免半透明弹窗后方继续出现高优先级文字。
- [x] P0：战力低于推荐值 `65%` 时，在出战配置中同时显示“严重欠战力”状态和明确按钮警告；首次点击只进入 `2.6` 秒确认窗口，第二次点击才真正出战，不阻止熟练玩家自选高压打法。
- [x] P0：收藏详情的满级状态统一显示“已满级 / 成长已完成”，底部升级按钮也不再显示无意义金币价格；新增 UI 与数据回归。
- [x] P1：地图增加当前推进关卡标记、章节状态与“继续推进 / 回顾战区”动作层级；战力状态优先于克制提示，减少玩家在长列表和配置页里的判断成本。
- [x] P1：结算页改为当前关卡环境背景，新增英雄战果卡、胜负关键数字、分段入场和小型得星粒子；截图回归发现首版粒子纹理尺寸失控后，已缩为 8 枚 `20–32 px` 小粒子并复拍通过。
- [x] P1：Boss 登场、角色招牌技、越线警告和胜负结算加入运行时 BGM 动态让位；不替换未在监听环境下重新母带的音频文件，静态音频门禁同步覆盖。
- [x] P1：完成发布包素材审计；确认约 `406 MiB` source refs、`38 MiB` 视频、`26 MiB` 联系表、`14 MiB` flow 和已登记尾帧不会进入 iPhone 包。最后关头不对 `446 MiB` 动画和 `192 MiB` VFX 运行序列做高风险有损重编码。
- [x] 视觉验收：标准屏 / 长屏专项复核地图、严重欠战力配置、满级医疗无人机详情、三选一弹窗、胜利入场中间帧、胜负稳定结算；随后完整 `89` 路真实 Godot 截图矩阵通过。
- [x] 最终验证：资源包 `9,223` 文件、字体授权、数据、`355` 个 `res://` 引用、99 关压力、终局平衡、经济、色板 / 对比度、全动作 / VFX / 音频、安全区、Godot boot、battle boot、存档完整性、M1 smoke 和完整 Release Candidate 全部通过。
- [ ] Owner：至少一台真实 iPhone 完成最终耳机 / 外放混音、触感、热量、峰值内存和整局触控签字；这仍是仓库自动化无法替代的上架前最后一步。

## 阶段 55 · 首次操作与长线导航连续性（2026-07-27）

- [x] P0：首关教学不再把“双击锁定”误写成单击；战场提示与设置说明统一为“自动开火 / 按住拖动手动瞄准 / 双击僵尸锁定 / 双击空地解除”。
- [x] P0：战区地图根据首个已解锁未通关关卡自动定位当前章节；进入当前章节后自动定位当前关卡，返回外层地图时恢复刚离开的章节卡。
- [x] P0：收藏列表升级、购买、装备或刷新后恢复原滚动位置；刷新时旧行先移出节点命名空间再释放，避免新行被 Godot 改成临时节点名而破坏物品 ID。
- [x] P1：App Store Owner 待办同步到最新已上传 Build 38，并明确当前源码仍领先 TestFlight；素材状态文档同步当前运行时动画、VFX、App Preview 与音频母带边界。
- [x] 回归覆盖：M1 smoke 验证教学文案、后期章节/关卡可见性、返回定位、收藏滚动与稳定节点 ID；视觉矩阵新增第九战区和 089 当前关卡两条长屏路线，由 `89` 路扩展为 `91` 路并通过。
- [x] 专项截图：`tmp/final_experience_round_2026_07_27/` 保存首关教学、第九战区定位和 089 当前关卡定位三张真实 Godot 截图，人工复核无裁切、遮挡或层级问题。
- [x] 最终验证：低战力二次确认拆为确定性独立回归，避免本机存档强弱影响挑战入口测试；完整 Release Candidate 通过，包括资源包 `9,223` 文件、字体授权、数据、`356` 个 `res://` 引用、平衡 / 经济 / VFX / 音频 / 长屏 HUD、Godot / battle boot、存档完整性、M1 smoke 和 `91` 路真实界面截图。

## 阶段 56 · 付费主题 / 终焉军械总方案与第一阶段冻结（2026-07-27）

- [x] Owner 决策：App 继续免费；不增加广告、订阅、体力、随机付费或付费货币。
- [x] Owner 最终决策：保留炼狱赤焰、极地极光、霓虹雷暴 3 套全局主题，参考价均为 `US$1.99`；不再规划第四套。
- [x] Owner 最终决策：3 套终焉军械分别对应火、冰、雷；完整包参考价 `US$6.99` 并包含对应主题，主题已购用户显示约 `US$4.99` 军械升级商品。
- [x] Owner 决策：终焉装备从 1 级开始，使用普通金币升级；满级整套实际总输出必须高于免费同属性最强满配 50%，实现目标冻结为 `1.52x~1.58x`、中心 `1.55x`。
- [x] 详细方案：`design/21_premium_themes_and_apocalypse_arsenal_plan.md` 已按最终目录记录商品 / entitlement、三主题、三军械、升级、数值、素材、StoreKit、UI、App Store、QA、风险和跨 session 接手规则。
- [x] 第一阶段锁定霓虹雷暴 + 终焉·雷霆军械四件套，并以逐套生产方式控制范围。
- [x] 第一阶段盘点：`design/22_neon_tempest_thunder_phase1_inventory.md` 已记录现有雷电数据 / VFX / DPS 基线、模块化角色与武器动画方案、约 95 个主题硬编码触点、基地叠层方案、StoreKit 三商品、双语缺口、包体风险和 Phase 1A~1F 工作分解。
- [x] Phase 1A：制作霓虹综合色板、四角色服装、代表武器涂装、菜单 / 基地 / HUD / Logo、三版天罚电弧炮轮廓和雷霆攻击分镜；完成四个角色 × 代表武器的原型、真实战场合成图和联系表验收，不覆盖运行时默认素材。
- [x] Phase 1A-1 首批候选：四角色服装、三版天罚电弧炮、六段雷霆 VFX、菜单 / 收藏 / 战斗 / 结算视觉系统和修正后的综合战场图已保存到 `assets/production/source_refs/generated/premium_neon_tempest_phase1a_2026_07_27/`；完整提示词和拒绝原因已登记。
- [x] Phase 1A-1 自检：拒绝含 7 只僵尸且电弧过亮的首稿；最终战场图为 1 名角色 / 6 只僵尸，主目标最亮、次级连锁减细，攻击由基地向上，所有候选无文字乱码和头部裁切。
- [x] Owner：确认四角色服装、UI / 基地和六段攻击特效的整体渲染方向满意。
- [x] Owner：以继续执行确认中案三线圈重型旋转雷暴炮；Phase 1A-2 运行时版缩短枪身约 20%，保留三线圈识别点。
- [x] Phase 1A-2：护甲 / 芯片 / 宠物、三把免费手持武器霓虹涂装、四个代表模块化握枪组合、四环境基地覆盖层和四窄屏手机尺度证明已完成；误画独立特斯拉装置和漏冰川基地的首稿均已拒绝并修正。文件与完整提示词保存在 `assets/production/source_refs/generated/premium_neon_tempest_phase1a2_2026_07_27/`。
- [x] Phase 1B-1：新增 ThemeManager、`themes.json`、Save v2 主题 / 已验证权益字段和缺失权益安全回退；`UiKit` 语义路由覆盖五个代表页面。六个原生宽高族生成 72 张精确尺寸霓虹按钮，运行时禁止 `STRETCH_SCALE`；战斗角色 / 结算肖像接入避开头脸的动态虹彩，减弱特效时静止降亮。仍只用 Debug fixture，不伪造 StoreKit 购买。
- [x] Phase 1B-2：补齐菜单 / 地图 / 收藏 / 配装 / 设置 / 战斗 / 结算的面板、标题、HUD 和基地覆盖层；免费武器战斗改用融合持枪动作承载主题材质，Debug / TestFlight 预览与本地商品闭环均已接入，真实 Apple 交易仍未开始。
  - [x] Phase 1B-2a：四角色独立霓虹肖像、44 张透明备用 idle / attack / hurt 帧、枪口与弹体霓虹材质、4 帧渲染式开火电弧翼、四主动技能霓虹叠层和设置页默认 / 霓虹可逆切换均已接入；2026-08-01 已撤销会造成悬空枪的独立武器前景层。
  - [x] 删除被 Owner 拒绝的程序网状开火线；新电弧翼位于人物后方、中心留空、随射击方向旋转，并支持“减弱特效”降级。
  - [x] 霓虹专项矩阵固定覆盖 43 路：菜单 / 设置 / 角色列表、四角色配装、完整 `4 × 8` 免费武器开枪矩阵和四角色主动技能。
  - [x] Phase 1B-2b：结构性面板、基地和 HUD 主题化已收口；完整 `4 × 8` 运行时开枪矩阵作为永久回归，并在 2026-08-01 增加融合持枪硬门禁。
- [x] Phase 1C：接入雷霆军械四件套、金币升级、五阶段表现、2 / 4 件套和双基线数值验收；免费构筑保持不变。
- [ ] Phase 1D：本地无扣费 PurchaseManager、中英文商品页、购买 / 恢复 / 重置安全回退、标准 / 长屏布局已完成；Apple StoreKit Configuration、verified transaction、Sandbox / TestFlight、退款回调和 App Store Connect IAP 仍待后续接入验收。
- [x] Owner：首批整体渲染方向通过；下一工作包限定为 Phase 1A-2 运行时尺寸和模块化证明。

## 阶段 57 · TestFlight Build 39 霓虹主题验收包（2026-07-27）

- [x] 验收包约束：Build 39 仅用于 TestFlight 视觉验收；iOS 导出时使用专用 `neon_tempest_preview` feature 直接启用霓虹主题，不授予或持久化购买权益。上传完成后本地发布预设已恢复为普通 `release`，禁止把 Build 39 直接选作 App Review 构建。
- [x] 发布门禁：资源包 `9,417` 文件、字体授权、99 关数据、`360` 个 `res://` 引用、平衡 / 经济 / 动作 / VFX / 音频 / 长屏、Godot / battle boot、Save v2、M1 smoke 和 `91` 路真实界面截图全部通过。
- [x] 导出包：Build 39 PCK 为 `607,877,860` bytes，包含 `7,071` 个文件和 `3,412` 个导入资源，SHA-256 `170cd123b0631cb08aad3140e92f70a8dad1fdadcf7525d28e5014df8d323b02`；导出包 battle boot、存档完整性与 M1 smoke 通过。
- [x] 签名产物：`1.0.0 (39)` IPA 为 `637,222,351` bytes（607.7 MiB），SHA-256 `2c338669b6c3a092451365201d1511fbe2346246850a5ede4d73ca41c9b2ed4c`。
- [x] Apple 交付：Delivery UUID `ec1400d1-68ec-43cc-9f64-42049f5156ac`；最终状态 `VALID / APP_STORE_ELIGIBLE / IS-ON-APP-STORE-CONNECT`，非豁免加密为 `false`。
- [x] 发布记录：`build/ios/release/build_39/release_manifest.json` 已记录源码 commit `49af255883abf1efcb4f566b0e8fe0f8f890cda8` 及工作树有改动；本地产物有效，Desktop 旧 IPA 因 macOS 权限未替换，不影响 TestFlight。

## 阶段 58 · 简体中文 / English 完整运行时（2026-07-27）

- [x] 新增 `LocalizationManager` 与动态 Translation，支持精确文案、运行时 `%` 格式模板和可复用术语；设置页可以即时切换并持久化语言。
- [x] 全新安装按系统语言选择中文 / English；没有语言字段的旧设置安全迁移为中文。
- [x] 补齐 88 个稳定内容 ID 的英文名称，以及 UI、战斗、技能、99 关目标、十战区剧情、挑战规则和 Boss 机制英文文案。
- [x] 修复英文特有版式：章节按单词换行、地图剧情摘要、空装备摘要、收藏标签、强化卡标题 / 推荐徽章 / 说明、设置帮助和结算长标题。
- [x] 新增静态覆盖 / 占位符 / 中文残留门禁、运行时双语 smoke、14 路英文截图矩阵，并纳入 Release Candidate。
- [ ] Owner / App Store 工作：准备英文商店名称、副标题、关键词、描述、宣传文案与截图标题；未来 StoreKit 商品需在 App Store Connect 单独配置中英文元数据。

## 阶段 59 · 英文首页品牌与 Skill Codex 排版收口（2026-07-27）

- [x] P0：为英文模式制作独立的 `ZOMBIE FIRE` 首页标题资产，保持中文版标题的裂纹钢、橙蓝边光与厚重立体质感。
- [x] P0：首页根据当前语言自动切换中英文标题资产，中文模式保持原标题不变。
- [x] P1：Skill Codex 英文卡片改为技能名、等级固定双列，避免长标题推动等级并造成纵向错位。
- [x] P1：缩短英文类型标签并补齐 `Projectile` 术语，消除重复标签与拥挤。
- [x] P1：保存生成提示词、透明化源图与资产索引记录，确保素材可追溯、可复现。

## 阶段 60 · TestFlight Build 40 双语联合验收包（2026-07-28）

- [x] 验收包约束：Build 40 继续使用 TestFlight 专用 `neon_tempest_preview` feature，联合验收霓虹主题、完整中英文运行时、英文 `ZOMBIE FIRE` 标题和 Skill Codex 排版；不授予购买权益，禁止直接选作 App Review 构建。
- [x] 发布门禁首次发现配装页宠物摘要的双语格式回归并在构建号递增前拦截；修复后玩法门禁、本地化、发布字符串与 Godot 启动专项复测通过。
- [x] 完整发布门禁：资源包 `9,424` 文件、字体授权、99 关数据、`366` 个 `res://` 引用、平衡 / 经济 / 动作 / VFX / 音频 / 长屏、Godot / battle boot、Save v2、双语 smoke、M1 smoke 和 `105` 路真实界面截图全部通过。
- [x] 导出包：Build 40 PCK 为 `609,183,408` bytes，包含 `7,081` 个文件和 `3,413` 个导入资源，SHA-256 `60193a5a36aaf0d412c3108804a020e6cea6c8db7e3b8131bfdc3c44ad1365cb`；导出包 battle boot、存档完整性与 M1 smoke 通过，独立探针确认 `neon_tempest_preview=true` 且活动主题为 `neon_tempest`。
- [x] 签名产物：`1.0.0 (40)` IPA 为 `638,491,266` bytes（608.9 MiB），SHA-256 `fe8a1b3c715743bb64530ce4372717e6e4c15bdd8995a1cdf7f295e14f560981`。
- [x] Apple 交付：Delivery UUID `f8f36abd-ed24-46db-a278-77b03a862167`；最终状态 `VALID / APP_STORE_ELIGIBLE / IS-ON-APP-STORE-CONNECT`，非豁免加密为 `false`。
- [x] 发布记录：`build/ios/release/build_40/release_manifest.json` 已记录源码 commit `49af255883abf1efcb4f566b0e8fe0f8f890cda8` 及工作树有改动；上传后本地预设已恢复为普通 `release`。Desktop 旧 IPA 因 macOS 权限未替换，不影响 TestFlight。

## 阶段 61 · 一级自动机枪弹药层级修复（2026-07-28）

- [x] 确认一级自动机枪本体没有 `split / chain / splash`，异常的多目标观感来自钢铁先锋初始穿透与普通命中的双层扩散圆环
- [x] 钢铁先锋物理亲和由“1 级 1 穿透、成长 II 再加 1”改为“1 级 0 穿透、成长 II 一次解锁 2”；一级恢复单体直射，满级双穿透上限保持不变
- [x] 自动机枪新增独立 `autocannon` 视觉档；普通物理命中只保留小型定向接触光与 5 枚金属火花，不再生成扩散冲击环或第二层通用命中特效
- [x] 分裂、弹射、溅射、穿透技能的专属路径保持不变，获得对应能力后仍有明确的机制与视觉升级
- [x] M1 smoke 与静态玩法门禁新增一级 `split / chain / splash / pierce = 0`、成长 II 双穿透及紧凑命中档回归
- [x] 使用锁定为一级先锋、一级自动机枪、无护甲 / 芯片 / 宠物的干净配装完成真实 Godot 专项截图；命中集中在目标身体，未出现扩散圆环或跳弹轨迹
- [x] 最终验证：资源包 `9,424` 文件、99 关数据、`367` 个 `res://` 引用、关卡压力、卡牌模拟、终局平衡、玩法打磨门禁、Godot boot、M1 smoke 与 `105` 路真实中英文界面截图全部通过

## 阶段 62 · 霓虹雷暴四角色运行时与双语布局收口（2026-07-28）

- [x] 接入 4 张霓虹肖像和 44 张独立透明备用战斗帧，每人包含 4 idle、4 attack / recoil、3 hurt；融合持枪轮廓继续叠加霓虹动态材质。
- [x] 2026-08-01 持枪纠偏：霓虹与炼狱的 8 把免费武器正式战斗均优先使用 `character_weapon_combos`，两把终焉武器使用三向 `true_grip`；独立手持枪节点不再覆盖人物。完整 `4 × 8 × 2` 主题开枪截图均设为硬失败门禁。
- [x] 删除开火时的人物网状线框，替换为 4 帧渲染式青紫等离子电弧翼；人物中心、脸部和武器留空，随瞄准方向旋转，主动技能保留角色专属元素层。
- [x] 设置页提供默认 / 霓虹可逆预览选择；预览不会伪造 StoreKit entitlement，也不把验收选择误报为已购买。
- [x] 英文专项扩展到 26 路，逐角色覆盖四套主动技长按说明，并修复 Boss 提示、推荐徽章、卡牌详情点击区、角色购买 / 装备按钮和残留中文。
- [x] 全量截图回归额外发现并修复长屏安全区收藏详情右侧越界和设置页上下越界；原生按钮模型不拉伸，仅调整外层安全区留白与隐藏点击区。
- [x] 最终验证：资源包 `9,541` 文件、99 关数据、`368` 个 `res://` 引用、关卡压力、卡牌模拟、本地化、玩法 / 素材门禁、Godot boot、主题专项、M1 smoke、`117` 路全量截图和 `43` 路霓虹专项全部通过。
- [ ] Owner：在真实 iPhone 上验收四角色连续开火时的亮度、热量与“减弱特效”模式；StoreKit、正式商品和终焉军械数值仍不在本阶段。

## 阶段 63 · TestFlight Build 41 霓虹完整运行时验收包（2026-07-28）

- [x] 验收包约束：Build 41 使用 TestFlight 专用 `neon_tempest_preview` feature，供 Owner 验收四角色完整霓虹动画、渲染式开火电弧翼、主题战斗特效及中英文界面；不授予或持久化购买权益，禁止直接选作 App Review 构建。
- [x] 发布链路加固：TestFlight 脚本支持临时注入并在成功 / 失败时恢复导出 feature；导出 PCK 通过独立探针确认 `neon_tempest_preview=true`，本地预设上传后恢复为普通 `release`。
- [x] 发布门禁发现并修复英文暂停页长技能名轻微裁切，以及中英文强化卡长文案底部安全距；固定长文案 fixture 与全量视觉矩阵均纳入永久回归。
- [x] 完整发布门禁：资源包 `9,541` 文件、字体授权、99 关数据、`368` 个 `res://` 引用、平衡 / 经济 / 动作 / VFX / 音频 / 长屏、Godot / battle boot、Save v2、双语 smoke、ThemeManager、M1 smoke 和 `117` 路真实界面截图全部通过。
- [x] 导出包：Build 41 PCK 为 `616,014,340` bytes，包含 `7,185` 个文件和 `3,465` 个导入资源，SHA-256 `1f4a3e358758e1e14c169ad71a5f6f667b17bbda8e8def912379b1739a762fbf`；导出包 battle boot、存档完整性、M1 smoke 与 feature probe 通过。
- [x] 签名产物：`1.0.0 (41)` IPA 为 `645,281,641` bytes（615.4 MiB），SHA-256 `c3c6d0c27cc4a425deea4763fe85aeb55124bc794855ffd161cbfb518b004a4c`。
- [x] Apple 交付：Delivery UUID `afde2490-39e9-485d-90e5-aa0f6d5ef956`；最终状态 `VALID / APP_STORE_ELIGIBLE / IS-ON-APP-STORE-CONNECT`，非豁免加密为 `false`。
- [x] 发布记录：`build/ios/release/build_41/release_manifest.json` 已记录源码 commit `140754ae0d29d4eee2dc4d93f80f98d622385bdb` 及工作树有改动；Desktop IPA 因 macOS 权限未替换，不影响 TestFlight。

## 阶段 64 · 难度与成长曲线 UX 调优（design/24 主方案）（2026-07-29）

### Phase 0 · 修模拟器（Boss 关通关时间下界保护）

- [x] 定位缺陷真因：`simulate_balance.py` 对 `n>=50` 的 Boss 关整关改用实测 runtime benchmark，而 benchmark 的 `crowd_dps`（1,862 万）是 45 只敌人满编队形下的峰值吞吐，按进度线性缩放后杂兵段仍只要 0.1–1.3 秒清完百万级 HP；叠加 `boss_survival_hp_ramp` 在 50 关起点倍率为 1.0，50/55/60/65 关 t_ws 塌到 2.0 / 10.1 / 16.0 / 19.2 秒。
- [x] 下界保护：杂兵段改用 `min(crowd_dps, dps_ws)`，即与其余 79 关同一套 crowd 模型对齐（`estimate_skill_mult` 本就注明是 effective crowd throughput）；Boss 单体段保持实测 `boss_dps`，因为 `dps_ws` 内含群伤倍率、不是合法的单体速率。
- [x] 未动任何游戏数值旋钮：`boss_survival_hp_ramp` 的 `max_mult` / `curve_power` 保持 56.0 / 1.15，方案允许的 curve_power 微调本次不需要。
- [x] 校验基线更新（引用 design/24 Phase 0）：`clear_time_cap(90+)` 由 330s 改为 350s——原 330s 是在 level_095 被低估为 188.6s 时定的，修正后为 334.4s，与既有 460s 毕业关容差一致。
- [x] 验收：`Levels < 30s (with skill)` 只剩 level_001（28.1s）；全部 20 个 Boss 关 t_ws ≥ 51.6s，50 关之后单调递增；validate_data / check_level_pressure / check_balance_profile / simulate_balance / check_endgame_balance / check_release_candidate 全绿。

### Phase 1 · 星级判定统一 + 单一事实来源

- [x] 新增 `data/economy.json` `star_thresholds`（`three_star_hp_ratio 0.70` / `two_star_hp_ratio 0.35`），并新建 `core/data/star_rules.gd` 作为唯一读取入口（含同值兜底默认，防数据缺失）。
- [x] `gameplay/battle/battle.gd` 结算不再硬编码"满血才 3 星"，改调 `StarRules.stars_for_hp_ratio()`；`tools/simulate_balance.py` 删除硬编码 40/70，改由 `star_leak_caps()` 从同一份 economy.json 换算成 leak 口径（3★ ≤30%、2★ ≤65%）。
- [x] UI 同源动态提示：结算页星星行下方与配装页战术摘要底部都显示 `三星 防线 ≥70%  ·  两星 ≥35%`，数字全部由 economy.json 生成；英文目录补 `3★ base line ≥%d%%  ·  2★ ≥%d%%`。
- [x] 配装摘要面板高度 316 → 388，容纳英文下会折成三行的护甲/芯片/宠物行 + 新增星级提示行；中英文实机截图确认不再裁切。
- [x] 存档无需迁移：星级按 `max(new - old, 0)` 补差额，放宽后只会多拿星。
- [x] 验收：headless 打 level_001 故意漏 20% 血 → 结算 3★（旧规则为 2★），0.50 → 2★、0.20 → 1★；grep 确认 `0.70/0.35` 只存在于 economy.json 与两处有注释的兜底默认；`check_release_candidate.py` 含 117 路截图全绿。

### Phase 2 · Boss 关公平性包

- [x] `data/economy.json` 新增 `boss_level_base_hp_mult: 1.25`；`battle.gd` 任一波含 `boss` 的关卡基地血量上限按 `base_hp_ref × 1.25` 起算（再乘人物/护甲/芯片/宠物），`simulate_balance.py` 的 leak 分母同步。推荐战力公式、Boss HP ramp、敌方压力一律不动。
- [x] 发现并修掉模拟器第二个缺陷：`leak_damage()` 把整关（含 1–4 波纯杂兵波）都按 Boss 的 12% 漏怪率计，而这些无 Boss 在场的波次占 Boss 关突破伤害的 60–79%。改为按波取漏怪率（含 boss 的波 12%、其余 5%），普通关数字零变化。
- [x] 结果：Boss 关 leak 由 66–100% 降到 33–57%，**20/20 全部达到 2★ 口径**；99 关分布 3★ 12 / 2★ 86 / 1★ 1。无关卡 leak >90%，无需动 waves count。
- [x] 明确不做：未加保底维修事件，未动 `boss_survival_hp_ramp.max_mult`。
- [x] ~~Owner 拍板：早期 Boss 关难度倒挂~~ → **已在"阶段 65 · 早期 Boss 关垫子曲线化"落地**（commit `540b5471`）。同时更正了此处描述：压力其实是 U 型（5–20 与 65–99 都是 46–57%，25–60 才是 33–46%），不是单纯"早期最难"。垫子改为 ≤10 关 1.75 → ≥25 关 1.25 线性插值后，5/10/15/20 关 leak 降到 35/41/38/41%。方案原文要求的"3★ 口径"仍未达成（需 ~2.4× 垫子），但 §4 主目标"2★ 常态"已达成。
- [x] 验收：headless 确认 level_005/010 相对 level_004/009 的基地血量比恰为 1.25；validate_data / check_level_pressure / check_balance_profile / simulate_balance / check_endgame_balance / check_economy_loop / check_release_candidate（117 路截图）全绿。

### Phase 3 · 星级经济复核

- [x] 星级供给按 Phase 1+2 后的分布重算：战役 209 星；挑战按 challenges.json 实际系数（`hp_mult` 1.30–1.42 × `breach_damage_mult` 1.00–1.18）建模得 167 星，合计 **376 星**。方案原文的"普通关星级 −1 档"整档下调对卡在档位上沿的关卡过度惩罚（34% leak 的关卡挑战下是 46%、仍是 2★），只给出 319 星，故改用系数建模并记录两条口径。
- [x] **判定 376 / 318 = 1.18 ≥ 1.10，供给充足 → 最贵一档解锁价维持不动**（volt/plasmacannon 16★、railgun/reactive/chip_element/collector 14★）。这是 Phase 1+2 的直接结果，本 Phase 无数据改动。
- [x] XP 经济抽查：需求 137,400 XP（16 永久技能 + 4 专属技满级）；10/30/50/70/90 关单局 665/731/1,644/2,202/2,968 XP，全战役一遍即 138,055（100%），战役+全挑战 201%，远超方案设定的 60–80%。XP 不是瓶颈。
- [x] ~~Owner 拍板（Phase 3 范围外，仅记录）：两个死旋钮~~ → **已在"阶段 65 · 死旋钮清理"落地**（commit `236a8742`）：`econ_xp_growth` / `xp_per_kill_growth` 与 schema 的 `star_total_cap` 全部删除。
- [x] ~~XP 供给过剩~~ → **部分解决**：Owner 设计的重复通关经验递减已落地（commit `755faa24`），刷三遍战役由 301% 压到 176%。**首通一遍仍是 100%**，剩余部分见下方"XP 经济"小节的未决项。
- [x] 验收：`check_economy_loop.py` 全绿（star_unlock_total=318 / max_item=16 / normal_campaign=297 / challenge_needed=21）；供需表与 XP 抽查表已写入 design/24 附录。

### Phase 4 · 低风险平滑项

- [x] **6.1 章节开局毛刺：撤销，问题 F 是误判。** `difficulty_coef` 不是难度指数，只是压在波次编成之上的倍率；61/89 coef 高恰恰是因为章节开局编成弱、需要高倍率接住上一关压力。真实压力：59 关 37,302 → 61 关 38,380（+2.9%），且 61 关紧跟 Boss 关 116,752 之后是**大幅下降**，不存在"闷棍"。按方案改成 3.10/4.40 后 `check_level_pressure.py` 直接报 `level_061 28803.8 < level_059 37302.7`、`level_089 191905.2 < level_088 198573.8`——改动会让战役难度真的倒退。按 §10 红线判定校验是对的，两关 coef 保持 4.1307 / 5.1302；97/98 的 6.62/8.24 本就保留。
- [x] **6.2 后期金币收入平滑：已实施。** 85–99 关 `reward_gold_mult = max(mult, 0.26)`（原 0.25 逐级衰减到 0.20），`upgrade_cost_linear_k` 未动。单局金币 85 关 +4%、90 关 +8%、95 关 +18%、99 关 +30%，85–99 合计 +14.0%（方案预估 +20–30%，因 85–87 本就接近 0.26 地板）。
- [x] 验收：validate_data / check_level_pressure / check_balance_profile / simulate_balance / check_endgame_balance / check_economy_loop 全绿，`check_economy_loop.py` 基线无需更新；`check_release_candidate.py`（117 路截图）全绿。

### Phase 5 · 元素与武器经济

- [x] 毒弱点覆盖 2 关 → **6 关**：level_032/034 由 physical、level_037/039 由 fire 改为 `primary_weakness: "poison"`，`card_bias` 的元素键同步改为 `poison: 1.35`。分布变为 物理 37 / 火 32 / 冰 12 / 雷 12 / 毒 6；四关星级口径零变化（模型基线不含克制，符合方案预期）。
- [x] 偏离方案①：`env_toxic_biolab` 只在第 4 章（31–40 关），方案写的"第 8/9 章"不存在（第 8/9 章是虚空圣堂/轨道遗址）；且第 4 章只有 2 关 fire 弱点，凑不满 4 关，故另取 2 关 physical（最富余的一档）。
- [x] 偏离方案②：`weapon_venomlauncher.unlock_cost_star` 10 → **8**（非方案要求的 6）。`validate_data.py` / `check_balance_profile.py` / `m1_smoke_test.gd` 三处既有硬约束：付费解锁价必须在 8–16 星区间且同类目不得超过 2× 曲线；6★ 同时踩两条。取区间下限 8★（与 flamethrower/cryocannon 同价，对 plasmacannon 恰好 2.0×）。
- [x] 校验基线更新（引用 design/24 Phase 5，非静默改动）：解锁总价 318 → 316，`m1_smoke_test.gd` 的 `total == 318` / `challenge_needed == 21` 改为 316 / 19。
- [x] 7.2 配装页克制建议：已拥有同元素武器但未装备时，战术摘要底部追加绿色可点击行 `建议武器：{武器名}（克制本关，伤害×1.5）`，点击跳武器图鉴，不自动换装；倍率动态读 `weakness_mult`，英文目录同步。面板高度按是否出现建议行在 388 / 452 之间切换。
- [x] ~~Owner 拍板：毒弱点仍全部集中在第 4 章~~ → **已在"阶段 65 · 毒弱点铺到 6/7 章"落地**（commit `16b11088`）：level_053/059（沉没地铁）与 level_062/069（沙暴炼油区）改为 poison，毒弱点 6 → 10 关，与冰、雷同量级；venomlauncher 覆盖 4/6/7 三章。
- [x] 验收：中英文实机截图确认建议行显示与点击区（`建议武器：冰霜炮…` / `Suggested: Cryo Cannon…`）；`check_release_strings.py`、`simulate_card_director.py`、`check_release_candidate.py`（117 路截图）全绿。

### Phase 6 · 技能生态再平衡

- [x] `save_manager.gd` `_combat_skill_effect_multiplier` 权重按方案调整：survival `0.18 → 0.28`、barrier `0.22 → 0.35`、slow `0.30 → 0.40`、pierce secondary_gain `0.075 → 0.065`；gold_rush 未动。`RECOMMENDED_POWER_COEF` 未动，实测推荐战力（level_050 = 245、level_099 = 757）分毫未变。
- [x] 实测评分变化：barrier×4 `1.0317 → 1.0784`（+4.5%）、barrier×2+slow×2 `+3.7%`、slow×4 `+2.4%`、pierce×4 `1.4805 → 1.4405`（−2.7%）、纯进攻组合 −1.5%。
- [x] **更正方案 §8 第 4/5 条**：这两条目标无法通过第 1/2 条达成——它们作用在两套互不相干的系统上。选取率来自发牌阶段（`gameplay/skill/card_director.gd` 与镜像 `tools/simulate_card_director.py`，权重公式 `4 + Σ_tag round(bias[tag] × 2)`，只读 `card_tags`/`card_bias`，完全不读 save_manager）；`simulate_balance.py` 的技能吞吐取自 `tools/combat_power_model.py`，同样不读 save_manager。实测：改权重前后 `simulate_card_director.py` 全量输出逐字节相同，星级分布仍为 3★ 12 / 2★ 86 / 1★ 1（漂移 0 关）。
- [x] 真实根因已定位并记录：发牌权重与 `card_tags` 数量近似成正比。`skill_barrier` 只有 `['defense']` 1 个标签（12.7%），`skill_pierce` 有 4 个且起始武器为物理、tank 威胁再加成（31.7%）。
- [x] ~~Owner 拍板：给 barrier 补标签~~ → **已在"阶段 65 · barrier 补标签"落地**（commit `16b11088`）：`skill_barrier.card_tags` 加 `anti_swarm`，选取率 9.8% → 12.8%、高压关 11.7% → 13.9%。§8 的两个量化目标仍未达成，剩余部分见"技能生态 · `skill_barrier` 补标签"小节的未决项。
- [x] 验收：`simulate_card_director.py`、`simulate_balance.py`、`check_release_candidate.py`（117 路截图）全绿。

### Phase 7 · 战力口径显示修正

- [x] 三口径统一命名（全仓库 grep 替换，无混用残留）：`战前 → 基准`（内含 4 次标准选卡的预估加成）、`成型 → 预计成型`、`本局成型 → 终局战力`（与"终局"同一个量，改名消除混用）、`终局` 不变。
- [x] 终局低于基准时，结算提示追加 `（选卡未满）`：`基准 12 → 终局 8（选卡未满）/ 关卡 34。已计入局内技能。`；英文 `Baseline 12 → Final 8 (partial draft) / Stage 34. In-run skills included.`。
- [x] 量纲未动：`RECOMMENDED_POWER_COEF` 是按这把尺子标定的，动尺子要重标，不值得（方案原文同此判断）。§9 第 3 条的"长按战力数字说明"——配装页战力格本就没有 tooltip / 长按详情，按方案"没有就不加交互，只改文案"处理。
- [x] 双语目录同步：3 条结算模板各加一条"（选卡未满）"变体（共 6 键），`__terms` 补 `基准 / 预计成型 / 终局战力 /（选卡未满）`。
- [x] 验收：headless 打一局一张卡都不选 → `cards_picked=0  基准=12  终局=8`，结算文案含"（选卡未满）"；中英文实机截图核对；`check_release_strings.py`、`check_release_candidate.py`（117 路截图）全绿。

## 阶段 65 · design/24 收尾（Owner 拍板项落地）（2026-07-29）

### 早期 Boss 关难度倒挂 · `boss_level_base_hp_mult` 曲线化

- [x] 更正 Phase 2 的描述：Boss 关压力其实是 **U 型**，不是单纯"早期最难"——5–20 关与 65–99 关都是 46–57% leak，25–60 关只有 33–46%。平垫子会让玩家最先遇到的三个 Boss 关成为全场最难的一档。
- [x] `boss_level_base_hp_mult` 由标量 1.25 改为曲线对象 `{base 1.25, early_mult 1.75, early_full_level 10, early_end_level 25}`：≤10 关取 1.75，≥25 关取 1.25，中间线性插值；兼容旧的浮点写法。`battle.gd._boss_level_base_hp_mult()` 与 `tools/simulate_balance.py:boss_base_hp_cushion()` 是同一条公式的两份实现。
- [x] 结果：早臂 5/10/15/20 关 leak 由 50/57/48/46% 降到 **35/41/38/41%**，与中段 33–46% 齐平；晚臂 65–99 保持 43–57%（最难，符合设计意图）。20/20 Boss 关仍全部 2★，99 关分布 3★ 12 / 2★ 86 / 1★ 1 不变。
- [x] 验收：headless 逐关对比 Boss 关与相邻普通关的基地血量比，5/10/15/20/25/99 关实测垫子 1.756/1.753/1.583/1.417/1.249/1.250，与公式逐项吻合（level_050 因既有的"`level_ordinal < 50` 且战力不足时 ×1.08"无障碍垫子退出而显示 1.159，属既有行为，非本次改动）。
- [x] `check_release_candidate.py`（117 路截图）全绿。

### 技能生态 · `skill_barrier` 补标签

- [x] `skill_barrier.card_tags` 由 `['defense']` 改为 `['defense', 'anti_swarm']`（屏障挡的正是尸潮，语义成立）。发牌权重由 `4 + 2·bias` 提升到 `4 + 4·bias` 量级。
- [x] 实测：barrier 全场平均选取率 9.8% → **12.8%**；高压关（20 个 Boss 关 + 90 关后共 27 关）11.7% → **13.9%**。其余技能位移均在 ±0.3% 以内，gold_rush 未动（8.3% → 8.2%）。
- [ ] **仍未达成 + 新数据（需 Owner 拍板）**：方案 §8 的两个量化目标——"barrier 在高压关进 15%+"差 1.1 个点；"没有技能在超过 80 关里进前二"仍未达成（pierce 98/99 关）。实测唯一能一次性达成两者的杠杆是**把 `physical` 从 `skill_pierce.card_tags` 里去掉**：pierce 进前二的关卡 98 → **15**，最高者变为 charge_shot 60 关（< 80 达标），barrier 高压关 → 14.3%，pierce 平均 31.1% → 23.5%（仍健康）。代价：`skill_pierce` 是全表**唯一**带 `physical` 标签的技能，去掉后物理武器玩家将没有任何"武器适配"卡（`matches_loadout` 的 +4 永远不触发），而火/冰/雷/毒玩家都有对应元素弹药技能——会造成反向不对称。该改动超出本次授权范围，未擅自执行。

### XP 经济 · 重复通关经验递减（Owner 设计）

- [x] `data/economy.json` 新增 `repeat_clear_xp_mult: [1.0, 0.5, 0.25]`：按**本关此前的通关次数**取下标，首通 100%、二周目 50%、三周目及以后 25%（超表长钳到末位）。倍率表只存这一处。
- [x] 存档新增 `level_clear_counts` / `challenge_clear_counts` 两个字典，普通关与挑战各自独立计数，失败不计数。纯追加字段，`_merge_defaults_recursive` 自动补空字典，**无需迁移版本号**；存档形状校验已把两个新字段纳入数值检查。
- [x] 倍率在 `battle.gd._finish()` 构造结算 payload 时就乘进 `result.xp`（另附 `xp_full` / `repeat_xp_mult` 供 UI 用），**结算页显示的就是实际入账的数字**，SaveManager 不再二次打折。取的是"本次通关之前"的次数，早于 `apply_*_result` 递增。
- [x] UI：倍率 < 1 时结算页经验卡标题显示 `经 验  ×50%`（英文 `XP  x50%`），百分比由数据算出不写死；中英文实机截图核对。
- [x] 永久回归：`m1_smoke_test.gd` 新增 `_verify_repeat_clear_xp_decay` —— 逐次通关倍率 1.0/0.5/0.25/0.25、挑战计数与普通关隔离、失败不计数、旧存档缺字段按首通处理。
- [x] XP 供需实测（需求 137,400）：战役一遍 138,055（100%）不变；刷满二周目 151%、三周目 176%（旧规则刷三遍是 301%）；战役+挑战各一遍 201%。
- [ ] Owner 拍板：递减机制封住了刷本上限（3 遍由 301% 压到 176%），但**首通一遍仍是 100%**——"打完一遍战役即可点满全部永久技能"这一条没有变。要一并解决需要提高技能 XP 成本或降低 `run_xp`，属另一个决策，未擅自执行。

### 死旋钮清理

- [x] 删除 `battle.gd` 的 `econ_xp_growth` 变量与赋值——它从 economy 读入后在整个战斗流程里从未被使用；同时删掉 `data/economy.json` 里没有任何读者的 `xp_per_kill_growth: 0.06`。真正的单局经验来自每个僵尸/Boss 的 `run_xp` 累加。
- [x] 删除 `design/data/schema.md` 里记录的 `star_total_cap: 297`——该字段在 `data/economy.json` 中并不存在，也没有任何代码读取，属于文档与数据脱节。
- [x] 验收：全仓库 grep 确认三个标识符已无代码/数据引用；`check_release_candidate.py`（117 路截图）全绿。

## 阶段 66 · TestFlight Build 42 难度调优验收包（2026-07-29）

- [x] 验收目标：design/24 全量落地（Phase 0–7 + Owner 拍板的 5 项收尾）后的真人手感验证——星级判定放宽、Boss 关全部可拿 2★、早期 Boss 垫子、后期金币 +14%、毒弱点 10 关与配装页克制建议、重复通关经验递减。
- [x] 构建为**普通 `release`**，未注入 `neon_tempest_preview` 临时 feature（与 Build 41 不同）；不授予任何购买权益。
- [x] 源码 commit `236a8742`，`tracked_changes_present: true`——工作区仍有 Jul 28 的 Neon Tempest 并行改动（30 个已跟踪文件 + 5 个未跟踪路径），因此本构建**包含**那批未提交的霓虹运行时改动，与 Build 41 情况一致。
- [x] 发布门禁：`check_release_candidate.py` 全绿（117 路中英文截图）；导出 PCK `7,187` 文件 / `3,465` 导入资源 / `587.5 MiB`，导出包 battle boot、存档完整性与 M1 smoke 全部通过。
- [x] 产物：PCK `616,021,004` bytes，SHA-256 `0761f61de3b0c1c0993f8ced3e861067e2d1a60968ce8462cf965559ac32008b`；IPA `645,285,656` bytes，SHA-256 `d316c4a037b8ffbfe8f964cf431869733503c1560fb4e827f2ca9870e0f7c732`。
- [x] Apple 交付：Delivery UUID `79598e5a-f6f6-443e-ad6a-a274adb17710`；`VALID / APP_STORE_ELIGIBLE / IS-ON-APP-STORE-CONNECT`，非豁免加密 `false`。发布记录 `build/ios/release/build_42/release_manifest.json`。
- [ ] Owner 真机验收重点：① 早期 5/10/15 关 Boss 是否仍显吃力；② 星级放宽后 2★/3★ 的达成感是否合理；③ 同一关第二次打时经验卡的 `×50%` 是否读得懂；④ 配装页"建议武器"行的可点击区与跳转。

## 阶段 67 · 编队原型真正生效 + 变体关首波出怪修复（2026-07-29）

- [x] **发现 `wave_pattern` 是死字段**：99 关全都写了 `standard / rush / pincer / escort / siege`（24/20/19/18/18），但运行时从来没读过——只有 `check_level_pressure.py` 数了数种类、`rebalance_difficulty.py` 写过它。五种编队一直只是标签，玩家感受不到任何差别，正是本条 todo 说的"只靠 HP/数量换皮"。
- [x] 接入 `battle.gd._formation_lane()`：`standard` 沿用作者写的 `lane`；`rush` 全部压中路；`pincer` 左右交替、中路留空；`escort` 支援目标走中路、其余贴两翼；`siege` 左/右/散开三路轮转铺满战线。Boss 不受影响，始终按作者通道入场；无尽模式在模板替换之后再读，不会误用入口关卡的编队。
- [x] **只改队形几何，不碰数量/间隔/HP/总出怪时长**——validate_data、check_level_pressure、check_balance_profile、simulate_balance、check_endgame_balance、check_economy_loop、simulate_card_director 全部数字不变，星级分布仍为 3★ 12 / 2★ 86 / 1★ 1。编成签名本就有 96 种（99 关），差异化的缺口在表现层而非数据层。
- [x] **顺带发现并修复一个既有 P0 bug**：出怪循环被错误地缩进在波次提示分支的 `else` 里，于是 `elite` / `treasure` 变体关的第 1 波只弹一条提示、**一只敌人都不刷**——11 个精英关 + 10 个宝箱关共 **442 只敌人从未出现过**，而所有平衡模型全程都把它们算在内。变体只应决定提示文案，不应决定是否出怪。
- [x] 永久回归：`m1_smoke_test.gd` 新增 `_verify_wave_formation_lanes`（五种编队各自的通道契约，实机排队验证）与 `_verify_variant_wave_one_spawns`（变体关第 1 波必须编排敌人）。
- [x] 验收：五种编队实机排队分别为 `spread×7` / `center×10` / `left6+right4` / `left6+right6` / `left4+right4+spread4`；`check_release_candidate.py`（117 路截图）全绿。

### 阶段 67 · 按环境的动态音频混音

- [x] 复核既有实现：todo 里的另外两条其实**早已满足**——`get_sfx_concurrency_limit()` 已对 `shot_ / muzzle_ / hit_` 做同类并发上限，`get_sfx_priority()` 已给 Boss 入场 / 防线告急 / 威胁预警 100、主动技与角色技 70、UI 65、普通命中 40、枪声 30，并由 `_request_bgm_duck_for_sfx()` 做 BGM 闪避。缺的只有"按环境"这一条。
- [x] `data/environments.json` 全部 14 个环境新增 `audio_mix`：`sfx_db` / `bgm_db` / `reverb_wet` / `reverb_room` / `reverb_damping`，按各自空间声学给值——虚空圣堂最长混响（0.24）、沉没地铁次之（0.22）、冰川断桥明亮长尾（0.20）、沙暴炼油区几乎全干（0.05）、毒液生化舱短促阻尼（0.09）。
- [x] `default_bus_layout.tres` 的 SFX 总线新增 `AudioEffectReverb`（默认 `wet=0`，不改变现状）；UI 音效走 UI 总线，永远保持干声。
- [x] `AudioManager.apply_environment_mix()` / `clear_environment_mix()`：`sfx_db` / `bgm_db` 以**播放器音量偏移**施加，绝不写总线音量，避免与设置页音量滑杆互相覆盖。战斗 `setup()` 施加、`_exit_tree()` 归零，成对保证菜单/地图/结算不会挂着战场混响。
- [x] 永久回归：`m1_smoke_test.gd` 新增 `_verify_environment_audio_mix`——每个环境必须声明 `audio_mix`、`reverb_wet` 在 0–0.35 内、各环境之间必须真有区分度、进入战斗套用对应环境、离开战斗必须归零。
- [x] 验收：实机 5 关抽查 wet 分别为 0.14 / 0.20 / 0.22 / 0.24 / 0.12，`mix_id` 与关卡环境逐关吻合，退出后全部归零；`check_audio_overlap.py` 与 `check_release_candidate.py`（117 路截图）全绿。
- [ ] Owner 验收（属 B 组既有条目）：扬声器与耳机两套实听复核。

## 阶段 68 · 霓虹雷暴商品与终焉雷霆本地购买闭环（2026-07-29）

- [x] Phase 1C：新增终焉雷霆炮、天穹导体甲、超导风暴核心、雷暴终端四件数据、独立素材、金币升级、2/4 件套、连锁 / 过载、护甲反击、宠物群体放电和终端雷柱。
- [x] 本地商品：三 SKU 按主题 `1.99`、完整包 `6.99`、主题拥有者升级 `4.99` 切换；购买确认、恢复、清空、整套装备与撤权回退闭环完成，所有界面明确标注不连接 Apple、不会扣款。
- [x] 权益安全：Save v3 的 `commerce.mock_receipts` 与 `entitlements.verified` 分离；本地演示不写 verified，完整包一次授予主题 + 军械，清空后回退默认主题 / 自动机枪并保留休眠等级。
- [x] 收藏入口：premium 装备不再显示 `999999★`，卡片和详情统一进入霓虹军械库；英文长装备名和未拥有状态已完成截图适配。
- [x] 数值：`tools/audit_character_endgame_dps.py` 排除 premium 后保持四角色免费基线，并计算过载 / 终端雷柱 / 宠物技能；终焉雷霆整套满级单 Boss 持续输出实测 `1.550x` 免费 Volt 最强上限。
- [x] 视觉：四件独立高质量渲染和 7 个商品 / 装备 runtime 导出完成；删除 124 个未被运行时使用的旧兼容帧，约节省 21.3 MiB；雷柱边缘安全，四件套由宠物明确引雷，无递归结算。
- [x] 握持收口：终焉雷霆炮不再作为悬浮独立层贴在人物前方。四角色各有左 / 中 / 右 3 张真实双手握持战斗母版，共 12 张 380×520 runtime 图；前手托护木、后手握扳机、炮尾抵肩、宽站姿承受后坐力，枪口锚点逐方向重标。
- [x] 特效衣服分层：石墨护甲、人物专属剪影、青 / 紫导光缝和棱彩材质底色烘进人物模型；彩虹流光、电脉冲、枪口联动光翼和后坐力继续由 shader / VFX / rig 动态生成，减弱特效模式仍有效。
- [ ] Apple 后续：接 `.storekit`、iOS StoreKit 2 bridge、已验证交易 / pending / cancel / failure、退款撤权、Sandbox、TestFlight 真实购买和 App Store Connect IAP 元数据。

## 阶段 69 · TestFlight Build 43 霓虹商品与终焉握持验收包（2026-07-30）

- [x] 验收目标：将霓虹军械库本地购买 / 恢复 / 清空 / 装备闭环、终焉雷霆四件套与四角色左 / 中 / 右真实双手握持运行时交给 Owner 真机验收。
- [x] 构建形态：普通 `release`，不注入 `neon_tempest_preview`，不自动授予 verified 权益；本地演示收据仍与未来 Apple 已验证交易严格隔离。
- [x] 发布门禁补强：免费经济、免费价格曲线与免费武器 DPS 排名统一排除 premium `999999` sentinel；商店遮罩和确认弹窗改走纹理化 UiKit；视觉、动作与 HUD 验证器正式覆盖 12 张终焉真实握持母版和运行时后坐力曲线。
- [x] 完整发布门禁全绿：117 路中英文截图、1056 个战斗 sprite 文件、689 帧战斗 VFX、83 组语义 VFX / 710 帧、108 组攻击动作、20 类僵尸攻击、908 帧 HUD 遮挡审计，以及 headless / battle boot / save integrity / localization / theme manager / M1 smoke。
- [x] 导出 PCK：`7,233` 文件 / `3,484` 导入资源，`619,240,720` bytes，SHA-256 `880f5c9beb4e1d85408e97ca80274eac96ed5bf34f2fd91f3cc9912d9ba334ea`；导出包 battle boot、存档完整性与 M1 smoke 全部通过。
- [x] IPA：`648,487,272` bytes，SHA-256 `c153e6ebbcad940bcc5dbc649c2560fe978b93974a8da193c5a276099e3fae02`；Xcode archive、IPA 校验与上传全部成功。
- [x] Apple 交付：Delivery UUID `23b1fff1-7ae9-41e6-953e-3baa60a889df`；`VALID / APP_STORE_ELIGIBLE / IS-ON-APP-STORE-CONNECT`，非豁免加密 `false`。发布记录：`build/ios/release/build_43/release_manifest.json`。
- [ ] Owner 真机验收：新存档购买主题 → 主题拥有者升级 → 整套装备 → 四角色三方向握持 / 枪口 / 后坐力 → 降低特效 → 重启恢复 → 清空撤权回退。
- [ ] App Review 前必须移除或隐藏本地演示购买入口，并接通 StoreKit 2、已验证交易、恢复 / pending / cancel / failure、退款撤权、Sandbox 与 App Store Connect IAP 元数据。

## 阶段 70 · TestFlight 倍速常开（2026-07-30）

- [x] 新增独立导出 feature `testflight_speed_unlocked`：TestFlight 内测包从第 1 关常显倍速按钮，并完整开放 `1X / 2X / 5X` 循环；不强制玩家使用高倍速，继续记住玩家最后选择。
- [x] 正式成长规则不变：无 feature 时仍为第 30 关显示 / 开放 2X、第 50 关开放 5X，旧存档的越级速度仍会被安全限制。
- [x] `ship_testflight.sh` 默认只在 TestFlight 导出期间临时注入 feature，结束后恢复普通 `release` 预设；导出 feature probe 与导出 PCK M1 smoke 会同时验证标记存在及第 1 关三档切换。
- [x] 双路径验收：源码普通 `release` M1 smoke 通过第 29 / 30 / 50 关门禁；临时导出 PCK 的 feature probe 确认 `testflight_speed_unlocked=true`，导出包 M1 smoke 通过第 1 关按钮可见及 `5X → 1X → 2X → 5X` 循环；AGENTS 规定的素材、数据、引用、压力、卡牌、Godot boot 与 M1 smoke 全部通过。
- [ ] App Store 提审前：从 `tools/ship_testflight.sh` 移除 `testflight_speed_unlocked` 默认注入，并重新跑普通 release 的第 29 / 30 / 50 关倍速门禁。

### TestFlight Build 44 最新内测交付（2026-08-02）

- [x] 以 `release,testflight_speed_unlocked` 临时 feature 导出 Build `44`；导出 PCK feature probe 明确返回 `testflight_speed_unlocked=true`，M1 smoke 验证第 1 关常显倍速按钮及完整 `1X / 2X / 5X` 循环。
- [x] 正式 preset 在上传结束后恢复为纯 `release`；正式成长规则继续保持第 30 关开放 2X、第 50 关开放 5X。
- [x] 完整 Release Candidate、导出 PCK 启动 / 存档 / M1、Xcode archive、IPA 审计和 Apple 服务端校验全部通过。
- [x] Apple 交付：Delivery UUID `a47bbf50-bb0e-49a3-a572-eeb388fae4c8`；状态 `VALID / APP_STORE_ELIGIBLE / IS-ON-APP-STORE-CONNECT`，发布记录位于 `build/ios/release/build_44/release_manifest.json`。
- [ ] Owner 真机内测：第 1 关确认按钮常显，依次切换 `1X → 2X → 5X → 1X`，并复核暂停 / 结算 / 重进关卡后的速度状态。

## 阶段 71 · 霓虹按钮视觉降噪（2026-07-30）

- [x] 保留霓虹雷暴按钮的赛博朋克金属框、青 / 紫双色能量面与原生长短按钮模型，不改尺寸、不拉伸、不改字号。
- [x] 统一将主按钮纹理表面收敛到约 `80%–86%` RGB 强度、次级按钮轻收敛到 `92%–96%`；只调底图 `self_modulate / StyleBoxTexture.modulate_color`，子级文字保持全亮。
- [x] 所有 UiKit 装甲文字按钮增加 3px 深色描边，提升白字 / 金字在青紫发光面上的轮廓，不依赖缩字获得清晰度。
- [x] ThemeManager 回归锁定：霓虹 TextureButton 必须只压低自身纹理、不得压暗子级文案；普通 Button 必须使用相同表面调制并保留至少 3px 文字描边。
- [x] 验收：中文 / 英文菜单与英文霓虹军械库真实截图人工复核通过；完整 43 路霓虹界面矩阵无文字越界、按钮拉伸或运行时布局问题；素材、数据、引用、关卡压力、卡牌模拟、Godot boot、ThemeManager 与 M1 smoke 全部通过。

## 阶段 72 · 全局主题与逐角色换装（2026-07-30）

- [x] 设置页不再用单按钮轮换主题，改为独立的「主题与外观 / Theme & Appearance」页：全局主题负责菜单、基地、按钮、枪械配色与战斗氛围，角色战衣允许逐人覆盖。
- [x] Save v3 新增 `cosmetics.character_outfits`，四名角色均支持 `follow_theme / default / neon_tempest`；默认跟随全局主题，单独指定后不再随全局切换，权益撤销时自动回退。
- [x] 收藏角色详情新增等宽「外观」按钮；配装页人物卡新增不遮挡原角色选择区的「外观 / Outfit」快捷入口。战斗内与暂停页不提供热切换，避免中途重载人物、枪口锚点和特效状态。
- [x] 本地购买完成页提供「立即应用整套」与「逐个角色换装」两条后续路径；前者统一启用霓虹主题并把四人恢复为跟随主题，后者进入逐角色配置。
- [x] 展示立绘、战斗人物、开枪动画、角色主动技与角色专属流光均按每名角色的有效主题解析；基地、武器与公共 UI 仍严格跟随全局主题，外观与数值完全分离。
- [x] 中英文补齐主题说明、状态、操作按钮和购买完成提示；语言检查覆盖 `986` 条运行时中文源，结果为 `93` 个内容 ID、`391` 条精确文案、`532` 个复用词条全通过。
- [x] 视觉回归新增全局主题页中英、逐角色页中英、购买完成中英 6 个固定场景；本轮真实截图矩阵通过。随后把配装页人物选择区与换装入口拆成互不重叠的点击区域，并将换装触控高度提升到 88px。
- [x] 永久回归：ThemeManager 测试锁定全局默认 + 单人霓虹、全局霓虹 + 单人默认、跟随切换、动作帧 / shader 路由和撤权回退；M1 smoke 锁定购买、整套应用、四人跟随与撤权闭环。
- [x] 发布门禁：素材 `9,647` 文件、99 关数据、383 个 `res://` 引用、关卡压力、卡牌导演、Localization、Godot headless boot、Save Integrity、ThemeManager 与 M1 smoke 全部通过。
- [ ] Owner 真机验收：设置页全局切换、四角色分别混搭、配装页头像快捷入口、购买完成两条路径，以及重启后的外观持久化。
- [ ] App Store 前仍须把本地演示购买入口移除或隐藏，并接 StoreKit 2、已验证交易、恢复 / pending / cancel / failure、退款撤权与 App Store Connect IAP 元数据。

## 阶段 73 · 第二套炼狱赤焰 / 终焉炼狱范围冻结（2026-07-31）

- [x] Owner 明确选择炼狱赤焰 `Infernal Dominion` + 终焉·炼狱军械 `Inferno Apocalypse` 作为第二套。
- [x] 新增 `design/25_infernal_dominion_inferno_phase2_inventory.md`，冻结主题 / entitlement / 三 SKU / 四件套 ID、四角色身份、八武器、72 原生按钮、基地 / UI / Logo、完整攻击链和中英文商品范围。
- [x] 盘出第二套前置架构风险：PurchaseManager、Store、Neon shader / VFX、Thunder true-grip、后坐力 / 枪口锚点和多项验证器仍是单系列硬编码。
- [x] 执行顺序冻结为 Step 0–8：多系列架构 → 视觉原型 → 主题 runtime → 军械机制 → 顶级表现 → 本地商品 → 完整回归 → TestFlight → Apple 商业接入。
- [x] 数值边界继续使用三类场 `40% Boss / 40% 尸群 / 20% 混合`，最终综合输出 `1.52x–1.58x`；免费难度、推荐战力和敌人攻击不随付费装备上调。
- [x] Step 0：完成多系列架构解耦；霓虹视觉、购买、撤权和雷霆 `1.550x` DPS 保持不变。
- [x] Step 1：完成炼狱色板、四人战衣、八武器、四件套、UI / 基地 / Logo、战场综合图和十段表现分镜，Owner 已确认整体渲染方向。
- [x] Step 2：完成炼狱主题 runtime：4 立绘、44 角色帧、72 原生按钮、8 把免费武器三形态涂装、主题 / 逐人换装和代表场景。
- [x] Step 3：完成终焉炼狱四件套数据与机制；Boss / 尸群 / 混合加权满级输出 `1.571x`，落在锁定 `1.52x–1.58x` 带内。
- [x] Step 4：完成背面三向真实握持、身体附着持续灼烧、中央 / 边缘 / Boss 爆燃、一次死亡传播、方向语义锁定的机械凤凰、向上基地反击、满级觉醒，以及 5 组限频音效 / 触感；减弱特效保留机制信息。
- [x] Step 5：开放炼狱本地 3 SKU；完成 `1.99 / 6.99 / 4.99` 状态切换、购买 / 恢复 / 全清 / 单系列清空、整套应用、逐人换装、霓虹与炼狱独立收据 / 撤权 / 混搭 / 重启恢复。
- [x] Step 6：完整发布矩阵回归通过；Boss / 尸群 / 混合输出 `1.475x / 1.659x / 1.589x`，加权 `1.571x`。默认 137 路、霓虹 43 路、炼狱 43 路、双主题 × 双终焉 × 四角色 16 路截图通过；修复长屏角色详情、共享确认框和主题普通武器悬空持枪，并把融合持枪设为截图硬门禁。
- [ ] Step 7：TestFlight 后续执行；本次没有提交、推送、导出或上传，真机持续帧率、温升与内存峰值留在设备验收。

## 阶段 76 · 极地极光 / 终焉·绝对零度第三套与三系列收口（2026-08-01）

- [x] 最终产品目录收口为三套：霓虹雷暴 / 雷霆、炼狱赤焰 / 炼狱、极地极光 / 绝对零度；第四候选系列已从总方案、发布范围、交接、阶段文档和后续路线中移除。
- [x] 新增 `design/26_polar_aurora_absolute_zero_phase3_inventory.md`，冻结主题、权益、三 SKU、四件套、视觉语法、机制、平衡、来源和验收矩阵。
- [x] 极地运行时共 168 个确定性文件：4 立绘、44 战斗帧、72 原生按钮、8×3 免费武器涂装、7 个终焉装备素材、12 个后视真实握持方向、4 帧背挂极光冰翼和主题标题。
- [x] 绝对零度战斗表现：6 帧脆化、8 帧碎冰、7 帧一代冰晶波、8 帧极光冻原、8 帧防线反击、8 帧觉醒，以及 5 个独立 SFX；全部来自已登记的生产母版与可重复构建器。
- [x] 四角色终焉持枪使用 380×520 后视融合模型，枪托抵肩、双手真实握持、枪口锚点分左 / 中 / 右；极光冰翼在人物背后，不生成前景浮枪。
- [x] 本地演示商品接入主题 `1.99`、完整包 `6.99`、主题拥有者升级 `4.99`；支持整套装备、全局主题、逐角色换装、三主题混搭、恢复、单系列撤权和总撤权。
- [x] 绝对零度机制：4 / 5 次脆化触发普通 / Boss 碎冰；护甲三击蓄能 + 9 秒反击；宠物有限极光冻原；四件套向最密集区释放独立冷却且不递归的一代冰晶波。
- [x] 满级审计计入所有永久 / 局内技能、散射、多弹道、穿透、宠物、护甲和套装：Boss `1.342x`、密集 `1.752x`、混合 `1.550x`、加权 `1.547x`，处于 `1.52x–1.58x` 锁定带宽。
- [x] 自动回归扩为 3 主题 × 3 终焉武器 × 4 角色共 36 路交叉战斗；另有极地主题 43 路和绝对零度商品 / 脆化 / 碎冰 / 冰晶波 / 冻原 / 反击 / 觉醒专项路由。
- [x] 收口回归发现并修复截图工具首页先读本机旧存档、后切主题却不重建页面的假阳性；首页现统一在主题权益覆盖后重建，极地标题、原生比例按钮、副标题和入口强调色均稳定为冰蓝语义。
- [x] 最终 Release Candidate 通过：默认 / 双语 / 长屏 `148` 路、霓虹 `43` 路、炼狱 `43` 路、极地 `43` 路、三主题 × 三终焉 × 四角色 `36` 路、绝对零度专项 `11` 路，共 `324` 路真实 Godot 截图。
- [ ] Owner 真机验收极地长短按钮、四角色全部免费武器开火、三把终焉武器跨主题组合、冰晶波方向、边缘碎冰、背挂极光冰翼、持续 FPS / 温升和扬声器 / 耳机实听。
- [ ] Apple 阶段：接 StoreKit 2、已验证交易、pending / cancel / failure、退款撤权、Sandbox / TestFlight 实购和 App Store Connect 三系列商品元数据。

## 阶段 77 · 全主题主 Logo 与战斗人物 1.5× 表现升级（2026-08-01）

- [x] 默认、霓虹雷暴、炼狱赤焰、极地极光四套首页主 Logo 统一改为有效像素裁切后的 1040×500 展示框；不拉伸原图，也不再把设计板透明留白计入视觉尺寸。
- [x] 为炼狱、极地源设计板补充数据化展示区域；炼狱额外使用暗底抠除 shader，清理放大后暴露的画板底色和边缘分隔线。
- [x] 关卡内四角色完整表现 rig 统一放大至 `1.50×`，以可见脚底为锚点回提，确保人物变大但不沉入经验条或血条。
- [x] 枪械真实握持、枪口锚点、开火闪光 / 光锥 / 热浪 / 分叉电弧、主题背挂特效、觉醒环和角色周边随人物层级同步换算；碰撞、射程和数值半径保持不变。
- [x] 宠物横移至 `x=800`，技能栏改为 6 列并上移收紧；932 组角色 / 武器帧静态审计无重叠，技能最小净距 `72.6 px`、底部资源最小净距 `7.2 px`。
- [x] 四主题首页与默认先锋 / 霓虹电弧 / 炼狱火焰 / 极地冰霜代表战斗截图已逐张复核；后续仍需 Owner 在真机确认 1.50× 人物带来的最终战场占比和手感。

## 阶段 78 · 第四套流光黑金 Step 0 文案与原型（2026-08-01）

- [x] 明确第四套不是已取消“黑曜铸炉”的复活，而是新的通关后毕业系列：鎏金永夜 / 终焉·黄金律。
- [x] 新增 `design/27_gilded_eclipse_golden_law_phase4_proposal.md`，覆盖命名、商品文案、四套解锁节奏、视觉语法、四角色、UI / Logo / 基地、四件套、战斗表现、成长曲线、生产步骤和永久验收。
- [x] 生成并入库两张非运行时原型：四角色 + UI / Logo / 基地综合色板，以及四件套 + 六段固定底部战斗 VFX 方向板；提示词与评审结论已记录并登记素材索引。
- [x] 建议门禁冻结为炼狱通关 30、霓虹通关 50、极地通关 80、黑金通关 99 且任意角色 Lv.40；已拥有权益优先于进度隐藏。
- [x] 建议数值口径冻结为 Lv.1 `1.20x–1.30x`，满级武器攻击 / 护甲防御单槽属性 `2.00x`，真实满配攻击 / 防御审计带 `1.90x–2.05x`，避免四件各自 2x 后指数相乘。
- [x] Owner 已确认正式中英文名、黑金门禁、两倍属性口径与 `1.99 / 6.99 / 4.99` 继续沿用；阶段 80 已完成对应本地运行时、商品和战斗数值。

## 阶段 79 · 鎏金永夜 / 黄金律 Step 1A 顶级详细原型（2026-08-01）

- [x] 将最初两张粗方向图扩展为十一张相互约束的非运行时母版：四角色正 / 后视服装、八免费武器、四件套、Logo / 原生控件 / HUD / 基地、后视握持与五拍后坐、十段战斗 VFX、9:16 实战比例和四屏商品流程。
- [x] 视觉规则锁定为 `74%` 镜黑 / `18%` 暖金 / `8%` 白金；金必须表现为丝带 / 液态光墨，不得与炼狱火、霓虹电或极地冰混淆。
- [x] Owner 指出中央开火姿势不够：补做 `golden_law_true_grip_three_direction_master_v2.png`，覆盖四角色 × 左上 / 正上 / 右上共 12 格；双手、肘肩、躯干、枪械、后坐、枪口、弹道和人物背后的鎏金签名必须整体随方向变化。
- [x] 手机实战合成按 `1.50×` 人物合同验证：人物、枪械、背后效果和天隼明确可读，同时不遮挡僵尸、弹道、基地与 HUD。
- [x] 所有生成提示词、引用、逐张评审和运行时限制写入 `prompt_log.md`，十一张文件登记进 `OUTSOURCER_ASSET_INDEX.json`；概念板文字不作为本地化来源，控件不得从画板拉伸。
- [x] 原型入库后完整验证通过：素材包 `10,745` 文件、99 关数据、`392` 个 `res://` 引用、关卡压力、卡牌导演、Godot headless boot 与 M1 smoke；本轮没有改变任何运行时数据或玩法。
- [ ] 后续 Step 1B 才生产透明立绘、四角色 × 三向融合持枪攻击帧、八免费武器三形态、原生控件与标题运行时文件；本轮没有新增主题 ID、权益、商品、数值或 Apple 接入。

## 阶段 80 · 鎏金永夜 / 黄金律本地 App 完整接入（2026-08-01）

- [x] 冻结第四套名称、显示门禁和价格：通关 99 + 任意角色 Lv.40 后出现；主题 `US$1.99`、完整包 `US$6.99`、主题拥有者升级 `US$4.99`；已拥有权益不受进度回滚隐藏。
- [x] 生产 168 个独立 runtime 文件：四角色立绘 / 44 帧战斗动作、72 个原生尺寸按钮、八免费武器三形态黑金涂装、四件套、四角色 × 左 / 中 / 右 12 张后视双手握持、背后鎏金开火签名和纯净主 Logo。
- [x] 接入黄金律四件套：裁决叠层 / 黄金裁决、四件黄金敕令、天隼敕印、永夜反击、满级觉醒；6 组语义序列与 6 个 SFX 绑定真实事件，敕令仅一代且不会递归。
- [x] 本地演示商品、购买确认、主题拥有者补差、恢复、系列清空、整套装备、逐角色换装、撤权回退和中英文文案全部接通；未伪造 Apple verified 权益。
- [x] 数值审计：一级物理枪 `1.205x`；满级 Boss `1.995x`、密集 `2.090x`、混合 / 加权 `2.043x`；永夜甲裸 HP `1.888x` 反应装甲，另有一层额外破防盾与有限修复。
- [x] 永久回归锁定四主题、四角色 × 三方向真实握持、原生按钮、免费涂装、premium 身份隔离、门禁顺序与撤权安全；26 路第四套真实截图全部通过。
- [x] 人工截图闭环发现并修复两处自动审计漏网问题：主 Logo 裁切混入原型板右侧控件 / 第二 Logo 残片；黄金敕令多目标命中重复显示通用穿透长句。
- [ ] Owner 真机验收第四套菜单、设置 / 换装、四角色三方向、全部黄金律事件、减少特效、持续 FPS / 温升与扬声器 / 耳机。
- [ ] Apple 阶段：接 StoreKit 2、已验证交易、pending / cancel / failure、退款撤权、Sandbox / TestFlight 实购和 App Store Connect 四系列商品元数据。

## 阶段 81 · 黄金敕令深度渲染替换（2026-08-01）

- [x] 根据 Owner 实机截图确认旧黄金敕令由程序圆环 / 直线构成，虽能表达多目标命中，但明显低于黑金套装的素材质量标准。
- [x] 使用内置图像生成分别制作“王权敕印聚能”和“裁决落地爆发”两张独立母版；完成色键透明化、绿色反光收敛和来源 / 最终提示词登记。
- [x] 黄金敕令改为七帧“聚能 → 降临 → 流金冲击释放”；黄金裁决同步复用独立落地母版的八帧冲击序列，不再使用几何占位图。
- [x] 新序列保留真实多目标位置、单代不递归、独立冷却、错峰触发和透明安全边距；101 组 / 845 帧战斗 VFX 语义检查通过。
- [ ] Owner 真机确认多目标同时触发时的亮度、目标可读性和减少特效模式；如需再收敛，只调运行时尺寸 / 亮度，不退回线条占位素材。

## 阶段 82 · App Store 全运行时占位表达清零与全主题 Logo 二次放大（2026-08-01）

- [x] 五套首页主标题统一提升至 `1040×560` 展示框；默认 / 霓虹按透明有效像素紧裁，炼狱 / 极地从原始综合色板重新提取独立主标题，黑金使用纯净独立 Logo，全部保持比例不拉伸。
- [x] 修复放大后暴露的真实素材问题：炼狱标题不再带综合色板边线 / 邻栏，极地标题不再带右侧分隔线 / 下方徽章碎片；五套 1080×1920 Godot 菜单截图逐张复核无碰撞或裁切。
- [x] 对全部 `101` 组运行时 VFX 生成六张带 ID / 来源标签的峰值审计表；确认最后六组程序占位感素材并全部换成独立深渲染母版：黄金律审判、天隼、反击、觉醒、僵尸狂暴和人物升级。
- [x] 狂暴峰值层级移至僵尸身后，保留怪物轮廓；人物升级统一为金青一体化上升光柱；天隼锁定向下俯冲、反击锁定由基地向上、觉醒锁定人物背后。
- [x] 永久门禁新增六组 rendered-source contracts；去除升级光柱的旧硬边例外。当前 `101 sequences / 850 non-empty frames` 全部通过普通透明安全边距、硬裁切、帧差异、方向和来源验证。
- [x] 完整审计结论写入 `design/assets/app_store_runtime_placeholder_audit_2026_08_01.md`；动态弹道 / 锁定 / 范围边界仅作为真实玩法语义保留，不再把它们当作静态技能美术。
- [x] 清除角色详情里最后一个硬编码菱形占位：被动栏改用角色元素成品图标，异常路径也只回退到成品天赋图标。
- [ ] Owner 真机确认五套首页主标题的最终视觉占比，以及狂暴 / 升级 / 黄金律多目标峰值在真机亮度和减少特效模式下的舒适度。

## 阶段 83 · App Store UI 图标 / 裁片占位清零与霓虹按钮收光（2026-08-01）

- [x] 将 `sprites/ui` 的 `102` 张非重复运行时位图重新生成五张原尺寸审计表；发现并清除同一灰色方框内的扁平资源 / 元素 / 系统图标族，以及五张从概念板误裁的碎片型 HUD 皮肤。
- [x] 深渲染并原路径替换 `32` 张资源：14 张金币 / 星星 / XP / 元素 / 系统图标，13 张卡牌 / 战术 / 目标优先级图标，5 张关卡卡 / 连击 / pill / plate / 伤害数字原生比例表面。
- [x] 新图标保留 256×256 与透明安全边距；五张表面保留独立渲染角件，只延展安静中段，不拉伸转角；自动门禁锁定来源、数量、尺寸、色深、透明边距与绿边。
- [x] 霓虹主题只收敛按钮位图：边框亮度降至 0.74、边框色度 0.82、半透明外发光 0.78，中央高光仅轻降至 0.90；按钮形状、长度族、文字、人物、武器、特效及其他主题均不改。
- [x] 完整 Release Candidate 回归通过：M1 smoke、174 路基础界面、43 路霓虹、43 路炼狱、43 路极地、64 路跨主题 / 角色和 11 路绝对零度截图全部无回归；霓虹菜单 / 设置 / 角色 / 配装 / 战斗截图人工复核文字层级清晰。
- [ ] Owner 真机确认新版金币 / 资源栏图标在最小 HUD 尺寸下的辨识度，以及霓虹按钮在低亮度 / 高亮度屏幕上的舒适度。

## 阶段 84 · 全局 Boss 血条标题分层修复（2026-08-02）

- [x] 根据 Owner 真机截图定位为共享 Boss HUD 的排版问题：全局字号放大后，标题实际字体与描边总高度超过旧 `28 px` 文本盒，且旧血条仅距标题顶端 `34 px`，导致文字下沿被裁切并与血条重叠。
- [x] 所有主题、所有 Boss、中英文统一改用独立 `56 px` 标题区；血条轨道保持原绝对位置，标题上移并与轨道保留 `10 px` 净距，不挤压波次条或战场区域。
- [x] Boss 长英文名称 / 弱点 / 百分比组合启用单行自适应，保留完整文案并在必要时缩小到安全字号，不换行、不截断、不压住血条。
- [x] 静态 HUD 审计与 M1 smoke 新增永久门禁，检查波次条、Boss 标题、轨道、填充条的边界、容纳高度和间距；完整发布验证通过。

## 阶段 85 · 三模式瞄准合同复核与自动多弹道纠偏（2026-08-02）

- [x] 修复自动多弹道只判断“敌人位于扇形角度内”、却不能保证真实射线命中的边界；2–5 条弹道现在整体旋转，使其中一条精确穿过当前自动目标中心。
- [x] 扇形纠偏只做整体刚体旋转，所有相邻弹道继续保持固定夹角；不会把每颗子弹改成独立追踪，也不改变弹道数、伤害、衰减、射速或技能数值。
- [x] 手动锁定合同复核：iPhone 双击僵尸锁定、双击空地解除；锁定目标持续覆盖自动选择，目标死亡 / 越线后由既有逻辑清除。
- [x] 方向锁定合同复核：按住 `0.30 s` 后进入手动方向瞄准，拖动实时更新；按住期间优先于自动目标与点名锁定，松手保留 `0.18 s` 收尾后恢复自动瞄准。
- [x] M1 smoke 新增自动 2–5 弹道逐档精确命中、固定夹角、触控双击信号、点名锁怪 / 空地解除和自动开火持续追踪回归；完整发布验证通过。

## 阶段 86 · 局内技能详情移动端正文放大（2026-08-02）

- [x] 根据 Owner 真机截图将技能详情 `All Levels / 全部等级` 下方五级列表从 authored `13` 提至 `15`，实际运行字号由 `20 px` 提至 `23 px`，并将行距从 `4 px` 提至 `7 px`。
- [x] 技能长说明从 authored `15` 提至 `17`，实际运行字号由 `23 px` 提至 `26 px`；Tags / 标签行同步从 `22 px` 提至 `23 px`，保持信息层级一致。
- [x] 重新分配列表、说明、标签与关闭按钮纵向区域；说明框增至 `164 px`，四区之间仍保留 `8–12 px` 净距，关闭按钮底部保留 `24 px` 安全边。
- [x] 中英文都优先使用放大字号；若未来英文文案继续增长，只允许自适应缩回不低于旧发布字号，不能截断。M1 smoke 用真实中英文 Split Shot 文案验证字号、换行高度和所有区块间距。

## 阶段 87 · 黑金换装立绘裁切与按钮状态语义修复（2026-08-02）

- [x] 确认问题来自黑金服装母版的窄列机械裁片，而不是 Godot `TextureRect`：四张 720×980 运行图的有效人物宽度仅 `210–233 px`，肩甲、手臂和衣摆在源素材阶段已被切掉。
- [x] 保留四角色身份、脸、体型、服装和材质，分别横向补画完整前视全身图；正式运行立绘有效宽度提升至 `300–392 px`，头、肩、双臂、手、衣摆和双脚均在透明安全区内。
- [x] 换装页与全局主题页统一三态：已应用 / 已穿戴为不可点灰态，可应用 / 可穿戴为高亮主动作，未拥有为低饱和次级购买态；卡片状态明确显示“未拥有 / Not Owned”，按钮使用完整字号“购买 / BUY”。
- [x] 黑金构建脚本优先使用审核后的 V2 透明立绘，避免未来重建重新切回窄条；M1 smoke 锁定四张有效宽度及中英文三态按钮、可点击性和表面亮度层级。

## 阶段 88 · 全主题角色列表立绘统一身高与脚底线（2026-08-02）

- [x] 修复角色列表按完整透明画布宽度缩放、再用固定小窗裁切导致的视觉体量不一；列表改为读取人物真实非透明区域并按可见身高归一。
- [x] 四角色统一 `180 px` 可见身高与 `194 px` 脚底基线，逻辑立绘区域由 `118×126` 扩至 `148×196`；发型、肩甲、衣摆可越出旧头像小窗，但最终仍由整张卡片安全裁切。
- [x] 中文与英文分别使用卡片内独立纵向位置，保持人物横向中心、脚底线、文字起点和动作按钮互不碰撞；壮汉与少女只保留真实体型宽窄，不再有额外缩放差。
- [x] 默认、霓虹、炼狱、极地、黑金五套中文角色列表以及默认 / 黑金英文列表完成真实 Godot 截图复核；无头顶裁切、脚底漂移、跨卡片、压字或按钮碰撞。
- [x] M1 smoke 永久检查四行均使用统一可见身高、脚底线和全身展示区域，防止以后更换立绘时回退到按画布裁切。

## 阶段 89 · 波次出怪随机分散与防聚簇（2026-08-02）

- [x] 定位“随机却仍成坨”的真实原因：同组怪连续落在旧左 / 右 `210 px`、中路 `160 px` 固定窄带，`rush` 又会把整波全部压进中路；独立 `randf_range` 无法阻止相邻结果靠得很近。
- [x] 普通怪安全出生带拓宽为左 `150–430`、中 `300–780`、右 `650–930`、散开 `150–930`；保持突袭 / 钳形 / 护送 / 围城的队形语义，不把所有关卡退化成无规则全屏随机。
- [x] 每次出生随机生成 9 个候选，选择距离最近 6 个出生点及入口区存活怪最疏的位置；最近一只额外加权避让，Y 在 `158–222` 内轻微错峰，解决连续重叠和“横向几坨”。
- [x] Boss 继续使用旧聚焦通道与固定 `y=190`；数量、间隔、HP、伤害、掉落、波次总时长和关卡压力均未改变。
- [x] M1 smoke 固定随机种子对四种通道各采样 24 次，要求覆盖至少 85% 通道、连续近邻不超过 3 对、历史恒定为 6；另用 1,000 个随机种子审计，最差覆盖 `88.5%`、连续近邻最多 2 对。12 只混合僵尸按真实中位 `0.60 s` 节奏的 Godot 战斗截图人工复核已横向铺开且纵向错峰。

## 阶段 90 · 技能图鉴详情移动端二次放大与升级按钮收文案（2026-08-02）

- [x] 只放大技能图鉴详情，不扰动已经验收的角色 / 武器 / 护甲 / 芯片 / 宠物详情：技能名、等级徽章、标签、摘要、区块标题、核心数据、五级数值和战术说明全部提高一档。
- [x] 五级数值行由 `58 px` 增至 `64 px`，字号与行高同步成长；中英文长效果值保持自动换行，内容区继续使用真实滚动容器。
- [x] 底部升级按钮由“升级技能 150经验 / Upgrade · 150 XP”收为价格式 `150★`，保留悬停 / 辅助说明明确真实消耗为 `150 XP`；按钮字号提高后仍不越出原生边框。
- [x] M1 smoke 永久检查等级行 / 效果值 / 战术正文目标字号、行高、短价格文案和按钮真实字宽；标准屏中英文顶部 / 底部滚动状态人工复核无覆盖。
- [x] 全部 16 个技能 × 中英文共 32 路详情，加一张既有英文代表页，共 `33` 路真实 Godot 截图通过，`error_count=0`；截图只输出到 `/tmp`，不纳入 Git。

## 阶段 91 · 五主题技能语义标签边框与双语基线重制（2026-08-02）

- [x] 定位旧标签边界发虚的根因：通用 `ui_map_pill_skin` 无视调用方传入的主题强调色，在深色纹理卡片上只剩断续装饰线，产生未对齐错觉。
- [x] 技能图鉴列表改用专用语义标签组件：统一 `40 px` 高度、`2 px` 实线边框、稳定圆角 / 内边距 / 阴影与垂直居中；类型标签和能力标签使用两级色彩，不再与普通按钮共用皮肤。
- [x] 默认、霓虹、炼狱、极地、黑金五套分别建立数据驱动 `tag_palette`，覆盖边框、填充和文字六项颜色；中文与英文继续使用相同几何合同。
- [x] 首轮人工截图发现标签上沿离技能标题过近，二次调整为标题、标签、效果摘要三段稳定基线；自动审计随后发现两条长摘要需要双行高度，再扩至 `80 px` 后清零裁切。
- [x] 新增五主题 × 中英文 `10` 路真实 Godot 截图矩阵及 M1 smoke 门禁；检查全部 16 个技能标签的边框、角色色级、文字容纳、总宽度和段间净距。最终 `10/10` 路 `error_count=0`，截图保留在 `/tmp/zf-skill-tag-theme-review/`，不纳入 Git。

## 阶段 92 · 局内技能 HUD 放大、半屏换行与主动技能点击合同（2026-08-02）

- [x] 左侧已获得技能从旧 `46×58` 小图标升级为 `96×120` 卡片，技能图标增至 `66×66`，等级改用移动端有效 `23 px` 字号；中英文分别显示 `等级1 / Lv.1`。
- [x] 技能区不再继承全屏横向锚点，固定占用 `x=18–530` 的左半屏；每行最多 5 个，第 6 个起向上换行，底边与右侧 `120×120` 主动技能按钮对齐。
- [x] 已获得技能改为显式单击 / 长按显示说明，不再仅凭悬停遮挡战斗；说明保持显示，供手机用户读完后再继续操作。
- [x] 主动技能可释放时短按立即释放且不弹说明；释放进入冷却后按钮仍可点击，再次短按显示说明；任意状态长按只显示说明，并吞掉同一次松手信号，保证绝不误释放。
- [x] M1 smoke 永久覆盖左半屏边界、移动端字号、单行 / 双行换行、单击详情、冷却态说明与长按防误触；新增中文双行、英文满技能、中文冷却说明、英文待释放和黑金满技能 `5` 路真实 Godot 截图，最终 `5/5` 零审计错误，输出在 `/tmp/zf-battle-skill-interaction-review/`，不纳入 Git。

## 阶段 93 · 黑金冰霜少女三方向全身战斗原型修复（2026-08-02）

- [x] 确认母版三方向均有完整双腿与靴子，真正缺陷来自运行时导出脚本只保留最大连通块：深色腿甲 / 鞋与黑色跑道相近，被错误删除，只剩上身和衣摆。
- [x] 按已验收身份、银白长发、黑金服装、黄金律重炮和后视双手持枪合同，重做冰霜少女左 / 中 / 右三方向专用色键母版；三张均保留完整头、躯干、髋、双腿、双靴和枪口安全边。
- [x] 黑金构建脚本只对冰霜少女三方向启用专用色键提取并清除绿边，其余 9 张已验收握持原型不变；输出路径及 `380×520` 战斗合同不变。
- [x] 构建期检查完整轮廓与双侧下肢覆盖；视觉素材门禁额外要求三张图最下 8% 的脚部横向跨度至少 `150 px`，可直接拦截旧半身 / 单衣摆回归。
- [x] 强制刷新 Godot 导入缓存后重拍左 / 中 / 右三张 1080×1920 真运行画面；三张均完整显示双腿和双靴，枪口、弹道与左 / 中 / 右方向一致，运行时审计与图片分析 `3/3` 通过。最终截图仅保存在 `/tmp/zf_gilded_frost_fullbody_final/`，不纳入 Git。

## 阶段 94 · 霓虹火焰少年左右枪口竖屏抬升（2026-08-02）

- [x] 保留 Owner 认可的背面三分之四站姿、人物身份、霓虹服装和雷霆末日炮，仅重做右向上半身持枪动力学并严格镜像为左向；中间直射母版及运行图不改。
- [x] 左右枪管由近水平姿势抬至明显斜上方，运行图霓虹枪管轴线实测均为 `38.2°`，让侧向锁定仍落在竖屏上方主要刷怪区域。
- [x] 两手继续分别连接扳机握把和前托，肩、肘、腕、头部视线随枪械自然抬升；完整发型、枪口、双腿和双靴均保留透明安全边。
- [x] 视觉素材门禁新增左右枪管至少 `35°` 且方向符号正确的检查；构建后中间运行图 SHA-256 保持 `340a2762...3f07dfc`，证明未被这次修改扰动。
- [x] 刷新 Godot 导入缓存后完成左 / 右两张 1080×1920 真运行截图；人物、霓虹翼、枪口方向和战场上方射击走廊一致，运行时与图片审计 `2/2` 通过。截图仅保存在 `/tmp/zf_neon_blaze_raised_aim_final2/`，不纳入 Git。
- [ ] Owner 真机确认新左右斜射姿势的视觉角度和战斗阅读性。

## 阶段 95 · 全角色 / 全套装战斗人体尺寸归一（2026-08-02）

- [x] 定位战斗人物大小漂移的根因：旧逻辑按整张 `380×520` 合成图缩放，枪管长度、披风、裙摆、光翼和枪口光都会改变有效外框；角色等级还会额外放大人物，导致同一角色换武器 / 套装后也不一致。
- [x] 新增数据驱动人体标尺，覆盖默认角色动作以及雷霆、炼狱、绝对零度、黄金律四套真握持模型，共四角色 × 左 / 中 / 右；每张姿势独立记录人体头脚高度、脚底点与人体横向中心，明确排除枪械、披风尾迹、翅膀和枪口光。
- [x] 战斗运行时先按头顶到脚底归一为统一 `420 px` 源标尺，再放回既有 `1.50×` 战场展示；最终所有人体均为 `322.56 px` 设计高度、脚底固定在 `y=1752`。人物等级不再改变模型尺寸，只保留数值和成长徽章。
- [x] 左 / 中 / 右换姿势时同步更新人物缩放与脚底锚点；已内嵌在合成图中的枪械随人体等比恢复，独立主题光翼 / 火翼 / 冰翼 / 黑金流光继续在人体之外自由延展。
- [x] 枪口坐标同步经过同一人体缩放和锚点变换，保证子弹仍从真实枪口发出；底部 HUD 静态审计覆盖 `944` 个角色 / 武器帧，最小资源条净距 `6.9 px`。
- [x] 新增五主题 × 四角色 × 三方向共 `60` 路真实 1080×1920 Godot 截图回归；再以统一头顶线 / 脚底线裁切复核人体，枪械与特效允许越界但人体体量和脚底基线一致。最终 `60/60` 路零运行时 / 图像审计错误，截图保留在 `/tmp/zf_body_scale_regression_v1/`，不纳入 Git。
- [x] 数据验证、视觉素材、HUD 重叠和 M1 smoke 均新增永久门禁；完整发布验证通过。

## 阶段 96 · 换装页人物透明画布裁切修复（2026-08-02）

- [x] 确认 `Follow Global` 在全局黑金主题下与 `Gilded Eclipse` 正确解析为同一张钢铁先锋黑金立绘；两处同时显得窄小的根因是 UI 将整张 `720×980` 透明画布适配进缩略图，而不是人物素材缺失或解析成两张图。
- [x] 换装页所有顶部预览和列表缩略图改为先读取真实 alpha 可见范围，仅移除外围透明画布，再以保持比例方式完整适配人物；可见范围额外保留 `10 px` 安全边，头发、肩甲、手臂、披风和双脚均不裁切。
- [x] `Follow Global` 与具体主题卡共享同一解析 / 裁边规则；同一主题下显示区域完全一致，默认、霓虹、炼狱、极地与黑金五套也统一获得更稳定的视觉体量。
- [x] M1 smoke 遍历中英文全部六种换装选择，要求每张缩略图使用 alpha 区域适配、显示区域完整包围真实人物并保留四周安全边。
- [x] 黑金钢铁先锋英文换装页完成真实 1080×1920 Godot 截图复核，`Follow Global` 与 `Gilded Eclipse` 两处人物均完整、等大、无压字或边框碰撞；截图保留在 `/tmp/zf_appearance_portrait_fix/`，不纳入 Git。

## 阶段 97 · 全主题换装页统一英雄半身构图（2026-08-02）

- [x] 根据 Owner 对电弧少女黑金缩略图的复核，确认“完整全身”仍会让细长服装在手机小卡片中显得弱小；换装页因此从全身素材适配改为统一的英雄半身取景，而不是继续按人物天然宽度补偿或横向拉伸。
- [x] 所有角色、所有主题列表缩略图统一保留人物真实可见轮廓顶部至 `62%` 高度，上方主预览保留至 `70%`；两者都额外保留 `10 px` 头发安全边，并按显示框宽高比围绕人体中心截取。
- [x] 黑金、默认、炼狱、霓虹、极地人物现在共享头部高度、中心线和取景深度；壮汉 / 少女的自然体型宽窄、武器和肩甲外扩继续保留，不通过非等比缩放伪造一致。
- [x] 截图工具补充高层换装弹窗滚动定位，能够真实检查列表下半部，而不是误滚动被遮挡的角色列表。
- [x] 四名角色分别完成顶部与下半部共 `8` 张真实 1080×1920 Godot 截图复核，覆盖五套主题与 Follow Global；无削头、偏心、按钮碰撞或越框。M1 smoke 在中英文下遍历六种外观选择，并永久检查半身取景比例、头部安全区、人体中心与显示框比例。

## 阶段 98 · 黑金出战页人物体量与黄金律武器完整构图（2026-08-02）

- [x] 定位四名黑金人物在出战页“框大人小”的根因：页面仍按整张 `720×980` 透明画布使用固定 `378 px` 图宽，而黑金四张人物的真实 alpha 宽度明显更窄，导致可见人体比默认 / 霓虹 / 炼狱 / 极地小一档。
- [x] 黑金出战立绘改为按真实 alpha 可见宽度归一到 `260 px` 的主视觉目标，并以 `460–540 px` 图宽限制保护自然体型；继续保留 `10 px` 头发安全边、原始比例和上半身裁切，四名人物不横向拉伸。
- [x] 黄金律武器旧图含有右下角重复细节插图且主体贴边，已生成一张独立完整的黑金流金重炮原型，去掉展示倒影 / 重复小图，并重建枪口、后机匣和双握把。最终透明图为 `384×384`，四周均有安全留白。
- [x] 出战页对黄金律 V2 图标按真实 alpha 区域再加 `12 px` 安全边适配；既放大主体，又保证枪口、枪尾和握把不被 Weapon Panel 裁切。其他武器显示逻辑不变。
- [x] 四名黑金角色各完成一张 1080×1920 真运行截图；另以火焰少年横向拍摄默认、霓虹、炼狱、极地四套作尺度基准。共 `8/8` 路截图审计通过，人工复核无削头、比例漂移、武器切边、重复插图或文字 / 边框碰撞；输出保留在 `/tmp/zf_gilded_loadout_fix/`，不纳入 Git。
- [x] M1 smoke 新增四角色黑金可见人体宽度、图宽保护区、黄金律 V2 路径、透明安全边和完整显示区域门禁，防止以后重新出现小人或裁枪。
- [x] 完整发布验证通过：素材包 `11,319` 文件、数据 `99` 关 / `20` 僵尸 / `8` Boss / `16` 技能、`401` 个 `res://` 引用、99 关压力、99 关卡牌模拟、`1,092` 个战斗视觉素材、Godot 启动、M1 smoke 和 `git diff --check` 均通过。

## 阶段 99 · 炼狱赤焰主菜单 Logo 二次放大（2026-08-02）

- [x] 确认炼狱 Logo 的 `1040×340` 原图含有大量概念稿暗色横向舞台，真正金属标题只占中间区域；暗底着色器虽能抠除背景，但旧布局仍按整张图宽度适配，导致主体偏小。
- [x] 为炼狱主题单独配置对称展示窗 `[210, 0, 620, 340]`，只裁掉无效左右舞台，不缩边、不重画、不影响默认 / 霓虹 / 极地 / 黑金主题。
- [x] 最终 1080×1920 真运行截图中，Logo 左右各保留约 `145 px` 安全区，顶部机械尖塔和底部熔火尖角完整，与副标题保持约 `80 px` 净距；无触边、压字或按钮位移。截图保留在 `/tmp/zf_infernal_logo_review/menu_logo_infernal_final.png`，不纳入 Git。
- [x] M1 smoke 锁定炼狱主题展示窗和运行时 AtlasTexture 区域，防止之后重新把概念稿留白算进 Logo 尺寸。
- [x] 完整发布验证通过：素材包 `11,319` 文件、数据、`401` 个资源引用、99 关压力、99 关卡牌模拟、Godot 启动、M1 smoke、最终截图图像分析和 `git diff --check` 全部通过。

## 阶段 100 · 小关卡双模式直达按钮与信息重排（2026-08-02）

- [x] 删除关卡卡片内重复的 `进入 / Enter` 与 `挑战模式 / Challenge Mode` 二级按钮；`普通 / Normal`、`挑战 / Challenge` 本身改为两枚完整可点击入口。
- [x] 每枚模式按钮直接承载自己的三星进度；挑战未解锁时在按钮内部显示锁标识、降低表面饱和度并保持路由守卫，普通三星后原位转为可点击状态。
- [x] 使用五主题均已有的原生 `412×88` 按钮模型，卡片高度调整为 `192 px`；两枚按钮视觉区域和触控区域均不重叠，也不拉伸按钮素材。
- [x] 关卡信息重排为左侧三位编号 / 当前状态、中部名称 / 战力 / 弱点、右侧双模式入口；弱点胶囊扩宽，修复英文 `Weak: Frost / Physical` 与 `Current` 相撞。
- [x] 默认主题中英文、黑金主题英文以及已填充普通 / 挑战星级状态完成真实 Godot 截图复核；无文案截断、按钮碰撞、星级越框或锁定状态歧义，截图仅保存在 `/tmp/zombie_fire_level_modes_final/` 与 `/tmp/zombie_fire_level_modes_review_v2/`，不纳入 Git。
- [x] M1 smoke 永久检查新模式节点、旧重复入口消失、星级内嵌、挑战锁标识、模式身份、最低触控高度和两枚命中区域不重叠。

## 阶段 101 · 角色列表大立绘与独立文字栏重排（2026-08-02）

- [x] 四张角色卡统一提升至 `310 px` 展示高度；人物栏由旧 `148×196` 小头像扩大为 `220×282`，真实人物轮廓统一到 `250 px` 高并共用 `y=276` 脚底基线。
- [x] 标题、标签与属性说明整体右移至独立 `x=260` 文字栏，与人物展示区保持至少 `20 px` 净距；右侧装备 / 解锁按钮保留独立操作区，不压人物或说明。
- [x] 中文属性由自然换行改为明确的“定位 / 元素 / 下级成长”语义分行，消除“物 / 理”“火 / 焰”等孤字断行；英文采用同构的 Role / Element / Next Lv. 分行。
- [x] 默认、霓虹、炼狱、极地、黑金五主题 × 中英文共 `10` 路真实 Godot 截图完成回归；四名人物均完整显示、等高落脚，无削头、压字、按钮碰撞或卡片越界。
- [x] M1 smoke 永久检查卡片高度、人物展示包络、真实可见高度、统一脚底基线以及三组文字节点必须位于人物栏右侧。

## 阶段 102 · 全主题出战页人物半身与无框枪械统一（2026-08-02）

- [x] 以 Owner 认可的默认钢铁先锋出战半身构图为唯一标尺：保留其原 `378 px` 画布显示宽度，并换算出统一人物真实可见高度；五主题 × 四角色全部按 alpha 人物轮廓等比缩放。
- [x] 所有人物统一保留 `10 px` 头部安全边，并按真实可见轮廓而非透明画布居中；壮汉、少女、衣摆和肩甲继续保持自然宽窄，不横向拉伸。
- [x] 出战页武器不再使用带装饰框的库存图标，统一优先读取无边框 `handheld` 枪体；主题只替换八把普通武器的对应枪体，四把终焉武器继续保持各自商品身份。
- [x] 所有枪械按真实 alpha 外框加比例安全边后适配同一 `296×296` 展示标尺，枪口、枪托和握把完整保留；黄金律使用独立无重复插图的 V2 展示图，不再读取带概念稿副图的持枪素材。
- [x] 新增五主题 × 十二武器共 `60` 路真实 1080×1920 出战页截图矩阵，同时循环覆盖四名角色；自动布局 / 图片审计 `60/60` 通过，人物与枪械对照表人工复核无大小漂移、旧边框、裁切、压字或卡框。截图仅保存在 `/tmp/zf_loadout_presentation_20260802/`，不纳入 Git。
- [x] M1 smoke 遍历 20 张人物立绘及所有默认 / 主题 / 终焉枪体，永久检查统一人物标尺、头部安全边、可见轮廓居中、完整枪械区域和一致有效占比。

## 阶段 103 · 挑战结算页统一英雄半身像（2026-08-02）

- [x] 结算页英雄高光栏从 `108×108` 小型全身图改为 `170×144` 半身视窗，结果卡对应增高到 `164 px`，人物具备与主标题相称的视觉存在感。
- [x] 五主题 × 四角色共用同一 `280 px` 真实人物高度标尺、`8 px` 头部安全边和可见轮廓中心线；透明画布、枪械、披风及主题特效不再改变人物尺寸。
- [x] 姓名与本局高光保持独立文案栏；中英文最长英雄名及 `Defense Complete` 状态均不压人物、不碰右边框。
- [x] 五主题 × 四角色 × 中英文共 `40` 张真实 1080×1920 挑战胜利结算截图全部通过布局 / 图片审计；人工对照表确认半身取景、头部基线和人物高度一致。截图仅保存在 `/tmp/zf_result_portrait_review_20260802/`，不纳入 Git。
- [x] M1 smoke 永久遍历 20 张结果页人物素材，锁定半身模式、人物标尺、头部安全边、轮廓居中和实际裁切关系。

## 阶段 104 · 结算奖励与战力说明图标安全边距（2026-08-03）

- [x] 金币、经验奖励卡统一为 `30 px` 左右安全内边距，`54 px` 图标与标题 / 数值整组垂直居中。
- [x] 基准 / 终局 / 挑战说明条统一为 `28 px` 左右安全内边距，星形图标不再压住发光边框。
- [x] 奖励图标尺寸、左右净空与垂直基线写入 M1 冒烟门禁，并复跑全主题中英文结果页截图。

## 阶段 105 · 精品军械库跨主题商品陈列统一（2026-08-03）

- [x] 移除玩家商店直接按商品 `art` 显示战斗截图、风格板和概念拼图的做法；商品表新增明确的 `theme_roster / arsenal_grid` 陈列语义，旧图只保留为设计来源与兼容回退。
- [x] 四套主题商品统一使用四角色 `2×2` 装束半身陈列；所有人物共用 `212 px` 人体标尺、`8 px` 头部安全边和相同格位，保留壮汉 / 少女的自然体型差异。
- [x] 四套完整军械包统一按武器 / 护甲 / 芯片 / 宠物顺序展示真实运行素材；四格共用 `124 px` 长边标尺，不再混入边框、场景图或整张概念母版。
- [x] 黑金芯片与天隼素材通过数据化 `store_preview_region` 只取主物件，剔除母图右下角缩略变体和说明字；黑金护甲已升级为干净的单物件完整全身原型，不再依赖商店裁切区域。
- [x] 中英文各四个滚动停点共 `8` 张真实 Godot 截图完成全目录复核；四主题、八张首购商品卡的卡片尺寸、标题 / 说明 / 价格按钮和主题色边框均无裁切、乱码、压框或视觉语法漂移。截图保留在 `/tmp/zf_store_preview_review_20260803/`，不纳入 Git。
- [x] 数据验证锁定商品类型与陈列类型映射；M1 smoke 锁定 8 张首购卡、固定四格尺寸、人物 / 装备标尺、生产素材路径，并禁止 `source_refs` 重新进入玩家商店。

## 阶段 106 · 护甲原型完整性重制与永久门禁（2026-08-03）

- [x] 拉出并逐件审计全部 `10` 件护甲原型；6 件普通护甲确认是完整独立的背心 / 胸甲 / 防护服装备图标，4 件终焉护甲确认存在仅胸甲、无头全身或夹带副缩略图的问题。
- [x] 天穹导体甲、熔星战甲、永冻晶壁与永夜神盾全部重制为透明底、完整头盔、双臂、双腿、双靴、无武器、无副缩略图的独立全身装备原型，并沿用原有 ID / 数据引用 / 运行路径。
- [x] 黑金护甲移除旧 `store_preview_region`；护甲详情、护甲列表和四套军械库商品格统一读取同一张干净生产素材，不再以裁切补救原型缺陷。
- [x] 新增 `--armor-prototypes-only` 中英文专项回归：护甲全目录 2 张 + 全部护甲详情 20 张，共 `22/22` 张真实 1080×1920 截图通过布局与图片审计；人工复核完整头盔 / 四肢 / 靴部、边距、名称、等级徽章和关闭按钮。截图保留在 `/tmp/zf_armor_prototype_review_20260803_v4/`，不纳入 Git。
- [x] 资产验证新增四件终焉护甲的语义门禁：固定 `384×384`、透明非空、四边安全距、足够完整的全身高度、头盔 / 肩宽比例和大面积分离副图检测，后续无头、半身或重复插图素材会直接令校验失败。

## 阶段 107 · 角色详情页移动端小字重排（2026-08-03）

- [x] 角色详情页弹种亲和、角色 / 元素标签、属性标题与成长副值、技能标题 / 类型 / 说明、专属技能等级与逐级成长说明统一提升一档；主标题和底部主操作保持既有层级，不做无差别全页放大。
- [x] 专属技能升级区由“长成长说明挤在宽按钮左侧”改为两层布局：等级与原生 `286×112` 升级按钮同排，逐级成长规则在下方占满整行；长英文不再被按钮压窄，按钮同时满足全局 `88 px` 最小触控高度。
- [x] 属性卡高度按中英文分别提升到 `98 / 112 px`，技能行最小高度提升到 `118 px`；说明文字允许自然换行，较矮设备由详情内容区独立滚动承载，底部四个操作按钮持续固定。
- [x] 新增四角色 × 中英文 × 1080×2340 / 1080×2046 两种手机高度共 `16/16` 张真实 Godot 专项截图；长英文、标签、成长说明、按钮与边框均无截断、乱码或碰撞。截图保留在 `/tmp/zf_character_detail_readability_20260803_final/`，不纳入 Git。
- [x] M1 smoke 永久检查亲和摘要、标签、属性副值、技能说明与成长说明的最低有效字号，并锁定成长说明必须获得升级按钮两倍以上的整行宽度。

## 阶段 108 · 角色详情页整页字号二次提升（2026-08-03）

- [x] 按 Owner 的手机易读性复核，把放大范围从说明小字扩展到完整信息层级：角色名 / 等级、区块标题、亲和摘要、标签、属性标题 / 数值 / 成长、技能名 / 类型 / 说明、专属技能等级 / 成长规则均再提升一档；底部四枚已验收原生按钮保持尺寸不变。
- [x] 共享组件新增角色详情专用字号增量，武器、护甲、芯片、宠物详情不被连带放大；角色属性卡随字号同步增加 `8 px` 高度，技能行最小高度从 `118 px` 提升至 `132 px`，英文长句继续自然换行。
- [x] 角色名、等级、区块标题及所有正文语义节点进入 M1 smoke，最低有效字号分别锁定为 `50 / 28 / 29 / 24–32 px`；后续修改不能通过缩字重新塞回旧布局。
- [x] 专项视觉矩阵增加本次 Owner 截图对应的 `1080×1920` 标准竖屏，在原 `1080×2340 / 1080×2046` 基础上形成四角色 × 中英文 × 三屏高共 `24` 路回归；滚动内容与固定操作栏在三种高度下均保持独立，无压字、裁切、乱码或边框碰撞。

## 阶段 109 · App Store 上架前全量截图复核包（2026-08-03）

- [x] 在截图路由器新增 `--full-review`，去重合并最终发布矩阵、角色详情三屏高专项、五主题 × 十二武器出战页专项，以及五主题 × 四角色 × 中英文结算半身像专项。
- [x] 真实 Godot 运行并完成 `1,093 / 1,093` 张截图；覆盖全部人物、五套主题、十二把武器、十件护甲、十二枚芯片、十只宠物、十六项技能、二十类僵尸、八名 BOSS、十个战区、双语商店 / 设置 / 结算 / 战斗 HUD 及主要特效状态。
- [x] 截图路由、运行时布局检查与图片分析全部通过，清单条目与 PNG 文件均为 `1,093`，无丢图或重复标签。
- [x] 额外生成 `62` 页、每页最多 `20` 张的分类联系表，便于按主题、角色、武器、文案、BOSS、僵尸和特效横向人工复核。
- [x] 原图、JSON 清单与联系表仅保存在 `/tmp/zombie_fire_app_store_full_review_20260803_r1/`，不纳入 Git。

## 阶段 110 · 全局语义标签与五主题双语视觉合同（2026-08-03）

- [x] 将技能图鉴已经成立的“类别标签”标准扩展到角色、武器、护甲、芯片、宠物列表与详情页，以及出战页的战力 / 克制状态；标签不再混在普通说明文字里。
- [x] 放弃小尺寸下会挤成碎亮点的旧装饰边框，最终采用专用可九宫格缩放的连续纹理微边框、低饱和深底与稳定内边距；五套主题仍由 `data/themes.json` 提供各自配色，不硬编码主题内容，也不退回运行时扁平几何占位。
- [x] 列表移除重复的 Role / Element prose；无元素宠物不再显示无意义的 `-` 标签，保留真实的职责 / 支援语义。
- [x] 五主题 × 中英文 × 五类收藏完成 `50` 张真机比例列表截图；另复核 `10` 张技能标签、`6` 张详情页和 `1` 张出战页，共 `67` 张原图。完整未跟踪目录为 `/Users/gavin/Desktop/ZombieFire_Tag_Regression_2026-08-03/`。
- [x] M1 smoke 锁定专用纹理路径、四边连续九宫格边距、移动端标签高度、非空文案、垂直居中与语义角色，并覆盖五类收藏、技能详情及出战状态标签。

## 阶段 111 · 挑战模式 99 关模拟门禁（2026-08-03）

- [x] `simulate_balance.py` 新增 `--challenge`，按 `data/challenges.json` 逐章读取生命、移速、突破伤害与机制频率倍率；不复制挑战数值、不新增全局旋钮。
- [x] 挑战生命倍率进入敌方总生命与清场时长；移速、突破与机制频率进入漏怪压力，输出 99 关逐关时长 / 漏怪 / 星级及十章汇总。
- [x] 首轮模拟识别 `level_085 / 090 / 095 / 099` 四个时长墙；仅把第 9 章生命倍率 `1.42 → 1.12`、第 10 章 `1.40 → 1.01`，其余章节及三类机制倍率不动。
- [x] 调整后 99 关无超时、无 100% 漏怪；各章最差关均至少 1★，全战役挑战可得 `175` 星，高于星级经济要求的 `19` 星。
- [x] `check_release_candidate.py` 已把普通与挑战两种模拟都列为非视觉必过门禁；数据验证与普通关压力检查继续通过。

## 阶段 112 · 星级边界可复跑体检（2026-08-03）

- [x] `simulate_balance.py` 新增 `--star-boundary-audit`，不复制 30% / 65% 阈值，继续从 `economy.json.star_thresholds` 动态推导两条漏怪边界。
- [x] 默认审计窗口为边界上下 `2.00` 个百分点，也可通过 `--star-boundary-window` 显式调整；输出保留四位小数与有符号距离，避免整数表格掩盖压线关。
- [x] 当前普通战役识别 `14` 个观察项：`level_008` 是唯一靠近 1★ 边界的关卡，另有 `13` 关靠近 3★ / 2★ 边界；完整清单写入 `design/25` 附录 A。
- [x] 体检只增加诊断输出，不修改星级阈值、关卡波次、终局走廊或经济旋钮。

## 阶段 113 · 发布截图门禁授权说明（2026-08-03）

- [x] `design/app_store_qa_checklist.md` 明确区分无人值守非视觉 RC 与 Owner 授权的最终完整截图 RC，退出码 `125` 不再被误判为素材 / 布局回归。
- [x] 发布前必须人工带 `ZOMBIE_FIRE_ALLOW_WINDOW_CAPTURE=1` 完整跑一次；该步骤可能抢焦点，未经 Owner 当次授权不得执行。
- [x] 日常数值 / 数据回归可带 `ZOMBIE_FIRE_SKIP_WINDOWED_VISUALS=1` 安全运行，但验收记录必须标注截图跳过原因，且不能据此签字通过 App Store 最终截图门禁。

## 阶段 114 · 出战配置空槽文案收口（2026-08-03）

- [x] 护甲 / 芯片 / 宠物三张空槽卡移除重复的“点击选择 / Tap to Select + 槽位 · 选择”两层动作文案，统一为“`+` / `选择（Select）` / 槽位名”三级结构。
- [x] 保持既有移动端字号，不以缩字补救英文长度；动作与槽位标签均保留明确水平安全边并启用最终裁切保护。
- [x] M1 smoke 强制清空三类装备后逐卡锁定紧凑动作文案、槽位身份、边框内净空与绘制裁切。
- [x] 中英文真实 1080×1920 配装页各一张通过布局与图片审计；截图保留在 `/tmp/zombie_fire_loadout_empty_slots_20260803_v2/`，不纳入 Git。

## 阶段 115 · 宠物列表英文信息组间距（2026-08-03）

- [x] 英文宠物名称均为单行短标题，不再沿用武器 / 护甲长名称所需的双行标题预留；标签组整体上移 `32 px`。
- [x] 标签与支援说明保持 `6 px` 紧凑间隔，图标、信息组与购买按钮互不碰撞；卡片高度、字号和按钮位置保持不变。
- [x] M1 smoke 固定检查英文宠物标题到标签距离，以及标签到支援说明的 `4–10 px` 合法区间。
- [x] 英文真实 1080×1920 宠物列表通过布局与图片审计；截图保留在 `/tmp/zombie_fire_pet_title_spacing_20260803/`，不纳入 Git。

## 阶段 116 · 重复通关衰减后的 XP 经济合同（2026-08-03）

- [x] `check_economy_loop.py` 按运行时波次数量曲线、敌人 `run_xp` 与 Godot 正数舍入逐关计算经验；审计口径固定为每关首通、二周目、三周目各一次，倍率继续读取 `repeat_clear_xp_mult`。
- [x] 旧成本下首通经验 `138,063`、三遍合计 `241,645`、全满成本 `137,400`，覆盖率 `175.87%`，确认重复衰减落地后仍会过早点满。
- [x] 仅调整允许的永久技能 / 专属技 XP 成本表，新的总成本为 `303,000`，三遍覆盖率收口到 `79.75%`；经验掉落、`1.0 / 0.5 / 0.25` 衰减、金币、星级与战斗数值均不变。
- [x] 覆盖率合同 `[55%, 85%]` 纳入 `check_economy_loop.py`，并由既有 Release Candidate 经济步骤持续执行。

## 阶段 117 · 第一章首个 3★ 约束冲突（2026-08-03）

- [x] 按正式模拟口径穷举 `level_001 / 002 / 006` 的末波 count 与 `base_hp_ref`。
- [x] 确认即使把原简报的二选一放宽为两项同时调整且各用满 `8%`，最优漏怪率仍为 `33.04%`，无法达到 `<=28%`。
- [x] 在 `design/25` 附录 C 记录每个候选关的当前值、`<=8%` 最优值与真实所需幅度，明确不以超范围数值伪造验收。
- [x] Owner 要求继续完成后，选择不破坏末波节奏的最小结构破坏方案：`level_001.base_hp_ref 120 -> 161`，并在提交与 `design/25` 中明示它超出了原 `8%` 幅度。
- [x] `level_001` 漏怪率收口到 `27.8986%`、成为第一章首个 3★；全战役只有该关星级变化，1★ 保持 `0`，关卡压力无倒挂。

## 阶段 118 · 出战资源芯片与连击浮层上线前收口（2026-08-05）

- [x] 顶部金币 / 星星 / 经验 / 战力资源芯片移除小尺寸下显得混乱的双层贴图边框，改为单层主题描边、深色底、固定内边距，并按数字长度自动扩宽。
- [x] 资源芯片图标与数值统一垂直居中，长数字不再压到框外；出战配置页真实截图复核通过。
- [x] 战斗连击浮层扩大有效文本框，居中“2 连击 / N 连击”和里程碑文案，降低描边厚度，确保文字落在面板内部。
- [x] 截图工具新增 `debug_combo_hud` 专项状态，后续可稳定复查连击 HUD，不影响正式运行逻辑。

## 阶段 119 · 军械库四系列完整目录与购买门禁解耦（2026-08-08）

- [x] 精品军械库始终遍历四个已实现系列，不再把未达到关卡条件误处理为整套商品隐藏；初始存档同样展示四套主题与四套完整军械预览。
- [x] 炼狱 30、霓虹 50、极地 80、鎏金 99 + 任意角色 Lv.40 的原门槛继续只控制购买 / 装备；锁定卡购买按钮禁用，本地购买接口仍拒绝越权。
- [x] 每个系列数据化提供中英文完整解锁说明与按钮短文案；标题、预览和按钮锁定态保持一致，长英文不挤出按钮。
- [x] 数据、字符串与 M1 冒烟门禁锁定四系列 / 八首购卡的锁定目录状态，并同时验证达标后的主题单品、完整包和补差包路由不变。

## 阶段 120 · 关卡选择全区域拖动手势（2026-08-08）

- [x] Normal / Challenge、进入战区与返回战区按钮由阻断输入改为向 `ScrollContainer` 传递同一组触摸事件；从按钮内部起手拖动也能滚动列表。
- [x] 章节大卡取消整卡点击入口，只保留明确的“进入战区”按钮；短按仍只触发按钮，滑动越过阈值则由滚动容器取消按钮点击。
- [x] 小型章节按钮自动扩展出的隐形 `TouchTarget` 同步改为可传递拖动，避免视觉按钮修好后仍被透明命中层截断手势。
- [x] 关卡列表拖动识别阈值由 `24` 收紧到 `16`，并由 M1 smoke 锁定卡片、按钮和扩展命中层的滚动穿透合同。

## 阶段 121 · 角色战力口径诚实化 Phase A（2026-08-08）

- [x] 战力模型读取角色已有的成长档直伤、穿透、连锁、异常、溅射、碎冰与减速亲和；元素不匹配继续严格返回中性倍率。
- [x] 生存战力纳入角色 `base_hp × (1 + hp_growth × 0.45 × (L-1))`，与真实战斗同式；冰霜 / 火焰满级有效生命比 `1.7095x` 已在门禁可见。
- [x] `SaveManager` 与 `tools/power_ruler_model.py` 使用同一组折算常量；四角色模型 / 真实终局 DPS 拟合最大误差 `3.096%`，低于 `±12%`。
- [x] 推荐侧使用同一 vanguard + autocannon 身份估计器抵消新增角色项；I1 为 `1.1099x`、I2 为 `56★`，先锋终局硬锚近零漂移。
- [x] `generate_clear_requirements.py` 重生成 99 关后无数据 diff；固定 fixture、前后六关矩阵、拟合常量与舍入边界记录在 `design/29` 附录 A/B。
- [x] M1 smoke 新增全亲和字段、元素门控、减速转生存和冰霜 / 火焰 HP 比回归，防止未来再次漏读或只改一套模型。

## 阶段 122 · 付费角色战力带宽收口 Phase B（2026-08-08）

- [x] 只用 blaze / frost / volt 的数据化主动技旋钮压缩终局离散；vanguard、自动机枪和 99 关免疫配置全程未动。
- [x] 固定 fixture 的 L099 挑战比值收口为 blaze `1.5057x`、frost `1.1783x`、volt `1.6496x`；三者均不低于免费锚点 `1.1099x`，付费带宽 `1.4000x`。
- [x] blaze 火焰直伤亲和由 `0.04` 修正为 `0.08`，只强化同元素中期身份；火焰成长档同步标定为 `0.012`，避免真实 DPS 与显示尺反向扩散。
- [x] 四角色真实同元素满配 DPS max/min 从 `1.146x` 收窄到 `1.143x`；frost / blaze 坦度比继续为 `1.7095x`。
- [x] 雷霆 / 炼狱 / 绝对零度 / 黄金律合同分别复核为 `1.575180x / 1.575x / 1.539x / 2.043x`，全部留在锁定带；免费基准已同步重冻结到 `design/21` 附录 A。
- [x] 同一 fixture 的 1/25/50/75/90/99 六关矩阵与 I1/I2/I3 实测写入 `design/29` 附录 C/D。

## 阶段 123 · TestFlight 四主题 / 四军械验收入口（2026-08-09）

- [x] TestFlight 临时导出特性统一为 `testflight_premium_preview`，可直接切换默认与四个付费主题。
- [x] 同一特性仅在内测包中绕过四系列的展示 / 本地演示购买关卡门槛，四套终焉军械均可完整购买、装备、切换与回归。
- [x] 演示购买继续只写本地 mock receipt，不伪造 StoreKit 已验证权益、不产生扣款。
- [x] 正式 iOS Release preset 保持只有 `release`；30 / 50 / 80 / 99+Lv.40 门槛及正式倍速解锁规则均未改动。

## 阶段 124 · 全集合页中英文信息节奏统一（2026-08-10）

- [x] 武器 / 护甲 / 芯片 / 宠物不再按语言切换卡片高度或标题预留，统一标题、标签、说明和动作按钮的固定垂直基线。
- [x] 标题→标签、标签→说明均保持 `6 px` 设计间距；角色列表同步锁定既有 `8 px / 6 px` 节奏及中英文一致卡高。
- [x] 英文超长终焉武器名称只在超出标题栏时自适应缩字，普通标题保持完整移动端字号，不换行撑高卡片。
- [x] M1 smoke 覆盖中英文 × 角色 / 武器 / 护甲 / 芯片 / 宠物全部真实行，锁定卡高、两段间距、语义标签边框和按钮边界。
- [x] 10 张中英文专项截图通过运行时文字裁切与图片审计，输出留在 `/tmp/zombie_fire_collection_spacing_review_20260810_v3/`，不纳入 Git。

## 阶段 125 · 黑金主题全尺寸按钮深度渲染（2026-08-10）

- [x] 替换黑金主题原先由多边形、细线和菱形节点程序堆叠的主 / 次按钮，改为两张独立高质量黑曜金属渲染母版。
- [x] 保留全部 `36` 种原生尺寸与现有路径；端部装甲独立保形，中间只延展安静文字区，不整图拉伸。
- [x] 主按钮采用流金高光与更强层级，次按钮采用低饱和古金 / 枪灰层级，装备、升级、关闭等并列动作可一眼区分。
- [x] 生成 `72` 张运行时按钮、专项 manifest 与五种高风险长宽比联系表；尺寸、透明角、材质变化和完整发布门禁纳入复核。

## 阶段 126 · 全集合页标题与标签固定节奏（2026-08-10）

- [x] 角色、武器、护甲、芯片、宠物统一使用同一条标题基线，不再按内容类别或语言保留不同高度的标题空区。
- [x] 标题底边到语义标签固定为 `8 px`，标签到说明固定为 `6 px`；中英文共享同一组数据化布局常量。
- [x] 标题采用底部对齐，普通名称保持完整移动端字号；只有真正超过标题栏宽度的本地化长名称才自适应缩小。
- [x] M1 smoke 锁定五类页面 × 中英文的 `8 px / 6 px` 间隔、标题对齐方式和语义标签结构，防止后续再次漂移。
- [x] 10 张 1080×1920 中英文专项截图通过运行时文字与图片审计；输出保留在 `/tmp/zombie_fire_collection_title_tag_spacing_20260810_v2/`，不纳入 Git。

## 阶段 127 · 炼狱主题全尺寸按钮深度渲染（2026-08-10）

- [x] 确认炼狱主题按钮并非已有渲染资产路由错误，而是生成器仍在程序绘制多边形、双描边、节点圆点与中轴线；旧占位表达已完整移除。
- [x] 新增独立主 / 次两张黑钢铜焰渲染母版：主按钮保留受控熔芯亮度，次按钮改用低饱和枪灰 / 古铜，均保留深色文字安全区。
- [x] 全部 `36` 种原生尺寸继续沿用既有资源路径；端盖独立保形，仅平静中段延展，不整图拉伸，产出 `72` 张运行时按钮。
- [x] 新增按钮专项 manifest、五种极端长宽比联系表与材质门禁；精确尺寸、透明角、主次层级及非扁平材质变化全部自动复核。
- [x] 设置页中英文加入炼狱按钮专项截图门禁，覆盖全宽、双列、三列与底部主按钮，防止旧线框占位版或错误尺寸回退重新出现。
- [x] 强制刷新 Godot 导入缓存后，中英文芯片页与菜单共 `4` 张 1080×1920 真实截图通过运行时文字 / 布局 / 图片审计；输出保留在 `/tmp/zombie_fire_infernal_button_review_20260810_v3/`，不纳入 Git。

## 阶段 128 · 减速力场 V3 非径向区域表达（2026-08-10）

- [x] 移除大范围下会暴露为半圆罩的固定弧形前缘，改为横贯战场的非径向低温前线；范围升级只移动真实边界，不拉伸边缘素材。
- [x] 从边界到防线完整铺设低饱和冰雾、霜裂与微粒层，30% 到 70% 覆盖都能明确读成“区域”，而非一条孤立特效。
- [x] 视觉边界、内部覆盖和实际减速继续共用 `data/skills.json` 的 `y_min`；五级敌人真实位移减速与边界外正常移速由 M1 smoke 锁定。
- [x] 新增 V3 素材形态门禁，自动检查横向覆盖、非径向轮廓、纹理接缝、运行时尺寸与五级边界对齐，并纳入发布候选检查。
- [x] 30% / 70% 专项截图通过人工复核，输出保留在 `/tmp/zombie_fire_slow_field_v3_review_20260810_d/`，不纳入 Git。

## 阶段 129 · 挑战结算战力文案去术语化（2026-08-10）

- [x] 挑战胜利提示不再使用“基准 → 终局 / 挑战”这一组需要猜测的内部术语，分别明确为“出战预估战力 / 本局最终 / 挑战建议战力”。
- [x] 当本局拿卡未达到标准预估时，直接说明“本局技能未选满”，避免较低的最终数字被误解为角色变弱。
- [x] 星级规则由“只补最高差额”改写为“星星奖励仅补发超过历史最高星数的部分”，明确这是历史最佳星数的增量奖励。
- [x] 中英文使用相同信息顺序；2 张 1080×2340 专项截图通过运行时文字、换行与边界审计，输出保留在 `/tmp/zf-result-copy-review-20260810-final-v2/`，不纳入 Git。

## 阶段 130 · 付费系列按战役进度整套揭示（2026-08-10）

- [x] 最终 Owner 决策覆盖阶段 119 的常驻目录：未达到 30 / 50 / 80 / 99+Lv.40 条件前，对应系列在所有玩家界面完全隐藏，不展示名称、素材、价格或解锁关卡提示。
- [x] 商店、主题与逐角色战衣、武器 / 护甲 / 芯片 / 宠物收藏统一读取同一个数据化系列揭示门禁；达到条件后整套首次出现。
- [x] 主菜单在第一套尚未揭示前隐藏军械库入口；已验证永久权益优先，存档进度回退仍可恢复与使用已购内容。
- [x] TestFlight 预览只放宽已揭示系列的试穿 / 本地验收权益，不再提前泄露未揭示系列；内部全矩阵继续使用显式 fixture。
- [x] M1 smoke 锁定新存档全隐藏、30 关只出现炼狱、后续逐套揭示，以及商店 / 外观 / 收藏三类入口的一致性。

## 阶段 131 · 全详情页伪进度横线清理（2026-08-10）

- [x] 确认宠物 / 武器 / 护甲 / 芯片 / 角色详情页标题下方横线不是进度数据，而是结果面板装饰纹理在超高弹窗中拉伸后的视觉接缝。
- [x] 详情弹窗改为连续不拉伸的深色底板；独立渲染金属素材只绘制四周边框，中心永久关闭绘制，消除标题下与空白区的伪进度条。
- [x] 结果结算页继续使用原结果面板纹理，不受本次详情专用修正影响。
- [x] M1 smoke 锁定角色 / 装备详情的连续底板与 `draw_center = false` 渲染契约，避免未来回退到整张纹理纵向拉伸。
- [x] 角色、武器、护甲、芯片、宠物共 `5` 张专项截图复核通过，输出保留在 `/tmp/zf-detail-panel-final-20260810/`，不纳入 Git。

## 阶段 132 · 顶部资源条五主题居中与边框回归（2026-08-11）

- [x] 金币 / 星星 / 经验 / 战力数字脱离图标参与的整组居中，改为以完整按钮边框的几何中心独立水平、垂直居中。
- [x] 四类资源图标使用固定左侧安全槽，并按五主题中端部装甲最深的炼狱边框预留净空；图标不再骑在外框或进入数字栏。
- [x] 资源条从共用默认面板改为读取默认、霓虹、炼狱、极地、鎏金各自的原生次级按钮边框；功能图标颜色保持不变。
- [x] 长数字按有效字号和对称安全槽自动扩宽，`31612 / 37 / 12172 / 38` fixture 在收藏页安全宽度内完整容纳。
- [x] M1 smoke 新增五主题边框路径、四项资源数量、数字中心线、图标边框净空及图标 / 数字栏分离断言。
- [x] 五张真实 `1080×1920` 护甲页截图通过人工复核，输出保存在 `/Users/gavin/Desktop/ZombieFire_TopResourceBar_Regression_2026-08-11/`，不纳入 Git。

## 阶段 133 · 极地按钮渲染与资源条光学居中回归（2026-08-11）

- [x] Owner 截图复核否决阶段 132 的“数字独立几何居中”：控件矩形虽居中，但图标与数字整体明显左重；现改为紧凑内容组共同居中。
- [x] 依据可见像素而非控件矩形增加 `-4 px` 水平与 `+2 px` 垂直光学校准；四类图标仍完整离开五主题最深端甲，数字与图标保持 `10 px` 间隔。
- [x] 极地极光主 / 次按钮移除程序多边形、细线、节点与中轴线，换为冰银 / 极光晶体及极地枪灰两张独立深度渲染母版。
- [x] 极地 `36` 种原生尺寸 × 主次两层共 `72` 张全部沿既有路径重建；仅延展平静中段，端部装甲保形，新增 V2 manifest、联系表和材质自动门禁。
- [x] 强制刷新 Godot 导入缓存，避免运行时继续读取旧线框纹理；五主题真实 `1080×1920` 护甲页复拍和图片审计 `5/5` 通过。
- [x] 最终截图保存在 `/Users/gavin/Desktop/ZombieFire_TopResourceBar_Regression_2026-08-11_v2/`，不纳入 Git。

## 阶段 134 · Build 49 TestFlight 与五主题核心界面审查包（2026-08-12）

- [x] iOS 版本保持 `1.0.0`，构建号由 `48` 升至 `49`；完整 Release Candidate、导出 PCK、Archive、IPA 与 Store 包审计全部通过。
- [x] Build 49 已上传并通过 Apple 服务端验证：Delivery UUID `9027e20f-bef7-473c-995b-1961499094c8`，状态 `VALID / APP_STORE_ELIGIBLE`；已上传 IPA 复制到 `/Users/gavin/Desktop/ZombieFire.ipa`。
- [x] TestFlight 临时导出特性仅用于本次内测包；上传成功后 iOS preset 已自动恢复为正式 `release`，正式进度与权益门禁未改动。
- [x] 新增 Owner 专用五主题中文核心界面矩阵：每套 `17` 张，共 `85` 张 `1080×1920` 原图；按要求不再展开四人物、逐武器或逐局内特效枚举。
- [x] `85/85` 截图通过运行时缺图 / 回退与图像完整性门禁，并生成五张主题联系表；人工抽查确认顶部四资源组合在边框内、极地按钮为深度渲染素材且五主题按钮边框均正确切换。
- [x] 完整审查包、manifest 与审查说明保存在 `/Users/gavin/Desktop/ZombieFire_Build49_Theme_Interface_Review_2026-08-11/`，不纳入 Git。
- [x] 记录 Apple `90068` 前瞻警告：本包 iOS 14 最低版本当前仍有效；2027 年春季前需另行评估升至 iOS 15，本次不扩大部署范围。

## 阶段 135 · 顶部资源数字可见字形垂直居中（2026-08-12）

- [x] Owner 再次以 Build 49 审查截图指出顶部资源数字仍偏下；复测确认四组数字可见字形中心比边框内槽中心低约 `3–4 px`。
- [x] 根因是阶段 133 将紧凑内容组整体向下补偿 `+2 px`，与 Glow Sans 数字墨迹本身偏下叠加；现改为向上 `-2 px`，横向 `-4 px` 与图标 / 数字 `10 px` 间隔保持不变。
- [x] M1 smoke 明确锁定 `-2 px` 向上可见墨迹校准，继续覆盖五主题、四资源、边框路径、端甲净空与内容组中心合同。
- [x] 五主题 `1080×1920` 护甲页复拍 `5/5` 通过；像素测量得到数字墨迹中心均值 `216.625`、边框内槽中心 `216.5`，误差 `0.125 px`。
- [x] 最终截图保存至 `/Users/gavin/Desktop/ZombieFire_TopResourceBar_Regression_2026-08-12_v3/`，不纳入 Git；Build 49 保留已上传内容，本次未越权重传新包。

## 阶段 136 · 关卡模式大触控双按钮（2026-08-12）

- [x] 关卡未通关、挑战尚未显示时，只保留一个 `286×164` 的普通模式大按钮，并在卡片右侧动作区水平 / 垂直居中；不再让不可用挑战入口占据整行。
- [x] 普通模式已有通关记录后，动作区切换为普通 / 挑战两个等宽 `206×164` 大按钮左右并排；两块真实命中区域保持 `10 px` 间隔且继续支持从按钮起手拖动列表。
- [x] 两种布局统一改成模式名在上、独立三星进度在下；原有“普通 3 星才解锁挑战”规则未改，1–2 星通关时挑战按钮可见但灰化并带锁，3 星后启用。
- [x] 默认、霓虹风暴、炼狱统御、极地极光、鎏金蚀日 × 单按钮 / 双按钮共 `10` 张真实 `1080×1920` 截图全部通过运行时界面审计，五套按钮均使用各自已渲染原生主题边框。
- [x] 总览图、原图和零问题 manifest 保存在 `/Users/gavin/Desktop/ZombieFire_关卡模式双按钮回归_2026-08-12/`，不纳入 Git。

## 阶段 137 · Build 50 TestFlight（2026-08-12）

- [x] iOS 版本保持 `1.0.0`，构建号由 `49` 升至 `50`；本包包含阶段 135 顶部资源数字可见字形垂直居中修正，以及阶段 136 关卡模式单 / 双大按钮布局。
- [x] 完整 Release Candidate、导出 PCK 探针、Xcode Archive、App Store IPA 审计及 Apple 服务端处理全部通过；PCK `702572780` bytes，IPA `731446327` bytes。
- [x] Build 50 已进入 App Store Connect：Delivery UUID `d53f6ef7-32f8-4b42-a2b7-f154e9fed6e7`，状态 `VALID / APP_STORE_ELIGIBLE`，`IMPORT-STATUS: VALID`。
- [x] 已上传 IPA 与 `/Users/gavin/Desktop/ZombieFire.ipa` 逐字节一致，SHA-256 `b8bb37e45387334b0535dbf932622d22f187ab5dd79d362e5f8116e48684e3da`；发布记录保存在 `build/ios/release/build_50/release_manifest.json`。
- [x] TestFlight 临时预览特性仅用于本次内测归档；上传成功后 iOS preset 已恢复为正式 `release`。Apple `90068` 仍为非阻断前瞻警告：2027 年春季前需将最低系统从 iOS 14 评估提升到 iOS 15。

## 阶段 138 · 暂停页操作按钮单行安全区（2026-08-12）

- [x] 确认“继续战斗 / 重打本关 / 返回关卡”内容骑框并非按钮外框越界，而是图标占用主题端甲、副标题压到下边框；三颗按钮共用的双行坐标会影响全部主题。
- [x] 保留三行独立大触控目标，移除非必要副标题，统一为图标 + 单行操作名称 + 箭头；标题与按钮中心线对齐，不缩小命中区域。
- [x] 图标、标题、箭头全部收进五主题最深端甲的共同 `584×76` 安全区；M1 smoke 锁定无副标题、单行布局、中心线与子控件包围关系。
- [x] 默认、霓虹风暴、炼狱统御、极地极光、鎏金蚀日五张中文暂停页，以及英文标准 / 长屏两张截图全部通过运行时与图片审计。
- [x] 七张回归原图保存在 `/Users/gavin/Desktop/ZombieFire_暂停按钮单行回归_2026-08-12/`，不纳入 Git；本次未生成或上传新的 TestFlight。

## 阶段 139 · 单关卡入口动作化文案（2026-08-12）

- [x] 挑战入口尚未显示时，唯一的普通关入口从对比性标签“普通”改为动作标签“闯关”；英文对应使用 `Play`。
- [x] 普通已有通关记录、两个入口同时出现时，继续显示“普通 / 挑战”，不改变挑战三星解锁或任一路由身份。
- [x] M1 smoke 锁定单按钮“闯关”和双按钮“普通 / 挑战”两种文案合同；单按钮仍携带 `level_mode=normal`，只改显示不改玩法。
- [x] 中文单按钮、英文单按钮、中文双按钮三张 `1080×1920` 真实截图通过运行时和图片审计，保存在 `/Users/gavin/Desktop/ZombieFire_闯关按钮文案回归_2026-08-12/`，不纳入 Git。

## 阶段 140 · 单一战力口径与固定推荐尺（2026-08-12）

- [x] 按 Owner 最终定义将玩家侧“战力”统一为当前装备、当前永久技能等级、本关预期选卡预算及元素克制共同形成的一个数值；不再拆成基准 / 预计成型 / 终局战力。
- [x] 配装摘要、战力状态、严重不足二次确认、战斗入口与结算提示全部改用同一个关卡战力；地图关卡卡片明确标为“推荐”。
- [x] 推荐战力改为只读取关卡 `clear_requirement`、`recommend_level` 与固定通用选卡吞吐的关卡门槛；切换角色、武器或永久技能不再带动推荐值上涨。
- [x] 地图、出战配置和收藏页顶部战力统一按当前 / 最高已解锁关卡的预期成型口径显示；历史 API 只保留给内部工具兼容，不再形成第二套玩家概念。
- [x] M1 smoke 锁定技能升级抬高玩家战力、推荐值对存档构筑保持不变，以及所有玩家文案不再出现“基准 / 预计成型 / 本局最终”拆分。

## 阶段 141 · 火焰小子主动技全战场覆盖（2026-08-13）

- [x] `sig_blaze_meltdown` 从高威胁目标周围的局部爆区改为每段命中战场内全部存活敌人，解决尸潮里看起来只打到少数目标的问题。
- [x] 全屏语义由 `characters.json.active_skill.coverage_mode=battlefield` 声明，数据校验限制为 `local / battlefield`，不在角色 ID 分支里硬编码覆盖规则。
- [x] 保留原目标中心的每段权重与距离衰减作为统一单体伤害系数；改变的是命中覆盖，不额外抬升 Boss 单体伤害，也不改变玩家战力公式。
- [x] 爆燃主视觉按上下左右战场锚点扫过，逐敌命中继续生成火焰反馈；M1 smoke 以左上、中央、右下三个远距敌人锁定真实全屏掉血。

## 阶段 142 · 关卡内人物静态 / 开枪统一缩放并整体缩小 20%（2026-08-13）

- [x] 修复旧人体归一仍按姿势独立缩放的问题：蹲姿 / 后仰开枪帧不再因为头脚投影较短而被额外放大；同一角色 / 同一套模型的待机、受击和三方向开枪现在共用 `center` 人体倍率。
- [x] 姿势数据继续独立控制人体中轴与脚底落点，确保静态和开枪动作共用体量时双脚仍固定在同一防线基准，枪口继续跟随真实合成图坐标。
- [x] 完整人物 rig 从 `1.50×` 调整为 `1.20×`，即严格缩为此前显示尺寸的 `80%`；角色等级、武器等级、主题和装扮不再追加人物体型变化。
- [x] HUD 静态门禁覆盖 `944` 张角色 / 武器帧，最小底部资源条净距为 `22.1 px`；视觉回归新增五主题 × 四人物的冻结待机帧，不再只审查左 / 中 / 右开枪图。

## 阶段 143 · 基地受击 / 相位闪现 / 僵尸攻击音效解耦重做（2026-08-13）

- [x] 重做 `sfx_enemy_breach.wav`：用钢制防线挠曲、沙袋闷响、螺栓与碎石回落组成写实基地受击层；仅在基地真实承伤时播放（护盾格挡改播独立格挡声），不再承担僵尸动作语义。
- [x] 重做 `sfx_zombie_phantom.wav`：删除旧电子故障、电弧与撞击瞬态，改为 `0.44s` 的双层空气风切“刷”声，专用于相位幽影闪现。
- [x] 新增七类普通僵尸攻击动作音效：爪击、快速爪击、撕咬、重击、爆破、腐蚀和支援施法；20 种普通僵尸按已有 `attack_animation.mode` 路由，在攻击预备时播放，接触基地后另叠写实受击声。
- [x] 音效仍为 `44.1kHz / mono WAV`，统一峰值 `-4.8 dBFS`；原版受击 / 闪现声音、可复现生成器、manifest 与波形审查图均存入 `source_refs/generated/combat_foley_sfx_2026_08_13/`。
- [x] 新增 `check_combat_foley_sfx_quality.py` 并接入 Release Candidate，永久检查格式、时长、频谱差异、运行时注册和三层语义解耦。

## 阶段 144 · 局内技能说明临时浮层关闭交互（2026-08-13）

- [x] 技能长按说明显示后启动独立 `3.0s` 实时时限；玩家没有继续操作时自动收起，不受战斗倍速影响。
- [x] 收口为统一的“长按查看”语义：已有技能短按不再弹说明，主动技能短按只负责可用时释放；冷却中短按不弹浮层。
- [x] 点击技能说明以外的空白战场 / HUD 区域立即收起，并消费该次触摸，避免关闭说明的同一次点击误触发手动瞄准或锁敌。
- [x] 浮层显示时，主动技能、已有技能、暂停和加速按钮仍保持一击可用；点击说明面板自身不会穿透到战场。
- [x] 自动关闭发生在长按尚未松手时保留按压状态，确保松手不会被重新解释成一次主动技能释放。
- [x] M1 冒烟覆盖长按打开、空白点击关闭、三秒自动关闭、计时清理和技能按钮点击不被吞掉。

## 阶段 145 · 玩家 / 推荐战力共享技能投影器（2026-08-13）

- [x] 推荐战力删除独立的通用选卡多项式，和玩家战力共同调用同一个选卡投影器与战斗技能效果计算器。
- [x] 玩家侧显式传入当前武器与永久技能等级；推荐侧显式冻结为先锋、自动机枪、空永久技能档案和关卡推荐等级，同一关不再随玩家存档移动。
- [x] 结算保持唯一玩家战力，新增真实“本局选卡 X/Y”；跳过卡牌只推进出卡流程，不伪装成已经选择。
- [x] Python 终局镜像同步共享投影器，99 关普通推荐固定为 `3099`；三套免费满配物理武器的终局通关模拟仍全部通过。
- [x] M1 冒烟锁定技能逐级升级战力单调不下降、推荐及其固定选卡投影跨存档严格相同，以及结果页不回退到基准 / 终局双战力。

## 阶段 146 · Build 51 TestFlight（2026-08-13）

- [x] Build 51 收录单一战力共享投影器、真实本局选卡计数，以及截至阶段 145 的当前 Owner 验收改动；完整 Release Candidate、导出 PCK 启动 / 存档 / M1 / 特性探针、Xcode Archive、App Store IPA 审计全部通过。
- [x] 导出包探针不再把 TestFlight 合法保存的 `2X / 5X` 误判为异常；现在严格检查未暂停、所选倍速属于可用档位，并与 `Engine.time_scale` 一致。M1 持续时间断言在 5X 专项后显式回到隔离的 1X 时钟。
- [x] Apple Delivery `d37aefe6-ee6e-4f58-9465-6a3f3aefe7ce` 达到 `BUILD-STATUS: VALID / IMPORT-STATUS: VALID / APP_STORE_ELIGIBLE`，并已进入 App Store Connect。
- [x] 已上传 IPA 为 `731519490` bytes，SHA-256 `68ff8f2a7478d9839352fa00378ace5eb0473b1719f2c3e74e9bd7e2372a3e98`；桌面副本逐字节一致，发布记录保存于 `build/ios/release/build_51/release_manifest.json`。
- [x] TestFlight 临时 `testflight_speed_unlocked / testflight_premium_preview` 特性在导出后恢复为普通 `release`；Apple `90068` 仍只是 2027 年春季 iOS 15 最低版本要求的非阻断前瞻警告。

## 阶段 147 · 多重射击五级弹道曲线与四级补偿（2026-08-14）

- [x] 按 Owner 指定把 Lv1~Lv5 额外弹丸固定为 `+1/+2/+3/+3/+4`，即总弹道 `2/3/4/4/5`；四级不再提前得到第五条弹道。
- [x] Lv4 / Lv5 分别使用 `lane_damage_bonus: 0.08 / 0.02`：四级维持 4 条但单弹由 `75%` 回补至 `83%`，五级增加到 5 条并保留小幅回补至 `72%`。
- [x] 实战伤害、技能卡牌 / 图鉴说明、玩家战力、固定推荐战力的共享技能投影与 Python 镜像统一读取该字段，避免显示、战斗和战力三套数值漂移。
- [x] M1 smoke 锁定五级弹道序列、四 / 五级回补、永久 Lv4 首次预加载与 Lv5 升级结果；满级终局审计同步使用 `0.72` 单弹倍率。

## 阶段 148 · 三短板单一战力与运行时双 Boss 合同（2026-08-14）

- [x] 玩家侧继续只显示一个“战力”，底层改为清群、Boss、防线三项实战能力分别除以本关对应门槛，并取三者最低比值；任一关键短板都不能再被无关高数值掩盖。
- [x] 推荐战力冻结为关卡自己的能力合同，不再由玩家构筑反推；当前战力与推荐战力共用同一套永久技能、预期选卡、元素克制、Boss 机制和防线承伤口径。
- [x] 99 关第二只 Boss 改为 `levels.json.runtime_bosses` 明确声明，战斗生成、离线模拟和推荐战力均读取同一数据；删除战斗脚本里仅运行时追加 Boss 的隐藏分支。
- [x] 99 关首轮选卡由数据保证至少出现“防线屏障 / 缓速力场”之一，只保证候选、不替玩家自动选择，避免双 Boss 关因随机选卡形成不可控死局。
- [x] 99 关免费满配物理构筑冻结为 `4770 / 推荐 4097`、Boss 短板；55 关 Owner 截图构筑冻结为 `401 / 推荐 425`、防线短板，作为 Python 与 Godot 双端永久回归标尺。
- [x] 全 99 关重新生成 `power_contract`，数据校验、终局审计、选卡回归和 M1 smoke 均检查关卡合同、运行时 Boss 与两组锚点不漂移。

## 阶段 149 · 减速力场五级强度与雪花可读性回归（2026-08-14）

- [x] 按 Owner 指定将 Lv1~Lv5 减速强度固定为 `30% / 40% / 50% / 60% / 80%`；覆盖范围继续保持 `30% / 40% / 50% / 60% / 70%`，不混淆范围与强度。
- [x] 删除运行时旧 `40%` / `45%` 最低移速双保底，改为共享 `20%` 最低移速；五级真实移动距离为原速的 `20%`，冰霜角色 / 芯片 / 宠物强化也统一受同一上限约束。
- [x] 力场强度从 `skills.json` 数据读取，不再在 `battle.gd` 复制五档旧数值；三短板战力的防线容量同步把减速折算上限由 `65%` 对齐至真实 `80%`。
- [x] 保留已认可的 V3 冰面与非径向边界，持续粒子从淡色通用光点改为既有冰晶命中特效的小型雪晶；数量随覆盖面积和等级从至少 `56` 增长到最多 `124`，并提高冰面细节可见度。
- [x] M1 smoke 锁定五档数据、真实敌人位移、统一最低移速、雪晶素材和最低密度；Lv1 / Lv5 两张真实战斗截图通过运行时与图片审计，保存在 `artifacts/slow_field_review_2026-08-14/`。

## 阶段 150 · 精品军械库全内容触摸滚动修复（2026-08-15）

- [x] 根因确认：外层 `ScrollContainer` 与真实滚动范围一直存在，但商品整卡使用停止事件，购买、撤销、装备与升级按钮也沿用默认拦截，导致手指从绝大多数可见内容起拖时无法到达滚动框。
- [x] 商店主列表统一使用 `12 px` 拖动死区；内容树内所有非忽略控件与按钮递归切换为事件透传，商品卡、头像、说明、购买按钮、已购套装与升级区均可作为上下滑动起点。
- [x] 商品详情继续保留短按打开；购买按钮通过独立按下来源标记与跨触摸 / 模拟鼠标的重复释放保护，拖动不会误弹详情或购买确认，静止短按仍执行原动作。
- [x] 底部“恢复购买 / 清空演示 / 返回”仍位于滚动框之外保持固定，不参与列表拖动透传。
- [x] M1 smoke 锁定真实滚动范围、滚动位置改变、全内容 `PASS` 链、按钮拖动元数据和拖动无误触；顶部 / 深层两张 `1080×2340` 路由截图通过运行时与图片审计，保存在 `artifacts/store_scroll_fix_2026-08-14/`。

## 阶段 151 · 商品详情页独立触摸滚动修复（2026-08-15）

- [x] 确认商品详情是独立于外层商品列表的第二个 `ScrollContainer`；其说明区、主题卡、人物卡、武器卡和终焉装备卡仍使用默认事件拦截，因此外层修复不会自动覆盖详情页。
- [x] 详情滚动框统一使用 `12 px` 拖动死区，并在完整数据驱动内容生成后递归应用同一套滚动透传合同；所有主题、完整包与主题持有者升级包共用修复。
- [x] 顶部关闭按钮与底部“演示购买 / 返回商品列表”继续固定在滚动区外；只允许中间详情内容滑动，不改变购买路由或商品权益。
- [x] M1 smoke 对每个商品详情锁定独立滚动范围、滚动位置改变、全内容 `PASS` 链；霓虹雷霆完整包顶部 / 深层两张 `1080×2340` 截图通过运行时与图片审计，保存在 `artifacts/store_detail_scroll_fix_2026-08-15/`。

## 阶段 152 · Build 52 TestFlight（2026-08-15）

- [x] iOS 版本保持 `1.0.0`，构建号由 `51` 升至 `52`；本包收录阶段 147–151 的多重射击曲线、三短板战力合同、减速力场与雪晶增强，以及精品军械库列表 / 商品详情双层触摸滚动修复。
- [x] 完整 Release Candidate、导出 PCK 启动 / 存档 / M1 / 特性探针、Xcode Archive、App Store IPA 审计全部通过；PCK `716233260` bytes，IPA `744933251` bytes。
- [x] Apple Delivery `24744398-24a9-4198-992c-27ab5ba6edf8` 达到 `BUILD-STATUS: VALID / IMPORT-STATUS: VALID / APP_STORE_ELIGIBLE`，并已进入 App Store Connect。
- [x] 已上传 IPA 与 `/Users/gavin/Desktop/ZombieFire.ipa` 逐字节一致，SHA-256 `505c1ae4a936b875ba155f3c4f98ab949a496b2a982496f317c62593d09f223f`；发布记录保存于 `build/ios/release/build_52/release_manifest.json`。
- [x] 发布记录如实标记源工作区存在已跟踪改动（commit `6c903db3ed19994458f9ccd4fb406c3160729fed`）；TestFlight 临时 `testflight_speed_unlocked / testflight_premium_preview` 特性在导出后恢复为普通 `release`。
- [x] Apple `90068` 仍为非阻断前瞻警告：本次 iOS 14 最低版本被接受，2027 年春季前需评估提升至 iOS 15。

## 阶段 153 · 出战配置武器展示重渲染与终焉规格放大（2026-08-15）

- [x] 为八把免费武器新增独立 `loadout_art`：保留武器类型与元素身份，改成透明、完整、三维机械产品图；局内 handheld / turret、弹道、枪口、VFX 与数值均不改动。
- [x] 免费武器展示窗从旧库存图标规格扩大为 `388×252`，四把终焉付费武器统一扩大为 `410×296`；运行时按真实 alpha 边界二次适配，主体占满卡片但保留安全边距。
- [x] 黄金裁决废弃“旧斜图旋转”补救，新增横向 V3 黑金裁决重炮：黄金审判核心、长裁决导轨与同心判决炮口均在真实出战卡片中完整显示，所有武器恢复零旋转展示。
- [x] 八把免费源图、黄金裁决 V3 源图、提示词、可复现构建器、hash manifest 与审查图均已登记到 `OUTSOURCER_ASSET_INDEX.json`；M1 smoke 锁定免费 / 付费尺寸尺、alpha 完整性、黄金裁决最小占幅和零旋转。
- [x] 五主题真实出战页完成回归；免费八武器、付费四武器与黄金裁决 V3 对比图保存在 `artifacts/free_weapon_loadout_showcase_2026_08_15/`。

## 阶段 154 · 武器图鉴宽卡片与大图标排版（2026-08-15）

- [x] 武器图鉴卡片从 `760 px` 放宽为 `860 px`，占用更多 1080 竖屏安全区；角色、护甲、芯片、宠物和技能图鉴保持原有尺寸，不扩大改动范围。
- [x] 武器图标经 Owner 二次实图复核，最终从 `92×92` 放大至 `168×168`，并将左起点移至 `x=44`；标题、标签、属性说明统一移动到 `x=244` 文字轴，与图标保留至少 `28 px` 净距。
- [x] 装备 / 已装备 / 购买按钮移动至宽卡最右安全区，锁定遮罩和内层框同步随卡片扩宽，按钮、文字和边框均不相互覆盖。
- [x] M1 smoke 锁定卡片、内框、图标、文字轴、图文净距及按钮右边界；霓虹雷暴中英文 `1080×1920` 真实路由截图保存在 `artifacts/weapon_collection_layout_2026_08_15/`。

## 阶段 155 · 商品详情文字安全边距统一（2026-08-15）

- [x] 商品标题在既有弹窗总边距内增加 `16 px` 左侧文字缓冲，关闭按钮与固定底部购买区保持原位。
- [x] Owner 二次实图复核后，所有商品详情分区统一使用左 `36 px`、右 `24 px`、上下 `22 px` 的标题 / 正文安全边距，文字轴进一步向右移动且不无谓压缩右侧。
- [x] 主题四格说明卡统一使用左 `26 px`、右 `18 px`、上下 `14 px` 内边距；终焉装备说明卡统一使用左 `26 px`、右 `18 px`、上下 `16 px` 内边距。
- [x] M1 smoke 遍历主题、完整包与升级包的所有详情分区锁定统一边距；中英文主题页及中文完整包深层截图通过实图复核，保存在 `artifacts/store_detail_padding_2026-08-15/`。

## 阶段 156 · 局内三选一技能图片放大（2026-08-15）

- [x] 三选一技能图片经 Owner 二次实图复核，最终从 `100×100` 放大为 `156×156`，金属图标框同步从 `116×116` 放大为 `176×176`。
- [x] 标题、当前数值、说明和标签共用文字轴从 `x=176` 移至 `x=220`，图标框与文字保持至少 `28 px` 净距。
- [x] 等级 / 推荐徽章仍保留独立右上区域；三张卡片高度、重抽 / 跳过按钮和长按详情交互不变。
- [x] 中英文 `1080×2340` 真实战斗选卡截图确认图片更醒目且最长说明无裁切，保存在 `artifacts/card_offer_icon_scale_2026-08-15/`。

## 阶段 157 · 相位闪现 / 基地受击音效彻底解耦（2026-08-15）

- [x] 全量盘点普通 `zombie_phantom`、Boss `boss_void_phantom`、相位突进与 `dash_combo` 四条运行时路径；确认 WAV 本体和注册 ID 从未共用，残留问题来自同帧叠播通用警报及近线相位伤害的高优先级基地撞击层。
- [x] 普通相位闪现现在只播放 `sfx_zombie_phantom.wav` 的空气风切声，不再叠播 `threat_warning`；相位穿行造成的近线伤害保留伤害反馈，但不伪造钢板 / 沙袋实体撞击。
- [x] 虚空幽影 Boss 的周期相位突进继续使用专属风切声；其 `dash_combo` 可见位移动作补上同一风切身份，真实斩击与真实防线接触仍分别保留打击层和 `enemy_breach`。
- [x] 音频质量门禁和 M1 smoke 新增运行时路由断言，覆盖普通相位、Boss 相位、物理冲锋和非相位重击，防止以后再次把闪现、警报和基地撞击混成一层。

## 阶段 158 · 局内三选一弹窗战场区域垂直居中（2026-08-15）

- [x] 删除放大技能图片前遗留的固定纵坐标与长屏向下偏移；弹窗改为在顶部战斗控件下沿与真实防线 `BREACH_Y` 之间按自身实时高度垂直居中。
- [x] `1080×1920` 标准屏、长屏与超长屏共用同一计算规则；安全区、长屏高度补偿、中英文和所有主题均不会再各自积累位置偏差。
- [x] 技能卡片、放大后的 `156×156` 图片、详情浮层和重抽 / 跳过交互保持原规格；仅修正整个三选一弹窗的位置，不改变战斗数值或选卡逻辑。
- [x] M1 smoke 锁定弹窗中心必须与可用战场区域中心重合，并确认上下边界不会越过顶部控件或压到防线 / 人物区域；标准屏与五主题超长屏实图保存在 `artifacts/card_offer_vertical_center_2026-08-15/`。

## 阶段 159 · 减速力场边界亮线水平校正（2026-08-15）

- [x] 确认运行时节点旋转、位置和真实减速判定均为水平；视觉倾斜来自 V3 边界素材右侧主亮线比左侧低约 `16–23 px`，雪花 / 冰雾增强后更容易被看见。
- [x] 新增边界专用水平校正 shader，以 `18 px` 中心对称 UV 反向补偿素材的全局斜率，并在真实减速起点叠加低强度、端部渐隐的绝对水平冰线；不旋转、不拉伸、不裁短整张 `1080 px` 边界，保留局部冰峰与雪雾形状。
- [x] 真实减速起点、五级范围、减速强度和粒子密度均保持不变；M1 smoke 锁定零旋转、专用 shader、补偿量和完整宽度。
- [x] Lv1 / Lv5 真实战斗截图通过运行时与图片复核，水平冰线左右端点使用同一像素高度，保存在 `artifacts/slow_field_boundary_level_2026-08-15/`。

## 阶段 160 · 穿山甲冲锋尸远距位移音效解耦（2026-08-15）

- [x] 按 Owner 实机描述反查模型而非只查 `phase` 命名，确认“穿山甲”外形对应 `zombie_charger`；其远距 `charge` 位移仍同时播放旧冲锋撞击声与通用警报，正是基地未受伤却听起来像受击的漏网路径。
- [x] `charge` 位移改为复用已验收的纯空气风切 `zombie_phantom`，并取消同帧 `threat_warning` 叠播；远处冲锋现在只有一次“刷”声，不再带金属 / 沙袋撞击错觉。
- [x] 基地音效继续严格绑定真实接触：冲锋只有从防线压力带内发起并实际进入伤害分支时才可播放 `enemy_breach`；触发点 `y=660` 的远距位移明确不能扣基地血或请求接触声。
- [x] 音频质量门禁与 M1 smoke 锁定冲锋尸模型路由、无旧警报、远距不进基地伤害分支，以及真实近线接触仍保留基地受击反馈。

## 阶段 161 · 全僵尸生命周期音效单通道去叠播（2026-08-15）

- [x] 完整盘点 20 种普通僵尸与 8 个 Boss 的出生、移动/机制、基地攻击起手、视觉命中、真实基地接触和死亡路径；确认叠播不只来自闪现，而是出生重播机制声、位移叠加通用警报、直接攻城技能同帧双声、Boss 视觉命中重复基地声、特殊尸死亡重播机制声五类系统问题。
- [x] `AudioManager` 新增全局 `enemy_foley` 单通道：任意时刻只允许一个僵尸动作/攻击/死亡/防线反馈；普通动作不会抢断当前声音，真实基地受击、屏障格挡和防线警报会打断旧尾音而不是叠在上面。
- [x] 普通僵尸出生、基础行走、装甲/潜行被动提示改为纯视觉；跑尸、跳跃、冲锋、相位位移各只保留自身一个动作声；吐毒、震地、寒潮和 Boss 直接攻城以真实基地接触声为唯一同帧声音。
- [x] 所有普通僵尸死亡统一使用 `enemy_death`，不再把闪现、冲锋、召唤、护盾等机制声当死亡声重播；装甲命中也取消“元素命中 + 装甲尸叫声”双层。
- [x] Boss 基地攻击起手取消重复通用警报，最终视觉命中不再预播元素命中 / 基地撞击；真实 `breached` 事件成为基地接触音唯一所有者，中间多段攻击仍可保留单个元素反馈。
- [x] `check_audio_overlap.py`、战斗拟音质量门禁与 M1 smoke 锁定全 20 种僵尸的 action/death/entry/ambient/passive 音效矩阵、敌方单通道、三类高优先级打断和全部位移无双警报合同。

## 阶段 162 · 关卡相关战力统一命名“有效战力”（2026-08-15）

- [x] 确认三短板公式读取本关清群 / Boss / 防线合同、主弱点与选卡预算，显示值本质上是关卡相关的预计通关能力，不是同一套装备固定不变的角色面板值。
- [x] 出战资源栏、战术摘要、详情格、低于推荐提示、严重不足二次确认、战斗结算和失败补强动作统一改为“有效战力”；“推荐战力 / 推荐”继续表示关卡固定通关门槛。
- [x] 商品纯外观声明、芯片说明和局内金币卡说明同步使用“有效战力”，中英文统一为 `有效战力 / Effective Power`。
- [x] 游戏性静态门禁与 M1 smoke 锁定新术语，拒绝出战与结算页面回退成会被误解为固定面板值的裸“战力”。

## 阶段 163 · 上线走查 P0：商店空态与三格资源栏（2026-08-15）

- [x] 精品军械库在没有任何已解密系列时不再渲染空白页；新增中英文空态卡片，展示最近一档与后续档位的匿名解锁条件，并继续保留“恢复购买”入口。
- [x] 解锁说明完全由 `premium_sets.json` 的 `store_unlock` 动态排序与生成，不硬编码关卡号，不改变系列门控、定价或已购短路逻辑，也不提前泄露未解锁商品身份。
- [x] 地图、出战配置、图鉴顶部资源栏统一移除重复的“战力”第 4 格，只保留金币、星星、经验；出战配置战术摘要内已认可的“有效战力 / 推荐”保持不动。
- [x] 删除地图遗留的资源格死代码与裸“战力”字符串；本地化门禁恢复全绿，M1 smoke 覆盖空存档、30 关解锁、已购回滚可见与三页三格合同。
- [x] 中英文空态和地图 / 出战 / 图鉴三页截图通过实图复核，保存在 `artifacts/design30_task12/`。

## 阶段 164 · 上线走查 P1：图鉴信息去重与机制单位（2026-08-15）

- [x] 武器、护甲、芯片、宠物卡片统一为“标签负责一眼识别、正文只保留未展示数值”的两层信息结构；元素、抗性、属性名和特殊机制不再在同一卡片重复出现。
- [x] 武器特殊属性只在实际数值大于零时生成机制标签；一级自动机枪只保留“物理”元素标签，不再把“扩散 0”或替代占位文案包装成特殊机制。
- [x] 按运行时实际语义补全单位：`spread` 明确为角度，显示“扩散 10°”；`cloud` 明确为作用半径，显示“毒云范围 120”；`chain` 明确为额外目标数，显示“自带连锁 +2 目标”。
- [x] 芯片正文改为“当前加成 +数值”，不重复属性名，也不再显示四舍五入后无意义的“下级 +0%”。
- [x] 本地化与 M1 smoke 锁定中英文去重、零值标签抑制和三类单位；四类图鉴中英文八张实图保存在 `artifacts/design30_task3/`。

## 阶段 165 · 战力 3.0 中期走廊与保守选卡期望（2026-08-15）

- [x] 玩家侧与 Python 镜像统一为“保底卡按实计 + 非保底卡按最弱正收益兼容卡计”；物理武器面对非物理弱点时先消耗一个真实卡位取得对应弹种。
- [x] 合同参考永久技能等级按累计 XP 分档，单一工具 fixture 覆盖按节奏免费族与 71 关后的最强免费族；生成合同把 fixture manifest 一并落表供 Godot smoke 读取。
- [x] 2–70 关精确比值全部落在 `[1.00,1.40]`，71–98 关全部落在 `[0.95,1.40]`；完整 99 关扫描与逐轴校准记录写入 `design/32` 附录。
- [x] 099 锚点保持 `R=1.1643/Boss`、055 Owner 锚点保持 `R=0.9430/防线`；反向物理 055、半速 085 与雷霆 L1@013 风险线均进入 CI。
- [x] 真实难度引擎、`min_output`、经济压力、波次、敌方 HP、伤害与星级阈值零改动；Godot M1 smoke 已恢复 2/13/25/40/50/70/85/98 八关走廊采样断言。

## 阶段 166 · 终局 Apex 单体 / 双 Boss 双口径审计（2026-08-15）

- [x] `check_endgame_balance.py` 保留并明确标注 Apex 单体相位审计，L99 继续钉住 `116.6s / 21` 次技能窗合同。
- [x] 新增 099 双 Boss 全程审计，从 `waves`、`runtime_bosses` 与 `power_contract.boss_effective_hp` 动态读取阵容和 `334.61M` 机制等效血量。
- [x] 三套免费满配逐一输出：自动机枪 `323.8s`、磁轨炮 `279.9s`、散弹炮 `164.3s`，全部如实对照固定 `460s` cap，不为构筑修改上限。
- [x] 最强免费散弹炮落入 `[150,185]s`，毕业构筑明确为散弹炮族；自动机枪仍在 cap 内，因此无需触发“超 cap”判定分支。
