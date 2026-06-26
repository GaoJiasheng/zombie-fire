extends Node

const SAVE_PATH := "user://save_main.json"
const BACKUP_PATH := "user://save_backup.json"

var save_data := {
	"version": 1,
	"player": {"gold": 0, "xp": 0, "star": 0},
	"levels_progress": {},
	"unlocks": {
		"levels": ["level_001"],
		"characters": ["vanguard"],
		"weapons": ["weapon_autocannon"],
		"armors": ["armor_kevlar"],
		"chips": ["chip_attack"],
		"pets": []
	},
	"equipment": {
		"vanguard": 1,
		"weapon_autocannon": 1,
		"armor_kevlar": 1,
		"chip_attack": 1,
		"selected_character": "vanguard",
		"selected_weapon": "weapon_autocannon",
		"selected_armor": "armor_kevlar",
		"selected_chip": "chip_attack",
		"selected_pet": ""
	}
}

func _default_save() -> Dictionary:
	return {
		"version": 1,
		"player": {"gold": 0, "xp": 0, "star": 0},
		"levels_progress": {},
		"unlocks": {
			"levels": ["level_001"],
			"characters": ["vanguard"],
			"weapons": ["weapon_autocannon"],
			"armors": ["armor_kevlar"],
			"chips": ["chip_attack"],
			"pets": []
		},
		"equipment": {
			"vanguard": 1,
			"weapon_autocannon": 1,
			"armor_kevlar": 1,
			"chip_attack": 1,
			"selected_character": "vanguard",
			"selected_weapon": "weapon_autocannon",
			"selected_armor": "armor_kevlar",
			"selected_chip": "chip_attack",
			"selected_pet": ""
		}
	}

func reset_game() -> void:
	backup_game()
	save_data = _default_save()
	save_game()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_game()
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed is Dictionary:
		save_data = _merged_save(parsed)
		_refresh_star_unlocks()
		repair_progression_unlocks()

func _merged_save(parsed: Dictionary) -> Dictionary:
	var merged := _default_save()
	for key in parsed.keys():
		if merged.has(key) and merged[key] is Dictionary and parsed[key] is Dictionary:
			var nested: Dictionary = merged[key]
			nested.merge(parsed[key], true)
			merged[key] = nested
		else:
			merged[key] = parsed[key]
	return merged

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data, "\t"))

func backup_game() -> void:
	var file := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data, "\t"))

func has_backup() -> bool:
	return FileAccess.file_exists(BACKUP_PATH)

func restore_backup() -> bool:
	if not has_backup():
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BACKUP_PATH))
	if not parsed is Dictionary:
		return false
	save_data = _merged_save(parsed)
	save_game()
	return true

func apply_level_result(result: Dictionary, persist := true) -> void:
	var level_id := str(result.get("level_id", ""))
	if level_id == "" or DataLoader.get_row("levels", level_id).is_empty():
		push_error("Cannot apply level result without a valid level_id: %s" % str(result))
		return
	var stars: int = int(result.get("stars", 0))
	var victory := bool(result.get("victory", stars > 0))
	var levels_progress: Dictionary = save_data.get("levels_progress", {})
	var player: Dictionary = save_data.get("player", {})
	var unlocks: Dictionary = save_data.get("unlocks", {})
	var unlocked_levels: Array = unlocks.get("levels", ["level_001"])
	var previous: int = int(levels_progress.get(level_id, 0))
	var star_delta: int = max(stars - previous, 0)
	if stars > previous:
		levels_progress[level_id] = stars
	player["gold"] = int(player.get("gold", 0)) + int(result.get("gold", 0))
	player["xp"] = int(player.get("xp", 0)) + int(result.get("xp", 0))
	player["star"] = int(player.get("star", 0)) + star_delta
	var next_level: String = str(result.get("next_level", ""))
	if next_level == "" and victory:
		next_level = str(DataLoader.get_row("levels", level_id).get("next_level", ""))
	if victory and next_level != "" and not unlocked_levels.has(next_level):
		unlocked_levels.append(next_level)
	unlocks["levels"] = unlocked_levels
	save_data["levels_progress"] = levels_progress
	save_data["player"] = player
	save_data["unlocks"] = unlocks
	_refresh_level_unlocks_from_progress()
	_refresh_star_unlocks()
	if persist:
		save_game()

func repair_progression_unlocks() -> bool:
	var changed := _refresh_level_unlocks_from_progress()
	if changed:
		save_game()
	return changed

func _refresh_level_unlocks_from_progress() -> bool:
	var changed := false
	var unlocks: Dictionary = save_data.get("unlocks", {})
	var unlocked_levels: Array = unlocks.get("levels", ["level_001"])
	if not unlocked_levels.has("level_001"):
		unlocked_levels.append("level_001")
		changed = true
	var levels_progress: Dictionary = save_data.get("levels_progress", {})
	for level in DataLoader.get_table("levels"):
		var level_id := str(level.get("id", ""))
		if level_id == "":
			continue
		var stars := int(levels_progress.get(level_id, 0))
		if stars <= 0:
			continue
		if not unlocked_levels.has(level_id):
			unlocked_levels.append(level_id)
			changed = true
		var next_level := str(level.get("next_level", ""))
		if next_level != "" and not unlocked_levels.has(next_level):
			unlocked_levels.append(next_level)
			changed = true
	unlocks["levels"] = unlocked_levels
	save_data["unlocks"] = unlocks
	return changed

func _refresh_star_unlocks() -> void:
	var unlocks: Dictionary = save_data.get("unlocks", {})
	_unlock_by_table(unlocks, "characters", "characters")
	_unlock_by_table(unlocks, "weapons", "weapons")
	_unlock_by_table(unlocks, "armors", "armors")
	_unlock_by_table(unlocks, "chips", "chips")
	_unlock_by_table(unlocks, "pets", "pets")
	save_data["unlocks"] = unlocks

func _unlock_by_table(unlocks: Dictionary, unlock_key: String, table: String) -> void:
	var items: Array = unlocks.get(unlock_key, [])
	var table_data: Dictionary = DataLoader.get_table(table)
	for id: String in table_data.keys():
		var row: Dictionary = DataLoader.get_row(table, id)
		var unlock_rule: Dictionary = row.get("unlock", {})
		var cost: int = int(row.get("unlock_cost_star", unlock_rule.get("price", 999999)))
		var unlock_type: String = str(unlock_rule.get("type", "stars"))
		if unlock_type == "default" or cost <= get_total_stars():
			if not items.has(id):
				items.append(id)
	unlocks[unlock_key] = items

func get_weapon_level(weapon_id: String) -> int:
	return get_item_level(weapon_id)

func get_item_level(item_id: String) -> int:
	var equipment: Dictionary = save_data.get("equipment", {})
	return int(equipment.get(item_id, 1))

func get_selected(slot: String) -> String:
	var equipment: Dictionary = save_data.get("equipment", {})
	return str(equipment.get("selected_%s" % slot, ""))

func select_item(slot: String, item_id: String) -> bool:
	if item_id == "":
		var equipment_empty: Dictionary = save_data.get("equipment", {})
		equipment_empty["selected_%s" % slot] = ""
		save_data["equipment"] = equipment_empty
		save_game()
		return true
	var unlock_key: String = "%ss" % slot
	if slot == "armor":
		unlock_key = "armors"
	var unlocks: Dictionary = save_data.get("unlocks", {})
	var items: Array = unlocks.get(unlock_key, [])
	if not items.has(item_id):
		return false
	var equipment: Dictionary = save_data.get("equipment", {})
	equipment["selected_%s" % slot] = item_id
	save_data["equipment"] = equipment
	save_game()
	return true

func is_item_unlocked(slot: String, item_id: String) -> bool:
	if item_id == "":
		return true
	var unlock_key: String = "%ss" % slot
	if slot == "armor":
		unlock_key = "armors"
	var unlocks: Dictionary = save_data.get("unlocks", {})
	var items: Array = unlocks.get(unlock_key, [])
	return items.has(item_id)

func get_weapon_damage_multiplier(weapon_id: String) -> float:
	return 1.0 + 0.08 * float(max(get_weapon_level(weapon_id) - 1, 0))

func get_weapon_fire_rate_multiplier(weapon_id: String) -> float:
	return 1.0 + 0.025 * float(max(get_weapon_level(weapon_id) - 1, 0))

func get_loadout_power() -> int:
	var character_id := get_selected("character")
	var weapon_id := get_selected("weapon")
	var armor_id := get_selected("armor")
	var chip_id := get_selected("chip")
	var pet_id := get_selected("pet")
	var power := 0.0
	power += float(get_item_level(character_id)) * 1.15
	power += float(get_item_level(weapon_id)) * 1.45
	power += float(get_item_level(armor_id)) * 0.85
	power += float(get_item_level(chip_id)) * 0.75
	if pet_id != "":
		power += float(get_item_level(pet_id)) * 0.55
	return int(round(power))

func get_recommended_power_for_level(level_id: String) -> int:
	var level := DataLoader.get_row("levels", level_id)
	var recommended := int(level.get("recommend_level", 1))
	var boss_bonus := 0
	for wave in level.get("waves", []):
		if wave.has("boss"):
			boss_bonus = 2
			break
	return int(round(float(recommended) * 4.3 + float(boss_bonus)))

func get_player_gold() -> int:
	var player: Dictionary = save_data.get("player", {})
	return int(player.get("gold", 0))

func get_weapon_upgrade_cost(weapon_id: String) -> int:
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var base_cost := int(weapon.get("cost_base_gold", 100))
	return _scaled_upgrade_cost(base_cost, get_weapon_level(weapon_id))

func get_item_upgrade_cost(table: String, item_id: String) -> int:
	if table == "weapons":
		return get_weapon_upgrade_cost(item_id)
	var row := DataLoader.get_row(table, item_id)
	var base_cost := int(row.get("cost_base_gold", row.get("upgrade_cost_gold", _default_upgrade_cost(table))))
	return _scaled_upgrade_cost(base_cost, get_item_level(item_id))

func _scaled_upgrade_cost(base_cost: int, current_level: int) -> int:
	var economy: Dictionary = DataLoader.get_table("economy")
	var growth := float(economy.get("upgrade_cost_growth", 1.15))
	var level: int = max(current_level, 1)
	var tier_step := 1.0 + 0.08 * float((level - 1) / 10)
	return int(round(float(base_cost) * pow(growth, float(level - 1)) * tier_step))

func _default_upgrade_cost(table: String) -> int:
	match table:
		"characters":
			return 160
		"armors":
			return 130
		"chips":
			return 120
		"pets":
			return 140
		_:
			return 100

func can_upgrade_weapon(weapon_id: String) -> bool:
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var max_level := int(weapon.get("max_level", 1))
	return get_weapon_level(weapon_id) < max_level and get_player_gold() >= get_weapon_upgrade_cost(weapon_id)

func upgrade_weapon(weapon_id: String) -> bool:
	return upgrade_item("weapons", weapon_id)

func can_upgrade_item(table: String, item_id: String) -> bool:
	if item_id == "":
		return false
	var slot := _slot_for_table(table)
	if slot != "" and not is_item_unlocked(slot, item_id):
		return false
	var row := DataLoader.get_row(table, item_id)
	var max_level := int(row.get("max_level", 30))
	return get_item_level(item_id) < max_level and get_player_gold() >= get_item_upgrade_cost(table, item_id)

func upgrade_item(table: String, item_id: String) -> bool:
	if not can_upgrade_item(table, item_id):
		return false
	var equipment: Dictionary = save_data.get("equipment", {})
	var player: Dictionary = save_data.get("player", {})
	var current_level := get_item_level(item_id)
	player["gold"] = get_player_gold() - get_item_upgrade_cost(table, item_id)
	equipment[item_id] = current_level + 1
	save_data["equipment"] = equipment
	save_data["player"] = player
	save_game()
	return true

func _slot_for_table(table: String) -> String:
	match table:
		"characters":
			return "character"
		"weapons":
			return "weapon"
		"armors":
			return "armor"
		"chips":
			return "chip"
		"pets":
			return "pet"
		_:
			return ""

func is_level_unlocked(level_id: String) -> bool:
	var unlocks: Dictionary = save_data.get("unlocks", {})
	var levels: Array = unlocks.get("levels", ["level_001"])
	return levels.has(level_id)

func get_level_stars(level_id: String) -> int:
	var levels_progress: Dictionary = save_data.get("levels_progress", {})
	return int(levels_progress.get(level_id, 0))

func get_total_stars() -> int:
	var levels_progress: Dictionary = save_data.get("levels_progress", {})
	var total := 0
	for level_id in levels_progress.keys():
		total += int(levels_progress.get(level_id, 0))
	return total
