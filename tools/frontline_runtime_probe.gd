extends SceneTree

## Deterministic, headless campaign-frontline calibration probe.
##
## The probe consumes the single progression-fixture export produced by
## audit_campaign_frontline.py, stages the real Battle scene, applies the
## deterministic player policy stored in economy.probe_card_policy, auto-casts
## the real signature skill,
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
var _profile_id := "control"
var _card_policy_id := "v2"
var _seed_override: Array[int] = []
var _ignore_level_guarantees := false
var _ignore_offer_category_floor := false
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
		var run_seeds: Array = _seed_override if not _seed_override.is_empty() else fixture_row.get("card_seeds", [])
		for seed_value in run_seeds:
			var run := await _run_level(save_manager, fixture_row, int(seed_value))
			_results.append(run)
			print(
				"FRONTLINE_RUNTIME profile=%s level=%03d seed=%d progress=%.4f base=%.4f victory=%s elapsed=%.2f boss=%.2f cards=%s"
				% [
					_profile_id,
					level_number,
					int(seed_value),
					float(run.get("max_progress", 0.0)),
					float(run.get("base_ratio", 0.0)),
					str(run.get("victory", false)),
					float(run.get("elapsed_seconds", 0.0)),
					float(run.get("boss_phase_seconds", 0.0)),
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
		elif text.begins_with("--profile="):
			_profile_id = text.trim_prefix("--profile=").strip_edges()
		elif text.begins_with("--card-policy="):
			_card_policy_id = text.trim_prefix("--card-policy=").strip_edges()
		elif text.begins_with("--seeds="):
			_seed_override.clear()
			for token in text.trim_prefix("--seeds=").split(",", false):
				var seed_value := int(token)
				if seed_value > 0 and not _seed_override.has(seed_value):
					_seed_override.append(seed_value)
		elif text == "--ignore-level-guarantees":
			_ignore_level_guarantees = true
		elif text == "--ignore-offer-category-floor":
			_ignore_offer_category_floor = true
	if _requested_levels.is_empty():
		_fail("--levels must contain at least one positive level number")
		return false
	if not ["control", "tier_a", "tier_b"].has(_profile_id):
		_fail("--profile must be control, tier_a or tier_b")
		return false
	if not ["v2", "legacy"].has(_card_policy_id):
		_fail("--card-policy must be v2 or legacy")
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
	var data_loader := root.get_node("/root/DataLoader")
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
	var level_override_state := _install_level_override(
		data_loader,
		str(fixture_row.get("level_id", ""))
	)
	# Freeze the battle before it enters the tree so startup frames cannot consume
	# combat RNG or advance the wave before the deterministic audit setup is done.
	battle.set_physics_process(false)
	battle.setup(router, {"level_id": str(fixture_row.get("level_id", ""))})
	root.add_child(battle)
	await process_frame
	_restore_level_override(data_loader, level_override_state)
	if battle.card_director != null:
		battle.card_director.set_audit_seed(seed_value)
	battle._set_fire_rate_profile(_profile_id)
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
	var card_timeline: Array[Dictionary] = []
	var wave_timeline: Array[Dictionary] = []
	var logical_seconds := 0.0
	var timeout := false
	var boss_phase_start := -1.0
	var boss_phase_last_seen := -1.0
	var max_living_bosses := 0
	var tracked_wave := int(battle.wave_index)
	var wave_max_progress := 0.0
	while is_instance_valid(battle) and not battle.battle_finished:
		await physics_frame
		logical_seconds += 1.0 / float(BASE_PHYSICS_TICKS)
		var current_progress := _deepest_progress(battle)
		max_progress = maxf(max_progress, current_progress)
		wave_max_progress = maxf(wave_max_progress, current_progress)
		if int(battle.wave_index) != tracked_wave:
			wave_timeline.append(
				_wave_snapshot(battle, tracked_wave, logical_seconds, wave_max_progress)
			)
			tracked_wave = int(battle.wave_index)
			wave_max_progress = current_progress
		var boss_state := _boss_combat_state(battle)
		var living_bosses := int(boss_state.get("living", 0))
		max_living_bosses = maxi(max_living_bosses, living_bosses)
		# Boss phase means the actual combat window, not the approach from its
		# spawn point.  Starting at first damage keeps this metric comparable
		# across lanes and support formations.
		if bool(boss_state.get("engaged", false)):
			if boss_phase_start < 0.0:
				boss_phase_start = logical_seconds
			boss_phase_last_seen = logical_seconds
		if battle.card_offer_active:
			var choice := _select_live_offer(battle)
			var selected := str(choice.get("selected", ""))
			if selected != "":
				selected_skills.append(selected)
				choice["time"] = logical_seconds
				choice["wave"] = int(battle.wave_index)
				card_timeline.append(choice)
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
	if tracked_wave >= 0:
		wave_timeline.append(
			_wave_snapshot(battle, tracked_wave, logical_seconds, wave_max_progress)
		)
	var base_ratio := clampf(
		float(battle.base_hp) / maxf(float(battle.base_hp_max), 1.0),
		0.0,
		1.0
	)
	var elapsed := float(battle.battle_elapsed_seconds) * WALL_ACCELERATION
	var victory := bool(router.result.get("victory", false)) if not router.result.is_empty() else false
	var boss_state_at_end := _boss_combat_state(battle)
	var result := {
		"level": int(fixture_row.get("level", 0)),
		"level_id": str(fixture_row.get("level_id", "")),
		"seed": seed_value,
		"build": build.duplicate(true),
		"max_progress": max_progress,
		"base_ratio": base_ratio,
		"victory": victory,
		"elapsed_seconds": elapsed,
		"boss_phase_seconds": maxf(boss_phase_last_seen - boss_phase_start, 0.0) if boss_phase_start >= 0.0 else 0.0,
		"max_living_bosses": max_living_bosses,
		"boss_hp_ratio_at_end": float(boss_state_at_end.get("hp_ratio", 0.0)),
		"timeout": timeout,
		"card_policy": _card_policy_id,
		"selected_skills": selected_skills,
		"card_timeline": card_timeline,
		"wave_timeline": wave_timeline,
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


func _install_level_override(data_loader: Node, level_id: String) -> Dictionary:
	if not _ignore_level_guarantees and not _ignore_offer_category_floor:
		return {}
	var rows: Array = data_loader.get_table("levels")
	for index in range(rows.size()):
		var row := rows[index] as Dictionary
		if str(row.get("id", "")) != level_id:
			continue
		var override := row.duplicate(true)
		if _ignore_level_guarantees:
			override.erase("guaranteed_card_offers")
		if _ignore_offer_category_floor:
			override.erase("offer_category_floor")
		rows[index] = override
		return {"index": index, "original": row}
	return {}


func _restore_level_override(data_loader: Node, state: Dictionary) -> void:
	if state.is_empty():
		return
	var rows: Array = data_loader.get_table("levels")
	var index := int(state.get("index", -1))
	if index >= 0 and index < rows.size():
		rows[index] = state.get("original", {})


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


func _select_live_offer(battle: Node) -> Dictionary:
	var cards := battle.get_node_or_null("Hud/CardPanel/Cards")
	if cards == null:
		return {}
	var candidates: Array[String] = []
	for child in cards.get_children():
		var candidate_id := str(child.get_meta("skill_id", ""))
		if candidate_id != "":
			candidates.append(candidate_id)
	if candidates.is_empty():
		battle._on_skip_card()
		return {}
	if _card_policy_id == "legacy":
		return _select_legacy_offer(battle, candidates)
	return _select_policy_offer(battle, candidates)


func _select_legacy_offer(battle: Node, candidates: Array[String]) -> Dictionary:
	var guaranteed_ids: Array[String] = []
	for rule_var in battle.level.get("guaranteed_card_offers", []):
		if not rule_var is Dictionary:
			continue
		var rule := rule_var as Dictionary
		if int(rule.get("offer", -1)) != int(battle.card_director._offer_index):
			continue
		for skill_id_var in rule.get("skill_ids", []):
			guaranteed_ids.append(str(skill_id_var))
	for guaranteed_id in candidates:
		if guaranteed_ids.has(guaranteed_id):
			battle._choose_card(guaranteed_id)
			return {
				"selected": guaranteed_id,
				"candidates": candidates,
				"reason": "legacy_guarantee",
				"offer": int(battle.card_director._offer_index),
			}
	var selected := candidates[0]
	battle._choose_card(selected)
	return {
		"selected": selected,
		"candidates": candidates,
		"reason": "legacy_first",
		"offer": int(battle.card_director._offer_index),
	}


func _select_policy_offer(battle: Node, candidates: Array[String]) -> Dictionary:
	var data_loader := root.get_node("/root/DataLoader")
	var economy: Dictionary = data_loader.get_table("economy")
	var policy: Dictionary = economy.get("probe_card_policy", {})
	if policy.is_empty():
		_fail("economy.probe_card_policy is missing")
		return _select_legacy_offer(battle, candidates)
	var clear_requirement: Dictionary = battle.level.get("clear_requirement", {})
	var boss_share := float(clear_requirement.get("boss_hp_share", 0.0))
	var boss_dominant := boss_share >= float(policy.get("boss_hp_share_threshold", 0.5))
	var priorities: Array = (
		policy.get("boss_priority", []) if boss_dominant else policy.get("mob_priority", [])
	)
	var weapon_row: Dictionary = data_loader.get_row("weapons", str(battle.weapon_id))
	var weapon_element := str(weapon_row.get("element", "physical"))
	var best_index := 0
	var best_rank := 1000000
	var best_reason := "remaining"
	for index in range(candidates.size()):
		var skill_id := candidates[index]
		var skill_row: Dictionary = data_loader.get_row("skills", skill_id)
		var tags: Array = skill_row.get("card_tags", [])
		var owned := int(battle.skills.level(skill_id)) > 0
		var reason := _policy_reason(
			tags,
			owned,
			boss_dominant,
			weapon_element,
			policy
		)
		var rank := priorities.find(reason)
		if rank < 0:
			rank = priorities.find("remaining")
		if rank < 0:
			rank = priorities.size()
		if rank < best_rank:
			best_index = index
			best_rank = rank
			best_reason = reason
	var selected := candidates[best_index]
	battle._choose_card(selected)
	return {
		"selected": selected,
		"candidates": candidates,
		"reason": best_reason,
		"rank": best_rank,
		"mode": "boss" if boss_dominant else "mob",
		"boss_hp_share": boss_share,
		"weapon_element": weapon_element,
		"offer": int(battle.card_director._offer_index),
	}


func _policy_reason(
	tags: Array,
	owned: bool,
	boss_dominant: bool,
	weapon_element: String,
	policy: Dictionary
) -> String:
	if _has_policy_category(tags, "economy", policy):
		return "economy"
	var crowd := _has_policy_category(tags, "crowd", policy)
	var single_target := _has_policy_category(tags, "single_target", policy)
	if boss_dominant:
		if owned and single_target:
			return "owned_single_target_upgrade"
		if not owned and single_target:
			return "new_single_target"
		if crowd:
			return "crowd"
		if _has_policy_category(tags, "control", policy):
			return "control"
		if _has_policy_category(tags, "defense", policy):
			return "defense"
		return "remaining"
	if owned and crowd:
		return "owned_crowd_upgrade"
	if not owned and crowd and _card_matches_weapon_element(tags, weapon_element, policy):
		return "new_matching_element_crowd"
	if _has_policy_category(tags, "control", policy):
		return "control"
	if _has_policy_category(tags, "defense", policy):
		return "defense"
	return "remaining"


func _has_policy_category(tags: Array, category: String, policy: Dictionary) -> bool:
	var category_tags: Array = policy.get("category_tags", {}).get(category, [])
	var exclusion_tags: Array = policy.get("category_exclusions", {}).get(category, [])
	for tag_var in exclusion_tags:
		if tags.has(str(tag_var)):
			return false
	for tag_var in category_tags:
		if tags.has(str(tag_var)):
			return true
	return false


func _card_matches_weapon_element(
	tags: Array,
	weapon_element: String,
	policy: Dictionary
) -> bool:
	var element_tags: Array = policy.get("element_tags", [])
	var has_element_tag := false
	for tag_var in element_tags:
		var tag := str(tag_var)
		if not tags.has(tag):
			continue
		has_element_tag = true
		if tag == weapon_element:
			return true
	return not has_element_tag and bool(policy.get("neutral_cards_match_weapon_element", true))


func _wave_snapshot(
	battle: Node,
	wave_index: int,
	time_seconds: float,
	progress: float
) -> Dictionary:
	return {
		"wave": wave_index,
		"end_time": time_seconds,
		"max_progress": progress,
		"base_ratio": clampf(
			float(battle.base_hp) / maxf(float(battle.base_hp_max), 1.0),
			0.0,
			1.0
		),
	}


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


func _boss_combat_state(battle: Node) -> Dictionary:
	var enemy_layer := battle.get_node_or_null("EnemyLayer")
	if enemy_layer == null:
		return {"living": 0, "engaged": false, "hp_ratio": 0.0}
	var count := 0
	var engaged := false
	var living_hp := 0.0
	var living_max_hp := 0.0
	for enemy in enemy_layer.get_children():
		if (
			enemy is Node
			and is_instance_valid(enemy)
			and not enemy.is_queued_for_deletion()
			and bool(enemy.get("boss"))
			and float(enemy.get("hp")) > 0.0
		):
			count += 1
			living_hp += float(enemy.get("hp"))
			living_max_hp += maxf(float(enemy.get("max_hp")), 1.0)
			var hp_damaged := float(enemy.get("hp")) < float(enemy.get("max_hp")) - 0.001
			var armor_damaged := (
				float(enemy.get("armor_hp_max")) > 0.0
				and float(enemy.get("armor_hp")) < float(enemy.get("armor_hp_max")) - 0.001
			)
			engaged = engaged or hp_damaged or armor_damaged
	return {
		"living": count,
		"engaged": engaged,
		"hp_ratio": living_hp / living_max_hp if living_max_hp > 0.0 else 0.0,
	}


func _write_output() -> bool:
	var payload := {
		"schema_version": 1,
		"fixture_source": BUILD_EXPORT_PATH.trim_prefix("res://"),
		"levels": _requested_levels,
		"profile": _profile_id,
		"card_policy": _card_policy_id,
		"ignore_level_guarantees": _ignore_level_guarantees,
		"ignore_offer_category_floor": _ignore_offer_category_floor,
		"seeds_per_level": _seed_override.size() if not _seed_override.is_empty() else 3,
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
