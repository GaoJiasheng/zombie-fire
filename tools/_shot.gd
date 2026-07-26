extends SceneTree

# Visual capture helper: loads a scene through the real router and screenshots the
# viewport so container-layout refactors can be verified, not just smoke-compiled.
# Usage: godot --path . --script tools/_shot.gd -- <route> [payload_json] [out_png]

func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var route := args[0] if args.size() > 0 else "menu"
	var payload: Dictionary = {}
	if args.size() > 1 and args[1] != "":
		var parsed: Variant = JSON.parse_string(args[1])
		if parsed is Dictionary:
			payload = parsed
	var out_path := args[2] if args.size() > 2 else "/tmp/zf_shot_%s.png" % route
	if payload.has("viewport_size") and payload["viewport_size"] is Array and (payload["viewport_size"] as Array).size() >= 2:
		var viewport_size: Array = payload["viewport_size"]
		root.size = Vector2i(int(viewport_size[0]), int(viewport_size[1]))
		DisplayServer.window_set_size(root.size)
		await process_frame

	var dl := root.get_node("/root/DataLoader")
	dl.load_all()
	var sm := root.get_node("/root/SaveManager")
	sm.load_game()
	if payload.has("save_override") and payload["save_override"] is Dictionary:
		_apply_save_override(sm, payload["save_override"])
	if payload.has("equipment") and payload["equipment"] is Dictionary:
		_apply_equipment_override(sm, payload["equipment"])
	var main = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	if payload.has("save_override") and payload["save_override"] is Dictionary:
		_apply_save_override(sm, payload["save_override"])
	if payload.has("equipment") and payload["equipment"] is Dictionary:
		_apply_equipment_override(sm, payload["equipment"])
	if route != "menu":
		main.change_scene(route, payload)
	for i in range(12):
		await process_frame
		await physics_frame
	if payload.has("debug_spawn_boss") and main.current_scene != null and main.current_scene.has_method("_spawn_enemy"):
		if bool(payload.get("debug_clean_boss_stage", false)):
			# Marketing/visual-regression capture only: suspend the authored wave
			# and remove incidental mobs so the boss telegraph and health bar can
			# be judged without changing live campaign behavior.
			main.current_scene.pending_spawns.clear()
			main.current_scene.active_spawning = false
			for enemy in main.current_scene.get_node("EnemyLayer").get_children():
				enemy.queue_free()
			for marker in main.current_scene.get_node("ThreatMarkerLayer").get_children():
				marker.queue_free()
			for projectile in main.current_scene.get_node("ProjectileLayer").get_children():
				projectile.queue_free()
			await process_frame
			await process_frame
		var boss_id := str(payload.get("debug_spawn_boss", ""))
		if boss_id != "":
			main.current_scene.call("_spawn_enemy", boss_id, "center", true)
			if bool(payload.get("debug_clean_boss_stage", false)):
				var showcase_boss: Node = main.current_scene.get("active_boss")
				if showcase_boss != null and is_instance_valid(showcase_boss):
					var dramatic_showcase := bool(payload.get("debug_boss_showcase", false))
					var base_attack_showcase := bool(payload.get("debug_boss_base_attack", false))
					showcase_boss.position.y = 630.0 if dramatic_showcase else 360.0
					if base_attack_showcase:
						# Visual-regression-only deterministic staging: put the real
						# Boss on its authored melee/ranged attack line and start one
						# complete data-driven base-attack cycle.
						main.current_scene.turret.set("fire_enabled", false)
						main.current_scene.turret.set_physics_process(false)
						showcase_boss.speed = 0.0
						showcase_boss.max_hp *= 12.0
						showcase_boss.hp = showcase_boss.max_hp
						showcase_boss.position.y = float(showcase_boss.get("attack_line_y"))
						showcase_boss.call("_enter_base_attack")
						showcase_boss.set("base_attack_timer", 0.0)
						main.current_scene.base_hp = main.current_scene.base_hp_max
						if main.current_scene.target_manager != null:
							main.current_scene.target_manager.lock_enemy(showcase_boss)
						main.current_scene.call("_update_lock_indicator")
						main.current_scene.onboarding_tip_shown = true
						main.current_scene.pending_wave_toast = {}
						main.current_scene.pending_wave_toast_timer_active = false
						main.current_scene.call_deferred("_hide_wave_toast")
					elif dramatic_showcase:
						# Store-only deterministic staging: keep the actual boss
						# model, HUD, targeting and weapon systems live, but hold
						# the boss in a readable mid-lane composition long enough
						# to capture projectiles and its special pose.
						showcase_boss.position.y = 690.0
						showcase_boss.speed = 0.0
						showcase_boss.max_hp *= 8.0
						showcase_boss.hp = showcase_boss.max_hp
						var showcase_sprite := showcase_boss.get_node_or_null("Sprite") as Sprite2D
						if showcase_sprite != null:
							showcase_sprite.scale *= 1.14
							showcase_boss.set("_base_sprite_scale", showcase_sprite.scale)
						if showcase_boss.has_method("_update_hp_bar"):
							showcase_boss.call("_update_hp_bar")
						if showcase_boss.has_method("play_special"):
							showcase_boss.call("play_special", 2.4)
						if main.current_scene.target_manager != null:
							main.current_scene.target_manager.lock_enemy(showcase_boss)
						main.current_scene.call("_update_lock_indicator")
						# Deferred onboarding/wave tips can be queued while the
						# scene warms up. Clear them after the boss exists so
						# marketing captures show the real boss HUD unobstructed.
						main.current_scene.onboarding_tip_shown = true
						main.current_scene.pending_wave_toast = {}
						main.current_scene.pending_wave_toast_timer_active = false
						main.current_scene.call_deferred("_hide_wave_toast")
	if bool(payload.get("debug_dense_combat", false)) and main.current_scene != null and main.current_scene.has_method("_spawn_enemy_instance"):
		await _prepare_dense_combat(main.current_scene)
	if bool(payload.get("debug_store_combat", false)) and main.current_scene != null and main.current_scene.has_method("_spawn_enemy_instance"):
		await _prepare_store_combat(main.current_scene)
	if bool(payload.get("debug_cast_active", false)) and main.current_scene != null and main.current_scene.has_method("_on_character_skill_pressed"):
		main.current_scene.character_active_cd = 0.0
		main.current_scene.call("_on_character_skill_pressed")
	if bool(payload.get("debug_boss_skill", false)) and main.current_scene != null and main.current_scene.has_method("_announce_boss_phase"):
		main.current_scene.turret.set("fire_enabled", false)
		main.current_scene.turret.set_physics_process(false)
		var skill_boss: Node = main.current_scene.get("active_boss")
		if skill_boss != null and is_instance_valid(skill_boss):
			main.current_scene.call("_announce_boss_phase", skill_boss, "技能释放", Color(0.86, 0.96, 1.0, 1.0))
	if bool(payload.get("debug_clean_hit_stage", false)) and main.current_scene != null and main.current_scene.has_method("_spawn_enemy_instance"):
		await _prepare_isolated_vfx_stage(main.current_scene, true)
	if bool(payload.get("debug_clean_death_stage", false)) and main.current_scene != null and main.current_scene.has_method("_spawn_enemy_instance"):
		await _prepare_isolated_vfx_stage(main.current_scene, false)
	if payload.has("debug_hit_showcase") and main.current_scene != null and main.current_scene.has_method("_spawn_hit_layer_vfx"):
		main.current_scene.turret.set("fire_enabled", false)
		main.current_scene.turret.set_physics_process(false)
		var hit_spec: Variant = payload.get("debug_hit_showcase")
		if hit_spec is Dictionary:
			var hit_element := str((hit_spec as Dictionary).get("element", "physical"))
			var hit_kind := str((hit_spec as Dictionary).get("kind", "normal"))
			var hit_enemy: Node = main.current_scene.get_node("EnemyLayer").get_child(0) if main.current_scene.get_node("EnemyLayer").get_child_count() > 0 else null
			if hit_enemy != null and is_instance_valid(hit_enemy):
				if hit_kind == "crit":
					main.current_scene.call(
						"_spawn_vfx_sequence",
						"vfx_crit",
						hit_enemy.global_position + Vector2(0, -38),
						0.5,
						Color(1.0, 0.96, 0.74, 0.96),
						1.32,
						0.0,
						1.16,
						Vector2(0, -18),
						0.0,
						true
					)
				elif hit_kind == "normal" and hit_enemy.has_method("_play_hurt_feedback"):
					hit_enemy.call("_play_hurt_feedback", hit_element)
				else:
					main.current_scene.call("_spawn_hit_layer_vfx", hit_enemy.global_position, hit_element, hit_kind == "weak", hit_kind)
	if payload.has("debug_enemy_skill_showcase") and main.current_scene != null and main.current_scene.has_method("_spawn_enemy_attack_vfx"):
		main.current_scene.turret.set("fire_enabled", false)
		main.current_scene.turret.set_physics_process(false)
		var skill_enemy: Node = main.current_scene.get_node("EnemyLayer").get_child(0) if main.current_scene.get_node("EnemyLayer").get_child_count() > 0 else null
		if skill_enemy != null and is_instance_valid(skill_enemy):
			main.current_scene.call(
				"_spawn_enemy_attack_vfx",
				skill_enemy,
				str(payload.get("debug_enemy_skill_showcase", "charge")),
				skill_enemy.global_position + Vector2(0, -42)
			)
	if payload.has("debug_death_showcase") and main.current_scene != null and main.current_scene.has_method("_spawn_death_element_vfx"):
		main.current_scene.turret.set("fire_enabled", false)
		main.current_scene.turret.set_physics_process(false)
		main.current_scene.call(
			"_spawn_death_element_vfx",
			Vector2(540, 880),
			str(payload.get("debug_death_showcase", "physical")),
			false
		)
	if payload.has("debug_skill_pick_vfx") and main.current_scene != null and main.current_scene.has_method("_spawn_skill_pick_vfx"):
		main.current_scene.turret.set("fire_enabled", false)
		main.current_scene.turret.set_physics_process(false)
		main.current_scene.call("_spawn_skill_pick_vfx", str(payload.get("debug_skill_pick_vfx", "skill_split_shot")))
	if bool(payload.get("debug_barrier", false)) and main.current_scene != null and main.current_scene.has_method("_update_barrier_visual"):
		var skill_runtime: Variant = main.current_scene.get("skills")
		if skill_runtime != null and skill_runtime.has_method("add_skill"):
			skill_runtime.call("add_skill", "skill_barrier")
		main.current_scene.call("_update_barrier_visual")
	var warmup_frames := clampi(int(payload.get("warmup_frames", 0)), 0, 600)
	for i in range(warmup_frames):
		await process_frame
		await physics_frame
	if bool(payload.get("pause", false)) and main.current_scene != null and main.current_scene.has_method("_set_battle_paused"):
		main.current_scene.call("_set_battle_paused", true, false)
		for i in range(2):
			await process_frame
	if payload.has("detail_item") and main.current_scene != null and main.current_scene.has_method("_show_item_detail"):
		var detail_item := str(payload.get("detail_item", ""))
		var table_data: Dictionary = _current_collection_table(str(payload.get("mode", "")))
		if detail_item != "" and table_data.has(detail_item):
			main.current_scene.call("_show_item_detail", detail_item, table_data[detail_item])
			for i in range(18):
				await process_frame
	if bool(payload.get("card_offer", false)) and main.current_scene != null and main.current_scene.has_method("_show_card_offer"):
		main.current_scene.call("_show_card_offer")
		for i in range(18):
			await process_frame
	if payload.has("card_detail") and main.current_scene != null and main.current_scene.has_method("_show_card_detail"):
		var skill_id := str(payload.get("card_detail", "skill_split_shot"))
		if skill_id != "":
			if main.current_scene.has_node("Hud/CardPanel"):
				main.current_scene.get_node("Hud/CardPanel").visible = true
			main.current_scene.call("_show_card_detail", skill_id)
			for i in range(18):
				await process_frame
	var image := root.get_viewport().get_texture().get_image()
	if image == null:
		print("FAIL: viewport screenshot unavailable; run without --headless for visual capture")
		await _cleanup_scene(main)
		quit(2)
		return
	image.save_png(out_path)
	print("shot saved: ", out_path, " size=", image.get_size())
	await _cleanup_scene(main)
	quit(0)

func _cleanup_scene(main: Node) -> void:
	paused = false
	Engine.time_scale = 1.0
	if main != null and is_instance_valid(main):
		main.queue_free()
	var audio := root.get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("release_for_tests"):
		audio.release_for_tests()
	for i in range(3):
		await process_frame

func _apply_equipment_override(save_manager: Node, equipment_override: Dictionary) -> void:
	var shot_save: Dictionary = save_manager.save_data.duplicate(true)
	var equipment: Dictionary = shot_save.get("equipment", {}).duplicate(true)
	for key in equipment_override.keys():
		equipment[str(key)] = equipment_override[key]
	shot_save["equipment"] = equipment
	var unlocks: Dictionary = shot_save.get("unlocks", {}).duplicate(true)
	_ensure_unlocked(unlocks, "characters", str(equipment.get("selected_character", "")))
	_ensure_unlocked(unlocks, "weapons", str(equipment.get("selected_weapon", "")))
	_ensure_unlocked(unlocks, "armors", str(equipment.get("selected_armor", "")))
	_ensure_unlocked(unlocks, "chips", str(equipment.get("selected_chip", "")))
	_ensure_unlocked(unlocks, "pets", str(equipment.get("selected_pet", "")))
	shot_save["unlocks"] = unlocks
	save_manager.save_data = shot_save

func _apply_save_override(save_manager: Node, save_override: Dictionary) -> void:
	var shot_save: Dictionary = save_manager.save_data.duplicate(true)
	for key in save_override.keys():
		if shot_save.has(key) and shot_save[key] is Dictionary and save_override[key] is Dictionary:
			var nested: Dictionary = shot_save[key].duplicate(true)
			nested.merge(save_override[key], true)
			shot_save[key] = nested
		else:
			shot_save[key] = save_override[key]
	save_manager.save_data = shot_save

func _ensure_unlocked(unlocks: Dictionary, key: String, item_id: String) -> void:
	if item_id == "":
		return
	var items: Array = unlocks.get(key, []).duplicate()
	if not items.has(item_id):
		items.append(item_id)
	unlocks[key] = items

func _prepare_dense_combat(battle: Node) -> void:
	battle.pending_spawns.clear()
	battle.active_spawning = false
	for enemy in battle.get_node("EnemyLayer").get_children():
		enemy.queue_free()
	for marker in battle.get_node("ThreatMarkerLayer").get_children():
		marker.queue_free()
	await process_frame
	await process_frame
	var ids := [
		"zombie_runner", "zombie_shambler", "zombie_armored", "zombie_spitter",
		"zombie_crawler", "zombie_bomber", "zombie_shielder", "zombie_mutant",
		"zombie_runner", "zombie_brute", "zombie_charger", "zombie_screamer",
		"zombie_shambler", "zombie_warden", "zombie_toxic", "zombie_hopper",
	]
	var frontline: Node = null
	for index in range(ids.size()):
		var column := index % 4
		var row := int(index / 4)
		var position := Vector2(145.0 + float(column) * 255.0, 250.0 + float(row) * 230.0)
		var enemy: Node = battle.call("_spawn_enemy_instance", ids[index], position, false, 0.0)
		if index == 13:
			frontline = enemy
	if frontline != null and battle.target_manager != null:
		battle.target_manager.lock_enemy(frontline)
	battle.call("_update_combat_information_density", 0.0, true)
	var priority: Array[Node] = battle.call("_combat_information_priority", battle.get_node("EnemyLayer").get_children())
	var visible_markers := 0
	for marker in battle.get_node("ThreatMarkerLayer").get_children():
		if marker is CanvasItem and marker.visible:
			visible_markers += 1
	print("dense combat label audit: enemies=%d priorities=%d visible_threat_markers=%d" % [
		battle.get_node("EnemyLayer").get_child_count(),
		priority.size(),
		visible_markers,
	])

func _prepare_store_combat(battle: Node) -> void:
	# Deterministic marketing capture made only from live battle systems. It
	# stages a readable mid-density lane, an explicit frontline lock and a real
	# active-skill cast so the first App Store screenshot proves the claim in
	# its headline instead of showing a nearly empty battlefield.
	battle.pending_spawns.clear()
	battle.active_spawning = false
	for enemy in battle.get_node("EnemyLayer").get_children():
		enemy.queue_free()
	for marker in battle.get_node("ThreatMarkerLayer").get_children():
		marker.queue_free()
	await process_frame
	await process_frame
	battle.wave_index = 4
	battle.wave_total = 5
	battle.onboarding_tip_shown = true
	battle.pending_wave_toast = {}
	battle.pending_wave_toast_timer_active = false
	battle.last_wave_toast_at = -99.0
	battle._hide_wave_toast()
	for skill_id in ["skill_incendiary", "skill_split_shot", "skill_slow_field"]:
		if battle.skills.level(skill_id) <= 0:
			battle.skills.add_skill(skill_id)
	battle._update_skill_slots()
	battle._update_hud()
	var formation := [
		["zombie_armored", Vector2(190, 300)],
		["zombie_spitter", Vector2(455, 350)],
		["zombie_shielder", Vector2(760, 315)],
		["zombie_runner", Vector2(875, 545)],
		["zombie_bomber", Vector2(270, 620)],
		["zombie_mutant", Vector2(650, 690)],
		["zombie_charger", Vector2(810, 850)],
		["zombie_runner", Vector2(520, 910)],
	]
	var frontline: Node = null
	for index in range(formation.size()):
		var item: Array = formation[index]
		var position: Vector2 = item[1]
		var enemy: Node = battle._spawn_enemy_instance(str(item[0]), position, false, 0.0)
		if enemy == null:
			continue
		enemy.max_hp *= 4.0
		enemy.hp = enemy.max_hp
		enemy.speed *= 0.18
		if enemy.has_method("_update_hp_bar"):
			enemy.call("_update_hp_bar")
		if index == formation.size() - 1:
			frontline = enemy
	if frontline != null and battle.target_manager != null:
		battle.target_manager.lock_enemy(frontline)
	battle._update_combat_information_density(0.0, true)
	battle._update_lock_indicator()
	battle._show_wave_toast("已锁定近线威胁 · 集火击破", Color(1.0, 0.76, 0.24))
	print("store combat audit: enemies=%d locked=%s skills=%s" % [
		battle.get_node("EnemyLayer").get_child_count(),
		str(battle.target_manager.has_lock()),
		str(battle.skills.owned),
	])

func _prepare_isolated_vfx_stage(battle: Node, spawn_target: bool) -> void:
	battle.pending_spawns.clear()
	battle.active_spawning = false
	battle.turret.set("fire_enabled", false)
	battle.turret.set_physics_process(false)
	for enemy in battle.get_node("EnemyLayer").get_children():
		enemy.queue_free()
	for marker in battle.get_node("ThreatMarkerLayer").get_children():
		marker.queue_free()
	for projectile in battle.get_node("ProjectileLayer").get_children():
		projectile.queue_free()
	await process_frame
	await process_frame
	battle.onboarding_tip_shown = true
	battle.pending_wave_toast = {}
	battle.pending_wave_toast_timer_active = false
	battle.call("_hide_wave_toast")
	if not spawn_target:
		return
	var target: Node = battle.call("_spawn_enemy_instance", "zombie_shambler", Vector2(540, 760), false, 0.0)
	if target != null and is_instance_valid(target):
		target.speed = 0.0
		target.max_hp *= 20.0
		target.hp = target.max_hp
		if target.has_method("_update_hp_bar"):
			target.call("_update_hp_bar")

func _current_collection_table(mode: String) -> Dictionary:
	match mode:
		"characters":
			return root.get_node("/root/DataLoader").get_table("characters")
		"weapons":
			return root.get_node("/root/DataLoader").get_table("weapons")
		"armors":
			return root.get_node("/root/DataLoader").get_table("armors")
		"chips":
			return root.get_node("/root/DataLoader").get_table("chips")
		"pets":
			return root.get_node("/root/DataLoader").get_table("pets")
		"skills":
			return root.get_node("/root/DataLoader").get_table("skills")
		_:
			return {}
