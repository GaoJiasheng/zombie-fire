extends SceneTree
const Kit := preload("res://ui/ui_kit.gd")
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func settle() -> void:
	for i in range(12):
		await process_frame
func _initialize() -> void:
	for bus in range(AudioServer.bus_count):
		AudioServer.set_bus_mute(bus,true)
	await process_frame
	var save = root.get_node("SaveManager")
	save.suppress_persistence_for_captures = true
	for native in [Vector2i(1080,1920),Vector2i(1320,2868),Vector2i(750,1334)]:
		for language in ["zh","en"]:
			var viewport := SubViewport.new()
			viewport.size = native
			var scale_factor := minf(native.x/1080.0,native.y/1920.0)
			viewport.size_2d_override = Vector2i(floor(native.x/scale_factor),floor(native.y/scale_factor))
			viewport.size_2d_override_stretch = true
			root.add_child(viewport)
			var main = load("res://main.tscn").instantiate()
			viewport.add_child(main)
			await settle()
			save.save_data = save._default_save()
			for level in root.get_node("DataLoader").get_table("levels"):
				save.save_data["unlocks"]["levels"].append(level.id)
				save.save_data["levels_progress"][level.id] = 3
			root.get_node("LocalizationManager").apply_language(language,false)
			main.change_scene("map",{"chapter":1})
			await settle()
			var map = main.current_scene
			var back: Button = map.find_child("ChapterBackButton",true,false)
			check(back != null and back.is_visible_in_tree(),"chapter has fixed top back button")
			for chapter in range(1,11):
				map._open_chapter(chapter)
				await settle()
				var page_title: Label = map.find_child("Title",true,false)
				check(not back.get_global_rect().intersects(page_title.get_global_rect()),"back must not overlap chapter title")
				check(page_title.get_visible_line_count() >= page_title.get_line_count(),"chapter title must not clip")
				var list: VBoxContainer = map.find_child("LevelList",true,false)
				for card in list.get_children():
					if not str(card.name).begins_with("level_"):continue
					var title: Label = card.get_node("LevelTitle")
					var row: HBoxContainer = card.get_node("LevelSummaryRow")
					check(title.get_theme_font_size("font_size") == Kit.scaled_font_size(30),"large title ruler: "+card.name)
					check(title.get_visible_line_count() >= title.get_line_count(),"full stage title visible: "+card.name)
					check(title.get_rect().end.y+8 <= row.position.y,"summary below full title: "+card.name)
					check(card.get_global_rect().encloses(row.get_global_rect()),"summary fits card: "+card.name)
					var power: Control = row.get_child(0)
					var weakness: Control = row.get_child(1)
					check(is_equal_approx(power.position.y,weakness.position.y),"power and weakness share row")
					check(power.get_rect().end.x+10 <= weakness.position.x,"metadata chips retain separation")
					for name in ["NormalModeButton","ChallengeModeButton"]:
						var action: Control = card.get_node_or_null(name)
						if action == null:continue
						check(card.get_global_rect().encloses(action.get_global_rect()),"mode button fits card: "+card.name)
						check(not action.get_global_rect().intersects(title.get_global_rect()) and not action.get_global_rect().intersects(row.get_global_rect()),"mode button must not overlap copy: "+card.name)
					var variant: Control = card.get_node_or_null("VariantMarker")
					if variant != null:
						check(not title.get_global_rect().intersects(variant.get_global_rect()),"variant must not overlap title")
				var scroll: ScrollContainer = map.find_child("LevelScroll",true,false)
				var fixed_rect := back.get_global_rect()
				scroll.scroll_vertical = 10000
				await settle()
				check(back.get_global_rect() == fixed_rect,"back stays fixed while level list scrolls")
			back.pressed.emit()
			await settle()
			check(map.selected_chapter == 0 and not back.visible,"top back returns to overview and hides itself")
			print("LEVEL_LAYOUT ",native," ",language," 99 stages checked")
			viewport.queue_free()
			await settle()
	print("Level layout regression: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
