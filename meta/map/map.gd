extends Control

const UiKit := preload("res://ui/ui_kit.gd")
const BUTTON_PRIMARY := "res://assets/production/sprites/ui/ui_button_primary.png"
const BUTTON_SECONDARY := "res://assets/production/sprites/ui/ui_button_secondary.png"
const RESOURCE_POWER_ICON := "res://assets/production/sprites/ui/icon_talent_point.png"
const RESOURCE_TIP_DURATION := 1.8

var router: Node
var resource_tip_tween: Tween = null

func setup(main: Node, _payload := {}) -> void:
	router = main

func _ready() -> void:
	AudioManager.play_bgm("map")
	_apply_map_style()
	SaveManager.repair_progression_unlocks()
	_refresh_header()
	_build_nav()
	_build_levels()
	_ensure_endless_button()

# 无限尸潮入口：复用玩家当前解锁到的最高一关作为难度种子，波次打完循环继续、每轮血量递增，
# 直到漏怪耗尽基地生命结束。奖励按撑过的轮数发放(不影响正常关卡进度/解锁)。
func _ensure_endless_button() -> void:
	if get_node_or_null("Root/VBox/EndlessButton") != null:
		return
	var vbox := $Root/VBox as VBoxContainer
	var wrap := get_node_or_null("Root/VBox/ResourceBarWrap") as Control
	var btn := TextureButton.new()
	btn.name = "EndlessButton"
	btn.texture_normal = load("res://assets/production/sprites/ui/ui_button_secondary.png")
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_SCALE
	btn.custom_minimum_size = Vector2(0, 74)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var best := SaveManager.get_endless_best_loops()
	var label := Label.new()
	label.name = "Label"
	label.text = "无限尸潮" if best <= 0 else "无限尸潮 · 最佳 %d 轮" % best
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.apply_label(label, 24, Color(1.0, 0.82, 0.5, 1.0), 3)
	btn.add_child(label)
	btn.pressed.connect(_on_endless_pressed)
	vbox.add_child(btn)
	if wrap != null:
		vbox.move_child(btn, wrap.get_index() + 1)

func _on_endless_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	router.start_endless_level(SaveManager.get_highest_unlocked_level_id())

func _apply_map_style() -> void:
	var bg := get_node_or_null("Background") as TextureRect
	if bg != null:
		bg.modulate = Color(0.42, 0.39, 0.34, 1.0)
	UiKit.apply_label(%Title, 48, UiKit.TEXT_MAIN, 5)
	(%Progress as Label).visible = false
	_ensure_resource_bar()

func _refresh_header() -> void:
	var total_stars: int = DataLoader.get_table("levels").size() * 3
	var progress := %Progress as Label
	progress.visible = false
	progress.text = "%d  %d/%d  %d" % [SaveManager.get_player_gold(), SaveManager.get_total_stars(), total_stars, SaveManager.get_loadout_power()]
	var row := _ensure_resource_bar().get_node("Row") as HBoxContainer
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	# 统一用 UiKit 共享资源条(金币/星星/经验/战力),与出战配置、收藏页一致。
	var bar := UiKit.standard_resource_bar(
		SaveManager.get_player_gold(),
		SaveManager.get_player_star(),
		SaveManager.get_player_xp(),
		SaveManager.get_loadout_power()
	)
	for chip in bar.get_children():
		bar.remove_child(chip)
		row.add_child(chip)
	bar.free()

func _ensure_resource_bar() -> VBoxContainer:
	var existing := get_node_or_null("Root/VBox/ResourceBarWrap") as VBoxContainer
	if existing != null:
		return existing

	var vbox := $Root/VBox as VBoxContainer
	var wrap := VBoxContainer.new()
	wrap.name = "ResourceBarWrap"
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.add_theme_constant_override("separation", 6)
	vbox.add_child(wrap)
	vbox.move_child(wrap, (%Progress as Label).get_index() + 1)

	var row := HBoxContainer.new()
	row.name = "Row"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	wrap.add_child(row)

	var tip := PanelContainer.new()
	tip.name = "ResourceTooltip"
	tip.visible = false
	tip.custom_minimum_size = Vector2(520, 42)
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.add_theme_stylebox_override("panel", _resource_tip_style(UiKit.GOLD))
	wrap.add_child(tip)

	var tip_label := Label.new()
	tip_label.name = "Text"
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(tip_label, 18, UiKit.TEXT_MAIN, 2)
	tip.add_child(tip_label)
	return wrap

func _make_resource_chip(title: String, icon_path: String, accent: Color, value: String, tip: String) -> Button:
	var button := Button.new()
	button.name = _resource_chip_name(title)
	button.text = ""
	button.custom_minimum_size = Vector2(168, 52)
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = "%s：%s" % [title, tip]
	button.add_theme_stylebox_override("normal", _resource_chip_style(accent, false, false))
	button.add_theme_stylebox_override("hover", _resource_chip_style(accent, true, false))
	button.add_theme_stylebox_override("pressed", _resource_chip_style(accent, true, true))
	button.add_theme_stylebox_override("disabled", _resource_chip_style(accent, false, false))
	button.pressed.connect(_show_resource_tip.bind(title, tip, accent))

	var content := HBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 14
	content.offset_top = 6
	content.offset_right = -14
	content.offset_bottom = -6
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 9)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)

	var icon := UiKit.icon(icon_path, Vector2(34, 34))
	icon.modulate = Color(1.06, 1.02, 0.92, 1.0)
	content.add_child(icon)

	var label := UiKit.label(value, 26, UiKit.TEXT_MAIN, 3)
	label.name = "Value"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(label)
	return button

func _resource_chip_name(title: String) -> String:
	match title:
		"金币":
			return "GoldResourceChip"
		"星星":
			return "StarResourceChip"
		"战力":
			return "PowerResourceChip"
		_:
			return "ResourceChip"

func _resource_chip_style(_accent: Color, _hovered: bool, _pressed: bool) -> StyleBox:
	return UiKit.resource_chip_texture_style()

func _resource_tip_style(_accent: Color) -> StyleBox:
	return UiKit.hint_texture_style(false)

func _show_resource_tip(title: String, tip: String, accent: Color) -> void:
	AudioManager.play_sfx("ui_click", -8.0)
	var panel := get_node_or_null("Root/VBox/ResourceBarWrap/ResourceTooltip") as PanelContainer
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", _resource_tip_style(accent))
	var label := panel.get_node_or_null("Text") as Label
	if label != null:
		label.text = "%s：%s" % [title, tip]
		UiKit.apply_label(label, 18, UiKit.TEXT_MAIN, 2)
	panel.visible = true
	panel.modulate = Color(1, 1, 1, 1)
	if resource_tip_tween != null and resource_tip_tween.is_valid():
		resource_tip_tween.kill()
	resource_tip_tween = panel.create_tween()
	resource_tip_tween.tween_interval(RESOURCE_TIP_DURATION)
	resource_tip_tween.tween_property(panel, "modulate:a", 0.0, 0.18)
	resource_tip_tween.tween_callback(func() -> void:
		if is_instance_valid(panel):
			panel.visible = false
			panel.modulate.a = 1.0
	)

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
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, 124)
	stage.clip_contents = true
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(stage)

	if mode == "characters":
		_add_nav_character_bust(stage)
	elif ResourceLoader.exists(icon_path):
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
		icon.modulate = Color(1.02, 1.02, 0.98, 1.0)
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

	var hit := Button.new()
	hit.name = "HitArea"
	hit.set_anchors_preset(Control.PRESET_FULL_RECT)
	hit.text = ""
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	for key in ["normal", "hover", "pressed", "disabled", "focus"]:
		hit.add_theme_stylebox_override(key, StyleBoxEmpty.new())
	hit.pressed.connect(_open_collection.bind(mode))
	hit.mouse_entered.connect(_set_nav_card_style.bind(card, card_hover_style))
	hit.mouse_exited.connect(_set_nav_card_style.bind(card, card_rest_style))
	card.add_child(hit)
	return card

func _add_nav_character_bust(stage: Control) -> void:
	var row := _nav_selected_row("characters")
	if row.is_empty():
		row = DataLoader.get_row("characters", "vanguard")
	var center := CenterContainer.new()
	center.name = "IconCenter"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 12
	center.offset_top = 4
	center.offset_right = -12
	center.offset_bottom = -36
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(center)

	var clip := TextureRect.new()
	clip.name = "Icon"
	clip.texture = null
	clip.clip_contents = true
	clip.custom_minimum_size = Vector2(112, 86)
	clip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(clip)
	UiKit.add_character_bust(clip, row, Vector2(112, 86), 128.0, -30.0, Color(1.02, 1.02, 0.98, 1.0))

func _set_nav_card_style(card: PanelContainer, style: StyleBox) -> void:
	if not is_instance_valid(card):
		return
	card.add_theme_stylebox_override("panel", style)

func _build_nav_dock_style() -> StyleBox:
	return UiKit.panel_texture_style(8.0)

func _build_nav_card_style(_accent: Color, _highlighted: bool) -> StyleBox:
	return UiKit.map_nav_card_texture_style()

func _build_nav_status_style(_accent: Color) -> StyleBox:
	return UiKit.map_pill_texture_style()

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

func _open_collection(mode: String) -> void:
	AudioManager.play_sfx("ui_click")
	router.change_scene("collection", {"mode": mode, "return_to": "map"})

func _build_level_card(level_id: String, level: Dictionary, unlocked: bool, stars: int) -> TextureButton:
	var button := TextureButton.new()
	button.custom_minimum_size = Vector2(900, 148)
	var base_texture := load("res://assets/production/sprites/ui/ui_map_level_card_skin.png")
	button.texture_normal = base_texture
	button.texture_hover = base_texture
	button.texture_pressed = base_texture
	button.texture_disabled = base_texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.clip_contents = true
	button.disabled = not unlocked
	# PASS 而非默认 STOP：让触摸拖拽能穿到 ScrollContainer 去滚动(点按仍能进关，滚动时会自动取消误触)。
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.modulate = Color(0.96, 0.96, 0.92, 1.0) if unlocked else Color(0.58, 0.60, 0.62, 0.82)
	if unlocked:
		button.pressed.connect(_open_level.bind(level_id))

	var weakness := str(level.get("primary_weakness", "physical"))
	var accent := UiKit.element_color(weakness)
	var variant := str(level.get("variant", "normal"))
	var legacy_title := Label.new()
	legacy_title.name = "LegacySmokeTitle"
	legacy_title.text = DataLoader.level_display_name(level_id)
	legacy_title.visible = false
	legacy_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(legacy_title)

	var card_frame := PanelContainer.new()
	card_frame.name = "CardFrame"
	card_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_frame.offset_left = 0
	card_frame.offset_top = 0
	card_frame.offset_right = 0
	card_frame.offset_bottom = 0
	card_frame.add_theme_stylebox_override("panel", _level_card_style(accent, unlocked, stars, variant))
	card_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(card_frame)

	var accent_bar := TextureRect.new()
	accent_bar.position = Vector2(20, 22)
	accent_bar.size = Vector2(18, 98)
	accent_bar.texture = load("res://assets/production/sprites/ui/ui_map_accent_strip.png")
	accent_bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	accent_bar.stretch_mode = TextureRect.STRETCH_SCALE
	accent_bar.modulate = Color(accent.r, accent.g, accent.b, 0.92 if unlocked else 0.42)
	accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(accent_bar)

	var level_num := level_id.replace("level_", "")
	var index_plate := PanelContainer.new()
	index_plate.position = Vector2(34, 28)
	index_plate.size = Vector2(92, 74)
	index_plate.add_theme_stylebox_override("panel", _level_index_style(accent, unlocked))
	index_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(index_plate)
	var index_label := UiKit.label(level_num, 28, UiKit.TEXT_MAIN, 3)
	index_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	index_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	index_plate.add_child(index_label)

	var title := Label.new()
	title.text = DataLoader.level_display_name(level_id).replace("%s " % level_num, "")
	title.position = Vector2(146, 18)
	title.size = Vector2(360, 46)
	UiKit.apply_label(title, 32, UiKit.TEXT_MAIN if unlocked else UiKit.TEXT_MUTED, 3)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(title)

	_add_card_pill(button, Vector2(146, 72), Vector2(172, 38), "战力 %d" % SaveManager.get_recommended_power_for_level(level_id), UiKit.CYAN)
	_add_card_pill(button, Vector2(328, 72), Vector2(126, 38), "已解锁" if unlocked else "未解锁", UiKit.SUCCESS if unlocked else UiKit.TEXT_MUTED)
	_add_element_pill(button, Vector2(464, 72), Vector2(138, 38), weakness)
	_add_variant_marker(button, variant)

	var star_row := HBoxContainer.new()
	star_row.position = Vector2(662, 28)
	star_row.size = Vector2(162, 46)
	star_row.add_theme_constant_override("separation", 8)
	star_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(star_row)
	for i in range(3):
		star_row.add_child(UiKit.icon(UiKit.star_icon_path(i < stars), Vector2(42, 42)))

	_add_deploy_status(button, unlocked)
	return button

func _level_card_style(_accent: Color, unlocked: bool, _stars: int, _variant: String) -> StyleBox:
	return UiKit.map_level_card_texture_style(not unlocked)

func _level_index_style(_accent: Color, _unlocked: bool) -> StyleBox:
	return UiKit.map_index_texture_style()

func _add_deploy_status(parent: Control, unlocked: bool) -> void:
	var status := PanelContainer.new()
	status.position = Vector2(644, 80)
	status.size = Vector2(198, 38)
	var accent := UiKit.GOLD if unlocked else UiKit.TEXT_MUTED
	var bg := Color(0.12, 0.075, 0.024, 0.86) if unlocked else Color(0.020, 0.022, 0.026, 0.70)
	status.add_theme_stylebox_override("panel", UiKit.deploy_pill_texture_style())
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(status)

	var label := UiKit.label("点击出战" if unlocked else "尚未解锁", 17, accent, 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.add_child(label)

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
	pill.add_theme_stylebox_override("panel", UiKit.map_pill_texture_style())
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
	pill.add_theme_stylebox_override("panel", UiKit.map_pill_texture_style())
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pill)
	var label := UiKit.label(text, 18, UiKit.TEXT_MAIN, 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.add_child(label)

func _add_element_pill(parent: Control, pos: Vector2, size: Vector2, element: String) -> void:
	var pill := PanelContainer.new()
	var accent := UiKit.element_color(element)
	pill.position = pos
	pill.size = size
	pill.add_theme_stylebox_override("panel", UiKit.map_pill_texture_style())
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pill)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	pill.add_child(row)
	row.add_child(UiKit.icon(UiKit.element_icon_path(element), Vector2(24, 24)))
	var label := UiKit.label("弱%s" % _element_name(element), 17, UiKit.TEXT_MAIN, 2)
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
