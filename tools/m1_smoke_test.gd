extends SceneTree

class FakeRouter:
	extends Node

	var last_route := ""
	var last_payload := {}
	var last_started_level := ""
	var last_started_endless_level := ""
	var last_result := {}
	var run_context := {}

	func change_scene(route: String, payload := {}) -> void:
		last_route = route
		last_payload = payload

	func start_level(level_id: String) -> void:
		last_started_level = level_id

	func start_endless_level(level_id: String) -> void:
		last_started_endless_level = level_id

	func finish_level(result: Dictionary) -> void:
		last_result = result

class FakeDamageTarget:
	extends Node2D

	var hits := 0
	var total_damage := 0.0

	func take_damage(amount: float, _element := "physical") -> void:
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

func _initialize() -> void:
	await process_frame
	root.size = Vector2i(1080, 1920)
	var data_loader := root.get_node("/root/DataLoader")
	var save_manager := root.get_node("/root/SaveManager")
	var audio_manager := root.get_node("/root/AudioManager")
	var input_manager := root.get_node("/root/InputManager")
	data_loader.load_all()
	save_manager.load_game()
	var smoke_save_snapshot: Dictionary = save_manager.save_data.duplicate(true)
	_expect(InputMap.has_action("cycle_target_strategy"), "input map must expose target strategy cycling")
	_expect(save_manager.get_weapon_damage_multiplier("weapon_autocannon") >= 1.0, "weapon upgrade must expose damage multiplier")
	_expect(root.has_node("/root/SettingsManager"), "settings manager must be autoloaded")

	_expect(data_loader.get_table("levels").size() >= 99, "levels table must contain a launch campaign")
	_expect(data_loader.get_table("skills").size() >= 16, "skills table must contain a broad launch pool")
	_verify_zombie_mechanic_profiles(data_loader)
	_verify_ui_font()
	var starter_weapon: Dictionary = data_loader.get_row("weapons", "weapon_autocannon")
	_expect(data_loader.tr_key(starter_weapon.get("name_key", "")) == "自动机枪", "starter weapon must be displayed as 自动机枪, not a cannon")
	_expect(str(starter_weapon.get("turret", "")) == "res://assets/production/sprites/weapons/weapon_autocannon_turret.png", "starter weapon prototype must use the production machine-gun fallback asset")
	_expect(data_loader.level_display_name("level_002") == "002 城市突围", "level display names must hide internal ids")
	_expect(data_loader.level_display_name("level_011") == "011 废街突围", "all launch levels must have authored display names")
	var economy: Dictionary = data_loader.get_table("economy")
	var enemy_speed_mult := float(economy.get("ENEMY_SPEED_MULT", 1.0))
	_expect(absf(enemy_speed_mult - 0.41) <= 0.001, "enemy walking speed must be halved via ENEMY_SPEED_MULT without changing spawn intervals")
	var fire_rate_mult := float(economy.get("PLAYER_FIRE_RATE_MULT", 0.25))
	var shot_damage_mult := float(economy.get("PLAYER_SHOT_DAMAGE_MULT", 3.0))
	_expect(absf(fire_rate_mult - 0.25) <= 0.001, "initial player fire rate must use the retuned +50% paced value")
	_expect(absf(fire_rate_mult * shot_damage_mult - 0.75) <= 0.005, "fire-rate retune must preserve the intended shot damage product")
	_verify_progression_unlock_repair(save_manager)
	_verify_manual_aim_input(input_manager)
	_verify_targeting_frontline_priority()
	await _verify_turret_fire_gate(data_loader)
	_verify_skill_runtime_mods()
	_verify_ammo_element_rules(save_manager)
	await _verify_feedback_budget_guards()
	_verify_projectile_pierce_runtime()
	_verify_projectile_pierce_sweep_runtime()
	_verify_projectile_visual_profiles()
	await _verify_turret_muzzle_sockets(data_loader)
	await _verify_character_weapon_skins(data_loader, save_manager)
	await _verify_character_active_skill_controls(data_loader, save_manager)
	await _verify_bottom_skill_slot_level_merge(save_manager)
	await _verify_endless_mode(save_manager)
	await _verify_enemy_hit_flash_scope(data_loader)

	var main := _instance("res://main.tscn")
	root.add_child(main)
	await process_frame
	_expect(main.current_scene != null, "main must open initial menu")
	_expect(main.current_scene.find_child("HelpButton", true, false) != null, "menu must expose settings entry")
	main.current_scene._on_help_pressed()
	await process_frame
	_expect(main.current_scene.name == "Settings", "settings entry must open the dedicated settings page")
	var settings_vbox: Node = main.current_scene.get_node("Center/Panel/Margin/VBox")
	_expect(settings_vbox.has_node("SoundButton"), "settings must expose sound toggle")
	_expect(settings_vbox.has_node("QualityButton"), "settings must expose quality setting")
	_expect(settings_vbox.has_node("DataRow/BackupButton"), "settings must expose save backup")
	_expect(settings_vbox.has_node("DataRow/RestoreButton"), "settings must expose save restore")
	_expect(settings_vbox.has_node("ResetButton"), "settings must expose reset save entry")
	_expect(settings_vbox.has_node("AboutRow/PrivacyButton"), "settings must expose privacy entry")
	_expect(settings_vbox.has_node("AboutRow/SupportButton"), "settings must expose support entry")
	main.current_scene._show_info("privacy")
	_expect((settings_vbox.get_node("InfoBody") as Label).text.contains("隐私"), "privacy info must render")
	main.current_scene._show_info("support")
	_expect((settings_vbox.get_node("InfoBody") as Label).text.contains("支持"), "support info must render")
	main.current_scene._on_reset()
	_expect((settings_vbox.get_node("ResetButton") as Button).text.contains("确认"), "reset save must require confirmation")
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
	_expect(map_resource_row != null and map_resource_row.get_child_count() >= 4, "map resource bar must show the unified gold/star/xp/power chips")
	_expect(main.current_scene.find_child("Nav", true, false) != null, "map must expose collection navigation")
	var map_character_card: Node = main.current_scene.find_child("charactersNavCard", true, false)
	_expect(map_character_card != null, "map must expose the character feature card")
	var map_character_bust := map_character_card.find_child("BustImage", true, false) as TextureRect
	_expect(map_character_bust != null and map_character_bust.texture != null, "map character feature card must use a bust portrait")
	_expect(str(map_character_bust.texture.resource_path).ends_with("_portrait_frameless.png"), "map character feature card must use frameless 正脸立绘")
	var level_list: Node = main.current_scene.find_child("LevelList", true, false)
	_expect(level_list != null, "map level list must be scrollable")
	_expect(level_list.get_child_count() >= 99, "map must render the launch campaign")
	_expect(level_list.get_child(0) is TextureButton, "map levels must use styled texture buttons")
	_expect((level_list.get_child(0).get_child(0) as Label).text == "001 城市缺口", "map must show three-digit level number and display name")
	_expect((level_list.get_child(10).get_child(0) as Label).text == "011 废街突围", "map must show authored names beyond the first ten levels")
	main.change_scene("collection", {"mode": "characters"})
	await process_frame
	_expect(main.current_scene.name == "Collection", "main must route to character collection")
	var character_item: Node = main.current_scene.find_child("ItemList", true, false).get_child(0)
	_expect(character_item is TextureButton, "character collection rows must use styled texture buttons")
	_expect((character_item as Control).clip_contents, "character collection rows must clip portrait content")
	_expect((character_item as Control).custom_minimum_size.y >= 128.0, "character collection rows must be tall enough for portraits")
	_expect(character_item.has_node("Icon"), "character collection rows must render a bounded portrait")
	var character_icon := character_item.get_node("Icon") as TextureRect
	_expect(character_icon != null, "character collection portrait must be a TextureRect")
	_expect(character_icon.size.x <= 120.0 and character_icon.size.y <= 128.0, "character collection portrait must stay inside its row, got %s" % str(character_icon.size))
	_expect(character_icon.clip_contents, "character collection portrait must crop upper-body art")
	var character_bust := character_icon.get_node_or_null("BustImage") as TextureRect
	_expect(character_bust != null and character_bust.texture != null, "character collection portrait must render a bust image")
	_expect(str(character_bust.texture.resource_path).ends_with("_portrait_frameless.png"), "character collection portrait must use frameless 正脸立绘")
	_expect(character_bust.size.y > character_icon.size.y, "character collection portrait must be zoomed and cropped")
	_expect(character_bust.expand_mode == TextureRect.EXPAND_IGNORE_SIZE, "character collection portrait must use its assigned rect instead of the texture's natural size")
	character_item.emit_signal("pressed")
	await process_frame
	_expect(main.current_scene.has_node("CharacterDetail"), "character row click must open character detail")
	var character_detail: Node = main.current_scene.get_node("CharacterDetail")
	var character_close := character_detail.find_child("CloseButton", true, false) as Button
	_expect(character_close != null, "character detail top close must be a compact button")
	_expect(character_close.text == "×", "character detail top close must use an icon-only x")
	_expect(character_close.custom_minimum_size.x <= 64.0 and character_close.custom_minimum_size.y <= 64.0, "character detail top close must not use a large text button")
	main.current_scene._close_character_detail()
	await process_frame
	var collection_back := main.current_scene.find_child("BackButton", true, false) as TextureButton
	_expect(collection_back != null, "collection must expose a context-aware back button")
	_expect((collection_back.get_node("Label") as Label).text == "返回地图", "collection opened from map must return to map")
	collection_back.emit_signal("pressed")
	await process_frame
	_expect(main.current_scene.name == "Map", "collection opened from map must route back to map")
	main.change_scene("collection", {"mode": "skills"})
	await process_frame
	_expect(main.current_scene.name == "Collection", "main must route to skill collection")
	var skill_list: Node = main.current_scene.find_child("ItemList", true, false)
	_expect(skill_list != null and skill_list.get_child_count() >= 16, "skill collection must render the skill codex")
	var skill_item: Node = skill_list.get_child(0)
	_expect(skill_item is TextureButton, "skill collection rows must use clickable texture buttons")
	_expect(skill_item.has_node("SkillCard"), "skill collection rows must use one full-width visual card")
	_expect(not skill_item.has_node("Frame"), "skill collection rows must not render the old nested inner frame")
	var skill_card := skill_item.get_node("SkillCard") as PanelContainer
	_expect(skill_card != null and skill_card.size.x >= 720.0, "skill collection card must span the row without a disconnected right panel")
	_expect(skill_item.has_node("MaxLevelValue"), "skill collection card must show max level in the right meta area")
	skill_item.emit_signal("pressed")
	await process_frame
	_expect(main.current_scene.has_node("ItemDetail"), "skill collection row click must open skill detail")
	var skill_detail: Node = main.current_scene.get_node("ItemDetail")
	var skill_close := skill_detail.find_child("CloseButton", true, false) as Button
	_expect(skill_close != null, "skill detail top close must be a compact button")
	_expect(skill_close.text == "×", "skill detail top close must use an icon-only x")
	_expect(skill_close.custom_minimum_size.x <= 64.0 and skill_close.custom_minimum_size.y <= 64.0, "skill detail top close must not use a large text button")
	skill_close.emit_signal("pressed")
	await process_frame
	_expect(not main.current_scene.has_node("ItemDetail"), "skill detail compact close must dismiss the modal")
	collection_back = main.current_scene.find_child("BackButton", true, false) as TextureButton
	collection_back.emit_signal("pressed")
	await process_frame
	_expect(main.current_scene.name == "Map", "skill collection opened from map must route back to map")
	main.change_scene("collection", {"mode": "weapons"})
	await process_frame
	_expect(main.current_scene.name == "Collection", "main must route to collection")
	_expect(main.current_scene.find_child("ItemList", true, false) != null, "collection item list must be scrollable")
	var weapon_list: Node = main.current_scene.find_child("ItemList", true, false)
	_expect(weapon_list.get_child_count() >= 8, "collection must render weapon pool")
	var first_weapon: TextureButton = null
	for weapon_child in weapon_list.get_children():
		if weapon_child is TextureButton and not (weapon_child as TextureButton).disabled:
			first_weapon = weapon_child
			break
	_expect(first_weapon != null, "collection must expose at least one unlocked weapon")
	_expect(not first_weapon.has_node("UpgradeButton"), "collection rows must keep actions inside detail")
	first_weapon.emit_signal("pressed")
	await process_frame
	_expect(main.current_scene.has_node("ItemDetail"), "collection row click must open item detail")
	var item_detail: Node = main.current_scene.get_node("ItemDetail")
	var item_close := item_detail.find_child("CloseButton", true, false) as Button
	_expect(item_close != null, "item detail top close must be a compact button")
	_expect(item_close.text == "×", "item detail top close must use an icon-only x")
	_expect(item_close.custom_minimum_size.x <= 64.0 and item_close.custom_minimum_size.y <= 64.0, "item detail top close must not use a large text button")
	_expect(item_detail.find_child("EquipButton", true, false) != null, "item detail must expose equip action")
	_expect(item_detail.find_child("UpgradeButton", true, false) != null, "item detail must expose upgrade action")
	main.current_scene._close_character_detail()
	await process_frame
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
	_expect(main.current_scene.get_node("SignatureCards").get_child_count() >= 3, "loadout must show passive and two signature previews")
	_expect(main.current_scene.get_node("Summary").text.contains("001 城市缺口"), "loadout must show player-facing level name")
	_expect(not main.current_scene.get_node("Summary").text.contains("level_001"), "loadout must not expose internal level id")
	_expect(main.current_scene.get_node("Summary").text.contains("五波") or main.current_scene.get_node("Objective").text.contains("五波"), "loadout copy must mention five-wave pacing")
	_expect(main.current_scene.get_node("EquipNav").get_child_count() >= 5, "loadout must link to all equipment categories")
	var character_panel: Node = main.current_scene.find_child("CharacterPanel", true, false)
	_expect(character_panel != null and character_panel.has_node("OpenHitArea"), "loadout character panel must open collection as a layer")
	(character_panel.get_node("OpenHitArea") as Button).emit_signal("pressed")
	await process_frame
	_expect(main.current_scene.name == "Collection", "loadout character panel must route to collection")
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
		var routed_hp_floor: float = float(main.current_scene.level.get("base_hp_ref", 50)) * float(main.current_scene.level.get("difficulty_coef", 1.0)) * 0.55
		_expect(float(routed_enemy.max_hp) >= routed_hp_floor, "main-routed battle enemy hp must use requested level; got %.1f expected floor %.1f" % [float(routed_enemy.max_hp), routed_hp_floor])
	save_manager.save_data = smoke_save_snapshot.duplicate(true)
	main.queue_free()
	await process_frame

	var router := FakeRouter.new()
	root.add_child(router)
	save_manager.save_data = _battle_smoke_loadout(smoke_save_snapshot)
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
		_expect(bool(battle.character_weapon_combo_active), "battle must use fused selected character/weapon art for %s" % battle.level_id)
		_expect(battle.character_weapon_sprite == null, "fused battle art must not also mount a floating weapon sprite for %s" % battle.level_id)
		_expect(not bool(battle.turret.visible), "legacy turret sprite must stay hidden while logic is reused")
		var fused_texture := (battle.character_sprite as Sprite2D).texture
		_expect(fused_texture != null, "fused character/weapon texture must exist for %s" % battle.level_id)
		var fused_texture_path := str(fused_texture.resource_path)
		if fused_texture_path != "":
			_expect(fused_texture_path.contains("/character_weapon_combos/"), "battle character must load fused art from character_weapon_combos for %s" % battle.level_id)
		_expect(battle.character_idle_frames.size() >= 4, "fused character/weapon art must provide idle frames for %s" % battle.level_id)
		_expect(battle.character_attack_left_frames.size() >= 4, "fused character/weapon art must provide left-aim attack frames for %s" % battle.level_id)
		_expect(battle.character_attack_frames.size() >= 4, "fused character/weapon art must provide attack frames for %s" % battle.level_id)
		_expect(battle.character_attack_right_frames.size() >= 4, "fused character/weapon art must provide right-aim attack frames for %s" % battle.level_id)
		_expect(battle.character_hurt_frames.size() >= 3, "fused character/weapon art must provide hurt frames for %s" % battle.level_id)
		var expected_fused_origin: Vector2 = battle.character_rig.global_position + battle._character_combo_muzzle_for_aim()
		_expect(battle._weapon_fire_origin().distance_to(expected_fused_origin) <= 1.0, "projectiles must originate from the fused character/weapon muzzle")
		battle._set_character_combo_aim_from_direction(Vector2.UP)
		var expected_center_origin: Vector2 = battle.character_rig.global_position + battle.character_weapon_combo_muzzle
		battle._set_character_combo_aim_from_direction(Vector2(-0.75, -0.66).normalized())
		var left_origin: Vector2 = battle._weapon_fire_origin()
		battle._set_character_combo_aim_from_direction(Vector2(0.75, -0.66).normalized())
		var right_origin: Vector2 = battle._weapon_fire_origin()
		_expect(left_origin.x < expected_center_origin.x - 20.0, "left-aim fused muzzle must move left for %s" % battle.level_id)
		_expect(right_origin.x > expected_center_origin.x + 20.0, "right-aim fused muzzle must move right for %s" % battle.level_id)
		_expect(float(battle.turret.damage_mult) > 1.0, "turret must receive character and chip damage multipliers")
		_expect(battle.base_hp_max > int(battle.level.get("base_hp_ref", 100)), "battle must receive armor and character survivability")
		_expect(not battle.has_node("Hud/StrategyButton"), "battle HUD must not expose the old target strategy button")
		_expect(battle.has_node("Hud/SkillSlots"), "battle must expose skill slots")
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
			_verify_manual_aim_battle_priority(battle)
			_verify_multi_shot_targeting(battle)
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
			var expected_runtime_hp_floor := float(battle.level.get("base_hp_ref", 50)) * float(battle.level.get("difficulty_coef", 1.0)) * 0.55
			_expect(float(first_enemy.max_hp) >= expected_runtime_hp_floor, "enemy hp must scale with base_hp_ref; got %.1f expected floor %.1f on %s" % [float(first_enemy.max_hp), expected_runtime_hp_floor, battle.level_id])
			if battle.level_id == "level_001":
				battle._show_card_offer()
				await process_frame
				_verify_card_offer_full_pause(battle)
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
				_expect(first_card_icon.size.x <= 128.0 and first_card_icon.size.y <= 128.0, "card icon must stay bounded, got %s" % str(first_card_icon.size))
				first_card.emit_signal("mouse_entered")
				await process_frame
				_expect(battle.get_node("Hud/SkillHintOverlay").visible, "card hover must show an in-game skill explanation")
				first_card.emit_signal("mouse_exited")
				await process_frame
				_expect(not battle.get_node("Hud/SkillHintOverlay").visible, "card hover exit must hide the skill explanation")
				battle._show_card_detail("skill_split_shot")
				await process_frame
				_expect(battle.get_node("Hud/CardPanel/DetailOverlay").visible, "card long-press detail overlay must open")
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
	result.setup(router, {"level_id": "level_001", "victory": true, "stars": 3, "gold": 120, "xp": 12})
	await process_frame
	_expect(result.get_node("Content/HeroCard/HeroBox/LevelName").text.contains("001 城市缺口"), "result must show player-facing level name")
	_expect(not result.get_node("Content/HeroCard/HeroBox/LevelName").text.contains("level_001"), "result must not expose internal level id")
	_expect(result.get_node("Content/RewardRow/GoldCard/GoldBox/GoldVBox/GoldValue").text.contains("120"), "result gold card must show earned gold")
	_expect(result.get_node("Content/RewardRow/XpCard/XpBox/XpVBox/XpValue").text.contains("12"), "result xp card must show earned xp")
	_expect(result.get_node("Content/HintCard/HintBox/Hint").text != "", "result must show next action hint")
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
	_expect(battle.get_node("Hud/CardPanel").process_mode == Node.PROCESS_MODE_ALWAYS, "card panel must remain interactive during card offer pause")
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

func _verify_ui_font() -> void:
	var font_path := "res://assets/production/fonts/font_main.ttf"
	_expect(str(ProjectSettings.get_setting("gui/theme/custom_font")) == font_path, "project must use the production CJK font as the global UI font")
	var font := FontFile.new()
	var err := font.load_dynamic_font(font_path)
	_expect(err == OK, "production UI font must load")
	_expect(font.has_char("鉴".unicode_at(0)), "production UI font must include the glyph for 鉴")

func _verify_manual_aim_input(input_manager: Node) -> void:
	var started := {"count": 0, "pos": Vector2.ZERO}
	var aimed := {"count": 0, "pos": Vector2.ZERO}
	var released := {"count": 0, "pos": Vector2.ZERO}
	var on_started := func(pos: Vector2) -> void:
		started["count"] = int(started.get("count", 0)) + 1
		started["pos"] = pos
	var on_aimed := func(pos: Vector2) -> void:
		aimed["count"] = int(aimed.get("count", 0)) + 1
		aimed["pos"] = pos
	var on_released := func(pos: Vector2) -> void:
		released["count"] = int(released.get("count", 0)) + 1
		released["pos"] = pos
	input_manager.manual_aim_started.connect(on_started)
	input_manager.aim_point.connect(on_aimed)
	input_manager.manual_aim_released.connect(on_released)

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

	input_manager._cancel_aim_press()
	input_manager.manual_aim_started.disconnect(on_started)
	input_manager.aim_point.disconnect(on_aimed)
	input_manager.manual_aim_released.disconnect(on_released)

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

	battle._on_manual_aim_released(dragged_point)
	battle.manual_aim_until = 0.0
	battle._update_auto_target()
	_expect(battle.turret.target_point.distance_to(dragged_point) > 1.0, "auto aim must resume after manual aim release grace")
	battle.get_node("EnemyLayer").remove_child(auto_target)
	auto_target.free()

func _verify_xp_bar_single_track(battle: Node) -> void:
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
	var pause_panel := battle.get_node("Hud/PauseOverlay/Panel") as Control
	_expect(pause_panel != null and pause_panel.clip_contents, "pause panel must clip its content")
	_expect(pause_panel.has_node("PauseContent"), "pause panel must render structured content instead of raw text only")
	var legacy_summary := battle.get_node("Hud/PauseOverlay/Panel/BuildSummary") as Label
	_expect(legacy_summary != null and not legacy_summary.visible, "pause legacy summary text must be hidden behind designed cards")
	for button_path in ["ResumeButton", "RestartButton", "MapButton"]:
		var button := pause_panel.get_node(button_path) as Control
		var rect := Rect2(button.position, button.size)
		_expect(rect.position.y >= 0.0 and rect.end.y <= pause_panel.size.y, "pause %s must stay inside the panel bounds" % button_path)
		_expect(button.has_node("IconPlate") and button.has_node("ActionTitle") and button.has_node("ActionSub"), "pause %s must use icon plus title/subtitle styling" % button_path)
	battle._physics_process(1.0)
	_expect(first_enemy.global_position.distance_to(enemy_pos) <= 0.1, "pause must freeze enemy movement even though Battle processes always")
	_expect(absf(float(battle.spawn_timer) - spawn_timer_before) <= 0.001, "pause must not advance spawn timer")
	_expect(int(battle.pending_spawns.size()) == pending_before, "pause must not consume pending spawns")
	_expect(absf(float(battle.pet_cooldown) - pet_cooldown_before) <= 0.001, "pause must not advance pet attack cooldown")
	_expect(battle.get_node("ProjectileLayer").get_child_count() == projectiles_before, "pause must not spawn pet or weapon projectiles")
	_expect(not bool(battle.turret.get("fire_enabled")), "pause must disable turret firing permission")
	battle._on_resume_pressed()
	_expect(not bool(battle.paused) and not battle.get_tree().paused, "resume button must restore battle processing")

func _verify_runtime_skill_hints(battle: Node) -> void:
	var button := battle.get_node("Hud/CharacterSkillButton") as BaseButton
	button.emit_signal("mouse_entered")
	await process_frame
	_expect(battle.get_node("Hud/SkillHintOverlay").visible, "active skill hover must show a readable skill explanation")
	button.emit_signal("mouse_exited")
	await process_frame
	_expect(not battle.get_node("Hud/SkillHintOverlay").visible, "active skill hover exit must hide the explanation")

	if battle.skills.level("skill_split_shot") <= 0:
		_expect(battle.skills.add_skill("skill_split_shot"), "skill hint regression must seed a bottom skill slot")
	battle._update_skill_slots()
	await process_frame
	var slots := battle.get_node("Hud/SkillSlots")
	_expect(slots.has_node("skill_split_shot"), "seeded skill must render in the bottom skill shelf")
	var slot := slots.get_node("skill_split_shot")
	slot.emit_signal("mouse_entered")
	await process_frame
	_expect(battle.get_node("Hud/SkillHintOverlay").visible, "bottom skill hover must show a readable skill explanation")
	slot.emit_signal("mouse_exited")
	await process_frame
	_expect(not battle.get_node("Hud/SkillHintOverlay").visible, "bottom skill hover exit must hide the explanation")

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

func _verify_skill_runtime_mods() -> void:
	var runtime := SkillRuntime.new()
	runtime.add_skill("skill_multishot")
	runtime.add_skill("skill_salvo")
	var mods: Dictionary = runtime.projectile_mods()
	_expect(int(mods.get("extra_projectiles", 0)) == 1, "multishot alone must add projectile lanes")
	_expect(runtime.fire_rate_multiplier() > 1.2, "salvo must now increase fire rate instead of duplicating multishot")

func _verify_ammo_element_rules(save_manager: Node) -> void:
	var runtime := SkillRuntime.new()
	_expect(runtime.add_skill("skill_tesla"), "tesla ammo must be addable")
	_expect(runtime.projectile_element("physical") == "lightning", "physical weapons can be converted to tesla ammo")
	_expect(runtime.projectile_element("fire") == "fire", "native elemental weapons must keep their weapon element")
	_expect(runtime.add_skill("skill_venom"), "venom ammo must be addable")
	_expect(runtime.level("skill_tesla") == 0, "tesla and venom ammo must be mutually exclusive")
	_expect(runtime.level("skill_venom") == 1, "new ammo module must replace the previous ammo module")
	_expect(runtime.projectile_element("physical") == "poison", "active ammo module must drive physical weapon projectile element")
	_expect(runtime.projectile_element("fire") == "fire", "plasma/fire weapons must not be overwritten by venom or tesla ammo")

	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var test_save: Dictionary = original_save.duplicate(true)
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
	test_save["equipment"] = equipment
	save_manager.save_data = test_save
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
	damage_layer.queue_free()

	var fake_battle := Node2D.new()
	root.add_child(fake_battle)
	var gold_label := Label.new()
	var gold_icon := TextureRect.new()
	fake_battle.add_child(gold_label)
	fake_battle.add_child(gold_icon)
	var gold_fx := preload("res://gameplay/hud/gold_fly.gd").new()
	root.add_child(gold_fx)
	gold_fx.bind(fake_battle, gold_label, gold_icon)
	for i in range(24):
		gold_fx.fly_to_hud(Vector2(120 + i, 800), 10)
	_expect(fake_battle.get_child_count() <= 12, "gold reward flash must cap active coin/ring nodes")
	gold_fx.queue_free()
	fake_battle.queue_free()

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
	var directions: Array[Vector2] = battle._primary_shot_directions(origin, Vector2.UP, 3, deg_to_rad(18.0))
	_expect(directions.size() == 3, "multi-shot must return one direction per projectile")
	for direction in directions:
		_expect(direction.y < -0.45, "multi-shot lanes must point into the battlefield")
	# 固定夹角扇形：相邻弹道之间夹角相等且>0（对称扇形，不各自锁敌 → 不 imba）
	var ang_a := absf(directions[0].angle_to(directions[1]))
	var ang_b := absf(directions[1].angle_to(directions[2]))
	_expect(ang_a > 0.02 and ang_b > 0.02, "multi-shot must spread into a fan (distinct lanes)")
	_expect(absf(ang_a - ang_b) < 0.03, "multi-shot fan must use a FIXED equal angle between adjacent lanes")
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

func _verify_projectile_visual_profiles() -> void:
	var expected := {
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
		if profile == "rail":
			_expect(sprite.scale.x > sprite.scale.y * 2.2, "rail projectile must read as a long lance")
		elif profile == "scatter":
			_expect(sprite.scale.x < 0.32 and sprite.scale.y < 0.32, "scatter pellets must stay small")
		elif profile == "plasma":
			_expect(sprite.scale.x >= 0.36 and sprite.modulate.r > 0.8 and sprite.modulate.b > 0.8, "plasma projectile must read as a large purple energy core")
		projectile.queue_free()

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
			_expect(bool(battle.character_weapon_combo_active), "%s + %s must use fused character/weapon battle art" % [character_key, weapon_key])
			_expect(battle.character_weapon_sprite == null, "%s + %s must not also mount a floating gun sprite" % [character_key, weapon_key])
			var combo_texture := (battle.character_sprite as Sprite2D).texture
			_expect(combo_texture != null, "fused combo texture must exist for %s + %s" % [character_key, weapon_key])
			var combo_texture_path := str(combo_texture.resource_path)
			if combo_texture_path != "":
				_expect(combo_texture_path.contains("/character_weapon_combos/%s/" % character_asset_id), "fused combo texture must be loaded from %s; got %s" % [character_asset_id, combo_texture_path])
			_expect(battle.character_idle_frames.size() >= 4, "%s + %s must provide idle fused frames" % [character_key, weapon_key])
			_expect(battle.character_attack_left_frames.size() >= 4, "%s + %s must provide left-aim attack fused frames" % [character_key, weapon_key])
			_expect(battle.character_attack_frames.size() >= 4, "%s + %s must provide attack fused frames" % [character_key, weapon_key])
			_expect(battle.character_attack_right_frames.size() >= 4, "%s + %s must provide right-aim attack fused frames" % [character_key, weapon_key])
			_expect(battle.character_hurt_frames.size() >= 3, "%s + %s must provide hurt fused frames" % [character_key, weapon_key])
			var expected_combo_origin: Vector2 = battle.character_rig.global_position + battle._character_combo_muzzle_for_aim()
			_expect(battle._weapon_fire_origin().distance_to(expected_combo_origin) <= 1.0, "%s + %s projectile origin must use fused muzzle" % [character_key, weapon_key])
			battle._set_character_combo_aim_from_direction(Vector2.UP)
			var expected_combo_center_origin: Vector2 = battle.character_rig.global_position + battle.character_weapon_combo_muzzle
			battle._set_character_combo_aim_from_direction(Vector2(-0.75, -0.66).normalized())
			var combo_left_origin: Vector2 = battle._weapon_fire_origin()
			battle._set_character_combo_aim_from_direction(Vector2(0.75, -0.66).normalized())
			var combo_right_origin: Vector2 = battle._weapon_fire_origin()
			_expect(combo_left_origin.x < expected_combo_center_origin.x - 20.0, "%s + %s left-aim muzzle must move left" % [character_key, weapon_key])
			_expect(combo_right_origin.x > expected_combo_center_origin.x + 20.0, "%s + %s right-aim muzzle must move right" % [character_key, weapon_key])
			battle.queue_free()
			await process_frame
	save_manager.save_data = original_save
	router.queue_free()
	await process_frame

func _verify_character_active_skill_controls(data_loader: Node, save_manager: Node) -> void:
	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var router := FakeRouter.new()
	root.add_child(router)
	var input_manager := root.get_node("/root/InputManager")
	var character_table: Dictionary = data_loader.get_table("characters")
	for character_id in character_table.keys():
		var character_key := str(character_id)
		var test_save: Dictionary = _battle_smoke_loadout(original_save)
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
	_expect(slots is HBoxContainer, "battle skill slots must use the bottom horizontal shelf")
	_expect(slots.get_child_count() == 1, "tesla weapon seed must create exactly one skill slot")
	_expect(slots.has_node("skill_tesla"), "tesla weapon seed must use the tesla skill slot")
	var slot := slots.get_node("skill_tesla")
	_expect(slot.has_node("HBox/LevelBadge"), "tesla slot must expose a level badge")
	_expect((slot.get_node("HBox/LevelBadge") as Label).text == "等级1", "tesla seed must start at level 1")
	_expect(battle.skills.add_skill("skill_tesla"), "adding tesla once must upgrade the existing slot")
	battle._update_skill_slots()
	await process_frame
	_expect(slots.get_child_count() == 1, "upgrading tesla must not add a duplicate slot")
	_expect((slot.get_node("HBox/LevelBadge") as Label).text == "等级2", "upgrading tesla must display level 2 on the existing slot")
	battle.queue_free()
	save_manager.save_data = original_save
	router.queue_free()
	await process_frame

func _verify_endless_mode(save_manager: Node) -> void:
	var original_save: Dictionary = save_manager.save_data.duplicate(true)
	var router := FakeRouter.new()
	root.add_child(router)
	var battle := _instance("res://gameplay/battle/battle.tscn")
	battle.setup(router, {"level_id": "level_001", "endless": true})
	root.add_child(battle)
	await process_frame
	await physics_frame
	_expect(battle.is_endless_mode, "battle must enter endless mode when payload requests it")
	_expect(battle.endless_loop == 0 and is_equal_approx(battle.endless_difficulty_mult, 1.0), "endless mode must start at loop 0 with no HP escalation")
	battle.wave_index = 1
	var before: Node = battle._spawn_enemy_instance("zombie_shambler", Vector2(540, 190), false)
	var hp_before: float = before.max_hp
	before.queue_free()
	battle._advance_endless_loop()
	_expect(battle.endless_loop == 1, "first loop completion must advance endless_loop to 1")
	# _advance_endless_loop 把 wave_index 归零后立刻调用 _start_next_wave()(内部会 +1)，
	# 所以函数返回时 wave_index==1，代表"重新从第一波开始播"而不是停在0。
	_expect(battle.wave_index == 1, "advancing an endless loop must restart from the first wave")
	_expect(battle.endless_difficulty_mult > 1.0, "advancing an endless loop must raise the HP escalation multiplier")
	battle.wave_index = 1
	var after: Node = battle._spawn_enemy_instance("zombie_shambler", Vector2(540, 190), false)
	var hp_after: float = after.max_hp
	after.queue_free()
	_expect(hp_after > hp_before * 1.1, "endless loop escalation must meaningfully raise spawned enemy HP, got %.1f -> %.1f" % [hp_before, hp_after])
	battle._advance_endless_loop()
	_expect(battle.endless_loop == 2, "second loop completion must advance endless_loop to 2")
	var mult_loop1: float = 1.0 + float(battle.ENDLESS_LOOP_HP_GROWTH)
	var mult_loop2: float = 1.0 + float(battle.ENDLESS_LOOP_HP_GROWTH) * 2.0
	_expect(battle.endless_difficulty_mult > mult_loop1 - 0.001 and battle.endless_difficulty_mult < mult_loop2 + 0.001, "endless HP multiplier must escalate per loop as designed")
	battle.base_hp = 0
	battle._finish(false)
	_expect(bool(router.last_result.get("endless", false)), "endless defeat must report an endless result to the router")
	_expect(int(router.last_result.get("endless_loop", -1)) == 2, "endless defeat result must report the loop reached")
	battle.queue_free()
	save_manager.save_data = original_save
	router.queue_free()
	await process_frame

	# apply_endless_result: 奖励发放 + 星星按轮数封顶 + 不写 levels_progress/unlocks。
	var pre_save: Dictionary = save_manager.save_data.duplicate(true)
	var pre_gold: int = save_manager.get_player_gold()
	var pre_star: int = save_manager.get_player_star()
	save_manager.apply_endless_result({"level_id": "level_001", "endless_loop": 9, "gold": 500, "xp": 300}, false)
	_expect(save_manager.get_player_gold() == pre_gold + 500, "endless result must credit gold")
	_expect(save_manager.get_player_star() == pre_star + mini(save_manager.ENDLESS_STAR_CAP, 9 / save_manager.ENDLESS_STAR_PER_LOOPS), "endless result must award capped star count from loops survived")
	_expect(save_manager.get_endless_best_loops() == 9, "endless result must track the best loop count reached")
	_expect(not save_manager.save_data.get("levels_progress", {}).has("level_001") or int(pre_save.get("levels_progress", {}).get("level_001", 0)) == int(save_manager.save_data.get("levels_progress", {}).get("level_001", 0)), "endless result must not alter normal level star progress")
	save_manager.save_data = original_save

func _verify_enemy_hit_flash_scope(data_loader: Node) -> void:
	var boss_enemy: Node = _instance("res://gameplay/enemy/enemy.tscn")
	root.add_child(boss_enemy)
	var boss_row: Dictionary = data_loader.get_row("bosses", "boss_tank_titan").duplicate(true)
	boss_row["mechanic"] = "basic"
	boss_row["immune"] = []
	boss_row["weakness"] = "none"
	boss_row["resist"] = "none"
	boss_enemy.call("setup", boss_row, 1.0, true)
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
	var kind_to_vfx := {
		"runner_dash": "vfx_threat_warning.png",
		"leap_strike": "vfx_threat_warning.png",
		"charge": "vfx_threat_warning.png",
		"toxic_cloud": "vfx_poison_cloud.png",
		"regen": "vfx_poison_cloud.png",
		"mutate": "vfx_boss_phase.png",
		"enrage": "vfx_explosion_fire.png",
		"buff_aura": "vfx_boss_phase.png",
		"shield_aura": "vfx_crit.png",
		"ward": "vfx_crit.png",
		"juggernaut": "vfx_crit.png"
	}
	for kind in kind_to_vfx.keys():
		var path := str(battle._attack_vfx_path(kind))
		_expect(path.ends_with(kind_to_vfx[kind]), "enemy mechanic %s must use a distinct vfx, got %s" % [kind, path])
		_expect(battle._attack_color_for_mechanic(kind).a > 0.7, "enemy mechanic %s must define a visible vfx color" % kind)
	var target := FakeAimTarget.new()
	target.breach_damage = 20
	battle.breach_damage_mult = 0.5
	_expect(battle._enemy_skill_damage(target, 0.35, 2.0) == 4, "enemy skill damage must respect breach damage mitigation")

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

	save_manager.save_data = save_manager._default_save()
	save_manager.apply_level_result({"level_id": "level_002", "victory": false, "stars": 0, "next_level": "level_003", "gold": 0, "xp": 0}, false)
	_expect(not save_manager.is_level_unlocked("level_003"), "defeat result must not unlock level_003")
	save_manager.save_data = original_save

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
