extends SceneTree

# Visual capture helper: loads a scene through the real router and screenshots the
# viewport so container-layout refactors can be verified, not just smoke-compiled.
# Usage: godot --path . --script tools/_shot.gd -- <route> [payload_json] [out_png]

const StatusVfxControllerScript := preload("res://gameplay/vfx/status_vfx_controller.gd")
const UiKit := preload("res://ui/ui_kit.gd")

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
	if payload.has("language"):
		root.get_node("/root/LocalizationManager").apply_language(str(payload.get("language", "zh")), false)
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
	root.get_node("/root/ThemeManager").refresh_from_save()
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
	if payload.has("debug_status_vfx_showcase") and main.current_scene != null and main.current_scene.has_method("_spawn_enemy_instance"):
		await _prepare_status_vfx_showcase(
			main.current_scene,
			str(payload.get("debug_status_vfx_showcase", "single"))
		)
	if payload.has("debug_zombie_model_showcase") and main.current_scene != null and main.current_scene.has_method("_spawn_enemy_instance"):
		await _prepare_zombie_model_showcase(
			main.current_scene,
			str(payload.get("debug_zombie_model_showcase", "redesigned"))
		)
	if payload.has("debug_zombie_attack_showcase") and main.current_scene != null and main.current_scene.has_method("_spawn_enemy_instance"):
		await _prepare_zombie_attack_showcase(
			main.current_scene,
			int(payload.get("debug_zombie_attack_showcase", 0))
		)
	if payload.has("debug_character_shooting_frame") and main.current_scene != null and main.current_scene.has_method("_character_combo_attack_frames"):
		await _prepare_character_shooting_showcase(
			main.current_scene,
			int(payload.get("debug_character_shooting_frame", 3)),
			str(payload.get("debug_character_shooting_aim", "center")),
			bool(payload.get("debug_character_shooting_muzzle", false))
		)
	if bool(payload.get("debug_cast_active", false)) and main.current_scene != null and main.current_scene.has_method("_on_character_skill_pressed"):
		main.current_scene.character_active_cd = 0.0
		main.current_scene.call("_on_character_skill_pressed")
	if bool(payload.get("debug_boss_skill", false)) and main.current_scene != null and main.current_scene.has_method("_announce_boss_phase"):
		main.current_scene.turret.set("fire_enabled", false)
		main.current_scene.turret.set_physics_process(false)
		var skill_boss: Node = main.current_scene.get("active_boss")
		if skill_boss != null and is_instance_valid(skill_boss):
			main.current_scene.call("_announce_boss_phase", skill_boss, "技能释放", Color(0.86, 0.96, 1.0, 1.0))
	if bool(payload.get("debug_boss_phase", false)) and main.current_scene != null and main.current_scene.has_method("_announce_boss_phase"):
		var phase_boss: Node = main.current_scene.get("active_boss")
		if phase_boss != null and is_instance_valid(phase_boss):
			main.current_scene.call("_announce_boss_phase", phase_boss, "进入二阶段", Color(1.0, 0.72, 0.24, 1.0))
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
				if hit_kind == "starter_autocannon":
					var shot_origin: Vector2 = main.current_scene.call("_weapon_fire_origin")
					var hit_position := (hit_enemy as Node2D).global_position
					var shot_direction: Vector2 = (hit_position - shot_origin).normalized()
					main.current_scene.call(
						"_spawn_projectile",
						shot_origin,
						shot_direction,
						10.0,
						0,
						0,
						0.55,
						0.0,
						0.0,
						0.0,
						1.0,
						"autocannon",
						0.0,
						0.0,
						hit_enemy
					)
					var projectile_layer: Node = main.current_scene.get_node("ProjectileLayer")
					var projectile: Node = null
					for child in projectile_layer.get_children():
						if child.has_method("_hit") and str(child.get("visual_profile")) == "autocannon":
							projectile = child
							break
					if projectile != null:
						projectile.call("_hit", hit_enemy)
					await process_frame
					paused = true
				elif hit_kind == "crit":
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
				skill_enemy.global_position + Vector2(0, -42),
				Vector2.DOWN
			)
	if payload.has("debug_projectile_showcase") and main.current_scene != null:
		main.current_scene.turret.set("fire_enabled", false)
		main.current_scene.turret.set_physics_process(false)
		var projectile_kind := str(payload.get("debug_projectile_showcase", "acid_spit"))
		if projectile_kind == "acid_spit" and main.current_scene.has_method("_spawn_spit_attack_vfx"):
			var projectile_enemy: Node = main.current_scene.get_node("EnemyLayer").get_child(0) if main.current_scene.get_node("EnemyLayer").get_child_count() > 0 else null
			if projectile_enemy != null and is_instance_valid(projectile_enemy):
				main.current_scene.call(
					"_spawn_spit_attack_vfx",
					projectile_enemy,
					projectile_enemy.global_position + Vector2(0, 620)
				)
		elif projectile_kind == "split_mini" and main.current_scene.has_method("_on_projectile_split_requested"):
			main.current_scene.call(
				"_on_projectile_split_requested",
				Vector2(540, 1320),
				Vector2.UP,
				3,
				10.0,
				"physical",
				0.0,
				1.0
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
	if bool(payload.get("debug_pet_repair", false)) and main.current_scene != null and main.current_scene.has_method("_process_repair_pet"):
		main.current_scene.base_hp = int(round(float(main.current_scene.base_hp_max) * float(payload.get("debug_pet_hp_ratio", 0.30))))
		main.current_scene.pet_repair_cooldown = 999.0
		main.current_scene.pet_emergency_cooldown = 0.0
		main.current_scene.call("_process_repair_pet", 0.01)
		for i in range(3):
			await process_frame
	if bool(payload.get("debug_pet_skill", false)) and main.current_scene != null and main.current_scene.has_method("_process_pet_skill"):
		await _prepare_pet_skill_showcase(main.current_scene)
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
	if payload.has("purchase_item") and main.current_scene != null and main.current_scene.has_method("_purchase_item_flow"):
		var purchase_item := str(payload.get("purchase_item", ""))
		var purchase_table: Dictionary = _current_collection_table(str(payload.get("mode", "")))
		if purchase_item != "" and purchase_table.has(purchase_item):
			main.current_scene.call("_purchase_item_flow", purchase_item, purchase_table[purchase_item])
			for i in range(12):
				await process_frame
	if bool(payload.get("card_offer", false)) and main.current_scene != null and main.current_scene.has_method("_show_card_offer"):
		main.current_scene.call("_show_card_offer")
		if payload.get("debug_card_offer_skills", []) is Array:
			var cards := main.current_scene.get_node_or_null("Hud/CardPanel/Cards") as VBoxContainer
			if cards != null:
				for child in cards.get_children():
					child.queue_free()
				var data_loader := root.get_node("/root/DataLoader")
				for raw_skill_id in payload.get("debug_card_offer_skills", []):
					var skill_id := str(raw_skill_id)
					var row: Dictionary = data_loader.get_row("skills", skill_id)
					if row.is_empty():
						continue
					var level_value := int(main.current_scene.call("_skill_offer_level", skill_id))
					var display_name: String = str(data_loader.tr_key(row.get("name_key", skill_id)))
					cards.add_child(main.current_scene.call(
						"_build_skill_card",
						skill_id,
						row,
						display_name,
						level_value
					))
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
	if bool(payload.get("debug_character_skill_hint", false)) and main.current_scene != null and main.current_scene.has_method("_show_character_skill_hint"):
		main.current_scene.call("_show_character_skill_hint")
		for i in range(3):
			await process_frame
	_emit_final_ui_audit(main, route)
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

func _emit_final_ui_audit(main: Node, route: String) -> void:
	if OS.get_environment("ZOMBIE_FIRE_UI_AUDIT") != "1" or main == null or main.current_scene == null:
		return
	var roots: Array[Control] = []
	if main.current_scene is Control:
		roots.append(main.current_scene as Control)
	else:
		for child in main.current_scene.get_children():
			if child is Control:
				roots.append(child as Control)
			elif child is CanvasLayer:
				for grandchild in child.get_children():
					if grandchild is Control:
						roots.append(grandchild as Control)
	var issues: Array[String] = []
	var insets := UiKit.safe_area_canvas_insets(root.get_viewport())
	for control_root in roots:
		for issue in UiKit.audit_ui(control_root, insets):
			if not issues.has(issue):
				issues.append(issue)
	print("UI_AUDIT_JSON:", JSON.stringify({"route": route, "issues": issues, "insets": [insets.x, insets.y, insets.z, insets.w], "final": true}))

func _prepare_pet_skill_showcase(battle: Node) -> void:
	battle.set_physics_process(false)
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
	var positions := [
		Vector2(540, 690),
		Vector2(420, 620),
		Vector2(660, 620),
		Vector2(420, 760),
		Vector2(660, 760),
		Vector2(540, 840),
	]
	var spawned: Array[Node] = []
	for i in range(positions.size()):
		var enemy: Node = battle.call(
			"_spawn_enemy_instance",
			"zombie_brute" if i % 2 == 0 else "zombie_shambler",
			positions[i],
			false,
			0.0
		)
		if enemy == null:
			continue
		enemy.speed = 0.0
		enemy.max_hp *= 80.0
		enemy.hp = enemy.max_hp
		enemy.call("set_combat_label_visibility", false, false)
		enemy.call("_update_hp_bar")
		spawned.append(enemy)
	for _entry_frame in range(24):
		await process_frame
	if not spawned.is_empty() and battle.target_manager != null:
		battle.target_manager.lock_enemy(spawned[0])
	battle.pet_skill_cooldown = 0.0
	if str(battle.pet_data.get("pet_skill", {}).get("kind", "")) == "wave_salvage":
		battle.call("_apply_pet_wave_salvage")
	else:
		battle.call("_process_pet_skill", 0.01)
	for _frame in range(1):
		await process_frame

func _cleanup_scene(main: Node) -> void:
	paused = false
	Engine.time_scale = 1.0
	if main != null and is_instance_valid(main):
		main.queue_free()
	var audio := root.get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("release_for_tests"):
		audio.release_for_tests()
	StatusVfxControllerScript.release_cached_resources_for_tests()
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

func _prepare_character_shooting_showcase(battle: Node, one_based_frame: int, aim: String, show_muzzle: bool) -> void:
	battle.pending_spawns.clear()
	battle.active_spawning = false
	battle.onboarding_tip_shown = true
	battle.pending_wave_toast = {}
	battle.pending_wave_toast_timer_active = false
	battle.call("_hide_wave_toast")
	for enemy in battle.get_node("EnemyLayer").get_children():
		enemy.queue_free()
	for marker in battle.get_node("ThreatMarkerLayer").get_children():
		marker.queue_free()
	for projectile in battle.get_node("ProjectileLayer").get_children():
		projectile.queue_free()
	await process_frame
	await process_frame
	battle.turret.set("fire_enabled", false)
	battle.turret.set_physics_process(false)
	match aim:
		"left":
			battle.call("_set_character_combo_aim_from_direction", Vector2(-0.62, -0.78))
		"right":
			battle.call("_set_character_combo_aim_from_direction", Vector2(0.62, -0.78))
		_:
			battle.call("_set_character_combo_aim_from_direction", Vector2.UP)
	battle.character_weapon_combo_locked_aim = battle.character_weapon_combo_aim
	var frames: Array[Texture2D] = battle.call("_character_combo_attack_frames")
	var frame_index := clampi(one_based_frame - 1, 0, maxi(frames.size() - 1, 0))
	if not frames.is_empty():
		battle.character_anim_frame = frame_index
		battle.character_sprite.texture = frames[frame_index]
	battle.character_attack_duration = float(battle.CHARACTER_WEAPON_ATTACK_DURATION.get(battle.weapon_id, 0.32))
	battle.character_attack_time = battle.character_attack_duration * 0.58
	battle.call("_update_character_body_pose")
	if show_muzzle:
		var origin: Vector2 = battle.call("_weapon_fire_origin")
		var direction: Vector2 = battle.call("_weapon_fire_direction", Vector2.UP)
		var data_loader := root.get_node("/root/DataLoader")
		var element := str(data_loader.get_row("weapons", battle.weapon_id).get("element", "physical"))
		battle.call("_spawn_muzzle_flash", origin, direction, element, battle.call("_weapon_visual_profile", battle.weapon_id))
		battle.call("_pulse_neon_tempest_character")
		battle.call("_spawn_neon_tempest_fire_signature", origin, direction, element)
		if battle.get("character_neon_fire_aura") is AnimatedSprite2D:
			var neon_aura := battle.get("character_neon_fire_aura") as AnimatedSprite2D
			neon_aura.stop()
			neon_aura.frame = mini(2, neon_aura.sprite_frames.get_frame_count("fire") - 1)
			neon_aura.visible = true
	battle.set_process(false)
	battle.set_physics_process(false)
	# Let the renderer consume the explicitly assigned frame. Without this,
	# the property path is correct but the screenshot can still contain the
	# previous draw command from the warm-up frame.
	await process_frame
	await process_frame
	print("character shooting audit: character=%s weapon=%s aim=%s effective=%s frame=%d muzzle=%s flip_h=%s scale=%s rig_scale=%s battle_scale=%s global_x=%s global_y=%s texture=%s" % [
		battle.character_id,
		battle.weapon_id,
		aim,
		str(battle.call("_character_combo_effective_aim")),
		frame_index + 1,
		str(show_muzzle),
		str(battle.character_sprite.flip_h),
		str(battle.character_sprite.scale),
		str(battle.character_rig.scale),
		str(battle.scale),
		str(battle.character_sprite.global_transform.x),
		str(battle.character_sprite.global_transform.y),
		str(battle.character_sprite.texture.resource_path),
	])

func _prepare_status_vfx_showcase(battle: Node, mode: String) -> void:
	battle.set_physics_process(false)
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

	var staged: Array[Dictionary] = []
	match mode:
		"stacked":
			staged = [
				{"id": "zombie_brute", "position": Vector2(270, 520), "statuses": ["fire", "poison"]},
				{"id": "zombie_armored", "position": Vector2(805, 520), "statuses": ["ice", "lightning"]},
				{"id": "zombie_mutant", "position": Vector2(270, 940), "statuses": ["fire", "ice", "poison"]},
				{"id": "boss_tank_titan", "position": Vector2(775, 920), "statuses": ["fire", "ice", "poison", "lightning"], "boss": true},
			]
		"dense":
			var ids := ["zombie_runner", "zombie_shambler", "zombie_brute", "zombie_toxic"]
			var statuses := ["fire", "ice", "poison", "lightning"]
			for index in range(36):
				staged.append({
					"id": ids[index % ids.size()],
					"position": Vector2(115 + (index % 6) * 170, 265 + int(index / 6) * 188),
					"statuses": [statuses[index % statuses.size()]],
				})
		_:
			staged = [
				{"id": "zombie_brute", "position": Vector2(275, 500), "statuses": ["fire"]},
				{"id": "zombie_armored", "position": Vector2(805, 500), "statuses": ["ice"]},
				{"id": "zombie_toxic", "position": Vector2(275, 960), "statuses": ["poison"]},
				{"id": "zombie_shielder", "position": Vector2(805, 960), "statuses": ["lightning"]},
			]

	var spawned: Array[Node] = []
	for spec in staged:
		var is_boss := bool(spec.get("boss", false))
		var enemy: Node = battle.call(
			"_spawn_enemy_instance",
			str(spec.get("id", "zombie_shambler")),
			spec.get("position", Vector2(540, 720)),
			is_boss,
			0.0
		)
		if enemy == null:
			continue
		enemy.speed = 0.0
		enemy.max_hp *= 40.0
		enemy.hp = enemy.max_hp
		enemy.call("set_combat_label_visibility", false, mode != "dense")
		for status_id_var in spec.get("statuses", []):
			var status_id := str(status_id_var)
			if status_id in ["fire", "ice", "lightning"]:
				enemy.call("amplify_character_status", status_id, 80.0, 3, 0.12)
			else:
				enemy.call("_apply_element_status", 80.0, status_id, 0.35)
		enemy.call("_update_hp_bar")
		spawned.append(enemy)

	battle.call("_update_combat_information_density", 0.0, true, battle.get_node("EnemyLayer").get_children())
	if mode != "dense":
		for enemy in spawned:
			enemy.call("set_combat_label_visibility", false, true)
	print("status VFX audit: mode=%s enemies=%d" % [mode, spawned.size()])

func _prepare_zombie_model_showcase(battle: Node, mode: String) -> void:
	# Deterministic runtime lineup for reviewing the actual imported animation
	# frames at phone scale. It changes no campaign spawn or balance data.
	battle.set_physics_process(false)
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

	var redesigned := [
		"zombie_bomber",
		"zombie_spitter",
		"zombie_juggernaut",
		"zombie_necromancer",
		"zombie_charger",
		"zombie_regenerator",
		"zombie_splitter",
		"zombie_warden",
	]
	var roster := [
		"zombie_shambler", "zombie_runner", "zombie_brute", "zombie_bomber", "zombie_screamer",
		"zombie_spitter", "zombie_crawler", "zombie_armored", "zombie_shielder", "zombie_hopper",
		"zombie_juggernaut", "zombie_phantom", "zombie_necromancer", "zombie_toxic", "zombie_charger",
		"zombie_regenerator", "zombie_splitter", "zombie_warden", "zombie_mutant", "zombie_berserker",
	]
	var ids: Array = redesigned
	var columns := 4
	var start_x := 175.0
	var step_x := 243.0
	var start_y := 420.0
	var step_y := 480.0
	if mode == "roster":
		ids = roster
		columns = 5
		start_x = 120.0
		step_x = 210.0
		start_y = 300.0
		step_y = 315.0
	elif mode == "dense":
		ids = []
		for index in range(24):
			ids.append(roster[index % roster.size()])
		columns = 6
		start_x = 120.0
		step_x = 168.0
		start_y = 270.0
		step_y = 300.0

	var spawned := 0
	for index in range(ids.size()):
		var column := index % columns
		var row := int(index / columns)
		var enemy: Node = battle.call(
			"_spawn_enemy_instance",
			str(ids[index]),
			Vector2(start_x + float(column) * step_x, start_y + float(row) * step_y),
			false,
			0.0
		)
		if enemy == null:
			continue
		enemy.speed = 0.0
		enemy.max_hp *= 40.0
		enemy.hp = enemy.max_hp
		enemy.set_physics_process(false)
		enemy.call("set_combat_label_visibility", false, false)
		enemy.call("_update_hp_bar")
		spawned += 1
	print("zombie model audit: mode=%s enemies=%d" % [mode, spawned])

func _prepare_zombie_attack_showcase(battle: Node, group_index: int) -> void:
	# Three real runtime sprites per identity expose anticipation/contact/recovery
	# together. This catches wrong imports, phone-scale readability and baseward
	# direction without relying on a source-art contact sheet.
	battle.set_physics_process(false)
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

	var roster := [
		"zombie_shambler", "zombie_runner", "zombie_brute", "zombie_bomber", "zombie_screamer",
		"zombie_spitter", "zombie_crawler", "zombie_armored", "zombie_shielder", "zombie_hopper",
		"zombie_juggernaut", "zombie_phantom", "zombie_necromancer", "zombie_toxic", "zombie_charger",
		"zombie_regenerator", "zombie_splitter", "zombie_warden", "zombie_mutant", "zombie_berserker",
	]
	var start := clampi(group_index, 0, 3) * 5
	var stage_frames := [0, 3, 5]
	var stage_x := [210.0, 540.0, 870.0]
	var spawned := 0
	for row_index in range(5):
		var zombie_id := str(roster[start + row_index])
		for stage_index in range(stage_frames.size()):
			var enemy: Node = battle.call(
				"_spawn_enemy_instance",
				zombie_id,
				Vector2(stage_x[stage_index], 330.0 + float(row_index) * 275.0),
				false,
				0.0
			)
			if enemy == null:
				continue
			enemy.speed = 0.0
			enemy.max_hp *= 40.0
			enemy.hp = enemy.max_hp
			enemy.set_physics_process(false)
			enemy.call("set_combat_label_visibility", false, false)
			var frames: Array = enemy.get("_attack_frames")
			var frame_index := int(stage_frames[stage_index])
			var sprite := enemy.get_node("Sprite") as Sprite2D
			if sprite != null and frame_index < frames.size():
				sprite.texture = frames[frame_index]
				if stage_index == 1:
					var profile: Dictionary = enemy.get("attack_animation_profile")
					sprite.position.y = float(profile.get("lunge", 18.0))
			var hp_bg: TextureRect = enemy.get("_hp_bg")
			var hp_fill: TextureRect = enemy.get("_hp_fill")
			var rank_aura: Sprite2D = enemy.get("_rank_aura")
			if hp_bg != null:
				hp_bg.visible = false
			if hp_fill != null:
				hp_fill.visible = false
			if rank_aura != null:
				rank_aura.visible = false
			spawned += 1
	for effect in battle.get_node("ProjectileLayer").get_children():
		effect.queue_free()
	await process_frame
	print("zombie attack audit: group=%d identities=5 sprites=%d" % [group_index, spawned])

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
