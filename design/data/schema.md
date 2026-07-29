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
      "pierce_bonus": 1,           // 可选：物理穿透
      "rank_pierce_bonus": 1       // 可选：成长档位达到 II 后追加
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
- `sig_level_*`：角色专属主动技的独立 `0-5` 级成长。所有主动技必须至少声明伤害增幅与冷却缩减；各技能再通过持续时间、范围、状态强度、阈值数组或每 N 级机制增量形成可感知质变。

`bullet_affinity` 是角色被动与弹种绑定的主入口。不同元素可扩展字段：火焰 `splash_bonus/status_bonus`，冰霜 `slow_bonus/shatter_bonus`，闪电 `chain_bonus/status_bonus`，物理 `pierce_bonus`。闪电还可声明 `chain_overflow_reference`、`chain_overflow_damage_bonus` 与 `chain_target_falloff`：连锁数量不设代码硬上限，超过参考数量的成长转化为主目标增伤，同时后续连锁按递减系数控制密集尸潮收益。

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
  "endless_template_level": "level_025",
  "endless_boss_immunity_grace_loops": 1,
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
- `boss_survival_hp_ramp` 是第 50 关起的 Boss 专用展示窗口倍率；第 98 关达到 `56.0x`，第 99 关为 `60.48x`，只乘 HP，不改变伤害、攻击频率、移速或机制数值。曲线依据真实运行时的满级散弹 / 多重 / 穿透 / 分裂 / 弹射 / 暴击 / 主动技组合校准。
- `endless_template_level` 是无限尸潮的独立模板关卡；无论从哪一关入口进入，无尽首轮都按该模板的波次、推荐强度、金币等级和 HP 基准起步。
- `endless_boss_immunity_grace_loops` 控制无尽前几轮 Boss 是否移除硬免疫，避免第一轮出现“打不掉血”的元素/破甲墙。
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
    "icon":"weapon_railgun_icon.png"
  }
}
```

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
      "lunge":25                        // 仅补充向屏幕下方的位移，不替代姿势
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

## bosses.json
```jsonc
{
  "boss_void_phantom": {
    "name_key":"boss_void_phantom", "appear_level":72,
    "hp_coef":45, "phases":2,
    "immune":["physical_is_only"],   // 全元素免疫→只吃物理（特殊标记）
	    "weakness":"physical",
	    "counter_hint":"使用物理破防主轴，并搭配控制或屏障。",
	    "phase_cues":[{"threshold":0.67,"text":"终焉护阵","color":"ffb02e"}],
    "mechanic":"phase_intangible",
    "mechanic_params":{"phase_interval":8,"phase_duration":2.5,"immune_damage_floor":0.08},
    "intro_video":"vid_boss_intro_void_phantom.mp4",
    "sprite_prefix":"boss_void_phantom",
    "anim":["idle","attack","hurt","death","special"]
  }
}
```
`immune_damage_floor` 仅用于 Boss 的错误元素保底伤害比例；必须大于 `0`，以免形成绝对软锁。未声明时使用运行时通用值 `0.18`，终局 Boss 可按毕业配装检查收紧。`phase_cues` 按血量阈值驱动阶段播报，`counter_hint` 同时用于失败战报，不在战斗脚本硬编码首领文案。

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

## levels.json （数组，见 08 完整示例）
```jsonc
[
  { "id":"level_001","env":"env_lava_foundry","chapter":1,
    "recommend_level":1,"difficulty_coef":1.0,
    "primary_weakness":"fire","base_hp_ref":100,
    "threat_tags":["anti_swarm","breach"],
    "card_bias":{"anti_swarm":1.2,"control":1.0,"economy":0.8},
    "onboarding_stage":"aim_and_first_card",
    "waves":[ { "wave":1,"spawns":[
        {"type":"zombie_shambler","count":5,"interval":1.2,"lane":"spread"} ] } ],
    "star_rule":"base_hp_percent",
    "first_clear_reward":{"gold":120},
    "first_3star_reward":{"drop":null} }
  // ... 至 level_099
]
```
波次 `lane`：`center|left|right|spread`。Boss wave：`{"wave":"boss","boss":"...","support":[...]}`。

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
  "endless_template_level": "level_025",
  "endless_boss_immunity_grace_loops": 1,
  "endless_first_loop_armor_hits_cap": 8,
  "level_xp_coef": 50, "level_xp_pow": 1.0,
  "atk_growth_default": 0.08, "hp_growth_default": 0.06,
  "talent_per_level_early": 1, "talent_per_level_late": 2, "talent_late_from": 40,
  "scale_linear": 0.10, "scale_quad": 0.004,
  "crit_dmg_base": 1.5,
  "weakness_mult": 1.5, "resist_mult": 0.5,
  "star_thresholds": {"three_star_hp_ratio": 0.70, "two_star_hp_ratio": 0.35},
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
  },
  "star_total_cap": 297
}
```
- `ENEMY_SPEED_MULT` 是普通僵尸与 Boss 共享的基础移动速度旋钮；`BOSS_SPEED_MULT` 是 Boss 专用追加倍率，当前 `1.5` 表示 Boss 在共享速度口径之上再快 50%，不影响普通僵尸、HP、伤害或奖励。
- `PLAYER_FIRE_RATE_MULT / PLAYER_SHOT_DAMAGE_MULT` 是主武器手感旋钮：当前基础射速节奏值为 `0.25`，单发伤害补偿为 `3.0`；关卡压力由 `tools/rebalance_difficulty.py` 按推荐等级 DPS 重新反推。
- `late_wave_hp_bonus` 是普通僵尸/支援怪的后半段波次血量旋钮；当前第 3/4/5 波分别为 `1.45/1.85/2.30`。
- `late_wave_count_mult` 是普通僵尸/支援怪的波次基础数量旋钮；当前第 4/5 波分别为 `2x/3x`。
- `late_wave_count_level_ramp` 是后期第 3 波以后追加的尸潮数量曲线；第 90–98 关为 `1.25x`，第 99 关为 `1.35x`，普通、挑战和无尽模式共用运行时入口，但无尽模板 `level_025` 不会误吃主线曲线。
- `late_wave_boss_hp_bonus` 是 Boss 单独旋钮，避免 Boss 误吃普通怪后期加成；当前第 3/4/5 波分别为 `1.30/1.50/1.75`。
- `late_wave_level_ramp` 是后期第 3 波以后追加的普通怪 / Boss 波基础 HP 曲线；第 98 关为 `2.05x`，第 99 关为 `2.296x`。
- `late_wave_damage_ramp` 是兼容字段，当前及以后都固定为 `1.0x`；后期不再额外提高压线、技能或 Boss 攻城伤害。
- `boss_hp_level_bonus` 是关卡段 boss 血量旋钮；当前从第 20 关开始，所有 boss 额外乘 `2.0`，只影响 boss HP/压力估算，不提高 boss 伤害。
- `boss_survival_hp_ramp` 是后期 Boss 展示窗口旋钮；第 50–98 关由 `1.0x` 曲线提高至 `56.0x`，第 99 关为 `60.48x`，确保即使完整物理技能组合也能让终局 Boss 稳定跨阶段并释放多轮技能。
- `endless_template_level` 固定无尽首轮的独立模板，当前 `level_025` 表示无尽开局约等价二三十关，不继承入口关卡的高阶波次或 HP 曲线。
- `endless_boss_immunity_grace_loops` / `endless_first_loop_armor_hits_cap` 用于避免无尽第一轮 Boss 直接成为硬免疫墙；后续轮次恢复 Boss 原本免疫机制。
- `endless_loop_hp_growth` 是无尽模式完成整轮后的复利 HP 成长；当前每轮至少比上一轮提高 50%，覆盖普通怪和 Boss，普通主线/挑战模式不受影响。
- `boss_level_base_hp_mult` 是 Boss 关的防线血量垫子（design/24 Phase 2，Phase 8 曲线化）：任一波含 `boss` 的关卡，基地血量上限按 `base_hp_ref × 垫子` 起算，之后再乘人物/护甲/芯片/宠物加成。垫子按关卡号取：`≤ early_full_level`（10）为 `early_mult`（1.75），`≥ early_end_level`（25）为 `base`（1.25），中间线性插值；也兼容直接写一个浮点数的旧写法。曲线化的原因是 Boss 关压力呈 U 型（5–20 关与 65–99 关都是 46–57% leak，25–60 关只有 33–46%），平垫子会让玩家最先遇到的三个 Boss 关成为全场最难的一档。只抬防线，不动 Boss HP ramp、不动敌方压力、不动推荐战力公式；无尽模板 `level_025` 含 Boss，故无尽与挑战模式同样吃这个垫子。`tools/simulate_balance.py` 的 `boss_base_hp_cushion()` 与 `battle.gd._boss_level_base_hp_mult()` 是同一条公式的两份实现，改一处必须同步另一处。
- `star_thresholds` 是胜利星级判定的唯一事实来源（design/24 Phase 1）：结算时剩余防线血量比 `>= three_star_hp_ratio` 给 3 星、`>= two_star_hp_ratio` 给 2 星，否则 1 星。运行时经 `core/data/star_rules.gd` 读取，结算页与配装页的提示文案同源动态生成，`tools/simulate_balance.py` 把它换算成 leak% 口径（3 星 leak ≤ 30%、2 星 ≤ 65%）。任何地方都不许再硬编码 `0.70 / 0.35`。`data/levels.json` 的 `star_rule: "base_hp_percent"` 是描述字段，运行时不读。

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
      "premium": false,
      "entitlement": "",
      "ui": {"button_root": "res://assets/production/sprites/ui"},
      "effects": {"character_iridescence": false}
    },
    {
      "id": "neon_tempest",
      "name_zh": "霓虹雷暴",
      "name_en": "Neon Tempest",
      "premium": true,
      "entitlement": "ent_theme_neon_tempest",
      "ui": {"button_root": "res://assets/production/sprites/themes/neon_tempest/ui"},
      "effects": {"character_iridescence": true}
    }
  ]
}
```

- `id` 必须全局唯一，并与 `SaveManager.cosmetics.selected_theme` 一致。
- `entitlement` 是永久权益 ID；默认主题为空。付费主题无已验证权益时必须自动回退 `default`。
- `button_root` 下必须覆盖 `UiKit.NATIVE_BUTTON_SIZES` 的主 / 次两种精确尺寸。
- `character_iridescence` 只控制运行时衣装动态材质，不允许改角色数值；减弱特效时必须静止并降亮。

---

## 校验工具（见 13）
- 启动时校验：所有 `*.json` 引用的 ID/资源文件是否存在、是否有孤儿引用。
- 配表自检脚本：跑 `09 §6` 可过性矩阵。
- CI（可选）：JSON schema 校验 + 资源存在性检查。
