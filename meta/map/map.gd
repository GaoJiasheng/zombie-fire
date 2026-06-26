extends Control

const BUTTON_PRIMARY := "res://assets/sprites/ui/ui_button_primary.png"
const BUTTON_SECONDARY := "res://assets/sprites/ui/ui_button_secondary.png"

var router: Node

func setup(main: Node, _payload := {}) -> void:
	router = main

func _ready() -> void:
	AudioManager.play_bgm("map")
	SaveManager.repair_progression_unlocks()
	_refresh_header()
	_build_nav()
	_build_levels()

func _refresh_header() -> void:
	var total_stars: int = DataLoader.get_table("levels").size() * 3
	$Progress.text = "金币 %d   星星 %d/%d   战力 %d" % [SaveManager.get_player_gold(), SaveManager.get_total_stars(), total_stars, SaveManager.get_loadout_power()]

func _build_levels() -> void:
	for child in $LevelScroll/LevelList.get_children():
		child.queue_free()
	var levels: Array = DataLoader.get_table("levels")
	for level in levels:
		var level_id: String = level.get("id", "level_001")
		var unlocked := SaveManager.is_level_unlocked(level_id)
		var stars := SaveManager.get_level_stars(level_id)
		$LevelScroll/LevelList.add_child(_build_level_card(level_id, level, unlocked, stars))

func _build_nav() -> void:
	for child in $Nav.get_children():
		child.queue_free()
	for item in [
		["角色", "characters"],
		["武器", "weapons"],
		["护甲", "armors"],
		["芯片", "chips"],
		["宠物", "pets"],
		["技能", "skills"],
	]:
			var button := Button.new()
			button.text = str(item[0])
			button.custom_minimum_size = Vector2(140, 58)
			button.pressed.connect(_open_collection.bind(str(item[1])))
			$Nav.add_child(button)

func _open_collection(mode: String) -> void:
	AudioManager.play_sfx("ui_click")
	router.change_scene("collection", {"mode": mode})

func _build_level_card(level_id: String, level: Dictionary, unlocked: bool, stars: int) -> TextureButton:
	var button := TextureButton.new()
	button.custom_minimum_size = Vector2(760, 112)
	button.texture_normal = load(BUTTON_PRIMARY if unlocked else BUTTON_SECONDARY)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.clip_contents = true
	button.disabled = not unlocked
	button.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.55, 0.55, 0.55, 0.86)
	if unlocked:
		button.pressed.connect(_open_level.bind(level_id))

	var title := Label.new()
	title.text = DataLoader.level_display_name(level_id)
	title.position = Vector2(34, 14)
	title.size = Vector2(390, 44)
	title.add_theme_font_size_override("font_size", 31)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(title)

	var meta := Label.new()
	meta.text = "推荐战力 %d  ·  %s  ·  弱%s" % [SaveManager.get_recommended_power_for_level(level_id), "已解锁" if unlocked else "未解锁", _element_name(str(level.get("primary_weakness", "physical")))]
	meta.position = Vector2(36, 62)
	meta.size = Vector2(390, 34)
	meta.add_theme_font_size_override("font_size", 22)
	meta.add_theme_color_override("font_color", Color(0.72, 0.9, 1.0) if unlocked else Color(0.75, 0.75, 0.75))
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(meta)

	var star := Label.new()
	star.text = _stars_text(stars)
	star.position = Vector2(520, 28)
	star.size = Vector2(200, 50)
	star.add_theme_font_size_override("font_size", 34)
	star.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2) if stars > 0 else Color(0.72, 0.72, 0.72))
	star.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(star)
	return button

func _open_level(level_id: String) -> void:
	AudioManager.play_sfx("ui_confirm")
	router.change_scene("loadout", {"level_id": level_id})

func _stars_text(count: int) -> String:
	var text := ""
	for i in range(3):
		text += "★" if i < count else "☆"
	return text

func _element_name(element: String) -> String:
	match element:
		"physical":
			return "物"
		"fire":
			return "火"
		"ice":
			return "冰"
		"lightning":
			return "电"
		"poison":
			return "毒"
		_:
			return element
