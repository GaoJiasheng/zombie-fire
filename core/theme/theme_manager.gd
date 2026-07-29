extends Node

signal theme_changed(theme_id: String)

const CATALOG_PATH := "res://data/themes.json"
const DEFAULT_THEME_ID := "default"
const PREVIEW_ENV := "ZOMBIE_FIRE_THEME_PREVIEW"
const TESTFLIGHT_PREVIEW_FEATURE := "neon_tempest_preview"
const TESTFLIGHT_PREVIEW_THEME_ID := "neon_tempest"
const CHARACTER_IRIDESCENCE_SHADER := preload(
	"res://gameplay/vfx/shaders/neon_tempest_character.gdshader"
)

var _themes: Dictionary = {}
var _active_theme_id := DEFAULT_THEME_ID
var _forced_preview_theme_id := ""


func _ready() -> void:
	_load_catalog()
	_forced_preview_theme_id = _validated_forced_preview_theme()


func _load_catalog() -> void:
	_themes.clear()
	if not FileAccess.file_exists(CATALOG_PATH):
		push_error("ThemeManager: missing catalog %s" % CATALOG_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if not parsed is Dictionary:
		push_error("ThemeManager: catalog root must be a dictionary")
		return
	for raw_theme in parsed.get("themes", []):
		if not raw_theme is Dictionary:
			continue
		var theme: Dictionary = raw_theme
		var theme_id := str(theme.get("id", "")).strip_edges()
		if theme_id != "":
			_themes[theme_id] = theme.duplicate(true)
	if not _themes.has(DEFAULT_THEME_ID):
		push_error("ThemeManager: catalog must define the default theme")


func refresh_from_save() -> String:
	_forced_preview_theme_id = _validated_forced_preview_theme()
	var requested := SaveManager.get_selected_theme()
	var resolved := _resolve_allowed_theme(requested)
	if _forced_preview_theme_id != "":
		resolved = _forced_preview_theme_id
	_set_active_without_persist(resolved)
	return _active_theme_id


func active_theme_id() -> String:
	return _active_theme_id


func active_theme() -> Dictionary:
	return (_themes.get(_active_theme_id, {}) as Dictionary).duplicate(true)


func is_active(theme_id: String) -> bool:
	return _active_theme_id == theme_id


func can_select(theme_id: String) -> bool:
	if theme_id == DEFAULT_THEME_ID:
		return true
	if not _themes.has(theme_id):
		return false
	if preview_access_enabled():
		return true
	var entitlement_id := str((_themes[theme_id] as Dictionary).get("entitlement", ""))
	return entitlement_id != "" and SaveManager.has_verified_entitlement(entitlement_id)


func select_theme(theme_id: String) -> bool:
	if not can_select(theme_id):
		return false
	_forced_preview_theme_id = ""
	_set_active_without_persist(theme_id)
	SaveManager.select_theme(theme_id)
	return true


func preview_access_enabled() -> bool:
	# TestFlight/dev preview access deliberately grants selection only. It never
	# writes a commerce entitlement and it no longer forces Neon Tempest on every
	# launch, so reviewers/testers can compare the default and premium treatments.
	return OS.has_feature(TESTFLIGHT_PREVIEW_FEATURE) or OS.is_debug_build()


func available_themes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for theme_id_var in _themes.keys():
		var theme_id := str(theme_id_var)
		if can_select(theme_id):
			result.append((_themes[theme_id] as Dictionary).duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if str(a.get("id", "")) == DEFAULT_THEME_ID:
			return true
		if str(b.get("id", "")) == DEFAULT_THEME_ID:
			return false
		return str(a.get("id", "")) < str(b.get("id", ""))
	)
	return result


func theme_display_name(theme_id: String) -> String:
	var theme: Dictionary = _themes.get(theme_id, {})
	if theme.is_empty():
		return theme_id
	return str(theme.get("name_en" if LocalizationManager.is_english() else "name_zh", theme_id))


func resolve_button_path(kind: String, native_size: Vector2i, disabled := false) -> String:
	if _active_theme_id == DEFAULT_THEME_ID:
		return ""
	var theme: Dictionary = _themes.get(_active_theme_id, {})
	var ui: Dictionary = theme.get("ui", {})
	var button_root := str(ui.get("button_root", "")).trim_suffix("/")
	if button_root == "":
		return ""
	var resolved_kind := "secondary" if disabled else kind
	var candidate := "%s/ui_button_%s_native_%dx%d.png" % [
		button_root,
		resolved_kind,
		native_size.x,
		native_size.y,
	]
	return candidate if _resource_or_file_exists(candidate) else ""


func resolve_character_portrait(character_id: String, fallback_path: String) -> String:
	if _active_theme_id == DEFAULT_THEME_ID:
		return fallback_path
	var theme: Dictionary = _themes.get(_active_theme_id, {})
	var characters: Dictionary = theme.get("characters", {})
	var portrait_root := str(characters.get("portrait_root", "")).trim_suffix("/")
	if portrait_root == "":
		return fallback_path
	var asset_id := character_id if character_id.begins_with("char_") else "char_%s" % character_id
	var candidate := "%s/%s_portrait_frameless.png" % [portrait_root, asset_id]
	return candidate if _resource_or_file_exists(candidate) else fallback_path


func resolve_character_animation_base(character_id: String) -> String:
	if _active_theme_id == DEFAULT_THEME_ID:
		return ""
	var theme: Dictionary = _themes.get(_active_theme_id, {})
	var characters: Dictionary = theme.get("characters", {})
	var animation_root := str(characters.get("battle_animation_root", "")).trim_suffix("/")
	if animation_root == "":
		return ""
	var asset_id := character_id if character_id.begins_with("char_") else "char_%s" % character_id
	var candidate := "%s/%s/%s" % [animation_root, asset_id, asset_id]
	return candidate if _resource_or_file_exists("%s_idle_01.png" % candidate) else ""


func character_iridescence_enabled() -> bool:
	if _active_theme_id == DEFAULT_THEME_ID:
		return false
	var theme: Dictionary = _themes.get(_active_theme_id, {})
	var effects: Dictionary = theme.get("effects", {})
	return bool(effects.get("character_iridescence", false))


func create_character_iridescence_material() -> ShaderMaterial:
	if not character_iridescence_enabled():
		return null
	var material := ShaderMaterial.new()
	material.shader = CHARACTER_IRIDESCENCE_SHADER
	if SettingsManager.reduced_effects_enabled():
		material.set_shader_parameter("effect_intensity", 0.24)
		material.set_shader_parameter("flow_speed", 0.0)
	else:
		material.set_shader_parameter("effect_intensity", 0.58)
		material.set_shader_parameter("flow_speed", 0.46)
	material.set_shader_parameter("fire_pulse", 0.0)
	return material


func create_neon_surface_material() -> ShaderMaterial:
	if not character_iridescence_enabled():
		return null
	var material := create_character_iridescence_material()
	if material == null:
		return null
	material.set_shader_parameter("head_protection", 0.0)
	material.set_shader_parameter("effect_intensity", 0.42 if SettingsManager.reduced_effects_enabled() else 0.64)
	return material


func resolve_effect_sequence(effect_id: String) -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	if _active_theme_id == DEFAULT_THEME_ID:
		return result
	var theme: Dictionary = _themes.get(_active_theme_id, {})
	var effects: Dictionary = theme.get("effects", {})
	var spec: Dictionary = effects.get(effect_id, {})
	var base := str(spec.get("base", "")).trim_suffix("_")
	var frame_count := int(spec.get("frames", 0))
	if base == "" or frame_count <= 0:
		return result
	for index in range(1, frame_count + 1):
		var candidate := "%s_%02d.png" % [base, index]
		if not _resource_or_file_exists(candidate):
			return []
		var texture := load(candidate) as Texture2D
		if texture == null:
			return []
		result.append(texture)
	return result


func _resolve_allowed_theme(requested: String) -> String:
	if can_select(requested):
		return requested
	if requested != DEFAULT_THEME_ID:
		SaveManager.select_theme(DEFAULT_THEME_ID)
	return DEFAULT_THEME_ID


func _set_active_without_persist(theme_id: String) -> void:
	var resolved := theme_id if _themes.has(theme_id) else DEFAULT_THEME_ID
	if _active_theme_id == resolved:
		return
	_active_theme_id = resolved
	theme_changed.emit(_active_theme_id)


func _validated_forced_preview_theme() -> String:
	# The environment route remains deterministic for screenshot fixtures. The
	# TestFlight feature itself only unlocks the selector (see preview_access_enabled).
	if not OS.is_debug_build():
		return ""
	var requested := OS.get_environment(PREVIEW_ENV).strip_edges()
	if requested != "" and _themes.has(requested):
		return requested
	return ""


func _resource_or_file_exists(path: String) -> bool:
	if ResourceLoader.exists(path):
		return true
	if not path.begins_with("res://"):
		return false
	return FileAccess.file_exists(ProjectSettings.globalize_path(path))
