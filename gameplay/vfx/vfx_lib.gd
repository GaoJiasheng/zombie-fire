extends RefCounted
class_name VfxLib

const RADIAL_GLOW_TEXTURE := preload("res://assets/production/sprites/vfx/vfx_input_radial_glow.png")
const STREAK_TEXTURE := preload("res://assets/production/sprites/vfx/vfx_input_streak.png")
const SPARK_TEXTURE := preload("res://assets/production/sprites/vfx/vfx_input_spark.png")
const GLOW_CORE_SHADER := preload("res://gameplay/vfx/shaders/vfx_glow_core.gdshader")

const MAX_BURST_PARTICLES := 48
const MAX_BURST_LIFETIME := 0.45
const MAX_TRAIL_POINTS := 14

static var _screen_shake_node: Node = null


class FadingTrail2D:
	extends Line2D

	var target: Node2D
	var max_points := MAX_TRAIL_POINTS
	var min_point_distance := 7.0
	var release_fade_speed := 7.0

	func setup(target_node: Node2D, trail_color: Color, trail_width: float, additive_material: Material) -> void:
		target = target_node
		name = "VfxTrail"
		top_level = true
		global_position = Vector2.ZERO
		z_index = max(target_node.z_index - 1, 0)
		width = clampf(trail_width, 1.0, 42.0)
		joint_mode = Line2D.LINE_JOINT_ROUND
		begin_cap_mode = Line2D.LINE_CAP_ROUND
		end_cap_mode = Line2D.LINE_CAP_ROUND
		texture = STREAK_TEXTURE
		texture_mode = Line2D.LINE_TEXTURE_STRETCH
		default_color = trail_color
		gradient = _trail_gradient(trail_color)
		material = additive_material
		add_point(target_node.global_position)
		set_process(true)

	func _process(delta: float) -> void:
		if is_instance_valid(target):
			var next_point := target.global_position
			if get_point_count() == 0 or get_point_position(get_point_count() - 1).distance_to(next_point) >= min_point_distance:
				add_point(next_point)
			while get_point_count() > max_points:
				remove_point(0)
			return

		modulate.a = maxf(0.0, modulate.a - delta * release_fade_speed)
		width = maxf(0.0, width - delta * release_fade_speed * 3.0)
		if modulate.a <= 0.02 or width <= 0.5:
			queue_free()

	func _trail_gradient(trail_color: Color) -> Gradient:
		var start := trail_color
		start.a = 0.0
		var mid := trail_color
		mid.a = minf(trail_color.a, 0.72)
		var end := trail_color.lightened(0.35)
		end.a = minf(trail_color.a, 0.95)
		var gradient_resource := Gradient.new()
		gradient_resource.set_offset(0, 0.0)
		gradient_resource.set_color(0, start)
		gradient_resource.set_offset(1, 1.0)
		gradient_resource.set_color(1, end)
		gradient_resource.add_point(0.72, mid)
		return gradient_resource


static func bind_screen_shake(shake_node: Node) -> void:
	_screen_shake_node = shake_node


static func spawn_glow(parent: Node, pos: Vector2, color: Color, size: float, duration: float) -> Node:
	if parent == null:
		return null
	var life := clampf(duration, 0.03, 0.8)
	var safe_size := clampf(size, 8.0, 420.0)
	var root := Node2D.new()
	root.name = "VfxGlow"
	root.process_mode = Node.PROCESS_MODE_PAUSABLE
	root.z_index = 72
	root.scale = Vector2.ONE * 0.72
	parent.add_child(root)
	root.global_position = pos

	var halo := Sprite2D.new()
	halo.name = "Halo"
	halo.texture = RADIAL_GLOW_TEXTURE
	halo.centered = true
	halo.material = _new_additive_material()
	var halo_color := color
	halo_color.a = minf(color.a, 0.48)
	halo.modulate = halo_color
	halo.scale = Vector2.ONE * (safe_size / float(RADIAL_GLOW_TEXTURE.get_width()))
	root.add_child(halo)

	var core := Sprite2D.new()
	core.name = "Core"
	core.texture = RADIAL_GLOW_TEXTURE
	core.centered = true
	core.scale = Vector2.ONE * (safe_size * 0.36 / float(RADIAL_GLOW_TEXTURE.get_width()))
	var core_material := ShaderMaterial.new()
	core_material.shader = GLOW_CORE_SHADER
	core_material.set_shader_parameter("tint", color)
	core_material.set_shader_parameter("intensity", 2.75)
	core_material.set_shader_parameter("core_power", 0.92)
	core.material = core_material
	root.add_child(core)

	var tween := root.create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(root, "scale", Vector2.ONE * 1.08, life)
	tween.parallel().tween_property(root, "modulate:a", 0.0, life)
	tween.tween_callback(root.queue_free)
	return root


static func spawn_burst(parent: Node, pos: Vector2, color: Color, amount: int, speed: float, spread_deg: float, lifetime: float) -> Node:
	if parent == null:
		return null
	var particles := GPUParticles2D.new()
	particles.name = "VfxBurst"
	particles.process_mode = Node.PROCESS_MODE_PAUSABLE
	particles.one_shot = true
	particles.amount = clampi(amount, 1, MAX_BURST_PARTICLES)
	particles.lifetime = clampf(lifetime, 0.05, MAX_BURST_LIFETIME)
	particles.explosiveness = 1.0
	particles.randomness = 0.42
	particles.local_coords = false
	particles.texture = SPARK_TEXTURE
	particles.material = _new_additive_material()
	particles.z_index = 74
	particles.visibility_rect = Rect2(-520.0, -520.0, 1040.0, 1040.0)

	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	process_material.direction = Vector3(1.0, 0.0, 0.0)
	process_material.spread = clampf(spread_deg, 0.0, 180.0)
	process_material.initial_velocity_min = maxf(0.0, speed * 0.42)
	process_material.initial_velocity_max = minf(maxf(speed, 0.0), 900.0)
	process_material.gravity = Vector3(0.0, 145.0, 0.0)
	process_material.damping_min = 18.0
	process_material.damping_max = 42.0
	process_material.angle_min = -95.0
	process_material.angle_max = 95.0
	process_material.angular_velocity_min = -320.0
	process_material.angular_velocity_max = 320.0
	process_material.scale_min = 0.075
	process_material.scale_max = 0.22
	process_material.scale_curve = _spark_scale_curve()
	process_material.color_ramp = _spark_color_ramp(color)
	particles.process_material = process_material

	particles.finished.connect(particles.queue_free)
	parent.add_child(particles)
	particles.global_position = pos
	particles.emitting = true
	return particles


static func spawn_particles(parent: Node, pos: Vector2, color: Color, amount: int, speed: float, spread_deg: float, lifetime: float) -> Node:
	return spawn_burst(parent, pos, color, amount, speed, spread_deg, lifetime)


static func spawn_trail(target: Node2D, color: Color, width: float) -> Node:
	if target == null or not is_instance_valid(target):
		return null
	var parent := target.get_parent()
	if parent == null:
		return null
	var trail := FadingTrail2D.new()
	parent.add_child(trail)
	trail.setup(target, color, width, _new_additive_material())
	return trail


static func screen_shake(intensity: float, duration: float) -> void:
	if _screen_shake_node == null or not is_instance_valid(_screen_shake_node):
		return
	if _screen_shake_node.has_method("shake"):
		_screen_shake_node.shake(maxf(0.0, intensity), maxf(0.0, duration))


static func _new_additive_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return material


static func _spark_color_ramp(color: Color) -> GradientTexture1D:
	var hot := color.lightened(0.48)
	hot.a = minf(color.a, 1.0)
	var body := color
	body.a = minf(color.a, 0.74)
	var tail := color
	tail.a = 0.0
	var gradient_resource := Gradient.new()
	gradient_resource.set_offset(0, 0.0)
	gradient_resource.set_color(0, hot)
	gradient_resource.set_offset(1, 1.0)
	gradient_resource.set_color(1, tail)
	gradient_resource.add_point(0.32, body)
	var texture := GradientTexture1D.new()
	texture.gradient = gradient_resource
	return texture


static func _spark_scale_curve() -> CurveTexture:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.18, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	var texture := CurveTexture.new()
	texture.curve = curve
	return texture
