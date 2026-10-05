extends "res://tools/audit_base_attack_feedback.gd"

## Native-renderer diagnostic only. Uses the parent's isolated, non-persisting save.
## Contact coverage/matrix remain the independent audit's responsibility.
func capture_roster(data: Node) -> void:
	Engine.time_scale = 1.0
	root.get_node("SettingsManager").settings.reduced_effects = false
	clear_decorations()
	var origin := Vector2(540, battle.BREACH_Y - 440)
	var crop := Rect2i(280, int(origin.y) - 180, 520, 360)
	var material_sheet := Image.create(1600, 8 * 277, false, Image.FORMAT_RGBA8)
	var kinds := ["physical", "fire", "ice", "poison", "lightning", "void", "shield", "charge"]
	for row in range(kinds.size()):
		var fx := MaterialArt.new()
		battle.get_node("ProjectileLayer").add_child(fx)
		fx.position = origin
		fx.z_index = 76
		fx.setup(kinds[row], Vector2(270, 224), 1.0)
		fx.set_process(false)
		for column in range(4):
			fx.elapsed = 0.0
			fx._process([0.05, 0.27, 0.53, 0.79][column])
			await process_frame # Flush queued custom drawing before GPU readback.
			RenderingServer.force_draw(false)
			var frame := viewport.get_texture().get_image().get_region(crop)
			frame.resize(400, 277, Image.INTERPOLATE_LANCZOS)
			material_sheet.blit_rect(frame, Rect2i(0, 0, 400, 277), Vector2i(column * 400, row * 277))
		fx.free()
	check(material_sheet.save_png(output.path_join("materials_native_phases.png")) == OK, "material phase sheet failed")
	# Exercise real presentation helpers, not just the atlas preview.
	var helpers := [
		["chain", "_spawn_chain_arc", [origin + Vector2(-210, 80), origin + Vector2(210, -80), "lightning"]],
		["weapon_trace", "_spawn_weapon_trace", [origin + Vector2(-210, 80), origin + Vector2(210, -80), Color(1, 0.6, 0.2), 16.0, 0.3]],
		["muzzle_ice", "_spawn_muzzle_fork_lines", [origin, Vector2.UP, Color(0.5, 0.8, 1), 3, 180.0, 20.0, 0.3, 5.0]],
		["muzzle_poison", "_spawn_muzzle_bubbles", [origin, Vector2.UP, Color(0.5, 1, 0.1), 4, 0.3]],
		["muzzle_fire", "_spawn_muzzle_fork_lines", [origin, Vector2.UP, Color(1, 0.8, 0.3), 5, 180.0, 20.0, 0.3, 5.0, "fire"]],
		["muzzle_gold", "_spawn_muzzle_fork_lines", [origin, Vector2.UP, Color(1, 0.8, 0.3), 5, 180.0, 20.0, 0.3, 5.0, "physical"]],
		["impact_ice", "_spawn_impact_fork_lines", [origin, Color(0.5, 0.8, 1), 3, 145.0, 0.3, 5.0, true, "ice"]],
		["impact_fire", "_spawn_impact_streaks", [origin, Color(1, 0.4, 0.1), 6, 145.0, 0.3, 5.0, true]],
		["shield", "_spawn_barrier_shell_pulse", [origin, 150.0, Color(0.4, 0.8, 1), 0.3]],
	]
	for entry in helpers:
		clear_decorations()
		await process_frame
		RenderingServer.force_draw(false)
		var before := viewport.get_texture().get_image()
		battle.callv(entry[1], entry[2])
		for fx in battle.get_node("ProjectileLayer").get_children():
			if fx is MaterialArt:
				fx.set_process(false)
				fx._process(0.05)
		await process_frame
		RenderingServer.force_draw(false)
		var after := viewport.get_texture().get_image()
		var changed := 0
		for y in range(crop.position.y, crop.end.y, 3):
			for x in range(crop.position.x, crop.end.x, 3):
				var a := before.get_pixel(x, y)
				var b := after.get_pixel(x, y)
				if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.15:
					changed += 1
		check(changed > 40, str(entry[0]) + " helper is invisible in native renderer")
		check(after.save_png(output.path_join(str(entry[0]) + "_native.png")) == OK, str(entry[0]) + " helper capture failed")
	# All 28 authored actors: rest, anticipation, contact, recovery. No damage.
	for table in ["zombies", "bosses"]:
		for id in data.get_table(table):
			clear_decorations()
			var enemy: Node = battle._spawn_enemy_instance(str(id), origin, table == "bosses")
			enemy.set_physics_process(false)
			enemy.set_process(false)
			enemy._attack_duration = 1.0
			enemy._base_attack_sequence_active = false
			var contact := clampf(float(enemy.attack_animation_profile.get("contact_ratio", 0.5)), 0.25, 0.8)
			var sheet := Image.create(1280, 480, false, Image.FORMAT_RGBA8)
			for column in range(4):
				enemy._attack_time = 1.0 - [0.0, contact * 0.4, contact, 1.0][column]
				enemy._update_attack_pose()
				await process_frame
				RenderingServer.force_draw(false)
				var frame := viewport.get_texture().get_image().get_region(Rect2i(300, int(origin.y) - 310, 480, 720))
				frame.resize(320, 480, Image.INTERPOLATE_LANCZOS)
				sheet.blit_rect(frame, Rect2i(0, 0, 320, 480), Vector2i(column * 320, 0))
			check(sheet.save_png(output.path_join(str(id) + "_motion.png")) == OK, str(id) + " motion capture failed")
			enemy.free()
	print("COMBAT_VFX_POLISH_NATIVE materials=8 helpers=9 motions=28")
