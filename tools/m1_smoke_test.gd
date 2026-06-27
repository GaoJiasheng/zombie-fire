extends SceneTree

class FakeRouter:
	extends Node

	var last_route := ""
	var last_payload := {}
	var last_started_level := ""
	var last_result := {}
	var run_context := {}

	func change_scene(route: String, payload := {}) -> void:
		last_route = route
		last_payload = payload

	func start_level(level_id: String) -> void:
		last_started_level = level_id

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
	var data_loader := root.get_node("/root/DataLoader")
	var save_manager := root.get_node("/root/SaveManager")
	var audio_manager := root.get_node("/root/AudioManager")
	data_loader.load_all()
	save_manager.load_game()
	var smoke_save_snapshot: Dictionary = save_manager.save_data.duplicate(true)
	_expect(InputMap.has_action("cycle_target_strategy"), "input map must expose target strategy cycling")
	_expect(save_manager.get_weapon_damage_multiplier("weapon_autocannon") >= 1.0, "weapon upgrade must expose damage multiplier")
	_expect(root.has_node("/root/SettingsManager"), "settings manager must be autoloaded")

	_expect(data_loader.get_table("levels").size() >= 99, "levels table must contain a launch campaign")
	_expect(data_loader.get_table("skills").size() >= 16, "skills table must contain a broad launch pool")
	_expect(data_loader.level_display_name("level_002") == "002 城市突围", "level display names must hide internal ids")
	_expect(data_loader.level_display_name("level_011") == "011 废街突围", "all launch levels must have authored display names")
	var economy: Dictionary = data_loader.get_table("economy")
	var fire_rate_mult := float(economy.get("PLAYER_FIRE_RATE_MULT", 0.25))
	var shot_damage_mult := float(economy.get("PLAYER_SHOT_DAMAGE_MULT", 3.0))
	_expect(absf(fire_rate_mult - 0.25) <= 0.001, "initial player fire rate must use the retuned +50% paced value")
	_expect(absf(fire_rate_mult * shot_damage_mult - 0.75) <= 0.005, "fire-rate retune must preserve the intended shot damage product")
	_verify_progression_unlock_repair(save_manager)
	_verify_skill_runtime_mods()
	_verify_ammo_element_rules(save_manager)
	await _verify_feedback_budget_guards()
	_verify_projectile_pierce_runtime()
	_verify_projectile_pierce_sweep_runtime()
	await _verify_turret_muzzle_sockets(data_loader)
	await _verify_character_weapon_skins(data_loader, save_manager)
	await _verify_bottom_skill_slot_level_merge(save_manager)

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
	_expect(main.current_scene.find_child("Nav", true, false) != null, "map must expose collection navigation")
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
	_expect(character_icon.size.x <= 90.0 and character_icon.size.y <= 90.0, "character collection portrait must stay inside its row, got %s" % str(character_icon.size))
	_expect(character_icon.expand_mode == TextureRect.EXPAND_IGNORE_SIZE, "character collection portrait must use its assigned rect instead of the texture's natural size")
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
		_expect(battle.character_weapon_sprite != null, "battle must mount the selected weapon on the character for %s" % battle.level_id)
		_expect(not bool(battle.turret.visible), "legacy turret sprite must stay hidden while logic is reused")
		_expect((battle.character_weapon_sprite as Sprite2D).texture != null, "character-mounted weapon must render a visible weapon skin")
		_expect(battle._weapon_fire_origin().distance_to(battle.turret.global_position) > 24.0, "projectiles must originate from the character weapon muzzle, not the hidden turret center")
		_expect(float(battle.turret.damage_mult) > 1.0, "turret must receive character and chip damage multipliers")
		_expect(battle.base_hp_max > int(battle.level.get("base_hp_ref", 100)), "battle must receive armor and character survivability")
		_expect(battle.has_node("Hud/StrategyButton"), "battle must expose target strategy button")
		_expect(battle.has_node("Hud/SkillSlots"), "battle must expose skill slots")
		_expect(battle.has_node("Hud/CharacterSkillButton"), "battle must expose character active skill button")
		_expect(str(battle.character_active_id) != "", "battle must configure selected character active skill")
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
			await _verify_base_attack_runtime(battle)
			_verify_multi_shot_targeting(battle)
			var cd_before := float(battle.character_active_cd)
			battle._on_character_skill_pressed()
			# Only vanguard/frost skills are guaranteed to cast; volt/blaze may
			# bail if no valid target. Check cooldown only for guaranteed casts.
			var guaranteed_cast := ["sig_vanguard_railvolley", "sig_frost_glacier"].has(str(battle.character_active_id))
			if guaranteed_cast:
				_expect(float(battle.character_active_cd) > cd_before, "character active skill must trigger and enter cooldown")
		if battle.get_node("EnemyLayer").get_child_count() > 0:
			var first_enemy := battle.get_node("EnemyLayer").get_child(0)
			_expect(first_enemy.has_node("HpBar"), "enemy must render hp bar")
			var expected_runtime_hp_floor := float(battle.level.get("base_hp_ref", 50)) * float(battle.level.get("difficulty_coef", 1.0)) * 0.55
			_expect(float(first_enemy.max_hp) >= expected_runtime_hp_floor, "enemy hp must scale with base_hp_ref; got %.1f expected floor %.1f on %s" % [float(first_enemy.max_hp), expected_runtime_hp_floor, battle.level_id])
		if battle.level_id == "level_001":
			battle._show_card_offer()
			await process_frame
			var cards := battle.get_node("Hud/CardPanel/Cards")
			_expect(cards.get_child_count() == 3, "card offer must render three cards")
			var first_card := cards.get_child(0)
			_expect(first_card.has_node("Icon") or first_card.get_child_count() >= 4, "card must render icon and text children")
			var first_card_icon := first_card.get_node("Icon") as TextureRect
			_expect(first_card_icon != null, "card icon must be a TextureRect")
			_expect(first_card_icon.size.x <= 128.0 and first_card_icon.size.y <= 128.0, "card icon must stay bounded, got %s" % str(first_card_icon.size))
			battle._show_card_detail("skill_split_shot")
			await process_frame
			_expect(battle.get_node("Hud/CardPanel/DetailOverlay").visible, "card long-press detail overlay must open")
			battle._hide_card_detail()
			battle.get_tree().paused = false
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
	await process_frame

	print("M1 smoke test passed")
	quit(0)

func _instance(path: String) -> Node:
	var packed := load(path) as PackedScene
	_expect(packed != null, "scene must load: %s" % path)
	return packed.instantiate()

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
	var has_left := false
	var has_right := false
	for direction in directions:
		_expect(direction.y < -0.45, "multi-shot target direction must point into the battlefield")
		if direction.x < -0.08:
			has_left = true
		if direction.x > 0.08:
			has_right = true
	_expect(directions.size() == 3, "multi-shot targeting must return one direction per projectile")
	_expect(has_left and has_right, "multi-shot targeting must assign side lanes to actual enemies")
	for target in fake_targets:
		target.queue_free()

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
	var weapon_table: Dictionary = data_loader.get_table("weapons")
	for weapon_id in weapon_table.keys():
		var row: Dictionary = data_loader.get_row("weapons", weapon_id)
		var handheld_path := str(row.get("handheld", ""))
		_expect(handheld_path != "", "weapon must define handheld skin: %s" % weapon_id)
		_expect(ResourceLoader.exists(handheld_path), "weapon handheld skin must exist: %s" % handheld_path)
		var test_save: Dictionary = original_save.duplicate(true)
		var unlocks: Dictionary = test_save.get("unlocks", {}).duplicate(true)
		var weapons: Array = unlocks.get("weapons", []).duplicate()
		if not weapons.has(weapon_id):
			weapons.append(weapon_id)
		unlocks["weapons"] = weapons
		test_save["unlocks"] = unlocks
		var equipment: Dictionary = test_save.get("equipment", {}).duplicate(true)
		equipment["selected_weapon"] = weapon_id
		equipment[weapon_id] = 18
		test_save["equipment"] = equipment
		save_manager.save_data = test_save
		var battle := _instance("res://gameplay/battle/battle.tscn")
		battle.setup(router, {"level_id": "level_001"})
		root.add_child(battle)
		await process_frame
		await physics_frame
		_expect(battle.character_weapon_sprite != null, "battle must mount weapon skin for %s" % weapon_id)
		var weapon_sprite := battle.character_weapon_sprite as Sprite2D
		_expect(weapon_sprite.texture != null, "mounted weapon texture must exist for %s" % weapon_id)
		_expect(str(weapon_sprite.texture.resource_path) == handheld_path, "mounted weapon must use handheld skin; got %s expected %s" % [str(weapon_sprite.texture.resource_path), handheld_path])
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
