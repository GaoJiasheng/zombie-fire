extends Control
## Kill streak display. Increment on each kill, decay when idle.

const UiKit := preload("res://ui/ui_kit.gd")
const COMBO_DECAY := 1.6
const MILESTONES := [10, 25, 50, 100, 200, 500]

var _count := 0
var _last_hit_time := -99.0
var _milestone_index := 0
var _base_scale := 1.0
var _frame: Panel
var _accent_bar: ColorRect

@onready var _label: Label = $Label
@onready var _milestone: Label = $Milestone
@onready var _timer: Timer = $DecayTimer

func _ready() -> void:
	_setup_visuals()
	visible = false
	_label.text = ""
	_milestone.text = ""
	_milestone.modulate.a = 0.0
	_timer.wait_time = COMBO_DECAY
	_timer.one_shot = true
	_timer.timeout.connect(_on_decay)

func _setup_visuals() -> void:
	_frame = get_node_or_null("Frame") as Panel
	if _frame == null:
		_frame = Panel.new()
		_frame.name = "Frame"
		add_child(_frame)
		move_child(_frame, 0)
	_frame.offset_left = 18.0
	_frame.offset_top = 12.0
	_frame.offset_right = 312.0
	_frame.offset_bottom = 76.0
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.z_index = -1
	_frame.add_theme_stylebox_override("panel", _combo_frame_style())

	_accent_bar = get_node_or_null("AccentBar") as ColorRect
	if _accent_bar == null:
		_accent_bar = ColorRect.new()
		_accent_bar.name = "AccentBar"
		add_child(_accent_bar)
		move_child(_accent_bar, 1)
	_accent_bar.offset_left = 30.0
	_accent_bar.offset_top = 22.0
	_accent_bar.offset_right = 38.0
	_accent_bar.offset_bottom = 66.0
	_accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_accent_bar.color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.86)

	_label.offset_left = 46.0
	_label.offset_top = 12.0
	_label.offset_right = 304.0
	_label.offset_bottom = 76.0
	_label.add_theme_font_size_override("font_size", 42)
	_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.42, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(0.02, 0.012, 0.004, 1.0))
	_label.add_theme_constant_override("outline_size", 5)

	_milestone.offset_left = 34.0
	_milestone.offset_top = 76.0
	_milestone.offset_right = 308.0
	_milestone.offset_bottom = 136.0
	_milestone.add_theme_font_size_override("font_size", 28)
	_milestone.add_theme_color_override("font_color", Color(1.0, 0.58, 0.2, 1.0))
	_milestone.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	_milestone.add_theme_constant_override("outline_size", 5)

func _combo_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.028, 0.018, 0.76)
	style.border_color = Color(UiKit.GOLD.r, UiKit.GOLD.g, UiKit.GOLD.b, 0.62)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 2
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = 8
	return style

func register_kill() -> void:
	_count += 1
	_last_hit_time = Time.get_ticks_msec() / 1000.0
	_timer.start()
	visible = _count >= 2
	if not visible:
		return
	_label.text = "%d 连击" % _count
	_bump()
	if _count >= MILESTONES[_milestone_index]:
		_show_milestone(MILESTONES[_milestone_index])
		_milestone_index = mini(_milestone_index + 1, MILESTONES.size() - 1)

func reset() -> void:
	_count = 0
	_milestone_index = 0
	visible = false
	_label.text = ""
	_milestone.text = ""
	_milestone.modulate.a = 0.0

func _bump() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(_base_scale * 1.18, _base_scale * 1.18), 0.06)
	tween.tween_property(self, "scale", Vector2(_base_scale, _base_scale), 0.12)

func _show_milestone(value: int) -> void:
	_milestone.text = "× %d 杀！" % value
	_milestone.modulate.a = 1.0
	_milestone.scale = Vector2(0.6, 0.6)
	var tween := create_tween()
	tween.parallel().tween_property(_milestone, "scale", Vector2(1.0, 1.0), 0.18)
	tween.tween_interval(0.4)
	tween.tween_property(_milestone, "modulate:a", 0.0, 0.4)

func _on_decay() -> void:
	reset()
