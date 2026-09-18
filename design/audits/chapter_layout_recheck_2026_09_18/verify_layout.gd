extends SceneTree
const Kit := preload("res://ui/ui_kit.gd")
var failures: Array[String] = []
var checked := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func settle() -> void:
	for i in range(12):
		await process_frame
func _initialize() -> void:
	OS.set_environment("ZOMBIE_FIRE_DEBUG_SAFE_INSETS", "44,132,44,102")
	for bus in range(AudioServer.bus_count):
		AudioServer.set_bus_mute(bus, true)
	await process_frame
	var save = root.get_node("SaveManager")
	save.suppress_persistence_for_captures = true
	for theme in ["default", "neon_tempest", "infernal_dominion", "polar_aurora", "gilded_eclipse"]:
		for native in [Vector2i(1080,1920),Vector2i(1320,2868),Vector2i(750,1334)]:
			for language in ["zh", "en"]:
				var viewport := SubViewport.new()
				viewport.size = native
				var factor := minf(native.x / 1080.0, native.y / 1920.0)
				viewport.size_2d_override = Vector2i(floor(native.x / factor), floor(native.y / factor))
				viewport.size_2d_override_stretch = true
				root.add_child(viewport)
				var main = load("res://main.tscn").instantiate()
				viewport.add_child(main)
				await settle()
				save.save_data = save._default_save()
				for level in root.get_node("DataLoader").get_table("levels"):
					save.save_data["unlocks"]["levels"].append(level.id)
					save.save_data["levels_progress"][level.id] = 3
				root.get_node("LocalizationManager").apply_language(language, false)
				root.get_node("ThemeManager")._set_active_without_persist(theme)
				main.change_scene("map", {"chapter":1})
				await settle()
				var map = main.current_scene
				var back: Button = map.find_child("ChapterBackButton", true, false)
				for chapter in range(1,11):
					map._open_chapter(chapter)
					await settle()
					var list: VBoxContainer = map.find_child("LevelList", true, false)
					var header: Control = list.get_child(0)
					var body: Control = header.get_node("ChapterDetailContent")
					var progress: Control = header.get_node("ChapterProgress")
					var header_back: Control = header.get_node("BackToChapterMapButton")
					if chapter == 1:
						print("CHAPTER_GEOMETRY ",theme," ",native," ",language," header=",header.size.y," stage001=",(list.get_child(1) as Control).size.y)
					check(header.get_global_rect().encloses(body.get_global_rect()), "chapter body fits")
					check(header.get_global_rect().encloses(progress.get_global_rect()), "chapter progress fits")
					check(header_back.size == Vector2(286,80), "native back button retained")
					check(header_back.position.y >= 172 and header_back.get_rect().end.y <= header.size.y - 56, "existing back separation ruler retained")
					check(not progress.get_global_rect().intersects(header_back.get_global_rect()), "progress/back separation")
					check(body.get_rect().end.y + 16 <= progress.position.y, "full story before footer")
					for label in body.get_children():
						check(label.get_visible_line_count() >= label.get_line_count(), "chapter text fully visible")
					for card in list.get_children():
						# Reopening the current chapter may temporarily uniquify node
						# names while queued old cards leave; count by card structure.
						if not card.has_node("LevelTitle"):continue
						checked += 1
						var title: Label = card.get_node("LevelTitle")
						var row: HBoxContainer = card.get_node("LevelSummaryRow")
						check(title.get_theme_font_size("font_size") == Kit.scaled_font_size(30), "level title font retained")
						check(title.get_visible_line_count() >= title.get_line_count(), "level title fully visible")
						check(title.get_rect().end.y + 8 <= row.position.y, "metadata below title")
						check(card.get_global_rect().encloses(row.get_global_rect()), "metadata fits")
						check(is_equal_approx(row.get_child(0).position.y, row.get_child(1).position.y), "metadata shares row")
						var variant: Control = card.get_node_or_null("VariantMarker")
						for name in ["NormalModeButton", "ChallengeModeButton"]:
							var action: Control = card.get_node_or_null(name)
							if action == null:continue
							check(is_equal_approx(action.position.y, 14), "mode buttons remain alongside stage title")
							check(card.get_global_rect().encloses(action.get_global_rect()), "action fits")
							check(not action.get_global_rect().intersects(title.get_global_rect()) and not action.get_global_rect().intersects(row.get_global_rect()), "action does not overlap text")
							if variant != null:check(not action.get_global_rect().intersects(variant.get_global_rect()), "action/variant separation")
						if variant != null:
							check(not title.get_global_rect().intersects(variant.get_global_rect()) and not row.get_global_rect().intersects(variant.get_global_rect()), "variant does not overlap copy")
					var scroll: ScrollContainer = map.find_child("LevelScroll", true, false)
					var back_rect := back.get_global_rect()
					scroll.scroll_vertical = 10000
					await settle()
					check(back.get_global_rect() == back_rect, "top back remains fixed")
				back.pressed.emit()
				await settle()
				check(map.selected_chapter == 0 and not back.visible, "top back returns to overview")
				print("CHAPTER_LAYOUT ",theme," ",native," ",language," checked")
				viewport.queue_free()
				await settle()
	check(checked == 2970, "all 99 stages x five themes x three sizes x two languages were checked")
	print("Chapter layout regression: %d stages, %d failures" % [checked, failures.size()])
	quit(0 if failures.is_empty() else 1)
