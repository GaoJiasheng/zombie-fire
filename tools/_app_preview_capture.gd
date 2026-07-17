extends SceneTree

const DURATION_SECONDS := 18.0

class PreviewRouter:
	extends Node
	var last_result := {}
	func finish_level(result: Dictionary) -> void:
		last_result = result

var battle: Node
var router: Node
var elapsed := 0.0
var triggered := {}

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
	battle.base_hp_max = 1000
	battle.base_hp = 1000
	battle.skills.add_skill("skill_incendiary")
	battle.skills.add_skill("skill_split_shot")
	battle.skills.add_skill("skill_slow_field")
	battle._update_skill_slots()
	_spawn_showcase_wave(false)

func _process(delta: float) -> bool:
	if battle == null or not is_instance_valid(battle):
		return false
	elapsed += delta
	if elapsed >= 3.8 and not triggered.has("reinforce"):
		triggered["reinforce"] = true
		_spawn_showcase_wave(false)
	if elapsed >= 6.2 and not triggered.has("cards"):
		triggered["cards"] = true
		battle._show_card_offer()
	if elapsed >= 8.9 and not triggered.has("pick"):
		triggered["pick"] = true
		battle._choose_card("skill_slow_field")
	if elapsed >= 9.5 and not triggered.has("boss"):
		triggered["boss"] = true
		_spawn_showcase_wave(true)
	if elapsed >= 12.4 and not triggered.has("phase"):
		triggered["phase"] = true
		if battle.active_boss != null and is_instance_valid(battle.active_boss):
			battle.active_boss.hp = battle.active_boss.max_hp * 0.62
	if elapsed >= 14.1 and not triggered.has("active"):
		triggered["active"] = true
		battle.character_active_cd = 0.0
		battle._on_character_skill_pressed()
	if elapsed >= 15.8 and not triggered.has("final_wave"):
		triggered["final_wave"] = true
		_spawn_showcase_wave(false)
	if elapsed >= DURATION_SECONDS:
		Engine.time_scale = 1.0
		quit(0)
	return false

func _spawn_showcase_wave(include_boss: bool) -> void:
	if not is_instance_valid(battle):
		return
	var ids := [
		"zombie_shambler", "zombie_runner", "zombie_armored", "zombie_spitter",
		"zombie_crawler", "zombie_bomber", "zombie_shielder", "zombie_mutant",
	]
	for index in range(ids.size()):
		var x := 150.0 + float(index % 4) * 250.0
		var y := 250.0 + float(index / 4) * 235.0 + randf_range(-35.0, 35.0)
		battle._spawn_enemy_instance(ids[index], Vector2(x, y), false, 0.0)
	if include_boss:
		battle._spawn_enemy_instance("boss_plague_mother", Vector2(540, 300), true, 0.0)
