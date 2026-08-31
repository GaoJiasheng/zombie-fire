class_name ChallengeRules
extends RefCounted

const FALLBACK := {
	"id": "challenge_default",
	"name": "高压尸潮",
	"summary": "敌群更强，突破伤害提高",
	"counter_hint": "围绕本关主弱点配装，并优先控制贴近防线的敌人。",
	"hp_mult": 1.5,
	"speed_mult": 1.0,
	"breach_damage_mult": 1.0,
	"mechanic_rate_mult": 1.0,
	"recommended_power_mult": 1.5,
}

static func for_level(level_id: String, table: Variant) -> Dictionary:
	var level_number := int(level_id.trim_prefix("level_"))
	var chapter := clampi(int(floor(float(maxi(level_number, 1) - 1) / 10.0)) + 1, 1, 10)
	if table is Dictionary:
		var chapters_var: Variant = table.get("chapters", table)
		var row_var: Variant = chapters_var.get("chapter_%02d" % chapter, {}) if chapters_var is Dictionary else {}
		if row_var is Dictionary and not row_var.is_empty():
			var result := _merged(row_var)
			var curve_var: Variant = table.get("curve", {})
			if curve_var is Dictionary and not curve_var.is_empty():
				_apply_curve(result, level_number, curve_var)
			return result
	return FALLBACK.duplicate(true)

static func _apply_curve(result: Dictionary, level_number: int, curve: Dictionary) -> void:
	var budget := _curve_budget(level_number, curve)
	var exponents := _curve_exponents(level_number, curve)
	result["hp_mult"] = budget
	result["speed_mult"] = pow(budget, float(exponents.get("speed", 0.20)))
	result["breach_damage_mult"] = pow(budget, float(exponents.get("breach", 0.40)))
	result["mechanic_rate_mult"] = pow(budget, float(exponents.get("mechanic", 0.40)))
	result["recommended_power_mult"] = budget
	result["reference_fixture"] = _reference_fixture(level_number, curve)

static func _curve_budget(level_number: int, curve: Dictionary) -> float:
	var anchors: Array = curve.get("anchors", [])
	if anchors.is_empty():
		return 1.0
	var first: Dictionary = anchors[0]
	if level_number <= int(first.get("level", 1)):
		return float(first.get("k", 1.0))
	for index in range(1, anchors.size()):
		var right: Dictionary = anchors[index]
		if level_number > int(right.get("level", 99)):
			continue
		var left: Dictionary = anchors[index - 1]
		var span := maxf(float(int(right.get("level", 99)) - int(left.get("level", 1))), 1.0)
		var t := clampf(float(level_number - int(left.get("level", 1))) / span, 0.0, 1.0)
		if str(curve.get("shape", "")) == "piecewise_smoothstep":
			t = 3.0 * t * t - 2.0 * t * t * t
		return lerpf(float(left.get("k", 1.0)), float(right.get("k", 1.0)), t)
	return float((anchors[-1] as Dictionary).get("k", 1.0))

static func _curve_exponents(level_number: int, curve: Dictionary) -> Dictionary:
	var anchors: Array = curve.get("line_pressure_exponents", {}).get("anchors", [])
	if anchors.is_empty():
		return {"speed": 0.2, "breach": 0.4, "mechanic": 0.4}
	var first: Dictionary = anchors[0]
	if level_number <= int(first.get("level", 1)):
		return first
	for index in range(1, anchors.size()):
		var right: Dictionary = anchors[index]
		if level_number > int(right.get("level", 99)):
			continue
		var left: Dictionary = anchors[index - 1]
		var span := maxf(float(int(right.get("level", 99)) - int(left.get("level", 1))), 1.0)
		var t := clampf(float(level_number - int(left.get("level", 1))) / span, 0.0, 1.0)
		return {
			"speed": lerpf(float(left.get("speed", 0.2)), float(right.get("speed", 0.2)), t),
			"breach": lerpf(float(left.get("breach", 0.4)), float(right.get("breach", 0.4)), t),
			"mechanic": lerpf(float(left.get("mechanic", 0.4)), float(right.get("mechanic", 0.4)), t),
		}
	return anchors[-1]

static func _reference_fixture(level_number: int, curve: Dictionary) -> String:
	for route_var in curve.get("reference_routes", []):
		if not route_var is Dictionary:
			continue
		var route := route_var as Dictionary
		if level_number >= int(route.get("from", 1)) and level_number <= int(route.get("to", 99)):
			return str(route.get("fixture", ""))
	return ""

static func _merged(row: Dictionary) -> Dictionary:
	var result := FALLBACK.duplicate(true)
	for key in row.keys():
		result[key] = row[key]
	return result

static func headline(rule: Dictionary) -> String:
	return "%s · %s" % [str(rule.get("name", FALLBACK["name"])), str(rule.get("summary", FALLBACK["summary"]))]

static func pressure_text(rule: Dictionary) -> String:
	var parts: Array[String] = []
	_append_delta(parts, "生命", float(rule.get("hp_mult", 1.0)))
	_append_delta(parts, "移速", float(rule.get("speed_mult", 1.0)))
	_append_delta(parts, "突破", float(rule.get("breach_damage_mult", 1.0)))
	_append_delta(parts, "机制频率", float(rule.get("mechanic_rate_mult", 1.0)))
	return " / ".join(parts)

static func _append_delta(parts: Array[String], label: String, multiplier: float) -> void:
	var percent := int(round((multiplier - 1.0) * 100.0))
	if percent != 0:
		parts.append("%s %+d%%" % [label, percent])
