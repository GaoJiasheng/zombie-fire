extends RefCounted

const PASSIVE_DESCRIPTIONS := {
	"breach_guard": {
		"name": "钢铁防线",
		"desc": "已生效：漏怪护盾 +1；15级后再 +1。物理弹获得实弹校准加成。",
	},
	"flame_overdrive": {
		"name": "烈焰超载",
		"desc": "已生效：火焰弹伤害、爆燃范围和灼烧强度提升。",
	},
	"frost_command": {
		"name": "寒冰指令",
		"desc": "已生效：减速效果提升；冰霜弹强化冻结并触发碎冰伤害。",
	},
	"volt_chain": {
		"name": "电弧链击",
		"desc": "已生效：闪电弹伤害提升，并获得额外连锁跳转。",
	},
}

const SIG_SKILL_DESCRIPTIONS := {
	"sig_vanguard_railvolley": {"name": "弹幕齐射", "desc": "主动：短时间提高攻速，主武器额外弹道并增加穿透。"},
	"sig_vanguard_overload": {"name": "过载反击", "desc": "自动：基地生命低于 30% 时触发 5 秒强攻（每关 1 次）。"},
	"sig_blaze_meltdown": {"name": "熔毁爆发", "desc": "主动：锁定高威胁目标引爆火焰范围伤害，并点燃周围敌人。"},
	"sig_blaze_napalm": {"name": "凝固汽油", "desc": "弹种：火焰弹获得小范围爆燃和更强灼烧。"},
	"sig_frost_glacier": {"name": "冰川领域", "desc": "主动：在防线前展开寒冰领域，持续减速并周期造成冰霜伤害。"},
	"sig_frost_shatter": {"name": "冰碎", "desc": "弹种：冰霜弹命中受控目标时追加碎冰伤害。"},
	"sig_volt_chain": {"name": "闪电链", "desc": "弹种：闪电弹获得额外连锁目标，成长后连锁数继续提高。"},
	"sig_volt_storm": {"name": "雷暴领域", "desc": "主动：向最多 6 个高威胁敌人释放雷击并附加震击。"},
}

static func passive_info(passive_id: String) -> Dictionary:
	return PASSIVE_DESCRIPTIONS.get(passive_id, {"name": passive_id, "desc": "已生效：未知被动。"})

static func signature_info(signature_id: String) -> Dictionary:
	return SIG_SKILL_DESCRIPTIONS.get(signature_id, {"name": signature_id, "desc": "专属：效果说明缺失。"})
