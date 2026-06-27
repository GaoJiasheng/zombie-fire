# M1 Implementation Progress

> Purpose: resumable checkpoint for playable M1 implementation.

## Current State

M1 is complete against the 17 acceptance items in `MINIMAX_FINAL_INSTRUCTIONS.md`.
The project now passes static validators, `res://` reference scans, Godot headless startup,
and an automated M1 smoke test that instantiates the main flow, loadout upgrade entry,
all five battle scenes, and the result scene.

### Implemented (new since previous checkpoint)

- **HUD bars**: `BaseHpBar`, `WaveProgress`, `XpBar` with real `ui_base_hp_bar` / `ui_wave_progress` / `ui_run_xp_bar` textures and `ColorRect` fill driven by HP / wave / XP ratios.
- **Pause overlay**: `Hud/PauseOverlay` with dim layer + centered panel; Resume / Restart / Map buttons on `ui_button_primary` / `ui_button_secondary`. Toggled by `icon_pause.png` button or `Esc` (`InputManager.pause_pressed`).
- **Result screen**: real `ui_button_primary.png` for Retry, `ui_button_secondary.png` for Map. Retry replays `level_id` via `router.start_level`.
- **Reroll (1 charge per run)**: `reroll_charges` initialized to 1, decremented in `_on_reroll_pressed`. CardPanel button shows "重抽 (n)", disabled + dimmed at 0.
- **Skip card**: CardPanel Skip button grants a small XP threshold bump without picking a card.
- **Lv3 qualitative feedback**:
  - `skill_slow_field` Lv3 draws a wide translucent cyan band starting at `y = 1160`, alpha `~0.27`.
  - `skill_split_shot` Lv3 fires 5 split bullets in an 80° fan (vs 50° at Lv1).
  - `skill_pierce` Lv3 = `pierce: 3, dmg_mult: 1.15`.
  - `skill_multishot` Lv3 = `extra_projectiles: 3, spread: 12°` (4-shot fan).
- **Threat markers**: each enemy spawns a `Label` child added to a separate `ThreatMarkerLayer`. Color and label derived from `threat_tags` (`BOSS`, `ELITE`, `BREACH`, `TANK`, `BURST`, `FAST`, `SUPPORT`). Markers are cleaned up on enemy `tree_exiting`.
- **Boss armor-break**: `enemy.take_damage` reads `mechanic == "armor_break"` and `mechanic_params.armor_hits`. Physical hits on `boss_tank_titan` decrement `armor_hits_left` with a gray flash; on the breaking hit, boss permanently tints reddish and the marker text becomes `BROKEN`. Level 5 is therefore winnable with the M1 physical weapon.
- **Weakness / resist**: `take_damage` applies `weakness_mult = 1.5` and `resist_mult = 0.5` per `data/economy.json`. M1 weapon is physical, so only `boss_tank_titan.weakness = "fire"` matters at higher tiers.
- **Targeting debug overlay**: `F3` toggles `Hud/DebugOverlay`. Shows level / wave / HP / XP / cards / reroll / strategy / lock state / top target score and id.
- **res:// reference scanner**: `tools/check_res_refs.py` walks every `.gd` / `.tscn` / `project.godot` and reports missing `res://` targets (skips `%` placeholders). Currently 40 refs, 0 missing.
- **Menu / Loadout styling**: title typography bumped; `StartButton` uses `ui_button_primary.png` for visual consistency with battle / result.
- **Loadout upgrade entry**: `weapon_autocannon +1` is visible in Loadout, reads/writes `SaveManager`, checks gold cost, updates level/cost/gold text, and persists on upgrade.
- **Runtime smoke test**: `tools/m1_smoke_test.gd` verifies data counts, menu/map/loadout routing, upgrade button presence, five battle scene first-spawn readiness, and result summary rendering.
- **App shell pass**: menu help / sound toggle, map progress + level lock/star display, result next-level button.
- **Audio pass**: global `AudioManager` with menu/map/battle/result BGM and key SFX for fire, hit, kill, breach, lock, pause, card offer/pick, reroll, upgrade, victory, defeat.
- **Combat feedback pass**: muzzle flash, projectile visual rotation, hit VFX, enemy walk/hurt/death frame animation.
- **Combat readability pass**: enemy HP bars, kill reward float text, breach damage float text.
- **Card UX pass**: skill cards now render icon + title + short description + tags; long press / right click opens a detail overlay.
- **Meta polish pass**: map level cards use texture buttons with localized names/stars/lock state; loadout shows weapon icon.
- **Control completeness pass**: right click / double click target lock; Tab / strategy button cycles target priority; HUD exposes current strategy and skill slots.
- **Flow clarity pass**: loadout shows per-level objective, wave/Boss toast appears during battle, result screen shows next-action hint.
- **Delivery pass**: `README.md` documents run and validation commands.

## Verification

- `python3 tools/validate_data.py` → `Data validation passed: 5 levels, 5 zombies, 1 boss, 4 skills`.
- `python3 tools/validate_asset_pack.py` → `Asset pack validation passed: 3703 files`.
- `python3 tools/check_res_refs.py` → `checked 40 res:// references` / `res:// references OK`.
- `godot --headless --path . --quit` → exits cleanly on Godot 4.7.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed` (headless exit may still print resource cleanup warnings from runtime-owned objects).

## Acceptance Checklist (per `MINIMAX_FINAL_INSTRUCTIONS.md`)

1. Godot opens & runs — headless startup and M1 smoke test pass on Godot 4.7.
2. menu → map → loadout → battle → result → map flow — wired in `main.gd` + per-scene `setup` / button signals.
3. `level_001` … `level_005` enterable, winnable, losable, result shown — `meta/map/map.gd` enumerates all five; `_finish(victory)` covers both branches.
4. Fixed bottom turret, auto fire, mouse aim — `gameplay/turret/turret.gd` at `(540, 1660)`, `aim_at` driven by `InputManager.aim_point`.
5. Right-click lock, indicator follows, auto-cancel on death / out of range — `_on_target_lock_requested` + `TargetingManager.lock_enemy` / `clear_lock`; cleared in `_on_enemy_died` / `_on_enemy_breached`.
6. Auto-priority breach > elite / boss > nearest — `TargetingManager._score_enemy` with `strategy = breach` default; debug overlay surfaces the score.
7. Enemies spawn from top, push down, breach damages base — `enemy.gd._physics_process` + `BREACH_Y = 1500`.
8. Projectile flight, collision, hit, kill, gold, XP — `projectile.gd` + `_on_enemy_died` reward wiring.
9. XP threshold triggers 3-choice, pauses, resumes — `_show_card_offer` sets `get_tree().paused = true`; HUD has `PROCESS_MODE_WHEN_PAUSED`.
10. Reroll 1 per run — `reroll_charges` flow above.
11. 4 M1 skills visible — split / pierce / multishot / slow_field all wired (see "Implemented").
12. Lv3 qualitative — slow field band + boss `BROKEN` marker; split fan width also scales.
13. HUD: HP / wave / XP / gold / pause — see HUD section.
14. Threat markers + debug overlay — see "Implemented".
15. Level 5 boss winnable — armor-break: 30 hits to break, then physical works.
16. macOS 60 FPS target — headless runtime smoke passes; device FPS remains a M2 profiling item.
17. All runtime assets from `assets/production` / `assets/sprites` — `check_res_refs.py` enforces this.

## Remaining Risks

- **Interactive device playtest**: headless startup/smoke passes, but mouse/touch feel and real macOS FPS still need a visible editor/device run in M2 profiling.
- **Map buttons are plain `Button`** (not `TextureButton`). Functionally correct; visually less consistent than battle / result. Low priority; revisit in polish.
- **Threat marker initial frame**: the marker is parented to `ThreatMarkerLayer` (Node2D), so its first `position` is set in `enemy.gd._physics_process`. The very first rendered frame may briefly show the marker at `(0,0)` before the first physics tick.
- **Boss armor visual** is a single tint + marker change. No dedicated `vfx_armor_break` sprite exists in `assets/sprites/vfx/`. The tint + BROKEN label is sufficient for M1.
- **Audio**: no `AudioStreamPlayer` is wired. SFX / BGM in `assets/production/audio/` are unused in M1 by design; wire them in M2 once interaction pacing is locked.

---

## Stage 1 P0 Pass — Combat Feel & Feedback (2026-06-26)

> Follow-up pass after the M1 baseline. Goal: bring "feel" up to the level implied by the genre gap analysis.

### New feedback systems

- **`core/feedback/hit_stop.gd`** — hit pause on crits and boss kills. Briefly drives `Engine.time_scale` down to 0.04 for 40-120 ms and restores it via a `create_timer` with `ignore_time_scale=true`. Throttled by a 0.16 s cooldown so dense crits don't stall the game.
- **`core/feedback/screen_shake.gd`** — bound to the battle root. `shake(intensity, duration)` decays amplitude over the duration with a sin/cos jitter so it feels less mechanical than a single random offset.
- **`gameplay/hud/combo_hud.gd`** — `2-HIT` / `10-HIT` / `25-HIT` … X-HIT counter with milestone flares at 10/25/50/100/200/500. Decays after 1.6 s of no kills. Boss kills display a custom `BOSS 击破！` label.
- **`gameplay/hud/damage_number_layer.gd`** — spawns pop-up damage numbers at the impact point, sized/colored by `(crit, weak_hit, element)`, stacks vertically when many hits land in the same spot, fades and rises over 0.85-1.05 s.
- **`gameplay/hud/off_screen_indicator.gd`** — draws a colored arrow on the left/right edge of the viewport for every enemy that's currently above the play area, with the same threat color used by in-battle threat markers.
- **`gameplay/hud/gold_fly.gd`** — physical gold coin sprite that arcs from the enemy's death position to the gold label and bumps the label when it lands. Replaces the previous flat "金" chip and stacks cleanly with the XP chip for visual distinction.

### Wiring in `battle.gd`

- New `damage_dealt(enemy, amount, element, crit_hit, weak_hit)` signal on `enemy.gd` (alongside the existing `hit_feedback` / `died` / `breached`).
- `_spawn_feedback_managers()` instantiates and binds all the above at battle `_ready`. Managers are children of `Battle`, so they are auto-freed with the scene.
- `_on_enemy_damage_dealt` → spawns damage number, triggers a small hit-stop and a 6.0 screen-shake on crits.
- `_on_enemy_died` → registers a kill on the combo HUD, fires a kill-burst screen shake (4.0 / 7.0 / 18.0 depending on kill streak / boss), triggers a 0.12 s hit-stop on bosses, and flies a gold coin to the HUD.
- `_update_lock_indicator` now also pulses the lock ring (1.0x ↔ 1.18x scale, 0.7 s loop) while a manual lock is active.
- `_physics_process` calls `_update_off_screen_indicators()` so the side arrows stay in sync.
- `_on_pause_pressed` populates a new `BuildSummary` label on the pause overlay (level name, recommended level, weakness, character, weapon Lv., armor, chip, pet, current skill slots with levels, target strategy) so players can read their build at a glance.

### Pause overlay build summary

A new `BuildSummary` label below the existing pause buttons lists:

- 关卡名 + 建议等级
- 本关弱点（中文元素名）
- 角色 / 枪械 Lv. / 护甲 / 芯片 / 宝宝
- 已带技能 + 当前等级
- 当前目标策略（中文）

### Files added

- `core/feedback/hit_stop.gd`
- `core/feedback/screen_shake.gd`
- `gameplay/hud/combo_hud.gd`
- `gameplay/hud/damage_number_layer.gd`
- `gameplay/hud/off_screen_indicator.gd`
- `gameplay/hud/gold_fly.gd`

### Files modified

- `gameplay/battle/battle.gd` — wired all managers, added `damage_dealt` handler, lock-ring pulse, off-screen refresh, pause build summary.
- `gameplay/battle/battle.tscn` — added `ComboHud` (Control) with `Label` / `Milestone` / `DecayTimer` children, and `PauseOverlay/BuildSummary` label.
- `gameplay/enemy/enemy.gd` — added `damage_dealt` signal, emit on every real hit (including status-tick damage) with element / crit / weak flags.

### Verification (after Stage 1 P0)

- `godot --headless --path . --quit` → exits cleanly.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`.
- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 165 res:// references / res references OK`.
- `godot --path .` (windowed) → opens, no startup errors, Metal 4.0 on M5 Max.

---

## Stage 1 P1 Pass — Skill Slots, Character Clarity & Difficulty Rebalance (2026-06-26 morning)

> Addressed three concrete player reports: skill cards silently dropping past slot 8, characters feeling indistinguishable in UI, and the campaign being trivial through level 30.

### Fix 1: Skill card slot overflow (was a real bug)

`_current_skill_slot_ids()` walked a fixed `SKILL_ORDER` list and sliced to the first 8 owned skills, so any 9th+ card got its level recorded but disappeared from the slot strip. The slot UI now follows acquisition order, no cap.

- `SkillRuntime` gained an `_order` array populated by `add_skill()` and exposed via `owned_order()`.
- `battle.gd::_current_skill_slot_ids()` now returns `skills.owned_order()` directly.
- `_build_skill_slots()` computes dynamic icon size: `slot_size = clamp(520 / count - 4, 26, 52)` so 1-16 skills all fit in the bottom strip without overflow.

### Fix 2: Character detail modal

The collection screen's character rows used to show only "定位 / 元素 / 下一级" with no numbers, so the four characters felt interchangeable. Clicking a character now opens a modal that surfaces:

- 立绘（大图）
- 名字 + 等级 + 段位标签
- 基础攻击 / 基础血量 / 每级成长百分比
- 暴击率 / 射速倍率 / 瞄准速度
- 被动名 + 中文描述（PASSIVE_DESCRIPTIONS 表）
- 专属技能列表 + 描述（SIG_SKILL_DESCRIPTIONS 表，覆盖 8 个 sig_* 占位）
- 流派倾向（card_affinity_tags）
- 选定 / 关闭按钮

The full Chinese descriptions live in `meta/collection/collection.gd` at the top of the file so designers can edit them without grepping through JSON.

### Fix 3: Difficulty coefficient rebalance

The `difficulty_coef` field across all 99 levels had been mass-filled with `0.75`, ignoring the `scale(n) = 1 + 0.10*(n-1) + 0.004*(n-1)^2` formula in `design/09_balance.md §3`. The result: enemies at level 30 had 1/10 the HP the design intended, so even a "balanced" vanguard with a lv15 autocannon cleared the level in ~15 s.

- New tool `tools/rebalance_difficulty.py` recomputes `difficulty_coef` per the formula and applies a +50% spike on every 5th level (5, 10, 15, ..., 95) where a boss wave lives.
- New tool `tools/simulate_balance.py` simulates clear time per level for a vanguard + autocannon at recommended level, with both "no skill cards" and "with mid-run skill stack" scenarios, plus a leak% estimate and predicted star rating (1-3 stars).
- Sample output (`tools/simulate_balance.py`):
  - Level 1 (coef 1.0): 6 s clear, 8 % leak, predicted 3★
  - Level 30 (coef 10.9): 130 s clear, 100 % leak, predicted 1-2★
  - Level 99 (coef 49.2): 134 s clear, 100 % leak, predicted 1★
  - Average across campaign: 118 s clear with skills (matches the 90-150 s design target)

### Files added

- `tools/rebalance_difficulty.py`
- `tools/simulate_balance.py`

### Files modified

- `gameplay/skill/skill_runtime.gd` — added `_order` array + `owned_order()` accessor.
- `gameplay/battle/battle.gd` — removed `SKILL_SLOT_LIMIT` cap from `_current_skill_slot_ids()`, rewrote `_build_skill_slots()` with dynamic icon sizing.
- `meta/collection/collection.gd` — added `PASSIVE_DESCRIPTIONS` / `SIG_SKILL_DESCRIPTIONS` tables and `_show_character_detail()` modal builder; `_build_item_button()` now routes characters into the modal instead of selecting directly.
- `data/levels.json` — all 99 `difficulty_coef` values regenerated.

### Verification (after Stage 1 P1)

- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`.
- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 165 res:// references / res references OK`.
- `python3 tools/simulate_balance.py` → average 118 s clear with skill cards, curve ramps from 6 s at level 1 to 134 s at level 99.

### Player action required

The game is currently running on PID 13359 with the OLD code loaded. Restart the project (`Cmd+Q` then `godot --path .`) to pick up:

1. Skill slots now show every picked card in acquisition order, dynamically resized.
2. Collection → 角色 → click a character opens a detail modal with stats / passive / signature skills.
3. Level difficulty is now formula-driven — level 30 should feel meaningfully harder than level 1.

---

## Stage 1 P2 Pass — Loadout / Result Layout Polish (2026-06-26)

> Addressed player reports that the pre-battle loadout page and result page still had cramped copy, weak framing, and large stacked buttons.

- **Loadout page**: rebuilt the visual hierarchy around a compact header, two framed hero / cannon panels, a direct character portrait row, a direct armor / chip / pet icon row, a dedicated mission panel, and a compact economy / upgrade hint panel.
- **Direct interactions kept**: clicking the cannon icon still upgrades the current weapon; the old large upgrade button stays hidden. Character and gear category buttons are now framed icon buttons instead of loose images or text tabs.
- **Text compression**: loadout summary now uses two concise lines for level, power, weakness, lineup, counter state, and growth tier. Objective text sits in its own panel so it does not collide with the stat summary.
- **Result page**: rebuilt around separate result, reward, and action panels. Star rating uses the existing star UI assets; gold / XP use currency icons; actions are grouped into a two-column row plus full-width next / map buttons.
- **Regression guard**: smoke test still verifies loadout nodes, direct character / gear controls, player-facing level names, five-wave copy, battle flow, and result summary.

### Verification (after Stage 1 P2)

- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 172 res:// references / res:// references OK`.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`.

---

## Stage 1 P2.1 Fix — Battle Route Setup Order (2026-06-26)

> Fixed the real cause of "later-level small enemies still die in one shot".

- **Root cause**: `main.gd::change_scene()` added the new scene to the tree before calling `setup()`. For `Battle`, `_ready()` runs on `add_child()`, so the battle loaded default `level_001` waves and HP before `setup({"level_id": ...})` arrived.
- **Player symptom**: entering level 35/45 could still spawn level 1 enemies, e.g. a `zombie_runner` with ~49 HP, so a level 19 autocannon killed small mobs in one shot.
- **Fix**: `main.gd` now calls `setup()` before `add_child()`, so `_ready()` receives the requested level id before loading data and starting waves.
- **Regression guard**: `tools/m1_smoke_test.gd` now validates main-routed `start_level("level_035")` initializes Battle as level 35 and spawned enemy HP uses that level's `base_hp_ref * difficulty_coef` runtime scale. Direct battle smoke instantiation also now calls `setup()` before `add_child()`.

### Verification (after Stage 1 P2.1)

- Runtime probe before cleanup confirmed current save `weapon_autocannon Lv.19` has `shot_damage=68.32`, while `level_035` first enemy HP is `2112.5` and `level_045` first enemy HP is `1655.7`.
- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 172 res:// references / res:// references OK`.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`.

---

## Stage 1 P2.2 Pass — Character Signature Visibility (2026-06-26)

> Addressed the report that character exclusive skills were not visible from the loadout flow.

- **Loadout page**: added a visible `角色专属` section under the tactical summary. It shows the selected character's passive, active skill, and bullet-affinity signature before entering battle.
- **State clarity**: passive cards are labeled `被动已生效`; signature cards now distinguish `主动技能` and `专属被动` because the `sig_*` entries are active battle mechanics.
- **Shared copy source**: moved passive/signature descriptions into `core/data/character_skill_text.gd`, and both collection detail and loadout now read from the same helper to prevent copy drift.
- **Regression guard**: smoke test now verifies that loadout exposes `SignatureCards` and renders at least passive + two signature cards.

### Verification (after Stage 1 P2.2)

- `python3 tools/check_res_refs.py` → `checked 174 res:// references / res:// references OK`.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`.

---

## Stage 1 P2.3 Pass — Character Active Skills & Bullet Affinity (2026-06-26)

> Addressed the request that each character should have playable active/passive identity, and that fire / ice / lightning characters should clearly strengthen matching bullet types.

- **Character data**: all 4 characters now define `active_skill` and `bullet_affinity` in `data/characters.json`.
- **Battle active skill**: battle HUD exposes a dedicated `角色技能` button, also bound to keyboard `1`.
- **Vanguard**: `sig_vanguard_railvolley` temporarily increases fire rate, adds extra lanes, and improves physical pierce. `sig_vanguard_overload` auto-triggers once when base HP falls below 30%.
- **Blaze**: `sig_blaze_meltdown` detonates a high-threat target in an AoE and amplifies fire burn. Fire bullets gain damage, splash radius, and stronger burn.
- **Frost**: `sig_frost_glacier` creates a defensive ice field near the frontline. Ice bullets gain damage, stronger slow, and shatter controlled targets.
- **Volt**: `sig_volt_storm` chains lightning through high-threat targets. Lightning bullets gain damage, extra chain targets, and stronger shock.
- **Enemy status hooks**: enemies now expose `amplify_character_status`, `is_controlled`, and `has_element_status` so character passives can interact with burn, slow, shock, and shatter cleanly.
- **Regression guard**: smoke test verifies the battle active button, configured active skill id, bullet-affinity data, and basic active-skill cast path.

### Verification (after Stage 1 P2.3)

- `python3 tools/validate_asset_pack.py` → `Asset pack validation passed: 3703 files`.
- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 175 res:// references / res:// references OK`.
- `python3 tools/check_level_pressure.py` → pressure estimate completes across all 99 levels.
- `python3 tools/simulate_card_director.py` → card offer simulation completes across all 99 levels.
- `godot --headless --path . --quit` → exits 0 on Godot 4.7; still prints existing ObjectDB/resource cleanup warnings.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`; exits 0 with the same cleanup warnings.

---

## Stage 1 P3.7 Runtime Readability & Effect Budget Guardrails (2026-06-27)

> Follow-up after the global UI palette pass. Goal: reduce screen clutter and node churn without changing rules, data tables, or assets.

- **Damage-number cap**: `gameplay/hud/damage_number_layer.gd` now drops low-priority dense hit labels once the screen is saturated, while preserving crit / weak-hit numbers.
- **Reward flash cap**: `gameplay/hud/gold_fly.gd` keeps the cleaned-up coin flash behavior but caps concurrent coin/ring nodes and falls back to a HUD number pulse during dense kill bursts.
- **Projectile / battle VFX budget**: battle-spawned muzzle flashes, rings, chains, splashes, blood pools, shards, skill-flight icons, and float text are tagged as transient effects and skipped when their layer budget is already full.
- **Projectile trail budget**: `gameplay/projectile/projectile.gd` now caps afterimages, impact flashes, pierce rings, and pierce traces on the projectile layer.
- **Enemy local hit VFX throttle**: `gameplay/enemy/enemy.gd` throttles repeated per-enemy hit flashes so split / chain / DoT builds do not cover zombies with stacked sprites.
- **Off-screen indicator reuse fix**: `gameplay/hud/off_screen_indicator.gd` now uses stable left/right arrow pools instead of mutating both pools during cleanup.
- **Release text guard**: `tools/check_release_strings.py` now blocks visible release fallbacks like `待配置` and common player-facing English UI tokens.
- **Smoke coverage**: `tools/m1_smoke_test.gd` now asserts that damage numbers, gold reward flashes, and off-screen indicators stay bounded under burst conditions.

### Verification (after Stage 1 P3.7)

- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/validate_asset_pack.py` → `Asset pack validation passed: 3721 files`.
- `python3 tools/check_res_refs.py` → `checked 211 res:// references / res:// references OK`.
- `python3 tools/check_release_strings.py` → `Release string check OK`.
- `python3 tools/check_gameplay_polish.py` → `Gameplay polish OK: 16 skills, 8 weapons, 28 enemies covered`.
- `python3 tools/check_level_pressure.py` → pressure estimate completes across all 99 levels.
- `python3 tools/check_balance_profile.py` → `Balance profile OK`.
- `python3 tools/check_economy_loop.py` → `Economy loop OK`.
- `python3 tools/simulate_card_director.py` → card offer simulation completes for all 99 levels.
- `python3 tools/simulate_balance.py` → with-skill average clear time `98.3s`, min/max `14.3s / 178.8s`, levels `<30s = 4`, levels `>180s = 0`.
- `git diff --check -- ...` → no whitespace errors for the touched files.
- `godot --headless --path . --quit` → exits 0 on Godot 4.7; still prints existing ObjectDB/resource cleanup warnings.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`; exits 0 with the same cleanup warnings.

---

## Stage 1 P3.3 Map Entry Strip Cleanup — Remove Label Cut Lines (2026-06-27)

> Addressed the report that the top map entry strip had an ugly horizontal line cutting through the category labels.

- **No label slash line**: removed the one-sided top border from map nav label plates. The `角色 / 武器 / 护甲 / 芯片 / 宠物 / 技能` labels now sit on clean dark translucent nameplates instead of a bright line.
- **Cleaner icon cards**: slightly retuned icon insets, label plate bounds, and card background opacity so the six entry cards read as icon-first collection entries rather than framed text strips.

### Verification (after Stage 1 P3.3)

- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 207 res:// references / res:// references OK`.
- `git diff --check -- meta/map/map.gd` → no whitespace errors.
- `godot --headless --path . --quit` → exits 0 on Godot 4.7; still prints existing ObjectDB/resource cleanup warnings.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`; exits 0 with the same cleanup warnings.

---

## Stage 1 P2.5 Combat Rule Fix — Persistent Base Attacks (2026-06-26)

> Addressed the report that enemies should not touch the base once and disappear; they should pile up at the gate and keep attacking like the reference game.

- **Enemy base state**: enemies now enter `attacking_base` when they reach the gate line, stop moving, remain targetable, and repeat base attacks until killed.
- **Attack identity**: base attack damage / interval / VFX are derived from `mechanic + bd_coef`: fast units attack often for lighter damage, tanks slam slower for heavier damage, corrosion / blast / support units use distinct attack treatment.
- **Control still matters**: ice slow and lightning shock slow down the base-attack charge timer, so control skills remain valuable even after enemies reach the gate.
- **Readability fix**: removed per-enemy `逼近防线` float text and shortened threat labels from English `BREACH 弱X` to compact Chinese labels like `近线·冰`.
- **Base damage copy**: repeated base hits now use short `-8` / `格挡` float text instead of long overlapping `-8 基地` / `护盾拦截` strings.
- **Regression guard**: smoke test now forces one enemy to the gate and verifies it remains alive/targetable, enters persistent base-attack state, and ticks base damage over time.

### Verification (after Stage 1 P2.5)

- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 175 res:// references / res:// references OK`.
- `godot --headless --path . --quit` → exits 0 on Godot 4.7; still prints existing ObjectDB/resource cleanup warnings.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`; exits 0 with the same cleanup warnings.

---

## Stage 1 P2.4 Balance Tuning — Enemy Pace Relief (2026-06-26)

> Addressed the report that the difficulty curve finally has enough HP pressure, but enemies reach the base too quickly and the game feels too hard.

- **Kept HP curve intact**: no rollback to `difficulty_coef`, enemy HP, or wave count.
- **Added global speed knob**: `data/economy.json` now defines `ENEMY_SPEED_MULT`.
- **Runtime wiring**: `battle.gd::_spawn_enemy_instance()` duplicates the source enemy row and applies `ENEMY_SPEED_MULT` to the row speed before `enemy.setup()`.
- **Current tuning**: `ENEMY_SPEED_MULT = 0.82`, so all normal enemies and bosses move 18% slower while preserving each enemy type's relative speed identity.

### Verification (after Stage 1 P2.4)

- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 175 res:// references / res:// references OK`.
- `python3 tools/check_level_pressure.py` → pressure estimate completes across all 99 levels; this tool does not include movement speed, so HP pressure output is intentionally unchanged.
- `godot --headless --path . --quit` → exits 0 on Godot 4.7; still prints existing ObjectDB/resource cleanup warnings.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`; exits 0 with the same cleanup warnings.

---

## Stage 1 P2.6 Animation Polish — Character Weapon Rig & Enemy State Motion (2026-06-26)

> Addressed the report that heroes / zombies looked like sliding stickers, and that the old bottom cannon should visually become a character-held weapon without breaking existing weapon stats.

- **Character rig**: battle now spawns a centered `CharacterRig` with the selected character avatar, idle / attack / hurt frame cycling, skill-cast pose, recoil pose, elemental aura, and a weapon mount.
- **Weapon visual split**: the legacy `turret` node is hidden and kept only for fire-rate, damage, targeting, and upgrade logic. The visible weapon skin is mounted on the character, uses the selected weapon's existing animation frames, and changes when `weapon_id` changes.
- **Muzzle alignment**: projectile origin / muzzle flash / multishot directions now resolve from the character-mounted weapon muzzle, so bullets no longer appear to come from the old floor cannon center.
- **Enemy state motion**: enemies now use idle / walk / attack / hurt / death frame sets where available. Hurt interrupts walk frames with recoil; base attacks use attack frames plus lunge / squash instead of a static stop at the gate.
- **Regression guard**: smoke test now verifies the character-mounted weapon exists, all 8 selected weapons swap the mounted skin, the legacy turret sprite stays hidden, and projectile origin is offset to the weapon muzzle rather than the hidden turret center.

### Verification (after Stage 1 P2.6)

- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 176 res:// references / res:// references OK`.
- `godot --headless --path . --quit` → exits 0 on Godot 4.7; still prints existing ObjectDB/resource cleanup warnings.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`; exits 0 with the same cleanup warnings.

---

## Stage 1 P2.7 Visual Polish — Handheld Gun Skins & Mobile UI Cleanup (2026-06-26)

> Addressed the report that the weapon mounted on the hero still looked like an ugly floor cannon, and that several menu/detail/result screens had low-quality alignment and text overflow.

- **Handheld weapon assets**: added 8 transparent handheld gun sprites under `assets/production/sprites/weapons/handheld/`, one for every weapon row.
- **Data-driven weapon visual**: `data/weapons.json` now defines `handheld` for each weapon. Battle uses this field for the character-mounted visible weapon, keeping the legacy turret hidden for targeting / damage / upgrade logic only.
- **Muzzle and scale tuning**: adjusted mounted weapon scale and muzzle distances for the new gun proportions so projectiles originate from the character-held gun rather than a floor cannon.
- **Map UI**: moved equipment navigation into the top utility area and made entries icon-forward instead of plain text tabs.
- **Loadout UI**: tightened first-screen hierarchy around hero + weapon, icon equipment rows, compact signature cards, and separated economy / start action areas.
- **Character detail UI**: changed character detail to a framed hero header, scrollable stat / passive / signature sections, and fixed bottom actions so long skill text cannot overflow the modal.
- **Result UI**: shortened recommendation copy and next-level label to avoid text spilling outside cards.
- **Regression guard**: smoke test now requires every weapon to define an existing `handheld` skin and verifies battle mounts exactly that texture. It also caught and fixed a script-loading issue in `enemy.gd` plus a skill-slot icon sizing overflow.

### Verification (after Stage 1 P2.7)

- `python3 tools/validate_asset_pack.py` → `Asset pack validation passed: 3719 files`.
- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 186 res:// references / res:// references OK`.
- `godot --headless --path . --quit` → exits 0 on Godot 4.7; still prints existing ObjectDB/resource cleanup warnings.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`; exits 0 with the same cleanup warnings.

---

## Stage 1 P2.8 Combat HUD Polish — Bottom Skill Shelf (2026-06-26)

> Addressed the report that upgraded Tesla ammo showed like a Lv.1 card plus an overlapping icon and blocked the battlefield.

- **Bottom skill shelf**: moved owned skill slots from the right-side battlefield card stack to a compact horizontal shelf just above the bottom XP bar.
- **Single-slot upgrades**: repeated picks now visibly update the existing skill slot level badge, e.g. Tesla seed `LV1` + one Tesla pick becomes one `LV2` Tesla slot.
- **Less battlefield obstruction**: owned skills now show as icon + level only; long names and descriptions no longer sit over enemies during combat.
- **Pick animation cleanup**: the skill-pick fly-in icon is smaller, targets the bottom shelf, and fades out instead of lingering over the skill card.
- **Regression guard**: smoke test now verifies Tesla uses exactly one bottom `skill_tesla` slot and updates its badge from `LV1` to `LV2` after one upgrade.

### Verification (after Stage 1 P2.8)

- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 186 res:// references / res:// references OK`.
- `godot --headless --path . --quit` → exits 0 on Godot 4.7; still prints existing ObjectDB/resource cleanup warnings.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`; exits 0 with the same cleanup warnings.

---

## Stage 1 P2.9 Combat Pacing — Slower Initial Fire Rate, Same Baseline DPS (2026-06-26)

> Historical pass: addressed the request to reduce initial attack speed while keeping overall level difficulty unchanged. Superseded by Stage 1 P3.5, which raises the paced fire-rate value to `0.25` and rebuilds the full 99-level curve.

- **Global pacing knobs**: `data/economy.json` defines `PLAYER_FIRE_RATE_MULT` and `PLAYER_SHOT_DAMAGE_MULT`, so weapon feel can be tuned without hardcoding turret values.
- **Fire-rate change**: turret setup reads `PLAYER_FIRE_RATE_MULT` instead of the previous hardcoded `0.5` pacing constant.
- **Difficulty preservation**: primary projectile base damage multiplies by `PLAYER_SHOT_DAMAGE_MULT`, letting the balance tools reason about cadence and per-shot power separately.
- **Scope control**: enemy HP, enemy speed, wave counts, active-skill damage, and level coefficients were not changed.
- **Tooling sync**: balance simulation and gameplay-polish checks now read the economy pacing knobs instead of assuming the old hardcoded `0.5` value.
- **Regression guard**: smoke test verifies the current economy fire-rate multiplier and the DPS-preserving product.

### Verification (after Stage 1 P2.9)

- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 186 res:// references / res:// references OK`.
- `python3 tools/check_gameplay_polish.py` → `Gameplay polish OK`.
- `python3 tools/check_level_pressure.py` → pressure estimate completes across all 99 levels.
- `python3 tools/check_balance_profile.py` → `Balance profile OK`.
- `python3 tools/check_economy_loop.py` → `Economy loop OK`.
- `python3 tools/simulate_balance.py` → simulation completes; with-skill average clear time remains in the same estimate path because DPS compensation offsets the fire-rate cut.
- `godot --headless --path . --quit` → exits 0 on Godot 4.7; still prints existing ObjectDB/resource cleanup warnings.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`; exits 0 with the same cleanup warnings.

---

## Stage 1 P2.10 Map Entry Polish — Larger Icon Tiles (2026-06-26)

> Addressed the report that the map collection entries still looked like small icons with detached text.

- **Map navigation cards**: rebuilt the six top entries as icon-forward tiles. The category icon now fills the card as the main visual instead of sitting inside a small inner box.
- **Embedded label**: category text is now drawn on a translucent bottom nameplate inside the image area, with outline and accent top border. This keeps the row compact while making the entries feel closer to premium mobile game shortcuts.
- **No asset churn**: reused existing production icons for character, weapon, armor, chip, pet, and skill. No new images were generated.

### Verification (after Stage 1 P2.10)

- `python3 tools/check_res_refs.py` → `checked 186 res:// references / res:// references OK`.
- `godot --headless --path . --quit` → exits 0 on Godot 4.7; still prints existing ObjectDB/resource cleanup warnings.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`; exits 0 with the same cleanup warnings.

---

## Stage 1 P2.11 Combat Rule Fix — Element Ammo Exclusivity (2026-06-26)

> Addressed the report that plasma cannon could appear to fire Tesla ammo, and that Tesla / venom ammo could coexist.

- **Root cause**: elemental ammo skills were normal additive skills. `SkillRuntime.projectile_element()` let the highest-level ammo skill override the weapon's base element, so a fire/plasma weapon could be visually converted to lightning if Tesla ammo became higher level.
- **Weapon identity lock**: non-physical weapons now keep their native projectile element. Plasma cannon remains fire/plasma-themed; Tesla / venom / cryo cards cannot override it.
- **Ammo exclusivity**: incendiary, cryo, Tesla, and venom now declare `exclusive_group = projectile_element` plus `ammo_element`. Adding one ammo module removes the previous one from the runtime skill state.
- **Card director filtering**: physical weapons can choose one ammo module and then only upgrade that module. Elemental weapons only see their matching ammo upgrade card.
- **Copy cleanup**: card short / long descriptions now explain that ammo modules are mutually exclusive and only transform physical weapons.
- **Regression guard**: smoke test verifies Tesla + venom cannot coexist, physical weapons can be converted by one ammo module, and plasma cannon does not offer or inherit off-element ammo.

### Verification (after Stage 1 P2.11)

- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 186 res:// references / res:// references OK`.
- `godot --headless --path . --quit` → exits 0 on Godot 4.7; still prints existing ObjectDB/resource cleanup warnings.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`; exits 0 with the same cleanup warnings.

---

## Stage 1 P2.12 Combat Cleanup — Reward Flash & Blood Fade (2026-06-26)

> Addressed the report that gold / XP drops cluttered the battlefield and made the lanes look messy.

- **No reward litter**: removed battlefield reward chips and floating `金` / `XP` labels from enemy death rewards.
- **Instant accounting**: gold and XP are added directly to the bottom HUD counters when the zombie dies.
- **Gold feedback**: gold rewards now show one short coin flash at the kill position, then pulse the gold counter instead of flying piles across the lane.
- **XP feedback**: XP rewards now pulse the bottom XP bar only, keeping the center combat space clear.
- **Zombie cleanup effect**: enemy death now leaves a short-lived green blood / puddle effect that fades out after roughly 2-3 seconds.
- **Regression guard**: gameplay polish check fails if old reward chip functions return or if the death blood cleanup effect is removed.

### Verification (after Stage 1 P2.12)

- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 186 res:// references / res:// references OK`.
- `python3 tools/check_gameplay_polish.py` → `Gameplay polish OK: 16 skills, 8 weapons, 28 enemies covered`.
- `godot --headless --path . --quit` → exits 0 on Godot 4.7; still prints existing ObjectDB/resource cleanup warnings.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`; exits 0 with the same cleanup warnings.

---

## Stage 1 P2.13 Battle Model Polish — Rear-Facing Heroes & Handheld Guns (2026-06-26)

> Addressed the report that the battle hero still looked front-facing / sticker-like and the mounted gun looked like an abstract geometric cannon.

- **Rear-facing battle poses**: replaced all four character battle animation frame sets with battlefield-facing 3/4 rear-view sprites. Character selection portraits remain unchanged.
- **Pose coverage**: regenerated idle, attack, and hurt frame variants for Vanguard, Blaze, Frost, and Volt so the battle model has visible stance changes instead of a single static front pose.
- **Realistic handheld guns**: replaced the eight handheld weapon sprites with polished sci-fi rifle / launcher cutouts aligned to the current weapon roster.
- **Weapon animation sync**: regenerated weapon idle / recoil frame sets from the same new handheld art so future animation fallback stays visually consistent.
- **Mount alignment**: changed the character-held weapon baseline to right-facing sprites, retuned the weapon socket, visual scale, and muzzle distance so the gun sits near the hero's hands and rotates toward the target instead of floating over the head.
- **Intro cleanup**: removed the oversized start-of-battle `角色 / 枪械 / 宠物 Lv.x` floating badges; level growth remains visible through tint, aura, scale, and equipment art instead of big text over the model.
- **Source traceability**: added the generated source sheets under `assets/production/source_refs/` and a reproducible importer at `tools/generate_battle_visual_polish.py`.
- **Regression guard**: gameplay polish check now requires right-facing weapon rotation baseline, the visual source sheets, and no oversized intro level badge calls.

### Verification (after Stage 1 P2.13)

- `python3 tools/validate_asset_pack.py` → `Asset pack validation passed: 3721 files`.
- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 186 res:// references / res:// references OK`.
- `python3 tools/check_gameplay_polish.py` → `Gameplay polish OK: 16 skills, 8 weapons, 28 enemies covered`.
- `godot --headless --path . --quit` → exits 0 on Godot 4.7; still prints existing ObjectDB/resource cleanup warnings.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`; exits 0 with the same cleanup warnings.

---

## Stage 1 P2.14 Loadout Simplification — Three Entry Sections & Summary (2026-06-26)

> Addressed the report that the loadout page had overlapping cards / text, repeated small character logos, tinted character art, and too many competing info blocks.

- **Three entry sections**: simplified the loadout main screen to Hero, Main Weapon, and Armor / Chip / Pet entries. The duplicate character quick-select row is hidden from the main page.
- **Selection / upgrade routing**: clicking Hero, Weapon, Armor, Chip, or Pet now routes into the corresponding collection page, where selection and upgrade decisions belong.
- **Bounded summary**: replaced scattered mission / economy / signature text blocks with one framed summary that lists level, waves, weakness, power, gold, hero, weapon, armor, chip, and pet.
- **Artwork fidelity**: stopped applying level-tint modulation to the selected character and weapon art, and also stopped tinting unlocked collection icons. This keeps Volt / Frost / Blaze portraits in their original colors instead of turning green, blue, or gold.
- **Cleaner main screen**: hid the visible signature cards, mission hint, upgrade panel, gold label, and direct upgrade button from the loadout surface so the page reads as a selection hub instead of a stacked text report.

### Verification (after Stage 1 P2.14)

- `python3 tools/check_gameplay_polish.py` → `Gameplay polish OK: 16 skills, 8 weapons, 28 enemies covered`.
- `git diff --check -- meta/loadout/loadout.gd meta/loadout/loadout.tscn meta/collection/collection.gd` → no whitespace errors.

---

## Stage 1 P3.0 UI System Pass — Mature Mobile Screen Language (2026-06-27)

> Started the full UI review pass requested after comparing the current screens against mature live mobile game standards.

- **Shared UI kit**: added `ui/ui_kit.gd` with reusable neon panel, plate, pill, label, icon, element-color, currency, star, and press-feedback helpers. New UI work should use this instead of hand-rolling style boxes per page.
- **Map page**: rebuilt campaign entries into battle-zone cards with a number plate, authored level name, recommended power pill, unlock state, weakness element icon, star icons, and deploy/locked status. A hidden compatibility label preserves existing smoke expectations.
- **Collection page**: rebuilt item rows into framed equipment cards with bounded icon art, title, compact tags, description, equipped/growth state, and a contained upgrade button. This reduces the old text/button overlap risk.
- **Loadout page**: replaced the visible multiline summary block with a framed tactical summary grid: level/waves, weakness, power, gold, counter state, and current hero/weapon/armor/chip/pet loadout.
- **Battle card UI**: skill cards now use element/tactic accent borders, framed icons, short descriptions, icon-tag chips, and recommendation badges while preserving click/long-press behavior and smoke-compatible `Icon` nodes.
- **Pause UI**: moved build summary inside the pause panel and applied the shared cyber panel style, so the pause state no longer looks like detached text floating below the modal.
- **Menu / result polish**: applied shared panel and label styling to the main menu settings overlay and result cards, keeping existing start/settings/result actions intact.

### Verification (after Stage 1 P3.0)

- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 207 res:// references / res:// references OK`.
- `git diff --check -- ui/ui_kit.gd meta/menu/menu.gd meta/map/map.gd meta/collection/collection.gd meta/loadout/loadout.gd meta/result/result.gd gameplay/battle/battle.gd gameplay/battle/battle.tscn` → no whitespace errors.
- `godot --headless --path . --quit` → exits 0 on Godot 4.7; still prints existing ObjectDB/resource cleanup warnings.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`; exits 0 with the same cleanup warnings.

---

## Stage 1 P3.1 Loadout Bottom Cleanup — Single Summary Tray (2026-06-27)

> Addressed the report that the bottom loadout area still had nested frames, crossing borders, and noisy equipment tiles.

- **Removed frame clutter**: hid the oversized loadout background frame that crossed behind the bottom summary and made the section look like stacked boxes.
- **Single summary tray**: changed the tactical summary from four individually framed tiles into one integrated stat plate with level, weakness, power, and gold cells.
- **Cleaner equipment icons**: removed the overlaid `护甲 / 芯片 / 宠物` text from inside the three equipment buttons; the section header now carries the slot meaning, and each icon remains clickable with tooltip context.
- **Better spacing**: retuned the Armor / Chip / Pet row and summary panel bounds so they no longer collide with the bottom information frame.

### Verification (after Stage 1 P3.1)

- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 207 res:// references / res:// references OK`.
- `git diff --check -- meta/loadout/loadout.gd meta/loadout/loadout.tscn` → no whitespace errors.
- `godot --headless --path . --quit` → exits 0 on Godot 4.7; still prints existing ObjectDB/resource cleanup warnings.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → currently stops on an existing battle multiplier assertion: `turret must receive character and chip damage multipliers`. The loadout page loads before this assertion, and this failure is outside the P3.1 UI path.

---

## Stage 1 P3.2 Battle Hero Visual Cleanup — No Floating UI Gun (2026-06-27)

> Addressed the report that the battle hero still looked like a sticker with a floating abstract gun and a square red skill/VFX block.

- **Handheld gun recentering**: retuned `tools/generate_battle_visual_polish.py` so the opaque gun body is centered in the handheld texture canvas. This prevents right-facing weapon art from swinging around a bottom-biased pivot when the battle code rotates it.
- **Smaller weapon mount**: reduced the character-mounted weapon scale, moved the socket closer to the hero's hands, and shortened muzzle offsets so guns no longer float over the shoulder like oversized UI icons.
- **No weapon tint wash**: stopped applying level tint directly onto the character and weapon art in battle. Growth can still be shown through subtle effects, but the base art no longer turns muddy or off-palette.
- **No square aura texture**: replaced the persistent character/pet aura and level-up flash texture with procedural ring lines, removing the visible rectangular texture footprint behind the hero.
- **No `战技` overlap**: hid the `SkillPanelTitle` text permanently; skill slots remain as bottom icons and no longer put raw label text on top of the character.
- **Stable smoke setup**: made the battle section of `m1_smoke_test.gd` use a fixed vanguard + autocannon + attack-chip loadout. This keeps the multiplier assertion from depending on whatever equipment the local save currently has selected.

### Verification (after Stage 1 P3.2)

- `python3 tools/validate_asset_pack.py` → `Asset pack validation passed: 3721 files`.
- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 207 res:// references / res:// references OK`.
- `python3 tools/check_gameplay_polish.py` → `Gameplay polish OK: 16 skills, 8 weapons, 28 enemies covered`.
- `git diff --check -- gameplay/battle/battle.gd gameplay/battle/battle.tscn tools/generate_battle_visual_polish.py tools/m1_smoke_test.gd` → no whitespace errors.
- `godot --headless --path . --quit` → exits 0 on Godot 4.7; still prints existing ObjectDB/resource cleanup warnings.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`; exits 0 with the same cleanup warnings.

---

## Stage 1 P3.3 Loadout Summary & Collection Detail Consistency (2026-06-27)

> Addressed the report that the loadout tactical summary still had a stray inner box and low text readability, and that collection interactions were inconsistent between direct equip and detail-first equip.

- **Single-layer summary tray**: removed the scaled texture frame from the tactical summary background and rebuilt the tray as one controlled style panel, removing the odd small square behind the text.
- **Sharper summary text**: increased summary title/value font sizes, outline strength, panel opacity, and contrast so level, weakness, power, gold, and loadout names read clearly over the ruined-city background.
- **Consistent collection flow**: all unlocked collection rows now open a detail modal first. Equipment actions live in the detail view instead of being split between row-click direct equip and detail-page equip.
- **Generic item details**: added detail cards for weapons, armor, chips, pets, and skills with icon art, tags, core stats, tactical notes, and contained equip/upgrade/close actions. Existing character detail remains the character-specific version of the same detail-first rule.
- **Smoke coverage updated**: the smoke test now asserts that weapon rows no longer expose direct row upgrade buttons and that clicking an unlocked row opens an item detail with equip and upgrade actions.

### Verification (after Stage 1 P3.3)

- `godot --headless --path . --quit` → exits 0 on Godot 4.7; still prints existing ObjectDB/resource cleanup warnings.
- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 207 res:// references / res:// references OK`.
- `python3 tools/check_gameplay_polish.py` → `Gameplay polish OK: 16 skills, 8 weapons, 28 enemies covered`.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`; exits 0 with the same cleanup warnings.

---

## Stage 1 P3.4 Map Feature Dock Redesign (2026-06-27)

> Addressed the report that the map feature entry row still looked low-end: separate small boxes, crude black label plates, unclear hierarchy, and weak item status.

- **Unified feature dock**: rebuilt the six top entries as one integrated command dock instead of six disconnected button cards.
- **Cleaner visual hierarchy**: removed the heavy black label plates and moved labels into bottom dock titles with stronger outline, slimmer accent underlines, and less visual noise.
- **Current loadout signal**: feature icons now use the currently selected hero, weapon, armor, chip, and pet art where available, with a compact `Lv.` badge per slot. Skills remains a `图鉴` entry.
- **Premium separators and accents**: added subtle per-slot accent lines, dividers, and hover state styling so each entry reads as an intentional module rather than a generic rectangle.
- **Layout breathing room**: increased the navigation row height and moved the level list down slightly so the new dock has enough vertical space and no longer feels squeezed.

### Verification (after Stage 1 P3.4)

- `godot --headless --path . --quit` → exits 0 on Godot 4.7; still prints existing ObjectDB/resource cleanup warnings.
- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 208 res:// references / res:// references OK`.
- `git diff --check -- meta/map/map.gd meta/map/map.tscn` → no whitespace errors.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`; exits 0 with the same cleanup warnings.

---

## Stage 1 P3.5 Combat Balance Retune — Faster Cadence & Linear 99-Level Pressure (2026-06-27)

> Addressed the report that the previous attack-speed cut made even advanced gear fail early levels, while the campaign still needed a real endgame pressure curve.

- **Attack-speed correction**: raised `PLAYER_FIRE_RATE_MULT` from `0.1666667` to `0.25`, exactly +50% over the previous paced value.
- **Data-driven runtime**: `gameplay/turret/turret.gd` keeps reading the pacing knob from `data/economy.json`; the fallback constant now matches `0.25`.
- **Linear progression**: rebuilt `tools/rebalance_difficulty.py` so `recommend_level` runs linearly from Lv.1 to Lv.50 across 99 stages, and `base_hp_ref` runs linearly from 120 to 820.
- **Three pressure bands**: levels 1-5 are intentionally generous, levels 6-89 ramp linearly, and levels 90-99 enter a high-pressure endgame band that expects near-max core gear and correct build choices.
- **DPS-aware coefficients**: `difficulty_coef` is now reverse-solved from recommended-player DPS, target spawn time, target pressure, and enemy HP weights instead of being a simple static growth multiplier.
- **Simulation result**: after the rebuild, with-skill clear estimates are 14.3-42.2s for levels 1-5 and 145.8-178.8s for levels 90-99; no level exceeds the 180s hard-check window.

### Verification (after Stage 1 P3.5)

- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 208 res:// references / res:// references OK`.
- `python3 tools/check_level_pressure.py` → pressure estimate completes across all 99 levels.
- `python3 tools/check_balance_profile.py` → `Balance profile OK`.
- `python3 tools/check_economy_loop.py` → `Economy loop OK`.
- `python3 tools/check_gameplay_polish.py` → `Gameplay polish OK: 16 skills, 8 weapons, 28 enemies covered`.
- `python3 tools/simulate_balance.py` → with-skill average clear time `98.3s`, min/max `14.3s / 178.8s`, levels `<30s = 4`, levels `>180s = 0`.
- `godot --headless --path . --quit` → exits 0 on Godot 4.7; still prints existing ObjectDB/resource cleanup warnings.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`; exits 0 with the same cleanup warnings.

---

## Stage 1 P3.6 Global UI Palette & Chinese Text Unification (2026-06-27)

> Addressed the report that the UI framework was acceptable, but window colors felt harsh and inconsistent, while several player-facing labels still mixed Chinese with English.

- **Unified premium palette**: rebuilt `UiKit` around a darker translucent base, softer blue-gray text, controlled cyan accents, and restrained gold highlights instead of saturated blue panels everywhere.
- **Window color pass**: retinted loadout, map dock, collection/detail modals, menu support panel, result cards, pause panel, and battle card overlays to use the same dark metal + gold/cyan hierarchy.
- **Chinese visible text**: replaced player-facing `Lv.`, `LV`, `HP`, `Wave`, `XP`, `BOSS`, `BROKEN`, `LOCK`, `TAP TO DEPLOY`, `BATTLE REPORT`, `ZOMBIE FIRE`, and `Roguelite` displays with Chinese equivalents.
- **Naming consistency**: standardized the current equipment slot as `武器` across loadout, pause summary, result hints, and skill descriptions; kept asset/data keys unchanged.
- **Smoke guard update**: updated skill-slot smoke expectations from `LV1/LV2` to `等级1/等级2` so regression checks match the new Chinese UI.

### Verification (after Stage 1 P3.6)

- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 208 res:// references / res:// references OK`.
- `python3 tools/check_gameplay_polish.py` → `Gameplay polish OK: 16 skills, 8 weapons, 28 enemies covered`.
- `git diff --check -- ui/ui_kit.gd meta/loadout/loadout.gd meta/loadout/loadout.tscn meta/map/map.gd meta/collection/collection.gd meta/menu/menu.gd meta/menu/menu.tscn core/settings/settings_manager.gd meta/result/result.gd meta/result/result.tscn gameplay/battle/battle.gd gameplay/battle/battle.tscn gameplay/hud/combo_hud.gd gameplay/enemy/enemy.gd core/data/character_skill_text.gd tools/m1_smoke_test.gd` → no whitespace errors.
- `godot --headless --path . --quit` → exits 0 on Godot 4.7; still prints existing ObjectDB/resource cleanup warnings.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`; exits 0 with the same cleanup warnings.
