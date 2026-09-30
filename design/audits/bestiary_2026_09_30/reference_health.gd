extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	await process_frame
	var save = root.get_node("SaveManager")
	var loader = root.get_node("DataLoader")
	loader.load_all()
	save.suppress_persistence_for_captures = true
	var fixture = JSON.parse_string(FileAccess.get_file_as_string("res://design/audits/campaign_progression_fixture_builds.json"))
	for row in fixture.rows:
		if not int(row.level) in [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 70, 80, 90, 99]:
			continue
		save.save_data = save._default_save()
		var build: Dictionary = row.build
		for kind in ["character", "weapon", "armor", "chip", "pet"]:
			var id := str(build.get(kind, ""))
			save.save_data.equipment["selected_" + kind] = id
			if id != "":
				save.save_data.equipment[id] = int(build.get(kind + "_level", 1))
			var table: String = "characters" if kind == "character" else kind + "s"
			save.save_data.unlocks[table] = [id] if id != "" else []
		save.save_data.skill_base_levels = build.get("skill_base_levels", {}).duplicate(true)
		save.save_data.sig_skill_levels = {str(build.character): int(build.get("signature_level", 0))}
		var battle: Node = load("res://gameplay/battle/battle.tscn").instantiate()
		battle.setup(null, {"level_id": row.level_id})
		root.add_child(battle)
		battle.set_process(false)
		battle.set_physics_process(false)
		print("REFERENCE ", row.level, " hp=", battle.base_hp_max, " damage_mult=", battle.breach_damage_mult)
		battle.queue_free()
		await process_frame
	root.get_node("AudioManager").release_for_tests()
	for tween in get_processed_tweens():
		tween.kill()
	load("res://ui/ui_kit.gd").release_cached_resources_for_tests()
	quit()
