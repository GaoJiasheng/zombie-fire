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
	if payload.has("viewport_size") and payload["viewport_size"] is Array and (payload["viewport_size"] as Array).size() >= 2:
		var viewport_size: Array = payload["viewport_size"]
		root.size = Vector2i(int(viewport_size[0]), int(viewport_size[1]))
		DisplayServer.window_set_size(root.size)
		await process_frame

	var dl := root.get_node("/root/DataLoader")
	dl.load_all()
	var sm := root.get_node("/root/SaveManager")
	sm.load_game()
	if payload.has("save_override") and payload["save_override"] is Dictionary:
		_apply_save_override(sm, payload["save_override"])
	if payload.has("equipment") and payload["equipment"] is Dictionary:
		_apply_equipment_override(sm, payload["equipment"])
	var main = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	if payload.has("save_override") and payload["save_override"] is Dictionary:
		_apply_save_override(sm, payload["save_override"])
	if payload.has("equipment") and payload["equipment"] is Dictionary:
		_apply_equipment_override(sm, payload["equipment"])
	if route != "menu":
		main.change_scene(route, payload)
	for i in range(12):
		await process_frame
		await physics_frame
	if payload.has("debug_spawn_boss") and main.current_scene != null and main.current_scene.has_method("_spawn_enemy"):
		var boss_id := str(payload.get("debug_spawn_boss", ""))
		if boss_id != "":
			main.current_scene.call("_spawn_enemy", boss_id, "center", true)
	if bool(payload.get("debug_barrier", false)) and main.current_scene != null and main.current_scene.has_method("_update_barrier_visual"):
		var skill_runtime: Variant = main.current_scene.get("skills")
		if skill_runtime != null and skill_runtime.has_method("add_skill"):
			skill_runtime.call("add_skill", "skill_barrier")
		main.current_scene.call("_update_barrier_visual")
	var warmup_frames := clampi(int(payload.get("warmup_frames", 0)), 0, 600)
	for i in range(warmup_frames):
		await process_frame
		await physics_frame
	if bool(payload.get("pause", false)) and main.current_scene != null and main.current_scene.has_method("_set_battle_paused"):
		main.current_scene.call("_set_battle_paused", true, false)
		for i in range(2):
			await process_frame
	if payload.has("detail_item") and main.current_scene != null and main.current_scene.has_method("_show_item_detail"):
		var detail_item := str(payload.get("detail_item", ""))
		var table_data: Dictionary = _current_collection_table(str(payload.get("mode", "")))
		if detail_item != "" and table_data.has(detail_item):
			main.current_scene.call("_show_item_detail", detail_item, table_data[detail_item])
			for i in range(18):
				await process_frame
	if bool(payload.get("card_offer", false)) and main.current_scene != null and main.current_scene.has_method("_show_card_offer"):
		main.current_scene.call("_show_card_offer")
		for i in range(18):
			await process_frame
	if payload.has("card_detail") and main.current_scene != null and main.current_scene.has_method("_show_card_detail"):
		var skill_id := str(payload.get("card_detail", "skill_split_shot"))
		if skill_id != "":
			if main.current_scene.has_node("Hud/CardPanel"):
				main.current_scene.get_node("Hud/CardPanel").visible = true
			main.current_scene.call("_show_card_detail", skill_id)
			for i in range(18):
				await process_frame
	var image := root.get_viewport().get_texture().get_image()
	if image == null:
		print("FAIL: viewport screenshot unavailable; run without --headless for visual capture")
		await _cleanup_scene(main)
		quit(2)
		return
	image.save_png(out_path)
	print("shot saved: ", out_path, " size=", image.get_size())
	await _cleanup_scene(main)
	quit(0)

func _cleanup_scene(main: Node) -> void:
	paused = false
	Engine.time_scale = 1.0
	if main != null and is_instance_valid(main):
		main.queue_free()
	var audio := root.get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("release_for_tests"):
		audio.release_for_tests()
	for i in range(3):
		await process_frame

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

func _apply_save_override(save_manager: Node, save_override: Dictionary) -> void:
	var shot_save: Dictionary = save_manager.save_data.duplicate(true)
	for key in save_override.keys():
		if shot_save.has(key) and shot_save[key] is Dictionary and save_override[key] is Dictionary:
			var nested: Dictionary = shot_save[key].duplicate(true)
			nested.merge(save_override[key], true)
			shot_save[key] = nested
		else:
			shot_save[key] = save_override[key]
	save_manager.save_data = shot_save

func _ensure_unlocked(unlocks: Dictionary, key: String, item_id: String) -> void:
	if item_id == "":
		return
	var items: Array = unlocks.get(key, []).duplicate()
	if not items.has(item_id):
		items.append(item_id)
	unlocks[key] = items

func _current_collection_table(mode: String) -> Dictionary:
	match mode:
		"characters":
			return root.get_node("/root/DataLoader").get_table("characters")
		"weapons":
			return root.get_node("/root/DataLoader").get_table("weapons")
		"armors":
			return root.get_node("/root/DataLoader").get_table("armors")
		"chips":
			return root.get_node("/root/DataLoader").get_table("chips")
		"pets":
			return root.get_node("/root/DataLoader").get_table("pets")
		"skills":
			return root.get_node("/root/DataLoader").get_table("skills")
		_:
			return {}
