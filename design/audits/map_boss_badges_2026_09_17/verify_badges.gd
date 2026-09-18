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

func touch(viewport: SubViewport, point: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = point
	event.pressed = down
	viewport.push_input(event, true)

func _initialize() -> void:
	# Headless has no touch display. Enable the desktop touch-scroll path and
	# inject the companion mouse stream that iOS normally synthesizes for GUI.
	Input.emulate_touch_from_mouse = true
	for bus in range(AudioServer.bus_count):
		AudioServer.set_bus_mute(bus, true)
	await process_frame
	var save = root.get_node("SaveManager")
	save.suppress_persistence_for_captures = true
	for native in [Vector2i(750,1334), Vector2i(1080,1920), Vector2i(1320,2868)]:
		for language in ["zh", "en"]:
			var viewport := SubViewport.new()
			viewport.size = native
			var scale_factor := minf(native.x / 1080.0, native.y / 1920.0)
			viewport.size_2d_override = Vector2i(floor(native.x/scale_factor),floor(native.y/scale_factor))
			viewport.size_2d_override_stretch = true
			root.add_child(viewport)
			var main = load("res://main.tscn").instantiate()
			viewport.add_child(main)
			await settle()
			save.save_data = save._default_save()
			root.get_node("LocalizationManager").apply_language(language, false)
			main.change_scene("map")
			await settle()
			var map = main.current_scene
			var list: VBoxContainer = map.find_child("LevelList",true,false)
			var scroll: ScrollContainer = map.find_child("LevelScroll",true,false)
			for card in list.get_children():
				var action: Control = card.find_child("EnterChapterButton",true,false)
				check(action.size == Vector2(286,80), "native CTA must remain exactly 286x80")
				check(card.get_global_rect().end.x - action.get_global_rect().end.x >= 30, "CTA must keep right frame inset")
				check(card.get_global_rect().encloses(action.get_global_rect()), "CTA must fit actual chapter card, including safe-area pressure")
				var minor: Control = card.find_child("SmallBossNode",true,false)
				var major: Control = card.find_child("MajorBossNode",true,false)
				check(minor.size.x >= 112 and major.size.x >= 112, "boss badges must reserve icon/number breathing room")
				check(action.get_global_rect().position.x - major.get_global_rect().end.x >= 6, "badge/action controls must retain row separation")
				for badge in [minor,major]:
					var number: Label = badge.find_child("BossLevelNumber",true,false)
					check(badge.get_global_rect().encloses(number.get_global_rect()), "number must fit badge")
					check(number.get_theme_font_size("font_size") == Kit.scaled_font_size(13), "boss numbers must not shrink")
			var badge: Control = list.get_child(0).find_child("SmallBossNode",true,false)
			scroll.ensure_control_visible(badge)
			await settle()
			var point := badge.get_global_rect().get_center()
			touch(viewport,point,true)
			touch(viewport,point,false)
			await create_timer(0.6).timeout
			check(map.find_child("ChapterBossHint",true,false) == null, "short tap must not show long-press hint")
			touch(viewport,point,true)
			await create_timer(0.65).timeout
			await settle()
			var hint: PanelContainer = map.find_child("ChapterBossHint",true,false)
			check(hint != null and hint.visible, "real touch long press must show hint")
			if hint != null:
				print("HINT_RECT ",hint.get_global_rect()," min=",hint.get_combined_minimum_size()," viewport=",viewport.get_visible_rect())
				check(viewport.get_visible_rect().encloses(hint.get_global_rect()), "hint must fit viewport")
				var copy: Label = hint.find_child("BossHintText",true,false)
				check(copy.text.contains("5") and copy.text.contains("stage number" if language == "en" else "关卡编号"), "hint must explain exact stage number in selected language")
				check(copy.get_visible_line_count() >= copy.get_line_count(), "all hint lines must remain visible")
				check(not hint.get_global_rect().intersects(badge.get_global_rect()), "hint must not obscure held badge")
			touch(viewport,point,false)
			map._hide_chapter_boss_hint()
			var scroll_before := scroll.scroll_vertical
			touch(viewport,point,true)
			var mouse_drag_press := InputEventMouseButton.new()
			mouse_drag_press.button_index = MOUSE_BUTTON_LEFT
			mouse_drag_press.pressed = true
			mouse_drag_press.position = point
			viewport.push_input(mouse_drag_press,true)
			var drag := InputEventScreenDrag.new()
			drag.index = 0
			drag.position = point + Vector2(0,-50)
			drag.relative = Vector2(0,-50)
			viewport.push_input(drag,true)
			var mouse_drag := InputEventMouseMotion.new()
			mouse_drag.button_mask = MOUSE_BUTTON_MASK_LEFT
			mouse_drag.position = drag.position
			mouse_drag.relative = drag.relative
			viewport.push_input(mouse_drag,true)
			await process_frame
			drag.position = point + Vector2(0,-100)
			viewport.push_input(drag,true)
			mouse_drag.position = drag.position
			viewport.push_input(mouse_drag,true)
			await create_timer(0.65).timeout
			check(hint == null or not hint.visible, "drag must cancel long press")
			check(scroll.scroll_vertical > scroll_before, "drag starting on a badge must actually scroll the map")
			touch(viewport,drag.position,false)
			mouse_drag_press.pressed = false
			mouse_drag_press.position = drag.position
			viewport.push_input(mouse_drag_press,true)
			check(map.selected_chapter == 0, "badge gesture must not open chapter")
			var locked: Control = list.get_child(9).find_child("MajorBossNode",true,false)
			scroll.ensure_control_visible(locked)
			await settle()
			var mouse := InputEventMouseButton.new()
			mouse.button_index = MOUSE_BUTTON_LEFT
			mouse.position = locked.get_global_rect().get_center()
			mouse.pressed = true
			viewport.push_input(mouse,true)
			await create_timer(0.65).timeout
			await settle()
			check(hint != null and hint.visible, "mouse hold on locked major boss must show explanation")
			if hint != null:
				check((hint.find_child("BossHintText",true,false) as Label).text.contains("99"), "last chapter hint must use actual stage 99, not an inferred stage 100")
			mouse.pressed = false
			viewport.push_input(mouse,true)
			map._open_chapter(1)
			check(hint == null or not hint.visible, "navigation must dismiss stale hint")
			print("BADGE_CHECK ",native," ",language," button=",list.get_child(0).find_child("EnterChapterButton",true,false).get_global_rect()," badge=",badge.get_global_rect())
			viewport.queue_free()
			await settle()
	print("Boss badge regression: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
