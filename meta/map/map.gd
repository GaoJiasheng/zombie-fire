extends Control

const UiKit := preload("res://ui/ui_kit.gd")
const BUTTON_PRIMARY := "res://assets/production/sprites/ui/ui_button_primary.png"
const BUTTON_SECONDARY := "res://assets/production/sprites/ui/ui_button_secondary.png"
const RESOURCE_POWER_ICON := "res://assets/production/sprites/ui/icon_talent_point.png"
const RESOURCE_TIP_DURATION := 1.8
const LEVEL_CARD_HEIGHT := 150.0
const LEVEL_RIGHT_X := 532.0
const LEVEL_RIGHT_W := 338.0
const LEVEL_BUTTON_Y := 98.0
const LEVEL_BUTTON_H := 44.0
const CHAPTER_CARD_HEIGHT := 282.0
const CHAPTER_HERO_HEIGHT := 256.0

var router: Node
var resource_tip_tween: Tween = null
var selected_chapter := 0

func setup(main: Node, payload := {}) -> void:
	router = main
	if payload is Dictionary:
		selected_chapter = int(payload.get("chapter", 0))

func _ready() -> void:
	AudioManager.play_bgm("map")
	_apply_map_style()
	SaveManager.repair_progression_unlocks()
	_refresh_header()
	_build_nav()
	_build_levels()
	_ensure_endless_button()

# 无限尸潮入口：复用玩家当前解锁到的最高一关作为难度种子，波次打完循环继续、每轮血量递增，
# 直到漏怪耗尽基地生命结束。奖励按撑过的轮数发放(不影响正常关卡进度/解锁)。
func _ensure_endless_button() -> void:
	if get_node_or_null("Root/VBox/EndlessButton") != null:
		return
	var vbox := $Root/VBox as VBoxContainer
	var wrap := get_node_or_null("Root/VBox/ResourceBarWrap") as Control
	var btn := TextureButton.new()
	btn.name = "EndlessButton"
	btn.texture_normal = load("res://assets/production/sprites/ui/ui_button_secondary.png")
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_SCALE
	btn.custom_minimum_size = Vector2(0, 58)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var best := SaveManager.get_endless_best_loops()
	var label := Label.new()
	label.name = "Label"
	label.text = "无限尸潮" if best <= 0 else "无限尸潮 · 最佳 %d 轮" % best
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.apply_label(label, 20, Color(1.0, 0.82, 0.5, 1.0), 3)
	btn.add_child(label)
	btn.pressed.connect(_on_endless_pressed)
	vbox.add_child(btn)
	if wrap != null:
		vbox.move_child(btn, wrap.get_index() + 1)

func _on_endless_pressed() -> void:
	AudioManager.play_sfx("ui_confirm")
	router.start_endless_level(SaveManager.get_highest_unlocked_level_id())

func _apply_map_style() -> void:
	var bg := get_node_or_null("Background") as TextureRect
	if bg != null:
		bg.modulate = Color(0.42, 0.39, 0.34, 1.0)
	UiKit.apply_label(%Title, 44, UiKit.TEXT_MAIN, 5)
	(%Nav as HBoxContainer).custom_minimum_size = Vector2(0, 118)
	(%Progress as Label).visible = false
	_ensure_resource_bar()

func _refresh_header() -> void:
	var total_stars: int = DataLoader.get_table("levels").size() * 6
	var progress := %Progress as Label
	progress.visible = false
	progress.text = "%d  %d/%d  %d" % [SaveManager.get_player_gold(), SaveManager.get_total_stars(), total_stars, SaveManager.get_loadout_power()]
	var row := _ensure_resource_bar().get_node("Row") as HBoxContainer
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	# 统一用 UiKit 共享资源条(金币/星星/经验/战力),与出战配置、收藏页一致。
	var bar := UiKit.standard_resource_bar(
		SaveManager.get_player_gold(),
		SaveManager.get_player_star(),
		SaveManager.get_player_xp(),
		SaveManager.get_loadout_power(),
		Vector2(174, 56),
		26
	)
	for chip in bar.get_children():
		bar.remove_child(chip)
		row.add_child(chip)
	bar.free()

func _ensure_resource_bar() -> VBoxContainer:
	var existing := get_node_or_null("Root/VBox/ResourceBarWrap") as VBoxContainer
	if existing != null:
		return existing

	var vbox := $Root/VBox as VBoxContainer
	var wrap := VBoxContainer.new()
	wrap.name = "ResourceBarWrap"
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.add_theme_constant_override("separation", 6)
	vbox.add_child(wrap)
	vbox.move_child(wrap, (%Progress as Label).get_index() + 1)

	var row := HBoxContainer.new()
	row.name = "Row"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	wrap.add_child(row)

	var tip := PanelContainer.new()
	tip.name = "ResourceTooltip"
	tip.visible = false
	tip.custom_minimum_size = Vector2(520, 42)
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.add_theme_stylebox_override("panel", _resource_tip_style(UiKit.GOLD))
	wrap.add_child(tip)

	var tip_label := Label.new()
	tip_label.name = "Text"
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit.apply_label(tip_label, 18, UiKit.TEXT_MAIN, 2)
	tip.add_child(tip_label)
	return wrap

func _make_resource_chip(title: String, icon_path: String, accent: Color, value: String, tip: String) -> Button:
	var button := Button.new()
	button.name = _resource_chip_name(title)
	button.text = ""
	button.custom_minimum_size = Vector2(168, 52)
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = "%s：%s" % [title, tip]
	button.add_theme_stylebox_override("normal", _resource_chip_style(accent, false, false))
	button.add_theme_stylebox_override("hover", _resource_chip_style(accent, true, false))
	button.add_theme_stylebox_override("pressed", _resource_chip_style(accent, true, true))
	button.add_theme_stylebox_override("disabled", _resource_chip_style(accent, false, false))
	button.pressed.connect(_show_resource_tip.bind(title, tip, accent))

	var content := HBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 14
	content.offset_top = 6
	content.offset_right = -14
	content.offset_bottom = -6
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 9)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)

	var icon := UiKit.icon(icon_path, Vector2(34, 34))
	icon.modulate = Color(1.06, 1.02, 0.92, 1.0)
	content.add_child(icon)

	var label := UiKit.label(value, 26, UiKit.TEXT_MAIN, 3)
	label.name = "Value"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(label)
	return button

func _resource_chip_name(title: String) -> String:
	match title:
		"金币":
			return "GoldResourceChip"
		"星星":
			return "StarResourceChip"
		"战力":
			return "PowerResourceChip"
		_:
			return "ResourceChip"

func _resource_chip_style(_accent: Color, _hovered: bool, _pressed: bool) -> StyleBox:
	return UiKit.resource_chip_texture_style()

func _resource_tip_style(_accent: Color) -> StyleBox:
	return UiKit.hint_texture_style(false)

func _show_resource_tip(title: String, tip: String, accent: Color) -> void:
	AudioManager.play_sfx("ui_click", -8.0)
	var panel := get_node_or_null("Root/VBox/ResourceBarWrap/ResourceTooltip") as PanelContainer
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", _resource_tip_style(accent))
	var label := panel.get_node_or_null("Text") as Label
	if label != null:
		label.text = "%s：%s" % [title, tip]
		UiKit.apply_label(label, 18, UiKit.TEXT_MAIN, 2)
	panel.visible = true
	panel.modulate = Color(1, 1, 1, 1)
	if resource_tip_tween != null and resource_tip_tween.is_valid():
		resource_tip_tween.kill()
	resource_tip_tween = panel.create_tween()
	resource_tip_tween.tween_interval(RESOURCE_TIP_DURATION)
	resource_tip_tween.tween_property(panel, "modulate:a", 0.0, 0.18)
	resource_tip_tween.tween_callback(func() -> void:
		if is_instance_valid(panel):
			panel.visible = false
			panel.modulate.a = 1.0
	)

func _build_levels() -> void:
	var level_list := %LevelList as VBoxContainer
	for child in level_list.get_children():
		child.queue_free()
	var chapters := _chapter_groups()
	if selected_chapter > 0:
		var current := _chapter_by_index(chapters, selected_chapter)
		if not current.is_empty():
			_build_chapter_levels(level_list, current)
			return
	selected_chapter = 0
	(%Title as Label).text = "战区地图"
	for chapter in chapters:
		level_list.add_child(_build_chapter_card(chapter))

func _build_chapter_levels(level_list: VBoxContainer, chapter: Dictionary) -> void:
	var env := _chapter_env(chapter)
	var chapter_id := int(chapter.get("chapter", 1))
	var title := str(env.get("chapter_title", "第%02d战区 · %s" % [chapter_id, env.get("name", "未知战区")]))
	(%Title as Label).text = title
	level_list.add_child(_build_chapter_header(chapter))
	for level in chapter.get("levels", []):
		var level_id: String = level.get("id", "level_001")
		var unlocked := SaveManager.is_level_unlocked(level_id)
		var stars := SaveManager.get_level_stars(level_id)
		var challenge_stars := SaveManager.get_challenge_stars(level_id)
		level_list.add_child(_build_level_card(level_id, level, unlocked, stars, challenge_stars))

func _chapter_groups() -> Array:
	var groups := {}
	var order: Array[int] = []
	var levels: Array = DataLoader.get_table("levels")
	for level in levels:
		var chapter := int(level.get("chapter", _chapter_from_level_id(str(level.get("id", "level_001")))))
		if not groups.has(chapter):
			groups[chapter] = {"chapter": chapter, "env": str(level.get("env", "")), "levels": []}
			order.append(chapter)
		var group: Dictionary = groups[chapter]
		var chapter_levels: Array = group.get("levels", [])
		chapter_levels.append(level)
		group["levels"] = chapter_levels
		if str(group.get("env", "")) == "":
			group["env"] = str(level.get("env", ""))
		groups[chapter] = group
	order.sort()
	var result: Array = []
	for chapter in order:
		result.append(groups[chapter])
	return result

func _chapter_by_index(chapters: Array, chapter_id: int) -> Dictionary:
	for chapter in chapters:
		if int(chapter.get("chapter", 0)) == chapter_id:
			return chapter
	return {}

func _chapter_from_level_id(level_id: String) -> int:
	var number := int(DataLoader.level_number(level_id))
	return int(floor(float(max(number - 1, 0)) / 10.0)) + 1

func _chapter_env(chapter: Dictionary) -> Dictionary:
	return DataLoader.get_row("environments", str(chapter.get("env", "")))

func _chapter_unlocked(chapter: Dictionary) -> bool:
	var levels: Array = chapter.get("levels", [])
	if levels.is_empty():
		return false
	return SaveManager.is_level_unlocked(str((levels[0] as Dictionary).get("id", "")))

func _chapter_completed(chapter: Dictionary) -> bool:
	var levels: Array = chapter.get("levels", [])
	if levels.is_empty():
		return false
	var last: Dictionary = levels[levels.size() - 1]
	return SaveManager.get_level_stars(str(last.get("id", ""))) > 0

func _chapter_star_count(chapter: Dictionary) -> int:
	var total := 0
	for level in chapter.get("levels", []):
		var level_id := str((level as Dictionary).get("id", ""))
		total += SaveManager.get_level_stars(level_id)
		total += SaveManager.get_challenge_stars(level_id)
	return total

func _chapter_total_stars(chapter: Dictionary) -> int:
	return int((chapter.get("levels", []) as Array).size()) * 6

func _chapter_cleared_count(chapter: Dictionary) -> int:
	var count := 0
	for level in chapter.get("levels", []):
		if SaveManager.get_level_stars(str((level as Dictionary).get("id", ""))) > 0:
			count += 1
	return count

func _chapter_range_text(chapter: Dictionary) -> String:
	var levels: Array = chapter.get("levels", [])
	if levels.is_empty():
		return "---"
	var first := DataLoader.level_number(str((levels[0] as Dictionary).get("id", "")))
	var last := DataLoader.level_number(str((levels[levels.size() - 1] as Dictionary).get("id", "")))
	return "%s-%s" % [first, last]

func _chapter_status_text(chapter: Dictionary) -> String:
	if not _chapter_unlocked(chapter):
		return "未展开"
	if _chapter_completed(chapter):
		return "已肃清"
	return "作战中"

func _chapter_accent(chapter: Dictionary) -> Color:
	var levels: Array = chapter.get("levels", [])
	for level in levels:
		var weakness := str((level as Dictionary).get("primary_weakness", ""))
		if weakness != "":
			return UiKit.element_color(weakness)
	return UiKit.CYAN

func _chapter_boss_level(chapter: Dictionary, major := false) -> Dictionary:
	var levels: Array = chapter.get("levels", [])
	var fallback: Dictionary = {}
	for level in levels:
		var level_row := level as Dictionary
		var level_id := str(level_row.get("id", ""))
		var number := int(DataLoader.level_number(level_id))
		var variant := str(level_row.get("variant", "normal"))
		if variant in ["boss", "boss_rush"]:
			fallback = level_row
			if major and (number % 10 == 0 or variant == "boss_rush" or level_row == levels[levels.size() - 1]):
				return level_row
			if not major and number % 10 == 5:
				return level_row
	return fallback

func _chapter_next_lock_text(chapter: Dictionary) -> String:
	var chapter_id := int(chapter.get("chapter", 1))
	if chapter_id <= 1:
		return "默认展开"
	return "肃清第%02d战区后展开" % (chapter_id - 1)

func _wrap_chapter_text(text: String, max_chars := 24) -> String:
	var source := text.strip_edges()
	var lines: Array[String] = []
	var line := ""
	for i in range(source.length()):
		var ch := source.substr(i, 1)
		if ch == "\n":
			if line.strip_edges() != "":
				lines.append(line.strip_edges())
			line = ""
			continue
		line += ch
		var soft_break := ch in ["，", "。", "；", "、"] and line.length() >= maxi(12, max_chars - 7)
		if line.length() >= max_chars or soft_break:
			lines.append(line.strip_edges())
			line = ""
	if line.strip_edges() != "":
		lines.append(line.strip_edges())
	return "\n".join(lines)

func _build_chapter_card(chapter: Dictionary) -> TextureButton:
	var chapter_id := int(chapter.get("chapter", 1))
	var env := _chapter_env(chapter)
	var unlocked := _chapter_unlocked(chapter)
	var accent := _chapter_accent(chapter)
	var button := TextureButton.new()
	button.name = "Chapter%02dCard" % chapter_id
	button.custom_minimum_size = Vector2(0, CHAPTER_CARD_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.texture_normal = load("res://assets/production/sprites/ui/ui_map_level_card_skin.png")
	button.texture_hover = button.texture_normal
	button.texture_pressed = button.texture_normal
	button.texture_disabled = button.texture_normal
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.clip_contents = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.modulate = Color.WHITE if unlocked else Color(0.52, 0.55, 0.58, 0.78)
	if unlocked:
		button.pressed.connect(_open_chapter.bind(chapter_id))

	_add_chapter_art(button, str(env.get("portrait", "")), unlocked)
	_add_chapter_frame(button, accent, unlocked)

	var title := UiKit.label(str(env.get("chapter_title", "第%02d战区 · %s" % [chapter_id, env.get("name", "未知战区")])), 24, UiKit.TEXT_MAIN if unlocked else UiKit.TEXT_MUTED, 4)
	title.name = "ChapterTitle"
	title.position = Vector2(36, 26)
	title.size = Vector2(560, 46)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_child(title)

	var range := UiKit.label("关卡 %s" % _chapter_range_text(chapter), 14, accent if unlocked else UiKit.TEXT_MUTED, 2)
	range.name = "ChapterRange"
	range.position = Vector2(38, 76)
	range.size = Vector2(190, 28)
	button.add_child(range)

	_add_chapter_status_pill(button, Vector2(218, 75), _chapter_status_text(chapter), accent if unlocked else UiKit.TEXT_MUTED)

	var story := UiKit.label(_wrap_chapter_text(str(env.get("story", "沿主防线推进，夺回下一个沦陷战区。")), 24), 15, UiKit.TEXT_MAIN if unlocked else UiKit.TEXT_MUTED, 2)
	story.name = "ChapterStory"
	story.position = Vector2(36, 110)
	story.size = Vector2(526, 72)
	story.autowrap_mode = TextServer.AUTOWRAP_OFF
	story.clip_text = true
	story.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	button.add_child(story)

	var objective := UiKit.label(_wrap_chapter_text(str(env.get("objective", "突破尸潮封锁，击破本战区大首领。")), 31), 13, UiKit.TEXT_MUTED, 2)
	objective.name = "ChapterObjective"
	objective.position = Vector2(36, 184)
	objective.size = Vector2(520, 38)
	objective.autowrap_mode = TextServer.AUTOWRAP_OFF
	objective.clip_text = true
	button.add_child(objective)

	_add_chapter_progress(button, chapter, Vector2(590, 28), unlocked, accent)
	var small_boss := _chapter_boss_level(chapter, false)
	var major_boss := _chapter_boss_level(chapter, true)
	_add_chapter_boss_node(button, Vector2(596, 154), small_boss, "小首领", false, unlocked)
	_add_chapter_boss_node(button, Vector2(742, 154), major_boss, "大首领", true, unlocked)

	var action_label := "进入战区" if unlocked else _chapter_next_lock_text(chapter)
	_add_chapter_action_button(button, Vector2(604, 218), Vector2(270, 46), action_label, unlocked, _open_chapter.bind(chapter_id), "EnterChapterButton")
	return button

func _add_chapter_art(parent: Control, portrait_path: String, unlocked: bool) -> void:
	if portrait_path == "" or not ResourceLoader.exists(portrait_path):
		return
	var art := TextureRect.new()
	art.name = "ChapterArt"
	art.texture = load(portrait_path)
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.modulate = Color(0.72, 0.76, 0.76, 0.70) if unlocked else Color(0.40, 0.42, 0.44, 0.56)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)

	var dim := TextureRect.new()
	dim.name = "ChapterReadabilityVeil"
	dim.texture = load("res://assets/production/sprites/ui/ui_panel_skin.png")
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dim.stretch_mode = TextureRect.STRETCH_SCALE
	dim.modulate = Color(0.0, 0.0, 0.0, 0.58 if unlocked else 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(dim)

func _add_chapter_frame(parent: Control, accent: Color, unlocked: bool) -> void:
	var frame := PanelContainer.new()
	frame.name = "ChapterFrame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_stylebox_override("panel", UiKit.map_level_card_texture_style(not unlocked))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(frame)
	var rail := TextureRect.new()
	rail.name = "ChapterRouteRail"
	rail.texture = load("res://assets/production/sprites/ui/ui_map_accent_strip.png")
	rail.position = Vector2(20, 28)
	rail.size = Vector2(14, CHAPTER_CARD_HEIGHT - 56)
	rail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rail.stretch_mode = TextureRect.STRETCH_SCALE
	rail.modulate = Color(accent.r, accent.g, accent.b, 0.95 if unlocked else 0.35)
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rail)

func _add_chapter_status_pill(parent: Control, pos: Vector2, text: String, accent: Color) -> void:
	var pill := PanelContainer.new()
	pill.name = "ChapterStatus"
	pill.position = pos
	pill.size = Vector2(110, 32)
	pill.add_theme_stylebox_override("panel", UiKit.map_pill_texture_style())
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pill)
	var label := UiKit.label(text, 13, accent, 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.add_child(label)

func _add_chapter_progress(parent: Control, chapter: Dictionary, pos: Vector2, unlocked: bool, accent: Color) -> void:
	var panel := Control.new()
	panel.name = "ChapterProgress"
	panel.position = pos
	panel.size = Vector2(282, 104)
	panel.clip_contents = true
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)

	var skin := TextureRect.new()
	skin.name = "ProgressSkin"
	skin.texture = load("res://assets/production/sprites/ui/ui_panel_skin.png")
	skin.set_anchors_preset(Control.PRESET_FULL_RECT)
	skin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skin.stretch_mode = TextureRect.STRETCH_SCALE
	skin.modulate = Color(0.84, 0.95, 1.0, 0.82 if unlocked else 0.42)
	skin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(skin)

	var title := UiKit.label("战区进度", 13, accent if unlocked else UiKit.TEXT_MUTED, 2)
	title.position = Vector2(18, 10)
	title.size = Vector2(120, 26)
	panel.add_child(title)
	var count := _chapter_cleared_count(chapter)
	var total_levels := int((chapter.get("levels", []) as Array).size())
	var stars := _chapter_star_count(chapter)
	var star_total := _chapter_total_stars(chapter)
	var value := UiKit.label("%d/%d  %d/%d★" % [count, total_levels, stars, star_total], 18, UiKit.TEXT_MAIN if unlocked else UiKit.TEXT_MUTED, 3)
	value.name = "ChapterProgressValue"
	value.position = Vector2(18, 38)
	value.size = Vector2(230, 36)
	panel.add_child(value)
	_add_progress_micro_bar(panel, Vector2(18, 78), Vector2(236, 14), float(count) / maxf(float(total_levels), 1.0), accent, unlocked)

func _add_progress_micro_bar(parent: Control, pos: Vector2, size: Vector2, ratio: float, accent: Color, enabled: bool) -> void:
	var bar := TextureProgressBar.new()
	bar.name = "ProgressBar"
	bar.position = pos
	bar.size = size
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = clampf(ratio, 0.0, 1.0)
	bar.texture_under = load("res://assets/production/sprites/ui/ui_run_xp_bar.png")
	bar.texture_progress = load("res://assets/production/sprites/ui/ui_bar_fill_wave.png")
	bar.nine_patch_stretch = true
	bar.stretch_margin_left = 32
	bar.stretch_margin_top = 12
	bar.stretch_margin_right = 32
	bar.stretch_margin_bottom = 12
	bar.custom_minimum_size = size
	bar.size = size
	bar.tint_under = Color(0.20, 0.23, 0.25, 0.62)
	bar.tint_progress = Color(accent.r, accent.g, accent.b, 0.95 if enabled else 0.38)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bar)

func _add_chapter_boss_node(parent: Control, pos: Vector2, level: Dictionary, label_text: String, major: bool, unlocked: bool) -> void:
	var panel := Control.new()
	panel.name = "MajorBossNode" if major else "SmallBossNode"
	panel.position = pos
	panel.size = Vector2(126, 48)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	var skin := TextureRect.new()
	skin.texture = load("res://assets/production/sprites/ui/ui_map_pill_skin.png")
	skin.set_anchors_preset(Control.PRESET_FULL_RECT)
	skin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skin.stretch_mode = TextureRect.STRETCH_SCALE
	skin.modulate = Color(0.86, 0.96, 1.0, 0.92 if unlocked else 0.36)
	skin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(skin)
	var level_id := str(level.get("id", ""))
	var number := DataLoader.level_number(level_id)
	var cleared := SaveManager.get_level_stars(level_id) > 0
	var accent := UiKit.DANGER if major else UiKit.WARNING
	var text := UiKit.label("%s  %s" % [number, label_text], 12, accent if unlocked else UiKit.TEXT_MUTED, 2)
	text.position = Vector2(8, 2)
	text.size = Vector2(110, 22)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(text)
	var state := UiKit.label("已击破" if cleared else ("待挑战" if unlocked else "未展开"), 10, UiKit.TEXT_MAIN if cleared else UiKit.TEXT_MUTED, 1)
	state.position = Vector2(8, 24)
	state.size = Vector2(110, 18)
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(state)

func _add_chapter_action_button(parent: Control, pos: Vector2, size: Vector2, text: String, enabled: bool, callback: Callable, node_name: String) -> void:
	var action := TextureButton.new()
	action.name = node_name
	action.position = pos
	action.size = size
	action.custom_minimum_size = size
	var tex := load(BUTTON_PRIMARY if enabled else BUTTON_SECONDARY)
	action.texture_normal = tex
	action.texture_hover = tex
	action.texture_pressed = tex
	action.texture_disabled = tex
	action.ignore_texture_size = true
	action.stretch_mode = TextureButton.STRETCH_SCALE
	action.disabled = not enabled
	action.mouse_filter = Control.MOUSE_FILTER_STOP
	action.modulate = Color.WHITE if enabled else Color(0.40, 0.43, 0.46, 0.82)
	if enabled:
		action.pressed.connect(callback)
	parent.add_child(action)
	var label := UiKit.label(text, 15 if enabled else 12, Color(1.0, 0.88, 0.58, 1.0) if enabled else Color(0.70, 0.75, 0.78, 0.9), 3)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	action.add_child(label)

func _build_chapter_header(chapter: Dictionary) -> TextureButton:
	var chapter_id := int(chapter.get("chapter", 1))
	var env := _chapter_env(chapter)
	var accent := _chapter_accent(chapter)
	var header := TextureButton.new()
	header.name = "ChapterHeader"
	header.custom_minimum_size = Vector2(0, CHAPTER_HERO_HEIGHT)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.texture_normal = load("res://assets/production/sprites/ui/ui_map_level_card_skin.png")
	header.texture_hover = header.texture_normal
	header.texture_pressed = header.texture_normal
	header.texture_disabled = header.texture_normal
	header.ignore_texture_size = true
	header.stretch_mode = TextureButton.STRETCH_SCALE
	header.clip_contents = true
	header.focus_mode = Control.FOCUS_NONE
	header.mouse_filter = Control.MOUSE_FILTER_PASS
	_add_chapter_art(header, str(env.get("portrait", "")), true)
	_add_chapter_frame(header, accent, true)

	var title := UiKit.label(str(env.get("chapter_title", "第%02d战区 · %s" % [chapter_id, env.get("name", "未知战区")])), 24, UiKit.TEXT_MAIN, 4)
	title.name = "ChapterDetailTitle"
	title.position = Vector2(36, 28)
	title.size = Vector2(600, 48)
	header.add_child(title)
	var story := UiKit.label(_wrap_chapter_text(str(env.get("story", "")), 24), 15, UiKit.TEXT_MAIN, 2)
	story.name = "ChapterDetailStory"
	story.position = Vector2(38, 88)
	story.size = Vector2(510, 72)
	story.autowrap_mode = TextServer.AUTOWRAP_OFF
	story.clip_text = true
	header.add_child(story)
	var objective := UiKit.label(_wrap_chapter_text(str(env.get("objective", "")), 31), 13, UiKit.TEXT_MUTED, 2)
	objective.position = Vector2(38, 164)
	objective.size = Vector2(510, 42)
	objective.autowrap_mode = TextServer.AUTOWRAP_OFF
	objective.clip_text = true
	header.add_child(objective)

	_add_chapter_progress(header, chapter, Vector2(606, 36), true, accent)
	_add_chapter_action_button(header, Vector2(612, 180), Vector2(250, 48), "返回战区地图", true, _back_to_chapter_map, "BackToChapterMapButton")
	return header

func _open_chapter(chapter_id: int) -> void:
	var chapter := _chapter_by_index(_chapter_groups(), chapter_id)
	if chapter.is_empty() or not _chapter_unlocked(chapter):
		AudioManager.play_sfx("ui_click", -8.0)
		return
	AudioManager.play_sfx("ui_confirm")
	selected_chapter = chapter_id
	_build_levels()
	var scroll := %LevelScroll as ScrollContainer
	scroll.scroll_vertical = 0

func _back_to_chapter_map() -> void:
	AudioManager.play_sfx("ui_click")
	selected_chapter = 0
	_build_levels()
	var scroll := %LevelScroll as ScrollContainer
	scroll.scroll_vertical = 0

func _build_nav() -> void:
	var nav := %Nav as HBoxContainer
	for child in nav.get_children():
		child.queue_free()
	var dock := PanelContainer.new()
	dock.name = "FeatureDock"
	dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dock.custom_minimum_size = Vector2(0, 114)
	dock.add_theme_stylebox_override("panel", _build_nav_dock_style())
	nav.add_child(dock)

	var bar := HBoxContainer.new()
	bar.name = "FeatureBar"
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_theme_constant_override("separation", 0)
	dock.add_child(bar)

	var modes := ["characters", "weapons", "armors", "chips", "pets", "skills"]
	for i in range(modes.size()):
		var mode := str(modes[i])
		bar.add_child(_make_nav_card(_nav_title(mode), mode, _nav_icon_path(mode), _nav_accent(mode), i < modes.size() - 1))

func _make_nav_card(label: String, mode: String, icon_path: String, accent: Color, has_divider: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "%sNavCard" % mode
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 114)
	var card_rest_style := _build_nav_card_style(accent, false)
	var card_hover_style := _build_nav_card_style(accent, true)
	card.add_theme_stylebox_override("panel", card_rest_style)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, 112)
	stage.clip_contents = true
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(stage)

	if mode == "characters":
		_add_nav_character_bust(stage)
	elif ResourceLoader.exists(icon_path):
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.texture = load(icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 16
		icon.offset_top = 10
		icon.offset_right = -16
		icon.offset_bottom = -32
		icon.modulate = Color(1.02, 1.02, 0.98, 1.0)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(icon)

	var status_plate := PanelContainer.new()
	status_plate.name = "StatusBadge"
	status_plate.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	status_plate.offset_left = -90
	status_plate.offset_top = 12
	status_plate.offset_right = -14
	status_plate.offset_bottom = 40
	status_plate.add_theme_stylebox_override("panel", _build_nav_status_style(accent))
	status_plate.clip_contents = true
	status_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(status_plate)

	var status := Label.new()
	status.text = _nav_status_text(mode)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.clip_text = true
	UiKit.apply_label(status, 12, UiKit.TEXT_MAIN, 2)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_plate.add_child(status)

	var lbl := Label.new()
	lbl.name = "Label"
	lbl.text = label
	lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	lbl.offset_left = 0
	lbl.offset_top = -32
	lbl.offset_right = 0
	lbl.offset_bottom = -5
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiKit.apply_label(lbl, 20, UiKit.TEXT_MAIN, 4)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(lbl)

	var hit := Button.new()
	hit.name = "HitArea"
	hit.set_anchors_preset(Control.PRESET_FULL_RECT)
	hit.text = ""
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	for key in ["normal", "hover", "pressed", "disabled", "focus"]:
		hit.add_theme_stylebox_override(key, StyleBoxEmpty.new())
	hit.pressed.connect(_open_collection.bind(mode))
	hit.mouse_entered.connect(_set_nav_card_style.bind(card, card_hover_style))
	hit.mouse_exited.connect(_set_nav_card_style.bind(card, card_rest_style))
	card.add_child(hit)
	return card

func _add_nav_character_bust(stage: Control) -> void:
	var row := _nav_selected_row("characters")
	if row.is_empty():
		row = DataLoader.get_row("characters", "vanguard")
	var center := CenterContainer.new()
	center.name = "IconCenter"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 12
	center.offset_top = 6
	center.offset_right = -12
	center.offset_bottom = -31
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(center)

	var clip := TextureRect.new()
	clip.name = "Icon"
	clip.texture = null
	clip.clip_contents = true
	clip.custom_minimum_size = Vector2(100, 72)
	clip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(clip)
	UiKit.add_character_bust(clip, row, Vector2(100, 72), 100.0, 3.0, Color(1.02, 1.02, 0.98, 1.0))

func _set_nav_card_style(card: PanelContainer, style: StyleBox) -> void:
	if not is_instance_valid(card):
		return
	card.add_theme_stylebox_override("panel", style)

func _build_nav_dock_style() -> StyleBox:
	return UiKit.panel_texture_style(8.0)

func _build_nav_card_style(_accent: Color, _highlighted: bool) -> StyleBox:
	return UiKit.map_nav_card_texture_style()

func _build_nav_status_style(_accent: Color) -> StyleBox:
	return UiKit.map_pill_texture_style()

func _nav_title(mode: String) -> String:
	match mode:
		"characters":
			return "角色"
		"weapons":
			return "武器"
		"armors":
			return "护甲"
		"chips":
			return "芯片"
		"pets":
			return "宠物"
		"skills":
			return "技能"
		_:
			return mode

func _nav_table(mode: String) -> String:
	match mode:
		"characters":
			return "characters"
		"weapons":
			return "weapons"
		"armors":
			return "armors"
		"chips":
			return "chips"
		"pets":
			return "pets"
		_:
			return ""

func _nav_slot(mode: String) -> String:
	match mode:
		"characters":
			return "character"
		"weapons":
			return "weapon"
		"armors":
			return "armor"
		"chips":
			return "chip"
		"pets":
			return "pet"
		_:
			return ""

func _nav_default_icon(mode: String) -> String:
	match mode:
		"characters":
			return "res://assets/production/sprites/characters/char_vanguard_icon.png"
		"weapons":
			return "res://assets/production/sprites/weapons/weapon_autocannon_icon.png"
		"armors":
			return "res://assets/production/sprites/equipment/armor_faraday_icon.png"
		"chips":
			return "res://assets/production/sprites/equipment/chip_attack_icon.png"
		"pets":
			return "res://assets/production/sprites/pets/pet_turret_drone_icon.png"
		"skills":
			return "res://assets/production/sprites/ui/skill_barrier_icon.png"
		_:
			return "res://assets/production/sprites/ui/icon_warning.png"

func _nav_selected_row(mode: String) -> Dictionary:
	var table := _nav_table(mode)
	var slot := _nav_slot(mode)
	if table == "" or slot == "":
		return {}
	var item_id := SaveManager.get_selected(slot)
	if item_id == "":
		return {}
	return DataLoader.get_row(table, item_id)

func _nav_icon_path(mode: String) -> String:
	var fallback := _nav_default_icon(mode)
	var row := _nav_selected_row(mode)
	if row.is_empty():
		return fallback
	return str(row.get("portrait", row.get("icon", fallback)))

func _nav_accent(mode: String) -> Color:
	var row := _nav_selected_row(mode)
	match mode:
		"characters":
			return UiKit.element_color(str(row.get("element_focus", "physical")))
		"weapons":
			return UiKit.element_color(str(row.get("element", "physical")))
		"armors":
			return Color(0.58, 0.72, 0.82)
		"chips":
			return UiKit.GREEN
		"pets":
			return UiKit.element_color(str(row.get("element", "physical")))
		"skills":
			return UiKit.PURPLE
		_:
			return UiKit.CYAN

func _nav_status_text(mode: String) -> String:
	if mode == "skills":
		return "图鉴"
	var slot := _nav_slot(mode)
	if slot == "":
		return ""
	var item_id := SaveManager.get_selected(slot)
	if item_id == "":
		return "未装"
	return "等级%d" % SaveManager.get_item_level(item_id)

func _open_collection(mode: String) -> void:
	AudioManager.play_sfx("ui_click")
	router.change_scene("collection", {"mode": mode, "return_to": "map"})

func _build_level_card(level_id: String, level: Dictionary, unlocked: bool, stars: int, challenge_stars: int) -> TextureButton:
	var button := TextureButton.new()
	button.custom_minimum_size = Vector2(0, LEVEL_CARD_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var base_texture := load("res://assets/production/sprites/ui/ui_map_level_card_skin.png")
	button.texture_normal = base_texture
	button.texture_hover = base_texture
	button.texture_pressed = base_texture
	button.texture_disabled = base_texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.clip_contents = true
	button.disabled = false
	button.focus_mode = Control.FOCUS_NONE
	# PASS 而非默认 STOP：让触摸拖拽能穿到 ScrollContainer 去滚动(点按仍能进关，滚动时会自动取消误触)。
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.modulate = Color(0.96, 0.96, 0.92, 1.0) if unlocked else Color(0.58, 0.60, 0.62, 0.82)

	var weakness := str(level.get("primary_weakness", "physical"))
	var accent := UiKit.element_color(weakness)
	var variant := str(level.get("variant", "normal"))
	var legacy_title := Label.new()
	legacy_title.name = "LegacySmokeTitle"
	legacy_title.text = DataLoader.level_display_name(level_id)
	legacy_title.visible = false
	legacy_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(legacy_title)

	var card_frame := PanelContainer.new()
	card_frame.name = "CardFrame"
	card_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_frame.offset_left = 0
	card_frame.offset_top = 0
	card_frame.offset_right = 0
	card_frame.offset_bottom = 0
	card_frame.add_theme_stylebox_override("panel", _level_card_style(accent, unlocked, stars, variant))
	card_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(card_frame)

	var accent_bar := TextureRect.new()
	accent_bar.position = Vector2(22, 20)
	accent_bar.size = Vector2(14, 110)
	accent_bar.texture = load("res://assets/production/sprites/ui/ui_map_accent_strip.png")
	accent_bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	accent_bar.stretch_mode = TextureRect.STRETCH_SCALE
	accent_bar.modulate = Color(accent.r, accent.g, accent.b, 0.92 if unlocked else 0.42)
	accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(accent_bar)

	var level_num := level_id.replace("level_", "")
	var index_plate := PanelContainer.new()
	index_plate.position = Vector2(44, 46)
	index_plate.size = Vector2(82, 58)
	index_plate.add_theme_stylebox_override("panel", _level_index_style(accent, unlocked))
	index_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(index_plate)
	var index_label := UiKit.label(level_num, 24, UiKit.TEXT_MAIN, 3)
	index_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	index_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	index_plate.add_child(index_label)

	var title := Label.new()
	title.text = DataLoader.level_display_name(level_id).replace("%s " % level_num, "")
	title.position = Vector2(148, 18)
	title.size = Vector2(360, 44)
	UiKit.apply_label(title, 28, UiKit.TEXT_MAIN if unlocked else UiKit.TEXT_MUTED, 3)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(title)

	_add_card_pill(button, Vector2(148, 84), Vector2(154, 34), "战力 %d" % SaveManager.get_recommended_power_for_level(level_id), UiKit.CYAN)
	_add_element_pill(button, Vector2(318, 84), Vector2(124, 34), weakness)
	_add_variant_marker(button, variant)

	_add_level_star_block(button, Vector2(LEVEL_RIGHT_X, 18), stars, challenge_stars, unlocked)
	_add_level_action_button(button, Vector2(LEVEL_RIGHT_X, LEVEL_BUTTON_Y), Vector2(154, LEVEL_BUTTON_H), "进入", unlocked, true, _open_level.bind(level_id), "EnterLevelButton")
	_add_level_action_button(button, Vector2(LEVEL_RIGHT_X + 166, LEVEL_BUTTON_Y), Vector2(172, LEVEL_BUTTON_H), "挑战模式", unlocked, false, _open_challenge_level.bind(level_id), "ChallengeLevelButton")
	return button

func _level_card_style(_accent: Color, unlocked: bool, _stars: int, _variant: String) -> StyleBox:
	return UiKit.map_level_card_texture_style(not unlocked)

func _level_index_style(_accent: Color, _unlocked: bool) -> StyleBox:
	return UiKit.map_index_texture_style()

func _add_deploy_status(parent: Control, unlocked: bool) -> void:
	var status := PanelContainer.new()
	status.position = Vector2(652, 74)
	status.size = Vector2(184, 36)
	var accent := UiKit.GOLD if unlocked else UiKit.TEXT_MUTED
	var bg := Color(0.12, 0.075, 0.024, 0.86) if unlocked else Color(0.020, 0.022, 0.026, 0.70)
	status.add_theme_stylebox_override("panel", UiKit.deploy_pill_texture_style())
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(status)

	var label := UiKit.label("出战" if unlocked else "未解锁", 16, accent, 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.add_child(label)

func _add_variant_marker(parent: Control, variant: String) -> void:
	var label := ""
	var accent := UiKit.GOLD
	match variant:
		"elite":
			label = "精英·奖励"
			accent = UiKit.DANGER
		"treasure":
			label = "宝箱"
			accent = UiKit.GOLD
		"boss":
			label = "首领"
			accent = UiKit.INFO
		"boss_rush":
			label = "首领乱斗"
			accent = UiKit.DANGER
		_:
			return
	var pill := PanelContainer.new()
	pill.position = Vector2(424, 28)
	pill.size = Vector2(78 if label.length() <= 2 else 110, 34)
	pill.add_theme_stylebox_override("panel", UiKit.map_pill_texture_style())
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pill)
	var text := UiKit.label(label, 16, accent, 2)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.add_child(text)

func _add_level_star_block(parent: Control, pos: Vector2, stars: int, challenge_stars: int, unlocked: bool) -> void:
	var block := Control.new()
	block.name = "StarProgressBlock"
	block.position = pos
	block.size = Vector2(LEVEL_RIGHT_W, 72)
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(block)
	_add_star_progress_row(block, Vector2(0, 0), "普通", stars, unlocked, UiKit.GOLD)
	_add_star_progress_row(block, Vector2(0, 36), "挑战", challenge_stars, unlocked, UiKit.PURPLE)

func _add_star_progress_row(parent: Control, pos: Vector2, label_text: String, stars: int, unlocked: bool, accent: Color) -> void:
	var row := HBoxContainer.new()
	row.position = pos
	row.size = Vector2(LEVEL_RIGHT_W, 32)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)
	var label := UiKit.label(label_text, 14, accent if unlocked else UiKit.TEXT_MUTED, 2)
	label.custom_minimum_size = Vector2(48, 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	for i in range(3):
		row.add_child(UiKit.icon(UiKit.star_icon_path(i < stars), Vector2(30, 30)))

func _add_level_action_button(parent: Control, pos: Vector2, size: Vector2, text: String, enabled: bool, primary: bool, callback: Callable, node_name: String) -> void:
	var action := TextureButton.new()
	action.name = node_name
	action.position = pos
	action.size = size
	action.custom_minimum_size = size
	var tex := load(BUTTON_PRIMARY if primary else BUTTON_SECONDARY)
	action.texture_normal = tex
	action.texture_hover = tex
	action.texture_pressed = tex
	action.texture_disabled = tex
	action.ignore_texture_size = true
	action.stretch_mode = TextureButton.STRETCH_SCALE
	action.disabled = not enabled
	action.mouse_filter = Control.MOUSE_FILTER_STOP
	action.modulate = Color.WHITE if enabled else Color(0.42, 0.45, 0.48, 0.82)
	if enabled:
		action.pressed.connect(callback)
	parent.add_child(action)
	var label := UiKit.label(text, 16, Color(1.0, 0.88, 0.58, 1.0) if enabled else Color(0.72, 0.76, 0.78, 0.9), 3)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action.add_child(label)

func _add_card_pill(parent: Control, pos: Vector2, size: Vector2, text: String, accent: Color) -> void:
	var pill := PanelContainer.new()
	pill.position = pos
	pill.size = size
	pill.add_theme_stylebox_override("panel", UiKit.map_pill_texture_style())
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pill)
	var label := UiKit.label(text, 16, UiKit.TEXT_MAIN, 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.add_child(label)

func _add_element_pill(parent: Control, pos: Vector2, size: Vector2, element: String) -> void:
	var pill := PanelContainer.new()
	var accent := UiKit.element_color(element)
	pill.position = pos
	pill.size = size
	pill.add_theme_stylebox_override("panel", UiKit.map_pill_texture_style())
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pill)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	pill.add_child(row)
	row.add_child(UiKit.icon(UiKit.element_icon_path(element), Vector2(22, 22)))
	var label := UiKit.label("弱%s" % _element_name(element), 15, UiKit.TEXT_MAIN, 2)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

func _open_level(level_id: String) -> void:
	AudioManager.play_sfx("ui_confirm")
	router.change_scene("loadout", {"level_id": level_id})

func _open_challenge_level(level_id: String) -> void:
	AudioManager.play_sfx("ui_confirm")
	router.change_scene("loadout", {"level_id": level_id, "challenge": true})

func _stars_text(count: int) -> String:
	var text := ""
	for i in range(3):
		text += "★" if i < count else "☆"
	return text

func _element_name(element: String) -> String:
	match element:
		"physical":
			return "物"
		"fire":
			return "火"
		"ice":
			return "冰"
		"lightning":
			return "电"
		"poison":
			return "毒"
		_:
			return element
