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
		var row_var: Variant = table.get("chapter_%02d" % chapter, {})
		if row_var is Dictionary and not row_var.is_empty():
			return _merged(row_var)
	return FALLBACK.duplicate(true)

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
