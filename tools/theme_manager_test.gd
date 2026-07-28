extends SceneTree

const UiKit := preload("res://ui/ui_kit.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var data_loader := root.get_node("/root/DataLoader")
	var save_manager := root.get_node("/root/SaveManager")
	var settings_manager := root.get_node("/root/SettingsManager")
	var theme_manager := root.get_node("/root/ThemeManager")
	data_loader.load_all()

	var save_snapshot: Dictionary = save_manager.save_data.duplicate(true)
	var settings_snapshot: Dictionary = settings_manager.settings.duplicate(true)
	save_manager.save_data = save_manager._default_save()

	save_manager.select_theme("neon_tempest", false)
	theme_manager.refresh_from_save()
	_expect(
		theme_manager.active_theme_id() == "default",
		"unowned premium theme must fall back to default"
	)

	var verified_entitlements: Array[String] = ["ent_theme_neon_tempest"]
	save_manager.replace_verified_entitlements(
		verified_entitlements,
		int(Time.get_unix_time_from_system()),
		false
	)
	save_manager.select_theme("neon_tempest", false)
	theme_manager.refresh_from_save()
	_expect(
		theme_manager.active_theme_id() == "neon_tempest",
		"verified entitlement must activate Neon Tempest"
	)

	for native_size: Vector2i in UiKit.NATIVE_BUTTON_SIZES:
		for kind in ["primary", "secondary"]:
			var path: String = str(
				theme_manager.resolve_button_path(kind, native_size, kind == "secondary")
			)
			_expect(path != "", "missing %s theme button at %s" % [kind, str(native_size)])
			if path == "":
				continue
			var image := Image.load_from_file(ProjectSettings.globalize_path(path))
			_expect(
				image != null and image.get_size() == native_size,
				"%s must be exact-size %s, got %s" % [
					path,
					str(native_size),
					str(image.get_size()) if image != null else "null",
				]
			)

	var texture_button := TextureButton.new()
	UiKit.apply_armored_texture_button(texture_button, true, Vector2(600, 120), true)
	_expect(
		texture_button.stretch_mode == TextureButton.STRETCH_KEEP_ASPECT_CENTERED,
		"themed TextureButtons must never use STRETCH_SCALE"
	)
	_expect(
		texture_button.texture_normal != null
			and texture_button.texture_normal.resource_path.contains("/themes/neon_tempest/"),
		"UiKit must route active theme buttons through ThemeManager"
	)
	texture_button.free()

	settings_manager.settings["reduced_effects"] = false
	var full_material: ShaderMaterial = theme_manager.create_character_iridescence_material()
	_expect(full_material != null, "Neon Tempest must create the character iridescence material")
	if full_material != null:
		_expect(
			is_equal_approx(float(full_material.get_shader_parameter("flow_speed")), 0.72),
			"full character iridescence must animate"
		)
	settings_manager.settings["reduced_effects"] = true
	var reduced_material: ShaderMaterial = theme_manager.create_character_iridescence_material()
	if reduced_material != null:
		_expect(
			is_zero_approx(float(reduced_material.get_shader_parameter("flow_speed"))),
			"reduced effects must freeze rainbow flow"
		)
		_expect(
			float(reduced_material.get_shader_parameter("effect_intensity")) <= 0.16,
			"reduced effects must lower rainbow intensity"
		)

	save_manager.save_data = save_snapshot
	settings_manager.settings = settings_snapshot
	if failures.is_empty():
		print("Theme manager test passed: entitlement fallback, 72 exact-size buttons, non-stretch routing, and reduced VFX.")
		quit(0)
	else:
		for failure in failures:
			push_error("Theme manager test: %s" % failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
