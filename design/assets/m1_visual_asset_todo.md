# M1 Visual Asset Todo · 全局图片资产原型包

> M1 需要准备全局图片资产原型包，目的不是最终精修，而是提前锁住全游戏视觉一致性。
> 状态枚举：`needed` / `generated` / `reviewed` / `accepted` / `replace_later`。

## 生产原则

- 先样张，后批量。
- 所有图片遵守 `design/11_art_bible.md` 和 `design/data/naming_convention.md`。
- 动态单位 M1 允许先用 `portrait + icon + prototype_sprite`，骨骼分件可标 `replace_later`。
- 每批生成后必须做 contact sheet，不单张孤立验收。
- 原型图可以粗，但视角、光源、元素色、轮廓语言必须一致。

## 0. 样张组（先做）

| Asset | Files | Status | Notes |
|---|---|---|---|
| `char_vanguard` | portrait / icon / prototype_sprite | accepted | 角色基准；v2 accepted |
| `zombie_shambler` | portrait / icon / prototype_sprite | accepted | 基础僵尸基准；v2 accepted |
| `zombie_runner` | portrait / icon / prototype_sprite | accepted | 快怪剪影基准；v2 accepted |
| `zombie_brute` | portrait / icon / prototype_sprite | accepted | 肉盾体型基准 |
| `boss_tank_titan` | portrait / icon / prototype_sprite | accepted | Boss 体量基准 |
| `weapon_autocannon` | icon / machine-gun prototype | accepted | 玩家长期注视对象 |
| `bg_city_ruins` | background prototype | accepted | 第一章色调基准；后续批量背景要更 stylized |
| `ui_card_frame` | card frame / selected / locked | reviewed | 框架方向可用；技能 icon 需单独重做 |
| `skill_split_shot_icon` | icon | accepted | 弹道技能基准 |
| `skill_pierce_icon` | icon | accepted | 弹道技能基准 |
| `skill_slow_field_icon` | icon | accepted | 防御/控制技能基准 |

## 1. 角色（4）

| ID | Required Files | Status |
|---|---|---|
| `char_vanguard` | portrait / icon / prototype_sprite / parts_later | accepted |
| `char_blaze` | portrait / icon / prototype_sprite / parts_later | accepted |
| `char_frost` | portrait / icon / prototype_sprite / parts_later | accepted |
| `char_volt` | portrait / icon / prototype_sprite / parts_later | accepted |

## 2. 专属技能图标（8）

| ID | Required Files | Status |
|---|---|---|
| `sig_vanguard_railvolley_icon` | icon | accepted |
| `sig_vanguard_overload_icon` | icon | accepted |
| `sig_blaze_napalm_icon` | icon | accepted |
| `sig_blaze_meltdown_icon` | icon | accepted |
| `sig_frost_glacier_icon` | icon | accepted |
| `sig_frost_shatter_icon` | icon | accepted |
| `sig_volt_chain_icon` | icon | accepted |
| `sig_volt_storm_icon` | icon | accepted |

## 3. 通用技能图标（16）

| ID | Required Files | Status |
|---|---|---|
| `skill_split_shot_icon` | icon | accepted |
| `skill_pierce_icon` | icon | accepted |
| `skill_ricochet_icon` | icon | accepted |
| `skill_multishot_icon` | icon | accepted |
| `skill_homing_icon` | icon | accepted |
| `skill_salvo_icon` | icon | accepted |
| `skill_critical_icon` | icon | accepted |
| `skill_charge_shot_icon` | icon | accepted |
| `skill_incendiary_icon` | icon | accepted |
| `skill_cryo_icon` | icon | accepted |
| `skill_tesla_icon` | icon | accepted |
| `skill_venom_icon` | icon | accepted |
| `skill_barrier_icon` | icon | accepted |
| `skill_slow_field_icon` | icon | accepted |
| `skill_gold_rush_icon` | icon | accepted |
| `skill_recycle_icon` | icon | accepted |

## 4. 普通僵尸（20）

| ID | Required Files | Status |
|---|---|---|
| `zombie_shambler` | portrait / icon / prototype_sprite / parts_later | accepted |
| `zombie_runner` | portrait / icon / prototype_sprite / parts_later | accepted |
| `zombie_brute` | portrait / icon / prototype_sprite / parts_later | accepted |
| `zombie_spitter` | portrait / icon / prototype_sprite / parts_later | accepted |
| `zombie_crawler` | portrait / icon / prototype_sprite / parts_later | accepted |
| `zombie_armored` | portrait / icon / prototype_sprite / parts_later | accepted |
| `zombie_bomber` | portrait / icon / prototype_sprite / parts_later | accepted |
| `zombie_shielder` | portrait / icon / prototype_sprite / parts_later | accepted |
| `zombie_hopper` | portrait / icon / prototype_sprite / parts_later | accepted |
| `zombie_screamer` | portrait / icon / prototype_sprite / parts_later | accepted |
| `zombie_juggernaut` | portrait / icon / prototype_sprite / parts_later | accepted |
| `zombie_phantom` | portrait / icon / prototype_sprite / parts_later | accepted |
| `zombie_necromancer` | portrait / icon / prototype_sprite / parts_later | accepted |
| `zombie_toxic` | portrait / icon / prototype_sprite / parts_later | accepted |
| `zombie_charger` | portrait / icon / prototype_sprite / parts_later | accepted |
| `zombie_regenerator` | portrait / icon / prototype_sprite / parts_later | accepted |
| `zombie_splitter` | portrait / icon / prototype_sprite / parts_later | accepted |
| `zombie_warden` | portrait / icon / prototype_sprite / parts_later | accepted |
| `zombie_mutant` | portrait / icon / prototype_sprite / parts_later | accepted |
| `zombie_berserker` | portrait / icon / prototype_sprite / parts_later | accepted |

## 5. Boss（8）

| ID | Required Files | Status |
|---|---|---|
| `boss_tank_titan` | portrait / icon / prototype_sprite / parts_later | accepted |
| `boss_inferno_maw` | portrait / icon / prototype_sprite / parts_later | accepted |
| `boss_frost_warden` | portrait / icon / prototype_sprite / parts_later | accepted |
| `boss_storm_caller` | portrait / icon / prototype_sprite / parts_later | accepted |
| `boss_plague_mother` | portrait / icon / prototype_sprite / parts_later | accepted |
| `boss_void_phantom` | portrait / icon / prototype_sprite / parts_later | accepted |
| `boss_necrotitan` | portrait / icon / prototype_sprite / parts_later | accepted |
| `boss_apex_overlord` | portrait / icon / prototype_sprite / parts_later | accepted |

## 6. 主炮（8）

| ID | Required Files | Status |
|---|---|---|
| `weapon_autocannon` | icon / machine-gun prototype | accepted |
| `weapon_railgun` | icon / turret | accepted |
| `weapon_scattergun` | icon / turret | accepted |
| `weapon_flamethrower` | icon / turret | accepted |
| `weapon_cryocannon` | icon / turret | accepted |
| `weapon_teslacoil` | icon / turret | accepted |
| `weapon_venomlauncher` | icon / turret | accepted |
| `weapon_plasmacannon` | icon / turret | accepted |

## 7. 护甲 / 芯片 / 宝宝

| Category | IDs | Required Files | Status |
|---|---|---|---|
| Armor | `armor_kevlar`, `armor_reactive`, `armor_thermal`, `armor_cryo`, `armor_faraday`, `armor_hazmat` | icon | accepted |
| Chip | `chip_attack`, `chip_health`, `chip_crit`, `chip_haste`, `chip_pierce`, `chip_element`, `chip_greed`, `chip_guardian` | icon | accepted |
| Pet | `pet_turret_drone`, `pet_fire_imp`, `pet_frost_wisp`, `pet_volt_orb`, `pet_medic_drone`, `pet_collector` | portrait / icon / prototype_sprite | accepted |

## 8. 子弹 / 投射物

| File | Status |
|---|---|
| `proj_bullet_physical.png` | accepted |
| `proj_bullet_fire.png` | accepted |
| `proj_bullet_ice.png` | accepted |
| `proj_bullet_lightning.png` | accepted |
| `proj_bullet_poison.png` | accepted |
| `proj_heavy_charge.png` | accepted |
| `proj_acid_spit.png` | accepted |
| `proj_split_mini.png` | accepted |

## 9. VFX 原型

M1 可以先用单帧或短序列帧，之后替换为完整序列。

| Prefix | Status |
|---|---|
| `vfx_hit_physical` | accepted |
| `vfx_hit_fire` | accepted |
| `vfx_hit_ice` | accepted |
| `vfx_hit_lightning` | accepted |
| `vfx_hit_poison` | accepted |
| `vfx_crit` | accepted |
| `vfx_explosion_fire` | accepted |
| `vfx_freeze` | accepted |
| `vfx_chain_lightning` | accepted |
| `vfx_poison_cloud` | accepted |
| `vfx_levelup_glow` | accepted |
| `vfx_death_dissolve` | accepted |
| `vfx_boss_phase` | accepted |
| `vfx_muzzle_physical` | accepted |
| `vfx_muzzle_fire` | accepted |
| `vfx_muzzle_ice` | accepted |
| `vfx_muzzle_lightning` | accepted |
| `vfx_muzzle_poison` | accepted |
| `vfx_target_lock` | accepted |
| `vfx_threat_warning` | accepted |
| `vfx_hit_immune` | accepted |

## 10. 背景

| File | Status |
|---|---|
| `bg_city_ruins.png` | accepted |
| `bg_subway.png` | accepted |
| `bg_military.png` | accepted |
| `bg_biolab.png` | accepted |
| `bg_main_menu.png` | accepted |
| `bg_level_map.png` | accepted |

## 11. UI / Icon 套件

| Category | Files | Status |
|---|---|---|
| Buttons | `ui_button_primary`, `ui_button_secondary` | accepted |
| Panels | `ui_panel`, `ui_card_frame`, `ui_card_frame_fire`, `ui_card_frame_ice`, `ui_card_frame_lightning`, `ui_card_frame_poison`, `ui_card_frame_physical` | accepted |
| Bars | `ui_base_hp_bar`, `ui_wave_progress`, `ui_run_xp_bar`, `ui_shield_bar` | accepted |
| Skill slots | `ui_skill_slot`, `ui_skill_slot_active`, `ui_cd_overlay` | accepted |
| Targeting | `ui_target_strategy_nearest`, `ui_target_strategy_breach`, `ui_target_strategy_elite`, `ui_target_strategy_low_hp`, `ui_target_lock` | accepted |
| Cards | `ui_card_reroll`, `ui_card_pin`, `ui_card_skip`, `ui_card_tag_projectile`, `ui_card_tag_element`, `ui_card_tag_control`, `ui_card_tag_economy` | accepted |
| Stars | `ui_star_filled`, `ui_star_empty` | accepted |
| Currency | `icon_currency_gold`, `icon_currency_xp`, `icon_currency_star`, `icon_talent_point`, `icon_reroll_charge` | accepted |
| Elements | `icon_element_physical`, `icon_element_fire`, `icon_element_ice`, `icon_element_lightning`, `icon_element_poison` | accepted |
| System | `icon_pause`, `icon_settings`, `icon_lock`, `icon_warning` | accepted |

## 12. Contact Sheets

| Sheet | Contents | Status |
|---|---|---|
| `contact_characters.png` | 4 角色 | accepted |
| `contact_zombies_t1_t2.png` | T1/T2 僵尸 | accepted |
| `contact_zombies_t3_t4.png` | T3/T4 僵尸 | accepted |
| `contact_bosses.png` | 8 Boss | accepted |
| `contact_weapons_equipment.png` | 主炮/护甲/芯片/宝宝 | accepted |
| `contact_skills.png` | 24 技能图标 | accepted |
| `contact_ui.png` | UI 套件 | accepted |
| `contact_vfx.png` | VFX 原型 | accepted |
| `contact_backgrounds.png` | 背景 | accepted |
| `contact_battle_mock.png` | 角色/怪/炮塔/UI/背景同屏 | accepted |
