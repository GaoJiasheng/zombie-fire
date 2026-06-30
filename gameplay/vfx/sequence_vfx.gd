extends Sprite2D

static var sequence_cache: Dictionary = {}

var frames: Array[Texture2D] = []
var fps := 16.0
var elapsed := 0.0
var base_scale := Vector2.ONE
var base_alpha := 1.0
var start_rotation := 0.0
var grow := 1.0
var fade_from := 0.72
var lift := Vector2.ZERO
var spin := 0.0


func setup(sequence_id: String, world_position: Vector2, scale_mult := 1.0, tint := Color.WHITE, fps_mult := 1.0, rotation_rad := 0.0, grow_mult := 1.0, lift_vector := Vector2.ZERO, spin_rad := 0.0) -> bool:
	var data := _load_sequence(sequence_id)
	frames.clear()
	for frame in data.get("frames", []):
		if frame is Texture2D:
			frames.append(frame)
	if frames.is_empty():
		return false
	fps = maxf(1.0, float(data.get("fps", 16.0)) * fps_mult)
	elapsed = 0.0
	global_position = world_position
	texture = frames[0]
	scale = Vector2.ONE * scale_mult
	base_scale = scale
	modulate = tint
	base_alpha = tint.a
	rotation = rotation_rad
	start_rotation = rotation_rad
	grow = grow_mult
	lift = lift_vector
	spin = spin_rad
	z_index = 24
	set_process(true)
	return true


func _process(delta: float) -> void:
	elapsed += delta
	var frame_index := int(floor(elapsed * fps))
	if frame_index >= frames.size():
		queue_free()
		return
	texture = frames[frame_index]
	var t := clampf(float(frame_index) / maxf(float(frames.size() - 1), 1.0), 0.0, 1.0)
	scale = base_scale * lerpf(1.0, grow, t)
	global_position += lift * delta
	rotation = start_rotation + spin * t
	if t >= fade_from:
		var fade_t := inverse_lerp(fade_from, 1.0, t)
		modulate.a = base_alpha * (1.0 - fade_t)


static func _load_sequence(sequence_id: String) -> Dictionary:
	if sequence_cache.has(sequence_id):
		return sequence_cache[sequence_id]
	var result := {
		"frames": [],
		"fps": 16.0,
	}
	var json_path := "res://assets/production/sprites/vfx_sequences/%s/%s_sequence.json" % [sequence_id, sequence_id]
	if not FileAccess.file_exists(json_path):
		sequence_cache[sequence_id] = result
		return result
	var file := FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		sequence_cache[sequence_id] = result
		return result
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		sequence_cache[sequence_id] = result
		return result
	var loaded_frames: Array[Texture2D] = []
	for frame_path in parsed.get("frames", []):
		var full_path := "res://assets/production/%s" % str(frame_path)
		if not ResourceLoader.exists(full_path):
			continue
		var texture_resource := load(full_path) as Texture2D
		if texture_resource != null:
			loaded_frames.append(texture_resource)
	result["frames"] = loaded_frames
	result["fps"] = float(parsed.get("fps", 16.0))
	sequence_cache[sequence_id] = result
	return result
