extends Node

const SAVE_PATH := "user://save_main.json"
const BACKUP_PATH := "user://save_backup.json"

enum PurchaseResult { OK, ALREADY_OWNED, NOT_ENOUGH_STAR, INVALID }

var save_data := {
	"version": 1,
	"player": {"gold": 0, "xp": 0, "star": 0},
	"levels_progress": {},
	"skill_base_levels": {},
	"sig_skill_levels": {},
	"unlocks": {
		"levels": ["level_001"],
		"characters": ["vanguard"],
		"weapons": ["weapon_autocannon"],
		"armors": [],
		"chips": [],
		"pets": []
	},
	"equipment": {
		"vanguard": 1,
		"weapon_autocannon": 1,
		"selected_character": "vanguard",
		"selected_weapon": "weapon_autocannon",
		"selected_armor": "",
		"selected_chip": "",
		"selected_pet": ""
	}
}

func _default_save() -> Dictionary:
	return {
		"version": 1,
		"player": {"gold": 0, "xp": 0, "star": 0},
		"levels_progress": {},
		"skill_base_levels": {},
	"sig_skill_levels": {},
		"unlocks": {
			"levels": ["level_001"],
			"characters": ["vanguard"],
			"weapons": ["weapon_autocannon"],
			"armors": [],
			"chips": [],
			"pets": []
		},
		"equipment": {
			"vanguard": 1,
			"weapon_autocannon": 1,
			"selected_character": "vanguard",
			"selected_weapon": "weapon_autocannon",
			"selected_armor": "",
			"selected_chip": "",
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
	var char_level := get_item_level(character_id)
	power += float(char_level) * 1.15
	power += float(get_item_level(weapon_id)) * 1.45
	power += float(get_item_level(armor_id)) * 0.85
	power += float(get_item_level(chip_id)) * 0.75
	if pet_id != "":
		power += float(get_item_level(pet_id)) * 0.55
	# 技能永久升级(通用技能 base level)——战力的大头，此前完全没算
	var skill_levels := 0
	for v in save_data.get("skill_base_levels", {}).values():
		skill_levels += int(v)
	power += float(skill_levels) * 1.30
	# 角色主动/专属技能(2 个 signature，威力随角色等级成长)
	if character_id != "":
		var sig_count := int(DataLoader.get_row("characters", character_id).get("signature_skills", []).size())
		power += float(sig_count) * (1.5 + 0.55 * float(char_level))
		# 专属主动技独立经验等级(新增的投资轴，见 get_sig_skill_level)
		power += float(get_sig_skill_level(character_id)) * 2.0
	return int(round(power))

# 系数校准(2026-07)：旧系数 4.3 是早期拍脑袋定的，从没和"真实可达战力"对过。
# 单角色全部装备/16通用技能/专属主动技全部满级，实测约 352 战力(见 design 里的推导记录)。
# 终章(recommend_level=50)按此系数算出 292，约为满配上限的 83%——即全满配玩家在终章前
# 仍有约 20% 战力余裕，而不是之前 1.6 倍那种"推荐值远低于真实上限"的失真。
const RECOMMENDED_POWER_COEF := 5.8
func get_recommended_power_for_level(level_id: String) -> int:
	var level := DataLoader.get_row("levels", level_id)
	var recommended := int(level.get("recommend_level", 1))
	var boss_bonus := 0
	for wave in level.get("waves", []):
		if wave.has("boss"):
			boss_bonus = 2
			break
	return int(round(float(recommended) * RECOMMENDED_POWER_COEF + float(boss_bonus)))

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
	var k := float(economy.get("upgrade_cost_linear_k", 0.7))
	var level: int = max(current_level, 1)
	return int(round(float(base_cost) * (1.0 + k * float(level - 1))))

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


# ===== 经济重构新增 API(见 design/19+20) =====
func get_player_star() -> int:
	return int(save_data.get("player", {}).get("star", 0))

func get_player_xp() -> int:
	return int(save_data.get("player", {}).get("xp", 0))

func is_default_free(item_id: String) -> bool:
	return item_id == "vanguard" or item_id == "weapon_autocannon"

func get_unlock_price_star(table: String, item_id: String) -> int:
	var row := DataLoader.get_row(table, item_id)
	return int(row.get("unlock_cost_star", row.get("unlock", {}).get("price", 0)))

func is_item_owned(table: String, item_id: String) -> bool:
	if item_id == "":
		return true
	var unlocks: Dictionary = save_data.get("unlocks", {})
	var items: Array = unlocks.get(table, [])
	return items.has(item_id)

func can_purchase(table: String, item_id: String) -> bool:
	if item_id == "" or is_item_owned(table, item_id):
		return false
	return get_player_star() >= get_unlock_price_star(table, item_id)

func purchase_item(table: String, item_id: String) -> int:
	if item_id == "" or DataLoader.get_row(table, item_id).is_empty():
		return PurchaseResult.INVALID
	if is_item_owned(table, item_id):
		return PurchaseResult.ALREADY_OWNED
	var price := get_unlock_price_star(table, item_id)
	if get_player_star() < price:
		return PurchaseResult.NOT_ENOUGH_STAR
	var player: Dictionary = save_data.get("player", {})
	player["star"] = get_player_star() - price
	save_data["player"] = player
	var unlocks: Dictionary = save_data.get("unlocks", {})
	var items: Array = unlocks.get(table, [])
	if not items.has(item_id):
		items.append(item_id)
	unlocks[table] = items
	save_data["unlocks"] = unlocks
	var equipment: Dictionary = save_data.get("equipment", {})
	if int(equipment.get(item_id, 0)) < 1:
		equipment[item_id] = 1
	save_data["equipment"] = equipment
	save_game()
	return PurchaseResult.OK

func get_skill_base_level(skill_id: String) -> int:
	return int(save_data.get("skill_base_levels", {}).get(skill_id, 0))

func get_skill_base_max(skill_id: String) -> int:
	var row := DataLoader.get_row("skills", skill_id)
	var levels: Array = row.get("levels", [])
	var m := 0
	for entry in levels:
		if entry is Dictionary:
			m = maxi(m, int(entry.get("lv", 0)))
	return maxi(m, 5)

func get_skill_base_upgrade_cost(skill_id: String) -> int:
	var economy: Dictionary = DataLoader.get_table("economy")
	var costs: Array = economy.get("skill_base_xp_costs", [50, 120, 220, 360, 540])
	var lvl := get_skill_base_level(skill_id)
	if lvl >= costs.size():
		return -1
	return int(costs[lvl])

func can_upgrade_skill_base(skill_id: String) -> bool:
	if get_skill_base_level(skill_id) >= get_skill_base_max(skill_id):
		return false
	var cost := get_skill_base_upgrade_cost(skill_id)
	return cost >= 0 and get_player_xp() >= cost

func upgrade_skill_base(skill_id: String) -> bool:
	if not can_upgrade_skill_base(skill_id):
		return false
	var cost := get_skill_base_upgrade_cost(skill_id)
	var player: Dictionary = save_data.get("player", {})
	player["xp"] = get_player_xp() - cost
	save_data["player"] = player
	var sbl: Dictionary = save_data.get("skill_base_levels", {})
	sbl[skill_id] = get_skill_base_level(skill_id) + 1
	save_data["skill_base_levels"] = sbl
	save_game()
	return true

const SIG_SKILL_MAX_LEVEL := 5

# 专属技能(主动技)独立经验升级——之前只有 16 个通用技能能花经验升级，专属技能只能
# 被动跟着角色等级涨，玩家没法针对性投资。以 character_id 为 key(每个角色只有一个
# 数据驱动的主动技 = characters.json 的 active_skill)。
func get_sig_skill_level(character_id: String) -> int:
	return int(save_data.get("sig_skill_levels", {}).get(character_id, 0))

func get_sig_skill_upgrade_cost(character_id: String) -> int:
	var economy: Dictionary = DataLoader.get_table("economy")
	var costs: Array = economy.get("sig_skill_xp_costs", [200, 550, 1200, 2400, 4200])
	var lvl := get_sig_skill_level(character_id)
	if lvl >= costs.size():
		return -1
	return int(costs[lvl])

func can_upgrade_sig_skill(character_id: String) -> bool:
	if get_sig_skill_level(character_id) >= SIG_SKILL_MAX_LEVEL:
		return false
	var cost := get_sig_skill_upgrade_cost(character_id)
	return cost >= 0 and get_player_xp() >= cost

func upgrade_sig_skill(character_id: String) -> bool:
	if not can_upgrade_sig_skill(character_id):
		return false
	var cost := get_sig_skill_upgrade_cost(character_id)
	var player: Dictionary = save_data.get("player", {})
	player["xp"] = get_player_xp() - cost
	save_data["player"] = player
	var ssl: Dictionary = save_data.get("sig_skill_levels", {})
	ssl[character_id] = get_sig_skill_level(character_id) + 1
	save_data["sig_skill_levels"] = ssl
	save_game()
	return true
