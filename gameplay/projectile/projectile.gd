extends Area2D

signal split_requested(origin: Vector2, direction: Vector2, count: int, damage: float, element: String)
signal hit_confirmed(target: Node, origin: Vector2, damage: float, element: String, splash_radius: float, cloud_radius: float, chain_depth: int, visual_profile: String)

const VfxLib := preload("res://gameplay/vfx/vfx_lib.gd")

const SPRITE_FORWARD_ANGLE := 0.0
const PROJECTILE_SPEED_MULTIPLIER := 0.5
const PIERCE_SWEEP_RANGE := 420.0
const PIERCE_SWEEP_HALF_WIDTH := 92.0
const MAX_LAYER_TRAIL_FX := 110
const MAX_LAYER_HIT_FX := 150

var velocity := Vector2.ZERO
var damage := 10.0
var element := "physical"
var pierce_left := 0
var split_count := 0
var split_falloff := 0.55
var homing_strength := 0.0
var splash_radius := 0.0
var cloud_radius := 0.0
var visual_scale := 1.0
var visual_profile := ""
var trail_timer := 0.0
var trail_interval := 0.028
var lifetime := 0.0
var chain_depth := 0
var texture_override_path := ""
var hit_target_ids := {}
var _flight_trail: Node
var _projectile_vfx_ready := false

func setup(origin: Vector2, direction: Vector2, speed: float, dmg: float, elem := "physical", pierce := 0, split := 0, falloff := 0.55, homing := 0.0, splash := 0.0, cloud := 0.0, scale_mult := 1.0, chain_depth_value := 0, texture_override := "", profile := "") -> void:
	global_position = origin
	var flight_direction := direction.normalized()
	velocity = flight_direction * speed * PROJECTILE_SPEED_MULTIPLIER
	rotation = flight_direction.angle() - SPRITE_FORWARD_ANGLE
	damage = dmg
	element = elem
	pierce_left = pierce
	split_count = split
	split_falloff = falloff
	homing_strength = homing
	splash_radius = splash
	cloud_radius = cloud
	visual_scale = clampf(scale_mult, 0.72, 1.75)
	texture_override_path = texture_override
	visual_profile = _resolved_visual_profile(profile, texture_override_path)
	chain_depth = chain_depth_value
	hit_target_ids = {}
	_projectile_vfx_ready = false
	var texture_path := texture_override_path if texture_override_path != "" else _projectile_texture_path(element, visual_profile)
	$Sprite.texture = load(texture_path)
	$Sprite.scale = _projectile_sprite_scale(visual_profile) * visual_scale
	$Sprite.modulate = _projectile_sprite_color(element, visual_profile)
	$CollisionShape2D.shape = CircleShape2D.new()
	$CollisionShape2D.shape.radius = 18.0 * maxf(visual_scale, 0.85) * _collision_radius_mult(visual_profile)
	trail_interval = _trail_interval_for(visual_profile)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if is_inside_tree():
		_configure_projectile_vfx()

func _ready() -> void:
	_configure_projectile_vfx()

func _physics_process(delta: float) -> void:
	lifetime += delta
	_apply_homing(delta)
	position += velocity * delta
	if velocity.length_squared() > 1.0:
		rotation = velocity.angle() - SPRITE_FORWARD_ANGLE
	_process_trail(delta)
	if position.y < -80 or position.y > 2020 or position.x < -80 or position.x > 1160:
		queue_free()

func _apply_homing(delta: float) -> void:
	if homing_strength <= 0.0:
		return
	var target := _nearest_enemy()
	if target == null:
		return
	var speed := velocity.length()
	if speed <= 0.0:
		return
	# 只转方向、保持速度（用 lerp 直接混合等长向量会缩短结果，导致追踪弹越转越慢最后卡住）。
	var desired_dir := (target.global_position - global_position).normalized()
	var new_dir := velocity.normalized().lerp(desired_dir, clampf(homing_strength * delta, 0.0, 0.32)).normalized()
	if new_dir.length_squared() <= 0.0:
		return
	velocity = new_dir * speed

func _nearest_enemy() -> Node2D:
	var best: Node2D
	var best_dist := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		var enemy_node := enemy as Node2D
		if enemy_node.global_position.y > 1540.0:
			continue
		var dist := global_position.distance_squared_to(enemy_node.global_position)
		if dist < best_dist:
			best = enemy_node
			best_dist = dist
	return best

func _process_trail(delta: float) -> void:
	trail_timer -= delta
	if trail_timer > 0.0:
		return
	trail_timer = trail_interval
	_spawn_trail_particle_pulse(0.34)

func _configure_projectile_vfx() -> void:
	if _projectile_vfx_ready or $Sprite.texture == null:
		return
	_projectile_vfx_ready = true
	$Sprite.material = _new_additive_material()
	_build_energy_halo()
	_build_energy_core()
	_spawn_vfxlib_trail()
	_spawn_trail_particle_pulse(0.72)

func _build_energy_halo() -> void:
	var halo := Sprite2D.new()
	halo.name = "EnergyHalo"
	halo.texture = VfxLib.RADIAL_GLOW_TEXTURE
	halo.centered = true
	halo.z_index = -1
	halo.material = _new_additive_material()
	var color := _projectile_color(element, visual_profile)
	color.a = _halo_alpha_for(visual_profile)
	halo.modulate = color
	var halo_size := _halo_size_for(visual_profile) * visual_scale
	halo.scale = Vector2(
		halo_size.x / float(VfxLib.RADIAL_GLOW_TEXTURE.get_width()),
		halo_size.y / float(VfxLib.RADIAL_GLOW_TEXTURE.get_height())
	)
	add_child(halo)
	var target_scale := halo.scale
	halo.scale = target_scale * 0.72
	var tween := halo.create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(halo, "scale", target_scale, 0.09)

func _build_energy_core() -> void:
	var core := Sprite2D.new()
	core.name = "EnergyCore"
	core.texture = VfxLib.RADIAL_GLOW_TEXTURE
	core.centered = true
	core.z_index = 2
	var core_material := ShaderMaterial.new()
	core_material.shader = VfxLib.GLOW_CORE_SHADER
	var core_color := _projectile_color(element, visual_profile).lightened(0.34)
	core_color.a = 0.94
	core_material.set_shader_parameter("tint", core_color)
	core_material.set_shader_parameter("intensity", _core_intensity_for(visual_profile))
	core_material.set_shader_parameter("core_power", _core_power_for(visual_profile))
	core.material = core_material
	var core_size := _core_size_for(visual_profile) * visual_scale
	core.scale = Vector2(
		core_size.x / float(VfxLib.RADIAL_GLOW_TEXTURE.get_width()),
		core_size.y / float(VfxLib.RADIAL_GLOW_TEXTURE.get_height())
	)
	add_child(core)

func _spawn_vfxlib_trail() -> void:
	if get_parent() == null or not _can_spawn_projectile_fx():
		return
	var color := _trail_color_for(element, visual_profile)
	color.a = _trail_alpha_for(visual_profile)
	_flight_trail = VfxLib.spawn_trail(self, color, _trail_width_for(visual_profile) * maxf(visual_scale, 0.85))
	if _flight_trail == null:
		return
	_track_transient_fx(_flight_trail)
	_flight_trail.set("max_points", _trail_point_count_for(visual_profile))
	_flight_trail.set("min_point_distance", _trail_point_distance_for(visual_profile))

func _spawn_trail_particle_pulse(alpha: float) -> void:
	var parent := get_parent()
	if parent == null or velocity.length_squared() <= 1.0:
		return
	if not _can_spawn_projectile_fx() or not _can_spawn_transient_fx(MAX_LAYER_TRAIL_FX):
		return
	var dir := velocity.normalized()
	var color := _particle_color_for(element, visual_profile)
	color.a = clampf(alpha * _particle_alpha_for(visual_profile), 0.08, 0.72)
	var burst := VfxLib.spawn_particles(
		parent,
		global_position - dir * _particle_offset_for(visual_profile),
		color,
		_trail_particle_amount_for(element, visual_profile),
		_trail_particle_speed_for(element, visual_profile),
		_trail_particle_spread_for(element, visual_profile),
		_trail_particle_lifetime_for(element, visual_profile)
	)
	if burst == null:
		return
	_track_transient_fx(burst)
	if burst is Node2D:
		var burst_node := burst as Node2D
		burst_node.rotation = dir.angle() + PI
		burst_node.z_index = maxi(z_index - 1, 0)

func _resolved_visual_profile(profile: String, texture_override := "") -> String:
	if profile != "":
		return profile
	if texture_override.contains("proj_split"):
		return "split"
	if texture_override.contains("proj_heavy"):
		return "heavy"
	if texture_override.contains("proj_acid"):
		return "acid"
	return ""

func _element_color(elem: String) -> Color:
	match elem:
		"fire":
			return Color(1.0, 0.34, 0.10, 1.0)
		"ice":
			return Color(0.48, 0.92, 1.0, 1.0)
		"lightning":
			return Color(0.66, 0.92, 1.0, 1.0)
		"poison":
			return Color(0.44, 1.0, 0.24, 1.0)
		_:
			return Color(1.0, 0.86, 0.34, 1.0)

func _projectile_color(elem: String, profile := "") -> Color:
	match profile:
		"rail":
			return Color(0.62, 0.96, 1.0, 1.0)
		"scatter":
			return Color(1.0, 0.76, 0.28, 1.0)
		"plasma":
			return Color(0.94, 0.46, 1.0, 1.0)
		"split":
			return _element_color(elem).lightened(0.16)
		"heavy":
			return Color(1.0, 0.66, 0.18, 1.0)
		"acid":
			return Color(0.46, 1.0, 0.18, 1.0)
	return _element_color(elem)

func _projectile_sprite_color(_elem: String, _profile := "") -> Color:
	return Color.WHITE

func _projectile_texture_path(elem: String, profile := "") -> String:
	match profile:
		"rail":
			return "res://assets/production/sprites/projectiles/proj_rail_slug.png"
		"scatter":
			return "res://assets/production/sprites/projectiles/proj_scatter_pellet.png"
		"plasma":
			return "res://assets/production/sprites/projectiles/proj_plasma_orb.png"
		"split":
			return "res://assets/production/sprites/projectiles/proj_split_mini.png"
		"heavy":
			return "res://assets/production/sprites/projectiles/proj_heavy_charge.png"
		"acid":
			return "res://assets/production/sprites/projectiles/proj_acid_spit.png"
	match elem:
		"fire":
			return "res://assets/production/sprites/projectiles/proj_bullet_fire.png"
		"ice":
			return "res://assets/production/sprites/projectiles/proj_bullet_ice.png"
		"lightning":
			return "res://assets/production/sprites/projectiles/proj_bullet_lightning.png"
		"poison":
			return "res://assets/production/sprites/projectiles/proj_bullet_poison.png"
		_:
			return "res://assets/production/sprites/projectiles/proj_bullet_physical.png"

func _projectile_sprite_scale(profile := "") -> Vector2:
	# 子弹视觉整体缩小约 28%（仅视觉，碰撞箱不变）。
	match profile:
		"rail":
			return Vector2(0.52, 0.17)
		"scatter":
			return Vector2(0.18, 0.18)
		"plasma":
			return Vector2(0.40, 0.40)
		"split":
			return Vector2(0.22, 0.22)
		"heavy":
			return Vector2(0.40, 0.34)
		"acid":
			return Vector2(0.34, 0.30)
		_:
			return Vector2(0.30, 0.30)

func _collision_radius_mult(profile := "") -> float:
	match profile:
		"scatter":
			return 0.7
		"plasma":
			return 1.15
		_:
			return 1.0

func _trail_interval_for(profile := "") -> float:
	match profile:
		"rail":
			return 0.016
		"scatter":
			return 0.046
		"plasma":
			return 0.022
		"split":
			return 0.038
		"heavy":
			return 0.02
		"acid":
			return 0.034
		_:
			return 0.028

func _trail_length_for(profile := "") -> float:
	match profile:
		"rail":
			return 132.0
		"scatter":
			return 38.0
		"plasma":
			return 78.0
		"split":
			return 46.0
		"heavy":
			return 94.0
		"acid":
			return 58.0
		_:
			return 64.0

func _trail_width_for(profile := "") -> float:
	match profile:
		"rail":
			return 10.0
		"scatter":
			return 5.0
		"plasma":
			return 14.0
		"split":
			return 5.6
		"heavy":
			return 13.0
		"acid":
			return 8.0
		_:
			return 9.0

func _trail_color_for(elem: String, profile := "") -> Color:
	var color := _projectile_color(elem, profile)
	match profile:
		"rail":
			return Color(0.72, 1.0, 1.0, 1.0)
		"plasma":
			return Color(1.0, 0.48, 0.92, 1.0)
		"acid":
			return Color(0.44, 1.0, 0.2, 1.0)
		_:
			return color

func _particle_color_for(elem: String, profile := "") -> Color:
	match profile:
		"plasma":
			return Color(1.0, 0.56, 0.20, 1.0)
		"rail":
			return Color(0.82, 1.0, 1.0, 1.0)
		"acid":
			return Color(0.54, 1.0, 0.16, 1.0)
	match elem:
		"fire":
			return Color(1.0, 0.48, 0.12, 1.0)
		"ice":
			return Color(0.72, 0.98, 1.0, 1.0)
		"lightning":
			return Color(0.88, 0.98, 1.0, 1.0)
		"poison":
			return Color(0.48, 1.0, 0.22, 1.0)
		_:
			return Color(1.0, 0.9, 0.42, 1.0)

func _halo_size_for(profile := "") -> Vector2:
	match profile:
		"rail":
			return Vector2(196.0, 42.0)
		"scatter":
			return Vector2(48.0, 48.0)
		"plasma":
			return Vector2(146.0, 146.0)
		"split":
			return Vector2(54.0, 42.0)
		"heavy":
			return Vector2(126.0, 92.0)
		"acid":
			return Vector2(92.0, 70.0)
		_:
			return Vector2(88.0, 62.0)

func _core_size_for(profile := "") -> Vector2:
	match profile:
		"rail":
			return Vector2(82.0, 18.0)
		"scatter":
			return Vector2(24.0, 24.0)
		"plasma":
			return Vector2(66.0, 66.0)
		"split":
			return Vector2(26.0, 22.0)
		"heavy":
			return Vector2(58.0, 42.0)
		"acid":
			return Vector2(42.0, 34.0)
		_:
			return Vector2(38.0, 30.0)

func _halo_alpha_for(profile := "") -> float:
	match profile:
		"scatter":
			return 0.34
		"rail":
			return 0.46
		"plasma":
			return 0.58
		"heavy":
			return 0.52
		_:
			return 0.42

func _trail_alpha_for(profile := "") -> float:
	match profile:
		"rail":
			return 0.78
		"plasma":
			return 0.72
		"scatter":
			return 0.52
		"split":
			return 0.58
		_:
			return 0.64

func _particle_alpha_for(profile := "") -> float:
	match profile:
		"plasma":
			return 0.82
		"rail":
			return 0.54
		"scatter":
			return 0.48
		_:
			return 0.68

func _core_intensity_for(profile := "") -> float:
	match profile:
		"rail":
			return 3.35
		"scatter":
			return 2.45
		"plasma":
			return 4.25
		"heavy":
			return 3.65
		"acid":
			return 2.95
		_:
			return 2.85

func _core_power_for(profile := "") -> float:
	match profile:
		"rail":
			return 1.85
		"plasma":
			return 0.78
		"heavy":
			return 1.05
		"acid":
			return 1.18
		_:
			return 1.32

func _trail_point_count_for(profile := "") -> int:
	match profile:
		"rail":
			return 14
		"plasma":
			return 14
		"heavy":
			return 13
		"scatter":
			return 8
		"split":
			return 9
		_:
			return 11

func _trail_point_distance_for(profile := "") -> float:
	match profile:
		"rail":
			return 10.0
		"plasma":
			return 6.0
		"scatter":
			return 9.0
		"split":
			return 8.0
		_:
			return 7.0

func _trail_particle_amount_for(elem: String, profile := "") -> int:
	match profile:
		"plasma":
			return 6
		"heavy":
			return 5
		"scatter":
			return 2
		"rail":
			return 2
		"split":
			return 2
		"acid":
			return 4
	match elem:
		"fire":
			return 5
		"ice":
			return 3
		"lightning":
			return 3
		"poison":
			return 4
		_:
			return 3

func _trail_particle_speed_for(elem: String, profile := "") -> float:
	match profile:
		"rail":
			return 460.0
		"plasma":
			return 250.0
		"scatter":
			return 180.0
		"heavy":
			return 320.0
		"acid":
			return 135.0
	match elem:
		"fire":
			return 310.0
		"ice":
			return 220.0
		"lightning":
			return 380.0
		"poison":
			return 145.0
		_:
			return 285.0

func _trail_particle_spread_for(elem: String, profile := "") -> float:
	match profile:
		"rail":
			return 12.0
		"plasma":
			return 58.0
		"scatter":
			return 42.0
		"acid":
			return 72.0
	match elem:
		"fire":
			return 46.0
		"ice":
			return 24.0
		"lightning":
			return 18.0
		"poison":
			return 68.0
		_:
			return 28.0

func _trail_particle_lifetime_for(elem: String, profile := "") -> float:
	match profile:
		"rail":
			return 0.1
		"scatter":
			return 0.11
		"plasma":
			return 0.22
		"acid":
			return 0.28
	match elem:
		"fire":
			return 0.16
		"ice":
			return 0.18
		"lightning":
			return 0.1
		"poison":
			return 0.28
		_:
			return 0.13

func _particle_offset_for(profile := "") -> float:
	match profile:
		"rail":
			return 44.0
		"plasma":
			return 30.0
		"scatter":
			return 15.0
		"split":
			return 18.0
		_:
			return 24.0

func _on_body_entered(body: Node) -> void:
	_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_hit(area)

func _hit(target: Node) -> void:
	if not target.has_method("take_damage"):
		return
	var target_id := target.get_instance_id()
	if hit_target_ids.has(target_id):
		return
	hit_target_ids[target_id] = true
	var hit_origin := global_position
	var flight_direction := velocity.normalized()
	target.take_damage(damage, element)
	_spawn_impact_flash()
	hit_confirmed.emit(target, hit_origin, damage, element, splash_radius, cloud_radius, chain_depth, visual_profile)
	if split_count > 0:
		split_requested.emit(hit_origin, flight_direction, split_count, damage * split_falloff, element)
	if pierce_left <= 0:
		queue_free()
	else:
		var pass_throughs_before := pierce_left
		var swept_hits := _apply_pierce_sweep(target, hit_origin, flight_direction, pass_throughs_before)
		var remaining_pass_throughs := pass_throughs_before - swept_hits - 1
		if remaining_pass_throughs < 0:
			queue_free()
		else:
			pierce_left = remaining_pass_throughs
			global_position = hit_origin + flight_direction * (52.0 + 24.0 * float(swept_hits))
			_spawn_pierce_flash()

func _apply_pierce_sweep(primary: Node, origin: Vector2, direction: Vector2, max_hits: int) -> int:
	if max_hits <= 0 or direction.length_squared() <= 0.0:
		return 0
	var candidates: Array = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == primary or not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		if not enemy.has_method("take_damage"):
			continue
		var enemy_node := enemy as Node2D
		var enemy_id := enemy_node.get_instance_id()
		if hit_target_ids.has(enemy_id):
			continue
		var to_enemy: Vector2 = enemy_node.global_position - origin
		var forward := to_enemy.dot(direction)
		if forward <= 18.0 or forward > PIERCE_SWEEP_RANGE:
			continue
		var lateral := absf(to_enemy.cross(direction))
		if lateral > _pierce_sweep_half_width(enemy_node):
			continue
		candidates.append({"enemy": enemy_node, "forward": forward})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("forward", 0.0)) < float(b.get("forward", 0.0))
	)
	var hits := 0
	var trace_start := origin
	for candidate in candidates:
		if hits >= max_hits:
			break
		var enemy_node := candidate.get("enemy") as Node2D
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		var enemy_id := enemy_node.get_instance_id()
		if hit_target_ids.has(enemy_id):
			continue
		hit_target_ids[enemy_id] = true
		var hit_pos := enemy_node.global_position
		_spawn_pierce_trace(trace_start, hit_pos)
		enemy_node.take_damage(damage, element)
		_spawn_impact_flash_at(hit_pos)
		hit_confirmed.emit(enemy_node, hit_pos, damage, element, splash_radius, cloud_radius, chain_depth, visual_profile)
		trace_start = hit_pos
		hits += 1
	return hits

func _pierce_sweep_half_width(enemy: Node2D) -> float:
	var width := PIERCE_SWEEP_HALF_WIDTH * maxf(visual_scale, 0.9)
	var boss_value: Variant = enemy.get("boss")
	if boss_value is bool and bool(boss_value):
		width = maxf(width, 150.0)
	return width

func _spawn_impact_flash() -> void:
	_spawn_impact_flash_at(global_position)

func _spawn_impact_flash_at(at_position: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return
	if not _can_spawn_transient_fx(MAX_LAYER_HIT_FX):
		return
	var flash := Sprite2D.new()
	_track_transient_fx(flash)
	flash.texture = load(_impact_vfx_path(element, visual_profile))
	flash.global_position = at_position
	flash.rotation = randf_range(-0.45, 0.45)
	var scale_mult := 0.62 if visual_profile == "plasma" else 0.36 if visual_profile == "scatter" else 0.5 if visual_profile == "rail" else 0.44
	flash.scale = Vector2(scale_mult, scale_mult) * visual_scale
	flash.modulate = _projectile_color(element, visual_profile)
	parent.add_child(flash)
	var tween := flash.create_tween()
	tween.parallel().tween_property(flash, "scale", flash.scale * 1.62, 0.18)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.18)
	tween.tween_callback(flash.queue_free)

func _spawn_pierce_flash() -> void:
	var parent := get_parent()
	if parent == null:
		return
	if not _can_spawn_transient_fx(MAX_LAYER_HIT_FX):
		return
	var ring := Sprite2D.new()
	_track_transient_fx(ring)
	ring.texture = load("res://assets/production/sprites/vfx/vfx_crit.png")
	ring.global_position = global_position
	ring.rotation = velocity.angle()
	ring.scale = Vector2(0.24, 0.24)
	ring.modulate = Color(1.0, 0.95, 0.55, 0.65)
	parent.add_child(ring)
	var tween := ring.create_tween()
	tween.parallel().tween_property(ring, "scale", Vector2(0.56, 0.56), 0.12)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.12)
	tween.tween_callback(ring.queue_free)

func _spawn_pierce_trace(from: Vector2, to: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return
	if not _can_spawn_transient_fx(MAX_LAYER_HIT_FX):
		return
	var parent_node := parent as Node2D
	var start := parent_node.to_local(from) if parent_node != null else from
	var finish := parent_node.to_local(to) if parent_node != null else to
	var trace := Line2D.new()
	_track_transient_fx(trace)
	trace.width = 18.0 * maxf(visual_scale, 0.85)
	trace.default_color = Color(0.62, 0.98, 1.0, 0.72) if visual_profile == "rail" else Color(1.0, 0.9, 0.36, 0.58)
	trace.points = PackedVector2Array([start, finish])
	parent.add_child(trace)
	var tween := trace.create_tween()
	tween.parallel().tween_property(trace, "width", 3.0, 0.16)
	tween.parallel().tween_property(trace, "modulate:a", 0.0, 0.16)
	tween.tween_callback(trace.queue_free)

func _new_additive_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return material

func _can_spawn_projectile_fx(priority := false) -> bool:
	var battle := _battle_node()
	if battle != null and battle.has_method("_can_spawn_projectile_fx"):
		return bool(battle.call("_can_spawn_projectile_fx", priority))
	return _can_spawn_transient_fx(MAX_LAYER_HIT_FX if priority else MAX_LAYER_TRAIL_FX)

func _battle_node() -> Node:
	var node := get_parent()
	while node != null:
		if node.has_method("_can_spawn_projectile_fx"):
			return node
		node = node.get_parent()
	return null

func _track_transient_fx(node: Node) -> void:
	node.set_meta("transient_vfx", true)

func _can_spawn_transient_fx(limit: int) -> bool:
	var parent := get_parent()
	if parent == null:
		return true
	var count := 0
	for child in parent.get_children():
		if child.has_meta("transient_vfx") and not child.is_queued_for_deletion():
			count += 1
			if count >= limit:
				return false
	return true

func _impact_vfx_path(elem: String, profile := "") -> String:
	match profile:
		"rail":
			return "res://assets/production/sprites/vfx/vfx_crit.png"
		"scatter":
			return "res://assets/production/sprites/vfx/vfx_hit_physical.png"
		"plasma":
			return "res://assets/production/sprites/vfx/vfx_explosion_fire.png"
	match elem:
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
