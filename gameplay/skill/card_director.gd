class_name CardDirector
extends RefCounted

# 连续多少次三选一都没命中角色/武器适配技能后触发保底(economy.json 的
# pity_after_missing_core_tag)；实例跟随 battle 生命周期存活，天然按局重置。
var _missed_core_tag_streak := 0

var skill_pool := [
	"skill_split_shot",
	"skill_pierce",
	"skill_multishot",
	"skill_slow_field",
	"skill_incendiary",
	"skill_cryo",
	"skill_tesla",
	"skill_venom",
	"skill_critical",
	"skill_charge_shot",
	"skill_ricochet",
	"skill_homing",
	"skill_barrier",
	"skill_recycle",
	"skill_gold_rush",
	"skill_salvo"
]

func offer(level: Dictionary, owned: Dictionary, count := 3) -> Array[String]:
	var weighted: Array[String] = []
	var eligible: Array[String] = []
	var bias := _build_bias(level)
	var data_loader = _data_loader()
	if data_loader == null:
		return []
	var skills: Dictionary = data_loader.get_table("skills")
	for skill_id in skill_pool:
		var row: Dictionary = skills.get(skill_id, {})
		if not _allowed_by_selected_weapon(skill_id, row, owned):
			continue
		var current_level := int(owned.get(skill_id, 0))
		if current_level >= _skill_max_level(row):
			continue
		eligible.append(skill_id)
		var weight := 4
		if current_level > 0:
			weight += max(0, 2 - current_level)
		for tag in row.get("card_tags", []):
			weight += int(round(float(bias.get(tag, 1.0)) * 2.0))
		if _matches_selected_loadout(row):
			weight += 4
		for i in range(max(weight, 1)):
			weighted.append(skill_id)
	var result: Array[String] = []
	var economy: Dictionary = data_loader.get_table("economy")
	var economy_rules: Dictionary = economy.get("card_director", {})
	var max_economy := int(economy_rules.get("max_economy_cards_per_offer", 1))
	var economy_count := 0
	while result.size() < count and not weighted.is_empty():
		var picked: String = weighted.pick_random()
		var picked_row: Dictionary = skills.get(picked, {})
		var picked_tags: Array = picked_row.get("card_tags", [])
		var is_economy := picked_tags.has("economy")
		if not result.has(picked) and (not is_economy or economy_count < max_economy):
			result.append(picked)
			if is_economy:
				economy_count += 1
		weighted = weighted.filter(func(id: String) -> bool: return id != picked)
	_apply_pity(result, eligible, skills, economy_rules)
	return result

# 连续 N 次三选一都没有一张命中角色/武器适配技能时,强制把本次的最后一张
# 换成一张命中适配的技能(economy.json 的 pity_after_missing_core_tag)。
func _apply_pity(result: Array[String], eligible: Array[String], skills: Dictionary, economy_rules: Dictionary) -> void:
	var pity_threshold := int(economy_rules.get("pity_after_missing_core_tag", 0))
	if pity_threshold <= 0 or result.is_empty():
		return
	var has_core_tag := false
	for skill_id in result:
		if _matches_selected_loadout(skills.get(skill_id, {})):
			has_core_tag = true
			break
	if has_core_tag:
		_missed_core_tag_streak = 0
		return
	_missed_core_tag_streak += 1
	if _missed_core_tag_streak < pity_threshold:
		return
	var matching_pool: Array[String] = []
	for skill_id in eligible:
		if not result.has(skill_id) and _matches_selected_loadout(skills.get(skill_id, {})):
			matching_pool.append(skill_id)
	if matching_pool.is_empty():
		return
	result[result.size() - 1] = matching_pool.pick_random()
	_missed_core_tag_streak = 0

func _skill_max_level(row: Dictionary) -> int:
	var max_value := 0
	for level_row in row.get("levels", []):
		if level_row is Dictionary:
			max_value = maxi(max_value, int(level_row.get("lv", 0)))
	return maxi(max_value, 3)

func _build_bias(level: Dictionary) -> Dictionary:
	var bias: Dictionary = level.get("card_bias", {}).duplicate(true)
	for tag in level.get("threat_tags", []):
		match str(tag):
			"fast":
				bias["control"] = float(bias.get("control", 1.0)) + 0.9
				bias["ice"] = float(bias.get("ice", 1.0)) + 0.6
			"tank":
				bias["pierce"] = float(bias.get("pierce", 1.0)) + 0.8
				bias["execute"] = float(bias.get("execute", 1.0)) + 0.6
			"support":
				bias["homing"] = float(bias.get("homing", 1.0)) + 0.7
				bias["chain"] = float(bias.get("chain", 1.0)) + 0.6
			"burst":
				bias["defense"] = float(bias.get("defense", 1.0)) + 0.8
			"breach":
				bias["anti_swarm"] = float(bias.get("anti_swarm", 1.0)) + 0.7
	var save_manager = _save_manager()
	var data_loader = _data_loader()
	if save_manager != null and data_loader != null:
		var character_id: String = str(save_manager.get_selected("character"))
		var weapon_id: String = str(save_manager.get_selected("weapon"))
		for tag in data_loader.get_row("characters", character_id).get("card_affinity_tags", []):
			bias[str(tag)] = float(bias.get(str(tag), 1.0)) + 1.1
		var weapon_element := str(data_loader.get_row("weapons", weapon_id).get("element", "physical"))
		if weapon_element != "":
			bias[weapon_element] = float(bias.get(weapon_element, 1.0)) + 1.2
	if data_loader != null:
		var economy_rules: Dictionary = data_loader.get_table("economy").get("card_director", {})
		var boost_until := int(economy_rules.get("early_fun_card_boost_until_level", 0))
		if boost_until > 0:
			var level_number := int(str(level.get("id", "")).trim_prefix("level_"))
			if level_number > 0 and level_number <= boost_until:
				# 新手期弱化"经济"类卡的存在感,把牌面让给清群/破甲/连锁这类
				# 立刻有反馈的战斗卡,economy.json 的 early_fun_card_boost_until_level。
				bias["economy"] = maxf(0.3, float(bias.get("economy", 1.0)) - 0.5)
	return bias

func root_has_save_manager() -> bool:
	return _save_manager() != null

func _matches_selected_loadout(row: Dictionary) -> bool:
	var save_manager = _save_manager()
	var data_loader = _data_loader()
	if save_manager == null or data_loader == null:
		return false
	var character_id: String = str(save_manager.get_selected("character"))
	var weapon_id: String = str(save_manager.get_selected("weapon"))
	var character: Dictionary = data_loader.get_row("characters", character_id)
	var weapon: Dictionary = data_loader.get_row("weapons", weapon_id)
	var tags: Array = row.get("card_tags", [])
	for tag in character.get("card_affinity_tags", []):
		if tags.has(tag):
			return true
	var element: String = str(weapon.get("element", ""))
	return element != "" and tags.has(element)

func _allowed_by_selected_weapon(skill_id: String, row: Dictionary, owned: Dictionary) -> bool:
	if str(row.get("exclusive_group", "")) != "projectile_element":
		return true
	var save_manager = _save_manager()
	var data_loader = _data_loader()
	if save_manager == null or data_loader == null:
		return true
	var weapon_id: String = str(save_manager.get_selected("weapon"))
	var weapon: Dictionary = data_loader.get_row("weapons", weapon_id)
	var weapon_element := str(weapon.get("element", "physical"))
	var ammo_element := str(row.get("ammo_element", ""))
	if weapon_element != "" and weapon_element != "physical":
		return ammo_element == weapon_element
	var current_level := int(owned.get(skill_id, 0))
	if current_level > 0:
		return true
	for other_id in owned.keys():
		if int(owned.get(other_id, 0)) <= 0:
			continue
		var other_row: Dictionary = data_loader.get_row("skills", str(other_id))
		if str(other_row.get("exclusive_group", "")) == "projectile_element" and str(other_id) != skill_id:
			return false
	return true

func _data_loader():
	var loop := Engine.get_main_loop()
	if loop == null or not loop is SceneTree:
		return null
	return (loop as SceneTree).root.get_node_or_null("/root/DataLoader")

func _save_manager():
	var loop := Engine.get_main_loop()
	if loop == null or not loop is SceneTree:
		return null
	return (loop as SceneTree).root.get_node_or_null("/root/SaveManager")
