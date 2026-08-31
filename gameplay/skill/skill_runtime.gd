class_name SkillRuntime
extends RefCounted

const SLOW_FIELD_DESIGN_BASE_LINE_Y := 1500.0

var owned := {}
var _order: Array[String] = []

func add_skill(skill_id: String) -> bool:
	var current := level(skill_id)
	if current >= max_level(skill_id):
		return false
	var next_level := level_after_add(skill_id)
	var group := _exclusive_group(skill_id)
	if group != "":
		_remove_exclusive_peers(skill_id, group)
	if not owned.has(skill_id):
		_order.append(skill_id)
	owned[skill_id] = next_level
	return true

func owned_order() -> Array[String]:
	return _order.duplicate()

func level(skill_id: String) -> int:
	return int(owned.get(skill_id, 0))

func level_after_add(skill_id: String) -> int:
	var maximum := max_level(skill_id)
	if maximum <= 0:
		return 0
	var current := level(skill_id)
	if current > 0:
		return mini(current + 1, maximum)
	return clampi(maxi(_base_level(skill_id), 1), 1, maximum)

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
	return max_value if max_value > 0 else 3

func _data_loader() -> Node:
	var loop := Engine.get_main_loop()
	if loop == null or not loop is SceneTree:
		return null
	return (loop as SceneTree).root.get_node_or_null("/root/DataLoader")

func _save_manager() -> Node:
	var loop := Engine.get_main_loop()
	if loop == null or not loop is SceneTree:
		return null
	return (loop as SceneTree).root.get_node_or_null("/root/SaveManager")

func _base_level(skill_id: String) -> int:
	var sm := _save_manager()
	if sm == null:
		return 0
	return int(sm.get_skill_base_level(skill_id))

func can_add_skill(skill_id: String) -> bool:
	return level(skill_id) < max_level(skill_id)

# --- Data-driven effects: values come from data/skills.json per current level ---

func _current_effect(skill_id: String) -> Dictionary:
	var lv := level(skill_id)
	if lv <= 0:
		return {}
	var levels: Array = _skill_row(skill_id).get("levels", [])
	var chosen: Dictionary = {}
	for entry in levels:
		if entry is Dictionary and int(entry.get("lv", 0)) <= lv:
			chosen = entry.get("effect", {})
	return chosen

func _eff(skill_id: String, key: String, default_value := 0.0) -> float:
	return float(_current_effect(skill_id).get(key, default_value))

func projectile_mods() -> Dictionary:
	var split_falloff := 0.55
	if level("skill_split_shot") > 0:
		split_falloff = _eff("skill_split_shot", "falloff", 0.55)
	return {
		"pierce": int(_eff("skill_pierce", "pierce") + _eff("skill_homing", "pierce")),
		"extra_projectiles": int(_eff("skill_multishot", "extra_projectiles")),
		"multishot_lane_damage_bonus": _eff("skill_multishot", "lane_damage_bonus"),
		"spread_deg": 8.0 + _eff("skill_multishot", "spread"),
		"split": int(_eff("skill_split_shot", "split")),
		"split_falloff": split_falloff,
		"homing": _eff("skill_homing", "homing"),
		"ricochet": int(_eff("skill_ricochet", "chain")),
		"chain": int(_eff("skill_ricochet", "chain") + _eff("skill_tesla", "chain"))
	}

func projectile_status_strength(element: String) -> float:
	match element:
		"fire":
			return _eff("skill_incendiary", "burn", 0.22)
		"ice":
			return _eff("skill_cryo", "slow", 0.18)
		"poison":
			return _eff("skill_venom", "poison", 0.16)
		"lightning":
			return 1.0 if level("skill_tesla") > 0 else 0.0
		_:
			return 0.0

func fire_rate_multiplier() -> float:
	return 1.0 + _eff("skill_salvo", "fire_rate_mult")

func slow_cap(is_boss := false) -> float:
	var fallback := 0.40 if is_boss else 0.80
	var data_loader := _data_loader()
	if data_loader == null:
		return fallback
	var economy: Dictionary = data_loader.get_table("economy")
	var pacing_var: Variant = economy.get("boss_pacing", {})
	var pacing: Dictionary = pacing_var if pacing_var is Dictionary else {}
	var key := "boss_slow_cap" if is_boss else "mob_slow_cap"
	return clampf(float(pacing.get(key, fallback)), 0.0, 0.95)

func slow_speed_floor(is_boss := false) -> float:
	return 1.0 - slow_cap(is_boss)

func slow_mult_for_y(
	y: float,
	base_line_y: float = SLOW_FIELD_DESIGN_BASE_LINE_Y,
	is_boss := false,
) -> float:
	var slow := _eff("skill_slow_field", "slow") + _eff("skill_cryo", "slow")
	if slow <= 0.0:
		return 1.0
	var y_min := base_line_y - 340.0
	if level("skill_slow_field") > 0:
		var design_y_min := _eff("skill_slow_field", "y_min", 820.0)
		var design_offset := maxf(0.0, SLOW_FIELD_DESIGN_BASE_LINE_Y - design_y_min)
		y_min = base_line_y - design_offset
	if y < y_min:
		return 1.0
	# Small enemies retain the authored control ceiling. Bosses read their
	# separate resistance ceiling from economy.json so runtime and audits agree.
	return max(slow_speed_floor(is_boss), 1.0 - slow)

func damage_multiplier() -> float:
	return 1.0 \
		+ _eff("skill_charge_shot", "dmg_mult") \
		+ _eff("skill_critical", "dmg_mult") \
		+ _eff("skill_pierce", "dmg_mult") \
		+ _eff("skill_incendiary", "dmg_mult") \
		+ _eff("skill_cryo", "dmg_mult") \
		+ _eff("skill_tesla", "dmg_mult") \
		+ _eff("skill_venom", "dmg_mult")

func crit_bonus() -> float:
	return _eff("skill_critical", "crit_add")

func crit_damage_mult() -> float:
	# Base crit multiplier is 1.85; high-level critical adds a burst spike.
	return 1.85 + _eff("skill_critical", "crit_dmg")

func armor_penetration() -> float:
	return clampf(_eff("skill_charge_shot", "armor_penetration"), 0.0, 0.95)

func gold_multiplier() -> float:
	return 1.0 + _eff("skill_gold_rush", "gold_mult")

func barrier_base_hp_bonus() -> float:
	return _eff("skill_barrier", "base_hp_mult")

func barrier_shields() -> int:
	return 0

func barrier_gain() -> int:
	return 0

func reroll_gain() -> int:
	return maxi(1, int(_eff("skill_recycle", "reroll")))

func projectile_element(base_element: String, weapon_id := "") -> String:
	var resolved_weapon_id := weapon_id if weapon_id != "" else _selected_weapon_id()
	if base_element != "" and base_element != "physical" and not _weapon_allows_ammo_override(resolved_weapon_id):
		return base_element
	var active := active_ammo_skill()
	if active == "":
		return base_element
	var ammo := ammo_element_for_skill(active)
	return ammo if ammo != "" else base_element

func _selected_weapon_id() -> String:
	var save_manager := _save_manager()
	if save_manager == null:
		return ""
	return str(save_manager.get_selected("weapon"))

func _weapon_allows_ammo_override(weapon_id: String) -> bool:
	var data_loader := _data_loader()
	if data_loader == null or weapon_id == "":
		return false
	var weapon: Dictionary = data_loader.get_row("weapons", weapon_id)
	var set_id := str(weapon.get("premium_set", ""))
	if set_id == "":
		return false
	var set_row: Dictionary = data_loader.get_row("premium_sets", set_id)
	return str(set_row.get("weapon", "")) == weapon_id and bool(set_row.get("ammo_cards_override_base_element", false))

func active_ammo_skill() -> String:
	for index in range(_order.size() - 1, -1, -1):
		var skill_id := str(_order[index])
		if level(skill_id) > 0 and _exclusive_group(skill_id) == "projectile_element":
			return skill_id
	return ""

func ammo_element_for_skill(skill_id: String) -> String:
	return str(_skill_row(skill_id).get("ammo_element", ""))

func _remove_exclusive_peers(skill_id: String, group: String) -> void:
	var data_loader := _data_loader()
	if data_loader == null:
		return
	var table: Dictionary = data_loader.get_table("skills")
	for peer_id in table.keys():
		var peer := str(peer_id)
		if peer == skill_id:
			continue
		var row: Dictionary = table.get(peer, {})
		if str(row.get("exclusive_group", "")) != group:
			continue
		if owned.has(peer):
			owned.erase(peer)
			_order.erase(peer)

func _exclusive_group(skill_id: String) -> String:
	return str(_skill_row(skill_id).get("exclusive_group", ""))

func _skill_row(skill_id: String) -> Dictionary:
	var data_loader := _data_loader()
	if data_loader == null:
		return {}
	return data_loader.get_row("skills", skill_id)
