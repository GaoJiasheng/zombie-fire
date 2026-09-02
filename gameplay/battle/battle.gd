extends Node2D

const ENEMY_SCENE := preload("res://gameplay/enemy/enemy.tscn")
const TURRET_SCENE := preload("res://gameplay/turret/turret.tscn")
const PROJECTILE_SCENE := preload("res://gameplay/projectile/projectile.tscn")
const CharacterSkillText := preload("res://core/data/character_skill_text.gd")
const SkillEffectText := preload("res://core/data/skill_effect_text.gd")
const ChallengeRules := preload("res://core/data/challenge_rules.gd")
const FireRateProfiles := preload("res://core/combat/fire_rate_profiles.gd")
const SequenceVfx := preload("res://gameplay/vfx/sequence_vfx.gd")
const VfxLib := preload("res://gameplay/vfx/vfx_lib.gd")
const SLOW_FIELD_SHADER := preload("res://gameplay/vfx/shaders/vfx_slow_field.gdshader")
const SLOW_FIELD_BOUNDARY_LEVEL_SHADER := preload("res://gameplay/vfx/shaders/vfx_slow_field_boundary_level.gdshader")
const UiKit := preload("res://ui/ui_kit.gd")
const SCREEN_FLASH_TEXTURE := preload("res://assets/production/sprites/ui/ui_panel_skin.png")
const SLOW_FIELD_SURFACE_TEXTURE := preload("res://assets/production/sprites/vfx/vfx_slow_field_surface_v3.png")
const SLOW_FIELD_BOUNDARY_TEXTURE := preload("res://assets/production/sprites/vfx/vfx_slow_field_boundary_v3.png")
const SLOW_FIELD_SNOW_TEXTURE := preload("res://assets/production/sprites/vfx/vfx_hit_ice.png")
const BARRIER_GLASS_TEXTURE := preload("res://assets/production/sprites/vfx/vfx_barrier_glass.png")
const BARRIER_VISUAL_Z := 7
const DEFENSE_ACTOR_Z := 10
const CHARACTER_BACK_EFFECT_Z := -2
const BUTTON_PRIMARY_PATH := "res://assets/production/sprites/ui/ui_button_primary.png"
const BUTTON_SECONDARY_PATH := "res://assets/production/sprites/ui/ui_button_secondary.png"
const PAUSE_ACTION_BUTTON_SIZE := Vector2(276.0, 154.0)
# The deepest premium-theme corners reach farther into a compact three-column
# action than the default skin. Keep both the larger icon and the short verb in
# one horizontal row, inside a shared inset that is safe for all five themes.
const PAUSE_ACTION_ICON_RECT := Rect2(32.0, 39.0, 72.0, 76.0)
const PAUSE_ACTION_TITLE_RECT := Rect2(106.0, 38.0, 138.0, 78.0)
const PAUSE_ACTION_FRAME_SAFE_RECT := Rect2(32.0, 30.0, 212.0, 94.0)
const PAUSE_CONTENT_ORIGIN := Vector2(44.0, 124.0)
const PAUSE_CONTENT_WIDTH := 884.0
const PAUSE_CONTENT_SECTION_GAP := 16.0
const PAUSE_STATUS_CARD_HEIGHT := 214.0
const PAUSE_LOADOUT_CARD_HEIGHT := 288.0
const PAUSE_SKILL_CHIP_HEIGHT := 78.0
const PAUSE_SKILL_ROW_GAP := 8.0
const PAUSE_SKILL_CARD_CHROME := 92.0
const PAUSE_ACTION_CONTENT_GAP := 32.0
const PAUSE_PANEL_BOTTOM_PADDING := 42.0
const BREACH_Y_DESIGN := 1500.0
const CHARACTER_BASE_Y_DESIGN := 1652.0
const PET_BASE_X_DESIGN := 800.0
const PET_BASE_LINE_OFFSET := 125.0
const PET_IDLE_FLOAT_AMPLITUDE := 8.0
const BASE_LINE_DEFAULT_SLOW_FIELD_INSET := 340.0
const SLOW_FIELD_BOUNDARY_SIZE := Vector2(1080.0, 240.0)
const SLOW_FIELD_BOUNDARY_ANCHOR_Y := 96.0
const SLOW_FIELD_BOUNDARY_SLOPE_COMPENSATION_PX := 18.0
const SLOW_FIELD_BOUNDARY_SEAM_OPACITY := 0.34
const SLOW_FIELD_SNOW_MIN_AMOUNT := 56
const SLOW_FIELD_SNOW_MAX_AMOUNT := 124
const BASE_LINE_NEAR_WARNING_INSET := 300.0
const BASE_LINE_BOSS_NEAR_WARNING_INSET := 360.0
const BASE_LINE_WARNING_INSET := 190.0
const BASE_LINE_BOSS_WARNING_INSET := 240.0
# 比 1080x1920 设计画布更高宽比的设备(如 iPhone 16 Pro Max)上，expand 拉伸会
# 多出一截视口高度。以前的做法是让人物/护栏底座这个"下方基座群组"固定钉在设计
# 高度 1920 内，多出来的高度晾在下面垫色块——能看，但人物没有真正用到下面多出
# 的那截屏幕，观感"没用满全屏"。现在把这一整个基座群组(人物、护栏/breach 线、
# 底部 HUD 条)统一按 bottom_dock_shift 整体下移，钉到真实屏幕底部；战斗背景使用
# 1080x2622 的高屏画布，运行时只做底边锚定，避免顶部再出现黑色补条。
var bottom_dock_shift := 0.0
var BREACH_Y := 1500.0
var CHARACTER_BASE_POSITION := Vector2(540, 1652)
## 正式版战斗加速按最高已解锁关卡开放：30关显示并开放2X，50关开放5X。
## TestFlight 内测 feature 会从第1关常显按钮并开放 1X / 2X / 5X；
## 正式提审前只需停止注入该 feature，不改存档，也不改正式成长规则。
## 只在战斗场景生效，离开战斗时 main.gd 会把 Engine.time_scale 复位成 1.0。
var battle_speed := 1.0
var battle_speed_progress_level := 1
const CHARACTER_VISUAL_BASE_SCALE := 0.512
# Owner 2026-08-13: after making the static and firing models share one
# character/profile scale, reduce the complete battlefield actor to 80% of the
# previously approved 1.50x presentation (1.50 * 0.80 = 1.20).
const CHARACTER_PRESENTATION_SCALE := 1.20
const CHARACTER_VFX_PRESENTATION_SCALE := 1.25
const CHARACTER_BODY_TARGET_HEIGHT_FALLBACK := 420.0
const CHARACTER_BODY_TARGET_FOOT_OFFSET_FALLBACK := 100.0
const CHARACTER_WEAPON_SOCKET := Vector2(58, -28)
const CHARACTER_WEAPON_DEFAULT_DIRECTION := Vector2(0, -1)
const CHARACTER_WEAPON_MUZZLE_DISTANCE := {
	"weapon_autocannon": 68.0,
	"weapon_cryocannon": 68.0,
	"weapon_flamethrower": 70.0,
	"weapon_plasmacannon": 74.0,
	"weapon_railgun": 78.0,
	"weapon_scattergun": 66.0,
	"weapon_teslacoil": 74.0,
	"weapon_venomlauncher": 70.0,
}
const CHARACTER_WEAPON_COMBO_MUZZLE := {
	"char_vanguard/weapon_autocannon": Vector2(32.2, -130.1),
	"char_vanguard/weapon_flamethrower": Vector2(34.3, -129.8),
	"char_vanguard/weapon_cryocannon": Vector2(29.2, -127.8),
	"char_vanguard/weapon_teslacoil": Vector2(33.3, -129.8),
	"char_vanguard/weapon_venomlauncher": Vector2(25.1, -128.2),
	"char_vanguard/weapon_railgun": Vector2(29.7, -130.1),
	"char_vanguard/weapon_scattergun": Vector2(25.8, -128.6),
	"char_vanguard/weapon_plasmacannon": Vector2(26.4, -127.7),
	"char_blaze/weapon_autocannon": Vector2(26.1, -129.5),
	"char_blaze/weapon_flamethrower": Vector2(45.0, -130.1),
	"char_blaze/weapon_cryocannon": Vector2(29.2, -130.1),
	"char_blaze/weapon_teslacoil": Vector2(32.2, -129.8),
	"char_blaze/weapon_venomlauncher": Vector2(30.2, -130.1),
	"char_blaze/weapon_railgun": Vector2(24.8, -128.5),
	"char_blaze/weapon_scattergun": Vector2(30.6, -128.7),
	"char_blaze/weapon_plasmacannon": Vector2(20.9, -127.8),
	"char_frost/weapon_autocannon": Vector2(17.9, -128.4),
	"char_frost/weapon_flamethrower": Vector2(27.1, -125.3),
	"char_frost/weapon_cryocannon": Vector2(18.9, -127.1),
	"char_frost/weapon_teslacoil": Vector2(18.8, -128.7),
	"char_frost/weapon_venomlauncher": Vector2(18.4, -128.2),
	"char_frost/weapon_railgun": Vector2(23.9, -128.7),
	"char_frost/weapon_scattergun": Vector2(17.7, -128.0),
	"char_frost/weapon_plasmacannon": Vector2(20.0, -123.1),
	"char_volt/weapon_autocannon": Vector2(26.1, -129.5),
	"char_volt/weapon_flamethrower": Vector2(24.8, -129.5),
	"char_volt/weapon_cryocannon": Vector2(29.2, -128.7),
	"char_volt/weapon_teslacoil": Vector2(22.6, -128.5),
	"char_volt/weapon_venomlauncher": Vector2(25.6, -128.5),
	"char_volt/weapon_railgun": Vector2(24.6, -129.5),
	"char_volt/weapon_scattergun": Vector2(27.3, -128.0),
	"char_volt/weapon_plasmacannon": Vector2(25.1, -124.2),
}
const CHARACTER_WEAPON_COMBO_MUZZLE_LEFT := {
	"char_vanguard/weapon_autocannon": Vector2(-69.0, -121.5),
	"char_vanguard/weapon_flamethrower": Vector2(-70.2, -118.2),
	"char_vanguard/weapon_cryocannon": Vector2(-63.8, -116.8),
	"char_vanguard/weapon_teslacoil": Vector2(-69.1, -119.3),
	"char_vanguard/weapon_venomlauncher": Vector2(-60.6, -117.5),
	"char_vanguard/weapon_railgun": Vector2(-65.5, -119.8),
	"char_vanguard/weapon_scattergun": Vector2(-60.7, -118.1),
	"char_vanguard/weapon_plasmacannon": Vector2(-60.4, -117.0),
	"char_blaze/weapon_autocannon": Vector2(-61.7, -119.5),
	"char_blaze/weapon_flamethrower": Vector2(-80.6, -120.2),
	"char_blaze/weapon_cryocannon": Vector2(-65.0, -119.8),
	"char_blaze/weapon_teslacoil": Vector2(-68.1, -119.8),
	"char_blaze/weapon_venomlauncher": Vector2(-67.0, -119.8),
	"char_blaze/weapon_railgun": Vector2(-59.9, -120.0),
	"char_blaze/weapon_scattergun": Vector2(-65.6, -118.2),
	"char_blaze/weapon_plasmacannon": Vector2(-55.8, -117.5),
	"char_frost/weapon_autocannon": Vector2(-54.6, -119.5),
	"char_frost/weapon_flamethrower": Vector2(-61.0, -113.0),
	"char_frost/weapon_cryocannon": Vector2(-53.8, -117.0),
	"char_frost/weapon_teslacoil": Vector2(-54.0, -119.0),
	"char_frost/weapon_venomlauncher": Vector2(-54.2, -118.2),
	"char_frost/weapon_railgun": Vector2(-59.4, -117.5),
	"char_frost/weapon_scattergun": Vector2(-52.3, -118.2),
	"char_frost/weapon_plasmacannon": Vector2(-52.1, -114.0),
	"char_volt/weapon_autocannon": Vector2(-61.9, -119.8),
	"char_volt/weapon_flamethrower": Vector2(-60.4, -119.3),
	"char_volt/weapon_cryocannon": Vector2(-65.0, -118.5),
	"char_volt/weapon_teslacoil": Vector2(-57.2, -119.0),
	"char_volt/weapon_venomlauncher": Vector2(-61.0, -119.8),
	"char_volt/weapon_railgun": Vector2(-60.4, -119.8),
	"char_volt/weapon_scattergun": Vector2(-62.2, -118.1),
	"char_volt/weapon_plasmacannon": Vector2(-53.8, -115.4),
}
const CHARACTER_WEAPON_COMBO_MUZZLE_RIGHT := {
	"char_vanguard/weapon_autocannon": Vector2(64.8, -123.5),
	"char_vanguard/weapon_flamethrower": Vector2(66.1, -120.3),
	"char_vanguard/weapon_cryocannon": Vector2(60.2, -118.6),
	"char_vanguard/weapon_teslacoil": Vector2(65.0, -121.4),
	"char_vanguard/weapon_venomlauncher": Vector2(55.8, -119.6),
	"char_vanguard/weapon_railgun": Vector2(61.4, -121.4),
	"char_vanguard/weapon_scattergun": Vector2(56.1, -120.6),
	"char_vanguard/weapon_plasmacannon": Vector2(57.1, -118.6),
	"char_blaze/weapon_autocannon": Vector2(58.1, -121.1),
	"char_blaze/weapon_flamethrower": Vector2(76.8, -122.6),
	"char_blaze/weapon_cryocannon": Vector2(61.0, -121.8),
	"char_blaze/weapon_teslacoil": Vector2(64.0, -121.8),
	"char_blaze/weapon_venomlauncher": Vector2(63.0, -121.8),
	"char_blaze/weapon_railgun": Vector2(56.1, -121.6),
	"char_blaze/weapon_scattergun": Vector2(62.2, -119.8),
	"char_blaze/weapon_plasmacannon": Vector2(51.7, -119.0),
	"char_frost/weapon_autocannon": Vector2(50.4, -121.1),
	"char_frost/weapon_flamethrower": Vector2(57.2, -114.5),
	"char_frost/weapon_cryocannon": Vector2(49.9, -118.6),
	"char_frost/weapon_teslacoil": Vector2(49.9, -120.6),
	"char_frost/weapon_venomlauncher": Vector2(49.7, -120.0),
	"char_frost/weapon_railgun": Vector2(55.0, -119.8),
	"char_frost/weapon_scattergun": Vector2(48.9, -119.5),
	"char_frost/weapon_plasmacannon": Vector2(48.2, -115.4),
	"char_volt/weapon_autocannon": Vector2(57.8, -121.8),
	"char_volt/weapon_flamethrower": Vector2(56.3, -121.4),
	"char_volt/weapon_cryocannon": Vector2(60.6, -120.3),
	"char_volt/weapon_teslacoil": Vector2(53.8, -120.8),
	"char_volt/weapon_venomlauncher": Vector2(56.8, -121.4),
	"char_volt/weapon_railgun": Vector2(56.3, -121.8),
	"char_volt/weapon_scattergun": Vector2(58.2, -119.8),
	"char_volt/weapon_plasmacannon": Vector2(54.8, -114.0),
}
const WEAPON_VISUAL_PROFILES := {
	"weapon_autocannon": "autocannon",
	"weapon_flamethrower": "flame",
	"weapon_railgun": "rail",
	"weapon_scattergun": "scatter",
	"weapon_plasmacannon": "plasma",
}
const ELEMENTAL_AMMO_VISUAL_PROFILE_PREFIX := "ammo_"
const CHARACTER_WEAPON_SCALE := {
	"weapon_autocannon": 0.56,
	"weapon_cryocannon": 0.57,
	"weapon_flamethrower": 0.57,
	"weapon_plasmacannon": 0.58,
	"weapon_railgun": 0.60,
	"weapon_scattergun": 0.56,
	"weapon_teslacoil": 0.58,
	"weapon_venomlauncher": 0.57,
}
const CHARACTER_WEAPON_ACTION_FRAME_COUNT := 8
const CHARACTER_WEAPON_FIRE_FRAME_INDEX := 1
const CHARACTER_WEAPON_ATTACK_DURATION := {
	"weapon_autocannon": 0.28,
	"weapon_cryocannon": 0.34,
	"weapon_flamethrower": 0.32,
	"weapon_plasmacannon": 0.38,
	"weapon_railgun": 0.40,
	"weapon_scattergun": 0.38,
	"weapon_teslacoil": 0.28,
	"weapon_venomlauncher": 0.36,
}
const CHARACTER_WEAPON_PREFIRE_LEAD := {
	"weapon_autocannon": 0.060,
	"weapon_cryocannon": 0.080,
	"weapon_flamethrower": 0.075,
	"weapon_plasmacannon": 0.100,
	"weapon_railgun": 0.110,
	"weapon_scattergun": 0.100,
	"weapon_teslacoil": 0.060,
	"weapon_venomlauncher": 0.090,
}
const CHARACTER_WEAPON_ACTION_RECOIL_CURVE := [-0.34, 0.0, 1.0, 0.58, -0.18, 0.20, -0.06, 0.0]
const CHARACTER_WEAPON_RECOIL_POSE := {
	"weapon_autocannon": 13.0,
	"weapon_cryocannon": 15.0,
	"weapon_flamethrower": 12.0,
	"weapon_plasmacannon": 18.0,
	"weapon_railgun": 21.0,
	"weapon_scattergun": 24.0,
	"weapon_teslacoil": 13.0,
	"weapon_venomlauncher": 16.0,
}
const SKILL_ORDER := ["skill_split_shot", "skill_pierce", "skill_multishot", "skill_slow_field", "skill_homing", "skill_critical", "skill_barrier", "skill_gold_rush", "skill_ricochet", "skill_salvo", "skill_incendiary", "skill_cryo", "skill_tesla", "skill_venom", "skill_charge_shot", "skill_recycle"]
const SKILL_SLOT_LIMIT := 8
const HUD_HP_BAR_PATH := "Hud/BottomBar/BaseHpBar"
const HUD_WAVE_BAR_PATH := "Hud/TopBar/WaveProgress"
const HUD_HP_FILL_RIGHT := 812.0
const HUD_WAVE_FILL_TEXTURE := "res://assets/production/sprites/ui/ui_wave_progress_fill_native.png"
const HUD_WAVE_FILL_LEFT := 40.0
const HUD_WAVE_FILL_RIGHT := 680.0
const HUD_WAVE_BAR_SIZE := Vector2(720, 46)
const HUD_XP_FILL_RIGHT := 778.0
const BOSS_HP_HUD_POSITION := Vector2(160, 130)
const BOSS_HP_HUD_SIZE := Vector2(760, 124)
const BOSS_HP_LABEL_SIZE := Vector2(760, 56)
const BOSS_HP_LABEL_FONT_SIZE := 24
const BOSS_HP_HUD_TOP_GAP := 22.0
const BOSS_HP_TRACK_POSITION := Vector2(0, 66)
const BOSS_HP_TRACK_SIZE := Vector2(760, 22)
const BOSS_HP_FILL_POSITION := Vector2(2, 68)
const BOSS_HP_FILL_SIZE := Vector2(756, 18)
const BOSS_HP_STACKED_TRACK_POSITION := Vector2(0, 94)
const BOSS_HP_STACKED_FILL_POSITION := Vector2(2, 96)
const BOSS_HP_LABEL_TRACK_GAP := 10.0
const BOTTOM_RESOURCE_ROW_DROP := 20.0
const COMBAT_LABEL_FULL_DENSITY_MAX := 8
const COMBAT_LABEL_MEDIUM_DENSITY_MAX := 16
const COMBAT_LABEL_MEDIUM_CAP := 7
const COMBAT_LABEL_HIGH_CAP := 5
const COMBAT_LABEL_REFRESH_SECONDS := 0.16
const ENABLE_DEBUG_OVERLAY := false
const MAX_PROJECTILE_TRANSIENT_FX := 150
const MAX_PROJECTILE_PRIORITY_FX := 185
const MAX_HUD_TRANSIENT_FX := 52
const MAX_HUD_PRIORITY_FX := 68
const MAX_FLOAT_TEXTS := 8
const MAX_PRIORITY_FLOAT_TEXTS := 12
# Directional bitmap contract: every authored texture below has a visible
# "forward" direction in its source pixels. Runtime must rotate that source
# forward vector onto the actual gameplay travel vector; otherwise a pretty
# static frame can contradict the movement it is meant to explain.
const DIRECTIONAL_VFX_SOURCE_FORWARD := {
	"vfx_enemy_skill_runner_dash": 0.0,
	"vfx_enemy_skill_charge": 0.0,
	"vfx_enemy_skill_leap_strike": 0.7853981633974483,
	"vfx_enemy_skill_phase_shift": 0.0,
	"vfx_enemy_skill_ranged_spit": 0.0,
	# The source phoenix flies upper-right (-45 degrees). Keep this explicit so
	# its head, wing sweep and molten trail always agree with the live path.
	"vfx_apocalypse_inferno_phoenix": -0.7853981633974483,
	"vfx_apocalypse_absolute_zero_wave": -0.7853981633974483,
}
# 多重射击每条弹道之间的固定夹角(度)。固定=不 imba；扇形中心对准敌群。
const MULTISHOT_LANE_DEG := 7.0
const MAX_MULTISHOT_LANES := 5
# 散弹的运行时弹速较低；沿用普通弹丸 1 秒导引延迟时，外侧弹丸常在导引启动前已经
# 命中或飞出侧边。保留约 0.3 秒原始扇形，再进入同样受 460px 转弯半径约束的追踪。
const SCATTER_HOMING_ACTIVATION_DELAY := 0.35
# Directional character art must not choose its next pose from the muzzle of
# its current pose. At point-blank range that creates a feedback loop: the
# left-pose muzzle crosses the target centre and requests right, then the
# right-pose muzzle crosses back and requests left. Use a pose-independent
# body reference plus separate enter/exit thresholds instead.
const CHARACTER_COMBO_SIDE_AIM_ENTER_X := 0.22
const CHARACTER_COMBO_SIDE_AIM_EXIT_X := 0.12
# 基地单次受伤上限 = 最大血量的比例。防止 Boss/技能"一下打死"，任何来源都受此限制。
const MAX_BASE_HIT_FRACTION := 0.4
# 第3/4/5波单独加血量(绝不加速度)：局内前两波保持开局节奏，后半段用血量拉回张力。
# 运行时优先读取 economy.json，同步给校验/模拟工具；这里是缺省兜底。
const DEFAULT_LATE_WAVE_HP_BONUS := {3: 1.45, 4: 1.85, 5: 2.30}
const DEFAULT_LATE_WAVE_COUNT_MULT := {4: 2.0, 5: 3.0}
const DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP := {"start_level": 55, "full_level": 90, "start_wave": 3, "max_mult": 1.25, "curve_power": 1.0, "final_level": 99, "final_mult": 1.08}
const DEFAULT_LATE_WAVE_BOSS_HP_BONUS := {3: 1.30, 4: 1.50, 5: 1.75}
const DEFAULT_LATE_WAVE_LEVEL_RAMP := {"start_level": 50, "full_level": 98, "max_mult": 2.05, "curve_power": 1.0, "final_level": 99, "final_mult": 1.12}
const DEFAULT_LATE_WAVE_DAMAGE_RAMP := {"start_level": 50, "full_level": 98, "start_wave": 3, "max_mult": 1.0, "curve_power": 1.0, "final_level": 99, "final_mult": 1.0}
const DEFAULT_BOSS_HP_LEVEL_BONUS := {"start_level": 20, "multiplier": 2.0}
const DEFAULT_BOSS_SURVIVAL_HP_RAMP := {"start_level": 50, "full_level": 98, "max_mult": 56.0, "curve_power": 1.15, "final_level": 99, "final_mult": 1.08}
const WAVE_TOAST_BASE_POSITION := Vector2(290, 96)
const WAVE_TOAST_SIZE := Vector2(500, 54)
const WAVE_TOAST_LONG_SIZE := Vector2(600, 164)
const WAVE_TOAST_MIN_INTERVAL := 2.50
const ACTIVE_SKILL_DOT_COUNT := 8
const SKILL_HINT_AUTO_HIDE_SECONDS := 3.0
const HUD_SKILL_DOCK_LEFT := 18.0
const HUD_SKILL_DOCK_RIGHT := 426.0
const HUD_SKILL_DOCK_BOTTOM := 1808.0
const HUD_SKILL_SLOT_SIZE := Vector2(96.0, 120.0)
const HUD_SKILL_DOCK_COLUMNS := 4
const HUD_SKILL_DOCK_GAP := 8
const FROST_GLACIER_MIN_DURATION := 5.0
const FROST_GLACIER_TICK_INTERVAL := 0.52
const FROST_GLACIER_STATUS_REFRESH := 0.86
const FROST_GLACIER_NORMAL_SPEED := 0.40
const FROST_GLACIER_BOSS_SPEED := 0.62
const PREFINAL_CARD_OFFER_XP_RATIO := 0.85
const CARD_OFFER_PANEL_X := 54.0
const CARD_OFFER_CENTER_TOP_Y := 100.0
const CARD_OFFER_PANEL_SIZE := Vector2(972.0, 1154.0)
const CARD_OFFER_CARDS_POS := Vector2(54.0, 108.0)
const CARD_OFFER_CARDS_SIZE := Vector2(864.0, 842.0)
const CARD_OFFER_BUTTON_SIZE := Vector2(412.0, 88.0)
const CARD_OFFER_ACTION_GAP := 50.0
const CARD_OFFER_ACTION_LANE_HEIGHT := 124.0
const CARD_OFFER_CARD_WIDTH := 864.0
const CARD_OFFER_CARD_BASE_HEIGHT := 270.0
const CARD_OFFER_ICON_FRAME_POS := Vector2(32.0, 48.0)
const CARD_OFFER_ICON_FRAME_SIZE := Vector2(196.0, 196.0)
const CARD_OFFER_ICON_POS := Vector2(41.0, 57.0)
const CARD_OFFER_ICON_SIZE := Vector2(178.0, 178.0)
const CARD_OFFER_TEXT_X := 252.0
const CARD_OFFER_TEXT_WIDTH := 584.0
const CARD_OFFER_COPY_TOP_Y := 82.0
const CARD_OFFER_COPY_GAP := 8.0
const CARD_OFFER_CARD_SEPARATION := 10
const CARD_OFFER_TAG_MIN_HEIGHT := 48.0
const CARD_OFFER_BOTTOM_PADDING := 28.0
const CARD_DETAIL_LEVELS_BODY_FONT_SIZE := 15
const CARD_DETAIL_DESCRIPTION_FONT_SIZE := 17
const CARD_DETAIL_TAGS_FONT_SIZE := 15
const MANUAL_AIM_RELEASE_GRACE := 0.18
const CHALLENGE_HP_MULT := 1.5
const CHALLENGE_RECOMMENDED_POWER_MULT := 1.5
# Normal enemies use wider authored corridors than the old 160–210px bands.
# The lane identity remains readable, but a group no longer enters as one stack.
const SPAWN_LANE_X_BOUNDS := {
	"left": Vector2(150.0, 430.0),
	"center": Vector2(300.0, 780.0),
	"right": Vector2(650.0, 930.0),
	"spread": Vector2(150.0, 930.0),
}
# Boss staging stays deliberately tighter so its entrance, banner and support
# composition keep the authored focal point.
const BOSS_SPAWN_LANE_X_BOUNDS := {
	"left": Vector2(180.0, 390.0),
	"center": Vector2(460.0, 620.0),
	"right": Vector2(690.0, 900.0),
	"spread": Vector2(150.0, 930.0),
}
const NORMAL_SPAWN_Y_BOUNDS := Vector2(158.0, 222.0)
const SPAWN_CANDIDATE_COUNT := 9
const SPAWN_RECENT_HISTORY := 6
const SPAWN_ENTRY_BLOCKER_MAX_Y := 330.0

var router: Node
var level := {}
var level_id := "level_001"
var base_hp := 100
var base_hp_max := 100
var gold := 0
var xp := 0
var variant := "normal"
var variant_gold_mult := 1.0
var variant_xp_mult := 1.0
# 无限尸潮：使用 economy.endless_template_level 作为独立模板，不继承入口关卡难度；
# 小怪按 economy.endless_hp_growth_stages 分段复利，Boss 则使用独立轮次总预算。
var is_endless_mode := false
var is_challenge_mode := false
var challenge_rule: Dictionary = {}
var endless_loop := 0
var endless_difficulty_mult := 1.0
var endless_template_level_id := ""
var endless_gold_milestones_claimed := {}
const ENDLESS_LOOP_HP_GROWTH := 0.50
const ENDLESS_BOSS_COUNT_STEP := 4
const ENDLESS_BOSS_COUNT_CAP := 6
var level_ordinal := 1
## 阶段 67：关卡的 `wave_pattern` 编队原型，决定敌人从哪条通道进攻。
var wave_formation := "standard"
var econ_gold_base := 5.0
var econ_gold_per := 0.6
## Wave-clear fast-forward (`data/economy.json` -> `wave_clear_fast_forward`).
## Default is disabled; when off none of the three fields below are read by
## any gameplay path, so closed-switch behavior is byte-identical to before
## this feature existed. See `_load_wave_clear_fast_forward_config`.
var wave_clear_fast_forward_enabled := false
var wave_clear_fast_forward_breather := 3.0
## Gameplay-clock timestamp (see `_gameplay_now_seconds`) of the most recent
## moment the battlefield held zero live enemies, or -1.0 if it currently
## holds at least one (or hasn't gone empty since the last spawn). Reset to
## -1.0 whenever a new enemy joins `$EnemyLayer` so a stale timestamp from an
## earlier lull can never leak into a later, still-populated moment.
var _wave_clear_fast_forward_clear_at := -1.0
var pending_spawns: Array = []
var boss_spawn_counts: Dictionary = {}
var recent_spawn_positions: Array[Vector2] = []
## Headless audit probes can isolate combat randomness from presentation-only
## randomness. Runtime leaves this null and keeps the legacy global RNG path.
var _audit_combat_rng: RandomNumberGenerator
var _audit_enemy_spawn_sequence := 0
var _audit_projectile_spawn_sequence := 0
var _audit_delayed_skill_callbacks: Array[Dictionary] = []
var spawn_timer := 0.0
var wave_index := 0
var wave_total := 0
var active_spawning := false
var turret: Node2D
var target_manager: TargetingManager
var combat_label_refresh_left := 0.0
var card_director := CardDirector.new()
var skills := SkillRuntime.new()
var next_xp_offer := 12
var card_offer_active := false
var reroll_charges := 1
var cards_picked := 0
var cards_selected := 0
var level_total_run_xp := 0
var level_raw_run_xp_total := 0
var level_run_xp_budget := 0
var level_run_xp_raw_earned := 0.0
var level_run_xp_budget_awarded := 0
var target_card_picks := 3
var paused := false
var manual_aim_active := false
var manual_aim_point := Vector2(540, 600)
var manual_aim_until := 0.0
var battle_finished := false
var pre_final_offer_used := false
var debug_overlay_on := false
var slow_field_rect: TextureRect
var slow_field_boundary: TextureRect
var slow_field_particles: GPUParticles2D
var slow_field_sfx_level := 0
var card_press_skill_id := ""
var card_press_started_at := 0.0
var card_long_press_opened := false
var skill_hint_press_kind := ""
var skill_hint_press_skill_id := ""
var skill_hint_press_started_at := 0.0
var skill_hint_long_press_opened := false
var skill_hint_auto_hide_at := 0.0
var suppress_next_character_skill_press := false
var weapon_id := "weapon_autocannon"
var character_id := "vanguard"
var armor_id := "armor_kevlar"
var chip_id := "chip_attack"
var pet_id := ""
var character_data: Dictionary = {}
var armor_data: Dictionary = {}
var chip_data: Dictionary = {}
var pet_data: Dictionary = {}
var pet_sprite: Sprite2D
var character_rig: Node2D
var character_sprite: Sprite2D
var character_aura: Node2D
var character_weapon_sprite: Sprite2D
var character_weapon_glow: Sprite2D
var pet_aura: Node2D
var character_idle_frames: Array[Texture2D] = []
var character_attack_left_frames: Array[Texture2D] = []
var character_attack_frames: Array[Texture2D] = []
var character_attack_right_frames: Array[Texture2D] = []
var character_hurt_frames: Array[Texture2D] = []
var character_weapon_idle_frames: Array[Texture2D] = []
var character_weapon_recoil_frames: Array[Texture2D] = []
var character_anim_time := 0.0
var character_anim_frame := 0
var character_attack_time := 0.0
var character_hurt_time := 0.0
var character_skill_time := 0.0
var character_weapon_anim_time := 0.0
var character_weapon_anim_frame := 0
var character_weapon_recoil_time := 0.0
var character_weapon_recoil_offset := 0.0
var character_weapon_direction := CHARACTER_WEAPON_DEFAULT_DIRECTION
var character_weapon_combo_active := false
var character_weapon_combo_muzzle := CHARACTER_WEAPON_SOCKET
var character_weapon_combo_aim := "center"
var character_weapon_combo_locked_aim := ""
var character_rig_foot_lift := 0.0
var character_theme_pulse_tween: Tween
var character_theme_fire_aura: AnimatedSprite2D
var character_attack_duration := 0.30
var pet_idle_frames: Array[Texture2D] = []
var pet_attack_frames: Array[Texture2D] = []
var pet_anim_time := 0.0
var pet_anim_frame := 0
var pet_attack_time := 0.0
var pet_cooldown := 0.0
var pet_skill_cooldown := 0.0
var pet_skill_timer := 0.0
var pet_repair_cooldown := 0.0
var pet_emergency_cooldown := 0.0
var breach_shields := 0
var skill_barriers_left := 0
var barrier_visual: Node2D
var barrier_sprite: Sprite2D
var gold_mult := 1.0
var breach_damage_mult := 1.0
var crit_rate := 0.0
var pierce_bonus := 0
var element_damage_bonus := 1.0
var slow_strength_bonus := 1.0
var chain_bonus := 0
var apocalypse_overload_hits := 0
var apocalypse_terminal_cooldown := 0.0
var apocalypse_armor_charge := 0
var apocalypse_armor_counter_cooldown := 0.0
var inferno_high_heat_shots := 0
var inferno_awakening_cooldown := 0.0
var inferno_feedback_cooldown := 0.0
var absolute_zero_wave_cooldown := 0.0
var absolute_zero_awakening_cooldown := 0.0
var golden_law_awakening_cooldown := 0.0
var golden_law_decree_cooldown := 0.0
var absolute_zero_feedback_cooldown := 0.0
var skill_fire_rate_mult := 1.0
var fire_rate_profile_id := FireRateProfiles.DEFAULT_PROFILE_ID
var fire_rate_weapon_base := 1.0
var fire_rate_authored_weapon_base := 1.0
var fire_rate_control_rate := 1.0
var skill_slot_ids: Array[String] = []
var character_active_id := ""
var character_active_cd := 0.0
var character_active_cd_max := 16.0
var character_fire_rate_mult := 1.0
var sig_vanguard_barrage_timer := 0.0
var sig_vanguard_overload_timer := 0.0
var sig_vanguard_overload_used := false
var sig_frost_glacier_timer := 0.0
var sig_frost_glacier_tick := 0.0
var character_level := 1
var weapon_level := 1
var armor_level := 1
var chip_level := 1
var pet_level := 1
var low_hp_warned := false
var active_boss: Node = null
var boss_hp_bar: Control = null
var boss_hp_track: TextureRect = null
var boss_hp_fill: TextureRect = null
var boss_armor_track: TextureRect = null
var boss_armor_fill: TextureRect = null
var boss_hp_label: Label = null
var last_threat_warning_at := -99.0
var last_gold_sfx_at := -99.0
# design/28: 推荐战力 = 本关"恰好能通关"线(1★能过口径),loadout_power_ratio 因此
# 语义变为"相对通关线的余量":< 1.0 → 模型判"预计打不过",目标面板提示;
# ∈ [0.85, 1.0) 且前 50 关 → 早期兜底 +8% 基地血量,帮压线玩家挤过去(更低则模型
# 判定救不回来,不再假装能救)。带宽初值来自 design/28,验收探针复核后定稿。
const CLEAR_LINE_WARNING_RATIO := 1.0
const CLEAR_LINE_CUSHION_MIN_RATIO := 0.85
var primary_weakness := "physical"
var loadout_power_ratio := 1.0
var power_level_id := "level_001"
var player_power := 1
var recommended_combat_power := 1
var run_skill_hp_pressure_mult := 1.0
var run_skill_speed_pressure_mult := 1.0
var onboarding_stage := ""
var onboarding_tip_shown := false
var wave_tip_shown := {}
var kill_streak := 0
var last_kill_at := -99.0
var low_hp_pulse: Control
var screen_flash: TextureRect
var screen_flash_tween: Tween
var wave_toast_tween: Tween
var wave_toast_banner: Control
var wave_toast_panel: PanelContainer
var wave_toast_label: Label
var wave_fill_material: ShaderMaterial
var last_wave_toast_at := -99.0
var pending_wave_toast := {}
var pending_wave_toast_timer_active := false
var displayed_wave_pct := 0.0
var displayed_xp_pct := 0.0
var build_feedback_shown := {}
var weak_kill_feedback_count := 0
var weak_kill_feedback_pending := false
var last_weak_kill_feedback_at := -99.0
var battle_elapsed_seconds := 0.0
var battle_damage_total := 0.0
var battle_damage_by_source := {}
var battle_damage_by_element: Dictionary = {}
var battle_crit_damage := 0.0
var battle_weak_damage := 0.0
var battle_kills := 0
var battle_boss_kills := 0
var battle_base_damage_taken := 0
var battle_base_damage_prevented := 0
var battle_control_seconds := 0.0
var battle_active_skill_casts := 0
var battle_max_kill_streak := 0
var battle_last_boss_id := ""

# Stage 1 P0 — combat feel & feedback
var hit_stop: Node
var screen_shake_node: Node
var combo_hud: Control
var damage_numbers: Node2D
var off_screen_indicators: Node2D
var gold_fly: Node
var last_impact_feedback_at := -99.0
var _lock_indicator_base_scale := 0.3
var _lock_pulse_tween: Tween
var _last_kill_at_for_combo := -99.0

func _loc(zh: String, en: String) -> String:
	return en if LocalizationManager.is_english() else zh

func setup(main: Node, payload := {}) -> void:
	router = main
	level_id = _resolve_level_id(payload)
	is_endless_mode = bool(payload.get("endless", false))
	is_challenge_mode = bool(payload.get("challenge", false))

func set_audit_combat_seed(seed_value: int) -> void:
	_audit_combat_rng = RandomNumberGenerator.new()
	_audit_combat_rng.seed = seed_value

func _combat_randf() -> float:
	return _audit_combat_rng.randf() if _audit_combat_rng != null else randf()

func _combat_randf_range(from: float, to: float) -> float:
	return _audit_combat_rng.randf_range(from, to) if _audit_combat_rng != null else randf_range(from, to)

func _next_audit_enemy_seed() -> int:
	return int(_audit_combat_rng.randi()) if _audit_combat_rng != null else 0

func _configure_audit_projectile(projectile: Node) -> void:
	if _audit_combat_rng != null and projectile != null and projectile.has_method("set_audit_deterministic_collisions"):
		_audit_projectile_spawn_sequence += 1
		projectile.set_meta("audit_projectile_spawn_index", _audit_projectile_spawn_sequence)
		projectile.process_physics_priority = 20000 + _audit_projectile_spawn_sequence
		# Nodes created from inside a physics callback are not guaranteed to join
		# that same callback list on every run.  Arm them at the deferred boundary
		# so every audit projectile starts on the following authored tick.
		projectile.set_physics_process(false)
		projectile.call("set_audit_deterministic_collisions", true)

func _activate_audit_physics_node(node: Node) -> void:
	# Runtime probes advance combat actors explicitly from Battle's authored
	# physics tick.  Keeping their automatic callbacks disabled removes Godot's
	# tree-insertion/callback-order variance without changing production combat.
	if _audit_combat_rng != null and node != null:
		node.set_physics_process(false)
		node.set_process(false)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _audit_combat_rng != null:
		# The runtime probe observes a full physics tick only after battle state,
		# aiming, enemies and projectiles have advanced in a stable authored order.
		# Production combat keeps Godot's legacy default priorities unchanged.
		process_physics_priority = -100000
	get_tree().paused = false
	battle_speed_progress_level = _level_ordinal_from_id(SaveManager.get_highest_unlocked_level_id())
	battle_speed = SettingsManager.get_battle_speed(battle_speed_progress_level)
	Engine.time_scale = battle_speed
	# On tall iPhones, keep the top HUD fixed while docking the complete defense
	# group to the real viewport bottom. The 1080x2622 backgrounds use the same
	# bottom anchor, so the authored barricade, breach line, hero, pet and bottom
	# HUD remain one coherent composition instead of drifting apart vertically.
	var visible_size := get_viewport().get_visible_rect().size
	bottom_dock_shift = maxf(0.0, visible_size.y - 1920.0)
	BREACH_Y = BREACH_Y_DESIGN + bottom_dock_shift
	CHARACTER_BASE_POSITION = Vector2(540, CHARACTER_BASE_Y_DESIGN + bottom_dock_shift)
	# HUD controls must receive GUI input both during battle and while card
	# offers pause the tree; individual buttons decide their own enabled state.
	$Hud.process_mode = Node.PROCESS_MODE_ALWAYS
	_configure_pause_process_modes()
	level = DataLoader.get_row("levels", level_id)
	_apply_level_background()
	var _econ: Dictionary = DataLoader.get_table("economy")
	level_ordinal = _level_ordinal_from_id(level_id)
	challenge_rule = ChallengeRules.for_level(level_id, DataLoader.get_table("challenges"))
	if is_endless_mode:
		_apply_endless_template_level(_econ)
	# 必须在无尽模板替换 `level` 之后再读，否则无尽会沿用入口关卡的编队而不是模板的。
	wave_formation = str(level.get("wave_pattern", "standard"))
	# 阶段 67：进入战斗时套用本关环境的空间混音，离开战斗时在 _exit_tree 归零。
	AudioManager.apply_environment_mix(str(level.get("env", "")))
	econ_gold_base = float(_econ.get("gold_drop_base", 5))
	econ_gold_per = float(_econ.get("gold_drop_per_level", 0.6))
	_load_wave_clear_fast_forward_config(_econ)
	AudioManager.play_bgm(_battle_bgm_id())
	primary_weakness = str(level.get("primary_weakness", "physical"))
	onboarding_stage = str(level.get("onboarding_stage", ""))
	_apply_variant_modifiers()
	power_level_id = endless_template_level_id if is_endless_mode and endless_template_level_id != "" else level_id
	recommended_combat_power = SaveManager.get_recommended_power_for_level(power_level_id)
	if is_challenge_mode:
		recommended_combat_power = int(ceil(float(recommended_combat_power) * _challenge_mult("recommended_power_mult", CHALLENGE_RECOMMENDED_POWER_MULT)))
	player_power = SaveManager.get_power_for_level(power_level_id)
	loadout_power_ratio = float(player_power) / maxf(float(recommended_combat_power), 1.0)
	run_skill_hp_pressure_mult = SaveManager.get_run_skill_hp_pressure_for_level(power_level_id)
	run_skill_speed_pressure_mult = SaveManager.get_run_skill_speed_pressure_for_level(power_level_id)
	wave_total = int(level.get("waves", []).size())
	base_hp_max = int(round(float(level.get("base_hp_ref", 100)) * _boss_level_base_hp_mult(_econ)))
	base_hp = base_hp_max
	xp = 0
	gold = 0
	cards_picked = 0
	cards_selected = 0
	target_card_picks = maxi(1, int(level.get("target_card_picks", 3)))
	level_raw_run_xp_total = _compute_level_raw_run_xp()
	level_run_xp_budget = 0 if is_endless_mode else maxi(0, int(level.get("run_xp_budget", 0)))
	level_run_xp_raw_earned = 0.0
	level_run_xp_budget_awarded = 0
	level_total_run_xp = _compute_level_total_run_xp()
	next_xp_offer = _pick_threshold(1)
	reroll_charges = 1
	battle_finished = false
	pre_final_offer_used = false
	skill_fire_rate_mult = 1.0
	fire_rate_profile_id = SettingsManager.get_fire_rate_profile()
	fire_rate_weapon_base = 1.0
	fire_rate_authored_weapon_base = 1.0
	fire_rate_control_rate = 1.0
	character_active_cd = 0.0
	character_fire_rate_mult = 1.0
	sig_vanguard_barrage_timer = 0.0
	sig_vanguard_overload_timer = 0.0
	sig_vanguard_overload_used = false
	sig_frost_glacier_timer = 0.0
	sig_frost_glacier_tick = 0.0
	card_offer_active = false
	paused = false
	manual_aim_active = false
	manual_aim_point = Vector2(540, 600)
	manual_aim_until = 0.0
	debug_overlay_on = false
	low_hp_warned = false
	last_threat_warning_at = -99.0
	last_gold_sfx_at = -99.0
	last_wave_toast_at = -99.0
	pending_wave_toast = {}
	pending_wave_toast_timer_active = false
	onboarding_tip_shown = false
	wave_tip_shown = {}
	kill_streak = 0
	last_kill_at = -99.0
	displayed_wave_pct = 0.0
	displayed_xp_pct = 0.0
	build_feedback_shown = {}
	_reset_battle_report()
	$Hud/DebugOverlay.visible = false
	$Hud/PauseOverlay.visible = false
	$Hud/CardPanel.visible = false
	_apply_runtime_ui_styles()
	_install_testflight_performance_overlay()
	_ensure_skill_hint_overlay()
	_apply_safe_area()
	_ensure_boss_hp_bar()
	_spawn_low_hp_pulse()
	_spawn_feedback_managers()
	target_manager = TargetingManager.new()
	add_child(target_manager)
	_load_equipment()
	_configure_character_active_skill()
	_seed_character_affinity()
	_apply_base_survivability()
	turret = TURRET_SCENE.instantiate()
	if _audit_combat_rng != null:
		turret.process_physics_priority = -50000
	turret.position = Vector2(540, 1660.0 + bottom_dock_shift)
	turret.setup(_themed_weapon_row(DataLoader.get_row("weapons", weapon_id)), weapon_level)
	fire_rate_weapon_base = turret.fire_rate
	fire_rate_authored_weapon_base = turret.fire_rate
	_apply_turret_modifiers()
	turret.visible = false
	turret.fired.connect(_on_turret_fired)
	add_child(turret)
	turret.process_mode = Node.PROCESS_MODE_PAUSABLE
	if _audit_combat_rng != null:
		turret.set_physics_process(false)
	_spawn_character()
	_spawn_theme_base_overlay()
	_spawn_pet()
	InputManager.manual_aim_started.connect(_on_manual_aim_started)
	InputManager.aim_point.connect(_on_manual_aim_point)
	InputManager.manual_aim_released.connect(_on_manual_aim_released)
	InputManager.target_locked.connect(_on_target_lock_requested)
	InputManager.pause_pressed.connect(_on_pause_pressed)
	InputManager.target_strategy_changed.connect(_on_strategy_changed)
	InputManager.skill_pressed.connect(_on_skill_pressed)
	$PauseLayer/PauseButton.pressed.connect(_on_pause_pressed)
	$Hud/PauseOverlay/Panel/ResumeButton.pressed.connect(_on_resume_pressed)
	$Hud/PauseOverlay/Panel/RestartButton.pressed.connect(_on_restart_pressed)
	$Hud/PauseOverlay/Panel/MapButton.pressed.connect(_on_pause_to_map)
	$Hud/CharacterSkillButton.pressed.connect(_on_character_skill_pressed)
	$Hud/CardPanel/RerollButton.pressed.connect(_on_reroll_pressed)
	$Hud/CardPanel/SkipButton.pressed.connect(_on_skip_card)
	$Hud/CardPanel/DetailOverlay/Panel/CloseButton.pressed.connect(_hide_card_detail)
	$LockIndicator.texture = load("res://assets/production/sprites/vfx/vfx_target_lock.png")
	$LockIndicator.modulate = Color(0.6, 0.92, 1.0, 0.88)  # MiniMax HUD 锁定环，青白发光，加法融入战场
	($LockIndicator as CanvasItem).material = VfxLib._new_additive_material()  # 加法发光，融入战场光感
	_spawn_slow_field_visual()
	_spawn_barrier_visual()
	_build_skill_slots()
	_update_objective_panel()
	_update_hud()
	_show_loadout_intro()
	_start_next_wave()
	call_deferred("_show_onboarding_tip")
	call_deferred("_ensure_battle_running")

func _install_testflight_performance_overlay() -> void:
	if not OS.has_feature("testflight_speed_unlocked"):
		return
	var overlay_script := load("res://gameplay/hud/testflight_performance_overlay.gd")
	var overlay: Node = overlay_script.new()
	$Hud.add_child(overlay)
	overlay.call("setup", $EnemyLayer, $ProjectileLayer)

func _ensure_battle_running() -> void:
	if not is_inside_tree():
		return
	if Engine.time_scale < 0.99:
		Engine.time_scale = 1.0
	if card_offer_active and (!$Hud/CardPanel.visible):
		_close_card_offer(false)
	elif get_tree().paused and not paused and not card_offer_active:
		get_tree().paused = false
	elif get_tree().paused and card_offer_active and $Hud/CardPanel.visible:
		var cards := $Hud/CardPanel/Cards
		if cards.get_child_count() == 0:
			_close_card_offer(false)
	if not card_offer_active and not paused and active_spawning and pending_spawns.is_empty() and $EnemyLayer.get_child_count() == 0 and spawn_timer <= 0.0:
		active_spawning = false

func _configure_pause_process_modes() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for path in ["Background", "EnemyLayer", "ProjectileLayer", "ThreatMarkerLayer", "SlowFieldLayer", "LockIndicator"]:
		var node := get_node_or_null(path)
		if node != null:
			node.process_mode = Node.PROCESS_MODE_PAUSABLE
	if has_node("Hud"):
		$Hud.process_mode = Node.PROCESS_MODE_ALWAYS
		for path in ["Hud/CardPanel", "Hud/PauseOverlay", "Hud/DebugOverlay", "Hud/CharacterSkillButton", "Hud/SkillHintOverlay"]:
			var hud_node := get_node_or_null(path)
			if hud_node != null:
				hud_node.process_mode = Node.PROCESS_MODE_ALWAYS
	if has_node("PauseLayer"):
		$PauseLayer.process_mode = Node.PROCESS_MODE_ALWAYS
	_refresh_runtime_pause_modes()

func _refresh_runtime_pause_modes() -> void:
	for path in ["EnemyLayer", "ProjectileLayer", "ThreatMarkerLayer", "SlowFieldLayer"]:
		var layer := get_node_or_null(path)
		if layer == null:
			continue
		layer.process_mode = Node.PROCESS_MODE_PAUSABLE
		for child in layer.get_children():
			_set_subtree_process_mode(child, Node.PROCESS_MODE_PAUSABLE)
	for node in [turret, character_rig, pet_sprite, barrier_visual, hit_stop, screen_shake_node, off_screen_indicators, gold_fly]:
		if node != null and is_instance_valid(node):
			(node as Node).process_mode = Node.PROCESS_MODE_PAUSABLE

func _set_subtree_process_mode(node: Node, mode_value: int) -> void:
	if node == null or not is_instance_valid(node):
		return
	node.process_mode = mode_value
	for child in node.get_children():
		if child is Node:
			_set_subtree_process_mode(child, mode_value)

func _set_card_offer_pause_active(active: bool) -> void:
	card_offer_active = active
	_refresh_runtime_pause_modes()
	if active:
		_set_turret_fire_enabled(false)
		_hide_skill_hint()
		# Card selection is the only decision surface while the run is paused.
		# Clear queued onboarding/wave copy as well as the visible banner so it
		# cannot read through the modal or compete with the offer title.
		_hide_wave_toast()
		card_press_skill_id = ""
		card_long_press_opened = false
		skill_hint_press_kind = ""
		skill_hint_long_press_opened = false
		Engine.time_scale = battle_speed
	get_tree().paused = paused or card_offer_active
	_update_character_skill_button()

func _close_card_offer(play_resume_sfx := false) -> void:
	if play_resume_sfx:
		AudioManager.play_sfx("resume", -5.0)
	_set_card_offer_pause_active(false)
	$Hud/CardPanel.visible = false
	$Hud/CardPanel/DetailOverlay.visible = false
	card_press_skill_id = ""
	card_long_press_opened = false

func _physics_process(delta: float) -> void:
	_ensure_battle_running()
	if paused:
		_set_turret_fire_enabled(false)
		_update_hud()
		return
	if card_offer_active:
		_set_turret_fire_enabled(false)
		return
	var real_delta := delta / maxf(battle_speed, 1.0)
	# EnemyLayer is queried by targeting, reporting, information density, enemy
	# mechanics and the slow field every physics tick. Capture one stable view
	# for those systems instead of allocating the same child array repeatedly.
	# Newly spawned enemies enter after this group and are intentionally picked
	# up on the next physics tick, matching the existing processing order.
	var frame_enemies := $EnemyLayer.get_children()
	if _audit_combat_rng != null:
		frame_enemies.sort_custom(func(left: Node, right: Node) -> bool:
			return int(left.get_meta("audit_spawn_index", 2147483647)) < int(right.get_meta("audit_spawn_index", 2147483647))
		)
	battle_elapsed_seconds += real_delta
	apocalypse_terminal_cooldown = maxf(0.0, apocalypse_terminal_cooldown - real_delta)
	inferno_awakening_cooldown = maxf(0.0, inferno_awakening_cooldown - real_delta)
	inferno_feedback_cooldown = maxf(0.0, inferno_feedback_cooldown - real_delta)
	absolute_zero_wave_cooldown = maxf(0.0, absolute_zero_wave_cooldown - real_delta)
	absolute_zero_awakening_cooldown = maxf(0.0, absolute_zero_awakening_cooldown - real_delta)
	golden_law_awakening_cooldown = maxf(0.0, golden_law_awakening_cooldown - real_delta)
	golden_law_decree_cooldown = maxf(0.0, golden_law_decree_cooldown - real_delta)
	absolute_zero_feedback_cooldown = maxf(0.0, absolute_zero_feedback_cooldown - real_delta)
	_update_battle_report_control(real_delta, frame_enemies)
	_sync_logic_turret_to_character()
	_update_auto_target(frame_enemies)
	_update_combat_information_density(delta, false, frame_enemies)
	_process_character_animation(delta)
	_process_character_signatures(delta)
	_audit_process_delayed_skill_callbacks(real_delta)
	_process_pet(delta)
	_process_enemy_mechanics(delta * _challenge_mult("mechanic_rate_mult"), frame_enemies)
	_apply_slow_field(frame_enemies)
	_process_spawns(delta)
	_audit_advance_combat_nodes(delta)
	_check_victory()
	_update_lock_indicator()
	_update_off_screen_indicators()
	_update_hud()

func _audit_advance_combat_nodes(delta: float) -> void:
	if _audit_combat_rng == null:
		return
	# Match the production frame's logical order, but make it explicit and
	# stable for the headless calibration probe: battle -> turret -> enemies ->
	# projectiles.  Nodes born during this pass join on the next authored tick.
	if turret != null and is_instance_valid(turret) and not turret.is_queued_for_deletion():
		turret.call("_physics_process", delta)
	var audit_enemies := $EnemyLayer.get_children()
	audit_enemies.sort_custom(func(left: Node, right: Node) -> bool:
		return int(left.get_meta("audit_spawn_index", 2147483647)) < int(right.get_meta("audit_spawn_index", 2147483647))
	)
	for enemy in audit_enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			enemy.call("_physics_process", delta)
	var audit_projectiles := $ProjectileLayer.get_children()
	audit_projectiles = audit_projectiles.filter(func(node: Node) -> bool:
		return node.has_meta("audit_projectile_spawn_index")
	)
	audit_projectiles.sort_custom(func(left: Node, right: Node) -> bool:
		return int(left.get_meta("audit_projectile_spawn_index", 2147483647)) < int(right.get_meta("audit_projectile_spawn_index", 2147483647))
	)
	for projectile in audit_projectiles:
		if is_instance_valid(projectile) and not projectile.is_queued_for_deletion():
			projectile.call("_physics_process", delta)

func _update_auto_target(enemies: Array = []) -> void:
	var candidates := enemies if not enemies.is_empty() else $EnemyLayer.get_children()
	var has_fireable_target := _has_fireable_targets(candidates)
	_set_turret_fire_enabled(has_fireable_target)
	if not has_fireable_target:
		return
	if _manual_aim_has_priority():
		_apply_manual_aim()
		return
	var target := target_manager.choose_target(candidates, _weapon_fire_origin(false))
	if target:
		turret.aim_at(target.global_position)
	else:
		_set_turret_fire_enabled(false)

func _update_combat_information_density(delta: float, force := false, enemies: Array = []) -> void:
	combat_label_refresh_left -= delta
	if not force and combat_label_refresh_left > 0.0:
		return
	combat_label_refresh_left = COMBAT_LABEL_REFRESH_SECONDS
	var source := enemies if not enemies.is_empty() else $EnemyLayer.get_children()
	var valid_enemies: Array[Node] = []
	for child in source:
		if child is Node and is_instance_valid(child) and not child.is_queued_for_deletion() and child.has_method("targeting_snapshot"):
			valid_enemies.append(child)
	var priority := _combat_information_priority(valid_enemies)
	var condensed := valid_enemies.size() > COMBAT_LABEL_FULL_DENSITY_MAX
	var status_vfx_table: Dictionary = DataLoader.get_table("status_vfx")
	var status_vfx_global: Dictionary = status_vfx_table.get("global", {})
	var full_effect_max := int(status_vfx_global.get("full_density_max", 24))
	var condensed_effect_max := int(status_vfx_global.get("condensed_density_max", 48))
	for enemy in valid_enemies:
		var selected := not condensed or priority.has(enemy)
		if enemy.has_method("set_combat_label_visibility"):
			enemy.call("set_combat_label_visibility", selected, selected)
		if enemy.has_method("set_combat_effect_density"):
			var lod := "full"
			if valid_enemies.size() > condensed_effect_max:
				lod = "full" if priority.has(enemy) else "minimal"
			elif valid_enemies.size() > full_effect_max:
				lod = "full" if priority.has(enemy) else "condensed"
			enemy.call("set_combat_effect_density", lod, priority.has(enemy))

func _combat_information_priority(enemies: Array[Node]) -> Array[Node]:
	var valid: Array[Node] = []
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or not enemy.has_method("targeting_snapshot"):
			continue
		var hp_value = enemy.get("hp")
		if hp_value != null and float(hp_value) <= 0.0:
			continue
		valid.append(enemy)
	if valid.size() <= COMBAT_LABEL_FULL_DENSITY_MAX:
		return valid

	var selected: Array[Node] = []
	var origin := _weapon_fire_origin(false)
	var locked = target_manager.locked_enemy if target_manager != null else null
	if is_instance_valid(locked) and valid.has(locked):
		selected.append(locked)
	for enemy in valid:
		var snapshot: Dictionary = enemy.targeting_snapshot()
		if bool(snapshot.get("boss", false)) and not selected.has(enemy):
			selected.append(enemy)

	# Preserve one elite callout even when a wave contains several elite-tagged
	# units. Remaining elites still rank naturally by pressure, but do not make
	# every label permanent and recreate the wall of text this policy removes.
	var best_elite: Node = null
	var best_elite_score := -INF
	for enemy in valid:
		var snapshot: Dictionary = enemy.targeting_snapshot()
		if not bool(snapshot.get("elite", false)) or bool(snapshot.get("boss", false)):
			continue
		var score := target_manager.score_enemy(snapshot, origin) if target_manager != null else float(snapshot.get("y", 0.0))
		if score > best_elite_score:
			best_elite_score = score
			best_elite = enemy
	if best_elite != null and not selected.has(best_elite):
		selected.append(best_elite)

	var primary := target_manager.choose_target(valid, _weapon_fire_origin(false)) if target_manager != null else null
	if is_instance_valid(primary) and not selected.has(primary):
		selected.append(primary)

	var ranked: Array[Dictionary] = []
	for enemy in valid:
		if selected.has(enemy):
			continue
		var snapshot: Dictionary = enemy.targeting_snapshot()
		ranked.append({
			"enemy": enemy,
			"score": target_manager.score_enemy(snapshot, origin) if target_manager != null else float(snapshot.get("y", 0.0)),
			"y": float(snapshot.get("y", 0.0)),
		})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a := float(a.get("score", 0.0))
		var score_b := float(b.get("score", 0.0))
		if not is_equal_approx(score_a, score_b):
			return score_a > score_b
		return float(a.get("y", 0.0)) > float(b.get("y", 0.0))
	)
	var cap := COMBAT_LABEL_MEDIUM_CAP if valid.size() <= COMBAT_LABEL_MEDIUM_DENSITY_MAX else COMBAT_LABEL_HIGH_CAP
	for item in ranked:
		if selected.size() >= cap:
			break
		selected.append(item.get("enemy") as Node)
	return selected

func _set_turret_fire_enabled(enabled: bool) -> void:
	if turret == null or not is_instance_valid(turret):
		return
	turret.set("fire_enabled", enabled)

func _has_fireable_targets(enemies: Array = []) -> bool:
	var candidates := enemies if not enemies.is_empty() else $EnemyLayer.get_children()
	for enemy in candidates:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if not enemy.has_method("targeting_snapshot"):
			continue
		var hp_value = enemy.get("hp")
		if hp_value != null and float(hp_value) <= 0.0:
			continue
		return true
	return false

func _on_manual_aim_started(world_pos: Vector2) -> void:
	if _manual_aim_blocked():
		return
	manual_aim_active = true
	manual_aim_point = _bounded_aim_point(world_pos)
	manual_aim_until = _now_seconds() + MANUAL_AIM_RELEASE_GRACE
	_apply_manual_aim()

func _on_manual_aim_point(world_pos: Vector2) -> void:
	if _manual_aim_blocked():
		return
	manual_aim_point = _bounded_aim_point(world_pos)
	if manual_aim_active:
		manual_aim_until = _now_seconds() + MANUAL_AIM_RELEASE_GRACE
		_apply_manual_aim()

func _on_manual_aim_released(world_pos: Vector2) -> void:
	if _manual_aim_blocked():
		manual_aim_active = false
		manual_aim_until = 0.0
		return
	manual_aim_point = _bounded_aim_point(world_pos)
	manual_aim_active = false
	manual_aim_until = _now_seconds() + MANUAL_AIM_RELEASE_GRACE
	_apply_manual_aim()

func _manual_aim_has_priority() -> bool:
	if _manual_aim_blocked():
		return false
	if manual_aim_active:
		return true
	return _now_seconds() <= manual_aim_until

func _manual_aim_blocked() -> bool:
	return battle_finished or card_offer_active or paused or turret == null

func _apply_manual_aim() -> void:
	if turret == null:
		return
	turret.aim_at(manual_aim_point)

func _bounded_aim_point(world_pos: Vector2) -> Vector2:
	return Vector2(clampf(world_pos.x, 0.0, 1080.0), clampf(world_pos.y, 0.0, 1920.0 + bottom_dock_shift))

func _now_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0

## Deterministic clock for gameplay-affecting cooldowns (premium-set combustion/
## shatter/verdict triggers and armor counters). Those systems store an
## absolute "ready at" deadline and later gate real damage + base_hp repair on
## it, so under the headless audit probe they must key off the fixed 1/60
## simulation clock instead of wall time — real elapsed process time varies
## with host scheduling/acceleration and previously made those triggers (and
## the damage/base HP they apply) fire on different physics ticks between
## byte-identical seeded runs. Production combat keeps the authored wall-clock
## feel; only the audit probe (_audit_combat_rng != null) switches source.
## Pure presentation throttles (screen shake, sfx/toast rate limiting, sprite
## jitter) intentionally keep using _now_seconds()/Time directly since they
## never feed back into combat state.
func _gameplay_now_seconds() -> float:
	return battle_elapsed_seconds if _audit_combat_rng != null else Time.get_ticks_msec() / 1000.0

func _load_equipment() -> void:
	character_id = SaveManager.get_selected("character")
	if character_id == "":
		character_id = "vanguard"
	weapon_id = SaveManager.get_selected("weapon")
	if weapon_id == "":
		weapon_id = "weapon_autocannon"
	weapon_level = SaveManager.get_weapon_level(weapon_id)
	# 不再回退默认护甲/芯片：开局未拥有就真的没有（与商店/出战配置一致，也让前期不再被白送装备）。
	armor_id = SaveManager.get_selected("armor")
	chip_id = SaveManager.get_selected("chip")
	pet_id = SaveManager.get_selected("pet")
	character_data = DataLoader.get_row("characters", character_id)
	armor_data = DataLoader.get_row("armors", armor_id) if armor_id != "" else {}
	chip_data = DataLoader.get_row("chips", chip_id) if chip_id != "" else {}
	pet_data = DataLoader.get_row("pets", pet_id) if pet_id != "" else {}
	character_level = SaveManager.get_item_level(character_id)
	armor_level = SaveManager.get_item_level(armor_id) if armor_id != "" else 1
	chip_level = SaveManager.get_item_level(chip_id) if chip_id != "" else 1
	pet_level = SaveManager.get_item_level(pet_id) if pet_id != "" else 1

func _configure_character_active_skill() -> void:
	var active: Dictionary = character_data.get("active_skill", {})
	character_active_id = str(active.get("id", ""))
	character_active_cd_max = _active_skill_cooldown(active)
	character_active_cd = 0.0
	if has_node("Hud/CharacterSkillButton"):
		$Hud/CharacterSkillButton.visible = character_active_id != ""
		_bind_character_skill_button()
		_update_character_skill_button()

func _bind_character_skill_button() -> void:
	if not has_node("Hud/CharacterSkillButton"):
		return
	var button := $Hud/CharacterSkillButton as BaseButton
	var label := $Hud/CharacterSkillButton/Label as Label
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = false
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	if button is Button:
		(button as Button).text = ""
	if button is TextureButton:
		var texture_button := button as TextureButton
		texture_button.texture_normal = null
		texture_button.texture_hover = null
		texture_button.texture_pressed = null
		texture_button.texture_disabled = null
	button.focus_mode = Control.FOCUS_NONE
	_ensure_character_skill_icon_nodes()
	if not button.mouse_entered.is_connected(_on_character_skill_button_hover):
		button.mouse_entered.connect(_on_character_skill_button_hover.bind(true))
		button.mouse_exited.connect(_on_character_skill_button_hover.bind(false))
	if not button.gui_input.is_connected(_on_character_skill_hint_input):
		button.gui_input.connect(_on_character_skill_hint_input)

func _ensure_character_skill_icon_nodes() -> void:
	if not has_node("Hud/CharacterSkillButton"):
		return
	var button := $Hud/CharacterSkillButton as BaseButton
	button.pivot_offset = button.size * 0.5
	var label := button.get_node_or_null("Label") as Label
	if label != null:
		label.visible = false
	var legacy_fill := button.get_node_or_null("CooldownFill") as CanvasItem
	if legacy_fill != null:
		legacy_fill.visible = false
	if button.get_node_or_null("CooldownTexture") == null:
		var cooldown := TextureRect.new()
		cooldown.name = "CooldownTexture"
		cooldown.texture = load("res://assets/production/sprites/ui/ui_cd_overlay.png")
		cooldown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cooldown.stretch_mode = TextureRect.STRETCH_SCALE
		cooldown.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cooldown.z_index = 6
		cooldown.visible = false
		button.add_child(cooldown)
	var overlay := button.get_node_or_null("UnavailableOverlay") as Control
	if overlay != null:
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.offset_left = 0.0
		overlay.offset_top = 0.0
		overlay.offset_right = 0.0
		overlay.offset_bottom = 0.0
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.z_index = 8
	if button.get_node_or_null("IconFrame") == null:
		var frame := PanelContainer.new()
		frame.name = "IconFrame"
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame.offset_left = 10.0
		frame.offset_top = 10.0
		frame.offset_right = -10.0
		frame.offset_bottom = -10.0
		frame.z_index = 2
		button.add_child(frame)
		var icon := TextureRect.new()
		icon.name = "SkillIcon"
		icon.custom_minimum_size = Vector2(76, 76)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(icon)
	if button.get_node_or_null("ReadyOrbit") == null:
		var orbit := Control.new()
		orbit.name = "ReadyOrbit"
		orbit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		orbit.set_anchors_preset(Control.PRESET_FULL_RECT)
		orbit.z_index = 5
		button.add_child(orbit)
		for i in range(ACTIVE_SKILL_DOT_COUNT):
			var dot := PanelContainer.new()
			dot.name = "Dot%d" % i
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dot.size = Vector2(9, 9)
			dot.custom_minimum_size = Vector2(9, 9)
			orbit.add_child(dot)
	if button.get_node_or_null("CooldownLabel") == null:
		var cd_label := Label.new()
		cd_label.name = "CooldownLabel"
		cd_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cd_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cd_label.z_index = 7
		cd_label.visible = false
		cd_label.add_theme_font_size_override("font_size", UiKit.bumped_font_size(24))
		cd_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0, 1.0))
		cd_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
		cd_label.add_theme_constant_override("outline_size", 4)
		button.add_child(cd_label)

func _character_skill_accent() -> Color:
	match character_id:
		"blaze":
			return Color(1.0, 0.55, 0.22, 1.0)
		"volt":
			return Color(1.0, 0.9, 0.35, 1.0)
		"frost":
			return UiKit.INFO
		_:
			return UiKit.GOLD

func _character_skill_style(ready: bool, _accent: Color, _hovered: bool, _pressed: bool = false) -> StyleBox:
	return UiKit.skill_slot_texture_style(ready)

func _character_skill_icon_style(_accent: Color, ready: bool) -> StyleBox:
	return UiKit.icon_frame_texture_style(ready)

func _character_skill_dot_style(_accent: Color, _pulse: float) -> StyleBox:
	return UiKit.icon_frame_texture_style(true)

func _character_active_icon_path() -> String:
	match character_active_id:
		"sig_vanguard_railvolley":
			return str(DataLoader.get_row("skills", "skill_salvo").get("icon", ""))
		"sig_blaze_meltdown":
			return str(DataLoader.get_row("skills", "skill_incendiary").get("icon", ""))
		"sig_frost_glacier":
			return str(DataLoader.get_row("skills", "skill_cryo").get("icon", ""))
		"sig_volt_storm":
			return str(DataLoader.get_row("skills", "skill_tesla").get("icon", ""))
		_:
			return UiKit.element_icon_path(str(character_data.get("element_focus", "physical")))

func _on_character_skill_button_hover(inside: bool) -> void:
	if not has_node("Hud/CharacterSkillButton"):
		return
	var button := $Hud/CharacterSkillButton as BaseButton
	if button.disabled:
		button.scale = Vector2.ONE
		return
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05) if inside else Vector2.ONE, 0.08)

func _on_character_skill_hint_input(event: InputEvent) -> void:
	if character_active_id == "":
		return
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			_begin_skill_hint_press("character", "")
		else:
			_end_skill_hint_press()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_skill_hint_press("character", "")
		else:
			_end_skill_hint_press()

func _ensure_skill_hint_overlay() -> void:
	if not has_node("Hud") or has_node("Hud/SkillHintOverlay"):
		return
	var overlay := PanelContainer.new()
	overlay.name = "SkillHintOverlay"
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 620
	overlay.anchor_left = 0.5
	overlay.anchor_right = 0.5
	overlay.offset_left = -360.0
	overlay.offset_right = 360.0
	overlay.offset_top = 1460.0 + bottom_dock_shift
	overlay.offset_bottom = 1730.0 + bottom_dock_shift
	overlay.add_theme_stylebox_override("panel", UiKit.panel_texture_style(12.0))
	$Hud.add_child(overlay)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(margin)

	var row := HBoxContainer.new()
	row.name = "Row"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var icon_box := PanelContainer.new()
	icon_box.name = "IconBox"
	icon_box.custom_minimum_size = Vector2(104, 104)
	icon_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_box.add_theme_stylebox_override("panel", UiKit.icon_frame_texture_style(true))
	row.add_child(icon_box)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(94, 94)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_box.add_child(icon)

	var text_box := VBoxContainer.new()
	text_box.name = "TextBox"
	text_box.custom_minimum_size = Vector2(550, 228)
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_theme_constant_override("separation", 8)
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_box)

	var title := UiKit.label("", 26, UiKit.TEXT_MAIN, 3)
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.clip_text = false
	title.custom_minimum_size = Vector2(550, 34)
	text_box.add_child(title)

	var body := UiKit.label("", 19, Color(0.78, 0.9, 0.94, 1.0), 2)
	body.name = "Body"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.clip_text = false
	body.custom_minimum_size = Vector2(550, 176)
	text_box.add_child(body)

func _show_skill_hint_for_skill(skill_id: String) -> void:
	if skill_id == "":
		return
	_ensure_skill_hint_overlay()
	if not has_node("Hud/SkillHintOverlay"):
		return
	var row := DataLoader.get_row("skills", skill_id)
	if row.is_empty():
		return
	var lv: int = maxi(1, skills.level(skill_id))
	if card_offer_active:
		lv = _skill_offer_level(skill_id)
	var effect := SkillEffectText.format_effect(SkillEffectText.effect_for_level(row, lv))
	var title := "%s  %s" % [DataLoader.tr_key(str(row.get("name_key", skill_id))), LocalizationManager.text("等级%d") % lv]
	var body := "%s: %s\n%s: %s" % [
		_loc("效果", "Effect"),
		effect,
		_loc("说明", "Description"),
		LocalizationManager.text(_skill_short_desc(skill_id, lv)),
	]
	_show_skill_hint(title, body, str(row.get("icon", "")), _skill_card_accent(skill_id, row))

func _show_character_skill_hint() -> void:
	if character_active_id == "":
		return
	var info: Dictionary = CharacterSkillText.signature_info(character_active_id)
	var cooldown := LocalizationManager.text("冷却 %.0f 秒" % character_active_cd_max)
	var title := LocalizationManager.text("%s  主动技能" % LocalizationManager.text(str(info.get("name", "角色技能"))))
	var body := "%s\n%s" % [cooldown, LocalizationManager.text(str(info.get("desc", "")))]
	_show_skill_hint(title, body, _character_active_icon_path(), _character_skill_accent())

func _show_skill_hint(title_text: String, body_text: String, icon_path: String, accent: Color) -> void:
	_ensure_skill_hint_overlay()
	if not has_node("Hud/SkillHintOverlay"):
		return
	var overlay := $Hud/SkillHintOverlay as PanelContainer
	overlay.visible = true
	# Runtime skill explanations are temporary, non-pausing combat UI. Card-offer
	# hover copy keeps its existing hover/exit lifetime so selecting a card never
	# requires an extra dismissing tap.
	skill_hint_auto_hide_at = (
		0.0
		if card_offer_active
		else Time.get_ticks_msec() / 1000.0 + SKILL_HINT_AUTO_HIDE_SECONDS
	)
	overlay.add_theme_stylebox_override("panel", UiKit.panel_texture_style(12.0))
	var icon_box := overlay.get_node_or_null("Margin/Row/IconBox") as PanelContainer
	if icon_box != null:
		icon_box.add_theme_stylebox_override("panel", UiKit.icon_frame_texture_style(true))
	var icon := overlay.get_node_or_null("Margin/Row/IconBox/Icon") as TextureRect
	if icon != null:
		icon.texture = load(icon_path) if icon_path != "" and ResourceLoader.exists(icon_path) else null
	var title := overlay.get_node_or_null("Margin/Row/TextBox/Title") as Label
	if title != null:
		title.text = title_text
		UiKit.apply_label(title, 26, Color(0.96, 0.94, 0.86, 1.0), 3)
	var body := overlay.get_node_or_null("Margin/Row/TextBox/Body") as Label
	if body != null:
		body.text = body_text
		UiKit.apply_label(body, 19, Color(0.78, 0.9, 0.94, 1.0), 2)
	if title != null and body != null:
		_fit_skill_hint_overlay_content(overlay, title, body)

func _fit_skill_hint_overlay_content(overlay: PanelContainer, title: Label, body: Label) -> void:
	var text_width := 550.0
	var title_height := _wrapped_label_required_height(title, text_width, 34.0)
	var body_height := _wrapped_label_required_height(body, text_width, 176.0)
	title.custom_minimum_size = Vector2(text_width, title_height)
	body.custom_minimum_size = Vector2(text_width, body_height)
	var text_box := overlay.get_node_or_null("Margin/Row/TextBox") as VBoxContainer
	if text_box != null:
		text_box.custom_minimum_size = Vector2(text_width, title_height + 8.0 + body_height)
	var content_height := maxf(104.0, title_height + 8.0 + body_height) + 32.0
	var overlay_height := ceilf(maxf(270.0, content_height))
	overlay.offset_top = overlay.offset_bottom - overlay_height

func _hide_skill_hint(clear_press_state := true) -> void:
	if has_node("Hud/SkillHintOverlay"):
		$Hud/SkillHintOverlay.visible = false
	skill_hint_auto_hide_at = 0.0
	if clear_press_state:
		_clear_skill_hint_press_state()

func _skill_hint_is_temporarily_visible() -> bool:
	return (
		skill_hint_auto_hide_at > 0.0
		and has_node("Hud/SkillHintOverlay")
		and $Hud/SkillHintOverlay.visible
	)

func _primary_press_position(event: InputEvent) -> Variant:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			return event.position
	elif event is InputEventScreenTouch and event.pressed:
		return event.position
	return null

func _skill_hint_position_hits_action(position: Vector2) -> bool:
	# Do not turn the explanation into a modal that makes the pause, speed or
	# another skill button need two taps. Only empty battlefield/HUD space owns
	# the dismiss gesture.
	var action_paths := [
		"Hud/CharacterSkillButton",
		"PauseLayer/PauseButton",
		"PauseLayer/SpeedButton",
	]
	for path in action_paths:
		var action := get_node_or_null(path) as Control
		if action != null and action.visible and action.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			if action.get_global_rect().has_point(position):
				return true
	var slots := get_node_or_null("Hud/SkillSlots")
	if slots != null:
		for slot_node in slots.get_children():
			var slot := slot_node as Control
			if slot != null and slot.visible and slot.get_global_rect().has_point(position):
				return true
	return false

func _input(event: InputEvent) -> void:
	if not _skill_hint_is_temporarily_visible():
		return
	var press_position_var: Variant = _primary_press_position(event)
	if not (press_position_var is Vector2):
		return
	var press_position: Vector2 = press_position_var
	if _consume_skill_hint_press(press_position):
		get_viewport().set_input_as_handled()

func _consume_skill_hint_press(press_position: Vector2) -> bool:
	if not _skill_hint_is_temporarily_visible():
		return false
	var overlay := $Hud/SkillHintOverlay as Control
	if overlay.get_global_rect().has_point(press_position):
		# The panel itself is informational; consume presses inside it so they do
		# not leak through to manual aim.
		return true
	if _skill_hint_position_hits_action(press_position):
		return false
	# An empty-space tap is a pure dismissal. Cancel any already-observed aim
	# press as a defensive measure against input-order differences on iOS.
	var keep_press_state := skill_hint_press_kind != ""
	_hide_skill_hint(not keep_press_state)
	InputManager.cancel_active_input()
	return true

func _clear_skill_hint_press_state() -> void:
	skill_hint_press_kind = ""
	skill_hint_press_skill_id = ""
	skill_hint_long_press_opened = false

func _begin_skill_hint_press(kind: String, skill_id: String) -> void:
	skill_hint_press_kind = kind
	skill_hint_press_skill_id = skill_id
	skill_hint_press_started_at = Time.get_ticks_msec() / 1000.0
	skill_hint_long_press_opened = false

func _end_skill_hint_press() -> void:
	var press_kind := skill_hint_press_kind
	var was_long_press := skill_hint_long_press_opened
	_clear_skill_hint_press_state()
	if press_kind == "character" and was_long_press:
		# BaseButton emits `pressed` after the release gui_input. Swallow exactly
		# that release so a hold-to-inspect gesture can never also cast.
		suppress_next_character_skill_press = true

# Seed the equipped weapon's intrinsic element skill at its saved permanent
# level (minimum 1) so the build is visible from the first frame. Anchored on
# the weapon (not
# the character's bullet_affinity) because what the player *sees*
# firing on screen — e.g. flame jets, ice shards, lightning — is the
# weapon's element, and that should match the seeded skill. Physical
# weapons skip this; picking the matching element card later still
# levels up the same way.
func _seed_character_affinity() -> void:
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var element := str(weapon.get("element", "physical"))
	if element == "" or element == "physical":
		return
	var skill_id := _ammo_skill_for_element(element)
	if skill_id == "":
		return
	if not skills.can_add_skill(skill_id):
		return
	skills.add_skill(skill_id)

func _ammo_skill_for_element(element: String) -> String:
	var skill_table: Dictionary = DataLoader.get_table("skills")
	for skill_id in skill_table.keys():
		var row: Dictionary = skill_table.get(skill_id, {})
		if str(row.get("exclusive_group", "")) == "projectile_element" and str(row.get("ammo_element", "")) == element:
			return str(skill_id)
	return ""

func _skill_compatible_with_weapon(skill_id: String) -> bool:
	var row := DataLoader.get_row("skills", skill_id)
	if str(row.get("exclusive_group", "")) != "projectile_element":
		return true
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var weapon_element := str(weapon.get("element", "physical"))
	var set_id := str(weapon.get("premium_set", ""))
	if set_id != "":
		var set_row := DataLoader.get_row("premium_sets", set_id)
		if str(set_row.get("weapon", "")) == weapon_id and bool(set_row.get("ammo_cards_override_base_element", false)):
			return true
	if weapon_element == "" or weapon_element == "physical":
		return true
	return str(row.get("ammo_element", "")) == weapon_element

func _on_skill_pressed(slot: int) -> void:
	if slot == 0:
		_on_character_skill_pressed()

func _on_character_skill_pressed() -> void:
	if suppress_next_character_skill_press:
		suppress_next_character_skill_press = false
		return
	if card_offer_active or paused or character_active_id == "":
		return
	if character_active_cd > 0.0:
		# Skill explanations are hold-only. The authored cooldown number already
		# communicates this short tap's unavailable state without opening a panel.
		return
	_hide_skill_hint()
	var cast_success := false
	match character_active_id:
		"sig_vanguard_railvolley":
			cast_success = _cast_vanguard_railvolley()
		"sig_blaze_meltdown":
			cast_success = _cast_blaze_meltdown()
		"sig_frost_glacier":
			cast_success = _cast_frost_glacier()
		"sig_volt_storm":
			cast_success = _cast_volt_storm()
		_:
			return
	if not cast_success:
		_flash_character_skill_button_unavailable()
		_show_wave_toast("技能暂不可用", Color(0.72, 0.92, 1.0))
		AudioManager.play_sfx("ui_click", -6.0)
		return
	battle_active_skill_casts += 1
	_play_character_skill()
	SettingsManager.pulse_haptic("medium")
	character_active_cd = character_active_cd_max
	_update_character_skill_button()
	_update_character_skill_button()

func _process_character_signatures(delta: float) -> void:
	if character_active_cd > 0.0:
		character_active_cd = maxf(0.0, character_active_cd - delta)
	if sig_vanguard_barrage_timer > 0.0:
		sig_vanguard_barrage_timer = maxf(0.0, sig_vanguard_barrage_timer - delta)
	if sig_vanguard_overload_timer > 0.0:
		sig_vanguard_overload_timer = maxf(0.0, sig_vanguard_overload_timer - delta)
	if character_id == "vanguard" and not sig_vanguard_overload_used and base_hp_max > 0 and float(base_hp) / float(base_hp_max) <= 0.3:
		_trigger_vanguard_overload()
	if sig_frost_glacier_timer > 0.0:
		sig_frost_glacier_timer = maxf(0.0, sig_frost_glacier_timer - delta)
		_process_frost_glacier(delta)
	_refresh_character_fire_rate_buff()
	_update_character_skill_button()

func _cast_vanguard_railvolley() -> bool:
	var active: Dictionary = character_data.get("active_skill", {})
	sig_vanguard_barrage_timer = _active_skill_duration(active, 6.0)
	var volley_count := _vanguard_railvolley_count(active)
	var primary_damage := _current_primary_shot_damage("physical")
	var damage := _vanguard_railvolley_damage(primary_damage)
	_active_skill_cast_intro("弹幕齐射", Color(1.0, 0.88, 0.42), "sig_vanguard_railvolley")
	var muzzle := _weapon_fire_origin()
	_spawn_vfx_sequence("vfx_muzzle_physical", muzzle + Vector2(0, -28), 0.88, Color(1.0, 0.9, 0.46, 0.9), 1.4, _weapon_fire_direction().angle(), 1.08, Vector2.ZERO, 0.0, true)
	_spawn_vfx_sequence("vfx_crit", muzzle + Vector2(0, -76), 0.72, Color(1.0, 0.88, 0.36, 0.68), 1.25, randf_range(-0.2, 0.2), 1.18, Vector2(0, -22), randf_range(-0.4, 0.4), true)
	for i in range(volley_count):
		_active_skill_after(0.08 + float(i) * 0.15, Callable(self, "_vanguard_railvolley_hit").bind(i, volley_count, damage, primary_damage))
	_refresh_character_fire_rate_buff()
	return true

func _trigger_vanguard_overload() -> void:
	sig_vanguard_overload_used = true
	sig_vanguard_overload_timer = 5.0
	AudioManager.play_sfx("skill_salvo", -5.0, 0.02)
	_show_wave_toast("过载反击", Color(1.0, 0.42, 0.18))
	_play_character_skill(0.46)
	_spawn_vfx_sequence("vfx_levelup_glow", _weapon_fire_origin() + Vector2(0, -60), 0.94, Color(1.0, 0.48, 0.18, 0.76), 1.25, randf_range(-0.2, 0.2), 1.12, Vector2(0, -18), 0.32, true)
	_spawn_vfx_sequence("vfx_active_sig_vanguard_overload", _weapon_fire_origin() + Vector2(0, -74), 1.2, Color(1.0, 0.48, 0.18, 0.92), 0.95, randf_range(-0.1, 0.1), 1.08, Vector2(0, -8), randf_range(-0.16, 0.16), true)
	_refresh_character_fire_rate_buff()

func _cast_blaze_meltdown() -> bool:
	var active: Dictionary = character_data.get("active_skill", {})
	var radius := _blaze_meltdown_radius(active)
	var damage := _character_active_damage("fire", float(active.get("damage_mult", 3.6)))
	var target := _best_active_target()
	var origin := target.global_position if target != null else _active_skill_fallback_point(0.46)
	var battlefield_coverage := _blaze_meltdown_uses_battlefield(active)
	var opening_visual_origin := _blaze_meltdown_battlefield_visual_origin(0) if battlefield_coverage else origin
	_active_skill_cast_intro("熔毁爆发", Color(1.0, 0.42, 0.14), "sig_blaze_meltdown")
	_spawn_vfx_sequence("vfx_muzzle_fire", _weapon_fire_origin() + Vector2(0, -38), 0.92, Color(1.0, 0.58, 0.2, 0.86), 1.35, _weapon_fire_direction().angle(), 1.08, Vector2.ZERO, 0.0, true)
	_spawn_vfx_sequence("vfx_explosion_fire", opening_visual_origin + Vector2(0, -44), maxf(radius / 300.0, 0.72), Color(1.0, 0.48, 0.16, 0.86), 0.92, randf_range(-0.24, 0.24), 1.16, Vector2(0, -12), randf_range(-0.25, 0.25), true)
	for i in range(_blaze_meltdown_pulse_count(active)):
		_active_skill_after(0.16 + float(i) * 0.22, Callable(self, "_blaze_meltdown_pulse").bind(origin, radius, damage, i, battlefield_coverage))
	return true

func _cast_frost_glacier() -> bool:
	var active: Dictionary = character_data.get("active_skill", {})
	sig_frost_glacier_timer = _frost_glacier_duration(active)
	sig_frost_glacier_tick = 0.0
	var field_y := _frost_glacier_field_y(active)
	var tick_damage := _character_active_damage("ice", float(active.get("damage_mult", 0.34)))
	_active_skill_cast_intro("冰川领域", Color(0.55, 0.9, 1.0), "sig_frost_glacier")
	_spawn_vfx_sequence("vfx_muzzle_ice", _weapon_fire_origin() + Vector2(0, -42), 0.9, Color(0.66, 0.94, 1.0, 0.86), 1.35, _weapon_fire_direction().angle(), 1.08, Vector2.ZERO, 0.0, true)
	_spawn_vfx_sequence("vfx_freeze", Vector2(540, 1180.0 + bottom_dock_shift), 2.05, Color(0.6, 0.92, 1.0, 0.46), 0.86, 0.0, 1.05, Vector2(0, -8), 0.0, true)
	var wave_count := _frost_glacier_wave_count(active)
	for i in range(wave_count):
		var wave_y := lerpf(1220.0, field_y, float(i) / float(maxi(wave_count - 1, 1)))
		_active_skill_after(0.08 + float(i) * 0.2, Callable(self, "_frost_glacier_wave").bind(wave_y, tick_damage, i))
	_active_skill_after(0.92, Callable(self, "_process_frost_glacier").bind(0.0))
	return true

func _process_frost_glacier(delta: float) -> void:
	var active: Dictionary = character_data.get("active_skill", {})
	var field_y := _frost_glacier_field_y(active)
	var tick_damage := _character_active_damage("ice", float(active.get("damage_mult", 0.34)))
	sig_frost_glacier_tick -= delta
	var should_tick := sig_frost_glacier_tick <= 0.0
	if should_tick:
		sig_frost_glacier_tick = FROST_GLACIER_TICK_INTERVAL
	var affected := 0
	var field_enemies := $EnemyLayer.get_children()
	if _audit_combat_rng != null:
		field_enemies.sort_custom(_audit_enemy_precedes)
	for enemy in field_enemies:
		if not is_instance_valid(enemy) or enemy.global_position.y < field_y:
			continue
		affected += 1
		_apply_frost_glacier_status(enemy, tick_damage, FROST_GLACIER_STATUS_REFRESH)
		if should_tick and enemy.has_method("take_damage"):
			enemy.take_damage(tick_damage, "ice")
	if should_tick:
		var alpha := 0.34 + minf(float(affected), 7.0) * 0.018
		_spawn_vfx_sequence("vfx_freeze", Vector2(540, 1135.0 + bottom_dock_shift), 1.8, Color(0.56, 0.92, 1.0, alpha), 0.9, 0.0, 1.04, Vector2(0, -8), 0.0, true)

func _apply_frost_glacier_status(enemy: Node, tick_damage: float, status_duration: float) -> void:
	var active: Dictionary = character_data.get("active_skill", {})
	var speed_factor := _frost_glacier_speed_factor(active, bool(enemy.get("boss")))
	var slow_bonus := _frost_glacier_slow_bonus(active)
	if enemy.has_method("apply_glacier_field"):
		enemy.apply_glacier_field(tick_damage, _growth_rank(character_level), slow_bonus, status_duration, speed_factor)
	elif enemy.has_method("amplify_character_status"):
		enemy.set("speed_mult", float(enemy.get("speed_mult")) * speed_factor)
		enemy.amplify_character_status("ice", tick_damage, _growth_rank(character_level), slow_bonus)
	else:
		enemy.set("speed_mult", float(enemy.get("speed_mult")) * speed_factor)

func _cast_volt_storm() -> bool:
	var active: Dictionary = character_data.get("active_skill", {})
	var max_targets := _volt_storm_max_targets(active)
	var damage := _character_active_damage("lightning", float(active.get("damage_mult", 2.1)))
	var strike_count := _volt_storm_strike_count(active, max_targets)
	_active_skill_cast_intro("雷暴领域", Color(0.62, 0.94, 1.0), "sig_volt_storm")
	_spawn_vfx_sequence("vfx_muzzle_lightning", _weapon_fire_origin() + Vector2(0, -40), 1.0, Color(0.72, 0.96, 1.0, 0.9), 1.45, _weapon_fire_direction().angle(), 1.1, Vector2.ZERO, 0.0, true)
	_spawn_vfx_sequence("vfx_chain_lightning", _active_skill_fallback_point(0.38) + Vector2(0, -52), 1.2, Color(0.68, 0.94, 1.0, 0.72), 1.1, randf_range(-0.3, 0.3), 1.1, Vector2(0, -18), randf_range(-0.45, 0.45), true)
	for i in range(strike_count):
		_active_skill_after(0.08 + float(i) * 0.17, Callable(self, "_volt_storm_strike").bind(i, max_targets, damage))
	_active_skill_after(0.12 + float(strike_count) * 0.17, Callable(self, "_active_skill_finish_flash").bind(Color(0.56, 0.92, 1.0, 0.12), 0.2))
	return true

func _best_active_target() -> Node2D:
	var targets := _active_target_candidates(1)
	if targets.is_empty():
		return null
	return targets[0]

func _active_target_candidates(max_count: int) -> Array[Node2D]:
	var candidates := []
	var origin := _weapon_fire_origin(false)
	for enemy in $EnemyLayer.get_children():
		if not is_instance_valid(enemy) or not enemy is Node2D or not enemy.has_method("targeting_snapshot"):
			continue
		var score := target_manager.score_enemy(enemy.targeting_snapshot(), origin)
		if bool(enemy.boss):
			score += 95.0
		candidates.append({"enemy": enemy as Node2D, "score": score})
	# Active-skill target ranking (railvolley, meltdown fallback ordering, etc.)
	# previously broke score ties on Array.sort_custom's unstable ordering of the
	# raw, unsorted $EnemyLayer child list. That list's relative order is not
	# guaranteed stable across otherwise-identical seeded runs once nodes have
	# been added/removed over the battle, so two enemies with an equal score
	# (common in a dense crowd on the same line) could each win the tie on a
	# different run and take an extra volley hit that the other run's enemy
	# didn't. Break ties on the deterministic spawn index in audit mode; keep
	# production's existing highest-score-first behaviour otherwise.
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a := float(a.get("score", 0.0))
		var score_b := float(b.get("score", 0.0))
		if not is_equal_approx(score_a, score_b):
			return score_a > score_b
		if _audit_combat_rng == null:
			return false
		var enemy_a := a.get("enemy") as Node
		var enemy_b := b.get("enemy") as Node
		if enemy_a == null or enemy_b == null:
			return false
		return int(enemy_a.get_meta("audit_spawn_index", 2147483647)) < int(enemy_b.get_meta("audit_spawn_index", 2147483647))
	)
	var result: Array[Node2D] = []
	for item in candidates:
		if result.size() >= max_count:
			break
		var enemy_node := item.get("enemy") as Node2D
		if enemy_node != null and is_instance_valid(enemy_node):
			result.append(enemy_node)
	return result

func _active_skill_fallback_point(depth_ratio := 0.48) -> Vector2:
	var origin := _weapon_fire_origin(false)
	var direction := _weapon_fire_direction(Vector2.UP)
	var y := lerpf(560.0, 1160.0, clampf(depth_ratio, 0.0, 1.0))
	var projected := origin + direction.normalized() * 520.0
	return Vector2(clampf(projected.x, 190.0, 890.0), y)

func _active_skill_fallback_chain_points(count: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var center := _active_skill_fallback_point(0.42)
	var spacing := 132.0
	var first := -float(count - 1) * 0.5
	for i in range(count):
		points.append(Vector2(clampf(center.x + (first + float(i)) * spacing, 170.0, 910.0), center.y + float(i % 2) * 90.0))
	return points

func _active_skill_after(delay: float, callback: Callable) -> void:
	if _audit_combat_rng != null:
		_audit_delayed_skill_callbacks.append({
			"remaining": maxf(delay, 0.0),
			"callback": callback,
		})
		return
	var tween := create_tween()
	tween.tween_interval(maxf(delay, 0.0))
	tween.tween_callback(func() -> void:
		if not _active_skill_can_continue():
			return
		if paused or card_offer_active:
			_active_skill_after(0.08, callback)
			return
		callback.call()
	)

func _audit_process_delayed_skill_callbacks(delta: float) -> void:
	if _audit_combat_rng == null or _audit_delayed_skill_callbacks.is_empty():
		return
	# SceneTree tweens advance on rendered/process frames, so accelerated probes
	# can group a different number of authored physics ticks around a callback.
	# Audit combat owns the same delays on its fixed 1/60 clock instead.  Copy the
	# queue before invoking callbacks because a callback may schedule more work;
	# newly scheduled work starts on the next authored tick in stable FIFO order.
	var pending := _audit_delayed_skill_callbacks
	_audit_delayed_skill_callbacks = []
	for item in pending:
		var remaining := maxf(0.0, float(item.get("remaining", 0.0)) - delta)
		var callback: Callable = item.get("callback", Callable())
		if remaining > 0.000001:
			item["remaining"] = remaining
			_audit_delayed_skill_callbacks.append(item)
		elif _active_skill_can_continue() and callback.is_valid():
			callback.call()

func _active_skill_can_continue() -> bool:
	return is_inside_tree() and not battle_finished and has_node("EnemyLayer") and has_node("ProjectileLayer")

func _active_skill_cast_intro(title: String, color: Color, sfx_id: String) -> void:
	AudioManager.play_sfx(sfx_id, -2.0, 0.02)
	_show_wave_toast(title, color)
	_show_screen_flash(Color(color.r, color.g, color.b, 0.08), 0.16)
	_active_skill_screen_shake(5.5, 0.12)
	var cast_origin := _weapon_fire_origin()
	_spawn_character_theme_cast_signature(cast_origin, color)
	if sfx_id.begins_with("sig_"):
		if character_active_id != "":
			_spawn_vfx_sequence("vfx_active_%s" % character_active_id, cast_origin + Vector2(0, -74), 1.2, Color(color.r, color.g, color.b, 0.92), 0.95, randf_range(-0.06, 0.06), 1.08, Vector2(0, -8), randf_range(-0.12, 0.12), true)
		return
	var sequence_id := "vfx_levelup_glow"
	match sfx_id:
		"muzzle_fire", "sig_blaze_meltdown":
			sequence_id = "vfx_muzzle_fire"
		"muzzle_ice", "sig_frost_glacier":
			sequence_id = "vfx_muzzle_ice"
		"muzzle_lightning", "sig_volt_storm":
			sequence_id = "vfx_muzzle_lightning"
		"sig_vanguard_railvolley":
			sequence_id = "vfx_muzzle_physical"
		_:
			sequence_id = "vfx_levelup_glow"
	_spawn_vfx_sequence(sequence_id, cast_origin + Vector2(0, -58), 0.92, Color(color.r, color.g, color.b, 0.82), 1.28, randf_range(-0.16, 0.16), 1.12, Vector2(0, -16), randf_range(-0.32, 0.32), true)
	if character_active_id != "":
		_spawn_vfx_sequence("vfx_active_%s" % character_active_id, cast_origin + Vector2(0, -74), 1.2, Color(color.r, color.g, color.b, 0.92), 0.95, randf_range(-0.1, 0.1), 1.08, Vector2(0, -8), randf_range(-0.16, 0.16), true)

func _active_skill_finish_flash(color: Color, duration: float) -> void:
	_show_screen_flash(color, duration)
	_active_skill_screen_shake(6.0, 0.12)

func _active_skill_screen_shake(amount: float, duration: float) -> void:
	if screen_shake_node != null:
		screen_shake_node.shake(amount, duration)

func _active_skill_apply_hit(target: Node, amount: float, element: String, status_scale := 1.0) -> void:
	if target == null or not is_instance_valid(target) or not target is Node2D:
		return
	var target_position := (target as Node2D).global_position
	if target.has_method("play_special"):
		target.play_special(0.28)
	_spawn_element_impact_vfx(target, target_position, element)
	if target.has_method("amplify_character_status") and element != "physical":
		var bonus_key := "slow_bonus" if element == "ice" else "status_bonus"
		target.amplify_character_status(element, amount * status_scale, _growth_rank(character_level), _affinity_float(bonus_key))
	if target.has_method("take_damage"):
		target.take_damage(amount, element)

func _vanguard_railvolley_hit(volley_index: int, volley_count: int, damage: float, min_hit_damage := 0.0) -> void:
	if not _active_skill_can_continue():
		return
	var origin := _weapon_fire_origin()
	var direction := _weapon_fire_direction(Vector2.UP)
	var color := Color(1.0, 0.88, 0.42, 0.74)
	_spawn_vfx_sequence("vfx_muzzle_physical", origin + direction.normalized() * 34.0, 0.58, Color(1.0, 0.88, 0.38, 0.78), 1.55, direction.angle(), 1.05, direction.normalized() * 26.0, 0.0, true)
	if volley_index % 2 == 0:
		AudioManager.play_sfx("shot_autocannon", -10.0, 0.02)
	var target_count := _vanguard_railvolley_target_count(character_data.get("active_skill", {}))
	var targets := _active_target_candidates(target_count)
	if targets.is_empty():
		var points := _active_skill_fallback_chain_points(target_count)
		for i in range(points.size()):
			var point := points[i] + Vector2(randf_range(-28.0, 28.0), randf_range(-32.0, 22.0))
			_spawn_vfx_sequence("vfx_hit_physical", point, 0.46, Color(1.0, 0.88, 0.38, 0.72), 1.3, randf_range(-0.4, 0.4), 1.12, Vector2(0, -14), randf_range(-0.35, 0.35))
		return
	for i in range(targets.size()):
		var target := targets[(volley_index + i) % targets.size()]
		if target == null or not is_instance_valid(target):
			continue
		var target_position := target.global_position + Vector2(randf_range(-18.0, 18.0), randf_range(-64.0, -24.0))
		_spawn_vfx_sequence("vfx_hit_physical", target_position, 0.52, Color(1.0, 0.88, 0.36, 0.82), 1.35, randf_range(-0.45, 0.45), 1.16, Vector2(0, -18), randf_range(-0.45, 0.45))
		if volley_index == volley_count - 1:
			_spawn_vfx_sequence("vfx_crit", target_position + Vector2(0, -8), 0.46, Color(1.0, 0.92, 0.38, 0.64), 1.15, randf_range(-0.35, 0.35), 1.12, Vector2(0, -16), randf_range(-0.35, 0.35))
		var hit_damage := damage * (0.82 if targets.size() > 1 else 1.06)
		_active_skill_apply_hit(target, maxf(hit_damage, min_hit_damage), "physical", 0.0)
	_active_skill_screen_shake(3.2 + float(volley_index % 3), 0.08)
	if volley_index == volley_count - 1:
		_show_screen_flash(Color(1.0, 0.86, 0.38, 0.08), 0.18)

func _blaze_meltdown_pulse(origin: Vector2, radius: float, damage: float, pulse_index: int, battlefield_coverage := false) -> void:
	if not _active_skill_can_continue():
		return
	var weights := [0.18, 0.22, 0.26, 0.3, 0.24, 0.2, 0.16]
	# Keep the original target-centred geometry as the per-target damage ruler.
	# Battlefield coverage changes who is eligible, not how hard one enemy is hit;
	# this prevents a crowd-control fix from silently buffing single-Boss damage.
	var reference_origin := _blaze_meltdown_reference_origin(origin, radius, pulse_index)
	var visual_origin := _blaze_meltdown_battlefield_visual_origin(pulse_index) if battlefield_coverage else reference_origin
	var local_radius := radius * (0.48 + 0.12 * float(pulse_index))
	var reference_distance := reference_origin.distance_to(origin)
	var reference_falloff := 1.0 - clampf(reference_distance / maxf(local_radius, 0.01), 0.0, 1.0)
	var pulse_factor := 0.0
	if reference_distance <= local_radius:
		pulse_factor = weights[mini(pulse_index, weights.size() - 1)] * (0.58 + reference_falloff * 0.42)
	AudioManager.play_sfx("skill_incendiary", -9.0, randf_range(-0.03, 0.04))
	_spawn_vfx_sequence("vfx_explosion_fire", visual_origin + Vector2(0, -44), 0.9 + 0.18 * float(pulse_index), Color(1.0, 0.42, 0.12, 0.9), 1.0, randf_range(-0.22, 0.22), 1.18, Vector2(0, -20), randf_range(-0.3, 0.3), true)
	for spark_index in range(3):
		var angle := TAU * (float(spark_index) / 3.0) + float(pulse_index) * 0.42
		var burst_pos := visual_origin + Vector2(cos(angle), sin(angle)) * minf(local_radius, 310.0) * randf_range(0.22, 0.48) + Vector2(0, -38)
		_spawn_vfx_sequence("vfx_hit_fire", burst_pos, 0.56 + 0.08 * float(pulse_index), Color(1.0, 0.48, 0.16, 0.72), 1.2, randf_range(-0.35, 0.35), 1.12, Vector2(0, -16), randf_range(-0.4, 0.4))
	for enemy in $EnemyLayer.get_children():
		if not is_instance_valid(enemy) or not enemy is Node2D or not enemy.has_method("take_damage"):
			continue
		var hit_factor := pulse_factor
		if not battlefield_coverage:
			var dist: float = (enemy as Node2D).global_position.distance_to(reference_origin)
			if dist > local_radius:
				continue
			var falloff := 1.0 - clampf(dist / local_radius, 0.0, 1.0)
			hit_factor = weights[mini(pulse_index, weights.size() - 1)] * (0.58 + falloff * 0.42)
		_active_skill_apply_hit(enemy, damage * hit_factor, "fire", _active_skill_status_scale(character_data.get("active_skill", {})))
	_active_skill_screen_shake(5.0 + float(pulse_index) * 1.8, 0.12)
	if pulse_index == 3:
		_show_screen_flash(Color(1.0, 0.38, 0.12, 0.12), 0.2)

func _blaze_meltdown_reference_origin(origin: Vector2, radius: float, pulse_index: int) -> Vector2:
	var offsets := [
		Vector2.ZERO,
		Vector2(-radius * 0.24, -70.0),
		Vector2(radius * 0.26, 24.0),
		Vector2(0.0, -128.0),
	]
	if pulse_index < offsets.size():
		return origin + offsets[pulse_index]
	var angle := TAU * float(pulse_index - offsets.size()) / 3.0 + 0.35
	return origin + Vector2(cos(angle), sin(angle)) * radius * 0.34 + Vector2(0, -62)

func _blaze_meltdown_battlefield_visual_origin(pulse_index: int) -> Vector2:
	# The first four authored pulses already sweep lower-centre, left, right and
	# upper-centre. Later character/signature growth fills the remaining lanes.
	var points := [
		Vector2(540, 1120.0 + bottom_dock_shift * 0.35),
		Vector2(245, 820.0 + bottom_dock_shift * 0.2),
		Vector2(835, 760.0 + bottom_dock_shift * 0.2),
		Vector2(540, 430.0),
		Vector2(220, 360.0),
		Vector2(860, 340.0),
		Vector2(230, 1280.0 + bottom_dock_shift * 0.45),
		Vector2(850, 1260.0 + bottom_dock_shift * 0.45),
		Vector2(540, 850.0 + bottom_dock_shift * 0.25),
	]
	return points[mini(pulse_index, points.size() - 1)]

func _frost_glacier_wave(wave_y: float, tick_damage: float, wave_index: int) -> void:
	if not _active_skill_can_continue():
		return
	var center := Vector2(540, wave_y)
	var radius := 390.0 + float(wave_index) * 48.0
	AudioManager.play_sfx("skill_cryo", -9.5, randf_range(-0.03, 0.03))
	for i in range(5):
		var x := lerpf(210.0, 870.0, float(i) / 4.0) + randf_range(-18.0, 18.0)
		var pos := Vector2(x, wave_y + randf_range(-20.0, 18.0))
		_spawn_vfx_sequence("vfx_freeze", pos, 0.78 + 0.12 * float(wave_index), Color(0.6, 0.94, 1.0, 0.54), 1.05, randf_range(-0.18, 0.18), 1.08, Vector2(0, -12), randf_range(-0.2, 0.2), i == 2)
	_spawn_vfx_sequence("vfx_hit_ice", center + Vector2(0, -34), 0.9 + 0.12 * float(wave_index), Color(0.62, 0.95, 1.0, 0.72), 1.2, 0.0, 1.12, Vector2(0, -14), 0.0, true)
	for enemy in $EnemyLayer.get_children():
		if not is_instance_valid(enemy) or not enemy is Node2D or not enemy.has_method("take_damage"):
			continue
		var enemy_pos := (enemy as Node2D).global_position
		var field_distance := absf(enemy_pos.x - center.x) * 0.58 + absf(enemy_pos.y - center.y)
		if field_distance > radius:
			continue
		_apply_frost_glacier_status(enemy, tick_damage, 1.15)
		_active_skill_apply_hit(enemy, tick_damage * (0.9 + float(wave_index) * 0.08), "ice")
	_active_skill_screen_shake(3.2 + float(wave_index), 0.09)
	if wave_index == 3:
		_show_screen_flash(Color(0.5, 0.9, 1.0, 0.1), 0.18)

func _volt_storm_strike(strike_index: int, max_targets: int, damage: float) -> void:
	if not _active_skill_can_continue():
		return
	var start := _weapon_fire_origin()
	var hit_position := _active_skill_fallback_point(0.38)
	var target: Node2D = null
	var targets := _active_target_candidates(max_targets)
	if targets.is_empty():
		var points := _active_skill_fallback_chain_points(maxi(3, mini(max_targets, 5)))
		hit_position = points[strike_index % points.size()]
		if strike_index > 0:
			start = points[(strike_index - 1) % points.size()]
	else:
		target = targets[strike_index % targets.size()]
		if target != null and is_instance_valid(target):
			hit_position = target.global_position
		if strike_index > 0 and targets.size() > 1:
			var previous := targets[(strike_index - 1) % targets.size()]
			if previous != null and is_instance_valid(previous):
				start = previous.global_position
	AudioManager.play_sfx("skill_tesla", -9.0, randf_range(-0.025, 0.035))
	var strike_angle := (hit_position - start).angle()
	_spawn_vfx_sequence("vfx_chain_lightning", hit_position + Vector2(0, -54), 0.86, Color(0.72, 0.96, 1.0, 0.96), 1.55, strike_angle + randf_range(-0.28, 0.28), 1.08, Vector2(0, -20), randf_range(-0.5, 0.5), true)
	_spawn_vfx_sequence("vfx_hit_lightning", hit_position + Vector2(randf_range(-12.0, 12.0), -42.0), 0.7, Color(0.78, 0.98, 1.0, 0.9), 1.35, randf_range(-0.35, 0.35), 1.16, Vector2(0, -18), randf_range(-0.45, 0.45))
	if target != null and is_instance_valid(target):
		_active_skill_apply_hit(target, damage * 0.62, "lightning")
	_active_skill_screen_shake(4.2, 0.08)

func _refresh_character_fire_rate_buff() -> void:
	if turret == null:
		return
	var next_mult := 1.0
	if sig_vanguard_barrage_timer > 0.0:
		var active: Dictionary = character_data.get("active_skill", {})
		if fire_rate_profile_id == FireRateProfiles.DEFAULT_PROFILE_ID:
			next_mult *= _vanguard_railvolley_fire_rate_mult(active)
		else:
			next_mult *= FireRateProfiles.barrage_multiplier(
				_fire_rate_economy(),
				fire_rate_profile_id,
				active,
				character_level,
				_growth_rank(character_level),
				_sig_skill_level(),
			)
	if sig_vanguard_overload_timer > 0.0:
		next_mult *= 1.5 if fire_rate_profile_id == FireRateProfiles.DEFAULT_PROFILE_ID else FireRateProfiles.overload_multiplier(_fire_rate_economy(), fire_rate_profile_id)
	if absf(next_mult - character_fire_rate_mult) <= 0.001:
		return
	if fire_rate_profile_id == FireRateProfiles.DEFAULT_PROFILE_ID:
		turret.fire_rate *= next_mult / maxf(character_fire_rate_mult, 0.001)
	character_fire_rate_mult = next_mult
	if fire_rate_profile_id != FireRateProfiles.DEFAULT_PROFILE_ID:
		_recompute_profiled_fire_rate()

func _update_character_skill_button() -> void:
	if not has_node("Hud/CharacterSkillButton"):
		return
	_ensure_character_skill_icon_nodes()
	var button: BaseButton = $Hud/CharacterSkillButton
	button.visible = character_active_id != ""
	if character_active_id == "":
		return
	var info: Dictionary = CharacterSkillText.signature_info(character_active_id)
	var label: Label = $Hud/CharacterSkillButton/Label
	var fill_texture := button.get_node_or_null("CooldownTexture") as TextureRect
	var interaction_blocked := card_offer_active or paused
	var ready := character_active_cd <= 0.0 and not interaction_blocked
	# Keep the cooling-down button interactive: a tap during cooldown opens
	# the description. Only modal/paused combat blocks interaction entirely.
	button.disabled = interaction_blocked
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not interaction_blocked else Control.CURSOR_ARROW
	button.tooltip_text = "%s\n%s" % [
		LocalizationManager.text(str(info.get("name", "角色技能"))),
		LocalizationManager.text(str(info.get("desc", ""))),
	]
	var accent := _character_skill_accent()
	button.add_theme_stylebox_override("normal", _character_skill_style(ready, accent, false))
	button.add_theme_stylebox_override("hover", _character_skill_style(ready, accent, true))
	button.add_theme_stylebox_override("pressed", _character_skill_style(ready, accent, true, true))
	button.add_theme_stylebox_override("disabled", _character_skill_style(false, accent, false))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.modulate = Color.WHITE if ready else Color(0.72, 0.78, 0.84, 0.92)
	label.visible = false
	var frame := button.get_node_or_null("IconFrame") as PanelContainer
	if frame != null:
		frame.add_theme_stylebox_override("panel", _character_skill_icon_style(accent, ready))
	var icon := button.get_node_or_null("IconFrame/SkillIcon") as TextureRect
	var icon_path := _character_active_icon_path()
	if icon != null:
		if icon_path != "" and ResourceLoader.exists(icon_path):
			if icon.texture == null or icon.texture.resource_path != icon_path:
				icon.texture = load(icon_path)
		icon.modulate = Color.WHITE if ready else Color(0.78, 0.84, 0.9, 0.78)
	var ratio := clampf(character_active_cd / maxf(character_active_cd_max, 0.1), 0.0, 1.0)
	if fill_texture != null:
		fill_texture.visible = ratio > 0.04
		fill_texture.position = Vector2(12.0, 12.0)
		fill_texture.size = Vector2(maxf(button.size.x - 24.0, 1.0), maxf(button.size.y - 24.0, 1.0))
		fill_texture.modulate = Color(0.42, 0.55, 0.62, lerpf(0.0, 0.46, ratio))
	var cd_label := button.get_node_or_null("CooldownLabel") as Label
	if cd_label != null:
		cd_label.visible = character_active_cd > 0.0
		cd_label.text = "%d" % int(ceil(character_active_cd))
	_update_character_skill_orbit(button, ready, accent)

func _update_character_skill_orbit(button: Control, ready: bool, accent: Color) -> void:
	var orbit := button.get_node_or_null("ReadyOrbit") as Control
	if orbit == null:
		return
	orbit.visible = ready
	if not ready:
		return
	var count := orbit.get_child_count()
	if count <= 0:
		return
	var center := button.size * 0.5
	if center.x <= 0.0 or center.y <= 0.0:
		center = Vector2(52, 52)
	var radius := maxf(34.0, minf(button.size.x, button.size.y) * 0.48)
	var t := Time.get_ticks_msec() / 1000.0
	var pulse_cursor := fposmod(t * 6.0, float(count))
	for i in range(count):
		var dot := orbit.get_child(i) as PanelContainer
		if dot == null:
			continue
		var angle := -PI * 0.5 + t * 2.45 + TAU * float(i) / float(count)
		var index_distance := absf(float(i) - pulse_cursor)
		index_distance = minf(index_distance, float(count) - index_distance)
		var pulse := clampf(1.0 - index_distance / 2.0, 0.0, 1.0)
		var dot_size := 7.0 + 5.0 * pulse
		dot.size = Vector2(dot_size, dot_size)
		dot.position = center + Vector2(cos(angle), sin(angle)) * radius - dot.size * 0.5
		dot.modulate = Color(1, 1, 1, 0.48 + 0.52 * pulse)
		dot.add_theme_stylebox_override("panel", _character_skill_dot_style(accent, pulse))

# Visual feedback for "you pressed the button but there's nothing to hit".
# Wave intermissions make this state reachable: the previous wave is
# dead, the next wave hasn't spawned, and the player naturally tries
# the active skill while looking at the bottom-right button. Before
# this, the only feedback was a 1.27s toast at the top of the screen
# that was easy to miss — the button just felt dead. Now a red wash
# flashes *on the button itself* so the press reads as acknowledged.
func _flash_character_skill_button_unavailable() -> void:
	if not has_node("Hud/CharacterSkillButton/UnavailableOverlay"):
		return
	var overlay := $Hud/CharacterSkillButton/UnavailableOverlay as CanvasItem
	overlay.modulate = Color(1, 0.34, 0.28, 0.0)
	overlay.visible = true
	var tween := overlay.create_tween()
	tween.tween_property(overlay, "modulate", Color(1, 0.34, 0.28, 0.55), 0.08)
	tween.tween_property(overlay, "modulate", Color(1, 0.34, 0.28, 0.0), 0.55)
	tween.tween_callback(func() -> void:
		if is_instance_valid(overlay):
			overlay.visible = false
	)

func _character_active_damage(element: String, mult: float) -> float:
	var active: Dictionary = character_data.get("active_skill", {})
	var basis := str(active.get("scaling_basis", "weapon"))
	var base_damage := _current_primary_shot_damage(element, false) if basis == "weapon" else _character_active_character_damage(element)
	var damage := base_damage * mult * _character_active_power_scale(active)
	return damage

func _character_active_character_damage(element: String) -> float:
	var active: Dictionary = character_data.get("active_skill", {})
	var damage := 28.0 * _player_shot_damage_multiplier()
	damage *= float(character_data.get("base_atk", 100)) / 100.0
	damage *= 1.0 + float(character_data.get("atk_growth", 0.08)) * 0.52 * float(max(character_level - 1, 0))
	# Character-basis skills stay independent of the equipped weapon's raw
	# coefficient, cadence and turret modifier, but can opt into part of the
	# permanent weapon-level axis. This keeps late-game signature skills from
	# becoming negligible without double-dipping the weapon's identity.
	var weapon_level_inherit := clampf(float(active.get("weapon_level_inherit", 0.0)), 0.0, 1.0)
	if weapon_level_inherit > 0.0:
		damage *= lerpf(1.0, SaveManager.get_weapon_damage_multiplier(weapon_id), weapon_level_inherit)
	damage *= _chip_multiplier("damage_mult")
	if element != "physical":
		damage *= _chip_multiplier("element_damage_mult")
	damage *= skills.damage_multiplier()
	damage *= _character_bullet_damage_multiplier(element)
	if element == primary_weakness:
		damage *= 1.15
	return damage

func _current_primary_shot_damage(element_override := "", include_barrage_bonus := true) -> float:
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var element := element_override
	if element == "":
		element = skills.projectile_element(str(weapon.get("element", "physical")), weapon_id)
	var damage := 28.0 * float(weapon.get("base_atk_coef", 1.0)) * _player_shot_damage_multiplier()
	damage *= float(turret.damage_mult)
	damage *= skills.damage_multiplier()
	damage *= _character_bullet_damage_multiplier(element)
	if include_barrage_bonus and sig_vanguard_barrage_timer > 0.0:
		damage *= 1.08
	if element == primary_weakness:
		damage *= 1.15
	return damage

func _vanguard_railvolley_damage(primary_damage := -1.0) -> float:
	if primary_damage <= 0.0:
		primary_damage = _current_primary_shot_damage("physical")
	var active: Dictionary = character_data.get("active_skill", {})
	var mult := float(active.get("damage_mult", 1.25)) * _character_active_power_scale(active)
	return primary_damage * maxf(mult, 1.0)

func _character_active_power_scale(active: Dictionary) -> float:
	var level_delta := float(maxi(character_level - 1, 0))
	var rank := float(_growth_rank(character_level))
	var level_growth := float(active.get("level_damage_growth", 0.0))
	var rank_bonus := float(active.get("rank_damage_bonus", 0.0))
	var sig_level_bonus := float(_sig_skill_level()) * float(active.get("sig_level_damage_bonus", 0.1))
	return maxf(1.0, 1.0 + level_growth * level_delta + rank_bonus * rank + sig_level_bonus)

func _sig_skill_level() -> int:
	return clampi(SaveManager.get_sig_skill_level(character_id), 0, SaveManager.SIG_SKILL_MAX_LEVEL)

func _sig_level_steps(active: Dictionary, key: String) -> int:
	var every := maxi(1, int(active.get(key, 999)))
	return floori(float(_sig_skill_level()) / float(every))

func _sig_level_threshold_count(active: Dictionary, key: String) -> int:
	var thresholds_var: Variant = active.get(key, [])
	if not thresholds_var is Array:
		return 0
	var count := 0
	for threshold in thresholds_var:
		if _sig_skill_level() >= int(threshold):
			count += 1
	return count

func _active_skill_cooldown(active: Dictionary) -> float:
	var base := float(active.get("cooldown", 16.0))
	var reduction := clampf(float(active.get("sig_level_cooldown_reduction", 0.0)) * float(_sig_skill_level()), 0.0, 0.35)
	return maxf(4.0, base * (1.0 - reduction))

func _active_skill_status_scale(active: Dictionary) -> float:
	return 1.0 + float(active.get("sig_level_status_bonus", 0.0)) * float(_sig_skill_level())

func _active_skill_duration(active: Dictionary, fallback: float) -> float:
	var base := float(active.get("duration", fallback))
	var rank_bonus := float(active.get("rank_duration_bonus", 0.0)) * float(_growth_rank(character_level))
	var level_bonus := float(active.get("level_duration_growth", 0.0)) * float(maxi(character_level - 1, 0))
	var sig_bonus := float(active.get("sig_level_duration_bonus", 0.0)) * float(_sig_skill_level())
	return maxf(fallback, base + rank_bonus + level_bonus + sig_bonus)

func _vanguard_railvolley_count(active: Dictionary) -> int:
	var base := int(active.get("base_volleys", 5))
	var rank_bonus := int(active.get("rank_extra_volleys", 0)) * _growth_rank(character_level)
	var max_extra := int(active.get("max_extra_volleys", rank_bonus))
	var sig_bonus := _sig_level_steps(active, "sig_level_extra_volley_every")
	return maxi(base + mini(rank_bonus, max_extra) + sig_bonus, base)

func _vanguard_railvolley_target_count(active: Dictionary) -> int:
	return 3 + _sig_level_steps(active, "sig_level_extra_target_every")

func _vanguard_railvolley_fire_rate_mult(active: Dictionary) -> float:
	var base := float(active.get("barrage_fire_rate_mult", 1.25))
	var rank_bonus := float(active.get("rank_fire_rate_bonus", 0.05)) * float(_growth_rank(character_level))
	var level_bonus := float(active.get("level_fire_rate_growth", 0.0)) * float(maxi(character_level - 1, 0))
	return maxf(1.0, base + rank_bonus + level_bonus)

func _blaze_meltdown_radius(active: Dictionary) -> float:
	var base := float(active.get("radius", 260.0))
	var level_bonus := base * float(active.get("level_radius_growth", 0.0)) * float(maxi(character_level - 1, 0))
	var rank_bonus := float(active.get("rank_radius_bonus", 24.0)) * float(_growth_rank(character_level))
	var sig_bonus := base * float(active.get("sig_level_radius_bonus", 0.0)) * float(_sig_skill_level())
	return maxf(base, base + level_bonus + rank_bonus + sig_bonus)

func _blaze_meltdown_uses_battlefield(active: Dictionary) -> bool:
	return str(active.get("coverage_mode", "local")) == "battlefield"

func _blaze_meltdown_pulse_count(active: Dictionary) -> int:
	var base := int(active.get("base_pulses", 4))
	var rank_bonus := int(active.get("rank_extra_pulses", 0)) * _growth_rank(character_level)
	var sig_bonus := _sig_level_threshold_count(active, "sig_level_extra_pulse_levels")
	return clampi(base + rank_bonus + sig_bonus, base, 9)

func _frost_glacier_duration(active: Dictionary) -> float:
	return _active_skill_duration(active, FROST_GLACIER_MIN_DURATION)

func _frost_glacier_field_y(_active: Dictionary) -> float:
	return 120.0

func _frost_glacier_wave_count(active: Dictionary) -> int:
	var base := int(active.get("base_waves", 4))
	var rank_bonus := int(active.get("rank_extra_waves", 0)) * _growth_rank(character_level)
	var sig_bonus := _sig_level_threshold_count(active, "sig_level_extra_wave_levels")
	return clampi(base + rank_bonus + sig_bonus, base, 9)

func _frost_glacier_slow_bonus(active: Dictionary) -> float:
	var level_bonus := float(active.get("level_slow_bonus_growth", 0.0)) * float(maxi(character_level - 1, 0))
	var rank_bonus := float(active.get("rank_slow_bonus", 0.0)) * float(_growth_rank(character_level))
	return _affinity_float("slow_bonus") + level_bonus + rank_bonus

func _frost_glacier_speed_factor(active: Dictionary, is_boss: bool) -> float:
	var base := FROST_GLACIER_BOSS_SPEED if is_boss else FROST_GLACIER_NORMAL_SPEED
	var rank_bonus := float(active.get("rank_slow_bonus", 0.0)) * float(_growth_rank(character_level)) * 0.35
	var level_bonus := float(active.get("level_slow_bonus_growth", 0.0)) * float(maxi(character_level - 1, 0)) * 0.45
	var sig_bonus := float(active.get("sig_level_slow_factor_bonus", 0.0)) * float(_sig_skill_level())
	var floor_value := 0.52 if is_boss else 0.28
	return clampf(base - rank_bonus - level_bonus - sig_bonus, floor_value, base)

func _volt_storm_max_targets(active: Dictionary) -> int:
	var base := int(active.get("max_targets", 6))
	var rank_bonus := int(active.get("rank_target_bonus", 0)) * _growth_rank(character_level)
	var sig_bonus := _sig_level_steps(active, "sig_level_extra_target_every")
	return maxi(base + rank_bonus + sig_bonus, base)

func _volt_storm_strike_count(active: Dictionary, max_targets: int) -> int:
	var rank_bonus := int(active.get("rank_extra_strikes", 0)) * _growth_rank(character_level)
	var sig_bonus := _sig_level_steps(active, "sig_level_extra_strike_every")
	return maxi(max_targets + 2 + rank_bonus + sig_bonus, max_targets + 2)

func _player_shot_damage_multiplier() -> float:
	var economy: Dictionary = DataLoader.get_table("economy")
	return float(economy.get("PLAYER_SHOT_DAMAGE_MULT", 1.0))

func _bullet_affinity() -> Dictionary:
	return character_data.get("bullet_affinity", {})

func _affinity_float(key: String, fallback := 0.0) -> float:
	return float(_bullet_affinity().get(key, fallback))

func _is_character_affinity_element(element: String) -> bool:
	return element != "" and element == str(_bullet_affinity().get("element", ""))

func _character_bullet_damage_multiplier(element: String) -> float:
	if not _is_character_affinity_element(element):
		return 1.0
	var rank := _growth_rank(character_level)
	return 1.0 + _affinity_float("damage_bonus") + _affinity_float("rank_damage_bonus") * float(rank)

func _character_pierce_bonus(element: String) -> int:
	if not _is_character_affinity_element(element):
		return 0
	var bonus := int(_bullet_affinity().get("pierce_bonus", 0))
	if _growth_rank(character_level) >= 2:
		bonus += int(_bullet_affinity().get("rank_pierce_bonus", 0))
	return bonus

func _character_splash_bonus(element: String) -> float:
	if not _is_character_affinity_element(element):
		return 0.0
	var rank := _growth_rank(character_level)
	return _affinity_float("splash_bonus") + _affinity_float("rank_splash_bonus") * float(rank)

func _character_chain_bonus_for(element: String) -> int:
	if not _is_character_affinity_element(element):
		return 0
	var bonus := int(_bullet_affinity().get("chain_bonus", 0))
	if _growth_rank(character_level) >= 2:
		bonus += int(_bullet_affinity().get("rank_chain_bonus", 0))
	return bonus

func _resolved_chain_count(element: String, mods: Dictionary, special: Dictionary) -> int:
	return maxi(
		0,
		int(mods.get("chain", 0))
			+ int(special.get("chain", 0))
			+ chain_bonus
			+ _character_chain_bonus_for(element),
	)

func _active_premium_set_id() -> String:
	for table_and_id in [["weapons", weapon_id], ["armors", armor_id], ["chips", chip_id], ["pets", pet_id]]:
		var row := DataLoader.get_row(str(table_and_id[0]), str(table_and_id[1]))
		var set_id := str(row.get("premium_set", ""))
		if set_id != "":
			return set_id
	return ""

func _premium_set_piece_count(set_id := "") -> int:
	var resolved_set_id := set_id if set_id != "" else _active_premium_set_id()
	var set_row := DataLoader.get_row("premium_sets", resolved_set_id)
	if set_row.is_empty():
		return 0
	var count := 0
	for slot in ["weapon", "armor", "chip", "pet"]:
		if SaveManager.get_selected(slot) == str(set_row.get(slot, "")):
			count += 1
	return count

func _character_chain_overflow_damage_multiplier(element: String, chain_count: int) -> float:
	if not _is_character_affinity_element(element):
		return 1.0
	var per_chain := maxf(0.0, _affinity_float("chain_overflow_damage_bonus"))
	if per_chain <= 0.0:
		return 1.0
	var reference := maxi(0, int(_bullet_affinity().get("chain_overflow_reference", 5)))
	return 1.0 + float(maxi(chain_count - reference, 0)) * per_chain

func _character_chain_target_falloff(element: String) -> float:
	if not _is_character_affinity_element(element):
		return 1.0
	return clampf(_affinity_float("chain_target_falloff", 1.0), 0.72, 1.0)

func _character_homing_bonus(element: String) -> float:
	if not _is_character_affinity_element(element):
		return 0.0
	return _affinity_float("homing_bonus")

func _resolve_level_id(payload: Dictionary) -> String:
	var provided := str(payload.get("level_id", ""))
	if provided != "":
		return provided
	if router != null:
		var context: Variant = router.get("run_context")
		if context is Dictionary:
			var active := str(context.get("level_id", ""))
			if active != "":
				return active
	return "level_001"

func _level_ordinal_from_id(source_level_id: String) -> int:
	return maxi(1, int(str(source_level_id).get_slice("_", 1)))

func _apply_endless_template_level(economy: Dictionary) -> void:
	endless_template_level_id = _resolve_endless_template_level_id(economy)
	var template_level := DataLoader.get_row("levels", endless_template_level_id)
	if template_level.is_empty():
		push_warning("Endless template level missing: %s; using entry level %s" % [endless_template_level_id, level_id])
		endless_template_level_id = level_id
		return
	level = template_level.duplicate(true)
	level_ordinal = _level_ordinal_from_id(endless_template_level_id)

func _resolve_endless_template_level_id(economy: Dictionary) -> String:
	var configured := str(economy.get("endless_template_level", "level_025"))
	if configured != "" and not DataLoader.get_row("levels", configured).is_empty():
		return configured
	if not DataLoader.get_row("levels", "level_025").is_empty():
		return "level_025"
	return level_id

func _apply_base_survivability() -> void:
	var hp_mult := float(character_data.get("base_hp", 100)) / 100.0
	hp_mult *= 1.0 + float(character_data.get("hp_growth", 0.06)) * 0.45 * float(max(character_level - 1, 0))
	hp_mult *= float(armor_data.get("hp_mult", 1.0))
	hp_mult *= 1.0 + float(armor_data.get("level_hp_growth", 0.018)) * float(max(armor_level - 1, 0))
	var armor_max_level := maxi(2, int(armor_data.get("max_level", 35)))
	var armor_growth_progress := clampf(float(armor_level - 1) / float(armor_max_level - 1), 0.0, 1.0)
	hp_mult *= 1.0 + float(armor_data.get("endgame_hp_growth_bonus", 0.0)) * pow(armor_growth_progress, maxf(1.0, float(armor_data.get("endgame_growth_curve", 1.0))))
	hp_mult *= _chip_multiplier("base_hp_mult")
	hp_mult *= 1.0 + _pet_stat_value("base_hp_mult")
	# Early/mid campaign keeps a small accessibility cushion. Endgame is a real
	# build check: an underpowered loadout must not gain hidden survivability.
	if loadout_power_ratio >= CLEAR_LINE_CUSHION_MIN_RATIO and loadout_power_ratio < CLEAR_LINE_WARNING_RATIO and level_ordinal < 50:
		hp_mult *= 1.08
	base_hp_max = int(round(float(base_hp_max) * hp_mult))
	base_hp = base_hp_max
	breach_shields = int(armor_data.get("breach_shield", 0))
	skill_barriers_left = 0
	breach_damage_mult = 1.0 - _chip_value("breach_damage_reduction")
	breach_damage_mult *= maxf(0.35, 1.0 - _pet_stat_value("breach_damage_reduction"))
	if str(armor_data.get("resist", "none")) == primary_weakness:
		breach_damage_mult *= 0.88
	gold_mult = _chip_multiplier("gold_mult")
	if pet_data.get("role", "") == "economy":
		gold_mult *= 1.0 + _pet_scaled_value("gold_mult", "level_gold_growth")
	gold_mult *= 1.0 + _pet_stat_value("gold_mult")
	match str(character_data.get("passive", "")):
		"breach_guard":
			# 不再默认给屏障（屏障只来自屏障技能）；改为防线伤害减免，保留防御定位。
			breach_damage_mult *= 0.82
			if _growth_rank(character_level) >= 2:
				breach_damage_mult *= 0.88
		"frost_command":
			slow_strength_bonus = 1.18
			if _growth_rank(character_level) >= 1:
				slow_strength_bonus = 1.28
	slow_strength_bonus *= 1.0 + _pet_stat_value("slow_strength_mult")

func _apply_turret_modifiers() -> void:
	var attack_mult := float(character_data.get("base_atk", 100)) / 100.0
	attack_mult *= 1.0 + float(character_data.get("atk_growth", 0.08)) * 0.45 * float(max(character_level - 1, 0))
	attack_mult *= _chip_multiplier("damage_mult")
	attack_mult *= 1.0 + _pet_stat_value("damage_mult")
	var weapon_element := str(DataLoader.get_row("weapons", weapon_id).get("element", "physical"))
	if weapon_element != "physical":
		attack_mult *= _chip_multiplier("element_damage_mult")
	if weapon_element != "physical" or str(pet_data.get("element", "")) == weapon_element:
		attack_mult *= 1.0 + _pet_stat_value("element_damage_mult")
	turret.damage_mult *= attack_mult
	if fire_rate_profile_id == FireRateProfiles.DEFAULT_PROFILE_ID:
		# Production/control intentionally retains the exact pre-profile
		# multiplication expression and operation order.
		turret.fire_rate *= float(character_data.get("fire_rate_mod", 1.0)) * _chip_multiplier("fire_rate_mult") * (1.0 + 0.01 * float(max(chip_level - 1, 0))) * (1.0 + _pet_stat_value("fire_rate_mult"))
		fire_rate_control_rate = turret.fire_rate
	else:
		_recompute_profiled_fire_rate()
	turret.turn_speed *= float(character_data.get("aim_turn_speed", 1.0))
	crit_rate = float(character_data.get("crit_rate_base", 0.0)) + _chip_value("crit_rate") + _pet_stat_value("crit_rate")
	pierce_bonus = int(round(_chip_value("pierce_bonus"))) + int(round(_pet_stat_value("pierce_bonus")))
	element_damage_bonus = 1.0
	chain_bonus = int(round(_pet_stat_value("chain_bonus")))

func _fire_rate_economy() -> Dictionary:
	return DataLoader.get_table("economy")

func _fire_rate_for_profile(profile_id: String) -> float:
	var economy := _fire_rate_economy()
	var fire_rate := fire_rate_weapon_base
	fire_rate *= float(character_data.get("fire_rate_mod", 1.0))
	var chip_intrinsic := _chip_value("fire_rate_mult")
	if profile_id == FireRateProfiles.DEFAULT_PROFILE_ID:
		fire_rate *= (1.0 + chip_intrinsic) * (1.0 + 0.01 * float(max(chip_level - 1, 0)))
		fire_rate *= 1.0 + _pet_stat_value("fire_rate_mult")
		fire_rate *= skills.fire_rate_multiplier()
	else:
		fire_rate *= FireRateProfiles.chip_multiplier(economy, profile_id, chip_intrinsic, chip_level)
		fire_rate *= FireRateProfiles.pet_multiplier(economy, profile_id, _pet_stat_value("fire_rate_mult"))
		fire_rate *= FireRateProfiles.salvo_multiplier(economy, profile_id, skills.level("skill_salvo"), skills.fire_rate_multiplier())
	var active_mult := 1.0
	if sig_vanguard_barrage_timer > 0.0:
		var active: Dictionary = character_data.get("active_skill", {})
		active_mult *= _vanguard_railvolley_fire_rate_mult(active) if profile_id == FireRateProfiles.DEFAULT_PROFILE_ID else FireRateProfiles.barrage_multiplier(
			economy,
			profile_id,
			active,
			character_level,
			_growth_rank(character_level),
			_sig_skill_level(),
		)
	if sig_vanguard_overload_timer > 0.0:
		active_mult *= 1.5 if profile_id == FireRateProfiles.DEFAULT_PROFILE_ID else FireRateProfiles.overload_multiplier(economy, profile_id)
	fire_rate *= active_mult
	return FireRateProfiles.capped_fire_rate(economy, profile_id, fire_rate, fire_rate_authored_weapon_base)

func _recompute_profiled_fire_rate() -> void:
	if turret == null:
		return
	turret.fire_rate = _fire_rate_for_profile(fire_rate_profile_id)
	skill_fire_rate_mult = skills.fire_rate_multiplier() if fire_rate_profile_id == FireRateProfiles.DEFAULT_PROFILE_ID else FireRateProfiles.salvo_multiplier(
		_fire_rate_economy(), fire_rate_profile_id, skills.level("skill_salvo"), skills.fire_rate_multiplier()
	)
	fire_rate_control_rate = _fire_rate_for_profile(FireRateProfiles.DEFAULT_PROFILE_ID)

func _fire_rate_shot_damage_compensation() -> float:
	if turret == null or fire_rate_profile_id == FireRateProfiles.DEFAULT_PROFILE_ID:
		return 1.0
	return FireRateProfiles.shot_damage_compensation(
		_fire_rate_economy(), fire_rate_profile_id, _fire_rate_for_profile(FireRateProfiles.DEFAULT_PROFILE_ID), turret.fire_rate
	)

func _weapon_profile_endgame_damage_multiplier(weapon: Dictionary) -> float:
	var profile_bonuses_var: Variant = weapon.get("profile_endgame_damage_growth_bonus", {})
	var profile_bonuses: Dictionary = profile_bonuses_var if profile_bonuses_var is Dictionary else {}
	var growth_bonus := maxf(float(profile_bonuses.get(fire_rate_profile_id, 0.0)), 0.0)
	if growth_bonus <= 0.0:
		return 1.0
	var progress := SaveManager.weapon_endgame_growth_progress_from_row(weapon, weapon_level)
	var curve := maxf(float(weapon.get("endgame_growth_curve", 1.0)), 1.0)
	return 1.0 + growth_bonus * pow(progress, curve)

func _fire_rate_status_normalization() -> float:
	if turret == null or fire_rate_profile_id == FireRateProfiles.DEFAULT_PROFILE_ID:
		return 1.0
	return FireRateProfiles.per_shot_status_normalization(_fire_rate_for_profile(FireRateProfiles.DEFAULT_PROFILE_ID), turret.fire_rate)

func _set_fire_rate_profile(profile_id: String) -> void:
	var ids := FireRateProfiles.profile_ids(_fire_rate_economy())
	if not ids.has(profile_id):
		profile_id = FireRateProfiles.DEFAULT_PROFILE_ID
	fire_rate_profile_id = profile_id
	_recompute_profiled_fire_rate()

func _chip_multiplier(stat: String) -> float:
	return 1.0 + _chip_value(stat)

func _chip_value(stat: String) -> float:
	if chip_data.get("stat", "") == stat:
		var value := float(chip_data.get("value", 0.0))
		if stat == "pierce_bonus":
			return value + float(_growth_rank(chip_level))
		var growth := float(chip_data.get("level_value_growth", 0.035))
		return value * (1.0 + growth * float(max(chip_level - 1, 0)))
	var secondary: Dictionary = chip_data.get("secondary_stats", {})
	if secondary.has(stat):
		var secondary_growth: Dictionary = chip_data.get("secondary_level_growth", {})
		return (
			float(secondary.get(stat, 0.0))
			+ float(secondary_growth.get(stat, 0.0)) * float(max(chip_level - 1, 0))
		)
	return 0.0

func _pet_stat_value(stat: String) -> float:
	if pet_data.is_empty():
		return 0.0
	var base_map: Dictionary = pet_data.get("stat_bonus", {})
	var growth_map: Dictionary = pet_data.get("level_stat_growth", {})
	var base := float(base_map.get(stat, 0.0))
	var growth := float(growth_map.get(stat, 0.0))
	return base + growth * float(max(pet_level - 1, 0))

func _update_lock_indicator() -> void:
	if target_manager.has_lock():
		$LockIndicator.visible = true
		$LockIndicator.global_position = target_manager.locked_enemy.global_position
		if not $LockIndicator.has_meta("pulse_attached"):
			$LockIndicator.set_meta("pulse_attached", true)
			$LockIndicator.scale = Vector2(_lock_indicator_base_scale, _lock_indicator_base_scale)
			_pulse_lock_indicator()
	else:
		$LockIndicator.visible = false

func _update_off_screen_indicators() -> void:
	if off_screen_indicators == null:
		return
	var viewport := Rect2(Vector2(0, 140), Vector2(1080, BREACH_Y))
	off_screen_indicators.refresh(viewport, Vector2.ZERO)

func _pulse_lock_indicator() -> void:
	if _lock_pulse_tween:
		_lock_pulse_tween.kill()
	_lock_pulse_tween = create_tween().set_loops()
	_lock_pulse_tween.tween_property($LockIndicator, "scale", Vector2(_lock_indicator_base_scale * 1.18, _lock_indicator_base_scale * 1.18), 0.35)
	_lock_pulse_tween.tween_property($LockIndicator, "scale", Vector2(_lock_indicator_base_scale, _lock_indicator_base_scale), 0.35)

func _on_target_lock_requested(world_pos: Vector2) -> void:
	var nearest: Node2D
	var nearest_dist := 999999.0
	for enemy in $EnemyLayer.get_children():
		if not is_instance_valid(enemy):
			continue
		var dist: float = enemy.global_position.distance_to(world_pos)
		if dist < nearest_dist and dist <= 180.0:
			nearest = enemy
			nearest_dist = dist
	if nearest:
		target_manager.lock_enemy(nearest)
		AudioManager.play_sfx("lock")
	else:
		target_manager.clear_lock()

func _on_strategy_changed(strategy: String) -> void:
	target_manager.strategy = strategy

func _on_pause_pressed() -> void:
	if card_offer_active:
		return
	_set_battle_paused(not paused, true)

func _set_battle_paused(active: bool, play_sfx := false) -> void:
	if battle_finished and active:
		return
	if card_offer_active and active:
		return
	paused = active
	_refresh_runtime_pause_modes()
	if play_sfx:
		AudioManager.play_sfx("pause" if paused else "resume")
	if paused:
		_set_turret_fire_enabled(false)
		manual_aim_active = false
		manual_aim_until = 0.0
		_hide_skill_hint()
		_hide_wave_toast()
		_refresh_pause_build_summary()
	else:
		_hide_skill_hint()
	$Hud/PauseOverlay.visible = paused
	_set_pause_background_hud_hidden(paused)
	get_tree().paused = paused or card_offer_active
	_update_character_skill_button()

func _set_pause_background_hud_hidden(hidden: bool) -> void:
	var top_bar := get_node_or_null("Hud/TopBar") as CanvasItem
	if top_bar != null:
		top_bar.visible = not hidden
	var pause_button := get_node_or_null("PauseLayer/PauseButton") as CanvasItem
	if pause_button != null:
		pause_button.visible = not hidden
	var speed_button := get_node_or_null("PauseLayer/SpeedButton") as CanvasItem
	if speed_button != null:
		speed_button.visible = not hidden and _is_speed_button_unlocked()
	if boss_hp_bar != null and is_instance_valid(boss_hp_bar):
		if hidden:
			boss_hp_bar.visible = false
		else:
			_update_boss_hp_bar()

func _refresh_pause_build_summary() -> void:
	_rebuild_pause_overlay_content()
	var summary_path := "Hud/PauseOverlay/Panel/BuildSummary"
	if not has_node(summary_path):
		summary_path = "Hud/PauseOverlay/BuildSummary"
	if not has_node(summary_path):
		return
	var label := get_node(summary_path) as Label
	if label == null:
		return
	var lines: Array[String] = []
	lines.append("关卡：%s（建议等级 %d）" % [DataLoader.level_display_name(level_id), int(level.get("recommend_level", 1))])
	var element_label := _element_label(primary_weakness)
	lines.append("本关弱点：%s" % element_label)
	lines.append("角色：%s" % _display_name(character_data, character_id))
	lines.append("武器：%s（等级%d）" % [_display_name(DataLoader.get_row("weapons", weapon_id), weapon_id), weapon_level])
	if character_active_id != "":
		var active_info: Dictionary = CharacterSkillText.signature_info(character_active_id)
		lines.append("角色主动：%s（冷却 %.0fs）" % [str(active_info.get("name", character_active_id)), character_active_cd_max])
	var affinity: Dictionary = _bullet_affinity()
	if not affinity.is_empty():
		lines.append("弹种加成：%s 弹" % _element_name(str(affinity.get("element", "physical"))))
	lines.append("护甲：%s  芯片：%s" % [_display_name(armor_data, armor_id), _display_name(chip_data, chip_id)])
	if pet_id != "":
		lines.append("宝宝：%s" % _display_name(pet_data, pet_id))
	lines.append("")
	lines.append("已带技能：")
	for skill_id in skill_slot_ids:
		var row: Dictionary = DataLoader.get_row("skills", skill_id)
		var lv := skills.level(skill_id) if skills else 0
		lines.append("  • %s  等级%d" % [str(row.get("name", skill_id)), lv])
	if skill_slot_ids.is_empty():
		lines.append("  （暂无 — 局内首张三选一牌出现时自动填入）")
	label.text = "\n".join(lines)

func _rebuild_pause_overlay_content() -> void:
	_setup_pause_overlay_layout()
	var content := get_node_or_null("Hud/PauseOverlay/Panel/PauseContent") as VBoxContainer
	if content == null:
		return
	for child in content.get_children():
		child.free()
	content.add_child(_pause_status_card())
	content.add_child(_pause_loadout_card())
	content.add_child(_pause_skill_card())
	# Container minimum sizes are only authoritative after the dynamic cards are
	# attached. Re-run the frame layout against that measured height so late-game
	# 8-10 skill summaries grow the panel instead of covering the action row.
	_setup_pause_overlay_layout()

func _pause_status_card() -> PanelContainer:
	var card := _pause_section("战场状态", UiKit.GOLD, PAUSE_STATUS_CARD_HEIGHT)
	var body := card.get_child(0) as VBoxContainer
	if SettingsManager.has_fire_rate_lab():
		var header := body.get_child(0) as HBoxContainer
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(spacer)
		var lab_button := Button.new()
		lab_button.name = "FireRateLabButton"
		lab_button.process_mode = Node.PROCESS_MODE_ALWAYS
		lab_button.text = LocalizationManager.text("攻速实验：%s") % SettingsManager.fire_rate_profile_label(fire_rate_profile_id)
		lab_button.pressed.connect(_on_pause_fire_rate_lab)
		header.add_child(lab_button)
		UiKit.apply_armored_button(lab_button, false, Vector2(224, 60), 19, true)
	var grid := GridContainer.new()
	grid.columns = 1 if LocalizationManager.is_english() else 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)
	grid.add_child(_pause_metric("关卡", DataLoader.level_display_name(level_id), UiKit.CYAN))
	grid.add_child(_pause_metric("建议等级", str(int(level.get("recommend_level", 1))), UiKit.GOLD))
	grid.add_child(_pause_metric("本关弱点", _element_name(primary_weakness), UiKit.element_color(primary_weakness)))
	grid.add_child(_pause_metric("防线生命", "%d/%d" % [base_hp, base_hp_max], UiKit.GREEN))
	return card

func _on_pause_fire_rate_lab() -> void:
	var next_profile := SettingsManager.cycle_fire_rate_profile()
	_set_fire_rate_profile(next_profile)
	AudioManager.play_sfx("ui_click")
	_refresh_pause_build_summary()

func _pause_loadout_card() -> PanelContainer:
	var card := _pause_section("出战配置", UiKit.CYAN, PAUSE_LOADOUT_CARD_HEIGHT)
	var body := card.get_child(0) as VBoxContainer
	var grid := GridContainer.new()
	grid.columns = 1 if LocalizationManager.is_english() else 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)
	grid.add_child(_pause_metric("英雄", _display_name(character_data, character_id), UiKit.CYAN))
	grid.add_child(_pause_metric("武器", "%s  等级%d" % [_display_name(DataLoader.get_row("weapons", weapon_id), weapon_id), weapon_level], UiKit.GOLD))
	grid.add_child(_pause_metric("护甲", _display_name(armor_data, armor_id), UiKit.CYAN))
	grid.add_child(_pause_metric("芯片", _display_name(chip_data, chip_id), UiKit.GREEN))
	var pet_text := _display_name(pet_data, pet_id) if pet_id != "" else LocalizationManager.text("未携带")
	grid.add_child(_pause_metric("宝宝", pet_text, UiKit.element_color(str(pet_data.get("element", "physical")))))
	var active_text := "未配置"
	if character_active_id != "":
		var active_info: Dictionary = CharacterSkillText.signature_info(character_active_id)
		active_text = "%s  %.0fs" % [str(active_info.get("name", character_active_id)), character_active_cd_max]
	grid.add_child(_pause_metric("主动", active_text, UiKit.PURPLE))
	return card

func _pause_skill_card() -> PanelContainer:
	var card_height := _pause_skill_card_height()
	var card := _pause_section("已带技能", UiKit.PURPLE, card_height)
	var body := card.get_child(0) as VBoxContainer
	var grid := GridContainer.new()
	grid.columns = _pause_skill_columns()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)
	if skill_slot_ids.is_empty():
		var empty := UiKit.label("暂无技能，局内首次三选一会自动加入。", 20, UiKit.TEXT_MUTED, 2)
		empty.custom_minimum_size = Vector2(780, 74)
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		body.add_child(empty)
		return card
	for skill_id in skill_slot_ids:
		grid.add_child(_pause_skill_chip(skill_id))
	return card

func _pause_skill_row_count() -> int:
	return maxi(1, int(ceil(float(maxi(skill_slot_ids.size(), 1)) / float(_pause_skill_columns()))))

func _pause_skill_columns() -> int:
	return 2 if LocalizationManager.is_english() else 3

func _pause_skill_card_height() -> float:
	var rows := _pause_skill_row_count()
	var row_gaps := float(maxi(rows - 1, 0)) * PAUSE_SKILL_ROW_GAP
	return maxf(198.0, PAUSE_SKILL_CARD_CHROME + float(rows) * PAUSE_SKILL_CHIP_HEIGHT + row_gaps)

func _pause_content_height() -> float:
	var predicted_height := (
		PAUSE_STATUS_CARD_HEIGHT
		+ PAUSE_LOADOUT_CARD_HEIGHT
		+ _pause_skill_card_height()
		+ PAUSE_CONTENT_SECTION_GAP * 2.0
	)
	# Preserve the approved two-row baseline, then let the live container be the
	# source of truth for fonts, locale and theme content margins.
	var measured_height := 0.0
	var content := get_node_or_null("Hud/PauseOverlay/Panel/PauseContent") as VBoxContainer
	if content != null:
		measured_height = content.get_combined_minimum_size().y
	return maxf(790.0, maxf(predicted_height, measured_height))

func _pause_section(title_text: String, accent: Color, min_height: float) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, min_height)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", UiKit.panel_texture_style(12.0))
	var body := VBoxContainer.new()
	body.name = "Body"
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	card.add_child(body)
	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 14)
	body.add_child(header)
	var rail := TextureRect.new()
	rail.texture = load("res://assets/production/sprites/ui/ui_map_accent_strip.png")
	rail.custom_minimum_size = Vector2(18, 34)
	rail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rail.stretch_mode = TextureRect.STRETCH_SCALE
	rail.modulate = accent
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(rail)
	var title := UiKit.label(title_text, 25, Color(0.95, 0.90, 0.76, 1.0), 2)
	title.name = "SectionTitle"
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)
	return card

func _pause_metric(label_text: String, value_text: String, accent: Color) -> PanelContainer:
	var metric := PanelContainer.new()
	metric.custom_minimum_size = Vector2(0, 66)
	metric.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metric.mouse_filter = Control.MOUSE_FILTER_IGNORE
	metric.clip_contents = true
	metric.add_theme_stylebox_override("panel", UiKit.pill_style(accent, Color(0.012, 0.018, 0.026, 0.76)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	metric.add_child(row)
	var english := LocalizationManager.is_english()
	var key := UiKit.label(label_text, 17 if english else 19, Color(0.62, 0.78, 0.82, 1.0), 2)
	key.name = "MetricKey"
	key.custom_minimum_size = Vector2(174 if english else 122, 0)
	key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key.clip_text = true
	key.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(key)
	var value := UiKit.label(value_text, 18 if english else 20, UiKit.TEXT_MAIN, 2)
	value.name = "MetricValue"
	value.custom_minimum_size = Vector2(1, 0)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.clip_text = true
	value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(value)
	return metric

func _pause_skill_chip(skill_id: String) -> PanelContainer:
	var row: Dictionary = DataLoader.get_row("skills", skill_id)
	var accent := UiKit.element_color(str(row.get("element", row.get("ammo_element", "physical"))))
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(274, PAUSE_SKILL_CHIP_HEIGHT)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.clip_contents = true
	chip.add_theme_stylebox_override("panel", UiKit.pill_style(accent, Color(0.012, 0.018, 0.026, 0.82)))
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	chip.add_child(hbox)
	var icon := UiKit.icon(str(row.get("icon", UiKit.element_icon_path("physical"))), Vector2(58, 58))
	icon.name = "SkillIcon"
	hbox.add_child(icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	hbox.add_child(col)
	# Three chips share one phone-width row. English skill names need one logical
	# point less than CJK here (19 px effective vs 20 px) to remain complete
	# without ellipsis; the level line keeps the same hierarchy and touch layout.
	var name_size := 15 if LocalizationManager.is_english() else 17
	var name := UiKit.label(DataLoader.tr_key(row.get("name_key", skill_id)), name_size, UiKit.TEXT_MAIN, 2)
	name.name = "SkillName"
	name.custom_minimum_size = Vector2(0, 24)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.clip_text = true
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(name)
	var level := UiKit.label("Lv%d" % skills.level(skill_id), 15, UiKit.GOLD, 2)
	level.name = "SkillLevel"
	col.add_child(level)
	return chip

func _display_name(row: Dictionary, fallback: String) -> String:
	if row.is_empty():
		return fallback
	var name_key := str(row.get("name_key", ""))
	if name_key != "":
		return DataLoader.tr_key(name_key)
	return str(row.get("name", fallback))

func _apply_variant_modifiers() -> void:
	variant = str(level.get("variant", "normal"))
	variant_gold_mult = 1.0
	variant_xp_mult = 1.0
	match variant:
		"treasure":
			variant_gold_mult = 1.5
		"elite":
			variant_xp_mult = 1.3
		_:
			pass

func _ensure_boss_hp_bar() -> void:
	if boss_hp_bar != null and is_instance_valid(boss_hp_bar):
		return
	boss_hp_bar = Control.new()
	boss_hp_bar.name = "BossHpBar"
	# The global font scale turns the authored 24 px label into a 36 px face
	# with a 6 px outline. The old 28 px box clipped its lower strokes and let
	# the rail cover CJK / Latin descenders. Give the identity line its own
	# full-height band and preserve that band below the safe-area-shifted wave UI.
	# The wave rail moves below the notch / Dynamic Island with TopBar. Anchor
	# the boss band to the shifted rail instead of leaving it at its authored
	# 1920-canvas Y; otherwise tall iPhones merge both labels into one line.
	boss_hp_bar.position = _boss_hp_hud_position()
	boss_hp_bar.size = BOSS_HP_HUD_SIZE
	boss_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_hp_bar.visible = false
	boss_hp_label = UiKit.label("", BOSS_HP_LABEL_FONT_SIZE, Color(1.0, 0.72, 0.46), 4)
	boss_hp_label.name = "Label"
	boss_hp_label.position = Vector2(0, 0)
	boss_hp_label.size = BOSS_HP_LABEL_SIZE
	boss_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_hp_bar.add_child(boss_hp_label)
	boss_armor_track = TextureRect.new()
	boss_armor_track.name = "ArmorTrack"
	boss_armor_track.texture = load("res://assets/production/sprites/ui/ui_boss_hp_bar.png")
	boss_armor_track.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boss_armor_track.stretch_mode = TextureRect.STRETCH_SCALE
	boss_armor_track.position = BOSS_HP_TRACK_POSITION
	boss_armor_track.size = BOSS_HP_TRACK_SIZE
	boss_armor_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_armor_track.visible = false
	boss_hp_bar.add_child(boss_armor_track)
	boss_armor_fill = TextureRect.new()
	boss_armor_fill.name = "ArmorFill"
	boss_armor_fill.texture = load("res://assets/production/sprites/ui/ui_bar_fill_hp.png")
	boss_armor_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boss_armor_fill.stretch_mode = TextureRect.STRETCH_SCALE
	boss_armor_fill.position = BOSS_HP_FILL_POSITION
	boss_armor_fill.size = BOSS_HP_FILL_SIZE
	boss_armor_fill.modulate = Color(0.98, 0.76, 0.22, 1.0)
	boss_armor_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_armor_fill.visible = false
	boss_hp_bar.add_child(boss_armor_fill)
	boss_hp_track = TextureRect.new()
	boss_hp_track.name = "Track"
	boss_hp_track.texture = load("res://assets/production/sprites/ui/ui_boss_hp_bar.png")
	boss_hp_track.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boss_hp_track.stretch_mode = TextureRect.STRETCH_SCALE
	boss_hp_track.position = BOSS_HP_TRACK_POSITION
	boss_hp_track.size = BOSS_HP_TRACK_SIZE
	boss_hp_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_hp_bar.add_child(boss_hp_track)
	boss_hp_fill = TextureRect.new()
	boss_hp_fill.name = "Fill"
	boss_hp_fill.texture = load("res://assets/production/sprites/ui/ui_bar_fill_hp.png")
	boss_hp_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boss_hp_fill.stretch_mode = TextureRect.STRETCH_SCALE
	boss_hp_fill.position = BOSS_HP_FILL_POSITION
	boss_hp_fill.size = BOSS_HP_FILL_SIZE
	boss_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_hp_bar.add_child(boss_hp_fill)
	$Hud.add_child(boss_hp_bar)

func _boss_hp_hud_position() -> Vector2:
	var y := BOSS_HP_HUD_POSITION.y
	var top_bar := get_node_or_null("Hud/TopBar") as Control
	if top_bar != null:
		y = maxf(y, top_bar.offset_bottom + BOSS_HP_HUD_TOP_GAP)
	return Vector2(BOSS_HP_HUD_POSITION.x, y)

func _update_boss_hp_bar() -> void:
	if boss_hp_bar == null or not is_instance_valid(boss_hp_bar):
		return
	if active_boss == null or not is_instance_valid(active_boss) or not active_boss.boss or float(active_boss.hp) <= 0.0:
		_refresh_active_boss()
	if active_boss == null or not is_instance_valid(active_boss):
		boss_hp_bar.visible = false
		return
	var ratio := clampf(float(active_boss.hp) / maxf(float(active_boss.max_hp), 1.0), 0.0, 1.0)
	var armor_max := maxf(float(active_boss.get("armor_hp_max")), 0.0)
	var armor_ratio := clampf(float(active_boss.get("armor_hp")) / armor_max if armor_max > 0.0 else 0.0, 0.0, 1.0)
	var has_armor_layer := armor_max > 0.0
	if paused:
		boss_hp_bar.visible = false
		return
	boss_hp_bar.visible = true
	boss_hp_bar.size.y = BOSS_HP_HUD_SIZE.y if has_armor_layer else 96.0
	boss_hp_track.position = BOSS_HP_STACKED_TRACK_POSITION if has_armor_layer else BOSS_HP_TRACK_POSITION
	boss_hp_fill.position = BOSS_HP_STACKED_FILL_POSITION if has_armor_layer else BOSS_HP_FILL_POSITION
	boss_hp_fill.size.x = BOSS_HP_FILL_SIZE.x * ratio
	boss_armor_track.visible = has_armor_layer
	boss_armor_fill.visible = has_armor_layer
	if has_armor_layer:
		boss_armor_fill.size.x = BOSS_HP_FILL_SIZE.x * armor_ratio
	var boss_name := DataLoader.tr_key(active_boss.data.get("name_key", "")) if active_boss.data is Dictionary else ""
	var boss_count := _living_boss_count()
	var count_suffix := "  x%d" % boss_count if boss_count > 1 else ""
	var weakness := _element_name(str(active_boss.data.get("weakness", "physical"))) if active_boss.data is Dictionary else ""
	var weakness_bonus := int(round((maxf(float(DataLoader.get_table("economy").get("weakness_mult", 1.5)), 1.0) - 1.0) * 100.0))
	var hp_percent_text := _boss_hp_percent_text(ratio)
	var armor_percent_text := _boss_hp_percent_text(armor_ratio)
	if LocalizationManager.is_english():
		boss_hp_label.text = (
			"%s%s · %s +%d%% · %s / %s"
			% [boss_name, count_suffix, weakness, weakness_bonus, armor_percent_text, hp_percent_text]
			if has_armor_layer
			else "%s%s · %s +%d%% · %s" % [boss_name, count_suffix, weakness, weakness_bonus, hp_percent_text]
		)
	else:
		boss_hp_label.text = (
			"%s%s · 弱%s +%d%% · 甲%s / 血%s"
			% [boss_name, count_suffix, weakness, weakness_bonus, armor_percent_text, hp_percent_text]
			if has_armor_layer
			else "%s%s · 弱%s +%d%% · %s" % [boss_name, count_suffix, weakness, weakness_bonus, hp_percent_text]
		)
	# Long English names may shrink within the dedicated identity band, but
	# never wrap, crop, or descend into the HP rail.
	UiKit.fit_label_text(
		boss_hp_label,
		UiKit.scaled_font_size(BOSS_HP_LABEL_FONT_SIZE),
		28,
		12.0,
		4.0
	)
	_refresh_visible_wave_toast_boss_clearance()

func _refresh_visible_wave_toast_boss_clearance() -> void:
	if wave_toast_banner == null or not is_instance_valid(wave_toast_banner) or not wave_toast_banner.visible:
		return
	var target := _wave_toast_target_position()
	# A weakness tip can begin before the boss reference and HP band settle on
	# the following frame. Keep its live position below the now-authoritative
	# band instead of leaving the original tween aimed at the pre-boss anchor.
	if wave_toast_banner.position.y < target.y:
		wave_toast_banner.position.y = target.y

func _boss_hp_percent_text(ratio: float) -> String:
	var clamped := clampf(ratio, 0.0, 1.0)
	if clamped >= 1.0:
		return "100%"
	# Large late-game Boss pools can absorb real damage while an integer label
	# still rounds to 100. Adaptive precision makes the first HP loss observable.
	var percent := minf(clamped * 100.0, 99.9999)
	if percent >= 99.9:
		return "%.4f%%" % percent
	if percent >= 99.0:
		return "%.2f%%" % percent
	return "%.1f%%" % percent

func _living_boss_count() -> int:
	var count := 0
	for candidate in $EnemyLayer.get_children():
		if is_instance_valid(candidate) and bool(candidate.get("boss")) and float(candidate.get("hp")) > 0.0 and not candidate.is_queued_for_deletion():
			count += 1
	return count

func _refresh_active_boss() -> void:
	active_boss = null
	var best_y := -INF
	for candidate in $EnemyLayer.get_children():
		if not is_instance_valid(candidate) or not bool(candidate.get("boss")) or float(candidate.get("hp")) <= 0.0 or candidate.is_queued_for_deletion():
			continue
		if float(candidate.global_position.y) > best_y:
			best_y = float(candidate.global_position.y)
			active_boss = candidate

func _apply_safe_area() -> void:
	# Only shift HUD for insets inside the game window (notch / home indicator).
	# Desktop windowed mode should stay at 0; monitor menu-bar safe area must not
	# push battle HUD into the middle of the screen.
	var insets := _viewport_safe_insets()
	if insets.top <= 0.0 and insets.bottom <= 0.0:
		return
	for path in ["Hud/TopBar", "PauseLayer/PauseButton", "PauseLayer/SpeedButton"]:
		if not has_node(path):
			continue
		var control := get_node(path) as Control
		control.offset_top += insets.top
		control.offset_bottom += insets.top
	for path in ["Hud/BottomBar", "Hud/SkillSlots", "Hud/SkillPanelTitle", "Hud/CharacterSkillButton"]:
		if not has_node(path):
			continue
		var control := get_node(path) as Control
		control.offset_top -= insets.bottom
		control.offset_bottom -= insets.bottom

func _viewport_safe_insets() -> Dictionary:
	var canvas_insets := UiKit.safe_area_canvas_insets(get_viewport())
	return {
		"top": clampf(canvas_insets.y, 0.0, 120.0),
		"bottom": clampf(canvas_insets.w, 0.0, 120.0),
	}

func _apply_runtime_ui_styles() -> void:
	_layout_runtime_hud()
	_ensure_hud_fill_texture(HUD_HP_BAR_PATH, "res://assets/production/sprites/ui/ui_bar_fill_hp.png", 18.0, 16.0)
	_ensure_hud_fill_texture(HUD_WAVE_BAR_PATH, HUD_WAVE_FILL_TEXTURE, 14.0, 18.0)
	_style_xp_bar()
	if has_node("Hud/CardPanel"):
		var card_panel: Panel = $Hud/CardPanel
		card_panel.add_theme_stylebox_override("panel", UiKit.result_panel_texture_style())
		_layout_card_offer_panel()
		UiKit.apply_label($Hud/CardPanel/CardTitle, 34, UiKit.TEXT_MAIN, 4)
		UiKit.apply_armored_texture_button($Hud/CardPanel/RerollButton as TextureButton, true, Vector2(412, 88), true)
		UiKit.apply_armored_texture_button($Hud/CardPanel/SkipButton as TextureButton, false, Vector2(412, 88), true)
		UiKit.apply_label($Hud/CardPanel/RerollButton/RerollLabel, 25, UiKit.TEXT_MAIN, 3)
		UiKit.apply_label($Hud/CardPanel/SkipButton/SkipLabel, 25, UiKit.TEXT_MAIN, 3)
	if has_node("Hud/CardPanel/DetailOverlay/Panel"):
		var detail: Panel = $Hud/CardPanel/DetailOverlay/Panel
		detail.add_theme_stylebox_override("panel", UiKit.result_panel_texture_style())
		_layout_card_detail_overlay()
	if has_node("Hud/PauseOverlay/Panel"):
		var pause_panel: Panel = $Hud/PauseOverlay/Panel
		pause_panel.add_theme_stylebox_override("panel", UiKit.result_panel_texture_style())
		UiKit.apply_label($Hud/PauseOverlay/Panel/Title, 50, UiKit.TEXT_MAIN, 4)
		if has_node("Hud/PauseOverlay/Panel/BuildSummary"):
			UiKit.apply_label($Hud/PauseOverlay/Panel/BuildSummary, 21, Color(0.82, 0.88, 0.88, 1.0), 2)
		_setup_pause_overlay_layout()
	_setup_wave_toast_banner()

func _layout_runtime_hud() -> void:
	_ensure_hp_bar_in_bottom_bar()
	_ensure_speed_button()
	var top_bar := get_node_or_null("Hud/TopBar") as Control
	if top_bar != null:
		top_bar.offset_left = 180.0
		top_bar.offset_top = 18.0
		top_bar.offset_right = -180.0
		top_bar.offset_bottom = 74.0
		top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_layout_status_bar(HUD_WAVE_BAR_PATH, Vector2(0, 0), HUD_WAVE_BAR_SIZE, 14.0, 18.0, 18)
	var bottom_bar := get_node_or_null("Hud/BottomBar") as Control
	if bottom_bar != null:
		bottom_bar.offset_left = 28.0
		bottom_bar.offset_top = 1792.0 + bottom_dock_shift
		bottom_bar.offset_right = -28.0
		bottom_bar.offset_bottom = 1894.0 + bottom_dock_shift
		bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_layout_bottom_resource_bar()
	var skill_slots := get_node_or_null("Hud/SkillSlots") as GridContainer
	if skill_slots != null:
		# 固定锚定设计高度(1920)内的绝对位置,不锚定屏幕真实底部(anchor_bottom=1.0
		# 那种锚法在更高宽比设备上会让这个元素自己漂到真实屏幕底部、和其它还留在
		# 设计高度内的 HUD 元素脱节，比如漂进黑色空白区域)。真正要"用满全屏"是靠
		# 下面这个 +bottom_dock_shift——同一个偏移量同时加到人物、护栏、这整个底部
		# HUD 群组上，大家一起挪到真实屏幕底部，彼此之间的相对位置完全不变。
		skill_slots.anchor_left = 0.0
		skill_slots.anchor_top = 0.0
		skill_slots.anchor_right = 0.0
		skill_slots.anchor_bottom = 0.0
		skill_slots.offset_left = HUD_SKILL_DOCK_LEFT
		skill_slots.offset_top = HUD_SKILL_DOCK_BOTTOM - HUD_SKILL_SLOT_SIZE.y + bottom_dock_shift
		skill_slots.offset_right = HUD_SKILL_DOCK_RIGHT
		skill_slots.offset_bottom = HUD_SKILL_DOCK_BOTTOM + bottom_dock_shift
		skill_slots.columns = HUD_SKILL_DOCK_COLUMNS
		skill_slots.add_theme_constant_override("h_separation", HUD_SKILL_DOCK_GAP)
		skill_slots.add_theme_constant_override("v_separation", HUD_SKILL_DOCK_GAP)
	var active_button := get_node_or_null("Hud/CharacterSkillButton") as Control
	if active_button != null:
		active_button.offset_left = -154.0
		active_button.offset_top = 1688.0 + bottom_dock_shift
		active_button.offset_right = -34.0
		active_button.offset_bottom = 1808.0 + bottom_dock_shift
	var pause_button := get_node_or_null("PauseLayer/PauseButton") as TextureButton
	if pause_button != null:
		pause_button.offset_left = 18.0
		pause_button.offset_top = 18.0
		pause_button.offset_right = 100.0
		pause_button.offset_bottom = 100.0
		pause_button.ignore_texture_size = true
		pause_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		pause_button.modulate = Color(0.92, 0.96, 1.0, 0.94)
	# 镜像暂停按钮，放右上角；这块正好是空的(ObjectivePanel 从 offset_top=100
	# 才开始)，不受 bottom_dock_shift 影响(顶部锚定，和暂停按钮一样)。
	var speed_button := get_node_or_null("PauseLayer/SpeedButton") as Button
	if speed_button != null:
		speed_button.offset_left = 980.0
		speed_button.offset_top = 18.0
		speed_button.offset_right = 1062.0
		speed_button.offset_bottom = 100.0

func _layout_card_offer_panel() -> void:
	var panel := get_node_or_null("Hud/CardPanel") as Panel
	if panel == null:
		return
	var bounds := _card_offer_vertical_bounds()
	var max_panel_height := maxf(0.0, bounds.y - bounds.x)
	var content_height := float(panel.get_meta("card_offer_content_height", 0.0))
	# Wrapped card copy owns the modal height. Tall screens only move the finished
	# modal to the battlefield center; they must not stretch an empty lane between
	# the third card and the primary actions.
	var panel_height := minf(max_panel_height, maxf(CARD_OFFER_PANEL_SIZE.y, content_height))
	panel.size = Vector2(CARD_OFFER_PANEL_SIZE.x, panel_height)
	panel.position = Vector2(CARD_OFFER_PANEL_X, _card_offer_centered_y(panel.size.y))
	var button_y := panel.size.y - CARD_OFFER_ACTION_LANE_HEIGHT
	var title := panel.get_node_or_null("CardTitle") as Label
	if title != null:
		title.position = Vector2(54, 26)
		title.size = Vector2(864, 70)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var cards := panel.get_node_or_null("Cards") as VBoxContainer
	if cards != null:
		cards.position = CARD_OFFER_CARDS_POS
		var measured_cards_height := float(panel.get_meta("card_offer_cards_height", 0.0))
		var cards_lane := maxf(0.0, button_y - CARD_OFFER_CARDS_POS.y - CARD_OFFER_ACTION_GAP)
		cards.size = Vector2(
			CARD_OFFER_CARDS_SIZE.x,
			minf(cards_lane, measured_cards_height) if measured_cards_height > 0.0 else cards_lane
		)
		cards.add_theme_constant_override("separation", CARD_OFFER_CARD_SEPARATION)
		# Actions follow the real bottom of the collapsed card stack, so the quiet
		# lane stays exactly CARD_OFFER_ACTION_GAP instead of inheriting whatever
		# space the panel had left over.
		if measured_cards_height > 0.0:
			button_y = cards.position.y + cards.size.y + CARD_OFFER_ACTION_GAP
	var reroll := panel.get_node_or_null("RerollButton") as TextureButton
	if reroll != null:
		reroll.position = Vector2(78, button_y)
		reroll.size = CARD_OFFER_BUTTON_SIZE
		reroll.custom_minimum_size = CARD_OFFER_BUTTON_SIZE
		var label := reroll.get_node_or_null("RerollLabel") as Label
		if label != null:
			label.position = Vector2.ZERO
			label.size = CARD_OFFER_BUTTON_SIZE
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var skip := panel.get_node_or_null("SkipButton") as TextureButton
	if skip != null:
		skip.position = Vector2(522, button_y)
		skip.size = CARD_OFFER_BUTTON_SIZE
		skip.custom_minimum_size = CARD_OFFER_BUTTON_SIZE
		var label := skip.get_node_or_null("SkipLabel") as Label
		if label != null:
			label.position = Vector2.ZERO
			label.size = CARD_OFFER_BUTTON_SIZE
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _card_offer_vertical_bounds() -> Vector2:
	# The offer belongs to the live battlefield, not to the full physical phone
	# height. Centre it between the fixed top combat controls and the real breach
	# line so tall phones do not push the enlarged cards down onto the hero/base.
	var insets := _viewport_safe_insets()
	var top_y := CARD_OFFER_CENTER_TOP_Y + float(insets.get("top", 0.0))
	var viewport_bottom := get_viewport_rect().size.y - float(insets.get("bottom", 0.0))
	var bottom_y := minf(BREACH_Y, viewport_bottom)
	return Vector2(top_y, maxf(top_y, bottom_y))

func _card_offer_centered_y(panel_height: float) -> float:
	var bounds := _card_offer_vertical_bounds()
	var centered_y := (bounds.x + bounds.y - panel_height) * 0.5
	return clampf(centered_y, bounds.x, maxf(bounds.x, bounds.y - panel_height))

func _layout_card_detail_overlay() -> void:
	var overlay := get_node_or_null("Hud/CardPanel/DetailOverlay") as Control
	var panel := get_node_or_null("Hud/CardPanel/DetailOverlay/Panel") as Panel
	if overlay == null or panel == null:
		return
	var host_panel := get_node_or_null("Hud/CardPanel") as Control
	var host_size := host_panel.size if host_panel != null else CARD_OFFER_PANEL_SIZE
	# The detail view owns the already corridor-constrained offer panel. Using the
	# whole host gives localized copy room without extending into the hero/base
	# lane, and avoids a second arbitrary 112px/98px inset inside the modal.
	overlay.position = Vector2.ZERO
	overlay.size = host_size
	overlay.clip_contents = true
	var dim := overlay.get_node_or_null("Dim") as TextureRect
	if dim != null:
		dim.position = Vector2.ZERO
		dim.size = overlay.size
		dim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dim.stretch_mode = TextureRect.STRETCH_SCALE
		dim.modulate = Color(0.0, 0.0, 0.0, 0.82)
	var panel_width := minf(888.0, maxf(804.0, overlay.size.x - 84.0))
	var content_x := 44.0
	var content_width := panel_width - content_x * 2.0
	panel.size = Vector2(panel_width, 854.0)
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", UiKit.result_panel_texture_style())
	var icon := panel.get_node_or_null("Icon") as TextureRect
	if icon != null:
		icon.position = Vector2(content_x, 32)
		icon.size = Vector2(96, 96)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var title := panel.get_node_or_null("Title") as Label
	if title != null:
		title.position = Vector2(166, 32)
		title.size = Vector2(panel_width - 210.0, 64)
		title.clip_text = true
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UiKit.apply_label(title, 24, UiKit.TEXT_MAIN, 3)
	var current := _ensure_card_detail_label(panel, "Body")
	current.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	current.clip_text = true
	current.add_theme_constant_override("line_spacing", 4)
	UiKit.apply_label(current, 16, UiKit.CYAN, 2)
	current.position = Vector2(content_x, 140)
	current.size = Vector2(content_width, _wrapped_label_required_height(current, content_width, 70.0))
	var levels_title := _ensure_card_detail_label(panel, "AllLevelsTitle")
	levels_title.position = Vector2(content_x, current.position.y + current.size.y + 12.0)
	levels_title.size = Vector2(content_width, 34)
	levels_title.text = LocalizationManager.text("全部等级")
	levels_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiKit.apply_label(levels_title, 17, UiKit.GOLD, 2)
	var levels := _ensure_card_detail_label(panel, "AllLevelsBody")
	levels.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	levels.clip_text = true
	levels.add_theme_constant_override("line_spacing", 7)
	UiKit.apply_label(levels, CARD_DETAIL_LEVELS_BODY_FONT_SIZE, Color(0.86, 0.92, 0.92, 1.0), 2)
	levels.position = Vector2(content_x, levels_title.position.y + levels_title.size.y + 8.0)
	levels.size = Vector2(content_width, _wrapped_label_required_height(levels, content_width, 196.0))
	var desc := _ensure_card_detail_label(panel, "DescBody")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.clip_text = true
	desc.add_theme_constant_override("line_spacing", 6)
	UiKit.apply_label(desc, CARD_DETAIL_DESCRIPTION_FONT_SIZE, Color(0.84, 0.92, 0.94, 1.0), 2)
	desc.position = Vector2(content_x, levels.position.y + levels.size.y + 12.0)
	desc.size = Vector2(content_width, _wrapped_label_required_height(desc, content_width, 164.0))
	var tags := _ensure_card_detail_label(panel, "TagsBody")
	tags.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tags.clip_text = true
	tags.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiKit.apply_label(tags, CARD_DETAIL_TAGS_FONT_SIZE, UiKit.TEXT_MUTED, 2)
	tags.position = Vector2(content_x, desc.position.y + desc.size.y + 12.0)
	tags.size = Vector2(content_width, _wrapped_label_required_height(tags, content_width, 52.0))
	var close := panel.get_node_or_null("CloseButton") as TextureButton
	if close != null:
		close.position = Vector2((panel_width - 320.0) * 0.5, tags.position.y + tags.size.y + 16.0)
		close.size = Vector2(320, 80)
		close.custom_minimum_size = Vector2(320, 80)
		close.ignore_texture_size = true
		UiKit.apply_armored_texture_button(close, false, Vector2(320, 80), true)
		UiKit.attach_touch_target(close, Vector2(320, 88))
		var close_label := close.get_node_or_null("Label") as Label
		if close_label != null:
			close_label.position = Vector2.ZERO
			close_label.size = Vector2(320, 80)
			close_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			close_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			UiKit.apply_label(close_label, 21, UiKit.TEXT_MAIN, 3)
		var required_panel_height := close.position.y + close.size.y + 24.0
		var max_panel_height := maxf(0.0, overlay.size.y - 84.0)
		panel.size.y = minf(required_panel_height, max_panel_height)
		panel.position = Vector2(
			(overlay.size.x - panel.size.x) * 0.5,
			maxf(42.0, (overlay.size.y - panel.size.y) * 0.5)
		)

func _ensure_card_detail_label(panel: Control, node_name: String) -> Label:
	var label := panel.get_node_or_null(node_name) as Label
	if label == null:
		label = Label.new()
		label.name = node_name
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(label)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _ensure_hp_bar_in_bottom_bar() -> void:
	var bottom_bar := get_node_or_null("Hud/BottomBar") as Control
	if bottom_bar == null:
		return
	var hp_bar := get_node_or_null(HUD_HP_BAR_PATH) as Control
	if hp_bar == null:
		hp_bar = get_node_or_null("Hud/TopBar/BaseHpBar") as Control
	if hp_bar == null:
		return
	if hp_bar.get_parent() != bottom_bar:
		var old_parent := hp_bar.get_parent()
		if old_parent != null:
			old_parent.remove_child(hp_bar)
		bottom_bar.add_child(hp_bar)

func _ensure_speed_button() -> void:
	if not has_node("PauseLayer") or has_node("PauseLayer/SpeedButton"):
		_update_speed_button_visual()
		return
	var button := Button.new()
	button.name = "SpeedButton"
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.tooltip_text = "战斗加速"
	button.add_theme_font_size_override("font_size", UiKit.bumped_font_size(26))
	button.add_theme_color_override("font_color", UiKit.TEXT_MAIN)
	button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	button.add_theme_constant_override("outline_size", 3)
	button.pressed.connect(_cycle_battle_speed)
	$PauseLayer.add_child(button)
	_update_speed_button_visual()

func _update_speed_button_visual() -> void:
	var button := get_node_or_null("PauseLayer/SpeedButton") as Button
	if button == null:
		return
	var unlocked := _is_speed_button_unlocked()
	button.visible = unlocked and not paused
	button.disabled = not unlocked
	var available_speeds := SettingsManager.available_battle_speeds(battle_speed_progress_level)
	button.tooltip_text = (
		"战斗加速：1X / 2X / 5X"
		if available_speeds.has(5.0)
		else "战斗加速：最高 2X（第50关解锁 5X）"
	)
	var boosted := battle_speed > 1.0
	button.text = "%dX" % int(round(battle_speed))
	# 直接复用 icon_frame 贴图，但用比 icon_frame_texture_style() 默认更小的
	# margin——那个默认 margin(32px)是给 120px+ 的图鉴/技能格子配的，按钮只有
	# 82px 见方时边框相对贴图会被压得太挤，实测会糊成一个圆斑；同一张图换小
	# margin 就能在小尺寸下正常显示方角边框。
	var path := UiKit.UI_TEXTURE_ROOT + ("ui_icon_frame_active.png" if boosted else "ui_icon_frame.png")
	var style := UiKit.texture_style(path, 14.0, 6.0, UiKit.GOLD if boosted else UiKit.CYAN)
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color", UiKit.GOLD if boosted else UiKit.TEXT_MAIN)

func _cycle_battle_speed() -> void:
	if not _is_speed_button_unlocked():
		return
	battle_speed = SettingsManager.cycle_battle_speed(battle_speed_progress_level)
	Engine.time_scale = battle_speed
	if hit_stop != null and is_instance_valid(hit_stop):
		hit_stop.target_scale = battle_speed
	_update_speed_button_visual()
	AudioManager.play_sfx("ui_click")

func _is_speed_button_unlocked() -> bool:
	return SettingsManager.is_battle_speed_unlocked(battle_speed_progress_level)

func _layout_status_bar(path: String, pos: Vector2, bar_size: Vector2, fill_top: float, fill_height: float, font_size: int) -> void:
	var bar := get_node_or_null(path) as Control
	if bar == null:
		return
	bar.position = pos
	bar.size = bar_size
	bar.clip_contents = true
	var under := bar.get_node_or_null("Under") as TextureRect
	if under != null:
		under.position = Vector2.ZERO
		under.size = bar_size
		under.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		under.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED if path == HUD_WAVE_BAR_PATH else TextureRect.STRETCH_SCALE
		under.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := bar.get_node_or_null("FillTexture") as TextureRect
	if fill != null:
		fill.position = Vector2(6.0, fill_top)
		fill.size = Vector2(maxf(bar_size.x - 12.0, 1.0), fill_height)
		fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fill.stretch_mode = TextureRect.STRETCH_SCALE
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := bar.get_node_or_null("Label") as Label
	if label != null:
		label.position = Vector2.ZERO
		label.size = bar_size
		UiKit.apply_label(label, font_size, UiKit.TEXT_MAIN, 3)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _layout_bottom_resource_bar() -> void:
	# Keep the three bottom resources on one optical baseline. Physical-iPhone
	# review showed the old row floating too close to the hero and defense line;
	# drop only this row, preserving the skill shelf, actor anchors and safe-area
	# dock as authored.
	var gold_icon := get_node_or_null("Hud/BottomBar/GoldIcon") as TextureRect
	if gold_icon != null:
		gold_icon.position = Vector2(8.0, 22.0 + BOTTOM_RESOURCE_ROW_DROP)
		gold_icon.size = Vector2(54, 54)
		gold_icon.custom_minimum_size = Vector2(54, 54)
	var gold_label := get_node_or_null("Hud/BottomBar/GoldLabel") as Label
	if gold_label != null:
		gold_label.position = Vector2(64.0, 16.0 + BOTTOM_RESOURCE_ROW_DROP)
		gold_label.size = Vector2(112, 62)
		UiKit.apply_label(gold_label, 26, UiKit.GOLD, 3)
		gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var xp_icon := get_node_or_null("Hud/BottomBar/XpIcon") as TextureRect
	if xp_icon != null:
		xp_icon.position = Vector2(184.0, 27.0 + BOTTOM_RESOURCE_ROW_DROP)
		xp_icon.size = Vector2(44, 44)
		xp_icon.custom_minimum_size = Vector2(44, 44)
	var xp_bar := get_node_or_null("Hud/BottomBar/XpBar") as Control
	if xp_bar != null:
		xp_bar.position = Vector2(232.0, 21.0 + BOTTOM_RESOURCE_ROW_DROP)
		xp_bar.size = Vector2(386.0, 54.0)
		xp_bar.clip_contents = true
		var track := xp_bar.get_node_or_null("Track") as Panel
		if track != null:
			track.position = Vector2.ZERO
			track.size = Vector2(386.0, 54.0)
		var fill := xp_bar.get_node_or_null("Fill") as Panel
		if fill != null:
			fill.position = Vector2(7.0, 16.0)
			fill.size = Vector2(372.0, 22.0)
		var label := xp_bar.get_node_or_null("Label") as Label
		if label != null:
			label.position = Vector2.ZERO
			label.size = Vector2(386.0, 54.0)
	var hp_bar := get_node_or_null(HUD_HP_BAR_PATH) as Control
	if hp_bar != null:
		_layout_status_bar(HUD_HP_BAR_PATH, Vector2(632.0, 21.0 + BOTTOM_RESOURCE_ROW_DROP), Vector2(384.0, 54.0), 18.0, 16.0, 22)

func _ensure_hud_fill_texture(bar_path: String, texture_path: String, top: float, height: float) -> void:
	var bar := get_node_or_null(bar_path) as Control
	if bar == null:
		return
	bar.clip_contents = true
	var legacy := bar.get_node_or_null("Fill") as CanvasItem
	if legacy != null:
		legacy.visible = false
	var fill := bar.get_node_or_null("FillTexture") as TextureRect
	if fill == null:
		fill = TextureRect.new()
		fill.name = "FillTexture"
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill.z_index = 1
		bar.add_child(fill)
	fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fill.stretch_mode = TextureRect.STRETCH_SCALE
	if ResourceLoader.exists(texture_path):
		fill.texture = load(texture_path)
	fill.material = _wave_fill_material() if bar_path == HUD_WAVE_BAR_PATH else null
	var fill_left := _hud_fill_left(bar_path, 6.0)
	var fill_right := _hud_fill_right(bar_path, maxf(bar.size.x - 6.0, 1.0))
	if bar_path == HUD_HP_BAR_PATH or bar_path == HUD_WAVE_BAR_PATH:
		var clip := _ensure_hud_fill_clip(bar, fill_left, top, maxf(fill_right - fill_left, 1.0), height)
		if fill.get_parent() != clip:
			var old_parent := fill.get_parent()
			if old_parent != null:
				old_parent.remove_child(fill)
			clip.add_child(fill)
		fill.position = Vector2.ZERO
		fill.size = Vector2(maxf(fill_right - fill_left, 1.0), height)
		fill.z_index = 0
	else:
		fill.position = Vector2(fill_left, top)
		fill.size = Vector2(maxf(fill_right - fill_left, 1.0), height)
	var label := bar.get_node_or_null("Label") as CanvasItem
	if label != null:
		label.z_index = 3

func _ensure_hud_fill_clip(bar: Control, fill_left: float, top: float, width: float, height: float) -> Control:
	var clip := bar.get_node_or_null("FillClip") as Control
	if clip == null:
		clip = Control.new()
		clip.name = "FillClip"
		clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip.z_index = 1
		bar.add_child(clip)
		var label := bar.get_node_or_null("Label") as CanvasItem
		if label != null:
			bar.move_child(label, bar.get_child_count() - 1)
	clip.clip_contents = true
	clip.position = Vector2(fill_left, top)
	clip.size = Vector2(width, height)
	return clip

func _hud_fill_clip(bar_path: String) -> Control:
	return get_node_or_null("%s/FillClip" % bar_path) as Control

func _hud_fill_texture(bar_path: String) -> TextureRect:
	var direct := get_node_or_null("%s/FillTexture" % bar_path) as TextureRect
	if direct != null:
		return direct
	return get_node_or_null("%s/FillClip/FillTexture" % bar_path) as TextureRect

func _wave_fill_material() -> ShaderMaterial:
	if wave_fill_material != null:
		return wave_fill_material
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 fill_tint : source_color = vec4(1.0, 0.66, 0.20, 1.0);
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float light = max(max(tex.r, tex.g), tex.b);
	vec3 warm = mix(fill_tint.rgb * 0.58, min(fill_tint.rgb * 1.22, vec3(1.0)), light);
	COLOR = vec4(warm, tex.a);
}
"""
	wave_fill_material = ShaderMaterial.new()
	wave_fill_material.shader = shader
	return wave_fill_material

func _style_xp_bar() -> void:
	if not has_node("Hud/BottomBar/XpBar"):
		return
	var xp_bar := $Hud/BottomBar/XpBar as Control
	xp_bar.clip_contents = true
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("Hud/BottomBar/XpBar/Track"):
		var track := $Hud/BottomBar/XpBar/Track as Panel
		var track_style := UiKit.texture_style("res://assets/production/sprites/ui/ui_run_xp_bar.png", 24.0, 0.0, UiKit.CYAN)
		track.add_theme_stylebox_override("panel", track_style)
		track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("Hud/BottomBar/XpBar/Fill"):
		var fill := $Hud/BottomBar/XpBar/Fill as Panel
		var fill_style := UiKit.texture_style("res://assets/production/sprites/ui/ui_bar_fill_xp.png", 18.0, 0.0, UiKit.SUCCESS)
		fill.add_theme_stylebox_override("panel", fill_style)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("Hud/BottomBar/XpBar/Label"):
		var label := $Hud/BottomBar/XpBar/Label as Label
		UiKit.apply_label(label, 23, Color(0.92, 0.98, 0.94, 1.0), 3)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _setup_pause_overlay_layout() -> void:
	if not has_node("Hud/PauseOverlay/Panel"):
		return
	var modal_shift := UiKit.tall_modal_shift(get_viewport_rect().size.y, 160.0, 0.34)
	var content_height := _pause_content_height()
	var action_top := PAUSE_CONTENT_ORIGIN.y + content_height + PAUSE_ACTION_CONTENT_GAP
	var panel_height := action_top + PAUSE_ACTION_BUTTON_SIZE.y + PAUSE_PANEL_BOTTOM_PADDING
	var overlay := $Hud/PauseOverlay as Control
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var scrim := $Hud/PauseOverlay/Dim as TextureRect
	scrim.visible = true
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.offset_left = 0.0
	scrim.offset_top = 0.0
	scrim.offset_right = 0.0
	scrim.offset_bottom = 0.0
	scrim.modulate = Color(0.0, 0.0, 0.0, 0.68)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel := $Hud/PauseOverlay/Panel as Panel
	panel.offset_left = 54.0
	panel.offset_top = 140.0 + modal_shift
	panel.offset_right = 1026.0
	panel.offset_bottom = panel.offset_top + panel_height
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", UiKit.result_panel_texture_style())
	var title := $Hud/PauseOverlay/Panel/Title as Label
	title.position = Vector2(0, 24)
	title.size = Vector2(972, 86)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiKit.apply_label(title, 52, UiKit.TEXT_MAIN, 4)
	var legacy_summary := $Hud/PauseOverlay/Panel/BuildSummary as Label
	legacy_summary.visible = false
	var content := panel.get_node_or_null("PauseContent") as VBoxContainer
	if content == null:
		content = VBoxContainer.new()
		content.name = "PauseContent"
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(content)
	content.z_index = 0
	content.add_theme_constant_override("separation", 16)
	content.position = PAUSE_CONTENT_ORIGIN
	content.size = Vector2(PAUSE_CONTENT_WIDTH, content_height)
	# Pause actions are deliberately one left/centre/right row. Their taller
	# targets remain easy to hit, while the short verbs keep every locale clear
	# of the ornamental button corners.
	_layout_pause_action_button($Hud/PauseOverlay/Panel/ResumeButton as TextureButton, Vector2(44, action_top), "res://assets/production/sprites/ui/icon_pause.png", "继续", true)
	_layout_pause_action_button($Hud/PauseOverlay/Panel/RestartButton as TextureButton, Vector2(348, action_top), "res://assets/production/sprites/ui/icon_reroll_charge.png", "重开", true)
	_layout_pause_action_button($Hud/PauseOverlay/Panel/MapButton as TextureButton, Vector2(652, action_top), "res://assets/production/sprites/ui/icon_settings.png", "退出", false)

func _layout_pause_action_button(button: TextureButton, pos: Vector2, icon_path: String, title_text: String, primary: bool) -> void:
	if button == null:
		return
	var button_size := PAUSE_ACTION_BUTTON_SIZE
	button.visible = true
	# PauseContent is rebuilt after the authored scene buttons. Keep the actions
	# explicitly above that dynamic sibling so even an unexpectedly tall locale
	# or future skill row can never paint over the three required exits.
	button.z_index = 10
	button.offset_left = pos.x
	button.offset_top = pos.y
	button.offset_right = pos.x + button_size.x
	button.offset_bottom = pos.y + button_size.y
	button.custom_minimum_size = button_size
	button.ignore_texture_size = true
	UiKit.apply_armored_texture_button(button, primary, button_size, true)
	button.clip_contents = true
	var old_label := button.get_node_or_null("Label") as Label
	if old_label != null:
		old_label.visible = false
	for child_name in ["IconPlate", "ActionTitle", "ActionSub", "ActionArrow"]:
		var old := button.get_node_or_null(child_name)
		if old != null:
			old.free()
	var icon_plate := PanelContainer.new()
	icon_plate.name = "IconPlate"
	icon_plate.position = PAUSE_ACTION_ICON_RECT.position
	icon_plate.size = PAUSE_ACTION_ICON_RECT.size
	icon_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_plate.add_theme_stylebox_override("panel", UiKit.pill_style(UiKit.GOLD if primary else UiKit.BORDER_SOFT, Color(0.018, 0.022, 0.028, 0.78)))
	button.add_child(icon_plate)
	var icon := UiKit.icon(icon_path, Vector2(48, 48))
	icon.modulate = Color(1.0, 0.9, 0.62, 1.0) if primary else Color(0.82, 0.92, 1.0, 0.92)
	icon_plate.add_child(icon)
	var title_size := 21 if LocalizationManager.is_english() else 24
	var title := UiKit.label(LocalizationManager.text(title_text), title_size, Color.WHITE, 3)
	title.name = "ActionTitle"
	title.position = PAUSE_ACTION_TITLE_RECT.position
	title.size = PAUSE_ACTION_TITLE_RECT.size
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.clip_text = true
	UiKit.fit_label_text(
		title,
		UiKit.scaled_font_size(title_size),
		UiKit.scaled_font_size(20 if LocalizationManager.is_english() else 23),
		2.0,
		2.0
	)
	button.add_child(title)
	button.set_meta("pause_action_layout", "three_column_compact")
	button.set_meta("pause_action_safe_rect", PAUSE_ACTION_FRAME_SAFE_RECT)

func _setup_wave_toast_banner() -> void:
	if wave_toast_banner != null and is_instance_valid(wave_toast_banner):
		return
	if has_node("Hud/WaveToast"):
		($Hud/WaveToast as Label).visible = false
	var banner := Control.new()
	banner.name = "WaveBanner"
	banner.position = WAVE_TOAST_BASE_POSITION
	banner.size = WAVE_TOAST_SIZE
	banner.pivot_offset = WAVE_TOAST_SIZE * 0.5
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.z_index = 90
	banner.visible = false
	$Hud.add_child(banner)

	var band := TextureRect.new()
	band.name = "Band"
	band.texture = load("res://assets/production/sprites/ui/ui_hint_strip.png")
	band.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	band.stretch_mode = TextureRect.STRETCH_SCALE
	band.position = Vector2.ZERO
	band.size = WAVE_TOAST_SIZE
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(band)

	var accent_line := TextureRect.new()
	accent_line.name = "AccentLine"
	accent_line.texture = load("res://assets/production/sprites/ui/ui_map_pill_skin.png")
	accent_line.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	accent_line.stretch_mode = TextureRect.STRETCH_SCALE
	accent_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accent_line.modulate = UiKit.GOLD
	accent_line.position = Vector2(72, 72)
	accent_line.size = Vector2(WAVE_TOAST_SIZE.x - 144.0, 10.0)
	banner.add_child(accent_line)

	wave_toast_panel = null
	wave_toast_label = Label.new()
	wave_toast_label.name = "Text"
	wave_toast_label.position = Vector2.ZERO
	wave_toast_label.size = WAVE_TOAST_SIZE
	wave_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wave_toast_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	wave_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.apply_label(wave_toast_label, 28, UiKit.GOLD, 4)
	wave_toast_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.78))
	wave_toast_label.add_theme_constant_override("shadow_offset_x", 0)
	wave_toast_label.add_theme_constant_override("shadow_offset_y", 3)
	banner.add_child(wave_toast_label)
	wave_toast_banner = banner
	wave_toast_banner.position = _wave_toast_target_position()

func _wave_toast_target_position() -> Vector2:
	var banner_size := WAVE_TOAST_SIZE
	if wave_toast_banner != null and is_instance_valid(wave_toast_banner):
		banner_size = wave_toast_banner.size
	var target_y := WAVE_TOAST_BASE_POSITION.y
	var top_bar := get_node_or_null("Hud/TopBar") as Control
	if top_bar != null:
		target_y = maxf(target_y, top_bar.offset_bottom + 22.0)
	# The boss identity/HP rail owns the next HUD band. Long onboarding and
	# wave tips must sit below it instead of obscuring the boss name and health.
	if active_boss != null and is_instance_valid(active_boss) and boss_hp_bar != null and is_instance_valid(boss_hp_bar):
		target_y = maxf(target_y, boss_hp_bar.position.y + boss_hp_bar.size.y + 18.0)
	return Vector2((1080.0 - banner_size.x) * 0.5, target_y)

func _wave_toast_band_texture() -> GradientTexture2D:
	# 暗色椭圆光带：中心较实、四周淡出到全透明，横向拉伸后是柔和的横条，无硬边
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([
		Color(0.028, 0.022, 0.016, 0.92),
		Color(0.028, 0.022, 0.016, 0.60),
		Color(0.028, 0.022, 0.016, 0.0),
	])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 64
	return t

func _wave_toast_line_texture() -> GradientTexture2D:
	# 细线：两端淡出到透明、中间实（配合 modulate 染成货币色）
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([
		Color(1, 1, 1, 0.0),
		Color(1, 1, 1, 0.95),
		Color(1, 1, 1, 0.0),
	])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_LINEAR
	t.fill_from = Vector2(0.0, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 4
	return t

func _strategy_label(strategy: String) -> String:
	match strategy:
		"breach": return "近线威胁"
		"elite": return "精英 / 首领"
		"low_hp": return "血少优先"
		"nearest": return "最近"
		_: return strategy

func _element_label(element: String) -> String:
	match element:
		"physical": return "物理"
		"fire": return "火"
		"ice": return "冰"
		"lightning": return "雷"
		"poison": return "毒"
		_: return element

func _on_resume_pressed() -> void:
	_set_battle_paused(false, true)

func _on_restart_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	_set_battle_paused(false, false)
	router.start_level(level_id)

func _on_pause_to_map() -> void:
	AudioManager.play_sfx("ui_click")
	_set_battle_paused(false, false)
	if is_endless_mode:
		_finish(false)
		return
	router.change_scene("map")

func _process_spawns(delta: float) -> void:
	if not active_spawning:
		return
	spawn_timer -= delta
	if wave_clear_fast_forward_enabled and spawn_timer > 0.0 and _wave_clear_fast_forward_clear_at >= 0.0 and not pending_spawns.is_empty():
		_apply_wave_clear_fast_forward(pending_spawns[0])
	if spawn_timer > 0.0:
		return
	if pending_spawns.is_empty():
		active_spawning = false
		return
	var item: Dictionary = pending_spawns.pop_front()
	var spawn_delay := maxf(float(item.get("spawn_delay", 0.0)), 0.0)
	if spawn_delay > 0.0 and not bool(item.get("_spawn_delay_consumed", false)):
		item["_spawn_delay_consumed"] = true
		pending_spawns.push_front(item)
		spawn_timer = spawn_delay
		return
	_spawn_enemy(
		item.get("type", "zombie_shambler"),
		item.get("lane", "spread"),
		item.get("boss", false),
		float(item.get("endless_boss_hp", 0.0)),
		bool(item.get("xp_budget_counted", false)),
	)
	spawn_timer = item.get("interval", 0.8)

## Loads the `wave_clear_fast_forward` switch from `data/economy.json`. The
## key is optional (older/fixture economy tables omit it entirely) and its
## absence must resolve to the same disabled default as an explicit
## `{"enabled": false}`, so every read goes through `.get(...)` with the
## documented defaults rather than assuming the key exists.
func _load_wave_clear_fast_forward_config(economy: Dictionary) -> void:
	var raw: Variant = economy.get("wave_clear_fast_forward", {})
	var cfg: Dictionary = raw if raw is Dictionary else {}
	wave_clear_fast_forward_enabled = bool(cfg.get("enabled", false))
	wave_clear_fast_forward_breather = maxf(float(cfg.get("breather_seconds", 3.0)), 0.0)
	_wave_clear_fast_forward_clear_at = -1.0

## Owner-reported pain point: when output is high, the previous Boss dies and
## the next authored Boss in a multi-Boss wave still waits out its full
## `runtime_bosses[].spawn_delay` (levels author up to 65s) with nothing left
## on screen. This only tightens that specific wait: once the battlefield has
## been fully clear (no live enemies, so implicitly no live Boss) for at
## least `wave_clear_fast_forward_breather` seconds, the next delayed-Boss
## queue entry is allowed to spawn immediately instead of waiting out its
## remaining authored delay. `minf` guarantees the result can only arrive
## sooner than the authored schedule, never later — a slow clear (or one that
## never fully clears) leaves `spawn_timer` completely untouched, matching
## pre-feature behavior exactly ("only advance, never delay").
func _apply_wave_clear_fast_forward(front_item: Dictionary) -> void:
	if not bool(front_item.get("boss", false)) or not bool(front_item.get("_spawn_delay_consumed", false)):
		return
	var earliest_remaining := maxf((_wave_clear_fast_forward_clear_at + wave_clear_fast_forward_breather) - _gameplay_now_seconds(), 0.0)
	if earliest_remaining >= spawn_timer:
		return
	spawn_timer = earliest_remaining
	if not bool(front_item.get("_fast_forward_notified", false)):
		front_item["_fast_forward_notified"] = true
		_show_wave_toast("首领提前来袭", Color(1.0, 0.82, 0.25))

func _start_next_wave() -> void:
	var waves: Array = level.get("waves", [])
	if wave_index >= waves.size():
		return
	_apply_wave_start_support()
	var wave: Dictionary = waves[wave_index]
	wave_index += 1
	if wave_clear_fast_forward_enabled:
		_wave_clear_fast_forward_clear_at = -1.0
	pending_spawns.clear()
	if wave_index == 1:
		boss_spawn_counts.clear()
	recent_spawn_positions.clear()
	_update_objective_panel()
	_show_wave_tip(wave)
	if wave.has("boss"):
		AudioManager.play_bgm("boss")
		SettingsManager.pulse_haptic("heavy")
		var boss_id: String = wave.get("boss", "boss_tank_titan")
		AudioManager.play_sfx(_boss_intro_sfx(boss_id), 1.5, 0.015)
		_show_screen_flash(Color(1.0, 0.18, 0.08, 0.22), 0.22)
		var boss_name := DataLoader.tr_key(DataLoader.get_row("bosses", boss_id).get("name_key", boss_id))
		_show_wave_toast("首领来袭：%s" % boss_name, Color(1.0, 0.32, 0.22))
		_show_boss_banner(boss_name)
		pending_spawns.append({"type": boss_id, "interval": 1.0, "lane": "center", "boss": true, "xp_budget_counted": not is_endless_mode})
		# Extra bosses are authored in levels.json so runtime, balance simulation and
		# the power ruler all see the same encounter. The former boss_rush branch
		# hardcoded Tank Titan here, which made level_099 about 40% heavier than every
		# offline recommendation knew about.
		var delayed_boss_spawns: Array[Dictionary] = []
		for extra_var in level.get("runtime_bosses", []):
			if not extra_var is Dictionary:
				continue
			var extra := extra_var as Dictionary
			if int(extra.get("wave", wave_index)) != wave_index:
				continue
			var extra_id := str(extra.get("type", ""))
			if extra_id == "" or DataLoader.get_row("bosses", extra_id).is_empty():
				continue
			var boss_spawn := {
				"type": extra_id,
				"interval": maxf(float(extra.get("interval", 1.6)), 0.0),
				"lane": str(extra.get("lane", "spread")),
				"boss": true,
				"xp_budget_counted": false,
			}
			var extra_spawn_delay := maxf(float(extra.get("spawn_delay", 0.0)), 0.0)
			if extra_spawn_delay > 0.0:
				boss_spawn["spawn_delay"] = extra_spawn_delay
				delayed_boss_spawns.append(boss_spawn)
			else:
				pending_spawns.append(boss_spawn)
		if is_endless_mode and _is_endless_final_wave(waves):
			_queue_endless_final_bosses(1)
		for support in wave.get("support", []):
			_queue_spawn_group(support, false, true)
		# Authored delayed reinforcements wait until the opening support column has
		# entered, then stage their own pre-spawn delay. Missing spawn_delay keeps
		# the historical Boss-before-support queue order byte-for-byte unchanged.
		for delayed_boss_spawn in delayed_boss_spawns:
			pending_spawns.append(delayed_boss_spawn)
	else:
		if wave_index == 1 and variant == "treasure" and not is_endless_mode:
			_show_wave_toast("宝箱关 · 金币 +50%", UiKit.GOLD)
		elif wave_index == 1 and variant == "elite" and not is_endless_mode:
			_show_wave_toast("精英关 · 经验 +30%", UiKit.DANGER)
		else:
			var wave_text: String
			if is_endless_mode:
				wave_text = "第 %d 轮 · 第 %d 波" % [endless_loop + 1, wave_index]
			elif wave_index >= waves.size():
				wave_text = "最终尸潮来袭"
			else:
				wave_text = "第 %d 波  尸潮来袭" % wave_index
			_show_wave_toast(wave_text, Color(1.0, 0.82, 0.25))
		# 阶段 67 修复：出怪循环此前缩在上面那个 else 里，于是 elite / treasure
		# 变体关的第 1 波只弹一条提示、一只敌人都不刷——21 关共 442 只敌人从未
		# 出现过，而平衡模型全程都把它们算在内。变体只决定提示文案，不应决定
		# 是否出怪。
		for group in wave.get("spawns", []):
			_queue_spawn_group(group, false)
		if is_endless_mode and _is_endless_final_wave(waves):
			_show_wave_toast("第 %d 轮最终波 · 首领压境" % (endless_loop + 1), Color(1.0, 0.36, 0.18))
			_queue_endless_final_bosses(0)
	if _is_endless_final_wave(waves):
		_assign_endless_boss_budget_to_pending()
	active_spawning = true
	spawn_timer = 0.2

func _is_endless_final_wave(waves: Array) -> bool:
	return is_endless_mode and not waves.is_empty() and wave_index >= waves.size()

func _queue_endless_final_bosses(existing_boss_count: int) -> void:
	var count := maxi(0, _endless_boss_count() - existing_boss_count)
	var lanes := ["center", "left", "right", "spread", "left", "right"]
	for i in range(count):
		pending_spawns.append({
			"type": _endless_boss_id(i),
			"interval": 2.0 if i == 0 and existing_boss_count <= 0 else 1.6,
			"lane": lanes[i % lanes.size()],
			"boss": true
		})

func _endless_boss_count() -> int:
	var economy: Dictionary = DataLoader.get_table("economy")
	var step := maxi(int(economy.get("endless_boss_count_step", ENDLESS_BOSS_COUNT_STEP)), 1)
	var cap := maxi(int(economy.get("endless_boss_count_cap", ENDLESS_BOSS_COUNT_CAP)), 1)
	return clampi(1 + int(endless_loop / step), 1, cap)

func _assign_endless_boss_budget_to_pending() -> void:
	var economy: Dictionary = DataLoader.get_table("economy")
	var total_budget := _endless_boss_total_budget(endless_loop + 1, economy)
	if total_budget <= 0.0:
		return
	var local_counts := {}
	var boss_indices: Array[int] = []
	var weights: Array[float] = []
	for index in range(pending_spawns.size()):
		var item_var = pending_spawns[index]
		if not item_var is Dictionary:
			continue
		var item := item_var as Dictionary
		if not bool(item.get("boss", false)):
			continue
		var enemy_id := str(item.get("type", ""))
		var copy_index := int(local_counts.get(enemy_id, 0))
		local_counts[enemy_id] = copy_index + 1
		boss_indices.append(index)
		weights.append(_same_type_boss_hp_multiplier(enemy_id, copy_index, economy))
	var weight_total := 0.0
	for weight in weights:
		weight_total += weight
	if boss_indices.is_empty() or weight_total <= 0.0:
		return
	for offset in range(boss_indices.size()):
		var item := pending_spawns[boss_indices[offset]] as Dictionary
		item["endless_boss_hp"] = total_budget * weights[offset] / weight_total
		pending_spawns[boss_indices[offset]] = item

func _endless_boss_total_budget(display_loop: int, economy: Dictionary) -> float:
	var pacing_var = economy.get("endless_boss_pacing", {})
	var pacing: Dictionary = pacing_var if pacing_var is Dictionary else {}
	var budgets_var = pacing.get("budgets", [])
	var budgets: Array = budgets_var if budgets_var is Array else []
	var fallback := 0.0
	for row_var in budgets:
		if not row_var is Dictionary:
			continue
		var row := row_var as Dictionary
		fallback = maxf(float(row.get("total_hp", fallback)), 0.0)
		if int(row.get("loop", 0)) == display_loop:
			return fallback
	# The experience curve caps after the generated table; later loops reuse its
	# final Boss budget while mob pressure remains free to grow monotonically.
	return fallback

func _endless_boss_id(offset := 0) -> String:
	var bosses: Dictionary = DataLoader.get_table("bosses")
	var eligible: Array[String] = []
	var virtual_level := level_ordinal + endless_loop * 5
	for boss_id in bosses.keys():
		var row: Dictionary = bosses[boss_id]
		if int(row.get("appear_level", 1)) <= virtual_level:
			eligible.append(str(boss_id))
	if eligible.is_empty():
		return "boss_tank_titan"
	eligible.sort_custom(func(a: String, b: String) -> bool:
		var a_level := int((bosses.get(a, {}) as Dictionary).get("appear_level", 1))
		var b_level := int((bosses.get(b, {}) as Dictionary).get("appear_level", 1))
		return a_level < b_level if a_level != b_level else a < b
	)
	return eligible[posmod(eligible.size() - 1 - offset, eligible.size())]

func _apply_wave_start_support() -> void:
	var skill := _pet_skill_data()
	match str(skill.get("kind", "")):
		"repair":
			if base_hp >= base_hp_max:
				return
			var flat_heal := _pet_scaled_value("heal_per_wave", "level_heal_growth")
			var ratio_heal := float(base_hp_max) * _pet_linear_value("heal_per_wave_ratio", "level_wave_heal_ratio_growth")
			_apply_pet_base_heal(int(round(flat_heal + ratio_heal)), "波次整备", true)
		"wave_salvage":
			_apply_pet_wave_salvage()

func _queue_spawn_group(group: Dictionary, is_boss: bool, support := false) -> void:
	var count := int(group.get("count", 1))
	if not is_boss:
		count = _scaled_wave_group_count(count, wave_index)
	var authored_lane := str(group.get("lane", "spread"))
	for i in range(count):
		pending_spawns.append({
			"type": group.get("type", "zombie_shambler"),
			"interval": group.get("interval", 0.8),
			"lane": authored_lane if is_boss else _formation_lane(authored_lane, i, support),
			"boss": is_boss,
			"xp_budget_counted": not is_endless_mode,
		})

## 阶段 67：所有 99 关都写了 `wave_pattern`，但运行时从来没读过——五种编队名
## (standard / rush / pincer / escort / siege) 一直只是标签，玩家感受不到任何
## 差别，正是 todo 里"避免只靠 HP/数量换皮"指的问题。
##
## 这里只改**队形几何**：把同一批敌人分配到不同的进攻通道。刻意不碰数量、
## 出怪间隔、HP 和总出怪时长，因此 check_level_pressure / simulate_balance 的
## 每一个数字都保持不变，差异纯粹体现在走位与火力分配上。
func _formation_lane(authored_lane: String, index: int, support: bool) -> String:
	match wave_formation:
		"rush":
			# 正面猛冲：全部压中路直扑防线。
			return "center"
		"pincer":
			# 钳形：左右两爪交替合围，中路留空。
			return "left" if index % 2 == 0 else "right"
		"escort":
			# 护送：被护送的支援目标走中路，其余敌人贴两翼掩护。
			if support:
				return "center"
			return "left" if index % 2 == 0 else "right"
		"siege":
			# 围城：三路轮转铺满整条战线，逼玩家横向分配火力。
			match index % 3:
				0:
					return "left"
				1:
					return "right"
				_:
					return "spread"
		_:
			# standard：完全沿用关卡作者写的通道。
			return authored_lane

func _scaled_wave_group_count(base_count: int, current_wave: int) -> int:
	var economy: Dictionary = DataLoader.get_table("economy")
	var mult := _late_wave_count_mult(current_wave, economy)
	return maxi(1, int(round(float(maxi(base_count, 1)) * mult)))

func _late_wave_count_mult(current_wave: int, economy: Dictionary) -> float:
	var table_var = economy.get("late_wave_count_mult", DEFAULT_LATE_WAVE_COUNT_MULT)
	var table: Dictionary = table_var if table_var is Dictionary else DEFAULT_LATE_WAVE_COUNT_MULT
	var base := 1.0
	if table.has(str(current_wave)):
		base = float(table[str(current_wave)])
	else:
		base = float(table.get(current_wave, DEFAULT_LATE_WAVE_COUNT_MULT.get(current_wave, 1.0)))
	return maxf(1.0, base) * _late_wave_count_level_ramp_mult(current_wave, economy)

func _late_wave_count_level_ramp_mult(current_wave: int, economy: Dictionary) -> float:
	var rule_var = economy.get("late_wave_count_level_ramp", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP)
	var rule: Dictionary = rule_var if rule_var is Dictionary else DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP
	var start_wave := int(rule.get("start_wave", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP.get("start_wave", 3)))
	if current_wave < start_wave:
		return 1.0
	var start_level := float(rule.get("start_level", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP.get("start_level", 55)))
	var full_level := float(rule.get("full_level", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP.get("full_level", 90)))
	var max_mult := maxf(1.0, float(rule.get("max_mult", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP.get("max_mult", 1.25))))
	var curve_power := maxf(0.01, float(rule.get("curve_power", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP.get("curve_power", 1.0))))
	if float(level_ordinal) < start_level:
		return 1.0
	var ramp_mult := max_mult
	if full_level > start_level:
		var t := clampf((float(level_ordinal) - start_level) / (full_level - start_level), 0.0, 1.0)
		ramp_mult = lerpf(1.0, max_mult, pow(t, curve_power))
	var final_level := int(rule.get("final_level", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP.get("final_level", 99)))
	if level_ordinal >= final_level:
		ramp_mult *= maxf(1.0, float(rule.get("final_mult", DEFAULT_LATE_WAVE_COUNT_LEVEL_RAMP.get("final_mult", 1.08))))
	return ramp_mult

func _late_wave_hp_bonus(current_wave: int, is_boss_enemy: bool, economy: Dictionary) -> float:
	var key := "late_wave_boss_hp_bonus" if is_boss_enemy else "late_wave_hp_bonus"
	var fallback := DEFAULT_LATE_WAVE_BOSS_HP_BONUS if is_boss_enemy else DEFAULT_LATE_WAVE_HP_BONUS
	var table_var = economy.get(key, fallback)
	var table: Dictionary = table_var if table_var is Dictionary else fallback
	var base := 1.0
	if table.has(str(current_wave)):
		base = float(table[str(current_wave)])
	else:
		base = float(table.get(current_wave, fallback.get(current_wave, 1.0)))
	if current_wave >= 3:
		base *= _late_wave_level_ramp_mult(economy)
		base *= run_skill_hp_pressure_mult
	return base

func _late_wave_level_ramp_mult(economy: Dictionary) -> float:
	var rule_var = economy.get("late_wave_level_ramp", DEFAULT_LATE_WAVE_LEVEL_RAMP)
	var rule: Dictionary = rule_var if rule_var is Dictionary else DEFAULT_LATE_WAVE_LEVEL_RAMP
	var start_level := float(rule.get("start_level", DEFAULT_LATE_WAVE_LEVEL_RAMP.get("start_level", 50)))
	var full_level := float(rule.get("full_level", DEFAULT_LATE_WAVE_LEVEL_RAMP.get("full_level", 98)))
	var max_mult := float(rule.get("max_mult", DEFAULT_LATE_WAVE_LEVEL_RAMP.get("max_mult", 1.80)))
	var curve_power := maxf(0.01, float(rule.get("curve_power", DEFAULT_LATE_WAVE_LEVEL_RAMP.get("curve_power", 1.0))))
	if float(level_ordinal) < start_level:
		return 1.0
	var ramp_mult := max_mult
	if full_level > start_level:
		var t := clampf((float(level_ordinal) - start_level) / (full_level - start_level), 0.0, 1.0)
		ramp_mult = lerpf(1.0, max_mult, pow(t, curve_power))
	var final_level := int(rule.get("final_level", DEFAULT_LATE_WAVE_LEVEL_RAMP.get("final_level", 99)))
	if level_ordinal >= final_level:
		ramp_mult *= maxf(1.0, float(rule.get("final_mult", DEFAULT_LATE_WAVE_LEVEL_RAMP.get("final_mult", 1.20))))
	return ramp_mult

func _late_wave_damage_ramp_mult(economy: Dictionary) -> float:
	var rule_var = economy.get("late_wave_damage_ramp", DEFAULT_LATE_WAVE_DAMAGE_RAMP)
	var rule: Dictionary = rule_var if rule_var is Dictionary else DEFAULT_LATE_WAVE_DAMAGE_RAMP
	var start_wave := int(rule.get("start_wave", DEFAULT_LATE_WAVE_DAMAGE_RAMP.get("start_wave", 3)))
	if wave_index < start_wave:
		return 1.0
	var start_level := float(rule.get("start_level", DEFAULT_LATE_WAVE_DAMAGE_RAMP.get("start_level", 50)))
	var full_level := float(rule.get("full_level", DEFAULT_LATE_WAVE_DAMAGE_RAMP.get("full_level", 98)))
	var max_mult := float(rule.get("max_mult", DEFAULT_LATE_WAVE_DAMAGE_RAMP.get("max_mult", 2.0)))
	var curve_power := maxf(0.01, float(rule.get("curve_power", DEFAULT_LATE_WAVE_DAMAGE_RAMP.get("curve_power", 1.0))))
	if float(level_ordinal) < start_level:
		return 1.0
	var ramp_mult := max_mult
	if full_level > start_level:
		var t := clampf((float(level_ordinal) - start_level) / (full_level - start_level), 0.0, 1.0)
		ramp_mult = lerpf(1.0, max_mult, pow(t, curve_power))
	var final_level := int(rule.get("final_level", DEFAULT_LATE_WAVE_DAMAGE_RAMP.get("final_level", 99)))
	if level_ordinal >= final_level:
		ramp_mult *= maxf(1.0, float(rule.get("final_mult", DEFAULT_LATE_WAVE_DAMAGE_RAMP.get("final_mult", 1.15))))
	return ramp_mult

func _boss_level_hp_bonus(current_level: int, is_boss_enemy: bool, economy: Dictionary) -> float:
	if not is_boss_enemy:
		return 1.0
	var rule_var = economy.get("boss_hp_level_bonus", DEFAULT_BOSS_HP_LEVEL_BONUS)
	var rule: Dictionary = rule_var if rule_var is Dictionary else DEFAULT_BOSS_HP_LEVEL_BONUS
	var start_level := int(rule.get("start_level", DEFAULT_BOSS_HP_LEVEL_BONUS.get("start_level", 20)))
	var multiplier := float(rule.get("multiplier", DEFAULT_BOSS_HP_LEVEL_BONUS.get("multiplier", 2.0)))
	if current_level >= start_level:
		return multiplier
	return 1.0

func _boss_survival_hp_mult(current_level: int, is_boss_enemy: bool, economy: Dictionary) -> float:
	if not is_boss_enemy:
		return 1.0
	var rule_var = economy.get("boss_survival_hp_ramp", DEFAULT_BOSS_SURVIVAL_HP_RAMP)
	var rule: Dictionary = rule_var if rule_var is Dictionary else DEFAULT_BOSS_SURVIVAL_HP_RAMP
	var start_level := float(rule.get("start_level", DEFAULT_BOSS_SURVIVAL_HP_RAMP.get("start_level", 50)))
	var full_level := float(rule.get("full_level", DEFAULT_BOSS_SURVIVAL_HP_RAMP.get("full_level", 98)))
	var max_mult := maxf(1.0, float(rule.get("max_mult", DEFAULT_BOSS_SURVIVAL_HP_RAMP.get("max_mult", 56.0))))
	var curve_power := maxf(0.01, float(rule.get("curve_power", DEFAULT_BOSS_SURVIVAL_HP_RAMP.get("curve_power", 1.15))))
	if float(current_level) < start_level:
		return 1.0
	var ramp_mult := max_mult
	if full_level > start_level:
		var t := clampf((float(current_level) - start_level) / (full_level - start_level), 0.0, 1.0)
		ramp_mult = lerpf(1.0, max_mult, pow(t, curve_power))
	var final_level := int(rule.get("final_level", DEFAULT_BOSS_SURVIVAL_HP_RAMP.get("final_level", 99)))
	if current_level >= final_level:
		ramp_mult *= maxf(1.0, float(rule.get("final_mult", DEFAULT_BOSS_SURVIVAL_HP_RAMP.get("final_mult", 1.08))))
	return ramp_mult

func _spawn_enemy(enemy_id: String, lane: String, is_boss := false, endless_boss_hp := 0.0, xp_budget_counted := false) -> void:
	_spawn_enemy_instance(enemy_id, _next_enemy_spawn_position(lane, is_boss), is_boss, 1.0, endless_boss_hp, xp_budget_counted)

func _next_enemy_spawn_position(lane: String, is_boss := false) -> Vector2:
	var bounds := _spawn_lane_x_bounds(lane, is_boss)
	if is_boss:
		var boss_position := Vector2(_combat_randf_range(bounds.x, bounds.y), 190.0)
		_remember_spawn_position(boss_position)
		return boss_position

	# Best-candidate (blue-noise style) sampling: take several genuinely random
	# positions, then keep the one farthest from recent births and enemies still
	# inside the entry band. It stays unpredictable across runs while preventing
	# the visually obvious piles produced by independent random samples.
	var best_position := Vector2(_combat_randf_range(bounds.x, bounds.y), _combat_randf_range(NORMAL_SPAWN_Y_BOUNDS.x, NORMAL_SPAWN_Y_BOUNDS.y))
	var has_blockers := not recent_spawn_positions.is_empty() or _has_live_entry_blockers()
	if has_blockers:
		var best_score := -INF
		for _candidate_index in range(SPAWN_CANDIDATE_COUNT):
			var candidate := Vector2(
				_combat_randf_range(bounds.x, bounds.y),
				_combat_randf_range(NORMAL_SPAWN_Y_BOUNDS.x, NORMAL_SPAWN_Y_BOUNDS.y)
			)
			var edge_clearance := minf(candidate.x - bounds.x, bounds.y - candidate.x)
			var previous_gap_bonus := 0.0
			if not recent_spawn_positions.is_empty():
				previous_gap_bonus = absf(candidate.x - recent_spawn_positions.back().x) * 0.72
			var score := _spawn_candidate_clearance(candidate) + previous_gap_bonus + edge_clearance * 0.08 + _combat_randf_range(-18.0, 18.0)
			if score > best_score:
				best_score = score
				best_position = candidate
	_remember_spawn_position(best_position)
	return best_position

func _spawn_lane_x_bounds(lane: String, is_boss: bool) -> Vector2:
	var table: Dictionary = BOSS_SPAWN_LANE_X_BOUNDS if is_boss else SPAWN_LANE_X_BOUNDS
	var normalized := lane if table.has(lane) else "spread"
	return table[normalized]

func _has_live_entry_blockers() -> bool:
	if not is_inside_tree() or not has_node("EnemyLayer"):
		return false
	for enemy in $EnemyLayer.get_children():
		if enemy is Node2D and (enemy as Node2D).global_position.y <= SPAWN_ENTRY_BLOCKER_MAX_Y:
			return true
	return false

func _spawn_candidate_clearance(candidate: Vector2) -> float:
	var clearance := INF
	for recent in recent_spawn_positions:
		clearance = minf(clearance, _spawn_visual_distance(candidate, recent))
	if is_inside_tree() and has_node("EnemyLayer"):
		for enemy in $EnemyLayer.get_children():
			if not (enemy is Node2D):
				continue
			var enemy_position := (enemy as Node2D).global_position
			if enemy_position.y > SPAWN_ENTRY_BLOCKER_MAX_Y:
				continue
			clearance = minf(clearance, _spawn_visual_distance(candidate, enemy_position))
	return clearance if clearance < INF else 0.0

func _spawn_visual_distance(left: Vector2, right: Vector2) -> float:
	var delta := left - right
	# Y jitter adds organic entry depth, but it must never disguise two enemies
	# that are still visually stacked along X on a portrait battlefield.
	return Vector2(delta.x, delta.y * 0.45).length()

func _remember_spawn_position(spawn_position: Vector2) -> void:
	recent_spawn_positions.append(spawn_position)
	while recent_spawn_positions.size() > SPAWN_RECENT_HISTORY:
		recent_spawn_positions.pop_front()

func _spawn_enemy_instance(enemy_id: String, spawn_position: Vector2, is_boss := false, reward_scale := 1.0, endless_boss_hp := 0.0, xp_budget_counted := false) -> Node:
	var row := DataLoader.get_row("bosses" if is_boss else "zombies", enemy_id).duplicate(true)
	var economy: Dictionary = DataLoader.get_table("economy")
	if is_endless_mode and is_boss:
		_apply_endless_boss_opening_grace(row, economy)
	var speed_mult := float(economy.get("ENEMY_SPEED_MULT", 1.0))
	if is_boss:
		speed_mult *= float(economy.get("BOSS_SPEED_MULT", 1.0))
	# Boss movement is part of its stable authored identity. Ordinary enemies
	# still receive the bounded card-pressure response, while the same Boss does
	# not walk faster merely because it reappears in a later level.
	if wave_index >= 3 and not is_boss:
		speed_mult *= run_skill_speed_pressure_mult
	if is_challenge_mode:
		speed_mult *= _challenge_mult("speed_mult")
	row["speed"] = float(row.get("speed", 80.0)) * speed_mult
	row["bd_coef"] = float(row.get("bd_coef", 1.0)) * _late_wave_damage_ramp_mult(economy)
	var enemy := ENEMY_SCENE.instantiate()
	enemy.position = spawn_position
	enemy.set_meta("reward_scale", clampf(reward_scale, 0.0, 1.0))
	enemy.set_meta("xp_budget_counted", xp_budget_counted)
	# Campaign Boss rows own an absolute durability budget. Endless Bosses replace
	# it with the generated loop budget share and never inherit campaign fixed_hp
	# or the mob-only endless compound multiplier.
	if is_endless_mode and is_boss and endless_boss_hp > 0.0:
		row["fixed_hp"] = endless_boss_hp
	var has_fixed_boss_hp := is_boss and float(row.get("fixed_hp", 0.0)) > 0.0
	var hp_level_coef := 1.0 if has_fixed_boss_hp else float(level.get("difficulty_coef", 1.0)) * float(level.get("base_hp_ref", 50)) / 50.0
	if is_boss:
		var stack_mult := _next_same_type_boss_hp_multiplier(enemy_id, economy)
		if not (is_endless_mode and endless_boss_hp > 0.0):
			hp_level_coef *= stack_mult
	if not has_fixed_boss_hp:
		# Optional authored per-wave durability sits inside the existing mob HP
		# chain. Missing data is exactly neutral; fixed-HP campaign Boss identity
		# remains outside this chain by design.
		hp_level_coef *= _wave_hp_coef(wave_index)
		hp_level_coef *= _late_wave_hp_bonus(wave_index, is_boss, economy)
		hp_level_coef *= _boss_level_hp_bonus(level_ordinal, is_boss, economy)
		hp_level_coef *= _boss_survival_hp_mult(level_ordinal, is_boss, economy)
	if is_endless_mode and not is_boss:
		hp_level_coef *= endless_difficulty_mult
	if is_challenge_mode:
		hp_level_coef *= _challenge_mult("hp_mult", CHALLENGE_HP_MULT)
	if _audit_combat_rng != null and enemy.has_method("set_audit_combat_seed"):
		enemy.call("set_audit_combat_seed", _next_audit_enemy_seed())
	if _audit_combat_rng != null:
		_audit_enemy_spawn_sequence += 1
		enemy.set_meta("audit_spawn_index", _audit_enemy_spawn_sequence)
		enemy.process_physics_priority = 1000 + _audit_enemy_spawn_sequence
		enemy.set_physics_process(false)
	enemy.setup(row, hp_level_coef, is_boss)
	if enemy.has_method("configure_attack_line"):
		enemy.call("configure_attack_line", BREACH_Y)
	enemy.hit_feedback.connect(_on_enemy_hit_feedback)
	enemy.damage_dealt.connect(_on_enemy_damage_dealt)
	enemy.died.connect(_on_enemy_died)
	enemy.breached.connect(_on_enemy_breached)
	enemy.base_attack_started.connect(_on_enemy_base_attack_started)
	enemy.base_attack_visual_hit.connect(_on_enemy_base_attack_visual_hit)
	if is_boss and (active_boss == null or not is_instance_valid(active_boss)):
		active_boss = enemy
	if is_boss:
		battle_last_boss_id = enemy_id
	$EnemyLayer.add_child(enemy)
	if wave_clear_fast_forward_enabled:
		# A fresh live enemy invalidates any earlier "field went empty" moment
		# recorded for this wave; see `_wave_clear_fast_forward_clear_at`.
		_wave_clear_fast_forward_clear_at = -1.0
	_activate_audit_physics_node(enemy)
	$ThreatMarkerLayer.add_child(enemy.threat_marker)
	enemy.tree_exiting.connect(_on_enemy_tree_exiting.bind(enemy))
	enemy.threat_marker.position = enemy.global_position + Vector2(0, -90 if not is_boss else -160)
	_spawn_enemy_entry_vfx(enemy, is_boss)
	return enemy

func _wave_hp_coef(current_wave: int) -> float:
	var waves_var: Variant = level.get("waves", [])
	if not waves_var is Array:
		return 1.0
	var waves := waves_var as Array
	var index := current_wave - 1
	if index < 0 or index >= waves.size() or not waves[index] is Dictionary:
		return 1.0
	return maxf(float((waves[index] as Dictionary).get("hp_coef", 1.0)), 0.01)

func _next_same_type_boss_hp_multiplier(enemy_id: String, economy: Dictionary) -> float:
	var copy_index := int(boss_spawn_counts.get(enemy_id, 0))
	boss_spawn_counts[enemy_id] = copy_index + 1
	return _same_type_boss_hp_multiplier(enemy_id, copy_index, economy)

func _same_type_boss_hp_multiplier(enemy_id: String, copy_index: int, economy: Dictionary) -> float:
	# Campaign quantity is literal: every copy has the model's authored fixed_hp.
	# Endless retains the sequence solely to distribute its generated loop budget.
	if not is_endless_mode:
		return 1.0
	var pacing_var: Variant = economy.get("boss_pacing", {})
	var pacing: Dictionary = pacing_var if pacing_var is Dictionary else {}
	var start_level := maxi(int(pacing.get("same_type_hp_start_level", 11)), 1)
	if int(level.get("id", "level_001").trim_prefix("level_")) < start_level:
		return 1.0
	var values_var: Variant = pacing.get("same_type_hp_multipliers", [1.0])
	var values: Array = values_var if values_var is Array else [1.0]
	if values.is_empty():
		return 1.0
	return maxf(float(values[mini(copy_index, values.size() - 1)]), 0.01)

func _apply_endless_boss_opening_grace(row: Dictionary, economy: Dictionary) -> void:
	var grace_loops := maxi(0, int(economy.get("endless_boss_resistance_grace_loops", 1)))
	if endless_loop >= grace_loops:
		return
	row["resistances"] = {}
	row["immune"] = []
	if str(row.get("mechanic", "")) == "armor_break":
		var params_var = row.get("mechanic_params", {})
		var params: Dictionary = params_var.duplicate(true) if params_var is Dictionary else {}
		var cap := maxi(0, int(economy.get("endless_first_loop_armor_hits_cap", 8)))
		if cap > 0:
			params["armor_hits"] = mini(int(params.get("armor_hits", cap)), cap)
		row["mechanic_params"] = params

func _process_enemy_mechanics(delta: float, enemies: Array = []) -> void:
	var candidates := enemies if not enemies.is_empty() else $EnemyLayer.get_children()
	_process_threat_feedback(candidates)
	for enemy in candidates:
		if is_instance_valid(enemy):
			enemy.speed_mult = 1.0
			enemy.external_damage_mult = 1.0
	for source in candidates:
		if not is_instance_valid(source):
			continue
		_process_boss_phase_feedback(source)
		match str(source.mechanic):
			"basic", "tank":
				pass
			"buff_aura":
				_apply_speed_aura(source, candidates)
				_process_aura_feedback(source, "buff_aura", delta)
			"shield_aura", "ward":
				_apply_damage_reduction_aura(source, candidates)
				_process_aura_feedback(source, str(source.mechanic), delta)
			"summon":
				_process_summoner(source, delta)
			"ranged_spit":
				_process_ranged_pressure(source, delta)
			"toxic_cloud":
				_process_toxic_cloud_pressure(source, delta)
			"runner":
				_process_runner_skill(source, delta)
			"leap":
				_process_leap_skill(source, delta)
			"charge":
				_process_charge_skill(source, delta)
			"juggernaut":
				_process_juggernaut_pressure(source, delta)
			"phase":
				_process_phase_enemy_skill(source, delta)
			"regen":
				_process_regen_feedback(source, delta)
			"mutate":
				_process_mutation(source)
			"enrage":
				_process_enrage_feedback(source)
			"armor", "low_profile":
				_process_passive_enemy_feedback(source, delta)
			"phase_burn":
				_process_boss_pressure(source, delta, 4.2, 0.42, "熔火压制", Color(1.0, 0.34, 0.12))
			"freeze_field":
				_process_freeze_field(source, candidates, delta)
			"storm_chain":
				_process_boss_pressure(source, delta, 3.6, 0.36, "雷暴连锁", Color(0.56, 0.92, 1.0))
			"spawn_minions":
				_process_boss_minions(source, delta)
			"phase_shift":
				_process_phase_shift(source, delta)
			"regenerate":
				_process_boss_pressure(source, delta, 5.8, 0.28, "腐化再生", Color(0.48, 1.0, 0.32))
			"multi_phase":
				_process_apex_pressure(source, candidates, delta)

func _apply_speed_aura(source: Node, enemies: Array) -> void:
	var radius := float(source.mechanic_params.get("radius", 260.0))
	var radius_squared := radius * radius
	var speed_boost := float(source.mechanic_params.get("speed_mult", 1.18))
	for enemy in enemies:
		if enemy == source or not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_squared_to(source.global_position) <= radius_squared:
			# 取全场最强的单个光环效果，而不是按范围内光环源数量连乘——密集刷同类
			# 光环怪(如成群守护者)聚在一起时，连乘会指数级失控。
			enemy.speed_mult = maxf(enemy.speed_mult, speed_boost)

func _apply_damage_reduction_aura(source: Node, enemies: Array) -> void:
	var radius := float(source.mechanic_params.get("radius", 280.0))
	var radius_squared := radius * radius
	var damage_mult := float(source.mechanic_params.get("damage_taken_mult", 0.72))
	for enemy in enemies:
		if enemy == source or not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_squared_to(source.global_position) <= radius_squared:
			# 同上：减伤取全场最强单个光环，不按范围内光环源数量连乘。此前连乘在
			# 守护者刷成一整群、互相都在彼此 320 半径内时会把承伤压到 0.66^N，
			# 群怪聚集(如第38关第3波)时几乎变成打不死，这是真实的"无敌"bug而非设计如此。
			enemy.external_damage_mult = minf(enemy.external_damage_mult, damage_mult)

func _enemy_mechanic_timer_ready(source: Node, key: String, delta: float, interval: float, jitter := 0.0, initial_delay := 0.4) -> bool:
	var meta_key := "mechanic_timer_%s" % key
	var remaining := initial_delay
	if source.has_meta(meta_key):
		remaining = float(source.get_meta(meta_key))
	remaining -= delta
	if remaining > 0.0:
		source.set_meta(meta_key, remaining)
		return false
	source.set_meta(meta_key, maxf(0.15, interval + _combat_randf_range(0.0, jitter)))
	return true

func _enemy_skill_damage(source: Node, scale: float, minimum := 1.0) -> int:
	var breach_damage := float(source.breach_damage)
	# A model-level bd_coef of zero is an explicit "no base damage" contract.
	# Do not let the generic minimum chip damage silently override that data.
	if breach_damage <= 0.0:
		return 0
	var raw := maxf(minimum, breach_damage * scale)
	return maxi(0, int(ceil(raw * breach_damage_mult * _challenge_mult("breach_damage_mult"))))

func _base_line_y() -> float:
	return BREACH_Y

func _pet_anchor_position() -> Vector2:
	return Vector2(PET_BASE_X_DESIGN, _base_line_y() + PET_BASE_LINE_OFFSET)

func _pet_combat_origin() -> Vector2:
	# Preserve the shipped runtime origin exactly. The deterministic probe uses
	# the authored anchor because its presentation process is intentionally off.
	if _audit_combat_rng != null:
		return to_global(_pet_anchor_position())
	return pet_sprite.global_position

func _base_line_inner_y(offset: float) -> float:
	return _base_line_y() - offset

func _base_damage_impact_position(x: float) -> Vector2:
	return Vector2(clampf(x, 96.0, 984.0), _base_line_y())

func _slow_field_inner_offset_for_level(slow_level: int) -> float:
	var row: Dictionary = DataLoader.get_row("skills", "skill_slow_field")
	for entry_var in row.get("levels", []):
		if not entry_var is Dictionary:
			continue
		var entry: Dictionary = entry_var
		if int(entry.get("lv", 0)) != slow_level:
			continue
		var effect: Dictionary = entry.get("effect", {})
		var y_min := float(effect.get("y_min", SkillRuntime.SLOW_FIELD_DESIGN_BASE_LINE_Y - BASE_LINE_DEFAULT_SLOW_FIELD_INSET))
		return maxf(0.0, SkillRuntime.SLOW_FIELD_DESIGN_BASE_LINE_Y - y_min)
	return BASE_LINE_DEFAULT_SLOW_FIELD_INSET

func _slow_field_strength_for_level(slow_level: int) -> float:
	var row: Dictionary = DataLoader.get_row("skills", "skill_slow_field")
	for entry_var in row.get("levels", []):
		if not entry_var is Dictionary:
			continue
		var entry: Dictionary = entry_var
		if int(entry.get("lv", 0)) == slow_level:
			return clampf(float(entry.get("effect", {}).get("slow", 0.0)), 0.0, 0.8)
	return 0.0

func _slow_field_min_y_for_level(slow_level: int) -> float:
	return _base_line_inner_y(_slow_field_inner_offset_for_level(slow_level))

func _apply_enemy_skill_base_damage(
	source: Node,
	damage: int,
	label: String,
	color: Color,
	target_position: Vector2,
	impact_sfx_id := "enemy_breach"
) -> void:
	if battle_finished:
		return
	var impact_position := _base_damage_impact_position(target_position.x)
	var final_damage := maxi(0, damage)
	final_damage = mini(final_damage, maxi(1, int(round(float(base_hp_max) * MAX_BASE_HIT_FRACTION))))  # 防秒杀
	var preventable_damage := final_damage
	var shield_absorbed := false
	if final_damage > 0 and breach_shields + skill_barriers_left > 0:
		if breach_shields > 0:
			breach_shields -= 1
		else:
			skill_barriers_left -= 1
		final_damage = 0
		shield_absorbed = true
	if is_instance_valid(source) and not _boss_has_profiled_base_attack(source):
		_spawn_breach_attack_vfx(source, shield_absorbed)
	if shield_absorbed:
		battle_base_damage_prevented += preventable_damage
		_spawn_barrier_break_vfx(impact_position)
		AudioManager.play_enemy_sfx("hit_immune", -8.0, 0.02)
		_update_barrier_visual()
		_spawn_float_text(impact_position, "格挡", Color(0.64, 0.9, 1.0))
		return
	if final_damage <= 0:
		return
	if not impact_sfx_id.is_empty():
		AudioManager.play_enemy_sfx(impact_sfx_id, -5.5, 0.025)
	base_hp = max(base_hp - final_damage, 0)
	battle_base_damage_taken += final_damage
	_apply_apocalypse_armor_counter(source, final_damage, impact_position)
	_show_screen_flash(Color(color.r, color.g, color.b, 0.08), 0.12)
	_spawn_float_text(impact_position, "-%d %s" % [final_damage, label], color)
	_check_low_hp_warning()
	if base_hp <= 0:
		_finish(false)

func _process_aura_feedback(source: Node, kind: String, delta: float) -> void:
	var interval := float(source.mechanic_params.get("pulse_interval", 2.6))
	if not _enemy_mechanic_timer_ready(source, "aura_feedback", delta, interval, 0.35, 0.6):
		return
	var radius := float(source.mechanic_params.get("radius", 280.0))
	var color := _attack_color_for_mechanic(kind)
	var label := "加速" if kind == "buff_aura" else "护盾" if kind == "shield_aura" else "守护"
	if source.has_method("play_special"):
		source.play_special(0.28)
	_play_enemy_mechanic_sfx(source, -7.0, 0.02)
	_spawn_enemy_attack_vfx(source, kind, source.global_position + Vector2(0, -42.0))
	_spawn_attack_ring(source.global_position, radius, color, 0.34)
	_spawn_float_text(source.global_position + Vector2(0, -118.0), label, color)

func _process_runner_skill(source: Node, delta: float) -> void:
	if source.global_position.y < float(source.mechanic_params.get("dash_y", 680.0)):
		return
	var interval := float(source.mechanic_params.get("dash_interval", 3.4))
	if not _enemy_mechanic_timer_ready(source, "runner_dash", delta, interval, 0.35, 0.7):
		return
	var advance := float(source.mechanic_params.get("dash_advance", 54.0))
	_advance_enemy_with_skill(source, "runner_dash", advance, "突进", Color(1.0, 0.88, 0.24), float(source.mechanic_params.get("damage_coef", 0.08)))

func _process_leap_skill(source: Node, delta: float) -> void:
	if source.global_position.y < float(source.mechanic_params.get("trigger_y", 650.0)):
		return
	var interval := float(source.mechanic_params.get("leap_interval", 3.1))
	if not _enemy_mechanic_timer_ready(source, "leap", delta, interval, 0.35, 0.55):
		return
	var advance := float(source.mechanic_params.get("leap_advance", 82.0))
	_advance_enemy_with_skill(source, "leap_strike", advance, "跃击", Color(1.0, 0.82, 0.18), float(source.mechanic_params.get("damage_coef", 0.1)))

func _process_charge_skill(source: Node, delta: float) -> void:
	if source.global_position.y < float(source.mechanic_params.get("trigger_y", 660.0)):
		return
	var interval := float(source.mechanic_params.get("charge_interval", 3.8))
	if not _enemy_mechanic_timer_ready(source, "charge", delta, interval, 0.5, 0.65):
		return
	var advance := float(source.mechanic_params.get("charge_advance", 116.0))
	_advance_enemy_with_skill(source, "charge", advance, "冲撞", Color(1.0, 0.5, 0.16), float(source.mechanic_params.get("damage_coef", 0.18)))

func _process_phase_enemy_skill(source: Node, delta: float) -> void:
	var interval := float(source.mechanic_params.get("blink_interval", 4.0))
	if not _enemy_mechanic_timer_ready(source, "phase_blink", delta, interval, 0.55, 0.85):
		return
	var advance := float(source.mechanic_params.get("blink_advance", 74.0))
	_advance_enemy_with_skill(source, "phase", advance, "相位", Color(0.62, 0.82, 1.0), float(source.mechanic_params.get("damage_coef", 0.08)))

func _enemy_advance_warning_sfx(_kind: String) -> String:
	# Every advance already owns one movement/action cue. Defense proximity has
	# its own global warning route, so a dash/leap/blink must never add a second
	# generic alarm on the same frame.
	return ""

func _enemy_skill_base_impact_sfx(kind: String) -> String:
	# A phase slip can damage the line without making physical contact. Keep its
	# wind cue, damage flash and floating text, but do not fake a steel/sandbag hit.
	return "" if kind == "phase" else "enemy_breach"

func _enemy_advance_reaches_base(old_y: float) -> bool:
	# Advance skills may start far up-lane. Only an action that began inside the
	# authored base-pressure band is allowed to request base damage/contact audio.
	return old_y >= _base_line_inner_y(BASE_LINE_DEFAULT_SLOW_FIELD_INSET)

func _advance_enemy_with_skill(source: Node, kind: String, advance: float, label: String, color: Color, damage_scale: float) -> void:
	if source.has_method("play_special"):
		source.play_special(0.32)
	_play_enemy_mechanic_sfx(source, -7.5, 0.025)
	var old_position: Vector2 = source.global_position
	var old_y := float(old_position.y)
	var cap_y := float(source.attack_line_y) - 18.0
	source.global_position.y = minf(cap_y, old_y + advance)
	var travel_direction: Vector2 = source.global_position - old_position
	_spawn_enemy_attack_vfx(source, kind, source.global_position + Vector2(0, -36.0), travel_direction)
	_spawn_attack_telegraph(source.global_position + Vector2(0, 74.0), Color(color.r, color.g, color.b, 0.24), label)
	var warning_sfx_id := _enemy_advance_warning_sfx(kind)
	if not warning_sfx_id.is_empty():
		AudioManager.play_sfx(warning_sfx_id, -7.0, 0.02)
	if _enemy_advance_reaches_base(old_y):
		var damage := _enemy_skill_damage(source, damage_scale, 1.0)
		_apply_enemy_skill_base_damage(
			source,
			damage,
			label,
			color,
			_base_damage_impact_position(source.global_position.x),
			_enemy_skill_base_impact_sfx(kind)
		)

func _process_toxic_cloud_pressure(source: Node, delta: float) -> void:
	if source.global_position.y < float(source.mechanic_params.get("trigger_y", 760.0)):
		return
	var interval := float(source.mechanic_params.get("cloud_interval", 4.8))
	if not _enemy_mechanic_timer_ready(source, "toxic_cloud", delta, interval, 0.55, 0.8):
		return
	if source.has_method("play_special"):
		source.play_special(0.42)
	var damage := _enemy_skill_damage(source, float(source.mechanic_params.get("damage_coef", 0.22)), 2.0)
	var impact := _base_damage_impact_position(source.global_position.x)
	_spawn_attack_telegraph(impact, Color(0.42, 1.0, 0.24, 0.32), "毒雾")
	_spawn_enemy_attack_vfx(source, "toxic_cloud", source.global_position + Vector2(0, -52.0))
	_spawn_attack_ring(source.global_position, float(source.mechanic_params.get("radius", 190.0)), Color(0.42, 1.0, 0.24, 0.28), 0.42)
	_spawn_enemy_cast_bolt(source.global_position + Vector2(0, -30.0), impact, Color(0.52, 1.0, 0.3), "poison", false)
	_apply_enemy_skill_base_damage(source, damage, "毒雾", Color(0.56, 1.0, 0.32), impact)

func _process_juggernaut_pressure(source: Node, delta: float) -> void:
	if source.global_position.y < float(source.mechanic_params.get("shock_y", 900.0)):
		_process_passive_enemy_feedback(source, delta)
		return
	var interval := float(source.mechanic_params.get("shock_interval", 5.6))
	if not _enemy_mechanic_timer_ready(source, "juggernaut_shock", delta, interval, 0.55, 0.9):
		return
	if source.has_method("play_special"):
		source.play_special(0.46)
	var color := Color(0.96, 0.72, 0.42)
	_spawn_enemy_attack_vfx(source, "juggernaut", source.global_position + Vector2(0, -42.0))
	_spawn_attack_ring(source.global_position + Vector2(0, 70.0), 230.0, Color(color.r, color.g, color.b, 0.28), 0.38)
	var impact := _base_damage_impact_position(source.global_position.x)
	_spawn_attack_telegraph(impact, Color(color.r, color.g, color.b, 0.26), "震地")
	var damage := _enemy_skill_damage(source, float(source.mechanic_params.get("damage_coef", 0.16)), 2.0)
	_apply_enemy_skill_base_damage(source, damage, "震地", color, impact)

func _process_regen_feedback(source: Node, delta: float) -> void:
	if float(source.hp) >= float(source.max_hp) * 0.98:
		return
	var interval := float(source.mechanic_params.get("pulse_interval", 3.0))
	if not _enemy_mechanic_timer_ready(source, "regen_feedback", delta, interval, 0.4, 0.9):
		return
	if source.has_method("play_special"):
		source.play_special(0.42)
	var color := Color(0.48, 1.0, 0.32)
	_spawn_enemy_attack_vfx(source, "regen", source.global_position + Vector2(0, -48.0))
	_spawn_attack_ring(source.global_position, 150.0, Color(color.r, color.g, color.b, 0.24), 0.34)
	_spawn_float_text(source.global_position + Vector2(0, -118.0), "再生", color)
	AudioManager.play_enemy_sfx("zombie_regenerator", -8.0, 0.025)

func _process_mutation(source: Node) -> void:
	if source.has_meta("mutated"):
		return
	if float(source.max_hp) <= 0.0:
		return
	var trigger := float(source.mechanic_params.get("trigger_hp_ratio", 0.48))
	if float(source.hp) / float(source.max_hp) > trigger:
		return
	source.set_meta("mutated", true)
	source.speed *= float(source.mechanic_params.get("speed_mult", 1.18))
	source.breach_damage = int(round(float(source.breach_damage) * float(source.mechanic_params.get("damage_mult", 1.22))))
	source.hp = minf(float(source.max_hp), float(source.hp) + float(source.max_hp) * float(source.mechanic_params.get("heal_ratio", 0.12)))
	if source.has_method("play_special"):
		source.play_special(0.5)
	if source.has_method("_update_hp_bar"):
		source.call("_update_hp_bar")
	_spawn_enemy_attack_vfx(source, "mutate", source.global_position + Vector2(0, -62.0))
	_spawn_attack_ring(source.global_position, 210.0, Color(0.88, 0.34, 1.0, 0.28), 0.42)
	_spawn_float_text(source.global_position + Vector2(0, -132.0), "突变", Color(0.92, 0.45, 1.0))
	AudioManager.play_enemy_sfx("zombie_mutant", -6.0, 0.02)

func _process_enrage_feedback(source: Node) -> void:
	if not bool(source.enrage_triggered) or source.has_meta("enrage_feedback_done"):
		return
	source.set_meta("enrage_feedback_done", true)
	if source.has_method("play_special"):
		source.play_special(0.42)
	_spawn_enemy_attack_vfx(source, "enrage", source.global_position + Vector2(0, -52.0))
	_spawn_attack_ring(source.global_position, 185.0, Color(1.0, 0.32, 0.16, 0.3), 0.36)
	_spawn_float_text(source.global_position + Vector2(0, -124.0), "狂暴", Color(1.0, 0.32, 0.16))
	AudioManager.play_enemy_sfx("zombie_berserker", -6.5, 0.02)

func _process_passive_enemy_feedback(source: Node, delta: float) -> void:
	var interval := float(source.mechanic_params.get("pulse_interval", 3.8))
	if not _enemy_mechanic_timer_ready(source, "passive_feedback", delta, interval, 0.55, 1.1):
		return
	var kind := str(source.mechanic)
	var color := _attack_color_for_mechanic(kind)
	_spawn_enemy_attack_vfx(source, kind, source.global_position + Vector2(0, -42.0))
	if kind == "armor":
		_spawn_float_text(source.global_position + Vector2(0, -116.0), "装甲", color)
	elif kind == "low_profile":
		_spawn_float_text(source.global_position + Vector2(0, -98.0), "潜行", color)

func _process_summoner(source: Node, delta: float) -> void:
	source.mechanic_timer -= delta
	if source.mechanic_timer > 0.0:
		return
	var interval := float(source.mechanic_params.get("skill_interval", 5.0))
	source.mechanic_timer = _combat_randf_range(interval, interval + 1.2)
	var spawn_position: Vector2 = source.global_position + Vector2(_combat_randf_range(-75, 75), _combat_randf_range(-35, 45))
	spawn_position.x = clampf(spawn_position.x, 120.0, 960.0)
	spawn_position.y = clampf(spawn_position.y, 190.0, 1220.0)
	if source.has_method("play_special"):
		source.play_special(0.54)
	_spawn_enemy_attack_vfx(source, "summon", spawn_position)
	_spawn_enemy_instance(str(source.mechanic_params.get("summon_id", "zombie_shambler")), spawn_position, false, 0.0)
	AudioManager.play_enemy_sfx("zombie_necromancer", -6.0, 0.02)
	_spawn_float_text(source.global_position + Vector2(0, -86), "召唤", Color(0.72, 0.4, 1.0))

func _process_ranged_pressure(source: Node, delta: float) -> void:
	if source.global_position.y < float(source.mechanic_params.get("trigger_y", 720.0)):
		return
	source.mechanic_timer -= delta
	if source.mechanic_timer > 0.0:
		return
	var interval := float(source.mechanic_params.get("skill_interval", 4.2))
	source.mechanic_timer = _combat_randf_range(interval, interval + 0.9)
	if source.has_method("play_special"):
		source.play_special(0.46)
	var spit_damage := _enemy_skill_damage(source, float(source.mechanic_params.get("damage_coef", 0.35)), 2.0)
	var target_position := _base_damage_impact_position(source.global_position.x)
	_spawn_attack_telegraph(target_position, Color(0.46, 1.0, 0.25, 0.34), "腐蚀")
	_spawn_spit_attack_vfx(source, target_position)
	_apply_enemy_skill_base_damage(source, spit_damage, "腐蚀", Color(0.56, 1.0, 0.32), target_position)

func _process_boss_pressure(source: Node, delta: float, interval: float, damage_scale: float, label: String, color: Color) -> void:
	if source.global_position.y < 560.0:
		return
	source.mechanic_timer -= delta
	if source.mechanic_timer > 0.0:
		return
	source.mechanic_timer = _combat_randf_range(interval, interval + 1.4)
	if source.has_method("play_special"):
		source.play_special()
	var pressure_damage := _enemy_skill_damage(source, damage_scale, 3.0)
	var impact := _base_damage_impact_position(source.global_position.x)
	_spawn_attack_telegraph(impact, Color(color.r, color.g, color.b, 0.34), label)
	_spawn_boss_attack_vfx(source, label, color, impact)
	_apply_enemy_skill_base_damage(source, pressure_damage, label, color, impact)

func _process_freeze_field(source: Node, enemies: Array, delta: float) -> void:
	if source.global_position.y < 520.0:
		return
	for enemy in enemies:
		if enemy != source and is_instance_valid(enemy):
			enemy.speed_mult *= 0.88
	source.mechanic_timer -= delta
	if source.mechanic_timer > 0.0:
		return
	source.mechanic_timer = _combat_randf_range(5.0, 6.6)
	if source.has_method("play_special"):
		source.play_special()
	_spawn_float_text(source.global_position + Vector2(0, -120), "寒潮领域", Color(0.45, 0.86, 1.0))
	var impact := _base_damage_impact_position(source.global_position.x)
	_spawn_attack_telegraph(impact, Color(0.45, 0.86, 1.0, 0.32), "寒潮")
	_spawn_boss_attack_vfx(source, "寒潮领域", Color(0.45, 0.86, 1.0), impact)
	var frost_damage := _enemy_skill_damage(source, 0.24, 2.0)
	_apply_enemy_skill_base_damage(source, frost_damage, "寒潮", Color(0.45, 0.86, 1.0), impact)

func _process_boss_minions(source: Node, delta: float) -> void:
	source.mechanic_timer -= delta
	if source.mechanic_timer > 0.0:
		return
	source.mechanic_timer = _combat_randf_range(5.5, 7.2)
	if source.has_method("play_special"):
		source.play_special(0.58)
	for offset in [-92.0, 0.0, 92.0]:
		var spawn_position: Vector2 = source.global_position + Vector2(offset, 32.0)
		spawn_position.x = clampf(spawn_position.x, 120.0, 960.0)
		spawn_position.y = clampf(spawn_position.y, 220.0, 1180.0 + bottom_dock_shift)
		_spawn_enemy_attack_vfx(source, "spawn_minions", spawn_position)
		_spawn_enemy_instance("zombie_crawler", spawn_position, false, 0.0)
	AudioManager.play_enemy_sfx("zombie_necromancer", -6.0, 0.02)
	_spawn_float_text(source.global_position + Vector2(0, -130), "孵化尸群", Color(0.66, 1.0, 0.3))

func _process_phase_shift(source: Node, delta: float) -> void:
	source.mechanic_timer -= delta
	if source.mechanic_timer <= 0.0:
		source.mechanic_timer = _combat_randf_range(2.4, 3.4)
		if source.has_method("play_special"):
			source.play_special(0.34)
		AudioManager.play_enemy_sfx("zombie_phantom", -6.5, 0.02)
		var old_position: Vector2 = source.global_position
		source.global_position.y = min(source.global_position.y + 86.0, _base_line_inner_y(60.0))
		_spawn_enemy_attack_vfx(source, "phase_shift", source.global_position, source.global_position - old_position)
		_spawn_float_text(source.global_position + Vector2(0, -130), "相位突进", Color(0.62, 0.82, 1.0))

func _process_apex_pressure(source: Node, enemies: Array, delta: float) -> void:
	var hp_ratio: float = source.hp / source.max_hp if source.max_hp > 0.0 else 0.0
	if hp_ratio < 0.67:
		_apply_damage_reduction_aura(source, enemies)
	if hp_ratio < 0.34:
		_apply_speed_aura(source, enemies)
	_process_boss_pressure(source, delta, 4.8 if hp_ratio >= 0.34 else 3.4, 0.32 if hp_ratio >= 0.34 else 0.48, "终局威压", Color(1.0, 0.25, 0.25))

func _process_boss_phase_feedback(source: Node) -> void:
	if not bool(source.boss):
		return
	if float(source.max_hp) <= 0.0:
		return
	if str(source.mechanic) == "armor_break" and bool(source.armor_broken) and not source.has_meta("armor_break_announced"):
		source.set_meta("armor_break_announced", true)
		_announce_boss_phase(source, "护甲破裂", Color(1.0, 0.42, 0.22, 1.0))
	var hp_ratio: float = float(source.hp) / float(source.max_hp)
	var cues: Array = source.data.get("phase_cues", []) if source.data is Dictionary else []
	if cues.is_empty():
		cues = [
			{"threshold": 0.67, "text": "进入二阶段", "color": "ffb83d"},
			{"threshold": 0.34, "text": "三阶段狂暴", "color": "ff2e1f"},
		]
	for index in range(cues.size() - 1, -1, -1):
		var cue_var: Variant = cues[index]
		if not cue_var is Dictionary:
			continue
		var cue: Dictionary = cue_var
		var meta_key := "boss_phase_cue_%d_announced" % index
		if hp_ratio <= float(cue.get("threshold", 0.0)) and not source.has_meta(meta_key):
			source.set_meta(meta_key, true)
			_announce_boss_phase(source, LocalizationManager.text(str(cue.get("text", "阶段转换"))), Color.from_string(str(cue.get("color", "ffb83d")), Color(1.0, 0.72, 0.24, 1.0)))
			break

func _announce_boss_phase(source: Node, text: String, color: Color) -> void:
	if not is_instance_valid(source):
		return
	if source.has_method("play_special"):
		source.play_special(0.54)
	AudioManager.play_enemy_sfx("threat_warning", -3.0, 0.02)
	var phase_label := "Boss · %s" % text if LocalizationManager.is_english() else "首领 · %s" % text
	_show_wave_toast(phase_label, color)
	_spawn_float_text(source.global_position + Vector2(0, -180), text, color)
	var phase_sequence := "vfx_enemy_skill_%s" % str(source.mechanic)
	_spawn_vfx_sequence(
		phase_sequence,
		source.global_position + Vector2(0, -78),
		1.35,
		Color(1.0, 1.0, 1.0, 0.96),
		1.06,
		_directional_vfx_rotation(phase_sequence, Vector2.DOWN, randf_range(-0.1, 0.1)),
		1.1,
		Vector2(0, -18),
		randf_range(-0.14, 0.14),
		true
	)
	_spawn_attack_ring(source.global_position + Vector2(0, -40), 230.0, Color(color.r, color.g, color.b, 0.28), 0.32)
	_show_screen_flash(Color(color.r, color.g, color.b, 0.14), 0.22)

func _on_turret_fired(origin: Vector2, direction: Vector2) -> void:
	_sync_logic_turret_to_character()
	direction = _weapon_fire_direction(direction)
	if character_weapon_combo_active and turret != null:
		_set_character_combo_aim_from_target(turret.target_point)
	else:
		_set_character_combo_aim_from_direction(direction)
	# Bind gameplay contact to the authored ignition pose before resolving the
	# muzzle. The projectile remains instantaneous; only the preceding brace
	# and following recoil are visual anticipation/follow-through.
	_play_character_attack()
	origin = _weapon_fire_origin()
	direction = _weapon_fire_direction(direction)
	var mods := skills.projectile_mods()
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var special: Dictionary = weapon.get("special", {})
	var multishot_lanes := 1 + int(mods.get("extra_projectiles", 0))
	if sig_vanguard_barrage_timer > 0.0:
		multishot_lanes += 1
		if _growth_rank(character_level) >= 2:
			multishot_lanes += 1
	multishot_lanes = clampi(multishot_lanes, 1, MAX_MULTISHOT_LANES)
	var pellet_count := maxi(1, int(special.get("pellets", 1)))
	var lane_spread := deg_to_rad(float(mods.get("spread_deg", 0.0)))
	var pellet_spread := deg_to_rad(float(special.get("spread", 0.0)))
	var homing: float = float(mods.get("homing", 0)) * 1.8
	var base_element := str(weapon.get("element", "physical"))
	var element: String = skills.projectile_element(base_element, weapon_id)
	var chain_count := _resolved_chain_count(element, mods, special)
	var visual_profile := _resolved_weapon_projectile_visual_profile(
		base_element,
		element,
		_weapon_visual_profile(weapon_id),
	)
	homing += _character_homing_bonus(element)
	AudioManager.play_sfx(_weapon_shot_sfx(weapon_id), -7.0)
	if element != "physical":
		AudioManager.play_sfx(_element_muzzle_sfx(element), -10.0, 0.025)
	if multishot_lanes > 1 and skills.level("skill_multishot") > 0:
		AudioManager.play_sfx("skill_multishot", -11.0, 0.025)
	if skills.level("skill_salvo") > 0 and randf() < 0.12:
		AudioManager.play_sfx("skill_salvo", -12.0, 0.025)
	if element == primary_weakness and randf() < 0.08:
		_spawn_float_text(origin + Vector2(-120, -80), "弱点装填", Color(1.0, 0.86, 0.32))
	if weapon_level >= 15 and randf() < 0.08:
		_spawn_weapon_power_ring(origin, element)
	_spawn_muzzle_flash(origin, direction, element, visual_profile)
	_pulse_character_theme_material()
	_spawn_character_theme_fire_signature(origin, direction, element)
	var base_damage: float = 28.0 * float(weapon.get("base_atk_coef", 1.0)) * _player_shot_damage_multiplier()
	base_damage *= _fire_rate_shot_damage_compensation()
	base_damage *= _weapon_profile_endgame_damage_multiplier(weapon)
	var pierce: int = int(mods.get("pierce", 0)) + pierce_bonus + int(special.get("pierce", 0)) + _character_pierce_bonus(element)
	if sig_vanguard_barrage_timer > 0.0:
		pierce += 1
	var split: int = int(mods.get("split", 0)) + int(special.get("split", 0))
	var splash: float = maxf(float(special.get("splash", 0.0)), _character_splash_bonus(element))
	var cloud: float = float(special.get("cloud", 0.0))
	var lane_directions := _primary_shot_directions(origin, direction, multishot_lanes, lane_spread)
	var shot_directions := _lane_pellet_directions(lane_directions, pellet_count, pellet_spread)
	var shots := shot_directions.size()
	var visual_scale := _projectile_visual_scale(shots, pierce, split, homing, splash, cloud)
	var lane_damage_mult := _multishot_damage_multiplier(
		multishot_lanes,
		float(mods.get("multishot_lane_damage_bonus", 0.0)),
	)
	var armor_penetration := skills.armor_penetration()
	var status_strength := skills.projectile_status_strength(element)
	if visual_profile == "apocalypse_inferno":
		var burn_ratio := float(special.get("burn_ratio", 0.38)) * (1.0 + _chip_value("burn_efficiency"))
		var inferno_set := DataLoader.get_row("premium_sets", str(weapon.get("premium_set", "")))
		if _premium_set_piece_count(str(weapon.get("premium_set", ""))) >= 2:
			burn_ratio *= 1.0 + float(inferno_set.get("two_piece", {}).get("burn_efficiency", 0.0))
		status_strength = maxf(status_strength, burn_ratio)
		inferno_high_heat_shots += 1
	elif visual_profile == "apocalypse_absolute_zero":
		status_strength = maxf(status_strength, float(special.get("slow", 0.30)) * (1.0 + _chip_value("slow_strength_mult") + _pet_stat_value("slow_strength_mult")))
	status_strength *= _fire_rate_status_normalization()
	var preferred_target: Node2D = target_manager.locked_enemy if target_manager.has_lock() else null
	var homing_targets: Array[Node2D] = []
	var scatter_homing_delay := -1.0
	if homing > 0.0 and pellet_count > 1:
		var homing_target_limit := maxi(1, skills.level("skill_homing"))
		homing_targets = _homing_target_assignments(origin, shot_directions, homing_target_limit, preferred_target)
		scatter_homing_delay = SCATTER_HOMING_ACTIVATION_DELAY
	var penetration_feedback_triggered := armor_penetration > 0.0 and randf() < 0.14
	if penetration_feedback_triggered:
		AudioManager.play_sfx("skill_pierce", -11.0, 0.02)
		_spawn_float_text(origin + Vector2(105, -72), "伤害穿透", Color(1.0, 0.78, 0.24))
	for i in range(shots):
		var shot_direction: Vector2 = shot_directions[i] if i < shot_directions.size() else direction
		var shot_preferred_target: Node2D = preferred_target
		if i < homing_targets.size():
			shot_preferred_target = homing_targets[i]
		var damage: float = base_damage * float(turret.damage_mult) * skills.damage_multiplier()
		damage *= lane_damage_mult
		damage *= _character_bullet_damage_multiplier(element)
		damage *= _character_chain_overflow_damage_multiplier(element, chain_count)
		if sig_vanguard_barrage_timer > 0.0:
			damage *= 1.08
		if element == primary_weakness:
			damage *= 1.15
		var is_crit := _combat_randf() < crit_rate + skills.crit_bonus()
		if is_crit:
			damage *= skills.crit_damage_mult()
			_spawn_crit_shot_vfx(origin, shot_direction, element)
		_spawn_projectile(
			origin,
			shot_direction,
			damage,
			pierce,
			split,
			float(mods.get("split_falloff", 0.65)),
			homing,
			splash,
			cloud,
			visual_scale,
			visual_profile,
			armor_penetration,
			status_strength,
			shot_preferred_target,
			scatter_homing_delay
		)
	if shots >= 3:
		_spawn_salvo_fan_vfx(origin, direction, maxf(lane_spread, pellet_spread), shots, element, visual_profile)

func _lane_pellet_directions(lane_directions: Array[Vector2], pellet_count: int, pellet_spread: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for lane_direction in lane_directions:
		var center := lane_direction.normalized()
		if pellet_count <= 1 or pellet_spread <= 0.0:
			result.append(center)
			continue
		for pellet_index in range(pellet_count):
			var t := 0.5 if pellet_count == 1 else float(pellet_index) / float(pellet_count - 1)
			result.append(center.rotated(lerpf(-pellet_spread * 0.5, pellet_spread * 0.5, t)).normalized())
	return result

func _homing_target_assignments(origin: Vector2, shot_directions: Array[Vector2], max_unique_targets: int, forced_target: Node2D = null) -> Array[Node2D]:
	var assignments: Array[Node2D] = []
	if shot_directions.is_empty():
		return assignments
	if is_instance_valid(forced_target):
		for _direction in shot_directions:
			assignments.append(forced_target)
		return assignments

	var candidates: Array[Node2D] = []
	for child in $EnemyLayer.get_children():
		if not is_instance_valid(child) or not child is Node2D or child.is_queued_for_deletion():
			continue
		if not child.has_method("targeting_snapshot"):
			continue
		var target := child as Node2D
		var hp_value: Variant = target.get("hp")
		if hp_value != null and float(hp_value) <= 0.0:
			continue
		if target.global_position.y > BREACH_Y + 40.0:
			continue
		candidates.append(target)
	if candidates.is_empty():
		for _direction in shot_directions:
			assignments.append(null)
		return assignments
	# _best_homing_candidate_index below has no explicit tie-break: on an equal
	# score it keeps the first array entry, so the raw $EnemyLayer child order
	# silently decided ties. That order is not guaranteed stable across
	# byte-identical seeded runs, which could hand a homing volley to a
	# different enemy run-to-run. Fix the order once up front instead.
	if _audit_combat_rng != null:
		candidates.sort_custom(_audit_enemy_precedes)

	# 追踪等级限制本轮可同时覆盖的目标数：Lv1~5 最多覆盖 1~5 个目标。先按扇形中
	# 均匀抽样的方向选出兼顾威胁与方向的不同目标，再让所有弹丸在这些目标间稳定轮转。
	var selected: Array[Node2D] = []
	var available: Array[Node2D] = candidates.duplicate()
	var target_count := mini(maxi(1, max_unique_targets), mini(available.size(), shot_directions.size()))
	for target_index in range(target_count):
		var direction_index := 0
		if target_count > 1:
			direction_index = roundi(float(target_index) * float(shot_directions.size() - 1) / float(target_count - 1))
		var sample_direction: Vector2 = shot_directions[direction_index]
		var best_index := _best_homing_candidate_index(available, origin, sample_direction)
		if best_index < 0:
			break
		selected.append(available[best_index])
		available.remove_at(best_index)
	if selected.is_empty():
		for _direction in shot_directions:
			assignments.append(null)
		return assignments

	var cycle: Array[Node2D] = []
	for shot_direction in shot_directions:
		if cycle.is_empty():
			for target in selected:
				cycle.append(target)
		var cycle_index := _best_homing_candidate_index(cycle, origin, shot_direction)
		assignments.append(cycle[cycle_index])
		cycle.remove_at(cycle_index)
	return assignments

func _best_homing_candidate_index(candidates: Array[Node2D], origin: Vector2, shot_direction: Vector2) -> int:
	var best_index := -1
	var best_score := -INF
	var normalized_direction := shot_direction.normalized()
	for index in range(candidates.size()):
		var target := candidates[index]
		if not is_instance_valid(target):
			continue
		var offset := target.global_position - origin
		if offset.length_squared() <= 0.01:
			continue
		var alignment := normalized_direction.dot(offset.normalized())
		var threat_score := target_manager.score_enemy(target.targeting_snapshot(), origin)
		var score := threat_score + alignment * 180.0 - offset.length() * 0.01
		if score > best_score:
			best_score = score
			best_index = index
	return best_index

func _multishot_damage_multiplier(lane_count: int, lane_damage_bonus := 0.0) -> float:
	# Per-projectile falloff is intentionally mild: multishot should still feel like a power spike,
	# but homing + dense lanes should not multiply into full-damage swarms. Lv4+ keeps the
	# four-lane plateau meaningful by restoring a small, data-owned slice of each lane's damage.
	var base_multiplier := 1.0
	match clampi(lane_count, 1, MAX_MULTISHOT_LANES):
		1:
			base_multiplier = 1.0
		2:
			base_multiplier = 0.85
		3:
			base_multiplier = 0.80
		4:
			base_multiplier = 0.75
		_:
			base_multiplier = 0.70
	return clampf(base_multiplier + float(lane_damage_bonus), 0.0, 1.0)

func _spawn_projectile(origin: Vector2, direction: Vector2, damage: float, pierce: int, split: int, split_falloff: float, homing := 0.0, splash := 0.0, cloud := 0.0, visual_scale := 1.0, visual_profile := "", armor_penetration := 0.0, status_strength := -1.0, preferred_target: Node2D = null, homing_delay_override := -1.0) -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	_configure_audit_projectile(projectile)
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var base_element := str(weapon.get("element", "physical"))
	var element := skills.projectile_element(base_element, weapon_id)
	var base_profile := visual_profile if visual_profile != "" else _weapon_visual_profile(weapon_id)
	var profile := _resolved_weapon_projectile_visual_profile(base_element, element, base_profile)
	if element == "fire" and profile == "":
		profile = "fire_round"
	projectile.setup(origin, direction, float(weapon.get("projectile_speed", 1450.0)), damage, element, pierce, split, split_falloff, homing, splash, cloud, visual_scale, 0, "", profile, armor_penetration, status_strength, preferred_target, homing_delay_override)
	projectile.split_requested.connect(_on_projectile_split_requested)
	projectile.hit_confirmed.connect(_on_projectile_hit_confirmed)
	$ProjectileLayer.add_child(projectile)
	_activate_audit_physics_node(projectile)
	if homing > 0.0:
		if skills.level("skill_homing") > 0:
			AudioManager.play_sfx("skill_homing", -12.0, 0.02)
		_spawn_homing_line_vfx(origin, direction, element)

func _primary_shot_directions(origin: Vector2, base_direction: Vector2, shots: int, spread: float) -> Array[Vector2]:
	# 多重射击 = “固定夹角”的对称扇形：每条弹道之间角度固定、不各自变道锁敌（避免 imba）。
	# 无点名时扇形整体仍参考敌群质心，但会整体旋转到至少一条真实弹道精确穿过当前自动目标；
	# 锁定/手动瞄准时同样让一条主弹道精确命中优先方向。整个扇形只做刚体旋转，
	# 因此偶数弹道不会从目标两侧跨过，所有相邻弹道也继续保持固定夹角。
	# 每条弹道的固定夹角取自 MULTISHOT_LANE_DEG（不再用武器随机 spread——那会在 spread=0 时把所有
	# 弹道叠成一条线，稍微偏一点就整组打空）；散射类武器额外的 spread 只做“下限加宽”。
	var directions: Array[Vector2] = []
	if shots <= 1:
		directions.append(base_direction.normalized())
		return directions
	var priority_dir := _priority_aim_direction(origin)
	var center_dir := priority_dir if priority_dir.length_squared() > 0.01 else _multishot_center_direction(origin, base_direction)
	var lane_step: float = maxf(deg_to_rad(MULTISHOT_LANE_DEG), spread / float(shots - 1))
	var total: float = lane_step * float(shots - 1)
	for index in range(shots):
		var offset: float = -total * 0.5 + lane_step * float(index)
		directions.append(center_dir.rotated(offset).normalized())
	var hit_direction := priority_dir
	if hit_direction.length_squared() <= 0.01:
		hit_direction = _automatic_multishot_hit_direction(origin, base_direction)
	if hit_direction.length_squared() > 0.01:
		var hit_lane := 0
		var hit_angle := INF
		for index in range(directions.size()):
			var angle := absf(directions[index].angle_to(hit_direction))
			if angle < hit_angle:
				hit_angle = angle
				hit_lane = index
		# Rotate the complete fan instead of bending one projectile independently.
		# This puts one lane through the target centre and preserves every authored gap.
		var correction := directions[hit_lane].angle_to(hit_direction)
		for index in range(directions.size()):
			directions[index] = directions[index].rotated(correction).normalized()
	return directions

func _priority_aim_direction(origin: Vector2) -> Vector2:
	var priority_point := Vector2.ZERO
	var has_priority := false
	if _manual_aim_has_priority():
		priority_point = manual_aim_point
		has_priority = true
	elif target_manager != null and target_manager.has_lock():
		var locked := target_manager.locked_enemy
		if is_instance_valid(locked):
			priority_point = locked.global_position
			has_priority = true
	if not has_priority:
		return Vector2.ZERO
	var direction := priority_point - origin
	return direction.normalized() if direction.length_squared() > 4.0 else Vector2.ZERO

func _automatic_multishot_hit_direction(origin: Vector2, requested_direction: Vector2) -> Vector2:
	# `requested_direction` comes from the automatic target selected for the turret.
	# Resolve it back to the nearest still-live enemy direction so a stale/centroid
	# direction can never be mistaken for an actual hittable lane.
	var requested := requested_direction.normalized() if requested_direction.length_squared() > 0.01 else Vector2.UP
	var best_direction := Vector2.ZERO
	var best_angle := INF
	for child in $EnemyLayer.get_children():
		if not is_instance_valid(child) or child.is_queued_for_deletion() or not (child is Node2D):
			continue
		var hp_value = child.get("hp")
		if hp_value != null and float(hp_value) <= 0.0:
			continue
		var enemy := child as Node2D
		if enemy.global_position.y > BREACH_Y + 40.0:
			continue
		var to_enemy := enemy.global_position - origin
		if to_enemy.length_squared() <= 4.0:
			continue
		var enemy_direction := to_enemy.normalized()
		var angle := absf(requested.angle_to(enemy_direction))
		if angle < best_angle:
			best_angle = angle
			best_direction = enemy_direction
	return best_direction

func _multishot_center_direction(origin: Vector2, fallback: Vector2) -> Vector2:
	# 敌群质心方向（只算尚未越过基线的敌人）；无敌人时退回原瞄准方向。
	var priority_dir := _priority_aim_direction(origin)
	if priority_dir.length_squared() > 0.01:
		return priority_dir
	var sum := Vector2.ZERO
	var n := 0
	for e in $EnemyLayer.get_children():
		if not is_instance_valid(e) or not (e is Node2D):
			continue
		var en := e as Node2D
		if en.global_position.y > 1540.0 + bottom_dock_shift:
			continue
		sum += en.global_position
		n += 1
	var safe_fallback := fallback.normalized() if fallback.length_squared() > 0.01 else Vector2.UP
	if n == 0:
		return safe_fallback
	var dir := (sum / float(n)) - origin
	if dir.length_squared() <= 4.0:
		return safe_fallback
	return dir.normalized()

func _multi_shot_target_candidates(origin: Vector2, base_direction: Vector2) -> Array:
	var candidates := []
	var used_ids := {}
	if target_manager.has_lock():
		var locked := target_manager.locked_enemy
		if is_instance_valid(locked):
			used_ids[locked.get_instance_id()] = true
			candidates.append({"enemy": locked, "score": 999999.0})
	for enemy in $EnemyLayer.get_children():
		if not is_instance_valid(enemy) or not enemy is Node2D or not enemy.has_method("targeting_snapshot"):
			continue
		var enemy_node := enemy as Node2D
		if used_ids.has(enemy_node.get_instance_id()):
			continue
		var to_enemy: Vector2 = enemy_node.global_position - origin
		var distance := to_enemy.length()
		if distance <= 24.0:
			continue
		var target_direction := to_enemy / distance
		var forward := target_direction.dot(base_direction.normalized())
		if forward <= 0.12:
			continue
		var angle_penalty := absf(wrapf(target_direction.angle() - base_direction.angle(), -PI, PI))
		var score := target_manager.score_enemy(enemy.targeting_snapshot(), origin)
		score += forward * 70.0
		score -= angle_penalty * 28.0
		score -= distance * 0.018
		candidates.append({"enemy": enemy_node, "score": score})
	# Multishot/homing lane assignment: break score ties deterministically (see
	# _active_target_candidates for why raw $EnemyLayer order cannot be trusted
	# for this on an otherwise byte-identical seeded run).
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a := float(a.get("score", 0.0))
		var score_b := float(b.get("score", 0.0))
		if not is_equal_approx(score_a, score_b):
			return score_a > score_b
		if _audit_combat_rng == null:
			return false
		return _audit_enemy_precedes(a.get("enemy") as Node, b.get("enemy") as Node)
	)
	return candidates

func _spawn_pet() -> void:
	if pet_data.is_empty():
		return
	pet_sprite = Sprite2D.new()
	pet_sprite.name = "Pet"
	pet_sprite.process_mode = Node.PROCESS_MODE_PAUSABLE
	pet_sprite.texture = load(pet_data.get("sprite", pet_data.get("icon", "")))
	pet_sprite.position = _pet_anchor_position()
	pet_sprite.scale = Vector2(0.26, 0.26) * _visual_level_scale(pet_level)
	pet_sprite.modulate = Color.WHITE
	pet_sprite.z_index = DEFENSE_ACTOR_Z
	add_child(pet_sprite)
	_load_pet_animation_frames(str(pet_data.get("sprite", "")))
	_attach_growth_badge(pet_sprite, pet_level, Vector2(-88, -152))
	_spawn_pet_aura()
	var skill := _pet_skill_data()
	var skill_cooldown := float(skill.get("cooldown", 0.0))
	pet_skill_cooldown = minf(3.0, skill_cooldown * 0.35) if skill_cooldown > 0.0 else 0.0
	pet_skill_timer = 0.0
	if pet_data.get("role", "") == "repair":
		pet_repair_cooldown = maxf(1.0, float(pet_data.get("repair_interval", 18.0)))
		pet_emergency_cooldown = 0.0
		_spawn_float_text(pet_sprite.global_position + Vector2(0, -80), "维修系统在线", Color(0.35, 1.0, 0.68))

func _spawn_character() -> void:
	character_rig = Node2D.new()
	character_rig.name = "CharacterRig"
	character_rig.process_mode = Node.PROCESS_MODE_PAUSABLE
	character_rig.position = CHARACTER_BASE_POSITION
	character_rig.z_index = DEFENSE_ACTOR_Z
	add_child(character_rig)

	character_sprite = Sprite2D.new()
	character_sprite.name = "Character"
	character_sprite.position = Vector2.ZERO
	character_sprite.scale = Vector2.ONE * CHARACTER_VISUAL_BASE_SCALE
	character_sprite.modulate = Color.WHITE
	character_sprite.z_index = 1
	character_rig.add_child(character_sprite)
	_load_character_animation_frames()
	if not character_idle_frames.is_empty():
		character_sprite.texture = character_idle_frames[0]
	else:
		character_sprite.texture = load(character_data.get("portrait", ""))
	_apply_character_body_normalization("center" if _character_uses_true_grip() else "idle")
	_apply_character_presentation_scale()
	character_sprite.material = ThemeManager.create_character_material(_character_asset_id())
	_attach_growth_badge(character_sprite, character_level, Vector2(-98, -190))
	_spawn_character_weapon_visual()
	_spawn_character_aura()
	_spawn_character_theme_fire_aura()

func _apply_character_presentation_scale() -> void:
	if character_rig == null or character_sprite == null:
		return
	# The rig owns the final 1.20x battlefield presentation (80% of the former
	# 1.50x size), while its lift follows the anatomical foot contract rather than the full
	# alpha bounds. A tall cannon, coat, wing or muzzle glow can therefore extend
	# freely without moving the hero's boots or making the human body smaller.
	var foot_offset := _character_body_target_foot_offset()
	character_rig_foot_lift = maxf(0.0, foot_offset * (CHARACTER_PRESENTATION_SCALE - 1.0))
	character_rig.position = CHARACTER_BASE_POSITION - Vector2(0.0, character_rig_foot_lift)
	character_rig.scale = Vector2.ONE * CHARACTER_PRESENTATION_SCALE

func _character_body_metrics_table() -> Dictionary:
	var table: Variant = DataLoader.get_table("character_body_metrics")
	return table if table is Dictionary else {}

func _character_uses_true_grip() -> bool:
	var true_grip: Variant = _weapon_presentation().get("true_grip", {})
	return true_grip is Dictionary and not (true_grip as Dictionary).is_empty()

func _character_body_profile_id() -> String:
	var profiles: Dictionary = _character_body_metrics_table().get("profiles", {})
	return weapon_id if profiles.has(weapon_id) else "standard"

func _character_body_metric(pose_key := "") -> Dictionary:
	var resolved_pose := pose_key
	if resolved_pose == "":
		resolved_pose = _character_current_body_pose_key()
	var profiles: Dictionary = _character_body_metrics_table().get("profiles", {})
	var profile: Dictionary = profiles.get(_character_body_profile_id(), {})
	var character_profile: Dictionary = profile.get(_character_asset_id(), {})
	if character_profile.has(resolved_pose):
		return (character_profile.get(resolved_pose, {}) as Dictionary).duplicate(true)
	var fallback_pose := "center" if _character_uses_true_grip() else "idle"
	if character_profile.has(fallback_pose):
		return (character_profile.get(fallback_pose, {}) as Dictionary).duplicate(true)
	return {
		"body_height_px": CHARACTER_BODY_TARGET_HEIGHT_FALLBACK,
		"foot_y_px": 486.0,
		"body_center_x_px": 190.0,
	}

func _character_body_target_height() -> float:
	return maxf(1.0, float(_character_body_metrics_table().get(
		"target_body_height_px", CHARACTER_BODY_TARGET_HEIGHT_FALLBACK
	)))

func _character_body_target_foot_offset() -> float:
	return float(_character_body_metrics_table().get(
		"target_foot_offset_px", CHARACTER_BODY_TARGET_FOOT_OFFSET_FALLBACK
	))

func _character_body_sprite_scale(pose_key := "") -> float:
	# Every frame in one character/profile depicts the same person and therefore
	# shares one physical model scale. The old per-pose normalization enlarged a
	# crouched/recoiling fire pose and shrank the upright static pose. Centre is the
	# common ruler for standard fused strips and premium true-grip directions;
	# pose-specific metrics now affect only body centre and boot anchoring.
	var scale_pose := str(_character_body_metrics_table().get("scale_reference_pose", "center"))
	var metric := _character_body_metric(scale_pose)
	var source_height := maxf(1.0, float(metric.get("body_height_px", _character_body_target_height())))
	return CHARACTER_VISUAL_BASE_SCALE * _character_body_target_height() / source_height

func _character_body_anchor_offset(pose_key: String, sprite_scale: float) -> Vector2:
	var metric := _character_body_metric(pose_key)
	var texture_size := Vector2(380.0, 520.0)
	if character_sprite != null and character_sprite.texture != null:
		texture_size = character_sprite.texture.get_size()
	var body_center_x := float(metric.get("body_center_x_px", texture_size.x * 0.5))
	var foot_y := float(metric.get("foot_y_px", texture_size.y * 0.5))
	return Vector2(
		(texture_size.x * 0.5 - body_center_x) * sprite_scale,
		_character_body_target_foot_offset() - (foot_y - texture_size.y * 0.5) * sprite_scale
	)

func _apply_character_body_normalization(pose_key := "") -> void:
	if character_sprite == null:
		return
	var resolved_pose := pose_key if pose_key != "" else _character_current_body_pose_key()
	var sprite_scale := _character_body_sprite_scale(resolved_pose)
	character_sprite.scale = Vector2.ONE * sprite_scale
	character_sprite.position = _character_body_anchor_offset(resolved_pose, sprite_scale)

func _character_current_body_pose_key() -> String:
	if _character_uses_true_grip():
		if character_attack_time > 0.0 or character_skill_time > 0.0 or _character_prefire_active():
			return _character_combo_effective_aim()
		return "center"
	if character_hurt_time > 0.0:
		return "hurt"
	if character_attack_time > 0.0 or character_skill_time > 0.0 or _character_prefire_active():
		return _character_combo_effective_aim()
	return "idle"

func _character_visible_bottom_offset() -> float:
	if character_sprite == null or character_sprite.texture == null:
		return 0.0
	var image := character_sprite.texture.get_image()
	if image == null or image.is_empty():
		return float(character_sprite.texture.get_height()) * absf(character_sprite.scale.y) * 0.5
	var used := image.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return float(image.get_height()) * absf(character_sprite.scale.y) * 0.5
	return maxf(0.0, float(used.end.y) - float(image.get_height()) * 0.5) * absf(character_sprite.scale.y)

func _spawn_theme_base_overlay() -> void:
	match ThemeManager.active_effect_profile():
		"neon_tempest":
			_spawn_neon_tempest_base_overlay()
		"infernal_dominion":
			_spawn_infernal_dominion_base_overlay()
		"polar_aurora":
			_spawn_polar_aurora_base_overlay()
		"gilded_eclipse":
			_spawn_gilded_eclipse_base_overlay()

func _spawn_character_theme_fire_aura() -> void:
	match ThemeManager.character_effect_profile(_character_asset_id()):
		"neon_tempest":
			_spawn_neon_tempest_character_fire_aura()
		"infernal_dominion":
			_spawn_infernal_character_fire_aura()
		"polar_aurora":
			_spawn_polar_aurora_character_fire_aura()
		"gilded_eclipse":
			_spawn_gilded_eclipse_character_fire_aura()

func _spawn_character_theme_fire_signature(origin: Vector2, direction: Vector2, element: String) -> void:
	match ThemeManager.character_effect_profile(_character_asset_id()):
		"neon_tempest":
			_spawn_neon_tempest_fire_signature(origin, direction, element)
		"infernal_dominion":
			_spawn_infernal_fire_signature(origin, direction, element)
		"polar_aurora":
			_spawn_polar_aurora_fire_signature(origin, direction, element)
		"gilded_eclipse":
			_spawn_gilded_eclipse_fire_signature(origin, direction, element)

func _spawn_character_theme_cast_signature(origin: Vector2, base_color: Color) -> void:
	match ThemeManager.character_effect_profile(_character_asset_id()):
		"neon_tempest":
			_spawn_neon_tempest_cast_signature(origin, base_color)
		"infernal_dominion":
			_spawn_infernal_cast_signature(origin, base_color)
		"polar_aurora":
			_spawn_polar_aurora_cast_signature(origin, base_color)
		"gilded_eclipse":
			_spawn_gilded_eclipse_cast_signature(origin, base_color)

func _spawn_neon_tempest_base_overlay() -> void:
	if not ThemeManager.is_active("neon_tempest"):
		return
	var root := Node2D.new()
	root.name = "NeonTempestBaseOverlay"
	root.process_mode = Node.PROCESS_MODE_PAUSABLE
	root.z_index = DEFENSE_ACTOR_Z - 1
	add_child(root)
	var base_y := 1532.0 + bottom_dock_shift
	for index in range(2):
		var rail := Line2D.new()
		rail.name = "BaseEnergyRail%d" % (index + 1)
		rail.width = 8.0 if index == 0 else 3.2
		rail.default_color = Color(0.10, 0.92, 1.0, 0.40) if index == 0 else Color(0.96, 0.18, 1.0, 0.62)
		rail.joint_mode = Line2D.LINE_JOINT_ROUND
		rail.begin_cap_mode = Line2D.LINE_CAP_ROUND
		rail.end_cap_mode = Line2D.LINE_CAP_ROUND
		rail.texture = VfxLib.STREAK_TEXTURE
		rail.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		rail.material = _new_muzzle_additive_material()
		var offset_y := 0.0 if index == 0 else 12.0
		rail.points = PackedVector2Array([
			Vector2(122, base_y + 18.0 + offset_y),
			Vector2(286, base_y - 5.0 + offset_y),
			Vector2(540, base_y - 14.0 + offset_y),
			Vector2(794, base_y - 5.0 + offset_y),
			Vector2(958, base_y + 18.0 + offset_y),
		])
		root.add_child(rail)
		if not SettingsManager.reduced_effects_enabled():
			var tween := rail.create_tween().set_loops()
			tween.tween_property(rail, "modulate:a", 0.56, 0.72 + float(index) * 0.12)
			tween.tween_property(rail, "modulate:a", 1.0, 0.72 + float(index) * 0.12)
	for side_x in [132.0, 948.0]:
		var glow := VfxLib.spawn_glow(root, Vector2(side_x, base_y + 8.0), Color(0.34, 0.9, 1.0, 0.36), 82.0, 0.72)
		if glow != null:
			glow.set_meta("persistent_theme_fx", true)


func _spawn_infernal_dominion_base_overlay() -> void:
	if not ThemeManager.is_active("infernal_dominion"):
		return
	var root := Node2D.new()
	root.name = "InfernalDominionBaseOverlay"
	root.process_mode = Node.PROCESS_MODE_PAUSABLE
	root.z_index = DEFENSE_ACTOR_Z - 1
	add_child(root)
	var base_y := 1532.0 + bottom_dock_shift
	for index in range(2):
		var rail := Line2D.new()
		rail.name = "FurnaceRail%d" % (index + 1)
		rail.width = 9.0 if index == 0 else 3.5
		rail.default_color = Color(0.96, 0.24, 0.055, 0.34) if index == 0 else Color(1.0, 0.72, 0.18, 0.58)
		rail.joint_mode = Line2D.LINE_JOINT_ROUND
		rail.begin_cap_mode = Line2D.LINE_CAP_ROUND
		rail.end_cap_mode = Line2D.LINE_CAP_ROUND
		rail.texture = VfxLib.STREAK_TEXTURE
		rail.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		rail.material = _new_muzzle_additive_material()
		var inset := float(index) * 20.0
		rail.points = PackedVector2Array([
			Vector2(112 + inset, base_y + 20.0),
			Vector2(286, base_y - 4.0 - inset * 0.12),
			Vector2(540, base_y - 18.0 - inset * 0.18),
			Vector2(794, base_y - 4.0 - inset * 0.12),
			Vector2(968 - inset, base_y + 20.0),
		])
		root.add_child(rail)
		if not SettingsManager.reduced_effects_enabled():
			var tween := rail.create_tween().set_loops()
			tween.tween_property(rail, "modulate:a", 0.52, 0.66 + float(index) * 0.10)
			tween.tween_property(rail, "modulate:a", 1.0, 0.66 + float(index) * 0.10)
	for side_x in [130.0, 950.0]:
		var glow := VfxLib.spawn_glow(root, Vector2(side_x, base_y + 8.0), Color(1.0, 0.30, 0.05, 0.30), 88.0, 0.72)
		if glow != null:
			glow.set_meta("persistent_theme_fx", true)


func _spawn_polar_aurora_base_overlay() -> void:
	if not ThemeManager.is_active("polar_aurora"):
		return
	var root := Node2D.new()
	root.name = "PolarAuroraBaseOverlay"
	root.process_mode = Node.PROCESS_MODE_PAUSABLE
	root.z_index = DEFENSE_ACTOR_Z - 1
	add_child(root)
	var base_y := 1532.0 + bottom_dock_shift
	for index in range(3):
		var rail := Line2D.new()
		rail.name = "CryoRail%d" % (index + 1)
		rail.width = 8.0 if index == 0 else 3.0
		rail.default_color = Color(0.34, 0.90, 1.0, 0.34) if index != 2 else Color(0.60, 0.40, 0.94, 0.42)
		rail.joint_mode = Line2D.LINE_JOINT_ROUND
		rail.begin_cap_mode = Line2D.LINE_CAP_ROUND
		rail.end_cap_mode = Line2D.LINE_CAP_ROUND
		rail.texture = VfxLib.STREAK_TEXTURE
		rail.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		rail.material = _new_muzzle_additive_material()
		var inset := float(index) * 20.0
		rail.points = PackedVector2Array([
			Vector2(118 + inset, base_y + 18.0),
			Vector2(302, base_y - 7.0 - inset * 0.10),
			Vector2(540, base_y - 20.0 - inset * 0.15),
			Vector2(778, base_y - 7.0 - inset * 0.10),
			Vector2(962 - inset, base_y + 18.0),
		])
		root.add_child(rail)
		if not SettingsManager.reduced_effects_enabled():
			var tween := rail.create_tween().set_loops()
			tween.tween_property(rail, "modulate:a", 0.50, 0.80 + float(index) * 0.10)
			tween.tween_property(rail, "modulate:a", 1.0, 0.80 + float(index) * 0.10)
	for side_x in [132.0, 948.0]:
		var glow := VfxLib.spawn_glow(root, Vector2(side_x, base_y + 6.0), Color(0.40, 0.88, 1.0, 0.30), 86.0, 0.76)
		if glow != null:
			glow.set_meta("persistent_theme_fx", true)


func _spawn_gilded_eclipse_base_overlay() -> void:
	if not ThemeManager.is_active("gilded_eclipse"):
		return
	var root := Node2D.new()
	root.name = "GildedEclipseBaseOverlay"
	root.process_mode = Node.PROCESS_MODE_PAUSABLE
	root.z_index = DEFENSE_ACTOR_Z - 1
	add_child(root)
	var base_y := 1532.0 + bottom_dock_shift
	for index in range(3):
		var rail := Line2D.new()
		rail.name = "GoldenLawRail%d" % (index + 1)
		rail.width = 7.5 if index == 0 else 2.8
		rail.default_color = Color(1.0, 0.72, 0.20, 0.36) if index != 2 else Color(1.0, 0.94, 0.70, 0.46)
		rail.joint_mode = Line2D.LINE_JOINT_ROUND
		rail.begin_cap_mode = Line2D.LINE_CAP_ROUND
		rail.end_cap_mode = Line2D.LINE_CAP_ROUND
		rail.texture = VfxLib.STREAK_TEXTURE
		rail.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		rail.material = _new_muzzle_additive_material()
		var inset := float(index) * 22.0
		rail.points = PackedVector2Array([
			Vector2(118 + inset, base_y + 18.0),
			Vector2(300, base_y - 8.0 - inset * 0.08),
			Vector2(540, base_y - 22.0 - inset * 0.14),
			Vector2(780, base_y - 8.0 - inset * 0.08),
			Vector2(962 - inset, base_y + 18.0),
		])
		root.add_child(rail)
		if not SettingsManager.reduced_effects_enabled():
			var tween := rail.create_tween().set_loops()
			tween.tween_property(rail, "modulate:a", 0.48, 0.88 + float(index) * 0.12)
			tween.tween_property(rail, "modulate:a", 1.0, 0.88 + float(index) * 0.12)
	for side_x in [132.0, 948.0]:
		var glow := VfxLib.spawn_glow(root, Vector2(side_x, base_y + 6.0), Color(1.0, 0.72, 0.22, 0.30), 88.0, 0.78)
		if glow != null:
			glow.set_meta("persistent_theme_fx", true)


func _spawn_neon_tempest_character_fire_aura() -> void:
	var character_id := _character_asset_id()
	if character_rig == null or not ThemeManager.character_uses_theme(character_id, "neon_tempest"):
		return
	var textures := ThemeManager.resolve_character_effect_sequence(character_id, "character_fire_aura")
	if textures.is_empty():
		return
	var frames := SpriteFrames.new()
	frames.add_animation("fire")
	frames.set_animation_loop("fire", false)
	frames.set_animation_speed("fire", 19.0)
	for texture in textures:
		frames.add_frame("fire", texture)
	character_theme_fire_aura = AnimatedSprite2D.new()
	character_theme_fire_aura.name = "ThemeFireAura"
	character_theme_fire_aura.sprite_frames = frames
	character_theme_fire_aura.animation = "fire"
	character_theme_fire_aura.position = Vector2(0, -82)
	character_theme_fire_aura.scale = Vector2.ONE * (0.54 if SettingsManager.reduced_effects_enabled() else 0.66)
	character_theme_fire_aura.modulate = Color(1.0, 1.0, 1.0, 0.48 if SettingsManager.reduced_effects_enabled() else 0.90)
	character_theme_fire_aura.material = _new_muzzle_additive_material()
	# The theme signature is a back-mounted discharge, not a foreground decal.
	# Keep it below the fused hero/weapon sprite regardless of child insertion
	# order; muzzle flash and projectile effects remain on their combat layers.
	character_theme_fire_aura.z_index = CHARACTER_BACK_EFFECT_Z
	character_theme_fire_aura.show_behind_parent = true
	character_theme_fire_aura.visible = false
	character_theme_fire_aura.process_mode = Node.PROCESS_MODE_PAUSABLE
	character_theme_fire_aura.animation_finished.connect(
		func() -> void:
			if is_instance_valid(character_theme_fire_aura):
				character_theme_fire_aura.visible = false
	)
	character_rig.add_child(character_theme_fire_aura)


func _spawn_infernal_character_fire_aura() -> void:
	var character_id := _character_asset_id()
	if character_rig == null or not ThemeManager.character_uses_theme(character_id, "infernal_dominion"):
		return
	var textures := ThemeManager.resolve_character_effect_sequence(character_id, "character_fire_aura")
	if textures.is_empty():
		return
	var frames := SpriteFrames.new()
	frames.add_animation("fire")
	frames.set_animation_loop("fire", false)
	frames.set_animation_speed("fire", 17.0)
	for texture in textures:
		frames.add_frame("fire", texture)
	character_theme_fire_aura = AnimatedSprite2D.new()
	character_theme_fire_aura.name = "InfernalMechanicalFireWings"
	character_theme_fire_aura.sprite_frames = frames
	character_theme_fire_aura.animation = "fire"
	# Rear-view socket: the hinge sits between the shoulder blades. Keep the
	# silhouette showy but narrower than the hero so it never replaces the actor.
	character_theme_fire_aura.position = Vector2(0, -62)
	character_theme_fire_aura.scale = Vector2.ONE * (0.39 if SettingsManager.reduced_effects_enabled() else 0.48)
	character_theme_fire_aura.modulate = Color(1.0, 0.90, 0.76, 0.44 if SettingsManager.reduced_effects_enabled() else 0.78)
	character_theme_fire_aura.material = _new_muzzle_additive_material()
	character_theme_fire_aura.z_index = CHARACTER_BACK_EFFECT_Z
	character_theme_fire_aura.show_behind_parent = true
	character_theme_fire_aura.visible = false
	character_theme_fire_aura.process_mode = Node.PROCESS_MODE_PAUSABLE
	character_theme_fire_aura.animation_finished.connect(
		func() -> void:
			if is_instance_valid(character_theme_fire_aura):
				character_theme_fire_aura.visible = false
	)
	character_rig.add_child(character_theme_fire_aura)


func _spawn_polar_aurora_character_fire_aura() -> void:
	var character_id := _character_asset_id()
	if character_rig == null or not ThemeManager.character_uses_theme(character_id, "polar_aurora"):
		return
	var textures := ThemeManager.resolve_character_effect_sequence(character_id, "character_fire_aura")
	if textures.is_empty():
		return
	var frames := SpriteFrames.new()
	frames.add_animation("fire")
	frames.set_animation_loop("fire", false)
	frames.set_animation_speed("fire", 17.0)
	for texture in textures:
		frames.add_frame("fire", texture)
	character_theme_fire_aura = AnimatedSprite2D.new()
	character_theme_fire_aura.name = "PolarAuroraIceWings"
	character_theme_fire_aura.sprite_frames = frames
	character_theme_fire_aura.animation = "fire"
	# The zero-point hinge is mounted between the shoulder blades. The generated
	# center is deliberately clear so the fused hero/weapon silhouette stays in
	# front and the wing tips never become a muzzle decal.
	character_theme_fire_aura.position = Vector2(0, -66)
	character_theme_fire_aura.scale = Vector2.ONE * (0.38 if SettingsManager.reduced_effects_enabled() else 0.47)
	character_theme_fire_aura.modulate = Color(0.90, 0.98, 1.0, 0.42 if SettingsManager.reduced_effects_enabled() else 0.76)
	character_theme_fire_aura.material = _new_muzzle_additive_material()
	character_theme_fire_aura.z_index = CHARACTER_BACK_EFFECT_Z
	character_theme_fire_aura.show_behind_parent = true
	character_theme_fire_aura.visible = false
	character_theme_fire_aura.process_mode = Node.PROCESS_MODE_PAUSABLE
	character_theme_fire_aura.animation_finished.connect(
		func() -> void:
			if is_instance_valid(character_theme_fire_aura):
				character_theme_fire_aura.visible = false
	)
	character_rig.add_child(character_theme_fire_aura)


func _spawn_gilded_eclipse_character_fire_aura() -> void:
	var character_id := _character_asset_id()
	if character_rig == null or not ThemeManager.character_uses_theme(character_id, "gilded_eclipse"):
		return
	var textures := ThemeManager.resolve_character_effect_sequence(character_id, "character_fire_aura")
	if textures.is_empty():
		return
	var frames := SpriteFrames.new()
	frames.add_animation("fire")
	frames.set_animation_loop("fire", false)
	frames.set_animation_speed("fire", 18.0)
	for texture in textures:
		frames.add_frame("fire", texture)
	character_theme_fire_aura = AnimatedSprite2D.new()
	character_theme_fire_aura.name = "GildedEclipseFlowingMantle"
	character_theme_fire_aura.sprite_frames = frames
	character_theme_fire_aura.animation = "fire"
	character_theme_fire_aura.position = Vector2(0, -60)
	character_theme_fire_aura.scale = Vector2.ONE * (0.39 if SettingsManager.reduced_effects_enabled() else 0.49)
	character_theme_fire_aura.modulate = Color(1.0, 0.91, 0.68, 0.44 if SettingsManager.reduced_effects_enabled() else 0.80)
	character_theme_fire_aura.material = _new_muzzle_additive_material()
	character_theme_fire_aura.z_index = CHARACTER_BACK_EFFECT_Z
	character_theme_fire_aura.show_behind_parent = true
	character_theme_fire_aura.visible = false
	character_theme_fire_aura.process_mode = Node.PROCESS_MODE_PAUSABLE
	character_theme_fire_aura.animation_finished.connect(
		func() -> void:
			if is_instance_valid(character_theme_fire_aura):
				character_theme_fire_aura.visible = false
	)
	character_rig.add_child(character_theme_fire_aura)


func _play_neon_tempest_character_fire_aura(direction: Vector2) -> void:
	if character_theme_fire_aura == null or not is_instance_valid(character_theme_fire_aura):
		return
	var dir := _safe_vfx_direction(direction)
	character_theme_fire_aura.rotation = dir.angle() + PI * 0.5
	character_theme_fire_aura.flip_h = dir.x < 0.0
	character_theme_fire_aura.visible = true
	character_theme_fire_aura.stop()
	character_theme_fire_aura.frame = 0
	character_theme_fire_aura.play("fire")


func _play_infernal_character_fire_aura(direction: Vector2) -> void:
	if character_theme_fire_aura == null or not is_instance_valid(character_theme_fire_aura):
		return
	var dir := _safe_vfx_direction(direction)
	# This is a physical furnace-wing assembly mounted on the character's back,
	# not a muzzle billboard. Keep it upright in the rear-view battle camera and
	# only let it bank subtly toward the current aim direction.
	character_theme_fire_aura.rotation = clampf(dir.x * 0.16, -0.16, 0.16)
	character_theme_fire_aura.flip_h = dir.x < 0.0
	character_theme_fire_aura.visible = true
	character_theme_fire_aura.stop()
	character_theme_fire_aura.frame = 0
	character_theme_fire_aura.play("fire")


func _play_polar_aurora_character_fire_aura(direction: Vector2) -> void:
	if character_theme_fire_aura == null or not is_instance_valid(character_theme_fire_aura):
		return
	var dir := _safe_vfx_direction(direction)
	character_theme_fire_aura.rotation = clampf(dir.x * 0.12, -0.12, 0.12)
	character_theme_fire_aura.flip_h = dir.x < 0.0
	character_theme_fire_aura.visible = true
	character_theme_fire_aura.stop()
	character_theme_fire_aura.frame = 0
	character_theme_fire_aura.play("fire")


func _play_gilded_eclipse_character_fire_aura(direction: Vector2) -> void:
	if character_theme_fire_aura == null or not is_instance_valid(character_theme_fire_aura):
		return
	var dir := _safe_vfx_direction(direction)
	character_theme_fire_aura.rotation = clampf(dir.x * 0.10, -0.10, 0.10)
	character_theme_fire_aura.flip_h = dir.x < 0.0
	character_theme_fire_aura.visible = true
	character_theme_fire_aura.stop()
	character_theme_fire_aura.frame = 0
	character_theme_fire_aura.play("fire")


func _spawn_character_weapon_visual() -> void:
	if character_rig == null:
		return
	if character_weapon_combo_active:
		character_weapon_sprite = null
		character_weapon_idle_frames = []
		character_weapon_recoil_frames = []
		return
	var weapon := DataLoader.get_row("weapons", weapon_id)
	character_weapon_sprite = Sprite2D.new()
	character_weapon_sprite.name = "CharacterWeapon"
	character_weapon_sprite.position = CHARACTER_WEAPON_SOCKET
	character_weapon_sprite.scale = Vector2.ONE * _weapon_visual_scale()
	character_weapon_sprite.z_index = 3
	character_rig.add_child(character_weapon_sprite)
	var handheld_path := ThemeManager.resolve_weapon_asset(weapon_id, "handheld", str(weapon.get("handheld", "")))
	if handheld_path != "" and ResourceLoader.exists(handheld_path):
		character_weapon_idle_frames = []
		character_weapon_recoil_frames = []
		character_weapon_sprite.texture = load(handheld_path)
	else:
		_load_character_weapon_animation_frames()
		if not character_weapon_idle_frames.is_empty():
			character_weapon_sprite.texture = character_weapon_idle_frames[0]
		else:
			var fallback := str(weapon.get("turret", weapon.get("icon", "")))
			character_weapon_sprite.texture = load(ThemeManager.resolve_weapon_asset(weapon_id, "turret", fallback))
	character_weapon_sprite.modulate = Color.WHITE
	character_weapon_sprite.material = ThemeManager.create_surface_material()
	_attach_growth_badge(character_weapon_sprite, weapon_level, Vector2(-82, -126))


func _themed_weapon_row(row: Dictionary) -> Dictionary:
	var resolved := row.duplicate(true)
	for kind in ["icon", "handheld", "turret"]:
		resolved[kind] = ThemeManager.resolve_weapon_asset(weapon_id, kind, str(row.get(kind, "")))
	return resolved

func _pulse_character_theme_material() -> void:
	if character_sprite == null:
		return
	var material := character_sprite.material as ShaderMaterial
	if material == null:
		return
	var pulse_parameter := ThemeManager.character_material_pulse_parameter(_character_asset_id())
	if pulse_parameter == "":
		return
	material.set_shader_parameter(pulse_parameter, 1.0)
	if character_theme_pulse_tween != null and character_theme_pulse_tween.is_valid():
		character_theme_pulse_tween.kill()
	character_theme_pulse_tween = create_tween()
	character_theme_pulse_tween.set_trans(Tween.TRANS_QUINT)
	character_theme_pulse_tween.set_ease(Tween.EASE_OUT)
	character_theme_pulse_tween.tween_method(
		func(value: float) -> void:
			if is_instance_valid(character_sprite) and character_sprite.material == material:
				material.set_shader_parameter(pulse_parameter, value),
		1.0,
		0.0,
		0.22
	)

func _spawn_neon_tempest_fire_signature(origin: Vector2, direction: Vector2, element: String) -> void:
	if not ThemeManager.character_uses_theme(_character_asset_id(), "neon_tempest") or not _can_spawn_projectile_fx(true):
		return
	var dir := _safe_vfx_direction(direction)
	var cyan := Color(0.18, 0.96, 1.0, 0.82)
	var magenta := Color(0.96, 0.18, 1.0, 0.66)
	var element_color := _element_color(element)
	element_color.a = 0.72
	_play_neon_tempest_character_fire_aura(dir)
	var shoulder := character_rig.to_global(Vector2(-dir.x * 34.0, -92.0))
	var weapon_bus := origin - dir * 44.0 * CHARACTER_VFX_PRESENTATION_SCALE
	var shoulder_glow := VfxLib.spawn_glow($ProjectileLayer, shoulder, magenta, 86.0 * CHARACTER_VFX_PRESENTATION_SCALE, 0.16)
	if shoulder_glow != null:
		_track_transient_fx(shoulder_glow, "projectile")
	_spawn_muzzle_light_cone(origin, dir, cyan, 148.0, 18.0, 0.11, 4.4)
	_spawn_muzzle_light_cone(origin + dir * 4.0, dir, magenta, 112.0, 34.0, 0.13, 3.3)
	_spawn_muzzle_fork_lines(origin + dir * 12.0, dir, Color(cyan.r, cyan.g, cyan.b, 0.72), 3, 92.0, 20.0, 0.13, 2.6)
	if not SettingsManager.reduced_effects_enabled():
		var motes := VfxLib.spawn_particles($ProjectileLayer, weapon_bus, element_color.lerp(magenta, 0.42), 9, 240.0, 54.0, 0.2)
		if motes != null:
			_track_transient_fx(motes, "projectile")
			if motes is Node2D:
				(motes as Node2D).rotation = dir.angle()


func _spawn_neon_tempest_cast_signature(origin: Vector2, base_color: Color) -> void:
	if not ThemeManager.character_uses_theme(_character_asset_id(), "neon_tempest") or not _can_spawn_projectile_fx(true):
		return
	_play_neon_tempest_character_fire_aura(Vector2.UP)
	var cyan := Color(0.20, 0.98, 1.0, 0.76)
	var magenta := Color(0.98, 0.20, 1.0, 0.62)
	var mixed := base_color.lerp(cyan, 0.34)
	var glow := VfxLib.spawn_glow($ProjectileLayer, origin + Vector2(0, -42) * CHARACTER_VFX_PRESENTATION_SCALE, mixed, 238.0 * CHARACTER_VFX_PRESENTATION_SCALE, 0.36)
	if glow != null:
		_track_transient_fx(glow, "projectile")
	_spawn_attack_ring(origin + Vector2(0, -18) * CHARACTER_VFX_PRESENTATION_SCALE, 126.0 * CHARACTER_VFX_PRESENTATION_SCALE, cyan, 0.28)
	_spawn_attack_ring(origin + Vector2(0, -18) * CHARACTER_VFX_PRESENTATION_SCALE, 178.0 * CHARACTER_VFX_PRESENTATION_SCALE, magenta, 0.34)
	_spawn_muzzle_fork_lines(origin + Vector2(0, -72) * CHARACTER_VFX_PRESENTATION_SCALE, Vector2.UP, cyan, 5, 138.0, 58.0, 0.24, 3.2)


func _spawn_infernal_fire_signature(origin: Vector2, direction: Vector2, element: String) -> void:
	if not ThemeManager.character_uses_theme(_character_asset_id(), "infernal_dominion") or not _can_spawn_projectile_fx(true):
		return
	var dir := _safe_vfx_direction(direction)
	var ember := Color(1.0, 0.26, 0.045, 0.78)
	var white_hot := Color(1.0, 0.86, 0.48, 0.80)
	var copper := Color(0.78, 0.20, 0.055, 0.58)
	var element_color := _element_color(element)
	element_color.a = 0.62
	_play_infernal_character_fire_aura(dir)
	var shoulder := character_rig.to_global(Vector2(-dir.x * 30.0, -90.0))
	var furnace_bus := origin - dir * 48.0 * CHARACTER_VFX_PRESENTATION_SCALE
	var shoulder_glow := VfxLib.spawn_glow($ProjectileLayer, shoulder, copper, 84.0 * CHARACTER_VFX_PRESENTATION_SCALE, 0.16)
	if shoulder_glow != null:
		_track_transient_fx(shoulder_glow, "projectile")
	# Two compact, low-glare cones read as heat being compressed toward the
	# muzzle. The authored mechanical wing sprite supplies the broad silhouette.
	_spawn_muzzle_light_cone(origin, dir, white_hot, 152.0, 15.0, 0.10, 4.2)
	_spawn_muzzle_light_cone(origin + dir * 5.0, dir, ember, 118.0, 30.0, 0.13, 3.3)
	_spawn_muzzle_fork_lines(origin + dir * 10.0, dir, Color(1.0, 0.50, 0.10, 0.66), 3, 88.0, 18.0, 0.12, 2.5)
	if _weapon_visual_profile() == "apocalypse_inferno":
		var weapon_row := DataLoader.get_row("weapons", weapon_id)
		var special: Dictionary = weapon_row.get("special", {})
		var heat_shots := maxi(1, int(special.get("high_heat_shots", 12)))
		var vent_shots := maxi(1, int(special.get("vent_shots", 3)))
		var phase := inferno_high_heat_shots % (heat_shots + vent_shots)
		var awakening_phase := maxi(1, int(round(float(heat_shots) * 0.58)))
		if weapon_level >= int(weapon_row.get("max_level", 50)) and phase == awakening_phase and inferno_awakening_cooldown <= 0.0:
			var reduced := SettingsManager.reduced_effects_enabled()
			var awakening := _spawn_vfx_sequence(
				"vfx_apocalypse_inferno_awakening",
				character_rig.to_global(Vector2(0, -72)),
				0.82 if reduced else 1.08,
				Color(1.0, 0.91, 0.72, 0.56 if reduced else 0.90),
				1.0,
				0.0,
				1.02,
				Vector2(0, -5),
				0.0,
				true
			)
			if awakening != null:
				awakening.set("z_index", DEFENSE_ACTOR_Z - 2)
				AudioManager.play_sfx("apocalypse_inferno_awakening", -4.0, 0.01)
				SettingsManager.pulse_haptic("medium")
			inferno_awakening_cooldown = 7.0
		if phase >= heat_shots:
			# Vent reset stays dimmer than the white-hot stream, so it reads as
			# recovery rather than a second screen-filling shot.
			_spawn_muzzle_light_cone(origin - dir * 34.0, -dir, Color(0.88, 0.20, 0.035, 0.42), 92.0, 42.0, 0.18, 3.0)
			_spawn_attack_ring(origin - dir * 22.0, 78.0, Color(1.0, 0.38, 0.06, 0.30), 0.20)
		elif phase >= int(round(float(heat_shots) * 0.58)):
			# High heat: compact fin arcs plus a stable white-hot plasma core.
			_spawn_muzzle_light_cone(origin + dir * 8.0, dir, Color(1.0, 0.92, 0.68, 0.74), 178.0, 10.0, 0.12, 5.4)
			_spawn_muzzle_fork_lines(origin - dir * 6.0, dir, Color(1.0, 0.64, 0.14, 0.52), 4, 108.0, 28.0, 0.15, 2.2)
	if not SettingsManager.reduced_effects_enabled():
		var motes := VfxLib.spawn_particles($ProjectileLayer, furnace_bus, element_color.lerp(ember, 0.60), 8, 218.0, 48.0, 0.19)
		if motes != null:
			_track_transient_fx(motes, "projectile")
			if motes is Node2D:
				(motes as Node2D).rotation = dir.angle()


func _spawn_infernal_cast_signature(origin: Vector2, base_color: Color) -> void:
	if not ThemeManager.character_uses_theme(_character_asset_id(), "infernal_dominion") or not _can_spawn_projectile_fx(true):
		return
	_play_infernal_character_fire_aura(Vector2.UP)
	var ember := Color(1.0, 0.26, 0.04, 0.72)
	var gold_heat := Color(1.0, 0.70, 0.18, 0.64)
	var mixed := base_color.lerp(ember, 0.48)
	var glow := VfxLib.spawn_glow($ProjectileLayer, origin + Vector2(0, -38) * CHARACTER_VFX_PRESENTATION_SCALE, mixed, 222.0 * CHARACTER_VFX_PRESENTATION_SCALE, 0.34)
	if glow != null:
		_track_transient_fx(glow, "projectile")
	_spawn_attack_ring(origin + Vector2(0, -16) * CHARACTER_VFX_PRESENTATION_SCALE, 122.0 * CHARACTER_VFX_PRESENTATION_SCALE, ember, 0.26)
	_spawn_attack_ring(origin + Vector2(0, -16) * CHARACTER_VFX_PRESENTATION_SCALE, 172.0 * CHARACTER_VFX_PRESENTATION_SCALE, gold_heat, 0.33)
	_spawn_muzzle_fork_lines(origin + Vector2(0, -70) * CHARACTER_VFX_PRESENTATION_SCALE, Vector2.UP, gold_heat, 5, 132.0, 54.0, 0.22, 3.0)


func _spawn_polar_aurora_fire_signature(origin: Vector2, direction: Vector2, element: String) -> void:
	if not ThemeManager.character_uses_theme(_character_asset_id(), "polar_aurora") or not _can_spawn_projectile_fx(true):
		return
	var dir := _safe_vfx_direction(direction)
	var ice := Color(0.44, 0.92, 1.0, 0.78)
	var white_core := Color(0.88, 0.98, 1.0, 0.82)
	var violet := Color(0.62, 0.40, 0.94, 0.56)
	var element_color := _element_color(element)
	element_color.a = 0.58
	_play_polar_aurora_character_fire_aura(dir)
	var shoulder := character_rig.to_global(Vector2(-dir.x * 28.0, -92.0))
	var halo := VfxLib.spawn_glow($ProjectileLayer, shoulder, violet, 86.0 * CHARACTER_VFX_PRESENTATION_SCALE, 0.16)
	if halo != null:
		_track_transient_fx(halo, "projectile")
	_spawn_muzzle_light_cone(origin, dir, white_core, 158.0, 12.0, 0.11, 4.8)
	_spawn_muzzle_light_cone(origin + dir * 6.0, dir, ice, 126.0, 27.0, 0.14, 3.2)
	_spawn_muzzle_fork_lines(origin + dir * 12.0, dir, Color(0.72, 0.96, 1.0, 0.66), 3, 94.0, 20.0, 0.13, 2.5)
	if _weapon_visual_profile() == "apocalypse_absolute_zero" and weapon_level >= int(DataLoader.get_row("weapons", weapon_id).get("max_level", 50)) and absolute_zero_awakening_cooldown <= 0.0:
		var reduced := SettingsManager.reduced_effects_enabled()
		var awakening := _spawn_vfx_sequence(
			"vfx_apocalypse_absolute_zero_awakening",
			character_rig.to_global(Vector2(0, -82)),
			0.78 if reduced else 1.02,
			Color(0.86, 0.98, 1.0, 0.54 if reduced else 0.88),
			1.0,
			0.0,
			1.02,
			Vector2(0, -5),
			0.0,
			true
		)
		if awakening != null:
			awakening.set("z_index", DEFENSE_ACTOR_Z - 2)
			AudioManager.play_sfx("apocalypse_absolute_zero_awakening", -4.5, 0.015)
		absolute_zero_awakening_cooldown = 7.5
	if not SettingsManager.reduced_effects_enabled():
		var motes := VfxLib.spawn_particles($ProjectileLayer, origin - dir * 42.0, element_color.lerp(ice, 0.58), 7, 196.0, 42.0, 0.20)
		if motes != null:
			_track_transient_fx(motes, "projectile")
			if motes is Node2D:
				(motes as Node2D).rotation = dir.angle()


func _spawn_polar_aurora_cast_signature(origin: Vector2, base_color: Color) -> void:
	if not ThemeManager.character_uses_theme(_character_asset_id(), "polar_aurora") or not _can_spawn_projectile_fx(true):
		return
	_play_polar_aurora_character_fire_aura(Vector2.UP)
	var ice := Color(0.42, 0.92, 1.0, 0.72)
	var violet := Color(0.62, 0.42, 0.94, 0.58)
	var mixed := base_color.lerp(ice, 0.44)
	var glow := VfxLib.spawn_glow($ProjectileLayer, origin + Vector2(0, -42) * CHARACTER_VFX_PRESENTATION_SCALE, mixed, 226.0 * CHARACTER_VFX_PRESENTATION_SCALE, 0.34)
	if glow != null:
		_track_transient_fx(glow, "projectile")
	_spawn_attack_ring(origin + Vector2(0, -18) * CHARACTER_VFX_PRESENTATION_SCALE, 122.0 * CHARACTER_VFX_PRESENTATION_SCALE, ice, 0.27)
	_spawn_attack_ring(origin + Vector2(0, -18) * CHARACTER_VFX_PRESENTATION_SCALE, 174.0 * CHARACTER_VFX_PRESENTATION_SCALE, violet, 0.34)
	_spawn_muzzle_fork_lines(origin + Vector2(0, -72) * CHARACTER_VFX_PRESENTATION_SCALE, Vector2.UP, Color(0.82, 0.98, 1.0, 0.70), 5, 134.0, 54.0, 0.23, 3.0)


func _spawn_gilded_eclipse_fire_signature(origin: Vector2, direction: Vector2, element: String) -> void:
	if not ThemeManager.character_uses_theme(_character_asset_id(), "gilded_eclipse") or not _can_spawn_projectile_fx(true):
		return
	var dir := _safe_vfx_direction(direction)
	var gold := Color(1.0, 0.72, 0.18, 0.78)
	var white_gold := Color(1.0, 0.95, 0.72, 0.84)
	var element_color := _element_color(element)
	element_color.a = 0.46
	_play_gilded_eclipse_character_fire_aura(dir)
	var shoulder := character_rig.to_global(Vector2(-dir.x * 26.0, -90.0))
	var halo := VfxLib.spawn_glow($ProjectileLayer, shoulder, gold, 92.0 * CHARACTER_VFX_PRESENTATION_SCALE, 0.17)
	if halo != null:
		_track_transient_fx(halo, "projectile")
	_spawn_muzzle_light_cone(origin, dir, white_gold, 164.0, 11.0, 0.11, 5.0)
	_spawn_muzzle_light_cone(origin + dir * 7.0, dir, gold, 134.0, 25.0, 0.14, 3.4)
	_spawn_muzzle_fork_lines(origin + dir * 14.0, dir, Color(1.0, 0.84, 0.38, 0.70), 4, 104.0, 22.0, 0.14, 2.8)
	if _weapon_visual_profile() == "apocalypse_golden_law" and weapon_level >= int(DataLoader.get_row("weapons", weapon_id).get("max_level", 50)) and golden_law_awakening_cooldown <= 0.0:
		var reduced := SettingsManager.reduced_effects_enabled()
		var awakening := _spawn_vfx_sequence(
			"vfx_apocalypse_golden_law_awakening",
			character_rig.to_global(Vector2(0, -78)),
			0.80 if reduced else 1.04,
			Color(1.0, 0.90, 0.58, 0.54 if reduced else 0.90),
			1.0, 0.0, 1.02, Vector2(0, -5), 0.0, true
		)
		if awakening != null:
			awakening.set("z_index", DEFENSE_ACTOR_Z - 2)
			AudioManager.play_sfx("apocalypse_golden_law_awakening", -4.0, 0.015)
		golden_law_awakening_cooldown = 7.5
	if not SettingsManager.reduced_effects_enabled():
		var motes := VfxLib.spawn_particles($ProjectileLayer, origin - dir * 44.0, element_color.lerp(gold, 0.72), 8, 205.0, 46.0, 0.20)
		if motes != null:
			_track_transient_fx(motes, "projectile")
			if motes is Node2D:
				(motes as Node2D).rotation = dir.angle()


func _spawn_gilded_eclipse_cast_signature(origin: Vector2, base_color: Color) -> void:
	if not ThemeManager.character_uses_theme(_character_asset_id(), "gilded_eclipse") or not _can_spawn_projectile_fx(true):
		return
	_play_gilded_eclipse_character_fire_aura(Vector2.UP)
	var gold := Color(1.0, 0.72, 0.18, 0.74)
	var white_gold := Color(1.0, 0.94, 0.72, 0.70)
	var mixed := base_color.lerp(gold, 0.52)
	var glow := VfxLib.spawn_glow($ProjectileLayer, origin + Vector2(0, -40) * CHARACTER_VFX_PRESENTATION_SCALE, mixed, 232.0 * CHARACTER_VFX_PRESENTATION_SCALE, 0.34)
	if glow != null:
		_track_transient_fx(glow, "projectile")
	_spawn_attack_ring(origin + Vector2(0, -18) * CHARACTER_VFX_PRESENTATION_SCALE, 126.0 * CHARACTER_VFX_PRESENTATION_SCALE, gold, 0.28)
	_spawn_attack_ring(origin + Vector2(0, -18) * CHARACTER_VFX_PRESENTATION_SCALE, 178.0 * CHARACTER_VFX_PRESENTATION_SCALE, white_gold, 0.35)
	_spawn_muzzle_fork_lines(origin + Vector2(0, -72) * CHARACTER_VFX_PRESENTATION_SCALE, Vector2.UP, white_gold, 5, 140.0, 56.0, 0.24, 3.1)

func _load_character_animation_frames() -> void:
	var asset_id := _character_asset_id()
	character_weapon_combo_active = false
	character_weapon_combo_muzzle = CHARACTER_WEAPON_SOCKET
	character_weapon_combo_aim = "center"
	character_weapon_combo_locked_aim = ""
	character_attack_left_frames = []
	character_attack_right_frames = []
	if _load_premium_true_grip_frames(asset_id):
		return
	# A battlefield hero is never rendered as a weaponless theme sprite with a
	# separate gun decal on top. The authored combo frames are the grip contract:
	# stock against the shoulder, both hands contacting the weapon, forearms in
	# front of the receiver, and a direction-specific muzzle. Theme character
	# materials and firing signatures are applied to this fused silhouette, so
	# cosmetic outfits keep their palette/effects without breaking the anatomy.
	var combo_base := _character_weapon_combo_base(asset_id)
	if _image_resource_exists("%s_idle_01.png" % combo_base):
		character_idle_frames = _load_frame_set(combo_base, "idle", 4)
		character_attack_left_frames = _load_frame_set(combo_base, "attack_left", CHARACTER_WEAPON_ACTION_FRAME_COUNT)
		character_attack_frames = _load_frame_set(combo_base, "attack", CHARACTER_WEAPON_ACTION_FRAME_COUNT)
		character_attack_right_frames = _load_frame_set(combo_base, "attack_right", CHARACTER_WEAPON_ACTION_FRAME_COUNT)
		character_hurt_frames = _load_frame_set(combo_base, "hurt", 3)
		if character_attack_left_frames.is_empty():
			character_attack_left_frames = character_attack_frames.duplicate()
		if character_attack_right_frames.is_empty():
			character_attack_right_frames = character_attack_frames.duplicate()
		if character_attack_frames.is_empty():
			character_attack_frames = character_idle_frames.duplicate()
		if character_hurt_frames.is_empty():
			character_hurt_frames = character_idle_frames.duplicate()
		character_weapon_combo_active = true
		var combo_key := "%s/%s" % [asset_id, weapon_id]
		character_weapon_combo_muzzle = CHARACTER_WEAPON_COMBO_MUZZLE.get(combo_key, Vector2(104, -82))
		return
	# Theme-only weaponless animation is a last-resort fallback for incomplete
	# content. Production validation requires every selectable weapon to resolve
	# through a fused combo or premium true-grip path before reaching this branch.
	var themed_base := ThemeManager.resolve_character_animation_base(asset_id)
	if themed_base != "":
		character_idle_frames = _load_frame_set(themed_base, "idle", 4)
		character_attack_frames = _load_frame_set(themed_base, "attack", 4)
		character_hurt_frames = _load_frame_set(themed_base, "hurt", 3)
		if character_attack_frames.is_empty():
			character_attack_frames = character_idle_frames.duplicate()
		if character_hurt_frames.is_empty():
			character_hurt_frames = character_idle_frames.duplicate()
		return
	var base := "res://assets/production/sprites/animations/characters_weaponless/%s/%s" % [asset_id, asset_id]
	if not _image_resource_exists("%s_idle_01.png" % base):
		base = "res://assets/production/sprites/animations/characters/%s/%s" % [asset_id, asset_id]
	character_idle_frames = _load_frame_set(base, "idle", 4)
	character_attack_left_frames = []
	character_attack_frames = _load_frame_set(base, "attack", 4)
	character_attack_right_frames = []
	character_hurt_frames = _load_frame_set(base, "hurt", 3)

func _load_premium_true_grip_frames(asset_id: String) -> bool:
	var grip: Dictionary = _weapon_presentation().get("true_grip", {})
	var root := str(grip.get("root", "")).trim_suffix("/")
	if root == "":
		return false
	var center_path := "%s/%s" % [root, str(grip.get("center_pattern", "")).replace("{character_id}", asset_id)]
	var left_path := "%s/%s" % [root, str(grip.get("left_pattern", "")).replace("{character_id}", asset_id)]
	var right_path := "%s/%s" % [root, str(grip.get("right_pattern", "")).replace("{character_id}", asset_id)]
	if not _image_resource_exists(center_path) or not _image_resource_exists(left_path) or not _image_resource_exists(right_path):
		push_error("Premium true-grip sprites missing for %s/%s" % [weapon_id, asset_id])
		return false
	var center_texture := load(center_path) as Texture2D
	var left_texture := load(left_path) as Texture2D
	var right_texture := load(right_path) as Texture2D
	if center_texture == null or left_texture == null or right_texture == null:
		push_error("Premium true-grip textures failed to load for %s/%s" % [weapon_id, asset_id])
		return false
	# One approved master per direction keeps the signature weapon compact. The
	# rig supplies breathing and recoil while every frame preserves exact
	# two-hand contact and shoulder bracing.
	character_idle_frames = _repeat_character_texture(center_texture, 4)
	character_attack_left_frames = _repeat_character_texture(left_texture, CHARACTER_WEAPON_ACTION_FRAME_COUNT)
	character_attack_frames = _repeat_character_texture(center_texture, CHARACTER_WEAPON_ACTION_FRAME_COUNT)
	character_attack_right_frames = _repeat_character_texture(right_texture, CHARACTER_WEAPON_ACTION_FRAME_COUNT)
	character_hurt_frames = _repeat_character_texture(center_texture, 3)
	character_weapon_combo_active = true
	character_weapon_combo_muzzle = _premium_true_grip_muzzle(asset_id, "center", Vector2(0.0, -124.0))
	return true

func _repeat_character_texture(texture: Texture2D, count: int) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	for _index in range(count):
		frames.append(texture)
	return frames

func _character_weapon_combo_base(asset_id: String) -> String:
	return "res://assets/production/sprites/animations/character_weapon_combos/%s/%s_%s" % [asset_id, asset_id, weapon_id]

func _load_character_weapon_animation_frames() -> void:
	var base := "res://assets/production/sprites/animations/weapons/%s/%s" % [weapon_id, weapon_id]
	character_weapon_idle_frames = _load_frame_set(base, "idle", 3)
	character_weapon_recoil_frames = _load_frame_set(base, "recoil", 4)

func _character_asset_id() -> String:
	match character_id:
		"vanguard":
			return "char_vanguard"
		"blaze":
			return "char_blaze"
		"frost":
			return "char_frost"
		"volt":
			return "char_volt"
		_:
			return "char_vanguard"

func _process_character_animation(delta: float) -> void:
	if character_sprite == null or character_rig == null:
		return
	var frames := character_idle_frames
	var fps := 7.0
	var forced_frame := -1
	var attack_playback := false
	var body_pose_key := "center" if _character_uses_true_grip() else "idle"
	if character_hurt_time > 0.0:
		frames = character_hurt_frames
		fps = 16.0
		body_pose_key = "center" if _character_uses_true_grip() else "hurt"
		character_hurt_time -= delta
	elif character_skill_time > 0.0:
		frames = _character_combo_attack_frames()
		fps = 12.0
		body_pose_key = _character_combo_effective_aim()
		character_skill_time -= delta
	elif character_attack_time > 0.0:
		frames = _character_combo_attack_frames()
		fps = float(maxi(frames.size() - CHARACTER_WEAPON_FIRE_FRAME_INDEX, 1)) / maxf(character_attack_duration, 0.08)
		attack_playback = true
		body_pose_key = _character_combo_effective_aim()
		character_attack_time -= delta
		if character_attack_time <= 0.0:
			character_weapon_combo_locked_aim = ""
	elif _character_prefire_active():
		frames = _character_combo_attack_frames()
		forced_frame = 0
		body_pose_key = _character_combo_effective_aim()
		character_anim_time = 0.0
	if not frames.is_empty():
		var next_frame := forced_frame
		if forced_frame < 0:
			character_anim_time += delta
			next_frame = int(character_anim_time * fps)
			if attack_playback:
				next_frame += CHARACTER_WEAPON_FIRE_FRAME_INDEX
		if character_hurt_time > 0.0 or attack_playback or character_skill_time > 0.0:
			next_frame = mini(next_frame, frames.size() - 1)
		else:
			next_frame = next_frame % frames.size()
		if next_frame != character_anim_frame:
			character_anim_frame = next_frame
		character_sprite.texture = frames[character_anim_frame]
	_update_character_body_pose(body_pose_key)
	_update_character_weapon_pose(delta)
	_update_character_aura(delta)

func _character_combo_attack_frames() -> Array[Texture2D]:
	if not character_weapon_combo_active:
		return character_attack_frames
	var aim := _character_combo_effective_aim()
	if aim == "left" and not character_attack_left_frames.is_empty():
		return character_attack_left_frames
	if aim == "right" and not character_attack_right_frames.is_empty():
		return character_attack_right_frames
	return character_attack_frames

func _play_character_attack() -> void:
	character_attack_duration = _weapon_presentation_float("attack_duration", float(CHARACTER_WEAPON_ATTACK_DURATION.get(weapon_id, 0.32)))
	character_attack_time = character_attack_duration
	character_anim_time = 0.0
	character_weapon_combo_locked_aim = character_weapon_combo_aim
	var frames := _character_combo_attack_frames()
	character_anim_frame = mini(CHARACTER_WEAPON_FIRE_FRAME_INDEX, maxi(frames.size() - 1, 0))
	if character_sprite != null and not frames.is_empty():
		character_sprite.texture = frames[character_anim_frame]
	_play_character_weapon_recoil(minf(character_attack_duration, 0.28))

func _character_prefire_active() -> bool:
	if not character_weapon_combo_active or turret == null:
		return false
	if not bool(turret.fire_enabled) or float(turret.cooldown) <= 0.0:
		return false
	var shot_interval := 1.0 / maxf(float(turret.fire_rate), 0.01)
	var authored_lead := _weapon_presentation_float("prefire_lead", float(CHARACTER_WEAPON_PREFIRE_LEAD.get(weapon_id, 0.075)))
	return float(turret.cooldown) <= minf(authored_lead, shot_interval * 0.42)

func _play_character_skill(duration := 0.56) -> void:
	character_skill_time = duration
	character_anim_time = 0.0
	character_anim_frame = 0
	_play_character_weapon_recoil(0.28)
	if character_sprite:
		var color := _element_color(str(character_data.get("element_focus", "physical")))
		_spawn_levelup_vfx(character_sprite.global_position + Vector2(0, -28), color, 0.38)

func _play_character_hurt() -> void:
	character_hurt_time = 0.28
	character_anim_time = 0.0
	character_anim_frame = 0
	if character_sprite:
		_spawn_levelup_vfx(character_sprite.global_position, Color(1.0, 0.25, 0.2), 0.36)

func _update_character_body_pose(pose_key := "") -> void:
	var resolved_pose := pose_key if pose_key != "" else _character_current_body_pose_key()
	var normalized_scale := _character_body_sprite_scale(resolved_pose)
	var breathe := sin(Time.get_ticks_msec() / 420.0)
	var pose_offset := _character_body_anchor_offset(resolved_pose, normalized_scale)
	pose_offset += Vector2(0.0, -absf(breathe) * 3.0)
	var pose_rotation := 0.0
	# Character level is deliberately excluded from body size. Growth still has
	# badges, color and gameplay stats, while every hero/outfit keeps the same
	# anatomical height on the battlefield.
	var pose_scale := Vector2.ONE * normalized_scale
	if character_hurt_time > 0.0:
		var hurt_ratio := clampf(character_hurt_time / 0.28, 0.0, 1.0)
		pose_offset += Vector2(randf_range(-2.5, 2.5), 10.0 * hurt_ratio)
		pose_rotation = deg_to_rad(-2.2) * hurt_ratio
	elif character_skill_time > 0.0:
		var progress := 1.0 - clampf(character_skill_time / 0.56, 0.0, 1.0)
		var pulse := sin(progress * PI)
		pose_offset += Vector2(0.0, -12.0 * pulse)
		pose_scale *= 1.0 + 0.035 * pulse
	elif character_attack_time > 0.0:
		var recoil_curve := float(CHARACTER_WEAPON_ACTION_RECOIL_CURVE[clampi(character_anim_frame, 0, CHARACTER_WEAPON_ACTION_RECOIL_CURVE.size() - 1)])
		var recoil_strength := _weapon_presentation_float("recoil_pose", float(CHARACTER_WEAPON_RECOIL_POSE.get(weapon_id, 14.0)))
		# The bitmap already carries the full-body recoil. This small rig-level
		# accent supplies contact weight without double-moving the held weapon.
		var recoil_accent := _weapon_presentation_float("recoil_accent", 0.24)
		var recoil_twist := _weapon_presentation_float("recoil_twist", 0.9)
		pose_offset += -character_weapon_direction * (recoil_strength * recoil_curve * recoil_accent)
		pose_rotation = deg_to_rad(clampf(character_weapon_direction.x, -0.8, 0.8) * recoil_twist * recoil_curve)
		pose_scale *= 1.0 + 0.004 * maxf(recoil_curve, 0.0)
	character_sprite.position = pose_offset
	character_sprite.rotation = pose_rotation
	character_sprite.scale = pose_scale

func _spawn_character_weapon_glow() -> void:
	if character_weapon_sprite == null:
		return
	character_weapon_glow = Sprite2D.new()
	character_weapon_glow.name = "WeaponGlow"
	character_weapon_glow.texture = load("res://assets/production/sprites/vfx/vfx_levelup_glow.png")
	character_weapon_glow.position = Vector2(0, -190)
	character_weapon_glow.scale = Vector2(0.18, 0.18)
	character_weapon_glow.z_index = -1
	var color := _element_color(str(DataLoader.get_row("weapons", weapon_id).get("element", "physical")))
	color.a = 0.2 + 0.04 * float(_growth_rank(weapon_level))
	character_weapon_glow.modulate = color
	character_weapon_sprite.add_child(character_weapon_glow)

func _update_character_weapon_pose(delta: float) -> void:
	var socket := _weapon_socket_global()
	var desired_direction := _weapon_aim_direction_from(socket)
	character_weapon_direction = character_weapon_direction.lerp(desired_direction, minf(delta * 14.0, 1.0)).normalized()
	if character_weapon_direction.length_squared() <= 0.01:
		character_weapon_direction = CHARACTER_WEAPON_DEFAULT_DIRECTION
	if character_weapon_combo_active:
		if character_weapon_combo_locked_aim == "":
			if turret != null:
				_set_character_combo_aim_from_target(turret.target_point)
			else:
				_set_character_combo_aim_from_direction(character_weapon_direction)
		return
	if character_weapon_sprite == null:
		return
	_update_character_weapon_frames(delta)
	var recoil := 0.0
	if character_weapon_recoil_time > 0.0:
		var progress := 1.0 - clampf(character_weapon_recoil_time / maxf(character_weapon_recoil_offset, 0.001), 0.0, 1.0)
		recoil = sin(progress * PI) * 22.0
	character_weapon_sprite.position = CHARACTER_WEAPON_SOCKET - character_weapon_direction * recoil
	character_weapon_sprite.rotation = character_weapon_direction.angle()
	character_weapon_sprite.scale = Vector2.ONE * _weapon_visual_scale()
	if character_weapon_glow:
		character_weapon_glow.rotation -= delta * 1.5
		var pulse := 0.82 + absf(sin(Time.get_ticks_msec() / 260.0)) * 0.2
		character_weapon_glow.scale = Vector2(0.18, 0.18) * pulse

func _update_character_weapon_frames(delta: float) -> void:
	var recoil_active := character_weapon_recoil_time > 0.0
	var frames := character_weapon_recoil_frames if recoil_active and not character_weapon_recoil_frames.is_empty() else character_weapon_idle_frames
	if recoil_active:
		character_weapon_recoil_time = maxf(0.0, character_weapon_recoil_time - delta)
	if frames.is_empty():
		return
	character_weapon_anim_time += delta
	var fps := 22.0 if recoil_active else 7.0
	var next_frame := int(character_weapon_anim_time * fps)
	if recoil_active:
		next_frame = mini(next_frame, frames.size() - 1)
	else:
		next_frame = next_frame % frames.size()
	if next_frame != character_weapon_anim_frame:
		character_weapon_anim_frame = next_frame
		character_weapon_sprite.texture = frames[character_weapon_anim_frame]

func _play_character_weapon_recoil(duration := 0.16) -> void:
	character_weapon_recoil_time = duration
	character_weapon_recoil_offset = duration
	character_weapon_anim_time = 0.0
	character_weapon_anim_frame = 0

func _weapon_visual_scale() -> float:
	var base_scale := _weapon_presentation_float("weapon_scale", float(CHARACTER_WEAPON_SCALE.get(weapon_id, 0.52)))
	return base_scale * (1.0 + clampf(float(weapon_level - 1) * 0.0025, 0.0, 0.1))

func _weapon_presentation(id := "") -> Dictionary:
	var resolved_id := id if id != "" else weapon_id
	return (DataLoader.get_row("weapons", resolved_id).get("presentation", {}) as Dictionary).duplicate(true)

func _weapon_presentation_float(key: String, fallback: float) -> float:
	return float(_weapon_presentation().get(key, fallback))

func _premium_true_grip_muzzle(asset_id: String, aim: String, fallback: Vector2) -> Vector2:
	var grip: Dictionary = _weapon_presentation().get("true_grip", {})
	var by_character: Dictionary = grip.get("muzzle_by_character", {})
	var per_character: Dictionary = by_character.get(asset_id, {})
	var raw: Variant = per_character.get(aim, [])
	if raw is Array and raw.size() >= 2:
		return Vector2(float(raw[0]), float(raw[1]))
	return fallback

func _weapon_visual_profile(id := "") -> String:
	var resolved_id := id if id != "" else weapon_id
	var row := DataLoader.get_row("weapons", resolved_id)
	return str(row.get("visual_profile", WEAPON_VISUAL_PROFILES.get(resolved_id, "")))

func _resolved_weapon_projectile_visual_profile(base_element: String, effective_element: String, base_profile: String) -> String:
	# Attribute-ammo skills already change the damage element. Keep the authored
	# profile only when the weapon remains on its native element. A free physical
	# weapon converted to fire / ice / lightning / poison must also change its
	# projectile model, muzzle, trail, and impact presentation instead of retaining
	# the original ballistic rail/scatter/autocannon shell.
	#
	# Paid Apocalypse weapons may now override their native element with an ammo
	# card. The held weapon keeps its authored identity, while the projectile uses
	# the single effective element so visuals, resistance and native mechanisms
	# cannot imply a second damage channel.
	if base_element == effective_element:
		return base_profile
	return "%s%s" % [ELEMENTAL_AMMO_VISUAL_PROFILE_PREFIX, effective_element]

func _sync_logic_turret_to_character() -> void:
	if turret == null:
		return
	turret.global_position = _weapon_socket_global()
	if _audit_combat_rng != null:
		turret.force_update_transform()

func _weapon_socket_global() -> Vector2:
	if character_rig != null:
		if character_weapon_combo_active:
			return character_rig.to_global(_character_combo_muzzle_for_aim())
		return character_rig.to_global(CHARACTER_WEAPON_SOCKET)
	if turret != null:
		return turret.global_position
	return Vector2(540, 1660.0 + bottom_dock_shift)

func _character_combo_key() -> String:
	return "%s/%s" % [_character_asset_id(), weapon_id]

func _character_combo_effective_aim() -> String:
	if character_weapon_combo_locked_aim != "":
		return character_weapon_combo_locked_aim
	return character_weapon_combo_aim

func _character_combo_muzzle_for_aim() -> Vector2:
	var aim := _character_combo_effective_aim()
	return _character_combo_muzzle_for_pose(aim)

func _character_combo_muzzle_for_pose(aim: String) -> Vector2:
	var combo_key := _character_combo_key()
	var fallback := character_weapon_combo_muzzle
	if aim == "left":
		fallback = CHARACTER_WEAPON_COMBO_MUZZLE_LEFT.get(combo_key, character_weapon_combo_muzzle)
	elif aim == "right":
		fallback = CHARACTER_WEAPON_COMBO_MUZZLE_RIGHT.get(combo_key, character_weapon_combo_muzzle)
	var authored_muzzle := _premium_true_grip_muzzle(_character_asset_id(), aim, fallback)
	var sprite_scale := _character_body_sprite_scale(aim)
	var body_anchor := _character_body_anchor_offset(aim, sprite_scale)
	return body_anchor + authored_muzzle * (sprite_scale / CHARACTER_VISUAL_BASE_SCALE)

func _character_pose_aim_reference_global() -> Vector2:
	if character_rig == null:
		return CHARACTER_BASE_POSITION
	if not character_weapon_combo_active:
		return character_rig.to_global(Vector2(0.0, CHARACTER_WEAPON_SOCKET.y))
	# Keep the reference at the centre of the actor, but at the authored centre
	# muzzle height. Horizontal left/right muzzle displacement is deliberately
	# excluded so changing pose cannot change the next pose decision.
	var center_muzzle := _character_combo_muzzle_for_pose("center")
	return character_rig.to_global(Vector2(0.0, center_muzzle.y))

func _set_character_combo_aim_from_target(target_point: Vector2) -> void:
	var direction := target_point - _character_pose_aim_reference_global()
	_set_character_combo_aim_from_direction(direction)

func _set_character_combo_aim_from_direction(direction: Vector2) -> void:
	if not character_weapon_combo_active:
		return
	if direction.length_squared() <= 0.01:
		character_weapon_combo_aim = "center"
	else:
		var normalized_x := direction.normalized().x
		var current_aim := _character_combo_effective_aim()
		match current_aim:
			"left":
				if normalized_x <= -CHARACTER_COMBO_SIDE_AIM_EXIT_X:
					character_weapon_combo_aim = "left"
				elif normalized_x >= CHARACTER_COMBO_SIDE_AIM_ENTER_X:
					character_weapon_combo_aim = "right"
				else:
					character_weapon_combo_aim = "center"
			"right":
				if normalized_x >= CHARACTER_COMBO_SIDE_AIM_EXIT_X:
					character_weapon_combo_aim = "right"
				elif normalized_x <= -CHARACTER_COMBO_SIDE_AIM_ENTER_X:
					character_weapon_combo_aim = "left"
				else:
					character_weapon_combo_aim = "center"
			_:
				if normalized_x <= -CHARACTER_COMBO_SIDE_AIM_ENTER_X:
					character_weapon_combo_aim = "left"
				elif normalized_x >= CHARACTER_COMBO_SIDE_AIM_ENTER_X:
					character_weapon_combo_aim = "right"
				else:
					character_weapon_combo_aim = "center"
	if character_weapon_combo_locked_aim != "":
		character_weapon_combo_locked_aim = character_weapon_combo_aim

func _weapon_fire_origin(include_muzzle := true) -> Vector2:
	var socket := _weapon_socket_global()
	if character_weapon_combo_active:
		return socket
	if character_weapon_sprite != null:
		socket = character_weapon_sprite.global_position
	if not include_muzzle:
		return socket
	var direction := _weapon_aim_direction_from(socket)
	var muzzle_distance := _weapon_presentation_float("muzzle_distance", float(CHARACTER_WEAPON_MUZZLE_DISTANCE.get(weapon_id, 70.0)))
	return socket + direction * muzzle_distance * CHARACTER_PRESENTATION_SCALE

func _weapon_fire_direction(fallback := Vector2.UP) -> Vector2:
	var origin := _weapon_fire_origin(false)
	var direction := _weapon_aim_direction_from(origin)
	if direction.length_squared() <= 0.01:
		return fallback.normalized() if fallback.length_squared() > 0.01 else CHARACTER_WEAPON_DEFAULT_DIRECTION
	return direction

func _weapon_aim_direction_from(origin: Vector2) -> Vector2:
	var target := origin + CHARACTER_WEAPON_DEFAULT_DIRECTION * 300.0
	if turret != null:
		target = turret.target_point
	var direction := target - origin
	if direction.length_squared() <= 4.0:
		return character_weapon_direction if character_weapon_direction.length_squared() > 0.01 else CHARACTER_WEAPON_DEFAULT_DIRECTION
	return direction.normalized()

func _load_pet_animation_frames(sprite_path: String) -> void:
	var asset_id := sprite_path.get_file().get_basename().replace("_prototype", "")
	if asset_id == "":
		return
	var base := "res://assets/production/sprites/animations/pets/%s/%s" % [asset_id, asset_id]
	pet_idle_frames = _load_frame_set(base, "idle", 4)
	pet_attack_frames = _load_frame_set(base, "attack", 4)
	if pet_sprite and not pet_idle_frames.is_empty():
		pet_sprite.texture = pet_idle_frames[0]

func _update_pet_animation(delta: float) -> void:
	if pet_sprite == null:
		return
	var frames := pet_attack_frames if pet_attack_time > 0.0 else pet_idle_frames
	if frames.is_empty():
		return
	pet_anim_time += delta
	if pet_attack_time > 0.0:
		pet_attack_time -= delta
	var fps := 16.0 if pet_attack_time > 0.0 else 7.0
	var next_frame := int(pet_anim_time * fps)
	if pet_attack_time > 0.0:
		next_frame = mini(next_frame, frames.size() - 1)
	else:
		next_frame = next_frame % frames.size()
	if next_frame != pet_anim_frame:
		pet_anim_frame = next_frame
		pet_sprite.texture = frames[pet_anim_frame]
	pet_sprite.position.y = _pet_anchor_position().y - absf(sin(Time.get_ticks_msec() / 300.0)) * PET_IDLE_FLOAT_AMPLITUDE
	_update_pet_aura(delta)

func _load_frame_set(base: String, anim: String, max_count: int) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	for i in range(1, max_count + 1):
		var path := "%s_%s_%02d.png" % [base, anim, i]
		if _image_resource_exists(path):
			var tex := _load_image_texture(path)
			if tex:
				frames.append(tex)
	return frames

func _image_resource_exists(path: String) -> bool:
	if ResourceLoader.exists(path):
		return true
	if path.begins_with("res://"):
		return false
	return FileAccess.file_exists(path)

func _load_image_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var loaded := load(path) as Texture2D
		if loaded != null:
			return loaded
	if path.begins_with("res://"):
		return null
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	if image.load(path) != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	texture.resource_path = path
	return texture

func _process_pet(delta: float) -> void:
	if pet_sprite == null or pet_data.is_empty():
		return
	_update_pet_animation(delta)
	_process_pet_skill(delta)
	if pet_data.get("role", "") == "repair":
		_process_repair_pet(delta)
		return
	pet_cooldown -= delta
	if pet_cooldown > 0.0:
		return
	var fire_rate := float(pet_data.get("fire_rate", 0.0))
	var shot_damage := _pet_scaled_value("damage", "level_damage_growth")
	var skill := _pet_skill_data()
	if str(skill.get("kind", "")) == "overclock" and pet_skill_timer > 0.0:
		fire_rate *= _pet_skill_linear_value("fire_rate_mult", "level_fire_rate_growth")
		shot_damage *= _pet_skill_linear_value("damage_mult", "level_damage_mult_growth")
	if fire_rate <= 0.0:
		return
	var pet_targets: Array[Node] = $EnemyLayer.get_children()
	if _audit_combat_rng != null:
		pet_targets.sort_custom(_audit_enemy_precedes)
	var pet_origin := _pet_combat_origin()
	var target := target_manager.choose_target(pet_targets, pet_origin)
	if target == null:
		return
	pet_cooldown = 1.0 / fire_rate
	AudioManager.play_sfx(_element_muzzle_sfx(str(pet_data.get("element", "physical"))), -12.0, 0.03)
	pet_attack_time = 0.22
	pet_anim_time = 0.0
	pet_anim_frame = 0
	var direction: Vector2 = (target.global_position - pet_origin).normalized()
	var projectile := PROJECTILE_SCENE.instantiate()
	_configure_audit_projectile(projectile)
	projectile.setup(
		pet_origin,
		direction,
		1120.0,
		shot_damage,
		str(pet_data.get("element", "physical")),
		0,
		0
	)
	projectile.damage_source = "phoenix" if str(pet_data.get("role", "")) == "apocalypse_fire" else "pet"
	projectile.hit_confirmed.connect(_on_projectile_hit_confirmed)
	$ProjectileLayer.add_child(projectile)
	_activate_audit_physics_node(projectile)

func _process_pet_skill(delta: float) -> void:
	if battle_finished:
		return
	pet_skill_timer = maxf(0.0, pet_skill_timer - delta)
	var skill := _pet_skill_data()
	var kind := str(skill.get("kind", ""))
	if kind in ["", "repair", "wave_salvage"]:
		return
	pet_skill_cooldown = maxf(0.0, pet_skill_cooldown - delta)
	if pet_skill_cooldown > 0.0:
		return
	var targets := _pet_skill_targets(1)
	if targets.is_empty():
		return
	match kind:
		"overclock":
			_activate_pet_overclock(skill)
		"area_blast":
			_activate_pet_area_blast(skill, targets[0])
		"multi_strike":
			_activate_pet_multi_strike(skill)
		"fire_flyby":
			_activate_pet_fire_flyby(skill)
		"golden_mark":
			_activate_pet_golden_mark(skill, targets[0])
		_:
			return
	pet_skill_cooldown = maxf(1.0, float(skill.get("cooldown", 12.0)))

func _activate_pet_overclock(skill: Dictionary) -> void:
	pet_skill_timer = maxf(0.5, _pet_skill_linear_value("duration", "level_duration_growth"))
	pet_cooldown = 0.0
	var color := _element_color(str(pet_data.get("element", "physical")))
	_play_pet_skill_feedback(skill, pet_sprite.global_position + Vector2(0, -36), color, 132.0)

func _activate_pet_area_blast(skill: Dictionary, target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return
	var origin := target.global_position
	var element := str(pet_data.get("element", "physical"))
	var color := _element_color(element)
	var radius := _pet_skill_linear_value("radius", "level_radius_growth")
	var damage := _pet_scaled_value("damage", "level_damage_growth") * _pet_skill_linear_value("damage_mult", "level_damage_mult_growth")
	var status_strength := _pet_skill_linear_value("status_strength", "level_status_growth")
	for enemy in $EnemyLayer.get_children():
		if not is_instance_valid(enemy) or not enemy is Node2D or not enemy.has_method("take_damage"):
			continue
		var distance := (enemy as Node2D).global_position.distance_to(origin)
		if distance > radius:
			continue
		var falloff := 1.0 - clampf(distance / maxf(radius, 1.0), 0.0, 1.0)
		enemy.take_damage(damage * (0.62 + falloff * 0.38), element, 0.0, status_strength)
	if element == "fire":
		_spawn_radial_vfx(origin, radius, Color(color.r, color.g, color.b, 0.62))
	else:
		_spawn_attack_ring(origin, radius, Color(color.r, color.g, color.b, 0.72), 0.34)
		_spawn_vfx_sequence(str(skill.get("sequence", "")), origin + Vector2(0, -28), clampf(radius / 190.0, 0.78, 1.55), Color(color.r, color.g, color.b, 0.82), 1.06, 0.0, 1.08, Vector2(0, -10), 0.0, radius >= 250.0)
	_play_pet_skill_feedback(skill, pet_sprite.global_position + Vector2(0, -34), color, 116.0, false)

func _activate_pet_multi_strike(skill: Dictionary) -> void:
	var extra_every := maxi(1, int(skill.get("extra_target_every", 10)))
	var target_count := int(skill.get("target_count", 1)) + int(max(pet_level - 1, 0) / extra_every)
	var targets := _pet_skill_targets(maxi(target_count, 1))
	if targets.is_empty():
		return
	var element := str(pet_data.get("element", "lightning"))
	var color := _element_color(element)
	var damage := _pet_scaled_value("damage", "level_damage_growth") * _pet_skill_linear_value("damage_mult", "level_damage_mult_growth")
	var status_strength := _pet_skill_linear_value("status_strength", "level_status_growth")
	var falloff := clampf(float(skill.get("target_falloff", 0.9)), 0.55, 1.0)
	var arc_origin := pet_sprite.global_position + Vector2(0, -24)
	for i in range(targets.size()):
		var target := targets[i]
		if target == null or not is_instance_valid(target):
			continue
		target.take_damage(damage * pow(falloff, float(i)), element, 0.0, status_strength)
		var impact := target.global_position + Vector2(0, -28)
		_spawn_weapon_trace(arc_origin, impact, Color(0.72, 0.96, 1.0, 0.84), 15.0, 0.17)
		_spawn_chain_arc(arc_origin, impact, element)
		arc_origin = impact
	_play_pet_skill_feedback(skill, pet_sprite.global_position + Vector2(0, -34), color, 124.0)


func _activate_pet_fire_flyby(skill: Dictionary) -> void:
	var extra_every := maxi(1, int(skill.get("extra_target_every", 10)))
	var target_count := int(skill.get("target_count", 1)) + int(max(pet_level - 1, 0) / extra_every)
	var targets := _pet_skill_targets(maxi(target_count, 1))
	if targets.is_empty():
		return
	var damage := _pet_scaled_value("damage", "level_damage_growth") * _pet_skill_linear_value("damage_mult", "level_damage_mult_growth")
	var status_strength := _pet_skill_linear_value("status_strength", "level_status_growth")
	var falloff := clampf(float(skill.get("target_falloff", 0.88)), 0.55, 1.0)
	var flyby_origin := pet_sprite.global_position + Vector2(0, -30)
	var reduced := SettingsManager.reduced_effects_enabled()
	var trail_budget := mini(int(skill.get("trail_max_concurrent", 2)), 1 if reduced else 2)
	_spawn_attack_ring(flyby_origin, 112.0, Color(1.0, 0.38, 0.06, 0.44), 0.24)
	for index in range(targets.size()):
		var target := targets[index]
		if target == null or not is_instance_valid(target):
			continue
		var impact := target.global_position + Vector2(0, -30)
		var travel := impact - flyby_origin
		_deal_damage_with_source(target, damage * pow(falloff, float(index)), "fire", 0.0, status_strength, "phoenix")
		_spawn_muzzle_light_cone(flyby_origin, travel.normalized(), Color(1.0, 0.36, 0.06, 0.68), travel.length(), 30.0, 0.18, 5.0)
		if index < trail_budget:
			_spawn_weapon_trace(flyby_origin, impact, Color(1.0, 0.56, 0.10, 0.78), 18.0, 0.24)
		# One authored phoenix crosses the first real path. Later targets keep the
		# readable molten trail without duplicating four birds over the horde.
		if index == 0 and travel.length_squared() > 1.0:
			var midpoint := flyby_origin.lerp(impact, 0.52)
			var desired_scale := 0.72 if reduced else 0.96
			_spawn_vfx_sequence(
				"vfx_apocalypse_inferno_phoenix",
				midpoint,
				_inferno_edge_safe_vfx_scale(midpoint, desired_scale),
				Color(1.0, 0.92, 0.72, 0.64 if reduced else 0.94),
				1.0,
				_directional_vfx_rotation("vfx_apocalypse_inferno_phoenix", travel),
				1.02,
				travel.normalized() * 34.0,
				0.0,
				true
			)
		flyby_origin = impact
	_play_pet_skill_feedback(skill, pet_sprite.global_position + Vector2(0, -34), Color(1.0, 0.40, 0.06, 1.0), 136.0, false)
	SettingsManager.pulse_haptic("medium")


func _activate_pet_golden_mark(skill: Dictionary, target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return
	var damage := _pet_scaled_value("damage", "level_damage_growth") * _pet_skill_linear_value("damage_mult", "level_damage_mult_growth")
	_deal_damage_with_source(target, damage, "physical", 0.18, 0.0, "skyfalcon_mark")
	var duration := _pet_skill_linear_value("mark_duration", "level_mark_duration_growth")
	var amp := _pet_skill_linear_value("mark_damage_amp", "level_mark_amp_growth")
	target.set_meta("golden_law_mark_until", _gameplay_now_seconds() + duration)
	target.set_meta("golden_law_mark_amp", amp)
	var repair_ratio := _pet_skill_linear_value("repair_ratio", "level_repair_growth")
	var restored := maxi(1, int(round(float(base_hp_max) * repair_ratio)))
	base_hp = mini(base_hp_max, base_hp + restored)
	var origin := target.global_position + Vector2(0, -44 if not _is_boss_node(target) else -82)
	_spawn_vfx_sequence("vfx_apocalypse_golden_law_falcon", origin, 0.74 if SettingsManager.reduced_effects_enabled() else 0.98, Color(1.0, 0.88, 0.52, 0.90), 1.0, 0.0, 1.02, Vector2(0, -5), 0.0, true)
	_spawn_float_text(target.global_position + Vector2(-78, -114), LocalizationManager.text("天隼敕印"), Color(1.0, 0.84, 0.36, 1.0), true, 22, 220.0)
	_play_pet_skill_feedback(skill, pet_sprite.global_position + Vector2(0, -34), Color(1.0, 0.76, 0.24, 1.0), 132.0, false)
	AudioManager.play_sfx("apocalypse_golden_law_falcon", -4.5, 0.02)

func _pet_skill_targets(max_count: int) -> Array[Node2D]:
	var valid: Array[Node] = []
	for enemy in $EnemyLayer.get_children():
		if not is_instance_valid(enemy) or not enemy is Node2D or not enemy.has_method("targeting_snapshot"):
			continue
		var hp_value = enemy.get("hp")
		if hp_value != null and float(hp_value) <= 0.0:
			continue
		valid.append(enemy)
	if _audit_combat_rng != null:
		valid.sort_custom(_audit_enemy_precedes)
	if valid.is_empty():
		return []
	var result: Array[Node2D] = []
	var pet_origin := _pet_combat_origin()
	var primary = target_manager.choose_target(valid, pet_origin) if target_manager != null else valid[0]
	if primary is Node2D and is_instance_valid(primary):
		result.append(primary as Node2D)
	var ranked: Array[Dictionary] = []
	for enemy in valid:
		if enemy == primary:
			continue
		var snapshot: Dictionary = enemy.targeting_snapshot()
		var score := target_manager.score_enemy(snapshot, pet_origin) if target_manager != null else float(snapshot.get("y", 0.0))
		ranked.append({"enemy": enemy, "score": score})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_score := float(a.get("score", 0.0))
		var b_score := float(b.get("score", 0.0))
		if not is_equal_approx(a_score, b_score):
			return a_score > b_score
		return _audit_enemy_precedes(a.get("enemy") as Node, b.get("enemy") as Node)
	)
	for item in ranked:
		if result.size() >= max_count:
			break
		var enemy_node := item.get("enemy") as Node2D
		if enemy_node != null and is_instance_valid(enemy_node):
			result.append(enemy_node)
	return result

func _pet_skill_data() -> Dictionary:
	var value = pet_data.get("pet_skill", {})
	return value if value is Dictionary else {}

func _pet_skill_linear_value(key: String, growth_key: String) -> float:
	var skill := _pet_skill_data()
	return float(skill.get(key, 0.0)) + float(skill.get(growth_key, 0.0)) * float(max(pet_level - 1, 0))

func _play_pet_skill_feedback(skill: Dictionary, origin: Vector2, color: Color, radius: float, spawn_sequence := true) -> void:
	pet_attack_time = 0.32
	pet_anim_time = 0.0
	pet_anim_frame = 0
	if spawn_sequence:
		_spawn_vfx_sequence(str(skill.get("sequence", "")), origin, clampf(radius / 128.0, 0.74, 1.36), Color(color.r, color.g, color.b, 0.84), 1.08, 0.0, 1.08, Vector2(0, -8), 0.0, radius >= 128.0)
	_spawn_attack_ring(origin, radius, Color(color.r, color.g, color.b, 0.62), 0.3)
	_spawn_float_text(origin + Vector2(-110, -76), str(skill.get("name", "宠物技能")), color, true, 22, 220.0)
	var sfx_id := str(skill.get("sfx", ""))
	if sfx_id != "":
		AudioManager.play_sfx(sfx_id, -8.5, 0.025)

func _apply_pet_wave_salvage() -> int:
	var skill := _pet_skill_data()
	if str(skill.get("kind", "")) != "wave_salvage":
		return 0
	var equivalent := _pet_skill_linear_value("kill_equivalent", "level_salvage_growth")
	var gold_per_kill := econ_gold_base + econ_gold_per * float(level_ordinal)
	var amount := maxi(1, int(round(gold_per_kill * equivalent * gold_mult * skills.gold_multiplier() * variant_gold_mult)))
	gold += amount
	if pet_sprite != null and is_instance_valid(pet_sprite):
		var color := Color(1.0, 0.82, 0.26, 0.96)
		_play_pet_skill_feedback(skill, pet_sprite.global_position + Vector2(0, -34), color, 126.0)
		_spawn_float_text(pet_sprite.global_position + Vector2(-110, -118), "+%d 战场回收" % amount, color, true, 22, 220.0)
	_pulse_reward_target("gold")
	_update_hud()
	return amount

func _process_repair_pet(delta: float) -> void:
	if battle_finished or base_hp_max <= 0:
		return
	pet_repair_cooldown = maxf(0.0, pet_repair_cooldown - delta)
	pet_emergency_cooldown = maxf(0.0, pet_emergency_cooldown - delta)
	if base_hp >= base_hp_max:
		return
	var hp_ratio := float(base_hp) / float(base_hp_max)
	var emergency_threshold := clampf(float(pet_data.get("emergency_threshold", 0.0)), 0.0, 1.0)
	if emergency_threshold > 0.0 and hp_ratio <= emergency_threshold and pet_emergency_cooldown <= 0.0:
		var emergency_ratio := _pet_linear_value("emergency_heal_ratio", "level_emergency_heal_growth")
		if _apply_pet_base_heal(int(round(float(base_hp_max) * emergency_ratio)), "应急救援", true) > 0:
			pet_emergency_cooldown = maxf(1.0, float(pet_data.get("emergency_cooldown", 45.0)))
			pet_repair_cooldown = maxf(1.0, float(pet_data.get("repair_interval", 18.0)))
		return
	if pet_repair_cooldown > 0.0:
		return
	var repair_ratio := _pet_linear_value("repair_ratio", "level_repair_ratio_growth")
	_apply_pet_base_heal(int(round(float(base_hp_max) * repair_ratio)), "持续维修", false)
	pet_repair_cooldown = maxf(1.0, float(pet_data.get("repair_interval", 18.0)))

func _apply_pet_base_heal(amount: int, label_text: String, major: bool) -> int:
	if amount <= 0 or base_hp >= base_hp_max:
		return 0
	var previous_hp := base_hp
	base_hp = mini(base_hp_max, base_hp + amount)
	var actual_heal := base_hp - previous_hp
	if actual_heal <= 0:
		return 0
	var repair_color := Color(0.35, 1.0, 0.68, 0.92)
	var impact := _base_damage_impact_position(540.0) + Vector2(0, -18.0)
	if pet_sprite != null and is_instance_valid(pet_sprite):
		pet_attack_time = 0.28 if major else 0.20
		pet_anim_time = 0.0
		pet_anim_frame = 0
		_spawn_weapon_trace(pet_sprite.global_position + Vector2(0, -18.0), impact, repair_color, 14.0 if major else 8.0, 0.24 if major else 0.18)
	_spawn_vfx_sequence("vfx_enemy_skill_regen", impact + Vector2(0, -32.0), 0.94 if major else 0.68, repair_color, 1.05, 0.0, 1.04, Vector2(0, -8.0), 0.0, major)
	_spawn_attack_ring(impact, 176.0 if major else 116.0, repair_color, 0.34 if major else 0.24)
	_spawn_float_text(impact + Vector2(0, -72.0), "+%d %s" % [actual_heal, label_text], repair_color)
	AudioManager.play_sfx("level_up", -9.0 if major else -13.0, 0.025)
	_pulse_reward_target("hp")
	_update_hud()
	return actual_heal

func _track_transient_fx(node: Node, bucket: String) -> void:
	node.set_meta("battle_transient_fx", bucket)
	if bucket == "projectile":
		node.set_meta("transient_vfx", true)

func _can_spawn_projectile_fx(priority := false) -> bool:
	# Runtime probes own a deterministic authored combat clock and intentionally
	# skip presentation-only nodes.  Their deferred/tween lifetimes otherwise
	# depend on how many authored ticks are batched into one host frame.
	if _audit_combat_rng != null:
		return false
	var base_limit := MAX_PROJECTILE_PRIORITY_FX if priority else MAX_PROJECTILE_TRANSIENT_FX
	return _transient_fx_count($ProjectileLayer, "projectile") < _scaled_vfx_budget(base_limit, priority)

func _can_spawn_hud_fx(priority := false) -> bool:
	if _audit_combat_rng != null:
		return false
	var base_limit := MAX_HUD_PRIORITY_FX if priority else MAX_HUD_TRANSIENT_FX
	return _transient_fx_count($Hud, "hud") < _scaled_vfx_budget(base_limit, priority)

func _scaled_vfx_budget(base_limit: int, priority: bool) -> int:
	var scale := 1.0
	if SettingsManager.get_quality() == "battery":
		scale *= 0.62 if priority else 0.48
	if SettingsManager.reduced_effects_enabled():
		scale *= 0.82 if priority else 0.68
	if battle_speed >= 4.5:
		scale *= 0.64 if priority else 0.42
	elif battle_speed >= 1.5:
		scale *= 0.82 if priority else 0.66
	var enemy_count := $EnemyLayer.get_child_count() if has_node("EnemyLayer") else 0
	if enemy_count >= 100:
		scale *= 0.72 if priority else 0.54
	elif enemy_count >= 60:
		scale *= 0.86 if priority else 0.72
	return maxi(18 if priority else 12, int(round(float(base_limit) * scale)))

func _can_spawn_float_text(priority := false) -> bool:
	if _audit_combat_rng != null:
		return false
	var base_limit := MAX_PRIORITY_FLOAT_TEXTS if priority else MAX_FLOAT_TEXTS
	return _transient_fx_count($Hud, "float_text") < _scaled_vfx_budget(base_limit, priority)

func _transient_fx_count(parent: Node, bucket: String) -> int:
	var count := 0
	for child in parent.get_children():
		if child.is_queued_for_deletion():
			continue
		if bucket == "projectile" and child.has_meta("transient_vfx"):
			count += 1
		elif str(child.get_meta("battle_transient_fx", "")) == bucket:
			count += 1
	return count

func _spawn_muzzle_flash(origin: Vector2, direction: Vector2, element := "physical", visual_profile := "") -> void:
	if not _can_spawn_projectile_fx():
		return
	var dir := _safe_vfx_direction(direction)
	var muzzle_profile := _muzzle_weapon_profile(visual_profile)
	var spec := _muzzle_element_spec(element, muzzle_profile)
	var hot_color: Color = spec.get("hot", _element_color(element))
	hot_color.a = 0.94
	var cone_color: Color = spec.get("cone", hot_color)
	cone_color.a = minf(cone_color.a, 0.72)
	var glow := VfxLib.spawn_glow(
		$ProjectileLayer,
		origin + dir * 10.0 * CHARACTER_VFX_PRESENTATION_SCALE,
		hot_color,
		float(spec.get("glow_size", 104.0)) * CHARACTER_VFX_PRESENTATION_SCALE,
		float(spec.get("glow_life", 0.13))
	)
	if glow != null:
		_track_transient_fx(glow, "projectile")
	_spawn_muzzle_light_cone(origin, dir, cone_color, float(spec.get("cone_length", 104.0)), float(spec.get("cone_width", 34.0)), float(spec.get("cone_life", 0.11)), float(spec.get("intensity", 3.2)))
	_spawn_muzzle_element_particles(origin, dir, element, muzzle_profile)
	_spawn_muzzle_smoke(origin, dir, element, muzzle_profile)
	_spawn_weapon_muzzle_profile_vfx(origin, dir, element, muzzle_profile)

func _spawn_weapon_muzzle_profile_vfx(origin: Vector2, direction: Vector2, element: String, visual_profile: String) -> void:
	var profile := _muzzle_weapon_profile(visual_profile)
	if profile == "":
		return
	var dir := _safe_vfx_direction(direction)
	var spec := _muzzle_element_spec(element, profile)
	var hot_color: Color = spec.get("hot", _element_color(element))
	match profile:
		"autocannon":
			_spawn_weapon_trace(origin + dir * 20.0, origin + dir * 96.0, Color(1.0, 0.86, 0.34, 0.5), 5.0, 0.07)
		"rail":
			_spawn_muzzle_light_cone(origin, dir, Color(0.66, 0.98, 1.0, 0.72), 168.0, 18.0, 0.1, 4.4)
			_spawn_weapon_trace(origin - dir * 18.0, origin + dir * 142.0, Color(0.66, 0.98, 1.0, 0.76), 14.0, 0.1)
			_spawn_muzzle_fork_lines(origin + dir * 18.0, dir, Color(0.78, 1.0, 1.0, 0.58), 3, 116.0, 12.0, 0.11, 2.8)
		"scatter":
			var color := Color(1.0, 0.78, 0.36, 0.52)
			for i in range(5):
				var offset := lerpf(-0.24, 0.24, float(i) / 4.0)
				var shot_dir := dir.rotated(offset)
				_spawn_muzzle_light_cone(origin, shot_dir, color, 76.0, 16.0, 0.08, 2.7)
				_spawn_short_muzzle_spark(origin, shot_dir, element, color, 0.15, "res://assets/production/sprites/projectiles/proj_scatter_pellet.png")
		"plasma":
			var plasma_color := Color(0.98, 0.46, 1.0, 0.82)
			_spawn_muzzle_light_cone(origin, dir, plasma_color, 126.0, 48.0, 0.14, 4.0)
			_spawn_muzzle_heat_haze(origin + dir * 22.0, dir, plasma_color, 0.18, 1.18)
			var plasma_glow := VfxLib.spawn_glow($ProjectileLayer, origin + dir * 34.0, Color(1.0, 0.68, 1.0, 0.86), 118.0, 0.16)
			if plasma_glow != null:
				_track_transient_fx(plasma_glow, "projectile")
		"flame":
			_spawn_muzzle_light_cone(origin, dir, Color(1.0, 0.22, 0.08, 0.62), 132.0, 58.0, 0.13, 3.8)
			_spawn_muzzle_heat_haze(origin + dir * 18.0, dir, Color(1.0, 0.34, 0.08, 0.48), 0.2, 1.05)
		"cryo":
			_spawn_muzzle_fork_lines(origin + dir * 16.0, dir, Color(0.74, 1.0, 1.0, 0.68), 5, 72.0, 28.0, 0.14, 3.2)
		"tesla":
			_spawn_muzzle_fork_lines(origin + dir * 16.0, dir, Color(0.74, 0.96, 1.0, 0.78), 6, 106.0, 36.0, 0.12, 3.0)
		"venom":
			_spawn_muzzle_bubbles(origin + dir * 12.0, dir, hot_color, 5, 0.28)

func _projectile_visual_scale(shots: int, pierce: int, split: int, homing: float, splash: float, cloud: float) -> float:
	var scale := 1.0
	scale += 0.08 * float(skills.level("skill_charge_shot"))
	scale += 0.035 * float(pierce)
	if split > 0:
		scale += 0.05
	if homing > 0.0:
		scale += 0.04
	if splash > 0.0 or cloud > 0.0:
		scale += 0.12
	if shots >= 4:
		scale *= 0.88
	return clampf(scale, 0.78, 1.55)

func _spawn_salvo_fan_vfx(origin: Vector2, direction: Vector2, spread: float, shots: int, element: String, visual_profile := "") -> void:
	var dir := _safe_vfx_direction(direction)
	var spec := _muzzle_element_spec(element, _muzzle_weapon_profile(visual_profile))
	var color: Color = spec.get("cone", _element_color(element))
	color.a = 0.42
	var fan_glow := VfxLib.spawn_glow($ProjectileLayer, origin + dir * 18.0, color, 78.0 + float(mini(shots, 6)) * 6.0, 0.1)
	if fan_glow != null:
		_track_transient_fx(fan_glow, "projectile")
	for i in range(mini(shots, 6)):
		var offset: float = 0.0 if shots == 1 else lerpf(-spread, spread, float(i) / float(shots - 1))
		var shot_dir := dir.rotated(offset)
		_spawn_muzzle_light_cone(origin, shot_dir, color, 66.0, 14.0, 0.075, 2.2)
		if i % 2 == 0 and _can_spawn_projectile_fx():
			var fan_particles := VfxLib.spawn_particles($ProjectileLayer, origin + shot_dir * 22.0, color, 4, 260.0, 18.0, 0.1)
			if fan_particles != null:
				_track_transient_fx(fan_particles, "projectile")
				if fan_particles is Node2D:
					(fan_particles as Node2D).rotation = shot_dir.angle()

func _spawn_homing_line_vfx(origin: Vector2, direction: Vector2, element: String) -> void:
	var color := _element_color(element)
	color.a = 0.36
	_spawn_short_muzzle_spark(origin, direction, element, color, 0.2)

func _spawn_weapon_power_ring(origin: Vector2, element: String) -> void:
	if not _can_spawn_projectile_fx():
		return
	var color := _element_color(element)
	color.a = 0.64
	var rank_radius := 78.0 + float(_growth_rank(weapon_level)) * 22.0
	var glow := VfxLib.spawn_glow($ProjectileLayer, origin, color.lightened(0.18), rank_radius * 1.12, 0.2)
	if glow != null:
		_track_transient_fx(glow, "projectile")
	for i in range(2):
		if not _can_spawn_projectile_fx():
			break
		var ring := Node2D.new()
		_track_transient_fx(ring, "projectile")
		ring.name = "WeaponPowerConvergeRing"
		ring.process_mode = Node.PROCESS_MODE_PAUSABLE
		ring.global_position = origin
		ring.rotation = randf_range(-0.22, 0.22)
		ring.scale = Vector2.ONE * (1.24 + float(i) * 0.28)
		ring.z_index = 76
		$ProjectileLayer.add_child(ring)
		var ring_color := Color(color.r, color.g, color.b, color.a * (0.9 - float(i) * 0.22))
		var line := _make_ring_line(rank_radius * (0.72 + float(i) * 0.18), ring_color, 4.0 - float(i) * 0.8, 80)
		line.texture = VfxLib.STREAK_TEXTURE
		line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		line.material = _new_muzzle_additive_material()
		ring.add_child(line)
		var tween := ring.create_tween()
		tween.set_trans(Tween.TRANS_QUINT)
		tween.set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(ring, "scale", Vector2.ONE * (0.58 + float(i) * 0.08), 0.22)
		tween.parallel().tween_property(ring, "rotation", ring.rotation + (0.52 if i == 0 else -0.44), 0.22)
		tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.22)
		tween.tween_callback(ring.queue_free)
	var motes := VfxLib.spawn_particles($ProjectileLayer, origin, color, 12, 210.0, 160.0, 0.24)
	if motes != null:
		_track_transient_fx(motes, "projectile")

func _spawn_crit_shot_vfx(origin: Vector2, direction: Vector2, element: String) -> void:
	if not _can_spawn_projectile_fx(true):
		return
	var dir := _safe_vfx_direction(direction)
	var color := Color(1.0, 0.84, 0.24, 0.86)
	var elem_color := _element_color(element)
	elem_color.a = 0.46
	var hot := Color(1.0, 0.96, 0.58, 0.96)
	var burst_origin := origin + dir * 34.0
	var glow := VfxLib.spawn_glow($ProjectileLayer, burst_origin, hot, 138.0, 0.18)
	if glow != null:
		_track_transient_fx(glow, "projectile")
	_spawn_muzzle_light_cone(origin, dir, Color(1.0, 0.74, 0.22, 0.72), 122.0, 36.0, 0.12, 4.5)
	_spawn_impact_shock_ring(burst_origin, Color(1.0, 0.82, 0.28, 0.68), 92.0, 8.0, 0.18, true)
	_spawn_impact_streaks(burst_origin, Color(1.0, 0.9, 0.42, 0.82), 7, 96.0, 0.16, 4.2, true)
	var sparks := VfxLib.spawn_burst($ProjectileLayer, burst_origin, color, 24, 620.0, 50.0, 0.2)
	if sparks != null:
		_track_transient_fx(sparks, "projectile")
		if sparks is Node2D:
			(sparks as Node2D).rotation = dir.angle()
	var element_glow := VfxLib.spawn_particles($ProjectileLayer, origin + dir * 22.0, elem_color, 7, 260.0, 42.0, 0.14)
	if element_glow != null:
		_track_transient_fx(element_glow, "projectile")
		if element_glow is Node2D:
			(element_glow as Node2D).rotation = dir.angle()
	VfxLib.screen_shake(2.8, 0.045)

func _spawn_short_muzzle_spark(origin: Vector2, direction: Vector2, element: String, color: Color, scale_mult := 0.18, texture_path := "") -> void:
	if not _can_spawn_projectile_fx():
		return
	var dir := _safe_vfx_direction(direction)
	var spark_color := color
	spark_color.a = minf(color.a, 0.58)
	_spawn_muzzle_light_cone(origin, dir, spark_color, 54.0, 12.0, 0.07, 2.35)
	var particles := VfxLib.spawn_particles($ProjectileLayer, origin + dir * 22.0, spark_color, 5, 285.0, 22.0, 0.1)
	if particles != null:
		_track_transient_fx(particles, "projectile")
		if particles is Node2D:
			(particles as Node2D).rotation = dir.angle()
	if texture_path == "":
		return
	var tex := load(texture_path) as Texture2D
	if tex == null or not _can_spawn_projectile_fx():
		return
	var spark := Sprite2D.new()
	_track_transient_fx(spark, "projectile")
	spark.name = "MuzzleAccent"
	spark.texture = tex
	spark.global_position = origin + dir * 30.0
	spark.rotation = dir.angle()
	spark.scale = Vector2(scale_mult, scale_mult) * CHARACTER_VFX_PRESENTATION_SCALE
	spark.modulate = color
	spark.material = _new_muzzle_additive_material()
	spark.z_index = 75
	$ProjectileLayer.add_child(spark)
	var tween := spark.create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(spark, "global_position", spark.global_position + dir * 20.0, 0.08)
	tween.parallel().tween_property(spark, "scale", spark.scale * 0.54, 0.08)
	tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.08)
	tween.tween_callback(spark.queue_free)

func _safe_vfx_direction(direction: Vector2) -> Vector2:
	var dir := direction.normalized()
	if dir.length_squared() <= 0.01:
		return Vector2.UP
	return dir

func _muzzle_weapon_profile(visual_profile: String) -> String:
	if visual_profile != "":
		return visual_profile
	match weapon_id:
		"weapon_autocannon":
			return "autocannon"
		"weapon_flamethrower":
			return "flame"
		"weapon_cryocannon":
			return "cryo"
		"weapon_teslacoil":
			return "tesla"
		"weapon_venomlauncher":
			return "venom"
		_:
			return ""

func _muzzle_element_spec(element: String, profile := "") -> Dictionary:
	var spec := {}
	match element:
		"fire":
			spec = {
				"hot": Color(1.0, 0.36, 0.08, 1.0),
				"cone": Color(1.0, 0.18, 0.04, 0.68),
				"smoke": Color(1.0, 0.36, 0.12, 0.2),
				"glow_size": 124.0,
				"glow_life": 0.15,
				"cone_length": 116.0,
				"cone_width": 48.0,
				"cone_life": 0.13,
				"intensity": 3.6,
				"burst_amount": 20,
				"burst_speed": 430.0,
				"burst_spread": 46.0,
				"burst_life": 0.22,
				"smoke_amount": 8,
			}
		"ice":
			spec = {
				"hot": Color(0.72, 1.0, 1.0, 1.0),
				"cone": Color(0.34, 0.9, 1.0, 0.58),
				"smoke": Color(0.58, 0.96, 1.0, 0.22),
				"glow_size": 114.0,
				"glow_life": 0.14,
				"cone_length": 96.0,
				"cone_width": 52.0,
				"cone_life": 0.13,
				"intensity": 3.2,
				"burst_amount": 18,
				"burst_speed": 360.0,
				"burst_spread": 58.0,
				"burst_life": 0.24,
				"smoke_amount": 10,
			}
		"lightning":
			spec = {
				"hot": Color(0.78, 0.96, 1.0, 1.0),
				"cone": Color(0.58, 0.9, 1.0, 0.7),
				"smoke": Color(0.44, 0.76, 1.0, 0.12),
				"glow_size": 118.0,
				"glow_life": 0.11,
				"cone_length": 112.0,
				"cone_width": 30.0,
				"cone_life": 0.09,
				"intensity": 4.4,
				"burst_amount": 22,
				"burst_speed": 610.0,
				"burst_spread": 38.0,
				"burst_life": 0.14,
				"smoke_amount": 4,
			}
		"poison":
			spec = {
				"hot": Color(0.46, 1.0, 0.18, 1.0),
				"cone": Color(0.32, 1.0, 0.2, 0.58),
				"smoke": Color(0.34, 1.0, 0.16, 0.25),
				"glow_size": 112.0,
				"glow_life": 0.16,
				"cone_length": 92.0,
				"cone_width": 56.0,
				"cone_life": 0.16,
				"intensity": 3.0,
				"burst_amount": 15,
				"burst_speed": 285.0,
				"burst_spread": 68.0,
				"burst_life": 0.28,
				"smoke_amount": 12,
			}
		_:
			spec = {
				"hot": Color(1.0, 0.9, 0.34, 1.0),
				"cone": Color(1.0, 0.78, 0.24, 0.62),
				"smoke": Color(0.72, 0.68, 0.58, 0.16),
				"glow_size": 104.0,
				"glow_life": 0.13,
				"cone_length": 108.0,
				"cone_width": 30.0,
				"cone_life": 0.1,
				"intensity": 3.1,
				"burst_amount": 18,
				"burst_speed": 520.0,
				"burst_spread": 30.0,
				"burst_life": 0.18,
				"smoke_amount": 5,
			}
	match profile:
		"rail":
			spec["hot"] = Color(0.72, 1.0, 1.0, 1.0)
			spec["cone"] = Color(0.58, 0.96, 1.0, 0.72)
			spec["glow_size"] = 132.0
			spec["cone_length"] = 148.0
			spec["cone_width"] = 20.0
			spec["intensity"] = 4.6
			spec["burst_speed"] = 690.0
			spec["burst_spread"] = 18.0
			spec["burst_life"] = 0.12
		"scatter":
			spec["cone_width"] = maxf(float(spec.get("cone_width", 30.0)), 44.0)
			spec["burst_amount"] = mini(int(spec.get("burst_amount", 18)) + 6, 30)
			spec["burst_spread"] = maxf(float(spec.get("burst_spread", 34.0)), 64.0)
		"plasma":
			spec["hot"] = Color(1.0, 0.58, 1.0, 1.0)
			spec["cone"] = Color(0.95, 0.36, 1.0, 0.68)
			spec["smoke"] = Color(1.0, 0.42, 0.72, 0.16)
			spec["glow_size"] = 138.0
			spec["cone_length"] = 120.0
			spec["cone_width"] = 54.0
			spec["intensity"] = 4.1
			spec["burst_life"] = 0.2
		"flame":
			spec["cone_length"] = maxf(float(spec.get("cone_length", 112.0)), 130.0)
			spec["cone_width"] = maxf(float(spec.get("cone_width", 46.0)), 62.0)
			spec["smoke_amount"] = maxi(int(spec.get("smoke_amount", 8)), 10)
		"cryo":
			spec["cone_width"] = maxf(float(spec.get("cone_width", 48.0)), 58.0)
			spec["smoke_amount"] = maxi(int(spec.get("smoke_amount", 8)), 12)
		"tesla":
			spec["hot"] = Color(0.82, 0.98, 1.0, 1.0)
			spec["cone"] = Color(0.56, 0.9, 1.0, 0.72)
			spec["intensity"] = 4.6
			spec["burst_speed"] = 640.0
		"venom":
			spec["cone_width"] = maxf(float(spec.get("cone_width", 52.0)), 66.0)
			spec["smoke_amount"] = maxi(int(spec.get("smoke_amount", 10)), 14)
	return spec

func _spawn_muzzle_light_cone(origin: Vector2, direction: Vector2, color: Color, length: float, width: float, duration: float, intensity := 3.0) -> void:
	if not _can_spawn_projectile_fx():
		return
	var dir := _safe_vfx_direction(direction)
	var safe_length := clampf(length * CHARACTER_VFX_PRESENTATION_SCALE, 24.0, 238.0)
	var safe_width := clampf(width * CHARACTER_VFX_PRESENTATION_SCALE, 8.0, 95.0)
	var life := clampf(duration, 0.04, 0.24)
	var root := Node2D.new()
	root.name = "MuzzleLightCone"
	root.process_mode = Node.PROCESS_MODE_PAUSABLE
	root.z_index = 73
	root.rotation = dir.angle()
	root.scale = Vector2(0.72, 1.12)
	_track_transient_fx(root, "projectile")
	$ProjectileLayer.add_child(root)
	root.global_position = origin

	var cone := Sprite2D.new()
	cone.name = "AdditiveCone"
	cone.texture = VfxLib.STREAK_TEXTURE
	cone.centered = true
	cone.position = Vector2(safe_length * 0.46, 0.0)
	cone.scale = Vector2(safe_length / float(VfxLib.STREAK_TEXTURE.get_width()), safe_width / float(VfxLib.STREAK_TEXTURE.get_height()))
	cone.modulate = color
	cone.material = _new_muzzle_core_material(color, intensity, 0.74)
	root.add_child(cone)

	var core_color := color.lightened(0.28)
	core_color.a = minf(color.a + 0.16, 0.96)
	var core := Sprite2D.new()
	core.name = "ShaderCore"
	core.texture = VfxLib.RADIAL_GLOW_TEXTURE
	core.centered = true
	core.position = Vector2(16.0, 0.0)
	core.scale = Vector2.ONE * (safe_width * 0.74 / float(VfxLib.RADIAL_GLOW_TEXTURE.get_width()))
	core.material = _new_muzzle_core_material(core_color, intensity + 0.65, 0.82)
	root.add_child(core)

	var tween := root.create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(root, "scale", Vector2(1.08, 0.76), life)
	tween.parallel().tween_property(root, "modulate:a", 0.0, life)
	tween.tween_callback(root.queue_free)

func _spawn_muzzle_element_particles(origin: Vector2, direction: Vector2, element: String, profile: String) -> void:
	var spec := _muzzle_element_spec(element, profile)
	var dir := _safe_vfx_direction(direction)
	var hot_color: Color = spec.get("hot", _element_color(element))
	hot_color.a = 0.84
	if _can_spawn_projectile_fx():
		var burst := VfxLib.spawn_burst(
			$ProjectileLayer,
			origin + dir * 20.0,
			hot_color,
			int(spec.get("burst_amount", 16)),
			float(spec.get("burst_speed", 420.0)),
			float(spec.get("burst_spread", 38.0)),
			float(spec.get("burst_life", 0.18))
		)
		if burst != null:
			_track_transient_fx(burst, "projectile")
			if burst is Node2D:
				(burst as Node2D).rotation = dir.angle()
	if _can_spawn_projectile_fx():
		var mote_color := hot_color.lightened(0.18)
		mote_color.a = 0.46
		var motes := VfxLib.spawn_particles($ProjectileLayer, origin + dir * 10.0, mote_color, 7, float(spec.get("burst_speed", 420.0)) * 0.46, float(spec.get("burst_spread", 38.0)) + 24.0, 0.18)
		if motes != null:
			_track_transient_fx(motes, "projectile")
			if motes is Node2D:
				(motes as Node2D).rotation = dir.angle()
	match element:
		"fire":
			_spawn_muzzle_heat_haze(origin + dir * 18.0, dir, Color(1.0, 0.24, 0.06, 0.44), 0.18, 0.95)
		"ice":
			_spawn_muzzle_fork_lines(origin + dir * 14.0, dir, Color(0.82, 1.0, 1.0, 0.62), 4, 62.0, 28.0, 0.13, 2.5)
		"lightning":
			_spawn_muzzle_fork_lines(origin + dir * 12.0, dir, Color(0.82, 0.98, 1.0, 0.82), 5, 96.0, 34.0, 0.11, 2.8)
		"poison":
			_spawn_muzzle_bubbles(origin + dir * 10.0, dir, Color(0.46, 1.0, 0.16, 0.46), 4, 0.26)

func _spawn_muzzle_smoke(origin: Vector2, direction: Vector2, element: String, profile: String) -> void:
	if not _can_spawn_projectile_fx():
		return
	var spec := _muzzle_element_spec(element, profile)
	var smoke_color: Color = spec.get("smoke", Color(0.7, 0.68, 0.6, 0.14))
	var amount := clampi(int(spec.get("smoke_amount", 6)), 3, 14)
	var dir := _safe_vfx_direction(direction)
	var particles := GPUParticles2D.new()
	particles.name = "MuzzleSmokeParticles"
	particles.process_mode = Node.PROCESS_MODE_PAUSABLE
	particles.one_shot = true
	particles.amount = amount
	particles.lifetime = 0.28 if element != "poison" else 0.38
	particles.explosiveness = 1.0
	particles.randomness = 0.7
	particles.local_coords = false
	particles.texture = VfxLib.RADIAL_GLOW_TEXTURE
	particles.material = _new_muzzle_additive_material()
	particles.z_index = 71
	particles.visibility_rect = Rect2(-420.0, -420.0, 840.0, 840.0)

	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	process_material.direction = Vector3(1.0, 0.0, 0.0)
	process_material.spread = 58.0 if element != "poison" else 84.0
	process_material.initial_velocity_min = 28.0 if element == "poison" else 46.0
	process_material.initial_velocity_max = 116.0 if element == "poison" else 190.0
	process_material.gravity = Vector3(0.0, -18.0 if element == "ice" else -6.0, 0.0)
	process_material.damping_min = 28.0
	process_material.damping_max = 58.0
	process_material.angle_min = -35.0
	process_material.angle_max = 35.0
	process_material.angular_velocity_min = -80.0
	process_material.angular_velocity_max = 80.0
	process_material.scale_min = 0.16 if element != "poison" else 0.2
	process_material.scale_max = 0.42 if element != "poison" else 0.58
	process_material.scale_curve = _muzzle_smoke_scale_curve()
	process_material.color_ramp = _muzzle_color_ramp(smoke_color.lightened(0.14), smoke_color, Color(smoke_color.r, smoke_color.g, smoke_color.b, 0.0))
	particles.process_material = process_material

	particles.finished.connect(particles.queue_free)
	_track_transient_fx(particles, "projectile")
	$ProjectileLayer.add_child(particles)
	particles.global_position = origin + dir * 14.0
	particles.rotation = dir.angle()
	particles.emitting = true

func _spawn_muzzle_heat_haze(origin: Vector2, direction: Vector2, color: Color, duration: float, scale_mult := 1.0) -> void:
	if not _can_spawn_projectile_fx():
		return
	var dir := _safe_vfx_direction(direction)
	var haze := Sprite2D.new()
	haze.name = "MuzzleShaderHeatHaze"
	haze.process_mode = Node.PROCESS_MODE_PAUSABLE
	haze.texture = VfxLib.RADIAL_GLOW_TEXTURE
	haze.centered = true
	scale_mult *= CHARACTER_VFX_PRESENTATION_SCALE
	haze.global_position = origin + dir * 18.0 * CHARACTER_VFX_PRESENTATION_SCALE
	haze.rotation = dir.angle()
	haze.scale = Vector2(0.7, 0.34) * scale_mult
	haze.modulate = color
	haze.material = _new_muzzle_core_material(color, 2.45, 1.8)
	haze.z_index = 72
	_track_transient_fx(haze, "projectile")
	$ProjectileLayer.add_child(haze)
	var tween := haze.create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(haze, "scale", Vector2(1.22, 0.58) * scale_mult, duration)
	tween.parallel().tween_property(haze, "rotation", haze.rotation + 0.1, duration)
	tween.parallel().tween_property(haze, "modulate:a", 0.0, duration)
	tween.tween_callback(haze.queue_free)

func _spawn_muzzle_fork_lines(origin: Vector2, direction: Vector2, color: Color, count: int, length: float, spread_deg: float, duration: float, width: float) -> void:
	if not _can_spawn_projectile_fx():
		return
	var dir := _safe_vfx_direction(direction)
	var root := Node2D.new()
	root.name = "MuzzleForkLines"
	root.process_mode = Node.PROCESS_MODE_PAUSABLE
	root.global_position = origin
	root.rotation = dir.angle()
	root.z_index = 76
	_track_transient_fx(root, "projectile")
	$ProjectileLayer.add_child(root)
	var safe_count := clampi(count, 1, 7)
	var presentation_length := length * CHARACTER_VFX_PRESENTATION_SCALE
	var presentation_width := width * CHARACTER_VFX_PRESENTATION_SCALE
	for i in range(safe_count):
		var t := 0.5 if safe_count == 1 else float(i) / float(safe_count - 1)
		var lateral := tan(deg_to_rad(lerpf(-spread_deg, spread_deg, t))) * presentation_length * 0.26
		var jitter := randf_range(-8.0, 8.0) * CHARACTER_VFX_PRESENTATION_SCALE
		var line := Line2D.new()
		line.width = presentation_width * randf_range(0.72, 1.18)
		line.default_color = color.lightened(randf_range(0.0, 0.25))
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.texture = VfxLib.STREAK_TEXTURE
		line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		line.material = _new_muzzle_additive_material()
		line.points = PackedVector2Array([
			Vector2(8.0, 0.0),
			Vector2(presentation_length * randf_range(0.38, 0.58), lateral * 0.45 + jitter),
			Vector2(presentation_length * randf_range(0.74, 1.05), lateral + randf_range(-10.0, 10.0) * CHARACTER_VFX_PRESENTATION_SCALE),
		])
		root.add_child(line)
		if i % 2 == 0:
			var branch := Line2D.new()
			branch.width = maxf(presentation_width * 0.55, 1.2)
			branch.default_color = Color(color.r, color.g, color.b, color.a * 0.72)
			branch.joint_mode = Line2D.LINE_JOINT_ROUND
			branch.begin_cap_mode = Line2D.LINE_CAP_ROUND
			branch.end_cap_mode = Line2D.LINE_CAP_ROUND
			branch.texture = VfxLib.STREAK_TEXTURE
			branch.texture_mode = Line2D.LINE_TEXTURE_STRETCH
			branch.material = _new_muzzle_additive_material()
			var branch_start := Vector2(presentation_length * 0.48, lateral * 0.42)
			branch.points = PackedVector2Array([
				branch_start,
				branch_start + Vector2(presentation_length * 0.22, randf_range(-22.0, 22.0) * CHARACTER_VFX_PRESENTATION_SCALE),
			])
			root.add_child(branch)
	var tween := root.create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(root, "scale", Vector2(1.08, 0.82), duration)
	tween.parallel().tween_property(root, "modulate:a", 0.0, duration)
	tween.tween_callback(root.queue_free)

func _spawn_muzzle_bubbles(origin: Vector2, direction: Vector2, color: Color, count: int, duration: float) -> void:
	if not _can_spawn_projectile_fx():
		return
	var dir := _safe_vfx_direction(direction)
	var root := Node2D.new()
	root.name = "MuzzlePoisonBubbles"
	root.process_mode = Node.PROCESS_MODE_PAUSABLE
	root.global_position = origin
	root.rotation = dir.angle()
	root.scale = Vector2.ONE * CHARACTER_VFX_PRESENTATION_SCALE
	root.z_index = 74
	_track_transient_fx(root, "projectile")
	$ProjectileLayer.add_child(root)
	var safe_count := clampi(count, 2, 6)
	for i in range(safe_count):
		var bubble := Sprite2D.new()
		bubble.name = "Bubble"
		bubble.texture = VfxLib.RADIAL_GLOW_TEXTURE
		bubble.centered = true
		bubble.position = Vector2(randf_range(10.0, 34.0), randf_range(-18.0, 18.0))
		bubble.scale = Vector2.ONE * randf_range(0.07, 0.14)
		bubble.modulate = Color(color.r, color.g, color.b, randf_range(0.28, 0.5))
		bubble.material = _new_muzzle_core_material(bubble.modulate, 2.2, 1.2)
		root.add_child(bubble)
		var travel := Vector2(randf_range(32.0, 76.0), randf_range(-36.0, 36.0))
		var tween := bubble.create_tween()
		tween.set_trans(Tween.TRANS_QUINT)
		tween.set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(bubble, "position", bubble.position + travel, duration)
		tween.parallel().tween_property(bubble, "scale", bubble.scale * randf_range(1.5, 2.2), duration)
		tween.parallel().tween_property(bubble, "modulate:a", 0.0, duration)
	var root_tween := root.create_tween()
	root_tween.tween_interval(duration + 0.02)
	root_tween.tween_callback(root.queue_free)

func _muzzle_color_ramp(start: Color, mid: Color, finish: Color) -> GradientTexture1D:
	var gradient_resource := Gradient.new()
	gradient_resource.set_offset(0, 0.0)
	gradient_resource.set_color(0, start)
	gradient_resource.set_offset(1, 1.0)
	gradient_resource.set_color(1, finish)
	gradient_resource.add_point(0.36, mid)
	var texture := GradientTexture1D.new()
	texture.gradient = gradient_resource
	return texture

func _muzzle_smoke_scale_curve() -> CurveTexture:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.16))
	curve.add_point(Vector2(0.35, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	var texture := CurveTexture.new()
	texture.curve = curve
	return texture

func _new_muzzle_core_material(color: Color, intensity: float, core_power: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = VfxLib.GLOW_CORE_SHADER
	material.set_shader_parameter("tint", color)
	material.set_shader_parameter("intensity", intensity)
	material.set_shader_parameter("core_power", core_power)
	return material

func _new_muzzle_additive_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return material

func _spawn_weapon_trace(start: Vector2, finish: Vector2, color: Color, width := 10.0, duration := 0.12) -> void:
	if not _can_spawn_projectile_fx():
		return
	var trace := Line2D.new()
	_track_transient_fx(trace, "projectile")
	trace.width = width
	trace.default_color = color
	trace.joint_mode = Line2D.LINE_JOINT_ROUND
	trace.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trace.end_cap_mode = Line2D.LINE_CAP_ROUND
	trace.texture = VfxLib.STREAK_TEXTURE
	trace.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	trace.material = _new_muzzle_additive_material()
	trace.points = PackedVector2Array([$ProjectileLayer.to_local(start), $ProjectileLayer.to_local(finish)])
	$ProjectileLayer.add_child(trace)
	var tween := trace.create_tween()
	tween.parallel().tween_property(trace, "width", maxf(width * 0.18, 2.0), duration)
	tween.parallel().tween_property(trace, "modulate:a", 0.0, duration)
	tween.tween_callback(trace.queue_free)

func _spawn_levelup_vfx(origin: Vector2, color: Color, duration := 0.75) -> void:
	if not _can_spawn_projectile_fx(true):
		return
	var safe_duration := clampf(duration, 0.28, 0.95)
	var hot := color.lightened(0.26)
	hot.a = 0.92
	var glow := VfxLib.spawn_glow($ProjectileLayer, origin + Vector2(0, -40), hot, 260.0, minf(safe_duration, 0.78))
	if glow != null:
		_track_transient_fx(glow, "projectile")
	var beam := Sprite2D.new()
	_track_transient_fx(beam, "projectile")
	beam.name = "LevelUpLightColumn"
	beam.texture = VfxLib.RADIAL_GLOW_TEXTURE
	beam.centered = true
	beam.global_position = origin + Vector2(0, -175)
	beam.scale = Vector2(0.7, 3.25)
	beam.modulate = Color(color.r, color.g, color.b, minf(color.a, 0.54))
	beam.material = _new_muzzle_core_material(Color(hot.r, hot.g, hot.b, 0.72), 2.8, 1.45)
	beam.z_index = 15
	$ProjectileLayer.add_child(beam)
	var beam_tween := beam.create_tween()
	beam_tween.set_trans(Tween.TRANS_QUINT)
	beam_tween.set_ease(Tween.EASE_OUT)
	beam_tween.parallel().tween_property(beam, "scale", Vector2(0.98, 3.9), safe_duration)
	beam_tween.parallel().tween_property(beam, "global_position:y", beam.global_position.y - 42.0, safe_duration)
	beam_tween.parallel().tween_property(beam, "modulate:a", 0.0, safe_duration)
	beam_tween.tween_callback(beam.queue_free)

	var particles := GPUParticles2D.new()
	_track_transient_fx(particles, "projectile")
	particles.name = "LevelUpRisingParticles"
	particles.process_mode = Node.PROCESS_MODE_PAUSABLE
	particles.one_shot = true
	particles.amount = 40
	particles.lifetime = minf(safe_duration + 0.12, 0.95)
	particles.explosiveness = 0.82
	particles.randomness = 0.72
	particles.local_coords = false
	particles.texture = VfxLib.SPARK_TEXTURE
	particles.material = _new_muzzle_additive_material()
	particles.z_index = 17
	particles.visibility_rect = Rect2(-360.0, -620.0, 720.0, 760.0)
	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(110.0, 16.0, 0.0)
	process_material.direction = Vector3(0.0, -1.0, 0.0)
	process_material.spread = 24.0
	process_material.initial_velocity_min = 170.0
	process_material.initial_velocity_max = 430.0
	process_material.gravity = Vector3(0.0, -48.0, 0.0)
	process_material.damping_min = 18.0
	process_material.damping_max = 46.0
	process_material.angle_min = -60.0
	process_material.angle_max = 60.0
	process_material.angular_velocity_min = -180.0
	process_material.angular_velocity_max = 180.0
	process_material.scale_min = 0.08
	process_material.scale_max = 0.24
	process_material.scale_curve = _impact_cloud_scale_curve()
	process_material.color_ramp = _impact_color_ramp(hot, Color(color.r, color.g, color.b, 0.54), Color(color.r, color.g, color.b, 0.0))
	particles.process_material = process_material
	particles.finished.connect(particles.queue_free)
	$ProjectileLayer.add_child(particles)
	particles.global_position = origin + Vector2(0, 20)
	particles.emitting = true

	var ring := Node2D.new()
	_track_transient_fx(ring, "projectile")
	ring.global_position = origin
	ring.z_index = 16
	$ProjectileLayer.add_child(ring)
	var outer := _make_ring_line(92.0, color, 3.0, 72)
	outer.texture = VfxLib.STREAK_TEXTURE
	outer.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	outer.material = _new_muzzle_additive_material()
	var inner_color := color
	inner_color.a = minf(color.a, 0.42)
	var inner := _make_ring_line(54.0, inner_color, 2.0, 72)
	inner.texture = VfxLib.STREAK_TEXTURE
	inner.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	inner.material = _new_muzzle_additive_material()
	ring.add_child(outer)
	ring.add_child(inner)
	ring.scale = Vector2(0.3, 0.3)
	var tween := ring.create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ring, "scale", Vector2(0.92, 0.92), safe_duration)
	tween.parallel().tween_property(ring, "rotation", 0.45, safe_duration)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, safe_duration)
	tween.tween_callback(ring.queue_free)

func _make_ring_line(radius: float, color: Color, width: float, segments := 72) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.closed = true
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		line.add_point(Vector2(cos(angle), sin(angle)) * radius)
	return line

func _spawn_character_aura() -> void:
	if character_sprite == null:
		return
	character_aura = Node2D.new()
	character_aura.name = "CharacterAura"
	character_aura.position = Vector2(0, -28)
	character_aura.scale = Vector2(0.42, 0.42) * (1.0 + 0.08 * float(_growth_rank(character_level)))
	character_aura.z_index = -1
	var color := _element_color(str(character_data.get("element_focus", "physical")))
	color.a = 0.28 + 0.05 * float(_growth_rank(character_level))
	character_aura.add_child(_make_ring_line(118.0, color, 3.0, 80))
	var inner_color := color
	inner_color.a *= 0.58
	character_aura.add_child(_make_ring_line(78.0, inner_color, 2.0, 80))
	character_sprite.add_child(character_aura)

func _update_character_aura(delta: float) -> void:
	if character_aura == null:
		return
	character_aura.rotation += delta * 0.65
	var pulse := 0.92 + absf(sin(Time.get_ticks_msec() / 420.0)) * 0.14
	character_aura.scale = Vector2(0.42, 0.42) * (1.0 + 0.08 * float(_growth_rank(character_level))) * pulse

func _spawn_pet_aura() -> void:
	if pet_sprite == null:
		return
	pet_aura = Node2D.new()
	pet_aura.name = "PetAura"
	pet_aura.position = Vector2(0, -20)
	pet_aura.scale = Vector2(0.28, 0.28) * (1.0 + 0.06 * float(_growth_rank(pet_level)))
	pet_aura.z_index = -1
	var color := _element_color(str(pet_data.get("element", "physical")))
	color.a = 0.24 + 0.04 * float(_growth_rank(pet_level))
	pet_aura.add_child(_make_ring_line(92.0, color, 2.5, 72))
	var inner_color := color
	inner_color.a *= 0.5
	pet_aura.add_child(_make_ring_line(58.0, inner_color, 1.8, 72))
	pet_sprite.add_child(pet_aura)

func _update_pet_aura(delta: float) -> void:
	if pet_aura == null:
		return
	pet_aura.rotation -= delta * 0.9
	var pulse := 0.9 + absf(sin(Time.get_ticks_msec() / 330.0)) * 0.18
	pet_aura.scale = Vector2(0.28, 0.28) * (1.0 + 0.06 * float(_growth_rank(pet_level))) * pulse

func _show_loadout_intro() -> void:
	var character_name := DataLoader.tr_key(character_data.get("name_key", character_id))
	var weapon_name := DataLoader.tr_key(DataLoader.get_row("weapons", weapon_id).get("name_key", weapon_id))
	var text := "%s 等级%d  ·  %s 等级%d" % [character_name, character_level, weapon_name, weapon_level]
	if not pet_data.is_empty():
		text += "  ·  宠物 等级%d" % pet_level
	AudioManager.play_sfx(_character_intro_sfx(), -4.0, 0.02)
	_show_wave_toast(text, Color(0.78, 0.94, 1.0))

func _spawn_loadout_badge(origin: Vector2, label_text: String, level: int, color: Color) -> void:
	if not _can_spawn_hud_fx(true):
		return
	var badge := Label.new()
	_track_transient_fx(badge, "hud")
	badge.text = "%s\n等级%d" % [label_text, level]
	badge.position = origin - Vector2(58, 34)
	badge.size = Vector2(116, 68)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", UiKit.bumped_font_size(22))
	badge.add_theme_color_override("font_color", color)
	badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	badge.add_theme_constant_override("outline_size", 4)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Hud.add_child(badge)
	var tween := badge.create_tween()
	tween.tween_property(badge, "scale", Vector2(1.14, 1.14), 0.12)
	tween.tween_property(badge, "scale", Vector2.ONE, 0.12)
	tween.tween_interval(1.0)
	tween.parallel().tween_property(badge, "position:y", badge.position.y - 32.0, 0.3)
	tween.parallel().tween_property(badge, "modulate:a", 0.0, 0.3)
	tween.tween_callback(badge.queue_free)

func _spawn_enemy_entry_vfx(enemy: Node, is_boss: bool) -> void:
	if not is_instance_valid(enemy):
		return
	var color := Color(1.0, 0.3, 0.16, 0.34) if is_boss else Color(0.74, 0.9, 1.0, 0.22)
	var sequence := "vfx_boss_phase" if is_boss else "vfx_levelup_glow"
	var fx := _spawn_vfx_sequence(sequence, enemy.global_position + Vector2(0, -34), 1.05 if is_boss else 0.42, Color(color.r, color.g, color.b, 0.62), 1.15, randf_range(-0.16, 0.16), 1.08, Vector2(0, -8), randf_range(-0.18, 0.18), is_boss)
	if fx == null and is_boss:
		_spawn_attack_sprite("res://assets/production/sprites/vfx/vfx_threat_warning.png", enemy.global_position + Vector2(0, -86), Color(1.0, 0.28, 0.12, 0.72), 1.3, 0.38)

func _spawn_attack_telegraph(origin: Vector2, color: Color, label_text: String) -> void:
	_spawn_attack_sprite("res://assets/production/sprites/vfx/vfx_threat_warning.png", origin, Color(color.r, color.g, color.b, 0.64), 0.58, 0.24)
	if not _can_spawn_float_text(true):
		return
	var label := Label.new()
	_track_transient_fx(label, "float_text")
	label.text = label_text
	label.position = origin + Vector2(-120, -92)
	label.size = Vector2(240, 42)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UiKit.bumped_font_size(24))
	label.add_theme_color_override("font_color", Color(color.r, color.g, color.b, 0.95))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Hud.add_child(label)
	var tween := label.create_tween()
	tween.parallel().tween_property(label, "position:y", label.position.y - 34.0, 0.38)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.38)
	tween.tween_callback(label.queue_free)

func _pulse_reward_target(kind: String) -> void:
	var target: Control
	match kind:
		"gold":
			if has_node("Hud/BottomBar/GoldLabel"):
				target = $Hud/BottomBar/GoldLabel
		"xp":
			if has_node("Hud/BottomBar/XpBar"):
				target = $Hud/BottomBar/XpBar
		"hp":
			target = get_node_or_null(HUD_HP_BAR_PATH) as Control
	if target == null:
		return
	var tween := target.create_tween()
	tween.tween_property(target, "scale", Vector2(1.08, 1.08), 0.08)
	tween.tween_property(target, "scale", Vector2.ONE, 0.12)

func _shake_hud(amount: float, duration: float) -> void:
	var original: Vector2 = $Hud.offset
	var tween := $Hud.create_tween()
	var steps := 5
	for i in range(steps):
		var offset := Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
		tween.tween_property($Hud, "offset", original + offset, duration / float(steps))
	tween.tween_property($Hud, "offset", original, 0.05)

func _show_boss_banner(boss_name: String) -> void:
	var banner := TextureRect.new()
	banner.texture = load("res://assets/production/sprites/ui/ui_warning_strip.png")
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_SCALE
	banner.modulate = Color(1.0, 0.30, 0.18, 0.92)
	banner.position = Vector2(-1080, 520)
	banner.size = Vector2(1080, 106)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Hud.add_child(banner)
	var label := Label.new()
	label.text = "首领来袭  %s" % boss_name
	label.position = Vector2(0, 16)
	label.size = Vector2(1080, 74)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UiKit.bumped_font_size(42))
	label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.28, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(label)
	var tween := banner.create_tween()
	tween.tween_property(banner, "position:x", 0.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.68)
	tween.tween_property(banner, "position:x", 1080.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(banner.queue_free)

func _vfx_path(kind: String, element: String) -> String:
	match kind:
		"muzzle":
			match element:
				"fire":
					return "res://assets/production/sprites/vfx/vfx_muzzle_fire.png"
				"ice":
					return "res://assets/production/sprites/vfx/vfx_muzzle_ice.png"
				"lightning":
					return "res://assets/production/sprites/vfx/vfx_muzzle_lightning.png"
				"poison":
					return "res://assets/production/sprites/vfx/vfx_muzzle_poison.png"
				_:
					return "res://assets/production/sprites/vfx/vfx_muzzle_physical.png"
		"hit":
			match element:
				"fire":
					return "res://assets/production/sprites/vfx/vfx_hit_fire.png"
				"ice":
					return "res://assets/production/sprites/vfx/vfx_hit_ice.png"
				"lightning":
					return "res://assets/production/sprites/vfx/vfx_hit_lightning.png"
				"poison":
					return "res://assets/production/sprites/vfx/vfx_hit_poison.png"
				_:
					return "res://assets/production/sprites/vfx/vfx_hit_physical.png"
	return "res://assets/production/sprites/vfx/vfx_hit_physical.png"

func _level_tint(level: int) -> Color:
	if level >= 25:
		return Color(1.0, 0.82, 0.34, 1.0)
	if level >= 15:
		return Color(0.72, 0.9, 1.0, 1.0)
	if level >= 8:
		return Color(0.78, 1.0, 0.72, 1.0)
	return Color.WHITE

func _visual_level_scale(level: int) -> Vector2:
	var bonus := clampf(float(level - 1) * 0.006, 0.0, 0.16)
	return Vector2(1.0 + bonus, 1.0 + bonus)

func _attach_growth_badge(parent: Node, level: int, offset: Vector2) -> void:
	if level < 8 or parent == null:
		return
	var badge := Label.new()
	badge.name = "GrowthBadge"
	badge.text = _growth_badge_text(level)
	badge.position = offset
	badge.size = Vector2(180, 34)
	badge.add_theme_font_size_override("font_size", UiKit.bumped_font_size(20))
	badge.add_theme_color_override("font_color", _level_tint(level))
	badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	badge.add_theme_constant_override("outline_size", 4)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(badge)
	var glow := Node2D.new()
	glow.name = "GrowthGlow"
	glow.position = Vector2(0, -36)
	glow.scale = Vector2(0.36, 0.36)
	var glow_color := _level_tint(level)
	glow_color.a = 0.32
	glow.add_child(_make_ring_line(76.0, glow_color, 2.0, 60))
	parent.add_child(glow)

func _growth_badge_text(level: int) -> String:
	if level >= 25:
		return "III"
	if level >= 15:
		return "II"
	return "I"

func _growth_rank(level: int) -> int:
	if level >= 25:
		return 3
	if level >= 15:
		return 2
	if level >= 8:
		return 1
	return 0

func _pet_scaled_value(value_key: String, growth_key: String) -> float:
	var value := float(pet_data.get(value_key, 0.0))
	var growth := float(pet_data.get(growth_key, 0.0))
	return value * (1.0 + growth * float(max(pet_level - 1, 0)))

func _pet_linear_value(value_key: String, growth_key: String) -> float:
	var value := float(pet_data.get(value_key, 0.0))
	var growth := float(pet_data.get(growth_key, 0.0))
	return value + growth * float(max(pet_level - 1, 0))

func _on_projectile_split_requested(origin: Vector2, direction: Vector2, count: int, damage: float, element: String, armor_penetration: float, status_strength: float) -> void:
	AudioManager.play_sfx("skill_split_shot", -9.0, 0.025)
	var fan := deg_to_rad(30.0 + float(count) * 10.0)
	_spawn_split_burst_vfx(origin, direction, fan, count, element)
	_spawn_attack_ring(origin, 92.0 + float(count) * 14.0, Color(_element_color(element).r, _element_color(element).g, _element_color(element).b, 0.26), 0.18)
	var target_directions := _split_target_directions(origin, direction, count, fan)
	for i in range(count):
		var projectile := PROJECTILE_SCENE.instantiate()
		_configure_audit_projectile(projectile)
		var split_direction: Vector2 = target_directions[i]
		projectile.setup(origin + split_direction * 22.0, split_direction, 1180.0, damage, element, 0, 0, 0.55, 2.6, 0.0, 0.0, 0.82, 0, "res://assets/production/sprites/projectiles/proj_split_mini.png", "split", armor_penetration, status_strength)
		projectile.hit_confirmed.connect(_on_projectile_hit_confirmed)
		if _audit_combat_rng != null:
			$ProjectileLayer.add_child(projectile)
		else:
			$ProjectileLayer.call_deferred("add_child", projectile)
		_activate_audit_physics_node(projectile)

func _on_projectile_hit_confirmed(primary: Node, origin: Vector2, damage: float, element: String, splash_radius: float, cloud_radius: float, chain_depth: int, visual_profile: String, armor_penetration: float, status_strength: float, damage_source := "weapon") -> void:
	_spawn_element_impact_vfx(primary, origin, element, visual_profile)
	_play_skill_impact_sfx(element)
	_trigger_impact_feedback(primary, damage, visual_profile)
	if chain_depth <= 0 and damage_source == "weapon":
		_spawn_chain_projectiles(primary, origin, damage, element, armor_penetration, status_strength)
	if damage_source == "weapon":
		_apply_character_bullet_on_hit(primary, origin, damage, element)
	if chain_depth <= 0 and damage_source == "weapon":
		_apply_premium_weapon_on_hit(primary, origin, damage, element)
	var radius: float = maxf(splash_radius, cloud_radius)
	if radius <= 0.0:
		if element == "lightning" and skills.level("skill_tesla") > 0:
			_spawn_chain_flash(origin, primary)
		return
	var color := Color(1.0, 0.45, 0.18) if splash_radius >= cloud_radius else Color(0.42, 1.0, 0.28)
	_spawn_radial_vfx(origin, radius, color)
	for target in $EnemyLayer.get_children():
		if target == primary or not is_instance_valid(target) or not target.has_method("take_damage"):
			continue
		if target.global_position.distance_to(origin) > radius:
			continue
		var falloff := 1.0 - clampf(target.global_position.distance_to(origin) / radius, 0.0, 1.0)
		var scale := 0.45 if splash_radius >= cloud_radius else 0.32
		_deal_damage_with_source(target, damage * scale * (0.55 + falloff * 0.45), element, armor_penetration, status_strength, damage_source)

func _apply_premium_weapon_on_hit(primary: Node, origin: Vector2, damage: float, effective_element: String) -> void:
	var native_element := str(DataLoader.get_row("weapons", weapon_id).get("element", "physical"))
	if effective_element != native_element:
		return
	match _weapon_visual_profile():
		"apocalypse_thunder":
			_apply_apocalypse_thunder_on_hit(primary, origin, damage)
		"apocalypse_inferno":
			_apply_apocalypse_inferno_on_hit(primary, origin, damage)
		"apocalypse_absolute_zero":
			_apply_apocalypse_absolute_zero_on_hit(primary, origin, damage)
		"apocalypse_golden_law":
			_apply_apocalypse_golden_law_on_hit(primary, origin, damage)


func _deal_damage_with_source(target: Node, amount: float, element: String, armor_penetration: float, status_strength: float, source: String) -> void:
	if target == null or not is_instance_valid(target) or not target.has_method("take_damage"):
		return
	target.set_meta("incoming_damage_source", source)
	target.set_meta("_damage_source_for_feedback", source)
	target.take_damage(amount, element, armor_penetration, status_strength)
	# Non-Enemy test doubles keep their four-argument interface and may not
	# consume the context marker; remove it here to avoid a stale attribution.
	if is_instance_valid(target) and target.has_meta("incoming_damage_source"):
		target.remove_meta("incoming_damage_source")
	if is_instance_valid(target) and target.has_meta("_damage_source_for_feedback"):
		target.remove_meta("_damage_source_for_feedback")

func _apply_apocalypse_thunder_on_hit(primary: Node, origin: Vector2, damage: float) -> void:
	if primary == null or not is_instance_valid(primary):
		return
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var set_id := str(weapon.get("premium_set", ""))
	var set_row := DataLoader.get_row("premium_sets", set_id)
	var special: Dictionary = weapon.get("special", {})
	var efficiency := _chip_value("overload_efficiency")
	if _premium_set_piece_count(set_id) >= 2:
		efficiency += float(set_row.get("two_piece", {}).get("overload_efficiency", 0.0))
	var hits_needed := maxi(3, int(round(float(special.get("overload_hits", 7)) * (1.0 - clampf(efficiency, 0.0, 0.45)))))
	apocalypse_overload_hits += 1
	if apocalypse_overload_hits < hits_needed:
		if apocalypse_overload_hits == hits_needed - 1:
			_spawn_attack_ring(origin, 104.0, Color(0.38, 0.9, 1.0, 0.42), 0.18)
		return
	apocalypse_overload_hits = 0
	var target := _densest_apocalypse_target(primary) if _premium_set_piece_count(set_id) >= 4 else primary
	if target == null or not is_instance_valid(target):
		return
	var impact := (target as Node2D).global_position
	var overload_damage := damage * float(special.get("overload_damage_mult", 2.2))
	if target.has_method("take_damage"):
		_deal_damage_with_source(target, overload_damage, "lightning", 0.12, 1.45, "overload")
	var visual_impact := _apocalypse_edge_safe_vfx_point(impact)
	if visual_impact.distance_to(impact) > 2.0:
		# Keep the accepted full-size pillar inside the portrait viewport. The short
		# grounding arc preserves the hit location when the victim hugs an edge.
		_spawn_chain_arc(visual_impact, impact, "lightning")
	_spawn_attack_sprite(
		"res://assets/production/sprites/vfx/vfx_boss_storm_column.png",
		visual_impact + Vector2(0, -150),
		Color(0.80, 0.94, 1.0, 0.94),
		0.78,
		0.34
	)
	_spawn_attack_sprite(
		"res://assets/production/sprites/vfx/vfx_boss_storm_impact.png",
		visual_impact + Vector2(0, -34),
		Color(0.92, 0.50, 1.0, 0.90),
		0.66,
		0.28
	)
	_spawn_attack_ring(impact, 172.0, Color(0.32, 0.92, 1.0, 0.48), 0.26)
	AudioManager.play_sfx("skill_tesla", -3.0, 0.02)
	if _premium_set_piece_count(set_id) >= 4 and apocalypse_terminal_cooldown <= 0.0:
		var four_piece: Dictionary = set_row.get("four_piece", {})
		var terminal_damage := damage * float(four_piece.get("terminal_pillar_damage_mult", 2.6))
		if target.has_method("take_damage"):
			_deal_damage_with_source(target, terminal_damage, "lightning", 0.16, 1.65, "terminal")
		if pet_sprite != null and is_instance_valid(pet_sprite):
			_spawn_chain_arc(pet_sprite.global_position + Vector2(0, -26), visual_impact, "lightning")
			_play_pet_skill_feedback(
				DataLoader.get_row("pets", str(set_row.get("pet", ""))).get("pet_skill", {}),
				pet_sprite.global_position + Vector2(0, -34),
				Color(0.62, 0.42, 1.0, 1.0),
				138.0
			)
		_spawn_float_text(impact + Vector2(-118, -112), "终端雷柱", Color(0.48, 0.94, 1.0, 1.0), true, 24, 250.0)
		apocalypse_terminal_cooldown = float(set_row.get("four_piece", {}).get("terminal_pillar_cooldown", 8.0))


func _apply_apocalypse_inferno_on_hit(primary: Node, origin: Vector2, damage: float) -> void:
	if primary == null or not is_instance_valid(primary) or not primary is Node2D:
		return
	var hp_value: Variant = primary.get("hp")
	if hp_value != null and float(hp_value) <= 0.0:
		return
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var set_id := str(weapon.get("premium_set", ""))
	var set_row := DataLoader.get_row("premium_sets", set_id)
	var special: Dictionary = weapon.get("special", {})
	var efficiency := _chip_value("combustion_stack_efficiency")
	if _premium_set_piece_count(set_id) >= 2:
		efficiency += float(set_row.get("two_piece", {}).get("combustion_stack_efficiency", 0.0))
	var stack_cap := maxi(3, int(special.get("combustion_max_stacks", 5)))
	var trigger_stacks := maxi(3, int(round(float(stack_cap) * (1.0 - clampf(efficiency, 0.0, 0.42)))))
	var stacks := int(primary.get_meta("inferno_combustion_stacks", 0)) + maxi(1, int(special.get("combustion_stack_gain", 1)))
	primary.set_meta("inferno_combustion_stacks", mini(stacks, stack_cap))
	if stacks < trigger_stacks:
		if stacks == trigger_stacks - 1:
			var ready_impact := (primary as Node2D).global_position + Vector2(0, -34 if not _is_boss_node(primary) else -70)
			var ready_scale := 0.40 if not _is_boss_node(primary) else 0.66
			_spawn_vfx_sequence(
				"vfx_status_inferno_burn",
				ready_impact,
				_inferno_edge_safe_vfx_scale(ready_impact, ready_scale),
				Color(1.0, 0.82, 0.54, 0.58),
				1.18,
				0.0,
				1.02,
				Vector2.ZERO,
				0.0,
				false
			)
			_spawn_attack_ring((primary as Node2D).global_position, 92.0, Color(1.0, 0.34, 0.05, 0.26), 0.17)
		return
	var now := _gameplay_now_seconds()
	var ready_at := float(primary.get_meta("inferno_combustion_ready_at", 0.0))
	if now < ready_at:
		return
	primary.set_meta("inferno_combustion_stacks", 0)
	primary.set_meta("inferno_combustion_ready_at", now + float(special.get("combustion_trigger_cooldown", 1.4)))
	var impact := (primary as Node2D).global_position
	var radius := float(special.get("combustion_radius", 230.0))
	var max_targets := maxi(1, int(special.get("combustion_max_targets", 5)))
	var burst_damage := damage * float(special.get("combustion_damage_mult", 2.3)) * (1.0 + _chip_value("combustion_damage_mult"))
	var candidates: Array[Dictionary] = []
	for target in $EnemyLayer.get_children():
		if not is_instance_valid(target) or not target is Node2D or not target.has_method("take_damage"):
			continue
		var distance := (target as Node2D).global_position.distance_to(impact)
		if distance <= radius:
			candidates.append({"target": target, "distance": distance})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _audit_distance_candidate_less(a, b)
	)
	for index in range(mini(candidates.size(), max_targets)):
		var candidate: Dictionary = candidates[index]
		var target := candidate.get("target") as Node
		if target == null or not is_instance_valid(target):
			continue
		var distance := float(candidate.get("distance", 0.0))
		var falloff := lerpf(1.0, float(special.get("combustion_spread_falloff", 0.62)), clampf(distance / maxf(radius, 1.0), 0.0, 1.0))
		_deal_damage_with_source(target, burst_damage * falloff, "fire", 0.10, float(special.get("burn_ratio", 0.38)), "combustion")
	var reduced := SettingsManager.reduced_effects_enabled()
	var visual_impact := impact + Vector2(0, -34 if not _is_boss_node(primary) else -68)
	var desired_scale := (1.08 if _is_boss_node(primary) else 0.84) * (0.76 if reduced else 1.0)
	_spawn_vfx_sequence(
		"vfx_apocalypse_inferno_combustion",
		visual_impact,
		_inferno_edge_safe_vfx_scale(visual_impact, desired_scale),
		Color(1.0, 0.90, 0.66, 0.62 if reduced else 0.96),
		1.0,
		0.0,
		1.03,
		Vector2(0, -6),
		0.0,
		true
	)
	_spawn_attack_ring(impact, radius, Color(1.0, 0.68, 0.14, 0.28 if reduced else 0.40), 0.28)
	_spawn_float_text(impact + Vector2(-78, -112), LocalizationManager.text("爆燃"), Color(1.0, 0.62, 0.14, 1.0), true, 24, 220.0)
	AudioManager.play_sfx("apocalypse_inferno_combustion", -3.5, 0.018)
	if inferno_feedback_cooldown <= 0.0:
		SettingsManager.pulse_haptic("medium")
		inferno_feedback_cooldown = 0.68


func _apply_apocalypse_absolute_zero_on_hit(primary: Node, _origin: Vector2, damage: float) -> void:
	if primary == null or not is_instance_valid(primary) or not primary is Node2D:
		return
	var hp_value: Variant = primary.get("hp")
	if hp_value != null and float(hp_value) <= 0.0:
		return
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var set_id := str(weapon.get("premium_set", ""))
	var set_row := DataLoader.get_row("premium_sets", set_id)
	var special: Dictionary = weapon.get("special", {})
	var efficiency := _chip_value("brittle_efficiency")
	if _premium_set_piece_count(set_id) >= 2:
		efficiency += float(set_row.get("two_piece", {}).get("brittle_efficiency", 0.0))
	var base_hits := maxi(3, int(special.get("brittle_hits", 5)))
	var threshold := maxi(3, int(round(float(base_hits) * (1.0 - clampf(efficiency, 0.0, 0.44)))))
	if _is_boss_node(primary):
		threshold += maxi(0, int(special.get("boss_threshold_bonus", 1)))
	var stacks := int(primary.get_meta("absolute_zero_brittle_stacks", 0)) + 1
	primary.set_meta("absolute_zero_brittle_stacks", mini(stacks, threshold))
	if primary.has_method("mark_ice_slow_visual"):
		primary.mark_ice_slow_visual(2.2)
	if stacks < threshold:
		if stacks == threshold - 1:
			var ready_center := (primary as Node2D).global_position + Vector2(0, -36 if not _is_boss_node(primary) else -72)
			_spawn_vfx_sequence(
				"vfx_status_absolute_zero_brittle",
				ready_center,
				0.42 if not _is_boss_node(primary) else 0.70,
				Color(0.72, 0.96, 1.0, 0.58),
				1.1,
				0.0,
				1.02,
				Vector2.ZERO,
				0.0,
				false
			)
			_spawn_float_text((primary as Node2D).global_position + Vector2(-64, -104), LocalizationManager.text("脆化"), Color(0.62, 0.92, 1.0, 1.0), false, 21, 180.0)
		return
	var now := _gameplay_now_seconds()
	if now < float(primary.get_meta("absolute_zero_shatter_ready_at", 0.0)):
		return
	primary.set_meta("absolute_zero_brittle_stacks", 0)
	primary.set_meta("absolute_zero_shatter_ready_at", now + float(special.get("shatter_cooldown", 0.85)))
	var impact := (primary as Node2D).global_position
	var radius := float(special.get("shatter_radius", 205.0))
	var max_targets := maxi(1, int(special.get("shatter_max_targets", 5)))
	var set_bonus := float(set_row.get("two_piece", {}).get("shatter_damage_mult", 0.0)) if _premium_set_piece_count(set_id) >= 2 else 0.0
	var shatter_damage := damage * float(special.get("shatter_damage_mult", 1.85)) * (1.0 + _chip_value("shatter_damage_mult") + set_bonus)
	var candidates: Array[Dictionary] = []
	for target in $EnemyLayer.get_children():
		if not is_instance_valid(target) or not target is Node2D or not target.has_method("take_damage"):
			continue
		var distance := (target as Node2D).global_position.distance_to(impact)
		if distance <= radius:
			candidates.append({"target": target, "distance": distance})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _audit_distance_candidate_less(a, b)
	)
	for index in range(mini(candidates.size(), max_targets)):
		var candidate: Dictionary = candidates[index]
		var target := candidate.get("target") as Node
		if target == null or not is_instance_valid(target):
			continue
		var distance := float(candidate.get("distance", 0.0))
		var falloff := lerpf(1.0, float(special.get("shatter_falloff", 0.66)), clampf(distance / maxf(radius, 1.0), 0.0, 1.0))
		_deal_damage_with_source(target, shatter_damage * falloff, "ice", 0.08, float(special.get("slow", 0.30)), "shatter")
	var reduced := SettingsManager.reduced_effects_enabled()
	var center := impact + Vector2(0, -36 if not _is_boss_node(primary) else -72)
	_spawn_vfx_sequence(
		"vfx_apocalypse_absolute_zero_shatter",
		center,
		_inferno_edge_safe_vfx_scale(center, (0.78 if reduced else 1.02) * (1.18 if _is_boss_node(primary) else 1.0)),
		Color(0.84, 0.98, 1.0, 0.60 if reduced else 0.94),
		1.0,
		0.0,
		1.02,
		Vector2(0, -5),
		0.0,
		true
	)
	_spawn_attack_ring(impact, radius, Color(0.44, 0.90, 1.0, 0.24 if reduced else 0.38), 0.28)
	_spawn_float_text(impact + Vector2(-70, -112), LocalizationManager.text("碎冰"), Color(0.66, 0.94, 1.0, 1.0), true, 24, 220.0)
	AudioManager.play_sfx("apocalypse_absolute_zero_shatter", -3.5, 0.018)
	if absolute_zero_feedback_cooldown <= 0.0:
		SettingsManager.pulse_haptic("medium")
		absolute_zero_feedback_cooldown = 0.70
	if _premium_set_piece_count(set_id) >= 4 and absolute_zero_wave_cooldown <= 0.0:
		_apply_absolute_zero_crystal_wave(primary, impact, damage, set_row)


func _apply_absolute_zero_crystal_wave(primary: Node, impact: Vector2, damage: float, set_row: Dictionary) -> void:
	var four_piece: Dictionary = set_row.get("four_piece", {})
	if int(four_piece.get("generation_limit", 1)) < 1:
		return
	var dense_target := _densest_apocalypse_target(primary)
	if dense_target == null or not is_instance_valid(dense_target) or not dense_target is Node2D:
		return
	var wave_center := (dense_target as Node2D).global_position
	var travel := wave_center - impact
	if travel.length_squared() < 4.0:
		travel = Vector2.UP
	var radius := float(four_piece.get("crystal_wave_radius", 310.0))
	var max_targets := maxi(1, int(four_piece.get("crystal_wave_max_targets", 5)))
	var targets: Array[Dictionary] = []
	for candidate in $EnemyLayer.get_children():
		if not is_instance_valid(candidate) or not candidate is Node2D or not candidate.has_method("take_damage"):
			continue
		var distance := (candidate as Node2D).global_position.distance_to(wave_center)
		if distance <= radius:
			targets.append({"target": candidate, "distance": distance})
	targets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _audit_distance_candidate_less(a, b)
	)
	for index in range(mini(targets.size(), max_targets)):
		var target := targets[index].get("target") as Node
		if target == null or not is_instance_valid(target):
			continue
		var wave_damage := damage * float(four_piece.get("crystal_wave_damage_mult", 0.68)) * pow(float(four_piece.get("crystal_wave_falloff", 0.72)), float(index))
		_deal_damage_with_source(target, wave_damage, "ice", 0.04, 0.34, "crystal_wave")
	var midpoint := impact.lerp(wave_center, 0.55) + Vector2(0, -34)
	_spawn_vfx_sequence(
		"vfx_apocalypse_absolute_zero_wave",
		midpoint,
		_inferno_edge_safe_vfx_scale(midpoint, 0.70 if SettingsManager.reduced_effects_enabled() else 0.94),
		Color(0.76, 0.96, 1.0, 0.58 if SettingsManager.reduced_effects_enabled() else 0.90),
		1.0,
		_directional_vfx_rotation("vfx_apocalypse_absolute_zero_wave", travel),
		1.02,
		travel.normalized() * 28.0,
		0.0,
		true
	)
	_spawn_float_text(wave_center + Vector2(-82, -108), LocalizationManager.text("冰晶波"), Color(0.70, 0.94, 1.0, 1.0), true, 22, 220.0)
	absolute_zero_wave_cooldown = float(four_piece.get("crystal_wave_cooldown", 5.5))


func _apply_apocalypse_golden_law_on_hit(primary: Node, _origin: Vector2, damage: float) -> void:
	if primary == null or not is_instance_valid(primary) or not primary is Node2D:
		return
	var hp_value: Variant = primary.get("hp")
	if hp_value != null and float(hp_value) <= 0.0:
		return
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var set_id := str(weapon.get("premium_set", ""))
	var set_row := DataLoader.get_row("premium_sets", set_id)
	var special: Dictionary = weapon.get("special", {})
	var now := _gameplay_now_seconds()
	var mark_until := float(primary.get_meta("golden_law_mark_until", 0.0))
	if now < mark_until:
		var mark_amp := float(primary.get_meta("golden_law_mark_amp", 0.0))
		if mark_amp > 0.0:
			_deal_damage_with_source(primary, damage * mark_amp, "physical", 0.16, 0.0, "golden_mark")
	var efficiency := _chip_value("judgment_efficiency")
	if _premium_set_piece_count(set_id) >= 2:
		efficiency += float(set_row.get("two_piece", {}).get("judgment_efficiency", 0.0))
	var threshold := maxi(3, int(round(float(special.get("judgment_hits", 6)) * (1.0 - clampf(efficiency, 0.0, 0.48)))))
	var stacks := int(primary.get_meta("golden_law_judgment_stacks", 0)) + 1
	primary.set_meta("golden_law_judgment_stacks", mini(stacks, threshold))
	if stacks < threshold:
		if stacks == threshold - 1:
			var ready_center := (primary as Node2D).global_position + Vector2(0, -38 if not _is_boss_node(primary) else -76)
			_spawn_vfx_sequence("vfx_status_golden_law_judgment", ready_center, 0.44 if not _is_boss_node(primary) else 0.72, Color(1.0, 0.84, 0.42, 0.64), 1.0, 0.0, 1.02, Vector2.ZERO, 0.0, false)
		return
	if now < float(primary.get_meta("golden_law_verdict_ready_at", 0.0)):
		return
	primary.set_meta("golden_law_judgment_stacks", 0)
	primary.set_meta("golden_law_verdict_ready_at", now + float(special.get("judgment_cooldown", 0.62)))
	var set_bonus := float(set_row.get("two_piece", {}).get("verdict_damage_mult", 0.0)) if _premium_set_piece_count(set_id) >= 2 else 0.0
	var verdict_damage := damage * float(special.get("judgment_damage_mult", 1.18)) * (1.0 + _chip_value("verdict_damage_mult") + set_bonus)
	var penetration := clampf(float(special.get("judgment_armor_penetration", 0.32)) + _chip_value("armor_penetration"), 0.0, 0.72)
	_deal_damage_with_source(primary, verdict_damage, "physical", penetration, 0.0, "golden_verdict")
	var impact := (primary as Node2D).global_position
	var center := impact + Vector2(0, -38 if not _is_boss_node(primary) else -76)
	_spawn_vfx_sequence("vfx_apocalypse_golden_law_impact", center, _inferno_edge_safe_vfx_scale(center, 0.76 if SettingsManager.reduced_effects_enabled() else 1.0), Color(1.0, 0.90, 0.58, 0.92), 1.0, 0.0, 1.02, Vector2(0, -4), 0.0, true)
	_spawn_float_text(impact + Vector2(-80, -116), LocalizationManager.text("黄金裁决"), Color(1.0, 0.82, 0.34, 1.0), true, 24, 220.0)
	AudioManager.play_sfx("apocalypse_golden_law_impact", -3.5, 0.018)
	if _premium_set_piece_count(set_id) >= 4 and golden_law_decree_cooldown <= 0.0:
		_apply_golden_law_decree(damage, set_row)


func _apply_golden_law_decree(damage: float, set_row: Dictionary) -> void:
	var four_piece: Dictionary = set_row.get("four_piece", {})
	if int(four_piece.get("generation_limit", 1)) < 1:
		return
	var max_targets := maxi(1, int(four_piece.get("decree_max_targets", 4)))
	var targets: Array[Node2D] = []
	for candidate in $EnemyLayer.get_children():
		if is_instance_valid(candidate) and candidate is Node2D and candidate.has_method("take_damage"):
			targets.append(candidate as Node2D)
	targets.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		if not is_equal_approx(a.global_position.y, b.global_position.y):
			return a.global_position.y > b.global_position.y
		return _audit_combat_rng != null and _audit_enemy_precedes(a, b)
	)
	if targets.size() > max_targets:
		targets.resize(max_targets)
	for index in range(targets.size()):
		var target := targets[index]
		if target == null or not is_instance_valid(target):
			continue
		var decree_damage := damage * float(four_piece.get("decree_damage_mult", 0.78)) * pow(float(four_piece.get("decree_falloff", 0.82)), float(index))
		_deal_damage_with_source(target, decree_damage, "physical", 0.24, 0.0, "golden_decree")
		var center := target.global_position + Vector2(0, -46 if not _is_boss_node(target) else -82)
		_spawn_vfx_sequence("vfx_apocalypse_golden_law_decree", center, 0.46 if SettingsManager.reduced_effects_enabled() else 0.62, Color(1.0, 0.91, 0.62, 0.86), 1.0, 0.0, 1.02, Vector2.ZERO, float(index) * 0.035, false)
	if not targets.is_empty():
		_spawn_float_text((targets[0] as Node2D).global_position + Vector2(-72, -112), LocalizationManager.text("黄金敕令"), Color(1.0, 0.86, 0.42, 1.0), true, 22, 220.0)
	AudioManager.play_sfx("apocalypse_golden_law_decree", -4.0, 0.02)
	golden_law_decree_cooldown = float(four_piece.get("decree_cooldown", 5.8))


func _apply_inferno_death_spread(enemy: Node, reward: Dictionary) -> void:
	if str(reward.get("death_source", "")) != "combustion" or not is_instance_valid(enemy) or not enemy is Node2D:
		return
	var set_id := "set_apocalypse_inferno"
	if _premium_set_piece_count(set_id) < 4:
		return
	var set_row := DataLoader.get_row("premium_sets", set_id)
	var four_piece: Dictionary = set_row.get("four_piece", {})
	var generation_limit := maxi(0, int(four_piece.get("generation_limit", 1)))
	if generation_limit < 1:
		return
	var origin := (enemy as Node2D).global_position
	var radius := float(four_piece.get("death_spread_radius", 260.0))
	var max_targets := maxi(1, int(four_piece.get("death_spread_max_targets", 4)))
	var falloff := clampf(float(four_piece.get("death_spread_falloff", 0.62)), 0.25, 0.95)
	var source_damage := _current_primary_shot_damage("fire", false)
	var targets: Array[Node2D] = []
	for candidate in $EnemyLayer.get_children():
		if candidate == enemy or not is_instance_valid(candidate) or not candidate is Node2D:
			continue
		if (candidate as Node2D).global_position.distance_to(origin) <= radius:
			targets.append(candidate as Node2D)
	targets.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return _audit_node2d_metric_less(a, b, a.global_position.distance_squared_to(origin), b.global_position.distance_squared_to(origin))
	)
	for index in range(mini(targets.size(), max_targets)):
		var target := targets[index]
		var scaled := source_damage * 0.12 * pow(falloff, float(index))
		_deal_damage_with_source(target, scaled, "fire", 0.0, float(four_piece.get("death_spread_burn_ratio", 0.38)), "set_spread")
		_spawn_weapon_trace(origin, target.global_position, Color(1.0, 0.32, 0.04, 0.64), 10.0, 0.18)
	var spread_center := origin + Vector2(0, -34 if not _is_boss_node(enemy) else -68)
	var reduced := SettingsManager.reduced_effects_enabled()
	_spawn_vfx_sequence(
		"vfx_apocalypse_inferno_spread",
		spread_center,
		_inferno_edge_safe_vfx_scale(spread_center, 0.64 if reduced else 0.86),
		Color(1.0, 0.80, 0.48, 0.56 if reduced else 0.88),
		1.0,
		0.0,
		1.02,
		Vector2(0, -4),
		0.0,
		false
	)
	_spawn_attack_ring(origin, radius * 0.72, Color(1.0, 0.26, 0.04, 0.20 if reduced else 0.30), 0.24)
	AudioManager.play_sfx("apocalypse_inferno_combustion", -9.0, 0.02)

func _inferno_edge_safe_vfx_scale(point: Vector2, desired: float) -> float:
	# Keep the effect centered on the gameplay event instead of clamping it away
	# from a left/right enemy. Scale down only when the real event is near an
	# edge; the authored 512px source retains a 7.5% internal safety margin.
	var viewport_size := get_viewport().get_visible_rect().size
	var width := maxf(1080.0, viewport_size.x)
	var height := maxf(1920.0, viewport_size.y)
	var room := minf(minf(point.x, width - point.x), minf(point.y, height - point.y))
	var safe_scale := maxf(0.16, maxf(room, 24.0) / 226.0 * 0.92)
	return minf(maxf(desired, 0.16), safe_scale)

func _apocalypse_edge_safe_vfx_point(impact: Vector2) -> Vector2:
	# The authored column/impact textures are deliberately large (864/1254 px).
	# Keep their center within a safe visual band so no premium VFX is cropped on
	# either 1080-wide or safe-area portrait devices.
	return Vector2(clampf(impact.x, 420.0, 660.0), impact.y)

func _densest_apocalypse_target(fallback: Node) -> Node:
	var best: Node = fallback
	var best_count := -1
	for candidate in $EnemyLayer.get_children():
		if not is_instance_valid(candidate) or not candidate is Node2D:
			continue
		var count := 0
		for peer in $EnemyLayer.get_children():
			if is_instance_valid(peer) and peer is Node2D and (peer as Node2D).global_position.distance_to((candidate as Node2D).global_position) <= 240.0:
				count += 1
		# Break ties on the deterministic spawn index instead of raw $EnemyLayer
		# order: two candidates with an equal local crowd count previously kept
		# whichever the unsorted child list happened to visit first, which is
		# not guaranteed stable across otherwise-identical seeded runs.
		if count > best_count or (count == best_count and _audit_combat_rng != null and _audit_enemy_precedes(candidate, best)):
			best_count = count
			best = candidate
	return best

func _play_skill_impact_sfx(element: String) -> void:
	if skills.level("skill_pierce") > 0 and randf() < 0.16:
		AudioManager.play_sfx("skill_pierce", -12.5, 0.025)
	match element:
		"fire":
			if skills.level("skill_incendiary") > 0:
				AudioManager.play_sfx("skill_incendiary", -12.0, 0.025)
		"ice":
			if skills.level("skill_cryo") > 0:
				AudioManager.play_sfx("skill_cryo", -12.0, 0.025)
		"lightning":
			if skills.level("skill_tesla") > 0:
				AudioManager.play_sfx("skill_tesla", -12.0, 0.025)
		"poison":
			if skills.level("skill_venom") > 0:
				AudioManager.play_sfx("skill_venom", -12.0, 0.025)

func _apply_character_bullet_on_hit(primary: Node, origin: Vector2, damage: float, element: String) -> void:
	if primary == null or not is_instance_valid(primary) or not _is_character_affinity_element(element):
		return
	var rank := _growth_rank(character_level)
	if primary.has_method("amplify_character_status"):
		primary.amplify_character_status(element, damage, rank, _affinity_float("status_bonus"))
	match character_id:
		"frost":
			if primary.has_method("is_controlled") and primary.is_controlled():
				var shatter_damage := damage * (_affinity_float("shatter_bonus") + 0.04 * float(rank))
				if shatter_damage > 0.0 and primary.has_method("take_damage"):
					_spawn_attack_sprite("res://assets/production/sprites/vfx/vfx_freeze.png", origin + Vector2(0, -34), Color(0.58, 0.92, 1.0, 0.78), 0.46, 0.16)
					primary.take_damage(shatter_damage, "ice")
		"blaze":
			if _combat_randf() < 0.18 + 0.03 * float(rank):
				_spawn_attack_ring(origin, 92.0, Color(1.0, 0.42, 0.12, 0.2), 0.14)
		"volt":
			if _combat_randf() < 0.14 + 0.03 * float(rank):
				_spawn_chain_flash(origin, primary)

func _split_target_directions(origin: Vector2, base_direction: Vector2, count: int, fan: float) -> Array[Vector2]:
	var candidates := []
	for enemy in $EnemyLayer.get_children():
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		if enemy.global_position.y > BREACH_Y + 40.0:
			continue
		var enemy_node := enemy as Node2D
		var to_enemy: Vector2 = enemy_node.global_position - origin
		var dist: float = to_enemy.length()
		if dist <= 24.0 or dist > 720.0:
			continue
		var angle_penalty := absf(wrapf(to_enemy.angle() - base_direction.angle(), -PI, PI))
		candidates.append({"enemy": enemy, "score": dist + angle_penalty * 180.0})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _audit_target_score_less(a, b)
	)
	var directions: Array[Vector2] = []
	for i in range(count):
		if i < candidates.size():
			var target := candidates[i].get("enemy") as Node2D
			if target != null and is_instance_valid(target):
				directions.append((target.global_position - origin).normalized())
				continue
		var offset := lerpf(-fan, fan, 0.5 if count == 1 else float(i) / float(count - 1))
		directions.append(base_direction.rotated(offset).normalized())
	return directions

func _spawn_chain_projectiles(primary: Node, origin: Vector2, damage: float, element: String, armor_penetration: float, status_strength: float) -> void:
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var special: Dictionary = weapon.get("special", {})
	var weapon_profile := _weapon_visual_profile()
	var premium_set_id := str(weapon.get("premium_set", ""))
	var premium_set := DataLoader.get_row("premium_sets", premium_set_id)
	var mods := skills.projectile_mods()
	# No arbitrary chain ceiling: the authored skill/weapon/character/pet
	# bonuses resolve in full. Actual fan-out is naturally bounded by valid
	# enemies in range, while per-target falloff keeps dense waves controlled.
	var chain_count := _resolved_chain_count(element, mods, special)
	if chain_count <= 0:
		return
	var targets: Array[Node2D] = _chain_targets(origin, primary, chain_count, 430.0)
	var target_falloff := _character_chain_target_falloff(element)
	if weapon_profile == "apocalypse_thunder":
		target_falloff = maxf(target_falloff, float(special.get("chain_falloff", 0.88)) + _chip_value("chain_retention"))
		if _premium_set_piece_count(premium_set_id) >= 2:
			target_falloff += float(premium_set.get("two_piece", {}).get("chain_retention", 0.0))
		target_falloff = clampf(target_falloff, 0.72, 0.97)
	if not targets.is_empty():
		AudioManager.play_sfx("skill_tesla" if element == "lightning" and skills.level("skill_tesla") > 0 else "skill_ricochet", -9.5, 0.025)
	for target_index in range(targets.size()):
		var target := targets[target_index]
		if target == null or not is_instance_valid(target):
			continue
		var direction: Vector2 = (target.global_position - origin).normalized()
		var projectile := PROJECTILE_SCENE.instantiate()
		_configure_audit_projectile(projectile)
		var chain_element := "lightning" if element == "physical" else element
		var chain_base := 0.52 if weapon_profile == "apocalypse_thunder" else 0.42
		var chain_damage := damage * chain_base * pow(target_falloff, float(target_index))
		_spawn_chain_arc(origin, target.global_position, chain_element)
		var chain_profile := "apocalypse_thunder" if weapon_profile == "apocalypse_thunder" else "split"
		var chain_texture := "" if weapon_profile == "apocalypse_thunder" else "res://assets/production/sprites/projectiles/proj_split_mini.png"
		projectile.setup(origin + direction * 18.0, direction, 1500.0, chain_damage, chain_element, 0, 0, 0.55, 2.8, 0.0, 0.0, 0.62 if weapon_profile == "apocalypse_thunder" else 0.52, 1, chain_texture, chain_profile, armor_penetration, status_strength, target)
		projectile.hit_confirmed.connect(_on_projectile_hit_confirmed)
		if _audit_combat_rng != null:
			$ProjectileLayer.add_child(projectile)
		else:
			$ProjectileLayer.call_deferred("add_child", projectile)
		_activate_audit_physics_node(projectile)

func _chain_targets(origin: Vector2, primary: Node, count: int, radius: float) -> Array[Node2D]:
	var candidates := []
	for enemy in $EnemyLayer.get_children():
		if enemy == primary or not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		var enemy_node := enemy as Node2D
		var dist: float = origin.distance_to(enemy_node.global_position)
		if dist > radius:
			continue
		candidates.append({"enemy": enemy_node, "score": dist + maxf(0.0, enemy_node.global_position.y - origin.y) * 0.18})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _audit_target_score_less(a, b)
	)
	var targets: Array[Node2D] = []
	for item in candidates:
		if targets.size() >= count:
			break
		var target := item.get("enemy") as Node2D
		if target != null and is_instance_valid(target):
			targets.append(target)
	return targets


func _audit_target_score_less(a: Dictionary, b: Dictionary) -> bool:
	var left_score := float(a.get("score", 0.0))
	var right_score := float(b.get("score", 0.0))
	if not is_equal_approx(left_score, right_score):
		return left_score < right_score
	# Godot does not promise a stable custom sort when two floating scores are
	# equal. The runtime probe gives every enemy a deterministic spawn index so
	# audit-only target ties cannot depend on scene-tree/deferred queue timing.
	# Production combat has no such metadata and keeps its existing order.
	if _audit_combat_rng == null:
		return false
	var left := a.get("enemy") as Node
	var right := b.get("enemy") as Node
	if left == null or right == null:
		return false
	return int(left.get_meta("audit_spawn_index", 2147483647)) < int(right.get_meta("audit_spawn_index", 2147483647))


func _audit_enemy_precedes(left: Node, right: Node) -> bool:
	if left == null or right == null:
		return false
	return int(left.get_meta("audit_spawn_index", 2147483647)) < int(right.get_meta("audit_spawn_index", 2147483647))

## Same tie-break as _audit_target_score_less/_audit_enemy_precedes, for the
## premium-set AoE target rankers that sort {"target": Node, "distance": float}
## candidates by nearest-first. Two enemies at (float-)equal distance from the
## blast center previously fell back on Array.sort_custom's unstable order of
## the raw $EnemyLayer child list, so which one made the max_targets cut (and
## therefore took combustion/shatter/crystal-wave damage) could differ between
## byte-identical seeded runs.
func _audit_distance_candidate_less(a: Dictionary, b: Dictionary) -> bool:
	var left_distance := float(a.get("distance", 0.0))
	var right_distance := float(b.get("distance", 0.0))
	if not is_equal_approx(left_distance, right_distance):
		return left_distance < right_distance
	if _audit_combat_rng == null:
		return false
	return _audit_enemy_precedes(a.get("target") as Node, b.get("target") as Node)

## Same intent as _audit_distance_candidate_less, for the plain Array[Node2D]
## AoE rankers that sort by distance-to-a-point or by line depth (global_position.y)
## instead of a {"target":..,"distance":..} Dictionary.
func _audit_node2d_metric_less(left: Node2D, right: Node2D, left_metric: float, right_metric: float) -> bool:
	if not is_equal_approx(left_metric, right_metric):
		return left_metric < right_metric
	if _audit_combat_rng == null:
		return false
	return _audit_enemy_precedes(left, right)

func _impact_anchor(primary: Node, fallback: Vector2, vertical_offset := -38.0) -> Vector2:
	var pos := fallback
	var offset := vertical_offset
	if primary != null and is_instance_valid(primary) and primary is Node2D:
		pos = (primary as Node2D).global_position
		if _is_boss_node(primary):
			offset = minf(vertical_offset * 1.85, -72.0)
	return pos + Vector2(randf_range(-8.0, 8.0), offset)

func _is_boss_node(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	var boss_value: Variant = node.get("boss")
	return boss_value is bool and bool(boss_value)

func _impact_palette(element: String, hit_kind := "normal") -> Dictionary:
	match hit_kind:
		"armor":
			return {
				"core": Color(1.0, 0.86, 0.42, 0.96),
				"spark": Color(1.0, 0.7, 0.22, 0.9),
				"ring": Color(1.0, 0.92, 0.62, 0.58),
			}
		"armor_pierce":
			return {
				"core": Color(1.0, 0.94, 0.48, 1.0),
				"spark": Color(1.0, 0.72, 0.18, 0.94),
				"ring": Color(1.0, 0.88, 0.36, 0.66),
			}
		"shield":
			return {
				"core": Color(0.72, 0.94, 1.0, 0.94),
				"spark": Color(0.42, 0.82, 1.0, 0.82),
				"ring": Color(0.48, 0.84, 1.0, 0.62),
			}
		"immune", "phase_evade", "suppressed", "resisted":
			return {
				"core": Color(0.82, 0.9, 1.0, 0.76),
				"spark": Color(0.64, 0.78, 1.0, 0.48),
				"ring": Color(0.64, 0.82, 1.0, 0.54),
			}
		"weak":
			return {
				"core": Color(1.0, 0.96, 0.36, 1.0),
				"spark": Color(1.0, 0.72, 0.18, 0.94),
				"ring": Color(1.0, 0.9, 0.24, 0.7),
			}
	match element:
		"fire":
			return {
				"core": Color(1.0, 0.32, 0.06, 0.95),
				"spark": Color(1.0, 0.54, 0.12, 0.88),
				"ring": Color(1.0, 0.24, 0.06, 0.5),
			}
		"ice":
			return {
				"core": Color(0.68, 0.98, 1.0, 0.94),
				"spark": Color(0.54, 0.9, 1.0, 0.86),
				"ring": Color(0.42, 0.86, 1.0, 0.56),
			}
		"lightning":
			return {
				"core": Color(0.84, 0.98, 1.0, 1.0),
				"spark": Color(0.62, 0.92, 1.0, 0.92),
				"ring": Color(0.58, 0.88, 1.0, 0.62),
			}
		"poison":
			return {
				"core": Color(0.42, 1.0, 0.18, 0.9),
				"spark": Color(0.54, 1.0, 0.22, 0.78),
				"ring": Color(0.26, 1.0, 0.16, 0.5),
			}
		_:
			return {
				"core": Color(1.0, 0.96, 0.78, 0.96),
				"spark": Color(1.0, 0.72, 0.28, 0.86),
				"ring": Color(1.0, 0.86, 0.42, 0.56),
			}

func _spawn_b4_impact_stack(position: Vector2, element: String, power := 1.0, hit_kind := "normal", priority := false) -> void:
	if not _can_spawn_projectile_fx(priority):
		return
	var safe_power := clampf(power, 0.55, 2.5)
	var palette := _impact_palette(element, hit_kind)
	var core: Color = palette.get("core", Color.WHITE)
	var spark: Color = palette.get("spark", core)
	var ring: Color = palette.get("ring", core)
	var life := 0.14 + safe_power * 0.035
	var glow := VfxLib.spawn_glow($ProjectileLayer, position, core, 86.0 * safe_power, life)
	if glow != null:
		_track_transient_fx(glow, "projectile")
	_spawn_impact_core_flash(position, core, 0.18 + safe_power * 0.11, minf(life, 0.22), 3.1 + safe_power, priority)
	if _can_spawn_projectile_fx(priority):
		var burst := VfxLib.spawn_burst(
			$ProjectileLayer,
			position,
			spark,
			_impact_particle_count(element, hit_kind, safe_power),
			_impact_particle_speed(element, hit_kind, safe_power),
			_impact_particle_spread(element, hit_kind),
			minf(life + 0.04, 0.34)
		)
		if burst != null:
			_track_transient_fx(burst, "projectile")
			if burst is Node2D:
				(burst as Node2D).rotation = randf_range(-PI, PI)
	_spawn_impact_shock_ring(position, ring, 48.0 * safe_power, 4.0 + safe_power * 2.0, life, priority)
	match hit_kind:
		"shield", "immune", "phase_evade", "suppressed", "resisted":
			_spawn_vfx_sequence(
				"vfx_hit_immune",
				position,
				0.34 + safe_power * 0.1,
				Color(0.86, 0.96, 1.0, 0.88),
				1.34,
				randf_range(-0.16, 0.16),
				1.06,
				Vector2(0, -6),
				randf_range(-0.18, 0.18),
				priority
			)
			_spawn_impact_fork_lines(position, ring, 5, 72.0 * safe_power, 0.15, 2.2 + safe_power, priority)
		"armor", "armor_pierce":
			_spawn_vfx_sequence(
				"vfx_hit_armor",
				position,
				0.34 + safe_power * 0.1,
				Color(1.0, 0.9, 0.68, 0.92),
				1.34,
				randf_range(-0.2, 0.2),
				1.08,
				Vector2(0, -8),
				randf_range(-0.22, 0.22),
				priority
			)
			_spawn_impact_streaks(position, spark, 5, 66.0 * safe_power, 0.13, 3.2 + safe_power, priority)
		"weak":
			_spawn_vfx_sequence(
				"vfx_hit_weak",
				position,
				0.38 + safe_power * 0.1,
				Color(1.0, 0.98, 0.82, 0.96),
				1.42,
				randf_range(-0.18, 0.18),
				1.1,
				Vector2(0, -12),
				randf_range(-0.24, 0.24),
				true
			)
			_spawn_impact_streaks(position, spark, 5, 66.0 * safe_power, 0.13, 3.2 + safe_power, priority)
		_:
			match element:
				"fire":
					_spawn_vfx_sequence("vfx_hit_fire", position + Vector2(0, -4), 0.38 + safe_power * 0.08, Color(1.0, 0.48, 0.14, 0.78), 1.22, randf_range(-0.18, 0.18), 1.12, Vector2(0, -8), randf_range(-0.22, 0.22), priority)
				"ice":
					_spawn_impact_fork_lines(position, Color(0.76, 1.0, 1.0, 0.72), 6, 58.0 * safe_power, 0.18, 2.6 + safe_power, priority)
					_spawn_impact_cloud(position + Vector2(0, -6), Color(0.58, 0.94, 1.0, 0.22), 7, 0.3, true, priority)
				"lightning":
					_spawn_impact_fork_lines(position, Color(0.82, 0.98, 1.0, 0.86), 7, 78.0 * safe_power, 0.12, 2.8 + safe_power, priority)
				"poison":
					_spawn_impact_cloud(position + Vector2(0, -2), Color(0.38, 1.0, 0.16, 0.32), 10, 0.36, false, priority)
					_spawn_impact_bubbles(position, Color(0.52, 1.0, 0.18, 0.46), 5, 0.32, safe_power, priority)
				_:
					_spawn_impact_streaks(position, Color(1.0, 0.86, 0.42, 0.72), 4, 58.0 * safe_power, 0.12, 3.0 + safe_power, priority)

func _impact_particle_count(element: String, hit_kind: String, power: float) -> int:
	var base := 12
	match element:
		"fire":
			base = 18
		"ice":
			base = 15
		"lightning":
			base = 16
		"poison":
			base = 15
		_:
			base = 14
	match hit_kind:
		"armor", "weak":
			base += 5
		"immune", "phase_evade", "resisted":
			base -= 4
	return clampi(int(round(float(base) * power)), 4, 30)

func _impact_particle_speed(element: String, hit_kind: String, power: float) -> float:
	var speed := 430.0
	match element:
		"fire":
			speed = 440.0
		"ice":
			speed = 320.0
		"lightning":
			speed = 620.0
		"poison":
			speed = 230.0
		_:
			speed = 520.0
	match hit_kind:
		"armor", "weak":
			speed += 120.0
		"immune", "phase_evade", "resisted":
			speed *= 0.7
	return speed * clampf(power, 0.65, 1.8)

func _impact_particle_spread(element: String, hit_kind: String) -> float:
	if hit_kind == "immune" or hit_kind == "phase_evade" or hit_kind == "suppressed" or hit_kind == "resisted":
		return 116.0
	match element:
		"fire":
			return 104.0
		"ice":
			return 86.0
		"lightning":
			return 58.0
		"poison":
			return 132.0
		_:
			return 72.0

func _spawn_impact_core_flash(position: Vector2, color: Color, scale_mult: float, duration: float, intensity: float, priority := false) -> void:
	if not _can_spawn_projectile_fx(priority):
		return
	var core := Sprite2D.new()
	_track_transient_fx(core, "projectile")
	core.name = "B4ImpactShaderCore"
	core.texture = VfxLib.RADIAL_GLOW_TEXTURE
	core.centered = true
	core.global_position = position
	core.scale = Vector2.ONE * scale_mult
	core.z_index = 78
	core.material = _new_muzzle_core_material(color, intensity, 0.86)
	$ProjectileLayer.add_child(core)
	var tween := core.create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(core, "scale", core.scale * 1.85, duration)
	tween.parallel().tween_property(core, "modulate:a", 0.0, duration)
	tween.tween_callback(core.queue_free)

func _spawn_impact_shock_ring(position: Vector2, color: Color, radius: float, width: float, duration: float, priority := false) -> void:
	if not _can_spawn_projectile_fx(priority):
		return
	var root := Node2D.new()
	_track_transient_fx(root, "projectile")
	root.name = "B4ImpactShockRing"
	root.process_mode = Node.PROCESS_MODE_PAUSABLE
	root.global_position = position
	root.z_index = 76
	root.scale = Vector2.ONE * 0.28
	$ProjectileLayer.add_child(root)
	var ring := _make_ring_line(radius, color, width, 64)
	ring.texture = VfxLib.STREAK_TEXTURE
	ring.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	ring.material = _new_muzzle_additive_material()
	root.add_child(ring)
	var tween := root.create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(root, "scale", Vector2.ONE, duration)
	tween.parallel().tween_property(ring, "width", 1.0, duration)
	tween.parallel().tween_property(root, "modulate:a", 0.0, duration)
	tween.tween_callback(root.queue_free)

func _spawn_impact_streaks(position: Vector2, color: Color, count: int, radius: float, duration: float, width: float, priority := false) -> void:
	if not _can_spawn_projectile_fx(priority):
		return
	var root := Node2D.new()
	_track_transient_fx(root, "projectile")
	root.name = "B4ImpactStreaks"
	root.process_mode = Node.PROCESS_MODE_PAUSABLE
	root.global_position = position
	root.z_index = 77
	$ProjectileLayer.add_child(root)
	for i in range(clampi(count, 1, 8)):
		var angle := randf_range(-PI, PI)
		var dir := Vector2(cos(angle), sin(angle))
		var start := dir * randf_range(6.0, 14.0)
		var finish := dir * randf_range(radius * 0.52, radius)
		var line := Line2D.new()
		line.width = width * randf_range(0.72, 1.18)
		line.default_color = color.lightened(randf_range(0.0, 0.2))
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.texture = VfxLib.STREAK_TEXTURE
		line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		line.material = _new_muzzle_additive_material()
		line.points = PackedVector2Array([start, finish])
		root.add_child(line)
	var tween := root.create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(root, "scale", Vector2.ONE * 1.08, duration)
	tween.parallel().tween_property(root, "modulate:a", 0.0, duration)
	tween.tween_callback(root.queue_free)

func _spawn_impact_fork_lines(position: Vector2, color: Color, count: int, radius: float, duration: float, width: float, priority := false) -> void:
	if not _can_spawn_projectile_fx(priority):
		return
	var root := Node2D.new()
	_track_transient_fx(root, "projectile")
	root.name = "B4ImpactForkLines"
	root.process_mode = Node.PROCESS_MODE_PAUSABLE
	root.global_position = position
	root.z_index = 79
	$ProjectileLayer.add_child(root)
	var safe_count := clampi(count, 1, 9)
	for i in range(safe_count):
		var base_angle := TAU * float(i) / float(safe_count) + randf_range(-0.28, 0.28)
		var dir := Vector2(cos(base_angle), sin(base_angle))
		var tangent := Vector2(-dir.y, dir.x)
		var length := radius * randf_range(0.62, 1.08)
		var elbow := dir * length * randf_range(0.35, 0.58) + tangent * randf_range(-18.0, 18.0)
		var end := dir * length + tangent * randf_range(-24.0, 24.0)
		var line := Line2D.new()
		line.width = width * randf_range(0.65, 1.15)
		line.default_color = color.lightened(randf_range(0.0, 0.28))
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.texture = VfxLib.STREAK_TEXTURE
		line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		line.material = _new_muzzle_additive_material()
		line.points = PackedVector2Array([Vector2.ZERO, elbow, end])
		root.add_child(line)
	var tween := root.create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(root, "scale", Vector2.ONE * 1.12, duration)
	tween.parallel().tween_property(root, "modulate:a", 0.0, duration)
	tween.tween_callback(root.queue_free)

func _spawn_impact_cloud(position: Vector2, color: Color, amount: int, duration: float, upward: bool, priority := false) -> void:
	if not _can_spawn_projectile_fx(priority):
		return
	var particles := GPUParticles2D.new()
	particles.name = "B4ImpactCloudParticles"
	particles.process_mode = Node.PROCESS_MODE_PAUSABLE
	particles.one_shot = true
	particles.amount = clampi(amount, 3, 18)
	particles.lifetime = clampf(duration, 0.14, 0.42)
	particles.explosiveness = 1.0
	particles.randomness = 0.82
	particles.local_coords = false
	particles.texture = VfxLib.RADIAL_GLOW_TEXTURE
	particles.material = _new_muzzle_additive_material()
	particles.z_index = 73
	particles.visibility_rect = Rect2(-460.0, -460.0, 920.0, 920.0)
	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	process_material.direction = Vector3(0.0, -1.0 if upward else 0.0, 0.0)
	process_material.spread = 180.0
	process_material.initial_velocity_min = 28.0 if not upward else 44.0
	process_material.initial_velocity_max = 112.0 if not upward else 165.0
	process_material.gravity = Vector3(0.0, -34.0 if upward else 26.0, 0.0)
	process_material.damping_min = 22.0
	process_material.damping_max = 58.0
	process_material.angle_min = -35.0
	process_material.angle_max = 35.0
	process_material.angular_velocity_min = -90.0
	process_material.angular_velocity_max = 90.0
	process_material.scale_min = 0.16
	process_material.scale_max = 0.48
	process_material.scale_curve = _impact_cloud_scale_curve()
	process_material.color_ramp = _impact_color_ramp(color.lightened(0.12), color, Color(color.r, color.g, color.b, 0.0))
	particles.process_material = process_material
	particles.finished.connect(particles.queue_free)
	_track_transient_fx(particles, "projectile")
	$ProjectileLayer.add_child(particles)
	particles.global_position = position
	particles.emitting = true

func _spawn_impact_bubbles(position: Vector2, color: Color, count: int, duration: float, power := 1.0, priority := false) -> void:
	var safe_count := clampi(count, 2, 8)
	for i in range(safe_count):
		if not _can_spawn_projectile_fx(priority):
			break
		var bubble := Sprite2D.new()
		_track_transient_fx(bubble, "projectile")
		bubble.name = "B4PoisonBubble"
		bubble.texture = VfxLib.RADIAL_GLOW_TEXTURE
		bubble.centered = true
		bubble.global_position = position + Vector2(randf_range(-26.0, 26.0), randf_range(-18.0, 16.0))
		bubble.scale = Vector2.ONE * randf_range(0.08, 0.16) * clampf(power, 0.8, 1.7)
		bubble.modulate = color
		bubble.material = _new_muzzle_core_material(color, 2.2, 1.25)
		bubble.z_index = 77
		$ProjectileLayer.add_child(bubble)
		var travel := Vector2(randf_range(-38.0, 38.0), randf_range(-52.0, 18.0))
		var tween := bubble.create_tween()
		tween.set_trans(Tween.TRANS_QUINT)
		tween.set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(bubble, "global_position", bubble.global_position + travel, duration)
		tween.parallel().tween_property(bubble, "scale", bubble.scale * randf_range(1.4, 2.1), duration)
		tween.parallel().tween_property(bubble, "modulate:a", 0.0, duration)
		tween.tween_callback(bubble.queue_free)

func _spawn_impact_heat_haze(position: Vector2, color: Color, duration: float, power := 1.0, priority := false) -> void:
	if not _can_spawn_projectile_fx(priority):
		return
	var haze := Sprite2D.new()
	_track_transient_fx(haze, "projectile")
	haze.name = "B4ImpactHeatHaze"
	haze.texture = VfxLib.RADIAL_GLOW_TEXTURE
	haze.centered = true
	haze.global_position = position
	haze.rotation = randf_range(-0.35, 0.35)
	haze.scale = Vector2(0.42, 0.22) * clampf(power, 0.8, 2.1)
	haze.modulate = color
	haze.material = _new_muzzle_core_material(color, 2.35, 1.65)
	haze.z_index = 72
	$ProjectileLayer.add_child(haze)
	var tween := haze.create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(haze, "scale", haze.scale * Vector2(2.4, 1.75), duration)
	tween.parallel().tween_property(haze, "rotation", haze.rotation + randf_range(-0.12, 0.12), duration)
	tween.parallel().tween_property(haze, "modulate:a", 0.0, duration)
	tween.tween_callback(haze.queue_free)

func _impact_color_ramp(start: Color, mid: Color, finish: Color) -> GradientTexture1D:
	var gradient_resource := Gradient.new()
	gradient_resource.set_offset(0, 0.0)
	gradient_resource.set_color(0, start)
	gradient_resource.set_offset(1, 1.0)
	gradient_resource.set_color(1, finish)
	gradient_resource.add_point(0.38, mid)
	var texture := GradientTexture1D.new()
	texture.gradient = gradient_resource
	return texture

func _impact_cloud_scale_curve() -> CurveTexture:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.12))
	curve.add_point(Vector2(0.32, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	var texture := CurveTexture.new()
	texture.curve = curve
	return texture

func _impact_profile_power(visual_profile: String) -> float:
	match visual_profile:
		"rail":
			return 1.45
		"scatter":
			return 0.78
		"plasma":
			return 1.65
		"heavy":
			return 1.35
		"acid":
			return 1.2
		_:
			return 1.0

func _trigger_impact_feedback(primary: Node, damage: float, visual_profile: String) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var is_boss := _is_boss_node(primary)
	var cooldown := 0.035 if is_boss else 0.055
	if now - last_impact_feedback_at < cooldown:
		return
	last_impact_feedback_at = now
	var profile_boost := 0.0
	match visual_profile:
		"rail":
			profile_boost = 1.2
		"plasma":
			profile_boost = 1.0
		"heavy":
			profile_boost = 0.7
		"scatter":
			profile_boost = -0.2
	var damage_boost := clampf(sqrt(maxf(damage, 0.0)) * 0.14, 0.0, 2.2)
	var intensity := clampf(1.35 + damage_boost + profile_boost, 1.0, 5.8)
	if is_boss:
		intensity *= 1.28
	VfxLib.screen_shake(intensity, 0.045 + minf(intensity, 5.0) * 0.006)
	if hit_stop != null and (is_boss or visual_profile == "rail" or visual_profile == "plasma" or damage >= 32.0):
		hit_stop.pulse(0.026 if not is_boss else 0.04)

func _spawn_split_burst_vfx(origin: Vector2, direction: Vector2, fan: float, count: int, element: String) -> void:
	if not _can_spawn_projectile_fx():
		return
	var dir := _safe_vfx_direction(direction)
	var color := _element_color(element)
	color.a = 0.78
	var hot := color.lightened(0.28)
	hot.a = 0.94
	var glow := VfxLib.spawn_glow($ProjectileLayer, origin, hot, 118.0 + float(count) * 8.0, 0.22)
	if glow != null:
		_track_transient_fx(glow, "projectile")
	_spawn_impact_shock_ring(origin, Color(color.r, color.g, color.b, 0.52), 92.0 + float(count) * 14.0, 6.5, 0.22, false)
	var core_burst := VfxLib.spawn_burst($ProjectileLayer, origin, color, clampi(12 + count * 2, 14, 28), 430.0, 78.0, 0.24)
	if core_burst != null:
		_track_transient_fx(core_burst, "projectile")
		if core_burst is Node2D:
			(core_burst as Node2D).rotation = dir.angle()
	for i in range(mini(count, 7)):
		if not _can_spawn_projectile_fx():
			break
		var offset := lerpf(-fan, fan, 0.5 if count == 1 else float(i) / float(count - 1))
		var shard_dir := dir.rotated(offset).normalized()
		_spawn_muzzle_light_cone(origin, shard_dir, Color(color.r, color.g, color.b, 0.48), 86.0, 14.0, 0.12, 3.0)
		var orb := Sprite2D.new()
		_track_transient_fx(orb, "projectile")
		orb.name = "SplitSkillLightOrb"
		orb.texture = VfxLib.RADIAL_GLOW_TEXTURE
		orb.centered = true
		orb.global_position = origin + shard_dir * 12.0
		orb.rotation = shard_dir.angle()
		orb.scale = Vector2.ONE * 0.12
		orb.modulate = color
		orb.material = _new_muzzle_core_material(hot, 3.2, 0.82)
		orb.z_index = 78
		$ProjectileLayer.add_child(orb)
		var travel := shard_dir * (116.0 + float(i % 3) * 20.0)
		var tween := orb.create_tween()
		tween.set_trans(Tween.TRANS_QUINT)
		tween.set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(orb, "global_position", origin + travel, 0.22)
		tween.parallel().tween_property(orb, "scale", Vector2.ONE * 0.28, 0.22)
		tween.parallel().tween_property(orb, "modulate:a", 0.0, 0.22)
		tween.tween_callback(orb.queue_free)

func _spawn_element_impact_vfx(primary: Node, origin: Vector2, element: String, visual_profile := "") -> void:
	if is_instance_valid(primary):
		primary.set_meta("_recent_impact_vfx_ms", Time.get_ticks_msec())
	var target_position := _impact_anchor(primary, origin)
	match visual_profile:
		"autocannon":
			# The projectile owns the compact directional contact spark. Do not
			# stack the generic radial impact here: an expanding ring makes the
			# level-one ballistic round read as splash damage.
			return
		"rail":
			_spawn_rail_impact_vfx(target_position, origin)
			return
		"scatter":
			_spawn_scatter_impact_vfx(target_position, element)
			return
		"plasma":
			_spawn_plasma_impact_vfx(target_position)
			return
	_spawn_b4_impact_stack(target_position, element, _impact_profile_power(visual_profile), "normal", false)

func _spawn_rail_impact_vfx(target_position: Vector2, hit_origin: Vector2) -> void:
	var muzzle := _weapon_fire_origin()
	var direction := (target_position - muzzle).normalized()
	if direction.length_squared() <= 0.01:
		direction = (target_position - hit_origin).normalized()
	if direction.length_squared() <= 0.01:
		direction = Vector2.UP
	_spawn_b4_impact_stack(target_position, "lightning", 1.45, "normal", true)
	_spawn_weapon_trace(target_position - direction * 72.0, target_position + direction * 18.0, Color(0.78, 1.0, 1.0, 0.82), 13.0, 0.1)
	_spawn_impact_fork_lines(target_position, Color(0.82, 0.98, 1.0, 0.9), 5, 92.0, 0.11, 2.4, true)

func _spawn_scatter_impact_vfx(target_position: Vector2, element: String) -> void:
	var base_color := _element_color(element)
	for i in range(3):
		var offset := Vector2(randf_range(-30.0, 30.0), randf_range(-18.0, 18.0))
		_spawn_b4_impact_stack(target_position + offset, element, 0.62, "normal", false)
	_spawn_impact_streaks(target_position, Color(1.0, 0.78, 0.32, 0.78), 7, 72.0, 0.12, 2.8, false)
	if base_color != Color.WHITE:
		var tint := base_color
		tint.a = 0.46
		_spawn_impact_cloud(target_position, tint, 5, 0.22, true, false)

func _spawn_plasma_impact_vfx(target_position: Vector2) -> void:
	_spawn_b4_impact_stack(target_position, "fire", 1.55, "normal", true)
	_spawn_impact_core_flash(target_position + Vector2(0, -4), Color(1.0, 0.48, 1.0, 0.96), 0.42, 0.2, 4.8, true)
	_spawn_impact_shock_ring(target_position, Color(1.0, 0.38, 1.0, 0.64), 96.0, 8.0, 0.2, true)
	_spawn_impact_cloud(target_position, Color(1.0, 0.32, 0.92, 0.28), 10, 0.32, true, true)

func _spawn_chain_flash(origin: Vector2, primary: Node) -> void:
	_spawn_b4_impact_stack(origin, "lightning", 0.72, "normal", false)
	_spawn_impact_fork_lines(origin, Color(0.82, 0.98, 1.0, 0.78), 5, 82.0, 0.13, 2.4, false)
	var nearest: Node2D
	var best_dist := 999999.0
	for enemy in $EnemyLayer.get_children():
		if enemy == primary or not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		var dist := origin.distance_squared_to(enemy.global_position)
		if dist < best_dist and dist < 240.0 * 240.0:
			best_dist = dist
			nearest = enemy
	if nearest == null:
		return
	_spawn_chain_arc(origin, nearest.global_position, "lightning")
	_spawn_impact_core_flash(nearest.global_position + Vector2(0, -36), Color(0.82, 0.98, 1.0, 0.84), 0.22, 0.12, 4.2, false)

func _spawn_chain_arc(start: Vector2, end: Vector2, element := "lightning") -> void:
	if not _can_spawn_projectile_fx():
		return
	var color := _element_color(element)
	color.a = 0.86
	var hot := Color(0.9, 1.0, 1.0, 0.96) if element == "lightning" else color.lightened(0.3)
	var vector := end - start
	var length := vector.length()
	if length <= 8.0:
		return
	var dir := vector / length
	var tangent := Vector2(-dir.y, dir.x)
	var root := Node2D.new()
	_track_transient_fx(root, "projectile")
	root.name = "ChainSkillForkedArc"
	root.process_mode = Node.PROCESS_MODE_PAUSABLE
	root.global_position = start
	root.z_index = 80
	$ProjectileLayer.add_child(root)
	for lane in range(2):
		var line := Line2D.new()
		line.width = 4.2 - float(lane) * 1.4
		line.default_color = Color(hot.r, hot.g, hot.b, hot.a * (0.84 - float(lane) * 0.22))
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.texture = VfxLib.STREAK_TEXTURE
		line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		line.material = _new_muzzle_additive_material()
		var points := PackedVector2Array()
		points.append(Vector2.ZERO)
		var segments := 4
		for i in range(1, segments):
			var t := float(i) / float(segments)
			var jitter := tangent * randf_range(-28.0, 28.0) * (1.0 - absf(t - 0.5) * 0.7)
			points.append(vector * t + jitter)
		points.append(vector)
		line.points = points
		root.add_child(line)
	for i in range(3):
		var branch_t := randf_range(0.18, 0.78)
		var branch_start := vector * branch_t + tangent * randf_range(-16.0, 16.0)
		var branch_dir := dir.rotated(randf_range(-0.9, 0.9))
		var branch := Line2D.new()
		branch.width = randf_range(1.4, 2.4)
		branch.default_color = Color(0.84, 0.98, 1.0, 0.58)
		branch.joint_mode = Line2D.LINE_JOINT_ROUND
		branch.begin_cap_mode = Line2D.LINE_CAP_ROUND
		branch.end_cap_mode = Line2D.LINE_CAP_ROUND
		branch.texture = VfxLib.STREAK_TEXTURE
		branch.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		branch.material = _new_muzzle_additive_material()
		branch.points = PackedVector2Array([branch_start, branch_start + branch_dir * randf_range(34.0, 72.0)])
		root.add_child(branch)
	var start_glow := VfxLib.spawn_glow($ProjectileLayer, start, hot, 58.0, 0.13)
	if start_glow != null:
		_track_transient_fx(start_glow, "projectile")
	var end_glow := VfxLib.spawn_glow($ProjectileLayer, end + Vector2(0, -32), hot, 76.0, 0.14)
	if end_glow != null:
		_track_transient_fx(end_glow, "projectile")
	var tween := root.create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(root, "scale", Vector2(1.02, 0.72), 0.13)
	tween.parallel().tween_property(root, "modulate:a", 0.0, 0.13)
	tween.tween_callback(root.queue_free)

func _spawn_radial_vfx(origin: Vector2, radius: float, color: Color) -> void:
	var safe_radius := clampf(radius, 42.0, 360.0)
	var element := "fire" if color.r >= color.g else "poison"
	var power := clampf(safe_radius / 132.0, 0.72, 2.1)
	var glow_color := Color(color.r, color.g, color.b, minf(color.a + 0.24, 0.76))
	var glow := VfxLib.spawn_glow($ProjectileLayer, origin, glow_color, safe_radius * 0.9, 0.28)
	if glow != null:
		_track_transient_fx(glow, "projectile")
	_spawn_b4_impact_stack(origin, element, power, "normal", safe_radius > 180.0)
	_spawn_impact_shock_ring(origin, Color(color.r, color.g, color.b, minf(color.a + 0.2, 0.68)), safe_radius, 7.0, 0.26, safe_radius > 180.0)
	_spawn_impact_streaks(origin, Color(color.r, color.g, color.b, minf(color.a + 0.18, 0.7)), 6, safe_radius * 0.72, 0.2, 3.4, safe_radius > 180.0)
	if element == "fire":
		_spawn_vfx_sequence("vfx_explosion_fire", origin + Vector2(0, -10), clampf(safe_radius / 250.0, 0.58, 1.45), Color(1.0, 0.46, 0.12, minf(color.a + 0.28, 0.86)), 1.08, randf_range(-0.18, 0.18), 1.12, Vector2(0, -14), randf_range(-0.24, 0.24), safe_radius > 180.0)
	else:
		_spawn_impact_cloud(origin, Color(color.r, color.g, color.b, minf(color.a, 0.34)), 14 if element == "poison" else 10, 0.38, element != "poison", safe_radius > 180.0)

func _spawn_hit_layer_vfx(position: Vector2, element: String, weak_hit: bool, hit_kind: String) -> void:
	var kind := hit_kind
	var power := 0.78
	match hit_kind:
		"armor":
			power = 1.05
		"armor_pierce":
			power = 1.18
		"shield":
			power = 1.12
		"immune", "phase_evade", "resisted", "suppressed":
			power = 0.88
		"weak":
			power = 1.24
		_:
			kind = "normal"
	var anchor := position + Vector2(randf_range(-16.0, 16.0), randf_range(-46.0, -18.0))
	_spawn_b4_impact_stack(anchor, element, power, kind, weak_hit or kind != "normal")
	if weak_hit:
		_spawn_b4_impact_stack(position + Vector2(0, -44), element, 1.18, "weak", true)
	if hit_kind == "armor" or hit_kind == "armor_pierce" or hit_kind == "shield" or hit_kind == "immune" or hit_kind == "resisted" or hit_kind == "suppressed":
		var palette := _impact_palette(element, kind)
		var ring: Color = palette.get("ring", Color.WHITE)
		_spawn_impact_shock_ring(position + Vector2(0, -36), ring, 74.0, 5.0, 0.18, true)

func _spawn_death_element_vfx(position: Vector2, element: String, is_boss: bool) -> void:
	var scale := 1.0 if not is_boss else 2.05
	_spawn_zombie_blood_pool(position, is_boss)
	var authored_death_sequence := "vfx_death_physical"
	var authored_tint := Color(1.0, 0.9, 0.72, 0.92)
	match element:
		"fire":
			authored_death_sequence = "vfx_death_fire"
			authored_tint = Color(1.0, 0.72, 0.38, 0.94)
		"ice":
			authored_death_sequence = "vfx_death_ice"
			authored_tint = Color(0.78, 0.96, 1.0, 0.94)
		"lightning":
			authored_death_sequence = "vfx_death_energy"
			authored_tint = Color(0.7, 0.94, 1.0, 0.94)
		"poison":
			authored_death_sequence = "vfx_death_energy"
			authored_tint = Color(0.62, 1.0, 0.72, 0.92)
	_spawn_vfx_sequence(
		authored_death_sequence,
		position + Vector2(0, -44 if not is_boss else -88),
		0.52 if not is_boss else 1.05,
		authored_tint,
		1.14,
		randf_range(-0.12, 0.12),
		1.12,
		Vector2(0, -18 if not is_boss else -30),
		randf_range(-0.16, 0.16),
		is_boss
	)
	if element == "fire" and not is_boss:
		_spawn_centered_fire_death_vfx(position)
		return
	_spawn_b4_impact_stack(position + Vector2(0, -38 if not is_boss else -78), element, scale, "weak" if is_boss else "normal", is_boss)
	match element:
		"fire":
			if is_boss:
				_spawn_vfx_sequence("vfx_explosion_fire", position + Vector2(0, -82), 1.24, Color(1.0, 0.42, 0.12, 0.82), 1.0, randf_range(-0.18, 0.18), 1.12, Vector2(0, -22), randf_range(-0.24, 0.24), true)
		"ice":
			_spawn_impact_fork_lines(position + Vector2(0, -42 if not is_boss else -86), Color(0.76, 1.0, 1.0, 0.78), 7 if not is_boss else 9, 76.0 * scale, 0.24, 3.0, is_boss)
			_spawn_impact_cloud(position + Vector2(0, -38 if not is_boss else -82), Color(0.56, 0.92, 1.0, 0.24), 10 if not is_boss else 16, 0.4, true, is_boss)
			_spawn_death_shards(position, Color(0.64, 0.92, 1.0, 0.8), is_boss)
		"lightning":
			_spawn_impact_fork_lines(position + Vector2(0, -46 if not is_boss else -92), Color(0.82, 0.98, 1.0, 0.9), 8 if not is_boss else 9, 96.0 * scale, 0.16, 3.2, is_boss)
			_spawn_death_shards(position, Color(0.72, 0.96, 1.0, 0.82), is_boss)
		"poison":
			_spawn_impact_cloud(position + Vector2(0, -26 if not is_boss else -64), Color(0.36, 1.0, 0.16, 0.36), 14 if not is_boss else 18, 0.42, false, is_boss)
			_spawn_impact_bubbles(position + Vector2(0, -30 if not is_boss else -70), Color(0.52, 1.0, 0.16, 0.5), 6 if not is_boss else 8, 0.42, scale, is_boss)
			_spawn_impact_shock_ring(position, Color(0.36, 1.0, 0.16, 0.42), 104.0 * scale, 6.0, 0.34, is_boss)
		_:
			_spawn_impact_streaks(position + Vector2(0, -36 if not is_boss else -76), Color(1.0, 0.84, 0.42, 0.76), 7 if not is_boss else 8, 86.0 * scale, 0.18, 3.5, is_boss)
			_spawn_death_shards(position, Color(1.0, 0.86, 0.58, 0.62), is_boss)
	if is_boss:
		_show_screen_flash(Color(1.0, 0.78, 0.28, 0.16), 0.32)

func _spawn_centered_fire_death_vfx(position: Vector2) -> void:
	var anchor := position + Vector2(0, -38)
	var glow := VfxLib.spawn_glow($ProjectileLayer, anchor, Color(1.0, 0.42, 0.1, 0.58), 112.0, 0.24)
	if glow != null:
		_track_transient_fx(glow, "projectile")
	_spawn_impact_core_flash(anchor, Color(1.0, 0.5, 0.16, 0.78), 0.42, 0.16, 4.2, false)
	_spawn_vfx_sequence("vfx_hit_fire", anchor, 0.34, Color(1.0, 0.5, 0.16, 0.58), 1.36, 0.0, 0.94, Vector2(0, -2), 0.0, false)
	_spawn_impact_shock_ring(anchor + Vector2(0, 2), Color(1.0, 0.54, 0.16, 0.42), 64.0, 3.6, 0.16, false)
	_spawn_impact_cloud(anchor + Vector2(0, -4), Color(1.0, 0.38, 0.1, 0.26), 7, 0.24, true, false)
	_spawn_death_shards(position, Color(1.0, 0.62, 0.24, 0.66), false)

func _spawn_zombie_blood_pool(position: Vector2, is_boss: bool) -> void:
	if not _can_spawn_projectile_fx(is_boss):
		return
	var scale := 1.0 if not is_boss else 1.9
	var residue_color := Color(0.26, 1.0, 0.16, 0.26)
	var residue := VfxLib.spawn_glow($ProjectileLayer, position + Vector2(randf_range(-8.0, 8.0), randf_range(18.0, 32.0)), residue_color, 118.0 * scale, 0.5)
	if residue != null:
		_track_transient_fx(residue, "projectile")
		if residue is Node2D:
			(residue as Node2D).z_index = -4
	_spawn_impact_cloud(position + Vector2(0, 18), Color(0.34, 1.0, 0.2, 0.24), 8 if not is_boss else 14, 0.42, false, is_boss)
	_spawn_impact_bubbles(position + Vector2(0, 12), Color(0.46, 1.0, 0.18, 0.34), 3 if not is_boss else 6, 0.46, scale, is_boss)

func _spawn_death_shards(position: Vector2, color: Color, is_boss: bool) -> void:
	if not _can_spawn_projectile_fx(is_boss):
		return
	var count := 8 if not is_boss else 14
	for i in range(count):
		if not _can_spawn_projectile_fx(is_boss):
			break
		var shard := Sprite2D.new()
		_track_transient_fx(shard, "projectile")
		shard.name = "B4DeathShard"
		shard.texture = VfxLib.STREAK_TEXTURE
		shard.centered = true
		shard.global_position = position + Vector2(randf_range(-18.0, 18.0), randf_range(-52.0, -16.0))
		shard.rotation = randf_range(-1.0, 1.0)
		shard.scale = Vector2(randf_range(0.18, 0.3), randf_range(0.035, 0.07)) * (1.35 if is_boss else 1.0)
		shard.modulate = color
		shard.material = _new_muzzle_core_material(color, 2.6, 1.1)
		shard.z_index = 77
		$ProjectileLayer.add_child(shard)
		var travel := Vector2(randf_range(-85.0, 85.0), randf_range(-120.0, -35.0)) * (1.35 if is_boss else 1.0)
		var tween := shard.create_tween()
		tween.parallel().tween_property(shard, "global_position", shard.global_position + travel, 0.26)
		tween.parallel().tween_property(shard, "rotation", shard.rotation + randf_range(-1.2, 1.2), 0.26)
		tween.parallel().tween_property(shard, "scale", shard.scale * 0.32, 0.26)
		tween.parallel().tween_property(shard, "modulate:a", 0.0, 0.26)
		tween.tween_callback(shard.queue_free)

# VFX tint only — deliberately brighter/more saturated than UiKit.element_color so
# effects pop in combat. Hue/semantics stay aligned with the UI coding. For any UI
# label / weakness coding use UiKit.element_color instead (single source).
func _element_color(element: String) -> Color:
	match element:
		"fire":
			return Color(1.0, 0.46, 0.16, 1.0)
		"ice":
			return Color(0.55, 0.9, 1.0, 1.0)
		"lightning":
			return Color(1.0, 0.9, 0.22, 1.0)
		"poison":
			return Color(0.5, 1.0, 0.28, 1.0)
		_:
			return Color(1.0, 0.96, 0.82, 1.0)

func _spawn_low_hp_pulse() -> void:
	low_hp_pulse = Control.new()
	low_hp_pulse.name = "LowHpPulse"
	low_hp_pulse.position = Vector2.ZERO
	low_hp_pulse.size = Vector2(1080, 1920.0 + bottom_dock_shift)
	low_hp_pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Hud.add_child(low_hp_pulse)
	for spec in [
		{"name": "Top", "pos": Vector2(0, 0), "size": Vector2(1080, 120)},
		{"name": "Bottom", "pos": Vector2(0, 1760.0 + bottom_dock_shift), "size": Vector2(1080, 160)},
		{"name": "Left", "pos": Vector2(0, 0), "size": Vector2(82, 1920.0 + bottom_dock_shift)},
		{"name": "Right", "pos": Vector2(998, 0), "size": Vector2(82, 1920.0 + bottom_dock_shift)}
	]:
		var edge := TextureRect.new()
		edge.name = str(spec.get("name", "Edge"))
		edge.texture = load("res://assets/production/sprites/vfx/vfx_threat_warning.png")
		edge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		edge.stretch_mode = TextureRect.STRETCH_SCALE
		edge.position = spec.get("pos", Vector2.ZERO)
		edge.size = spec.get("size", Vector2.ZERO)
		edge.modulate = Color(1.0, 0.04, 0.0, 0.0)
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		low_hp_pulse.add_child(edge)

func _spawn_feedback_managers() -> void:
	# Hit stop / hit pause
	hit_stop = preload("res://core/feedback/hit_stop.gd").new()
	hit_stop.name = "HitStop"
	hit_stop.process_mode = Node.PROCESS_MODE_PAUSABLE
	hit_stop.target_scale = battle_speed
	add_child(hit_stop)
	# Screen shake
	screen_shake_node = preload("res://core/feedback/screen_shake.gd").new()
	screen_shake_node.name = "ScreenShake"
	screen_shake_node.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(screen_shake_node)
	screen_shake_node.bind(self)
	VfxLib.bind_screen_shake(screen_shake_node)
	# Damage number layer
	damage_numbers = preload("res://gameplay/hud/damage_number_layer.gd").new()
	damage_numbers.name = "DamageNumbers"
	$ProjectileLayer.add_child(damage_numbers)
	# Off-screen indicators
	off_screen_indicators = preload("res://gameplay/hud/off_screen_indicator.gd").new()
	off_screen_indicators.name = "OffScreenIndicators"
	off_screen_indicators.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(off_screen_indicators)
	# Gold fly
	gold_fly = preload("res://gameplay/hud/gold_fly.gd").new()
	gold_fly.name = "GoldFly"
	gold_fly.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(gold_fly)
	gold_fly.bind(self, $Hud/BottomBar/GoldLabel, $Hud/BottomBar/GoldIcon)
	# Combo HUD
	if has_node("Hud/ComboHud"):
		combo_hud = $Hud/ComboHud
		if combo_hud is Control:
			combo_hud.visible = false
			(combo_hud as Control).reset()

func _update_low_hp_pulse(hp_pct: float) -> void:
	if low_hp_pulse == null:
		return
	if hp_pct > 0.32:
		_set_low_hp_pulse_alpha(0.0)
		return
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 180.0)
	_set_low_hp_pulse_alpha((0.035 + (0.32 - hp_pct) * 0.12) * pulse)

func _set_low_hp_pulse_alpha(alpha: float) -> void:
	if low_hp_pulse == null:
		return
	for child in low_hp_pulse.get_children():
		if child is CanvasItem:
			var edge := child as CanvasItem
			edge.modulate.a = clampf(alpha, 0.0, 0.07)

func _spawn_spit_attack_vfx(source: Node, target_position: Vector2) -> void:
	if not is_instance_valid(source):
		return
	if not _can_spawn_projectile_fx():
		return
	var spit := Sprite2D.new()
	_track_transient_fx(spit, "projectile")
	spit.texture = load("res://assets/production/sprites/projectiles/proj_acid_spit.png")
	spit.global_position = source.global_position + Vector2(0, -34)
	spit.rotation = (target_position - spit.global_position).angle()
	spit.scale = Vector2(0.42, 0.42)
	spit.modulate = Color(0.58, 1.0, 0.26, 0.95)
	$ProjectileLayer.add_child(spit)
	var tween := spit.create_tween()
	tween.parallel().tween_property(spit, "global_position", target_position, 0.22)
	tween.parallel().tween_property(spit, "scale", Vector2(0.62, 0.62), 0.22)
	tween.tween_callback(func() -> void:
		_spawn_attack_sprite("res://assets/production/sprites/vfx/vfx_poison_cloud.png", target_position, Color(0.48, 1.0, 0.24, 0.68), 0.72, 0.36)
		spit.queue_free()
	)

func _spawn_boss_attack_vfx(source: Node, label: String, color: Color, impact := Vector2.ZERO) -> void:
	if not is_instance_valid(source):
		return
	var element := _enemy_cast_element(label)
	var is_boss := bool(source.boss)
	if impact == Vector2.ZERO:
		impact = _base_damage_impact_position(source.global_position.x)
	var source_sequence := "vfx_enemy_skill_%s" % str(source.mechanic)
	var source_rotation := _directional_vfx_rotation(
		source_sequence,
		impact - source.global_position,
		randf_range(-0.12, 0.12)
	)
	_spawn_vfx_sequence(
		source_sequence,
		source.global_position + Vector2(0, -76),
		1.22 if is_boss else 0.82,
		Color(1.0, 1.0, 1.0, 0.94),
		1.08,
		source_rotation,
		1.08,
		Vector2(0, -14),
		randf_range(-0.16, 0.16),
		true
	)
	# 起手炮口/聚能闪光（在施法者身上）
	_spawn_attack_sprite(_vfx_path("muzzle", element), source.global_position + Vector2(0, -84), Color(color.r, color.g, color.b, 0.9), 1.5 if is_boss else 1.05, 0.34)
	# 一颗能量弹从施法者飞向基地防线，落地炸开——让“掉血”有清晰的来龙去脉
	_spawn_enemy_cast_bolt(source.global_position + Vector2(0, -40), impact, color, element, is_boss)

# 敌方技能：识别元素（按飘字标签），用于选弹体/命中特效
func _enemy_cast_element(label: String) -> String:
	if label.contains("熔火") or label.contains("火") or label.contains("焚"):
		return "fire"
	if label.contains("寒") or label.contains("冰") or label.contains("霜"):
		return "ice"
	if label.contains("雷") or label.contains("电"):
		return "lightning"
	if label.contains("腐") or label.contains("毒"):
		return "poison"
	return "physical"

func _enemy_proj_path(element: String) -> String:
	var p := "res://assets/production/sprites/projectiles/proj_bullet_%s.png" % element
	if ResourceLoader.exists(p):
		return p
	return "res://assets/production/sprites/projectiles/proj_bullet_physical.png"

func _enemy_impact_sequence(element: String) -> String:
	match element:
		"fire":
			return "vfx_explosion_fire"
		"ice":
			return "vfx_freeze"
		"lightning":
			return "vfx_hit_lightning"
		"poison":
			return "vfx_poison_cloud"
		_:
			return "vfx_hit_physical"

# 敌方施法弹：加法发光弹体 + 拉长拖尾，飞向目标后炸开
func _spawn_enemy_cast_bolt(origin: Vector2, target: Vector2, color: Color, element: String, is_boss: bool) -> void:
	if not _can_spawn_projectile_fx(true):
		_spawn_enemy_cast_impact(target, color, element, is_boss)
		return
	var bolt := Sprite2D.new()
	_track_transient_fx(bolt, "projectile")
	bolt.texture = load(_enemy_proj_path(element)) as Texture2D
	bolt.global_position = origin
	bolt.rotation = (target - origin).angle()
	bolt.scale = Vector2(0.72, 0.72) if is_boss else Vector2(0.5, 0.5)
	bolt.modulate = Color(color.r, color.g, color.b, 1.0)
	bolt.z_index = 26
	(bolt as CanvasItem).material = VfxLib._new_additive_material()
	var streak := Sprite2D.new()
	streak.texture = load("res://assets/production/sprites/vfx/vfx_input_streak.png") as Texture2D
	streak.position = Vector2(-52, 0)  # 弹体本地 +x 为前进方向，拖尾拖在后面
	streak.scale = Vector2(1.6, 0.55) if is_boss else Vector2(1.2, 0.42)
	streak.modulate = Color(color.r, color.g, color.b, 0.62)
	(streak as CanvasItem).material = VfxLib._new_additive_material()
	bolt.add_child(streak)
	$ProjectileLayer.add_child(bolt)
	var dur := 0.30 if is_boss else 0.24
	var tween := bolt.create_tween()
	tween.parallel().tween_property(bolt, "global_position", target, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(bolt, "scale", bolt.scale * 1.18, dur)
	tween.tween_callback(func() -> void:
		_spawn_enemy_cast_impact(target, color, element, is_boss)
		bolt.queue_free()
	)

func _spawn_enemy_cast_impact(target: Vector2, color: Color, element: String, is_boss: bool) -> void:
	var seq := _enemy_impact_sequence(element)
	var fx := _spawn_vfx_sequence(seq, target, 1.35 if is_boss else 0.92, Color(color.r, color.g, color.b, 0.96), 1.0, randf_range(-0.3, 0.3), 1.16, Vector2(0, -12), randf_range(-0.3, 0.3), true)
	if fx == null:
		_spawn_attack_sprite(_attack_vfx_path(element), target, color, 1.2 if is_boss else 0.9, 0.3)
		_spawn_attack_ring(target, 300.0 if is_boss else 190.0, color, 0.3)
	if is_boss:
		_shake_hud(7.0, 0.2)

func _spawn_enemy_attack_vfx(source: Node, kind: String, target_position: Vector2, travel_direction := Vector2.ZERO) -> void:
	if not is_instance_valid(source):
		return
	var color := _attack_color_for_mechanic(kind)
	var is_boss_source: bool = bool(source.boss)
	var sequence_id := "vfx_enemy_skill_%s" % kind
	var rotation := _directional_vfx_rotation(
		sequence_id,
		travel_direction,
		randf_range(-0.15, 0.15)
	)
	var spin := 0.0 if DIRECTIONAL_VFX_SOURCE_FORWARD.has(sequence_id) else randf_range(-0.2, 0.2)
	var fx := _spawn_vfx_sequence(sequence_id, target_position, 1.3 if is_boss_source else 0.9, Color(color.r, color.g, color.b, 0.94), 1.0, rotation, 1.12, Vector2(0, -10), spin, true)
	if kind == "enrage" and fx is Node2D:
		# The rendered molten claw corona is a body state, not a foreground
		# explosion. Parent it behind its owner so neither the battlefield nor
		# sibling ordering can hide the aura or the zombie silhouette.
		var fx_position := (fx as Node2D).global_position
		fx.reparent(source)
		(fx as Node2D).global_position = fx_position
		(source as CanvasItem).z_index = maxi((source as CanvasItem).z_index, 1)
		(fx as CanvasItem).z_as_relative = false
		(fx as CanvasItem).z_index = 0
	if fx == null:
		var path := _attack_vfx_path(kind)
		_spawn_attack_sprite(path, target_position, color, 0.66 if not is_boss_source else 1.12, 0.32)
		match kind:
			"summon", "spawn_minions":
				_spawn_attack_ring(target_position, 72.0, color, 0.22)
			"phase", "phase_shift":
				_spawn_attack_ring(target_position, 115.0, color, 0.2)
			"runner_dash", "leap_strike", "charge":
				_spawn_attack_ring(target_position, 120.0, color, 0.22)
			"buff_aura", "shield_aura", "ward", "regen", "mutate", "enrage":
				_spawn_attack_ring(target_position, 138.0, color, 0.24)
			"explode_on_death", "juggernaut":
				_spawn_attack_ring(target_position, 185.0, color, 0.28)
			"toxic_cloud":
				_spawn_attack_ring(target_position, 225.0, color, 0.32)

func _directional_vfx_rotation(sequence_id: String, travel_direction: Vector2, fallback_rotation := 0.0) -> float:
	if not DIRECTIONAL_VFX_SOURCE_FORWARD.has(sequence_id):
		return fallback_rotation
	var direction := travel_direction
	if direction.length_squared() <= 0.0001:
		# Deterministic preview/default for enemy movement skills: every enemy
		# advances from the top of the field toward the bottom base line.
		direction = Vector2.DOWN
	return direction.angle() - float(DIRECTIONAL_VFX_SOURCE_FORWARD[sequence_id])

func _on_enemy_base_attack_started(enemy: Node, profile: Dictionary) -> void:
	if not is_instance_valid(enemy):
		return
	if not bool(enemy.get("boss")):
		_play_zombie_base_attack_sfx(enemy)
		return
	if profile.is_empty():
		return
	var element := _boss_attack_element(profile, 0)
	var color := _boss_attack_color(profile, element, 0)
	var origin: Vector2 = (enemy as Node2D).global_position + Vector2(0, -86)
	var target := _boss_attack_target(enemy, profile, 0)
	var cast_sequence := str(profile.get("cast_sequence", "vfx_boss_phase"))
	var cast_rotation := _directional_vfx_rotation(
		cast_sequence,
		target - origin,
		randf_range(-0.16, 0.16)
	)
	_spawn_vfx_sequence(
		cast_sequence,
		origin,
		0.72,
		Color(color.r, color.g, color.b, 0.86),
		0.88,
		cast_rotation,
		1.12,
		Vector2(0, -8),
		randf_range(-0.16, 0.16),
		true
	)
	var telegraph_duration := maxf(
		0.18,
		float(profile.get("windup", 0.48)) + float(profile.get("travel_time", 0.0))
	)
	_spawn_boss_attack_telegraph(target, color, telegraph_duration)
	var last_label_at := float(enemy.get_meta("boss_base_attack_label_at", -99.0))
	var now := Time.get_ticks_msec() / 1000.0
	if now - last_label_at >= 4.0:
		enemy.set_meta("boss_base_attack_label_at", now)
		_spawn_float_text(
			enemy.global_position + Vector2(-180, -218),
			str(profile.get("label", "攻城")),
			Color(color.r, color.g, color.b, 1.0),
			true,
			23,
			360.0
		)

func _zombie_base_attack_sfx(enemy: Node) -> String:
	if enemy == null or not is_instance_valid(enemy):
		return ""
	var attack_profile_var: Variant = enemy.get("attack_animation_profile")
	var attack_profile: Dictionary = attack_profile_var if attack_profile_var is Dictionary else {}
	var mode := str(attack_profile.get("mode", ""))
	match mode:
		"rapid_claw", "claw_combo":
			return "enemy_attack_fast_claw"
		"low_bite":
			return "enemy_attack_bite"
		"heavy_slam", "shoulder_ram", "shield_bash", "piston_slam", "wedge_ram", "triple_maul", "mutant_hook":
			return "enemy_attack_heavy_slam"
		"core_blast":
			return "enemy_attack_blast"
		"acid_spit", "corrosion_burst", "regen_hook":
			return "enemy_attack_corrosion"
		"sonic_burst", "ritual_strike", "ward_pulse":
			return "enemy_attack_support"
		"claw_drag", "leap_rake", "phase_slash":
			return "enemy_attack_claw"
		_:
			return "enemy_attack_claw"

func _play_zombie_base_attack_sfx(enemy: Node) -> void:
	var sfx_id := _zombie_base_attack_sfx(enemy)
	if not sfx_id.is_empty():
		# This is the attacker's motion/material layer. The separate
		# enemy_breach cue is reserved for actual barricade contact and interrupts
		# any remaining wind-up tail instead of stacking over it.
		AudioManager.play_enemy_sfx(sfx_id, -9.5, 0.055)

func _boss_attack_motion_sfx(mode: String) -> String:
	# The Void Phantom's authored dash_combo is also a visible phase movement.
	# Give that motion the same air-cut identity before its separate strike and
	# real barricade-contact layers resolve.
	return "zombie_phantom" if mode == "dash_combo" else ""

func _on_enemy_base_attack_visual_hit(enemy: Node, profile: Dictionary, hit_index: int, hit_count: int) -> void:
	if not is_instance_valid(enemy) or profile.is_empty():
		return
	var element := _boss_attack_element(profile, hit_index)
	var color := _boss_attack_color(profile, element, hit_index)
	var target := _boss_attack_target(enemy, profile, hit_index)
	var mode := str(profile.get("mode", "melee_heavy"))
	var motion_sfx_id := _boss_attack_motion_sfx(mode)
	if hit_index == 0 and not motion_sfx_id.is_empty():
		AudioManager.play_enemy_sfx(motion_sfx_id, -7.0, 0.02)
	match mode:
		"ranged_volley":
			_spawn_boss_siege_projectile(enemy, target, profile, element, color, hit_index, hit_count)
		"channel":
			_spawn_boss_channel_beam(enemy, target, profile, element, color, hit_index, hit_count)
		"dash_combo":
			_spawn_boss_dash_afterimage(enemy, target, color)
			_spawn_boss_profile_impact(target, profile, element, color, hit_index, hit_count)
		_:
			_spawn_boss_profile_impact(target, profile, element, color, hit_index, hit_count)

func _boss_attack_element(profile: Dictionary, hit_index: int) -> String:
	var hit_elements_var: Variant = profile.get("hit_elements", [])
	if hit_elements_var is Array and not (hit_elements_var as Array).is_empty():
		var hit_elements: Array = hit_elements_var
		return str(hit_elements[hit_index % hit_elements.size()])
	return str(profile.get("element", "physical"))

func _boss_attack_color(profile: Dictionary, element: String, hit_index: int) -> Color:
	var hit_colors_var: Variant = profile.get("hit_colors", [])
	if hit_colors_var is Array and not (hit_colors_var as Array).is_empty():
		var hit_colors: Array = hit_colors_var
		return Color.from_string(str(hit_colors[hit_index % hit_colors.size()]), Color.WHITE)
	match element:
		"fire":
			return Color(1.0, 0.34, 0.08, 0.96)
		"ice":
			return Color(0.38, 0.86, 1.0, 0.96)
		"lightning":
			return Color(0.52, 0.9, 1.0, 0.98)
		"poison":
			return Color(0.42, 1.0, 0.22, 0.94)
		_:
			return Color(1.0, 0.68, 0.34, 0.96)

func _boss_attack_target(enemy: Node, profile: Dictionary, hit_index: int) -> Vector2:
	var hit_count := maxi(1, int(profile.get("hits", 1)))
	var center_offset := float(hit_index) - float(hit_count - 1) * 0.5
	var spread := 58.0
	match str(profile.get("projectile_style", "none")):
		"lob":
			spread = 78.0
		"beam":
			spread = 42.0
		"slash":
			spread = 50.0
		"prism":
			spread = 42.0
		_:
			pass
	return _base_damage_impact_position(float(enemy.global_position.x) + center_offset * spread)

func _spawn_boss_attack_telegraph(target: Vector2, color: Color, duration: float) -> void:
	if not _can_spawn_projectile_fx(true):
		return
	var telegraph := Sprite2D.new()
	_track_transient_fx(telegraph, "projectile")
	telegraph.texture = load("res://assets/production/sprites/vfx/vfx_target_lock.png") as Texture2D
	telegraph.global_position = target
	telegraph.scale = Vector2.ONE * 0.52
	telegraph.modulate = Color(color.r, color.g, color.b, 0.42)
	telegraph.z_index = 21
	(telegraph as CanvasItem).material = VfxLib._new_additive_material()
	$ProjectileLayer.add_child(telegraph)
	var tween := telegraph.create_tween()
	tween.parallel().tween_property(telegraph, "scale", Vector2.ONE * 0.76, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(telegraph, "rotation", TAU * 0.34, duration)
	tween.parallel().tween_property(telegraph, "modulate:a", 0.08, duration)
	tween.tween_callback(telegraph.queue_free)

func _spawn_boss_siege_projectile(enemy: Node, target: Vector2, profile: Dictionary, element: String, color: Color, hit_index: int, hit_count: int) -> void:
	if not is_instance_valid(enemy):
		return
	if not _can_spawn_projectile_fx(true):
		_spawn_boss_profile_impact(target, profile, element, color, hit_index, hit_count)
		return
	var origin: Vector2 = (enemy as Node2D).global_position + Vector2(0, -84)
	var projectile := Sprite2D.new()
	_track_transient_fx(projectile, "projectile")
	projectile.texture = load(_enemy_proj_path(element)) as Texture2D
	projectile.global_position = origin
	projectile.rotation = (target - origin).angle()
	var style := str(profile.get("projectile_style", "orb"))
	var projectile_scale := 0.88
	if style == "shard":
		projectile_scale = 1.02
	elif style == "lob":
		projectile_scale = 1.12
	elif style == "prism":
		projectile_scale = 1.18
	projectile.scale = Vector2.ONE * projectile_scale
	projectile.modulate = Color(color.r, color.g, color.b, 1.0)
	projectile.z_index = 28
	(projectile as CanvasItem).material = VfxLib._new_additive_material()
	var trail := Sprite2D.new()
	trail.texture = load("res://assets/production/sprites/vfx/vfx_input_streak.png") as Texture2D
	trail.position = Vector2(-58, 0)
	trail.scale = Vector2(1.72, 0.58)
	trail.modulate = Color(color.r, color.g, color.b, 0.66)
	(trail as CanvasItem).material = VfxLib._new_additive_material()
	projectile.add_child(trail)
	$ProjectileLayer.add_child(projectile)
	var travel_time := maxf(0.12, float(profile.get("travel_time", 0.24)))
	var control: Vector2 = origin.lerp(target, 0.5)
	if style == "lob":
		control.y -= 150.0
	elif style == "shard":
		control.x += (-1.0 if hit_index % 2 == 0 else 1.0) * 48.0
	elif style == "prism":
		control.y -= 74.0
	var tween := projectile.create_tween()
	tween.tween_method(
		func(progress: float) -> void:
			if not is_instance_valid(projectile):
				return
			var inv := 1.0 - progress
			var next_position: Vector2 = origin * inv * inv + control * 2.0 * inv * progress + target * progress * progress
			projectile.global_position = next_position
			projectile.rotation = (target - next_position).angle(),
		0.0,
		1.0,
		travel_time
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(
		func() -> void:
			_spawn_boss_profile_impact(target, profile, element, color, hit_index, hit_count)
			if is_instance_valid(projectile):
				projectile.queue_free()
	)

func _spawn_boss_channel_beam(enemy: Node, target: Vector2, profile: Dictionary, element: String, color: Color, hit_index: int, hit_count: int) -> void:
	if not is_instance_valid(enemy):
		return
	var origin: Vector2 = (enemy as Node2D).global_position + Vector2(0, -90)
	var beam_path := str(profile.get("beam_texture", ""))
	var impact_path := str(profile.get("impact_texture", ""))
	if beam_path.is_empty() or impact_path.is_empty():
		_spawn_boss_profile_impact(target, profile, element, color, hit_index, hit_count)
		return
	if _can_spawn_projectile_fx(true):
		var texture := load(beam_path) as Texture2D
		if texture != null:
			var direction := target - origin
			var length := maxf(1.0, direction.length())
			var length_scale := length / maxf(1.0, float(texture.get_height()))
			var beam := Sprite2D.new()
			_track_transient_fx(beam, "projectile")
			beam.texture = texture
			beam.global_position = origin.lerp(target, 0.5)
			beam.rotation = direction.angle() - PI * 0.5 + randf_range(-0.018, 0.018)
			beam.flip_h = hit_index % 2 == 1
			beam.scale = Vector2(length_scale * 0.76, length_scale * 1.06)
			beam.modulate = Color(1.0, 1.0, 1.0, 0.96)
			beam.z_index = 27
			(beam as CanvasItem).material = VfxLib._new_additive_material()
			$ProjectileLayer.add_child(beam)
			var glow := Sprite2D.new()
			glow.texture = texture
			glow.flip_h = beam.flip_h
			glow.modulate = Color(color.r * 0.58, color.g * 0.72, 1.0, 0.28)
			glow.scale = Vector2.ONE * 1.16
			glow.z_index = -1
			(glow as CanvasItem).material = VfxLib._new_additive_material()
			beam.add_child(glow)
			var life := clampf(float(profile.get("hit_gap", 0.12)) * 1.15, 0.11, 0.17)
			var tween := beam.create_tween()
			tween.parallel().tween_property(beam, "scale:x", beam.scale.x * 1.12, life).set_trans(Tween.TRANS_SINE)
			tween.parallel().tween_property(beam, "modulate:a", 0.0, life).set_delay(life * 0.36)
			tween.parallel().tween_property(glow, "modulate:a", 0.0, life)
			tween.tween_callback(beam.queue_free)
	_spawn_boss_storm_impact(target, profile, element, color, hit_index, hit_count)

func _spawn_boss_storm_impact(target: Vector2, profile: Dictionary, element: String, color: Color, hit_index: int, hit_count: int) -> void:
	var impact_path := str(profile.get("impact_texture", ""))
	if _can_spawn_projectile_fx(true) and not impact_path.is_empty():
		var texture := load(impact_path) as Texture2D
		if texture != null:
			var impact := Sprite2D.new()
			_track_transient_fx(impact, "projectile")
			impact.texture = texture
			impact.global_position = target
			# Source art includes a short incoming arc above the contact core. Align
			# the authored core with BREACH_Y instead of centering the full square.
			impact.offset = Vector2(0, -float(texture.get_height()) * 0.17)
			var impact_scale := maxf(0.4, float(profile.get("impact_scale", 1.0)))
			var final_scale := Vector2.ONE * (0.25 * impact_scale)
			impact.scale = final_scale * 0.68
			impact.rotation = randf_range(-0.035, 0.035)
			impact.modulate = Color(1.0, 1.0, 1.0, 0.94)
			impact.z_index = 9
			(impact as CanvasItem).material = VfxLib._new_additive_material()
			$ProjectileLayer.add_child(impact)
			var tween := impact.create_tween()
			tween.parallel().tween_property(impact, "scale", final_scale, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(impact, "modulate:a", 0.0, 0.24).set_delay(0.09)
			tween.tween_callback(impact.queue_free)
	var final_hit := hit_index >= hit_count - 1
	_spawn_attack_ring(target, 132.0 if final_hit else 96.0, color, 0.2 if final_hit else 0.13)
	var shake := float(profile.get("camera_shake", 6.0))
	_shake_hud(shake if final_hit else shake * 0.35, 0.16 if final_hit else 0.08)
	if not final_hit:
		AudioManager.play_enemy_sfx(_element_hit_sfx(element), -10.0, 0.025)

func _spawn_boss_dash_afterimage(enemy: Node, target: Vector2, color: Color) -> void:
	if not _can_spawn_projectile_fx(true):
		return
	var enemy_sprite := enemy.get_node_or_null("Sprite") as Sprite2D
	if enemy_sprite == null or enemy_sprite.texture == null:
		return
	var afterimage := Sprite2D.new()
	_track_transient_fx(afterimage, "projectile")
	afterimage.texture = enemy_sprite.texture
	afterimage.global_position = enemy.global_position
	afterimage.scale = enemy_sprite.scale
	afterimage.modulate = Color(color.r, color.g * 0.68, 1.0, 0.38)
	afterimage.z_index = 23
	(afterimage as CanvasItem).material = VfxLib._new_additive_material()
	$ProjectileLayer.add_child(afterimage)
	var dash_target: Vector2 = (enemy as Node2D).global_position.move_toward(target, 120.0)
	var tween := afterimage.create_tween()
	tween.parallel().tween_property(afterimage, "global_position", dash_target, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(afterimage, "modulate:a", 0.0, 0.16)
	tween.parallel().tween_property(afterimage, "scale", afterimage.scale * 1.14, 0.16)
	tween.tween_callback(afterimage.queue_free)

func _spawn_boss_profile_impact(target: Vector2, profile: Dictionary, element: String, color: Color, hit_index: int, hit_count: int) -> void:
	var impact_sequence := str(profile.get("impact_sequence", _enemy_impact_sequence(element)))
	var impact_scale := maxf(0.4, float(profile.get("impact_scale", 1.0)))
	_spawn_vfx_sequence(
		impact_sequence,
		target,
		impact_scale,
		Color(color.r, color.g, color.b, 0.94),
		1.08,
		randf_range(-0.24, 0.24),
		1.14,
		Vector2(0, -10),
		randf_range(-0.22, 0.22),
		true
	)
	var final_hit := hit_index >= hit_count - 1
	var mode := str(profile.get("mode", "melee_heavy"))
	if mode == "melee_heavy":
		_spawn_boss_base_rupture(target, impact_scale, mode == "melee_heavy")
	var ring_radius := (250.0 if mode == "melee_heavy" else 165.0) * impact_scale
	_spawn_attack_ring(target, ring_radius, color, 0.28 if final_hit else 0.18)
	var shake := float(profile.get("camera_shake", 8.0))
	_shake_hud(shake if final_hit else shake * 0.42, 0.2 if final_hit else 0.1)
	if not final_hit:
		AudioManager.play_enemy_sfx(_element_hit_sfx(element), -9.0, 0.025)

func _spawn_boss_base_rupture(target: Vector2, impact_scale: float, heavy: bool) -> void:
	if not _can_spawn_projectile_fx(true):
		return
	var rupture := Sprite2D.new()
	_track_transient_fx(rupture, "projectile")
	rupture.texture = load("res://assets/production/sprites/vfx/vfx_boss_base_rupture.png") as Texture2D
	rupture.global_position = target
	rupture.rotation = randf_range(-0.18, 0.18)
	var start_scale := (0.08 if heavy else 0.06) * impact_scale
	rupture.scale = Vector2.ONE * start_scale
	rupture.modulate = Color(1.0, 1.0, 1.0, 0.9 if heavy else 0.72)
	rupture.z_index = 8
	$ProjectileLayer.add_child(rupture)
	var tween := rupture.create_tween()
	tween.parallel().tween_property(rupture, "scale", rupture.scale * (1.42 if heavy else 1.32), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(rupture, "rotation", rupture.rotation + randf_range(-0.16, 0.16), 0.34)
	tween.parallel().tween_property(rupture, "modulate:a", 0.0, 0.4).set_delay(0.1)
	tween.tween_callback(rupture.queue_free)

func _boss_has_profiled_base_attack(enemy: Node) -> bool:
	if not is_instance_valid(enemy) or not bool(enemy.get("boss")):
		return false
	var profile_var: Variant = enemy.get("base_attack_profile")
	return profile_var is Dictionary and not (profile_var as Dictionary).is_empty()

func _spawn_breach_attack_vfx(enemy: Node, shielded: bool) -> void:
	if not is_instance_valid(enemy):
		return
	var mechanic := str(enemy.get("base_attack_kind"))
	if mechanic == "" or mechanic == "<null>":
		mechanic = str(enemy.mechanic)
	var color := Color(0.58, 0.86, 1.0, 0.78) if shielded else _attack_color_for_mechanic(mechanic)
	var target := _base_damage_impact_position(enemy.global_position.x)
	var path := "res://assets/production/sprites/vfx/vfx_hit_immune.png" if shielded else _attack_vfx_path(mechanic)
	var sequence := "vfx_hit_ice" if shielded else "vfx_enemy_skill_%s" % mechanic
	var fx := _spawn_vfx_sequence(sequence, target, _breach_attack_scale(mechanic), Color(color.r, color.g, color.b, 0.86), 1.18, randf_range(-0.14, 0.14), 1.08, Vector2(0, -8), randf_range(-0.16, 0.16), shielded)
	if fx == null:
		_spawn_attack_sprite(path, target, color, _breach_attack_scale(mechanic), 0.26)

func _attack_vfx_path(kind: String) -> String:
	match kind:
		"runner", "runner_dash", "charge", "leap", "leap_strike", "low_profile", "fast_claw":
			return "res://assets/production/sprites/vfx/vfx_threat_warning.png"
		"tank", "armor", "armor_break", "juggernaut", "shield_aura", "ward", "heavy_slam":
			return "res://assets/production/sprites/vfx/vfx_crit.png"
		"explode_on_death", "phase_burn", "blast":
			return "res://assets/production/sprites/vfx/vfx_explosion_fire.png"
		"ranged_spit", "toxic_cloud", "regenerate", "regen", "spawn_minions", "corrosion":
			return "res://assets/production/sprites/vfx/vfx_poison_cloud.png"
		"buff_aura", "support_strike", "mutate":
			return "res://assets/production/sprites/vfx/vfx_boss_phase.png"
		"enrage":
			return "res://assets/production/sprites/vfx/vfx_enemy_skill_enrage.png"
		"freeze_field":
			return "res://assets/production/sprites/vfx/vfx_freeze.png"
		"storm_chain":
			return "res://assets/production/sprites/vfx/vfx_chain_lightning.png"
		"summon":
			return "res://assets/production/sprites/vfx/vfx_boss_phase.png"
		"phase", "phase_shift", "multi_phase":
			return "res://assets/production/sprites/vfx/vfx_boss_phase.png"
		_:
			return "res://assets/production/sprites/vfx/vfx_hit_physical.png"

func _attack_color_for_mechanic(kind: String) -> Color:
	match kind:
		"runner", "runner_dash", "charge", "leap", "leap_strike", "low_profile", "fast_claw":
			return Color(1.0, 0.88, 0.24, 0.78)
		"tank", "armor", "armor_break", "juggernaut", "shield_aura", "ward", "heavy_slam":
			return Color(0.92, 0.72, 0.46, 0.82)
		"explode_on_death", "phase_burn", "blast":
			return Color(1.0, 0.42, 0.12, 0.78)
		"ranged_spit", "toxic_cloud", "regenerate", "regen", "spawn_minions", "corrosion":
			return Color(0.46, 1.0, 0.25, 0.76)
		"buff_aura", "support_strike":
			return Color(0.74, 0.45, 1.0, 0.72)
		"mutate":
			return Color(0.92, 0.45, 1.0, 0.78)
		"enrage":
			return Color(1.0, 0.32, 0.16, 0.78)
		"freeze_field":
			return Color(0.48, 0.9, 1.0, 0.76)
		"storm_chain":
			return Color(0.58, 0.92, 1.0, 0.82)
		"summon", "phase", "phase_shift", "multi_phase":
			return Color(0.68, 0.48, 1.0, 0.76)
		_:
			return Color(1.0, 0.24, 0.16, 0.76)

func _breach_attack_scale(kind: String) -> float:
	match kind:
		"tank", "armor", "armor_break", "juggernaut", "heavy_slam":
			return 1.22
		"explode_on_death", "toxic_cloud", "blast":
			return 1.34
		"runner", "runner_dash", "charge", "leap", "leap_strike", "low_profile", "fast_claw":
			return 0.86
		"corrosion":
			return 0.92
		"support_strike":
			return 0.78
		_:
			return 1.0

func _spawn_vfx_sequence(sequence_id: String, position: Vector2, scale_mult := 1.0, tint := Color.WHITE, fps_mult := 1.0, rotation_rad := 0.0, grow_mult := 1.0, lift_vector := Vector2.ZERO, spin_rad := 0.0, priority := false) -> Node:
	if not _can_spawn_projectile_fx(priority):
		return null
	var fx := SequenceVfx.new()
	_track_transient_fx(fx, "projectile")
	$ProjectileLayer.add_child(fx)
	if not fx.setup(sequence_id, position, scale_mult, tint, fps_mult, rotation_rad, grow_mult, lift_vector, spin_rad):
		fx.queue_free()
		return null
	return fx

func _spawn_attack_sprite(path: String, position: Vector2, color: Color, scale_mult: float, duration: float) -> void:
	var tex := load(path) as Texture2D
	if tex == null:
		return
	if not _can_spawn_projectile_fx():
		return
	var fx := Sprite2D.new()
	_track_transient_fx(fx, "projectile")
	fx.texture = tex
	fx.global_position = position
	fx.rotation = randf_range(-0.25, 0.25)
	fx.scale = Vector2(0.46, 0.46) * scale_mult
	fx.modulate = color
	$ProjectileLayer.add_child(fx)
	var tween := fx.create_tween()
	tween.parallel().tween_property(fx, "scale", fx.scale * 1.35, duration)
	tween.parallel().tween_property(fx, "rotation", fx.rotation + randf_range(-0.35, 0.35), duration)
	tween.parallel().tween_property(fx, "modulate:a", 0.0, duration)
	tween.tween_callback(fx.queue_free)

func _spawn_attack_ring(origin: Vector2, radius: float, color: Color, duration: float) -> void:
	if not _can_spawn_projectile_fx():
		return
	var ring := Sprite2D.new()
	_track_transient_fx(ring, "projectile")
	ring.texture = load("res://assets/production/sprites/vfx/vfx_target_lock.png")
	ring.global_position = origin
	ring.scale = Vector2.ONE * maxf(radius / 128.0, 0.25)
	ring.modulate = Color(color.r, color.g, color.b, minf(color.a, 0.36))
	$ProjectileLayer.add_child(ring)
	var tween := ring.create_tween()
	tween.parallel().tween_property(ring, "scale", ring.scale * 1.18, duration)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, duration)
	tween.tween_callback(ring.queue_free)

func _on_enemy_tree_exiting(enemy: Node) -> void:
	if enemy.threat_marker and is_instance_valid(enemy.threat_marker):
		enemy.threat_marker.queue_free()

func _on_enemy_died(enemy: Node, reward: Dictionary) -> void:
	battle_kills += 1
	if bool(reward.get("boss", false)):
		battle_boss_kills += 1
	var death_sfx := _zombie_event_sfx(str(enemy.get("mechanic")) if is_instance_valid(enemy) else "", "death")
	AudioManager.play_enemy_sfx(death_sfx, -7.5, 0.025)
	if enemy == active_boss:
		active_boss = null
		_refresh_active_boss()
	if is_instance_valid(enemy):
		enemy.set_meta("death_element", str(reward.get("death_element", "physical")))
	_apply_inferno_death_spread(enemy, reward)
	_resolve_death_mechanic(enemy)
	_process_kill_feedback(enemy, reward)
	# Stage 1 P0 — combat feel
	_register_kill_for_combo(bool(reward.get("boss", false)))
	_trigger_kill_screen_shake(bool(reward.get("boss", false)))
	_trigger_kill_hit_stop(bool(reward.get("boss", false)))
	var gold_per_kill := econ_gold_base + econ_gold_per * float(level_ordinal)
	var reward_scale := float(enemy.get_meta("reward_scale", 1.0)) if is_instance_valid(enemy) else 1.0
	var endless_gold_mult := _endless_gold_multiplier(endless_loop + 1) if is_endless_mode else 1.0
	var reward_gold := int(round(float(reward.get("gold_coef", 1.0)) * gold_per_kill * float(level.get("reward_gold_mult", 1.0)) * gold_mult * skills.gold_multiplier() * variant_gold_mult * reward_scale * endless_gold_mult))
	var raw_reward_xp := float(reward.get("xp", 0)) * reward_scale
	var xp_budget_counted := bool(enemy.get_meta("xp_budget_counted", false)) if is_instance_valid(enemy) else false
	var reward_xp := _normalized_run_xp_reward(raw_reward_xp, xp_budget_counted)
	gold += reward_gold
	xp += reward_xp
	if is_instance_valid(enemy):
		if reward_gold > 0 and gold_fly:
			gold_fly.fly_to_hud(enemy.global_position + Vector2(0, -20), reward_gold)
		if reward_xp > 0:
			_pulse_reward_target("xp")
	if reward_gold > 0:
		var now := Time.get_ticks_msec() / 1000.0
		if now - last_gold_sfx_at >= 0.18:
			last_gold_sfx_at = now
			AudioManager.play_sfx("gold_pickup", -8.0)
			if skills.level("skill_gold_rush") > 0:
				AudioManager.play_sfx("skill_gold_rush", -9.5, 0.02)
	if enemy == target_manager.locked_enemy:
		target_manager.clear_lock()
	_try_show_xp_card_offer(enemy)
	# The runtime calibration probe can advance many authored physics ticks
	# before SceneTree gets another process-frame boundary.  queue_free() is
	# intentionally deferred, so leaving a defeated enemy under EnemyLayer
	# would make wave completion and target snapshots depend on the chosen
	# acceleration factor.  Detach it immediately in audit mode while keeping
	# production death-animation / deferred-free behaviour unchanged.
	if _audit_combat_rng != null and is_instance_valid(enemy) and enemy.get_parent() == $EnemyLayer:
		$EnemyLayer.remove_child(enemy)
	if wave_clear_fast_forward_enabled and not _has_live_enemies(enemy):
		# Runs after `_resolve_death_mechanic`/`_apply_inferno_death_spread`
		# above, so a death that itself spawns something (e.g. the "split"
		# mechanic) is already reflected in `_has_live_enemies` and does not
		# get mistaken for a clear field.
		_wave_clear_fast_forward_clear_at = _gameplay_now_seconds()

func _normalized_run_xp_reward(raw_reward_xp: float, xp_budget_counted: bool) -> int:
	var reward_xp := int(round(raw_reward_xp * variant_xp_mult))
	if level_run_xp_budget > 0 and xp_budget_counted and level_raw_run_xp_total > 0:
		# Chapter pacing may replace many light bodies with fewer durable ones. A
		# topology-neutral authored-wave budget preserves campaign XP and card
		# timing without changing any per-enemy reward row. Runtime extra Bosses
		# and summons are deliberately outside this authored budget.
		level_run_xp_raw_earned += raw_reward_xp
		var earned_ratio := clampf(level_run_xp_raw_earned / float(level_raw_run_xp_total), 0.0, 1.0)
		var target_awarded := int(round(earned_ratio * float(level_run_xp_budget) * variant_xp_mult))
		reward_xp = maxi(0, target_awarded - level_run_xp_budget_awarded)
		level_run_xp_budget_awarded = target_awarded
	return reward_xp

func _on_enemy_damage_dealt(enemy: Node, amount: float, element: String, crit_hit: bool, weak_hit: bool, damage_source := "weapon") -> void:
	var applied := maxf(amount, 0.0)
	battle_damage_total += applied
	battle_damage_by_element[element] = float(battle_damage_by_element.get(element, 0.0)) + applied
	battle_damage_by_source[damage_source] = float(battle_damage_by_source.get(damage_source, 0.0)) + applied
	if crit_hit:
		battle_crit_damage += applied
	if weak_hit:
		battle_weak_damage += applied
	if damage_numbers and is_instance_valid(enemy):
		damage_numbers.spawn_damage(enemy.global_position + Vector2(0, -34 if not bool(enemy.boss) else -76), amount, element, crit_hit, weak_hit)
	# crit-only screen shake (light) and hit stop (very short)
	if crit_hit:
		if skills.level("skill_critical") > 0:
			AudioManager.play_sfx("skill_critical", -9.5, 0.02)
		VfxLib.screen_shake(6.0, 0.08)
		if hit_stop:
			hit_stop.pulse(0.04)

func _register_kill_for_combo(is_boss: bool) -> void:
	if combo_hud == null:
		return
	(combo_hud as Control).register_kill()
	if is_boss:
		var m: Control = combo_hud
		var milestone := m.get_node_or_null("Milestone") as Label
		if milestone:
			milestone.text = "首领击破！"
			milestone.modulate = Color(1.0, 0.4, 0.18, 1.0)
			milestone.modulate.a = 1.0
			milestone.scale = Vector2(0.7, 0.7)
			var tw := create_tween()
			tw.parallel().tween_property(milestone, "scale", Vector2(1.2, 1.2), 0.18)
			tw.tween_interval(0.5)
			tw.tween_property(milestone, "modulate:a", 0.0, 0.4)

func _trigger_kill_screen_shake(is_boss: bool) -> void:
	if screen_shake_node == null:
		return
	if is_boss:
		VfxLib.screen_shake(18.0, 0.36)
	elif kill_streak >= 8:
		VfxLib.screen_shake(7.0, 0.14)
	elif kill_streak >= 4:
		VfxLib.screen_shake(4.0, 0.10)

func _trigger_kill_hit_stop(is_boss: bool) -> void:
	if hit_stop == null:
		return
	if is_boss:
		hit_stop.pulse(0.12)

func _process_kill_feedback(enemy: Node, reward: Dictionary) -> void:
	# Combo accounting is part of the battle report.  Runtime keeps the authored
	# wall-clock feel, while deterministic probes use the battle's fixed logical
	# clock so host acceleration and process scheduling cannot change the streak.
	var now := battle_elapsed_seconds if _audit_combat_rng != null else Time.get_ticks_msec() / 1000.0
	kill_streak = kill_streak + 1 if now - last_kill_at <= 1.35 else 1
	battle_max_kill_streak = maxi(battle_max_kill_streak, kill_streak)
	last_kill_at = now
	if not is_instance_valid(enemy):
		return
	if bool(reward.get("boss", false)):
		_spawn_float_text(enemy.global_position + Vector2(0, -138), "首领击破", Color(1.0, 0.35, 0.16))
		_show_screen_flash(Color(1.0, 0.62, 0.18, 0.18), 0.24)
		AudioManager.play_sfx("level_up", -1.0, 0.01)
		return
	if bool(reward.get("weak_kill", false)):
		_queue_weak_kill_feedback()
		AudioManager.play_sfx("hit_immune", -7.0, 0.02)
	if kill_streak >= 5:
		_show_wave_toast("%d 连斩" % kill_streak, Color(1.0, 0.72, 0.24))
		if kill_streak % 5 == 0:
			AudioManager.play_sfx("level_up", -6.0, 0.02)

func _queue_weak_kill_feedback() -> void:
	weak_kill_feedback_count += 1
	if weak_kill_feedback_pending:
		return
	weak_kill_feedback_pending = true
	get_tree().create_timer(0.18).timeout.connect(_flush_weak_kill_feedback)

func _flush_weak_kill_feedback() -> void:
	weak_kill_feedback_pending = false
	if weak_kill_feedback_count <= 0:
		return
	var now := Time.get_ticks_msec() / 1000.0
	var cooldown := 0.62
	var wait_time := cooldown - (now - last_weak_kill_feedback_at)
	if wait_time > 0.0:
		weak_kill_feedback_pending = true
		get_tree().create_timer(wait_time).timeout.connect(_flush_weak_kill_feedback)
		return
	var count := weak_kill_feedback_count
	weak_kill_feedback_count = 0
	last_weak_kill_feedback_at = now
	var text := "弱点击破" if count <= 1 else "弱点击破 x%d" % count
	_show_wave_toast(text, Color(1.0, 0.86, 0.22))

func _resolve_death_mechanic(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	var death_element := "physical"
	if enemy.has_meta("death_element"):
		death_element = str(enemy.get_meta("death_element"))
	_spawn_death_element_vfx(enemy.global_position, death_element, bool(enemy.boss))
	match str(enemy.mechanic):
		"explode_on_death":
			_enemy_death_blast(enemy, 170.0, 0.45, Color(1.0, 0.45, 0.18))
		"toxic_cloud":
			_enemy_death_blast(enemy, 220.0, 0.28, Color(0.42, 1.0, 0.28))
		"split":
			for offset in [-46.0, 46.0]:
				_spawn_enemy_instance("zombie_crawler", enemy.global_position + Vector2(offset, 16.0), false, 0.0)

func _enemy_death_blast(enemy: Node, radius: float, damage_scale: float, color: Color) -> void:
	_spawn_enemy_attack_vfx(enemy, str(enemy.mechanic), enemy.global_position)
	_spawn_attack_ring(enemy.global_position, radius, color, 0.24)
	for target in $EnemyLayer.get_children():
		if target == enemy or not is_instance_valid(target):
			continue
		if target.global_position.distance_to(enemy.global_position) <= radius and target.has_method("take_damage"):
			target.take_damage(18.0 * damage_scale * float(turret.damage_mult), "fire")
	if enemy.global_position.y > 1080.0:
		var base_damage := _enemy_skill_damage(enemy, damage_scale, 2.0)
		_apply_enemy_skill_base_damage(enemy, base_damage, "爆裂", color, _base_damage_impact_position(enemy.global_position.x))

func _on_enemy_breached(enemy: Node, damage: int) -> void:
	var profiled_boss_attack := _boss_has_profiled_base_attack(enemy)
	_play_character_hurt()
	if not profiled_boss_attack:
		_shake_hud(5.0, 0.1)
	var final_damage := int(ceil(float(damage) * breach_damage_mult * _challenge_mult("breach_damage_mult")))
	var max_hit_fraction := MAX_BASE_HIT_FRACTION
	final_damage = mini(final_damage, maxi(1, int(round(float(base_hp_max) * max_hit_fraction))))  # 防秒杀
	var preventable_damage := final_damage
	var shield_absorbed := false
	if breach_shields + skill_barriers_left > 0:
		if breach_shields > 0:
			breach_shields -= 1
		else:
			skill_barriers_left -= 1
		final_damage = 0
		shield_absorbed = true
	if is_instance_valid(enemy):
		if not profiled_boss_attack:
			_spawn_breach_attack_vfx(enemy, final_damage <= 0)
		var text := "格挡" if final_damage <= 0 else "-%d" % final_damage
		var text_position: Vector2 = (enemy as Node2D).global_position + Vector2(randf_range(-16.0, 16.0), -104)
		if profiled_boss_attack:
			text_position = _base_damage_impact_position(enemy.global_position.x) + Vector2(-110, -76)
		_spawn_float_text(text_position, text, Color(1.0, 0.18, 0.18), profiled_boss_attack, 23 if profiled_boss_attack else 21)
		if shield_absorbed:
			_spawn_barrier_break_vfx(_base_damage_impact_position(enemy.global_position.x))
			_update_barrier_visual()
	if shield_absorbed:
		battle_base_damage_prevented += preventable_damage
		AudioManager.play_enemy_sfx("hit_immune", -8.0, 0.02)
	elif final_damage > 0:
		AudioManager.play_enemy_sfx("enemy_breach", -8.0 if profiled_boss_attack else -4.0, 0.02)
	base_hp = max(base_hp - final_damage, 0)
	battle_base_damage_taken += final_damage
	_apply_premium_armor_counter(enemy, final_damage, _base_damage_impact_position(enemy.global_position.x))
	if final_damage > 0:
		_show_screen_flash(Color(1.0, 0.05, 0.03, 0.06), 0.1)
	_check_low_hp_warning()
	if base_hp <= 0:
		_finish(false)

func _apply_premium_armor_counter(source: Node, final_damage: int, impact_position: Vector2) -> void:
	match str(armor_data.get("effect_profile", "")):
		"apocalypse_thunder_conductor":
			_apply_apocalypse_armor_counter(source, final_damage, impact_position)
		"apocalypse_inferno_molten":
			_apply_apocalypse_inferno_armor_counter(source, final_damage, impact_position)
		"apocalypse_absolute_zero_permafrost":
			_apply_apocalypse_absolute_zero_armor_counter(source, final_damage, impact_position)
		"apocalypse_golden_law_eternal_night":
			_apply_apocalypse_golden_law_armor_counter(source, final_damage, impact_position)

func _apply_apocalypse_armor_counter(source: Node, final_damage: int, impact_position: Vector2) -> void:
	if final_damage <= 0:
		return
	var now := _gameplay_now_seconds()
	apocalypse_armor_counter_cooldown = maxf(apocalypse_armor_counter_cooldown, 0.0)
	apocalypse_armor_charge += 1
	var hits_needed := maxi(2, int(armor_data.get("counter_charge_hits", 3)))
	if apocalypse_armor_charge < hits_needed or now < apocalypse_armor_counter_cooldown:
		_spawn_attack_ring(impact_position, 96.0, Color(0.36, 0.86, 1.0, 0.32), 0.18)
		return
	apocalypse_armor_charge = 0
	apocalypse_armor_counter_cooldown = now + float(armor_data.get("counter_cooldown", 8.0))
	if source != null and is_instance_valid(source) and source.has_method("take_damage"):
		var counter_damage := _current_primary_shot_damage("lightning", false) * float(armor_data.get("counter_damage_mult", 4.0))
		source.take_damage(counter_damage, "lightning", 0.18, 1.35)
		var target := (source as Node2D).global_position
		var visual_target := _apocalypse_edge_safe_vfx_point(target)
		if visual_target.distance_to(target) > 2.0:
			_spawn_chain_arc(visual_target, target, "lightning")
		_spawn_attack_sprite("res://assets/production/sprites/vfx/vfx_boss_storm_column.png", visual_target + Vector2(0, -140), Color(0.72, 0.96, 1.0, 0.94), 0.64, 0.30)
		_spawn_attack_ring(target, 150.0, Color(0.86, 0.42, 1.0, 0.48), 0.26)
		_spawn_float_text(target + Vector2(0, -128), LocalizationManager.text("导体反击"), UiKit.CYAN)


func _apply_apocalypse_inferno_armor_counter(_source: Node, final_damage: int, impact_position: Vector2) -> void:
	if final_damage <= 0:
		return
	var now := _gameplay_now_seconds()
	apocalypse_armor_charge += 1
	var hits_needed := maxi(2, int(armor_data.get("counter_charge_hits", 3)))
	if apocalypse_armor_charge < hits_needed or now < apocalypse_armor_counter_cooldown:
		_spawn_attack_ring(impact_position, 98.0, Color(1.0, 0.32, 0.05, 0.30), 0.18)
		return
	apocalypse_armor_charge = 0
	apocalypse_armor_counter_cooldown = now + float(armor_data.get("counter_cooldown", 9.0))
	var radius := float(armor_data.get("counter_radius", 270.0))
	var max_targets := maxi(1, int(armor_data.get("counter_max_targets", 8)))
	var counter_damage := _current_primary_shot_damage("fire", false) * float(armor_data.get("counter_damage_mult", 2.4))
	var targets: Array[Node2D] = []
	for candidate in $EnemyLayer.get_children():
		if not is_instance_valid(candidate) or not candidate is Node2D or not candidate.has_method("take_damage"):
			continue
		if (candidate as Node2D).global_position.distance_to(impact_position) <= radius:
			targets.append(candidate as Node2D)
	targets.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return _audit_node2d_metric_less(a, b, a.global_position.distance_squared_to(impact_position), b.global_position.distance_squared_to(impact_position))
	)
	for index in range(mini(targets.size(), max_targets)):
		var target := targets[index]
		var scale := lerpf(1.0, 0.54, float(index) / float(maxi(max_targets - 1, 1)))
		_deal_damage_with_source(target, counter_damage * scale, "fire", 0.10, 0.42, "armor_counter")
	var restored := int(round(float(base_hp_max) * float(armor_data.get("counter_restore_ratio", 0.025))))
	base_hp = mini(base_hp_max, base_hp + maxi(restored, 1))
	var reduced := SettingsManager.reduced_effects_enabled()
	var counter_center := impact_position + Vector2(0, -102)
	_spawn_vfx_sequence(
		"vfx_apocalypse_inferno_counter",
		counter_center,
		_inferno_edge_safe_vfx_scale(counter_center, 0.82 if reduced else 1.12),
		Color(1.0, 0.88, 0.62, 0.58 if reduced else 0.92),
		1.0,
		0.0,
		1.02,
		Vector2(0, -5),
		0.0,
		true
	)
	_spawn_attack_ring(impact_position, radius, Color(1.0, 0.54, 0.08, 0.24 if reduced else 0.38), 0.30)
	_spawn_float_text(impact_position + Vector2(-94, -116), LocalizationManager.text("熔炉反击 +%d" % restored), Color(1.0, 0.66, 0.18, 1.0), true, 24, 250.0)
	AudioManager.play_sfx("apocalypse_inferno_counter", -3.5, 0.015)
	SettingsManager.pulse_haptic("heavy")


func _apply_apocalypse_absolute_zero_armor_counter(_source: Node, final_damage: int, impact_position: Vector2) -> void:
	if final_damage <= 0:
		return
	var now := _gameplay_now_seconds()
	apocalypse_armor_charge += 1
	var hits_needed := maxi(2, int(armor_data.get("counter_charge_hits", 3)))
	if apocalypse_armor_charge < hits_needed or now < apocalypse_armor_counter_cooldown:
		_spawn_attack_ring(impact_position, 98.0, Color(0.44, 0.90, 1.0, 0.30), 0.18)
		return
	apocalypse_armor_charge = 0
	apocalypse_armor_counter_cooldown = now + float(armor_data.get("counter_cooldown", 9.0))
	var radius := float(armor_data.get("counter_radius", 280.0))
	var max_targets := maxi(1, int(armor_data.get("counter_max_targets", 8)))
	var counter_damage := _current_primary_shot_damage("ice", false) * float(armor_data.get("counter_damage_mult", 1.9))
	var targets: Array[Node2D] = []
	for candidate in $EnemyLayer.get_children():
		if not is_instance_valid(candidate) or not candidate is Node2D or not candidate.has_method("take_damage"):
			continue
		if (candidate as Node2D).global_position.distance_to(impact_position) <= radius:
			targets.append(candidate as Node2D)
	targets.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return _audit_node2d_metric_less(a, b, a.global_position.distance_squared_to(impact_position), b.global_position.distance_squared_to(impact_position))
	)
	for index in range(mini(targets.size(), max_targets)):
		var target := targets[index]
		var scale := lerpf(1.0, 0.56, float(index) / float(maxi(max_targets - 1, 1)))
		_deal_damage_with_source(target, counter_damage * scale, "ice", 0.06, float(armor_data.get("counter_slow", 0.38)), "armor_counter")
		if target.has_method("mark_ice_slow_visual"):
			target.mark_ice_slow_visual(2.0)
	var restored := int(round(float(base_hp_max) * float(armor_data.get("counter_restore_ratio", 0.018))))
	base_hp = mini(base_hp_max, base_hp + maxi(restored, 1))
	var reduced := SettingsManager.reduced_effects_enabled()
	var counter_center := impact_position + Vector2(0, -102)
	_spawn_vfx_sequence(
		"vfx_apocalypse_absolute_zero_counter",
		counter_center,
		_inferno_edge_safe_vfx_scale(counter_center, 0.80 if reduced else 1.08),
		Color(0.82, 0.98, 1.0, 0.56 if reduced else 0.90),
		1.0,
		0.0,
		1.02,
		Vector2(0, -5),
		0.0,
		true
	)
	_spawn_attack_ring(impact_position, radius, Color(0.42, 0.88, 1.0, 0.24 if reduced else 0.36), 0.30)
	_spawn_float_text(impact_position + Vector2(-94, -116), LocalizationManager.text("永冻反击 +%d") % restored, Color(0.66, 0.94, 1.0, 1.0), true, 24, 250.0)
	AudioManager.play_sfx("apocalypse_absolute_zero_counter", -3.5, 0.015)
	SettingsManager.pulse_haptic("heavy")


func _apply_apocalypse_golden_law_armor_counter(_source: Node, final_damage: int, impact_position: Vector2) -> void:
	if final_damage <= 0:
		return
	var now := _gameplay_now_seconds()
	apocalypse_armor_charge += 1
	var hits_needed := maxi(2, int(armor_data.get("counter_charge_hits", 3)))
	if apocalypse_armor_charge < hits_needed or now < apocalypse_armor_counter_cooldown:
		_spawn_attack_ring(impact_position, 100.0, Color(1.0, 0.76, 0.22, 0.30), 0.18)
		return
	apocalypse_armor_charge = 0
	apocalypse_armor_counter_cooldown = now + float(armor_data.get("counter_cooldown", 8.5))
	var radius := float(armor_data.get("counter_radius", 290.0))
	var max_targets := maxi(1, int(armor_data.get("counter_max_targets", 6)))
	var counter_damage := _current_primary_shot_damage("physical", false) * float(armor_data.get("counter_damage_mult", 2.1))
	var targets: Array[Node2D] = []
	for candidate in $EnemyLayer.get_children():
		if is_instance_valid(candidate) and candidate is Node2D and candidate.has_method("take_damage"):
			targets.append(candidate as Node2D)
	targets.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		if not is_equal_approx(a.global_position.y, b.global_position.y):
			return a.global_position.y > b.global_position.y
		return _audit_combat_rng != null and _audit_enemy_precedes(a, b)
	)
	if targets.size() > max_targets:
		targets.resize(max_targets)
	for index in range(targets.size()):
		var target := targets[index]
		var scale := lerpf(1.0, 0.62, float(index) / float(maxi(max_targets - 1, 1)))
		_deal_damage_with_source(target, counter_damage * scale, "physical", 0.20, 0.0, "armor_counter")
		_spawn_weapon_trace(impact_position, target.global_position + Vector2(0, -28), Color(1.0, 0.80, 0.30, 0.78), 11.0, 0.18)
	var restored := int(round(float(base_hp_max) * float(armor_data.get("counter_restore_ratio", 0.022))))
	base_hp = mini(base_hp_max, base_hp + maxi(restored, 1))
	var center := impact_position + Vector2(0, -102)
	_spawn_vfx_sequence("vfx_apocalypse_golden_law_counter", center, _inferno_edge_safe_vfx_scale(center, 0.82 if SettingsManager.reduced_effects_enabled() else 1.10), Color(1.0, 0.90, 0.58, 0.92), 1.0, 0.0, 1.02, Vector2(0, -5), 0.0, true)
	_spawn_attack_ring(impact_position, radius, Color(1.0, 0.72, 0.18, 0.36), 0.30)
	_spawn_float_text(impact_position + Vector2(-94, -116), LocalizationManager.text("永夜反击") + " +%d" % restored, Color(1.0, 0.84, 0.38, 1.0), true, 24, 250.0)
	AudioManager.play_sfx("apocalypse_golden_law_counter", -3.5, 0.015)
	SettingsManager.pulse_haptic("heavy")

## design/24 Phase 2: boss levels are survival sponges, so the same leak budget
## costs the player far more base HP than on an ordinary level. Give the base
## line a data-driven cushion instead of shaving the boss HP ramp. Enemy
## pressure and the recommended-power formula are untouched.
##
## Phase 8 turned the flat cushion into a curve. Boss-level pressure is U-shaped
## - levels 5-20 and 65-99 both read 46-57% leak while the 25-60 middle sits at
## 33-46% - so a flat multiplier left the first three boss levels a player ever
## meets among the hardest in the campaign. The extra early cushion straightens
## the left arm; the late arm stays hardest on purpose.
func _boss_level_base_hp_mult(economy: Dictionary) -> float:
	var is_boss_level := false
	for w in level.get("waves", []):
		if w.has("boss"):
			is_boss_level = true
			break
	if not is_boss_level:
		return 1.0
	var rule: Variant = economy.get("boss_level_base_hp_mult", 1.0)
	if not (rule is Dictionary):
		return maxf(1.0, float(rule))
	var row: Dictionary = rule
	var base := maxf(1.0, float(row.get("base", 1.0)))
	var early := maxf(base, float(row.get("early_mult", base)))
	var full_level := float(row.get("early_full_level", 0))
	var end_level := float(row.get("early_end_level", full_level))
	var ordinal := float(level_ordinal)
	if ordinal <= full_level:
		return early
	if ordinal >= end_level or end_level <= full_level:
		return base
	var t := (ordinal - full_level) / (end_level - full_level)
	return early + (base - early) * t

func _compute_level_raw_run_xp() -> int:
	var total := 0
	var economy: Dictionary = DataLoader.get_table("economy")
	for w in level.get("waves", []):
		var wave_no := int(w.get("wave", 0))
		var count_mult := _late_wave_count_mult(wave_no, economy)
		if w.has("boss"):
			total += int(DataLoader.get_row("bosses", str(w.get("boss", ""))).get("run_xp", 0))
		for s in w.get("spawns", []):
			total += int(round(float(int(s.get("count", 0))) * count_mult)) * int(DataLoader.get_row("zombies", str(s.get("type", ""))).get("run_xp", 0))
		for s in w.get("support", []):
			total += int(round(float(int(s.get("count", 0))) * count_mult)) * int(DataLoader.get_row("zombies", str(s.get("type", ""))).get("run_xp", 0))
	return total

func _compute_level_total_run_xp() -> int:
	if level_run_xp_budget > 0:
		return level_run_xp_budget
	return level_raw_run_xp_total if level_raw_run_xp_total > 0 else _compute_level_raw_run_xp()

func _pick_threshold(k: int) -> int:
	if k > target_card_picks and not is_endless_mode:
		return 1000000000
	if level_total_run_xp <= 0:
		return int(level.get("xp_first_offer", 16)) * k
	return int(round(float(level_total_run_xp) * float(k) / float(target_card_picks + 1)))

func _next_pick_threshold() -> int:
	return _pick_threshold(cards_picked + 1)

func _advance_card_xp_after_pick() -> void:
	if is_endless_mode:
		xp = 0
		displayed_xp_pct = 0.0
	next_xp_offer = _next_pick_threshold()

func _try_show_xp_card_offer(ignored_enemy: Node = null) -> bool:
	if xp < next_xp_offer:
		return false
	if card_offer_active or paused or battle_finished:
		return false
	if _would_finish_level_after_reward(ignored_enemy):
		return false
	_show_card_offer()
	return card_offer_active

func _would_finish_level_after_reward(ignored_enemy: Node = null) -> bool:
	var waves: Array = level.get("waves", [])
	if wave_index < waves.size():
		return false
	if not pending_spawns.is_empty():
		return false
	return not _has_live_enemies(ignored_enemy)

func _has_live_enemies(ignored_enemy: Node = null) -> bool:
	for enemy in $EnemyLayer.get_children():
		if enemy == ignored_enemy:
			continue
		if enemy.is_queued_for_deletion():
			continue
		var hp_value = enemy.get("hp")
		if hp_value != null and float(hp_value) <= 0.0:
			continue
		return true
	return false

func _maybe_show_pre_final_card_offer() -> bool:
	if pre_final_offer_used or card_offer_active or paused or battle_finished:
		return false
	var waves: Array = level.get("waves", [])
	if waves.size() <= 1:
		return false
	if wave_index != waves.size() - 1:
		return false
	if xp >= next_xp_offer:
		_show_card_offer()
	elif cards_picked == 0 and xp >= int(ceil(float(next_xp_offer) * PREFINAL_CARD_OFFER_XP_RATIO)):
		_show_card_offer()
	if not card_offer_active:
		return false
	pre_final_offer_used = true
	return true

func _check_victory() -> void:
	if active_spawning or not pending_spawns.is_empty() or $EnemyLayer.get_child_count() > 0:
		return
	var waves: Array = level.get("waves", [])
	if wave_index < waves.size():
		if _maybe_show_pre_final_card_offer():
			return
		_start_next_wave()
	elif is_endless_mode:
		_advance_endless_loop()
	else:
		_finish(true)

func _advance_endless_loop() -> void:
	var completed_loop := endless_loop + 1
	var economy: Dictionary = DataLoader.get_table("economy")
	_grant_endless_gold_milestone(completed_loop, economy)
	endless_loop += 1
	wave_index = 0
	endless_difficulty_mult = _endless_mob_hp_multiplier(endless_loop + 1, economy)
	_show_wave_toast("第 %d 轮尸潮 · 强度提升" % (endless_loop + 1), Color(1.0, 0.42, 0.22))
	_start_next_wave()

func _endless_gold_multiplier(display_loop: int, economy: Dictionary = {}) -> float:
	var source: Dictionary = economy if economy is Dictionary and not economy.is_empty() else DataLoader.get_table("economy")
	var loop_bonus := maxf(float(source.get("endless_gold_loop_bonus", 0.0)), 0.0)
	return 1.0 + loop_bonus * float(maxi(display_loop - 1, 0))

func _endless_gold_milestone_reward(completed_loop: int, economy: Dictionary) -> int:
	var config_var = economy.get("endless_gold_milestone", {})
	var config: Dictionary = config_var if config_var is Dictionary else {}
	var interval := maxi(int(config.get("interval", 0)), 0)
	if interval <= 0 or completed_loop <= 0 or completed_loop % interval != 0:
		return 0
	var milestone_index := int(completed_loop / interval)
	return maxi(int(config.get("gold_per_milestone", 0)) * milestone_index, 0)

func _grant_endless_gold_milestone(completed_loop: int, economy: Dictionary) -> int:
	if endless_gold_milestones_claimed.has(completed_loop):
		return 0
	var reward := _endless_gold_milestone_reward(completed_loop, economy)
	if reward <= 0:
		return 0
	endless_gold_milestones_claimed[completed_loop] = true
	gold += reward
	if gold_fly:
		gold_fly.fly_to_hud(Vector2(540.0, BREACH_Y - 48.0), reward)
	_pulse_reward_target("gold")
	AudioManager.play_sfx("gold_pickup", -3.5)
	var message := LocalizationManager.text("第 %d 轮里程碑 · 金币 +%d") % [completed_loop, reward]
	_show_wave_toast(message, UiKit.GOLD)
	return reward

func _endless_mob_hp_multiplier(display_loop: int, economy: Dictionary) -> float:
	var stages_var = economy.get("endless_hp_growth_stages", [])
	var stages: Array = stages_var if stages_var is Array else []
	if stages.is_empty():
		return pow(1.0 + ENDLESS_LOOP_HP_GROWTH, float(maxi(display_loop - 1, 0)))
	var multiplier := 1.0
	for current_loop in range(2, maxi(display_loop, 1) + 1):
		multiplier *= 1.0 + _endless_mob_hp_growth_for_loop(current_loop, stages)
	return multiplier

func _endless_mob_hp_growth_for_loop(display_loop: int, stages: Array) -> float:
	for stage_var in stages:
		if not stage_var is Dictionary:
			continue
		var stage := stage_var as Dictionary
		if not stage.has("until_loop") or display_loop <= int(stage.get("until_loop", display_loop)):
			return maxf(float(stage.get("growth", 0.0)), 0.0)
	return ENDLESS_LOOP_HP_GROWTH

func _finish(victory: bool) -> void:
	if battle_finished:
		return
	battle_finished = true
	_set_turret_fire_enabled(false)
	_hide_skill_hint()
	set_physics_process(false)
	if is_endless_mode:
		_show_screen_flash(Color(0.85, 0.0, 0.0, 0.22), 0.28)
		router.finish_level({
			"level_id": level_id,
			"endless": true,
			"endless_loop": endless_loop,
			"victory": false,
			"stars": 0,
			"gold": gold,
			"xp": 0,
			"power": player_power,
			"recommended_power": recommended_combat_power,
			"cards_selected": cards_selected,
			"target_card_picks": target_card_picks,
			"run_skill_levels": skills.owned.duplicate(true),
			"battle_report": _build_battle_report(),
		})
		return
	_show_screen_flash(Color(0.95, 0.78, 0.25, 0.18) if victory else Color(0.85, 0.0, 0.0, 0.22), 0.28)
	var hp_ratio := float(base_hp) / float(base_hp_max)
	var stars := 0
	if victory:
		# design/24 Phase 1: thresholds live in data/economy.json.star_thresholds
		# so the runtime and tools/simulate_balance.py rate a run the same way.
		stars = StarRules.stars_for_hp_ratio(hp_ratio, DataLoader.get_table("economy"))
	var first_clear_bonus := 0
	if victory and SaveManager.get_level_stars(level_id) == 0:
		first_clear_bonus = int(level.get("first_clear_reward", {}).get("gold", 0))
	# design/24 收尾：重复通关经验递减（首通 100% / 二周目 50% / 三周目起 25%）。
	# 在这里而不是在 SaveManager 里打折，是为了让结算页显示的数字就是实际入账的
	# 数字。倍率取"本次通关之前"的通关次数，必须在 apply_*_result 递增计数之前读。
	var repeat_xp_mult := SaveManager.get_repeat_clear_xp_mult(level_id, is_challenge_mode) if victory else 1.0
	var awarded_xp := int(round(float(xp) * repeat_xp_mult))
	var result := {
		"level_id": level_id,
		"victory": victory,
		"stars": stars,
		"gold": gold + first_clear_bonus,
		"xp": awarded_xp,
		"xp_full": xp,
		"repeat_xp_mult": repeat_xp_mult,
		"power": player_power,
		"recommended_power": recommended_combat_power,
		"cards_selected": cards_selected,
		"target_card_picks": target_card_picks,
		"run_skill_levels": skills.owned.duplicate(true),
		"battle_report": _build_battle_report(),
	}
	if is_challenge_mode:
		result["challenge"] = true
		result["gold"] = gold
	else:
		result["next_level"] = level.get("next_level", "")
	router.finish_level(result)

func _challenge_mult(key: String, fallback := 1.0) -> float:
	if not is_challenge_mode:
		return 1.0
	return maxf(0.1, float(challenge_rule.get(key, fallback)))

func _reset_battle_report() -> void:
	battle_elapsed_seconds = 0.0
	battle_damage_total = 0.0
	battle_damage_by_element = {}
	battle_damage_by_source = {}
	battle_crit_damage = 0.0
	battle_weak_damage = 0.0
	battle_kills = 0
	battle_boss_kills = 0
	battle_base_damage_taken = 0
	battle_base_damage_prevented = 0
	battle_control_seconds = 0.0
	battle_active_skill_casts = 0
	battle_max_kill_streak = 0
	battle_last_boss_id = ""

func _update_battle_report_control(real_delta: float, enemies: Array = []) -> void:
	var controlled := 0
	var candidates := enemies if not enemies.is_empty() else $EnemyLayer.get_children()
	for enemy in candidates:
		if is_instance_valid(enemy) and enemy.has_method("is_controlled") and enemy.is_controlled():
			controlled += 1
	battle_control_seconds += real_delta * float(controlled)

func _build_battle_report() -> Dictionary:
	var top_element := "physical"
	var top_damage := -1.0
	for element in battle_damage_by_element.keys():
		var value := float(battle_damage_by_element.get(element, 0.0))
		if value > top_damage:
			top_damage = value
			top_element = str(element)
	return {
		"duration_seconds": battle_elapsed_seconds,
		"damage_total": battle_damage_total,
		"damage_by_element": battle_damage_by_element.duplicate(true),
		"damage_by_source": battle_damage_by_source.duplicate(true),
		"top_element": top_element,
		"crit_damage": battle_crit_damage,
		"weak_damage": battle_weak_damage,
		"kills": battle_kills,
		"boss_kills": battle_boss_kills,
		"base_damage_taken": battle_base_damage_taken,
		"base_damage_prevented": battle_base_damage_prevented,
		"control_seconds": battle_control_seconds,
		"active_skill_casts": battle_active_skill_casts,
		"max_kill_streak": battle_max_kill_streak,
		"boss_id": battle_last_boss_id,
		"challenge_rule": challenge_rule.duplicate(true) if is_challenge_mode else {},
	}

func _update_hud() -> void:
	var hp_pct := float(base_hp) / float(base_hp_max) if base_hp_max > 0 else 0.0
	var hp_fill_left := _hud_fill_left(HUD_HP_BAR_PATH, 6.0)
	var hp_fill_right := _hud_fill_right(HUD_HP_BAR_PATH, HUD_HP_FILL_RIGHT)
	var hp_width := maxf(0.0, lerpf(hp_fill_left, hp_fill_right, hp_pct) - hp_fill_left)
	var hp_fill_texture := _hud_fill_texture(HUD_HP_BAR_PATH)
	if hp_fill_texture != null:
		var hp_fill_clip := _hud_fill_clip(HUD_HP_BAR_PATH)
		if hp_fill_clip != null:
			hp_fill_clip.size.x = hp_width
			hp_fill_texture.size.x = maxf(hp_fill_right - hp_fill_left, 1.0)
		else:
			hp_fill_texture.size.x = hp_width
	elif has_node("%s/Fill" % HUD_HP_BAR_PATH):
		var hp_fill := get_node("%s/Fill" % HUD_HP_BAR_PATH)
		hp_fill.offset_right = lerpf(hp_fill_left, hp_fill_right, hp_pct)
	var hp_label := get_node_or_null("%s/Label" % HUD_HP_BAR_PATH) as Label
	if hp_label != null:
		hp_label.text = "生命 %d/%d" % [base_hp, base_hp_max]
	_update_low_hp_pulse(hp_pct)
	_update_boss_hp_bar()
	var wave_pct := float(wave_index) / float(wave_total) if wave_total > 0 else 0.0
	displayed_wave_pct = lerpf(displayed_wave_pct, wave_pct, 0.22)
	var wave_fill_left := _hud_fill_left(HUD_WAVE_BAR_PATH, 6.0)
	var wave_fill_right := _hud_fill_right(HUD_WAVE_BAR_PATH, HUD_WAVE_FILL_RIGHT)
	var wave_width := maxf(0.0, lerpf(wave_fill_left, wave_fill_right, displayed_wave_pct) - wave_fill_left)
	var wave_fill_texture := _hud_fill_texture(HUD_WAVE_BAR_PATH)
	if wave_fill_texture != null:
		var wave_fill_clip := _hud_fill_clip(HUD_WAVE_BAR_PATH)
		if wave_fill_clip != null:
			wave_fill_clip.size.x = wave_width
			wave_fill_texture.size.x = maxf(wave_fill_right - wave_fill_left, 1.0)
		else:
			wave_fill_texture.size.x = wave_width
	elif has_node("%s/Fill" % HUD_WAVE_BAR_PATH):
		get_node("%s/Fill" % HUD_WAVE_BAR_PATH).offset_right = lerpf(wave_fill_left, wave_fill_right, displayed_wave_pct)
	var wave_label := get_node_or_null("%s/Label" % HUD_WAVE_BAR_PATH) as Label
	if is_endless_mode:
		if wave_label != null:
			wave_label.text = "第 %d 轮 · %d/%d 波" % [endless_loop + 1, wave_index, wave_total]
	else:
		if wave_label != null:
			wave_label.text = "第 %d/%d 波" % [wave_index, wave_total]
	var xp_pct := float(xp) / float(next_xp_offer) if next_xp_offer > 0 else 0.0
	displayed_xp_pct = lerpf(displayed_xp_pct, clamp(xp_pct, 0.0, 1.0), 0.28)
	$Hud/BottomBar/XpBar/Fill.offset_right = lerpf(7.0, _hud_xp_fill_right(), displayed_xp_pct)
	$Hud/BottomBar/XpBar/Label.text = "经验 %s/%s" % [_format_compact_number(xp), _format_compact_number(next_xp_offer)]
	$Hud/BottomBar/GoldLabel.text = _format_compact_number(gold)
	_update_skill_slots()
	_update_character_skill_button()
	_update_barrier_visual()
	if debug_overlay_on:
		$Hud/DebugOverlay.text = _build_debug_text()

func _hud_fill_left(bar_path: String, fallback: float) -> float:
	var bar := get_node_or_null(bar_path) as Control
	if bar == null or bar.size.x <= 16.0:
		return fallback
	if bar_path == HUD_WAVE_BAR_PATH:
		return minf(HUD_WAVE_FILL_LEFT, maxf(6.0, bar.size.x * 0.5 - 320.0))
	if bar_path == HUD_HP_BAR_PATH:
		return maxf(18.0, bar.size.x * 0.07)
	return fallback

func _hud_fill_right(bar_path: String, fallback: float) -> float:
	var bar := get_node_or_null(bar_path) as Control
	if bar == null or bar.size.x <= 16.0:
		return fallback
	if bar_path == HUD_WAVE_BAR_PATH:
		return maxf(_hud_fill_left(bar_path, 6.0) + 1.0, minf(HUD_WAVE_FILL_RIGHT, bar.size.x * 0.5 + 320.0))
	if bar_path == HUD_HP_BAR_PATH:
		return maxf(32.0, bar.size.x - maxf(18.0, bar.size.x * 0.07))
	return maxf(8.0, bar.size.x - 6.0)

func _hud_xp_fill_right() -> float:
	var xp_bar := get_node_or_null("Hud/BottomBar/XpBar") as Control
	if xp_bar == null or xp_bar.size.x <= 24.0:
		return HUD_XP_FILL_RIGHT
	return maxf(10.0, xp_bar.size.x - 7.0)

func _format_compact_number(value: int) -> String:
	var sign: String = "-" if value < 0 else ""
	var abs_value: int = absi(value)
	if abs_value < 1000:
		return "%d" % value
	var divisor: float = 1000.0
	var unit: String = "k"
	if abs_value >= 1000000000:
		divisor = 1000000000.0
		unit = "b"
	elif abs_value >= 1000000:
		divisor = 1000000.0
		unit = "m"
	var compact := float(abs_value) / divisor
	if compact < 10.0:
		return "%s%.1f%s" % [sign, compact, unit]
	return "%s%d%s" % [sign, int(round(compact)), unit]

func _build_skill_slots() -> void:
	for child in $Hud/SkillSlots.get_children():
		child.queue_free()
	skill_slot_ids = _current_skill_slot_ids()
	var has_skills := not skill_slot_ids.is_empty()
	$Hud/SkillSlots.visible = has_skills
	if has_node("Hud/SkillPanelTitle"):
		$Hud/SkillPanelTitle.visible = false
	for skill_id in skill_slot_ids:
		$Hud/SkillSlots.add_child(_build_hud_skill_card(skill_id))
	_layout_skill_slots()
	_update_skill_slots()

func _layout_skill_slots() -> void:
	var slots := get_node_or_null("Hud/SkillSlots") as GridContainer
	if slots == null:
		return
	var item_count := skill_slot_ids.size()
	var columns := mini(HUD_SKILL_DOCK_COLUMNS, maxi(item_count, 1))
	var rows := maxi(1, ceili(float(item_count) / float(HUD_SKILL_DOCK_COLUMNS)))
	var content_height := float(rows) * HUD_SKILL_SLOT_SIZE.y + float(rows - 1) * float(HUD_SKILL_DOCK_GAP)
	slots.columns = columns
	# Preserve the safe-area-adjusted bottom that may already have been applied
	# after the base runtime layout, then grow upward as skills wrap.
	slots.offset_top = slots.offset_bottom - content_height

func _build_hud_skill_card(skill_id: String) -> PanelContainer:
	var row := DataLoader.get_row("skills", skill_id)
	var lv := skills.level(skill_id)
	var max_lv := skills.max_level(skill_id)
	var card := PanelContainer.new()
	card.name = skill_id
	card.custom_minimum_size = HUD_SKILL_SLOT_SIZE
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.clip_contents = true
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(_on_hud_skill_slot_input.bind(skill_id))
	card.add_theme_stylebox_override("panel", _skill_card_style(lv, max_lv))
	card.tooltip_text = "%s %s\n%s" % [
		DataLoader.tr_key(str(row.get("name_key", skill_id))),
		LocalizationManager.text("等级%d") % lv,
		_skill_brief(skill_id, row, lv)
	]
	var stack := VBoxContainer.new()
	stack.name = "HBox"
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 1)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(stack)
	var icon_box := PanelContainer.new()
	icon_box.name = "IconBox"
	icon_box.custom_minimum_size = Vector2(72, 72)
	icon_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_box.add_theme_stylebox_override("panel", _skill_card_icon_style(lv, max_lv))
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(icon_box)
	if ResourceLoader.exists(str(row.get("icon", ""))):
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.texture = load(str(row.get("icon", "")))
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(66, 66)
		icon.size = Vector2(66, 66)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_box.add_child(icon)
	var lv_badge := Label.new()
	lv_badge.name = "LevelBadge"
	lv_badge.text = LocalizationManager.text("等级%d") % lv
	lv_badge.add_theme_font_size_override("font_size", UiKit.scaled_font_size(15))
	var badge_color := _skill_level_color(lv, max_lv)
	lv_badge.add_theme_color_override("font_color", badge_color)
	lv_badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lv_badge.add_theme_constant_override("outline_size", 3)
	lv_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lv_badge.custom_minimum_size = Vector2(92, 30)
	lv_badge.clip_text = true
	lv_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(lv_badge)
	return card

func _on_hud_skill_slot_input(event: InputEvent, skill_id: String) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			_begin_skill_hint_press("skill", skill_id)
		else:
			_end_skill_hint_press()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_skill_hint_press("skill", skill_id)
		else:
			_end_skill_hint_press()

func _skill_card_style(_lv: int, _max_lv: int) -> StyleBox:
	return UiKit.collection_card_texture_style(true)

func _skill_card_icon_style(lv: int, max_lv: int) -> StyleBox:
	return UiKit.icon_frame_texture_style(lv >= max_lv and lv > 0)

func _skill_level_color(lv: int, max_lv: int) -> Color:
	if lv >= max_lv and lv > 0:
		return Color(0.42, 0.92, 1.0)  # cyan when maxed
	if lv >= 3:
		return Color(0.85, 0.5, 1.0)  # purple for 3+
	if lv >= 2:
		return Color(1.0, 0.82, 0.32)  # gold for 2+
	if lv >= 1:
		return Color(0.92, 0.96, 1.0)  # white for 1
	return Color(0.6, 0.6, 0.6)  # gray for 0

func _skill_brief(skill_id: String, row: Dictionary, lv: int) -> String:
	return SkillEffectText.format_effect(SkillEffectText.effect_for_level(row, lv))

func _current_skill_slot_ids() -> Array[String]:
	# Show all owned skills in acquisition order. The HUD resizes icons
	# based on count, so there is no hard cap here.
	return skills.owned_order()

func _update_skill_slots() -> void:
	if not has_node("Hud/SkillSlots"):
		return
	var desired := _current_skill_slot_ids()
	if desired != skill_slot_ids:
		_build_skill_slots()
		return
	var has_skills := not skill_slot_ids.is_empty()
	$Hud/SkillSlots.visible = has_skills
	if has_node("Hud/SkillPanelTitle"):
		$Hud/SkillPanelTitle.visible = false
	_layout_skill_slots()
	for skill_id in skill_slot_ids:
		var slot := $Hud/SkillSlots.get_node_or_null(skill_id)
		if slot == null:
			continue
		var lv := skills.level(skill_id)
		var max_lv := skills.max_level(skill_id)
		var badge := slot.get_node_or_null("HBox/LevelBadge")
		if badge != null and badge is Label:
			(badge as Label).text = LocalizationManager.text("等级%d") % lv
			(badge as Label).add_theme_color_override("font_color", _skill_level_color(lv, max_lv))
		var row := DataLoader.get_row("skills", skill_id)
		if slot is Control:
			(slot as Control).tooltip_text = "%s %s\n%s" % [
				DataLoader.tr_key(str(row.get("name_key", skill_id))),
				LocalizationManager.text("等级%d") % lv,
				_skill_brief(skill_id, row, lv)
			]
		# Re-apply card border + icon border to reflect new level color
		slot.add_theme_stylebox_override("panel", _skill_card_style(lv, max_lv))
		var icon_box := slot.get_node_or_null("HBox/IconBox")
		if icon_box != null and icon_box is PanelContainer:
			(icon_box as PanelContainer).add_theme_stylebox_override("panel", _skill_card_icon_style(lv, max_lv))

func _show_wave_toast(text: String, color: Color) -> void:
	if paused:
		return
	var now := _now_seconds()
	var priority := _wave_toast_is_priority(text)
	if not priority and now - last_wave_toast_at < WAVE_TOAST_MIN_INTERVAL:
		pending_wave_toast = {"text": text, "color": color}
		if not pending_wave_toast_timer_active:
			pending_wave_toast_timer_active = true
			var delay := maxf(0.12, WAVE_TOAST_MIN_INTERVAL - (now - last_wave_toast_at))
			get_tree().create_timer(delay).timeout.connect(_flush_pending_wave_toast)
		return
	last_wave_toast_at = now
	_setup_wave_toast_banner()
	if wave_toast_banner == null or wave_toast_label == null:
		return
	if wave_toast_tween != null and wave_toast_tween.is_valid():
		wave_toast_tween.kill()
	var accent := color
	_layout_wave_toast(text)
	wave_toast_label.text = text
	UiKit.apply_label(wave_toast_label, _wave_toast_font_size(text), color, 5)
	wave_toast_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.82))
	wave_toast_label.add_theme_constant_override("shadow_offset_x", 0)
	wave_toast_label.add_theme_constant_override("shadow_offset_y", 3)
	var accent_line := wave_toast_banner.get_node_or_null("AccentLine") as TextureRect
	if accent_line != null:
		accent_line.modulate = Color(accent.r, accent.g, accent.b, 0.95)
	var target_position := _wave_toast_target_position()
	wave_toast_banner.visible = true
	wave_toast_banner.position = target_position + Vector2(0, 18)
	wave_toast_banner.scale = Vector2(0.92, 0.92)
	wave_toast_banner.modulate = Color(1, 1, 1, 0.0)
	wave_toast_tween = wave_toast_banner.create_tween()
	wave_toast_tween.tween_property(wave_toast_banner, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	wave_toast_tween.parallel().tween_property(wave_toast_banner, "position", target_position, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	wave_toast_tween.parallel().tween_property(wave_toast_banner, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	wave_toast_tween.tween_interval(0.82)
	wave_toast_tween.tween_property(wave_toast_banner, "modulate:a", 0.0, 0.28)
	wave_toast_tween.parallel().tween_property(wave_toast_banner, "scale", Vector2(1.04, 1.04), 0.28)
	wave_toast_tween.tween_callback(func() -> void:
		wave_toast_banner.visible = false
		wave_toast_banner.modulate.a = 1.0
		wave_toast_banner.scale = Vector2.ONE
		wave_toast_banner.position = target_position
	)

func _wave_toast_is_priority(text: String) -> bool:
	if text.length() > 18:
		return true
	return text.contains("首领") or text.contains("防线") or text.contains("基地") or text.contains("最终") or text.contains("强度提升")

func _flush_pending_wave_toast() -> void:
	pending_wave_toast_timer_active = false
	if pending_wave_toast.is_empty() or paused or battle_finished:
		pending_wave_toast = {}
		return
	var toast := pending_wave_toast.duplicate()
	pending_wave_toast = {}
	var toast_color: Color = toast.get("color", Color(1.0, 0.82, 0.25))
	_show_wave_toast(str(toast.get("text", "")), toast_color)

func _hide_wave_toast() -> void:
	if wave_toast_tween != null and wave_toast_tween.is_valid():
		wave_toast_tween.kill()
	if wave_toast_banner != null and is_instance_valid(wave_toast_banner):
		wave_toast_banner.visible = false
		wave_toast_banner.modulate = Color.WHITE
		wave_toast_banner.scale = Vector2.ONE
		wave_toast_banner.position = _wave_toast_target_position()
	pending_wave_toast = {}

func _wave_toast_font_size(text: String) -> int:
	if text.length() <= 7:
		return 22
	if text.length() <= 13:
		return 20
	return 18

func _layout_wave_toast(text: String) -> void:
	var long_text := text.length() > 13
	var size := WAVE_TOAST_LONG_SIZE if long_text else WAVE_TOAST_SIZE
	wave_toast_banner.size = size
	wave_toast_banner.pivot_offset = size * 0.5
	wave_toast_banner.position = _wave_toast_target_position()
	var band := wave_toast_banner.get_node_or_null("Band") as TextureRect
	if band != null:
		band.position = Vector2.ZERO
		band.size = size
	wave_toast_label.position = Vector2(34, 2)
	wave_toast_label.size = size - Vector2(68, 22)
	wave_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if long_text else TextServer.AUTOWRAP_OFF
	wave_toast_label.clip_text = true
	var accent_line := wave_toast_banner.get_node_or_null("AccentLine") as TextureRect
	if accent_line != null:
		var line_w := size.x * 0.46
		accent_line.size = Vector2(line_w, 3)
		accent_line.position = Vector2((size.x - line_w) * 0.5, size.y - 15.0)

func _show_onboarding_tip() -> void:
	if onboarding_tip_shown:
		return
	onboarding_tip_shown = true
	var text := ""
	match onboarding_stage:
		"aim_and_first_card":
			text = "自动开火｜按住战场拖动：手动瞄准\n双击僵尸：锁定集火"
		"split_swarm":
			text = "经验满后选择技能卡：清群拿分裂/多重，漏怪拿减速/追踪。"
		"runner_priority":
			text = "高速单位弱冰，减速和追踪能更稳地压住漏怪。"
		"tank_burst":
			text = "重甲和支援要点名处理，锁定后配穿透更稳。"
		"first_boss":
			text = "首领有弱点和护甲阶段，优先拿穿透、蓄能和克制元素。"
		_:
			if wave_index <= 1:
				text = "本关主弱点：%s。命中弱点会获得额外伤害。" % _element_name(primary_weakness)
	if text == "":
		return
	_show_wave_toast(text, Color(0.72, 0.92, 1.0))

func _update_objective_panel() -> void:
	if not has_node("Hud/ObjectivePanel/Body"):
		return
	$Hud/ObjectivePanel.visible = false
	var title: Label = $Hud/ObjectivePanel/Title
	var body: Label = $Hud/ObjectivePanel/Body
	title.text = "目标 · %s · 弱%s" % [DataLoader.level_display_name(level_id), _element_name(primary_weakness)]
	body.text = _battle_objective_text()
	if loadout_power_ratio < CLEAR_LINE_WARNING_RATIO:
		body.text += "  低于本关通关线，可能守不住防线。"
	elif _current_loadout_hits_weakness():
		body.text += "  当前配装命中弱点。"

func _battle_objective_text() -> String:
	var tags: Array = level.get("threat_tags", [])
	if tags.has("fast"):
		return "高速单位会冲线：优先拿减速/追踪，稳住防线。"
	if tags.has("tank"):
		return "厚血推进：锁定精英，优先穿透/蓄能/暴击。"
	if tags.has("support"):
		return "支援会放大尸潮：点名处理，再清小怪。"
	if tags.has("burst"):
		return "爆发威胁高：留屏障和控制，别让近线爆开。"
	for wave in level.get("waves", []):
		if wave.has("boss"):
			return "首领关：先清支援，再集中破甲打弱点。"
	return "守住防线，围绕当前武器快速成型。"

func _current_loadout_hits_weakness() -> bool:
	var weapon := DataLoader.get_row("weapons", weapon_id)
	return str(weapon.get("element", "")) == primary_weakness

func _show_wave_tip(wave: Dictionary) -> void:
	var key := "wave_%d" % wave_index
	if wave_tip_shown.has(key):
		return
	wave_tip_shown[key] = true
	var text := ""
	if wave.has("boss"):
		text = "首领波：先清支援，锁定首领破甲。"
	else:
		var wave_tags: Array = level.get("threat_tags", [])
		if wave_tags.has("fast") and wave_index == 1:
			text = "提示：高速怪接近防线时，减速和追踪更可靠。"
		elif wave_tags.has("tank") and wave_index == 1:
			text = "提示：厚血怪别分散火力，锁定后穿透收益更高。"
		elif wave_tags.has("support") and wave_index == 1:
			text = "提示：支援单位出现时优先点名。"
		elif wave_index == 1:
			text = "提示：优先拿清群技能，尽快形成第一套火力。"
	if text != "":
		call_deferred("_show_wave_toast", text, Color(0.78, 0.92, 1.0))

func _build_debug_text() -> String:
	var enemies := $EnemyLayer.get_children()
	var lines: Array[String] = []
	lines.append("level=%s  wave=%d/%d  hp=%d/%d  gold=%d  xp=%d/%d  cards=%s  reroll=%d" % [
		level_id, wave_index, wave_total, base_hp, base_hp_max, gold, xp, next_xp_offer, str(skills.owned), reroll_charges
	])
	lines.append("strategy=%s  locked=%s  enemies=%d" % [
		target_manager.strategy, str(target_manager.has_lock()), enemies.size()
	])
	var top_score := -INF
	var top_enemy: Node = null
	var turret_pos := _weapon_fire_origin(false)
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.has_method("targeting_snapshot"):
			continue
		var snap: Dictionary = enemy.targeting_snapshot()
		var s := target_manager.score_enemy(snap, turret_pos)
		if s > top_score:
			top_score = s
			top_enemy = enemy
	if top_enemy:
		lines.append("top target score=%.1f id=%s y=%.0f" % [top_score, top_enemy.name, top_enemy.global_position.y])
	return "\n".join(lines)

func _apply_slow_field(enemies: Array = []) -> void:
	var slow_level := skills.level("skill_slow_field")
	if slow_level <= 0:
		slow_field_sfx_level = 0
		_update_slow_field_visual(0)
		return
	if slow_level != slow_field_sfx_level:
		slow_field_sfx_level = slow_level
		AudioManager.play_sfx("skill_slow_field", -8.0, 0.02)
	var candidates := enemies if not enemies.is_empty() else $EnemyLayer.get_children()
	for enemy in candidates:
		if enemy.has_method("targeting_snapshot"):
			var is_boss := bool(enemy.get("boss"))
			var slow_mult := skills.slow_mult_for_y(enemy.global_position.y, _base_line_y(), is_boss)
			if slow_mult < 1.0:
				slow_mult = max(skills.slow_speed_floor(is_boss), 1.0 - (1.0 - slow_mult) * slow_strength_bonus)
				if enemy.has_method("mark_ice_slow_visual"):
					enemy.mark_ice_slow_visual(0.18)
			enemy.speed_mult *= slow_mult
	_update_slow_field_visual(slow_level)

func _spawn_slow_field_visual() -> void:
	slow_field_rect = TextureRect.new()
	slow_field_rect.name = "SlowFieldSurfaceTiles"
	slow_field_rect.texture = SLOW_FIELD_SURFACE_TEXTURE
	slow_field_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slow_field_rect.stretch_mode = TextureRect.STRETCH_TILE
	slow_field_rect.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	slow_field_rect.position = Vector2(0, 0)
	slow_field_rect.size = Vector2(1080, 512)
	slow_field_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slow_field_rect.visible = false
	slow_field_rect.z_index = 2
	var field_material := ShaderMaterial.new()
	field_material.shader = SLOW_FIELD_SHADER
	field_material.set_shader_parameter("field_color", Color(0.3, 0.8, 1.0, 0.0))
	field_material.set_shader_parameter("intensity", 0.0)
	field_material.set_shader_parameter("secondary_opacity", 0.28)
	field_material.set_shader_parameter("zone_fill_opacity", 0.0)
	slow_field_rect.material = field_material
	$SlowFieldLayer.add_child(slow_field_rect)

	slow_field_boundary = TextureRect.new()
	slow_field_boundary.name = "SlowFieldZoneBoundary"
	slow_field_boundary.texture = SLOW_FIELD_BOUNDARY_TEXTURE
	slow_field_boundary.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slow_field_boundary.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slow_field_boundary.position = Vector2(0.0, 0.0)
	slow_field_boundary.size = SLOW_FIELD_BOUNDARY_SIZE
	slow_field_boundary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slow_field_boundary.visible = false
	slow_field_boundary.z_index = 5
	var boundary_level_material := ShaderMaterial.new()
	boundary_level_material.shader = SLOW_FIELD_BOUNDARY_LEVEL_SHADER
	boundary_level_material.set_shader_parameter("slope_compensation_px", SLOW_FIELD_BOUNDARY_SLOPE_COMPENSATION_PX)
	boundary_level_material.set_shader_parameter("gameplay_seam_y_px", SLOW_FIELD_BOUNDARY_ANCHOR_Y)
	boundary_level_material.set_shader_parameter("gameplay_seam_opacity", SLOW_FIELD_BOUNDARY_SEAM_OPACITY)
	slow_field_boundary.material = boundary_level_material
	$SlowFieldLayer.add_child(slow_field_boundary)

	slow_field_particles = GPUParticles2D.new()
	slow_field_particles.name = "SlowFieldSnowCrystals"
	slow_field_particles.process_mode = Node.PROCESS_MODE_PAUSABLE
	slow_field_particles.amount = SLOW_FIELD_SNOW_MIN_AMOUNT
	slow_field_particles.lifetime = 1.85
	slow_field_particles.preprocess = 1.2
	slow_field_particles.randomness = 0.84
	slow_field_particles.local_coords = false
	# Reuse the authored crystalline impact artwork at a small scale. The old
	# radial-glow dots disappeared against bright battlefields and did not read
	# as snow.
	slow_field_particles.texture = SLOW_FIELD_SNOW_TEXTURE
	slow_field_particles.material = _new_muzzle_additive_material()
	slow_field_particles.z_index = 6
	slow_field_particles.visibility_rect = Rect2(-620.0, -260.0, 1240.0, 520.0)
	slow_field_particles.emitting = false
	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(520.0, 46.0, 0.0)
	process_material.direction = Vector3(0.0, -1.0, 0.0)
	process_material.spread = 180.0
	process_material.initial_velocity_min = 14.0
	process_material.initial_velocity_max = 62.0
	process_material.gravity = Vector3(0.0, -14.0, 0.0)
	process_material.damping_min = 6.0
	process_material.damping_max = 18.0
	process_material.angle_min = -180.0
	process_material.angle_max = 180.0
	process_material.angular_velocity_min = -72.0
	process_material.angular_velocity_max = 72.0
	process_material.scale_min = 0.028
	process_material.scale_max = 0.075
	process_material.scale_curve = _impact_cloud_scale_curve()
	process_material.color_ramp = _impact_color_ramp(Color(0.92, 1.0, 1.0, 0.72), Color(0.48, 0.9, 1.0, 0.38), Color(0.3, 0.74, 1.0, 0.0))
	slow_field_particles.process_material = process_material
	$SlowFieldLayer.add_child(slow_field_particles)

func _update_slow_field_visual(slow_level: int) -> void:
	if slow_field_rect == null:
		return
	if slow_level <= 0:
		slow_field_rect.visible = false
		if slow_field_boundary != null:
			slow_field_boundary.visible = false
		if slow_field_particles != null:
			slow_field_particles.emitting = false
			slow_field_particles.visible = false
		return
	var y_min := _slow_field_min_y_for_level(slow_level)
	var slow_pct := _slow_field_strength_for_level(slow_level)
	slow_field_rect.position = Vector2(0, y_min)
	var field_height := maxf(_base_line_y() - y_min, 60.0)
	slow_field_rect.size = Vector2(1080, field_height)
	slow_field_rect.visible = true
	var field_color := Color(0.3, 0.8, 1.0, 0.13 + slow_pct * 0.20)
	var shader_material := slow_field_rect.material as ShaderMaterial
	if shader_material != null:
		shader_material.set_shader_parameter("field_color", field_color)
		shader_material.set_shader_parameter("intensity", 0.82 + slow_pct * 1.05)
		shader_material.set_shader_parameter("secondary_opacity", 0.34 + slow_pct * 0.28)
		shader_material.set_shader_parameter("zone_fill_opacity", 0.22 + slow_pct * 0.10)
	if slow_field_boundary != null:
		slow_field_boundary.position = Vector2(0.0, y_min - SLOW_FIELD_BOUNDARY_ANCHOR_Y)
		slow_field_boundary.size = SLOW_FIELD_BOUNDARY_SIZE
		slow_field_boundary.modulate = Color(0.82, 0.93, 1.0, clampf(0.48 + slow_pct * 0.54, 0.0, 0.82))
		slow_field_boundary.visible = true
	_update_slow_field_particles(y_min, field_height, slow_pct, slow_level)

func _update_slow_field_particles(y_min: float, field_height: float, slow_pct: float, slow_level: int) -> void:
	if slow_field_particles == null:
		return
	slow_field_particles.visible = true
	slow_field_particles.global_position = Vector2(540.0, y_min + field_height * 0.5)
	# Range expands with level, so particle count must grow with field area as
	# well as level; otherwise the snow becomes visibly sparser at Lv4/Lv5.
	slow_field_particles.amount = clampi(
		int(round(field_height * 0.08)) + slow_level * 8,
		SLOW_FIELD_SNOW_MIN_AMOUNT,
		SLOW_FIELD_SNOW_MAX_AMOUNT
	)
	slow_field_particles.emitting = true
	var process_material := slow_field_particles.process_material as ParticleProcessMaterial
	if process_material == null:
		return
	process_material.emission_box_extents = Vector3(520.0, maxf(field_height * 0.42, 34.0), 0.0)
	process_material.initial_velocity_min = 14.0 + slow_pct * 22.0
	process_material.initial_velocity_max = 58.0 + slow_pct * 54.0
	process_material.gravity = Vector3(0.0, -12.0 - slow_pct * 26.0, 0.0)

func _spawn_barrier_visual() -> void:
	barrier_visual = Node2D.new()
	barrier_visual.name = "BarrierGlass"
	barrier_visual.position = Vector2(540, _base_line_y())
	barrier_visual.visible = false
	barrier_visual.z_index = BARRIER_VISUAL_Z
	$SlowFieldLayer.add_child(barrier_visual)

	barrier_sprite = Sprite2D.new()
	barrier_sprite.name = "RenderedShield"
	barrier_sprite.texture = BARRIER_GLASS_TEXTURE
	barrier_sprite.centered = true
	barrier_visual.add_child(barrier_sprite)
	_update_barrier_visual()

func _barrier_charge_count() -> int:
	return breach_shields + skill_barriers_left

func _update_barrier_visual() -> void:
	if barrier_visual == null or barrier_sprite == null:
		return
	var charges := _barrier_charge_count()
	var skill_level := skills.level("skill_barrier")
	# The persistent glass wall belongs to the Defense Barrier card. Armor breach
	# interception is a separate one-hit equipment effect and must not make the
	# battle look as though the card was already learned at stage start.
	var has_barrier := skill_level > 0
	barrier_visual.visible = has_barrier
	if not has_barrier:
		return
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 240.0)
	var hp_ratio := clampf(float(base_hp) / float(maxi(base_hp_max, 1)), 0.0, 1.0)
	var alpha := clampf(0.4 + float(charges) * 0.08 + float(skill_level) * 0.035 + hp_ratio * 0.05 + pulse * 0.07, 0.44, 0.82)
	barrier_sprite.modulate = Color(0.86, 0.98, 1.0, alpha)

func _spawn_barrier_gain_vfx() -> void:
	_update_barrier_visual()
	if barrier_visual == null:
		return
	var color := Color(0.66, 0.92, 1.0, 0.76)
	var glow := VfxLib.spawn_glow($SlowFieldLayer, barrier_visual.global_position, color, 360.0, 0.26)
	if glow != null:
		_track_transient_fx(glow, "projectile")
	_spawn_barrier_shell_pulse(barrier_visual.global_position, 430.0, Color(0.58, 0.9, 1.0, 0.46), 0.3)
	_spawn_barrier_shell_pulse(barrier_visual.global_position + Vector2(0, -10), 310.0, Color(0.9, 1.0, 1.0, 0.36), 0.22)
	_spawn_impact_shock_ring(barrier_visual.global_position, Color(0.66, 0.94, 1.0, 0.52), 430.0, 7.0, 0.26, true)
	var motes := VfxLib.spawn_particles($SlowFieldLayer, barrier_visual.global_position + Vector2(0, -12), Color(0.76, 0.96, 1.0, 0.62), 18, 240.0, 120.0, 0.32)
	if motes != null:
		_track_transient_fx(motes, "projectile")
	var tween := barrier_visual.create_tween()
	barrier_visual.scale = Vector2(0.98, 0.98)
	tween.tween_property(barrier_visual, "scale", Vector2(1.025, 1.025), 0.09)
	tween.tween_property(barrier_visual, "scale", Vector2.ONE, 0.12)

func _spawn_barrier_break_vfx(hit_position: Vector2) -> void:
	var color := Color(0.78, 0.96, 1.0, 0.82)
	_spawn_b4_impact_stack(hit_position, "ice", 1.16, "shield", true)
	_spawn_barrier_shell_pulse(hit_position, 174.0, Color(0.76, 0.96, 1.0, 0.48), 0.22)
	var glow := VfxLib.spawn_glow($SlowFieldLayer, hit_position, color, 210.0, 0.22)
	if glow != null:
		_track_transient_fx(glow, "projectile")
	var shards := clampi(12 + _barrier_charge_count() * 2, 12, 18)
	for i in range(shards):
		if not _can_spawn_projectile_fx(true):
			break
		var drift := Vector2(randf_range(-140.0, 140.0), randf_range(-128.0, 72.0))
		if drift.length_squared() <= 1.0:
			drift = Vector2.RIGHT.rotated(randf_range(-PI, PI)) * 90.0
		var shard := Sprite2D.new()
		_track_transient_fx(shard, "projectile")
		shard.name = "BarrierEnergyShard"
		shard.texture = VfxLib.STREAK_TEXTURE
		shard.centered = true
		shard.global_position = hit_position + Vector2(randf_range(-72.0, 72.0), randf_range(-28.0, 22.0))
		shard.rotation = drift.angle() + randf_range(-0.36, 0.36)
		shard.scale = Vector2(randf_range(0.16, 0.32), randf_range(0.035, 0.075))
		shard.modulate = Color(0.72, 0.96, 1.0, randf_range(0.52, 0.78))
		shard.material = _new_muzzle_core_material(shard.modulate, 2.8, 1.0)
		shard.z_index = 8
		$SlowFieldLayer.add_child(shard)
		var tween := shard.create_tween()
		tween.set_trans(Tween.TRANS_QUINT)
		tween.set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(shard, "global_position", shard.global_position + drift, 0.34)
		tween.parallel().tween_property(shard, "rotation", shard.rotation + randf_range(-1.4, 1.4), 0.34)
		tween.parallel().tween_property(shard, "scale", shard.scale * randf_range(0.28, 0.46), 0.34)
		tween.parallel().tween_property(shard, "modulate:a", 0.0, 0.34)
		tween.tween_callback(shard.queue_free)
	var burst := VfxLib.spawn_burst($SlowFieldLayer, hit_position, color, 24, 460.0, 116.0, 0.32)
	if burst != null:
		_track_transient_fx(burst, "projectile")
	VfxLib.screen_shake(4.0, 0.075)

func _spawn_barrier_shell_pulse(origin: Vector2, radius: float, color: Color, duration: float) -> void:
	if not _can_spawn_projectile_fx(true):
		return
	var shell := Node2D.new()
	_track_transient_fx(shell, "projectile")
	shell.name = "BarrierEnergyShell"
	shell.process_mode = Node.PROCESS_MODE_PAUSABLE
	shell.global_position = origin
	shell.scale = Vector2(0.82, 0.18)
	shell.z_index = 7
	$SlowFieldLayer.add_child(shell)
	var line := _make_ring_line(radius, color, 5.0, 96)
	line.texture = VfxLib.STREAK_TEXTURE
	line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	line.material = _new_muzzle_additive_material()
	shell.add_child(line)
	var inner := _make_ring_line(radius * 0.72, Color(color.r, color.g, color.b, color.a * 0.55), 2.6, 96)
	inner.texture = VfxLib.STREAK_TEXTURE
	inner.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	inner.material = _new_muzzle_additive_material()
	shell.add_child(inner)
	var tween := shell.create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(shell, "scale", Vector2(1.08, 0.32), duration)
	tween.parallel().tween_property(shell, "modulate:a", 0.0, duration)
	tween.parallel().tween_property(line, "width", 1.2, duration)
	tween.parallel().tween_property(inner, "width", 0.8, duration)
	tween.tween_callback(shell.queue_free)

func _show_card_offer() -> void:
	_set_turret_fire_enabled(false)
	_hide_skill_hint()
	_render_card_offer(skills.owned)
	var cards := $Hud/CardPanel/Cards
	if cards.get_child_count() == 0:
		_close_card_offer(false)
		return
	_set_card_offer_pause_active(true)
	AudioManager.play_sfx("card_offer")
	AudioManager.play_sfx("level_up", -2.0, 0.02)
	_spawn_levelup_vfx(Vector2(540, 1580.0 + bottom_dock_shift), Color(0.7, 0.95, 1.0))
	$Hud/CardPanel/CardTitle.text = _card_offer_title()
	UiKit.apply_label($Hud/CardPanel/CardTitle, 29 if LocalizationManager.is_english() else 34, UiKit.TEXT_MAIN, 4)
	$Hud/CardPanel.visible = true
	_animate_card_panel_in()

func _card_offer_title() -> String:
	var tags: Array = level.get("threat_tags", [])
	if tags.has("fast"):
		return "选择强化 · 优先减速 / 追踪"
	if tags.has("tank") or tags.has("boss"):
		return "选择强化 · 优先穿透 / 蓄能"
	if tags.has("support"):
		return "选择强化 · 优先锁定 / 连锁"
	if tags.has("breach"):
		return "选择强化 · 优先清群 / 防线"
	return "选择强化 · 围绕当前武器成型"

func _animate_card_panel_in(delay := 0.0) -> void:
	var panel: Control = $Hud/CardPanel
	panel.scale = Vector2(0.94, 0.94)
	panel.modulate.a = 0.0
	var tween := panel.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.14)

func _render_card_offer(owned_snapshot: Dictionary) -> void:
	var cards: VBoxContainer = $Hud/CardPanel/Cards
	# queue_free() alone keeps the outgoing controls parented until the end of
	# the frame. A reroll (or a new offer opened on that same frame) would then
	# make the height pass count both the old and new trios, stretching the modal
	# to the battlefield cap even though only the new three cards survive to the
	# rendered frame. Detach first so layout always measures one authoritative
	# generation of cards, independent of deferred deletion order.
	for child in cards.get_children():
		cards.remove_child(child)
		child.queue_free()
	$Hud/CardPanel/DetailOverlay.visible = false
	_set_card_offer_base_content_visible(true)
	for skill_id in card_director.offer(level, owned_snapshot):
		var row := DataLoader.get_row("skills", skill_id)
		var name := DataLoader.tr_key(row.get("name_key", skill_id))
		var lv := _skill_offer_level(skill_id)
		cards.add_child(_build_skill_card(skill_id, row, name, lv))
	_refresh_card_offer_dynamic_layout()
	# Theme/font minimum sizes settle after parenting. Re-measure once on the
	# deferred pass so the first rendered frame and later locale/font changes use
	# the real chip and wrapped-text geometry rather than construction-time zeros.
	call_deferred("_refresh_card_offer_dynamic_layout")
	var reroll_label: Label = $Hud/CardPanel/RerollButton/RerollLabel
	reroll_label.text = "重抽 (%d)" % reroll_charges
	UiKit.apply_armored_texture_button($Hud/CardPanel/RerollButton as TextureButton, true, Vector2(412, 88), reroll_charges > 0)
	UiKit.apply_armored_texture_button($Hud/CardPanel/SkipButton as TextureButton, false, Vector2(412, 88), true)
	UiKit.apply_label(reroll_label, 25, UiKit.TEXT_MAIN if reroll_charges > 0 else UiKit.GREY_300, 3)
	var skip_label := $Hud/CardPanel/SkipButton/SkipLabel as Label
	UiKit.apply_label(skip_label, 25, UiKit.TEXT_MAIN, 3)

func _skill_offer_level(skill_id: String) -> int:
	return skills.level_after_add(skill_id)

func _refresh_card_offer_dynamic_layout() -> void:
	var cards := get_node_or_null("Hud/CardPanel/Cards") as VBoxContainer
	if cards == null:
		return
	for child in cards.get_children():
		if child is Panel:
			_layout_skill_offer_card(child as Panel)
	_fit_card_offer_panel_to_cards()

func _fit_card_offer_panel_to_cards() -> void:
	var panel := get_node_or_null("Hud/CardPanel") as Panel
	var cards := get_node_or_null("Hud/CardPanel/Cards") as VBoxContainer
	if panel == null or cards == null:
		return
	var content_h := 0.0
	var visible_cards := 0
	for child in cards.get_children():
		if not child is Control or not (child as Control).visible:
			continue
		content_h += (child as Control).custom_minimum_size.y
		visible_cards += 1
	if visible_cards > 1:
		content_h += float(cards.get_theme_constant("separation")) * float(visible_cards - 1)
	# Keep a full 62px quiet lane between the final card and the primary actions.
	# The panel may grow up to the real battlefield bounds, never over the base or
	# the hero model. This lets translated/wrapped card copy own its actual height.
	# Store the measured card stack too: the container must collapse to exactly the
	# three cards, otherwise the leftover panel space becomes a blank region between
	# the final card and the primary actions.
	panel.set_meta("card_offer_cards_height", content_h)
	panel.set_meta("card_offer_content_height", CARD_OFFER_CARDS_POS.y + content_h + CARD_OFFER_ACTION_GAP + CARD_OFFER_ACTION_LANE_HEIGHT)
	_layout_card_offer_panel()

func _build_skill_card(skill_id: String, row: Dictionary, display_name: String, lv: int) -> Panel:
	var stats_text := SkillEffectText.format_offer_block(row, lv, skills.level(skill_id))
	var card_h := CARD_OFFER_CARD_BASE_HEIGHT
	var card := Panel.new()
	# Runtime audits select from the exact cards rendered by the live director.
	# The metadata is inert in player builds, but keeps headless probes from
	# duplicating the offer/filtering rules in a second implementation.
	card.set_meta("skill_id", skill_id)
	card.custom_minimum_size = Vector2(CARD_OFFER_CARD_WIDTH, card_h)
	card.clip_contents = true
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(_on_skill_card_input.bind(skill_id))
	card.mouse_entered.connect(_show_skill_hint_for_skill.bind(skill_id))
	card.mouse_exited.connect(_hide_skill_hint)
	var accent := _skill_card_accent(skill_id, row)
	card.add_theme_stylebox_override("panel", UiKit.collection_card_texture_style(true))

	var accent_bar := TextureRect.new()
	accent_bar.position = Vector2(0, 0)
	accent_bar.size = Vector2(12, card_h)
	accent_bar.texture = load("res://assets/production/sprites/ui/ui_map_accent_strip.png")
	accent_bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	accent_bar.stretch_mode = TextureRect.STRETCH_SCALE
	accent_bar.modulate = accent
	accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(accent_bar)

	var icon_box := PanelContainer.new()
	icon_box.name = "IconFrame"
	icon_box.position = CARD_OFFER_ICON_FRAME_POS
	icon_box.size = CARD_OFFER_ICON_FRAME_SIZE
	icon_box.add_theme_stylebox_override("panel", UiKit.icon_frame_texture_style(true))
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon_box)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = load(row.get("icon", ""))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = CARD_OFFER_ICON_POS
	icon.size = CARD_OFFER_ICON_SIZE
	icon.custom_minimum_size = CARD_OFFER_ICON_SIZE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon)

	var title := Label.new()
	title.name = "Title"
	title.text = display_name
	title.position = Vector2(CARD_OFFER_TEXT_X, 20)
	title.size = Vector2(292.0, 60)
	var title_font_size := 24 if LocalizationManager.is_english() else 28
	UiKit.apply_label(title, title_font_size, Color(0.96, 0.99, 1.0, 1.0), 3)
	title.clip_text = true
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(title)
	# Enlarging and moving the icon preserves the card's hierarchy, while long
	# English skill names may step down slightly inside the fixed title lane.
	UiKit.fit_label_text(
		title,
		UiKit.scaled_font_size(title_font_size),
		UiKit.scaled_font_size(20 if LocalizationManager.is_english() else 24),
		2.0,
		2.0
	)

	var level_badge := PanelContainer.new()
	level_badge.name = "LevelBadge"
	level_badge.position = Vector2(552, 36)
	level_badge.size = Vector2(110, 34)
	level_badge.add_theme_stylebox_override("panel", UiKit.pill_style(UiKit.CYAN, Color(0.02, 0.045, 0.065, 0.86)))
	level_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(level_badge)
	var level_text := UiKit.label("等级 %d" % lv, 14, Color(0.82, 0.96, 1.0, 1.0), 2)
	level_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_badge.add_child(level_text)

	var reason := _skill_recommendation_reason(skill_id, row)
	if reason != "":
		var badge := PanelContainer.new()
		badge.name = "RecommendBadge"
		badge.add_theme_stylebox_override("panel", UiKit.pill_style(UiKit.GOLD, Color(0.14, 0.09, 0.015, 0.9)))
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(badge)
		var badge_text := UiKit.label("推荐 · %s" % reason, 12, UiKit.GOLD, 2)
		badge_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge_text.clip_text = false
		badge.add_child(badge_text)
		var badge_width := maxf(152.0, ceil(badge_text.get_combined_minimum_size().x + 28.0))
		badge.position = Vector2(CARD_OFFER_TEXT_X + CARD_OFFER_TEXT_WIDTH - badge_width, 36)
		badge.size = Vector2(badge_width, 34)

	var stats := Label.new()
	stats.name = "Stats"
	stats.text = stats_text
	stats.position = Vector2(CARD_OFFER_TEXT_X, 86)
	stats.size = Vector2(CARD_OFFER_TEXT_WIDTH, 54)
	UiKit.apply_label(stats, 18, UiKit.CYAN, 2)
	stats.add_theme_constant_override("line_spacing", 6)
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(stats)

	var desc := Label.new()
	desc.name = "Desc"
	# Resolve the locale before TextServer measures wrapping. Leaving the Chinese
	# source for automatic late translation could clip the last English glyph at
	# the right edge after this card's icon/text geometry changed.
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.text = LocalizationManager.text(_skill_short_desc(skill_id, lv))
	desc.position = Vector2(CARD_OFFER_TEXT_X, 150)
	desc.size = Vector2(CARD_OFFER_TEXT_WIDTH, 76)
	# English short descriptions are materially longer than their Chinese peers.
	# A 12 pt authored size still renders at the mobile UI scale while keeping the
	# longest description in the intended two-line lane beside the enlarged icon.
	UiKit.apply_label(desc, 12 if LocalizationManager.is_english() else 17, Color(0.78, 0.9, 0.96, 1.0), 2)
	if LocalizationManager.is_english():
		var balanced_desc := _balanced_card_desc_lines(desc.text, desc.get_theme_font("font"), desc.get_theme_font_size("font_size"))
		if balanced_desc.contains("\n"):
			desc.text = balanced_desc
			desc.autowrap_mode = TextServer.AUTOWRAP_OFF
	desc.add_theme_constant_override("line_spacing", 5)
	desc.clip_text = true
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(desc)

	var tags := HBoxContainer.new()
	tags.name = "Tags"
	tags.position = Vector2(CARD_OFFER_TEXT_X, card_h - 78.0)
	tags.size = Vector2(CARD_OFFER_TEXT_WIDTH, 30)
	tags.add_theme_constant_override("separation", 8)
	tags.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(tags)
	for tag in row.get("card_tags", []).slice(0, 3):
		tags.add_child(_card_tag_chip(str(tag), accent))
	_layout_skill_offer_card(card)

	return card

func _wrapped_label_required_height(label: Label, width: float, minimum_height: float) -> float:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	if font == null or font_size <= 0:
		return minimum_height
	var text_width := maxf(1.0, width - 8.0)
	var measured := font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, text_width, font_size)
	var line_height := maxf(1.0, font.get_height(font_size))
	var line_count := maxi(1, int(ceil(measured.y / line_height)))
	var line_spacing := label.get_theme_constant("line_spacing")
	# Font measurement already owns the glyph box. Four extra pixels protect the
	# two-pixel outline without reserving a phantom half-line on every wrapped
	# lane; that headroom matters when three long localized cards share one modal.
	var required := measured.y + float(maxi(0, line_count - 1) * line_spacing) + 4.0
	return ceil(maxf(minimum_height, required))

func _layout_skill_offer_card(card: Panel) -> void:
	var stats := card.get_node_or_null("Stats") as Label
	var desc := card.get_node_or_null("Desc") as Label
	var tags := card.get_node_or_null("Tags") as HBoxContainer
	var accent_bar := card.get_child(0) as TextureRect if card.get_child_count() > 0 else null
	if stats == null or desc == null or tags == null:
		return
	# Every vertical lane is derived from the measured lane above it. Explicit
	# newlines and automatic wrapping therefore follow the same path, so no skill,
	# level or locale needs a one-off y offset.
	var stats_h := _wrapped_label_required_height(stats, CARD_OFFER_TEXT_WIDTH, 54.0)
	stats.position = Vector2(CARD_OFFER_TEXT_X, CARD_OFFER_COPY_TOP_Y)
	stats.size = Vector2(CARD_OFFER_TEXT_WIDTH, stats_h)
	var desc_h := _wrapped_label_required_height(desc, CARD_OFFER_TEXT_WIDTH, 48.0)
	desc.position = Vector2(CARD_OFFER_TEXT_X, stats.position.y + stats_h + CARD_OFFER_COPY_GAP)
	desc.size = Vector2(CARD_OFFER_TEXT_WIDTH, desc_h)
	var tag_h := maxf(CARD_OFFER_TAG_MIN_HEIGHT, tags.get_combined_minimum_size().y)
	tags.position = Vector2(CARD_OFFER_TEXT_X, desc.position.y + desc_h + CARD_OFFER_COPY_GAP)
	tags.size = Vector2(CARD_OFFER_TEXT_WIDTH, tag_h)
	var icon_bottom := CARD_OFFER_ICON_FRAME_POS.y + CARD_OFFER_ICON_FRAME_SIZE.y + CARD_OFFER_BOTTOM_PADDING
	var copy_bottom := tags.position.y + tag_h + CARD_OFFER_BOTTOM_PADDING
	var measured_card_h: float = ceil(maxf(CARD_OFFER_CARD_BASE_HEIGHT, maxf(icon_bottom, copy_bottom)))
	card.custom_minimum_size = Vector2(CARD_OFFER_CARD_WIDTH, measured_card_h)
	card.size = card.custom_minimum_size
	if accent_bar != null:
		accent_bar.size = Vector2(12.0, measured_card_h)

func _balanced_card_desc_lines(value: String, font: Font, font_size: int) -> String:
	var words := value.split(" ", false)
	if words.size() < 2 or font == null:
		return value
	var best_text := value
	var best_width := INF
	for split_index in range(1, words.size()):
		var first_line := " ".join(words.slice(0, split_index))
		var second_line := " ".join(words.slice(split_index))
		var widest := maxf(
			font.get_string_size(first_line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x,
			font.get_string_size(second_line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
		)
		if widest < best_width:
			best_width = widest
			best_text = first_line + "\n" + second_line
	# Keep a little room for the two-pixel outline at both ends. If two balanced
	# lines still cannot fit, retain ordinary word wrapping as the safe fallback.
	return best_text if best_width <= CARD_OFFER_TEXT_WIDTH - 8.0 else value

func _skill_card_accent(skill_id: String, row: Dictionary) -> Color:
	var element := _skill_element(skill_id)
	if element != "":
		return UiKit.element_color(element)
	var tags: Array = row.get("card_tags", [])
	if tags.has("defense") or tags.has("control"):
		return UiKit.CYAN
	if tags.has("economy"):
		return UiKit.GOLD
	if tags.has("anti_armor"):
		return Color(1.0, 0.58, 0.28, 1.0)
	return Color(0.58, 0.78, 1.0, 1.0)

func _card_tag_chip(tag: String, accent: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(104, 28)
	chip.add_theme_stylebox_override("panel", UiKit.pill_style(accent, Color(0.02, 0.045, 0.065, 0.82)))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	chip.add_child(row)
	var icon_path := _tag_icon_path(tag)
	if icon_path != "":
		row.add_child(UiKit.icon(icon_path, Vector2(18, 18)))
	var label := UiKit.label(_tag_name(tag), 12, Color(0.9, 0.98, 1.0, 1.0), 2)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	return chip

func _tag_icon_path(tag: String) -> String:
	match tag:
		"projectile", "anti_swarm", "anti_armor", "pierce", "homing", "chain", "execute", "haste", "dps":
			return "res://assets/production/sprites/ui/ui_card_tag_projectile.png"
		"control", "defense":
			return "res://assets/production/sprites/ui/ui_card_tag_control.png"
		"economy":
			return "res://assets/production/sprites/ui/ui_card_tag_economy.png"
		"element", "fire", "ice", "lightning", "poison", "physical", "burn":
			return "res://assets/production/sprites/ui/ui_card_tag_element.png"
		_:
			return ""

func _on_skill_card_input(event: InputEvent, skill_id: String) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_show_card_detail(skill_id)
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				card_press_skill_id = skill_id
				card_press_started_at = Time.get_ticks_msec() / 1000.0
				card_long_press_opened = false
			elif card_press_skill_id == skill_id:
				var held_for := Time.get_ticks_msec() / 1000.0 - card_press_started_at
				if held_for >= 0.45 or card_long_press_opened:
					_show_card_detail(skill_id)
				else:
					_choose_card(skill_id)
				card_press_skill_id = ""
	elif event is InputEventScreenTouch:
		if event.pressed:
			card_press_skill_id = skill_id
			card_press_started_at = Time.get_ticks_msec() / 1000.0
			card_long_press_opened = false
		elif card_press_skill_id == skill_id:
			var held_for := Time.get_ticks_msec() / 1000.0 - card_press_started_at
			if held_for >= 0.45 or card_long_press_opened:
				_show_card_detail(skill_id)
			else:
				_choose_card(skill_id)
			card_press_skill_id = ""

func _process(_delta: float) -> void:
	_ensure_battle_running()
	if (
		_skill_hint_is_temporarily_visible()
		and Time.get_ticks_msec() / 1000.0 >= skill_hint_auto_hide_at
	):
		# Preserve a still-held long-press state until release so auto-dismissal
		# can never convert that release into an accidental active-skill cast.
		_hide_skill_hint(skill_hint_press_kind == "")
	if card_press_skill_id != "" and not card_long_press_opened:
		var held_for := Time.get_ticks_msec() / 1000.0 - card_press_started_at
		if held_for >= 0.45:
			card_long_press_opened = true
			_show_card_detail(card_press_skill_id)
	if skill_hint_press_kind != "" and not skill_hint_long_press_opened:
		var hint_held_for := Time.get_ticks_msec() / 1000.0 - skill_hint_press_started_at
		if hint_held_for >= 0.45:
			skill_hint_long_press_opened = true
			if skill_hint_press_kind == "character":
				_show_character_skill_hint()
			elif skill_hint_press_kind == "skill":
				_show_skill_hint_for_skill(skill_hint_press_skill_id)

func _show_card_detail(skill_id: String) -> void:
	AudioManager.play_sfx("ui_click", -4.0)
	var row := DataLoader.get_row("skills", skill_id)
	var lv := _skill_offer_level(skill_id)
	var current_lv := skills.level(skill_id)
	_layout_card_detail_overlay()
	_set_card_offer_base_content_visible(false)
	$Hud/CardPanel/DetailOverlay.visible = true
	$Hud/CardPanel/DetailOverlay/Panel/Icon.texture = load(row.get("icon", ""))
	$Hud/CardPanel/DetailOverlay/Panel/Title.text = "%s  %s" % [DataLoader.tr_key(row.get("name_key", skill_id)), LocalizationManager.text("等级%d") % lv]
	$Hud/CardPanel/DetailOverlay/Panel/Body.text = SkillEffectText.format_offer_block(row, lv, current_lv)
	$Hud/CardPanel/DetailOverlay/Panel/AllLevelsTitle.text = LocalizationManager.text("全部等级")
	$Hud/CardPanel/DetailOverlay/Panel/AllLevelsBody.text = SkillEffectText.format_all_levels(row, lv)
	$Hud/CardPanel/DetailOverlay/Panel/DescBody.text = LocalizationManager.text(_skill_long_desc(skill_id, lv))
	$Hud/CardPanel/DetailOverlay/Panel/TagsBody.text = "%s: %s" % [_loc("标签", "Tags"), LocalizationManager.text(_format_card_tags(row.get("card_tags", [])))]
	# Localized copy determines each lane's height. Re-layout after assigning the
	# strings so the mobile-first FONT_SCALE ruler is preserved exactly.
	_layout_card_detail_overlay()

func _hide_card_detail() -> void:
	AudioManager.play_sfx("ui_click", -5.0)
	$Hud/CardPanel/DetailOverlay.visible = false
	_set_card_offer_base_content_visible(true)
	card_press_skill_id = ""
	card_long_press_opened = false

func _set_card_offer_base_content_visible(is_visible: bool) -> void:
	for path in ["Hud/CardPanel/CardTitle", "Hud/CardPanel/Cards", "Hud/CardPanel/RerollButton", "Hud/CardPanel/SkipButton"]:
		var node := get_node_or_null(path) as CanvasItem
		if node != null:
			node.visible = is_visible

func _tag_name(tag: String) -> String:
	match str(tag):
		"projectile":
			return "弹道"
		"anti_swarm":
			return "清群"
		"anti_armor":
			return "破甲"
		"control":
			return "控制"
		"defense":
			return "防线"
		"economy":
			return "经济"
		"element":
			return "元素"
		"pierce":
			return "穿透"
		"homing":
			return "追踪"
		"chain":
			return "连锁"
		"execute":
			return "处决"
		"burn":
			return "灼烧"
		"haste":
			return "急速"
		"dps":
			return "输出"
		"fire", "ice", "lightning", "poison", "physical":
			return _element_name(tag)
		_:
			return str(tag)

func _format_card_tags(tags: Array) -> String:
	var names := []
	for tag in tags:
		names.append(_tag_name(str(tag)))
	return " / ".join(names)

func _skill_recommendation_reason(skill_id: String, row: Dictionary) -> String:
	var level_tags: Array = level.get("threat_tags", [])
	var card_tags: Array = row.get("card_tags", [])
	if level_tags.has("fast") and (skill_id == "skill_homing" or skill_id == "skill_slow_field" or skill_id == "skill_cryo"):
		return "压高速"
	if (level_tags.has("tank") or level_tags.has("boss")) and (skill_id == "skill_pierce" or skill_id == "skill_charge_shot" or skill_id == "skill_critical" or skill_id == "skill_venom"):
		return "破厚血"
	if level_tags.has("support") and (skill_id == "skill_homing" or skill_id == "skill_tesla" or skill_id == "skill_ricochet"):
		return "点支援"
	if level_tags.has("breach") and (skill_id == "skill_barrier" or skill_id == "skill_slow_field" or skill_id == "skill_split_shot" or skill_id == "skill_multishot"):
		return "稳防线"
	if _skill_element(skill_id) == primary_weakness:
		return "打弱点"
	for tag in character_data.get("card_affinity_tags", []):
		if card_tags.has(tag):
			return "角色适配"
	var weapon := DataLoader.get_row("weapons", weapon_id)
	if card_tags.has(str(weapon.get("element", ""))):
		return "武器适配"
	return ""

func _skill_element(skill_id: String) -> String:
	match skill_id:
		"skill_incendiary":
			return "fire"
		"skill_cryo":
			return "ice"
		"skill_tesla":
			return "lightning"
		"skill_venom":
			return "poison"
		_:
			return ""

func _process_build_feedback(_skill_id: String) -> void:
	for combo in _build_combo_candidates():
		var key := str(combo.get("key", ""))
		if key != "" and not build_feedback_shown.has(key):
			build_feedback_shown[key] = true
			var combo_color: Color = combo.get("color", Color(1.0, 0.86, 0.28, 1.0))
			_announce_build_feedback(key, str(combo.get("label", "战术联动")), combo_color, str(combo.get("family", "")))
			return
	var family := _dominant_build_family()
	if family == "":
		return
	var family_key := "family_%s" % family
	if build_feedback_shown.has(family_key):
		return
	build_feedback_shown[family_key] = true
	_announce_build_feedback(family_key, "流派成型：%s" % _build_family_label(family), _build_family_color(family), family)

func _build_combo_candidates() -> Array[Dictionary]:
	var combos: Array[Dictionary] = []
	if skills.level("skill_venom") > 0 and (skills.level("skill_split_shot") > 0 or skills.level("skill_ricochet") > 0):
		combos.append({"key": "combo_poison_spread", "label": "联动：毒素扩散", "family": "poison", "color": Color(0.48, 1.0, 0.24, 1.0)})
	if skills.level("skill_cryo") > 0 and skills.level("skill_slow_field") > 0:
		combos.append({"key": "combo_ice_control", "label": "联动：冰控防线", "family": "ice", "color": Color(0.54, 0.9, 1.0, 1.0)})
	if skills.level("skill_tesla") > 0 and (skills.level("skill_homing") > 0 or skills.level("skill_ricochet") > 0):
		combos.append({"key": "combo_chain_hunt", "label": "联动：电链追击", "family": "lightning", "color": Color(1.0, 0.9, 0.2, 1.0)})
	if skills.level("skill_incendiary") > 0 and (skills.level("skill_split_shot") > 0 or skills.level("skill_multishot") > 0 or skills.level("skill_salvo") > 0):
		combos.append({"key": "combo_fire_clear", "label": "联动：火焰清场", "family": "fire", "color": Color(1.0, 0.46, 0.16, 1.0)})
	if skills.level("skill_pierce") > 0 and (skills.level("skill_charge_shot") > 0 or skills.level("skill_critical") > 0):
		combos.append({"key": "combo_pierce_execute", "label": "联动：穿甲点杀", "family": "physical", "color": Color(1.0, 0.88, 0.48, 1.0)})
	if skills.level("skill_barrier") > 0 and skills.level("skill_slow_field") > 0:
		combos.append({"key": "combo_guard_line", "label": "联动：防线稳固", "family": "defense", "color": Color(0.58, 0.86, 1.0, 1.0)})
	return combos

func _dominant_build_family() -> String:
	var scores := {
		"fire": skills.level("skill_incendiary") * 2 + skills.level("skill_split_shot") + skills.level("skill_multishot") + skills.level("skill_salvo"),
		"ice": skills.level("skill_cryo") * 2 + skills.level("skill_slow_field") + skills.level("skill_barrier") + skills.level("skill_homing"),
		"lightning": skills.level("skill_tesla") * 2 + skills.level("skill_ricochet") + skills.level("skill_homing") + skills.level("skill_split_shot"),
		"poison": skills.level("skill_venom") * 2 + skills.level("skill_split_shot") + skills.level("skill_ricochet") + skills.level("skill_pierce"),
		"physical": skills.level("skill_pierce") + skills.level("skill_critical") + skills.level("skill_charge_shot") + skills.level("skill_salvo") + skills.level("skill_multishot"),
		"defense": skills.level("skill_barrier") * 2 + skills.level("skill_slow_field") + skills.level("skill_homing") + skills.level("skill_cryo")
	}
	var best_family := ""
	var best_score := 0
	for family in scores.keys():
		var score := int(scores[family])
		if score > best_score:
			best_family = str(family)
			best_score = score
	return best_family if best_score >= 3 else ""

func _build_family_label(family: String) -> String:
	match family:
		"fire":
			return "火焰爆燃"
		"ice":
			return "冰霜控场"
		"lightning":
			return "闪电连锁"
		"poison":
			return "毒素扩散"
		"physical":
			return "物理穿甲"
		"defense":
			return "防线堡垒"
		_:
			return "混合火力"

func _build_family_color(family: String) -> Color:
	match family:
		"fire":
			return Color(1.0, 0.46, 0.16, 1.0)
		"ice":
			return Color(0.54, 0.9, 1.0, 1.0)
		"lightning":
			return Color(1.0, 0.9, 0.2, 1.0)
		"poison":
			return Color(0.48, 1.0, 0.24, 1.0)
		"defense":
			return Color(0.58, 0.86, 1.0, 1.0)
		_:
			return Color(1.0, 0.88, 0.48, 1.0)

func _announce_build_feedback(key: String, text: String, color: Color, family: String) -> void:
	AudioManager.play_sfx("level_up", -2.0, 0.02)
	_show_wave_toast(text, color)
	_spawn_build_banner(text, color)
	_pulse_build_skill_slots(family)
	_spawn_attack_ring(Vector2(540, 1540.0 + bottom_dock_shift), 180.0, Color(color.r, color.g, color.b, 0.26), 0.28)

func _spawn_build_banner(text: String, color: Color) -> void:
	_show_wave_toast(text, color)

func _pulse_build_skill_slots(family: String) -> void:
	if family == "":
		return
	for skill_id in skill_slot_ids:
		if not _skill_belongs_to_family(skill_id, family):
			continue
		var slot := $Hud/SkillSlots.get_node_or_null(skill_id)
		if slot and slot is Control:
			var tween := (slot as Control).create_tween()
			tween.tween_property(slot, "scale", Vector2(1.2, 1.2), 0.08)
			tween.tween_property(slot, "scale", Vector2.ONE, 0.14)

func _skill_belongs_to_family(skill_id: String, family: String) -> bool:
	match family:
		"fire":
			return ["skill_incendiary", "skill_split_shot", "skill_multishot", "skill_salvo"].has(skill_id)
		"ice":
			return ["skill_cryo", "skill_slow_field", "skill_barrier", "skill_homing"].has(skill_id)
		"lightning":
			return ["skill_tesla", "skill_ricochet", "skill_homing", "skill_split_shot"].has(skill_id)
		"poison":
			return ["skill_venom", "skill_split_shot", "skill_ricochet", "skill_pierce"].has(skill_id)
		"defense":
			return ["skill_barrier", "skill_slow_field", "skill_cryo", "skill_homing"].has(skill_id)
		"physical":
			return ["skill_pierce", "skill_critical", "skill_charge_shot", "skill_salvo", "skill_multishot"].has(skill_id)
		_:
			return false

func _skill_short_desc(skill_id: String, lv: int) -> String:
	match skill_id:
		"skill_split_shot":
			return "命中后分裂成小弹，适合清理密集尸潮。"
		"skill_pierce":
			return "子弹穿透更多目标，对厚血敌人更稳。"
		"skill_multishot":
			return "额外发射弹丸，正面火力明显变宽。"
		"skill_slow_field":
			return "防线前生成大范围减速区，等级越高覆盖越远、减速越强。"
		"skill_homing":
			return "子弹获得轻微追踪，减少高速怪和斜线目标漏枪。"
		"skill_critical":
			return "蓄力打出重击，提高暴击概率、暴击伤害和主弹威力。"
		"skill_barrier":
			return "提高基地生命上限，并立即补上新增防线生命。"
		"skill_gold_rush":
			return "提高本局金币收益，适合滚长期养成。"
		"skill_ricochet":
			return "命中后额外弹射，强化清群和连锁补刀。"
		"skill_salvo":
			return "提高武器攻速，让持续输出更密。"
		"skill_incendiary":
			return "火焰弹药模块；物理枪转火，火系武器升级火焰效果。"
		"skill_cryo":
			return "冰霜弹药模块；物理枪转冰，冰系武器升级控制。"
		"skill_tesla":
			return "闪电弹药模块；物理枪转电，雷系武器升级连锁。"
		"skill_venom":
			return "毒素弹药模块；物理枪转毒，毒系武器升级中毒。"
		"skill_charge_shot":
			return "主弹获得伤害穿透，能把部分伤害打进护甲本体。"
		"skill_recycle":
			return "获得1次重抽机会，提高本局技能成型稳定性。"
		_:
			return "强化当前战斗能力。"

func _skill_long_desc(skill_id: String, lv: int) -> String:
	match skill_id:
		"skill_split_shot":
			return "每次命中都会触发分裂弹。等级越高分裂数量越多，满级(5级)分裂6发并大幅降低伤害衰减，形成密集扇形爆发，适合密集推进。"
		"skill_pierce":
			return "主弹可以继续穿透后排敌人。3级起附带额外伤害，满级穿透6名并显著增伤，适合处理巨臂和首领护甲。"
		"skill_multishot":
			return "每次开火额外发射弹丸，最多形成5条弹道。多弹道每发有轻微衰减，但可与追踪、穿透、分裂和跳弹继续叠加。"
		"skill_slow_field":
			return "在防线前展开持续减速区。覆盖范围按30%/40%/50%/60%/70%向前扩大；减速强度依次为30%/40%/50%/60%/80%。"
		"skill_homing":
			return "子弹飞行中会向最近目标修正方向。等级越高修正越明显，能显著改善斜线开火、高速小怪和残血补刀的手感。"
		"skill_critical":
			return "原弱点暴击重命名为蓄能重击。提高暴击概率、全局伤害，3级起提高暴击伤害；适合高射速武器和首领战。"
		"skill_barrier":
			return "不再按僵尸次数格挡，而是直接提高基地生命上限。等级成长为+20%/+40%/+60%/+80%/+120%，并立即补上新增生命。"
		"skill_gold_rush":
			return "本局获得金币提高。它不会直接提高有效战力，但能让过关后的武器和装备成长更快，适合低压波次选择。"
		"skill_ricochet":
			return "命中后产生额外弹射弹，只负责连锁跳弹，不自带分裂或散射。等级越高弹射数量越多，适合尸潮密度高的关卡。"
		"skill_salvo":
			return "提高武器攻击速度。等级越高射击间隔越短，适合搭配穿透、暴击和元素弹，在后期高数量尸潮里保持稳定压制。"
		"skill_incendiary":
			return "弹药元素模块，同组互斥。物理武器会转为火焰；火焰武器只升级火焰效果，不会被其他元素弹药覆盖。火焰更适合打爆裂、再生和怕火单位。"
		"skill_cryo":
			return "弹药元素模块，同组互斥。物理武器会转为冰霜；冰霜武器只升级冰霜控制，不会被其他元素弹药覆盖。适合防守压力大、敌人速度快的局。"
		"skill_tesla":
			return "弹药元素模块，同组互斥。物理武器会转为闪电；雷系武器只升级连锁效果，不会和毒素弹等其他弹药共存。闪电能稳定命中相位单位。"
		"skill_venom":
			return "弹药元素模块，同组互斥。物理武器会转为毒素；毒系武器只升级中毒效果，不会和特斯拉弹等其他弹药共存。毒素偏向破厚血和护甲压力。"
		"skill_charge_shot":
			return "改为伤害穿透。它提供直接伤害加成，并让主弹对护甲/护盾单位造成一部分本体穿透伤害，适合处理厚甲首领。"
		"skill_recycle":
			return "只提供1次额外重抽，不再升级。拿到它以后，后续技能选择更容易围绕角色、武器和关卡威胁成型。"
		_:
			return "获得一项战斗强化。"

func _on_reroll_pressed() -> void:
	if reroll_charges <= 0 or not card_offer_active:
		return
	_hide_skill_hint()
	reroll_charges -= 1
	AudioManager.play_sfx("reroll")
	_render_card_offer(skills.owned)
	_animate_card_panel_in(0.08)

func _on_skip_card() -> void:
	if not card_offer_active:
		return
	AudioManager.play_sfx("ui_click")
	_hide_skill_hint()
	_close_card_offer(false)
	_update_character_skill_button()
	cards_picked += 1
	_advance_card_xp_after_pick()

func _choose_card(skill_id: String) -> void:
	AudioManager.play_sfx("card_pick")
	AudioManager.play_sfx("level_up", -3.0, 0.02)
	_hide_skill_hint()
	var previous_skill_level := skills.level(skill_id)
	if not _skill_compatible_with_weapon(skill_id):
		_show_wave_toast("该弹药与当前武器不兼容", Color(1.0, 0.55, 0.24))
		_close_card_offer(false)
		_update_character_skill_button()
		return
	if not skills.add_skill(skill_id):
		_show_wave_toast("该技能已满级", Color(1.0, 0.72, 0.24))
		_close_card_offer(false)
		_update_character_skill_button()
		return
	var skill_sfx := _skill_sfx_id(skill_id)
	if skill_sfx != "":
		AudioManager.play_sfx(skill_sfx, -5.5, 0.02)
	cards_picked += 1
	cards_selected += 1
	_spawn_levelup_vfx(Vector2(540, 1580.0 + bottom_dock_shift), Color(1.0, 0.86, 0.3))
	_spawn_skill_pick_vfx(skill_id)
	if skill_id == "skill_barrier":
		_apply_barrier_base_hp_bonus(previous_skill_level)
	if skill_id == "skill_recycle":
		reroll_charges += skills.reroll_gain()
	if skill_id == "skill_salvo" and turret != null:
		var next_fire_rate_mult := skills.fire_rate_multiplier()
		if fire_rate_profile_id == FireRateProfiles.DEFAULT_PROFILE_ID:
			turret.fire_rate *= next_fire_rate_mult / skill_fire_rate_mult
			skill_fire_rate_mult = next_fire_rate_mult
		else:
			_recompute_profiled_fire_rate()
		_spawn_float_text(_weapon_fire_origin() + Vector2(0, -82), "攻速提升", Color(1.0, 0.86, 0.32))
	_process_build_feedback(skill_id)
	_show_wave_toast("%s 已生效" % DataLoader.tr_key(DataLoader.get_row("skills", skill_id).get("name_key", skill_id)), Color(1.0, 0.86, 0.28))
	_update_skill_slots()
	_spawn_skill_to_slot_vfx(skill_id)
	_advance_card_xp_after_pick()
	_close_card_offer(false)
	_update_character_skill_button()

func _skill_effect_float_for_level(skill_id: String, target_level: int, key: String) -> float:
	if target_level <= 0:
		return 0.0
	var row: Dictionary = DataLoader.get_row("skills", skill_id)
	var chosen: Dictionary = {}
	for entry in row.get("levels", []):
		if entry is Dictionary and int(entry.get("lv", 0)) <= target_level:
			chosen = entry.get("effect", {})
	return float(chosen.get(key, 0.0))

func _apply_barrier_base_hp_bonus(previous_level: int) -> void:
	var current_level := skills.level("skill_barrier")
	var previous_bonus := _skill_effect_float_for_level("skill_barrier", previous_level, "base_hp_mult")
	var current_bonus := _skill_effect_float_for_level("skill_barrier", current_level, "base_hp_mult")
	if current_bonus <= previous_bonus or base_hp_max <= 0:
		return
	var old_max := base_hp_max
	var base_without_barrier := float(base_hp_max) / maxf(1.0 + previous_bonus, 0.05)
	base_hp_max = maxi(1, int(round(base_without_barrier * (1.0 + current_bonus))))
	var hp_gain := maxi(0, base_hp_max - old_max)
	base_hp = mini(base_hp + hp_gain, base_hp_max)
	_update_hud()
	_spawn_barrier_gain_vfx()
	_spawn_float_text(Vector2(354, 1710.0 + bottom_dock_shift), "防线生命 +%d%%" % int(round((current_bonus - previous_bonus) * 100.0)), Color(0.62, 1.0, 0.78), true, 26, 360.0)

func _spawn_skill_pick_vfx(skill_id: String) -> void:
	if not _can_spawn_projectile_fx(true):
		return
	var origin := Vector2(540, 1560.0 + bottom_dock_shift)
	var color := _skill_signature_color(skill_id)
	var hot := color.lightened(0.26)
	hot.a = 0.9
	var glow := VfxLib.spawn_glow($ProjectileLayer, origin, hot, 190.0, 0.32)
	if glow != null:
		_track_transient_fx(glow, "projectile")
	_spawn_impact_shock_ring(origin, Color(color.r, color.g, color.b, 0.52), 124.0, 6.0, 0.28, true)
	var motes := VfxLib.spawn_particles($ProjectileLayer, origin, Color(color.r, color.g, color.b, 0.54), 16, 280.0, 140.0, 0.34)
	if motes != null:
		_track_transient_fx(motes, "projectile")
	_spawn_vfx_sequence("vfx_skill_cast_%s" % skill_id.trim_prefix("skill_"), origin + Vector2(0, -40), 1.15, Color(color.r, color.g, color.b, 0.92), 1.0, 0.0, 1.1, Vector2(0, -14), 0.0, true)
	match skill_id:
		"skill_split_shot":
			_spawn_split_burst_vfx(origin, Vector2.UP, deg_to_rad(42.0), 5, "physical")
		"skill_pierce":
			_spawn_weapon_trace(origin + Vector2(-145, -8), origin + Vector2(145, -8), Color(1.0, 0.92, 0.42, 0.82), 14.0, 0.22)
			_spawn_impact_streaks(origin, Color(1.0, 0.9, 0.46, 0.72), 5, 150.0, 0.22, 4.0, true)
		"skill_multishot":
			for i in range(5):
				var offset := lerpf(-0.42, 0.42, float(i) / 4.0)
				_spawn_muzzle_light_cone(origin, Vector2.UP.rotated(offset), Color(color.r, color.g, color.b, 0.52), 120.0, 16.0, 0.16, 3.4)
		"skill_slow_field":
			_spawn_impact_fork_lines(origin + Vector2(0, -12), Color(0.78, 1.0, 1.0, 0.74), 7, 128.0, 0.24, 3.0, true)
			_spawn_impact_cloud(origin, Color(0.42, 0.86, 1.0, 0.24), 12, 0.38, true, true)
		"skill_homing":
			_spawn_impact_shock_ring(origin, Color(0.64, 0.92, 1.0, 0.5), 82.0, 3.0, 0.36, true)
			_spawn_impact_shock_ring(origin, Color(0.64, 0.92, 1.0, 0.36), 154.0, 2.4, 0.42, true)
		"skill_critical":
			_spawn_impact_streaks(origin, Color(1.0, 0.88, 0.28, 0.86), 8, 150.0, 0.22, 4.4, true)
			VfxLib.screen_shake(2.4, 0.04)
		"skill_barrier":
			_spawn_barrier_shell_pulse(origin, 156.0, Color(0.72, 0.96, 1.0, 0.5), 0.34)
		"skill_gold_rush":
			_spawn_impact_streaks(origin, Color(1.0, 0.76, 0.22, 0.76), 10, 138.0, 0.26, 3.4, true)
		"skill_ricochet":
			_spawn_chain_arc(origin + Vector2(-120, -18), origin + Vector2(-28, -112), "lightning")
			_spawn_chain_arc(origin + Vector2(-28, -112), origin + Vector2(118, -26), "lightning")
		"skill_salvo":
			for i in range(3):
				_spawn_impact_shock_ring(origin, Color(color.r, color.g, color.b, 0.42 - float(i) * 0.08), 78.0 + float(i) * 44.0, 3.4, 0.18 + float(i) * 0.05, true)
		"skill_incendiary":
			_spawn_impact_heat_haze(origin, Color(1.0, 0.28, 0.06, 0.48), 0.34, 1.5, true)
			_spawn_impact_cloud(origin, Color(1.0, 0.34, 0.08, 0.28), 14, 0.36, true, true)
		"skill_cryo":
			_spawn_impact_fork_lines(origin, Color(0.78, 1.0, 1.0, 0.86), 8, 150.0, 0.28, 3.2, true)
		"skill_tesla":
			_spawn_chain_arc(origin + Vector2(-118, -34), origin + Vector2(112, -96), "lightning")
			_spawn_impact_fork_lines(origin, Color(0.86, 0.98, 1.0, 0.86), 8, 150.0, 0.16, 3.0, true)
		"skill_venom":
			_spawn_impact_cloud(origin, Color(0.38, 1.0, 0.16, 0.34), 16, 0.42, false, true)
			_spawn_impact_bubbles(origin, Color(0.52, 1.0, 0.18, 0.5), 7, 0.42, 1.2, true)
		"skill_charge_shot":
			_spawn_weapon_power_ring(origin, "physical")
		"skill_recycle":
			_spawn_impact_shock_ring(origin, Color(0.62, 1.0, 0.82, 0.48), 96.0, 3.2, 0.3, true)
			_spawn_impact_shock_ring(origin, Color(1.0, 0.84, 0.28, 0.42), 144.0, 3.2, 0.36, true)

func _skill_signature_color(skill_id: String) -> Color:
	match skill_id:
		"skill_incendiary":
			return _element_color("fire")
		"skill_cryo", "skill_slow_field":
			return _element_color("ice")
		"skill_tesla", "skill_ricochet", "skill_homing":
			return Color(0.78, 0.96, 1.0, 1.0)
		"skill_venom":
			return _element_color("poison")
		"skill_barrier":
			return Color(0.58, 0.86, 1.0, 1.0)
		"skill_split_shot", "skill_multishot", "skill_salvo":
			return Color(1.0, 0.68, 0.26, 1.0)
		"skill_pierce", "skill_charge_shot", "skill_critical":
			return Color(1.0, 0.9, 0.48, 1.0)
		"skill_gold_rush":
			return Color(1.0, 0.76, 0.22, 1.0)
		"skill_recycle":
			return Color(0.64, 1.0, 0.82, 1.0)
		_:
			return Color(1.0, 0.86, 0.28, 1.0)

func _spawn_skill_to_slot_vfx(skill_id: String) -> void:
	var slot := $Hud/SkillSlots.get_node_or_null(skill_id)
	if slot and slot is Control:
		var pulse := (slot as Control).create_tween()
		pulse.tween_property(slot, "scale", Vector2(1.14, 1.14), 0.08)
		pulse.tween_property(slot, "scale", Vector2.ONE, 0.14)

func _on_enemy_hit_feedback(enemy: Node, element: String, immune_hit: bool, weak_hit: bool, hit_kind: String) -> void:
	AudioManager.play_sfx("hit_immune" if immune_hit else _element_hit_sfx(element), -8.0)
	if not is_instance_valid(enemy):
		return
	var incoming_source := str(enemy.get_meta("_damage_source_for_feedback", "weapon"))
	# Golden Law already emits one authored, localized name for Verdict, Decree,
	# Skyfalcon and Eternal Counter. Repeating the generic armor-pierce sentence
	# above every target makes a four-target decree read as overlapping garbage.
	# Keep hit particles/audio, but suppress only the redundant rule sentence.
	var named_golden_law_hit := incoming_source in [
		"golden_verdict",
		"golden_decree",
		"golden_mark",
		"skyfalcon_mark",
		"armor_counter",
	]
	if not named_golden_law_hit and (immune_hit or hit_kind == "armor" or hit_kind == "shield" or hit_kind == "phase_evade" or hit_kind == "armor_pierce" or hit_kind == "suppressed" or hit_kind == "resisted"):
		_show_enemy_hit_rule_feedback(enemy, element, hit_kind)
	# 子弹命中(_on_projectile_hit_confirmed)和主动技能命中(_active_skill_apply_hit)
	# 都会直接调 _spawn_element_impact_vfx，随后 take_damage 又会通过这个信号再触发
	# 一次 _spawn_hit_layer_vfx——普通命中(hit_kind=="normal")两边其实是同一种粒子
	# 爆发，叠在一起打就变成一大团不自然的定向喷射。弱点/破甲/护盾/免疫命中另有专属
	# 提示效果，不去重。这里只对普通命中用极短时间窗去掉那份纯重复。
	if hit_kind == "normal" and enemy.has_meta("_recent_impact_vfx_ms") and Time.get_ticks_msec() - int(enemy.get_meta("_recent_impact_vfx_ms")) < 50:
		return
	_spawn_hit_layer_vfx(enemy.global_position, element, weak_hit, hit_kind)

func _show_enemy_hit_rule_feedback(enemy: Node, element: String, hit_kind: String) -> void:
	if not is_instance_valid(enemy) or not enemy is Node2D:
		return
	var text := _enemy_hit_rule_text(enemy, element, hit_kind)
	if text == "":
		return
	var now := _now_seconds()
	var meta_key := "_last_rule_feedback_at"
	var last := -99.0
	if enemy.has_meta(meta_key):
		last = float(enemy.get_meta(meta_key))
	var previous_text := str(enemy.get_meta("_last_rule_feedback_text")) if enemy.has_meta("_last_rule_feedback_text") else ""
	var cooldown := 0.55 if _is_boss_node(enemy) else 0.9
	if text == previous_text and now - last < cooldown:
		return
	enemy.set_meta(meta_key, now)
	enemy.set_meta("_last_rule_feedback_text", text)
	var boss_hit := _is_boss_node(enemy)
	var y_offset := -176.0 if boss_hit else -112.0
	var color := _enemy_hit_rule_color(element, hit_kind)
	var width := 380.0 if boss_hit else 270.0
	_spawn_float_text((enemy as Node2D).global_position + Vector2(-width * 0.5, y_offset), text, color, true, 26 if boss_hit else 22, width)

func _enemy_hit_rule_text(enemy: Node, element: String, hit_kind: String) -> String:
	var weakness_text := _enemy_weakness_suffix(enemy)
	match hit_kind:
		"armor":
			return "装甲承伤 · 破甲中"
		"armor_pierce":
			return "伤害穿透 · 直击本体"
		"shield":
			return "护盾吸收%s" % weakness_text
		"phase_evade":
			return "相位闪避 · 雷电可破"
		"immune":
			return "%s免疫%s" % [_element_combat_label(element), weakness_text]
		"suppressed":
			return "%s抗性 · 减伤50%%%s" % [_element_combat_label(element), weakness_text]
		"resisted":
			var reduction_pct := int(round(_enemy_resistance_reduction(enemy, element) * 100.0))
			return "%s抗性 · 减伤%d%%%s" % [_element_combat_label(element), reduction_pct, weakness_text]
		_:
			var immune_list: Variant = enemy.get("immune")
			if immune_list is Array and (immune_list as Array).has(element):
				return "%s免疫%s" % [_element_combat_label(element), weakness_text]
	return ""

func _enemy_resistance_reduction(enemy: Node, element: String) -> float:
	var values_var: Variant = enemy.get("resistances")
	if values_var is Dictionary and (values_var as Dictionary).has(element):
		return clampf(float((values_var as Dictionary).get(element, 0.0)), 0.0, 0.95)
	var resisted_element := str(enemy.get("resist"))
	if resisted_element == element:
		return 1.0 - clampf(float(DataLoader.get_table("economy").get("resist_mult", 0.5)), 0.05, 1.0)
	return 1.0 - clampf(float(DataLoader.get_table("economy").get("resist_mult", 0.5)), 0.05, 1.0)

func _enemy_weakness_suffix(enemy: Node) -> String:
	var weak := str(enemy.get("weakness"))
	if weak == "" or weak == "none":
		return ""
	return " · 弱点%s" % _element_combat_label(weak)

func _element_combat_label(element: String) -> String:
	match element:
		"physical":
			return "物理"
		"fire":
			return "火焰"
		"ice":
			return "冰霜"
		"lightning":
			return "雷电"
		"poison":
			return "毒素"
		_:
			return element

func _enemy_hit_rule_color(element: String, hit_kind: String) -> Color:
	match hit_kind:
		"armor":
			return Color(1.0, 0.82, 0.28, 1.0)
		"armor_pierce":
			return Color(1.0, 0.92, 0.42, 1.0)
		"shield":
			return Color(0.58, 0.92, 1.0, 1.0)
		"phase_evade":
			return Color(0.72, 0.84, 1.0, 1.0)
		_:
			return _element_color(element).lightened(0.18)

func _process_threat_feedback(enemies: Array) -> void:
	if enemies.is_empty():
		return
	var now := Time.get_ticks_msec() / 1000.0
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var near_line_y := _base_line_inner_y(BASE_LINE_BOSS_NEAR_WARNING_INSET if bool(enemy.boss) else BASE_LINE_NEAR_WARNING_INSET)
		var warning_line_y := _base_line_inner_y(BASE_LINE_BOSS_WARNING_INSET if bool(enemy.boss) else BASE_LINE_WARNING_INSET)
		if enemy.global_position.y >= near_line_y and not enemy.has_meta("near_line_warned"):
			enemy.set_meta("near_line_warned", true)
			var color := _attack_color_for_mechanic(str(enemy.mechanic))
			_spawn_attack_ring(_base_damage_impact_position(enemy.global_position.x) + Vector2(0.0, -50.0), 96.0 if not bool(enemy.boss) else 150.0, Color(color.r, color.g, color.b, 0.28), 0.2)
		if enemy.global_position.y >= warning_line_y:
			if now - last_threat_warning_at < 2.2:
				continue
			last_threat_warning_at = now
			AudioManager.play_enemy_sfx("threat_warning", -4.0, 0.02)
			_show_wave_toast("防线告急", Color(1.0, 0.22, 0.12))
			return

func _check_low_hp_warning() -> void:
	if low_hp_warned or base_hp_max <= 0:
		return
	var hp_ratio := float(base_hp) / float(base_hp_max)
	if hp_ratio > 0.28:
		return
	low_hp_warned = true
	AudioManager.play_enemy_sfx("threat_warning", -2.0, 0.0)
	_show_wave_toast("基地生命过低", Color(1.0, 0.12, 0.08))
	_show_screen_flash(Color(1.0, 0.0, 0.0, 0.1), 0.2)

func _show_screen_flash(color: Color, duration := 0.18) -> void:
	if screen_flash == null or not is_instance_valid(screen_flash):
		screen_flash = TextureRect.new()
		screen_flash.name = "ScreenFlash"
		screen_flash.texture = SCREEN_FLASH_TEXTURE
		screen_flash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		screen_flash.stretch_mode = TextureRect.STRETCH_SCALE
		screen_flash.position = Vector2.ZERO
		screen_flash.size = Vector2(1080, 1920.0 + bottom_dock_shift)
		screen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$Hud.add_child(screen_flash)
	if screen_flash_tween != null and screen_flash_tween.is_valid():
		screen_flash_tween.kill()
	var current_alpha := screen_flash.modulate.a
	var alpha_cap := 0.055 if SettingsManager.reduced_effects_enabled() else 0.14
	var alpha := minf(maxf(color.a, current_alpha), alpha_cap)
	screen_flash.modulate = Color(color.r, color.g, color.b, alpha)
	screen_flash_tween = screen_flash.create_tween()
	screen_flash_tween.tween_property(screen_flash, "modulate:a", 0.0, duration * (0.62 if SettingsManager.reduced_effects_enabled() else 1.0))

## 阶段 67：离开战斗必须归零环境混音，否则菜单/地图/结算会继续挂着战场的
## 混响与增益。放在 _exit_tree 而不是各个出口，保证与 setup 里的施加成对。
func _exit_tree() -> void:
	AudioManager.clear_environment_mix()

func _apply_level_background() -> void:
	var background := get_node_or_null("Background") as Sprite2D
	if background == null:
		return
	var env_id := str(level.get("env", "env_lava_foundry"))
	var env := _environment_row(env_id)
	var path := str(env.get("battle_background", "res://assets/production/sprites/backgrounds/bg_lava_foundry.png"))
	var texture := load(path) as Texture2D
	if texture == null:
		push_warning("Missing battle background for %s: %s" % [env_id, path])
		return
	background.texture = texture
	# 背景与玩法坐标对齐:10 张主线战斗背景已经扩展成 1080x2622，高出来的部分
	# 只在高屏设备顶部露出；原 1080x1920 内容仍贴在扩展画布底部。这样 1920
	# 设备看到的仍是原构图，高屏设备顶部看到真实环境延展，而背景里的护栏/基座
	# 和玩法 BREACH_Y 继续使用同一底边锚点，不再靠黑色 BackgroundExtension 补空。
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		background.scale = Vector2.ONE
		_hide_background_top_fill()
		return
	var visible_height := _battle_visible_height()
	var cover_scale := maxf(1080.0 / texture_size.x, visible_height / texture_size.y)
	background.scale = Vector2(cover_scale, cover_scale)
	background.position = Vector2(540, visible_height - texture_size.y * cover_scale * 0.5)
	background.modulate = Color(1, 1, 1, 1)
	_hide_background_top_fill()

func _battle_visible_height() -> float:
	var viewport_height := get_viewport().get_visible_rect().size.y
	return maxf(1920.0 + bottom_dock_shift, viewport_height)

func _sample_background_edge_color(texture: Texture2D, texture_size: Vector2, from_top := false) -> Color:
	var image := texture.get_image()
	if image == null:
		return Color(0.05, 0.05, 0.05, 1.0)
	if image.is_compressed():
		image.decompress()
	var sample_h := mini(32, int(texture_size.y))
	var sum := Color(0.0, 0.0, 0.0, 0.0)
	var count := 0
	var y0 := 0 if from_top else int(texture_size.y) - sample_h
	var y1 := sample_h if from_top else int(texture_size.y)
	var step := maxi(1, int(texture_size.x) / 48)
	for y in range(y0, y1):
		for x in range(0, int(texture_size.x), step):
			sum += image.get_pixel(x, y)
			count += 1
	if count == 0:
		return Color(0.05, 0.05, 0.05, 1.0)
	return Color(sum.r / count, sum.g / count, sum.b / count, 1.0)

func _apply_background_top_fill(edge_color: Color) -> void:
	var ext := get_node_or_null("BackgroundExtension") as TextureRect
	if ext == null:
		ext = TextureRect.new()
		ext.name = "BackgroundExtension"
		ext.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ext.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ext.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(ext)
		var bg := get_node_or_null("Background")
		if bg != null:
			# 必须排在 EnemyLayer 等玩法层前面(紧跟在 Background 后面)，否则会盖住
			# 生成在 y=0~bottom_dock_shift 这段空当附近的敌人/投射物。
			move_child(ext, bg.get_index() + 1)
	if bottom_dock_shift <= 0.5:
		ext.visible = false
		return
	# 纯色块贴上去在真实背景边缘会有一条硬边(色块没有背景本身的颗粒/噪点纹理)。
	# 改成从更暗的同色系渐变到取样色，越靠近背景衔接处颜色越接近背景边缘实际的
	# 平均色，衔接处的硬边感明显减弱；越往上(真实的走廊纵深处)则自然暗下去，
	# 读作雾气/暗部渐隐，而不是一块突兀的实色。
	var gradient := Gradient.new()
	var dark_color := Color(edge_color.r * 0.3, edge_color.g * 0.3, edge_color.b * 0.3, 1.0)
	gradient.colors = PackedColorArray([dark_color, edge_color])
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 4
	gradient_texture.height = 128
	gradient_texture.fill_from = Vector2(0.5, 0.0)
	gradient_texture.fill_to = Vector2(0.5, 1.0)
	ext.texture = gradient_texture
	ext.position = Vector2(0.0, 0.0)
	ext.size = Vector2(1080.0, bottom_dock_shift)
	ext.visible = true

func _hide_background_top_fill() -> void:
	var ext := get_node_or_null("BackgroundExtension") as TextureRect
	if ext != null:
		ext.visible = false

func _battle_bgm_id() -> String:
	var env := _environment_row(str(level.get("env", "env_lava_foundry")))
	return str(env.get("bgm", "battle_city"))

func _environment_row(env_id: String) -> Dictionary:
	var env := DataLoader.get_row("environments", env_id)
	if env.is_empty():
		env = DataLoader.get_row("environments", "env_lava_foundry")
	return env

func _weapon_shot_sfx(id: String) -> String:
	match id:
		"weapon_apocalypse_inferno":
			return "apocalypse_inferno_ignition"
		"weapon_apocalypse_absolute_zero":
			return "apocalypse_absolute_zero_fire"
		"weapon_apocalypse_golden_law":
			return "apocalypse_golden_law_fire"
		"weapon_flamethrower":
			return "shot_flamethrower"
		"weapon_cryocannon":
			return "shot_cryocannon"
		"weapon_teslacoil":
			return "shot_teslacoil"
		"weapon_venomlauncher":
			return "shot_venomlauncher"
		"weapon_railgun":
			return "shot_railgun"
		"weapon_scattergun":
			return "shot_scattergun"
		"weapon_plasmacannon":
			return "shot_plasmacannon"
		_:
			return "shot_autocannon"

func _element_muzzle_sfx(element: String) -> String:
	match element:
		"fire":
			return "muzzle_fire"
		"ice":
			return "muzzle_ice"
		"lightning":
			return "muzzle_lightning"
		"poison":
			return "muzzle_poison"
		_:
			return "shot_autocannon"

func _element_hit_sfx(element: String) -> String:
	match element:
		"fire":
			return "hit_fire"
		"ice":
			return "hit_ice"
		"lightning":
			return "hit_lightning"
		"poison":
			return "hit_poison"
		_:
			return "hit_physical"

func _skill_sfx_id(skill_id: String) -> String:
	match skill_id:
		"skill_charge_shot":
			return "skill_pierce"
		"skill_split_shot", "skill_pierce", "skill_multishot", "skill_slow_field", "skill_homing", "skill_critical", "skill_barrier", "skill_gold_rush", "skill_ricochet", "skill_salvo", "skill_incendiary", "skill_cryo", "skill_tesla", "skill_venom", "skill_recycle":
			return skill_id
		_:
			return ""

func _character_intro_sfx() -> String:
	match character_id:
		"blaze":
			return "char_blaze_intro"
		"frost":
			return "char_frost_intro"
		"volt":
			return "char_volt_intro"
		_:
			return "char_vanguard_intro"

func _zombie_mechanic_sfx(mechanic: String) -> String:
	match mechanic:
		"buff_aura":
			return "zombie_screamer"
		"ranged_spit":
			return "zombie_spitter"
		"shield_aura":
			return "zombie_shielder"
		"leap":
			return "zombie_hopper"
		"juggernaut":
			return "zombie_juggernaut"
		"phase", "phase_shift", "charge":
			return "zombie_phantom"
		"summon", "spawn_minions":
			return "zombie_necromancer"
		"toxic_cloud":
			return "zombie_toxic"
		"regen", "regenerate":
			return "zombie_regenerator"
		"split":
			return "zombie_splitter"
		"ward":
			return "zombie_warden"
		"mutate":
			return "zombie_mutant"
		"enrage":
			return "zombie_berserker"
		"runner":
			return "zombie_runner"
		"explode_on_death":
			return "zombie_bomber"
		"basic":
			return "zombie_shambler"
		"tank":
			return "zombie_brute"
		"armor", "armor_break":
			return "zombie_armored"
		"low_profile":
			return "zombie_crawler"
		_:
			return ""

func _zombie_event_sfx(mechanic: String, event: String) -> String:
	# One explicit owner per lifecycle event. Entry/ambient/passive visuals stay
	# silent; actions use their mechanic identity; every death uses the death cue
	# instead of accidentally replaying a charge, blink, summon or aura sound.
	match event:
		"action":
			return _zombie_mechanic_sfx(mechanic)
		"death":
			return "enemy_death"
		"entry", "ambient", "passive":
			return ""
		_:
			return ""

func _play_enemy_mechanic_sfx(source: Node, volume_db := -8.0, pitch_variation := 0.03) -> void:
	if source == null or not is_instance_valid(source):
		return
	var sfx_id := _zombie_event_sfx(str(source.get("mechanic")), "action")
	if sfx_id != "":
		AudioManager.play_enemy_sfx(sfx_id, volume_db, pitch_variation)

func _element_name(element: String) -> String:
	match element:
		"physical":
			return "物理"
		"fire":
			return "火焰"
		"ice":
			return "冰霜"
		"lightning":
			return "闪电"
		"poison":
			return "毒素"
		_:
			return element

func _boss_intro_sfx(boss_id: String) -> String:
	match boss_id:
		"boss_inferno_maw":
			return "boss_intro_inferno_maw"
		"boss_frost_warden":
			return "boss_intro_frost_warden"
		"boss_storm_caller":
			return "boss_intro_storm_caller"
		"boss_plague_mother":
			return "boss_intro_plague_mother"
		"boss_void_phantom":
			return "boss_intro_void_phantom"
		"boss_necrotitan":
			return "boss_intro_necrotitan"
		"boss_apex_overlord":
			return "boss_intro_apex_overlord"
		_:
			return "boss_intro_tank_titan"

func _spawn_float_text(world_pos: Vector2, text: String, color: Color, priority_override := false, font_size := 21, width := 220.0) -> void:
	var priority := priority_override or text.contains("首领") or text.contains("防线") or text.contains("基地") or text.contains("免疫") or text.contains("护盾") or text.contains("装甲") or text.contains("相位")
	if not _can_spawn_float_text(priority):
		return
	var label := Label.new()
	_track_transient_fx(label, "float_text")
	label.text = text
	label.position = world_pos
	label.size = Vector2(width, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UiKit.bumped_font_size(font_size))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Hud.add_child(label)
	var tween := label.create_tween()
	tween.parallel().tween_property(label, "position:y", label.position.y - 48.0, 0.55)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.55)
	tween.tween_callback(label.queue_free)
