extends Node2D

signal fired(origin: Vector2, direction: Vector2)

const MUZZLE_LOCAL_OFFSETS := {
	"weapon_autocannon": Vector2(34, -204),
	"weapon_cryocannon": Vector2(-160, -36),
	"weapon_flamethrower": Vector2(-154, -38),
	"weapon_plasmacannon": Vector2(-158, -44),
	"weapon_railgun": Vector2(-190, 54),
	"weapon_scattergun": Vector2(-145, -34),
	"weapon_teslacoil": Vector2(-28, -205),
	"weapon_venomlauncher": Vector2(-158, -48),
}
const FIRE_RATE_MULTIPLIER := 0.5

var target_point := Vector2(540, 600)
var fire_rate := 4.0
var cooldown := 0.0
var turn_speed := 9.0
var damage_mult := 1.0
var weapon_id := "weapon_autocannon"
var muzzle_local_position := Vector2(34, -204)
var idle_frames: Array[Texture2D] = []
var recoil_frames: Array[Texture2D] = []
var anim_time := 0.0
var recoil_time := 0.0
var frame_index := 0

func setup(weapon: Dictionary, weapon_level := 1) -> void:
	weapon_id = _weapon_id_from_turret(str(weapon.get("turret", "")))
	fire_rate = float(weapon.get("fire_rate", 4.0)) * (1.0 + 0.025 * float(max(weapon_level - 1, 0))) * FIRE_RATE_MULTIPLIER
	damage_mult = 1.0 + 0.08 * float(max(weapon_level - 1, 0))
	turn_speed *= 1.0 + 0.006 * float(max(weapon_level - 1, 0))
	$Sprite.texture = load(weapon.get("turret", "res://assets/sprites/weapons/weapon_autocannon_turret.png"))
	$Sprite.scale = Vector2.ONE * (1.0 + clampf(float(weapon_level - 1) * 0.0035, 0.0, 0.14))
	$Sprite.modulate = _level_tint(weapon_level)
	_load_animation_frames()
	_update_muzzle_position()

func aim_at(point: Vector2) -> void:
	target_point = point

func _physics_process(delta: float) -> void:
	var aim_vector := target_point - global_position
	if aim_vector.length_squared() <= 1.0:
		return
	var desired := aim_vector.angle() - muzzle_local_position.angle()
	rotation = lerp_angle(rotation, desired, min(turn_speed * delta, 1.0))
	cooldown -= delta
	if cooldown <= 0.0:
		cooldown = 1.0 / fire_rate
		_play_recoil()
		var direction: Vector2 = (target_point - $Muzzle.global_position).normalized()
		fired.emit($Muzzle.global_position, direction)
	_update_animation(delta)

func _play_recoil() -> void:
	recoil_time = 0.18
	anim_time = 0.0
	frame_index = 0

func _load_animation_frames() -> void:
	var base := "res://assets/production/sprites/animations/weapons/%s/%s" % [weapon_id, weapon_id]
	idle_frames = _load_frame_set(base, "idle", 3)
	recoil_frames = _load_frame_set(base, "recoil", 4)
	if not idle_frames.is_empty():
		$Sprite.texture = idle_frames[0]

func _update_muzzle_position() -> void:
	muzzle_local_position = MUZZLE_LOCAL_OFFSETS.get(weapon_id, Vector2(0, -204))
	$Muzzle.position = muzzle_local_position * $Sprite.scale.x

func _load_frame_set(base: String, anim: String, max_count: int) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	for i in range(1, max_count + 1):
		var path := "%s_%s_%02d.png" % [base, anim, i]
		if ResourceLoader.exists(path):
			var tex := load(path) as Texture2D
			if tex:
				frames.append(tex)
	return frames

func _update_animation(delta: float) -> void:
	var frames := recoil_frames if recoil_time > 0.0 else idle_frames
	if frames.is_empty():
		return
	anim_time += delta
	if recoil_time > 0.0:
		recoil_time -= delta
	var fps := 20.0 if recoil_time > 0.0 else 7.0
	var next_frame := int(anim_time * fps)
	if recoil_time > 0.0:
		next_frame = mini(next_frame, frames.size() - 1)
	else:
		next_frame = next_frame % frames.size()
	if next_frame != frame_index:
		frame_index = next_frame
		$Sprite.texture = frames[frame_index]

func _weapon_id_from_turret(path: String) -> String:
	var name := path.get_file().get_basename()
	return name.replace("_turret", "") if name != "" else "weapon_autocannon"

func _level_tint(level: int) -> Color:
	if level >= 25:
		return Color(1.0, 0.84, 0.38, 1.0)
	if level >= 15:
		return Color(0.74, 0.92, 1.0, 1.0)
	if level >= 8:
		return Color(0.82, 1.0, 0.74, 1.0)
	return Color.WHITE
