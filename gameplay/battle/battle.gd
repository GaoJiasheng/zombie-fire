extends Node2D

const ENEMY_SCENE := preload("res://gameplay/enemy/enemy.tscn")
const TURRET_SCENE := preload("res://gameplay/turret/turret.tscn")
const PROJECTILE_SCENE := preload("res://gameplay/projectile/projectile.tscn")
const CharacterSkillText := preload("res://core/data/character_skill_text.gd")
const SkillEffectText := preload("res://core/data/skill_effect_text.gd")
const SequenceVfx := preload("res://gameplay/vfx/sequence_vfx.gd")
const VfxLib := preload("res://gameplay/vfx/vfx_lib.gd")
const SLOW_FIELD_SHADER := preload("res://gameplay/vfx/shaders/vfx_slow_field.gdshader")
const UiKit := preload("res://ui/ui_kit.gd")
const SCREEN_FLASH_TEXTURE := preload("res://assets/production/sprites/ui/ui_panel_skin.png")
const SLOW_FIELD_BAND_TEXTURE := preload("res://assets/production/sprites/vfx/vfx_slow_field_band.png")
const BUTTON_PRIMARY_PATH := "res://assets/production/sprites/ui/ui_button_primary.png"
const BUTTON_SECONDARY_PATH := "res://assets/production/sprites/ui/ui_button_secondary.png"
const BREACH_Y := 1500.0
const CHARACTER_BASE_POSITION := Vector2(540, 1652)
const CHARACTER_VISUAL_BASE_SCALE := 0.512
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
	"char_vanguard/weapon_autocannon": Vector2(40.3, -162.6),
	"char_vanguard/weapon_flamethrower": Vector2(42.9, -162.2),
	"char_vanguard/weapon_cryocannon": Vector2(36.5, -159.7),
	"char_vanguard/weapon_teslacoil": Vector2(41.6, -162.3),
	"char_vanguard/weapon_venomlauncher": Vector2(31.4, -160.3),
	"char_vanguard/weapon_railgun": Vector2(37.1, -162.6),
	"char_vanguard/weapon_scattergun": Vector2(32.3, -160.7),
	"char_vanguard/weapon_plasmacannon": Vector2(33.0, -159.6),
	"char_blaze/weapon_autocannon": Vector2(32.6, -161.9),
	"char_blaze/weapon_flamethrower": Vector2(56.3, -162.6),
	"char_blaze/weapon_cryocannon": Vector2(36.5, -162.6),
	"char_blaze/weapon_teslacoil": Vector2(40.3, -162.3),
	"char_blaze/weapon_venomlauncher": Vector2(37.8, -162.6),
	"char_blaze/weapon_railgun": Vector2(31.0, -160.6),
	"char_blaze/weapon_scattergun": Vector2(38.2, -160.9),
	"char_blaze/weapon_plasmacannon": Vector2(26.1, -159.7),
	"char_frost/weapon_autocannon": Vector2(22.4, -160.5),
	"char_frost/weapon_flamethrower": Vector2(33.9, -156.6),
	"char_frost/weapon_cryocannon": Vector2(23.6, -158.9),
	"char_frost/weapon_teslacoil": Vector2(23.5, -160.9),
	"char_frost/weapon_venomlauncher": Vector2(23.0, -160.3),
	"char_frost/weapon_railgun": Vector2(29.9, -160.9),
	"char_frost/weapon_scattergun": Vector2(22.1, -160.0),
	"char_frost/weapon_plasmacannon": Vector2(25.0, -153.9),
	"char_volt/weapon_autocannon": Vector2(32.6, -161.9),
	"char_volt/weapon_flamethrower": Vector2(31.0, -161.9),
	"char_volt/weapon_cryocannon": Vector2(36.5, -160.9),
	"char_volt/weapon_teslacoil": Vector2(28.2, -160.6),
	"char_volt/weapon_venomlauncher": Vector2(32.0, -160.6),
	"char_volt/weapon_railgun": Vector2(30.7, -161.9),
	"char_volt/weapon_scattergun": Vector2(34.1, -160.0),
	"char_volt/weapon_plasmacannon": Vector2(31.4, -155.3),
}
const CHARACTER_WEAPON_COMBO_MUZZLE_LEFT := {
	"char_vanguard/weapon_autocannon": Vector2(-86.2, -151.9),
	"char_vanguard/weapon_flamethrower": Vector2(-87.7, -147.8),
	"char_vanguard/weapon_cryocannon": Vector2(-79.8, -146.0),
	"char_vanguard/weapon_teslacoil": Vector2(-86.4, -149.1),
	"char_vanguard/weapon_venomlauncher": Vector2(-75.8, -146.9),
	"char_vanguard/weapon_railgun": Vector2(-81.9, -149.8),
	"char_vanguard/weapon_scattergun": Vector2(-75.9, -147.6),
	"char_vanguard/weapon_plasmacannon": Vector2(-75.5, -146.2),
	"char_blaze/weapon_autocannon": Vector2(-77.1, -149.4),
	"char_blaze/weapon_flamethrower": Vector2(-100.8, -150.2),
	"char_blaze/weapon_cryocannon": Vector2(-81.3, -149.8),
	"char_blaze/weapon_teslacoil": Vector2(-85.1, -149.8),
	"char_blaze/weapon_venomlauncher": Vector2(-83.8, -149.8),
	"char_blaze/weapon_railgun": Vector2(-74.9, -150.0),
	"char_blaze/weapon_scattergun": Vector2(-82.0, -147.8),
	"char_blaze/weapon_plasmacannon": Vector2(-69.8, -146.9),
	"char_frost/weapon_autocannon": Vector2(-68.2, -149.4),
	"char_frost/weapon_flamethrower": Vector2(-76.2, -141.2),
	"char_frost/weapon_cryocannon": Vector2(-67.2, -146.3),
	"char_frost/weapon_teslacoil": Vector2(-67.5, -148.8),
	"char_frost/weapon_venomlauncher": Vector2(-67.8, -147.8),
	"char_frost/weapon_railgun": Vector2(-74.2, -146.9),
	"char_frost/weapon_scattergun": Vector2(-65.4, -147.8),
	"char_frost/weapon_plasmacannon": Vector2(-65.1, -142.5),
	"char_volt/weapon_autocannon": Vector2(-77.4, -149.8),
	"char_volt/weapon_flamethrower": Vector2(-75.5, -149.1),
	"char_volt/weapon_cryocannon": Vector2(-81.3, -148.1),
	"char_volt/weapon_teslacoil": Vector2(-71.5, -148.7),
	"char_volt/weapon_venomlauncher": Vector2(-76.2, -149.8),
	"char_volt/weapon_railgun": Vector2(-75.5, -149.8),
	"char_volt/weapon_scattergun": Vector2(-77.8, -147.6),
	"char_volt/weapon_plasmacannon": Vector2(-67.2, -144.2),
}
const CHARACTER_WEAPON_COMBO_MUZZLE_RIGHT := {
	"char_vanguard/weapon_autocannon": Vector2(81.0, -154.4),
	"char_vanguard/weapon_flamethrower": Vector2(82.6, -150.4),
	"char_vanguard/weapon_cryocannon": Vector2(75.2, -148.2),
	"char_vanguard/weapon_teslacoil": Vector2(81.3, -151.7),
	"char_vanguard/weapon_venomlauncher": Vector2(69.8, -149.5),
	"char_vanguard/weapon_railgun": Vector2(76.8, -151.7),
	"char_vanguard/weapon_scattergun": Vector2(70.1, -150.7),
	"char_vanguard/weapon_plasmacannon": Vector2(71.4, -148.2),
	"char_blaze/weapon_autocannon": Vector2(72.6, -151.4),
	"char_blaze/weapon_flamethrower": Vector2(96.0, -153.3),
	"char_blaze/weapon_cryocannon": Vector2(76.2, -152.3),
	"char_blaze/weapon_teslacoil": Vector2(80.0, -152.3),
	"char_blaze/weapon_venomlauncher": Vector2(78.7, -152.3),
	"char_blaze/weapon_railgun": Vector2(70.1, -152.0),
	"char_blaze/weapon_scattergun": Vector2(77.8, -149.8),
	"char_blaze/weapon_plasmacannon": Vector2(64.6, -148.8),
	"char_frost/weapon_autocannon": Vector2(63.0, -151.4),
	"char_frost/weapon_flamethrower": Vector2(71.5, -143.1),
	"char_frost/weapon_cryocannon": Vector2(62.4, -148.2),
	"char_frost/weapon_teslacoil": Vector2(62.4, -150.7),
	"char_frost/weapon_venomlauncher": Vector2(62.1, -150.0),
	"char_frost/weapon_railgun": Vector2(68.7, -149.8),
	"char_frost/weapon_scattergun": Vector2(61.1, -149.4),
	"char_frost/weapon_plasmacannon": Vector2(60.2, -144.3),
	"char_volt/weapon_autocannon": Vector2(72.3, -152.3),
	"char_volt/weapon_flamethrower": Vector2(70.4, -151.7),
	"char_volt/weapon_cryocannon": Vector2(75.8, -150.4),
	"char_volt/weapon_teslacoil": Vector2(67.2, -151.0),
	"char_volt/weapon_venomlauncher": Vector2(71.0, -151.7),
	"char_volt/weapon_railgun": Vector2(70.4, -152.3),
	"char_volt/weapon_scattergun": Vector2(72.8, -149.8),
	"char_volt/weapon_plasmacannon": Vector2(68.5, -142.5),
}
const WEAPON_VISUAL_PROFILES := {
	"weapon_railgun": "rail",
	"weapon_scattergun": "scatter",
	"weapon_plasmacannon": "plasma",
}
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
const CHARACTER_WEAPON_ACTION_FRAME_COUNT := 7
const CHARACTER_WEAPON_ATTACK_DURATION := {
	"weapon_autocannon": 0.30,
	"weapon_cryocannon": 0.34,
	"weapon_flamethrower": 0.36,
	"weapon_plasmacannon": 0.36,
	"weapon_railgun": 0.38,
	"weapon_scattergun": 0.40,
	"weapon_teslacoil": 0.32,
	"weapon_venomlauncher": 0.36,
}
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
const HUD_HP_FILL_RIGHT := 812.0
const HUD_WAVE_FILL_RIGHT := 812.0
const HUD_XP_FILL_RIGHT := 778.0
const ENABLE_DEBUG_OVERLAY := false
const MAX_PROJECTILE_TRANSIENT_FX := 150
const MAX_PROJECTILE_PRIORITY_FX := 185
const MAX_HUD_TRANSIENT_FX := 52
const MAX_HUD_PRIORITY_FX := 68
const MAX_FLOAT_TEXTS := 8
const MAX_PRIORITY_FLOAT_TEXTS := 12
# 多重射击每条弹道之间的固定夹角(度)。固定=不 imba；扇形中心对准敌群。
const MULTISHOT_LANE_DEG := 7.0
# 基地单次受伤上限 = 最大血量的比例。防止 Boss/技能"一下打死"，任何来源都受此限制。
const MAX_BASE_HIT_FRACTION := 0.4
# 第4/5波单独加血量(绝不加速度)：局内前几波卡牌叠加后输出膨胀明显，后两波用血量拉回张力。
# 只对普通僵尸生效，不叠加到 Boss 身上(Boss 已单独调过速度/血量)。
const LATE_WAVE_HP_BONUS := {4: 1.20, 5: 1.35}
const WAVE_TOAST_BASE_POSITION := Vector2(280, 136)
const WAVE_TOAST_SIZE := Vector2(520, 58)
const WAVE_TOAST_LONG_SIZE := Vector2(520, 128)
const ACTIVE_SKILL_DOT_COUNT := 8
const FROST_GLACIER_MIN_DURATION := 5.0
const FROST_GLACIER_TICK_INTERVAL := 0.52
const FROST_GLACIER_STATUS_REFRESH := 0.86
const FROST_GLACIER_NORMAL_SPEED := 0.40
const FROST_GLACIER_BOSS_SPEED := 0.62
const PREFINAL_CARD_OFFER_XP_RATIO := 0.85
const MANUAL_AIM_RELEASE_GRACE := 0.18

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
# 无限尸潮：复用当前关卡数据循环刷完的波次，每轮血量按 ENDLESS_LOOP_HP_GROWTH 递增，
# 只在漏怪耗尽基地生命时结束(没有"胜利"结算)，奖励按撑过的轮数发放。
var is_endless_mode := false
var endless_loop := 0
var endless_difficulty_mult := 1.0
const ENDLESS_LOOP_HP_GROWTH := 0.16
var level_ordinal := 1
var econ_gold_base := 5.0
var econ_gold_per := 0.6
var econ_xp_growth := 0.06
var pending_spawns: Array = []
var spawn_timer := 0.0
var wave_index := 0
var wave_total := 0
var active_spawning := false
var turret: Node2D
var target_manager := TargetingManager.new()
var card_director := CardDirector.new()
var skills := SkillRuntime.new()
var next_xp_offer := 12
var card_offer_active := false
var reroll_charges := 1
var cards_picked := 0
var level_total_run_xp := 0
var target_card_picks := 3
var paused := false
var manual_aim_active := false
var manual_aim_point := Vector2(540, 600)
var manual_aim_until := 0.0
var battle_finished := false
var pre_final_offer_used := false
var debug_overlay_on := false
var slow_field_rect: TextureRect
var slow_field_particles: GPUParticles2D
var slow_field_edge_lines: Array[Line2D] = []
var slow_field_rune_layer: Node2D
var card_press_skill_id := ""
var card_press_started_at := 0.0
var card_long_press_opened := false
var skill_hint_press_kind := ""
var skill_hint_press_skill_id := ""
var skill_hint_press_started_at := 0.0
var skill_hint_long_press_opened := false
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
var character_attack_duration := 0.30
var pet_idle_frames: Array[Texture2D] = []
var pet_attack_frames: Array[Texture2D] = []
var pet_anim_time := 0.0
var pet_anim_frame := 0
var pet_attack_time := 0.0
var pet_cooldown := 0.0
var breach_shields := 0
var skill_barriers_left := 0
var barrier_visual: Node2D
var barrier_fill: Polygon2D
var barrier_edges: Array[Line2D] = []
var gold_mult := 1.0
var breach_damage_mult := 1.0
var crit_rate := 0.0
var pierce_bonus := 0
var element_damage_bonus := 1.0
var slow_strength_bonus := 1.0
var chain_bonus := 0
var skill_fire_rate_mult := 1.0
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
var boss_hp_fill: TextureRect = null
var boss_hp_label: Label = null
var last_threat_warning_at := -99.0
var last_gold_sfx_at := -99.0
var primary_weakness := "physical"
var loadout_power_ratio := 1.0
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
var displayed_wave_pct := 0.0
var displayed_xp_pct := 0.0
var build_feedback_shown := {}
var weak_kill_feedback_count := 0
var weak_kill_feedback_pending := false
var last_weak_kill_feedback_at := -99.0

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

func setup(main: Node, payload := {}) -> void:
	router = main
	level_id = _resolve_level_id(payload)
	is_endless_mode = bool(payload.get("endless", false))

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	Engine.time_scale = 1.0
	# HUD controls must receive GUI input both during battle and while card
	# offers pause the tree; individual buttons decide their own enabled state.
	$Hud.process_mode = Node.PROCESS_MODE_ALWAYS
	_configure_pause_process_modes()
	level = DataLoader.get_row("levels", level_id)
	_apply_level_background()
	level_ordinal = maxi(1, int(str(level_id).get_slice("_", 1)))
	var _econ: Dictionary = DataLoader.get_table("economy")
	econ_gold_base = float(_econ.get("gold_drop_base", 5))
	econ_gold_per = float(_econ.get("gold_drop_per_level", 0.6))
	econ_xp_growth = float(_econ.get("xp_per_kill_growth", 0.06))
	AudioManager.play_bgm(_battle_bgm_id())
	primary_weakness = str(level.get("primary_weakness", "physical"))
	onboarding_stage = str(level.get("onboarding_stage", ""))
	_apply_variant_modifiers()
	loadout_power_ratio = float(SaveManager.get_loadout_power()) / maxf(float(SaveManager.get_recommended_power_for_level(level_id)), 1.0)
	wave_total = int(level.get("waves", []).size())
	base_hp_max = int(level.get("base_hp_ref", 100))
	base_hp = base_hp_max
	xp = 0
	gold = 0
	cards_picked = 0
	target_card_picks = maxi(1, int(level.get("target_card_picks", 3)))
	level_total_run_xp = _compute_level_total_run_xp()
	next_xp_offer = _pick_threshold(1)
	reroll_charges = 1
	battle_finished = false
	pre_final_offer_used = false
	skill_fire_rate_mult = 1.0
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
	onboarding_tip_shown = false
	wave_tip_shown = {}
	kill_streak = 0
	last_kill_at = -99.0
	displayed_wave_pct = 0.0
	displayed_xp_pct = 0.0
	build_feedback_shown = {}
	$Hud/DebugOverlay.visible = false
	$Hud/PauseOverlay.visible = false
	$Hud/CardPanel.visible = false
	_apply_runtime_ui_styles()
	_ensure_skill_hint_overlay()
	_apply_safe_area()
	_ensure_boss_hp_bar()
	_spawn_low_hp_pulse()
	_spawn_feedback_managers()
	add_child(target_manager)
	_load_equipment()
	_configure_character_active_skill()
	_seed_character_affinity()
	_apply_base_survivability()
	turret = TURRET_SCENE.instantiate()
	turret.position = Vector2(540, 1660)
	turret.setup(DataLoader.get_row("weapons", weapon_id), weapon_level)
	_apply_turret_modifiers()
	turret.visible = false
	turret.fired.connect(_on_turret_fired)
	add_child(turret)
	turret.process_mode = Node.PROCESS_MODE_PAUSABLE
	_spawn_character()
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
		card_press_skill_id = ""
		card_long_press_opened = false
		skill_hint_press_kind = ""
		skill_hint_long_press_opened = false
		Engine.time_scale = 1.0
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
	_sync_logic_turret_to_character()
	_update_auto_target()
	_process_character_animation(delta)
	_process_character_signatures(delta)
	_process_pet(delta)
	_process_enemy_mechanics(delta)
	_apply_slow_field()
	_process_spawns(delta)
	_check_victory()
	_update_lock_indicator()
	_update_off_screen_indicators()
	_update_hud()

func _update_auto_target() -> void:
	var has_fireable_target := _has_fireable_targets()
	_set_turret_fire_enabled(has_fireable_target)
	if not has_fireable_target:
		return
	if _manual_aim_has_priority():
		_apply_manual_aim()
		return
	var enemies := $EnemyLayer.get_children()
	var target := target_manager.choose_target(enemies, _weapon_fire_origin(false))
	if target:
		turret.aim_at(target.global_position)
	else:
		_set_turret_fire_enabled(false)

func _set_turret_fire_enabled(enabled: bool) -> void:
	if turret == null or not is_instance_valid(turret):
		return
	turret.set("fire_enabled", enabled)

func _has_fireable_targets() -> bool:
	for enemy in $EnemyLayer.get_children():
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
	return Vector2(clampf(world_pos.x, 0.0, 1080.0), clampf(world_pos.y, 0.0, 1920.0))

func _now_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0

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
	character_active_cd_max = float(active.get("cooldown", 16.0))
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
		cd_label.add_theme_font_size_override("font_size", 24)
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
	if inside:
		_show_character_skill_hint()
	else:
		_hide_skill_hint()
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
	overlay.offset_left = -335.0
	overlay.offset_right = 335.0
	overlay.offset_top = 1560.0
	overlay.offset_bottom = 1730.0
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
	text_box.custom_minimum_size = Vector2(500, 128)
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_theme_constant_override("separation", 8)
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_box)

	var title := UiKit.label("", 26, UiKit.TEXT_MAIN, 3)
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.clip_text = true
	title.custom_minimum_size = Vector2(500, 34)
	text_box.add_child(title)

	var body := UiKit.label("", 19, Color(0.78, 0.9, 0.94, 1.0), 2)
	body.name = "Body"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.clip_text = true
	body.custom_minimum_size = Vector2(500, 86)
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
	var title := "%s  等级%d" % [DataLoader.tr_key(str(row.get("name_key", skill_id))), lv]
	var body := "效果：%s\n说明：%s" % [effect, _skill_short_desc(skill_id, lv)]
	_show_skill_hint(title, body, str(row.get("icon", "")), _skill_card_accent(skill_id, row))

func _show_character_skill_hint() -> void:
	if character_active_id == "":
		return
	var info: Dictionary = CharacterSkillText.signature_info(character_active_id)
	var cooldown := "冷却 %.0f 秒" % character_active_cd_max
	var title := "%s  主动技能" % str(info.get("name", "角色技能"))
	var body := "%s\n%s" % [cooldown, str(info.get("desc", ""))]
	_show_skill_hint(title, body, _character_active_icon_path(), _character_skill_accent())

func _show_skill_hint(title_text: String, body_text: String, icon_path: String, accent: Color) -> void:
	_ensure_skill_hint_overlay()
	if not has_node("Hud/SkillHintOverlay"):
		return
	var overlay := $Hud/SkillHintOverlay as PanelContainer
	overlay.visible = true
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
		title.add_theme_color_override("font_color", Color(0.96, 0.94, 0.86, 1.0))
	var body := overlay.get_node_or_null("Margin/Row/TextBox/Body") as Label
	if body != null:
		body.text = body_text

func _hide_skill_hint() -> void:
	if has_node("Hud/SkillHintOverlay"):
		$Hud/SkillHintOverlay.visible = false
	skill_hint_press_kind = ""
	skill_hint_press_skill_id = ""
	skill_hint_long_press_opened = false

func _begin_skill_hint_press(kind: String, skill_id: String) -> void:
	skill_hint_press_kind = kind
	skill_hint_press_skill_id = skill_id
	skill_hint_press_started_at = Time.get_ticks_msec() / 1000.0
	skill_hint_long_press_opened = false

func _end_skill_hint_press() -> void:
	if skill_hint_long_press_opened:
		if skill_hint_press_kind == "character":
			suppress_next_character_skill_press = true
		_hide_skill_hint()
	else:
		skill_hint_press_kind = ""
		skill_hint_press_skill_id = ""

# Seed the equipped weapon's intrinsic element skill at level 1 so the
# build is visible from the first frame. Anchored on the weapon (not
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
	if card_offer_active or paused or character_active_id == "" or character_active_cd > 0.0:
		return
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
	_play_character_skill()
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
	_active_skill_cast_intro("弹幕齐射", Color(1.0, 0.88, 0.42), "level_up")
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
	AudioManager.play_sfx("threat_warning", -4.0, 0.02)
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
	_active_skill_cast_intro("熔毁爆发", Color(1.0, 0.42, 0.14), "muzzle_fire")
	_spawn_vfx_sequence("vfx_muzzle_fire", _weapon_fire_origin() + Vector2(0, -38), 0.92, Color(1.0, 0.58, 0.2, 0.86), 1.35, _weapon_fire_direction().angle(), 1.08, Vector2.ZERO, 0.0, true)
	_spawn_vfx_sequence("vfx_explosion_fire", origin + Vector2(0, -44), maxf(radius / 300.0, 0.72), Color(1.0, 0.48, 0.16, 0.86), 0.92, randf_range(-0.24, 0.24), 1.16, Vector2(0, -12), randf_range(-0.25, 0.25), true)
	for i in range(_blaze_meltdown_pulse_count(active)):
		_active_skill_after(0.16 + float(i) * 0.22, Callable(self, "_blaze_meltdown_pulse").bind(origin, radius, damage, i))
	return true

func _cast_frost_glacier() -> bool:
	var active: Dictionary = character_data.get("active_skill", {})
	sig_frost_glacier_timer = _frost_glacier_duration(active)
	sig_frost_glacier_tick = 0.0
	var field_y := _frost_glacier_field_y(active)
	var tick_damage := _character_active_damage("ice", float(active.get("damage_mult", 0.34)))
	_active_skill_cast_intro("冰川领域", Color(0.55, 0.9, 1.0), "muzzle_ice")
	_spawn_vfx_sequence("vfx_muzzle_ice", _weapon_fire_origin() + Vector2(0, -42), 0.9, Color(0.66, 0.94, 1.0, 0.86), 1.35, _weapon_fire_direction().angle(), 1.08, Vector2.ZERO, 0.0, true)
	_spawn_vfx_sequence("vfx_freeze", Vector2(540, 1180), 2.05, Color(0.6, 0.92, 1.0, 0.46), 0.86, 0.0, 1.05, Vector2(0, -8), 0.0, true)
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
	for enemy in $EnemyLayer.get_children():
		if not is_instance_valid(enemy) or enemy.global_position.y < field_y:
			continue
		affected += 1
		_apply_frost_glacier_status(enemy, tick_damage, FROST_GLACIER_STATUS_REFRESH)
		if should_tick and enemy.has_method("take_damage"):
			enemy.take_damage(tick_damage, "ice")
	if should_tick:
		var alpha := 0.34 + minf(float(affected), 7.0) * 0.018
		_spawn_vfx_sequence("vfx_freeze", Vector2(540, 1135), 1.8, Color(0.56, 0.92, 1.0, alpha), 0.9, 0.0, 1.04, Vector2(0, -8), 0.0, true)

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
	_active_skill_cast_intro("雷暴领域", Color(1.0, 0.9, 0.2), "muzzle_lightning")
	_spawn_vfx_sequence("vfx_muzzle_lightning", _weapon_fire_origin() + Vector2(0, -40), 1.0, Color(1.0, 0.92, 0.28, 0.86), 1.45, _weapon_fire_direction().angle(), 1.1, Vector2.ZERO, 0.0, true)
	_spawn_vfx_sequence("vfx_chain_lightning", _active_skill_fallback_point(0.38) + Vector2(0, -52), 1.2, Color(1.0, 0.94, 0.28, 0.62), 1.1, randf_range(-0.3, 0.3), 1.1, Vector2(0, -18), randf_range(-0.45, 0.45), true)
	for i in range(strike_count):
		_active_skill_after(0.08 + float(i) * 0.17, Callable(self, "_volt_storm_strike").bind(i, max_targets, damage))
	_active_skill_after(0.12 + float(strike_count) * 0.17, Callable(self, "_active_skill_finish_flash").bind(Color(1.0, 0.9, 0.2, 0.12), 0.2))
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
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
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

func _active_skill_can_continue() -> bool:
	return is_inside_tree() and not battle_finished and has_node("EnemyLayer") and has_node("ProjectileLayer")

func _active_skill_cast_intro(title: String, color: Color, sfx_id: String) -> void:
	AudioManager.play_sfx(sfx_id, -2.0, 0.02)
	_show_wave_toast(title, color)
	_show_screen_flash(Color(color.r, color.g, color.b, 0.08), 0.16)
	_active_skill_screen_shake(5.5, 0.12)
	var cast_origin := _weapon_fire_origin()
	var sequence_id := "vfx_levelup_glow"
	match sfx_id:
		"muzzle_fire":
			sequence_id = "vfx_muzzle_fire"
		"muzzle_ice":
			sequence_id = "vfx_muzzle_ice"
		"muzzle_lightning":
			sequence_id = "vfx_muzzle_lightning"
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
		AudioManager.play_sfx("shot_autocannon", -8.0, 0.02)
	var targets := _active_target_candidates(3)
	if targets.is_empty():
		var points := _active_skill_fallback_chain_points(3)
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

func _blaze_meltdown_pulse(origin: Vector2, radius: float, damage: float, pulse_index: int) -> void:
	if not _active_skill_can_continue():
		return
	var offsets := [
		Vector2.ZERO,
		Vector2(-radius * 0.24, -70.0),
		Vector2(radius * 0.26, 24.0),
		Vector2(0.0, -128.0),
	]
	var weights := [0.18, 0.22, 0.26, 0.3, 0.24, 0.2, 0.16]
	var local_origin: Vector2
	if pulse_index < offsets.size():
		local_origin = origin + offsets[pulse_index]
	else:
		var angle := TAU * float(pulse_index - offsets.size()) / 3.0 + 0.35
		local_origin = origin + Vector2(cos(angle), sin(angle)) * radius * 0.34 + Vector2(0, -62)
	var local_radius := radius * (0.48 + 0.12 * float(pulse_index))
	AudioManager.play_sfx("muzzle_fire", -7.0, randf_range(-0.03, 0.04))
	_spawn_vfx_sequence("vfx_explosion_fire", local_origin + Vector2(0, -44), 0.9 + 0.18 * float(pulse_index), Color(1.0, 0.42, 0.12, 0.9), 1.0, randf_range(-0.22, 0.22), 1.18, Vector2(0, -20), randf_range(-0.3, 0.3), true)
	for spark_index in range(3):
		var angle := TAU * (float(spark_index) / 3.0) + float(pulse_index) * 0.42
		var burst_pos := local_origin + Vector2(cos(angle), sin(angle)) * local_radius * randf_range(0.22, 0.48) + Vector2(0, -38)
		_spawn_vfx_sequence("vfx_hit_fire", burst_pos, 0.56 + 0.08 * float(pulse_index), Color(1.0, 0.48, 0.16, 0.72), 1.2, randf_range(-0.35, 0.35), 1.12, Vector2(0, -16), randf_range(-0.4, 0.4))
	for enemy in $EnemyLayer.get_children():
		if not is_instance_valid(enemy) or not enemy is Node2D or not enemy.has_method("take_damage"):
			continue
		var dist: float = (enemy as Node2D).global_position.distance_to(local_origin)
		if dist > local_radius:
			continue
		var falloff := 1.0 - clampf(dist / local_radius, 0.0, 1.0)
		_active_skill_apply_hit(enemy, damage * weights[mini(pulse_index, weights.size() - 1)] * (0.58 + falloff * 0.42), "fire")
	_active_skill_screen_shake(5.0 + float(pulse_index) * 1.8, 0.12)
	if pulse_index == 3:
		_show_screen_flash(Color(1.0, 0.38, 0.12, 0.12), 0.2)

func _frost_glacier_wave(wave_y: float, tick_damage: float, wave_index: int) -> void:
	if not _active_skill_can_continue():
		return
	var center := Vector2(540, wave_y)
	var radius := 390.0 + float(wave_index) * 48.0
	AudioManager.play_sfx("muzzle_ice", -8.0, randf_range(-0.03, 0.03))
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
	AudioManager.play_sfx("muzzle_lightning", -8.0, randf_range(-0.025, 0.035))
	var strike_angle := (hit_position - start).angle()
	_spawn_vfx_sequence("vfx_chain_lightning", hit_position + Vector2(0, -54), 0.86, Color(1.0, 0.92, 0.24, 0.92), 1.55, strike_angle + randf_range(-0.28, 0.28), 1.08, Vector2(0, -20), randf_range(-0.5, 0.5), true)
	_spawn_vfx_sequence("vfx_hit_lightning", hit_position + Vector2(randf_range(-12.0, 12.0), -42.0), 0.7, Color(1.0, 0.94, 0.28, 0.82), 1.35, randf_range(-0.35, 0.35), 1.16, Vector2(0, -18), randf_range(-0.45, 0.45))
	if target != null and is_instance_valid(target):
		_active_skill_apply_hit(target, damage * 0.62, "lightning")
	_active_skill_screen_shake(4.2, 0.08)

func _refresh_character_fire_rate_buff() -> void:
	if turret == null:
		return
	var next_mult := 1.0
	if sig_vanguard_barrage_timer > 0.0:
		var active: Dictionary = character_data.get("active_skill", {})
		next_mult *= _vanguard_railvolley_fire_rate_mult(active)
	if sig_vanguard_overload_timer > 0.0:
		next_mult *= 1.5
	if absf(next_mult - character_fire_rate_mult) <= 0.001:
		return
	turret.fire_rate *= next_mult / maxf(character_fire_rate_mult, 0.001)
	character_fire_rate_mult = next_mult

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
	var ready := character_active_cd <= 0.0 and not card_offer_active and not paused
	button.disabled = not ready
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if ready else Control.CURSOR_ARROW
	button.tooltip_text = "%s\n%s" % [str(info.get("name", "角色技能")), str(info.get("desc", ""))]
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
	var fill_height := maxf(button.size.y - 24.0, 1.0)
	if fill_texture != null:
		fill_texture.visible = ratio > 0.0
		fill_texture.position = Vector2(12.0, 12.0 + fill_height * (1.0 - ratio))
		fill_texture.size = Vector2(maxf(button.size.x - 24.0, 1.0), fill_height * ratio)
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
	var damage := 28.0 * _player_shot_damage_multiplier()
	damage *= float(character_data.get("base_atk", 100)) / 100.0
	damage *= 1.0 + float(character_data.get("atk_growth", 0.08)) * 0.52 * float(max(character_level - 1, 0))
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
		element = skills.projectile_element(str(weapon.get("element", "physical")))
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

const SIG_SKILL_LEVEL_DAMAGE_BONUS := 0.10  # 专属主动技每独立等级 +10% 伤害倍率(满5级 +50%)

func _character_active_power_scale(active: Dictionary) -> float:
	var level_delta := float(maxi(character_level - 1, 0))
	var rank := float(_growth_rank(character_level))
	var level_growth := float(active.get("level_damage_growth", 0.0))
	var rank_bonus := float(active.get("rank_damage_bonus", 0.0))
	var sig_level_bonus := float(SaveManager.get_sig_skill_level(character_id)) * SIG_SKILL_LEVEL_DAMAGE_BONUS
	return maxf(1.0, 1.0 + level_growth * level_delta + rank_bonus * rank + sig_level_bonus)

func _active_skill_duration(active: Dictionary, fallback: float) -> float:
	var base := float(active.get("duration", fallback))
	var rank_bonus := float(active.get("rank_duration_bonus", 0.0)) * float(_growth_rank(character_level))
	var level_bonus := float(active.get("level_duration_growth", 0.0)) * float(maxi(character_level - 1, 0))
	return maxf(fallback, base + rank_bonus + level_bonus)

func _vanguard_railvolley_count(active: Dictionary) -> int:
	var base := int(active.get("base_volleys", 5))
	var rank_bonus := int(active.get("rank_extra_volleys", 0)) * _growth_rank(character_level)
	var max_extra := int(active.get("max_extra_volleys", rank_bonus))
	return maxi(base + mini(rank_bonus, max_extra), base)

func _vanguard_railvolley_fire_rate_mult(active: Dictionary) -> float:
	var base := float(active.get("barrage_fire_rate_mult", 1.25))
	var rank_bonus := float(active.get("rank_fire_rate_bonus", 0.05)) * float(_growth_rank(character_level))
	var level_bonus := float(active.get("level_fire_rate_growth", 0.0)) * float(maxi(character_level - 1, 0))
	return maxf(1.0, base + rank_bonus + level_bonus)

func _blaze_meltdown_radius(active: Dictionary) -> float:
	var base := float(active.get("radius", 260.0))
	var level_bonus := base * float(active.get("level_radius_growth", 0.0)) * float(maxi(character_level - 1, 0))
	var rank_bonus := float(active.get("rank_radius_bonus", 24.0)) * float(_growth_rank(character_level))
	return maxf(base, base + level_bonus + rank_bonus)

func _blaze_meltdown_pulse_count(active: Dictionary) -> int:
	var base := int(active.get("base_pulses", 4))
	var rank_bonus := int(active.get("rank_extra_pulses", 0)) * _growth_rank(character_level)
	return clampi(base + rank_bonus, base, 7)

func _frost_glacier_duration(active: Dictionary) -> float:
	return _active_skill_duration(active, FROST_GLACIER_MIN_DURATION)

func _frost_glacier_field_y(active: Dictionary) -> float:
	var base := float(active.get("field_y", 860.0))
	var extend := float(active.get("rank_field_y_extend", 0.0)) * float(_growth_rank(character_level))
	return clampf(base - extend, 640.0, base)

func _frost_glacier_wave_count(active: Dictionary) -> int:
	var base := int(active.get("base_waves", 4))
	var rank_bonus := int(active.get("rank_extra_waves", 0)) * _growth_rank(character_level)
	return clampi(base + rank_bonus, base, 7)

func _frost_glacier_slow_bonus(active: Dictionary) -> float:
	var level_bonus := float(active.get("level_slow_bonus_growth", 0.0)) * float(maxi(character_level - 1, 0))
	var rank_bonus := float(active.get("rank_slow_bonus", 0.0)) * float(_growth_rank(character_level))
	return _affinity_float("slow_bonus") + level_bonus + rank_bonus

func _frost_glacier_speed_factor(active: Dictionary, is_boss: bool) -> float:
	var base := FROST_GLACIER_BOSS_SPEED if is_boss else FROST_GLACIER_NORMAL_SPEED
	var rank_bonus := float(active.get("rank_slow_bonus", 0.0)) * float(_growth_rank(character_level)) * 0.35
	var level_bonus := float(active.get("level_slow_bonus_growth", 0.0)) * float(maxi(character_level - 1, 0)) * 0.45
	var floor_value := 0.52 if is_boss else 0.28
	return clampf(base - rank_bonus - level_bonus, floor_value, base)

func _volt_storm_max_targets(active: Dictionary) -> int:
	var base := int(active.get("max_targets", 6))
	var rank_bonus := int(active.get("rank_target_bonus", 0)) * _growth_rank(character_level)
	return maxi(base + rank_bonus, base)

func _volt_storm_strike_count(active: Dictionary, max_targets: int) -> int:
	var rank_bonus := int(active.get("rank_extra_strikes", 0)) * _growth_rank(character_level)
	return maxi(max_targets + 2 + rank_bonus, max_targets + 2)

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

func _apply_base_survivability() -> void:
	var hp_mult := float(character_data.get("base_hp", 100)) / 100.0
	hp_mult *= 1.0 + float(character_data.get("hp_growth", 0.06)) * 0.45 * float(max(character_level - 1, 0))
	hp_mult *= float(armor_data.get("hp_mult", 1.0))
	hp_mult *= 1.0 + float(armor_data.get("level_hp_growth", 0.018)) * float(max(armor_level - 1, 0))
	hp_mult *= _chip_multiplier("base_hp_mult")
	if loadout_power_ratio < 0.82:
		hp_mult *= 1.08
	base_hp_max = int(round(float(base_hp_max) * hp_mult))
	base_hp = base_hp_max
	breach_shields = int(armor_data.get("breach_shield", 0))
	skill_barriers_left = 0
	breach_damage_mult = 1.0 - _chip_value("breach_damage_reduction")
	if str(armor_data.get("resist", "none")) == primary_weakness:
		breach_damage_mult *= 0.88
	gold_mult = _chip_multiplier("gold_mult")
	if pet_data.get("role", "") == "economy":
		gold_mult *= 1.0 + _pet_scaled_value("gold_mult", "level_gold_growth")
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

func _apply_turret_modifiers() -> void:
	var attack_mult := float(character_data.get("base_atk", 100)) / 100.0
	attack_mult *= 1.0 + float(character_data.get("atk_growth", 0.08)) * 0.45 * float(max(character_level - 1, 0))
	attack_mult *= _chip_multiplier("damage_mult")
	var weapon_element := str(DataLoader.get_row("weapons", weapon_id).get("element", "physical"))
	if weapon_element != "physical":
		attack_mult *= _chip_multiplier("element_damage_mult")
	turret.damage_mult *= attack_mult
	turret.fire_rate *= float(character_data.get("fire_rate_mod", 1.0)) * _chip_multiplier("fire_rate_mult") * (1.0 + 0.01 * float(max(chip_level - 1, 0)))
	turret.turn_speed *= float(character_data.get("aim_turn_speed", 1.0))
	crit_rate = float(character_data.get("crit_rate_base", 0.0)) + _chip_value("crit_rate")
	pierce_bonus = int(round(_chip_value("pierce_bonus")))
	element_damage_bonus = 1.0
	chain_bonus = 0

func _chip_multiplier(stat: String) -> float:
	return 1.0 + _chip_value(stat)

func _chip_value(stat: String) -> float:
	if chip_data.get("stat", "") != stat:
		return 0.0
	var value := float(chip_data.get("value", 0.0))
	if stat == "pierce_bonus":
		return value + float(_growth_rank(chip_level))
	var growth := float(chip_data.get("level_value_growth", 0.035))
	return value * (1.0 + growth * float(max(chip_level - 1, 0)))

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
	var viewport := Rect2(Vector2(0, 140), Vector2(1080, 1500))
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
		_refresh_pause_build_summary()
	else:
		_hide_skill_hint()
	$Hud/PauseOverlay.visible = paused
	get_tree().paused = paused or card_offer_active
	_update_character_skill_button()

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

func _pause_status_card() -> PanelContainer:
	var card := _pause_section("战场状态", UiKit.GOLD, 154)
	var body := card.get_child(0) as VBoxContainer
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	body.add_child(grid)
	grid.add_child(_pause_metric("关卡", DataLoader.level_display_name(level_id), UiKit.CYAN))
	grid.add_child(_pause_metric("建议等级", str(int(level.get("recommend_level", 1))), UiKit.GOLD))
	grid.add_child(_pause_metric("本关弱点", _element_name(primary_weakness), UiKit.element_color(primary_weakness)))
	grid.add_child(_pause_metric("防线生命", "%d/%d" % [base_hp, base_hp_max], UiKit.GREEN))
	return card

func _pause_loadout_card() -> PanelContainer:
	var card := _pause_section("出战配置", UiKit.CYAN, 190)
	var body := card.get_child(0) as VBoxContainer
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	body.add_child(grid)
	grid.add_child(_pause_metric("英雄", _display_name(character_data, character_id), UiKit.CYAN))
	grid.add_child(_pause_metric("武器", "%s  等级%d" % [_display_name(DataLoader.get_row("weapons", weapon_id), weapon_id), weapon_level], UiKit.GOLD))
	grid.add_child(_pause_metric("护甲", _display_name(armor_data, armor_id), UiKit.CYAN))
	grid.add_child(_pause_metric("芯片", _display_name(chip_data, chip_id), UiKit.GREEN))
	var pet_text := _display_name(pet_data, pet_id) if pet_id != "" else "未携带"
	grid.add_child(_pause_metric("宝宝", pet_text, UiKit.element_color(str(pet_data.get("element", "physical")))))
	var active_text := "未配置"
	if character_active_id != "":
		var active_info: Dictionary = CharacterSkillText.signature_info(character_active_id)
		active_text = "%s  %.0fs" % [str(active_info.get("name", character_active_id)), character_active_cd_max]
	grid.add_child(_pause_metric("主动", active_text, UiKit.PURPLE))
	return card

func _pause_skill_card() -> PanelContainer:
	var card := _pause_section("已带技能", UiKit.PURPLE, 218)
	var body := card.get_child(0) as VBoxContainer
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	body.add_child(grid)
	if skill_slot_ids.is_empty():
		var empty := UiKit.label("暂无技能，局内首次三选一会自动加入。", 22, UiKit.TEXT_MUTED, 2)
		empty.custom_minimum_size = Vector2(740, 72)
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		body.add_child(empty)
		return card
	for skill_id in skill_slot_ids:
		grid.add_child(_pause_skill_chip(skill_id))
	return card

func _pause_section(title_text: String, accent: Color, min_height: float) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, min_height)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", UiKit.panel_texture_style(12.0))
	var body := VBoxContainer.new()
	body.name = "Body"
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	card.add_child(body)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	body.add_child(header)
	var rail := TextureRect.new()
	rail.texture = load("res://assets/production/sprites/ui/ui_map_accent_strip.png")
	rail.custom_minimum_size = Vector2(18, 30)
	rail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rail.stretch_mode = TextureRect.STRETCH_SCALE
	rail.modulate = accent
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(rail)
	var title := UiKit.label(title_text, 21, Color(0.95, 0.90, 0.76, 1.0), 2)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)
	return card

func _pause_metric(label_text: String, value_text: String, accent: Color) -> PanelContainer:
	var metric := PanelContainer.new()
	metric.custom_minimum_size = Vector2(0, 54)
	metric.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metric.mouse_filter = Control.MOUSE_FILTER_IGNORE
	metric.add_theme_stylebox_override("panel", UiKit.pill_style(accent, Color(0.012, 0.018, 0.026, 0.76)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	metric.add_child(row)
	var key := UiKit.label(label_text, 17, Color(0.62, 0.78, 0.82, 1.0), 2)
	key.custom_minimum_size = Vector2(82, 0)
	key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(key)
	var value := UiKit.label(value_text, 20, UiKit.TEXT_MAIN, 2)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.clip_text = true
	row.add_child(value)
	return metric

func _pause_skill_chip(skill_id: String) -> PanelContainer:
	var row: Dictionary = DataLoader.get_row("skills", skill_id)
	var accent := UiKit.element_color(str(row.get("element", row.get("ammo_element", "physical"))))
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(178, 72)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", UiKit.pill_style(accent, Color(0.012, 0.018, 0.026, 0.82)))
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	chip.add_child(hbox)
	var icon := UiKit.icon(str(row.get("icon", UiKit.element_icon_path("physical"))), Vector2(46, 46))
	hbox.add_child(icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	hbox.add_child(col)
	var name := UiKit.label(DataLoader.tr_key(row.get("name_key", skill_id)), 16, UiKit.TEXT_MAIN, 2)
	name.clip_text = true
	col.add_child(name)
	var level := UiKit.label("等级%d" % skills.level(skill_id), 15, UiKit.GOLD, 2)
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
	boss_hp_bar.position = Vector2(160, 162)
	boss_hp_bar.size = Vector2(760, 64)
	boss_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_hp_bar.visible = false
	boss_hp_label = UiKit.label("", 24, UiKit.DANGER, 3)
	boss_hp_label.position = Vector2(0, 0)
	boss_hp_label.size = Vector2(760, 28)
	boss_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_hp_bar.add_child(boss_hp_label)
	var track := TextureRect.new()
	track.texture = load("res://assets/production/sprites/ui/ui_boss_hp_bar.png")
	track.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	track.stretch_mode = TextureRect.STRETCH_SCALE
	track.position = Vector2(0, 34)
	track.size = Vector2(760, 22)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_hp_bar.add_child(track)
	boss_hp_fill = TextureRect.new()
	boss_hp_fill.texture = load("res://assets/production/sprites/ui/ui_bar_fill_hp.png")
	boss_hp_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boss_hp_fill.stretch_mode = TextureRect.STRETCH_SCALE
	boss_hp_fill.position = Vector2(2, 36)
	boss_hp_fill.size = Vector2(756, 18)
	boss_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_hp_bar.add_child(boss_hp_fill)
	$Hud.add_child(boss_hp_bar)

func _update_boss_hp_bar() -> void:
	if boss_hp_bar == null or not is_instance_valid(boss_hp_bar):
		return
	if active_boss == null or not is_instance_valid(active_boss) or not active_boss.boss:
		boss_hp_bar.visible = false
		return
	var ratio := clampf(float(active_boss.hp) / maxf(float(active_boss.max_hp), 1.0), 0.0, 1.0)
	boss_hp_bar.visible = true
	boss_hp_fill.size.x = 756.0 * ratio
	var boss_name := DataLoader.tr_key(active_boss.data.get("name_key", "")) if active_boss.data is Dictionary else ""
	boss_hp_label.text = "%s  %d%%" % [boss_name, int(round(ratio * 100.0))]

func _apply_safe_area() -> void:
	# Only shift HUD for insets inside the game window (notch / home indicator).
	# Desktop windowed mode should stay at 0; monitor menu-bar safe area must not
	# push battle HUD into the middle of the screen.
	var insets := _viewport_safe_insets()
	if insets.top <= 0.0 and insets.bottom <= 0.0:
		return
	for path in ["Hud/TopBar", "PauseLayer/PauseButton"]:
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
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.y <= 0.0:
		return {"top": 0.0, "bottom": 0.0}
	var screen_size: Vector2i = DisplayServer.screen_get_size(DisplayServer.SCREEN_OF_MAIN_WINDOW)
	if screen_size.y <= 0:
		return {"top": 0.0, "bottom": 0.0}
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var usable_rect: Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.SCREEN_OF_MAIN_WINDOW)
	var scale_y := viewport_size.y / float(screen_size.y)
	var top := maxf(0.0, float(safe_area.position.y - usable_rect.position.y) * scale_y)
	var bottom := maxf(0.0, float(usable_rect.end.y - safe_area.end.y) * scale_y)
	return {
		"top": clampf(top, 0.0, 120.0),
		"bottom": clampf(bottom, 0.0, 120.0),
	}

func _apply_runtime_ui_styles() -> void:
	_layout_runtime_hud()
	_ensure_hud_fill_texture("Hud/TopBar/BaseHpBar", "res://assets/production/sprites/ui/ui_bar_fill_hp.png", 18.0, 16.0)
	_ensure_hud_fill_texture("Hud/TopBar/WaveProgress", "res://assets/production/sprites/ui/ui_bar_fill_wave.png", 15.0, 13.0)
	_style_xp_bar()
	if has_node("Hud/CardPanel"):
		var card_panel: Panel = $Hud/CardPanel
		card_panel.add_theme_stylebox_override("panel", UiKit.result_panel_texture_style())
		UiKit.apply_label($Hud/CardPanel/CardTitle, 37, UiKit.TEXT_MAIN, 4)
	if has_node("Hud/CardPanel/DetailOverlay/Panel"):
		var detail: Panel = $Hud/CardPanel/DetailOverlay/Panel
		detail.add_theme_stylebox_override("panel", UiKit.result_panel_texture_style())
		UiKit.apply_label($Hud/CardPanel/DetailOverlay/Panel/Title, 36, UiKit.TEXT_MAIN, 3)
		UiKit.apply_label($Hud/CardPanel/DetailOverlay/Panel/Body, 25, Color(0.82, 0.88, 0.88, 1.0), 2)
	if has_node("Hud/PauseOverlay/Panel"):
		var pause_panel: Panel = $Hud/PauseOverlay/Panel
		pause_panel.add_theme_stylebox_override("panel", UiKit.result_panel_texture_style())
		UiKit.apply_label($Hud/PauseOverlay/Panel/Title, 50, UiKit.TEXT_MAIN, 4)
		if has_node("Hud/PauseOverlay/Panel/BuildSummary"):
			UiKit.apply_label($Hud/PauseOverlay/Panel/BuildSummary, 21, Color(0.82, 0.88, 0.88, 1.0), 2)
		_setup_pause_overlay_layout()
	_setup_wave_toast_banner()

func _layout_runtime_hud() -> void:
	var top_bar := get_node_or_null("Hud/TopBar") as Control
	if top_bar != null:
		top_bar.offset_left = 142.0
		top_bar.offset_top = 16.0
		top_bar.offset_right = -142.0
		top_bar.offset_bottom = 126.0
		top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_layout_status_bar("Hud/TopBar/BaseHpBar", Vector2(0, 0), Vector2(796, 48), 18.0, 16.0, 22)
		_layout_status_bar("Hud/TopBar/WaveProgress", Vector2(0, 58), Vector2(796, 42), 15.0, 13.0, 18)
	var bottom_bar := get_node_or_null("Hud/BottomBar") as Control
	if bottom_bar != null:
		bottom_bar.offset_left = 28.0
		bottom_bar.offset_top = 1792.0
		bottom_bar.offset_right = -28.0
		bottom_bar.offset_bottom = 1894.0
		bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_layout_bottom_resource_bar()
	var skill_slots := get_node_or_null("Hud/SkillSlots") as HBoxContainer
	if skill_slots != null:
		# 固定锚定设计高度(1920)内的绝对位置,不锚定屏幕真实底部——
		# 否则在比 1080x1920 更高宽比的设备(如 iPhone 16 Pro Max)上会
		# 悬空脱离下方 HUD 群组,漂进黑色空白区域。
		skill_slots.anchor_top = 0.0
		skill_slots.anchor_bottom = 0.0
		skill_slots.offset_left = 174.0
		skill_slots.offset_top = 1684.0
		skill_slots.offset_right = -174.0
		skill_slots.offset_bottom = 1784.0
		skill_slots.add_theme_constant_override("separation", 10)
		skill_slots.alignment = BoxContainer.ALIGNMENT_CENTER
	var active_button := get_node_or_null("Hud/CharacterSkillButton") as Control
	if active_button != null:
		active_button.offset_left = -154.0
		active_button.offset_top = 1688.0
		active_button.offset_right = -34.0
		active_button.offset_bottom = 1808.0
	var pause_button := get_node_or_null("PauseLayer/PauseButton") as TextureButton
	if pause_button != null:
		pause_button.offset_left = 18.0
		pause_button.offset_top = 18.0
		pause_button.offset_right = 100.0
		pause_button.offset_bottom = 100.0
		pause_button.ignore_texture_size = true
		pause_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		pause_button.modulate = Color(0.92, 0.96, 1.0, 0.94)

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
		under.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := bar.get_node_or_null("FillTexture") as TextureRect
	if fill != null:
		fill.position = Vector2(6.0, fill_top)
		fill.size = Vector2(maxf(bar_size.x - 12.0, 1.0), fill_height)
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
	var gold_icon := get_node_or_null("Hud/BottomBar/GoldIcon") as TextureRect
	if gold_icon != null:
		gold_icon.position = Vector2(12.0, 20.0)
		gold_icon.size = Vector2(54, 54)
		gold_icon.custom_minimum_size = Vector2(54, 54)
	var gold_label := get_node_or_null("Hud/BottomBar/GoldLabel") as Label
	if gold_label != null:
		gold_label.position = Vector2(72.0, 16.0)
		gold_label.size = Vector2(140, 62)
		UiKit.apply_label(gold_label, 26, UiKit.GOLD, 3)
		gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var xp_icon := get_node_or_null("Hud/BottomBar/XpIcon") as TextureRect
	if xp_icon != null:
		xp_icon.position = Vector2(236.0, 25.0)
		xp_icon.size = Vector2(44, 44)
		xp_icon.custom_minimum_size = Vector2(44, 44)
	var xp_bar := get_node_or_null("Hud/BottomBar/XpBar") as Control
	if xp_bar != null:
		xp_bar.position = Vector2(292.0, 21.0)
		xp_bar.size = Vector2(704.0, 54.0)
		xp_bar.clip_contents = true
		var track := xp_bar.get_node_or_null("Track") as Panel
		if track != null:
			track.position = Vector2.ZERO
			track.size = Vector2(704.0, 54.0)
		var fill := xp_bar.get_node_or_null("Fill") as Panel
		if fill != null:
			fill.position = Vector2(7.0, 16.0)
			fill.size = Vector2(690.0, 22.0)
		var label := xp_bar.get_node_or_null("Label") as Label
		if label != null:
			label.position = Vector2.ZERO
			label.size = Vector2(704.0, 54.0)

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
		fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fill.stretch_mode = TextureRect.STRETCH_SCALE
		bar.add_child(fill)
	if ResourceLoader.exists(texture_path):
		fill.texture = load(texture_path)
	var fill_left := _hud_fill_left(bar_path, 6.0)
	var fill_right := _hud_fill_right(bar_path, maxf(bar.size.x - 6.0, 1.0))
	fill.position = Vector2(fill_left, top)
	fill.size = Vector2(maxf(fill_right - fill_left, 1.0), height)
	var label := bar.get_node_or_null("Label") as CanvasItem
	if label != null:
		label.z_index = 3

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
	var overlay := $Hud/PauseOverlay as Control
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := $Hud/PauseOverlay/Dim as Control
	dim.modulate = Color(0.0, 0.0, 0.0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel := $Hud/PauseOverlay/Panel as Panel
	panel.offset_left = 90.0
	panel.offset_top = 250.0
	panel.offset_right = 990.0
	panel.offset_bottom = 1428.0
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", UiKit.result_panel_texture_style())
	var title := $Hud/PauseOverlay/Panel/Title as Label
	title.position = Vector2(0, 32)
	title.size = Vector2(900, 70)
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
		content.add_theme_constant_override("separation", 14)
		panel.add_child(content)
	content.position = Vector2(54, 124)
	content.size = Vector2(792, 668)
	_layout_pause_action_button($Hud/PauseOverlay/Panel/ResumeButton as TextureButton, Vector2(78, 824), Vector2(744, 88), "res://assets/production/sprites/ui/icon_pause.png", "继续战斗", "恢复战场时间", true)
	_layout_pause_action_button($Hud/PauseOverlay/Panel/RestartButton as TextureButton, Vector2(78, 930), Vector2(744, 88), "res://assets/production/sprites/ui/icon_reroll_charge.png", "重打本关", "重新开始当前关卡", true)
	_layout_pause_action_button($Hud/PauseOverlay/Panel/MapButton as TextureButton, Vector2(78, 1036), Vector2(744, 88), "res://assets/production/sprites/ui/icon_settings.png", "返回关卡", "离开本局并回到关卡页", false)

func _layout_pause_action_button(button: TextureButton, pos: Vector2, button_size: Vector2, icon_path: String, title_text: String, subtitle_text: String, primary: bool) -> void:
	button.offset_left = pos.x
	button.offset_top = pos.y
	button.offset_right = pos.x + button_size.x
	button.offset_bottom = pos.y + button_size.y
	button.custom_minimum_size = button_size
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	var texture := load(BUTTON_PRIMARY_PATH if primary else BUTTON_SECONDARY_PATH)
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.texture_disabled = texture
	button.modulate = Color(1.0, 0.86, 0.56, 1.0) if primary else Color(0.82, 0.88, 0.92, 1.0)
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
	icon_plate.position = Vector2(18, 14)
	icon_plate.size = Vector2(62, 60)
	icon_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_plate.add_theme_stylebox_override("panel", UiKit.pill_style(UiKit.GOLD if primary else UiKit.BORDER_SOFT, Color(0.018, 0.022, 0.028, 0.78)))
	button.add_child(icon_plate)
	var icon := UiKit.icon(icon_path, Vector2(44, 44))
	icon.modulate = Color(1.0, 0.9, 0.62, 1.0) if primary else Color(0.82, 0.92, 1.0, 0.92)
	icon_plate.add_child(icon)
	var title := UiKit.label(title_text, 30, Color.WHITE, 3)
	title.name = "ActionTitle"
	title.position = Vector2(104, 12)
	title.size = Vector2(430, 34)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_child(title)
	var sub := UiKit.label(subtitle_text, 18, Color(0.74, 0.82, 0.82, 0.94), 2)
	sub.name = "ActionSub"
	sub.position = Vector2(104, 48)
	sub.size = Vector2(430, 28)
	sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_child(sub)
	var arrow := UiKit.label(">", 34, UiKit.GOLD if primary else Color(0.70, 0.84, 0.96, 1.0), 2)
	arrow.name = "ActionArrow"
	arrow.position = Vector2(button_size.x - 76.0, 18)
	arrow.size = Vector2(42, 50)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_child(arrow)

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
	router.change_scene("map")

func _process_spawns(delta: float) -> void:
	if not active_spawning:
		return
	spawn_timer -= delta
	if spawn_timer > 0.0:
		return
	if pending_spawns.is_empty():
		active_spawning = false
		return
	var item: Dictionary = pending_spawns.pop_front()
	_spawn_enemy(item.get("type", "zombie_shambler"), item.get("lane", "spread"), item.get("boss", false))
	spawn_timer = item.get("interval", 0.8)

func _start_next_wave() -> void:
	var waves: Array = level.get("waves", [])
	if wave_index >= waves.size():
		return
	_apply_wave_start_support()
	var wave: Dictionary = waves[wave_index]
	wave_index += 1
	pending_spawns.clear()
	_update_objective_panel()
	_show_wave_tip(wave)
	if wave.has("boss"):
		AudioManager.play_bgm("boss")
		var boss_id: String = wave.get("boss", "boss_tank_titan")
		AudioManager.play_sfx(_boss_intro_sfx(boss_id), 1.5, 0.015)
		_show_screen_flash(Color(1.0, 0.18, 0.08, 0.22), 0.22)
		var boss_name := DataLoader.tr_key(DataLoader.get_row("bosses", boss_id).get("name_key", boss_id))
		_show_wave_toast("首领来袭：%s" % boss_name, Color(1.0, 0.32, 0.22))
		_show_boss_banner(boss_name)
		pending_spawns.append({"type": boss_id, "interval": 1.0, "lane": "center", "boss": true})
		if variant == "boss_rush":
			pending_spawns.append({"type": "boss_tank_titan", "interval": 2.4, "lane": "left", "boss": true})
		for support in wave.get("support", []):
			_queue_spawn_group(support, false)
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
		for group in wave.get("spawns", []):
			_queue_spawn_group(group, false)
	active_spawning = true
	spawn_timer = 0.2

func _apply_wave_start_support() -> void:
	if pet_data.get("role", "") != "repair":
		return
	if base_hp >= base_hp_max:
		return
	var heal := int(round(_pet_scaled_value("heal_per_wave", "level_heal_growth")))
	if heal <= 0:
		return
	base_hp = min(base_hp + heal, base_hp_max)
	_spawn_float_text(Vector2(540, 1440), "+%d 基地维修" % heal, Color(0.35, 1.0, 0.68))

func _queue_spawn_group(group: Dictionary, is_boss: bool) -> void:
	for i in range(int(group.get("count", 1))):
		pending_spawns.append({
			"type": group.get("type", "zombie_shambler"),
			"interval": group.get("interval", 0.8),
			"lane": group.get("lane", "spread"),
			"boss": is_boss
		})

func _spawn_enemy(enemy_id: String, lane: String, is_boss := false) -> void:
	var x := 540.0
	match lane:
		"left":
			x = randf_range(180, 390)
		"right":
			x = randf_range(690, 900)
		"center":
			x = randf_range(460, 620)
		_:
			x = randf_range(150, 930)
	_spawn_enemy_instance(enemy_id, Vector2(x, 190), is_boss)

func _spawn_enemy_instance(enemy_id: String, spawn_position: Vector2, is_boss := false) -> Node:
	var row := DataLoader.get_row("bosses" if is_boss else "zombies", enemy_id).duplicate(true)
	var economy: Dictionary = DataLoader.get_table("economy")
	var enemy_speed_mult := float(economy.get("ENEMY_SPEED_MULT", 1.0))
	row["speed"] = float(row.get("speed", 80.0)) * enemy_speed_mult
	var enemy := ENEMY_SCENE.instantiate()
	enemy.position = spawn_position
	var hp_level_coef := float(level.get("difficulty_coef", 1.0)) * float(level.get("base_hp_ref", 50)) / 50.0
	if not is_boss:
		hp_level_coef *= float(LATE_WAVE_HP_BONUS.get(wave_index, 1.0))
	if is_endless_mode:
		hp_level_coef *= endless_difficulty_mult
	enemy.setup(row, hp_level_coef, is_boss)
	enemy.hit_feedback.connect(_on_enemy_hit_feedback)
	enemy.damage_dealt.connect(_on_enemy_damage_dealt)
	enemy.died.connect(_on_enemy_died)
	enemy.breached.connect(_on_enemy_breached)
	if is_boss:
		active_boss = enemy
	$EnemyLayer.add_child(enemy)
	$ThreatMarkerLayer.add_child(enemy.threat_marker)
	enemy.tree_exiting.connect(_on_enemy_tree_exiting.bind(enemy))
	enemy.threat_marker.position = enemy.global_position + Vector2(0, -90 if not is_boss else -160)
	_spawn_enemy_entry_vfx(enemy, is_boss)
	return enemy

func _process_enemy_mechanics(delta: float) -> void:
	var enemies := $EnemyLayer.get_children()
	_process_threat_feedback(enemies)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.speed_mult = 1.0
			enemy.external_damage_mult = 1.0
	for source in enemies:
		if not is_instance_valid(source):
			continue
		_process_boss_phase_feedback(source)
		match str(source.mechanic):
			"buff_aura":
				_apply_speed_aura(source, enemies)
				_process_aura_feedback(source, "buff_aura", delta)
			"shield_aura", "ward":
				_apply_damage_reduction_aura(source, enemies)
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
				_process_freeze_field(source, enemies, delta)
			"storm_chain":
				_process_boss_pressure(source, delta, 3.6, 0.36, "雷暴连锁", Color(1.0, 0.88, 0.2))
			"spawn_minions":
				_process_boss_minions(source, delta)
			"phase_shift":
				_process_phase_shift(source, delta)
			"regenerate":
				_process_boss_pressure(source, delta, 5.8, 0.28, "腐化再生", Color(0.48, 1.0, 0.32))
			"multi_phase":
				_process_apex_pressure(source, enemies, delta)

func _apply_speed_aura(source: Node, enemies: Array) -> void:
	var radius := float(source.mechanic_params.get("radius", 260.0))
	var speed_boost := float(source.mechanic_params.get("speed_mult", 1.18))
	for enemy in enemies:
		if enemy == source or not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(source.global_position) <= radius:
			enemy.speed_mult *= speed_boost

func _apply_damage_reduction_aura(source: Node, enemies: Array) -> void:
	var radius := float(source.mechanic_params.get("radius", 280.0))
	var damage_mult := float(source.mechanic_params.get("damage_taken_mult", 0.72))
	for enemy in enemies:
		if enemy == source or not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(source.global_position) <= radius:
			enemy.external_damage_mult *= damage_mult

func _enemy_mechanic_timer_ready(source: Node, key: String, delta: float, interval: float, jitter := 0.0, initial_delay := 0.4) -> bool:
	var meta_key := "mechanic_timer_%s" % key
	var remaining := initial_delay
	if source.has_meta(meta_key):
		remaining = float(source.get_meta(meta_key))
	remaining -= delta
	if remaining > 0.0:
		source.set_meta(meta_key, remaining)
		return false
	source.set_meta(meta_key, maxf(0.15, interval + randf_range(0.0, jitter)))
	return true

func _enemy_skill_damage(source: Node, scale: float, minimum := 1.0) -> int:
	var raw := maxf(minimum, float(source.breach_damage) * scale)
	return maxi(0, int(ceil(raw * breach_damage_mult)))

func _apply_enemy_skill_base_damage(source: Node, damage: int, label: String, color: Color, target_position: Vector2) -> void:
	if battle_finished:
		return
	var final_damage := maxi(0, damage)
	final_damage = mini(final_damage, maxi(1, int(round(float(base_hp_max) * MAX_BASE_HIT_FRACTION))))  # 防秒杀
	var shield_absorbed := false
	if final_damage > 0 and breach_shields + skill_barriers_left > 0:
		if breach_shields > 0:
			breach_shields -= 1
		else:
			skill_barriers_left -= 1
		final_damage = 0
		shield_absorbed = true
	if is_instance_valid(source):
		_spawn_breach_attack_vfx(source, shield_absorbed)
	if shield_absorbed:
		_spawn_barrier_break_vfx(Vector2(target_position.x, BREACH_Y - 30.0))
		_update_barrier_visual()
		_spawn_float_text(target_position, "格挡", Color(0.64, 0.9, 1.0))
		return
	if final_damage <= 0:
		return
	base_hp = max(base_hp - final_damage, 0)
	_show_screen_flash(Color(color.r, color.g, color.b, 0.08), 0.12)
	_spawn_float_text(target_position, "-%d %s" % [final_damage, label], color)
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

func _advance_enemy_with_skill(source: Node, kind: String, advance: float, label: String, color: Color, damage_scale: float) -> void:
	if source.has_method("play_special"):
		source.play_special(0.32)
	var old_y := float(source.global_position.y)
	var cap_y := float(source.attack_line_y) - 18.0
	source.global_position.y = minf(cap_y, old_y + advance)
	_spawn_enemy_attack_vfx(source, kind, source.global_position + Vector2(0, -36.0))
	_spawn_attack_telegraph(source.global_position + Vector2(0, 74.0), Color(color.r, color.g, color.b, 0.24), label)
	AudioManager.play_sfx("threat_warning", -7.0, 0.02)
	if old_y >= 1160.0:
		var damage := _enemy_skill_damage(source, damage_scale, 1.0)
		_apply_enemy_skill_base_damage(source, damage, label, color, Vector2(source.global_position.x, 1370.0))

func _process_toxic_cloud_pressure(source: Node, delta: float) -> void:
	if source.global_position.y < float(source.mechanic_params.get("trigger_y", 760.0)):
		return
	var interval := float(source.mechanic_params.get("cloud_interval", 4.8))
	if not _enemy_mechanic_timer_ready(source, "toxic_cloud", delta, interval, 0.55, 0.8):
		return
	if source.has_method("play_special"):
		source.play_special(0.42)
	var damage := _enemy_skill_damage(source, float(source.mechanic_params.get("damage_coef", 0.22)), 2.0)
	var impact := Vector2(source.global_position.x, 1440.0)
	_spawn_attack_telegraph(impact, Color(0.42, 1.0, 0.24, 0.32), "毒雾")
	_spawn_enemy_attack_vfx(source, "toxic_cloud", source.global_position + Vector2(0, -52.0))
	_spawn_attack_ring(source.global_position, float(source.mechanic_params.get("radius", 190.0)), Color(0.42, 1.0, 0.24, 0.28), 0.42)
	_spawn_enemy_cast_bolt(source.global_position + Vector2(0, -30.0), impact, Color(0.52, 1.0, 0.3), "poison", false)
	AudioManager.play_sfx("hit_poison", -5.0, 0.02)
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
	_spawn_attack_telegraph(Vector2(source.global_position.x, 1360.0), Color(color.r, color.g, color.b, 0.26), "震地")
	AudioManager.play_sfx("threat_warning", -6.0, 0.02)
	var damage := _enemy_skill_damage(source, float(source.mechanic_params.get("damage_coef", 0.16)), 2.0)
	_apply_enemy_skill_base_damage(source, damage, "震地", color, Vector2(source.global_position.x, 1360.0))

func _process_regen_feedback(source: Node, delta: float) -> void:
	if float(source.hp) >= float(source.max_hp) * 0.98:
		return
	var interval := float(source.mechanic_params.get("pulse_interval", 3.0))
	if not _enemy_mechanic_timer_ready(source, "regen_feedback", delta, interval, 0.4, 0.9):
		return
	var color := Color(0.48, 1.0, 0.32)
	_spawn_enemy_attack_vfx(source, "regen", source.global_position + Vector2(0, -48.0))
	_spawn_attack_ring(source.global_position, 150.0, Color(color.r, color.g, color.b, 0.24), 0.34)
	_spawn_float_text(source.global_position + Vector2(0, -118.0), "再生", color)

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
	AudioManager.play_sfx("threat_warning", -5.0, 0.02)

func _process_enrage_feedback(source: Node) -> void:
	if not bool(source.enrage_triggered) or source.has_meta("enrage_feedback_done"):
		return
	source.set_meta("enrage_feedback_done", true)
	if source.has_method("play_special"):
		source.play_special(0.42)
	_spawn_enemy_attack_vfx(source, "enrage", source.global_position + Vector2(0, -52.0))
	_spawn_attack_ring(source.global_position, 185.0, Color(1.0, 0.32, 0.16, 0.3), 0.36)
	_spawn_float_text(source.global_position + Vector2(0, -124.0), "狂暴", Color(1.0, 0.32, 0.16))
	AudioManager.play_sfx("threat_warning", -6.0, 0.02)

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
	source.mechanic_timer = randf_range(interval, interval + 1.2)
	var spawn_position: Vector2 = source.global_position + Vector2(randf_range(-75, 75), randf_range(-35, 45))
	spawn_position.x = clampf(spawn_position.x, 120.0, 960.0)
	spawn_position.y = clampf(spawn_position.y, 190.0, 1220.0)
	_spawn_enemy_attack_vfx(source, "summon", spawn_position)
	_spawn_enemy_instance(str(source.mechanic_params.get("summon_id", "zombie_shambler")), spawn_position, false)
	AudioManager.play_sfx("threat_warning", -6.0)
	_spawn_float_text(source.global_position + Vector2(0, -86), "召唤", Color(0.72, 0.4, 1.0))

func _process_ranged_pressure(source: Node, delta: float) -> void:
	if source.global_position.y < float(source.mechanic_params.get("trigger_y", 720.0)):
		return
	source.mechanic_timer -= delta
	if source.mechanic_timer > 0.0:
		return
	var interval := float(source.mechanic_params.get("skill_interval", 4.2))
	source.mechanic_timer = randf_range(interval, interval + 0.9)
	var spit_damage := _enemy_skill_damage(source, float(source.mechanic_params.get("damage_coef", 0.35)), 2.0)
	var target_position := Vector2(source.global_position.x, 1370)
	_spawn_attack_telegraph(target_position, Color(0.46, 1.0, 0.25, 0.34), "腐蚀")
	_spawn_spit_attack_vfx(source, target_position)
	AudioManager.play_sfx("hit_poison", -4.0)
	_apply_enemy_skill_base_damage(source, spit_damage, "腐蚀", Color(0.56, 1.0, 0.32), target_position)

func _process_boss_pressure(source: Node, delta: float, interval: float, damage_scale: float, label: String, color: Color) -> void:
	if source.global_position.y < 560.0:
		return
	source.mechanic_timer -= delta
	if source.mechanic_timer > 0.0:
		return
	source.mechanic_timer = randf_range(interval, interval + 1.4)
	if source.has_method("play_special"):
		source.play_special()
	var pressure_damage := _enemy_skill_damage(source, damage_scale, 3.0)
	var impact := Vector2(source.global_position.x, 1440.0)
	_spawn_attack_telegraph(impact, Color(color.r, color.g, color.b, 0.34), label)
	_spawn_boss_attack_vfx(source, label, color, impact)
	AudioManager.play_sfx("threat_warning", -5.0)
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
	source.mechanic_timer = randf_range(5.0, 6.6)
	if source.has_method("play_special"):
		source.play_special()
	_spawn_float_text(source.global_position + Vector2(0, -120), "寒潮领域", Color(0.45, 0.86, 1.0))
	_spawn_attack_telegraph(Vector2(source.global_position.x, 1360), Color(0.45, 0.86, 1.0, 0.32), "寒潮")
	_spawn_boss_attack_vfx(source, "寒潮领域", Color(0.45, 0.86, 1.0))
	var frost_damage := _enemy_skill_damage(source, 0.24, 2.0)
	AudioManager.play_sfx("hit_ice", -4.0)
	_apply_enemy_skill_base_damage(source, frost_damage, "寒潮", Color(0.45, 0.86, 1.0), Vector2(source.global_position.x, 1360))

func _process_boss_minions(source: Node, delta: float) -> void:
	source.mechanic_timer -= delta
	if source.mechanic_timer > 0.0:
		return
	source.mechanic_timer = randf_range(5.5, 7.2)
	if source.has_method("play_special"):
		source.play_special(0.58)
	for offset in [-92.0, 0.0, 92.0]:
		var spawn_position: Vector2 = source.global_position + Vector2(offset, 32.0)
		spawn_position.x = clampf(spawn_position.x, 120.0, 960.0)
		spawn_position.y = clampf(spawn_position.y, 220.0, 1180.0)
		_spawn_enemy_attack_vfx(source, "spawn_minions", spawn_position)
		_spawn_enemy_instance("zombie_crawler", spawn_position, false)
	AudioManager.play_sfx("threat_warning", -5.0)
	_spawn_float_text(source.global_position + Vector2(0, -130), "孵化尸群", Color(0.66, 1.0, 0.3))

func _process_phase_shift(source: Node, delta: float) -> void:
	source.mechanic_timer -= delta
	if source.mechanic_timer <= 0.0:
		source.mechanic_timer = randf_range(2.4, 3.4)
		if source.has_method("play_special"):
			source.play_special(0.34)
		AudioManager.play_sfx("threat_warning", -6.0)
		_spawn_enemy_attack_vfx(source, "phase_shift", source.global_position + Vector2(0, 86.0))
		source.global_position.y = min(source.global_position.y + 86.0, 1440.0)
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
	if hp_ratio <= 0.34 and not source.has_meta("boss_phase_3_announced"):
		source.set_meta("boss_phase_3_announced", true)
		_announce_boss_phase(source, "三阶段狂暴", Color(1.0, 0.18, 0.12, 1.0))
	elif hp_ratio <= 0.67 and not source.has_meta("boss_phase_2_announced"):
		source.set_meta("boss_phase_2_announced", true)
		_announce_boss_phase(source, "进入二阶段", Color(1.0, 0.72, 0.24, 1.0))

func _announce_boss_phase(source: Node, text: String, color: Color) -> void:
	if not is_instance_valid(source):
		return
	if source.has_method("play_special"):
		source.play_special(0.54)
	AudioManager.play_sfx("threat_warning", -3.0, 0.02)
	_show_wave_toast("首领%s" % text, color)
	_spawn_float_text(source.global_position + Vector2(0, -180), text, color)
	_spawn_attack_ring(source.global_position + Vector2(0, -40), 230.0, Color(color.r, color.g, color.b, 0.28), 0.32)
	_show_screen_flash(Color(color.r, color.g, color.b, 0.14), 0.22)

func _on_turret_fired(origin: Vector2, direction: Vector2) -> void:
	_sync_logic_turret_to_character()
	direction = _weapon_fire_direction(direction)
	_set_character_combo_aim_from_direction(direction)
	origin = _weapon_fire_origin()
	direction = _weapon_fire_direction(direction)
	var mods := skills.projectile_mods()
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var special: Dictionary = weapon.get("special", {})
	var shots: int = 1 + int(mods.get("extra_projectiles", 0)) + maxi(int(special.get("pellets", 1)) - 1, 0)
	if sig_vanguard_barrage_timer > 0.0:
		shots += 1
		if _growth_rank(character_level) >= 2:
			shots += 1
	var spread: float = deg_to_rad(float(mods.get("spread_deg", 0.0)) + float(special.get("spread", 0.0)))
	var homing: float = float(mods.get("homing", 0)) * 1.8
	var element: String = skills.projectile_element(str(weapon.get("element", "physical")))
	var visual_profile := _weapon_visual_profile(weapon_id)
	homing += _character_homing_bonus(element)
	AudioManager.play_sfx(_weapon_shot_sfx(weapon_id), -7.0)
	if element != "physical":
		AudioManager.play_sfx(_element_muzzle_sfx(element), -10.0, 0.025)
	if element == primary_weakness and randf() < 0.08:
		_spawn_float_text(origin + Vector2(-120, -80), "弱点装填", Color(1.0, 0.86, 0.32))
	if weapon_level >= 15 and randf() < 0.08:
		_spawn_weapon_power_ring(origin, element)
	_spawn_muzzle_flash(origin, direction, element, visual_profile)
	_play_character_attack()
	var base_damage: float = 28.0 * float(weapon.get("base_atk_coef", 1.0)) * _player_shot_damage_multiplier()
	var pierce: int = int(mods.get("pierce", 0)) + pierce_bonus + int(special.get("pierce", 0)) + _character_pierce_bonus(element)
	if sig_vanguard_barrage_timer > 0.0:
		pierce += 1
	var split: int = int(mods.get("split", 0)) + int(special.get("split", 0))
	var splash: float = maxf(float(special.get("splash", 0.0)), _character_splash_bonus(element))
	var cloud: float = float(special.get("cloud", 0.0))
	var visual_scale := _projectile_visual_scale(shots, pierce, split, homing, splash, cloud)
	var shot_directions := _primary_shot_directions(origin, direction, shots, spread)
	if skills.level("skill_charge_shot") > 0 and randf() < 0.18:
		_spawn_float_text(origin + Vector2(105, -72), "蓄能弹", Color(1.0, 0.78, 0.24))
	for i in range(shots):
		var shot_direction: Vector2 = shot_directions[i] if i < shot_directions.size() else direction
		var damage: float = base_damage * float(turret.damage_mult) * skills.damage_multiplier()
		if shots > 1:
			damage *= clampf(1.0 / sqrt(float(shots)), 0.42, 1.0)
		damage *= _character_bullet_damage_multiplier(element)
		if sig_vanguard_barrage_timer > 0.0:
			damage *= 1.08
		if element == primary_weakness:
			damage *= 1.15
		var is_crit := randf() < crit_rate + skills.crit_bonus()
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
			visual_profile
		)
	if shots >= 3:
		_spawn_salvo_fan_vfx(origin, direction, spread, shots, element)

func _spawn_projectile(origin: Vector2, direction: Vector2, damage: float, pierce: int, split: int, split_falloff: float, homing := 0.0, splash := 0.0, cloud := 0.0, visual_scale := 1.0, visual_profile := "") -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var element := skills.projectile_element(str(weapon.get("element", "physical")))
	var profile := visual_profile if visual_profile != "" else _weapon_visual_profile(weapon_id)
	projectile.setup(origin, direction, float(weapon.get("projectile_speed", 1450.0)), damage, element, pierce, split, split_falloff, homing, splash, cloud, visual_scale, 0, "", profile)
	projectile.split_requested.connect(_on_projectile_split_requested)
	projectile.hit_confirmed.connect(_on_projectile_hit_confirmed)
	$ProjectileLayer.add_child(projectile)
	if homing > 0.0:
		_spawn_homing_line_vfx(origin, direction, element)

func _primary_shot_directions(origin: Vector2, base_direction: Vector2, shots: int, spread: float) -> Array[Vector2]:
	# 多重射击 = “固定夹角”的对称扇形：每条弹道之间角度固定、不各自变道锁敌（避免 imba）。
	# 扇形整体“中心方向”对准敌群质心，所以它会随敌群转向、不再卡在竖直中线上打空。
	# 每条弹道的固定夹角取自 MULTISHOT_LANE_DEG（不再用武器随机 spread——那会在 spread=0 时把所有
	# 弹道叠成一条线，稍微偏一点就整组打空）；散射类武器额外的 spread 只做“下限加宽”。
	var directions: Array[Vector2] = []
	if shots <= 1:
		directions.append(base_direction.normalized())
		return directions
	var center_dir := _multishot_center_direction(origin, base_direction)
	var lane_step: float = maxf(deg_to_rad(MULTISHOT_LANE_DEG), spread / float(shots - 1))
	var total: float = lane_step * float(shots - 1)
	# 质心是"平均位置"，敌人分两侧站时质心可能落在没人的空地——固定夹角的扇形整体套在质心上会全部打空。
	# 保证至少一条弹道真的对着某个敌人：质心扇形覆盖不到任何敌人时，把整个扇形(角度仍固定)
	# 重新对准"离质心方向最近的那个真实敌人"，而不是让每条弹道各自变道锁敌（那样才是 imba）。
	var enemy_dirs := _battlefield_enemy_directions(origin)
	if not enemy_dirs.is_empty():
		var half_span: float = total * 0.5 + lane_step * 0.5
		var covered := false
		for d in enemy_dirs:
			if absf(center_dir.angle_to(d)) <= half_span:
				covered = true
				break
		if not covered:
			var best_dir: Vector2 = enemy_dirs[0]
			var best_diff := INF
			for d in enemy_dirs:
				var diff := absf(center_dir.angle_to(d))
				if diff < best_diff:
					best_diff = diff
					best_dir = d
			center_dir = best_dir
	for index in range(shots):
		var offset: float = -total * 0.5 + lane_step * float(index)
		directions.append(center_dir.rotated(offset).normalized())
	return directions

func _battlefield_enemy_directions(origin: Vector2) -> Array[Vector2]:
	# 场上所有尚未越线的敌人相对 origin 的单位方向（供多重射击"至少一条弹道命中"判定用）。
	var dirs: Array[Vector2] = []
	for e in $EnemyLayer.get_children():
		if not is_instance_valid(e) or not (e is Node2D):
			continue
		var en := e as Node2D
		if en.global_position.y > 1540.0:
			continue
		var to_enemy: Vector2 = en.global_position - origin
		if to_enemy.length_squared() <= 4.0:
			continue
		dirs.append(to_enemy.normalized())
	return dirs

func _multishot_center_direction(origin: Vector2, fallback: Vector2) -> Vector2:
	# 敌群质心方向（只算尚未越过基线的敌人）；无敌人时退回原瞄准方向。
	var sum := Vector2.ZERO
	var n := 0
	for e in $EnemyLayer.get_children():
		if not is_instance_valid(e) or not (e is Node2D):
			continue
		var en := e as Node2D
		if en.global_position.y > 1540.0:
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
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)
	return candidates

func _spawn_pet() -> void:
	if pet_data.is_empty():
		return
	pet_sprite = Sprite2D.new()
	pet_sprite.name = "Pet"
	pet_sprite.process_mode = Node.PROCESS_MODE_PAUSABLE
	pet_sprite.texture = load(pet_data.get("sprite", pet_data.get("icon", "")))
	pet_sprite.position = Vector2(725, 1625)
	pet_sprite.scale = Vector2(0.26, 0.26) * _visual_level_scale(pet_level)
	pet_sprite.modulate = Color.WHITE
	add_child(pet_sprite)
	_load_pet_animation_frames(str(pet_data.get("sprite", "")))
	_attach_growth_badge(pet_sprite, pet_level, Vector2(-88, -152))
	_spawn_pet_aura()
	if pet_data.get("role", "") == "repair":
		_spawn_float_text(pet_sprite.global_position + Vector2(0, -80), "维修宠物待命", Color(0.35, 1.0, 0.68))

func _spawn_character() -> void:
	character_rig = Node2D.new()
	character_rig.name = "CharacterRig"
	character_rig.process_mode = Node.PROCESS_MODE_PAUSABLE
	character_rig.position = CHARACTER_BASE_POSITION
	add_child(character_rig)

	character_sprite = Sprite2D.new()
	character_sprite.name = "Character"
	character_sprite.position = Vector2.ZERO
	character_sprite.scale = Vector2.ONE * CHARACTER_VISUAL_BASE_SCALE * _visual_level_scale(character_level)
	character_sprite.modulate = Color.WHITE
	character_sprite.z_index = 1
	character_rig.add_child(character_sprite)
	_load_character_animation_frames()
	if not character_idle_frames.is_empty():
		character_sprite.texture = character_idle_frames[0]
	else:
		character_sprite.texture = load(character_data.get("portrait", ""))
	_attach_growth_badge(character_sprite, character_level, Vector2(-98, -190))
	_spawn_character_weapon_visual()
	_spawn_character_aura()

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
	var handheld_path := str(weapon.get("handheld", ""))
	if handheld_path != "" and ResourceLoader.exists(handheld_path):
		character_weapon_idle_frames = []
		character_weapon_recoil_frames = []
		character_weapon_sprite.texture = load(handheld_path)
	else:
		_load_character_weapon_animation_frames()
		if not character_weapon_idle_frames.is_empty():
			character_weapon_sprite.texture = character_weapon_idle_frames[0]
		else:
			character_weapon_sprite.texture = load(weapon.get("turret", weapon.get("icon", "")))
	character_weapon_sprite.modulate = Color.WHITE
	_attach_growth_badge(character_weapon_sprite, weapon_level, Vector2(-82, -126))

func _load_character_animation_frames() -> void:
	var asset_id := _character_asset_id()
	character_weapon_combo_active = false
	character_weapon_combo_muzzle = CHARACTER_WEAPON_SOCKET
	character_weapon_combo_aim = "center"
	character_weapon_combo_locked_aim = ""
	character_attack_left_frames = []
	character_attack_right_frames = []
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
	var base := "res://assets/production/sprites/animations/characters_weaponless/%s/%s" % [asset_id, asset_id]
	if not _image_resource_exists("%s_idle_01.png" % base):
		base = "res://assets/production/sprites/animations/characters/%s/%s" % [asset_id, asset_id]
	character_idle_frames = _load_frame_set(base, "idle", 4)
	character_attack_left_frames = []
	character_attack_frames = _load_frame_set(base, "attack", 4)
	character_attack_right_frames = []
	character_hurt_frames = _load_frame_set(base, "hurt", 3)

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
	if character_hurt_time > 0.0:
		frames = character_hurt_frames
		fps = 16.0
		character_hurt_time -= delta
	elif character_skill_time > 0.0:
		frames = _character_combo_attack_frames()
		fps = 12.0
		character_skill_time -= delta
	elif character_attack_time > 0.0:
		frames = _character_combo_attack_frames()
		fps = float(maxi(frames.size(), 1)) / maxf(character_attack_duration, 0.08)
		character_attack_time -= delta
		if character_attack_time <= 0.0:
			character_weapon_combo_locked_aim = ""
	if not frames.is_empty():
		character_anim_time += delta
		var next_frame := int(character_anim_time * fps)
		if character_hurt_time > 0.0 or character_attack_time > 0.0 or character_skill_time > 0.0:
			next_frame = mini(next_frame, frames.size() - 1)
		else:
			next_frame = next_frame % frames.size()
		if next_frame != character_anim_frame:
			character_anim_frame = next_frame
		character_sprite.texture = frames[character_anim_frame]
	_update_character_body_pose()
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
	character_attack_duration = float(CHARACTER_WEAPON_ATTACK_DURATION.get(weapon_id, 0.32))
	character_attack_time = character_attack_duration
	character_anim_time = 0.0
	character_anim_frame = 0
	character_weapon_combo_locked_aim = character_weapon_combo_aim
	_play_character_weapon_recoil(minf(character_attack_duration, 0.28))

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

func _update_character_body_pose() -> void:
	var breathe := sin(Time.get_ticks_msec() / 420.0)
	var pose_offset := Vector2(0.0, -absf(breathe) * 3.0)
	var pose_rotation := 0.0
	var pose_scale := Vector2.ONE * CHARACTER_VISUAL_BASE_SCALE * _visual_level_scale(character_level)
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
		var attack_ratio := clampf(character_attack_time / maxf(character_attack_duration, 0.08), 0.0, 1.0)
		var pulse := sin((1.0 - attack_ratio) * PI)
		var recoil_strength := float(CHARACTER_WEAPON_RECOIL_POSE.get(weapon_id, 14.0))
		pose_offset += -character_weapon_direction * (recoil_strength * pulse)
		pose_rotation = deg_to_rad(clampf(character_weapon_direction.x, -0.8, 0.8) * 2.2 * pulse)
		pose_scale *= 1.0 + 0.012 * pulse
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
	var base_scale := float(CHARACTER_WEAPON_SCALE.get(weapon_id, 0.52))
	return base_scale * (1.0 + clampf(float(weapon_level - 1) * 0.0025, 0.0, 0.1))

func _weapon_visual_profile(id := "") -> String:
	var resolved_id := id if id != "" else weapon_id
	return str(WEAPON_VISUAL_PROFILES.get(resolved_id, ""))

func _sync_logic_turret_to_character() -> void:
	if turret == null:
		return
	turret.global_position = _weapon_socket_global()

func _weapon_socket_global() -> Vector2:
	if character_rig != null:
		if character_weapon_combo_active:
			return character_rig.global_position + _character_combo_muzzle_for_aim()
		return character_rig.global_position + CHARACTER_WEAPON_SOCKET
	if turret != null:
		return turret.global_position
	return Vector2(540, 1660)

func _character_combo_key() -> String:
	return "%s/%s" % [_character_asset_id(), weapon_id]

func _character_combo_effective_aim() -> String:
	if character_weapon_combo_locked_aim != "":
		return character_weapon_combo_locked_aim
	return character_weapon_combo_aim

func _character_combo_muzzle_for_aim() -> Vector2:
	var combo_key := _character_combo_key()
	var aim := _character_combo_effective_aim()
	if aim == "left":
		return CHARACTER_WEAPON_COMBO_MUZZLE_LEFT.get(combo_key, character_weapon_combo_muzzle)
	if aim == "right":
		return CHARACTER_WEAPON_COMBO_MUZZLE_RIGHT.get(combo_key, character_weapon_combo_muzzle)
	return character_weapon_combo_muzzle

func _set_character_combo_aim_from_direction(direction: Vector2) -> void:
	if not character_weapon_combo_active:
		return
	if direction.length_squared() <= 0.01:
		character_weapon_combo_aim = "center"
	elif direction.x < -0.18:
		character_weapon_combo_aim = "left"
	elif direction.x > 0.18:
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
	var muzzle_distance := float(CHARACTER_WEAPON_MUZZLE_DISTANCE.get(weapon_id, 70.0))
	return socket + direction * muzzle_distance

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
	pet_sprite.position.y = 1625.0 - absf(sin(Time.get_ticks_msec() / 300.0)) * 8.0
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
	if pet_data.get("role", "") == "repair":
		return
	pet_cooldown -= delta
	if pet_cooldown > 0.0:
		return
	var fire_rate := float(pet_data.get("fire_rate", 0.0))
	if fire_rate <= 0.0:
		return
	var target := target_manager.choose_target($EnemyLayer.get_children(), pet_sprite.global_position)
	if target == null:
		return
	pet_cooldown = 1.0 / fire_rate
	AudioManager.play_sfx(_element_muzzle_sfx(str(pet_data.get("element", "physical"))), -12.0, 0.03)
	pet_attack_time = 0.22
	pet_anim_time = 0.0
	pet_anim_frame = 0
	var direction: Vector2 = (target.global_position - pet_sprite.global_position).normalized()
	var projectile := PROJECTILE_SCENE.instantiate()
	projectile.setup(
		pet_sprite.global_position,
		direction,
		1120.0,
		_pet_scaled_value("damage", "level_damage_growth"),
		str(pet_data.get("element", "physical")),
		0,
		0
	)
	projectile.hit_confirmed.connect(_on_projectile_hit_confirmed)
	$ProjectileLayer.add_child(projectile)

func _track_transient_fx(node: Node, bucket: String) -> void:
	node.set_meta("battle_transient_fx", bucket)
	if bucket == "projectile":
		node.set_meta("transient_vfx", true)

func _can_spawn_projectile_fx(priority := false) -> bool:
	return _transient_fx_count($ProjectileLayer, "projectile") < (MAX_PROJECTILE_PRIORITY_FX if priority else MAX_PROJECTILE_TRANSIENT_FX)

func _can_spawn_hud_fx(priority := false) -> bool:
	return _transient_fx_count($Hud, "hud") < (MAX_HUD_PRIORITY_FX if priority else MAX_HUD_TRANSIENT_FX)

func _can_spawn_float_text(priority := false) -> bool:
	return _transient_fx_count($Hud, "float_text") < (MAX_PRIORITY_FLOAT_TEXTS if priority else MAX_FLOAT_TEXTS)

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
	var glow := VfxLib.spawn_glow($ProjectileLayer, origin + dir * 10.0, hot_color, float(spec.get("glow_size", 104.0)), float(spec.get("glow_life", 0.13)))
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

func _spawn_salvo_fan_vfx(origin: Vector2, direction: Vector2, spread: float, shots: int, element: String) -> void:
	var dir := _safe_vfx_direction(direction)
	var spec := _muzzle_element_spec(element, _muzzle_weapon_profile(""))
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
	spark.scale = Vector2(scale_mult, scale_mult)
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
	var safe_length := clampf(length, 24.0, 190.0)
	var safe_width := clampf(width, 8.0, 76.0)
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
	haze.global_position = origin + dir * 18.0
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
	for i in range(safe_count):
		var t := 0.5 if safe_count == 1 else float(i) / float(safe_count - 1)
		var lateral := tan(deg_to_rad(lerpf(-spread_deg, spread_deg, t))) * length * 0.26
		var jitter := randf_range(-8.0, 8.0)
		var line := Line2D.new()
		line.width = width * randf_range(0.72, 1.18)
		line.default_color = color.lightened(randf_range(0.0, 0.25))
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.texture = VfxLib.STREAK_TEXTURE
		line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		line.material = _new_muzzle_additive_material()
		line.points = PackedVector2Array([
			Vector2(8.0, 0.0),
			Vector2(length * randf_range(0.38, 0.58), lateral * 0.45 + jitter),
			Vector2(length * randf_range(0.74, 1.05), lateral + randf_range(-10.0, 10.0)),
		])
		root.add_child(line)
		if i % 2 == 0:
			var branch := Line2D.new()
			branch.width = maxf(width * 0.55, 1.2)
			branch.default_color = Color(color.r, color.g, color.b, color.a * 0.72)
			branch.joint_mode = Line2D.LINE_JOINT_ROUND
			branch.begin_cap_mode = Line2D.LINE_CAP_ROUND
			branch.end_cap_mode = Line2D.LINE_CAP_ROUND
			branch.texture = VfxLib.STREAK_TEXTURE
			branch.texture_mode = Line2D.LINE_TEXTURE_STRETCH
			branch.material = _new_muzzle_additive_material()
			var branch_start := Vector2(length * 0.48, lateral * 0.42)
			branch.points = PackedVector2Array([
				branch_start,
				branch_start + Vector2(length * 0.22, randf_range(-22.0, 22.0)),
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
	badge.add_theme_font_size_override("font_size", 22)
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
	var radius := 190.0 if is_boss else 82.0
	_spawn_attack_ring(enemy.global_position + Vector2(0, -20), radius, color, 0.28)
	if is_boss:
		_spawn_attack_sprite("res://assets/production/sprites/vfx/vfx_threat_warning.png", enemy.global_position + Vector2(0, -86), Color(1.0, 0.28, 0.12, 0.72), 1.3, 0.38)

func _spawn_attack_telegraph(origin: Vector2, color: Color, label_text: String) -> void:
	_spawn_attack_ring(origin, 96.0, color, 0.24)
	if not _can_spawn_float_text(true):
		return
	var label := Label.new()
	_track_transient_fx(label, "float_text")
	label.text = label_text
	label.position = origin + Vector2(-120, -92)
	label.size = Vector2(240, 42)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
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
	label.add_theme_font_size_override("font_size", 42)
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
	badge.add_theme_font_size_override("font_size", 20)
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

func _on_projectile_split_requested(origin: Vector2, direction: Vector2, count: int, damage: float, element: String) -> void:
	var fan := deg_to_rad(30.0 + float(count) * 10.0)
	_spawn_split_burst_vfx(origin, direction, fan, count, element)
	_spawn_attack_ring(origin, 92.0 + float(count) * 14.0, Color(_element_color(element).r, _element_color(element).g, _element_color(element).b, 0.26), 0.18)
	var target_directions := _split_target_directions(origin, direction, count, fan)
	for i in range(count):
		var projectile := PROJECTILE_SCENE.instantiate()
		var split_direction: Vector2 = target_directions[i]
		projectile.setup(origin + split_direction * 22.0, split_direction, 1180.0, damage, element, 0, 0, 0.55, 2.6, 0.0, 0.0, 0.82, 0, "res://assets/production/sprites/projectiles/proj_split_mini.png")
		projectile.hit_confirmed.connect(_on_projectile_hit_confirmed)
		$ProjectileLayer.call_deferred("add_child", projectile)

func _on_projectile_hit_confirmed(primary: Node, origin: Vector2, damage: float, element: String, splash_radius: float, cloud_radius: float, chain_depth: int, visual_profile: String) -> void:
	_spawn_element_impact_vfx(primary, origin, element, visual_profile)
	_trigger_impact_feedback(primary, damage, visual_profile)
	if chain_depth <= 0:
		_spawn_chain_projectiles(primary, origin, damage, element)
	_apply_character_bullet_on_hit(primary, origin, damage, element)
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
		target.take_damage(damage * scale * (0.55 + falloff * 0.45), element)

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
			if randf() < 0.18 + 0.03 * float(rank):
				_spawn_attack_ring(origin, 92.0, Color(1.0, 0.42, 0.12, 0.2), 0.14)
		"volt":
			if randf() < 0.14 + 0.03 * float(rank):
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
		return float(a.get("score", 0.0)) < float(b.get("score", 0.0))
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

func _spawn_chain_projectiles(primary: Node, origin: Vector2, damage: float, element: String) -> void:
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var special: Dictionary = weapon.get("special", {})
	var chain_count := int(skills.level("skill_ricochet")) + int(special.get("chain", 0)) + _character_chain_bonus_for(element)
	if element == "lightning" and skills.level("skill_tesla") > 0:
		chain_count += 1
	chain_count = mini(chain_count, 5)
	if chain_count <= 0:
		return
	var targets: Array[Node2D] = _chain_targets(origin, primary, chain_count, 430.0)
	for target in targets:
		if target == null or not is_instance_valid(target):
			continue
		var direction: Vector2 = (target.global_position - origin).normalized()
		var projectile := PROJECTILE_SCENE.instantiate()
		var chain_element := "lightning" if element == "physical" else element
		_spawn_chain_arc(origin, target.global_position, chain_element)
		projectile.setup(origin + direction * 18.0, direction, 1500.0, damage * 0.42, chain_element, 0, 0, 0.55, 2.8, 0.0, 0.0, 0.52, 1, "res://assets/production/sprites/projectiles/proj_split_mini.png")
		projectile.hit_confirmed.connect(_on_projectile_hit_confirmed)
		$ProjectileLayer.call_deferred("add_child", projectile)

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
		return float(a.get("score", 0.0)) < float(b.get("score", 0.0))
	)
	var targets: Array[Node2D] = []
	for item in candidates:
		if targets.size() >= count:
			break
		var target := item.get("enemy") as Node2D
		if target != null and is_instance_valid(target):
			targets.append(target)
	return targets

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
		"shield":
			return {
				"core": Color(0.72, 0.94, 1.0, 0.94),
				"spark": Color(0.42, 0.82, 1.0, 0.82),
				"ring": Color(0.48, 0.84, 1.0, 0.62),
			}
		"immune", "phase_evade":
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
		"shield", "immune", "phase_evade":
			_spawn_impact_fork_lines(position, ring, 5, 72.0 * safe_power, 0.15, 2.2 + safe_power, priority)
		"armor", "weak":
			_spawn_impact_streaks(position, spark, 5, 66.0 * safe_power, 0.13, 3.2 + safe_power, priority)
		_:
			match element:
				"fire":
					_spawn_impact_heat_haze(position, Color(1.0, 0.22, 0.04, 0.42), 0.18, safe_power, priority)
					_spawn_impact_cloud(position + Vector2(0, -4), Color(1.0, 0.32, 0.08, 0.26), 8, 0.26, true, priority)
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
		"immune", "phase_evade":
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
		"immune", "phase_evade":
			speed *= 0.7
	return speed * clampf(power, 0.65, 1.8)

func _impact_particle_spread(element: String, hit_kind: String) -> float:
	if hit_kind == "immune" or hit_kind == "phase_evade":
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
	_spawn_impact_cloud(origin, Color(color.r, color.g, color.b, minf(color.a, 0.34)), 14 if element == "poison" else 10, 0.38, element != "poison", safe_radius > 180.0)

func _spawn_hit_layer_vfx(position: Vector2, element: String, weak_hit: bool, hit_kind: String) -> void:
	var kind := hit_kind
	var power := 0.78
	match hit_kind:
		"armor":
			power = 1.05
		"shield":
			power = 1.12
		"immune", "phase_evade":
			power = 0.88
		"weak":
			power = 1.24
		_:
			kind = "normal"
	var anchor := position + Vector2(randf_range(-16.0, 16.0), randf_range(-46.0, -18.0))
	_spawn_b4_impact_stack(anchor, element, power, kind, weak_hit or kind != "normal")
	if weak_hit:
		_spawn_b4_impact_stack(position + Vector2(0, -44), element, 1.18, "weak", true)
	if hit_kind == "armor" or hit_kind == "shield" or hit_kind == "immune":
		var palette := _impact_palette(element, kind)
		var ring: Color = palette.get("ring", Color.WHITE)
		_spawn_impact_shock_ring(position + Vector2(0, -36), ring, 74.0, 5.0, 0.18, true)

func _spawn_death_element_vfx(position: Vector2, element: String, is_boss: bool) -> void:
	var scale := 1.0 if not is_boss else 2.05
	_spawn_zombie_blood_pool(position, is_boss)
	_spawn_b4_impact_stack(position + Vector2(0, -38 if not is_boss else -78), element, scale, "weak" if is_boss else "normal", is_boss)
	match element:
		"fire":
			_spawn_impact_cloud(position + Vector2(0, -38 if not is_boss else -82), Color(1.0, 0.3, 0.06, 0.34), 12 if not is_boss else 18, 0.42, true, is_boss)
			_spawn_impact_heat_haze(position + Vector2(0, -34 if not is_boss else -76), Color(1.0, 0.18, 0.04, 0.44), 0.28, scale, is_boss)
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
	low_hp_pulse.size = Vector2(1080, 1920)
	low_hp_pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Hud.add_child(low_hp_pulse)
	for spec in [
		{"name": "Top", "pos": Vector2(0, 0), "size": Vector2(1080, 120)},
		{"name": "Bottom", "pos": Vector2(0, 1760), "size": Vector2(1080, 160)},
		{"name": "Left", "pos": Vector2(0, 0), "size": Vector2(82, 1920)},
		{"name": "Right", "pos": Vector2(998, 0), "size": Vector2(82, 1920)}
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
		impact = Vector2(source.global_position.x, 1440.0)
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

func _spawn_enemy_attack_vfx(source: Node, kind: String, target_position: Vector2) -> void:
	if not is_instance_valid(source):
		return
	var color := _attack_color_for_mechanic(kind)
	var is_boss_source: bool = bool(source.boss)
	var fx := _spawn_vfx_sequence("vfx_enemy_skill_%s" % kind, target_position, 1.3 if is_boss_source else 0.9, Color(color.r, color.g, color.b, 0.94), 1.0, randf_range(-0.15, 0.15), 1.12, Vector2(0, -10), randf_range(-0.2, 0.2), true)
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

func _spawn_breach_attack_vfx(enemy: Node, shielded: bool) -> void:
	if not is_instance_valid(enemy):
		return
	var mechanic := str(enemy.get("base_attack_kind"))
	if mechanic == "" or mechanic == "<null>":
		mechanic = str(enemy.mechanic)
	var color := Color(0.58, 0.86, 1.0, 0.78) if shielded else _attack_color_for_mechanic(mechanic)
	var target := Vector2(enemy.global_position.x, minf(enemy.global_position.y + 54.0, BREACH_Y + 10.0))
	var path := "res://assets/production/sprites/vfx/vfx_hit_immune.png" if shielded else _attack_vfx_path(mechanic)
	_spawn_attack_sprite(path, target, color, _breach_attack_scale(mechanic), 0.26)
	_spawn_attack_ring(target, 118.0 * _breach_attack_scale(mechanic), color, 0.22)

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
			return "res://assets/production/sprites/vfx/vfx_explosion_fire.png"
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
			return Color(1.0, 0.9, 0.18, 0.78)
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
	AudioManager.play_sfx("enemy_death", -3.0)
	if enemy == active_boss:
		active_boss = null
	if is_instance_valid(enemy):
		enemy.set_meta("death_element", str(reward.get("death_element", "physical")))
	_resolve_death_mechanic(enemy)
	_process_kill_feedback(enemy, reward)
	# Stage 1 P0 — combat feel
	_register_kill_for_combo(bool(reward.get("boss", false)))
	_trigger_kill_screen_shake(bool(reward.get("boss", false)))
	_trigger_kill_hit_stop(bool(reward.get("boss", false)))
	var gold_per_kill := econ_gold_base + econ_gold_per * float(level_ordinal)
	var reward_gold := int(round(float(reward.get("gold_coef", 1.0)) * gold_per_kill * float(level.get("reward_gold_mult", 1.0)) * gold_mult * skills.gold_multiplier() * variant_gold_mult))
	var reward_xp := int(round(float(reward.get("xp", 0)) * variant_xp_mult))
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
	if enemy == target_manager.locked_enemy:
		target_manager.clear_lock()
	_try_show_xp_card_offer(enemy)

func _on_enemy_damage_dealt(enemy: Node, amount: float, element: String, crit_hit: bool, weak_hit: bool) -> void:
	if damage_numbers and is_instance_valid(enemy):
		damage_numbers.spawn_damage(enemy.global_position + Vector2(0, -34 if not bool(enemy.boss) else -76), amount, element, crit_hit, weak_hit)
	# crit-only screen shake (light) and hit stop (very short)
	if crit_hit:
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
	var now := Time.get_ticks_msec() / 1000.0
	kill_streak = kill_streak + 1 if now - last_kill_at <= 1.35 else 1
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
				_spawn_enemy_instance("zombie_crawler", enemy.global_position + Vector2(offset, 16.0), false)

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
		_apply_enemy_skill_base_damage(enemy, base_damage, "爆裂", color, enemy.global_position + Vector2(0, -80))

func _on_enemy_breached(enemy: Node, damage: int) -> void:
	AudioManager.play_sfx("enemy_breach", -4.0)
	_play_character_hurt()
	_shake_hud(5.0, 0.1)
	var final_damage := int(ceil(float(damage) * breach_damage_mult))
	final_damage = mini(final_damage, maxi(1, int(round(float(base_hp_max) * MAX_BASE_HIT_FRACTION))))  # 防秒杀
	var shield_absorbed := false
	if breach_shields + skill_barriers_left > 0:
		if breach_shields > 0:
			breach_shields -= 1
		else:
			skill_barriers_left -= 1
		final_damage = 0
		shield_absorbed = true
	if is_instance_valid(enemy):
		_spawn_breach_attack_vfx(enemy, final_damage <= 0)
		var text := "格挡" if final_damage <= 0 else "-%d" % final_damage
		_spawn_float_text(enemy.global_position + Vector2(randf_range(-16.0, 16.0), -104), text, Color(1.0, 0.18, 0.18))
		if shield_absorbed:
			_spawn_barrier_break_vfx(Vector2(enemy.global_position.x, BREACH_Y - 30.0))
			_update_barrier_visual()
	base_hp = max(base_hp - final_damage, 0)
	if final_damage > 0:
		_show_screen_flash(Color(1.0, 0.05, 0.03, 0.06), 0.1)
	_check_low_hp_warning()
	if base_hp <= 0:
		_finish(false)

func _compute_level_total_run_xp() -> int:
	var total := 0
	for w in level.get("waves", []):
		if w.has("boss"):
			total += int(DataLoader.get_row("bosses", str(w.get("boss", ""))).get("run_xp", 0))
		for s in w.get("spawns", []):
			total += int(s.get("count", 0)) * int(DataLoader.get_row("zombies", str(s.get("type", ""))).get("run_xp", 0))
		for s in w.get("support", []):
			total += int(s.get("count", 0)) * int(DataLoader.get_row("zombies", str(s.get("type", ""))).get("run_xp", 0))
	return total

func _pick_threshold(k: int) -> int:
	if k > target_card_picks and not is_endless_mode:
		return 1000000000
	if level_total_run_xp <= 0:
		return int(level.get("xp_first_offer", 16)) * k
	return int(round(float(level_total_run_xp) * float(k) / float(target_card_picks + 1)))

func _next_pick_threshold() -> int:
	return _pick_threshold(cards_picked + 1)

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
	endless_loop += 1
	wave_index = 0
	# 血量按轮次复利增长(而不是线性叠加):技能强化在无限模式里不设上限地持续变强,
	# 线性血量增长追不上,会导致刷到二三十轮之后反而越打越轻松;复利增长保持长期挑战感。
	endless_difficulty_mult = pow(1.0 + ENDLESS_LOOP_HP_GROWTH, float(endless_loop))
	_show_wave_toast("第 %d 轮尸潮 · 强度提升" % (endless_loop + 1), Color(1.0, 0.42, 0.22))
	_start_next_wave()

func _finish(victory: bool) -> void:
	if battle_finished:
		return
	battle_finished = true
	_set_turret_fire_enabled(false)
	_hide_skill_hint()
	set_physics_process(false)
	if is_endless_mode:
		AudioManager.play_sfx("defeat", 1.0, 0.0)
		_show_screen_flash(Color(0.85, 0.0, 0.0, 0.22), 0.28)
		router.finish_level({
			"level_id": level_id,
			"endless": true,
			"endless_loop": endless_loop,
			"victory": false,
			"stars": 0,
			"gold": gold,
			"xp": xp
		})
		return
	AudioManager.play_sfx("victory" if victory else "defeat", 1.0, 0.0)
	_show_screen_flash(Color(0.95, 0.78, 0.25, 0.18) if victory else Color(0.85, 0.0, 0.0, 0.22), 0.28)
	var hp_ratio := float(base_hp) / float(base_hp_max)
	var stars := 0
	if victory:
		stars = 3 if hp_ratio >= 1.0 else 2 if hp_ratio >= 0.5 else 1
	var first_clear_bonus := 0
	if victory and SaveManager.get_level_stars(level_id) == 0:
		first_clear_bonus = int(level.get("first_clear_reward", {}).get("gold", 0))
	router.finish_level({
		"level_id": level_id,
		"next_level": level.get("next_level", ""),
		"victory": victory,
		"stars": stars,
		"gold": gold + first_clear_bonus,
		"xp": xp
	})

func _update_hud() -> void:
	var hp_pct := float(base_hp) / float(base_hp_max) if base_hp_max > 0 else 0.0
	var hp_fill_left := _hud_fill_left("Hud/TopBar/BaseHpBar", 6.0)
	var hp_fill_right := _hud_fill_right("Hud/TopBar/BaseHpBar", HUD_HP_FILL_RIGHT)
	var hp_width := maxf(0.0, lerpf(hp_fill_left, hp_fill_right, hp_pct) - hp_fill_left)
	var hp_fill_texture := get_node_or_null("Hud/TopBar/BaseHpBar/FillTexture") as TextureRect
	if hp_fill_texture != null:
		hp_fill_texture.size.x = hp_width
	else:
		var hp_fill := $Hud/TopBar/BaseHpBar/Fill
		hp_fill.offset_right = lerpf(hp_fill_left, hp_fill_right, hp_pct)
	$Hud/TopBar/BaseHpBar/Label.text = "生命 %d/%d" % [base_hp, base_hp_max]
	_update_low_hp_pulse(hp_pct)
	_update_boss_hp_bar()
	var wave_pct := float(wave_index) / float(wave_total) if wave_total > 0 else 0.0
	displayed_wave_pct = lerpf(displayed_wave_pct, wave_pct, 0.22)
	var wave_fill_left := _hud_fill_left("Hud/TopBar/WaveProgress", 6.0)
	var wave_fill_right := _hud_fill_right("Hud/TopBar/WaveProgress", HUD_WAVE_FILL_RIGHT)
	var wave_width := maxf(0.0, lerpf(wave_fill_left, wave_fill_right, displayed_wave_pct) - wave_fill_left)
	var wave_fill_texture := get_node_or_null("Hud/TopBar/WaveProgress/FillTexture") as TextureRect
	if wave_fill_texture != null:
		wave_fill_texture.size.x = wave_width
	else:
		$Hud/TopBar/WaveProgress/Fill.offset_right = lerpf(wave_fill_left, wave_fill_right, displayed_wave_pct)
	if is_endless_mode:
		$Hud/TopBar/WaveProgress/Label.text = "第 %d 轮 · %d/%d 波" % [endless_loop + 1, wave_index, wave_total]
	else:
		$Hud/TopBar/WaveProgress/Label.text = "第 %d/%d 波" % [wave_index, wave_total]
	var xp_pct := float(xp) / float(next_xp_offer) if next_xp_offer > 0 else 0.0
	displayed_xp_pct = lerpf(displayed_xp_pct, clamp(xp_pct, 0.0, 1.0), 0.28)
	$Hud/BottomBar/XpBar/Fill.offset_right = lerpf(7.0, _hud_xp_fill_right(), displayed_xp_pct)
	$Hud/BottomBar/XpBar/Label.text = "经验 %d/%d" % [xp, next_xp_offer]
	$Hud/BottomBar/GoldLabel.text = "%d" % gold
	_update_skill_slots()
	_update_character_skill_button()
	_update_barrier_visual()
	if debug_overlay_on:
		$Hud/DebugOverlay.text = _build_debug_text()

func _hud_fill_left(bar_path: String, fallback: float) -> float:
	var bar := get_node_or_null(bar_path) as Control
	if bar == null or bar.size.x <= 16.0:
		return fallback
	if bar_path.begins_with("Hud/TopBar"):
		return bar.size.x * 0.31
	return fallback

func _hud_fill_right(bar_path: String, fallback: float) -> float:
	var bar := get_node_or_null(bar_path) as Control
	if bar == null or bar.size.x <= 16.0:
		return fallback
	if bar_path.begins_with("Hud/TopBar"):
		return bar.size.x * 0.69
	return maxf(8.0, bar.size.x - 6.0)

func _hud_xp_fill_right() -> float:
	var xp_bar := get_node_or_null("Hud/BottomBar/XpBar") as Control
	if xp_bar == null or xp_bar.size.x <= 24.0:
		return HUD_XP_FILL_RIGHT
	return maxf(10.0, xp_bar.size.x - 7.0)

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
	_update_skill_slots()

func _build_hud_skill_card(skill_id: String) -> PanelContainer:
	var row := DataLoader.get_row("skills", skill_id)
	var lv := skills.level(skill_id)
	var max_lv := skills.max_level(skill_id)
	var card := PanelContainer.new()
	card.name = skill_id
	card.custom_minimum_size = Vector2(60, 84)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.clip_contents = true
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_entered.connect(_show_skill_hint_for_skill.bind(skill_id))
	card.mouse_exited.connect(_hide_skill_hint)
	card.gui_input.connect(_on_hud_skill_slot_input.bind(skill_id))
	card.add_theme_stylebox_override("panel", _skill_card_style(lv, max_lv))
	card.tooltip_text = "%s 等级%d\n%s" % [
		DataLoader.tr_key(str(row.get("name_key", skill_id))),
		lv,
		_skill_brief(skill_id, row, lv)
	]
	var stack := VBoxContainer.new()
	stack.name = "HBox"
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 2)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(stack)
	var icon_box := PanelContainer.new()
	icon_box.name = "IconBox"
	icon_box.custom_minimum_size = Vector2(52, 52)
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
		icon.custom_minimum_size = Vector2(46, 46)
		icon.size = Vector2(46, 46)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_box.add_child(icon)
	var lv_badge := Label.new()
	lv_badge.name = "LevelBadge"
	lv_badge.text = "等级%d" % lv
	lv_badge.add_theme_font_size_override("font_size", 12)
	var badge_color := _skill_level_color(lv, max_lv)
	lv_badge.add_theme_color_override("font_color", badge_color)
	lv_badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lv_badge.add_theme_constant_override("outline_size", 3)
	lv_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lv_badge.custom_minimum_size = Vector2(54, 20)
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
	for skill_id in skill_slot_ids:
		var slot := $Hud/SkillSlots.get_node_or_null(skill_id)
		if slot == null:
			continue
		var lv := skills.level(skill_id)
		var max_lv := skills.max_level(skill_id)
		var badge := slot.get_node_or_null("HBox/LevelBadge")
		if badge != null and badge is Label:
			(badge as Label).text = "等级%d" % lv
			(badge as Label).add_theme_color_override("font_color", _skill_level_color(lv, max_lv))
		var row := DataLoader.get_row("skills", skill_id)
		if slot is Control:
			(slot as Control).tooltip_text = "%s 等级%d\n%s" % [
				DataLoader.tr_key(str(row.get("name_key", skill_id))),
				lv,
				_skill_brief(skill_id, row, lv)
			]
		# Re-apply card border + icon border to reflect new level color
		slot.add_theme_stylebox_override("panel", _skill_card_style(lv, max_lv))
		var icon_box := slot.get_node_or_null("HBox/IconBox")
		if icon_box != null and icon_box is PanelContainer:
			(icon_box as PanelContainer).add_theme_stylebox_override("panel", _skill_card_icon_style(lv, max_lv))

func _show_wave_toast(text: String, color: Color) -> void:
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
	wave_toast_banner.visible = true
	wave_toast_banner.position = WAVE_TOAST_BASE_POSITION + Vector2(0, 18)
	wave_toast_banner.scale = Vector2(0.92, 0.92)
	wave_toast_banner.modulate = Color(1, 1, 1, 0.0)
	wave_toast_tween = wave_toast_banner.create_tween()
	wave_toast_tween.tween_property(wave_toast_banner, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	wave_toast_tween.parallel().tween_property(wave_toast_banner, "position", WAVE_TOAST_BASE_POSITION, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	wave_toast_tween.parallel().tween_property(wave_toast_banner, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	wave_toast_tween.tween_interval(1.05)
	wave_toast_tween.tween_property(wave_toast_banner, "modulate:a", 0.0, 0.28)
	wave_toast_tween.parallel().tween_property(wave_toast_banner, "scale", Vector2(1.04, 1.04), 0.28)
	wave_toast_tween.tween_callback(func() -> void:
		wave_toast_banner.visible = false
		wave_toast_banner.modulate.a = 1.0
		wave_toast_banner.scale = Vector2.ONE
		wave_toast_banner.position = WAVE_TOAST_BASE_POSITION
	)

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
	var band := wave_toast_banner.get_node_or_null("Band") as TextureRect
	if band != null:
		band.position = Vector2.ZERO
		band.size = size
	wave_toast_label.position = Vector2(34, 2)
	wave_toast_label.size = size - Vector2(68, 22)
	wave_toast_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY if long_text else TextServer.AUTOWRAP_OFF
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
			text = "自动开火会优先压制近线威胁，点僵尸可锁定优先击杀。"
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
	if loadout_power_ratio < 0.86:
		body.text += "  战力偏低，优先保防线。"
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
	return str(character_data.get("element_focus", "")) == primary_weakness or str(weapon.get("element", "")) == primary_weakness or (str(chip_data.get("stat", "")) == "element_damage_mult" and primary_weakness != "physical")

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

func _apply_slow_field() -> void:
	var slow_level := skills.level("skill_slow_field")
	if slow_level <= 0:
		_update_slow_field_visual(0)
		return
	for enemy in $EnemyLayer.get_children():
		if enemy.has_method("targeting_snapshot"):
			var slow_mult := skills.slow_mult_for_y(enemy.global_position.y)
			if slow_mult < 1.0:
				slow_mult = max(0.45, 1.0 - (1.0 - slow_mult) * slow_strength_bonus)
			enemy.speed_mult *= slow_mult
	_update_slow_field_visual(slow_level)

func _spawn_slow_field_visual() -> void:
	slow_field_rect = TextureRect.new()
	slow_field_rect.name = "SlowFieldShaderTint"
	slow_field_rect.texture = SLOW_FIELD_BAND_TEXTURE
	slow_field_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slow_field_rect.stretch_mode = TextureRect.STRETCH_SCALE
	slow_field_rect.position = Vector2(0, 0)
	slow_field_rect.size = Vector2(1080, 80)
	slow_field_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slow_field_rect.visible = false
	slow_field_rect.z_index = 2
	var field_material := ShaderMaterial.new()
	field_material.shader = SLOW_FIELD_SHADER
	field_material.set_shader_parameter("field_color", Color(0.32, 0.82, 1.0, 0.0))
	field_material.set_shader_parameter("edge_color", Color(0.76, 0.96, 1.0, 0.0))
	field_material.set_shader_parameter("intensity", 0.0)
	field_material.set_shader_parameter("scan_strength", 0.32)
	slow_field_rect.material = field_material
	$SlowFieldLayer.add_child(slow_field_rect)

	slow_field_rune_layer = Node2D.new()
	slow_field_rune_layer.name = "SlowFieldAdditiveEdges"
	slow_field_rune_layer.process_mode = Node.PROCESS_MODE_PAUSABLE
	slow_field_rune_layer.visible = false
	slow_field_rune_layer.z_index = 5
	$SlowFieldLayer.add_child(slow_field_rune_layer)
	slow_field_edge_lines.clear()
	for edge_name in ["TopEdge", "BottomEdge", "ColdCurrent"]:
		var edge := Line2D.new()
		edge.name = edge_name
		edge.width = 3.0
		edge.default_color = Color(0.72, 0.96, 1.0, 0.0)
		edge.joint_mode = Line2D.LINE_JOINT_ROUND
		edge.begin_cap_mode = Line2D.LINE_CAP_ROUND
		edge.end_cap_mode = Line2D.LINE_CAP_ROUND
		edge.texture = VfxLib.STREAK_TEXTURE
		edge.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		edge.material = _new_muzzle_additive_material()
		slow_field_rune_layer.add_child(edge)
		slow_field_edge_lines.append(edge)

	slow_field_particles = GPUParticles2D.new()
	slow_field_particles.name = "SlowFieldColdMotes"
	slow_field_particles.process_mode = Node.PROCESS_MODE_PAUSABLE
	slow_field_particles.amount = 36
	slow_field_particles.lifetime = 1.45
	slow_field_particles.preprocess = 0.7
	slow_field_particles.randomness = 0.84
	slow_field_particles.local_coords = false
	slow_field_particles.texture = VfxLib.RADIAL_GLOW_TEXTURE
	slow_field_particles.material = _new_muzzle_additive_material()
	slow_field_particles.z_index = 6
	slow_field_particles.visibility_rect = Rect2(-620.0, -260.0, 1240.0, 520.0)
	slow_field_particles.emitting = false
	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(520.0, 46.0, 0.0)
	process_material.direction = Vector3(0.0, -1.0, 0.0)
	process_material.spread = 180.0
	process_material.initial_velocity_min = 8.0
	process_material.initial_velocity_max = 48.0
	process_material.gravity = Vector3(0.0, -10.0, 0.0)
	process_material.damping_min = 8.0
	process_material.damping_max = 24.0
	process_material.angle_min = -45.0
	process_material.angle_max = 45.0
	process_material.angular_velocity_min = -48.0
	process_material.angular_velocity_max = 48.0
	process_material.scale_min = 0.08
	process_material.scale_max = 0.22
	process_material.scale_curve = _impact_cloud_scale_curve()
	process_material.color_ramp = _impact_color_ramp(Color(0.86, 1.0, 1.0, 0.42), Color(0.38, 0.86, 1.0, 0.22), Color(0.26, 0.72, 1.0, 0.0))
	slow_field_particles.process_material = process_material
	$SlowFieldLayer.add_child(slow_field_particles)

func _update_slow_field_visual(slow_level: int) -> void:
	if slow_field_rect == null:
		return
	if slow_level <= 0:
		slow_field_rect.visible = false
		if slow_field_rune_layer != null:
			slow_field_rune_layer.visible = false
		if slow_field_particles != null:
			slow_field_particles.emitting = false
			slow_field_particles.visible = false
		return
	var y_min: float
	var slow_pct: float
	match slow_level:
		1:
			y_min = 1280.0
			slow_pct = 0.18
		2:
			y_min = 1220.0
			slow_pct = 0.26
		3:
			y_min = 1160.0
			slow_pct = 0.35
		_:
			y_min = 1500.0
			slow_pct = 0.0
	slow_field_rect.position = Vector2(0, y_min)
	var field_height := maxf(1500.0 - y_min, 60.0)
	slow_field_rect.size = Vector2(1080, field_height)
	slow_field_rect.visible = true
	var field_color := Color(0.28, 0.76, 1.0, 0.14 + slow_pct * 0.23)
	var edge_color := Color(0.78, 0.98, 1.0, 0.28 + slow_pct * 0.32)
	var shader_material := slow_field_rect.material as ShaderMaterial
	if shader_material != null:
		shader_material.set_shader_parameter("field_color", field_color)
		shader_material.set_shader_parameter("edge_color", edge_color)
		shader_material.set_shader_parameter("intensity", 0.72 + slow_pct * 1.1)
		shader_material.set_shader_parameter("scan_strength", 0.25 + slow_pct * 0.58)
	_update_slow_field_edges(y_min, field_height, slow_pct)
	_update_slow_field_particles(y_min, field_height, slow_pct, slow_level)

func _update_slow_field_edges(y_min: float, field_height: float, slow_pct: float) -> void:
	if slow_field_rune_layer == null:
		return
	slow_field_rune_layer.visible = true
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 340.0)
	var top_y := y_min + 6.0
	var bottom_y := y_min + field_height - 8.0
	var current_y := y_min + field_height * (0.44 + sin(Time.get_ticks_msec() / 980.0) * 0.08)
	for i in range(slow_field_edge_lines.size()):
		var edge := slow_field_edge_lines[i]
		if edge == null:
			continue
		var alpha := 0.24 + slow_pct * 0.4 + pulse * 0.1
		var y := top_y
		var width := 4.8
		if i == 1:
			y = bottom_y
			alpha *= 0.72
			width = 3.2
		elif i == 2:
			y = current_y
			alpha *= 0.42
			width = 2.4
		edge.width = width
		edge.default_color = Color(0.74, 0.98, 1.0, clampf(alpha, 0.08, 0.72))
		edge.points = PackedVector2Array([
			Vector2(46.0, y + sin(Time.get_ticks_msec() / 410.0) * 2.0),
			Vector2(330.0, y + sin(Time.get_ticks_msec() / 530.0 + float(i)) * 5.0),
			Vector2(720.0, y + sin(Time.get_ticks_msec() / 610.0 + float(i) * 1.7) * 5.0),
			Vector2(1034.0, y + sin(Time.get_ticks_msec() / 450.0 + float(i) * 0.8) * 2.0),
		])

func _update_slow_field_particles(y_min: float, field_height: float, slow_pct: float, slow_level: int) -> void:
	if slow_field_particles == null:
		return
	slow_field_particles.visible = true
	slow_field_particles.global_position = Vector2(540.0, y_min + field_height * 0.5)
	slow_field_particles.amount = clampi(20 + slow_level * 8, 24, 44)
	slow_field_particles.emitting = true
	var process_material := slow_field_particles.process_material as ParticleProcessMaterial
	if process_material == null:
		return
	process_material.emission_box_extents = Vector3(520.0, maxf(field_height * 0.42, 34.0), 0.0)
	process_material.initial_velocity_min = 8.0 + slow_pct * 24.0
	process_material.initial_velocity_max = 42.0 + slow_pct * 56.0
	process_material.gravity = Vector3(0.0, -8.0 - slow_pct * 24.0, 0.0)

func _spawn_barrier_visual() -> void:
	barrier_visual = Node2D.new()
	barrier_visual.name = "BarrierGlass"
	barrier_visual.position = Vector2(540, BREACH_Y - 30.0)
	barrier_visual.visible = false
	$SlowFieldLayer.add_child(barrier_visual)

	barrier_fill = Polygon2D.new()
	barrier_fill.name = "Fill"
	barrier_fill.polygon = PackedVector2Array([
		Vector2(-430, 18),
		Vector2(-350, -86),
		Vector2(350, -86),
		Vector2(430, 18),
		Vector2(336, 76),
		Vector2(-336, 76),
	])
	barrier_fill.material = _new_muzzle_additive_material()
	barrier_visual.add_child(barrier_fill)

	barrier_edges = []
	for points in [
		[Vector2(-430, 18), Vector2(-350, -86), Vector2(350, -86), Vector2(430, 18)],
		[Vector2(-336, 76), Vector2(336, 76)],
		[Vector2(-220, 58), Vector2(-160, -64)],
		[Vector2(0, 68), Vector2(0, -76)],
		[Vector2(220, 58), Vector2(160, -64)],
	]:
		var edge := Line2D.new()
		edge.points = PackedVector2Array(points)
		edge.width = 4.0
		edge.antialiased = true
		edge.texture = VfxLib.STREAK_TEXTURE
		edge.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		edge.material = _new_muzzle_additive_material()
		barrier_visual.add_child(edge)
		barrier_edges.append(edge)
	_update_barrier_visual()

func _barrier_charge_count() -> int:
	return breach_shields + skill_barriers_left

func _update_barrier_visual() -> void:
	if barrier_visual == null or barrier_fill == null:
		return
	var charges := _barrier_charge_count()
	barrier_visual.visible = charges > 0
	if charges <= 0:
		return
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 240.0)
	var alpha := clampf(0.12 + float(charges) * 0.035 + pulse * 0.035, 0.12, 0.28)
	barrier_fill.color = Color(0.42, 0.86, 1.0, alpha)
	for edge in barrier_edges:
		edge.default_color = Color(0.72, 0.94, 1.0, clampf(alpha + 0.22, 0.32, 0.58))

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
	_spawn_levelup_vfx(Vector2(540, 1580), Color(0.7, 0.95, 1.0))
	$Hud/CardPanel/CardTitle.text = _card_offer_title()
	$Hud/CardPanel.visible = true
	_animate_card_panel_in()

func _card_offer_title() -> String:
	var tags: Array = level.get("threat_tags", [])
	if tags.has("fast"):
		return "选择强化：优先减速/追踪"
	if tags.has("tank") or tags.has("boss"):
		return "选择强化：优先穿透/蓄能"
	if tags.has("support"):
		return "选择强化：优先锁定/连锁"
	if tags.has("breach"):
		return "选择强化：优先清群/防线"
	return "选择强化：围绕当前武器成型"

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
	for child in cards.get_children():
		child.queue_free()
	$Hud/CardPanel/DetailOverlay.visible = false
	for skill_id in card_director.offer(level, owned_snapshot):
		var row := DataLoader.get_row("skills", skill_id)
		var name := DataLoader.tr_key(row.get("name_key", skill_id))
		var lv := _skill_offer_level(skill_id)
		cards.add_child(_build_skill_card(skill_id, row, name, lv))
	var reroll_label: Label = $Hud/CardPanel/RerollButton/RerollLabel
	reroll_label.text = "重抽 (%d)" % reroll_charges
	$Hud/CardPanel/RerollButton.disabled = reroll_charges <= 0
	$Hud/CardPanel/RerollButton.modulate = Color(1, 1, 1, 1) if reroll_charges > 0 else Color(0.5, 0.5, 0.5, 1)

func _skill_offer_level(skill_id: String) -> int:
	return mini(skills.level(skill_id) + 1, skills.max_level(skill_id))

func _build_skill_card(skill_id: String, row: Dictionary, display_name: String, lv: int) -> Panel:
	var stats_text := SkillEffectText.format_offer_block(row, lv, skills.level(skill_id))
	var stats_extra_h := 34.0 * float(stats_text.count("\n"))
	var card_h := 196.0 + stats_extra_h
	var card := Panel.new()
	card.custom_minimum_size = Vector2(760, card_h)
	card.clip_contents = true
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(_on_skill_card_input.bind(skill_id))
	card.mouse_entered.connect(_show_skill_hint_for_skill.bind(skill_id))
	card.mouse_exited.connect(_hide_skill_hint)
	var accent := _skill_card_accent(skill_id, row)
	card.add_theme_stylebox_override("panel", UiKit.collection_card_texture_style(true))

	var accent_bar := TextureRect.new()
	accent_bar.position = Vector2(0, 0)
	accent_bar.size = Vector2(18, card_h)
	accent_bar.texture = load("res://assets/production/sprites/ui/ui_map_accent_strip.png")
	accent_bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	accent_bar.stretch_mode = TextureRect.STRETCH_SCALE
	accent_bar.modulate = accent
	accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(accent_bar)

	var icon_box := PanelContainer.new()
	icon_box.position = Vector2(20, 24)
	icon_box.size = Vector2(132, 132)
	icon_box.add_theme_stylebox_override("panel", UiKit.icon_frame_texture_style(true))
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon_box)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = load(row.get("icon", ""))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(27, 25)
	icon.size = Vector2(118, 118)
	icon.custom_minimum_size = Vector2(118, 118)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon)

	var title := Label.new()
	title.name = "Title"
	title.text = "%s  等级%d" % [display_name, lv]
	title.position = Vector2(170, 14)
	title.size = Vector2(370, 40)
	UiKit.apply_label(title, 31, Color(0.96, 0.99, 1.0, 1.0), 3)
	title.clip_text = true
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(title)

	var stats := Label.new()
	stats.name = "Stats"
	stats.text = stats_text
	stats.position = Vector2(170, 54)
	stats.size = Vector2(560, 56 + stats_extra_h)
	UiKit.apply_label(stats, 22, UiKit.CYAN, 2)
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(stats)

	var desc := Label.new()
	desc.name = "Desc"
	desc.text = _skill_short_desc(skill_id, lv)
	desc.position = Vector2(170, 112 + stats_extra_h)
	desc.size = Vector2(560, 44)
	UiKit.apply_label(desc, 19, Color(0.78, 0.9, 0.96, 1.0), 2)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.clip_text = true
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(desc)

	var tags := HBoxContainer.new()
	tags.name = "Tags"
	tags.position = Vector2(170, 156 + stats_extra_h)
	tags.size = Vector2(520, 34)
	tags.add_theme_constant_override("separation", 8)
	tags.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(tags)
	for tag in row.get("card_tags", []).slice(0, 3):
		tags.add_child(_card_tag_chip(str(tag), accent))

	var reason := _skill_recommendation_reason(skill_id, row)
	if reason != "":
		var badge := PanelContainer.new()
		badge.name = "RecommendBadge"
		badge.position = Vector2(538, 18)
		badge.size = Vector2(196, 34)
		badge.add_theme_stylebox_override("panel", UiKit.pill_style(UiKit.GOLD, Color(0.14, 0.09, 0.015, 0.9)))
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(badge)
		var badge_text := UiKit.label("推荐 · %s" % reason, 18, UiKit.GOLD, 3)
		badge_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_child(badge_text)

	return card

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
	chip.custom_minimum_size = Vector2(116, 32)
	chip.add_theme_stylebox_override("panel", UiKit.pill_style(accent, Color(0.02, 0.045, 0.065, 0.82)))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	chip.add_child(row)
	var icon_path := _tag_icon_path(tag)
	if icon_path != "":
		row.add_child(UiKit.icon(icon_path, Vector2(22, 22)))
	var label := UiKit.label(_tag_name(tag), 15, Color(0.9, 0.98, 1.0, 1.0), 2)
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
	$Hud/CardPanel/DetailOverlay.visible = true
	$Hud/CardPanel/DetailOverlay/Panel/Icon.texture = load(row.get("icon", ""))
	$Hud/CardPanel/DetailOverlay/Panel/Title.text = "%s  等级%d" % [DataLoader.tr_key(row.get("name_key", skill_id)), lv]
	$Hud/CardPanel/DetailOverlay/Panel/Body.text = "%s\n\n%s\n\n%s\n\n标签：%s" % [
		SkillEffectText.format_offer_block(row, lv, current_lv),
		"全部等级：\n%s" % SkillEffectText.format_all_levels(row, lv),
		_skill_long_desc(skill_id, lv),
		_format_card_tags(row.get("card_tags", []))
	]

func _hide_card_detail() -> void:
	AudioManager.play_sfx("ui_click", -5.0)
	$Hud/CardPanel/DetailOverlay.visible = false
	card_press_skill_id = ""
	card_long_press_opened = false

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
	_spawn_attack_ring(Vector2(540, 1540), 180.0, Color(color.r, color.g, color.b, 0.26), 0.28)

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
			return "防线前生成减速区，压住漏怪节奏。"
		"skill_homing":
			return "子弹获得轻微追踪，减少高速怪和斜线目标漏枪。"
		"skill_critical":
			return "提高暴击率和伤害，对精英与首领更有效。"
		"skill_barrier":
			return "获得一次防线拦截，挡下下一只冲线僵尸。"
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
			return "提升主弹伤害，让单点击杀更干脆。"
		"skill_recycle":
			return "获得额外重抽次数，提高技能成型稳定性。"
		_:
			return "强化当前战斗能力。"

func _skill_long_desc(skill_id: String, lv: int) -> String:
	match skill_id:
		"skill_split_shot":
			return "每次命中都会触发分裂弹。等级越高分裂数量越多，满级(5级)分裂6发并大幅降低伤害衰减，形成密集扇形爆发，适合密集推进。"
		"skill_pierce":
			return "主弹可以继续穿透后排敌人。3级起附带额外伤害，满级穿透6名并显著增伤，适合处理巨臂和首领护甲。"
		"skill_multishot":
			return "每次开火额外发射弹丸。等级越高弹丸越多，满级一次5发额外弹丸形成宽幅扇面，手感上是纯火力压制。"
		"skill_slow_field":
			return "在防线前展开持续减速区。等级越高，区域越靠前、减速越强，3级会显示更宽的青色力场。"
		"skill_homing":
			return "子弹飞行中会向最近目标修正方向。等级越高修正越明显，能显著改善斜线开火、高速小怪和残血补刀的手感。"
		"skill_critical":
			return "提高暴击概率与全局伤害，3级起额外提高暴击伤害，满级暴伤大幅跃升。适合搭配高射速武器，面对精英、首领和护盾怪收益最高。"
		"skill_barrier":
			return "立刻补充技能护盾，下一次敌人冲线时不扣基地生命。多次选择可叠加，满级单次补充2层，是后期容错核心。"
		"skill_gold_rush":
			return "本局获得金币提高。它不会直接提高战力，但能让过关后的武器和装备成长更快，适合低压波次选择。"
		"skill_ricochet":
			return "命中后产生额外弹射弹，和分裂弹共享清群定位。等级越高弹射数量越多，适合尸潮密度高的关卡。"
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
			return "提高所有主弹基础伤害。它没有复杂机制，但能直接缩短击杀时间，适合补足单体输出短板。"
		"skill_recycle":
			return "补充重抽机会，满级单次补充2次。拿到它以后，后续技能选择更容易围绕角色、武器和关卡威胁成型。"
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
	next_xp_offer = _next_pick_threshold()

func _choose_card(skill_id: String) -> void:
	AudioManager.play_sfx("card_pick")
	AudioManager.play_sfx("level_up", -3.0, 0.02)
	_hide_skill_hint()
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
	cards_picked += 1
	_spawn_levelup_vfx(Vector2(540, 1580), Color(1.0, 0.86, 0.3))
	_spawn_skill_pick_vfx(skill_id)
	if skill_id == "skill_barrier":
		skill_barriers_left += skills.barrier_gain()
		_spawn_barrier_gain_vfx()
	if skill_id == "skill_recycle":
		reroll_charges += skills.reroll_gain()
	if skill_id == "skill_salvo" and turret != null:
		var next_fire_rate_mult := skills.fire_rate_multiplier()
		turret.fire_rate *= next_fire_rate_mult / skill_fire_rate_mult
		skill_fire_rate_mult = next_fire_rate_mult
		_spawn_float_text(_weapon_fire_origin() + Vector2(0, -82), "攻速提升", Color(1.0, 0.86, 0.32))
	_process_build_feedback(skill_id)
	_show_wave_toast("%s 已生效" % DataLoader.tr_key(DataLoader.get_row("skills", skill_id).get("name_key", skill_id)), Color(1.0, 0.86, 0.28))
	_update_skill_slots()
	_spawn_skill_to_slot_vfx(skill_id)
	next_xp_offer = _next_pick_threshold()
	_close_card_offer(false)
	_update_character_skill_button()

func _spawn_skill_pick_vfx(skill_id: String) -> void:
	if not _can_spawn_projectile_fx(true):
		return
	var origin := Vector2(540, 1560)
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
	# 子弹命中(_on_projectile_hit_confirmed)和主动技能命中(_active_skill_apply_hit)
	# 都会直接调 _spawn_element_impact_vfx，随后 take_damage 又会通过这个信号再触发
	# 一次 _spawn_hit_layer_vfx——普通命中(hit_kind=="normal")两边其实是同一种粒子
	# 爆发，叠在一起打就变成一大团不自然的定向喷射。弱点/破甲/护盾/免疫命中另有专属
	# 提示效果，不去重。这里只对普通命中用极短时间窗去掉那份纯重复。
	if hit_kind == "normal" and enemy.has_meta("_recent_impact_vfx_ms") and Time.get_ticks_msec() - int(enemy.get_meta("_recent_impact_vfx_ms")) < 50:
		return
	_spawn_hit_layer_vfx(enemy.global_position, element, weak_hit, hit_kind)

func _process_threat_feedback(enemies: Array) -> void:
	if enemies.is_empty():
		return
	var now := Time.get_ticks_msec() / 1000.0
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.y >= 1160.0 and not enemy.has_meta("near_line_warned"):
			enemy.set_meta("near_line_warned", true)
			var color := _attack_color_for_mechanic(str(enemy.mechanic))
			_spawn_attack_ring(Vector2(enemy.global_position.x, 1450.0), 96.0 if not bool(enemy.boss) else 150.0, Color(color.r, color.g, color.b, 0.28), 0.2)
		if enemy.global_position.y >= 1260.0:
			if now - last_threat_warning_at < 2.2:
				continue
			last_threat_warning_at = now
			AudioManager.play_sfx("threat_warning", -4.0, 0.02)
			_show_wave_toast("防线告急", Color(1.0, 0.22, 0.12))
			return

func _check_low_hp_warning() -> void:
	if low_hp_warned or base_hp_max <= 0:
		return
	var hp_ratio := float(base_hp) / float(base_hp_max)
	if hp_ratio > 0.28:
		return
	low_hp_warned = true
	AudioManager.play_sfx("threat_warning", -2.0, 0.0)
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
		screen_flash.size = Vector2(1080, 1920)
		screen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$Hud.add_child(screen_flash)
	if screen_flash_tween != null and screen_flash_tween.is_valid():
		screen_flash_tween.kill()
	var current_alpha := screen_flash.modulate.a
	var alpha := minf(maxf(color.a, current_alpha), 0.14)
	screen_flash.modulate = Color(color.r, color.g, color.b, alpha)
	screen_flash_tween = screen_flash.create_tween()
	screen_flash_tween.tween_property(screen_flash, "modulate:a", 0.0, duration)

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
	# 背景与玩法坐标对齐:覆盖 1080x1920 玩法世界(中心 540,960),人物/刷怪/基座都对得上。
	# expand 多出来的视口高度靠深色清屏色垫底(project.godot default_clear_color),不再位移背景。
	background.position = Vector2(540, 960)
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		background.scale = Vector2.ONE
		return
	var cover_scale := maxf(1080.0 / texture_size.x, 1920.0 / texture_size.y)
	background.scale = Vector2(cover_scale, cover_scale)
	background.modulate = Color(1, 1, 1, 1)

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

func _spawn_float_text(world_pos: Vector2, text: String, color: Color) -> void:
	var priority := text.contains("首领") or text.contains("防线") or text.contains("基地")
	if not _can_spawn_float_text(priority):
		return
	var label := Label.new()
	_track_transient_fx(label, "float_text")
	label.text = text
	label.position = world_pos
	label.size = Vector2(220, 34)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 21)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Hud.add_child(label)
	var tween := label.create_tween()
	tween.parallel().tween_property(label, "position:y", label.position.y - 48.0, 0.55)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.55)
	tween.tween_callback(label.queue_free)
