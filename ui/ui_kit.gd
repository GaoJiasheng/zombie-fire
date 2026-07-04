extends RefCounted
class_name UiKit

const TEXT_MAIN := Color(0.96, 0.94, 0.86, 1.0)
const TEXT_MUTED := Color(0.66, 0.74, 0.76, 1.0)
const CYAN := Color(0.38, 0.76, 0.80, 1.0)
const GOLD := Color(0.88, 0.64, 0.32, 1.0)
const RED := Color(0.94, 0.28, 0.24, 1.0)
const GREEN := Color(0.48, 0.74, 0.50, 1.0)
const PURPLE := Color(0.72, 0.58, 0.88, 1.0)
const PANEL_BG := Color(0.020, 0.024, 0.030, 0.90)
const PANEL_BG_DARK := Color(0.010, 0.014, 0.020, 0.94)
const BORDER_SOFT := Color(0.48, 0.57, 0.60, 0.42)
const SURFACE := Color(0.018, 0.022, 0.028, 0.88)
const SURFACE_ALT := Color(0.030, 0.029, 0.025, 0.86)
const WARM_EDGE := Color(0.70, 0.53, 0.30, 0.46)

# Neutral grey ramp for backgrounds, dividers, disabled states and secondary text.
const GREY_900 := Color(0.07, 0.08, 0.10, 1.0)
const GREY_700 := Color(0.16, 0.18, 0.21, 1.0)
const GREY_500 := Color(0.42, 0.46, 0.50, 1.0)
const GREY_300 := Color(0.68, 0.72, 0.76, 1.0)

# Semantic status colors. SUCCESS is a teal-green kept deliberately distinct from
# the poison element green so "positive feedback" never reads as "poisoned".
const SUCCESS := Color(0.36, 0.80, 0.58, 1.0)
const WARNING := Color(0.96, 0.72, 0.30, 1.0)
const DANGER := Color(0.94, 0.28, 0.24, 1.0)
const INFO := Color(0.46, 0.80, 0.86, 1.0)
const UI_TEXTURE_ROOT := "res://assets/production/sprites/ui/"

# 全局 UI 字号放大系数（移动端可读性）。所有走 apply_label/label/pill 的文字统一放大。
const FONT_SCALE := 1.4

static func panel_style(_accent := CYAN, _bg := PANEL_BG, _border_width := 2, _radius := 8) -> StyleBox:
	return texture_style(UI_TEXTURE_ROOT + "ui_panel_skin.png", 36.0, 14.0, CYAN)

static func plate_style(_accent := CYAN) -> StyleBox:
	return texture_style(UI_TEXTURE_ROOT + "ui_plate_skin.png", 28.0, 8.0, CYAN)

static func texture_style(path: String, margin := 24.0, content := 12.0, fallback_accent := CYAN) -> StyleBox:
	if path != "" and ResourceLoader.exists(path):
		var style := StyleBoxTexture.new()
		style.texture = load(path) as Texture2D
		style.texture_margin_left = margin
		style.texture_margin_top = margin
		style.texture_margin_right = margin
		style.texture_margin_bottom = margin
		style.content_margin_left = content
		style.content_margin_top = content
		style.content_margin_right = content
		style.content_margin_bottom = content
		return style
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = content
	empty.content_margin_top = content
	empty.content_margin_right = content
	empty.content_margin_bottom = content
	return empty

static func panel_texture_style(content := 18.0) -> StyleBox:
	return texture_style(UI_TEXTURE_ROOT + "ui_panel_skin.png", 36.0, content, CYAN)

static func result_panel_texture_style() -> StyleBox:
	return texture_style(UI_TEXTURE_ROOT + "ui_result_panel_final.png", 42.0, 22.0, GOLD)

static func reward_texture_style(kind: String) -> StyleBox:
	if kind == "xp":
		return texture_style(UI_TEXTURE_ROOT + "ui_result_reward_card_xp.png", 26.0, 16.0, CYAN)
	return texture_style(UI_TEXTURE_ROOT + "ui_result_reward_card_gold.png", 26.0, 16.0, GOLD)

static func icon_frame_texture_style(active := false, empty := false) -> StyleBox:
	if empty:
		return texture_style(UI_TEXTURE_ROOT + "ui_empty_equipment_socket.png", 32.0, 10.0, BORDER_SOFT)
	if active:
		return texture_style(UI_TEXTURE_ROOT + "ui_icon_frame_active.png", 32.0, 10.0, GOLD)
	return texture_style(UI_TEXTURE_ROOT + "ui_icon_frame.png", 32.0, 10.0, CYAN)

static func skill_slot_texture_style(active := false) -> StyleBox:
	if active:
		return texture_style(UI_TEXTURE_ROOT + "ui_skill_slot_active.png", 32.0, 10.0, GOLD)
	return texture_style(UI_TEXTURE_ROOT + "ui_skill_slot.png", 32.0, 10.0, CYAN)

static func map_level_card_texture_style(locked := false) -> StyleBox:
	if locked:
		return texture_style(UI_TEXTURE_ROOT + "ui_map_level_card_locked_skin.png", 34.0, 0.0, BORDER_SOFT)
	return texture_style(UI_TEXTURE_ROOT + "ui_map_level_card_skin.png", 34.0, 0.0, CYAN)

static func map_nav_card_texture_style() -> StyleBox:
	return texture_style(UI_TEXTURE_ROOT + "ui_map_nav_card_skin.png", 28.0, 0.0, CYAN)

static func map_index_texture_style() -> StyleBox:
	return texture_style(UI_TEXTURE_ROOT + "ui_map_index_plate_skin.png", 22.0, 8.0, CYAN)

static func map_pill_texture_style() -> StyleBox:
	return texture_style(UI_TEXTURE_ROOT + "ui_map_pill_skin.png", 24.0, 10.0, CYAN)

static func deploy_pill_texture_style() -> StyleBox:
	return texture_style(UI_TEXTURE_ROOT + "ui_map_deploy_pill_skin.png", 24.0, 10.0, GOLD)

static func resource_chip_texture_style() -> StyleBox:
	return texture_style(UI_TEXTURE_ROOT + "ui_resource_chip_skin.png", 26.0, 12.0, GOLD)

static func collection_card_texture_style(skill := false) -> StyleBox:
	if skill:
		return texture_style(UI_TEXTURE_ROOT + "ui_collection_skill_card_skin.png", 34.0, 0.0, CYAN)
	return texture_style(UI_TEXTURE_ROOT + "ui_collection_card_skin.png", 36.0, 0.0, CYAN)

static func hint_texture_style(warning := false) -> StyleBox:
	if warning:
		return texture_style(UI_TEXTURE_ROOT + "ui_warning_strip.png", 26.0, 16.0, WARNING)
	return texture_style(UI_TEXTURE_ROOT + "ui_hint_strip.png", 26.0, 16.0, CYAN)

static func pill_style(accent := CYAN, bg := Color(0.022, 0.026, 0.032, 0.82)) -> StyleBox:
	if ResourceLoader.exists(UI_TEXTURE_ROOT + "ui_map_pill_skin.png"):
		return map_pill_texture_style()
	return texture_style(UI_TEXTURE_ROOT + "ui_pill_skin.png", 24.0, 10.0, accent)

static func apply_label(label: Label, size := 22, color := TEXT_MAIN, outline := 3) -> void:
	label.add_theme_font_size_override("font_size", int(round(size * FONT_SCALE)))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	# outline 此前一直是字面量、不随 FONT_SCALE 放大：字号越调越大后描边相对越来越
	# 细，是"整体字体偏细"的一部分原因。这里让描边跟字号同步缩放，保持粗细观感。
	label.add_theme_constant_override("outline_size", maxi(1, int(round(outline * FONT_SCALE))))

static func label(text: String, size := 22, color := TEXT_MAIN, outline := 3) -> Label:
	var node := Label.new()
	node.text = text
	apply_label(node, size, color, outline)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func pill(text: String, accent := CYAN, font_size := 18) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", pill_style(accent))
	panel.custom_minimum_size = Vector2(0, 36)
	var l := label(text, font_size, TEXT_MAIN, 2)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(l)
	return panel

static func icon(path: String, size := Vector2(64, 64)) -> TextureRect:
	var tex := TextureRect.new()
	if path != "" and ResourceLoader.exists(path):
		tex.texture = load(path)
	tex.custom_minimum_size = size
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tex

static func character_bust_path(row: Dictionary) -> String:
	var base_path := str(row.get("portrait", row.get("icon", "")))
	if base_path == "":
		return ""
	var candidates: Array[String] = []
	if base_path.ends_with("_icon.png"):
		# 菜单/选择/详情一律用“正脸”立绘：frameless 正脸 > 带框正脸 > 背面全身(prototype) > 图标
		candidates.append(base_path.replace("_icon.png", "_portrait_frameless.png"))
		candidates.append(base_path.replace("_icon.png", "_portrait.png"))
		candidates.append(base_path.replace("_icon.png", "_prototype.png"))
	candidates.append(base_path)
	for path in candidates:
		if path != "" and ResourceLoader.exists(path):
			return path
	return ""

static func character_bust_texture(row: Dictionary) -> Texture2D:
	var path := character_bust_path(row)
	if path == "":
		return null
	return load(path) as Texture2D

static func add_character_bust(parent: Control, row: Dictionary, viewport_size: Vector2, image_width: float, y_offset: float, tint := Color.WHITE) -> TextureRect:
	parent.clip_contents = true
	parent.custom_minimum_size = viewport_size
	var bust := parent.get_node_or_null("BustImage") as TextureRect
	if bust == null:
		bust = TextureRect.new()
		bust.name = "BustImage"
		bust.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bust.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bust.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		parent.add_child(bust)
	var texture := character_bust_texture(row)
	bust.texture = texture
	bust.modulate = tint
	if texture == null:
		bust.size = viewport_size
		bust.custom_minimum_size = viewport_size
		bust.position = Vector2.ZERO
		return bust
	var texture_size := texture.get_size()
	var aspect := texture_size.y / maxf(texture_size.x, 1.0)
	var bust_size := Vector2(image_width, image_width * aspect)
	bust.size = bust_size
	bust.custom_minimum_size = bust_size
	bust.position = Vector2((viewport_size.x - bust_size.x) * 0.5, y_offset)
	return bust

static func element_icon_path(element: String) -> String:
	match str(element):
		"fire":
			return "res://assets/production/sprites/ui/icon_element_fire.png"
		"ice":
			return "res://assets/production/sprites/ui/icon_element_ice.png"
		"lightning":
			return "res://assets/production/sprites/ui/icon_element_lightning.png"
		"poison":
			return "res://assets/production/sprites/ui/icon_element_poison.png"
		"physical":
			return "res://assets/production/sprites/ui/icon_element_physical.png"
		_:
			return "res://assets/production/sprites/ui/icon_warning.png"

static func element_color(element: String) -> Color:
	match str(element):
		"fire":
			return Color(0.95, 0.42, 0.22, 1.0)
		"ice":
			return Color(0.50, 0.78, 0.92, 1.0)
		"lightning":
			return Color(0.96, 0.78, 0.28, 1.0)
		"poison":
			return Color(0.48, 0.78, 0.40, 1.0)
		"physical":
			return Color(0.76, 0.82, 0.88, 1.0)
		_:
			return CYAN

static func star_icon_path(filled: bool) -> String:
	return "res://assets/production/sprites/ui/ui_star_filled.png" if filled else "res://assets/production/sprites/ui/ui_star_empty.png"

static func currency_icon_path(kind: String) -> String:
	match kind:
		"gold":
			return "res://assets/production/sprites/ui/icon_currency_gold.png"
		"xp":
			return "res://assets/production/sprites/ui/icon_currency_xp.png"
		"star":
			return "res://assets/production/sprites/ui/icon_currency_star.png"
		_:
			return "res://assets/production/sprites/ui/icon_warning.png"

static func press_feedback(control: Control) -> void:
	if control == null or not is_instance_valid(control):
		return
	var tween := control.create_tween()
	tween.tween_property(control, "scale", Vector2(0.97, 0.97), 0.05)
	tween.tween_property(control, "scale", Vector2.ONE, 0.08)

# 战力图标(与 map 一致)。
const POWER_ICON := "res://assets/production/sprites/ui/icon_talent_point.png"

# ---- 共享资源条(金币/星星/经验/战力)。各页面统一外观,只在此维护。----
static func _resource_chip_style(accent: Color) -> StyleBox:
	if ResourceLoader.exists(UI_TEXTURE_ROOT + "ui_resource_chip_skin.png"):
		return resource_chip_texture_style()
	return texture_style(UI_TEXTURE_ROOT + "ui_resource_chip_skin.png", 26.0, 12.0, accent)

static func resource_chip(icon_path: String, accent: Color, value: String, tip := "", chip_size := Vector2(186, 62), font_size := 30) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = chip_size
	btn.focus_mode = Control.FOCUS_NONE
	btn.tooltip_text = tip
	var style := _resource_chip_style(accent)
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(st, style)
	if tip != "":
		btn.pressed.connect(func() -> void: toast(btn, tip, accent))
	var content := HBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 9)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(content)
	var ic := icon(icon_path, Vector2(36, 36))
	ic.modulate = Color(1.06, 1.02, 0.92, 1.0)
	content.add_child(ic)
	var lbl := label(value, font_size, TEXT_MAIN, 3)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(lbl)
	return btn

# 轻量提示条:点资源 chip 时在顶部中央短暂显示说明(手机没有 hover tooltip)。
static func toast(anchor: Node, text: String, accent := GOLD) -> void:
	if anchor == null or not is_instance_valid(anchor) or anchor.get_tree() == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 128
	anchor.get_tree().root.add_child(layer)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", pill_style(accent, Color(0.02, 0.03, 0.04, 0.96)))
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.offset_top = 120.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var lbl := label(text, 26, TEXT_MAIN, 3)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(lbl)
	layer.add_child(panel)
	var tween := panel.create_tween()
	tween.tween_interval(1.8)
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(layer.queue_free)

# items: Array[Dictionary]，每项 {icon:String, accent:Color, value:String, tip:String}
static func resource_bar(items: Array, chip_size := Vector2(186, 62), font_size := 30) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	for it in items:
		if it is Dictionary:
			row.add_child(resource_chip(
				str(it.get("icon", "")),
				it.get("accent", GOLD),
				str(it.get("value", "")),
				str(it.get("tip", "")),
				chip_size,
				font_size
			))
	return row

# 标准四项资源条(金币/可用星星/经验/战力),数值由调用方传入,保证各页面内容一致。
static func standard_resource_bar(gold: int, star: int, xp: int, power: int, chip_size := Vector2(186, 62), font_size := 30) -> HBoxContainer:
	return resource_bar([
		{"icon": currency_icon_path("gold"), "accent": GOLD, "value": "%d" % gold, "tip": "金币：升级角色/武器/护甲/芯片/宠物"},
		{"icon": currency_icon_path("star"), "accent": Color(0.96, 0.80, 0.30, 1.0), "value": "%d" % star, "tip": "可用星星：购买/解锁角色与装备"},
		{"icon": currency_icon_path("xp"), "accent": CYAN, "value": "%d" % xp, "tip": "经验：永久升级技能"},
		{"icon": POWER_ICON, "accent": PURPLE, "value": "%d" % power, "tip": "战力：当前阵容综合强度"},
	], chip_size, font_size)

# 共享武器图标(统一外观,尺寸可变)。
static func weapon_icon(row: Dictionary, size := Vector2(88, 88)) -> TextureRect:
	return icon(str(row.get("icon", row.get("portrait", ""))), size)

# ---- 统一购买/确认弹框(所有商店、所有货币共用同一个模型)。----
# opts: title, message, cost_text, cost_icon, accent, confirm_text, cancel_text,
#       item_icon(可选立绘/图标), on_confirm(Callable), on_cancel(Callable)
static func _modal_button(text: String, accent: Color, primary: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(196, 82)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", int(30 * FONT_SCALE))
	var fg: Color = GREY_900 if primary else TEXT_MAIN
	var texture_path := UI_TEXTURE_ROOT + ("ui_modal_button_primary.png" if primary else "ui_modal_button_secondary.png")
	var normal := texture_style(texture_path, 34.0, 14.0, accent)
	var hover := texture_style(texture_path, 34.0, 14.0, accent)
	var pressed := texture_style(texture_path, 34.0, 14.0, accent)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", normal)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	return b

static func confirm_modal(host: Node, opts: Dictionary) -> CanvasLayer:
	var accent: Color = opts.get("accent", GOLD)
	var layer := CanvasLayer.new()
	layer.layer = 128
	var dim := TextureRect.new()
	dim.texture = load(UI_TEXTURE_ROOT + "ui_panel_skin.png")
	dim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dim.stretch_mode = TextureRect.STRETCH_SCALE
	dim.modulate = Color(0.0, 0.0, 0.0, 0.64)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", panel_style(accent, PANEL_BG_DARK, 3, 20))
	panel.custom_minimum_size = Vector2(660, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 52)
	margin.add_theme_constant_override("margin_right", 52)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	panel.add_child(margin)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 24)
	margin.add_child(vb)
	var title := label(str(opts.get("title", "确认")), 42, accent, 4)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var item_icon := str(opts.get("item_icon", ""))
	if item_icon != "" and ResourceLoader.exists(item_icon):
		var holder := CenterContainer.new()
		var frame := PanelContainer.new()
		frame.add_theme_stylebox_override("panel", pill_style(accent, Color(0.02, 0.026, 0.034, 0.9)))
		frame.clip_contents = true
		var ic := icon(item_icon, Vector2(168, 176))
		frame.add_child(ic)
		holder.add_child(frame)
		vb.add_child(holder)
	var msg := label(str(opts.get("message", "")), 31, TEXT_MAIN, 3)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(msg)
	var cost_text := str(opts.get("cost_text", ""))
	if cost_text != "":
		var cost_row := HBoxContainer.new()
		cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
		cost_row.add_theme_constant_override("separation", 12)
		var cicon := str(opts.get("cost_icon", ""))
		if cicon != "" and ResourceLoader.exists(cicon):
			cost_row.add_child(icon(cicon, Vector2(46, 46)))
		cost_row.add_child(label(cost_text, 44, accent, 4))
		vb.add_child(cost_row)
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 30)
	vb.add_child(btns)
	var cancel_btn := _modal_button(str(opts.get("cancel_text", "取消")), GREY_500, false)
	var confirm_btn := _modal_button(str(opts.get("confirm_text", "购买")), accent, true)
	btns.add_child(cancel_btn)
	btns.add_child(confirm_btn)
	var on_confirm: Callable = opts.get("on_confirm", Callable())
	var on_cancel: Callable = opts.get("on_cancel", Callable())
	var closed := [false]
	var close_modal := func() -> void:
		if not closed[0] and is_instance_valid(layer):
			closed[0] = true
			layer.queue_free()
	confirm_btn.pressed.connect(func() -> void:
		if on_confirm.is_valid():
			on_confirm.call()
		close_modal.call())
	cancel_btn.pressed.connect(func() -> void:
		if on_cancel.is_valid():
			on_cancel.call()
		close_modal.call())
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			if on_cancel.is_valid():
				on_cancel.call()
			close_modal.call())
	host.add_child(layer)
	panel.modulate.a = 0.0
	var tw := panel.create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.14)
	return layer
