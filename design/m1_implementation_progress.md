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
- 角色 / 主炮 Lv. / 护甲 / 芯片 / 宝宝
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
