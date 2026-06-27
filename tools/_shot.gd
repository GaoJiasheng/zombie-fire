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
	var main = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	if route != "menu":
		main.change_scene(route, payload)
	for i in range(12):
		await process_frame
		await physics_frame
	var image := root.get_viewport().get_texture().get_image()
	image.save_png(out_path)
	print("shot saved: ", out_path, " size=", image.get_size())
	quit()
