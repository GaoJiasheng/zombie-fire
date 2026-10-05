extends SceneTree

const UiKit := preload("res://ui/ui_kit.gd")
const SequenceVfx := preload("res://gameplay/vfx/sequence_vfx.gd")
const StatusVfx := preload("res://gameplay/vfx/status_vfx_controller.gd")
const MaterialArt := preload("res://gameplay/vfx/combat_vfx_art.gd")
var failures: Array[String] = []
var checks := 0
var output := ""
var authored_only := false
var viewport: SubViewport
var main: Node
var battle: Node

func _initialize() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_size(Vector2i(1, 1))
		DisplayServer.window_set_position(Vector2i(-32000, -32000))
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)

func settle() -> void:
	for frame in range(8):
		await process_frame

func _run() -> void:
	root.get_node("DataLoader").load_all()
	var save: Node = root.get_node("SaveManager")
	save.suppress_persistence_for_captures = true
	root.get_node("AudioManager")._headless_audio = true
	root.get_node("LocalizationManager").apply_language("zh", false)
	var args := OS.get_cmdline_user_args()
	authored_only = args.has("--authored-only")
	output = args[0] if not args.is_empty() else ""
	if output != "":
		DirAccess.make_dir_recursive_absolute(output)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1080, 2340)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	main = load("res://main.tscn").instantiate()
	viewport.add_child(main)
	await settle()
	# main._ready loads the save; apply the isolated fixture AFTER that load.
	configure_fixture(save)
	if is_instance_valid(main._power_scale_notice_layer):
		main._power_scale_notice_layer.queue_free()
	main.change_scene("battle", {"level_id": "level_030"})
	await settle()
	battle = main.current_scene
	battle.set_physics_process(false)
	battle.turret.fire_enabled = false
	battle.turret.set_physics_process(false)
	battle.pending_spawns.clear()
	battle.active_spawning = false
	battle.hit_stop.enabled = false
	battle.breach_damage_mult = 1.0
	for enemy in battle.get_node("EnemyLayer").get_children():
		enemy.free()
	var data: Node = root.get_node("DataLoader")
	var settings: Node = root.get_node("SettingsManager")
	var quality_modes: Array[bool] = [false, true]
	if args.has("--capture-only") or authored_only:
		quality_modes.clear() # Full matrix is independently required by the RC gate.
	for low in quality_modes:
		settings.settings.quality = "battery" if low else "standard"
		settings.settings.reduced_effects = low
		for speed in [1.0, 2.0, 5.0]:
			Engine.time_scale = speed
			battle.battle_speed = speed
			for saturated in [false, true]:
				print("BASE_ATTACK_FEEDBACK matrix low=", low, " speed=", speed, " saturated=", saturated)
				clear_decorations()
				if saturated:
					for i in range(320):
						var dummy := Node2D.new()
						dummy.set_meta("transient_vfx", true)
						battle.get_node("ProjectileLayer").add_child(dummy)
					check(not battle._can_spawn_projectile_fx(true), "fixture must exhaust priority decoration budget")
				for table in ["zombies", "bosses"]:
					for id in data.get_table(table):
						verify_cycle(str(id), table == "bosses", low, speed, saturated)
				verify_remote(low, speed, saturated)
				verify_death_blasts(low, speed, saturated)
				verify_bounds()
	verify_material_art()
	# Optional real-renderer contact/route frames under exactly the saturated cap.
	if output != "":
		# Dispose matrix float texts/tweens instead of photographing accumulated
		# synchronous fixture events as if they were a real battle frame.
		main.change_scene("battle", {"level_id": "level_030"})
		await settle()
		battle = main.current_scene
		battle.set_physics_process(false)
		battle.turret.fire_enabled = false
		battle.turret.set_physics_process(false)
		battle.pending_spawns.clear()
		battle.active_spawning = false
		battle.hit_stop.enabled = false
		for enemy in battle.get_node("EnemyLayer").get_children():
			enemy.free()
		await capture_roster(data)
	Engine.time_scale = 1.0
	settings.settings.quality = "standard"
	settings.settings.reduced_effects = false
	main.queue_free()
	await settle()
	viewport.queue_free()
	await process_frame
	root.get_node("AudioManager").release_for_tests()
	for tween in get_processed_tweens():
		tween.kill()
	UiKit.release_cached_resources_for_tests()
	SequenceVfx.release_cached_resources_for_tests()
	StatusVfx.release_cached_resources_for_tests()
	await settle()
	for failure in failures:
		printerr(failure)
	print("BASE_ATTACK_FEEDBACK_AUDIT checks=", checks, " failures=", failures.size())
	if failures.is_empty():
		print("BASE_ATTACK_FEEDBACK_AUDIT PASSED")
	quit(0 if failures.is_empty() else 1)

func configure_fixture(save: Node) -> void:
	save.save_data = save._default_save()
	save.save_data.equipment.merge({"selected_character": "frost", "frost": 20,
		"selected_weapon": "weapon_scattergun", "weapon_scattergun": 10,
		"selected_pet": "pet_frost_wisp", "pet_frost_wisp": 1}, true)
	save.save_data.unlocks.characters = ["vanguard", "frost"]
	save.save_data.unlocks.weapons = ["weapon_autocannon", "weapon_scattergun"]
	save.save_data.unlocks.pets = ["pet_frost_wisp"]
	root.get_node("PurchaseManager").refresh_catalog_and_access()
	root.get_node("ThemeManager").refresh_from_save()

func clear_decorations() -> void:
	for fx in battle.get_node("ProjectileLayer").get_children():
		fx.free()
	var feedback: Node = battle._base_attack_feedback()
	feedback.traces.clear()
	feedback.contacts.clear()
	feedback.windups.clear()
	feedback.set_process(false)

func reset_hp() -> void:
	battle.base_hp_max = 10000
	battle.base_hp = 10000
	battle.breach_shields = 0
	battle.skill_barriers_left = 0
	battle.battle_finished = false

func verify_cycle(id: String, boss: bool, low: bool, speed: float, saturated: bool) -> void:
	reset_hp()
	var feedback: Node = battle._base_attack_feedback()
	feedback.traces.clear()
	feedback.contacts.clear()
	feedback.windups.clear()
	var context := "%s low=%s speed=%s saturated=%s" % [id, low, speed, saturated]
	var enemy: Node = battle._spawn_enemy_instance(id, Vector2(540, battle.BREACH_Y - 270), boss)
	enemy.set_physics_process(false)
	enemy._enter_base_attack()
	enemy.base_attack_timer = 0.0
	var count_before := int(enemy.base_attack_damage)
	for step in range(100):
		enemy._process_base_attack(0.04)
		if step == 0:
			check(feedback.windups.size() == 1, context + " wind-up missing")
			check(feedback.contacts.is_empty(), context + " wind-up fabricated a contact")
		if battle.base_hp < 10000:
			break
	check(battle.base_hp == 10000 - count_before, context + " authored total damage changed")
	check(feedback.contacts.size() == 1, context + " real contact feedback missing/duplicated")
	check(not feedback.traces.is_empty(), context + " attacker-to-base route missing")
	if not feedback.contacts.is_empty():
		check(is_equal_approx(float(feedback.contacts[0].target.y), float(battle.BREACH_Y)), context + " contact off runtime barricade")
	check(feedback.z_index > battle.DEFENSE_ACTOR_Z and not feedback.z_as_relative, context + " critical feedback hidden behind actor")
	check(feedback.reduced == low, context + " reduced effects ignored")
	# 100 ms of real time must not turn into a 5x-shortened pulse.
	# Existing hit-stop can temporarily alter Engine.time_scale on a hit. Here
	# manually supplied deltas must use the exact scale they were authored for.
	Engine.time_scale = speed
	feedback._process(0.1 * speed)
	check(not feedback.contacts.is_empty() and is_equal_approx(float(feedback.contacts[0].age), 0.1), context + " pulse compressed by speed")
	feedback._process(0.5 * speed)
	check(feedback.contacts.is_empty() and feedback.traces.is_empty(), context + " feedback does not expire")
	# A full authored siege cycle consumes one shield, not one per visual hit.
	reset_hp()
	battle.breach_shields = 1
	feedback.contacts.clear()
	feedback.traces.clear()
	enemy._base_attack_sequence_active = false
	enemy._normal_attack_sequence_active = false
	enemy.base_attack_timer = 0.0
	for step in range(100):
		enemy._process_base_attack(0.04)
		if battle.breach_shields == 0:
			break
	check(battle.base_hp == 10000 and battle.breach_shields == 0, context + " authored shield behavior changed")
	check(feedback.contacts.size() == 1 and bool(feedback.contacts[0].blocked), context + " siege block missing")
	Engine.time_scale = speed
	feedback._process(0.1 * speed)
	check(not feedback.contacts.is_empty() and bool(feedback.contacts[0].blocked), context + " queued arrival erased block feedback")
	enemy.free()

func verify_death_blasts(low: bool, speed: float, saturated: bool) -> void:
	for id in ["zombie_bomber", "zombie_toxic"]:
		for language in ["zh", "en"]:
			root.get_node("LocalizationManager").apply_language(language, false)
			for reaches in [false, true]:
				reset_hp()
				var feedback: Node = battle._base_attack_feedback()
				feedback.contacts.clear()
				feedback.traces.clear()
				var enemy: Node = battle._spawn_enemy_instance(id, Vector2(540, battle.BREACH_Y - (90 if reaches else 500)), false)
				enemy.set_physics_process(false)
				battle._resolve_death_mechanic(enemy)
				var context := "%s death %s reaches=%s low=%s speed=%s saturated=%s" % [id, language, reaches, low, speed, saturated]
				check((battle.base_hp < 10000) == reaches, context + " authored blast radius/damage changed")
				check((not feedback.contacts.is_empty()) == reaches, context + " blast contact does not match radius")
				if reaches:
					check(feedback.contacts[0].element == ("fire" if id == "zombie_bomber" else "poison"), context + " localized label changed effect element")
				enemy.free()
	root.get_node("LocalizationManager").apply_language("zh", false)

func verify_remote(low: bool, speed: float, saturated: bool) -> void:
	var cases := {"zombie_spitter": "_process_ranged_pressure", "zombie_toxic": "_process_toxic_cloud_pressure",
		"zombie_juggernaut": "_process_juggernaut_pressure", "boss_frost_warden": "_process_freeze_field",
		"boss_inferno_maw": "", "boss_storm_caller": "", "boss_necrotitan": "", "boss_apex_overlord": "_process_apex_pressure"}
	for id in cases:
		reset_hp()
		var feedback: Node = battle._base_attack_feedback()
		feedback.contacts.clear()
		feedback.traces.clear()
		var enemy: Node = battle._spawn_enemy_instance(id, Vector2(540, battle.BREACH_Y - 400), str(id).begins_with("boss_"))
		enemy.set_physics_process(false)
		enemy.mechanic_timer = 0.0
		var before_damage := int(enemy.breach_damage)
		var before_interval := float(enemy.base_attack_interval)
		match cases[id]:
			"_process_freeze_field", "_process_apex_pressure":
				battle.call(cases[id], enemy, [enemy], 1.0)
			"":
				battle._process_boss_pressure(enemy, 1.0, 4.2, 0.42, "腐化" if id == "boss_necrotitan" else "雷暴" if id == "boss_storm_caller" else "熔火", Color(0.7, 0.9, 1.0))
			_:
				battle.call(cases[id], enemy, 1.0)
		var context := "%s remote low=%s speed=%s saturated=%s" % [id, low, speed, saturated]
		if before_damage > 0:
			check(battle.base_hp < 10000, context + " fixture did not deal damage")
			check(not feedback.contacts.is_empty() and not feedback.traces.is_empty(), context + " remote damage lacks route/contact")
		else:
			# Zero bd_coef is an explicit no-remote-damage contract. The new
			# siege budget must never leak into this independent pressure route.
			check(battle.base_hp == 10000, context + " zero remote damage changed")
			check(feedback.contacts.is_empty(), context + " zero damage fabricated a base contact")
		check(enemy.breach_damage == before_damage and is_equal_approx(float(enemy.base_attack_interval), before_interval), context + " feedback mutated combat parameters")
		feedback.contacts.clear()
		feedback.traces.clear()
		battle.breach_shields = 1
		battle._apply_enemy_skill_base_damage(enemy, 10, "寒潮" if id == "boss_frost_warden" else "腐蚀", Color(0.5, 0.9, 1.0), Vector2(540, battle.BREACH_Y))
		check(feedback.contacts.size() == 1 and bool(feedback.contacts[0].blocked), context + " shield contact missing")
		check(battle.breach_shields == 0, context + " shield charged twice")
		enemy.free()

func verify_bounds() -> void:
	var feedback: Node = battle._base_attack_feedback()
	for i in range(100):
		feedback.show_windup(Vector2(i * 50, 800), Vector2(i * 50, battle.BREACH_Y), Color.WHITE, 0.5, true)
		feedback.show_attack(Vector2(i * 50, 800), Vector2(i * 50, battle.BREACH_Y), "ice", Color.WHITE, true)
		feedback.show_contact(Vector2(i * 50, battle.BREACH_Y), "ice", Color.WHITE, true, false)
	check(feedback.traces.size() <= feedback.MAX_TRACES and feedback.contacts.size() <= feedback.MAX_CONTACTS, "critical feedback pool unbounded")
	check(feedback.windups.size() <= feedback.MAX_WINDUPS, "critical wind-up pool unbounded")
	feedback._process(1.0)
	check(feedback.windups.is_empty(), "wind-ups do not expire")
	feedback.traces.clear()
	feedback.contacts.clear()
	# Combat audit mode must still skip all presentation work.
	battle._audit_combat_rng = RandomNumberGenerator.new()
	check(battle._base_attack_feedback() == null, "deterministic probe gained presentation nodes")
	battle._audit_combat_rng = null

func capture_roster(data: Node) -> void:
	Engine.time_scale = 1.0
	battle.battle_speed = 1.0
	root.get_node("SettingsManager").settings.quality = "standard"
	root.get_node("SettingsManager").settings.reduced_effects = false
	var contact_tables: Array[String] = ["zombies", "bosses"]
	if authored_only:
		contact_tables.clear() # Recheck just the eight authored frames after HUD flush fixes.
	for table in contact_tables:
		for id in data.get_table(table):
			clear_decorations()
			for i in range(320):
				var dummy := Node2D.new()
				dummy.set_meta("transient_vfx", true)
				battle.get_node("ProjectileLayer").add_child(dummy)
			reset_hp()
			var enemy: Node = battle._spawn_enemy_instance(str(id), Vector2(540, battle.BREACH_Y - 270), table == "bosses")
			enemy.set_physics_process(false)
			# Allow entry glows and pose initialization to finish before contact.
			for frame in range(24):
				await process_frame
			enemy._enter_base_attack()
			enemy.base_attack_timer = 0.0
			var feedback: Node = battle._base_attack_feedback()
			for step in range(100):
				enemy._process_base_attack(0.04)
				Engine.time_scale = 1.0
				feedback._process(0.04)
				if battle.base_hp < 10000:
					break
			feedback._process(0.1)
			battle._update_hud()
			await process_frame
			capture_contact(str(id) + "_contact.png")
			print("BASE_ATTACK_FEEDBACK captured ", id)
			enemy.free()
			# Drain old float text and hit-flash between independent captures.
			for frame in range(80):
				await process_frame
	# Also inspect all eight authored, uncapped attacks advancing across actual
	# render frames, not just the emergency fallback under the saturation fixture.
	for id in data.get_table("bosses"):
		clear_decorations()
		reset_hp()
		var enemy: Node = battle._spawn_enemy_instance(str(id), Vector2(540, battle.BREACH_Y - 270), true)
		enemy.set_physics_process(false)
		for frame in range(24):
			await process_frame
		enemy._enter_base_attack()
		enemy.base_attack_timer = 0.0
		battle._base_attack_feedback().set_process(true)
		for frame in range(240):
			enemy._process_base_attack(1.0 / 60.0)
			await process_frame
			if battle.base_hp < 10000:
				break
		check(battle.base_hp < 10000, str(id) + " native authored attack never resolved")
		battle._base_attack_feedback().set_process(false)
		battle._update_hud()
		await process_frame # Flush the newly spawned Boss title and resolved HP.
		capture_contact(str(id) + "_authored.png")
		print("BASE_ATTACK_FEEDBACK authored ", id)
		enemy.free()
		for frame in range(80):
			await process_frame
	for id in ["zombie_spitter", "boss_frost_warden"]:
		clear_decorations()
		reset_hp()
		var enemy: Node = battle._spawn_enemy_instance(id, Vector2(540, battle.BREACH_Y - 720), id.begins_with("boss_"))
		enemy.set_physics_process(false)
		for frame in range(24):
			await process_frame
		enemy.mechanic_timer = 0.0
		if id == "zombie_spitter":
			battle._process_ranged_pressure(enemy, 1.0)
		else:
			# Frost's remote bd_coef is zero; capture its actual damaging siege
			# route in mid-flight instead of fabricating a remote damage effect.
			battle._on_enemy_base_attack_visual_hit(enemy, enemy.base_attack_profile, 0, 2)
			battle._base_attack_feedback()._process(0.12)
		battle._base_attack_feedback().set_process(false)
		battle._update_hud()
		await process_frame
		RenderingServer.force_draw(false)
		viewport.get_texture().get_image().save_png(output.path_join(id + "_route.png"))
		enemy.free()
	create_inspection_sheets(data)

func capture_contact(filename: String) -> void:
	RenderingServer.force_draw(false)
	var rendered := viewport.get_texture().get_image()
	var feedback: Node2D = battle._base_attack_feedback()
	feedback.visible = false
	RenderingServer.force_draw(false)
	var without_feedback := viewport.get_texture().get_image()
	feedback.visible = true
	var changed := 0
	var impact: Vector2 = battle._base_damage_impact_position(540)
	for y in range(int(impact.y) - 90, int(impact.y) + 40, 2):
		for x in range(420, 660, 2):
			var a := rendered.get_pixel(x, y)
			var b := without_feedback.get_pixel(x, y)
			if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.15:
				changed += 1
	check(changed >= 40, filename + " critical contact produces no visible pixels at the barricade")
	check(rendered.save_png(output.path_join(filename)) == OK, filename + " capture write failed")

func verify_material_art() -> void:
	# Explicit authored material, never inferred from the old fork-line count.
	for kind in ["fire", "ice", "lightning", "physical"]:
		clear_decorations()
		battle._spawn_muzzle_fork_lines(Vector2(540, 1000), Vector2.UP, Color.WHITE, 5, 100.0, 30.0, 0.2, 3.0, kind)
		var matching := 0
		for fx in battle.get_node("ProjectileLayer").get_children():
			if fx is MaterialArt and fx.kind == kind and fx.ribbon:
				matching += 1
		check(matching == 1, kind + " muzzle lost its explicit material identity")
	for kind in ["ice", "shield", "lightning"]:
		clear_decorations()
		battle._spawn_impact_fork_lines(Vector2(540, 1000), Color.WHITE, 8, 100.0, 0.2, 3.0, true, kind)
		var matching := 0
		for fx in battle.get_node("ProjectileLayer").get_children():
			if fx is MaterialArt and fx.kind == kind and not fx.ribbon:
				matching += 1
		check(matching == 1, kind + " impact lost its explicit material identity")
	clear_decorations()
	for kind in ["physical", "fire", "ice", "poison", "lightning", "void", "shield", "charge"]:
		for is_ribbon in [false, true]:
			var frames: Array[Texture2D] = MaterialArt.frames(kind, is_ribbon)
			check(frames.size() == 4, kind + " must have four authored material phases")
			for frame in frames:
				check(frame is AtlasTexture and frame.atlas != null, kind + " lost its production atlas")
				check(frame.filter_clip and frame.margin.size.x > 0.0, kind + " lost filtered safety gutter")
		var fx := MaterialArt.new()
		root.add_child(fx)
		fx.setup(kind, Vector2(160, 140), 0.46, Color.WHITE, false, true)
		fx.set_process(false)
		fx._process(0.2)
		check(fx._phase > 0.0 and fx._phase < 1.0, kind + " animation did not advance")
		fx._process(0.46)
		check(fx.modulate.a > 0.0 and fx._phase > 0.0, kind + " persistent animation popped out")
		fx.free()
	for table in ["zombies", "bosses"]:
		for id in root.get_node("DataLoader").get_table(table):
			var enemy: Node = battle._spawn_enemy_instance(str(id), Vector2(540, battle.BREACH_Y), table == "bosses")
			enemy.set_physics_process(false)
			enemy._attack_duration = 1.0
			enemy._base_attack_sequence_active = false
			var contact := clampf(float(enemy.attack_animation_profile.get("contact_ratio", 0.5)), 0.25, 0.8)
			enemy._attack_time = 1.0 - contact * 0.4
			enemy._update_attack_pose()
			check(enemy.get_node("Sprite").position.y < 0.0, str(id) + " lacks anticipation")
			enemy._attack_time = 1.0 - contact
			enemy._update_attack_pose()
			check(enemy.get_node("Sprite").position.y > 0.0, str(id) + " lacks a weighted strike")
			check(is_equal_approx(enemy.get_node("Sprite").position.x, float(enemy._base_sprite_x)), str(id) + " floats sideways")
			enemy._attack_time = 0.0
			enemy._update_attack_pose()
			check(is_zero_approx(enemy.get_node("Sprite").position.y), str(id) + " recovery did not return to its anchor")
			enemy.free()

func create_inspection_sheets(data: Node) -> void:
	# Diagnostic crops of native screenshots, not replacement game artwork.
	# Row order matches the data table, recorded in the accompanying report.
	for table in ["zombies", "bosses"]:
		var ids: Array = data.get_table(table).keys()
		var rows := ceili(float(ids.size()) / 4.0)
		var sheet := Image.create(1280, rows * 480, false, Image.FORMAT_RGBA8)
		sheet.fill(Color(0.015, 0.02, 0.025))
		for i in range(ids.size()):
			var shot := Image.load_from_file(output.path_join(str(ids[i]) + "_contact.png"))
			var crop := shot.get_region(Rect2i(300, int(battle.BREACH_Y) - 480, 480, 720))
			crop.resize(320, 480, Image.INTERPOLATE_LANCZOS)
			sheet.blit_rect(crop, Rect2i(0, 0, 320, 480), Vector2i((i % 4) * 320, int(i / 4) * 480))
		check(sheet.save_png(output.path_join(table + "_inspection.png")) == OK, table + " inspection sheet failed")
