extends Control

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
	var title := DataLoader.tr_key("ui_victory") if victory else DataLoader.tr_key("ui_defeat")
	$Title.text = title
	var stars_text := ""
	for i in range(result_stars):
		stars_text += "★ "
	var gold := int(payload.get("gold", 0))
	var xp := int(payload.get("xp", 0))
	$Summary.text = "关卡  %s\n评级  %s\n金币 +%d    经验 +%d" % [
		DataLoader.level_display_name(level_id),
		stars_text,
		gold,
		xp
	]
	if has_node("RewardGold"):
		$RewardGold.text = "+%d" % gold
	if has_node("RewardXp"):
		$RewardXp.text = "+%d" % xp
	_refresh_star_row(result_stars)
	$Hint.text = _result_hint(victory)
	$UpgradeButton/Label.text = _upgrade_action_label(victory)
	if has_node("NextButton/Label") and victory and next_level != "":
		$NextButton/Label.text = "下一关  %s" % DataLoader.level_display_name(next_level)
	$NextButton.visible = victory and next_level != ""
	if victory:
		SaveManager.repair_progression_unlocks()
	call_deferred("_animate_result_entry", victory)

func _ready() -> void:
	$UpgradeButton.pressed.connect(_on_upgrade_pressed)
	$NextButton.pressed.connect(_on_next_pressed)
	$MapButton.pressed.connect(_on_map_pressed)
	$RetryButton.pressed.connect(_on_retry_pressed)

func _animate_result_entry(victory: bool) -> void:
	$Title.scale = Vector2(0.86, 0.86)
	$Summary.modulate.a = 0.0
	if has_node("RewardPanel"):
		$RewardPanel.modulate.a = 0.0
	var title_tween := $Title.create_tween()
	title_tween.tween_property($Title, "scale", Vector2(1.08, 1.08), 0.12)
	title_tween.tween_property($Title, "scale", Vector2.ONE, 0.14)
	var summary_tween := $Summary.create_tween()
	summary_tween.tween_interval(0.1)
	summary_tween.tween_property($Summary, "modulate:a", 1.0, 0.22)
	if has_node("RewardPanel"):
		var reward_tween := $RewardPanel.create_tween()
		reward_tween.tween_interval(0.16)
		reward_tween.tween_property($RewardPanel, "modulate:a", 1.0, 0.2)
	if has_node("StarRow"):
		for i in range($StarRow.get_child_count()):
			var star := $StarRow.get_child(i)
			star.scale = Vector2(0.2, 0.2)
			var tween := star.create_tween()
			tween.tween_interval(0.08 * i)
			tween.tween_property(star, "scale", Vector2(1.12, 1.12), 0.12)
			tween.tween_property(star, "scale", Vector2.ONE, 0.12)

func _refresh_star_row(stars: int) -> void:
	if not has_node("StarRow"):
		return
	for child in $StarRow.get_children():
		child.queue_free()
	for i in range(3):
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(86, 86)
		icon.texture = load("res://assets/production/sprites/ui/ui_star_filled.png" if i < stars else "res://assets/production/sprites/ui/ui_star_empty.png")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$StarRow.add_child(icon)
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
		return ""
	var context: Variant = router.get("run_context")
	if context is Dictionary:
		return str(context.get("level_id", ""))
	return ""

func _result_hint(victory: bool) -> String:
	if victory:
		return "下一关已解锁。当前战力 %d，继续推关前可以优先补主炮和角色质变档。" % SaveManager.get_loadout_power()
	var recommended_power := SaveManager.get_recommended_power_for_level(level_id)
	if SaveManager.get_loadout_power() < recommended_power:
		return "当前战力 %d/%d 偏低。优先升级主炮、角色或核心芯片，再回来打会更稳。" % [SaveManager.get_loadout_power(), recommended_power]
	var level := DataLoader.get_row("levels", level_id)
	var weakness := str(level.get("primary_weakness", "physical"))
	match level_id:
		"level_003", "level_008":
			return "疾跑尸潮突破了防线。推荐使用%s克制，战斗中优先拿减速力场、追踪或多重射击。" % _element_name(weakness)
		"level_004", "level_007", "level_009":
			return "重甲/支援单位压力过高。推荐使用%s克制，优先拿穿透、蓄能，并锁定精英单位。" % _element_name(weakness)
		"level_005", "level_010":
			return "Boss 压力过高。推荐使用%s克制，优先拿穿透、蓄能和减速力场。" % _element_name(weakness)
		_:
			return "防线被突破。当前关卡主弱点是%s，回出战换克制武器/角色，或重打本关换一组技能卡。" % _element_name(weakness)

func _upgrade_action_label(victory: bool) -> String:
	if victory:
		return "强化再出发"
	var recommended_power := SaveManager.get_recommended_power_for_level(level_id)
	if SaveManager.get_loadout_power() < recommended_power:
		return "补强战力"
	return "调整克制"

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
		_:
			return element
