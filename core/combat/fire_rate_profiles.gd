extends RefCounted

const DEFAULT_PROFILE_ID := "control"

static func table(economy: Dictionary) -> Dictionary:
	var value: Variant = economy.get("fire_rate_profiles", {})
	return value if value is Dictionary else {}

static func profile(economy: Dictionary, profile_id: String) -> Dictionary:
	var profile_table := table(economy)
	var profiles_value: Variant = profile_table.get("profiles", {})
	var profiles: Dictionary = profiles_value if profiles_value is Dictionary else {}
	var normalized := profile_id if profiles.has(profile_id) else str(profile_table.get("default", DEFAULT_PROFILE_ID))
	var value: Variant = profiles.get(normalized, profiles.get(DEFAULT_PROFILE_ID, {}))
	return value if value is Dictionary else {}

static func profile_ids(economy: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var profile_table := table(economy)
	for value in profile_table.get("order", []):
		var profile_id := str(value)
		if not profile_id.is_empty() and profile(economy, profile_id).size() > 0:
			result.append(profile_id)
	if result.is_empty():
		result.append(DEFAULT_PROFILE_ID)
	return result

static func salvo_multiplier(economy: Dictionary, profile_id: String, level: int, fallback := 1.0) -> float:
	if level <= 0:
		return 1.0
	var values: Array = profile(economy, profile_id).get("salvo_fire_rate_mult", [])
	if values.is_empty():
		return fallback
	var index := clampi(level - 1, 0, values.size() - 1)
	return 1.0 + float(values[index])

static func chip_multiplier(economy: Dictionary, profile_id: String, intrinsic_value: float, level: int) -> float:
	var row := profile(economy, profile_id)
	var intrinsic_scale := float(row.get("chip_intrinsic_scale", 1.0))
	var level_bonus := float(row.get("chip_level_bonus_per_level", 0.01))
	return (1.0 + intrinsic_value * intrinsic_scale) * (1.0 + level_bonus * float(maxi(level - 1, 0)))

static func pet_multiplier(economy: Dictionary, profile_id: String, stat_value: float) -> float:
	var scale := float(profile(economy, profile_id).get("pet_fire_rate_scale", 1.0))
	return 1.0 + stat_value * scale

static func barrage_multiplier(
	economy: Dictionary,
	profile_id: String,
	active: Dictionary,
	character_level: int,
	growth_rank: int,
	sig_skill_level: int,
) -> float:
	var row := profile(economy, profile_id)
	var authored_base := float(active.get("barrage_fire_rate_mult", 1.0))
	var base := float(row.get("barrage_fire_rate_mult", authored_base))
	var rank_bonus := float(row.get("barrage_rank_bonus", active.get("rank_fire_rate_bonus", 0.0))) * float(growth_rank)
	var level_scale := float(row.get("barrage_level_growth_scale", 1.0))
	var level_bonus := float(active.get("level_fire_rate_growth", 0.0)) * float(maxi(character_level - 1, 0)) * level_scale
	var sig_bonus := float(active.get("sig_level_fire_rate_bonus", 0.0)) * float(sig_skill_level) * level_scale
	return maxf(1.0, base + rank_bonus + level_bonus + sig_bonus)

static func overload_multiplier(economy: Dictionary, profile_id: String) -> float:
	return maxf(1.0, float(profile(economy, profile_id).get("overload_fire_rate_mult", 1.5)))

static func capped_fire_rate(economy: Dictionary, profile_id: String, raw_fire_rate: float, authored_weapon_base: float) -> float:
	var cap_ratio := float(profile(economy, profile_id).get("global_weapon_base_cap", 0.0))
	if cap_ratio <= 0.0:
		return raw_fire_rate
	return minf(raw_fire_rate, maxf(authored_weapon_base, 0.01) * cap_ratio)

static func shot_damage_compensation(economy: Dictionary, profile_id: String, control_fire_rate: float, actual_fire_rate: float) -> float:
	var share := float(profile(economy, profile_id).get("removed_dps_compensation", 0.0))
	if share <= 0.0 or actual_fire_rate <= 0.0 or control_fire_rate <= actual_fire_rate:
		return 1.0
	return 1.0 + (control_fire_rate / actual_fire_rate - 1.0) * share

static func per_shot_status_normalization(control_fire_rate: float, actual_fire_rate: float) -> float:
	if actual_fire_rate <= 0.0:
		return 1.0
	return control_fire_rate / actual_fire_rate
