extends Area2D

signal died(enemy: Node, reward: Dictionary)
signal breached(enemy: Node, damage: int)
signal hit_feedback(enemy: Node, element: String, immune_hit: bool, weak_hit: bool, hit_kind: String)
signal damage_dealt(enemy: Node, amount: float, element: String, crit_hit: bool, weak_hit: bool)

const BREACH_Y := 1500.0
const BASE_ATTACK_Y := 1435.0
const SequenceVfx := preload("res://gameplay/vfx/sequence_vfx.gd")

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
var gold_coef := 1.0
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
var _idle_frames: Array[Texture2D] = []
var _walk_frames: Array[Texture2D] = []
var _attack_frames: Array[Texture2D] = []
var _special_frames: Array[Texture2D] = []
var _hurt_frames: Array[Texture2D] = []
var _death_frames: Array[Texture2D] = []
var _anim_state := "walk"
var _anim_time := 0.0
var _anim_frame := 0
var _hurt_time := 0.0
var _hurt_duration := 0.18
var _attack_time := 0.0
var _attack_duration := 0.36
var _special_time := 0.0
var _dying := false
var _death_time := 0.0
var _stride_phase := 0.0
var _base_sprite_x := 0.0
var _base_sprite_scale := Vector2.ONE
var _hurt_recoil := Vector2.ZERO
var _burn_time := 0.0
var _burn_dps := 0.0
var _poison_time := 0.0
var _poison_dps := 0.0
var _element_slow_time := 0.0
var _element_slow_mult := 1.0
var _glacier_field_time := 0.0
var _glacier_field_base_scale := Vector2.ONE
var _shock_time := 0.0
var _last_hit_weak := false
var _last_hit_element := "physical"
var _last_hit_vfx_at := -99.0
# DoT floating-number accumulator. Each tick accumulates damage + time
# locally; only when the bucket trips a 0.5s window (or ≥5 dmg) do we
# emit one damage_dealt signal. Stops 60Hz stack-on-stack number spam
# while still keeping damage feedback visible.
const DOT_TICK_WINDOW := 0.5
const DOT_TICK_MIN_DMG := 5.0
var _dot_tick_acc: Dictionary = {}
var _hp_bg: ColorRect
var _hp_fill: ColorRect
var _status_aura: Sprite2D
var _glacier_aura: Sprite2D
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
	gold_coef = float(row.get("gold_coef", 1.0))
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
		shield_hp = max_hp * float(mechanic_params.get("shield_ratio", 0.35))
	var sprite_base_alpha := 0.82 if mechanic == "phase" or mechanic == "phase_shift" else 1.0
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
	_base_sprite_scale = $Sprite.scale
	_base_sprite_x = $Sprite.position.x
	modulate = Color.WHITE
	_base_modulate = Color(1, 1, 1, sprite_base_alpha)
	$Sprite.self_modulate = _base_modulate
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
		return "首领%s" % weak
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
		if _hurt_time <= 0.0 and _attack_time <= 0.0 and _special_time <= 0.0:
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
	_play_attack_animation(0.34)

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
	_play_attack_animation(0.36 if not boss else 0.48)
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
						threat_marker.text = "破甲"
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
		died.emit(self, {"gold": gold, "gold_coef": gold_coef, "xp": run_xp, "weak_kill": _last_hit_weak, "boss": boss, "death_element": _last_hit_element})
		if _death_frames.is_empty():
			call_deferred("queue_free")

func _emit_hit_feedback(element: String, immune_hit: bool, weak_hit: bool, hit_kind: String) -> void:
	hit_feedback.emit(self, element, immune_hit, weak_hit, hit_kind)

func _process_self_mechanic(delta: float) -> void:
	if mechanic == "regen" or mechanic == "regenerate":
		hp = min(max_hp, hp + max_hp * float(mechanic_params.get("regen_pct_per_sec", 0.025)) * delta)
		_update_hp_bar()
	elif mechanic == "enrage" and not enrage_triggered and hp <= max_hp * float(mechanic_params.get("trigger_hp_ratio", 0.5)):
		enrage_triggered = true
		speed *= float(mechanic_params.get("speed_mult", 1.35))
		breach_damage = int(round(float(breach_damage) * float(mechanic_params.get("damage_mult", 1.25))))
		_base_modulate = Color(1.0, 0.52, 0.32)
		_flash(_base_modulate)
	elif mechanic == "charge" and global_position.y > float(mechanic_params.get("trigger_y", 760.0)):
		speed_mult = max(speed_mult, 1.08)
	elif mechanic == "leap":
		var leap_wave: float = maxf(0.0, sin(_stride_phase * 1.6))
		speed_mult = max(speed_mult, 1.0 + leap_wave * float(mechanic_params.get("speed_wave", 0.32)))
	elif mechanic == "low_profile":
		external_damage_mult *= float(mechanic_params.get("damage_taken_mult", 0.92))
	elif mechanic == "juggernaut":
		external_damage_mult *= float(mechanic_params.get("damage_taken_mult", 0.86))
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

func apply_glacier_field(_source_damage: float, rank: int, bonus: float = 0.0, duration: float = 0.86, speed_factor: float = 0.4) -> void:
	if _dying:
		return
	var was_active := _glacier_field_time > 0.0
	_glacier_field_time = maxf(_glacier_field_time, duration)
	_element_slow_time = maxf(_element_slow_time, duration + 0.08)
	var ranked_slow: float = 0.66 - 0.035 * float(rank) - bonus
	var target_slow: float = minf(speed_factor, ranked_slow)
	if boss:
		target_slow = maxf(target_slow, speed_factor)
	_element_slow_mult = minf(_element_slow_mult, clampf(target_slow, 0.36 if not boss else 0.58, 0.86))
	if not was_active:
		_flash(Color(0.62, 0.94, 1.0))
	_update_status_aura()

func is_controlled() -> bool:
	return _element_slow_time > 0.0 or _glacier_field_time > 0.0 or _shock_time > 0.0

func is_glacier_field_active() -> bool:
	return _glacier_field_time > 0.0

func has_element_status(element: String) -> bool:
	match element:
		"fire":
			return _burn_time > 0.0
		"ice":
			return _element_slow_time > 0.0 or _glacier_field_time > 0.0
		"lightning":
			return _shock_time > 0.0
		"poison":
			return _poison_time > 0.0
		_:
			return false

func _process_element_status(delta: float) -> void:
	if _burn_time > 0.0:
		_burn_time -= delta
		_accumulate_dot_damage("fire", _burn_dps * delta, delta)
	if _poison_time > 0.0:
		_poison_time -= delta
		_accumulate_dot_damage("poison", _poison_dps * delta, delta)
	if _element_slow_time > 0.0:
		_element_slow_time -= delta
		speed_mult *= _element_slow_mult
	else:
		_element_slow_mult = 1.0
	if _glacier_field_time > 0.0:
		_glacier_field_time -= delta
	if _shock_time > 0.0:
		_shock_time -= delta
		speed_mult *= 0.55 if not boss else 0.75
	_update_status_aura()

# Accumulates per-element DoT damage into a small bucket. The previous
# implementation called _apply_status_damage every frame, which both
# (a) lerp'd the sprite modulate toward the status color every frame so
# bosses looked like a permanent red flash, and (b) emitted one floating
# damage number per frame, so a 2s burn produced ~120 stacked digits
# nobody could read. Now we collect into a 0.5s window and emit at most
# one number per window, color-coded by element via damage_number_layer.
func _accumulate_dot_damage(element: String, amount: float, delta: float) -> void:
	if amount <= 0.0:
		return
	if not _dot_tick_acc.has(element):
		_dot_tick_acc[element] = {"dmg": 0.0, "time": 0.0}
	var bucket: Dictionary = _dot_tick_acc[element]
	bucket["dmg"] = float(bucket.get("dmg", 0.0)) + amount
	bucket["time"] = float(bucket.get("time", 0.0)) + delta
	if float(bucket["time"]) < DOT_TICK_WINDOW and float(bucket["dmg"]) < DOT_TICK_MIN_DMG:
		return
	_dot_tick_acc.erase(element)
	_apply_status_damage(float(bucket["dmg"]), element)

func _apply_status_damage(amount: float, element: String) -> void:
	if _dying or amount <= 0.0:
		return
	hp -= amount
	_update_hp_bar()
	damage_dealt.emit(self, amount, element, false, false)
	if hp <= 0.0:
		_dying = true
		_anim_state = "death"
		_anim_time = 0.0
		_anim_frame = 0
		$CollisionShape2D.set_deferred("disabled", true)
		died.emit(self, {"gold": gold, "gold_coef": gold_coef, "xp": run_xp, "weak_kill": false, "boss": boss})
		if _death_frames.is_empty():
			call_deferred("queue_free")

func _flash(color: Color) -> void:
	if boss:
		return
	var flash_color := Color(color.r, color.g, color.b, _base_modulate.a)
	$Sprite.self_modulate = flash_color
	var tween := create_tween()
	tween.tween_property($Sprite, "self_modulate", _base_modulate, 0.18)

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
	_glacier_aura = Sprite2D.new()
	_glacier_aura.name = "GlacierAura"
	_glacier_aura.texture = load("res://assets/production/sprites/vfx/vfx_freeze.png")
	_glacier_aura.position = Vector2(0, -42 if not boss else -84)
	_glacier_field_base_scale = Vector2(0.28, 0.28) if not boss else Vector2(0.52, 0.52)
	_glacier_aura.scale = _glacier_field_base_scale
	_glacier_aura.z_index = 2
	_glacier_aura.modulate = Color(0.62, 0.95, 1.0, 0.58)
	_glacier_aura.visible = false
	add_child(_glacier_aura)

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
	_hurt_duration = 0.2 if not boss else 0.16
	_hurt_time = _hurt_duration
	_anim_state = "hurt"
	_anim_time = 0.0
	_anim_frame = 0
	_hurt_recoil = Vector2(randf_range(-14.0, 14.0), -18.0 if not boss else -26.0)
	if not _hurt_frames.is_empty():
		$Sprite.texture = _hurt_frames[0]
	_flash(Color(1, 0.4, 0.4))
	_spawn_hit_vfx(element)

func _spawn_hit_vfx(element := "physical") -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if not boss and now - _last_hit_vfx_at < 0.055:
		return
	_last_hit_vfx_at = now
	if _local_transient_vfx_count() >= (8 if boss else 4):
		return
	var hit := SequenceVfx.new()
	hit.set_meta("enemy_transient_vfx", true)
	add_child(hit)
	var sequence_id := _hit_vfx_sequence_id(element)
	var scale := 0.34 if not boss else 0.56
	var position_offset := Vector2(randf_range(-12.0, 12.0), -38.0 if not boss else -72.0)
	if not hit.setup(sequence_id, global_position + position_offset, scale, Color(1, 1, 1, 0.9), 1.28, randf_range(-0.34, 0.34), 1.12, Vector2(0, -14), randf_range(-0.28, 0.28)):
		hit.queue_free()

func _spawn_crit_vfx(color: Color) -> void:
	if _local_transient_vfx_count() >= (10 if boss else 5):
		return
	var crit := SequenceVfx.new()
	crit.set_meta("enemy_transient_vfx", true)
	add_child(crit)
	var scale := 0.46 if not boss else 0.78
	var position_offset := Vector2(randf_range(-18.0, 18.0), -42.0 if not boss else -76.0)
	if not crit.setup("vfx_crit", global_position + position_offset, scale, color, 1.32, randf_range(-0.28, 0.28), 1.2, Vector2(0, -28), randf_range(-0.35, 0.35)):
		crit.queue_free()

func _local_transient_vfx_count() -> int:
	var count := 0
	for child in get_children():
		if child.has_meta("enemy_transient_vfx") and not child.is_queued_for_deletion():
			count += 1
	return count

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

func _hit_vfx_sequence_id(element: String) -> String:
	match element:
		"fire":
			return "vfx_hit_fire"
		"ice":
			return "vfx_hit_ice"
		"lightning":
			return "vfx_hit_lightning"
		"poison":
			return "vfx_hit_poison"
		_:
			return "vfx_hit_physical"

func _load_animation_frames(row: Dictionary, is_boss: bool) -> void:
	var sprite_path: String = row.get("sprite", "")
	var entity_id := sprite_path.get_file().get_basename().replace("_prototype", "")
	var family := "bosses" if is_boss else "zombies"
	var base := "res://assets/production/sprites/animations/%s/%s/%s" % [family, entity_id, entity_id]
	_idle_frames = _load_frame_set(base, "idle", 4)
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
		_update_hurt_pose()
		if _hurt_time <= 0.0:
			_anim_state = "walk"
			_anim_time = 0.0
			_anim_frame = 0
		return
	if _special_time > 0.0:
		_special_time -= delta
		var frames := _special_frames if not _special_frames.is_empty() else _attack_frames
		_advance_frames(frames, delta, 14.0, false)
		_update_special_pose()
		if _special_time <= 0.0:
			_anim_state = "attack" if attacking_base else "walk"
			_anim_time = 0.0
			_anim_frame = 0
		return
	if _attack_time > 0.0:
		_attack_time -= delta
		var frames := _attack_frames if not _attack_frames.is_empty() else _walk_frames
		_advance_frames(frames, delta, 15.0 if not boss else 12.0, false)
		_update_attack_pose()
		if _attack_time <= 0.0:
			_anim_state = "attack" if attacking_base else "walk"
			_anim_time = 0.0
			_anim_frame = 0
		return
	if attacking_base:
		var frames := _attack_frames if not _attack_frames.is_empty() else _idle_frames
		if frames.is_empty():
			frames = _walk_frames
		_advance_frames(frames, delta, 4.5 if not boss else 3.8, true)
		_update_base_attack_idle_pose()
		return
	var walk_frames := _walk_frames if not _walk_frames.is_empty() else _idle_frames
	_advance_frames(walk_frames, delta, 8.0 + speed * 0.018, true)

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

func _play_attack_animation(duration := 0.36) -> void:
	if _dying:
		return
	_attack_duration = duration
	_attack_time = duration
	_anim_state = "attack"
	_anim_time = 0.0
	_anim_frame = 0
	if not _attack_frames.is_empty():
		$Sprite.texture = _attack_frames[0]

func _update_hurt_pose() -> void:
	var ratio := clampf(_hurt_time / maxf(_hurt_duration, 0.001), 0.0, 1.0)
	$Sprite.position = _hurt_recoil * ratio
	$Sprite.scale = _base_sprite_scale * (1.0 + 0.04 * ratio)
	$Sprite.rotation = deg_to_rad(4.0 * ratio * (1.0 if _hurt_recoil.x >= 0.0 else -1.0))

func _update_attack_pose() -> void:
	var progress := 1.0 - clampf(_attack_time / maxf(_attack_duration, 0.001), 0.0, 1.0)
	var lunge := sin(progress * PI)
	var heavy := 1.3 if boss else 1.0
	$Sprite.position = Vector2(_base_sprite_x + sin(progress * TAU) * 3.0 * heavy, lunge * 18.0 * heavy)
	$Sprite.scale = _base_sprite_scale * (1.0 + 0.055 * lunge)
	$Sprite.rotation = deg_to_rad(sin(progress * PI * 2.0) * 2.5)

func _update_special_pose() -> void:
	var pulse := absf(sin(Time.get_ticks_msec() / 80.0))
	var heavy := 1.2 if boss else 1.0
	$Sprite.position = Vector2(_base_sprite_x + sin(Time.get_ticks_msec() / 95.0) * 4.0 * heavy, -5.0 * pulse)
	$Sprite.scale = _base_sprite_scale * (1.0 + 0.04 * pulse)
	$Sprite.rotation = deg_to_rad(sin(Time.get_ticks_msec() / 130.0) * 2.0)

func _update_base_attack_idle_pose() -> void:
	var pulse := absf(sin(Time.get_ticks_msec() / (260.0 if not boss else 340.0)))
	var sway := sin(Time.get_ticks_msec() / (320.0 if not boss else 420.0)) * (3.5 if not boss else 6.0)
	$Sprite.position = Vector2(_base_sprite_x + sway, pulse * (5.0 if not boss else 8.0))
	$Sprite.scale = _base_sprite_scale * (1.0 + 0.025 * pulse)
	$Sprite.rotation = deg_to_rad(sway * 0.32)

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
	if _glacier_aura and _glacier_aura.visible:
		_glacier_aura.rotation += delta * (1.05 if not boss else 0.72)
		var glacier_pulse := 0.9 + absf(sin(Time.get_ticks_msec() / 180.0)) * 0.16
		_glacier_aura.scale = _glacier_field_base_scale * glacier_pulse

func _update_status_aura() -> void:
	if _status_aura == null:
		return
	var glacier_active := _glacier_field_time > 0.0
	if _glacier_aura:
		_glacier_aura.visible = glacier_active
	var active := _burn_time > 0.0 or _poison_time > 0.0 or _element_slow_time > 0.0 or _shock_time > 0.0 or glacier_active
	_status_aura.visible = active
	_update_status_label()
	if not active:
		return
	if glacier_active:
		_status_aura.modulate = Color(0.56, 0.92, 1.0, 0.52)
	elif _shock_time > 0.0:
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
	$Sprite.scale = _base_sprite_scale * Vector2(1.0 + bob * 0.004, 1.0 - bob * 0.002)
	$Sprite.rotation = deg_to_rad(sway * 0.22)

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
