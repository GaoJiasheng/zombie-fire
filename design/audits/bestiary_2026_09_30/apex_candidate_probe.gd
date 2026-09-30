extends "res://tools/frontline_runtime_probe.gd"

func _parse_arguments() -> bool:
	var damage := int(OS.get_environment("ZF_APEX_DAMAGE"))
	assert(damage > 0)
	root.get_node("DataLoader").tables["bosses"]["boss_apex_overlord"]["mechanic_params"]["base_attack_damage"] = damage
	return super._parse_arguments()
