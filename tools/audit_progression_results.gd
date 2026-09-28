extends SceneTree

var Result: GDScript
var Values: GDScript
const UiKit := preload("res://ui/ui_kit.gd")
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)

func _run() -> void:
	await process_frame
	Result = load("res://ui/progression_result.gd")
	Values = load("res://ui/progression_values.gd")
	var data: Node = root.get_node("DataLoader")
	var save: Node = root.get_node("SaveManager")
	var purchase: Node = root.get_node("PurchaseManager")
	data.load_all()
	save.suppress_persistence_for_captures = true
	var args := OS.get_cmdline_user_args()
	var output := str(args[0]) if args.size() > 0 else ""
	if output != "":
		DirAccess.make_dir_recursive_absolute(output)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1080, 2340)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var main: Node = load("res://main.tscn").instantiate()
	viewport.add_child(main)
	await process_frame
	var fixture: Dictionary = save._default_save()
	fixture.player.gold = 1000000
	fixture.player.xp = 1000000
	fixture.player.star = 9999
	for stage in data.get_table("levels"):
		fixture.levels_progress[str(stage.id)] = 3
	for table in ["characters", "weapons", "armors", "chips", "pets"]:
		fixture.unlocks[table] = data.get_table(table).keys()
	save.save_data = fixture
	purchase.refresh_catalog_and_access()
	for product_id in data.get_table("store_products"):
		if str(data.get_row("store_products", product_id).get("kind", "")) == "arsenal_complete":
			purchase.mock_purchase(product_id, false)
	var baseline: Dictionary = save.save_data.duplicate(true)
	# All categories: debit exactly once, correct levels and repeat limits.
	for table in ["characters", "weapons", "armors", "chips", "pets", "skills", "signature"]:
		for id in data.get_table("characters" if table == "signature" else table):
			save.save_data = baseline.duplicate(true)
			var before: Dictionary = Values.snapshot(table, id)
			var result: Dictionary = Result._transact(table, id)
			check(not result.is_empty(), table + "/" + str(id) + " upgrade rejected")
			if result.is_empty():
				continue
			var after: Dictionary = Values.snapshot(table, id)
			check(not str(after.name).begins_with("sig_"), str(id) + " internal ID leaked into title")
			for stat in after.stats.values():
				check(not "_" in str(stat.label), str(id) + " internal stat key leaked: " + str(stat.label))
			check(int(after.level) == int(before.level) + 1, str(id) + " wrong level")
			var kind: String = result.cost.kind
			check(int(baseline.player[kind]) - int(save.save_data.player[kind]) == int(result.cost.amount), str(id) + " wrong debit")
			check(ResourceLoader.exists(str(after.icon)), str(id) + " missing icon " + str(after.icon))
	# Formula anchors and truthful zero-to-one.
	check(is_equal_approx(Values.hero_attribute(data.get_row("characters", "frost"), 20, "attack"), 143.128), "Frost Lv20 attack formula")
	var golden: Dictionary = Values.snapshot("weapons", "weapon_apocalypse_golden_law", 50)
	var golden_next: Dictionary = Values.snapshot("weapons", "weapon_apocalypse_golden_law", 51)
	check(golden.stats.rate == golden_next.stats.rate, "Golden overcap must not invent extra cadence")
	check(Values.changes(Values.snapshot("skills", "skill_split_shot", 0), Values.snapshot("skills", "skill_split_shot", 1)).is_empty(), "0-to-1 must not invent card combat gains")
	save.save_data = baseline.duplicate(true)
	save.save_data.player.gold = 0
	var frozen: Dictionary = save.save_data.duplicate(true)
	check(Result._transact("weapons", "weapon_autocannon").is_empty(), "Insufficient funds must not celebrate")
	check(save.save_data == frozen, "Failed upgrade changed save")
	save.save_data = baseline.duplicate(true)
	save.save_data.equipment.weapon_apocalypse_golden_law = 65
	frozen = save.save_data.duplicate(true)
	check(Result._transact("weapons", "weapon_apocalypse_golden_law").is_empty(), "Maxed weapon must not upgrade")
	check(save.save_data == frozen, "Maxed upgrade changed save")
	var samples := [["characters", "frost", 20], ["signature", "frost", 2], ["skills", "skill_split_shot", 2], ["weapons", "weapon_scattergun", 17], ["weapons", "weapon_apocalypse_golden_law", 50], ["armors", "armor_apocalypse_permafrost", 12], ["chips", "chip_apocalypse_golden_law", 12], ["pets", "pet_apocalypse_skyfalcon", 12]]
	for height in [1920, 2340]:
		viewport.size = Vector2i(1080, height)
		for language in ["zh", "en"]:
			root.get_node("LocalizationManager").apply_language(language, false)
			for sample in samples:
				save.save_data = baseline.duplicate(true)
				var table: String = sample[0]
				var id: String = sample[1]
				if table == "signature":
					save.save_data.sig_skill_levels[id] = sample[2]
				elif table == "skills":
					save.save_data.skill_base_levels[id] = sample[2]
				else:
					save.save_data.equipment[id] = sample[2]
				main.change_scene("collection", {"mode": "characters" if table == "signature" else table})
				await process_frame
				var collection: Node = main.current_scene
				if table == "signature":
					collection._upgrade_sig_skill_from_detail(id)
				elif table == "skills":
					collection._upgrade_skill_from_detail(id, data.get_row(table, id))
				else:
					collection._upgrade_item_from_detail(id, data.get_row(table, id))
				var popup: Node = collection.get_node("ProgressionResult")
				var context := "%s_%s_%s_%d" % [table, id, language, height]
				await audit(popup, context, output if height == 2340 else "")
				var old: int = Values.snapshot(table, id).level
				popup._repeat()
				check(int(Values.snapshot(table, id).level) == old + 1, context + " repeat should grant one level")
				popup._close()
				await process_frame
			# Actual ordinary purchase route, with its existing auto-equip behavior.
			save.save_data = baseline.duplicate(true)
			save.save_data.unlocks.weapons.erase("weapon_teslacoil")
			main.change_scene("collection", {"mode": "weapons"})
			await process_frame
			main.current_scene._do_purchase("weapons", "weapon_teslacoil")
			await audit(main.current_scene.get_node("ProgressionResult"), "new_weapon_" + language + "_" + str(height), output if height == 2340 else "")
			for suffix in ["arsenal.golden_law_complete", "arsenal.golden_law_upgrade", "theme.gilded_eclipse"]:
				main.change_scene("store")
				await process_frame
				main.current_scene._on_purchase_finished("com.gaojiasheng.zombiefire." + suffix, true, "")
				await audit(main.current_scene.get_node("ProgressionResult"), suffix + "_" + language + "_" + str(height), output if height == 2340 else "")
	main.queue_free()
	for frame in range(6):
		await process_frame
	viewport.queue_free()
	await process_frame
	root.get_node("AudioManager").release_for_tests()
	for tween in get_processed_tweens():
		tween.kill()
	UiKit.release_cached_resources_for_tests()
	for failure in failures:
		push_error(failure)
	print("PROGRESSION_RESULT checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

func audit(popup: Node, context: String, output: String) -> void:
	await create_timer(0.3).timeout
	var panel: Control = popup.panel
	var rect := panel.get_global_rect()
	var view := panel.get_viewport_rect()
	check(view.encloses(rect), context + " panel overflow " + str(rect))
	for button in panel.find_children("*", "Button", true, false):
		check(rect.encloses(button.get_global_rect()), context + " action outside panel")
	for label in panel.find_children("*", "Label", true, false):
		if label.name == "SpentCost":
			check(label.get_line_count() == 1, context + " cost must remain on one line")
		check(not label.clip_text and label.get_minimum_size().y <= label.size.y + 1, context + " text clipped: " + str(label.text))
		check(label.get_global_rect().end.x <= rect.end.x, context + " text horizontal overflow")
	if output != "":
		await RenderingServer.frame_post_draw
		popup.get_viewport().get_texture().get_image().save_png(output.path_join(context + ".png"))
	popup.scroll.scroll_vertical = int(popup.scroll.get_v_scroll_bar().max_value)
	for frame in range(4):
		await process_frame
	check(popup.body.get_global_rect().end.y <= popup.scroll.get_global_rect().end.y + 1, context + " final line unreachable")
