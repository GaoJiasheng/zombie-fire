# B2 免费元素武器可用性审计

口径：Tier B、免费装备全满级、永久技能全满；每把武器分别调用同一套
`maxed_free_build_for_level → power_for_build` 管线，在已编写的对应弱点关卡上
选择其余免费槽位的最优组合。硬门槛是原生元素枪的 matchup 感知战力必须高于
同关最强免费物理枪（包括真实技能投影产生的属性弹转化）。完整付费套的专属
触发、套装联动与主动技能不属于通用战力管线，因此付费对照直接引用各套装独立
DPS 审计锁定的完整套装倍率带，避免用缺少套装机制的通用战力数字误判。

| 元素 | 代表关 | 原生元素枪 | 有效战力 | 最强免费物理枪 | 物理战力 | 相对值 | 同元素完整付费套 DPS 合同 | 结论 |
|---|---:|---|---:|---|---:|---:|---:|---|
| ice | 20 | `weapon_cryocannon` | 3,989 | `weapon_scattergun` | 2,889 | 1.381× | `set_apocalypse_absolute_zero` 1.52–1.58× | 通过 |
| poison | 40 | `weapon_venomlauncher` | 5,159 | `weapon_scattergun` | 4,606 | 1.120× | — | 通过 |
| lightning | 65 | `weapon_teslacoil` | 19,139 | `weapon_scattergun` | 18,165 | 1.054× | `set_apocalypse_thunder` 1.52–1.60× | 通过 |
| fire | 75 | `weapon_flamethrower` | 3,061 | `weapon_scattergun` | 2,488 | 1.230× | `set_apocalypse_inferno` 1.52–1.58× | 通过 |

说明：绝对零度、雷霆、炼狱完整套分别继续由
`audit_absolute_zero_premium_dps.py`、`audit_character_endgame_dps.py`、
`audit_inferno_premium_dps.py` 实算并守住数据源里的发布合同。本表不再伪造一个
忽略套装机制的“付费有效战力”。B2b 将 Tier B 切成正式默认档前，须把三套独立
DPS 审计一并迁移到 Tier B 口径并重新确认倍率；B2a 试验包默认仍为 control。
