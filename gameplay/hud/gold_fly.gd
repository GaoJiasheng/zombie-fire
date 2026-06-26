extends Node
## Gold fly-to-HUD animation. Spawns a sprite that tweens to the HUD gold counter,
## and bumps the counter when it lands.

const FLY_DURATION := 0.55

var _battle: Node2D
var _gold_label: Label
var _gold_icon: TextureRect
var _template: Texture2D

func bind(battle: Node2D, gold_label: Label, gold_icon: TextureRect) -> void:
	_battle = battle
	_gold_label = gold_label
	_gold_icon = gold_icon
	_template = load("res://assets/sprites/ui/icon_currency_gold.png")

func fly_to_hud(from_world: Vector2, amount: int) -> void:
	if _battle == null or _gold_label == null or _template == null:
		return
	var coin := Sprite2D.new()
	coin.texture = _template
	coin.scale = Vector2(0.6, 0.6)
	coin.modulate = Color(1, 1, 1, 0.95)
	coin.global_position = from_world
	_battle.add_child(coin)
	var target_world := _hud_target_world()
	var tween := coin.create_tween()
	tween.set_parallel(true)
	var mid := (from_world + target_world) * 0.5
	mid.y -= 120.0
	tween.tween_property(coin, "position", mid, FLY_DURATION * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(coin, "position", _battle.to_local(target_world), FLY_DURATION * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(coin, "scale", Vector2(0.3, 0.3), FLY_DURATION)
	tween.tween_property(coin, "modulate:a", 0.0, FLY_DURATION * 0.5)
	tween.set_parallel(false)
	tween.tween_callback(func():
		coin.queue_free()
		_bump_label()
	)

func _hud_target_world() -> Vector2:
	if _gold_icon == null:
		return Vector2(540, 1850)
	return _gold_icon.global_position

func _bump_label() -> void:
	if _gold_label == null:
		return
	var tween := _gold_label.create_tween()
	tween.tween_property(_gold_label, "scale", Vector2(1.18, 1.18), 0.06)
	tween.tween_property(_gold_label, "scale", Vector2(1.0, 1.0), 0.12)
