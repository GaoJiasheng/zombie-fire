extends SceneTree

func _initialize() -> void:
	await process_frame
	var data_loader := root.get_node("/root/DataLoader")
	var save_manager := root.get_node("/root/SaveManager")
	data_loader.load_all()
	save_manager.load_game()

	var main_scene: Node = load("res://main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	await process_frame
	(main_scene as Node).call("start_level", "level_001")
	for i in range(120):
		await process_frame
		await physics_frame
	var battle: Node = (main_scene as Node).get("current_scene")
	if battle == null:
		print("FAIL: no battle scene")
		quit(1)
		return
	print("scene=", battle.name)
	print("paused=", paused, " time_scale=", Engine.time_scale)
	print("battle.paused=", battle.get("paused"))
	print("battle.card_offer_active=", battle.get("card_offer_active"))
	print("wave=", battle.get("wave_index"), "/", battle.get("wave_total"))
	print("pending_spawns=", (battle.get("pending_spawns") as Array).size())
	print("active_spawning=", battle.get("active_spawning"))
	print("enemies=", battle.get_node("EnemyLayer").get_child_count())
	print("character_rig=", battle.get("character_rig") != null)
	print("turret=", battle.get("turret") != null)
	quit(0)
