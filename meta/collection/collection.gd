extends Control

const UiKit := preload("res://ui/ui_kit.gd")
const BUTTON_PRIMARY := "res://assets/production/sprites/ui/ui_button_primary.png"
const BUTTON_SECONDARY := "res://assets/production/sprites/ui/ui_button_secondary.png"
const CharacterSkillText := preload("res://core/data/character_skill_text.gd")
const SkillEffectText := preload("res://core/data/skill_effect_text.gd")

var router: Node
var mode := "characters"
var _return_to := "map"
var _return_level_id := ""
var _loadout_return_to := "map"
var _loadout_return_payload := {}
var _detail_modal: Control = null

func setup(main: Node, payload := {}) -> void:
	router = main
	var data := {}
	if payload is Dictionary:
		data = payload
	mode = str(data.get("mode", "characters"))
	_return_to = str(data.get("return_to", "map"))
	_return_level_id = str(data.get("level_id", data.get("return_level_id", "")))
	_loadout_return_to = _sanitize_loadout_return_to(str(data.get("loadout_return_to", "map")))
	_loadout_return_payload = _sanitize_payload(data.get("loadout_return_payload", {}))
	if _return_to == "loadout" and _return_level_id == "" and router != null:
		var context: Variant = router.get("run_context")
		if context is Dictionary:
			_return_level_id = str(context.get("level_id", ""))
	if _return_to != "loadout":
		_return_to = "map"
	_refresh()

func _ready() -> void:
	(%BackButton as TextureButton).pressed.connect(_on_back_pressed)
	_refresh_back_button()
	_refresh()

func _on_back_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	if router == null:
		return
	if _return_to == "loadout":
		var payload := {}
		if _return_level_id != "":
			payload["level_id"] = _return_level_id
		payload["return_to"] = _loadout_return_to
		if not _loadout_return_payload.is_empty():
			payload["return_payload"] = _loadout_return_payload.duplicate(true)
		router.change_scene("loadout", payload)
		return
	router.change_scene("map")

func _refresh_back_button() -> void:
	var button := %BackButton as TextureButton
	var label := button.get_node_or_null("Label") as Label
	if label == null:
		return
	label.text = "返回配置" if _return_to == "loadout" else "返回地图"

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
	(%Title as Label).text = _title()
	_refresh_resource_bar()
	var item_list := %ItemList as VBoxContainer
	for child in item_list.get_children():
		child.queue_free()
	var table_data: Dictionary = _table()
	for item_id: String in table_data.keys():
		item_list.add_child(_build_item_button(item_id, table_data[item_id]))

func _refresh_resource_bar() -> void:
	var prog := %Progress as Label
	prog.visible = false
	var parent := prog.get_parent()
	var existing := parent.get_node_or_null("ResourceBar")
	if existing != null:
		existing.free()
	var bar := UiKit.standard_resource_bar(SaveManager.get_player_gold(), SaveManager.get_player_star(), SaveManager.get_player_xp(), SaveManager.get_loadout_power())
	bar.name = "ResourceBar"
	parent.add_child(bar)
	parent.move_child(bar, prog.get_index() + 1)

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
	var button := TextureButton.new()
	button.name = item_id
	button.custom_minimum_size = Vector2(760, 190)
	var base_texture := load("res://assets/production/sprites/ui/ui_collection_card_skin.png")
	button.texture_normal = base_texture
	button.texture_hover = base_texture
	button.texture_pressed = base_texture
	button.texture_disabled = base_texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.clip_contents = true
	button.modulate = Color(0.96, 0.96, 0.92, 1.0) if unlocked else Color(0.62, 0.64, 0.66, 0.9)
	button.disabled = false
	# 点卡片永远只看详情，绝不直接购买（购买走卡片上的“购买”按钮或详情页里的购买按钮）。
	button.pressed.connect(_show_item_detail.bind(item_id, row))

	var accent := _mode_accent(row)
	var frame := PanelContainer.new()
	frame.position = Vector2(16, 14)
	frame.size = Vector2(728, 162)
	frame.add_theme_stylebox_override("panel", UiKit.collection_card_texture_style(false))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(frame)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.position = Vector2(36, 22) if mode == "characters" else Vector2(48, 42)
	icon.size = Vector2(118, 126) if mode == "characters" else Vector2(88, 88)
	icon.custom_minimum_size = icon.size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.modulate = Color.WHITE if unlocked else Color(0.46, 0.5, 0.54, 0.72)
	if mode == "characters":
		icon.texture = null
		icon.clip_contents = true
		UiKit.add_character_bust(icon, row, Vector2(118, 126), 156.0, -24.0)
	else:
		icon.texture = load(row.get("icon", row.get("portrait", "")))
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	button.add_child(icon)
	icon.set_deferred("position", icon.position)
	icon.set_deferred("size", icon.size)

	var title := Label.new()
	title.text = "%s  等级%d%s" % [DataLoader.tr_key(row.get("name_key", item_id)), item_level, _tier_suffix(item_level)]
	title.position = Vector2(170, 26)
	title.size = Vector2(390, 40)
	UiKit.apply_label(title, 28, _level_tint(item_level) if unlocked else Color(0.7, 0.75, 0.82, 1.0), 3)
	title.clip_text = true
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(title)

	var tag_row := HBoxContainer.new()
	tag_row.position = Vector2(170, 70)
	tag_row.size = Vector2(400, 34)
	tag_row.add_theme_constant_override("separation", 8)
	tag_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(tag_row)
	for tag_text in _item_tags(row, unlocked).slice(0, 3):
		tag_row.add_child(UiKit.pill(str(tag_text), accent, 15))

	var desc := Label.new()
	desc.text = _item_desc(item_id, row, unlocked)
	desc.position = Vector2(170, 110)
	desc.size = Vector2(400, 52)
	UiKit.apply_label(desc, 18, Color(0.72, 0.9, 1.0) if unlocked else Color(0.78, 0.78, 0.78), 2)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.clip_text = true
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(desc)

	if unlocked and mode != "skills":
		var badge := Label.new()
		badge.name = "GrowthBadge"
		badge.text = "已装备" if selected else _growth_badge_text(item_level)
		badge.position = Vector2(588, 64)
		badge.size = Vector2(134, 32)
		UiKit.apply_label(badge, 17, Color(1.0, 0.88, 0.34, 1.0) if selected else _level_tint(item_level), 2)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(badge)
	elif not unlocked:
		var buy_price := SaveManager.get_unlock_price_star(_data_table_name(), item_id)
		var can_buy := SaveManager.get_player_star() >= buy_price
		var buy_btn := Button.new()
		buy_btn.text = ("购买 %d★" % buy_price) if can_buy else ("%d★ 不足" % buy_price)
		buy_btn.position = Vector2(560, 52)
		buy_btn.size = Vector2(156, 52)
		buy_btn.custom_minimum_size = Vector2(156, 52)
		buy_btn.disabled = not can_buy
		buy_btn.focus_mode = Control.FOCUS_NONE
		buy_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		buy_btn.add_theme_font_size_override("font_size", int(round(19 * UiKit.FONT_SCALE)))
		var buy_accent := Color(1.0, 0.84, 0.30) if can_buy else Color(0.42, 0.46, 0.52)
		for st in ["normal", "hover", "pressed", "focus"]:
			buy_btn.add_theme_stylebox_override(st, UiKit.pill_style(buy_accent))
		buy_btn.add_theme_stylebox_override("disabled", UiKit.pill_style(Color(0.34, 0.38, 0.44)))
		buy_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.42))
		buy_btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.58, 0.64))
		if can_buy:
			buy_btn.pressed.connect(_purchase_item_flow.bind(item_id, row))
		button.add_child(buy_btn)
	return button

func _build_skill_item_button(item_id: String, row: Dictionary) -> TextureButton:
	var accent := _mode_accent(row)
	var item_level := maxi(1, SaveManager.get_item_level(item_id))
	var levels: Array = row.get("levels", [])
	var max_level := maxi(1, levels.size())
	var button := TextureButton.new()
	button.name = item_id
	button.custom_minimum_size = Vector2(760, 158)
	var base_texture := load("res://assets/production/sprites/ui/ui_collection_skill_card_skin.png")
	button.texture_normal = base_texture
	button.texture_hover = base_texture
	button.texture_pressed = base_texture
	button.texture_disabled = base_texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.clip_contents = true
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(_show_item_detail.bind(item_id, row))

	var card := PanelContainer.new()
	card.name = "SkillCard"
	card.position = Vector2(10, 6)
	card.size = Vector2(740, 146)
	card.add_theme_stylebox_override("panel", _build_skill_card_style(accent))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(card)

	var accent_bar := TextureRect.new()
	accent_bar.name = "AccentBar"
	accent_bar.position = Vector2(10, 6)
	accent_bar.size = Vector2(18, 132)
	accent_bar.texture = load("res://assets/production/sprites/ui/ui_map_accent_strip.png")
	accent_bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	accent_bar.stretch_mode = TextureRect.STRETCH_SCALE
	accent_bar.modulate = Color(accent.r, accent.g, accent.b, 0.92)
	accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(accent_bar)

	var icon_frame := PanelContainer.new()
	icon_frame.name = "IconFrame"
	icon_frame.position = Vector2(32, 24)
	icon_frame.size = Vector2(90, 90)
	icon_frame.clip_contents = true
	icon_frame.add_theme_stylebox_override("panel", _build_skill_icon_frame_style(accent))
	icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon_frame)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = load(str(row.get("icon", "")))
	icon.position = Vector2(5, 5)
	icon.size = Vector2(80, 80)
	icon.custom_minimum_size = Vector2(80, 80)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_frame.add_child(icon)
	icon.set_deferred("position", Vector2(5, 5))
	icon.set_deferred("size", Vector2(80, 80))

	var title := Label.new()
	title.name = "Title"
	title.text = "%s  等级%d" % [DataLoader.tr_key(row.get("name_key", item_id)), item_level]
	title.position = Vector2(148, 18)
	title.size = Vector2(390, 40)
	title.clip_text = true
	UiKit.apply_label(title, 28, UiKit.TEXT_MAIN, 3)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(title)

	var tag_row := HBoxContainer.new()
	tag_row.name = "Tags"
	tag_row.position = Vector2(148, 58)
	tag_row.size = Vector2(392, 34)
	tag_row.add_theme_constant_override("separation", 8)
	tag_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(tag_row)
	tag_row.add_child(UiKit.pill(_kind_name(str(row.get("kind", "passive"))), Color(accent.r, accent.g, accent.b, 0.82), 15))
	for tag_text in _item_tags(row, true).slice(0, 3):
		tag_row.add_child(UiKit.pill(str(tag_text), accent, 15))

	var effect := Label.new()
	effect.name = "EffectSummary"
	effect.text = _skill_first_effect_text(row)
	effect.position = Vector2(148, 94)
	effect.size = Vector2(430, 30)
	effect.clip_text = true
	UiKit.apply_label(effect, 17, Color(0.68, 0.86, 0.88, 1.0), 2)
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(effect)

	var divider := TextureRect.new()
	divider.name = "MetaDivider"
	divider.position = Vector2(586, 26)
	divider.size = Vector2(10, 92)
	divider.texture = load("res://assets/production/sprites/ui/ui_map_accent_strip.png")
	divider.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	divider.stretch_mode = TextureRect.STRETCH_SCALE
	divider.modulate = Color(accent.r, accent.g, accent.b, 0.30)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(divider)

	var max_label := Label.new()
	max_label.name = "MaxLevel"
	max_label.text = "最高等级"
	max_label.position = Vector2(608, 32)
	max_label.size = Vector2(112, 24)
	max_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(max_label, 16, Color(0.64, 0.78, 0.80, 1.0), 2)
	max_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(max_label)

	var max_value := Label.new()
	max_value.name = "MaxLevelValue"
	max_value.text = "等级%d" % max_level
	max_value.position = Vector2(608, 56)
	max_value.size = Vector2(112, 36)
	max_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(max_value, 28, Color(accent.r, accent.g, accent.b, 1.0), 3)
	max_value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(max_value)

	var hint := Label.new()
	hint.name = "Hint"
	hint.text = "点击查看"
	hint.position = Vector2(608, 92)
	hint.size = Vector2(112, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.apply_label(hint, 15, Color(0.86, 0.72, 0.46, 1.0), 2)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(hint)
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

func _item_tags(row: Dictionary, unlocked: bool) -> Array[String]:
	if not unlocked:
		return ["星级解锁"]
	match mode:
		"characters":
			return [_role_name(row.get("role_tag", "-")), _element_name(row.get("element_focus", "-"))]
		"weapons":
			return [_element_name(row.get("element", "-")), _weapon_special_text(row)]
		"armors":
			return ["护甲", _element_name(row.get("resist", "none"))]
		"chips":
			return ["芯片", _stat_name(row.get("stat", "stat"))]
		"pets":
			return [_role_name(row.get("role", "-")), _element_name(row.get("element", "-"))]
		"skills":
			var tags: Array[String] = []
			for tag in row.get("card_tags", []):
				tags.append(_tag_name(str(tag)))
			return tags
		_:
			return []

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

func _item_desc(item_id: String, row: Dictionary, unlocked: bool) -> String:
	if not unlocked:
		var cost := int(row.get("unlock_cost_star", row.get("unlock", {}).get("price", 0)))
		return "%s  ·  售价 %d★" % [_item_stat_summary(row), cost]
	match mode:
		"characters":
			return "定位：%s  元素：%s  %s" % [_role_name(row.get("role_tag", "-")), _element_name(row.get("element_focus", "-")), _next_upgrade_hint(item_id, row)]
		"weapons":
			return "元素：%s  射速：%s  等级%d  %s" % [_element_name(row.get("element", "-")), row.get("fire_rate", "-"), SaveManager.get_weapon_level(item_id), _weapon_special_text(row)]
		"armors":
			return "生命倍率：%.0f%%  抗性：%s  %s%s" % [float(row.get("hp_mult", 1.0)) * 100.0, _element_name(row.get("resist", "none")), _next_upgrade_hint(item_id, row), "  防线屏障 +1" if int(row.get("breach_shield", 0)) > 0 else ""]
		"chips":
			return "%s +%s  %s" % [_stat_name(row.get("stat", "stat")), _value_text(row.get("value", 0)), _next_upgrade_hint(item_id, row)]
		"pets":
			return "定位：%s  元素：%s  %s" % [_role_name(row.get("role", "-")), _element_name(row.get("element", "-")), _next_upgrade_hint(item_id, row)]
		"skills":
			return "标签：%s" % _format_tags(row.get("card_tags", []))
		_:
			return item_id

func _item_stat_summary(row: Dictionary) -> String:
	# 未拥有时也要看到的核心参数（不含升级提示），方便判断该不该买。
	match mode:
		"characters":
			return "定位：%s  元素：%s" % [_role_name(row.get("role_tag", "-")), _element_name(row.get("element_focus", "-"))]
		"weapons":
			return "元素：%s  射速：%s  %s" % [_element_name(row.get("element", "-")), str(row.get("fire_rate", "-")), _weapon_special_text(row)]
		"armors":
			return "生命倍率：%.0f%%  抗性：%s%s" % [float(row.get("hp_mult", 1.0)) * 100.0, _element_name(row.get("resist", "none")), "  防线屏障+1" if int(row.get("breach_shield", 0)) > 0 else ""]
		"chips":
			return "%s +%s" % [_stat_name(row.get("stat", "stat")), _value_text(row.get("value", 0))]
		"pets":
			return "定位：%s  元素：%s" % [_role_name(row.get("role", "-")), _element_name(row.get("element", "-"))]
		_:
			return ""

func _skill_first_effect_text(row: Dictionary) -> String:
	var levels: Array = row.get("levels", [])
	if levels.is_empty():
		return "效果：%s" % _format_tags(row.get("card_tags", []))
	var first: Dictionary = levels[0]
	var effect: Dictionary = first.get("effect", {})
	return "等级1：%s" % SkillEffectText.format_effect(effect)

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
		_:
			return str(kind)

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

func _weapon_special_text(row: Dictionary) -> String:
	var special: Dictionary = row.get("special", {})
	if special.has("pellets"):
		return "%d 弹丸" % int(special.get("pellets", 1))
	if special.has("pierce"):
		return "自带穿透 +%d" % int(special.get("pierce", 0))
	if special.has("chain"):
		return "自带连锁 +%d" % int(special.get("chain", 0))
	if special.has("splash"):
		return "溅射 %d" % int(special.get("splash", 0))
	if special.has("cloud"):
		return "毒云 %d" % int(special.get("cloud", 0))
	if special.has("spread"):
		return "扩散 %d" % int(special.get("spread", 0))
	return "标准弹道"

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
			if row.has("heal_per_wave"):
				var hg := float(row.get("level_heal_growth", 0.0))
				var hbase := float(row.get("heal_per_wave", 0))
				rows.append({"label": "每波修复", "cur": "%d" % int(round(hbase * (1.0 + hg * float(level - 1)))), "next": "%d" % int(round(hbase * (1.0 + hg * float(nxt - 1)))), "delta": "每级 +%d%%" % int(round(hg * 100.0))})
	return rows

func _next_upgrade_hint(item_id: String, row: Dictionary) -> String:
	var level := SaveManager.get_item_level(item_id)
	var max_level := int(row.get("max_level", 30))
	if level >= max_level:
		return "已满级"
	match mode:
		"weapons":
			return "下级 伤害+8% · 射速+2.5%"
		"characters":
			return "下级 攻击+%d%%" % int(round(float(row.get("atk_growth", 0.08)) * 0.52 * 100.0))
		"armors":
			return "下级 生命+%d%%" % int(round(float(row.get("hp_mult", 1.0)) * float(row.get("level_hp_growth", 0.0)) * 100.0))
		"chips":
			return "下级 %s +%s" % [_stat_name(row.get("stat", "增幅")), _value_text(float(row.get("value", 0)) * float(row.get("level_value_growth", 0.0)))]
		"pets":
			if row.has("damage"):
				return "下级 伤害+%d" % int(round(float(row.get("damage", 0)) * float(row.get("level_damage_growth", 0.0))))
			return "下级 效率提升"
		_:
			return "下级强化"

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
	var table := _data_table_name()
	var price := SaveManager.get_unlock_price_star(table, item_id)
	if not SaveManager.can_purchase(table, item_id):
		AudioManager.play_sfx("ui_click", -6.0)
		return
	AudioManager.play_sfx("ui_click", -4.0)
	var name_text: String = DataLoader.tr_key(row.get("name_key", item_id))
	var preview_icon: String = UiKit.character_bust_path(row) if mode == "characters" else str(row.get("icon", row.get("portrait", "")))
	UiKit.confirm_modal(self, {
		"title": "购买确认",
		"message": "确认解锁 %s？" % name_text,
		"cost_text": "%d" % price,
		"cost_icon": UiKit.currency_icon_path("star"),
		"item_icon": preview_icon,
		"accent": Color(0.96, 0.80, 0.30, 1.0),
		"confirm_text": "购买",
		"cancel_text": "取消",
		"on_confirm": func() -> void: _do_purchase(table, item_id),
	})

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
	if mode == "characters":
		call_deferred("_show_character_detail", item_id, row)
		return
	if _detail_modal != null and is_instance_valid(_detail_modal):
		_detail_modal.queue_free()
	var slot := _slot()
	var table := _data_table_name()
	var item_level := SaveManager.get_item_level(item_id)
	var selected := slot != "" and SaveManager.get_selected(slot) == item_id
	var accent := _mode_accent(row)
	_detail_modal = Control.new()
	_detail_modal.name = "ItemDetail"
	_detail_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_detail_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	_detail_modal.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_detail_modal)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_modal.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 72.0
	panel.offset_top = 150.0
	panel.offset_right = -72.0
	panel.offset_bottom = -140.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _build_panel_style())
	_detail_modal.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 210)
	header.add_theme_constant_override("separation", 18)
	vbox.add_child(header)

	var icon_frame := PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(196, 196)
	icon_frame.add_theme_stylebox_override("panel", _build_pill_style(accent, Color(0.06, 0.1, 0.16, 0.92)))
	header.add_child(icon_frame)
	var icon := TextureRect.new()
	icon.texture = load(row.get("icon", row.get("portrait", "")))
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
	UiKit.apply_label(name_label, 40, Color(0.98, 0.99, 1.0, 1.0), 4)
	name_label.clip_text = true
	name_row.add_child(name_label)
	var level_badge := _make_pill("等级%d%s" % [item_level, _tier_suffix(item_level)], _level_tint(item_level), Color(0.08, 0.11, 0.16, 0.92))
	level_badge.custom_minimum_size = Vector2(128, 44)
	name_row.add_child(level_badge)

	var tag_row := HBoxContainer.new()
	tag_row.add_theme_constant_override("separation", 10)
	name_col.add_child(tag_row)
	for tag_text in _item_tags(row, true).slice(0, 4):
		tag_row.add_child(_make_pill(str(tag_text), accent, Color(0.05, 0.09, 0.14, 0.82)))

	var summary := Label.new()
	summary.text = _item_desc(item_id, row, true)
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(summary, 21, Color(0.78, 0.91, 1.0, 1.0), 3)
	name_col.add_child(summary)

	var close_btn := _compact_close_button("CloseButton")
	close_btn.pressed.connect(_close_character_detail)
	header.add_child(close_btn)

	var content_scroll := ScrollContainer.new()
	content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(content_scroll)
	var detail_content := VBoxContainer.new()
	detail_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_content.add_theme_constant_override("separation", 12)
	content_scroll.add_child(detail_content)

	var stats_section := _make_section_panel("核心数据", accent)
	detail_content.add_child(stats_section)
	var stats_grid := GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 12)
	stats_grid.add_theme_constant_override("v_separation", 10)
	stats_section.get_child(0).add_child(stats_grid)
	for stat in _detail_stats_for_item(item_id, row, item_level):
		stats_grid.add_child(_make_stat_pill(str(stat.get("label", "")), str(stat.get("value", "")), str(stat.get("sub", ""))))
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
		detail_content.add_child(_make_skill_levels_section(row, accent))

	var desc_section := _make_section_panel("战术说明", Color(0.68, 0.82, 1.0, 0.82))
	detail_content.add_child(desc_section)
	var desc_label := Label.new()
	desc_label.text = _detail_body_text(item_id, row)
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(desc_label, 20, Color(0.9, 0.96, 1.0, 1.0), 3)
	desc_section.get_child(0).add_child(desc_label)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 16)
	vbox.add_child(action_row)
	if mode != "skills" and not SaveManager.is_item_unlocked(slot, item_id):
		# 未拥有：详情页里直接给购买按钮（买得起=亮，买不起=灰禁用）。
		var buy_price := SaveManager.get_unlock_price_star(table, item_id)
		var can_buy := SaveManager.get_player_star() >= buy_price
		var buy_btn := _detail_button("BuyButton", ("购买  %d★" % buy_price) if can_buy else ("星星不足  %d★" % buy_price), true)
		buy_btn.disabled = not can_buy
		buy_btn.modulate = Color.WHITE if can_buy else Color(0.5, 0.54, 0.6, 0.82)
		buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buy_btn.pressed.connect(_purchase_item_flow.bind(item_id, row))
		action_row.add_child(buy_btn)
	elif mode != "skills":
		var equip_btn := _detail_button("EquipButton", "已装备" if selected else "装  备", true)
		equip_btn.disabled = selected
		equip_btn.modulate = Color(0.58, 0.62, 0.68, 0.88) if selected else Color.WHITE
		equip_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		equip_btn.size_flags_stretch_ratio = 1.35
		equip_btn.pressed.connect(_select_item_and_close.bind(slot, item_id))
		action_row.add_child(equip_btn)

		var can_upgrade := table != "" and SaveManager.can_upgrade_item(table, item_id)
		var cost := SaveManager.get_item_upgrade_cost(table, item_id) if table != "" else 0
		var upgrade_btn := _detail_button("UpgradeButton", "升级  %d" % cost, false)
		upgrade_btn.disabled = not can_upgrade
		upgrade_btn.modulate = Color.WHITE if can_upgrade else Color(0.5, 0.54, 0.6, 0.82)
		upgrade_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		upgrade_btn.pressed.connect(_upgrade_item_from_detail.bind(item_id, row))
		action_row.add_child(upgrade_btn)
	else:
		var skill_lvl := SaveManager.get_skill_base_level(item_id)
		var skill_max := SaveManager.get_skill_base_max(item_id)
		var skill_cost := SaveManager.get_skill_base_upgrade_cost(item_id)
		var can_up := SaveManager.can_upgrade_skill_base(item_id)
		var skill_label := ("已精通 %d/%d" % [skill_lvl, skill_max]) if skill_lvl >= skill_max else ("升级 %d经验  (%d/%d)" % [skill_cost, skill_lvl, skill_max])
		var skill_btn := _detail_button("SkillUpgradeButton", skill_label, true)
		skill_btn.disabled = not can_up
		skill_btn.modulate = Color.WHITE if can_up else Color(0.5, 0.54, 0.6, 0.82)
		skill_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		skill_btn.size_flags_stretch_ratio = 1.35
		skill_btn.pressed.connect(_upgrade_skill_from_detail.bind(item_id, row))
		action_row.add_child(skill_btn)
	var close_bottom := _detail_button("CloseBottomButton", "关  闭", false)
	close_bottom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_bottom.pressed.connect(_close_character_detail)
	action_row.add_child(close_bottom)

	_detail_modal.modulate.a = 0.0
	panel.scale = Vector2(0.95, 0.95)
	var tween := _detail_modal.create_tween()
	tween.parallel().tween_property(_detail_modal, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _detail_button(node_name: String, text: String, primary: bool) -> TextureButton:
	var button := TextureButton.new()
	button.name = node_name
	button.texture_normal = load(BUTTON_SECONDARY)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.custom_minimum_size = Vector2(0, 90)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.modulate = Color(1.0, 0.86, 0.54, 1.0) if primary else Color(0.86, 0.90, 0.92, 1.0)
	var label := Label.new()
	label.text = text
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiKit.apply_label(label, 30, Color.WHITE, 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	return button

func _compact_close_button(node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = "×"
	button.custom_minimum_size = Vector2(56, 56)
	button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", 34)
	button.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0, 0.95))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.86, 0.45, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.78, 0.9, 1.0, 1.0))
	button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.65))
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_stylebox_override("normal", _compact_close_style(Color(0.02, 0.035, 0.05, 0.42), Color(0.55, 0.68, 0.78, 0.45)))
	button.add_theme_stylebox_override("hover", _compact_close_style(Color(0.06, 0.055, 0.035, 0.72), Color(1.0, 0.76, 0.32, 0.86)))
	button.add_theme_stylebox_override("pressed", _compact_close_style(Color(0.01, 0.02, 0.03, 0.82), Color(0.56, 0.82, 1.0, 0.9)))
	button.add_theme_stylebox_override("disabled", _compact_close_style(Color(0.02, 0.025, 0.03, 0.30), Color(0.35, 0.4, 0.45, 0.35)))
	return button

func _compact_close_style(_bg: Color, _border: Color) -> StyleBox:
	return UiKit.map_pill_texture_style()

func _detail_stats_for_item(item_id: String, row: Dictionary, item_level: int) -> Array:
	var stats := []
	var table := _data_table_name()
	var max_level := int(row.get("max_level", 0))
	if mode != "skills":
		stats.append({"label": "等级", "value": "%d / %d" % [item_level, max_level], "sub": _growth_badge_text(item_level)})
	if mode != "skills" and table != "":
		stats.append({"label": "升级", "value": "%d 金币" % SaveManager.get_item_upgrade_cost(table, item_id), "sub": _next_upgrade_hint(item_id, row)})
	match mode:
		"weapons":
			stats.append({"label": "元素", "value": _element_name(row.get("element", "-")), "sub": str(row.get("projectile_type", "弹道"))})
			stats.append({"label": "攻击", "value": "%.0f%%" % (float(row.get("base_atk_coef", 1.0)) * 100.0), "sub": "等级伤害 %.0f%%" % ((SaveManager.get_weapon_damage_multiplier(item_id) - 1.0) * 100.0)})
			stats.append({"label": "射速", "value": "%.1f / 秒" % float(row.get("fire_rate", 0.0)), "sub": "等级射速 %.0f%%" % ((SaveManager.get_weapon_fire_rate_multiplier(item_id) - 1.0) * 100.0)})
			stats.append({"label": "弹速", "value": "%d" % int(row.get("projectile_speed", 0)), "sub": _weapon_special_text(row)})
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
			if row.has("damage"):
				var pet_g := float(row.get("level_damage_growth", 0.0))
				var pet_now := float(row.get("damage", 0)) * (1.0 + pet_g * float(max(item_level - 1, 0)))
				var pet_max := float(row.get("damage", 0)) * (1.0 + pet_g * float(max(max_level - 1, 0)))
				stats.append({"label": "伤害", "value": "%d" % int(round(pet_now)), "sub": "等级%d · 满级 %d" % [item_level, int(round(pet_max))]})
			if row.has("fire_rate"):
				stats.append({"label": "频率", "value": "%.1f / 秒" % float(row.get("fire_rate", 0.0)), "sub": "自动协战"})
			if row.has("heal_per_wave"):
				stats.append({"label": "修复", "value": "%d / 波" % int(row.get("heal_per_wave", 0)), "sub": "每级 +%d%%" % int(round(float(row.get("level_heal_growth", 0.0)) * 100.0))})
			if row.has("gold_mult"):
				stats.append({"label": "收益", "value": _value_text(row.get("gold_mult", 0)), "sub": "每级 +%s" % _value_text(row.get("level_gold_growth", 0))})
		"skills":
			var levels: Array = row.get("levels", [])
			stats.append({"label": "类型", "value": _kind_name(str(row.get("kind", "passive"))), "sub": _format_tags(row.get("card_tags", []))})
			stats.append({"label": "上限", "value": "等级%d" % levels.size(), "sub": "逐级叠加"})
	return stats

func _detail_body_text(item_id: String, row: Dictionary) -> String:
	match mode:
		"weapons":
			return "点击装备后进入出战配置。武器的元素、射速和弹道特性会决定局内基础手感；升级会提高伤害并少量提高射速。"
		"armors":
			return "护甲主要提高基地承伤和防线容错。高级护甲不是纯数值堆叠，抗性和屏障会影响特定关卡的防线稳定性。"
		"chips":
			return "芯片是核心加成位，偏向伤害、射速、暴击、生命、收益或元素流派。当前芯片会进入战力和关卡克制计算。"
		"pets":
			return "宠物提供自动协战、控制、修复或经济收益。它不替代主武器，但会补足阵容短板。"
		"skills":
			return "技能图鉴只用于查看局内卡牌成长。下方会列出每一级的具体数值，便于判断加点性价比；战斗中同名技能按等级叠加，互斥弹种会以当前主弹种为准。"
		_:
			return _item_desc(item_id, row, true)

func _make_skill_levels_section(row: Dictionary, accent: Color) -> PanelContainer:
	var section := _make_section_panel("各级加成", accent)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.get_child(0).add_child(list)
	for level in row.get("levels", []):
		var lv := int(level.get("lv", list.get_child_count() + 1))
		var effect: Dictionary = level.get("effect", {})
		list.add_child(_make_skill_level_row(lv, SkillEffectText.format_effect(effect), accent))
	return section

func _make_skill_level_row(level: int, effect_text: String, accent: Color) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pill.custom_minimum_size = Vector2(0, 58)
	pill.add_theme_stylebox_override("panel", _build_pill_style(Color(accent.r, accent.g, accent.b, 0.72), Color(0.026, 0.036, 0.048, 0.78)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pill.add_child(row)
	var level_label := Label.new()
	level_label.text = "等级%d" % level
	level_label.custom_minimum_size = Vector2(88, 0)
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 20)
	level_label.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 1.0))
	level_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	level_label.add_theme_constant_override("outline_size", 2)
	row.add_child(level_label)
	var value_label := Label.new()
	value_label.text = effect_text
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 19)
	value_label.add_theme_color_override("font_color", Color(0.78, 0.92, 1.0, 0.96))
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
	# 返回安全区(刘海/灵动岛/home 条)在画布坐标下的 左/上/右/下 内距;桌面/无刘海≈0。
	var win := DisplayServer.window_get_size()
	if win.x <= 0 or win.y <= 0:
		return Vector4.ZERO
	var safe := DisplayServer.get_display_safe_area()
	var vis := get_viewport().get_visible_rect().size
	var sx := vis.x / float(win.x)
	var sy := vis.y / float(win.y)
	return Vector4(
		maxf(float(safe.position.x) * sx, 0.0),
		maxf(float(safe.position.y) * sy, 0.0),
		maxf(float(win.x - safe.position.x - safe.size.x) * sx, 0.0),
		maxf(float(win.y - safe.position.y - safe.size.y) * sy, 0.0)
	)

func _show_character_detail(item_id: String, row: Dictionary) -> void:
	if _detail_modal != null and is_instance_valid(_detail_modal):
		_detail_modal.queue_free()
	_detail_modal = Control.new()
	_detail_modal.name = "CharacterDetail"
	_detail_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_detail_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	_detail_modal.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_detail_modal)
	# Dim background
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_modal.add_child(dim)
	# === Outer panel: card with proper framing ===
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var safe := _safe_area_canvas_insets()
	panel.offset_left = 60.0 + safe.x
	panel.offset_top = 90.0 + safe.y
	panel.offset_right = -60.0 - safe.z
	panel.offset_bottom = -90.0 - safe.w
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	UiKit.add_character_bust(portrait, row, Vector2(230, 230), 320.0, -54.0)
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
	name_label.text = DataLoader.tr_key(row.get("name_key", item_id))
	name_label.add_theme_font_size_override("font_size", 44)
	name_label.add_theme_color_override("font_color", Color(0.98, 0.99, 1, 1))
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	name_label.add_theme_constant_override("outline_size", 4)
	name_row.add_child(name_label)
	# Level badge
	var level_badge := PanelContainer.new()
	level_badge.add_theme_stylebox_override("panel", _build_level_badge_style())
	level_badge.custom_minimum_size = Vector2(104, 44)
	name_row.add_child(level_badge)
	var level_text := Label.new()
	level_text.text = "等级%d" % item_level
	level_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_text.add_theme_font_size_override("font_size", 24)
	level_text.add_theme_color_override("font_color", Color(1, 0.92, 0.5, 1))
	level_badge.add_child(level_text)
	# Tag row: role + element
	var tag_row := HBoxContainer.new()
	tag_row.add_theme_constant_override("separation", 10)
	name_col.add_child(tag_row)
	tag_row.add_child(_make_pill(_role_name(row.get("role_tag", "-")), Color(0.32, 0.62, 0.85), Color(0.18, 0.42, 0.6, 0.7)))
	tag_row.add_child(_make_pill(_element_name(row.get("element_focus", "-")), _element_color(row.get("element_focus", "physical")), _element_color_dark(row.get("element_focus", "physical"))))
	# Bullet affinity summary
	var affinity: Dictionary = row.get("bullet_affinity", {})
	if not affinity.is_empty():
		var affinity_text := "弹种亲和 · "
		var bonuses: Array[String] = []
		var elem := str(affinity.get("element", ""))
		if elem != "":
			bonuses.append(_element_name(elem) + "弹")
		var dmg := float(affinity.get("damage_bonus", 0.0))
		if dmg > 0.0:
			bonuses.append("伤害 +%d%%" % int(dmg * 100))
		var pierce := int(affinity.get("pierce_bonus", 0))
		if pierce > 0:
			bonuses.append("穿透 +%d" % pierce)
		var splash := float(affinity.get("splash_bonus", 0.0))
		if splash > 0.0:
			bonuses.append("爆燃 +%d" % int(splash))
		if bonuses.size() > 0:
			affinity_text += "  ".join(bonuses)
			var affinity_label := Label.new()
			affinity_label.text = affinity_text
			affinity_label.add_theme_font_size_override("font_size", 19)
			affinity_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1, 0.95))
			affinity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			name_col.add_child(affinity_label)
	# Compact top-right close affordance; the bottom action row remains the primary close path.
	var close_btn := _compact_close_button("CloseButton")
	close_btn.pressed.connect(_close_character_detail)
	hero.add_child(close_btn)

	var content_scroll := ScrollContainer.new()
	content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(content_scroll)
	var detail_content := VBoxContainer.new()
	detail_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_content.add_theme_constant_override("separation", 12)
	content_scroll.add_child(detail_content)

	# === BASE STATS section (cyan accent) ===
	var stats_section := _make_section_panel("基础属性", Color(0.58, 0.72, 0.82, 0.85))
	detail_content.add_child(stats_section)
	var stats_grid := GridContainer.new()
	stats_grid.columns = 3
	stats_grid.add_theme_constant_override("h_separation", 14)
	stats_grid.add_theme_constant_override("v_separation", 10)
	stats_section.get_child(0).add_child(stats_grid)
	stats_grid.add_child(_make_stat_pill("攻  击", str(int(row.get("base_atk", 0))), "+%.1f%% / 级" % (float(row.get("atk_growth", 0)) * 45.0)))
	stats_grid.add_child(_make_stat_pill("血  量", str(int(row.get("base_hp", 0))), "+%.1f%% / 级" % (float(row.get("hp_growth", 0)) * 45.0)))
	stats_grid.add_child(_make_stat_pill("暴  击", "%.0f%%" % (float(row.get("crit_rate_base", 0)) * 100.0), ""))
	stats_grid.add_child(_make_stat_pill("射  速", "%.2f×" % float(row.get("fire_rate_mod", 1.0)), ""))
	stats_grid.add_child(_make_stat_pill("瞄  准", "%.2f×" % float(row.get("aim_turn_speed", 1.0)), ""))
	# Empty 6th slot for grid alignment
	var filler := Label.new()
	filler.text = ""
	stats_grid.add_child(filler)

	# === PASSIVE section (green accent) ===
	var passive_id := str(row.get("passive", ""))
	var passive_info: Dictionary = CharacterSkillText.passive_info(passive_id)
	var passive_section := _make_section_panel("被  动", Color(0.48, 0.74, 0.50, 0.85))
	detail_content.add_child(passive_section)
	passive_section.get_child(0).add_child(_make_skill_row(
		null,  # no icon asset, use bullet
		passive_info["name"],
		"被动天赋",
		passive_info["desc"],
		UiKit.GREEN,
		passive_section
	))

	# === SIGNATURE SKILLS section (gold accent) ===
	var sig_section := _make_section_panel("专属技能", Color(0.92, 0.68, 0.34, 0.85))
	detail_content.add_child(sig_section)
	var sig_ids: Array = row.get("signature_skills", [])
	if sig_ids.is_empty():
		var empty := Label.new()
		empty.text = "（暂无）"
		empty.add_theme_font_size_override("font_size", 22)
		empty.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		sig_section.get_child(0).add_child(empty)
	else:
		for sig_id in sig_ids:
			var info: Dictionary = CharacterSkillText.signature_info(sig_id)
			var kind: String = "主动" if sig_id in ["sig_vanguard_railvolley", "sig_blaze_meltdown", "sig_frost_glacier", "sig_volt_storm"] else "弹种"
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

	# === AFFINITY TAGS section ===
	var card_affinity: Array = row.get("card_affinity_tags", [])
	if not card_affinity.is_empty():
		var aff_section := _make_section_panel("流派倾向", Color(0.7, 0.7, 0.85, 0.7))
		detail_content.add_child(aff_section)
		var aff_row := HBoxContainer.new()
		aff_row.add_theme_constant_override("separation", 8)
		aff_section.get_child(0).add_child(aff_row)
		for tag in card_affinity:
			aff_row.add_child(_make_pill(str(tag), Color(0.45, 0.55, 0.85), Color(0.22, 0.32, 0.6, 0.8)))

	# === Action buttons row ===
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer)
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 16)
	vbox.add_child(action_row)
	var select_btn := TextureButton.new()
	select_btn.texture_normal = load(BUTTON_SECONDARY)
	select_btn.ignore_texture_size = true
	select_btn.stretch_mode = TextureButton.STRETCH_SCALE
	select_btn.custom_minimum_size = Vector2(0, 110)
	select_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select_btn.size_flags_stretch_ratio = 2.0
	select_btn.disabled = selected
	select_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	select_btn.modulate = Color(1.0, 0.86, 0.54, 1.0) if not selected else Color(0.68, 0.72, 0.76, 0.84)
	select_btn.pressed.connect(_select_character_and_close.bind(item_id))
	var select_label := Label.new()
	select_label.text = "已装备" if selected else "选  定"
	select_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	select_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	select_label.add_theme_font_size_override("font_size", 36)
	select_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	select_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	select_label.add_theme_constant_override("outline_size", 3)
	select_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	select_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	select_btn.add_child(select_label)
	action_row.add_child(select_btn)
	var cancel_btn := TextureButton.new()
	cancel_btn.texture_normal = load(BUTTON_SECONDARY)
	cancel_btn.ignore_texture_size = true
	cancel_btn.stretch_mode = TextureButton.STRETCH_SCALE
	cancel_btn.custom_minimum_size = Vector2(0, 110)
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.size_flags_stretch_ratio = 1.0
	cancel_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	cancel_btn.pressed.connect(_close_character_detail)
	var cancel_label := Label.new()
	cancel_label.text = "关  闭"
	cancel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cancel_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cancel_label.add_theme_font_size_override("font_size", 36)
	cancel_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	cancel_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	cancel_label.add_theme_constant_override("outline_size", 3)
	cancel_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	cancel_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cancel_btn.add_child(cancel_label)
	action_row.add_child(cancel_btn)

	_detail_modal.modulate.a = 1.0
	panel.scale = Vector2.ONE

# === Helper builders for the modal ===

func _build_panel_style() -> StyleBox:
	return UiKit.result_panel_texture_style()

func _build_portrait_frame_style() -> StyleBox:
	return UiKit.icon_frame_texture_style(true)

func _build_level_badge_style() -> StyleBox:
	return UiKit.map_pill_texture_style()

func _build_skill_card_style(_accent: Color) -> StyleBox:
	return UiKit.collection_card_texture_style(true)

func _build_skill_icon_frame_style(_accent: Color) -> StyleBox:
	return UiKit.icon_frame_texture_style(false)

func _make_pill(text: String, border_color: Color, fill_color: Color) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", _build_pill_style(border_color, fill_color))
	pill.custom_minimum_size = Vector2(0, 34)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.96, 0.98, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("outline_size", 1)
	pill.add_child(label)
	return pill

func _build_pill_style(_border_color: Color, _fill_color: Color) -> StyleBox:
	return UiKit.map_pill_texture_style()

func _make_section_panel(title: String, accent: Color) -> PanelContainer:
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
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1, 1))
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	title_label.add_theme_constant_override("outline_size", 1)
	title_row.add_child(title_label)
	return panel

func _build_section_style(_accent: Color) -> StyleBox:
	return UiKit.panel_texture_style(14.0)

func _make_stat_pill(label_text: String, value_text: String, sub_text: String) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pill.custom_minimum_size = Vector2(0, 72)
	pill.add_theme_stylebox_override("panel", _build_pill_style(Color(0.58, 0.68, 0.74, 0.50), Color(0.026, 0.036, 0.048, 0.72)))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	pill.add_child(v)
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color(0.7, 0.88, 1, 0.9))
	v.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", 27)
	value.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	value.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	value.add_theme_constant_override("outline_size", 1)
	v.add_child(value)
	if sub_text != "":
		var sub := Label.new()
		sub.text = sub_text
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sub.add_theme_font_size_override("font_size", 14)
		sub.add_theme_color_override("font_color", Color(0.55, 0.85, 1, 0.75))
		v.add_child(sub)
	return pill

func _make_skill_row(icon_path, title: String, kind_label: String, desc: String, accent: Color, parent: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, 102)
	# Icon
	var icon_box := PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(78, 78)
	icon_box.add_theme_stylebox_override("panel", _build_pill_style(accent, Color(0.06, 0.1, 0.16, 0.85)))
	row.add_child(icon_box)
	if icon_path != null and str(icon_path) != "" and ResourceLoader.exists(str(icon_path)):
		var icon := TextureRect.new()
		icon.texture = load(str(icon_path))
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(64, 64)
		icon_box.add_child(icon)
	else:
		var placeholder := Label.new()
		placeholder.text = "◆"
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder.add_theme_font_size_override("font_size", 32)
		placeholder.add_theme_color_override("font_color", accent)
		icon_box.add_child(placeholder)
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
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.98, 0.99, 1, 1))
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	title_label.add_theme_constant_override("outline_size", 1)
	title_row.add_child(title_label)
	# Kind pill
	var kind_pill := PanelContainer.new()
	kind_pill.add_theme_stylebox_override("panel", _build_pill_style(accent, Color(0.06, 0.1, 0.16, 0.85)))
	title_row.add_child(kind_pill)
	var kind_label_text := Label.new()
	kind_label_text.text = kind_label
	kind_label_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kind_label_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	kind_label_text.add_theme_font_size_override("font_size", 16)
	kind_label_text.add_theme_color_override("font_color", accent)
	kind_pill.add_child(kind_label_text)
	# Description
	var desc_label := Label.new()
	desc_label.text = desc
	desc_label.add_theme_font_size_override("font_size", 17)
	desc_label.add_theme_color_override("font_color", Color(0.78, 0.88, 0.95, 1))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_col.add_child(desc_label)
	return row

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

func _select_character_and_close(item_id: String) -> void:
	if SaveManager.select_item("character", item_id):
		AudioManager.play_sfx("ui_confirm")
		_refresh()
	_close_character_detail()
