extends Control

var router: Node
var reset_armed := false
var info_mode := "help"

func setup(main: Node, _payload := {}) -> void:
	router = main

func _ready() -> void:
	AudioManager.play_bgm("menu")
	$StartButton.pressed.connect(_on_start_pressed)
	$HelpButton.pressed.connect(_on_help_pressed)
	$HelpOverlay/Panel/CloseButton.pressed.connect(_on_help_close_pressed)
	$HelpOverlay/Panel/SoundButton.pressed.connect(_on_sound_pressed)
	$HelpOverlay/Panel/QualityButton.pressed.connect(_on_quality_pressed)
	$HelpOverlay/Panel/ResetButton.pressed.connect(_on_reset_pressed)
	$HelpOverlay/Panel/BackupButton.pressed.connect(_on_backup_pressed)
	$HelpOverlay/Panel/RestoreButton.pressed.connect(_on_restore_pressed)
	$HelpOverlay/Panel/PrivacyButton.pressed.connect(_on_privacy_pressed)
	$HelpOverlay/Panel/SupportButton.pressed.connect(_on_support_pressed)

func _on_start_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	router.change_scene("map")

func _on_help_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	info_mode = "help"
	_refresh_info_body()
	_refresh_sound_label()
	_refresh_quality_label()
	_refresh_backup_buttons()
	$HelpOverlay.visible = true

func _on_help_close_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	$HelpOverlay.visible = false
	reset_armed = false
	$HelpOverlay/Panel/ResetButton/Label.text = "重置存档"

func _on_sound_pressed() -> void:
	AudioManager.toggle_enabled()
	_refresh_sound_label()

func _refresh_sound_label() -> void:
	$HelpOverlay/Panel/SoundButton/Label.text = "声音：%s" % ("开" if AudioManager.enabled else "关")

func _on_quality_pressed() -> void:
	SettingsManager.cycle_quality()
	AudioManager.play_sfx("ui_click")
	_refresh_quality_label()

func _refresh_quality_label() -> void:
	$HelpOverlay/Panel/QualityButton/Label.text = "画质：%s" % SettingsManager.quality_label()

func _on_backup_pressed() -> void:
	SaveManager.backup_game()
	AudioManager.play_sfx("ui_confirm")
	_refresh_backup_buttons()
	$HelpOverlay/Panel/BackupButton/Label.text = "已备份"

func _on_restore_pressed() -> void:
	if SaveManager.restore_backup():
		AudioManager.play_sfx("ui_confirm")
		$HelpOverlay/Panel/RestoreButton/Label.text = "已恢复"
	else:
		AudioManager.play_sfx("ui_click")
		$HelpOverlay/Panel/RestoreButton/Label.text = "无备份"

func _refresh_backup_buttons() -> void:
	$HelpOverlay/Panel/BackupButton/Label.text = "备份存档"
	$HelpOverlay/Panel/RestoreButton/Label.text = "恢复备份" if SaveManager.has_backup() else "无备份"
	$HelpOverlay/Panel/RestoreButton.disabled = not SaveManager.has_backup()
	$HelpOverlay/Panel/RestoreButton.modulate = Color(1, 1, 1, 1) if SaveManager.has_backup() else Color(0.55, 0.55, 0.55, 0.85)

func _on_privacy_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	info_mode = "privacy"
	_refresh_info_body()

func _on_support_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	info_mode = "support"
	_refresh_info_body()

func _refresh_info_body() -> void:
	match info_mode:
		"privacy":
			$HelpOverlay/Panel/Title.text = "隐私"
			$HelpOverlay/Panel/Body.text = "当前版本不采集个人数据，不包含广告、账号、内购、推送或第三方追踪。\\n\\n游戏进度只保存在本机，包括关卡星级、金币、经验和武器等级。"
		"support":
			$HelpOverlay/Panel/Title.text = "支持"
			$HelpOverlay/Panel/Body.text = "当前为本地离线游戏。\\n\\n如遇问题，请记录设备型号、系统版本、关卡和复现步骤，并通过 App Store 页面中的支持入口联系我们。"
		_:
			$HelpOverlay/Panel/Title.text = "操作说明"
			$HelpOverlay/Panel/Body.text = "移动鼠标或触控拖动：调整炮口方向\\n右键或双击目标：锁定优先攻击\\nTab/策略按钮：切换目标优先级\\nXP 满后选择技能卡；长按卡片查看详细说明\\n局外可选择角色、武器、护甲、芯片和宠物，并用金币升级武器"

func _on_reset_pressed() -> void:
	if not reset_armed:
		reset_armed = true
		AudioManager.play_sfx("ui_click")
		$HelpOverlay/Panel/ResetButton/Label.text = "再点确认重置"
		return
	SaveManager.reset_game()
	reset_armed = false
	AudioManager.play_sfx("ui_confirm")
	$HelpOverlay/Panel/ResetButton/Label.text = "存档已重置"
