extends Node

signal aim_point(world_pos: Vector2)
signal target_locked(world_pos: Vector2)
signal target_strategy_changed(strategy: String)
signal skill_pressed(slot: int)
signal pause_pressed

var current_strategy := "breach"
var strategies := ["breach", "elite", "nearest", "low_hp"]
var _last_tap_time := 0.0
var _last_tap_pos := Vector2.ZERO

func _ready() -> void:
	if not InputMap.has_action("cycle_target_strategy"):
		InputMap.add_action("cycle_target_strategy")
		var tab := InputEventKey.new()
		tab.keycode = KEY_TAB
		InputMap.action_add_event("cycle_target_strategy", tab)
	for i in range(5):
		var action := "skill_%d" % (i + 1)
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var key := InputEventKey.new()
			key.keycode = KEY_1 + i
			InputMap.action_add_event(action, key)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		aim_point.emit(event.position)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			target_locked.emit(event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click:
				target_locked.emit(event.position)
			else:
				aim_point.emit(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_handle_touch(event.position)
	elif event.is_action_pressed("ui_cancel"):
		pause_pressed.emit()
	elif event.is_action_pressed("cycle_target_strategy"):
		cycle_strategy()

	for i in range(5):
		if event.is_action_pressed("skill_%d" % (i + 1)):
			skill_pressed.emit(i)

func cycle_strategy() -> void:
	var index := strategies.find(current_strategy)
	current_strategy = strategies[(index + 1) % strategies.size()]
	target_strategy_changed.emit(current_strategy)

func _handle_touch(pos: Vector2) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_tap_time <= 0.32 and pos.distance_to(_last_tap_pos) <= 90.0:
		target_locked.emit(pos)
		_last_tap_time = 0.0
	else:
		aim_point.emit(pos)
		_last_tap_time = now
		_last_tap_pos = pos
