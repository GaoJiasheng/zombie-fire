extends SceneTree

const EXPECTED_LEVEL := "level_001"
const EXPECTED_SCENE := "res://gameplay/battle/battle.tscn"
const MAX_BOOT_FRAMES := 240


func _initialize() -> void:
	var failures: Array[String] = []
	await process_frame
	var data_loader := root.get_node_or_null("/root/DataLoader")
	var save_manager := root.get_node_or_null("/root/SaveManager")
	if data_loader == null:
		failures.append("DataLoader autoload is missing")
	if save_manager == null:
		failures.append("SaveManager autoload is missing")
	if not failures.is_empty():
		await _finish(null, failures)
		return

	data_loader.call("load_all")
	save_manager.call("load_game")
	var packed_main := load("res://main.tscn") as PackedScene
	if packed_main == null:
		failures.append("main.tscn could not be loaded")
		await _finish(null, failures)
		return

	var main_scene := packed_main.instantiate()
	root.add_child(main_scene)
	await process_frame
	await process_frame
	main_scene.call("start_level", EXPECTED_LEVEL)

	var battle: Node = null
	for _frame in range(MAX_BOOT_FRAMES):
		await process_frame
		await physics_frame
		battle = main_scene.get("current_scene") as Node
		if battle != null and battle.scene_file_path == EXPECTED_SCENE:
			var enemy_layer := battle.get_node_or_null("EnemyLayer")
			if enemy_layer != null and enemy_layer.get_child_count() > 0:
				break

	if battle == null:
		failures.append("no current scene after starting the level")
	else:
		if battle.scene_file_path != EXPECTED_SCENE:
			failures.append("current scene is not the battle scene: %s" % battle.scene_file_path)
		if str(battle.get("level_id")) != EXPECTED_LEVEL:
			failures.append("battle loaded the wrong level: %s" % battle.get("level_id"))
		if paused or not is_equal_approx(Engine.time_scale, 1.0):
			failures.append("scene tree is paused or time scale is not 1.0")
		if bool(battle.get("paused")):
			failures.append("battle is paused")
		if bool(battle.get("card_offer_active")):
			failures.append("battle booted into a card offer")
		if int(battle.get("wave_index")) < 1 or int(battle.get("wave_total")) < 1:
			failures.append("battle wave did not start")
		var enemy_layer := battle.get_node_or_null("EnemyLayer")
		if enemy_layer == null or enemy_layer.get_child_count() < 1:
			failures.append("battle did not spawn an enemy")
		var pending_spawns := battle.get("pending_spawns") as Array
		if pending_spawns.is_empty() and not bool(battle.get("active_spawning")):
			failures.append("battle has no active or pending spawn work")
		var turret := battle.get("turret") as Node
		if turret == null or not is_instance_valid(turret) or not turret.is_inside_tree():
			failures.append("battle turret is not active")
		var character_rig := battle.get("character_rig") as Node
		if character_rig == null or not is_instance_valid(character_rig) or not character_rig.is_inside_tree():
			failures.append("battle character rig is not active")

	if failures.is_empty():
		var enemy_count := battle.get_node("EnemyLayer").get_child_count()
		print(
			"BATTLE_BOOT_PROBE_OK level=", battle.get("level_id"),
			" scene=", battle.scene_file_path,
			" wave=", battle.get("wave_index"), "/", battle.get("wave_total"),
			" enemies=", enemy_count
		)
	await _finish(main_scene, failures)


func _finish(main_scene: Node, failures: Array[String]) -> void:
	if main_scene != null and is_instance_valid(main_scene):
		main_scene.queue_free()
		for _frame in range(4):
			await process_frame
	if failures.is_empty():
		quit(0)
		return
	for failure in failures:
		print("FAIL: ", failure)
	quit(1)
