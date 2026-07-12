extends Node

const SETTINGS_PATH := "user://settings_main.json"
const BATTLE_SPEEDS := [1.0, 2.0, 5.0]

var settings := {
	"quality": "standard",
	"battle_speed": 1.0
}

func _ready() -> void:
	load_settings()
	apply_settings()

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		save_settings()
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
	if parsed is Dictionary:
		settings.merge(parsed, true)

func save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(settings, "\t"))

func cycle_quality() -> String:
	settings["quality"] = "battery" if get_quality() == "standard" else "standard"
	apply_settings()
	save_settings()
	return get_quality()

func get_quality() -> String:
	return str(settings.get("quality", "standard"))

func quality_label() -> String:
	return "标准 60帧" if get_quality() == "standard" else "省电 30帧"

# 战斗加速：只在战斗场景里有意义，不放进 apply_settings()（那个函数管的是
# Engine.max_fps 这种全局即时生效的东西），由 battle.gd 自己读取应用。
func cycle_battle_speed() -> float:
	var idx := BATTLE_SPEEDS.find(get_battle_speed())
	var next: float = BATTLE_SPEEDS[(idx + 1) % BATTLE_SPEEDS.size()] if idx >= 0 else BATTLE_SPEEDS[0]
	settings["battle_speed"] = next
	save_settings()
	return next

func get_battle_speed() -> float:
	return float(settings.get("battle_speed", 1.0))

func apply_settings() -> void:
	Engine.max_fps = 30 if get_quality() == "battery" else 60
