class_name StarRules
extends RefCounted

# Single source of truth for the victory star rating (design/24 Phase 1).
# Before this existed the runtime hardcoded "3 stars requires a full base"
# while tools/simulate_balance.py rated levels on a leak budget, so the whole
# 99-level campaign was tuned against a rule the game never applied. Every
# consumer - battle resolution, the result screen and the loadout briefing -
# now reads data/economy.json.star_thresholds through here, and no caller may
# spell the numbers out again.

const DEFAULTS := {
	"three_star_hp_ratio": 0.7,
	"two_star_hp_ratio": 0.35,
}

static func thresholds(economy: Variant) -> Dictionary:
	var result := DEFAULTS.duplicate()
	if economy is Dictionary:
		var row_var: Variant = (economy as Dictionary).get("star_thresholds", {})
		if row_var is Dictionary:
			var row: Dictionary = row_var
			for key in DEFAULTS.keys():
				if row.has(key):
					result[key] = clampf(float(row[key]), 0.0, 1.0)
	if float(result["two_star_hp_ratio"]) > float(result["three_star_hp_ratio"]):
		result["two_star_hp_ratio"] = result["three_star_hp_ratio"]
	return result

static func three_star_ratio(economy: Variant) -> float:
	return float(thresholds(economy)["three_star_hp_ratio"])

static func two_star_ratio(economy: Variant) -> float:
	return float(thresholds(economy)["two_star_hp_ratio"])

## Stars awarded for a victory that ended with `hp_ratio` of the base line intact.
static func stars_for_hp_ratio(hp_ratio: float, economy: Variant) -> int:
	var rule := thresholds(economy)
	if hp_ratio >= float(rule["three_star_hp_ratio"]):
		return 3
	if hp_ratio >= float(rule["two_star_hp_ratio"]):
		return 2
	return 1

## Player-facing one-liner, e.g. "三星 防线 ≥70%  ·  两星 ≥35%".
static func hint_text(economy: Variant) -> String:
	var rule := thresholds(economy)
	return "三星 防线 ≥%d%%  ·  两星 ≥%d%%" % [
		int(round(float(rule["three_star_hp_ratio"]) * 100.0)),
		int(round(float(rule["two_star_hp_ratio"]) * 100.0)),
	]
