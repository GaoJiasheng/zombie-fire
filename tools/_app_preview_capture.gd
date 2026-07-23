extends SceneTree

const DURATION_SECONDS := 22.0

class PreviewRouter:
	extends Node
	var last_result := {}
	func finish_level(result: Dictionary) -> void:
		last_result = result

var battle: Node
var router: Node
var elapsed := 0.0
var triggered := {}
var showcase_enemies: Array[Node] = []

func _initialize() -> void:
	call_deferred("_start_capture")

func _start_capture() -> void:
	var data_loader := root.get_node("DataLoader")
	var save_manager := root.get_node("SaveManager")
	data_loader.load_all()
	save_manager.load_game()
	var preview_save: Dictionary = save_manager._default_save()
	var equipment: Dictionary = preview_save.get("equipment", {}).duplicate(true)
	equipment["selected_character"] = "blaze"
	equipment["selected_weapon"] = "weapon_plasmacannon"
	preview_save["equipment"] = equipment
	save_manager.save_data = preview_save
	router = PreviewRouter.new()
	root.add_child(router)
	var packed := load("res://gameplay/battle/battle.tscn") as PackedScene
	battle = packed.instantiate()
	battle.setup(router, {"level_id": "level_045"})
	root.add_child(battle)
	await process_frame
	await physics_frame
	battle.battle_speed = 1.0
	Engine.time_scale = 1.0
	battle.pending_spawns.clear()
	# Keep the authored campaign spawner suspended during the curated capture.
	# A long spawn timer preserves the real battle loop without allowing the
	# empty transition between showcase beats to auto-start another wave.
	battle.active_spawning = true
	battle.spawn_timer = 9999.0
	battle.onboarding_tip_shown = true
	battle._hide_wave_toast()
	for enemy in battle.get_node("EnemyLayer").get_children():
		enemy.queue_free()
	for marker in battle.get_node("ThreatMarkerLayer").get_children():
		marker.queue_free()
	await process_frame
	await process_frame
	battle.wave_index = 2
	battle.base_hp_max = 1000
	battle.base_hp = 1000
	battle.skills.add_skill("skill_incendiary")
	battle.skills.add_skill("skill_split_shot")
	battle.skills.add_skill("skill_slow_field")
	battle._update_skill_slots()
	battle._update_hud()
	_spawn_opening_squad()

func _process(delta: float) -> bool:
	if battle == null or not is_instance_valid(battle):
		return false
	elapsed += delta
	# Put the defining manual-lock interaction inside the first second so both
	# autoplay and the selectable poster frame communicate the core mechanic
	# before a viewer can scroll past.
	if elapsed >= 0.7 and not triggered.has("lock"):
		triggered["lock"] = true
		_lock_frontline_target()
	if elapsed >= 5.0 and not triggered.has("cards"):
		triggered["cards"] = true
		battle._show_card_offer()
	if elapsed >= 8.0 and not triggered.has("pick"):
		triggered["pick"] = true
		battle._choose_card("skill_slow_field")
	if elapsed >= 8.5 and not triggered.has("clear"):
		triggered["clear"] = true
		_clear_showcase_enemies()
	if elapsed >= 9.4 and not triggered.has("boss"):
		triggered["boss"] = true
		_spawn_boss_squad()
	if elapsed >= 13.0 and not triggered.has("phase"):
		triggered["phase"] = true
		if battle.active_boss != null and is_instance_valid(battle.active_boss):
			battle.active_boss.hp = battle.active_boss.max_hp * 0.62
	if elapsed >= 15.0 and not triggered.has("active"):
		triggered["active"] = true
		battle.character_active_cd = 0.0
		battle._on_character_skill_pressed()
	if elapsed >= 17.6 and not triggered.has("final_wave"):
		triggered["final_wave"] = true
		_spawn_final_pressure()
	if elapsed >= DURATION_SECONDS:
		if not triggered.has("finish"):
			triggered["finish"] = true
			call_deferred("_finish_capture")
	return false

func _spawn_opening_squad() -> void:
	if not is_instance_valid(battle):
		return
	var formation := [
		["zombie_shambler", Vector2(180, 300)],
		["zombie_runner", Vector2(430, 390)],
		["zombie_armored", Vector2(700, 300)],
		["zombie_spitter", Vector2(875, 520)],
		["zombie_bomber", Vector2(300, 650)],
		["zombie_shielder", Vector2(620, 760)],
	]
	for item in formation:
		var position: Vector2 = item[1]
		var enemy: Node = battle._spawn_enemy_instance(str(item[0]), position, false, 0.0)
		showcase_enemies.append(enemy)
	battle._update_combat_information_density(0.0, true)

func _lock_frontline_target() -> void:
	var best: Node2D = null
	for enemy in showcase_enemies:
		if not is_instance_valid(enemy) or not (enemy is Node2D):
			continue
		if best == null or enemy.global_position.y > best.global_position.y:
			best = enemy
	if best != null:
		battle.target_manager.lock_enemy(best)
		battle._update_combat_information_density(0.0, true)
		battle._update_lock_indicator()

func _clear_showcase_enemies() -> void:
	for enemy in showcase_enemies:
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		enemy.take_damage(float(enemy.max_hp) * 3.0, "fire")
	showcase_enemies.clear()
	battle.target_manager.clear_lock()

func _spawn_boss_squad() -> void:
	var formation := [
		["zombie_shielder", Vector2(190, 430)],
		["zombie_mutant", Vector2(850, 430)],
		["zombie_spitter", Vector2(300, 680)],
		["zombie_runner", Vector2(760, 730)],
	]
	for item in formation:
		var position: Vector2 = item[1]
		showcase_enemies.append(battle._spawn_enemy_instance(str(item[0]), position, false, 0.0))
	var boss: Node = battle._spawn_enemy_instance("boss_inferno_maw", Vector2(540, 320), true, 0.0)
	showcase_enemies.append(boss)
	battle.target_manager.lock_enemy(boss)
	battle._update_combat_information_density(0.0, true)

func _spawn_final_pressure() -> void:
	var ids := [
		"zombie_runner", "zombie_armored", "zombie_crawler", "zombie_bomber",
		"zombie_shielder", "zombie_mutant", "zombie_charger", "zombie_screamer",
	]
	for index in range(ids.size()):
		var x := 150.0 + float(index % 4) * 255.0
		var y := 230.0 + float(index / 4) * 220.0
		showcase_enemies.append(battle._spawn_enemy_instance(ids[index], Vector2(x, y), false, 0.0))
	battle._update_combat_information_density(0.0, true)

func _finish_capture() -> void:
	Engine.time_scale = 1.0
	if battle != null and is_instance_valid(battle):
		battle.queue_free()
	if router != null and is_instance_valid(router):
		router.queue_free()
	var audio := root.get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("release_for_tests"):
		audio.release_for_tests()
	for i in range(4):
		await process_frame
	quit(0)
