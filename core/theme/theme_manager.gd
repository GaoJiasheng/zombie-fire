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
var _preview_theme_id := ""


func _ready() -> void:
	_load_catalog()
	_preview_theme_id = _validated_preview_theme()


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
	_preview_theme_id = _validated_preview_theme()
	var requested := SaveManager.get_selected_theme()
	var resolved := _resolve_allowed_theme(requested)
	if _preview_theme_id != "":
		resolved = _preview_theme_id
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
	if _preview_theme_id == theme_id:
		return true
	var entitlement_id := str((_themes[theme_id] as Dictionary).get("entitlement", ""))
	return entitlement_id != "" and SaveManager.has_verified_entitlement(entitlement_id)


func select_theme(theme_id: String) -> bool:
	if not can_select(theme_id):
		return false
	_preview_theme_id = ""
	_set_active_without_persist(theme_id)
	SaveManager.select_theme(theme_id)
	return true


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
		material.set_shader_parameter("effect_intensity", 0.16)
		material.set_shader_parameter("flow_speed", 0.0)
	else:
		material.set_shader_parameter("effect_intensity", 0.44)
		material.set_shader_parameter("flow_speed", 0.72)
	return material


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


func _validated_preview_theme() -> String:
	if OS.has_feature(TESTFLIGHT_PREVIEW_FEATURE) and _themes.has(TESTFLIGHT_PREVIEW_THEME_ID):
		return TESTFLIGHT_PREVIEW_THEME_ID
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
