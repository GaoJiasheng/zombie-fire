extends Node

const ROUTES := {
	"menu": "res://meta/menu/menu.tscn",
	"map": "res://meta/map/map.tscn",
	"loadout": "res://meta/loadout/loadout.tscn",
	"collection": "res://meta/collection/collection.tscn",
	"settings": "res://meta/settings/settings.tscn",
	"battle": "res://gameplay/battle/battle.tscn",
	"result": "res://meta/result/result.tscn",
}

var current_scene: Node
var run_context := {}
var _scene_change_pending := false
var _pending_route := "menu"
var _pending_payload := {}

func _ready() -> void:
	DataLoader.load_all()
	SaveManager.load_game()
	get_tree().paused = false
	Engine.time_scale = 1.0
	change_scene("menu")

func change_scene(route: String, payload := {}) -> void:
	_pending_route = route
	_pending_payload = _normalize_route_payload(route, payload)
	if _scene_change_pending:
		return
	_scene_change_pending = true
	call_deferred("_apply_scene_change")

func _apply_scene_change() -> void:
	_scene_change_pending = false
	var route := _pending_route
	var normalized_payload := _pending_payload
	get_tree().paused = false
	Engine.time_scale = 1.0
	if current_scene:
		remove_child(current_scene)
		current_scene.queue_free()
	var scene_path: String = ROUTES.get(route, ROUTES.get("menu", ""))
	var packed := load(scene_path) as PackedScene
	current_scene = packed.instantiate()
	if current_scene.has_method("setup"):
		current_scene.setup(self, normalized_payload)
	add_child(current_scene)
	# 给 UI 界面统一加“安全区(刘海/灵动岛/home 指示条)”内边距；battle 保持铺满。
	if route != "battle" and current_scene is Control:
		_apply_safe_area(current_scene as Control)

func _apply_safe_area(root: Control) -> void:
	if not OS.get_name() in ["iOS", "Android"]:
		return
	var win := DisplayServer.window_get_size()
	if win.x <= 0 or win.y <= 0:
		return
	var safe := DisplayServer.get_display_safe_area()
	var vis := get_viewport().get_visible_rect().size
	var sx := vis.x / float(win.x)
	var sy := vis.y / float(win.y)
	var top := maxf(float(safe.position.y) * sy, 0.0)
	var bottom := maxf(float(win.y - safe.position.y - safe.size.y) * sy, 0.0)
	var left := maxf(float(safe.position.x) * sx, 0.0)
	var right := maxf(float(win.x - safe.position.x - safe.size.x) * sx, 0.0)
	# 部分机型上 get_display_safe_area() 与窗口尺寸的坐标空间换算会出现偏差，
	# 算出离谱的大内边距，把 Root 大片裁掉、露出下方清屏色形成大黑边(同类问题
	# battle.gd 的 _viewport_safe_insets() 已用 120 上限兜过)。真实刘海/灵动岛/
	# home 指示条不可能吃掉这么多，这里同样夹一个合理上限。
	top = minf(top, 120.0)
	bottom = minf(bottom, 120.0)
	left = minf(left, 120.0)
	right = minf(right, 120.0)
	if top <= 0.5 and bottom <= 0.5 and left <= 0.5 and right <= 0.5:
		return
	# 只内缩“内容”子节点;背景/遮罩(Background/Scrim/Dim/Backdrop)保持满屏,避免灰边。
	for child in root.get_children():
		if not (child is Control):
			continue
		var c := child as Control
		var n := str(c.name).to_lower()
		if n.contains("background") or n.contains("scrim") or n.contains("dim") or n.contains("backdrop") or n == "bg":
			continue
		# 仅处理铺满型内容容器(锚点为全矩形),避免破坏居中弹窗等布局。
		if is_equal_approx(c.anchor_left, 0.0) and is_equal_approx(c.anchor_top, 0.0) and is_equal_approx(c.anchor_right, 1.0) and is_equal_approx(c.anchor_bottom, 1.0):
			c.offset_left = left
			c.offset_top = top
			c.offset_right = -right
			c.offset_bottom = -bottom

func start_level(level_id: String) -> void:
	run_context = {"level_id": level_id}
	change_scene("battle", run_context)

# 无限尸潮：复用某个已解锁关卡的数据作为"种子"(僵尸/环境/元素弱点)，波次打完循环
# 继续、每轮血量递增，直到漏怪耗尽基地生命。不走正常关卡的胜利/解锁流程。
func start_endless_level(seed_level_id: String) -> void:
	run_context = {"level_id": seed_level_id, "endless": true}
	change_scene("battle", run_context)

func finish_level(result: Dictionary, persist := true) -> void:
	var normalized := result.duplicate()
	if bool(normalized.get("endless", false)):
		SaveManager.apply_endless_result(normalized, persist)
		change_scene("result", normalized)
		return
	var active_level_id := _active_level_id()
	var result_level_id := str(normalized.get("level_id", ""))
	if active_level_id != "" and (result_level_id == "" or (result_level_id == "level_001" and active_level_id != "level_001")):
		normalized["level_id"] = active_level_id
	if bool(normalized.get("victory", false)):
		var level_id := str(normalized.get("level_id", ""))
		var next_level := _campaign_next_level(level_id)
		if next_level != "":
			normalized["next_level"] = next_level
	SaveManager.apply_level_result(normalized, persist)
	change_scene("result", normalized)

func _normalize_route_payload(route: String, payload: Variant) -> Dictionary:
	var normalized := {}
	if payload is Dictionary:
		normalized = payload.duplicate()
	if route in ["loadout", "battle", "result"]:
		var payload_level_id := str(normalized.get("level_id", ""))
		if payload_level_id == "":
			var active_level_id := _active_level_id()
			if active_level_id != "":
				normalized["level_id"] = active_level_id
				payload_level_id = active_level_id
		if payload_level_id != "":
			run_context["level_id"] = payload_level_id
	return normalized

func _active_level_id() -> String:
	return str(run_context.get("level_id", ""))

func _campaign_next_level(level_id: String) -> String:
	var levels: Array = DataLoader.get_table("levels")
	for i in range(levels.size() - 1):
		var row: Dictionary = levels[i]
		if str(row.get("id", "")) == level_id:
			var next_row: Dictionary = levels[i + 1]
			return str(next_row.get("id", ""))
	return ""
