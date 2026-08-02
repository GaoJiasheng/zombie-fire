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
	var purchase_manager := root.get_node("/root/PurchaseManager")
	data_loader.load_all()

	var save_snapshot: Dictionary = save_manager.save_data.duplicate(true)
	var settings_snapshot: Dictionary = settings_manager.settings.duplicate(true)
	save_manager.save_data = save_manager._default_save()

	save_manager.select_theme("default", false)
	theme_manager.refresh_from_save()
	_expect(
		theme_manager.active_theme_id() == "default",
		"preview access must not force Neon Tempest over the saved default"
	)
	_expect(not theme_manager.preview_access_enabled(), "ordinary debug builds must not bypass the purchase flow")
	_expect(not theme_manager.select_theme("neon_tempest"), "Neon Tempest must reject selection without an entitlement")
	save_manager.save_data["commerce"]["mock_receipts"] = [
		"com.gaojiasheng.zombiefire.theme.neon_tempest"
	]
	purchase_manager._catalog = data_loader.get_table("store_products")
	purchase_manager.reconcile_access(false)
	_expect(theme_manager.select_theme("neon_tempest"), "local demo entitlement must activate Neon Tempest")
	_expect(
		not save_manager.has_verified_entitlement("ent_theme_neon_tempest"),
		"local demo selection must never forge a verified commerce entitlement"
	)

	save_manager.save_data["commerce"]["mock_receipts"] = []
	purchase_manager.reconcile_access(false)
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
	save_manager.select_theme("default", false)
	theme_manager.refresh_from_save()
	_expect(
		theme_manager.select_character_outfit("vanguard", "neon_tempest", false),
		"an owned Neon Tempest outfit must be selectable independently of the global theme"
	)
	_expect(
		theme_manager.effective_character_theme_id("vanguard") == "neon_tempest",
		"an explicit hero outfit must override the default global theme"
	)
	_expect(
		theme_manager.resolve_character_animation_base("vanguard") != "",
		"an explicit Neon outfit must route the matching battle animation"
	)
	_expect(
		theme_manager.select_character_outfit("frost", "default", false),
		"the default hero outfit must remain selectable while Neon Tempest is owned"
	)
	theme_manager.select_theme("neon_tempest")
	_expect(
		theme_manager.effective_character_theme_id("frost") == "default",
		"an explicit default outfit must not be overwritten by a global Neon selection"
	)
	_expect(
		theme_manager.resolve_character_animation_base("frost") == "",
		"an explicit default outfit must keep the original battle animation"
	)
	_expect(
		theme_manager.create_character_material("frost") == null,
		"an explicit default outfit must not inherit the Neon character shader"
	)
	theme_manager.select_character_outfit("blaze", "follow_theme", false)
	_expect(
		theme_manager.effective_character_theme_id("blaze") == "neon_tempest",
		"Follow Global must resolve against the active theme"
	)

	for character_id in ["char_vanguard", "char_blaze", "char_frost", "char_volt"]:
		theme_manager.select_character_outfit(character_id, "follow_theme", false)
		var animation_base: String = theme_manager.resolve_character_animation_base(character_id)
		_expect(animation_base != "", "missing themed battle animation base for %s" % character_id)
		for action_spec in [["idle", 4], ["attack", 4], ["hurt", 3]]:
			for frame_number in range(1, int(action_spec[1]) + 1):
				var frame_path := "%s_%s_%02d.png" % [
					animation_base,
					str(action_spec[0]),
					frame_number,
				]
				_expect(ResourceLoader.exists(frame_path), "missing Neon Tempest runtime frame %s" % frame_path)
	var fire_aura: Array[Texture2D] = theme_manager.resolve_effect_sequence("character_fire_aura")
	_expect(fire_aura.size() == 4, "Neon Tempest firing aura must expose four rendered frames")
	for texture in fire_aura:
		_expect(texture.get_size() == Vector2(512, 512), "firing aura frames must be 512x512")

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
	_expect(
		texture_button.self_modulate == theme_manager.button_surface_modulate(true, true),
		"Neon Tempest TextureButton surfaces must be restrained without dimming child copy"
	)
	_expect(
		texture_button.modulate == Color.WHITE,
		"enabled themed TextureButtons must keep child labels at full brightness"
	)
	texture_button.free()

	var text_button := Button.new()
	UiKit.apply_armored_button(text_button, true, Vector2(600, 120), 30, true)
	var normal_style := text_button.get_theme_stylebox("normal")
	_expect(
		normal_style is StyleBoxTexture
			and (normal_style as StyleBoxTexture).modulate_color == theme_manager.button_surface_modulate(true, true),
		"Neon Tempest Button style must tone down only the themed surface"
	)
	_expect(
		text_button.get_theme_constant("outline_size") >= 3,
		"armored button copy needs a dark outline over luminous punk surfaces"
	)
	text_button.free()

	settings_manager.settings["reduced_effects"] = false
	var full_material: ShaderMaterial = theme_manager.create_character_material()
	_expect(full_material != null, "Neon Tempest must create the character iridescence material")
	if full_material != null:
		_expect(
			is_equal_approx(float(full_material.get_shader_parameter("flow_speed")), 0.46),
			"full character iridescence must animate"
		)
	settings_manager.settings["reduced_effects"] = true
	var reduced_material: ShaderMaterial = theme_manager.create_character_material()
	if reduced_material != null:
		_expect(
			is_zero_approx(float(reduced_material.get_shader_parameter("flow_speed"))),
			"reduced effects must freeze rainbow flow"
		)
		_expect(
			float(reduced_material.get_shader_parameter("effect_intensity")) <= 0.24,
			"reduced effects must lower rainbow intensity"
		)

	# Second-series regression: Infernal Dominion must use its own runtime tree,
	# rear-view battle sprites and furnace shader without changing Neon assets.
	verified_entitlements = ["ent_theme_neon_tempest", "ent_theme_infernal_dominion"]
	save_manager.replace_verified_entitlements(verified_entitlements, int(Time.get_unix_time_from_system()), false)
	_expect(theme_manager.select_theme("infernal_dominion"), "verified entitlement must activate Infernal Dominion")
	_expect(theme_manager.active_theme_id() == "infernal_dominion", "Infernal Dominion must become the active theme")
	for character_id in ["char_vanguard", "char_blaze", "char_frost", "char_volt"]:
		theme_manager.select_character_outfit(character_id, "follow_theme", false)
		var infernal_base: String = theme_manager.resolve_character_animation_base(character_id)
		_expect(infernal_base.contains("/themes/infernal_dominion/"), "Infernal battle animation must use its own runtime root for %s" % character_id)
		for action_spec in [["idle", 4], ["attack", 4], ["hurt", 3]]:
			for frame_number in range(1, int(action_spec[1]) + 1):
				var frame_path := "%s_%s_%02d.png" % [infernal_base, str(action_spec[0]), frame_number]
				_expect(ResourceLoader.exists(frame_path), "missing Infernal rear-view runtime frame %s" % frame_path)
	var infernal_aura: Array[Texture2D] = theme_manager.resolve_effect_sequence("character_fire_aura")
	_expect(infernal_aura.size() == 4, "Infernal firing wings must expose four rendered frames")
	for texture in infernal_aura:
		_expect(texture.get_size() == Vector2(768, 768), "Infernal rear fire-wing frames must be 768x768")
	for native_size: Vector2i in UiKit.NATIVE_BUTTON_SIZES:
		for kind in ["primary", "secondary"]:
			var infernal_button: String = str(theme_manager.resolve_button_path(kind, native_size, kind == "secondary"))
			_expect(infernal_button.contains("/themes/infernal_dominion/ui/"), "missing native Infernal %s button at %s" % [kind, str(native_size)])
	var autocannon_fallback := str(data_loader.get_row("weapons", "weapon_autocannon").get("icon", ""))
	var infernal_autocannon: String = str(theme_manager.resolve_weapon_asset("weapon_autocannon", "icon", autocannon_fallback))
	_expect(infernal_autocannon.contains("/themes/infernal_dominion/weapons/"), "free weapons must resolve the active Infernal coating")
	var inferno_weapon: Dictionary = data_loader.get_row("weapons", "weapon_apocalypse_inferno")
	var inferno_icon := str(inferno_weapon.get("icon", ""))
	_expect(theme_manager.resolve_weapon_asset("weapon_apocalypse_inferno", "icon", inferno_icon) == inferno_icon, "premium weapon identity must not be overwritten by a cosmetic coating")
	var infernal_material: ShaderMaterial = theme_manager.create_character_material("vanguard")
	_expect(infernal_material != null and infernal_material.shader.resource_path.contains("infernal_dominion_character.gdshader"), "Infernal characters must use the furnace-edge shader")
	var inferno_true_grip: Dictionary = inferno_weapon.get("presentation", {}).get("true_grip", {})
	_expect(str(inferno_true_grip.get("viewpoint", "")) == "rear", "Inferno true-grip battle art must be explicitly rear-view")
	for suffix in ["_left", "", "_right"]:
		var grip_path := "%s/char_vanguard_apocalypse_attack%s.png" % [str(inferno_true_grip.get("root", "")), suffix]
		_expect(ResourceLoader.exists(grip_path), "missing Inferno rear true-grip direction %s" % grip_path)

	# Third-series regression: Polar Aurora must keep a distinct runtime tree,
	# cyan-violet material, native buttons, free-weapon coatings and rear true grip.
	verified_entitlements = ["ent_theme_neon_tempest", "ent_theme_infernal_dominion", "ent_theme_polar_aurora"]
	save_manager.replace_verified_entitlements(verified_entitlements, int(Time.get_unix_time_from_system()), false)
	_expect(theme_manager.select_theme("polar_aurora"), "verified entitlement must activate Polar Aurora")
	_expect(theme_manager.active_theme_id() == "polar_aurora", "Polar Aurora must become the active theme")
	var polar_accent: Color = theme_manager.active_ui_accent(UiKit.GOLD)
	_expect(
		polar_accent.b > polar_accent.r and polar_accent.g > polar_accent.r,
		"Polar Aurora semantic UI accent must remain icy cyan rather than inherited infernal orange"
	)
	for character_id in ["char_vanguard", "char_blaze", "char_frost", "char_volt"]:
		theme_manager.select_character_outfit(character_id, "follow_theme", false)
		var polar_base: String = theme_manager.resolve_character_animation_base(character_id)
		_expect(polar_base.contains("/themes/polar_aurora/"), "Polar battle animation must use its own runtime root for %s" % character_id)
		for action_spec in [["idle", 4], ["attack", 4], ["hurt", 3]]:
			for frame_number in range(1, int(action_spec[1]) + 1):
				var frame_path := "%s_%s_%02d.png" % [polar_base, str(action_spec[0]), frame_number]
				_expect(ResourceLoader.exists(frame_path), "missing Polar Aurora rear-view runtime frame %s" % frame_path)
	var polar_aura: Array[Texture2D] = theme_manager.resolve_effect_sequence("character_fire_aura")
	_expect(polar_aura.size() == 4, "Polar Aurora firing wings must expose four rendered frames")
	for texture in polar_aura:
		_expect(texture.get_size() == Vector2(768, 768), "Polar Aurora rear fire-wing frames must be 768x768")
	for native_size: Vector2i in UiKit.NATIVE_BUTTON_SIZES:
		for kind in ["primary", "secondary"]:
			var polar_button: String = str(theme_manager.resolve_button_path(kind, native_size, kind == "secondary"))
			_expect(polar_button.contains("/themes/polar_aurora/ui/"), "missing native Polar Aurora %s button at %s" % [kind, str(native_size)])
	var polar_autocannon: String = str(theme_manager.resolve_weapon_asset("weapon_autocannon", "icon", autocannon_fallback))
	_expect(polar_autocannon.contains("/themes/polar_aurora/weapons/"), "free weapons must resolve the active Polar Aurora coating")
	var absolute_zero_weapon: Dictionary = data_loader.get_row("weapons", "weapon_apocalypse_absolute_zero")
	var absolute_zero_icon := str(absolute_zero_weapon.get("icon", ""))
	_expect(theme_manager.resolve_weapon_asset("weapon_apocalypse_absolute_zero", "icon", absolute_zero_icon) == absolute_zero_icon, "Absolute Zero identity must not be overwritten by a cosmetic coating")
	var polar_material: ShaderMaterial = theme_manager.create_character_material("vanguard")
	_expect(polar_material != null and polar_material.shader.resource_path.contains("polar_aurora_character.gdshader"), "Polar characters must use the crystalline aurora shader")
	var absolute_zero_true_grip: Dictionary = absolute_zero_weapon.get("presentation", {}).get("true_grip", {})
	_expect(str(absolute_zero_true_grip.get("viewpoint", "")) == "rear", "Absolute Zero true-grip battle art must be explicitly rear-view")
	for suffix in ["_left", "", "_right"]:
		var grip_path := "%s/char_vanguard_apocalypse_attack%s.png" % [str(absolute_zero_true_grip.get("root", "")), suffix]
		_expect(ResourceLoader.exists(grip_path), "missing Absolute Zero rear true-grip direction %s" % grip_path)

	# Fourth-series regression: Gilded Eclipse is the post-clear prestige theme.
	# It still obeys the exact same independent-outfit, native-control and
	# three-direction true-grip contracts as the earlier paid series.
	verified_entitlements = [
		"ent_theme_neon_tempest",
		"ent_theme_infernal_dominion",
		"ent_theme_polar_aurora",
		"ent_theme_gilded_eclipse",
	]
	save_manager.replace_verified_entitlements(verified_entitlements, int(Time.get_unix_time_from_system()), false)
	_expect(theme_manager.select_theme("gilded_eclipse"), "verified entitlement must activate Gilded Eclipse")
	_expect(theme_manager.active_theme_id() == "gilded_eclipse", "Gilded Eclipse must become the active theme")
	var gilded_accent: Color = theme_manager.active_ui_accent(UiKit.GOLD)
	_expect(
		gilded_accent.r > gilded_accent.b and gilded_accent.g > gilded_accent.b,
		"Gilded Eclipse semantic UI accent must remain warm gold rather than inherited Polar cyan"
	)
	for character_id in ["char_vanguard", "char_blaze", "char_frost", "char_volt"]:
		_expect(
			theme_manager.select_character_outfit(character_id, "follow_theme", false),
			"Gilded Eclipse must support Follow Global for %s" % character_id
		)
		var gilded_base: String = theme_manager.resolve_character_animation_base(character_id)
		_expect(gilded_base.contains("/themes/gilded_eclipse/"), "Gilded battle animation must use its own runtime root for %s" % character_id)
		for action_spec in [["idle", 4], ["attack", 4], ["hurt", 3]]:
			for frame_number in range(1, int(action_spec[1]) + 1):
				var frame_path := "%s_%s_%02d.png" % [gilded_base, str(action_spec[0]), frame_number]
				_expect(ResourceLoader.exists(frame_path), "missing Gilded Eclipse rear-view runtime frame %s" % frame_path)
	var gilded_aura: Array[Texture2D] = theme_manager.resolve_effect_sequence("character_fire_aura")
	_expect(gilded_aura.size() == 4, "Gilded Eclipse flowing-gold firing signature must expose four rendered frames")
	for texture in gilded_aura:
		_expect(texture.get_size() == Vector2(768, 768), "Gilded Eclipse rear firing-signature frames must be 768x768")
	for native_size: Vector2i in UiKit.NATIVE_BUTTON_SIZES:
		for kind in ["primary", "secondary"]:
			var gilded_button: String = str(theme_manager.resolve_button_path(kind, native_size, kind == "secondary"))
			_expect(gilded_button.contains("/themes/gilded_eclipse/ui/"), "missing native Gilded Eclipse %s button at %s" % [kind, str(native_size)])
	var gilded_autocannon: String = str(theme_manager.resolve_weapon_asset("weapon_autocannon", "icon", autocannon_fallback))
	_expect(gilded_autocannon.contains("/themes/gilded_eclipse/weapons/"), "free weapons must resolve the active Gilded Eclipse coating")
	var golden_law_weapon: Dictionary = data_loader.get_row("weapons", "weapon_apocalypse_golden_law")
	var golden_law_icon := str(golden_law_weapon.get("icon", ""))
	_expect(theme_manager.resolve_weapon_asset("weapon_apocalypse_golden_law", "icon", golden_law_icon) == golden_law_icon, "Golden Law identity must not be overwritten by a cosmetic coating")
	var gilded_material: ShaderMaterial = theme_manager.create_character_material("vanguard")
	_expect(gilded_material != null and gilded_material.shader.resource_path.contains("gilded_eclipse_character.gdshader"), "Gilded characters must use the flowing black-gold shader")
	var golden_law_true_grip: Dictionary = golden_law_weapon.get("presentation", {}).get("true_grip", {})
	_expect(str(golden_law_true_grip.get("viewpoint", "")) == "rear", "Golden Law true-grip battle art must be explicitly rear-view")
	for character_id in ["char_vanguard", "char_blaze", "char_frost", "char_volt"]:
		for suffix in ["_left", "", "_right"]:
			var grip_path := "%s/%s_apocalypse_attack%s.png" % [str(golden_law_true_grip.get("root", "")), character_id, suffix]
			_expect(ResourceLoader.exists(grip_path), "missing Golden Law rear true-grip direction %s" % grip_path)
		_expect(
			theme_manager.select_character_outfit(character_id, "gilded_eclipse", false),
			"Gilded Eclipse must remain explicitly selectable per hero for %s" % character_id
		)
		_expect(
			theme_manager.effective_character_theme_id(character_id) == "gilded_eclipse",
			"explicit Gilded Eclipse outfit must resolve per hero for %s" % character_id
		)

	theme_manager.select_character_outfit("volt", "neon_tempest", false)
	var no_verified_entitlements: Array[String] = []
	save_manager.replace_verified_entitlements(no_verified_entitlements, 0, false)
	purchase_manager.reconcile_access(false)
	_expect(
		theme_manager.character_outfit_mode("volt") == "follow_theme",
		"revoking a premium entitlement must safely reset explicit paid outfits"
	)
	_expect(
		theme_manager.effective_character_theme_id("volt") == "default",
		"a revoked paid outfit must resolve to the safe default presentation"
	)

	save_manager.save_data = save_snapshot
	settings_manager.settings = settings_snapshot
	if failures.is_empty():
		print("Theme manager test passed: four gated themes, independent outfits, revoke fallback, Neon/Infernal/Polar/Gilded hero frames, four-hero three-direction rear premium true-grip, rendered firing auras, native buttons, weapon coatings, and reduced VFX.")
		quit(0)
	else:
		for failure in failures:
			push_error("Theme manager test: %s" % failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
