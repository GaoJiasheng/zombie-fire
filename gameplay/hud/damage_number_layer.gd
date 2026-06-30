extends Node2D
## Floating damage numbers. Spawn numbers at hit positions, pop, float, fade.

const RISE := 60.0
const LIFE := 0.85
const CRIT_LIFE := 1.05
const CRIT_SCALE := 1.55
const STACK_OFFSET := 12.0
const MAX_LABELS := 44
const HARD_LABELS := 58

var _stack_counter: Dictionary = {}

func reset() -> void:
	for child in get_children():
		child.queue_free()
	_stack_counter.clear()

func spawn_damage(position: Vector2, amount: float, element: String, crit := false, weak_hit := false) -> void:
	if amount <= 0.0:
		return
	var important := crit or weak_hit
	if not _reserve_label_slot(important):
		return
	var rounded := int(round(amount))
	var label := Label.new()
	label.set_meta("important_damage", important)
	label.text = str(rounded)
	label.add_theme_font_size_override("font_size", 26 if not crit else 44)
	var color := _damage_color(element)
	if crit:
		color = Color(1.0, 0.94, 0.32) if not weak_hit else Color(1.0, 0.5, 0.18)
	elif weak_hit:
		color = Color(1.0, 0.32, 0.18)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	label.add_theme_constant_override("outline_size", 3 if not crit else 5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(104, 44)
	label.pivot_offset = Vector2(52, 22)
	var stack_offset := _stack_offset(position)
	label.position = position + stack_offset
	add_child(label)
	_stack_counter[position] = stack_offset.y + STACK_OFFSET
	var life := CRIT_LIFE if crit else LIFE
	var rise := RISE * (1.35 if crit else 0.72)
	var target_scale := CRIT_SCALE if crit else 0.96
	var tween := label.create_tween()
	tween.parallel().tween_property(label, "position:y", label.position.y - rise, life)
	tween.parallel().tween_property(label, "modulate:a", 0.0, life)
	if crit:
		tween.parallel().tween_property(label, "scale", Vector2(target_scale, target_scale), 0.08).from(Vector2(0.4, 0.4))
		tween.parallel().tween_property(label, "scale", Vector2(0.95, 0.95), 0.12)
	else:
		tween.parallel().tween_property(label, "scale", Vector2(target_scale, target_scale), 0.08).from(Vector2(0.72, 0.72))
	tween.tween_callback(label.queue_free)
	# decay stack counter
	var decay_t := get_tree().create_timer(0.35)
	decay_t.timeout.connect(_decay_stack.bind(position))

func _reserve_label_slot(important: bool) -> bool:
	if get_child_count() < MAX_LABELS:
		return true
	if not important:
		return false
	for child in get_children():
		if not bool(child.get_meta("important_damage", false)):
			child.queue_free()
			return true
	return get_child_count() < HARD_LABELS

func _decay_stack(pos: Vector2) -> void:
	if _stack_counter.has(pos):
		_stack_counter[pos] -= STACK_OFFSET
		if _stack_counter[pos] <= 0.0:
			_stack_counter.erase(pos)

func _stack_offset(pos: Vector2) -> Vector2:
	var y := float(_stack_counter.get(pos, 0.0))
	var jitter := Vector2(randf_range(-4.0, 4.0), 0.0)
	return Vector2(jitter.x, -y)

func _damage_color(element: String) -> Color:
	match element:
		"fire":
			return Color(1.0, 0.22, 0.16)
		"ice":
			return Color(0.95, 0.28, 0.24)
		"lightning":
			return Color(1.0, 0.26, 0.18)
		"poison":
			return Color(0.86, 0.22, 0.18)
		_:
			return Color(1.0, 0.30, 0.24)
