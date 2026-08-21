extends SceneTree

## Deterministic, headless campaign-frontline calibration probe.
##
## The probe consumes the single progression-fixture export produced by
## audit_campaign_frontline.py, stages the real Battle scene, selects the first
## card offered by the live CardDirector, auto-casts the real signature skill,
## and records the deepest enemy advance, base health, outcome and elapsed
## one-speed battle time. It never persists the synthetic save.

const BUILD_EXPORT_PATH := "res://design/audits/campaign_progression_fixture_builds.json"
const DEFAULT_OUTPUT_PATH := "res://design/audits/frontline_runtime_probe.json"
const BATTLE_SCENE_PATH := "res://gameplay/battle/battle.tscn"
const DEFAULT_LEVELS := [3, 8, 13, 30, 40, 55, 62, 75, 84, 95]
const WALL_ACCELERATION := 1.0
const BASE_PHYSICS_TICKS := 60
const MAX_LOGICAL_SECONDS := 540.0
const SETTLE_FRAMES := 4


class ProbeRouter:
	extends Node
	var result: Dictionary = {}

	func finish_level(value: Dictionary) -> void:
		result = value.duplicate(true)


class CombatSeedDriver:
	extends Node
	var base_seed := 0
	var frame_index := 0

	func _ready() -> void:
		process_physics_priority = -100000

	func _physics_process(_delta: float) -> void:
		# Reset the global stream at the start of every simulation tick. Rendering
		# helpers also use the global RNG; this keeps their variable tween/process
		# cadence from perturbing combat randomness between identical audit runs.
		seed(base_seed + frame_index * 104729)
		frame_index += 1


var _snapshot: Dictionary
var _rows_by_level: Dictionary = {}
var _requested_levels: Array[int] = []
var _output_path := DEFAULT_OUTPUT_PATH
var _results: Array[Dictionary] = []


func _initialize() -> void:
	await process_frame
	var data_loader := root.get_node_or_null("/root/DataLoader")
	var save_manager := root.get_node_or_null("/root/SaveManager")
	if data_loader == null or save_manager == null:
		_fail("frontline runtime probe requires DataLoader and SaveManager autoloads")
		return
	data_loader.call("load_all")
	save_manager.call("load_game")
	_snapshot = save_manager.save_data.duplicate(true)
	if not _parse_arguments():
		_restore_and_quit(2)
		return
	if not _load_fixture_export():
		_restore_and_quit(2)
		return

	var original_ticks := Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = int(round(float(BASE_PHYSICS_TICKS) * WALL_ACCELERATION))
	for level_number in _requested_levels:
		var fixture_row: Dictionary = _rows_by_level.get(level_number, {})
		if fixture_row.is_empty():
			_fail("fixture export is missing level %03d" % level_number)
			continue
		for seed_value in fixture_row.get("card_seeds", []):
			var run := await _run_level(save_manager, fixture_row, int(seed_value))
			_results.append(run)
			print(
				"FRONTLINE_RUNTIME level=%03d seed=%d progress=%.4f base=%.4f victory=%s elapsed=%.2f cards=%s"
				% [
					level_number,
					int(seed_value),
					float(run.get("max_progress", 0.0)),
					float(run.get("base_ratio", 0.0)),
					str(run.get("victory", false)),
					float(run.get("elapsed_seconds", 0.0)),
					str(run.get("selected_skills", [])),
				]
			)
	Engine.physics_ticks_per_second = original_ticks
	Engine.time_scale = 1.0
	paused = false
	if not _write_output():
		_restore_and_quit(2)
		return
	_restore_and_quit(0)


func _parse_arguments() -> bool:
	_requested_levels.assign(DEFAULT_LEVELS)
	var args := OS.get_cmdline_user_args()
	for arg in args:
		var text := str(arg)
		if text.begins_with("--levels="):
			_requested_levels.clear()
			for token in text.trim_prefix("--levels=").split(",", false):
				var number := int(token)
				if number > 0 and not _requested_levels.has(number):
					_requested_levels.append(number)
		elif text.begins_with("--output="):
			_output_path = text.trim_prefix("--output=")
	if _requested_levels.is_empty():
		_fail("--levels must contain at least one positive level number")
		return false
	_requested_levels.sort()
	return true


func _load_fixture_export() -> bool:
	if not FileAccess.file_exists(BUILD_EXPORT_PATH):
		_fail("missing fixture export: %s" % BUILD_EXPORT_PATH)
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(BUILD_EXPORT_PATH))
	if not parsed is Dictionary:
		_fail("invalid fixture export JSON: %s" % BUILD_EXPORT_PATH)
		return false
	for row_var in parsed.get("rows", []):
		if row_var is Dictionary:
			var row := row_var as Dictionary
			_rows_by_level[int(row.get("level", 0))] = row
	return true


func _run_level(save_manager: Node, fixture_row: Dictionary, seed_value: int) -> Dictionary:
	var build: Dictionary = fixture_row.get("build", {})
	save_manager.save_data = _save_for_build(save_manager, fixture_row)
	var router := ProbeRouter.new()
	root.add_child(router)
	var seed_driver := CombatSeedDriver.new()
	seed_driver.base_seed = seed_value + 7000003
	root.add_child(seed_driver)
	var packed := load(BATTLE_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("unable to load %s" % BATTLE_SCENE_PATH)
		router.queue_free()
		seed_driver.queue_free()
		return _error_result(fixture_row, seed_value, "battle scene load failed")
	var battle := packed.instantiate()
	# Freeze the battle before it enters the tree so startup frames cannot consume
	# combat RNG or advance the wave before the deterministic audit setup is done.
	battle.set_physics_process(false)
	battle.setup(router, {"level_id": str(fixture_row.get("level_id", ""))})
	root.add_child(battle)
	await process_frame
	if battle.card_director != null:
		battle.card_director.set_audit_seed(seed_value)
	# Run this script with Godot's `--fixed-fps 60` switch. That mode advances
	# process and physics time in lockstep without wall-clock synchronization, so
	# it is both faster than real time and exactly the 1/60 control simulation.
	battle.battle_speed = WALL_ACCELERATION
	Engine.time_scale = WALL_ACCELERATION
	if battle.hit_stop != null:
		battle.hit_stop.target_scale = WALL_ACCELERATION
	battle.set_physics_process(true)

	var max_progress := 0.0
	var selected_skills: Array[String] = []
	var logical_seconds := 0.0
	var timeout := false
	while is_instance_valid(battle) and not battle.battle_finished:
		await physics_frame
		logical_seconds += 1.0 / float(BASE_PHYSICS_TICKS)
		max_progress = maxf(max_progress, _deepest_progress(battle))
		if battle.card_offer_active:
			var selected := _select_first_live_offer(battle)
			if selected != "":
				selected_skills.append(selected)
		if (
			float(battle.character_active_cd) <= 0.0
			and battle.get_node("EnemyLayer").get_child_count() > 0
			and not battle.card_offer_active
		):
			battle._on_character_skill_pressed()
		if logical_seconds > MAX_LOGICAL_SECONDS:
			timeout = true
			break

	max_progress = maxf(max_progress, _deepest_progress(battle))
	var base_ratio := clampf(
		float(battle.base_hp) / maxf(float(battle.base_hp_max), 1.0),
		0.0,
		1.0
	)
	var elapsed := float(battle.battle_elapsed_seconds) * WALL_ACCELERATION
	var victory := bool(router.result.get("victory", false)) if not router.result.is_empty() else false
	var result := {
		"level": int(fixture_row.get("level", 0)),
		"level_id": str(fixture_row.get("level_id", "")),
		"seed": seed_value,
		"build": build.duplicate(true),
		"max_progress": max_progress,
		"base_ratio": base_ratio,
		"victory": victory,
		"elapsed_seconds": elapsed,
		"timeout": timeout,
		"selected_skills": selected_skills,
		"final_skill_levels": battle.skills.owned.duplicate(true),
		"battle_report": router.result.get("battle_report", {}).duplicate(true),
	}
	battle.queue_free()
	router.queue_free()
	seed_driver.queue_free()
	paused = false
	Engine.time_scale = 1.0
	for _frame in range(SETTLE_FRAMES):
		await process_frame
	return result


func _save_for_build(save_manager: Node, fixture_row: Dictionary) -> Dictionary:
	var data: Dictionary = save_manager._default_save()
	var build: Dictionary = fixture_row.get("build", {})
	var character := str(build.get("character", "vanguard"))
	var weapon := str(build.get("weapon", "weapon_autocannon"))
	var armor := str(build.get("armor", ""))
	var chip := str(build.get("chip", ""))
	var pet := str(build.get("pet", ""))
	var equipment: Dictionary = data.get("equipment", {})
	equipment["selected_character"] = character
	equipment["selected_weapon"] = weapon
	equipment["selected_armor"] = armor
	equipment["selected_chip"] = chip
	equipment["selected_pet"] = pet
	equipment[character] = int(build.get("character_level", 1))
	equipment[weapon] = int(build.get("weapon_level", 1))
	if armor != "":
		equipment[armor] = int(build.get("armor_level", 1))
	if chip != "":
		equipment[chip] = int(build.get("chip_level", 1))
	if pet != "":
		equipment[pet] = int(build.get("pet_level", 1))
	data["equipment"] = equipment
	var unlocks: Dictionary = data.get("unlocks", {})
	unlocks["levels"] = [str(fixture_row.get("level_id", "level_001"))]
	unlocks["characters"] = [character]
	unlocks["weapons"] = [weapon]
	unlocks["armors"] = [armor] if armor != "" else []
	unlocks["chips"] = [chip] if chip != "" else []
	unlocks["pets"] = [pet] if pet != "" else []
	data["unlocks"] = unlocks
	data["skill_base_levels"] = build.get("skill_base_levels", {}).duplicate(true)
	var signature_level := int(build.get("signature_level", 0))
	data["sig_skill_levels"] = {character: signature_level} if signature_level > 0 else {}
	data["player"] = {
		"gold": int(fixture_row.get("resources_before", {}).get("gold", 0)),
		"xp": int(fixture_row.get("resources_before", {}).get("xp", 0)),
		"star": int(fixture_row.get("resources_before", {}).get("stars", 0)),
	}
	return data


func _select_first_live_offer(battle: Node) -> String:
	var cards := battle.get_node_or_null("Hud/CardPanel/Cards")
	if cards == null:
		return ""
	for child in cards.get_children():
		var skill_id := str(child.get_meta("skill_id", ""))
		if skill_id != "":
			battle._choose_card(skill_id)
			return skill_id
	battle._on_skip_card()
	return ""


func _deepest_progress(battle: Node) -> float:
	var enemy_layer := battle.get_node_or_null("EnemyLayer")
	if enemy_layer == null:
		return 0.0
	var spawn_y := 190.0
	var breach_y := float(battle.BREACH_Y)
	var route := maxf(breach_y - spawn_y, 1.0)
	var deepest := 0.0
	for enemy in enemy_layer.get_children():
		if not enemy is Node2D or not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		deepest = maxf(deepest, clampf((float(enemy.global_position.y) - spawn_y) / route, 0.0, 1.0))
	return deepest


func _write_output() -> bool:
	var payload := {
		"schema_version": 1,
		"fixture_source": BUILD_EXPORT_PATH.trim_prefix("res://"),
		"levels": _requested_levels,
		"seeds_per_level": 3,
		"simulation_step_seconds": 1.0 / float(BASE_PHYSICS_TICKS),
		"wall_acceleration": WALL_ACCELERATION,
		"runs": _results,
	}
	var file := FileAccess.open(_output_path, FileAccess.WRITE)
	if file == null:
		_fail("unable to write probe output: %s" % _output_path)
		return false
	file.store_string(JSON.stringify(payload, "  ", false) + "\n")
	return true


func _error_result(fixture_row: Dictionary, seed_value: int, message: String) -> Dictionary:
	return {
		"level": int(fixture_row.get("level", 0)),
		"level_id": str(fixture_row.get("level_id", "")),
		"seed": seed_value,
		"error": message,
	}


func _restore_and_quit(code: int) -> void:
	var save_manager := root.get_node_or_null("/root/SaveManager")
	if save_manager != null and not _snapshot.is_empty():
		save_manager.save_data = _snapshot
	Engine.time_scale = 1.0
	paused = false
	quit(code)


func _fail(message: String) -> void:
	push_error(message)
