extends Control

const UiKit := preload("res://ui/ui_kit.gd")

var router: Node
var reset_armed := false

@onready var _vbox: VBoxContainer = $Center/Panel/Margin/VBox

func setup(main: Node, _payload := {}) -> void:
	router = main

func _ready() -> void:
	_apply_style()
	_button("SoundButton").pressed.connect(_on_sound)
	_button("QualityButton").pressed.connect(_on_quality)
	_button("DataRow/BackupButton").pressed.connect(_on_backup)
	_button("DataRow/RestoreButton").pressed.connect(_on_restore)
	_button("ResetButton").pressed.connect(_on_reset)
	_button("AboutRow/HelpButton").pressed.connect(_show_info.bind("help"))
	_button("AboutRow/PrivacyButton").pressed.connect(_show_info.bind("privacy"))
	_button("AboutRow/SupportButton").pressed.connect(_show_info.bind("support"))
	_button("BackButton").pressed.connect(_on_back)
	_refresh_sound()
	_refresh_quality()
	_refresh_backup()
	_show_info("help")

func _button(path: String) -> Button:
	return _vbox.get_node(path) as Button

func _apply_style() -> void:
	$Center/Panel.add_theme_stylebox_override("panel", UiKit.panel_style(UiKit.GOLD, UiKit.PANEL_BG_DARK, 3, 14))
	UiKit.apply_label(_vbox.get_node("Title") as Label, 52, UiKit.TEXT_MAIN, 4)
	for section in ["AudioSection", "VideoSection", "DataSection", "AboutSection"]:
		UiKit.apply_label(_vbox.get_node(section) as Label, 26, UiKit.GOLD, 2)
	UiKit.apply_label(_vbox.get_node("InfoBody") as Label, 24, UiKit.GREY_300, 2)
	for path in ["SoundButton", "QualityButton", "DataRow/BackupButton", "DataRow/RestoreButton", "ResetButton", "AboutRow/HelpButton", "AboutRow/PrivacyButton", "AboutRow/SupportButton"]:
		_style_button(_button(path), UiKit.CYAN)
	_style_button(_button("BackButton"), UiKit.GOLD, 34)

func _style_button(button: Button, accent: Color, font_size := 30) -> void:
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, UiKit.pill_style(accent))
	button.add_theme_color_override("font_color", UiKit.TEXT_MAIN)
	button.add_theme_color_override("font_hover_color", UiKit.TEXT_MAIN)
	button.add_theme_color_override("font_pressed_color", accent)
	button.add_theme_font_size_override("font_size", font_size)

func _on_sound() -> void:
	AudioManager.toggle_enabled()
	_refresh_sound()

func _refresh_sound() -> void:
	_button("SoundButton").text = "声音：%s" % ("开" if AudioManager.enabled else "关")

func _on_quality() -> void:
	SettingsManager.cycle_quality()
	AudioManager.play_sfx("ui_click")
	_refresh_quality()

func _refresh_quality() -> void:
	_button("QualityButton").text = "画质：%s" % SettingsManager.quality_label()

func _on_backup() -> void:
	SaveManager.backup_game()
	AudioManager.play_sfx("ui_confirm")
	_refresh_backup()
	_button("DataRow/BackupButton").text = "已备份"

func _on_restore() -> void:
	if SaveManager.restore_backup():
		AudioManager.play_sfx("ui_confirm")
		_button("DataRow/RestoreButton").text = "已恢复"
	else:
		AudioManager.play_sfx("ui_click")
		_button("DataRow/RestoreButton").text = "无备份"

func _refresh_backup() -> void:
	_button("DataRow/BackupButton").text = "备份存档"
	var has_backup: bool = SaveManager.has_backup()
	var restore := _button("DataRow/RestoreButton")
	restore.text = "恢复备份" if has_backup else "无备份"
	restore.disabled = not has_backup
	restore.modulate = Color(1, 1, 1, 1) if has_backup else Color(0.55, 0.55, 0.55, 0.85)

func _on_reset() -> void:
	if not reset_armed:
		reset_armed = true
		AudioManager.play_sfx("ui_click")
		_button("ResetButton").text = "再点确认重置"
		return
	SaveManager.reset_game()
	reset_armed = false
	AudioManager.play_sfx("ui_confirm")
	_button("ResetButton").text = "存档已重置"

func _show_info(mode: String) -> void:
	AudioManager.play_sfx("ui_click")
	var body := _vbox.get_node("InfoBody") as Label
	match mode:
		"privacy":
			body.text = "隐私：当前版本不采集个人数据，不包含广告、账号、内购、推送或第三方追踪。\n游戏进度只保存在本机，包括关卡星级、金币、经验和武器等级。"
		"support":
			body.text = "支持：当前为本地离线游戏。\n如遇问题，请记录设备型号、系统版本、关卡和复现步骤，并通过应用商店页面中的支持入口联系我们。"
		_:
			body.text = "操作说明：\n移动鼠标或触控拖动调整枪口方向；右键或双击目标锁定优先攻击。\n经验满后选择技能卡，长按卡片查看详情。局外可选择角色、武器、护甲、芯片和宠物，并用金币升级。"

func _on_back() -> void:
	AudioManager.play_sfx("ui_click")
	router.change_scene("menu")
