extends Node

const SETTINGS_PATH := "user://settings_main.json"
const BATTLE_SPEEDS := [1.0, 2.0, 5.0]
const BATTLE_SPEED_VISIBLE_LEVEL := 30
const BATTLE_SPEED_5X_LEVEL := 50
const TESTFLIGHT_SPEED_FEATURE := "testflight_speed_unlocked"
const TESTFLIGHT_FIRERATE_FEATURE := "testflight_firerate_lab"

var settings := {
	"language": _system_default_language(),
	"quality": "standard",
	"battle_speed": 1.0,
	"fire_rate_profile": "tier_b",
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
		var had_language: bool = parsed.has("language")
		settings.merge(parsed, true)
		# Existing Chinese-only installs stay Chinese until the player explicitly
		# changes language. Fresh installs follow the device language.
		if not had_language:
			settings["language"] = "zh"

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

func get_language() -> String:
	return _normalize_language(str(settings.get("language", _system_default_language())))

func set_language(language: String) -> String:
	settings["language"] = _normalize_language(language)
	save_settings()
	return get_language()

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
	return is_testflight_speed_unlocked() or progression_level >= BATTLE_SPEED_VISIBLE_LEVEL

func available_battle_speeds(progression_level: int) -> Array[float]:
	var available: Array[float] = [1.0]
	if is_testflight_speed_unlocked():
		available.append(2.0)
		available.append(5.0)
		return available
	if progression_level >= BATTLE_SPEED_VISIBLE_LEVEL:
		available.append(2.0)
	if progression_level >= BATTLE_SPEED_5X_LEVEL:
		available.append(5.0)
	return available

func is_testflight_speed_unlocked() -> bool:
	return OS.has_feature(TESTFLIGHT_SPEED_FEATURE)

func has_fire_rate_lab() -> bool:
	return OS.has_feature(TESTFLIGHT_FIRERATE_FEATURE)

func get_fire_rate_profile() -> String:
	var table: Dictionary = DataLoader.get_table("economy").get("fire_rate_profiles", {})
	var default_profile := str(table.get("default", "tier_b"))
	# Formal/release packages have no selector and are hard-locked to the
	# frozen shipping profile even if a TestFlight settings file survives.
	if not has_fire_rate_lab():
		return default_profile
	var order: Array = table.get("order", ["control"])
	var stored := str(settings.get("fire_rate_profile", default_profile))
	return stored if order.has(stored) else default_profile

func cycle_fire_rate_profile() -> String:
	if not has_fire_rate_lab():
		return get_fire_rate_profile()
	var table: Dictionary = DataLoader.get_table("economy").get("fire_rate_profiles", {})
	var order: Array = table.get("order", ["control"])
	if order.is_empty():
		return "control"
	var current := get_fire_rate_profile()
	var index := order.find(current)
	var next_id := str(order[(index + 1) % order.size()]) if index >= 0 else str(order[0])
	settings["fire_rate_profile"] = next_id
	save_settings()
	return next_id

func fire_rate_profile_label(profile_id := "") -> String:
	var resolved := get_fire_rate_profile() if profile_id.is_empty() else profile_id
	match resolved:
		"tier_a":
			return LocalizationManager.text("A档")
		"tier_b":
			return LocalizationManager.text("B档")
		_:
			return LocalizationManager.text("对照档")

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

func _normalize_language(language: String) -> String:
	return "zh" if language.strip_edges().to_lower().begins_with("zh") else "en"

func _system_default_language() -> String:
	return _normalize_language(OS.get_locale_language())
