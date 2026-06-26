extends Node

const TABLES := [
	"elements",
	"economy",
	"characters",
	"weapons",
	"armors",
	"chips",
	"pets",
	"zombies",
	"bosses",
	"skills",
	"levels",
	"localization_zh",
]

var tables := {}

func load_all() -> void:
	tables.clear()
	for table in TABLES:
		tables[table] = _load_json("res://data/%s.json" % table)

func get_table(table: String) -> Variant:
	return tables.get(table, {})

func get_row(table: String, id: String) -> Dictionary:
	var data: Variant = get_table(table)
	if data is Dictionary:
		return data.get(id, {})
	if data is Array:
		for row in data:
			if row.get("id") == id:
				return row
	return {}

func tr_key(key: String) -> String:
	return get_table("localization_zh").get(key, key)

func level_number(level_id: String) -> String:
	var value := level_id
	if value.begins_with("level_"):
		value = value.replace("level_", "")
	if value.is_valid_int():
		return "%03d" % int(value)
	return value

func level_name(level_id: String) -> String:
	var row := get_row("levels", level_id)
	return str(row.get("name", ""))

func level_display_name(level_id: String) -> String:
	var number := level_number(level_id)
	var name := level_name(level_id)
	if name == "":
		return number
	return "%s %s" % [number, name]

func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Missing data file: %s" % path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_error("Invalid JSON: %s" % path)
		return {}
	return parsed
