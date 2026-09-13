extends SceneTree

const Kit := preload("res://ui/ui_kit.gd")
var failures: Array[String] = []

func _expect(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _settle() -> void:
	for frame in range(12):
		await process_frame

func _verify_owned_cards(store: Control, data: Node, language: String) -> void:
	for viewport in [Vector2i(1080, 1920), Vector2i(1320, 2868), Vector2i(750, 1334)]:
		root.size = viewport
		await _settle()
		for set_id in data.get_table("premium_sets"):
			var set_row: Dictionary = data.get_row("premium_sets", set_id)
			for pair in [["weapons", "weapon"], ["armors", "armor"], ["chips", "chip"], ["pets", "pet"]]:
				var card: PanelContainer = store._owned_item_row(pair[0], pair[1], str(set_row[pair[1]]))
				# A conservative content width inside the 1080-equivalent portrait page.
				card.size = Vector2(900, 0)
				store.add_child(card)
				await _settle()
				var style := card.get_theme_stylebox("panel")
				var inner := card.get_global_rect().grow(-18.0)
				for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
					_expect(style.get_content_margin(side) >= 18.0, "owned card must reserve texture-frame padding on every side")
				var layout := card.get_child(0) as HBoxContainer
				var copy := layout.get_child(1) as VBoxContainer
				for label in copy.get_children():
					_expect(inner.grow(0.5).encloses(label.get_global_rect()), "%s %s %s owned copy must stay inside padded frame" % [language, viewport, set_id])
					_expect(label.get_visible_line_count() >= label.get_line_count(), "owned card must retain all title and state lines")
				var title := copy.get_child(0) as Label
				_expect(title.get_theme_font_size("font_size") == Kit.scaled_font_size(22), "owned title must retain authorized type size")
				var upgrade := layout.get_child(2) as Button
				_expect(inner.grow(0.5).encloses(upgrade.get_global_rect()), "owned upgrade button must remain inside frame")
				_expect(absf(upgrade.get_global_rect().get_center().y - inner.get_center().y) <= 1.0, "owned upgrade action must be vertically centered, not stretched")
				card.queue_free()
				await _settle()

func _initialize() -> void:
	for bus in range(AudioServer.bus_count):
		AudioServer.set_bus_mute(bus, true)
	await process_frame
	root.get_node("SaveManager").suppress_persistence_for_captures = true
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await _settle()
	var locale = root.get_node("LocalizationManager")
	var themes = root.get_node("ThemeManager")
	var data = root.get_node("DataLoader")
	var surface_test := TextureButton.new()
	var original_material := CanvasItemMaterial.new()
	surface_test.material = original_material
	themes._set_active_without_persist("neon_tempest")
	Kit.apply_armored_texture_button(surface_test, false, Vector2(286, 80), true)
	var face := surface_test.get_node("ArmoredFace") as Panel
	_expect(surface_test.material is ShaderMaterial and (surface_test.material as ShaderMaterial).shader == Kit.ARMORED_FACE_OWNER, "neon nine-slice must be the sole painted surface, with no original-raster ghost")
	_expect(not face.use_parent_material and face.get_theme_stylebox("panel") is StyleBoxTexture, "visible neon face must remain independently texture-backed")
	var face_style := face.get_theme_stylebox("panel") as StyleBoxTexture
	_expect(face_style.region_rect == Rect2(Kit._armored_face_bounds(face_style.texture)), "nine-slice must use visible-rim bounds, not almost-transparent export staging")
	surface_test.disabled = true
	Kit._sync_armored_face(surface_test, face)
	_expect(face.get_theme_stylebox("panel") == face.get_meta("disabled_style"), "disabled state must update the visible nine-slice")
	themes._set_active_without_persist("default")
	Kit.apply_armored_texture_button(surface_test, false, Vector2(286, 80), true)
	_expect(surface_test.material == original_material and surface_test.get_node_or_null("ArmoredFace") == null, "switching theme must restore the original material and remove the neon face")
	surface_test.free()
	for language in ["zh", "en"]:
		locale.apply_language(language, false)
		for theme in ["default", "neon_tempest", "infernal_dominion", "polar_aurora", "gilded_eclipse"]:
			themes._set_active_without_persist(theme)
			main.change_scene("collection", {"mode": "weapons"})
			await _settle()
			for title in main.current_scene.find_children("Title", "Label", true, false):
				var badge = title.get_parent().get_node_or_null("LevelBadge")
				if badge == null:
					continue
				var line_height: float = title.get_theme_font("font").get_height(title.get_theme_font_size("font_size"))
				var expected: float = title.position.y + title.size.y - line_height * 0.5
				_expect(absf(badge.position.y + badge.size.y * 0.5 - expected) <= 1.0, "%s %s %s weapon badge must align with the last visible title line" % [language, theme, title.text])
				_expect(title.get_visible_line_count() >= title.get_line_count(), "weapon name must display every line")
			main.change_scene("map")
			await _settle()
			for action in main.current_scene.find_children("EnterChapterButton", "TextureButton", true, false):
				_expect(action.size == Vector2(286, 80), "native chapter CTA must remain 286x80")
			main.change_scene("loadout")
			await _settle()
			for weapon_id in data.get_table("weapons"):
				var weapon: Dictionary = data.get_row("weapons", weapon_id)
				var original := str(weapon.get("loadout_art", weapon.get("handheld", weapon.get("icon", ""))))
				_expect(main.current_scene._loadout_weapon_source_path(weapon_id, weapon) == original, "every theme must reuse original authored weapon showcase, not a new theme prototype")
			_expect(not FileAccess.file_exists("res://ui/" + "weapon_showcase_theme.gdshader"), "Owner-cancelled recolor shader must be removed")
		main.change_scene("store")
		await _settle()
		await _verify_owned_cards(main.current_scene, data, language)
		for native_message in ["Purchase cancelled", "Awaiting approval", "Network unavailable", "无法连接 App Store"]:
			_expect(main.current_scene._english_message(native_message, true) == native_message, "native purchase status must never be rewritten as demo failure")
		main.change_scene("collection", {"mode": "pets"})
		await _settle()
		for sample in [[10.5, "10.5"], [12.0, "12"], [8.25, "8.25"]]:
			var expected := ("%ss Cooldown" if language == "en" else "%s秒冷却") % sample[1]
			var actual: String = main.current_scene._pet_skill_cooldown_text({"kind": "test", "cooldown": sample[0]})
			_expect(actual == expected, "pet cooldown must preserve integer and fractional seconds: expected %s, got %s" % [expected, actual])
		_expect(main.current_scene._pet_skill_cooldown_text({"kind": "wave_salvage"}) == "每波触发", "wave-triggered pet wording must remain unchanged")
		_expect(main.current_scene._pet_skill_cooldown_text({"kind": "repair"}) == "分层自动触发", "repair pet wording must remain unchanged")
		main.change_scene("battle", {"level_id": "level_001"})
		await _settle()
		var battle = main.current_scene
		for size in [Vector2i(1080, 1920), Vector2i(1320, 2868), Vector2i(750, 1334)]:
			root.size = size
			await _settle()
			var header: Label = battle.get_node("Hud/CardPanel/CardTitle")
			header.text = "Choose Upgrade · Prioritize Slow / Homing" if language == "en" else "选择强化 · 优先减速 / 追踪"
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
			var panel: Panel = battle.get_node("Hud/CardPanel")
			var bounds: Vector2 = battle._card_offer_vertical_bounds()
			var actions: Control = panel.get_node("RerollButton")
			_expect(panel.position.y >= bounds.x - 0.5 and panel.position.y + panel.size.y <= bounds.y + 0.5, "long English cards must remain within battlefield corridor")
			_expect(cards.position.y + cards.size.y + battle.CARD_OFFER_ACTION_GAP <= actions.position.y + 0.5, "long cards must preserve the action quiet lane")
			var last: Control = cards.get_child(cards.get_child_count() - 1)
			_expect(last.position.y + last.size.y <= cards.size.y + 0.5, "%s %s all three complete cards must fit" % [language, size])
			for card in cards.get_children():
				var desc: Label = card.get_node("Desc")
				_expect(desc.get_theme_font_size("font_size") == Kit.scaled_font_size(16 if language == "en" else 17), "offer descriptions must retain the improved authorized size")
				_expect(desc.get_visible_line_count() >= desc.get_line_count(), "offer description must not lose a line")
	main.queue_free()
	await _settle()
	print("UI finish regression: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
