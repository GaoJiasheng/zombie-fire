extends Area2D

signal split_requested(origin: Vector2, direction: Vector2, count: int, damage: float, element: String)
signal hit_confirmed(target: Node, origin: Vector2, damage: float, element: String, splash_radius: float, cloud_radius: float, chain_depth: int)

const SPRITE_FORWARD_ANGLE := 0.0
const PROJECTILE_SPEED_MULTIPLIER := 0.5
const PIERCE_SWEEP_RANGE := 420.0
const PIERCE_SWEEP_HALF_WIDTH := 92.0

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
var trail_timer := 0.0
var trail_interval := 0.028
var lifetime := 0.0
var chain_depth := 0
var hit_target_ids := {}

func setup(origin: Vector2, direction: Vector2, speed: float, dmg: float, elem := "physical", pierce := 0, split := 0, falloff := 0.55, homing := 0.0, splash := 0.0, cloud := 0.0, scale_mult := 1.0, chain_depth_value := 0, texture_override := "") -> void:
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
	chain_depth = chain_depth_value
	hit_target_ids = {}
	var texture_path := texture_override if texture_override != "" else _projectile_texture_path(element)
	$Sprite.texture = load(texture_path)
	$Sprite.scale = Vector2(0.42, 0.42) * visual_scale
	$Sprite.modulate = _element_color(element)
	$CollisionShape2D.shape = CircleShape2D.new()
	$CollisionShape2D.shape.radius = 18.0 * maxf(visual_scale, 0.85)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_spawn_trail_afterimage(0.72)

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
	var desired := (target.global_position - global_position).normalized() * speed
	velocity = velocity.lerp(desired, clampf(homing_strength * delta, 0.0, 0.32))

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
	_spawn_trail_afterimage(0.34)

func _spawn_trail_afterimage(alpha: float) -> void:
	var parent := get_parent()
	if parent == null or $Sprite.texture == null:
		return
	var trail := Sprite2D.new()
	trail.texture = $Sprite.texture
	trail.global_position = global_position
	trail.rotation = rotation
	trail.scale = $Sprite.scale * (1.0 + minf(lifetime * 1.5, 0.16))
	var color := _element_color(element)
	color.a = alpha
	trail.modulate = color
	parent.add_child(trail)
	var tween := trail.create_tween()
	tween.parallel().tween_property(trail, "scale", trail.scale * 0.62, 0.16)
	tween.parallel().tween_property(trail, "modulate:a", 0.0, 0.16)
	tween.tween_callback(trail.queue_free)

func _element_color(elem: String) -> Color:
	match elem:
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

func _projectile_texture_path(elem: String) -> String:
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
	hit_confirmed.emit(target, hit_origin, damage, element, splash_radius, cloud_radius, chain_depth)
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
		hit_confirmed.emit(enemy_node, hit_pos, damage, element, splash_radius, cloud_radius, chain_depth)
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
	var flash := Sprite2D.new()
	flash.texture = load(_impact_vfx_path(element))
	flash.global_position = at_position
	flash.rotation = randf_range(-0.45, 0.45)
	flash.scale = Vector2(0.3, 0.3) * visual_scale
	flash.modulate = _element_color(element)
	parent.add_child(flash)
	var tween := flash.create_tween()
	tween.parallel().tween_property(flash, "scale", flash.scale * 1.45, 0.11)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.11)
	tween.tween_callback(flash.queue_free)

func _spawn_pierce_flash() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var ring := Sprite2D.new()
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
	var parent_node := parent as Node2D
	var start := parent_node.to_local(from) if parent_node != null else from
	var finish := parent_node.to_local(to) if parent_node != null else to
	var trace := Line2D.new()
	trace.width = 18.0 * maxf(visual_scale, 0.85)
	trace.default_color = Color(1.0, 0.9, 0.36, 0.58)
	trace.points = PackedVector2Array([start, finish])
	parent.add_child(trace)
	var tween := trace.create_tween()
	tween.parallel().tween_property(trace, "width", 3.0, 0.16)
	tween.parallel().tween_property(trace, "modulate:a", 0.0, 0.16)
	tween.tween_callback(trace.queue_free)

func _impact_vfx_path(elem: String) -> String:
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
