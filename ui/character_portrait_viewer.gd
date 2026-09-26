extends Control

signal appearance_requested
signal closed

const UiKit := preload("res://ui/ui_kit.gd")

var character_row: Dictionary = {}
var safe_insets := Vector4.ZERO
var zoom := 1.0
var pan := Vector2.ZERO
var _dragging := false
var _touch_index := -1
var _canvas: Control
var _image: TextureRect
var _zoom_button: Button

func _loc(zh: String, en: String) -> String:
	return en if LocalizationManager.is_english() else zh

func _ready() -> void:
	name = "CharacterPortraitViewer"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 16
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := TextureRect.new()
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.02, 0.03, 0.04, 0.98), Color(0.02, 0.03, 0.04, 0.98)])
	var shade := GradientTexture2D.new()
	shade.gradient = gradient
	backdrop.texture = shade
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = safe_insets.x + 28.0
	panel.offset_right = -safe_insets.z - 28.0
	panel.offset_top = safe_insets.y + 48.0
	panel.offset_bottom = -safe_insets.w - 48.0
	panel.add_theme_stylebox_override("panel", UiKit.detail_panel_texture_style())
	add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	layout.add_child(header)
	var title := UiKit.label(DataLoader.tr_key(str(character_row.get("name_key", ""))), 30, UiKit.TEXT_MAIN, 3)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(title)
	var close := Button.new()
	close.name = "ClosePortraitButton"
	UiKit.apply_close_glyph(close)
	for state in ["normal", "hover", "pressed", "focus"]:
		close.add_theme_stylebox_override(state, UiKit.icon_frame_texture_style(true))
	close.pressed.connect(close_viewer)
	header.add_child(close)
	_canvas = Control.new()
	_canvas.name = "PortraitCanvas"
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.clip_contents = true
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.resized.connect(_layout_image)
	_canvas.gui_input.connect(_on_portrait_input)
	layout.add_child(_canvas)
	_image = UiKit.icon(UiKit.character_bust_path(character_row), Vector2.ZERO)
	_image.name = "FullBodyImage"
	_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_canvas.add_child(_image)
	var hint := UiKit.label(_loc("全身原图 · 放大后可拖动查看", "Full portrait · Drag to pan when enlarged"), 17, UiKit.TEXT_MUTED, 2)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(hint)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 20)
	layout.add_child(actions)
	_zoom_button = _action("ZoomButton", _loc("放大 2×", "Zoom 2×"))
	_zoom_button.pressed.connect(toggle_zoom)
	actions.add_child(_zoom_button)
	var outfit := _action("PortraitAppearanceButton", _loc("外观", "Outfits"))
	outfit.pressed.connect(func():
		close_viewer()
		appearance_requested.emit()
	)
	actions.add_child(outfit)
	_layout_image.call_deferred()
	close.grab_focus()

func _action(node_name: String, text: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = Vector2(286, 96)
	button.add_theme_font_size_override("font_size", UiKit.scaled_font_size(20))
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, UiKit.armored_button_style(false, Vector2(286, 112), false))
	return button

func toggle_zoom() -> void:
	zoom = 2.0 if zoom == 1.0 else 1.0
	pan = Vector2.ZERO
	_zoom_button.text = _loc("查看全身", "Fit portrait") if zoom > 1.0 else _loc("放大 2×", "Zoom 2×")
	_layout_image()
	if zoom > 1.0:
		# Start with the face/upper body in view; the player can pan down to boots.
		pan.y = maxf(0.0, _image.size.y - _canvas.size.y) * 0.5
		_layout_image()

func _layout_image() -> void:
	if not is_instance_valid(_image) or _image.texture == null or _canvas.size.x <= 0.0 or _canvas.size.y <= 0.0:
		return
	var source := _image.texture.get_size()
	var fit := minf(_canvas.size.x / source.x, _canvas.size.y / source.y)
	_image.size = source * fit * zoom
	var limit := (_image.size - _canvas.size).max(Vector2.ZERO) * 0.5
	pan = pan.clamp(-limit, limit)
	_image.position = (_canvas.size - _image.size) * 0.5 + pan

func _on_portrait_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
	elif event is InputEventScreenDrag and event.index == _touch_index and zoom > 1.0:
		pan += event.relative
		_layout_image()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging and _touch_index == -1 and zoom > 1.0:
		pan += event.relative
		_layout_image()
	_canvas.accept_event()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_viewer()

func close_viewer() -> void:
	hide()
	closed.emit()
	queue_free()
