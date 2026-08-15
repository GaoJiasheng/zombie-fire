extends Control

const UiKit := preload("res://ui/ui_kit.gd")
const MENU_TITLE_KEY_SHADER := preload("res://meta/menu/menu_title_key.gdshader")
const MENU_TITLE_LOGO_PATH := "res://assets/production/sprites/ui/ui_menu_title_shichao_fangxian.png"
const MENU_TITLE_LOGO_EN_PATH := "res://assets/production/sprites/ui/ui_menu_title_zombie_fire.png"
const MENU_SUBTITLE := "火力封锁，寸土不让"
const MENU_TITLE_PRESENTATION_SIZE := Vector2(1040, 560)
const MENU_TITLE_ALPHA_PADDING_RATIO := 0.025

var router: Node

func setup(main: Node, _payload := {}) -> void:
	router = main

func _ready() -> void:
	AudioManager.play_bgm("menu")
	_apply_ui_style()
	(%StartButton as TextureButton).pressed.connect(_on_start_pressed)
	(%StoreButton as TextureButton).pressed.connect(_on_store_pressed)
	(%HelpButton as TextureButton).pressed.connect(_on_help_pressed)
	if not PurchaseManager.commerce_changed.is_connected(_refresh_store_visibility):
		PurchaseManager.commerce_changed.connect(_refresh_store_visibility)

func _apply_ui_style() -> void:
	var title := %Title as TextureRect
	var fallback_title := MENU_TITLE_LOGO_EN_PATH if LocalizationManager.is_english() else MENU_TITLE_LOGO_PATH
	var title_path := ThemeManager.resolve_ui_asset("menu_title", fallback_title)
	var title_presentation := ThemeManager.active_ui_asset_presentation("menu_title")
	title.texture = _visible_logo_texture(load(title_path) as Texture2D, title_presentation)
	title.material = _logo_key_material(title_presentation)
	title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title.custom_minimum_size = MENU_TITLE_PRESENTATION_SIZE
	(%Subtitle as Label).text = MENU_SUBTITLE
	var theme_accent := ThemeManager.active_ui_accent(UiKit.GOLD)
	UiKit.apply_label(%Subtitle, 34, theme_accent, 4)
	UiKit.apply_armored_texture_button(%StartButton as TextureButton, true, Vector2(600, 120), true)
	UiKit.apply_armored_texture_button(%StoreButton as TextureButton, false, Vector2(600, 120), true)
	UiKit.apply_armored_texture_button(%HelpButton as TextureButton, false, Vector2(600, 120), true)
	UiKit.apply_label((%StartButton as Control).get_node("Label"), 44, UiKit.TEXT_MAIN, 3)
	UiKit.apply_label((%StoreButton as Control).get_node("Label"), 38, theme_accent, 3)
	UiKit.apply_label((%HelpButton as Control).get_node("Label"), 40, UiKit.TEXT_MAIN, 3)
	(%StartButton as Control).get_node("Label").text = LocalizationManager.text("开始")
	(%StoreButton as Control).get_node("Label").text = LocalizationManager.text("终焉军械库")
	# Do not advertise the premium catalog before its first campaign reveal.
	# Owned non-consumables remain visible through PurchaseManager's ownership gate.
	_refresh_store_visibility()
	(%HelpButton as Control).get_node("Label").text = LocalizationManager.text("设置")


func _refresh_store_visibility() -> void:
	(%StoreButton as Control).visible = not PurchaseManager.store_series_ids().is_empty()

func _visible_logo_texture(source: Texture2D, presentation := {}) -> Texture2D:
	if source == null:
		return null
	var image := source.get_image()
	if image == null or image.is_empty():
		return source
	var used := image.get_used_rect()
	var authored_region: Variant = presentation.get("region", [])
	if authored_region is Array and authored_region.size() >= 4:
		used = Rect2i(
			int(authored_region[0]),
			int(authored_region[1]),
			int(authored_region[2]),
			int(authored_region[3])
		).intersection(Rect2i(0, 0, image.get_width(), image.get_height()))
	if used.size.x <= 0 or used.size.y <= 0:
		return source
	# Theme title masters deliberately keep generous transparent staging space.
	# Crop that space at presentation time so KEEP_ASPECT measures the authored
	# logo itself, while retaining a small glow-safe gutter on every side.
	var use_authored_region: bool = authored_region is Array and authored_region.size() >= 4
	var pad_x := 0 if use_authored_region else maxi(8, int(round(float(used.size.x) * MENU_TITLE_ALPHA_PADDING_RATIO)))
	var pad_y := 0 if use_authored_region else maxi(8, int(round(float(used.size.y) * MENU_TITLE_ALPHA_PADDING_RATIO)))
	var left := maxi(0, used.position.x - pad_x)
	var top := maxi(0, used.position.y - pad_y)
	var right := mini(image.get_width(), used.end.x + pad_x)
	var bottom := mini(image.get_height(), used.end.y + pad_y)
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(left, top, right - left, bottom - top)
	return atlas

func _logo_key_material(presentation: Dictionary) -> ShaderMaterial:
	var threshold := float(presentation.get("dark_key_threshold", 0.0))
	if threshold <= 0.0:
		return null
	var material := ShaderMaterial.new()
	material.shader = MENU_TITLE_KEY_SHADER
	material.set_shader_parameter("dark_key_threshold", threshold)
	material.set_shader_parameter("dark_key_softness", maxf(0.01, float(presentation.get("dark_key_softness", 0.06))))
	return material

func _on_start_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	router.change_scene("map")

func _on_store_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	router.change_scene("store")

func _on_help_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	router.change_scene("settings")
