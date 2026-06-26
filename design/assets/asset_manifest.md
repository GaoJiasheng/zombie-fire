# 素材清单（Asset Manifest）

> 全部素材的文件名、类型、尺寸、用途。文件名严格遵守 `data/naming_convention.md`。
> 逐条生成 prompt 见 `prompts_visual.md`（视觉）/ `prompts_audio.md`（音频）。
> 类型：`分件`=透明分件PNG做骨骼动画；`整图`=单张PNG；`序列帧`=多帧PNG；`图标`=方形PNG；`视频`=mp4；`音频`=ogg/wav。

## 0. 动态单位的分件展开规则

凡标注 `分件` 的单位，按 `{prefix}_{part}.png` 出 9 件（按造型增减）：
`head, body, arm_l, arm_r, hand_l, hand_r, leg_l, leg_r, weapon` + `{prefix}_portrait.png`（合体参考）。
动作（idle/walk/attack/hurt/death/special）在引擎里由骨骼驱动，**不另出帧**。

---

## 1. 角色（4）— `char_*` `sig_*`

| 文件名前缀 | 类型 | 尺寸@1x | 用途 |
|---|---|---|---|
| `char_vanguard_*`（分件 9 + portrait） | 分件 | 320×320 | 战斗炮手立绘 + 骨骼 |
| `char_vanguard_portrait.png` | 整图 | 720×1080 | 角色选择/养成大图 |
| `char_vanguard_icon.png` | 图标 | 256×256 | 头像 |
| `char_blaze_* / char_frost_* / char_volt_*` | 同上 | 同上 | 其余 3 角色 |
| `sig_vanguard_railvolley_icon.png` 等 8 个 | 图标 | 512×512 | 8 个专属技图标 |

合计：4 角色 ×（9 分件 + portrait + icon）= 44 ＋ 8 专属技图标。

## 2. 普通僵尸（20）— `zombie_*`

每个僵尸：`分件 9 + portrait`（共 10 件）+ `icon`（图鉴用）。

| ID | 类型 | 尺寸@1x | 备注 |
|---|---|---|---|
| `zombie_shambler_*` | 分件 | 256×256 | T1 |
| `zombie_runner_*` | 分件 | 256×256 | T1，瘦长 |
| `zombie_brute_*` | 分件 | 384×384 | T1，壮硕 |
| `zombie_spitter_*` | 分件 | 256×256 | T1，含口部喷吐 |
| `zombie_crawler_*` | 分件 | 192×192 | T1，矮小 |
| `zombie_armored_*` | 分件 | 288×288 | T2，护甲件 |
| `zombie_bomber_*` | 分件 | 256×256 | T2，体表炸药 |
| `zombie_shielder_*` | 分件 | 288×288 | T2，含盾件 |
| `zombie_hopper_*` | 分件 | 256×256 | T2，腿强化 |
| `zombie_screamer_*` | 分件 | 256×256 | T2，大口 |
| `zombie_juggernaut_*` | 分件 | 448×448 | T3，巨型 |
| `zombie_phantom_*` | 分件 | 256×256 | T3，半透明材质 |
| `zombie_necromancer_*` | 分件 | 288×288 | T3，法袍法杖 |
| `zombie_toxic_*` | 分件 | 288×288 | T3，毒液 |
| `zombie_charger_*` | 分件 | 288×288 | T3，前倾冲刺 |
| `zombie_regenerator_*` | 分件 | 320×320 | T4，再生组织 |
| `zombie_splitter_*` | 分件 | 256×256 | T4，可分裂 |
| `zombie_warden_*` | 分件 | 288×288 | T4，护盾光环 |
| `zombie_mutant_*` | 分件 | 288×288 | T4，可变色 |
| `zombie_berserker_*` | 分件 | 288×288 | T4，狂暴态变体 |

僵尸精英版：**复用同分件**，引擎加发光描边 shader，不另出图。

## 3. Boss（8）— `boss_*` + 登场视频 `vid_*`

每个 Boss：`分件（按造型，通常 9~12 件）+ portrait + icon` + 登场视频。

| ID | 分件类型 | 尺寸@1x | 登场视频 |
|---|---|---|---|
| `boss_tank_titan_*` | 分件 | 768×768 | `vid_boss_intro_tank_titan.mp4` |
| `boss_inferno_maw_*` | 分件 | 768×768 | `vid_boss_intro_inferno_maw.mp4` |
| `boss_frost_warden_*` | 分件 | 768×768 | `vid_boss_intro_frost_warden.mp4` |
| `boss_storm_caller_*` | 分件 | 768×768 | `vid_boss_intro_storm_caller.mp4` |
| `boss_plague_mother_*` | 分件 | 896×896 | `vid_boss_intro_plague_mother.mp4` |
| `boss_void_phantom_*` | 分件 | 768×768 | `vid_boss_intro_void_phantom.mp4` |
| `boss_necrotitan_*` | 分件 | 896×896 | `vid_boss_intro_necrotitan.mp4` |
| `boss_apex_overlord_*` | 分件 | 1024×1024 | `vid_boss_intro_apex_overlord.mp4` |

## 4. 武器/装备图标 — `weapon_/armor_/chip_/pet_*`

| 类别 | 文件 | 类型 | 尺寸 |
|---|---|---|---|
| 主炮（8） | `weapon_{id}_icon.png` + `weapon_{id}_turret.png`（战斗中底部炮塔图，分件） | 图标+分件 | 图标512 / 炮塔320 |
| 护甲（6） | `armor_{id}_icon.png` | 图标 | 512×512 |
| 芯片（8） | `chip_{id}_icon.png` | 图标 | 512×512 |
| 宝宝（6） | `pet_{id}_*`（分件 + portrait + icon） | 分件 | 192×192 |

> 炮塔 `weapon_*_turret` 是玩家长期注视对象，做分件以便后坐/开火动效。

## 5. 子弹/投射物 — `proj_*`

| 文件 | 用途 |
|---|---|
| `proj_bullet_physical.png` | 物理弹 |
| `proj_bullet_fire.png` / `_ice` / `_lightning` / `_poison` | 元素弹 |
| `proj_heavy_charge.png` | 蓄能/磁轨重弹 |
| `proj_acid_spit.png` | 喷吐者酸液 |
| `proj_split_mini.png` | 分裂小弹 |

类型整图/小序列帧，64~128px，配色严格按元素色（见 `11`）。

## 6. 特效 VFX — `vfx_*`（序列帧或粒子贴图）

| 文件前缀 | 帧 | 用途 |
|---|---|---|
| `vfx_hit_{element}_01..08` | 8 | 各元素命中 |
| `vfx_crit_01..08` | 8 | 暴击命中 |
| `vfx_explosion_fire_01..16` | 16 | 火爆/自爆者 |
| `vfx_freeze_01..12` | 12 | 冻结 |
| `vfx_chain_lightning_01..10` | 10 | 连锁电弧 |
| `vfx_poison_cloud_01..12` | 12 | 毒云/毒池 |
| `vfx_levelup_glow_01..12` | 12 | 三选一/升级光效 |
| `vfx_death_dissolve_01..10` | 10 | 僵尸死亡溶解 |
| `vfx_boss_phase_01..12` | 12 | Boss 相位/登场 |
| `vfx_muzzle_{element}_01..06` | 6 | 炮口火光（各元素） |
| `vfx_target_lock_01..08` | 8 | 手动锁定准星圈 |
| `vfx_threat_warning_01..08` | 8 | 高威胁敌人短提示 |
| `vfx_hit_immune_01..08` | 8 | 免疫/无效命中反馈 |

帧尺寸统一（命中类 128×128，爆炸/Boss 类 256×256+）。

## 7. 背景 — `bg_*`

| 文件 | 用途 |
|---|---|
| `bg_city_ruins.png`(+ `_far/_mid/_near` 可选分层) | 第一章战斗背景 |
| `bg_subway.png` | 第二章 |
| `bg_military.png` | 第三章 |
| `bg_biolab.png` | 第四章 |
| `bg_main_menu.png` | 主菜单 |
| `bg_level_map.png` | 关卡之路（可竖向长图/分段） |

整图 1080×1920（分层做视差为可选增强）。

## 8. UI — `ui_*` `icon_*`

| 类别 | 文件（示例） |
|---|---|
| 按钮 | `ui_button_primary.png`、`ui_button_secondary.png`（九宫格） |
| 面板 | `ui_panel.png`、`ui_card_frame.png`（技能卡框）、`ui_card_frame_{element}.png` |
| 血条/进度 | `ui_base_hp_bar.png`、`ui_wave_progress.png`、`ui_run_xp_bar.png`、`ui_shield_bar.png` |
| 技能槽 | `ui_skill_slot.png`、`ui_skill_slot_active.png`、`ui_cd_overlay.png` |
| 目标策略 | `ui_target_strategy_nearest.png`、`ui_target_strategy_breach.png`、`ui_target_strategy_elite.png`、`ui_target_strategy_low_hp.png`、`ui_target_lock.png` |
| 卡牌控制 | `ui_card_reroll.png`、`ui_card_pin.png`、`ui_card_skip.png`、`ui_card_tag_{tag}.png` |
| 星级 | `ui_star_filled.png`、`ui_star_empty.png` |
| 货币图标 | `icon_currency_gold.png`、`icon_currency_xp.png`、`icon_currency_star.png`、`icon_talent_point.png` |
| 局内资源 | `icon_reroll_charge.png` |
| 元素图标 | `icon_element_physical/fire/ice/lightning/poison.png` |
| 系统图标 | `icon_pause.png`、`icon_settings.png`、`icon_lock.png`、`icon_warning.png`（建议等级不足） |
| 字体 | `font_main.ttf`（含完整中文 + 等宽数字） |

## 9. 视频 — `vid_*`

| 文件 | 用途 |
|---|---|
| `vid_intro_opening.mp4` | 开场 CG（末日背景交代） |
| `vid_chapter_{env}.mp4`（×4） | 章节过场（可选） |
| `vid_boss_intro_{boss}.mp4`（×8） | 8 个 Boss 登场 |
| `vid_ending.mp4` | 通关结局（可选） |

竖屏 1080×1920，3~8s。

## 10. 数量汇总（出图工作量估算）

| 类别 | 大致文件数 |
|---|---|
| 角色（含分件/图标/专属技图标） | ≈52 |
| 普通僵尸（分件+icon） | ≈220 |
| Boss（分件+icon+视频） | ≈110 + 8 视频 |
| 武器/护甲/芯片/宝宝 | ≈70 |
| 子弹/投射物 | ≈10 |
| VFX 序列帧 | ≈130 |
| 背景 | ≈10 |
| UI/图标/字体 | ≈60 |
| 目标/卡牌新增 UI+VFX | ≈35 |
| 视频（含开场/章节/结局） | ≈15 |
| **合计（视觉）** | **≈735+** |
| 音频（BGM+SFX，见 12） | ≈65 |

> 这是全量 v1 目标。**M1 原型阶段只需先做 1 角色 + 5 僵尸 + 1 Boss + 基础 UI/VFX 的占位/首版**（见 `14`）。
