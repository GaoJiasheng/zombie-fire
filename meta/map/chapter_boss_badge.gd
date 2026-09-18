extends PanelContainer

# Observe, never consume, the gesture: the enclosing map still owns scrolling.
signal hint_requested
signal hint_dismissed
const HOLD_SECONDS := 0.5
const DRAG_CANCEL_DISTANCE := 12.0
var _pointer := -2
var _origin := Vector2.ZERO
var _badge_origin := Vector2.ZERO
var _hold_timer: Timer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_hold_timer = Timer.new()
	_hold_timer.one_shot = true
	_hold_timer.wait_time = HOLD_SECONDS
	add_child(_hold_timer)
	_hold_timer.timeout.connect(func():
		if _pointer != -2 and is_visible_in_tree() and global_position.distance_to(_badge_origin) < DRAG_CANCEL_DISTANCE:
			hint_requested.emit()
	)
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			ancestor.scroll_started.connect(_cancel_drag)
			ancestor.get_v_scroll_bar().value_changed.connect(func(_value): _cancel_drag())
			break
		ancestor = ancestor.get_parent()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and not event.canceled:
		_begin_hold(event.index, get_global_transform() * event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Real touch may also produce an emulated mouse press. Keep its touch ID.
		if _pointer == -2:
			_begin_hold(-1, get_global_transform() * event.position)

func _input(event: InputEvent) -> void:
	if _pointer == -2:
		return
	if event is InputEventScreenTouch and event.index == _pointer and (not event.pressed or event.canceled):
		if event.canceled:
			_cancel_drag()
		else:
			_end_hold()
	elif event is InputEventMouseButton and _pointer == -1 and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_end_hold()
	elif event is InputEventScreenDrag and event.index == _pointer:
		if event.position.distance_to(_origin) >= DRAG_CANCEL_DISTANCE:
			_cancel_drag()
	elif event is InputEventMouseMotion and _pointer == -1:
		if event.position.distance_to(_origin) >= DRAG_CANCEL_DISTANCE:
			_cancel_drag()

func _begin_hold(pointer: int, position_in_viewport: Vector2) -> void:
	if _pointer != -2:
		return
	_pointer = pointer
	_origin = position_in_viewport
	_badge_origin = global_position
	self_modulate = Color(1.22, 1.22, 1.22)
	_hold_timer.start()

func _end_hold() -> void:
	_pointer = -2
	_hold_timer.stop()
	self_modulate = Color.WHITE

func _cancel_drag() -> void:
	_end_hold()
	hint_dismissed.emit()
