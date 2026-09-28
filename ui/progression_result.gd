extends CanvasLayer

const UiKit := preload("res://ui/ui_kit.gd")
const Values := preload("res://ui/progression_values.gd")

var payload: Dictionary = {}
var repeat_action := Callable()
var finished := Callable()
var primary_action := Callable()
var secondary_action := Callable()
var panel: PanelContainer
var layout: VBoxContainer
var scroll: ScrollContainer
var body: VBoxContainer
var _busy := false
var _closed := false
var _animation: Tween

static func upgrade(host: Node, table: String, item_id: String, on_refresh := Callable(), on_finished := Callable()) -> bool:
	if host.has_meta("progression_result") and is_instance_valid(host.get_meta("progression_result")):
		return false
	var data := _transact(table, item_id)
	if data.is_empty():
		AudioManager.play_sfx("ui_click", -6)
		return false
	if on_refresh.is_valid():
		on_refresh.call()
	var popup = load("res://ui/progression_result.gd").new()
	popup.payload = data
	popup.finished = on_finished
	popup.repeat_action = func() -> Dictionary:
		var next := _transact(table, item_id)
		if not next.is_empty() and on_refresh.is_valid():
			on_refresh.call()
		return next
	host.set_meta("progression_result", popup)
	host.add_child(popup)
	return true

static func _transact(table: String, item_id: String) -> Dictionary:
	var before := Values.snapshot(table, item_id)
	var cost := SaveManager.get_item_upgrade_cost_spec(table, item_id)
	var success := false
	match table:
		"skills":
			cost = SaveManager.get_skill_base_upgrade_cost_spec(item_id)
			success = SaveManager.upgrade_skill_base(item_id)
		"signature":
			cost = SaveManager.get_sig_skill_upgrade_cost_spec(item_id)
			success = SaveManager.upgrade_sig_skill(item_id)
		_:
			success = SaveManager.upgrade_item(table, item_id)
	if not success:
		return {}
	var after := Values.snapshot(table, item_id)
	var max_level := int(DataLoader.get_row(table, item_id).get("max_level", 30))
	var can_repeat := SaveManager.can_upgrade_item(table, item_id)
	var next_cost := SaveManager.get_item_upgrade_cost_spec(table, item_id)
	if table == "skills":
		max_level = SaveManager.get_skill_base_max(item_id)
		can_repeat = SaveManager.can_upgrade_skill_base(item_id)
		next_cost = SaveManager.get_skill_base_upgrade_cost_spec(item_id)
	elif table == "signature":
		max_level = SaveManager.SIG_SKILL_MAX_LEVEL
		can_repeat = SaveManager.can_upgrade_sig_skill(item_id)
		next_cost = SaveManager.get_sig_skill_upgrade_cost_spec(item_id)
	AudioManager.play_sfx("upgrade")
	return {"title": Values._loc("升级成功", "Upgrade complete"), "name": after.name, "icon": after.icon,
		"level_text": "Lv.%d  →  Lv.%d" % [before.level, after.level], "rows": Values.changes(before, after),
		"note": after.note, "cost": cost, "next_cost": next_cost, "can_repeat": can_repeat,
		"maxed": int(after.level) >= max_level, "table": table, "item_id": item_id}

static func acquired(host: Node, table: String, item_id: String, cost: Dictionary, on_finished := Callable()) -> CanvasLayer:
	var after := Values.snapshot(table, item_id)
	var popup = load("res://ui/progression_result.gd").new()
	popup.payload = {"title": Values._loc("解锁成功", "Unlocked"), "name": after.name, "icon": after.icon,
		"level_text": Values._loc("新成员加入 · 等级 %d", "Added to your collection · Lv.%d") % after.level,
		"rows": Values.changes({}, after, true), "note": Values._loc("已解锁并装备，可继续在详情中培养。", "Unlocked and equipped. Open its details to keep upgrading."), "cost": cost}
	popup.payload["table"] = table
	popup.payload["item_id"] = item_id
	popup.finished = on_finished
	host.add_child(popup)
	return popup

static func premium(host: Node, product_id: String, apply: Callable, customize: Callable) -> CanvasLayer:
	var product := PurchaseManager.product(product_id)
	var set_row := DataLoader.get_row("premium_sets", PurchaseManager.set_id_for_product(product_id))
	var is_theme := str(product.get("kind", "")) == "theme"
	var language := "en" if LocalizationManager.is_english() else "zh"
	var items := []
	if not is_theme:
		for spec in [["weapon", "weapons"], ["armor", "armors"], ["chip", "chips"], ["pet", "pets"]]:
			var id := str(set_row.get(spec[0], ""))
			var row := DataLoader.get_row(spec[1], id)
			items.append({"name": DataLoader.tr_key(str(row.get("name_key", id))), "icon": UiKit.item_icon_path(spec[1], id, row), "level": SaveManager.get_item_level(id)})
	else:
		for id in DataLoader.get_table("characters"):
			var row := DataLoader.get_row("characters", id)
			var path := ThemeManager.resolve_character_portrait_for_theme(str(id), str(product.get("theme_id", "")), str(row.get("portrait", "")))
			items.append({"name": DataLoader.tr_key(str(row.get("name_key", id))), "icon": path, "level": -1})
	var theme_name := ThemeManager.theme_display_name(str(product.get("theme_id", "")))
	var note := Values._loc("外观权益已解锁；不包含人物解锁或军械属性。", "Visuals unlocked; hero ownership and arsenal stats are not included.") if is_theme else Values._loc("军械已入库，保留当前等级；新装备从 1 级开始培养。", "Your arsenal is ready. Existing levels are kept; new equipment starts at Lv.1.")
	if not is_theme:
		var target := SaveManager.get_premium_catch_up_level(PurchaseManager.set_id_for_product(product_id))
		if target > 1:
			var multiplier := float(DataLoader.get_table("economy").get("premium_equipment_catch_up", {}).get("cost_multiplier", 1.0))
			note += "\n" + Values._loc("追赶至各装备上限内的 Lv.%d：升级成本按原价 %.0f%% 计算。", "Catch up to Lv.%d, within each item's cap, at %.0f%% of the normal upgrade cost.") % [target, multiplier * 100]
	if not PurchaseManager.store_is_live():
		note += "\n" + Values._loc("本地演示购买 · 未发生真实扣款。", "Local demo purchase · No real charge.")
	var popup = load("res://ui/progression_result.gd").new()
	popup.payload = {"title": Values._loc("购买完成", "Purchase complete"), "name": str(product.get("name_" + language, "")),
		"level_text": Values._loc("永久外观已解锁", "Permanent visuals unlocked") if is_theme else Values._loc("完整军械已入库", "Arsenal added to collection"),
		"items": items, "rows": [], "note": note,
		"theme_text": Values._loc("主题外观 · %s", "Visual theme · %s") % theme_name,
		"primary": Values._loc("应用外观", "Apply look") if is_theme else Values._loc("装备整套并应用外观", "Equip arsenal & apply look"),
		"secondary": Values._loc("逐个角色换装", "Dress heroes")}
	popup.primary_action = apply
	popup.secondary_action = customize
	host.add_child(popup)
	return popup

func _ready() -> void:
	name = "ProgressionResult"
	layer = 140
	_build()

func _label(text: String, font_size: int, color: Color, node_name := "") -> Label:
	var label := Label.new()
	label.text = text
	if node_name != "":
		label.name = node_name
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var dim := TextureRect.new()
	dim.texture = load("res://assets/production/sprites/ui/ui_panel_skin.png")
	dim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dim.stretch_mode = TextureRect.STRETCH_SCALE
	dim.modulate = Color(0, 0, 0, 0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	panel = PanelContainer.new()
	panel.name = "ResultPanel"
	panel.set_meta("ui_modal_surface", true)
	panel.add_theme_stylebox_override("panel", UiKit.detail_panel_texture_style())
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	panel.add_child(margin)
	layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)
	var heading := _label(str(payload.title), 44, UiKit.GOLD, "ResultTitle")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(heading)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 24)
	layout.add_child(header)
	if str(payload.get("icon", "")) != "":
		if str(payload.get("table", "")) == "characters":
			var portrait := Control.new()
			header.add_child(portrait)
			UiKit.add_character_knee_crop_aligned(portrait, DataLoader.get_row("characters", str(payload.item_id)), Vector2(164, 164), 280, 4)
		else:
			var icon := UiKit.icon(str(payload.icon), Vector2(148, 148))
			header.add_child(icon)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.alignment = BoxContainer.ALIGNMENT_CENTER
	identity.add_theme_constant_override("separation", 14)
	header.add_child(identity)
	identity.add_child(_label(str(payload.name), 36, UiKit.TEXT_MAIN, "ResultName"))
	identity.add_child(_label(str(payload.level_text), 34, UiKit.GREEN, "ResultLevel"))
	scroll = ScrollContainer.new()
	scroll.name = "ResultScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.scroll_deadzone = 12
	layout.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	if payload.has("items"):
		var grid := GridContainer.new()
		grid.name = "GrantedItems"
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 14)
		body.add_child(grid)
		for item in payload.items:
			var card := PanelContainer.new()
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.add_theme_stylebox_override("panel", UiKit.icon_frame_texture_style(true))
			var card_inset := MarginContainer.new()
			for side in ["left", "right", "top", "bottom"]:
				card_inset.add_theme_constant_override("margin_" + side, 16)
			card.add_child(card_inset)
			var box := VBoxContainer.new()
			box.add_theme_constant_override("separation", 8)
			card_inset.add_child(box)
			box.add_child(UiKit.icon(str(item.icon), Vector2(0, 150)))
			var item_name := _label(str(item.name), 25, UiKit.TEXT_MAIN)
			item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			box.add_child(item_name)
			var status := "Lv.%d" % int(item.level) if int(item.level) >= 0 else Values._loc("外观可用", "Outfit available")
			var caption := _label(status, 25, UiKit.GREEN)
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			box.add_child(caption)
			grid.add_child(card)
		body.add_child(_label(str(payload.get("theme_text", "")), 26, UiKit.GOLD))
	else:
		body.add_child(_label(Values._loc("本次成长", "This upgrade") if payload.has("next_cost") else Values._loc("初始能力", "Starting attributes"), 26, UiKit.TEXT_MUTED))
		for row in payload.get("rows", []):
			var box := PanelContainer.new()
			box.add_theme_stylebox_override("panel", UiKit.pill_style(UiKit.CYAN, Color(0.02, 0.04, 0.05, 0.94)))
			var inset := MarginContainer.new()
			for side in ["left", "right", "top", "bottom"]:
				inset.add_theme_constant_override("margin_" + side, 16)
			box.add_child(inset)
			var line := HBoxContainer.new()
			line.add_theme_constant_override("separation", 18)
			inset.add_child(line)
			var stat_label := _label(str(row.label), 27, UiKit.TEXT_MAIN)
			line.add_child(stat_label)
			var values := _label((str(row.before) + "  →  " if str(row.before) != "" else "") + str(row.after), 29, UiKit.GREEN if row.positive else UiKit.GOLD)
			values.size_flags_horizontal = Control.SIZE_FILL
			values.custom_minimum_size.x = 300
			values.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			line.add_child(values)
			body.add_child(box)
		if payload.get("rows", []).is_empty():
			body.add_child(_label(Values._loc("永久等级已提升，本次没有直接战斗数值变化。", "Permanent level increased; no direct combat stats changed at this step."), 28, UiKit.TEXT_MAIN))
	if str(payload.get("note", "")) != "":
		body.add_child(_label(str(payload.note), 25, UiKit.TEXT_MUTED, "ResultNote"))
	if payload.has("cost"):
		var cost: Dictionary = payload.cost
		var cost_line := HBoxContainer.new()
		cost_line.alignment = BoxContainer.ALIGNMENT_CENTER
		cost_line.add_child(UiKit.icon(UiKit.currency_icon_path(str(cost.kind)), Vector2(32, 32)))
		var spent := _label(Values._loc("本次消耗 %d", "Spent: %d") % int(cost.amount), 24, UiKit.TEXT_MUTED)
		spent.name = "SpentCost"
		spent.autowrap_mode = TextServer.AUTOWRAP_OFF
		spent.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cost_line.add_child(spent)
		layout.add_child(cost_line)
	if payload.has("next_cost"):
		var caption := Values._loc("继续升级", "Upgrade again")
		if payload.maxed:
			caption = Values._loc("已达满级", "Maximum level")
		elif not payload.can_repeat:
			caption = Values._loc("资源不足", "Not enough resources")
		var next: Dictionary = payload.next_cost
		if not payload.maxed:
			caption += "  ·  %d %s" % [int(next.amount), Values._loc("金币", "gold") if next.kind == "gold" else Values._loc("经验", "XP")]
		_button(caption, "RepeatUpgrade", _repeat, true, bool(payload.can_repeat))
	elif primary_action.is_valid():
		_button(str(payload.primary), "ApplyPurchase", func(): _close(primary_action), true)
		_button(str(payload.secondary), "CustomizePurchase", func(): _close(secondary_action), false)
	_button(Values._loc("完成", "Done"), "CloseResult", func(): _close(), false)
	_layout.call_deferred()
	if not get_viewport().size_changed.is_connected(_layout):
		get_viewport().size_changed.connect(_layout)
	if not SettingsManager.reduced_effects_enabled():
		if _animation != null and _animation.is_valid():
			_animation.kill()
		panel.modulate.a = 0.15
		_animation = create_tween()
		_animation.tween_property(panel, "modulate:a", 1.0, 0.18)
	_busy = false

func _button(text: String, node_name: String, action: Callable, primary: bool, enabled := true) -> void:
	var button := Button.new()
	button.name = node_name
	button.text = text
	UiKit.apply_armored_button(button, primary, Vector2(680, 86), 24, enabled)
	button.custom_minimum_size = Vector2(0, 86)
	button.pressed.connect(action)
	layout.add_child(button)

func _layout() -> void:
	if not is_instance_valid(panel):
		return
	var size := get_viewport().get_visible_rect().size
	var safe := UiKit.safe_area_canvas_insets(get_viewport())
	var width := minf(860, size.x - safe.x - safe.z - 64)
	panel.size.x = width
	# Wrap first, measure second. Body scrolls; actions never leave the frame.
	await get_tree().process_frame
	if not is_instance_valid(panel):
		return
	var chrome := panel.get_combined_minimum_size().y
	var height := minf(chrome + body.get_combined_minimum_size().y + 8, size.y - safe.y - safe.w - 120)
	panel.size = Vector2(width, height)
	panel.position = Vector2(safe.x + (size.x - safe.x - safe.z - width) * 0.5, safe.y + (size.y - safe.y - safe.w - height) * 0.5)

func _repeat() -> void:
	if _busy or _closed or not repeat_action.is_valid():
		return
	_busy = true
	var next: Dictionary = repeat_action.call()
	if not next.is_empty():
		payload = next
		_build()
	else:
		_busy = false
		var button := find_child("RepeatUpgrade", true, false) as Button
		if button != null:
			button.disabled = true

func _close(action := Callable()) -> void:
	if _closed:
		return
	_closed = true
	if get_parent().has_meta("progression_result"):
		get_parent().remove_meta("progression_result")
	queue_free()
	if action.is_valid():
		action.call()
	elif finished.is_valid():
		finished.call()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
