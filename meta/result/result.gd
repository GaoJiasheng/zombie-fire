extends Control

const UiKit := preload("res://ui/ui_kit.gd")
const CONTENT_MAX_WIDTH := 920.0
const CONTENT_SIDE_MARGIN := 88.0
const HERO_TITLE_NORMAL_SIZE := 70
const HERO_TITLE_LONG_SIZE := 58
const HERO_TITLE_SHORT_SIZE := 78

var router: Node
var level_id := "level_001"
var next_level := ""
var result_stars := 0
var _result_return_payload := {}
var is_endless_result := false
var is_challenge_result := false
var endless_loops := 0
var _content_width := CONTENT_MAX_WIDTH

func setup(main: Node, payload := {}) -> void:
	router = main
	level_id = _resolve_level_id(payload)
	is_endless_result = bool(payload.get("endless", false))
	is_challenge_result = bool(payload.get("challenge", false))
	endless_loops = int(payload.get("endless_loop", 0))
	var victory := bool(payload.get("victory", false))
	next_level = _resolve_next_level(payload, victory)
	result_stars = int(payload.get("stars", 0))
	if is_endless_result:
		result_stars = 0
	_result_return_payload = _build_result_return_payload(payload, victory)
	AudioManager.play_bgm("victory" if victory else "defeat")
	AudioManager.play_sfx("victory" if victory else "defeat")
	_populate_hero(victory)
	_populate_rewards(payload, victory)
	_populate_hint(victory)
	_populate_actions(victory)
	if victory:
		SaveManager.repair_progression_unlocks()
	call_deferred("_animate_result_entry", victory)

func _ready() -> void:
	_apply_layout_constraints()
	_apply_ui_style()
	$Content/Actions/PrimaryRow/UpgradeButton.pressed.connect(_on_upgrade_pressed)
	$Content/Actions/PrimaryRow/RetryButton.pressed.connect(_on_retry_pressed)
	$Content/Actions/NextButton.pressed.connect(_on_next_pressed)
	$Content/Actions/MapButton.pressed.connect(_on_map_pressed)

func _apply_layout_constraints() -> void:
	var viewport_size := get_viewport_rect().size
	var raw_width := minf(CONTENT_MAX_WIDTH, maxf(840.0, viewport_size.x - CONTENT_SIDE_MARGIN * 2.0))
	var content_width := _native_result_content_width(raw_width)
	_content_width = content_width
	var content := $Content as Control
	var modal_shift := UiKit.tall_modal_shift(viewport_size.y, 160.0, 0.34)
	content.offset_left = -content_width * 0.5
	content.offset_right = content_width * 0.5
	content.offset_top = -820.0 + modal_shift
	content.offset_bottom = 660.0 + modal_shift
	content.add_theme_constant_override("separation", 12)
	for path in ["Content/HeroCard", "Content/RewardRow", "Content/HintCard", "Content/Actions"]:
		var node := get_node_or_null(path) as Control
		if node != null:
			node.custom_minimum_size.x = content_width
	$Content/HeroCard/HeroBox.add_theme_constant_override("separation", 6)
	$Content/HeroCard/HeroBox/Title.custom_minimum_size = Vector2(content_width - 96.0, 0)
	$Content/HeroCard/HeroBox/Title.clip_text = true
	$Content/HeroCard/HeroBox/LevelName.custom_minimum_size = Vector2(content_width - 120.0, 0)
	$Content/RewardRow.add_theme_constant_override("separation", 16)
	_configure_reward_layout()
	for path in ["Content/RewardRow/GoldCard/GoldBox/GoldIcon", "Content/RewardRow/XpCard/XpBox/XpIcon"]:
		var icon := get_node_or_null(path) as Control
		if icon != null:
			icon.custom_minimum_size = Vector2(58, 58)
	$Content/HintCard.custom_minimum_size = Vector2(content_width, 58)
	$Content/HintCard/HintBox.add_theme_constant_override("separation", 12)
	$Content/HintCard/HintBox/HintIcon.custom_minimum_size = Vector2(42, 42)

func _native_result_content_width(raw_width: float) -> float:
	if raw_width >= 912.0:
		return 920.0
	if raw_width >= 892.0:
		return 904.0
	if raw_width >= 860.0:
		return 880.0
	return 840.0

func _apply_ui_style() -> void:
	$Content/HeroCard.add_theme_stylebox_override("panel", UiKit.result_panel_texture_style())
	$Content/RewardRow/GoldCard.add_theme_stylebox_override("panel", UiKit.reward_texture_style("gold"))
	$Content/RewardRow/XpCard.add_theme_stylebox_override("panel", UiKit.reward_texture_style("xp"))
	_reset_action_button_tints()
	UiKit.apply_label($Content/HeroCard/HeroBox/Eyebrow, 18, UiKit.GOLD, 2)
	_apply_title_label_style(HERO_TITLE_NORMAL_SIZE, UiKit.TEXT_MAIN)
	UiKit.apply_label($Content/HeroCard/HeroBox/LevelName, 26, Color(0.78, 0.84, 0.84, 1.0), 3)
	UiKit.apply_label($Content/RewardRow/GoldCard/GoldBox/GoldVBox/GoldLabel, 18, UiKit.GOLD, 2)
	UiKit.apply_label($Content/RewardRow/GoldCard/GoldBox/GoldVBox/GoldValue, 40, UiKit.GOLD, 4)
	UiKit.apply_label($Content/RewardRow/XpCard/XpBox/XpVBox/XpLabel, 18, UiKit.CYAN, 2)
	UiKit.apply_label($Content/RewardRow/XpCard/XpBox/XpVBox/XpValue, 40, UiKit.CYAN, 4)
	UiKit.apply_label($Content/HintCard/HintBox/Hint, 22, UiKit.TEXT_MAIN, 2)
	for path in [
		"Content/Actions/PrimaryRow/UpgradeButton/UpgradeLabel",
		"Content/Actions/PrimaryRow/RetryButton/RetryLabel",
		"Content/Actions/NextButton/NextLabel",
		"Content/Actions/MapButton/MapLabel"
	]:
			var label := get_node_or_null(path) as Label
			if label != null:
				UiKit.apply_label(label, int(label.get_theme_font_size("font_size")), Color(1, 1, 1, 1), 5)

func _apply_title_label_style(size: int, color: Color) -> void:
	var title := $Content/HeroCard/HeroBox/Title as Label
	UiKit.apply_label(title, size, color, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _populate_hero(victory: bool) -> void:
	var level_name := DataLoader.level_display_name(level_id)
	if is_endless_result:
		$Content/HeroCard/HeroBox/Title.text = "无限尸潮"
		$Content/HeroCard/HeroBox/LevelName.text = "坚持 %d 轮 · %s" % [endless_loops, level_name]
		_apply_title_label_style(HERO_TITLE_SHORT_SIZE, Color(1, 0.78, 0.4, 1))
	elif is_challenge_result:
		$Content/HeroCard/HeroBox/Title.text = "挑战完成" if victory else "挑战失败"
		$Content/HeroCard/HeroBox/LevelName.text = level_name
		_apply_title_label_style(HERO_TITLE_LONG_SIZE, Color(1, 0.78, 0.4, 1) if victory else Color(1, 0.55, 0.45, 1))
	else:
		$Content/HeroCard/HeroBox/Title.text = DataLoader.tr_key("ui_victory") if victory else DataLoader.tr_key("ui_defeat")
		if victory:
			_apply_title_label_style(HERO_TITLE_SHORT_SIZE, Color(1, 0.95, 0.55, 1))
		else:
			_apply_title_label_style(HERO_TITLE_SHORT_SIZE, Color(1, 0.55, 0.45, 1))
		$Content/HeroCard/HeroBox/LevelName.text = level_name
	_refresh_star_row(result_stars)

func _populate_rewards(payload: Dictionary, victory: bool) -> void:
	var gold := int(payload.get("gold", 0))
	var xp := int(payload.get("xp", 0))
	_configure_reward_layout()
	if is_endless_result:
		$Content/RewardRow/GoldCard/GoldBox/GoldVBox/GoldValue.text = "+%s" % _format_result_number(gold)
		$Content/RewardRow/XpCard/XpBox/XpVBox/XpValue.text = "+0"
		return
	if victory or is_endless_result:
		$Content/RewardRow/GoldCard/GoldBox/GoldVBox/GoldValue.text = "+%s" % _format_result_number(gold)
		$Content/RewardRow/XpCard/XpBox/XpVBox/XpValue.text = "+%s" % _format_result_number(xp)
	else:
		# defeat: show what they got but no rewards credited
		$Content/RewardRow/GoldCard/GoldBox/GoldVBox/GoldValue.text = "+0"
		$Content/RewardRow/XpCard/XpBox/XpVBox/XpValue.text = "+0"
		$Content/RewardRow/GoldCard.modulate = Color(1, 1, 1, 0.45)
		$Content/RewardRow/XpCard.modulate = Color(1, 1, 1, 0.45)

func _configure_reward_layout() -> void:
	var gold_card := get_node_or_null("Content/RewardRow/GoldCard") as Control
	var xp_card := get_node_or_null("Content/RewardRow/XpCard") as Control
	if gold_card == null or xp_card == null:
		return
	if is_endless_result:
		gold_card.custom_minimum_size = Vector2(_content_width, 104)
		gold_card.size_flags_stretch_ratio = 1.0
		xp_card.hide()
	else:
		var reward_width := (_content_width - 16.0) * 0.5
		gold_card.custom_minimum_size = Vector2(reward_width, 104)
		xp_card.custom_minimum_size = Vector2(reward_width, 104)
		gold_card.size_flags_stretch_ratio = 1.0
		xp_card.size_flags_stretch_ratio = 1.0
		xp_card.show()

func _populate_hint(victory: bool) -> void:
	var hint_text := _result_hint(victory)
	$Content/HintCard/HintBox/Hint.text = hint_text
	# swap hint card style by outcome
	var card := $Content/HintCard
	if victory:
		_set_hint_style(card, "victory")
		$Content/HintCard/HintBox/HintIcon.texture = load("res://assets/production/sprites/ui/icon_currency_star.png")
	else:
		_set_hint_style(card, "warning")
		$Content/HintCard/HintBox/HintIcon.texture = load("res://assets/production/sprites/ui/icon_warning.png")

func _set_hint_style(card: PanelContainer, kind: String) -> void:
	card.add_theme_stylebox_override("panel", UiKit.hint_texture_style(kind == "warning"))

func _populate_actions(victory: bool) -> void:
	$Content/Actions/PrimaryRow/UpgradeButton/UpgradeLabel.text = _upgrade_action_label(victory)
	if victory and next_level != "" and not is_challenge_result:
		$Content/Actions/NextButton/NextLabel.text = "下一关"
		$Content/Actions/NextButton.show()
		$Content/Actions/NextButton.modulate = Color.WHITE
	else:
		$Content/Actions/NextButton.hide()
	# On defeat, dim the upgrade button less aggressively
	if not victory:
		$Content/Actions/PrimaryRow/UpgradeButton/UpgradeLabel.text = _upgrade_action_label(false)
	# Retry button text
	$Content/Actions/PrimaryRow/RetryButton/RetryLabel.text = "重打挑战" if is_challenge_result else "重打本关"
	$Content/Actions/MapButton/MapLabel.text = "返回关卡"

func _reset_action_button_tints() -> void:
	var half_button_width := (_content_width - 16.0) * 0.5
	var specs := [
		{"path": "Content/Actions/PrimaryRow/UpgradeButton", "primary": true, "size": Vector2(half_button_width, 88)},
		{"path": "Content/Actions/PrimaryRow/RetryButton", "primary": false, "size": Vector2(half_button_width, 88)},
		{"path": "Content/Actions/NextButton", "primary": true, "size": Vector2(_content_width, 88)},
		{"path": "Content/Actions/MapButton", "primary": false, "size": Vector2(_content_width, 88)},
	]
	for spec in specs:
		var button := get_node_or_null(str(spec["path"])) as TextureButton
		if button != null:
			var button_size: Vector2 = spec["size"]
			UiKit.apply_armored_texture_button(button, bool(spec["primary"]), button_size, true)

func _refresh_star_row(stars: int) -> void:
	var row := $Content/HeroCard/HeroBox/StarRow
	for child in row.get_children():
		child.queue_free()
	row.visible = not is_endless_result
	if is_endless_result:
		return
	for i in range(3):
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(66, 66)
		icon.texture = load("res://assets/production/sprites/ui/ui_star_filled.png" if i < stars else "res://assets/production/sprites/ui/ui_star_empty.png")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)

func _animate_result_entry(victory: bool) -> void:
	$Content.modulate.a = 0.0
	var tween := $Content.create_tween()
	tween.tween_property($Content, "modulate:a", 1.0, 0.32)
	# Stars pop in
	for i in range($Content/HeroCard/HeroBox/StarRow.get_child_count()):
		var star := $Content/HeroCard/HeroBox/StarRow.get_child(i)
		star.scale = Vector2(0.2, 0.2)
		var star_tween := star.create_tween()
		star_tween.tween_interval(0.15 + 0.08 * i)
		star_tween.tween_property(star, "scale", Vector2(1.18, 1.18), 0.14)
		star_tween.tween_property(star, "scale", Vector2.ONE, 0.14)

func _format_result_number(value: int) -> String:
	var sign := "-" if value < 0 else ""
	var abs_value: int = -value if value < 0 else value
	if abs_value >= 1000000:
		return "%s%.1fm" % [sign, float(abs_value) / 1000000.0]
	if abs_value >= 1000:
		return "%s%.1fk" % [sign, float(abs_value) / 1000.0]
	return "%s%d" % [sign, abs_value]

func _on_upgrade_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	router.change_scene("loadout", {
		"level_id": level_id,
		"challenge": is_challenge_result,
		"return_to": "result",
		"return_payload": _result_return_payload,
	})

func _on_next_pressed() -> void:
	level_id = _resolve_level_id({"level_id": level_id})
	next_level = _resolve_next_level({}, true)
	if next_level == "":
		return
	SaveManager.repair_progression_unlocks()
	AudioManager.play_sfx("ui_confirm")
	router.change_scene("loadout", {
		"level_id": next_level,
		"return_to": "result",
		"return_payload": _result_return_payload,
	})

func _on_map_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	router.change_scene("map")

func _on_retry_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	if is_endless_result:
		router.start_endless_level(level_id)
	elif is_challenge_result:
		router.start_challenge_level(level_id)
	else:
		router.start_level(level_id)

func _resolve_next_level(payload: Dictionary, victory: bool) -> String:
	if not victory:
		return ""
	if is_challenge_result:
		return ""
	var campaign_next := _campaign_next_level(level_id)
	if campaign_next != "":
		return campaign_next
	var provided := str(payload.get("next_level", ""))
	if provided != "":
		return provided
	return str(DataLoader.get_row("levels", level_id).get("next_level", ""))

func _campaign_next_level(current_level_id: String) -> String:
	var levels: Array = DataLoader.get_table("levels")
	for i in range(levels.size() - 1):
		var row: Dictionary = levels[i]
		if str(row.get("id", "")) == current_level_id:
			var next_row: Dictionary = levels[i + 1]
			return str(next_row.get("id", ""))
	return ""

func _resolve_level_id(payload: Dictionary) -> String:
	var provided := str(payload.get("level_id", ""))
	if provided != "":
		return provided
	var active := _router_level_id()
	if active != "":
		return active
	return "level_001"

func _build_result_return_payload(payload: Dictionary, victory: bool) -> Dictionary:
	var result_payload := payload.duplicate(true)
	result_payload["level_id"] = level_id
	result_payload["victory"] = victory
	result_payload["stars"] = result_stars
	if is_endless_result:
		result_payload["stars"] = 0
		result_payload["xp"] = 0
	if not result_payload.has("gold"):
		result_payload["gold"] = 0
	if not result_payload.has("xp"):
		result_payload["xp"] = 0
	if next_level != "":
		result_payload["next_level"] = next_level
	if is_challenge_result:
		result_payload["challenge"] = true
		result_payload.erase("next_level")
	return result_payload

func _router_level_id() -> String:
	if router == null:
		return null if false else ""  # i hate this syntax in GDScript but keep
	if router == null:
		return ""
	var context: Variant = router.get("run_context")
	if context is Dictionary:
		return str(context.get("level_id", ""))
	return ""

func _result_hint(victory: bool) -> String:
	if is_endless_result:
		return "无尽模式只结算金币；经验和星星不发放。最高坚持轮数会记录。"
	if victory:
		if is_challenge_result:
			return "挑战星按最高星级补差额发放；重复通关不会重复给星。当前战力 %d。" % SaveManager.get_loadout_power()
		return "当前战力 %d。继续推关前可强化武器、角色或核心芯片。" % SaveManager.get_loadout_power()
	if is_challenge_result:
		var challenge_power := int(ceil(float(SaveManager.get_recommended_power_for_level(level_id)) * 1.5))
		return "挑战尸潮更硬、漏怪更痛。战力 %d / 建议 %d，先补强克制配装再回来。" % [SaveManager.get_loadout_power(), challenge_power]
	var recommended_power := SaveManager.get_recommended_power_for_level(level_id)
	if SaveManager.get_loadout_power() < recommended_power:
		return "战力 %d / 推荐 %d。优先强化武器、角色或核心芯片。" % [SaveManager.get_loadout_power(), recommended_power]
	var level := DataLoader.get_row("levels", level_id)
	var weakness := str(level.get("primary_weakness", "physical"))
	match level_id:
		"level_003", "level_008":
			return "疾跑尸潮突破。推荐 %s 克制，优先减速、追踪或多重。" % _element_name(weakness)
		"level_004", "level_007", "level_009":
			return "重甲和支援压力高。推荐 %s 克制，优先穿透、蓄能和锁定。" % _element_name(weakness)
		"level_005", "level_010":
			return "首领压力高。推荐 %s 克制，优先穿透、蓄能和减速。" % _element_name(weakness)
		_:
			return "防线被突破。主弱点是 %s，可换克制配装或重打拿卡。" % _element_name(weakness)

func _upgrade_action_label(victory: bool) -> String:
	if victory:
		return "强化再出发"
	var recommended_power := SaveManager.get_recommended_power_for_level(level_id)
	if SaveManager.get_loadout_power() < recommended_power:
		return "补强战力"
	return "调整克制"

func _element_name(element: String) -> String:
	match element:
		"physical": return "物理"
		"fire": return "火焰"
		"ice": return "冰霜"
		"lightning": return "闪电"
		"poison": return "毒素"
		_: return element
