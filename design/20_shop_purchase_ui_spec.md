# 20 · 商店购买系统 + UI 详细规格(Codex 实现照此抄)

> 配套 `design/19_economy_rebalance_plan.md`。本文把**"星星阈值自动解锁 → 商店消费购买"** 的状态机、存档、API、UI、迁移、验收讲到"可直接实现"。
> 现状:`meta/shop/` 是空目录;实际是 `meta/collection/collection.gd` 兼做浏览+升级;锁定物品现在只是灰显 + 文案"需要 X 星解锁"(到阈值自动解锁,**无购买按钮**)。本次在 `collection` 内扩展,不新建独立 shop 场景。

## 0. 改动文件
- `core/save/save_manager.gd`(核心:钱包、购买、升级、迁移)
- `data/*.json`(价格/费用,见 19)
- `meta/collection/collection.gd` + `collection.tscn`(UI 状态与交互)
- `meta/map/map.gd`(顶栏星显示口径)
- 复用音效:`AudioManager.play_sfx("star_gain"/"gold_pickup"/"upgrade_success"/"ui_cancel")`

---

## 1. 物品生命周期状态机
每件**装备/角色**(角色/主炮/护甲/芯片/宝宝):
```
NOT_OWNED ──购买(扣 star)──▶ OWNED(Lv1) ──升级(扣 gold)──▶ OWNED(Lv n) ──▶ MAX(Lv max)
   │                              │
   │(默认免费件直接 OWNED@Lv1)      └──(已购买的可被"装备")
```
**技能**(16 通用 + 8 专属)走另一条:
```
base_level 0 ──升级(扣 xp)──▶ base_level 1 … ──▶ base_level 5(MAX)
```
- 角色/装备:`star` 买断"拥有权"(一次),之后 `gold` 升级 `level`(1→max_level)。
- 技能:`xp` 升 `base_level`(0→5)。技能不需要"购买拥有",直接可升(但需先在池中,见 19 解锁规则——通用技能默认在池)。
- 状态叠加:OWNED 的装备还有"未装备 / 已装备(EQUIPPED)"。

---

## 2. 存档数据模型 + 迁移(关键,别搞错)

### 2.1 字段(`save_data`)
```jsonc
{
  "player": {"gold": int, "xp": int, "star": int},   // star/xp = 可消费钱包(可扣)
  "unlocks": {                                        // 含义改为"已购买/已拥有"
     "characters": [id...], "weapons": [id...], "armors": [id...],
     "chips": [id...], "pets": [id...]
  },
  "equipment": { "<item_id>": level(int), "selected_<slot>": id },  // 升级等级 + 已装备
  "skill_base_levels": { "<skill_id>": int(0..5) },  // 新增:技能持久等级
  "levels_progress": { "<level_id>": best_stars },   // 不变;终身星=其总和
  "save_version": int
}
```
- **可消费星钱包 = `player.star`**(购买时 -=)。
- **终身星(完成度)= `get_total_stars()`**(= Σ levels_progress,**不扣**,仅展示 X/297)。
- 注意:旧逻辑里 `player.star` 与 `get_total_stars()` 数值相等(都=累计、从不扣)。新逻辑下 `player.star` 开始会因购买而 < 终身星,这是预期。

### 2.2 迁移(老存档,务必做)
老存档里 `unlocks.*` 是"阈值自动解锁"塞进去的(可能含很多未付费物品),且 `player.star` = 终身星(没扣过)。迁移规则:
1. **既往不咎**:老存档里已在 `unlocks.*` 的物品,**视为已拥有**(免费保留),不回收、不补扣。
2. `player.star` 保持现值(作为初始可消费钱包)。
3. 新增 `skill_base_levels`:缺省全 0(或把"默认在池"的通用技能给 base_level 1,见 19;二选一,推荐全 0 由玩家用 xp 升)。
4. 写 `save_version` 标记已迁移;迁移只跑一次。
5. **新档**:`unlocks.*` 只含默认免费件(见 §7);`player.star=0`。
> ⚠️ 关键:**删除/停用 `_refresh_star_unlocks()` 的"自动塞入"行为**(`save_manager.gd:168-188`),否则会和"购买"打架(自动解锁会让购买失去意义)。`apply_level_result` 里对它的调用一并移除。

---

## 3. SaveManager API(精确签名 + 行为 + 返回)

```gdscript
# —— 钱包 ——
func get_player_star() -> int            # = player.star(可消费)
func get_player_gold() -> int            # 已有
func get_player_xp() -> int              # = player.xp(可消费)
func get_total_stars() -> int            # 已有;终身星(展示用),不动

# —— 价格/拥有 ——
func get_unlock_price_star(table, id) -> int   # 读 unlock_cost_star
func is_item_owned(slot, id) -> bool           # = unlocks[slot+s].has(id)(替代旧 is_item_unlocked 语义)
func is_default_free(table, id) -> bool        # 见 §7

# —— 购买(扣星) ——
enum PurchaseResult { OK, ALREADY_OWNED, NOT_ENOUGH_STAR, INVALID }
func can_purchase(table, id) -> bool           # 未拥有 且 player.star >= price
func purchase_item(table, id) -> int           # 返回 PurchaseResult
#   行为:校验→ player.star -= price → unlocks[slot+s].append(id) → equipment[id]=max(1,现值) → save_game()
#   不可退款;原子写(写临时→rename)。

# —— 金币升级(已有,价格公式改线性见19) ——
func get_item_upgrade_cost(table, id) -> int   # 已有
func can_upgrade_item(table, id) -> bool       # 已有:需 is_item_owned 且 未满级 且 gold 够
func upgrade_item(table, id) -> bool           # 已有

# —— 技能 base_level(扣经验,新) ——
func get_skill_base_level(skill_id) -> int                 # = skill_base_levels.get(id,0)
func get_skill_base_max(skill_id) -> int                   # = skills.json 最大 lv(=5)
func get_skill_base_upgrade_cost(skill_id) -> int          # = xp_cost_table[当前base_level](见19)
func can_upgrade_skill_base(skill_id) -> bool              # 未满 且 player.xp >= cost
func upgrade_skill_base(skill_id) -> bool                  # player.xp -= cost; base_level+=1; save
```
- 装备前置:`select_item(slot,id)` 要求 `is_item_owned`(已有逻辑保留)。
- 战斗里:`skill_runtime` 初始 `run_level = get_skill_base_level(id)`(见 19 §4.1)。

---

## 4. UI 规格 —— 在 `collection.gd` 扩展(每类一页:角色/主炮/护甲/芯片/宝宝/技能)

### 4.1 顶栏(Header)
左:返回。右:**两/三个钱包芯片**
- `★ {player.star}`(可消费,商店用)+ 小字 `完成度 {get_total_stars()}/297`
- `⛁ {player.gold}`
- 技能页额外显示 `✦ {player.xp}`
图标用 `icon_currency_star.png / icon_currency_gold.png / icon_talent_point.png`(或 xp 图标)。

### 4.2 物品卡的 5 种状态(装备/角色页)
| 状态 | 外观 | 主按钮 | 文案 |
|---|---|---|---|
| **未拥有·买得起** | 正常色,价签高亮 | `购买` (主色) | 按钮:`购买 {price}★` |
| **未拥有·买不起** | 略灰,价签红 | `购买`(禁用) | `购买 {price}★`,下方小字 `你有 {player.star}★` |
| **已拥有·可升级** | 正常色 | `升级`(蓝) | `升级 {gold_cost}金 · Lv{level}` |
| **已拥有·满级** | 正常色,金边 | 无/置灰 | `已满级 Lv{max}` |
| **已拥有·当前装备** | 金色高亮边 | `升级` + 角标`已装备` | 同"可升级" |
卡片点击体:未拥有→弹购买确认;已拥有→进入"详情/装备/升级"(已拥有时单击=装备该件,长按/详情按钮=看数值,与现有 select 流一致)。

### 4.3 购买交互
1. 点`购买`→ **二次确认弹窗**(贵重件 price ≥ 30★ 才弹;便宜件可直接买):`确认花费 {price}★ 购买 {名称}?` [取消] [购买]。
2. 成功:`purchase_item` OK → 扣星动画(★芯片数字跳减)+ `play_sfx("star_gain")` + 卡片切到"已拥有·可升级" + 自动选中可选装备 → `_refresh()`。
3. 失败(钱不够,理论上按钮已禁用):`play_sfx("ui_cancel")` + 价签红闪 + toast`星星不足`。

### 4.4 升级交互(金币 / 经验)
- 装备`升级`:`upgrade_item` → 扣金动画 + `play_sfx("upgrade_success")` + Lv+1 + 刷新费用(线性递增)。买不起→禁用+灰。
- 技能页:每技能显示 **base_level 圆点(●●●○○ 表示 3/5)** + `升级 {xp_cost}经验`;`upgrade_skill_base` → 扣经验 + 圆点+1 + 展示该级新效果(复用现有 `_make_skill_levels_section` 的效果文案)。满级显示`已精通 5/5`。

### 4.5 "攒钱"可见性(呼应你的诉求)
- 买不起也**永远显示价格 + 你的余额**,让玩家明确"再攒 N★ 就能买"(可加 `还差 {price-player.star}★`)。
- 不隐藏未拥有物品(全目录可见、可向往)。

### 4.6 map 顶栏
`map.gd:28-29` 现用 `get_total_stars()` 显示。改为:`金币 {gold}　★可用 {player.star}　完成度 {total}/297　战力 {power}`。

---

## 5. 默认免费件(§见 19 决策5)
`is_default_free` 仅对:`char_vanguard`、`weapon_autocannon` 返回 true(新档即 OWNED@Lv1、已装备)。
**护甲/芯片/宝宝无任何免费件**;`armor_kevlar`、`chip_attack` 也要在 JSON 里带 `unlock_cost_star=5`(不再 0)。
- 玩家开局:仅 vanguard + autocannon;**前 5 关裸装可通**(由 `check_level_pressure` + 实测保证,见 19 §3)。

---

## 6. 边界用例(必须正确)
1. 重复购买 → `ALREADY_OWNED`,不二次扣星。
2. 购买后立即可被 `select_item` 装备;未拥有不可装备。
3. 升级/购买后**原子写存档**;关游戏重启,拥有/等级/技能 base_level/钱包**全部保留**。
4. 钱不够时按钮禁用而非报错;不出现负余额。
5. 满级不再可升;技能 base_level 封顶 5。
6. 迁移只跑一次(看 `save_version`);老存档已解锁件不丢、不补扣。
7. 删除自动解锁后,确保没有别处仍调用 `_refresh_star_unlocks` 把物品塞进 unlocks。

---

## 7. 验收(Codex 自检)
静态:`python3 tools/validate_data.py`(价格/字段齐全)。
脚本/真机:
- 新档:仅 vanguard+autocannon 已拥有;星=0;护甲/芯片/宝宝全为"未拥有·买不起"。
- 通关攒星 → 买得起最便宜护甲(kevlar 5★)→ 购买扣星成功 → 可装备 → 重启仍在。
- 星不足时购买按钮禁用、点击有拒绝反馈。
- 金币升级:Lv 上升、费用线性递增、满级置灰。
- 技能页:用经验把某技能 base_level 0→5,圆点与效果文案更新,重启保留;战斗内该技能从 base_level 起步。
- 迁移:载入一个"旧式"存档(unlocks 里有付费件)→ 这些件仍为已拥有、不被扣星。
- 回归:`godot --headless --path . --script res://tools/m1_smoke_test.gd` 通过。

## 8. 不要做
- 不新建独立 shop 场景(在 collection 内扩展即可);不重写 collection 整体结构。
- 不动 loadout 的"选择已拥有装备"流程(仅让"是否拥有"来自购买而非自动解锁)。
- 不改战斗玩法/数值之外的东西；如购买/图鉴体验需要更好的图标或原型，GPT/Codex 可按 owner 授权生成并登记替换素材。
