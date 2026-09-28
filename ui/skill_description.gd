extends RefCounted

# Existing battle explanation, shared unchanged with the collection codex.
static func short_description(skill_id: String, _level := 1) -> String:
	match skill_id:
		"skill_split_shot":
			return "命中分出小弹，追击附近尸群。"
		"skill_pierce":
			return "子弹穿过前排继续攻击后排；贯穿目标不等于穿透护甲。"
		"skill_multishot":
			return "额外发射弹丸，正面火力明显变宽。"
		"skill_slow_field":
			return "防线前生成大范围减速区，等级越高覆盖越远、减速越强。"
		"skill_homing":
			return "子弹获得轻微追踪，减少高速怪和斜线目标漏枪。"
		"skill_critical":
			return "蓄力打出重击，提高暴击概率、暴击伤害和主弹威力。"
		"skill_barrier":
			return "提高基地生命上限，并立即补上新增防线生命。"
		"skill_gold_rush":
			return "提高本局金币收益，适合滚长期养成。"
		"skill_ricochet":
			return "命中后额外弹射，强化清群和连锁补刀。"
		"skill_salvo":
			return "提高武器攻速，让持续输出更密。"
		"skill_incendiary":
			return "火焰弹药：强化灼烧；物理及适配的付费武器可转火。"
		"skill_cryo":
			return "冰霜弹药：强化减速；物理及适配的付费武器可转冰。"
		"skill_tesla":
			return "闪电弹药：强化连锁；物理及适配的付费武器可转电。"
		"skill_venom":
			return "毒素弹药：强化中毒；物理及适配的付费武器可转毒。"
		"skill_charge_shot":
			return "主弹获得伤害穿透，能把部分伤害打进护甲本体。"
		"skill_recycle":
			return "获得1次重抽机会，提高本局技能成型稳定性。"
		_:
			return "强化当前战斗能力。"
