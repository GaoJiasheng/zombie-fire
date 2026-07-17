extends Node
## Camera shake by jittering the bound target's position. Use shake(intensity, duration).

var _target: Node2D
var _original_position := Vector2.ZERO
var _shake_time := 0.0
var _shake_intensity := 0.0
var _phase := 0.0
var _active := false

func bind(target: Node2D) -> void:
	_target = target
	if _target:
		_original_position = _target.position

func unbind() -> void:
	if _target and _active:
		_target.position = _original_position
	_target = null
	_active = false
	_shake_time = 0.0

func shake(intensity: float, duration: float) -> void:
	if _target == null:
		return
	if SettingsManager.reduced_effects_enabled():
		intensity *= 0.28
		duration *= 0.60
		if intensity < 0.75 or duration < 0.025:
			return
	if intensity > _shake_intensity or _shake_time < duration * 0.4:
		_shake_intensity = intensity
	if duration > _shake_time:
		_shake_time = duration
	if not _active:
		_original_position = _target.position
		_active = true

func _process(delta: float) -> void:
	if _target == null or _shake_time <= 0.0:
		if _active and _target:
			_target.position = _original_position
		_active = false
		return
	_shake_time -= delta
	_phase += delta * 60.0
	var decay := clampf(_shake_time / 0.25, 0.0, 1.0)
	var offset := Vector2(sin(_phase * 7.3), cos(_phase * 9.1)) * _shake_intensity * decay
	_target.position = _original_position + offset
	if _shake_time <= 0.0:
		_target.position = _original_position
		_active = false
