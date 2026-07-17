extends Control

const UiKit := preload("res://ui/ui_kit.gd")
const CharacterSkillText := preload("res://core/data/character_skill_text.gd")
const ChallengeRules := preload("res://core/data/challenge_rules.gd")
const MAIN_ICON_SIZE := Vector2(296, 296)
const HERO_BUST_WINDOW_SIZE := Vector2(336, 282)
const HERO_BUST_IMAGE_WIDTH := 378.0
# All four frameless portraits share the same 642x962 source canvas. At the
# authored zoom their first opaque pixels begin about 39px below the image top;
# -30 keeps roughly 10px of visible headroom without shrinking the character.
const HERO_BUST_Y_OFFSET := -30.0
const GEAR_CARD_SIZE := Vector2(176, 176)
const GEAR_ROW_SEPARATION := 34
const SMALL_PORTRAIT_SIZE := Vector2(104, 104)
const CHALLENGE_RECOMMENDED_POWER_MULT := 1.5
const DETAILS_PANEL_HEIGHT := 316.0
const BOTTOM_ACTION_SPACER_HEIGHT := 28.0

var router: Node
var level_id := "level_001"
var is_challenge_mode := false
var _return_to := "map"
var _return_payload := {}

func setup(main: Node, payload := {}) -> void:
	router = main
	var data := {}
	if payload is Dictionary:
		data = payload
	level_id = _resolve_level_id(data)
	is_challenge_mode = bool(data.get("challenge", data.get("mode_challenge", false)))
	_return_to = _sanitize_return_to(str(data.get("return_to", "map")))
	_return_payload = _sanitize_return_payload(data.get("return_payload", {}))
	if _return_to == "result" and not _return_payload.has("level_id"):
		_return_payload["level_id"] = level_id
	if is_challenge_mode:
		_return_payload["challenge"] = true
	_refresh()

func _ready() -> void:
	AudioManager.play_bgm("map")
	if has_node("Root/Main/TopNeonLine"):
		($Root/Main/TopNeonLine as CanvasItem).visible = false
	_apply_runtime_layout()
	_bind_open_hit(%CharacterPanel as Control, "characters")
	_bind_open_hit(%WeaponPanel as Control, "weapons")
	UiKit.apply_armored_texture_button(%StartButton as TextureButton, true, Vector2(760, 112), true)
	UiKit.apply_armored_texture_button(%BackButton as TextureButton, false, Vector2(170, 84), true)
	UiKit.attach_touch_target(%BackButton as TextureButton)
	(%StartButton as TextureButton).set_meta("critical_touch", true)
	(%StartButton as TextureButton).pressed.connect(func() -> void:
		AudioManager.play_sfx("ui_confirm")
		if is_challenge_mode:
			router.start_challenge_level(level_id)
		else:
			router.start_level(level_id)
	)
	$UpgradeButton.pressed.connect(func() -> void:
		var weapon_id := SaveManager.get_selected("weapon")
		if weapon_id == "":
			weapon_id = "weapon_autocannon"
		if SaveManager.upgrade_weapon(weapon_id):
			AudioManager.play_sfx("upgrade")
			_refresh()
			_pulse_weapon_icon()
		else:
			AudioManager.play_sfx("ui_click", -6.0)
	)
	(%BackButton as TextureButton).pressed.connect(_on_back_pressed)
	_refresh_back_button()
	_refresh()
	_build_equip_nav()

func _apply_runtime_layout() -> void:
	var root := $Root as MarginContainer
	root.add_theme_constant_override("margin_top", 38)
	root.add_theme_constant_override("margin_bottom", 36)
	var main := $Root/Main as VBoxContainer
	main.add_theme_constant_override("separation", 13)
	if has_node("Root/Main/UnitsRow"):
		var units := $Root/Main/UnitsRow as HBoxContainer
		units.custom_minimum_size = Vector2(0, 430)
	if has_node("Root/Main/GearIconRow"):
		var gear := %GearIconRow as HBoxContainer
		gear.custom_minimum_size = Vector2(0, 176)
		gear.add_theme_constant_override("separation", GEAR_ROW_SEPARATION)
	if has_node("Root/Main/DetailsPanel"):
		(%DetailsPanel as Control).custom_minimum_size = Vector2(0, DETAILS_PANEL_HEIGHT)
	if has_node("Root/Main/BottomSpacer"):
		var spacer := $Root/Main/BottomSpacer as Control
		spacer.custom_minimum_size = Vector2(0, BOTTOM_ACTION_SPACER_HEIGHT)
		spacer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if has_node("Root/Main/StartButton"):
		var start := %StartButton as TextureButton
		start.custom_minimum_size = Vector2(760, 112)
		UiKit.apply_armored_texture_button(start, true, Vector2(760, 112), true)
		var start_label := start.get_node_or_null("Label") as Label
		if start_label != null:
			start_label.add_theme_font_size_override("font_size", 38)

func _bind_open_hit(panel: Control, mode: String) -> void:
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var hit := panel.get_node_or_null("OpenHitArea") as Button
	if hit == null:
		hit = Button.new()
		hit.name = "OpenHitArea"
		hit.set_anchors_preset(Control.PRESET_FULL_RECT)
		hit.text = ""
		hit.mouse_filter = Control.MOUSE_FILTER_STOP
		for key in ["normal", "hover", "pressed", "disabled", "focus"]:
			hit.add_theme_stylebox_override(key, StyleBoxEmpty.new())
		panel.add_child(hit)
	hit.pressed.connect(_open_collection.bind(mode))

func _on_back_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	if router == null:
		return
	if _return_to == "result":
		router.change_scene("result", _return_payload.duplicate(true))
		return
	router.change_scene("map")

func _refresh_back_button() -> void:
	var button := %BackButton as TextureButton
	UiKit.apply_armored_texture_button(button, false, Vector2(170, 84), true)
	var label := button.get_node_or_null("Label") as Label
	if label == null:
		return
	label.text = "返回结算" if _return_to == "result" else "返回关卡"

func _refresh_start_button() -> void:
	var label := (%StartButton as TextureButton).get_node_or_null("Label") as Label
	if label == null:
		return
	label.text = "开始挑战" if is_challenge_mode else "开始战斗"

func _refresh_resource_bar() -> void:
	var main := $Root/Main as VBoxContainer
	if main == null:
		return
	var existing := main.get_node_or_null("ResourceBar")
	if existing != null:
		existing.free()
	var bar := UiKit.standard_resource_bar(SaveManager.get_player_gold(), SaveManager.get_player_star(), SaveManager.get_player_xp(), SaveManager.get_loadout_power())
	bar.name = "ResourceBar"
	main.add_child(bar)
	var header := main.get_node_or_null("HeaderRow")
	if header != null:
		main.move_child(bar, header.get_index() + 1)
	else:
		main.move_child(bar, 0)

func _refresh() -> void:
	if not is_inside_tree():
		return
	_refresh_resource_bar()
	var weapon_id := SaveManager.get_selected("weapon")
	if weapon_id == "":
		weapon_id = "weapon_autocannon"
	var char_id := SaveManager.get_selected("character")
	if char_id == "":
		char_id = "vanguard"
	# 只显示真正已选/已拥有的装备；未拥有则留空（开局护甲/芯片/宠物都没有）。
	var armor_id := SaveManager.get_selected("armor")
	var chip_id := SaveManager.get_selected("chip")
	var pet_id := SaveManager.get_selected("pet")
	var weapon_level := SaveManager.get_weapon_level(weapon_id)
	var char_level := SaveManager.get_item_level(char_id)
	var armor_level := SaveManager.get_item_level(armor_id) if armor_id != "" else 0
	var chip_level := SaveManager.get_item_level(chip_id) if chip_id != "" else 0
	var pet_level := SaveManager.get_item_level(pet_id) if pet_id != "" else 0
	var upgrade_cost := SaveManager.get_weapon_upgrade_cost(weapon_id)
	var gold := SaveManager.get_player_gold()
	var power := SaveManager.get_loadout_power()
	var projected_power := SaveManager.get_projected_combat_power_for_level(level_id)
	var recommended_power := _recommended_power_for_current_mode()
	var level := DataLoader.get_row("levels", level_id)
	var weakness := str(level.get("primary_weakness", "physical"))
	var character_name := DataLoader.tr_key(DataLoader.get_row("characters", char_id).get("name_key", char_id))
	var weapon_name := DataLoader.tr_key(DataLoader.get_row("weapons", weapon_id).get("name_key", weapon_id))
	var armor_name := _row_name("armors", armor_id) if armor_id != "" else "未装备"
	var chip_name := _row_name("chips", chip_id) if chip_id != "" else "未装备"
	var pet_name := _row_name("pets", pet_id) if pet_id != "" else "未携带"
	var growth_tier := _tier_suffix(maxi(maxi(char_level, weapon_level), maxi(armor_level, chip_level))).strip_edges()
	if growth_tier == "":
		growth_tier = "基础"
	var counter_state := "克制有效" if _loadout_counters(weakness, char_id, weapon_id, chip_id) else "克制一般"
	(%CharacterName as Label).text = "%s  等级%d" % [character_name, char_level]
	(%WeaponName as Label).text = "%s  等级%d" % [weapon_name, weapon_level]
	var mode_label := "挑战模式" if is_challenge_mode else "五波尸潮"
	$Summary.text = "%s  |  %s  |  主弱点 %s\n战前 %d  |  预计成型 %d / 推荐 %d  |  %s  |  金币 %d\n英雄  %s 等级%d  |  武器  %s 等级%d\n护甲 %s 等级%d  |  芯片 %s 等级%d  |  宝宝 %s%s" % [
		DataLoader.level_display_name(level_id),
		mode_label,
		_element_name(weakness),
		power,
		projected_power,
		recommended_power,
		counter_state,
		gold,
		character_name,
		char_level,
		weapon_name,
		weapon_level,
		armor_name,
		armor_level,
		chip_name,
		chip_level,
		pet_name,
		" 等级%d" % pet_level if pet_id != "" else ""
	]
	$Summary.visible = false
	_refresh_summary_panel(level_id, weakness, power, projected_power, recommended_power, counter_state, gold, character_name, char_level, weapon_name, weapon_level, armor_name, armor_level, chip_name, chip_level, pet_name, pet_level, pet_id != "", is_challenge_mode)
	var weapon_icon := %WeaponIcon as TextureRect
	weapon_icon.texture = load(DataLoader.get_row("weapons", weapon_id).get("icon", ""))
	weapon_icon.modulate = Color.WHITE
	weapon_icon.scale = Vector2.ONE
	_refresh_character_bust(DataLoader.get_row("characters", char_id))
	var growth_badge := %GrowthBadge as Label
	growth_badge.text = "护甲  /  芯片  /  宠物"
	growth_badge.add_theme_color_override("font_color", Color(0.74, 0.86, 0.86, 1.0))
	_refresh_gear_badges([
		["角色", char_level],
		["武器", weapon_level],
		["护甲", armor_level],
		["芯片", chip_level],
		["宠物", pet_level]
	])
	$Objective.text = _level_objective(level_id)
	if is_challenge_mode:
		var challenge_rule := ChallengeRules.for_level(level_id, DataLoader.get_table("challenges"))
		$Objective.text = "%s\n压力：%s；推荐战力 +%d%%。\n应对：%s\n%s" % [
			ChallengeRules.headline(challenge_rule),
			ChallengeRules.pressure_text(challenge_rule),
			int(round((float(challenge_rule.get("recommended_power_mult", 1.5)) - 1.0) * 100.0)),
			str(challenge_rule.get("counter_hint", "围绕弱点配装。")),
			$Objective.text,
		]
	if projected_power < recommended_power:
		$Objective.text += "\n提示：预计成型战力仍偏低；该数值已计入永久技能等级和本关选卡预算。"
	elif _loadout_counters(weakness, char_id, weapon_id, chip_id):
		$Objective.text += "\n提示：当前配装命中主弱点，战斗中弱点装填更强。"
	$GoldLabel.text = "金币  %d" % gold
	var can_upgrade := SaveManager.can_upgrade_weapon(weapon_id)
	var dmg_bonus := int(round((SaveManager.get_weapon_damage_multiplier(weapon_id) - 1.0) * 100.0))
	var next_bonus := int(round(((1.0 + 0.08 * float(weapon_level)) - 1.0) * 100.0))
	$UpgradeInfo.text = "点击武器图标升级  |  %s +1  花费 %d\n当前伤害 +%d%%  →  +%d%%%s" % [
		DataLoader.tr_key(DataLoader.get_row("weapons", weapon_id).get("name_key", weapon_id)),
		upgrade_cost,
		dmg_bonus,
		next_bonus,
		"" if can_upgrade else "\n金币不足：通关或重打关卡获取"
	]
	$UpgradeButton.disabled = not SaveManager.can_upgrade_weapon(weapon_id)
	$UpgradeButton.modulate = Color(1, 1, 1, 1) if not $UpgradeButton.disabled else Color(0.55, 0.55, 0.55, 0.85)
	_refresh_start_button()
	_rebuild_character_bar(char_id)
	_rebuild_gear_icon_row(armor_id, chip_id, pet_id)
	_refresh_signature_panel(char_id)

func _character_display_texture(row: Dictionary) -> Texture2D:
	return UiKit.character_bust_texture(row)

func _refresh_character_bust(row: Dictionary) -> void:
	var clip := %CharacterIcon as TextureRect
	clip.texture = null
	clip.clip_contents = true
	clip.custom_minimum_size = HERO_BUST_WINDOW_SIZE
	clip.offset_left = -HERO_BUST_WINDOW_SIZE.x * 0.5
	clip.offset_top = -156.0
	clip.offset_right = HERO_BUST_WINDOW_SIZE.x * 0.5
	clip.offset_bottom = clip.offset_top + HERO_BUST_WINDOW_SIZE.y
	clip.pivot_offset = HERO_BUST_WINDOW_SIZE * 0.5
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.modulate = Color.WHITE
	clip.scale = Vector2.ONE

	var bust := clip.get_node_or_null("BustImage") as TextureRect
	if bust == null:
		bust = TextureRect.new()
		bust.name = "BustImage"
		bust.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bust.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bust.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		clip.add_child(bust)

	var texture := _character_display_texture(row)
	bust.texture = texture
	bust.modulate = Color.WHITE
	bust.scale = Vector2.ONE
	if texture == null:
		bust.size = HERO_BUST_WINDOW_SIZE
		bust.position = Vector2.ZERO
		return
	var texture_size := texture.get_size()
	var aspect := texture_size.y / maxf(texture_size.x, 1.0)
	var bust_size := Vector2(HERO_BUST_IMAGE_WIDTH, HERO_BUST_IMAGE_WIDTH * aspect)
	bust.size = bust_size
	bust.custom_minimum_size = bust_size
	bust.position = Vector2((HERO_BUST_WINDOW_SIZE.x - bust_size.x) * 0.5, HERO_BUST_Y_OFFSET)

func _row_name(table: String, item_id: String) -> String:
	if item_id == "":
		return ""
	var row := DataLoader.get_row(table, item_id)
	if row.is_empty():
		return item_id
	return DataLoader.tr_key(row.get("name_key", item_id))

func _refresh_summary_panel(display_level_id: String, weakness: String, power: int, projected_power: int, recommended_power: int, counter_state: String, gold: int, character_name: String, char_level: int, weapon_name: String, weapon_level: int, armor_name: String, armor_level: int, chip_name: String, chip_level: int, pet_name: String, pet_level: int, has_pet: bool, challenge_mode: bool) -> void:
	var panel: Control = %DetailsPanel
	var old := panel.get_node_or_null("SummaryGrid")
	if old != null:
		old.queue_free()
	if panel is TextureRect:
		(panel as TextureRect).texture = null
		panel.modulate = Color.WHITE
	var frame := PanelContainer.new()
	frame.name = "SummaryGrid"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", UiKit.panel_texture_style(14.0))
	panel.add_child(frame)

	var box := VBoxContainer.new()
	box.name = "SummaryContent"
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(box)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	box.add_child(title_row)
	var title := UiKit.label("挑战摘要" if challenge_mode else "战术摘要", 23, UiKit.TEXT_MAIN, 4)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var state := UiKit.pill(counter_state, UiKit.GREEN if counter_state == "克制有效" else UiKit.GOLD, 18)
	state.custom_minimum_size = Vector2(142, 38)
	title_row.add_child(state)

	var divider := TextureRect.new()
	divider.custom_minimum_size = Vector2(0, 8)
	divider.texture = load("res://assets/production/sprites/ui/ui_map_pill_skin.png")
	divider.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	divider.stretch_mode = TextureRect.STRETCH_SCALE
	divider.modulate = Color(1.0, 0.72, 0.36, 0.45)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(divider)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	grid.add_child(_summary_cell("关卡", "%s / %s" % [DataLoader.level_display_name(display_level_id), "挑战" if challenge_mode else "五波"], UiKit.CYAN, ""))
	grid.add_child(_summary_cell("弱点", _element_name(weakness), UiKit.element_color(weakness), UiKit.element_icon_path(weakness)))
	grid.add_child(_summary_cell("战前", "%d" % power, UiKit.CYAN, ""))
	grid.add_child(_summary_cell("推荐", "%d" % recommended_power, UiKit.GOLD, ""))
	grid.add_child(_summary_cell("成型", "%d" % projected_power, UiKit.GREEN if projected_power >= recommended_power else UiKit.GOLD, ""))
	grid.add_child(_summary_cell("金币", "%d" % gold, UiKit.GOLD, UiKit.currency_icon_path("gold")))

	var loadout := Label.new()
	loadout.text = "英雄 %s 等级%d  |  武器 %s 等级%d\n护甲 %s 等级%d  |  芯片 %s 等级%d  |  宠物 %s%s" % [
		character_name,
		char_level,
		weapon_name,
		weapon_level,
		armor_name,
		armor_level,
		chip_name,
		chip_level,
		pet_name,
		" 等级%d" % pet_level if has_pet else ""
	]
	loadout.custom_minimum_size = Vector2(0, 68)
	loadout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loadout.clip_text = false
	UiKit.apply_label(loadout, 21, UiKit.TEXT_MAIN, 4)
	box.add_child(loadout)

func _summary_cell(label_text: String, value_text: String, accent: Color, icon_path: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(360, 36)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	if icon_path != "":
		row.add_child(UiKit.icon(icon_path, Vector2(28, 28)))
	var title := UiKit.label(label_text, 18, Color(accent.r, accent.g, accent.b, 1.0), 4)
	title.custom_minimum_size = Vector2(52, 0)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title)
	var value := UiKit.label(value_text, 21, UiKit.TEXT_MAIN, 4)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.clip_text = true
	row.add_child(value)
	return row

func _summary_tile(label_text: String, value_text: String, accent: Color, icon_path: String) -> PanelContainer:
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(0, 54)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.add_theme_stylebox_override("panel", UiKit.panel_texture_style(10.0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	tile.add_child(row)
	if icon_path != "":
		row.add_child(UiKit.icon(icon_path, Vector2(30, 30)))
	var title := UiKit.label(label_text, 16, Color(accent.r, accent.g, accent.b, 0.92), 2)
	title.custom_minimum_size = Vector2(48, 0)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title)
	var value := UiKit.label(value_text, 18, UiKit.TEXT_MAIN, 2)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.clip_text = true
	row.add_child(value)
	return tile

func _level_tint(level: int) -> Color:
	if level >= 25:
		return Color(1.0, 0.82, 0.34, 1.0)
	if level >= 15:
		return Color(0.72, 0.9, 1.0, 1.0)
	if level >= 8:
		return Color(0.78, 1.0, 0.72, 1.0)
	return Color.WHITE

func _visual_level_scale(level: int) -> Vector2:
	var bonus := clampf(float(level - 1) * 0.006, 0.0, 0.16)
	return Vector2(1.0 + bonus, 1.0 + bonus)

func _growth_badge_text(level: int) -> String:
	if level >= 25:
		return "成长 III · 金色改装"
	if level >= 15:
		return "成长 II · 精英校准"
	if level >= 8:
		return "成长 I · 战术改装"
	return "基础整备"

func _refresh_gear_badges(items: Array) -> void:
	for child in $GearBadges.get_children():
		child.queue_free()
	for item in items:
		var level := int(item[1])
		if level <= 0:
			continue
		var label := Label.new()
		label.custom_minimum_size = Vector2(166, 48)
		label.text = "%s 等级%d%s" % [str(item[0]), level, _tier_suffix(level)]
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", _level_tint(level))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		label.add_theme_constant_override("outline_size", 3)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		$GearBadges.add_child(label)

func _tier_suffix(level: int) -> String:
	if level >= 25:
		return " III"
	if level >= 15:
		return " II"
	if level >= 8:
		return " I"
	return ""

func _pulse_weapon_icon() -> void:
	var weapon_icon := %WeaponIcon as TextureRect
	var base_scale: Vector2 = weapon_icon.scale
	var tween := weapon_icon.create_tween()
	tween.tween_property(weapon_icon, "scale", base_scale * 1.08, 0.08)
	tween.tween_property(weapon_icon, "scale", base_scale, 0.12)

func _try_upgrade_weapon() -> void:
	var selected_weapon := SaveManager.get_selected("weapon")
	if selected_weapon == "":
		selected_weapon = "weapon_autocannon"
	if SaveManager.upgrade_weapon(selected_weapon):
		AudioManager.play_sfx("upgrade")
		_refresh()
		_pulse_weapon_icon()
	else:
		AudioManager.play_sfx("ui_click", -6.0)

func _rebuild_character_bar(selected_character: String) -> void:
	for child in $CharacterSelectBar.get_children():
		child.queue_free()
	var characters: Dictionary = DataLoader.get_table("characters")
	for char_id in characters.keys():
		var row: Dictionary = DataLoader.get_row("characters", char_id)
		var unlocked := SaveManager.is_item_unlocked("character", char_id)
		var button := _icon_card(
			char_id,
			str(row.get("portrait", "")),
			SMALL_PORTRAIT_SIZE,
			10.0,
			char_id == selected_character,
			unlocked,
			Color(0.46, 0.92, 1.0, 0.92),
			DataLoader.tr_key(row.get("name_key", char_id))
		)
		button.modulate = _selection_tint(unlocked, false)
		if unlocked:
			(button.get_node("HitArea") as Button).pressed.connect(_select_character.bind(char_id))
		$CharacterSelectBar.add_child(button)

func _rebuild_gear_icon_row(armor_id: String, chip_id: String, pet_id: String) -> void:
	var gear_row := %GearIconRow as HBoxContainer
	for child in gear_row.get_children():
		child.queue_free()
	gear_row.add_child(_gear_icon_button("armors", "armor", armor_id, "armor_kevlar"))
	gear_row.add_child(_gear_icon_button("chips", "chip", chip_id, "chip_attack"))
	gear_row.add_child(_gear_icon_button("pets", "pet", pet_id, _first_pet_id()))

func _refresh_signature_panel(char_id: String) -> void:
	if not has_node("SignatureCards"):
		return
	for child in $SignatureCards.get_children():
		child.queue_free()
	var row := DataLoader.get_row("characters", char_id)
	var character_name := DataLoader.tr_key(row.get("name_key", char_id))
	$SignatureTitle.text = "角色专属 · %s" % character_name
	$SignatureHint.text = "主动可释放；弹种加成已进战斗"
	var passive_id := str(row.get("passive", ""))
	var passive_info: Dictionary = CharacterSkillText.passive_info(passive_id)
	$SignatureCards.add_child(_signature_card("被动已生效", str(passive_info.get("name", passive_id)), str(passive_info.get("desc", "")), Color(0.45, 1.0, 0.72, 0.96)))
	var sig_ids: Array = row.get("signature_skills", [])
	var active_skill_row: Dictionary = row.get("active_skill", {})
	var active_id := str(active_skill_row.get("id", ""))
	for sig_id in sig_ids.slice(0, 2):
		var info: Dictionary = CharacterSkillText.signature_info(str(sig_id))
		var kind := "主动技能" if str(sig_id) == active_id else "专属被动"
		$SignatureCards.add_child(_signature_card(kind, str(info.get("name", sig_id)), str(info.get("desc", "")), Color(1.0, 0.78, 0.34, 0.94)))

func _signature_card(kind: String, title: String, desc: String, accent: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(250, 118)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _signature_card_style(Color(0.022, 0.028, 0.036, 0.9), accent))
	card.tooltip_text = "%s：%s\n%s" % [kind, title, desc]
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 1)
	card.add_child(stack)
	var kind_label := Label.new()
	kind_label.text = kind
	kind_label.add_theme_font_size_override("font_size", 16)
	kind_label.add_theme_color_override("font_color", accent)
	kind_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	kind_label.add_theme_constant_override("outline_size", 2)
	stack.add_child(kind_label)
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(0.94, 1.0, 1.0, 1.0))
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title_label.add_theme_constant_override("outline_size", 3)
	title_label.clip_text = true
	stack.add_child(title_label)
	var desc_label := Label.new()
	desc_label.text = desc.replace("已生效：", "").replace("主动：", "").replace("自动：", "").replace("弹种：", "")
	desc_label.custom_minimum_size = Vector2(0, 48)
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.76, 0.9, 0.96, 0.96))
	desc_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	desc_label.add_theme_constant_override("outline_size", 2)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.clip_text = true
	stack.add_child(desc_label)
	return card

func _signature_card_style(_bg: Color, _border: Color) -> StyleBox:
	return UiKit.panel_texture_style(10.0)

func _gear_icon_button(table: String, slot: String, selected_id: String, _fallback_id: String) -> Control:
	var has_item := selected_id != ""
	var row := DataLoader.get_row(table, selected_id) if has_item else {}
	var accent := Color(1.0, 0.72, 0.28, 0.9) if slot == "armor" else Color(0.42, 0.92, 1.0, 0.82)
	var item_name := DataLoader.tr_key(row.get("name_key", selected_id)) if has_item else "未装备 · 点击获取"
	var card := _icon_card(
		"%sIcon" % slot.capitalize(),
		str(row.get("icon", "")) if has_item else "",
		GEAR_CARD_SIZE,
		16.0,
		has_item,
		true,
		accent,
		"%s：%s" % [_slot_label(slot), item_name]
	)
	card.modulate = Color(1, 1, 1, 1) if has_item else Color(0.74, 0.80, 0.86, 0.90)
	var slot_label := Label.new()
	slot_label.name = "SlotLabel"
	slot_label.text = _slot_label(slot) if has_item else "%s · 选择" % _slot_label(slot)
	slot_label.position = Vector2(10, GEAR_CARD_SIZE.y - 42.0)
	slot_label.size = Vector2(GEAR_CARD_SIZE.x - 20.0, 28.0)
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiKit.apply_label(slot_label, 15, UiKit.TEXT_MAIN if has_item else UiKit.TEXT_MUTED, 2)
	slot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(slot_label)
	(card.get_node("HitArea") as Button).pressed.connect(_open_collection.bind(table))
	return card

func _icon_card(card_name: String, texture_path: String, card_size: Vector2, margin: float, selected: bool, enabled: bool, accent: Color, tooltip: String) -> Control:
	var card := Control.new()
	card.name = card_name
	card.custom_minimum_size = card_size
	card.size = card_size
	card.clip_contents = true
	card.tooltip_text = tooltip

	var frame := PanelContainer.new()
	frame.name = "Frame"
	frame.position = Vector2.ZERO
	frame.size = card_size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", UiKit.icon_frame_texture_style(selected, texture_path == ""))
	card.add_child(frame)

	var icon := TextureRect.new()
	icon.name = "CenteredIcon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = card_size - Vector2(margin * 2.0, margin * 2.0)
	icon.size = icon.custom_minimum_size
	if texture_path != "" and ResourceLoader.exists(texture_path):
		icon.texture = load(texture_path)
	icon.position = Vector2(margin, margin)
	icon.size = icon.custom_minimum_size
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon)
	if texture_path == "":
		var plus := Label.new()
		plus.name = "EmptyPlus"
		plus.text = "+"
		plus.position = Vector2(20, 20)
		plus.size = Vector2(card_size.x - 40.0, 74)
		plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UiKit.apply_label(plus, 38, UiKit.CYAN, 3)
		plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(plus)
		var choose := Label.new()
		choose.name = "EmptyChooseLabel"
		choose.text = "点击选择"
		choose.position = Vector2(16, 88)
		choose.size = Vector2(card_size.x - 32.0, 34)
		choose.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		choose.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UiKit.apply_label(choose, 17, UiKit.TEXT_MAIN, 2)
		choose.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(choose)

	var hit_area := Button.new()
	hit_area.name = "HitArea"
	hit_area.position = Vector2.ZERO
	hit_area.size = card_size
	hit_area.text = ""
	hit_area.icon = null
	hit_area.disabled = not enabled
	hit_area.tooltip_text = tooltip
	_apply_transparent_button_style(hit_area)
	card.add_child(hit_area)
	return card

func _slot_label(slot: String) -> String:
	match slot:
		"armor":
			return "护甲"
		"chip":
			return "芯片"
		"pet":
			return "宠物"
		_:
			return slot

func _apply_icon_button_style(button: Button, selected: bool, enabled: bool, accent: Color) -> void:
	button.add_theme_stylebox_override("normal", UiKit.icon_frame_texture_style(selected, not enabled))
	button.add_theme_stylebox_override("hover", UiKit.icon_frame_texture_style(true, false))
	button.add_theme_stylebox_override("pressed", UiKit.icon_frame_texture_style(true, false))
	button.add_theme_stylebox_override("disabled", UiKit.icon_frame_texture_style(false, true))

func _icon_button_style(_bg: Color, _border: Color, _width: int) -> StyleBox:
	return UiKit.icon_frame_texture_style(false)

func _apply_transparent_button_style(button: Button) -> void:
	for key in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(key, StyleBoxEmpty.new())

func _selection_tint(unlocked: bool, selected: bool) -> Color:
	if not unlocked:
		return Color(0.32, 0.36, 0.4, 0.62)
	if selected:
		return Color(1.0, 1.0, 1.0, 1.0)
	return Color(1.0, 1.0, 1.0, 0.9)

func _select_character(char_id: String) -> void:
	if SaveManager.select_item("character", char_id):
		AudioManager.play_sfx("ui_confirm")
		_refresh()
	else:
		AudioManager.play_sfx("ui_click", -6.0)

func _first_pet_id() -> String:
	var pets: Dictionary = DataLoader.get_table("pets")
	for pet_id in pets.keys():
		return pet_id
	return ""

func _build_equip_nav() -> void:
	for child in $EquipNav.get_children():
		child.queue_free()
	for item in [
		["角色", "characters"],
		["武器", "weapons"],
		["护甲", "armors"],
		["芯片", "chips"],
		["宠物", "pets"],
	]:
		var button := Button.new()
		button.text = str(item[0])
		button.custom_minimum_size = Vector2(166, 58)
		UiKit.apply_armored_button(button, false, Vector2(166, 58), 18, true)
		button.pressed.connect(_open_collection.bind(str(item[1])))
		$EquipNav.add_child(button)

func _nav_button_style(_bg: Color, _border: Color) -> StyleBox:
	return UiKit.map_pill_texture_style()

func _resolve_level_id(payload: Dictionary) -> String:
	var provided := str(payload.get("level_id", ""))
	if provided != "":
		return provided
	if router != null:
		var context: Variant = router.get("run_context")
		if context is Dictionary:
			var active := str(context.get("level_id", ""))
			if active != "":
				return active
	return "level_001"

func _sanitize_return_to(route: String) -> String:
	match route:
		"result":
			return "result"
		_:
			return "map"

func _sanitize_return_payload(payload: Variant) -> Dictionary:
	if payload is Dictionary:
		return payload.duplicate(true)
	return {}

func _recommended_power_for_current_mode() -> int:
	var base := SaveManager.get_recommended_power_for_level(level_id)
	if is_challenge_mode:
		var challenge_rule := ChallengeRules.for_level(level_id, DataLoader.get_table("challenges"))
		return int(ceil(float(base) * float(challenge_rule.get("recommended_power_mult", CHALLENGE_RECOMMENDED_POWER_MULT))))
	return base

func _loadout_counters(weakness: String, char_id: String, weapon_id: String, chip_id: String) -> bool:
	var weapon := DataLoader.get_row("weapons", weapon_id)
	# Character affinity and an elemental chip amplify matching attacks, but they
	# do not convert a mismatched main weapon. The loadout summary must describe
	# sustained primary fire, especially for the element-locked final boss.
	return str(weapon.get("element", "")) == weakness

func _element_name(element: String) -> String:
	match element:
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
			return element

func _open_collection(mode: String) -> void:
	AudioManager.play_sfx("ui_click")
	router.change_scene("collection", {
		"mode": mode,
		"return_to": "loadout",
		"level_id": level_id,
		"challenge": is_challenge_mode,
		"loadout_return_to": _return_to,
		"loadout_return_payload": _return_payload,
	})

func _level_objective(id: String) -> String:
	match id:
		"level_001":
			return "目标：熟悉瞄准和自动开火，守住五波尸潮。"
		"level_002":
			return "目标：五波弹雨试炼，第一次选择技能卡，优先体验分裂弹清群。"
		"level_003":
			return "目标：处理疾跑僵尸，优先压制靠近防线的威胁。"
		"level_004":
			return "目标：用锁定、穿透或减速处理巨臂和爆弹。"
		"level_005":
			return "目标：击破装甲巨像护甲，守住首领压力。"
		"level_006":
			return "目标：处理左右双线突袭，优先打近线威胁。"
		"level_007":
			return "目标：尖啸僵尸会制造压力，先锁定支援单位。"
		"level_008":
			return "目标：疾跑和爆弹混合推进，用减速或多重压住节奏。"
		"level_009":
			return "目标：重甲尸墙推进，穿透和锁定是关键。"
		"level_010":
			return "目标：最终防线，先清支援再破首领护甲。"
		_:
			var level := DataLoader.get_row("levels", id)
			for wave in level.get("waves", []):
				if wave.has("boss"):
					return "目标：首领波次会持续压迫基地，先清支援再集中破首领。"
			var tags: Array = level.get("threat_tags", [])
			if tags.has("fast"):
				return "目标：高速单位较多，优先选择减速、追踪或多重射击。"
			if tags.has("tank"):
				return "目标：厚血单位较多，优先选择穿透、蓄能或元素克制。"
			if tags.has("support"):
				return "目标：支援单位会放大尸潮压力，锁定策略优先处理精英。"
			if tags.has("burst"):
				return "目标：爆发威胁较高，保留护盾和控制来稳住防线。"
			return "目标：守住防线，根据尸潮类型完成本局构筑。"
