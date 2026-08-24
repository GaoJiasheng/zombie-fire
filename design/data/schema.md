# 数据驱动 JSON Schema 定义

> 所有游戏内容都由 `res://data/*.json` 驱动，程序读表、设计师/工具改表。
> ID 一律取自 `naming_convention.md` 第 6 节。本文定义每张表的字段结构（JSONC 注释仅说明，实际文件为纯 JSON）。
> 设计文档（00–09）是"为什么"，本文是"长什么样"，二者必须一致。

## 通用约定
- 所有表是 `{ "id": {...} }` 的对象映射或 `[{...}]` 数组（下注明）。
- 内容名称不写死在表里，用 `name_key` 同时指向 `localization_zh.json` / `localization_en.json`（见末节）；历史运行时句子由英文目录覆盖。
- 数值留空旋钮（如 coef/base）便于平衡（见 `09`）。

---

## elements.json  （映射）
```jsonc
{
  "fire": {
    "name_key": "elem_fire",
    "color": "#FF5722",
    "on_hit": "burn",          // burn|slow|chain|poison|none
    "dot_coef": 0.25           // 见 09
  }
  // physical/ice/lightning/poison 同结构
}
```

## characters.json （映射）
```jsonc
{
  "vanguard": {
    "name_key": "char_vanguard",
    "element_focus": "physical",
    "role_tag": "balanced",
    "base_atk": 100,           // @Lv1，见 09 公式
    "base_hp": 100,
    "atk_growth": 0.08,
    "hp_growth": 0.06,
    "crit_rate_base": 0.08,
    "fire_rate_mod": 1.0,
    "aim_turn_speed": 1.0,
    "signature_skills": ["sig_vanguard_railvolley", "sig_vanguard_overload"],
    "active_skill": {
      "id": "sig_vanguard_railvolley",
      "scaling_basis": "weapon",  // weapon=按当前主武器伤害轻成长；character=按角色攻击独立成长
	  "coverage_mode": "local", // 可选：local=局部命中；battlefield=每段命中战场内全部存活敌人
      "cooldown": 18.0,
      "duration": 6.0,
      "damage_mult": 1.25,
      "weapon_level_inherit": 0.0, // 仅 character 可选；0~1，继承永久武器等级伤害成长的比例
      "level_damage_growth": 0.004, // weapon 挂钩技能应低，避免和主武器成长重复爆炸
      "rank_damage_bonus": 0.03,
      "rank_duration_bonus": 0.20,
	  "sig_level_damage_bonus": 0.10, // 独立专属技能等级每级伤害增幅
	  "sig_level_cooldown_reduction": 0.03, // 每级缩短基础冷却 3%
	  "sig_level_duration_bonus": 0.35, // 可选：每级增加持续秒数
	  "sig_level_extra_volley_every": 2, // 可选：每 N 级增加一次机制数量
	  "sig_level_extra_target_every": 2,
      "max_extra_volleys": 1
    },
    "bullet_affinity": {
      "element": "physical",       // physical|fire|ice|lightning
      "damage_bonus": 0.10,        // 命中本角色亲和弹种时的固定增伤
      "rank_damage_bonus": 0.025,  // 角色成长档位带来的额外增伤
      "pierce_bonus": 0,           // 可选：初始物理穿透；入门角色建议保持 0
      "rank_pierce_bonus": 2        // 可选：成长档位达到 II 后追加
    },
    "card_affinity_tags": ["projectile","execute","physical"],
    "unlock_cost_star": 0,     // 默认解锁
    "portrait": "res://assets/production/sprites/characters/char_vanguard_icon.png",
    "passive": "breach_guard"
  }
}
```
`active_skill` 是战斗 HUD 的角色主动技按钮来源；主动技能必须声明 `scaling_basis`：

- `weapon`：基于当前主武器攻击，技能本身只给轻量成长，适合弹幕齐射这类“主武器强化”技能。
- `character`：基于角色自身攻击和角色等级，不吃武器自身攻击系数、射速、炮塔倍率；可通过 `weapon_level_inherit`（`0~1`）继承部分永久武器等级伤害成长，避免满配后主动技掉出核心循环。
- `coverage_mode`：默认 `local`，按技能自身的目标 / 半径规则命中；`battlefield` 表示每段伤害覆盖战场内全部存活敌人。它只改变目标覆盖，不进入单体伤害或玩家战力公式，避免把清场语义重复折算为 Boss 数字。
- `sig_level_*`：角色专属主动技的独立 `0-5` 级成长。所有主动技必须至少声明伤害增幅与冷却缩减；各技能再通过持续时间、范围、状态强度、阈值数组或每 N 级机制增量形成可感知质变。

`bullet_affinity` 是角色被动与弹种绑定的主入口。不同元素可扩展字段：火焰 `splash_bonus/status_bonus`，冰霜 `slow_bonus/shatter_bonus`，闪电 `chain_bonus/status_bonus`，物理 `pierce_bonus`。入门角色的 `pierce_bonus` 应保持 `0`，避免一级普通弹在获得技能前就表现成多目标弹药；需要保留的物理角色特色通过 `rank_pierce_bonus` 在成长档位 II 解锁。闪电还可声明 `chain_overflow_reference`、`chain_overflow_damage_bonus` 与 `chain_target_falloff`：连锁数量不设代码硬上限，超过参考数量的成长转化为主目标增伤，同时后续连锁按递减系数控制密集尸潮收益。

## character_body_metrics.json（战斗人体标尺）

```jsonc
{
  "version": 1,
  "canvas_size": [380, 520],
  "target_body_height_px": 420.0,
  "target_foot_offset_px": 100.0,
  "scale_reference_pose": "center",
  "profiles": {
    "standard": {
      "char_vanguard": {
        "idle": {"body_height_px": 435, "foot_y_px": 480, "body_center_x_px": 170},
        "hurt": {"body_height_px": 435, "foot_y_px": 480, "body_center_x_px": 170},
        "left": {"body_height_px": 420, "foot_y_px": 490, "body_center_x_px": 200},
        "center": {"body_height_px": 405, "foot_y_px": 480, "body_center_x_px": 205},
        "right": {"body_height_px": 410, "foot_y_px": 480, "body_center_x_px": 180}
      }
    },
    "weapon_apocalypse_thunder": {
      "char_vanguard": {
        "left": {"body_height_px": 445, "foot_y_px": 490, "body_center_x_px": 210},
        "center": {"body_height_px": 390, "foot_y_px": 495, "body_center_x_px": 190},
        "right": {"body_height_px": 445, "foot_y_px": 490, "body_center_x_px": 170}
      }
    }
  }
}
```

- 这里只记录人物解剖标尺，不记录整张 PNG 的透明外框。`body_height_px` 是头顶到脚底，`foot_y_px` 是落脚线，`body_center_x_px` 是人体中轴；枪械、披风、翅膀和枪口光都不得进入测量。
- `standard` 覆盖普通融合枪模的 `idle / hurt / left / center / right`；每个带 `presentation.true_grip` 的终焉武器必须有同名 profile，并覆盖四角色与三个射击方向。
- `scale_reference_pose` 固定使用 `center`：同一角色 / 同一模型 profile 的待机、受击与左 / 中 / 右开枪帧共用一个人体缩放倍率，姿势只改变人体中轴和脚底锚点；禁止再按蹲姿、后仰等动作高度把开枪帧单独放大。
- 运行时统一人体基础标尺后再乘 `CHARACTER_PRESENTATION_SCALE=1.20`；这是既有 `1.50×` 战场展示的 `80%`。角色等级不再改变人体尺寸，等级差异继续通过属性、徽记与颜色表达。
- 方向 / 动作切换同时应用人体中轴与脚底锚点，枪口坐标跟随同一共用缩放与姿势锚点；主题背挂特效保持独立图层，不得参与人物尺寸计算。

## economy.json 后半波压力旋钮

```jsonc
{
  "late_wave_hp_bonus": {"3": 1.45, "4": 1.85, "5": 2.30},
  "late_wave_count_mult": {"4": 2, "5": 3},
  "late_wave_count_level_ramp": {"start_level": 55, "full_level": 90, "start_wave": 3, "max_mult": 1.25, "curve_power": 1.0, "final_level": 99, "final_mult": 1.08},
  "run_skill_pressure": {
    "reference_card_picks": 4,
    "hp_conversion": 0.65,
    "max_hp_mult": 1.60,
    "speed_conversion": 0.15,
    "max_speed_mult": 1.15
  },
  "late_wave_boss_hp_bonus": {"3": 1.30, "4": 1.50, "5": 1.75},
  "late_wave_level_ramp": {"start_level": 50, "full_level": 98, "max_mult": 2.05, "curve_power": 1.0, "final_level": 99, "final_mult": 1.12},
  "late_wave_damage_ramp": {"start_level": 50, "full_level": 98, "start_wave": 3, "max_mult": 1.0, "curve_power": 1.0, "final_level": 99, "final_mult": 1.0},
  "boss_survival_hp_ramp": {"start_level": 50, "full_level": 98, "max_mult": 56.0, "curve_power": 1.15, "final_level": 99, "final_mult": 1.08},
  "boss_pacing": {
    "mob_slow_cap": 0.8, "boss_slow_cap": 0.4,
    "same_type_hp_start_level": 11,
    "same_type_hp_multipliers": [1.0, 0.82, 0.45, 0.35],
    "finale_level_id": "level_099", "finale_target_seconds": 180.0,
    "finale_time_band": [150.0, 185.0]
  },
  "endless_template_level": "level_025",
  "endless_boss_resistance_grace_loops": 1,
  "endless_first_loop_armor_hits_cap": 8,
  "endless_loop_hp_growth": 0.50
}
```

- `late_wave_hp_bonus` 只加第 3 波及以后普通/支援怪 HP，不影响第 1/2 波开局节奏。
- `late_wave_count_mult` 是波次基础数量倍率；当前第 4 波 `2x`、第 5 波 `3x`，普通、挑战、无尽模式共享同一运行时入口。
- `late_wave_count_level_ramp` 从第 55 关起只对第 3 波以后追加尸潮数量，第 90–98 关达到 `1.25x`，第 99 关达到 `1.35x`；不复制 Boss。
- `run_skill_pressure` 把关卡 `target_card_picks` 对应的局内技能成型空间换算成第 3 波以后的附加压力。`reference_card_picks` 是战力面板基准；当前十次选卡关卡的额外压力约为 `1.54x HP / 1.12x 移速`，并分别受 `max_hp_mult / max_speed_mult` 限制。
- 该压力只读取关卡静态选卡预算，不读取玩家当前血量、实时 DPS 或输赢记录，因此不是动态追赶或惩罚性橡皮筋。挑战模式仍在同一基础上额外应用既定 `1.5x` 敌人生命。
- `late_wave_boss_hp_bonus` 是 Boss 波单独 HP 旋钮，避免 Boss 误吃普通怪的高倍率。
- `late_wave_level_ramp` 从 `start_level` 到 `full_level` 按 `curve_power` 递增，专门吸收中后期局内技能成型后的 DPS 爆发；当前第 98 关为 `2.05x`，第 99 关为 `2.296x`，只影响第 3 波以后。
- `late_wave_damage_ramp` 保留为兼容字段，但 `max_mult / final_mult` 永久固定为 `1.0`；后期难度不得再靠提高僵尸或 Boss 攻击制造暴毙。
- `boss_survival_hp_ramp` 自阶段 186 起只服务缺少 `fixed_hp` 的旧数据兼容。当前 8 个正式 Boss 全部以 `bosses.json.fixed_hp` 作为同型号固定总耐久，普通战役不再读取此倍率；后续难度通过 `levels.json.runtime_bosses` 的显式数量与编队表达。
- `boss_pacing` 是 Boss 节奏唯一数据源：普通怪 / Boss 减速上限分别为 `80% / 40%`。`same_type_hp_multipliers` 只供无尽模式在轮预算内分摊同型 Boss，普通战役的每一只同型 Boss 都保持 `bosses.json.fixed_hp` 全额耐久；终局目标与验收带由 `finale_target_seconds / finale_time_band` 定义。
- `endless_template_level` 是无限尸潮的独立模板关卡；无论从哪一关入口进入，无尽首轮都按该模板的波次、推荐强度、金币等级和 HP 基准起步。
- `endless_boss_resistance_grace_loops` 控制无尽前几轮 Boss 是否暂时移除元素抗性，避免第一轮同时承受抗性与破甲压力。
- `endless_first_loop_armor_hits_cap` 是无尽开局破甲 Boss 的护甲命中上限兜底。
- `endless_loop_hp_growth` 是无尽模式每完成一整轮后的 HP 复利成长下限；当前 `0.50` 表示第 2/3/4 轮约为 `1.5x/2.25x/3.375x`，运行时不会低于代码默认下限。

## skills.json （映射，含成长树）
```jsonc
{
  "skill_split_shot": {
    "name_key": "skill_split_shot",
    "kind": "passive",         // active|passive|hybrid
    "tags": ["projectile"],
    "card_tags": ["projectile","anti_swarm"],
    "exclusive_group": "",     // 可选；同组技能局内互斥
    "ammo_element": "",        // 可选；元素弹药模块使用 fire|ice|lightning|poison
    "weight_rules": {
      "role_affinity": {"vanguard": 1.2},
      "level_need": {"anti_swarm": 1.5},
      "emergency": {"leak_risk_high": 0.8}
    },
    "icon": "skill_split_shot_icon.png",
    "cd": 0,                    // active 才用
    "cost_table": [2,3,5,6,8], // base_level Lv1..Lv5 天赋点累进，见 09
    "levels": [
      { "lv":1, "effect": {"split":2, "falloff":0.5} },
      { "lv":2, "effect": {"split":3, "falloff":0.4} },
      { "lv":3, "branch": [
          {"id":"A_spray","name_key":"...","effect":{"split":5,"spread":"wide"}},
          {"id":"B_focus","name_key":"...","effect":{"split":2,"dmg_mult":1.6}} ] },
      { "lv":4, "effect_by_branch": {"A_spray":{...},"B_focus":{...}} },
      { "lv":5, "ult": [
          {"id":"X_chain_split","requires_branch":"A_spray","effect":{...}},
          {"id":"Y_pierce_split","requires_branch":"B_focus","effect":{...}} ] }
    ]
  }
  // 其余 15 通用 + 8 sig_* 同骨架（sig_* 增 owner:"vanguard"）
}
```
> 局内 `run_level` 不存表（运行时状态）；表里只定义每级效果。两层升级逻辑见 `03`。
> 元素弹药技能使用 `exclusive_group:"projectile_element"` 和 `ammo_element`。物理武器可在火/冰/雷/毒之间选择一种弹药转化；已有元素武器只允许升级同元素模块，不能被其他元素弹药覆盖。
> `skill_multishot.effect.lane_damage_bonus` 是可选的单弹基础伤害回补（小数倍率）。运行时先按总弹道数应用 `1/0.85/0.80/0.75/0.70` 的基础单弹倍率，再叠加该回补并封顶 `1.0`；玩家战力与推荐战力的技能投影必须读取同一字段。

## status_vfx.json（持续异常状态视觉）

持续异常状态的伤害、减速和时长仍由 `enemy.gd` 的战斗状态负责；本表只定义视觉，不得反向改写战斗数值。每个状态独立创建“脚下接触层 + 身体附着循环 + 可选副循环”，允许燃烧、冰冻、中毒、感电同时出现。

```jsonc
{
  "global": {
    "fade_in": 0.10,
    "fade_out": 0.25,
    "full_density_max": 24,
    "condensed_density_max": 48,
    "stack_alpha_two": 0.84,
    "stack_alpha_many": 0.70
  },
  "fire": {
    "sequence": "vfx_enemy_skill_phase_burn",
    "ground_texture": "res://assets/production/sprites/vfx/vfx_input_radial_glow.png",
    "tint": "FFF1D6",
    "ground_tint": "FF5218",
    "normal_scale": 0.25,
    "boss_scale": 0.47,
    "normal_offset": [0, -32],
    "boss_offset": [0, -72],
    "ground_normal_scale": [0.34, 0.105],
    "ground_boss_scale": [0.62, 0.17],
    "ground_normal_offset": [0, 42],
    "ground_boss_offset": [0, 78],
    "alpha": 0.82,
    "ground_alpha": 0.30,
    "fps_mult": 0.86,
    "loop_gap": 0.02,
    "secondary": true,
    "secondary_scale": 0.58,
    "secondary_offset": [-28, 12],
    "secondary_phase": 0.48,
    "follow_sprite": true,
    "z_index": 3
  }
}
```

- 必须定义 `fire / ice / glacier / poison / lightning`。`glacier` 是角色冰川领域中的加强冻结表现，和普通 `ice` 共用冻结文案但不共用视觉强度。
- `sequence` 引用 `assets/production/sprites/vfx_sequences/<id>/<id>_sequence.json`；`ground_texture` 必须为透明 `res://` 图片。
- `normal_* / boss_*` 分开控制普通僵尸与 Boss 的锚点和比例，避免固定缩放造成 Boss 裁切。
- 敌人数量超过 `full_density_max` 后，非优先目标隐藏副循环；超过 `condensed_density_max` 后，非优先目标只保留接触层。锁定目标、自动优先目标、精英和 Boss 始终保持完整语义。
- 两种及以上状态叠加时使用 `stack_alpha_two / stack_alpha_many` 限制总亮度，不采用互斥 `elif`，也不丢失任一状态。

## weapons.json
```jsonc
{
  "weapon_railgun": {
    "name_key":"weapon_railgun", "element":"physical",
    "base_atk_coef":2.4, "fire_rate":1.2,
    "projectile_type":"pierce_heavy",   // 见 06
    "special":{"pierce":2},
    "rarity":"rare", "max_level":50,
    "cost_base_gold":300,               // 强化基数，见 09 公式
    "unlock":{"type":"gold_shop","price":2000},
    "icon":"weapon_railgun_icon.png",
    "handheld":"weapon_railgun_rifle.png",       // 出战页优先使用的无边框枪体；主题可覆盖
    "loadout_art":"optional_clean_showcase.png"  // 可选：仅覆盖出战页展示，不改变战斗持枪/炮台素材
  }
}
```

`weapons.special` 的展示与运行时单位固定为：`spread` 是弹丸扇形夹角（度，运行时通过 `deg_to_rad()` 转换）；`cloud` / `splash` 是战场作用半径；`chain` / `pierce` 是额外目标数量。数值为 `0` 或字段为空表示没有对应机制，图鉴不得把它渲染成高亮标签。

## armors.json
```jsonc
{
  "armor_thermal": {
    "name_key":"armor_thermal",
    "base_hp_add":80, "dmg_reduce":0.05,
    "resist_element":"fire", "resist_value":0.4,
    "special":null, "rarity":"epic", "max_level":60,
    "cost_base_gold":400,
    "unlock":{"type":"star","price":8},
    "icon":"armor_thermal_icon.png"
  }
}
```

## chips.json
```jsonc
{
  "chip_crit": {
    "name_key":"chip_crit", "stat_type":"crit",
    "value_per_level":{"crit_rate":0.01,"crit_dmg":0.02},
    "rarity":"rare","max_level":50,"cost_base_gold":250,
    "selectable_param":null,            // chip_element 用它选元素
    "icon":"chip_crit_icon.png"
  }
}
```

## pets.json
```jsonc
{
  "pet_medic_drone": {
    "name_key":"pet_medic_drone", "role":"repair",
    "pet_skill":{"id":"defense_life_support","name":"防线维生","kind":"repair"},
    "heal_per_wave":8, "level_heal_growth":0.04, // 波次开始：固定修复及其乘法等级成长
    "heal_per_wave_ratio":0.05, "level_wave_heal_ratio_growth":0.001, // 波次开始：最大生命百分比（每级加法成长）
    "repair_interval":18.0,
    "repair_ratio":0.01, "level_repair_ratio_growth":0.00025, // 战斗中周期修复
    "emergency_threshold":0.35,
    "emergency_heal_ratio":0.08, "level_emergency_heal_growth":0.0015,
    "emergency_cooldown":45.0,
    "stat_bonus":{"base_hp_mult":0.07,"breach_damage_reduction":0.05},
    "level_stat_growth":{"base_hp_mult":0.003,"breach_damage_reduction":0.002},
    "max_level":30,"cost_base_gold":125,"unlock_cost_star":13,
    "icon":"res://assets/production/sprites/pets/pet_medic_drone_icon.png",
    "sprite":"res://assets/production/sprites/pets/pet_medic_drone_prototype.png"
  }
}
```
`stat_bonus` 当前支持：`damage_mult`、`fire_rate_mult`、`element_damage_mult`、`crit_rate`、`slow_strength_mult`、`base_hp_mult`、`breach_damage_reduction`、`chain_bonus`、`pierce_bonus`、`gold_mult`。数值型百分比使用小数（`0.08` = +8%），`chain_bonus` / `pierce_bonus` 使用可四舍五入的数量值。

`role:"repair"` 的三层修复均直接作用于基地生命并受最大生命封顶：`heal_per_wave + heal_per_wave_ratio` 用于波次整备，`repair_ratio` 按 `repair_interval` 周期触发，生命不高于 `emergency_threshold` 时可按 `emergency_cooldown` 触发 `emergency_heal_ratio`。三个百分比等级成长字段均为每级加法成长，不使用乘法。

所有宠物都必须定义 `pet_skill`，`kind` 当前允许：`overclock`（短时强化自身射速/伤害）、`area_blast`（目标周围范围打击）、`multi_strike`（多目标连续打击）、`repair`（基地三层修复）、`wave_salvage`（每波等效击杀收益）。战斗、收藏详情、升级预览和战力估算从同一字段读取；带冷却的主动宠物技能必须提供 `cooldown / sequence / sfx`，等级成长字段统一使用 `level_*_growth` 的每级加法口径。

## zombies.json
```jsonc
{
  "zombie_armored": {
    "name_key":"zombie_armored", "tier":2,
    "hp_coef":1.6, "speed":1.0, "bd_coef":1.2,   // breach dmg coef
    "gold_coef":1.4, "run_xp":3,
    "weakness":"lightning", "resist":"physical",
    "threat_tags":["tank","anti_armor"],
    "mechanic":"armor",                 // 见 07；驱动行为脚本
    "mechanic_params":{"phys_reduce":0.5},
    "attack_animation": {
      "mode":"shoulder_ram",            // 20 类普通僵尸的动作语义
      "duration":0.60,                  // 完整预备→命中→收招，秒
      "contact_ratio":0.55,             // 命中点占完整动作的时间比例
      "contact_frame":4,                // 固定绑定 8 帧序列的第 4 帧
      "lunge":25                        // 仅补充向屏幕下方的位移，不替代姿势；mode 同时路由攻击动作音效族
    },
    "sprite":"res://assets/production/sprites/zombies/zombie_armored_prototype.png"
  }
}
```

普通僵尸攻击动画统一为 8 张 512×512 透明帧，路径为
`assets/production/sprites/animations/zombies/<id>/<id>_attack_01..08.png`。
第 1–3 帧是预备，第 4 帧是接触，第 5–8 帧是冲击延续与收招。
运行时必须等到 `duration * contact_ratio` 才结算 `breached`，并在同一刻显示
`contact_frame`；不得在动作开始时提前扣基地血，也不得驻足后循环播放攻击帧。
`duration` 必须在 `0.32..0.8` 秒，`contact_ratio` 在 `0.35..0.68`，
`lunge` 在 `0..40` 设计像素。方向约定固定为从屏幕上方向下方基地进攻。
普通僵尸在动作预备开始时按 `attack_animation.mode` 路由到七个短促动作材质音效族
（普通爪击、快速爪击、撕咬、重击、爆破、腐蚀、支援），实际伤害接触再独立播放
`sfx_enemy_breach` 的钢板 / 沙袋受击声；二者禁止复用同一素材。`zombie_phantom`
只用于相位位移的空气风切声，不得带电弧、爆炸或基地撞击层。普通 `phase`
闪现不得在同一帧叠加通用 `threat_warning`；相位穿行造成近线伤害时也不得播放
物理 `enemy_breach`。Boss `phase_shift` / `dash_combo` 的可见相位移动同样先路由到
`zombie_phantom`，只有随后真实命中防线的接触帧才允许播放 `enemy_breach`。

## bosses.json
```jsonc
{
  "boss_void_phantom": {
    "name_key":"boss_void_phantom", "appear_level":55,
    "hp_coef":36, "phases":2,
    "resistances":{"physical":0.5}, // 数值是减伤比例；0.5 表示该属性减伤 50%
	    "weakness":"lightning",
	    "counter_hint":"使用闪电弱点主轴，并搭配控制或屏障。",
	    "phase_cues":[{"threshold":0.67,"text":"终焉护阵","color":"ffb02e"}],
    "mechanic":"phase_shift",
    "mechanic_params":{"phase_interval":8,"phase_duration":2.5},
    "intro_video":"vid_boss_intro_void_phantom.mp4",
    "sprite_prefix":"boss_void_phantom",
    "anim":["idle","attack","hurt","death","special"]
  }
}
```

- Boss 禁止声明 `immune` 或把任一 `resistances` 值写到 `1.0`。`resistances` 的键必须是五种合法元素，值严格位于 `(0,1)`，表示伤害减免比例而非剩余伤害倍率。
- `fixed_hp` 是正式 Boss 在普通战役中的**单只固定总耐久**；同一 Boss ID 无论出现在哪一关都使用相同值。若缺少该字段才回退到 `hp_coef × 关卡倍率` 的旧兼容路径。`armor_hp_ratio` 可选，范围 `[0,0.6]`，表示从 `fixed_hp` 所定义的总耐久预算中拆给外层装甲的比例，而不是在本体血量之外额外加血。运行时必须渲染装甲 / 本体双条：无伤害穿透时先扣装甲，`armor_penetration` 按比例越过装甲直击本体；持续伤害自身不带穿透。当前钢铁泰坦、亡骸泰坦和终焉霸主使用 `0.3`。
- 弱点增伤读取 `economy.weakness_mult`，当前为 `1.5`（+50%）；未命中弱点或抗性的伤害为 `1.0x`。Boss 血条和命中反馈必须显示对应百分比。
- `regenerate` Boss 必须显式提供 `regen_pct_per_sec`、`damage_regen_suppress_seconds` 与 `weakness_regen_suppress_seconds`，禁止从代码继承隐式回血率。
- `phase_cues` 按血量阈值驱动阶段播报，`counter_hint` 同时用于失败战报，不在战斗脚本硬编码首领文案。

Boss 的基地攻击演出由 `mechanic_params.base_attack_profile` 驱动，不能再退回按 `mechanic` 共用一团通用命中特效：

```jsonc
{
  "base_attack_kind": "boss_inferno_barrage",
  "base_attack_profile": {
    "id": "inferno_barrage",                // 8 个 Boss 间唯一
    "mode": "ranged_volley",                // melee_heavy / ranged_volley / channel / dash_combo
    "label": "熔核三连",
    "element": "fire",
    "hit_elements": [],                     // 可选；逐段覆盖 element，终局复合攻击使用
    "hit_colors": [],                       // 可选；与 hits 等长的 RRGGBB 演出色，不改变伤害元素
    "hits": 3,                              // 1..6，仅拆分动作/VFX 节拍
    "windup": 0.58,
    "hit_gap": 0.18,
    "travel_time": 0.26,
    "first_attack_delay": 1.15,
    "line_offset": -205.0,                  // 相对运行时基地线；远程单位更早驻足
    "cast_sequence": "vfx_enemy_skill_phase_burn",
    "impact_sequence": "vfx_enemy_skill_blast",
    "projectile_style": "orb",
    "impact_scale": 1.18,
    "camera_shake": 8.0
  }
}
```

`hits` 只决定一次攻城动作中可见的段数；一次完整动作仍只发出一次 `breached`，并以既有 `base_attack_damage` 结算总伤害。这样多段连击不会绕过单次伤害上限，也不会额外消耗多层屏障。`cast_sequence` / `impact_sequence` 必须引用 `assets/production/sprites/vfx_sequences/<id>/<id>_sequence.json`。

`channel` 模式还必须提供 `beam_texture` 与 `impact_texture` 两个 `res://` 路径：前者沿施法者到基地的矢量实时缩放，后者只负责基地接触冠。两张资源必须是透明、无矩形底板的独立特效；`impact_sequence` 继续作为资源降级回退。

## environments.json （映射）
```jsonc
{
  "env_lava_foundry": {
    "name": "熔岩铸厂",
    "chapter_title": "第一战区 · 熔岩铸厂",
    "story": "旧城熔炉重新点火，尸潮沿燃烧街区冲向中央防线。先锋队必须夺回十号闸门，切断第一条进攻通道。",
    "objective": "守住熔炉大道，击破驻守十号闸门的大首领。",
    "level_range": "001-010",
    "battle_background": "res://assets/production/sprites/backgrounds/bg_lava_foundry.png",
    "portrait": "res://assets/production/environment/bg_lava_foundry_portrait.png",
    "layout_guide": "res://assets/production/environment/bg_lava_foundry_battle_layout_guide.png",
    "bgm": "battle_city"
  }
}
```
`levels[].env` 必须引用本表。战斗背景、环境预览图、布局安全区、BGM、章节地图标题、章节故事和章节目标都从本表读取，避免在场景脚本里硬编码环境资源或关卡叙事。主线新增战斗背景按 iPhone 17 竖屏全屏比例 `1206x2622` 输出，运行时由 Battle 场景按可见视口 cover 缩放。

## campaign_pacing_targets.json（主线节奏冻结合同）

- `frozen / status` 表示 Owner 是否已经冻结逐关档位目标；B2 使用 `true / b2_owner_frozen`。
- `frozen_contract.authoritative_fire_rate_profile` 是关卡反解唯一权威攻速档；`target_grade_counts` 固定全 99 关目标分布并显式包含 `unwinnable: 0`。
- `chapter6_level_range / chapter6_levels_sha256` 锁定已经验收的第 6 章，后续生成器与审计不得改动其中任意关卡数据。
- `max_free_graduation` 引用 `campaign_progression_fixture.json` 中同 ID 毕业族，要求全 99 关可过且不超时。
- `chapter_level_targets / chapter_quotas / grade_bands` 分别是逐关序列、逐章配额与运行时战线档位带。冻结后只能由 Owner 新决策变更。
- `pacing_rules` 是生成与审计的单一约束源；关卡局部试点数据不能替代冻结合同。

## campaign_progression_fixture.json（主线成长样本）

- 根级样本描述无付费、首通、不刷关的按节奏免费账户；武器购买、升级和出战规则必须数据化并可确定性复现。
- `max_free_graduation` 描述免费满级毕业族：拥有全部非付费角色与装备并升满，每关以共享 `power_for_build` 口径选有效战力最高的完整免费配装。
- `fire_rate_profile` 必须与节奏冻结合同一致；同分时按各数据表原始顺序稳定决胜，禁止随机选择。
- 运行时探针与 Python 审计必须读取同一 fixture，不得各自手写另一份成长或毕业构筑。

## levels.json （数组，见 08 完整示例）
```jsonc
[
  { "id":"level_001","env":"env_lava_foundry","chapter":1,
    "recommend_level":1,"difficulty_coef":1.0,
    "primary_weakness":"fire","base_hp_ref":100,
    "threat_tags":["anti_swarm","breach"],
    "card_bias":{"anti_swarm":1.2,"control":1.0,"economy":0.8},
    "clear_requirement":{
      "min_output":1.0,"mob_hp_share":1.0,"boss_hp_share":0.0,"boss_id":null,
      "power_contract":{
        "model":"bottleneck_v5","recommended_power":11,
        "crowd_capacity":1.0,"boss_capacity":0.0,"line_capacity":0.5,
        "line_expected_breach":52.0,"line_base_hp":160.0,
        "line_target_hp_ratio":0.35,
        "line_exposure_weights":{"crowd":1.0,"boss":0.0},
        "boss_effective_hp":0.0,"boss_weights":{},
        "runtime_boss_pressure_mult":1.0,"guaranteed_skill_ids":[],
        "reference_skill_rank":1
      }
    },
    "onboarding_stage":"aim_and_first_card",
    "run_xp_budget":948,
    "waves":[ { "wave":1,"hp_coef":1.0,"spawns":[
        {"type":"zombie_shambler","count":5,"interval":1.2,"lane":"spread"} ] } ],
    "star_rule":"base_hp_percent",
    "first_clear_reward":{"gold":120},
    "first_3star_reward":{"drop":null} }
  // ... 至 level_099
]
```
波次 `lane`：`center|left|right|spread`。可选 `hp_coef` 默认为 `1.0`，只在普通怪/支援怪现有的 `difficulty_coef × late_wave_hp_bonus × 等级爬坡` 耐久链上追加一层；固定血量 Boss 不读取该字段。未填写时运行时与所有离线工具保持原行为。Boss wave：`{"wave":"boss","boss":"...","support":[...]}`。

可选 `run_xp_budget` 是本关**作者波次**的拓扑中性经验预算：填写后，普通怪、支援怪与主 Boss 的逐只经验按原始经验权重等比归一到该总额，从而在“少量重型单位替代大量轻型单位”时保持永久经验收入与三选一卡牌节奏；`runtime_bosses`、召唤物和无尽模式不计入该预算。缺省时继续逐只读取敌人 `run_xp`，行为完全不变。

终局可选运行时合同示例：

```jsonc
{
  "runtime_bosses":[
    {"wave":5,"type":"boss_apex_overlord","interval":2.4,"lane":"left"},
    {"wave":5,"type":"boss_apex_overlord","interval":2.4,"lane":"right"},
    {"wave":5,"type":"boss_apex_overlord","interval":2.4,"lane":"spread"}
  ],
  "guaranteed_card_offers":[{"offer":1,"skill_ids":["skill_barrier","skill_slow_field"]}]
}
```

- `runtime_bosses` 是运行时在指定波次追加的 Boss，必须由 `battle.gd`、`simulate_balance.py` 与战力合同生成器共同读取；禁止再在战斗代码里按 `variant` 硬编码额外 Boss。中后期 Boss 里程碑用本字段显式组成 2 / 3 / 4 只同型编队；`level_099` 的主波次 Boss 加三条运行时行，共四只 `boss_apex_overlord`。
- `guaranteed_card_offers` 只保证指定第几次三选一中至少出现 `skill_ids` 之一，不自动替玩家选牌。战力模型只可计入这里明确保证的卡，并按候选中较弱的一张保守折算。
- `clear_requirement.power_contract` 由 `tools/generate_clear_requirements.py` 机械生成、`tools/check_clear_requirements.py` 逐关重算校验，不得手填。`recommended_power` 是固定通关线；`crowd_capacity / boss_capacity / line_capacity` 是内部三轴门槛；`boss_weights` 已含运行时追加 Boss 和阶段/机制等效血量。`bottleneck_v5` 通过 `economy.power_ruler.weapon_runtime_axis_calibration` 把武器理论面板倍率转换为实测碰撞产能，并确保 Boss 数量只在 `boss_capacity` 计入一次，禁止在 headline 推荐值上再次乘数量。`line_expected_breach` 是与 `simulate_balance.py` 同源的预计漏怪伤害，`line_base_hp` 是该关参考防线生命，`line_target_hp_ratio` 是通关目标剩余生命边界，`line_exposure_weights` 用小怪/Boss 的血量份额限制清场速度对承伤时间的修正。玩家界面仍只显示一个“战力”，其内部定义为 `recommended_power × min(清群比, Boss比, 防线比)`；防线比最多只获得 `power_ruler.line_exposure_credit_max` 规定的有限清场速度收益。

## economy.json （全局旋钮）
```jsonc
{
  "GLOBAL_HP_BASE": 50, "GLOBAL_DMG_BASE": 10,
  "ENEMY_SPEED_MULT": 0.492,
  "BOSS_SPEED_MULT": 1.5,
  "PLAYER_FIRE_RATE_MULT": 0.25,
  "PLAYER_SHOT_DAMAGE_MULT": 3.0,
  "late_wave_hp_bonus": {"3":1.45,"4":1.85,"5":2.3},
  "late_wave_count_mult": {"4":2,"5":3},
  "late_wave_count_level_ramp": {"start_level":55,"full_level":90,"start_wave":3,"max_mult":1.25,"curve_power":1.0,"final_level":99,"final_mult":1.08},
  "late_wave_boss_hp_bonus": {"3":1.3,"4":1.5,"5":1.75},
  "late_wave_level_ramp": {"start_level":50,"full_level":98,"max_mult":2.05,"curve_power":1.0,"final_level":99,"final_mult":1.12},
  "late_wave_damage_ramp": {"start_level":50,"full_level":98,"start_wave":3,"max_mult":1.0,"curve_power":1.0,"final_level":99,"final_mult":1.0},
  "boss_hp_level_bonus": {"start_level":20,"multiplier":2.0},
  "boss_survival_hp_ramp": {"start_level":50,"full_level":98,"max_mult":56.0,"curve_power":1.15,"final_level":99,"final_mult":1.08},
  "boss_pacing": {
    "mob_slow_cap":0.8,"boss_slow_cap":0.4,"same_type_hp_start_level":11,
    "same_type_hp_multipliers":[1.0,0.82,0.45,0.35],
    "finale_level_id":"level_099","finale_target_seconds":180.0,
    "finale_time_band":[150.0,185.0]
  },
  "endless_template_level": "level_025",
  "endless_boss_resistance_grace_loops": 1,
  "endless_first_loop_armor_hits_cap": 8,
  "level_xp_coef": 50, "level_xp_pow": 1.0,
  "atk_growth_default": 0.08, "hp_growth_default": 0.06,
  "talent_per_level_early": 1, "talent_per_level_late": 2, "talent_late_from": 40,
  "scale_linear": 0.10, "scale_quad": 0.004,
  "crit_dmg_base": 1.5,
  "weakness_mult": 1.5, "resist_mult": 0.5,
  "star_thresholds": {"three_star_hp_ratio": 0.70, "two_star_hp_ratio": 0.35},
  "power_ruler": {
    "crowd_dps_per_capacity": 75.0,
    "boss_dps_per_capacity": 206.98,
    "boss_clear_window_seconds": 180.0,
    "runtime_replay_ratio_targets": {"level_080":1.05,"level_099":1.16},
    "weapon_runtime_axis_calibration": {
      "weapon_autocannon":{"crowd":4.739506,"boss":0.400941}
    },
    "line_requirement_floor": 0.25,
    "line_exposure_credit_min": 0.85,
    "line_exposure_credit_max": 1.15,
    "armor_break_effective_factor": 0.94,
    "boss_mechanic_time_mult": {"phase_shift":1.2821,"multi_phase":1.11}
  },
  "repeat_clear_xp_mult": [1.0, 0.5, 0.25],
  "boss_level_base_hp_mult": {"base": 1.25, "early_mult": 1.75, "early_full_level": 10, "early_end_level": 25},
  "gold_drop_base": 10, "gold_drop_per_level": 2,
  "first_clear_gold_base": 100, "first_clear_gold_per_level": 20,
  "upgrade_cost_growth": 1.15,
  "card_director": {
    "base_reroll_per_run": 1,
    "pity_after_missing_core_tag": 2,
	    "max_economy_cards_per_offer": 1,
	    "early_fun_card_boost_until_level": 5,
	    "opening_identity_offer_count": 2,
	    "opening_avoid_economy": true,
	    "opening_damage_tags": ["anti_swarm","projectile","dps"],
	    "opening_safety_tags": ["control","defense"]
  }
}
```

### 局外养成成本与 UI 资源语义

- 角色、武器、护甲、芯片、宠物的等级强化读取各表 `cost_base_gold`，唯一消费资源为 `gold`。
- 通用技能永久等级读取 `economy.skill_base_xp_costs`，角色专属主动技读取 `economy.sig_skill_xp_costs`，唯一消费资源为 `xp`。
- 免费角色与装备解锁读取 `unlock_cost_star`（兼容旧 `unlock.price`），唯一消费资源为 `star`。
- 玩家可点击的成本必须渲染为“操作文字 + 对应资源图标 + 纯数字数量”；禁止用 `★`、`金币`、`经验` 或 `Gold / XP` 文字假扮图标。关卡评分星仍使用评分星素材，不属于成本组件。
- UI 从 `SaveManager.get_*_cost_spec()` 获取 `{kind, amount}`，再由 `UiKit.currency_icon_path(kind)` 路由图标。当前还登记 `talent_point` 与 `reroll_charge` 图标供未来真实消费入口复用；没有真实消费规则时不得虚构扣除。

- `ENEMY_SPEED_MULT` 是普通僵尸与 Boss 共享的基础移动速度旋钮；`BOSS_SPEED_MULT` 是 Boss 专用追加倍率，当前 `1.5` 表示 Boss 在共享速度口径之上再快 50%，不影响普通僵尸、HP、伤害或奖励。
- `PLAYER_FIRE_RATE_MULT / PLAYER_SHOT_DAMAGE_MULT` 是主武器手感旋钮：当前基础射速节奏值为 `0.25`，单发伤害补偿为 `3.0`；关卡压力由 `tools/rebalance_difficulty.py` 按推荐等级 DPS 重新反推。
- `late_wave_hp_bonus` 是普通僵尸/支援怪的后半段波次血量旋钮；当前第 3/4/5 波分别为 `1.45/1.85/2.30`。
- `late_wave_count_mult` 是普通僵尸/支援怪的波次基础数量旋钮；当前第 4/5 波分别为 `2x/3x`。
- `late_wave_count_level_ramp` 是后期第 3 波以后追加的尸潮数量曲线；第 90–98 关为 `1.25x`，第 99 关为 `1.35x`，普通、挑战和无尽模式共用运行时入口，但无尽模板 `level_025` 不会误吃主线曲线。
- `late_wave_boss_hp_bonus` 是 Boss 单独旋钮，避免 Boss 误吃普通怪后期加成；当前第 3/4/5 波分别为 `1.30/1.50/1.75`。
- `late_wave_level_ramp` 是后期第 3 波以后追加的普通怪 / Boss 波基础 HP 曲线；第 98 关为 `2.05x`，第 99 关为 `2.296x`。
- `late_wave_damage_ramp` 是兼容字段，当前及以后都固定为 `1.0x`；后期不再额外提高压线、技能或 Boss 攻城伤害。
- `boss_hp_level_bonus` 是关卡段 boss 血量旋钮；当前从第 20 关开始，所有 boss 额外乘 `2.0`，只影响 boss HP/压力估算，不提高 boss 伤害。
- `boss_survival_hp_ramp` 是无 `fixed_hp` 旧 Boss 行的兼容旋钮；当前正式 Boss 均不消费它。同型号普通战役耐久只读 `fixed_hp`，多 Boss 压力只读 `runtime_bosses` 数量。
- `boss_pacing.mob_slow_cap / boss_slow_cap` 是减速力场的两条运行时夹取上限：普通怪保持 `80%`，Boss 最多受 `40%` 减速；技能自身五级数据不改。战力防线轴按合同中的小怪 / Boss 暴露份额对两条上限加权，GD 与 Python 必须同源镜像。
- `boss_pacing.same_type_hp_start_level / same_type_hp_multipliers` 只服务无尽 Boss 轮预算内部的同型分摊；普通战役分支明确返回 `1.0`，不得再用隐藏折减抵消 `runtime_bosses` 数量。`finale_level_id / finale_target_seconds / finale_time_band` 是终局生成器与审计的唯一时间合同源。
- `power_ruler.weapon_runtime_axis_calibration` 由 `tools/generate_weapon_power_profiles.py` 从运行时碰撞基准和付费套合同机械生成，分别校准清群与单体命中产能；禁止手填。`runtime_replay_ratio_targets` 只冻结已实测回放的结果语义，当前 80 关压力通关为 `R=1.05`，99 关毕业战为 `R=1.16`。
- `endless_template_level` 固定无尽首轮的独立模板，当前 `level_025` 表示无尽开局约等价二三十关，不继承入口关卡的高阶波次或 HP 曲线。
- `endless_boss_resistance_grace_loops` / `endless_first_loop_armor_hits_cap` 用于避免无尽第一轮 Boss 同时形成抗性与厚装甲墙；后续轮次恢复 Boss 原本的百分比抗性与完整装甲层数。
- `endless_loop_hp_growth` 是无尽模式完成整轮后的复利 HP 成长；当前每轮至少比上一轮提高 50%，覆盖普通怪和 Boss，普通主线/挑战模式不受影响。
- `boss_level_base_hp_mult` 是 Boss 关的防线血量垫子（design/24 Phase 2，Phase 8 曲线化）：任一波含 `boss` 的关卡，基地血量上限按 `base_hp_ref × 垫子` 起算，之后再乘人物/护甲/芯片/宠物加成。垫子按关卡号取：`≤ early_full_level`（10）为 `early_mult`（1.75），`≥ early_end_level`（25）为 `base`（1.25），中间线性插值；也兼容直接写一个浮点数的旧写法。曲线化的原因是 Boss 关压力呈 U 型（5–20 关与 65–99 关都是 46–57% leak，25–60 关只有 33–46%），平垫子会让玩家最先遇到的三个 Boss 关成为全场最难的一档。只抬防线，不动 Boss HP ramp、不动敌方压力、不动推荐战力公式；无尽模板 `level_025` 含 Boss，故无尽与挑战模式同样吃这个垫子。`tools/simulate_balance.py` 的 `boss_base_hp_cushion()` 与 `battle.gd._boss_level_base_hp_mult()` 是同一条公式的两份实现，改一处必须同步另一处。
- `repeat_clear_xp_mult` 是重复通关经验递减表（design/24 收尾）：按**本关此前的通关次数**取下标，首通 `1.0`、二周目 `0.5`、三周目及以后取末位 `0.25`（超出表长时钳到末位）。普通关与挑战模式各自独立计数，分别记在存档的 `level_clear_counts` / `challenge_clear_counts`；失败不计数。倍率在 `battle.gd._finish()` 结算时就已乘进 `result.xp`，因此**结算页显示的就是实际入账的数字**；`SaveManager` 不再二次打折。旧存档缺这两个字段时按首通处理（`_merge_defaults_recursive` 补空字典，无需迁移版本号）。结算页在倍率 < 1 时把经验卡标题显示为 `经 验  ×50%`，百分比由数据算出。
- `environments.json` 的 `audio_mix` 是**按环境的动态混音**（阶段 67）：`sfx_db` / `bgm_db` 是播放器音量偏移（**绝不写总线音量**，否则会和设置页音量滑杆互相覆盖），`reverb_wet`（上限 0.35）/ `reverb_room` / `reverb_damping` 施加在 SFX 总线的混响上。UI 音效走 UI 总线，永远保持干声。进入战斗时由 `battle.gd` 调 `AudioManager.apply_environment_mix()`，离开战斗在 `_exit_tree()` 调 `clear_environment_mix()` 归零。同类枪声/受击声并发上限与 Boss / 主动技 / 防线告急的优先级由 `get_sfx_concurrency_limit()` / `get_sfx_priority()` 负责，与本字段无关。
- `levels.json` 的 `wave_pattern` 是**编队原型**（阶段 67 起真正生效）：`standard` 沿用关卡作者写的 `lane`；`rush` 全部压中路；`pincer` 左右交替、中路留空；`escort` 支援目标走中路、其余贴两翼；`siege` 左/右/散开三路轮转铺满战线。运行时入口是 `battle.gd._formation_lane()`，Boss 不受影响（始终按作者写的通道入场）。阶段 89 起，普通怪在每条通道内使用更宽的安全出生带、`158–222` 的轻微 Y 抖动和 9 选 1 最疏候选采样；最近 6 个出生点及仍在入口带的怪物都会参与防聚簇。Boss 保留较窄作者通道与固定 `y=190` 的聚焦入场。**只改队形几何，不改数量、出怪间隔、HP 或总出怪时长**，因此所有平衡口径与该字段无关。`m1_smoke_test.gd:_verify_wave_formation_lanes` / `_verify_wave_spawn_distribution` 分别锁死编队语义与分散度。
- `levels.json` 的 `variant`（`normal / elite / treasure / boss / boss_rush`）**只决定波次提示文案，不决定是否出怪**。阶段 67 之前出怪循环被错误地缩进在提示分支的 `else` 里，导致 21 个 elite / treasure 关的第 1 波共 442 只敌人从未出现，而平衡模型全程都算了它们；`m1_smoke_test.gd:_verify_variant_wave_one_spawns` 已把这条契约固化。
- `star_thresholds` 是胜利星级判定的唯一事实来源（design/24 Phase 1）：结算时剩余防线血量比 `>= three_star_hp_ratio` 给 3 星、`>= two_star_hp_ratio` 给 2 星，否则 1 星。运行时经 `core/data/star_rules.gd` 读取，结算页与配装页的提示文案同源动态生成，`tools/simulate_balance.py` 把它换算成 leak% 口径（3 星 leak ≤ 30%、2 星 ≤ 65%）。任何地方都不许再硬编码 `0.70 / 0.35`。`data/levels.json` 的 `star_rule: "base_hp_percent"` 是描述字段，运行时不读。
- `wave_pressure` 是 design/35 的 11–99 关自适应增压唯一数据源：`start_level` 锁定前十关完全不动，`target_count_increase / scale_step / star_boundary_margin_pct` 控制目标增幅、反解精度与降星边界净空，`boss_target_waves / non_boss_target_waves` 定义两类关卡只允许改写的波次。`tools/generate_wave_pressure.py` 从冻结的原始数量 fixture 每次重新求解，因此可重复运行且不得手改 89 关；发布门禁同时锁定 13×3★/86×2★/0×1★、逐关不降星与前十关整对象哈希。
- `skill_xp_coverage_contract` 是完整普通战役前三次通关经验供给相对“通用技能 + 角色专属技能全满成本”的覆盖率合同；`target / tolerance` 当前锁定为 `80.9% ±1pp`，由 `tools/check_economy_loop.py` 读取，禁止在检查器另写一份范围。

## challenges.json （按章节固定变体映射）
```jsonc
{
  "chapter_01": {
    "id":"challenge_chapter_01",
    "name":"疾行突袭",
    "summary":"尸潮提速，留出控制窗口",
    "counter_hint":"优先减速、冰霜与多重火力。",
    "hp_mult":1.34,
    "speed_mult":1.12,
    "breach_damage_mult":1.0,
    "mechanic_rate_mult":1.0,
    "recommended_power_mult":1.5
  }
}
```
每 10 关共用一个固定挑战规则；配装页必须在入场前显示名称、压力倍率与应对建议。倍率只由本表读取，结算战报保留同一规则快照。

## localization_zh.json / localization_en.json（稳定 ID 文案）
```jsonc
{
  "char_vanguard": "钢铁先锋",
  "skill_split_shot": "分裂弹",
  "skill_split_shot_desc": "子弹命中后分裂…",
  "zombie_armored": "装甲僵尸",
  "ui_start": "开始", "ui_retry":"再战",
  "ui_target_strategy_breach": "优先越线威胁",
  "ui_card_reroll": "刷新",
  "ui_card_pin": "锁定"
  // 所有展示文案在此；代码/数据只引用 key
}
```

两张表的 key 必须完全一致；`tools/check_localization.py` 会阻止缺 key、英文目标残留中文或占位符不一致。

历史界面仍以中文源字符串编写，英文分为三张运行时目录：

- `localization_ui_en.json`：通用界面、动态模板和 `__terms`；
- `localization_gameplay_en.json`：战斗、技能、配装与结算；
- `localization_story_en.json`：章节、目标、挑战与 Boss 叙事。

格式化源文案（如 `"等级%d"`）必须在英文目录中保留相同占位符类型与数量。完整维护规则见 `design/23_bilingual_localization_framework.md`。

## themes.json（全局视觉主题）

```jsonc
{
  "version": 1,
  "themes": [
    {
      "id": "default",
      "name_zh": "末日防线",
      "name_en": "Last Defense",
	  "description_zh": "原版末日军工界面……",
	  "description_en": "Original industrial-apocalypse UI…",
      "premium": false,
      "entitlement": "",
	  "ui": {"button_root": "res://assets/production/sprites/ui", "accent_color": [0.88,0.64,0.32,1], "tag_palette": {"border": [0.34,0.76,0.84,1], "kind_border": [0.94,0.67,0.32,1], "fill": [0.018,0.06,0.074,0.96], "kind_fill": [0.105,0.064,0.025,0.97], "text": [0.91,0.98,1,1], "kind_text": [1,0.91,0.71,1]}, "surface_modulate": {}},
	  "materials": {},
	  "effects": {"profile": "", "projectile_palette_profile": ""}
    },
    {
      "id": "neon_tempest",
      "name_zh": "霓虹雷暴",
      "name_en": "Neon Tempest",
      "premium": true,
      "entitlement": "ent_theme_neon_tempest",
	  "ui": {
		"button_root": "res://assets/production/sprites/themes/neon_tempest/ui",
		"accent_color": [0.7,0.62,1,1],
		"tag_palette": {"border": [0.2,0.82,1,1], "kind_border": [0.82,0.44,1,1], "fill": [0.018,0.047,0.086,0.97], "kind_fill": [0.08,0.026,0.11,0.97], "text": [0.91,0.98,1,1], "kind_text": [0.97,0.87,1,1]},
		"assets": {},
		"asset_presentations": {},
		"surface_modulate": {"primary": [0.8,0.82,0.86,1], "secondary": [0.92,0.93,0.96,1], "disabled": [0.78,0.8,0.84,1]}
	  },
	  "materials": {
		"character": {"shader": "res://…gdshader", "full": {"effect_intensity": 0.58}, "reduced": {"effect_intensity": 0.24}, "pulse_parameter": "fire_pulse"},
		"surface": {"shader": "res://…gdshader", "full": {"effect_intensity": 0.64}, "reduced": {"effect_intensity": 0.42}}
	  },
	  "effects": {"profile": "neon_tempest", "projectile_palette_profile": "neon_tempest"}
    }
  ]
}
```

- `id` 必须全局唯一，并与 `SaveManager.cosmetics.selected_theme` 一致。
- `entitlement` 是永久权益 ID；默认主题为空。付费主题无已验证权益时必须自动回退 `default`。
- `button_root` 下必须覆盖 `UiKit.NATIVE_BUTTON_SIZES` 的主 / 次两种精确尺寸。
- `description_zh/en` 是主题选择器文案，禁止在 UI 代码里按主题 ID 分支写死。
- `surface_modulate` 只压制主题按钮底图亮度，不得降低子文字亮度。
- `accent_color` 是主题的高层语义强调色；首页副标题与入口强调文案必须跟随它，避免极地主题仍残留炼狱橙等跨主题串色。
- `tag_palette` 是技能图鉴等语义小标签的独立高对比色板：`border/fill/text` 用于能力标签，`kind_border/kind_fill/kind_text` 用于被动/主动等类型标签。每项必须是四通道归一化 RGBA；不可复用低对比背景贴图冒充边框。
- `ui.assets` 可按语义覆盖主题图片；`asset_presentations.<asset_id>.region` 是源图像素坐标裁切 `[x,y,w,h]`，用于剔除设计板留白 / 分隔线而不拉伸素材。`dark_key_threshold / dark_key_softness` 仅用于带暗色设计板底的展示图，运行时将暗底柔和透明化；省略时保留原 alpha。
- `materials.character/surface` 通过 `shader + full/reduced` 通用参数创建材质；`pulse_parameter` 可选。减弱特效必须静止并降亮。
- `effects.profile` 和 `projectile_palette_profile` 是主题表现分发键；战斗调用点只认 profile，不得直接判断主题商品或 entitlement ID。

Save v3 的外观状态结构为：

```jsonc
{
  "cosmetics": {
    "selected_theme": "default",
    "character_outfits": {
      "vanguard": "follow_theme",
      "blaze": "follow_theme",
      "frost": "follow_theme",
      "volt": "follow_theme"
    }
  }
}
```

- `selected_theme` 只控制全局菜单、基地、按钮、枪械配色与环境氛围。
- `character_outfits.<character_id>` 允许 `follow_theme`、`default` 或一项已拥有的主题 ID。`follow_theme` 是旧存档与新角色的安全默认，解析时跟随 `selected_theme`。
- 逐角色覆盖只影响该角色的立绘、战斗动画、动态衣装材质与角色专属开火 / 施法光效，不得改变数值，也不得在战斗中热切换。
- 若付费权益被退款、恢复失败或本地演示被清空，所有指向该主题的逐角色覆盖必须回退 `follow_theme`，全局主题同时回退 `default`。

---

## store_products.json（永久商品目录）

以 Apple product ID 为 key。每行必须声明：

- `kind / offer_role`: 当前都使用 `theme / arsenal_complete / arsenal_upgrade`；`kind` 保留商品类别兼容，购买路由只读取明确的 `offer_role`（缺省才回退 `kind`）。
- `series_id / theme_id / arsenal_set_id`: 商品所属系列及其主题/套装路由；同系列必须恰好各有一条三种 `kind`。
- `grants`: 逻辑 entitlement 数组；完整军械必须同时授予主题与军械权益。
- `name_zh/name_en`、`subtitle_zh/subtitle_en`、商品图和排序。
- `preview_layout`: 玩家商店只允许 `theme_roster / arsenal_grid`。主题固定用四名角色的等尺度半身装束四宫格；完整包与升级包固定用武器 / 护甲 / 芯片 / 宠物实装图标四宫格。旧 `art` 仅作设计来源和兼容回退，不得直接以不同比例的战斗截图、风格板或概念母图混入正式商品列表。
- 装备表可选 `store_preview_region: [x,y,w,h]`，只裁出玩家商店所需的单一主体；用于剔除旧母图里的缩略变体、角标或说明字，不改图鉴、战斗与配装页的原始 `icon`。
- `mock_price_zh/mock_price_en` 只允许用于明确标注“不连接 Apple / 不会扣款”的本地验收商店；生产显示价格必须由 StoreKit 返回。

本表不是真实购买凭证。生产权益真源只能进入 `SaveManager.entitlements.verified`；本地演示记录只进入 `commerce.mock_receipts`，二者禁止合并或互相伪装。

## premium_sets.json（终焉套装）

每个 `set_apocalypse_<series>` 必须映射唯一 `series_id / weapon / armor / chip / pet / theme / theme_entitlement / entitlement`，并数据化声明 `two_piece`、`four_piece`、双语商店状态文案和满级输出验收带宽。

- premium 装备行声明同一 `premium_entitlement` / `premium_set`。
- 购买后装备从 1 级开始，用普通金币升级，不参与星星解锁价格曲线。
- `target_full_set_ratio_min/center/max` 必须由可复现 DPS 审计验证；第一套雷霆为 `1.52 / 1.55 / 1.58`。
- 撤权只收回使用权并回退非法已装备项，不删除已投入的装备等级。
- 商店、权益恢复和一键装备必须遍历 `series_id`，不得再依赖某一套装的代码常量。
- `store_unlock` 同时控制系列在玩家界面的首次揭示与购买授权：未达条件前，商店、主题 / 战衣选择、收藏等入口必须整套隐藏，不得显示系列标题、素材、价格或购买按钮；达成后才生成商品卡。商店空态可以只按 `store_unlock` 动态汇总匿名档位条件，但不得提前泄露系列身份或商品内容。`unlock_hint_zh/en` 与 `unlock_cta_zh/en` 仅作为历史数据兼容 / 内部审核说明保留，不得直接用于未揭示玩家界面。已验证权益始终优先于本地进度门禁。
- 高级武器可在 `weapons.presentation` 声明 `weapon_scale / muzzle_distance / attack_duration / prefire_lead / recoil_pose / recoil_accent / recoil_twist`。`true_grip` 进一步声明根目录、`viewpoint`（竖屏底部防线战斗固定为 `rear`）、三向文件 pattern、画布尺寸及逐角色三向枪口坐标；运行时与视觉校验器都读取同一份数据。
- premium 宠物主动 `kind: fire_flyby` 表示按当前手动锁定 / 自动优先目标执行一次有目标上限的火焰掠场；必须声明冷却、伤害倍率、目标数、衰减、轨迹持续时间与最大并发，不得生成无限地面路径。
- 战报中的 premium 来源必须拆分记录主武器直伤、灼烧、爆燃、护甲反击、宠物与四件套传播；现有 `take_damage` 四参数调用兼容不变，新增来源通过可选上下文传递。

---

## 校验工具（见 13）
- 启动时校验：所有 `*.json` 引用的 ID/资源文件是否存在、是否有孤儿引用。
- 配表自检脚本：跑 `09 §6` 可过性矩阵。
- CI（可选）：JSON schema 校验 + 资源存在性检查。
