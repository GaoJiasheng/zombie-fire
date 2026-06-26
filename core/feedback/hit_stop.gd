extends Node
## Hit stop / hit pause. Briefly slows the engine to make impactful hits feel weighty.
## Usage: await HitStop.pulse(0.06) inside any function; it will restore time_scale to 1.0.

const MIN_SCALE := 0.04
const DEFAULT_SCALE := 0.06

var _cooldown := 0.0

func pulse(duration: float = DEFAULT_SCALE) -> void:
	if _cooldown > 0.0:
		return
	_cooldown = 0.16
	Engine.time_scale = MIN_SCALE
	var t := get_tree().create_timer(duration, true, false, true)
	await t.timeout
	Engine.time_scale = 1.0

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
