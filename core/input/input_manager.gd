extends Node

signal aim_point(world_pos: Vector2)
signal manual_aim_started(world_pos: Vector2)
signal manual_aim_released(world_pos: Vector2)
signal target_locked(world_pos: Vector2)
signal target_strategy_changed(strategy: String)
signal skill_pressed(slot: int)
signal pause_pressed

const MANUAL_AIM_HOLD_SECONDS := 0.30

var current_strategy := "breach"
var strategies := ["breach", "elite", "nearest", "low_hp"]
var _last_tap_time := 0.0
var _last_tap_pos := Vector2.ZERO
var _aim_press_active := false
var _aim_press_index := -1
var _aim_press_started_at := 0.0
var _aim_current_pos := Vector2.ZERO
var _manual_aim_active := false

func _ready() -> void:
	set_process(true)
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

func _process(_delta: float) -> void:
	if not _aim_press_active or _manual_aim_active:
		return
	if _now_seconds() - _aim_press_started_at < MANUAL_AIM_HOLD_SECONDS:
		return
	_manual_aim_active = true
	manual_aim_started.emit(_aim_current_pos)
	aim_point.emit(_aim_current_pos)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_aim_press(event.position, -1)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			target_locked.emit(event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if event.double_click:
					_cancel_aim_press()
					target_locked.emit(event.position)
				else:
					_begin_aim_press(event.position, -1)
			else:
				_end_aim_press(event.position, -1)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_handle_touch_lock(event.position)
			_begin_aim_press(event.position, event.index)
		else:
			_end_aim_press(event.position, event.index)
	elif event is InputEventScreenDrag:
		_update_aim_press(event.position, event.index)
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

func cancel_active_input() -> void:
	_cancel_aim_press()
	_last_tap_time = 0.0
	_last_tap_pos = Vector2.ZERO

func _handle_touch_lock(pos: Vector2) -> void:
	var now := _now_seconds()
	if now - _last_tap_time <= 0.32 and pos.distance_to(_last_tap_pos) <= 90.0:
		target_locked.emit(pos)
		_last_tap_time = 0.0
	else:
		_last_tap_time = now
		_last_tap_pos = pos

func _begin_aim_press(pos: Vector2, pointer_index: int) -> void:
	_aim_press_active = true
	_aim_press_index = pointer_index
	_aim_press_started_at = _now_seconds()
	_aim_current_pos = pos
	_manual_aim_active = false

func _update_aim_press(pos: Vector2, pointer_index: int) -> void:
	if not _aim_press_active:
		return
	if _aim_press_index != -1 and pointer_index != _aim_press_index:
		return
	_aim_current_pos = pos
	if _manual_aim_active:
		aim_point.emit(_aim_current_pos)

func _end_aim_press(pos: Vector2, pointer_index: int) -> void:
	if not _aim_press_active:
		return
	if _aim_press_index != -1 and pointer_index != _aim_press_index:
		return
	_aim_current_pos = pos
	if _manual_aim_active:
		aim_point.emit(_aim_current_pos)
		manual_aim_released.emit(_aim_current_pos)
	_cancel_aim_press()

func _cancel_aim_press() -> void:
	_aim_press_active = false
	_aim_press_index = -1
	_manual_aim_active = false

func _now_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0
