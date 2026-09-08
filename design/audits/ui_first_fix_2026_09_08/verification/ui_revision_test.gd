extends SceneTree

const Effects := preload("res://core/data/skill_effect_text.gd")
var failures: Array[String] = []

func _expect(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _settle() -> void:
	for frame in range(16):
		await process_frame

func _initialize() -> void:
	for bus in range(AudioServer.bus_count):
		AudioServer.set_bus_mute(bus, true)
	await process_frame
	root.size = Vector2i(1080, 1920)
	var save = root.get_node("SaveManager")
	save.suppress_persistence_for_captures = true
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await _settle()
	var localization = root.get_node("LocalizationManager")
	var data = root.get_node("DataLoader")
	for key in ["base_hp_mult", "lane_damage_bonus", "dmg_mult", "fire_rate_mult"]:
		_expect(Effects._value_text_for_key(key, 1.2) == "120%", key + " must preserve percentage units above 100%")
	for count in [3, 4, 5]:
		_expect(Effects._value_text_for_key("extra_projectiles", count) == str(count), "projectile counts must remain counts")
	for language in ["zh", "en"]:
		localization.apply_language(language, false)
		main.change_scene("map")
		await _settle()
		var titles: Array = main.current_scene.find_children("ChapterTitle", "Label", true, false)
		_expect(titles.size() == 10, "chapter title regression must cover all ten zones")
		for title in titles:
			_expect(title.get_visible_line_count() >= title.get_line_count(), "chapter title must retain full line height: " + language + " " + title.text)
		for action in main.current_scene.find_children("EnterChapterButton", "TextureButton", true, false):
			_expect(action.size == Vector2(286, 80), "chapter primary action must retain native 286x80, actual=" + str(action.size))
		main.change_scene("collection", {"mode": "characters"})
		await _settle()
		var collection = main.current_scene
		_expect(collection._value_text(0.00336) == "0.34%", "nonzero chip upgrade must not display 0%")
		_expect(collection._value_text(0.0) == "0%", "zero must retain existing format")
		var armor: Dictionary = data.get_row("armors", "armor_apocalypse_eternal_night")
		_expect(is_equal_approx(collection._armor_display_multiplier(armor, 1), float(armor.hp_mult)), "level-one armor display must match its authored base")
		var expected: float = float(armor.hp_mult) * (1.0 + float(armor.level_hp_growth) * 34.0)
		_expect(is_equal_approx(collection._armor_display_multiplier(armor, 35), expected), "armor summary must include existing level growth")
		collection._show_character_detail("frost", data.get_row("characters", "frost"))
		await _settle()
		var select = collection.find_child("SelectButton", true, false)
		_expect(select != null and select.disabled, "locked hero must not expose an enabled Select action")
		main.change_scene("result", {"victory": true, "level_id": "level_004", "stars": 3})
		await _settle()
		var hero: Label = main.current_scene.get_node("Content/HeroCard/HeroBox/OutcomePanel/OutcomeRow/OutcomeCopy/HeroName")
		_expect(hero.get_visible_line_count() >= hero.get_line_count(), "result outcome must retain every line: " + language)
	main.queue_free()
	await _settle()
	print("UI revision regression: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
