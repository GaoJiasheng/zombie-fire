extends Node

const SETTINGS_PATH := "user://settings_main.json"

var settings := {
	"quality": "standard"
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
	return "标准 60FPS" if get_quality() == "standard" else "省电 30FPS"

func apply_settings() -> void:
	Engine.max_fps = 30 if get_quality() == "battery" else 60
