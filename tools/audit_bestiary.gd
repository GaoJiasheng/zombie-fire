extends SceneTree

var errors: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		errors.append(message)

func _run() -> void:
	await process_frame
	var data: Node = root.get_node("DataLoader")
	var save: Node = root.get_node("SaveManager")
	data.load_all()
	save.suppress_persistence_for_captures = true
	var args := OS.get_cmdline_user_args()
	var output := str(args[0]) if not args.is_empty() else ""
	if output != "":
		DirAccess.make_dir_recursive_absolute(output)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1080, 2340)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var main: Node = load("res://main.tscn").instantiate()
	viewport.add_child(main)
	await process_frame
	save.save_data = save._default_save()
	if args.has("--boss-preview"):
		save.record_enemy_encounter("boss_frost_warden", false)
		main.change_scene("bestiary", {"chapter": 3})
		await process_frame
		var preview: Node = main.current_scene
		preview.category = "bosses"
		preview._show_list()
		await audit(preview, "boss_page_zh_2340", output)
		preview._open_entry("boss_frost_warden")
		await audit(preview, "boss_frost_warden_zh_2340", output)
		main.queue_free()
		for frame in range(8):
			await process_frame
		viewport.queue_free()
		await process_frame
		root.get_node("AudioManager").release_for_tests()
		for tween in get_processed_tweens():
			tween.kill()
		load("res://ui/ui_kit.gd").release_cached_resources_for_tests()
		print("BOSS_PREVIEW checks=", checks, " failures=", errors.size())
		quit(0 if errors.is_empty() else 1)
		return
	var old_save: Dictionary = save.save_data.duplicate(true)
	old_save.erase("enemy_encounters")
	var migrated: Dictionary = save._prepare_save(old_save, "legacy codex test")
	check(migrated.get("enemy_encounters", {"wrong": true}).is_empty(), "legacy save must default to fog, not inferred encounters")
	check(not save.record_enemy_encounter("invalid_enemy", false), "invalid IDs must not unlock")
	check(save.record_enemy_encounter("zombie_shambler", false), "first encounter must unlock")
	check(not save.record_enemy_encounter("zombie_shambler", false), "repeat encounter must not duplicate")
	check(save.save_data.enemy_encounters.size() == 1, "only one encounter should exist")
	# Exercise real disk round-trip, backup and reset in a disposable directory.
	var original_path: String = save._save_path
	var original_backup: String = save._backup_path
	var temp := "/tmp/zf-bestiary-save-" + str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(temp)
	save._save_path = temp.path_join("save.json")
	save._backup_path = temp.path_join("backup.json")
	save.suppress_persistence_for_captures = false
	save.save_game()
	save.save_data = save._default_save()
	save.load_game()
	check(save.has_encountered_enemy("zombie_shambler"), "encounter must survive reload")
	save.backup_game()
	save.save_data = save._default_save()
	check(save.restore_backup() and save.has_encountered_enemy("zombie_shambler"), "backup must restore encounters")
	save.reset_game()
	check(not save.has_encountered_enemy("zombie_shambler"), "reset must clear codex")
	save.suppress_persistence_for_captures = true
	save._save_path = original_path
	save._backup_path = original_backup
	# Real battle spawn integration, including a summoned/split child route.
	main.change_scene("battle", {"level_id": "level_001"})
	await process_frame
	var battle: Node = main.current_scene
	battle.set_process(false)
	battle.set_physics_process(false)
	var enemy: Node = battle._spawn_enemy_instance("zombie_bomber", Vector2(700, 700))
	check(save.has_encountered_enemy("zombie_bomber"), "battle spawn must record encounter without victory")
	check(enemy._threat_text() == data.tr_key("zombie_bomber"), "nameplate must show actual name only")
	battle._spawn_enemy_instance("zombie_crawler", Vector2(800, 750), false, 0.5)
	check(save.has_encountered_enemy("zombie_crawler"), "spawned child must unlock")
	check(not save.has_encountered_enemy("boss_apex_overlord"), "future boss must remain fogged")
	if output != "":
		for frame in range(10):
			await process_frame
		await capture(battle, output.path_join("battle_names_zh.png"))
	main.change_scene("map", {"chapter": 1})
	await process_frame
	if output != "":
		for frame in range(10):
			await process_frame
		await capture(main.current_scene, output.path_join("map_entry_zh.png"))
	check(save.has_encountered_enemy("zombie_bomber"), "retreat must retain encounters")
	var entry_button: Button = main.current_scene.find_child("BestiaryButton", true, false)
	check(entry_button != null, "map needs a codex entry")
	entry_button.pressed.emit()
	await process_frame
	check(main._current_route == "bestiary", "entry must navigate to codex")
	check(main.current_scene.chapter == 1, "return chapter must survive navigation")
	var codex_script: GDScript = load("res://meta/bestiary/bestiary.gd")
	for height in [1920, 2340]:
		viewport.size = Vector2i(1080, height)
		for language in ["zh", "en"]:
			root.get_node("LocalizationManager").apply_language(language, false)
			save.save_data = save._default_save()
			save.record_enemy_encounter("zombie_shambler", false)
			save.record_enemy_encounter("zombie_bomber", false)
			save.record_enemy_encounter("zombie_armored", false)
			main.change_scene("bestiary", {"chapter": 1})
			await process_frame
			var scene: Node = main.current_scene
			var fog: Button = scene.find_child("zombie_runner", true, false)
			check(fog.disabled, "unseen card must be disabled")
			check(fog.find_children("*", "TextureRect", true, false).is_empty(), "unseen portrait must not be exposed")
			for label in fog.find_children("*", "Label", true, false):
				check(not label.text.contains(data.tr_key("zombie_runner")), "unseen name leaked")
			scene._open_entry("zombie_runner")
			check(scene.selected_id == "", "programmatic unknown entry must also be blocked")
			await audit(scene, "fog_" + language + "_" + str(height), output)
			for table in ["zombies", "bosses"]:
				scene.category = table
				if table == "bosses":
					save.record_enemy_encounter("boss_frost_warden", false)
					scene.tabs.get_node("bosses").pressed.emit()
					check(scene.category == "bosses" and scene.selected_id == "", "boss tab click must open the separate listing")
					check(scene.heading.text == codex_script.text("boss_title"), "boss tab must have its own title")
					check(scene.body.find_child("zombie_shambler", true, false) == null, "boss page must not contain zombies")
					await audit(scene, "boss_page_" + language + "_" + str(height), output)
				for id in data.get_table(table):
					save.record_enemy_encounter(id, false)
					scene._open_entry(id)
					var selected: bool = id in ["zombie_bomber", "zombie_armored", "boss_tank_titan", "boss_frost_warden"] and height == 2340
					await audit(scene, id + "_" + language + "_" + str(height), output if selected else "")
					if selected and output != "":
						await capture(scene, output.path_join(id + "_story_" + language + ".png"))
				var snapshot_before: Dictionary = save.save_data.duplicate(true)
				scene._show_list()
				check(save.save_data == snapshot_before, "browsing must not grant encounters or currency")
			check(codex_script.defense_text(data.get_row("zombies", "zombie_brute")).contains(codex_script.text("no_armor")), "brute must not invent armor")
			scene.selected_id = ""
			scene._go_back()
			await process_frame
			check(main.current_scene.selected_chapter == 1, "back must restore chapter")
	# Every enemy name in both locales, with no threat/weakness prefix.
	var enemy_scene: PackedScene = load("res://gameplay/enemy/enemy.tscn")
	for language in ["zh", "en"]:
		root.get_node("LocalizationManager").apply_language(language, false)
		for table in ["zombies", "bosses"]:
			for id in data.get_table(table):
				var specimen: Node = enemy_scene.instantiate()
				specimen.data = data.get_row(table, id)
				check(specimen._threat_text() == data.tr_key(specimen.data.name_key), id + " name mismatch")
				specimen._build_threat_marker()
				specimen._sync_world_overlay_clearance()
				check(is_equal_approx(specimen.threat_marker.position.x + specimen.threat_marker.size.x / 2.0, specimen.position.x), id + " name must remain centered")
				specimen.threat_marker.free()
				specimen.free()
	main.queue_free()
	for frame in range(8):
		await process_frame
	viewport.queue_free()
	await process_frame
	root.get_node("AudioManager").release_for_tests()
	for tween in get_processed_tweens():
		tween.kill()
	load("res://ui/ui_kit.gd").release_cached_resources_for_tests()
	for error in errors:
		push_error(error)
	print("BESTIARY_AUDIT checks=", checks, " failures=", errors.size())
	quit(0 if errors.is_empty() else 1)

func audit(scene: Node, context: String, output: String) -> void:
	for frame in range(10):
		await process_frame
	var view: Rect2 = scene.get_viewport_rect()
	check(view.encloses(scene.back.get_global_rect()), context + " back button overflow")
	check(scene.back.get_global_rect().position.y >= scene.scroll.get_global_rect().end.y, context + " footer overlaps scroll")
	for label in scene.body.find_children("*", "Label", true, false):
		check(not label.clip_text and label.get_minimum_size().y <= label.size.y + 1, context + " truncated text: " + label.text)
		check(label.get_global_rect().end.x <= scene.scroll.get_global_rect().end.x + 1, context + " horizontal overflow")
	if output != "":
		await capture(scene, output.path_join(context + ".png"))
	scene.scroll.scroll_vertical = int(scene.scroll.get_v_scroll_bar().max_value)
	for frame in range(4):
		await process_frame
	check(scene.body.get_global_rect().end.y <= scene.scroll.get_global_rect().end.y + 1, context + " last line unreachable")

func capture(scene: Node, path: String) -> void:
	await RenderingServer.frame_post_draw
	scene.get_viewport().get_texture().get_image().save_png(path)
