extends Node2D
class_name StatusVfxController

# Persistent enemy status presentation.
#
# Each state owns an independent spatial layer:
# - ground contact/readability ring
# - body-attached looping sequence
# - optional offset secondary sequence for premium-density shots
#
# The controller only receives remaining durations from Enemy. It never owns
# gameplay timing or damage, so visuals can be tuned without affecting balance.

const DEFAULT_FADE_IN := 0.1
const DEFAULT_FADE_OUT := 0.25

static var _sequence_cache: Dictionary = {}

var _config: Dictionary = {}
var _layers: Dictionary = {}
var _tracked_sprite: Sprite2D
var _is_boss := false
var _lod := "full"
var _priority := false
var _reduced_effects := false


static func release_cached_resources_for_tests() -> void:
	_sequence_cache.clear()


class LoopingSequenceSprite:
	extends Sprite2D

	var frames: Array[Texture2D] = []
	var fps := 16.0
	var loop_gap := 0.0
	var elapsed := 0.0
	var phase := 0.0
	var presentation_allowed := true

	func configure(
			loaded_frames: Array[Texture2D],
			base_fps: float,
			fps_mult: float,
			gap: float,
			start_phase: float
	) -> void:
		frames = loaded_frames
		fps = maxf(1.0, base_fps * fps_mult)
		loop_gap = maxf(0.0, gap)
		phase = clampf(start_phase, 0.0, 0.99)
		var frame_duration := float(frames.size()) / fps if not frames.is_empty() else 0.0
		elapsed = phase * (frame_duration + loop_gap)
		set_process(not frames.is_empty())
		if not frames.is_empty():
			texture = frames[0]

	func _process(delta: float) -> void:
		if frames.is_empty():
			visible = false
			return
		elapsed += delta
		var frame_duration := float(frames.size()) / fps
		var cycle := frame_duration + loop_gap
		var local_time := fmod(elapsed, maxf(cycle, 0.001))
		if local_time >= frame_duration:
			visible = false
			return
		visible = presentation_allowed
		var frame_index := clampi(int(floor(local_time * fps)), 0, frames.size() - 1)
		texture = frames[frame_index]

	func set_presentation_allowed(allowed: bool) -> void:
		presentation_allowed = allowed
		if not allowed:
			visible = false


class StatusLayer:
	extends Node2D

	var status_id := ""
	var row: Dictionary = {}
	var tracked_sprite: Sprite2D
	var body_root: Node2D
	var ground: Sprite2D
	var primary: LoopingSequenceSprite
	var secondary: LoopingSequenceSprite
	var remaining := 0.0
	var age := 0.0
	var rendered_alpha := 0.0
	var pulse_strength := 0.0
	var fade_in := DEFAULT_FADE_IN
	var fade_out := DEFAULT_FADE_OUT
	var base_scale := 1.0
	var base_ground_scale := Vector2.ONE
	var base_ground_alpha := 0.3
	var base_alpha := 0.8
	var is_boss := false
	var lod := "full"
	var priority := false
	var reduced_effects := false
	var stack_alpha := 1.0
	var _was_active := false

	func configure(
			layer_id: String,
			layer_row: Dictionary,
			sprite: Sprite2D,
			boss: bool,
			loaded_frames: Array[Texture2D],
			base_fps: float,
			fade_in_seconds: float,
			fade_out_seconds: float
	) -> void:
		status_id = layer_id
		row = layer_row
		tracked_sprite = sprite
		is_boss = boss
		fade_in = maxf(0.01, fade_in_seconds)
		fade_out = maxf(0.05, fade_out_seconds)
		z_index = int(row.get("z_index", 2))
		visible = false

		ground = Sprite2D.new()
		ground.name = "GroundContact"
		var ground_path := str(row.get("ground_texture", ""))
		if ground_path != "" and ResourceLoader.exists(ground_path):
			ground.texture = load(ground_path) as Texture2D
		ground.material = _additive_material()
		ground.modulate = _hex_color(str(row.get("ground_tint", "FFFFFF")), 1.0)
		ground.position = _vector_for("ground_boss_offset" if is_boss else "ground_normal_offset", Vector2.ZERO)
		base_ground_scale = _vector_for(
			"ground_boss_scale" if is_boss else "ground_normal_scale",
			Vector2.ONE * (0.5 if is_boss else 0.3)
		)
		ground.scale = base_ground_scale
		base_ground_alpha = clampf(float(row.get("ground_alpha", 0.3)), 0.0, 1.0)
		ground.z_index = -2
		add_child(ground)

		body_root = Node2D.new()
		body_root.name = "BodyAttachment"
		body_root.position = _vector_for("boss_offset" if is_boss else "normal_offset", Vector2.ZERO)
		add_child(body_root)

		primary = LoopingSequenceSprite.new()
		primary.name = "PrimaryLoop"
		primary.material = _additive_material()
		primary.modulate = _hex_color(str(row.get("tint", "FFFFFF")), 1.0)
		base_scale = maxf(0.01, float(row.get("boss_scale" if is_boss else "normal_scale", 0.4 if is_boss else 0.24)))
		primary.scale = Vector2.ONE * base_scale
		primary.configure(
			loaded_frames,
			base_fps,
			float(row.get("fps_mult", 1.0)),
			float(row.get("loop_gap", 0.0)),
			0.0
		)
		body_root.add_child(primary)

		if bool(row.get("secondary", false)):
			secondary = LoopingSequenceSprite.new()
			secondary.name = "SecondaryLoop"
			secondary.material = _additive_material()
			secondary.modulate = _hex_color(str(row.get("tint", "FFFFFF")), 1.0)
			secondary.position = _vector_for("secondary_offset", Vector2.ZERO) * (1.65 if is_boss else 1.0)
			secondary.scale = Vector2.ONE * base_scale * float(row.get("secondary_scale", 0.55))
			secondary.configure(
				loaded_frames,
				base_fps,
				float(row.get("fps_mult", 1.0)) * 0.92,
				float(row.get("loop_gap", 0.0)),
				float(row.get("secondary_phase", 0.5))
			)
			body_root.add_child(secondary)
		base_alpha = clampf(float(row.get("alpha", 0.8)), 0.0, 1.0)
		set_process(true)

	func sync(time_left: float, active_stack_alpha: float) -> void:
		remaining = maxf(0.0, time_left)
		stack_alpha = clampf(active_stack_alpha, 0.35, 1.0)
		var active := remaining > 0.0
		if active and not _was_active:
			age = 0.0
			pulse_strength = 1.0
			_was_active = true
		elif not active and _was_active:
			_was_active = false

	func set_lod(next_lod: String, is_priority: bool, reduced: bool) -> void:
		lod = next_lod
		priority = is_priority
		reduced_effects = reduced

	func pulse(amount := 1.0) -> void:
		pulse_strength = maxf(pulse_strength, clampf(amount, 0.0, 1.5))

	func debug_snapshot() -> Dictionary:
		return {
			"visible": visible,
			"alpha": rendered_alpha,
			"remaining": remaining,
			"lod": lod,
			"ground_visible": ground != null and ground.visible,
			"primary_visible": primary != null and primary.visible,
			"secondary_visible": secondary != null and secondary.visible,
			"primary_allowed": primary != null and primary.presentation_allowed,
			"secondary_allowed": secondary != null and secondary.presentation_allowed,
		}

	func _process(delta: float) -> void:
		if remaining > 0.0:
			age += delta
		pulse_strength = move_toward(pulse_strength, 0.0, delta * 4.8)

		var entry_alpha := clampf(age / fade_in, 0.0, 1.0)
		var exit_alpha := clampf(remaining / fade_out, 0.0, 1.0) if remaining > 0.0 else 0.0
		var lod_alpha := 1.0
		if lod == "condensed":
			lod_alpha = 0.78
		elif lod == "minimal":
			lod_alpha = 0.58
		if reduced_effects:
			lod_alpha *= 0.72
		if priority:
			lod_alpha = maxf(lod_alpha, 0.9)
		var target_alpha := base_alpha * entry_alpha * exit_alpha * lod_alpha * stack_alpha
		rendered_alpha = move_toward(rendered_alpha, target_alpha, delta * 6.5)
		visible = rendered_alpha > 0.012
		if not visible:
			return

		var sprite_follow := tracked_sprite.position if tracked_sprite != null and bool(row.get("follow_sprite", true)) else Vector2.ZERO
		body_root.position = sprite_follow + _vector_for("boss_offset" if is_boss else "normal_offset", Vector2.ZERO)
		var pulse := 1.0 + pulse_strength * 0.13 + sin(Time.get_ticks_msec() * 0.008 + float(status_id.hash() % 19)) * 0.025
		body_root.scale = Vector2.ONE * pulse
		ground.rotation += delta * (0.34 if status_id == "lightning" else 0.16)
		ground.scale = base_ground_scale * (1.0 + pulse_strength * 0.1)
		ground.modulate.a = base_ground_alpha * entry_alpha * exit_alpha * lod_alpha * stack_alpha

		primary.modulate.a = rendered_alpha
		primary.set_presentation_allowed(lod != "minimal")
		if secondary != null:
			secondary.modulate.a = rendered_alpha * 0.74
			secondary.set_presentation_allowed(lod == "full" and not reduced_effects)

	func _vector_for(key: String, fallback: Vector2) -> Vector2:
		var value: Variant = row.get(key, [])
		if value is Array and (value as Array).size() >= 2:
			return Vector2(float(value[0]), float(value[1]))
		return fallback

	func _hex_color(value: String, alpha: float) -> Color:
		var normalized := value.strip_edges().trim_prefix("#")
		var color := Color.from_string(normalized, Color.WHITE)
		color.a = alpha
		return color

	func _additive_material() -> CanvasItemMaterial:
		var material := CanvasItemMaterial.new()
		material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		return material


func setup(sprite: Sprite2D, is_boss: bool) -> void:
	_tracked_sprite = sprite
	_is_boss = is_boss
	var data_loader := _autoload("/root/DataLoader")
	var table: Variant = data_loader.get_table("status_vfx") if data_loader != null else {}
	_config = table.duplicate(true) if table is Dictionary else {}
	_reduced_effects = _reduced_effects_enabled()


func sync_statuses(status_times: Dictionary) -> void:
	var active_count := 0
	for status_id in status_times.keys():
		if float(status_times.get(status_id, 0.0)) > 0.0:
			active_count += 1
	var global_row: Dictionary = _config.get("global", {})
	var stack_alpha := 1.0
	if active_count >= 3:
		stack_alpha = float(global_row.get("stack_alpha_many", 0.7))
	elif active_count == 2:
		stack_alpha = float(global_row.get("stack_alpha_two", 0.84))
	for status_id_var in status_times.keys():
		var status_id := str(status_id_var)
		var time_left := maxf(0.0, float(status_times.get(status_id, 0.0)))
		if time_left > 0.0 and not _layers.has(status_id):
			_create_layer(status_id)
		if _layers.has(status_id):
			var layer := _layers[status_id] as StatusLayer
			if layer != null:
				layer.sync(time_left, stack_alpha)


func set_density_lod(next_lod: String, priority := false) -> void:
	_lod = next_lod if next_lod in ["full", "condensed", "minimal"] else "full"
	_priority = priority
	_reduced_effects = _reduced_effects_enabled()
	for layer_var in _layers.values():
		var layer := layer_var as StatusLayer
		if layer != null:
			layer.set_lod(_lod, _priority, _reduced_effects)


func pulse(status_id: String, amount := 1.0) -> void:
	if _layers.has(status_id):
		var layer := _layers[status_id] as StatusLayer
		if layer != null:
			layer.pulse(amount)


func debug_active_statuses() -> Array[String]:
	var result: Array[String] = []
	for status_id in _layers.keys():
		var layer := _layers[status_id] as StatusLayer
		if layer != null and layer.remaining > 0.0:
			result.append(str(status_id))
	result.sort()
	return result


func debug_layer_snapshot(status_id: String) -> Dictionary:
	if not _layers.has(status_id):
		return {}
	var layer := _layers[status_id] as StatusLayer
	return layer.debug_snapshot() if layer != null else {}

func debug_advance(seconds: float) -> void:
	# Deterministic test hook: visual state has no gameplay authority, so smoke
	# tests can advance its release transition without relying on wall-clock FPS.
	var delta := maxf(0.0, seconds)
	for layer_var in _layers.values():
		var layer := layer_var as StatusLayer
		if layer != null:
			layer._process(delta)


func _create_layer(status_id: String) -> void:
	if not _config.has(status_id):
		return
	var row_var: Variant = _config.get(status_id, {})
	if not (row_var is Dictionary):
		return
	var row: Dictionary = row_var
	var sequence_id := str(row.get("sequence", ""))
	var sequence := _load_sequence(sequence_id)
	var frames: Array[Texture2D] = []
	for frame_var in sequence.get("frames", []):
		if frame_var is Texture2D:
			frames.append(frame_var)
	if frames.is_empty():
		return
	var global_row: Dictionary = _config.get("global", {})
	var layer := StatusLayer.new()
	layer.name = "%sStatus" % status_id.capitalize()
	add_child(layer)
	layer.configure(
		status_id,
		row,
		_tracked_sprite,
		_is_boss,
		frames,
		float(sequence.get("fps", 16.0)),
		float(global_row.get("fade_in", DEFAULT_FADE_IN)),
		float(global_row.get("fade_out", DEFAULT_FADE_OUT))
	)
	layer.set_lod(_lod, _priority, _reduced_effects)
	_layers[status_id] = layer


static func _load_sequence(sequence_id: String) -> Dictionary:
	if _sequence_cache.has(sequence_id):
		return _sequence_cache[sequence_id]
	var result := {"frames": [], "fps": 16.0}
	if sequence_id == "":
		return result
	var json_path := "res://assets/production/sprites/vfx_sequences/%s/%s_sequence.json" % [sequence_id, sequence_id]
	if not FileAccess.file_exists(json_path):
		_sequence_cache[sequence_id] = result
		return result
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(json_path))
	if not (parsed is Dictionary):
		_sequence_cache[sequence_id] = result
		return result
	var loaded_frames: Array[Texture2D] = []
	for frame_path_var in parsed.get("frames", []):
		var frame_path := "res://assets/production/%s" % str(frame_path_var)
		if not ResourceLoader.exists(frame_path):
			continue
		var texture_resource := load(frame_path) as Texture2D
		if texture_resource != null:
			loaded_frames.append(texture_resource)
	result["frames"] = loaded_frames
	result["fps"] = float(parsed.get("fps", 16.0))
	_sequence_cache[sequence_id] = result
	return result


static func _autoload(path: String) -> Node:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null(path)
	return null


static func _reduced_effects_enabled() -> bool:
	var settings_manager := _autoload("/root/SettingsManager")
	return (
		bool(settings_manager.call("reduced_effects_enabled"))
		if settings_manager != null and settings_manager.has_method("reduced_effects_enabled")
		else false
	)
