class_name CardDirector
extends RefCounted

# 连续多少次三选一都没命中角色/武器适配技能后触发保底(economy.json 的
# pity_after_missing_core_tag)；实例跟随 battle 生命周期存活，天然按局重置。
var _missed_core_tag_streak := 0
var _offer_index := 0
var _audit_rng: RandomNumberGenerator


# Headless audits may isolate card randomness from unrelated VFX/gameplay RNG.
# Player builds never call this method, so the default path below remains the
# exact Array.pick_random() behavior used before the audit hook existed.
func set_audit_seed(value: int) -> void:
	_audit_rng = RandomNumberGenerator.new()
	_audit_rng.seed = value


func _pick_random(values: Array) -> Variant:
	if values.is_empty():
		return null
	if _audit_rng == null:
		return values.pick_random()
	return values[_audit_rng.randi_range(0, values.size() - 1)]

func offer(level: Dictionary, owned: Dictionary, count := 3) -> Array[String]:
	var weighted: Array[String] = []
	var eligible: Array[String] = []
	var bias := _build_bias(level)
	var data_loader = _data_loader()
	if data_loader == null:
		return []
	var skills: Dictionary = data_loader.get_table("skills")
	var skill_ids: Array = skills.keys()
	skill_ids.sort()
	for skill_id_var in skill_ids:
		var skill_id := str(skill_id_var)
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
		var picked: String = str(_pick_random(weighted))
		var picked_row: Dictionary = skills.get(picked, {})
		var picked_tags: Array = picked_row.get("card_tags", [])
		var is_economy := picked_tags.has("economy")
		if not result.has(picked) and (not is_economy or economy_count < max_economy):
			result.append(picked)
			if is_economy:
				economy_count += 1
		weighted = weighted.filter(func(id: String) -> bool: return id != picked)
	_offer_index += 1
	_apply_opening_shape(result, eligible, skills, economy_rules, level)
	_apply_pity(result, eligible, skills, economy_rules)
	_apply_level_guarantee(result, eligible, skills, level)
	_apply_offer_category_floor(result, eligible, skills, economy, level, owned)
	return result


# Chapter pilots may guarantee that every offer contains one card from a broad
# pressure category without promising a specific skill.  The branch is a hard
# no-op when the level omits offer_category_floor: it performs no extra random
# draw and therefore preserves the exact offer stream for all existing stages.
func _apply_offer_category_floor(
	result: Array[String],
	eligible: Array[String],
	skills: Dictionary,
	economy: Dictionary,
	level: Dictionary,
	owned: Dictionary
) -> void:
	var category := str(level.get("offer_category_floor", "")).strip_edges()
	if category == "" or result.is_empty():
		return
	var policy: Dictionary = economy.get("probe_card_policy", {})
	if policy.is_empty():
		return
	for skill_id in result:
		if _has_policy_category(skills.get(skill_id, {}).get("card_tags", []), category, policy):
			return
	var replacement_pool: Array[String] = []
	for skill_id in eligible:
		if result.has(skill_id):
			continue
		var tags: Array = skills.get(skill_id, {}).get("card_tags", [])
		if _has_policy_category(tags, category, policy):
			replacement_pool.append(skill_id)
	if replacement_pool.is_empty():
		return
	var protected_ids := _current_guaranteed_ids(level)
	var replace_index := _lowest_policy_priority_index(result, skills, policy, level, owned, protected_ids)
	result[replace_index] = str(_pick_random(replacement_pool))


func _current_guaranteed_ids(level: Dictionary) -> Array[String]:
	var protected: Array[String] = []
	for rule_var in level.get("guaranteed_card_offers", []):
		if not rule_var is Dictionary:
			continue
		var rule := rule_var as Dictionary
		if int(rule.get("offer", -1)) != _offer_index:
			continue
		for skill_id_var in rule.get("skill_ids", []):
			protected.append(str(skill_id_var))
	return protected


func _lowest_policy_priority_index(
	result: Array[String],
	skills: Dictionary,
	policy: Dictionary,
	level: Dictionary,
	owned: Dictionary,
	protected_ids: Array[String] = []
) -> int:
	var boss_share := float(level.get("clear_requirement", {}).get("boss_hp_share", 0.0))
	var boss_dominant := boss_share >= float(policy.get("boss_hp_share_threshold", 0.5))
	var priorities: Array = policy.get("boss_priority", []) if boss_dominant else policy.get("mob_priority", [])
	var weapon_element := _selected_weapon_element()
	var worst_index := result.size() - 1
	var worst_rank := -1
	for index in range(result.size()):
		var skill_id := result[index]
		if protected_ids.has(skill_id):
			continue
		var tags: Array = skills.get(skill_id, {}).get("card_tags", [])
		var reason := _policy_reason(
			tags,
			int(owned.get(skill_id, 0)) > 0,
			boss_dominant,
			weapon_element,
			policy
		)
		var rank := priorities.find(reason)
		if rank < 0:
			rank = priorities.find("remaining")
		if rank < 0:
			rank = priorities.size()
		# On ties replace the later card, preserving the earlier offer ordering.
		if rank >= worst_rank:
			worst_rank = rank
			worst_index = index
	return worst_index


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


func _card_matches_weapon_element(tags: Array, weapon_element: String, policy: Dictionary) -> bool:
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


func _selected_weapon_element() -> String:
	var save_manager = _save_manager()
	var data_loader = _data_loader()
	if save_manager == null or data_loader == null:
		return "physical"
	var weapon_id := str(save_manager.get_selected("weapon"))
	return str(data_loader.get_row("weapons", weapon_id).get("element", "physical"))

# A level may promise one exact family of cards on a specific offer. This is
# deliberately data-driven and only guarantees visibility, not an automatic
# selection. level_099 uses it to make either Barrier or Slow Field available
# before its two-Boss pressure test; the power ruler therefore may conservatively
# count the weaker of those two choices instead of pretending random defence is
# guaranteed in every stage.
func _apply_level_guarantee(result: Array[String], eligible: Array[String], skills: Dictionary, level: Dictionary) -> void:
	if result.is_empty():
		return
	for rule_var in level.get("guaranteed_card_offers", []):
		if not rule_var is Dictionary:
			continue
		var rule := rule_var as Dictionary
		if int(rule.get("offer", -1)) != _offer_index:
			continue
		var guaranteed_ids: Array = rule.get("skill_ids", [])
		for skill_id_var in guaranteed_ids:
			if result.has(str(skill_id_var)):
				return
		for skill_id_var in guaranteed_ids:
			var skill_id := str(skill_id_var)
			if eligible.has(skill_id) and not result.has(skill_id) and skills.has(skill_id):
				result[result.size() - 1] = skill_id
				return

func _apply_opening_shape(result: Array[String], eligible: Array[String], skills: Dictionary, economy_rules: Dictionary, level: Dictionary) -> void:
	var opening_offers := maxi(0, int(economy_rules.get("opening_identity_offer_count", 2)))
	if _offer_index > opening_offers or result.is_empty():
		return
	if bool(economy_rules.get("opening_avoid_economy", true)):
		for index in range(result.size()):
			var row: Dictionary = skills.get(result[index], {})
			if row.get("card_tags", []).has("economy"):
				_replace_with_tags(result, eligible, skills, index, ["projectile", "element", "control", "defense"], true)
	_replace_with_loadout_match(result, eligible, skills, 0)
	if _offer_index == 1:
		if result.size() > 1:
			_replace_with_tags(result, eligible, skills, 1, economy_rules.get("opening_damage_tags", ["anti_swarm", "projectile", "dps"]), true)
		if result.size() > 2:
			_replace_with_tags(result, eligible, skills, 2, economy_rules.get("opening_safety_tags", ["control", "defense"]), true)
	elif result.size() > 1:
		_replace_with_tags(result, eligible, skills, 1, _counter_tags_for_level(level), true)

func _replace_with_loadout_match(result: Array[String], eligible: Array[String], skills: Dictionary, index: int) -> void:
	if index < 0 or index >= result.size():
		return
	if _matches_selected_loadout(skills.get(result[index], {})):
		return
	for skill_id in eligible:
		if result.has(skill_id) or not _matches_selected_loadout(skills.get(skill_id, {})):
			continue
		result[index] = skill_id
		return

func _replace_with_tags(result: Array[String], eligible: Array[String], skills: Dictionary, index: int, wanted_tags: Array, reject_economy: bool) -> void:
	if index < 0 or index >= result.size():
		return
	var current_tags: Array = skills.get(result[index], {}).get("card_tags", [])
	if _has_any_tag(current_tags, wanted_tags) and (not reject_economy or not current_tags.has("economy")):
		return
	for skill_id in eligible:
		if result.has(skill_id):
			continue
		var tags: Array = skills.get(skill_id, {}).get("card_tags", [])
		if reject_economy and tags.has("economy"):
			continue
		if _has_any_tag(tags, wanted_tags):
			result[index] = skill_id
			return

func _has_any_tag(tags: Array, wanted_tags: Array) -> bool:
	for tag in wanted_tags:
		if tags.has(tag):
			return true
	return false

func _counter_tags_for_level(level: Dictionary) -> Array:
	var tags: Array = []
	for threat in level.get("threat_tags", []):
		match str(threat):
			"fast": tags.append_array(["control", "ice"])
			"tank": tags.append_array(["anti_armor", "pierce", "execute"])
			"support": tags.append_array(["homing", "chain"])
			"burst": tags.append("defense")
			"breach": tags.append_array(["anti_swarm", "defense"])
	if tags.is_empty():
		tags = ["anti_swarm", "control", "defense"]
	return tags

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
	result[result.size() - 1] = str(_pick_random(matching_pool))
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
