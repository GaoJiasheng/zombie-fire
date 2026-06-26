extends Node2D
## Floating damage numbers. Spawn numbers at hit positions, pop, float, fade.

const RISE := 60.0
const LIFE := 0.85
const CRIT_LIFE := 1.05
const CRIT_SCALE := 1.55
const STACK_OFFSET := 12.0

var _stack_counter: Dictionary = {}

func reset() -> void:
	for child in get_children():
		child.queue_free()
	_stack_counter.clear()

func spawn_damage(position: Vector2, amount: float, element: String, crit := false, weak_hit := false) -> void:
	if amount <= 0.0:
		return
	var rounded := int(round(amount))
	var label := Label.new()
	label.text = str(rounded)
	label.add_theme_font_size_override("font_size", 38 if not crit else 56)
	var color := _element_color(element)
	if crit:
		color = Color(1.0, 0.94, 0.32) if not weak_hit else Color(1.0, 0.5, 0.18)
	elif weak_hit:
		color = Color(1.0, 0.74, 0.32)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	label.add_theme_constant_override("outline_size", 5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(140, 64)
	label.pivot_offset = Vector2(70, 32)
	var stack_offset := _stack_offset(position)
	label.position = position + stack_offset
	add_child(label)
	_stack_counter[position] = stack_offset.y + STACK_OFFSET
	var life := CRIT_LIFE if crit else LIFE
	var rise := RISE * (1.4 if crit else 1.0)
	var target_scale := CRIT_SCALE if crit else 1.0
	var tween := label.create_tween()
	tween.parallel().tween_property(label, "position:y", label.position.y - rise, life)
	tween.parallel().tween_property(label, "modulate:a", 0.0, life)
	if crit:
		tween.parallel().tween_property(label, "scale", Vector2(target_scale, target_scale), 0.08).from(Vector2(0.4, 0.4))
		tween.parallel().tween_property(label, "scale", Vector2(0.95, 0.95), 0.12)
	else:
		tween.parallel().tween_property(label, "scale", Vector2(1.0, 1.0), 0.08).from(Vector2(0.6, 0.6))
	tween.tween_callback(label.queue_free)
	# decay stack counter
	var decay_t := get_tree().create_timer(0.35)
	decay_t.timeout.connect(_decay_stack.bind(position))

func _decay_stack(pos: Vector2) -> void:
	if _stack_counter.has(pos):
		_stack_counter[pos] -= STACK_OFFSET
		if _stack_counter[pos] <= 0.0:
			_stack_counter.erase(pos)

func _stack_offset(pos: Vector2) -> Vector2:
	var y := float(_stack_counter.get(pos, 0.0))
	var jitter := Vector2(randf_range(-4.0, 4.0), 0.0)
	return Vector2(jitter.x, -y)

func _element_color(element: String) -> Color:
	match element:
		"fire":
			return Color(1.0, 0.62, 0.32)
		"ice":
			return Color(0.7, 0.92, 1.0)
		"lightning":
			return Color(1.0, 0.94, 0.5)
		"poison":
			return Color(0.7, 1.0, 0.5)
		_:
			return Color(1.0, 0.96, 0.88)
