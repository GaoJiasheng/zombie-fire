extends Area2D

signal died(enemy: Node, reward: Dictionary)
signal breached(enemy: Node, damage: int)
signal hit_feedback(enemy: Node, element: String, immune_hit: bool, weak_hit: bool, hit_kind: String)
signal damage_dealt(enemy: Node, amount: float, element: String, crit_hit: bool, weak_hit: bool)

const BREACH_Y := 1500.0
const BASE_ATTACK_Y := 1435.0

var data := {}
var max_hp := 100.0
var hp := 100.0
var speed := 80.0
var breach_damage := 10
var base_attack_damage := 10
var base_attack_interval := 1.35
var base_attack_kind := "basic"
var attack_line_y := BASE_ATTACK_Y
var gold := 10
var run_xp := 1
var elite := false
var boss := false
var speed_mult := 1.0
var attacking_base := false
var immune := []
var weakness := "none"
var resist := "none"
var mechanic := "basic"
var mechanic_params: Dictionary = {}
var base_attack_timer := 0.0
var armor_hits_left := 0
var armor_broken := false
var shield_hp := 0.0
var external_damage_mult := 1.0
var mechanic_timer := 0.0
var enrage_triggered := false
var threat_marker: Label
var _base_modulate: Color
var _walk_frames: Array[Texture2D] = []
var _attack_frames: Array[Texture2D] = []
var _special_frames: Array[Texture2D] = []
var _hurt_frames: Array[Texture2D] = []
var _death_frames: Array[Texture2D] = []
var _anim_state := "walk"
var _anim_time := 0.0
var _anim_frame := 0
var _hurt_time := 0.0
var _special_time := 0.0
var _dying := false
var _death_time := 0.0
var _stride_phase := 0.0
var _base_sprite_x := 0.0
var _burn_time := 0.0
var _burn_dps := 0.0
var _poison_time := 0.0
var _poison_dps := 0.0
var _element_slow_time := 0.0
var _element_slow_mult := 1.0
var _shock_time := 0.0
var _last_hit_weak := false
var _last_hit_element := "physical"
var _hp_bg: ColorRect
var _hp_fill: ColorRect
var _status_aura: Sprite2D
var _rank_aura: Sprite2D
var _status_label: Label

func setup(row: Dictionary, level_coef: float, is_boss := false) -> void:
	add_to_group("enemies")
	data = row
	boss = is_boss
	elite = boss or row.get("threat_tags", []).has("elite")
	max_hp = 50.0 * row.get("hp_coef", 1.0) * level_coef
	hp = max_hp
	speed = row.get("speed", 80.0)
	breach_damage = int(10 * row.get("bd_coef", 1.0))
	gold = int(10 * row.get("gold_coef", 1.0))
	run_xp = int(row.get("run_xp", 1))
	immune = row.get("immune", [])
	weakness = row.get("weakness", "none")
	resist = row.get("resist", "none")
	mechanic = row.get("mechanic", "basic")
	mechanic_params = row.get("mechanic_params", {})
	_configure_base_attack()
	if mechanic == "armor_break":
		armor_hits_left = int(mechanic_params.get("armor_hits", 0))
	if mechanic == "armor" or mechanic == "shield_aura" or mechanic == "ward":
		shield_hp = max_hp * 0.35
	if mechanic == "phase" or mechanic == "phase_shift":
		modulate.a = 0.82
	if mechanic == "summon":
		mechanic_timer = randf_range(1.2, 2.4)
	var tex := load(row.get("sprite", "")) as Texture2D
	$Sprite.texture = tex
	_load_animation_frames(row, is_boss)
	if not _walk_frames.is_empty():
		$Sprite.texture = _walk_frames[0]
	$CollisionShape2D.shape = CircleShape2D.new()
	$CollisionShape2D.shape.radius = 70.0 if not boss else 130.0
	$Sprite.scale = Vector2(0.32, 0.32) if not boss else Vector2(0.44, 0.44)
	_base_sprite_x = $Sprite.position.x
	_base_modulate = Color(1, 1, 1, 1)
	_build_hp_bar()
	_build_threat_marker()
	_build_model_polish_layers()

func _build_threat_marker() -> void:
	threat_marker = Label.new()
	threat_marker.text = _threat_text()
	threat_marker.add_theme_font_size_override("font_size", 22)
	threat_marker.add_theme_color_override("font_color", _threat_color())
	threat_marker.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	threat_marker.add_theme_constant_override("outline_size", 4)
	threat_marker.horizontal_alignment = 1
	threat_marker.size = Vector2(220, 32)
	threat_marker.position = Vector2(-110, 0)
	threat_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	threat_marker.visible = not threat_marker.text.is_empty()

func _threat_text() -> String:
	var tags: Array = data.get("threat_tags", [])
	var weak := _weakness_hint()
	if boss:
		return "BOSS%s" % weak
	if tags.has("breach"):
		return "近线%s" % weak
	if tags.has("elite"):
		return "精英%s" % weak
	if tags.has("support"):
		return "支援%s" % weak
	if tags.has("burst"):
		return "爆裂%s" % weak
	if tags.has("tank"):
		return "重甲%s" % weak
	if tags.has("fast"):
		return "高速%s" % weak
	return ""

func _weakness_hint() -> String:
	if weakness == "none" or weakness == "":
		return ""
	return "·%s" % _element_label(weakness)

func _element_label(element: String) -> String:
	match element:
		"physical":
			return "物"
		"fire":
			return "火"
		"ice":
			return "冰"
		"lightning":
			return "电"
		"poison":
			return "毒"
		_:
			return element

func _threat_color() -> Color:
	if boss:
		return Color(1.0, 0.25, 0.25)
	var tags: Array = data.get("threat_tags", [])
	if tags.has("breach"):
		return Color(1.0, 0.32, 0.32)
	if tags.has("elite") or tags.has("tank") or tags.has("burst"):
		return Color(1.0, 0.65, 0.2)
	if tags.has("support") or tags.has("fast"):
		return Color(1.0, 0.92, 0.3)
	return Color.WHITE

func _physics_process(delta: float) -> void:
	_update_animation(delta)
	_update_hp_bar_position()
	if _dying:
		return
	_process_self_mechanic(delta)
	_process_element_status(delta)
	if attacking_base:
		_process_base_attack(delta)
	else:
		position.y += speed * speed_mult * delta
		_update_stride(delta)
		if position.y >= attack_line_y:
			_enter_base_attack()
	if threat_marker and is_instance_valid(threat_marker):
		var offset_y := -110.0 if not boss else -190.0
		threat_marker.position = global_position + Vector2(-110.0, offset_y)

func _configure_base_attack() -> void:
	base_attack_damage = breach_damage
	base_attack_interval = 1.35
	base_attack_kind = mechanic
	match mechanic:
		"runner", "low_profile", "leap", "charge", "phase", "phase_shift":
			base_attack_damage = maxi(1, int(round(float(breach_damage) * 0.72)))
			base_attack_interval = 0.82
			base_attack_kind = "fast_claw"
		"tank", "armor", "armor_break", "juggernaut", "shield_aura", "ward", "multi_phase":
			base_attack_damage = maxi(1, int(round(float(breach_damage) * 1.38)))
			base_attack_interval = 1.72
			base_attack_kind = "heavy_slam"
		"explode_on_death", "phase_burn":
			base_attack_damage = maxi(1, int(round(float(breach_damage) * 1.18)))
			base_attack_interval = 1.46
			base_attack_kind = "blast"
		"ranged_spit", "toxic_cloud", "regenerate", "spawn_minions":
			base_attack_damage = maxi(1, int(round(float(breach_damage) * 0.86)))
			base_attack_interval = 1.12
			base_attack_kind = "corrosion"
		"buff_aura", "summon":
			base_attack_damage = maxi(1, int(round(float(breach_damage) * 0.76)))
			base_attack_interval = 1.05
			base_attack_kind = "support_strike"
	if boss:
		base_attack_damage = maxi(1, int(round(float(base_attack_damage) * 1.35)))
		base_attack_interval += 0.28
		attack_line_y = BASE_ATTACK_Y - 80.0 + randf_range(-14.0, 18.0)
	else:
		attack_line_y = BASE_ATTACK_Y + randf_range(-18.0, 26.0)
	base_attack_damage = int(mechanic_params.get("base_attack_damage", base_attack_damage))
	base_attack_interval = float(mechanic_params.get("base_attack_interval", base_attack_interval))
	base_attack_kind = str(mechanic_params.get("base_attack_kind", base_attack_kind))

func _enter_base_attack() -> void:
	attacking_base = true
	position.y = attack_line_y
	speed_mult = 1.0
	base_attack_timer = randf_range(0.08, 0.34)
	play_special(0.32)

func _process_base_attack(delta: float) -> void:
	var charge_delta := delta
	if _element_slow_time > 0.0:
		charge_delta *= clampf(_element_slow_mult, 0.45, 1.0)
	if _shock_time > 0.0:
		charge_delta *= 0.55 if not boss else 0.75
	base_attack_timer -= charge_delta
	if base_attack_timer > 0.0:
		return
	base_attack_timer = maxf(0.45, base_attack_interval + randf_range(-0.12, 0.18))
	play_special(0.36 if not boss else 0.48)
	breached.emit(self, base_attack_damage)

func take_damage(amount: float, element := "physical") -> void:
	if _dying:
		return
	_last_hit_weak = false
	_last_hit_element = element
	if (mechanic == "phase" or mechanic == "phase_shift") and element != "lightning" and randf() < (0.32 if not boss else 0.22):
		_emit_hit_feedback(element, true, false, "phase_evade")
		_flash(Color(0.45, 0.8, 1.0, 0.72))
		return
	var final_damage := amount * external_damage_mult
	if immune.has(element):
		if boss and not armor_broken:
			if armor_hits_left > 0:
				armor_hits_left -= 1
				_emit_hit_feedback(element, true, false, "armor")
				_flash(Color(0.6, 0.6, 0.6))
				if armor_hits_left <= 0:
					armor_broken = true
					_base_modulate = Color(1.0, 0.55, 0.55)
					_flash(_base_modulate)
					_spawn_crit_vfx(Color(1.0, 0.42, 0.28))
					if threat_marker and is_instance_valid(threat_marker):
						threat_marker.text = "BROKEN"
						threat_marker.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
				return
			armor_broken = true
		else:
			_emit_hit_feedback(element, true, false, "immune")
			_flash(Color(0.8, 0.8, 0.8))
			return
	if weakness != "none" and element == weakness:
		final_damage *= 1.5
		_last_hit_weak = true
	if resist != "none" and element == resist:
		final_damage *= 0.5
	if shield_hp > 0.0 and element != weakness:
		var absorbed: float = min(shield_hp, final_damage)
		shield_hp -= absorbed
		final_damage -= absorbed
		_flash(Color(0.45, 0.72, 1.0))
		if final_damage <= 0.0:
			_emit_hit_feedback(element, true, false, "shield")
			_update_hp_bar()
			return
	hp -= final_damage
	_apply_element_status(final_damage, element)
	_update_hp_bar()
	var crit_hit := _last_hit_weak or final_damage >= max_hp * (0.22 if not boss else 0.12)
	damage_dealt.emit(self, final_damage, element, crit_hit, _last_hit_weak)
	_emit_hit_feedback(element, false, _last_hit_weak, "weak" if _last_hit_weak else "normal")
	_play_hurt_feedback(element)
	if crit_hit:
		_spawn_crit_vfx(Color(1.0, 0.86, 0.28) if _last_hit_weak else Color(1.0, 0.38, 0.22))
	if hp <= 0.0:
		_dying = true
		_anim_state = "death"
		_anim_time = 0.0
		_anim_frame = 0
		$CollisionShape2D.set_deferred("disabled", true)
		died.emit(self, {"gold": gold, "xp": run_xp, "weak_kill": _last_hit_weak, "boss": boss, "death_element": _last_hit_element})
		if _death_frames.is_empty():
			call_deferred("queue_free")

func _emit_hit_feedback(element: String, immune_hit: bool, weak_hit: bool, hit_kind: String) -> void:
	hit_feedback.emit(self, element, immune_hit, weak_hit, hit_kind)

func _process_self_mechanic(delta: float) -> void:
	if mechanic == "regen" or mechanic == "regenerate":
		hp = min(max_hp, hp + max_hp * 0.025 * delta)
		_update_hp_bar()
	elif mechanic == "enrage" and not enrage_triggered and hp <= max_hp * 0.5:
		enrage_triggered = true
		speed *= 1.35
		breach_damage = int(round(float(breach_damage) * 1.25))
		_base_modulate = Color(1.0, 0.52, 0.32)
		_flash(_base_modulate)
	elif mechanic == "charge" and global_position.y > 760.0:
		speed_mult = max(speed_mult, 1.08)
	elif mechanic == "leap":
		speed_mult = max(speed_mult, 1.0 + max(0.0, sin(_stride_phase * 1.6)) * 0.32)
	elif mechanic == "low_profile":
		external_damage_mult *= 0.92
	elif mechanic == "juggernaut":
		external_damage_mult *= 0.86
	elif mechanic == "multi_phase":
		var hp_ratio := hp / max_hp if max_hp > 0.0 else 0.0
		if hp_ratio < 0.34:
			speed_mult *= 1.18
			external_damage_mult *= 0.82
		elif hp_ratio < 0.67:
			speed_mult *= 1.08
			external_damage_mult *= 0.9

func _apply_element_status(applied_damage: float, element: String) -> void:
	match element:
		"fire":
			_burn_time = max(_burn_time, 2.2)
			_burn_dps = max(_burn_dps, applied_damage * 0.22)
			_flash(Color(1.0, 0.42, 0.18))
		"poison":
			_poison_time = max(_poison_time, 3.2)
			_poison_dps = max(_poison_dps, applied_damage * 0.16)
			_flash(Color(0.42, 1.0, 0.28))
		"ice":
			_element_slow_time = max(_element_slow_time, 1.8)
			_element_slow_mult = min(_element_slow_mult, 0.72 if not boss else 0.84)
			_flash(Color(0.45, 0.86, 1.0))
		"lightning":
			_shock_time = max(_shock_time, 0.35)
			_flash(Color(1.0, 0.9, 0.2))

func amplify_character_status(element: String, source_damage: float, rank: int, bonus := 0.0) -> void:
	if _dying:
		return
	match element:
		"fire":
			_burn_time = max(_burn_time, 2.8 + 0.28 * float(rank))
			_burn_dps = max(_burn_dps, source_damage * (0.3 + bonus + 0.04 * float(rank)))
			_flash(Color(1.0, 0.34, 0.12))
		"ice":
			_element_slow_time = max(_element_slow_time, 2.35 + 0.28 * float(rank))
			var target_slow := 0.66 - 0.035 * float(rank) - bonus
			if boss:
				target_slow = max(target_slow, 0.74)
			_element_slow_mult = min(_element_slow_mult, clampf(target_slow, 0.48, 0.86))
			_flash(Color(0.48, 0.9, 1.0))
		"lightning":
			_shock_time = max(_shock_time, 0.52 + 0.08 * float(rank) + bonus)
			_flash(Color(1.0, 0.9, 0.18))
	_update_status_aura()

func is_controlled() -> bool:
	return _element_slow_time > 0.0 or _shock_time > 0.0

func has_element_status(element: String) -> bool:
	match element:
		"fire":
			return _burn_time > 0.0
		"ice":
			return _element_slow_time > 0.0
		"lightning":
			return _shock_time > 0.0
		"poison":
			return _poison_time > 0.0
		_:
			return false

func _process_element_status(delta: float) -> void:
	if _burn_time > 0.0:
		_burn_time -= delta
		_apply_status_damage(_burn_dps * delta, Color(1.0, 0.38, 0.12))
	if _poison_time > 0.0:
		_poison_time -= delta
		_apply_status_damage(_poison_dps * delta, Color(0.42, 1.0, 0.28))
	if _element_slow_time > 0.0:
		_element_slow_time -= delta
		speed_mult *= _element_slow_mult
	else:
		_element_slow_mult = 1.0
	if _shock_time > 0.0:
		_shock_time -= delta
		speed_mult *= 0.55 if not boss else 0.75
	_update_status_aura()

func _apply_status_damage(amount: float, color: Color) -> void:
	if _dying or amount <= 0.0:
		return
	hp -= amount
	_update_hp_bar()
	modulate = modulate.lerp(color, 0.2)
	damage_dealt.emit(self, amount, _status_to_element(color), false, false)
	if hp <= 0.0:
		_dying = true
		_anim_state = "death"
		_anim_time = 0.0
		_anim_frame = 0
		$CollisionShape2D.set_deferred("disabled", true)
		died.emit(self, {"gold": gold, "xp": run_xp, "weak_kill": false, "boss": boss})
		if _death_frames.is_empty():
			call_deferred("queue_free")

func _flash(color: Color) -> void:
	modulate = color
	var tween := create_tween()
	tween.tween_property(self, "modulate", _base_modulate, 0.18)

func _build_hp_bar() -> void:
	_hp_bg = ColorRect.new()
	_hp_bg.name = "HpBar"
	_hp_bg.color = Color(0.04, 0.04, 0.04, 0.88)
	_hp_bg.size = Vector2(118, 12) if not boss else Vector2(220, 18)
	_hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_bg)

	_hp_fill = ColorRect.new()
	_hp_fill.color = Color(0.86, 0.12, 0.12, 1.0) if not boss else Color(1.0, 0.42, 0.18, 1.0)
	_hp_fill.position = Vector2(2, 2)
	_hp_fill.size = _hp_bg.size - Vector2(4, 4)
	_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_bg.add_child(_hp_fill)
	_update_hp_bar_position()
	_update_hp_bar()

func _build_model_polish_layers() -> void:
	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.position = Vector2(-125, -154 if not boss else -254)
	_status_label.size = Vector2(250, 34)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 20 if not boss else 26)
	_status_label.add_theme_color_override("font_color", Color(0.78, 0.94, 1.0, 1.0))
	_status_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_status_label.add_theme_constant_override("outline_size", 4)
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_label.visible = false
	add_child(_status_label)
	if elite:
		_rank_aura = Sprite2D.new()
		_rank_aura.name = "RankAura"
		_rank_aura.texture = load("res://assets/production/sprites/vfx/vfx_levelup_glow.png")
		_rank_aura.position = Vector2(0, -36 if not boss else -74)
		_rank_aura.scale = Vector2(0.34, 0.34) if not boss else Vector2(0.72, 0.72)
		_rank_aura.z_index = -1
		_rank_aura.modulate = Color(1.0, 0.68, 0.16, 0.26) if not boss else Color(1.0, 0.18, 0.08, 0.38)
		add_child(_rank_aura)
	_status_aura = Sprite2D.new()
	_status_aura.name = "StatusAura"
	_status_aura.texture = load("res://assets/production/sprites/vfx/vfx_levelup_glow.png")
	_status_aura.position = Vector2(0, -34 if not boss else -72)
	_status_aura.scale = Vector2(0.24, 0.24) if not boss else Vector2(0.48, 0.48)
	_status_aura.z_index = -1
	_status_aura.visible = false
	add_child(_status_aura)

func _update_hp_bar_position() -> void:
	if _hp_bg == null:
		return
	var width := _hp_bg.size.x
	var y := -118.0 if not boss else -206.0
	_hp_bg.position = Vector2(-width / 2.0, y)

func _update_hp_bar() -> void:
	if _hp_bg == null or _hp_fill == null:
		return
	var ratio := clampf(hp / max_hp if max_hp > 0.0 else 0.0, 0.0, 1.0)
	_hp_fill.size.x = max((_hp_bg.size.x - 4.0) * ratio, 0.0)
	if shield_hp > 0.0:
		_hp_fill.color = Color(0.38, 0.76, 1.0, 1.0)
	elif armor_hits_left > 0 and not armor_broken:
		_hp_fill.color = Color(0.86, 0.68, 0.42, 1.0)
	elif boss:
		_hp_fill.color = Color(1.0, 0.42, 0.18, 1.0)
	else:
		_hp_fill.color = Color(0.86, 0.12, 0.12, 1.0)
	_hp_bg.visible = boss or ratio < 0.999
	_update_status_label()

func _play_hurt_feedback(element := "physical") -> void:
	_hurt_time = 0.16
	_anim_state = "hurt"
	_anim_time = 0.0
	_anim_frame = 0
	if not _hurt_frames.is_empty():
		$Sprite.texture = _hurt_frames[0]
	_flash(Color(1, 0.4, 0.4))
	var bump := create_tween()
	bump.tween_property($Sprite, "position:y", $Sprite.position.y - 10.0, 0.045)
	bump.tween_property($Sprite, "position:y", 0.0, 0.09)
	_spawn_hit_vfx(element)

func _spawn_hit_vfx(element := "physical") -> void:
	var tex := load(_hit_vfx_path(element)) as Texture2D
	if tex == null:
		return
	var hit := Sprite2D.new()
	hit.texture = tex
	hit.scale = Vector2(0.34, 0.34) if not boss else Vector2(0.52, 0.52)
	hit.modulate = Color(1, 1, 1, 0.9)
	hit.rotation = randf_range(-0.35, 0.35)
	add_child(hit)
	var tween := hit.create_tween()
	tween.parallel().tween_property(hit, "scale", hit.scale * 1.35, 0.12)
	tween.parallel().tween_property(hit, "modulate:a", 0.0, 0.12)
	tween.tween_callback(hit.queue_free)

func _spawn_crit_vfx(color: Color) -> void:
	var tex := load("res://assets/production/sprites/vfx/vfx_crit.png") as Texture2D
	if tex == null:
		return
	var crit := Sprite2D.new()
	crit.texture = tex
	crit.position = Vector2(randf_range(-18.0, 18.0), -42.0 if not boss else -76.0)
	crit.scale = Vector2(0.44, 0.44) if not boss else Vector2(0.7, 0.7)
	crit.modulate = color
	add_child(crit)
	var tween := crit.create_tween()
	tween.parallel().tween_property(crit, "scale", crit.scale * 1.5, 0.16)
	tween.parallel().tween_property(crit, "position:y", crit.position.y - 34.0, 0.16)
	tween.parallel().tween_property(crit, "modulate:a", 0.0, 0.16)
	tween.tween_callback(crit.queue_free)

func _hit_vfx_path(element: String) -> String:
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

func _status_to_element(color: Color) -> String:
	if color.r > 0.9 and color.g < 0.6:
		return "fire"
	if color.b > 0.9 and color.g > 0.7:
		return "ice"
	if color.r > 0.9 and color.g > 0.85 and color.b < 0.4:
		return "lightning"
	if color.g > 0.9 and color.r < 0.6:
		return "poison"
	return "physical"

func _load_animation_frames(row: Dictionary, is_boss: bool) -> void:
	var sprite_path: String = row.get("sprite", "")
	var entity_id := sprite_path.get_file().get_basename().replace("_prototype", "")
	var family := "bosses" if is_boss else "zombies"
	var base := "res://assets/production/sprites/animations/%s/%s/%s" % [family, entity_id, entity_id]
	_walk_frames = _load_frame_set(base, "walk", 6)
	_attack_frames = _load_frame_set(base, "attack", 4)
	_special_frames = _load_frame_set(base, "special", 6)
	_hurt_frames = _load_frame_set(base, "hurt", 3)
	_death_frames = _load_frame_set(base, "death", 6)

func _load_frame_set(base: String, anim: String, max_count: int) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	for i in range(1, max_count + 1):
		var path := "%s_%s_%02d.png" % [base, anim, i]
		if not ResourceLoader.exists(path):
			continue
		var tex := load(path) as Texture2D
		if tex:
			frames.append(tex)
	return frames

func _update_animation(delta: float) -> void:
	_update_model_polish(delta)
	if _dying:
		_death_time += delta
		_advance_frames(_death_frames, delta, 12.0, false)
		$Sprite.scale = $Sprite.scale.lerp(Vector2(0.18, 0.18) if not boss else Vector2(0.28, 0.28), min(delta * 5.0, 1.0))
		modulate.a = max(0.0, 1.0 - _death_time * 2.2)
		if _death_time >= max(0.12, float(_death_frames.size()) / 12.0):
			queue_free()
		return
	if _hurt_time > 0.0:
		_hurt_time -= delta
		_advance_frames(_hurt_frames, delta, 18.0, false)
		if _hurt_time <= 0.0:
			_anim_state = "walk"
			_anim_time = 0.0
			_anim_frame = 0
			return
	if _special_time > 0.0:
		_special_time -= delta
		var frames := _special_frames if not _special_frames.is_empty() else _attack_frames
		_advance_frames(frames, delta, 14.0, false)
		if _special_time <= 0.0:
			_anim_state = "attack" if attacking_base else "walk"
			_anim_time = 0.0
			_anim_frame = 0
		return
	if attacking_base:
		var frames := _attack_frames if not _attack_frames.is_empty() else _walk_frames
		_advance_frames(frames, delta, 7.5 if not boss else 6.0, true)
		return
	_advance_frames(_walk_frames, delta, 8.0 + speed * 0.018, true)

func play_special(duration := 0.42) -> void:
	if _dying:
		return
	_special_time = duration
	_anim_state = "special"
	_anim_time = 0.0
	_anim_frame = 0
	var frames := _special_frames if not _special_frames.is_empty() else _attack_frames
	if not frames.is_empty():
		$Sprite.texture = frames[0]

func _update_model_polish(delta: float) -> void:
	if _rank_aura:
		_rank_aura.rotation += delta * (0.75 if not boss else 0.42)
		var pulse := 0.92 + absf(sin(Time.get_ticks_msec() / (420.0 if not boss else 540.0))) * 0.16
		var base_scale := Vector2(0.34, 0.34) if not boss else Vector2(0.72, 0.72)
		_rank_aura.scale = base_scale * pulse
	if _status_aura and _status_aura.visible:
		_status_aura.rotation -= delta * 1.4
		var status_pulse := 0.86 + absf(sin(Time.get_ticks_msec() / 210.0)) * 0.22
		var status_scale := Vector2(0.24, 0.24) if not boss else Vector2(0.48, 0.48)
		_status_aura.scale = status_scale * status_pulse

func _update_status_aura() -> void:
	if _status_aura == null:
		return
	var active := _burn_time > 0.0 or _poison_time > 0.0 or _element_slow_time > 0.0 or _shock_time > 0.0
	_status_aura.visible = active
	_update_status_label()
	if not active:
		return
	if _shock_time > 0.0:
		_status_aura.modulate = Color(1.0, 0.92, 0.2, 0.42)
	elif _element_slow_time > 0.0:
		_status_aura.modulate = Color(0.48, 0.9, 1.0, 0.42)
	elif _burn_time > 0.0:
		_status_aura.modulate = Color(1.0, 0.36, 0.12, 0.42)
	elif _poison_time > 0.0:
		_status_aura.modulate = Color(0.42, 1.0, 0.25, 0.42)

func _update_status_label() -> void:
	if _status_label == null:
		return
	var tags: Array[String] = []
	var label_color := Color(0.78, 0.94, 1.0, 1.0)
	if shield_hp > 0.0:
		tags.append("盾")
		label_color = Color(0.48, 0.84, 1.0, 1.0)
	if armor_hits_left > 0 and not armor_broken:
		tags.append("甲")
		label_color = Color(0.96, 0.74, 0.42, 1.0)
	elif armor_broken and boss:
		tags.append("破甲")
		label_color = Color(1.0, 0.42, 0.28, 1.0)
	if _burn_time > 0.0:
		tags.append("燃")
		label_color = Color(1.0, 0.48, 0.16, 1.0)
	if _element_slow_time > 0.0:
		tags.append("冻")
		label_color = Color(0.55, 0.9, 1.0, 1.0)
	if _poison_time > 0.0:
		tags.append("毒")
		label_color = Color(0.52, 1.0, 0.26, 1.0)
	if _shock_time > 0.0:
		tags.append("电")
		label_color = Color(1.0, 0.9, 0.2, 1.0)
	_status_label.text = " ".join(tags)
	_status_label.visible = not tags.is_empty()
	_status_label.add_theme_color_override("font_color", label_color)

func _update_stride(delta: float) -> void:
	if _dying:
		return
	_stride_phase += delta * (4.4 + speed * 0.018) * speed_mult
	var sway: float = sin(_stride_phase) * (5.0 if not boss else 8.0)
	var bob: float = absf(sin(_stride_phase * 1.2)) * (4.0 if not boss else 6.0)
	$Sprite.position.x = _base_sprite_x + sway
	$Sprite.position.y = -bob

func _advance_frames(frames: Array[Texture2D], delta: float, fps: float, loop: bool) -> void:
	if frames.is_empty():
		return
	_anim_time += delta
	var frame_count := frames.size()
	var next_frame := int(_anim_time * fps)
	if loop:
		next_frame = next_frame % frame_count
	else:
		next_frame = min(next_frame, frame_count - 1)
	if next_frame != _anim_frame:
		_anim_frame = next_frame
		$Sprite.texture = frames[_anim_frame]

func targeting_snapshot() -> Dictionary:
	return {
		"position": global_position,
		"y": global_position.y,
		"breach_damage": breach_damage,
		"hp_ratio": hp / max_hp if max_hp > 0 else 0.0,
		"elite": elite,
		"boss": boss,
		"threat_tags": data.get("threat_tags", [])
	}
