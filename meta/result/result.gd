extends Control

const UiKit := preload("res://ui/ui_kit.gd")
const ChallengeRules := preload("res://core/data/challenge_rules.gd")
const CONTENT_MAX_WIDTH := 920.0
const CONTENT_SIDE_MARGIN := 88.0
const HERO_TITLE_NORMAL_SIZE := 70
const HERO_TITLE_LONG_SIZE := 58
const HERO_TITLE_SHORT_SIZE := 78
const RESULT_VISUAL_NUDGE_Y := -24.0
const RESULT_FALLBACK_HEIGHT := 900.0
const RESULT_PORTRAIT_WINDOW_SIZE := Vector2(170, 144)
const RESULT_PORTRAIT_VISIBLE_HEIGHT := 280.0
const RESULT_PORTRAIT_HEADROOM := 8.0
const RESULT_OUTCOME_PANEL_HEIGHT := 164.0
const RESULT_OUTCOME_HORIZONTAL_SAFE := 36.0
const RESULT_OUTCOME_COPY_GAP := 18
const RESULT_OUTCOME_HERO_LINE_HEIGHT := 62.0
const RESULT_OUTCOME_HERO_WRAPPED_HEIGHT := 112.0
const RESULT_REWARD_SIDE_PADDING := 30.0
const RESULT_REWARD_ICON_SIZE := Vector2(54, 54)
const RESULT_REWARD_COPY_GAP := 16
const RESULT_HINT_SIDE_PADDING := 28.0
const RESULT_HINT_ICON_SIZE := Vector2(50, 50)
const RESULT_HINT_COPY_GAP := 16
const RESULT_HINT_PREMIUM_HEIGHT := 168.0

var router: Node
var level_id := "level_001"
var next_level := ""
var result_stars := 0
var _result_return_payload := {}
var is_endless_result := false
var is_challenge_result := false
var endless_loops := 0
var _content_width := CONTENT_MAX_WIDTH
var power := 1
var recommended_power := 1
var cards_picked := 0
var target_card_picks := 0
var battle_report: Dictionary = {}
var repeat_xp_mult := 1.0
var challenge_rule: Dictionary = {}
var _premium_offer: Dictionary = {}

func setup(main: Node, payload := {}) -> void:
	router = main
	level_id = _resolve_level_id(payload)
	is_endless_result = bool(payload.get("endless", false))
	is_challenge_result = bool(payload.get("challenge", false))
	endless_loops = int(payload.get("endless_loop", 0))
	var victory := bool(payload.get("victory", false))
	next_level = _resolve_next_level(payload, victory)
	result_stars = int(payload.get("stars", 0))
	repeat_xp_mult = clampf(float(payload.get("repeat_xp_mult", 1.0)), 0.0, 1.0)
	power = int(payload.get("power", payload.get("projected_power", payload.get("standing_power", SaveManager.get_power_for_level(level_id)))))
	recommended_power = int(payload.get("recommended_power", SaveManager.get_recommended_power_for_level(level_id)))
	cards_picked = maxi(0, int(payload.get("cards_selected", payload.get("cards_picked", 0))))
	var level := DataLoader.get_row("levels", level_id)
	target_card_picks = maxi(0, int(payload.get("target_card_picks", level.get("target_card_picks", 0))))
	battle_report = payload.get("battle_report", {}).duplicate(true)
	challenge_rule = ChallengeRules.for_level(level_id, DataLoader.get_table("challenges"))
	if is_challenge_result and not payload.has("recommended_power"):
		recommended_power = int(ceil(float(recommended_power) * float(challenge_rule.get("recommended_power_mult", 1.5))))
	if is_endless_result:
		result_stars = 0
	_result_return_payload = _build_result_return_payload(payload, victory)
	_premium_offer = _result_premium_offer(victory)
	_populate_background(victory)
	AudioManager.play_bgm("victory" if victory else "defeat")
	AudioManager.play_sfx("victory" if victory else "defeat")
	_populate_hero(victory)
	_populate_outcome_showcase(victory)
	_populate_rewards(payload, victory)
	_populate_hint(victory)
	_populate_battle_report(victory)
	_populate_actions(victory)
	if victory:
		SaveManager.repair_progression_unlocks()
	call_deferred("_center_result_content")
	call_deferred("_animate_result_entry", victory)

func _ready() -> void:
	_apply_layout_constraints()
	_apply_ui_style()
	$Content/Actions/PrimaryRow/UpgradeButton.pressed.connect(_on_upgrade_pressed)
	$Content/Actions/PrimaryRow/RetryButton.pressed.connect(_on_retry_pressed)
	$Content/Actions/NextButton.pressed.connect(_on_next_pressed)
	$Content/Actions/MapButton.pressed.connect(_on_map_pressed)
	$Content/ReportButton.pressed.connect(_on_report_pressed)
	$Content/HintCard.gui_input.connect(_on_hint_card_gui_input)

func _apply_layout_constraints() -> void:
	var viewport_size := get_viewport_rect().size
	var raw_width := minf(CONTENT_MAX_WIDTH, maxf(840.0, viewport_size.x - CONTENT_SIDE_MARGIN * 2.0))
	var content_width := _native_result_content_width(raw_width)
	_content_width = content_width
	var content := $Content as Control
	var safe := UiKit.safe_area_canvas_insets(get_viewport())
	var safe_center_shift := (safe.y - safe.w) * 0.5
	content.offset_left = -content_width * 0.5
	content.offset_right = content_width * 0.5
	_set_result_content_height(RESULT_FALLBACK_HEIGHT, safe_center_shift)
	content.set_meta("safe_area_content", true)
	content.add_theme_constant_override("separation", 12)
	for path in ["Content/HeroCard", "Content/RewardRow", "Content/HintCard", "Content/ReportButton", "Content/ReportPanel", "Content/Actions"]:
		var node := get_node_or_null(path) as Control
		if node != null:
			node.custom_minimum_size.x = content_width
	$Content/HeroCard/HeroBox.add_theme_constant_override("separation", 6)
	$Content/HeroCard/HeroBox/Title.custom_minimum_size = Vector2(content_width - 96.0, 0)
	$Content/HeroCard/HeroBox/Title.clip_text = false
	$Content/HeroCard/HeroBox/LevelName.custom_minimum_size = Vector2(content_width - 120.0, 0)
	$Content/HeroCard/HeroBox/LevelName.clip_text = false
	var outcome_panel_width := content_width - 64.0
	$Content/HeroCard/HeroBox/OutcomePanel.custom_minimum_size = Vector2(outcome_panel_width, RESULT_OUTCOME_PANEL_HEIGHT)
	$Content/HeroCard/HeroBox/OutcomePanel/OutcomeRow.add_theme_constant_override("separation", RESULT_OUTCOME_COPY_GAP)
	var outcome_portrait := $Content/HeroCard/HeroBox/OutcomePanel/OutcomeRow/Portrait as TextureRect
	outcome_portrait.custom_minimum_size = RESULT_PORTRAIT_WINDOW_SIZE
	outcome_portrait.clip_contents = true
	outcome_portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	$Content/HeroCard/HeroBox/OutcomePanel/OutcomeRow/OutcomeCopy.custom_minimum_size = Vector2(
		outcome_panel_width
		- RESULT_OUTCOME_HORIZONTAL_SAFE * 2.0
		- RESULT_PORTRAIT_WINDOW_SIZE.x
		- RESULT_OUTCOME_COPY_GAP,
		0
	)
	var outcome_hero_name := $Content/HeroCard/HeroBox/OutcomePanel/OutcomeRow/OutcomeCopy/HeroName as Label
	outcome_hero_name.custom_minimum_size.y = maxf(outcome_hero_name.custom_minimum_size.y, RESULT_OUTCOME_HERO_LINE_HEIGHT)
	outcome_hero_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outcome_hero_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outcome_hero_name.max_lines_visible = 2
	outcome_hero_name.clip_text = true
	$Content/RewardRow.add_theme_constant_override("separation", 16)
	_configure_reward_layout()
	for path in ["Content/RewardRow/GoldCard/GoldBox", "Content/RewardRow/XpCard/XpBox"]:
		var reward_box := get_node_or_null(path) as HBoxContainer
		if reward_box != null:
			reward_box.add_theme_constant_override("separation", RESULT_REWARD_COPY_GAP)
	for path in ["Content/RewardRow/GoldCard/GoldBox/GoldIcon", "Content/RewardRow/XpCard/XpBox/XpIcon"]:
		var icon := get_node_or_null(path) as Control
		if icon != null:
			icon.custom_minimum_size = RESULT_REWARD_ICON_SIZE
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for path in ["Content/RewardRow/GoldCard/GoldBox/GoldVBox", "Content/RewardRow/XpCard/XpBox/XpVBox"]:
		var reward_copy := get_node_or_null(path) as Control
		if reward_copy != null:
			reward_copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	$Content/HintCard/HintBox.add_theme_constant_override("separation", RESULT_HINT_COPY_GAP)
	$Content/HintCard/HintBox/HintIcon.custom_minimum_size = RESULT_HINT_ICON_SIZE
	_configure_hint_layout()
	$Content/ReportButton.custom_minimum_size = Vector2(content_width, UiKit.MIN_TOUCH_TARGET.y)
	$Content/ReportPanel.custom_minimum_size.x = content_width
	call_deferred("_center_result_content")

func _center_result_content() -> void:
	if not is_inside_tree():
		return
	var content := $Content as Control
	var minimum_height := maxf(content.get_combined_minimum_size().y, 1.0)
	var safe := UiKit.safe_area_canvas_insets(get_viewport())
	var safe_center_shift := (safe.y - safe.w) * 0.5
	_set_result_content_height(minimum_height, safe_center_shift)

func _set_result_content_height(content_height: float, safe_center_shift: float) -> void:
	var content := $Content as Control
	var center_y := safe_center_shift + RESULT_VISUAL_NUDGE_Y
	content.offset_top = center_y - content_height * 0.5
	content.offset_bottom = center_y + content_height * 0.5

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
	$Content/HeroCard/HeroBox/OutcomePanel.add_theme_stylebox_override(
		"panel",
		_with_result_side_padding(UiKit.hint_texture_style(false), RESULT_OUTCOME_HORIZONTAL_SAFE)
	)
	$Content/RewardRow/GoldCard.add_theme_stylebox_override("panel", _with_result_side_padding(UiKit.reward_texture_style("gold"), RESULT_REWARD_SIDE_PADDING))
	$Content/RewardRow/XpCard.add_theme_stylebox_override("panel", _with_result_side_padding(UiKit.reward_texture_style("xp"), RESULT_REWARD_SIDE_PADDING))
	$Content/ReportPanel.add_theme_stylebox_override("panel", UiKit.result_panel_texture_style())
	UiKit.apply_armored_texture_button($Content/ReportButton, false, Vector2(_content_width, UiKit.MIN_TOUCH_TARGET.y), true)
	_reset_action_button_tints()
	UiKit.apply_label($Content/HeroCard/HeroBox/Eyebrow, 18, UiKit.GOLD, 2)
	_apply_title_label_style(HERO_TITLE_NORMAL_SIZE, UiKit.TEXT_MAIN)
	UiKit.apply_label($Content/HeroCard/HeroBox/LevelName, 26, Color(0.78, 0.84, 0.84, 1.0), 3)
	var outcome_hero_name := $Content/HeroCard/HeroBox/OutcomePanel/OutcomeRow/OutcomeCopy/HeroName as Label
	var outcome_hero_size := 24 if outcome_hero_name.custom_minimum_size.y >= RESULT_OUTCOME_HERO_WRAPPED_HEIGHT else 26
	UiKit.apply_label(outcome_hero_name, outcome_hero_size, UiKit.TEXT_MAIN, 3)
	UiKit.apply_label($Content/HeroCard/HeroBox/OutcomePanel/OutcomeRow/OutcomeCopy/Moment, 19, UiKit.CYAN, 2)
	UiKit.apply_label($Content/RewardRow/GoldCard/GoldBox/GoldVBox/GoldLabel, 18, UiKit.GOLD, 2)
	UiKit.apply_label($Content/RewardRow/GoldCard/GoldBox/GoldVBox/GoldValue, 40, UiKit.GOLD, 4)
	UiKit.apply_label($Content/RewardRow/XpCard/XpBox/XpVBox/XpLabel, 18, UiKit.CYAN, 2)
	UiKit.apply_label($Content/RewardRow/XpCard/XpBox/XpVBox/XpValue, 40, UiKit.CYAN, 4)
	UiKit.apply_label($Content/HintCard/HintBox/Hint, 22, UiKit.TEXT_MAIN, 2)
	UiKit.apply_label($Content/ReportButton/ReportLabel, 22, UiKit.CYAN, 4)
	UiKit.apply_label($Content/ReportPanel/ReportBox/Heading, 18, UiKit.GOLD, 2)
	UiKit.apply_label($Content/ReportPanel/ReportBox/Overview, 20, UiKit.TEXT_MAIN, 2)
	UiKit.apply_label($Content/ReportPanel/ReportBox/Output, 19, UiKit.CYAN, 2)
	UiKit.apply_label($Content/ReportPanel/ReportBox/Defense, 19, UiKit.TEXT_MUTED, 2)
	UiKit.apply_label($Content/ReportPanel/ReportBox/Coach, 18, UiKit.WARNING, 2)
	for spec in [
		{"path": "Content/Actions/PrimaryRow/UpgradeButton/UpgradeLabel", "size": 30},
		{"path": "Content/Actions/PrimaryRow/RetryButton/RetryLabel", "size": 30},
		{"path": "Content/Actions/NextButton/NextLabel", "size": 30},
		{"path": "Content/Actions/MapButton/MapLabel", "size": 22},
	]:
			var label := get_node_or_null(str(spec["path"])) as Label
			if label != null:
				var label_size := int(spec["size"])
				if LocalizationManager.is_english() and str(spec["path"]).contains("PrimaryRow"):
					label_size = mini(label_size, 24)
				UiKit.apply_label(label, label_size, Color(1, 1, 1, 1), 5)

func _apply_title_label_style(size: int, color: Color) -> void:
	var title := $Content/HeroCard/HeroBox/Title as Label
	if LocalizationManager.is_english():
		var translated_title := LocalizationManager.text(title.text)
		if translated_title.length() >= 14:
			size = mini(size, 44)
		elif translated_title.length() >= 10:
			size = mini(size, 50)
		else:
			size = mini(size, 66)
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
		$Content/HeroCard/HeroBox/LevelName.text = "%s · %s" % [level_name, LocalizationManager.text(str(challenge_rule.get("name", "高压尸潮")))]
		_apply_title_label_style(HERO_TITLE_LONG_SIZE, Color(1, 0.78, 0.4, 1) if victory else Color(1, 0.55, 0.45, 1))
	else:
		$Content/HeroCard/HeroBox/Title.text = DataLoader.tr_key("ui_victory") if victory else DataLoader.tr_key("ui_defeat")
		if victory:
			_apply_title_label_style(HERO_TITLE_SHORT_SIZE, Color(1, 0.95, 0.55, 1))
		else:
			_apply_title_label_style(HERO_TITLE_SHORT_SIZE, Color(1, 0.55, 0.45, 1))
		$Content/HeroCard/HeroBox/LevelName.text = level_name
	_refresh_star_row(result_stars)

func _populate_background(victory: bool) -> void:
	var level: Dictionary = DataLoader.get_row("levels", level_id)
	var env_id := str(level.get("env", ""))
	var env: Dictionary = DataLoader.get_row("environments", env_id)
	var background_path := str(env.get("battle_background", ""))
	var background := $Background as TextureRect
	if background_path != "" and ResourceLoader.exists(background_path):
		background.texture = load(background_path)
	background.modulate = Color(0.50, 0.47, 0.40, 1.0) if victory else Color(0.32, 0.36, 0.42, 1.0)

func _populate_outcome_showcase(victory: bool) -> void:
	var character_id := SaveManager.get_selected("character")
	if character_id == "":
		character_id = "vanguard"
	var character: Dictionary = DataLoader.get_row("characters", character_id)
	var portrait_path := UiKit.character_bust_path(character)
	var portrait := $Content/HeroCard/HeroBox/OutcomePanel/OutcomeRow/Portrait as TextureRect
	var portrait_texture := load(portrait_path) as Texture2D if portrait_path != "" and ResourceLoader.exists(portrait_path) else null
	_refresh_result_portrait(portrait, portrait_texture, character_id, victory)
	var character_name := DataLoader.tr_key(str(character.get("name_key", character_id)))
	var hero_name := $Content/HeroCard/HeroBox/OutcomePanel/OutcomeRow/OutcomeCopy/HeroName as Label
	var outcome_text := LocalizationManager.text("完成防守" if victory else "准备反击")
	hero_name.text = "%s · %s" % [character_name, outcome_text]
	var hero_line_size := 26
	var english_layout := LocalizationManager.is_english() or TranslationServer.get_locale().begins_with("en")
	if english_layout:
		hero_line_size = 24
		hero_name.custom_minimum_size.y = RESULT_OUTCOME_HERO_WRAPPED_HEIGHT
	else:
		hero_name.custom_minimum_size.y = RESULT_OUTCOME_HERO_LINE_HEIGHT
	UiKit.apply_label(hero_name, hero_line_size, UiKit.TEXT_MAIN, 3)
	hero_name.add_theme_color_override("font_color", UiKit.GOLD if victory else Color(1.0, 0.62, 0.52, 1.0))
	var duration := int(round(float(battle_report.get("duration_seconds", 0.0))))
	var minutes := int(duration / 60)
	var seconds := duration % 60
	var kills := int(battle_report.get("kills", 0))
	var boss_kills := int(battle_report.get("boss_kills", 0))
	var streak := int(battle_report.get("max_kill_streak", 0))
	var moment := $Content/HeroCard/HeroBox/OutcomePanel/OutcomeRow/OutcomeCopy/Moment as Label
	if victory and boss_kills > 0:
		moment.text = "首领击破 %d · 击杀 %d · 最高 %d 连斩" % [boss_kills, kills, streak]
	elif victory:
		moment.text = "防线守住 · 击杀 %d · 最高 %d 连斩" % [kills, streak]
	else:
		moment.text = "坚持 %d:%02d · 击杀 %d · 复盘后再战" % [minutes, seconds, kills]
	moment.add_theme_color_override("font_color", UiKit.CYAN if victory else UiKit.WARNING)


func _refresh_result_portrait(portrait: TextureRect, texture: Texture2D, character_id: String, victory: bool) -> void:
	portrait.texture = null
	portrait.clip_contents = true
	portrait.custom_minimum_size = RESULT_PORTRAIT_WINDOW_SIZE
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.modulate = Color.WHITE
	portrait.material = null
	var bust := portrait.get_node_or_null("BustImage") as TextureRect
	if bust == null:
		bust = TextureRect.new()
		bust.name = "BustImage"
		bust.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bust.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bust.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.add_child(bust)
	bust.texture = texture
	bust.modulate = Color.WHITE if victory else Color(0.72, 0.76, 0.80, 0.82)
	bust.material = ThemeManager.create_character_material(character_id)
	bust.scale = Vector2.ONE
	if texture == null:
		bust.size = RESULT_PORTRAIT_WINDOW_SIZE
		bust.custom_minimum_size = RESULT_PORTRAIT_WINDOW_SIZE
		bust.position = Vector2.ZERO
		return
	var layout := _result_portrait_layout(texture)
	bust.size = layout.get("size", RESULT_PORTRAIT_WINDOW_SIZE)
	bust.custom_minimum_size = bust.size
	bust.position = layout.get("position", Vector2.ZERO)
	bust.set_meta("result_portrait_scale", float(layout.get("scale", 1.0)))
	bust.set_meta("result_portrait_used_rect", layout.get("used_rect", Rect2()))
	bust.set_meta("result_portrait_visible_rect", layout.get("visible_rect", Rect2()))
	bust.set_meta("result_portrait_framing", "aligned_half_body")


func _result_portrait_layout(texture: Texture2D) -> Dictionary:
	if texture == null:
		return {
			"size": RESULT_PORTRAIT_WINDOW_SIZE,
			"position": Vector2.ZERO,
			"scale": 1.0,
			"used_rect": Rect2(),
			"visible_rect": Rect2(Vector2.ZERO, RESULT_PORTRAIT_WINDOW_SIZE),
		}
	var image := texture.get_image()
	if image == null or image.is_empty():
		return {
			"size": RESULT_PORTRAIT_WINDOW_SIZE,
			"position": Vector2.ZERO,
			"scale": 1.0,
			"used_rect": Rect2(Vector2.ZERO, texture.get_size()),
			"visible_rect": Rect2(Vector2.ZERO, RESULT_PORTRAIT_WINDOW_SIZE),
		}
	var used := image.get_used_rect()
	if used.size == Vector2i.ZERO:
		used = Rect2i(Vector2i.ZERO, Vector2i(texture.get_size()))
	# Use one human-height ruler for every hero and outfit, then let this compact
	# viewport reveal the same head-to-torso slice. Transparent canvas, weapons,
	# coat tails and theme effects cannot make a portrait appear smaller.
	var source_scale := RESULT_PORTRAIT_VISIBLE_HEIGHT / maxf(float(used.size.y), 1.0)
	var bust_size := texture.get_size() * source_scale
	var visible_size := Vector2(float(used.size.x), float(used.size.y)) * source_scale
	var visible_position := Vector2(
		(RESULT_PORTRAIT_WINDOW_SIZE.x - visible_size.x) * 0.5,
		RESULT_PORTRAIT_HEADROOM
	)
	return {
		"size": bust_size,
		"position": visible_position - Vector2(used.position) * source_scale,
		"scale": source_scale,
		"used_rect": Rect2(used),
		"visible_rect": Rect2(visible_position, visible_size),
	}

func _populate_rewards(payload: Dictionary, victory: bool) -> void:
	var gold := int(payload.get("gold", 0))
	var xp := int(payload.get("xp", 0))
	_configure_reward_layout()
	_refresh_xp_repeat_label()
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

## design/24 收尾：重复通关经验按 economy.json.repeat_clear_xp_mult 递减。
## 结算页显示的就是实际入账的数字，所以必须把折扣原因说清楚，否则玩家只会看到
## 同一关第二次打经验莫名变少。百分比由数据算出，不写死。
func _refresh_xp_repeat_label() -> void:
	var label := get_node_or_null("Content/RewardRow/XpCard/XpBox/XpVBox/XpLabel") as Label
	if label == null:
		return
	if repeat_xp_mult >= 0.999:
		label.text = "经 验"
	else:
		label.text = "经 验  ×%d%%" % int(round(repeat_xp_mult * 100.0))

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
	# setup() may run after _ready() (the normal router path and several tests do
	# this), so the offer-dependent height must be refreshed after the offer is
	# known rather than relying on the initial layout pass.
	_configure_hint_layout()
	var hint_text := _result_hint(victory)
	if not _premium_offer.is_empty():
		var premium_name := _premium_arsenal_name(str(_premium_offer.get("series_id", "")))
		var premise := LocalizationManager.text("克制本关 · %s：升级到与你现役同级后") % premium_name
		var power_line := LocalizationManager.text("有效战力 %s → %s") % [
			_format_full_power_number(int(_premium_offer.get("current_power", 0))),
			_format_full_power_number(int(_premium_offer.get("projected_power", 0))),
		]
		hint_text += "\n↗ %s · %s  ›" % [premise, power_line]
	$Content/HintCard/HintBox/Hint.text = hint_text
	$Content/HintCard.set_meta("premium_series_id", str(_premium_offer.get("series_id", "")))
	$Content/HintCard.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not _premium_offer.is_empty() else Control.CURSOR_ARROW
	$Content/HintCard.mouse_filter = Control.MOUSE_FILTER_STOP if not _premium_offer.is_empty() else Control.MOUSE_FILTER_PASS
	UiKit.apply_label($Content/HintCard/HintBox/Hint, 20 if not _premium_offer.is_empty() else 22, UiKit.TEXT_MAIN, 2)
	# swap hint card style by outcome
	var card := $Content/HintCard
	if victory:
		_set_hint_style(card, "victory")
		$Content/HintCard/HintBox/HintIcon.texture = load("res://assets/production/sprites/ui/icon_currency_star.png")
	else:
		_set_hint_style(card, "warning")
		$Content/HintCard/HintBox/HintIcon.texture = load("res://assets/production/sprites/ui/icon_warning.png")
	call_deferred("_center_result_content")

func _configure_hint_layout() -> void:
	var hint_card := get_node_or_null("Content/HintCard") as Control
	var hint_label := get_node_or_null("Content/HintCard/HintBox/Hint") as Control
	if hint_card == null or hint_label == null:
		return
	hint_card.custom_minimum_size = Vector2(
		_content_width,
		RESULT_HINT_PREMIUM_HEIGHT if not _premium_offer.is_empty() else 96.0
	)
	hint_label.custom_minimum_size = Vector2(
		_content_width - RESULT_HINT_SIDE_PADDING * 2.0 - RESULT_HINT_ICON_SIZE.x - RESULT_HINT_COPY_GAP,
		144.0 if not _premium_offer.is_empty() else 72.0
	)

func _result_premium_offer(victory: bool) -> Dictionary:
	if is_endless_result or (victory and result_stars != 1):
		return {}
	var offer: Dictionary = PurchaseManager.premium_power_offer_for_level(level_id, 0.0, 0.0)
	if offer.is_empty():
		return {}
	var result_ratio := float(offer.get("projected_power", 0)) / maxf(float(recommended_power), 1.0)
	if result_ratio + 0.0001 < 1.2:
		return {}
	offer["result_ratio"] = result_ratio
	return offer

func _on_hint_card_gui_input(event: InputEvent) -> void:
	if _premium_offer.is_empty():
		return
	var activate := false
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		activate = mouse_button.button_index == MOUSE_BUTTON_LEFT and not mouse_button.pressed
	elif event is InputEventScreenTouch:
		activate = not (event as InputEventScreenTouch).pressed
	if not activate:
		return
	get_viewport().set_input_as_handled()
	_open_premium_store(str(_premium_offer.get("series_id", "")))

func _open_premium_store(series_id: String) -> void:
	if series_id == "":
		return
	AudioManager.play_sfx("ui_click")
	router.change_scene("store", {
		"return_to": "result",
		"return_payload": _result_return_payload.duplicate(true),
		"focus_series_id": series_id,
	})

func _premium_arsenal_name(series_id: String) -> String:
	var set_row := PurchaseManager.set_for_series(series_id)
	return str(set_row.get(
		"store_title_en" if LocalizationManager.is_english() else "store_title_zh",
		series_id
	))

func _set_hint_style(card: PanelContainer, kind: String) -> void:
	card.add_theme_stylebox_override("panel", _with_result_side_padding(UiKit.hint_texture_style(kind == "warning"), RESULT_HINT_SIDE_PADDING))

func _with_result_side_padding(style: StyleBox, side_padding: float) -> StyleBox:
	# Result cards use decorated textures with luminous inner borders. Their generic
	# 16px content margin placed the icon on top of that border, so reserve an
	# explicit safe lane for the complete icon/copy group on both sides.
	style.content_margin_left = side_padding
	style.content_margin_right = side_padding
	return style

func _populate_battle_report(victory: bool) -> void:
	var duration := int(round(float(battle_report.get("duration_seconds", 0.0))))
	var minutes := int(duration / 60)
	var seconds := duration % 60
	var damage := int(round(float(battle_report.get("damage_total", 0.0))))
	var kills := int(battle_report.get("kills", 0))
	var boss_kills := int(battle_report.get("boss_kills", 0))
	var streak := int(battle_report.get("max_kill_streak", 0))
	var top_element := str(battle_report.get("top_element", "physical"))
	var top_damage := float(battle_report.get("damage_by_element", {}).get(top_element, 0.0))
	var top_share := int(round(top_damage / maxf(float(damage), 1.0) * 100.0))
	$Content/ReportPanel/ReportBox/Overview.text = "用时 %d:%02d  ·  总伤害 %s  ·  击杀 %d%s  ·  最高 %d 连斩" % [minutes, seconds, _format_result_number(damage), kills, "（首领 %d）" % boss_kills if boss_kills > 0 else "", streak]
	var output_line := "主力 %s %d%%  ·  暴击伤害 %s  ·  弱点伤害 %s" % [_element_name(top_element), top_share, _format_result_number(int(round(float(battle_report.get("crit_damage", 0.0))))), _format_result_number(int(round(float(battle_report.get("weak_damage", 0.0)))))]
	var premium_sources := _premium_damage_source_summary()
	$Content/ReportPanel/ReportBox/Output.text = "%s\n%s" % [premium_sources, output_line] if premium_sources != "" else output_line
	$Content/ReportPanel/ReportBox/Defense.text = "防线承伤 %d  ·  格挡 %d  ·  控制 %.1f秒  ·  主动技能 %d次" % [int(battle_report.get("base_damage_taken", 0)), int(battle_report.get("base_damage_prevented", 0)), float(battle_report.get("control_seconds", 0.0)), int(battle_report.get("active_skill_casts", 0))]
	$Content/ReportPanel/ReportBox/Coach.text = _battle_report_coach(victory)


func _premium_damage_source_summary() -> String:
	var sources: Dictionary = battle_report.get("damage_by_source", {})
	var labels_zh := {
		"weapon": "武器", "burn": "灼烧", "combustion": "爆燃",
		"armor_counter": "熔甲", "phoenix": "机凰", "set_spread": "扩散",
		"overload": "过载", "terminal": "雷柱",
	}
	var labels_en := {
		"weapon": "Weapon", "burn": "Burn", "combustion": "Combustion",
		"armor_counter": "Armor", "phoenix": "Phoenix", "set_spread": "Spread",
		"overload": "Overload", "terminal": "Pillar",
	}
	var priority := ["weapon", "burn", "combustion", "armor_counter", "phoenix", "set_spread", "overload", "terminal"]
	var parts: Array[String] = []
	var labels: Dictionary = labels_en if LocalizationManager.is_english() else labels_zh
	for source in priority:
		var value := int(round(float(sources.get(source, 0.0))))
		if value <= 0:
			continue
		parts.append("%s %s" % [str(labels.get(source, source)), _format_result_number(value)])
	if parts.size() <= 1:
		return ""
	return "  ·  ".join(parts.slice(0, mini(parts.size(), 6)))

func _battle_report_coach(victory: bool) -> String:
	if is_challenge_result:
		return "挑战规则：%s。应对：%s" % [ChallengeRules.pressure_text(challenge_rule), str(challenge_rule.get("counter_hint", "围绕弱点配装。"))]
	if not victory:
		var boss_id := str(battle_report.get("boss_id", ""))
		if boss_id != "":
			var boss_hint := str(DataLoader.get_row("bosses", boss_id).get("counter_hint", ""))
			if boss_hint != "":
				return "失败复盘：%s" % boss_hint
		var weak_damage := float(battle_report.get("weak_damage", 0.0))
		var total_damage := maxf(float(battle_report.get("damage_total", 0.0)), 1.0)
		if weak_damage / total_damage < 0.12:
			return "失败复盘：弱点伤害占比较低，换用本关克制元素并优先拿核心伤害牌。"
		if int(battle_report.get("base_damage_taken", 0)) > 0 and float(battle_report.get("control_seconds", 0.0)) < 2.0:
			return "失败复盘：防线承压但控制不足，补一张减速、冰霜或屏障牌。"
	return "复盘建议：保持主伤害流派，再补一张控制或防线牌，成型会更稳定。"

func _on_report_pressed() -> void:
	AudioManager.play_sfx("ui_click", -6.0)
	$Content/ReportPanel.visible = not $Content/ReportPanel.visible
	$Content/ReportButton/ReportLabel.text = "收起战斗战报  ⌃" if $Content/ReportPanel.visible else "展开战斗战报  ›"
	call_deferred("_center_result_content")

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
			button.set_meta("critical_touch", true)

func _refresh_star_row(stars: int) -> void:
	var row := $Content/HeroCard/HeroBox/StarRow
	for child in row.get_children():
		child.queue_free()
	row.visible = not is_endless_result
	_refresh_star_rule_hint()
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

## design/24 Phase 1: the star rule used to be invisible to the player. Numbers
## come from data/economy.json through StarRules - never spell them out here.
func _refresh_star_rule_hint() -> void:
	var box := $Content/HeroCard/HeroBox as VBoxContainer
	var hint := box.get_node_or_null("StarRule") as Label
	if hint == null:
		hint = Label.new()
		hint.name = "StarRule"
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(hint)
	hint.visible = not is_endless_result
	if is_endless_result:
		return
	hint.text = StarRules.hint_text(DataLoader.get_table("economy"))
	UiKit.apply_label(hint, 20, UiKit.TEXT_MUTED, 3)

func _animate_result_entry(victory: bool) -> void:
	$Content.modulate.a = 0.0
	var showcase := $Content/HeroCard/HeroBox/OutcomePanel as Control
	var rewards := $Content/RewardRow as Control
	var actions := $Content/Actions as Control
	showcase.pivot_offset = showcase.size * 0.5
	showcase.scale = Vector2(0.90, 0.90)
	showcase.modulate.a = 0.0
	rewards.modulate.a = 0.0
	actions.modulate.a = 0.0
	if SettingsManager.reduced_effects_enabled():
		$Content.modulate.a = 1.0
		showcase.scale = Vector2.ONE
		showcase.modulate.a = 1.0
		rewards.modulate.a = 1.0
		actions.modulate.a = 1.0
		return
	var tween := $Content.create_tween()
	tween.tween_property($Content, "modulate:a", 1.0, 0.24)
	var showcase_tween := showcase.create_tween()
	showcase_tween.tween_interval(0.06)
	showcase_tween.tween_property(showcase, "modulate:a", 1.0, 0.18)
	showcase_tween.parallel().tween_property(showcase, "scale", Vector2(1.035, 1.035), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	showcase_tween.tween_property(showcase, "scale", Vector2.ONE, 0.12)
	var reward_tween := rewards.create_tween()
	reward_tween.tween_interval(0.20)
	reward_tween.tween_property(rewards, "modulate:a", 1.0, 0.20)
	var action_tween := actions.create_tween()
	action_tween.tween_interval(0.34)
	action_tween.tween_property(actions, "modulate:a", 1.0, 0.20)
	# Stars pop in
	for i in range($Content/HeroCard/HeroBox/StarRow.get_child_count()):
		var star := $Content/HeroCard/HeroBox/StarRow.get_child(i)
		star.pivot_offset = star.size * 0.5
		star.scale = Vector2(0.2, 0.2)
		var star_tween := star.create_tween()
		star_tween.tween_interval(0.15 + 0.08 * i)
		star_tween.tween_property(star, "scale", Vector2(1.18, 1.18), 0.14)
		star_tween.tween_property(star, "scale", Vector2.ONE, 0.14)
	if victory:
		_spawn_victory_sparks()

func _spawn_victory_sparks() -> void:
	var texture := load("res://assets/production/sprites/ui/icon_currency_star.png") as Texture2D
	if texture == null:
		return
	var star_row := $Content/HeroCard/HeroBox/StarRow as Control
	var star_rect := star_row.get_global_rect()
	var origin := star_rect.position + star_rect.size * 0.5
	var random := RandomNumberGenerator.new()
	random.seed = 1701 + int(DataLoader.level_number(level_id))
	for index in range(8):
		var spark := TextureRect.new()
		spark.name = "VictorySpark%02d" % index
		spark.texture = texture
		spark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		spark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var side := 20.0 + random.randf_range(0.0, 12.0)
		spark.size = Vector2(side, side)
		spark.pivot_offset = spark.size * 0.5
		spark.position = origin - spark.pivot_offset
		spark.modulate = Color(1.0, 0.88, 0.35, 0.0)
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spark.z_index = 4
		add_child(spark)
		var angle := TAU * float(index) / 8.0 + random.randf_range(-0.14, 0.14)
		var distance := random.randf_range(110.0, 210.0)
		var target := spark.position + Vector2.RIGHT.rotated(angle) * distance
		var spark_tween := spark.create_tween()
		spark_tween.tween_interval(0.04 + float(index % 4) * 0.035)
		spark_tween.tween_property(spark, "modulate:a", 0.90, 0.10)
		spark_tween.parallel().tween_property(spark, "position", target, 0.72).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		spark_tween.parallel().tween_property(spark, "rotation", random.randf_range(-1.2, 1.2), 0.72)
		spark_tween.tween_property(spark, "modulate:a", 0.0, 0.22)
		spark_tween.tween_callback(spark.queue_free)

func _format_result_number(value: int) -> String:
	var sign := "-" if value < 0 else ""
	var abs_value: int = -value if value < 0 else value
	if abs_value >= 1000000:
		return "%s%.1fm" % [sign, float(abs_value) / 1000000.0]
	if abs_value >= 1000:
		return "%s%.1fk" % [sign, float(abs_value) / 1000.0]
	return "%s%d" % [sign, abs_value]

func _format_full_power_number(value: int) -> String:
	var digits := str(maxi(value, 0))
	var parts: Array[String] = []
	while digits.length() > 3:
		parts.push_front(digits.substr(digits.length() - 3, 3))
		digits = digits.substr(0, digits.length() - 3)
	parts.push_front(digits)
	return ",".join(parts)

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
		return LocalizationManager.text("无尽只结算金币，并记录最高轮数 · %s") % _card_pick_summary()
	if victory:
		if is_challenge_result:
			return LocalizationManager.text("有效战力 %d · 挑战推荐 %d · %s\n星星奖励仅补发超过历史最高星数的部分") % [power, recommended_power, _card_pick_summary()]
		return LocalizationManager.text("有效战力 %d / 推荐 %d · %s。已完成防守。") % [power, recommended_power, _card_pick_summary()]
	if is_challenge_result:
		return LocalizationManager.text("有效战力 %d / 挑战推荐 %d · %s。优先补强克制配装和核心技能。") % [power, recommended_power, _card_pick_summary()]
	if power < recommended_power:
		return LocalizationManager.text("有效战力 %d / 推荐 %d · %s。优先强化武器、角色或核心技能。") % [power, recommended_power, _card_pick_summary()]
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

func _card_pick_summary() -> String:
	if target_card_picks <= 0:
		return LocalizationManager.text("本局选卡 %d") % cards_picked
	# Keep the numerator truthful even if a future mode awards more offers than
	# the authored target. This is a run fact, not another projected power value.
	return LocalizationManager.text("本局选卡 %d/%d") % [cards_picked, target_card_picks]

func _upgrade_action_label(victory: bool) -> String:
	if victory:
		return "强化再出发"
	if power < recommended_power:
		return "补强有效战力"
	return "调整克制"

func _element_name(element: String) -> String:
	match element:
		"physical": return "物理"
		"fire": return "火焰"
		"ice": return "冰霜"
		"lightning": return "闪电"
		"poison": return "毒素"
		_: return element
