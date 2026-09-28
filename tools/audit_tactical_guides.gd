extends SceneTree

# Use a disposable project/user directory: never mutate a player's save.
var failures: Array[String] = []
var checked := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var capture := args.size() > 0
	var output := str(args[0]) if capture else ""
	if capture:
		DirAccess.make_dir_recursive_absolute(output)
	var data: Node = root.get_node("DataLoader")
	data.load_all()
	var save: Node = root.get_node("SaveManager")
	save.suppress_persistence_for_captures = true
	var fixture: Dictionary = save._default_save()
	for level in data.get_table("levels"):
		fixture.levels_progress[str(level.id)] = 3
	save.save_data = fixture
	root.get_node("PurchaseManager").refresh_catalog_and_access()
	var viewport := SubViewport.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var main: Node = load("res://main.tscn").instantiate()
	viewport.add_child(main)
	await process_frame
	# Main loads its save on ready; install the preview fixture afterwards.
	save.save_data = fixture
	root.get_node("PurchaseManager").refresh_catalog_and_access()
	var samples := ["skill_split_shot", "skill_incendiary", "weapon_apocalypse_golden_law", "armor_apocalypse_permafrost", "chip_element", "pet_apocalypse_skyfalcon", "vanguard", "frost"]
	for height in [1920, 2340]:
		viewport.size = Vector2i(1080, height)
		for language in ["zh", "en"]:
			root.get_node("LocalizationManager").apply_language(language, false)
			for table in ["skills", "weapons", "armors", "chips", "pets", "characters"]:
				main.change_scene("collection", {"mode": table})
				await process_frame
				var collection: Node = main.current_scene
				for item_id in data.get_table(table):
					if capture and (height != 2340 or not samples.has(str(item_id))):
						continue
					collection._show_item_detail(str(item_id), data.get_row(table, str(item_id)))
					for frame in range(8):
						await process_frame
					if capture:
						# Let the real modal entrance fade/scale finish before visual QA.
						await create_timer(0.35).timeout
					var modal: Control = collection._detail_modal
					var context := "%s/%s/%d" % [item_id, language, height]
					if modal == null:
						failures.append(context + ": missing detail")
						continue
					var body_name := "CharacterTacticalBody" if table == "characters" else "DescriptionBody"
					var body := modal.find_child(body_name, true, false) as Label
					var scroll := modal.find_child("DetailScroll", true, false) as ScrollContainer
					var guide: Dictionary = data.get_row("tactical_guides", str(item_id))
					if body == null or scroll == null:
						failures.append(context + ": missing tactical body or scroll")
						continue
					if not body.text.contains(str(guide["guide_" + language])):
						failures.append(context + ": authored copy not wired to UI")
					for node in modal.find_children("*", "Label", true, false):
						var label := node as Label
						if label.name not in [body_name, "CharacterModelBody", "SkillDescription", "ItemSummary"]:
							continue
						if label.clip_text or label.max_lines_visible != -1:
							failures.append(context + ": clipped label " + str(label.name))
						if label.get_minimum_size().y > label.size.y + 1.0:
							failures.append(context + ": insufficient text height " + str(label.name))
						var rect := label.get_global_rect()
						if rect.position.x < 0 or rect.end.x > 1080.5:
							failures.append(context + ": horizontal overflow " + str(label.name))
					if capture:
						await RenderingServer.frame_post_draw
						viewport.get_texture().get_image().save_png(output.path_join(context.replace("/", "_") + "_top.png"))
					# The final text line must be reachable above the fixed actions.
					scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
					for frame in range(4):
						await process_frame
					if body.get_global_rect().end.y > scroll.get_global_rect().end.y + 1.0:
						failures.append(context + ": tactical last line unreachable at scroll end")
					if capture:
						await RenderingServer.frame_post_draw
						viewport.get_texture().get_image().save_png(output.path_join(context.replace("/", "_") + "_bottom.png"))
					checked += 1
					collection._close_character_detail()
					await process_frame
			print("TACTICAL_LAYOUT completed language=", language, " height=", height, " checked=", checked)
	main.queue_free()
	for frame in range(5):
		await process_frame
	viewport.queue_free()
	await process_frame
	root.get_node("AudioManager").release_for_tests()
	for tween in get_processed_tweens():
		tween.kill()
	UiKit.release_cached_resources_for_tests()
	for failure in failures:
		push_error(failure)
	print("TACTICAL_LAYOUT checked=", checked, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
