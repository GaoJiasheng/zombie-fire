extends "res://tools/frontline_runtime_probe.gd"

# Read-only comparison: restore only the two pre-change siege overrides in memory.
func _parse_arguments() -> bool:
	var loader := root.get_node("DataLoader")
	for row in loader.tables["bosses"].values():
		row["mechanic_params"].erase("base_attack_damage")
		row["mechanic_params"].erase("base_attack_interval")
	return super._parse_arguments()
