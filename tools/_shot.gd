extends SceneTree

# Visual capture helper: loads a scene through the real router and screenshots the
# viewport so container-layout refactors can be verified, not just smoke-compiled.
# Usage: godot --path . --script tools/_shot.gd -- <route> [payload_json] [out_png]

func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var route := args[0] if args.size() > 0 else "menu"
	var payload: Dictionary = {}
	if args.size() > 1 and args[1] != "":
		var parsed: Variant = JSON.parse_string(args[1])
		if parsed is Dictionary:
			payload = parsed
	var out_path := args[2] if args.size() > 2 else "/tmp/zf_shot_%s.png" % route

	var dl := root.get_node("/root/DataLoader")
	dl.load_all()
	var sm := root.get_node("/root/SaveManager")
	sm.load_game()
	if payload.has("equipment") and payload["equipment"] is Dictionary:
		_apply_equipment_override(sm, payload["equipment"])
	var main = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	if payload.has("equipment") and payload["equipment"] is Dictionary:
		_apply_equipment_override(sm, payload["equipment"])
	if route != "menu":
		main.change_scene(route, payload)
	for i in range(12):
		await process_frame
		await physics_frame
	var image := root.get_viewport().get_texture().get_image()
	if image == null:
		print("FAIL: viewport screenshot unavailable; run without --headless for visual capture")
		quit(2)
		return
	image.save_png(out_path)
	print("shot saved: ", out_path, " size=", image.get_size())
	quit()

func _apply_equipment_override(save_manager: Node, equipment_override: Dictionary) -> void:
	var shot_save: Dictionary = save_manager.save_data.duplicate(true)
	var equipment: Dictionary = shot_save.get("equipment", {}).duplicate(true)
	for key in equipment_override.keys():
		equipment[str(key)] = equipment_override[key]
	shot_save["equipment"] = equipment
	var unlocks: Dictionary = shot_save.get("unlocks", {}).duplicate(true)
	_ensure_unlocked(unlocks, "characters", str(equipment.get("selected_character", "")))
	_ensure_unlocked(unlocks, "weapons", str(equipment.get("selected_weapon", "")))
	_ensure_unlocked(unlocks, "armors", str(equipment.get("selected_armor", "")))
	_ensure_unlocked(unlocks, "chips", str(equipment.get("selected_chip", "")))
	_ensure_unlocked(unlocks, "pets", str(equipment.get("selected_pet", "")))
	shot_save["unlocks"] = unlocks
	save_manager.save_data = shot_save

func _ensure_unlocked(unlocks: Dictionary, key: String, item_id: String) -> void:
	if item_id == "":
		return
	var items: Array = unlocks.get(key, []).duplicate()
	if not items.has(item_id):
		items.append(item_id)
	unlocks[key] = items
