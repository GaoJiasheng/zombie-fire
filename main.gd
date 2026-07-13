extends Node

const UiKit := preload("res://ui/ui_kit.gd")

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
var _current_route := ""

func _ready() -> void:
	if not DataLoader.load_all():
		push_error("Fatal data load failure: %s" % ", ".join(DataLoader.load_errors))
		get_tree().quit(2)
		return
	SaveManager.load_game()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_viewport().size_changed.connect(_refresh_safe_area)
	change_scene("menu")

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			if is_instance_valid(InputManager) and InputManager.has_method("cancel_active_input"):
				InputManager.cancel_active_input()
			if is_instance_valid(AudioManager) and AudioManager.has_method("pause_audio"):
				AudioManager.pause_audio()
			if is_instance_valid(SaveManager):
				SaveManager.save_game()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			if is_instance_valid(AudioManager) and AudioManager.has_method("resume_audio"):
				AudioManager.resume_audio()

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
	_current_route = route
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
		if OS.is_debug_build() and OS.get_environment("ZOMBIE_FIRE_UI_AUDIT") == "1":
			call_deferred("_emit_ui_audit", route, current_scene)

func _apply_safe_area(root: Control) -> void:
	UiKit.apply_safe_area_to_root(root, UiKit.safe_area_canvas_insets(get_viewport()))

func _refresh_safe_area() -> void:
	if _current_route == "battle" or not (current_scene is Control):
		return
	_apply_safe_area(current_scene as Control)

func _emit_ui_audit(route: String, scene: Node) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if scene != current_scene or route != _current_route or not (scene is Control):
		return
	var insets := UiKit.safe_area_canvas_insets(get_viewport())
	var issues := UiKit.audit_ui(scene as Control, insets)
	print("UI_AUDIT_JSON:", JSON.stringify({"route": route, "issues": issues, "insets": [insets.x, insets.y, insets.z, insets.w]}))

func start_level(level_id: String) -> void:
	run_context = {"level_id": level_id}
	change_scene("battle", run_context)

func start_challenge_level(level_id: String) -> void:
	run_context = {"level_id": level_id, "challenge": true}
	change_scene("battle", run_context)

# 无限尸潮：复用某个已解锁关卡的数据作为"种子"(僵尸/环境/元素弱点)，波次打完循环
# 继续、每轮血量递增，直到漏怪耗尽基地生命。不走正常关卡的胜利/解锁流程。
func start_endless_level(seed_level_id: String) -> void:
	run_context = {"level_id": seed_level_id, "endless": true}
	change_scene("battle", run_context)

func finish_level(result: Dictionary, persist := true) -> void:
	var normalized := result.duplicate()
	var active_level_id := _active_level_id()
	var result_level_id := str(normalized.get("level_id", ""))
	if active_level_id != "" and (result_level_id == "" or (result_level_id == "level_001" and active_level_id != "level_001")):
		normalized["level_id"] = active_level_id
	if bool(normalized.get("endless", false)):
		SaveManager.apply_endless_result(normalized, persist)
		change_scene("result", normalized)
		return
	if bool(normalized.get("challenge", run_context.get("challenge", false))):
		normalized["challenge"] = true
		normalized.erase("next_level")
		SaveManager.apply_challenge_result(normalized, persist)
		change_scene("result", normalized)
		return
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
		if normalized.has("challenge"):
			if bool(normalized.get("challenge", false)):
				run_context["challenge"] = true
			else:
				run_context.erase("challenge")
		elif route == "loadout":
			run_context.erase("challenge")
		elif bool(run_context.get("challenge", false)):
			normalized["challenge"] = true
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
