extends SceneTree

## Isolated-save, real renderer filmstrip. Not a gameplay/damage probe.
func _initialize() -> void:
	for bus in range(AudioServer.bus_count):
		AudioServer.set_bus_mute(bus, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	DisplayServer.window_set_size(Vector2i(1, 1))
	DisplayServer.window_set_position(Vector2i(-32000, -32000))
	await process_frame
	var args := OS.get_cmdline_user_args()
	var hero := str(args[0])
	var speed := float(args[1])
	var output := str(args[2])
	var boss_scene := args.size() > 3 and str(args[3]) == "boss"
	DirAccess.make_dir_recursive_absolute(output)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1560)
	viewport.size_2d_override = Vector2i(1080, 2340)
	viewport.size_2d_override_stretch = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	root.get_node("DataLoader").load_all()
	var save: Node = root.get_node("SaveManager")
	save.suppress_persistence_for_captures = true
	var main: Node = load("res://main.tscn").instantiate()
	viewport.add_child(main)
	await process_frame
	var fixture: Dictionary = save._default_save()
	fixture.equipment.selected_character = hero
	fixture.equipment.selected_weapon = "weapon_autocannon"
	fixture.unlocks.characters = [hero]
	fixture.sig_skill_levels = {hero: 0}
	save.save_data = fixture
	root.get_node("PurchaseManager").refresh_catalog_and_access()
	root.get_node("ThemeManager").refresh_from_save()
	main.change_scene("battle", {"level_id": "level_001"})
	for frame in range(12):
		await process_frame
	var battle: Node = main.current_scene
	battle.set_physics_process(false)
	battle.turret.fire_enabled = false
	battle.turret.set_physics_process(false)
	battle.battle_speed = speed
	Engine.time_scale = speed
	if battle.hit_stop != null:
		battle.hit_stop.target_scale = speed
	battle.card_offer_active = false
	battle.paused = false
	paused = false
	for enemy in battle.get_node("EnemyLayer").get_children():
		enemy.free()
	for i in range(1 if boss_scene else 8):
		var enemy: Node = battle._spawn_enemy_instance("boss_tank_titan" if boss_scene else "zombie_shambler", Vector2(540, 850) if boss_scene else Vector2(330 + (i % 4) * 140, 850 + (i / 4) * 170), boss_scene)
		enemy.set_physics_process(false)
		enemy.hp = 100000.0
		enemy.max_hp = 100000.0
	battle.character_active_cd = 0.0
	battle._on_character_skill_pressed()
	var elapsed := 0.0
	var times := [0.1, 0.3, 0.6, 1.0, 2.0, 4.0, 5.5, 7.0]
	var next := 0
	var wall_start := Time.get_ticks_msec()
	while next < times.size():
		await process_frame
		if Time.get_ticks_msec() - wall_start > 90000:
			push_error("Signature capture exceeded 90 seconds at frame %d" % next)
			quit(1)
			return
		var delta := battle.get_process_delta_time()
		elapsed += delta
		battle._process_character_signatures(delta)
		for enemy in battle.get_node("EnemyLayer").get_children():
			enemy._process_element_status(delta)
		if elapsed >= float(times[next]):
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png(output.path_join("%02d.png" % next))
			print("FRAME t=", elapsed, " fx=", battle.get_node("ProjectileLayer").get_child_count())
			next += 1
	Engine.time_scale = 1.0
	main.queue_free()
	for frame in range(8):
		await process_frame
	viewport.queue_free()
	await process_frame
	root.get_node("AudioManager").release_for_tests()
	for tween in get_processed_tweens():
		tween.kill()
	UiKit.release_cached_resources_for_tests()
	load("res://gameplay/vfx/sequence_vfx.gd").release_cached_resources_for_tests()
	load("res://gameplay/vfx/status_vfx_controller.gd").release_cached_resources_for_tests()
	for frame in range(4):
		await process_frame
	quit()
