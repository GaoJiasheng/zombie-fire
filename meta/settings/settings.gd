extends Control

const UiKit := preload("res://ui/ui_kit.gd")
const AppearanceSelector := preload("res://ui/appearance_selector.gd")
const PRIVACY_POLICY_URL := "https://blog.gavingao.cn/zombie-fire/privacy.html"
const SUPPORT_URL := "https://blog.gavingao.cn/zombie-fire/support.html"

var router: Node
var reset_armed := false
var _transparent_slider_grabber: Texture2D
var _appearance_selector: CanvasLayer
var _open_theme_on_ready := false

@onready var _vbox: VBoxContainer = $Center/Panel/Margin/VBox

func setup(main: Node, payload := {}) -> void:
	router = main
	_open_theme_on_ready = payload is Dictionary and bool(payload.get("open_theme_appearance", false))

func _ready() -> void:
	_apply_layout()
	_apply_style()
	_button("SoundButton").pressed.connect(_on_sound)
	_slider("MusicRow/Slider").value_changed.connect(_on_music_volume_changed)
	_slider("EffectsRow/Slider").value_changed.connect(_on_sfx_volume_changed)
	_slider("UiRow/Slider").value_changed.connect(_on_ui_volume_changed)
	_slider("EffectsRow/Slider").drag_ended.connect(_preview_effect_volume)
	_slider("UiRow/Slider").drag_ended.connect(_preview_ui_volume)
	_button("QualityButton").pressed.connect(_on_quality)
	_button("LanguageButton").pressed.connect(_on_language)
	_button("ThemeButton").pressed.connect(_on_theme)
	_button("AccessibilityRow/ReduceEffectsButton").pressed.connect(_on_reduce_effects)
	_button("AccessibilityRow/HapticsButton").pressed.connect(_on_haptics)
	_button("AccessibilityRow/FireRateLabButton").pressed.connect(_on_fire_rate_lab)
	_button("DataRow/BackupButton").pressed.connect(_on_backup)
	_button("DataRow/RestoreButton").pressed.connect(_on_restore)
	_button("ResetButton").pressed.connect(_on_reset)
	_button("AboutRow/HelpButton").pressed.connect(_show_info.bind("help"))
	_button("AboutRow/PrivacyButton").pressed.connect(_on_open_privacy)
	_button("AboutRow/SupportButton").pressed.connect(_on_open_support)
	_button("BackButton").pressed.connect(_on_back)
	_refresh_audio_controls()
	_refresh_quality()
	_refresh_language()
	_refresh_theme()
	_refresh_accessibility()
	_refresh_backup()
	_show_info("help")
	if _open_theme_on_ready:
		call_deferred("_open_theme_appearance")

func _apply_layout() -> void:
	$Center/Panel.custom_minimum_size = Vector2(880, 0)
	var safe := UiKit.safe_area_canvas_insets(get_viewport())
	var safe_height := get_viewport_rect().size.y - safe.y - safe.w
	var compact_safe_layout := safe_height < 1840.0
	# On shorter safe areas (large Dynamic Island + home indicator), the full
	# settings stack needs a denser authored rhythm. This keeps the whole panel
	# inside the safe rect without shrinking type or touch targets.
	_vbox.add_theme_constant_override("separation", 8 if compact_safe_layout else 14)
	var margin := $Center/Panel/Margin as MarginContainer
	# Twelve pixels keeps the complete settings stack four pixels below the
	# compact safe-area ceiling. At 16px the VBox minimum height was 1690px,
	# forcing CenterContainer to spill two pixels above and below a 1686px safe
	# rect even though its anchors were correct.
	margin.add_theme_constant_override("margin_top", 12 if compact_safe_layout else 44)
	margin.add_theme_constant_override("margin_bottom", 12 if compact_safe_layout else 44)
	for path in ["SoundButton", "QualityButton", "LanguageButton", "ThemeButton", "DataRow/BackupButton", "DataRow/RestoreButton", "ResetButton"]:
		_button(path).custom_minimum_size = Vector2(0, 88)
	for path in ["AccessibilityRow/ReduceEffectsButton", "AccessibilityRow/HapticsButton", "AccessibilityRow/FireRateLabButton", "AboutRow/HelpButton", "AboutRow/PrivacyButton", "AboutRow/SupportButton"]:
		_button(path).custom_minimum_size = Vector2(0, 80)
	var info_height := 132
	(_vbox.get_node("InfoBody") as Label).custom_minimum_size = Vector2(
		0,
		info_height if compact_safe_layout else (180 if LocalizationManager.is_english() else 136)
	)
	_button("BackButton").custom_minimum_size = Vector2(0, 96)

func _button(path: String) -> Button:
	return _vbox.get_node(path) as Button

func _slider(path: String) -> HSlider:
	return _vbox.get_node(path) as HSlider

func _apply_style() -> void:
	var panel := $Center/Panel as PanelContainer
	panel.add_theme_stylebox_override("panel", UiKit.detail_panel_texture_style())
	UiKit.apply_label(_vbox.get_node("Title") as Label, 46, UiKit.TEXT_MAIN, 4)
	for section in ["AudioSection", "VideoSection", "AccessibilitySection", "DataSection", "AboutSection"]:
		UiKit.apply_label(_vbox.get_node(section) as Label, 22, UiKit.GOLD, 2)
	for row_path in ["MusicRow", "EffectsRow", "UiRow"]:
		var row := _vbox.get_node(row_path)
		UiKit.apply_label(row.get_node("Label") as Label, 20, UiKit.TEXT_MAIN, 2)
		UiKit.apply_label(row.get_node("Value") as Label, 19, UiKit.CYAN, 2)
		_style_slider(row.get_node("Slider") as HSlider)
	UiKit.apply_label(_vbox.get_node("InfoBody") as Label, 18 if LocalizationManager.is_english() else 20, UiKit.GREY_300, 2)
	for path in ["SoundButton", "QualityButton", "LanguageButton", "ThemeButton", "AccessibilityRow/ReduceEffectsButton", "AccessibilityRow/HapticsButton", "AccessibilityRow/FireRateLabButton", "DataRow/BackupButton", "DataRow/RestoreButton", "ResetButton", "AboutRow/HelpButton", "AboutRow/PrivacyButton", "AboutRow/SupportButton"]:
		_style_button(_button(path), UiKit.CYAN, 24)
	for path in ["AccessibilityRow/ReduceEffectsButton", "AccessibilityRow/FireRateLabButton", "AboutRow/PrivacyButton", "AboutRow/SupportButton"]:
		_style_button(_button(path), UiKit.CYAN, 22)
	_style_button(_button("BackButton"), UiKit.GOLD, 28)

func _style_slider(slider: HSlider) -> void:
	var track := UiKit.texture_style(
		"res://assets/production/sprites/ui/ui_wave_progress.png",
		24.0,
		14.0,
		UiKit.CYAN
	)
	var fill := UiKit.texture_style(
		"res://assets/production/sprites/ui/ui_bar_fill_xp.png",
		20.0,
		14.0,
		UiKit.CYAN
	)
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	if _transparent_slider_grabber == null:
		var image := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		_transparent_slider_grabber = ImageTexture.create_from_image(image)
	for state in ["grabber", "grabber_highlight", "grabber_disabled"]:
		slider.add_theme_icon_override(state, _transparent_slider_grabber)

func _style_button(button: Button, accent: Color, font_size := 30) -> void:
	var button_size := Vector2(880, maxf(button.custom_minimum_size.y, 88.0))
	var parent := button.get_parent()
	if parent is HBoxContainer:
		var sibling_count := (parent as HBoxContainer).get_child_count()
		if sibling_count >= 3:
			button_size = Vector2(286, 80)
		else:
			button_size = Vector2(440, 88)
	if button.name == "BackButton":
		button_size = Vector2(880, 96)
	var primary := accent == UiKit.GOLD
	UiKit.apply_armored_button(button, primary, button_size, font_size, not button.disabled)

func _on_sound() -> void:
	SettingsManager.toggle_audio_enabled()
	_refresh_audio_controls()

func _refresh_audio_controls() -> void:
	_button("SoundButton").text = "总声音：%s" % ("开" if SettingsManager.is_audio_enabled() else "关")
	_set_slider_display("MusicRow", SettingsManager.get_bgm_volume())
	_set_slider_display("EffectsRow", SettingsManager.get_sfx_volume())
	_set_slider_display("UiRow", SettingsManager.get_ui_volume())

func _set_slider_display(row_path: String, value: float) -> void:
	var row := _vbox.get_node(row_path)
	(row.get_node("Slider") as HSlider).set_value_no_signal(roundf(value * 100.0))
	(row.get_node("Value") as Label).text = "%d%%" % int(round(value * 100.0))

func _on_music_volume_changed(value: float) -> void:
	SettingsManager.set_bgm_volume(value / 100.0)
	_set_slider_display("MusicRow", SettingsManager.get_bgm_volume())

func _on_sfx_volume_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value / 100.0)
	_set_slider_display("EffectsRow", SettingsManager.get_sfx_volume())

func _on_ui_volume_changed(value: float) -> void:
	SettingsManager.set_ui_volume(value / 100.0)
	_set_slider_display("UiRow", SettingsManager.get_ui_volume())

func _preview_effect_volume(_value_changed: bool) -> void:
	AudioManager.play_sfx("hit_physical", -3.0, 0.0)

func _preview_ui_volume(_value_changed: bool) -> void:
	AudioManager.play_sfx("ui_click", -2.0, 0.0)

func _on_quality() -> void:
	SettingsManager.cycle_quality()
	AudioManager.play_sfx("ui_click")
	_refresh_quality()

func _refresh_quality() -> void:
	_button("QualityButton").text = "画质：%s" % SettingsManager.quality_label()

func _on_language() -> void:
	AudioManager.play_sfx("ui_click")
	LocalizationManager.toggle_language()
	# Recreate the route so script-built controls, cached copy and layout all
	# start from one locale. Gameplay state is unaffected because language is a
	# device setting, not campaign progress.
	router.change_scene("settings")

func _refresh_language() -> void:
	_button("LanguageButton").text = "语言：%s" % LocalizationManager.language_label()

func _on_theme() -> void:
	_open_theme_appearance()

func _open_theme_appearance() -> void:
	if is_instance_valid(_appearance_selector):
		return
	AudioManager.play_sfx("ui_click")
	_appearance_selector = AppearanceSelector.new()
	add_child(_appearance_selector)
	_appearance_selector.global_theme_changed.connect(_on_global_theme_changed)
	_appearance_selector.store_requested.connect(_on_appearance_store_requested)
	_appearance_selector.closed.connect(func() -> void: _appearance_selector = null)
	_appearance_selector.open_global(router)

func _on_global_theme_changed(_theme_id: String) -> void:
	# Recreate Settings so every native-size button resolves against the newly
	# selected global theme atomically, then reopen the appearance page.
	router.change_scene("settings", {"open_theme_appearance": true})

func _on_appearance_store_requested() -> void:
	router.change_scene("store", {
		"return_to": "settings",
		"return_payload": {"open_theme_appearance": true},
	})

func _refresh_theme() -> void:
	var button := _button("ThemeButton")
	button.visible = true
	button.disabled = false
	button.text = LocalizationManager.text("主题与外观：%s") % ThemeManager.theme_display_name(ThemeManager.active_theme_id())
	button.tooltip_text = LocalizationManager.text("管理全局主题与每名角色的独立战衣")

func _on_reduce_effects() -> void:
	SettingsManager.toggle_reduced_effects()
	AudioManager.play_sfx("ui_click")
	_refresh_accessibility()

func _on_haptics() -> void:
	var enabled := SettingsManager.toggle_haptics()
	AudioManager.play_sfx("ui_click")
	if enabled:
		SettingsManager.pulse_haptic("light")
	_refresh_accessibility()

func _on_fire_rate_lab() -> void:
	SettingsManager.cycle_fire_rate_profile()
	AudioManager.play_sfx("ui_click")
	_refresh_accessibility()

func _refresh_accessibility() -> void:
	_button("AccessibilityRow/ReduceEffectsButton").text = "减弱闪烁震动：%s" % ("开" if SettingsManager.reduced_effects_enabled() else "关")
	_button("AccessibilityRow/HapticsButton").text = "触感反馈：%s" % ("开" if SettingsManager.haptics_enabled() else "关")
	var lab_button := _button("AccessibilityRow/FireRateLabButton")
	lab_button.visible = SettingsManager.has_fire_rate_lab()
	lab_button.text = LocalizationManager.text("攻速实验：%s") % SettingsManager.fire_rate_profile_label()

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
	var safe := UiKit.safe_area_canvas_insets(get_viewport())
	var safe_height := get_viewport_rect().size.y - safe.y - safe.w
	var regular_separation := 8 if safe_height < 1840.0 else 14
	_vbox.add_theme_constant_override("separation", mini(regular_separation, 12) if mode == "privacy" else regular_separation)
	# The privacy copy is intentionally more explicit than the controls/support
	# summaries. Give each state its authored height instead of forcing all three
	# through the short default box (which clipped both locales on device).
	match mode:
		"privacy":
			body.custom_minimum_size.y = 204.0 if LocalizationManager.is_english() else 180.0
		"support":
			body.custom_minimum_size.y = 180.0 if LocalizationManager.is_english() else 136.0
		_:
			body.custom_minimum_size.y = 180.0 if LocalizationManager.is_english() else 136.0
	match mode:
		"privacy":
			body.text = "隐私：本版本不采集个人数据，也没有广告、账号、内购、推送或第三方追踪。\n进度仅保存在本机；点击“隐私政策”查看完整政策。"
		"support":
			body.text = "支持：当前为本地离线游戏。\n如遇问题，请记录设备型号、系统版本、关卡和复现步骤；点击上方“支持”查看联系方式。"
		_:
			body.text = "操作说明：\n自动开火；按住战场拖动可手动瞄准。\n双击僵尸锁定集火，双击空地解除；长按技能查看详情。"

func _on_open_privacy() -> void:
	_show_info("privacy")
	_open_external_url(PRIVACY_POLICY_URL)

func _on_open_support() -> void:
	_show_info("support")
	_open_external_url(SUPPORT_URL)

func _open_external_url(url: String) -> void:
	var error := OS.shell_open(url)
	if error != OK:
		var body := _vbox.get_node("InfoBody") as Label
		body.text += "\n无法自动打开浏览器，请访问：%s" % url

func _on_back() -> void:
	AudioManager.play_sfx("ui_click")
	router.change_scene("menu")
