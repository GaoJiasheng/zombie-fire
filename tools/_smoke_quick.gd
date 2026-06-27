extends SceneTree

func _initialize() -> void:
	print("start")
	await process_frame
	var dl := root.get_node("/root/DataLoader")
	dl.load_all()
	print("loaded data")
	var sm := root.get_node("/root/SaveManager")
	sm.load_game()
	print("loaded save")
	var main = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	print("main loaded, scene=", main.current_scene.name)
	main.change_scene("collection", {"mode": "characters"})
	await process_frame
	print("collection loaded, scene=", main.current_scene.name)
	var list: Node = main.current_scene.get_node("ItemScroll/ItemList")
	print("list children=", list.get_child_count())
	if list.get_child_count() > 0:
		var first: Node = list.get_child(0)
		print("first child=", first.name, " is TextureButton=", first is TextureButton)
	main.change_scene("map")
	await process_frame
	print("map loaded, scene=", main.current_scene.name)
	print("DONE")
	quit(0)