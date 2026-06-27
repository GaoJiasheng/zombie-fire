extends Control

const UiKit := preload("res://ui/ui_kit.gd")

var router: Node
var level_id := "level_001"
var next_level := ""
var result_stars := 0

func setup(main: Node, payload := {}) -> void:
	router = main
	level_id = _resolve_level_id(payload)
	var victory := bool(payload.get("victory", false))
	next_level = _resolve_next_level(payload, victory)
	result_stars = int(payload.get("stars", 0))
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
	_apply_ui_style()
	$Content/Actions/PrimaryRow/UpgradeButton.pressed.connect(_on_upgrade_pressed)
	$Content/Actions/PrimaryRow/RetryButton.pressed.connect(_on_retry_pressed)
	$Content/Actions/NextButton.pressed.connect(_on_next_pressed)
	$Content/Actions/MapButton.pressed.connect(_on_map_pressed)

func _apply_ui_style() -> void:
	$Content/HeroCard.add_theme_stylebox_override("panel", UiKit.panel_style(UiKit.GOLD, Color(0.018, 0.022, 0.030, 0.90), 3, 12))
	$Content/RewardRow/GoldCard.add_theme_stylebox_override("panel", UiKit.panel_style(UiKit.GOLD, Color(0.12, 0.08, 0.03, 0.88), 2, 10))
	$Content/RewardRow/XpCard.add_theme_stylebox_override("panel", UiKit.panel_style(UiKit.CYAN, Color(0.025, 0.040, 0.052, 0.88), 2, 10))
	UiKit.apply_label($Content/HeroCard/HeroBox/Eyebrow, 18, UiKit.GOLD, 2)
	UiKit.apply_label($Content/HeroCard/HeroBox/Title, 86, UiKit.TEXT_MAIN, 6)
	UiKit.apply_label($Content/HeroCard/HeroBox/LevelName, 30, Color(0.78, 0.84, 0.84, 1.0), 3)
	UiKit.apply_label($Content/RewardRow/GoldCard/GoldBox/GoldVBox/GoldLabel, 22, UiKit.GOLD, 2)
	UiKit.apply_label($Content/RewardRow/GoldCard/GoldBox/GoldVBox/GoldValue, 50, UiKit.GOLD, 4)
	UiKit.apply_label($Content/RewardRow/XpCard/XpBox/XpVBox/XpLabel, 22, UiKit.CYAN, 2)
	UiKit.apply_label($Content/RewardRow/XpCard/XpBox/XpVBox/XpValue, 50, UiKit.CYAN, 4)
	UiKit.apply_label($Content/HintCard/HintBox/Hint, 25, UiKit.TEXT_MAIN, 2)
	for path in [
		"Content/Actions/PrimaryRow/UpgradeButton/UpgradeLabel",
		"Content/Actions/PrimaryRow/RetryButton/RetryLabel",
		"Content/Actions/NextButton/NextLabel",
		"Content/Actions/MapButton/MapLabel"
	]:
		var label := get_node_or_null(path) as Label
		if label != null:
			UiKit.apply_label(label, int(label.get_theme_font_size("font_size")), Color(1, 1, 1, 1), 5)

func _populate_hero(victory: bool) -> void:
	$Content/HeroCard/HeroBox/Title.text = DataLoader.tr_key("ui_victory") if victory else DataLoader.tr_key("ui_defeat")
	$Content/HeroCard/HeroBox/LevelName.text = DataLoader.level_display_name(level_id)
	_refresh_star_row(result_stars)
	if victory:
		$Content/HeroCard/HeroBox/Title.add_theme_color_override("font_color", Color(1, 0.95, 0.55, 1))
	else:
		$Content/HeroCard/HeroBox/Title.add_theme_color_override("font_color", Color(1, 0.55, 0.45, 1))

func _populate_rewards(payload: Dictionary, victory: bool) -> void:
	var gold := int(payload.get("gold", 0))
	var xp := int(payload.get("xp", 0))
	if victory:
		$Content/RewardRow/GoldCard/GoldBox/GoldVBox/GoldValue.text = "+%d" % gold
		$Content/RewardRow/XpCard/XpBox/XpVBox/XpValue.text = "+%d" % xp
	else:
		# defeat: show what they got but no rewards credited
		$Content/RewardRow/GoldCard/GoldBox/GoldVBox/GoldValue.text = "+0"
		$Content/RewardRow/XpCard/XpBox/XpVBox/XpValue.text = "+0"
		$Content/RewardRow/GoldCard.modulate = Color(1, 1, 1, 0.45)
		$Content/RewardRow/XpCard.modulate = Color(1, 1, 1, 0.45)

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
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.045, 0.035, 0.88) if kind == "warning" else Color(0.045, 0.090, 0.055, 0.88)
	style.border_width_left = 4
	style.border_color = Color(0.94, 0.38, 0.28, 0.62) if kind == "warning" else Color(0.50, 0.74, 0.42, 0.62)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 22
	style.content_margin_top = 18
	style.content_margin_right = 22
	style.content_margin_bottom = 18
	card.add_theme_stylebox_override("panel", style)

func _populate_actions(victory: bool) -> void:
	$Content/Actions/PrimaryRow/UpgradeButton/UpgradeLabel.text = _upgrade_action_label(victory)
	if victory and next_level != "":
		$Content/Actions/NextButton/NextLabel.text = "下一关"
		$Content/Actions/NextButton.show()
		# Gold-tint next button
		$Content/Actions/NextButton.modulate = Color(1, 0.92, 0.55, 1)
	else:
		$Content/Actions/NextButton.hide()
	# On defeat, dim the upgrade button less aggressively
	if not victory:
		$Content/Actions/PrimaryRow/UpgradeButton/UpgradeLabel.text = _upgrade_action_label(false)
	# Retry button text
	$Content/Actions/PrimaryRow/RetryButton/RetryLabel.text = "重打本关"
	$Content/Actions/MapButton/MapLabel.text = "返回关卡"

func _refresh_star_row(stars: int) -> void:
	var row := $Content/HeroCard/HeroBox/StarRow
	for child in row.get_children():
		child.queue_free()
	for i in range(3):
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(78, 78)
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

func _on_upgrade_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	router.change_scene("loadout", {"level_id": level_id})

func _on_next_pressed() -> void:
	level_id = _resolve_level_id({"level_id": level_id})
	next_level = _resolve_next_level({}, true)
	if next_level == "":
		return
	SaveManager.repair_progression_unlocks()
	AudioManager.play_sfx("ui_confirm")
	router.change_scene("loadout", {"level_id": next_level})

func _on_map_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	router.change_scene("map")

func _on_retry_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	router.start_level(level_id)

func _resolve_next_level(payload: Dictionary, victory: bool) -> String:
	if not victory:
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
	if victory:
		return "当前战力 %d。继续推关前可强化武器、角色或核心芯片。" % SaveManager.get_loadout_power()
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
