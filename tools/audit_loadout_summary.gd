extends SceneTree

# Real layout regression: actual recommendations, localization, live reflow,
# and the last action's reachability. Optional output folder enables renders.
const UiKit := preload("res://ui/ui_kit.gd")
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_size(Vector2i(1, 1))
		DisplayServer.window_set_position(Vector2i(-32000, -32000))
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)

func settle() -> void:
	for frame in range(12):
		await process_frame

func _run() -> void:
	var save: Node = root.get_node("SaveManager")
	var data: Node = root.get_node("DataLoader")
	var purchase: Node = root.get_node("PurchaseManager")
	data.load_all()
	save.suppress_persistence_for_captures = true
	# This audit tests layout/rendering, never sound. Avoid real BGM playback
	# retaining an audio-thread resource during fast native screenshot runs.
	root.get_node("AudioManager")._headless_audio = true
	for index in range(AudioServer.bus_count):
		AudioServer.set_bus_mute(index, true)
	var args := OS.get_cmdline_user_args()
	var output := str(args[0]) if not args.is_empty() else ""
	if output != "":
		DirAccess.make_dir_recursive_absolute(output)
	var viewport := SubViewport.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var main: Node = load("res://main.tscn").instantiate()
	viewport.add_child(main)
	await settle()
	for height in [1920, 2340, 2346]:
		viewport.size = Vector2i(1080, height)
		for language in ["zh", "en"]:
			root.get_node("LocalizationManager").apply_language(language, false)
			for fixture in ["empty", "owner", "two_advice"]:
				save.save_data = save._default_save()
				var equipment: Dictionary = save.save_data.equipment
				var stage := "level_001"
				if fixture != "empty":
					stage = "level_030"
					for level_no in range(1, 31):
						save.save_data.levels_progress["level_%03d" % level_no] = 1
					equipment.merge({"selected_character": "frost", "frost": 20,
						"selected_weapon": "weapon_scattergun", "weapon_scattergun": 10,
						"selected_armor": "", "selected_chip": "",
						"selected_pet": "pet_frost_wisp", "pet_frost_wisp": 1}, true)
					save.save_data.unlocks.characters = ["vanguard", "frost"]
					save.save_data.unlocks.weapons = ["weapon_autocannon", "weapon_scattergun"]
					save.save_data.unlocks.pets = ["pet_frost_wisp"]
					if fixture == "two_advice":
						save.save_data.unlocks.weapons.append("weapon_flamethrower")
						equipment["weapon_flamethrower"] = 10
				purchase.refresh_catalog_and_access()
				main.change_scene("loadout", {"level_id": stage})
				await settle()
				var scene: Control = main.current_scene
				var context := "%s_%s_%d" % [fixture, language, height]
				audit(scene, context)
				var premium := scene.find_child("PremiumCounterSuggestion", true, false) as Button
				check((premium != null) == (fixture != "empty"), context + " premium fixture missing/unexpected")
				check((scene.find_child("CounterSuggestion", true, false) != null) == (fixture == "two_advice"), context + " counter fixture missing/unexpected")
				if output != "" and height == 2340 and fixture != "empty":
					await RenderingServer.frame_post_draw
					viewport.get_texture().get_image().save_png(output.path_join(context + ".png"))
				if premium != null:
					var cost := premium.find_child("CatchUpCostText", true, false) as Label
					var original := cost.text
					var panel := scene.find_child("DetailsPanel", true, false) as Control
					var initial_height := panel.size.y
					# Runtime text changes must grow AND shrink, without rebuilding
					# the screen or an explicit fit call. Force a scrollable page too.
					cost.text = original + ("\n" + original).repeat(12)
					await settle()
					check(panel.size.y > initial_height + 250.0, context + " live text did not grow summary")
					audit(scene, context + "_long")
					var scroll := scene.find_child("ContentScroll", true, false) as ScrollContainer
					scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
					await settle()
					var start := scene.find_child("StartButton", true, false) as Control
					check(scroll.get_global_rect().encloses(start.get_global_rect()), context + " action unreachable after scroll")
					cost.text = original
					scroll.scroll_vertical = 0
					await settle()
					check(absf(panel.size.y - initial_height) < 1.0, context + " shorter text left stale height")
					# A narrower safe area changes wrapping without changing text.
					var margin := scene.get_node("Root") as MarginContainer
					margin.add_theme_constant_override("margin_left", 72)
					margin.add_theme_constant_override("margin_right", 72)
					await settle()
					audit(scene, context + "_narrow")
	main.queue_free()
	await settle()
	viewport.queue_free()
	await process_frame
	root.get_node("AudioManager").release_for_tests()
	for tween in get_processed_tweens():
		tween.kill()
	UiKit.release_cached_resources_for_tests()
	for failure in failures:
		printerr(failure)
	print("LOADOUT_SUMMARY_AUDIT checks=", checks, " failures=", failures.size())
	if failures.is_empty():
		print("LOADOUT_SUMMARY_AUDIT PASSED")
	quit(0 if failures.is_empty() else 1)

func audit(scene: Control, context: String) -> void:
	var panel := scene.find_child("DetailsPanel", true, false) as Control
	var box := panel.find_child("SummaryContent", true, false) as VBoxContainer
	var scroll := scene.find_child("ContentScroll", true, false) as ScrollContainer
	check(panel.get_global_rect().position.x >= scroll.get_global_rect().position.x - 0.5
		and panel.get_global_rect().end.x <= scroll.get_global_rect().end.x + 0.5, context + " summary overflows viewport width")
	var previous_end := box.get_global_rect().position.y
	for child: Control in box.get_children():
		var rect := child.get_global_rect()
		check(rect.position.y >= previous_end - 0.5, context + " overlapping summary section " + child.name)
		check(panel.get_global_rect().encloses(rect), context + " section outside summary " + child.name)
		previous_end = rect.end.y
	for label: Label in box.find_children("*", "Label", true, false):
		check(not label.clip_text and label.max_lines_visible == -1, context + " hidden text " + label.name)
		check(label.size.y >= label.get_minimum_size().y - 0.5, context + " text height " + label.name)
	var premium := scene.find_child("PremiumCounterSuggestion", true, false) as Button
	if premium != null:
		var copy := premium.get_node("RecommendationContent") as VBoxContainer
		check(premium.get_global_rect().encloses(copy.get_global_rect()), context + " premium copy outside hit area")
		var previous: Control = null
		for child: Control in copy.get_children():
			if previous != null:
				check(child.get_global_rect().position.y - previous.get_global_rect().end.y >= 9.5, context + " cramped advice lines")
			previous = child
		var recap := scene.find_child("EquipmentRecap", true, false) as Control
		check(recap.get_global_rect().position.y - premium.get_global_rect().end.y >= 15.5, context + " advice crowds equipment recap")
	var start := scene.find_child("StartButton", true, false) as Control
	check(start.get_global_rect().position.y - panel.get_global_rect().end.y >= 27.5, context + " summary crowds action")
