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
	"sig_vanguard_railvolley": {"name": "弹幕齐射", "desc": "主动：短时间提高攻速，以当前主武器伤害齐射多轮弹幕；技能升级会延长压制并增加齐射轮数与目标数。"},
	"sig_vanguard_overload": {"name": "过载反击", "desc": "自动：基地生命低于 30% 时触发 5 秒强攻（每关 1 次）。"},
	"sig_blaze_meltdown": {"name": "熔毁爆发", "desc": "主动：锁定高威胁目标引爆连续火焰冲击并点燃周围敌人；技能升级会扩大爆区、强化灼烧并增加爆发段数。"},
	"sig_blaze_napalm": {"name": "凝固汽油", "desc": "弹种：火焰弹获得小范围爆燃和更强灼烧。"},
	"sig_frost_glacier": {"name": "冰川领域", "desc": "主动：展开全屏寒冰领域，持续减速并周期造成冰霜伤害；技能升级会延长领域、增强减速并增加寒潮波次。"},
	"sig_frost_shatter": {"name": "冰碎", "desc": "弹种：冰霜弹命中受控目标时追加碎冰伤害。"},
	"sig_volt_chain": {"name": "闪电链", "desc": "弹种：闪电弹获得额外连锁目标，成长后连锁数继续提高。"},
	"sig_volt_storm": {"name": "雷暴领域", "desc": "主动：连续锁定多名高威胁敌人释放雷击并附加震击；技能升级会增加锁定目标与雷击次数。"},
}

const SIG_SKILL_LEVEL_GROWTH := {
	"sig_vanguard_railvolley": "每级：伤害 +10% · 冷却 -3% · 持续 +0.35秒；Lv2/4 各 +1轮齐射、+1目标",
	"sig_blaze_meltdown": "每级：伤害 +10% · 冷却 -3% · 范围 +5% · 灼烧 +8%；Lv3/5 各 +1段爆发",
	"sig_frost_glacier": "每级：伤害 +10% · 冷却 -3% · 持续 +0.5秒 · 减速增强；Lv3/5 各 +1波寒潮",
	"sig_volt_storm": "每级：伤害 +10% · 冷却 -3%；Lv2/4 各 +1锁定目标、+1次雷击",
}

static func passive_info(passive_id: String) -> Dictionary:
	return PASSIVE_DESCRIPTIONS.get(passive_id, {"name": passive_id, "desc": "已生效：未知被动。"})

static func signature_info(signature_id: String) -> Dictionary:
	return SIG_SKILL_DESCRIPTIONS.get(signature_id, {"name": signature_id, "desc": "专属：效果说明缺失。"})

static func signature_level_growth(signature_id: String) -> String:
	return str(SIG_SKILL_LEVEL_GROWTH.get(signature_id, "每级提高主动技能强度与冷却效率。"))
