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

func start_level(level_id: String) -> void:
	run_context = {"level_id": level_id}
	change_scene("battle", run_context)

func finish_level(result: Dictionary, persist := true) -> void:
	var normalized := result.duplicate()
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
