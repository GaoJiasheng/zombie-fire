extends Control

const UiKit := preload("res://ui/ui_kit.gd")

var router: Node

func setup(main: Node, _payload := {}) -> void:
	router = main

func _ready() -> void:
	AudioManager.play_bgm("menu")
	_apply_ui_style()
	(%StartButton as TextureButton).pressed.connect(_on_start_pressed)
	(%HelpButton as TextureButton).pressed.connect(_on_help_pressed)

func _apply_ui_style() -> void:
	UiKit.apply_label(%Title, 118, UiKit.TEXT_MAIN, 7)
	UiKit.apply_label(%Subtitle, 34, UiKit.GOLD, 4)
	(%StartButton as TextureButton).modulate = Color(1.0, 0.86, 0.54, 1.0)
	(%HelpButton as TextureButton).modulate = Color(0.82, 0.86, 0.86, 1.0)
	UiKit.apply_label((%StartButton as Control).get_node("Label"), 44, UiKit.TEXT_MAIN, 3)
	UiKit.apply_label((%HelpButton as Control).get_node("Label"), 40, UiKit.TEXT_MAIN, 3)

func _on_start_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	router.change_scene("map")

func _on_help_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	router.change_scene("settings")
