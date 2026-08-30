# B2 免费元素武器可用性审计

口径：Tier B、免费装备全满级、永久技能全满；每把武器分别调用同一套
`maxed_free_build_for_level → power_for_build` 管线，在已编写的对应弱点关卡上
选择其余免费槽位的最优组合。战力 6.0 的玩家数字是纯构筑中性值，属性克制
不再进入该数字；代表关只验证已编写弱点，实战增益单列 `伤害×1.50` 徽章。
完整付费套的专属
触发、套装联动与主动技能不属于通用战力管线，因此付费对照直接引用各套装独立
DPS 审计锁定的完整套装倍率带，避免用缺少套装机制的通用战力数字误判。

| 元素 | 代表关 | 原生元素枪 | 中性战力 | 最强免费物理枪 | 中性战力 | 中性比值 | 克制徽章 | 同元素完整付费套 DPS 合同 | 结论 |
|---|---:|---|---:|---|---:|---:|---:|---:|---|
| ice | 20 | `weapon_cryocannon` | 13,964 | `weapon_scattergun` | 13,587 | 1.028× | 伤害×1.50 | `set_apocalypse_absolute_zero` 1.22–1.28× | 通过 |
| poison | 40 | `weapon_venomlauncher` | 14,671 | `weapon_scattergun` | 13,587 | 1.080× | 伤害×1.50 | — | 通过 |
| lightning | 65 | `weapon_teslacoil` | 14,251 | `weapon_scattergun` | 13,587 | 1.049× | 伤害×1.50 | `set_apocalypse_thunder` 1.22–1.28× | 通过 |
| fire | 75 | `weapon_flamethrower` | 12,665 | `weapon_scattergun` | 13,587 | 0.932× | 伤害×1.50 | `set_apocalypse_inferno` 1.22–1.28× | 通过 |

说明：绝对零度、雷霆、炼狱完整套分别继续由
`audit_absolute_zero_premium_dps.py`、`audit_character_endgame_dps.py`、
`audit_inferno_premium_dps.py` 实算并守住数据源里的发布合同。本表不再伪造一个
忽略套装机制的“付费有效战力”。战役与正式运行时默认冻结为 Tier B；
属性弹覆盖与元素单通道行为由 m1 smoke 验证，不能用中性显示值替代伤害审计。
