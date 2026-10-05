extends Sprite2D
class_name CombatVfxArt

## Authored, alpha-textured material animation. Presentation only; no RNG.
const MATERIAL := preload("res://assets/production/sprites/vfx_polish/material_impacts.png")
const ENERGY := preload("res://assets/production/sprites/vfx_polish/energy_impacts.png")
const RIBBONS := preload("res://assets/production/sprites/vfx_polish/material_ribbons.png")
static var _frames: Dictionary = {}
var kind := "physical"
var ribbon := false
var lifetime := 0.46
var elapsed := 0.0
var looped := false
var unscaled := false
var base_scale := Vector2.ONE
var base_alpha := 1.0
var _phase := 0.0
var _cell_size := Vector2.ONE

static func frames(kind_id: String, is_ribbon := false) -> Array[Texture2D]:
	var key := kind_id + ("_ribbon" if is_ribbon else "")
	if _frames.has(key):
		return _frames[key]
	var sheet: Texture2D = MATERIAL
	var row := 0
	if is_ribbon:
		sheet = RIBBONS
		row = {"fire": 1, "lightning": 2, "poison": 3}.get(kind_id, 0)
	else:
		match kind_id:
			"fire": row = 1
			"ice": row = 2
			"poison": row = 3
			"lightning", "void", "shield", "charge":
				sheet = ENERGY
				row = {"lightning": 0, "void": 1, "shield": 2, "charge": 3}[kind_id]
	var result: Array[Texture2D] = []
	var cell := sheet.get_size() / 4.0
	for column in range(4):
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(Vector2(column, row) * cell, cell)
		# Virtual alpha gutter retains the complete authored image (no cropping)
		# and isolates each cell under mobile bilinear texture filtering.
		frame.margin = Rect2(cell * 0.1, cell * 0.2)
		frame.filter_clip = true
		result.append(frame)
	_frames[key] = result
	return result

static func material_kind(color: Color) -> String:
	if color.r > 0.55 and color.b > color.g * 1.18:
		return "void"
	if color.g > color.r * 1.25 and color.g > color.b * 1.15:
		return "poison"
	if color.b > color.r * 1.15:
		return "ice"
	if color.r > 0.65 and color.g < 0.65:
		return "fire"
	return "physical"

static func paint(canvas: Node2D, kind_id: String, position: Vector2, size: Vector2, phase: float, alpha := 1.0, rotation_rad := 0.0, is_ribbon := false, tint := Color.WHITE) -> void:
	var textures := frames(kind_id, is_ribbon)
	var step := clampf(phase, 0.0, 1.0) * 3.0
	var index := mini(int(step), 2)
	var blend := step - float(index)
	var color := tint
	if is_ribbon and kind_id == "ice":
		color *= Color(0.58, 0.84, 1.0)
	elif is_ribbon and kind_id == "void":
		color *= Color(0.76, 0.35, 1.0)
	elif is_ribbon and kind_id == "shield":
		color *= Color(0.58, 0.91, 1.0)
	canvas.draw_set_transform(position, rotation_rad)
	color.a = alpha * (1.0 - blend)
	canvas.draw_texture_rect(textures[index], Rect2(-size * 0.5, size), false, color)
	color.a = alpha * blend
	canvas.draw_texture_rect(textures[index + 1], Rect2(-size * 0.5, size), false, color)
	canvas.draw_set_transform(Vector2.ZERO)

func setup(kind_id: String, size: Vector2, duration: float, tint := Color.WHITE, is_ribbon := false, repeat := false, real_time := false) -> void:
	kind = kind_id
	ribbon = is_ribbon
	lifetime = maxf(duration, 0.04)
	looped = repeat
	unscaled = real_time
	_cell_size = frames(kind, ribbon)[0].get_size()
	base_scale = size / _cell_size
	texture = null # Draw both neighboring authored phases instead of hard cuts.
	scale = base_scale
	modulate = tint
	base_alpha = tint.a
	process_mode = Node.PROCESS_MODE_PAUSABLE
	queue_redraw()

func _draw() -> void:
	paint(self, kind, Vector2.ZERO, _cell_size, _phase, 1.0, 0.0, ribbon)

func _process(delta: float) -> void:
	elapsed += delta / maxf(Engine.time_scale, 0.001) if unscaled else delta
	if elapsed >= lifetime and not looped:
		queue_free()
		return
	# Persistent wisps breathe forward/back, not a popping frame-3/frame-0 loop.
	var phase := fmod(elapsed / lifetime, 2.0) if looped else elapsed / lifetime
	if looped and phase > 1.0:
		phase = 2.0 - phase
	_phase = phase
	scale = base_scale * lerpf(0.92, 1.05, phase)
	modulate.a = base_alpha * (1.0 if looped else (1.0 - smoothstep(0.62, 1.0, phase)))
	queue_redraw()
