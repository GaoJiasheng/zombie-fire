extends Control
## Combo / X-HIT display. Increment on each kill, decay when idle.

const COMBO_DECAY := 1.6
const MILESTONES := [10, 25, 50, 100, 200, 500]

var _count := 0
var _last_hit_time := -99.0
var _milestone_index := 0
var _base_scale := 1.0

@onready var _label: Label = $Label
@onready var _milestone: Label = $Milestone
@onready var _timer: Timer = $DecayTimer

func _ready() -> void:
	visible = false
	_label.text = ""
	_milestone.text = ""
	_milestone.modulate.a = 0.0
	_timer.wait_time = COMBO_DECAY
	_timer.one_shot = true
	_timer.timeout.connect(_on_decay)

func register_kill() -> void:
	_count += 1
	_last_hit_time = Time.get_ticks_msec() / 1000.0
	_timer.start()
	visible = _count >= 2
	if not visible:
		return
	_label.text = "%d-HIT" % _count
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
