extends Control

const UiKit := preload("res://ui/ui_kit.gd")
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
	(%Progress as Label).text = "金币 %d   星星 %d/%d   战力 %d" % [SaveManager.get_player_gold(), SaveManager.get_total_stars(), total_stars, SaveManager.get_loadout_power()]

func _build_levels() -> void:
	var level_list := %LevelList as VBoxContainer
	for child in level_list.get_children():
		child.queue_free()
	var levels: Array = DataLoader.get_table("levels")
	for level in levels:
		var level_id: String = level.get("id", "level_001")
		var unlocked := SaveManager.is_level_unlocked(level_id)
		var stars := SaveManager.get_level_stars(level_id)
		level_list.add_child(_build_level_card(level_id, level, unlocked, stars))

func _build_nav() -> void:
	var nav := %Nav as HBoxContainer
	for child in nav.get_children():
		child.queue_free()
	var dock := PanelContainer.new()
	dock.name = "FeatureDock"
	dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dock.custom_minimum_size = Vector2(0, 142)
	dock.add_theme_stylebox_override("panel", _build_nav_dock_style())
	nav.add_child(dock)

	var bar := HBoxContainer.new()
	bar.name = "FeatureBar"
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_theme_constant_override("separation", 0)
	dock.add_child(bar)

	var modes := ["characters", "weapons", "armors", "chips", "pets", "skills"]
	for i in range(modes.size()):
		var mode := str(modes[i])
		bar.add_child(_make_nav_card(_nav_title(mode), mode, _nav_icon_path(mode), _nav_accent(mode), i < modes.size() - 1))

func _make_nav_card(label: String, mode: String, icon_path: String, accent: Color, has_divider: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "%sNavCard" % mode
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 128)
	var card_rest_style := _build_nav_card_style(accent, false)
	var card_hover_style := _build_nav_card_style(accent, true)
	card.add_theme_stylebox_override("panel", card_rest_style)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(_on_nav_card_input.bind(mode, card, card_rest_style, card_hover_style))
	card.mouse_entered.connect(_set_nav_card_style.bind(card, card_hover_style))
	card.mouse_exited.connect(_set_nav_card_style.bind(card, card_rest_style))

	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, 124)
	stage.clip_contents = true
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(stage)

	var top_line := ColorRect.new()
	top_line.color = Color(accent.r, accent.g, accent.b, 0.18)
	top_line.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_line.offset_left = 26
	top_line.offset_top = 10
	top_line.offset_right = -26
	top_line.offset_bottom = 12
	top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(top_line)

	if ResourceLoader.exists(icon_path):
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.texture = load(icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 16
		icon.offset_top = 12
		icon.offset_right = -16
		icon.offset_bottom = -38
		icon.modulate = Color(1.08, 1.08, 1.08, 1.0)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(icon)

	var status_plate := PanelContainer.new()
	status_plate.name = "StatusBadge"
	status_plate.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	status_plate.offset_left = -70
	status_plate.offset_top = 14
	status_plate.offset_right = -12
	status_plate.offset_bottom = 40
	status_plate.add_theme_stylebox_override("panel", _build_nav_status_style(accent))
	status_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(status_plate)

	var status := Label.new()
	status.text = _nav_status_text(mode)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiKit.apply_label(status, 14, UiKit.TEXT_MAIN, 2)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_plate.add_child(status)

	var lbl := Label.new()
	lbl.name = "Label"
	lbl.text = label
	lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	lbl.offset_left = 0
	lbl.offset_top = -38
	lbl.offset_right = 0
	lbl.offset_bottom = -8
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiKit.apply_label(lbl, 25, UiKit.TEXT_MAIN, 4)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(lbl)

	var underline := ColorRect.new()
	underline.color = Color(accent.r, accent.g, accent.b, 0.22)
	underline.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	underline.offset_left = 42
	underline.offset_top = -6
	underline.offset_right = -42
	underline.offset_bottom = -3
	underline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(underline)

	if has_divider:
		var divider := ColorRect.new()
		divider.color = Color(0.80, 0.70, 0.52, 0.10)
		divider.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
		divider.offset_left = -1
		divider.offset_top = 18
		divider.offset_right = 0
		divider.offset_bottom = -18
		divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(divider)
	return card

func _set_nav_card_style(card: PanelContainer, style: StyleBoxFlat) -> void:
	if not is_instance_valid(card):
		return
	card.add_theme_stylebox_override("panel", style)

func _build_nav_dock_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.022, 0.030, 0.82)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.80, 0.64, 0.38, 0.34)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 8
	style.content_margin_top = 7
	style.content_margin_right = 8
	style.content_margin_bottom = 7
	return style

func _build_nav_card_style(accent: Color, highlighted: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, 0.11 if highlighted else 0.026)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(accent.r, accent.g, accent.b, 0.58 if highlighted else 0.18)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_right = 7
	style.corner_radius_bottom_left = 7
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	return style

func _build_nav_status_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.022, 0.026, 0.034, 0.86)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(accent.r, accent.g, accent.b, 0.48)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	style.content_margin_left = 6
	style.content_margin_top = 1
	style.content_margin_right = 6
	style.content_margin_bottom = 1
	return style

func _nav_title(mode: String) -> String:
	match mode:
		"characters":
			return "角色"
		"weapons":
			return "武器"
		"armors":
			return "护甲"
		"chips":
			return "芯片"
		"pets":
			return "宠物"
		"skills":
			return "技能"
		_:
			return mode

func _nav_table(mode: String) -> String:
	match mode:
		"characters":
			return "characters"
		"weapons":
			return "weapons"
		"armors":
			return "armors"
		"chips":
			return "chips"
		"pets":
			return "pets"
		_:
			return ""

func _nav_slot(mode: String) -> String:
	match mode:
		"characters":
			return "character"
		"weapons":
			return "weapon"
		"armors":
			return "armor"
		"chips":
			return "chip"
		"pets":
			return "pet"
		_:
			return ""

func _nav_default_icon(mode: String) -> String:
	match mode:
		"characters":
			return "res://assets/production/sprites/characters/char_vanguard_icon.png"
		"weapons":
			return "res://assets/production/sprites/weapons/weapon_autocannon_icon.png"
		"armors":
			return "res://assets/production/sprites/equipment/armor_faraday_icon.png"
		"chips":
			return "res://assets/production/sprites/equipment/chip_attack_icon.png"
		"pets":
			return "res://assets/production/sprites/pets/pet_turret_drone_icon.png"
		"skills":
			return "res://assets/production/sprites/ui/skill_critical_icon.png"
		_:
			return "res://assets/production/sprites/ui/icon_warning.png"

func _nav_selected_row(mode: String) -> Dictionary:
	var table := _nav_table(mode)
	var slot := _nav_slot(mode)
	if table == "" or slot == "":
		return {}
	var item_id := SaveManager.get_selected(slot)
	if item_id == "":
		return {}
	return DataLoader.get_row(table, item_id)

func _nav_icon_path(mode: String) -> String:
	var fallback := _nav_default_icon(mode)
	var row := _nav_selected_row(mode)
	if row.is_empty():
		return fallback
	return str(row.get("portrait", row.get("icon", fallback)))

func _nav_accent(mode: String) -> Color:
	var row := _nav_selected_row(mode)
	match mode:
		"characters":
			return UiKit.element_color(str(row.get("element_focus", "physical")))
		"weapons":
			return UiKit.element_color(str(row.get("element", "physical")))
		"armors":
			return Color(0.58, 0.72, 0.82)
		"chips":
			return UiKit.GREEN
		"pets":
			return UiKit.element_color(str(row.get("element", "physical")))
		"skills":
			return UiKit.PURPLE
		_:
			return UiKit.CYAN

func _nav_status_text(mode: String) -> String:
	if mode == "skills":
		return "图鉴"
	var slot := _nav_slot(mode)
	if slot == "":
		return ""
	var item_id := SaveManager.get_selected(slot)
	if item_id == "":
		return "未装"
	return "等级%d" % SaveManager.get_item_level(item_id)

func _on_nav_card_input(event: InputEvent, mode: String, card: PanelContainer, rest_style: StyleBoxFlat, hover_style: StyleBoxFlat) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		AudioManager.play_sfx("ui_click")
		router.change_scene("collection", {"mode": mode})
	elif event is InputEventScreenTouch and event.pressed:
		AudioManager.play_sfx("ui_click")
		router.change_scene("collection", {"mode": mode})

func _open_collection(mode: String) -> void:
	AudioManager.play_sfx("ui_click")
	router.change_scene("collection", {"mode": mode})

func _build_level_card(level_id: String, level: Dictionary, unlocked: bool, stars: int) -> TextureButton:
	var button := TextureButton.new()
	button.custom_minimum_size = Vector2(900, 142)
	button.texture_normal = load(BUTTON_PRIMARY if unlocked else BUTTON_SECONDARY)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.clip_contents = true
	button.disabled = not unlocked
	button.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.55, 0.55, 0.55, 0.86)
	if unlocked:
		button.pressed.connect(_open_level.bind(level_id))

	var weakness := str(level.get("primary_weakness", "physical"))
	var accent := UiKit.element_color(weakness)
	var legacy_title := Label.new()
	legacy_title.name = "LegacySmokeTitle"
	legacy_title.text = DataLoader.level_display_name(level_id)
	legacy_title.visible = false
	legacy_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(legacy_title)

	var accent_bar := ColorRect.new()
	accent_bar.position = Vector2(18, 20)
	accent_bar.size = Vector2(5, 102)
	accent_bar.color = accent
	accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(accent_bar)

	var level_num := level_id.replace("level_", "")
	var index_plate := PanelContainer.new()
	index_plate.position = Vector2(34, 28)
	index_plate.size = Vector2(92, 74)
	index_plate.add_theme_stylebox_override("panel", UiKit.panel_style(accent, Color(0.025, 0.045, 0.07, 0.86), 2, 8))
	index_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(index_plate)
	var index_label := UiKit.label(level_num, 28, Color(0.98, 1.0, 1.0, 1.0), 3)
	index_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	index_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	index_plate.add_child(index_label)

	var title := Label.new()
	title.text = DataLoader.level_display_name(level_id).replace("%s " % level_num, "")
	title.position = Vector2(146, 18)
	title.size = Vector2(360, 46)
	UiKit.apply_label(title, 32, Color(0.96, 0.99, 1.0, 1.0), 3)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(title)

	_add_card_pill(button, Vector2(146, 72), Vector2(172, 38), "战力 %d" % SaveManager.get_recommended_power_for_level(level_id), UiKit.CYAN)
	_add_card_pill(button, Vector2(328, 72), Vector2(126, 38), "已解锁" if unlocked else "未解锁", Color(0.48, 1.0, 0.64, 1.0) if unlocked else Color(0.75, 0.82, 0.9, 1.0))
	_add_element_pill(button, Vector2(464, 72), Vector2(138, 38), weakness)
	_add_variant_marker(button, str(level.get("variant", "normal")))

	var star_row := HBoxContainer.new()
	star_row.position = Vector2(662, 28)
	star_row.size = Vector2(162, 46)
	star_row.add_theme_constant_override("separation", 8)
	star_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(star_row)
	for i in range(3):
		star_row.add_child(UiKit.icon(UiKit.star_icon_path(i < stars), Vector2(42, 42)))

	var status := Label.new()
	status.text = "点击出战" if unlocked else "尚未解锁"
	status.position = Vector2(650, 82)
	status.size = Vector2(190, 30)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(status, 17, UiKit.GOLD if unlocked else UiKit.TEXT_MUTED, 2)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(status)
	return button

func _add_variant_marker(parent: Control, variant: String) -> void:
	var label := ""
	var accent := UiKit.GOLD
	match variant:
		"elite":
			label = "精英"
			accent = UiKit.DANGER
		"treasure":
			label = "宝箱"
			accent = UiKit.GOLD
		"boss":
			label = "首领"
			accent = UiKit.INFO
		"boss_rush":
			label = "首领乱斗"
			accent = UiKit.DANGER
		_:
			return
	var pill := PanelContainer.new()
	pill.position = Vector2(516, 20)
	pill.size = Vector2(128, 40)
	pill.add_theme_stylebox_override("panel", UiKit.pill_style(accent, Color(0.02, 0.012, 0.006, 0.82)))
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pill)
	var text := UiKit.label(label, 18, accent, 2)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.add_child(text)

func _add_card_pill(parent: Control, pos: Vector2, size: Vector2, text: String, accent: Color) -> void:
	var pill := PanelContainer.new()
	pill.position = pos
	pill.size = size
	pill.add_theme_stylebox_override("panel", UiKit.pill_style(accent, Color(0.015, 0.03, 0.045, 0.74)))
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pill)
	var label := UiKit.label(text, 18, Color(0.88, 0.96, 1.0, 1.0), 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.add_child(label)

func _add_element_pill(parent: Control, pos: Vector2, size: Vector2, element: String) -> void:
	var pill := PanelContainer.new()
	var accent := UiKit.element_color(element)
	pill.position = pos
	pill.size = size
	pill.add_theme_stylebox_override("panel", UiKit.pill_style(accent, Color(0.015, 0.03, 0.045, 0.74)))
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pill)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	pill.add_child(row)
	row.add_child(UiKit.icon(UiKit.element_icon_path(element), Vector2(24, 24)))
	var label := UiKit.label("弱%s" % _element_name(element), 17, Color(0.9, 0.98, 1.0, 1.0), 2)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

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
