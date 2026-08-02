extends Node

signal theme_changed(theme_id: String)
signal character_outfit_changed(character_id: String, outfit_mode: String)

const CATALOG_PATH := "res://data/themes.json"
const DEFAULT_THEME_ID := "default"
const PREVIEW_ENV := "ZOMBIE_FIRE_THEME_PREVIEW"
const TESTFLIGHT_PREVIEW_FEATURE := "neon_tempest_preview"
const OUTFIT_FOLLOW_THEME := "follow_theme"

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
	_sanitize_character_outfits()
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
	return entitlement_id != "" and PurchaseManager.has_entitlement(entitlement_id)


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
	return (
		OS.has_feature(TESTFLIGHT_PREVIEW_FEATURE)
		or (OS.is_debug_build() and OS.get_environment(PREVIEW_ENV).strip_edges() != "")
	)


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


func catalog_themes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for theme_id_var in _themes.keys():
		result.append((_themes[str(theme_id_var)] as Dictionary).duplicate(true))
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


func theme_description(theme_id: String) -> String:
	var theme: Dictionary = _themes.get(theme_id, {})
	return str(theme.get(
		"description_en" if LocalizationManager.is_english() else "description_zh",
		""
	))


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


func character_outfit_mode(character_id: String) -> String:
	var mode := SaveManager.get_character_outfit(character_id)
	return mode if _is_valid_outfit_mode(mode) else OUTFIT_FOLLOW_THEME


func effective_character_theme_id(character_id: String) -> String:
	var mode := character_outfit_mode(character_id)
	return _active_theme_id if mode == OUTFIT_FOLLOW_THEME else mode


func can_select_character_outfit(outfit_mode: String) -> bool:
	return outfit_mode == OUTFIT_FOLLOW_THEME or can_select(outfit_mode)


func select_character_outfit(character_id: String, outfit_mode: String, persist := true) -> bool:
	if not can_select_character_outfit(outfit_mode):
		return false
	var normalized_character_id := character_id.trim_prefix("char_")
	SaveManager.select_character_outfit(normalized_character_id, outfit_mode, persist)
	character_outfit_changed.emit(normalized_character_id, outfit_mode)
	return true


func apply_theme_to_all_characters(theme_id: String) -> bool:
	if not can_select(theme_id):
		return false
	_forced_preview_theme_id = ""
	_set_active_without_persist(theme_id)
	SaveManager.select_theme(theme_id, false)
	for character_id in _character_ids():
		SaveManager.select_character_outfit(character_id, OUTFIT_FOLLOW_THEME, false)
		character_outfit_changed.emit(character_id, OUTFIT_FOLLOW_THEME)
	SaveManager.save_game()
	return true


func character_uses_theme(character_id: String, theme_id: String) -> bool:
	return effective_character_theme_id(character_id) == theme_id


func resolve_character_portrait(character_id: String, fallback_path: String) -> String:
	return resolve_character_portrait_for_theme(
		character_id,
		effective_character_theme_id(character_id),
		fallback_path
	)


func resolve_character_portrait_for_theme(character_id: String, theme_id: String, fallback_path: String) -> String:
	if theme_id == DEFAULT_THEME_ID:
		return fallback_path
	var theme: Dictionary = _themes.get(theme_id, {})
	var characters: Dictionary = theme.get("characters", {})
	var portrait_root := str(characters.get("portrait_root", "")).trim_suffix("/")
	if portrait_root == "":
		return fallback_path
	var asset_id := character_id if character_id.begins_with("char_") else "char_%s" % character_id
	var candidate := "%s/%s_portrait_frameless.png" % [portrait_root, asset_id]
	return candidate if _resource_or_file_exists(candidate) else fallback_path


func resolve_character_animation_base(character_id: String) -> String:
	var character_theme_id := effective_character_theme_id(character_id)
	if character_theme_id == DEFAULT_THEME_ID:
		return ""
	var theme: Dictionary = _themes.get(character_theme_id, {})
	var characters: Dictionary = theme.get("characters", {})
	var animation_root := str(characters.get("battle_animation_root", "")).trim_suffix("/")
	if animation_root == "":
		return ""
	var asset_id := character_id if character_id.begins_with("char_") else "char_%s" % character_id
	var candidate := "%s/%s/%s" % [animation_root, asset_id, asset_id]
	return candidate if _resource_or_file_exists("%s_idle_01.png" % candidate) else ""


func resolve_weapon_asset(weapon_id: String, kind: String, fallback_path: String) -> String:
	if _active_theme_id == DEFAULT_THEME_ID:
		return fallback_path
	var theme: Dictionary = _themes.get(_active_theme_id, {})
	var weapons: Dictionary = theme.get("weapons", {})
	var asset_root := str(weapons.get("asset_root", "")).trim_suffix("/")
	if asset_root == "" or not kind in ["icon", "handheld", "turret"]:
		return fallback_path
	# Premium weapons carry their own authored identity. A cosmetic theme only
	# recolors the eight free weapons; it never overwrites another paid set.
	if weapon_id.begins_with("weapon_apocalypse_"):
		return fallback_path
	var candidate := "%s/%s_%s.png" % [asset_root, weapon_id, kind]
	return candidate if _resource_or_file_exists(candidate) else fallback_path


func resolve_ui_asset(asset_id: String, fallback_path := "") -> String:
	if _active_theme_id == DEFAULT_THEME_ID:
		return fallback_path
	var theme: Dictionary = _themes.get(_active_theme_id, {})
	var ui: Dictionary = theme.get("ui", {})
	var assets: Dictionary = ui.get("assets", {})
	var candidate := str(assets.get(asset_id, ""))
	return candidate if candidate != "" and _resource_or_file_exists(candidate) else fallback_path


func active_ui_asset_presentation(asset_id: String) -> Dictionary:
	var theme: Dictionary = _themes.get(_active_theme_id, {})
	var ui: Dictionary = theme.get("ui", {})
	var presentations: Dictionary = ui.get("asset_presentations", {})
	return (presentations.get(asset_id, {}) as Dictionary).duplicate(true)


func active_effect_profile() -> String:
	return _effect_profile_for_theme(_active_theme_id)


func character_effect_profile(character_id: String) -> String:
	return _effect_profile_for_theme(effective_character_theme_id(character_id))


func active_projectile_palette_profile() -> String:
	var theme: Dictionary = _themes.get(_active_theme_id, {})
	var effects: Dictionary = theme.get("effects", {})
	return str(effects.get("projectile_palette_profile", ""))


func button_surface_modulate(primary: bool, enabled: bool) -> Color:
	var theme: Dictionary = _themes.get(_active_theme_id, {})
	var ui: Dictionary = theme.get("ui", {})
	var spec: Dictionary = ui.get("surface_modulate", {})
	var key := "disabled" if not enabled else ("primary" if primary else "secondary")
	return _color_from_data(spec.get(key, []), Color.WHITE)


func active_ui_accent(fallback := Color(0.88, 0.64, 0.32, 1.0)) -> Color:
	var theme: Dictionary = _themes.get(_active_theme_id, {})
	var ui: Dictionary = theme.get("ui", {})
	return _color_from_data(ui.get("accent_color", []), fallback)


func active_tag_palette() -> Dictionary:
	return tag_palette_for_theme(_active_theme_id)


func tag_palette_for_theme(theme_id: String) -> Dictionary:
	# Semantic micro-labels need their own contrast contract. Reusing the broad
	# theme accent over textured cards made their edges disappear, especially on
	# tall phone captures. Keep this data-driven so every theme remains legible.
	var theme: Dictionary = _themes.get(theme_id, _themes.get(DEFAULT_THEME_ID, {}))
	var ui: Dictionary = theme.get("ui", {})
	var spec: Dictionary = ui.get("tag_palette", {})
	return {
		"border": _color_from_data(spec.get("border", []), Color(0.34, 0.76, 0.84, 1.0)),
		"kind_border": _color_from_data(spec.get("kind_border", []), Color(0.94, 0.67, 0.32, 1.0)),
		"fill": _color_from_data(spec.get("fill", []), Color(0.018, 0.060, 0.074, 0.96)),
		"kind_fill": _color_from_data(spec.get("kind_fill", []), Color(0.105, 0.064, 0.025, 0.97)),
		"text": _color_from_data(spec.get("text", []), Color(0.91, 0.98, 1.0, 1.0)),
		"kind_text": _color_from_data(spec.get("kind_text", []), Color(1.0, 0.91, 0.71, 1.0)),
	}


func character_material_enabled(character_id := "") -> bool:
	var theme_id := _active_theme_id if character_id == "" else effective_character_theme_id(character_id)
	return not _material_spec(theme_id, "character").is_empty()


func create_character_material(character_id := "") -> ShaderMaterial:
	var theme_id := _active_theme_id if character_id == "" else effective_character_theme_id(character_id)
	return _create_theme_material(theme_id, "character")


func create_surface_material() -> ShaderMaterial:
	return _create_theme_material(_active_theme_id, "surface")


func character_material_pulse_parameter(character_id := "") -> String:
	var theme_id := _active_theme_id if character_id == "" else effective_character_theme_id(character_id)
	return str(_material_spec(theme_id, "character").get("pulse_parameter", ""))


func _effect_profile_for_theme(theme_id: String) -> String:
	var theme: Dictionary = _themes.get(theme_id, {})
	var effects: Dictionary = theme.get("effects", {})
	return str(effects.get("profile", ""))


func _material_spec(theme_id: String, kind: String) -> Dictionary:
	var theme: Dictionary = _themes.get(theme_id, {})
	var materials: Dictionary = theme.get("materials", {})
	return (materials.get(kind, {}) as Dictionary).duplicate(true)


func _create_theme_material(theme_id: String, kind: String) -> ShaderMaterial:
	var spec := _material_spec(theme_id, kind)
	var shader_path := str(spec.get("shader", ""))
	if shader_path == "" or not _resource_or_file_exists(shader_path):
		return null
	var shader := load(shader_path) as Shader
	if shader == null:
		return null
	var material := ShaderMaterial.new()
	material.shader = shader
	var parameter_key := "reduced" if SettingsManager.reduced_effects_enabled() else "full"
	var parameters: Dictionary = spec.get(parameter_key, {})
	for parameter_var in parameters.keys():
		material.set_shader_parameter(str(parameter_var), parameters[parameter_var])
	return material


func _color_from_data(value: Variant, fallback: Color) -> Color:
	if not value is Array or value.size() < 3:
		return fallback
	return Color(
		float(value[0]),
		float(value[1]),
		float(value[2]),
		float(value[3]) if value.size() >= 4 else 1.0
	)


func resolve_character_effect_sequence(character_id: String, effect_id: String) -> Array[Texture2D]:
	return _resolve_effect_sequence_for_theme(effective_character_theme_id(character_id), effect_id)


func resolve_effect_sequence(effect_id: String) -> Array[Texture2D]:
	return _resolve_effect_sequence_for_theme(_active_theme_id, effect_id)


func _resolve_effect_sequence_for_theme(theme_id: String, effect_id: String) -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	if theme_id == DEFAULT_THEME_ID:
		return result
	var theme: Dictionary = _themes.get(theme_id, {})
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


func _sanitize_character_outfits() -> void:
	var changed := false
	for character_id in _character_ids():
		var requested := SaveManager.get_character_outfit(character_id)
		if _is_valid_outfit_mode(requested) and can_select_character_outfit(requested):
			continue
		SaveManager.select_character_outfit(character_id, OUTFIT_FOLLOW_THEME, false)
		changed = true
	if changed:
		SaveManager.save_game()


func _is_valid_outfit_mode(outfit_mode: String) -> bool:
	return outfit_mode == OUTFIT_FOLLOW_THEME or _themes.has(outfit_mode)


func _character_ids() -> Array[String]:
	var result: Array[String] = []
	var table: Dictionary = DataLoader.get_table("characters")
	for character_id_var in table.keys():
		result.append(str(character_id_var).trim_prefix("char_"))
	result.sort()
	return result


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
