extends Node2D

const ENEMY_SCENE := preload("res://gameplay/enemy/enemy.tscn")
const TURRET_SCENE := preload("res://gameplay/turret/turret.tscn")
const PROJECTILE_SCENE := preload("res://gameplay/projectile/projectile.tscn")
const CharacterSkillText := preload("res://core/data/character_skill_text.gd")
const BREACH_Y := 1500.0
const SKILL_ORDER := ["skill_split_shot", "skill_pierce", "skill_multishot", "skill_slow_field", "skill_homing", "skill_critical", "skill_barrier", "skill_gold_rush", "skill_ricochet", "skill_salvo", "skill_incendiary", "skill_cryo", "skill_tesla", "skill_venom", "skill_charge_shot", "skill_recycle"]
const SKILL_SLOT_LIMIT := 8
const HUD_HP_FILL_RIGHT := 556.0
const HUD_WAVE_FILL_RIGHT := 556.0
const HUD_XP_FILL_RIGHT := 716.0
const ENABLE_DEBUG_OVERLAY := false

var router: Node
var level := {}
var level_id := "level_001"
var base_hp := 100
var base_hp_max := 100
var gold := 0
var xp := 0
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
var paused := false
var debug_overlay_on := false
var slow_field_rect: Control
var card_press_skill_id := ""
var card_press_started_at := 0.0
var card_long_press_opened := false
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
var character_sprite: Sprite2D
var character_aura: Sprite2D
var pet_aura: Sprite2D
var character_idle_frames: Array[Texture2D] = []
var character_attack_frames: Array[Texture2D] = []
var character_hurt_frames: Array[Texture2D] = []
var character_anim_time := 0.0
var character_anim_frame := 0
var character_attack_time := 0.0
var character_hurt_time := 0.0
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
var screen_flash: ColorRect
var screen_flash_tween: Tween
var displayed_wave_pct := 0.0
var displayed_xp_pct := 0.0
var build_feedback_shown := {}

# Stage 1 P0 — combat feel & feedback
var hit_stop: Node
var screen_shake_node: Node
var combo_hud: Control
var damage_numbers: Node2D
var off_screen_indicators: Node2D
var gold_fly: Node
var _lock_indicator_base_scale := 0.42
var _lock_pulse_tween: Tween
var _last_kill_at_for_combo := -99.0

func setup(main: Node, payload := {}) -> void:
	router = main
	level_id = _resolve_level_id(payload)

func _ready() -> void:
	$Hud.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	level = DataLoader.get_row("levels", level_id)
	AudioManager.play_bgm(_battle_bgm_id())
	primary_weakness = str(level.get("primary_weakness", "physical"))
	onboarding_stage = str(level.get("onboarding_stage", ""))
	loadout_power_ratio = float(SaveManager.get_loadout_power()) / maxf(float(SaveManager.get_recommended_power_for_level(level_id)), 1.0)
	wave_total = int(level.get("waves", []).size())
	base_hp_max = int(level.get("base_hp_ref", 100))
	base_hp = base_hp_max
	xp = 0
	gold = 0
	cards_picked = 0
	next_xp_offer = int(level.get("xp_first_offer", 16))
	reroll_charges = 1
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
	_spawn_low_hp_pulse()
	_spawn_feedback_managers()
	add_child(target_manager)
	_load_equipment()
	_configure_character_active_skill()
	_apply_base_survivability()
	weapon_id = SaveManager.get_selected("weapon")
	if weapon_id == "":
			weapon_id = "weapon_autocannon"
	weapon_level = SaveManager.get_weapon_level(weapon_id)
	turret = TURRET_SCENE.instantiate()
	turret.position = Vector2(540, 1660)
	turret.setup(DataLoader.get_row("weapons", weapon_id), weapon_level)
	_apply_turret_modifiers()
	turret.fired.connect(_on_turret_fired)
	add_child(turret)
	_attach_growth_badge(turret, weapon_level, Vector2(-82, -145))
	_spawn_character()
	_spawn_pet()
	InputManager.aim_point.connect(turret.aim_at)
	InputManager.target_locked.connect(_on_target_lock_requested)
	InputManager.pause_pressed.connect(_on_pause_pressed)
	InputManager.target_strategy_changed.connect(_on_strategy_changed)
	InputManager.skill_pressed.connect(_on_skill_pressed)
	$PauseLayer/PauseButton.pressed.connect(_on_pause_pressed)
	$Hud/PauseOverlay/Panel/ResumeButton.pressed.connect(_on_resume_pressed)
	$Hud/PauseOverlay/Panel/RestartButton.pressed.connect(_on_restart_pressed)
	$Hud/PauseOverlay/Panel/MapButton.pressed.connect(_on_pause_to_map)
	$Hud/StrategyButton.pressed.connect(_on_strategy_button_pressed)
	$Hud/CharacterSkillButton.pressed.connect(_on_character_skill_pressed)
	$Hud/CardPanel/RerollButton.pressed.connect(_on_reroll_pressed)
	$Hud/CardPanel/SkipButton.pressed.connect(_on_skip_card)
	$Hud/CardPanel/DetailOverlay/Panel/CloseButton.pressed.connect(_hide_card_detail)
	$LockIndicator.texture = load("res://assets/sprites/vfx/vfx_target_lock.png")
	_spawn_slow_field_visual()
	_spawn_barrier_visual()
	_build_skill_slots()
	_update_objective_panel()
	_update_hud()
	_show_loadout_intro()
	_start_next_wave()
	call_deferred("_show_onboarding_tip")

func _physics_process(delta: float) -> void:
	if card_offer_active or paused:
		_update_lock_indicator()
		return
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
	var enemies := $EnemyLayer.get_children()
	var target := target_manager.choose_target(enemies, turret.global_position)
	if target:
		turret.aim_at(target.global_position)

func _load_equipment() -> void:
	character_id = SaveManager.get_selected("character")
	if character_id == "":
		character_id = "vanguard"
	armor_id = SaveManager.get_selected("armor")
	if armor_id == "":
		armor_id = "armor_kevlar"
	chip_id = SaveManager.get_selected("chip")
	if chip_id == "":
		chip_id = "chip_attack"
	pet_id = SaveManager.get_selected("pet")
	character_data = DataLoader.get_row("characters", character_id)
	armor_data = DataLoader.get_row("armors", armor_id)
	chip_data = DataLoader.get_row("chips", chip_id)
	pet_data = DataLoader.get_row("pets", pet_id) if pet_id != "" else {}
	character_level = SaveManager.get_item_level(character_id)
	armor_level = SaveManager.get_item_level(armor_id)
	chip_level = SaveManager.get_item_level(chip_id)
	pet_level = SaveManager.get_item_level(pet_id) if pet_id != "" else 1

func _configure_character_active_skill() -> void:
	var active: Dictionary = character_data.get("active_skill", {})
	character_active_id = str(active.get("id", ""))
	character_active_cd_max = float(active.get("cooldown", 16.0))
	character_active_cd = 0.0
	if has_node("Hud/CharacterSkillButton"):
		$Hud/CharacterSkillButton.visible = character_active_id != ""
		_update_character_skill_button()

func _on_skill_pressed(slot: int) -> void:
	if slot == 0:
		_on_character_skill_pressed()

func _on_character_skill_pressed() -> void:
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
		_show_wave_toast("暂无可释放目标", Color(0.72, 0.92, 1.0))
		AudioManager.play_sfx("ui_click", -6.0)
		return
	character_active_cd = character_active_cd_max
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
	sig_vanguard_barrage_timer = float(active.get("duration", 6.0))
	AudioManager.play_sfx("level_up", -3.0, 0.02)
	_show_wave_toast("弹幕齐射", Color(1.0, 0.88, 0.42))
	_spawn_attack_ring(turret.global_position + Vector2(0, -90), 220.0, Color(1.0, 0.86, 0.38, 0.3), 0.28)
	_refresh_character_fire_rate_buff()
	return true

func _trigger_vanguard_overload() -> void:
	sig_vanguard_overload_used = true
	sig_vanguard_overload_timer = 5.0
	AudioManager.play_sfx("threat_warning", -4.0, 0.02)
	_show_wave_toast("过载反击", Color(1.0, 0.42, 0.18))
	_spawn_levelup_vfx(turret.global_position + Vector2(0, -110), Color(1.0, 0.42, 0.18), 0.42)
	_refresh_character_fire_rate_buff()

func _cast_blaze_meltdown() -> bool:
	var active: Dictionary = character_data.get("active_skill", {})
	var radius := float(active.get("radius", 260.0)) + float(_growth_rank(character_level)) * 24.0
	var damage := _character_active_damage("fire", float(active.get("damage_mult", 3.6)))
	var target := _best_active_target()
	if target == null:
		return false
	var origin := target.global_position
	AudioManager.play_sfx("muzzle_fire", -2.0, 0.02)
	_show_wave_toast("熔毁爆发", Color(1.0, 0.42, 0.14))
	_spawn_radial_vfx(origin, radius, Color(1.0, 0.42, 0.12, 0.58))
	_spawn_attack_ring(origin, radius, Color(1.0, 0.42, 0.12, 0.34), 0.28)
	for enemy in $EnemyLayer.get_children():
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		var dist: float = enemy.global_position.distance_to(origin)
		if dist > radius:
			continue
		var falloff := 1.0 - clampf(dist / radius, 0.0, 1.0)
		enemy.take_damage(damage * (0.58 + falloff * 0.42), "fire")
		if enemy.has_method("amplify_character_status"):
			enemy.amplify_character_status("fire", damage, _growth_rank(character_level), _affinity_float("status_bonus"))
	return true

func _cast_frost_glacier() -> bool:
	var active: Dictionary = character_data.get("active_skill", {})
	sig_frost_glacier_timer = float(active.get("duration", 5.0))
	sig_frost_glacier_tick = 0.0
	AudioManager.play_sfx("muzzle_ice", -2.0, 0.02)
	_show_wave_toast("冰川领域", Color(0.55, 0.9, 1.0))
	_spawn_attack_ring(Vector2(540, 1180), 430.0, Color(0.5, 0.9, 1.0, 0.34), 0.34)
	_process_frost_glacier(0.0)
	return true

func _process_frost_glacier(delta: float) -> void:
	var active: Dictionary = character_data.get("active_skill", {})
	var field_y := float(active.get("field_y", 860.0))
	var tick_damage := _character_active_damage("ice", float(active.get("damage_mult", 0.34)))
	sig_frost_glacier_tick -= delta
	var should_tick := sig_frost_glacier_tick <= 0.0
	if should_tick:
		sig_frost_glacier_tick = 0.72
	for enemy in $EnemyLayer.get_children():
		if not is_instance_valid(enemy) or enemy.global_position.y < field_y:
			continue
		enemy.speed_mult *= 0.48 if not bool(enemy.boss) else 0.68
		if enemy.has_method("amplify_character_status"):
			enemy.amplify_character_status("ice", tick_damage, _growth_rank(character_level), _affinity_float("slow_bonus"))
		if should_tick and enemy.has_method("take_damage"):
			enemy.take_damage(tick_damage, "ice")
	if should_tick:
		_spawn_attack_ring(Vector2(540, 1190), 430.0, Color(0.55, 0.9, 1.0, 0.22), 0.18)

func _cast_volt_storm() -> bool:
	var active: Dictionary = character_data.get("active_skill", {})
	var max_targets := int(active.get("max_targets", 6))
	if _growth_rank(character_level) >= 3:
		max_targets += 1
	var damage := _character_active_damage("lightning", float(active.get("damage_mult", 2.1)))
	var targets := _active_target_candidates(max_targets)
	if targets.is_empty():
		return false
	AudioManager.play_sfx("muzzle_lightning", -2.0, 0.02)
	_show_wave_toast("雷暴领域", Color(1.0, 0.9, 0.2))
	var last_pos := turret.global_position + Vector2(0, -160)
	for target in targets:
		if target == null or not is_instance_valid(target):
			continue
		_spawn_chain_arc(last_pos, target.global_position, "lightning")
		_spawn_attack_sprite("res://assets/production/sprites/vfx/vfx_chain_lightning.png", target.global_position + Vector2(0, -52), Color(1.0, 0.9, 0.2, 0.86), 0.72, 0.18)
		target.take_damage(damage, "lightning")
		if target.has_method("amplify_character_status"):
			target.amplify_character_status("lightning", damage, _growth_rank(character_level), _affinity_float("status_bonus"))
		last_pos = target.global_position
	_show_screen_flash(Color(1.0, 0.9, 0.2, 0.1), 0.18)
	return true

func _best_active_target() -> Node2D:
	var targets := _active_target_candidates(1)
	if targets.is_empty():
		return null
	return targets[0]

func _active_target_candidates(max_count: int) -> Array[Node2D]:
	var candidates := []
	var origin := turret.global_position if turret != null else Vector2(540, 1660)
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

func _refresh_character_fire_rate_buff() -> void:
	if turret == null:
		return
	var next_mult := 1.0
	if sig_vanguard_barrage_timer > 0.0:
		next_mult *= 1.25 + 0.05 * float(_growth_rank(character_level))
	if sig_vanguard_overload_timer > 0.0:
		next_mult *= 1.5
	if absf(next_mult - character_fire_rate_mult) <= 0.001:
		return
	turret.fire_rate *= next_mult / maxf(character_fire_rate_mult, 0.001)
	character_fire_rate_mult = next_mult

func _update_character_skill_button() -> void:
	if not has_node("Hud/CharacterSkillButton"):
		return
	var button: TextureButton = $Hud/CharacterSkillButton
	button.visible = character_active_id != ""
	if character_active_id == "":
		return
	var info: Dictionary = CharacterSkillText.signature_info(character_active_id)
	var label: Label = $Hud/CharacterSkillButton/Label
	var fill: ColorRect = $Hud/CharacterSkillButton/CooldownFill
	var ready := character_active_cd <= 0.0 and not card_offer_active and not paused
	button.disabled = not ready
	button.modulate = Color(1, 1, 1, 1) if ready else Color(0.58, 0.64, 0.7, 0.9)
	if character_active_cd > 0.0:
		label.text = "%s\n%.0fs" % [str(info.get("name", "角色技能")), ceil(character_active_cd)]
	else:
		label.text = "%s\n可释放" % str(info.get("name", "角色技能"))
	var ratio := clampf(character_active_cd / maxf(character_active_cd_max, 0.1), 0.0, 1.0)
	fill.visible = ratio > 0.0
	fill.offset_top = lerpf(64.0, 8.0, ratio)

func _character_active_damage(element: String, mult: float) -> float:
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var damage := 28.0 * float(weapon.get("base_atk_coef", 1.0)) * float(turret.damage_mult) * mult
	damage *= _character_bullet_damage_multiplier(element)
	if element == primary_weakness:
		damage *= 1.15
	return damage

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
			breach_shields += 1
			if _growth_rank(character_level) >= 2:
				breach_shields += 1
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
	_update_strategy_label()

func _on_strategy_button_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	InputManager.cycle_strategy()

func _on_pause_pressed() -> void:
	if card_offer_active:
		return
	paused = not paused
	AudioManager.play_sfx("pause" if paused else "resume")
	$Hud/PauseOverlay.visible = paused
	if paused:
		_refresh_pause_build_summary()
	get_tree().paused = paused

func _refresh_pause_build_summary() -> void:
	if not has_node("Hud/PauseOverlay/BuildSummary"):
		return
	var label: Label = $Hud/PauseOverlay/BuildSummary
	var lines: Array[String] = []
	lines.append("关卡：%s（建议等级 %d）" % [str(level.get("name", level_id)), int(level.get("recommend_level", 1))])
	var element_label := _element_label(primary_weakness)
	lines.append("本关弱点：%s" % element_label)
	lines.append("角色：%s" % str(character_data.get("name", character_id)))
	lines.append("主炮：%s（Lv.%d）" % [str(DataLoader.get_row("weapons", weapon_id).get("name", weapon_id)), weapon_level])
	if character_active_id != "":
		var active_info: Dictionary = CharacterSkillText.signature_info(character_active_id)
		lines.append("角色主动：%s（冷却 %.0fs）" % [str(active_info.get("name", character_active_id)), character_active_cd_max])
	var affinity: Dictionary = _bullet_affinity()
	if not affinity.is_empty():
		lines.append("弹种加成：%s 弹" % _element_name(str(affinity.get("element", "physical"))))
	lines.append("护甲：%s  芯片：%s" % [str(armor_data.get("name", armor_id)), str(chip_data.get("name", chip_id))])
	if pet_id != "":
		lines.append("宝宝：%s" % str(pet_data.get("name", pet_id)))
	lines.append("")
	lines.append("已带技能：")
	for skill_id in skill_slot_ids:
		var row: Dictionary = DataLoader.get_row("skills", skill_id)
		var lv := skills.level(skill_id) if skills else 0
		lines.append("  • %s  Lv.%d" % [str(row.get("name", skill_id)), lv])
	if skill_slot_ids.is_empty():
		lines.append("  （暂无 — 局内首张三选一牌出现时自动填入）")
	lines.append("")
	lines.append("目标策略：%s" % _strategy_label(target_manager.strategy))
	label.text = "\n".join(lines)

func _strategy_label(strategy: String) -> String:
	match strategy:
		"breach": return "越线威胁"
		"elite": return "精英 / Boss"
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
	AudioManager.play_sfx("resume")
	paused = false
	$Hud/PauseOverlay.visible = false
	get_tree().paused = false

func _on_restart_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	paused = false
	$Hud/PauseOverlay.visible = false
	get_tree().paused = false
	router.start_level(level_id)

func _on_pause_to_map() -> void:
	AudioManager.play_sfx("ui_click")
	paused = false
	$Hud/PauseOverlay.visible = false
	get_tree().paused = false
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
		_show_wave_toast("Boss 来袭：%s" % boss_name, Color(1.0, 0.32, 0.22))
		_show_boss_banner(boss_name)
		pending_spawns.append({"type": boss_id, "interval": 1.0, "lane": "center", "boss": true})
		for support in wave.get("support", []):
			_queue_spawn_group(support, false)
	else:
		_show_wave_toast("第 %d 波尸潮" % wave_index, Color(1.0, 0.82, 0.25))
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
	enemy.setup(row, hp_level_coef, is_boss)
	enemy.hit_feedback.connect(_on_enemy_hit_feedback)
	enemy.damage_dealt.connect(_on_enemy_damage_dealt)
	enemy.died.connect(_on_enemy_died)
	enemy.breached.connect(_on_enemy_breached)
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
			"shield_aura", "ward":
				_apply_damage_reduction_aura(source, enemies)
			"summon":
				_process_summoner(source, delta)
			"ranged_spit":
				_process_ranged_pressure(source, delta)
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
	for enemy in enemies:
		if enemy == source or not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(source.global_position) <= radius:
			enemy.external_damage_mult *= 0.72

func _process_summoner(source: Node, delta: float) -> void:
	source.mechanic_timer -= delta
	if source.mechanic_timer > 0.0:
		return
	source.mechanic_timer = randf_range(4.2, 5.8)
	var spawn_position: Vector2 = source.global_position + Vector2(randf_range(-75, 75), randf_range(-35, 45))
	spawn_position.x = clampf(spawn_position.x, 120.0, 960.0)
	spawn_position.y = clampf(spawn_position.y, 190.0, 1220.0)
	_spawn_enemy_attack_vfx(source, "summon", spawn_position)
	_spawn_enemy_instance("zombie_shambler", spawn_position, false)
	AudioManager.play_sfx("threat_warning", -6.0)
	_spawn_float_text(source.global_position + Vector2(0, -86), "召唤", Color(0.72, 0.4, 1.0))

func _process_ranged_pressure(source: Node, delta: float) -> void:
	if source.global_position.y < 720.0:
		return
	source.mechanic_timer -= delta
	if source.mechanic_timer > 0.0:
		return
	source.mechanic_timer = randf_range(3.8, 5.0)
	var spit_damage := int(max(2.0, float(source.breach_damage) * 0.35))
	var target_position := Vector2(source.global_position.x, 1370)
	_spawn_attack_telegraph(target_position, Color(0.46, 1.0, 0.25, 0.34), "腐蚀")
	_spawn_spit_attack_vfx(source, target_position)
	base_hp = max(base_hp - spit_damage, 0)
	AudioManager.play_sfx("hit_poison", -4.0)
	_show_screen_flash(Color(0.36, 1.0, 0.22, 0.12), 0.16)
	_spawn_float_text(target_position, "-%d 腐蚀" % spit_damage, Color(0.56, 1.0, 0.32))
	_check_low_hp_warning()
	if base_hp <= 0:
		_finish(false)

func _process_boss_pressure(source: Node, delta: float, interval: float, damage_scale: float, label: String, color: Color) -> void:
	if source.global_position.y < 560.0:
		return
	source.mechanic_timer -= delta
	if source.mechanic_timer > 0.0:
		return
	source.mechanic_timer = randf_range(interval, interval + 1.4)
	if source.has_method("play_special"):
		source.play_special()
	var pressure_damage := int(max(3.0, float(source.breach_damage) * damage_scale))
	_spawn_attack_telegraph(Vector2(source.global_position.x, 1360), Color(color.r, color.g, color.b, 0.34), label)
	_spawn_boss_attack_vfx(source, label, color)
	base_hp = max(base_hp - pressure_damage, 0)
	AudioManager.play_sfx("threat_warning", -5.0)
	_show_screen_flash(Color(color.r, color.g, color.b, 0.12), 0.16)
	_spawn_float_text(Vector2(source.global_position.x, 1360), "-%d %s" % [pressure_damage, label], color)
	_check_low_hp_warning()
	if base_hp <= 0:
		_finish(false)

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
	var frost_damage := int(max(2.0, float(source.breach_damage) * 0.24))
	base_hp = max(base_hp - frost_damage, 0)
	AudioManager.play_sfx("hit_ice", -4.0)
	_show_screen_flash(Color(0.42, 0.86, 1.0, 0.12), 0.16)
	_spawn_float_text(Vector2(source.global_position.x, 1360), "-%d 寒潮" % frost_damage, Color(0.45, 0.86, 1.0))
	_check_low_hp_warning()
	if base_hp <= 0:
		_finish(false)

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
	_show_wave_toast("Boss %s" % text, color)
	_spawn_float_text(source.global_position + Vector2(0, -180), text, color)
	_spawn_attack_ring(source.global_position + Vector2(0, -40), 230.0, Color(color.r, color.g, color.b, 0.28), 0.32)
	_show_screen_flash(Color(color.r, color.g, color.b, 0.14), 0.22)

func _on_turret_fired(origin: Vector2, direction: Vector2) -> void:
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
	homing += _character_homing_bonus(element)
	AudioManager.play_sfx(_weapon_shot_sfx(weapon_id), -7.0)
	if element != "physical":
		AudioManager.play_sfx(_element_muzzle_sfx(element), -10.0, 0.025)
	if element == primary_weakness and randf() < 0.08:
		_spawn_float_text(origin + Vector2(-120, -80), "弱点装填", Color(1.0, 0.86, 0.32))
	if weapon_level >= 15 and randf() < 0.08:
		_spawn_weapon_power_ring(origin, element)
	_spawn_muzzle_flash(origin, direction, element)
	_play_character_attack()
	var base_damage: float = 28.0 * float(weapon.get("base_atk_coef", 1.0))
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
			damage *= 1.85
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
			visual_scale
		)
	if shots >= 3:
		_spawn_salvo_fan_vfx(origin, direction, spread, shots, element)

func _spawn_projectile(origin: Vector2, direction: Vector2, damage: float, pierce: int, split: int, split_falloff: float, homing := 0.0, splash := 0.0, cloud := 0.0, visual_scale := 1.0) -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var element := skills.projectile_element(str(weapon.get("element", "physical")))
	projectile.setup(origin, direction, float(weapon.get("projectile_speed", 1450.0)), damage, element, pierce, split, split_falloff, homing, splash, cloud, visual_scale)
	projectile.split_requested.connect(_on_projectile_split_requested)
	projectile.hit_confirmed.connect(_on_projectile_hit_confirmed)
	$ProjectileLayer.add_child(projectile)
	if homing > 0.0:
		_spawn_homing_line_vfx(origin, direction, element)

func _primary_shot_directions(origin: Vector2, base_direction: Vector2, shots: int, spread: float) -> Array[Vector2]:
	var directions: Array[Vector2] = []
	if shots <= 1:
		directions.append(base_direction.normalized())
		return directions
	var candidates := _multi_shot_target_candidates(origin, base_direction)
	for candidate in candidates:
		if directions.size() >= shots:
			break
		var enemy := candidate.get("enemy") as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		var target_direction := (enemy.global_position - origin).normalized()
		if target_direction.length_squared() <= 0.0:
			continue
		directions.append(target_direction)
	while directions.size() < shots:
		var index := directions.size()
		var offset: float = lerpf(-spread, spread, 0.5 if shots == 1 else float(index) / float(shots - 1))
		directions.append(base_direction.rotated(offset).normalized())
	directions.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return wrapf(a.angle() - base_direction.angle(), -PI, PI) < wrapf(b.angle() - base_direction.angle(), -PI, PI)
	)
	return directions

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
		var score := target_manager.score_enemy(enemy.targeting_snapshot(), turret.global_position)
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
	pet_sprite.texture = load(pet_data.get("sprite", pet_data.get("icon", "")))
	pet_sprite.position = Vector2(725, 1625)
	pet_sprite.scale = Vector2(0.26, 0.26) * _visual_level_scale(pet_level)
	pet_sprite.modulate = _level_tint(pet_level)
	add_child(pet_sprite)
	_load_pet_animation_frames(str(pet_data.get("sprite", "")))
	_attach_growth_badge(pet_sprite, pet_level, Vector2(-88, -152))
	_spawn_pet_aura()
	if pet_data.get("role", "") == "repair":
		_spawn_float_text(pet_sprite.global_position + Vector2(0, -80), "维修宠物待命", Color(0.35, 1.0, 0.68))

func _spawn_character() -> void:
	character_sprite = Sprite2D.new()
	character_sprite.name = "Character"
	character_sprite.position = Vector2(350, 1640)
	character_sprite.scale = Vector2(0.26, 0.26) * _visual_level_scale(character_level)
	character_sprite.modulate = _level_tint(character_level)
	add_child(character_sprite)
	_load_character_animation_frames()
	if not character_idle_frames.is_empty():
		character_sprite.texture = character_idle_frames[0]
	else:
		character_sprite.texture = load(character_data.get("portrait", ""))
	_attach_growth_badge(character_sprite, character_level, Vector2(-98, -190))
	_spawn_levelup_vfx(character_sprite.global_position, _level_tint(character_level), 0.55)
	_spawn_character_aura()

func _load_character_animation_frames() -> void:
	var asset_id := _character_asset_id()
	var base := "res://assets/production/sprites/animations/characters/%s/%s" % [asset_id, asset_id]
	character_idle_frames = _load_frame_set(base, "idle", 4)
	character_attack_frames = _load_frame_set(base, "attack", 4)
	character_hurt_frames = _load_frame_set(base, "hurt", 3)

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
	if character_sprite == null:
		return
	var frames := character_idle_frames
	var fps := 7.0
	if character_hurt_time > 0.0:
		frames = character_hurt_frames
		fps = 16.0
		character_hurt_time -= delta
	elif character_attack_time > 0.0:
		frames = character_attack_frames
		fps = 14.0
		character_attack_time -= delta
	if frames.is_empty():
		return
	character_anim_time += delta
	var next_frame := int(character_anim_time * fps)
	if character_hurt_time > 0.0 or character_attack_time > 0.0:
		next_frame = mini(next_frame, frames.size() - 1)
	else:
		next_frame = next_frame % frames.size()
	if next_frame != character_anim_frame:
		character_anim_frame = next_frame
		character_sprite.texture = frames[character_anim_frame]
	character_sprite.position.y = 1640.0 - absf(sin(Time.get_ticks_msec() / 350.0)) * 5.0
	_update_character_aura(delta)

func _play_character_attack() -> void:
	character_attack_time = 0.24
	character_anim_time = 0.0
	character_anim_frame = 0

func _play_character_hurt() -> void:
	character_hurt_time = 0.28
	character_anim_time = 0.0
	character_anim_frame = 0
	if character_sprite:
		_spawn_levelup_vfx(character_sprite.global_position, Color(1.0, 0.25, 0.2), 0.36)

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
		if ResourceLoader.exists(path):
			var tex := load(path) as Texture2D
			if tex:
				frames.append(tex)
	return frames

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

func _spawn_muzzle_flash(origin: Vector2, direction: Vector2, element := "physical") -> void:
	var tex := load(_vfx_path("muzzle", element)) as Texture2D
	if tex == null:
		return
	var flash := Sprite2D.new()
	flash.texture = tex
	flash.global_position = origin
	flash.rotation = direction.angle() + PI / 4.0
	flash.scale = Vector2(0.28, 0.28)
	flash.modulate = Color(1, 1, 1, 0.9)
	$ProjectileLayer.add_child(flash)
	var tween := flash.create_tween()
	tween.parallel().tween_property(flash, "scale", Vector2(0.48, 0.48), 0.08)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.08)
	tween.tween_callback(flash.queue_free)

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
	var color := _element_color(element)
	color.a = 0.42
	for i in range(mini(shots, 6)):
		var offset: float = 0.0 if shots == 1 else lerpf(-spread, spread, float(i) / float(shots - 1))
		_spawn_short_muzzle_spark(origin, direction.rotated(offset), element, color, 0.18)

func _spawn_homing_line_vfx(origin: Vector2, direction: Vector2, element: String) -> void:
	var color := _element_color(element)
	color.a = 0.36
	_spawn_short_muzzle_spark(origin, direction, element, color, 0.2)

func _spawn_weapon_power_ring(origin: Vector2, element: String) -> void:
	var color := _element_color(element)
	color.a = 0.34
	_spawn_attack_ring(origin, 78.0 + float(_growth_rank(weapon_level)) * 22.0, color, 0.16)

func _spawn_crit_shot_vfx(origin: Vector2, direction: Vector2, element: String) -> void:
	var color := _element_color(element)
	color.a = 0.62
	_spawn_short_muzzle_spark(origin, direction, element, color, 0.24, "res://assets/production/sprites/vfx/vfx_crit.png")

func _spawn_short_muzzle_spark(origin: Vector2, direction: Vector2, element: String, color: Color, scale_mult := 0.18, texture_path := "") -> void:
	var path := texture_path if texture_path != "" else _vfx_path("muzzle", element)
	var tex := load(path) as Texture2D
	if tex == null:
		return
	var spark := Sprite2D.new()
	spark.texture = tex
	spark.global_position = origin + direction.normalized() * 28.0
	spark.rotation = direction.angle()
	spark.scale = Vector2(scale_mult, scale_mult)
	spark.modulate = color
	$ProjectileLayer.add_child(spark)
	var tween := spark.create_tween()
	tween.parallel().tween_property(spark, "global_position", spark.global_position + direction.normalized() * 18.0, 0.08)
	tween.parallel().tween_property(spark, "scale", spark.scale * 0.68, 0.08)
	tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.08)
	tween.tween_callback(spark.queue_free)

func _spawn_levelup_vfx(origin: Vector2, color: Color, duration := 0.75) -> void:
	var tex := load("res://assets/production/sprites/vfx/vfx_levelup_glow.png") as Texture2D
	if tex == null:
		return
	var glow := Sprite2D.new()
	glow.texture = tex
	glow.global_position = origin
	glow.scale = Vector2(0.36, 0.36)
	glow.modulate = color
	$ProjectileLayer.add_child(glow)
	var tween := glow.create_tween()
	tween.parallel().tween_property(glow, "scale", Vector2(0.76, 0.76), duration)
	tween.parallel().tween_property(glow, "modulate:a", 0.0, duration)
	tween.tween_callback(glow.queue_free)

func _spawn_character_aura() -> void:
	if character_sprite == null:
		return
	character_aura = Sprite2D.new()
	character_aura.name = "CharacterAura"
	character_aura.texture = load("res://assets/production/sprites/vfx/vfx_levelup_glow.png")
	character_aura.position = Vector2(0, -28)
	character_aura.scale = Vector2(0.42, 0.42) * (1.0 + 0.08 * float(_growth_rank(character_level)))
	character_aura.z_index = -1
	var color := _element_color(str(character_data.get("element_focus", "physical")))
	color.a = 0.18 + 0.06 * float(_growth_rank(character_level))
	character_aura.modulate = color
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
	pet_aura = Sprite2D.new()
	pet_aura.name = "PetAura"
	pet_aura.texture = load("res://assets/production/sprites/vfx/vfx_levelup_glow.png")
	pet_aura.position = Vector2(0, -20)
	pet_aura.scale = Vector2(0.28, 0.28) * (1.0 + 0.06 * float(_growth_rank(pet_level)))
	pet_aura.z_index = -1
	var color := _element_color(str(pet_data.get("element", "physical")))
	color.a = 0.16 + 0.04 * float(_growth_rank(pet_level))
	pet_aura.modulate = color
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
	var text := "%s Lv.%d  ·  %s Lv.%d" % [character_name, character_level, weapon_name, weapon_level]
	if not pet_data.is_empty():
		text += "  ·  宠物 Lv.%d" % pet_level
	_show_wave_toast(text, Color(0.78, 0.94, 1.0))
	_spawn_loadout_badge(Vector2(350, 1510), "角色", character_level, _element_color(str(character_data.get("element_focus", "physical"))))
	_spawn_loadout_badge(Vector2(540, 1510), "主炮", weapon_level, _element_color(str(DataLoader.get_row("weapons", weapon_id).get("element", "physical"))))
	if not pet_data.is_empty():
		_spawn_loadout_badge(Vector2(730, 1510), "宠物", pet_level, _element_color(str(pet_data.get("element", "physical"))))

func _spawn_loadout_badge(origin: Vector2, label_text: String, level: int, color: Color) -> void:
	var badge := Label.new()
	badge.text = "%s\nLv.%d" % [label_text, level]
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
	var label := Label.new()
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

func _spawn_reward_flyouts(origin: Vector2, reward_gold: int, reward_xp: int) -> void:
	if reward_gold > 0:
		_spawn_reward_chip(origin + Vector2(-18, -30), "金", Color(1.0, 0.86, 0.22, 1.0), _reward_target_position("gold"), "gold")
	if reward_xp > 0:
		_spawn_reward_chip(origin + Vector2(22, -30), "XP", Color(0.45, 0.86, 1.0, 1.0), _reward_target_position("xp"), "xp")

func _reward_target_position(kind: String) -> Vector2:
	match kind:
		"gold":
			if has_node("Hud/BottomBar/GoldLabel"):
				return $Hud/BottomBar/GoldLabel.global_position + Vector2(28, 20)
		"xp":
			if has_node("Hud/BottomBar/XpBar"):
				return $Hud/BottomBar/XpBar.global_position + Vector2(360, 20)
	return Vector2(540, 1700)

func _spawn_reward_chip(origin: Vector2, text: String, color: Color, target: Vector2, kind: String) -> void:
	var chip := Label.new()
	chip.text = text
	chip.position = origin
	chip.size = Vector2(42, 28)
	chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_theme_font_size_override("font_size", 15)
	chip.add_theme_color_override("font_color", color)
	chip.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	chip.add_theme_constant_override("outline_size", 3)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Hud.add_child(chip)
	var arc := origin + Vector2(randf_range(-30.0, 30.0), -62.0)
	var tween := chip.create_tween()
	tween.tween_property(chip, "position", arc, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(chip, "scale", Vector2(1.08, 1.08), 0.12)
	tween.tween_property(chip, "position", target, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(chip, "scale", Vector2(0.42, 0.42), 0.26)
	tween.parallel().tween_property(chip, "modulate:a", 0.0, 0.26)
	tween.tween_callback(func() -> void:
		_pulse_reward_target(kind)
		chip.queue_free()
	)

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
	var banner := ColorRect.new()
	banner.color = Color(0.38, 0.02, 0.0, 0.78)
	banner.position = Vector2(-1080, 520)
	banner.size = Vector2(1080, 106)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Hud.add_child(banner)
	var label := Label.new()
	label.text = "BOSS  %s" % boss_name
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
	var glow := Sprite2D.new()
	glow.name = "GrowthGlow"
	glow.texture = load("res://assets/production/sprites/vfx/vfx_levelup_glow.png")
	glow.position = Vector2(0, -36)
	glow.scale = Vector2(0.28, 0.28)
	var glow_color := _level_tint(level)
	glow_color.a = 0.32
	glow.modulate = glow_color
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
	var target_directions := _split_target_directions(origin, direction, count, fan)
	for i in range(count):
		var projectile := PROJECTILE_SCENE.instantiate()
		var split_direction: Vector2 = target_directions[i]
		projectile.setup(origin + split_direction * 18.0, split_direction, 1320.0, damage, element, 0, 0, 0.55, 2.2, 0.0, 0.0, 0.58, 0, "res://assets/production/sprites/projectiles/proj_split_mini.png")
		projectile.hit_confirmed.connect(_on_projectile_hit_confirmed)
		$ProjectileLayer.call_deferred("add_child", projectile)

func _on_projectile_hit_confirmed(primary: Node, origin: Vector2, damage: float, element: String, splash_radius: float, cloud_radius: float, chain_depth: int) -> void:
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
		_spawn_chain_arc(origin, target.global_position, element)
		var projectile := PROJECTILE_SCENE.instantiate()
		var chain_element := "lightning" if element == "physical" else element
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

func _spawn_split_burst_vfx(origin: Vector2, direction: Vector2, fan: float, count: int, element: String) -> void:
	var color := _element_color(element)
	color.a = 0.55
	var tex := load("res://assets/production/sprites/vfx/vfx_crit.png") as Texture2D
	for i in range(mini(count, 7)):
		var offset := lerpf(-fan, fan, 0.5 if count == 1 else float(i) / float(count - 1))
		var shard := Sprite2D.new()
		shard.texture = tex
		shard.global_position = origin
		shard.rotation = direction.rotated(offset).angle()
		shard.scale = Vector2(0.18, 0.18)
		shard.modulate = color
		$ProjectileLayer.add_child(shard)
		var travel := direction.rotated(offset).normalized() * 72.0
		var tween := shard.create_tween()
		tween.parallel().tween_property(shard, "global_position", origin + travel, 0.13)
		tween.parallel().tween_property(shard, "scale", Vector2(0.36, 0.36), 0.13)
		tween.parallel().tween_property(shard, "modulate:a", 0.0, 0.13)
		tween.tween_callback(shard.queue_free)

func _spawn_chain_flash(origin: Vector2, primary: Node) -> void:
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

func _spawn_chain_arc(start: Vector2, end: Vector2, element := "lightning") -> void:
	var tex := load("res://assets/production/sprites/vfx/vfx_chain_lightning.png") as Texture2D
	if tex == null:
		return
	var color := _element_color(element)
	color.a = 0.78
	var bolt := Sprite2D.new()
	bolt.texture = tex
	bolt.global_position = (start + end) * 0.5
	var length := start.distance_to(end)
	bolt.rotation = (end - start).angle()
	bolt.scale = Vector2(maxf(length / 256.0, 0.45), 0.42)
	bolt.modulate = color
	$ProjectileLayer.add_child(bolt)
	var tween := bolt.create_tween()
	tween.parallel().tween_property(bolt, "scale:y", 0.1, 0.12)
	tween.parallel().tween_property(bolt, "modulate:a", 0.0, 0.12)
	tween.tween_callback(bolt.queue_free)

func _spawn_radial_vfx(origin: Vector2, radius: float, color: Color) -> void:
	var tex_path := "res://assets/production/sprites/vfx/vfx_explosion_fire.png" if color.r >= color.g else "res://assets/production/sprites/vfx/vfx_poison_cloud.png"
	var tex := load(tex_path) as Texture2D
	if tex:
		var burst := Sprite2D.new()
		burst.texture = tex
		burst.global_position = origin
		burst.scale = Vector2(radius / 220.0, radius / 220.0)
		burst.modulate = Color(color.r, color.g, color.b, 0.42)
		$ProjectileLayer.add_child(burst)
		var burst_tween := burst.create_tween()
		burst_tween.parallel().tween_property(burst, "scale", burst.scale * 1.18, 0.22)
		burst_tween.parallel().tween_property(burst, "modulate:a", 0.0, 0.22)
		burst_tween.tween_callback(burst.queue_free)

func _spawn_hit_layer_vfx(position: Vector2, element: String, weak_hit: bool, hit_kind: String) -> void:
	var color := _element_color(element)
	var path := _vfx_path("hit", element)
	var scale := 0.42
	match hit_kind:
		"armor":
			path = "res://assets/production/sprites/vfx/vfx_crit.png"
			color = Color(1.0, 0.82, 0.42, 0.86)
			scale = 0.52
		"shield":
			path = "res://assets/production/sprites/vfx/vfx_hit_immune.png"
			color = Color(0.48, 0.82, 1.0, 0.82)
			scale = 0.6
		"immune", "phase_evade":
			path = "res://assets/production/sprites/vfx/vfx_hit_immune.png"
			color = Color(0.78, 0.86, 1.0, 0.75)
			scale = 0.5
		"weak":
			path = "res://assets/production/sprites/vfx/vfx_crit.png"
			color = Color(1.0, 0.9, 0.24, 0.95)
			scale = 0.7
	_spawn_attack_sprite(path, position + Vector2(randf_range(-18.0, 18.0), randf_range(-45.0, -12.0)), color, scale, 0.18)
	if weak_hit:
		_spawn_attack_ring(position + Vector2(0, -40), 72.0, Color(1.0, 0.86, 0.24, 0.42), 0.14)
	if hit_kind == "armor" or hit_kind == "shield" or hit_kind == "immune":
		_spawn_attack_ring(position + Vector2(0, -34), 58.0, color, 0.16)

func _spawn_death_element_vfx(position: Vector2, element: String, is_boss: bool) -> void:
	var scale := 0.95 if not is_boss else 1.85
	match element:
		"fire":
			_spawn_attack_sprite("res://assets/production/sprites/vfx/vfx_explosion_fire.png", position + Vector2(0, -36), Color(1.0, 0.4, 0.12, 0.78), scale, 0.36)
			_spawn_attack_ring(position, 120.0 * scale, Color(1.0, 0.42, 0.12, 0.24), 0.32)
		"ice":
			_spawn_attack_sprite("res://assets/production/sprites/vfx/vfx_freeze.png", position + Vector2(0, -40), Color(0.58, 0.9, 1.0, 0.82), scale, 0.34)
			_spawn_death_shards(position, Color(0.64, 0.92, 1.0, 0.8), is_boss)
		"lightning":
			_spawn_attack_sprite("res://assets/production/sprites/vfx/vfx_chain_lightning.png", position + Vector2(0, -46), Color(1.0, 0.92, 0.22, 0.86), scale, 0.28)
			_spawn_death_shards(position, Color(1.0, 0.92, 0.22, 0.78), is_boss)
		"poison":
			_spawn_attack_sprite("res://assets/production/sprites/vfx/vfx_poison_cloud.png", position + Vector2(0, -24), Color(0.44, 1.0, 0.25, 0.72), scale, 0.46)
			_spawn_attack_ring(position, 100.0 * scale, Color(0.42, 1.0, 0.25, 0.2), 0.36)
		_:
			_spawn_attack_sprite("res://assets/production/sprites/vfx/vfx_death_dissolve.png", position + Vector2(0, -36), Color(1.0, 0.92, 0.74, 0.72), scale, 0.3)
			_spawn_death_shards(position, Color(1.0, 0.86, 0.58, 0.62), is_boss)
	if is_boss:
		_show_screen_flash(Color(1.0, 0.78, 0.28, 0.16), 0.32)

func _spawn_death_shards(position: Vector2, color: Color, is_boss: bool) -> void:
	var count := 8 if not is_boss else 18
	for i in range(count):
		var shard := ColorRect.new()
		shard.color = color
		shard.size = Vector2(8, 18) if not is_boss else Vector2(12, 28)
		shard.global_position = position + Vector2(randf_range(-18.0, 18.0), randf_range(-52.0, -16.0))
		shard.rotation = randf_range(-1.0, 1.0)
		shard.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$Hud.add_child(shard)
		var travel := Vector2(randf_range(-85.0, 85.0), randf_range(-120.0, -35.0)) * (1.35 if is_boss else 1.0)
		var tween := shard.create_tween()
		tween.parallel().tween_property(shard, "global_position", shard.global_position + travel, 0.26)
		tween.parallel().tween_property(shard, "rotation", shard.rotation + randf_range(-1.2, 1.2), 0.26)
		tween.parallel().tween_property(shard, "modulate:a", 0.0, 0.26)
		tween.tween_callback(shard.queue_free)

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
		var edge := ColorRect.new()
		edge.name = str(spec.get("name", "Edge"))
		edge.position = spec.get("pos", Vector2.ZERO)
		edge.size = spec.get("size", Vector2.ZERO)
		edge.color = Color(1.0, 0.04, 0.0, 0.0)
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		low_hp_pulse.add_child(edge)

func _spawn_feedback_managers() -> void:
	# Hit stop / hit pause
	hit_stop = preload("res://core/feedback/hit_stop.gd").new()
	hit_stop.name = "HitStop"
	add_child(hit_stop)
	# Screen shake
	screen_shake_node = preload("res://core/feedback/screen_shake.gd").new()
	screen_shake_node.name = "ScreenShake"
	add_child(screen_shake_node)
	screen_shake_node.bind(self)
	# Damage number layer
	damage_numbers = preload("res://gameplay/hud/damage_number_layer.gd").new()
	damage_numbers.name = "DamageNumbers"
	$ProjectileLayer.add_child(damage_numbers)
	# Off-screen indicators
	off_screen_indicators = preload("res://gameplay/hud/off_screen_indicator.gd").new()
	off_screen_indicators.name = "OffScreenIndicators"
	add_child(off_screen_indicators)
	# Gold fly
	gold_fly = preload("res://gameplay/hud/gold_fly.gd").new()
	gold_fly.name = "GoldFly"
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
		if child is ColorRect:
			var edge := child as ColorRect
			edge.color.a = clampf(alpha, 0.0, 0.07)

func _spawn_spit_attack_vfx(source: Node, target_position: Vector2) -> void:
	if not is_instance_valid(source):
		return
	var spit := Sprite2D.new()
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

func _spawn_boss_attack_vfx(source: Node, label: String, color: Color) -> void:
	if not is_instance_valid(source):
		return
	var path := "res://assets/production/sprites/vfx/vfx_boss_phase.png"
	if label.contains("熔火"):
		path = "res://assets/production/sprites/vfx/vfx_explosion_fire.png"
	elif label.contains("寒潮"):
		path = "res://assets/production/sprites/vfx/vfx_freeze.png"
	elif label.contains("雷暴"):
		path = "res://assets/production/sprites/vfx/vfx_chain_lightning.png"
	elif label.contains("腐化"):
		path = "res://assets/production/sprites/vfx/vfx_poison_cloud.png"
	_spawn_attack_sprite(path, source.global_position + Vector2(0, -80), Color(color.r, color.g, color.b, 0.72), 1.05 if not bool(source.boss) else 1.45, 0.42)
	_spawn_attack_ring(Vector2(source.global_position.x, 1360), 210.0 if not bool(source.boss) else 310.0, color, 0.32)

func _spawn_enemy_attack_vfx(source: Node, kind: String, target_position: Vector2) -> void:
	if not is_instance_valid(source):
		return
	var color := _attack_color_for_mechanic(kind)
	var path := _attack_vfx_path(kind)
	_spawn_attack_sprite(path, target_position, color, 0.66 if not bool(source.boss) else 1.12, 0.32)
	match kind:
		"summon", "spawn_minions":
			_spawn_attack_ring(target_position, 72.0, color, 0.22)
		"phase", "phase_shift":
			_spawn_attack_ring(target_position, 115.0, color, 0.2)
		"explode_on_death":
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
		"runner", "charge", "leap", "low_profile", "fast_claw":
			return "res://assets/production/sprites/vfx/vfx_threat_warning.png"
		"tank", "armor", "armor_break", "juggernaut", "shield_aura", "ward", "heavy_slam":
			return "res://assets/production/sprites/vfx/vfx_crit.png"
		"explode_on_death", "phase_burn", "blast":
			return "res://assets/production/sprites/vfx/vfx_explosion_fire.png"
		"ranged_spit", "toxic_cloud", "regenerate", "spawn_minions", "corrosion":
			return "res://assets/production/sprites/vfx/vfx_poison_cloud.png"
		"support_strike":
			return "res://assets/production/sprites/vfx/vfx_boss_phase.png"
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
		"runner", "charge", "leap", "low_profile", "fast_claw":
			return Color(1.0, 0.88, 0.24, 0.78)
		"tank", "armor", "armor_break", "juggernaut", "shield_aura", "ward", "heavy_slam":
			return Color(0.92, 0.72, 0.46, 0.82)
		"explode_on_death", "phase_burn", "blast":
			return Color(1.0, 0.42, 0.12, 0.78)
		"ranged_spit", "toxic_cloud", "regenerate", "spawn_minions", "corrosion":
			return Color(0.46, 1.0, 0.25, 0.76)
		"support_strike":
			return Color(0.74, 0.45, 1.0, 0.72)
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
		"runner", "charge", "leap", "low_profile", "fast_claw":
			return 0.86
		"corrosion":
			return 0.92
		"support_strike":
			return 0.78
		_:
			return 1.0

func _spawn_attack_sprite(path: String, position: Vector2, color: Color, scale_mult: float, duration: float) -> void:
	var tex := load(path) as Texture2D
	if tex == null:
		return
	var fx := Sprite2D.new()
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
	var ring := Sprite2D.new()
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
	if is_instance_valid(enemy):
		enemy.set_meta("death_element", str(reward.get("death_element", "physical")))
	_resolve_death_mechanic(enemy)
	_process_kill_feedback(enemy, reward)
	# Stage 1 P0 — combat feel
	_register_kill_for_combo(bool(reward.get("boss", false)))
	_trigger_kill_screen_shake(bool(reward.get("boss", false)))
	_trigger_kill_hit_stop(bool(reward.get("boss", false)))
	var reward_gold := int(round(float(reward.get("gold", 0)) * float(level.get("reward_gold_mult", 1.0)) * gold_mult * skills.gold_multiplier()))
	var reward_xp := int(reward.get("xp", 0))
	if is_instance_valid(enemy):
		_spawn_reward_flyouts(enemy.global_position, reward_gold, reward_xp)
		# New: gold coin flies to HUD instead of (or with) the small chip
		if reward_gold > 0 and gold_fly:
			gold_fly.fly_to_hud(enemy.global_position + Vector2(0, -20), reward_gold)
	gold += reward_gold
	xp += reward_xp
	if reward_gold > 0:
		var now := Time.get_ticks_msec() / 1000.0
		if now - last_gold_sfx_at >= 0.18:
			last_gold_sfx_at = now
			AudioManager.play_sfx("gold_pickup", -8.0)
	if enemy == target_manager.locked_enemy:
		target_manager.clear_lock()
	if xp >= next_xp_offer and not card_offer_active:
		_show_card_offer()

func _on_enemy_damage_dealt(enemy: Node, amount: float, element: String, crit_hit: bool, weak_hit: bool) -> void:
	if damage_numbers and is_instance_valid(enemy):
		damage_numbers.spawn_damage(enemy.global_position + Vector2(0, -34 if not bool(enemy.boss) else -76), amount, element, crit_hit, weak_hit)
	# crit-only screen shake (light) and hit stop (very short)
	if crit_hit:
		if screen_shake_node:
			screen_shake_node.shake(6.0, 0.08)
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
			milestone.text = "BOSS 击破！"
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
		screen_shake_node.shake(18.0, 0.36)
	elif kill_streak >= 8:
		screen_shake_node.shake(7.0, 0.14)
	elif kill_streak >= 4:
		screen_shake_node.shake(4.0, 0.10)

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
		_spawn_float_text(enemy.global_position + Vector2(0, -138), "BOSS 击破", Color(1.0, 0.35, 0.16))
		_show_screen_flash(Color(1.0, 0.62, 0.18, 0.18), 0.24)
		AudioManager.play_sfx("level_up", -1.0, 0.01)
		return
	if bool(reward.get("weak_kill", false)):
		_spawn_float_text(enemy.global_position + Vector2(0, -108), "弱点击破", Color(1.0, 0.86, 0.22))
		AudioManager.play_sfx("hit_immune", -7.0, 0.02)
	if kill_streak >= 5:
		_show_wave_toast("%d 连斩" % kill_streak, Color(1.0, 0.72, 0.24))
		if kill_streak % 5 == 0:
			AudioManager.play_sfx("level_up", -6.0, 0.02)

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
		var base_damage := int(max(2.0, float(enemy.breach_damage) * damage_scale))
		base_hp = max(base_hp - base_damage, 0)
		_spawn_float_text(enemy.global_position + Vector2(0, -80), "-%d 爆裂" % base_damage, color)
		if base_hp <= 0:
			_finish(false)

func _on_enemy_breached(enemy: Node, damage: int) -> void:
	AudioManager.play_sfx("enemy_breach", -4.0)
	_play_character_hurt()
	_shake_hud(5.0, 0.1)
	var final_damage := int(ceil(float(damage) * breach_damage_mult))
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

func _check_victory() -> void:
	if active_spawning or not pending_spawns.is_empty() or $EnemyLayer.get_child_count() > 0:
		return
	var waves: Array = level.get("waves", [])
	if wave_index < waves.size():
		_start_next_wave()
	else:
		_finish(true)

func _finish(victory: bool) -> void:
	set_physics_process(false)
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
	var hp_fill := $Hud/TopBar/BaseHpBar/Fill
	hp_fill.offset_right = lerpf(4.0, HUD_HP_FILL_RIGHT, hp_pct)
	$Hud/TopBar/BaseHpBar/Label.text = "HP %d/%d" % [base_hp, base_hp_max]
	_update_low_hp_pulse(hp_pct)
	var wave_pct := float(wave_index) / float(wave_total) if wave_total > 0 else 0.0
	displayed_wave_pct = lerpf(displayed_wave_pct, wave_pct, 0.22)
	$Hud/TopBar/WaveProgress/Fill.offset_right = lerpf(4.0, HUD_WAVE_FILL_RIGHT, displayed_wave_pct)
	$Hud/TopBar/WaveProgress/Label.text = "Wave %d/%d" % [wave_index, wave_total]
	var xp_pct := float(xp) / float(next_xp_offer) if next_xp_offer > 0 else 0.0
	displayed_xp_pct = lerpf(displayed_xp_pct, clamp(xp_pct, 0.0, 1.0), 0.28)
	$Hud/BottomBar/XpBar/Fill.offset_right = lerpf(4.0, HUD_XP_FILL_RIGHT, displayed_xp_pct)
	$Hud/BottomBar/XpBar/Label.text = "XP %d/%d" % [xp, next_xp_offer]
	$Hud/BottomBar/GoldLabel.text = "%d" % gold
	_update_skill_slots()
	_update_character_skill_button()
	_update_barrier_visual()
	_update_strategy_label()
	if debug_overlay_on:
		$Hud/DebugOverlay.text = _build_debug_text()

func _build_skill_slots() -> void:
	for child in $Hud/SkillSlots.get_children():
		child.queue_free()
	skill_slot_ids = _current_skill_slot_ids()
	$Hud/SkillSlots.visible = not skill_slot_ids.is_empty()
	# Dynamic icon size: shrink as the player collects more skills so they
	# all fit without overflowing the bottom bar.
	var count := skill_slot_ids.size()
	var slot_size: int = int(clampf(520.0 / maxf(float(count), 1.0) - 4.0, 26.0, 52.0))
	var icon_size: int = slot_size - 8
	var icon_offset: int = (slot_size - icon_size) / 2
	var label_offset_y: int = slot_size - 18
	var font_size: int = 12 if slot_size >= 40 else 10
	for skill_id in skill_slot_ids:
		var row := DataLoader.get_row("skills", skill_id)
		var slot := Panel.new()
		slot.name = skill_id
		slot.custom_minimum_size = Vector2(slot_size, slot_size)
		slot.clip_contents = true
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.texture = load(row.get("icon", ""))
		icon.position = Vector2(icon_offset, icon_offset)
		icon.size = Vector2(icon_size, icon_size)
		icon.custom_minimum_size = Vector2(icon_size, icon_size)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)
		icon.set_deferred("position", Vector2(icon_offset, icon_offset))
		icon.set_deferred("size", Vector2(icon_size, icon_size))
		var label := Label.new()
		label.name = "Level"
		label.position = Vector2(slot_size - 16, label_offset_y)
		label.size = Vector2(16, 16)
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3, 1.0))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		label.add_theme_constant_override("outline_size", 2)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(label)
		$Hud/SkillSlots.add_child(slot)
	_update_skill_slots()

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
	$Hud/SkillSlots.visible = not skill_slot_ids.is_empty()
	for skill_id in skill_slot_ids:
		var slot := $Hud/SkillSlots.get_node_or_null(skill_id)
		if slot == null:
			continue
		var lv := skills.level(skill_id)
		slot.modulate = Color(1, 1, 1, 1) if lv > 0 else Color(0.42, 0.42, 0.42, 0.78)
		slot.get_node("Level").text = "%d" % lv

func _update_strategy_label() -> void:
	if not has_node("Hud/StrategyButton/Label"):
		return
	$Hud/StrategyButton/Label.text = "策略：%s" % _strategy_name(target_manager.strategy)

func _strategy_name(strategy: String) -> String:
	match strategy:
		"breach":
			return "越线"
		"elite":
			return "精英"
		"nearest":
			return "最近"
		"low_hp":
			return "残血"
		_:
			return strategy

func _show_wave_toast(text: String, color: Color) -> void:
	var toast: Label = $Hud/WaveToast
	toast.text = text
	toast.add_theme_color_override("font_color", color)
	toast.visible = true
	toast.modulate.a = 1.0
	var tween := toast.create_tween()
	tween.tween_interval(0.95)
	tween.tween_property(toast, "modulate:a", 0.0, 0.32)
	tween.tween_callback(func() -> void:
		toast.visible = false
		toast.modulate.a = 1.0
	)

func _show_onboarding_tip() -> void:
	if onboarding_tip_shown:
		return
	onboarding_tip_shown = true
	var text := ""
	match onboarding_stage:
		"aim_and_first_card":
			text = "自动开火会瞄准当前策略目标，点僵尸可锁定优先击杀。"
		"first_card":
			text = "XP 满后选择技能卡：清群拿分裂/多重，漏怪拿减速/追踪。"
		"runner_threat":
			text = "高速单位弱冰，切到越线策略可优先压住漏怪。"
		"lock_and_pierce":
			text = "重甲和支援要点名处理，锁定后配穿透更稳。"
		"boss_pressure":
			text = "Boss 有弱点和护甲阶段，优先拿穿透、蓄能和克制元素。"
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
		return "高速单位会漏线：切越线策略，拿减速/追踪。"
	if tags.has("tank"):
		return "厚血推进：锁定精英，优先穿透/蓄能/暴击。"
	if tags.has("support"):
		return "支援会放大尸潮：点名处理，再清小怪。"
	if tags.has("burst"):
		return "爆发威胁高：留屏障和控制，别让近线爆开。"
	for wave in level.get("waves", []):
		if wave.has("boss"):
			return "Boss 关：先清支援，再集中破甲打弱点。"
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
		text = "Boss 波：先清支援，锁定 Boss 破甲。"
	else:
		var wave_tags: Array = level.get("threat_tags", [])
		if wave_tags.has("fast") and wave_index == 1:
			text = "提示：高速怪接近防线时，越线策略更可靠。"
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
	var turret_pos := turret.global_position
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
	slow_field_rect = ColorRect.new()
	slow_field_rect.color = Color(0.32, 0.78, 1.0, 0.0)
	slow_field_rect.position = Vector2(0, 0)
	slow_field_rect.size = Vector2(1080, 80)
	slow_field_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$SlowFieldLayer.add_child(slow_field_rect)

func _update_slow_field_visual(slow_level: int) -> void:
	if slow_field_rect == null:
		return
	if slow_level <= 0:
		slow_field_rect.color.a = 0.0
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
	slow_field_rect.size = Vector2(1080, max(1500.0 - y_min, 60.0))
	slow_field_rect.color = Color(0.32, 0.78, 1.0, 0.18 + slow_pct * 0.25)

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
	_spawn_attack_ring(barrier_visual.global_position, 430.0, Color(0.55, 0.9, 1.0, 0.35), 0.24)
	var tween := barrier_visual.create_tween()
	barrier_visual.scale = Vector2(0.98, 0.98)
	tween.tween_property(barrier_visual, "scale", Vector2(1.025, 1.025), 0.09)
	tween.tween_property(barrier_visual, "scale", Vector2.ONE, 0.12)

func _spawn_barrier_break_vfx(hit_position: Vector2) -> void:
	_spawn_attack_ring(hit_position, 150.0, Color(0.76, 0.96, 1.0, 0.42), 0.18)
	for i in range(10):
		var shard := Polygon2D.new()
		var size := randf_range(18.0, 42.0)
		shard.polygon = PackedVector2Array([
			Vector2(0, -size * 0.55),
			Vector2(size * 0.45, size * 0.4),
			Vector2(-size * 0.5, size * 0.5),
		])
		shard.global_position = hit_position + Vector2(randf_range(-70.0, 70.0), randf_range(-26.0, 22.0))
		shard.rotation = randf_range(-0.5, 0.5)
		shard.color = Color(0.72, 0.94, 1.0, 0.42)
		$SlowFieldLayer.add_child(shard)
		var drift := Vector2(randf_range(-90.0, 90.0), randf_range(-96.0, 54.0))
		var tween := shard.create_tween()
		tween.parallel().tween_property(shard, "global_position", shard.global_position + drift, 0.32)
		tween.parallel().tween_property(shard, "rotation", shard.rotation + randf_range(-1.1, 1.1), 0.32)
		tween.parallel().tween_property(shard, "color:a", 0.0, 0.32)
		tween.tween_callback(shard.queue_free)

func _show_card_offer() -> void:
	card_offer_active = true
	AudioManager.play_sfx("card_offer")
	AudioManager.play_sfx("level_up", -2.0, 0.02)
	_spawn_levelup_vfx(Vector2(540, 1580), Color(0.7, 0.95, 1.0))
	get_tree().paused = true
	_render_card_offer(skills.owned)
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
	var card := Panel.new()
	card.custom_minimum_size = Vector2(760, 168)
	card.clip_contents = true
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(_on_skill_card_input.bind(skill_id))

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = load(row.get("icon", ""))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(22, 20)
	icon.size = Vector2(128, 128)
	icon.custom_minimum_size = Vector2(128, 128)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon)
	icon.set_deferred("position", Vector2(22, 20))
	icon.set_deferred("size", Vector2(128, 128))

	var title := Label.new()
	title.name = "Title"
	title.text = "%s  Lv.%d" % [display_name, lv]
	title.position = Vector2(170, 16)
	title.size = Vector2(560, 44)
	title.add_theme_font_size_override("font_size", 32)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(title)

	var desc := Label.new()
	desc.name = "Desc"
	desc.text = _skill_short_desc(skill_id, lv)
	desc.position = Vector2(170, 62)
	desc.size = Vector2(560, 54)
	desc.add_theme_font_size_override("font_size", 24)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(desc)

	var tags := Label.new()
	tags.name = "Tags"
	tags.text = _format_card_tags(row.get("card_tags", []))
	tags.position = Vector2(170, 122)
	tags.size = Vector2(560, 34)
	tags.add_theme_font_size_override("font_size", 21)
	tags.add_theme_color_override("font_color", Color(0.72, 0.92, 1.0))
	tags.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(tags)

	var reason := _skill_recommendation_reason(skill_id, row)
	if reason != "":
		var badge := Label.new()
		badge.name = "RecommendBadge"
		badge.text = "推荐 · %s" % reason
		badge.position = Vector2(538, 18)
		badge.size = Vector2(196, 34)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", 19)
		badge.add_theme_color_override("font_color", Color(1.0, 0.86, 0.28, 1.0))
		badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		badge.add_theme_constant_override("outline_size", 4)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(badge)
		card.modulate = Color(1.0, 0.98, 0.86, 1.0)

	return card

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
	if card_press_skill_id == "" or card_long_press_opened:
		return
	var held_for := Time.get_ticks_msec() / 1000.0 - card_press_started_at
	if held_for >= 0.45:
		card_long_press_opened = true
		_show_card_detail(card_press_skill_id)

func _show_card_detail(skill_id: String) -> void:
	AudioManager.play_sfx("ui_click", -4.0)
	var row := DataLoader.get_row("skills", skill_id)
	var lv := _skill_offer_level(skill_id)
	$Hud/CardPanel/DetailOverlay.visible = true
	$Hud/CardPanel/DetailOverlay/Panel/Icon.texture = load(row.get("icon", ""))
	$Hud/CardPanel/DetailOverlay/Panel/Title.text = "%s  Lv.%d" % [DataLoader.tr_key(row.get("name_key", skill_id)), lv]
	$Hud/CardPanel/DetailOverlay/Panel/Body.text = "%s\n\n%s" % [
		_skill_long_desc(skill_id, lv),
		"标签：%s" % _format_card_tags(row.get("card_tags", []))
	]

func _hide_card_detail() -> void:
	AudioManager.play_sfx("ui_click", -5.0)
	$Hud/CardPanel/DetailOverlay.visible = false
	card_press_skill_id = ""
	card_long_press_opened = false

func _format_card_tags(tags: Array) -> String:
	var names := []
	for tag in tags:
		match str(tag):
			"projectile":
				names.append("弹道")
			"anti_swarm":
				names.append("清群")
			"anti_armor":
				names.append("破甲")
			"control":
				names.append("控制")
			"defense":
				names.append("防线")
			_:
				names.append(str(tag))
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
		combos.append({"key": "combo_poison_spread", "label": "Combo：毒素扩散", "family": "poison", "color": Color(0.48, 1.0, 0.24, 1.0)})
	if skills.level("skill_cryo") > 0 and skills.level("skill_slow_field") > 0:
		combos.append({"key": "combo_ice_control", "label": "Combo：冰控防线", "family": "ice", "color": Color(0.54, 0.9, 1.0, 1.0)})
	if skills.level("skill_tesla") > 0 and (skills.level("skill_homing") > 0 or skills.level("skill_ricochet") > 0):
		combos.append({"key": "combo_chain_hunt", "label": "Combo：电链追击", "family": "lightning", "color": Color(1.0, 0.9, 0.2, 1.0)})
	if skills.level("skill_incendiary") > 0 and (skills.level("skill_split_shot") > 0 or skills.level("skill_multishot") > 0 or skills.level("skill_salvo") > 0):
		combos.append({"key": "combo_fire_clear", "label": "Combo：火焰清场", "family": "fire", "color": Color(1.0, 0.46, 0.16, 1.0)})
	if skills.level("skill_pierce") > 0 and (skills.level("skill_charge_shot") > 0 or skills.level("skill_critical") > 0):
		combos.append({"key": "combo_pierce_execute", "label": "Combo：穿甲点杀", "family": "physical", "color": Color(1.0, 0.88, 0.48, 1.0)})
	if skills.level("skill_barrier") > 0 and skills.level("skill_slow_field") > 0:
		combos.append({"key": "combo_guard_line", "label": "Combo：防线稳固", "family": "defense", "color": Color(0.58, 0.86, 1.0, 1.0)})
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
			return "提高暴击率和伤害，对精英与 Boss 更有效。"
		"skill_barrier":
			return "获得一次防线拦截，挡下下一只越线僵尸。"
		"skill_gold_rush":
			return "提高本局金币收益，适合滚长期养成。"
		"skill_ricochet":
			return "命中后额外弹射，强化清群和连锁补刀。"
		"skill_salvo":
			return "提高主炮攻速，让持续输出更密。"
		"skill_incendiary":
			return "把弹药改为火焰属性，压制怕火目标。"
		"skill_cryo":
			return "把弹药改为冰霜属性，并强化减速控制。"
		"skill_tesla":
			return "把弹药改为闪电属性，专门克制相位敌人。"
		"skill_venom":
			return "把弹药改为毒素属性，对厚甲目标更稳。"
		"skill_charge_shot":
			return "提升主弹伤害，让单点击杀更干脆。"
		"skill_recycle":
			return "获得额外重抽次数，提高技能成型稳定性。"
		_:
			return "强化当前战斗能力。"

func _skill_long_desc(skill_id: String, lv: int) -> String:
	match skill_id:
		"skill_split_shot":
			return "每次命中都会触发分裂弹。等级越高，分裂数量越多，Lv.3 会形成更大的扇形爆发，适合第三关这种密集推进。"
		"skill_pierce":
			return "主弹可以继续穿透后排敌人。等级越高，穿透次数越多，Lv.3 还会提高子弹伤害，适合处理巨臂和 Boss 护甲。"
		"skill_multishot":
			return "每次开火额外发射弹丸。等级越高，弹丸数量越多，Lv.3 会形成四发扇面，手感上更像火力压制。"
		"skill_slow_field":
			return "在防线前展开持续减速区。等级越高，区域越靠前、减速越强，Lv.3 会显示更宽的青色力场。"
		"skill_homing":
			return "子弹飞行中会向最近目标修正方向。等级越高修正越明显，能显著改善斜线开火、高速小怪和残血补刀的手感。"
		"skill_critical":
			return "提高暴击概率，同时小幅提高全局伤害。适合搭配高射速武器，面对精英、Boss 和护盾怪时收益更稳定。"
		"skill_barrier":
			return "立刻补充一次技能护盾，下一次敌人越线时不扣基地生命。多次选择可以叠加，是后期容错核心。"
		"skill_gold_rush":
			return "本局获得金币提高。它不会直接提高战力，但能让过关后的武器和装备成长更快，适合低压波次选择。"
		"skill_ricochet":
			return "命中后产生额外弹射弹，和分裂弹共享清群定位。等级越高弹射数量越多，适合尸潮密度高的关卡。"
		"skill_salvo":
			return "提高主炮攻击速度。等级越高射击间隔越短，适合搭配穿透、暴击和元素弹，在后期高数量尸潮里保持稳定压制。"
		"skill_incendiary":
			return "当前弹药转为火焰属性。火焰更适合打爆裂、再生和怕火单位，也会触发元素芯片的额外伤害。"
		"skill_cryo":
			return "当前弹药转为冰霜属性，并把减速区效果合并进弹道体系。适合防守压力大、敌人速度快的局。"
		"skill_tesla":
			return "当前弹药转为闪电属性。闪电能稳定命中相位单位，并和电系角色的连锁被动形成清屏联动。"
		"skill_venom":
			return "当前弹药转为毒素属性。毒素偏向破厚血和护甲压力，适合对付坦克、守卫和后期高血量敌人。"
		"skill_charge_shot":
			return "提高所有主弹基础伤害。它没有复杂机制，但能直接缩短击杀时间，适合补足单体输出短板。"
		"skill_recycle":
			return "补充一次重抽机会。拿到它以后，后续技能选择更容易围绕角色、武器和关卡威胁成型。"
		_:
			return "获得一项战斗强化。"

func _on_reroll_pressed() -> void:
	if reroll_charges <= 0 or not card_offer_active:
		return
	reroll_charges -= 1
	AudioManager.play_sfx("reroll")
	_render_card_offer(skills.owned)
	_animate_card_panel_in(0.08)

func _on_skip_card() -> void:
	if not card_offer_active:
		return
	AudioManager.play_sfx("ui_click")
	card_offer_active = false
	$Hud/CardPanel.visible = false
	get_tree().paused = false
	cards_picked += 1
	next_xp_offer += maxi(6, int(round(float(level.get("xp_offer_growth", 18)) * 0.55)))

func _choose_card(skill_id: String) -> void:
	AudioManager.play_sfx("card_pick")
	AudioManager.play_sfx("level_up", -3.0, 0.02)
	if not skills.add_skill(skill_id):
		_show_wave_toast("该技能已满级", Color(1.0, 0.72, 0.24))
		card_offer_active = false
		$Hud/CardPanel.visible = false
		get_tree().paused = false
		return
	cards_picked += 1
	_spawn_levelup_vfx(Vector2(540, 1580), Color(1.0, 0.86, 0.3))
	_spawn_skill_pick_vfx(skill_id)
	if skill_id == "skill_barrier":
		skill_barriers_left += 1
		_spawn_barrier_gain_vfx()
	if skill_id == "skill_recycle":
		reroll_charges += 1
	if skill_id == "skill_salvo" and turret != null:
		var next_fire_rate_mult := skills.fire_rate_multiplier()
		turret.fire_rate *= next_fire_rate_mult / skill_fire_rate_mult
		skill_fire_rate_mult = next_fire_rate_mult
		_spawn_float_text(turret.global_position + Vector2(0, -190), "攻速提升", Color(1.0, 0.86, 0.32))
	_process_build_feedback(skill_id)
	_show_wave_toast("%s 已生效" % DataLoader.tr_key(DataLoader.get_row("skills", skill_id).get("name_key", skill_id)), Color(1.0, 0.86, 0.28))
	_update_skill_slots()
	_spawn_skill_to_slot_vfx(skill_id)
	next_xp_offer += int(round(float(level.get("xp_offer_growth", 18)) + float(cards_picked) * float(level.get("xp_offer_ramp", 4))))
	card_offer_active = false
	$Hud/CardPanel.visible = false
	get_tree().paused = false

func _spawn_skill_pick_vfx(skill_id: String) -> void:
	var color := Color(1.0, 0.86, 0.28)
	var tex_path := "res://assets/production/sprites/vfx/vfx_levelup_glow.png"
	match skill_id:
		"skill_incendiary":
			color = _element_color("fire")
			tex_path = "res://assets/production/sprites/vfx/vfx_explosion_fire.png"
		"skill_cryo":
			color = _element_color("ice")
			tex_path = "res://assets/production/sprites/vfx/vfx_freeze.png"
		"skill_tesla":
			color = _element_color("lightning")
			tex_path = "res://assets/production/sprites/vfx/vfx_chain_lightning.png"
		"skill_venom":
			color = _element_color("poison")
			tex_path = "res://assets/production/sprites/vfx/vfx_poison_cloud.png"
		"skill_barrier":
			color = Color(0.58, 0.86, 1.0, 1.0)
		"skill_split_shot", "skill_ricochet":
			color = Color(1.0, 0.68, 0.26, 1.0)
		"skill_pierce", "skill_charge_shot":
			color = Color(1.0, 0.9, 0.48, 1.0)
	var fx := Sprite2D.new()
	fx.texture = load(tex_path)
	fx.global_position = Vector2(540, 1560)
	fx.scale = Vector2(0.42, 0.42)
	fx.modulate = color
	$ProjectileLayer.add_child(fx)
	var tween := fx.create_tween()
	tween.parallel().tween_property(fx, "scale", Vector2(1.05, 1.05), 0.32)
	tween.parallel().tween_property(fx, "rotation", fx.rotation + 0.28, 0.32)
	tween.parallel().tween_property(fx, "modulate:a", 0.0, 0.32)
	tween.tween_callback(fx.queue_free)

func _spawn_skill_to_slot_vfx(skill_id: String) -> void:
	var row := DataLoader.get_row("skills", skill_id)
	var icon := TextureRect.new()
	icon.texture = load(row.get("icon", ""))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(490, 980)
	icon.size = Vector2(100, 100)
	icon.custom_minimum_size = Vector2(100, 100)
	icon.pivot_offset = Vector2(50, 50)
	icon.modulate = Color(1, 1, 1, 0.95)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Hud.add_child(icon)
	icon.set_deferred("position", Vector2(805, 120))
	icon.set_deferred("size", Vector2(72, 72))
	var target := Vector2(860, 48)
	var slot := $Hud/SkillSlots.get_node_or_null(skill_id)
	if slot and slot is Control:
		target = (slot as Control).global_position + Vector2(14, 14)
	var tween := icon.create_tween()
	tween.parallel().tween_property(icon, "position", target, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(icon, "scale", Vector2(0.42, 0.42), 0.28)
	tween.parallel().tween_property(icon, "rotation", 0.18, 0.28)
	tween.tween_callback(func() -> void:
		if slot and slot is Control:
			var pulse := (slot as Control).create_tween()
			pulse.tween_property(slot, "scale", Vector2(1.16, 1.16), 0.08)
			pulse.tween_property(slot, "scale", Vector2.ONE, 0.12)
		icon.queue_free()
	)

func _on_enemy_hit_feedback(enemy: Node, element: String, immune_hit: bool, weak_hit: bool, hit_kind: String) -> void:
	AudioManager.play_sfx("hit_immune" if immune_hit else _element_hit_sfx(element), -8.0)
	if not is_instance_valid(enemy):
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
		screen_flash = ColorRect.new()
		screen_flash.name = "ScreenFlash"
		screen_flash.position = Vector2.ZERO
		screen_flash.size = Vector2(1080, 1920)
		screen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$Hud.add_child(screen_flash)
	if screen_flash_tween != null and screen_flash_tween.is_valid():
		screen_flash_tween.kill()
	var current_alpha := screen_flash.color.a * screen_flash.modulate.a
	var alpha := minf(maxf(color.a, current_alpha), 0.14)
	screen_flash.color = Color(color.r, color.g, color.b, alpha)
	screen_flash.modulate.a = 1.0
	screen_flash_tween = screen_flash.create_tween()
	screen_flash_tween.tween_property(screen_flash, "modulate:a", 0.0, duration)

func _battle_bgm_id() -> String:
	match str(level.get("env", "")):
		"env_subway":
			return "battle_subway"
		"env_biolab":
			return "battle_biolab"
		"env_military":
			return "battle_military"
		_:
			return "battle_city"

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
	var label := Label.new()
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
