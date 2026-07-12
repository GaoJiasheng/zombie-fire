extends Node
## Hit stop / hit pause. Briefly slows the engine to make impactful hits feel weighty.
## Usage: await HitStop.pulse(0.06) inside any function; it will restore time_scale to 1.0.

const MIN_SCALE := 0.04
const DEFAULT_SCALE := 0.06

var _cooldown := 0.0
## 顿帧结束后要恢复到的"正常"速度——战斗加速功能会把这个设成当前选择的
## 倍速(1x/2x/5x)，不能写死恢复成 1.0，否则每次顿帧都会把加速悄悄打回原速。
var target_scale := 1.0

func pulse(duration: float = DEFAULT_SCALE) -> void:
	if _cooldown > 0.0:
		return
	_cooldown = 0.16
	Engine.time_scale = MIN_SCALE
	var tree := get_tree()
	if tree == null:
		# 不在场景树里(节点已经/正要被销毁)，说明是收尾场景而不是正常战斗中的
		# 顿帧——这时候恢复到引擎真正的静息态 1.0，而不是可能已经过期的
		# target_scale，否则离开战斗时会把上一局选的倍速错误地带出战斗场景。
		Engine.time_scale = 1.0
		return
	var t := tree.create_timer(duration, true, false, true)
	await t.timeout
	if is_inside_tree():
		Engine.time_scale = target_scale

func _exit_tree() -> void:
	# 同上：这是节点被销毁时的兜底(防止顿帧进行到一半时突然离场，导致
	# time_scale 卡在 MIN_SCALE 出不来)，只在明显还卡在慢动作里时才纠正，
	# 且纠正到 1.0 而不是 target_scale——离开战斗时 main.gd 已经把
	# time_scale 设回 1.0，这里不该用可能已经过期的战斗倍速去覆盖它。
	if Engine.time_scale < MIN_SCALE + 0.01:
		Engine.time_scale = 1.0

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
