# 数据驱动 JSON Schema 定义

> 所有游戏内容都由 `res://data/*.json` 驱动，程序读表、设计师/工具改表。
> ID 一律取自 `naming_convention.md` 第 6 节。本文定义每张表的字段结构（JSONC 注释仅说明，实际文件为纯 JSON）。
> 设计文档（00–09）是"为什么"，本文是"长什么样"，二者必须一致。

## 通用约定
- 所有表是 `{ "id": {...} }` 的对象映射或 `[{...}]` 数组（下注明）。
- 文案不写死在表里，用 `name_key` 指向 `localization_zh.json`（见末节）。
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
      "level_damage_growth": 0.004, // weapon 挂钩技能应低，避免和主武器成长重复爆炸
      "rank_damage_bonus": 0.03,
      "rank_duration_bonus": 0.20,
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
- `character`：基于角色自身攻击和角色等级，不重复吃主武器等级，技能成长可以更明显，适合火焰、冰霜、雷电等角色领域/爆发技能。

`bullet_affinity` 是角色被动与弹种绑定的主入口。不同元素可扩展字段：火焰 `splash_bonus/status_bonus`，冰霜 `slow_bonus/shatter_bonus`，闪电 `chain_bonus/status_bonus`，物理 `pierce_bonus`。

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
  "pet_frost_wisp": {
    "name_key":"pet_frost_wisp", "element":"ice",
    "atk_coef":0.6, "attack_type":"ice_bolt",
    "pet_skill":{"id":"frost_aura","cd":8,"effect":{"slow":0.3,"radius":300}},
    "stat_bonus":{"slow_strength_mult":0.08,"base_hp_mult":0.025}, // 可选：宠物提供的全局属性
    "level_stat_growth":{"slow_strength_mult":0.006,"base_hp_mult":0.002}, // 可选：每级成长
    "rarity":"epic","max_level":60,"cost_base_gold":350,
    "unlock":{"type":"star","price":6},
    "sprite_prefix":"pet_frost_wisp"
  }
}
```
`stat_bonus` 当前支持：`damage_mult`、`fire_rate_mult`、`element_damage_mult`、`crit_rate`、`slow_strength_mult`、`base_hp_mult`、`breach_damage_reduction`、`chain_bonus`、`pierce_bonus`、`gold_mult`。数值型百分比使用小数（`0.08` = +8%），`chain_bonus` / `pierce_bonus` 使用可四舍五入的数量值。

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
    "sprite_prefix":"zombie_armored",
    "anim":["idle","walk","attack","hurt","death"]
  }
}
```

## bosses.json
```jsonc
{
  "boss_void_phantom": {
    "name_key":"boss_void_phantom", "appear_level":72,
    "hp_coef":45, "phases":2,
    "immune":["physical_is_only"],   // 全元素免疫→只吃物理（特殊标记）
    "weakness":"physical",
    "mechanic":"phase_intangible",
    "mechanic_params":{"phase_interval":8,"phase_duration":2.5},
    "intro_video":"vid_boss_intro_void_phantom.mp4",
    "sprite_prefix":"boss_void_phantom",
    "anim":["idle","attack","hurt","death","special"]
  }
}
```

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
  "ENEMY_SPEED_MULT": 0.82,
  "PLAYER_FIRE_RATE_MULT": 0.25,
  "PLAYER_SHOT_DAMAGE_MULT": 3.0,
  "late_wave_hp_bonus": {"3":1.2,"4":1.44,"5":1.62},
  "late_wave_boss_hp_bonus": {"3":1.2,"4":1.2,"5":1.2},
  "boss_hp_level_bonus": {"start_level":20,"multiplier":2.0},
  "level_xp_coef": 50, "level_xp_pow": 1.5,
  "atk_growth_default": 0.08, "hp_growth_default": 0.06,
  "talent_per_level_early": 1, "talent_per_level_late": 2, "talent_late_from": 40,
  "scale_linear": 0.10, "scale_quad": 0.004,
  "crit_dmg_base": 1.5,
  "weakness_mult": 1.5, "resist_mult": 0.5,
  "gold_drop_base": 10, "gold_drop_per_level": 2,
  "first_clear_gold_base": 100, "first_clear_gold_per_level": 20,
  "upgrade_cost_growth": 1.15,
  "card_director": {
    "base_reroll_per_run": 1,
    "pity_after_missing_core_tag": 2,
    "max_economy_cards_per_offer": 1,
    "early_fun_card_boost_until_level": 5
  },
  "star_total_cap": 297
}
```
- `PLAYER_FIRE_RATE_MULT / PLAYER_SHOT_DAMAGE_MULT` 是主武器手感旋钮：当前基础射速节奏值为 `0.25`，单发伤害补偿为 `3.0`；关卡压力由 `tools/rebalance_difficulty.py` 按推荐等级 DPS 重新反推。
- `late_wave_hp_bonus` 是普通僵尸/支援怪的后半段波次血量旋钮；当前第 3 波 +20%，第 4 波在原 1.20 基础上再 +20% 到 1.44，第 5 波在原 1.35 基础上再 +20% 到 1.62。
- `late_wave_boss_hp_bonus` 是 Boss 单独旋钮，避免 Boss 误吃普通怪后期加成；当前第 5 波 Boss 按 owner 要求整体 +20%。
- `boss_hp_level_bonus` 是关卡段 boss 血量旋钮；当前从第 20 关开始，所有 boss 额外乘 `2.0`，只影响 boss HP/压力估算，不提高 boss 伤害。

## challenges.json （数组，M3/M4 后启用）
```jsonc
[
  {
    "id":"challenge_city_swarm",
    "name_key":"challenge_city_swarm",
    "base_level":"level_010",
    "mutation_tags":["double_runners","bonus_elites"],
    "reward":{"gold":500,"skin_shard":"skin_city_badge"},
    "affects_main_progress":false
  }
]
```

## localization_zh.json （文案集中，预留英文 localization_en.json）
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

---

## 校验工具（见 13）
- 启动时校验：所有 `*.json` 引用的 ID/资源文件是否存在、是否有孤儿引用。
- 配表自检脚本：跑 `09 §6` 可过性矩阵。
- CI（可选）：JSON schema 校验 + 资源存在性检查。
