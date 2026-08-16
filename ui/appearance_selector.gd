extends CanvasLayer

signal global_theme_changed(theme_id: String)
signal character_outfit_changed(character_id: String, outfit_mode: String)
signal store_requested
signal closed

const UiKit := preload("res://ui/ui_kit.gd")
const FOLLOW_THEME := "follow_theme"
const DEFAULT_THEME := "default"
const PREVIEW_CHARACTER := "vanguard"
const ACTION_CURRENT := "current"
const ACTION_AVAILABLE := "available"
const ACTION_PURCHASE := "purchase"

var _router: Node
var _mode := "global"
var _character_id := ""
var _return_to_global := false
var _root: Control


func open_global(router_ref: Node = null) -> void:
	_router = router_ref
	_mode = "global"
	_character_id = ""
	_return_to_global = false
	_build()


func open_character(character_id: String, router_ref: Node = null, return_to_global := false) -> void:
	_router = router_ref
	_mode = "character"
	_character_id = character_id.trim_prefix("char_")
	_return_to_global = return_to_global
	_build()


func _build() -> void:
	layer = 112
	if is_instance_valid(_root):
		remove_child(_root)
		_root.queue_free()
	_root = Control.new()
	_root.name = "AppearanceSelectorRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.set_meta("ui_modal_surface", true)
	add_child(_root)

	var dim := TextureRect.new()
	dim.name = "Dim"
	dim.texture = load("res://assets/production/sprites/ui/ui_panel_skin.png")
	dim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dim.stretch_mode = TextureRect.STRETCH_SCALE
	dim.modulate = Color(0.0, 0.0, 0.0, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var safe := UiKit.safe_area_canvas_insets(get_viewport())
	var modal_shift := UiKit.tall_modal_shift(get_viewport().get_visible_rect().size.y, 110.0, 0.26)
	panel.offset_left = 44.0 + safe.x
	panel.offset_top = 104.0 + safe.y + modal_shift
	panel.offset_right = -44.0 - safe.z
	panel.offset_bottom = -104.0 - safe.w + modal_shift
	panel.set_meta("safe_area_content", true)
	panel.add_theme_stylebox_override("panel", UiKit.result_panel_texture_style())
	_root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "Content"
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	vbox.add_child(_header())

	var intro := UiKit.label(
		_loc(
			"全局主题控制菜单、基地、按钮和战斗氛围；角色战衣可单独覆盖。",
			"The global theme controls menus, the base, buttons, and battle ambience. Hero outfits can be overridden individually."
		) if _mode == "global" else _loc(
			"只改变这名角色的展示、战斗模型与角色专属光效，不改变任何属性。",
			"Changes only this hero's display art, battle model, and signature effects. Stats are unchanged."
		),
		19,
		UiKit.GREY_300,
		2
	)
	intro.name = "Intro"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size = Vector2(0, 74 if LocalizationManager.is_english() else 58)
	vbox.add_child(intro)

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	var content := VBoxContainer.new()
	content.name = "ScrollContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)
	if _mode == "global":
		_build_global(content)
	else:
		_build_character(content)

	var close := Button.new()
	close.name = "CloseButton"
	close.text = _loc("完  成", "Done")
	close.focus_mode = Control.FOCUS_NONE
	UiKit.apply_armored_button(close, false, Vector2(880, 96), 25, true)
	close.pressed.connect(_close)
	vbox.add_child(close)


func _header() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Header"
	row.custom_minimum_size = Vector2(0, 96)
	row.add_theme_constant_override("separation", 12)
	var title := UiKit.label(
		_loc("主题与外观", "Theme & Appearance") if _mode == "global" else _character_title(),
		39 if LocalizationManager.is_english() else 44,
		UiKit.TEXT_MAIN,
		4
	)
	title.name = "Title"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.clip_text = true
	row.add_child(title)
	var back := Button.new()
	back.name = "HeaderBackButton"
	back.focus_mode = Control.FOCUS_NONE
	back.add_theme_stylebox_override("normal", UiKit.map_pill_texture_style())
	back.add_theme_stylebox_override("hover", UiKit.map_pill_texture_style())
	back.add_theme_stylebox_override("pressed", UiKit.map_pill_texture_style())
	back.add_theme_color_override("font_color", Color.WHITE)
	back.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.82))
	back.add_theme_constant_override("outline_size", 3)
	if _return_to_global:
		back.text = _loc("角色总览", "All Heroes")
		back.custom_minimum_size = Vector2(190, 88)
		back.add_theme_font_size_override("font_size", UiKit.bumped_font_size(18))
	else:
		UiKit.apply_close_glyph(back)
	back.pressed.connect(_back_or_close)
	row.add_child(back)
	return row


func _build_global(content: VBoxContainer) -> void:
	content.add_child(_section_title(_loc("全局主题", "GLOBAL THEME"), UiKit.CYAN))
	for theme in ThemeManager.catalog_themes():
		if not PurchaseManager.is_theme_revealed(str(theme.get("id", DEFAULT_THEME))):
			continue
		content.add_child(_theme_card(theme))

	var follow_all := Button.new()
	follow_all.name = "FollowAllButton"
	follow_all.text = _loc("让所有角色跟随当前主题", "Make Every Hero Follow Global Theme")
	follow_all.focus_mode = Control.FOCUS_NONE
	UiKit.apply_armored_button(follow_all, false, Vector2(880, 88), 21, true)
	follow_all.pressed.connect(_follow_all_characters)
	content.add_child(follow_all)

	content.add_child(_section_title(_loc("逐个角色换装", "HERO OUTFITS"), UiKit.GOLD))
	var note := UiKit.label(
		_loc("默认均为“跟随主题”；单独指定后不再随全局切换。", "Default is Follow Global. An explicit outfit stops following global changes."),
		17,
		UiKit.GREY_300,
		2
	)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(0, 48)
	content.add_child(note)
	for character_id_var in _character_ids():
		content.add_child(_character_row(str(character_id_var)))


func _build_character(content: VBoxContainer) -> void:
	var row := DataLoader.get_row("characters", _character_id)
	var showcase := PanelContainer.new()
	showcase.name = "HeroShowcase"
	showcase.custom_minimum_size = Vector2(0, 314)
	showcase.add_theme_stylebox_override("panel", UiKit.collection_card_texture_style(true))
	var hero_row := HBoxContainer.new()
	hero_row.add_theme_constant_override("separation", 24)
	showcase.add_child(hero_row)
	var portrait := _portrait(_character_id, ThemeManager.effective_character_theme_id(_character_id), Vector2(260, 290), 0.70)
	portrait.name = "HeroPortrait"
	hero_row.add_child(portrait)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 14)
	hero_row.add_child(copy)
	var name := UiKit.label(DataLoader.tr_key(str(row.get("name_key", _character_id))), 31, UiKit.TEXT_MAIN, 3)
	copy.add_child(name)
	var active := ThemeManager.character_outfit_mode(_character_id)
	copy.add_child(UiKit.label(_loc("当前：", "Current: ") + _outfit_display(active), 21, UiKit.GOLD, 2))
	var safe_note := UiKit.label(
		_loc("外观与数值完全分离", "Cosmetic only · Stats unchanged"),
		17,
		UiKit.SUCCESS,
		2
	)
	copy.add_child(safe_note)
	content.add_child(showcase)

	content.add_child(_section_title(_loc("选择战衣", "CHOOSE OUTFIT"), UiKit.CYAN))
	content.add_child(_outfit_card(FOLLOW_THEME))
	for theme in ThemeManager.catalog_themes():
		if not PurchaseManager.is_theme_revealed(str(theme.get("id", DEFAULT_THEME))):
			continue
		content.add_child(_outfit_card(str(theme.get("id", DEFAULT_THEME))))


func _theme_card(theme: Dictionary) -> PanelContainer:
	var theme_id := str(theme.get("id", DEFAULT_THEME))
	var owned := ThemeManager.can_select(theme_id)
	var current := ThemeManager.is_active(theme_id)
	var panel := PanelContainer.new()
	panel.name = "Theme_" + theme_id
	panel.custom_minimum_size = Vector2(0, 248)
	panel.add_theme_stylebox_override("panel", UiKit.collection_card_texture_style(current))
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	panel.add_child(hbox)
	hbox.add_child(_portrait(PREVIEW_CHARACTER, theme_id, Vector2(176, 228)))

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 8)
	hbox.add_child(copy)
	copy.add_child(UiKit.label(ThemeManager.theme_display_name(theme_id), 27, UiKit.TEXT_MAIN, 3))
	var description := UiKit.label(_theme_description(theme_id), 17, UiKit.GREY_300, 2)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(0, 70)
	copy.add_child(description)
	copy.add_child(UiKit.label(
		_loc("当前主题", "Active") if current else (_loc("已拥有", "Owned") if owned else _loc("未拥有", "Not Owned")),
		17,
		UiKit.SUCCESS if owned else UiKit.WARNING,
		2
	))

	var action := Button.new()
	action.name = "ThemeAction_" + theme_id
	action.focus_mode = Control.FOCUS_NONE
	action.text = _loc("已应用", "ACTIVE") if current else (_loc("应  用", "Apply") if owned else _loc("购  买", "BUY"))
	_style_appearance_action(action, ACTION_CURRENT if current else (ACTION_AVAILABLE if owned else ACTION_PURCHASE))
	if owned:
		action.pressed.connect(_select_global_theme.bind(theme_id))
	else:
		action.pressed.connect(_request_store)
	hbox.add_child(action)
	return panel


func _character_row(character_id: String) -> PanelContainer:
	var row := DataLoader.get_row("characters", character_id)
	var panel := PanelContainer.new()
	panel.name = "Character_" + character_id
	panel.custom_minimum_size = Vector2(0, 164)
	panel.add_theme_stylebox_override("panel", UiKit.collection_card_texture_style(false))
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	panel.add_child(hbox)
	hbox.add_child(_portrait(character_id, ThemeManager.effective_character_theme_id(character_id), Vector2(132, 148)))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 8)
	hbox.add_child(copy)
	copy.add_child(UiKit.label(DataLoader.tr_key(str(row.get("name_key", character_id))), 24, UiKit.TEXT_MAIN, 2))
	copy.add_child(UiKit.label(_outfit_display(ThemeManager.character_outfit_mode(character_id)), 17, UiKit.CYAN, 2))
	var action := Button.new()
	action.name = "OutfitAction_" + character_id
	action.text = _loc("换  装", "Outfit")
	action.focus_mode = Control.FOCUS_NONE
	UiKit.apply_armored_button(action, false, Vector2(236, 96), 19, true)
	action.pressed.connect(_open_character_from_global.bind(character_id))
	hbox.add_child(action)
	return panel


func _outfit_card(outfit_mode: String) -> PanelContainer:
	var effective_theme := ThemeManager.active_theme_id() if outfit_mode == FOLLOW_THEME else outfit_mode
	var owned := ThemeManager.can_select_character_outfit(outfit_mode)
	var selected := ThemeManager.character_outfit_mode(_character_id) == outfit_mode
	var panel := PanelContainer.new()
	panel.name = "Outfit_" + outfit_mode
	panel.custom_minimum_size = Vector2(0, 188)
	panel.add_theme_stylebox_override("panel", UiKit.collection_card_texture_style(selected))
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	panel.add_child(hbox)
	hbox.add_child(_portrait(_character_id, effective_theme, Vector2(150, 172)))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 8)
	hbox.add_child(copy)
	copy.add_child(UiKit.label(_outfit_display(outfit_mode), 25, UiKit.TEXT_MAIN, 3))
	var detail := _loc("随全局主题自动换装", "Changes whenever the global theme changes") if outfit_mode == FOLLOW_THEME else _theme_description(outfit_mode)
	var description := UiKit.label(detail, 16, UiKit.GREY_300, 2)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(0, 52)
	copy.add_child(description)
	if not owned:
		var ownership := UiKit.label(_loc("尚未拥有", "Not Owned"), 15, UiKit.WARNING, 2)
		ownership.name = "OwnershipStatus"
		copy.add_child(ownership)
	var action := Button.new()
	action.name = "OutfitSelect_" + outfit_mode
	action.focus_mode = Control.FOCUS_NONE
	action.text = _loc("已穿戴", "WORN") if selected else (_loc("穿  戴", "Wear") if owned else _loc("购  买", "BUY"))
	_style_appearance_action(action, ACTION_CURRENT if selected else (ACTION_AVAILABLE if owned else ACTION_PURCHASE))
	if owned:
		action.pressed.connect(_select_character_outfit.bind(outfit_mode))
	else:
		action.pressed.connect(_request_store)
	hbox.add_child(action)
	return panel


func _style_appearance_action(action: Button, state: String) -> void:
	# Appearance actions carry three different meanings. Keep the accepted
	# armored geometry, but make their affordance readable before the label is
	# parsed: equipped is quiet/disabled, wearable is bright, and store-bound is
	# a restrained secondary surface with an explicit purchase label.
	action.set_meta("appearance_action_state", state)
	match state:
		ACTION_CURRENT:
			UiKit.apply_armored_button(action, false, Vector2(236, 96), 19, false)
			_tint_button_surface(action, ["disabled"], Color(0.55, 0.56, 0.57, 0.76))
			action.add_theme_color_override("font_disabled_color", Color(0.68, 0.70, 0.72, 0.96))
		ACTION_AVAILABLE:
			UiKit.apply_armored_button(action, true, Vector2(236, 96), 19, true)
			_tint_button_surface(action, ["normal", "hover", "pressed", "focus"], Color(1.0, 0.98, 0.94, 1.0))
			action.add_theme_color_override("font_color", UiKit.TEXT_MAIN)
		ACTION_PURCHASE:
			UiKit.apply_armored_button(action, false, Vector2(236, 96), 19, true)
			_tint_button_surface(action, ["normal", "hover", "pressed", "focus"], Color(0.72, 0.70, 0.66, 0.90))
			action.add_theme_color_override("font_color", Color(0.94, 0.82, 0.58, 1.0))
			action.add_theme_color_override("font_hover_color", Color(1.0, 0.91, 0.68, 1.0))
	UiKit.fit_button_text(action, UiKit.scaled_font_size(19), 16, 34.0)


func _tint_button_surface(action: Button, states: Array[String], tint: Color) -> void:
	for state_name in states:
		var style := action.get_theme_stylebox(state_name)
		if not style is StyleBoxTexture:
			continue
		var tinted := (style as StyleBoxTexture).duplicate(true) as StyleBoxTexture
		tinted.modulate_color = tinted.modulate_color * tint
		action.add_theme_stylebox_override(state_name, tinted)


func _portrait(character_id: String, theme_id: String, size: Vector2, visible_fraction := 0.62) -> TextureRect:
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = size
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fallback := _default_portrait_path(character_id)
	var path := ThemeManager.resolve_character_portrait_for_theme(character_id, theme_id, fallback)
	if path != "" and ResourceLoader.exists(path):
		var source := load(path) as Texture2D
		portrait.set_meta("portrait_source_path", path)
		portrait.texture = _portrait_bust_region(source, portrait, size, visible_fraction)
	return portrait


func _portrait_bust_region(source: Texture2D, portrait: TextureRect, viewport_size: Vector2, visible_fraction: float) -> Texture2D:
	if source == null:
		return null
	var image := source.get_image()
	if image == null or image.is_empty():
		return source
	var used := image.get_used_rect()
	if used.size == Vector2i.ZERO:
		return source
	# Appearance cards are comparison thumbnails, not full-body collection art.
	# Frame every source from head to upper thigh at one common proportion so a
	# naturally slim outfit cannot look half the size of a broad armored pose.
	# The source pixels stay untouched; only the viewport becomes a consistent,
	# high-impact hero bust with a small head/shoulder safety gutter.
	var gutter := 10
	var top := maxi(0, used.position.y - gutter)
	var clamped_fraction := clampf(visible_fraction, 0.58, 0.74)
	var bottom := mini(
		image.get_height(),
		used.position.y + int(round(float(used.size.y) * clamped_fraction)) + gutter
	)
	var region_height := maxi(1, bottom - top)
	var target_aspect := viewport_size.x / maxf(viewport_size.y, 1.0)
	var region_width := mini(image.get_width(), maxi(1, int(round(float(region_height) * target_aspect))))
	var body_center_x := float(used.position.x) + float(used.size.x) * 0.5
	var left := clampi(int(round(body_center_x - float(region_width) * 0.5)), 0, image.get_width() - region_width)
	var region := Rect2i(left, top, region_width, region_height)
	var cropped := AtlasTexture.new()
	cropped.atlas = source
	cropped.region = Rect2(region)
	portrait.set_meta("portrait_source_used_rect", Rect2(used))
	portrait.set_meta("portrait_display_region", Rect2(region))
	portrait.set_meta("portrait_framing_mode", "hero_bust")
	portrait.set_meta("portrait_visible_fraction", clamped_fraction)
	return cropped


func _default_portrait_path(character_id: String) -> String:
	var row := DataLoader.get_row("characters", character_id)
	var path := str(row.get("portrait", ""))
	var frameless := path.replace("_icon.png", "_portrait_frameless.png")
	if frameless != "" and ResourceLoader.exists(frameless):
		return frameless
	return path


func _section_title(text_value: String, color: Color) -> Label:
	var label := UiKit.label(text_value, 20, color, 2)
	label.custom_minimum_size = Vector2(0, 44)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _select_global_theme(theme_id: String) -> void:
	if not ThemeManager.select_theme(theme_id):
		return
	AudioManager.play_sfx("ui_confirm")
	global_theme_changed.emit(theme_id)


func _follow_all_characters() -> void:
	if not ThemeManager.apply_theme_to_all_characters(ThemeManager.active_theme_id()):
		return
	AudioManager.play_sfx("ui_confirm")
	for character_id in _character_ids():
		character_outfit_changed.emit(character_id, FOLLOW_THEME)
	_build()


func _select_character_outfit(outfit_mode: String) -> void:
	if not ThemeManager.select_character_outfit(_character_id, outfit_mode):
		return
	AudioManager.play_sfx("ui_confirm")
	character_outfit_changed.emit(_character_id, outfit_mode)
	_build()


func _open_character_from_global(character_id: String) -> void:
	_mode = "character"
	_character_id = character_id
	_return_to_global = true
	AudioManager.play_sfx("ui_click")
	_build()


func _back_or_close() -> void:
	if _return_to_global:
		_mode = "global"
		_character_id = ""
		_return_to_global = false
		AudioManager.play_sfx("ui_click")
		_build()
		return
	_close()


func _request_store() -> void:
	AudioManager.play_sfx("ui_confirm")
	store_requested.emit()
	_close()


func _close() -> void:
	AudioManager.play_sfx("ui_click")
	closed.emit()
	queue_free()


func _character_title() -> String:
	var row := DataLoader.get_row("characters", _character_id)
	return "%s · %s" % [
		DataLoader.tr_key(str(row.get("name_key", _character_id))),
		_loc("外观", "Outfit"),
	]


func _outfit_display(outfit_mode: String) -> String:
	if outfit_mode == FOLLOW_THEME:
		return _loc("跟随主题", "Follow Global")
	return ThemeManager.theme_display_name(outfit_mode)


func _theme_description(theme_id: String) -> String:
	return ThemeManager.theme_description(theme_id)


func _character_ids() -> Array[String]:
	var result: Array[String] = []
	var table: Dictionary = DataLoader.get_table("characters")
	for character_id in ["vanguard", "blaze", "frost", "volt"]:
		if table.has(character_id):
			result.append(character_id)
	for character_id_var in table.keys():
		var character_id := str(character_id_var)
		if not result.has(character_id):
			result.append(character_id)
	return result


func _loc(zh: String, en: String) -> String:
	return en if LocalizationManager.is_english() else zh
