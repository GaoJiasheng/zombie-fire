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

# 全局 UI 字号放大系数（移动端可读性）。所有走 apply_label/label/pill 的文字统一放大。
const FONT_SCALE := 1.22

static func panel_style(accent := CYAN, bg := PANEL_BG, border_width := 2, radius := 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color(accent.r, accent.g, accent.b, 0.64)
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	return style

static func plate_style(accent := CYAN) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.022, 0.028, 0.82)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.52)
	style.border_width_top = 2
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	return style

static func pill_style(accent := CYAN, bg := Color(0.022, 0.026, 0.032, 0.82)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color(accent.r, accent.g, accent.b, 0.58)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_top = 4
	style.content_margin_right = 12
	style.content_margin_bottom = 4
	return style

static func apply_label(label: Label, size := 22, color := TEXT_MAIN, outline := 3) -> void:
	label.add_theme_font_size_override("font_size", int(round(size * FONT_SCALE)))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	label.add_theme_constant_override("outline_size", outline)

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
		candidates.append(base_path.replace("_icon.png", "_prototype.png"))
		candidates.append(base_path.replace("_icon.png", "_portrait_frameless.png"))
		candidates.append(base_path.replace("_icon.png", "_portrait.png"))
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
static func _resource_chip_style(accent: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.012, 0.016, 0.022, 0.78)
	s.set_border_width_all(2)
	s.border_color = Color(accent.r, accent.g, accent.b, 0.42)
	s.set_corner_radius_all(11)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

static func resource_chip(icon_path: String, accent: Color, value: String, tip := "", chip_size := Vector2(186, 62), font_size := 30) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = chip_size
	panel.tooltip_text = tip
	panel.add_theme_stylebox_override("panel", _resource_chip_style(accent))
	var content := HBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 9)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content)
	var ic := icon(icon_path, Vector2(36, 36))
	ic.modulate = Color(1.06, 1.02, 0.92, 1.0)
	content.add_child(ic)
	var lbl := label(value, font_size, TEXT_MAIN, 3)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(lbl)
	return panel

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
