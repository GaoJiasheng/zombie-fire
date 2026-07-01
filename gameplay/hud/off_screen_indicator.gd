extends Node2D
## Off-screen enemy indicators. Draws arrows on the left/right edges pointing to enemies
## that have spawned but are not visible in the current viewport rectangle.

const MARGIN := 70.0
const ARROW_SIZE := 56.0
const ENEMY_GROUP := "enemies"

var _arrows_left: Array[Node2D] = []
var _arrows_right: Array[Node2D] = []
var _arrow_template: Texture2D

func _ready() -> void:
	_arrow_template = load("res://assets/production/sprites/vfx/vfx_target_lock.png")
	z_index = 50

func reset() -> void:
	for a in _arrows_left:
		if is_instance_valid(a):
			a.queue_free()
	for a in _arrows_right:
		if is_instance_valid(a):
			a.queue_free()
	_arrows_left.clear()
	_arrows_right.clear()

func refresh(viewport: Rect2, camera_offset: Vector2) -> void:
	if _arrow_template == null or not is_inside_tree():
		return
	_arrows_left = _arrows_left.filter(func(a): return is_instance_valid(a))
	_arrows_right = _arrows_right.filter(func(a): return is_instance_valid(a))
	for arrow in _arrows_left:
		arrow.visible = false
	for arrow in _arrows_right:
		arrow.visible = false
	var left_used := 0
	var right_used := 0
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if not is_instance_valid(enemy):
			continue
		var pos: Vector2 = enemy.global_position
		if viewport.has_point(pos):
			continue
		var to_enemy := pos - viewport.get_center()
		var side := _pick_side(to_enemy)
		if side == 0:
			continue
		var index := right_used if side == 1 else left_used
		var arr := _get_arrow(side, index)
		if side == 1:
			right_used += 1
		else:
			left_used += 1
		var arrow_pos := _arrow_position(side, to_enemy, viewport)
		arr.global_position = arrow_pos
		arr.rotation = _arrow_rotation(side, to_enemy)
		arr.modulate = _threat_color(enemy)
		arr.visible = true

func _pick_side(to_enemy: Vector2) -> int:
	if absf(to_enemy.x) > absf(to_enemy.y) * 1.1:
		return 1 if to_enemy.x > 0 else -1
	if to_enemy.y < 0:
		return 1 if to_enemy.x > 0 else -1
	return 0

func _get_arrow(side: int, index: int) -> Node2D:
	if side == 1:
		while _arrows_right.size() <= index:
			_arrows_right.append(_make_arrow())
		return _arrows_right[index]
	while _arrows_left.size() <= index:
		_arrows_left.append(_make_arrow())
	return _arrows_left[index]

func _make_arrow() -> Node2D:
	var arr := Sprite2D.new()
	arr.texture = _arrow_template
	arr.scale = Vector2(0.18, 0.18)
	arr.visible = false
	add_child(arr)
	return arr

func _arrow_position(side: int, to_enemy: Vector2, viewport: Rect2) -> Vector2:
	var center := viewport.get_center()
	var vertical_clamp := clampf(center.y + to_enemy.y * 0.18, viewport.position.y + MARGIN + ARROW_SIZE, viewport.end.y - MARGIN - ARROW_SIZE)
	if side == 1:
		return Vector2(viewport.end.x - MARGIN - 18.0, vertical_clamp)
	return Vector2(viewport.position.x + MARGIN + 18.0, vertical_clamp)

func _arrow_rotation(side: int, to_enemy: Vector2) -> float:
	var dir := Vector2(to_enemy.x, to_enemy.y * 0.35)
	if side == 1:
		return atan2(dir.y, dir.x) - PI * 0.5
	return atan2(dir.y, dir.x) + PI * 0.5

func _threat_color(enemy: Node) -> Color:
	if enemy.get("boss"):
		return Color(1.0, 0.25, 0.25)
	var tags: Array = enemy.data.get("threat_tags", []) if enemy.get("data") is Dictionary else []
	if tags.has("elite") or tags.has("tank") or tags.has("burst"):
		return Color(1.0, 0.68, 0.25)
	if tags.has("breach") or tags.has("fast"):
		return Color(1.0, 0.85, 0.4)
	return Color(1.0, 1.0, 1.0, 0.85)
