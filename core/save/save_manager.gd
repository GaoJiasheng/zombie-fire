extends Node

const SAVE_PATH := "user://save_main.json"
const BACKUP_PATH := "user://save_backup.json"
const CURRENT_SAVE_VERSION := 1
const POWER_REFERENCE_CARD_PICKS := 4
const POWER_SKILL_THROUGHPUT_CAP := 13.5
const POWER_SKILL_SCORE_EXPONENT := 0.5
const POWER_PER_SIG_SKILL_LEVEL := 3.00
const POWER_SIG_SKILL_BASE := 1.80
const POWER_SIG_SKILL_LEVEL_SCALE := 0.65

enum PurchaseResult { OK, ALREADY_OWNED, NOT_ENOUGH_STAR, INVALID }

var _save_path := SAVE_PATH
var _backup_path := BACKUP_PATH
var _last_persistence_error := ""

var save_data := {
	"version": CURRENT_SAVE_VERSION,
	"player": {"gold": 0, "xp": 0, "star": 0},
	"levels_progress": {},
	"challenge_progress": {},
	"skill_base_levels": {},
	"sig_skill_levels": {},
	"endless_best_loops": 0,
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
		"version": CURRENT_SAVE_VERSION,
		"player": {"gold": 0, "xp": 0, "star": 0},
		"levels_progress": {},
		"challenge_progress": {},
		"skill_base_levels": {},
		"sig_skill_levels": {},
		"endless_best_loops": 0,
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
	if FileAccess.file_exists(_save_path):
		var main_record := _read_save_record(_save_path, "main save")
		if not main_record.is_empty():
			save_data = main_record["data"]
			var repaired := _refresh_level_unlocks_from_progress()
			if bool(main_record.get("requires_write", false)) or repaired:
				save_game()
			return

		var corrupt_preserved := _preserve_corrupt_file(_save_path)
		var backup_record := _read_save_record(_backup_path, "backup save") if FileAccess.file_exists(_backup_path) else {}
		if not backup_record.is_empty():
			save_data = backup_record["data"]
			_refresh_level_unlocks_from_progress()
			if corrupt_preserved:
				_write_save_atomically(_save_path, save_data, "recovered main save")
			return

		save_data = _default_save()
		if corrupt_preserved:
			_write_save_atomically(_save_path, save_data, "replacement main save")
		return

	var backup_record := _read_save_record(_backup_path, "backup save") if FileAccess.file_exists(_backup_path) else {}
	if not backup_record.is_empty():
		save_data = backup_record["data"]
		_refresh_level_unlocks_from_progress()
		_write_save_atomically(_save_path, save_data, "recovered missing main save")
		return

	save_data = _default_save()
	_write_save_atomically(_save_path, save_data, "initial main save")

func _merged_save(parsed: Dictionary) -> Dictionary:
	var prepared := _prepare_save(parsed, "save payload")
	return prepared if not prepared.is_empty() else _default_save()

func save_game() -> void:
	var prepared := _prepare_save(save_data, "in-memory save")
	if prepared.is_empty():
		return

	var previous_main: Dictionary = {}
	if FileAccess.file_exists(_save_path):
		var previous_record := _read_save_record(_save_path, "existing main save")
		if previous_record.is_empty():
			if not _preserve_corrupt_file(_save_path):
				_report_persistence_error("refusing to overwrite an invalid main save that could not be preserved")
				return
		else:
			previous_main = previous_record["data"]

	if not _write_save_atomically(_save_path, prepared, "main save"):
		return

	save_data = prepared
	if not previous_main.is_empty():
		_write_save_atomically(_backup_path, previous_main, "automatic backup")

func backup_game() -> void:
	var prepared := _prepare_save(save_data, "in-memory backup")
	if not prepared.is_empty():
		_write_save_atomically(_backup_path, prepared, "manual backup")

func has_backup() -> bool:
	return FileAccess.file_exists(_backup_path) and not _read_save_record(_backup_path, "backup save").is_empty()

func restore_backup() -> bool:
	if not FileAccess.file_exists(_backup_path):
		return false
	var backup_record := _read_save_record(_backup_path, "backup save")
	if backup_record.is_empty():
		return false
	var restored: Dictionary = backup_record["data"]
	var original_data := save_data
	save_data = restored
	_refresh_level_unlocks_from_progress()
	restored = save_data
	save_data = original_data

	if FileAccess.file_exists(_save_path):
		var main_record := _read_save_record(_save_path, "main save before restore")
		if main_record.is_empty() and not _preserve_corrupt_file(_save_path):
			_report_persistence_error("refusing to restore over an invalid main save that could not be preserved")
			return false
	if not _write_save_atomically(_save_path, restored, "restored main save"):
		return false
	save_data = restored
	return true

func _read_save_record(path: String, label: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_report_persistence_error("cannot open %s at %s: %s" % [label, path, error_string(FileAccess.get_open_error())])
		return {}
	var contents := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error != OK:
		_report_persistence_error("cannot read %s at %s: %s" % [label, path, error_string(read_error)])
		return {}

	var json := JSON.new()
	var parse_error := json.parse(contents)
	if parse_error != OK:
		_report_persistence_error("cannot parse %s at %s (line %d): %s" % [label, path, json.get_error_line(), json.get_error_message()])
		return {}
	var parsed: Variant = json.data
	var prepared := _prepare_save(parsed, label)
	if prepared.is_empty():
		return {}
	return {
		"data": prepared,
		"requires_write": prepared != parsed
	}

func _prepare_save(candidate: Variant, label: String) -> Dictionary:
	if not candidate is Dictionary:
		_report_persistence_error("%s root must be a dictionary" % label)
		return {}
	var migrated := _migrate_save(candidate)
	if migrated.is_empty():
		_report_persistence_error("%s has an unsupported or invalid version" % label)
		return {}
	if not _validate_save_shape(migrated, label):
		return {}
	var merged := _merge_defaults_recursive(_default_save(), migrated)
	merged["version"] = CURRENT_SAVE_VERSION
	return merged

func _migrate_save(candidate: Dictionary) -> Dictionary:
	var migrated: Dictionary = candidate.duplicate(true)
	var version := _save_version(migrated)
	if version < 0 or version > CURRENT_SAVE_VERSION:
		return {}
	while version < CURRENT_SAVE_VERSION:
		match version:
			0:
				migrated = _migrate_v0_to_v1(migrated)
			_:
				return {}
		var next_version := _save_version(migrated)
		if next_version <= version:
			return {}
		version = next_version
	return migrated

func _migrate_v0_to_v1(candidate: Dictionary) -> Dictionary:
	var migrated: Dictionary = candidate.duplicate(true)
	# Legacy unlocks remain owned; defaults add only fields absent from the old save.
	migrated["version"] = 1
	return migrated

func _save_version(candidate: Dictionary) -> int:
	if not candidate.has("version"):
		return 0
	var raw_version: Variant = candidate["version"]
	if typeof(raw_version) != TYPE_INT and typeof(raw_version) != TYPE_FLOAT:
		return -1
	var numeric_version := float(raw_version)
	if not is_finite(numeric_version) or numeric_version != floorf(numeric_version):
		return -1
	return int(numeric_version)

func _validate_save_shape(candidate: Dictionary, label: String) -> bool:
	for required_key in ["player", "unlocks", "equipment"]:
		if not candidate.has(required_key) or not candidate[required_key] is Dictionary:
			_report_persistence_error("%s is missing dictionary field '%s'" % [label, required_key])
			return false
	if not _matches_default_schema(candidate, _default_save()):
		_report_persistence_error("%s contains a known field with an invalid type" % label)
		return false
	for progress_key in ["levels_progress", "challenge_progress", "skill_base_levels", "sig_skill_levels"]:
		var progress: Dictionary = candidate.get(progress_key, {})
		for value in progress.values():
			if not _is_finite_number(value):
				_report_persistence_error("%s field '%s' contains a non-numeric value" % [label, progress_key])
				return false
	var unlocks: Dictionary = candidate["unlocks"]
	for unlock_key in ["levels", "characters", "weapons", "armors", "chips", "pets"]:
		for item_id in unlocks.get(unlock_key, []):
			if typeof(item_id) != TYPE_STRING:
				_report_persistence_error("%s unlock list '%s' contains a non-string id" % [label, unlock_key])
				return false
	var equipment: Dictionary = candidate["equipment"]
	for equipment_key in equipment.keys():
		var equipment_value: Variant = equipment[equipment_key]
		if str(equipment_key).begins_with("selected_"):
			if typeof(equipment_value) != TYPE_STRING:
				_report_persistence_error("%s equipment selection '%s' must be a string" % [label, equipment_key])
				return false
		elif not _is_finite_number(equipment_value):
			_report_persistence_error("%s equipment level '%s' must be numeric" % [label, equipment_key])
			return false
	return true

func _is_finite_number(value: Variant) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	return is_finite(float(value))

func _matches_default_schema(value: Variant, default_value: Variant) -> bool:
	if default_value is Dictionary:
		if not value is Dictionary:
			return false
		for key in default_value.keys():
			if value.has(key) and not _matches_default_schema(value[key], default_value[key]):
				return false
		return true
	if default_value is Array:
		return value is Array
	var default_type := typeof(default_value)
	var value_type := typeof(value)
	if default_type == TYPE_INT or default_type == TYPE_FLOAT:
		return value_type == TYPE_INT or value_type == TYPE_FLOAT
	return value_type == default_type

func _merge_defaults_recursive(defaults: Dictionary, candidate: Dictionary) -> Dictionary:
	var merged: Dictionary = defaults.duplicate(true)
	for key in candidate.keys():
		if merged.has(key) and merged[key] is Dictionary and candidate[key] is Dictionary:
			merged[key] = _merge_defaults_recursive(merged[key], candidate[key])
		else:
			merged[key] = candidate[key]
	return merged

func _write_save_atomically(path: String, data: Dictionary, label: String) -> bool:
	var prepared := _prepare_save(data, label)
	if prepared.is_empty():
		return false
	var temp_path := "%s.tmp" % path
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		_report_persistence_error("cannot open temporary %s at %s: %s" % [label, temp_path, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(prepared, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		_report_persistence_error("cannot flush temporary %s at %s: %s" % [label, temp_path, error_string(write_error)])
		_discard_temp_file(temp_path)
		return false

	var verification := _read_save_record(temp_path, "temporary %s" % label)
	if verification.is_empty():
		_report_persistence_error("temporary %s failed validation at %s" % [label, temp_path])
		_discard_temp_file(temp_path)
		return false
	var rename_error := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path))
	if rename_error != OK:
		_report_persistence_error("cannot atomically replace %s at %s: %s" % [label, path, error_string(rename_error)])
		_discard_temp_file(temp_path)
		return false
	return true

func _preserve_corrupt_file(path: String) -> bool:
	var source := FileAccess.open(path, FileAccess.READ)
	if source == null:
		_report_persistence_error("cannot open invalid save for preservation at %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return false
	var source_length := source.get_length()
	var bytes := source.get_buffer(source_length)
	source.close()
	if bytes.size() != source_length:
		_report_persistence_error("cannot read all bytes from invalid save at %s" % path)
		return false
	var corrupt_path := _next_corrupt_copy_path(path)
	if not _write_bytes_atomically(corrupt_path, bytes, "corrupt save copy"):
		return false
	print("SaveManager: preserved invalid save at %s" % corrupt_path)
	return true

func _next_corrupt_copy_path(path: String) -> String:
	var extension := path.get_extension()
	var base := path.get_basename() if extension != "" else path
	var suffix := ".%s" % extension if extension != "" else ""
	var timestamp := int(Time.get_unix_time_from_system())
	var candidate := "%s.corrupt.%d%s" % [base, timestamp, suffix]
	var sequence := 1
	while FileAccess.file_exists(candidate) or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(candidate)):
		candidate = "%s.corrupt.%d.%d%s" % [base, timestamp, sequence, suffix]
		sequence += 1
	return candidate

func _write_bytes_atomically(path: String, bytes: PackedByteArray, label: String) -> bool:
	var temp_path := "%s.tmp" % path
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		_report_persistence_error("cannot open temporary %s at %s: %s" % [label, temp_path, error_string(FileAccess.get_open_error())])
		return false
	file.store_buffer(bytes)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		_report_persistence_error("cannot flush temporary %s at %s: %s" % [label, temp_path, error_string(write_error)])
		_discard_temp_file(temp_path)
		return false

	var verification := FileAccess.open(temp_path, FileAccess.READ)
	if verification == null:
		_report_persistence_error("cannot reopen temporary %s at %s: %s" % [label, temp_path, error_string(FileAccess.get_open_error())])
		_discard_temp_file(temp_path)
		return false
	var verified_bytes := verification.get_buffer(verification.get_length())
	verification.close()
	if verified_bytes != bytes:
		_report_persistence_error("temporary %s byte verification failed at %s" % [label, temp_path])
		_discard_temp_file(temp_path)
		return false
	var rename_error := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path))
	if rename_error != OK:
		_report_persistence_error("cannot atomically place %s at %s: %s" % [label, path, error_string(rename_error)])
		_discard_temp_file(temp_path)
		return false
	return true

func _discard_temp_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _report_persistence_error(message: String) -> void:
	_last_persistence_error = message
	push_error("SaveManager: %s" % message)

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

func apply_challenge_result(result: Dictionary, persist := true) -> void:
	var level_id := str(result.get("level_id", ""))
	if level_id == "" or DataLoader.get_row("levels", level_id).is_empty():
		push_error("Cannot apply challenge result without a valid level_id: %s" % str(result))
		return
	var stars: int = int(result.get("stars", 0))
	var challenge_progress: Dictionary = save_data.get("challenge_progress", {})
	var player: Dictionary = save_data.get("player", {})
	var previous: int = int(challenge_progress.get(level_id, 0))
	var star_delta: int = max(stars - previous, 0)
	if stars > previous:
		challenge_progress[level_id] = stars
	player["gold"] = int(player.get("gold", 0)) + int(result.get("gold", 0))
	player["xp"] = int(player.get("xp", 0)) + int(result.get("xp", 0))
	player["star"] = int(player.get("star", 0)) + star_delta
	save_data["challenge_progress"] = challenge_progress
	save_data["player"] = player
	if persist:
		save_game()

# 无限尸潮结算：只发金币，不发经验/星星，不写 levels_progress/unlocks。
# 不影响正常关卡的星级记录、星币、经验和解锁进度。
func apply_endless_result(result: Dictionary, persist := true) -> void:
	var loops := int(result.get("endless_loop", 0))
	var player: Dictionary = save_data.get("player", {})
	player["gold"] = int(player.get("gold", 0)) + int(result.get("gold", 0))
	save_data["player"] = player
	if loops > int(save_data.get("endless_best_loops", 0)):
		save_data["endless_best_loops"] = loops
	if persist:
		save_game()

func get_endless_best_loops() -> int:
	return int(save_data.get("endless_best_loops", 0))

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
	var reference_levels := _projected_run_skill_levels(POWER_REFERENCE_CARD_PICKS, "")
	return int(round(_loadout_core_power() * _skill_power_scale(reference_levels)))

func get_projected_combat_power_for_level(level_id: String) -> int:
	var level := DataLoader.get_row("levels", level_id)
	var card_picks := maxi(1, int(level.get("target_card_picks", POWER_REFERENCE_CARD_PICKS)))
	var weakness := str(level.get("primary_weakness", "physical"))
	var projected_levels := _projected_run_skill_levels(card_picks, weakness)
	return get_combat_power_for_skill_levels(projected_levels)

func get_combat_power_for_skill_levels(run_skill_levels: Dictionary) -> int:
	return int(round(_loadout_core_power() * _skill_power_scale(run_skill_levels)))

func get_power_breakdown_for_level(level_id: String, challenge := false) -> Dictionary:
	var recommended := get_recommended_power_for_level(level_id)
	if challenge:
		recommended = int(ceil(float(recommended) * 1.5))
	return {
		"standing": get_loadout_power(),
		"projected": get_projected_combat_power_for_level(level_id),
		"recommended": recommended,
	}

func _loadout_core_power() -> float:
	var character_id := get_selected("character")
	var weapon_id := get_selected("weapon")
	if character_id == "":
		character_id = "vanguard"
	if weapon_id == "":
		weapon_id = "weapon_autocannon"
	var armor_id := get_selected("armor")
	var chip_id := get_selected("chip")
	var pet_id := get_selected("pet")
	var power := 0.0
	var char_level := get_item_level(character_id)
	var character := DataLoader.get_row("characters", character_id)
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var armor := DataLoader.get_row("armors", armor_id)
	var character_offense := float(character.get("base_atk", 100.0)) / 100.0 * float(character.get("fire_rate_mod", 1.0))
	var weapon_quality := sqrt(maxf(_weapon_effective_dps(weapon) / 4.0, 0.35))
	power += float(char_level) * 1.15 * character_offense
	power += float(get_item_level(weapon_id)) * 1.45 * weapon_quality
	if armor_id != "":
		power += float(get_item_level(armor_id)) * 0.85 * sqrt(maxf(float(armor.get("hp_mult", 1.0)), 0.5))
	if chip_id != "":
		power += float(get_item_level(chip_id)) * 0.75 * _chip_power_quality(chip_id)
	if pet_id != "":
		power += float(get_item_level(pet_id)) * 0.55
		power += _pet_stat_power(pet_id)
	if character_id != "":
		var sig_count := int(DataLoader.get_row("characters", character_id).get("signature_skills", []).size())
		power += float(sig_count) * (POWER_SIG_SKILL_BASE + POWER_SIG_SKILL_LEVEL_SCALE * float(char_level))
		power += float(get_sig_skill_level(character_id)) * POWER_PER_SIG_SKILL_LEVEL
	return maxf(power, 1.0)

func _projected_run_skill_levels(card_picks: int, weakness: String) -> Dictionary:
	var projected: Dictionary = {}
	var skills_table: Dictionary = DataLoader.get_table("skills")
	if skills_table.is_empty():
		return projected
	_seed_projected_weapon_element(projected, skills_table)
	for _pick in range(maxi(card_picks, 0)):
		var current_score := _combat_skill_effect_multiplier(projected)
		var best_score := current_score
		var best_id := ""
		var best_levels: Dictionary = {}
		var ids := skills_table.keys()
		ids.sort()
		for id_var in ids:
			var skill_id := str(id_var)
			var row: Dictionary = skills_table.get(skill_id, {})
			if not _power_skill_compatible_with_weapon(row):
				continue
			var candidate := _power_candidate_skill_levels(projected, skill_id, row, skills_table)
			if candidate.is_empty():
				continue
			var candidate_score := _combat_skill_effect_multiplier(candidate)
			if str(row.get("ammo_element", "")) == weakness:
				candidate_score += 0.015
			if candidate_score > best_score + 0.0001:
				best_score = candidate_score
				best_id = skill_id
				best_levels = candidate
		if best_id == "":
			break
		projected = best_levels
	return projected

func _seed_projected_weapon_element(projected: Dictionary, skills_table: Dictionary) -> void:
	var weapon_id := get_selected("weapon")
	if weapon_id == "":
		weapon_id = "weapon_autocannon"
	var weapon_element := str(DataLoader.get_row("weapons", weapon_id).get("element", "physical"))
	if weapon_element == "" or weapon_element == "physical":
		return
	for id_var in skills_table.keys():
		var skill_id := str(id_var)
		var row: Dictionary = skills_table.get(skill_id, {})
		if str(row.get("exclusive_group", "")) != "projectile_element":
			continue
		if str(row.get("ammo_element", "")) != weapon_element:
			continue
		projected[skill_id] = clampi(maxi(get_skill_base_level(skill_id), 1), 1, _power_skill_max_level(row))
		return

func _power_candidate_skill_levels(current: Dictionary, skill_id: String, row: Dictionary, skills_table: Dictionary) -> Dictionary:
	var max_level := _power_skill_max_level(row)
	var current_level := int(current.get(skill_id, 0))
	if current_level >= max_level:
		return {}
	var next_level := mini(max_level, current_level + 1)
	if current_level <= 0:
		next_level = clampi(maxi(get_skill_base_level(skill_id), 1), 1, max_level)
	var candidate: Dictionary = current.duplicate(true)
	var exclusive_group := str(row.get("exclusive_group", ""))
	if exclusive_group != "":
		for peer_var in skills_table.keys():
			var peer_id := str(peer_var)
			if peer_id == skill_id:
				continue
			var peer: Dictionary = skills_table.get(peer_id, {})
			if str(peer.get("exclusive_group", "")) == exclusive_group:
				candidate.erase(peer_id)
	candidate[skill_id] = next_level
	return candidate

func _power_skill_max_level(row: Dictionary) -> int:
	var result := 1
	for entry_var in row.get("levels", []):
		if entry_var is Dictionary:
			result = maxi(result, int((entry_var as Dictionary).get("lv", 1)))
	return result

func _power_skill_compatible_with_weapon(row: Dictionary) -> bool:
	if str(row.get("exclusive_group", "")) != "projectile_element":
		return true
	var weapon_id := get_selected("weapon")
	if weapon_id == "":
		weapon_id = "weapon_autocannon"
	var weapon_element := str(DataLoader.get_row("weapons", weapon_id).get("element", "physical"))
	return weapon_element == "" or weapon_element == "physical" or str(row.get("ammo_element", "")) == weapon_element

func _skill_power_scale(run_skill_levels: Dictionary) -> float:
	return pow(_combat_skill_effect_multiplier(run_skill_levels), POWER_SKILL_SCORE_EXPONENT)

func _combat_skill_effect_multiplier(run_skill_levels: Dictionary) -> float:
	var damage_add := 0.0
	var fire_rate_add := 0.0
	var crit_add := 0.0
	var crit_damage_add := 0.0
	var extra_projectiles := 0
	var pierce := 0
	var split := 0
	var split_falloff := 0.55
	var chain := 0
	var homing := 0.0
	var burn := 0.0
	var poison := 0.0
	var slow := 0.0
	var barrier_hp := 0.0
	var armor_penetration := 0.0
	for id_var in run_skill_levels.keys():
		var skill_id := str(id_var)
		var effect := _power_skill_effect(skill_id, int(run_skill_levels.get(id_var, 0)))
		damage_add += float(effect.get("dmg_mult", 0.0))
		fire_rate_add += float(effect.get("fire_rate_mult", 0.0))
		crit_add += float(effect.get("crit_add", 0.0))
		crit_damage_add += float(effect.get("crit_dmg", 0.0))
		extra_projectiles = maxi(extra_projectiles, int(effect.get("extra_projectiles", 0)))
		pierce += int(effect.get("pierce", 0))
		split = maxi(split, int(effect.get("split", 0)))
		if effect.has("falloff"):
			split_falloff = float(effect.get("falloff", split_falloff))
		chain += int(effect.get("chain", 0))
		homing += float(effect.get("homing", 0.0))
		burn += float(effect.get("burn", 0.0))
		poison += float(effect.get("poison", 0.0))
		slow += float(effect.get("slow", 0.0))
		barrier_hp += float(effect.get("base_hp_mult", 0.0))
		armor_penetration += float(effect.get("armor_penetration", 0.0))
	var direct_factor := maxf(1.0, 1.0 + damage_add)
	var cadence_factor := maxf(1.0, 1.0 + fire_rate_add)
	var base_crit_rate := 0.08
	var base_crit_expectation := 1.0 + base_crit_rate * 0.85
	var upgraded_crit_expectation := 1.0 + clampf(base_crit_rate + crit_add, 0.0, 0.85) * (0.85 + crit_damage_add)
	var crit_factor := maxf(1.0, upgraded_crit_expectation / base_crit_expectation)
	var lane_count := clampi(1 + extra_projectiles, 1, 5)
	var lane_total := float(lane_count) * _power_multishot_lane_damage(lane_count)
	var lane_factor := 1.0 + maxf(0.0, lane_total - 1.0) * 0.55
	var secondary_gain := float(pierce) * 0.075
	secondary_gain += float(split) * clampf(split_falloff, 0.0, 1.0) * 0.11
	secondary_gain += float(chain) * 0.09
	secondary_gain += homing * 0.03
	var coverage_factor := 1.0 + minf(1.75, secondary_gain)
	var status_factor := 1.0 + burn * 0.28 + poison * 0.32
	var penetration_factor := 1.0 + clampf(armor_penetration, 0.0, 0.95) * 0.22
	var offense := direct_factor * cadence_factor * crit_factor * lane_factor * coverage_factor * status_factor * penetration_factor
	var survival := 1.0 + maxf(0.0, barrier_hp) * 0.22 + clampf(slow, 0.0, 0.75) * 0.30
	var combined := 1.0 + maxf(0.0, offense - 1.0) * 0.82 + maxf(0.0, survival - 1.0) * 0.18
	return clampf(combined, 1.0, POWER_SKILL_THROUGHPUT_CAP)

func _power_multishot_lane_damage(lane_count: int) -> float:
	match clampi(lane_count, 1, 5):
		1:
			return 1.0
		2:
			return 0.85
		3:
			return 0.80
		4:
			return 0.75
		_:
			return 0.70

func _power_skill_effect(skill_id: String, level: int) -> Dictionary:
	if level <= 0:
		return {}
	var chosen: Dictionary = {}
	for entry_var in DataLoader.get_row("skills", skill_id).get("levels", []):
		if entry_var is Dictionary:
			var entry := entry_var as Dictionary
			if int(entry.get("lv", 0)) <= level:
				chosen = entry.get("effect", {})
	return chosen

func _weapon_effective_dps(weapon: Dictionary) -> float:
	if weapon.is_empty():
		return 4.0
	var effective := float(weapon.get("base_atk_coef", 1.0)) * float(weapon.get("fire_rate", 4.0))
	var special: Dictionary = weapon.get("special", {})
	var pellets := maxi(1, int(special.get("pellets", 1)))
	if pellets > 1:
		effective *= 1.0 + float(pellets - 1) * 0.62
	effective *= 1.0 + 0.18 * float(special.get("pierce", 0))
	effective *= 1.0 + 0.36 * float(special.get("chain", 0))
	if float(special.get("splash", 0.0)) > 0.0 or float(special.get("cloud", 0.0)) > 0.0:
		effective *= 1.28
	effective *= 1.0 + 0.65 * (float(special.get("burn", 0.0)) + float(special.get("poison", 0.0)))
	return effective

func _chip_power_quality(chip_id: String) -> float:
	var chip := DataLoader.get_row("chips", chip_id)
	match str(chip.get("stat", "")):
		"damage_mult", "fire_rate_mult", "element_damage_mult":
			return 1.12
		"crit_rate", "pierce_bonus":
			return 1.08
		"base_hp_mult", "breach_damage_reduction":
			return 1.04
		_:
			return 1.0

func _pet_stat_power(pet_id: String) -> float:
	if pet_id == "":
		return 0.0
	var row := DataLoader.get_row("pets", pet_id)
	if row.is_empty():
		return 0.0
	var level := get_item_level(pet_id)
	var base_map: Dictionary = row.get("stat_bonus", {})
	var growth_map: Dictionary = row.get("level_stat_growth", {})
	var score := 0.0
	for stat in base_map.keys():
		var value := float(base_map.get(stat, 0.0)) + float(growth_map.get(stat, 0.0)) * float(max(level - 1, 0))
		match str(stat):
			"damage_mult", "fire_rate_mult", "element_damage_mult", "base_hp_mult":
				score += value * 16.0
			"crit_rate", "breach_damage_reduction", "slow_strength_mult", "gold_mult":
				score += value * 10.0
			"chain_bonus", "pierce_bonus":
				score += value * 1.4
			_:
				score += value * 4.0
	return score

# 推荐战力和玩家战力使用同一套“战前核心 + 局内技能成型”量纲。
# 四次选卡是战力面板的基准；更多选卡带来的乘法协同会同时抬高关卡推荐值和晚波压力。
const RECOMMENDED_POWER_COEF := 6.25
func get_recommended_power_for_level(level_id: String) -> int:
	var level := DataLoader.get_row("levels", level_id)
	var recommended := int(level.get("recommend_level", 1))
	var boss_bonus := 0
	for wave in level.get("waves", []):
		if wave.has("boss"):
			boss_bonus = 6
			break
	var late_wave_bonus := _recommended_power_late_wave_bonus(level)
	var base_power := float(recommended) * RECOMMENDED_POWER_COEF + float(boss_bonus + late_wave_bonus)
	return int(round(base_power * get_card_budget_power_factor_for_level(level_id)))

func get_card_budget_power_factor_for_level(level_id: String) -> float:
	var level := DataLoader.get_row("levels", level_id)
	var card_picks := maxi(1, int(level.get("target_card_picks", POWER_REFERENCE_CARD_PICKS)))
	var economy: Dictionary = DataLoader.get_table("economy")
	var pressure_var = economy.get("run_skill_pressure", {})
	var pressure: Dictionary = pressure_var if pressure_var is Dictionary else {}
	var reference_picks := maxi(1, int(pressure.get("reference_card_picks", POWER_REFERENCE_CARD_PICKS)))
	var reference := _generic_card_skill_throughput(reference_picks)
	var current := _generic_card_skill_throughput(card_picks)
	return maxf(1.0, pow(current / maxf(reference, 0.01), POWER_SKILL_SCORE_EXPONENT))

func get_run_skill_hp_pressure_for_level(level_id: String) -> float:
	return _run_skill_pressure_for_level(level_id, "hp_conversion", "max_hp_mult", 0.65, 1.60)

func get_run_skill_speed_pressure_for_level(level_id: String) -> float:
	return _run_skill_pressure_for_level(level_id, "speed_conversion", "max_speed_mult", 0.15, 1.15)

func _run_skill_pressure_for_level(level_id: String, conversion_key: String, cap_key: String, fallback_conversion: float, fallback_cap: float) -> float:
	var economy: Dictionary = DataLoader.get_table("economy")
	var pressure_var = economy.get("run_skill_pressure", {})
	var pressure: Dictionary = pressure_var if pressure_var is Dictionary else {}
	var factor := get_card_budget_power_factor_for_level(level_id)
	var conversion := maxf(0.0, float(pressure.get(conversion_key, fallback_conversion)))
	var cap := maxf(1.0, float(pressure.get(cap_key, fallback_cap)))
	return minf(cap, 1.0 + maxf(0.0, factor - 1.0) * conversion)

func _generic_card_skill_throughput(card_picks: int) -> float:
	var picks := float(maxi(card_picks, 0))
	return minf(POWER_SKILL_THROUGHPUT_CAP, 1.0 + 0.42 * picks + 0.08 * picks * picks)

func _recommended_power_late_wave_bonus(level: Dictionary) -> int:
	var economy: Dictionary = DataLoader.get_table("economy")
	var level_parts := str(level.get("id", "level_001")).split("_")
	var level_no := int(level_parts[level_parts.size() - 1]) if level_parts.size() > 0 else 1
	var ramp_mult := _recommended_power_late_wave_ramp_mult(economy, level_no)
	var late_score := 0.0
	var table_var = economy.get("late_wave_hp_bonus", {})
	var boss_table_var = economy.get("late_wave_boss_hp_bonus", {})
	var count_table_var = economy.get("late_wave_count_mult", {})
	var table: Dictionary = table_var if table_var is Dictionary else {}
	var boss_table: Dictionary = boss_table_var if boss_table_var is Dictionary else {}
	var count_table: Dictionary = count_table_var if count_table_var is Dictionary else {}
	for wave in level.get("waves", []):
		var wave_no := int(wave.get("wave", 0))
		if wave_no < 3:
			continue
		var wave_mult := float(table.get(str(wave_no), table.get(wave_no, 1.0))) * ramp_mult
		late_score += maxf(0.0, wave_mult - 1.0)
		var count_mult := float(count_table.get(str(wave_no), count_table.get(wave_no, 1.0)))
		late_score += maxf(0.0, count_mult - 1.0) * 0.9
		if wave.has("boss"):
			var boss_mult := float(boss_table.get(str(wave_no), boss_table.get(wave_no, 1.0))) * ramp_mult
			late_score += maxf(0.0, boss_mult - 1.0) * 0.85
	return int(round(late_score * 4.0))

func _recommended_power_late_wave_ramp_mult(economy: Dictionary, level_no: int) -> float:
	var rule_var = economy.get("late_wave_level_ramp", {})
	var rule: Dictionary = rule_var if rule_var is Dictionary else {}
	var start_level := float(rule.get("start_level", 9999))
	var full_level := float(rule.get("full_level", start_level))
	var max_mult := float(rule.get("max_mult", 1.0))
	var curve_power := maxf(0.01, float(rule.get("curve_power", 1.0)))
	if float(level_no) < start_level:
		return 1.0
	var ramp_mult := max_mult
	if full_level > start_level:
		var t := clampf((float(level_no) - start_level) / (full_level - start_level), 0.0, 1.0)
		ramp_mult = lerpf(1.0, max_mult, pow(t, curve_power))
	var final_level := int(rule.get("final_level", 0))
	if final_level > 0 and level_no >= final_level:
		ramp_mult *= maxf(1.0, float(rule.get("final_mult", 1.0)))
	return ramp_mult

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

func is_challenge_unlocked(level_id: String) -> bool:
	return is_level_unlocked(level_id) and get_level_stars(level_id) >= 3

# 无限尸潮的难度"种子"：玩家已合法解锁的最高一关(僵尸/环境/元素弱点数据都从它复用)。
func get_highest_unlocked_level_id() -> String:
	var rows: Array = DataLoader.get_table("levels")
	var best := "level_001"
	for row in rows:
		var lvid := str(row.get("id", ""))
		if is_level_unlocked(lvid):
			best = lvid
	return best

func get_level_stars(level_id: String) -> int:
	var levels_progress: Dictionary = save_data.get("levels_progress", {})
	return int(levels_progress.get(level_id, 0))

func get_challenge_stars(level_id: String) -> int:
	var challenge_progress: Dictionary = save_data.get("challenge_progress", {})
	return int(challenge_progress.get(level_id, 0))

func get_total_stars() -> int:
	var levels_progress: Dictionary = save_data.get("levels_progress", {})
	var challenge_progress: Dictionary = save_data.get("challenge_progress", {})
	var total := 0
	for level_id in levels_progress.keys():
		total += int(levels_progress.get(level_id, 0))
	for level_id in challenge_progress.keys():
		total += int(challenge_progress.get(level_id, 0))
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
