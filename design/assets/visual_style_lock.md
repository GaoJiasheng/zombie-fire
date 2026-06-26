# Visual Style Lock · M1 视觉基准

> 状态：locked
> 这份文件用于锁定 M1 全局图片资产的一致性。样张组通过后，将状态改为 `locked`。

## 核心判断

M1 图片资产允许粗糙，但不允许风格漂移。所有原型图必须看起来像同一个游戏里的素材，而不是不同模型、不同批次、不同 UI 包拼起来。

## 风格定位

- 2.5D 卡通写实，像 3D 渲染过的 2D sprite。
- 竖屏移动端塔防视角，3/4 顶视侧角。
- 末日题材，但颜色保持清楚、饱和、易读。
- 单位轮廓优先，细节服务于识别，不堆噪点。
- UI 是科技军事 HUD + 末日磨损，不做厚重写实仪表盘。

## 固定视觉规则

| 项 | 规则 |
|---|---|
| 光源 | 主光来自画面右上方 |
| 视角 | 3/4 顶视侧角，单位默认面向上方/侧上 |
| 轮廓 | 0.5 秒内能识别单位类型和威胁 |
| 角色 | 更干净、更英雄、更高饱和 |
| 普通僵尸 | 病态青绿基调，剪影差异明显 |
| Boss | 普通僵尸 2.5-4 倍体量，机制特征必须夸张 |
| 炮塔 | 底部中央玩家长期注视对象，机械细节可多 |
| 技能图标 | 中心构图，元素色强，不能靠文字识别 |
| 背景 | 支持战斗可读性，顶部生成区和底部防线要能分辨 |
| UI | 警戒橙描边，深色金属底，清晰边缘 |

## 元素颜色

| 元素 | 色彩 |
|---|---|
| 物理 | 钢灰白 `#D9DEE5` |
| 火 | 橙红 `#FF5722` |
| 冰 | 冰蓝 `#46C6FF` |
| 雷 | 电紫 `#C77DFF` + 电黄 `#FFE14D` |
| 毒 | 毒绿 `#8BE04E` |

元素颜色是硬约束：子弹、技能图标、命中特效、卡框、弱点提示必须一致。

## 样张组验收

样张组必须同时通过下面检查：

- [x] `char_vanguard` 和 `zombie_shambler` 看得出同一光源与视角
- [x] `zombie_runner` 和 `zombie_brute` 剪影差异足够明显
- [x] `boss_tank_titan` 体量和压迫感明显高于普通僵尸
- [x] `weapon_autocannon` 放在底部 HUD 区域仍然清楚
- [x] `bg_city_ruins` 不抢怪物和子弹可读性
- [x] 技能卡框和技能图标像同一个 UI 系统
- [x] 锁定圈/威胁标记清楚但不遮挡目标
- [x] contact sheet 放在一起没有明显批次感

Current accepted anchor:

- `assets/m1_visual/contact_sheets/contact_m1_samples_overview_v1.png`
- `assets/m1_visual/contact_sheets/contact_units_samples_v2.png`
- `assets/m1_visual/contact_sheets/contact_characters.png`
- `assets/m1_visual/samples/bg_city_ruins.png`
- `assets/m1_visual/contact_sheets/contact_skill_icons_v1.png`
- `assets/m1_visual/contact_sheets/contact_targeting_vfx_v1.png`

Notes:

- Hero roster is locked as four distinct archetypes: brawny strongman Vanguard, young fire-guy Blaze, aloof mature female Frost, and electro girl Volt. Future portraits, skins, icons, and cutscene shots must preserve this spread instead of turning the roster into four same-body armored soldiers.
- Unit and turret style is now close enough to anchor batch generation.
- UI card frame direction is usable. For final production, keep card frame as UI layer and avoid baking heavy frames into every skill icon.
- `bg_city_ruins` is accepted for M1, but future backgrounds should be slightly more stylized and less photoreal.
- `vfx_hit_immune` direction is accepted, but final in-battle implementation should be smaller and more particle-like than the shield mock.

## 不接受的情况

- 单位视角忽高忽低。
- 有的图偏写实恐怖，有的图偏 Q 版糖果。
- 元素色不稳定，例如火图标有时红、有时黄、有时紫。
- 背景太暗或太花，导致子弹/怪物看不清。
- UI 过度厚重，挤占战斗视野。
- 技能图标靠小字说明，缩小后看不懂。
- Boss 只是普通僵尸放大，没有机制符号。

## 样张通过后的锁定动作

- [x] 将本文件状态从 `draft` 改为 `locked`
- [x] 在 `m1_visual_asset_todo.md` 将样张状态改为 `accepted`
- [x] 把样张 contact sheet 作为后续批量生产参考
- [x] 后续所有图片批量生成必须对照样张组，不再重新定义风格
