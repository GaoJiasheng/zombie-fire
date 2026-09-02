extends Control

const UiKit := preload("res://ui/ui_kit.gd")
const BUTTON_PRIMARY := "res://assets/production/sprites/ui/ui_button_primary.png"
const BUTTON_SECONDARY := "res://assets/production/sprites/ui/ui_button_secondary.png"
const ACTION_ACTIVE_MODULATE := Color(1.0, 0.86, 0.54, 1.0)
const ACTION_SECONDARY_MODULATE := Color(0.86, 0.90, 0.92, 1.0)
const ACTION_DISABLED_MODULATE := Color(0.48, 0.52, 0.58, 0.86)
const LOCKED_CARD_VEIL_TEXTURE := "res://assets/production/sprites/ui/ui_panel_skin.png"
const CharacterSkillText := preload("res://core/data/character_skill_text.gd")
const SkillEffectText := preload("res://core/data/skill_effect_text.gd")
const AppearanceSelector := preload("res://ui/appearance_selector.gd")
const COLLECTION_CARD_WIDTH := 860.0
# Non-character catalogs own the full collection safe width after reserving the
# ScrollContainer's 8px vertical bar. Keeping characters on their separate
# ruler avoids changing the accepted knee-crop
# presentation while weapons / armor / chips / pets / skills share one denser
# showcase layout.
const CATALOG_LIST_CARD_WIDTH := 896.0
const COLLECTION_SCROLLBAR_RESERVE := 8.0
const COLLECTION_MIN_SAFE_GUTTER := 24.0
const CATALOG_LIST_CARD_HEIGHT := 256.0
const CATALOG_LIST_ICON_POSITION := Vector2(32.0, 26.0)
const CATALOG_LIST_ICON_SIZE := Vector2(204.0, 204.0)
const CATALOG_LIST_SKILL_ART_POSITION := Vector2(10.0, 10.0)
const CATALOG_LIST_SKILL_ART_SIZE := Vector2(184.0, 184.0)
const CATALOG_LIST_TEXT_X := 272.0
const CATALOG_LIST_ACTION_X := 686.0
const CATALOG_LIST_TEXT_WIDTH := 382.0
const CATALOG_LIST_TITLE_WIDTH := 588.0
const CATALOG_LIST_SKILL_INFO_X := 782.0
const CATALOG_LIST_SKILL_LEVEL_X := 652.0
const SKILL_CARD_TEXT_WIDTH := 498.0
const CHARACTER_LIST_PORTRAIT_POSITION := Vector2(24.0, 10.0)
const CHARACTER_LIST_PORTRAIT_SIZE := Vector2(320.0, 310.0)
const CHARACTER_LIST_SUBJECT_HEIGHT := 465.0
const CHARACTER_LIST_HEAD_BASELINE := 6.0
const CHARACTER_LIST_TEXT_X := 370.0
const CHARACTER_LIST_TEXT_WIDTH := 260.0
const CHARACTER_LIST_ACTION_X := 650.0
const COLLECTION_LIST_TITLE_Y := 24.0
const COLLECTION_LIST_TITLE_HEIGHT := 60.0
const COLLECTION_LIST_TITLE_TAG_GAP := 8.0
const COLLECTION_LIST_TAG_Y := COLLECTION_LIST_TITLE_Y + COLLECTION_LIST_TITLE_HEIGHT + COLLECTION_LIST_TITLE_TAG_GAP
# Semantic tag pills resolve to a 45px mobile minimum at the 1.5x font scale.
# Author the row at its real minimum so the following 6px interval is exact.
const COLLECTION_LIST_TAG_HEIGHT := 45.0
const COLLECTION_LIST_TAG_DESCRIPTION_GAP := 6.0
const COLLECTION_LIST_DESCRIPTION_Y := COLLECTION_LIST_TAG_Y + COLLECTION_LIST_TAG_HEIGHT + COLLECTION_LIST_TAG_DESCRIPTION_GAP
const EQUIPMENT_LIST_ACTION_Y := 162.0
const CHARACTER_DETAIL_BUST_Y := -12.0
const ARMORED_BUTTON_LABEL_OPTICAL_Y := -4.0
const SKILL_DETAIL_NAME_FONT_SIZE_ZH := 42
const SKILL_DETAIL_NAME_FONT_SIZE_EN := 32
const SKILL_DETAIL_SUMMARY_FONT_SIZE := 23
const SKILL_DETAIL_SECTION_TITLE_FONT_SIZE := 26
const SKILL_DETAIL_DESCRIPTION_FONT_SIZE := 22
const SKILL_DETAIL_LEVEL_FONT_SIZE := 22
const SKILL_DETAIL_EFFECT_FONT_SIZE := 21
const SKILL_DETAIL_STAT_FONT_DELTA := 2
const CHARACTER_DETAIL_NAME_FONT_SIZE := 48
const CHARACTER_DETAIL_LEVEL_FONT_SIZE := 26
const CHARACTER_DETAIL_SECTION_TITLE_FONT_SIZE := 27
const CHARACTER_DETAIL_SECOND_PASS_DELTA := 2
const CHARACTER_DETAIL_AFFINITY_FONT_SIZE := 25
const CHARACTER_DETAIL_PILL_FONT_SIZE := 20
const CHARACTER_DETAIL_STAT_LABEL_FONT_SIZE := 20
const CHARACTER_DETAIL_STAT_VALUE_FONT_SIZE := 28
const CHARACTER_DETAIL_STAT_SUB_FONT_SIZE := 18
const CHARACTER_DETAIL_SKILL_TITLE_FONT_SIZE := 28
const CHARACTER_DETAIL_SKILL_KIND_FONT_SIZE := 22
const CHARACTER_DETAIL_SKILL_DESC_FONT_SIZE := 24
const CHARACTER_DETAIL_SKILL_LEADING_INSET := 12.0
const CHARACTER_DETAIL_SKILL_ICON_FRAME_SIZE := Vector2(148.0, 148.0)
const CHARACTER_DETAIL_SKILL_ICON_SIZE := Vector2(128.0, 128.0)
const CHARACTER_DETAIL_SIG_LEVEL_FONT_SIZE := 24
const CHARACTER_DETAIL_SIG_GROWTH_FONT_SIZE := 21
const DETAIL_CLOSE_BUTTON_SIZE := Vector2(104.0, 104.0)
const DETAIL_CLOSE_GLYPH_FONT_SIZE := 68
const DETAIL_SCROLL_BOTTOM_CLEARANCE := 44.0
const DETAIL_SCROLL_DEADZONE := 12

var router: Node
var mode := "characters"
var _return_to := "map"
var _return_level_id := ""
var _return_challenge_mode := false
var _loadout_return_to := "map"
var _loadout_return_payload := {}
var _detail_modal: Control = null
var _appearance_selector: CanvasLayer = null
var _refresh_generation := 0

func _loc(zh: String, en: String) -> String:
	return en if LocalizationManager.is_english() else zh

func _is_premium_item(row: Dictionary) -> bool:
	return str(row.get("premium_entitlement", "")).strip_edges() != ""

func setup(main: Node, payload := {}) -> void:
	router = main
	var data := {}
	if payload is Dictionary:
		data = payload
	mode = str(data.get("mode", "characters"))
	_return_to = str(data.get("return_to", "map"))
	_return_level_id = str(data.get("level_id", data.get("return_level_id", "")))
	_return_challenge_mode = bool(data.get("challenge", false))
	_loadout_return_to = _sanitize_loadout_return_to(str(data.get("loadout_return_to", "map")))
	_loadout_return_payload = _sanitize_payload(data.get("loadout_return_payload", {}))
	if _return_to == "loadout" and _return_level_id == "" and router != null:
		var context: Variant = router.get("run_context")
		if context is Dictionary:
			_return_level_id = str(context.get("level_id", ""))
			_return_challenge_mode = bool(context.get("challenge", _return_challenge_mode))
	if _return_to != "loadout":
		_return_to = "map"
	_refresh()

func _ready() -> void:
	AudioManager.play_bgm("map")
	(%BackButton as TextureButton).pressed.connect(_on_back_pressed)
	_apply_safe_horizontal_margins()
	_apply_safe_horizontal_margins.call_deferred()
	_refresh_back_button()
	_refresh()

func _apply_safe_horizontal_margins() -> void:
	if not is_inside_tree():
		return
	var root := get_node_or_null("Root") as MarginContainer
	if root == null:
		return
	# The app shell applies device safe-area offsets to this full-rect container.
	# Derive the inner gutter from the resulting width so both ordinary and tall
	# phones keep the complete card inside the safe area.
	var safe := UiKit.safe_area_canvas_insets(get_viewport())
	# setup/_ready run before Main applies the safe offsets to Root. Derive the
	# target width from the viewport and insets directly so the first full-width
	# layout cannot cache an oversized gutter.
	var available_width := get_viewport_rect().size.x - safe.x - safe.z
	var card_width := COLLECTION_CARD_WIDTH if mode == "characters" else CATALOG_LIST_CARD_WIDTH
	var gutter := maxf(COLLECTION_MIN_SAFE_GUTTER, floor((available_width - card_width - COLLECTION_SCROLLBAR_RESERVE) * 0.5))
	root.add_theme_constant_override("margin_left", int(gutter))
	root.add_theme_constant_override("margin_right", int(gutter))

func _on_back_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	if router == null:
		return
	if _return_to == "loadout":
		var payload := {}
		if _return_level_id != "":
			payload["level_id"] = _return_level_id
		if _return_challenge_mode:
			payload["challenge"] = true
		payload["return_to"] = _loadout_return_to
		if not _loadout_return_payload.is_empty():
			payload["return_payload"] = _loadout_return_payload.duplicate(true)
		router.change_scene("loadout", payload)
		return
	router.change_scene("map")

func _refresh_back_button() -> void:
	var button := %BackButton as TextureButton
	UiKit.apply_armored_texture_button(button, false, Vector2(560, 104), true)
	var label := button.get_node_or_null("Label") as Label
	if label == null:
		return
	label.text = "返回配置" if _return_to == "loadout" else "返回地图"
	_apply_armored_button_label_alignment(label)

func _sanitize_loadout_return_to(route: String) -> String:
	match route:
		"result":
			return "result"
		_:
			return "map"

func _sanitize_payload(payload: Variant) -> Dictionary:
	if payload is Dictionary:
		return payload.duplicate(true)
	return {}

func _refresh() -> void:
	if not is_inside_tree():
		return
	var item_scroll := %ItemScroll as ScrollContainer
	var preserved_scroll := item_scroll.scroll_vertical
	_refresh_generation += 1
	var generation := _refresh_generation
	(%Title as Label).text = _title()
	_refresh_resource_bar()
	var item_list := %ItemList as VBoxContainer
	item_list.add_theme_constant_override("separation", 18 if _uses_spacious_collection_cards() else 14)
	for child in item_list.get_children():
		# Remove rows from the namespace immediately before queuing their memory
		# release. Otherwise the replacement rows receive generated @Node names,
		# breaking item-ID lookup during purchase, pulse and scroll restoration.
		item_list.remove_child(child)
		child.queue_free()
	var table_data: Dictionary = _table()
	for item_id: String in table_data.keys():
		var row: Dictionary = table_data[item_id]
		var premium_entitlement := str(row.get("premium_entitlement", "")).strip_edges()
		if premium_entitlement != "" and not PurchaseManager.is_entitlement_revealed(premium_entitlement):
			continue
		item_list.add_child(_build_item_button(item_id, row))
	var scroll_end_padding := Control.new()
	scroll_end_padding.name = "ScrollEndPadding"
	scroll_end_padding.custom_minimum_size = Vector2(0, 44)
	scroll_end_padding.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_list.add_child(scroll_end_padding)
	call_deferred("_restore_item_scroll", preserved_scroll, generation)

func _restore_item_scroll(scroll_position: int, generation: int) -> void:
	# Refresh replaces every row. Wait for both the queued old rows to leave and
	# the new VBox minimum size to settle before restoring the player's context.
	await get_tree().process_frame
	await get_tree().process_frame
	if generation != _refresh_generation or not is_inside_tree():
		return
	(%ItemScroll as ScrollContainer).scroll_vertical = maxi(0, scroll_position)

func _refresh_resource_bar() -> void:
	var prog := %Progress as Label
	prog.visible = false
	var parent := prog.get_parent()
	var existing := parent.get_node_or_null("ResourceBar")
	if existing != null:
		existing.free()
	var bar := UiKit.standard_resource_bar(SaveManager.get_player_gold(), SaveManager.get_player_star(), SaveManager.get_player_xp(), Vector2(174, 58), 25)
	bar.name = "ResourceBar"
	bar.custom_minimum_size = Vector2(0, 66)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.add_theme_constant_override("separation", 12)
	parent.add_child(bar)
	parent.move_child(bar, prog.get_index() + 1)

func _uses_spacious_collection_cards() -> bool:
	return mode in ["weapons", "armors", "chips", "pets"]

func _title() -> String:
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
			return "技能图鉴"
		_:
			return mode

func _table() -> Dictionary:
	match mode:
		"characters":
			return DataLoader.get_table("characters")
		"weapons":
			return DataLoader.get_table("weapons")
		"armors":
			return DataLoader.get_table("armors")
		"chips":
			return DataLoader.get_table("chips")
		"pets":
			return DataLoader.get_table("pets")
		"skills":
			return DataLoader.get_table("skills")
		_:
			return {}

func _slot() -> String:
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

func _build_item_button(item_id: String, row: Dictionary) -> TextureButton:
	if mode == "skills":
		return _build_skill_item_button(item_id, row)

	var slot := _slot()
	var unlocked := true if mode == "skills" else SaveManager.is_item_unlocked(slot, item_id)
	var selected := slot != "" and SaveManager.get_selected(slot) == item_id
	var item_level := SaveManager.get_item_level(item_id)
	var spacious := _uses_spacious_collection_cards()
	var english_layout := LocalizationManager.is_english()
	var card_width := COLLECTION_CARD_WIDTH if mode == "characters" else CATALOG_LIST_CARD_WIDTH
	# Character cards use the same generous presentation height in both
	# languages. This lets the portrait consume the full card instead of keeping
	# the former tiny-avatar geometry inside an already tall English row.
	# Equipment cards now also share one bilingual geometry. Previously English
	# reserved a mostly-empty two-line title block while Chinese compressed its
	# tags against the title, so changing language visibly reflowed the catalog.
	var card_height := 330.0 if mode == "characters" else CATALOG_LIST_CARD_HEIGHT
	var button := TextureButton.new()
	button.name = item_id
	button.custom_minimum_size = Vector2(card_width, card_height)
	# Every equipment family now uses the same wide-card ruler. This keeps pets,
	# armor and chips from looking like compact text rows beside weapon showcases.
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.texture_normal = null
	button.texture_hover = null
	button.texture_pressed = null
	button.texture_disabled = null
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.clip_contents = true
	button.modulate = Color.WHITE
	button.disabled = false
	# PASS 而非默认 STOP：让触摸拖拽能穿到 ItemScroll 去滚动(点按仍能开详情，滚动时
	# 自动取消误触)，同类问题 map.gd 的关卡卡片已用这个写法修过(见其注释)。
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	# 点卡片永远只看详情，绝不直接购买（购买走卡片上的“购买”按钮或详情页里的购买按钮）。
	button.pressed.connect(_show_item_detail.bind(item_id, row))

	var accent := _mode_accent(row)
	var frame := PanelContainer.new()
	frame.name = "Frame"
	frame.position = Vector2(16, 14)
	frame.size = Vector2(card_width - 32.0, card_height - 28.0)
	frame.add_theme_stylebox_override("panel", UiKit.collection_card_texture_style(false))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.visible = true
	button.add_child(frame)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.position = CHARACTER_LIST_PORTRAIT_POSITION if mode == "characters" else CATALOG_LIST_ICON_POSITION
	icon.size = CHARACTER_LIST_PORTRAIT_SIZE if mode == "characters" else CATALOG_LIST_ICON_SIZE
	icon.custom_minimum_size = icon.size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.modulate = Color.WHITE if unlocked else Color(0.46, 0.5, 0.54, 0.72)
	if mode == "characters":
		icon.texture = null
		icon.clip_contents = true
		UiKit.add_character_knee_crop_aligned(
			icon,
			row,
			CHARACTER_LIST_PORTRAIT_SIZE,
			CHARACTER_LIST_SUBJECT_HEIGHT,
			CHARACTER_LIST_HEAD_BASELINE
		)
	else:
		icon.texture = load(UiKit.item_icon_path(_data_table_name(), item_id, row))
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if mode == "weapons":
			UiKit.apply_theme_surface(icon)
	button.add_child(icon)
	icon.z_index = 2
	icon.set_deferred("position", icon.position)
	icon.set_deferred("size", icon.size)

	var title := Label.new()
	title.name = "Title"
	title.text = "%s  等级%d%s" % [DataLoader.tr_key(row.get("name_key", item_id)), item_level, _tier_suffix(item_level)]
	var text_x := CHARACTER_LIST_TEXT_X if mode == "characters" else CATALOG_LIST_TEXT_X
	title.position = Vector2(text_x, COLLECTION_LIST_TITLE_Y)
	# The title occupies the otherwise-empty upper-right of the card.  Keep the
	# full width available so long weapon names plus level/tier remain readable
	# after the global mobile font increase instead of clipping or shrinking.
	title.size = Vector2(450 if mode == "characters" else CATALOG_LIST_TITLE_WIDTH, COLLECTION_LIST_TITLE_HEIGHT)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	# Bottom-align the glyphs inside the fixed title lane.  This makes the visible
	# title-to-tag interval equal to the authored 8px rhythm instead of leaving a
	# language/font-metric-dependent pocket of empty space below the name.
	title.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	var title_font_size := 23 if english_layout and mode != "characters" else (24 if english_layout else (27 if spacious else 28))
	UiKit.apply_label(title, title_font_size, _level_tint(item_level) if unlocked else Color(0.7, 0.75, 0.82, 1.0), 3)
	# Keep every catalog title on the same one-line baseline. Only genuinely long
	# localized names shrink to fit; ordinary Chinese and English names retain the
	# full mobile-readable size and the exact same interval before metadata tags.
	UiKit.fit_label_text(title, UiKit.scaled_font_size(title_font_size), UiKit.scaled_font_size(18), 2.0, 2.0)
	title.clip_text = true
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(title)
	title.z_index = 2

	var tag_row := HBoxContainer.new()
	tag_row.name = "Tags"
	tag_row.position = Vector2(text_x, COLLECTION_LIST_TAG_Y)
	# Three bilingual metadata chips (unlock/role/element) need a wider lane than
	# prose. They live above the action button, so using the full card width here
	# does not steal any description space.
	tag_row.size = Vector2(452 if mode == "characters" else CATALOG_LIST_TITLE_WIDTH, COLLECTION_LIST_TAG_HEIGHT)
	tag_row.add_theme_constant_override("separation", 10 if spacious else 8)
	tag_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(tag_row)
	tag_row.z_index = 2
	var tag_index := 0
	for tag_spec in _item_tag_specs(row, unlocked).slice(0, 3):
		var tag := UiKit.semantic_tag_pill(
			LocalizationManager.text(str(tag_spec.get("text", ""))),
			str(tag_spec.get("role", "ability")),
			13 if english_layout else 15
		)
		tag.name = "MetadataTag%d" % tag_index
		tag_row.add_child(tag)
		tag_index += 1

	var desc := Label.new()
	desc.name = "Description"
	desc.text = _item_desc(item_id, row, unlocked)
	desc.position = Vector2(text_x, COLLECTION_LIST_DESCRIPTION_Y)
	# The mobile font pass makes a two-line description about 80px tall. Keep a
	# little metric headroom so the second line never disappears on iOS fonts.
	desc.size = Vector2(CHARACTER_LIST_TEXT_WIDTH if mode == "characters" else CATALOG_LIST_TEXT_WIDTH, 120 if mode == "characters" else 104)
	var desc_font_size := 16 if LocalizationManager.is_english() else (17 if spacious else 18)
	UiKit.apply_label(desc, desc_font_size, Color(0.72, 0.9, 1.0) if unlocked else Color(0.78, 0.78, 0.78), 2)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc.clip_text = true
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(desc)
	desc.z_index = 2

	if mode != "skills":
		var buy_price := 0
		var can_buy := false
		var action_cost_spec := {}
		var premium_locked := not unlocked and _is_premium_item(row)
		if not unlocked:
			if premium_locked:
				can_buy = true
			else:
				action_cost_spec = SaveManager.get_unlock_cost_spec(_data_table_name(), item_id)
				buy_price = int(action_cost_spec.get("amount", 0))
				can_buy = SaveManager.get_player_star() >= buy_price
			_add_locked_card_veil(button, card_width, card_height, can_buy)

		var action_text := "已装备" if selected else ("选  定" if mode == "characters" else "装  备")
		var action_enabled := unlocked and not selected
		var action_primary := true
		var action_callback: Callable = _select_item.bind(slot, item_id)
		if not unlocked:
			action_primary = true
			if premium_locked:
				action_text = _loc("军械库", "Arsenal")
				action_enabled = true
				action_callback = _open_premium_store
			else:
				action_enabled = false
				action_callback = Callable()
				action_text = _loc("购买", "Buy") if can_buy else _loc("不足", "Need")
				action_enabled = can_buy
				action_callback = _purchase_item_flow.bind(item_id, row)
		var action_size := Vector2(176, 76) if spacious else Vector2(174, 72)
		var action_pos := Vector2(CHARACTER_LIST_ACTION_X if mode == "characters" else CATALOG_LIST_ACTION_X, 238.0 if mode == "characters" else EQUIPMENT_LIST_ACTION_Y)
		var action_btn := _card_action_button("CardActionButton", action_text, action_enabled, action_primary, action_pos, action_size)
		if not action_cost_spec.is_empty():
			UiKit.apply_resource_cost(
				action_btn,
				action_text,
				str(action_cost_spec.get("kind", "star")),
				buy_price,
				15,
				22.0
			)
		action_btn.z_index = 3
		if action_enabled and action_callback.is_valid():
			action_btn.pressed.connect(action_callback)
		button.add_child(action_btn)
	return button

func _add_locked_card_veil(parent: Control, card_width: float, card_height: float, can_buy: bool) -> void:
	var veil := TextureRect.new()
	veil.name = "LockedCardVeil"
	veil.texture = load(LOCKED_CARD_VEIL_TEXTURE)
	veil.position = Vector2(18, 16)
	veil.size = Vector2(card_width - 36.0, card_height - 32.0)
	veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	veil.stretch_mode = TextureRect.STRETCH_SCALE
	veil.modulate = Color(0.0, 0.0, 0.0, 0.24 if can_buy else 0.32)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.z_index = 1
	parent.add_child(veil)

func _card_action_button(node_name: String, text: String, enabled: bool, primary: bool, pos: Vector2, button_size: Vector2) -> TextureButton:
	var button := _armored_action_button(node_name, text, enabled, primary, button_size, 18)
	button.position = pos
	button.size = button_size
	button.custom_minimum_size = button_size
	UiKit.attach_touch_target(button)
	return button

func _build_skill_item_button(item_id: String, row: Dictionary) -> TextureButton:
	var accent := _mode_accent(row)
	var item_level := SaveManager.get_skill_base_level(item_id)
	var button := TextureButton.new()
	button.name = item_id
	button.custom_minimum_size = Vector2(CATALOG_LIST_CARD_WIDTH, CATALOG_LIST_CARD_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.texture_normal = null
	button.texture_hover = null
	button.texture_pressed = null
	button.texture_disabled = null
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.clip_contents = true
	# PASS 而非 STOP：让触摸拖拽能穿到 ItemScroll 去滚动(点按仍能开详情，滚动时
	# 自动取消误触)，同类问题 map.gd 的关卡卡片已用这个写法修过(见其注释)。
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.pressed.connect(_show_item_detail.bind(item_id, row))

	var card := PanelContainer.new()
	card.name = "SkillCard"
	card.position = Vector2(10, 6)
	card.size = Vector2(CATALOG_LIST_CARD_WIDTH - 20.0, CATALOG_LIST_CARD_HEIGHT - 12.0)
	card.add_theme_stylebox_override("panel", _build_skill_card_style(accent))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.visible = true
	button.add_child(card)

	var accent_bar := TextureRect.new()
	accent_bar.name = "AccentBar"
	accent_bar.position = Vector2(10, 6)
	accent_bar.size = Vector2(18, CATALOG_LIST_CARD_HEIGHT - 26.0)
	accent_bar.texture = load("res://assets/production/sprites/ui/ui_map_accent_strip.png")
	accent_bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	accent_bar.stretch_mode = TextureRect.STRETCH_SCALE
	accent_bar.modulate = Color(accent.r, accent.g, accent.b, 0.92)
	accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(accent_bar)

	var icon_frame := PanelContainer.new()
	icon_frame.name = "IconFrame"
	icon_frame.position = CATALOG_LIST_ICON_POSITION
	icon_frame.size = CATALOG_LIST_ICON_SIZE
	icon_frame.clip_contents = true
	icon_frame.add_theme_stylebox_override("panel", _build_skill_icon_frame_style(accent))
	icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon_frame)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = load(str(row.get("icon", "")))
	icon.position = CATALOG_LIST_SKILL_ART_POSITION
	icon.size = CATALOG_LIST_SKILL_ART_SIZE
	icon.custom_minimum_size = CATALOG_LIST_SKILL_ART_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_frame.add_child(icon)
	icon.set_deferred("position", CATALOG_LIST_SKILL_ART_POSITION)
	icon.set_deferred("size", CATALOG_LIST_SKILL_ART_SIZE)

	var title := Label.new()
	title.name = "Title"
	var english_layout := LocalizationManager.is_english()
	title.text = DataLoader.tr_key(row.get("name_key", item_id)) if english_layout else "%s  等级%d" % [DataLoader.tr_key(row.get("name_key", item_id)), item_level]
	title.position = Vector2(CATALOG_LIST_TEXT_X, 18)
	title.size = Vector2(CATALOG_LIST_SKILL_LEVEL_X - CATALOG_LIST_TEXT_X - 8.0 if english_layout else SKILL_CARD_TEXT_WIDTH, 40)
	title.clip_text = true
	UiKit.apply_label(title, 26 if english_layout else 28, UiKit.TEXT_MAIN, 3)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(title)

	# English names are much wider than their Chinese counterparts. Keep the
	# skill name and level in independent authored columns so every Lv. badge
	# shares one baseline and long names never shove it sideways.
	if english_layout:
		var level := Label.new()
		level.name = "Level"
		level.text = "等级%d" % item_level
		level.position = Vector2(CATALOG_LIST_SKILL_LEVEL_X, 18)
		level.size = Vector2(112, 40)
		level.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		level.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		level.clip_text = true
		UiKit.apply_label(level, 22, UiKit.TEXT_MAIN, 3)
		level.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(level)

	var tag_row := HBoxContainer.new()
	tag_row.name = "Tags"
	tag_row.position = Vector2(CATALOG_LIST_TEXT_X, 76)
	tag_row.size = Vector2(SKILL_CARD_TEXT_WIDTH, 40)
	tag_row.add_theme_constant_override("separation", 10)
	tag_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(tag_row)
	var tag_font_size := 13 if english_layout else 15
	var kind_tag := UiKit.skill_tag_pill(_skill_kind_short_name(str(row.get("kind", "passive"))) if english_layout else _kind_name(str(row.get("kind", "passive"))), true, tag_font_size)
	kind_tag.name = "KindTag"
	tag_row.add_child(kind_tag)
	var tag_limit := 2 if english_layout else 3
	var tag_index := 0
	for tag_text in _item_tags(row, true).slice(0, tag_limit):
		var semantic_tag := UiKit.skill_tag_pill(str(tag_text), false, tag_font_size)
		semantic_tag.name = "AbilityTag%d" % tag_index
		tag_row.add_child(semantic_tag)
		tag_index += 1

	var effect := Label.new()
	effect.name = "EffectSummary"
	effect.text = _skill_effect_summary(row, item_level)
	# The semantic tag style owns real mobile padding, so leave an authored gap
	# below its measured height instead of relying on the former hairline badge.
	effect.position = Vector2(CATALOG_LIST_TEXT_X, 130)
	# Own the full remaining copy lane. Some high-level summaries (notably the
	# critical-charge skill) wrap after the final percentage; the former fixed
	# 80px height clipped that line and could visually collide with later UI.
	effect.size = Vector2(SKILL_CARD_TEXT_WIDTH, CATALOG_LIST_CARD_HEIGHT - effect.position.y - 20.0)
	effect.clip_text = true
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(effect, 17, Color(0.68, 0.86, 0.88, 1.0), 2)
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(effect)

	var info_button := Button.new()
	info_button.name = "InfoButton"
	info_button.text = "i"
	info_button.position = Vector2(CATALOG_LIST_SKILL_INFO_X, 34)
	info_button.size = Vector2(88, 88)
	info_button.custom_minimum_size = Vector2(88, 88)
	info_button.focus_mode = Control.FOCUS_NONE
	info_button.mouse_filter = Control.MOUSE_FILTER_STOP
	info_button.tooltip_text = "查看技能详情与等级效果"
	info_button.add_theme_font_size_override("font_size", UiKit.bumped_font_size(34))
	info_button.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 1.0))
	info_button.add_theme_color_override("font_hover_color", Color.WHITE)
	info_button.add_theme_color_override("font_pressed_color", UiKit.GOLD)
	for state in ["normal", "hover", "pressed", "focus"]:
		info_button.add_theme_stylebox_override(state, UiKit.map_pill_texture_style())
	info_button.set_meta("critical_touch", true)
	info_button.pressed.connect(_show_item_detail.bind(item_id, row))
	button.add_child(info_button)
	return button

func _mode_accent(row: Dictionary) -> Color:
	match mode:
		"characters":
			return UiKit.element_color(str(row.get("element_focus", "physical")))
		"weapons":
			return UiKit.element_color(str(row.get("element", "physical")))
		"armors":
			return Color(0.48, 0.84, 1.0, 1.0)
		"chips":
			return Color(0.48, 1.0, 0.58, 1.0)
		"pets":
			return UiKit.element_color(str(row.get("element", "physical")))
		"skills":
			return UiKit.element_color(str(row.get("element", row.get("ammo_element", "physical"))))
		_:
			return UiKit.CYAN

func _item_tag_specs(row: Dictionary, unlocked: bool) -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	if not unlocked:
		specs.append({"text": "星级解锁", "role": "access"})
	match mode:
		"characters":
			specs.append({"text": _role_name(row.get("role_tag", "-")), "role": "kind"})
			specs.append({"text": _element_name(row.get("element_focus", "-")), "role": "element"})
		"weapons":
			specs.append({"text": _element_name(row.get("element", "-")), "role": "element"})
			var weapon_special := _weapon_special_text(row)
			if weapon_special != "":
				specs.append({"text": weapon_special, "role": "ability"})
		"armors":
			specs.append({"text": "护甲", "role": "kind"})
			specs.append({"text": _element_name(row.get("resist", "none")), "role": "element"})
		"chips":
			specs.append({"text": "芯片", "role": "kind"})
			specs.append({"text": _stat_name(row.get("stat", "stat")), "role": "ability"})
		"pets":
			specs.append({"text": _role_name(row.get("role", "-")), "role": "kind"})
			# Medic/collector support pets deliberately have no elemental affinity.
			# A bordered "-"/"None" chip reads like missing content, so only expose
			# the element when the data actually declares one.
			var pet_element := str(row.get("element", "")).strip_edges()
			if pet_element not in ["", "-", "none", "null", "<null>"]:
				specs.append({"text": _element_name(pet_element), "role": "element"})
		"skills":
			for tag in row.get("card_tags", []):
				specs.append({"text": _tag_name(str(tag)), "role": "ability"})
	return specs

func _item_tags(row: Dictionary, unlocked: bool) -> Array[String]:
	# Text-only compatibility helper for copy that still needs a joined list.
	var tags: Array[String] = []
	for spec in _item_tag_specs(row, unlocked):
		tags.append(str(spec.get("text", "")))
	return tags

func _style_upgrade_button(button: Button, item_level: int) -> void:
	var rank := _growth_rank(item_level)
	button.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.62, 0.68, 0.78))
	button.add_theme_stylebox_override("normal", _upgrade_style(Color(0.12, 0.22, 0.34, 0.9), Color(0.35, 0.58, 0.86, 0.85 + 0.04 * rank)))
	button.add_theme_stylebox_override("hover", _upgrade_style(Color(0.16, 0.31, 0.48, 0.95), Color(0.56, 0.78, 1.0, 0.95)))
	button.add_theme_stylebox_override("pressed", _upgrade_style(Color(0.08, 0.16, 0.25, 0.96), Color(0.35, 0.68, 1.0, 0.95)))
	button.add_theme_stylebox_override("disabled", _upgrade_style(Color(0.08, 0.1, 0.14, 0.76), Color(0.28, 0.34, 0.44, 0.78)))

func _upgrade_style(_bg: Color, _border: Color) -> StyleBox:
	return UiKit.map_pill_texture_style()

func _growth_rank(level: int) -> int:
	if level >= 40:
		return 4
	if level >= 30:
		return 3
	if level >= 20:
		return 2
	if level >= 10:
		return 1
	return 0

func _data_table_name() -> String:
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

func _locked_character_teaser(item_id: String) -> String:
	match item_id:
		"char_blaze":
			return _loc("专属预告：熔毁轰击 · 锁定强敌连续引爆火焰", "Signature Preview: Meltdown · Repeated firebursts on a priority target")
		"char_frost":
			return _loc("专属预告：冰川领域 · 全屏减速并掀起寒潮", "Signature Preview: Glacier · Field-wide Slow and frost waves")
		"char_volt":
			return _loc("专属预告：雷暴链击 · 连续雷击高威胁目标", "Signature Preview: Storm Chain · Repeated strikes on high-threat targets")
		_:
			return _loc("专属预告：钢雨齐射 · 多轮弹幕压制尸潮", "Signature Preview: Steel Rain · Multi-salvo horde suppression")

func _item_desc(item_id: String, row: Dictionary, unlocked: bool) -> String:
	if mode == "characters":
		if not unlocked:
			return _locked_character_teaser(item_id)
		return LocalizationManager.text(_next_upgrade_hint(item_id, row))
	if not unlocked:
		# Price already lives in the action button; repeating it here squeezes the
		# useful stats and can collide with the button on a phone-sized card.
		return _item_stat_summary(row)
	match mode:
		"weapons":
			# Element and weapon mechanism already live in the semantic tag row.
			# Keep prose for the numeric value that is not represented there.
			return _loc("射速：%s", "Fire Rate: %s") % row.get("fire_rate", "-")
		"armors":
			var barrier_zh := "\n防线屏障 +1" if int(row.get("breach_shield", 0)) > 0 else ""
			var barrier_en := "\nBarrier +1" if int(row.get("breach_shield", 0)) > 0 else ""
			return _loc(
				"生命倍率：%.0f%%\n%s%s" % [float(row.get("hp_mult", 1.0)) * 100.0, _next_upgrade_hint(item_id, row), barrier_zh],
				"HP: %.0f%%\n%s%s" % [float(row.get("hp_mult", 1.0)) * 100.0, LocalizationManager.text(_next_upgrade_hint(item_id, row)), barrier_en]
			)
		"chips":
			return _loc("当前加成 +%s", "Current Bonus +%s") % _value_text(row.get("value", 0))
		"pets":
			var pet_skill: Dictionary = row.get("pet_skill", {})
			return "%s · %s" % [LocalizationManager.text(str(pet_skill.get("name", "专属协战"))), LocalizationManager.text(_next_upgrade_hint(item_id, row))]
		"skills":
			return _loc("标签：%s", "Tags: %s") % LocalizationManager.text(_format_tags(row.get("card_tags", [])))
		_:
			return item_id

func _item_stat_summary(row: Dictionary) -> String:
	# 未拥有时也要看到的核心参数（不含升级提示），方便判断该不该买。
	match mode:
		"characters":
			return _loc("定位：%s  元素：%s", "Role: %s · Element: %s") % [LocalizationManager.text(_role_name(row.get("role_tag", "-"))), LocalizationManager.text(_element_name(row.get("element_focus", "-")))]
		"weapons":
			return _loc("射速：%s", "Fire Rate: %s") % str(row.get("fire_rate", "-"))
		"armors":
			return _loc("生命倍率：%.0f%%%s", "HP: %.0f%%%s") % [float(row.get("hp_mult", 1.0)) * 100.0, _loc("\n防线屏障 +1", "\nBarrier +1") if int(row.get("breach_shield", 0)) > 0 else ""]
		"chips":
			return _loc("解锁后加成 +%s", "Bonus After Unlock +%s") % _value_text(row.get("value", 0))
		"pets":
			var pet_skill: Dictionary = row.get("pet_skill", {})
			return _loc("协战：%s", "Support: %s") % LocalizationManager.text(str(pet_skill.get("name", "专属协战")))
		_:
			return ""

func _skill_effect_summary(row: Dictionary, current_level: int) -> String:
	var levels: Array = row.get("levels", [])
	if levels.is_empty():
		return _loc("效果：%s", "Effect: %s") % LocalizationManager.text(_format_tags(row.get("card_tags", [])))
	var max_level := levels.size()
	if current_level <= 0:
		var first: Dictionary = levels[0]
		return LocalizationManager.text("当前：未升级 · 首级 %s") % SkillEffectText.format_effect(first.get("effect", {}))
	var clamped := clampi(current_level, 1, max_level)
	var effect := SkillEffectText.effect_for_level(row, clamped)
	return _loc("当前：%s", "Current: %s") % SkillEffectText.format_effect(effect)

func _element_name(element: String) -> String:
	match str(element):
		"physical":
			return "物理"
		"fire":
			return "火焰"
		"ice":
			return "冰霜"
		"lightning":
			return "闪电"
		"poison":
			return "毒素"
		"none", "":
			return "无"
		_:
			return str(element)

func _role_name(role: String) -> String:
	match str(role):
		"balanced":
			return "均衡"
		"burst":
			return "爆发"
		"control":
			return "控制"
		"speed":
			return "高速"
		"damage":
			return "输出"
		"burn":
			return "灼烧"
		"slow":
			return "减速"
		"chain":
			return "连锁"
		"repair":
			return "维修"
		"economy":
			return "经济"
		"apocalypse_chain":
			return _loc("终焉连锁", "Apocalypse Chain")
		"apocalypse_fire":
			return _loc("终焉火焰", "Apocalypse Fire")
		"apocalypse_ice":
			return _loc("终焉冰霜", "Apocalypse Frost")
		"apocalypse_golden_law":
			return _loc("黄金律令", "Golden Law")
		_:
			return str(role)

func _stat_name(stat: String) -> String:
	match str(stat):
		"damage_mult":
			return "伤害"
		"fire_rate_mult":
			return "射速"
		"crit_rate":
			return "暴击率"
		"pierce_bonus":
			return "穿透"
		"base_hp_mult":
			return "基地生命"
		"breach_damage_reduction":
			return "防线减伤"
		"gold_mult":
			return "金币收益"
		"element_damage_mult":
			return "元素伤害"
		_:
			return str(stat)

func _tag_name(tag: String) -> String:
	match tag:
		"projectile":
			return "弹道"
		"anti_swarm":
			return "清群"
		"anti_armor":
			return "破甲"
		"control":
			return "控制"
		"defense":
			return "防线"
		"economy":
			return "经济"
		"element":
			return "元素"
		"execute":
			return "处决"
		"pierce":
			return "穿透"
		"homing":
			return "追踪"
		"chain":
			return "连锁"
		"burn":
			return "灼烧"
		"haste":
			return "急速"
		"dps":
			return "输出"
		"fire", "ice", "lightning", "poison", "physical":
			return _element_name(tag)
		_:
			return tag

func _kind_name(kind: String) -> String:
	match str(kind):
		"passive":
			return "被动强化"
		"active":
			return "主动技能"
		"ammo":
			return "弹药模块"
		"projectile":
			return "弹道强化"
		"economy":
			return "收益强化"
		"defense":
			return "防线强化"
		"element":
			return "元素模块"
		_:
			return str(kind)

func _skill_kind_short_name(kind: String) -> String:
	match str(kind):
		"passive":
			return "被动"
		"active":
			return "主动"
		"ammo":
			return "弹种"
		"projectile":
			return "弹道类"
		"economy":
			return "经济"
		"defense":
			return "防线"
		_:
			return _kind_name(kind)

func _format_tags(tags: Array) -> String:
	var names: Array[String] = []
	for tag in tags:
		names.append(_tag_name(str(tag)))
	return " / ".join(names)

func _value_text(value: Variant) -> String:
	var numeric := float(value)
	if absf(numeric) < 1.0:
		return "%d%%" % int(round(numeric * 100.0))
	return "%d" % int(round(numeric))

func _weapon_special_text(row: Dictionary, item_level := -1) -> String:
	var special: Dictionary = row.get("special", {})
	if int(special.get("pellets", 0)) > 0:
		var pellet_growth_var: Variant = special.get("pellet_growth", [])
		var pellet_growth: Array = pellet_growth_var if pellet_growth_var is Array else []
		if not pellet_growth.is_empty():
			var base_step: Dictionary = pellet_growth[0] if pellet_growth[0] is Dictionary else {}
			var base_pellets := int(base_step.get("pellets", special.get("pellets", 1)))
			var max_pellets := int(special.get("pellets", base_pellets))
			if item_level >= 1:
				return _loc("当前 %d 弹丸 · 满级 %d", "Current %d pellets · max %d") % [SaveManager.weapon_pellet_count_from_row(row, item_level), max_pellets]
			return _loc("%d→%d 弹丸", "%d→%d pellets") % [base_pellets, max_pellets]
		return "%d 弹丸" % int(special.get("pellets", 1))
	if int(special.get("pierce", 0)) > 0:
		return "自带穿透 +%d" % int(special.get("pierce", 0))
	if int(special.get("chain", 0)) > 0:
		return "自带连锁 +%d 目标" % int(special.get("chain", 0))
	if float(special.get("splash", 0.0)) > 0.0:
		return "溅射 %d" % int(special.get("splash", 0))
	if float(special.get("cloud", 0.0)) > 0.0:
		return "毒云范围 %d" % int(special.get("cloud", 0))
	if float(special.get("spread", 0.0)) > 0.0:
		# Runtime consumes this field with deg_to_rad(), so the authored unit is degrees.
		return "扩散 %d°" % int(special.get("spread", 0))
	return ""

# 升级预览：返回 [{label, cur, next, delta}]，直观展示本级 → 下级各属性变化。
func _upgrade_preview_rows(item_id: String, row: Dictionary, level: int) -> Array:
	var max_level := int(row.get("max_level", 30))
	if level >= max_level:
		return []
	var nxt := level + 1
	var rows := []
	match mode:
		"weapons":
			rows.append({"label": "伤害", "cur": "+%d%%" % int(round(0.08 * float(level - 1) * 100.0)), "next": "+%d%%" % int(round(0.08 * float(nxt - 1) * 100.0)), "delta": "每级 +8%"})
			rows.append({"label": "射速", "cur": "+%d%%" % int(round(0.025 * float(level - 1) * 100.0)), "next": "+%d%%" % int(round(0.025 * float(nxt - 1) * 100.0)), "delta": "每级 +2.5%"})
		"characters":
			var g := float(row.get("atk_growth", 0.08)) * 0.52
			rows.append({"label": "攻击", "cur": "+%d%%" % int(round(g * float(level - 1) * 100.0)), "next": "+%d%%" % int(round(g * float(nxt - 1) * 100.0)), "delta": "每级 +%d%%" % int(round(g * 100.0))})
			rows.append({"label": "主动/专属技能", "cur": "等级%d" % level, "next": "等级%d" % nxt, "delta": "威力随等级成长"})
		"armors":
			var ag := float(row.get("level_hp_growth", 0.0))
			var hp := float(row.get("hp_mult", 1.0))
			rows.append({"label": "基地生命", "cur": "+%d%%" % int(round((hp * (1.0 + ag * float(level - 1)) - 1.0) * 100.0)), "next": "+%d%%" % int(round((hp * (1.0 + ag * float(nxt - 1)) - 1.0) * 100.0)), "delta": "每级 +%d%%" % int(round(hp * ag * 100.0))})
		"chips":
			var cg := float(row.get("level_value_growth", 0.0))
			var base := float(row.get("value", 0))
			rows.append({"label": _stat_name(row.get("stat", "增幅")), "cur": _value_text(base * (1.0 + cg * float(level - 1))), "next": _value_text(base * (1.0 + cg * float(nxt - 1))), "delta": "每级 +%s" % _value_text(base * cg)})
		"pets":
			if row.has("damage"):
				var pg := float(row.get("level_damage_growth", 0.0))
				var pbase := float(row.get("damage", 0))
				rows.append({"label": "伤害", "cur": "%d" % int(round(pbase * (1.0 + pg * float(level - 1)))), "next": "%d" % int(round(pbase * (1.0 + pg * float(nxt - 1)))), "delta": "每级 +%d" % int(round(pbase * pg))})
			var pet_skill: Dictionary = row.get("pet_skill", {})
			if str(pet_skill.get("kind", "")) not in ["", "repair"]:
				rows.append({
					"label": str(pet_skill.get("name", "专属技能")),
					"cur": _pet_skill_summary(row, level),
					"next": _pet_skill_summary(row, nxt),
					"delta": "专属效果随等级成长"
				})
			if row.has("heal_per_wave"):
				var hg := float(row.get("level_heal_growth", 0.0))
				var hbase := float(row.get("heal_per_wave", 0))
				var wave_ratio := float(row.get("heal_per_wave_ratio", 0.0))
				var wave_ratio_growth := float(row.get("level_wave_heal_ratio_growth", 0.0))
				rows.append({
					"label": "波次整备",
					"cur": "%d + %.1f%%" % [int(round(hbase * (1.0 + hg * float(level - 1)))), (wave_ratio + wave_ratio_growth * float(level - 1)) * 100.0],
					"next": "%d + %.1f%%" % [int(round(hbase * (1.0 + hg * float(nxt - 1)))), (wave_ratio + wave_ratio_growth * float(nxt - 1)) * 100.0],
					"delta": "固定值 + 最大生命"
				})
			if row.has("repair_ratio"):
				var repair_ratio := float(row.get("repair_ratio", 0.0))
				var repair_growth := float(row.get("level_repair_ratio_growth", 0.0))
				rows.append({
					"label": "持续维修",
					"cur": "%.2f%%" % ((repair_ratio + repair_growth * float(level - 1)) * 100.0),
					"next": "%.2f%%" % ((repair_ratio + repair_growth * float(nxt - 1)) * 100.0),
					"delta": "每 %.0f 秒" % float(row.get("repair_interval", 18.0))
				})
			if row.has("emergency_heal_ratio"):
				var emergency_ratio := float(row.get("emergency_heal_ratio", 0.0))
				var emergency_growth := float(row.get("level_emergency_heal_growth", 0.0))
				rows.append({
					"label": "应急救援",
					"cur": "%.1f%%" % ((emergency_ratio + emergency_growth * float(level - 1)) * 100.0),
					"next": "%.1f%%" % ((emergency_ratio + emergency_growth * float(nxt - 1)) * 100.0),
					"delta": "低血量触发"
				})
	return rows

func _next_upgrade_hint(item_id: String, row: Dictionary) -> String:
	var level := SaveManager.get_item_level(item_id)
	var max_level := int(row.get("max_level", 30))
	if level >= max_level:
		return "已满级"
	match mode:
		"weapons":
			var weapon_hint := "下一级 伤害+8% · 射速+2.5%"
			var current_pellets := SaveManager.weapon_pellet_count_from_row(row, level)
			var next_pellets := SaveManager.weapon_pellet_count_from_row(row, level + 1)
			if next_pellets > current_pellets:
				weapon_hint += " · 弹丸+%d" % (next_pellets - current_pellets)
			return weapon_hint
		"characters":
			return "下一级 攻击+%d%%" % int(round(float(row.get("atk_growth", 0.08)) * 0.52 * 100.0))
		"armors":
			return "下一级 生命+%d%%" % int(round(float(row.get("hp_mult", 1.0)) * float(row.get("level_hp_growth", 0.0)) * 100.0))
		"chips":
			return "下一级 +%s" % _value_text(float(row.get("value", 0)) * float(row.get("level_value_growth", 0.0)))
		"pets":
			if row.get("role", "") == "repair":
				return "下一级 波次+%.1f%% · 持续+%.2f%%" % [
					float(row.get("level_wave_heal_ratio_growth", 0.0)) * 100.0,
					float(row.get("level_repair_ratio_growth", 0.0)) * 100.0,
				]
			var pet_skill: Dictionary = row.get("pet_skill", {})
			if not pet_skill.is_empty():
				# The skill name is already printed immediately before this hint.
				# Avoid repeating it in a narrow phone card.
				return "下一级 协战强化"
			if row.has("damage"):
				return "下一级 伤害+%d" % int(round(float(row.get("damage", 0)) * float(row.get("level_damage_growth", 0.0))))
			return "下一级 效率提升"
		_:
			return "下一级强化"

func _level_tint(level: int) -> Color:
	if level >= 25:
		return Color(1.0, 0.82, 0.34, 1.0)
	if level >= 15:
		return Color(0.72, 0.9, 1.0, 1.0)
	if level >= 8:
		return Color(0.78, 1.0, 0.72, 1.0)
	return Color.WHITE

func _tier_suffix(level: int) -> String:
	if level >= 25:
		return " III"
	if level >= 15:
		return " II"
	if level >= 8:
		return " I"
	return ""

func _growth_badge_text(level: int) -> String:
	if level >= 25:
		return "金色改装"
	if level >= 15:
		return "精英校准"
	if level >= 8:
		return "战术改装"
	return "基础型"

func _upgrade_item(item_id: String) -> void:
	if SaveManager.upgrade_item(_data_table_name(), item_id):
		AudioManager.play_sfx("upgrade")
		_refresh()
		_pulse_selected_item(item_id)
	else:
		AudioManager.play_sfx("ui_click", -6.0)

func _select_item(slot: String, item_id: String) -> void:
	if SaveManager.select_item(slot, item_id):
		AudioManager.play_sfx("ui_confirm")
		_refresh()
		_pulse_selected_item(item_id)

func _purchase_item_flow(item_id: String, row: Dictionary) -> void:
	if _is_premium_item(row):
		_open_premium_store()
		return
	var table := _data_table_name()
	var price := SaveManager.get_unlock_price_star(table, item_id)
	if not SaveManager.can_purchase(table, item_id):
		AudioManager.play_sfx("ui_click", -6.0)
		return
	AudioManager.play_sfx("ui_click", -4.0)
	var name_text: String = DataLoader.tr_key(row.get("name_key", item_id))
	var preview_icon: String = UiKit.character_bust_path(row) if mode == "characters" else UiKit.item_icon_path(table, item_id, row)
	UiKit.confirm_modal(self, {
		"title": "购买确认",
		"message": "确认解锁 %s？" % name_text,
		"cost_text": "%d" % price,
		"cost_kind": "star",
		"item_icon": preview_icon,
		"accent": Color(0.96, 0.80, 0.30, 1.0),
		"confirm_text": "购买",
		"cancel_text": "取消",
		"on_confirm": func() -> void: _do_purchase(table, item_id),
	})

func _open_premium_store() -> void:
	AudioManager.play_sfx("ui_confirm")
	if _detail_modal != null and is_instance_valid(_detail_modal):
		_detail_modal.queue_free()
		_detail_modal = null
	if router != null:
		router.change_scene("store")

func _do_purchase(table: String, item_id: String) -> void:
	var res := SaveManager.purchase_item(table, item_id)
	if res == SaveManager.PurchaseResult.OK:
		AudioManager.play_sfx("star_gain")
		var slot := _slot()
		if slot != "":
			SaveManager.select_item(slot, item_id)
		_refresh()
		_pulse_selected_item(item_id)
	else:
		AudioManager.play_sfx("ui_click", -6.0)

func _pulse_selected_item(item_id: String) -> void:
	for child in (%ItemList as VBoxContainer).get_children():
		if child.name != item_id:
			continue
		var tween := child.create_tween()
		tween.tween_property(child, "scale", Vector2(1.035, 1.035), 0.08)
		tween.tween_property(child, "scale", Vector2.ONE, 0.12)
		return

func _show_item_detail(item_id: String, row: Dictionary) -> void:
	var premium_entitlement := str(row.get("premium_entitlement", "")).strip_edges()
	if premium_entitlement != "" and not PurchaseManager.is_entitlement_revealed(premium_entitlement):
		return
	if mode == "characters":
		call_deferred("_show_character_detail", item_id, row)
		return
	_set_collection_content_visible(false)
	if _detail_modal != null and is_instance_valid(_detail_modal):
		_detail_modal.queue_free()
	var slot := _slot()
	var table := _data_table_name()
	var item_level := SaveManager.get_skill_base_level(item_id) if mode == "skills" else SaveManager.get_item_level(item_id)
	var selected := slot != "" and SaveManager.get_selected(slot) == item_id
	var accent := _mode_accent(row)
	_detail_modal = Control.new()
	_detail_modal.name = "ItemDetail"
	_detail_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Collection row children use z=1..3 for veils, portraits and actions. Keep the
	# entire modal above that local stack so list text cannot punch through it.
	_detail_modal.z_index = 64
	_detail_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	_detail_modal.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_detail_modal)

	var dim := TextureRect.new()
	dim.texture = _modal_dim_texture()
	dim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dim.stretch_mode = TextureRect.STRETCH_SCALE
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_modal.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var safe := UiKit.safe_area_canvas_insets(get_viewport())
	var modal_shift := UiKit.tall_modal_shift(get_viewport_rect().size.y, 150.0, 0.30)
	# The three-action row has a fixed 934 px native minimum. Keep the modal
	# gutters inside the real safe width instead of letting Container minimums
	# push the right edge under a tall-phone sensor inset.
	panel.offset_left = 28.0 + safe.x
	panel.offset_top = 150.0 + safe.y + modal_shift
	panel.offset_right = -28.0 - safe.z
	panel.offset_bottom = -140.0 - safe.w + modal_shift
	if mode == "skills":
		panel.offset_top = 230.0 + safe.y + modal_shift
		panel.offset_bottom = -250.0 - safe.w + modal_shift
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_meta("safe_area_content", true)
	panel.add_theme_stylebox_override("panel", _build_panel_style())
	_detail_modal.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 244 if LocalizationManager.is_english() else 210)
	header.add_theme_constant_override("separation", 18)
	vbox.add_child(header)

	var icon_frame := PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(196, 196)
	icon_frame.add_theme_stylebox_override("panel", _build_pill_style(accent, Color(0.06, 0.1, 0.16, 0.92)))
	header.add_child(icon_frame)
	var icon := TextureRect.new()
	icon.texture = load(UiKit.item_icon_path(_data_table_name(), item_id, row))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(180, 180)
	icon_frame.add_child(icon)

	var name_col := VBoxContainer.new()
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_col.add_theme_constant_override("separation", 8)
	header.add_child(name_col)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 12)
	name_col.add_child(name_row)
	var name_label := Label.new()
	name_label.text = DataLoader.tr_key(row.get("name_key", item_id))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# The English apocalypse name is intentionally descriptive. Reserve the
	# level/close controls and use the same mobile-readable fit as other long
	# English equipment names instead of clipping the last word.
	var detail_name_font_size := 30 if LocalizationManager.is_english() else 40
	if mode == "skills":
		detail_name_font_size = SKILL_DETAIL_NAME_FONT_SIZE_EN if LocalizationManager.is_english() else SKILL_DETAIL_NAME_FONT_SIZE_ZH
	UiKit.apply_label(name_label, detail_name_font_size, Color(0.98, 0.99, 1.0, 1.0), 4)
	if LocalizationManager.is_english():
		name_label.custom_minimum_size = Vector2(0, 112)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = false
	name_row.add_child(name_label)
	var level_badge := _make_pill("等级%d%s" % [item_level, _tier_suffix(item_level)], _level_tint(item_level), Color(0.08, 0.11, 0.16, 0.92))
	level_badge.custom_minimum_size = Vector2(128, 44)
	if mode == "skills":
		(level_badge.get_child(0) as Label).add_theme_font_size_override("font_size", UiKit.bumped_font_size(20))
	name_row.add_child(level_badge)

	var tag_row := HBoxContainer.new()
	tag_row.name = "DetailMetadataTags"
	tag_row.add_theme_constant_override("separation", 10)
	name_col.add_child(tag_row)
	var detail_tag_index := 0
	for tag_spec in _item_tag_specs(row, true).slice(0, 4):
		var tag_pill := UiKit.semantic_tag_pill(
			LocalizationManager.text(str(tag_spec.get("text", ""))),
			str(tag_spec.get("role", "ability")),
			15 if mode == "skills" else 16
		)
		tag_pill.name = "DetailMetadataTag%d" % detail_tag_index
		if mode == "skills":
			tag_pill.custom_minimum_size.y = 38.0
		tag_row.add_child(tag_pill)
		detail_tag_index += 1

	var summary := Label.new()
	summary.text = _item_desc(item_id, row, true)
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(summary, SKILL_DETAIL_SUMMARY_FONT_SIZE if mode == "skills" else 21, Color(0.78, 0.91, 1.0, 1.0), 3)
	name_col.add_child(summary)

	var close_btn := _compact_close_button("CloseButton")
	close_btn.pressed.connect(_close_character_detail)
	header.add_child(close_btn)

	var content_scroll := ScrollContainer.new()
	content_scroll.name = "DetailScroll"
	content_scroll.scroll_deadzone = DETAIL_SCROLL_DEADZONE
	content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(content_scroll)
	var detail_content := VBoxContainer.new()
	detail_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_content.add_theme_constant_override("separation", 12)
	content_scroll.add_child(detail_content)

	var stats_section := _make_section_panel(
		"核心数据",
		accent,
		SKILL_DETAIL_SECTION_TITLE_FONT_SIZE if mode == "skills" else 24
	)
	detail_content.add_child(stats_section)
	var stats_grid := GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 12)
	stats_grid.add_theme_constant_override("v_separation", 10)
	stats_section.get_child(0).add_child(stats_grid)
	for stat in _detail_stats_for_item(item_id, row, item_level):
		stats_grid.add_child(_make_stat_pill(
			str(stat.get("label", "")),
			str(stat.get("value", "")),
			str(stat.get("sub", "")),
			SKILL_DETAIL_STAT_FONT_DELTA if mode == "skills" else 0,
			str(stat.get("resource_kind", ""))
		))
	# 升级预览：本级 → 下级，直观看到"升级到底加了什么"
	if mode != "skills" and SaveManager.is_item_unlocked(slot, item_id):
		var preview := _upgrade_preview_rows(item_id, row, item_level)
		if not preview.is_empty():
			var up_section := _make_section_panel("升级预览  (等级%d → %d)" % [item_level, item_level + 1], UiKit.GREEN)
			detail_content.add_child(up_section)
			var up_grid := GridContainer.new()
			up_grid.columns = 1
			up_grid.add_theme_constant_override("v_separation", 8)
			up_section.get_child(0).add_child(up_grid)
			for pr in preview:
				up_grid.add_child(_make_stat_pill(str(pr.get("label", "")), "%s → %s" % [str(pr.get("cur", "")), str(pr.get("next", ""))], str(pr.get("delta", ""))))
	if mode == "skills":
		detail_content.add_child(_make_skill_levels_section(row, accent, item_level))

	var desc_section := _make_section_panel(
		"战术说明",
		Color(0.68, 0.82, 1.0, 0.82),
		SKILL_DETAIL_SECTION_TITLE_FONT_SIZE if mode == "skills" else 24
	)
	desc_section.name = "TacticalNotesSection"
	detail_content.add_child(desc_section)
	var desc_label := Label.new()
	desc_label.text = _detail_body_text(item_id, row)
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.clip_text = false
	desc_label.name = "DescriptionBody"
	UiKit.apply_label(desc_label, SKILL_DETAIL_DESCRIPTION_FONT_SIZE if mode == "skills" else 20, Color(0.9, 0.96, 1.0, 1.0), 3)
	desc_label.add_theme_constant_override("line_spacing", 7)
	desc_section.get_child(0).add_child(desc_label)
	detail_content.add_child(_make_detail_scroll_bottom_clearance())
	content_scroll.mouse_force_pass_scroll_events = true
	_configure_detail_scroll_surface(detail_content)

	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 16)
	vbox.add_child(action_row)
	if mode != "skills" and not SaveManager.is_item_unlocked(slot, item_id):
		if _is_premium_item(row):
			var store_btn := _armored_action_button("OpenArsenalButton", _loc("前往终焉军械库", "Open Apocalypse Arsenal"), true, true, Vector2(440, 112), 24)
			store_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			store_btn.pressed.connect(_open_premium_store)
			action_row.add_child(store_btn)
		else:
			# 未拥有：详情页里直接给购买按钮（买得起=亮，买不起=灰禁用）。
			var buy_cost_spec := SaveManager.get_unlock_cost_spec(table, item_id)
			var buy_price := int(buy_cost_spec.get("amount", 0))
			var can_buy := SaveManager.get_player_star() >= buy_price
			var buy_action := _loc("购买", "Buy") if can_buy else _loc("不足", "Need")
			var buy_btn := _detail_button("BuyButton", buy_action, true)
			UiKit.apply_resource_cost(buy_btn, buy_action, str(buy_cost_spec.get("kind", "star")), buy_price, 18, 28.0)
			buy_btn.disabled = not can_buy
			buy_btn.modulate = ACTION_ACTIVE_MODULATE if can_buy else ACTION_DISABLED_MODULATE
			buy_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			buy_btn.pressed.connect(_purchase_item_flow.bind(item_id, row))
			action_row.add_child(buy_btn)
	elif mode != "skills":
		var equip_btn := _detail_button("EquipButton", "已装备" if selected else "装  备", true)
		equip_btn.disabled = selected
		equip_btn.modulate = ACTION_DISABLED_MODULATE if selected else ACTION_ACTIVE_MODULATE
		equip_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		equip_btn.pressed.connect(_select_item_and_close.bind(slot, item_id))
		action_row.add_child(equip_btn)

		var can_upgrade := table != "" and SaveManager.can_upgrade_item(table, item_id)
		var upgrade_cost_spec := SaveManager.get_item_upgrade_cost_spec(table, item_id) if table != "" else {}
		var cost := int(upgrade_cost_spec.get("amount", 0))
		var max_level := int(row.get("max_level", item_level))
		var upgrade_label := "已满级" if item_level >= max_level else _loc("升级", "Upgrade")
		var upgrade_btn := _detail_button("UpgradeButton", upgrade_label, false)
		if item_level < max_level:
			UiKit.apply_resource_cost(upgrade_btn, upgrade_label, str(upgrade_cost_spec.get("kind", "gold")), cost, 18, 28.0)
		upgrade_btn.disabled = not can_upgrade
		upgrade_btn.modulate = ACTION_SECONDARY_MODULATE if can_upgrade else ACTION_DISABLED_MODULATE
		upgrade_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		upgrade_btn.pressed.connect(_upgrade_item_from_detail.bind(item_id, row))
		action_row.add_child(upgrade_btn)
	else:
		var skill_lvl := SaveManager.get_skill_base_level(item_id)
		var skill_max := SaveManager.get_skill_base_max(item_id)
		var skill_cost_spec := SaveManager.get_skill_base_upgrade_cost_spec(item_id)
		var skill_cost := int(skill_cost_spec.get("amount", -1))
		var can_up := SaveManager.can_upgrade_skill_base(item_id)
		var skill_label := "已精通" if skill_lvl >= skill_max else _loc("升级", "Upgrade")
		var skill_btn := _armored_action_button("SkillUpgradeButton", skill_label, true, true, Vector2(412, 112), 24)
		if skill_lvl < skill_max:
			UiKit.apply_resource_cost(skill_btn, skill_label, str(skill_cost_spec.get("kind", "xp")), skill_cost, 21, 32.0)
		skill_btn.tooltip_text = _loc("消耗 %d 经验，永久提升技能" % skill_cost, "Spend %d XP to permanently upgrade this skill" % skill_cost)
		skill_btn.disabled = not can_up
		skill_btn.modulate = ACTION_ACTIVE_MODULATE if can_up else ACTION_DISABLED_MODULATE
		skill_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		skill_btn.pressed.connect(_upgrade_skill_from_detail.bind(item_id, row))
		action_row.add_child(skill_btn)
	var close_bottom := _detail_button("CloseBottomButton", "关  闭", false)
	close_bottom.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_bottom.pressed.connect(_close_character_detail)
	action_row.add_child(close_bottom)

	_detail_modal.modulate.a = 0.0
	panel.scale = Vector2(0.95, 0.95)
	var tween := _detail_modal.create_tween()
	tween.parallel().tween_property(_detail_modal, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _detail_button(node_name: String, text: String, primary: bool) -> TextureButton:
	return _armored_action_button(node_name, text, true, primary, Vector2(286, 112), 24)

func _armored_action_button(node_name: String, text: String, enabled: bool, primary: bool, button_size: Vector2, font_size: int) -> TextureButton:
	var button := TextureButton.new()
	button.name = node_name
	UiKit.apply_armored_texture_button(button, primary, button_size, enabled)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.modulate = (ACTION_ACTIVE_MODULATE if primary else ACTION_SECONDARY_MODULATE) if enabled else ACTION_DISABLED_MODULATE
	var label := Label.new()
	label.name = "ActionLabel"
	label.text = LocalizationManager.text(text)
	button.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_armored_button_label_alignment(label)
	var preferred_size := UiKit.scaled_font_size(font_size)
	UiKit.apply_label(label, font_size, Color.WHITE if enabled else Color(0.74, 0.78, 0.82, 1.0), 3)
	UiKit.fit_label_text(label, preferred_size, 16, 18.0, 10.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return button

func _apply_armored_button_label_alignment(label: Label) -> void:
	# Glow Sans has generous upper metrics, so mathematical centering reads low
	# inside the asymmetric armored bezel. Keep the control centered and apply
	# one small, collection-wide optical correction to the glyph box only.
	label.offset_top = ARMORED_BUTTON_LABEL_OPTICAL_Y
	label.offset_bottom = ARMORED_BUTTON_LABEL_OPTICAL_Y

func _compact_close_button(node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0, 0.95))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.86, 0.45, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.78, 0.9, 1.0, 1.0))
	button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.65))
	# The former map-pill texture was authored as a wide horizontal capsule.
	# Compressing it into a square made its top corners read shifted right and
	# its bottom corners shifted left. Use the production square icon frame for
	# one straight perimeter, with the active frame only for interaction states.
	button.add_theme_stylebox_override("normal", _compact_close_style(false))
	button.add_theme_stylebox_override("hover", _compact_close_style(true))
	button.add_theme_stylebox_override("pressed", _compact_close_style(true))
	button.add_theme_stylebox_override("disabled", _compact_close_style(false))
	UiKit.apply_close_glyph(button)
	button.custom_minimum_size = DETAIL_CLOSE_BUTTON_SIZE
	button.add_theme_font_size_override("font_size", DETAIL_CLOSE_GLYPH_FONT_SIZE)
	return button

func _compact_close_style(active: bool) -> StyleBox:
	return UiKit.icon_frame_texture_style(active)

func _make_detail_scroll_bottom_clearance() -> Control:
	var clearance := Control.new()
	clearance.name = "DetailScrollBottomClearance"
	clearance.custom_minimum_size = Vector2(0.0, DETAIL_SCROLL_BOTTOM_CLEARANCE)
	clearance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return clearance

func _configure_detail_scroll_surface(root: Node) -> void:
	# Detail cards contain panels and an upgrade button. STOP on any of those
	# children prevented an iPhone drag from reaching DetailScroll, producing a
	# visible scrollbar that felt inert. PASS retains stationary button taps but
	# lets ScrollContainer cancel the press once the drag deadzone is crossed.
	if root is Control and (root as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
		(root as Control).mouse_filter = Control.MOUSE_FILTER_PASS
	if root is BaseButton:
		root.set_meta("detail_scroll_drag_passthrough", true)
	for child in root.get_children():
		_configure_detail_scroll_surface(child)

func _detail_stats_for_item(item_id: String, row: Dictionary, item_level: int) -> Array:
	var stats := []
	var table := _data_table_name()
	var max_level := int(row.get("max_level", 0))
	if mode != "skills":
		stats.append({"label": "等级", "value": "%d / %d" % [item_level, max_level], "sub": _growth_badge_text(item_level)})
	if mode != "skills" and table != "":
		if _is_premium_item(row) and not SaveManager.is_item_unlocked(_slot(), item_id):
			stats.append({
				"label": _loc("获取方式", "Access"),
				"value": _loc("终焉军械库", "Apocalypse Arsenal"),
				"sub": _loc("购买整套后可升级", "Upgrade after unlock"),
			})
		elif item_level >= max_level:
			stats.append({"label": "状态", "value": "已满级", "sub": "成长已完成"})
		else:
			var cost_spec := SaveManager.get_item_upgrade_cost_spec(table, item_id)
			stats.append({
				"label": "升级",
				"value": "%d" % int(cost_spec.get("amount", 0)),
				"resource_kind": str(cost_spec.get("kind", "gold")),
				"sub": _next_upgrade_hint(item_id, row),
			})
	match mode:
		"weapons":
			stats.append({"label": "元素", "value": _element_name(row.get("element", "-")), "sub": _projectile_type_name(str(row.get("projectile_type", "bullet")))})
			stats.append({"label": "攻击", "value": "%.0f%%" % (float(row.get("base_atk_coef", 1.0)) * 100.0), "sub": "等级伤害 %.0f%%" % ((SaveManager.get_weapon_damage_multiplier(item_id) - 1.0) * 100.0)})
			stats.append({"label": "射速", "value": "%.1f / 秒" % float(row.get("fire_rate", 0.0)), "sub": "等级射速 %.0f%%" % ((SaveManager.get_weapon_fire_rate_multiplier(item_id) - 1.0) * 100.0)})
			stats.append({"label": "弹速", "value": "%d" % int(row.get("projectile_speed", 0)), "sub": _weapon_special_text(row, item_level)})
		"armors":
			var armor_g := float(row.get("level_hp_growth", 0.0))
			var armor_now := float(row.get("hp_mult", 1.0)) * (1.0 + armor_g * float(max(item_level - 1, 0)))
			var armor_max := float(row.get("hp_mult", 1.0)) * (1.0 + armor_g * float(max(max_level - 1, 0)))
			stats.append({"label": "生命", "value": "+%d%%" % int(round((armor_now - 1.0) * 100.0)), "sub": "等级%d · 满级 +%d%%" % [item_level, int(round((armor_max - 1.0) * 100.0))]})
			stats.append({"label": "抗性", "value": _element_name(row.get("resist", "none")), "sub": "防线承压"})
			stats.append({"label": "屏障", "value": "+%d" % int(row.get("breach_shield", 0)), "sub": "防线容错"})
		"chips":
			var chip_g := float(row.get("level_value_growth", 0.0))
			var chip_base := float(row.get("value", 0))
			var chip_now := chip_base * (1.0 + chip_g * float(max(item_level - 1, 0)))
			var chip_max := chip_base * (1.0 + chip_g * float(max(max_level - 1, 0)))
			stats.append({"label": "属性", "value": _stat_name(row.get("stat", "stat")), "sub": "核心芯片"})
			stats.append({"label": "增幅", "value": _value_text(chip_now), "sub": "等级%d · 满级 %s" % [item_level, _value_text(chip_max)]})
		"pets":
			stats.append({"label": "定位", "value": _role_name(row.get("role", "-")), "sub": _element_name(row.get("element", "none"))})
			var pet_skill: Dictionary = row.get("pet_skill", {})
			if not pet_skill.is_empty():
				stats.append({
					"label": str(pet_skill.get("name", "专属技能")),
					"value": _pet_skill_summary(row, item_level),
					"sub": _pet_skill_cooldown_text(pet_skill)
				})
			if row.has("damage"):
				var pet_g := float(row.get("level_damage_growth", 0.0))
				var pet_now := float(row.get("damage", 0)) * (1.0 + pet_g * float(max(item_level - 1, 0)))
				var pet_max := float(row.get("damage", 0)) * (1.0 + pet_g * float(max(max_level - 1, 0)))
				stats.append({"label": "伤害", "value": "%d" % int(round(pet_now)), "sub": "等级%d · 满级 %d" % [item_level, int(round(pet_max))]})
			if row.has("fire_rate"):
				stats.append({"label": "频率", "value": "%.1f / 秒" % float(row.get("fire_rate", 0.0)), "sub": "自动协战"})
			if row.has("heal_per_wave"):
				var wave_flat_now := float(row.get("heal_per_wave", 0.0)) * (1.0 + float(row.get("level_heal_growth", 0.0)) * float(max(item_level - 1, 0)))
				var wave_flat_max := float(row.get("heal_per_wave", 0.0)) * (1.0 + float(row.get("level_heal_growth", 0.0)) * float(max(max_level - 1, 0)))
				var wave_ratio_now := float(row.get("heal_per_wave_ratio", 0.0)) + float(row.get("level_wave_heal_ratio_growth", 0.0)) * float(max(item_level - 1, 0))
				var wave_ratio_max := float(row.get("heal_per_wave_ratio", 0.0)) + float(row.get("level_wave_heal_ratio_growth", 0.0)) * float(max(max_level - 1, 0))
				stats.append({"label": "波次整备", "value": "%d + %.1f%%" % [int(round(wave_flat_now)), wave_ratio_now * 100.0], "sub": "满级 %d + %.1f%%" % [int(round(wave_flat_max)), wave_ratio_max * 100.0]})
			if row.has("repair_ratio"):
				var repair_now := float(row.get("repair_ratio", 0.0)) + float(row.get("level_repair_ratio_growth", 0.0)) * float(max(item_level - 1, 0))
				var repair_max := float(row.get("repair_ratio", 0.0)) + float(row.get("level_repair_ratio_growth", 0.0)) * float(max(max_level - 1, 0))
				stats.append({"label": "持续维修", "value": "%.2f%% / %.0f秒" % [repair_now * 100.0, float(row.get("repair_interval", 18.0))], "sub": "满级 %.2f%%" % (repair_max * 100.0)})
			if row.has("emergency_heal_ratio"):
				var emergency_now := float(row.get("emergency_heal_ratio", 0.0)) + float(row.get("level_emergency_heal_growth", 0.0)) * float(max(item_level - 1, 0))
				var emergency_max := float(row.get("emergency_heal_ratio", 0.0)) + float(row.get("level_emergency_heal_growth", 0.0)) * float(max(max_level - 1, 0))
				stats.append({"label": "应急救援", "value": "%.1f%% · ≤%.0f%%" % [emergency_now * 100.0, float(row.get("emergency_threshold", 0.35)) * 100.0], "sub": "%.0f秒冷却 · 满级 %.1f%%" % [float(row.get("emergency_cooldown", 45.0)), emergency_max * 100.0]})
			if row.has("gold_mult"):
				stats.append({"label": "收益", "value": _value_text(row.get("gold_mult", 0)), "sub": "每级 +%s" % _value_text(row.get("level_gold_growth", 0))})
			for bonus in _pet_stat_bonus_stats(row, item_level, max_level):
				stats.append(bonus)
		"skills":
			var levels: Array = row.get("levels", [])
			stats.append({"label": "类型", "value": _kind_name(str(row.get("kind", "passive"))), "sub": _format_tags(row.get("card_tags", []))})
			stats.append({"label": "当前", "value": "%d / %d" % [item_level, levels.size()], "sub": "永久技能等级"})
			stats.append({"label": "上限", "value": "等级%d" % levels.size(), "sub": "逐级叠加"})
	return stats

func _projectile_type_name(projectile_type: String) -> String:
	match projectile_type:
		"bullet":
			return _loc("常规弹", "Ballistic Rounds")
		"flame":
			return _loc("火焰喷流", "Flame Stream")
		"ice_bolt":
			return _loc("寒冰弹", "Frost Bolt")
		"chain":
			return _loc("连锁电弧", "Chain Arc")
		"lob":
			return _loc("抛射毒弹", "Toxic Lob")
		"rail":
			return _loc("磁轨弹", "Rail Shot")
		"pellet":
			return _loc("散射弹丸", "Pellets")
		"plasma":
			return _loc("等离子体", "Plasma Bolt")
		"apocalypse_chain":
			return _loc("终焉连锁", "Apocalypse Chain")
		"apocalypse_inferno_stream":
			return _loc("炼狱火流", "Inferno Stream")
		"apocalypse_absolute_zero_bolt":
			return _loc("绝对零度弹", "Absolute Zero Bolt")
		"apocalypse_golden_law_verdict":
			return _loc("黄金裁决弹", "Golden Verdict")
		_:
			return _loc("弹道", "Projectile")

func _pet_stat_bonus_stats(row: Dictionary, item_level: int, max_level: int) -> Array:
	var stats := []
	var base_map: Dictionary = row.get("stat_bonus", {})
	if base_map.is_empty():
		return stats
	var growth_map: Dictionary = row.get("level_stat_growth", {})
	for stat in base_map.keys():
		var base := float(base_map.get(stat, 0.0))
		var growth := float(growth_map.get(stat, 0.0))
		var now := base + growth * float(max(item_level - 1, 0))
		var max_value := base + growth * float(max(max_level - 1, 0))
		stats.append({
			"label": _pet_stat_name(str(stat)),
			"value": _pet_stat_value_text(str(stat), now),
			"sub": "等级%d · 满级 %s" % [item_level, _pet_stat_value_text(str(stat), max_value)]
		})
	return stats

func _pet_stat_name(stat: String) -> String:
	match stat:
		"damage_mult":
			return "主炮伤害"
		"fire_rate_mult":
			return "射速"
		"element_damage_mult":
			return "元素增伤"
		"crit_rate":
			return "暴击"
		"slow_strength_mult":
			return "减速"
		"base_hp_mult":
			return "生命"
		"breach_damage_reduction":
			return "防线减伤"
		"chain_bonus":
			return "连锁"
		"pierce_bonus":
			return "穿透"
		"gold_mult":
			return "金币"
		_:
			return stat

func _pet_stat_value_text(stat: String, value: float) -> String:
	match stat:
		"chain_bonus", "pierce_bonus":
			return "+%d" % int(round(value))
		"crit_rate", "damage_mult", "fire_rate_mult", "element_damage_mult", "slow_strength_mult", "base_hp_mult", "breach_damage_reduction", "gold_mult":
			return "+%d%%" % int(round(value * 100.0))
		_:
			return _value_text(value)

func _pet_skill_summary(row: Dictionary, level: int) -> String:
	var skill: Dictionary = row.get("pet_skill", {})
	var offset := float(max(level - 1, 0))
	match str(skill.get("kind", "")):
		"overclock":
			var duration := float(skill.get("duration", 0.0)) + float(skill.get("level_duration_growth", 0.0)) * offset
			var fire_rate := float(skill.get("fire_rate_mult", 1.0)) + float(skill.get("level_fire_rate_growth", 0.0)) * offset
			var damage := float(skill.get("damage_mult", 1.0)) + float(skill.get("level_damage_mult_growth", 0.0)) * offset
			return "%.1f秒 · 射速×%.2f · 伤害×%.2f" % [duration, fire_rate, damage]
		"area_blast":
			var radius := float(skill.get("radius", 0.0)) + float(skill.get("level_radius_growth", 0.0)) * offset
			var area_damage := float(skill.get("damage_mult", 1.0)) + float(skill.get("level_damage_mult_growth", 0.0)) * offset
			return "半径%d · 威力×%.2f" % [int(round(radius)), area_damage]
		"multi_strike":
			var every := maxi(1, int(skill.get("extra_target_every", 10)))
			var count := int(skill.get("target_count", 1)) + int(max(level - 1, 0) / every)
			var strike_damage := float(skill.get("damage_mult", 1.0)) + float(skill.get("level_damage_mult_growth", 0.0)) * offset
			return "%d目标 · 威力×%.2f" % [count, strike_damage]
		"repair":
			return "整备 · 持续维修 · 应急救援"
		"wave_salvage":
			var equivalent := float(skill.get("kill_equivalent", 0.0)) + float(skill.get("level_salvage_growth", 0.0)) * offset
			return "每波≈%.1f只击杀收益" % equivalent
		_:
			return "自动触发"

func _pet_skill_cooldown_text(skill: Dictionary) -> String:
	var kind := str(skill.get("kind", ""))
	if kind == "wave_salvage":
		return "每波触发"
	if kind == "repair":
		return "分层自动触发"
	return "%.0f秒冷却" % float(skill.get("cooldown", 0.0))

func _detail_body_text(item_id: String, row: Dictionary) -> String:
	match mode:
		"weapons":
			return _weapon_tactical_guide(item_id, row)
		"armors":
			return _armor_tactical_guide(row)
		"chips":
			return _chip_tactical_guide(row)
		"pets":
			return _pet_tactical_guide(row)
		"skills":
			return "技能图鉴只用于查看局内卡牌成长。下方会列出每一级的具体数值，便于判断加点性价比；战斗中同名技能按等级叠加，互斥弹种会以当前主弹种为准。"
		_:
			return _item_desc(item_id, row, true)

func _weapon_tactical_guide(item_id: String, row: Dictionary) -> String:
	var fire_rate := float(row.get("fire_rate", 0.0))
	var projectile_type := str(row.get("projectile_type", "bullet"))
	var item_level := SaveManager.get_item_level(item_id)
	var position := _loc(
		"%s属性 · %s；基础射速 %.2f 发/秒，属于%s。",
		"%s · %s; base fire rate %.2f rounds/sec, a %s weapon."
	) % [
		LocalizationManager.text(_element_name(str(row.get("element", "physical")))),
		_projectile_type_name(projectile_type),
		fire_rate,
		_weapon_cadence_name(fire_rate),
	]
	var standard_cap := SaveManager.weapon_standard_growth_cap_from_row(row)
	var growth := _loc(
		"1-%d级每级提高单发伤害 8%%、射速 2.5%%。",
		"Levels 1-%d add 8%% shot damage and 2.5%% fire rate per level."
	) % standard_cap
	var segments: Array = row.get("level_growth_segments", [])
	if not segments.is_empty():
		var segment: Dictionary = segments[0] if segments[0] is Dictionary else {}
		growth += _loc(
			" %d-%d级为独享延伸段，每级继续增加 %.1f%% 伤害，基础射速成长停在前段上限。",
			" Levels %d-%d are an exclusive extension, adding %.1f%% damage per level while base fire-rate growth stays capped at the earlier tier."
		) % [int(segment.get("from_level", standard_cap + 1)), int(segment.get("to_level", row.get("max_level", standard_cap))), float(segment.get("atk_growth_per_level", 0.08)) * 100.0]
	var special: Dictionary = row.get("special", {})
	var pellet_growth_var: Variant = special.get("pellet_growth", [])
	var pellet_growth: Array = pellet_growth_var if pellet_growth_var is Array else []
	if not pellet_growth.is_empty():
		var pellet_steps: Array[String] = []
		for step_var in pellet_growth:
			var step: Dictionary = step_var if step_var is Dictionary else {}
			pellet_steps.append(_loc("Lv%d 为 %d 枚", "Lv%d: %d pellets") % [int(step.get("from_level", 1)), int(step.get("pellets", 1))])
		growth += _loc(" 散弹阶梯：%s。", " Pellet progression: %s.") % " / ".join(pellet_steps)
	return _tactical_guide_text(
		_loc("属性与定位", "Role & Attribute"), position,
		_loc("核心特性", "Core Traits"), _weapon_feature_text(row, item_level),
		_loc("成长方式", "Growth"), growth,
		_loc("使用建议", "How to Use"), _weapon_usage_text(projectile_type)
	)

func _weapon_cadence_name(fire_rate: float) -> String:
	if fire_rate >= 5.0:
		return _loc("高速持续输出", "rapid sustained-fire")
	if fire_rate >= 4.0:
		return _loc("偏高射速持续输出", "fast sustained-fire")
	if fire_rate >= 3.0:
		return _loc("均衡射速", "balanced-cadence")
	return _loc("低射速重击", "slow, heavy-hitting")

func _weapon_feature_text(row: Dictionary, item_level := 1) -> String:
	var special: Dictionary = row.get("special", {})
	var features: Array[String] = []
	if int(special.get("pellets", 0)) > 0:
		var current_pellets := SaveManager.weapon_pellet_count_from_row(row, item_level)
		var max_pellets := int(special.get("pellets", current_pellets))
		var pellet_text := _loc(
			"当前每次发射 %d 枚散弹，以 %d° 扇面覆盖多个目标",
			"Currently fires %d pellets across a %d° fan to cover multiple targets"
		) % [current_pellets, int(special.get("spread", 0))]
		if current_pellets < max_pellets:
			pellet_text += _loc("；满级成长至 %d 枚", "; grows to %d at max level") % max_pellets
		pellet_text += _loc("；可与多重射击和角色齐射叠加", "; stacks with Multishot and character barrages")
		features.append(pellet_text)
	elif int(special.get("chain", 0)) > 0:
		var chain_text := _loc(
			"命中后额外连锁 %d 个目标",
			"Chains to %d additional targets after the first hit"
		) % int(special.get("chain", 0))
		if special.has("chain_falloff"):
			chain_text += _loc(
				"，每跳保留 %.0f%% 伤害",
				", retaining %.0f%% damage per jump"
			) % (float(special.get("chain_falloff", 1.0)) * 100.0)
		features.append(chain_text)
	if int(special.get("pellets", 0)) <= 0 and float(special.get("spread", 0.0)) > 0.0:
		features.append(_loc("弹道具有 %d° 扩散范围", "Projectiles use a %d° spread") % int(special.get("spread", 0)))
	if int(special.get("pierce", 0)) > 0:
		features.append(_loc(
			"弹体自带穿透 +%d，可沿直线贯穿敌群",
			"Built-in +%d pierce lets each shot pass through a line of enemies"
		) % int(special.get("pierce", 0)))
	if float(special.get("splash", 0.0)) > 0.0:
		features.append(_loc("命中产生 %d 范围爆炸", "Impact creates an explosion with %d radius") % int(special.get("splash", 0)))
	if float(special.get("cloud", 0.0)) > 0.0:
		features.append(_loc(
			"抛射命中留下 %d 范围毒云，并施加 %.0f%% 毒素效果",
			"Lobbed hits leave a %d-radius toxic cloud with a %.0f%% poison effect"
		) % [int(special.get("cloud", 0)), float(special.get("poison", 0.0)) * 100.0])
	var burn_ratio := float(special.get("burn", special.get("burn_ratio", 0.0)))
	if burn_ratio > 0.0:
		features.append(_loc("持续命中会施加 %.0f%% 灼烧", "Sustained hits apply a %.0f%% burn") % (burn_ratio * 100.0))
	if float(special.get("slow", 0.0)) > 0.0:
		features.append(_loc("命中施加 %.0f%% 减速", "Hits apply a %.0f%% slow") % (float(special.get("slow", 0.0)) * 100.0))
	if int(special.get("overload_hits", 0)) > 0:
		features.append(_loc(
			"累计 %d 次命中触发 %.2f× 过载打击",
			"Every %d accumulated hits trigger a %.2f× Overload strike"
		) % [int(special.get("overload_hits", 0)), float(special.get("overload_damage_mult", 1.0))])
	if int(special.get("combustion_max_stacks", 0)) > 0:
		features.append(_loc(
			"灼烧叠至 %d 层触发燃爆扩散，最多波及 %d 个目标",
			"At %d burn stacks, Combustion spreads to as many as %d targets"
		) % [int(special.get("combustion_max_stacks", 0)), int(special.get("combustion_max_targets", 0))])
	if int(special.get("high_heat_shots", 0)) > 0:
		features.append(_loc(
			"每 %d 发高热射击后进入 %d 发散热节奏",
			"Cycles through %d high-heat shots followed by %d venting shots"
		) % [int(special.get("high_heat_shots", 0)), int(special.get("vent_shots", 0))])
	if int(special.get("brittle_hits", 0)) > 0:
		features.append(_loc(
			"累计 %d 次命中触发碎冰连爆，最多波及 %d 个目标",
			"Every %d hits trigger a Shatter burst against as many as %d targets"
		) % [int(special.get("brittle_hits", 0)), int(special.get("shatter_max_targets", 0))])
	if int(special.get("judgment_hits", 0)) > 0:
		features.append(_loc(
			"累计 %d 次命中降下裁决，造成 %.2f× 伤害并穿透 %.0f%% 护甲",
			"Every %d hits invoke Judgment for %.2f× damage with %.0f%% armor penetration"
		) % [int(special.get("judgment_hits", 0)), float(special.get("judgment_damage_mult", 1.0)), float(special.get("judgment_armor_penetration", 0.0)) * 100.0])
	if features.is_empty():
		features.append(_loc("稳定单发弹道，没有额外扩散或触发条件", "Stable single-shot ballistics with no spread or trigger condition"))
	return _loc("；", "; ").join(features) + _loc("。", ".")

func _weapon_usage_text(projectile_type: String) -> String:
	match projectile_type:
		"flame", "apocalypse_inferno_stream":
			return _loc("持续压住密集尸群，让灼烧与燃爆充分叠加；频繁切换孤立目标会损失持续命中收益。", "Hold fire on dense groups so Burn and Combustion can build; frequent swaps between isolated targets waste sustained-hit value.")
		"ice_bolt", "apocalypse_absolute_zero_bolt":
			return _loc("优先控制最接近防线或移动最快的敌人，让减速与碎冰为整条防线争取时间。", "Prioritize the closest or fastest enemies so Slow and Shatter buy time for the entire defense.")
		"chain", "apocalypse_chain":
			return _loc("优先瞄准尸群前排或中央目标，让电弧向周围扩散；面对孤立目标时连锁收益较低。", "Aim at the front or center of a group so arcs can spread; chain value drops against isolated targets.")
		"lob":
			return _loc("把毒云落在敌群汇合处或行进路线前方，利用持续覆盖清理密集目标。", "Place toxic clouds where groups converge or along their path to maximize lingering coverage.")
		"rail", "apocalypse_golden_law_verdict":
			return _loc("让瞄准线穿过尽可能多的敌人；对纵向密集队列和高甲目标收益最高。", "Line up as many enemies as possible; it excels against packed columns and armored targets.")
		"pellet":
			return _loc("将扇面中心压在密集尸群上，使弹丸分摊到更多目标；对单体时让更多弹丸汇聚于同一目标。", "Center the fan on dense groups to spread pellets; against one target, keep the fan centered so more pellets converge.")
		"plasma":
			return _loc("优先射击敌群中心，利用命中爆炸同时削减周围目标；不适合把爆炸浪费在孤立边缘单位上。", "Shoot into the center of groups so each impact damages nearby enemies; avoid wasting explosions on isolated edge targets.")
		_:
			return _loc("作为稳定通用主武器，持续锁定最接近防线的威胁；再用弹药卡补足关卡元素克制。", "Use it as a stable general-purpose weapon, focusing the closest threat and adding ammo cards for the level's elemental matchup.")

func _armor_tactical_guide(row: Dictionary) -> String:
	var resist := str(row.get("resist", "none"))
	var position := _loc("基地生命倍率 %.0f%%；%s。", "%.0f%% base-HP multiplier; %s.") % [float(row.get("hp_mult", 1.0)) * 100.0, _armor_resist_text(resist)]
	var traits: Array[String] = []
	var shield_count := int(row.get("breach_shield", 0))
	if shield_count > 0:
		traits.append(_loc("开局提供 %d 层防线屏障，可抵消同等次数的防线突破", "Starts with %d barrier charge(s), negating that many breaches") % shield_count)
	if int(row.get("counter_charge_hits", 0)) > 0:
		var counter := _loc(
			"累计承受 %d 次防线受击后发动 %.1f× 反击，冷却 %.1f 秒",
			"After %d defense hits, launches a %.1f× counterattack on a %.1f-second cooldown"
		) % [int(row.get("counter_charge_hits", 0)), float(row.get("counter_damage_mult", 1.0)), float(row.get("counter_cooldown", 0.0))]
		if float(row.get("counter_restore_ratio", 0.0)) > 0.0:
			counter += _loc("，并修复 %.1f%% 最大生命", ", restoring %.1f%% max HP") % (float(row.get("counter_restore_ratio", 0.0)) * 100.0)
		if float(row.get("counter_slow", 0.0)) > 0.0:
			counter += _loc("、施加 %.0f%% 减速", " and applying a %.0f%% slow") % (float(row.get("counter_slow", 0.0)) * 100.0)
		if int(row.get("counter_radius", 0)) > 0:
			counter += _loc(
				"，覆盖 %d 范围内最多 %d 个目标",
			" within %d radius across as many as %d targets"
			) % [int(row.get("counter_radius", 0)), int(row.get("counter_max_targets", 0))]
		traits.append(counter)
	if traits.is_empty():
		traits.append(_loc("以生命与定向抗性提供稳定、常驻的防线容错", "Provides steady, always-on defense through HP and focused resistance"))
	var growth := _loc(
		"最高 %d 级；每级按基础生命倍率继续增加 %.1f%% 生命。",
		"Up to level %d; each level adds %.1f%% HP from the armor's base multiplier."
	) % [int(row.get("max_level", 35)), float(row.get("level_hp_growth", 0.0)) * 100.0]
	if float(row.get("endgame_hp_growth_bonus", 0.0)) > 0.0:
		growth += _loc(" 高等级还会获得额外终局生命成长。", " High levels also gain additional endgame HP growth.")
	return _tactical_guide_text(
		_loc("防护定位", "Defense Profile"), position,
		_loc("核心特性", "Core Traits"), _loc("；", "; ").join(traits) + _loc("。", "."),
		_loc("成长方式", "Growth"), growth,
		_loc("使用建议", "How to Use"), _armor_usage_text(row)
	)

func _armor_resist_text(resist: String) -> String:
	if resist in ["", "none"]:
		return _loc("不限定元素抗性，侧重通用生存", "no fixed elemental resistance, focused on general survival")
	return _loc("重点抵抗%s伤害", "focused resistance to %s damage") % LocalizationManager.text(_element_name(resist))

func _armor_usage_text(row: Dictionary) -> String:
	var resist := str(row.get("resist", "none"))
	if float(row.get("counter_slow", 0.0)) > 0.0:
		return _loc("用于冰霜高压关和近线尸群；反击蓄满后同时控场、反伤和修复，但屏障仍应留给真正的突破。", "Use in frost-heavy stages and close-line swarms; a charged counter controls, retaliates, and repairs, but barrier charges should still be saved for real breaches.")
	if float(row.get("counter_restore_ratio", 0.0)) > 0.0:
		return _loc("适合持续承压的长战斗；反击兼具清线与修复，避免把屏障浪费在可安全击杀的零散敌人上。", "Best in long fights under sustained pressure; its counter clears and repairs, so avoid wasting barriers on stragglers that can be killed safely.")
	if int(row.get("counter_charge_hits", 0)) > 0:
		return _loc("面对对应属性和高频防线受击时价值最高；让反击承担清线，但不要主动放任敌人突破来充能。", "Best against its matching damage type and frequent defense hits; let the counter help clear, but never allow breaches just to charge it.")
	if int(row.get("breach_shield", 0)) > 0:
		return _loc("适合属性混杂或未知威胁，靠通用生命与屏障兜底；用于容错，不替代及时清理近线敌人。", "Use against mixed or unknown threats for broad HP and barrier insurance; it adds forgiveness but does not replace clearing enemies near the line.")
	return _loc(
		"在%s敌人为主的章节使用，能把有限的护甲位转化为更稳定的有效生命；混合属性关则需权衡覆盖率。",
		"Equip it when %s enemies dominate to turn the armor slot into more effective HP; weigh its coverage in mixed-element stages."
	) % LocalizationManager.text(_element_name(resist))

func _chip_tactical_guide(row: Dictionary) -> String:
	var stat := str(row.get("stat", "damage_mult"))
	var value := float(row.get("value", 0.0))
	var position := _loc(
		"主属性为%s，1级提供 %s；这是常驻加成，会进入实际战斗计算。",
		"Primary stat: %s, granting %s at level 1; this always-on bonus is used in live combat."
	) % [_tactical_stat_name(stat), _tactical_stat_value(stat, value)]
	var secondary: Dictionary = row.get("secondary_stats", {})
	var traits := _loc("没有附加触发条件，效果始终生效。", "No trigger condition; its effect is always active.")
	if not secondary.is_empty():
		var feature_parts: Array[String] = []
		for secondary_stat in secondary.keys():
			feature_parts.append(_chip_secondary_feature(str(secondary_stat), float(secondary.get(secondary_stat, 0.0))))
		traits = _loc("同时强化", "Also improves ") + _loc("、", ", ").join(feature_parts) + _loc("。", ".")
	var level_growth := float(row.get("level_value_growth", 0.0))
	var growth := _loc("最高 %d 级；主属性每级按基础值成长 %.1f%%。", "Up to level %d; the primary stat grows by %.1f%% of its base value per level.") % [int(row.get("max_level", 35)), level_growth * 100.0]
	if is_zero_approx(level_growth):
		growth = _loc("最高 %d 级；主属性固定为 %s，不随等级按百分比膨胀。", "Up to level %d; the primary %s bonus is fixed rather than percentage-scaled by level.") % [int(row.get("max_level", 20)), _tactical_stat_value(stat, value)]
	if not row.get("secondary_level_growth", {}).is_empty():
		growth += _loc(" 附加机制也会随等级同步增强。", " Its secondary mechanics also improve with level.")
	return _tactical_guide_text(
		_loc("芯片定位", "Chip Profile"), position,
		_loc("核心特性", "Core Traits"), traits,
		_loc("成长方式", "Growth"), growth,
		_loc("使用建议", "How to Use"), _chip_usage_text(stat, secondary)
	)

func _tactical_stat_name(stat: String) -> String:
	match stat:
		"damage_mult": return _loc("主炮伤害", "weapon damage")
		"fire_rate_mult": return _loc("主炮射速", "weapon fire rate")
		"crit_rate": return _loc("暴击率", "critical chance")
		"pierce_bonus": return _loc("弹道穿透", "projectile pierce")
		"base_hp_mult": return _loc("基地生命", "base HP")
		"breach_damage_reduction": return _loc("防线突破减伤", "breach damage reduction")
		"gold_mult": return _loc("金币收益", "gold income")
		"element_damage_mult": return _loc("元素伤害", "elemental damage")
		"slow_strength_mult": return _loc("减速强度", "slow strength")
		"chain_bonus": return _loc("连锁目标", "chain targets")
		"armor_penetration": return _loc("护甲穿透", "armor penetration")
		_: return str(stat)

func _tactical_stat_value(stat: String, value: float) -> String:
	if stat in ["pierce_bonus", "chain_bonus"]:
		return "+%d" % int(round(value))
	return "+%.1f%%" % (value * 100.0)

func _chip_secondary_feature(stat: String, value: float) -> String:
	match stat:
		"chain_retention": return _loc("连锁衰减保留 +%.0f%%", "chain retention +%.0f%%") % (value * 100.0)
		"overload_efficiency": return _loc("过载效率 +%.0f%%", "Overload efficiency +%.0f%%") % (value * 100.0)
		"burn_efficiency": return _loc("灼烧效率 +%.0f%%", "Burn efficiency +%.0f%%") % (value * 100.0)
		"combustion_stack_efficiency": return _loc("燃爆叠层效率 +%.0f%%", "Combustion stack efficiency +%.0f%%") % (value * 100.0)
		"combustion_damage_mult": return _loc("燃爆伤害 +%.0f%%", "Combustion damage +%.0f%%") % (value * 100.0)
		"brittle_efficiency": return _loc("脆化效率 +%.0f%%", "Brittle efficiency +%.0f%%") % (value * 100.0)
		"shatter_damage_mult": return _loc("碎冰伤害 +%.0f%%", "Shatter damage +%.0f%%") % (value * 100.0)
		"judgment_efficiency": return _loc("裁决效率 +%.0f%%", "Judgment efficiency +%.0f%%") % (value * 100.0)
		"verdict_damage_mult": return _loc("裁决伤害 +%.0f%%", "Verdict damage +%.0f%%") % (value * 100.0)
		_: return "%s %s" % [_tactical_stat_name(stat), _tactical_stat_value(stat, value)]

func _chip_usage_text(stat: String, secondary: Dictionary) -> String:
	if secondary.has("overload_efficiency"):
		return _loc("与雷霆连锁和过载机制配套，尸群越密集越能同时兑现元素、连锁和射速收益。", "Pair with Thunder chain and Overload mechanics; denser groups let its elemental, chain, and fire-rate bonuses work together.")
	if secondary.has("combustion_stack_efficiency"):
		return _loc("与灼烧、燃爆和持续命中配套，优先用于能稳定叠层的火焰构筑。", "Pair with Burn, Combustion, and sustained hits; use it in fire builds that can stack reliably.")
	if secondary.has("brittle_efficiency"):
		return _loc("与减速、脆化和碎冰配套，适合用控制换取安全时间并清理密集目标。", "Pair with Slow, Brittle, and Shatter to trade control for safety and clear packed targets.")
	if secondary.has("judgment_efficiency"):
		return _loc("与物理暴击、穿透和裁决配套，对高甲目标及需要直线贯穿的关卡最有效。", "Pair with physical crit, pierce, and Judgment; strongest against armored targets and stages that reward lined-up shots.")
	match stat:
		"damage_mult": return _loc("没有构筑门槛，适合任何依赖主炮输出的阵容，也是最直接的通用增伤选择。", "No build requirement: use it in any weapon-damage loadout as the most direct general damage option.")
		"fire_rate_mult": return _loc("适合依赖命中次数、叠层或触发频率的武器；单发很重但射速低的武器提升体感尤其明显。", "Best for weapons that depend on hit count, stacking, or trigger frequency; it also smooths slow heavy weapons.")
		"crit_rate": return _loc("适合已有高单发伤害或暴击联动的构筑；伤害波动会增加，不提供控制或生存。", "Best with high shot damage or crit synergies; it raises variance and adds no control or survival.")
		"pierce_bonus": return _loc("用于纵向密集尸群，让一发弹道贯穿更多目标；对无法利用直线队列的单体战收益有限。", "Use against enemies packed in a line so each projectile hits more targets; limited value in isolated single-target fights.")
		"base_hp_mult": return _loc("在输出够用但容易漏怪时装备，提高基地容错；不会直接加快清怪速度。", "Equip when damage is adequate but leaks are costly; it improves base forgiveness without speeding up kills.")
		"breach_damage_reduction": return _loc("针对会频繁触线或造成高额防线伤害的章节，和高生命护甲搭配可进一步稳定防线。", "Use in stages with frequent breaches or heavy base damage; pairing it with high-HP armor further stabilizes the line.")
		"gold_mult": return _loc("用于压力可控的刷取与成长关；若当前关卡已经守不住，应先换回输出或生存芯片。", "Use for farming and progression when pressure is controlled; switch back to damage or defense if the stage is already unsafe.")
		"element_damage_mult": return _loc("在主武器、弹药卡或技能能稳定造成元素伤害时使用；纯物理且无元素转换时收益较低。", "Use when your weapon, ammo card, or skills reliably deal elemental damage; value is lower in a purely physical build without conversion.")
		_: return _loc("围绕它的主属性选择阵容，让单一芯片位解决最明确的输出或生存短板。", "Build around its primary stat so the single chip slot addresses your clearest damage or survival gap.")

func _pet_tactical_guide(row: Dictionary) -> String:
	var skill: Dictionary = row.get("pet_skill", {})
	var has_attack := row.has("damage") and row.has("fire_rate")
	var position := ""
	if has_attack:
		position = _loc(
			"%s属性 · %s协战；基础攻击频率 %.2f 次/秒，并持续自动攻击。",
			"%s · %s support; attacks automatically at a base %.2f attacks/sec."
		) % [LocalizationManager.text(_element_name(str(row.get("element", "physical")))), LocalizationManager.text(_role_name(str(row.get("role", "damage")))), float(row.get("fire_rate", 0.0))]
	else:
		position = _loc("%s型非攻击宠物，重点提供常驻支援与自动功能。", "A non-attacking %s support pet focused on passive bonuses and automatic utility.") % LocalizationManager.text(_role_name(str(row.get("role", "repair"))))
	var skill_name := LocalizationManager.text(str(skill.get("name", _loc("专属协战", "Signature Support"))))
	var traits := "%s：%s" % [skill_name, _pet_skill_tactical_text(row)]
	var growth_parts: Array[String] = []
	if row.has("damage"):
		growth_parts.append(_loc("协战伤害每级 +%.1f%%", "support damage +%.1f%% per level") % (float(row.get("level_damage_growth", 0.0)) * 100.0))
	if row.has("heal_per_wave"):
		growth_parts.append(_loc("波次整备、持续维修与应急救援随等级增强", "wave prep, continuous repair, and emergency aid improve with level"))
	if row.has("gold_mult"):
		growth_parts.append(_loc("金币收益与战场回收效率随等级增强", "gold income and battlefield salvage improve with level"))
	if not row.get("level_stat_growth", {}).is_empty():
		growth_parts.append(_loc("常驻队伍加成同步成长", "passive team bonuses scale alongside it"))
	var growth := _loc("最高 %d 级；", "Up to level %d; ") % int(row.get("max_level", 30))
	growth += _loc("，", ", ").join(growth_parts) + _loc("。", ".")
	return _tactical_guide_text(
		_loc("协战定位", "Support Role"), position,
		_loc("专属机制", "Signature Mechanic"), traits,
		_loc("成长方式", "Growth"), growth,
		_loc("使用建议", "How to Use"), _pet_usage_text(row)
	)

func _pet_skill_tactical_text(row: Dictionary) -> String:
	var skill: Dictionary = row.get("pet_skill", {})
	match str(skill.get("kind", "")):
		"overclock":
			return _loc("每 %.0f 秒启动一次，持续 %.1f 秒，同时提高自身射速和伤害。", "Triggers every %.0f seconds for %.1f seconds, boosting its own fire rate and damage.") % [float(skill.get("cooldown", 0.0)), float(skill.get("duration", 0.0))]
		"area_blast":
			return _loc("每 %.0f 秒以当前高威胁目标为中心发动 %d 范围爆发，并强化对应元素状态。", "Every %.0f seconds, blasts a %d-radius area around the current high-priority target and strengthens its elemental status.") % [float(skill.get("cooldown", 0.0)), int(skill.get("radius", 0))]
		"multi_strike":
			return _loc("每 %.0f 秒同时打击 %d 个高威胁目标；每提升 %d 级再增加目标数。", "Every %.0f seconds, strikes %d high-priority targets; target count rises every %d levels.") % [float(skill.get("cooldown", 0.0)), int(skill.get("target_count", 1)), int(skill.get("extra_target_every", 10))]
		"repair":
			return _loc("每波开始整备，战斗中定时维修；基地低于 %.0f%% 生命时还会触发有冷却的应急救援。", "Prepares at each wave, repairs periodically during combat, and triggers a cooldown-limited emergency heal below %.0f%% base HP.") % (float(row.get("emergency_threshold", 0.35)) * 100.0)
		"wave_salvage":
			return _loc("每波自动结算约 %.1f 只敌人的等效击杀收益，同时提高常规金币获取。", "Each wave automatically grants roughly %.1f enemies' worth of kill income while also raising normal gold gain.") % float(skill.get("kill_equivalent", 0.0))
		"fire_flyby":
			return _loc("每 %.1f 秒俯冲打击 %d 个目标，并留下最多 %d 片持续 %.1f 秒的燃烧轨迹。", "Every %.1f seconds, dives across %d targets and leaves up to %d burning trails for %.1f seconds.") % [float(skill.get("cooldown", 0.0)), int(skill.get("target_count", 1)), int(skill.get("trail_max_concurrent", 1)), float(skill.get("trail_duration", 0.0))]
		"golden_mark":
			return _loc("每 %.1f 秒标记高威胁目标 %.1f 秒，使其额外承伤 %.0f%%，并修复 %.1f%% 基地生命。", "Every %.1f seconds, marks a high-priority target for %.1f seconds, increasing damage taken by %.0f%% and repairing %.1f%% base HP.") % [float(skill.get("cooldown", 0.0)), float(skill.get("mark_duration", 0.0)), float(skill.get("mark_damage_amp", 0.0)) * 100.0, float(skill.get("repair_ratio", 0.0)) * 100.0]
		_:
			return _loc("自动寻找合适时机触发，补足当前阵容的输出或生存短板。", "Triggers automatically when useful to cover the loadout's damage or survival gap.")

func _pet_usage_text(row: Dictionary) -> String:
	var kind := str(row.get("pet_skill", {}).get("kind", ""))
	match kind:
		"repair": return _loc("适合输出已经够用、但容易在漏怪或爆发波次中失守的阵容；它不攻击，价值全部来自保线。", "Use when damage is sufficient but leaks or burst waves threaten the base; it does not attack, so all value comes from keeping the line alive.")
		"wave_salvage": return _loc("用于压力可控的成长与刷取关；高压关若缺输出或控制，应换成对应协战宠物。", "Use in manageable farming and progression stages; swap to combat support when high-pressure stages need damage or control.")
		"overclock": return _loc("通用持续输出选择，适合补稳定火力；与射速、主炮伤害加成组合时收益更直观。", "A general sustained-damage pick that adds reliable firepower, especially alongside fire-rate and weapon-damage bonuses.")
		"area_blast": return _loc("让它的范围技能覆盖密集尸群；冰霜版本偏控线，火焰版本偏范围伤害与状态叠加。", "Keep its area skill centered on dense groups; frost variants favor control, while fire variants favor area damage and status buildup.")
		"multi_strike": return _loc("适合同时出现多个高威胁目标的波次，目标越分散，自动多目标打击越能避免主炮来回切换。", "Best when several threats appear at once; its automatic multi-target strikes reduce the need for the main weapon to keep switching.")
		"fire_flyby": return _loc("用于密集长波次，让俯冲与燃烧轨迹持续覆盖敌人行进路线；孤立单体不能充分利用轨迹。", "Use in long, dense waves so dives and burning trails cover enemy paths; isolated targets cannot fully exploit the trails.")
		"golden_mark": return _loc("优先放大 Boss 或高甲精英承伤，同时提供少量修复；适合需要集中火力处理关键目标的阵容。", "Use to amplify damage against bosses or armored elites while adding a small repair; ideal for loadouts focused on priority targets.")
		_: return _loc("根据它提供的常驻加成补足阵容短板，并让自动技能承担主炮不擅长的目标类型。", "Use its passive bonuses to cover a loadout gap and let its automatic skill handle targets the main weapon struggles with.")

func _tactical_guide_text(label_a: String, body_a: String, label_b: String, body_b: String, label_c: String, body_c: String, label_d: String, body_d: String) -> String:
	return "%s：%s\n%s：%s\n%s：%s\n%s：%s" % [label_a, body_a, label_b, body_b, label_c, body_c, label_d, body_d]

func _make_skill_levels_section(row: Dictionary, accent: Color, current_level: int) -> PanelContainer:
	var section := _make_section_panel("各级加成", accent, SKILL_DETAIL_SECTION_TITLE_FONT_SIZE)
	section.name = "SkillLevelsSection"
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.get_child(0).add_child(list)
	for level in row.get("levels", []):
		var lv := int(level.get("lv", list.get_child_count() + 1))
		var effect: Dictionary = level.get("effect", {})
		list.add_child(_make_skill_level_row(lv, SkillEffectText.format_effect(effect), accent, current_level))
	return section

func _make_skill_level_row(level: int, effect_text: String, accent: Color, current_level: int) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.name = "SkillLevel%d" % level
	pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pill.custom_minimum_size = Vector2(0, 64)
	var active := current_level >= level
	var border := Color(accent.r, accent.g, accent.b, 0.86 if active else 0.46)
	var fill := Color(0.038, 0.058, 0.074, 0.88) if active else Color(0.026, 0.036, 0.048, 0.68)
	pill.add_theme_stylebox_override("panel", _build_pill_style(border, fill))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pill.add_child(row)
	var level_label := Label.new()
	level_label.name = "Level"
	level_label.text = "等级%d" % level
	level_label.custom_minimum_size = Vector2(88, 0)
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", UiKit.bumped_font_size(SKILL_DETAIL_LEVEL_FONT_SIZE))
	level_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.56, 1.0) if active else Color(0.72, 0.82, 0.86, 0.88))
	level_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	level_label.add_theme_constant_override("outline_size", 2)
	row.add_child(level_label)
	var value_label := Label.new()
	value_label.name = "Effect"
	value_label.text = effect_text
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_label.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 1.0) if active else Color(0.72, 0.82, 0.86, 0.86))
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", UiKit.bumped_font_size(SKILL_DETAIL_EFFECT_FONT_SIZE))
	value_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
	value_label.add_theme_constant_override("outline_size", 1)
	row.add_child(value_label)
	return pill

func _select_item_and_close(slot: String, item_id: String) -> void:
	if SaveManager.select_item(slot, item_id):
		AudioManager.play_sfx("ui_confirm")
		_refresh()
	_close_character_detail()

func _upgrade_item_from_detail(item_id: String, row: Dictionary) -> void:
	var table := _data_table_name()
	if table != "" and SaveManager.upgrade_item(table, item_id):
		AudioManager.play_sfx("upgrade")
		_refresh()
		var fresh_row := DataLoader.get_row(table, item_id)
		_close_character_detail()
		call_deferred("_show_item_detail", item_id, fresh_row if not fresh_row.is_empty() else row)
	else:
		AudioManager.play_sfx("ui_click", -6.0)

func _upgrade_skill_from_detail(item_id: String, row: Dictionary) -> void:
	if SaveManager.upgrade_skill_base(item_id):
		AudioManager.play_sfx("upgrade")
		_refresh()
		_close_character_detail()
		call_deferred("_show_item_detail", item_id, row)
	else:
		AudioManager.play_sfx("ui_click", -6.0)

# ========== Character detail modal ==========

func _safe_area_canvas_insets() -> Vector4:
	return UiKit.safe_area_canvas_insets(get_viewport())

func _set_collection_content_visible(value: bool) -> void:
	(%ItemScroll as ScrollContainer).visible = value
	(%BackButton as TextureButton).visible = value

func _modal_dim_texture() -> GradientTexture2D:
	# A solid generated texture satisfies the production texture-backed UI
	# contract while keeping the modal backdrop opaque enough to suppress list
	# text beneath the intentionally translucent card artwork.
	var gradient := Gradient.new()
	var dim_color := Color(0.005, 0.008, 0.012, 0.90)
	gradient.colors = PackedColorArray([dim_color, dim_color])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 2
	texture.height = 2
	return texture

func _show_character_detail(item_id: String, row: Dictionary) -> void:
	_set_collection_content_visible(false)
	if _detail_modal != null and is_instance_valid(_detail_modal):
		_detail_modal.queue_free()
	_detail_modal = Control.new()
	_detail_modal.name = "CharacterDetail"
	_detail_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Character cards also own positive-z children; without an explicit modal
	# layer those children render over the detail panel on-device.
	_detail_modal.z_index = 64
	_detail_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	_detail_modal.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_detail_modal)
	# Dim background
	var dim := TextureRect.new()
	dim.texture = _modal_dim_texture()
	dim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dim.stretch_mode = TextureRect.STRETCH_SCALE
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_modal.add_child(dim)
	# === Outer panel: card with proper framing ===
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var safe := _safe_area_canvas_insets()
	# Keep the translated modal inside the bottom safe edge. The character
	# dialog only owns a 90px authored bottom gutter, so a taller-device shift
	# may never exceed that available gutter.
	var modal_shift := UiKit.tall_modal_shift(get_viewport_rect().size.y, 90.0, 0.30)
	# Match the item's safe-width modal contract. Native action-button models
	# stay untouched; only the outer authored gutter yields on narrow safe areas.
	panel.offset_left = 28.0 + safe.x
	panel.offset_top = 90.0 + safe.y + modal_shift
	panel.offset_right = -28.0 - safe.z
	panel.offset_bottom = -90.0 - safe.w + modal_shift
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_meta("safe_area_content", true)
	panel.add_theme_stylebox_override("panel", _build_panel_style())
	_detail_modal.add_child(panel)
	# Inner VBox — vertical sections
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# === HERO ROW: portrait + name/role + close ===
	var hero := HBoxContainer.new()
	hero.custom_minimum_size = Vector2(0, 230)
	hero.add_theme_constant_override("separation", 18)
	vbox.add_child(hero)
	# Portrait frame
	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(230, 230)
	portrait_frame.add_theme_stylebox_override("panel", _build_portrait_frame_style())
	hero.add_child(portrait_frame)
	var portrait := TextureRect.new()
	portrait.name = "PortraitClip"
	portrait.texture = null
	portrait.clip_contents = true
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.custom_minimum_size = Vector2(230, 230)
	portrait_frame.add_child(portrait)
	UiKit.add_character_bust(portrait, row, Vector2(230, 230), 320.0, CHARACTER_DETAIL_BUST_Y)
	# Name + role + tags column
	var name_col := VBoxContainer.new()
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_col.add_theme_constant_override("separation", 8)
	hero.add_child(name_col)
	var item_level := SaveManager.get_item_level(item_id)
	var selected := SaveManager.get_selected("character") == item_id
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 14)
	name_col.add_child(name_row)
	var name_label := Label.new()
	name_label.name = "CharacterName"
	name_label.text = DataLoader.tr_key(row.get("name_key", item_id))
	name_label.add_theme_font_size_override("font_size", UiKit.bumped_font_size(CHARACTER_DETAIL_NAME_FONT_SIZE))
	name_label.add_theme_color_override("font_color", Color(0.98, 0.99, 1, 1))
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	name_label.add_theme_constant_override("outline_size", 4)
	name_row.add_child(name_label)
	# Level badge
	var level_badge := PanelContainer.new()
	level_badge.add_theme_stylebox_override("panel", _build_level_badge_style())
	level_badge.custom_minimum_size = Vector2(112, 48)
	name_row.add_child(level_badge)
	var level_text := Label.new()
	level_text.name = "CharacterLevel"
	level_text.text = "等级%d" % item_level
	level_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_text.add_theme_font_size_override("font_size", UiKit.bumped_font_size(CHARACTER_DETAIL_LEVEL_FONT_SIZE))
	level_text.add_theme_color_override("font_color", Color(1, 0.92, 0.5, 1))
	level_badge.add_child(level_text)
	# Tag row: role + element
	var tag_row := HBoxContainer.new()
	tag_row.name = "CharacterMetadataTags"
	tag_row.add_theme_constant_override("separation", 10)
	name_col.add_child(tag_row)
	var role_tag := UiKit.semantic_tag_pill(LocalizationManager.text(_role_name(row.get("role_tag", "-"))), "kind", 16)
	role_tag.name = "CharacterRoleTag"
	tag_row.add_child(role_tag)
	var element_tag := UiKit.semantic_tag_pill(LocalizationManager.text(_element_name(row.get("element_focus", "-"))), "element", 16)
	element_tag.name = "CharacterElementTag"
	tag_row.add_child(element_tag)
	# Bullet affinity summary
	var affinity: Dictionary = row.get("bullet_affinity", {})
	if not affinity.is_empty():
		var affinity_text := _loc("弹种亲和 · ", "Ammo Affinity · ")
		var bonuses: Array[String] = []
		var elem := str(affinity.get("element", ""))
		if elem != "":
			bonuses.append(_loc("%s弹" % _element_name(elem), "%s Rounds" % LocalizationManager.text(_element_name(elem))))
		var dmg := float(affinity.get("damage_bonus", 0.0))
		if dmg > 0.0:
			bonuses.append(_loc("伤害 +%d%%", "Damage +%d%%") % int(dmg * 100))
		var pierce := int(affinity.get("pierce_bonus", 0))
		if pierce > 0:
			bonuses.append(_loc("穿透 +%d", "Piercing +%d") % pierce)
		var splash := float(affinity.get("splash_bonus", 0.0))
		if splash > 0.0:
			bonuses.append(_loc("爆燃 +%d", "Combustion +%d") % int(splash))
		if bonuses.size() > 0:
			affinity_text += "  ".join(bonuses)
			var affinity_label := Label.new()
			affinity_label.name = "AffinitySummary"
			affinity_label.text = affinity_text
			affinity_label.add_theme_font_size_override("font_size", UiKit.bumped_font_size(CHARACTER_DETAIL_AFFINITY_FONT_SIZE))
			affinity_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1, 0.95))
			affinity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			name_col.add_child(affinity_label)
	# Compact top-right close affordance; the bottom action row remains the primary close path.
	var close_btn := _compact_close_button("CloseButton")
	close_btn.pressed.connect(_close_character_detail)
	hero.add_child(close_btn)

	var content_scroll := ScrollContainer.new()
	content_scroll.name = "DetailScroll"
	content_scroll.scroll_deadzone = DETAIL_SCROLL_DEADZONE
	content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(content_scroll)
	var detail_content := VBoxContainer.new()
	detail_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_content.add_theme_constant_override("separation", 12)
	content_scroll.add_child(detail_content)

	# === BASE STATS section (cyan accent) ===
	var stats_section := _make_section_panel("基础属性", Color(0.58, 0.72, 0.82, 0.85), CHARACTER_DETAIL_SECTION_TITLE_FONT_SIZE)
	detail_content.add_child(stats_section)
	var stats_grid := GridContainer.new()
	stats_grid.columns = 3
	stats_grid.add_theme_constant_override("h_separation", 14)
	stats_grid.add_theme_constant_override("v_separation", 10)
	stats_section.get_child(0).add_child(stats_grid)
	stats_grid.add_child(_make_stat_pill("攻  击", str(int(row.get("base_atk", 0))), "+%.1f%% / 级" % (float(row.get("atk_growth", 0)) * 45.0), CHARACTER_DETAIL_SECOND_PASS_DELTA))
	stats_grid.add_child(_make_stat_pill("血  量", str(int(row.get("base_hp", 0))), "+%.1f%% / 级" % (float(row.get("hp_growth", 0)) * 45.0), CHARACTER_DETAIL_SECOND_PASS_DELTA))
	stats_grid.add_child(_make_stat_pill("暴  击", "%.0f%%" % (float(row.get("crit_rate_base", 0)) * 100.0), "", CHARACTER_DETAIL_SECOND_PASS_DELTA))
	stats_grid.add_child(_make_stat_pill("射  速", "%.2f×" % float(row.get("fire_rate_mod", 1.0)), "", CHARACTER_DETAIL_SECOND_PASS_DELTA))
	stats_grid.add_child(_make_stat_pill("瞄  准", "%.2f×" % float(row.get("aim_turn_speed", 1.0)), "", CHARACTER_DETAIL_SECOND_PASS_DELTA))
	# Empty 6th slot for grid alignment
	var filler := Label.new()
	filler.text = ""
	stats_grid.add_child(filler)

	# === 升级预览：本级 → 下级(角色此前一直缺失，只有武器/护甲/芯片/宠物有) ===
	var char_preview := _upgrade_preview_rows(item_id, row, item_level)
	if not char_preview.is_empty():
		var up_section := _make_section_panel("升级预览  (等级%d → %d)" % [item_level, item_level + 1], UiKit.GREEN, CHARACTER_DETAIL_SECTION_TITLE_FONT_SIZE)
		detail_content.add_child(up_section)
		var up_grid := GridContainer.new()
		up_grid.columns = 1
		up_grid.add_theme_constant_override("v_separation", 8)
		up_section.get_child(0).add_child(up_grid)
		for pr in char_preview:
			up_grid.add_child(_make_stat_pill(str(pr.get("label", "")), "%s → %s" % [str(pr.get("cur", "")), str(pr.get("next", ""))], str(pr.get("delta", "")), CHARACTER_DETAIL_SECOND_PASS_DELTA))

	# === PASSIVE section (green accent) ===
	var passive_id := str(row.get("passive", ""))
	var passive_info: Dictionary = CharacterSkillText.passive_info(passive_id)
	var passive_icon_path := "res://assets/production/sprites/ui/icon_element_%s.png" % str(row.get("element", "physical"))
	var passive_section := _make_section_panel("被  动", Color(0.48, 0.74, 0.50, 0.85), CHARACTER_DETAIL_SECTION_TITLE_FONT_SIZE)
	detail_content.add_child(passive_section)
	passive_section.get_child(0).add_child(_make_skill_row(
		passive_icon_path,
		passive_info["name"],
		"被动天赋",
		passive_info["desc"],
		UiKit.GREEN,
		passive_section
	))

	# === SIGNATURE SKILLS section (gold accent) ===
	var sig_section := _make_section_panel("专属技能", Color(0.92, 0.68, 0.34, 0.85), CHARACTER_DETAIL_SECTION_TITLE_FONT_SIZE)
	detail_content.add_child(sig_section)
	var sig_ids: Array = row.get("signature_skills", [])
	if sig_ids.is_empty():
		var empty := Label.new()
		empty.text = "（暂无）"
		empty.add_theme_font_size_override("font_size", UiKit.bumped_font_size(24))
		empty.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		sig_section.get_child(0).add_child(empty)
	else:
		var active_skill_id := str(row.get("active_skill", {}).get("id", ""))
		for sig_id in sig_ids:
			var info: Dictionary = CharacterSkillText.signature_info(sig_id)
			var is_active_skill: bool = (str(sig_id) == active_skill_id)
			var kind: String = "主动" if is_active_skill else "弹种"
			# Map sig id to icon
			var icon_path := "res://assets/production/sprites/ui/%s_icon.png" % sig_id
			if not ResourceLoader.exists(icon_path):
				icon_path = "res://assets/production/sprites/ui/icon_talent_point.png"
			sig_section.get_child(0).add_child(_make_skill_row(
				icon_path,
				info["name"],
				kind,
				info["desc"],
				UiKit.GOLD,
				sig_section
			))
			# 专属主动技独立经验升级(此前只能被动跟着角色等级涨，玩家没法针对性投资)。
			if is_active_skill:
				sig_section.get_child(0).add_child(_make_sig_skill_upgrade_row(item_id, active_skill_id))

	# === AFFINITY TAGS section ===
	var card_affinity: Array = row.get("card_affinity_tags", [])
	if not card_affinity.is_empty():
		var aff_section := _make_section_panel("流派倾向", Color(0.7, 0.7, 0.85, 0.7), CHARACTER_DETAIL_SECTION_TITLE_FONT_SIZE)
		detail_content.add_child(aff_section)
		var aff_row := HBoxContainer.new()
		aff_row.name = "AffinityTags"
		aff_row.add_theme_constant_override("separation", 8)
		aff_section.get_child(0).add_child(aff_row)
		var affinity_index := 0
		for affinity_tag in card_affinity:
			var affinity_pill := UiKit.semantic_tag_pill(LocalizationManager.text(_tag_name(str(affinity_tag))), "ability", 16)
			affinity_pill.name = "AffinityTag%d" % affinity_index
			aff_row.add_child(affinity_pill)
			affinity_index += 1

	# Keep the final growth line clear of both the scroll viewport edge and the
	# fixed 2x2 action row. The extra range also makes the last drag visibly move
	# instead of ending exactly where the label's descenders meet the frame.
	detail_content.add_child(_make_detail_scroll_bottom_clearance())
	content_scroll.mouse_force_pass_scroll_events = true
	_configure_detail_scroll_surface(detail_content)

	# === Action buttons row ===
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer)
	# Four native 236px buttons plus ornamental panel margins cannot fit inside
	# the 992px safe width of a tall iPhone. Preserve the approved button models
	# at their native size and use a centered 2x2 grid instead of shrinking or
	# stretching them.
	var action_row := GridContainer.new()
	action_row.columns = 2
	action_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	action_row.add_theme_constant_override("h_separation", 12)
	action_row.add_theme_constant_override("v_separation", 10)
	vbox.add_child(action_row)
	# 升级按钮(角色此前一直缺失，只有武器/护甲/芯片/宠物能升级)
	var char_can_upgrade := SaveManager.can_upgrade_item("characters", item_id)
	var char_upgrade_cost_spec := SaveManager.get_item_upgrade_cost_spec("characters", item_id)
	var char_upgrade_cost := int(char_upgrade_cost_spec.get("amount", 0))
	var char_max_level := int(row.get("max_level", 30))
	var upgrade_btn := _armored_action_button(
		"UpgradeButton",
		("已满级" if item_level >= char_max_level else _loc("升级", "Upgrade")),
		true,
		false,
		Vector2(236, 96),
		20
	)
	if item_level < char_max_level:
		UiKit.apply_resource_cost(upgrade_btn, _loc("升级", "Upgrade"), str(char_upgrade_cost_spec.get("kind", "gold")), char_upgrade_cost, 17, 26.0)
	upgrade_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	upgrade_btn.disabled = not char_can_upgrade
	upgrade_btn.modulate = ACTION_SECONDARY_MODULATE if char_can_upgrade else ACTION_DISABLED_MODULATE
	upgrade_btn.pressed.connect(_upgrade_item_from_detail.bind(item_id, row))
	action_row.add_child(upgrade_btn)
	var select_btn := _armored_action_button("SelectButton", "已装备" if selected else "选  定", true, true, Vector2(236, 96), 20)
	select_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	select_btn.disabled = selected
	select_btn.modulate = ACTION_DISABLED_MODULATE if selected else ACTION_ACTIVE_MODULATE
	select_btn.pressed.connect(_select_character_and_close.bind(item_id))
	action_row.add_child(select_btn)
	var appearance_btn := _armored_action_button("AppearanceButton", "外  观", true, false, Vector2(236, 96), 20)
	appearance_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	appearance_btn.pressed.connect(_open_character_appearance.bind(item_id))
	action_row.add_child(appearance_btn)
	var cancel_btn := _armored_action_button("CancelButton", "关  闭", true, false, Vector2(236, 96), 20)
	cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel_btn.pressed.connect(_close_character_detail)
	action_row.add_child(cancel_btn)

	_detail_modal.modulate.a = 1.0
	panel.scale = Vector2.ONE

func _open_character_appearance(character_id: String) -> void:
	if is_instance_valid(_appearance_selector):
		return
	AudioManager.play_sfx("ui_click")
	_appearance_selector = AppearanceSelector.new()
	add_child(_appearance_selector)
	_appearance_selector.store_requested.connect(_on_character_appearance_store_requested)
	_appearance_selector.closed.connect(_on_character_appearance_closed.bind(character_id))
	_appearance_selector.open_character(character_id, router)

func _on_character_appearance_closed(character_id: String) -> void:
	_appearance_selector = null
	if not is_inside_tree():
		return
	var row := DataLoader.get_row("characters", character_id)
	if not row.is_empty():
		call_deferred("_show_character_detail", character_id, row)

func _on_character_appearance_store_requested() -> void:
	router.change_scene("store", {
		"return_to": "collection",
		"return_payload": {
			"mode": "characters",
			"return_to": _return_to,
			"return_level_id": _return_level_id,
			"challenge": _return_challenge_mode,
			"loadout_return_to": _loadout_return_to,
			"loadout_return_payload": _loadout_return_payload.duplicate(true),
		},
	})

# === Helper builders for the modal ===

func _build_panel_style() -> StyleBox:
	return UiKit.detail_panel_texture_style()

func _build_portrait_frame_style() -> StyleBox:
	return UiKit.icon_frame_texture_style(true)

func _build_level_badge_style() -> StyleBox:
	return UiKit.map_pill_texture_style()

func _build_skill_card_style(_accent: Color) -> StyleBox:
	return UiKit.collection_card_texture_style(true)

func _build_skill_icon_frame_style(_accent: Color) -> StyleBox:
	return UiKit.icon_frame_texture_style(false)

func _make_pill(text: String, border_color: Color, fill_color: Color, font_delta := 0) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", _build_pill_style(border_color, fill_color))
	pill.custom_minimum_size = Vector2(0, 38 + max(font_delta, 0) * 3)
	var label := Label.new()
	label.name = "PillLabel"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UiKit.bumped_font_size(CHARACTER_DETAIL_PILL_FONT_SIZE + font_delta))
	label.add_theme_color_override("font_color", Color(0.96, 0.98, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("outline_size", 1)
	pill.add_child(label)
	return pill

func _build_pill_style(_border_color: Color, _fill_color: Color) -> StyleBox:
	return UiKit.map_pill_texture_style()

func _make_section_panel(title: String, accent: Color, title_font_size := 24) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _build_section_style(accent))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	panel.add_child(inner)
	# Title row
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	inner.add_child(title_row)
	# Accent bar
	var bar := TextureRect.new()
	bar.texture = load("res://assets/production/sprites/ui/ui_map_accent_strip.png")
	bar.custom_minimum_size = Vector2(18, 36)
	bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bar.stretch_mode = TextureRect.STRETCH_SCALE
	bar.modulate = accent
	title_row.add_child(bar)
	var title_label := Label.new()
	title_label.name = "SectionTitle"
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", UiKit.bumped_font_size(title_font_size))
	title_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1, 1))
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	title_label.add_theme_constant_override("outline_size", 1)
	title_row.add_child(title_label)
	return panel

func _build_section_style(_accent: Color) -> StyleBox:
	return UiKit.panel_texture_style(14.0)

func _make_stat_pill(label_text: String, value_text: String, sub_text: String, font_delta := 0, resource_kind := "") -> PanelContainer:
	var pill := PanelContainer.new()
	pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var authored_height := 112 if LocalizationManager.is_english() else 98
	pill.custom_minimum_size = Vector2(0, authored_height + max(font_delta, 0) * 4)
	pill.add_theme_stylebox_override("panel", _build_pill_style(Color(0.58, 0.68, 0.74, 0.50), Color(0.026, 0.036, 0.048, 0.72)))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	pill.add_child(v)
	var label := Label.new()
	label.name = "StatLabel"
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", UiKit.bumped_font_size(CHARACTER_DETAIL_STAT_LABEL_FONT_SIZE + font_delta))
	label.add_theme_color_override("font_color", Color(0.7, 0.88, 1, 0.9))
	v.add_child(label)
	var value := Label.new()
	value.name = "StatValue"
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.add_theme_font_size_override("font_size", UiKit.bumped_font_size(CHARACTER_DETAIL_STAT_VALUE_FONT_SIZE + font_delta))
	value.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	value.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	value.add_theme_constant_override("outline_size", 1)
	if resource_kind == "":
		v.add_child(value)
	else:
		var resource_row := HBoxContainer.new()
		resource_row.name = "StatResourceCost"
		resource_row.alignment = BoxContainer.ALIGNMENT_CENTER
		resource_row.add_theme_constant_override("separation", 8)
		var resource_icon := UiKit.icon(UiKit.currency_icon_path(resource_kind), Vector2(28, 28))
		resource_icon.name = "StatResourceIcon"
		resource_row.add_child(resource_icon)
		# In an ordinary stat cell the value expands to the whole card. For a
		# resource pair it must shrink to its digits so logo + amount stay together.
		value.autowrap_mode = TextServer.AUTOWRAP_OFF
		value.clip_text = false
		value.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		resource_row.add_child(value)
		resource_row.set_meta("cost_resource_kind", resource_kind)
		v.add_child(resource_row)
	if sub_text != "":
		var sub := Label.new()
		sub.name = "StatSub"
		sub.text = sub_text
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sub.add_theme_font_size_override("font_size", UiKit.bumped_font_size(CHARACTER_DETAIL_STAT_SUB_FONT_SIZE + font_delta))
		sub.add_theme_color_override("font_color", Color(0.55, 0.85, 1, 0.75))
		v.add_child(sub)
	return pill

func _make_skill_row(icon_path, title: String, kind_label: String, desc: String, accent: Color, parent: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "SkillRow"
	row.add_theme_constant_override("separation", 22)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, 168)
	# The authored section frame already owns its ornamental inset. Keep an
	# additional content-safe gutter so a larger square icon never rides the
	# left rail; all enlargement therefore consumes space to the right.
	var leading_inset := Control.new()
	leading_inset.name = "SkillLeadingInset"
	leading_inset.custom_minimum_size = Vector2(CHARACTER_DETAIL_SKILL_LEADING_INSET, 0)
	row.add_child(leading_inset)
	# Icon
	var icon_box := PanelContainer.new()
	icon_box.name = "SkillIconFrame"
	icon_box.custom_minimum_size = CHARACTER_DETAIL_SKILL_ICON_FRAME_SIZE
	# HBox children fill the cross axis by default, which previously stretched
	# the frame into a tall rectangle and forced square artwork to scale by the
	# narrower width. A centred shrink flag keeps the frame genuinely square.
	icon_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_box.add_theme_stylebox_override("panel", _build_pill_style(accent, Color(0.06, 0.1, 0.16, 0.85)))
	row.add_child(icon_box)
	if icon_path != null and str(icon_path) != "" and ResourceLoader.exists(str(icon_path)):
		var icon := TextureRect.new()
		icon.name = "SkillIcon"
		icon.texture = load(str(icon_path))
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = CHARACTER_DETAIL_SKILL_ICON_SIZE
		icon_box.add_child(icon)
	else:
		# Invalid dynamic data must still resolve to finished raster art in a
		# release build; never expose the old geometric diamond placeholder.
		var fallback_icon := TextureRect.new()
		fallback_icon.name = "SkillIcon"
		fallback_icon.texture = load("res://assets/production/sprites/ui/icon_talent_point.png")
		fallback_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fallback_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fallback_icon.custom_minimum_size = CHARACTER_DETAIL_SKILL_ICON_SIZE
		icon_box.add_child(fallback_icon)
	# Text column
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)
	row.add_child(text_col)
	# Title row
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	text_col.add_child(title_row)
	var title_label := Label.new()
	title_label.name = "SkillTitle"
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", UiKit.bumped_font_size(CHARACTER_DETAIL_SKILL_TITLE_FONT_SIZE))
	title_label.add_theme_color_override("font_color", Color(0.98, 0.99, 1, 1))
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	title_label.add_theme_constant_override("outline_size", 1)
	title_row.add_child(title_label)
	# Kind pill — same semantic component as the Skill Codex list.
	var kind_pill := UiKit.semantic_tag_pill(LocalizationManager.text(kind_label), "kind", 16)
	kind_pill.name = "SkillKindTag"
	title_row.add_child(kind_pill)
	var kind_label_text := kind_pill.get_node("Text") as Label
	kind_label_text.name = "SkillKind"
	# Description
	var desc_label := Label.new()
	desc_label.name = "SkillDescription"
	desc_label.text = desc
	desc_label.add_theme_font_size_override("font_size", UiKit.bumped_font_size(CHARACTER_DETAIL_SKILL_DESC_FONT_SIZE))
	desc_label.add_theme_color_override("font_color", Color(0.78, 0.88, 0.95, 1))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_col.add_child(desc_label)
	return row

# 专属主动技独立升级行：等级 N/5 + 花经验升级按钮，紧跟在该技能的 _make_skill_row 下面。
func _make_sig_skill_upgrade_row(character_id: String, signature_id: String) -> VBoxContainer:
	# Keep the upgrade control on its own top line and give the growth copy the
	# full card width below. The old side-by-side layout compressed the most
	# useful mobile reading text into a narrow column beside a wide button.
	var row := VBoxContainer.new()
	row.name = "SignatureUpgradeLayout"
	row.add_theme_constant_override("separation", 7)
	row.custom_minimum_size = Vector2(0, 178)
	var lvl := SaveManager.get_sig_skill_level(character_id)
	var maxed := lvl >= SaveManager.SIG_SKILL_MAX_LEVEL
	var top_row := HBoxContainer.new()
	top_row.name = "SignatureUpgradeTopRow"
	top_row.custom_minimum_size = Vector2(0, 112)
	top_row.add_theme_constant_override("separation", 12)
	row.add_child(top_row)
	var level_label := Label.new()
	level_label.name = "SignatureLevel"
	level_label.text = "专属技能等级 %d/%d" % [lvl, SaveManager.SIG_SKILL_MAX_LEVEL]
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", UiKit.bumped_font_size(CHARACTER_DETAIL_SIG_LEVEL_FONT_SIZE))
	level_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.62, 1))
	top_row.add_child(level_label)
	var can_up := SaveManager.can_upgrade_sig_skill(character_id)
	var cost_spec := SaveManager.get_sig_skill_upgrade_cost_spec(character_id)
	var cost := int(cost_spec.get("amount", -1))
	var btn := _armored_action_button("SigSkillUpgradeButton", "已精通" if maxed else _loc("升级", "Upgrade"), true, true, Vector2(286, 112), 20)
	if not maxed:
		UiKit.apply_resource_cost(btn, _loc("升级", "Upgrade"), str(cost_spec.get("kind", "xp")), cost, 17, 26.0)
	btn.custom_minimum_size = Vector2(286, 112)
	btn.disabled = not can_up
	btn.modulate = ACTION_ACTIVE_MODULATE if can_up else ACTION_DISABLED_MODULATE
	btn.pressed.connect(_upgrade_sig_skill_from_detail.bind(character_id))
	top_row.add_child(btn)
	var growth_label := Label.new()
	growth_label.name = "SignatureGrowth"
	growth_label.text = CharacterSkillText.signature_level_growth(signature_id)
	growth_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	growth_label.add_theme_font_size_override("font_size", UiKit.bumped_font_size(CHARACTER_DETAIL_SIG_GROWTH_FONT_SIZE))
	growth_label.add_theme_color_override("font_color", Color(0.66, 0.82, 0.9, 1))
	growth_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	growth_label.custom_minimum_size = Vector2(0, 52)
	growth_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	growth_label.clip_text = false
	row.add_child(growth_label)
	return row

func _upgrade_sig_skill_from_detail(character_id: String) -> void:
	if SaveManager.upgrade_sig_skill(character_id):
		AudioManager.play_sfx("upgrade")
		_refresh()
		var fresh_row := DataLoader.get_row("characters", character_id)
		_close_character_detail()
		call_deferred("_show_character_detail", character_id, fresh_row)
	else:
		AudioManager.play_sfx("ui_click", -6.0)

func _element_color(element: String) -> Color:
	# Single source of truth: never diverge from UiKit element coding.
	return UiKit.element_color(element)

func _element_color_dark(element: String) -> Color:
	var base := UiKit.element_color(element)
	return Color(base.r * 0.34, base.g * 0.34, base.b * 0.34, 0.7)

func _close_character_detail() -> void:
	if _detail_modal != null and is_instance_valid(_detail_modal):
		_detail_modal.queue_free()
	_detail_modal = null
	_set_collection_content_visible(true)

func _select_character_and_close(item_id: String) -> void:
	if SaveManager.select_item("character", item_id):
		AudioManager.play_sfx("ui_confirm")
		_refresh()
	_close_character_detail()
