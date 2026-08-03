extends Control

const UiKit := preload("res://ui/ui_kit.gd")
const AppearanceSelector := preload("res://ui/appearance_selector.gd")
const STORE_PREVIEW_SIZE := Vector2(330, 330)
const STORE_PREVIEW_INSET := 10
const STORE_PREVIEW_GAP := 6
const STORE_PREVIEW_CELL_SIZE := Vector2(152, 152)
const STORE_PREVIEW_CELL_CONTENT_SIZE := Vector2(146, 146)
const STORE_THEME_BUST_VISIBLE_HEIGHT := 212.0
const STORE_THEME_BUST_HEADROOM := 8.0
const STORE_ITEM_VISIBLE_EXTENT := 124.0

var router: Node
var _dialog_layer: CanvasLayer
var _status_label: Label
var _appearance_selector: CanvasLayer
var _return_to := "menu"
var _return_payload := {}
var _open_appearance_on_ready := false


func setup(main: Node, payload := {}) -> void:
	router = main
	if payload is Dictionary:
		var requested_return := str(payload.get("return_to", "menu"))
		_return_to = requested_return if requested_return in ["menu", "settings", "collection", "loadout"] else "menu"
		var raw_return_payload: Variant = payload.get("return_payload", {})
		_return_payload = raw_return_payload.duplicate(true) if raw_return_payload is Dictionary else {}
		_open_appearance_on_ready = bool(payload.get("open_theme_appearance", false))


func _ready() -> void:
	AudioManager.play_bgm("menu")
	PurchaseManager.refresh_catalog_and_access()
	$Root/VBox/Footer/RestoreButton.pressed.connect(_restore)
	$Root/VBox/Footer/ResetButton.pressed.connect(_confirm_reset)
	$Root/VBox/Footer/BackButton.pressed.connect(_back)
	PurchaseManager.commerce_changed.connect(_rebuild)
	PurchaseManager.purchase_finished.connect(_on_purchase_finished)
	_apply_style()
	_rebuild()
	if _open_appearance_on_ready:
		call_deferred("_open_theme_appearance")


func _loc(zh: String, en: String) -> String:
	return en if LocalizationManager.is_english() else zh


func _apply_style() -> void:
	UiKit.apply_label($Root/VBox/Title, 42, UiKit.TEXT_MAIN, 4)
	UiKit.apply_label($Root/VBox/MockNotice, 18, UiKit.WARNING, 2)
	$Root/VBox/Title.text = _store_title()
	$Root/VBox/MockNotice.text = _loc(
		"本地演示商店 · 不连接 Apple · 不会扣款",
		"LOCAL DEMO STORE · No Apple connection · No charge"
	)
	# Fit the final localized copy, not the longer Chinese scene placeholders.
	# Otherwise switching to English inherits an unnecessary 18 px fallback.
	$Root/VBox/Footer/RestoreButton.text = _loc("恢复购买", "Restore")
	$Root/VBox/Footer/ResetButton.text = _loc("清空演示", "Reset Demo")
	$Root/VBox/Footer/BackButton.text = _loc("返回", "Back")
	for spec in [
		[$Root/VBox/Footer/RestoreButton, false],
		[$Root/VBox/Footer/ResetButton, false],
		[$Root/VBox/Footer/BackButton, true],
	]:
		UiKit.apply_armored_button(spec[0], spec[1], Vector2(286, 88), 19, true)
		(spec[0] as Button).focus_mode = Control.FOCUS_NONE


func _rebuild() -> void:
	var content := $Root/VBox/ScrollWrap/Scroll/Content as VBoxContainer
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

	_status_label = UiKit.label(_ownership_status(), 18, UiKit.CYAN, 2)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(0, 54)
	content.add_child(_status_label)

	for series_id in PurchaseManager.store_series_ids():
		content.add_child(_series_header(series_id))
		for product_id in PurchaseManager.visible_offer_ids(series_id):
			content.add_child(_product_card(PurchaseManager.product(product_id)))
		if PurchaseManager.is_arsenal_owned(series_id):
			content.add_child(_owned_set_panel(PurchaseManager.set_id_for_series(series_id)))
		elif PurchaseManager.is_theme_owned(series_id):
			content.add_child(_owned_theme_panel(series_id))


func _series_header(series_id: String) -> PanelContainer:
	var set_row := PurchaseManager.set_for_series(series_id)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.hint_texture_style(false))
	panel.custom_minimum_size = Vector2(0, 72)
	var label := UiKit.label(str(set_row.get(
		"store_title_en" if LocalizationManager.is_english() else "store_title_zh",
		series_id
	)), 24, UiKit.GOLD, 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel


func _store_title() -> String:
	var series_ids := PurchaseManager.store_series_ids()
	if series_ids.size() == 1:
		var set_row := PurchaseManager.set_for_series(series_ids[0])
		return str(set_row.get("store_title_en" if LocalizationManager.is_english() else "store_title_zh", _loc("精品军械库", "Premium Arsenal")))
	return _loc("精品军械库", "Premium Arsenal")


func _ownership_status() -> String:
	var lines: Array[String] = []
	var key := "owned_status_en" if LocalizationManager.is_english() else "owned_status_zh"
	var theme_key := "theme_status_en" if LocalizationManager.is_english() else "theme_status_zh"
	for series_id in PurchaseManager.store_series_ids():
		var set_row := PurchaseManager.set_for_series(series_id)
		if PurchaseManager.is_arsenal_owned(series_id):
			lines.append(str(set_row.get(key, series_id)))
		elif PurchaseManager.is_theme_owned(series_id):
			lines.append(str(set_row.get(theme_key, series_id)))
	if not lines.is_empty():
		return "\n".join(lines)
	return _loc("先预览完整购买闭环；正式版价格将由 App Store 返回", "Preview the complete flow; App Store will supply production prices")


func _product_card(row: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var product_id := str(row.get("id", ""))
	var offer_role := str(row.get("offer_role", ""))
	panel.name = "Product_%s" % product_id.replace(".", "_")
	panel.set_meta("store_product_id", product_id)
	panel.add_theme_stylebox_override("panel", UiKit.panel_texture_style(22.0))
	panel.custom_minimum_size = Vector2(0, 430 if offer_role != "theme" else 390)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 22)
	panel.add_child(margin)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	margin.add_child(hbox)

	hbox.add_child(_product_preview(row))

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 12)
	hbox.add_child(copy)
	var name := UiKit.label(str(row.get("name_en" if LocalizationManager.is_english() else "name_zh", "")), 25, UiKit.TEXT_MAIN, 3)
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(name)
	var subtitle := UiKit.label(str(row.get("subtitle_en" if LocalizationManager.is_english() else "subtitle_zh", "")), 17, UiKit.GREY_300, 2)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	copy.add_child(subtitle)
	if offer_role != "theme":
		var set_row := DataLoader.get_row("premium_sets", str(row.get("arsenal_set_id", "")))
		var dominance := UiKit.label(str(set_row.get(
			"dominance_en" if LocalizationManager.is_english() else "dominance_zh",
			""
		)), 16, UiKit.GOLD, 2)
		dominance.name = "DominanceRange"
		dominance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dominance.custom_minimum_size = Vector2(0, 58)
		copy.add_child(dominance)
	var contents := UiKit.label(
		_loc("永久解锁 · 可恢复 · 不含消耗品", "Permanent · Restorable · No consumables"),
		16,
		UiKit.SUCCESS,
		2
	)
	contents.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(contents)
	var buy := Button.new()
	buy.name = "Buy_" + str(row.get("id", "")).replace(".", "_")
	buy.focus_mode = Control.FOCUS_NONE
	buy.text = _loc("演示购买  ", "Demo Buy  ") + str(row.get("mock_price_en" if LocalizationManager.is_english() else "mock_price_zh", ""))
	UiKit.apply_armored_button(buy, true, Vector2(484, 102), 20, true)
	buy.pressed.connect(_confirm_purchase.bind(str(row.get("id", ""))))
	copy.add_child(buy)
	return panel


func _product_preview(row: Dictionary) -> Control:
	var preview_layout := str(row.get("preview_layout", ""))
	var theme_id := str(row.get("theme_id", "default"))
	var accent := _theme_preview_accent(theme_id)
	var frame := PanelContainer.new()
	frame.name = "Preview"
	frame.custom_minimum_size = STORE_PREVIEW_SIZE
	frame.clip_contents = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_meta("store_preview_layout", preview_layout)
	frame.set_meta("store_preview_theme", theme_id)
	frame.set_meta("store_preview_slots", 4)
	frame.add_theme_stylebox_override("panel", _store_preview_frame_style(accent))

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, STORE_PREVIEW_INSET)
	frame.add_child(margin)
	var grid := GridContainer.new()
	grid.name = "Grid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", STORE_PREVIEW_GAP)
	grid.add_theme_constant_override("v_separation", STORE_PREVIEW_GAP)
	margin.add_child(grid)

	match preview_layout:
		"theme_roster":
			_populate_theme_preview(grid, theme_id, accent)
		"arsenal_grid":
			_populate_arsenal_preview(grid, str(row.get("arsenal_set_id", "")), accent)
		_:
			# Compatibility fallback for external/fixture products. Authored launch
			# offers all use one of the two semantic layouts above.
			var legacy := UiKit.icon(str(row.get("art", "")), STORE_PREVIEW_SIZE - Vector2(20, 20))
			legacy.name = "LegacyArt"
			legacy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			grid.columns = 1
			grid.add_child(legacy)
	return frame


func _populate_theme_preview(grid: GridContainer, theme_id: String, accent: Color) -> void:
	var characters: Dictionary = DataLoader.get_table("characters")
	for character_id_var in characters.keys():
		var character_id := str(character_id_var)
		var row: Dictionary = characters.get(character_id, {})
		var fallback_path := UiKit.character_bust_path(row)
		var portrait_path := ThemeManager.resolve_character_portrait_for_theme(character_id, theme_id, fallback_path)
		var texture := load(portrait_path) as Texture2D if ResourceLoader.exists(portrait_path) else null
		var cell := _store_preview_cell("Hero_%s" % character_id, accent)
		grid.add_child(cell)
		var viewport := Control.new()
		viewport.name = "Viewport"
		viewport.custom_minimum_size = STORE_PREVIEW_CELL_CONTENT_SIZE
		viewport.clip_contents = true
		viewport.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(viewport)
		_add_store_theme_bust(viewport, texture, portrait_path)


func _populate_arsenal_preview(grid: GridContainer, set_id: String, accent: Color) -> void:
	var set_row := DataLoader.get_row("premium_sets", set_id)
	for slot_spec in [
		["weapon", "weapons"],
		["armor", "armors"],
		["chip", "chips"],
		["pet", "pets"],
	]:
		var slot := str(slot_spec[0])
		var table := str(slot_spec[1])
		var item_id := str(set_row.get(slot, ""))
		var item_row := DataLoader.get_row(table, item_id)
		var icon_path := str(item_row.get("icon", ""))
		var texture := _store_preview_texture(item_row, icon_path)
		var cell := _store_preview_cell(slot.capitalize(), accent)
		cell.set_meta("store_preview_item_id", item_id)
		grid.add_child(cell)
		var viewport := Control.new()
		viewport.name = "Viewport"
		viewport.custom_minimum_size = STORE_PREVIEW_CELL_CONTENT_SIZE
		viewport.clip_contents = true
		viewport.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(viewport)
		_add_store_item(viewport, texture, icon_path)


func _store_preview_texture(item_row: Dictionary, icon_path: String) -> Texture2D:
	var texture := load(icon_path) as Texture2D if ResourceLoader.exists(icon_path) else null
	var region_value: Variant = item_row.get("store_preview_region", [])
	if texture == null or not region_value is Array:
		return texture
	var region: Array = region_value
	if region.size() != 4:
		return texture
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(
		float(region[0]),
		float(region[1]),
		float(region[2]),
		float(region[3])
	)
	return atlas


func _store_preview_cell(cell_name: String, accent: Color) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.name = cell_name
	cell.custom_minimum_size = STORE_PREVIEW_CELL_SIZE
	cell.clip_contents = true
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_theme_stylebox_override("panel", _store_preview_cell_style(accent))
	return cell


func _add_store_theme_bust(parent: Control, texture: Texture2D, source_path: String) -> void:
	var bust := TextureRect.new()
	bust.name = "Bust"
	bust.texture = texture
	bust.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bust.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bust.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bust)
	if texture == null:
		bust.custom_minimum_size = STORE_PREVIEW_CELL_CONTENT_SIZE
		return
	var used := _texture_used_rect(texture)
	var scale_factor := STORE_THEME_BUST_VISIBLE_HEIGHT / maxf(used.size.y, 1.0)
	var texture_size := texture.get_size() * scale_factor
	var visible_size := used.size * scale_factor
	var visible_position := Vector2(
		(STORE_PREVIEW_CELL_CONTENT_SIZE.x - visible_size.x) * 0.5,
		STORE_THEME_BUST_HEADROOM
	)
	bust.position = visible_position - used.position * scale_factor
	bust.size = texture_size
	bust.custom_minimum_size = texture_size
	bust.set_meta("store_preview_source", source_path)
	bust.set_meta("store_preview_visible_rect", Rect2(visible_position, visible_size))
	bust.set_meta("store_preview_visible_height", STORE_THEME_BUST_VISIBLE_HEIGHT)


func _add_store_item(parent: Control, texture: Texture2D, source_path: String) -> void:
	var item := TextureRect.new()
	item.name = "Item"
	item.texture = texture
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	if texture == null:
		item.custom_minimum_size = STORE_PREVIEW_CELL_CONTENT_SIZE
		return
	var used := _texture_used_rect(texture)
	var scale_factor := STORE_ITEM_VISIBLE_EXTENT / maxf(maxf(used.size.x, used.size.y), 1.0)
	var texture_size := texture.get_size() * scale_factor
	var visible_size := used.size * scale_factor
	var visible_position := (STORE_PREVIEW_CELL_CONTENT_SIZE - visible_size) * 0.5
	item.position = visible_position - used.position * scale_factor
	item.size = texture_size
	item.custom_minimum_size = texture_size
	item.set_meta("store_preview_source", source_path)
	item.set_meta("store_preview_visible_rect", Rect2(visible_position, visible_size))
	item.set_meta("store_preview_visible_extent", maxf(visible_size.x, visible_size.y))


func _texture_used_rect(texture: Texture2D) -> Rect2:
	var image := texture.get_image() if texture != null else null
	if image == null or image.is_empty():
		return Rect2(Vector2.ZERO, texture.get_size() if texture != null else Vector2.ONE)
	var used := image.get_used_rect()
	if used.size == Vector2i.ZERO:
		return Rect2(Vector2.ZERO, texture.get_size())
	return Rect2(used)


func _theme_preview_accent(theme_id: String) -> Color:
	for theme in ThemeManager.catalog_themes():
		if str(theme.get("id", "")) != theme_id:
			continue
		var rgba: Array = theme.get("ui", {}).get("accent_color", [])
		if rgba.size() >= 4:
			return Color(float(rgba[0]), float(rgba[1]), float(rgba[2]), float(rgba[3]))
	return UiKit.CYAN


func _store_preview_frame_style(accent: Color) -> StyleBox:
	var style := UiKit.texture_style(
		UiKit.UI_TEXTURE_ROOT + "ui_icon_frame.png",
		32.0,
		4.0,
		accent
	)
	if style is StyleBoxTexture:
		(style as StyleBoxTexture).modulate_color = Color.WHITE.lerp(accent, 0.22)
	return style


func _store_preview_cell_style(accent: Color) -> StyleBox:
	var style := UiKit.texture_style(
		UiKit.UI_TEXTURE_ROOT + "ui_icon_frame.png",
		28.0,
		3.0,
		accent
	)
	if style is StyleBoxTexture:
		(style as StyleBoxTexture).modulate_color = Color.WHITE.lerp(accent, 0.14)
	return style


func _owned_theme_panel(series_id: String) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_texture_style(24.0))
	var set_row := PurchaseManager.set_for_series(series_id)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var label := UiKit.label(str(set_row.get(
		"theme_owned_description_en" if LocalizationManager.is_english() else "theme_owned_description_zh",
		_loc("主题已解锁，可在设置中切换。", "Theme unlocked; select it in Settings.")
	)), 20, UiKit.SUCCESS, 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(0, 84)
	box.add_child(label)
	box.add_child(_series_reset_button(series_id))
	return panel


func _owned_set_panel(set_id: String) -> Control:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", UiKit.panel_texture_style(24.0))
	var header_box := VBoxContainer.new()
	header.add_child(header_box)
	var set_row := DataLoader.get_row("premium_sets", set_id)
	var title := UiKit.label(str(set_row.get(
		"owned_title_en" if LocalizationManager.is_english() else "owned_title_zh",
		_loc("完整套装 · 已拥有", "Complete Set · Owned")
	)), 28, UiKit.GOLD, 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_box.add_child(title)
	var equip := Button.new()
	equip.focus_mode = Control.FOCUS_NONE
	equip.text = _loc("一键装备整套并启用主题", "Equip Full Set + Theme")
	UiKit.apply_armored_button(equip, true, Vector2(760, 96), 22, true)
	equip.pressed.connect(_equip_set.bind(set_id))
	header_box.add_child(equip)
	header_box.add_child(_series_reset_button(str(set_row.get("series_id", ""))))
	root.add_child(header)

	for table_slot in [["weapons", "weapon"], ["armors", "armor"], ["chips", "chip"], ["pets", "pet"]]:
		var table: String = table_slot[0]
		var slot: String = table_slot[1]
		root.add_child(_owned_item_row(table, slot, str(set_row.get(slot, ""))))
	var bonus := UiKit.label(
		str(set_row.get(
			"two_piece_description_en" if LocalizationManager.is_english() else "two_piece_description_zh",
			_loc("套装效果已启用", "Set bonuses active")
		)),
		18,
		UiKit.CYAN,
		2
	)
	bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bonus.custom_minimum_size = Vector2(0, 100)
	root.add_child(bonus)
	return root


func _series_reset_button(series_id: String) -> Button:
	var reset := Button.new()
	reset.focus_mode = Control.FOCUS_NONE
	reset.text = _loc("撤销本系列演示购买", "Reset This Series")
	UiKit.apply_armored_button(reset, false, Vector2(520, 78), 17, true)
	reset.pressed.connect(_confirm_series_reset.bind(series_id))
	return reset


func _owned_item_row(table: String, slot: String, item_id: String) -> PanelContainer:
	var row := DataLoader.get_row(table, item_id)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.collection_card_texture_style(false))
	panel.custom_minimum_size = Vector2(0, 158)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	panel.add_child(h)
	h.add_child(UiKit.icon(str(row.get("icon", "")), Vector2(138, 138)))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(copy)
	var title := UiKit.label(DataLoader.tr_key(str(row.get("name_key", item_id))), 22, UiKit.TEXT_MAIN, 2)
	copy.add_child(title)
	var level := SaveManager.get_item_level(item_id)
	copy.add_child(UiKit.label(
		LocalizationManager.text("等级 %d / %d") % [level, int(row.get("max_level", 1))],
		17,
		UiKit.CYAN,
		2
	))
	var selected := SaveManager.get_selected(slot) == item_id
	copy.add_child(UiKit.label(_loc("已装备" if selected else "已拥有", "Equipped" if selected else "Owned"), 16, UiKit.SUCCESS, 2))
	var upgrade := Button.new()
	upgrade.focus_mode = Control.FOCUS_NONE
	var maxed := level >= int(row.get("max_level", 1))
	var cost := SaveManager.get_item_upgrade_cost(table, item_id)
	upgrade.text = _loc("已满级", "MAX") if maxed else _loc("升级 %d 金币" % cost, "Upgrade %d Gold" % cost)
	upgrade.disabled = maxed or not SaveManager.can_upgrade_item(table, item_id)
	UiKit.apply_armored_button(upgrade, false, Vector2(320, 80), 17, not upgrade.disabled)
	upgrade.pressed.connect(_upgrade_item.bind(table, item_id))
	h.add_child(upgrade)
	return panel


func _confirm_purchase(product_id: String) -> void:
	var row := PurchaseManager.product(product_id)
	var dominance := ""
	if str(row.get("offer_role", "")) != "theme":
		var set_row := DataLoader.get_row("premium_sets", str(row.get("arsenal_set_id", "")))
		dominance = str(set_row.get("dominance_en" if LocalizationManager.is_english() else "dominance_zh", ""))
	_show_dialog(
		_loc("确认演示购买", "Confirm Demo Purchase"),
		_loc(
			"%s\n%s%s\n\n这是本地流程验证，不连接 Apple，也不会扣款。" % [row.get("name_zh", ""), row.get("mock_price_zh", ""), "\n" + dominance if dominance != "" else ""],
			"%s\n%s%s\n\nThis is a local flow test. Apple is not connected and no charge occurs." % [row.get("name_en", ""), row.get("mock_price_en", ""), "\n" + dominance if dominance != "" else ""]
		),
		_loc("确认购买", "Confirm"),
		func() -> void: PurchaseManager.mock_purchase(product_id)
	)


func _confirm_reset() -> void:
	_show_dialog(
		_loc("清空演示购买？", "Reset Demo Purchases?"),
		_loc("会收回本地主题与军械权益，装备等级会保留，方便重复验收。", "Local entitlements will be revoked; item levels stay for repeat testing."),
		_loc("清空", "Reset"),
		func() -> void: PurchaseManager.reset_mock_purchases()
	)


func _confirm_series_reset(series_id: String) -> void:
	var set_row := PurchaseManager.set_for_series(series_id)
	var series_name := str(set_row.get(
		"store_title_en" if LocalizationManager.is_english() else "store_title_zh",
		series_id
	))
	_show_dialog(
		_loc("撤销本系列演示购买？", "Reset This Demo Series?"),
		_loc(
			"只收回「%s」的本地权益，不影响另一套已购主题或军械。" % series_name,
			"Only %s local entitlements are revoked; the other series remains owned." % series_name
		),
		_loc("确认撤销", "Reset Series"),
		func() -> void: PurchaseManager.reset_mock_purchases_for_series(series_id)
	)


func _show_dialog(title_text: String, body_text: String, confirm_text: String, callback: Callable) -> void:
	if is_instance_valid(_dialog_layer):
		_dialog_layer.queue_free()
	_dialog_layer = UiKit.confirm_modal(self, {
		"title": title_text,
		"message": body_text,
		"accent": UiKit.GOLD,
		"confirm_text": confirm_text,
		"cancel_text": _loc("取消", "Cancel"),
		"on_confirm": callback,
	})


func _restore() -> void:
	PurchaseManager.restore_mock_purchases()


func _equip_set(set_id: String) -> void:
	if PurchaseManager.equip_complete_set(set_id):
		AudioManager.play_sfx("ui_confirm")
		_rebuild()


func _upgrade_item(table: String, item_id: String) -> void:
	if SaveManager.upgrade_item(table, item_id):
		AudioManager.play_sfx("ui_confirm")
		_rebuild()


func _on_purchase_finished(_product_id: String, success: bool, message: String) -> void:
	AudioManager.play_sfx("ui_confirm" if success else "ui_click")
	if success and _product_id != "":
		_show_purchase_completion(_product_id)
	else:
		_show_toast(_loc(message, _english_message(message)))


func _show_purchase_completion(product_id: String) -> void:
	var row := PurchaseManager.product(product_id)
	_dialog_layer = UiKit.confirm_modal(self, {
		"title": _loc("购买完成", "Purchase Complete"),
		"message": _loc(
			"%s 已解锁。\n现在应用整套，或逐个角色选择战衣。" % str(row.get("name_zh", "")),
			"%s is unlocked.\nApply the complete look now, or dress each hero individually." % str(row.get("name_en", ""))
		),
		"accent": UiKit.GOLD,
		"confirm_text": _loc("立即应用整套", "Apply Full Look"),
		"cancel_text": _loc("逐个角色换装", "Dress Heroes"),
		"on_confirm": _apply_new_purchase.bind(product_id),
		"on_cancel": _customize_new_purchase.bind(product_id),
	})


func _apply_new_purchase(product_id: String) -> void:
	var set_id := PurchaseManager.set_id_for_product(product_id)
	var series_id := PurchaseManager.series_id_for_product(product_id)
	if PurchaseManager.is_arsenal_owned(series_id):
		PurchaseManager.equip_complete_set(set_id)
	ThemeManager.apply_theme_to_all_characters(PurchaseManager.theme_id_for_product(product_id))
	router.change_scene("store", _store_payload(false))


func _customize_new_purchase(product_id: String) -> void:
	ThemeManager.select_theme(PurchaseManager.theme_id_for_product(product_id))
	router.change_scene("store", _store_payload(true))


func _open_theme_appearance() -> void:
	if is_instance_valid(_appearance_selector):
		return
	_appearance_selector = AppearanceSelector.new()
	add_child(_appearance_selector)
	_appearance_selector.global_theme_changed.connect(
		func(_theme_id: String) -> void: router.change_scene("store", _store_payload(true))
	)
	_appearance_selector.closed.connect(func() -> void: _appearance_selector = null)
	_appearance_selector.open_global(router)


func _store_payload(open_appearance: bool) -> Dictionary:
	return {
		"return_to": _return_to,
		"return_payload": _return_payload.duplicate(true),
		"open_theme_appearance": open_appearance,
	}


func _english_message(message: String) -> String:
	if message.begins_with("本地演示购买成功"):
		return "Demo purchase complete. No charge occurred."
	if message.begins_with("已恢复"):
		return "Local demo purchases restored."
	if message.begins_with("本地演示购买已清空"):
		return "Local demo purchases reset."
	if message.begins_with("已清空本系列"):
		return "This local demo series was reset."
	return "The demo purchase could not be completed."


func _show_toast(message: String) -> void:
	var toast := PanelContainer.new()
	toast.add_theme_stylebox_override("panel", UiKit.hint_texture_style(false))
	toast.position = Vector2(160, 1500)
	toast.size = Vector2(760, 96)
	var label := UiKit.label(message, 18, UiKit.SUCCESS, 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast.add_child(label)
	add_child(toast)
	var tween := toast.create_tween()
	tween.tween_interval(1.4)
	tween.tween_property(toast, "modulate:a", 0.0, 0.3)
	tween.tween_callback(toast.queue_free)


func _back() -> void:
	AudioManager.play_sfx("ui_click")
	router.change_scene(_return_to, _return_payload.duplicate(true))
