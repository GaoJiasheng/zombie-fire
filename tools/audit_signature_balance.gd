extends "res://tools/frontline_runtime_probe.gd"

## Same executable against an isolated before snapshot and current source.
## Bench: real Enemy DOT/status, fixed immortal targets, one cast, no gunfire.
## Campaign: inherited deterministic real-battle runner and card policy.
func _initialize() -> void:
	await process_frame
	root.get_node("DataLoader").load_all()
	var save: Node = root.get_node("SaveManager")
	_snapshot = save.save_data.duplicate(true)
	var output := "/tmp/signature_balance.json"
	var campaign := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
		if arg == "--campaign":
			campaign = true
	var rows: Array = []
	if campaign:
		_profile_id = "tier_b"
		_card_policy_id = "v2"
		_wall_acceleration = 20.0
		Engine.physics_ticks_per_second = 1200
		var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://design/audits/campaign_progression_fixture_builds.json"))
		for hero in ["vanguard", "blaze", "frost", "volt"]:
			for level_number in [1, 5, 10, 99]:
				var fixture: Dictionary = {}
				for candidate in source.rows:
					if int(candidate.level) == level_number:
						fixture = candidate.duplicate(true)
				fixture.build.character = hero
				for seed_value in [1103, 2207]:
					var result: Dictionary = await _run_level(save, fixture, seed_value)
					rows.append(result)
					print("CAMPAIGN ", hero, " ", level_number, " ", seed_value, " win=", result.victory, " hp=", result.base_ratio, " seconds=", result.elapsed_seconds)
					_write_audit(output, rows)
	else:
		for hero in ["vanguard", "blaze", "frost", "volt"]:
			for levels in [[1, 0], [1, 1], [40, 5]]:
				for arrangement in ["single", "cluster", "spread"]:
					rows.append(await _bench(save, hero, levels[0], levels[1], arrangement))
		_write_audit(output, rows)
	save.save_data = _snapshot
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	root.get_node("AudioManager").release_for_tests()
	for tween in get_processed_tweens():
		tween.kill()
	UiKit.release_cached_resources_for_tests()
	load("res://gameplay/vfx/sequence_vfx.gd").release_cached_resources_for_tests()
	load("res://gameplay/vfx/status_vfx_controller.gd").release_cached_resources_for_tests()
	print("SIGNATURE_AUDIT_PASS rows=", rows.size())
	quit()

func _write_audit(path: String, rows: Array) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"rows": rows}, "\t"))

func _bench(save: Node, hero: String, hero_level: int, signature_level: int, arrangement: String) -> Dictionary:
	var build := {"character": hero, "character_level": hero_level, "weapon": "weapon_autocannon", "weapon_level": 1, "signature_level": signature_level}
	save.save_data = _save_for_build(save, {"build": build})
	var battle: Node = load(BATTLE_SCENE_PATH).instantiate()
	var router := ProbeRouter.new()
	root.add_child(router)
	battle.set_audit_combat_seed(73001)
	battle.set_physics_process(false)
	battle.setup(router, {"level_id": "level_001"})
	root.add_child(battle)
	await process_frame
	_disable_battle_process_frames(battle)
	battle._set_fire_rate_profile("tier_b")
	battle.set_physics_process(false)
	battle.turret.set_physics_process(false)
	battle.turret.fire_enabled = false
	battle.primary_weakness = "none"
	battle.card_offer_active = false
	battle.paused = false
	paused = false
	for enemy in battle.get_node("EnemyLayer").get_children():
		enemy.free()
	var count := 1 if arrangement == "single" else 8
	var enemies: Array[Node] = []
	for i in range(count):
		var pos := Vector2(540, 850)
		if arrangement == "cluster":
			pos += Vector2((i % 4 - 1.5) * 65, (i / 4) * 70)
		elif arrangement == "spread":
			pos = Vector2(220 + (i % 2) * 640, 350 + (i / 2) * 310)
		var enemy: Node = battle._spawn_enemy_instance("zombie_shambler", pos)
		enemy.set_physics_process(false)
		enemy.set_process(false)
		enemy.hp = 100000000.0
		enemy.max_hp = 100000000.0
		enemy.armor_hp = 0.0
		enemy.weakness = "none"
		enemy.resist = "none"
		enemy.boss = arrangement == "single"
		enemies.append(enemy)
	battle._on_character_skill_pressed()
	for step in range(900):
		battle._process_character_signatures(1.0 / 60.0)
		battle._audit_process_delayed_skill_callbacks(1.0 / 60.0)
		for enemy in enemies:
			enemy.speed_mult = 1.0
			enemy._process_element_status(1.0 / 60.0)
	var damage := 0.0
	var hits: Array = []
	for enemy in enemies:
		var amount := 100000000.0 - float(enemy.hp)
		hits.append(amount)
		damage += amount
	var active: Dictionary = battle.character_data.get("active_skill", {})
	var neutral_gun_dps := float(battle._current_primary_shot_damage("physical", false)) * float(battle.turret.fire_rate) * (1.0 + float(battle.crit_rate) * (float(battle.skills.crit_damage_mult()) - 1.0))
	var result := {"character": hero, "character_level": hero_level, "signature_level": signature_level, "arrangement": arrangement, "damage": damage, "per_target": hits, "cooldown": battle._active_skill_cooldown(active), "neutral_gun_expected_dps": neutral_gun_dps}
	assert(damage > 0.0, "invalid bench: a skill must hit at least one target")
	print("BENCH ", JSON.stringify(result))
	battle.queue_free()
	router.queue_free()
	for frame in range(4):
		await process_frame
	return result
