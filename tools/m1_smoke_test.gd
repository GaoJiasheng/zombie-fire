extends SceneTree

const SequenceVfx := preload("res://gameplay/vfx/sequence_vfx.gd")
const StatusVfxControllerScript := preload("res://gameplay/vfx/status_vfx_controller.gd")
const FireRateProfiles := preload("res://core/combat/fire_rate_profiles.gd")

class FakeRouter:
	extends Node

	var last_route := ""
	var last_payload := {}
	var last_started_level := ""
	var last_started_challenge_level := ""
	var last_started_endless_level := ""
	var last_result := {}
	var run_context := {}

	func change_scene(route: String, payload := {}) -> void:
		last_route = route
		last_payload = payload

	func start_level(level_id: String) -> void:
		last_started_level = level_id

	func start_challenge_level(level_id: String) -> void:
		last_started_challenge_level = level_id

	func start_endless_level(level_id: String) -> void:
		last_started_endless_level = level_id

	func finish_level(result: Dictionary) -> void:
		last_result = result

class FakeDamageTarget:
	extends Node2D

	var hits := 0
	var total_damage := 0.0

	func take_damage(amount: float, _element := "physical", _armor_penetration := 0.0, _status_strength := -1.0) -> void:
		hits += 1
		total_damage += amount

class FakeAimTarget:
	extends Node2D

	var breach_damage := 20
	var hp_ratio := 1.0
	var elite := false
	var boss := false
	var threat_tags := ["breach"]
	var speed_mult := 1.0
	var external_damage_mult := 1.0
	var mechanic := ""
	var hp := 100.0
	var max_hp := 100.0
	var hits := 0
	var total_damage := 0.0
	var last_element := ""
	var last_status_strength := 0.0
	var threat_label_visible := true
	var status_label_visible := true

	func targeting_snapshot() -> Dictionary:
		return {
			"position": global_position,
			"y": global_position.y,
			"breach_damage": breach_damage,
			"hp_ratio": hp_ratio,
			"elite": elite,
			"boss": boss,
			"threat_tags": threat_tags
		}

	func set_combat_label_visibility(show_threat: bool, show_status: bool) -> void:
		threat_label_visible = show_threat
		status_label_visible = show_status

	func take_damage(amount: float, element := "physical", _armor_penetration := 0.0, status_strength := -1.0) -> void:
		hits += 1
		total_damage += amount
		last_element = element
		last_status_strength = status_strength
		hp = maxf(1.0, hp - amount)

func _initialize() -> void:
	await process_frame
	root.size = Vector2i(1080, 1920)
	var data_loader := root.get_node("/root/DataLoader")
	var save_manager := root.get_node("/root/SaveManager")
	var audio_manager := root.get_node("/root/AudioManager")
	var input_manager := root.get_node("/root/InputManager")
	var settings_manager := root.get_node("/root/SettingsManager")
	data_loader.load_all()
	save_manager.load_game()
	var smoke_save_snapshot: Dictionary = save_manager.save_data.duplicate(true)
	var smoke_settings_snapshot: Dictionary = settings_manager.settings.duplicate(true)
	_expect(InputMap.has_action("cycle_target_strategy"), "input map must expose target strategy cycling")
	_expect(save_manager.get_weapon_damage_multiplier("weapon_autocannon") >= 1.0, "weapon upgrade must expose damage multiplier")
	_expect(root.has_node("/root/SettingsManager"), "settings manager must be autoloaded")

	_expect(data_loader.get_table("levels").size() >= 99, "levels table must contain a launch campaign")
	_expect(data_loader.get_table("skills").size() >= 16, "skills table must contain a broad launch pool")
	var golden_weapon: Dictionary = data_loader.get_row("weapons", "weapon_apocalypse_golden_law")
	_expect(absf(save_manager._weapon_endgame_growth_multiplier(golden_weapon, 1) - 1.0) <= 0.000001, "weapon endgame growth must be neutral at level 1")
	_expect(absf(save_manager._weapon_endgame_growth_multiplier(golden_weapon, int(golden_weapon.get("max_level", 50))) - 1.07) <= 0.000001, "weapon endgame growth must reach its authored max-level bonus")
	_verify_zombie_mechanic_profiles(data_loader)
	_verify_zombie_model_redesigns(data_loader)
	_verify_zombie_attack_animation_contracts(data_loader)
	_verify_boss_base_attack_profiles(data_loader)
	_verify_ui_font()
	var starter_weapon: Dictionary = data_loader.get_row("weapons", "weapon_autocannon")
	_expect(data_loader.tr_key(starter_weapon.get("name_key", "")) == "自动机枪", "starter weapon must be displayed as 自动机枪, not a cannon")
	_expect(str(starter_weapon.get("turret", "")) == "res://assets/production/sprites/weapons/weapon_autocannon_turret.png", "starter weapon prototype must use the production machine-gun fallback asset")
	_verify_starter_projectile_hierarchy(data_loader)
	_expect(data_loader.level_display_name("level_002") == "002 城市突围", "level display names must hide internal ids")
	_expect(data_loader.level_display_name("level_011") == "011 废街突围", "all launch levels must have authored display names")
	var economy: Dictionary = data_loader.get_table("economy")
	var enemy_speed_mult := float(economy.get("ENEMY_SPEED_MULT", 1.0))
	_expect(absf(enemy_speed_mult - 0.492) <= 0.001, "enemy walking speed must be globally +20% from the tuned 0.41 baseline via ENEMY_SPEED_MULT")
	var boss_speed_mult := float(economy.get("BOSS_SPEED_MULT", 1.0))
	_expect(absf(boss_speed_mult - 1.5) <= 0.001, "boss walking speed must be +50% via BOSS_SPEED_MULT")
	_expect(str(economy.get("endless_template_level", "")) == "level_025", "endless mode must use a fixed level-25-equivalent template independent of entry level")
	_expect(int(economy.get("endless_boss_resistance_grace_loops", 0)) >= 1, "endless first loop must soften boss resistance and armor pressure")
	var fire_rate_mult := float(economy.get("PLAYER_FIRE_RATE_MULT", 0.25))
	var shot_damage_mult := float(economy.get("PLAYER_SHOT_DAMAGE_MULT", 3.0))
	_expect(absf(fire_rate_mult - 0.25) <= 0.001, "initial player fire rate must use the retuned +50% paced value")
	_expect(absf(fire_rate_mult * shot_damage_mult - 0.75) <= 0.005, "fire-rate retune must preserve the intended shot damage product")
	_verify_fire_rate_profiles(economy)
	_verify_progression_unlock_repair(save_manager)
	await _verify_battle_speed_progression_gate(save_manager)
	await _verify_battle_speed_stress(save_manager)
	# The speed regressions above deliberately exercise the saved 5X setting.
	# Every timing assertion after them must run against the authored 1X clock,
	# independent of the developer/tester's persisted TestFlight speed choice.
	settings_manager.settings["battle_speed"] = 1.0
	Engine.time_scale = 1.0
	_verify_power_skill_level_accounting(save_manager)
	_verify_recommended_power_calibration(save_manager, data_loader)
	_verify_character_power_identity_model(save_manager, data_loader)
	_verify_manual_aim_input(input_manager)
	_verify_targeting_frontline_priority()
	await _verify_turret_fire_gate(data_loader)
	_verify_slow_field_range_contract(data_loader)
	_verify_skill_runtime_mods(save_manager)
	_verify_ammo_element_rules(save_manager)
	await _verify_feedback_budget_guards()
	await _verify_late_wave_count_multipliers(data_loader, save_manager)
	await _verify_endgame_pressure_ramp(data_loader, save_manager)
	await _verify_wave_clear_fast_forward(data_loader, save_manager)
	_verify_projectile_pierce_runtime()
	_verify_projectile_pierce_sweep_runtime()
	_verify_homing_pierce_frontline_cleanup()
	_verify_projectile_visual_profiles()
	_verify_projectile_ballistics_rules()
	await _verify_turret_muzzle_sockets(data_loader)
	await _verify_character_weapon_skins(data_loader, save_manager)
	await _verify_character_active_skill_controls(data_loader, save_manager)
	await _verify_bottom_skill_slot_level_merge(save_manager)
	await _verify_card_offer_permanent_level_preload(save_manager)
	await _verify_endless_mode(save_manager)
	await _verify_boss_resistance_and_regeneration(data_loader)
	await _verify_enemy_hit_flash_scope(data_loader)
	_verify_ice_slow_visual_tint(data_loader)
	await _verify_status_vfx_layers(data_loader)
	await _verify_medic_pet_repair_runtime(data_loader, save_manager, smoke_save_snapshot)
	await _verify_pet_skill_runtime(data_loader, save_manager, smoke_save_snapshot)
	_verify_collection_star_curve(data_loader)
	_verify_owned_store_upgrade_cost(save_manager)
	_verify_local_purchase_flow(data_loader, save_manager, root.get_node("/root/PurchaseManager"))
	await _verify_current_warzone_store_recommendation(data_loader, save_manager, root.get_node("/root/PurchaseManager"))
	await _verify_quantified_premium_loadout_offer(data_loader, save_manager, root.get_node("/root/PurchaseManager"))
	await _verify_quantified_premium_result_offer(data_loader, save_manager, root.get_node("/root/PurchaseManager"))
	await _verify_store_product_preview_contract(data_loader, save_manager)
	await _verify_appearance_selector_states(save_manager)
	_verify_repeat_clear_xp_decay(save_manager, smoke_save_snapshot)
	_verify_variant_wave_one_spawns(data_loader)
	await _verify_wave_formation_lanes(data_loader)
	await _verify_wave_spawn_distribution()
	await _verify_environment_audio_mix(data_loader)
	await _verify_pet_defense_line_anchor(save_manager, smoke_save_snapshot)
	await _verify_underpower_confirmation(save_manager, smoke_save_snapshot)

	var main := _instance("res://main.tscn")
	root.add_child(main)
	# Main refreshes the persisted cosmetic choice during _ready(). Keep the
	# baseline smoke contract deterministic even when a developer/tester last
	# exited with a preview theme selected. Theme-specific rendering is verified
	# independently by theme_manager_test.gd and the visual screenshot matrix.
	root.get_node("/root/ThemeManager")._set_active_without_persist("default")
	await process_frame
	await _verify_resource_chip_theme_matrix(root.get_node("/root/ThemeManager"))
	await _verify_combo_hud_optical_layout()
	_expect(main.current_scene != null, "main must open initial menu")
	_expect(main.current_scene.find_child("HelpButton", true, false) != null, "menu must expose settings entry")
	_expect(main.current_scene.find_child("StoreButton", true, false) != null, "menu must expose the Apocalypse Arsenal entry")
	var menu_title := main.current_scene.find_child("Title", true, false) as TextureRect
	_expect(menu_title != null and menu_title.texture is AtlasTexture, "menu title must crop transparent staging space before aspect fitting")
	_expect(menu_title != null and menu_title.custom_minimum_size.y >= 480.0, "menu title must retain the enlarged all-theme presentation height after safe-area fitting")
	var infernal_theme: Dictionary = {}
	for catalog_theme in root.get_node("/root/ThemeManager").catalog_themes():
		if str(catalog_theme.get("id", "")) == "infernal_dominion":
			infernal_theme = catalog_theme
			break
	_expect(not infernal_theme.is_empty(), "Infernal theme must exist in the runtime theme catalog")
	var infernal_ui: Dictionary = infernal_theme.get("ui", {})
	var infernal_assets: Dictionary = infernal_ui.get("assets", {})
	var infernal_presentations: Dictionary = infernal_ui.get("asset_presentations", {})
	var infernal_logo_presentation: Dictionary = infernal_presentations.get("menu_title", {})
	var infernal_logo_region: Array = infernal_logo_presentation.get("region", [])
	_expect(infernal_logo_region.size() >= 4, "Infernal menu title must define an authored presentation window")
	var infernal_authored_region := Rect2i(
		int(infernal_logo_region[0]),
		int(infernal_logo_region[1]),
		int(infernal_logo_region[2]),
		int(infernal_logo_region[3])
	) if infernal_logo_region.size() >= 4 else Rect2i()
	_expect(infernal_authored_region == Rect2i(210, 0, 620, 340), "Infernal menu title must discard concept-board side staging and keep the reviewed enlarged logo window")
	var infernal_logo_source := load(str(infernal_assets.get("menu_title", ""))) as Texture2D
	var infernal_logo_display: Texture2D = main.current_scene._visible_logo_texture(infernal_logo_source, infernal_logo_presentation)
	_expect(infernal_logo_display is AtlasTexture, "Infernal menu title must use its authored presentation crop")
	if infernal_logo_display is AtlasTexture:
		var infernal_display_region := Rect2i((infernal_logo_display as AtlasTexture).region)
		_expect(infernal_display_region == Rect2i(210, 0, 620, 340), "Infernal menu title crop must preserve symmetric glow-safe staging")
	main.current_scene._on_help_pressed()
	await process_frame
	_expect(main.current_scene.name == "Settings", "settings entry must open the dedicated settings page")
	var settings_vbox: Node = main.current_scene.get_node("Center/Panel/Margin/VBox")
	var settings_panel := main.current_scene.get_node("Center/Panel") as PanelContainer
	var settings_panel_style := settings_panel.get_theme_stylebox("panel") as StyleBoxTexture
	_expect(settings_panel_style != null and settings_panel_style.texture != null and settings_panel_style.texture.resource_path.ends_with("ui_detail_panel_clear.png"), "settings must use the authored rule-free texture surface")
	_expect(settings_vbox.has_node("SoundButton"), "settings must expose sound toggle")
	_expect(settings_vbox.has_node("QualityButton"), "settings must expose quality setting")
	_expect(settings_vbox.has_node("DataRow/BackupButton"), "settings must expose save backup")
	_expect(settings_vbox.has_node("DataRow/RestoreButton"), "settings must expose save restore")
	_expect(settings_vbox.has_node("ResetButton"), "settings must expose reset save entry")
	_expect(settings_vbox.has_node("AboutRow/PrivacyButton"), "settings must expose privacy entry")
	_expect(settings_vbox.has_node("AboutRow/SupportButton"), "settings must expose support entry")
	var privacy_button_text := (settings_vbox.get_node("AboutRow/PrivacyButton") as Button).text
	var support_button_text := (settings_vbox.get_node("AboutRow/SupportButton") as Button).text
	_expect(privacy_button_text.contains("隐私") and privacy_button_text.contains("↗"), "privacy entry must identify the public policy link")
	_expect(support_button_text.contains("支持") and support_button_text.contains("↗"), "support entry must identify the public support link")
	_expect(main.current_scene.PRIVACY_POLICY_URL.begins_with("https://"), "privacy policy link must use HTTPS")
	_expect(main.current_scene.SUPPORT_URL.begins_with("https://"), "support link must use HTTPS")
	main.current_scene._show_info("privacy")
	_expect((settings_vbox.get_node("InfoBody") as Label).text.contains("隐私"), "privacy info must render")
	main.current_scene._show_info("support")
	_expect((settings_vbox.get_node("InfoBody") as Label).text.contains("支持"), "support info must render")
	main.current_scene._show_info("help")
	var control_help := (settings_vbox.get_node("InfoBody") as Label).text
	_expect(control_help.contains("按住战场拖动"), "control help must explain the hold-and-drag manual aim gesture")
	_expect(control_help.contains("双击僵尸"), "control help must accurately explain touch target lock")
	_expect(control_help.contains("双击空地解除"), "control help must explain how to clear a manual lock")
	main.current_scene._on_reset()
	_expect((settings_vbox.get_node("ResetButton") as Button).text.contains("确认"), "reset save must require confirmation")
	var map_gate_save: Dictionary = save_manager._default_save()
	map_gate_save["levels_progress"] = {"level_002": 2, "level_003": 3}
	map_gate_save["unlocks"]["levels"] = ["level_001", "level_002", "level_003", "level_004"]
	map_gate_save["player"]["star"] = 5
	save_manager.save_data = map_gate_save
	main.change_scene("map")
	await process_frame
	_expect(main.current_scene.name == "Map", "main must route to map")
	_expect(main.current_scene.has_node("Background"), "map must render themed background")
	_expect(main.current_scene.find_child("Progress", true, false) != null, "map must show account progress")
	var map_progress := main.current_scene.find_child("Progress", true, false) as Label
	_expect(map_progress != null and not map_progress.visible, "map must hide the old text-only resource copy")
	var map_resource_bar: Node = main.current_scene.find_child("ResourceBarWrap", true, false)
	_expect(map_resource_bar != null, "map must render icon-based account resources")
	var map_resource_row: Node = map_resource_bar.find_child("Row", true, false)
	_expect(map_resource_row != null and map_resource_row.get_child_count() == 3, "map resource bar must show only the unified gold/star/xp chips")
	_assert_resource_chip_geometry(map_resource_row, "map resource bar", "default")
	_expect(main.current_scene.find_child("Nav", true, false) != null, "map must expose collection navigation")
	var map_character_card: Node = main.current_scene.find_child("charactersNavCard", true, false)
	_expect(map_character_card != null, "map must expose the character feature card")
	var map_character_bust := map_character_card.find_child("BustImage", true, false) as TextureRect
	_expect(map_character_bust != null and map_character_bust.texture != null, "map character feature card must use a bust portrait")
	_expect(str(map_character_bust.texture.resource_path).ends_with("_portrait_frameless.png"), "map character feature card must use frameless 正脸立绘")
	var level_list: Node = main.current_scene.find_child("LevelList", true, false)
	_expect(level_list != null, "map level list must be scrollable")
	var map_level_scroll := main.current_scene.find_child("LevelScroll", true, false) as ScrollContainer
	_expect(map_level_scroll != null and map_level_scroll.scroll_deadzone <= 16, "map drag recognition must stay responsive on mobile")
	_expect(level_list.get_child_count() >= 10, "map must render ten chapter cards before sub-level cards")
	var first_chapter: Node = level_list.get_child(0)
	_expect(first_chapter is TextureButton, "map chapters must use styled texture buttons")
	_expect((first_chapter as TextureButton).mouse_filter == Control.MOUSE_FILTER_PASS, "chapter card surfaces must pass drag gestures to the map scroll container")
	_expect((first_chapter as TextureButton).get_signal_connection_list("pressed").is_empty(), "chapter entry must only be bound to its explicit button, not the full card surface")
	_expect(first_chapter.find_child("ChapterStory", true, false) != null, "map chapter cards must show authored chapter story")
	_expect(first_chapter.find_child("SmallBossNode", true, false) != null, "map chapter cards must mark the level-5 small boss")
	_expect(first_chapter.find_child("MajorBossNode", true, false) != null, "map chapter cards must mark the level-10 major boss")
	var enter_chapter_button := first_chapter.find_child("EnterChapterButton", true, false) as TextureButton
	_expect(enter_chapter_button != null, "map chapter cards must expose an explicit chapter entry button")
	_expect(enter_chapter_button.size.x >= 280.0 and enter_chapter_button.size.y >= 80.0, "chapter Continue/Review entry must use the enlarged primary-action ruler")
	_expect(enter_chapter_button.position.y + enter_chapter_button.size.y <= first_chapter.size.y - 10.0, "enlarged chapter action must retain a protected bottom edge")
	var enter_chapter_label := enter_chapter_button.find_child("ActionLabel", false, false) as Label
	_expect(enter_chapter_label != null and enter_chapter_label.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "chapter primary-action copy must stay vertically centered inside the taller button")
	_expect(enter_chapter_button.mouse_filter == Control.MOUSE_FILTER_PASS and bool(enter_chapter_button.get_meta("scroll_drag_passthrough", false)), "chapter entry button must preserve drag-to-scroll gestures")
	var enter_chapter_touch_target := enter_chapter_button.find_child("TouchTarget", false, false) as Button
	_expect(enter_chapter_touch_target == null or enter_chapter_touch_target.mouse_filter == Control.MOUSE_FILTER_PASS, "expanded chapter touch target must not swallow drag-to-scroll gestures")
	main.current_scene._open_chapter(1)
	await process_frame
	level_list = main.current_scene.find_child("LevelList", true, false)
	_expect(level_list != null and level_list.get_child_count() >= 11, "chapter detail must render a header plus its ten sub-level cards")
	var back_to_chapter_map := level_list.get_child(0).find_child("BackToChapterMapButton", true, false) as TextureButton
	_expect(back_to_chapter_map != null, "chapter detail must expose a back-to-chapter-map button")
	_expect(back_to_chapter_map.size.x >= 280.0 and back_to_chapter_map.size.y >= 80.0, "Back to Zone Map must share the enlarged primary-navigation ruler")
	_expect(back_to_chapter_map.position.y >= 172.0 and back_to_chapter_map.position.y + back_to_chapter_map.size.y <= level_list.get_child(0).size.y - 56.0, "Back to Zone Map must keep clear separation from progress and the chapter-card bottom edge")
	var back_to_chapter_label := back_to_chapter_map.find_child("ActionLabel", false, false) as Label
	_expect(back_to_chapter_label != null and back_to_chapter_label.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "Back to Zone Map copy must stay vertically centered inside the enlarged button")
	_expect(back_to_chapter_map.mouse_filter == Control.MOUSE_FILTER_PASS and bool(back_to_chapter_map.get_meta("scroll_drag_passthrough", false)), "back-to-chapter-map button must preserve drag-to-scroll gestures")
	var back_touch_target := back_to_chapter_map.find_child("TouchTarget", false, false) as Button
	_expect(back_touch_target == null or back_touch_target.mouse_filter == Control.MOUSE_FILTER_PASS, "expanded back-button touch target must not swallow drag-to-scroll gestures")
	var first_level: Node = level_list.get_child(1)
	_expect(first_level is TextureButton, "chapter levels must use styled texture buttons")
	_expect((first_level.get_child(0) as Label).text == "001 城市缺口", "chapter detail must show three-digit level number and display name")
	var first_normal := first_level.find_child("NormalModeButton", true, false) as Button
	var first_challenge := first_level.find_child("ChallengeModeButton", true, false) as Button
	_expect(first_normal != null, "chapter level cards must expose Normal itself as the direct entry button")
	_expect(first_challenge == null, "unplayed normal levels must hide Challenge instead of reserving a dead button")
	_expect(first_level.find_child("EnterLevelButton", true, false) == null, "chapter level cards must not retain a redundant Enter button")
	_expect(first_level.find_child("ChallengeLevelButton", true, false) == null, "chapter level cards must not retain a redundant Challenge Mode button")
	_expect(str(first_normal.get_meta("level_mode", "")) == "normal", "normal entry button must carry an explicit mode identity")
	_expect(first_normal.mouse_filter == Control.MOUSE_FILTER_PASS and bool(first_normal.get_meta("scroll_drag_passthrough", false)), "single Normal button must preserve drag-to-scroll gestures")
	_expect(first_normal.find_child("ModeStars", true, false) != null, "single Normal button must carry its own three-star progress")
	_expect(first_normal.size.y >= 150.0 and first_normal.size.x >= 280.0, "single Normal button must be a large centered touch target")
	_expect(absf(first_normal.get_rect().get_center().x - 751.0) <= 1.0, "single Normal button must be horizontally centered in the action lane")
	_expect(str(first_normal.get_meta("mode_layout", "")) == "single", "unplayed Normal button must declare the single-button layout")
	var first_mode_label := first_normal.find_child("ModeLabel", true, false) as Label
	_expect(first_mode_label != null and first_mode_label.text == "闯关", "single entry must use the standalone action label 闯关 instead of an unpaired 普通")
	_expect(not first_normal.disabled, "unplayed but unlocked normal level must allow entering normal mode")
	main.current_scene._open_challenge_level("level_001")
	await process_frame
	_expect(main.current_scene.name == "Map", "challenge route guard must block levels without normal 3-star clear")
	var second_level: Node = level_list.get_child(2)
	var second_normal := second_level.find_child("NormalModeButton", true, false) as Button
	var second_challenge := second_level.find_child("ChallengeModeButton", true, false) as Button
	_expect(second_normal != null and not second_normal.disabled, "cleared 2-star normal level must still allow normal re-entry")
	_expect(second_challenge != null and second_challenge.disabled, "2-star normal clear must not unlock challenge mode")
	_expect(str(second_normal.get_meta("mode_layout", "")) == "dual" and str(second_challenge.get_meta("mode_layout", "")) == "dual", "cleared levels must use the paired mode-button layout")
	var second_normal_label := second_normal.find_child("ModeLabel", true, false) as Label
	var second_challenge_label := second_challenge.find_child("ModeLabel", true, false) as Label
	_expect(second_normal_label != null and second_normal_label.text == "普通", "paired normal entry must keep the comparative label 普通")
	_expect(second_challenge_label != null and second_challenge_label.text == "挑战", "paired challenge entry must keep the comparative label 挑战")
	_expect(second_normal.size.y >= 150.0 and second_challenge.size.y >= 150.0, "paired mode buttons must provide large touch targets")
	_expect(second_normal.position.x + second_normal.size.x <= second_challenge.position.x, "paired normal and challenge hit regions must never overlap")
	_expect(absf(second_normal.position.y - second_challenge.position.y) <= 0.1, "paired mode buttons must align on the same row")
	_expect(second_normal.find_child("ModeStars", true, false) != null and second_challenge.find_child("ModeStars", true, false) != null, "paired mode buttons must carry stacked three-star progress")
	_expect(second_challenge.find_child("UnlockRequirement", true, false) != null, "visible but locked challenge mode must show an in-button unlock marker")
	second_challenge.emit_signal("pressed")
	await process_frame
	_expect(main.current_scene.name == "Map", "disabled challenge button must not route to loadout when pressed")
	var third_level: Node = level_list.get_child(3)
	var third_normal := third_level.find_child("NormalModeButton", true, false) as Button
	var third_challenge := third_level.find_child("ChallengeModeButton", true, false) as Button
	_expect(third_normal != null and not third_normal.disabled, "3-star normal level must allow normal re-entry")
	_expect(third_challenge != null and not third_challenge.disabled, "3-star normal clear must unlock challenge mode")
	_expect(third_challenge.find_child("UnlockRequirement", true, false) == null, "unlocked challenge mode must remove the lock marker")
	var late_map_save: Dictionary = save_manager._default_save()
	var late_map_progress := {}
	var late_map_levels: Array[String] = []
	for level_number in range(1, 90):
		var late_level_id := "level_%03d" % level_number
		late_map_levels.append(late_level_id)
		if level_number < 89:
			late_map_progress[late_level_id] = 1
	late_map_save["levels_progress"] = late_map_progress
	var late_map_unlocks: Dictionary = late_map_save.get("unlocks", {}).duplicate(true)
	late_map_unlocks["levels"] = late_map_levels
	late_map_save["unlocks"] = late_map_unlocks
	save_manager.save_data = late_map_save
	main.change_scene("map")
	for i in range(4):
		await process_frame
	var late_map_scroll := main.current_scene.find_child("LevelScroll", true, false) as ScrollContainer
	var current_chapter_card := main.current_scene.find_child("Chapter09Card", true, false) as Control
	_expect(late_map_scroll.scroll_vertical > 0, "late campaign map must scroll to the current chapter instead of reopening at chapter one")
	_expect(current_chapter_card != null, "late campaign map must keep the current chapter card")
	var chapter_view := late_map_scroll.get_global_rect()
	var chapter_rect := current_chapter_card.get_global_rect()
	_expect(chapter_rect.position.y >= chapter_view.position.y - 1.0 and chapter_rect.end.y <= chapter_view.end.y + 1.0, "current chapter card must be fully visible after automatic map focus")
	main.current_scene._open_chapter(9)
	for i in range(4):
		await process_frame
	late_map_scroll = main.current_scene.find_child("LevelScroll", true, false) as ScrollContainer
	var current_level_card := main.current_scene.find_child("level_089", true, false) as Control
	_expect(late_map_scroll.scroll_vertical > 0, "late chapter must scroll to the current level instead of reopening at its first mission")
	_expect(current_level_card != null, "chapter detail must name level cards for deterministic focus restoration")
	var level_view := late_map_scroll.get_global_rect()
	var level_rect := current_level_card.get_global_rect()
	_expect(level_rect.position.y >= level_view.position.y - 1.0 and level_rect.end.y <= level_view.end.y + 1.0, "current level card must be fully visible after automatic chapter focus")
	main.current_scene._back_to_chapter_map()
	for i in range(4):
		await process_frame
	late_map_scroll = main.current_scene.find_child("LevelScroll", true, false) as ScrollContainer
	current_chapter_card = main.current_scene.find_child("Chapter09Card", true, false) as Control
	chapter_view = late_map_scroll.get_global_rect()
	chapter_rect = current_chapter_card.get_global_rect()
	_expect(chapter_rect.position.y >= chapter_view.position.y - 1.0 and chapter_rect.end.y <= chapter_view.end.y + 1.0, "returning from a chapter must restore the chapter card the player just left")
	save_manager.save_data = map_gate_save
	main.change_scene("collection", {"mode": "characters"})
	await process_frame
	_expect(main.current_scene.name == "Collection", "main must route to character collection")
	var character_item: Node = main.current_scene.find_child("ItemList", true, false).get_child(0)
	_expect(character_item is TextureButton, "character collection rows must use styled texture buttons")
	_expect((character_item as Control).size_flags_horizontal == Control.SIZE_SHRINK_CENTER, "character collection rows must center their fixed-width artwork inside the safe-area list")
	_expect((character_item as Control).clip_contents, "character collection rows must own the final portrait safety clip")
	_expect((character_item as Control).custom_minimum_size.x >= 860.0 and (character_item as Control).custom_minimum_size.y >= 330.0, "character collection rows must dedicate the wide authored card to the enlarged hero presentation")
	_expect(character_item.has_node("Icon"), "character collection rows must render a bounded portrait")
	var character_icon := character_item.get_node("Icon") as TextureRect
	_expect(character_icon != null, "character collection portrait must be a TextureRect")
	_expect(character_icon.position == Vector2(24.0, 10.0) and character_icon.size == Vector2(320.0, 310.0), "character collection portrait lane must use the enlarged knee-crop envelope, got %s at %s" % [str(character_icon.size), str(character_icon.position)])
	_expect(character_icon.clip_contents, "character collection portrait lane must crop lower legs without leaking into neighbouring copy")
	var character_bust := character_icon.get_node_or_null("BustImage") as TextureRect
	_expect(character_bust != null and character_bust.texture != null, "character collection portrait must render a bust image")
	_expect(str(character_bust.texture.resource_path).ends_with("_portrait_frameless.png"), "character collection portrait must use frameless 正脸立绘")
	_expect(character_bust.has_meta("aligned_visible_rect") and character_bust.has_meta("aligned_crop_rect"), "character collection portrait must expose its normalized subject and knee-crop envelopes")
	var character_visible_rect: Rect2 = character_bust.get_meta("aligned_visible_rect", Rect2())
	var character_crop_rect: Rect2 = character_bust.get_meta("aligned_crop_rect", Rect2())
	_expect(absf(character_visible_rect.size.y - 465.0) <= 0.1 and absf(character_visible_rect.position.y - 6.0) <= 0.1, "character collection portrait must normalize subject scale and headline, got %s" % str(character_visible_rect))
	_expect(character_visible_rect.end.y > character_icon.size.y + 120.0, "character collection portrait must intentionally crop the lower body instead of shrinking to show complete feet")
	_expect(character_crop_rect.position.y <= 6.1 and character_crop_rect.end.y <= character_icon.size.y + 0.1 and character_crop_rect.size.y >= 300.0, "character collection portrait must preserve a head-to-knee visible crop")
	_expect(absf(character_bust.position.x + character_bust.size.x * 0.5 - character_icon.size.x * 0.5) <= 0.1, "character collection portrait must align the authored canvas centerline")
	_expect(character_bust.expand_mode == TextureRect.EXPAND_IGNORE_SIZE, "character collection portrait must use its assigned rect instead of the texture's natural size")
	for text_node_name in ["Title", "Tags", "Description"]:
		var character_text_node := character_item.get_node_or_null(text_node_name) as Control
		_expect(character_text_node != null and character_text_node.position.x >= character_icon.position.x + character_icon.size.x + 24.0, "character collection %s must start to the right of the enlarged portrait lane" % text_node_name)
	var character_rows: Array[Node] = main.current_scene.find_child("ItemList", true, false).get_children()
	var aligned_character_count := 0
	for character_row in character_rows:
		var row_icon := character_row.get_node_or_null("Icon") as TextureRect
		var row_bust := row_icon.get_node_or_null("BustImage") as TextureRect if row_icon != null else null
		if row_bust == null or not row_bust.has_meta("aligned_visible_rect"):
			continue
		var row_visible_rect: Rect2 = row_bust.get_meta("aligned_visible_rect")
		var row_crop_rect: Rect2 = row_bust.get_meta("aligned_crop_rect")
		_expect(absf(row_visible_rect.size.y - character_visible_rect.size.y) <= 0.1, "all character collection portraits must share one visible height")
		_expect(absf(row_visible_rect.position.y - character_visible_rect.position.y) <= 0.1, "all character collection portraits must share one headline")
		_expect(absf(row_crop_rect.size.y - character_crop_rect.size.y) <= 0.1, "all character collection portraits must share one head-to-knee crop height")
		_expect(absf(row_bust.position.x + row_bust.size.x * 0.5 - character_icon.size.x * 0.5) <= 0.1, "all character collection portraits must share one authored canvas centerline")
		aligned_character_count += 1
	_expect(aligned_character_count == 4, "character collection must align all four hero portraits, got %d" % aligned_character_count)
	var character_action := character_item.find_child("CardActionButton", true, false) as TextureButton
	var character_action_label := character_action.get_node_or_null("ActionLabel") as Label if character_action != null else null
	_expect(character_action_label != null and character_action_label.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "character collection action text must use vertical centering")
	_expect(character_action_label != null and absf(character_action_label.offset_top + 4.0) <= 0.1 and absf(character_action_label.offset_bottom + 4.0) <= 0.1, "character collection action text must apply the Glow Sans optical centering correction")
	character_item.emit_signal("pressed")
	await process_frame
	_expect(main.current_scene.has_node("CharacterDetail"), "character row click must open character detail")
	var character_detail: Node = main.current_scene.get_node("CharacterDetail")
	_expect((character_detail as Control).z_index >= 64, "character detail must render above positive-z collection row children")
	var character_detail_panel := character_detail.get_node("Panel") as PanelContainer
	var character_detail_style := character_detail_panel.get_theme_stylebox("panel") as StyleBoxTexture
	_expect(character_detail_style != null and character_detail_style.texture != null and character_detail_style.texture.resource_path.ends_with("ui_detail_panel_clear.png"), "character detail must use the authored rule-free texture surface")
	var collection_scroll := main.current_scene.find_child("ItemScroll", true, false) as ScrollContainer
	var hidden_collection_back := main.current_scene.find_child("BackButton", true, false) as TextureButton
	_expect(collection_scroll != null and not collection_scroll.visible, "character detail must hide the underlying collection list so row text cannot bleed through translucent artwork")
	_expect(hidden_collection_back != null and not hidden_collection_back.visible, "character detail must hide the underlying back action")
	var detail_portrait := character_detail.find_child("PortraitClip", true, false) as TextureRect
	var detail_bust := detail_portrait.get_node_or_null("BustImage") as TextureRect if detail_portrait != null else null
	_expect(detail_bust != null and detail_bust.position.y >= -12.0, "character detail portrait must preserve headroom")
	var character_close := character_detail.find_child("CloseButton", true, false) as Button
	_expect(character_close != null, "character detail top close must be a compact button")
	_expect(character_close.text == "×", "character detail top close must use an icon-only x")
	_expect(character_close.custom_minimum_size.x >= UiKit.CLOSE_BUTTON_MIN_SIZE.x and character_close.custom_minimum_size.y >= UiKit.CLOSE_BUTTON_MIN_SIZE.y, "character detail top close must keep the larger modal-close target")
	_expect(character_close.get_theme_font_size("font_size") >= UiKit.CLOSE_GLYPH_FONT_SIZE, "character detail top close glyph must remain visually prominent")
	var affinity_summary := character_detail.find_child("AffinitySummary", true, false) as Label
	_expect(affinity_summary != null and affinity_summary.get_theme_font_size("font_size") >= 27, "character detail affinity summary must use the second-pass mobile-readable type")
	var character_name := character_detail.find_child("CharacterName", true, false) as Label
	var character_level := character_detail.find_child("CharacterLevel", true, false) as Label
	_expect(character_name != null and character_name.get_theme_font_size("font_size") >= 50, "character detail hero name must use at least 50px effective type")
	_expect(character_level != null and character_level.get_theme_font_size("font_size") >= 28, "character detail level badge must use at least 28px effective type")
	var detail_section_titles := character_detail.find_children("SectionTitle", "Label", true, false)
	_expect(detail_section_titles.size() >= 5, "character detail must expose every section title to the readability audit")
	for section_title_node in detail_section_titles:
		var section_title := section_title_node as Label
		_expect(section_title != null and section_title.get_theme_font_size("font_size") >= 29, "character detail section titles must use at least 29px effective type")
	for character_tag_name in ["CharacterRoleTag", "CharacterElementTag"]:
		var character_tag := character_detail.find_child(character_tag_name, true, false) as PanelContainer
		_expect(character_tag != null, "character detail must expose the %s semantic tag" % character_tag_name)
		if character_tag != null:
			_assert_semantic_tag_panel(character_tag, "character detail %s" % character_tag_name)
			var character_tag_text := character_tag.get_node_or_null("Text") as Label
			_expect(character_tag_text != null and character_tag_text.get_theme_font_size("font_size") >= 24, "character detail semantic tags must use at least 24px effective type")
	var stat_labels := character_detail.find_children("StatLabel", "Label", true, false)
	var stat_values := character_detail.find_children("StatValue", "Label", true, false)
	_expect(not stat_labels.is_empty() and not stat_values.is_empty(), "character detail stat cards must expose primary labels and values")
	for stat_label_node in stat_labels:
		var stat_label := stat_label_node as Label
		_expect(stat_label != null and stat_label.get_theme_font_size("font_size") >= 24, "character detail stat labels must use at least 24px effective type")
	for stat_value_node in stat_values:
		var stat_value := stat_value_node as Label
		_expect(stat_value != null and stat_value.get_theme_font_size("font_size") >= 32, "character detail stat values must use at least 32px effective type")
	var stat_sub_labels := character_detail.find_children("StatSub", "Label", true, false)
	_expect(not stat_sub_labels.is_empty(), "character detail stat cards must expose readable secondary values")
	for stat_sub_node in stat_sub_labels:
		var stat_sub := stat_sub_node as Label
		_expect(stat_sub != null and stat_sub.get_theme_font_size("font_size") >= 22, "character detail stat secondary values must use at least 22px effective type")
	var skill_titles := character_detail.find_children("SkillTitle", "Label", true, false)
	var skill_kinds := character_detail.find_children("SkillKind", "Label", true, false)
	_expect(skill_titles.size() >= 2 and skill_kinds.size() >= 2, "character detail must expose mobile-readable skill names and kinds")
	var skill_icon_frames := character_detail.find_children("SkillIconFrame", "PanelContainer", true, false)
	var skill_icons := character_detail.find_children("SkillIcon", "TextureRect", true, false)
	var skill_leading_insets := character_detail.find_children("SkillLeadingInset", "Control", true, false)
	_expect(skill_icon_frames.size() >= 2 and skill_icons.size() == skill_icon_frames.size(), "character detail passive and signature rows must all use the shared large-icon component (frames=%d icons=%d)" % [skill_icon_frames.size(), skill_icons.size()])
	_expect(skill_leading_insets.size() == skill_icon_frames.size(), "character detail skill rows must all reserve a left safe inset")
	for skill_leading_inset_node in skill_leading_insets:
		var skill_leading_inset := skill_leading_inset_node as Control
		_expect(skill_leading_inset != null and skill_leading_inset.custom_minimum_size.x >= 12.0, "character detail skill icons must stay clear of the left ornamental rail")
	for skill_icon_frame_node in skill_icon_frames:
		var skill_row := skill_icon_frame_node.get_parent() as HBoxContainer
		_expect(skill_row != null and skill_row.custom_minimum_size.y >= 168.0, "character detail skill rows must reserve the enlarged icon height")
		_expect(skill_row != null and skill_row.get_theme_constant("separation") >= 22, "character detail skill rows must retain a clear icon-to-copy gap")
		var skill_icon_frame := skill_icon_frame_node as PanelContainer
		_expect(skill_icon_frame != null and skill_icon_frame.custom_minimum_size.x >= 148.0 and skill_icon_frame.custom_minimum_size.y >= 148.0, "character detail skill icon frames must use the enlarged 148px square ruler")
		_expect(skill_icon_frame != null and skill_icon_frame.size_flags_vertical == Control.SIZE_SHRINK_CENTER, "character detail skill icon frames must remain square instead of stretching with the text row")
	for skill_icon_node in skill_icons:
		var skill_icon := skill_icon_node as TextureRect
		_expect(skill_icon != null and skill_icon.custom_minimum_size.x >= 128.0 and skill_icon.custom_minimum_size.y >= 128.0, "character detail skill artwork must use the enlarged 128px ruler")
		_expect(skill_icon != null and skill_icon.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "character detail skill artwork must remain aspect-preserving and centered")
	for skill_title_node in skill_titles:
		var skill_title := skill_title_node as Label
		_expect(skill_title != null and skill_title.get_theme_font_size("font_size") >= 30, "character detail skill names must use at least 30px effective type")
	for skill_kind_node in skill_kinds:
		var skill_kind := skill_kind_node as Label
		_expect(skill_kind != null and skill_kind.get_theme_font_size("font_size") >= 24, "character detail skill kinds must use at least 24px effective type")
	var skill_descriptions := character_detail.find_children("SkillDescription", "Label", true, false)
	_expect(skill_descriptions.size() >= 2, "character detail must expose passive and signature descriptions")
	for description_node in skill_descriptions:
		var skill_description := description_node as Label
		_expect(skill_description != null and skill_description.get_theme_font_size("font_size") >= 26, "character detail skill descriptions must use at least 26px effective type")
		if skill_description != null:
			_expect(_label_required_height_for_smoke(skill_description) <= skill_description.size.y + 0.5, "character detail skill descriptions must expand for wrapped copy without covering the next row")
	var signature_layout := character_detail.find_child("SignatureUpgradeLayout", true, false) as VBoxContainer
	var signature_growth := character_detail.find_child("SignatureGrowth", true, false) as Label
	var signature_button := character_detail.find_child("SigSkillUpgradeButton", true, false) as TextureButton
	_expect(signature_layout != null and signature_growth != null and signature_button != null, "character detail signature upgrade must use the dedicated full-width readability layout")
	_assert_resource_cost(signature_button, "xp", save_manager.get_sig_skill_upgrade_cost("vanguard"), "signature skill upgrade")
	_expect(signature_growth.get_theme_font_size("font_size") >= 23, "signature growth copy must use at least 23px effective type")
	_expect(signature_growth.size.x > signature_button.size.x * 2.0, "signature growth copy must own the full card width below the upgrade button")
	var character_upgrade_button := character_detail.find_child("UpgradeButton", true, false) as TextureButton
	_assert_resource_cost(character_upgrade_button, "gold", save_manager.get_item_upgrade_cost("characters", "vanguard"), "character upgrade")
	main.current_scene._close_character_detail()
	await process_frame
	var collection_back := main.current_scene.find_child("BackButton", true, false) as TextureButton
	_expect(collection_back != null, "collection must expose a context-aware back button")
	_expect(collection_scroll.visible and collection_back.visible, "closing character detail must restore collection list and back action")
	var collection_back_label := collection_back.get_node("Label") as Label
	_expect(collection_back_label.text == "返回地图", "collection opened from map must return to map")
	_expect(collection_back_label.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "collection back text must use vertical centering")
	_expect(absf(collection_back_label.offset_top + 4.0) <= 0.1 and absf(collection_back_label.offset_bottom + 4.0) <= 0.1, "collection back text must share the Glow Sans optical centering correction")
	collection_back.emit_signal("pressed")
	await process_frame
	_expect(main.current_scene.name == "Map", "collection opened from map must route back to map")
	var skill_level_test_save: Dictionary = save_manager.save_data.duplicate(true)
	var skill_level_test_levels: Dictionary = skill_level_test_save.get("skill_base_levels", {}).duplicate(true)
	skill_level_test_levels["skill_split_shot"] = 4
	skill_level_test_levels["skill_pierce"] = 2
	skill_level_test_levels["skill_multishot"] = 0
	skill_level_test_save["skill_base_levels"] = skill_level_test_levels
	save_manager.save_data = skill_level_test_save
	main.change_scene("collection", {"mode": "skills"})
	await process_frame
	_expect(main.current_scene.name == "Collection", "main must route to skill collection")
	var skill_list: Node = main.current_scene.find_child("ItemList", true, false)
	_expect(skill_list != null and skill_list.get_child_count() >= 16, "skill collection must render the skill codex")
	var skill_item: Node = skill_list.get_child(0)
	_expect(skill_item is TextureButton, "skill collection rows must use clickable texture buttons")
	_expect((skill_item as Control).size_flags_horizontal == Control.SIZE_SHRINK_CENTER, "skill collection rows must center their fixed-width artwork inside the safe-area list")
	_expect(skill_item.has_node("SkillCard"), "skill collection rows must use one full-width visual card")
	_expect(not skill_item.has_node("Frame"), "skill collection rows must not render the old nested inner frame")
	var skill_card := skill_item.get_node("SkillCard") as PanelContainer
	_expect(skill_card != null and skill_card.size.x >= 720.0, "skill collection card must span the row without a disconnected right panel")
	_expect(skill_item.has_node("InfoButton"), "skill collection card must expose a dedicated accessible detail control")
	var skill_list_icon_frame := skill_item.get_node_or_null("IconFrame") as PanelContainer
	var skill_list_icon := skill_list_icon_frame.get_node_or_null("Icon") as TextureRect if skill_list_icon_frame != null else null
	var skill_title := skill_item.get_node("Title") as Label
	_expect(skill_item.size.x >= 896.0 and skill_item.size.y >= 256.0, "skill collection rows must consume the catalog safe width beside the scrollbar")
	_expect(skill_list_icon_frame != null and skill_list_icon_frame.position.x >= 32.0 and skill_list_icon_frame.size.x >= 204.0, "skill collection icon frame must use the shared 204px catalog geometry")
	_expect(skill_list_icon != null and skill_list_icon.size.x >= 184.0 and skill_list_icon.size.y >= 184.0, "skill collection artwork must fill the enlarged shared icon frame")
	_expect(skill_title.position.x >= 272.0, "skill collection copy must use the shared right-shifted catalog text axis")
	_expect(skill_title.position.x - (skill_list_icon_frame.position.x + skill_list_icon_frame.size.x) >= 30.0, "skill collection copy must share the equipment list text axis after the enlarged icon")
	_expect(skill_title.text.find("等级4") >= 0, "upgraded skill collection row must show its actual permanent level, got %s" % skill_title.text)
	var skill_tags := skill_item.get_node("Tags") as HBoxContainer
	_expect(skill_tags != null and skill_tags.get_child_count() >= 3, "skill collection rows must render a kind tag plus semantic ability tags")
	# Labels report a font-driven minimum control height that is larger than the
	# visible glyph bounds. Lock the authored baseline here; the routed screenshot
	# audit is the source of truth for visual overlap.
	_expect(skill_tags.position.y >= 76.0, "skill tags must keep the authored baseline below the title")
	var tag_width_total := 0.0
	for tag_index in range(skill_tags.get_child_count()):
		var tag_panel := skill_tags.get_child(tag_index) as PanelContainer
		_expect(tag_panel != null, "skill tags must use the dedicated bordered panel component")
		if tag_panel == null:
			continue
		var tag_style := tag_panel.get_theme_stylebox("panel") as StyleBoxTexture
		_expect(
			tag_style != null
			and tag_style.texture != null
			and tag_style.texture.resource_path.ends_with("ui_semantic_tag_microframe_v2.png")
			and tag_style.texture_margin_left >= 16.0
			and tag_style.texture_margin_top >= 16.0,
			"skill tags must keep the dedicated continuous texture-backed border"
		)
		_expect(tag_panel.custom_minimum_size.y >= 40.0, "skill tags must share a stable mobile-height baseline")
		_expect(tag_panel.has_meta("semantic_tag_role"), "skill tags must declare their semantic color role")
		var tag_text := tag_panel.get_node("Text") as Label
		_expect(tag_text != null and tag_text.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "skill tag copy must be vertically centered")
		tag_width_total += tag_panel.size.x
	if skill_tags.get_child_count() > 1:
		tag_width_total += float(skill_tags.get_theme_constant("separation")) * float(skill_tags.get_child_count() - 1)
	_expect(tag_width_total <= skill_tags.size.x + 0.5, "skill tags must fit inside the authored card width without clipping")
	var skill_effect_summary := skill_item.get_node("EffectSummary") as Label
	_expect(skill_effect_summary.position.y >= skill_tags.position.y + skill_tags.size.y + 6.0, "skill effect summary must keep a clean gap below the tag row")
	_expect(_label_required_height_for_smoke(skill_effect_summary) <= skill_effect_summary.size.y + 0.5, "skill collection effect summary must reserve every wrapped line")
	var theme_manager := root.get_node("/root/ThemeManager")
	var tag_border_signatures: Dictionary = {}
	for theme_id in ["default", "neon_tempest", "infernal_dominion", "polar_aurora", "gilded_eclipse"]:
		var tag_palette: Dictionary = theme_manager.tag_palette_for_theme(theme_id)
		for color_key in ["border", "kind_border", "fill", "kind_fill", "text", "kind_text"]:
			_expect(tag_palette.get(color_key) is Color and (tag_palette[color_key] as Color).a >= 0.95, "%s tag palette must provide an opaque %s color" % [theme_id, color_key])
		var border_color: Color = tag_palette.get("border", Color.TRANSPARENT)
		tag_border_signatures[border_color.to_html()] = true
	_expect(tag_border_signatures.size() == 5, "all five themes must provide visibly distinct semantic tag borders")
	var checked_skill_tag_rows := 0
	for skill_row_index in range(skill_list.get_child_count()):
		var skill_row := skill_list.get_child(skill_row_index)
		if not skill_row is TextureButton or not skill_row.has_node("Tags"):
			continue
		checked_skill_tag_rows += 1
		var row_tags := skill_row.get_node_or_null("Tags") as HBoxContainer
		var row_effect_summary := skill_row.get_node_or_null("EffectSummary") as Label
		_expect(row_tags != null and row_tags.get_child_count() >= 2, "every skill row must keep its bilingual semantic tags")
		_expect(row_effect_summary != null and _label_required_height_for_smoke(row_effect_summary) <= row_effect_summary.size.y + 0.5, "skill row %d effect summary must fit without covering adjacent content" % skill_row_index)
		if row_tags == null:
			continue
		var row_tag_width := 0.0
		for row_tag_index in range(row_tags.get_child_count()):
			var row_tag := row_tags.get_child(row_tag_index) as PanelContainer
			if row_tag != null:
				row_tag_width += row_tag.size.x
				var row_tag_text := row_tag.get_node_or_null("Text") as Label
				_expect(row_tag_text != null and row_tag_text.get_minimum_size().x <= row_tag.size.x, "skill row %d tag copy must fit its border" % skill_row_index)
		if row_tags.get_child_count() > 1:
			row_tag_width += float(row_tags.get_theme_constant("separation")) * float(row_tags.get_child_count() - 1)
		_expect(row_tag_width <= row_tags.size.x + 0.5, "skill row %d bilingual tags must fit the authored card width" % skill_row_index)
	_expect(checked_skill_tag_rows == 16, "semantic tag regression must inspect all 16 authored skill rows")
	var second_skill_item := skill_list.get_child(1)
	var second_skill_title := second_skill_item.get_node("Title") as Label
	_expect(second_skill_title.text.find("等级2") >= 0, "second upgraded skill row must show level 2, got %s" % second_skill_title.text)
	var third_skill_item := skill_list.get_child(2)
	var third_skill_title := third_skill_item.get_node("Title") as Label
	_expect(third_skill_title.text.find("等级0") >= 0, "unupgraded skill row must show level 0, got %s" % third_skill_title.text)
	skill_item.emit_signal("pressed")
	await process_frame
	_expect(main.current_scene.has_node("ItemDetail"), "skill collection row click must open skill detail")
	var skill_detail: Node = main.current_scene.get_node("ItemDetail")
	_expect((skill_detail as Control).z_index >= 64, "item detail must render above positive-z collection row children")
	_expect(not (main.current_scene.find_child("ItemScroll", true, false) as ScrollContainer).visible, "item detail must hide the underlying collection list")
	var skill_detail_panel := skill_detail.get_node("Panel") as PanelContainer
	var skill_detail_style := skill_detail_panel.get_theme_stylebox("panel") as StyleBoxTexture
	_expect(
		skill_detail_style != null
		and skill_detail_style.texture != null
		and skill_detail_style.texture.resource_path.ends_with("ui_detail_panel_clear.png"),
		"skill detail must use the authored rule-free texture surface"
	)
	var skill_close := skill_detail.find_child("CloseButton", true, false) as Button
	_expect(skill_close != null, "skill detail top close must be a compact button")
	_expect(skill_close.text == "×", "skill detail top close must use an icon-only x")
	_expect(skill_close.custom_minimum_size.x >= UiKit.CLOSE_BUTTON_MIN_SIZE.x and skill_close.custom_minimum_size.y >= UiKit.CLOSE_BUTTON_MIN_SIZE.y, "skill detail top close must keep the larger modal-close target")
	_expect(skill_close.get_theme_font_size("font_size") >= UiKit.CLOSE_GLYPH_FONT_SIZE, "skill detail top close glyph must remain visually prominent")
	var skill_level_one := skill_detail.find_child("SkillLevel1", true, false) as PanelContainer
	_expect(skill_level_one != null, "skill detail must render a named first-level readability row")
	var skill_level_label := skill_level_one.find_child("Level", true, false) as Label
	var skill_effect_label := skill_level_one.find_child("Effect", true, false) as Label
	_expect(skill_level_label.get_theme_font_size("font_size") == UiKit.bumped_font_size(22), "skill detail level labels must use the larger mobile size")
	_expect(skill_effect_label.get_theme_font_size("font_size") == UiKit.bumped_font_size(21), "skill detail effect values must use the larger mobile size")
	_expect(skill_level_one.custom_minimum_size.y >= 64.0, "larger skill detail copy must retain comfortable row height")
	var skill_description := skill_detail.find_child("DescriptionBody", true, false) as Label
	_expect(skill_description != null and skill_description.get_theme_font_size("font_size") == UiKit.scaled_font_size(22), "skill tactical notes must use the larger mobile body size")
	var skill_upgrade_button := skill_detail.find_child("SkillUpgradeButton", true, false) as TextureButton
	var expected_skill_cost: int = int(save_manager.get_skill_base_upgrade_cost("skill_split_shot"))
	_assert_resource_cost(skill_upgrade_button, "xp", expected_skill_cost, "generic skill upgrade")
	var skill_cost_action := skill_upgrade_button.find_child("CostAction", true, false) as Label
	_expect(skill_cost_action != null and not skill_cost_action.text.contains("经验") and not skill_cost_action.text.contains("★"), "skill action copy must leave resource identity to the XP icon")
	skill_close.emit_signal("pressed")
	await process_frame
	_expect(not main.current_scene.has_node("ItemDetail"), "skill detail compact close must dismiss the modal")
	collection_back = main.current_scene.find_child("BackButton", true, false) as TextureButton
	collection_back.emit_signal("pressed")
	await process_frame
	_expect(main.current_scene.name == "Map", "skill collection opened from map must route back to map")
	# Every categorical collection uses the Skill Codex semantic-tag contract and
	# one bilingual vertical rhythm. Inspect both owned and locked rows across
	# every equipment family so changing language cannot reopen the former large
	# English title gap / cramped Chinese title gap.
	var semantic_catalog_save: Dictionary = save_manager._default_save()
	save_manager.save_data = semantic_catalog_save
	var semantic_localization_manager := root.get_node("/root/LocalizationManager")
	var semantic_language_before := str(semantic_localization_manager.current_language)
	var semantic_card_heights := {}
	for semantic_language in ["zh", "en"]:
		semantic_localization_manager.apply_language(semantic_language, false)
		var language_card_heights := {}
		for semantic_mode in ["characters", "weapons", "armors", "chips", "pets"]:
			main.change_scene("collection", {"mode": semantic_mode})
			await process_frame
			var semantic_list: Node = main.current_scene.find_child("ItemList", true, false)
			_expect(semantic_list != null, "%s %s collection must expose a semantic-tag list" % [semantic_language, semantic_mode])
			var semantic_rows_checked := 0
			var mode_card_height := 0.0
			for semantic_row_node in semantic_list.get_children():
				if not semantic_row_node is TextureButton:
					continue
				var semantic_row := semantic_row_node as TextureButton
				var semantic_title := semantic_row.get_node_or_null("Title") as Label
				var semantic_tags := semantic_row.get_node_or_null("Tags") as HBoxContainer
				var semantic_description := semantic_row.get_node_or_null("Description") as Label
				var semantic_action := semantic_row.get_node_or_null("CardActionButton") as TextureButton
				var semantic_icon := semantic_row.get_node_or_null("Icon") as TextureRect
				_expect(semantic_title != null and semantic_tags != null and semantic_description != null, "%s %s row must expose title/tag/description anchors" % [semantic_language, semantic_mode])
				var expected_tag_minimum := 1 if semantic_mode == "weapons" else 2
				_expect(semantic_tags != null and semantic_tags.get_child_count() >= expected_tag_minimum, "%s %s row must expose its available categorical tags without inventing empty values" % [semantic_language, semantic_mode])
				if semantic_title == null or semantic_tags == null or semantic_description == null:
					continue
				_expect(_label_required_height_for_smoke(semantic_description) <= semantic_description.size.y + 0.5, "%s %s description must reserve all wrapped lines" % [semantic_language, semantic_mode])
				var title_tag_gap := semantic_tags.position.y - (semantic_title.position.y + semantic_title.size.y)
				var tag_description_gap := semantic_description.position.y - (semantic_tags.position.y + semantic_tags.size.y)
				_expect(is_equal_approx(title_tag_gap, 8.0), "%s %s title-to-tag gap must stay at the shared 8px rhythm, got %.1f" % [semantic_language, semantic_mode, title_tag_gap])
				_expect(is_equal_approx(tag_description_gap, 6.0), "%s %s tag-to-description gap must stay at the shared 6px rhythm, got %.1f" % [semantic_language, semantic_mode, tag_description_gap])
				_expect(semantic_title.vertical_alignment == VERTICAL_ALIGNMENT_BOTTOM, "%s %s title glyphs must bottom-align against the fixed tag gap" % [semantic_language, semantic_mode])
				if semantic_mode in ["weapons", "armors", "chips", "pets"]:
					_expect(semantic_row.size.x >= 896.0, "%s %s row must consume the catalog safe width beside the scrollbar" % [semantic_language, semantic_mode])
					_expect(semantic_icon != null and semantic_icon.size.x >= 204.0 and semantic_icon.size.y >= 204.0, "%s %s icon must use the shared 204px catalog size" % [semantic_language, semantic_mode])
					_expect(semantic_icon != null and semantic_icon.position.x >= 32.0, "%s %s icon must retain its 16px inner-frame breathing room" % [semantic_language, semantic_mode])
					_expect(semantic_title.position.x >= 272.0 and semantic_tags.position.x == semantic_title.position.x and semantic_description.position.x == semantic_title.position.x, "%s %s copy must share one right-shifted text axis" % [semantic_language, semantic_mode])
					_expect(semantic_icon != null and semantic_title.position.x - (semantic_icon.position.x + semantic_icon.size.x) >= 30.0, "%s %s copy must clear the enlarged icon" % [semantic_language, semantic_mode])
				var semantic_tag_texts: Array[String] = []
				var weapon_ability_tag_count := 0
				for semantic_tag_node in semantic_tags.get_children():
					var semantic_tag := semantic_tag_node as PanelContainer
					_expect(semantic_tag != null, "%s %s row tags must use semantic PanelContainers" % [semantic_language, semantic_mode])
					if semantic_tag != null:
						_assert_semantic_tag_panel(semantic_tag, "%s %s collection row" % [semantic_language, semantic_mode])
						var semantic_tag_text := semantic_tag.get_node_or_null("Text") as Label
						var tag_copy := semantic_tag_text.text if semantic_tag_text != null else ""
						semantic_tag_texts.append(tag_copy)
						var tag_role := str(semantic_tag.get_meta("semantic_tag_role", ""))
						if semantic_mode in ["weapons", "armors", "chips", "pets"] and tag_role == "ability":
							_expect(tag_copy == "" or not semantic_description.text.contains(tag_copy), "%s %s %s must not repeat mechanism/stat tag '%s' in prose" % [semantic_language, semantic_mode, semantic_row.name, tag_copy])
						if semantic_mode in ["weapons", "armors", "pets"] and tag_role == "element":
							_expect(not semantic_description.text.contains("元素：") and not semantic_description.text.contains("Element:") and not semantic_description.text.contains("抗性：") and not semantic_description.text.contains("Resist:"), "%s %s %s must keep its element/resistance identity only in the tag row" % [semantic_language, semantic_mode, semantic_row.name])
						if semantic_mode == "weapons" and tag_role == "ability":
							weapon_ability_tag_count += 1
							_expect(not tag_copy.ends_with(" 0") and not tag_copy.ends_with(" 0°") and not tag_copy.ends_with("+0"), "%s weapon %s must suppress zero-value mechanism pills" % [semantic_language, semantic_row.name])
				if semantic_mode == "weapons":
					var expected_mechanism := ""
					match semantic_row.name:
						"weapon_autocannon":
							_expect(weapon_ability_tag_count == 0, "%s starter autocannon must not turn spread 0 into a mechanism pill" % semantic_language)
						"weapon_flamethrower":
							expected_mechanism = "扩散 10°" if semantic_language == "zh" else "Spread 10°"
						"weapon_teslacoil":
							expected_mechanism = "自带连锁 +2 目标" if semantic_language == "zh" else "Built-in Chain +2 Targets"
						"weapon_venomlauncher":
							expected_mechanism = "毒云范围 120" if semantic_language == "zh" else "Cloud Radius 120"
					if expected_mechanism != "":
						_expect(semantic_tag_texts.has(expected_mechanism), "%s weapon %s must expose the verified mechanism unit '%s'" % [semantic_language, semantic_row.name, expected_mechanism])
				if semantic_action != null:
					_expect(semantic_action.position.y + semantic_action.size.y <= semantic_row.size.y - 12.0, "%s %s action must stay inside its card" % [semantic_language, semantic_mode])
				if mode_card_height <= 0.0:
					mode_card_height = semantic_row.size.y
				else:
					_expect(is_equal_approx(semantic_row.size.y, mode_card_height), "%s %s rows must share one card height" % [semantic_language, semantic_mode])
				semantic_rows_checked += 1
			_expect(semantic_rows_checked > 0, "%s %s collection spacing audit must inspect real rows" % [semantic_language, semantic_mode])
			language_card_heights[semantic_mode] = mode_card_height
		semantic_card_heights[semantic_language] = language_card_heights
	for semantic_mode in ["characters", "weapons", "armors", "chips", "pets"]:
		var zh_height := float((semantic_card_heights.get("zh", {}) as Dictionary).get(semantic_mode, 0.0))
		var en_height := float((semantic_card_heights.get("en", {}) as Dictionary).get(semantic_mode, 0.0))
		_expect(zh_height > 0.0 and is_equal_approx(zh_height, en_height), "%s collection card height must remain identical in Chinese and English" % semantic_mode)
	semantic_localization_manager.apply_language(semantic_language_before, false)
	var collection_test_save: Dictionary = save_manager._default_save()
	var collection_player: Dictionary = collection_test_save.get("player", {}).duplicate(true)
	collection_player["gold"] = 184321
	collection_player["xp"] = 32752
	collection_player["star"] = 73
	collection_test_save["player"] = collection_player
	var collection_unlocks: Dictionary = collection_test_save.get("unlocks", {}).duplicate(true)
	collection_unlocks["weapons"] = ["weapon_autocannon", "weapon_cryocannon"]
	collection_test_save["unlocks"] = collection_unlocks
	var collection_equipment: Dictionary = collection_test_save.get("equipment", {}).duplicate(true)
	collection_equipment["weapon_autocannon"] = 5
	collection_equipment["weapon_cryocannon"] = 1
	collection_equipment["selected_weapon"] = "weapon_cryocannon"
	collection_test_save["equipment"] = collection_equipment
	save_manager.save_data = collection_test_save
	main.change_scene("collection", {"mode": "weapons"})
	await process_frame
	_expect(main.current_scene.name == "Collection", "main must route to collection")
	var collection_resource_bar: Node = main.current_scene.find_child("ResourceBar", true, false)
	_expect(collection_resource_bar != null, "collection must expose the shared account resource bar")
	_assert_resource_chip_geometry(collection_resource_bar, "collection resource bar", "default")
	_expect(main.current_scene.find_child("ItemList", true, false) != null, "collection item list must be scrollable")
	var weapon_list: Node = main.current_scene.find_child("ItemList", true, false)
	_expect(weapon_list.get_child_count() >= 8, "collection must render weapon pool")
	var weapon_scroll := main.current_scene.find_child("ItemScroll", true, false) as ScrollContainer
	weapon_scroll.scroll_vertical = 360
	await process_frame
	var preserved_weapon_scroll := weapon_scroll.scroll_vertical
	_expect(preserved_weapon_scroll > 0, "collection regression setup must reach a non-zero browsing position")
	main.current_scene._refresh()
	for i in range(3):
		await process_frame
	weapon_scroll = main.current_scene.find_child("ItemScroll", true, false) as ScrollContainer
	_expect(absi(weapon_scroll.scroll_vertical - preserved_weapon_scroll) <= 2, "collection refresh must preserve the player's browsing position")
	weapon_list = main.current_scene.find_child("ItemList", true, false)
	var first_weapon: TextureButton = null
	var purchasable_weapon: TextureButton = null
	for weapon_child in weapon_list.get_children():
		if not (weapon_child is TextureButton):
			continue
		var weapon_button := weapon_child as TextureButton
		var card_action := weapon_button.find_child("CardActionButton", true, false) as TextureButton
		if first_weapon == null and not weapon_button.has_node("LockedCardVeil"):
			first_weapon = weapon_button
		if purchasable_weapon == null and weapon_button.has_node("LockedCardVeil") and card_action != null and not card_action.disabled:
			purchasable_weapon = weapon_button
	_expect(first_weapon != null, "collection must expose at least one unlocked weapon")
	_expect(purchasable_weapon != null, "collection must expose a purchasable locked weapon when player has enough stars")
	if first_weapon != null:
		var weapon_frame := first_weapon.get_node_or_null("Frame") as PanelContainer
		var weapon_icon := first_weapon.get_node_or_null("Icon") as TextureRect
		var weapon_title := first_weapon.get_node_or_null("Title") as Label
		var weapon_description := first_weapon.get_node_or_null("Description") as Label
		var weapon_action := first_weapon.get_node_or_null("CardActionButton") as TextureButton
		_expect(first_weapon.size.x >= 896.0, "weapon collection cards must consume the safe-area ruler beside the scrollbar")
		_expect(weapon_frame != null and weapon_frame.size.x >= 864.0, "weapon collection frame must expand with the full-width card; got %.1f inside %.1f" % [weapon_frame.size.x if weapon_frame != null else 0.0, first_weapon.size.x])
		_expect(weapon_icon != null and weapon_icon.size.x >= 204.0 and weapon_icon.size.y >= 204.0, "weapon collection logo must use the shared enlarged 204px showcase size")
		_expect(weapon_icon != null and weapon_icon.position.x >= 32.0, "weapon collection logo must keep its left-frame breathing room")
		_expect(weapon_title != null and weapon_title.position.x >= 272.0, "weapon collection title must share the right-shifted catalog text axis")
		_expect(weapon_description != null and weapon_description.position.x == weapon_title.position.x, "weapon collection copy must share one right-shifted text axis")
		_expect(weapon_icon != null and weapon_title != null and weapon_title.position.x - (weapon_icon.position.x + weapon_icon.size.x) >= 30.0, "weapon collection text must keep breathing room after the enlarged logo")
		_expect(weapon_action != null and weapon_action.position.x + weapon_action.size.x <= first_weapon.size.x - 32.0, "weapon collection action must remain inside the widened frame")
	var purchasable_veil := purchasable_weapon.get_node("LockedCardVeil") as TextureRect
	var purchase_action := purchasable_weapon.find_child("CardActionButton", true, false) as TextureButton
	var purchase_label := purchase_action.get_node("ActionLabel") as Label
	_expect(purchasable_veil != null, "purchasable locked weapon rows must keep the card body dark")
	_expect(purchase_action != null and not purchase_action.disabled, "purchasable locked weapon rows must keep the purchase button bright and enabled")
	_expect(purchase_action.z_index > purchasable_veil.z_index, "purchase button must render above the locked-row dark veil")
	_expect(purchase_label.text.begins_with("购买"), "purchasable locked weapon action must read as purchase, got %s" % purchase_label.text)
	_assert_resource_cost(purchase_action, "star", save_manager.get_unlock_price_star("weapons", String(purchasable_weapon.name)), "locked collection purchase")
	_expect(not first_weapon.has_node("LockedCardVeil"), "owned weapon rows must not use the locked dark veil")
	_expect(not first_weapon.has_node("UpgradeButton"), "collection rows must keep actions inside detail")
	var purchased_weapon_id := String(purchasable_weapon.name)
	main.current_scene._do_purchase("weapons", purchased_weapon_id)
	await process_frame
	await process_frame
	_expect(save_manager.is_item_unlocked("weapon", purchased_weapon_id), "purchased weapon must be unlocked")
	_expect(save_manager.get_selected("weapon") == purchased_weapon_id, "purchased weapon must auto-equip after purchase")
	weapon_list = main.current_scene.find_child("ItemList", true, false)
	var purchased_weapon: TextureButton = null
	for weapon_child in weapon_list.get_children():
		if not (weapon_child is TextureButton):
			continue
		var weapon_button := weapon_child as TextureButton
		var card_action := weapon_button.find_child("CardActionButton", true, false) as TextureButton
		var action_label: Label = null
		if card_action != null:
			action_label = card_action.get_node("ActionLabel") as Label
		if not weapon_button.has_node("LockedCardVeil") and action_label != null and action_label.text == "已装备":
			purchased_weapon = weapon_button
			break
	_expect(purchased_weapon != null, "purchased weapon row must become bright and show equipped state")
	purchased_weapon.emit_signal("pressed")
	await process_frame
	_expect(main.current_scene.has_node("ItemDetail"), "collection row click must open item detail")
	var item_detail: Node = main.current_scene.get_node("ItemDetail")
	var item_detail_panel := item_detail.get_node("Panel") as PanelContainer
	var item_detail_style := item_detail_panel.get_theme_stylebox("panel") as StyleBoxTexture
	_expect(item_detail_style != null and item_detail_style.texture != null and item_detail_style.texture.resource_path.ends_with("ui_detail_panel_clear.png"), "equipment detail must use the authored rule-free texture surface")
	var item_close := item_detail.find_child("CloseButton", true, false) as Button
	_expect(item_close != null, "item detail top close must be a compact button")
	_expect(item_close.text == "×", "item detail top close must use an icon-only x")
	_expect(item_close.custom_minimum_size.x >= UiKit.CLOSE_BUTTON_MIN_SIZE.x and item_close.custom_minimum_size.y >= UiKit.CLOSE_BUTTON_MIN_SIZE.y, "item detail top close must keep the larger modal-close target")
	_expect(item_close.get_theme_font_size("font_size") >= UiKit.CLOSE_GLYPH_FONT_SIZE, "item detail top close glyph must remain visually prominent")
	_expect(item_detail.find_child("EquipButton", true, false) != null, "item detail must expose equip action")
	var item_upgrade_button := item_detail.find_child("UpgradeButton", true, false) as TextureButton
	_expect(item_upgrade_button != null, "item detail must expose upgrade action")
	_assert_resource_cost(item_upgrade_button, "gold", save_manager.get_item_upgrade_cost("weapons", purchased_weapon_id), "equipment upgrade")
	main.current_scene._close_character_detail()
	await process_frame
	var purchased_row: Dictionary = data_loader.get_row("weapons", purchased_weapon_id)
	var purchased_max_level := int(purchased_row.get("max_level", 30))
	var max_equipment: Dictionary = save_manager.save_data.get("equipment", {}).duplicate(true)
	max_equipment[purchased_weapon_id] = purchased_max_level
	save_manager.save_data["equipment"] = max_equipment
	main.current_scene._refresh()
	await process_frame
	var max_weapon_row := main.current_scene.find_child(purchased_weapon_id, true, false) as TextureButton
	_expect(max_weapon_row != null, "max-level regression must find the purchased weapon row")
	max_weapon_row.emit_signal("pressed")
	await process_frame
	var max_detail: Node = main.current_scene.get_node("ItemDetail")
	var max_upgrade_label := max_detail.find_child("UpgradeButton", true, false).get_node("ActionLabel") as Label
	_expect(max_upgrade_label.text == "已满级", "max-level item detail must replace upgrade cost with a completed-state label")
	var max_stats: Array = main.current_scene._detail_stats_for_item(purchased_weapon_id, purchased_row, purchased_max_level)
	var has_completed_growth_state := false
	for max_stat: Dictionary in max_stats:
		if str(max_stat.get("value", "")) == "已满级" and str(max_stat.get("sub", "")) == "成长已完成":
			has_completed_growth_state = true
			break
	_expect(has_completed_growth_state, "max-level stats must communicate completed growth without a stale coin cost")
	main.current_scene._close_character_detail()
	await process_frame
	save_manager.save_data = smoke_save_snapshot.duplicate(true)
	main.change_scene("map", {"chapter": 1})
	await process_frame
	_expect(main.current_scene.name == "Map" and main.current_scene.selected_chapter == 1, "chapter route payload must open the requested sub-warzone")
	main.current_scene._open_level("level_001")
	await process_frame
	_expect(main.current_scene.name == "Loadout", "sub-warzone level entry must route to loadout")
	_expect(int(main.current_scene._return_payload.get("chapter", 0)) == 1, "loadout opened from a sub-warzone must retain its chapter return context")
	var sub_warzone_loadout_back := main.current_scene.find_child("BackButton", true, false) as TextureButton
	_expect(sub_warzone_loadout_back != null, "sub-warzone loadout must expose a back button")
	if sub_warzone_loadout_back != null:
		sub_warzone_loadout_back.emit_signal("pressed")
		await process_frame
	_expect(main.current_scene.name == "Map", "loadout back must return to the map route")
	_expect(main.current_scene.selected_chapter == 1, "loadout back must restore the originating sub-warzone instead of the chapter overview")
	var returned_sub_warzone_levels: Node = main.current_scene.find_child("LevelList", true, false)
	_expect(returned_sub_warzone_levels != null and returned_sub_warzone_levels.get_child_count() >= 11, "restored sub-warzone must render its header and ten level cards")
	main.change_scene("loadout", {"level_id": "level_001"})
	await process_frame
	_expect(main.current_scene.name == "Loadout", "main must route to loadout")
	_expect(main.current_scene.has_node("Background"), "loadout must render themed background")
	_expect(main.current_scene.has_node("UpgradeButton"), "loadout must expose weapon upgrade entry")
	_expect(main.current_scene.find_child("WeaponIcon", true, false) != null, "loadout must show weapon icon")
	_expect(main.current_scene.find_child("CharacterIcon", true, false) != null, "loadout must show character portrait")
	var loadout_character_icon := main.current_scene.find_child("CharacterIcon", true, false) as TextureRect
	_expect(loadout_character_icon.texture == null, "loadout hero frame must not draw a baked portrait card")
	_expect(loadout_character_icon.clip_contents, "loadout hero frame must crop upper-body art")
	var loadout_bust := loadout_character_icon.get_node_or_null("BustImage") as TextureRect
	_expect(loadout_bust != null and loadout_bust.texture != null, "loadout hero frame must render a bust image")
	_expect(str(loadout_bust.texture.resource_path).ends_with("_portrait_frameless.png"), "loadout hero bust must use frameless 正脸立绘")
	_expect(loadout_bust.size.y > loadout_character_icon.size.y, "loadout hero bust must be zoomed and cropped")
	var loadout_theme_manager := root.get_node("/root/ThemeManager")
	var loadout_theme_ids := ["default", "neon_tempest", "infernal_dominion", "polar_aurora", "gilded_eclipse"]
	for theme_id in loadout_theme_ids:
		for character_id in ["vanguard", "blaze", "frost", "volt"]:
			var character_row: Dictionary = data_loader.get_row("characters", character_id)
			var fallback_path := str(character_row.get("portrait", character_row.get("icon", "")))
			var frameless_fallback := fallback_path.replace("_icon.png", "_portrait_frameless.png")
			if frameless_fallback != "" and ResourceLoader.exists(frameless_fallback):
				fallback_path = frameless_fallback
			var portrait_path := str(loadout_theme_manager.resolve_character_portrait_for_theme(character_id, theme_id, fallback_path))
			var portrait := load(portrait_path) as Texture2D
			_expect(portrait != null, "%s/%s loadout portrait must resolve" % [theme_id, character_id])
			if portrait == null:
				continue
			var layout: Dictionary = main.current_scene._loadout_bust_layout(portrait)
			var visible_rect: Rect2 = layout.get("visible_rect", Rect2())
			_expect(absf(visible_rect.position.y - 10.0) <= 0.1, "%s/%s loadout portrait must keep exact head safety" % [theme_id, character_id])
			_expect(absf(visible_rect.size.y - main.current_scene.HERO_BUST_REFERENCE_VISIBLE_HEIGHT) <= 0.1, "%s/%s loadout portrait must share the Steel Vanguard human ruler" % [theme_id, character_id])
			_expect(absf(visible_rect.get_center().x - main.current_scene.HERO_BUST_WINDOW_SIZE.x * 0.5) <= 0.1, "%s/%s loadout silhouette must be centered by visible bounds" % [theme_id, character_id])
			_expect((layout.get("size", Vector2.ZERO) as Vector2).y > main.current_scene.HERO_BUST_WINDOW_SIZE.y, "%s/%s loadout portrait must remain an impactful half-body crop" % [theme_id, character_id])
	# The accepted default Steel Vanguard screenshot is the immutable reference:
	# the new alpha-aware contract must reproduce its old 378 px authored width.
	var default_vanguard := load("res://assets/production/sprites/characters/char_vanguard_portrait_frameless.png") as Texture2D
	var default_vanguard_layout: Dictionary = main.current_scene._loadout_bust_layout(default_vanguard)
	_expect(absf((default_vanguard_layout.get("size", Vector2.ZERO) as Vector2).x - 378.0) <= 0.5, "default Steel Vanguard must retain the owner-approved loadout scale")
	var golden_law_row: Dictionary = data_loader.get_row("weapons", "weapon_apocalypse_golden_law")
	var golden_law_loadout_path := str(golden_law_row.get("loadout_art", ""))
	_expect(golden_law_loadout_path.ends_with("weapon_apocalypse_golden_law_loadout_v3.png"), "Golden Law loadout must use its dedicated horizontal V3 product render")
	var loadout_weapon_paths: Array[String] = []
	var loadout_weapon_ids_by_path := {}
	for weapon_key_var in data_loader.get_table("weapons").keys():
		var weapon_key := str(weapon_key_var)
		var weapon_row: Dictionary = data_loader.get_row("weapons", weapon_key)
		var clean_path := str(weapon_row.get("loadout_art", weapon_row.get("handheld", "")))
		if clean_path != "" and not loadout_weapon_paths.has(clean_path):
			loadout_weapon_paths.append(clean_path)
			loadout_weapon_ids_by_path[clean_path] = weapon_key
		if weapon_key.begins_with("weapon_apocalypse_"):
			continue
		for root in [
			"res://assets/production/sprites/themes/infernal_dominion/weapons",
			"res://assets/production/sprites/themes/polar_aurora/weapons",
			"res://assets/production/sprites/themes/gilded_eclipse/weapons",
		]:
			var themed_path := "%s/%s_handheld.png" % [root, weapon_key]
			if ResourceLoader.exists(themed_path) and not loadout_weapon_paths.has(themed_path):
				loadout_weapon_paths.append(themed_path)
				loadout_weapon_ids_by_path[themed_path] = weapon_key
	var loadout_weapon_icon := main.current_scene.find_child("WeaponIcon", true, false) as TextureRect
	for clean_path in loadout_weapon_paths:
		var path_weapon_id := str(loadout_weapon_ids_by_path.get(clean_path, "weapon_autocannon"))
		main.current_scene._configure_weapon_showcase_rect(loadout_weapon_icon, path_weapon_id)
		var clean_weapon := load(clean_path) as Texture2D
		_expect(clean_weapon != null, "loadout clean weapon art must resolve: %s" % clean_path)
		if clean_weapon == null:
			continue
		var clean_display: Texture2D = main.current_scene._loadout_weapon_texture(clean_weapon, loadout_weapon_icon)
		_expect(clean_display is AtlasTexture, "every loadout weapon must be alpha-fitted without its authoring canvas: %s" % clean_path)
		if clean_display is AtlasTexture:
			var clean_used := clean_weapon.get_image().get_used_rect()
			var clean_region := Rect2i((clean_display as AtlasTexture).region)
			_expect(clean_region.encloses(clean_used), "loadout weapon display must preserve the complete gun silhouette: %s" % clean_path)
			var visible_long_axis := float(loadout_weapon_icon.get_meta("loadout_weapon_visible_long_axis", 0.0))
			if path_weapon_id.begins_with("weapon_apocalypse_"):
				_expect(visible_long_axis >= 260.0 and visible_long_axis <= 400.0, "paid loadout weapon must occupy the enlarged premium ruler; got %.1f: %s" % [visible_long_axis, clean_path])
			else:
				_expect(visible_long_axis >= 328.0 and visible_long_axis <= 360.0, "free loadout weapon must occupy the enlarged showcase ruler; got %.1f: %s" % [visible_long_axis, clean_path])
			if path_weapon_id == "weapon_apocalypse_golden_law":
				_expect(visible_long_axis >= 370.0, "Golden Law V3 must read as a full-width endgame cannon; got %.1f" % visible_long_axis)
			_expect(absf(loadout_weapon_icon.rotation_degrees) <= 0.01, "loadout weapon must remain rotation-neutral: %s" % clean_path)
	main.current_scene._refresh_character_bust(data_loader.get_row("characters", save_manager.get_selected("character")))
	_expect(main.current_scene.find_child("GrowthBadge", true, false) != null, "loadout must show visible growth tier")
	_expect(main.current_scene.has_node("GearBadges"), "loadout must summarize gear levels")
	_expect(main.current_scene.has_node("EquipNav"), "loadout must expose equipment navigation")
	_expect(main.current_scene.find_child("BackButton", true, false) != null, "loadout must expose back-to-map button")
	_expect(main.current_scene.has_node("CharacterSelectBar"), "loadout must expose direct character selection bar")
	_expect(main.current_scene.find_child("GearIconRow", true, false) != null, "loadout must expose direct armor/chip/pet icon row")
	_expect(main.current_scene.has_node("SignatureCards"), "loadout must expose character signature skills")
	_expect(main.current_scene.has_node("Root"), "loadout must use a responsive container layout")
	_expect(main.current_scene.find_child("CharacterPanel", true, false) != null, "loadout must render a bordered character panel")
	_expect(main.current_scene.find_child("WeaponPanel", true, false) != null, "loadout must render a bordered weapon panel")
	_expect(not main.current_scene.get_node("UpgradeButton").visible, "loadout must not use a large weapon upgrade button")
	_expect(not main.current_scene.get_node("EquipNav").visible, "loadout must hide old text equipment nav")
	_expect(main.current_scene.get_node("CharacterSelectBar").get_child_count() >= 4, "loadout character bar must render direct portrait buttons")
	_expect(main.current_scene.find_child("GearIconRow", true, false).get_child_count() == 3, "loadout gear row must render armor/chip/pet icons")
	var loadout_equipment_before_empty_test: Dictionary = save_manager.save_data.get("equipment", {}).duplicate(true)
	var empty_loadout_equipment: Dictionary = loadout_equipment_before_empty_test.duplicate(true)
	for empty_slot_key in ["selected_armor", "selected_chip", "selected_pet"]:
		empty_loadout_equipment[empty_slot_key] = ""
	save_manager.save_data["equipment"] = empty_loadout_equipment
	main.current_scene._refresh()
	await process_frame
	var empty_gear_row := main.current_scene.find_child("GearIconRow", true, false) as HBoxContainer
	var verified_empty_slot_count := 0
	for gear_card_node in empty_gear_row.get_children():
		var gear_card := gear_card_node as Control
		var empty_choose := gear_card.find_child("EmptyChooseLabel", true, false) as Label
		var slot_identity := gear_card.find_child("SlotLabel", true, false) as Label
		if empty_choose == null:
			continue
		verified_empty_slot_count += 1
		_expect(empty_choose.text == "选择", "empty loadout slot must use the compact localized Select action")
		_expect(empty_choose.clip_text, "empty loadout slot action must never paint outside its card")
		_expect(empty_choose.position.x >= 8.0 and empty_choose.position.x + empty_choose.size.x <= gear_card.size.x - 8.0, "empty loadout slot action must keep horizontal frame safety")
		_expect(slot_identity != null and not slot_identity.text.contains("选择"), "empty loadout slot identity must not repeat the Select action")
		_expect(slot_identity != null and slot_identity.clip_text, "empty loadout slot identity must never paint outside its card")
	_expect(verified_empty_slot_count == 3, "loadout must verify compact empty-state copy for armor, chip and pet")
	save_manager.save_data["equipment"] = loadout_equipment_before_empty_test
	main.current_scene._refresh()
	await process_frame
	_expect(main.current_scene.get_node("SignatureCards").get_child_count() >= 3, "loadout must show passive and two signature previews")
	var loadout_details := main.current_scene.find_child("DetailsPanel", true, false) as Control
	var loadout_start := main.current_scene.find_child("StartButton", true, false) as TextureButton
	var loadout_summary_safe := loadout_details.find_child("SummarySafeArea", true, false) as MarginContainer
	var loadout_summary_content := loadout_details.find_child("SummaryContent", true, false) as VBoxContainer
	_expect(loadout_summary_safe != null, "loadout tactical summary must reserve an explicit content safe area")
	if loadout_summary_safe != null:
		_expect(loadout_summary_safe.get_theme_constant("margin_left") >= 32, "loadout tactical summary must keep its copy clear of the left frame")
		_expect(loadout_summary_safe.get_theme_constant("margin_right") >= 28, "loadout tactical summary must keep its copy clear of the right frame")
	if loadout_summary_content != null:
		var loadout_summary_rect := loadout_summary_content.get_global_rect()
		var loadout_details_rect := loadout_details.get_global_rect()
		_expect(loadout_summary_rect.position.x - loadout_details_rect.position.x >= 30.0, "loadout tactical summary rendered copy must keep left-frame clearance")
		_expect(loadout_details_rect.end.x - loadout_summary_rect.end.x >= 26.0, "loadout tactical summary rendered copy must keep right-frame clearance")
	var loadout_action_gap := loadout_start.get_global_rect().position.y - (loadout_details.get_global_rect().position.y + loadout_details.get_global_rect().size.y)
	_expect(loadout_action_gap >= 50.0, "loadout bottom action must keep a clear gap below the tactical summary")
	var loadout_power_pill := loadout_details.find_child("PowerStatePill", true, false) as PanelContainer
	var loadout_counter_pill := loadout_details.find_child("CounterStatePill", true, false) as PanelContainer
	var loadout_bottleneck_reason := loadout_details.find_child("BottleneckReason", true, false) as Label
	_expect(loadout_power_pill != null, "loadout must expose a dedicated combat-power state pill")
	_expect(loadout_counter_pill != null, "loadout must keep counter guidance secondary to combat-power state")
	_expect(loadout_bottleneck_reason != null and loadout_bottleneck_reason.text.strip_edges() != "", "loadout tactical summary must explain the current three-axis power bottleneck")
	if loadout_power_pill != null:
		_assert_semantic_tag_panel(loadout_power_pill, "loadout combat-power state")
	if loadout_counter_pill != null:
		_assert_semantic_tag_panel(loadout_counter_pill, "loadout counter guidance")
	_expect(main.current_scene.get_node("Summary").text.contains("001 城市缺口"), "loadout must show player-facing level name")
	_expect(main.current_scene.get_node("Summary").text.contains("有效战力"), "loadout must name the level-relative player value Effective Power")
	_expect(not main.current_scene.get_node("Summary").text.contains("基准") and not main.current_scene.get_node("Summary").text.contains("预计成型"), "loadout must not split power into baseline and projected concepts")
	_expect(not main.current_scene.get_node("Summary").text.contains("level_001"), "loadout must not expose internal level id")
	_expect(main.current_scene.get_node("Summary").text.contains("五波") or main.current_scene.get_node("Objective").text.contains("五波"), "loadout copy must mention five-wave pacing")
	_expect(main.current_scene.get_node("EquipNav").get_child_count() >= 5, "loadout must link to all equipment categories")
	main.change_scene("loadout", {"level_id": "level_001", "challenge": true})
	await process_frame
	_expect(main.current_scene.name == "Loadout", "main must route to challenge loadout")
	_expect(main.current_scene.is_challenge_mode, "challenge loadout must keep the challenge flag")
	var challenge_start := main.current_scene.find_child("StartButton", true, false) as TextureButton
	var challenge_start_label := challenge_start.get_node("Label") as Label
	var challenge_was_severely_underpowered: bool = bool(main.current_scene._is_severely_underpowered())
	_expect(
		challenge_start_label.text.contains("有效战力严重不足") if challenge_was_severely_underpowered else challenge_start_label.text == "开始挑战",
		"challenge loadout start button must accurately reflect its combat-power state"
	)
	challenge_start.emit_signal("pressed")
	if challenge_was_severely_underpowered:
		_expect(challenge_start_label.text.contains("再次点击"), "severely underpowered challenge entry must require a deliberate second confirmation")
		challenge_start.emit_signal("pressed")
	await process_frame
	_expect(main.current_scene.name == "Battle", "challenge start must route to battle")
	_expect(main.current_scene.is_challenge_mode, "battle must enter challenge mode when started from challenge loadout")
	main.finish_level({"victory": true, "stars": 3, "gold": 0, "xp": 0, "challenge": true}, false)
	await process_frame
	_expect(main.current_scene.name == "Result", "challenge finish must route to result")
	_expect(main.current_scene.is_challenge_result, "challenge result must keep the challenge flag")
	_expect(main.current_scene.next_level == "", "challenge result must not expose campaign next-level progression")
	main.change_scene("loadout", {"level_id": "level_001"})
	await process_frame
	var character_panel := main.current_scene.find_child("CharacterPanel", true, false) as Control
	_expect(character_panel != null and character_panel.has_node("OpenHitArea"), "loadout character panel must open collection as a layer")
	var character_open_hit := character_panel.get_node("OpenHitArea") as Button
	var character_panel_rect := character_panel.get_global_rect()
	var character_hit_rect := character_open_hit.get_global_rect()
	_expect(character_hit_rect.size.x >= character_panel_rect.size.x - 2.0 and character_hit_rect.size.y >= character_panel_rect.size.y - 2.0, "loadout hero card must use its full surface for hero selection")
	_expect(not character_panel.has_node("AppearanceHitArea"), "loadout hero card must not split portrait taps into an outfit-only shortcut")
	_expect(character_open_hit.has_node("CharacterEntryBadge"), "loadout hero card must explain that the entry supports hero and outfit changes")
	character_open_hit.emit_signal("pressed")
	await process_frame
	_expect(main.current_scene.name == "Collection", "loadout character panel must route to collection")
	_expect(main.current_scene.mode == "characters", "loadout hero card must open the hero collection rather than an outfit-only dialog")
	var loadout_selected_character := str(save_manager.get_selected("character"))
	var loadout_selected_character_row: Dictionary = data_loader.get_row("characters", loadout_selected_character)
	main.current_scene._show_character_detail(loadout_selected_character, loadout_selected_character_row)
	await process_frame
	_expect(main.current_scene.find_child("SelectButton", true, false) != null, "hero detail opened from loadout must retain the hero-selection action")
	_expect(main.current_scene.find_child("AppearanceButton", true, false) != null, "hero detail opened from loadout must also retain the outfit action")
	var loadout_character_detail_close := main.current_scene.find_child("CancelButton", true, false) as TextureButton
	_expect(loadout_character_detail_close != null, "hero detail opened from loadout must remain closable")
	if loadout_character_detail_close != null:
		loadout_character_detail_close.emit_signal("pressed")
		await process_frame
	collection_back = main.current_scene.find_child("BackButton", true, false) as TextureButton
	_expect(collection_back != null, "collection opened from loadout must expose back button")
	_expect((collection_back.get_node("Label") as Label).text == "返回配置", "collection opened from loadout must label back as returning to configuration")
	collection_back.emit_signal("pressed")
	await process_frame
	_expect(main.current_scene.name == "Loadout", "collection opened from loadout must route back to loadout")
	_expect(main.current_scene.level_id == "level_001", "collection back to loadout must preserve current level")
	main.start_level("level_003")
	await process_frame
	main.finish_level({"victory": true, "stars": 3, "gold": 0, "xp": 0}, false)
	await process_frame
	_expect(main.current_scene.name == "Result", "main finish must route to result")
	_expect(main.current_scene.level_id == "level_003", "main finish must recover active level_id when result payload omits it")
	_expect(main.current_scene.next_level == "level_004", "main finish must normalize level_003 clear to level_004")
	main.current_scene._on_next_pressed()
	await process_frame
	_expect(main.current_scene.name == "Loadout", "next button must route to loadout after recovered result")
	_expect(main.current_scene.level_id == "level_004", "next button must route recovered level_003 clear to level_004")
	var result_loadout_back := main.current_scene.find_child("BackButton", true, false) as TextureButton
	_expect(result_loadout_back != null, "result-opened loadout must expose a back button")
	_expect((result_loadout_back.get_node("Label") as Label).text == "返回结算", "result-opened loadout must label back as returning to result")
	var result_loadout_character_panel: Node = main.current_scene.find_child("CharacterPanel", true, false)
	(result_loadout_character_panel.get_node("OpenHitArea") as Button).emit_signal("pressed")
	await process_frame
	_expect(main.current_scene.name == "Collection", "result-opened loadout must still open collection")
	collection_back = main.current_scene.find_child("BackButton", true, false) as TextureButton
	collection_back.emit_signal("pressed")
	await process_frame
	_expect(main.current_scene.name == "Loadout", "collection back must return to result-opened loadout")
	_expect(main.current_scene.level_id == "level_004", "collection back must preserve next-level loadout id")
	result_loadout_back = main.current_scene.find_child("BackButton", true, false) as TextureButton
	result_loadout_back.emit_signal("pressed")
	await process_frame
	_expect(main.current_scene.name == "Result", "result-opened loadout back must return to result instead of map")
	_expect(main.current_scene.level_id == "level_003", "returned result must preserve the cleared level")
	main.start_level("level_035")
	await process_frame
	for i in range(20):
		await physics_frame
	_expect(main.current_scene.name == "Battle", "main start_level must route to battle")
	_expect(main.current_scene.level_id == "level_035", "main start_level must initialize requested battle level before _ready")
	if main.current_scene.get_node("EnemyLayer").get_child_count() > 0:
		var routed_enemy: Node = main.current_scene.get_node("EnemyLayer").get_child(0)
		var routed_hp_floor: float = float(main.current_scene.level.get("base_hp_ref", 50)) * float(main.current_scene.level.get("difficulty_coef", 1.0)) * float(main.current_scene._wave_hp_coef(1)) * 0.55
		_expect(float(routed_enemy.max_hp) >= routed_hp_floor, "main-routed battle enemy hp must use requested level; got %.1f expected floor %.1f" % [float(routed_enemy.max_hp), routed_hp_floor])
	save_manager.save_data = smoke_save_snapshot.duplicate(true)
	main.queue_free()
	await process_frame

	var router := FakeRouter.new()
	root.add_child(router)
	save_manager.save_data = _battle_smoke_loadout(smoke_save_snapshot)
	await _verify_level20_boss_hp_modes(router, data_loader)
	for level in data_loader.get_table("levels"):
		var battle := _instance("res://gameplay/battle/battle.tscn")
		battle.setup(router, {"level_id": level.get("id", "level_001")})
		root.add_child(battle)
		await process_frame
		for i in range(20):
			await physics_frame
		_expect(battle.level_id == level.get("id", ""), "battle must keep requested level id")
		_expect(battle.wave_total == 5, "battle must load five waves for %s" % battle.level_id)
		_expect(battle.turret != null, "battle must spawn turret for %s" % battle.level_id)
		_expect(battle.character_sprite != null, "battle must spawn selected character avatar for %s" % battle.level_id)
		_expect(absf(float(battle.CHARACTER_PRESENTATION_SCALE) - 1.20) <= 0.001, "battle hero must be reduced to 80% of the former 1.50x presentation")
		_expect((battle.character_rig as Node2D).scale.is_equal_approx(Vector2.ONE * float(battle.CHARACTER_PRESENTATION_SCALE)), "battle hero rig must use the 1.20x presentation scale")
		_expect(float(battle.character_rig_foot_lift) > 0.0 and absf((battle.character_rig as Node2D).position.y + float(battle.character_rig_foot_lift) - float(battle.CHARACTER_BASE_POSITION.y)) <= 0.5, "enlarged battle hero must remain foot-anchored above the bottom HUD")
		_expect(bool(battle.character_weapon_combo_active), "battle must use fused selected character/weapon art for %s" % battle.level_id)
		_expect(battle.character_weapon_sprite == null, "fused battle art must not also mount a floating weapon sprite for %s" % battle.level_id)
		_expect(not bool(battle.turret.visible), "legacy turret sprite must stay hidden while logic is reused")
		var fused_texture := (battle.character_sprite as Sprite2D).texture
		_expect(fused_texture != null, "fused character/weapon texture must exist for %s" % battle.level_id)
		var fused_texture_path := str(fused_texture.resource_path)
		if fused_texture_path != "":
			_expect(fused_texture_path.contains("/character_weapon_combos/"), "battle character must load fused art from character_weapon_combos for %s" % battle.level_id)
		_expect(battle.character_idle_frames.size() >= 4, "fused character/weapon art must provide idle frames for %s" % battle.level_id)
		_expect(battle.character_attack_left_frames.size() == 8, "fused character/weapon art must provide the full 8-frame left-aim firing strip for %s" % battle.level_id)
		_expect(battle.character_attack_frames.size() == 8, "fused character/weapon art must provide the full 8-frame firing strip for %s" % battle.level_id)
		_expect(battle.character_attack_right_frames.size() == 8, "fused character/weapon art must provide the full 8-frame right-aim firing strip for %s" % battle.level_id)
		_expect(battle.character_hurt_frames.size() >= 3, "fused character/weapon art must provide hurt frames for %s" % battle.level_id)
		var expected_fused_origin: Vector2 = battle.character_rig.to_global(battle._character_combo_muzzle_for_aim())
		_expect(battle._weapon_fire_origin().distance_to(expected_fused_origin) <= 1.0, "projectiles must originate from the fused character/weapon muzzle")
		battle._set_character_combo_aim_from_direction(Vector2.UP)
		var expected_center_origin: Vector2 = battle.character_rig.to_global(battle.character_weapon_combo_muzzle)
		battle._set_character_combo_aim_from_direction(Vector2(-0.75, -0.66).normalized())
		var left_origin: Vector2 = battle._weapon_fire_origin()
		battle._set_character_combo_aim_from_direction(Vector2(0.75, -0.66).normalized())
		var right_origin: Vector2 = battle._weapon_fire_origin()
		_expect(left_origin.x < expected_center_origin.x - 20.0, "left-aim fused muzzle must move left for %s" % battle.level_id)
		_expect(right_origin.x > expected_center_origin.x + 20.0, "right-aim fused muzzle must move right for %s" % battle.level_id)
		battle._set_character_combo_aim_from_direction(Vector2.UP)
		battle._play_character_attack()
		_expect(battle.character_anim_frame == 1, "real character fire must bind to authored F2 ignition for %s" % battle.level_id)
		_expect((battle.character_sprite as Sprite2D).texture == battle.character_attack_frames[1], "ignition frame texture must be visible at real fire contact for %s" % battle.level_id)
		_expect(float(battle.turret.damage_mult) > 1.0, "turret must receive character and chip damage multipliers")
		_expect(battle.base_hp_max > int(battle.level.get("base_hp_ref", 100)), "battle must receive armor and character survivability")
		_expect(not battle.has_node("Hud/StrategyButton"), "battle HUD must not expose the old target strategy button")
		_expect(battle.has_node("Hud/SkillSlots"), "battle must expose skill slots")
		if battle.level_id == "level_001":
			_verify_boss_hp_hud_layout(battle)
			battle.onboarding_tip_shown = false
			battle._show_onboarding_tip()
			_expect(battle.wave_toast_label.text.contains("按住战场拖动"), "first battle onboarding must explain hold-and-drag manual aim")
			_expect(battle.wave_toast_label.text.contains("双击僵尸"), "first battle onboarding must accurately explain double-tap target lock")
			_expect(not battle.wave_toast_label.text.contains("点僵尸可锁定"), "first battle onboarding must not describe a double-tap lock as a single tap")
		_verify_xp_bar_single_track(battle)
		_expect(battle.has_node("Hud/CharacterSkillButton"), "battle must expose character active skill button")
		_expect(str(battle.character_active_id) != "", "battle must configure selected character active skill")
		_expect(battle.has_node("Hud/CharacterSkillButton/IconFrame/SkillIcon"), "character active skill button must render an icon instead of text")
		_expect(not bool(battle.get_node("Hud/CharacterSkillButton/Label").visible), "character active skill button label must stay hidden in icon mode")
		var weapon_row: Dictionary = data_loader.get_row("weapons", battle.weapon_id)
		_expect(not weapon_row.is_empty(), "battle must have selected weapon row for %s" % battle.weapon_id)
		# Affinity element is auto-seeded as Lv.1; physical weapons leave the bar empty.
		var element := str(weapon_row.get("element", "physical"))
		var expected_seed := 0 if element == "" or element == "physical" else 1
		_expect(battle.get_node("Hud/SkillSlots").get_child_count() == expected_seed, "battle skill slots must show seeded affinity skill for %s weapon element" % element)
		if battle.get_node("Hud/SkillSlots").get_child_count() > 0:
			var first_slot := battle.get_node("Hud/SkillSlots").get_child(0)
			_expect(first_slot.has_node("HBox/IconBox/Icon"), "skill slot must render a bounded icon")
			var first_slot_icon := first_slot.get_node("HBox/IconBox/Icon") as TextureRect
			_expect(first_slot_icon != null, "skill slot icon must be a TextureRect")
			_expect(first_slot_icon.size.x <= 80.0 and first_slot_icon.size.y <= 80.0, "skill slot icon must stay bounded, got %s" % str(first_slot_icon.size))
		_expect(battle.has_node("Hud/WaveToast"), "battle must expose wave warning toast")
		_expect(battle.has_node("Hud/ObjectivePanel"), "battle must expose objective panel")
		_expect(not battle.get_node("Hud/ObjectivePanel").visible, "battle objective panel must not cover the combat lane by default")
		_expect(not battle.get_node("Hud/ObjectivePanel/Title").text.contains("level_"), "battle objective title must not expose internal level id")
		_expect(battle.get_node("Hud/ObjectivePanel/Body").text != "", "battle objective panel must explain the current goal")
		_expect(battle.pending_spawns.size() > 0 or battle.get_node("EnemyLayer").get_child_count() > 0, "battle must queue or spawn enemies for %s" % battle.level_id)
		if battle.level_id == "level_001":
			_verify_manual_target_lock_battle(battle)
			_verify_manual_aim_battle_priority(battle)
			_verify_multi_shot_targeting(battle)
			_verify_combat_information_density(battle)
			_verify_barrier_visual_runtime(battle)
			await _verify_base_attack_runtime(battle)
			_verify_pause_freezes_battle(battle)
			await _verify_runtime_skill_hints(battle)
			_verify_wave_toast_wrapping(battle)
			var cd_before := float(battle.character_active_cd)
			battle._on_character_skill_pressed()
			_expect(float(battle.character_active_cd) > cd_before, "character active skill must trigger and enter cooldown")
		if battle.get_node("EnemyLayer").get_child_count() > 0:
			var first_enemy := battle.get_node("EnemyLayer").get_child(0)
			_expect(first_enemy.has_node("HpBar"), "enemy must render hp bar")
			var expected_runtime_hp_floor := float(battle.level.get("base_hp_ref", 50)) * float(battle.level.get("difficulty_coef", 1.0)) * float(battle._wave_hp_coef(1)) * 0.55
			_expect(float(first_enemy.max_hp) >= expected_runtime_hp_floor, "enemy hp must scale with base_hp_ref; got %.1f expected floor %.1f on %s" % [float(first_enemy.max_hp), expected_runtime_hp_floor, battle.level_id])
			if battle.level_id == "level_001":
				battle._show_card_offer()
				await process_frame
				_verify_card_offer_full_pause(battle)
				await _verify_all_skill_offer_copy_layouts(battle)
				await _verify_card_offer_same_frame_rebuild(battle)
				var paused_fire_counter := {"count": 0}
				battle.turret.fired.connect(func(_origin: Vector2, _direction: Vector2) -> void:
					paused_fire_counter["count"] = int(paused_fire_counter.get("count", 0)) + 1
				)
				battle.turret.cooldown = 0.0
				battle.turret._physics_process(0.6)
				_expect(int(paused_fire_counter.get("count", 0)) == 0, "turret must not fire while card offer pauses battle")
				var cards := battle.get_node("Hud/CardPanel/Cards")
				_expect(cards.get_child_count() == 3, "card offer must render three cards")
				var first_card := cards.get_child(0)
				_expect(first_card.has_node("Icon") or first_card.get_child_count() >= 4, "card must render icon and text children")
				var first_card_icon := first_card.get_node("Icon") as TextureRect
				_expect(first_card_icon != null, "card icon must be a TextureRect")
				var first_card_icon_frame := first_card.get_node("IconFrame") as PanelContainer
				_expect(first_card_icon.size == Vector2(178, 178), "card icon must use the final enlarged 178px visual ruler, got %s" % str(first_card_icon.size))
				_expect(first_card_icon_frame != null and first_card_icon_frame.size == Vector2(196, 196), "card icon frame must enlarge with the skill image")
				var first_card_title := first_card.get_node("Title") as Label
				_expect(first_card_title.position.x >= first_card_icon_frame.position.x + first_card_icon_frame.size.x + 20.0, "enlarged card icon must retain at least 20px before the text lane")
				first_card.emit_signal("mouse_entered")
				await process_frame
				_expect(battle.get_node("Hud/SkillHintOverlay").visible, "card hover must show an in-game skill explanation")
				first_card.emit_signal("mouse_exited")
				await process_frame
				_expect(not battle.get_node("Hud/SkillHintOverlay").visible, "card hover exit must hide the skill explanation")
				battle._show_card_detail("skill_split_shot")
				await process_frame
				_expect(battle.get_node("Hud/CardPanel/DetailOverlay").visible, "card long-press detail overlay must open")
				var detail_panel := battle.get_node("Hud/CardPanel/DetailOverlay/Panel") as Control
				var detail_close := detail_panel.get_node("CloseButton") as Control
				var detail_body := detail_panel.get_node("Body") as Label
				var detail_levels := detail_panel.get_node("AllLevelsBody") as Label
				var detail_desc := detail_panel.get_node("DescBody") as Label
				var detail_tags := detail_panel.get_node("TagsBody") as Label
				_expect(detail_panel.clip_contents, "card detail panel must clip content inside the designed modal")
				_expect(detail_body.text != "" and not detail_body.text.contains("全部等级"), "card detail current-value block must not contain the whole old combined body")
				_expect((detail_levels.text.contains("等级1") or detail_levels.text.contains("Lv.1")) and detail_levels.position.y + detail_levels.size.y <= detail_desc.position.y - 8.0, "card detail all-levels block must be separated from description")
				_expect(detail_desc.position.y + detail_desc.size.y <= detail_tags.position.y - 8.0, "card detail description must not overlap tag line")
				_expect(detail_tags.position.y + detail_tags.size.y <= detail_close.position.y - 8.0, "card detail tags must not overlap close button")
				_expect(detail_close.position.y + detail_close.size.y <= detail_panel.size.y - 8.0, "card detail close button must stay inside modal bounds")
				var localization_manager := root.get_node("/root/LocalizationManager")
				var original_detail_language := str(localization_manager.current_language)
				for detail_language in ["zh", "en"]:
					localization_manager.apply_language(detail_language, false)
					battle._show_card_detail("skill_split_shot")
					await process_frame
					_expect(detail_levels.get_theme_font_size("font_size") == UiKit.scaled_font_size(battle.CARD_DETAIL_LEVELS_BODY_FONT_SIZE), "%s all-level rows must retain the larger mobile type size" % detail_language)
					_expect(detail_desc.get_theme_font_size("font_size") == UiKit.scaled_font_size(battle.CARD_DETAIL_DESCRIPTION_FONT_SIZE), "%s skill description must retain the larger mobile type size" % detail_language)
					_expect(detail_tags.get_theme_font_size("font_size") == UiKit.scaled_font_size(battle.CARD_DETAIL_TAGS_FONT_SIZE), "%s skill tags must retain the larger mobile type size" % detail_language)
					for text_contract in [
						[detail_levels, "all-level rows"],
						[detail_desc, "description"],
						[detail_tags, "tags"],
					]:
						var detail_label := text_contract[0] as Label
						var detail_font_size := detail_label.get_theme_font_size("font_size")
						var required_text_size := detail_label.get_theme_font("font").get_multiline_string_size(
							detail_label.text,
							HORIZONTAL_ALIGNMENT_LEFT,
							detail_label.size.x - 8.0,
							detail_font_size
						)
						_expect(required_text_size.y <= detail_label.size.y - 8.0, "%s %s must fit without vertical clipping" % [detail_language, str(text_contract[1])])
				localization_manager.apply_language(original_detail_language, false)
				battle._hide_card_detail()
				_dismiss_card_offer_for_smoke(battle)
				for enemy in battle.get_node("EnemyLayer").get_children():
					enemy.free()
				battle.pending_spawns.clear()
				battle.active_spawning = false
				battle.wave_index = battle.wave_total
				battle.xp = battle.next_xp_offer
				_expect(not battle._try_show_xp_card_offer(), "final wave clear must not show a late card offer")
				battle.wave_index = battle.wave_total - 1
				battle.xp = int(ceil(float(battle.next_xp_offer) * battle.PREFINAL_CARD_OFFER_XP_RATIO))
				_expect(battle._maybe_show_pre_final_card_offer(), "pre-final wave transition should offer a near-ready skill card")
				_dismiss_card_offer_for_smoke(battle)
			battle.queue_free()
			await process_frame

	var result := _instance("res://meta/result/result.tscn")
	root.add_child(result)
	result.setup(router, {
		"level_id": "level_001", "victory": true, "stars": 3, "gold": 120, "xp": 12,
		"cards_selected": 3, "target_card_picks": 4,
		"battle_report": {
			"duration_seconds": 95.0, "damage_total": 12800.0,
			"damage_by_element": {"fire": 9600.0}, "top_element": "fire",
			"crit_damage": 3200.0, "weak_damage": 4800.0, "kills": 42,
			"boss_kills": 1, "base_damage_taken": 12, "base_damage_prevented": 8,
			"control_seconds": 6.5, "active_skill_casts": 3, "max_kill_streak": 11,
		}
	})
	await process_frame
	await process_frame
	var result_content := result.get_node("Content") as Control
	var result_rect := result_content.get_global_rect()
	var result_center_y := result_rect.position.y + result_rect.size.y * 0.5
	_expect(absf(result_center_y - (root.size.y * 0.5 + result.RESULT_VISUAL_NUDGE_Y)) <= 36.0, "result stack must be visually centered on iPhone canvas; center=%.1f" % result_center_y)
	_expect(result_rect.position.y >= 0.0 and result_rect.end.y <= root.size.y, "result stack must remain fully visible after centering")
	_expect(result.get_node("Content/HeroCard/HeroBox/LevelName").text.contains("001 城市缺口"), "result must show player-facing level name")
	_expect(not result.get_node("Content/HeroCard/HeroBox/LevelName").text.contains("level_001"), "result must not expose internal level id")
	_expect(result.get_node("Content/RewardRow/GoldCard/GoldBox/GoldVBox/GoldValue").text.contains("120"), "result gold card must show earned gold")
	_expect(result.get_node("Content/RewardRow/XpCard/XpBox/XpVBox/XpValue").text.contains("12"), "result xp card must show earned xp")
	var result_gold_card := result.get_node("Content/RewardRow/GoldCard") as Control
	var result_xp_card := result.get_node("Content/RewardRow/XpCard") as Control
	var result_gold_icon := result.get_node("Content/RewardRow/GoldCard/GoldBox/GoldIcon") as Control
	var result_xp_icon := result.get_node("Content/RewardRow/XpCard/XpBox/XpIcon") as Control
	var result_hint_card := result.get_node("Content/HintCard") as Control
	var result_hint_icon := result.get_node("Content/HintCard/HintBox/HintIcon") as Control
	_expect(result_gold_icon.get_global_rect().position.x - result_gold_card.get_global_rect().position.x >= result.RESULT_REWARD_SIDE_PADDING - 0.1, "result gold icon must clear the decorated card border")
	_expect(result_xp_icon.get_global_rect().position.x - result_xp_card.get_global_rect().position.x >= result.RESULT_REWARD_SIDE_PADDING - 0.1, "result xp icon must clear the decorated card border")
	_expect(result_hint_icon.get_global_rect().position.x - result_hint_card.get_global_rect().position.x >= result.RESULT_HINT_SIDE_PADDING - 0.1, "result standing-power star must clear the hint-strip border")
	_expect(result_gold_icon.custom_minimum_size == result.RESULT_REWARD_ICON_SIZE and result_xp_icon.custom_minimum_size == result.RESULT_REWARD_ICON_SIZE, "result reward icons must share one visual size")
	_expect(absf(result_gold_icon.get_global_rect().get_center().y - result_xp_icon.get_global_rect().get_center().y) <= 0.1, "result reward icons must share one vertical baseline")
	_expect(result.get_node("Content/HintCard/HintBox/Hint").text != "", "result must show next action hint")
	_expect(result.get_node("Content/HintCard/HintBox/Hint").text.contains("本局选卡 3/4"), "result must show the real card-pick count separately from power")
	var challenge_result := _instance("res://meta/result/result.tscn")
	root.add_child(challenge_result)
	challenge_result.setup(router, {
		"level_id": "level_004", "victory": true, "challenge": true, "stars": 3,
		"gold": 120, "xp": 12, "power": 23,
		"recommended_power": 27,
		"cards_selected": 2, "target_card_picks": 5,
	})
	await process_frame
	var challenge_result_hint := (challenge_result.get_node("Content/HintCard/HintBox/Hint") as Label).text
	_expect(challenge_result_hint.contains("有效战力 23"), "challenge result must reuse the one player-facing Effective Power value")
	_expect(challenge_result_hint.contains("挑战推荐 27"), "challenge result must name the fixed challenge recommendation explicitly")
	_expect(not challenge_result_hint.contains("本局最终") and not challenge_result_hint.contains("基准"), "challenge result must not reintroduce a second power concept")
	_expect(challenge_result_hint.contains("本局选卡 2/5"), "challenge result must report actual card progress without converting it into a second power")
	_expect(challenge_result_hint.contains("超过历史最高"), "challenge result must explain incremental star rewards in player-facing language")
	challenge_result.queue_free()
	_expect(result.has_node("Content/ReportButton") and result.has_node("Content/ReportPanel"), "result must expose an expandable battle report")
	_expect(result.has_node("Content/HeroCard/HeroBox/OutcomePanel"), "result must expose a compact hero outcome showcase")
	var result_outcome_panel := result.get_node("Content/HeroCard/HeroBox/OutcomePanel") as Control
	var result_hero_name := result.get_node("Content/HeroCard/HeroBox/OutcomePanel/OutcomeRow/OutcomeCopy/HeroName") as Label
	_expect(result_hero_name.text.contains("完成防守"), "victory outcome showcase must communicate the hero result")
	_expect(result_hero_name.custom_minimum_size.y >= result.RESULT_OUTCOME_HERO_LINE_HEIGHT, "result hero line must reserve its two-line fallback height")
	_expect(result_hero_name.autowrap_mode != TextServer.AUTOWRAP_OFF and result_hero_name.max_lines_visible == 2, "result hero line must wrap safely before reaching the decorated edge")
	_expect(result_hero_name.clip_text, "result hero line must retain final clipping protection")
	_expect(result_outcome_panel.get_global_rect().end.x - result_hero_name.get_global_rect().end.x >= result.RESULT_OUTCOME_HORIZONTAL_SAFE - 0.1, "result hero line must keep at least %.0fpx right-side clearance" % result.RESULT_OUTCOME_HORIZONTAL_SAFE)
	var result_portrait_clip := result.get_node("Content/HeroCard/HeroBox/OutcomePanel/OutcomeRow/Portrait") as TextureRect
	var result_portrait_bust := result_portrait_clip.get_node_or_null("BustImage") as TextureRect
	_expect(result_portrait_clip.clip_contents, "result hero showcase must use a deliberate half-body viewport")
	_expect(result_portrait_bust != null and result_portrait_bust.texture != null, "result hero showcase must render a themed half-body portrait")
	_expect(str(result_portrait_bust.get_meta("result_portrait_framing", "")) == "aligned_half_body", "result hero showcase must declare the aligned half-body contract")
	var result_theme_manager := root.get_node("/root/ThemeManager")
	for theme_id in ["default", "neon_tempest", "infernal_dominion", "polar_aurora", "gilded_eclipse"]:
		for character_id in ["vanguard", "blaze", "frost", "volt"]:
			var character_row: Dictionary = data_loader.get_row("characters", character_id)
			var fallback_path := str(character_row.get("portrait", character_row.get("icon", "")))
			var frameless_fallback := fallback_path.replace("_icon.png", "_portrait_frameless.png")
			if frameless_fallback != "" and ResourceLoader.exists(frameless_fallback):
				fallback_path = frameless_fallback
			var portrait_path := str(result_theme_manager.resolve_character_portrait_for_theme(character_id, theme_id, fallback_path))
			var portrait_texture := load(portrait_path) as Texture2D
			_expect(portrait_texture != null, "%s/%s result portrait must resolve" % [theme_id, character_id])
			if portrait_texture == null:
				continue
			var portrait_layout: Dictionary = result._result_portrait_layout(portrait_texture)
			var visible_rect: Rect2 = portrait_layout.get("visible_rect", Rect2())
			_expect(absf(visible_rect.position.y - result.RESULT_PORTRAIT_HEADROOM) <= 0.1, "%s/%s result portrait must preserve exact headroom" % [theme_id, character_id])
			_expect(absf(visible_rect.size.y - result.RESULT_PORTRAIT_VISIBLE_HEIGHT) <= 0.1, "%s/%s result portrait must share one human-height ruler" % [theme_id, character_id])
			_expect(absf(visible_rect.get_center().x - result.RESULT_PORTRAIT_WINDOW_SIZE.x * 0.5) <= 0.1, "%s/%s result portrait must center its visible silhouette" % [theme_id, character_id])
			_expect((portrait_layout.get("size", Vector2.ZERO) as Vector2).y > result.RESULT_PORTRAIT_WINDOW_SIZE.y, "%s/%s result portrait must be a genuine half-body crop" % [theme_id, character_id])
	_expect((result.get_node("Background") as TextureRect).texture != null, "result must inherit the current level environment background")
	_expect(result.get_node("Content/ReportPanel/ReportBox/Overview").text.contains("1:35"), "battle report must format combat duration")
	_expect(result.get_node("Content/ReportPanel/ReportBox/Output").text.contains("火焰"), "battle report must show dominant damage element")
	result._on_report_pressed()
	await process_frame
	await process_frame
	_expect(result.get_node("Content/ReportPanel").visible, "battle report button must expand report details")
	var expanded_rect := result_content.get_global_rect()
	_expect(expanded_rect.position.y >= 0.0 and expanded_rect.end.y <= root.size.y, "expanded battle report must remain inside the iPhone canvas")
	result._on_report_pressed()
	_expect(result.has_node("Content/Actions/PrimaryRow/UpgradeButton/UpgradeLabel"), "result must expose recommended upgrade action")
	_expect(result.get_node("Content/Actions/PrimaryRow/UpgradeButton/UpgradeLabel").text != "", "result upgrade action must be labelled")
	_expect(result.has_node("Content/Actions/NextButton"), "result must expose next button")
	_expect(result.has_node("Content/Actions/MapButton"), "result must expose map button")
	_expect(result.has_node("Background"), "result must render themed background")
	result._on_upgrade_pressed()
	_expect(router.last_route == "loadout", "result upgrade action must route to loadout")
	_expect(str(router.last_payload.get("level_id", "")) == "level_001", "result upgrade action must keep current level in loadout")
	_expect(str(router.last_payload.get("return_to", "")) == "result", "result upgrade action must mark loadout as returning to result")
	var upgrade_return_payload: Dictionary = router.last_payload.get("return_payload", {})
	_expect(bool(upgrade_return_payload.get("victory", false)), "result upgrade return payload must preserve victory state")
	_expect(int(upgrade_return_payload.get("stars", 0)) == 3, "result upgrade return payload must preserve star result")
	result.queue_free()
	await process_frame
	var next_result := _instance("res://meta/result/result.tscn")
	root.add_child(next_result)
	next_result.setup(router, {"level_id": "level_003", "next_level": "level_002", "victory": true, "stars": 3, "gold": 0, "xp": 0})
	await process_frame
	_expect(next_result.next_level == "level_004", "result must normalize level_003 next target to level_004")
	next_result._on_next_pressed()
	_expect(router.last_route == "loadout", "result next button must route to loadout")
	_expect(str(router.last_payload.get("level_id", "")) == "level_004", "result next button must route level_003 clear to level_004, got %s" % str(router.last_payload))
	_expect(str(router.last_payload.get("return_to", "")) == "result", "result next loadout must still return to result")
	var next_return_payload: Dictionary = router.last_payload.get("return_payload", {})
	_expect(str(next_return_payload.get("level_id", "")) == "level_003", "result next return payload must preserve cleared result level")
	next_result.queue_free()
	var endless_result := _instance("res://meta/result/result.tscn")
	root.add_child(endless_result)
	endless_result.setup(router, {"level_id": "level_076", "victory": false, "endless": true, "endless_loop": 3, "stars": 1, "gold": 24454, "xp": 4556})
	await process_frame
	await process_frame
	_expect(endless_result.get_node("Content/HeroCard/HeroBox/Title").text == "无限尸潮", "endless result must keep the main title short enough for mobile safe width")
	_expect(endless_result.get_node("Content/HeroCard/HeroBox/LevelName").text.contains("坚持 3 轮"), "endless result subtitle must carry loop count")
	_expect(endless_result.get_node("Content/RewardRow/GoldCard/GoldBox/GoldVBox/GoldValue").text == "+24.5k", "large result gold rewards must use compact k formatting")
	_expect(not endless_result.get_node("Content/HeroCard/HeroBox/StarRow").visible, "endless result must not display campaign/challenge stars")
	_expect(not endless_result.get_node("Content/RewardRow/XpCard").visible, "endless result must not display XP rewards")
	_expect(endless_result.get_node("Content/HintCard/HintBox/Hint").text.contains("只结算金币"), "endless result copy must explain gold-only rewards")
	endless_result.queue_free()
	var recovered_result := _instance("res://meta/result/result.tscn")
	root.add_child(recovered_result)
	router.run_context = {"level_id": "level_003"}
	recovered_result.setup(router, {"victory": true, "stars": 3, "gold": 0, "xp": 0})
	await process_frame
	_expect(recovered_result.level_id == "level_003", "result must recover missing level_id from router run_context")
	_expect(recovered_result.next_level == "level_004", "result must not default missing level_id to level_001")
	recovered_result.queue_free()
	router.queue_free()
	audio_manager.release_for_tests()
	for tween in get_processed_tweens():
		tween.kill()
	UiKit.release_cached_resources_for_tests()
	SequenceVfx.release_cached_resources_for_tests()
	StatusVfxControllerScript.release_cached_resources_for_tests()
	settings_manager.settings = smoke_settings_snapshot
	Engine.time_scale = 1.0
	for i in range(4):
		await process_frame
	print("M1 smoke test passed")
	call_deferred("_quit_success")

func _quit_success() -> void:
	quit(0)

func _instance(path: String) -> Node:
	var packed := load(path) as PackedScene
	_expect(packed != null, "scene must load: %s" % path)
	return packed.instantiate()

func _verify_level20_boss_hp_modes(router: Node, data_loader: Node) -> void:
	var level_row: Dictionary = data_loader.get_row("levels", "level_020")
	_expect(not level_row.is_empty(), "level_020 must exist for boss HP escalation regression")
	var boss_id := ""
	for wave_var in level_row.get("waves", []):
		var wave: Dictionary = wave_var if wave_var is Dictionary else {}
		if str(wave.get("boss", "")) != "":
			boss_id = str(wave.get("boss", ""))
			break
	_expect(boss_id != "", "level_020 must include a boss spawn for boss HP escalation regression")
	var boss_row: Dictionary = data_loader.get_row("bosses", boss_id)
	_expect(not boss_row.is_empty(), "level_020 boss row must resolve: %s" % boss_id)

	var normal_battle := _instance("res://gameplay/battle/battle.tscn")
	normal_battle.setup(router, {"level_id": "level_020"})
	root.add_child(normal_battle)
	await process_frame
	await physics_frame
	normal_battle.wave_index = 5
	var normal_boss: Node = normal_battle._spawn_enemy_instance(boss_id, Vector2(540, 190), true)
	var economy: Dictionary = data_loader.get_table("economy")
	var expected_normal_hp := float(boss_row.get("fixed_hp", 0.0))
	var normal_boss_hp := float(normal_boss.max_hp)
	var expected_boss_speed := float(boss_row.get("speed", 80.0)) * float(economy.get("ENEMY_SPEED_MULT", 1.0)) * float(economy.get("BOSS_SPEED_MULT", 1.0))
	_expect(expected_normal_hp > 0.0, "level_020 boss must own a fixed identity durability")
	_expect(absf(normal_boss_hp - expected_normal_hp) <= maxf(1.0, expected_normal_hp * 0.001), "normal level_020 boss must use its fixed per-model durability; got %.1f expected %.1f" % [normal_boss_hp, expected_normal_hp])
	_expect(absf(float(normal_boss.speed) - expected_boss_speed) <= maxf(0.01, expected_boss_speed * 0.001), "boss walking speed must include ENEMY_SPEED_MULT * BOSS_SPEED_MULT; got %.2f expected %.2f" % [float(normal_boss.speed), expected_boss_speed])
	normal_boss.queue_free()
	normal_battle.queue_free()
	await process_frame

	var challenge_battle := _instance("res://gameplay/battle/battle.tscn")
	challenge_battle.setup(router, {"level_id": "level_020", "challenge": true})
	root.add_child(challenge_battle)
	await process_frame
	await physics_frame
	challenge_battle.wave_index = 5
	var challenge_boss: Node = challenge_battle._spawn_enemy_instance(boss_id, Vector2(540, 190), true)
	var challenge_hp_mult := float(challenge_battle._challenge_mult("hp_mult", challenge_battle.CHALLENGE_HP_MULT))
	var expected_challenge_hp := expected_normal_hp * challenge_hp_mult
	var challenge_boss_hp := float(challenge_boss.max_hp)
	_expect(absf(challenge_boss_hp - expected_challenge_hp) <= maxf(1.0, expected_challenge_hp * 0.001), "challenge level_020 boss may apply only the explicit challenge multiplier to fixed durability; got %.1f expected %.1f" % [challenge_boss_hp, expected_challenge_hp])
	_expect(absf(challenge_boss_hp / maxf(normal_boss_hp, 1.0) - challenge_hp_mult) <= 0.01, "challenge boss HP must be normal boss HP * chapter challenge multiplier")
	challenge_boss.queue_free()
	challenge_battle.queue_free()
	await process_frame

func _verify_ice_slow_visual_tint(data_loader: Node) -> void:
	var row: Dictionary = data_loader.get_row("zombies", "zombie_shambler").duplicate(true)
	_expect(not row.is_empty(), "ice slow tint test requires zombie_shambler")
	var enemy := _instance("res://gameplay/enemy/enemy.tscn")
	root.add_child(enemy)
	enemy.setup(row, 1.0, false)
	var sprite := enemy.get_node("Sprite") as Sprite2D
	var base_color := sprite.self_modulate
	enemy.mark_ice_slow_visual(0.35)
	var tint_color := sprite.self_modulate
	_expect(tint_color.b > base_color.b and tint_color.b > tint_color.r, "ice slow visual tint must push slowed zombies toward ice blue")
	enemy._process_element_status(0.4)
	var restored_color := sprite.self_modulate
	_expect(absf(restored_color.r - base_color.r) <= 0.01 and absf(restored_color.g - base_color.g) <= 0.01 and absf(restored_color.b - base_color.b) <= 0.01, "ice slow visual tint must restore after the slow visual timer expires")
	enemy.queue_free()

func _verify_status_vfx_layers(data_loader: Node) -> void:
	var config: Dictionary = data_loader.get_table("status_vfx")
	for status_id in ["fire", "ice", "glacier", "poison", "lightning"]:
		_expect(config.has(status_id), "status VFX config must define %s" % status_id)
	var row: Dictionary = data_loader.get_row("zombies", "zombie_shambler").duplicate(true)
	var enemy := _instance("res://gameplay/enemy/enemy.tscn")
	root.add_child(enemy)
	enemy.setup(row, 20.0, false)
	enemy.call("_apply_element_status", 30.0, "fire", 0.35)
	enemy.call("_apply_element_status", 30.0, "ice", 0.35)
	enemy.call("_apply_element_status", 30.0, "poison", 0.35)
	enemy.call("amplify_character_status", "lightning", 30.0, 3, 0.12)
	enemy.call("_update_status_aura")
	for _frame in range(10):
		await process_frame
	var controller: Node = enemy.get_node_or_null("StatusVfxController")
	_expect(controller != null, "enemy must build the persistent status VFX controller")
	if controller != null:
		var active: Array = controller.call("debug_active_statuses")
		for status_id in ["fire", "ice", "poison", "lightning"]:
			_expect(active.has(status_id), "persistent status VFX must keep %s independently active" % status_id)
			var snapshot: Dictionary = controller.call("debug_layer_snapshot", status_id)
			_expect(not snapshot.is_empty() and float(snapshot.get("alpha", 0.0)) > 0.02, "%s status VFX must render after its entry transition" % status_id)
		enemy.call("set_combat_effect_density", "minimal", false)
		await process_frame
		var minimal_fire: Dictionary = controller.call("debug_layer_snapshot", "fire")
		_expect(bool(minimal_fire.get("ground_visible", false)), "minimal status VFX LOD must preserve the semantic ground contact")
		_expect(not bool(minimal_fire.get("primary_allowed", true)), "minimal status VFX LOD must suppress the body sequence on non-priority enemies")
		enemy.call("set_combat_effect_density", "full", true)
		await process_frame
		var priority_fire: Dictionary = controller.call("debug_layer_snapshot", "fire")
		_expect(bool(priority_fire.get("primary_allowed", false)), "priority status VFX must restore the body sequence")
		_expect(not bool(config.get("fire", {}).get("secondary", true)), "body-attached Inferno burn must use one coherent silhouette instead of a duplicated offset flame")
		_expect(not bool(priority_fire.get("secondary_allowed", false)), "priority burn VFX must not reintroduce a detached secondary flame")
	enemy.set("_burn_dps", 0.0)
	enemy.set("_burn_time", 0.0)
	enemy.call("_refresh_burn", 20.0, 3.0)
	var strong_burn := float(enemy.get("_burn_dps"))
	for _refresh in range(4):
		enemy.call("_refresh_burn", 4.0, 3.0)
	var refreshed_burn := float(enemy.get("_burn_dps"))
	_expect(refreshed_burn < strong_burn * 0.5 and refreshed_burn > 4.0, "weaker burn refreshes must decay the historical peak instead of preserving it forever")
	enemy.call("_process_element_status", 5.0)
	_expect(float(enemy.get("_burn_time")) == 0.0 and float(enemy.get("_burn_dps")) == 0.0, "expired burn must clear both duration and cached DPS")
	if controller != null:
		controller.call("debug_advance", 0.35)
		_expect((controller.call("debug_active_statuses") as Array).is_empty(), "expired status VFX layers must leave no active semantic state")
		for status_id in ["fire", "ice", "poison", "lightning"]:
			var expired: Dictionary = controller.call("debug_layer_snapshot", status_id)
			_expect(not bool(expired.get("visible", true)), "%s status VFX must finish its fade after expiration" % status_id)
	enemy.queue_free()
	await process_frame

func _verify_pet_defense_line_anchor(save_manager: Node, snapshot: Dictionary) -> void:
	var original_size := root.size
	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var test_save: Dictionary = _battle_smoke_loadout(snapshot)
	var unlocks: Dictionary = test_save.get("unlocks", {}).duplicate(true)
	var levels: Array = unlocks.get("levels", []).duplicate()
	for level_no in range(1, 51):
		var level_id := "level_%03d" % level_no
		if not levels.has(level_id):
			levels.append(level_id)
	unlocks["levels"] = levels
	var pets: Array = unlocks.get("pets", []).duplicate()
	if not pets.has("pet_turret_drone"):
		pets.append("pet_turret_drone")
	unlocks["pets"] = pets
	test_save["unlocks"] = unlocks
	var equipment: Dictionary = test_save.get("equipment", {}).duplicate(true)
	equipment["selected_pet"] = "pet_turret_drone"
	equipment["pet_turret_drone"] = maxi(1, int(equipment.get("pet_turret_drone", 1)))
	test_save["equipment"] = equipment
	save_manager.save_data = test_save
	var router := FakeRouter.new()
	root.add_child(router)
	var viewport_heights := [1920, 2046, 2337, 2340, 2348, 2622]
	for viewport_height in viewport_heights:
		root.size = Vector2i(1080, viewport_height)
		await process_frame
		var battle := _instance("res://gameplay/battle/battle.tscn")
		battle.setup(router, {"level_id": "level_001"})
		root.add_child(battle)
		await process_frame
		await process_frame
		var expected_shift := maxf(0.0, float(viewport_height) - 1920.0)
		var context := " at 1080x%d" % viewport_height
		_expect(absf(float(battle.bottom_dock_shift) - expected_shift) <= 0.1, "battle base group must bottom-dock" + context)
		_expect(absf(float(battle.BREACH_Y) - (float(battle.BREACH_Y_DESIGN) + expected_shift)) <= 0.1, "breach line must follow the bottom dock" + context)
		_expect(absf(float(battle.CHARACTER_BASE_POSITION.y) - (float(battle.CHARACTER_BASE_Y_DESIGN) + expected_shift)) <= 0.1, "hero must follow the bottom dock" + context)
		var top_bar := battle.get_node("Hud/TopBar") as Control
		var bottom_bar := battle.get_node("Hud/BottomBar") as Control
		var gold_icon := battle.get_node("Hud/BottomBar/GoldIcon") as Control
		var gold_label := battle.get_node("Hud/BottomBar/GoldLabel") as Control
		var xp_icon := battle.get_node("Hud/BottomBar/XpIcon") as Control
		var xp_bar := battle.get_node("Hud/BottomBar/XpBar") as Control
		var hp_bar := battle.get_node("Hud/BottomBar/BaseHpBar") as Control
		var skill_slots := battle.get_node("Hud/SkillSlots") as Control
		var active_skill := battle.get_node("Hud/CharacterSkillButton") as Control
		var pause_button := battle.get_node("PauseLayer/PauseButton") as Control
		var speed_button := battle.get_node("PauseLayer/SpeedButton") as Control
		_expect(absf(bottom_bar.offset_top - (1792.0 + expected_shift)) <= 0.1, "bottom HUD must follow the bottom dock" + context)
		_expect(absf(gold_icon.position.y - 42.0) <= 0.1 and absf(gold_label.position.y - 36.0) <= 0.1, "gold counter must use the lowered bottom resource row" + context)
		_expect(absf(xp_icon.position.y - 47.0) <= 0.1 and absf(xp_bar.position.y - 41.0) <= 0.1, "XP counter must use the lowered bottom resource row" + context)
		_expect(absf(hp_bar.position.y - 41.0) <= 0.1, "base HP must share the lowered bottom resource row" + context)
		_expect(maxf(gold_label.position.y + gold_label.size.y, maxf(xp_bar.position.y + xp_bar.size.y, hp_bar.position.y + hp_bar.size.y)) <= bottom_bar.size.y + 0.1, "lowered bottom resources must remain inside the dock" + context)
		_expect(absf(skill_slots.offset_top - (1688.0 + expected_shift)) <= 0.1, "empty skill dock must align one slot row with the active-skill bottom edge" + context)
		_expect(absf(skill_slots.offset_left - 18.0) <= 0.1 and absf(skill_slots.offset_right - 426.0) <= 0.1, "skill slots must stay inside the four-column left-side dock" + context)
		_expect(is_equal_approx(skill_slots.anchor_left, 0.0) and is_equal_approx(skill_slots.anchor_right, 0.0), "skill dock must not inherit a full-width anchor" + context)
		_expect(absf(active_skill.offset_top - (1688.0 + expected_shift)) <= 0.1, "active skill must follow the bottom dock" + context)
		_expect(bottom_bar.offset_bottom <= float(viewport_height) + 0.1, "bottom HUD must remain on-screen" + context)
		_expect(skill_slots.offset_bottom <= float(viewport_height) + 0.1, "skill slots must remain on-screen" + context)
		_expect(active_skill.offset_bottom <= float(viewport_height) + 0.1, "active skill must remain on-screen" + context)
		_expect(speed_button.visible, "speed button must be visible after level 30" + context)
		_expect(absf(pause_button.offset_top - speed_button.offset_top) <= 0.1 and absf(pause_button.offset_bottom - speed_button.offset_bottom) <= 0.1, "pause and speed controls must share a top row" + context)
		_expect(pause_button.offset_right <= top_bar.offset_left + 0.1, "pause control must not overlap the wave bar" + context)
		_expect(speed_button.offset_left >= 1080.0 + top_bar.offset_right - 0.1, "speed control must not overlap the wave bar" + context)
		_expect(speed_button.offset_right <= 1080.0 + 0.1, "speed control must remain on-screen" + context)
		var toast_position: Vector2 = battle._wave_toast_target_position()
		_expect(toast_position.y >= top_bar.offset_bottom + 21.9, "battle hints must clear the wave bar" + context)
		_expect(battle.pet_sprite != null, "battle must spawn equipped pet for line-anchor regression" + context)
		var expected_anchor: Vector2 = battle._pet_anchor_position()
		_expect(absf(expected_anchor.x - 800.0) <= 0.1, "pet must keep the enlarged hero's right-side breathing room" + context)
		_expect(battle.pet_sprite.position.y <= expected_anchor.y + 0.1 and battle.pet_sprite.position.y >= expected_anchor.y - 10.0, "pet must stay on the defense-line anchor hover band%s, got %.1f expected %.1f" % [context, battle.pet_sprite.position.y, expected_anchor.y])
		battle._update_pet_animation(0.016)
		_expect(battle.pet_sprite.position.y <= expected_anchor.y + 0.1 and battle.pet_sprite.position.y >= expected_anchor.y - 10.0, "pet idle float must stay attached to the defense-line anchor" + context)
		battle.queue_free()
		await process_frame
	router.queue_free()
	root.size = original_size
	save_manager.save_data = original_save
	await process_frame

func _verify_underpower_confirmation(save_manager: Node, snapshot: Dictionary) -> void:
	save_manager.save_data = save_manager._default_save()
	var router := FakeRouter.new()
	root.add_child(router)
	var loadout := _instance("res://meta/loadout/loadout.tscn")
	loadout.setup(router, {"level_id": "level_099", "challenge": true})
	root.add_child(loadout)
	await process_frame
	_expect(loadout._is_severely_underpowered(), "fresh equipment against the final challenge must deterministically exercise the severe-power guard")
	var start_button := loadout.find_child("StartButton", true, false) as TextureButton
	var start_label := start_button.get_node("Label") as Label
	_expect(start_label.text.contains("有效战力严重不足"), "severe-power challenge entry must warn before the first tap")
	start_button.emit_signal("pressed")
	_expect(router.last_started_challenge_level == "", "the first severe-power tap must not start combat")
	_expect(start_label.text.contains("再次点击"), "the first severe-power tap must arm an explicit second confirmation")
	start_button.emit_signal("pressed")
	_expect(router.last_started_challenge_level == "level_099", "the second severe-power tap must honor the player's deliberate confirmation")
	loadout.queue_free()
	router.queue_free()
	save_manager.save_data = snapshot.duplicate(true)
	await process_frame

func _verify_medic_pet_repair_runtime(data_loader: Node, save_manager: Node, snapshot: Dictionary) -> void:
	var medic: Dictionary = data_loader.get_row("pets", "pet_medic_drone")
	_expect(not medic.is_empty() and str(medic.get("role", "")) == "repair", "medical pet must keep the repair role")
	var max_level := int(medic.get("max_level", 30))
	var level_offset := float(max_level - 1)
	var wave_ratio := float(medic.get("heal_per_wave_ratio", 0.0)) + float(medic.get("level_wave_heal_ratio_growth", 0.0)) * level_offset
	var repair_ratio := float(medic.get("repair_ratio", 0.0)) + float(medic.get("level_repair_ratio_growth", 0.0)) * level_offset
	var emergency_ratio := float(medic.get("emergency_heal_ratio", 0.0)) + float(medic.get("level_emergency_heal_growth", 0.0)) * level_offset
	_expect(wave_ratio >= 0.075, "max medical pet wave preparation must remain meaningful at late-game base HP")
	_expect(repair_ratio >= 0.016, "max medical pet periodic repair must remain meaningful")
	_expect(emergency_ratio >= 0.12, "max medical pet emergency rescue must restore a visible low-HP chunk")

	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var test_save: Dictionary = _battle_smoke_loadout(snapshot)
	var unlocks: Dictionary = test_save.get("unlocks", {}).duplicate(true)
	var pets: Array = unlocks.get("pets", []).duplicate()
	if not pets.has("pet_medic_drone"):
		pets.append("pet_medic_drone")
	unlocks["pets"] = pets
	test_save["unlocks"] = unlocks
	var equipment: Dictionary = test_save.get("equipment", {}).duplicate(true)
	equipment["selected_pet"] = "pet_medic_drone"
	equipment["pet_medic_drone"] = max_level
	test_save["equipment"] = equipment
	save_manager.save_data = test_save
	# design/28 乘法口径:维修宠物的治疗成长通过生存乘区进战力,直接断言乘区随等级增长。
	var max_medic_survival := float(save_manager._pet_repair_survival_multiplier(medic, max_level))
	var level_one_medic_survival := float(save_manager._pet_repair_survival_multiplier(medic, 1))
	_expect(max_medic_survival > level_one_medic_survival + 0.03, "medical pet survival multiplier must account for repair growth, not only passive stats; L1=%.3f max=%.3f" % [level_one_medic_survival, max_medic_survival])
	equipment["pet_medic_drone"] = max_level
	save_manager.save_data["equipment"] = equipment

	var router := FakeRouter.new()
	root.add_child(router)
	var battle := _instance("res://gameplay/battle/battle.tscn")
	var audio_manager := root.get_node("/root/AudioManager")
	battle.setup(router, {"level_id": "level_099"})
	root.add_child(battle)
	await process_frame
	await physics_frame
	_expect(battle.pet_sprite != null and battle.pet_data.get("role", "") == "repair", "battle must spawn the equipped medical pet")
	var hp_max := int(battle.base_hp_max)
	_expect(hp_max >= 1000, "late-game medical pet regression needs a scaled base HP pool")

	battle.base_hp = int(round(float(hp_max) * 0.60))
	battle.pet_repair_cooldown = 0.0
	battle.pet_emergency_cooldown = 999.0
	var periodic_before := int(battle.base_hp)
	battle._process_repair_pet(0.01)
	var expected_periodic := int(round(float(hp_max) * repair_ratio))
	_expect(int(battle.base_hp) - periodic_before == expected_periodic, "periodic medical repair must scale from max base HP")
	_expect(float(battle.pet_repair_cooldown) >= float(medic.get("repair_interval", 18.0)) - 0.1, "periodic repair must respect its authored cooldown")

	battle.base_hp = int(round(float(hp_max) * 0.30))
	battle.pet_repair_cooldown = 999.0
	battle.pet_emergency_cooldown = 0.0
	var emergency_before := int(battle.base_hp)
	battle._process_repair_pet(0.01)
	var expected_emergency := int(round(float(hp_max) * emergency_ratio))
	_expect(int(battle.base_hp) - emergency_before == expected_emergency, "low-HP emergency rescue must scale from max base HP")
	_expect(float(battle.pet_emergency_cooldown) >= float(medic.get("emergency_cooldown", 45.0)) - 0.1, "emergency rescue must enter its authored cooldown")

	battle.base_hp = int(round(float(hp_max) * 0.50))
	var wave_before := int(battle.base_hp)
	battle._apply_wave_start_support()
	var expected_wave := int(round(
		float(medic.get("heal_per_wave", 0.0)) * (1.0 + float(medic.get("level_heal_growth", 0.0)) * level_offset)
		+ float(hp_max) * wave_ratio
	))
	_expect(int(battle.base_hp) - wave_before == expected_wave, "wave preparation must combine flat and max-HP repair")
	battle.base_hp = hp_max - 1
	_expect(int(battle._apply_pet_base_heal(expected_emergency, "封顶验证", true)) == 1 and int(battle.base_hp) == hp_max, "all medical repairs must clamp to max base HP")

	battle.queue_free()
	router.queue_free()
	save_manager.save_data = original_save
	await process_frame

func _verify_pet_skill_runtime(data_loader: Node, save_manager: Node, snapshot: Dictionary) -> void:
	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var test_save: Dictionary = _battle_smoke_loadout(snapshot)
	var unlocks: Dictionary = test_save.get("unlocks", {}).duplicate(true)
	var pets: Array = unlocks.get("pets", []).duplicate()
	if not pets.has("pet_turret_drone"):
		pets.append("pet_turret_drone")
	unlocks["pets"] = pets
	test_save["unlocks"] = unlocks
	var equipment: Dictionary = test_save.get("equipment", {}).duplicate(true)
	equipment["selected_pet"] = "pet_turret_drone"
	equipment["pet_turret_drone"] = 30
	test_save["equipment"] = equipment
	save_manager.save_data = test_save
	var router := FakeRouter.new()
	root.add_child(router)
	var battle := _instance("res://gameplay/battle/battle.tscn")
	battle.setup(router, {"level_id": "level_050"})
	root.add_child(battle)
	await process_frame
	battle.active_spawning = false
	battle.pending_spawns.clear()
	for child in battle.get_node("EnemyLayer").get_children():
		child.queue_free()
	await process_frame
	var targets: Array[FakeAimTarget] = []
	for i in range(6):
		var target := FakeAimTarget.new()
		target.position = Vector2(390.0 + float(i % 3) * 120.0, 640.0 + float(i / 3) * 90.0)
		target.breach_damage = 15 + i
		battle.get_node("EnemyLayer").add_child(target)
		targets.append(target)

	battle.pet_data = data_loader.get_row("pets", "pet_turret_drone")
	battle.pet_level = int(battle.pet_data.get("max_level", 30))
	battle.pet_skill_cooldown = 0.0
	battle._process_pet_skill(0.01)
	_expect(float(battle.pet_skill_timer) > 3.5, "turret pet overheat must gain duration with level")
	_expect(float(battle.pet_skill_cooldown) >= 12.9, "turret pet overheat must enter authored cooldown")

	for target in targets:
		target.hits = 0
		target.total_damage = 0.0
	battle.pet_data = data_loader.get_row("pets", "pet_fire_imp")
	battle.pet_level = int(battle.pet_data.get("max_level", 30))
	battle.pet_skill_cooldown = 0.0
	battle._process_pet_skill(0.01)
	var fire_hits := 0
	var fire_status_ok := false
	for target in targets:
		if target.hits > 0:
			fire_hits += 1
			fire_status_ok = fire_status_ok or (target.last_element == "fire" and target.last_status_strength > 1.0)
	_expect(fire_hits >= 3, "fire pet molten burst must visibly damage a local group")
	_expect(fire_status_ok, "fire pet skill must carry authored burn strength")

	for target in targets:
		target.hits = 0
		target.total_damage = 0.0
	battle.pet_data = data_loader.get_row("pets", "pet_frost_wisp")
	battle.pet_level = int(battle.pet_data.get("max_level", 30))
	battle.pet_skill_cooldown = 0.0
	battle._process_pet_skill(0.01)
	var frost_hits := 0
	for target in targets:
		if target.hits > 0:
			frost_hits += 1
	_expect(frost_hits == targets.size(), "frost pet domain must cover the staged control group at max level")
	_expect(targets[0].last_element == "ice" and targets[0].last_status_strength > 1.4, "frost pet domain must scale its control strength")

	for target in targets:
		target.hits = 0
		target.total_damage = 0.0
	battle.pet_data = data_loader.get_row("pets", "pet_volt_orb")
	battle.pet_level = int(battle.pet_data.get("max_level", 30))
	battle.pet_skill_cooldown = 0.0
	battle._process_pet_skill(0.01)
	var volt_hits := 0
	var volt_element_ok := false
	for target in targets:
		if target.hits > 0:
			volt_hits += 1
			volt_element_ok = volt_element_ok or target.last_element == "lightning"
	_expect(volt_hits == 5, "volt pet overload must grow from 3 to 5 targets without a hard runtime cap")
	_expect(volt_element_ok, "volt pet overload must retain lightning semantics")

	battle.pet_data = data_loader.get_row("pets", "pet_collector")
	battle.pet_level = int(battle.pet_data.get("max_level", 30))
	var gold_before := int(battle.gold)
	var salvage := int(battle._apply_pet_wave_salvage())
	_expect(salvage > 0 and int(battle.gold) == gold_before + salvage, "collector pet must convert every wave into direct salvage gold")

	battle.queue_free()
	router.queue_free()
	save_manager.save_data = original_save
	await process_frame

func _verify_environment_audio_mix(data_loader: Node) -> void:
	# 阶段 67：按环境的动态混音。契约有三条——每个环境都必须声明 audio_mix；
	# 进入战斗时套用对应环境；离开战斗必须归零，否则菜单/结算会挂着战场混响。
	var audio_manager := root.get_node_or_null("/root/AudioManager")
	_expect(audio_manager != null, "AudioManager must be autoloaded")
	if audio_manager == null:
		return
	var environments: Dictionary = data_loader.get_table("environments")
	var wets := {}
	for environment_id in environments.keys():
		var mix_value: Variant = (environments[environment_id] as Dictionary).get("audio_mix", {})
		_expect(mix_value is Dictionary and not (mix_value as Dictionary).is_empty(), "%s must declare an audio_mix" % str(environment_id))
		if mix_value is Dictionary:
			var mix: Dictionary = mix_value
			var wet := float(mix.get("reverb_wet", 0.0))
			_expect(wet >= 0.0 and wet <= 0.35, "%s reverb_wet must stay inside 0-0.35, got %.2f" % [str(environment_id), wet])
			wets[str(environment_id)] = wet
	_expect(wets.values().min() < wets.values().max(), "environment reverb must actually differ between environments")
	var router := FakeRouter.new()
	root.add_child(router)
	var battle := _instance("res://gameplay/battle/battle.tscn")
	battle.setup(router, {"level_id": "level_075"})
	root.add_child(battle)
	await process_frame
	var applied := str(audio_manager.current_environment_mix_id())
	_expect(applied == str(battle.level.get("env", "")), "entering a battle must apply that environment's audio mix, got '%s'" % applied)
	_expect(audio_manager.sfx_reverb_wet() > 0.0, "the cathedral environment must apply reverb to the SFX bus")
	battle.queue_free()
	await process_frame
	_expect(str(audio_manager.current_environment_mix_id()) == "", "leaving a battle must clear the environment audio mix")
	_expect(absf(audio_manager.sfx_reverb_wet()) <= 0.001, "leaving a battle must reset the SFX reverb to dry")
	router.queue_free()
	await process_frame

func _verify_wave_formation_lanes(data_loader: Node) -> void:
	# 阶段 67：`wave_pattern` 此前 99 关都写了却从来没被运行时读过。这里锁死
	# 五种编队各自的通道契约，避免它再退回成纯标签。只验队形几何，不验数量、
	# 间隔或 HP——那些刻意保持与编队无关。
	var representative := {}
	for level in data_loader.get_table("levels"):
		var pattern := str(level.get("wave_pattern", "standard"))
		if not representative.has(pattern):
			representative[pattern] = str(level.get("id", ""))
	_expect(representative.size() >= 5, "campaign must keep all five wave formations, got %d" % representative.size())
	var router := FakeRouter.new()
	root.add_child(router)
	for pattern in representative.keys():
		var battle := _instance("res://gameplay/battle/battle.tscn")
		battle.setup(router, {"level_id": representative[pattern]})
		root.add_child(battle)
		await process_frame
		var lanes := {}
		for item in battle.pending_spawns:
			var lane := str(item.get("lane", ""))
			lanes[lane] = int(lanes.get(lane, 0)) + 1
		_expect(not battle.pending_spawns.is_empty(), "%s (%s) must queue wave-1 enemies" % [representative[pattern], pattern])
		match str(pattern):
			"rush":
				_expect(lanes.size() == 1 and lanes.has("center"), "rush formation must funnel every spawn down the centre, got %s" % str(lanes))
			"pincer":
				_expect(not lanes.has("center"), "pincer formation must leave the centre lane open, got %s" % str(lanes))
				_expect(lanes.has("left") and lanes.has("right"), "pincer formation must use both flanks, got %s" % str(lanes))
			"siege":
				_expect(lanes.size() >= 3, "siege formation must fill the whole line, got %s" % str(lanes))
			"escort":
				_expect(lanes.has("left") and lanes.has("right"), "escort formation must flank, got %s" % str(lanes))
		battle.queue_free()
		await process_frame
	router.queue_free()
	await process_frame

func _verify_wave_spawn_distribution() -> void:
	# Random must not mean four independent samples landing in one pile. Exercise
	# the live picker with a fixed seed so the release gate proves corridor bounds,
	# broad coverage, recent-history limits and low consecutive clustering.
	var router := FakeRouter.new()
	root.add_child(router)
	var battle := _instance("res://gameplay/battle/battle.tscn")
	battle.setup(router, {"level_id": "level_001"})
	root.add_child(battle)
	await process_frame
	battle.active_spawning = false
	battle.pending_spawns.clear()
	for enemy in battle.get_node("EnemyLayer").get_children():
		enemy.queue_free()
	await process_frame
	seed(8802)
	var expected_bounds := {
		"left": Vector2(150.0, 430.0),
		"center": Vector2(300.0, 780.0),
		"right": Vector2(650.0, 930.0),
		"spread": Vector2(150.0, 930.0),
	}
	for lane in expected_bounds.keys():
		battle.recent_spawn_positions.clear()
		var xs: Array[float] = []
		var close_consecutive := 0
		var previous_x := -9999.0
		for _sample_index in range(24):
			var position: Vector2 = battle._next_enemy_spawn_position(str(lane), false)
			var bounds: Vector2 = expected_bounds[lane]
			_expect(position.x >= bounds.x and position.x <= bounds.y, "%s spawn x must stay in its authored corridor, got %.1f" % [str(lane), position.x])
			_expect(position.y >= 158.0 and position.y <= 222.0, "%s spawn y jitter must stay inside the safe entry band, got %.1f" % [str(lane), position.y])
			if previous_x > -9000.0 and absf(position.x - previous_x) < 64.0:
				close_consecutive += 1
			previous_x = position.x
			xs.append(position.x)
		var span: float = (expected_bounds[lane] as Vector2).y - (expected_bounds[lane] as Vector2).x
		var coverage: float = (float(xs.max()) - float(xs.min())) / span
		_expect(coverage >= 0.85, "%s spawns must cover most of their corridor, got %.1f%%" % [str(lane), coverage * 100.0])
		_expect(close_consecutive <= 3, "%s spawns must avoid repeated horizontal piles, got %d close pairs" % [str(lane), close_consecutive])
		_expect(battle.recent_spawn_positions.size() == battle.SPAWN_RECENT_HISTORY, "spawn anti-cluster history must stay bounded")
	var boss_bounds: Vector2 = battle._spawn_lane_x_bounds("center", true)
	var boss_position: Vector2 = battle._next_enemy_spawn_position("center", true)
	_expect(boss_position.x >= boss_bounds.x and boss_position.x <= boss_bounds.y and absf(boss_position.y - 190.0) <= 0.1, "boss entrance must keep its tighter authored focal corridor")
	battle.queue_free()
	router.queue_free()
	await process_frame

func _verify_variant_wave_one_spawns(data_loader: Node) -> void:
	# 阶段 67：elite / treasure 变体关的第 1 波曾因出怪循环缩进错误而一只不刷
	# （21 关共 442 只敌人从未出现），而所有平衡模型都把它们算在内。这里锁死
	# 数据侧契约：变体关的第 1 波必须真的编排了敌人。运行时是否照单出怪由
	# _verify_wave_formation_lanes 一起守。
	var variant_levels := 0
	for level in data_loader.get_table("levels"):
		var variant := str(level.get("variant", ""))
		if variant != "elite" and variant != "treasure":
			continue
		variant_levels += 1
		var waves: Array = level.get("waves", [])
		_expect(not waves.is_empty(), "%s must author waves" % str(level.get("id", "")))
		var first_wave: Dictionary = waves[0]
		var queued := 0
		for group in first_wave.get("spawns", []):
			queued += int(group.get("count", 0))
		_expect(queued > 0, "%s wave 1 must spawn enemies despite its variant toast" % str(level.get("id", "")))
	_expect(variant_levels >= 20, "elite/treasure variants must remain part of the campaign, got %d" % variant_levels)

func _verify_repeat_clear_xp_decay(save_manager: Node, snapshot: Dictionary) -> void:
	# design/24 收尾：重复通关经验递减 100% / 50% / 25%。倍率表只允许存在于
	# data/economy.json.repeat_clear_xp_mult；普通关与挑战各自独立计数；失败不计数。
	var original: Dictionary = save_manager.save_data.duplicate(true)
	save_manager.save_data = snapshot.duplicate(true)
	save_manager.save_data["level_clear_counts"] = {}
	save_manager.save_data["challenge_clear_counts"] = {}
	var expected := [1.0, 0.5, 0.25, 0.25]
	for index in range(expected.size()):
		var multiplier: float = save_manager.get_repeat_clear_xp_mult("level_003", false)
		_expect(absf(multiplier - expected[index]) < 0.001, "repeat clear %d must award %.2fx xp, got %.2fx" % [index + 1, expected[index], multiplier])
		save_manager.apply_level_result({"level_id": "level_003", "victory": true, "stars": 2, "gold": 0, "xp": 0}, false)
	var challenge_multiplier: float = save_manager.get_repeat_clear_xp_mult("level_003", true)
	_expect(absf(challenge_multiplier - 1.0) < 0.001, "challenge clears must count separately from normal clears")
	var defeat_count: int = save_manager.get_clear_count("level_010", false)
	save_manager.apply_level_result({"level_id": "level_010", "victory": false, "stars": 0, "gold": 0, "xp": 0}, false)
	_expect(int(save_manager.get_clear_count("level_010", false)) == defeat_count, "a defeat must not consume a clear count")
	save_manager.save_data.erase("level_clear_counts")
	var legacy: float = save_manager.get_repeat_clear_xp_mult("level_050", false)
	_expect(absf(legacy - 1.0) < 0.001, "a legacy save without clear counts must still award full xp")
	save_manager.save_data = original

func _verify_collection_star_curve(data_loader: Node) -> void:
	var table_names := ["characters", "weapons", "armors", "chips", "pets"]
	var total := 0
	var maximum := 0
	for table_name in table_names:
		var prices := []
		for row in data_loader.get_table(table_name).values():
			if str(row.get("premium_entitlement", "")) != "":
				continue
			var price := int(row.get("unlock_cost_star", 0))
			if price <= 0:
				continue
			prices.append(price)
			total += price
			maximum = maxi(maximum, price)
		_expect(not prices.is_empty(), "%s must keep a paid collection progression" % table_name)
		_expect(prices.min() >= 8 and prices.max() <= 16, "%s prices must stay in the 8-16 star band" % table_name)
		_expect(prices.max() <= prices.min() * 2, "%s prices must not exceed a 2x category curve" % table_name)
	# design/24 Phase 5 moved weapon_venomlauncher from 10 to the 8-star band
	# floor after poison weakness coverage grew from 2 levels to 6, so the
	# reviewed curve total is 316 rather than 318. The band and 2x-curve
	# invariants above are unchanged.
	_expect(total == 316, "launch collection star total must stay at the reviewed 316-star curve")
	_expect(maximum == 16, "no single collection unlock may exceed 16 stars")
	_expect(total - 99 * 3 == 19, "normal campaign must leave only 19 challenge stars for full collection")

func _verify_owned_store_upgrade_cost(save_manager: Node) -> void:
	# The owned-upgrade row needs thunder to actually be owned; build that state
	# explicitly instead of inheriting whatever the ambient local save holds.
	var original: Dictionary = save_manager.save_data.duplicate(true)
	var owned_save: Dictionary = save_manager._default_save()
	var owned_entitlements: Dictionary = owned_save.get("entitlements", {}).duplicate(true)
	var verified: Array = owned_entitlements.get("verified", []).duplicate()
	if not verified.has("ent_arsenal_thunder"):
		verified.append("ent_arsenal_thunder")
	owned_entitlements["verified"] = verified
	owned_save["entitlements"] = owned_entitlements
	save_manager.save_data = owned_save
	var store := _instance("res://meta/store/store.tscn")
	var owned_row := store.call("_owned_item_row", "weapons", "weapon", "weapon_apocalypse_thunder") as PanelContainer
	_expect(owned_row != null, "owned premium equipment must build its upgrade row")
	if owned_row != null:
		var upgrade_buttons := owned_row.find_children("*", "Button", true, false)
		var upgrade := upgrade_buttons[0] as Button if not upgrade_buttons.is_empty() else null
		_assert_resource_cost(
			upgrade,
			"gold",
			save_manager.get_item_upgrade_cost("weapons", "weapon_apocalypse_thunder"),
			"owned premium equipment upgrade"
		)
		owned_row.free()
	store.free()
	save_manager.save_data = original

func _verify_quantified_premium_loadout_offer(data_loader: Node, save_manager: Node, purchase_manager: Node) -> void:
	var original: Dictionary = save_manager.save_data.duplicate(true)
	var test_save: Dictionary = save_manager._default_save()
	test_save["levels_progress"] = {"level_030": 1}
	test_save["entitlements"] = {"verified": [], "last_sync_unix": 0}
	test_save["commerce"] = {"mock_receipts": [], "mock_last_transaction_unix": 0}
	var equipment: Dictionary = test_save.get("equipment", {})
	equipment.merge({
		"blaze": 40,
		"weapon_scattergun": 36,
		"armor_kevlar": 21,
		"chip_attack": 21,
		"pet_turret_drone": 15,
		"selected_character": "blaze",
		"selected_weapon": "weapon_scattergun",
		"selected_armor": "armor_kevlar",
		"selected_chip": "chip_attack",
		"selected_pet": "pet_turret_drone",
	}, true)
	test_save["equipment"] = equipment
	save_manager.save_data = test_save
	purchase_manager._catalog = data_loader.get_table("store_products")
	purchase_manager.reconcile_access(false)
	var equipment_before: Dictionary = save_manager.save_data.get("equipment", {}).duplicate(true)
	var offer: Dictionary = purchase_manager.premium_power_offer_for_level("level_080", 0.15, 0.0)
	_expect(str(offer.get("series_id", "")) == "inferno", "fire weakness plus a revealed unowned Inferno series must produce the quantified loadout recommendation")
	_expect(float(offer.get("uplift_ratio", 0.0)) >= 0.15, "premium loadout recommendation must be backed by at least +15% effective power")
	_expect(str(offer.get("weakness", "")) == "fire", "premium loadout recommendation must match the stage primary weakness")
	_expect(save_manager.save_data.get("equipment", {}) == equipment_before, "premium power projection must restore the player's exact equipped build")
	var projected_build: Dictionary = offer.get("build", {})
	_expect(int(projected_build.get("weapon", {}).get("level", 0)) == 36, "premium weapon projection must use the current weapon level")
	_expect(int(projected_build.get("armor", {}).get("level", 0)) == 21, "premium armor projection must use the current armor level")
	_expect(purchase_manager.premium_power_offer_for_level("level_084", 0.15, 0.0).is_empty(), "a paid series with the wrong element must not be recommended")

	var router := FakeRouter.new()
	root.add_child(router)
	var loadout := _instance("res://meta/loadout/loadout.tscn")
	loadout.setup(router, {"level_id": "level_080"})
	root.add_child(loadout)
	await process_frame
	await process_frame
	var premium_button := loadout.find_child("PremiumCounterSuggestion", true, false) as Button
	_expect(premium_button != null, "loadout summary must render the quantified premium recommendation inline")
	if premium_button != null:
		var recommendation_text := premium_button.find_child("RecommendationText", true, false) as Label
		_expect(recommendation_text != null and recommendation_text.text.contains("有效战力"), "quantified premium line must state the effective-power premise")
		var projected_power_text := str(loadout.call("_format_power_number", int(offer.get("projected_power", 0))))
		_expect(recommendation_text != null and recommendation_text.text.contains(projected_power_text), "quantified premium line must render the complete projected power value")
		_expect(str(loadout.call("_format_power_number", 1428)) == "1,428", "quantified premium power must retain all digits when adding thousands separators")
		premium_button.emit_signal("pressed")
		_expect(router.last_route == "store", "premium recommendation must route to the store")
		_expect(str(router.last_payload.get("focus_series_id", "")) == "inferno", "premium recommendation must focus the matching store series")
	loadout.queue_free()
	router.queue_free()
	await process_frame

	test_save["entitlements"] = {"verified": ["ent_arsenal_inferno"], "last_sync_unix": 1}
	save_manager.save_data = test_save
	_expect(purchase_manager.premium_power_offer_for_level("level_080", 0.15, 0.0).is_empty(), "an already-owned premium arsenal must never remain in purchase recommendations")
	test_save["entitlements"] = {"verified": [], "last_sync_unix": 0}
	test_save["levels_progress"] = {}
	save_manager.save_data = test_save
	_expect(purchase_manager.premium_power_offer_for_level("level_080", 0.15, 0.0).is_empty(), "an unrevealed premium series must never appear in purchase recommendations")
	save_manager.save_data = original
	purchase_manager.reconcile_access(false)

func _verify_quantified_premium_result_offer(data_loader: Node, save_manager: Node, purchase_manager: Node) -> void:
	var original: Dictionary = save_manager.save_data.duplicate(true)
	var test_save: Dictionary = save_manager._default_save()
	test_save["levels_progress"] = {"level_030": 1, "level_070": 1}
	test_save["entitlements"] = {"verified": [], "last_sync_unix": 0}
	test_save["commerce"] = {"mock_receipts": [], "mock_last_transaction_unix": 0}
	var equipment: Dictionary = test_save.get("equipment", {})
	equipment.merge({
		"blaze": 40,
		"weapon_scattergun": 36,
		"armor_kevlar": 21,
		"chip_attack": 21,
		"pet_turret_drone": 15,
		"selected_character": "blaze",
		"selected_weapon": "weapon_scattergun",
		"selected_armor": "armor_kevlar",
		"selected_chip": "chip_attack",
		"selected_pet": "pet_turret_drone",
	}, true)
	test_save["equipment"] = equipment
	save_manager.save_data = test_save
	purchase_manager._catalog = data_loader.get_table("store_products")
	purchase_manager.reconcile_access(false)
	var shared_offer: Dictionary = purchase_manager.premium_power_offer_for_level("level_070", 0.0, 1.2)
	_expect(not shared_offer.is_empty(), "result recommendation fixture must reuse the shared premium power calculation")
	var router := FakeRouter.new()
	root.add_child(router)

	var defeat := _instance("res://meta/result/result.tscn")
	root.add_child(defeat)
	defeat.setup(router, {"level_id": "level_070", "victory": false, "stars": 0, "gold": 0, "xp": 0})
	await process_frame
	await process_frame
	var defeat_hint := defeat.get_node("Content/HintCard/HintBox/Hint") as Label
	_expect(not defeat._premium_offer.is_empty(), "a defeat must show an unlocked unowned premium set that lifts the stage ratio to at least 1.2")
	_expect(float(defeat._premium_offer.get("result_ratio", 0.0)) >= 1.2, "result premium guidance must be backed by a projected ratio of at least 1.2")
	_expect(defeat_hint.text.contains("升级到与你现役同级后") and defeat_hint.text.contains("有效战力"), "defeat guidance must state the same-level premise and quantified effective power")
	defeat._open_premium_store(str(defeat._premium_offer.get("series_id", "")))
	_expect(router.last_route == "store" and str(router.last_payload.get("focus_series_id", "")) == "inferno", "result premium guidance must open the matching store series")
	_expect(str(router.last_payload.get("return_to", "")) == "result", "store opened from a result must return to the same result")
	defeat.queue_free()
	await process_frame

	var one_star := _instance("res://meta/result/result.tscn")
	root.add_child(one_star)
	one_star.setup(router, {"level_id": "level_070", "victory": true, "stars": 1, "gold": 0, "xp": 0})
	await process_frame
	_expect(not one_star._premium_offer.is_empty(), "a one-star victory may show quantified premium guidance")
	one_star.queue_free()
	await process_frame

	for stars in [2, 3]:
		var clean_victory := _instance("res://meta/result/result.tscn")
		root.add_child(clean_victory)
		clean_victory.setup(router, {"level_id": "level_070", "victory": true, "stars": stars, "gold": 0, "xp": 0})
		await process_frame
		_expect(clean_victory._premium_offer.is_empty(), "%d-star victory must never show a purchase recommendation" % stars)
		clean_victory.queue_free()
		await process_frame

	test_save["entitlements"] = {"verified": ["ent_arsenal_inferno"], "last_sync_unix": 1}
	save_manager.save_data = test_save
	purchase_manager.reconcile_access(false)
	var owned_result := _instance("res://meta/result/result.tscn")
	root.add_child(owned_result)
	owned_result.setup(router, {"level_id": "level_070", "victory": false, "stars": 0, "gold": 0, "xp": 0})
	await process_frame
	_expect(owned_result._premium_offer.is_empty(), "an owned premium set must never appear in result purchase guidance")
	owned_result.queue_free()
	router.queue_free()
	await process_frame
	save_manager.save_data = original
	purchase_manager.reconcile_access(false)

func _verify_local_purchase_flow(data_loader: Node, save_manager: Node, purchase_manager: Node) -> void:
	var original: Dictionary = save_manager.save_data.duplicate(true)
	var theme_manager := root.get_node("/root/ThemeManager")
	var testflight_preview: bool = bool(theme_manager.preview_access_enabled())
	var test_save: Dictionary = original.duplicate(true)
	test_save["commerce"] = {"mock_receipts": [], "mock_last_transaction_unix": 0}
	test_save["entitlements"] = {"verified": [], "last_sync_unix": 0}
	test_save["cosmetics"] = {
		"selected_theme": "default",
		"character_outfits": {
			"vanguard": "follow_theme",
			"blaze": "follow_theme",
			"frost": "follow_theme",
			"volt": "follow_theme",
		},
	}
	# The smoke suite may run after an interactive or screenshot session that has
	# already cleared the campaign and maxed a hero. Build the store-gate fixture
	# from an explicitly fresh progression state so host-local save data cannot
	# make premium series visible before the assertions below reveal them.
	test_save["levels_progress"] = {}
	var fresh_equipment: Dictionary = test_save.get("equipment", {}).duplicate(true)
	for character_id in ["vanguard", "blaze", "frost", "volt"]:
		fresh_equipment[character_id] = 1
	test_save["equipment"] = fresh_equipment
	save_manager.save_data = test_save
	purchase_manager._catalog = data_loader.get_table("store_products")
	purchase_manager.reconcile_access(false)
	_expect(purchase_manager.catalog_series_ids() == ["thunder", "inferno", "absolute_zero", "golden_law"], "premium catalog must contain all four authored series")
	_expect(purchase_manager.store_series_ids().is_empty(), "fresh premium catalog must hide every unrevealed series, including in TestFlight")
	for locked_series_id in purchase_manager.catalog_series_ids():
		_expect(purchase_manager.display_offer_ids(locked_series_id).is_empty(), "%s must not produce player-facing cards before its reveal gate" % locked_series_id)
		_expect(purchase_manager.visible_offer_ids(locked_series_id).is_empty(), "%s must not authorize purchase before its reveal gate" % locked_series_id)
	test_save["levels_progress"] = {"level_030": 1}
	_expect(purchase_manager.store_series_ids() == ["inferno"], "Infernal Dominion must first appear after clearing level 30")
	test_save["levels_progress"]["level_050"] = 1
	_expect(purchase_manager.store_series_ids() == ["thunder", "inferno"], "Neon Tempest must first appear after clearing level 50")
	test_save["levels_progress"]["level_069"] = 1
	_expect(not purchase_manager.store_series_ids().has("absolute_zero"), "Polar Aurora must remain hidden after clearing level 69")
	test_save["levels_progress"]["level_070"] = 1
	_expect(purchase_manager.store_series_ids() == ["thunder", "inferno", "absolute_zero"], "Polar Aurora must first appear after clearing level 70")
	var absolute_zero_set: Dictionary = data_loader.get_row("premium_sets", "set_apocalypse_absolute_zero")
	_expect(str(absolute_zero_set.get("dominance_zh", "")).begins_with("主宰区间：碎冰连爆与减速控场"), "Absolute Zero store positioning must lead with its authored Shatter and slow-control mechanics")
	_expect(str(absolute_zero_set.get("dominance_en", "")).begins_with("Dominance Range: Shatter chains and slow control"), "Absolute Zero English positioning must match the mechanics-led claim")
	test_save["levels_progress"]["level_089"] = 1
	_expect(not purchase_manager.store_series_ids().has("golden_law"), "Golden Law must remain hidden after clearing level 89")
	test_save["levels_progress"]["level_090"] = 1
	_expect(purchase_manager.store_series_ids() == ["thunder", "inferno", "absolute_zero", "golden_law"], "Golden Law must become purchase-authorized only after level 99 clear plus any hero at level 40")
	_expect(purchase_manager.set_id_for_series("thunder") == "set_apocalypse_thunder", "series routing must resolve the Thunder set from data")
	_expect(purchase_manager.set_id_for_series("inferno") == "set_apocalypse_inferno", "series routing must resolve the Inferno set from data")
	_expect(purchase_manager.set_id_for_series("absolute_zero") == "set_apocalypse_absolute_zero", "series routing must resolve the Absolute Zero set from data")
	_expect(purchase_manager.set_id_for_series("golden_law") == "set_apocalypse_golden_law", "series routing must resolve the Golden Law set from data")
	_expect(purchase_manager.theme_id_for_product("com.gaojiasheng.zombiefire.theme.neon_tempest") == "neon_tempest", "product routing must resolve its theme from data")
	_expect(purchase_manager.theme_id_for_product("com.gaojiasheng.zombiefire.theme.infernal_dominion") == "infernal_dominion", "Inferno product routing must resolve its own theme")
	_expect(purchase_manager.theme_id_for_product("com.gaojiasheng.zombiefire.theme.polar_aurora") == "polar_aurora", "Absolute Zero product routing must resolve its own theme")
	_expect(purchase_manager.theme_id_for_product("com.gaojiasheng.zombiefire.theme.gilded_eclipse") == "gilded_eclipse", "Golden Law product routing must resolve Gilded Eclipse")
	_expect(purchase_manager.visible_offer_ids().has("com.gaojiasheng.zombiefire.arsenal.thunder_complete"), "fresh store must offer the complete 6.99 arsenal package")
	_expect(purchase_manager.visible_offer_ids().has("com.gaojiasheng.zombiefire.arsenal.inferno_complete"), "fresh store must offer the Inferno 6.99 complete package")
	_expect(purchase_manager.visible_offer_ids().has("com.gaojiasheng.zombiefire.arsenal.absolute_zero_complete"), "fresh store must offer the Absolute Zero 6.99 complete package")
	_expect(purchase_manager.visible_offer_ids().has("com.gaojiasheng.zombiefire.arsenal.golden_law_complete"), "eligible endgame store must offer the Golden Law 6.99 complete package")
	_expect(purchase_manager.visible_offer_ids("thunder").size() == 2, "fresh Thunder series must expose theme plus complete offers")
	_expect(purchase_manager.visible_offer_ids("inferno").size() == 2, "fresh Inferno series must expose theme plus complete offers")
	_expect(purchase_manager.visible_offer_ids("absolute_zero").size() == 2, "fresh Absolute Zero series must expose theme plus complete offers")
	_expect(purchase_manager.visible_offer_ids("golden_law").size() == 2, "fresh Golden Law series must expose theme plus complete offers")
	_expect(purchase_manager.mock_purchase("com.gaojiasheng.zombiefire.theme.neon_tempest", false), "local theme purchase must complete")
	_expect(purchase_manager.has_entitlement("ent_theme_neon_tempest"), "theme purchase must grant the theme entitlement")
	var unlocked_progress: Dictionary = test_save["levels_progress"].duplicate(true)
	var unlocked_vanguard_level := int(test_save["equipment"].get("vanguard", 1))
	test_save["levels_progress"] = {}
	test_save["equipment"]["vanguard"] = 1
	_expect(purchase_manager.store_series_ids().has("thunder"), "owned premium series must remain visible after campaign progress rolls backward")
	test_save["levels_progress"] = unlocked_progress
	test_save["equipment"]["vanguard"] = unlocked_vanguard_level
	_expect(theme_manager.select_character_outfit("vanguard", "neon_tempest", false), "owned themes must be selectable per hero")
	_expect(theme_manager.effective_character_theme_id("vanguard") == "neon_tempest", "an explicit hero outfit must override the default global theme")
	_expect(purchase_manager.visible_offer_ids().has("com.gaojiasheng.zombiefire.arsenal.thunder_upgrade"), "theme owner must see the 4.99 upgrade package")
	_expect(not purchase_manager.visible_offer_ids().has("com.gaojiasheng.zombiefire.arsenal.thunder_complete"), "theme owner must not be double-charged through the complete package")
	_expect(purchase_manager.mock_purchase("com.gaojiasheng.zombiefire.arsenal.thunder_upgrade", false), "local arsenal upgrade must complete")
	_expect(purchase_manager.has_entitlement("ent_arsenal_thunder"), "arsenal purchase must grant its entitlement")
	_expect(save_manager.is_item_unlocked("weapon", "weapon_apocalypse_thunder"), "arsenal purchase must unlock its weapon")
	_expect(purchase_manager.equip_complete_set("set_apocalypse_thunder"), "owned arsenal must equip all four pieces through an explicit set id")
	_expect(save_manager.get_selected("pet") == "pet_apocalypse_tempest", "full-set equip must include the premium pet")
	_expect(theme_manager.apply_theme_to_all_characters("neon_tempest"), "apply-full-look must select the theme and reset every hero to Follow Global")
	for character_id in ["vanguard", "blaze", "frost", "volt"]:
		_expect(save_manager.get_character_outfit(character_id) == "follow_theme", "apply-full-look must include %s" % character_id)
	_expect(purchase_manager.mock_purchase("com.gaojiasheng.zombiefire.arsenal.inferno_complete", false), "Inferno complete purchase must complete without requiring the theme first")
	_expect(purchase_manager.has_entitlement("ent_theme_infernal_dominion"), "Inferno complete package must grant the theme entitlement in the same receipt")
	_expect(purchase_manager.has_entitlement("ent_arsenal_inferno"), "Inferno complete package must grant the arsenal entitlement in the same receipt")
	_expect(save_manager.is_item_unlocked("weapon", "weapon_apocalypse_inferno"), "Inferno complete package must unlock its weapon")
	_expect(purchase_manager.equip_complete_set("set_apocalypse_inferno"), "Inferno complete package must equip its explicit four-piece set")
	_expect(save_manager.get_selected("pet") == "pet_apocalypse_phoenix", "Inferno full-set equip must include the Ember Phoenix")
	_expect(theme_manager.active_theme_id() == "infernal_dominion", "Inferno full-set equip must apply its matching global theme")
	_expect(theme_manager.select_character_outfit("vanguard", "neon_tempest", false), "owned Neon and Infernal themes must remain mixable per hero")
	_expect(theme_manager.select_character_outfit("volt", "infernal_dominion", false), "owned Infernal theme must be selectable per hero")
	_expect(theme_manager.effective_character_theme_id("vanguard") == "neon_tempest", "mixed Neon outfit must override the Infernal global theme")
	_expect(purchase_manager.mock_purchase("com.gaojiasheng.zombiefire.arsenal.absolute_zero_complete", false), "Absolute Zero complete purchase must complete without requiring the theme first")
	_expect(purchase_manager.has_entitlement("ent_theme_polar_aurora"), "Absolute Zero complete package must grant the Polar Aurora theme entitlement")
	_expect(purchase_manager.has_entitlement("ent_arsenal_absolute_zero"), "Absolute Zero complete package must grant its arsenal entitlement")
	_expect(save_manager.is_item_unlocked("weapon", "weapon_apocalypse_absolute_zero"), "Absolute Zero package must unlock its weapon")
	_expect(purchase_manager.equip_complete_set("set_apocalypse_absolute_zero"), "Absolute Zero package must equip its explicit four-piece set")
	_expect(save_manager.get_selected("pet") == "pet_apocalypse_aurora", "Absolute Zero full-set equip must include the Aurora Wisp")
	_expect(theme_manager.active_theme_id() == "polar_aurora", "Absolute Zero full-set equip must apply Polar Aurora")
	_expect(theme_manager.select_character_outfit("blaze", "infernal_dominion", false), "all three owned themes must remain independently selectable per hero")
	_expect(theme_manager.select_character_outfit("frost", "polar_aurora", false), "Polar Aurora must be selectable per hero")
	_expect(theme_manager.effective_character_theme_id("frost") == "polar_aurora", "explicit Polar Aurora outfit must override the global theme")
	_expect(purchase_manager.mock_purchase("com.gaojiasheng.zombiefire.arsenal.golden_law_complete", false), "Golden Law complete purchase must complete at the endgame gate")
	_expect(purchase_manager.has_entitlement("ent_theme_gilded_eclipse"), "Golden Law complete package must grant Gilded Eclipse")
	_expect(purchase_manager.has_entitlement("ent_arsenal_golden_law"), "Golden Law complete package must grant its arsenal entitlement")
	_expect(save_manager.is_item_unlocked("weapon", "weapon_apocalypse_golden_law"), "Golden Law package must unlock Sovereign Verdict")
	_expect(purchase_manager.equip_complete_set("set_apocalypse_golden_law"), "Golden Law package must equip its explicit four-piece set")
	_expect(save_manager.get_selected("pet") == "pet_apocalypse_skyfalcon", "Golden Law full-set equip must include the Aureate Skyfalcon")
	_expect(theme_manager.active_theme_id() == "gilded_eclipse", "Golden Law full-set equip must apply Gilded Eclipse")
	_expect(theme_manager.select_character_outfit("volt", "gilded_eclipse", false), "Gilded Eclipse must be independently selectable per hero")
	_expect(purchase_manager.restore_mock_purchases() == 5, "restore must reconcile all five independent local receipts across four product series")
	_expect(purchase_manager.reset_mock_purchases_for_series("golden_law", false) == 1, "series reset must remove only the Golden Law complete receipt")
	_expect(not purchase_manager.has_entitlement("ent_arsenal_golden_law"), "Golden Law reset must revoke its arsenal")
	_expect(purchase_manager.has_entitlement("ent_arsenal_absolute_zero"), "Golden Law reset must preserve Absolute Zero access")
	_expect(purchase_manager.reset_mock_purchases_for_series("absolute_zero", false) == 1, "series reset must remove only the Absolute Zero complete receipt")
	_expect(not purchase_manager.has_entitlement("ent_arsenal_absolute_zero"), "Absolute Zero reset must revoke its arsenal access")
	_expect(not purchase_manager.has_entitlement("ent_theme_polar_aurora"), "Absolute Zero reset must revoke its bundled theme")
	_expect(purchase_manager.has_entitlement("ent_arsenal_inferno"), "Absolute Zero reset must preserve Inferno arsenal access")
	_expect(
		save_manager.get_character_outfit("frost") == ("polar_aurora" if testflight_preview else "follow_theme"),
		"revoking Polar Aurora must preserve a TestFlight-preview outfit or reset the production outfit"
	)
	_expect(save_manager.get_character_outfit("blaze") == "infernal_dominion", "revoking Polar Aurora must preserve an owned Infernal outfit")
	_expect(purchase_manager.reset_mock_purchases_for_series("inferno", false) == 1, "series reset must remove only the Inferno complete receipt")
	_expect(not purchase_manager.has_entitlement("ent_arsenal_inferno"), "Inferno series reset must revoke Inferno arsenal access")
	_expect(not purchase_manager.has_entitlement("ent_theme_infernal_dominion"), "Inferno series reset must revoke its bundled theme")
	_expect(purchase_manager.has_entitlement("ent_arsenal_thunder"), "Inferno series reset must preserve Thunder arsenal access")
	_expect(purchase_manager.has_entitlement("ent_theme_neon_tempest"), "Inferno series reset must preserve Neon theme access")
	_expect(save_manager.is_item_unlocked("weapon", "weapon_apocalypse_thunder"), "Inferno series reset must not remove Thunder equipment")
	_expect(not save_manager.is_item_unlocked("weapon", "weapon_apocalypse_inferno"), "Inferno series reset must remove only Inferno equipment")
	_expect(
		save_manager.get_character_outfit("volt") == ("gilded_eclipse" if testflight_preview else "follow_theme"),
		"revoking Infernal must preserve Volt's selected TestFlight-preview Gilded outfit or reset the production outfit"
	)
	_expect(save_manager.get_character_outfit("vanguard") == "neon_tempest", "revoking Infernal must preserve an owned Neon outfit")
	purchase_manager.reset_mock_purchases(false)
	_expect(not purchase_manager.has_entitlement("ent_arsenal_thunder"), "reset must revoke only local mock arsenal access")
	_expect(save_manager.get_selected("weapon") == "weapon_autocannon", "revocation must fall back to the starter weapon")
	_expect(
		save_manager.get_character_outfit("vanguard") == ("neon_tempest" if testflight_preview else "follow_theme"),
		"global reset must preserve TestFlight-preview outfits or reset production paid outfits"
	)
	save_manager.save_data = original
	purchase_manager.reconcile_access(false)
	_verify_multi_series_purchase_routing(data_loader, save_manager, purchase_manager)


func _verify_current_warzone_store_recommendation(data_loader: Node, save_manager: Node, purchase_manager: Node) -> void:
	var original: Dictionary = save_manager.save_data.duplicate(true)
	var test_save: Dictionary = save_manager._default_save()
	test_save["commerce"] = {"mock_receipts": [], "mock_last_transaction_unix": 0}
	test_save["entitlements"] = {"verified": [], "last_sync_unix": 0}
	test_save["levels_progress"] = {"level_030": 3, "level_050": 3, "level_070": 3}
	var unlocked_levels: Array[String] = []
	for level_number in range(1, 61):
		unlocked_levels.append("level_%03d" % level_number)
	var unlocks: Dictionary = test_save.get("unlocks", {}).duplicate(true)
	unlocks["levels"] = unlocked_levels
	test_save["unlocks"] = unlocks
	save_manager.save_data = test_save
	purchase_manager._catalog = data_loader.get_table("store_products")
	purchase_manager.reconcile_access(false)

	var chapter_six_offer: Dictionary = purchase_manager.current_warzone_counter_offer()
	_expect(str(chapter_six_offer.get("series_id", "")) == "thunder", "chapter 6's authored weakness mode must recommend Thunder")
	_expect(str(chapter_six_offer.get("weakness", "")) == "lightning", "chapter 6 store recommendation must derive lightning from level data")
	_expect(int(chapter_six_offer.get("chapter", 0)) == 6, "store recommendation must use the highest unlocked stage's chapter")
	_expect(int(chapter_six_offer.get("weakness_count", 0)) == 3 and int(chapter_six_offer.get("chapter_stage_count", 0)) == 10, "chapter 6 weakness mode must scan all ten authored stages")
	var router := FakeRouter.new()
	root.add_child(router)
	var chapter_six_store := _instance("res://meta/store/store.tscn")
	chapter_six_store.setup(router, {})
	root.add_child(chapter_six_store)
	await process_frame
	await process_frame
	var chapter_six_headers: Array[Control] = []
	var chapter_six_content := chapter_six_store.get_node_or_null("Root/VBox/ScrollWrap/Scroll/Content")
	if chapter_six_content != null:
		for child in chapter_six_content.get_children():
			if child is Control and child.has_meta("store_series_id"):
				chapter_six_headers.append(child as Control)
	_expect(not chapter_six_headers.is_empty() and str(chapter_six_headers[0].get_meta("store_series_id", "")) == "thunder", "matching current-warzone arsenal must move to the top of the store")
	_expect(not chapter_six_headers.is_empty() and bool(chapter_six_headers[0].get_meta("current_warzone_counter", false)), "top matching series must carry the current-warzone counter marker")
	_expect(chapter_six_store.find_child("CurrentWarzoneCounterBadge", true, false) != null, "matching store series must render one inline current-warzone badge")
	chapter_six_store.queue_free()
	await process_frame

	unlocked_levels = []
	for level_number in range(1, 81):
		unlocked_levels.append("level_%03d" % level_number)
	unlocks = test_save.get("unlocks", {}).duplicate(true)
	unlocks["levels"] = unlocked_levels
	test_save["unlocks"] = unlocks
	save_manager.save_data = test_save
	purchase_manager.reconcile_access(false)
	var chapter_eight_offer: Dictionary = purchase_manager.current_warzone_counter_offer()
	_expect(str(chapter_eight_offer.get("series_id", "")) == "inferno", "chapter 8's authored weakness mode must switch the recommendation to Inferno")
	_expect(str(chapter_eight_offer.get("weakness", "")) == "fire" and int(chapter_eight_offer.get("weakness_count", 0)) == 6, "chapter 8 store recommendation must derive its six-stage fire mode from level data")
	var chapter_eight_store := _instance("res://meta/store/store.tscn")
	chapter_eight_store.setup(router, {})
	root.add_child(chapter_eight_store)
	await process_frame
	await process_frame
	var chapter_eight_headers: Array[Control] = []
	var chapter_eight_content := chapter_eight_store.get_node_or_null("Root/VBox/ScrollWrap/Scroll/Content")
	if chapter_eight_content != null:
		for child in chapter_eight_content.get_children():
			if child is Control and child.has_meta("store_series_id"):
				chapter_eight_headers.append(child as Control)
	_expect(not chapter_eight_headers.is_empty() and str(chapter_eight_headers[0].get_meta("store_series_id", "")) == "inferno", "changing campaign progress must data-drive a different store series to the top")
	var inferno_header_count := 0
	var counter_badge_count := 0
	for header in chapter_eight_headers:
		if str(header.get_meta("store_series_id", "")) == "inferno":
			inferno_header_count += 1
		if bool(header.get_meta("current_warzone_counter", false)):
			counter_badge_count += 1
	_expect(inferno_header_count == 1, "reordering the matching series must never duplicate it")
	_expect(counter_badge_count == 1, "the store must render exactly one current-warzone recommendation")
	chapter_eight_store.queue_free()
	await process_frame

	# Chapter 4 is poison-led and has no paid poison arsenal. Preserve authored
	# store order and omit the badge rather than inventing a chapter mapping.
	test_save["levels_progress"] = {"level_030": 3}
	unlocked_levels = []
	for level_number in range(1, 41):
		unlocked_levels.append("level_%03d" % level_number)
	unlocks = test_save.get("unlocks", {}).duplicate(true)
	unlocks["levels"] = unlocked_levels
	test_save["unlocks"] = unlocks
	save_manager.save_data = test_save
	purchase_manager.reconcile_access(false)
	_expect(purchase_manager.current_warzone_counter_offer().is_empty(), "a chapter with no matching paid element must not fabricate a store recommendation")
	var unmatched_store := _instance("res://meta/store/store.tscn")
	unmatched_store.setup(router, {})
	root.add_child(unmatched_store)
	await process_frame
	await process_frame
	_expect(unmatched_store.find_child("CurrentWarzoneCounterBadge", true, false) == null, "a chapter with no matching premium coverage must render no counter badge")
	unmatched_store.queue_free()
	await process_frame

	# Even in a matching chapter, ownership removes the series from sales
	# recommendations while the existing owned visibility path remains intact.
	test_save["levels_progress"] = {"level_030": 3, "level_050": 3, "level_070": 3}
	unlocked_levels = []
	for level_number in range(1, 81):
		unlocked_levels.append("level_%03d" % level_number)
	unlocks = test_save.get("unlocks", {}).duplicate(true)
	unlocks["levels"] = unlocked_levels
	test_save["unlocks"] = unlocks
	test_save["entitlements"] = {"verified": ["ent_arsenal_inferno"], "last_sync_unix": 1}
	save_manager.save_data = test_save
	purchase_manager.reconcile_access(false)
	_expect(purchase_manager.current_warzone_counter_offer().is_empty(), "an already-owned matching arsenal must never be a store sales recommendation")
	var owned_store := _instance("res://meta/store/store.tscn")
	owned_store.setup(router, {})
	root.add_child(owned_store)
	await process_frame
	await process_frame
	_expect(owned_store.find_child("CurrentWarzoneCounterBadge", true, false) == null, "owned matching series must not retain a sales badge")
	var owned_inferno_headers := 0
	var owned_content := owned_store.get_node_or_null("Root/VBox/ScrollWrap/Scroll/Content")
	if owned_content != null:
		for child in owned_content.get_children():
			if child is Control and str(child.get_meta("store_series_id", "")) == "inferno":
				owned_inferno_headers += 1
	_expect(owned_inferno_headers == 1, "owned series visibility must remain single-instance after recommendation filtering")
	owned_store.queue_free()
	router.queue_free()
	await process_frame
	save_manager.save_data = original
	purchase_manager.reconcile_access(false)


func _verify_multi_series_purchase_routing(data_loader: Node, save_manager: Node, purchase_manager: Node) -> void:
	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var original_catalog: Dictionary = purchase_manager._catalog.duplicate(true)
	var original_sets: Dictionary = data_loader.tables.get("premium_sets", {}).duplicate(true)
	var fixture_sets := original_sets.duplicate(true)
	fixture_sets["set_fixture_second"] = {
		"series_id": "fixture_second",
		"entitlement": "ent_fixture_arsenal",
		"theme": "default",
		"theme_entitlement": "ent_fixture_theme",
		"weapon": "fixture_weapon",
		"armor": "fixture_armor",
		"chip": "fixture_chip",
		"pet": "fixture_pet",
	}
	data_loader.tables["premium_sets"] = fixture_sets
	var fixture_catalog := original_catalog.duplicate(true)
	for offer in [
		["fixture.theme", "theme", ["ent_fixture_theme"], 210],
		["fixture.complete", "arsenal_complete", ["ent_fixture_theme", "ent_fixture_arsenal"], 220],
		["fixture.upgrade", "arsenal_upgrade", ["ent_fixture_arsenal"], 230],
	]:
		fixture_catalog[str(offer[0])] = {
			"series_id": "fixture_second",
			"theme_id": "default",
			"arsenal_set_id": "set_fixture_second",
			"kind": str(offer[1]),
			"offer_role": str(offer[1]),
			"grants": offer[2],
			"sort": int(offer[3]),
			"visible_in_mock_store": true,
		}
	purchase_manager._catalog = fixture_catalog
	save_manager.save_data = save_manager._default_save()
	save_manager.save_data["levels_progress"] = {"level_030": 1, "level_050": 1, "level_070": 1, "level_080": 1, "level_090": 1, "level_099": 1}
	save_manager.save_data["equipment"]["vanguard"] = 40
	purchase_manager.reconcile_access(false)
	_expect(purchase_manager.store_series_ids() == ["thunder", "inferno", "absolute_zero", "fixture_second", "golden_law"], "aggregate catalog must expose every eligible independent series in authored offer order")
	_expect(purchase_manager.visible_offer_ids("fixture_second").has("fixture.complete"), "an unowned second series must offer its own complete package")
	_expect(purchase_manager.mock_purchase("fixture.theme", false), "second-series theme purchase must complete independently")
	_expect(purchase_manager.visible_offer_ids("fixture_second").has("fixture.upgrade"), "second-series theme ownership must route only that series to its upgrade")
	_expect(purchase_manager.visible_offer_ids("thunder").has("com.gaojiasheng.zombiefire.arsenal.thunder_complete"), "second-series ownership must not alter Thunder offers")
	_expect(purchase_manager.visible_offer_ids("inferno").has("com.gaojiasheng.zombiefire.arsenal.inferno_complete"), "fixture ownership must not alter Inferno offers")
	_expect(purchase_manager.visible_offer_ids("absolute_zero").has("com.gaojiasheng.zombiefire.arsenal.absolute_zero_complete"), "fixture ownership must not alter Absolute Zero offers")
	_expect(purchase_manager.mock_purchase("fixture.upgrade", false), "second-series arsenal upgrade must complete independently")
	_expect(save_manager.save_data.get("unlocks", {}).get("weapons", []).has("fixture_weapon"), "second-series reconciliation must unlock its own equipment")
	_expect(not purchase_manager.has_entitlement("ent_arsenal_thunder"), "second-series purchase must not grant Thunder")
	purchase_manager.reset_mock_purchases(false)
	_expect(not save_manager.save_data.get("unlocks", {}).get("weapons", []).has("fixture_weapon"), "second-series revocation must remove its own equipment")
	data_loader.tables["premium_sets"] = original_sets
	purchase_manager._catalog = original_catalog
	save_manager.save_data = original_save
	purchase_manager.reconcile_access(false)

func _verify_store_product_preview_contract(data_loader: Node, save_manager: Node) -> void:
	# Launch merchandising must not expose mismatched design boards or battle
	# screenshots. Every theme is a four-outfit roster and every arsenal is the
	# same semantic weapon / armor / chip / pet grid, with alpha-fitted subjects.
	var purchase_manager := root.get_node("/root/PurchaseManager")
	var theme_manager := root.get_node("/root/ThemeManager")
	var localization_manager := root.get_node("/root/LocalizationManager")
	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var original_language := str(localization_manager.current_language)
	var test_save: Dictionary = original_save.duplicate(true)
	test_save["levels_progress"] = {}
	for character_id in ["vanguard", "blaze", "frost", "volt"]:
		test_save["equipment"][character_id] = 1
	test_save["commerce"] = {"mock_receipts": [], "mock_last_transaction_unix": 0}
	test_save["entitlements"] = {"verified": [], "last_sync_unix": 0}
	test_save["cosmetics"] = {
		"selected_theme": "default",
		"character_outfits": {
			"vanguard": "follow_theme",
			"blaze": "follow_theme",
			"frost": "follow_theme",
			"volt": "follow_theme",
		},
	}
	save_manager.save_data = test_save
	purchase_manager.refresh_catalog_and_access()
	theme_manager.refresh_from_save()
	localization_manager.apply_language("en", false)
	var router := FakeRouter.new()
	root.add_child(router)
	var fresh_menu := _instance("res://meta/menu/menu.tscn")
	fresh_menu.setup(router, {})
	root.add_child(fresh_menu)
	await process_frame
	var fresh_store_button := fresh_menu.find_child("StoreButton", true, false) as Control
	_expect(fresh_store_button != null and fresh_store_button.visible, "main menu must keep the arsenal entry available so a fresh player can read its unlock path")
	fresh_menu.queue_free()
	await process_frame

	var selector_script := load("res://ui/appearance_selector.gd") as GDScript
	var fresh_selector := selector_script.new() as CanvasLayer
	root.add_child(fresh_selector)
	fresh_selector.open_global()
	await process_frame
	_expect(fresh_selector.find_child("Theme_default", true, false) != null, "fresh appearance selector must retain the free default theme")
	for hidden_theme_id in ["infernal_dominion", "neon_tempest", "polar_aurora", "gilded_eclipse"]:
		_expect(fresh_selector.find_child("Theme_" + hidden_theme_id, true, false) == null, "%s must be absent from appearance UI before reveal" % hidden_theme_id)
	fresh_selector.queue_free()
	await process_frame

	var fresh_outfit_selector := selector_script.new() as CanvasLayer
	root.add_child(fresh_outfit_selector)
	fresh_outfit_selector.open_character("vanguard")
	await process_frame
	_expect(fresh_outfit_selector.find_child("Outfit_follow_theme", true, false) != null, "fresh outfit selector must retain Follow Global")
	_expect(fresh_outfit_selector.find_child("Outfit_default", true, false) != null, "fresh outfit selector must retain the free default outfit")
	for hidden_theme_id in ["infernal_dominion", "neon_tempest", "polar_aurora", "gilded_eclipse"]:
		_expect(fresh_outfit_selector.find_child("Outfit_" + hidden_theme_id, true, false) == null, "%s must be absent from per-hero outfits before reveal" % hidden_theme_id)
	fresh_outfit_selector.queue_free()
	await process_frame

	var hidden_premium_items := {
		"weapons": [
			"weapon_apocalypse_inferno",
			"weapon_apocalypse_thunder",
			"weapon_apocalypse_absolute_zero",
			"weapon_apocalypse_golden_law",
		],
		"armors": [
			"armor_apocalypse_molten",
			"armor_apocalypse_conductor",
			"armor_apocalypse_permafrost",
			"armor_apocalypse_eternal_night",
		],
		"chips": [
			"chip_apocalypse_stellar",
			"chip_apocalypse_superconductive",
			"chip_apocalypse_entropy",
			"chip_apocalypse_golden_law",
		],
		"pets": [
			"pet_apocalypse_phoenix",
			"pet_apocalypse_tempest",
			"pet_apocalypse_aurora",
			"pet_apocalypse_skyfalcon",
		],
	}
	for collection_mode in hidden_premium_items.keys():
		var fresh_collection := _instance("res://meta/collection/collection.tscn")
		fresh_collection.setup(router, {"mode": str(collection_mode)})
		root.add_child(fresh_collection)
		await process_frame
		for hidden_item_id in hidden_premium_items[collection_mode]:
			_expect(fresh_collection.find_child(str(hidden_item_id), true, false) == null, "%s must be absent from %s collection before reveal" % [hidden_item_id, collection_mode])
		fresh_collection.queue_free()
		await process_frame

	var locked_store := _instance("res://meta/store/store.tscn")
	locked_store.setup(router, {})
	root.add_child(locked_store)
	await process_frame
	await process_frame
	var locked_content := locked_store.get_node_or_null("Root/VBox/ScrollWrap/Scroll/Content")
	var locked_headers: Array[Control] = []
	var locked_cards: Array[Control] = []
	if locked_content != null:
		for child in locked_content.get_children():
			if not child is Control:
				continue
			if child.has_meta("store_series_id"):
				locked_headers.append(child as Control)
			elif child.has_meta("store_product_id"):
				locked_cards.append(child as Control)
	var locked_empty_state := locked_store.find_child("LockedStoreEmptyState", true, false) as Control
	var expected_nearest_clear := 2147483647
	for set_id_var in data_loader.get_table("premium_sets").keys():
		var set_row: Dictionary = data_loader.get_row("premium_sets", str(set_id_var))
		if not purchase_manager.catalog_series_ids().has(str(set_row.get("series_id", ""))):
			continue
		var unlock: Dictionary = set_row.get("store_unlock", {})
		var clear_level := int(unlock.get("clear_level", 0))
		if clear_level > 0:
			expected_nearest_clear = mini(expected_nearest_clear, clear_level)
	_expect(locked_empty_state != null, "fresh premium store must render a deliberate encrypted empty state instead of a blank page")
	if locked_empty_state != null:
		_expect(int(locked_empty_state.get_meta("nearest_clear_level", 0)) == expected_nearest_clear, "fresh premium store must derive its nearest unlock tier from premium_sets.store_unlock")
		_expect(locked_empty_state.find_child("NearestUnlockText", true, false) != null, "fresh premium store must explain the nearest unlock requirement")
		_expect(locked_empty_state.find_child("LaterUnlockText", true, false) != null, "fresh premium store must summarize later unlock tiers")
		_expect(locked_empty_state.get_meta("later_clear_levels", []) == [50, 70, 90], "fresh premium store must dynamically summarize the 30 / 50 / 70 / 90 reveal tiers")
	var locked_restore := locked_store.get_node_or_null("Root/VBox/Footer/RestoreButton") as Button
	_expect(locked_restore != null and not locked_restore.disabled and locked_restore.visible, "restore purchases must remain available in the locked store empty state")
	_expect(locked_headers.is_empty(), "fresh premium store must not reveal any series identity before its gate")
	_expect(locked_cards.is_empty(), "fresh premium store must not reveal any product art, copy, price or action")
	locked_store.queue_free()
	await process_frame

	# The first reveal is atomic: after stage 30, Infernal appears as a complete
	# two-card series while every later series remains entirely absent.
	test_save["levels_progress"] = {"level_030": 3}
	save_manager.save_data = test_save
	purchase_manager.refresh_catalog_and_access()
	theme_manager.refresh_from_save()
	var first_reveal_menu := _instance("res://meta/menu/menu.tscn")
	first_reveal_menu.setup(router, {})
	root.add_child(first_reveal_menu)
	await process_frame
	var first_reveal_store_button := first_reveal_menu.find_child("StoreButton", true, false) as Control
	_expect(first_reveal_store_button != null and first_reveal_store_button.visible, "main menu must expose the arsenal entry after the first series reveal")
	first_reveal_menu.queue_free()
	await process_frame

	var first_reveal_store := _instance("res://meta/store/store.tscn")
	first_reveal_store.setup(router, {})
	root.add_child(first_reveal_store)
	await process_frame
	await process_frame
	var first_reveal_content := first_reveal_store.get_node_or_null("Root/VBox/ScrollWrap/Scroll/Content")
	var first_reveal_headers: Array[Control] = []
	var first_reveal_cards: Array[Control] = []
	if first_reveal_content != null:
		for child in first_reveal_content.get_children():
			if not child is Control:
				continue
			if child.has_meta("store_series_id"):
				first_reveal_headers.append(child as Control)
			elif child.has_meta("store_product_id"):
				first_reveal_cards.append(child as Control)
	_expect(first_reveal_headers.size() == 1 and str(first_reveal_headers[0].get_meta("store_series_id", "")) == "inferno", "stage 30 must reveal only the Infernal series")
	_expect(first_reveal_cards.size() == 2, "stage 30 must reveal exactly the Infernal theme and complete arsenal cards")
	_expect(first_reveal_store.find_child("LockedStoreEmptyState", true, false) == null, "the store empty state must disappear as soon as the first series is revealed")
	for card in first_reveal_cards:
		_expect(str(card.get_meta("store_product_id", "")).contains("inferno") or str(card.get_meta("store_product_id", "")).contains("infernal_dominion"), "first-reveal cards must belong only to Infernal")
	first_reveal_store.queue_free()
	await process_frame

	test_save["levels_progress"] = {
		"level_030": 3,
		"level_050": 3,
		"level_070": 3,
		"level_080": 3,
		"level_090": 3,
		"level_099": 3,
	}
	test_save["equipment"]["vanguard"] = 40
	save_manager.save_data = test_save
	purchase_manager.refresh_catalog_and_access()
	theme_manager.refresh_from_save()
	var store := _instance("res://meta/store/store.tscn")
	store.setup(router, {})
	root.add_child(store)
	await process_frame
	await process_frame
	var content := store.get_node_or_null("Root/VBox/ScrollWrap/Scroll/Content")
	_expect(content != null, "premium store must expose its product content container")
	var store_scroll := store.get_node_or_null("Root/VBox/ScrollWrap/Scroll") as ScrollContainer
	_expect(store_scroll != null, "premium store must retain its vertical ScrollContainer")
	if store_scroll != null:
		_expect(store_scroll.scroll_deadzone == 12, "premium store must use a deliberate 12px touch-scroll deadzone")
		var vertical_bar := store_scroll.get_v_scroll_bar()
		_expect(vertical_bar != null and vertical_bar.max_value > vertical_bar.page, "fully revealed premium store must have real vertical scroll range")
		store_scroll.scroll_vertical = 240
		await process_frame
		_expect(store_scroll.scroll_vertical > 0, "premium store ScrollContainer must accept vertical movement")
		store_scroll.scroll_vertical = 0
	if content is Control:
		_expect((content as Control).mouse_filter == Control.MOUSE_FILTER_PASS, "premium store content must pass touch drags to its ScrollContainer")
	var cards: Array[Control] = []
	if content != null:
		for child in content.get_children():
			if child is Control and child.has_meta("store_product_id"):
				cards.append(child as Control)
	_expect(cards.size() == 8, "fresh fully revealed store must render four theme and four complete-arsenal cards")
	# Reproduce the reported mobile gesture from directly on top of a purchase
	# button. Headless synthetic touch does not run the native ScrollContainer's
	# OS gesture recognizer, so the scroll range and PASS chain are asserted
	# above; this sequence guards the remaining observable failure mode: a drag
	# must not be misread as a product-detail or purchase tap.
	if store_scroll != null and not cards.is_empty():
		await process_frame
		var drag_button := cards[0].find_child("Buy_*", true, false) as BaseButton
		_expect(drag_button != null, "premium store drag regression requires a visible purchase action")
		if drag_button != null:
			var drag_start := drag_button.get_global_rect().get_center()
			var drag_touch := InputEventScreenTouch.new()
			drag_touch.index = 7
			drag_touch.position = drag_start
			drag_touch.pressed = true
			Input.parse_input_event(drag_touch)
			await process_frame
			var previous_position := drag_start
			for drag_distance in [32.0, 76.0, 132.0]:
				var drag_position := drag_start - Vector2(0.0, drag_distance)
				var drag_event := InputEventScreenDrag.new()
				drag_event.index = 7
				drag_event.position = drag_position
				drag_event.relative = drag_position - previous_position
				drag_event.screen_relative = drag_position - previous_position
				drag_event.velocity = Vector2(0.0, -900.0)
				drag_event.screen_velocity = Vector2(0.0, -900.0)
				Input.parse_input_event(drag_event)
				previous_position = drag_position
				await process_frame
			var drag_release := InputEventScreenTouch.new()
			drag_release.index = 7
			# Reproduce iOS' stale release coordinate: ScreenDrag carried the real
			# movement, while the final touch can still report the press origin.
			drag_release.position = drag_start
			drag_release.pressed = false
			Input.parse_input_event(drag_release)
			# Even if a child Button emits pressed on that same release dispatch,
			# the page-level drag arbiter must reject the action.
			drag_button.emit_signal("pressed")
			await process_frame
			_expect(store.find_child("StoreProductDetail", true, false) == null, "dragging the premium store must not misfire a product detail")
			var accidental_dialog: Variant = store.get("_dialog_layer")
			_expect(accidental_dialog == null or not is_instance_valid(accidental_dialog), "dragging the premium store must not misfire a purchase confirmation")
			# A stationary gesture on the same card must still open its detail.
			var tap_card := cards[0]
			var tap_product_id := str(tap_card.get_meta("store_product_id", ""))
			var tap_local := Vector2(40.0, 40.0)
			var tap_global := tap_card.get_global_transform_with_canvas() * tap_local
			var tap_press_global := InputEventScreenTouch.new()
			tap_press_global.index = 8
			tap_press_global.position = tap_global
			tap_press_global.pressed = true
			store.call("_input", tap_press_global)
			var tap_press_local := InputEventScreenTouch.new()
			tap_press_local.index = 8
			tap_press_local.position = tap_local
			tap_press_local.pressed = true
			store.call("_on_product_card_input", tap_press_local, tap_product_id, tap_card)
			var tap_release_global := InputEventScreenTouch.new()
			tap_release_global.index = 8
			tap_release_global.position = tap_global
			tap_release_global.pressed = false
			store.call("_input", tap_release_global)
			var tap_release_local := InputEventScreenTouch.new()
			tap_release_local.index = 8
			tap_release_local.position = tap_local
			tap_release_local.pressed = false
			store.call("_on_product_card_input", tap_release_local, tap_product_id, tap_card)
			await process_frame
			_expect(store.find_child("StoreProductDetail", true, false) != null, "stationary store tap must still open product detail")
			store.call("_close_product_detail")
			await process_frame
			store_scroll.scroll_vertical = 0
	for card in cards:
		var product_id := str(card.get_meta("store_product_id", ""))
		var product: Dictionary = data_loader.get_row("store_products", product_id)
		var role := str(product.get("offer_role", ""))
		_expect(bool(card.get_meta("store_card_opens_detail", false)), "%s entire product card must advertise a detail action" % product_id)
		_expect(not card.gui_input.get_connections().is_empty(), "%s product card must connect its tap/click detail action" % product_id)
		_expect(card.mouse_filter == Control.MOUSE_FILTER_PASS, "%s product card must pass vertical drags to the store ScrollContainer" % product_id)
		var buy := card.find_child("Buy_*", true, false) as BaseButton
		_expect(buy != null, "%s product card must retain its purchase action" % product_id)
		if buy != null:
			_expect(buy.mouse_filter == Control.MOUSE_FILTER_PASS, "%s purchase action must allow drag-to-scroll gestures" % product_id)
			_expect(bool(buy.get_meta("store_scroll_drag_passthrough", false)), "%s purchase action must declare scroll-drag passthrough" % product_id)
			var buy_center_global := buy.get_global_rect().get_center()
			var buy_center_local := card.get_global_transform_with_canvas().affine_inverse() * buy_center_global
			_expect(bool(store.call("_product_card_event_hits_action", buy_center_local, card)), "%s card tap resolver must exclude its purchase action" % product_id)
		var expected_layout := "theme_roster" if role == "theme" else "arsenal_grid"
		var preview := card.find_child("Preview", true, false) as Control
		var dominance := card.find_child("DominanceRange", true, false) as Label
		if role == "theme":
			_expect(dominance == null, "%s theme card must not claim an arsenal dominance range" % product_id)
		else:
			var set_row: Dictionary = data_loader.get_row("premium_sets", str(product.get("arsenal_set_id", "")))
			_expect(card.custom_minimum_size.y >= 430.0, "%s arsenal card must reserve height for its dominance disclosure" % product_id)
			_expect(dominance != null, "%s arsenal card must disclose its dominance range before purchase" % product_id)
			if dominance != null:
				_expect(dominance.text == str(set_row.get("dominance_en", "")), "%s dominance copy must come from the bilingual set data" % product_id)
				_expect(dominance.custom_minimum_size.y >= 58.0, "%s dominance disclosure must retain a readable two-line lane" % product_id)
		_expect(preview != null, "%s must expose a semantic preview" % product_id)
		if preview == null:
			continue
		_expect(preview.custom_minimum_size == Vector2(330, 330), "%s preview must use the shared 330x330 footprint" % product_id)
		_expect(str(preview.get_meta("store_preview_layout", "")) == expected_layout, "%s must use %s" % [product_id, expected_layout])
		_expect(int(preview.get_meta("store_preview_slots", 0)) == 4, "%s preview must declare four semantic slots" % product_id)
		var grid := preview.find_child("Grid", true, false) as GridContainer
		_expect(grid != null and grid.get_child_count() == 4, "%s preview must render a 2x2 four-slot grid" % product_id)
		if grid == null:
			continue
		for cell_var in grid.get_children():
			var cell := cell_var as Control
			_expect(cell != null and cell.custom_minimum_size == Vector2(152, 152), "%s preview cells must share the same footprint" % product_id)
			if cell == null:
				continue
			var visual_name := "Bust" if expected_layout == "theme_roster" else "Item"
			var visual := cell.find_child(visual_name, true, false) as TextureRect
			_expect(visual != null and visual.texture != null, "%s %s slot must resolve a production texture" % [product_id, cell.name])
			if visual == null:
				continue
			var source := str(visual.get_meta("store_preview_source", ""))
			_expect(source.begins_with("res://assets/production/sprites/"), "%s must use a runtime production asset" % product_id)
			_expect(not source.contains("/source_refs/"), "%s must not expose a design/source board in the player store" % product_id)
			var visible_rect: Rect2 = visual.get_meta("store_preview_visible_rect", Rect2())
			if expected_layout == "theme_roster":
				_expect(source.contains("/sprites/themes/"), "%s theme roster must use its authored outfit portraits" % product_id)
				_expect(is_equal_approx(float(visual.get_meta("store_preview_visible_height", 0.0)), 212.0), "%s outfit subjects must share the same human-height ruler" % product_id)
				_expect(is_equal_approx(visible_rect.position.y, 8.0), "%s outfit subjects must share the same headroom" % product_id)
				_expect(visible_rect.position.x >= -0.01 and visible_rect.end.x <= 146.01, "%s outfit bust must remain horizontally complete" % product_id)
			else:
				_expect(source.contains("/sprites/premium/"), "%s arsenal grid must use the clean premium item assets" % product_id)
				_expect(is_equal_approx(float(visual.get_meta("store_preview_visible_extent", 0.0)), 124.0), "%s arsenal subjects must share the same long-axis ruler" % product_id)
				_expect(visible_rect.position.x >= -0.01 and visible_rect.position.y >= -0.01, "%s arsenal subject must start inside its cell" % product_id)
				_expect(visible_rect.end.x <= 146.01 and visible_rect.end.y <= 146.01, "%s arsenal subject must not be cropped by its cell" % product_id)

		store.call("_show_product_detail", product_id)
		await process_frame
		var detail := store.find_child("StoreProductDetail", true, false) as Control
		_expect(detail != null, "%s card must open a product detail layer" % product_id)
		if detail != null:
			_expect(str(detail.get_meta("store_detail_product_id", "")) == product_id, "%s detail must retain the exact product identity" % product_id)
			var detail_close := detail.find_child("CloseButton", true, false) as Button
			_expect(detail_close != null and detail_close.text == "×", "%s detail must expose the shared icon-only close action" % product_id)
			if detail_close != null:
				_expect(detail_close.custom_minimum_size.x >= UiKit.CLOSE_BUTTON_MIN_SIZE.x and detail_close.custom_minimum_size.y >= UiKit.CLOSE_BUTTON_MIN_SIZE.y, "%s detail close must keep the larger modal-close target" % product_id)
				_expect(detail_close.get_theme_font_size("font_size") >= UiKit.CLOSE_GLYPH_FONT_SIZE, "%s detail close glyph must remain visually prominent" % product_id)
			var detail_scroll := detail.find_child("DetailScroll", true, false) as ScrollContainer
			var detail_content := detail.find_child("DetailContent", true, false) as Control
			_expect(detail_scroll != null, "%s detail must retain its independent vertical ScrollContainer" % product_id)
			_expect(detail_content != null and detail_content.mouse_filter == Control.MOUSE_FILTER_PASS, "%s detail content must pass touch drags to its ScrollContainer" % product_id)
			if detail_scroll != null:
				_expect(detail_scroll.scroll_deadzone == 12, "%s detail must use the shared 12px touch-scroll deadzone" % product_id)
				var detail_bar := detail_scroll.get_v_scroll_bar()
				_expect(detail_bar != null and detail_bar.max_value > detail_bar.page, "%s detail must expose real vertical scroll range" % product_id)
				detail_scroll.scroll_vertical = 240
				await process_frame
				_expect(detail_scroll.scroll_vertical > 0, "%s detail ScrollContainer must accept vertical movement" % product_id)
				detail_scroll.scroll_vertical = 0
			if detail_content != null:
				for surface_var in detail_content.find_children("*", "Control", true, false):
					var detail_surface := surface_var as Control
					if detail_surface.mouse_filter != Control.MOUSE_FILTER_IGNORE:
						_expect(detail_surface.mouse_filter == Control.MOUSE_FILTER_PASS, "%s detail surface %s must allow drag-to-scroll gestures" % [product_id, detail_surface.name])
			var title := detail.find_child("ProductTitle", true, false) as Label
			_expect(title != null and title.text == str(product.get("name_en", "")), "%s English detail must use the catalog product name" % product_id)
			var header_text_inset := detail.find_child("HeaderTextInset", true, false) as Control
			_expect(header_text_inset != null and header_text_inset.custom_minimum_size.x >= 16.0, "%s product title must clear the outer frame with the shared header inset" % product_id)
			if detail_content != null:
				for section_var in detail_content.get_children():
					if not section_var is PanelContainer:
						continue
					var section := section_var as PanelContainer
					var section_margin := section.get_node_or_null("Margin") as MarginContainer
					_expect(section_margin != null, "%s section %s must expose its shared text margin" % [product_id, section.name])
					if section_margin != null:
						_expect(section_margin.get_theme_constant("margin_left") >= 36 and section_margin.get_theme_constant("margin_right") >= 24, "%s section %s title/body must keep the owner-reviewed 36px left / 24px right clearance" % [product_id, section.name])
						_expect(section_margin.get_theme_constant("margin_top") >= 22 and section_margin.get_theme_constant("margin_bottom") >= 22, "%s section %s title/body must keep 22px vertical clearance" % [product_id, section.name])
			for info_margin_var in detail.find_children("InfoMargin", "MarginContainer", true, false):
				var info_margin := info_margin_var as MarginContainer
				_expect(info_margin.get_theme_constant("margin_left") >= 26 and info_margin.get_theme_constant("margin_right") >= 18 and info_margin.get_theme_constant("margin_top") >= 14, "%s nested theme info copy must keep its right-shifted inner gutter" % product_id)
			for gear_margin_var in detail.find_children("GearMargin", "MarginContainer", true, false):
				var gear_margin := gear_margin_var as MarginContainer
				_expect(gear_margin.get_theme_constant("margin_left") >= 26 and gear_margin.get_theme_constant("margin_right") >= 18 and gear_margin.get_theme_constant("margin_top") >= 16, "%s arsenal item copy must keep its right-shifted inner gutter" % product_id)
			var action := detail.find_child("PurchaseButton", true, false) as Button
			_expect(action != null and not action.disabled, "%s current offer detail must retain a live purchase action" % product_id)
			if action != null:
				_expect(str(action.get_meta("store_detail_product_id", "")) == product_id, "%s detail purchase action must target the opened product" % product_id)
				_expect(str(action.get_meta("store_detail_action_state", "")) == "purchase", "%s current detail action must be marked purchase" % product_id)
			var hero_grid := detail.find_child("DetailHeroGrid", true, false) as GridContainer
			var weapon_skin_grid := detail.find_child("DetailWeaponSkinGrid", true, false) as GridContainer
			var gear_grid := detail.find_child("DetailArsenalGearGrid", true, false) as GridContainer
			if role in ["theme", "arsenal_complete"]:
				_expect(hero_grid != null and hero_grid.get_child_count() == 4, "%s detail must enumerate all four themed hero outfits" % product_id)
				_expect(weapon_skin_grid != null and weapon_skin_grid.get_child_count() == 8, "%s detail must enumerate all eight free-weapon theme looks" % product_id)
			else:
				_expect(hero_grid == null and weapon_skin_grid == null, "%s upgrade must not charge for or re-grant owned theme contents" % product_id)
			if role != "theme":
				_expect(gear_grid != null and gear_grid.get_child_count() == 4, "%s detail must enumerate weapon, armor, chip and pet" % product_id)
				_expect(detail.find_child("SetBonusDescription", true, false) != null, "%s detail must disclose the set synergy" % product_id)
				_expect(detail.find_child("PowerTarget", true, false) != null, "%s detail must disclose the authored max-level power target" % product_id)
			else:
				_expect(gear_grid == null, "%s theme-only detail must not imply arsenal ownership" % product_id)
		store.call("_close_product_detail")
		await process_frame

	store.queue_free()
	await process_frame

	# Theme owners see a different logical product. Verify all four upgrade cards
	# open the same data-driven gear detail while omitting already-owned theme
	# contents and preserving the discounted purchase action.
	var theme_receipts: Array[String] = []
	for product_id_var in data_loader.get_table("store_products").keys():
		var product_id := str(product_id_var)
		var product: Dictionary = data_loader.get_row("store_products", product_id)
		if str(product.get("offer_role", "")) == "theme":
			theme_receipts.append(product_id)
	test_save["commerce"] = {"mock_receipts": theme_receipts, "mock_last_transaction_unix": 0}
	save_manager.save_data = test_save
	purchase_manager.refresh_catalog_and_access()
	theme_manager.refresh_from_save()
	var upgrade_store := _instance("res://meta/store/store.tscn")
	upgrade_store.setup(router, {})
	root.add_child(upgrade_store)
	await process_frame
	await process_frame
	var upgrade_content := upgrade_store.get_node_or_null("Root/VBox/ScrollWrap/Scroll/Content")
	var upgrade_cards: Array[Control] = []
	if upgrade_content != null:
		for child in upgrade_content.get_children():
			if child is Control and child.has_meta("store_product_id"):
				upgrade_cards.append(child as Control)
		for button_var in upgrade_content.find_children("*", "BaseButton", true, false):
			var list_button := button_var as BaseButton
			_expect(list_button.mouse_filter == Control.MOUSE_FILTER_PASS, "%s must pass vertical drags to the owned-store ScrollContainer" % list_button.name)
			_expect(bool(list_button.get_meta("store_scroll_drag_passthrough", false)), "%s must declare owned-store scroll-drag passthrough" % list_button.name)
	_expect(upgrade_cards.size() == 4, "four revealed theme owners must see one discounted arsenal upgrade per series")
	for upgrade_card in upgrade_cards:
		var upgrade_product_id := str(upgrade_card.get_meta("store_product_id", ""))
		var upgrade_product: Dictionary = data_loader.get_row("store_products", upgrade_product_id)
		_expect(str(upgrade_product.get("offer_role", "")) == "arsenal_upgrade", "%s must be a theme-owner upgrade" % upgrade_product_id)
		upgrade_store.call("_show_product_detail", upgrade_product_id)
		await process_frame
		var detail := upgrade_store.find_child("StoreProductDetail", true, false) as Control
		_expect(detail != null, "%s must open a discounted upgrade detail" % upgrade_product_id)
		if detail != null:
			_expect(detail.find_child("UpgradePricingNote", true, false) != null, "%s must explain that theme value is not charged twice" % upgrade_product_id)
			_expect(detail.find_child("DetailHeroGrid", true, false) == null, "%s must omit already-owned hero outfits" % upgrade_product_id)
			var gear_grid := detail.find_child("DetailArsenalGearGrid", true, false) as GridContainer
			_expect(gear_grid != null and gear_grid.get_child_count() == 4, "%s must enumerate all four missing arsenal items" % upgrade_product_id)
			var action := detail.find_child("PurchaseButton", true, false) as Button
			_expect(action != null and action.text.contains("US$4.99"), "%s detail must retain the discounted upgrade price" % upgrade_product_id)
		upgrade_store.call("_close_product_detail")
		await process_frame
	upgrade_store.queue_free()
	router.queue_free()
	await process_frame
	localization_manager.apply_language(original_language, false)
	save_manager.save_data = original_save
	purchase_manager.refresh_catalog_and_access()
	theme_manager.refresh_from_save()

func _verify_appearance_selector_states(save_manager: Node) -> void:
	var purchase_manager := root.get_node("/root/PurchaseManager")
	var theme_manager := root.get_node("/root/ThemeManager")
	var localization_manager := root.get_node("/root/LocalizationManager")
	var testflight_preview: bool = bool(theme_manager.preview_access_enabled())
	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var original_language := str(localization_manager.current_language)
	var test_save: Dictionary = original_save.duplicate(true)
	test_save["levels_progress"] = {
		"level_030": 3,
		"level_050": 3,
		"level_070": 3,
		"level_080": 3,
		"level_090": 3,
		"level_099": 3,
	}
	test_save["equipment"]["vanguard"] = 40
	test_save["commerce"] = {"mock_receipts": [], "mock_last_transaction_unix": 0}
	test_save["entitlements"] = {"verified": [], "last_sync_unix": 0}
	test_save["cosmetics"] = {
		"selected_theme": "default",
		"character_outfits": {
			"vanguard": "follow_theme",
			"blaze": "follow_theme",
			"frost": "follow_theme",
			"volt": "follow_theme",
		},
	}
	save_manager.save_data = test_save
	purchase_manager.refresh_catalog_and_access()
	theme_manager.refresh_from_save()

	for language in ["zh", "en"]:
		localization_manager.apply_language(language, false)
		var selector_script := load("res://ui/appearance_selector.gd") as GDScript
		_expect(selector_script != null, "appearance selector script must compile")
		if selector_script == null:
			continue
		var selector := selector_script.new() as CanvasLayer
		root.add_child(selector)
		selector.open_character("vanguard")
		await process_frame
		var appearance_close := selector.find_child("HeaderBackButton", true, false) as Button
		_expect(appearance_close != null and appearance_close.text == "×", "character appearance header must expose the shared icon-only close action")
		if appearance_close != null:
			_expect(appearance_close.custom_minimum_size.x >= UiKit.CLOSE_BUTTON_MIN_SIZE.x and appearance_close.custom_minimum_size.y >= UiKit.CLOSE_BUTTON_MIN_SIZE.y, "character appearance close must keep the larger modal-close target")
			_expect(appearance_close.get_theme_font_size("font_size") >= UiKit.CLOSE_GLYPH_FONT_SIZE, "character appearance close glyph must remain visually prominent")
		var worn := selector.find_child("OutfitSelect_follow_theme", true, false) as Button
		var wear := selector.find_child("OutfitSelect_default", true, false) as Button
		var buy := selector.find_child("OutfitSelect_gilded_eclipse", true, false) as Button
		var gilded_card := selector.find_child("Outfit_gilded_eclipse", true, false) as Control
		var ownership: Label = gilded_card.find_child("OwnershipStatus", true, false) as Label if gilded_card != null else null
		_expect(worn != null and wear != null and buy != null, "appearance selector must expose current, wearable and store-bound actions")
		if worn != null and wear != null and buy != null:
			_expect(worn.disabled and str(worn.get_meta("appearance_action_state", "")) == "current", "worn outfit action must be disabled and marked current")
			_expect(not wear.disabled and str(wear.get_meta("appearance_action_state", "")) == "available", "owned outfit action must remain bright and wearable")
			_expect(
				not buy.disabled and str(buy.get_meta("appearance_action_state", "")) == ("available" if testflight_preview else "purchase"),
				"premium outfit action must follow the TestFlight-preview or production-purchase state contract"
			)
			_expect(worn.text == ("已穿戴" if language == "zh" else "WORN"), "worn action must keep a clear bilingual state label")
			_expect(wear.text == ("穿  戴" if language == "zh" else "Wear"), "wear action must keep a clear bilingual verb")
			_expect(
				buy.text == (("穿  戴" if language == "zh" else "Wear") if testflight_preview else ("购  买" if language == "zh" else "BUY")),
				"premium outfit action must use the correct bilingual TestFlight-preview or purchase verb"
			)
			_expect(
				ownership == null if testflight_preview else (ownership != null and ownership.text == ("尚未拥有" if language == "zh" else "Not Owned")),
				"premium outfit ownership disclosure must follow the TestFlight-preview or production contract"
			)
			var worn_style := worn.get_theme_stylebox("disabled") as StyleBoxTexture
			var wear_style := wear.get_theme_stylebox("normal") as StyleBoxTexture
			var buy_style := buy.get_theme_stylebox("normal") as StyleBoxTexture
			_expect(worn_style != null and wear_style != null and buy_style != null, "appearance actions must use armored raster styles in every state")
			if worn_style != null and wear_style != null and buy_style != null:
				_expect(worn_style.modulate_color.get_luminance() < wear_style.modulate_color.get_luminance(), "worn surface must be visibly quieter than the wearable surface")
				if testflight_preview:
					_expect(is_equal_approx(buy_style.modulate_color.get_luminance(), wear_style.modulate_color.get_luminance()), "TestFlight-preview outfits must share the wearable surface")
				else:
					_expect(buy_style.modulate_color.get_luminance() < wear_style.modulate_color.get_luminance(), "purchase surface must be lower-gloss than the wearable surface")
		var portrait_cards: Array[Control] = []
		var hero_portrait := selector.find_child("HeroPortrait", true, false) as TextureRect
		_expect(hero_portrait != null and hero_portrait.texture is AtlasTexture, "appearance hero showcase must use the shared hero-bust viewport")
		if hero_portrait != null:
			_expect(str(hero_portrait.get_meta("portrait_framing_mode", "")) == "hero_bust", "appearance hero showcase must declare the hero-bust framing contract")
			_expect(is_equal_approx(float(hero_portrait.get_meta("portrait_visible_fraction", 0.0)), 0.70), "appearance hero showcase must use the roomier 70% body crop")
		for outfit_mode in ["follow_theme", "default", "neon_tempest", "infernal_dominion", "polar_aurora", "gilded_eclipse"]:
			var outfit_card := selector.find_child("Outfit_" + outfit_mode, true, false) as Control
			_expect(outfit_card != null, "appearance selector must expose %s portrait card" % outfit_mode)
			if outfit_card != null:
				portrait_cards.append(outfit_card)
		for card in portrait_cards:
			var portrait: TextureRect = null
			for child in card.find_children("*", "TextureRect", true, false):
				if child.has_meta("portrait_display_region"):
					portrait = child as TextureRect
					break
			_expect(portrait != null, "appearance outfit card must expose an alpha-fitted portrait")
			if portrait != null:
				_expect(portrait.texture is AtlasTexture, "appearance portrait must use an authored hero-bust viewport")
				_expect(str(portrait.get_meta("portrait_framing_mode", "")) == "hero_bust", "appearance portrait must advertise the shared bust framing contract")
				var source_used: Rect2 = portrait.get_meta("portrait_source_used_rect", Rect2())
				var display_region: Rect2 = portrait.get_meta("portrait_display_region", Rect2())
				var visible_fraction := float(portrait.get_meta("portrait_visible_fraction", 0.0))
				_expect(visible_fraction >= 0.58 and visible_fraction <= 0.74, "appearance portrait bust fraction must stay in the mobile impact range")
				_expect(display_region.position.y <= source_used.position.y, "appearance portrait must retain complete hair and headroom")
				_expect(display_region.end.y >= source_used.position.y + source_used.size.y * 0.58, "appearance portrait must include torso and upper legs")
				_expect(display_region.end.y <= source_used.position.y + source_used.size.y * 0.76, "appearance portrait must not regress to a tiny full-body thumbnail")
				_expect(display_region.position.x <= source_used.get_center().x and display_region.end.x >= source_used.get_center().x, "appearance portrait must stay centered on the source body")
				var viewport_aspect := portrait.custom_minimum_size.x / maxf(portrait.custom_minimum_size.y, 1.0)
				_expect(absf(display_region.size.x / maxf(display_region.size.y, 1.0) - viewport_aspect) <= 0.01, "appearance portrait crop must match its viewport aspect without a second accidental crop")
		selector.queue_free()
		await process_frame

	for character_id in ["vanguard", "blaze", "frost", "volt"]:
		var portrait_path: String = str(theme_manager.resolve_character_portrait_for_theme(character_id, "gilded_eclipse", ""))
		var portrait_texture := load(portrait_path) as Texture2D
		_expect(portrait_texture != null, "Gilded Eclipse portrait must resolve for %s" % character_id)
		if portrait_texture != null:
			var used_rect := portrait_texture.get_image().get_used_rect()
			_expect(used_rect.size.x >= 290, "Gilded Eclipse %s portrait must not regress to the clipped prototype strip" % character_id)

	localization_manager.apply_language(original_language, false)
	save_manager.save_data = original_save
	purchase_manager.refresh_catalog_and_access()
	theme_manager.refresh_from_save()

func _verify_power_skill_level_accounting(save_manager: Node) -> void:
	var data_loader := save_manager.get_node("/root/DataLoader")
	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var base_save: Dictionary = _battle_smoke_loadout(original_save)
	var equipment: Dictionary = base_save.get("equipment", {}).duplicate(true)
	equipment["selected_character"] = "vanguard"
	equipment["selected_weapon"] = "weapon_autocannon"
	# Use a formed permanent loadout so the public integer power display does
	# not round both sides of the skill comparison down to 1 on the v5 runtime
	# throughput scale. The assertion still isolates skill levels: equipment is
	# identical in every sample below.
	equipment["vanguard"] = 40
	equipment["weapon_autocannon"] = 50
	base_save["equipment"] = equipment
	base_save["skill_base_levels"] = {}
	base_save["sig_skill_levels"] = {}
	save_manager.save_data = base_save
	var base_power := int(save_manager.get_power_for_level("level_097"))
	var fixed_recommendation := int(save_manager.get_recommended_power_for_level("level_097"))
	var level97: Dictionary = data_loader.get_row("levels", "level_097")
	var fixed_projection: Dictionary = save_manager._projected_run_skill_levels_for_profile(
		int(level97.get("target_card_picks", 4)),
		str(level97.get("primary_weakness", "physical")),
		"weapon_autocannon",
		{},
	)
	_expect(not fixed_projection.is_empty(), "fixed recommendation must use the shared skill projector with an explicit reference profile")
	var previous_upgrade_power := base_power
	for skill_level in range(1, 6):
		var step_save: Dictionary = base_save.duplicate(true)
		step_save["skill_base_levels"] = {"skill_split_shot": skill_level}
		save_manager.save_data = step_save
		var step_power := int(save_manager.get_power_for_level("level_097"))
		_expect(step_power >= previous_upgrade_power, "every permanent skill upgrade must keep player power monotonic; lv%d=%d previous=%d" % [skill_level, step_power, previous_upgrade_power])
		previous_upgrade_power = step_power
	var skilled_save: Dictionary = base_save.duplicate(true)
	skilled_save["skill_base_levels"] = {
		"skill_split_shot": 5,
		"skill_pierce": 3,
		"skill_multishot": 2,
	}
	skilled_save["sig_skill_levels"] = {"vanguard": 4}
	save_manager.save_data = skilled_save
	var skilled_power := int(save_manager.get_power_for_level("level_097"))
	# design/28 乘法口径下低端绝对差被压缩(L1 裸装约 21),改按相对涨幅断言。
	_expect(float(skilled_power) >= float(base_power) * 1.35, "power must visibly account for current passive and active skill levels; base=%d skilled=%d" % [base_power, skilled_power])
	_expect(int(save_manager.get_recommended_power_for_level("level_097")) == fixed_recommendation, "skill upgrades must not move a level's fixed recommended power")
	var alternate_save: Dictionary = skilled_save.duplicate(true)
	var alternate_equipment: Dictionary = alternate_save.get("equipment", {}).duplicate(true)
	alternate_equipment["selected_character"] = "volt"
	alternate_equipment["selected_weapon"] = "weapon_teslacoil"
	alternate_equipment["volt"] = 40
	alternate_equipment["weapon_teslacoil"] = 50
	alternate_save["equipment"] = alternate_equipment
	save_manager.save_data = alternate_save
	_expect(int(save_manager.get_recommended_power_for_level("level_097")) == fixed_recommendation, "changing character or weapon must not move a level's fixed recommended power")
	var fixed_projection_after_save_change: Dictionary = save_manager._projected_run_skill_levels_for_profile(
		int(level97.get("target_card_picks", 4)),
		str(level97.get("primary_weakness", "physical")),
		"weapon_autocannon",
		{},
	)
	_expect(fixed_projection_after_save_change == fixed_projection, "fixed recommendation projection must be identical across player saves")
	# Recommended power remains a level-authored minimum-clear line and grows with
	# campaign pressure, while the one player power value grows with current skills.
	var level68_power := int(save_manager.get_recommended_power_for_level("level_068"))
	_expect(level68_power >= 450, "level_068 clear-line power must scale into the late campaign, got %d" % level68_power)
	var level97_power := int(save_manager.get_recommended_power_for_level("level_097"))
	_expect(level97_power >= 1000, "level_097 clear-line power must scale with its ten-card budget on the v4 corridor scale, got %d" % level97_power)
	_expect(level97_power > level68_power, "a later level must have a higher clear line; level_068=%d level_097=%d" % [level68_power, level97_power])
	_expect(float(save_manager.get_run_skill_hp_pressure_for_level("level_097")) >= 1.45, "level_097 late waves must absorb ten-card DPS growth through authored HP pressure")
	_expect(float(save_manager.get_run_skill_speed_pressure_for_level("level_097")) >= 1.10, "level_097 late waves must gain bounded movement pressure")
	save_manager.save_data = original_save

# Owner 2026-08-20 战力 5.0 验收电池：玩家仍只看到一个战力，但内部严格取
# 清群 / Boss / 防线三条比值的最短板。绝对刻度随最弱兼容卡口径更新，冻结物是：
# - 99 关满级免费最强物理：R≈1.1600，Boss 是短板；
# - 80 关 Owner 实战配置：R≈1.0500，Boss 是短板，不再把面板弹丸当成实命中。
func _verify_recommended_power_calibration(save_manager: Node, data_loader: Node) -> void:
	var gate_probe: Node = _instance("res://gameplay/battle/battle.tscn")
	var cushion_min := float(gate_probe.CLEAR_LINE_CUSHION_MIN_RATIO)
	var warning_gate := float(gate_probe.CLEAR_LINE_WARNING_RATIO)
	gate_probe.queue_free()
	_expect(warning_gate > cushion_min, "the warning gate must sit above the cushion floor")
	_expect(absf(warning_gate - 1.0) <= 0.001, "design/28: the warning gate IS the clear line (ratio 1.0)")

	for level_id in ["level_001", "level_013", "level_070", "level_085", "level_099"]:
		var contract: Dictionary = data_loader.get_row("levels", level_id).get("clear_requirement", {}).get("power_contract", {})
		_expect(str(contract.get("model", "")) == "bottleneck_v5", "%s must carry a bottleneck_v5 power contract" % level_id)
		_expect(float(contract.get("crowd_capacity", 0.0)) > 0.0, "%s crowd contract must be positive" % level_id)
		_expect(float(contract.get("line_capacity", 0.0)) > 0.0, "%s line contract must be valid" % level_id)
		_expect(float(contract.get("line_expected_breach", -1.0)) >= 0.0, "%s must serialize expected breach damage" % level_id)
		_expect(float(contract.get("line_base_hp", 0.0)) > 0.0, "%s must serialize reference base HP" % level_id)
		_expect(float(contract.get("line_target_hp_ratio", -1.0)) >= 0.0, "%s must serialize the survival boundary" % level_id)
		_expect(not contract.get("line_exposure_weights", {}).is_empty(), "%s must serialize line exposure weights" % level_id)

	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var all_max_skills: Dictionary = {}
	for skill_id_var in data_loader.get_table("skills").keys():
		var skill_id := str(skill_id_var)
		all_max_skills[skill_id] = save_manager._power_skill_max_level(data_loader.get_row("skills", skill_id))

	_apply_calibration_build(save_manager, original_save, "vanguard", 40, "weapon_scattergun", 50, "armor_kevlar", 35, "chip_attack", 35, "pet_turret_drone", 30, 5)
	save_manager.save_data["skill_base_levels"] = all_max_skills.duplicate(true)
	var final_breakdown: Dictionary = save_manager.get_power_breakdown_for_level("level_099")
	_expect(int(final_breakdown.get("power", 0)) == 1667, "level_099 max-free power must include the literal four-Boss roster, got %d" % int(final_breakdown.get("power", 0)))
	_expect(int(final_breakdown.get("recommended", 0)) == 1437, "level_099 recommendation must include all four fixed-identity Bosses exactly once, got %d" % int(final_breakdown.get("recommended", 0)))
	_expect(str(final_breakdown.get("power_bottleneck", "")) == "boss", "level_099 max-free bottleneck must be Boss")
	var final_ratios: Dictionary = final_breakdown.get("power_ratios", {})
	_expect(absf(float(final_ratios.get("boss", 0.0)) - 1.1600) <= 0.002, "level_099 Boss ratio must remain replay-calibrated near 1.160")

	_apply_calibration_build(save_manager, original_save, "blaze", 40, "weapon_apocalypse_inferno", 36, "armor_apocalypse_molten", 21, "chip_apocalypse_stellar", 21, "pet_apocalypse_phoenix", 15, 5)
	var rank4_skills: Dictionary = {}
	for skill_id_var in data_loader.get_table("skills").keys():
		var skill_id := str(skill_id_var)
		rank4_skills[skill_id] = mini(4, save_manager._power_skill_max_level(data_loader.get_row("skills", skill_id)))
	save_manager.save_data["skill_base_levels"] = rank4_skills
	var observed_breakdown: Dictionary = save_manager.get_power_breakdown_for_level("level_080")
	_expect(int(observed_breakdown.get("power", 0)) == 1038, "observed level_080 build must use collider-calibrated Boss throughput, got %d" % int(observed_breakdown.get("power", 0)))
	_expect(int(observed_breakdown.get("recommended", 0)) == 989, "level_080 recommendation must count the three-Necromancer roster exactly once")
	_expect(str(observed_breakdown.get("power_bottleneck", "")) == "boss", "observed level_080 build must expose Boss output as its internal bottleneck")
	_expect(absf(float(observed_breakdown.get("power", 0)) / 989.0 - 1.0500) <= 0.002, "observed level_080 replay ratio must stay aligned with the pressure-clear result")
	_expect(float(observed_breakdown.get("power_line_exposure_credit", 0.0)) <= 1.1501, "line exposure credit must remain bounded at +15%")

	# The fixture manifest is generated by the single Python model and checked into
	# each contract. Smoke consumes it rather than defining a second fixture table.
	for sample_level_id in ["level_002", "level_013", "level_025", "level_040", "level_050", "level_070", "level_085", "level_098"]:
		var sample_level: Dictionary = data_loader.get_row("levels", sample_level_id)
		var sample_contract: Dictionary = sample_level.get("clear_requirement", {}).get("power_contract", {})
		var calibration: Dictionary = sample_contract.get("corridor_calibration", {})
		var fixture: Dictionary = calibration.get("fixture", {})
		_expect(not fixture.is_empty(), "%s must serialize the design/32 corridor fixture" % sample_level_id)
		_apply_calibration_build(
			save_manager,
			original_save,
			str(fixture.get("character", "vanguard")),
			int(fixture.get("character_level", 1)),
			str(fixture.get("weapon", "weapon_autocannon")),
			int(fixture.get("weapon_level", 1)),
			str(fixture.get("armor", "armor_kevlar")),
			int(fixture.get("armor_level", 1)),
			str(fixture.get("chip", "chip_attack")),
			int(fixture.get("chip_level", 1)),
			str(fixture.get("pet", "")),
			int(fixture.get("pet_level", 1)),
			int(fixture.get("signature_level", 0)),
		)
		var fixture_skills: Dictionary = {}
		var fixture_rank := int(fixture.get("skill_rank", 1))
		for skill_id_var in data_loader.get_table("skills").keys():
			var fixture_skill_id := str(skill_id_var)
			fixture_skills[fixture_skill_id] = mini(fixture_rank, save_manager._power_skill_max_level(data_loader.get_row("skills", fixture_skill_id)))
		save_manager.save_data["skill_base_levels"] = fixture_skills
		var sample_breakdown: Dictionary = save_manager.get_power_breakdown_for_level(sample_level_id)
		var sample_ratio := float(sample_breakdown.get("power", 0)) / maxf(float(sample_breakdown.get("recommended", 1)), 1.0)
		var band: Array = calibration.get("band", [1.0, 1.4])
		_expect(sample_ratio >= float(band[0]) - 0.01 and sample_ratio <= float(band[1]) + 0.01, "%s corridor fixture ratio %.4f must stay inside [%s,%s]" % [sample_level_id, sample_ratio, str(band[0]), str(band[1])])

	var level99: Dictionary = data_loader.get_row("levels", "level_099")
	_expect(level99.get("runtime_bosses", []).size() == 2, "level_099 must author two Apex reinforcements in levels.json")
	for runtime_boss in level99.get("runtime_bosses", []):
		_expect(str(runtime_boss.get("type", "")) == "boss_apex_overlord", "level_099 runtime Boss reinforcements must all reuse the identical Apex model")
	_expect(level99.get("guaranteed_card_offers", []).size() >= 1, "level_099 must guarantee a defensive card offer")
	save_manager.save_data = original_save

# design/29 Phase A regression battery. These checks deliberately use the authored
# affinity fields instead of a second fixture table: changing character data remains
# legal, while silently dropping rank/status/splash/shatter/chain/slow from the power
# ruler turns the release gate red immediately.
func _verify_character_power_identity_model(save_manager: Node, data_loader: Node) -> void:
	var vanguard: Dictionary = data_loader.get_row("characters", "vanguard")
	var blaze: Dictionary = data_loader.get_row("characters", "blaze")
	var frost: Dictionary = data_loader.get_row("characters", "frost")
	var volt: Dictionary = data_loader.get_row("characters", "volt")
	var autocannon: Dictionary = data_loader.get_row("weapons", "weapon_autocannon")
	var flamethrower: Dictionary = data_loader.get_row("weapons", "weapon_flamethrower")
	var cryocannon: Dictionary = data_loader.get_row("weapons", "weapon_cryocannon")
	var teslacoil: Dictionary = data_loader.get_row("weapons", "weapon_teslacoil")

	var vanguard_affinity: Dictionary = vanguard.get("bullet_affinity", {})
	var expected_vanguard := (
		1.0
		+ float(vanguard_affinity.get("damage_bonus", 0.0))
		+ float(vanguard_affinity.get("rank_damage_bonus", 0.0)) * 3.0
	) * (
		1.0
		+ float(int(vanguard_affinity.get("pierce_bonus", 0)) + int(vanguard_affinity.get("rank_pierce_bonus", 0))) * 0.065
	)
	var measured_vanguard := float(save_manager._bullet_affinity_multiplier(vanguard, autocannon, 40))
	_expect(absf(measured_vanguard - expected_vanguard) <= 0.0001, "design/29: vanguard affinity must include rank damage and rank pierce; expected %.5f got %.5f" % [expected_vanguard, measured_vanguard])
	_expect(absf(float(save_manager._bullet_affinity_multiplier(vanguard, flamethrower, 40)) - 1.0) <= 0.0001, "design/29: character affinity must remain gated by matching weapon element")

	var blaze_affinity: Dictionary = blaze.get("bullet_affinity", {})
	var blaze_radius := float(blaze_affinity.get("splash_bonus", 0.0)) + float(blaze_affinity.get("rank_splash_bonus", 0.0)) * 3.0
	var expected_blaze := (
		1.0
		+ float(blaze_affinity.get("damage_bonus", 0.0))
		+ float(blaze_affinity.get("rank_damage_bonus", 0.0)) * 3.0
	) * (1.0 + float(blaze_affinity.get("status_bonus", 0.0)) * 0.28) * (1.0 + blaze_radius * 0.0001)
	var measured_blaze := float(save_manager._bullet_affinity_multiplier(blaze, flamethrower, 40))
	_expect(absf(measured_blaze - expected_blaze) <= 0.0001, "design/29: blaze affinity must include rank damage, status, and splash radius; expected %.5f got %.5f" % [expected_blaze, measured_blaze])
	var battlefield_coverage_blaze := blaze.duplicate(true)
	var battlefield_coverage_active: Dictionary = battlefield_coverage_blaze.get("active_skill", {}).duplicate(true)
	battlefield_coverage_active["coverage_mode"] = "battlefield"
	battlefield_coverage_blaze["active_skill"] = battlefield_coverage_active
	var local_active_power := float(save_manager._active_skill_offense_multiplier(blaze, 40, 5))
	var battlefield_active_power := float(save_manager._active_skill_offense_multiplier(battlefield_coverage_blaze, 40, 5))
	_expect(absf(battlefield_active_power - local_active_power) <= 0.0001, "Blaze coverage mode must not change displayed single-target power")

	var frost_affinity: Dictionary = frost.get("bullet_affinity", {})
	var frost_shatter := float(frost_affinity.get("shatter_bonus", 0.0)) + 0.04 * 3.0
	var expected_frost := (
		1.0
		+ float(frost_affinity.get("damage_bonus", 0.0))
		+ float(frost_affinity.get("rank_damage_bonus", 0.0)) * 3.0
	) * (1.0 + frost_shatter * 6.0)
	var measured_frost := float(save_manager._bullet_affinity_multiplier(frost, cryocannon, 40))
	_expect(absf(measured_frost - expected_frost) <= 0.0001, "design/29: frost affinity must include rank damage and runtime-equivalent shatter; expected %.5f got %.5f" % [expected_frost, measured_frost])
	var expected_frost_slow := 1.0 + (
		float(frost_affinity.get("slow_bonus", 0.0))
		+ float(frost_affinity.get("rank_slow_bonus", 0.0)) * 3.0
	) * 0.40
	var measured_frost_slow := float(save_manager._bullet_affinity_survival_multiplier(frost, cryocannon, 40))
	_expect(absf(measured_frost_slow - expected_frost_slow) <= 0.0001, "design/29: frost slow must enter survival power; expected %.5f got %.5f" % [expected_frost_slow, measured_frost_slow])

	var volt_affinity: Dictionary = volt.get("bullet_affinity", {})
	var volt_chain := int(volt_affinity.get("chain_bonus", 0)) + int(volt_affinity.get("rank_chain_bonus", 0))
	var expected_volt := (
		1.0
		+ float(volt_affinity.get("damage_bonus", 0.0))
		+ float(volt_affinity.get("rank_damage_bonus", 0.0)) * 3.0
	) * (
		1.0
		+ float(volt_chain) * 0.09 * clampf(float(volt_affinity.get("chain_target_falloff", 1.0)), 0.72, 1.0)
	) * (1.0 + float(volt_affinity.get("status_bonus", 0.0)) * 0.28) * (
		1.0
		+ float(int(volt_affinity.get("chain_overflow_reference", 0)) + volt_chain) * float(volt_affinity.get("chain_overflow_damage_bonus", 0.0))
	)
	var measured_volt := float(save_manager._bullet_affinity_multiplier(volt, teslacoil, 40))
	_expect(absf(measured_volt - expected_volt) <= 0.0001, "design/29: volt affinity must include chain retention, status, and overflow; expected %.5f got %.5f" % [expected_volt, measured_volt])

	var frost_hp := float(frost.get("base_hp", 100.0)) * (1.0 + float(frost.get("hp_growth", 0.0)) * 0.45 * 39.0)
	var blaze_hp := float(blaze.get("base_hp", 100.0)) * (1.0 + float(blaze.get("hp_growth", 0.0)) * 0.45 * 39.0)
	var hp_ratio := frost_hp / maxf(blaze_hp, 0.01)
	_expect(hp_ratio >= 1.68 and hp_ratio <= 1.74, "design/29: frost/blaze effective HP ratio must expose the authored ~1.7x identity, got %.4f" % hp_ratio)

func _apply_calibration_family(save_manager: Node, original_save: Dictionary, index: int) -> void:
	_apply_calibration_build(save_manager, original_save, "vanguard", mini(index, 40), "weapon_autocannon", mini(index, 50), "", 1, "chip_attack", mini(index, 35), "", 1, mini(index / 8, 5))

func _apply_calibration_build(save_manager: Node, original_save: Dictionary, character: String, char_level: int, weapon: String, weapon_level: int, armor: String, armor_level: int, chip: String, chip_level: int, pet: String, pet_level: int, sig_level: int) -> void:
	var save: Dictionary = original_save.duplicate(true)
	var equipment: Dictionary = save.get("equipment", {}).duplicate(true)
	equipment["selected_character"] = character
	equipment["selected_weapon"] = weapon
	equipment["selected_armor"] = armor
	equipment["selected_chip"] = chip
	equipment["selected_pet"] = pet
	equipment[character] = maxi(char_level, 1)
	equipment[weapon] = maxi(weapon_level, 1)
	if armor != "":
		equipment[armor] = maxi(armor_level, 1)
	if chip != "":
		equipment[chip] = maxi(chip_level, 1)
	if pet != "":
		equipment[pet] = maxi(pet_level, 1)
	save["equipment"] = equipment
	save["skill_base_levels"] = {}
	save["sig_skill_levels"] = {} if sig_level <= 0 else {character: sig_level}
	save_manager.save_data = save

func _dismiss_card_offer_for_smoke(battle: Node) -> void:
	if battle.has_method("_close_card_offer"):
		battle._close_card_offer(false)
	else:
		if battle.has_node("Hud/CardPanel"):
			battle.get_node("Hud/CardPanel").visible = false
		if battle.has_node("Hud/CardPanel/DetailOverlay"):
			battle.get_node("Hud/CardPanel/DetailOverlay").visible = false
		battle.card_offer_active = false
		battle.paused = false
		battle.get_tree().paused = false

func _verify_card_offer_full_pause(battle: Node) -> void:
	_expect(bool(battle.card_offer_active), "card offer must mark the battle as card-offer active")
	_expect(battle.get_tree().paused, "card offer must pause the whole scene tree")
	_expect(battle.get_node("Hud").process_mode == Node.PROCESS_MODE_ALWAYS, "HUD must remain interactive during card offer pause")
	var card_panel := battle.get_node("Hud/CardPanel") as Control
	_expect(card_panel.process_mode == Node.PROCESS_MODE_ALWAYS, "card panel must remain interactive during card offer pause")
	_expect(not battle.wave_toast_banner.visible, "card offer must clear any wave or onboarding toast behind the modal")
	_expect(battle.pending_wave_toast.is_empty(), "card offer must clear queued wave toasts so they do not reappear under the modal")
	var card_bounds: Vector2 = battle._card_offer_vertical_bounds()
	var cards := card_panel.get_node("Cards") as VBoxContainer
	var visible_card_height := 0.0
	var visible_card_count := 0
	for card_node in cards.get_children():
		var visible_card := card_node as Control
		if visible_card == null or not visible_card.visible:
			continue
		visible_card_height += visible_card.custom_minimum_size.y
		visible_card_count += 1
	if visible_card_count > 1:
		visible_card_height += float(cards.get_theme_constant("separation")) * float(visible_card_count - 1)
	var expected_content_height: float = battle.CARD_OFFER_CARDS_POS.y + visible_card_height + battle.CARD_OFFER_ACTION_GAP + battle.CARD_OFFER_ACTION_LANE_HEIGHT
	var expected_panel_height: float = minf(card_bounds.y - card_bounds.x, maxf(battle.CARD_OFFER_PANEL_SIZE.y, expected_content_height))
	_expect(absf(card_panel.size.y - expected_panel_height) <= 1.0, "card offer panel height must follow measured card content instead of stretching an empty tall-screen lane")
	var card_center_y := card_panel.position.y + card_panel.size.y * 0.5
	var battlefield_center_y := (card_bounds.x + card_bounds.y) * 0.5
	_expect(absf(card_center_y - battlefield_center_y) <= 1.0, "card offer panel must remain vertically centered between the top combat controls and the real breach line")
	_expect(card_panel.position.y >= card_bounds.x - 1.0 and card_panel.position.y + card_panel.size.y <= card_bounds.y + 1.0, "card offer panel must stay inside its centered battlefield corridor")
	for card_node in cards.get_children():
		var skill_card := card_node as Control
		if skill_card == null:
			continue
		var card_size := skill_card.size
		var icon_frame := skill_card.get_node_or_null("IconFrame") as Control
		var card_icon := skill_card.get_node_or_null("Icon") as TextureRect
		var card_title := skill_card.get_node_or_null("Title") as Label
		_expect(icon_frame != null and card_icon != null, "card offer must render its skill icon inside a dedicated frame")
		if icon_frame != null and card_icon != null:
			_expect(icon_frame.position.x >= 30.0, "card-offer skill icon frame must clear the ornamental left edge")
			_expect(icon_frame.size.x >= 192.0 and icon_frame.size.y >= 192.0, "card-offer skill icon frame must retain the enlarged mobile-readable size")
			_expect(card_icon.position.x > icon_frame.position.x and card_icon.position.y > icon_frame.position.y, "card-offer skill artwork must keep an inset inside its icon frame")
			_expect(card_icon.position.x + card_icon.size.x < icon_frame.position.x + icon_frame.size.x and card_icon.position.y + card_icon.size.y < icon_frame.position.y + icon_frame.size.y, "card-offer skill artwork must stay fully inside its icon frame")
			_expect(card_icon.size.x >= 176.0 and card_icon.size.y >= 176.0, "card-offer skill artwork must use the approved larger presentation")
		if icon_frame != null and card_title != null:
			_expect(card_title.position.x - (icon_frame.position.x + icon_frame.size.x) >= 20.0, "card-offer enlarged icon must keep a clear gap before title copy")
		var card_stats := skill_card.get_node_or_null("Stats") as Label
		var card_desc := skill_card.get_node_or_null("Desc") as Label
		for card_copy in [card_stats, card_desc]:
			if card_copy != null:
				_expect(card_copy.position.x + card_copy.size.x <= card_size.x - 24.0, "card-offer copy must retain right-frame clearance after the icon enlargement")
		var tags := skill_card.get_node_or_null("Tags") as Control
		if tags != null:
			_expect(tags.position.y + tags.size.y <= card_size.y - battle.CARD_OFFER_BOTTOM_PADDING + 0.5, "card tag chips must stay inside the rendered card frame")
		for badge_name in ["LevelBadge", "RecommendBadge"]:
			var badge := skill_card.get_node_or_null(badge_name) as Control
			if badge != null:
				_expect(badge.position.x + badge.size.x <= card_size.x - 40.0, "%s must keep a safe right inset inside the card" % badge_name)
	var reroll := card_panel.get_node("RerollButton") as TextureButton
	var skip := card_panel.get_node("SkipButton") as TextureButton
	var measured_action_gap := reroll.position.y - (cards.position.y + visible_card_height)
	_expect(absf(measured_action_gap - battle.CARD_OFFER_ACTION_GAP) <= 1.0, "card offer must keep the approved quiet lane after the final card without leaving a large blank region")
	_expect(absf(cards.size.y - visible_card_height) <= 1.0, "card offer list height must collapse to its three measured cards")
	var reroll_texture_path := str(reroll.texture_normal.resource_path) if reroll.texture_normal != null else ""
	var skip_texture_path := str(skip.texture_normal.resource_path) if skip.texture_normal != null else ""
	_expect(reroll_texture_path.ends_with("ui_button_primary_native_412x88.png"), "card reroll button must use the native primary armored texture, got %s" % reroll_texture_path)
	_expect(skip_texture_path.ends_with("ui_button_secondary_native_412x88.png"), "card skip button must use the native secondary armored texture, got %s" % skip_texture_path)
	_expect(battle.get_node("PauseLayer").process_mode == Node.PROCESS_MODE_ALWAYS, "pause layer must remain input-capable while the tree is paused")
	for path in ["EnemyLayer", "ProjectileLayer", "ThreatMarkerLayer", "SlowFieldLayer", "LockIndicator"]:
		var node := battle.get_node(path)
		_expect(node.process_mode == Node.PROCESS_MODE_PAUSABLE, "%s must not inherit Battle PROCESS_MODE_ALWAYS during card offer" % path)
	_expect(battle.turret != null and battle.turret.process_mode == Node.PROCESS_MODE_PAUSABLE, "turret must be pausable during card offer")
	_expect(battle.character_rig != null and battle.character_rig.process_mode == Node.PROCESS_MODE_PAUSABLE, "character rig must be pausable during card offer")
	if battle.pet_sprite != null:
		_expect(battle.pet_sprite.process_mode == Node.PROCESS_MODE_PAUSABLE, "pet must be pausable during card offer")
	if battle.get_node("EnemyLayer").get_child_count() > 0:
		var enemy := battle.get_node("EnemyLayer").get_child(0)
		_expect(enemy.process_mode != Node.PROCESS_MODE_ALWAYS, "live enemies must not force processing during card offer")

func _verify_card_offer_same_frame_rebuild(battle: Node) -> void:
	var cards := battle.get_node("Hud/CardPanel/Cards") as VBoxContainer
	var outgoing_cards := cards.get_children()
	# Rebuild twice without yielding, matching a reroll/new-offer transition in
	# the exact frame where the old controls are still queued for deletion.
	battle._render_card_offer(battle.skills.owned)
	battle._render_card_offer(battle.skills.owned)
	_expect(cards.get_child_count() == 3, "same-frame card-offer rebuild must expose only the current trio to layout")
	for outgoing_card in outgoing_cards:
		_expect(outgoing_card.get_parent() == null, "outgoing offer cards must detach before deferred deletion")
	_verify_card_offer_full_pause(battle)
	await process_frame
	_expect(cards.get_child_count() == 3, "deferred card cleanup must not remove the replacement trio")
	_verify_card_offer_full_pause(battle)

func _verify_all_skill_offer_copy_layouts(battle: Node) -> void:
	var data_loader := root.get_node("/root/DataLoader")
	var localization_manager := root.get_node("/root/LocalizationManager")
	var original_language := str(localization_manager.current_language)
	var skill_table: Dictionary = data_loader.get_table("skills")
	var authored_skill_levels := 0
	for skill_row_value in skill_table.values():
		var authored_levels: Array = (skill_row_value as Dictionary).get("levels", [])
		authored_skill_levels += maxi(1, authored_levels.size())
	var verified_cards := 0
	for language in ["zh", "en"]:
		localization_manager.apply_language(language, false)
		var fixture := VBoxContainer.new()
		fixture.name = "SkillOfferWrapFixture_" + language
		fixture.position = Vector2(-2400.0, -2400.0)
		fixture.size = Vector2(battle.CARD_OFFER_CARD_WIDTH, 4000.0)
		fixture.add_theme_constant_override("separation", battle.CARD_OFFER_CARD_SEPARATION)
		root.add_child(fixture)
		var language_card_heights: Array[float] = []
		for skill_id_value in skill_table.keys():
			var skill_id := str(skill_id_value)
			var row: Dictionary = skill_table.get(skill_id, {})
			var level_count := maxi(1, (row.get("levels", []) as Array).size())
			for skill_level in range(1, level_count + 1):
				var display_name: String = str(data_loader.tr_key(row.get("name_key", skill_id)))
				var card := battle._build_skill_card(skill_id, row, display_name, skill_level) as Panel
				card.name = "%s_%d" % [skill_id, skill_level]
				fixture.add_child(card)
				verified_cards += 1
		await process_frame
		for card_node in fixture.get_children():
			var card := card_node as Panel
			battle._layout_skill_offer_card(card)
			var stats := card.get_node_or_null("Stats") as Label
			var desc := card.get_node_or_null("Desc") as Label
			var tags := card.get_node_or_null("Tags") as Control
			_expect(stats != null and desc != null and tags != null, "%s %s must expose measured stats, description and tag lanes" % [language, card.name])
			if stats == null or desc == null or tags == null:
				continue
			_expect(_label_required_height_for_smoke(stats) <= stats.size.y + 0.5, "%s %s stats must reserve automatic wrapped lines" % [language, card.name])
			_expect(_label_required_height_for_smoke(desc) <= desc.size.y + 0.5, "%s %s description must reserve automatic wrapped lines" % [language, card.name])
			_expect(stats.position.y + stats.size.y + battle.CARD_OFFER_COPY_GAP <= desc.position.y + 0.5, "%s %s description must begin below the complete stats block" % [language, card.name])
			_expect(desc.position.y + desc.size.y + battle.CARD_OFFER_COPY_GAP <= tags.position.y + 0.5, "%s %s tags must begin below the complete description block" % [language, card.name])
			_expect(tags.position.y + tags.size.y + battle.CARD_OFFER_BOTTOM_PADDING <= card.size.y + 0.5, "%s %s card must grow to contain every wrapped lane" % [language, card.name])
			language_card_heights.append(card.size.y)
		# Any possible three-card offer must still fit above the primary actions and
		# inside the battlefield corridor, even when all three use the longest copy.
		language_card_heights.sort()
		var worst_three_height := 0.0
		for height_index in range(maxi(0, language_card_heights.size() - 3), language_card_heights.size()):
			worst_three_height += language_card_heights[height_index]
		if language_card_heights.size() >= 3:
			worst_three_height += float(battle.CARD_OFFER_CARD_SEPARATION * 2)
		var bounds: Vector2 = battle._card_offer_vertical_bounds()
		var maximum_card_lane: float = bounds.y - bounds.x - float(battle.CARD_OFFER_CARDS_POS.y) - float(battle.CARD_OFFER_ACTION_GAP) - 124.0
		_expect(worst_three_height <= maximum_card_lane + 0.5, "%s three longest skill cards must fit the live battlefield modal; need %.1f have %.1f" % [language, worst_three_height, maximum_card_lane])
		fixture.queue_free()
		await process_frame
	localization_manager.apply_language(original_language, false)
	_expect(skill_table.size() >= 16, "skill offer wrap regression must retain the complete authored skill roster")
	_expect(verified_cards == authored_skill_levels * 2, "skill offer wrap regression must inspect every authored skill level in both languages")

func _label_required_height_for_smoke(label: Label) -> float:
	if label == null:
		return INF
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	if font == null or font_size <= 0:
		return 0.0
	var text_width := maxf(1.0, label.size.x - 8.0)
	var measured := font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, text_width, font_size)
	var line_height := maxf(1.0, font.get_height(font_size))
	var line_count := maxi(1, int(ceil(measured.y / line_height)))
	var line_spacing := label.get_theme_constant("line_spacing")
	return ceil(measured.y + float(maxi(0, line_count - 1) * line_spacing))

func _verify_ui_font() -> void:
	var font_path := "res://assets/production/fonts/font_main.ttf"
	_expect(str(ProjectSettings.get_setting("gui/theme/custom_font")) == font_path, "project must use the production CJK font as the global UI font")
	_expect(int(ProjectSettings.get_setting("gui/theme/default_font_size")) == 34, "global inherited UI font must be two logical pixels larger for mobile readability")
	_expect(UiKit.FONT_SIZE_STEP == 2, "all authored UI font paths must keep the global two-pixel readability step")
	_expect(UiKit.scaled_font_size(20) == 32, "UiKit scaled labels must include the 1.5x global scale and two-pixel readability step")
	_expect(UiKit.bumped_font_size(20) == 22, "direct runtime labels must include the same two-pixel readability step")
	var font := FontFile.new()
	var err := font.load_dynamic_font(font_path)
	_expect(err == OK, "production UI font must load")
	_expect(font.has_char("鉴".unicode_at(0)), "production UI font must include the glyph for 鉴")

func _verify_manual_aim_input(input_manager: Node) -> void:
	var started := {"count": 0, "pos": Vector2.ZERO}
	var aimed := {"count": 0, "pos": Vector2.ZERO}
	var released := {"count": 0, "pos": Vector2.ZERO}
	var lock_requested := {"count": 0, "pos": Vector2.ZERO}
	var on_started := func(pos: Vector2) -> void:
		started["count"] = int(started.get("count", 0)) + 1
		started["pos"] = pos
	var on_aimed := func(pos: Vector2) -> void:
		aimed["count"] = int(aimed.get("count", 0)) + 1
		aimed["pos"] = pos
	var on_released := func(pos: Vector2) -> void:
		released["count"] = int(released.get("count", 0)) + 1
		released["pos"] = pos
	var on_lock_requested := func(pos: Vector2) -> void:
		lock_requested["count"] = int(lock_requested.get("count", 0)) + 1
		lock_requested["pos"] = pos
	input_manager.manual_aim_started.connect(on_started)
	input_manager.aim_point.connect(on_aimed)
	input_manager.manual_aim_released.connect(on_released)
	input_manager.target_locked.connect(on_lock_requested)

	input_manager._cancel_aim_press()
	input_manager._begin_aim_press(Vector2(240, 760), -1)
	input_manager._process(0.0)
	_expect(int(started.get("count", 0)) == 0, "manual aim must not start before the long-press threshold")
	input_manager._aim_press_started_at = input_manager._now_seconds() - 0.36
	input_manager._process(0.0)
	_expect(int(started.get("count", 0)) == 1, "manual aim must start only after a long mouse/finger press")
	_expect((started.get("pos", Vector2.ZERO) as Vector2).distance_to(Vector2(240, 760)) <= 1.0, "manual aim start must use the held point")
	_expect(int(aimed.get("count", 0)) >= 1, "manual aim long press must emit an aim point")
	input_manager._update_aim_press(Vector2(420, 640), -1)
	_expect((aimed.get("pos", Vector2.ZERO) as Vector2).distance_to(Vector2(420, 640)) <= 1.0, "manual aim must update while held and dragged")
	input_manager._end_aim_press(Vector2(430, 620), -1)
	_expect(int(released.get("count", 0)) == 1, "manual aim must emit release when the long press ends")
	_expect((released.get("pos", Vector2.ZERO) as Vector2).distance_to(Vector2(430, 620)) <= 1.0, "manual aim release must use the final pointer position")

	var starts_after_long_press := int(started.get("count", 0))
	input_manager._begin_aim_press(Vector2(180, 500), -1)
	input_manager._aim_press_started_at = input_manager._now_seconds() - 0.05
	input_manager._process(0.0)
	input_manager._end_aim_press(Vector2(180, 500), -1)
	_expect(int(started.get("count", 0)) == starts_after_long_press, "short click/tap must not steal auto aim priority")

	input_manager._last_tap_time = 0.0
	input_manager._last_tap_pos = Vector2.ZERO
	input_manager._handle_touch_lock(Vector2(420, 680))
	_expect(int(lock_requested.get("count", 0)) == 0, "one touch tap must wait for the deliberate double-tap lock gesture")
	input_manager._handle_touch_lock(Vector2(426, 684))
	_expect(int(lock_requested.get("count", 0)) == 1, "a second nearby touch tap must request target lock")
	_expect((lock_requested.get("pos", Vector2.ZERO) as Vector2).distance_to(Vector2(426, 684)) <= 1.0, "touch lock must use the tapped enemy position")

	input_manager._cancel_aim_press()
	input_manager.manual_aim_started.disconnect(on_started)
	input_manager.aim_point.disconnect(on_aimed)
	input_manager.manual_aim_released.disconnect(on_released)
	input_manager.target_locked.disconnect(on_lock_requested)

func _verify_targeting_frontline_priority() -> void:
	var manager := TargetingManager.new()
	manager.strategy = "breach"
	var front := FakeAimTarget.new()
	var back := FakeAimTarget.new()
	front.global_position = Vector2(540, 1455)
	front.breach_damage = 4
	front.threat_tags = []
	back.global_position = Vector2(540, 520)
	back.breach_damage = 72
	back.threat_tags = ["breach"]
	var chosen := manager.choose_target([back, front], Vector2(540, 1660))
	_expect(chosen == front, "default auto aim must prefer the frontline enemy over a backline threat")
	front.free()
	back.free()
	manager.free()

func _verify_turret_fire_gate(data_loader: Node) -> void:
	var turret := _instance("res://gameplay/turret/turret.tscn")
	root.add_child(turret)
	turret.setup(data_loader.get_row("weapons", "weapon_autocannon"), 1)
	turret.global_position = Vector2(540, 1660)
	turret.aim_at(Vector2(540, 360))
	var fired := {"count": 0}
	turret.fired.connect(func(_origin: Vector2, _direction: Vector2) -> void:
		fired["count"] = int(fired.get("count", 0)) + 1
	)
	turret.set("fire_enabled", false)
	turret.cooldown = 0.0
	turret._physics_process(0.6)
	_expect(int(fired.get("count", 0)) == 0, "turret must not fire when no live target is available")
	turret.set("fire_enabled", true)
	turret.cooldown = 0.0
	turret._physics_process(0.6)
	_expect(int(fired.get("count", 0)) == 1, "turret must fire once fire_enabled is granted by battle targeting")
	turret.queue_free()
	await process_frame

func _verify_manual_aim_battle_priority(battle: Node) -> void:
	var auto_target := FakeAimTarget.new()
	auto_target.global_position = Vector2(540, 1460)
	auto_target.breach_damage = 1
	auto_target.threat_tags = []
	battle.get_node("EnemyLayer").add_child(auto_target)
	battle.target_manager.clear_lock()

	var manual_point := Vector2(70, 90)
	battle._on_manual_aim_started(manual_point)
	battle._update_auto_target()
	_expect(battle.turret.target_point.distance_to(manual_point) <= 1.0, "active manual aim must override automatic target selection")

	var dragged_point := Vector2(980, 520)
	battle._on_manual_aim_point(dragged_point)
	battle._update_auto_target()
	_expect(battle.turret.target_point.distance_to(dragged_point) <= 1.0, "manual aim must keep following the held pointer")
	var manual_origin: Vector2 = battle._weapon_fire_origin(false)
	var manual_direction: Vector2 = (dragged_point - manual_origin).normalized()
	var manual_fan: Array[Vector2] = battle._primary_shot_directions(manual_origin, manual_direction, 2, deg_to_rad(7.0))
	var manual_lane_hits_aim := false
	for direction in manual_fan:
		if absf(direction.angle_to(manual_direction)) <= 0.001:
			manual_lane_hits_aim = true
			break
	_expect(manual_lane_hits_aim, "multi-shot must keep one lane exactly on the active manual aim point")

	battle._on_manual_aim_released(dragged_point)
	battle.manual_aim_until = 0.0
	battle._update_auto_target()
	_expect(battle.turret.target_point.distance_to(dragged_point) > 1.0, "auto aim must resume after manual aim release grace")
	battle.get_node("EnemyLayer").remove_child(auto_target)
	auto_target.free()

func _verify_manual_target_lock_battle(battle: Node) -> void:
	var locked_target := FakeAimTarget.new()
	locked_target.global_position = Vector2(330, 820)
	battle.get_node("EnemyLayer").add_child(locked_target)
	battle.target_manager.clear_lock()
	battle._on_target_lock_requested(locked_target.global_position + Vector2(8, -6))
	_expect(battle.target_manager.has_lock(), "touching a zombie with the lock gesture must create a persistent manual target")
	_expect(battle.target_manager.locked_enemy == locked_target, "manual lock must select the zombie nearest the touched point")
	battle._update_auto_target()
	_expect(battle.turret.target_point.distance_to(locked_target.global_position) <= 1.0, "automatic fire must continue aiming at the manually locked zombie")
	battle._on_target_lock_requested(Vector2(1040, 1840))
	_expect(not battle.target_manager.has_lock(), "the lock gesture on empty battlefield space must clear manual target lock")
	battle.get_node("EnemyLayer").remove_child(locked_target)
	locked_target.free()

func _verify_xp_bar_single_track(battle: Node) -> void:
	var wave_bar := battle.get_node("Hud/TopBar/WaveProgress") as Control
	_expect(wave_bar.size.x <= 720.1 and wave_bar.size.x >= 640.0, "top wave progress must be compact, centered, and not span the whole screen")
	var wave_clip := wave_bar.get_node_or_null("FillClip") as Control
	var wave_fill := wave_bar.get_node_or_null("FillClip/FillTexture") as TextureRect
	_expect(wave_clip != null and wave_fill != null, "wave fill must be clipped instead of scaled directly")
	_expect(wave_clip.position.x >= 36.0 and wave_clip.position.x + wave_fill.size.x <= wave_bar.size.x - 36.0, "wave fill must stay inside the native rendered progress frame")
	_expect(wave_fill.size.y >= 17.0 and str(wave_fill.texture.resource_path).ends_with("ui_wave_progress_fill_native.png"), "wave fill must use the native-height rendered texture")
	var xp_bar := battle.get_node("Hud/BottomBar/XpBar") as Control
	_expect(xp_bar != null, "battle must expose the XP bar")
	_expect(xp_bar.clip_contents, "XP bar must clip its single fill track")
	_expect(not xp_bar.has_node("Under"), "XP bar must not keep the old texture underlay that creates double bars")
	_expect(xp_bar.has_node("Track"), "XP bar must render one styled track")
	var fill := xp_bar.get_node("Fill") as Panel
	_expect(fill != null, "XP bar fill must be a single Panel, not a second texture bar")
	var label := xp_bar.get_node("Label") as Label
	_expect(label != null, "XP bar must render a centered label")
	_expect(label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "XP bar label must be horizontally centered")
	_expect(label.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "XP bar label must be vertically centered")
	_expect(label.position.x <= 0.1 and label.size.x >= xp_bar.size.x - 0.1, "XP bar label must span the full track for true centering")
	battle.xp = 914
	battle.next_xp_offer = 1000000000
	battle._update_hud()
	_expect(label.text == "经验 914/1.0b", "XP bar must compact huge thresholds instead of overflowing with raw digits")

func _verify_pause_freezes_battle(battle: Node) -> void:
	var enemy_layer := battle.get_node("EnemyLayer")
	_expect(enemy_layer.get_child_count() > 0, "pause regression needs at least one live enemy")
	var first_enemy := enemy_layer.get_child(0) as Node2D
	var enemy_pos := first_enemy.global_position
	var spawn_timer_before := float(battle.spawn_timer)
	var pending_before := int(battle.pending_spawns.size())
	var pet_cooldown_before := float(battle.pet_cooldown)
	var projectiles_before := battle.get_node("ProjectileLayer").get_child_count()
	battle._on_pause_pressed()
	_expect(bool(battle.paused) and battle.get_tree().paused, "pause button must set both battle and tree pause")
	_expect(battle.get_node("Hud/PauseOverlay").visible, "pause button must show pause overlay")
	_expect(not battle.get_node("Hud/TopBar").visible, "pause overlay must hide top combat bars instead of letting them crowd the pause title")
	_expect(not battle.get_node("PauseLayer/PauseButton").visible, "pause overlay must hide the floating pause button")
	var pause_panel := battle.get_node("Hud/PauseOverlay/Panel") as Control
	_expect(pause_panel != null and pause_panel.clip_contents, "pause panel must clip its content")
	_expect(pause_panel.has_node("PauseContent"), "pause panel must render structured content instead of raw text only")
	var content := pause_panel.get_node("PauseContent") as Control
	var resume_button := pause_panel.get_node("ResumeButton") as Control
	_expect(content.position.y + content.size.y <= resume_button.position.y - 32.0, "pause content must leave breathing room before the action buttons")
	_expect(content.position.x <= 46.0 and content.size.x >= 880.0, "pause information cards must use the widened reading lane")
	var status_card := content.get_child(0) as PanelContainer
	var status_body := status_card.get_node("Body") as VBoxContainer
	var status_title := status_body.get_node("Header/SectionTitle") as Label
	var status_grid := status_body.get_child(1) as GridContainer
	var first_metric := status_grid.get_child(0) as PanelContainer
	var first_metric_row := first_metric.get_child(0) as HBoxContainer
	var first_metric_key := first_metric_row.get_node("MetricKey") as Label
	var first_metric_value := first_metric_row.get_node("MetricValue") as Label
	_expect(status_title.get_theme_font_size("font_size") >= UiKit.scaled_font_size(25), "pause section titles must keep the enlarged readable type")
	_expect(first_metric.size.y >= 66.0, "pause metric rows must leave vertical frame clearance around enlarged type")
	_expect(first_metric_key.get_theme_font_size("font_size") >= UiKit.scaled_font_size(17), "pause metric keys must keep the enlarged bilingual type")
	_expect(first_metric_value.get_theme_font_size("font_size") >= UiKit.scaled_font_size(18), "pause metric values must keep the enlarged bilingual type")
	var legacy_summary := battle.get_node("Hud/PauseOverlay/Panel/BuildSummary") as Label
	_expect(legacy_summary != null and not legacy_summary.visible, "pause legacy summary text must be hidden behind designed cards")
	var action_buttons: Array[Control] = []
	for button_path in ["ResumeButton", "RestartButton", "MapButton"]:
		var button := pause_panel.get_node(button_path) as Control
		action_buttons.append(button)
		var rect := Rect2(button.position, button.size)
		_expect(rect.position.y >= 0.0 and rect.end.y <= pause_panel.size.y, "pause %s must stay inside the panel bounds" % button_path)
		_expect(button.size.x >= 270.0 and button.size.y >= 152.0, "pause %s must keep the extra-tall three-column touch target" % button_path)
		_expect(button.has_node("IconPlate") and button.has_node("ActionTitle"), "pause %s must use the compact icon and title styling" % button_path)
		_expect(not button.has_node("ActionSub") and not button.has_node("ActionArrow"), "pause %s must not crowd the compact action with subtitle or arrow chrome" % button_path)
		_expect(str(button.get_meta("pause_action_layout", "")) == "three_column_compact", "pause %s must declare the approved three-column layout" % button_path)
		var safe_rect := button.get_meta("pause_action_safe_rect", Rect2()) as Rect2
		_expect(safe_rect.position.y >= 28.0 and button.size.y - safe_rect.end.y >= 28.0, "pause %s must retain explicit top and bottom bezel clearance" % button_path)
		for child_name in ["IconPlate", "ActionTitle"]:
			var child := button.get_node(child_name) as Control
			var child_rect := Rect2(child.position, child.size)
			_expect(safe_rect.encloses(child_rect), "pause %s/%s must stay inside the deepest five-theme frame safe area (safe=%s child=%s)" % [button_path, child_name, safe_rect, child_rect])
		var action_title := button.get_node("ActionTitle") as Label
		_expect(action_title.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "pause %s title must be vertically centered in its single row" % button_path)
		_expect(action_title.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "pause %s short title must be centered beside its icon" % button_path)
		var icon_plate := button.get_node("IconPlate") as Control
		_expect(icon_plate.position.x + icon_plate.size.x <= action_title.position.x, "pause %s icon and title must keep the approved horizontal order" % button_path)
	_expect(action_buttons[0].position.y == action_buttons[1].position.y and action_buttons[1].position.y == action_buttons[2].position.y, "pause actions must share one horizontal row")
	_expect(action_buttons[0].position.x < action_buttons[1].position.x and action_buttons[1].position.x < action_buttons[2].position.x, "pause actions must keep left/centre/right ordering")
	var pause_localization := root.get_node("/root/LocalizationManager")
	_expect((action_buttons[0].get_node("ActionTitle") as Label).text == pause_localization.text("继续"), "pause primary action must use the short Resume label")
	_expect((action_buttons[1].get_node("ActionTitle") as Label).text == pause_localization.text("重开"), "pause restart action must use the short Restart label")
	_expect((action_buttons[2].get_node("ActionTitle") as Label).text == pause_localization.text("退出"), "pause exit action must use the short Exit label")
	# Late chapters can carry 8-10 skills. The previous fixed-height skill card
	# silently grew past its clamp at 7 skills and, because it was rebuilt after
	# the authored buttons, painted over the whole action row. Exercise the real
	# ten-skill ceiling so the three actions can never become intermittent again.
	var original_skill_slot_ids: Array[String] = battle.skill_slot_ids.duplicate()
	var skill_table: Dictionary = root.get_node("/root/DataLoader").get_table("skills")
	var stress_skill_ids: Array[String] = []
	var sorted_skill_ids: Array = skill_table.keys()
	sorted_skill_ids.sort()
	for skill_id_var in sorted_skill_ids:
		stress_skill_ids.append(str(skill_id_var))
		if stress_skill_ids.size() == 10:
			break
	_expect(stress_skill_ids.size() == 10, "pause max-skill regression requires ten data-backed skills")
	battle.skill_slot_ids = stress_skill_ids
	battle._rebuild_pause_overlay_content()
	content = pause_panel.get_node("PauseContent") as Control
	resume_button = pause_panel.get_node("ResumeButton") as Control
	_expect(int(battle._pause_skill_row_count()) == 4, "ten pause skills must wrap into four rows")
	_expect(content.get_combined_minimum_size().y <= content.size.y + 0.1, "pause content must allocate the full intrinsic height of ten skills (minimum=%.1f size=%.1f)" % [content.get_combined_minimum_size().y, content.size.y])
	_expect(content.position.y + content.size.y <= resume_button.position.y - 32.0, "ten-skill pause content must leave the action-row gap")
	for button_path in ["ResumeButton", "RestartButton", "MapButton"]:
		var stress_button := pause_panel.get_node(button_path) as Control
		_expect(stress_button.visible, "pause %s must remain visible with ten carried skills" % button_path)
		_expect(stress_button.z_index > content.z_index, "pause %s must render above rebuilt dynamic content" % button_path)
		_expect(stress_button.position.y + stress_button.size.y <= pause_panel.size.y, "pause %s must remain inside the grown ten-skill panel" % button_path)
	battle.skill_slot_ids = original_skill_slot_ids
	battle._rebuild_pause_overlay_content()
	battle._physics_process(1.0)
	_expect(first_enemy.global_position.distance_to(enemy_pos) <= 0.1, "pause must freeze enemy movement even though Battle processes always")
	_expect(absf(float(battle.spawn_timer) - spawn_timer_before) <= 0.001, "pause must not advance spawn timer")
	_expect(int(battle.pending_spawns.size()) == pending_before, "pause must not consume pending spawns")
	_expect(absf(float(battle.pet_cooldown) - pet_cooldown_before) <= 0.001, "pause must not advance pet attack cooldown")
	_expect(battle.get_node("ProjectileLayer").get_child_count() == projectiles_before, "pause must not spawn pet or weapon projectiles")
	_expect(not bool(battle.turret.get("fire_enabled")), "pause must disable turret firing permission")
	battle._on_resume_pressed()
	_expect(not bool(battle.paused) and not battle.get_tree().paused, "resume button must restore battle processing")
	_expect(battle.get_node("Hud/TopBar").visible, "resume must restore top combat bars")
	_expect(battle.get_node("PauseLayer/PauseButton").visible, "resume must restore the floating pause button")

func _verify_runtime_skill_hints(battle: Node) -> void:
	var button := battle.get_node("Hud/CharacterSkillButton") as BaseButton
	button.emit_signal("mouse_entered")
	await process_frame
	_expect(not battle.get_node("Hud/SkillHintOverlay").visible, "active skill hover must not cover combat with an unsolicited explanation")
	button.emit_signal("mouse_exited")
	await process_frame
	battle._begin_skill_hint_press("character", "")
	battle.skill_hint_press_started_at -= 0.5
	battle._process(0.0)
	_expect(battle.get_node("Hud/SkillHintOverlay").visible, "active skill long press must show a readable skill explanation")
	battle._end_skill_hint_press()
	_expect(battle.get_node("Hud/SkillHintOverlay").visible, "active skill explanation must stay visible after the long press ends")
	_expect(float(battle.skill_hint_auto_hide_at) > Time.get_ticks_msec() / 1000.0, "active skill explanation must arm its three-second auto-dismiss deadline")
	_expect(battle._consume_skill_hint_press(Vector2(540, 820)), "empty battlefield tap must be consumed as a skill-hint dismissal")
	_expect(not battle.get_node("Hud/SkillHintOverlay").visible, "empty battlefield tap must dismiss the active skill explanation")
	_expect(is_zero_approx(float(battle.skill_hint_auto_hide_at)), "manual skill-hint dismissal must clear its pending timeout")
	# Mirror the BaseButton release signal so the one-shot suppression is
	# consumed before the next independent active-skill regression.
	battle._on_character_skill_pressed()

	battle._show_character_skill_hint()
	_expect(battle.get_node("Hud/SkillHintOverlay").visible, "active skill explanation must reopen for timeout regression")
	battle.skill_hint_auto_hide_at = Time.get_ticks_msec() / 1000.0 - 0.01
	battle._process(0.0)
	_expect(not battle.get_node("Hud/SkillHintOverlay").visible, "active skill explanation must auto-dismiss after three seconds without input")
	_expect(is_zero_approx(float(battle.skill_hint_auto_hide_at)), "automatic skill-hint dismissal must clear its deadline")

	if battle.skills.level("skill_split_shot") <= 0:
		_expect(battle.skills.add_skill("skill_split_shot"), "skill hint regression must seed a bottom skill slot")
	battle._update_skill_slots()
	await process_frame
	var slots := battle.get_node("Hud/SkillSlots")
	_expect(slots.has_node("skill_split_shot"), "seeded skill must render in the bottom skill shelf")
	var slot := slots.get_node("skill_split_shot")
	slot.emit_signal("mouse_entered")
	await process_frame
	_expect(not battle.get_node("Hud/SkillHintOverlay").visible, "owned skill hover must not cover combat before an explicit tap")
	battle._begin_skill_hint_press("skill", "skill_split_shot")
	battle._end_skill_hint_press()
	_expect(not battle.get_node("Hud/SkillHintOverlay").visible, "single tapping an owned skill must not open a hold-only explanation")
	battle._begin_skill_hint_press("skill", "skill_split_shot")
	battle.skill_hint_press_started_at -= 0.5
	battle._process(0.0)
	_expect(battle.get_node("Hud/SkillHintOverlay").visible, "long pressing an owned skill must show a readable skill explanation")
	battle._end_skill_hint_press()
	var slot_center: Vector2 = (slot as Control).get_global_rect().get_center()
	_expect(not battle._consume_skill_hint_press(slot_center), "another skill action must remain directly tappable while a hint is visible")
	_expect(battle.get_node("Hud/SkillHintOverlay").visible, "tapping another skill action must not be swallowed as an empty-space dismissal")
	battle._hide_skill_hint()

func _verify_wave_toast_wrapping(battle: Node) -> void:
	var long_tip := "自动开火会优先压制近线威胁，点僵尸可锁定优先击杀。"
	battle._show_wave_toast(long_tip, Color(0.72, 0.92, 1.0))
	var banner := battle.get_node("Hud/WaveBanner") as Control
	var label := banner.get_node("Text") as Label
	_expect(banner.has_node("Band"), "wave toast must use the soft gradient band (not the old bordered plate)")
	_expect(banner.size.y >= 128.0, "long wave toast must expand vertically for two-line copy")
	_expect(label.autowrap_mode != TextServer.AUTOWRAP_OFF, "long wave toast must enable text wrapping")
	_expect(label.clip_text, "long wave toast must clip text inside the card bounds")
	_expect(label.size.x <= banner.size.x - 32.0, "long wave toast label must stay inside the banner bounds")
	_expect(label.text == long_tip, "long wave toast must preserve the full onboarding copy")

func _verify_boss_hp_hud_layout(battle: Node) -> void:
	var hud := battle.get_node("Hud/BossHpBar") as Control
	var label := hud.get_node("Label") as Label
	var armor_track := hud.get_node("ArmorTrack") as Control
	var armor_fill := hud.get_node("ArmorFill") as Control
	var track := hud.get_node("Track") as Control
	var fill := hud.get_node("Fill") as Control
	var effective_font := label.get_theme_font_size("font_size")
	var effective_outline := label.get_theme_constant("outline_size")
	var required_height := float(effective_font + effective_outline * 2)
	_expect(label.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "Boss identity must be vertically centered in its dedicated text band")
	_expect(label.size.y >= required_height, "Boss identity band must contain the scaled font and outline without clipping")
	_expect(track.position.y - (label.position.y + label.size.y) >= float(battle.BOSS_HP_LABEL_TRACK_GAP) - 0.1, "Boss identity must keep a 10px clear gap above the HP rail")
	_expect(not label.get_rect().intersects(track.get_rect()), "Boss identity text box must never overlap the HP rail")
	_expect(fill.position.y >= track.position.y and fill.position.y + fill.size.y <= track.position.y + track.size.y, "Boss HP fill must remain inside its track")
	_expect(track.position.y + track.size.y <= hud.size.y, "Boss HP rail must remain inside the shared HUD container")
	_expect(armor_fill.position.y >= armor_track.position.y and armor_fill.position.y + armor_fill.size.y <= armor_track.position.y + armor_track.size.y, "Boss armor fill must remain inside its track")
	_expect(armor_track.position.y - (label.position.y + label.size.y) >= float(battle.BOSS_HP_LABEL_TRACK_GAP) - 0.1, "Boss armor rail must keep the identity safety gap")
	_expect(float(battle.BOSS_HP_STACKED_TRACK_POSITION.y) >= armor_track.position.y + armor_track.size.y, "stacked Boss body rail must stay below the armor rail")

func _verify_skill_runtime_mods(save_manager: Node) -> void:
	# SkillRuntime intentionally seeds a newly picked card from the player's
	# permanent skill level. Keep this contract test independent from whatever
	# real save happens to be present on the machine running the release check.
	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var isolated_save: Dictionary = original_save.duplicate(true)
	isolated_save["skill_base_levels"] = {}
	save_manager.save_data = isolated_save
	var progression_runtime := SkillRuntime.new()
	var expected_extra_projectiles := [1, 2, 3, 3, 4]
	var expected_lane_damage_bonus := [0.0, 0.0, 0.0, 0.08, 0.02]
	for level_index in range(5):
		_expect(progression_runtime.add_skill("skill_multishot"), "multishot level %d must be addable" % (level_index + 1))
		var progression_mods: Dictionary = progression_runtime.projectile_mods()
		_expect(
			int(progression_mods.get("extra_projectiles", 0)) == int(expected_extra_projectiles[level_index]),
			"multishot Lv%d must add %d projectiles" % [level_index + 1, expected_extra_projectiles[level_index]],
		)
		_expect(
			absf(float(progression_mods.get("multishot_lane_damage_bonus", 0.0)) - float(expected_lane_damage_bonus[level_index])) <= 0.001,
			"multishot Lv%d must expose the authored lane damage compensation" % (level_index + 1),
		)
	var runtime := SkillRuntime.new()
	runtime.add_skill("skill_multishot")
	runtime.add_skill("skill_salvo")
	var mods: Dictionary = runtime.projectile_mods()
	_expect(int(mods.get("extra_projectiles", 0)) == 1, "multishot alone must add projectile lanes")
	_expect(int(mods.get("split", 0)) == 0, "multishot alone must not add split/scatter behavior")
	_expect(int(mods.get("chain", 0)) == 0, "multishot alone must not add ricochet behavior")
	_expect(runtime.fire_rate_multiplier() > 1.2, "salvo must now increase fire rate instead of duplicating multishot")
	_expect(runtime.add_skill("skill_homing"), "homing must stack with multishot")
	mods = runtime.projectile_mods()
	_expect(float(mods.get("homing", 0.0)) > 0.0 and int(mods.get("extra_projectiles", 0)) == 1, "homing and multishot must stack without replacing each other")
	_expect(int(mods.get("split", 0)) == 0 and int(mods.get("chain", 0)) == 0, "homing + multishot must not implicitly add split or ricochet")
	var ricochet_runtime := SkillRuntime.new()
	_expect(ricochet_runtime.add_skill("skill_ricochet"), "ricochet must be addable")
	mods = ricochet_runtime.projectile_mods()
	_expect(int(mods.get("split", 0)) == 0, "ricochet must not masquerade as split-shot")
	_expect(int(mods.get("chain", 0)) == 1 and int(mods.get("ricochet", 0)) == 1, "ricochet must expose chain count only")
	save_manager.save_data = original_save

func _verify_slow_field_range_contract(data_loader: Node) -> void:
	var row: Dictionary = data_loader.get_row("skills", "skill_slow_field")
	_expect(not row.is_empty(), "slow field skill row must exist")
	var expected_y_min := {
		1: 1050.0,
		2: 900.0,
		3: 750.0,
		4: 600.0,
		5: 450.0,
	}
	var expected_slow := {
		1: 0.30,
		2: 0.40,
		3: 0.50,
		4: 0.60,
		5: 0.80,
	}
	var battle := _instance("res://gameplay/battle/battle.tscn")
	battle._spawn_slow_field_visual()
	_expect(battle.slow_field_rect.name == "SlowFieldSurfaceTiles", "slow field must use the rendered tiled interior surface")
	_expect(battle.slow_field_rect.stretch_mode == TextureRect.STRETCH_TILE, "slow field interior must tile at fixed density instead of stretching with range")
	_expect(battle.slow_field_rect.texture_repeat == CanvasItem.TEXTURE_REPEAT_ENABLED, "slow field interior texture repeat must be enabled")
	_expect(battle.slow_field_boundary != null and battle.slow_field_boundary.name == "SlowFieldZoneBoundary", "slow field must have an independent full-width non-radial threshold")
	_expect(battle.slow_field_boundary.texture.resource_path.ends_with("vfx_slow_field_boundary_v3.png"), "slow field threshold must use the rendered V3 non-radial asset")
	_expect(is_zero_approx(battle.slow_field_boundary.rotation), "slow field threshold must remain geometrically horizontal instead of rotating its full-width texture")
	var boundary_level_material := battle.slow_field_boundary.material as ShaderMaterial
	_expect(boundary_level_material != null, "slow field threshold must use the dedicated slope-leveling shader material")
	if boundary_level_material != null:
		_expect(boundary_level_material.shader.resource_path.ends_with("vfx_slow_field_boundary_level.gdshader"), "slow field threshold must use the dedicated non-destructive leveling shader")
		_expect(absf(float(boundary_level_material.get_shader_parameter("slope_compensation_px")) - 18.0) <= 0.001, "slow field threshold must counter the authored right-edge drop by the approved 18px ruler")
		_expect(absf(float(boundary_level_material.get_shader_parameter("gameplay_seam_y_px")) - battle.SLOW_FIELD_BOUNDARY_ANCHOR_Y) <= 0.001, "slow field threshold must draw its level seam on the exact gameplay slowdown boundary")
		_expect(absf(float(boundary_level_material.get_shader_parameter("gameplay_seam_opacity")) - 0.34) <= 0.001, "slow field threshold must keep the horizontal reference seam readable but subordinate to the ice crest")
	_expect(battle.slow_field_rect.texture.resource_path.ends_with("vfx_slow_field_surface_v3.png"), "slow field interior must use the rendered V3 quiet area tile")
	_expect(battle.slow_field_particles.name == "SlowFieldSnowCrystals", "slow field particles must read as authored snow crystals rather than generic glow dots")
	_expect(battle.slow_field_particles.texture.resource_path.ends_with("vfx_hit_ice.png"), "slow field snow must use the authored crystalline ice artwork")
	var fixed_boundary_size: Vector2 = battle.slow_field_boundary.size
	_expect(is_equal_approx(fixed_boundary_size.x, 1080.0), "slow field threshold must span the full battlefield width")
	for entry_var in row.get("levels", []):
		var entry: Dictionary = entry_var if entry_var is Dictionary else {}
		var lv := int(entry.get("lv", 0))
		if not expected_y_min.has(lv):
			continue
		var effect: Dictionary = entry.get("effect", {})
		var y_min := float(effect.get("y_min", -1.0))
		var expected := float(expected_y_min[lv])
		_expect(absf(y_min - expected) <= 0.001, "slow field Lv%d y_min must match 30/40/50/60/70 coverage contract at %.0f, got %.0f" % [lv, expected, y_min])
		var visual_offset := float(battle._slow_field_inner_offset_for_level(lv))
		_expect(absf(visual_offset - (1500.0 - expected)) <= 0.001, "slow field Lv%d visual offset must match data y_min; got %.0f expected %.0f" % [lv, visual_offset, 1500.0 - expected])
		var runtime := SkillRuntime.new()
		runtime.owned["skill_slow_field"] = lv
		var slow_pct := float(effect.get("slow", 0.0))
		_expect(absf(slow_pct - float(expected_slow[lv])) <= 0.001, "slow field Lv%d must use the approved %.0f%% slow, got %.0f%%" % [lv, float(expected_slow[lv]) * 100.0, slow_pct * 100.0])
		_expect(is_equal_approx(runtime.slow_mult_for_y(expected - 1.0), 1.0), "slow field Lv%d runtime must not slow before y_min %.0f" % [lv, expected])
		_expect(absf(runtime.slow_mult_for_y(expected + 1.0) - maxf(runtime.slow_speed_floor(false), 1.0 - slow_pct)) <= 0.001, "slow field Lv%d runtime must slow a mob after y_min %.0f" % [lv, expected])
		_expect(absf(runtime.slow_mult_for_y(expected + 1.0, SkillRuntime.SLOW_FIELD_DESIGN_BASE_LINE_Y, true) - maxf(runtime.slow_speed_floor(true), 1.0 - slow_pct)) <= 0.001, "slow field Lv%d runtime must apply the Boss-specific speed floor after y_min %.0f" % [lv, expected])
		battle._update_slow_field_visual(lv)
		_expect(battle.slow_field_particles.amount >= battle.SLOW_FIELD_SNOW_MIN_AMOUNT, "slow field Lv%d must keep a readable minimum snow density" % lv)
		_expect(battle.slow_field_boundary.size.is_equal_approx(fixed_boundary_size), "slow field Lv%d must move its full-width rendered threshold without stretching it" % lv)
		_expect(absf(battle.slow_field_boundary.position.y - (expected - battle.SLOW_FIELD_BOUNDARY_ANCHOR_Y)) <= 0.001, "slow field Lv%d rendered threshold must follow the same data-driven y_min" % lv)
		_expect(absf(battle.slow_field_rect.position.y - expected) <= 0.001, "slow field Lv%d area fill must begin at the real slowdown boundary" % lv)
		_expect(absf(battle.slow_field_rect.size.y - (1500.0 - expected)) <= 0.001, "slow field Lv%d area fill must cover the complete affected region" % lv)

	# Exercise the actual enemy movement path, not only the multiplier helper:
	# battle applies every level's data multiplier, then enemy.gd consumes
	# speed_mult in its per-tick position update. This catches any future
	# disconnect between data and motion.
	var enemy := _instance("res://gameplay/enemy/enemy.tscn")
	enemy.speed = 100.0
	enemy.attack_line_y = 1900.0
	enemy.position = Vector2(540.0, 1100.0)
	enemy.speed_mult = 1.0
	var baseline_y: float = enemy.position.y
	enemy._physics_process(1.0)
	var baseline_distance: float = enemy.position.y - baseline_y
	_expect(absf(baseline_distance - 100.0) <= 0.001, "enemy baseline movement must consume speed at 1.0x")
	for entry_var in row.get("levels", []):
		var entry: Dictionary = entry_var if entry_var is Dictionary else {}
		var lv := int(entry.get("lv", 0))
		if not expected_y_min.has(lv):
			continue
		var effect: Dictionary = entry.get("effect", {})
		var slow_pct := float(effect.get("slow", 0.0))
		var expected_mult := maxf(battle.skills.slow_speed_floor(false), 1.0 - slow_pct)
		enemy.position = Vector2(540.0, float(expected_y_min[lv]) + 1.0)
		enemy.speed_mult = 1.0
		battle.skills.owned["skill_slow_field"] = lv
		battle.slow_field_sfx_level = lv
		battle._apply_slow_field([enemy])
		var applied_mult: float = enemy.speed_mult
		var slowed_y: float = enemy.position.y
		enemy._physics_process(1.0)
		var slowed_distance: float = enemy.position.y - slowed_y
		_expect(absf(applied_mult - expected_mult) <= 0.001, "slow field Lv%d must apply its data-driven %.2f movement multiplier to an in-range enemy" % [lv, expected_mult])
		_expect(absf(slowed_distance - baseline_distance * applied_mult) <= 0.001, "enemy.gd must consume the Lv%d slow multiplier in its real movement update" % lv)
	enemy.position = Vector2(540.0, 1049.0)
	enemy.speed_mult = 1.0
	battle.skills.owned["skill_slow_field"] = 1
	battle.slow_field_sfx_level = 1
	battle._apply_slow_field([enemy])
	_expect(is_equal_approx(enemy.speed_mult, 1.0), "slow field must not slow a zombie one pixel before its data-driven boundary")
	enemy.free()
	battle.free()

func _verify_ammo_element_rules(save_manager: Node) -> void:
	var data_loader := root.get_node("DataLoader")
	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var test_save: Dictionary = original_save.duplicate(true)
	test_save["skill_base_levels"] = {}
	save_manager.save_data = test_save
	var runtime := SkillRuntime.new()
	_expect(runtime.add_skill("skill_tesla"), "tesla ammo must be addable")
	_expect(runtime.projectile_element("physical") == "lightning", "physical weapons can be converted to tesla ammo")
	_expect(runtime.projectile_element("fire") == "fire", "native elemental weapons must keep their weapon element")
	_expect(runtime.add_skill("skill_venom"), "venom ammo must be addable")
	_expect(runtime.level("skill_tesla") == 0, "tesla and venom ammo must be mutually exclusive")
	_expect(runtime.level("skill_venom") == 1, "new ammo module must replace the previous ammo module")
	_expect(runtime.projectile_element("physical") == "poison", "active ammo module must drive physical weapon projectile element")
	_expect(runtime.projectile_element("fire") == "fire", "plasma/fire weapons must not be overwritten by venom or tesla ammo")

	var equipment: Dictionary = test_save.get("equipment", {}).duplicate(true)
	equipment["selected_weapon"] = "weapon_plasmacannon"
	test_save["equipment"] = equipment
	save_manager.save_data = test_save
	var director := CardDirector.new()
	var plasma_offers := director.offer({"card_bias": {}, "threat_tags": []}, {"skill_incendiary": 1}, 16)
	_expect(plasma_offers.has("skill_incendiary"), "plasma cannon may upgrade its matching fire ammo module")
	_expect(not plasma_offers.has("skill_tesla"), "plasma cannon must not offer tesla ammo")
	_expect(not plasma_offers.has("skill_venom"), "plasma cannon must not offer venom ammo")
	_expect(not plasma_offers.has("skill_cryo"), "plasma cannon must not offer cryo ammo")

	equipment["selected_weapon"] = "weapon_autocannon"
	equipment["selected_character"] = "vanguard"
	test_save["equipment"] = equipment
	save_manager.save_data = test_save
	var pre_floor_sequences := {
		1103: [
			["skill_ricochet", "skill_charge_shot", "skill_barrier"],
			["skill_tesla", "skill_barrier", "skill_charge_shot"],
			["skill_pierce", "skill_homing", "skill_multishot"],
			["skill_salvo", "skill_charge_shot", "skill_multishot"],
		],
		2207: [
			["skill_split_shot", "skill_pierce", "skill_barrier"],
			["skill_critical", "skill_barrier", "skill_charge_shot"],
			["skill_barrier", "skill_pierce", "skill_recycle"],
			["skill_pierce", "skill_charge_shot", "skill_split_shot"],
		],
		3301: [
			["skill_critical", "skill_ricochet", "skill_homing"],
			["skill_homing", "skill_slow_field", "skill_barrier"],
			["skill_venom", "skill_barrier", "skill_salvo"],
			["skill_charge_shot", "skill_pierce", "skill_gold_rush"],
		],
	}
	var level_050: Dictionary = data_loader.get_row("levels", "level_050")
	_expect(str(level_050.get("offer_category_floor", "")) == "compatible_crowd", "level 050 must preserve its accepted clear-pool floor")
	var non_floor_level: Dictionary = level_050.duplicate(true)
	non_floor_level.erase("offer_category_floor")
	for audit_seed_var in pre_floor_sequences.keys():
		var audit_seed := int(audit_seed_var)
		var sequence_director := CardDirector.new()
		sequence_director.set_audit_seed(audit_seed)
		var actual_sequence: Array = []
		var sequence_owned: Dictionary = {}
		for _offer_index in range(4):
			var sequence_offer := sequence_director.offer(non_floor_level, sequence_owned, 3)
			actual_sequence.append(sequence_offer.duplicate())
			if not sequence_offer.is_empty():
				var selected_id := str(sequence_offer[0])
				sequence_owned[selected_id] = int(sequence_owned.get(selected_id, 0)) + 1
		_expect(
			actual_sequence == pre_floor_sequences[audit_seed_var],
			"non-enabled card offers must stay byte-for-byte equivalent for audit seed %d" % audit_seed,
		)
	var floor_policy: Dictionary = data_loader.get_table("economy").get("probe_card_policy", {})
	var synthetic_floor_level := non_floor_level.duplicate(true)
	synthetic_floor_level["offer_category_floor"] = "crowd"
	for audit_seed in [1103, 2207, 3301]:
		var floor_director := CardDirector.new()
		floor_director.set_audit_seed(audit_seed)
		var floor_owned: Dictionary = {}
		for _offer_index in range(4):
			var floor_offer := floor_director.offer(synthetic_floor_level, floor_owned, 3)
			var has_crowd := false
			for skill_id in floor_offer:
				var tags: Array = data_loader.get_row("skills", skill_id).get("card_tags", [])
				has_crowd = has_crowd or floor_director._has_policy_category(tags, "crowd", floor_policy)
			_expect(has_crowd, "category-floor offers must contain an eligible crowd card")
			if not floor_offer.is_empty():
				var selected_id := str(floor_offer[0])
				floor_owned[selected_id] = int(floor_owned.get(selected_id, 0)) + 1
	var opening_director := CardDirector.new()
	var opening_level: Dictionary = data_loader.get_row("levels", "level_001")
	var opening_offer := opening_director.offer(opening_level, {}, 3)
	_expect(opening_offer.size() == 3, "opening card offer must keep three distinct choices")
	var opening_has_damage := false
	var opening_has_safety := false
	var opening_has_core := false
	for skill_id in opening_offer:
		var opening_row: Dictionary = data_loader.get_row("skills", skill_id)
		var opening_tags: Array = opening_row.get("card_tags", [])
		_expect(not opening_tags.has("economy"), "opening card offer must not spend a slot on an economy card")
		opening_has_damage = opening_has_damage or opening_tags.has("anti_swarm") or opening_tags.has("projectile") or opening_tags.has("dps")
		opening_has_safety = opening_has_safety or opening_tags.has("control") or opening_tags.has("defense")
		opening_has_core = opening_has_core or opening_director._matches_selected_loadout(opening_row)
	_expect(opening_has_damage, "first card offer must include an immediate damage identity choice")
	_expect(opening_has_safety, "first card offer must include a control or defense stabilizer")
	_expect(opening_has_core, "first card offer must include a selected-loadout affinity choice")
	var second_offer := opening_director.offer(opening_level, {}, 3)
	var second_has_core := false
	for skill_id in second_offer:
		var second_row: Dictionary = data_loader.get_row("skills", skill_id)
		_expect(not second_row.get("card_tags", []).has("economy"), "second card offer must not spend a slot on an economy card")
		second_has_core = second_has_core or opening_director._matches_selected_loadout(second_row)
	_expect(second_has_core, "second card offer must reinforce the selected-loadout identity")
	var finale_director := CardDirector.new()
	var finale_level: Dictionary = data_loader.get_row("levels", "level_099")
	var finale_offer := finale_director.offer(finale_level, {}, 3)
	_expect(
		finale_offer.has("skill_barrier") or finale_offer.has("skill_slow_field"),
		"level_099 category floor must preserve its authored Barrier or Slow Field guarantee",
	)
	var finale_policy: Dictionary = data_loader.get_table("economy").get("probe_card_policy", {})
	var finale_has_single_target := false
	for skill_id in finale_offer:
		finale_has_single_target = finale_has_single_target or finale_director._has_policy_category(
			data_loader.get_row("skills", skill_id).get("card_tags", []),
			"single_target",
			finale_policy,
		)
	_expect(finale_has_single_target, "level_099 first offer must also satisfy its single-target category floor")
	var physical_offers := director.offer({"card_bias": {}, "threat_tags": []}, {"skill_tesla": 1}, 16)
	_expect(physical_offers.has("skill_tesla"), "physical weapon should continue upgrading the chosen ammo module")
	_expect(not physical_offers.has("skill_venom"), "physical weapon must not offer a second ammo module after tesla is chosen")
	_expect(not physical_offers.has("skill_incendiary"), "physical weapon must not offer fire ammo after tesla is chosen")
	_expect(not physical_offers.has("skill_cryo"), "physical weapon must not offer cryo ammo after tesla is chosen")
	save_manager.save_data = original_save

func _verify_feedback_budget_guards() -> void:
	var damage_layer := preload("res://gameplay/hud/damage_number_layer.gd").new()
	root.add_child(damage_layer)
	for i in range(90):
		damage_layer.spawn_damage(Vector2(320 + float(i % 6), 620), 8.0 + float(i), "physical", false, false)
	_expect(damage_layer.get_child_count() <= 58, "damage number layer must cap dense non-critical hit labels")
	if damage_layer.get_child_count() > 0:
		var first_damage := damage_layer.get_child(0) as Label
		_expect(first_damage.get_theme_font_size("font_size") <= 30, "normal damage numbers must stay compact red hit text")
	damage_layer.spawn_damage(Vector2(540, 620), 999.0, "fire", true, true)
	_expect(damage_layer.get_child_count() <= 58, "damage number layer must keep cap after important damage")
	damage_layer.reset()
	await process_frame
	damage_layer.free()

	var fake_battle := Node2D.new()
	root.add_child(fake_battle)
	var gold_label := Label.new()
	gold_label.name = "SmokeGoldLabel"
	var gold_icon := TextureRect.new()
	fake_battle.add_child(gold_label)
	fake_battle.add_child(gold_icon)
	var gold_fx := preload("res://gameplay/hud/gold_fly.gd").new()
	root.add_child(gold_fx)
	gold_fx.bind(fake_battle, gold_label, gold_icon)
	for i in range(24):
		gold_fx.fly_to_hud(Vector2(120 + i, 800), 10)
	_expect(fake_battle.get_child_count() <= 12, "gold reward flash must cap active coin/ring nodes")
	gold_fx.free()
	fake_battle.free()

	var offscreen := preload("res://gameplay/hud/off_screen_indicator.gd").new()
	root.add_child(offscreen)
	await process_frame
	var left_enemy := FakeAimTarget.new()
	var right_enemy := FakeAimTarget.new()
	left_enemy.add_to_group("enemies")
	right_enemy.add_to_group("enemies")
	left_enemy.global_position = Vector2(-320, 480)
	right_enemy.global_position = Vector2(1380, 520)
	root.add_child(left_enemy)
	root.add_child(right_enemy)
	var viewport := Rect2(Vector2(100, 100), Vector2(880, 1200))
	offscreen.refresh(viewport, Vector2.ZERO)
	var arrows_after_first := offscreen.get_child_count()
	offscreen.refresh(viewport, Vector2.ZERO)
	_expect(offscreen.get_child_count() == arrows_after_first, "off-screen indicators must reuse arrow nodes across refreshes")
	left_enemy.queue_free()
	right_enemy.queue_free()
	offscreen.queue_free()
	await process_frame

func _verify_late_wave_count_multipliers(data_loader: Node, save_manager: Node) -> void:
	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var level_row: Dictionary = data_loader.get_row("levels", "level_001")
	var waves: Array = level_row.get("waves", [])
	_expect(waves.size() >= 5, "level_001 must have at least five authored waves")
	var router := FakeRouter.new()
	root.add_child(router)
	for payload in [
		{"level_id": "level_001"},
		{"level_id": "level_001", "challenge": true},
		{"level_id": "level_001", "endless": true},
	]:
		var battle := _instance("res://gameplay/battle/battle.tscn")
		battle.setup(router, payload)
		root.add_child(battle)
		await process_frame
		await physics_frame
		var mode_waves: Array = battle.level.get("waves", [])
		_expect(mode_waves.size() >= 5, "payload %s must resolve to at least five authored waves" % str(payload))
		var wave4: Dictionary = mode_waves[3]
		var wave5: Dictionary = mode_waves[4]
		var wave4_base := _wave_mob_count(wave4)
		var wave5_base := _wave_mob_count(wave5)
		_expect(wave4_base > 0 and wave5_base > 0, "payload %s must have wave 4/5 mob counts" % str(payload))
		battle.pending_spawns.clear()
		battle.active_spawning = false
		battle.wave_index = 3
		battle._start_next_wave()
		_expect(battle.pending_spawns.size() == wave4_base * 2, "wave 4 mob queue must be 2x in payload %s; got %d expected %d" % [str(payload), battle.pending_spawns.size(), wave4_base * 2])
		battle.pending_spawns.clear()
		battle.active_spawning = false
		battle.wave_index = 4
		battle._start_next_wave()
		var expected_wave5 := wave5_base * 3
		if bool(payload.get("endless", false)):
			expected_wave5 += int(battle._endless_boss_count())
		elif wave5.has("boss"):
			expected_wave5 += 1
		_expect(battle.pending_spawns.size() == expected_wave5, "wave 5 mob queue must be 3x in payload %s; got %d expected %d" % [str(payload), battle.pending_spawns.size(), expected_wave5])
		battle.queue_free()
		await process_frame
	router.queue_free()
	save_manager.save_data = original_save
	await process_frame

func _verify_endgame_pressure_ramp(data_loader: Node, save_manager: Node) -> void:
	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var test_save: Dictionary = _battle_smoke_loadout(original_save)
	var equipment: Dictionary = test_save.get("equipment", {}).duplicate(true)
	equipment["selected_character"] = "vanguard"
	equipment["selected_weapon"] = "weapon_autocannon"
	test_save["equipment"] = equipment
	save_manager.save_data = test_save

	var router := FakeRouter.new()
	root.add_child(router)
	var battle := _instance("res://gameplay/battle/battle.tscn")
	battle.setup(router, {"level_id": "level_099"})
	root.add_child(battle)
	await process_frame
	await physics_frame
	battle.pending_spawns.clear()
	battle.active_spawning = false
	var economy: Dictionary = data_loader.get_table("economy")
	battle.level_ordinal = 98
	var pre_final_hp_ramp := float(battle._late_wave_level_ramp_mult(economy))
	_expect(absf(pre_final_hp_ramp - 2.05) <= 0.001, "level_098 late-wave HP ramp must already reach 2.05x, got %.3f" % pre_final_hp_ramp)
	battle.wave_index = 3
	var pre_final_damage_ramp := float(battle._late_wave_damage_ramp_mult(economy))
	_expect(absf(pre_final_damage_ramp - 1.0) <= 0.001, "late-game base damage must remain at authored 1.0x, got %.3f" % pre_final_damage_ramp)
	_expect(absf(float(battle._late_wave_count_level_ramp_mult(3, economy)) - 1.25) <= 0.001, "level_098 wave-3 count ramp must reach 1.25x")
	battle.level_ordinal = 99
	var hp_ramp := float(battle._late_wave_level_ramp_mult(economy))
	_expect(absf(hp_ramp - 2.296) <= 0.001, "level_099 late-wave HP ramp must reach 2.296x, got %.3f" % hp_ramp)
	var damage_ramp := float(battle._late_wave_damage_ramp_mult(economy))
	_expect(absf(damage_ramp - 1.0) <= 0.001, "level_099 base damage must remain at authored 1.0x, got %.3f" % damage_ramp)
	_expect(absf(float(battle._late_wave_count_level_ramp_mult(3, economy)) - 1.35) <= 0.001, "level_099 wave-3 count ramp must reach 1.35x")
	_expect(battle._scaled_wave_group_count(100, 3) == 135, "level_099 wave-3 mob count must apply the 1.35x crowd ramp")
	_expect(battle._scaled_wave_group_count(100, 5) == 405, "level_099 wave-5 mob count must combine the 3.0x wave and 1.35x crowd ramps")

	var zombie_id := "zombie_berserker"
	var zombie_row: Dictionary = data_loader.get_row("zombies", zombie_id)
	var authored_level: Dictionary = battle.level
	var neutral_level: Dictionary = authored_level.duplicate(true)
	(neutral_level.get("waves", [])[2] as Dictionary).erase("hp_coef")
	battle.level = neutral_level
	_expect(absf(float(battle._wave_hp_coef(3)) - 1.0) <= 0.000001, "waves without hp_coef must remain exactly neutral")
	battle.level = authored_level
	var expected_ch6_xp_budgets := {
		"level_051": 948, "level_052": 1767, "level_053": 1336, "level_054": 1671,
		"level_055": 1798, "level_056": 1549, "level_057": 1530, "level_058": 1623,
		"level_059": 1855, "level_060": 1989,
	}
	for xp_level_id in expected_ch6_xp_budgets:
		var xp_level_row: Dictionary = data_loader.get_row("levels", xp_level_id)
		_expect(int(xp_level_row.get("run_xp_budget", 0)) == int(expected_ch6_xp_budgets[xp_level_id]), "%s must preserve its topology-neutral authored-wave XP budget" % xp_level_id)
	var b2a_xp_budget_total := 0
	for b2a_level_number in range(61, 100):
		var b2a_level_id := "level_%03d" % b2a_level_number
		var b2a_level_row: Dictionary = data_loader.get_row("levels", b2a_level_id)
		_expect(b2a_level_row.has("run_xp_budget"), "%s must preserve its topology-neutral authored-wave XP budget" % b2a_level_id)
		b2a_xp_budget_total += int(b2a_level_row.get("run_xp_budget", 0))
	_expect(b2a_xp_budget_total == 95741, "B2a levels must preserve the B2b-merged authored-wave XP total; got %d" % b2a_xp_budget_total)
	_expect(not data_loader.get_row("levels", "level_050").has("run_xp_budget"), "non-pilot levels must keep legacy per-enemy XP behavior")
	var saved_raw_xp_total: int = int(battle.level_raw_run_xp_total)
	var saved_xp_budget: int = int(battle.level_run_xp_budget)
	var saved_raw_xp_earned: float = float(battle.level_run_xp_raw_earned)
	var saved_xp_budget_awarded: int = int(battle.level_run_xp_budget_awarded)
	var saved_variant_xp_mult: float = float(battle.variant_xp_mult)
	battle.level_raw_run_xp_total = 40
	battle.level_run_xp_budget = 100
	battle.level_run_xp_raw_earned = 0.0
	battle.level_run_xp_budget_awarded = 0
	battle.variant_xp_mult = 1.0
	_expect(battle._normalized_run_xp_reward(10.0, true) == 25, "authored-wave XP must preserve its proportional card timing under topology normalization")
	_expect(battle._normalized_run_xp_reward(30.0, true) == 75, "authored-wave XP normalization must land exactly on the level budget")
	_expect(battle._normalized_run_xp_reward(10.0, false) == 10, "runtime extra enemies must remain outside the authored-wave XP budget")
	battle.level_raw_run_xp_total = saved_raw_xp_total
	battle.level_run_xp_budget = saved_xp_budget
	battle.level_run_xp_raw_earned = saved_raw_xp_earned
	battle.level_run_xp_budget_awarded = saved_xp_budget_awarded
	battle.variant_xp_mult = saved_variant_xp_mult
	var enemy: Node = battle._spawn_enemy_instance(zombie_id, Vector2(540, 190), false)
	var level_row: Dictionary = data_loader.get_row("levels", "level_099")
	var level_coef := float(level_row.get("difficulty_coef", 1.0)) * float(level_row.get("base_hp_ref", 50)) / 50.0
	var expected_hp := 50.0 * float(zombie_row.get("hp_coef", 1.0)) * level_coef * float(battle._wave_hp_coef(3)) * float(battle._late_wave_hp_bonus(3, false, economy))
	var expected_breach := int(10.0 * float(zombie_row.get("bd_coef", 1.0)) * damage_ramp)
	_expect(absf(float(enemy.max_hp) - expected_hp) <= maxf(1.0, expected_hp * 0.001), "level_099 wave-3 enemy must receive the full authored HP ramp")
	_expect(int(enemy.breach_damage) == expected_breach, "level_099 wave-3 enemy must keep authored base damage; got %d expected %d" % [int(enemy.breach_damage), expected_breach])
	enemy.queue_free()
	var synthetic_level: Dictionary = authored_level.duplicate(true)
	(synthetic_level.get("waves", [])[2] as Dictionary)["hp_coef"] = float(battle._wave_hp_coef(3)) * 0.5
	battle.level = synthetic_level
	var reduced_enemy: Node = battle._spawn_enemy_instance(zombie_id, Vector2(540, 190), false)
	_expect(absf(float(reduced_enemy.max_hp) - expected_hp * 0.5) <= maxf(1.0, expected_hp * 0.001), "explicit wave hp_coef must multiply only the existing mob durability chain")
	reduced_enemy.queue_free()
	battle.level = authored_level

	battle.wave_index = 2
	_expect(absf(float(battle._late_wave_damage_ramp_mult(economy)) - 1.0) <= 0.001, "waves 1-2 must stay outside the late-game damage ramp")
	var apex: Dictionary = data_loader.get_row("bosses", "boss_apex_overlord")
	battle.wave_index = 5
	var expected_apex_hp := float(apex.get("fixed_hp", 0.0))
	_expect(not level_row.has("boss_stack_hp_multipliers"), "campaign levels must not hide per-copy Boss durability overrides")
	battle.boss_spawn_counts.clear()
	for copy_index in range(4):
		var apex_enemy: Node = battle._spawn_enemy_instance("boss_apex_overlord", Vector2(540, 190), true)
		var apex_total_durability := float(apex_enemy.max_hp) + float(apex_enemy.armor_hp_max)
		_expect(absf(apex_total_durability - expected_apex_hp) <= maxf(1.0, expected_apex_hp * 0.001), "level_099 Apex copy %d must keep the model's full fixed durability" % [copy_index + 1])
		_expect(int(apex_enemy.breach_damage) == int(10.0 * float(apex.get("bd_coef", 1.0))), "Apex attack must not inherit any late-game damage multiplier")
		apex_enemy.queue_free()
	var finale_level: Dictionary = battle.level
	battle.level = {"id": "level_085"}
	battle.boss_spawn_counts.clear()
	_expect(absf(float(battle._next_same_type_boss_hp_multiplier("boss_necromancer_titan", economy)) - 1.0) <= 0.001, "campaign Bosses must keep full durability on the first copy")
	_expect(absf(float(battle._next_same_type_boss_hp_multiplier("boss_necromancer_titan", economy)) - 1.0) <= 0.001, "campaign Bosses must keep full durability on repeated copies")
	battle.level = finale_level
	var apex_resistances: Dictionary = apex.get("resistances", {})
	_expect(apex_resistances.size() == 4, "final boss must express its four non-physical counters as bounded resistances")
	for apex_element in ["fire", "ice", "lightning", "poison"]:
		_expect(absf(float(apex_resistances.get(apex_element, 0.0)) - 0.5) <= 0.001, "final boss %s resistance must reduce damage by 50 percent" % apex_element)
	_expect(int(save_manager.get_recommended_power_for_level("level_099")) >= 390, "level_099 recommended power must reflect graduation pressure")

	battle.queue_free()
	router.queue_free()
	save_manager.save_data = original_save
	await process_frame

func _wave_mob_count(wave: Dictionary) -> int:
	var total := 0
	for group in wave.get("spawns", []) + wave.get("support", []):
		# Runtime treats an authored zero-count group as one before applying the
		# late-wave multiplier; mirror that exact queue contract here.
		total += maxi(1, int(group.get("count", 1)))
	return total

func _verify_multi_shot_targeting(battle: Node) -> void:
	var origin := Vector2(540, 1500)
	var fake_targets: Array[Node] = []
	for position in [Vector2(410, 940), Vector2(540, 880), Vector2(670, 940)]:
		var target := FakeAimTarget.new()
		target.global_position = position
		target.breach_damage = 80
		target.elite = true
		battle.get_node("EnemyLayer").add_child(target)
		fake_targets.append(target)
	battle.target_manager.clear_lock()
	var automatic_target: Node2D = battle.target_manager.choose_target(fake_targets, origin)
	_expect(automatic_target != null, "automatic targeting must select a live zombie before multi-shot fires")
	var automatic_direction: Vector2 = (automatic_target.global_position - origin).normalized()
	for lane_count in range(2, battle.MAX_MULTISHOT_LANES + 1):
		var automatic_fan: Array[Vector2] = battle._primary_shot_directions(origin, automatic_direction, lane_count, deg_to_rad(18.0))
		var automatic_lane_hits_target := false
		for lane_direction in automatic_fan:
			if absf(lane_direction.angle_to(automatic_direction)) <= 0.001:
				automatic_lane_hits_target = true
				break
		_expect(automatic_lane_hits_target, "automatic %d-lane fire must put at least one real trajectory through the selected zombie" % lane_count)
		for lane_index in range(1, automatic_fan.size()):
			var previous_gap := absf(automatic_fan[lane_index - 1].angle_to(automatic_fan[lane_index]))
			_expect(previous_gap >= deg_to_rad(battle.MULTISHOT_LANE_DEG) - 0.001, "automatic target correction must preserve fixed multi-shot lane spacing")
	var directions: Array[Vector2] = battle._primary_shot_directions(origin, Vector2.UP, 3, deg_to_rad(18.0))
	_expect(directions.size() == 3, "multi-shot must return one direction per projectile")
	for direction in directions:
		_expect(direction.y < -0.45, "multi-shot lanes must point into the battlefield")
	# 固定夹角扇形：相邻弹道之间夹角相等且>0（对称扇形，不各自锁敌 → 不 imba）
	var ang_a := absf(directions[0].angle_to(directions[1]))
	var ang_b := absf(directions[1].angle_to(directions[2]))
	_expect(ang_a > 0.02 and ang_b > 0.02, "multi-shot must spread into a fan (distinct lanes)")
	_expect(absf(ang_a - ang_b) < 0.03, "multi-shot fan must use a FIXED equal angle between adjacent lanes")
	var automatic_homing_targets: Array[Node2D] = battle._homing_target_assignments(origin, directions, 3)
	_expect(automatic_homing_targets.size() == directions.size(), "scatter homing must assign one preferred target per projectile")
	var automatic_target_ids := {}
	for homing_target in automatic_homing_targets:
		if is_instance_valid(homing_target):
			automatic_target_ids[homing_target.get_instance_id()] = true
	_expect(automatic_target_ids.size() == 3, "homing Lv3 must distribute a scatter fan across three distinct live targets")
	var locked_target := fake_targets[0] as Node2D
	battle.target_manager.lock_enemy(locked_target)
	var locked_direction := (locked_target.global_position - origin).normalized()
	var locked_fan: Array[Vector2] = battle._primary_shot_directions(origin, locked_direction, 2, deg_to_rad(7.0))
	var locked_lane_hits_target := false
	for direction in locked_fan:
		if absf(direction.angle_to(locked_direction)) <= 0.001:
			locked_lane_hits_target = true
			break
	_expect(locked_lane_hits_target, "two-lane multi-shot must keep one projectile exactly on the player-locked enemy")
	_expect(absf(battle._multishot_center_direction(origin, Vector2.UP).angle_to(locked_direction)) <= 0.001, "player lock must override enemy-centroid multi-shot aiming")
	var locked_homing_targets: Array[Node2D] = battle._homing_target_assignments(origin, directions, 3, locked_target)
	_expect(locked_homing_targets.size() == directions.size(), "locked scatter homing must keep one assignment per projectile")
	for homing_target in locked_homing_targets:
		_expect(homing_target == locked_target, "player lock must focus every homing pellet on the locked enemy")
	battle.target_manager.clear_lock()
	_expect(absf(float(battle._multishot_damage_multiplier(1)) - 1.0) <= 0.001, "single projectile must keep full damage")
	_expect(absf(float(battle._multishot_damage_multiplier(2)) - 0.85) <= 0.001, "2 projectile lanes must use 15% falloff")
	_expect(absf(float(battle._multishot_damage_multiplier(3)) - 0.80) <= 0.001, "3 projectile lanes must use 20% falloff")
	_expect(absf(float(battle._multishot_damage_multiplier(4)) - 0.75) <= 0.001, "4 projectile lanes must use 25% falloff")
	_expect(absf(float(battle._multishot_damage_multiplier(5)) - 0.70) <= 0.001, "5 projectile lanes must use 30% falloff")
	_expect(absf(float(battle._multishot_damage_multiplier(6)) - 0.70) <= 0.001, "projectile lanes above 5 must clamp at 30% falloff")
	_expect(absf(float(battle._multishot_damage_multiplier(4, 0.08)) - 0.83) <= 0.001, "multishot Lv4 must compensate four-lane damage to 83% per projectile")
	_expect(absf(float(battle._multishot_damage_multiplier(5, 0.02)) - 0.72) <= 0.001, "multishot Lv5 must retain bounded compensation at 72% per projectile")
	for target in fake_targets:
		battle.get_node("EnemyLayer").remove_child(target)
		target.free()

func _verify_combat_information_density(battle: Node) -> void:
	var fake_targets: Array[Node] = []
	for index in range(18):
		var target := FakeAimTarget.new()
		target.global_position = Vector2(120.0 + float(index % 6) * 160.0, 260.0 + float(index / 6) * 320.0)
		target.breach_damage = 10 + index
		target.elite = index == 2
		target.boss = index == 3
		if target.elite:
			target.global_position.y = 1080.0
			target.breach_damage = 200
		battle.get_node("EnemyLayer").add_child(target)
		fake_targets.append(target)
	var locked := fake_targets[17] as Node2D
	battle.target_manager.lock_enemy(locked)
	battle._update_combat_information_density(0.0, true)
	var visible_count := 0
	for target in fake_targets:
		if bool(target.threat_label_visible):
			visible_count += 1
	_expect(visible_count <= battle.COMBAT_LABEL_HIGH_CAP, "high-density waves must cap semantic enemy labels, got %d" % visible_count)
	_expect(bool(locked.get("threat_label_visible")), "the player-locked enemy label must remain visible in a high-density wave")
	_expect(bool(fake_targets[2].get("threat_label_visible")), "the highest-pressure elite label must remain visible in a high-density wave")
	_expect(bool(fake_targets[3].get("threat_label_visible")), "boss labels must remain visible in a high-density wave")
	battle.target_manager.clear_lock()
	for target in fake_targets:
		battle.get_node("EnemyLayer").remove_child(target)
		target.free()

func _verify_base_attack_runtime(battle: Node) -> void:
	var enemies: Node = battle.get_node("EnemyLayer")
	if enemies.get_child_count() <= 0:
		return
	var enemy: Node = enemies.get_child(0)
	battle.breach_shields = 0
	battle.skill_barriers_left = 0
	battle.breach_damage_mult = 1.0
	battle.base_hp = battle.base_hp_max
	enemy.hp = 999999.0
	enemy.max_hp = 999999.0
	enemy.global_position = Vector2(540, float(enemy.get("attack_line_y")) + 8.0)
	var hp_before := int(battle.base_hp)
	for i in range(45):
		await physics_frame
		if int(battle.base_hp) < hp_before:
			break
	_expect(is_instance_valid(enemy), "enemy must remain targetable while attacking the base")
	_expect(bool(enemy.get("attacking_base")), "enemy must enter persistent base attack state instead of disappearing")
	_expect(int(battle.base_hp) < hp_before, "base attack state must tick damage over time")

func _verify_boss_base_attack_profiles(data_loader: Node) -> void:
	var expected := {
		"boss_tank_titan": {"mode": "melee_heavy", "hits": 1},
		"boss_inferno_maw": {"mode": "ranged_volley", "hits": 3},
		"boss_frost_warden": {"mode": "ranged_volley", "hits": 2},
		"boss_storm_caller": {"mode": "channel", "hits": 5},
		"boss_plague_mother": {"mode": "ranged_volley", "hits": 4},
		"boss_void_phantom": {"mode": "dash_combo", "hits": 3},
		"boss_necrotitan": {"mode": "melee_heavy", "hits": 1},
		"boss_apex_overlord": {"mode": "ranged_volley", "hits": 4},
	}
	var enemy_scene := load("res://gameplay/enemy/enemy.tscn") as PackedScene
	for boss_id in expected.keys():
		var row: Dictionary = data_loader.get_row("bosses", boss_id)
		var enemy: Node = enemy_scene.instantiate()
		root.add_child(enemy)
		enemy.setup(row, 1.0, true)
		enemy.configure_attack_line(1500.0)
		var profile: Dictionary = enemy.get("base_attack_profile")
		var contract: Dictionary = expected[boss_id]
		_expect(not profile.is_empty(), "%s must expose a data-driven base attack profile" % boss_id)
		_expect(str(profile.get("mode", "")) == str(contract["mode"]), "%s base attack mode must remain distinct" % boss_id)
		_expect(int(profile.get("hits", 0)) == int(contract["hits"]), "%s base attack hit cadence must remain authored" % boss_id)
		var ranged := str(profile.get("mode", "")) == "ranged_volley" or str(profile.get("mode", "")) == "channel"
		if ranged:
			_expect(float(enemy.get("attack_line_y")) <= 1280.0, "%s must stop at a readable ranged attack line" % boss_id)
		else:
			_expect(float(enemy.get("attack_line_y")) >= 1240.0, "%s must retain a near-base melee/dash line" % boss_id)
		var events := {"started": 0, "visual_hits": 0, "breaches": 0, "damage": 0}
		enemy.base_attack_started.connect(func(_source: Node, _profile: Dictionary) -> void:
			events["started"] = int(events["started"]) + 1
		)
		enemy.base_attack_visual_hit.connect(func(_source: Node, _profile: Dictionary, _hit_index: int, _hit_count: int) -> void:
			events["visual_hits"] = int(events["visual_hits"]) + 1
		)
		enemy.breached.connect(func(_source: Node, damage: int) -> void:
			events["breaches"] = int(events["breaches"]) + 1
			events["damage"] = int(events["damage"]) + damage
		)
		enemy.call("_enter_base_attack")
		enemy.set("base_attack_timer", 0.0)
		enemy.call("_process_base_attack", 0.01)
		for _step in range(40):
			if int(events["breaches"]) > 0:
				break
			enemy.call("_process_base_attack", 0.12)
		_expect(int(events["started"]) == 1, "%s must telegraph one attack cycle" % boss_id)
		_expect(int(events["visual_hits"]) == int(contract["hits"]), "%s must emit every authored visual hit" % boss_id)
		_expect(int(events["breaches"]) == 1, "%s multi-hit presentation must settle base damage exactly once" % boss_id)
		_expect(int(events["damage"]) == int(enemy.get("base_attack_damage")), "%s presentation must preserve authored total damage" % boss_id)
		enemy.free()

func _verify_barrier_visual_runtime(battle: Node) -> void:
	var owned_before: Dictionary = battle.skills.owned.duplicate(true)
	var breach_shields_before := int(battle.breach_shields)
	var skill_barriers_before := int(battle.skill_barriers_left)
	battle.breach_shields = 0
	battle.skill_barriers_left = 0
	battle.skills.owned.erase("skill_barrier")
	battle._update_barrier_visual()
	_expect(not battle.barrier_visual.visible, "barrier visual must stay hidden before the defense skill is learned")
	battle.breach_shields = 2
	battle._update_barrier_visual()
	_expect(
		not battle.barrier_visual.visible,
		"armor breach interception must not impersonate an unlearned defense skill at stage start"
	)
	battle.skills.owned["skill_barrier"] = 1
	battle._update_barrier_visual()
	_expect(battle.barrier_visual.visible, "barrier visual must remain visible after barrier becomes a base-HP skill")
	_expect(
		battle.character_rig != null and battle.character_rig.z_index > battle.barrier_visual.z_index,
		"character must render above barrier glass"
	)
	if battle.pet_sprite != null:
		_expect(
			battle.pet_sprite.z_index > battle.barrier_visual.z_index,
			"pet must render above barrier glass"
		)
	battle.skills.owned = owned_before
	battle.breach_shields = breach_shields_before
	battle.skill_barriers_left = skill_barriers_before
	battle._update_barrier_visual()

## Owner pain point: on high-output runs, a multi-Boss wave's next authored
## Boss (levels.json `runtime_bosses[].spawn_delay`, up to 65s) still waits
## out its full authored delay after the previous Boss dies, leaving the
## player with nothing to shoot. `wave_clear_fast_forward` (data/economy.json)
## lets that wait fast-forward once the field has been clear for
## `breather_seconds`, but only ever *earlier* than the authored schedule.
## This guards: (1) the switch ships disabled with a positive breather, (2) a
## disabled switch leaves `_process_spawns`'s consumed delayed-Boss wait
## decrementing byte-identically even with a recorded clear timestamp sitting
## on it, (3) the same setup with the switch enabled does fast-forward, (4)
## an occupied field (no clear recorded) leaves the enabled switch's path
## untouched too ("only advance, never delay" for a slow/never-clearing
## build), and (5) a live enemy spawning invalidates a stale clear timestamp.
func _verify_wave_clear_fast_forward(data_loader: Node, save_manager: Node) -> void:
	var economy: Dictionary = data_loader.get_table("economy")
	_expect(economy.has("wave_clear_fast_forward"), "economy.json must define wave_clear_fast_forward")
	var wcff_cfg: Dictionary = economy.get("wave_clear_fast_forward", {})
	_expect(wcff_cfg.has("enabled") and bool(wcff_cfg["enabled"]) == false, "wave_clear_fast_forward must ship disabled by default")
	_expect(wcff_cfg.has("breather_seconds") and float(wcff_cfg["breather_seconds"]) > 0.0, "wave_clear_fast_forward must author a positive breather_seconds")

	var router := FakeRouter.new()
	root.add_child(router)
	var battle := _instance("res://gameplay/battle/battle.tscn")
	var level_row: Dictionary = data_loader.get_row("levels", "level_090")
	_expect(level_row.get("runtime_bosses", []).size() == 1 and float((level_row.get("runtime_bosses", [])[0] as Dictionary).get("spawn_delay", 0.0)) > 0.0, "level_090 must still author a delayed second Boss for this probe")
	battle.setup(router, {"level_id": "level_090"})
	root.add_child(battle)
	await process_frame
	await physics_frame
	_expect(battle.wave_clear_fast_forward_enabled == false, "a freshly loaded battle must resolve the shipped disabled default from economy.json")
	_expect(absf(battle.wave_clear_fast_forward_breather - float(wcff_cfg["breather_seconds"])) <= 0.001, "a freshly loaded battle must resolve the authored breather_seconds")

	for existing in (battle.get_node("EnemyLayer") as Node).get_children():
		existing.queue_free()
	battle.active_spawning = true

	# (2) Closed switch: a recorded clear timestamp on a consumed delayed-Boss
	# wait must not change spawn_timer's ordinary decrement at all.
	var delayed_item := {"type": "boss_apex_overlord", "interval": 2.4, "lane": "left", "boss": true, "_spawn_delay_consumed": true}
	battle.pending_spawns = [delayed_item.duplicate()]
	battle.spawn_timer = 10.0
	battle.wave_clear_fast_forward_enabled = false
	battle._wave_clear_fast_forward_clear_at = battle._gameplay_now_seconds()
	battle._process_spawns(0.5)
	_expect(absf(battle.spawn_timer - 9.5) <= 0.0001, "a disabled switch must leave a consumed delayed Boss wait decrementing by exactly delta")
	_expect(bool((battle.pending_spawns[0] as Dictionary).get("boss", false)), "a disabled switch must not spawn or otherwise touch the queued delayed Boss")

	# (3) Enabled switch, field cleared just now with a 1s breather: the wait
	# must fast-forward from its authored ~10s remainder down toward
	# breather_seconds instead of running out the full delay (while a tiny
	# delta keeps this frame from also reaching the clamped target and
	# spawning early, isolating the clamp from the pop-and-spawn step it
	# feeds into).
	battle.pending_spawns = [delayed_item.duplicate()]
	battle.spawn_timer = 10.0
	battle.wave_clear_fast_forward_enabled = true
	battle.wave_clear_fast_forward_breather = 1.0
	battle._wave_clear_fast_forward_clear_at = battle._gameplay_now_seconds()
	battle._process_spawns(0.01)
	_expect(battle.pending_spawns.size() == 1, "a fast-forwarded wait must not itself trigger the spawn ahead of its clamped remaining time")
	_expect(battle.spawn_timer > 0.0 and battle.spawn_timer <= 1.001, "a cleared field must fast-forward a consumed delayed Boss wait down to (approximately) breather_seconds instead of its authored ~10s, got %.3f" % battle.spawn_timer)
	# Once that clamped wait elapses, the delayed Boss must actually spawn —
	# proving the fast-forward closes the loop, not just shrinks a number.
	battle._process_spawns(battle.spawn_timer + 0.001)
	_expect(battle.pending_spawns.is_empty(), "once its fast-forwarded wait elapses, the delayed Boss must actually spawn")
	for spawned in (battle.get_node("EnemyLayer") as Node).get_children():
		spawned.queue_free()

	# (4) Enabled switch, field never recorded clear (still occupied /
	# "slow build"): the authored wait must proceed exactly as if the switch
	# were off — only advance, never delay.
	battle.pending_spawns = [delayed_item.duplicate()]
	battle.spawn_timer = 10.0
	battle.wave_clear_fast_forward_enabled = true
	battle.wave_clear_fast_forward_breather = 3.0
	battle._wave_clear_fast_forward_clear_at = -1.0
	battle._process_spawns(0.5)
	_expect(absf(battle.spawn_timer - 9.5) <= 0.0001, "an occupied field (no recorded clear) must leave a consumed delayed Boss wait untouched even with the switch enabled")

	# (5) A live enemy joining the field must invalidate a stale clear
	# timestamp, and `_has_live_enemies` must reflect the field honestly.
	battle.wave_clear_fast_forward_enabled = true
	battle._wave_clear_fast_forward_clear_at = 123.0
	_expect(not battle._has_live_enemies(), "the probe's cleared EnemyLayer must report no live enemies before spawning")
	var probe_enemy: Node = battle._spawn_enemy_instance("zombie_shambler", Vector2(540, 190), false)
	_expect(battle._wave_clear_fast_forward_clear_at < 0.0, "a freshly spawned live enemy must invalidate any previously recorded clear timestamp")
	_expect(battle._has_live_enemies(), "a freshly spawned enemy must count as a live enemy")
	probe_enemy.queue_free()

	battle.queue_free()
	router.queue_free()
	await process_frame

func _verify_projectile_pierce_runtime() -> void:
	var projectile := _instance("res://gameplay/projectile/projectile.tscn")
	root.add_child(projectile)
	projectile.setup(Vector2(100, 100), Vector2.RIGHT, 1000.0, 10.0, "physical", 1, 0)
	var first := FakeDamageTarget.new()
	var second := FakeDamageTarget.new()
	first.global_position = Vector2(120, 100)
	second.global_position = Vector2(260, 100)
	root.add_child(first)
	root.add_child(second)
	projectile._hit(first)
	projectile._hit(first)
	_expect(first.hits == 1, "piercing projectile must not repeatedly hit the same target")
	_expect(projectile.pierce_left == 0, "piercing projectile must spend one pierce after first target")
	_expect(not projectile.is_queued_for_deletion(), "piercing projectile must keep flying after first target")
	projectile._hit(second)
	_expect(second.hits == 1, "piercing projectile must hit a second target")
	_expect(projectile.is_queued_for_deletion(), "piercing projectile must expire after pierce charges are spent")
	first.queue_free()
	second.queue_free()
	projectile.queue_free()

func _verify_projectile_pierce_sweep_runtime() -> void:
	var projectile := _instance("res://gameplay/projectile/projectile.tscn")
	root.add_child(projectile)
	projectile.setup(Vector2(100, 100), Vector2.RIGHT, 1000.0, 10.0, "physical", 1, 0)
	var first := FakeDamageTarget.new()
	var second := FakeDamageTarget.new()
	var off_lane := FakeDamageTarget.new()
	first.global_position = Vector2(120, 100)
	second.global_position = Vector2(285, 124)
	off_lane.global_position = Vector2(285, 260)
	second.add_to_group("enemies")
	off_lane.add_to_group("enemies")
	root.add_child(first)
	root.add_child(second)
	root.add_child(off_lane)
	projectile._hit(first)
	_expect(first.hits == 1, "pierce sweep must keep primary hit")
	_expect(second.hits == 1, "pierce sweep must immediately damage a backline target")
	_expect(off_lane.hits == 0, "pierce sweep must stay in the projectile lane")
	_expect(projectile.is_queued_for_deletion(), "pierce sweep must expire after spending its only pierce")
	first.queue_free()
	second.queue_free()
	off_lane.queue_free()
	projectile.queue_free()

func _verify_homing_pierce_frontline_cleanup() -> void:
	var no_target_projectile := _instance("res://gameplay/projectile/projectile.tscn")
	root.add_child(no_target_projectile)
	no_target_projectile.setup(Vector2(540, 1460), Vector2.UP, 1000.0, 10.0, "fire", 2, 0, 0.55, 5.0)
	# Keep the regression isolated from any combat fixture that may still own an
	# enemy-group node elsewhere in the smoke tree.
	for enemy in get_nodes_in_group("enemies"):
		no_target_projectile.hit_target_ids[enemy.get_instance_id()] = true
	var frontline_target := FakeDamageTarget.new()
	frontline_target.global_position = Vector2(540, 1380)
	root.add_child(frontline_target)
	no_target_projectile._hit(frontline_target)
	_expect(frontline_target.hits == 1, "frontline homing projectile must still damage its confirmed target")
	_expect(
		no_target_projectile.is_queued_for_deletion(),
		"homing pierce must dissipate after a frontline hit when no onward enemy exists"
	)
	frontline_target.queue_free()
	no_target_projectile.queue_free()

	var chained_projectile := _instance("res://gameplay/projectile/projectile.tscn")
	root.add_child(chained_projectile)
	chained_projectile.setup(Vector2(540, 1460), Vector2.UP, 1000.0, 10.0, "fire", 2, 0, 0.55, 5.0)
	for enemy in get_nodes_in_group("enemies"):
		chained_projectile.hit_target_ids[enemy.get_instance_id()] = true
	var first_target := FakeDamageTarget.new()
	var onward_target := FakeDamageTarget.new()
	first_target.global_position = Vector2(540, 1380)
	onward_target.global_position = Vector2(540, 880)
	onward_target.add_to_group("enemies")
	root.add_child(first_target)
	root.add_child(onward_target)
	chained_projectile._hit(first_target)
	_expect(first_target.hits == 1, "homing pierce chain must keep its primary hit")
	_expect(
		not chained_projectile.is_queued_for_deletion(),
		"homing pierce must remain active when a real onward enemy can consume the remaining pierce"
	)
	_expect(
		chained_projectile.velocity.normalized().dot(Vector2.UP) > 0.99,
		"homing pierce must leave the frontline aimed at the real onward target instead of fanning away"
	)
	first_target.queue_free()
	onward_target.remove_from_group("enemies")
	onward_target.queue_free()
	chained_projectile.queue_free()

func _verify_projectile_visual_profiles() -> void:
	var expected := {
		"autocannon": {"element": "physical", "texture": "proj_bullet_physical.png"},
		"rail": {"element": "physical", "texture": "proj_rail_slug.png"},
		"scatter": {"element": "physical", "texture": "proj_scatter_pellet.png"},
		"plasma": {"element": "fire", "texture": "proj_plasma_orb.png"},
	}
	for profile in expected.keys():
		var projectile := _instance("res://gameplay/projectile/projectile.tscn")
		root.add_child(projectile)
		var row: Dictionary = expected[profile]
		projectile.setup(Vector2(100, 100), Vector2.RIGHT, 1000.0, 10.0, str(row.get("element", "physical")), 0, 0, 0.55, 0.0, 0.0, 0.0, 1.0, 0, "", profile)
		var sprite := projectile.get_node("Sprite") as Sprite2D
		_expect(str(projectile.visual_profile) == profile, "projectile must retain visual profile %s" % profile)
		_expect(sprite.texture != null and str(sprite.texture.resource_path).ends_with(str(row.get("texture", ""))), "profile %s must use distinct projectile texture, got %s" % [profile, str(sprite.texture.resource_path)])
		_expect(sprite.modulate == Color.WHITE, "projectile model texture must keep original asset colors instead of flat tinting")
		if profile == "autocannon":
			_expect(projectile._uses_compact_ballistic_impact(), "starter autocannon must use the compact non-radial impact tier")
		elif profile == "rail":
			_expect(sprite.scale.x > sprite.scale.y * 2.2, "rail projectile must read as a long lance")
		elif profile == "scatter":
			_expect(sprite.scale.x < 0.32 and sprite.scale.y < 0.32, "scatter pellets must stay small")
		elif profile == "plasma":
			_expect(sprite.scale.x >= 0.36 and sprite.modulate.r > 0.8 and sprite.modulate.b > 0.8, "plasma projectile must read as a large purple energy core")
		projectile.queue_free()

	var battle = load("res://gameplay/battle/battle.gd").new()
	_expect(
		battle._resolved_weapon_projectile_visual_profile("physical", "physical", "rail") == "rail",
		"unmodified physical ammo must retain its authored weapon profile"
	)
	_expect(
		battle._resolved_weapon_projectile_visual_profile("fire", "fire", "plasma") == "plasma",
		"native elemental weapons must retain their authored projectile profile"
	)
	_expect(
		battle._resolved_weapon_projectile_visual_profile("physical", "lightning", "apocalypse_golden_law") == "apocalypse_golden_law",
		"premium physical weapon presentation must not be replaced by shared elemental ammo art"
	)
	var converted_expected := {
		"fire": "proj_bullet_fire.png",
		"ice": "proj_bullet_ice.png",
		"lightning": "proj_bullet_lightning.png",
		"poison": "proj_bullet_poison.png",
	}
	var source_profiles := ["autocannon", "rail", "scatter", "autocannon"]
	var converted_index := 0
	for converted_element in converted_expected.keys():
		var source_profile: String = source_profiles[converted_index]
		converted_index += 1
		var converted_profile: String = battle._resolved_weapon_projectile_visual_profile("physical", converted_element, source_profile)
		_expect(converted_profile == "ammo_%s" % converted_element, "physical %s rounds must switch to the %s ammo presentation" % [source_profile, converted_element])
		_expect(battle._muzzle_weapon_profile(converted_profile) == converted_profile, "converted %s ammo must bypass the original physical muzzle profile" % converted_element)
		var converted_projectile := _instance("res://gameplay/projectile/projectile.tscn")
		root.add_child(converted_projectile)
		converted_projectile.setup(Vector2(100, 100), Vector2.RIGHT, 1000.0, 10.0, converted_element, 0, 0, 0.55, 0.0, 0.0, 0.0, 1.0, 0, "", converted_profile)
		var converted_sprite := converted_projectile.get_node("Sprite") as Sprite2D
		_expect(str(converted_projectile.visual_profile) == converted_profile, "converted %s ammo must retain its presentation profile" % converted_element)
		_expect(
			converted_sprite.texture != null and str(converted_sprite.texture.resource_path).ends_with(str(converted_expected[converted_element])),
			"converted %s ammo must use its element model, got %s" % [converted_element, str(converted_sprite.texture.resource_path)]
		)
		_expect(not converted_projectile._uses_compact_ballistic_impact(), "converted %s ammo must use elemental rather than physical impact VFX" % converted_element)
		converted_projectile.queue_free()
	battle.free()

func _verify_starter_projectile_hierarchy(data_loader: Node) -> void:
	var starter_weapon: Dictionary = data_loader.get_row("weapons", "weapon_autocannon")
	var starter_special: Dictionary = starter_weapon.get("special", {})
	var vanguard: Dictionary = data_loader.get_row("characters", "vanguard")
	var affinity: Dictionary = vanguard.get("bullet_affinity", {})
	_expect(int(starter_special.get("split", 0)) == 0, "level-one autocannon must not start with split shot")
	_expect(int(starter_special.get("chain", 0)) == 0, "level-one autocannon must not start with ricochet")
	_expect(float(starter_special.get("splash", 0.0)) <= 0.0, "level-one autocannon must not start with splash damage")
	_expect(int(affinity.get("pierce_bonus", 0)) == 0, "level-one Vanguard bullets must remain single-target before growth rank II")
	_expect(int(affinity.get("rank_pierce_bonus", 0)) == 2, "Vanguard growth rank II must restore the original two-pierce endgame ceiling")
	var battle = load("res://gameplay/battle/battle.gd").new()
	battle.character_data = vanguard
	battle.character_level = 1
	_expect(int(battle._character_pierce_bonus("physical")) == 0, "runtime level-one Vanguard physical rounds must resolve zero pierce")
	_expect(float(battle._character_splash_bonus("physical")) <= 0.0, "runtime level-one Vanguard physical rounds must resolve zero splash")
	_expect(int(battle._resolved_chain_count("physical", {}, starter_special)) == 0, "runtime level-one Vanguard physical rounds must resolve zero chain")
	_expect(str(battle._weapon_visual_profile("weapon_autocannon")) == "autocannon", "starter weapon must route through the compact autocannon impact profile")
	battle.character_level = 15
	_expect(int(battle._character_pierce_bonus("physical")) == 2, "Vanguard growth rank II must unlock two straight-through pierces")
	battle.free()

func _verify_projectile_ballistics_rules() -> void:
	var projectile := _instance("res://gameplay/projectile/projectile.tscn")
	root.add_child(projectile)
	var target := FakeDamageTarget.new()
	target.global_position = Vector2(900, 1500)
	target.add_to_group("enemies")
	root.add_child(target)
	projectile.setup(Vector2(540, 1500), Vector2.UP, 1000.0, 10.0, "physical", 0, 0, 0.55, 5.0)
	var initial_dir: Vector2 = projectile.velocity.normalized()
	projectile._physics_process(0.5)
	_expect(projectile.velocity.normalized().dot(initial_dir) > 0.999, "homing projectile must fly straight for the first second after muzzle exit")
	var before_turn_dir: Vector2 = projectile.velocity.normalized()
	var speed: float = projectile.velocity.length()
	projectile._physics_process(0.6)
	var after_turn_dir: Vector2 = projectile.velocity.normalized()
	var turn_angle := absf(before_turn_dir.angle_to(after_turn_dir))
	var max_turn := float(projectile._homing_turn_rate_limit(speed)) * 0.6 + 0.015
	_expect(turn_angle > 0.05, "homing projectile must start steering after the one-second arming delay")
	_expect(turn_angle <= max_turn, "homing projectile turn must respect the minimum turn radius, got %.3f > %.3f" % [turn_angle, max_turn])

	var scatter_projectile := _instance("res://gameplay/projectile/projectile.tscn")
	root.add_child(scatter_projectile)
	scatter_projectile.setup(Vector2(540, 1500), Vector2.UP, 1000.0, 10.0, "physical", 0, 0, 0.55, 5.0, 0.0, 0.0, 1.0, 0, "", "scatter", 0.0, -1.0, target, 0.35)
	var scatter_initial_dir: Vector2 = scatter_projectile.velocity.normalized()
	scatter_projectile._physics_process(0.2)
	_expect(scatter_projectile.velocity.normalized().dot(scatter_initial_dir) > 0.999, "scatter homing must preserve the visible muzzle fan during its short arming delay")
	scatter_projectile._physics_process(0.20)
	_expect(scatter_projectile.velocity.normalized().dot(scatter_initial_dir) < 0.999, "scatter homing must begin steering after 0.35 seconds instead of waiting the full second")
	target.queue_free()
	projectile.queue_free()
	scatter_projectile.queue_free()

	var close_boss := FakeAimTarget.new()
	close_boss.boss = true
	close_boss.global_position = Vector2(900, 1500)
	close_boss.add_to_group("enemies")
	root.add_child(close_boss)
	var close_projectile := _instance("res://gameplay/projectile/projectile.tscn")
	root.add_child(close_projectile)
	close_projectile.setup(Vector2(540, 1500), Vector2.UP, 1000.0, 10.0, "physical", 0, 0, 0.55, 5.0)
	var close_initial_dir: Vector2 = close_projectile.velocity.normalized()
	close_projectile._physics_process(0.2)
	_expect(close_projectile.velocity.normalized().dot(close_initial_dir) < 0.999, "homing projectile must bypass muzzle-delay when a boss is already in close range")
	close_boss.queue_free()
	close_projectile.queue_free()

	var offscreen := _instance("res://gameplay/projectile/projectile.tscn")
	root.add_child(offscreen)
	offscreen.setup(Vector2(540, 10), Vector2.UP, 1000.0, 10.0, "physical")
	offscreen._physics_process(0.05)
	_expect(offscreen.is_queued_for_deletion(), "projectiles must be destroyed immediately after leaving the visible screen bounds")
	offscreen.queue_free()

	var expired := _instance("res://gameplay/projectile/projectile.tscn")
	root.add_child(expired)
	expired.setup(Vector2(540, 960), Vector2.UP, 1000.0, 10.0, "physical")
	expired._physics_process(5.0)
	_expect(expired.is_queued_for_deletion(), "projectiles must be force-cleared after five seconds in flight")
	expired.queue_free()

func _verify_turret_muzzle_sockets(data_loader: Node) -> void:
	var expected := {
		"weapon_autocannon": Vector2(34, -204),
		"weapon_cryocannon": Vector2(-160, -36),
		"weapon_flamethrower": Vector2(-154, -38),
		"weapon_plasmacannon": Vector2(-158, -44),
		"weapon_railgun": Vector2(-190, 54),
		"weapon_scattergun": Vector2(-145, -34),
		"weapon_teslacoil": Vector2(-28, -205),
		"weapon_venomlauncher": Vector2(-158, -48),
	}
	for weapon_id in expected.keys():
		var row: Dictionary = data_loader.get_row("weapons", weapon_id)
		_expect(not row.is_empty(), "weapon row must exist for muzzle socket: %s" % weapon_id)
		var turret := _instance("res://gameplay/turret/turret.tscn")
		root.add_child(turret)
		turret.setup(row, 18)
		var sprite := turret.get_node("Sprite") as Sprite2D
		var muzzle := turret.get_node("Muzzle") as Marker2D
		var expected_position: Vector2 = expected[weapon_id] * sprite.scale.x
		var economy: Dictionary = data_loader.get_table("economy")
		var expected_fire_rate := float(row.get("fire_rate", 4.0)) * (1.0 + 0.025 * 17.0) * float(economy.get("PLAYER_FIRE_RATE_MULT", 0.25))
		_expect(muzzle.position.distance_to(expected_position) <= 1.0, "turret muzzle must sit on %s barrel, got %s expected %s" % [weapon_id, str(muzzle.position), str(expected_position)])
		_expect(absf(turret.fire_rate - expected_fire_rate) <= 0.01, "turret fire rate must use economy pacing for %s, got %.3f expected %.3f" % [weapon_id, turret.fire_rate, expected_fire_rate])
		turret.aim_at(turret.global_position + expected_position.normalized() * 1000.0)
		await process_frame
		await physics_frame
		_expect(absf(turret.rotation) < 0.04, "turret rotation must align %s muzzle vector to target, got %.3f" % [weapon_id, turret.rotation])
		turret.queue_free()
		await process_frame

func _verify_character_weapon_skins(data_loader: Node, save_manager: Node) -> void:
	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var router := FakeRouter.new()
	root.add_child(router)
	var character_table: Dictionary = data_loader.get_table("characters")
	var weapon_table: Dictionary = data_loader.get_table("weapons")
	for character_id in character_table.keys():
		var character_key := str(character_id)
		var character_asset_id := _character_combo_asset_id(character_key)
		for weapon_id in weapon_table.keys():
			var weapon_key := str(weapon_id)
			var row: Dictionary = data_loader.get_row("weapons", weapon_key)
			var handheld_path := str(row.get("handheld", ""))
			_expect(handheld_path != "", "weapon must define handheld source skin: %s" % weapon_key)
			_expect(ResourceLoader.exists(handheld_path), "weapon handheld source skin must exist: %s" % handheld_path)
			var test_save: Dictionary = original_save.duplicate(true)
			var unlocks: Dictionary = test_save.get("unlocks", {}).duplicate(true)
			var characters: Array = unlocks.get("characters", []).duplicate()
			if not characters.has(character_key):
				characters.append(character_key)
			unlocks["characters"] = characters
			var weapons: Array = unlocks.get("weapons", []).duplicate()
			if not weapons.has(weapon_key):
				weapons.append(weapon_key)
			unlocks["weapons"] = weapons
			test_save["unlocks"] = unlocks
			var equipment: Dictionary = test_save.get("equipment", {}).duplicate(true)
			equipment["selected_character"] = character_key
			equipment[character_key] = maxi(1, int(equipment.get(character_key, 1)))
			equipment["selected_weapon"] = weapon_key
			equipment[weapon_key] = 18
			test_save["equipment"] = equipment
			save_manager.save_data = test_save
			var battle := _instance("res://gameplay/battle/battle.tscn")
			battle.setup(router, {"level_id": "level_001"})
			root.add_child(battle)
			await process_frame
			await physics_frame
			if weapon_key.begins_with("weapon_apocalypse_"):
				_expect(bool(battle.character_weapon_combo_active), "%s + %s must use the approved true-grip fused battle model" % [character_key, weapon_key])
				_expect(battle.character_weapon_sprite == null, "%s + %s must not mount a second floating cannon layer" % [character_key, weapon_key])
				var apocalypse_texture := (battle.character_sprite as Sprite2D).texture
				_expect(apocalypse_texture != null, "%s + %s true-grip battle texture must exist" % [character_key, weapon_key])
				var apocalypse_path := str(apocalypse_texture.resource_path)
				var true_grip: Dictionary = row.get("presentation", {}).get("true_grip", {})
				var true_grip_root := str(true_grip.get("root", ""))
				_expect(true_grip_root != "", "%s must declare its true-grip runtime root" % weapon_key)
				_expect(apocalypse_path.begins_with(true_grip_root + "/%s_apocalypse_" % character_asset_id), "%s + %s must load the premium true-grip runtime model; got %s" % [character_key, weapon_key, apocalypse_path])
				if weapon_key in ["weapon_apocalypse_inferno", "weapon_apocalypse_absolute_zero"]:
					_expect(str(true_grip.get("viewpoint", "")) == "rear", "%s battle models must explicitly preserve the rear-view battlefield camera" % weapon_key)
				_expect(battle.character_idle_frames.size() == 4, "%s + %s must provide four rig-driven idle beats" % [character_key, weapon_key])
				_expect(battle.character_attack_left_frames.size() == 8, "%s + %s must provide eight left-aim firing beats" % [character_key, weapon_key])
				_expect(battle.character_attack_frames.size() == 8, "%s + %s must provide eight center firing beats" % [character_key, weapon_key])
				_expect(battle.character_attack_right_frames.size() == 8, "%s + %s must provide eight right-aim firing beats" % [character_key, weapon_key])
				_expect(battle.character_hurt_frames.size() == 3, "%s + %s must provide three rig-driven hurt beats" % [character_key, weapon_key])
				for apocalypse_frame in [battle.character_attack_left_frames[0], battle.character_attack_frames[0], battle.character_attack_right_frames[0]]:
					_expect((apocalypse_frame as Texture2D).get_size() == Vector2(380, 520), "%s + %s true-grip direction masters must preserve the 380x520 battle contract" % [character_key, weapon_key])
				var apocalypse_reference_scale := float(battle._character_body_sprite_scale("center"))
				for body_pose in ["left", "center", "right"]:
					var body_metric: Dictionary = battle._character_body_metric(body_pose)
					var body_scale: float = battle._character_body_sprite_scale(body_pose)
					_expect(absf(body_scale - apocalypse_reference_scale) <= 0.0001, "%s + %s %s must share one true-grip model scale" % [character_key, weapon_key, body_pose])
					var body_anchor: Vector2 = battle._character_body_anchor_offset(body_pose, body_scale)
					var body_foot_local := body_anchor.y + (float(body_metric.get("foot_y_px", 260.0)) - 260.0) * body_scale
					_expect(absf(body_foot_local - battle._character_body_target_foot_offset()) <= 0.01, "%s + %s %s boots must share the global foot line" % [character_key, weapon_key, body_pose])
				battle._set_character_combo_aim_from_direction(Vector2.UP)
				var apocalypse_center_origin: Vector2 = battle.character_rig.to_global(battle._character_combo_muzzle_for_aim())
				battle._set_character_combo_aim_from_direction(Vector2(-0.62, -0.78))
				var apocalypse_left_origin: Vector2 = battle._weapon_fire_origin()
				battle._set_character_combo_aim_from_direction(Vector2(0.62, -0.78))
				var apocalypse_right_origin: Vector2 = battle._weapon_fire_origin()
				_expect(apocalypse_left_origin.x < apocalypse_center_origin.x - 45.0, "%s + %s left muzzle must follow the rendered cannon" % [character_key, weapon_key])
				_expect(apocalypse_right_origin.x > apocalypse_center_origin.x + 45.0, "%s + %s right muzzle must follow the rendered cannon" % [character_key, weapon_key])
				battle._set_character_combo_aim_from_direction(Vector2.UP)
				battle._play_character_attack()
				_expect(battle.character_anim_frame == 1, "%s + %s real fire must start on the authored ignition beat" % [character_key, weapon_key])
				_expect((battle.character_sprite as Sprite2D).texture == battle.character_attack_frames[1], "%s + %s ignition beat must keep the true-grip model visible" % [character_key, weapon_key])
			else:
				_expect(bool(battle.character_weapon_combo_active), "%s + %s must use fused character/weapon battle art" % [character_key, weapon_key])
				_expect(battle.character_weapon_sprite == null, "%s + %s must not also mount a floating gun sprite" % [character_key, weapon_key])
				var combo_texture := (battle.character_sprite as Sprite2D).texture
				_expect(combo_texture != null, "fused combo texture must exist for %s + %s" % [character_key, weapon_key])
				var combo_texture_path := str(combo_texture.resource_path)
				if combo_texture_path != "":
					_expect(combo_texture_path.contains("/character_weapon_combos/%s/" % character_asset_id), "fused combo texture must be loaded from %s; got %s" % [character_asset_id, combo_texture_path])
				_expect(battle.character_idle_frames.size() >= 4, "%s + %s must provide idle fused frames" % [character_key, weapon_key])
				_expect(battle.character_attack_left_frames.size() == 8, "%s + %s must provide the full 8-frame left-aim firing strip" % [character_key, weapon_key])
				_expect(battle.character_attack_frames.size() == 8, "%s + %s must provide the full 8-frame firing strip" % [character_key, weapon_key])
				_expect(battle.character_attack_right_frames.size() == 8, "%s + %s must provide the full 8-frame right-aim firing strip" % [character_key, weapon_key])
				_expect(battle.character_hurt_frames.size() >= 3, "%s + %s must provide hurt fused frames" % [character_key, weapon_key])
				var standard_reference_scale := float(battle._character_body_sprite_scale("center"))
				for body_pose in ["idle", "hurt", "left", "center", "right"]:
					var body_metric: Dictionary = battle._character_body_metric(body_pose)
					var body_scale: float = battle._character_body_sprite_scale(body_pose)
					_expect(absf(body_scale - standard_reference_scale) <= 0.0001, "%s + %s %s must share one static/firing model scale" % [character_key, weapon_key, body_pose])
					var body_anchor: Vector2 = battle._character_body_anchor_offset(body_pose, body_scale)
					var body_foot_local := body_anchor.y + (float(body_metric.get("foot_y_px", 260.0)) - 260.0) * body_scale
					_expect(absf(body_foot_local - battle._character_body_target_foot_offset()) <= 0.01, "%s + %s %s boots must stay on the shared foot line" % [character_key, weapon_key, body_pose])
				var expected_combo_origin: Vector2 = battle.character_rig.to_global(battle._character_combo_muzzle_for_aim())
				_expect(battle._weapon_fire_origin().distance_to(expected_combo_origin) <= 1.0, "%s + %s projectile origin must use fused muzzle" % [character_key, weapon_key])
				battle._set_character_combo_aim_from_direction(Vector2.UP)
				var expected_combo_center_origin: Vector2 = battle.character_rig.to_global(battle._character_combo_muzzle_for_aim())
				battle._set_character_combo_aim_from_direction(Vector2(-0.75, -0.66).normalized())
				var combo_left_origin: Vector2 = battle._weapon_fire_origin()
				battle._set_character_combo_aim_from_direction(Vector2(0.75, -0.66).normalized())
				var combo_right_origin: Vector2 = battle._weapon_fire_origin()
				_expect(combo_left_origin.x < expected_combo_center_origin.x - 20.0, "%s + %s left-aim muzzle must move left" % [character_key, weapon_key])
				_expect(combo_right_origin.x > expected_combo_center_origin.x + 20.0, "%s + %s right-aim muzzle must move right" % [character_key, weapon_key])
				battle._set_character_combo_aim_from_direction(Vector2.UP)
				battle._play_character_attack()
				_expect(battle.character_anim_frame == 1, "%s + %s real fire must bind to authored F2 ignition" % [character_key, weapon_key])
				_expect((battle.character_sprite as Sprite2D).texture == battle.character_attack_frames[1], "%s + %s ignition texture must be visible at real fire contact" % [character_key, weapon_key])
			_verify_point_blank_character_aim(battle, "%s + %s" % [character_key, weapon_key])
			battle.queue_free()
			await process_frame
	save_manager.save_data = original_save
	router.queue_free()
	await process_frame

func _verify_point_blank_character_aim(battle: Node, context: String) -> void:
	_expect(bool(battle.character_weapon_combo_active), "%s point-blank stability requires directional fused art" % context)
	battle.character_weapon_combo_locked_aim = ""
	battle._set_character_combo_aim_from_direction(Vector2.UP)
	var stable_reference: Vector2 = battle._character_pose_aim_reference_global()
	var close_wall_target := stable_reference + Vector2(-52.0, -180.0)
	var close_wall_aims: Array[String] = []
	for pose in ["left", "center", "right", "left", "right", "center"]:
		battle.character_weapon_combo_aim = pose
		battle.character_weapon_combo_locked_aim = ""
		_expect(battle._character_pose_aim_reference_global().distance_to(stable_reference) <= 0.5, "%s point-blank pose reference must not move with the current muzzle pose" % context)
		battle._set_character_combo_aim_from_target(close_wall_target)
		close_wall_aims.append(str(battle.character_weapon_combo_aim))
	_expect(close_wall_aims.all(func(aim: String) -> bool: return aim == "left"), "%s point-blank wall target must resolve to one stable aim instead of alternating left/right: %s" % [context, str(close_wall_aims)])
	battle.turret.target_point = close_wall_target
	var close_wall_direction: Vector2 = battle._weapon_fire_direction()
	var actual_muzzle: Vector2 = battle._weapon_fire_origin(false)
	_expect(absf(close_wall_direction.angle_to((close_wall_target - actual_muzzle).normalized())) <= 0.001, "%s stable character pose must still fire directly from the real muzzle to the wall target" % context)
	battle._set_character_combo_aim_from_direction(Vector2.UP)

func _verify_character_active_skill_controls(data_loader: Node, save_manager: Node) -> void:
	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var router := FakeRouter.new()
	root.add_child(router)
	var input_manager := root.get_node("/root/InputManager")
	var character_table: Dictionary = data_loader.get_table("characters")
	for character_id in character_table.keys():
		var character_key := str(character_id)
		var test_save: Dictionary = _battle_smoke_loadout(original_save)
		var initial_sig_levels: Dictionary = test_save.get("sig_skill_levels", {}).duplicate(true)
		initial_sig_levels[character_key] = 0
		test_save["sig_skill_levels"] = initial_sig_levels
		var unlocks: Dictionary = test_save.get("unlocks", {}).duplicate(true)
		var characters: Array = unlocks.get("characters", []).duplicate()
		if not characters.has(character_key):
			characters.append(character_key)
		unlocks["characters"] = characters
		test_save["unlocks"] = unlocks
		var equipment: Dictionary = test_save.get("equipment", {}).duplicate(true)
		equipment["selected_character"] = character_key
		equipment[character_key] = maxi(1, int(equipment.get(character_key, 1)))
		test_save["equipment"] = equipment
		save_manager.save_data = test_save
		var battle := _instance("res://gameplay/battle/battle.tscn")
		battle.setup(router, {"level_id": "level_001"})
		root.add_child(battle)
		await process_frame
		await physics_frame
		_expect(battle.get_node("Hud").process_mode == Node.PROCESS_MODE_ALWAYS, "battle HUD must receive active-skill clicks while combat is unpaused")
		var button := battle.get_node("Hud/CharacterSkillButton") as BaseButton
		_expect(button != null, "%s active skill button must be a BaseButton" % character_key)
		_expect(button is Button, "%s active skill button must be a real Button, not an empty TextureButton" % character_key)
		_expect(button.visible and not button.disabled, "%s active skill button must start visible and ready" % character_key)
		_expect(str(battle.character_active_id) != "", "%s must configure an active skill" % character_key)
		var active: Dictionary = battle.character_data.get("active_skill", {})
		var scaling_basis := str(active.get("scaling_basis", ""))
		_expect(["weapon", "character"].has(scaling_basis), "%s active skill must declare weapon or character scaling" % character_key)
		# Signature assertions below are deltas against these baselines, but the test
		# save inherits equipment levels from the ambient local save. Pin a neutral
		# character level so the deltas isolate signature contribution alone (frost's
		# authored sig slow 0.015x5=0.075 vs the 0.07 threshold leaves no room for the
		# high-level floor clamp; the volt branch re-pins 40 internally where it needs
		# rank scaling).
		var pinned_prior_character_level := int(battle.character_level)
		battle.character_level = 1
		var base_sig_power := float(battle._character_active_power_scale(active))
		var base_sig_cooldown := float(battle._active_skill_cooldown(active))
		var base_sig_duration := float(battle._active_skill_duration(active, float(active.get("duration", 0.0))))
		var base_vanguard_volleys := int(battle._vanguard_railvolley_count(active))
		var base_vanguard_targets := int(battle._vanguard_railvolley_target_count(active))
		var base_blaze_radius := float(battle._blaze_meltdown_radius(active))
		var base_blaze_pulses := int(battle._blaze_meltdown_pulse_count(active))
		var base_frost_waves := int(battle._frost_glacier_wave_count(active))
		var base_frost_speed := float(battle._frost_glacier_speed_factor(active, false))
		var base_volt_targets := int(battle._volt_storm_max_targets(active))
		var base_volt_strikes := int(battle._volt_storm_strike_count(active, base_volt_targets))
		var max_sig_levels: Dictionary = save_manager.save_data.get("sig_skill_levels", {}).duplicate(true)
		max_sig_levels[character_key] = save_manager.SIG_SKILL_MAX_LEVEL
		save_manager.save_data["sig_skill_levels"] = max_sig_levels
		_expect(float(battle._character_active_power_scale(active)) >= base_sig_power + 0.49, "%s max signature level must add about 50%% active damage" % character_key)
		_expect(float(battle._active_skill_cooldown(active)) <= base_sig_cooldown * 0.851, "%s max signature level must reduce cooldown by 15%%" % character_key)
		match character_key:
			"vanguard":
				_expect(float(battle._active_skill_duration(active, 6.0)) >= base_sig_duration + 1.7, "vanguard signature levels must extend barrage duration")
				_expect(int(battle._vanguard_railvolley_count(active)) >= base_vanguard_volleys + 2, "vanguard signature levels must add volleys")
				_expect(int(battle._vanguard_railvolley_target_count(active)) >= base_vanguard_targets + 2, "vanguard signature levels must add targets")
			"blaze":
				_expect(str(active.get("coverage_mode", "local")) == "local", "blaze meltdown must use a target-centred area instead of unconditional battlefield coverage")
				_expect(not battle._blaze_meltdown_uses_battlefield(active), "blaze meltdown runtime must not resolve as battlefield-wide")
				_expect(float(active.get("radius", 0.0)) >= 340.0, "blaze meltdown must keep a generous base blast area after removing full-screen coverage")
				# Signature growth is authored as +5% of the skill's base radius
				# per level. Compare that absolute authored contribution instead
				# of multiplying the already level/rank-boosted radius; the old
				# assertion became save-dependent when Blaze was already Lv40.
				var authored_blaze_radius := float(active.get("radius", 260.0))
				_expect(
					float(battle._blaze_meltdown_radius(active)) >= base_blaze_radius + authored_blaze_radius * 0.24,
					"blaze signature levels must expand blast radius",
				)
				_expect(int(battle._blaze_meltdown_pulse_count(active)) >= base_blaze_pulses + 2, "blaze signature levels must add pulse stages")
				_expect(float(battle._active_skill_status_scale(active)) >= 1.39, "blaze signature levels must strengthen burn status")
			"frost":
				_expect(float(battle._frost_glacier_duration(active)) >= base_sig_duration + 2.4, "frost signature levels must extend full-screen field duration")
				_expect(int(battle._frost_glacier_wave_count(active)) >= base_frost_waves + 2, "frost signature levels must add cold waves")
				_expect(float(battle._frost_glacier_speed_factor(active, false)) <= base_frost_speed - 0.07, "frost signature levels must strengthen slow")
			"volt":
				var original_volt_level := int(battle.character_level)
				var original_pet_chain := int(battle.chain_bonus)
				battle.character_level = 40
				battle.chain_bonus = 0
				var max_volt_targets := int(battle._volt_storm_max_targets(active))
				_expect(max_volt_targets >= 16, "max Volt storm must reach at least 16 authored targets without a code cap")
				_expect(int(battle._volt_storm_strike_count(active, max_volt_targets)) >= 26, "max Volt storm must deliver at least 26 authored strikes")
				var max_chain_count := int(battle._resolved_chain_count("lightning", {"chain": 9}, {"chain": 2}))
				_expect(max_chain_count == 13, "Volt chain resolver must retain all skill, weapon and affinity chains beyond the old five-target cap")
				_expect(float(battle._character_chain_overflow_damage_multiplier("lightning", max_chain_count)) >= 1.159, "excess Volt chains must convert into primary-target damage")
				battle.chain_bonus = 3
				_expect(int(battle._resolved_chain_count("lightning", {"chain": 9}, {"chain": 2})) == 16, "Volt pet chain bonuses must participate in the uncapped resolver")
				battle.chain_bonus = original_pet_chain
				battle.character_level = original_volt_level
		battle.character_level = pinned_prior_character_level
		var reset_sig_levels: Dictionary = save_manager.save_data.get("sig_skill_levels", {}).duplicate(true)
		reset_sig_levels[character_key] = 0
		save_manager.save_data["sig_skill_levels"] = reset_sig_levels
		var original_character_level := int(battle.character_level)
		var active_element := str(battle.character_data.get("element_focus", "physical"))
		var active_mult := float(active.get("damage_mult", 1.0))
		battle.character_level = 1
		var level_one_scale := float(battle._character_active_power_scale(active))
		battle.character_level = 25
		var level_twenty_five_scale := float(battle._character_active_power_scale(active))
		if scaling_basis == "weapon":
			_expect(level_twenty_five_scale > level_one_scale and level_twenty_five_scale <= 1.25, "%s weapon-linked active skill must grow mildly because main weapon already scales" % character_key)
			var weapon_scaled_damage := float(battle._character_active_damage(active_element, active_mult))
			var old_turret_mult := float(battle.turret.damage_mult)
			battle.turret.damage_mult = old_turret_mult * 2.0
			var boosted_weapon_scaled_damage := float(battle._character_active_damage(active_element, active_mult))
			_expect(boosted_weapon_scaled_damage > weapon_scaled_damage * 1.9, "%s weapon-linked active skill must follow main weapon attack" % character_key)
			battle.turret.damage_mult = old_turret_mult
		else:
			_expect(level_twenty_five_scale >= level_one_scale * 1.5, "%s character active skill must gain meaningful level scaling" % character_key)
			var weapon_level_inherit := float(active.get("weapon_level_inherit", 0.0))
			_expect(weapon_level_inherit > 0.0, "%s character active skill must inherit part of permanent weapon-level growth" % character_key)
			var selected_weapon := str(battle.weapon_id)
			var equipment_levels: Dictionary = save_manager.save_data.get("equipment", {}).duplicate(true)
			var original_weapon_level := int(equipment_levels.get(selected_weapon, 1))
			equipment_levels[selected_weapon] = 1
			save_manager.save_data["equipment"] = equipment_levels
			var level_one_weapon_active := float(battle._character_active_damage(active_element, active_mult))
			equipment_levels[selected_weapon] = 50
			save_manager.save_data["equipment"] = equipment_levels
			var max_weapon_active := float(battle._character_active_damage(active_element, active_mult))
			_expect(max_weapon_active >= level_one_weapon_active * 3.5, "%s active skill must retain meaningful damage at max weapon investment" % character_key)
			equipment_levels[selected_weapon] = original_weapon_level
			save_manager.save_data["equipment"] = equipment_levels
			var character_scaled_damage := float(battle._character_active_damage(active_element, active_mult))
			var old_turret_mult_character := float(battle.turret.damage_mult)
			battle.turret.damage_mult = old_turret_mult_character * 2.0
			var boosted_character_scaled_damage := float(battle._character_active_damage(active_element, active_mult))
			_expect(absf(boosted_character_scaled_damage - character_scaled_damage) <= maxf(character_scaled_damage * 0.01, 0.05), "%s character-scaling active skill must not double-dip main weapon level" % character_key)
			battle.turret.damage_mult = old_turret_mult_character
		battle.character_level = original_character_level
		if character_key == "vanguard":
			battle.sig_vanguard_barrage_timer = 1.0
			var primary_damage := float(battle._current_primary_shot_damage("physical"))
			var railvolley_damage := float(battle._vanguard_railvolley_damage(primary_damage))
			_expect(railvolley_damage * 0.82 >= primary_damage, "railvolley multi-target hit must scale from current primary shot damage; got %.1f vs primary %.1f" % [railvolley_damage * 0.82, primary_damage])
			battle.sig_vanguard_barrage_timer = 0.0
		if character_key == "blaze":
			var blaze_probes := [
				battle._spawn_enemy_instance("zombie_shambler", Vector2(540, 840), false),
				battle._spawn_enemy_instance("zombie_shambler", Vector2(700, 840), false),
				battle._spawn_enemy_instance("zombie_shambler", Vector2(110, 260), false),
			]
			var blaze_probe_hp: Array[float] = []
			for probe in blaze_probes:
				blaze_probe_hp.append(float(probe.hp))
			battle._blaze_meltdown_pulse(Vector2(540, 840), float(battle._blaze_meltdown_radius(active)), 1.0, 0, battle._blaze_meltdown_uses_battlefield(active))
			_expect(is_instance_valid(blaze_probes[0]) and float(blaze_probes[0].hp) < blaze_probe_hp[0], "blaze local pulse must damage its locked target")
			_expect(is_instance_valid(blaze_probes[1]) and float(blaze_probes[1].hp) < blaze_probe_hp[1], "blaze local pulse must retain useful crowd coverage around the locked target")
			_expect(is_instance_valid(blaze_probes[2]) and absf(float(blaze_probes[2].hp) - blaze_probe_hp[2]) <= 0.001, "blaze local pulse must not damage a remote enemy outside the blast area")
		var frost_probe = null
		var frost_probe_hp_before := 0.0
		if character_key == "frost":
			frost_probe = battle._spawn_enemy_instance("zombie_shambler", Vector2(540, 1120), false)
			frost_probe_hp_before = float(frost_probe.hp)

		battle.character_active_cd = 0.0
		battle._update_character_skill_button()
		input_manager.skill_pressed.emit(0)
		await process_frame
		_expect(float(battle.character_active_cd) > 0.0, "%s active skill must trigger from shortcut signal" % character_key)
		if character_key == "frost" and is_instance_valid(frost_probe):
			_expect(float(battle.sig_frost_glacier_timer) >= 4.8, "frost glacier must run for about five seconds")
			battle._process_frost_glacier(0.08)
			_expect(frost_probe.has_method("is_glacier_field_active") and frost_probe.is_glacier_field_active(), "frost glacier must visibly mark affected enemies")
			frost_probe.speed_mult = 1.0
			frost_probe.call("_process_element_status", 0.1)
			_expect(float(frost_probe.speed_mult) < 0.7, "frost glacier must slow affected enemies")
			battle._process_frost_glacier(0.56)
			_expect(float(frost_probe.hp) < frost_probe_hp_before, "frost glacier must deal periodic ice damage")

		battle.character_active_cd = 0.0
		battle._update_character_skill_button()
		var center := button.get_global_rect().get_center()
		var motion := InputEventMouseMotion.new()
		motion.position = center
		motion.global_position = center
		root.push_input(motion)
		await process_frame
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		press.position = center
		press.global_position = center
		root.push_input(press)
		await process_frame
		var release := InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		release.pressed = false
		release.position = center
		release.global_position = center
		root.push_input(release)
		await process_frame
		_expect(root.gui_get_hovered_control() == button, "%s active skill button must be the hovered control at its visual center" % character_key)
		_expect(float(battle.character_active_cd) > 0.0, "%s active skill must trigger from real mouse/touch click" % character_key)
		_expect(not button.disabled, "%s cooling active skill must remain tappable for its description" % character_key)
		var cast_count_after_ready_tap := int(battle.battle_active_skill_casts)
		var cooldown_after_ready_tap := float(battle.character_active_cd)
		battle._on_character_skill_pressed()
		await process_frame
		_expect(battle.has_node("Hud/SkillHintOverlay") and not battle.get_node("Hud/SkillHintOverlay").visible, "%s short tap during cooldown must not open a hold-only description" % character_key)
		_expect(int(battle.battle_active_skill_casts) == cast_count_after_ready_tap, "%s cooldown inspect tap must not cast again" % character_key)
		_expect(float(battle.character_active_cd) <= cooldown_after_ready_tap and float(battle.character_active_cd) > 0.0, "%s cooldown inspect tap must not reset the cooldown" % character_key)
		battle.character_active_cd = 0.0
		battle._update_character_skill_button()
		battle._hide_skill_hint()
		battle._begin_skill_hint_press("character", "")
		battle.skill_hint_press_started_at -= 0.5
		battle._process(0.0)
		_expect(battle.skill_hint_long_press_opened, "%s active-skill long press must cross the inspect threshold" % character_key)
		_expect(battle.get_node("Hud/SkillHintOverlay").visible, "%s active-skill long press must show its description" % character_key)
		battle._end_skill_hint_press()
		battle._on_character_skill_pressed()
		_expect(int(battle.battle_active_skill_casts) == cast_count_after_ready_tap, "%s active-skill long press release must never cast" % character_key)
		_expect(is_zero_approx(float(battle.character_active_cd)), "%s active-skill long press release must leave a ready skill ready" % character_key)
		_expect(battle.get_node("Hud/SkillHintOverlay").visible, "%s active-skill long-press description must remain readable after release" % character_key)
		battle.queue_free()
		await process_frame
	save_manager.save_data = original_save
	router.queue_free()
	await process_frame

func _battle_smoke_loadout(snapshot: Dictionary) -> Dictionary:
	var test_save: Dictionary = snapshot.duplicate(true)
	var unlocks: Dictionary = test_save.get("unlocks", {}).duplicate(true)
	for key in ["characters", "weapons", "armors", "chips"]:
		unlocks[key] = unlocks.get(key, []).duplicate()
	if not unlocks["characters"].has("vanguard"):
		unlocks["characters"].append("vanguard")
	if not unlocks["weapons"].has("weapon_autocannon"):
		unlocks["weapons"].append("weapon_autocannon")
	if not unlocks["armors"].has("armor_kevlar"):
		unlocks["armors"].append("armor_kevlar")
	if not unlocks["chips"].has("chip_attack"):
		unlocks["chips"].append("chip_attack")
	test_save["unlocks"] = unlocks
	var equipment: Dictionary = test_save.get("equipment", {}).duplicate(true)
	equipment["selected_character"] = "vanguard"
	equipment["selected_weapon"] = "weapon_autocannon"
	equipment["selected_armor"] = "armor_kevlar"
	equipment["selected_chip"] = "chip_attack"
	equipment["vanguard"] = maxi(1, int(equipment.get("vanguard", 1)))
	equipment["weapon_autocannon"] = maxi(1, int(equipment.get("weapon_autocannon", 1)))
	equipment["armor_kevlar"] = maxi(1, int(equipment.get("armor_kevlar", 1)))
	equipment["chip_attack"] = maxi(1, int(equipment.get("chip_attack", 1)))
	test_save["equipment"] = equipment
	return test_save

func _character_combo_asset_id(character_id: String) -> String:
	match character_id:
		"vanguard":
			return "char_vanguard"
		"blaze":
			return "char_blaze"
		"frost":
			return "char_frost"
		"volt":
			return "char_volt"
		_:
			return "char_%s" % character_id

func _verify_bottom_skill_slot_level_merge(save_manager: Node) -> void:
	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var router := FakeRouter.new()
	root.add_child(router)
	var test_save: Dictionary = original_save.duplicate(true)
	test_save["skill_base_levels"] = {}
	var unlocks: Dictionary = test_save.get("unlocks", {}).duplicate(true)
	var weapons: Array = unlocks.get("weapons", []).duplicate()
	if not weapons.has("weapon_teslacoil"):
		weapons.append("weapon_teslacoil")
	unlocks["weapons"] = weapons
	test_save["unlocks"] = unlocks
	var equipment: Dictionary = test_save.get("equipment", {}).duplicate(true)
	equipment["selected_weapon"] = "weapon_teslacoil"
	equipment["weapon_teslacoil"] = 18
	test_save["equipment"] = equipment
	save_manager.save_data = test_save
	var battle := _instance("res://gameplay/battle/battle.tscn")
	battle.setup(router, {"level_id": "level_001"})
	root.add_child(battle)
	await process_frame
	await physics_frame
	var slots := battle.get_node("Hud/SkillSlots")
	_expect(slots is GridContainer, "battle skill slots must use the lower-left wrapping dock")
	_expect(slots.get_child_count() == 1, "tesla weapon seed must create exactly one skill slot")
	_expect(slots.has_node("skill_tesla"), "tesla weapon seed must use the tesla skill slot")
	_expect(is_equal_approx(slots.anchor_left, 0.0) and is_equal_approx(slots.anchor_right, 0.0), "skill dock must be bounded to the left half instead of anchored across the viewport")
	_expect(absf(slots.offset_right - 426.0) <= 0.1 and absf(slots.size.x - 408.0) <= 0.1, "skill dock must reserve exactly four unchanged 96px cards plus three gaps")
	_expect(absf(slots.offset_bottom - 1808.0) <= 0.1, "single-row skill dock must bottom-align with the active skill")
	_expect(slots.size.y >= 120.0 and slots.size.y <= 132.0, "single-row skill dock must use the enlarged mobile-readable row; got %.1f" % slots.size.y)
	var slot := slots.get_node("skill_tesla")
	_expect(slot.has_node("HBox/LevelBadge"), "tesla slot must expose a level badge")
	_expect((slot.get_node("HBox/LevelBadge") as Label).text == "等级1", "tesla seed must start at level 1")
	_expect((slot as Control).custom_minimum_size == Vector2(96, 120), "HUD skill card must match the enlarged touch/readability target")
	_expect((slot.get_node("HBox/IconBox/Icon") as TextureRect).custom_minimum_size == Vector2(66, 66), "HUD skill icon must be large enough to identify on a phone")
	_expect((slot.get_node("HBox/LevelBadge") as Label).get_theme_font_size("font_size") >= 23, "HUD skill level must use the new mobile-readable size")
	battle._begin_skill_hint_press("skill", "skill_tesla")
	battle._end_skill_hint_press()
	_expect(battle.has_node("Hud/SkillHintOverlay") and not battle.get_node("Hud/SkillHintOverlay").visible, "single tapping an owned HUD skill must not open its hold-only detail hint")
	battle._begin_skill_hint_press("skill", "skill_tesla")
	battle.skill_hint_press_started_at -= 0.5
	battle._process(0.0)
	_expect(battle.get_node("Hud/SkillHintOverlay").visible, "long pressing an owned HUD skill must open its detail hint")
	battle._end_skill_hint_press()
	battle._hide_skill_hint()
	_expect(battle.skills.add_skill("skill_tesla"), "adding tesla once must upgrade the existing slot")
	battle._update_skill_slots()
	await process_frame
	_expect(slots.get_child_count() == 1, "upgrading tesla must not add a duplicate slot")
	_expect((slot.get_node("HBox/LevelBadge") as Label).text == "等级2", "upgrading tesla must display level 2 on the existing slot")
	for skill_id in ["skill_split_shot", "skill_pierce", "skill_multishot", "skill_slow_field", "skill_homing"]:
		_expect(battle.skills.add_skill(skill_id), "%s must be addable for HUD wrap regression" % skill_id)
	battle._update_skill_slots()
	await process_frame
	await process_frame
	_expect(slots.get_child_count() == 6, "six owned skills must produce six distinct HUD cards")
	_expect((slots as GridContainer).columns == 4, "skill dock must wrap after four cards")
	_expect(slots.size.y >= 248.0 and slots.size.y <= 264.0, "six skills must wrap to two enlarged rows; got %.1f" % slots.size.y)
	var first_card := slots.get_child(0) as Control
	var fourth_card := slots.get_child(3) as Control
	var fifth_card := slots.get_child(4) as Control
	var sixth_card := slots.get_child(5) as Control
	_expect(absf(fourth_card.position.y - first_card.position.y) <= 0.1, "the first four skills must remain on one row")
	_expect(fifth_card.position.y >= first_card.position.y + 120.0, "the fifth skill must start the second row without overlap")
	_expect(absf(fifth_card.position.x - first_card.position.x) <= 0.1, "wrapped skill rows must keep the same left alignment")
	_expect(absf(sixth_card.position.y - fifth_card.position.y) <= 0.1, "later skills must continue across the wrapped second row")
	_expect(fourth_card.position.x + fourth_card.size.x <= slots.size.x + 0.1, "the fourth skill must remain inside the narrowed dock instead of entering the hero lane")
	battle.queue_free()
	save_manager.save_data = original_save
	router.queue_free()
	await process_frame

func _verify_card_offer_permanent_level_preload(save_manager: Node) -> void:
	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var router := FakeRouter.new()
	root.add_child(router)
	var test_save: Dictionary = original_save.duplicate(true)
	test_save["skill_base_levels"] = {"skill_multishot": 4}
	var equipment: Dictionary = test_save.get("equipment", {}).duplicate(true)
	equipment["selected_character"] = "vanguard"
	equipment["selected_weapon"] = "weapon_autocannon"
	equipment["vanguard"] = maxi(1, int(equipment.get("vanguard", 1)))
	equipment["weapon_autocannon"] = maxi(1, int(equipment.get("weapon_autocannon", 1)))
	test_save["equipment"] = equipment
	save_manager.save_data = test_save
	var battle := _instance("res://gameplay/battle/battle.tscn")
	battle.setup(router, {"level_id": "level_001"})
	root.add_child(battle)
	await process_frame
	await physics_frame
	_expect(battle.skills.level("skill_multishot") == 0, "permanent skill levels must not auto-own every skill before it is picked")
	_expect(battle._skill_offer_level("skill_multishot") == 4, "an unowned level-4 permanent skill must preview its real level 4 on first pick")
	var row: Dictionary = root.get_node("/root/DataLoader").get_row("skills", "skill_multishot")
	var card: Panel = battle._build_skill_card("skill_multishot", row, "多重射击", battle._skill_offer_level("skill_multishot"))
	var badge := card.get_node("LevelBadge").get_child(0) as Label
	_expect(badge != null and badge.text == "等级 4", "the multishot card badge must display permanent level 4 before acquisition")
	_expect((card.get_node("Stats") as Label).text == SkillEffectText.format_offer_block(row, 4, 0), "the card's current-value block must use permanent level-4 effects")
	card.queue_free()
	_expect(battle.skills.add_skill("skill_multishot"), "level-4 permanent multishot must be acquirable")
	_expect(battle.skills.level("skill_multishot") == 4, "first acquisition must preload multishot directly at permanent level 4")
	var level4_mods: Dictionary = battle.skills.projectile_mods()
	_expect(int(level4_mods.get("extra_projectiles", 0)) == 3, "preloaded multishot must immediately apply its current level-4 projectile value")
	_expect(absf(float(level4_mods.get("multishot_lane_damage_bonus", 0.0)) - 0.08) <= 0.001, "preloaded multishot Lv4 must apply its lane damage compensation")
	battle._update_skill_slots()
	await process_frame
	var slot_badge := battle.get_node("Hud/SkillSlots/skill_multishot/HBox/LevelBadge") as Label
	_expect(slot_badge != null and slot_badge.text == "等级4", "battle HUD must show level 4 immediately after the first multishot pick")
	_expect(battle._skill_offer_level("skill_multishot") == 5, "a later multishot card must preview the next runtime level after the permanent baseline")
	_expect(battle.skills.add_skill("skill_multishot") and battle.skills.level("skill_multishot") == 5, "the second multishot pick must upgrade level 4 to level 5")
	var level5_mods: Dictionary = battle.skills.projectile_mods()
	_expect(int(level5_mods.get("extra_projectiles", 0)) == 4, "multishot Lv5 must increase from four total lanes to five")
	_expect(absf(float(level5_mods.get("multishot_lane_damage_bonus", 0.0)) - 0.02) <= 0.001, "multishot Lv5 must retain the bounded lane damage compensation")
	battle.queue_free()
	save_manager.save_data = original_save
	router.queue_free()
	await process_frame

func _verify_endless_mode(save_manager: Node) -> void:
	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var economy: Dictionary = save_manager.get_node("/root/DataLoader").get_table("economy")
	_expect(not economy.has("endless_loop_hp_growth"), "endless mode must not retain the retired single-growth source")
	var growth_stages_var = economy.get("endless_hp_growth_stages", [])
	var growth_stages: Array = growth_stages_var if growth_stages_var is Array else []
	_expect(growth_stages.size() == 3, "endless mob HP must use the three approved growth stages")
	_expect(int(economy.get("endless_boss_count_step", 0)) == 4, "endless Boss count step must come from economy and equal four loops")
	_expect(int(economy.get("endless_boss_count_cap", 0)) == 6, "endless Boss count cap must come from economy and remain six")
	_expect(absf(float(economy.get("endless_gold_loop_bonus", 0.0)) - 0.13) <= 0.0001, "endless kill gold must use the approved Tier B linear 13 percent loop bonus")
	var milestone_var = economy.get("endless_gold_milestone", {})
	var milestone: Dictionary = milestone_var if milestone_var is Dictionary else {}
	_expect(int(milestone.get("interval", 0)) == 5, "endless gold milestone must trigger every five completed loops")
	_expect(int(milestone.get("gold_per_milestone", 0)) == 30, "endless milestone base must preserve monotonic gold per minute under Tier B")
	var pacing_var = economy.get("endless_boss_pacing", {})
	var pacing: Dictionary = pacing_var if pacing_var is Dictionary else {}
	var budgets_var = pacing.get("budgets", [])
	var budgets: Array = budgets_var if budgets_var is Array else []
	_expect(int(pacing.get("max_loop", 0)) >= 20 and budgets.size() >= 20, "endless Boss budget table must cover at least twenty loops")
	var previous_budget := 0.0
	for display_loop in range(1, 21):
		var row_var = budgets[display_loop - 1] if display_loop - 1 < budgets.size() else {}
		var row: Dictionary = row_var if row_var is Dictionary else {}
		var total_hp := float(row.get("total_hp", 0.0))
		_expect(int(row.get("loop", 0)) == display_loop, "endless Boss budget rows must be contiguous at loop %d" % display_loop)
		_expect(total_hp >= previous_budget and total_hp > 0.0, "endless Boss budgets must be positive and monotonic at loop %d" % display_loop)
		previous_budget = total_hp
	var router := FakeRouter.new()
	root.add_child(router)
	var battle := _instance("res://gameplay/battle/battle.tscn")
	battle.setup(router, {"level_id": "level_001", "endless": true})
	root.add_child(battle)
	await process_frame
	await physics_frame
	_expect(battle.is_endless_mode, "battle must enter endless mode when payload requests it")
	_expect(battle.endless_loop == 0 and is_equal_approx(battle.endless_difficulty_mult, 1.0), "endless mode must start at loop 0 with no HP escalation")
	_expect(battle.endless_template_level_id == "level_025", "endless must resolve to the fixed level_025 template; got %s" % battle.endless_template_level_id)
	_expect(battle.level_ordinal == 25, "endless first loop must use level-25-equivalent economy scaling, got %d" % battle.level_ordinal)
	_expect(absf(battle._endless_gold_multiplier(1, economy) - 1.0) <= 0.0001, "endless loop one kill gold must remain at baseline")
	_expect(absf(battle._endless_gold_multiplier(10, economy) - 2.17) <= 0.0001, "endless loop ten kill gold must be the Tier B linear 2.17x value")
	_expect(battle._endless_gold_milestone_reward(4, economy) == 0, "endless milestone must not pay before loop five")
	_expect(battle._endless_gold_milestone_reward(5, economy) == 30, "endless loop five milestone must pay the first 30 gold grant")
	_expect(battle._endless_gold_milestone_reward(10, economy) == 60, "endless loop ten milestone must scale linearly to 60 gold")
	var gold_before_milestone := int(battle.gold)
	_expect(battle._grant_endless_gold_milestone(5, economy) == 30, "endless milestone must pay exactly once on first claim")
	_expect(int(battle.gold) == gold_before_milestone + 30, "endless milestone must enter the visible run-gold balance")
	_expect(battle._grant_endless_gold_milestone(5, economy) == 0, "endless milestone must reject duplicate claims")
	battle.gold = gold_before_milestone
	battle.endless_gold_milestones_claimed.clear()
	_expect(battle._endless_boss_count() == 1, "endless loops 1-4 must start with one Boss")
	battle.endless_loop = 4
	_expect(battle._endless_boss_count() == 2, "endless loop 5 must add the second Boss using the economy step")
	battle.endless_loop = 40
	_expect(battle._endless_boss_count() == 6, "endless Boss count must respect the economy cap")
	battle.endless_loop = 0
	var last_mob_mult := 0.0
	for display_loop in range(1, 21):
		var mob_mult: float = battle._endless_mob_hp_multiplier(display_loop, economy)
		_expect(mob_mult > last_mob_mult, "endless mob HP multiplier must rise strictly at loop %d" % display_loop)
		last_mob_mult = mob_mult
	var loop8_mult: float = battle._endless_mob_hp_multiplier(8, economy)
	_expect(loop8_mult >= 3.96 and loop8_mult <= 4.84, "endless loop 8 mob HP must remain near 4.4x, got %.3fx" % loop8_mult)
	var late_entry := _instance("res://gameplay/battle/battle.tscn")
	late_entry.setup(router, {"level_id": "level_076", "endless": true})
	root.add_child(late_entry)
	await process_frame
	await physics_frame
	_expect(late_entry.endless_template_level_id == battle.endless_template_level_id, "endless entry from late campaign must use the same template")
	_expect(late_entry.level_ordinal == battle.level_ordinal, "endless entry from late campaign must not inherit late-level economy scaling")
	battle.wave_index = 1
	late_entry.wave_index = 1
	var early_probe: Node = battle._spawn_enemy_instance("zombie_shambler", Vector2(540, 190), false)
	var late_probe: Node = late_entry._spawn_enemy_instance("zombie_shambler", Vector2(540, 190), false)
	_expect(absf(float(early_probe.max_hp) - float(late_probe.max_hp)) <= 0.01, "endless first-loop mob HP must be independent of entry level")
	early_probe.queue_free()
	late_probe.queue_free()
	var grace_boss: Node = battle._spawn_enemy_instance("boss_tank_titan", Vector2(540, 190), true)
	_expect(grace_boss.resistances.is_empty(), "endless first-loop boss grace must remove the opening resistance wall")
	grace_boss.queue_free()
	var budget_probe: Node = battle._spawn_enemy_instance("boss_frost_warden", Vector2(540, 190), true, 1.0, 12345.0)
	var budget_probe_total := float(budget_probe.max_hp) + float(budget_probe.armor_hp_max)
	_expect(absf(budget_probe_total - 12345.0) <= 0.1, "endless Boss must use its loop-budget share without campaign fixed HP or mob multiplier; got %.1f" % budget_probe_total)
	budget_probe.queue_free()
	late_entry.queue_free()
	await process_frame
	var first_endless_threshold := int(battle.next_xp_offer)
	battle.xp = first_endless_threshold + 999
	battle._choose_card("skill_pierce")
	_expect(int(battle.xp) == 0, "endless mode must clear the current XP bar after a skill pick")
	_expect(int(battle.next_xp_offer) > 0, "endless mode must keep a valid next XP threshold after a skill pick")
	_expect(not battle._try_show_xp_card_offer(), "endless mode must not immediately repeat card offers after XP is cleared")
	battle.wave_index = 1
	var before: Node = battle._spawn_enemy_instance("zombie_shambler", Vector2(540, 190), false)
	var hp_before: float = before.max_hp
	before.queue_free()
	battle._advance_endless_loop()
	_expect(battle.endless_loop == 1, "first loop completion must advance endless_loop to 1")
	# _advance_endless_loop 把 wave_index 归零后立刻调用 _start_next_wave()(内部会 +1)，
	# 所以函数返回时 wave_index==1，代表"重新从第一波开始播"而不是停在0。
	_expect(battle.wave_index == 1, "advancing an endless loop must restart from the first wave")
	var mult_loop1: float = battle._endless_mob_hp_multiplier(2, economy)
	_expect(absf(battle.endless_difficulty_mult - mult_loop1) <= 0.001, "second displayed endless loop must use the first staged mob multiplier")
	battle.wave_index = 1
	var after: Node = battle._spawn_enemy_instance("zombie_shambler", Vector2(540, 190), false)
	var hp_after: float = after.max_hp
	after.queue_free()
	_expect(absf(hp_after / maxf(hp_before, 0.001) - mult_loop1) <= 0.01, "endless loop escalation must apply the staged mob multiplier, got %.1f -> %.1f" % [hp_before, hp_after])
	battle._advance_endless_loop()
	_expect(battle.endless_loop == 2, "second loop completion must advance endless_loop to 2")
	var mult_loop2: float = battle._endless_mob_hp_multiplier(3, economy)
	_expect(absf(battle.endless_difficulty_mult - mult_loop2) <= 0.001, "third displayed endless loop must compound the staged mob multiplier")
	_expect(absf(battle.endless_difficulty_mult / maxf(mult_loop1, 0.001) - 1.20) <= 0.001, "early endless mob difficulty must grow by the approved 20%% stage")
	battle.base_hp = 0
	battle._finish(false)
	_expect(bool(router.last_result.get("endless", false)), "endless defeat must report an endless result to the router")
	_expect(int(router.last_result.get("endless_loop", -1)) == 2, "endless defeat result must report the loop reached")
	_expect(int(router.last_result.get("stars", -1)) == 0, "endless defeat result must not report stars")
	_expect(int(router.last_result.get("xp", -1)) == 0, "endless defeat result must not report account XP")
	battle.queue_free()
	save_manager.save_data = original_save
	router.queue_free()
	await process_frame

	# apply_endless_result: 只发金币 + 记录最高轮数，不发经验/星星，不写 levels_progress/unlocks。
	var pre_save: Dictionary = save_manager.save_data.duplicate(true)
	var pre_gold: int = save_manager.get_player_gold()
	var pre_xp: int = save_manager.get_player_xp()
	var pre_star: int = save_manager.get_player_star()
	save_manager.apply_endless_result({"level_id": "level_001", "endless_loop": 9, "gold": 500, "xp": 300, "stars": 5}, false)
	_expect(save_manager.get_player_gold() == pre_gold + 500, "endless result must credit gold")
	_expect(save_manager.get_player_xp() == pre_xp, "endless result must not credit account XP")
	_expect(save_manager.get_player_star() == pre_star, "endless result must not credit star currency")
	_expect(save_manager.get_endless_best_loops() == 9, "endless result must track the best loop count reached")
	_expect(not save_manager.save_data.get("levels_progress", {}).has("level_001") or int(pre_save.get("levels_progress", {}).get("level_001", 0)) == int(save_manager.save_data.get("levels_progress", {}).get("level_001", 0)), "endless result must not alter normal level star progress")
	save_manager.save_data = original_save

func _verify_boss_resistance_and_regeneration(data_loader: Node) -> void:
	var armored_bosses := ["boss_tank_titan", "boss_necrotitan", "boss_apex_overlord"]
	for boss_id_var in data_loader.get_table("bosses").keys():
		var boss_id := str(boss_id_var)
		var boss_row: Dictionary = data_loader.get_row("bosses", boss_id)
		_expect(not boss_row.has("immune") or (boss_row.get("immune", []) as Array).is_empty(), "%s must not ship a hard elemental immunity" % boss_id)
		var values_var: Variant = boss_row.get("resistances", {})
		_expect(values_var is Dictionary, "%s resistances must be data-driven" % boss_id)
		if values_var is Dictionary:
			for reduction_var in (values_var as Dictionary).values():
				var reduction := float(reduction_var)
				_expect(reduction > 0.0 and reduction < 1.0, "%s resistance must stay bounded below full immunity" % boss_id)
		if boss_id in armored_bosses:
			_expect(absf(float(boss_row.get("armor_hp_ratio", 0.0)) - 0.3) <= 0.001, "%s must allocate 30 percent of its total durability to armor" % boss_id)
	var void_phantom: Dictionary = data_loader.get_row("bosses", "boss_void_phantom")
	_expect(absf(float(void_phantom.get("fixed_hp", 0.0)) - 380000.0) <= 1.0, "Void Phantom must keep the B1 model-level HP solve")
	_expect(absf(float(void_phantom.get("bd_coef", 0.0)) - 0.85) <= 0.0001, "Void Phantom must keep the B1 route-pressure base-damage solve")
	_expect(absf(float((void_phantom.get("resistances", {}) as Dictionary).get("physical", 0.0)) - 0.25) <= 0.0001, "Void Phantom must preserve its physical-resistant lightning-weak identity")

	var necro := _instance("res://gameplay/enemy/enemy.tscn")
	root.add_child(necro)
	necro.call("setup", data_loader.get_row("bosses", "boss_necrotitan").duplicate(true), 1.0, true)
	var necro_total_durability := float(necro.max_hp) + float(necro.armor_hp_max)
	_expect(absf(float(necro.armor_hp_max) / necro_total_durability - 0.3) <= 0.001, "Necrotitan armor must be split from, not added on top of, authored durability")
	_expect(necro.has_node("ArmorBar") and necro.get_node("ArmorBar").has_node("ArmorFill"), "armored Bosses must render a local armor rail above the body rail")
	var necro_body_before_armor_hit := float(necro.hp)
	var necro_armor_before_hit := float(necro.armor_hp)
	necro.call("take_damage", 100.0, "lightning")
	_expect(absf(float(necro.hp) - necro_body_before_armor_hit) <= 0.01, "damage without Armor Bypass must not reach the Necrotitan body while armor remains")
	_expect(absf(float(necro.armor_hp) - (necro_armor_before_hit - 100.0)) <= 0.01, "damage without Armor Bypass must drain Necrotitan armor")
	necro.armor_hp = 0.0
	necro.call("_break_armor_layer")
	var necro_start := float(necro.hp)
	necro.call("take_damage", 100.0, "lightning")
	_expect(absf(float(necro.hp) - (necro_start - 100.0)) <= 0.01, "neutral lightning must visibly damage the Necrotitan")
	necro.call("_process_self_mechanic", 0.5)
	_expect(absf(float(necro.hp) - (necro_start - 100.0)) <= 0.01, "recent neutral damage must pause Necrotitan regeneration")
	necro.call("_process_self_mechanic", 0.31)
	_expect(float(necro.hp) > necro_start - 100.0, "Necrotitan regeneration must resume after the neutral-hit delay")
	var before_fire := float(necro.hp)
	necro.call("take_damage", 100.0, "fire")
	_expect(absf(float(necro.hp) - (before_fire - 150.0)) <= 0.01, "Necrotitan fire weakness must add 50 percent damage")
	_expect(float(necro.regen_suppressed_time) >= 2.99, "fire weakness must suppress Necrotitan regeneration for the authored extended window")
	var before_poison := float(necro.hp)
	necro.call("take_damage", 100.0, "poison")
	_expect(absf(float(necro.hp) - (before_poison - 50.0)) <= 0.01, "Necrotitan poison resistance must reduce damage by 50 percent without nullifying it")
	necro.queue_free()
	await process_frame

	var titan := _instance("res://gameplay/enemy/enemy.tscn")
	root.add_child(titan)
	titan.call("setup", data_loader.get_row("bosses", "boss_tank_titan").duplicate(true), 1.0, true)
	var titan_body_start := float(titan.hp)
	var titan_armor_start := float(titan.armor_hp)
	var titan_physical_resistance := float((data_loader.get_row("bosses", "boss_tank_titan").get("resistances", {}) as Dictionary).get("physical", 0.0))
	var titan_resisted_hit := 100.0 * (1.0 - titan_physical_resistance)
	titan.call("take_damage", 100.0, "physical")
	_expect(absf(float(titan.hp) - titan_body_start) <= 0.01, "Tank Titan body must stay intact while a non-penetrating hit is absorbed by armor")
	_expect(absf(float(titan.armor_hp) - (titan_armor_start - titan_resisted_hit)) <= 0.01, "Tank Titan physical resistance must reduce armor damage by its authored amount")
	var body_before_bypass := float(titan.hp)
	var armor_before_bypass := float(titan.armor_hp)
	titan.call("take_damage", 100.0, "physical", 0.5)
	var titan_penetrating_hit := 100.0 * (1.0 - titan_physical_resistance * 0.5)
	_expect(absf(float(titan.hp) - (body_before_bypass - titan_penetrating_hit * 0.5)) <= 0.01, "50 percent Armor Bypass must send half of the resisted hit directly to the Tank Titan body")
	_expect(absf(float(titan.armor_hp) - (armor_before_bypass - titan_penetrating_hit * 0.5)) <= 0.01, "the non-bypassed half of a penetrating hit must still drain Tank Titan armor")
	titan.armor_hp = 10.0
	var before_break := float(titan.hp)
	titan.call("take_damage", 100.0, "physical")
	_expect(bool(titan.armor_broken) and is_zero_approx(float(titan.armor_hp)), "Tank Titan armor must break when its durability reaches zero")
	_expect(absf(float(titan.hp) - (before_break - (titan_resisted_hit - 10.0))) <= 0.01, "overflow from the armor-breaking physical hit must reach the Boss body")
	titan.queue_free()
	await process_frame

	var apex := _instance("res://gameplay/enemy/enemy.tscn")
	root.add_child(apex)
	apex.call("setup", data_loader.get_row("bosses", "boss_apex_overlord").duplicate(true), 1.0, true)
	apex.armor_hp = 0.0
	apex.call("_break_armor_layer")
	var apex_start := float(apex.hp)
	apex.call("take_damage", 100.0, "fire")
	_expect(absf(float(apex.hp) - (apex_start - 50.0)) <= 0.01, "Apex elemental resistance must leave 50 percent real damage")
	var before_physical := float(apex.hp)
	apex.call("take_damage", 100.0, "physical")
	_expect(absf(float(apex.hp) - (before_physical - 150.0)) <= 0.01, "Apex physical weakness must add 50 percent damage")
	apex.queue_free()
	await process_frame

func _verify_enemy_hit_flash_scope(data_loader: Node) -> void:
	var boss_enemy: Node = _instance("res://gameplay/enemy/enemy.tscn")
	root.add_child(boss_enemy)
	var boss_row: Dictionary = data_loader.get_row("bosses", "boss_tank_titan").duplicate(true)
	boss_row["mechanic"] = "basic"
	boss_row["immune"] = []
	boss_row["resistances"] = {}
	boss_row["weakness"] = "none"
	boss_row["resist"] = "none"
	boss_enemy.call("setup", boss_row, 1.0, true)
	var expected_boss_name: String = str(data_loader.tr_key(str(boss_row.get("name_key", ""))))
	_expect(
		boss_enemy.threat_marker != null and str(boss_enemy.threat_marker.text) == expected_boss_name,
		"boss local marker must show the translated monster name only; got %s expected %s" % [
			str(boss_enemy.threat_marker.text) if boss_enemy.threat_marker != null else "<missing>",
			expected_boss_name,
		]
	)
	boss_enemy.call("take_damage", 10.0, "fire")
	await process_frame
	var boss_canvas := boss_enemy as CanvasItem
	var boss_sprite := boss_enemy.get_node("Sprite") as Sprite2D
	_expect(_color_close(boss_canvas.modulate, Color.WHITE), "boss hit feedback must not tint the whole enemy node")
	_expect(_color_close(boss_sprite.self_modulate, Color.WHITE), "boss hit feedback must not reveal a full-size red bitmap rectangle")
	boss_enemy.queue_free()
	await process_frame

	var normal_enemy: Node = _instance("res://gameplay/enemy/enemy.tscn")
	root.add_child(normal_enemy)
	var normal_row: Dictionary = data_loader.get_row("zombies", "zombie_shambler").duplicate(true)
	normal_row["immune"] = []
	normal_row["weakness"] = "none"
	normal_row["resist"] = "none"
	normal_enemy.call("setup", normal_row, 1.0, false)
	normal_enemy.call("take_damage", 5.0, "fire")
	await process_frame
	var normal_canvas := normal_enemy as CanvasItem
	_expect(_color_close(normal_canvas.modulate, Color.WHITE), "enemy hit feedback must keep HP/status children out of the flash tint")
	normal_enemy.queue_free()
	await process_frame

func _verify_zombie_mechanic_profiles(data_loader: Node) -> void:
	var zombies: Dictionary = data_loader.get_table("zombies")
	var audio_manager := root.get_node("/root/AudioManager")
	var required_params := {
		"zombie_runner": ["dash_interval", "dash_advance", "damage_coef"],
		"zombie_spitter": ["skill_interval", "damage_coef"],
		"zombie_screamer": ["radius", "speed_mult", "pulse_interval"],
		"zombie_shielder": ["radius", "damage_taken_mult", "pulse_interval"],
		"zombie_hopper": ["leap_interval", "leap_advance", "damage_coef"],
		"zombie_juggernaut": ["shock_interval", "damage_coef"],
		"zombie_phantom": ["blink_interval", "blink_advance", "damage_coef"],
		"zombie_necromancer": ["skill_interval", "summon_id"],
		"zombie_toxic": ["cloud_interval", "damage_coef", "radius"],
		"zombie_charger": ["charge_interval", "charge_advance", "damage_coef"],
		"zombie_regenerator": ["regen_pct_per_sec", "pulse_interval"],
		"zombie_warden": ["radius", "damage_taken_mult", "pulse_interval"],
		"zombie_mutant": ["trigger_hp_ratio", "speed_mult", "damage_mult", "heal_ratio"],
		"zombie_berserker": ["trigger_hp_ratio", "speed_mult", "damage_mult"]
	}
	for zombie_id in required_params.keys():
		_expect(zombies.has(zombie_id), "zombie table must include mechanic profile: %s" % zombie_id)
		var params: Dictionary = zombies[zombie_id].get("mechanic_params", {})
		for key in required_params[zombie_id]:
			_expect(params.has(key), "%s mechanic params must include %s" % [zombie_id, key])
	var battle := _instance("res://gameplay/battle/battle.tscn")
	for zombie_id_var in zombies.keys():
		var zombie_id := str(zombie_id_var)
		var mechanic := str((zombies[zombie_id] as Dictionary).get("mechanic", ""))
		_expect(not battle._zombie_event_sfx(mechanic, "action").is_empty(), "%s action must resolve exactly one mechanic cue" % zombie_id)
		_expect(battle._zombie_event_sfx(mechanic, "death") == "enemy_death", "%s death must use the shared death cue instead of replaying its mechanic" % zombie_id)
		_expect(battle._zombie_event_sfx(mechanic, "entry").is_empty(), "%s entry must remain silent instead of replaying its mechanic" % zombie_id)
		_expect(battle._zombie_event_sfx(mechanic, "ambient").is_empty(), "%s ambient loop must remain silent" % zombie_id)
		_expect(battle._zombie_event_sfx(mechanic, "passive").is_empty(), "%s passive visual feedback must remain silent" % zombie_id)
	_expect(audio_manager.ENEMY_FOLEY_GROUP == "enemy_foley", "all zombie and defense feedback must share one exclusive foley lane")
	_expect(audio_manager.enemy_sfx_interrupts_current("enemy_breach"), "real base contact must interrupt the current zombie action tail")
	_expect(audio_manager.enemy_sfx_interrupts_current("threat_warning"), "defense warning must interrupt lower-priority zombie chatter")
	_expect(audio_manager.enemy_sfx_interrupts_current("hit_immune"), "base barrier contact must interrupt the current zombie action tail")
	_expect(not audio_manager.enemy_sfx_interrupts_current("zombie_runner"), "ordinary zombie actions must not replace an already audible enemy action")
	var kind_to_vfx := {
		"runner_dash": "vfx_threat_warning.png",
		"leap_strike": "vfx_threat_warning.png",
		"charge": "vfx_threat_warning.png",
		"toxic_cloud": "vfx_poison_cloud.png",
		"regen": "vfx_poison_cloud.png",
		"mutate": "vfx_boss_phase.png",
		"enrage": "vfx_enemy_skill_enrage.png",
		"buff_aura": "vfx_boss_phase.png",
		"shield_aura": "vfx_crit.png",
		"ward": "vfx_crit.png",
		"juggernaut": "vfx_crit.png"
	}
	for kind in kind_to_vfx.keys():
		var path := str(battle._attack_vfx_path(kind))
		_expect(path.ends_with(kind_to_vfx[kind]), "enemy mechanic %s must use a distinct vfx, got %s" % [kind, path])
		_expect(battle._attack_color_for_mechanic(kind).a > 0.7, "enemy mechanic %s must define a visible vfx color" % kind)
	# Directional texture semantics: all four authored source vectors must rotate
	# onto the enemy's screen-down advance vector. This prevents a polished
	# frame from visually firing sideways or landing behind the moving zombie.
	_expect(
		is_equal_approx(battle._directional_vfx_rotation("vfx_enemy_skill_runner_dash", Vector2.DOWN), PI * 0.5),
		"runner dash wedge must point toward the bottom base"
	)
	_expect(
		is_equal_approx(battle._directional_vfx_rotation("vfx_enemy_skill_charge", Vector2.DOWN), PI * 0.5),
		"charge wedge must point toward the bottom base"
	)
	_expect(
		is_equal_approx(battle._directional_vfx_rotation("vfx_enemy_skill_leap_strike", Vector2.DOWN), PI * 0.25),
		"leap landing arc must terminate below the zombie"
	)
	_expect(
		is_equal_approx(battle._directional_vfx_rotation("vfx_enemy_skill_phase_shift", Vector2.DOWN), PI * 0.5),
		"phase trail must follow the boss toward the bottom base"
	)
	_expect(
		is_equal_approx(battle._directional_vfx_rotation("vfx_enemy_skill_ranged_spit", Vector2.DOWN), PI * 0.5),
		"ranged venom launch must point from its source toward the bottom base"
	)
	_expect(
		is_equal_approx(battle._directional_vfx_rotation("vfx_hit_physical", Vector2.DOWN, 0.37), 0.37),
		"radial/non-directional VFX must preserve their authored fallback rotation"
	)
	_expect(battle._zombie_mechanic_sfx("phase") == "zombie_phantom", "ordinary phase blink must route to the wind-cut SFX")
	_expect(battle._zombie_mechanic_sfx("phase_shift") == "zombie_phantom", "boss phase shift must route to the wind-cut SFX")
	_expect(battle._zombie_mechanic_sfx("charge") == "zombie_phantom", "pangolin-like charger movement must route to the wind-cut SFX")
	_expect(battle._enemy_advance_warning_sfx("phase").is_empty(), "phase blink must not layer the legacy generic warning cue")
	_expect(battle._enemy_advance_warning_sfx("charge").is_empty(), "far charger movement must not layer the legacy impact-like warning cue")
	_expect(battle._enemy_advance_warning_sfx("runner_dash").is_empty(), "runner dash must not layer a generic warning over its movement cue")
	_expect(battle._enemy_advance_warning_sfx("leap_strike").is_empty(), "hopper leap must not layer a generic warning over its movement cue")
	_expect(battle._enemy_skill_base_impact_sfx("phase").is_empty(), "phase slip damage must not fake a physical barricade impact")
	_expect(battle._enemy_skill_base_impact_sfx("charge") == "enemy_breach", "physical charge damage must retain barricade contact")
	var charger_trigger_y := float(zombies["zombie_charger"].get("mechanic_params", {}).get("trigger_y", 660.0))
	_expect(not battle._enemy_advance_reaches_base(charger_trigger_y), "far charger movement must not enter the base-damage/contact branch")
	_expect(battle._enemy_advance_reaches_base(battle._base_line_inner_y(battle.BASE_LINE_DEFAULT_SLOW_FIELD_INSET)), "charger contact that begins at the base-pressure band must retain real base damage")
	_expect(battle._boss_attack_motion_sfx("dash_combo") == "zombie_phantom", "Void Phantom dash attacks must announce their phase motion before impact")
	_expect(battle._boss_attack_motion_sfx("melee_heavy").is_empty(), "non-phase boss attacks must not inherit the phase whoosh")
	var bosses: Dictionary = data_loader.get_table("bosses")
	for boss_id in bosses.keys():
		var boss_row: Dictionary = bosses[boss_id]
		if str(boss_row.get("mechanic", "")) == "phase_shift":
			var base_profile: Dictionary = boss_row.get("mechanic_params", {}).get("base_attack_profile", {})
			_expect(
				battle._boss_attack_motion_sfx(str(base_profile.get("mode", ""))) == "zombie_phantom",
				"%s phase-shift attack motion must route to the wind-cut SFX" % boss_id
			)
	var target := FakeAimTarget.new()
	target.breach_damage = 20
	battle.breach_damage_mult = 0.5
	_expect(battle._enemy_skill_damage(target, 0.35, 2.0) == 4, "enemy skill damage must respect breach damage mitigation")
	target.breach_damage = 0
	_expect(battle._enemy_skill_damage(target, 0.35, 2.0) == 0, "zero model base damage must not be overridden by generic enemy skill chip damage")
	target.free()
	battle.free()

func _verify_zombie_model_redesigns(data_loader: Node) -> void:
	# The Python silhouette audit proves transparent padding and cross-roster
	# separation. This runtime probe closes the other half of the contract:
	# Godot must import every authored action frame and Enemy must actually use
	# those paths instead of silently falling back to a prototype.
	var redesigned_ids := [
		"zombie_bomber",
		"zombie_spitter",
		"zombie_juggernaut",
		"zombie_necromancer",
		"zombie_charger",
		"zombie_regenerator",
		"zombie_splitter",
		"zombie_warden",
	]
	var expected_actions := {
		"_idle_frames": 4,
		"_walk_frames": 6,
		"_attack_frames": 8,
		"_special_frames": 6,
		"_hurt_frames": 3,
		"_death_frames": 6,
	}
	var enemy_scene := load("res://gameplay/enemy/enemy.tscn") as PackedScene
	_expect(enemy_scene != null, "zombie model runtime check must load enemy.tscn")
	for zombie_id_var in redesigned_ids:
		var zombie_id := str(zombie_id_var)
		var row: Dictionary = data_loader.get_row("zombies", zombie_id)
		_expect(not row.is_empty(), "redesigned zombie data must remain present: %s" % zombie_id)
		var enemy: Node = enemy_scene.instantiate()
		root.add_child(enemy)
		enemy.call("setup", row, 1.0, false)
		for property_var in expected_actions.keys():
			var property_name := str(property_var)
			var frames: Array = enemy.get(property_name)
			_expect(
				frames.size() == int(expected_actions[property_name]),
				"%s %s must import the complete frame family" % [zombie_id, property_name]
			)
			for frame_var in frames:
				var frame := frame_var as Texture2D
				_expect(frame != null, "%s %s contains a missing imported texture" % [zombie_id, property_name])
				if frame == null:
					continue
				_expect(
					frame.get_width() == 512 and frame.get_height() == 512,
					"%s runtime animation frames must remain 512x512" % zombie_id
				)
				_expect(
					str(frame.resource_path).contains("/%s/" % zombie_id),
					"%s must not fall back to another zombie's frame" % zombie_id
				)
		var sprite := enemy.get_node("Sprite") as Sprite2D
		_expect(sprite.texture != null, "%s must render a live animation texture" % zombie_id)
		_expect(
			is_equal_approx(sprite.scale.x, 0.32) and is_equal_approx(sprite.scale.y, 0.32),
			"%s model redesign must not alter collision or gameplay scale" % zombie_id
		)
		enemy.free()

func _verify_zombie_attack_animation_contracts(data_loader: Node) -> void:
	var enemy_scene := load("res://gameplay/enemy/enemy.tscn") as PackedScene
	_expect(enemy_scene != null, "zombie attack contract check must load enemy.tscn")
	var attack_sfx_by_mode := {
		"rapid_claw": "enemy_attack_fast_claw", "claw_combo": "enemy_attack_fast_claw",
		"low_bite": "enemy_attack_bite",
		"heavy_slam": "enemy_attack_heavy_slam", "shoulder_ram": "enemy_attack_heavy_slam",
		"shield_bash": "enemy_attack_heavy_slam", "piston_slam": "enemy_attack_heavy_slam",
		"wedge_ram": "enemy_attack_heavy_slam", "triple_maul": "enemy_attack_heavy_slam",
		"mutant_hook": "enemy_attack_heavy_slam",
		"core_blast": "enemy_attack_blast",
		"acid_spit": "enemy_attack_corrosion", "corrosion_burst": "enemy_attack_corrosion",
		"regen_hook": "enemy_attack_corrosion",
		"sonic_burst": "enemy_attack_support", "ritual_strike": "enemy_attack_support",
		"ward_pulse": "enemy_attack_support",
		"claw_drag": "enemy_attack_claw", "leap_rake": "enemy_attack_claw",
		"phase_slash": "enemy_attack_claw",
	}
	var attack_sfx_families := {}
	for zombie_id_var in data_loader.get_table("zombies").keys():
		var zombie_id := str(zombie_id_var)
		var row: Dictionary = data_loader.get_row("zombies", zombie_id)
		var attack: Dictionary = row.get("attack_animation", {})
		_expect(not attack.is_empty(), "%s must expose an authored attack profile" % zombie_id)
		_expect(
			int(attack.get("contact_frame", 0)) == 4,
			"%s damage contact must bind to authored frame 4" % zombie_id
		)
		var enemy: Node = enemy_scene.instantiate()
		root.add_child(enemy)
		enemy.call("setup", row, 1.0, false)
		var frames: Array = enemy.get("_attack_frames")
		_expect(frames.size() == 8, "%s must import all 8 attack frames" % zombie_id)
		var attack_sfx_id := str(attack_sfx_by_mode.get(str(attack.get("mode", "")), ""))
		_expect(not attack_sfx_id.is_empty(), "%s must resolve a zombie attack-action SFX before base contact" % zombie_id)
		attack_sfx_families[attack_sfx_id] = true
		var events := {"started": 0, "breaches": 0}
		enemy.base_attack_started.connect(func(_source: Node, _profile: Dictionary) -> void:
			events["started"] = int(events["started"]) + 1
		)
		enemy.breached.connect(func(_source: Node, _damage: int) -> void:
			events["breaches"] = int(events["breaches"]) + 1
		)
		enemy.call("_enter_base_attack")
		enemy.set("base_attack_timer", 0.0)
		enemy.call("_process_base_attack", 0.001)
		_expect(
			bool(enemy.get("_normal_attack_sequence_active")),
			"%s must begin a contact-timed attack state" % zombie_id
		)
		_expect(
			int(events["started"]) == 1,
			"%s must emit one attack-action cue at wind-up before base contact" % zombie_id
		)
		_expect(
			int(events["breaches"]) == 0,
			"%s must not damage the base when anticipation starts" % zombie_id
		)
		var duration := float(attack.get("duration", 0.48))
		var contact_time := duration * float(attack.get("contact_ratio", 0.5))
		var pre_contact := maxf(0.01, contact_time - 0.02)
		enemy.call("_update_animation", pre_contact)
		enemy.call("_process_base_attack", pre_contact)
		_expect(
			int(events["breaches"]) == 0,
			"%s must not damage the base before its visual contact pose" % zombie_id
		)
		enemy.call("_update_animation", 0.03)
		enemy.call("_process_base_attack", 0.03)
		_expect(
			int(events["breaches"]) == 1,
			"%s must damage the base exactly on its authored contact" % zombie_id
		)
		_expect(
			int(enemy.get("_anim_frame")) == 3,
			"%s contact event must display runtime frame 4" % zombie_id
		)
		enemy.call("_update_animation", duration)
		enemy.call("_process_base_attack", duration)
		_expect(
			int(events["breaches"]) == 1,
			"%s recovery must not duplicate base damage" % zombie_id
		)
		_expect(
			not bool(enemy.get("_normal_attack_sequence_active")),
			"%s must leave the attack state after recovery" % zombie_id
		)
		enemy.free()
	_expect(attack_sfx_families.size() >= 7, "ordinary zombies must span at least seven distinct attack-action SFX families")
	_expect(str(AudioManager.SFX.get("enemy_breach", "")).ends_with("sfx_enemy_breach.wav"), "base contact must retain its dedicated realistic barricade SFX")
	_expect(str(AudioManager.SFX.get("zombie_phantom", "")).ends_with("sfx_zombie_phantom.wav"), "phase blink must retain its dedicated wind-cut SFX")

func _color_close(a: Color, b: Color, tolerance := 0.01) -> bool:
	return absf(a.r - b.r) <= tolerance and absf(a.g - b.g) <= tolerance and absf(a.b - b.b) <= tolerance and absf(a.a - b.a) <= tolerance

func _verify_progression_unlock_repair(save_manager: Node) -> void:
	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	save_manager.save_data = save_manager._default_save()
	save_manager.save_data["levels_progress"] = {"level_001": 3, "level_002": 3}
	save_manager.save_data["unlocks"]["levels"] = ["level_001", "level_002"]
	_expect(save_manager._refresh_level_unlocks_from_progress(), "progression repair must detect stale level unlocks")
	_expect(save_manager.is_level_unlocked("level_003"), "cleared level_002 must unlock level_003 during repair")

	save_manager.save_data = save_manager._default_save()
	save_manager.apply_level_result({"level_id": "level_002", "victory": true, "stars": 2, "gold": 0, "xp": 0}, false)
	_expect(save_manager.is_level_unlocked("level_003"), "victory result must infer and unlock level_003 even without payload next_level")
	_expect(not save_manager.is_challenge_unlocked("level_002"), "normal 2-star clear must not unlock challenge mode")
	save_manager.apply_level_result({"level_id": "level_002", "victory": true, "stars": 3, "gold": 0, "xp": 0}, false)
	_expect(save_manager.is_challenge_unlocked("level_002"), "normal 3-star clear must unlock challenge mode")

	save_manager.save_data = save_manager._default_save()
	save_manager.apply_level_result({"level_id": "level_002", "victory": false, "stars": 0, "next_level": "level_003", "gold": 0, "xp": 0}, false)
	_expect(not save_manager.is_level_unlocked("level_003"), "defeat result must not unlock level_003")
	_expect(not save_manager.is_challenge_unlocked("level_002"), "defeat must not unlock challenge mode")

	save_manager.save_data = save_manager._default_save()
	var star_before_challenge: int = save_manager.get_player_star()
	save_manager.apply_challenge_result({"level_id": "level_002", "victory": true, "stars": 2, "gold": 0, "xp": 0}, false)
	_expect(save_manager.get_challenge_stars("level_002") == 2, "challenge result must store challenge stars separately")
	_expect(save_manager.get_level_stars("level_002") == 0, "challenge result must not overwrite normal level stars")
	_expect(not save_manager.is_challenge_unlocked("level_002"), "challenge stars alone must not unlock challenge entry without normal 3-star clear")
	_expect(save_manager.get_player_star() == star_before_challenge + 2, "first challenge clear must credit earned challenge stars")
	_expect(not save_manager.is_level_unlocked("level_003"), "challenge clear must not unlock the next campaign level")
	save_manager.apply_challenge_result({"level_id": "level_002", "victory": true, "stars": 2, "gold": 0, "xp": 0}, false)
	_expect(save_manager.get_player_star() == star_before_challenge + 2, "repeating the same challenge stars must not duplicate star currency")
	save_manager.apply_challenge_result({"level_id": "level_002", "victory": true, "stars": 3, "gold": 0, "xp": 0}, false)
	_expect(save_manager.get_player_star() == star_before_challenge + 3, "improving challenge stars must only credit the delta")
	save_manager.save_data = original_save

func _verify_battle_speed_progression_gate(save_manager: Node) -> void:
	var settings_manager := root.get_node("/root/SettingsManager")
	var internal_test_override := bool(settings_manager.is_testflight_speed_unlocked())
	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var original_settings: Dictionary = settings_manager.settings.duplicate(true)
	var router := FakeRouter.new()
	root.add_child(router)

	var tiers := (
		[
			{"level": 1, "expected_speed": 5.0, "visible": true},
			{"level": 29, "expected_speed": 5.0, "visible": true},
			{"level": 50, "expected_speed": 5.0, "visible": true},
		]
		if internal_test_override
		else [
			{"level": 29, "expected_speed": 1.0, "visible": false},
			{"level": 30, "expected_speed": 2.0, "visible": true},
			{"level": 50, "expected_speed": 5.0, "visible": true},
		]
	)
	for tier in tiers:
		var highest_level := int(tier["level"])
		var test_save: Dictionary = _battle_smoke_loadout(original_save)
		var unlocked_levels: Array = []
		for level_no in range(1, highest_level + 1):
			unlocked_levels.append("level_%03d" % level_no)
		test_save["unlocks"]["levels"] = unlocked_levels
		save_manager.save_data = test_save
		settings_manager.settings["battle_speed"] = 5.0

		var battle := _instance("res://gameplay/battle/battle.tscn")
		battle.setup(router, {"level_id": "level_001"})
		root.add_child(battle)
		await process_frame
		await physics_frame
		var speed_button := battle.get_node("PauseLayer/SpeedButton") as Button
		_expect(battle.battle_speed_progress_level == highest_level, "battle speed gate must use highest unlocked campaign level %d" % highest_level)
		_expect(is_equal_approx(float(battle.battle_speed), float(tier["expected_speed"])), "level %d speed gate must clamp stale 5X to %.0fX" % [highest_level, float(tier["expected_speed"])])
		_expect(speed_button.visible == bool(tier["visible"]), "speed button visibility must match level %d unlock tier" % highest_level)
		if internal_test_override and highest_level == 1:
			battle._cycle_battle_speed()
			_expect(is_equal_approx(float(battle.battle_speed), 1.0), "internal TestFlight speed button must wrap from 5X to 1X at level 1")
			battle._cycle_battle_speed()
			_expect(is_equal_approx(float(battle.battle_speed), 2.0), "internal TestFlight speed button must expose 2X at level 1")
			battle._cycle_battle_speed()
			_expect(is_equal_approx(float(battle.battle_speed), 5.0), "internal TestFlight speed button must expose 5X at level 1")
		if highest_level == 30:
			battle._cycle_battle_speed()
			_expect(is_equal_approx(float(battle.battle_speed), 1.0), "level 30 speed button must wrap from 2X to 1X without exposing 5X")
			battle._cycle_battle_speed()
			_expect(is_equal_approx(float(battle.battle_speed), 2.0), "level 30 speed button must cycle back to 2X")
		if highest_level == 50:
			settings_manager.settings["battle_speed"] = 2.0
			battle.battle_speed = 2.0
			battle._cycle_battle_speed()
			_expect(is_equal_approx(float(battle.battle_speed), 5.0), "level 50 speed button must unlock the 5X option")
		battle.queue_free()
		await process_frame
		Engine.time_scale = 1.0

	settings_manager.settings = original_settings
	settings_manager.save_settings()
	save_manager.save_data = original_save
	router.queue_free()
	await process_frame

func _verify_battle_speed_stress(save_manager: Node) -> void:
	var settings_manager := root.get_node("/root/SettingsManager")
	var input_manager := root.get_node("/root/InputManager")
	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var original_settings: Dictionary = settings_manager.settings.duplicate(true)
	var router := FakeRouter.new()
	root.add_child(router)
	var test_save: Dictionary = _battle_smoke_loadout(original_save)
	var unlocked_levels: Array = []
	for level_no in range(1, 51):
		unlocked_levels.append("level_%03d" % level_no)
	test_save["unlocks"]["levels"] = unlocked_levels
	save_manager.save_data = test_save
	settings_manager.settings["battle_speed"] = 5.0

	var battle := _instance("res://gameplay/battle/battle.tscn")
	battle.setup(router, {"level_id": "level_001"})
	root.add_child(battle)
	await process_frame
	await physics_frame
	_expect(is_equal_approx(float(battle.battle_speed), 5.0), "5X stress battle must start at the unlocked 5X speed")
	var peak_enemies := 0
	var peak_projectiles := 0
	for frame in range(240):
		if frame == 72:
			input_manager.skill_pressed.emit(0)
		await physics_frame
		if not is_instance_valid(battle):
			_expect(false, "5X stress battle scene must remain valid")
			break
		peak_enemies = maxi(peak_enemies, battle.get_node("EnemyLayer").get_child_count())
		peak_projectiles = maxi(peak_projectiles, battle.get_node("ProjectileLayer").get_child_count())
	_expect(is_instance_valid(battle) and not battle.battle_finished, "5X battle must remain active through the stress window")
	_expect(peak_enemies < 220, "5X enemy population must remain bounded; peak=%d" % peak_enemies)
	_expect(peak_projectiles < 480, "5X projectile population must remain bounded; peak=%d" % peak_projectiles)
	if is_instance_valid(battle):
		battle.queue_free()
	await process_frame
	Engine.time_scale = 1.0
	settings_manager.settings = original_settings
	settings_manager.save_settings()
	save_manager.save_data = original_save
	router.queue_free()
	await process_frame

func _verify_resource_chip_theme_matrix(theme_manager: Node) -> void:
	var original_theme_id := str(theme_manager.active_theme_id())
	var fixture_host := Control.new()
	fixture_host.name = "ResourceChipThemeFixture"
	fixture_host.position = Vector2(-2200.0, -2200.0)
	fixture_host.size = Vector2(904.0, 58.0)
	root.add_child(fixture_host)
	for theme_id in ["default", "neon_tempest", "infernal_dominion", "polar_aurora", "gilded_eclipse"]:
		theme_manager._set_active_without_persist(theme_id)
		var bar := UiKit.standard_resource_bar(31612, 37, 12172, Vector2(174, 58), 25)
		bar.name = "ResourceBar_" + theme_id
		bar.size = fixture_host.size
		bar.add_theme_constant_override("separation", 12)
		fixture_host.add_child(bar)
		await process_frame
		_expect(bar.get_child_count() == 3, "%s resource bar must render only gold, stars and XP" % theme_id)
		_expect(bar.get_node_or_null("PowerResourceChip") == null, "%s resource bar must not present Effective Power as a fourth currency" % theme_id)
		_assert_resource_chip_geometry(bar, "%s resource chips" % theme_id, theme_id)
		bar.queue_free()
		await process_frame
	theme_manager._set_active_without_persist(original_theme_id)
	fixture_host.queue_free()
	await process_frame

func _verify_combo_hud_optical_layout() -> void:
	var fixture := Control.new()
	fixture.name = "ComboHudOpticalFixture"
	fixture.set_script(load("res://gameplay/hud/combo_hud.gd"))
	var label_node := Label.new()
	label_node.name = "Label"
	fixture.add_child(label_node)
	var milestone_node := Label.new()
	milestone_node.name = "Milestone"
	fixture.add_child(milestone_node)
	var timer_node := Timer.new()
	timer_node.name = "DecayTimer"
	fixture.add_child(timer_node)
	fixture.position = Vector2(-2200.0, -2200.0)
	root.add_child(fixture)
	await process_frame
	var frame := fixture.get_node_or_null("Frame") as Panel
	var label := fixture.get_node_or_null("Label") as Label
	_expect(frame != null and label != null, "combo HUD must expose its authored frame and main label")
	if frame != null and label != null:
		_expect(label.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "combo HUD label must retain vertical alignment")
		_expect(label.autowrap_mode == TextServer.AUTOWRAP_OFF, "combo HUD text must remain a single centered line")
		_expect(absf(float(label.get_meta("combo_optical_center_y", 0.0)) + 4.0) <= 0.1, "combo HUD must keep the owner-approved four-pixel upward glyph correction")
		_expect(absf(label.get_rect().get_center().y - frame.get_rect().get_center().y + 4.0) <= 0.1, "combo HUD label lane must derive from the plate center plus its optical correction")
		for count in [2, 11, 100]:
			label.text = "%d 连击" % count
			_expect(not label.text.contains("\n"), "combo HUD %d-hit copy must remain on one line" % count)
	fixture.queue_free()
	await process_frame

func _assert_resource_chip_geometry(row: Node, context: String, expected_theme_id: String) -> void:
	_expect(row != null, "%s must exist" % context)
	if row == null:
		return
	var chips_checked := 0
	for chip_node in row.get_children():
		if not chip_node is Button:
			continue
		var chip := chip_node as Button
		var content := chip.get_node_or_null("Content") as Control
		var group := chip.get_node_or_null("Content/ContentGroup") as HBoxContainer
		var icon_node := chip.get_node_or_null("Content/ContentGroup/Icon") as TextureRect
		var value := chip.get_node_or_null("Content/ContentGroup/Value") as Label
		_expect(content != null and group != null and icon_node != null and value != null, "%s chips must expose one tightly sized icon + value group" % context)
		if content == null or group == null or icon_node == null or value == null:
			continue
		var chip_rect := chip.get_global_rect()
		var group_rect := group.get_global_rect()
		var icon_rect := icon_node.get_global_rect()
		var value_rect := value.get_global_rect()
		var optical_x := float(chip.get_meta("resource_chip_optical_offset_x", 0.0))
		var optical_y := float(chip.get_meta("resource_chip_optical_offset_y", 0.0))
		_expect(absf(optical_y + 2.0) <= 0.1, "%s %s must keep the owner-approved two-pixel upward visible-ink correction" % [context, chip.name])
		_expect(absf(group_rect.get_center().x - (chip_rect.get_center().x + optical_x)) <= 0.6, "%s %s content group must keep its declared horizontal optical correction" % [context, chip.name])
		_expect(absf(group_rect.get_center().y - (chip_rect.get_center().y + optical_y)) <= 0.6, "%s %s content group must keep its declared vertical optical correction" % [context, chip.name])
		_expect(absf(icon_rect.get_center().y - value_rect.get_center().y) <= 0.6, "%s %s icon and value must share one visual baseline centre" % [context, chip.name])
		_expect(icon_rect.position.x >= chip_rect.position.x + 42.0, "%s %s icon must clear the deepest themed end armour" % [context, chip.name])
		_expect(icon_rect.end.x <= value_rect.position.x - 8.0, "%s %s icon and value must keep a readable optical gap" % [context, chip.name])
		var style := chip.get_theme_stylebox("normal") as StyleBoxTexture
		var expected_path_fragment := "/sprites/ui/ui_button_secondary_native_" if expected_theme_id == "default" else "/sprites/themes/%s/ui/ui_button_secondary_native_" % expected_theme_id
		_expect(
			style != null
			and style.texture != null
			and style.texture.resource_path.contains(expected_path_fragment),
			"%s %s must use the active theme's rendered native bezel" % [context, chip.name]
		)
		chips_checked += 1
	_expect(chips_checked == 3, "%s must audit exactly the three account resources: gold, stars and XP" % context)

func _assert_semantic_tag_panel(tag: PanelContainer, context: String) -> void:
	_expect(tag.has_meta("semantic_tag_role"), "%s must declare a semantic tag role" % context)
	_expect(tag.custom_minimum_size.y >= 38.0, "%s must preserve the mobile tag height" % context)
	var style := tag.get_theme_stylebox("panel") as StyleBoxTexture
	_expect(
		style != null
		and style.texture != null
		and style.texture.resource_path.ends_with("ui_semantic_tag_microframe_v2.png")
		and style.texture_margin_left >= 16.0
		and style.texture_margin_top >= 16.0
		and style.modulate_color.a >= 0.90,
		"%s must use the dedicated continuous texture-backed semantic tag style" % context
	)
	var copy := tag.get_node_or_null("Text") as Label
	_expect(copy != null and copy.text.strip_edges() != "", "%s must expose non-empty tag copy" % context)
	if copy != null:
		_expect(copy.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "%s tag copy must be vertically centered" % context)

func _assert_resource_cost(button: BaseButton, expected_kind: String, expected_amount: int, context: String) -> void:
	_expect(button != null, "%s button must exist" % context)
	if button == null:
		return
	var content := button.get_node_or_null("ResourceCostContent") as CenterContainer
	var cost_icon := button.find_child("CostIcon", true, false) as TextureRect
	var cost_value := button.find_child("CostValue", true, false) as Label
	var action := button.find_child("CostAction", true, false) as Label
	_expect(content != null and cost_icon != null and cost_value != null and action != null, "%s must render action + resource logo + amount" % context)
	_expect(str(button.get_meta("cost_resource_kind", "")) == expected_kind, "%s must declare %s as its real resource kind" % [context, expected_kind])
	_expect(int(button.get_meta("cost_resource_amount", -999)) == expected_amount, "%s must expose the exact cost amount %d" % [context, expected_amount])
	var expected_path := UiKit.currency_icon_path(expected_kind)
	_expect(str(button.get_meta("cost_resource_icon", "")) == expected_path, "%s metadata must route to the matching resource icon" % context)
	_expect(cost_icon != null and cost_icon.texture != null and cost_icon.texture.resource_path == expected_path, "%s must render the matching resource logo" % context)
	_expect(cost_value != null and cost_value.text == "%d" % expected_amount, "%s amount must be numeric and must not append a conflicting resource glyph" % context)
	_expect(action != null and action.text.strip_edges() != "", "%s must keep an explicit action label" % context)
	var legacy_label := button.get_node_or_null("ActionLabel") as Label
	if legacy_label != null:
		_expect(not legacy_label.visible, "%s must hide the old combined-text label when structured cost content is active" % context)

func _verify_fire_rate_profiles(economy: Dictionary) -> void:
	var ids := FireRateProfiles.profile_ids(economy)
	_expect(ids == ["control", "tier_a", "tier_b"], "fire-rate laboratory must expose the data-owned control/A/B order")
	_expect(str(economy.get("fire_rate_profiles", {}).get("default", "")) == "tier_b", "formal fire-rate profile must default to frozen Tier B")
	var authored_base := 1.0
	var character_mult := 0.96
	var chip_intrinsic := 0.18
	var chip_level := 35
	var pet_stat := 0.12
	var skill_level := 5
	var control_rate := authored_base * character_mult
	control_rate *= FireRateProfiles.chip_multiplier(economy, "control", chip_intrinsic, chip_level)
	control_rate *= FireRateProfiles.pet_multiplier(economy, "control", pet_stat)
	control_rate *= FireRateProfiles.salvo_multiplier(economy, "control", skill_level, 2.20)
	# This is the exact pre-profile reference cadence and projectile DPS.  The
	# control row must retain both values rather than merely remaining close.
	_expect(absf(control_rate - 3.740233728) <= 0.000001, "control profile must preserve the pre-A2 reference cadence exactly")
	var control_dps := 28.0 * 3.0 * control_rate
	_expect(absf(control_dps - 314.179633152) <= 0.000001, "control profile must preserve the pre-A2 reference projectile DPS exactly")
	for profile_id in ["tier_a", "tier_b"]:
		var raw_rate := authored_base * character_mult
		raw_rate *= FireRateProfiles.chip_multiplier(economy, profile_id, chip_intrinsic, chip_level)
		raw_rate *= FireRateProfiles.pet_multiplier(economy, profile_id, pet_stat)
		raw_rate *= FireRateProfiles.salvo_multiplier(economy, profile_id, skill_level, 2.20)
		var actual_rate := FireRateProfiles.capped_fire_rate(economy, profile_id, raw_rate, authored_base)
		var expected_cap := 1.8 if profile_id == "tier_a" else 2.2
		_expect(absf(actual_rate - expected_cap) <= 0.000001, "%s stacked cadence must land on its authored weapon-base cap" % profile_id)
		var compensation := FireRateProfiles.shot_damage_compensation(economy, profile_id, control_rate, actual_rate)
		var expected_dps := actual_rate * compensation
		_expect(absf(expected_dps - (actual_rate + control_rate) * 0.5) <= 0.000001, "%s must refund exactly 50%% of removed projectile DPS" % profile_id)
		var status_norm := FireRateProfiles.per_shot_status_normalization(control_rate, actual_rate)
		var normalized_triggers_per_second := actual_rate * status_norm
		var drift := absf(normalized_triggers_per_second / control_rate - 1.0)
		_expect(drift <= 0.05, "%s slow coverage must stay within 5%% of control after per-shot normalization" % profile_id)
		_expect(drift <= 0.05, "%s ignite uptime must stay within 5%% of control after per-shot normalization" % profile_id)

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
