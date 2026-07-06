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
# 追踪弹：出膛后必须先直飞 1 秒，形成清楚的枪管弹道，再进入导引。
const HOMING_ACTIVATION_DELAY := 1.0
# 追踪弹转向速率上限(弧度/秒)，按 homing_strength 线性给速率，同时受最小转弯半径约束。
# 不再用"每帧朝目标方向 lerp"的软插值(那样在角度接近180°时能几帧内掉头，看起来像瞬间转弯)。
const HOMING_TURN_RATE_PER_STRENGTH := 1.6  # rad/sec，每点 homing_strength 贡献的转向速率
const HOMING_MIN_TURN_RADIUS := 460.0  # px，保证追踪弹是大弧线转向，而不是原地急转
const HOMING_MAX_TURN_RATE := 3.4  # rad/sec 额外硬上限，避免高速弹也转出过小视觉半径
const PROJECTILE_MAX_LIFETIME := 5.0
const PROJECTILE_OFFSCREEN_MARGIN := 0.0

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
var _spawn_position := Vector2.ZERO
var chain_depth := 0
var texture_override_path := ""
var hit_target_ids := {}
var _flight_trail: Node
var _projectile_vfx_ready := false

func setup(origin: Vector2, direction: Vector2, speed: float, dmg: float, elem := "physical", pierce := 0, split := 0, falloff := 0.55, homing := 0.0, splash := 0.0, cloud := 0.0, scale_mult := 1.0, chain_depth_value := 0, texture_override := "", profile := "") -> void:
	global_position = origin
	_spawn_position = origin
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
	if lifetime >= PROJECTILE_MAX_LIFETIME:
		queue_free()
		return
	if _is_outside_screen():
		queue_free()
		return
	_apply_homing(delta)
	position += velocity * delta
	if velocity.length_squared() > 1.0:
		rotation = velocity.angle() - SPRITE_FORWARD_ANGLE
	_process_trail(delta)
	if _is_outside_screen():
		queue_free()
		return

func _is_outside_screen() -> bool:
	var p := global_position
	var viewport_size := get_viewport().get_visible_rect().size
	var max_x := maxf(1080.0, viewport_size.x)
	var max_y := maxf(1920.0, viewport_size.y)
	return p.y < -PROJECTILE_OFFSCREEN_MARGIN or p.y > max_y + PROJECTILE_OFFSCREEN_MARGIN or p.x < -PROJECTILE_OFFSCREEN_MARGIN or p.x > max_x + PROJECTILE_OFFSCREEN_MARGIN

func _apply_homing(delta: float) -> void:
	if homing_strength <= 0.0:
		return
	# 多弹道追踪弹刚出膛时方向各不相同；如果立刻开始追踪，全部瞬间拐向同一最近目标、弹道当场重合。
	# 先从枪口按原方向飞满一秒，之后再进入有限半径追踪。
	if lifetime < HOMING_ACTIVATION_DELAY:
		return
	var target := _nearest_enemy()
	if target == null:
		return
	var speed := velocity.length()
	if speed <= 0.0:
		return
	# 硬性最大转向角速度：不再用"每帧朝目标方向 lerp"的软插值(那样能在角度接近180°时
	# 几帧内转出接近原地掉头的急弯)。改成真正按角速度上限旋转当前方向。
	var desired_dir := (target.global_position - global_position).normalized()
	var current_dir := velocity.normalized()
	var angle_diff := current_dir.angle_to(desired_dir)
	var turn_rate := _homing_turn_rate_limit(speed)
	var max_step := turn_rate * delta
	var step := clampf(angle_diff, -max_step, max_step)
	var new_dir := current_dir.rotated(step)
	if new_dir.length_squared() <= 0.0:
		return
	velocity = new_dir * speed

func _homing_turn_rate_limit(speed: float) -> float:
	var strength_limit := homing_strength * HOMING_TURN_RATE_PER_STRENGTH
	var radius_limit := speed / HOMING_MIN_TURN_RADIUS
	return minf(minf(strength_limit, radius_limit), HOMING_MAX_TURN_RATE)

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
	if not _can_spawn_projectile_fx(true):
		return
	var color := _impact_color_for(element, visual_profile)
	var hot := color.lightened(0.34)
	hot.a = 0.92
	var life := _impact_lifetime_for(visual_profile)
	var glow := VfxLib.spawn_glow(parent, at_position, hot, _impact_glow_size_for(visual_profile) * visual_scale, life)
	if glow != null:
		_track_transient_fx(glow)
	if not _can_spawn_projectile_fx():
		return
	if element == "fire" and visual_profile != "plasma":
		_spawn_impact_ring_at(parent, at_position, color, _impact_ring_radius_for(visual_profile) * visual_scale * 0.72, life * 0.82)
		return
	var direction := velocity.normalized()
	if direction.length_squared() <= 0.01:
		direction = Vector2.UP
	var sparks := VfxLib.spawn_burst(
		parent,
		at_position,
		color,
		_impact_particle_amount_for(element, visual_profile),
		_impact_particle_speed_for(element, visual_profile) * maxf(visual_scale, 0.82),
		_impact_particle_spread_for(element, visual_profile),
		life
	)
	if sparks != null:
		_track_transient_fx(sparks)
		if sparks is Node2D:
			(sparks as Node2D).rotation = direction.angle() + PI
	_spawn_impact_ring_at(parent, at_position, color, _impact_ring_radius_for(visual_profile) * visual_scale, life)

func _spawn_pierce_flash() -> void:
	var parent := get_parent()
	if parent == null:
		return
	if not _can_spawn_projectile_fx(true):
		return
	var dir := velocity.normalized()
	if dir.length_squared() <= 0.01:
		dir = Vector2.UP
	var color := _impact_color_for(element, visual_profile).lightened(0.18)
	color.a = 0.82
	var hot := color.lightened(0.32)
	hot.a = 0.95
	var glow := VfxLib.spawn_glow(parent, global_position + dir * 18.0, hot, 96.0 * maxf(visual_scale, 0.9), 0.16)
	if glow != null:
		_track_transient_fx(glow)

	var sweep := Node2D.new()
	_track_transient_fx(sweep)
	sweep.name = "PierceSkillSweep"
	sweep.process_mode = Node.PROCESS_MODE_PAUSABLE
	sweep.global_position = global_position
	sweep.rotation = dir.angle()
	sweep.z_index = 78
	sweep.scale = Vector2(0.68, 1.16)
	parent.add_child(sweep)

	var band := Line2D.new()
	band.width = 24.0 * maxf(visual_scale, 0.88)
	band.default_color = Color(color.r, color.g, color.b, minf(color.a, 0.72))
	band.joint_mode = Line2D.LINE_JOINT_ROUND
	band.begin_cap_mode = Line2D.LINE_CAP_ROUND
	band.end_cap_mode = Line2D.LINE_CAP_ROUND
	band.texture = VfxLib.STREAK_TEXTURE
	band.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	band.material = _new_additive_material()
	band.points = PackedVector2Array([Vector2(-42.0, 0.0), Vector2(158.0, 0.0)])
	sweep.add_child(band)

	var core := Sprite2D.new()
	core.name = "PierceShaderCore"
	core.texture = VfxLib.RADIAL_GLOW_TEXTURE
	core.centered = true
	core.position = Vector2(22.0, 0.0)
	core.scale = Vector2(0.46, 0.13) * maxf(visual_scale, 0.88)
	var core_material := ShaderMaterial.new()
	core_material.shader = VfxLib.GLOW_CORE_SHADER
	core_material.set_shader_parameter("tint", hot)
	core_material.set_shader_parameter("intensity", 4.0)
	core_material.set_shader_parameter("core_power", 0.78)
	core.material = core_material
	sweep.add_child(core)

	var tween := sweep.create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sweep, "scale", Vector2(1.1, 0.58), 0.16)
	tween.parallel().tween_property(band, "width", 3.0, 0.16)
	tween.parallel().tween_property(sweep, "modulate:a", 0.0, 0.16)
	tween.tween_callback(sweep.queue_free)

	if _can_spawn_projectile_fx():
		var sparks := VfxLib.spawn_burst(parent, global_position + dir * 22.0, color, 12, 610.0 * maxf(visual_scale, 0.85), 30.0, 0.16)
		if sparks != null:
			_track_transient_fx(sparks)
			if sparks is Node2D:
				(sparks as Node2D).rotation = dir.angle()

func _spawn_pierce_trace(from: Vector2, to: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return
	if not _can_spawn_projectile_fx():
		return
	var parent_node := parent as Node2D
	var start := parent_node.to_local(from) if parent_node != null else from
	var finish := parent_node.to_local(to) if parent_node != null else to
	var direction := (to - from).normalized()
	if direction.length_squared() <= 0.01:
		direction = velocity.normalized()
	if direction.length_squared() <= 0.01:
		direction = Vector2.UP
	var color := _impact_color_for(element, visual_profile)
	color.a = 0.74
	var hot := color.lightened(0.36)
	hot.a = 0.9
	var midpoint := (from + to) * 0.5
	var glow := VfxLib.spawn_glow(parent, midpoint, hot, clampf(from.distance_to(to) * 0.32, 72.0, 180.0), 0.14)
	if glow != null:
		_track_transient_fx(glow)
	var trace := Line2D.new()
	_track_transient_fx(trace)
	trace.width = 18.0 * maxf(visual_scale, 0.85)
	trace.default_color = Color(color.r, color.g, color.b, minf(color.a, 0.68))
	trace.texture = VfxLib.STREAK_TEXTURE
	trace.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	trace.material = _new_additive_material()
	trace.points = PackedVector2Array([start, finish])
	parent.add_child(trace)
	var core_trace := Line2D.new()
	_track_transient_fx(core_trace)
	core_trace.width = 4.5 * maxf(visual_scale, 0.85)
	core_trace.default_color = hot
	core_trace.joint_mode = Line2D.LINE_JOINT_ROUND
	core_trace.begin_cap_mode = Line2D.LINE_CAP_ROUND
	core_trace.end_cap_mode = Line2D.LINE_CAP_ROUND
	core_trace.texture = VfxLib.STREAK_TEXTURE
	core_trace.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	core_trace.material = _new_additive_material()
	core_trace.points = PackedVector2Array([start, finish])
	parent.add_child(core_trace)
	var tween := trace.create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(trace, "width", 3.0, 0.16)
	tween.parallel().tween_property(trace, "modulate:a", 0.0, 0.16)
	tween.tween_callback(trace.queue_free)
	var core_tween := core_trace.create_tween()
	core_tween.set_trans(Tween.TRANS_QUINT)
	core_tween.set_ease(Tween.EASE_OUT)
	core_tween.parallel().tween_property(core_trace, "width", 1.0, 0.12)
	core_tween.parallel().tween_property(core_trace, "modulate:a", 0.0, 0.12)
	core_tween.tween_callback(core_trace.queue_free)

	for i in range(3):
		if not _can_spawn_projectile_fx():
			break
		var t := (float(i) + 0.35) / 3.2
		var spark_pos := from.lerp(to, t) + Vector2(-direction.y, direction.x) * randf_range(-12.0, 12.0)
		var sparks := VfxLib.spawn_particles(parent, spark_pos, color, 4, 390.0, 34.0, 0.13)
		if sparks != null:
			_track_transient_fx(sparks)
			if sparks is Node2D:
				(sparks as Node2D).rotation = direction.angle()

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

func _spawn_impact_ring_at(parent: Node, at_position: Vector2, color: Color, radius: float, duration: float) -> void:
	if parent == null or not _can_spawn_projectile_fx():
		return
	var root := Node2D.new()
	_track_transient_fx(root)
	root.name = "ProjectileImpactShockRing"
	root.process_mode = Node.PROCESS_MODE_PAUSABLE
	root.global_position = at_position
	root.z_index = 75
	root.scale = Vector2.ONE * 0.34
	parent.add_child(root)
	var line := Line2D.new()
	line.width = 5.0 if visual_profile == "rail" else 8.0
	line.default_color = Color(color.r, color.g, color.b, minf(color.a, 0.62))
	line.closed = true
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.texture = VfxLib.STREAK_TEXTURE
	line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	line.material = _new_additive_material()
	var segments := 56
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		line.add_point(Vector2(cos(angle), sin(angle)) * radius)
	root.add_child(line)
	var tween := root.create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(root, "scale", Vector2.ONE, duration)
	tween.parallel().tween_property(line, "width", 1.0, duration)
	tween.parallel().tween_property(root, "modulate:a", 0.0, duration)
	tween.tween_callback(root.queue_free)

func _impact_color_for(elem: String, profile := "") -> Color:
	match profile:
		"rail":
			return Color(0.7, 1.0, 1.0, 0.94)
		"scatter":
			return Color(1.0, 0.78, 0.34, 0.86)
		"plasma":
			return Color(1.0, 0.52, 1.0, 0.94)
		"acid":
			return Color(0.46, 1.0, 0.18, 0.9)
	var color := _particle_color_for(elem, profile)
	color.a = 0.88
	return color

func _impact_glow_size_for(profile := "") -> float:
	match profile:
		"rail":
			return 118.0
		"scatter":
			return 62.0
		"plasma":
			return 146.0
		"heavy":
			return 132.0
		"acid":
			return 104.0
		_:
			return 88.0

func _impact_ring_radius_for(profile := "") -> float:
	match profile:
		"rail":
			return 78.0
		"scatter":
			return 38.0
		"plasma":
			return 94.0
		"heavy":
			return 86.0
		"acid":
			return 70.0
		_:
			return 58.0

func _impact_particle_amount_for(elem: String, profile := "") -> int:
	match profile:
		"plasma":
			return 18
		"heavy":
			return 16
		"scatter":
			return 8
		"rail":
			return 12
		"acid":
			return 14
	match elem:
		"fire":
			return 16
		"ice":
			return 13
		"lightning":
			return 14
		"poison":
			return 13
		_:
			return 12

func _impact_particle_speed_for(elem: String, profile := "") -> float:
	match profile:
		"rail":
			return 660.0
		"plasma":
			return 420.0
		"scatter":
			return 390.0
		"heavy":
			return 470.0
		"acid":
			return 260.0
	match elem:
		"fire":
			return 450.0
		"ice":
			return 330.0
		"lightning":
			return 590.0
		"poison":
			return 240.0
		_:
			return 520.0

func _impact_particle_spread_for(elem: String, profile := "") -> float:
	match profile:
		"rail":
			return 28.0
		"scatter":
			return 86.0
		"plasma":
			return 130.0
		"acid":
			return 122.0
	match elem:
		"fire":
			return 96.0
		"ice":
			return 74.0
		"lightning":
			return 54.0
		"poison":
			return 118.0
		_:
			return 64.0

func _impact_lifetime_for(profile := "") -> float:
	match profile:
		"rail":
			return 0.13
		"scatter":
			return 0.12
		"plasma":
			return 0.22
		"acid":
			return 0.24
		_:
			return 0.16

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
