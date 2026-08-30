extends Control

const UiKit := preload("res://ui/ui_kit.gd")
const BUTTON_PRIMARY := "res://assets/production/sprites/ui/ui_button_primary.png"
const BUTTON_SECONDARY := "res://assets/production/sprites/ui/ui_button_secondary.png"
const RESOURCE_POWER_ICON := "res://assets/production/sprites/ui/icon_talent_point.png"
const RESOURCE_TIP_DURATION := 1.8
const LEVEL_CARD_HEIGHT := 192.0
const LEVEL_MODE_AREA_X := 540.0
const LEVEL_MODE_AREA_W := 422.0
const LEVEL_MODE_SINGLE_W := 286.0
const LEVEL_MODE_DUAL_GAP := 10.0
const LEVEL_MODE_DUAL_W := (LEVEL_MODE_AREA_W - LEVEL_MODE_DUAL_GAP) * 0.5
const LEVEL_MODE_Y := 14.0
const LEVEL_MODE_H := 164.0
const LEVEL_MODE_STYLE_SIZE := Vector2(286.0, 112.0)
const CHAPTER_CARD_HEIGHT := 344.0
const CHAPTER_HERO_HEIGHT := 400.0
const CHAPTER_TEXT_X := 64.0
const CHAPTER_TEXT_W := 510.0
const CHAPTER_RIGHT_X := 626.0
const CHAPTER_RIGHT_W := 300.0
const CHAPTER_ACTION_SIZE := Vector2(284.0, 80.0)
const CHAPTER_ACTION_Y := 252.0

var router: Node
var resource_tip_tween: Tween = null
var selected_chapter := 0
var _scroll_focus_generation := 0
var _overview_focus_chapter := 0

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
	# Let the safe-area-owned Root decide the width. The authored 980px texture
	# scales cleanly, while a hard 980px minimum forced the 1080 capture outside
	# the 44px device gutters.
	btn.custom_minimum_size = Vector2(0, 184)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.focus_mode = Control.FOCUS_NONE
	var animated := AnimatedTexture.new()
	animated.frames = 4
	animated.speed_scale = 1.6
	for index in range(4):
		var path := "res://assets/production/sprites/ui/map/endless_horde/endless_horde_frame_%02d_980x184.png" % (index + 1)
		if ResourceLoader.exists(path):
			animated.set_frame_texture(index, load(path))
		animated.set_frame_duration(index, 0.20)
	btn.texture_normal = animated
	btn.texture_hover = animated
	btn.texture_pressed = animated
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_SCALE
	var veil := ColorRect.new()
	veil.name = "ReadabilityVeil"
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.012, 0.026, 0.045, 0.42)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(veil)
	var frame := PanelContainer.new()
	frame.name = "EndlessFrame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_stylebox_override("panel", UiKit.map_level_card_texture_style(false))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(frame)
	var best := SaveManager.get_endless_best_loops()
	var content := MarginContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("margin_left", 34)
	content.add_theme_constant_override("margin_top", 24)
	content.add_theme_constant_override("margin_right", 26)
	content.add_theme_constant_override("margin_bottom", 22)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(content)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(row)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 6)
	row.add_child(copy)
	var label := UiKit.label("无限尸潮", 28, Color(1.0, 0.82, 0.5, 1.0), 4)
	label.name = "Label"
	copy.add_child(label)
	var subtitle := UiKit.label("循环尸潮 · 金币结算 · 挑战最高轮数", 17, UiKit.TEXT_MAIN, 2)
	subtitle.name = "Subtitle"
	subtitle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(subtitle)
	var best_badge := PanelContainer.new()
	best_badge.name = "BestLoopBadge"
	best_badge.custom_minimum_size = Vector2(176, 76)
	best_badge.add_theme_stylebox_override("panel", UiKit.map_pill_texture_style())
	row.add_child(best_badge)
	var best_label := UiKit.label("最高\n%d 轮" % best, 18, UiKit.CYAN, 3)
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	best_badge.add_child(best_label)
	var cta := PanelContainer.new()
	cta.name = "EndlessCTA"
	cta.custom_minimum_size = Vector2(190, 80)
	cta.add_theme_stylebox_override("panel", UiKit.armored_button_style(true, Vector2(190, 80), false))
	row.add_child(cta)
	var cta_label := UiKit.label("迎战", 21, UiKit.GOLD, 3)
	cta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cta_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cta.add_child(cta_label)
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
	_apply_page_title_style(44)
	(%Nav as HBoxContainer).custom_minimum_size = Vector2(0, 150)
	(%Progress as Label).visible = false
	_ensure_resource_bar()

func _apply_page_title_style(size: int) -> void:
	var title := %Title as Label
	UiKit.apply_label(title, size, UiKit.TEXT_MAIN, 5)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.clip_text = true

func _refresh_header() -> void:
	var total_stars: int = DataLoader.get_table("levels").size() * 6
	var progress := %Progress as Label
	progress.visible = false
	progress.text = "%d  %d/%d" % [SaveManager.get_player_gold(), SaveManager.get_total_stars(), total_stars]
	var row := _ensure_resource_bar().get_node("Row") as HBoxContainer
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	# 统一用 UiKit 共享资源条(金币/星星/经验),与出战配置、收藏页一致。
	var bar := UiKit.standard_resource_bar(
		SaveManager.get_player_gold(),
		SaveManager.get_player_star(),
		SaveManager.get_player_xp(),
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
			var focus_level_id := _campaign_focus_level_id()
			if _chapter_contains_level(current, focus_level_id):
				_schedule_map_scroll_focus(focus_level_id, 34.0)
			else:
				_schedule_map_scroll_focus("", 0.0)
			return
	selected_chapter = 0
	_apply_page_title_style(44)
	(%Title as Label).text = "战区地图"
	for chapter in chapters:
		level_list.add_child(_build_chapter_card(chapter))
	var focus_chapter := _overview_focus_chapter
	if focus_chapter <= 0:
		focus_chapter = _chapter_from_level_id(_campaign_focus_level_id())
	_overview_focus_chapter = 0
	_schedule_map_scroll_focus("Chapter%02dCard" % focus_chapter, 28.0)

func _build_chapter_levels(level_list: VBoxContainer, chapter: Dictionary) -> void:
	var env := _chapter_env(chapter)
	var chapter_id := int(chapter.get("chapter", 1))
	var title := str(env.get("chapter_title", "第%02d战区 · %s" % [chapter_id, env.get("name", "未知战区")]))
	_apply_page_title_style(40)
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
	if _chapter_is_current(chapter):
		return "当前推进"
	return "已展开"

func _campaign_focus_level_id() -> String:
	var levels: Array = DataLoader.get_table("levels")
	for level in levels:
		var level_id := str((level as Dictionary).get("id", ""))
		if level_id != "" and SaveManager.is_level_unlocked(level_id) and SaveManager.get_level_stars(level_id) <= 0:
			return level_id
	return str((levels[levels.size() - 1] as Dictionary).get("id", "")) if not levels.is_empty() else ""

func _chapter_is_current(chapter: Dictionary) -> bool:
	if not _chapter_unlocked(chapter) or _chapter_completed(chapter):
		return false
	var focus_level_id := _campaign_focus_level_id()
	for level in chapter.get("levels", []):
		if str((level as Dictionary).get("id", "")) == focus_level_id:
			return true
	return false

func _chapter_contains_level(chapter: Dictionary, level_id: String) -> bool:
	if level_id == "":
		return false
	for level in chapter.get("levels", []):
		if str((level as Dictionary).get("id", "")) == level_id:
			return true
	return false

func _schedule_map_scroll_focus(control_name: String, top_inset: float) -> void:
	_scroll_focus_generation += 1
	call_deferred("_restore_map_scroll_focus", control_name, top_inset, _scroll_focus_generation)

func _restore_map_scroll_focus(control_name: String, top_inset: float, generation: int) -> void:
	# VBox sizing and queued removals settle over two frames. Restoring earlier
	# can measure the previous chapter list and land on the wrong card.
	if not is_inside_tree():
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if generation != _scroll_focus_generation or not is_inside_tree():
		return
	var scroll := %LevelScroll as ScrollContainer
	if control_name == "":
		scroll.scroll_vertical = 0
		return
	var target := (%LevelList as VBoxContainer).get_node_or_null(control_name) as Control
	if target == null:
		scroll.scroll_vertical = 0
		return
	scroll.scroll_vertical = maxi(0, int(round(target.position.y - top_inset)))

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
	var source := LocalizationManager.text(text).strip_edges()
	var lines: Array[String] = []
	if LocalizationManager.is_english():
		for paragraph in source.split("\n"):
			var line := ""
			for word in str(paragraph).split(" ", false):
				var candidate := str(word) if line == "" else "%s %s" % [line, word]
				if line != "" and candidate.length() > max_chars:
					lines.append(line)
					line = str(word)
				else:
					line = candidate
			if line != "":
				lines.append(line)
		return "\n".join(lines)
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

func _chapter_wrap_limit(chinese_limit: int) -> int:
	return chinese_limit * 2 + 6 if LocalizationManager.is_english() else chinese_limit

func _chapter_summary(chapter_id: int) -> String:
	var summaries := [
		"重启熔炉，切断尸潮路线",
		"重启桥塔，封锁冰原通道",
		"夺回工厂，恢复重弹补给",
		"关闭生化泄漏源",
		"重启主变压器",
		"夺回地下换乘枢纽",
		"夺回炼油区能源节点",
		"封印圣堂裂隙",
		"关闭轨道感染信号",
		"攻入核心，终结尸潮信号",
	]
	if chapter_id < 1 or chapter_id > summaries.size():
		return LocalizationManager.text("击破战区首领，推进防线")
	return LocalizationManager.text(str(summaries[chapter_id - 1]))

func _build_chapter_card(chapter: Dictionary) -> TextureButton:
	var chapter_id := int(chapter.get("chapter", 1))
	var env := _chapter_env(chapter)
	var unlocked := _chapter_unlocked(chapter)
	var completed := _chapter_completed(chapter)
	var current := _chapter_is_current(chapter)
	var accent := _chapter_accent(chapter)
	var button := TextureButton.new()
	button.name = "Chapter%02dCard" % chapter_id
	button.custom_minimum_size = Vector2(0, CHAPTER_CARD_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.texture_normal = null
	button.texture_hover = null
	button.texture_pressed = null
	button.texture_disabled = null
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.clip_contents = false
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.modulate = Color.WHITE if current else Color(0.90, 0.92, 0.94, 0.96) if unlocked else Color(0.84, 0.86, 0.88, 0.94)
	# The chapter card is presentation only. Entry is deliberately bound to the
	# explicit button below so every other point on the card remains a reliable
	# scroll-drag surface.
	_add_chapter_frame(button, accent, unlocked)

	var margin := MarginContainer.new()
	margin.name = "ChapterContentMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	columns.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(columns)

	var visual_column := VBoxContainer.new()
	visual_column.custom_minimum_size = Vector2(384, 0)
	visual_column.add_theme_constant_override("separation", 8)
	visual_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columns.add_child(visual_column)
	visual_column.add_child(_build_chapter_thumbnail(chapter_id, unlocked))

	var range_row := HBoxContainer.new()
	range_row.add_theme_constant_override("separation", 10)
	range_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual_column.add_child(range_row)
	var range := UiKit.label("关卡 %s" % _chapter_range_text(chapter), 17, accent if unlocked else UiKit.TEXT_MUTED, 2)
	range.name = "ChapterRange"
	range.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	range.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	range_row.add_child(range)
	range_row.add_child(_build_chapter_status_pill(_chapter_status_text(chapter), accent if unlocked else UiKit.TEXT_MUTED))

	var objective := UiKit.label(LocalizationManager.text("击破战区首领，推进防线"), 15, UiKit.TEXT_MUTED, 2)
	objective.name = "ChapterObjective"
	objective.custom_minimum_size = Vector2(0, 34)
	objective.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	visual_column.add_child(objective)

	var info_column := VBoxContainer.new()
	info_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_column.add_theme_constant_override("separation", 8)
	info_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columns.add_child(info_column)

	var title_font := 18 if LocalizationManager.is_english() else 23
	var title := UiKit.label(str(env.get("chapter_title", "第%02d战区 · %s" % [chapter_id, env.get("name", "未知战区")])), title_font, UiKit.TEXT_MAIN if unlocked else UiKit.TEXT_MUTED, 4)
	title.name = "ChapterTitle"
	title.custom_minimum_size = Vector2(0, 46)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info_column.add_child(title)

	var story_color := UiKit.TEXT_MAIN if current else UiKit.TEXT_MUTED
	var story := UiKit.label(_chapter_summary(chapter_id), 15, story_color if unlocked else UiKit.TEXT_MUTED, 2)
	story.name = "ChapterStory"
	story.custom_minimum_size = Vector2(0, 34)
	story.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_column.add_child(story)

	info_column.add_child(_build_chapter_progress_panel(chapter, unlocked, accent))

	var bottom := HBoxContainer.new()
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 8)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_column.add_child(bottom)
	bottom.add_child(_build_chapter_boss_badge(_chapter_boss_level(chapter, false), false, unlocked))
	bottom.add_child(_build_chapter_boss_badge(_chapter_boss_level(chapter, true), true, unlocked))
	var action_label := "继续推进" if current else "回顾战区" if completed else "进入战区" if unlocked else _chapter_next_lock_text(chapter)
	bottom.add_child(_build_chapter_action_control(action_label, unlocked, _open_chapter.bind(chapter_id)))
	return button

func _chapter_thumbnail_path(chapter_id: int) -> String:
	var names := [
		"lava_foundry", "glacier_pass", "abandoned_factory", "toxic_biolab", "storm_substation",
		"flooded_subway", "desert_refinery", "void_cathedral", "orbital_ruins", "apex_core",
	]
	if chapter_id < 1 or chapter_id > names.size():
		return ""
	return "res://assets/production/sprites/ui/map/warzone_thumbnails/warzone_%02d_%s_thumb_candidate_420x144.png" % [chapter_id, names[chapter_id - 1]]

func _build_chapter_thumbnail(chapter_id: int, unlocked: bool) -> TextureRect:
	var thumbnail := TextureRect.new()
	thumbnail.name = "ChapterThumbnail"
	thumbnail.custom_minimum_size = Vector2(384, 132)
	var path := _chapter_thumbnail_path(chapter_id)
	if ResourceLoader.exists(path):
		thumbnail.texture = load(path)
	thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumbnail.modulate = Color.WHITE if unlocked else Color(0.48, 0.52, 0.56, 0.72)
	thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return thumbnail

func _build_chapter_status_pill(text: String, accent: Color) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.name = "ChapterStatus"
	pill.custom_minimum_size = Vector2(126, 38)
	pill.add_theme_stylebox_override("panel", UiKit.map_pill_texture_style())
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := UiKit.label(text, 15, accent, 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.add_child(label)
	return pill

func _build_chapter_progress_panel(chapter: Dictionary, unlocked: bool, accent: Color) -> VBoxContainer:
	var stack := VBoxContainer.new()
	stack.name = "ChapterProgress"
	stack.custom_minimum_size = Vector2(0, 82)
	stack.add_theme_constant_override("separation", 4)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var count := _chapter_cleared_count(chapter)
	var total_levels := int((chapter.get("levels", []) as Array).size())
	var stars := _chapter_star_count(chapter)
	var star_total := _chapter_total_stars(chapter)
	var summary_font := 13 if LocalizationManager.is_english() else 15
	var summary := UiKit.label("战区进度  %d/%d    ★ %d/%d" % [count, total_levels, stars, star_total], summary_font, accent if unlocked else UiKit.TEXT_MUTED, 2)
	summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stack.add_child(summary)
	var segments := HBoxContainer.new()
	segments.name = "ProgressSegments"
	segments.custom_minimum_size = Vector2(0, 22)
	segments.add_theme_constant_override("separation", 4)
	segments.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(segments)
	for index in range(maxi(total_levels, 1)):
		var segment := PanelContainer.new()
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.custom_minimum_size = Vector2(10, 18)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(accent.r, accent.g, accent.b, 0.92) if index < count and unlocked else Color(0.18, 0.23, 0.28, 0.82)
		style.border_color = Color(accent.r, accent.g, accent.b, 0.62 if unlocked else 0.22)
		style.set_border_width_all(1)
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 3
		segment.add_theme_stylebox_override("panel", style)
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		segments.add_child(segment)
	return stack

func _build_chapter_boss_badge(level: Dictionary, major: bool, unlocked: bool) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.name = "MajorBossNode" if major else "SmallBossNode"
	badge.custom_minimum_size = Vector2(82, 66)
	badge.add_theme_stylebox_override("panel", UiKit.map_pill_texture_style())
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 2)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(row)
	var icon_path := "res://assets/production/sprites/ui/map/ui_boss_badge_major.png" if major else "res://assets/production/sprites/ui/map/ui_boss_badge_minor.png"
	var icon := UiKit.icon(icon_path, Vector2(48, 48))
	icon.modulate = Color.WHITE if unlocked else Color(0.54, 0.57, 0.60, 0.70)
	row.add_child(icon)
	var level_number := DataLoader.level_number(str(level.get("id", "")))
	var number := UiKit.label(str(level_number), 13, UiKit.TEXT_MAIN if unlocked else UiKit.TEXT_MUTED, 1)
	number.custom_minimum_size = Vector2(26, 0)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(number)
	badge.tooltip_text = TranslationServer.translate("大首领" if major else "小首领")
	return badge

func _build_chapter_action_control(text: String, enabled: bool, callback: Callable, primary := true) -> TextureButton:
	var action := TextureButton.new()
	action.name = "EnterChapterButton"
	# 280x80 is the authored primary-action ruler (m1 smoke pins it); 286x80 is the
	# matching native button size so the frame art is never resampled.
	action.custom_minimum_size = Vector2(286, 80)
	UiKit.apply_armored_texture_button(action, primary, Vector2(286, 80), enabled)
	_make_scroll_friendly_button(action)
	action.modulate = Color.WHITE if enabled else Color(0.54, 0.57, 0.60, 0.88)
	if enabled:
		action.pressed.connect(callback)
	var label_color := (UiKit.GOLD if primary else UiKit.CYAN) if enabled else UiKit.TEXT_MUTED
	var label := UiKit.label(text, 17 if enabled else 14, label_color, 3)
	label.name = "ActionLabel"
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action.add_child(label)
	var touch_target := UiKit.attach_touch_target(action)
	if touch_target != null:
		_make_scroll_friendly_button(touch_target)
	return action

func _add_chapter_art(parent: Control, portrait_path: String, unlocked: bool) -> void:
	if portrait_path == "" or not ResourceLoader.exists(portrait_path):
		return
	var art := TextureRect.new()
	art.name = "ChapterArt"
	art.texture = load(portrait_path)
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.modulate = Color(0.72, 0.76, 0.76, 0.70) if unlocked else Color(0.54, 0.56, 0.58, 0.70)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)

	var dim := TextureRect.new()
	dim.name = "ChapterReadabilityVeil"
	dim.texture = load("res://assets/production/sprites/ui/ui_panel_skin.png")
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dim.stretch_mode = TextureRect.STRETCH_SCALE
	dim.modulate = Color(0.0, 0.0, 0.0, 0.56 if unlocked else 0.43)
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
	rail.size = Vector2(14, maxf(72.0, parent.custom_minimum_size.y - 56.0))
	rail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rail.stretch_mode = TextureRect.STRETCH_SCALE
	rail.modulate = Color(accent.r, accent.g, accent.b, 0.95 if unlocked else 0.52)
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rail)

func _add_chapter_status_pill(parent: Control, pos: Vector2, text: String, accent: Color) -> void:
	var pill := PanelContainer.new()
	pill.name = "ChapterStatus"
	pill.position = pos
	pill.size = Vector2(118, 34)
	pill.add_theme_stylebox_override("panel", UiKit.map_pill_texture_style())
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pill)
	var label := UiKit.label(text, 16, accent, 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.add_child(label)

func _add_chapter_progress(parent: Control, chapter: Dictionary, pos: Vector2, unlocked: bool, accent: Color, panel_size := Vector2(282, 104)) -> void:
	var panel := Control.new()
	panel.name = "ChapterProgress"
	panel.position = pos
	panel.size = panel_size
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

	var title := UiKit.label("战区进度", 16, accent if unlocked else UiKit.TEXT_MUTED, 2)
	title.position = Vector2(24, 14)
	title.size = Vector2(panel_size.x - 48, 28)
	panel.add_child(title)
	var count := _chapter_cleared_count(chapter)
	var total_levels := int((chapter.get("levels", []) as Array).size())
	var stars := _chapter_star_count(chapter)
	var star_total := _chapter_total_stars(chapter)
	var value := UiKit.label("%d/%d  %d/%d★" % [count, total_levels, stars, star_total], 21, UiKit.TEXT_MAIN if unlocked else UiKit.TEXT_MUTED, 3)
	value.name = "ChapterProgressValue"
	value.position = Vector2(24, 48)
	value.size = Vector2(panel_size.x - 48, 40)
	panel.add_child(value)
	_add_progress_micro_bar(panel, Vector2(24, panel_size.y - 28), Vector2(panel_size.x - 56, 14), float(count) / maxf(float(total_levels), 1.0), accent, unlocked)

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
	panel.size = Vector2(144, 52)
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
	var text := UiKit.label("%s  %s" % [number, label_text], 15, accent if unlocked else UiKit.TEXT_MUTED, 2)
	text.position = Vector2(8, 2)
	text.size = Vector2(128, 26)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.clip_text = true
	panel.add_child(text)
	var state := UiKit.label("已击破" if cleared else ("待挑战" if unlocked else "未展开"), 14, UiKit.TEXT_MAIN if cleared else UiKit.TEXT_MUTED, 1)
	state.position = Vector2(8, 29)
	state.size = Vector2(128, 20)
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state.clip_text = true
	panel.add_child(state)

func _add_chapter_action_button(parent: Control, pos: Vector2, size: Vector2, text: String, enabled: bool, callback: Callable, node_name: String) -> void:
	var action := TextureButton.new()
	action.name = node_name
	action.position = pos
	action.size = size
	action.custom_minimum_size = size
	UiKit.apply_armored_texture_button(action, true, size, enabled)
	_make_scroll_friendly_button(action)
	action.modulate = Color.WHITE if enabled else Color(0.54, 0.57, 0.60, 0.88)
	if enabled:
		action.pressed.connect(callback)
	parent.add_child(action)
	var label := UiKit.label(text, 20 if enabled else 16, Color(1.0, 0.88, 0.58, 1.0) if enabled else Color(0.78, 0.82, 0.84, 0.96), 3)
	label.name = "ActionLabel"
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action.add_child(label)
	var touch_target := UiKit.attach_touch_target(action)
	if touch_target != null:
		_make_scroll_friendly_button(touch_target)

func _make_scroll_friendly_button(button: BaseButton) -> void:
	# PASS lets ScrollContainer receive the same press/drag sequence. Godot then
	# cancels the button activation once the scroll deadzone is crossed, while a
	# stationary short tap still emits pressed on the explicit button only.
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.set_meta("scroll_drag_passthrough", true)

func _build_chapter_header(chapter: Dictionary) -> TextureButton:
	var chapter_id := int(chapter.get("chapter", 1))
	var env := _chapter_env(chapter)
	var accent := _chapter_accent(chapter)
	var header := TextureButton.new()
	header.name = "ChapterHeader"
	header.custom_minimum_size = Vector2(0, CHAPTER_HERO_HEIGHT)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.texture_normal = null
	header.texture_hover = null
	header.texture_pressed = null
	header.texture_disabled = null
	header.ignore_texture_size = true
	header.clip_contents = false
	header.focus_mode = Control.FOCUS_NONE
	header.mouse_filter = Control.MOUSE_FILTER_PASS
	_add_chapter_art(header, str(env.get("portrait", "")), true)
	_add_chapter_frame(header, accent, true)

	var margin := MarginContainer.new()
	margin.name = "ChapterDetailContent"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 20)
	columns.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(columns)
	var copy := VBoxContainer.new()
	copy.custom_minimum_size = Vector2(470, 0)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 8)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columns.add_child(copy)
	var title := UiKit.label(str(env.get("chapter_title", "第%02d战区 · %s" % [chapter_id, env.get("name", "未知战区")])), 23, UiKit.TEXT_MAIN, 4)
	title.name = "ChapterDetailTitle"
	title.custom_minimum_size = Vector2(0, 48)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(title)
	var story := UiKit.label(str(env.get("story", "")), 16, UiKit.TEXT_MAIN, 2)
	story.name = "ChapterDetailStory"
	story.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.max_lines_visible = 4
	story.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	story.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	story.add_theme_constant_override("line_spacing", 3)
	copy.add_child(story)
	var objective := UiKit.label(str(env.get("objective", "")), 15, UiKit.TEXT_MUTED, 2)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.max_lines_visible = 2
	objective.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	objective.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	objective.add_theme_constant_override("line_spacing", 3)
	copy.add_child(objective)
	var actions := VBoxContainer.new()
	actions.custom_minimum_size = Vector2(340, 0)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 18)
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columns.add_child(actions)
	actions.add_child(_build_chapter_progress_panel(chapter, true, accent))
	var back := _build_chapter_action_control("返回战区地图", true, _back_to_chapter_map, false)
	back.name = "BackToChapterMapButton"
	back.custom_minimum_size = Vector2(284, 80)
	actions.add_child(back)
	return header

func _open_chapter(chapter_id: int) -> void:
	var chapter := _chapter_by_index(_chapter_groups(), chapter_id)
	if chapter.is_empty() or not _chapter_unlocked(chapter):
		AudioManager.play_sfx("ui_click", -8.0)
		return
	AudioManager.play_sfx("ui_confirm")
	selected_chapter = chapter_id
	_build_levels()

func _back_to_chapter_map() -> void:
	AudioManager.play_sfx("ui_click")
	_overview_focus_chapter = selected_chapter
	selected_chapter = 0
	_build_levels()

func _build_nav() -> void:
	var nav := %Nav as HBoxContainer
	for child in nav.get_children():
		child.queue_free()
	var dock := PanelContainer.new()
	dock.name = "FeatureDock"
	dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dock.custom_minimum_size = Vector2(0, 146)
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
	var is_empty := _nav_is_empty(mode)
	var card := PanelContainer.new()
	card.name = "%sNavCard" % mode
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 144)
	var card_rest_style := _build_nav_card_style(accent, false)
	var card_hover_style := _build_nav_card_style(accent, true)
	card.add_theme_stylebox_override("panel", card_rest_style)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, 142)
	# The label deliberately sits on the lower edge of the art stage. Clipping
	# the stage made its glyph bounds fail even though the nav card had room.
	stage.clip_contents = false
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
		icon.offset_left = 12
		icon.offset_top = 30
		icon.offset_right = -12
		icon.offset_bottom = -36
		icon.modulate = Color(0.54, 0.78, 0.86, 0.42) if is_empty else Color(1.02, 1.02, 0.98, 1.0)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(icon)
		if is_empty:
			var plus := UiKit.label("+", 34, UiKit.CYAN, 3)
			plus.name = "EmptySlotPlus"
			plus.set_anchors_preset(Control.PRESET_FULL_RECT)
			plus.offset_bottom = -18
			plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stage.add_child(plus)

	var status_plate := PanelContainer.new()
	status_plate.name = "StatusBadge"
	status_plate.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	status_plate.offset_left = -88
	status_plate.offset_top = 7
	status_plate.offset_right = -12
	# Keep enough inner width and vertical breathing room for the licensed
	# display font at the largest equipped-level strings (for example Lv40).
	# The previous compact plate could clip the glyph metrics after the global
	# readability increase.
	status_plate.offset_bottom = 40
	status_plate.add_theme_stylebox_override("panel", _build_nav_status_style(accent))
	status_plate.visible = not is_empty
	status_plate.clip_contents = true
	status_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(status_plate)

	var status := Label.new()
	status.text = _nav_status_short_text(mode)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.clip_text = true
	UiKit.apply_label(status, 14, UiKit.TEXT_MAIN, 2)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_plate.add_child(status)

	var lbl := Label.new()
	lbl.name = "Label"
	lbl.text = label
	lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	lbl.offset_left = 0
	lbl.offset_top = -38
	lbl.offset_right = 0
	lbl.offset_bottom = -3
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
	center.offset_left = 8
	center.offset_top = 22
	center.offset_right = -8
	center.offset_bottom = -40
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(center)

	var clip := TextureRect.new()
	clip.name = "Icon"
	clip.texture = null
	clip.clip_contents = true
	clip.custom_minimum_size = Vector2(124, 80)
	clip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(clip)
	UiKit.add_character_bust(clip, row, Vector2(124, 80), 124.0, -10.0, Color(1.04, 1.04, 0.98, 1.0))

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
		return fallback if mode in ["characters", "skills"] else "res://assets/production/sprites/ui/ui_empty_equipment_socket.png"
	return str(row.get("portrait", row.get("icon", fallback)))

func _nav_is_empty(mode: String) -> bool:
	if mode in ["characters", "skills"]:
		return false
	var slot := _nav_slot(mode)
	return slot != "" and SaveManager.get_selected(slot) == ""

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
		return ""
	return "等级%d" % SaveManager.get_item_level(item_id)

func _nav_status_short_text(mode: String) -> String:
	if mode == "skills":
		return "图鉴"
	var slot := _nav_slot(mode)
	if slot == "":
		return ""
	var item_id := SaveManager.get_selected(slot)
	if item_id == "":
		return ""
	return "Lv%d" % SaveManager.get_item_level(item_id)

func _open_collection(mode: String) -> void:
	AudioManager.play_sfx("ui_click")
	router.change_scene("collection", {"mode": mode, "return_to": "map"})

func _build_level_card(level_id: String, level: Dictionary, unlocked: bool, stars: int, challenge_stars: int) -> TextureButton:
	var button := TextureButton.new()
	button.name = level_id
	button.custom_minimum_size = Vector2(0, LEVEL_CARD_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.texture_normal = null
	button.texture_hover = null
	button.texture_pressed = null
	button.texture_disabled = null
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	# The dual-mode labels sit optically into the authored frame edge. The level
	# card has no overflowing art to mask, so ancestor clipping only cuts valid
	# Normal/Challenge glyph bounds on completed stages.
	button.clip_contents = false
	button.disabled = false
	button.focus_mode = Control.FOCUS_NONE
	# PASS 而非默认 STOP：让触摸拖拽能穿到 ScrollContainer 去滚动(点按仍能进关，滚动时会自动取消误触)。
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.modulate = Color(0.96, 0.96, 0.92, 1.0) if unlocked else Color(0.84, 0.86, 0.88, 0.94)

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
	accent_bar.position = Vector2(22, 22)
	accent_bar.size = Vector2(14, 148)
	accent_bar.texture = load("res://assets/production/sprites/ui/ui_map_accent_strip.png")
	accent_bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	accent_bar.stretch_mode = TextureRect.STRETCH_SCALE
	accent_bar.modulate = Color(accent.r, accent.g, accent.b, 0.92 if unlocked else 0.42)
	accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(accent_bar)

	var level_num := level_id.replace("level_", "")
	var index_plate := PanelContainer.new()
	index_plate.position = Vector2(44, 57)
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
	title.position = Vector2(148, 24)
	var title_width := 264.0 if variant in ["elite", "treasure", "boss", "boss_rush"] else 360.0
	title.size = Vector2(title_width, 44)
	var title_font_size := 24 if title.text.length() > 10 else 28
	UiKit.apply_label(title, title_font_size, UiKit.TEXT_MAIN if unlocked else Color(0.80, 0.84, 0.86, 1.0), 3)
	# English level names are much wider than their Chinese counterparts. Keep
	# the complete name inside its reserved lane and out of the variant badge.
	UiKit.fit_label_text(title, title_font_size, 18, 2.0, 2.0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(title)

	_add_card_pill(button, Vector2(148, 108), Vector2(154, 34), "推荐 %d" % SaveManager.get_recommended_power_for_level(level_id), UiKit.CYAN)
	_add_element_pill(button, Vector2(318, 108), Vector2(210, 34), weakness)
	if level_id == _campaign_focus_level_id():
		# Keep the translated Current badge in the index lane. The information
		# lane then has enough width for every localized weakness name without
		# collisions or tiny adaptive type.
		_add_card_pill(button, Vector2(44, 130), Vector2(82, 32), "当前", UiKit.GOLD)
	_add_variant_marker(button, variant)

	var challenge_unlocked := SaveManager.is_challenge_unlocked(level_id)
	# Do not reserve a dead second row before the player has cleared Normal.
	# Once Normal has a result, switch the action lane to two equal, tall touch
	# targets. Challenge remains governed by the existing 3-star unlock rule.
	var challenge_visible := stars > 0
	var normal_width := LEVEL_MODE_DUAL_W if challenge_visible else LEVEL_MODE_SINGLE_W
	var normal_x := LEVEL_MODE_AREA_X if challenge_visible else LEVEL_MODE_AREA_X + (LEVEL_MODE_AREA_W - LEVEL_MODE_SINGLE_W) * 0.5
	var normal_label := "普通" if challenge_visible else "闯关"
	_add_level_mode_button(
		button,
		Vector2(normal_x, LEVEL_MODE_Y),
		Vector2(normal_width, LEVEL_MODE_H),
		normal_label,
		stars,
		unlocked,
		true,
		UiKit.GOLD,
		_open_level.bind(level_id),
		"NormalModeButton",
		"normal"
	)
	if challenge_visible:
		_add_level_mode_button(
			button,
			Vector2(LEVEL_MODE_AREA_X + LEVEL_MODE_DUAL_W + LEVEL_MODE_DUAL_GAP, LEVEL_MODE_Y),
			Vector2(LEVEL_MODE_DUAL_W, LEVEL_MODE_H),
			"挑战",
			challenge_stars,
			challenge_unlocked,
			false,
			UiKit.PURPLE,
			_open_challenge_level.bind(level_id),
			"ChallengeModeButton",
			"challenge"
		)
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

func _add_level_mode_button(parent: Control, pos: Vector2, size: Vector2, text: String, stars: int, enabled: bool, primary: bool, accent: Color, callback: Callable, node_name: String, mode_id: String) -> void:
	var action := Button.new()
	action.name = node_name
	action.position = pos
	action.size = size
	action.custom_minimum_size = action.size
	action.text = ""
	action.focus_mode = Control.FOCUS_NONE
	action.disabled = not enabled
	# Use the authored 286x112 themed raster as a nine-slice surface. This keeps
	# every theme's real frame/corners while allowing the two-column controls to
	# become tall enough for a friendly touch target and stacked content.
	for state in ["normal", "hover", "pressed", "focus"]:
		action.add_theme_stylebox_override(state, UiKit.armored_button_style(primary, LEVEL_MODE_STYLE_SIZE, false))
	action.add_theme_stylebox_override("disabled", UiKit.armored_button_style(false, LEVEL_MODE_STYLE_SIZE, true))
	_make_scroll_friendly_button(action)
	action.set_meta("level_mode", mode_id)
	action.set_meta("star_count", stars)
	action.set_meta("mode_layout", "dual" if size.x < LEVEL_MODE_SINGLE_W else "single")
	action.tooltip_text = TranslationServer.translate(text) if enabled else "%s · %s" % [TranslationServer.translate(text), TranslationServer.translate("普通三星解锁")]
	if enabled:
		action.pressed.connect(callback)
	parent.add_child(action)

	var content := VBoxContainer.new()
	content.name = "ModeContent"
	content.position = Vector2(8, 18)
	content.size = Vector2(size.x - 16.0, size.y - 36.0)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 2)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action.add_child(content)

	var mode_font := 17 if size.x < LEVEL_MODE_SINGLE_W else 21
	if LocalizationManager.is_english():
		mode_font -= 1
	var label := UiKit.label(text, mode_font, accent if enabled else UiKit.TEXT_MUTED, 3)
	label.name = "ModeLabel"
	label.custom_minimum_size = Vector2(0, 42)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(label)

	var star_row := HBoxContainer.new()
	star_row.name = "ModeStars"
	star_row.custom_minimum_size = Vector2(0, 38)
	star_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	star_row.add_theme_constant_override("separation", 2)
	star_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(star_row)

	if not enabled and mode_id == "challenge":
		var lock_icon := UiKit.icon("res://assets/production/sprites/ui/icon_lock.png", Vector2(26, 26))
		lock_icon.name = "UnlockRequirement"
		lock_icon.modulate = Color(0.72, 0.76, 0.80, 0.86)
		star_row.add_child(lock_icon)
	for i in range(3):
		var star := UiKit.icon(UiKit.star_icon_path(i < stars), Vector2(30, 30))
		star.name = "Star%d" % (i + 1)
		star.modulate = Color.WHITE if enabled else Color(0.66, 0.69, 0.72, 0.82)
		star_row.add_child(star)
	var touch_target := UiKit.attach_touch_target(action)
	if touch_target != null:
		_make_scroll_friendly_button(touch_target)

func _add_card_pill(parent: Control, pos: Vector2, size: Vector2, text: String, accent: Color) -> void:
	var pill := PanelContainer.new()
	pill.position = pos
	pill.size = size
	pill.add_theme_stylebox_override("panel", UiKit.map_pill_texture_style())
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pill)
	var label := UiKit.label(text, 17, UiKit.TEXT_MAIN, 2)
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
	var label := UiKit.label("弱%s" % _element_name(element), 16, UiKit.TEXT_MAIN, 2)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

func _open_level(level_id: String) -> void:
	if not SaveManager.is_level_unlocked(level_id):
		AudioManager.play_sfx("ui_click", -8.0)
		return
	AudioManager.play_sfx("ui_confirm")
	router.change_scene("loadout", _loadout_route_payload(level_id, false))

func _open_challenge_level(level_id: String) -> void:
	if not SaveManager.is_challenge_unlocked(level_id):
		AudioManager.play_sfx("ui_click", -8.0)
		return
	AudioManager.play_sfx("ui_confirm")
	router.change_scene("loadout", _loadout_route_payload(level_id, true))

func _loadout_route_payload(level_id: String, challenge: bool) -> Dictionary:
	var chapter_id := selected_chapter
	if chapter_id <= 0:
		chapter_id = _chapter_from_level_id(level_id)
	return {
		"level_id": level_id,
		"challenge": challenge,
		"return_to": "map",
		"return_payload": {"chapter": chapter_id},
	}

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
