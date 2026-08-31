# 状态：通过

## 合并范围

- 主线：`main` at `f0866c05`
- C 阶段源：`codex/power-scale-v6` at `f82facc2`
- 合并提交：`fb85764b32516bd0f9c189813b6fe926a4f65c90`
- 策略：保留主线 UI、视觉、截图与确定性路径；接入 C 阶段战力 6.0、推荐战力合同、付费数值与追赶折扣。

## 11 个重叠文件的实际取舍

| 文件 | 实际裁决 |
| --- | --- |
| `core/save/save_manager.gd` | 以 C 为主：战力 6.0 镜像、分段成长和付费追赶折扣全部保留；同时保留主线 `suppress_persistence_for_captures` 截图只读护栏。 |
| `data/economy.json` | 合并两边：C 的 `premium_equipment_catch_up` 与 XP 合同，主线的无尽 Tier B 键与 `wave_clear_fast_forward`。 |
| `data/premium_sets.json` | 倍率带与付费数值取 C；`store_unlock` 严格取主线 30/50/70/90，Golden Law 仅需通关 90 关，不带 C 的角色 40 级附加门槛；解锁提示已同步到该语义。 |
| `data/localization_ui_en.json` | 保留两边新增键，并补齐 RC 检查发现的 70/90 关与追赶折扣英文映射。 |
| `gameplay/battle/battle.gd` | 保留主线字体弹窗与确定性实现；仅合入 C 的付费武器弹药卡“最终元素覆盖”非审计逻辑。未手工修改审计模式路径。 |
| `meta/store/store.gd` | 以主线解锁路线图和纹理化 UI 为主，逐处保留 C 的 `CatchUpCostText` 与追平报价展示。 |
| `meta/collection/collection.gd` | 完整取主线版本。 |
| `tools/check_visual_screens.py` | 完整取主线静默执行、只读护栏与真机矩阵版本。 |
| `tools/m1_smoke_test.gd` | 合并两边断言：C 的战力、付费、分段成长、追赶折扣；主线的存档隔离、30/50/70/90 解锁阶梯与清场快进护栏。 |
| `design/m1_todo.md` | 保留两边收官记录，不丢条目。 |
| `design/m1_implementation_progress.md` | 保留两边实施历史，不丢条目。 |

## 验证结果

| 门禁 | 结果 |
| --- | --- |
| M1 smoke | **PASS** — `godot --headless --path . --script tools/m1_smoke_test.gd`，零 `ERROR`。 |
| 战力 6.0 黄金测试 | **PASS** — `python3 tools/test_power_scale_v6.py`，当前套件 15/15 通过（覆盖简报要求的 12 项）。 |
| RC 非视觉总门禁 | **PASS** — `ZOMBIE_FIRE_SKIP_WINDOWED_VISUALS=1 python3 tools/check_release_candidate.py`，完整日志无 `check failed`，结尾 `Release candidate check OK`。 |
| 五个单项复核 | **PASS** — `check_clear_requirements` / `check_economy_loop` / `validate_data` / `check_balance_profile` / `check_campaign_pacing_contract` 全绿。 |
| 推荐战力单调性 | **PASS** — 99 关零回落（允许持平）；L01=54、L50=944、L99=5000。 |
| 免费侧零泄漏 | **PASS** — Tier B / v2 / 10 种子，99 关共 990 条 `runs` 与合并前逐位一致；双方 SHA-256 均为 `9532dc4e981f93953658b9ac7bc3db5c754a725279d582d822b0f62d312066f7`，989 胜、0 超时。 |

## 需 Owner / Fable 知道的语义与证据边界

1. C 源分支最终提交 `8938b8af` 已按 Owner 覆盖把付费追赶系数从早期 `0.0005` 改为 `0.5`；本次合并保留最终 `0.5`。C 分支内部分历史商业化审计文档仍引用 `0.0005` 与旧的 6% 前提，它们是历史证据，不能解读为当前数值合同。本次未改阈值、未用旧文档反向改代码。
2. Golden Law 解锁语义按本次明示的文件归属裁决取主线：通关 90 关即开放。这覆盖 C 分支的“90 关 + 任意角色 40 级”条件，属于有意的冲突裁决，不是遗漏。
3. 合并前阻塞 Git 的 3 个未跟踪预建文件已可恢复地备份到 `/private/tmp/zf-main-premerge-untracked-20260831/`；未删除。
4. 主线原有未提交的 `export_presets.cfg`、Godot `.import` 和 `.uid` 文件全部保留，未纳入本次两条提交链。
5. 验证期间另一隔离 worktree 同时运行约 20 个 Godot 探针 worker，两次 M1 出现相同的卡牌列表离屏布局时序错误。未改布局实现、阈值或断言；待外部 worker 全部退出后，独立 M1 与完整 RC 内嵌 M1 均零 `ERROR` 通过。

本次未 push。
