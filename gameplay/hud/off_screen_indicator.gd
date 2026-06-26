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
	_arrow_template = load("res://assets/sprites/vfx/vfx_target_lock.png")
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
	# Trim stale arrows
	_arrows_left = _arrows_left.filter(func(a): return is_instance_valid(a))
	_arrows_right = _arrows_right.filter(func(a): return is_instance_valid(a))
	var used: Dictionary = {}
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
		var arr := _get_arrow(side)
		var arrow_pos := _arrow_position(side, to_enemy, viewport)
		arr.global_position = arrow_pos
		arr.rotation = _arrow_rotation(side, to_enemy)
		arr.modulate = _threat_color(enemy)
		used[arr.get_instance_id()] = true
	_cleanup_unused(used)

func _pick_side(to_enemy: Vector2) -> int:
	if absf(to_enemy.x) > absf(to_enemy.y) * 1.1:
		return 1 if to_enemy.x > 0 else -1
	if to_enemy.y < 0:
		return 1 if to_enemy.x > 0 else -1
	return 0

func _get_arrow(side: int) -> Node2D:
	var pool: Array = _arrows_right if side == 1 else _arrows_left
	if pool.is_empty():
		var arr := Sprite2D.new()
		arr.texture = _arrow_template
		arr.scale = Vector2(0.18, 0.18)
		add_child(arr)
		pool.append(arr)
		return arr
	return pool.pop_back()

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

func _cleanup_unused(used: Dictionary) -> void:
	for a in _arrows_left:
		if not used.has(a.get_instance_id()):
			a.visible = false
	for a in _arrows_right:
		if not used.has(a.get_instance_id()):
			a.visible = false
	for a in _arrows_left:
		if a.visible:
			_arrows_left.append(a)
		else:
			_arrows_right.append(a)  # re-pool
	_arrows_left.clear()
	_arrows_right.clear()
	# restore visibility
	for a in get_children():
		a.visible = used.has(a.get_instance_id()) if a is Sprite2D else a.visible
