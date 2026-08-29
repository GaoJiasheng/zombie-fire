extends Label
## TestFlight-only live performance readout. The node is never constructed in
## ordinary release builds.

const SAMPLE_CAP := 240
const REFRESH_SECONDS := 0.5

var _enemy_layer: Node
var _projectile_layer: Node
var _frame_ms: Array[float] = []
var _refresh_left := 0.0

func setup(enemy_layer: Node, projectile_layer: Node) -> void:
	_enemy_layer = enemy_layer
	_projectile_layer = projectile_layer
	name = "TestFlightPerformanceOverlay"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 500
	position = Vector2(666.0, 154.0)
	size = Vector2(382.0, 116.0)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vertical_alignment = VERTICAL_ALIGNMENT_TOP
	add_theme_font_size_override("font_size", 22)
	add_theme_color_override("font_color", Color(0.78, 1.0, 0.86, 0.94))
	add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))
	add_theme_constant_override("outline_size", 4)
	text = "PERF --"

func _process(delta: float) -> void:
	_frame_ms.append(delta * 1000.0)
	if _frame_ms.size() > SAMPLE_CAP:
		_frame_ms.pop_front()
	_refresh_left -= delta
	if _refresh_left > 0.0:
		return
	_refresh_left = REFRESH_SECONDS
	var sorted := _frame_ms.duplicate()
	sorted.sort()
	var p95 := 0.0
	if not sorted.is_empty():
		p95 = sorted[clampi(int(ceil(float(sorted.size()) * 0.95)) - 1, 0, sorted.size() - 1)]
	var enemies := _enemy_layer.get_child_count() if is_instance_valid(_enemy_layer) else 0
	var projectiles := _active_projectile_count()
	text = "FPS %d  P95 %.2f ms\n实体 %d  敌 %d  弹/VFX %d" % [
		Engine.get_frames_per_second(),
		p95,
		enemies + projectiles,
		enemies,
		projectiles,
	]

func _active_projectile_count() -> int:
	if not is_instance_valid(_projectile_layer):
		return 0
	var count := 0
	for child in _projectile_layer.get_children():
		if child.name == "DamageNumbers":
			continue
		if child is CanvasItem and not (child as CanvasItem).visible:
			continue
		count += 1
	return count

