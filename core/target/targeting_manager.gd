class_name TargetingManager
extends Node

var locked_enemy: Node2D
var strategy := "breach"

func choose_target(enemies: Array[Node], turret_pos: Vector2) -> Node2D:
	if is_instance_valid(locked_enemy):
		return locked_enemy
	locked_enemy = null
	var best: Node2D
	var best_score := -INF
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.has_method("targeting_snapshot"):
			continue
		var snap: Dictionary = enemy.targeting_snapshot()
		var score := score_enemy(snap, turret_pos)
		if score > best_score:
			best_score = score
			best = enemy
	return best

func lock_enemy(enemy: Node2D) -> void:
	locked_enemy = enemy

func clear_lock() -> void:
	locked_enemy = null

func has_lock() -> bool:
	return is_instance_valid(locked_enemy)

func score_enemy(snap: Dictionary, turret_pos: Vector2) -> float:
	var score := 0.0
	var y_ratio := clampf(float(snap.get("y", 0.0)) / 1500.0, 0.0, 1.0)
	var line_pressure := y_ratio * 140.0 + y_ratio * y_ratio * 180.0 + y_ratio * y_ratio * y_ratio * 220.0
	if y_ratio >= 0.72:
		line_pressure += 70.0
	if y_ratio >= 0.86:
		line_pressure += 120.0
	score += line_pressure
	score += float(snap.get("breach_damage", 1.0)) * 3.0
	if snap.get("elite", false) or snap.get("boss", false):
		score += 28.0 + y_ratio * 22.0
	if snap.get("threat_tags", []).has("breach"):
		score += 20.0 + y_ratio * 35.0
	match strategy:
		"elite":
			if snap.get("elite", false) or snap.get("boss", false):
				score += 60.0
		"low_hp":
			score += (1.0 - snap.get("hp_ratio", 1.0)) * 35.0
		"nearest":
			score -= snap.get("position", turret_pos).distance_to(turret_pos) * 0.02
		"breach":
			score += y_ratio * 90.0 + y_ratio * y_ratio * 110.0
	return score
