extends Node

signal language_changed(language: String)

const DynamicTranslationScript := preload("res://core/localization/dynamic_translation.gd")
const CATALOG_PATHS := [
	"res://data/localization_ui_en.json",
	"res://data/localization_gameplay_en.json",
	"res://data/localization_story_en.json",
]

var current_language := "zh"
var _translation: Translation
var _translation_registered := false
var _catalog: Dictionary = {}

func _ready() -> void:
	_load_catalog()
	apply_language(SettingsManager.get_language(), false)

func _exit_tree() -> void:
	if _translation != null and _translation_registered:
		TranslationServer.remove_translation(_translation)
	_translation_registered = false
	_translation = null

func apply_language(language: String, persist := true) -> String:
	var normalized := normalize_language(language)
	current_language = normalized
	if persist:
		SettingsManager.set_language(normalized)
	var godot_locale := "en" if normalized == "en" else "zh_CN"
	if normalized == "en" and _translation != null and not _translation_registered:
		TranslationServer.add_translation(_translation)
		_translation_registered = true
	elif normalized == "zh" and _translation != null and _translation_registered:
		# Godot's default fallback locale is English. Unregister the English
		# Translation while Chinese is active so source labels cannot fall
		# through to it after an explicit language switch.
		TranslationServer.remove_translation(_translation)
		_translation_registered = false
	TranslationServer.set_locale(godot_locale)
	get_tree().root.propagate_notification(NOTIFICATION_TRANSLATION_CHANGED)
	language_changed.emit(normalized)
	return normalized

func toggle_language() -> String:
	return apply_language("en" if current_language == "zh" else "zh")

func text(source: Variant) -> String:
	var value := str(source)
	if current_language != "en":
		return value
	return str(TranslationServer.translate(value))

func is_english() -> bool:
	return current_language == "en"

func language_label() -> String:
	return "English" if is_english() else "简体中文"

func normalize_language(language: String) -> String:
	var normalized := language.strip_edges().to_lower().replace("-", "_")
	return "zh" if normalized.begins_with("zh") else "en"

func _load_catalog() -> void:
	_catalog.clear()
	var merged_terms := {}
	for path in CATALOG_PATHS:
		if not FileAccess.file_exists(path):
			push_error("Missing English localization catalog: %s" % path)
			return
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not (parsed is Dictionary):
			push_error("Invalid English localization catalog: %s" % path)
			return
		var part: Dictionary = parsed
		if part.has("__terms") and part["__terms"] is Dictionary:
			merged_terms.merge(part["__terms"], true)
		part = part.duplicate()
		part.erase("__terms")
		_catalog.merge(part, true)
	_catalog["__terms"] = merged_terms
	_translation = DynamicTranslationScript.new()
	_translation.configure(_catalog)
