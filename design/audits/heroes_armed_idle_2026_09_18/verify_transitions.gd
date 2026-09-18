extends SceneTree
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func _initialize() -> void:
	for bus in range(AudioServer.bus_count): AudioServer.set_bus_mute(bus,true)
	await process_frame
	var save = root.get_node("SaveManager")
	save.suppress_persistence_for_captures = true
	var data = root.get_node("DataLoader")
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	for hero in data.get_table("characters"):
		for weapon in data.get_table("weapons"):
			if not data.get_row("weapons",weapon).get("presentation",{}).get("true_grip",{}).is_empty():continue
			save.save_data = save._default_save()
			save.save_data["unlocks"]["characters"].append(hero)
			save.save_data["unlocks"]["weapons"].append(weapon)
			save.save_data["equipment"]["selected_character"] = hero
			save.save_data["equipment"]["selected_weapon"] = weapon
			save.save_data["equipment"][weapon] = 1
			main.change_scene("battle",{"level_id":"level_001"})
			for i in range(3):await process_frame
			var battle = main.current_scene
			battle.set_process(false)
			battle.set_physics_process(false)
			battle.turret.fire_enabled = false
			battle.turret.set_physics_process(false)
			var context: String = str(hero)+"/"+str(weapon)
			check(battle.character_armed_rest_pose,"armed rest enabled: "+context)
			for direction in [Vector2.UP,Vector2(-0.75,-0.66),Vector2(0.75,-0.66)]:
				battle.character_weapon_combo_locked_aim = ""
				battle._set_character_combo_aim_from_direction(direction)
				var origin: Vector2 = battle._weapon_fire_origin()
				battle.character_armed_rest_pose = false
				check(origin.is_equal_approx(battle._weapon_fire_origin()),"muzzle unchanged: "+context)
				battle.character_armed_rest_pose = true
				battle.character_hurt_time = 0.0
				battle.character_skill_time = 0.0
				for cycle in range(3):
					battle._play_character_attack()
					check(battle.character_sprite.texture == battle._character_combo_attack_frames()[1],"F2 ignition: "+context)
					battle._process_character_animation(battle.character_attack_duration+0.01)
					battle._process_character_animation(0.01)
					check(battle.character_sprite.texture == battle.character_attack_frames[0],"post-shot armed rest: "+context)
					battle._play_character_hurt()
					battle._process_character_animation(0.01)
					check(battle.character_sprite.texture == battle.character_attack_frames[0],"armed hurt: "+context)
					battle.character_hurt_time = 0.0
				print("ARMED_REST ",context," aim=",direction," three cycles passed")
	main.queue_free()
	for i in range(3):await process_frame
	UiKit.release_cached_resources_for_tests()
	print("All-hero armed-rest transition regression: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
