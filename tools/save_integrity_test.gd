extends SceneTree

const TEST_DIR := "user://save_integrity_test"

var failures: Array[String] = []
var save_manager

func _initialize() -> void:
	await process_frame
	save_manager = root.get_node("/root/SaveManager")
	var original_save_path: String = save_manager._save_path
	var original_backup_path: String = save_manager._backup_path
	var original_save_data: Dictionary = save_manager.save_data.duplicate(true)
	var original_error: String = save_manager._last_persistence_error
	var original_suppression: bool = save_manager._suppress_expected_persistence_errors_for_tests

	_remove_tree(TEST_DIR)
	var mkdir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_DIR))
	_expect(mkdir_error == OK, "test directory must be created")
	save_manager._save_path = "%s/save_main.json" % TEST_DIR
	save_manager._backup_path = "%s/save_backup.json" % TEST_DIR

	_test_normal_save_and_rotation()
	_test_corrupt_main_fallback()
	_test_migration_and_recursive_defaults()
	_test_manual_backup_restore()
	_test_missing_main_fallback()
	_test_application_pause_persistence()
	_test_write_failure_preserves_good_files()

	save_manager._save_path = original_save_path
	save_manager._backup_path = original_backup_path
	save_manager.save_data = original_save_data
	save_manager._last_persistence_error = original_error
	save_manager._suppress_expected_persistence_errors_for_tests = original_suppression
	_remove_tree(TEST_DIR)

	if failures.is_empty():
		print("SAVE INTEGRITY TEST PASSED")
		quit(0)
		return
	for failure in failures:
		push_error("SAVE INTEGRITY TEST: %s" % failure)
	quit(1)

func _test_normal_save_and_rotation() -> void:
	var first_save: Dictionary = save_manager._default_save()
	first_save["player"]["gold"] = 111
	save_manager.save_data = first_save
	save_manager.save_game()
	_expect(FileAccess.file_exists(save_manager._save_path), "normal save must create the main file")
	_expect(not FileAccess.file_exists(save_manager._backup_path), "first save must not invent a backup without a prior main file")
	_expect(_gold_at(save_manager._save_path) == 111, "main file must contain the first committed save")

	var second_save: Dictionary = first_save.duplicate(true)
	second_save["player"]["gold"] = 222
	save_manager.save_data = second_save
	save_manager.save_game()
	_expect(_gold_at(save_manager._save_path) == 222, "second save must atomically replace the main file")
	_expect(_gold_at(save_manager._backup_path) == 111, "backup rotation must retain the previously verified main file")

func _test_corrupt_main_fallback() -> void:
	const CORRUPT_CONTENT := "{broken-main-save"
	save_manager._suppress_expected_persistence_errors_for_tests = true
	_write_text(save_manager._save_path, CORRUPT_CONTENT)
	save_manager.load_game()
	_expect(int(save_manager.save_data.get("player", {}).get("gold", -1)) == 111, "corrupt main must recover the verified backup")
	_expect(_gold_at(save_manager._save_path) == 111, "backup recovery must rebuild a valid main file")

	var corrupt_copy := _find_corrupt_copy()
	_expect(corrupt_copy != "", "corrupt main must be retained beside the save files")
	if corrupt_copy != "":
		_expect(_read_text(corrupt_copy) == CORRUPT_CONTENT, "retained corrupt copy must preserve the original bytes")

	var invalid_shape: Dictionary = save_manager._default_save()
	invalid_shape["player"]["gold"] = "not-a-number"
	_write_text(save_manager._save_path, JSON.stringify(invalid_shape))
	save_manager.load_game()
	_expect(int(save_manager.save_data.get("player", {}).get("gold", -1)) == 111, "schema-invalid main must also recover the verified backup")
	_expect(_gold_at(save_manager._save_path) == 111, "schema fallback must leave a valid rebuilt main file")
	save_manager._suppress_expected_persistence_errors_for_tests = false

func _test_migration_and_recursive_defaults() -> void:
	var legacy_save := {
		"version": 0,
		"player": {"gold": 73},
		"unlocks": {"levels": ["level_001"]},
		"equipment": {"selected_weapon": "weapon_autocannon"}
	}
	_write_text(save_manager._save_path, JSON.stringify(legacy_save, "\t"))
	save_manager.load_game()

	_expect(int(save_manager.save_data.get("version", -1)) == save_manager.CURRENT_SAVE_VERSION, "legacy save must migrate through the explicit version entry point")
	_expect(int(save_manager.save_data.get("player", {}).get("gold", -1)) == 73, "migration must retain legacy values")
	_expect(int(save_manager.save_data.get("player", {}).get("xp", -1)) == 0, "migration must recursively add nested player defaults")
	_expect(save_manager.save_data.get("unlocks", {}).get("weapons", []).has("weapon_autocannon"), "migration must add nested unlock defaults")
	_expect(str(save_manager.save_data.get("equipment", {}).get("selected_armor", "missing")) == "", "migration must add nested equipment defaults")

	var persisted := _read_json(save_manager._save_path)
	_expect(int(persisted.get("version", -1)) == save_manager.CURRENT_SAVE_VERSION, "migrated version must be persisted")
	_expect(persisted.get("player", {}).has("xp"), "persisted migration must include merged defaults")

	var deep_defaults := {"outer": {"middle": {"kept": 4, "added": 9}}}
	var deep_candidate := {"outer": {"middle": {"kept": 8}}}
	var deep_merged: Dictionary = save_manager._merge_defaults_recursive(deep_defaults, deep_candidate)
	_expect(int(deep_merged.get("outer", {}).get("middle", {}).get("kept", -1)) == 8, "recursive merge must preserve a deep saved value")
	_expect(int(deep_merged.get("outer", {}).get("middle", {}).get("added", -1)) == 9, "recursive merge must add a deep missing default")

func _test_manual_backup_restore() -> void:
	var committed_gold := int(save_manager.save_data.get("player", {}).get("gold", -1))
	save_manager.backup_game()
	_expect(save_manager.has_backup(), "manual backup must produce a verified backup record")

	var unsaved_change: Dictionary = save_manager.save_data.duplicate(true)
	unsaved_change["player"]["gold"] = committed_gold + 700
	save_manager.save_data = unsaved_change
	_expect(save_manager.restore_backup(), "manual backup must be restorable")
	_expect(int(save_manager.save_data.get("player", {}).get("gold", -1)) == committed_gold, "restore must replace in-memory data with the backed-up value")
	_expect(_gold_at(save_manager._save_path) == committed_gold, "restore must atomically replace the persisted main save")

func _test_missing_main_fallback() -> void:
	var expected_gold := int(save_manager.save_data.get("player", {}).get("gold", -1))
	var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(save_manager._save_path))
	_expect(remove_error == OK, "missing-main fixture must remove the current main save")
	save_manager.save_data = save_manager._default_save()
	save_manager.load_game()
	_expect(int(save_manager.save_data.get("player", {}).get("gold", -1)) == expected_gold, "a missing main save must recover the verified backup")
	_expect(_gold_at(save_manager._save_path) == expected_gold, "missing-main recovery must rebuild a valid main save")

func _test_application_pause_persistence() -> void:
	var lifecycle_save: Dictionary = save_manager.save_data.duplicate(true)
	lifecycle_save["player"]["gold"] = 31415
	save_manager.save_data = lifecycle_save

	var input_manager := root.get_node("/root/InputManager")
	var audio_manager := root.get_node("/root/AudioManager")
	input_manager._begin_aim_press(Vector2(360, 720), 0)
	audio_manager.resume_audio()

	var main := (load("res://main.tscn") as PackedScene).instantiate()
	main._notification(NOTIFICATION_APPLICATION_PAUSED)
	_expect(not bool(input_manager._aim_press_active), "application pause must cancel an active touch/aim gesture")
	_expect(bool(audio_manager._manual_paused), "application pause must suspend managed audio")
	_expect(_gold_at(save_manager._save_path) == 31415, "application pause must persist the latest in-memory save")

	main._notification(NOTIFICATION_APPLICATION_RESUMED)
	_expect(not bool(audio_manager._manual_paused), "application resume must restore managed audio")
	main.free()

func _test_write_failure_preserves_good_files() -> void:
	var main_before := _read_text(save_manager._save_path)
	var backup_before := _read_text(save_manager._backup_path)
	var temp_path: String = "%s.tmp" % save_manager._save_path
	var temp_global := ProjectSettings.globalize_path(temp_path)
	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(temp_global)
	var mkdir_error := DirAccess.make_dir_absolute(temp_global)
	_expect(mkdir_error == OK, "write-failure fixture must block the temporary file path")

	var changed: Dictionary = save_manager.save_data.duplicate(true)
	changed["player"]["gold"] = 9999
	save_manager.save_data = changed
	save_manager._last_persistence_error = ""
	save_manager._suppress_expected_persistence_errors_for_tests = true
	save_manager.save_game()
	save_manager._suppress_expected_persistence_errors_for_tests = false

	_expect(_read_text(save_manager._save_path) == main_before, "temporary-file open failure must not alter the good main file")
	_expect(_read_text(save_manager._backup_path) == backup_before, "failed main write must not rotate or alter the backup")
	_expect("cannot open temporary main save" in save_manager._last_persistence_error, "write failure must expose a diagnostic")
	DirAccess.remove_absolute(temp_global)

func _gold_at(path: String) -> int:
	return int(_read_json(path).get("player", {}).get("gold", -1))

func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(_read_text(path))
	_expect(parsed is Dictionary, "%s must contain valid JSON save data" % path)
	return parsed if parsed is Dictionary else {}

func _write_text(path: String, contents: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	_expect(file != null, "test fixture must open %s for writing" % path)
	if file == null:
		return
	file.store_string(contents)
	file.flush()
	var write_error := file.get_error()
	file.close()
	_expect(write_error == OK, "test fixture must flush %s" % path)

func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	_expect(file != null, "test fixture must open %s for reading" % path)
	if file == null:
		return ""
	var contents := file.get_as_text()
	file.close()
	return contents

func _find_corrupt_copy() -> String:
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		return ""
	for file_name in dir.get_files():
		if file_name.begins_with("save_main.corrupt.") and file_name.ends_with(".json"):
			return "%s/%s" % [TEST_DIR, file_name]
	return ""

func _remove_tree(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file_name in dir.get_files():
		DirAccess.remove_absolute(ProjectSettings.globalize_path("%s/%s" % [path, file_name]))
	for directory_name in dir.get_directories():
		_remove_tree("%s/%s" % [path, directory_name])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
