extends Node

const SAVE_PATH := "user://save_main.json"
const BACKUP_PATH := "user://save_backup.json"
const CURRENT_SAVE_VERSION := 4
const POWER_REFERENCE_CARD_PICKS := 4
const POWER_SKILL_THROUGHPUT_CAP := 13.5
const POWER_SKILL_SCORE_EXPONENT := 0.5

enum PurchaseResult { OK, ALREADY_OWNED, NOT_ENOUGH_STAR, INVALID }

var _save_path := SAVE_PATH
var _backup_path := BACKUP_PATH
var _last_persistence_error := ""
var _suppress_expected_persistence_errors_for_tests := false

var save_data := {
	"version": CURRENT_SAVE_VERSION,
	"player": {"gold": 0, "xp": 0, "star": 0},
	"levels_progress": {},
	"challenge_progress": {},
	"level_clear_counts": {},
	"challenge_clear_counts": {},
	"skill_base_levels": {},
	"sig_skill_levels": {},
	"endless_best_loops": 0,
	"cosmetics": {
		"selected_theme": "default",
		"character_outfits": {
			"vanguard": "follow_theme",
			"blaze": "follow_theme",
			"frost": "follow_theme",
			"volt": "follow_theme",
		},
	},
	"entitlements": {"verified": [], "last_sync_unix": 0},
	"commerce": {
		"mock_receipts": [],
		"mock_last_transaction_unix": 0,
	},
	"notices": {"power_scale_v6_seen": true},
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
		"level_clear_counts": {},
		"challenge_clear_counts": {},
		"skill_base_levels": {},
		"sig_skill_levels": {},
		"endless_best_loops": 0,
		"cosmetics": {
			"selected_theme": "default",
			"character_outfits": {
				"vanguard": "follow_theme",
				"blaze": "follow_theme",
				"frost": "follow_theme",
				"volt": "follow_theme",
			},
		},
		"entitlements": {"verified": [], "last_sync_unix": 0},
		"commerce": {
			"mock_receipts": [],
			"mock_last_transaction_unix": 0,
		},
		"notices": {"power_scale_v6_seen": true},
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
	var verified_entitlements: Dictionary = save_data.get(
		"entitlements",
		{"verified": [], "last_sync_unix": 0}
	).duplicate(true)
	save_data = _default_save()
	save_data["entitlements"] = verified_entitlements
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
			1:
				migrated = _migrate_v1_to_v2(migrated)
			2:
				migrated = _migrate_v2_to_v3(migrated)
			3:
				migrated = _migrate_v3_to_v4(migrated)
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

func _migrate_v1_to_v2(candidate: Dictionary) -> Dictionary:
	var migrated: Dictionary = candidate.duplicate(true)
	# Theme selection and verified permanent entitlements are additive. Existing
	# progression remains byte-for-byte compatible after defaults are merged.
	migrated["version"] = 2
	return migrated

func _migrate_v2_to_v3(candidate: Dictionary) -> Dictionary:
	var migrated: Dictionary = candidate.duplicate(true)
	# Local purchase receipts are deliberately separate from StoreKit-verified
	# entitlements. This lets the complete storefront flow be exercised without
	# ever making a mock transaction look like Apple commerce truth.
	migrated["version"] = 3
	return migrated

func _migrate_v3_to_v4(candidate: Dictionary) -> Dictionary:
	var migrated: Dictionary = candidate.duplicate(true)
	# Existing players see the v6 ruler explanation once. Fresh version-4 saves
	# default to already acknowledged because their first displayed value is v6.
	migrated["notices"] = {"power_scale_v6_seen": false}
	migrated["version"] = 4
	return migrated

func should_show_power_scale_v6_notice() -> bool:
	return not bool(save_data.get("notices", {}).get("power_scale_v6_seen", true))

func mark_power_scale_v6_notice_seen(persist := true) -> void:
	var notices: Dictionary = save_data.get("notices", {}).duplicate(true)
	notices["power_scale_v6_seen"] = true
	save_data["notices"] = notices
	if persist:
		save_game()

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
	for progress_key in ["levels_progress", "challenge_progress", "level_clear_counts", "challenge_clear_counts", "skill_base_levels", "sig_skill_levels"]:
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
	var cosmetics: Dictionary = candidate.get("cosmetics", {})
	if cosmetics.has("selected_theme") and typeof(cosmetics["selected_theme"]) != TYPE_STRING:
		_report_persistence_error("%s selected theme must be a string" % label)
		return false
	var character_outfits: Dictionary = cosmetics.get("character_outfits", {})
	for character_id in character_outfits.keys():
		if typeof(character_id) != TYPE_STRING or typeof(character_outfits[character_id]) != TYPE_STRING:
			_report_persistence_error("%s character outfits must map string ids to string modes" % label)
			return false
	var entitlements: Dictionary = candidate.get("entitlements", {})
	for entitlement_id in entitlements.get("verified", []):
		if typeof(entitlement_id) != TYPE_STRING:
			_report_persistence_error("%s verified entitlements must contain strings" % label)
			return false
	var commerce: Dictionary = candidate.get("commerce", {})
	for product_id in commerce.get("mock_receipts", []):
		if typeof(product_id) != TYPE_STRING:
			_report_persistence_error("%s mock receipts must contain product ids" % label)
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
	if _suppress_expected_persistence_errors_for_tests:
		print("SaveManager expected test failure: %s" % message)
	else:
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
	if victory:
		_bump_clear_count("level_clear_counts", level_id)
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

## 重复通关经验递减（design/24 收尾）。首通 100%、二周目 50%、三周目及以后 25%，
## 倍率表来自 data/economy.json.repeat_clear_xp_mult，代码内不写死。
## 取的是"本次通关之前"的通关次数，所以战斗结算必须在 apply_level_result /
## apply_challenge_result 递增计数之前调用它。
func get_repeat_clear_xp_mult(level_id: String, challenge := false) -> float:
	var table_var: Variant = DataLoader.get_table("economy").get("repeat_clear_xp_mult", [1.0])
	if not (table_var is Array) or (table_var as Array).is_empty():
		return 1.0
	var table: Array = table_var
	var index := clampi(get_clear_count(level_id, challenge), 0, table.size() - 1)
	return clampf(float(table[index]), 0.0, 1.0)

func get_clear_count(level_id: String, challenge := false) -> int:
	var key := "challenge_clear_counts" if challenge else "level_clear_counts"
	var counts: Dictionary = save_data.get(key, {})
	return maxi(0, int(counts.get(level_id, 0)))

func _bump_clear_count(key: String, level_id: String) -> void:
	var counts: Dictionary = save_data.get(key, {})
	counts[level_id] = maxi(0, int(counts.get(level_id, 0))) + 1
	save_data[key] = counts

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
	if bool(result.get("victory", stars > 0)):
		_bump_clear_count("challenge_clear_counts", level_id)
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

func get_selected_theme() -> String:
	var cosmetics: Dictionary = save_data.get("cosmetics", {})
	return str(cosmetics.get("selected_theme", "default"))

func select_theme(theme_id: String, persist := true) -> void:
	var cosmetics: Dictionary = save_data.get("cosmetics", {})
	cosmetics["selected_theme"] = theme_id
	save_data["cosmetics"] = cosmetics
	if persist:
		save_game()

func get_character_outfit(character_id: String) -> String:
	var cosmetics: Dictionary = save_data.get("cosmetics", {})
	var outfits: Dictionary = cosmetics.get("character_outfits", {})
	return str(outfits.get(character_id.trim_prefix("char_"), "follow_theme"))

func select_character_outfit(character_id: String, outfit_mode: String, persist := true) -> void:
	var normalized_character_id := character_id.trim_prefix("char_")
	var cosmetics: Dictionary = save_data.get("cosmetics", {})
	var outfits: Dictionary = cosmetics.get("character_outfits", {})
	outfits[normalized_character_id] = outfit_mode
	cosmetics["character_outfits"] = outfits
	save_data["cosmetics"] = cosmetics
	if persist:
		save_game()

func get_verified_entitlements() -> Array[String]:
	var output: Array[String] = []
	var entitlements: Dictionary = save_data.get("entitlements", {})
	for entitlement_id in entitlements.get("verified", []):
		var normalized := str(entitlement_id).strip_edges()
		if normalized != "" and not output.has(normalized):
			output.append(normalized)
	return output

func has_verified_entitlement(entitlement_id: String) -> bool:
	return get_verified_entitlements().has(entitlement_id)

func replace_verified_entitlements(entitlement_ids: Array[String], sync_unix: int, persist := true) -> void:
	var normalized: Array[String] = []
	for entitlement_id in entitlement_ids:
		var clean := entitlement_id.strip_edges()
		if clean != "" and not normalized.has(clean):
			normalized.append(clean)
	save_data["entitlements"] = {
		"verified": normalized,
		"last_sync_unix": maxi(sync_unix, 0),
	}
	if persist:
		save_game()

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
	var row := DataLoader.get_row("weapons", weapon_id)
	var level := get_weapon_level(weapon_id)
	return weapon_damage_multiplier_at_level(row, level)

func weapon_damage_multiplier_at_level(weapon: Dictionary, weapon_level: int, fire_rate_profile := "control") -> float:
	return weapon_level_damage_multiplier_from_row(weapon, weapon_level) * _weapon_endgame_growth_multiplier(weapon, weapon_level, fire_rate_profile)

func weapon_level_damage_multiplier_from_row(weapon: Dictionary, weapon_level: int) -> float:
	var level_offset := maxi(weapon_level - 1, 0)
	var segments_var: Variant = weapon.get("level_growth_segments", [])
	var segments: Array = segments_var if segments_var is Array else []
	# Preserve the legacy expression exactly for every existing weapon. This
	# branch is the zero-leakage contract for rows without segmented growth.
	if segments.is_empty():
		return 1.0 + 0.08 * float(level_offset)
	var multiplier := 1.0
	var cursor := 2
	for segment_var in segments:
		var segment: Dictionary = segment_var if segment_var is Dictionary else {}
		var from_level := int(segment.get("from_level", 2))
		var to_level := int(segment.get("to_level", int(weapon.get("max_level", weapon_level))))
		if weapon_level < from_level:
			multiplier += 0.08 * float(maxi(weapon_level - cursor + 1, 0))
			return multiplier
		multiplier += 0.08 * float(maxi(from_level - cursor, 0))
		var segment_end := mini(weapon_level, to_level)
		multiplier += float(segment.get("atk_growth_per_level", 0.08)) * float(maxi(segment_end - from_level + 1, 0))
		cursor = to_level + 1
		if weapon_level <= to_level:
			return multiplier
	multiplier += 0.08 * float(maxi(weapon_level - cursor + 1, 0))
	return multiplier

func weapon_standard_growth_cap_from_row(weapon: Dictionary) -> int:
	var segments_var: Variant = weapon.get("level_growth_segments", [])
	var segments: Array = segments_var if segments_var is Array else []
	if segments.is_empty():
		return maxi(2, int(weapon.get("max_level", 50)))
	var first_segment: Dictionary = segments[0] if segments[0] is Dictionary else {}
	return maxi(2, int(first_segment.get("from_level", 2)) - 1)

func weapon_standard_growth_level_from_row(weapon: Dictionary, weapon_level: int) -> int:
	var segments_var: Variant = weapon.get("level_growth_segments", [])
	var segments: Array = segments_var if segments_var is Array else []
	# Keep the historical input value and arithmetic path exact for every row
	# without segments. Segmented overcap levels add only their authored attack
	# growth; baseline cadence remains frozen at the pre-segment cap.
	if segments.is_empty():
		return weapon_level
	return mini(weapon_level, weapon_standard_growth_cap_from_row(weapon))

func weapon_endgame_growth_progress_from_row(weapon: Dictionary, weapon_level: int) -> float:
	var base_cap := weapon_standard_growth_cap_from_row(weapon)
	var growth_level := weapon_standard_growth_level_from_row(weapon, weapon_level)
	return clampf(float(growth_level - 1) / float(base_cap - 1), 0.0, 1.0)

func _weapon_endgame_growth_multiplier(weapon: Dictionary, weapon_level: int, fire_rate_profile := "control") -> float:
	var progress := weapon_endgame_growth_progress_from_row(weapon, weapon_level)
	var growth_bonus := maxf(float(weapon.get("endgame_damage_growth_bonus", 0.0)), 0.0)
	var profile_bonuses_var: Variant = weapon.get("profile_endgame_damage_growth_bonus", {})
	var profile_bonuses: Dictionary = profile_bonuses_var if profile_bonuses_var is Dictionary else {}
	growth_bonus += maxf(float(profile_bonuses.get(fire_rate_profile, 0.0)), 0.0)
	var growth_curve := maxf(1.0, float(weapon.get("endgame_growth_curve", 1.0)))
	return 1.0 + growth_bonus * pow(progress, growth_curve)

func get_weapon_fire_rate_multiplier(weapon_id: String) -> float:
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var growth_level := weapon_standard_growth_level_from_row(weapon, get_weapon_level(weapon_id))
	return 1.0 + 0.025 * float(max(growth_level - 1, 0))

func get_loadout_power() -> int:
	return get_power_for_level(get_highest_unlocked_level_id())

func get_projected_combat_power_for_level(level_id: String) -> int:
	return get_power_for_level(level_id)

# Runs a hypothetical equipment set through the exact same effective-power
# pipeline used by the loadout screen. The projection is synchronous and never
# persists or unlocks the supplied items; callers only receive the calculated
# number. This keeps commerce guidance tied to real player-facing math.
func power_for_build(level_id: String, build: Dictionary) -> int:
	var original_equipment_var: Variant = save_data.get("equipment", {})
	var original_equipment: Dictionary = (
		original_equipment_var.duplicate(true) if original_equipment_var is Dictionary else {}
	)
	var projected := original_equipment.duplicate(true)
	for slot in ["weapon", "armor", "chip", "pet"]:
		var spec_var: Variant = build.get(slot, {})
		if not spec_var is Dictionary:
			continue
		var spec: Dictionary = spec_var
		var item_id := str(spec.get("id", "")).strip_edges()
		if item_id == "":
			continue
		projected["selected_%s" % slot] = item_id
		projected[item_id] = maxi(1, int(spec.get("level", 1)))
	save_data["equipment"] = projected
	var power := get_power_for_level(level_id)
	save_data["equipment"] = original_equipment
	return power

# 战力 6.0：有效战力是全游戏恒定的纯构筑函数。level_id 只为兼容旧调用签名，
# 不参与任何玩家侧能力、选卡或属性计算；关卡差异只进入固定推荐值与徽章。
func get_power_for_level(level_id: String) -> int:
	var _compat_level_id := level_id
	return int(_power_v6_breakdown().get("power", 1))

func _power_v6_config() -> Dictionary:
	var value: Variant = DataLoader.get_table("economy").get("power_scale_v6", {})
	return value if value is Dictionary else {}

func _power_v6_stable_skill_levels(config: Dictionary) -> Dictionary:
	var base_var: Variant = save_data.get("skill_base_levels", {})
	var base: Dictionary = base_var if base_var is Dictionary else {}
	var owned: Dictionary = {}
	for skill_id_var in base.keys():
		var skill_id := str(skill_id_var)
		var row := DataLoader.get_row("skills", skill_id)
		if row.is_empty():
			continue
		var rank := clampi(int(base.get(skill_id_var, 0)), 0, _power_skill_max_level(row))
		if rank > 0:
			owned[skill_id] = rank
	var ordered: Array[String] = []
	for skill_id_var in config.get("stable_skill_priority", []):
		ordered.append(str(skill_id_var))
	var remaining := owned.keys()
	remaining.sort()
	for skill_id_var in remaining:
		var skill_id := str(skill_id_var)
		if not ordered.has(skill_id):
			ordered.append(skill_id)
	var result: Dictionary = {}
	var budget := maxi(int(config.get("stable_card_budget", POWER_REFERENCE_CARD_PICKS)), 1)
	for skill_id in ordered:
		if owned.has(skill_id):
			result[skill_id] = owned[skill_id]
			if result.size() >= budget:
				break
	return result

func _power_v6_runtime_chip_value(chip: Dictionary, chip_level: int, stat: String) -> float:
	if chip.is_empty():
		return 0.0
	var offset := float(maxi(chip_level - 1, 0))
	if str(chip.get("stat", "")) == stat:
		return float(chip.get("value", 0.0)) * (1.0 + float(chip.get("level_value_growth", 0.035)) * offset)
	var secondary_var: Variant = chip.get("secondary_stats", {})
	var secondary: Dictionary = secondary_var if secondary_var is Dictionary else {}
	var growth_var: Variant = chip.get("secondary_level_growth", {})
	var growth: Dictionary = growth_var if growth_var is Dictionary else {}
	return float(secondary.get(stat, 0.0)) + float(growth.get(stat, 0.0)) * offset

func _power_v6_runtime_pet_value(pet: Dictionary, pet_level: int, stat: String) -> float:
	if pet.is_empty():
		return 0.0
	var stats_var: Variant = pet.get("stat_bonus", {})
	var stats: Dictionary = stats_var if stats_var is Dictionary else {}
	var growth_var: Variant = pet.get("level_stat_growth", {})
	var growth: Dictionary = growth_var if growth_var is Dictionary else {}
	return float(stats.get(stat, 0.0)) + float(growth.get(stat, 0.0)) * float(maxi(pet_level - 1, 0))

func _power_v6_fire_rate_throughput(projected: Dictionary, profile_id: String) -> float:
	if profile_id == "control":
		return 1.0
	var economy: Dictionary = DataLoader.get_table("economy")
	var profiles_root_var: Variant = economy.get("fire_rate_profiles", {})
	var profiles_root: Dictionary = profiles_root_var if profiles_root_var is Dictionary else {}
	var profiles_var: Variant = profiles_root.get("profiles", {})
	var profiles: Dictionary = profiles_var if profiles_var is Dictionary else {}
	var profile_var: Variant = profiles.get(profile_id, profiles.get(str(profiles_root.get("default", "control")), {}))
	var profile: Dictionary = profile_var if profile_var is Dictionary else {}
	var character_id := get_selected("character")
	var weapon_id := get_selected("weapon")
	if character_id == "":
		character_id = "vanguard"
	if weapon_id == "":
		weapon_id = "weapon_autocannon"
	var character := DataLoader.get_row("characters", character_id)
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var weapon_level := get_item_level(weapon_id)
	var chip_id := get_selected("chip")
	var chip := DataLoader.get_row("chips", chip_id) if chip_id != "" else {}
	var chip_level := get_item_level(chip_id) if chip_id != "" else 1
	var pet_id := get_selected("pet")
	var pet := DataLoader.get_row("pets", pet_id) if pet_id != "" else {}
	var pet_level := get_item_level(pet_id) if pet_id != "" else 1
	var authored_base := float(weapon.get("fire_rate", 4.0))
	var weapon_growth_level := weapon_standard_growth_level_from_row(weapon, weapon_level)
	authored_base *= 1.0 + 0.025 * float(maxi(weapon_growth_level - 1, 0))
	authored_base *= float(economy.get("PLAYER_FIRE_RATE_MULT", 0.25))
	var character_mult := float(character.get("fire_rate_mod", 1.0))
	var chip_value := _power_v6_runtime_chip_value(chip, chip_level, "fire_rate_mult")
	var pet_value := _power_v6_runtime_pet_value(pet, pet_level, "fire_rate_mult")
	var salvo_level := int(projected.get("skill_salvo", 0))
	var control_salvo := 1.0
	if salvo_level > 0:
		control_salvo += float(_power_skill_effect("skill_salvo", salvo_level).get("fire_rate_mult", 0.0))
	var control_rate := authored_base * character_mult
	control_rate *= 1.0 + chip_value
	control_rate *= 1.0 + 0.01 * float(maxi(chip_level - 1, 0))
	control_rate *= 1.0 + pet_value
	control_rate *= control_salvo
	var chip_mult := (1.0 + chip_value * float(profile.get("chip_intrinsic_scale", 1.0)))
	chip_mult *= 1.0 + float(profile.get("chip_level_bonus_per_level", 0.01)) * float(maxi(chip_level - 1, 0))
	var pet_mult := 1.0 + pet_value * float(profile.get("pet_fire_rate_scale", 1.0))
	var salvo_mult := 1.0
	if salvo_level > 0:
		var values_var: Variant = profile.get("salvo_fire_rate_mult", [])
		var values: Array = values_var if values_var is Array else []
		if values.is_empty():
			salvo_mult = control_salvo
		else:
			salvo_mult = 1.0 + float(values[clampi(salvo_level - 1, 0, values.size() - 1)])
	var raw_rate := authored_base * character_mult * chip_mult * pet_mult * salvo_mult
	var cap_ratio := float(profile.get("global_weapon_base_cap", 0.0))
	var actual_rate := minf(raw_rate, maxf(authored_base, 0.01) * cap_ratio) if cap_ratio > 0.0 else raw_rate
	var compensation := 1.0
	var share := float(profile.get("removed_dps_compensation", 0.0))
	if share > 0.0 and actual_rate > 0.0 and control_rate > actual_rate:
		compensation += (control_rate / actual_rate - 1.0) * share
	return actual_rate / maxf(control_rate, 0.000001) * compensation

func _power_v6_axis_inverse(value: float, row: Dictionary) -> float:
	var gs_var: Variant = row.get("g_samples", [])
	var samples_var: Variant = row.get("samples", [])
	var gs: Array = gs_var if gs_var is Array else []
	var samples: Array = samples_var if samples_var is Array else []
	if gs.is_empty() or samples.size() != gs.size():
		return 1.0
	var safe_value := maxf(value, 0.000000000001)
	if safe_value <= float(samples[0]):
		return float(gs[0]) + log(safe_value / float(samples[0])) / maxf(float(row.get("bottom_slope", 0.000001)), 0.000001)
	var last := samples.size() - 1
	if safe_value >= float(samples[last]):
		return float(gs[last]) + log(safe_value / float(samples[last])) / maxf(float(row.get("top_slope", 0.000001)), 0.000001)
	var index := 1
	while index < samples.size() and float(samples[index]) < safe_value:
		index += 1
	var lo_g := float(gs[index - 1])
	var hi_g := float(gs[index])
	var lo_f := float(samples[index - 1])
	var hi_f := float(samples[index])
	if is_equal_approx(hi_f, lo_f):
		return lo_g
	return lo_g + (safe_value - lo_f) / (hi_f - lo_f) * (hi_g - lo_g)

func _power_v6_display(g: float, config: Dictionary) -> float:
	var gs: Array = config.get("anchor_g", [5.0, 50.0, 99.0])
	var ps: Array = config.get("anchor_power", [81.2, 1000.0, 5000.0])
	var k1 := log(float(ps[1]) / float(ps[0])) / (float(gs[1]) - float(gs[0]))
	var k2 := log(float(ps[2]) / float(ps[1])) / (float(gs[2]) - float(gs[1]))
	if g <= float(gs[1]):
		return float(ps[0]) * exp(k1 * (g - float(gs[0])))
	return float(ps[1]) * exp(k2 * (g - float(gs[1])))

func _power_v6_breakdown() -> Dictionary:
	var config := _power_v6_config()
	if config.is_empty():
		return {"power": maxi(int(round(_loadout_core_power())), 1)}
	var projected := _power_v6_stable_skill_levels(config)
	var boss_share := clampf(float(config.get("neutral_boss_share", 0.5)), 0.0, 1.0)
	var skill_axes := _power_skill_capacity_profile(projected, boss_share)
	var profile_id := str(config.get("fire_rate_profile", "tier_b"))
	var offense := _loadout_offense_multiplier(profile_id)
	var throughput := _power_v6_fire_rate_throughput(projected, profile_id)
	var weapon_id := get_selected("weapon")
	if weapon_id == "":
		weapon_id = "weapon_autocannon"
	var crowd := offense * float(skill_axes.get("crowd", 1.0)) * throughput
	crowd *= _power_weapon_axis_calibration(weapon_id, "crowd")
	var boss := offense * float(skill_axes.get("boss", 1.0)) * throughput
	boss *= _power_weapon_axis_calibration(weapon_id, "boss")
	var line_weights_var: Variant = config.get("line_clearance_weights", {})
	var line_weights: Dictionary = line_weights_var if line_weights_var is Dictionary else {}
	var clearance := pow(maxf(crowd, 1.0), float(line_weights.get("crowd", 0.10)))
	clearance *= pow(maxf(boss, 1.0), float(line_weights.get("boss", 0.05)))
	var line := _loadout_survival_multiplier() * float(skill_axes.get("line", 1.0)) * clearance
	var character_id := get_selected("character")
	if character_id == "":
		character_id = "vanguard"
	var character := DataLoader.get_row("characters", character_id)
	if str(character.get("passive", "")) == "breach_guard":
		line /= 0.82
		if _power_growth_rank(get_item_level(character_id)) >= 2:
			line /= 0.88
	var capacities := {"crowd": crowd, "boss": boss, "line": line}
	var axes_var: Variant = config.get("axes", {})
	var axes: Dictionary = axes_var if axes_var is Dictionary else {}
	var g_by_axis := {
		"crowd": _power_v6_axis_inverse(crowd, axes.get("crowd", {})),
		"boss": _power_v6_axis_inverse(boss, axes.get("boss", {})),
		"line": _power_v6_axis_inverse(line, axes.get("line", {})),
	}
	var bottleneck := "crowd"
	for axis in ["boss", "line"]:
		if float(g_by_axis.get(axis, INF)) < float(g_by_axis.get(bottleneck, INF)):
			bottleneck = axis
	var g_player := float(g_by_axis.get(bottleneck, 1.0))
	return {
		"power": maxi(int(round(_power_v6_display(g_player, config))), 1),
		"power_model": "bottleneck_v6",
		"power_capacities": capacities,
		"power_axis_g": g_by_axis,
		"power_bottleneck": bottleneck,
		"g_player": g_player,
		"projected_skill_levels": projected,
		"fire_rate_profile": profile_id,
		"fire_rate_throughput": throughput,
	}

func get_combat_power_for_skill_levels(run_skill_levels: Dictionary) -> int:
	return int(round(_loadout_core_power() * _skill_power_scale(run_skill_levels)))

# design/28 决策③:本关元素乘区——错配构筑的"预计成型"必须现形。
# 小怪按本关 primary_weakness、Boss 按 bosses.json 弱点/抗性表,伤害倍率全部从
# economy.json / bosses.json 动态读取,按敌方 HP 占比(clear_requirement 落表)
# 加权后以 0.82 攻击权重压缩进战力空间。
func get_element_power_factor_for_level(level_id: String) -> float:
	var level := DataLoader.get_row("levels", level_id)
	var requirement_var: Variant = level.get("clear_requirement", {})
	var requirement: Dictionary = requirement_var if requirement_var is Dictionary else {}
	if requirement.is_empty():
		return 1.0
	var weapon_id := get_selected("weapon")
	if weapon_id == "":
		weapon_id = "weapon_autocannon"
	var element := str(DataLoader.get_row("weapons", weapon_id).get("element", "physical"))
	var economy: Dictionary = DataLoader.get_table("economy")
	var weakness_mult := maxf(float(economy.get("weakness_mult", 1.5)), 1.0)
	var ruler_var: Variant = economy.get("power_ruler", {})
	var ruler: Dictionary = ruler_var if ruler_var is Dictionary else {}
	var weight := clampf(float(ruler.get("element_weight", 0.82)), 0.1, 1.0)
	var mob_factor := weakness_mult if element == str(level.get("primary_weakness", "physical")) else 1.0
	var boss_factor := 1.0
	var boss_id := str(requirement.get("boss_id", ""))
	if boss_id != "" and boss_id != "<null>":
		var boss := DataLoader.get_row("bosses", boss_id)
		if not boss.is_empty():
			boss_factor = _power_boss_element_factor(boss, element)
	var mob_share := clampf(float(requirement.get("mob_hp_share", 1.0)), 0.0, 1.0)
	var boss_share := clampf(float(requirement.get("boss_hp_share", 0.0)), 0.0, 1.0)
	var weighted := mob_share * mob_factor + boss_share * boss_factor
	return pow(maxf(weighted, 0.02), weight)

func get_power_breakdown_for_level(level_id: String, challenge := false) -> Dictionary:
	var recommended := get_recommended_power_for_level(level_id)
	if challenge:
		recommended = int(ceil(float(recommended) * 1.5))
	var power := get_power_for_level(level_id)
	var result := {
		"power": power,
		"recommended": recommended,
		# Compatibility aliases for existing diagnostic tools. Player-facing UI must
		# not expose these as separate power concepts.
		"standing": power,
		"projected": power,
	}
	result.merge(_power_internal_breakdown_for_level(level_id), true)
	return result

# design/28 战力口径 2.0:核心战力改为与 battle.gd 伤害管线同构的乘法结构。
# 旧公式是"等级 × 固定分"的加法,和真实战斗的乘法关系不同构,Owner 实测(24 战力
# 配置 1★通过 65 推荐关)判定两条曲线偏离过大。新结构:
#   战力 = K × (输出倍率^0.82 × 生存倍率^0.28)^γ
# 0.82/0.28 攻防权重沿用 design/24 Phase 6 已标定值;等级只通过它对真实伤害/生存
# 的影响进入战力,武器固有强度(含付费爆发机制折算)乘在等级成长上——付费武器每
# 升一级涨幅自动大于免费武器。
const POWER_SCALE_K := 11.0
const POWER_SCALE_GAMMA := 1.0
# design/29 Phase A:角色弹种亲和的战力折算。pierce/chain/status/slow 复用技能
# 侧已经标定的同名系数；像素半径与碎冰循环没有可直接复用的无量纲口径，使用
# audit_character_endgame_dps.best_result() 四角色终局 fixture 拟合（附录 B）。
const POWER_AFFINITY_PIERCE_COVERAGE := 0.065
const POWER_AFFINITY_CHAIN_COVERAGE := 0.09
const POWER_AFFINITY_STATUS_THROUGHPUT := 0.28
const POWER_AFFINITY_SLOW_SURVIVAL := 0.40
const POWER_AFFINITY_SPLASH_RADIUS := 0.0001
const POWER_AFFINITY_SHATTER_CYCLE := 6.0

func _loadout_core_power() -> float:
	var offense := _loadout_offense_multiplier()
	var survival := _loadout_survival_multiplier()
	var combined := pow(offense, 0.82) * pow(survival, 0.28)
	return maxf(POWER_SCALE_K * pow(combined, POWER_SCALE_GAMMA), 1.0)

# 输出倍率 O:免费裸装 L1(vanguard + autocannon)= 1.0 基准。
func _loadout_offense_multiplier(fire_rate_profile := "control") -> float:
	var character_id := get_selected("character")
	var weapon_id := get_selected("weapon")
	if character_id == "":
		character_id = "vanguard"
	if weapon_id == "":
		weapon_id = "weapon_autocannon"
	var character := DataLoader.get_row("characters", character_id)
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var char_level := get_item_level(character_id)
	var weapon_level := get_item_level(weapon_id)
	var char_atk := float(character.get("base_atk", 100.0)) / 100.0 * float(character.get("fire_rate_mod", 1.0))
	char_atk *= 1.0 + float(character.get("atk_growth", 0.08)) * 0.45 * float(maxi(char_level - 1, 0))
	var weapon_dps := maxf(_weapon_effective_dps(weapon) / 4.0, 0.35)
	weapon_dps *= weapon_level_damage_multiplier_from_row(weapon, weapon_level)
	var weapon_growth_level := weapon_standard_growth_level_from_row(weapon, weapon_level)
	weapon_dps *= 1.0 + 0.025 * float(maxi(weapon_growth_level - 1, 0))
	weapon_dps *= _weapon_endgame_growth_multiplier(weapon, weapon_level, fire_rate_profile)
	# 角色-武器元素亲和(bullet_affinity):真实战斗与模拟器都算这 10% 上下的加成,
	# 战力不算的话跨元素配装(如先锋+雷霆)会被系统性高估。
	var affinity := _bullet_affinity_multiplier(character, weapon, char_level)
	var gear := _offense_gear_multiplier(fire_rate_profile)
	var active := _active_skill_offense_multiplier(character, char_level, get_sig_skill_level(character_id), fire_rate_profile)
	return maxf(char_atk * weapon_dps * affinity * gear * active, 0.05)

func _bullet_affinity_multiplier(character: Dictionary, weapon: Dictionary, char_level: int) -> float:
	var affinity_var: Variant = character.get("bullet_affinity", {})
	var affinity: Dictionary = affinity_var if affinity_var is Dictionary else {}
	if affinity.is_empty():
		return 1.0
	if str(weapon.get("element", "physical")) != str(affinity.get("element", character.get("element_focus", "physical"))):
		return 1.0
	var rank := _power_growth_rank(char_level)
	var direct := 1.0 + maxf(
		float(affinity.get("damage_bonus", 0.0))
			+ float(affinity.get("rank_damage_bonus", 0.0)) * float(rank),
		0.0,
	)
	var pierce := int(affinity.get("pierce_bonus", 0))
	var chain := int(affinity.get("chain_bonus", 0))
	if rank >= 2:
		pierce += int(affinity.get("rank_pierce_bonus", 0))
		chain += int(affinity.get("rank_chain_bonus", 0))
	var chain_retention := clampf(float(affinity.get("chain_target_falloff", 1.0)), 0.72, 1.0)
	var coverage := 1.0
	coverage += float(maxi(pierce, 0)) * POWER_AFFINITY_PIERCE_COVERAGE
	coverage += float(maxi(chain, 0)) * POWER_AFFINITY_CHAIN_COVERAGE * chain_retention
	var status := 1.0 + maxf(float(affinity.get("status_bonus", 0.0)), 0.0) * POWER_AFFINITY_STATUS_THROUGHPUT
	var splash_radius := maxf(
		float(affinity.get("splash_bonus", 0.0))
			+ float(affinity.get("rank_splash_bonus", 0.0)) * float(rank),
		0.0,
	)
	var splash := 1.0 + splash_radius * POWER_AFFINITY_SPLASH_RADIUS
	# battle.gd 的冰霜碎冰在每次受控命中循环触发；0.04×成长档是运行时同式。
	var shatter_strength := 0.0
	if affinity.has("shatter_bonus"):
		shatter_strength = maxf(float(affinity.get("shatter_bonus", 0.0)) + 0.04 * float(rank), 0.0)
	var shatter := 1.0 + shatter_strength * POWER_AFFINITY_SHATTER_CYCLE
	# 连锁溢出依赖局内连锁卡。静态战力用数据内 reference 窗口 + 角色自带连锁数
	# 估算进入溢出区的期望次数，避免把任意固定链数硬编码进角色公式。
	var overflow_window := maxi(int(affinity.get("chain_overflow_reference", 0)) + maxi(chain, 0), 0)
	var overflow := 1.0 + maxf(float(affinity.get("chain_overflow_damage_bonus", 0.0)), 0.0) * float(overflow_window)
	return maxf(direct * coverage * status * splash * shatter * overflow, 1.0)

func _legacy_bullet_affinity_multiplier(character: Dictionary, weapon: Dictionary) -> float:
	var affinity_var: Variant = character.get("bullet_affinity", {})
	var affinity: Dictionary = affinity_var if affinity_var is Dictionary else {}
	if affinity.is_empty():
		return 1.0
	if str(weapon.get("element", "physical")) != str(affinity.get("element", character.get("element_focus", "physical"))):
		return 1.0
	return 1.0 + maxf(float(affinity.get("damage_bonus", 0.0)), 0.0)

func _bullet_affinity_survival_multiplier(character: Dictionary, weapon: Dictionary, char_level: int) -> float:
	var affinity_var: Variant = character.get("bullet_affinity", {})
	var affinity: Dictionary = affinity_var if affinity_var is Dictionary else {}
	if affinity.is_empty():
		return 1.0
	if str(weapon.get("element", "physical")) != str(affinity.get("element", character.get("element_focus", "physical"))):
		return 1.0
	var rank := _power_growth_rank(char_level)
	var slow := maxf(
		float(affinity.get("slow_bonus", 0.0))
			+ float(affinity.get("rank_slow_bonus", 0.0)) * float(rank),
		0.0,
	)
	return 1.0 + slow * POWER_AFFINITY_SLOW_SURVIVAL

func _power_growth_rank(level: int) -> int:
	if level >= 25:
		return 3
	if level >= 15:
		return 2
	if level >= 8:
		return 1
	return 0

# 芯片/宠物的进攻类实值加成(damage/fire_rate/element/crit/pierce/chain),
# 全部按 value + level_value_growth 实际读数折算,不再用档位常量。
func _offense_gear_multiplier(fire_rate_profile := "control") -> float:
	var mult := 1.0
	var chip_id := get_selected("chip")
	if chip_id != "":
		var chip := DataLoader.get_row("chips", chip_id)
		var chip_offset := float(maxi(get_item_level(chip_id) - 1, 0))
		var value := float(chip.get("value", 0.0)) + float(chip.get("level_value_growth", 0.0)) * chip_offset
		mult *= _offense_stat_factor(str(chip.get("stat", "")), value)
		# 终焉军械芯片把机制加成放在 secondary_stats 字典里(f0463f63 同类坑:
		# 专属字段不折算 = 付费芯片被系统性低估),按同一 stat 口径逐项折入。
		var secondary_var: Variant = chip.get("secondary_stats", {})
		var secondary: Dictionary = secondary_var if secondary_var is Dictionary else {}
		var secondary_growth_var: Variant = chip.get("secondary_level_growth", {})
		var secondary_growth: Dictionary = secondary_growth_var if secondary_growth_var is Dictionary else {}
		for stat in secondary.keys():
			var sec_value := float(secondary.get(stat, 0.0)) + float(secondary_growth.get(stat, 0.0)) * chip_offset
			mult *= _offense_stat_factor(str(stat), sec_value)
	var pet_id := get_selected("pet")
	if pet_id != "":
		var pet := DataLoader.get_row("pets", pet_id)
		var pet_level := get_item_level(pet_id)
		var base_map: Dictionary = pet.get("stat_bonus", {})
		var growth_map: Dictionary = pet.get("level_stat_growth", {})
		for stat in base_map.keys():
			var value := float(base_map.get(stat, 0.0)) + float(growth_map.get(stat, 0.0)) * float(maxi(pet_level - 1, 0))
			mult *= _offense_stat_factor(str(stat), value)
		# 输出型宠物自身炮台的直伤贡献:除以玩家当前主炮输出而非固定基准——
		# 终局审计实测宠物直伤占比可忽略(212630 里只占 9),固定基准会在满级时
		# 虚增、在低级时相对正确,除以主炮输出才是真实占比。按 damage 字段而非
		# role 白名单判定——终焉宠物的 role 是 apocalypse_* 专属值,按 role 判会漏。
		var pet_damage := float(pet.get("damage", 0.0))
		if pet_damage > 0.0:
			var pet_dps := pet_damage * (1.0 + float(pet.get("level_damage_growth", 0.0)) * float(maxi(pet_level - 1, 0))) * float(pet.get("fire_rate", 1.0))
			mult *= 1.0 + pet_dps / maxf(40.0 * _main_output_multiplier(fire_rate_profile), 1.0)
		mult *= _pet_skill_offense_multiplier(pet, pet_level)
	return mult

# 玩家当前"角色×武器"主炮输出倍率(相对 L1 裸装基准),供宠物直伤占比折算。
func _main_output_multiplier(fire_rate_profile := "control") -> float:
	var character_id := get_selected("character")
	var weapon_id := get_selected("weapon")
	if character_id == "":
		character_id = "vanguard"
	if weapon_id == "":
		weapon_id = "weapon_autocannon"
	var character := DataLoader.get_row("characters", character_id)
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var char_atk := float(character.get("base_atk", 100.0)) / 100.0 * float(character.get("fire_rate_mod", 1.0))
	char_atk *= 1.0 + float(character.get("atk_growth", 0.08)) * 0.45 * float(maxi(get_item_level(character_id) - 1, 0))
	var weapon_dps := maxf(_weapon_effective_dps(weapon) / 4.0, 0.35)
	var weapon_level := get_item_level(weapon_id)
	weapon_dps *= weapon_level_damage_multiplier_from_row(weapon, weapon_level)
	var weapon_growth_level := weapon_standard_growth_level_from_row(weapon, weapon_level)
	weapon_dps *= 1.0 + 0.025 * float(maxi(weapon_growth_level - 1, 0))
	weapon_dps *= _weapon_endgame_growth_multiplier(weapon, weapon_level, fire_rate_profile)
	return maxf(char_atk * weapon_dps, 0.05)

# 宠物技能的进攻侧期望折算(uptime/冷却期望,同旧公式的分类口径,但输出乘数而非加分)。
func _pet_skill_offense_multiplier(pet: Dictionary, pet_level: int) -> float:
	var skill: Dictionary = pet.get("pet_skill", {})
	var offset := float(maxi(pet_level - 1, 0))
	match str(skill.get("kind", "")):
		"overclock":
			var duration := float(skill.get("duration", 0.0)) + float(skill.get("level_duration_growth", 0.0)) * offset
			var cooldown := maxf(1.0, float(skill.get("cooldown", 12.0)))
			var fire_rate := float(skill.get("fire_rate_mult", 1.0)) + float(skill.get("level_fire_rate_growth", 0.0)) * offset
			var damage := float(skill.get("damage_mult", 1.0)) + float(skill.get("level_damage_mult_growth", 0.0)) * offset
			return 1.0 + maxf(fire_rate * damage - 1.0, 0.0) * clampf(duration / cooldown, 0.0, 1.0)
		"golden_mark":
			var duration := float(skill.get("mark_duration", 0.0)) + float(skill.get("level_mark_duration_growth", 0.0)) * offset
			var cooldown := maxf(1.0, float(skill.get("cooldown", 12.0)))
			var amp := float(skill.get("mark_damage_amp", 0.0)) + float(skill.get("level_mark_amp_growth", 0.0)) * offset
			return 1.0 + maxf(amp, 0.0) * clampf(duration / cooldown, 0.0, 1.0)
		"area_blast", "multi_strike":
			var cooldown := maxf(1.0, float(skill.get("cooldown", 12.0)))
			var damage := float(skill.get("damage_mult", 1.0)) + float(skill.get("level_damage_mult_growth", 0.0)) * offset
			# 独立于主炮的周期直伤,按"相当于主炮多少秒输出/冷却"折小头
			return 1.0 + clampf(damage / cooldown, 0.0, 0.5) * 0.5
		_:
			return 1.0

func _offense_stat_factor(stat: String, value: float) -> float:
	match stat:
		"damage_mult", "fire_rate_mult", "element_damage_mult":
			return 1.0 + maxf(value, 0.0)
		"crit_rate":
			# 基线暴击 8%/85% 加成,与 _combat_skill_effect_multiplier 同一折算
			return 1.0 + maxf(value, 0.0) * 0.85
		"pierce_bonus":
			return 1.0 + maxf(value, 0.0) * 0.065
		"chain_bonus":
			return 1.0 + maxf(value, 0.0) * 0.09
		"chain_retention":
			# 连锁衰减降低 → 每跳保留更多伤害,按连锁覆盖同档折算
			return 1.0 + maxf(value, 0.0) * 0.2
		"overload_efficiency":
			# 过载充能更快 → 过载爆发期望上移,保守折半计入
			return 1.0 + maxf(value, 0.0) * 0.3
		_:
			return 1.0

# 个人主动技乘区:uptime × (爆发倍率 − 1) 的期望折算,全部从 active_skill 实值
# 读取。含专属技等级成长(sig_level_*)与角色等级 0.52 主动轨(对齐 battle.gd:1883)。
func _active_skill_offense_multiplier(character: Dictionary, char_level: int, sig_level: int, fire_rate_profile := "control") -> float:
	var active: Dictionary = character.get("active_skill", {})
	if active.is_empty():
		return 1.0
	var cooldown := maxf(float(active.get("cooldown", 18.0)) * (1.0 - clampf(float(active.get("sig_level_cooldown_reduction", 0.0)) * float(sig_level), 0.0, 0.35)), 1.0)
	var duration := float(active.get("duration", 6.0)) + float(active.get("sig_level_duration_bonus", 0.0)) * float(sig_level)
	var uptime := clampf(duration / cooldown, 0.0, 1.0)
	var damage_mult := float(active.get("damage_mult", 1.0)) + float(active.get("sig_level_damage_bonus", 0.0)) * float(sig_level)
	damage_mult *= 1.0 + float(character.get("atk_growth", 0.08)) * 0.52 * float(maxi(char_level - 1, 0))
	var barrage_rate := float(active.get("barrage_fire_rate_mult", 1.0))
	if fire_rate_profile != "control":
		var economy: Dictionary = DataLoader.get_table("economy")
		var profiles_var: Variant = economy.get("fire_rate_profiles", {})
		var profiles: Dictionary = profiles_var if profiles_var is Dictionary else {}
		var rows_var: Variant = profiles.get("profiles", {})
		var rows: Dictionary = rows_var if rows_var is Dictionary else {}
		var profile_var: Variant = rows.get(fire_rate_profile, {})
		var profile: Dictionary = profile_var if profile_var is Dictionary else {}
		var scale := float(profile.get("barrage_level_growth_scale", 1.0))
		barrage_rate = float(profile.get("barrage_fire_rate_mult", barrage_rate))
		barrage_rate += float(profile.get("barrage_rank_bonus", active.get("rank_fire_rate_bonus", 0.0))) * float(_power_growth_rank(char_level))
		barrage_rate += float(active.get("level_fire_rate_growth", 0.0)) * float(maxi(char_level - 1, 0)) * scale
		barrage_rate += float(active.get("sig_level_fire_rate_bonus", 0.0)) * float(sig_level) * scale
		barrage_rate = maxf(barrage_rate, 1.0)
	var burst := damage_mult * barrage_rate
	return 1.0 + uptime * maxf(burst - 1.0, 0.0)

# 生存倍率 S:无护甲/芯片/宠物 = 1.0 基准。护盾/反击按期望折算。
func _loadout_survival_multiplier() -> float:
	var character_id := get_selected("character")
	var weapon_id := get_selected("weapon")
	if character_id == "":
		character_id = "vanguard"
	if weapon_id == "":
		weapon_id = "weapon_autocannon"
	var character := DataLoader.get_row("characters", character_id)
	var weapon := DataLoader.get_row("weapons", weapon_id)
	var char_level := get_item_level(character_id)
	# 与 battle.gd _apply_base_survivability 同式：角色 HP 成长也使用 0.45 阻尼。
	var mult := maxf(float(character.get("base_hp", 100.0)) / 100.0, 0.5)
	mult *= 1.0 + float(character.get("hp_growth", 0.06)) * 0.45 * float(maxi(char_level - 1, 0))
	mult *= _bullet_affinity_survival_multiplier(character, weapon, char_level)
	var armor_id := get_selected("armor")
	if armor_id != "":
		var armor := DataLoader.get_row("armors", armor_id)
		var armor_level := get_item_level(armor_id)
		mult *= maxf(float(armor.get("hp_mult", 1.0)), 0.5)
		mult *= 1.0 + float(armor.get("level_hp_growth", 0.0)) * float(maxi(armor_level - 1, 0))
		mult *= 1.0 + 0.10 * float(armor.get("breach_shield", 0))
		if float(armor.get("counter_damage_mult", 0.0)) > 0.0:
			mult *= 1.10
	var chip_id := get_selected("chip")
	if chip_id != "":
		var chip := DataLoader.get_row("chips", chip_id)
		var value := float(chip.get("value", 0.0)) + float(chip.get("level_value_growth", 0.0)) * float(maxi(get_item_level(chip_id) - 1, 0))
		mult *= _survival_stat_factor(str(chip.get("stat", "")), value)
	var pet_id := get_selected("pet")
	if pet_id != "":
		var pet := DataLoader.get_row("pets", pet_id)
		var pet_level := get_item_level(pet_id)
		var base_map: Dictionary = pet.get("stat_bonus", {})
		var growth_map: Dictionary = pet.get("level_stat_growth", {})
		for stat in base_map.keys():
			var value := float(base_map.get(stat, 0.0)) + float(growth_map.get(stat, 0.0)) * float(maxi(pet_level - 1, 0))
			mult *= _survival_stat_factor(str(stat), value)
		mult *= _pet_repair_survival_multiplier(pet, pet_level)
	return maxf(mult, 0.5)

# 维修型宠物:治疗量按"等效额外基地HP占比"折算(旧公式同一分类口径,输出乘数)。
func _pet_repair_survival_multiplier(pet: Dictionary, pet_level: int) -> float:
	var offset := float(maxi(pet_level - 1, 0))
	var mult := 1.0
	if str(pet.get("role", "")) == "repair":
		var wave_ratio := float(pet.get("heal_per_wave_ratio", 0.0)) + float(pet.get("level_wave_heal_ratio_growth", 0.0)) * offset
		var repair_ratio := float(pet.get("repair_ratio", 0.0)) + float(pet.get("level_repair_ratio_growth", 0.0)) * offset
		var emergency := float(pet.get("emergency_heal_ratio", 0.0)) + float(pet.get("level_emergency_heal_growth", 0.0)) * offset
		var interval := maxf(1.0, float(pet.get("repair_interval", 18.0)))
		# 一关约5波/2-3分钟:波次治疗×4 + 周期维修每分钟量 + 应急一次
		mult *= 1.0 + clampf(wave_ratio * 4.0 + repair_ratio * (60.0 / interval) + emergency, 0.0, 1.5)
	var skill: Dictionary = pet.get("pet_skill", {})
	if str(skill.get("kind", "")) == "golden_mark":
		var repair := float(skill.get("repair_ratio", 0.0)) + float(skill.get("level_repair_growth", 0.0)) * offset
		var cooldown := maxf(1.0, float(skill.get("cooldown", 12.0)))
		mult *= 1.0 + clampf(repair * (60.0 / cooldown), 0.0, 0.75)
	return mult

func _survival_stat_factor(stat: String, value: float) -> float:
	match stat:
		"base_hp_mult":
			return 1.0 + maxf(value, 0.0)
		"breach_damage_reduction":
			return 1.0 / maxf(1.0 - clampf(value, 0.0, 0.65), 0.35)
		"slow_strength_mult":
			return 1.0 + maxf(value, 0.0) * 0.20
		_:
			return 1.0

func _projected_run_skill_levels(card_picks: int, weakness: String) -> Dictionary:
	var weapon_id := get_selected("weapon")
	if weapon_id == "":
		weapon_id = "weapon_autocannon"
	return _projected_run_skill_levels_for_profile(
		card_picks,
		weakness,
		weapon_id,
		save_data.get("skill_base_levels", {}),
	)

# One projection engine serves both sides of the ruler. Player power supplies the
# equipped weapon and saved permanent levels; the fixed level recommendation
# supplies autocannon plus an empty permanent-level profile. Keeping those inputs
# explicit prevents the recommendation from ever reading or following the save.
func _projected_run_skill_levels_for_profile(
	card_picks: int,
	weakness: String,
	weapon_id: String,
	base_skill_levels: Dictionary,
	guaranteed_skill_ids: Array = [],
	boss_share := 0.0,
	offer_category_floor := "",
) -> Dictionary:
	var projected: Dictionary = {}
	var skills_table: Dictionary = DataLoader.get_table("skills")
	if skills_table.is_empty():
		return projected
	_seed_projected_weapon_element(projected, skills_table, weapon_id, base_skill_levels)
	var consumed_picks := 0
	var guaranteed_id := _power_conservative_guaranteed_skill(
		guaranteed_skill_ids,
		base_skill_levels,
		skills_table,
		boss_share,
	)
	if guaranteed_id != "" and not projected.has(guaranteed_id):
		var guaranteed_row: Dictionary = skills_table.get(guaranteed_id, {})
		projected[guaranteed_id] = clampi(
			maxi(int(base_skill_levels.get(guaranteed_id, 0)), 1),
			1,
			_power_skill_max_level(guaranteed_row),
		)
		consumed_picks = 1
	# 物理武器面对非物理弱点时，先消耗一个真实卡位拿对应弹种；否则后续卡
	# 对本关不构成“兼容”投影。等级仍使用玩家当前永久技能等级。
	var weapon_element := str(DataLoader.get_row("weapons", weapon_id).get("element", "physical"))
	if (weapon_element == "" or weapon_element == "physical") and weakness != "" and weakness != "physical":
		var element_ids := skills_table.keys()
		element_ids.sort()
		for id_var in element_ids:
			var element_skill_id := str(id_var)
			var element_row: Dictionary = skills_table.get(element_skill_id, {})
			if str(element_row.get("exclusive_group", "")) != "projectile_element":
				continue
			if str(element_row.get("ammo_element", "")) != weakness:
				continue
			if not projected.has(element_skill_id) and consumed_picks < card_picks:
				projected[element_skill_id] = clampi(
					maxi(int(base_skill_levels.get(element_skill_id, 0)), 1),
					1,
					_power_skill_max_level(element_row),
				)
				consumed_picks += 1
			break
	# design/32:保底卡按实计；其余卡位按当前永久等级选择最弱的正收益兼容卡。
	# 这是保守期望，不假设最优选卡、组合或协同。
	for _pick in range(maxi(card_picks - consumed_picks, 0)):
		var current_score := _power_projection_score(projected)
		var candidates: Array[Dictionary] = []
		var ids := skills_table.keys()
		ids.sort()
		for id_var in ids:
			var skill_id := str(id_var)
			var row: Dictionary = skills_table.get(skill_id, {})
			if not _power_skill_compatible_with_weapon(row, weapon_id, weakness):
				continue
			var candidate := _power_candidate_skill_levels(
				projected,
				skill_id,
				row,
				skills_table,
				base_skill_levels,
			)
			if candidate.is_empty():
				continue
			var candidate_score := _power_projection_score(candidate)
			if candidate_score <= current_score + 0.000001:
				continue
			var selection_score := candidate_score
			if str(row.get("ammo_element", "")) == weakness:
				selection_score += 0.015
			candidates.append({
				"score": selection_score,
				"skill_id": skill_id,
				"levels": candidate,
				"in_floor": _power_skill_in_offer_category(row, str(offer_category_floor)),
			})
		var floor_candidates: Array[Dictionary] = []
		if str(offer_category_floor) != "":
			for item in candidates:
				if bool(item.get("in_floor", false)):
					floor_candidates.append(item)
		var selection_pool := floor_candidates if not floor_candidates.is_empty() else candidates
		if selection_pool.is_empty():
			break
		selection_pool.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var a_score := float(a.get("score", INF))
			var b_score := float(b.get("score", INF))
			if not is_equal_approx(a_score, b_score):
				return a_score < b_score
			return str(a.get("skill_id", "")) < str(b.get("skill_id", ""))
		)
		projected = selection_pool[0].get("levels", {})
	return projected


func _power_skill_in_offer_category(row: Dictionary, category: String) -> bool:
	if category == "":
		return false
	var economy: Dictionary = DataLoader.get_table("economy")
	var policy_var: Variant = economy.get("probe_card_policy", {})
	var policy: Dictionary = policy_var if policy_var is Dictionary else {}
	var category_tags_var: Variant = policy.get("category_tags", {})
	var category_tags: Dictionary = category_tags_var if category_tags_var is Dictionary else {}
	var exclusions_var: Variant = policy.get("category_exclusions", {})
	var exclusions: Dictionary = exclusions_var if exclusions_var is Dictionary else {}
	var tags: Array = row.get("card_tags", [])
	for exclusion_var in exclusions.get(category, []):
		if tags.has(str(exclusion_var)):
			return false
	for tag_var in category_tags.get(category, []):
		if tags.has(str(tag_var)):
			return true
	return false

func _power_projection_score(levels: Dictionary) -> float:
	var axes := _power_skill_capacity_profile(levels)
	return log(maxf(float(axes.get("crowd", 1.0)), 1.0)) * 0.55 \
		+ log(maxf(float(axes.get("boss", 1.0)), 1.0)) * 0.25 \
		+ log(maxf(float(axes.get("line", 1.0)), 1.0)) * 0.20

func _power_conservative_guaranteed_skill(
	skill_ids: Array,
	base_skill_levels: Dictionary,
	skills_table: Dictionary,
	boss_share := 0.0,
) -> String:
	var best_id := ""
	var best_line := INF
	for skill_id_var in skill_ids:
		var skill_id := str(skill_id_var)
		var row: Dictionary = skills_table.get(skill_id, {})
		if row.is_empty():
			continue
		var level := clampi(maxi(int(base_skill_levels.get(skill_id, 0)), 1), 1, _power_skill_max_level(row))
		var line := float(_power_skill_capacity_profile({skill_id: level}, boss_share).get("line", 1.0))
		if line < best_line or (is_equal_approx(line, best_line) and (best_id == "" or skill_id < best_id)):
			best_line = line
			best_id = skill_id
	return best_id

func _seed_projected_weapon_element(
	projected: Dictionary,
	skills_table: Dictionary,
	weapon_id: String,
	base_skill_levels: Dictionary,
) -> void:
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
		projected[skill_id] = clampi(
			maxi(int(base_skill_levels.get(skill_id, 0)), 1),
			1,
			_power_skill_max_level(row),
		)
		return

func _power_candidate_skill_levels(
	current: Dictionary,
	skill_id: String,
	row: Dictionary,
	skills_table: Dictionary,
	base_skill_levels: Dictionary,
) -> Dictionary:
	var max_level := _power_skill_max_level(row)
	var current_level := int(current.get(skill_id, 0))
	if current_level >= max_level:
		return {}
	var next_level := mini(max_level, current_level + 1)
	if current_level <= 0:
		next_level = clampi(maxi(int(base_skill_levels.get(skill_id, 0)), 1), 1, max_level)
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

func _power_skill_compatible_with_weapon(row: Dictionary, weapon_id: String, weakness: String) -> bool:
	if str(row.get("exclusive_group", "")) != "projectile_element":
		return true
	var weapon_element := str(DataLoader.get_row("weapons", weapon_id).get("element", "physical"))
	var ammo_element := str(row.get("ammo_element", ""))
	if weapon_element != "" and weapon_element != "physical":
		return ammo_element == weapon_element
	return ammo_element == weakness

func _skill_power_scale(run_skill_levels: Dictionary) -> float:
	return pow(_combat_skill_effect_multiplier(run_skill_levels), POWER_SKILL_SCORE_EXPONENT)

func _power_skill_capacity_profile(run_skill_levels: Dictionary, boss_share := 0.0) -> Dictionary:
	var damage_add := 0.0
	var fire_rate_add := 0.0
	var crit_add := 0.0
	var crit_damage_add := 0.0
	var extra_projectiles := 0
	var multishot_lane_damage_bonus := 0.0
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
		multishot_lane_damage_bonus = maxf(multishot_lane_damage_bonus, float(effect.get("lane_damage_bonus", 0.0)))
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
	var lane_total := float(lane_count) * _power_multishot_lane_damage(lane_count, multishot_lane_damage_bonus)
	var lane_factor := 1.0 + maxf(0.0, lane_total - 1.0) * 0.55
	# design/24 Phase 6: pierce is the campaign's evergreen king; trim its
	# secondary-coverage credit a notch so a pierce stack no longer dominates
	# the power score outright.
	var secondary_gain := float(pierce) * 0.065
	secondary_gain += float(split) * clampf(split_falloff, 0.0, 1.0) * 0.11
	secondary_gain += float(chain) * 0.09
	secondary_gain += homing * 0.03
	var coverage_factor := 1.0 + minf(1.75, secondary_gain)
	var status_factor := 1.0 + burn * 0.28 + poison * 0.32
	var penetration_factor := 1.0 + clampf(armor_penetration, 0.0, 0.95) * 0.22
	var common := direct_factor * cadence_factor * crit_factor * status_factor * penetration_factor
	var crowd := common * lane_factor * coverage_factor
	var boss_lane := 1.0 + maxf(0.0, lane_total - 1.0) * 0.10
	var boss_coverage := 1.0 + minf(0.35, float(pierce) * 0.025 + homing * 0.01)
	var boss := common * boss_lane * boss_coverage
	var economy: Dictionary = DataLoader.get_table("economy")
	var pacing_var: Variant = economy.get("boss_pacing", {})
	var pacing: Dictionary = pacing_var if pacing_var is Dictionary else {}
	var mob_slow_cap := clampf(float(pacing.get("mob_slow_cap", 0.80)), 0.0, 0.95)
	var boss_slow_cap := clampf(float(pacing.get("boss_slow_cap", 0.40)), 0.0, 0.95)
	var boss_weight := clampf(float(boss_share), 0.0, 1.0)
	var effective_slow := (1.0 - boss_weight) * minf(maxf(slow, 0.0), mob_slow_cap)
	effective_slow += boss_weight * minf(maxf(slow, 0.0), boss_slow_cap)
	var line := (1.0 + maxf(barrier_hp, 0.0)) / (1.0 - effective_slow)
	return {
		"crowd": maxf(crowd, 1.0),
		"boss": maxf(boss, 1.0),
		"line": maxf(line, 1.0),
	}

func _combat_skill_effect_multiplier(run_skill_levels: Dictionary) -> float:
	# Compatibility scalar for old diagnostics. The player-facing v3 ruler never
	# averages these dimensions; it takes the minimum ratio in get_power_for_level.
	var profile := _power_skill_capacity_profile(run_skill_levels)
	var offense := float(profile.get("crowd", 1.0))
	var survival := float(profile.get("line", 1.0))
	var combined := 1.0 + maxf(0.0, offense - 1.0) * 0.82 + maxf(0.0, survival - 1.0) * 0.28
	return clampf(combined, 1.0, POWER_SKILL_THROUGHPUT_CAP)

func _power_multishot_lane_damage(lane_count: int, lane_damage_bonus := 0.0) -> float:
	var base_multiplier := 1.0
	match clampi(lane_count, 1, 5):
		1:
			base_multiplier = 1.0
		2:
			base_multiplier = 0.85
		3:
			base_multiplier = 0.80
		4:
			base_multiplier = 0.75
		_:
			base_multiplier = 0.70
	return clampf(base_multiplier + float(lane_damage_bonus), 0.0, 1.0)

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
	# design/26: 终焉军械四套（雷霆/炼狱/绝对零度/黄金法则）用的是各自专属的字段名，
	# 此前完全没被下面识别，导致四把武器的真实战力被系统性低估——雷霆/黄金法则只是
	# 巧合命中了 chain/pierce 才蹭到部分加成，炼狱的 burn_ratio 和 burn 字段名不一致
	# 直接漏判，绝对零度/黄金法则各自的爆发机制则完全没有对应字段。
	# burn_ratio 是 burn 的专属命名，直接并入既有的 burn/poison 加成路径。
	effective *= 1.0 + 0.65 * (float(special.get("burn", 0.0)) + float(special.get("burn_ratio", 0.0)) + float(special.get("poison", 0.0)))
	# 过载/焚烧连爆/破裂霜爆/审判连击都是"每 N 次确认命中触发一次 M 倍爆发"的同一种
	# 形态，用周期爆发的期望值折算成等效持续倍率：1 + (M-1)/N。这不是逐机制精确复刻
	# 战斗代码，是和现有 chain/pierce 系数同一档的估算，量级已经用
	# audit_*_premium_dps.py 的满配实测倍率（1.52x-2.05x）校对过不会离谱，
	# 但不追求逐位对齐——那些审计含护甲/芯片/宠物整套，这里只估武器自身。
	var overload_hits := float(special.get("overload_hits", 0.0))
	var overload_mult := float(special.get("overload_damage_mult", 1.0))
	if overload_hits > 0.0 and overload_mult > 1.0:
		effective *= 1.0 + (overload_mult - 1.0) / overload_hits
	var combustion_stacks := float(special.get("combustion_max_stacks", 0.0))
	var combustion_mult := float(special.get("combustion_damage_mult", 1.0))
	if combustion_stacks > 0.0 and combustion_mult > 1.0:
		effective *= 1.0 + (combustion_mult - 1.0) / combustion_stacks
		effective *= 1.28
	var brittle_hits := float(special.get("brittle_hits", 0.0))
	var shatter_mult := float(special.get("shatter_damage_mult", 0.0))
	if brittle_hits > 0.0 and shatter_mult > 0.0:
		effective *= 1.0 + shatter_mult / brittle_hits
		effective *= 1.28
	var judgment_hits := float(special.get("judgment_hits", 0.0))
	var judgment_mult := float(special.get("judgment_damage_mult", 1.0))
	if judgment_hits > 0.0 and judgment_mult > 1.0:
		effective *= 1.0 + (judgment_mult - 1.0) / judgment_hits
	effective *= 1.0 + 0.22 * float(special.get("judgment_armor_penetration", 0.0))
	effective *= 1.0 + 0.30 * float(special.get("slow", 0.0))
	return effective

func _power_effective_element(weapon_id: String, projected_levels: Dictionary) -> String:
	var element := str(DataLoader.get_row("weapons", weapon_id).get("element", "physical"))
	for skill_id_var in projected_levels.keys():
		if int(projected_levels.get(skill_id_var, 0)) <= 0:
			continue
		var row := DataLoader.get_row("skills", str(skill_id_var))
		if str(row.get("exclusive_group", "")) == "projectile_element":
			return str(row.get("ammo_element", element))
	return element

func _power_boss_element_factor(boss: Dictionary, element: String) -> float:
	var economy: Dictionary = DataLoader.get_table("economy")
	var weakness_mult := maxf(float(economy.get("weakness_mult", 1.5)), 1.0)
	if str(boss.get("weakness", "")) == element:
		return weakness_mult
	var resistances_var: Variant = boss.get("resistances", {})
	var resistances: Dictionary = resistances_var if resistances_var is Dictionary else {}
	if resistances.has(element):
		var ruler_var: Variant = economy.get("power_ruler", {})
		var ruler: Dictionary = ruler_var if ruler_var is Dictionary else {}
		var params_var: Variant = boss.get("mechanic_params", {})
		var params: Dictionary = params_var if params_var is Dictionary else {}
		if str(boss.get("mechanic", "")) == "armor_break" and bool(params.get("resistance_until_armor_break", false)):
			return clampf(float(ruler.get("armor_break_effective_factor", 0.94)), 0.01, 1.0)
		return 1.0 - clampf(float(resistances.get(element, 0.0)), 0.0, 0.95)
	# A stale Boss row using the retired immune list is still treated as bounded
	# resistance in projections, matching the runtime compatibility path.
	var legacy_immune: Array = boss.get("immune", [])
	if legacy_immune.has(element):
		return clampf(float(economy.get("resist_mult", 0.5)), 0.05, 1.0)
	return 1.0

func _power_weighted_boss_element_factor(contract: Dictionary, element: String) -> float:
	var weights_var: Variant = contract.get("boss_weights", {})
	var weights: Dictionary = weights_var if weights_var is Dictionary else {}
	if weights.is_empty():
		return 1.0
	var result := 0.0
	for boss_id_var in weights.keys():
		var boss_id := str(boss_id_var)
		result += float(weights.get(boss_id_var, 0.0)) * _power_boss_element_factor(
			DataLoader.get_row("bosses", boss_id), element)
	return maxf(result, 0.01)

func _power_line_mitigation_capacity(level: Dictionary) -> float:
	var result := 1.0
	var armor_id := get_selected("armor")
	if armor_id != "":
		var armor := DataLoader.get_row("armors", armor_id)
		if str(armor.get("resist", "none")) == str(level.get("primary_weakness", "physical")):
			result /= 0.88
	var character_id := get_selected("character")
	if character_id == "":
		character_id = "vanguard"
	var character := DataLoader.get_row("characters", character_id)
	if str(character.get("passive", "")) == "breach_guard":
		result /= 0.82
		if _power_growth_rank(get_item_level(character_id)) >= 2:
			result /= 0.88
	return result

func _power_line_exposure_credit(crowd_ratio: float, boss_ratio: float, contract: Dictionary) -> float:
	# v4: the generated line requirement already represents a normal on-pace
	# fight. Clearing faster earns only a bounded contact-time credit; clearing
	# slower receives the symmetric penalty. The HP-share weights are generated
	# offline with the rest of the immutable level contract.
	var weights_var: Variant = contract.get("line_exposure_weights", {})
	var weights: Dictionary = weights_var if weights_var is Dictionary else {}
	var crowd_weight := clampf(float(weights.get("crowd", 1.0)), 0.0, 1.0)
	var boss_weight := clampf(float(weights.get("boss", 0.0)), 0.0, 1.0)
	var total := crowd_weight + boss_weight
	if total <= 0.0:
		crowd_weight = 1.0
		boss_weight = 0.0
		total = 1.0
	crowd_weight /= total
	boss_weight /= total
	var pressure := crowd_weight / maxf(crowd_ratio, 0.35)
	pressure += boss_weight / maxf(boss_ratio, 0.35)
	var economy: Dictionary = DataLoader.get_table("economy")
	var ruler_var: Variant = economy.get("power_ruler", {})
	var ruler: Dictionary = ruler_var if ruler_var is Dictionary else {}
	var lower := clampf(float(ruler.get("line_exposure_credit_min", 0.85)), 0.5, 1.0)
	var upper := maxf(float(ruler.get("line_exposure_credit_max", 1.15)), 1.0)
	return clampf(pow(maxf(pressure, 0.000001), -0.5), lower, upper)

func _power_contract_boss_share(contract: Dictionary) -> float:
	var weights_var: Variant = contract.get("line_exposure_weights", {})
	var weights: Dictionary = weights_var if weights_var is Dictionary else {}
	var crowd_weight := maxf(float(weights.get("crowd", 1.0)), 0.0)
	var boss_weight := maxf(float(weights.get("boss", 0.0)), 0.0)
	return boss_weight / maxf(crowd_weight + boss_weight, 0.000001)

func _power_weapon_axis_calibration(weapon_id: String, axis: String) -> float:
	var economy: Dictionary = DataLoader.get_table("economy")
	var ruler_var: Variant = economy.get("power_ruler", {})
	var ruler: Dictionary = ruler_var if ruler_var is Dictionary else {}
	var profiles_var: Variant = ruler.get("weapon_runtime_axis_calibration", {})
	var profiles: Dictionary = profiles_var if profiles_var is Dictionary else {}
	var row_var: Variant = profiles.get(weapon_id, {})
	var row: Dictionary = row_var if row_var is Dictionary else {}
	return maxf(float(row.get(axis, 1.0)), 0.01)

func _power_internal_breakdown_for_level(level_id: String) -> Dictionary:
	var result := _power_v6_breakdown()
	var level := DataLoader.get_row("levels", level_id)
	var requirement_var: Variant = level.get("clear_requirement", {})
	var requirement: Dictionary = requirement_var if requirement_var is Dictionary else {}
	var contract_var: Variant = requirement.get("power_contract", {})
	var contract: Dictionary = contract_var if contract_var is Dictionary else {}
	if contract.is_empty():
		return result
	var capacities_var: Variant = result.get("power_capacities", {})
	var capacities: Dictionary = capacities_var if capacities_var is Dictionary else {}
	var ratios := {
		"crowd": float(capacities.get("crowd", 0.0)) / maxf(float(contract.get("crowd_capacity", 1.0)), 0.000000000001),
		"boss": float(capacities.get("boss", 0.0)) / maxf(float(contract.get("boss_capacity", 1.0)), 0.000000000001),
		"line": float(capacities.get("line", 0.0)) / maxf(float(contract.get("line_capacity", 1.0)), 0.000000000001),
	}
	var bottleneck := "crowd"
	if float(ratios.get("boss", 99.0)) < float(ratios.get(bottleneck, 99.0)):
		bottleneck = "boss"
	if float(ratios.get("line", 99.0)) < float(ratios.get(bottleneck, 99.0)):
		bottleneck = "line"
	result["power_model"] = str(contract.get("model", ""))
	result["power_ratios"] = ratios
	result["power_bottleneck"] = bottleneck
	result["matchup_factor"] = get_element_power_factor_for_level(level_id)
	return result

# 单一战力 v5：推荐战力仍是本关固定的“有压力、通常能过”门槛，不得随存档变化。
# Python 离线模型把运行时追加 Boss、阶段减伤与重复攻线压力写入 power_contract；
# 生成表把每把武器的真实碰撞清群/Boss产能写入 economy；GDScript 只读合同和
# 校准表，杜绝客户端和校验工具再各算一套关卡难度。
# required_t(min_output)由 tools/generate_clear_requirements.py 基于难度模型离线解出、
# 落表在 levels.json 的 clear_requirement 字段(check_clear_requirements.py 在 RC 中防
# 不同步);这里只做查表 + 与玩家同一把尺的映射:
#   推荐战力 = K × ((required_t × O_L1裸装)^0.82 × S_ref^0.28)^γ × 标准选卡缩放
# S_ref = economy.power_ruler.survival_reference(与模型求解假设的典型护甲一致)。
# 玩家唯一“战力”与这条固定门槛直接比较，余量大小由星级去表达。
func get_recommended_power_for_level(level_id: String) -> int:
	var level := DataLoader.get_row("levels", level_id)
	var requirement_var: Variant = level.get("clear_requirement", {})
	var requirement: Dictionary = requirement_var if requirement_var is Dictionary else {}
	var contract_var: Variant = requirement.get("power_contract", {})
	var contract: Dictionary = contract_var if contract_var is Dictionary else {}
	if not contract.is_empty():
		return maxi(int(contract.get("recommended_power", 1)), 1)
	var required_t := maxf(float(requirement.get("min_output", 1.0)), 0.05)
	var economy: Dictionary = DataLoader.get_table("economy")
	var ruler_var: Variant = economy.get("power_ruler", {})
	var ruler: Dictionary = ruler_var if ruler_var is Dictionary else {}
	var survival_ref := maxf(float(ruler.get("survival_reference", 1.2)), 0.5)
	var reference_level := clampi(int(level.get("recommend_level", 1)), 1, 40)
	var reference_character := DataLoader.get_row("characters", "vanguard")
	var reference_weapon := DataLoader.get_row("weapons", "weapon_autocannon")
	# design/29 同源抵消：新增角色身份项在玩家侧与按节奏参考侧使用同一估计器。
	# required_t 仍是独立难度模拟器的旧归一语义；这里只把固定参考构筑
	# vanguard + autocannon @ recommend_level 相对 L1 的亲和/HP 乘子接到门槛侧。
	var reference_affinity_delta := _bullet_affinity_multiplier(reference_character, reference_weapon, reference_level)
	reference_affinity_delta /= maxf(_legacy_bullet_affinity_multiplier(reference_character, reference_weapon), 0.01)
	var reference_character_survival := maxf(float(reference_character.get("base_hp", 100.0)) / 100.0, 0.5)
	reference_character_survival *= 1.0 + float(reference_character.get("hp_growth", 0.06)) * 0.45 * float(maxi(reference_level - 1, 0))
	reference_character_survival *= _bullet_affinity_survival_multiplier(reference_character, reference_weapon, reference_level)
	survival_ref *= reference_character_survival
	var o_ref := required_t * _offense_baseline_l1() * reference_affinity_delta
	var combined := pow(o_ref, 0.82) * pow(survival_ref, 0.28)
	var card_picks := maxi(1, int(level.get("target_card_picks", POWER_REFERENCE_CARD_PICKS)))
	var weakness := str(level.get("primary_weakness", "physical"))
	# Use the exact same projection/effect pipeline as player power, but with a
	# frozen free reference profile. The recommendation therefore remains a level
	# constant while both sides value every card through one calculator.
	var reference_levels := _projected_run_skill_levels_for_profile(
		card_picks,
		weakness,
		"weapon_autocannon",
		{},
	)
	var card_scale := _skill_power_scale(reference_levels)
	return maxi(int(round(POWER_SCALE_K * pow(combined, POWER_SCALE_GAMMA) * card_scale)), 1)

# 免费裸装 L1(vanguard + autocannon,零专属技)的输出倍率——required_t 的归一基准,
# 全部从数据实值算出,与 tools/power_ruler_model.py 的 offense_baseline_l1 镜像一致。
func _offense_baseline_l1() -> float:
	var character := DataLoader.get_row("characters", "vanguard")
	var weapon := DataLoader.get_row("weapons", "weapon_autocannon")
	var char_atk := float(character.get("base_atk", 100.0)) / 100.0 * float(character.get("fire_rate_mod", 1.0))
	var weapon_dps := maxf(_weapon_effective_dps(weapon) / 4.0, 0.35)
	var affinity := _bullet_affinity_multiplier(character, weapon, 1)
	return maxf(char_atk * weapon_dps * affinity * _active_skill_offense_multiplier(character, 1, 0), 0.05)

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

func get_item_upgrade_cost_spec(table: String, item_id: String) -> Dictionary:
	return {"kind": "gold", "amount": get_item_upgrade_cost(table, item_id)}

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

func get_unlock_cost_spec(table: String, item_id: String) -> Dictionary:
	return {"kind": "star", "amount": get_unlock_price_star(table, item_id)}

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

func get_skill_base_upgrade_cost_spec(skill_id: String) -> Dictionary:
	return {"kind": "xp", "amount": get_skill_base_upgrade_cost(skill_id)}

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

func get_sig_skill_upgrade_cost_spec(character_id: String) -> Dictionary:
	return {"kind": "xp", "amount": get_sig_skill_upgrade_cost(character_id)}

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
