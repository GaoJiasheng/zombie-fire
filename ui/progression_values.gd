extends RefCounted

# Read-only UI snapshots. Never equip an item, mutate a save or run a battle.
const UiKit := preload("res://ui/ui_kit.gd")
const Effects := preload("res://core/data/skill_effect_text.gd")

static func _loc(zh: String, en: String) -> String:
	return en if LocalizationManager.is_english() else zh

static func entry(label: String, value: float, unit := "number", lower := false) -> Dictionary:
	return {"label": label, "value": value, "unit": unit, "lower": lower}

static func hero_attribute(row: Dictionary, level: int, stat: String) -> float:
	var base_key := "base_atk" if stat == "attack" else "base_hp"
	var growth_key := "atk_growth" if stat == "attack" else "hp_growth"
	return float(row.get(base_key, 100)) * (1.0 + float(row.get(growth_key, 0.0)) * 0.45 * float(maxi(level - 1, 0)))

static func snapshot(table: String, item_id: String, level := -1) -> Dictionary:
	var source_table := "characters" if table == "signature" else table
	var row := DataLoader.get_row(source_table, item_id)
	if level < 0:
		level = SaveManager.get_sig_skill_level(item_id) if table == "signature" else (SaveManager.get_skill_base_level(item_id) if table == "skills" else SaveManager.get_item_level(item_id))
	var result := {"level": level, "stats": {}, "name": DataLoader.tr_key(str(row.get("name_key", item_id))), "icon": UiKit.item_icon_path(source_table, item_id, row), "note": ""}
	var stats: Dictionary = result.stats
	# These pure runtime methods require no scene children or _ready(). Keeping
	# signature/chip/pet snapshots on their actual methods avoids stale previews.
	var runtime: Node = load("res://gameplay/battle/battle.gd").new()
	runtime.character_id = item_id
	runtime.character_data = row
	runtime.character_level = SaveManager.get_item_level(item_id) if table == "signature" else level
	runtime.chip_data = row
	runtime.chip_level = level
	runtime.pet_data = row
	runtime.pet_level = level
	match table:
		"characters":
			result.icon = UiKit.character_bust_path(row)
			stats.attack = entry(_loc("角色攻击", "Hero attack"), hero_attribute(row, level, "attack"))
			stats.hp = entry(_loc("角色生命", "Hero health"), hero_attribute(row, level, "hp"))
			var element := str(row.get("bullet_affinity", {}).get("element", "physical"))
			stats.affinity = entry(_loc("亲和弹种伤害倍率", "Affinity ammo damage scale"), runtime._character_bullet_damage_multiplier(element), "mult")
			stats.affinity_pierce = entry(_loc("亲和弹种额外穿透", "Affinity ammo extra pierce"), runtime._character_pierce_bonus(element), "count")
			stats.affinity_chain = entry(_loc("亲和弹种额外连锁", "Affinity ammo extra chains"), runtime._character_chain_bonus_for(element), "count")
			if str(row.get("passive", "")) == "breach_guard":
				stats.breach = entry(_loc("角色漏怪减伤", "Hero breach reduction"), 1.0 - 0.82 * (0.88 if level >= 15 else 1.0), "percent")
			_add_signature(stats, runtime, row)
			result.note = _loc("角色自身成长；最终战斗数值还受装备、卡牌和关卡影响。专属技能等级不随角色升级。", "Hero growth only; equipment, cards and stages also affect combat. Signature skill level is upgraded separately.")
		"signature":
			var active: Dictionary = row.get("active_skill", {})
			var skill_id := str(active.get("id", ""))
			result.name = str(TranslationServer.translate(preload("res://core/data/character_skill_text.gd").signature_info(skill_id).name))
			result.icon = "res://assets/production/sprites/ui/" + skill_id + "_icon.png"
			_add_signature(stats, runtime, row)
			result.note = _loc("专属技能独立强化；伤害倍率基于当前角色成长，不代表整套总伤害。", "Signature skill upgrade; its damage scale includes current hero growth, not total loadout damage.")
		"weapons":
			var growth_level := SaveManager.weapon_standard_growth_level_from_row(row, level)
			var profile := SettingsManager.get_fire_rate_profile()
			stats.damage = entry(_loc("武器伤害系数", "Weapon damage coefficient"), float(row.get("base_atk_coef", 1.0)) * SaveManager.weapon_damage_multiplier_at_level(row, level, profile), "mult")
			stats.rate = entry(_loc("基础射速", "Base fire rate"), float(row.get("fire_rate", 1.0)) * (1.0 + 0.025 * float(growth_level - 1)), "rate")
			stats.pellets = entry(_loc("固有弹丸", "Innate pellets"), SaveManager.weapon_pellet_count_from_row(row, level), "count")
			result.note = _loc("武器自身数值，不含人物、芯片与局内增益；实战射速还受当前攻速档位限制。", "Weapon-only values, before hero, chip and run bonuses. Combat cadence also follows the current fire-rate profile.")
		"armors":
			var progress := clampf(float(level - 1) / float(maxi(2, int(row.get("max_level", 35))) - 1), 0, 1)
			var hp := float(row.get("hp_mult", 1)) * (1.0 + float(row.get("level_hp_growth", 0.018)) * float(level - 1))
			hp *= 1.0 + float(row.get("endgame_hp_growth_bonus", 0)) * pow(progress, maxf(1, float(row.get("endgame_growth_curve", 1))))
			stats.hp = entry(_loc("护甲生命倍率", "Armor health multiplier"), hp, "mult")
			stats.shield = entry(_loc("漏怪护盾", "Breach shields"), float(row.get("breach_shield", 0)), "count")
		"chips":
			var keys: Array = row.get("secondary_stats", {}).keys()
			keys.push_front(str(row.get("stat", "")))
			for key in keys:
				stats[key] = entry(stat_name(key), runtime._chip_value(key), "count" if key == "pierce_bonus" else "percent")
			stats.cadence = entry(_loc("芯片等级射速成长", "Chip-level cadence growth"), float(preload("res://core/combat/fire_rate_profiles.gd").profile(DataLoader.get_table("economy"), SettingsManager.get_fire_rate_profile()).get("chip_level_bonus_per_level", 0.01)) * float(level - 1), "percent")
		"pets":
			for key in row.get("stat_bonus", {}):
				var value: float = runtime._pet_stat_value(key)
				if key in ["chain_bonus", "pierce_bonus"]:
					value = roundf(value)
				stats[key] = entry(stat_name(key), value, "count" if key in ["chain_bonus", "pierce_bonus"] else "percent")
			for spec in [["damage", "level_damage_growth", "宠物单发伤害", "Pet shot damage", "number"], ["heal_per_wave", "level_heal_growth", "波次固定回血", "Flat wave healing", "number"], ["gold_mult", "level_gold_growth", "回收金币加成", "Salvage gold bonus", "percent"]]:
				if row.has(spec[0]):
					stats["pet_" + spec[0]] = entry(_loc(spec[2], spec[3]), runtime._pet_scaled_value(spec[0], spec[1]), spec[4])
			for spec in [["heal_per_wave_ratio", "level_wave_heal_ratio_growth", "波次生命回复", "Wave health restored"], ["repair_ratio", "level_repair_ratio_growth", "定时维修比例", "Periodic repair"], ["emergency_heal_ratio", "level_emergency_heal_growth", "应急维修比例", "Emergency repair"]]:
				if row.has(spec[0]):
					stats[spec[0]] = entry(_loc(spec[2], spec[3]), runtime._pet_linear_value(spec[0], spec[1]), "percent")
			var skill: Dictionary = row.get("pet_skill", {})
			for spec in [["damage_mult", "level_damage_mult_growth", "技能伤害倍率", "Skill damage scale", "mult"], ["duration", "level_duration_growth", "技能持续", "Skill duration", "seconds"], ["fire_rate_mult", "level_fire_rate_growth", "爆发射速倍率", "Burst cadence", "mult"], ["radius", "level_radius_growth", "技能范围", "Skill radius", "number"], ["status_strength", "level_status_growth", "状态强度", "Status strength", "mult"], ["kill_equivalent", "level_salvage_growth", "波次回收等效击杀", "Wave salvage kill-equivalents", "number"], ["mark_duration", "level_mark_duration_growth", "敕印持续", "Mark duration", "seconds"], ["mark_damage_amp", "level_mark_amp_growth", "敕印追加比例", "Mark damage ratio", "percent"], ["repair_ratio", "level_repair_growth", "技能维修比例", "Skill repair", "percent"]]:
				if skill.has(spec[0]):
					stats["skill_" + spec[0]] = entry(_loc(spec[2], spec[3]), runtime._pet_skill_linear_value(spec[0], spec[1]), spec[4])
			if skill.has("target_count"):
				stats.targets = entry(_loc("技能目标数", "Skill targets"), int(skill.target_count) + floori(float(level - 1) / float(maxi(1, int(skill.get("extra_target_every", 999))))), "count")
		"skills":
			# Permanent Lv0 and Lv1 both offer the card at Lv1 on its first pick.
			var effect := Effects.effect_for_level(row, maxi(1, level))
			for key in effect:
				if key in ["element"]:
					continue
				stats[key] = {"label": str(TranslationServer.translate(Effects.key_name(key))), "text": Effects._value_text_for_key(key, effect[key])}
				if typeof(effect[key]) in [TYPE_FLOAT, TYPE_INT]:
					stats[key]["value"] = float(effect[key])
					stats[key]["lower"] = key == "y_min"
			result.note = _loc("永久起始等级只在战斗中首次选到此卡时生效，不会自动获得技能。", "The permanent starting level applies when you first pick this card in a run; it does not grant the card automatically.")
			if level <= 1:
				result.note += ("\n" + _loc("0→1 是永久养成的第一步；首次选卡原本就是 1 级，本次不虚报额外战斗增益。", "0→1 starts permanent progression. The first pick already grants Lv1, so this step adds no extra combat stats."))
	runtime.free()
	return result

static func _add_signature(stats: Dictionary, runtime: Node, row: Dictionary) -> void:
	var active: Dictionary = row.get("active_skill", {})
	stats.skill_power = entry(_loc("专属技能成长倍率", "Signature growth scale"), runtime._character_active_power_scale(active), "mult")
	stats.cooldown = entry(_loc("专属技能冷却", "Signature cooldown"), runtime._active_skill_cooldown(active), "seconds", true)
	if active.has("sig_level_status_bonus"):
		stats.status = entry(_loc("专属技能状态强度", "Signature status strength"), runtime._active_skill_status_scale(active), "mult")
	if active.has("duration"):
		stats.duration = entry(_loc("技能持续时间", "Skill duration"), runtime._active_skill_duration(active, 5.0 if active.id == "sig_frost_glacier" else float(active.duration)), "seconds")
	match str(active.get("id", "")):
		"sig_vanguard_railvolley":
			stats.volleys = entry(_loc("齐射轮数", "Volley rounds"), runtime._vanguard_railvolley_count(active), "count")
			stats.targets = entry(_loc("每轮目标数", "Targets per volley"), runtime._vanguard_railvolley_target_count(active), "count")
		"sig_blaze_meltdown":
			stats.pulses = entry(_loc("熔爆波次", "Meltdown pulses"), runtime._blaze_meltdown_pulse_count(active), "count")
			if not runtime._blaze_meltdown_uses_battlefield(active):
				stats.radius = entry(_loc("熔爆范围", "Meltdown radius"), runtime._blaze_meltdown_radius(active))
		"sig_frost_glacier":
			stats.waves = entry(_loc("寒潮波次", "Cold waves"), runtime._frost_glacier_wave_count(active), "count")
			stats.slow = entry(_loc("普通敌人减速", "Enemy slow"), 1.0 - runtime._frost_glacier_speed_factor(active, false), "percent")
			stats.boss_slow = entry(_loc("首领减速", "Boss slow"), 1.0 - runtime._frost_glacier_speed_factor(active, true), "percent")
		"sig_volt_storm":
			var targets: int = runtime._volt_storm_max_targets(active)
			stats.targets = entry(_loc("风暴目标上限", "Storm target cap"), targets, "count")
			stats.strikes = entry(_loc("落雷次数", "Lightning strikes"), runtime._volt_storm_strike_count(active, targets), "count")

static func format_value(stat: Dictionary) -> String:
	if stat.has("text"):
		return str(stat.text)
	var value := float(stat.get("value", 0))
	match str(stat.get("unit", "number")):
		"percent": return "%.2f%%" % (value * 100.0)
		"mult": return "%.3f×" % value
		"seconds": return "%.2f s" % value
		"rate": return "%.2f / s" % value
		"count": return str(int(value))
	return "%.2f" % value

static func changes(before: Dictionary, after: Dictionary, acquired := false) -> Array:
	var result := []
	for key in after.stats:
		var next: Dictionary = after.stats[key]
		var prev: Dictionary = before.get("stats", {}).get(key, {})
		if not acquired and prev == next:
			continue
		var positive := true
		if next.has("value") and prev.has("value"):
			if is_equal_approx(next.value, prev.value):
				continue
			positive = (next.value < prev.value) if next.get("lower", false) else (next.value > prev.value)
		result.append({"label": next.label, "before": "" if acquired else format_value(prev), "after": format_value(next), "positive": positive})
	return result

static func stat_name(key: String) -> String:
	var labels := {
		"damage_mult": ["伤害加成", "Damage bonus"], "element_damage_mult": ["元素伤害加成", "Elemental damage bonus"],
		"base_hp_mult": ["生命加成", "Health bonus"], "fire_rate_mult": ["射速加成", "Fire-rate bonus"],
		"crit_rate": ["暴击率加成", "Critical chance bonus"], "gold_mult": ["金币加成", "Gold bonus"],
		"breach_damage_reduction": ["漏怪减伤", "Breach damage reduction"], "slow_strength_mult": ["减速强度加成", "Slow strength bonus"],
		"pierce_bonus": ["额外穿透目标", "Extra pierce targets"], "chain_bonus": ["额外连锁目标", "Extra chain targets"],
		"armor_penetration": ["护甲穿透", "Armor penetration"], "chain_retention": ["连锁伤害保留", "Chain damage retention"],
		"brittle_efficiency": ["脆化效率", "Brittle efficiency"], "burn_efficiency": ["燃烧效率", "Burn efficiency"],
		"combustion_damage_mult": ["燃爆伤害加成", "Combustion damage bonus"], "combustion_stack_efficiency": ["燃爆叠层效率", "Combustion stack efficiency"],
		"judgment_efficiency": ["裁决效率", "Judgment efficiency"], "overload_efficiency": ["过载效率", "Overload efficiency"],
		"shatter_damage_mult": ["碎冰伤害加成", "Shatter damage bonus"], "verdict_damage_mult": ["敕令伤害加成", "Verdict damage bonus"],
	}
	var pair: Array = labels.get(key, [key, key])
	return _loc(pair[0], pair[1])
