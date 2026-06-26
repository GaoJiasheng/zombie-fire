class_name SkillRuntime
extends RefCounted

var owned := {}
var _order: Array[String] = []

func add_skill(skill_id: String) -> bool:
	var current := level(skill_id)
	if current >= max_level(skill_id):
		return false
	if not owned.has(skill_id):
		_order.append(skill_id)
	owned[skill_id] = current + 1
	return true

func owned_order() -> Array[String]:
	return _order.duplicate()

func level(skill_id: String) -> int:
	return int(owned.get(skill_id, 0))

func max_level(skill_id: String) -> int:
	var data_loader := _data_loader()
	if data_loader == null:
		return 3
	var row: Dictionary = data_loader.get_row("skills", skill_id)
	var levels: Array = row.get("levels", [])
	var max_value := 0
	for level_row in levels:
		if level_row is Dictionary:
			max_value = maxi(max_value, int(level_row.get("lv", 0)))
	return maxi(max_value, 3)

func _data_loader() -> Node:
	var loop := Engine.get_main_loop()
	if loop == null or not loop is SceneTree:
		return null
	return (loop as SceneTree).root.get_node_or_null("/root/DataLoader")

func can_add_skill(skill_id: String) -> bool:
	return level(skill_id) < max_level(skill_id)

func projectile_mods() -> Dictionary:
	return {
		"pierce": level("skill_pierce") + level("skill_homing"),
		"extra_projectiles": level("skill_multishot"),
		"spread_deg": 8.0 + level("skill_multishot") * 2.0,
		"split": level("skill_split_shot") + level("skill_ricochet"),
		"split_falloff": 0.55,
		"homing": level("skill_homing"),
		"ricochet": level("skill_ricochet")
	}

func fire_rate_multiplier() -> float:
	return 1.0 + 0.22 * float(level("skill_salvo"))

func slow_mult_for_y(y: float) -> float:
	var slow_level := level("skill_slow_field") + level("skill_cryo")
	if slow_level <= 0 or y < 1160.0:
		return 1.0
	return max(0.55, 1.0 - 0.12 * slow_level)

func damage_multiplier() -> float:
	return 1.0 + 0.12 * float(level("skill_charge_shot")) + 0.08 * float(level("skill_critical"))

func crit_bonus() -> float:
	return 0.04 * float(level("skill_critical"))

func gold_multiplier() -> float:
	return 1.0 + 0.1 * float(level("skill_gold_rush"))

func barrier_shields() -> int:
	return level("skill_barrier")

func projectile_element(base_element: String) -> String:
	var best := base_element
	var best_level := 0
	for item in [
		["fire", level("skill_incendiary")],
		["ice", level("skill_cryo")],
		["lightning", level("skill_tesla")],
		["poison", level("skill_venom")]
	]:
		if int(item[1]) > best_level:
			best = str(item[0])
			best_level = int(item[1])
	return best
