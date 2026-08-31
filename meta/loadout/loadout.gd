extends Control

const UiKit := preload("res://ui/ui_kit.gd")
const CharacterSkillText := preload("res://core/data/character_skill_text.gd")
const ChallengeRules := preload("res://core/data/challenge_rules.gd")
const FREE_WEAPON_SHOWCASE_SIZE := Vector2(388, 252)
const PREMIUM_WEAPON_SHOWCASE_SIZE := Vector2(410, 296)
const HERO_BUST_WINDOW_SIZE := Vector2(336, 282)
const HERO_BUST_REFERENCE_CANVAS_WIDTH := 642.0
const HERO_BUST_REFERENCE_IMAGE_WIDTH := 378.0
const HERO_BUST_REFERENCE_VISIBLE_HEIGHT := 845.0 * HERO_BUST_REFERENCE_IMAGE_WIDTH / HERO_BUST_REFERENCE_CANVAS_WIDTH
const HERO_BUST_HEADROOM := 10.0
const WEAPON_DISPLAY_GUTTER_RATIO := 0.055
const WEAPON_DISPLAY_MIN_GUTTER := 8
const GEAR_CARD_SIZE := Vector2(176, 176)
const GEAR_ROW_SEPARATION := 34
const SMALL_PORTRAIT_SIZE := Vector2(104, 104)
const CHALLENGE_RECOMMENDED_POWER_MULT := 1.5
# design/24 Phase 1 added the star-rule line. The height must clear the worst
# case: English wraps the armor/chip/pet line to three rows. design/24 Phase 5
# adds a conditional counter-weapon suggestion row on top of that.
const DETAILS_PANEL_HEIGHT := 430.0
const DETAILS_PANEL_HEIGHT_WITH_SUGGESTION := 494.0
const DETAILS_PANEL_HEIGHT_WITH_TWO_SUGGESTIONS := 578.0
const BOTTOM_ACTION_SPACER_HEIGHT := 28.0
# design/28:通关线口径下,0.85 以下 = 早期兜底也救不回来的"远低于通关线"档。
const SEVERE_POWER_RATIO := 0.85
const UNDERPOWER_CONFIRM_WINDOW_MSEC := 2600
const SUMMARY_MARGIN_LEFT := 34
const SUMMARY_MARGIN_RIGHT := 30
const SUMMARY_MARGIN_TOP := 20
const SUMMARY_MARGIN_BOTTOM := 20

var router: Node
var level_id := "level_001"
var is_challenge_mode := false
var _return_to := "map"
var _return_payload := {}
var _underpower_confirmation_armed_until_msec := 0

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
	UiKit.apply_armored_texture_button(%BackButton as TextureButton, false, Vector2(170, 88), true)
	UiKit.attach_touch_target(%BackButton as TextureButton)
	(%StartButton as TextureButton).set_meta("critical_touch", true)
	(%StartButton as TextureButton).pressed.connect(_on_start_pressed)
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
	var safe := UiKit.safe_area_canvas_insets(get_viewport())
	var safe_height := get_viewport_rect().size.y - safe.y - safe.w
	var compact_safe_layout := safe_height < 1800.0
	var root := $Root as MarginContainer
	root.add_theme_constant_override("margin_top", 8 if compact_safe_layout else 38)
	root.add_theme_constant_override("margin_bottom", 8 if compact_safe_layout else 36)
	var main := $Root/Main as VBoxContainer
	main.add_theme_constant_override("separation", 8 if compact_safe_layout else 13)
	if has_node("Root/Main/UnitsRow"):
		var units := $Root/Main/UnitsRow as HBoxContainer
		units.custom_minimum_size = Vector2(0, 390 if compact_safe_layout else 430)
	if has_node("Root/Main/GrowthBadge"):
		(%GrowthBadge as Label).custom_minimum_size = Vector2(0, 32 if compact_safe_layout else 42)
	if has_node("Root/Main/GearIconRow"):
		var gear := %GearIconRow as HBoxContainer
		gear.custom_minimum_size = Vector2(0, 176)
		gear.add_theme_constant_override("separation", GEAR_ROW_SEPARATION)
	if has_node("Root/Main/DetailsPanel"):
		(%DetailsPanel as Control).custom_minimum_size = Vector2(0, DETAILS_PANEL_HEIGHT)
	if has_node("Root/Main/BottomSpacer"):
		var spacer := $Root/Main/BottomSpacer as Control
		spacer.custom_minimum_size = Vector2(0, 12 if compact_safe_layout else BOTTOM_ACTION_SPACER_HEIGHT)
		spacer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if has_node("Root/Main/StartButton"):
		var start := %StartButton as TextureButton
		start.custom_minimum_size = Vector2(760, 112)
		UiKit.apply_armored_texture_button(start, true, Vector2(760, 112), true)
		var start_label := start.get_node_or_null("Label") as Label
		if start_label != null:
			start_label.add_theme_font_size_override("font_size", UiKit.bumped_font_size(30 if LocalizationManager.is_english() else 38))

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
	if mode == "characters":
		hit.tooltip_text = LocalizationManager.text("点击更换人物或外观")
		_add_character_entry_badge(hit)
	hit.pressed.connect(_open_collection.bind(mode))

func _add_character_entry_badge(hit: Button) -> void:
	if hit.has_node("CharacterEntryBadge"):
		return
	var badge_panel := PanelContainer.new()
	badge_panel.name = "CharacterEntryBadge"
	badge_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	badge_panel.offset_left = -174.0
	badge_panel.offset_top = 58.0
	badge_panel.offset_right = -22.0
	badge_panel.offset_bottom = 102.0
	badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_panel.add_theme_stylebox_override("panel", UiKit.map_pill_texture_style())
	hit.add_child(badge_panel)
	var badge := Label.new()
	badge.name = "Label"
	badge.text = LocalizationManager.text("人物 / 外观")
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.apply_label(badge, 16, UiKit.CYAN, 3)
	badge_panel.add_child(badge)

func _on_back_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	if router == null:
		return
	router.change_scene(_return_to, _return_payload.duplicate(true))

func _refresh_back_button() -> void:
	var button := %BackButton as TextureButton
	UiKit.apply_armored_texture_button(button, false, Vector2(170, 88), true)
	var label := button.get_node_or_null("Label") as Label
	if label == null:
		return
	label.text = "返回结算" if _return_to == "result" else "返回"

func _refresh_start_button() -> void:
	var label := (%StartButton as TextureButton).get_node_or_null("Label") as Label
	if label == null:
		return
	if _is_severely_underpowered():
		var armed := Time.get_ticks_msec() <= _underpower_confirmation_armed_until_msec
		label.text = LocalizationManager.text("再次点击 · 确认出战" if armed else "有效战力严重不足 · 谨慎出战")
		label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.42, 1.0))
	else:
		label.text = LocalizationManager.text("开始挑战" if is_challenge_mode else "开始战斗")
		label.add_theme_color_override("font_color", Color.WHITE)
	UiKit.fit_label_text(
		label,
		UiKit.bumped_font_size(28 if LocalizationManager.is_english() else 38),
		22,
		42.0,
		10.0
	)

func _on_start_pressed() -> void:
	if _is_severely_underpowered():
		var now := Time.get_ticks_msec()
		if now > _underpower_confirmation_armed_until_msec:
			_underpower_confirmation_armed_until_msec = now + UNDERPOWER_CONFIRM_WINDOW_MSEC
			AudioManager.play_sfx("threat_warning", -6.0, 0.0)
			_refresh_start_button()
			_pulse_start_warning()
			return
	_underpower_confirmation_armed_until_msec = 0
	AudioManager.play_sfx("ui_confirm")
	if is_challenge_mode:
		router.start_challenge_level(level_id)
	else:
		router.start_level(level_id)

func _pulse_start_warning() -> void:
	var button := %StartButton as TextureButton
	button.pivot_offset = button.size * 0.5
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2(0.975, 0.975), 0.07)
	tween.tween_property(button, "scale", Vector2(1.018, 1.018), 0.09)
	tween.tween_property(button, "scale", Vector2.ONE, 0.10)

func _is_severely_underpowered() -> bool:
	var recommended := _recommended_power_for_current_mode()
	if recommended <= 0:
		return false
	var power := SaveManager.get_power_for_level(level_id)
	return float(power) / float(recommended) < SEVERE_POWER_RATIO

# design/28:推荐战力=通关线,三档文案按"能过/压线/过不了"的模型语义命名。
func _power_state(power: int, recommended_power: int) -> Dictionary:
	var ratio := float(power) / maxf(float(recommended_power), 1.0)
	if ratio >= 1.0:
		return {"text": "可通关", "color": UiKit.GREEN}
	if ratio >= SEVERE_POWER_RATIO:
		return {"text": "低于通关线", "color": UiKit.GOLD}
	return {"text": "远低于通关线", "color": UiKit.DANGER}

func _refresh_resource_bar() -> void:
	var main := $Root/Main as VBoxContainer
	if main == null:
		return
	var existing := main.get_node_or_null("ResourceBar")
	if existing != null:
		existing.free()
	var bar := UiKit.standard_resource_bar(SaveManager.get_player_gold(), SaveManager.get_player_star(), SaveManager.get_player_xp())
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
	_underpower_confirmation_armed_until_msec = 0
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
	var power := SaveManager.get_power_for_level(level_id)
	var recommended_power := _recommended_power_for_current_mode()
	var level := DataLoader.get_row("levels", level_id)
	var weakness := str(level.get("primary_weakness", "physical"))
	var character_name := DataLoader.tr_key(DataLoader.get_row("characters", char_id).get("name_key", char_id))
	var weapon_name := DataLoader.tr_key(DataLoader.get_row("weapons", weapon_id).get("name_key", weapon_id))
	var armor_name := _row_name("armors", armor_id) if armor_id != "" else LocalizationManager.text("未装备")
	var chip_name := _row_name("chips", chip_id) if chip_id != "" else LocalizationManager.text("未装备")
	var pet_name := _row_name("pets", pet_id) if pet_id != "" else LocalizationManager.text("未携带")
	var armor_display := "%s Lv%d" % [armor_name, armor_level] if armor_id != "" else armor_name
	var chip_display := "%s Lv%d" % [chip_name, chip_level] if chip_id != "" else chip_name
	var pet_display := "%s Lv%d" % [pet_name, pet_level] if pet_id != "" else pet_name
	var growth_tier := _tier_suffix(maxi(maxi(char_level, weapon_level), maxi(armor_level, chip_level))).strip_edges()
	if growth_tier == "":
		growth_tier = "基础"
	var matchup_factor := _loadout_matchup_factor(level, weapon_id)
	var counter_state := _loadout_matchup_badge(level, weapon_id)
	(%CharacterName as Label).text = "%s  等级%d" % [character_name, char_level]
	(%WeaponName as Label).text = "%s  等级%d" % [weapon_name, weapon_level]
	var mode_label := "挑战模式" if is_challenge_mode else "五波尸潮"
	$Summary.text = LocalizationManager.text("%s · %s · 主弱点 %s\n有效战力 %d / 推荐 %d · %s · 金币 %d\n英雄 %s Lv%d · 武器 %s Lv%d\n护甲 %s · 芯片 %s · 宠物 %s") % [
		DataLoader.level_display_name(level_id),
		mode_label,
		_element_name(weakness),
		power,
		recommended_power,
		counter_state,
		gold,
		character_name,
		char_level,
		weapon_name,
		weapon_level,
		armor_display,
		chip_display,
		pet_display,
	]
	$Summary.visible = false
	_refresh_summary_panel(level_id, weakness, power, recommended_power, counter_state, character_name, char_level, weapon_name, weapon_level, armor_name, armor_level, armor_id != "", chip_name, chip_level, chip_id != "", pet_name, pet_level, pet_id != "", is_challenge_mode)
	var weapon_icon := %WeaponIcon as TextureRect
	var weapon_row := DataLoader.get_row("weapons", weapon_id)
	_configure_weapon_showcase_rect(weapon_icon, weapon_id)
	var weapon_source_path := _loadout_weapon_source_path(weapon_id, weapon_row)
	var weapon_source := load(weapon_source_path) as Texture2D if weapon_source_path != "" else null
	weapon_icon.texture = _loadout_weapon_texture(weapon_source, weapon_icon)
	weapon_icon.modulate = Color.WHITE
	weapon_icon.scale = Vector2.ONE
	UiKit.apply_theme_surface(weapon_icon)
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
	if power < recommended_power:
		if matchup_factor < 1.0:
			$Objective.text += "\n" + LocalizationManager.text("有效战力低于推荐，且属性抗性会压低实际伤害，可能吃力。")
		else:
			$Objective.text += "\n" + LocalizationManager.text("提示：有效战力低于推荐；该数值已计入当前永久技能等级和本关选卡预算。")
	elif matchup_factor < 1.0:
		$Objective.text += "\n" + LocalizationManager.text("战力足够但属性不利，实际战斗可能吃力。")
	elif matchup_factor > 1.0:
		$Objective.text += "\n" + LocalizationManager.text("战力足够且属性克制，实际伤害更有利。")
	$GoldLabel.text = "金币  %d" % gold
	var can_upgrade := SaveManager.can_upgrade_weapon(weapon_id)
	var dmg_bonus := int(round((SaveManager.get_weapon_damage_multiplier(weapon_id) - 1.0) * 100.0))
	var next_level := mini(weapon_level + 1, int(weapon_row.get("max_level", weapon_level)))
	var next_bonus := int(round((SaveManager.weapon_damage_multiplier_at_level(weapon_row, next_level) - 1.0) * 100.0))
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


func _configure_weapon_showcase_rect(icon: TextureRect, weapon_id: String) -> void:
	# Free guns need a broader, banner-like stage so their full mechanical
	# silhouette reads at phone scale. Apocalypse weapons receive a slightly
	# larger ruler so their paid hierarchy remains unmistakable without touching
	# the panel title, item name or metal frame.
	var display_size := PREMIUM_WEAPON_SHOWCASE_SIZE if weapon_id.begins_with("weapon_apocalypse_") else FREE_WEAPON_SHOWCASE_SIZE
	icon.custom_minimum_size = display_size
	icon.anchor_left = 0.5
	icon.anchor_top = 0.5
	icon.anchor_right = 0.5
	icon.anchor_bottom = 0.5
	icon.offset_left = -display_size.x * 0.5
	icon.offset_top = -display_size.y * 0.5
	icon.offset_right = display_size.x * 0.5
	icon.offset_bottom = display_size.y * 0.5
	icon.pivot_offset = display_size * 0.5
	# Every source now has its own authored horizontal showcase silhouette. Keep
	# the stage rotation-neutral so the weapon and its text share one visual axis.
	icon.rotation_degrees = 0.0

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
	var layout := _loadout_bust_layout(texture)
	var bust_size: Vector2 = layout.get("size", HERO_BUST_WINDOW_SIZE)
	bust.size = bust_size
	bust.custom_minimum_size = bust_size
	bust.position = layout.get("position", Vector2.ZERO)
	bust.set_meta("loadout_portrait_scale", float(layout.get("scale", 1.0)))
	bust.set_meta("loadout_portrait_used_rect", layout.get("used_rect", Rect2()))
	bust.set_meta("loadout_portrait_visible_rect", layout.get("visible_rect", Rect2()))
	bust.set_meta("loadout_portrait_target_visible_height", HERO_BUST_REFERENCE_VISIBLE_HEIGHT)
	bust.set_meta("loadout_portrait_normalized", true)


func _loadout_bust_layout(texture: Texture2D) -> Dictionary:
	if texture == null:
		return {
			"size": HERO_BUST_WINDOW_SIZE,
			"position": Vector2.ZERO,
			"scale": 1.0,
			"used_rect": Rect2(),
			"visible_rect": Rect2(Vector2.ZERO, HERO_BUST_WINDOW_SIZE),
		}
	var image := texture.get_image()
	if image == null or image.is_empty():
		return {
			"size": HERO_BUST_WINDOW_SIZE,
			"position": Vector2.ZERO,
			"scale": 1.0,
			"used_rect": Rect2(Vector2.ZERO, texture.get_size()),
			"visible_rect": Rect2(Vector2.ZERO, HERO_BUST_WINDOW_SIZE),
		}
	var used := image.get_used_rect()
	if used.size == Vector2i.ZERO:
		used = Rect2i(Vector2i.ZERO, Vector2i(texture.get_size()))
	# The accepted default Steel Vanguard composition is the ruler. Measure the
	# actual alpha silhouette instead of the authoring canvas so transparent
	# padding, slim outfits and wide weapon/effect layers cannot make one hero
	# read smaller than another. Natural body width is never stretched.
	var source_scale := HERO_BUST_REFERENCE_VISIBLE_HEIGHT / maxf(float(used.size.y), 1.0)
	var texture_size := texture.get_size()
	var bust_size := texture_size * source_scale
	var visible_size := Vector2(float(used.size.x), float(used.size.y)) * source_scale
	var visible_position := Vector2(
		(HERO_BUST_WINDOW_SIZE.x - visible_size.x) * 0.5,
		HERO_BUST_HEADROOM
	)
	return {
		"size": bust_size,
		"position": visible_position - Vector2(used.position) * source_scale,
		"scale": source_scale,
		"used_rect": Rect2(used),
		"visible_rect": Rect2(visible_position, visible_size),
	}


func _loadout_weapon_source_path(weapon_id: String, row: Dictionary) -> String:
	# Loadout cards are product showcases, not inventory icons. Prefer a clean,
	# unframed weapon render and let the active cosmetic theme resolve its matching
	# skin. A per-item loadout_art override handles authored exceptions without
	# leaking UI presentation rules into combat assets.
	var fallback := str(row.get("loadout_art", row.get("handheld", row.get("icon", ""))))
	return ThemeManager.resolve_weapon_asset(weapon_id, "handheld", fallback)


func _loadout_weapon_texture(source: Texture2D, icon: TextureRect) -> Texture2D:
	if icon != null:
		icon.remove_meta("loadout_weapon_source_path")
		icon.remove_meta("loadout_weapon_source_used_rect")
		icon.remove_meta("loadout_weapon_display_region")
		icon.remove_meta("loadout_weapon_visible_long_axis")
	if source == null:
		return source
	var image := source.get_image()
	if image == null or image.is_empty():
		return source
	var used := image.get_used_rect()
	if used.size == Vector2i.ZERO:
		return source
	var gutter := maxi(WEAPON_DISPLAY_MIN_GUTTER, int(ceil(float(maxi(used.size.x, used.size.y)) * WEAPON_DISPLAY_GUTTER_RATIO)))
	var left := maxi(0, used.position.x - gutter)
	var top := maxi(0, used.position.y - gutter)
	var right := mini(image.get_width(), used.end.x + gutter)
	var bottom := mini(image.get_height(), used.end.y + gutter)
	var region := Rect2i(left, top, right - left, bottom - top)
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(region)
	if icon != null:
		icon.set_meta("loadout_weapon_source_path", source.resource_path)
		icon.set_meta("loadout_weapon_source_used_rect", Rect2(used))
		icon.set_meta("loadout_weapon_display_region", Rect2(region))
		var fit_scale := minf(icon.size.x / maxf(float(region.size.x), 1.0), icon.size.y / maxf(float(region.size.y), 1.0))
		icon.set_meta("loadout_weapon_visible_long_axis", float(maxi(used.size.x, used.size.y)) * fit_scale)
	return atlas

func _row_name(table: String, item_id: String) -> String:
	if item_id == "":
		return ""
	var row := DataLoader.get_row(table, item_id)
	if row.is_empty():
		return item_id
	return DataLoader.tr_key(row.get("name_key", item_id))

func _refresh_summary_panel(display_level_id: String, weakness: String, power: int, recommended_power: int, counter_state: String, character_name: String, char_level: int, weapon_name: String, weapon_level: int, armor_name: String, armor_level: int, has_armor: bool, chip_name: String, chip_level: int, has_chip: bool, pet_name: String, pet_level: int, has_pet: bool, challenge_mode: bool) -> void:
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

	var safe_area := MarginContainer.new()
	safe_area.name = "SummarySafeArea"
	safe_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	var safe := UiKit.safe_area_canvas_insets(get_viewport())
	var compact_safe_layout := get_viewport_rect().size.y - safe.y - safe.w < 1800.0
	safe_area.add_theme_constant_override("margin_left", SUMMARY_MARGIN_LEFT)
	safe_area.add_theme_constant_override("margin_right", SUMMARY_MARGIN_RIGHT)
	safe_area.add_theme_constant_override("margin_top", 12 if compact_safe_layout else SUMMARY_MARGIN_TOP)
	safe_area.add_theme_constant_override("margin_bottom", 12 if compact_safe_layout else SUMMARY_MARGIN_BOTTOM)
	safe_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(safe_area)

	var box := VBoxContainer.new()
	box.name = "SummaryContent"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_area.add_child(box)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	box.add_child(title_row)
	var title := UiKit.label("挑战摘要" if challenge_mode else "战术摘要", 23, UiKit.TEXT_MAIN, 4)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var power_state := _power_state(power, recommended_power)
	var power_pill := UiKit.semantic_tag_pill(str(power_state.get("text", "低于通关线")), "status", 14)
	power_pill.name = "PowerStatePill"
	power_pill.custom_minimum_size = Vector2(156, 38)
	title_row.add_child(power_pill)
	var state := UiKit.semantic_tag_pill(counter_state, "ability", 14)
	state.name = "CounterStatePill"
	state.custom_minimum_size = Vector2(224, 38)
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
	grid.add_child(_summary_cell("关卡", "%s / %s" % [DataLoader.level_display_name(display_level_id), "挑战" if challenge_mode else "五波"], UiKit.GOLD, ""))
	grid.add_child(_summary_cell("弱点", _element_name(weakness), UiKit.PURPLE, UiKit.element_icon_path(weakness)))
	grid.add_child(_summary_cell("有效战力", "%d" % power, UiKit.GREEN if power >= recommended_power else UiKit.PURPLE, ""))
	grid.add_child(_summary_cell("推荐", "%d" % recommended_power, UiKit.GOLD, ""))

	# The three-axis power contract already determines why this loadout is held
	# back. Surface that existing result here instead of asking players to infer
	# it from one scalar. This is explanatory UI only; it does not recalculate or
	# alter Effective Power.
	var bottleneck_reason := UiKit.label(_power_bottleneck_reason(display_level_id, challenge_mode), 18, UiKit.PURPLE, 4)
	bottleneck_reason.name = "BottleneckReason"
	bottleneck_reason.custom_minimum_size = Vector2(0, 32)
	bottleneck_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottleneck_reason.clip_text = false
	box.add_child(bottleneck_reason)

	var loadout := Label.new()
	# Never decide level suffixes from translated display text. English used to
	# render the impossible "Not Equipped Lv0" because this branch compared the
	# localized name against the Chinese sentinel.
	var armor_display := "%s Lv%d" % [armor_name, armor_level] if has_armor else armor_name
	var chip_display := "%s Lv%d" % [chip_name, chip_level] if has_chip else chip_name
	var pet_level_suffix := (" Lv%d" % pet_level) if has_pet else ""
	loadout.text = "英雄 %s Lv%d · 武器 %s Lv%d\n护甲 %s · 芯片 %s · 宠物 %s%s" % [
		character_name,
		char_level,
		weapon_name,
		weapon_level,
		armor_display,
		chip_display,
		pet_name,
		pet_level_suffix,
	]
	loadout.custom_minimum_size = Vector2(0, 68)
	loadout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loadout.clip_text = false
	UiKit.apply_label(loadout, 21, UiKit.TEXT_MAIN, 4)
	box.add_child(loadout)

	# design/24 Phase 5: elemental counter is a 3x difficulty swing that the
	# player cannot see. If they already own a matching weapon and left it in
	# the collection, say so and offer one tap to go look at it. Suggest only -
	# never swap gear behind the player's back. The 1.5 comes from economy.json.
	var suggestion := _counter_weapon_suggestion(weakness, str(SaveManager.get_selected("weapon")))
	var power_scale: Dictionary = DataLoader.get_table("economy").get("power_scale_v6", {})
	var commercial: Dictionary = power_scale.get("commercial_thresholds", {})
	var premium_offer := PurchaseManager.premium_power_offer_for_level(
		level_id,
		float(commercial.get("loadout_uplift", 0.15)),
		0.0,
	)
	var suggestion_count := int(suggestion != "") + int(not premium_offer.is_empty())
	panel.custom_minimum_size = Vector2(0, _summary_panel_floor(suggestion_count))
	if suggestion != "":
		var suggest := Button.new()
		suggest.name = "CounterSuggestion"
		suggest.text = suggestion
		suggest.flat = true
		suggest.custom_minimum_size = Vector2(0, 44)
		suggest.mouse_filter = Control.MOUSE_FILTER_STOP
		suggest.add_theme_color_override("font_color", UiKit.GREEN)
		suggest.add_theme_font_size_override("font_size", UiKit.bumped_font_size(19))
		suggest.pressed.connect(_open_collection.bind("weapons"))
		box.add_child(suggest)
	if not premium_offer.is_empty():
		var premium_suggest := Button.new()
		premium_suggest.name = "PremiumCounterSuggestion"
		var premium_name := _premium_arsenal_name(str(premium_offer.get("series_id", "")))
		var catch_up_level := int(premium_offer.get("catch_up_level", 1))
		var catch_up_gold := int(premium_offer.get("catch_up_gold", 0))
		var premium_premise := (
			"POWER PLAN · %s · AFTER CATCH-UP TO LV%d" % [premium_name, catch_up_level]
			if LocalizationManager.is_english()
			else "战力方案 · %s：追赶至 Lv%d 后" % [premium_name, catch_up_level]
		)
		var premium_power := LocalizationManager.text("有效战力 %s → %s") % [
			_format_power_number(int(premium_offer.get("current_power", 0))),
			_format_power_number(int(premium_offer.get("projected_power", 0))),
		]
		var catch_up_copy := (
			"Full set to Lv%d · %s Gold (catch-up discount included)" % [catch_up_level, _format_power_number(catch_up_gold)]
			if LocalizationManager.is_english()
			else "整套追平至 Lv%d · 需 %s 金币（已含追赶折扣）" % [catch_up_level, _format_power_number(catch_up_gold)]
		)
		premium_suggest.set_meta("premium_series_id", str(premium_offer.get("series_id", "")))
		premium_suggest.set_meta("current_power", int(premium_offer.get("current_power", 0)))
		premium_suggest.set_meta("projected_power", int(premium_offer.get("projected_power", 0)))
		premium_suggest.flat = true
		premium_suggest.custom_minimum_size = Vector2(0, 96)
		premium_suggest.mouse_filter = Control.MOUSE_FILTER_STOP
		premium_suggest.pressed.connect(_open_premium_store.bind(str(premium_offer.get("series_id", ""))))
		var premium_copy := VBoxContainer.new()
		premium_copy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		premium_copy.offset_left = 8
		premium_copy.offset_right = -8
		premium_copy.alignment = BoxContainer.ALIGNMENT_CENTER
		premium_copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		premium_copy.add_theme_constant_override("separation", 0)
		var premium_premise_label := UiKit.label(premium_premise, 15 if LocalizationManager.is_english() else 17, UiKit.GOLD, 3)
		premium_premise_label.name = "RecommendationPremiseText"
		premium_premise_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		premium_premise_label.clip_text = false
		premium_copy.add_child(premium_premise_label)
		var premium_power_label := UiKit.label(premium_power, 17 if LocalizationManager.is_english() else 18, UiKit.GOLD, 3)
		premium_power_label.name = "RecommendationText"
		premium_power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		premium_power_label.clip_text = false
		premium_copy.add_child(premium_power_label)
		var catch_up_label := UiKit.label(catch_up_copy, 14 if LocalizationManager.is_english() else 16, UiKit.GOLD, 3)
		catch_up_label.name = "CatchUpCostText"
		catch_up_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		catch_up_label.clip_text = false
		premium_copy.add_child(catch_up_label)
		premium_suggest.add_child(premium_copy)
		box.add_child(premium_suggest)

	# Turn the rating contract into a compact three-stop visual ruler. Thresholds
	# still come exclusively from economy.json through StarRules.
	box.add_child(_star_threshold_guide())
	# English equipment names and the star rule can wrap to an extra line. Size
	# the summary from its rendered minimum instead of letting the fixed floor
	# clip into the battle button on tall iPhones.
	call_deferred("_fit_summary_panel_to_content", panel, box)

func _star_threshold_guide() -> VBoxContainer:
	var economy: Dictionary = DataLoader.get_table("economy")
	var two_star := int(round(StarRules.two_star_ratio(economy) * 100.0))
	var three_star := int(round(StarRules.three_star_ratio(economy) * 100.0))
	var guide := VBoxContainer.new()
	guide.name = "StarRule"
	guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guide.add_theme_constant_override("separation", 4)
	guide.tooltip_text = LocalizationManager.text(StarRules.hint_text(economy))
	var title := UiKit.label("防线完整度", 15, UiKit.TEXT_MUTED, 2)
	title.name = "Title"
	guide.add_child(title)
	var stops := HBoxContainer.new()
	stops.name = "ThresholdStops"
	stops.add_theme_constant_override("separation", 10)
	guide.add_child(stops)
	var entries := [
		{"stars": 1, "threshold": "< %d%%" % two_star, "accent": UiKit.PURPLE},
		{"stars": 2, "threshold": "≥ %d%%" % two_star, "accent": UiKit.GOLD},
		{"stars": 3, "threshold": "≥ %d%%" % three_star, "accent": UiKit.GREEN},
	]
	for entry in entries:
		var stop := PanelContainer.new()
		stop.custom_minimum_size = Vector2(0, 42)
		stop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stop.add_theme_stylebox_override("panel", UiKit.pill_style(entry.accent))
		stops.add_child(stop)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 4)
		stop.add_child(row)
		for index in int(entry.stars):
			var star := UiKit.icon(UiKit.currency_icon_path("star"), Vector2(18, 18))
			star.name = "Star%d" % (index + 1)
			star.modulate = entry.accent
			row.add_child(star)
		var threshold := UiKit.label(str(entry.threshold), 14, entry.accent, 2)
		threshold.name = "Threshold"
		row.add_child(threshold)
	return guide

func _power_bottleneck_reason(display_level_id: String, challenge_mode: bool) -> String:
	var breakdown := SaveManager.get_power_breakdown_for_level(display_level_id, challenge_mode)
	match str(breakdown.get("power_bottleneck", "crowd")):
		"boss":
			var level := DataLoader.get_row("levels", display_level_id)
			var requirement_var: Variant = level.get("clear_requirement", {})
			var requirement: Dictionary = requirement_var if requirement_var is Dictionary else {}
			var boss_share := clampi(int(round(float(requirement.get("boss_hp_share", 0.0)) * 100.0)), 0, 100)
			return LocalizationManager.text("短板：Boss 单体输出（本关 Boss 血量占比 %d%%）") % boss_share
		"line":
			return LocalizationManager.text("短板：防线维持")
		_:
			return LocalizationManager.text("短板：清群火力")

func _fit_summary_panel_to_content(panel: Control, content: Control) -> void:
	if not is_instance_valid(panel) or not is_instance_valid(content):
		return
	var suggestion_count := int(content.get_node_or_null("CounterSuggestion") != null)
	suggestion_count += int(content.get_node_or_null("PremiumCounterSuggestion") != null)
	var authored_floor := _summary_panel_floor(suggestion_count)
	var rendered_height := ceilf(content.get_combined_minimum_size().y + SUMMARY_MARGIN_TOP + SUMMARY_MARGIN_BOTTOM)
	panel.custom_minimum_size = Vector2(0, maxf(authored_floor, rendered_height))

func _summary_panel_floor(suggestion_count: int) -> float:
	if suggestion_count >= 2:
		return DETAILS_PANEL_HEIGHT_WITH_TWO_SUGGESTIONS
	if suggestion_count == 1:
		return DETAILS_PANEL_HEIGHT_WITH_SUGGESTION
	return DETAILS_PANEL_HEIGHT

func _summary_cell(label_text: String, value_text: String, accent: Color, icon_path: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(360, 50 if LocalizationManager.is_english() else 36)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	if icon_path != "":
		row.add_child(UiKit.icon(icon_path, Vector2(28, 28)))
	var title := UiKit.label(label_text, 18, Color(accent.r, accent.g, accent.b, 1.0), 4)
	title.custom_minimum_size = Vector2(52, 0)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title)
	var value := UiKit.label(value_text, 16 if LocalizationManager.is_english() else 21, accent, 4)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.clip_text = false
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
		label.add_theme_font_size_override("font_size", UiKit.bumped_font_size(20))
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
	kind_label.add_theme_font_size_override("font_size", UiKit.bumped_font_size(16))
	kind_label.add_theme_color_override("font_color", accent)
	kind_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	kind_label.add_theme_constant_override("outline_size", 2)
	stack.add_child(kind_label)
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", UiKit.bumped_font_size(20))
	title_label.add_theme_color_override("font_color", Color(0.94, 1.0, 1.0, 1.0))
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title_label.add_theme_constant_override("outline_size", 3)
	title_label.clip_text = true
	stack.add_child(title_label)
	var desc_label := Label.new()
	desc_label.text = desc.replace("已生效：", "").replace("主动：", "").replace("自动：", "").replace("弹种：", "")
	desc_label.custom_minimum_size = Vector2(0, 48)
	desc_label.add_theme_font_size_override("font_size", UiKit.bumped_font_size(16))
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
		UiKit.item_icon_path(table, selected_id, row) if has_item else "",
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
	# The whole card is already the action target. Repeating “Select” here made
	# the empty English state read “Tap to Select / Armor · Select” and forced
	# both labels against a 176 px frame. Keep this line as the slot identity.
	slot_label.text = _slot_label(slot)
	slot_label.position = Vector2(8, GEAR_CARD_SIZE.y - 42.0)
	slot_label.size = Vector2(GEAR_CARD_SIZE.x - 16.0, 28.0)
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slot_label.clip_text = true
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
		plus.position = Vector2(20, 14)
		plus.size = Vector2(card_size.x - 40.0, 66)
		plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UiKit.apply_label(plus, 38, UiKit.CYAN, 3)
		plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(plus)
		var choose := Label.new()
		choose.name = "EmptyChooseLabel"
		# “选择 / Select” keeps the accepted mobile size without wrapping or
		# leaking beyond the narrow three-column equipment card.
		choose.text = "选择"
		choose.position = Vector2(12, 76)
		choose.size = Vector2(card_size.x - 24.0, 48)
		choose.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		choose.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		choose.clip_text = true
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

## design/24 Phase 5: returns the "you already own a counter weapon" line, or ""
## when there is nothing to suggest (already equipped, or none owned).
func _counter_weapon_suggestion(weakness: String, equipped_weapon_id: String) -> String:
	if weakness == "":
		return ""
	if str(DataLoader.get_row("weapons", equipped_weapon_id).get("element", "")) == weakness:
		return ""
	var weapons: Dictionary = DataLoader.get_table("weapons")
	for key in weapons.keys():
		var weapon_id := str(key)
		var row: Dictionary = weapons[key]
		if weapon_id == equipped_weapon_id:
			continue
		if str(row.get("element", "")) != weakness:
			continue
		if not SaveManager.is_item_unlocked("weapon", weapon_id):
			continue
		var mult := float(DataLoader.get_table("economy").get("weakness_mult", 1.5))
		return "建议武器：%s（克制本关，伤害×%s）" % [
			DataLoader.tr_key(str(row.get("name_key", weapon_id))),
			String.num(mult, 1).trim_suffix(".0"),
		]
	return ""

func _loadout_counters(weakness: String, char_id: String, weapon_id: String, chip_id: String) -> bool:
	var weapon := DataLoader.get_row("weapons", weapon_id)
	# Character affinity and an elemental chip amplify matching attacks, but they
	# do not convert a mismatched main weapon. The loadout summary must describe
	# sustained primary fire, especially for the element-locked final boss.
	return str(weapon.get("element", "")) == weakness

func _loadout_matchup_factor(level: Dictionary, weapon_id: String) -> float:
	var weapon_element := str(DataLoader.get_row("weapons", weapon_id).get("element", "physical"))
	var boss_factor := 1.0
	var has_boss := false
	for wave_value in level.get("waves", []):
		var wave: Dictionary = wave_value
		var boss_id := str(wave.get("boss", ""))
		if boss_id == "":
			continue
		has_boss = true
		boss_factor = minf(boss_factor, float(SaveManager._power_boss_element_factor(DataLoader.get_row("bosses", boss_id), weapon_element)))
		if boss_factor < 1.0:
			return boss_factor
	if has_boss and boss_factor > 1.0:
		return boss_factor
	if weapon_element == str(level.get("primary_weakness", "physical")):
		return maxf(float(DataLoader.get_table("economy").get("weakness_mult", 1.5)), 1.0)
	return 1.0

func _loadout_matchup_badge(level: Dictionary, weapon_id: String) -> String:
	var factor := _loadout_matchup_factor(level, weapon_id)
	var factor_text := "%.1f" % factor if is_equal_approx(factor, roundf(factor)) else String.num(factor, 2).trim_suffix("0")
	if factor > 1.0:
		return LocalizationManager.text("克制：伤害×%s") % factor_text
	if factor < 1.0:
		return LocalizationManager.text("抗性：伤害×%s") % factor_text
	return LocalizationManager.text("属性中性：伤害×1.0")

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

func _open_premium_store(series_id: String) -> void:
	if series_id == "":
		return
	AudioManager.play_sfx("ui_click")
	router.change_scene("store", {
		"return_to": "loadout",
		"return_payload": {
			"level_id": level_id,
			"challenge": is_challenge_mode,
			"return_to": _return_to,
			"return_payload": _return_payload.duplicate(true),
		},
		"focus_series_id": series_id,
	})

func _premium_arsenal_name(series_id: String) -> String:
	var set_row := PurchaseManager.set_for_series(series_id)
	var value := str(set_row.get(
		"store_title_en" if LocalizationManager.is_english() else "store_title_zh",
		series_id
	))
	return value

func _format_power_number(value: int) -> String:
	var digits := str(maxi(value, 0))
	var parts: Array[String] = []
	while digits.length() > 3:
		parts.push_front(digits.substr(digits.length() - 3, 3))
		digits = digits.substr(0, digits.length() - 3)
	parts.push_front(digits)
	return ",".join(parts)

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
