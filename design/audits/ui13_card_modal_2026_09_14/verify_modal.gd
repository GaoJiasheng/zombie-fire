extends SceneTree

const Kit := preload("res://ui/ui_kit.gd")
var failures: Array[String] = []

func _expect(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _settle() -> void:
	for i in range(12):
		await process_frame

func _initialize() -> void:
	for bus in range(AudioServer.bus_count):
		AudioServer.set_bus_mute(bus, true)
	await process_frame
	root.get_node("SaveManager").suppress_persistence_for_captures = true
	var data = root.get_node("DataLoader")
	var locale = root.get_node("LocalizationManager")
	for size in [Vector2i(750, 1334), Vector2i(1080, 1920), Vector2i(1320, 2868)]:
		for language in ["zh", "en"]:
			locale.apply_language(language, false)
			var viewport := SubViewport.new()
			viewport.size = size
			var scale_factor := minf(float(size.x) / 1080.0, float(size.y) / 1920.0)
			viewport.size_2d_override = Vector2i(floor(size.x / scale_factor), floor(size.y / scale_factor))
			viewport.size_2d_override_stretch = true
			root.add_child(viewport)
			var main = load("res://main.tscn").instantiate()
			viewport.add_child(main)
			await _settle()
			main.change_scene("battle", {"level_id": "level_001"})
			await _settle()
			var battle = main.current_scene
			battle._show_card_offer()
			await create_timer(0.2, true, false, true).timeout
			var cards: VBoxContainer = battle.get_node("Hud/CardPanel/Cards")
			for child in cards.get_children():
				cards.remove_child(child)
				child.queue_free()
			for id in ["skill_slow_field", "skill_incendiary", "skill_critical"]:
				var row: Dictionary = data.get_row("skills", id)
				cards.add_child(battle._build_skill_card(id, row, data.tr_key(row.name_key), 5))
			await _settle()
			battle._refresh_card_offer_dynamic_layout()
			await _settle()
			var panel: Control = battle.get_node("Hud/CardPanel")
			var wave: Control = battle.get_node(battle.HUD_WAVE_BAR_PATH)
			var gap: float = panel.get_global_rect().position.y - wave.get_global_rect().end.y
			var last: Control = cards.get_child(2)
			var actions: Control = panel.get_node("RerollButton")
			var natural: Array = []
			var header: Label = panel.get_node("CardTitle")
			print("UI13_HEADER:", header.text, " size=",header.size," unwrapped=",header.get_theme_font("font").get_string_size(header.text.replace("\n", " · "),HORIZONTAL_ALIGNMENT_LEFT,-1,header.get_theme_font_size("font_size")))
			for card in cards.get_children():
				natural.append({"height":card.get_meta("card_offer_natural_height"),"stats":card.get_node("Stats").size,"desc":card.get_node("Desc").size,"tags":card.get_node("Tags").size})
			print("UI13_GEOMETRY:", JSON.stringify({"size":size,"language":language,"gap":gap,"gap_pixels":gap*scale_factor,"panel":panel.get_global_rect(),"content":panel.get_meta("card_offer_content_height"),"natural":natural,"wave":wave.get_global_rect(),"cards":cards.size,"last_bottom":last.position.y+last.size.y,"actions_bottom":actions.position.y+actions.size.y,"breach":battle.BREACH_Y}))
			_expect(gap >= 48.0 - 0.5, "offer must keep at least 48 canvas px below wave progress")
			_expect(panel.get_global_rect().end.y <= battle.BREACH_Y + 0.5, "offer must remain above breach line")
			_expect(last.position.y + last.size.y <= cards.size.y + 0.5, "whole third card must remain in card lane")
			_expect(actions.position.y + actions.size.y <= panel.size.y - 24.0, "actions must retain bottom frame padding")
			for card in cards.get_children():
				var desc: Label = card.get_node("Desc")
				var stats: Label = card.get_node("Stats")
				var tags: Control = card.get_node("Tags")
				_expect(stats.position.y + stats.size.y + battle.CARD_OFFER_COPY_GAP <= desc.position.y + 0.5, "complete stats must remain above description")
				_expect(desc.position.y + desc.size.y + battle.CARD_OFFER_DESC_TAG_GAP <= tags.position.y + 0.5, "complete description must remain above tags")
				_expect(tags.position.y + tags.size.y + battle.CARD_OFFER_BOTTOM_PADDING <= card.size.y + 0.5, "tags must remain inside card")
				_expect(desc.get_theme_font_size("font_size") == Kit.scaled_font_size(16 if language == "en" else 17), "description must retain authorized font")
				_expect(desc.get_visible_line_count() >= desc.get_line_count(), "description must retain every line")
			var markers: CanvasItem = battle.get_node("ThreatMarkerLayer")
			var nameplate := Label.new()
			nameplate.text = "Frontline·Frost"
			markers.add_child(nameplate)
			var lod_hidden := Label.new()
			lod_hidden.visible = false
			markers.add_child(lod_hidden)
			_expect(not nameplate.is_visible_in_tree(), "all world nameplates including new children must hide during offer")
			battle._render_card_offer(battle.skills.owned)
			_expect(not nameplate.is_visible_in_tree(), "reroll must not reveal world nameplates")
			battle._show_card_detail("skill_split_shot")
			_expect(not nameplate.is_visible_in_tree(), "nested detail must not reveal world nameplates")
			battle._hide_card_detail()
			battle._close_card_offer(false)
			_expect(nameplate.is_visible_in_tree() and not lod_hidden.is_visible_in_tree(), "closing restores visible names without overriding LOD-hidden names")
			battle._show_card_offer()
			_expect(not nameplate.is_visible_in_tree(), "reopening must hide names immediately")
			battle._close_card_offer(false)
			viewport.queue_free()
			await _settle()
	print("UI13 modal regression: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
