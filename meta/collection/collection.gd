extends Control

const BUTTON_PRIMARY := "res://assets/sprites/ui/ui_button_primary.png"
const BUTTON_SECONDARY := "res://assets/sprites/ui/ui_button_secondary.png"
const CharacterSkillText := preload("res://core/data/character_skill_text.gd")

var router: Node
var mode := "characters"
var _detail_modal: Control = null

func setup(main: Node, payload := {}) -> void:
	router = main
	mode = payload.get("mode", "characters")
	_refresh()

func _ready() -> void:
	$BackButton.pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_click")
		router.change_scene("map")
	)
	_refresh()

func _refresh() -> void:
	if not is_inside_tree():
		return
	$Title.text = _title()
	$Progress.text = "星星 %d  金币 %d" % [SaveManager.get_total_stars(), SaveManager.get_player_gold()]
	for child in $ItemScroll/ItemList.get_children():
		child.queue_free()
	var table_data: Dictionary = _table()
	for item_id: String in table_data.keys():
		$ItemScroll/ItemList.add_child(_build_item_button(item_id, table_data[item_id]))

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
	var slot := _slot()
	var unlocked := true if mode == "skills" else SaveManager.is_item_unlocked(slot, item_id)
	var selected := slot != "" and SaveManager.get_selected(slot) == item_id
	var item_level := SaveManager.get_item_level(item_id)
	var button := TextureButton.new()
	button.name = item_id
	button.custom_minimum_size = Vector2(760, 128)
	button.texture_normal = load(BUTTON_PRIMARY if unlocked else BUTTON_SECONDARY)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.clip_contents = true
	button.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.52, 0.52, 0.52, 0.88)
	button.disabled = not unlocked
	if unlocked and slot != "" and mode != "characters":
		button.pressed.connect(_select_item.bind(slot, item_id))
	elif mode == "characters" and unlocked:
		button.pressed.connect(_show_character_detail.bind(item_id, row))

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = load(row.get("icon", row.get("portrait", "")))
	icon.position = Vector2(24, 20)
	icon.size = Vector2(88, 88)
	icon.custom_minimum_size = Vector2(88, 88)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.modulate = _level_tint(item_level)
	button.add_child(icon)
	icon.set_deferred("position", Vector2(24, 20))
	icon.set_deferred("size", Vector2(88, 88))

	var title := Label.new()
	title.text = "%s  Lv.%d%s%s" % [DataLoader.tr_key(row.get("name_key", item_id)), item_level, _tier_suffix(item_level), "  已装备" if selected else ""]
	title.position = Vector2(132, 18)
	title.size = Vector2(420, 40)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", _level_tint(item_level))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(title)

	var desc := Label.new()
	desc.text = _item_desc(item_id, row, unlocked)
	desc.position = Vector2(134, 64)
	desc.size = Vector2(450, 48)
	desc.add_theme_font_size_override("font_size", 21)
	desc.add_theme_color_override("font_color", Color(0.72, 0.9, 1.0) if unlocked else Color(0.78, 0.78, 0.78))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(desc)

	if unlocked and mode != "skills":
		var badge := Label.new()
		badge.name = "GrowthBadge"
		badge.text = _growth_badge_text(item_level)
		badge.position = Vector2(604, 72)
		badge.size = Vector2(126, 32)
		badge.add_theme_font_size_override("font_size", 17)
		badge.add_theme_color_override("font_color", _level_tint(item_level))
		badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		badge.add_theme_constant_override("outline_size", 2)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(badge)

		var up := Button.new()
		up.name = "UpgradeButton"
		up.text = "升级 %d" % SaveManager.get_item_upgrade_cost(_data_table_name(), item_id)
		up.position = Vector2(596, 20)
		up.size = Vector2(136, 42)
		up.add_theme_font_size_override("font_size", 18)
		up.disabled = not SaveManager.can_upgrade_item(_data_table_name(), item_id)
		up.mouse_filter = Control.MOUSE_FILTER_STOP
		_style_upgrade_button(up, item_level)
		up.pressed.connect(_upgrade_item.bind(item_id))
		button.add_child(up)
	return button

func _style_upgrade_button(button: Button, item_level: int) -> void:
	var rank := _growth_rank(item_level)
	button.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.62, 0.68, 0.78))
	button.add_theme_stylebox_override("normal", _upgrade_style(Color(0.12, 0.22, 0.34, 0.9), Color(0.35, 0.58, 0.86, 0.85 + 0.04 * rank)))
	button.add_theme_stylebox_override("hover", _upgrade_style(Color(0.16, 0.31, 0.48, 0.95), Color(0.56, 0.78, 1.0, 0.95)))
	button.add_theme_stylebox_override("pressed", _upgrade_style(Color(0.08, 0.16, 0.25, 0.96), Color(0.35, 0.68, 1.0, 0.95)))
	button.add_theme_stylebox_override("disabled", _upgrade_style(Color(0.08, 0.1, 0.14, 0.76), Color(0.28, 0.34, 0.44, 0.78)))

func _upgrade_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 8
	style.content_margin_right = 8
	return style

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
		return "需要 %d 星解锁" % cost
	match mode:
		"characters":
			return "定位：%s  元素：%s  %s" % [_role_name(row.get("role_tag", "-")), _element_name(row.get("element_focus", "-")), _next_upgrade_hint(item_id, row)]
		"weapons":
			return "元素：%s  射速：%s  Lv.%d  %s" % [_element_name(row.get("element", "-")), row.get("fire_rate", "-"), SaveManager.get_weapon_level(item_id), _weapon_special_text(row)]
		"armors":
			return "生命倍率：%.0f%%  抗性：%s  %s%s" % [float(row.get("hp_mult", 1.0)) * 100.0, _element_name(row.get("resist", "none")), _next_upgrade_hint(item_id, row), "  越线护盾 +1" if int(row.get("breach_shield", 0)) > 0 else ""]
		"chips":
			return "%s +%s  %s" % [_stat_name(row.get("stat", "stat")), _value_text(row.get("value", 0)), _next_upgrade_hint(item_id, row)]
		"pets":
			return "定位：%s  元素：%s  %s" % [_role_name(row.get("role", "-")), _element_name(row.get("element", "-")), _next_upgrade_hint(item_id, row)]
		"skills":
			return "标签：%s" % _format_tags(row.get("card_tags", []))
		_:
			return item_id

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
			return "越线减伤"
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

func _next_upgrade_hint(item_id: String, row: Dictionary) -> String:
	var level := SaveManager.get_item_level(item_id)
	var max_level := int(row.get("max_level", 30))
	if level >= max_level:
		return "已满级"
	var next := level + 1
	if [8, 15, 25].has(next):
		return "下级解锁质变档"
	match mode:
		"characters":
			return "下级攻防成长"
		"armors":
			return "下级生命成长"
		"chips":
			return "下级芯片增幅"
		"pets":
			return "下级宠物效率"
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

func _pulse_selected_item(item_id: String) -> void:
	for child in $ItemScroll/ItemList.get_children():
		if child.name != item_id:
			continue
		var tween := child.create_tween()
		tween.tween_property(child, "scale", Vector2(1.035, 1.035), 0.08)
		tween.tween_property(child, "scale", Vector2.ONE, 0.12)
		return

# ========== Character detail modal ==========

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
	# Panel
	var panel := Panel.new()
	panel.name = "Panel"
	panel.offset_left = 100.0
	panel.offset_top = 140.0
	panel.offset_right = 980.0
	panel.offset_bottom = 1620.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_modal.add_child(panel)
	# Close X (top-right)
	var close_btn := TextureButton.new()
	close_btn.texture_normal = load(BUTTON_SECONDARY)
	close_btn.ignore_texture_size = true
	close_btn.stretch_mode = TextureButton.STRETCH_SCALE
	close_btn.offset_left = 820.0
	close_btn.offset_top = 16.0
	close_btn.offset_right = 980.0
	close_btn.offset_bottom = 176.0
	close_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	close_btn.pressed.connect(_close_character_detail)
	var close_label := Label.new()
	close_label.text = "✕"
	close_label.add_theme_font_size_override("font_size", 56)
	close_label.add_theme_color_override("font_color", Color(1, 1, 1))
	close_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	close_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	close_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close_btn.add_child(close_label)
	panel.add_child(close_btn)
	# Big portrait
	var portrait := TextureRect.new()
	portrait.texture = load(row.get("portrait", ""))
	portrait.offset_left = 36.0
	portrait.offset_top = 36.0
	portrait.offset_right = 320.0
	portrait.offset_bottom = 320.0
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(portrait)
	# Build text content on the right side
	var item_level := SaveManager.get_item_level(item_id)
	var selected := SaveManager.get_selected("character") == item_id
	var content_lines: Array[String] = []
	content_lines.append("%s  Lv.%d%s" % [DataLoader.tr_key(row.get("name_key", item_id)), item_level, _tier_suffix(item_level)])
	content_lines.append("定位：%s    元素：%s" % [_role_name(row.get("role_tag", "-")), _element_name(row.get("element_focus", "-"))])
	content_lines.append("")
	content_lines.append("─── 基础属性 ───")
	content_lines.append("基础攻击   %d    每级 +%.1f%%" % [int(row.get("base_atk", 0)), float(row.get("atk_growth", 0)) * 45.0])
	content_lines.append("基础血量   %d    每级 +%.1f%%" % [int(row.get("base_hp", 0)), float(row.get("hp_growth", 0)) * 45.0])
	content_lines.append("暴击率     %.0f%%" % [float(row.get("crit_rate_base", 0)) * 100.0])
	content_lines.append("射速倍率   %.2f×" % float(row.get("fire_rate_mod", 1.0)))
	content_lines.append("瞄准速度   %.2f×" % float(row.get("aim_turn_speed", 1.0)))
	content_lines.append("")
	# Passive
	var passive_id := str(row.get("passive", ""))
	var passive_info: Dictionary = CharacterSkillText.passive_info(passive_id)
	content_lines.append("─── 被动 ───")
	content_lines.append("「%s」" % passive_info["name"])
	content_lines.append("  %s" % passive_info["desc"])
	content_lines.append("")
	# Signature skills
	content_lines.append("─── 专属技能 ───")
	var sig_ids: Array = row.get("signature_skills", [])
	if sig_ids.is_empty():
		content_lines.append("  （无）")
	else:
		for sig_id in sig_ids:
			var info: Dictionary = CharacterSkillText.signature_info(sig_id)
			content_lines.append("▸ %s" % info["name"])
			content_lines.append("   %s" % info["desc"])
	content_lines.append("")
	# Affinity tags
	var affinity: Array = row.get("card_affinity_tags", [])
	if not affinity.is_empty():
		content_lines.append("─── 流派倾向 ───")
		content_lines.append("  %s" % ", ".join(affinity))
	content_lines.append("")
	# Action buttons
	var y_button := 1320.0
	var action_y_text := "选定"
	if selected:
		action_y_text = "已装备"
	var select_btn := TextureButton.new()
	select_btn.texture_normal = load(BUTTON_PRIMARY)
	select_btn.ignore_texture_size = true
	select_btn.stretch_mode = TextureButton.STRETCH_SCALE
	select_btn.offset_left = 360.0
	select_btn.offset_top = y_button
	select_btn.offset_right = 740.0
	select_btn.offset_bottom = y_button + 110.0
	select_btn.disabled = selected
	select_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	select_btn.pressed.connect(_select_character_and_close.bind(item_id))
	var select_label := Label.new()
	select_label.text = action_y_text
	select_label.add_theme_font_size_override("font_size", 36)
	select_label.add_theme_color_override("font_color", Color(1, 1, 1))
	select_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	select_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	select_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	select_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	select_btn.add_child(select_label)
	panel.add_child(select_btn)
	var cancel_btn := TextureButton.new()
	cancel_btn.texture_normal = load(BUTTON_SECONDARY)
	cancel_btn.ignore_texture_size = true
	cancel_btn.stretch_mode = TextureButton.STRETCH_SCALE
	cancel_btn.offset_left = 760.0
	cancel_btn.offset_top = y_button
	cancel_btn.offset_right = 940.0
	cancel_btn.offset_bottom = y_button + 110.0
	cancel_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	cancel_btn.pressed.connect(_close_character_detail)
	var cancel_label := Label.new()
	cancel_label.text = "关闭"
	cancel_label.add_theme_font_size_override("font_size", 36)
	cancel_label.add_theme_color_override("font_color", Color(1, 1, 1))
	cancel_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	cancel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cancel_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cancel_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cancel_btn.add_child(cancel_label)
	panel.add_child(cancel_btn)
	# Text content as single Label
	var content := Label.new()
	content.text = "\n".join(content_lines)
	content.offset_left = 360.0
	content.offset_top = 36.0
	content.offset_right = 880.0
	content.offset_bottom = y_button - 20.0
	content.add_theme_font_size_override("font_size", 24)
	content.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content)
	# Entrance animation
	_detail_modal.modulate.a = 0.0
	panel.scale = Vector2(0.94, 0.94)
	var tween := _detail_modal.create_tween()
	tween.parallel().tween_property(_detail_modal, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _close_character_detail() -> void:
	if _detail_modal != null and is_instance_valid(_detail_modal):
		_detail_modal.queue_free()
	_detail_modal = null

func _select_character_and_close(item_id: String) -> void:
	if SaveManager.select_item("character", item_id):
		AudioManager.play_sfx("ui_confirm")
		_refresh()
	_close_character_detail()
