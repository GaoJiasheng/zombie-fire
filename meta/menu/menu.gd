extends Control

const UiKit := preload("res://ui/ui_kit.gd")
const MENU_TITLE_LOGO_PATH := "res://assets/production/sprites/ui/ui_menu_title_shichao_fangxian.png"
const MENU_SUBTITLE := "火力封锁，寸土不让"

var router: Node

func setup(main: Node, _payload := {}) -> void:
	router = main

func _ready() -> void:
	AudioManager.play_bgm("menu")
	_apply_ui_style()
	(%StartButton as TextureButton).pressed.connect(_on_start_pressed)
	(%HelpButton as TextureButton).pressed.connect(_on_help_pressed)

func _apply_ui_style() -> void:
	var title := %Title as TextureRect
	title.texture = load(MENU_TITLE_LOGO_PATH)
	title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title.custom_minimum_size = Vector2(1040, 340)
	(%Subtitle as Label).text = MENU_SUBTITLE
	UiKit.apply_label(%Subtitle, 34, UiKit.GOLD, 4)
	UiKit.apply_armored_texture_button(%StartButton as TextureButton, true, Vector2(600, 120), true)
	UiKit.apply_armored_texture_button(%HelpButton as TextureButton, false, Vector2(600, 120), true)
	UiKit.apply_label((%StartButton as Control).get_node("Label"), 44, UiKit.TEXT_MAIN, 3)
	UiKit.apply_label((%HelpButton as Control).get_node("Label"), 40, UiKit.TEXT_MAIN, 3)

func _on_start_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	router.change_scene("map")

func _on_help_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	router.change_scene("settings")
