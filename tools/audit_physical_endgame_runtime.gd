extends SceneTree

## Runtime endgame throughput audit for the three physical weapons.
##
## Unlike the lightweight Python campaign estimator, this stages the real
## Battle/Projectile/Enemy code with every non-elemental offensive run skill at
## level 5. It therefore includes:
## - five-lane multishot and the live 0.70 per-lane falloff;
## - scattergun pellet geometry;
## - skill + weapon + character + chip pierce;
## - split-shot children, ricochet targets and homing;
## - crit expectation, Salvo cadence and Vanguard's active/barrage uptime;
## - the selected max-level chip and pet.
##
## Two target arrangements are measured: one real Apex collider and a
## deterministic 45-enemy formation. The audit never edits save files.

const PHYSICAL_WEAPONS := [
	"weapon_autocannon",
	"weapon_railgun",
	"weapon_scattergun",
]
const OFFENSIVE_SKILLS := [
	"skill_split_shot",
	"skill_pierce",
	"skill_multishot",
	"skill_homing",
	"skill_critical",
	"skill_ricochet",
	"skill_salvo",
	"skill_charge_shot",
]
const CHIP_CANDIDATES := ["chip_attack", "chip_pierce"]
const PET_CANDIDATES := ["pet_turret_drone", "pet_volt_orb"]
const MEASURE_FRAMES := 72
const ACTIVE_FRAMES := 48
const SIM_TIME_SCALE := 5.0
const BENCHMARK_PATH := "res://tools/physical_endgame_runtime_benchmark.json"
const BENCHMARK_TOLERANCE := 0.06

var _snapshot: Dictionary
var _results: Array[Dictionary] = []


func _initialize() -> void:
	await process_frame
	var data_loader := root.get_node_or_null("/root/DataLoader")
	var save_manager := root.get_node_or_null("/root/SaveManager")
	if data_loader == null or save_manager == null:
		push_error("Runtime DPS audit requires DataLoader and SaveManager autoloads")
		quit(1)
		return
	data_loader.call("load_all")
	save_manager.call("load_game")
	_snapshot = save_manager.save_data.duplicate(true)
	for weapon_id in PHYSICAL_WEAPONS:
		for chip_id in CHIP_CANDIDATES:
			for pet_id in PET_CANDIDATES:
				for scenario in ["boss", "crowd"]:
					var row := await _measure_build(save_manager, weapon_id, chip_id, pet_id, scenario)
					_results.append(row)
	save_manager.save_data = _snapshot
	Engine.time_scale = 1.0
	print("PHYSICAL_ENDGAME_RUNTIME_AUDIT_JSON=", JSON.stringify(_results))
	quit(0 if _validate_checked_in_benchmark() else 1)


func _validate_checked_in_benchmark() -> bool:
	if not FileAccess.file_exists(BENCHMARK_PATH):
		push_error("Missing runtime benchmark: %s" % BENCHMARK_PATH)
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(BENCHMARK_PATH))
	if not parsed is Dictionary:
		push_error("Invalid runtime benchmark JSON")
		return false
	var expected_builds: Dictionary = parsed.get("best_same_loadout", {})
	var ok := true
	for weapon_id in PHYSICAL_WEAPONS:
		var expected: Dictionary = expected_builds.get(weapon_id, {})
		if expected.is_empty():
			push_error("Runtime benchmark missing %s" % weapon_id)
			ok = false
			continue
		var chip_id := str(expected.get("chip", ""))
		var pet_id := str(expected.get("pet", ""))
		for scenario in ["boss", "crowd"]:
			var expected_dps := float(expected.get("%s_dps" % scenario, 0.0))
			var observed_dps := _result_dps(weapon_id, chip_id, pet_id, scenario)
			var relative_error := absf(observed_dps - expected_dps) / maxf(expected_dps, 1.0)
			if expected_dps <= 0.0 or relative_error > BENCHMARK_TOLERANCE:
				push_error(
					"%s %s runtime DPS drifted: observed %.1f expected %.1f (%.1f%%)"
					% [weapon_id, scenario, observed_dps, expected_dps, relative_error * 100.0]
				)
				ok = false
	return ok


func _result_dps(weapon_id: String, chip_id: String, pet_id: String, scenario: String) -> float:
	for row in _results:
		if (
			str(row.get("weapon", "")) == weapon_id
			and str(row.get("chip", "")) == chip_id
			and str(row.get("pet", "")) == pet_id
			and str(row.get("scenario", "")) == scenario
		):
			return float(row.get("total_dps", 0.0))
	return 0.0


func _measure_build(
	save_manager: Node,
	weapon_id: String,
	chip_id: String,
	pet_id: String,
	scenario: String,
) -> Dictionary:
	save_manager.save_data = _maxed_save(weapon_id, chip_id, pet_id)
	var router := Node.new()
	root.add_child(router)
	# Load after the first process frame so project autoload classes are already
	# registered. A top-level preload compiles Battle too early in --script runs.
	var battle_scene := load("res://gameplay/battle/battle.tscn") as PackedScene
	if battle_scene == null:
		push_error("Unable to load res://gameplay/battle/battle.tscn")
		router.queue_free()
		return {}
	var battle := battle_scene.instantiate()
	battle.setup(router, {"level_id": "level_099"})
	root.add_child(battle)
	await process_frame
	await physics_frame
	Engine.time_scale = SIM_TIME_SCALE
	_prepare_battle(battle)
	var targets := _stage_targets(battle, scenario)
	await process_frame
	await physics_frame

	var actual_crit_rate := clampf(float(battle.crit_rate) + float(battle.skills.crit_bonus()), 0.0, 1.0)
	var crit_mult := float(battle.skills.crit_damage_mult())
	# Suppress RNG during the runtime sample, then apply the exact expectation
	# once to every projectile-derived hit.
	battle.crit_rate = -float(battle.skills.crit_bonus())
	var normal_shot := await _measure_shot(battle, false)
	var barrage_shot := await _measure_shot(battle, true)
	var active_cast := await _measure_active_cast(battle)
	var crit_expectation := 1.0 + actual_crit_rate * (crit_mult - 1.0)
	normal_shot *= crit_expectation
	barrage_shot *= crit_expectation

	var normal_rate := float(battle.turret.fire_rate)
	var active: Dictionary = battle.character_data.get("active_skill", {})
	var barrage_rate_mult := float(battle._vanguard_railvolley_fire_rate_mult(active))
	var active_duration := float(battle._active_skill_duration(active, 6.0))
	var cooldown := float(battle.character_active_cd_max)
	var uptime := clampf(active_duration / maxf(cooldown, 0.01), 0.0, 1.0)
	var projectile_dps := normal_shot * normal_rate * (1.0 - uptime)
	projectile_dps += barrage_shot * normal_rate * barrage_rate_mult * uptime
	var active_dps := active_cast / maxf(cooldown, 0.01)
	var pet_dps := _pet_dps(battle.pet_data, battle.pet_level)
	var total_dps := projectile_dps + active_dps + pet_dps
	var result := {
		"weapon": weapon_id,
		"chip": chip_id,
		"pet": pet_id,
		"scenario": scenario,
		"target_count": targets.size(),
		"crit_rate": actual_crit_rate,
		"normal_shot": normal_shot,
		"barrage_shot": barrage_shot,
		"normal_rate": normal_rate,
		"barrage_rate_mult": barrage_rate_mult,
		"active_cast": active_cast,
		"active_cooldown": cooldown,
		"active_uptime": uptime,
		"projectile_dps": projectile_dps,
		"active_dps": active_dps,
		"pet_dps": pet_dps,
		"total_dps": total_dps,
	}
	battle.queue_free()
	router.queue_free()
	await process_frame
	await process_frame
	return result


func _prepare_battle(battle: Node) -> void:
	battle.pending_spawns.clear()
	battle.active_spawning = false
	battle.wave_index = int(battle.wave_total)
	battle.paused = true
	battle.card_offer_active = false
	battle.turret.set("fire_enabled", false)
	for child in battle.get_node("EnemyLayer").get_children():
		child.free()
	for child in battle.get_node("ProjectileLayer").get_children():
		child.free()
	for child in battle.get_node("ThreatMarkerLayer").get_children():
		child.free()
	battle.skills.owned = {}
	battle.skills._order.clear()
	# The temporary save seeds every base skill at level 5, so a single add
	# installs the real max-level effect and preserves the runtime skill order.
	for skill_id in OFFENSIVE_SKILLS:
		if not battle.skills.add_skill(skill_id):
			push_error("Unable to install max runtime skill: %s" % skill_id)
	var fire_rate_mult := float(battle.skills.fire_rate_multiplier())
	battle.turret.fire_rate *= fire_rate_mult
	battle.skill_fire_rate_mult = fire_rate_mult
	battle.battle_damage_total = 0.0
	battle.battle_damage_by_element = {}


func _stage_targets(battle: Node, scenario: String) -> Array[Node]:
	var targets: Array[Node] = []
	if scenario == "boss":
		var boss: Node = battle._spawn_enemy_instance("boss_apex_overlord", Vector2(540, 980), true)
		_configure_dummy(boss)
		targets.append(boss)
		battle.turret.aim_at(boss.global_position)
		battle.target_manager.lock_enemy(boss)
		return targets
	for row in range(5):
		for column in range(9):
			var position := Vector2(180.0 + float(column) * 90.0, 500.0 + float(row) * 180.0)
			var enemy: Node = battle._spawn_enemy_instance("zombie_shambler", position, false)
			_configure_dummy(enemy)
			targets.append(enemy)
	battle.turret.aim_at(Vector2(540, 1220))
	return targets


func _configure_dummy(enemy: Node) -> void:
	enemy.speed = 0.0
	enemy.breach_damage = 0
	enemy.mechanic = "basic"
	enemy.mechanic_params = {}
	enemy.max_hp = 1.0e12
	enemy.hp = enemy.max_hp
	if enemy.has_method("_update_hp_bar"):
		enemy.call("_update_hp_bar")


func _measure_shot(battle: Node, barrage: bool) -> float:
	battle.battle_damage_total = 0.0
	battle.sig_vanguard_barrage_timer = 999.0 if barrage else 0.0
	var origin: Vector2 = battle._weapon_fire_origin()
	var direction: Vector2 = battle._weapon_fire_direction(Vector2.UP)
	battle._on_turret_fired(origin, direction)
	for _frame in range(MEASURE_FRAMES):
		await physics_frame
	var damage := float(battle.battle_damage_total)
	for child in battle.get_node("ProjectileLayer").get_children():
		if child.has_meta("battle_transient_fx") or child.has_method("setup"):
			child.free()
	await process_frame
	return damage


func _measure_active_cast(battle: Node) -> float:
	battle.battle_damage_total = 0.0
	battle.sig_vanguard_barrage_timer = 0.0
	# Active-skill callbacks intentionally abort while the battle is paused.
	# Unpause only this isolated sandbox; spawning and turret fire stay disabled.
	battle.paused = false
	battle._cast_vanguard_railvolley()
	for _frame in range(ACTIVE_FRAMES):
		await physics_frame
	battle.paused = true
	return float(battle.battle_damage_total)


func _pet_dps(pet: Dictionary, level: int) -> float:
	var damage := float(pet.get("damage", 0.0))
	damage *= 1.0 + float(pet.get("level_damage_growth", 0.0)) * float(maxi(level - 1, 0))
	return damage * float(pet.get("fire_rate", 0.0))


func _maxed_save(weapon_id: String, chip_id: String, pet_id: String) -> Dictionary:
	var data := _snapshot.duplicate(true)
	var equipment: Dictionary = data.get("equipment", {}).duplicate(true)
	equipment["selected_character"] = "vanguard"
	equipment["selected_weapon"] = weapon_id
	equipment["selected_armor"] = "armor_kevlar"
	equipment["selected_chip"] = chip_id
	equipment["selected_pet"] = pet_id
	equipment["vanguard"] = 40
	equipment[weapon_id] = 50
	equipment["armor_kevlar"] = 35
	equipment[chip_id] = 35 if chip_id != "chip_pierce" else 20
	equipment[pet_id] = 30
	data["equipment"] = equipment
	var sig_levels: Dictionary = data.get("sig_skill_levels", {}).duplicate(true)
	sig_levels["vanguard"] = 5
	data["sig_skill_levels"] = sig_levels
	var base_levels: Dictionary = data.get("skill_base_levels", {}).duplicate(true)
	for skill_id in OFFENSIVE_SKILLS:
		base_levels[skill_id] = 5
	data["skill_base_levels"] = base_levels
	var unlocks: Dictionary = data.get("unlocks", {}).duplicate(true)
	unlocks["characters"] = _with_id(unlocks.get("characters", []), "vanguard")
	unlocks["weapons"] = _with_id(unlocks.get("weapons", []), weapon_id)
	unlocks["armors"] = _with_id(unlocks.get("armors", []), "armor_kevlar")
	unlocks["chips"] = _with_id(unlocks.get("chips", []), chip_id)
	unlocks["pets"] = _with_id(unlocks.get("pets", []), pet_id)
	data["unlocks"] = unlocks
	return data


func _with_id(source: Array, id: String) -> Array:
	var result := source.duplicate()
	if not result.has(id):
		result.append(id)
	return result
