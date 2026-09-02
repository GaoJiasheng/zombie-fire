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
const STORE_DETAIL_HERO_CELL_SIZE := Vector2(212, 268)
const STORE_DETAIL_WEAPON_CELL_SIZE := Vector2(212, 184)
const STORE_DETAIL_GEAR_CELL_SIZE := Vector2(432, 246)
const STORE_DETAIL_PORTRAIT_VIEW_SIZE := Vector2(200, 194)
const STORE_DETAIL_PORTRAIT_VISIBLE_HEIGHT := 248.0
const STORE_DETAIL_HEADER_TEXT_INSET := 16
const STORE_DETAIL_SECTION_MARGIN_LEFT := 36
const STORE_DETAIL_SECTION_MARGIN_RIGHT := 24
const STORE_DETAIL_SECTION_MARGIN_V := 22
const STORE_DETAIL_INFO_MARGIN_LEFT := 26
const STORE_DETAIL_INFO_MARGIN_RIGHT := 18
const STORE_DETAIL_INFO_MARGIN_V := 14
const STORE_DETAIL_GEAR_MARGIN_LEFT := 26
const STORE_DETAIL_GEAR_MARGIN_RIGHT := 18
const STORE_DETAIL_GEAR_MARGIN_V := 16
# Match both Store ScrollContainers' 12 px deadzone exactly: once the page has
# enough movement to scroll, the same gesture can no longer activate anything.
const STORE_TAP_MOVE_LIMIT := 12.0

var router: Node
var _dialog_layer: CanvasLayer
var _product_detail: Control
var _status_label: Label
var _appearance_selector: CanvasLayer
var _return_to := "menu"
var _return_payload := {}
var _open_appearance_on_ready := false
var _focus_series_id := ""
var _current_warzone_counter_series_id := ""
var _store_pointer_starts: Dictionary = {}
var _store_pointer_dragged: Dictionary = {}
var _store_release_blocks_activation := false
var _store_release_generation := 0


func setup(main: Node, payload := {}) -> void:
	router = main
	if payload is Dictionary:
		var requested_return := str(payload.get("return_to", "menu"))
		_return_to = requested_return if requested_return in ["menu", "settings", "collection", "loadout", "result"] else "menu"
		var raw_return_payload: Variant = payload.get("return_payload", {})
		_return_payload = raw_return_payload.duplicate(true) if raw_return_payload is Dictionary else {}
		_open_appearance_on_ready = bool(payload.get("open_theme_appearance", false))
		_focus_series_id = str(payload.get("focus_series_id", "")).strip_edges()


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
	if _focus_series_id != "":
		call_deferred("_focus_requested_series")
	if _open_appearance_on_ready:
		call_deferred("_open_theme_appearance")


func _input(event: InputEvent) -> void:
	# ScrollContainer correctly owns the physical movement, but iOS can deliver a
	# touch release near the original press coordinate after one or more separate
	# ScreenDrag events. Track the complete pointer stream at page scope so a
	# crossed drag threshold cancels every card/button activation for that release.
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_store_pointer_pressed(touch.index, touch.position)
		else:
			_store_pointer_released(touch.index, touch.position)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_store_pointer_moved(drag.index, drag.position)
	elif event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_button.pressed:
			_store_pointer_pressed(-1, mouse_button.position)
		else:
			_store_pointer_released(-1, mouse_button.position)
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_store_pointer_moved(-1, motion.position)


func _store_pointer_pressed(pointer_id: int, position: Vector2) -> void:
	_store_release_generation += 1
	_store_release_blocks_activation = false
	_store_pointer_starts[pointer_id] = position
	_store_pointer_dragged[pointer_id] = false


func _store_pointer_moved(pointer_id: int, position: Vector2) -> void:
	if not _store_pointer_starts.has(pointer_id):
		return
	var start := _store_pointer_starts[pointer_id] as Vector2
	if position.distance_to(start) > STORE_TAP_MOVE_LIMIT:
		_store_pointer_dragged[pointer_id] = true


func _store_pointer_released(pointer_id: int, position: Vector2) -> void:
	_store_pointer_moved(pointer_id, position)
	_store_release_blocks_activation = bool(_store_pointer_dragged.get(pointer_id, false))
	_store_pointer_starts.erase(pointer_id)
	_store_pointer_dragged.erase(pointer_id)
	_store_release_generation += 1
	var release_generation := _store_release_generation
	call_deferred("_clear_store_release_block", release_generation)


func _clear_store_release_block(release_generation: int) -> void:
	if release_generation == _store_release_generation:
		_store_release_blocks_activation = false


func _store_activation_is_drag() -> bool:
	if _store_release_blocks_activation:
		return true
	for dragged in _store_pointer_dragged.values():
		if bool(dragged):
			return true
	return false


func _run_store_tap(action: Callable) -> void:
	if _store_activation_is_drag():
		return
	action.call()


func _loc(zh: String, en: String) -> String:
	return en if LocalizationManager.is_english() else zh


func _format_store_number(value: int) -> String:
	var digits := str(maxi(value, 0))
	var parts: Array[String] = []
	while digits.length() > 3:
		parts.push_front(digits.substr(digits.length() - 3, 3))
		digits = digits.substr(0, digits.length() - 3)
	parts.push_front(digits)
	return ",".join(parts)


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
	$Root/VBox/Footer/ResetButton.text = _loc("清空演示", "Reset")
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

	var revealed_series := PurchaseManager.store_series_ids()
	var warzone_counter := PurchaseManager.current_warzone_counter_offer()
	_current_warzone_counter_series_id = str(warzone_counter.get("series_id", ""))
	if _current_warzone_counter_series_id != "" and revealed_series.has(_current_warzone_counter_series_id):
		revealed_series.erase(_current_warzone_counter_series_id)
		revealed_series.push_front(_current_warzone_counter_series_id)
	if not revealed_series.is_empty():
		_status_label = UiKit.label(_ownership_status(), 18, UiKit.CYAN, 2)
		if LocalizationManager.is_english():
			# The ownership sentence has two semantic clauses. Give each clause its
			# own centered line so the label never establishes a 1242 px minimum.
			_status_label.text = _status_label.text.replace(" · ", "\n")
		_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_status_label.custom_minimum_size = Vector2(0, 54)
		content.add_child(_status_label)
	else:
		_status_label = null
		content.add_child(_locked_store_empty_state())

	for series_id in revealed_series:
		content.add_child(_series_header(series_id))
		for product_id in PurchaseManager.display_offer_ids(series_id):
			content.add_child(_product_card(PurchaseManager.product(product_id)))
		if PurchaseManager.is_arsenal_owned(series_id):
			content.add_child(_owned_set_panel(PurchaseManager.set_id_for_series(series_id)))
		elif PurchaseManager.is_theme_owned(series_id):
			content.add_child(_owned_theme_panel(series_id))
	_configure_store_scroll_surface(content)
	if _focus_series_id != "":
		call_deferred("_focus_requested_series")

func _focus_requested_series() -> void:
	if _focus_series_id == "":
		return
	var content := $Root/VBox/ScrollWrap/Scroll/Content as VBoxContainer
	for child in content.get_children():
		if str(child.get_meta("store_series_id", "")) == _focus_series_id:
			($Root/VBox/ScrollWrap/Scroll as ScrollContainer).ensure_control_visible(child as Control)
			return


func _locked_store_empty_state() -> PanelContainer:
	var tiers := _store_unlock_tiers()
	var panel := PanelContainer.new()
	panel.name = "LockedStoreEmptyState"
	panel.set_meta("store_empty_state", true)
	panel.add_theme_stylebox_override("panel", UiKit.panel_texture_style(28.0))
	panel.custom_minimum_size = Vector2(0, 1040)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	call_deferred("_fit_locked_store_empty_state", panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_top", 42)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_bottom", 42)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
	margin.add_child(box)

	var lock_center := CenterContainer.new()
	lock_center.custom_minimum_size = Vector2(0, 112)
	box.add_child(lock_center)
	var lock_icon := UiKit.icon("res://assets/production/sprites/ui/icon_lock.png", Vector2(96, 96))
	lock_icon.modulate = Color(1.08, 0.92, 0.58, 1.0)
	lock_center.add_child(lock_icon)

	var title := UiKit.label(LocalizationManager.text("终焉军械库尚未解密"), 34, UiKit.TEXT_MAIN, 4)
	title.name = "EmptyStateTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var body := UiKit.label(
		LocalizationManager.text("继续推进战役，即可逐档解密主题与终焉军械。"),
		20,
		UiKit.GREY_300,
		2
	)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(0, 62)
	box.add_child(body)

	if not tiers.is_empty():
		var nearest: Dictionary = tiers[0]
		panel.set_meta("nearest_clear_level", int(nearest.get("clear_level", 0)))
		panel.set_meta("nearest_character_level", int(nearest.get("any_character_level", 0)))
		box.add_child(_build_store_unlock_roadmap(tiers))
		var later_lines: Array[String] = []
		var later_clear_levels: Array[int] = []
		for index in range(1, tiers.size()):
			var later: Dictionary = tiers[index]
			later_lines.append(_store_unlock_condition(later, true))
			later_clear_levels.append(int(later.get("clear_level", 0)))
		panel.set_meta("later_clear_levels", later_clear_levels)
		if not later_lines.is_empty():
			var later_copy := UiKit.label("  ·  ".join(later_lines), 15, UiKit.GREY_300, 2)
			later_copy.name = "LaterUnlockText"
			later_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			later_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			later_copy.custom_minimum_size = Vector2(0, 48)
			box.add_child(later_copy)

	var restore_hint := UiKit.label(
		LocalizationManager.text("已购买过？可使用下方“恢复购买”重新同步。"),
		17,
		UiKit.SUCCESS,
		2
	)
	restore_hint.name = "RestoreHint"
	restore_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restore_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(restore_hint)
	return panel


func _fit_locked_store_empty_state(panel: PanelContainer) -> void:
	# The empty state is the complete new-player store experience. Fit it to the
	# real ScrollContainer viewport so tall phones never end in a half-screen
	# black void. The deferred callback only measures controls after both nodes
	# have entered the tree, avoiding Control.get_rect() warnings in headless runs.
	if not is_instance_valid(panel) or not panel.is_inside_tree():
		return
	await get_tree().process_frame
	if not is_instance_valid(panel) or not panel.is_inside_tree():
		return
	var scroll := $Root/VBox/ScrollWrap/Scroll as ScrollContainer
	if not scroll.is_inside_tree():
		return
	panel.custom_minimum_size.y = maxf(1040.0, scroll.size.y - 2.0)


func _build_store_unlock_roadmap(tiers: Array[Dictionary]) -> PanelContainer:
	var cleared_level := _store_cleared_level()
	var final_level := int(tiers[tiers.size() - 1].get("clear_level", 1))
	var current_target_index := tiers.size() - 1
	for index in range(tiers.size()):
		if cleared_level < int(tiers[index].get("clear_level", 0)):
			current_target_index = index
			break

	var roadmap := PanelContainer.new()
	roadmap.name = "UnlockRoadmap"
	roadmap.set_meta("clear_level", cleared_level)
	roadmap.set_meta("unlock_clear_levels", tiers.map(func(tier: Dictionary) -> int: return int(tier.get("clear_level", 0))))
	roadmap.add_theme_stylebox_override("panel", UiKit.hint_texture_style(true))
	roadmap.custom_minimum_size = Vector2(0, 286)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 18)
	roadmap.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	margin.add_child(stack)

	var heading_row := HBoxContainer.new()
	heading_row.add_theme_constant_override("separation", 16)
	stack.add_child(heading_row)
	var heading := UiKit.label(LocalizationManager.text("解锁路线图"), 18, UiKit.GOLD, 3)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(heading)
	var progress_text_value := LocalizationManager.text("战役进度：尚未通关") if cleared_level <= 0 else LocalizationManager.text("战役进度：已通关第 %d 关") % cleared_level
	var progress_text := UiKit.label(progress_text_value, 15, UiKit.CYAN, 2)
	progress_text.name = "CampaignProgressText"
	progress_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	heading_row.add_child(progress_text)

	var progress := ProgressBar.new()
	progress.name = "UnlockProgressBar"
	progress.custom_minimum_size = Vector2(0, 18)
	progress.max_value = maxf(float(final_level), 1.0)
	progress.value = clampf(float(cleared_level), 0.0, progress.max_value)
	progress.show_percentage = false
	# Art-driven rail: visible UI is texture-backed, so tint the shared plate skin
	# rather than painting solid boxes.
	var progress_bg := UiKit.plate_style(UiKit.CYAN)
	progress.add_theme_stylebox_override("background", progress_bg)
	var progress_fill := UiKit.plate_style(UiKit.GOLD)
	progress.add_theme_stylebox_override("fill", progress_fill)
	stack.add_child(progress)

	var tier_row := HBoxContainer.new()
	tier_row.name = "UnlockTierRow"
	tier_row.add_theme_constant_override("separation", 10)
	stack.add_child(tier_row)
	for index in range(tiers.size()):
		var tier: Dictionary = tiers[index]
		var clear_level := int(tier.get("clear_level", 0))
		var unlocked := cleared_level >= clear_level
		var current := not unlocked and index == current_target_index
		var tier_box := VBoxContainer.new()
		tier_box.name = "UnlockTier%02d" % (index + 1)
		tier_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tier_box.set_meta("clear_level", clear_level)
		tier_box.set_meta("state", "unlocked" if unlocked else "current" if current else "locked")
		tier_box.alignment = BoxContainer.ALIGNMENT_CENTER
		tier_box.add_theme_constant_override("separation", 3)
		tier_row.add_child(tier_box)

		var marker_center := CenterContainer.new()
		marker_center.custom_minimum_size = Vector2(0, 42)
		tier_box.add_child(marker_center)
		var marker := PanelContainer.new()
		marker.custom_minimum_size = Vector2(34, 34)
		# A 34px node is far too small for the nine-patch plate skin to read, so use a
		# tinted icon instead of a panel style: art-driven and legible at this size.
		var marker_icon := TextureRect.new()
		marker_icon.texture = load("res://assets/production/sprites/ui/ui_plate_skin.png")
		marker_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		marker_icon.stretch_mode = TextureRect.STRETCH_SCALE
		marker_icon.custom_minimum_size = Vector2(26, 26)
		marker_icon.modulate = (
			UiKit.SUCCESS if unlocked
			else UiKit.GOLD if current
			else Color(0.38, 0.45, 0.52, 0.95)
		)
		marker_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.add_child(marker_icon)
		marker_center.add_child(marker)

		var level_copy := UiKit.label(LocalizationManager.text("第 %d 关") % clear_level, 15, UiKit.TEXT_MAIN, 2)
		level_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tier_box.add_child(level_copy)
		var state_copy_value := LocalizationManager.text("已解锁") if unlocked else LocalizationManager.text("当前目标") if current else LocalizationManager.text("还差 %d 关") % maxi(0, clear_level - cleared_level)
		var state_copy := UiKit.label(state_copy_value, 13, UiKit.SUCCESS if unlocked else UiKit.GOLD if current else UiKit.TEXT_MUTED, 2)
		state_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		state_copy.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		tier_box.add_child(state_copy)

	var nearest: Dictionary = tiers[current_target_index]
	var nearest_copy := UiKit.label(_store_unlock_condition(nearest, false), 18, UiKit.TEXT_MAIN, 2)
	nearest_copy.name = "NearestUnlockText"
	nearest_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nearest_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nearest_copy.custom_minimum_size = Vector2(0, 42)
	stack.add_child(nearest_copy)
	return roadmap


func _store_cleared_level() -> int:
	var highest := 0
	for level_value in DataLoader.get_table("levels"):
		var level: Dictionary = level_value
		var level_id := str(level.get("id", ""))
		if level_id != "" and SaveManager.get_level_stars(level_id) > 0:
			highest = maxi(highest, int(DataLoader.level_number(level_id)))
	return highest


func _store_unlock_tiers() -> Array[Dictionary]:
	var tiers: Array[Dictionary] = []
	var catalog_series := PurchaseManager.catalog_series_ids()
	for set_id_var in DataLoader.get_table("premium_sets").keys():
		var set_row := DataLoader.get_row("premium_sets", str(set_id_var))
		var series_id := str(set_row.get("series_id", ""))
		if series_id == "" or not catalog_series.has(series_id):
			continue
		var unlock_value: Variant = set_row.get("store_unlock", {})
		if not unlock_value is Dictionary:
			continue
		var unlock: Dictionary = unlock_value
		var clear_level := int(unlock.get("clear_level", 0))
		if clear_level <= 0:
			continue
		tiers.append({
			"clear_level": clear_level,
			"any_character_level": int(unlock.get("any_character_level", 0)),
		})
	tiers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_clear := int(a.get("clear_level", 0))
		var b_clear := int(b.get("clear_level", 0))
		if a_clear != b_clear:
			return a_clear < b_clear
		return int(a.get("any_character_level", 0)) < int(b.get("any_character_level", 0))
	)
	return tiers


func _store_unlock_condition(tier: Dictionary, compact: bool) -> String:
	var clear_level := int(tier.get("clear_level", 0))
	var character_level := int(tier.get("any_character_level", 0))
	if compact:
		if character_level > 0:
			return LocalizationManager.text("第 %d 关 + 任意角色 %d 级") % [clear_level, character_level]
		return LocalizationManager.text("第 %d 关") % clear_level
	if character_level > 0:
		return LocalizationManager.text("通关第 %d 关，并将任意角色提升至 %d 级") % [clear_level, character_level]
	return LocalizationManager.text("通关第 %d 关") % clear_level


func _configure_store_scroll_surface(root: Node) -> void:
	# Every visible list surface must let the parent ScrollContainer observe the
	# same touch sequence. BaseButton keeps stationary taps, while Godot cancels
	# its pressed action after the scroll deadzone is crossed.
	if root is Control and (root as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
		(root as Control).mouse_filter = Control.MOUSE_FILTER_PASS
	if root is BaseButton:
		root.set_meta("store_scroll_drag_passthrough", true)
	for child in root.get_children():
		_configure_store_scroll_surface(child)


func _series_header(series_id: String) -> PanelContainer:
	var set_row := PurchaseManager.set_for_series(series_id)
	var is_current_counter := series_id == _current_warzone_counter_series_id
	var panel := PanelContainer.new()
	panel.name = "Series_%s" % series_id
	panel.set_meta("store_series_id", series_id)
	panel.set_meta("current_warzone_counter", is_current_counter)
	panel.add_theme_stylebox_override("panel", UiKit.hint_texture_style(false))
	panel.custom_minimum_size = Vector2(0, 124 if is_current_counter else 72)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 14)
	box.add_child(title_row)
	var label := UiKit.label(str(set_row.get(
		"store_title_en" if LocalizationManager.is_english() else "store_title_zh",
		series_id
	)), 24, UiKit.GOLD, 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size = Vector2(0, 54)
	title_row.add_child(label)
	if is_current_counter:
		var badge := UiKit.semantic_tag_pill(_loc("当前战区克制", "Counters Current Warzone"), "status", 14)
		badge.name = "CurrentWarzoneCounterBadge"
		badge.set_meta("counter_series_id", series_id)
		badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(badge)
	return panel


func _store_title() -> String:
	return LocalizationManager.text("终焉军械库")


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
	return _loc(
		"已解密系列可永久购买与恢复",
		"Revealed series are permanent and restorable"
	)


func _product_card(row: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var product_id := str(row.get("id", ""))
	var offer_role := str(row.get("offer_role", ""))
	panel.name = "Product_%s" % product_id.replace(".", "_")
	panel.set_meta("store_product_id", product_id)
	panel.set_meta("store_card_opens_detail", true)
	panel.add_theme_stylebox_override("panel", UiKit.panel_texture_style(22.0))
	panel.custom_minimum_size = Vector2(0, 430 if offer_role != "theme" else 390)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.focus_mode = Control.FOCUS_ALL
	panel.tooltip_text = _loc("查看完整商品详情", "View complete product details")
	panel.gui_input.connect(_on_product_card_input.bind(product_id, panel))
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 22)
	panel.add_child(margin)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	margin.add_child(hbox)

	var preview := _product_preview(row)
	hbox.add_child(preview)

	var copy := VBoxContainer.new()
	copy.name = "Copy"
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 12)
	hbox.add_child(copy)
	var name := UiKit.label(str(row.get("name_en" if LocalizationManager.is_english() else "name_zh", "")), 25, UiKit.TEXT_MAIN, 3)
	_prepare_store_card_copy(name)
	copy.add_child(name)
	var subtitle := UiKit.label(str(row.get("subtitle_en" if LocalizationManager.is_english() else "subtitle_zh", "")), 17, UiKit.GREY_300, 2)
	_prepare_store_card_copy(subtitle)
	copy.add_child(subtitle)
	if offer_role != "theme":
		var set_row := DataLoader.get_row("premium_sets", str(row.get("arsenal_set_id", "")))
		var dominance := UiKit.label(str(set_row.get(
			"dominance_en" if LocalizationManager.is_english() else "dominance_zh",
			""
		)), 16, UiKit.GOLD, 2)
		dominance.name = "DominanceRange"
		_prepare_store_card_copy(dominance)
		dominance.custom_minimum_size = Vector2(0, 58)
		copy.add_child(dominance)
		var quote := PurchaseManager.premium_catch_up_quote_for_series(str(row.get("series_id", "")))
		var catch_up_level := int(quote.get("catch_up_level", 1))
		var catch_up_gold := int(quote.get("catch_up_gold", 0))
		var catch_up := UiKit.label(
			_loc(
				"整套追平至 Lv%d · 需 %s 金币（已含追赶折扣）" % [catch_up_level, _format_store_number(catch_up_gold)],
				"Catch up to Lv%d · %s Gold" % [catch_up_level, _format_store_number(catch_up_gold)]
			),
			15,
			UiKit.CYAN,
			2
		)
		catch_up.name = "CatchUpCostText"
		_prepare_store_card_copy(catch_up)
		copy.add_child(catch_up)
	var contents := UiKit.label(
		_loc("永久解锁 · 可恢复 · 不含消耗品", "Permanent · Restorable · No consumables"),
		16,
		UiKit.SUCCESS,
		2
	)
	_prepare_store_card_copy(contents)
	copy.add_child(contents)
	var detail_hint := UiKit.label(
		_loc("点击商品查看全部内容", "Tap product to view everything included"),
		14,
		UiKit.CYAN,
		2
	)
	detail_hint.name = "DetailHint"
	_prepare_store_card_copy(detail_hint)
	copy.add_child(detail_hint)
	var buy := Button.new()
	buy.name = "Buy_" + str(row.get("id", "")).replace(".", "_")
	buy.focus_mode = Control.FOCUS_NONE
	buy.text = _loc("演示购买  ", "Demo Buy  ") + str(row.get("mock_price_en" if LocalizationManager.is_english() else "mock_price_zh", ""))
	UiKit.apply_armored_button(buy, true, Vector2(484, 102), 20, true)
	# button_down is emitted before the event bubbles to the card. Mark that
	# origin explicitly because a bubbled touch position remains relative to its
	# original child control, not to the enclosing product panel.
	buy.button_down.connect(_on_product_action_button_down.bind(panel))
	buy.pressed.connect(_run_store_tap.bind(_confirm_purchase.bind(str(row.get("id", "")))))
	copy.add_child(buy)
	return panel


func _prepare_store_card_copy(label: Label) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _on_product_action_button_down(panel: PanelContainer) -> void:
	panel.set_meta("store_detail_press_started_on_action", true)
	panel.set_meta("store_detail_release_blocked_until_next_press", true)


func _on_product_card_input(event: InputEvent, product_id: String, panel: PanelContainer) -> void:
	var activate := false
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			if bool(panel.get_meta("store_detail_press_started_on_action", false)) or _product_card_event_hits_action(event.position, panel):
				panel.set_meta("store_detail_press_started_on_action", true)
				panel.set_meta("store_detail_release_blocked_until_next_press", true)
				return
			panel.remove_meta("store_detail_press_started_on_action")
			panel.remove_meta("store_detail_release_blocked_until_next_press")
			panel.set_meta("store_detail_press_position", event.position)
			return
		if bool(panel.get_meta("store_detail_press_started_on_action", false)) or bool(panel.get_meta("store_detail_release_blocked_until_next_press", false)):
			panel.remove_meta("store_detail_press_started_on_action")
			panel.remove_meta("store_detail_press_position")
			return
		if _product_card_event_hits_action(event.position, panel):
			panel.remove_meta("store_detail_press_position")
			return
		var press_position: Variant = panel.get_meta("store_detail_press_position", event.position)
		panel.remove_meta("store_detail_press_position")
		activate = not _store_activation_is_drag() and press_position is Vector2 and (event.position - (press_position as Vector2)).length() <= STORE_TAP_MOVE_LIMIT
	elif event is InputEventScreenTouch:
		if event.pressed:
			if bool(panel.get_meta("store_detail_press_started_on_action", false)) or _product_card_event_hits_action(event.position, panel):
				panel.set_meta("store_detail_press_started_on_action", true)
				panel.set_meta("store_detail_release_blocked_until_next_press", true)
				return
			panel.remove_meta("store_detail_press_started_on_action")
			panel.remove_meta("store_detail_release_blocked_until_next_press")
			panel.set_meta("store_detail_press_position", event.position)
			return
		if bool(panel.get_meta("store_detail_press_started_on_action", false)) or bool(panel.get_meta("store_detail_release_blocked_until_next_press", false)):
			panel.remove_meta("store_detail_press_started_on_action")
			panel.remove_meta("store_detail_press_position")
			return
		if _product_card_event_hits_action(event.position, panel):
			panel.remove_meta("store_detail_press_position")
			return
		var press_position: Variant = panel.get_meta("store_detail_press_position", event.position)
		panel.remove_meta("store_detail_press_position")
		activate = not _store_activation_is_drag() and press_position is Vector2 and (event.position - (press_position as Vector2)).length() <= STORE_TAP_MOVE_LIMIT
	elif event is InputEventKey:
		activate = event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_SPACE]
	if not activate:
		return
	panel.accept_event()
	AudioManager.play_sfx("ui_click")
	_show_product_detail(product_id)


func _product_card_event_hits_action(local_position: Vector2, panel: PanelContainer) -> bool:
	var action := panel.find_child("Buy_*", true, false) as BaseButton
	if action == null or not action.visible:
		return false
	var global_position := panel.get_global_transform_with_canvas() * local_position
	return action.get_global_rect().has_point(global_position)


func _show_product_detail(product_id: String) -> void:
	var row := PurchaseManager.product(product_id)
	if row.is_empty():
		return
	var series_id := str(row.get("series_id", ""))
	# The detail route obeys exactly the same reveal/offer gate as the list. This
	# prevents a debug call or stale card from leaking a future premium series.
	var is_current_offer := PurchaseManager.display_offer_ids(series_id).has(product_id)
	if not PurchaseManager.store_series_ids().has(series_id):
		return
	if not is_current_offer and not PurchaseManager.is_product_owned(product_id):
		return
	_close_product_detail()
	# The modal has its own dimmed backdrop. Remove the store footer's active
	# touch targets while it is open so hidden controls cannot intercept assistive
	# input or overlap the fixed detail purchase action.
	$Root/VBox/Footer.visible = false

	var theme_id := str(row.get("theme_id", "default"))
	var accent := _theme_preview_accent(theme_id)
	var detail := Control.new()
	detail.name = "StoreProductDetail"
	detail.set_anchors_preset(Control.PRESET_FULL_RECT)
	detail.mouse_filter = Control.MOUSE_FILTER_STOP
	detail.z_index = 96
	detail.set_meta("store_detail_product_id", product_id)
	detail.set_meta("store_detail_series_id", series_id)
	detail.set_meta("store_detail_theme_id", theme_id)
	detail.set_meta("store_detail_offer_role", str(row.get("offer_role", "")))
	add_child(detail)
	_product_detail = detail

	var dim := TextureRect.new()
	dim.name = "DismissBackground"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.texture = load("res://assets/production/sprites/ui/ui_panel_skin.png")
	dim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dim.stretch_mode = TextureRect.STRETCH_SCALE
	dim.modulate = Color(0.005, 0.008, 0.014, 0.94)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_product_detail_dim_input)
	detail.add_child(dim)

	var safe := UiKit.safe_area_canvas_insets(get_viewport())
	var modal_shift := UiKit.tall_modal_shift(get_viewport_rect().size.y, 96.0, 0.24)
	var panel := PanelContainer.new()
	panel.name = "DetailPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 38.0 + safe.x
	panel.offset_top = 66.0 + safe.y + modal_shift
	panel.offset_right = -38.0 - safe.z
	panel.offset_bottom = -66.0 - safe.w + modal_shift
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", UiKit.detail_panel_texture_style())
	detail.add_child(panel)

	var outer_margin := MarginContainer.new()
	outer_margin.name = "OuterMargin"
	for side in ["left", "top", "right", "bottom"]:
		outer_margin.add_theme_constant_override("margin_%s" % side, 28)
	panel.add_child(outer_margin)
	var outer := VBoxContainer.new()
	outer.name = "Layout"
	outer.add_theme_constant_override("separation", 14)
	outer_margin.add_child(outer)

	outer.add_child(_store_detail_header(row, accent))
	var scroll := ScrollContainer.new()
	scroll.name = "DetailScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 12
	outer.add_child(scroll)
	var content := VBoxContainer.new()
	content.name = "DetailContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)
	_populate_store_product_detail(content, row, accent)
	# Detail pages are a second, independent scrolling surface. Their nested
	# section, hero, weapon and gear panels must pass the drag sequence just like
	# the catalog cards do, otherwise the visible scrollbar cannot be touched.
	_configure_store_scroll_surface(content)
	outer.add_child(_store_detail_actions(row, is_current_offer))


func _store_detail_header(row: Dictionary, accent: Color) -> Control:
	var header := HBoxContainer.new()
	header.name = "DetailHeader"
	header.add_theme_constant_override("separation", 14)
	var text_inset := Control.new()
	text_inset.name = "HeaderTextInset"
	text_inset.custom_minimum_size = Vector2(STORE_DETAIL_HEADER_TEXT_INSET, 0)
	text_inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(text_inset)
	var copy := VBoxContainer.new()
	copy.name = "HeaderCopy"
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 6)
	header.add_child(copy)
	var title := UiKit.label(
		str(row.get("name_en" if LocalizationManager.is_english() else "name_zh", "")),
		29,
		UiKit.TEXT_MAIN,
		4
	)
	title.name = "ProductTitle"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(0, 58 if not LocalizationManager.is_english() else 88)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	copy.add_child(title)
	var role := str(row.get("offer_role", ""))
	var type_text := _loc("视觉主题", "VISUAL THEME")
	if role == "arsenal_complete":
		type_text = _loc("主题 + 终焉四件套", "THEME + APOCALYPSE SET")
	elif role == "arsenal_upgrade":
		type_text = _loc("主题拥有者军械升级", "THEME-OWNER ARSENAL UPGRADE")
	var type_line := UiKit.label(type_text, 15, accent, 2)
	type_line.name = "ProductType"
	copy.add_child(type_line)
	var close := Button.new()
	close.name = "CloseButton"
	close.focus_mode = Control.FOCUS_ALL
	close.tooltip_text = _loc("关闭详情", "Close details")
	UiKit.apply_armored_button(close, false, Vector2(110, 88), 20, true)
	UiKit.apply_close_glyph(close)
	close.pressed.connect(_close_product_detail)
	header.add_child(close)
	return header


func _populate_store_product_detail(content: VBoxContainer, row: Dictionary, accent: Color) -> void:
	var theme_id := str(row.get("theme_id", "default"))
	var set_id := str(row.get("arsenal_set_id", ""))
	var grants_theme := _product_grants_entitlement(row, str(DataLoader.get_row("premium_sets", set_id).get("theme_entitlement", "")))
	var grants_arsenal := _product_grants_entitlement(row, str(DataLoader.get_row("premium_sets", set_id).get("entitlement", "")))

	var summary := _store_detail_section("SummarySection", _loc("商品说明", "Product Overview"), accent)
	content.add_child(summary)
	var summary_body := _store_detail_section_body(summary)
	var subtitle := UiKit.label(
		str(row.get("subtitle_en" if LocalizationManager.is_english() else "subtitle_zh", "")),
		18,
		UiKit.TEXT_MAIN,
		2
	)
	subtitle.name = "ProductSummary"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_body.add_child(subtitle)
	var promise_text := _loc(
		"永久解锁 · 可恢复 · 不含消耗品 · 本页为本地演示，不连接 Apple、不会扣款",
		"Permanent · Restorable · No consumables · Local demo only; Apple is not connected and no charge occurs"
	)
	var promise := UiKit.label(promise_text, 15, UiKit.SUCCESS, 2)
	promise.name = "PermanentPromise"
	promise.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_body.add_child(promise)
	if str(row.get("offer_role", "")) == "arsenal_upgrade":
		var upgrade_note := UiKit.label(
			_loc("主题权益已拥有，本商品不会重复计价；只补齐下方四件终焉军械。", "Your theme is already owned and is not charged twice; this offer adds only the four Apocalypse items below."),
			16,
			UiKit.GOLD,
			2
		)
		upgrade_note.name = "UpgradePricingNote"
		upgrade_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		summary_body.add_child(upgrade_note)

	if grants_theme:
		_add_store_theme_detail_sections(content, theme_id, accent)
	if grants_arsenal:
		_add_store_arsenal_detail_sections(content, set_id, accent)


func _add_store_theme_detail_sections(content: VBoxContainer, theme_id: String, accent: Color) -> void:
	var theme_section := _store_detail_section("ThemeCoverageSection", _loc("主题包含内容", "Theme Contents"), accent)
	content.add_child(theme_section)
	var theme_body := _store_detail_section_body(theme_section)
	var description := UiKit.label(ThemeManager.theme_description(theme_id), 17, UiKit.GREY_300, 2)
	description.name = "ThemeDescription"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	theme_body.add_child(description)
	var coverage := GridContainer.new()
	coverage.name = "ThemeCoverageGrid"
	coverage.columns = 2
	coverage.add_theme_constant_override("h_separation", 12)
	coverage.add_theme_constant_override("v_separation", 10)
	theme_body.add_child(coverage)
	for spec in [
		[_loc("全局界面", "Global UI"), _loc("菜单、面板、按钮与资源栏", "Menus, panels, buttons and resource HUD")],
		[_loc("基地防线", "Base Defense"), _loc("主题边框、战斗 HUD 与结算外观", "Themed frames, battle HUD and results")],
		[_loc("八把免费武器", "8 Free Weapons"), _loc("主题枪械配色与弹体战斗色彩", "Theme colorways and projectile palette")],
		[_loc("专属开火特征", "Fire Signature"), _loc("角色背挂特征与战斗光效", "Rear character signature and combat effects")],
	]:
		coverage.add_child(_store_detail_info_card(str(spec[0]), str(spec[1]), accent))
	var visual_only := UiKit.label(
		_loc("纯外观权益：不增加有效战力，不改变数值。", "Visual-only entitlement: no Effective Power or combat-stat increase."),
		16,
		UiKit.WARNING,
		2
	)
	visual_only.name = "VisualOnlyDisclosure"
	visual_only.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	theme_body.add_child(visual_only)

	var heroes_section := _store_detail_section("HeroOutfitsSection", _loc("4 套角色战衣", "4 Hero Outfits"), accent)
	content.add_child(heroes_section)
	var hero_grid := GridContainer.new()
	hero_grid.name = "DetailHeroGrid"
	hero_grid.columns = 4
	hero_grid.add_theme_constant_override("h_separation", 12)
	_store_detail_section_body(heroes_section).add_child(hero_grid)
	var character_ids: Array[String] = []
	for character_id_var in DataLoader.get_table("characters").keys():
		character_ids.append(str(character_id_var))
	character_ids.sort()
	for character_id in character_ids:
		hero_grid.add_child(_store_detail_hero_card(character_id, theme_id, accent))

	var weapons_section := _store_detail_section("WeaponSkinsSection", _loc("8 把免费武器主题外观", "Theme Looks for 8 Free Weapons"), accent)
	content.add_child(weapons_section)
	var weapon_grid := GridContainer.new()
	weapon_grid.name = "DetailWeaponSkinGrid"
	weapon_grid.columns = 4
	weapon_grid.add_theme_constant_override("h_separation", 12)
	weapon_grid.add_theme_constant_override("v_separation", 10)
	_store_detail_section_body(weapons_section).add_child(weapon_grid)
	var weapon_ids: Array[String] = []
	var weapons: Dictionary = DataLoader.get_table("weapons")
	for weapon_id_var in weapons.keys():
		var weapon_id := str(weapon_id_var)
		var weapon_row: Dictionary = weapons.get(weapon_id, {})
		if str(weapon_row.get("premium_entitlement", "")) == "":
			weapon_ids.append(weapon_id)
	weapon_ids.sort()
	for weapon_id in weapon_ids:
		weapon_grid.add_child(_store_detail_weapon_skin_card(weapon_id, theme_id, accent))


func _add_store_arsenal_detail_sections(content: VBoxContainer, set_id: String, accent: Color) -> void:
	var set_row := DataLoader.get_row("premium_sets", set_id)
	var gear_section := _store_detail_section("ArsenalContentsSection", _loc("终焉军械 · 4 件", "Apocalypse Arsenal · 4 Items"), accent)
	content.add_child(gear_section)
	var gear_grid := GridContainer.new()
	gear_grid.name = "DetailArsenalGearGrid"
	gear_grid.columns = 2
	gear_grid.add_theme_constant_override("h_separation", 14)
	gear_grid.add_theme_constant_override("v_separation", 12)
	_store_detail_section_body(gear_section).add_child(gear_grid)
	for slot_spec in [["weapon", "weapons"], ["armor", "armors"], ["chip", "chips"], ["pet", "pets"]]:
		var slot := str(slot_spec[0])
		var table := str(slot_spec[1])
		gear_grid.add_child(_store_detail_gear_card(table, slot, str(set_row.get(slot, "")), accent))

	var synergy := _store_detail_section("SetSynergySection", _loc("套装协同与整套优势", "Set Synergy & Full-Set Edge"), accent)
	content.add_child(synergy)
	var synergy_body := _store_detail_section_body(synergy)
	var bonus := UiKit.label(str(set_row.get(
		"two_piece_description_en" if LocalizationManager.is_english() else "two_piece_description_zh",
		""
	)), 17, UiKit.CYAN, 2)
	bonus.name = "SetBonusDescription"
	bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	synergy_body.add_child(bonus)
	var dominance := UiKit.label(str(set_row.get(
		"dominance_en" if LocalizationManager.is_english() else "dominance_zh",
		""
	)), 16, UiKit.GOLD, 2)
	dominance.name = "SetDominanceDescription"
	dominance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	synergy_body.add_child(dominance)

	var growth := _store_detail_section("GrowthSection", _loc("等级、外观进化与强度承诺", "Levels, Visual Evolution & Power Target"), accent)
	content.add_child(growth)
	var growth_body := _store_detail_section_body(growth)
	var level_line := UiKit.label(
		LocalizationManager.text("武器等级 1–50 · 护甲等级 1–35 · 芯片等级 1–35 · 宠物等级 1–30"),
		16,
		UiKit.TEXT_MAIN,
		2
	)
	level_line.name = "LevelRanges"
	level_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	growth_body.add_child(level_line)
	var evolution := UiKit.label(
		LocalizationManager.text("外观进化：原型 → 激活 → 强化 → 过载 → 觉醒（等级 1 / 10 / 20 / 30 / 满级）"),
		15,
		UiKit.GREY_300,
		2
	)
	evolution.name = "EvolutionStages"
	evolution.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	growth_body.add_child(evolution)
	var center := float(set_row.get("target_full_set_ratio_center", 1.0))
	var minimum := float(set_row.get("target_full_set_ratio_min", center))
	var maximum := float(set_row.get("target_full_set_ratio_max", center))
	var target_text := _loc(
		"满级整套真实总输出目标：%.2f×（验收区间 %.2f×–%.2f×）" % [center, minimum, maximum],
		"Max-level full-set real-output target: %.2f× (acceptance %.2f×–%.2f×)" % [center, minimum, maximum]
	)
	var target := UiKit.label(target_text, 16, UiKit.SUCCESS, 2)
	target.name = "PowerTarget"
	target.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	growth_body.add_child(target)


func _store_detail_section(section_name: String, title_text: String, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = section_name
	panel.add_theme_stylebox_override("panel", UiKit.collection_card_texture_style(false))
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", STORE_DETAIL_SECTION_MARGIN_LEFT)
	margin.add_theme_constant_override("margin_top", STORE_DETAIL_SECTION_MARGIN_V)
	margin.add_theme_constant_override("margin_right", STORE_DETAIL_SECTION_MARGIN_RIGHT)
	margin.add_theme_constant_override("margin_bottom", STORE_DETAIL_SECTION_MARGIN_V)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	var title := UiKit.label(title_text, 20, accent, 3)
	title.name = "SectionTitle"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var body := VBoxContainer.new()
	body.name = "Body"
	body.add_theme_constant_override("separation", 12)
	box.add_child(body)
	return panel


func _store_detail_section_body(section: PanelContainer) -> VBoxContainer:
	return section.get_node("Margin/Box/Body") as VBoxContainer


func _store_detail_info_card(title_text: String, body_text: String, accent: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(432, 94)
	card.add_theme_stylebox_override("panel", _store_preview_cell_style(accent))
	var margin := MarginContainer.new()
	margin.name = "InfoMargin"
	margin.add_theme_constant_override("margin_left", STORE_DETAIL_INFO_MARGIN_LEFT)
	margin.add_theme_constant_override("margin_top", STORE_DETAIL_INFO_MARGIN_V)
	margin.add_theme_constant_override("margin_right", STORE_DETAIL_INFO_MARGIN_RIGHT)
	margin.add_theme_constant_override("margin_bottom", STORE_DETAIL_INFO_MARGIN_V)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)
	var title := UiKit.label(title_text, 15, UiKit.TEXT_MAIN, 2)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var body := UiKit.label(body_text, 12, UiKit.GREY_300, 1)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)
	return card


func _store_detail_hero_card(character_id: String, theme_id: String, accent: Color) -> PanelContainer:
	var row := DataLoader.get_row("characters", character_id)
	var card := PanelContainer.new()
	card.name = "Hero_%s" % character_id
	card.custom_minimum_size = STORE_DETAIL_HERO_CELL_SIZE
	card.clip_contents = true
	card.set_meta("store_detail_hero_id", character_id)
	card.add_theme_stylebox_override("panel", _store_preview_cell_style(accent))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(box)
	var viewport := Control.new()
	viewport.name = "PortraitViewport"
	viewport.custom_minimum_size = STORE_DETAIL_PORTRAIT_VIEW_SIZE
	viewport.clip_contents = true
	box.add_child(viewport)
	var fallback_path := UiKit.character_bust_path(row)
	var portrait_path := ThemeManager.resolve_character_portrait_for_theme(character_id, theme_id, fallback_path)
	var texture := load(portrait_path) as Texture2D if ResourceLoader.exists(portrait_path) else null
	_add_alpha_fitted_texture(viewport, texture, portrait_path, STORE_DETAIL_PORTRAIT_VIEW_SIZE, STORE_DETAIL_PORTRAIT_VISIBLE_HEIGHT, 4.0, "Portrait")
	var label := UiKit.label(DataLoader.tr_key(str(row.get("name_key", character_id))), 14, UiKit.TEXT_MAIN, 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(label)
	return card


func _store_detail_weapon_skin_card(weapon_id: String, theme_id: String, accent: Color) -> PanelContainer:
	var row := DataLoader.get_row("weapons", weapon_id)
	var card := PanelContainer.new()
	card.name = "WeaponSkin_%s" % weapon_id
	card.custom_minimum_size = STORE_DETAIL_WEAPON_CELL_SIZE
	card.set_meta("store_detail_weapon_id", weapon_id)
	card.add_theme_stylebox_override("panel", _store_preview_cell_style(accent))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	var icon_path := _store_theme_weapon_icon_path(theme_id, weapon_id, str(row.get("icon", "")))
	var icon := UiKit.icon(icon_path, Vector2(134, 122))
	icon.name = "WeaponIcon"
	icon.modulate = Color.WHITE.lerp(accent, 0.10)
	box.add_child(icon)
	var label := UiKit.label(DataLoader.tr_key(str(row.get("name_key", weapon_id))), 13, UiKit.TEXT_MAIN, 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(label)
	return card


func _store_detail_gear_card(table: String, slot: String, item_id: String, accent: Color) -> PanelContainer:
	var row := DataLoader.get_row(table, item_id)
	var card := PanelContainer.new()
	card.name = "Gear_%s" % slot.capitalize()
	card.custom_minimum_size = STORE_DETAIL_GEAR_CELL_SIZE
	card.set_meta("store_detail_item_id", item_id)
	card.set_meta("store_detail_item_table", table)
	card.add_theme_stylebox_override("panel", _store_preview_cell_style(accent))
	var margin := MarginContainer.new()
	margin.name = "GearMargin"
	margin.add_theme_constant_override("margin_left", STORE_DETAIL_GEAR_MARGIN_LEFT)
	margin.add_theme_constant_override("margin_top", STORE_DETAIL_GEAR_MARGIN_V)
	margin.add_theme_constant_override("margin_right", STORE_DETAIL_GEAR_MARGIN_RIGHT)
	margin.add_theme_constant_override("margin_bottom", STORE_DETAIL_GEAR_MARGIN_V)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	box.add_child(head)
	var icon := UiKit.icon(str(row.get("icon", "")), Vector2(112, 112))
	icon.name = "ItemIcon"
	head.add_child(icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(copy)
	var slot_name := _store_slot_name(slot)
	var name := UiKit.label(DataLoader.tr_key(str(row.get("name_key", item_id))), 16, UiKit.TEXT_MAIN, 2)
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(name)
	var level := UiKit.label(
		LocalizationManager.text("%s · 等级 1–%d") % [slot_name, int(row.get("max_level", 1))],
		13,
		accent,
		2
	)
	level.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(level)
	var summary := UiKit.label(_store_gear_summary(table, row), 12, UiKit.GREY_300, 1)
	summary.name = "ItemSummary"
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(summary)
	return card


func _store_detail_actions(row: Dictionary, is_current_offer: bool) -> Control:
	var actions := HBoxContainer.new()
	actions.name = "DetailActions"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 18)
	var product_id := str(row.get("id", ""))
	var purchase := Button.new()
	purchase.name = "PurchaseButton"
	purchase.set_meta("store_detail_product_id", product_id)
	var owned := PurchaseManager.is_product_owned(product_id)
	if is_current_offer:
		purchase.text = _loc("演示购买  ", "Demo Buy  ") + str(row.get("mock_price_en" if LocalizationManager.is_english() else "mock_price_zh", ""))
		purchase.set_meta("store_detail_action_state", "purchase")
		purchase.pressed.connect(_run_store_tap.bind(_purchase_from_product_detail.bind(product_id)))
	elif owned:
		purchase.text = _loc("已拥有 · 可恢复", "Owned · Restorable")
		purchase.set_meta("store_detail_action_state", "owned")
		purchase.disabled = true
	else:
		purchase.text = _loc("商品状态已更新", "Offer State Updated")
		purchase.set_meta("store_detail_action_state", "stale")
		purchase.disabled = true
	UiKit.apply_armored_button(purchase, true, Vector2(620, 96), 20, not purchase.disabled)
	actions.add_child(purchase)
	var close := Button.new()
	close.name = "FooterCloseButton"
	close.text = _loc("返回商品列表", "Back to Store")
	UiKit.apply_armored_button(close, false, Vector2(250, 96), 15, true)
	close.pressed.connect(_close_product_detail)
	actions.add_child(close)
	return actions


func _purchase_from_product_detail(product_id: String) -> void:
	_close_product_detail()
	_confirm_purchase(product_id)


func _on_product_detail_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_close_product_detail()
	elif event is InputEventScreenTouch and event.pressed:
		_close_product_detail()


func _close_product_detail() -> void:
	if is_instance_valid(_product_detail):
		_product_detail.queue_free()
	_product_detail = null
	if is_node_ready():
		$Root/VBox/Footer.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(_product_detail) and event.is_action_pressed("ui_cancel"):
		_close_product_detail()
		get_viewport().set_input_as_handled()


func _product_grants_entitlement(row: Dictionary, entitlement_id: String) -> bool:
	return entitlement_id != "" and row.get("grants", []).has(entitlement_id)


func _store_theme_weapon_icon_path(theme_id: String, weapon_id: String, fallback_path: String) -> String:
	for theme in ThemeManager.catalog_themes():
		if str(theme.get("id", "")) != theme_id:
			continue
		var root_path := str(theme.get("weapons", {}).get("asset_root", "")).trim_suffix("/")
		var candidate := "%s/%s_icon.png" % [root_path, weapon_id]
		if root_path != "" and (ResourceLoader.exists(candidate) or FileAccess.file_exists(ProjectSettings.globalize_path(candidate))):
			return candidate
		break
	return fallback_path


func _store_slot_name(slot: String) -> String:
	match slot:
		"weapon": return _loc("终焉武器", "Apocalypse Weapon")
		"armor": return _loc("终焉护甲", "Apocalypse Armor")
		"chip": return _loc("终焉芯片", "Apocalypse Chip")
		"pet": return _loc("终焉宠物", "Apocalypse Pet")
		_: return slot


func _store_element_name(element: String) -> String:
	match element:
		"physical": return _loc("物理", "Physical")
		"fire": return _loc("火焰", "Fire")
		"ice": return _loc("冰霜", "Frost")
		"lightning": return _loc("闪电", "Lightning")
		"poison": return _loc("毒素", "Poison")
		"none", "": return _loc("无", "None")
		_: return element


func _store_stat_name(stat: String) -> String:
	match stat:
		"damage_mult": return _loc("伤害", "Damage")
		"element_damage_mult": return _loc("元素伤害", "Element Damage")
		"fire_rate_mult": return _loc("射速", "Fire Rate")
		"crit_rate": return _loc("暴击率", "Critical Rate")
		_: return stat.replace("_", " ").capitalize()


func _store_gear_summary(table: String, row: Dictionary) -> String:
	match table:
		"weapons":
			var special: Dictionary = row.get("special", {})
			return _loc(
				"%s · 攻击系数 %.3f · 射速 %.1f\n专属机制 %d 项，满级持续强化" % [_store_element_name(str(row.get("element", ""))), float(row.get("base_atk_coef", 0.0)), float(row.get("fire_rate", 0.0)), special.size()],
				"%s · ATK coefficient %.3f · Rate %.1f\n%d signature mechanics; scales through MAX" % [_store_element_name(str(row.get("element", ""))), float(row.get("base_atk_coef", 0.0)), float(row.get("fire_rate", 0.0)), special.size()]
			)
		"armors":
			return _loc(
				"基地生命 %.0f%% · %s抗性 · 防线屏障 +%d\n受击反制随等级强化" % [float(row.get("hp_mult", 1.0)) * 100.0, _store_element_name(str(row.get("resist", "none"))), int(row.get("breach_shield", 0))],
				"Base HP %.0f%% · %s resist · Barrier +%d\nCounter effect scales by level" % [float(row.get("hp_mult", 1.0)) * 100.0, _store_element_name(str(row.get("resist", "none"))), int(row.get("breach_shield", 0))]
			)
		"chips":
			var secondary: Dictionary = row.get("secondary_stats", {})
			return _loc(
				"%s +%.0f%% · %d 项副属性\n核心与副属性均随等级成长" % [_store_stat_name(str(row.get("stat", ""))), float(row.get("value", 0.0)) * 100.0, secondary.size()],
				"%s +%.0f%% · %d secondary stats\nCore and secondary stats scale by level" % [_store_stat_name(str(row.get("stat", ""))), float(row.get("value", 0.0)) * 100.0, secondary.size()]
			)
		"pets":
			var skill: Dictionary = row.get("pet_skill", {})
			var skill_name := str(skill.get("name", _loc("专属协战", "Signature Support")))
			if LocalizationManager.is_english():
				skill_name = "Signature Support"
			return _loc(
				"%s · 伤害 %d · 射速 %.2f\n%s · 冷却 %.1f 秒" % [_store_element_name(str(row.get("element", ""))), int(row.get("damage", 0)), float(row.get("fire_rate", 0.0)), skill_name, float(skill.get("cooldown", 0.0))],
				"%s · Damage %d · Rate %.2f\n%s · %.1fs cooldown" % [_store_element_name(str(row.get("element", ""))), int(row.get("damage", 0)), float(row.get("fire_rate", 0.0)), skill_name, float(skill.get("cooldown", 0.0))]
			)
		_:
			return ""


func _add_alpha_fitted_texture(parent: Control, texture: Texture2D, source_path: String, view_size: Vector2, visible_height: float, headroom: float, node_name: String) -> void:
	var visual := TextureRect.new()
	visual.name = node_name
	visual.texture = texture
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(visual)
	if texture == null:
		visual.custom_minimum_size = view_size
		return
	var used := _texture_used_rect(texture)
	var scale_factor := visible_height / maxf(used.size.y, 1.0)
	var texture_size := texture.get_size() * scale_factor
	var visible_size := used.size * scale_factor
	var visible_position := Vector2((view_size.x - visible_size.x) * 0.5, headroom)
	visual.position = visible_position - used.position * scale_factor
	visual.size = texture_size
	visual.custom_minimum_size = texture_size
	visual.set_meta("store_detail_source", source_path)
	visual.set_meta("store_detail_visible_rect", Rect2(visible_position, visible_size))


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
	equip.pressed.connect(_run_store_tap.bind(_equip_set.bind(set_id)))
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
	reset.pressed.connect(_run_store_tap.bind(_confirm_series_reset.bind(series_id)))
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
	var cost_spec := SaveManager.get_item_upgrade_cost_spec(table, item_id)
	var cost := int(cost_spec.get("amount", 0))
	upgrade.text = _loc("已满级", "MAX") if maxed else _loc("升级", "Upgrade")
	upgrade.disabled = maxed or not SaveManager.can_upgrade_item(table, item_id)
	UiKit.apply_armored_button(upgrade, false, Vector2(320, 80), 17, not upgrade.disabled)
	if not maxed:
		UiKit.apply_resource_cost(upgrade, _loc("升级", "Upgrade"), str(cost_spec.get("kind", "gold")), cost, 16, 24.0, -2.0)
		if upgrade.disabled:
			upgrade.modulate = Color(0.72, 0.76, 0.80, 0.92)
	upgrade.pressed.connect(_run_store_tap.bind(_upgrade_item.bind(table, item_id)))
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
		"focus_series_id": _focus_series_id,
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
	toast.name = "StoreToast"
	toast.add_theme_stylebox_override("panel", UiKit.hint_texture_style(false))
	toast.size = Vector2(760, 96)
	var label := UiKit.label(message, 18, UiKit.SUCCESS, 2)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast.add_child(label)
	add_child(toast)
	call_deferred("_position_store_toast", toast)
	var tween := toast.create_tween()
	tween.tween_interval(1.4)
	tween.tween_property(toast, "modulate:a", 0.0, 0.3)
	tween.tween_callback(toast.queue_free)


func _position_store_toast(toast: PanelContainer) -> void:
	if not is_instance_valid(toast) or not toast.is_inside_tree():
		return
	await get_tree().process_frame
	if not is_instance_valid(toast) or not toast.is_inside_tree():
		return
	var target_y := 1500.0
	var restore_hint := find_child("RestoreHint", true, false) as Control
	if restore_hint != null and restore_hint.visible:
		target_y = restore_hint.global_position.y + restore_hint.size.y + 24.0 - global_position.y
	var footer := $Root/VBox/Footer as Control
	var footer_safe_y := footer.global_position.y - global_position.y - toast.size.y - 24.0
	toast.position = Vector2((size.x - toast.size.x) * 0.5, minf(target_y, footer_safe_y))


func _back() -> void:
	if is_instance_valid(_product_detail):
		AudioManager.play_sfx("ui_click")
		_close_product_detail()
		return
	AudioManager.play_sfx("ui_click")
	router.change_scene(_return_to, _return_payload.duplicate(true))
