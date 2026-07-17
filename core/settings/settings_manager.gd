extends Node

const SETTINGS_PATH := "user://settings_main.json"
const BATTLE_SPEEDS := [1.0, 2.0, 5.0]
const BATTLE_SPEED_VISIBLE_LEVEL := 30
const BATTLE_SPEED_5X_LEVEL := 50

var settings := {
	"quality": "standard",
	"battle_speed": 1.0,
	"audio_enabled": true,
	"bgm_volume": 0.82,
	"sfx_volume": 0.90,
	"ui_volume": 0.88,
	"reduced_effects": false,
	"haptics": true,
}

func _ready() -> void:
	load_settings()
	apply_settings()
	call_deferred("_apply_audio_settings")

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

func is_audio_enabled() -> bool:
	return bool(settings.get("audio_enabled", true))

func toggle_audio_enabled() -> bool:
	settings["audio_enabled"] = not is_audio_enabled()
	_apply_audio_settings()
	save_settings()
	return is_audio_enabled()

func get_bgm_volume() -> float:
	return clampf(float(settings.get("bgm_volume", 0.82)), 0.0, 1.0)

func get_sfx_volume() -> float:
	return clampf(float(settings.get("sfx_volume", 0.90)), 0.0, 1.0)

func get_ui_volume() -> float:
	return clampf(float(settings.get("ui_volume", 0.88)), 0.0, 1.0)

func set_bgm_volume(value: float) -> void:
	settings["bgm_volume"] = clampf(value, 0.0, 1.0)
	AudioManager.set_bgm_volume(get_bgm_volume())
	save_settings()

func set_sfx_volume(value: float) -> void:
	settings["sfx_volume"] = clampf(value, 0.0, 1.0)
	AudioManager.set_sfx_volume(get_sfx_volume())
	save_settings()

func set_ui_volume(value: float) -> void:
	settings["ui_volume"] = clampf(value, 0.0, 1.0)
	AudioManager.set_ui_volume(get_ui_volume())
	save_settings()

func reduced_effects_enabled() -> bool:
	return bool(settings.get("reduced_effects", false))

func toggle_reduced_effects() -> bool:
	settings["reduced_effects"] = not reduced_effects_enabled()
	save_settings()
	return reduced_effects_enabled()

func haptics_enabled() -> bool:
	return bool(settings.get("haptics", true))

func toggle_haptics() -> bool:
	settings["haptics"] = not haptics_enabled()
	save_settings()
	return haptics_enabled()

func pulse_haptic(kind := "light") -> void:
	if not haptics_enabled() or OS.get_name() != "iOS":
		return
	match kind:
		"heavy":
			Input.vibrate_handheld(90, 0.82)
		"medium":
			Input.vibrate_handheld(55, 0.58)
		_:
			Input.vibrate_handheld(28, 0.34)

# 战斗加速只在战斗场景里有意义，由 battle.gd 按关卡进度传入当前解锁档位。
func cycle_battle_speed(progression_level := BATTLE_SPEED_5X_LEVEL) -> float:
	var available := available_battle_speeds(progression_level)
	var idx := available.find(get_battle_speed(progression_level))
	var next: float = available[(idx + 1) % available.size()] if idx >= 0 else available[0]
	settings["battle_speed"] = next
	save_settings()
	return next

func get_battle_speed(progression_level := BATTLE_SPEED_5X_LEVEL) -> float:
	var stored := float(settings.get("battle_speed", 1.0))
	var available := available_battle_speeds(progression_level)
	var normalized: float = available[0]
	for speed in available:
		if float(speed) <= stored:
			normalized = float(speed)
	return normalized

func is_battle_speed_unlocked(progression_level: int) -> bool:
	return progression_level >= BATTLE_SPEED_VISIBLE_LEVEL

func available_battle_speeds(progression_level: int) -> Array[float]:
	var available: Array[float] = [1.0]
	if progression_level >= BATTLE_SPEED_VISIBLE_LEVEL:
		available.append(2.0)
	if progression_level >= BATTLE_SPEED_5X_LEVEL:
		available.append(5.0)
	return available

func apply_settings() -> void:
	Engine.max_fps = 30 if get_quality() == "battery" else 60
	_apply_audio_settings()

func _apply_audio_settings() -> void:
	if not is_instance_valid(AudioManager):
		return
	AudioManager.set_enabled(is_audio_enabled())
	AudioManager.set_bgm_volume(get_bgm_volume())
	AudioManager.set_sfx_volume(get_sfx_volume())
	AudioManager.set_ui_volume(get_ui_volume())
