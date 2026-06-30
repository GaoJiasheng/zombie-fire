extends RefCounted
class_name SkillEffectText

const KEY_ORDER := [
	"split",
	"falloff",
	"pierce",
	"extra_projectiles",
	"spread",
	"chain",
	"homing",
	"slow",
	"y_min",
	"burn",
	"poison",
	"dmg_mult",
	"fire_rate_mult",
	"crit_add",
	"crit_dmg",
	"gold_mult",
	"shields",
	"reroll",
]

static func value_text(value: Variant) -> String:
	if not _is_numeric_value(value):
		if value is bool:
			return "开启" if bool(value) else "关闭"
		if value is Array:
			var parts: Array[String] = []
			for item in value:
				parts.append(str(item))
			return " / ".join(parts)
		return str(value)
	var numeric := float(value)
	if absf(numeric) < 1.0 and not is_equal_approx(numeric, 0.0):
		return "%d%%" % int(round(numeric * 100.0))
	if absf(numeric - round(numeric)) > 0.001:
		return "%.1f" % numeric
	return "%d" % int(round(numeric))

static func _is_numeric_value(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT

static func signed_value_text(delta: float) -> String:
	if absf(delta) < 1.0:
		return "%+d%%" % int(round(delta * 100.0))
	if absf(delta - round(delta)) > 0.001:
		return "%+.1f" % delta
	return "%+d" % int(round(delta))

static func key_name(key: String) -> String:
	match key:
		"split":
			return "分裂"
		"falloff":
			return "衰减"
		"pierce":
			return "穿透"
		"dmg_mult":
			return "伤害"
		"fire_rate_mult":
			return "射速"
		"chain":
			return "连锁"
		"slow":
			return "减速"
		"burn":
			return "灼烧"
		"poison":
			return "中毒"
		"crit_add":
			return "暴击率"
		"crit_dmg":
			return "暴击伤害"
		"gold_mult":
			return "金币"
		"shields":
			return "护盾"
		"reroll":
			return "重摇"
		"extra_projectiles":
			return "弹丸"
		"spread":
			return "散射"
		"homing":
			return "追踪"
		"y_min":
			return "范围"
		_:
			return key

static func effect_for_level(row: Dictionary, lv: int) -> Dictionary:
	for level in row.get("levels", []):
		if int(level.get("lv", 0)) == lv:
			return level.get("effect", {})
	return {}

static func format_effect(effect: Dictionary) -> String:
	if effect.is_empty():
		return "无额外数值"
	var parts: Array[String] = []
	var seen := {}
	for key in KEY_ORDER:
		if not effect.has(key):
			continue
		parts.append("%s %s" % [key_name(key), value_text(effect.get(key))])
		seen[key] = true
	for key in effect.keys():
		if seen.has(key):
			continue
		parts.append("%s %s" % [key_name(str(key)), value_text(effect.get(key))])
	return " · ".join(parts)

static func format_level_line(lv: int, effect: Dictionary) -> String:
	return "等级%d  %s" % [lv, format_effect(effect)]

static func format_all_levels(row: Dictionary, highlight_lv: int = -1) -> String:
	var lines: Array[String] = []
	for level in row.get("levels", []):
		var lv := int(level.get("lv", lines.size() + 1))
		var prefix := "▶ " if lv == highlight_lv else "   "
		lines.append("%s%s" % [prefix, format_level_line(lv, level.get("effect", {}))])
	return "\n".join(lines)

static func format_delta(prev: Dictionary, next: Dictionary) -> String:
	var parts: Array[String] = []
	var keys := {}
	for key in prev.keys():
		keys[key] = true
	for key in next.keys():
		keys[key] = true
	for key in KEY_ORDER:
		if not keys.has(key):
			continue
		var before_value: Variant = prev.get(key, 0.0)
		var after_value: Variant = next.get(key, 0.0)
		if before_value == after_value:
			continue
		if _is_numeric_value(before_value) and _is_numeric_value(after_value):
			parts.append("%s %s" % [key_name(key), signed_value_text(float(after_value) - float(before_value))])
		else:
			parts.append("%s %s → %s" % [key_name(key), value_text(before_value), value_text(after_value)])
	for key in keys.keys():
		if KEY_ORDER.has(key):
			continue
		var before_value: Variant = prev.get(key, 0.0)
		var after_value: Variant = next.get(key, 0.0)
		if before_value == after_value:
			continue
		if _is_numeric_value(before_value) and _is_numeric_value(after_value):
			parts.append("%s %s" % [key_name(str(key)), signed_value_text(float(after_value) - float(before_value))])
		else:
			parts.append("%s %s → %s" % [key_name(str(key)), value_text(before_value), value_text(after_value)])
	return " · ".join(parts)

static func format_offer_block(row: Dictionary, target_lv: int, current_lv: int = 0) -> String:
	var target := effect_for_level(row, target_lv)
	var lines: Array[String] = ["本级数值：%s" % format_effect(target)]
	if current_lv > 0 and current_lv < target_lv:
		var delta := format_delta(effect_for_level(row, current_lv), target)
		if delta != "":
			lines.append("较当前：%s" % delta)
	return "\n".join(lines)
