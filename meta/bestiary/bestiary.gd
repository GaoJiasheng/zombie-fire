extends Control

const UiKit := preload("res://ui/ui_kit.gd")
var router: Node
var chapter := 0
var category := "zombies"
var selected_id := ""
var list_scroll := 0
var body: VBoxContainer
var scroll: ScrollContainer
var heading: Label
var back: Button
var tabs: HBoxContainer
var intro: Label

func setup(main: Node, payload := {}) -> void:
	router = main
	chapter = int(payload.get("chapter", 0))

static func text(key: String) -> String:
	return str(DataLoader.get_table("enemy_codex").get("labels", {}).get(key, {}).get("text_en" if LocalizationManager.is_english() else "text_zh", key))

func _ready() -> void:
	AudioManager.play_bgm("map")
	var bg := TextureRect.new()
	bg.texture = load("res://assets/production/sprites/backgrounds/bg_city_ruins.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.3, 0.34, 0.34)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var margin := MarginContainer.new()
	margin.name = "Root"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 44)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 20)
	margin.add_child(layout)
	heading = _label(text("title"), 48, UiKit.GOLD)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(heading)
	intro = _label(text("intro"), 26, UiKit.TEXT_MUTED)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(intro)
	tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 16)
	layout.add_child(tabs)
	for table in ["zombies", "bosses"]:
		var count := 0
		for id in DataLoader.get_table(table):
			if SaveManager.has_encountered_enemy(id):
				count += 1
		var tab := _button(text(table) + "  %d / %d" % [count, DataLoader.get_table(table).size()], 80)
		tab.name = table
		tab.pressed.connect(func():
			category = table
			selected_id = ""
			list_scroll = 0
			_show_list())
		tabs.add_child(tab)
	scroll = ScrollContainer.new()
	scroll.name = "DossierScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.scroll_deadzone = 12
	layout.add_child(scroll)
	body = VBoxContainer.new()
	body.name = "Content"
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 22)
	scroll.add_child(body)
	back = _button(text("back"), 90)
	back.pressed.connect(_go_back)
	layout.add_child(back)
	_show_list()

func _label(value: String, font_size: int, color := UiKit.TEXT_MAIN) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _button(value: String, height: float) -> Button:
	var button := Button.new()
	button.text = value
	UiKit.apply_armored_button(button, false, Vector2(400, height), 24, true)
	button.custom_minimum_size = Vector2(0, height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button

func _clear_body() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()

func _show_list() -> void:
	_clear_body()
	heading.text = text("boss_title") if category == "bosses" else text("title")
	intro.text = text("boss_intro") if category == "bosses" else text("intro")
	back.text = text("back")
	tabs.show()
	for tab in tabs.get_children():
		tab.modulate = Color.WHITE if tab.name == category else Color(0.65, 0.72, 0.76)
	var grid := GridContainer.new()
	grid.name = "Entries"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	body.add_child(grid)
	for id in DataLoader.get_table(category):
		grid.add_child(_card(id))
	_restore_scroll.call_deferred(list_scroll)

func _restore_scroll(value: int) -> void:
	await get_tree().process_frame
	if is_instance_valid(scroll):
		scroll.scroll_vertical = value

func _card(id: String) -> Button:
	var row := DataLoader.get_row(category, id)
	var known := SaveManager.has_encountered_enemy(id)
	var card := Button.new()
	card.name = id
	card.custom_minimum_size = Vector2(0, 352)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		card.add_theme_stylebox_override(state, UiKit.map_level_card_texture_style(false))
	card.disabled = not known
	var inset := MarginContainer.new()
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		inset.add_theme_constant_override("margin_" + side, 24)
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(inset)
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 10)
	inset.add_child(content)
	if known:
		var portrait := UiKit.icon(str(row.sprite), Vector2(0, 204))
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(portrait)
	else:
		# No unseen portrait, name, tooltip or counter data is exposed.
		var fog := _label("?", 104, Color(0.4, 0.51, 0.55))
		fog.custom_minimum_size.y = 204
		fog.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fog.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		content.add_child(fog)
	var title := _label(DataLoader.tr_key(str(row.name_key)) if known else text("unknown"), 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var hint := _label(text("discovered") if known else text("locked"), 23, UiKit.CYAN if known else UiKit.TEXT_MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(hint)
	card.pressed.connect(func():
		list_scroll = scroll.scroll_vertical
		_open_entry(id))
	return card

func _open_entry(id: String) -> void:
	# Guard the handler as well as the disabled tile: no hidden dossiers via code.
	if not SaveManager.has_encountered_enemy(id) or DataLoader.get_row(category, id).is_empty():
		return
	AudioManager.play_sfx("ui_click", -8)
	selected_id = id
	_clear_body()
	tabs.hide()
	back.text = text("back_list")
	var row := DataLoader.get_row(category, id)
	heading.text = DataLoader.tr_key(str(row.name_key))
	var portrait := UiKit.icon(str(row.sprite), Vector2(0, 330))
	body.add_child(portrait)
	var entry: Dictionary = DataLoader.get_table("enemy_codex").entries[id]
	var language := "en" if LocalizationManager.is_english() else "zh"
	_section(text("defenses"), defense_text(row))
	_section(text("analysis"), str(entry["guide_" + language]))
	if category == "bosses":
		var params: Dictionary = row.get("mechanic_params", {})
		var budget := text("siege_budget") % [int(params.get("base_attack_damage", 0)), float(params.get("base_attack_interval", 0))]
		_section(text("siege"), str(entry["siege_" + language]) + "\n\n" + budget)
	var facts := (text("fixed_hp") % float(row.fixed_hp)) if row.has("fixed_hp") else (text("hp_coef") % float(row.get("hp_coef", 1)))
	facts += "\n" + text("speed") % float(row.get("speed", 0))
	# Authored boss skill attacks cannot be represented by bd_coef alone.
	if category == "zombies":
		facts += "\n" + text("damage") % float(row.get("bd_coef", 0))
	_section(text("stats"), facts + "\n\n" + text("model"))
	_section(text("story"), str(entry["story_" + language]) + "\n\n" + text("story_note"))
	_restore_scroll.call_deferred(0)

static func defense_text(row: Dictionary) -> String:
	var lines: Array[String] = []
	var weakness := str(row.get("weakness", "none"))
	var economy: Dictionary = DataLoader.get_table("economy")
	lines.append(text("weakness") % [text(weakness), maxf(float(economy.get("weakness_mult", 1.5)), 1.0)] if weakness != "none" else text("no_weakness"))
	var resist := str(row.get("resist", "none"))
	if resist != "none":
		lines.append(text("resist") % [text(resist), clampf(float(economy.get("resist_mult", 0.5)), 0.05, 1.0)])
	for element in row.get("resistances", {}):
		lines.append(text("reduction") % [text(element), clampf(float(row.resistances[element]), 0, 0.95) * 100])
	if resist == "none" and row.get("resistances", {}).is_empty():
		lines.append(text("no_resist"))
	var armor := clampf(float(row.get("armor_hp_ratio", 0)), 0, 0.75)
	var shield := str(row.get("mechanic", "")) in ["armor", "shield_aura", "ward"]
	if armor > 0:
		lines.append(text("armor") % (armor * 100))
	if shield:
		lines.append(text("shield") % (float(row.get("mechanic_params", {}).get("shield_ratio", 0.35)) * 100))
	if armor <= 0 and not shield:
		lines.append(text("no_armor"))
	if bool(row.get("mechanic_params", {}).get("resistance_until_armor_break", false)):
		lines.append(text("armor_break"))
	return "\n\n".join(lines)

func _section(title: String, value: String) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.map_level_card_texture_style(false))
	body.add_child(panel)
	var inset := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		inset.add_theme_constant_override("margin_" + side, 28)
	panel.add_child(inset)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	inset.add_child(box)
	box.add_child(_label(title, 32, UiKit.GOLD))
	box.add_child(_label(value, 28))

func _go_back() -> void:
	if selected_id != "":
		selected_id = ""
		_show_list()
	else:
		router.change_scene("map", {"chapter": chapter})

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_go_back()
