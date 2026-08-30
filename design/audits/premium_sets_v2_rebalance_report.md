> 状态：部分完成（数值与运行时硬门禁通过；商业化等价分位未通过）

# C 阶段付费套数值重构 v2

## Tier B 中性纯物理 DPS

| 套装 | 武器 coef / 攻速 | 审计终值 | 合同 |
|---|---:|---:|---:|
| 雷霆 | 0.588 / 5.0 | 1.249x | 1.22–1.28 |
| 炼狱 | 0.855 / 6.2 | 1.251x | 1.22–1.28 |
| 绝对零度 | 0.969 / 4.3 | 1.250x | 1.22–1.28 |
| 黄金法则 Lv50 | 1.335 / 2.4 | 1.251x | 1.22–1.28 |
| 黄金法则 Lv65 | 1.335 / 2.4 | 1.600x | 1.55–1.65 |

黄金法则通用成长段为 Lv51–65、每级攻击加值 0.0275；与既有射速成长共同形成约 1.7%/级的整套输出斜率。Lv51–65 仍按原金币公式收费，逐级成本为 11,296、11,520、11,744、11,968、12,192、12,416、12,640、12,864、13,088、13,312、13,536、13,760、13,984、14,208、14,432，总计 **192,960 金币**，无成本断点。

## 商店合同

- 揭示阶梯：炼狱 30、雷霆 50、绝对零度 70、黄金法则 90 + 任意角色 40。
- 黄金法则完整包 US$8.99；主题 US$1.99；按同差价逻辑，升级包为 **US$6.99**。
- 其余三套完整包 / 升级包仍为 US$6.99 / US$4.99。

## 玩家侧文案草稿（未写入 localization）

### 中文

- 炼狱：满配物理输出约提升 25%，可自由切换弹药元素；保留火焰时可发挥爆燃与灼烧专属机制。
- 雷霆：满配单体物理输出约提升 25%，可自由切换弹药元素；保留雷电时可发挥连锁与过载群战优势。
- 绝对零度：满配物理输出约提升 25%，可自由切换弹药元素；保留寒冰时可发挥脆化、碎冰与减速控场。
- 黄金法则：Lv50 与三套同档，Lv51–65 进入超频成长，Lv65 满配物理输出约提升 60%；可自由切换弹药元素，保留物理时发挥裁决与黄金敕令。
- 策略说明：切换弹药可吃到关卡克制，但依赖本命元素的专属机制会暂时失效；这是“保机制 / 吃克制”的主动选择。

### English

- Inferno: About +25% maxed neutral physical output with freely selectable ammo elements. Keep Fire ammo to retain Combustion and Burn mechanics.
- Thunder: About +25% maxed single-target neutral physical output with freely selectable ammo elements. Keep Lightning ammo for Chain and Overload crowd pressure.
- Absolute Zero: About +25% maxed neutral physical output with freely selectable ammo elements. Keep Ice ammo for Brittle, Shatter, and slow control.
- Golden Law: Matches the first three sets at Lv50, then enters an Lv51–65 overclock curve to about +60% maxed neutral physical output. Keep Physical ammo for Judgment and Golden Decree.
- Strategy note: switching ammo gains the stage counter, but native-element mechanics pause while another element is loaded. Choose between native mechanics and the counter bonus.

## 商业化等价分位

当前实测仍有阻断：旧配装触发率 47.2%（17/36）、旧结算触发率 25.0%（9/36）；新恒定战力下，按“即时提升不得为负”的诚实门槛，两者均为 0/69。四套在按节奏同级继承样本中均出现负提升，详表由 `power_scale_v6_commercial_quantiles.md` 生成；未通过调低门槛掩盖负提升。

## 普通 099 十种子硬门禁

固定种子 `1103,2207,3301,4409,5513,6637,7741,8849,9901,10903`、Tier B、v2 卡牌策略，四套均为 **10/10 胜利、0 超时**：

| 套装 | 用时 min / median / max | 最低基地余量 | Boss 阶段最大值 |
|---|---:|---:|---:|
| 雷霆 Lv50 | 173.75 / 189.14 / 238.73s | 96.06% | 190.32s |
| 炼狱 Lv50 | 178.90 / 217.95 / 363.23s | 78.64% | 294.38s |
| 绝对零度 Lv50 | 193.13 / 235.84 / 442.98s | 98.22% | 395.43s |
| 黄金法则 Lv65 | 168.40 / 185.12 / 235.72s | 99.92% | 188.98s |

逐种子原始结果与哈希见 `premium_sets_v2_level099_ten_seed_evidence.json`。挑战 099 未作为三套一档门禁，符合 Owner 范围裁决。

## 零泄漏与确定性

- 付费改动前基线取同一 C 阶段合同提交 `4be071fb`，而不是更早的 v5/B2 推荐值快照；免费 99×10 经 5 条主机过载样本低并发复判后 **990/990 完整 run 对象逐位一致**，两侧 canonical SHA-256 同为 `00b7e346…`。其中 088/6637 的既有非胜利在前后完全一致，不属于付费路径泄漏；完整过程见 `power_scale_v6_free_zero_leakage_evidence.json`。
- 86/2207 与 90/1103 各跑 A/B，两组完整 run 对象均逐位一致；哈希分别为 `27f1916a…` 与 `28d8f824…`，详见 `power_scale_v6_determinism_evidence.json`。
- 非视觉 RC 除 B2 基线已缺失的美术源 manifest 外全部通过；两份缺失清单在 `f8361dfb` 同样不存在，不是本轮回归。
