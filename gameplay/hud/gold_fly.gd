extends Node
## Short reward flash. The battle already updates the HUD number directly; this
## only marks the kill position and bumps the gold counter without cluttering lanes.

const FLASH_DURATION := 0.34
const MAX_ACTIVE_FX := 10

var _battle: Node2D
var _gold_label: Label
var _gold_icon: TextureRect
var _template: Texture2D
var _active_fx: Array[Node] = []

func bind(battle: Node2D, gold_label: Label, gold_icon: TextureRect) -> void:
	_battle = battle
	_gold_label = gold_label
	_gold_icon = gold_icon
	_template = load("res://assets/production/sprites/ui/icon_currency_gold.png")

func fly_to_hud(from_world: Vector2, amount: int) -> void:
	if _battle == null or _gold_label == null or _template == null:
		return
	_trim_active_fx()
	if _active_fx.size() >= MAX_ACTIVE_FX:
		_bump_label()
		return
	var coin := Sprite2D.new()
	coin.texture = _template
	coin.scale = Vector2(0.35, 0.35)
	coin.modulate = Color(1, 1, 1, 0.95)
	coin.global_position = from_world
	_battle.add_child(coin)
	_track_fx(coin)

	var ring := Sprite2D.new()
	ring.texture = _template
	ring.scale = Vector2(0.18, 0.18)
	ring.modulate = Color(1.0, 0.82, 0.22, 0.34)
	ring.global_position = from_world
	_battle.add_child(ring)
	_track_fx(ring)

	var tween := coin.create_tween()
	tween.set_parallel(true)
	tween.tween_property(coin, "global_position", from_world + Vector2(0, -22), FLASH_DURATION)
	tween.tween_property(coin, "scale", Vector2(0.52, 0.52), FLASH_DURATION * 0.7)
	tween.tween_property(coin, "modulate:a", 0.0, FLASH_DURATION)
	tween.set_parallel(false)
	tween.tween_callback(func():
		_active_fx.erase(coin)
		coin.queue_free()
		_bump_label()
	)
	var ring_tween := ring.create_tween()
	ring_tween.parallel().tween_property(ring, "scale", Vector2(0.9, 0.9), FLASH_DURATION)
	ring_tween.parallel().tween_property(ring, "modulate:a", 0.0, FLASH_DURATION)
	ring_tween.tween_callback(func() -> void:
		_active_fx.erase(ring)
		ring.queue_free()
	)

func _track_fx(node: Node) -> void:
	_active_fx.append(node)

func _trim_active_fx() -> void:
	_active_fx = _active_fx.filter(func(node: Node) -> bool:
		return is_instance_valid(node) and not node.is_queued_for_deletion()
	)

func _bump_label() -> void:
	if _gold_label == null:
		return
	var tween := _gold_label.create_tween()
	tween.tween_property(_gold_label, "scale", Vector2(1.18, 1.18), 0.06)
	tween.tween_property(_gold_label, "scale", Vector2(1.0, 1.0), 0.12)
