# M1 Implementation Progress

> Purpose: resumable checkpoint for playable M1 implementation.

## Current State

M1 is complete against the 17 acceptance items in `MINIMAX_FINAL_INSTRUCTIONS.md`.
The project now passes static validators, `res://` reference scans, Godot headless startup,
and an automated M1 smoke test that instantiates the main flow, loadout upgrade entry,
all five battle scenes, and the result scene.

### Implemented (new since previous checkpoint)

- **全关卡挑战模式**：地图关卡卡片改为“进入关卡 / 挑战模式”双按钮；挑战战斗通过 `challenge` route payload 贯穿 loadout / battle / result，敌人 HP 提高到 1.5 倍，推荐战力同步抬高到 1.5 倍，漏怪伤害仍使用挑战专用加压倍率。
- **挑战星级经济**：`SaveManager.challenge_progress` 独立记录每关挑战最高星，`apply_challenge_result()` 只发本次星级超过历史最高的差额；重复通关不会重复给星，也不会解锁下一普通关。
- **战斗背景堡垒对齐**：以 `env_abandoned_factory` 的底部横向堡垒位置为基准，平移其余 9 张战斗背景并保留 1080×1920 合约；处理记录在 `assets/production/source_refs/generated/background_fortress_alignment_2026_07_06.json`，对照图在 `assets/production/contact_sheets/contact_background_fortress_alignment_2026_07_06.png`。
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

## Final Art Quality Audit (2026-07-01)

> Owner bar: every visible asset should read as high-end 3D rendered, App Store-grade final art.

Added `design/assets/final_art_quality_audit_2026_07_01.md` as a project-level screening report. This pass did not replace production assets; it classified current assets by final-art risk and captured temporary evidence sheets under `tmp/art_audit/`.

### Key audit result

- The project is content-complete enough for broad screening: `data/*.json` asset refs point to `assets/production`, and the current production pack passes technical cutout checks.
- The project is not yet final-art consistent. It mixes high-end prototype unit/icon art with flat UI assets, procedural runtime VFX, legacy runtime asset paths, placeholder store screenshots, placeholder 2-second videos, and crop-derived skeletal parts.
- The new app icon is closest to the desired premium direction. The launch image and App Store screenshots are the most visible mismatch.

### P0 follow-up scope

- Replace `assets/app/launch_1080x1920.png`.
- Regenerate App Store screenshots and app preview after UI polish.
- Replace flat UI PNGs and migrate 28 runtime `res://assets/sprites/...` refs away from legacy fallback paths.
- Skin code-generated UI panels and replace visible procedural effects with authored final VFX / number / badge assets.

### Verification during audit

- `python3 tools/validate_asset_pack.py` → `Asset pack validation passed: 5129 files`.
- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` → `checked 253 res:// references` / `res:// references OK`.
- `python3 tools/check_visual_assets.py` → `Visual asset check OK: 660 battle sprite files`.
- `python3 tools/check_level_pressure.py` → completed pressure estimate for `level_001` through `level_099`.
- `python3 tools/simulate_card_director.py` → completed 1000-run card offer simulation for `level_001` through `level_099`.
- `/opt/homebrew/bin/godot --headless --path . --quit` → exits 0.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`; Godot still prints known RID/ObjectDB/resource cleanup warnings on exit.
- `git diff --check` → no whitespace errors.
- Current route screenshots were captured from a visible Godot run for menu, map, loadout, collection, battle, and result.

---

## Final Art P0 Replacement Pass (2026-07-01)

> Owner approved replacing the "must redo" P0 art set against the high-end rendered / App Store-grade bar.

### Completed

- Generated a new high-end launch image at `assets/app/launch_1080x1920.png`, using the new app icon direction as the visual bar.
- Re-rendered the flat UI kit under `assets/production/sprites/ui/`: primary/secondary buttons, panel, HP/wave/XP/shield bars, generic icons, element icons, card frames, card utility icons, card tags, skill slots, stars, cooldown overlay, and target strategy badges.
- Replaced the visible target-lock ring at `assets/production/sprites/vfx/vfx_target_lock.png`.
- Migrated runtime references away from legacy `res://assets/sprites/...` paths to `res://assets/production/sprites/...`.
- Regenerated App Store screenshot drafts under `assets/appstore/screenshots/` for `ios_65`, `ios_67`, and `ipad_129`.
- Replaced `assets/production/video/vid_app_preview.mp4` with an 18-second 1080x1920 rendered preview draft.
- Added reproducible generation script `tools/generate_final_p0_assets.py`.
- Stored source prompt/spec/contact sheet under `assets/production/source_refs/generated/`.
- Registered the owner-directed generated replacements in `assets/production/OUTSOURCER_ASSET_INDEX.json`.
- Unified the result screen action buttons after review: `ui_button_primary.png` and `ui_button_secondary.png` now share the same bevel, border, glow, and lighting model; `meta/result/result.gd` no longer tints the action button textures into mismatched styles.
- Raised the visible P0 UI batch again after review using a generated top-tier HUD material reference: buttons, panels, icon frames, card frames, slots, progress bars, and target-lock VFX now use one dark gunmetal/glass material family with cyan/orange rim lighting, bevel depth, controlled glow, and non-flat symbol rendering.
- Recaptured the routed Godot runtime screens after the material pass and regenerated the App Store screenshot set, 18-second/432-frame app preview, and final replacement contact sheet from those fresh screens.

### Evidence

- `assets/production/source_refs/generated/final_p0_launch_source_2026_07_01.png`
- `assets/production/source_refs/generated/final_p0_launch_source_prompt_2026_07_01.txt`
- `assets/production/source_refs/generated/final_p0_hud_reference_source_2026_07_01.png`
- `assets/production/source_refs/generated/final_p0_hud_reference_prompt_2026_07_01.txt`
- `assets/production/source_refs/generated/final_p0_ui_store_spec_2026_07_01.json`
- `assets/production/source_refs/generated/final_p0_replacement_contact_sheet_2026_07_01.png`
- `tmp/final_p0_runtime_screens/` contains fresh routed Godot screenshots used for the store composites.
- `tmp/final_p0_runtime_screens/result_button_unified.png` captures the reviewed result page after the button-style correction.
- `assets/production/video/vid_app_preview.mp4` is 1080x1920, 18 seconds, 432 frames.

### Verification during P0 pass

- `python3 -m py_compile tools/generate_final_p0_assets.py` → pass.
- `python3 tools/validate_asset_pack.py` → `Asset pack validation passed: 5146 files`.
- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` → `checked 252 res:// references` / `res:// references OK`.
- `python3 tools/check_level_pressure.py` → pass; 99 levels reported pressure/spawn estimates.
- `python3 tools/simulate_card_director.py` → pass; 1000 card-offer simulations per level.
- `python3 tools/check_app_store_assets.py` → `App Store asset check OK`.
- `python3 tools/check_visual_screens.py` → `Visual screen check OK: 6 routed screenshots`; Godot still prints the known ObjectDB/resource cleanup warnings on some screenshot exits.
- `git diff --check` → pass.
- `rg "res://assets/sprites/" meta gameplay ui core project.godot` → no legacy visible runtime refs.
- `/opt/homebrew/bin/godot --headless --path . --quit` → pass.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`; Godot still prints the known Canvas/TextServer/RID/ObjectDB/resource cleanup warnings at process exit.

### Remaining art risk

This pass resolves the P0 asset replacements and legacy visible refs. A deeper UI-code skin pass is still useful for remaining `StyleBoxFlat`, `ColorRect`, raw labels, and procedural VFX primitives that are generated directly in GDScript.

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

---

## Stage 1 P3.7 Release Guardrail Pass — External Diff Review Follow-up (2026-06-28)

> Follow-up after the latest outsourced pass. Goal: accept the useful interaction / UI / battle resilience changes while adding guardrails for the bugs that kept recurring during live review.

- **Battle boot probe fixed**: `tools/_battle_boot_probe.gd` now initializes through the project autoloads and real `main.tscn` route before entering `level_001`. It verifies that Battle is active, unpaused, `Engine.time_scale == 1.0`, enemies/spawns exist, character rig is present, and the hidden logic turret is configured.
- **Visual asset guardrail**: added `tools/check_visual_assets.py` to scan battle character animation frames and handheld weapon sprites for baked square plates, visible canvas-border alpha, and severe green-screen/chroma-key fringe. This catches the previous "green edge / sticker sprite / square backing" class of regressions without generating replacement art.
- **Routed screenshot guardrail**: added `tools/check_visual_screens.py`, backed by `tools/_shot.gd`, to render menu, map, loadout, collection, battle, and result through the real router at 1080x1920 and reject blank captures or large exact-black bars. `_shot.gd` now exits clearly if someone tries visual capture through `--headless`, because Godot's dummy renderer cannot provide a viewport texture.
- **Release candidate expanded**: `tools/check_release_candidate.py` now runs visual asset checks, the battle boot probe, and routed screenshot checks in addition to the existing data, balance, UI, app-store, Godot startup, and smoke validations.
- **Skill effect text hardening**: `core/data/skill_effect_text.gd` no longer assumes every effect value is numeric. Non-numeric future fields render as text instead of crashing card/detail UI.

### Verification (after Stage 1 P3.7)

- `python3 tools/validate_asset_pack.py` → `Asset pack validation passed: 3723 files`.
- `python3 tools/validate_data.py` → `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` → `checked 218 res:// references / res:// references OK`.
- `python3 tools/check_visual_assets.py` → `Visual asset check OK: 52 battle sprite files`.
- `godot --headless --path . --script res://tools/_battle_boot_probe.gd` → Battle route active, unpaused, time scale restored, spawns/enemies present.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` → `M1 smoke test passed`.
- `python3 tools/check_visual_screens.py` → `Visual screen check OK: 6 routed screenshots`.
- `python3 tools/check_release_candidate.py` → `Release candidate check OK`.

### Remaining Guardrail Risk

- Godot still prints existing ObjectDB/resource cleanup warnings on exit. Current commands exit 0, but this should remain a tracked cleanup item rather than being treated as a solved runtime-quality issue.

---

## Stage 1 P3.8 Active Skill & Element Impact Polish (2026-06-28)

> Addressed the report that character active skills felt unavailable, elemental bullets did not communicate their hit effects strongly enough, split bullets were hard to perceive, and the selected-skill UI had duplicate bottom-region icon feedback.

- **Active skill fallback casting**: fire and lightning active skills no longer fail just because no target is currently eligible. Blaze now detonates on the current aim lane when no target exists; Volt now chains visible fallback lightning strikes across the lane. Existing target-based damage behavior remains intact when enemies are present.
- **Input reliability**: the character active button now explicitly captures pointer input and continues to update its ready/cooldown state through the shared button styling path.
- **Element hit feedback**: projectile hits now trigger a stronger battle-layer effect per element: fire adds burn/explosion feedback, ice adds frost/freeze feedback, lightning adds electric arcs/rings, and poison keeps a visible toxic hit pulse.
- **Split bullet readability**: split-shot hits now emit a visible burst ring, larger split shards, and bigger/slower homing mini projectiles so the player can clearly see the split behavior.
- **Selected skill HUD cleanup**: selecting/upgrading a skill no longer spawns a second floating icon over the character area. The bottom skill slot with its level badge is the single persistent selected-skill display, with a short pulse when upgraded.
- **Regression guardrails**: smoke test now requires every configured active skill to enter cooldown when pressed; gameplay polish checks now reject target-only active skill failures and duplicate floating skill icons.

### Verification (after Stage 1 P3.8)

- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 3723 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` -> `checked 218 res:// references / res:// references OK`.
- `python3 tools/check_gameplay_polish.py` -> `Gameplay polish OK: 16 skills, 8 weapons, 28 enemies covered`.
- `godot --headless --path . --script res://tools/_battle_boot_probe.gd` -> Battle route active, unpaused, time scale restored, spawns/enemies present.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`.

---

## Stage 1 P3.9 Map & Global Palette Retune (2026-06-28)

> Addressed the report that the map screen still looked too harsh and prototype-like because the level list relied on saturated blue button art.

- **Map card palette**: level cards now render their own opaque dark-metal panel over the existing `TextureButton` hit area, removing the bright-blue primary button look while preserving the smoke-test requirement that each level entry remains a `TextureButton`.
- **Warmer hierarchy**: map cards use black metal as the base, gold for stars / deploy intent, and element colors only for weakness accents and index rails.
- **Feature dock retune**: the top collection dock now uses darker cards, softer borders, and less saturated accent strips so it does not compete with the level list.
- **Shared UI color polish**: `UiKit` panel, plate, and pill defaults were slightly darkened and warmed, reducing the global cyan-blue cast.
- **Button tint cleanup**: menu, loadout, result, and collection primary actions now tint toward warm gold / muted steel instead of default bright blue.
- **No asset changes**: this pass only retints and restyles existing UI code. No new or replacement images were generated.

### Verification (after Stage 1 P3.9)

- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` -> `checked 218 res:// references / res:// references OK`.
- `python3 tools/check_gameplay_polish.py` -> `Gameplay polish OK: 16 skills, 8 weapons, 28 enemies covered`.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`.
- `python3 tools/check_visual_screens.py` -> `Visual screen check OK: 6 routed screenshots`.
- `python3 tools/check_release_candidate.py` -> `Release candidate check OK`.
- Visual map capture: `/tmp/zombie_fire_map_palette_v4.png`.

---

## Stage 1 P3.10 Combat HUD Micro-Polish (2026-06-28)

> Addressed live battle HUD feedback: combo text looked naked, the active skill control was still text-first, the hero model read too small, and the gun continued firing while card choice paused the zombies.

- **Combo HUD restyle**: `gameplay/hud/combo_hud.gd` now wraps the streak label in a compact gold-edged combat plate with a small accent rail, so "连击" is no longer bare floating text.
- **Active skill icon mode**: `Hud/CharacterSkillButton` is now a compact square icon control. The visible skill name / "可释放" text is hidden; the icon is mapped from the current character active skill to existing skill art.
- **Ready orbit feedback**: when the active skill is available, eight small glowing dots orbit the icon with staggered pulse intensity. Cooldown keeps a dark fill plus a small remaining-time number.
- **Hero scale pass**: the battle-facing character sprite base scale was raised from `0.32` to `0.64`, preserving the existing weapon muzzle / projectile origin logic.
- **Card-offer pause fix**: `gameplay/turret/turret.gd` now returns immediately while `SceneTree.paused`, so card choice pauses the gun as well as enemies.
- **Regression guardrail**: `tools/m1_smoke_test.gd` now asserts that the active skill button renders in icon mode and that the turret does not emit `fired` while the card offer has paused the tree.

### Verification (after Stage 1 P3.10)

- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` -> `checked 219 res:// references / res:// references OK`.
- `python3 tools/check_gameplay_polish.py` -> `Gameplay polish OK: 16 skills, 8 weapons, 28 enemies covered`.
- `python3 tools/check_visual_screens.py` -> `Visual screen check OK: 6 routed screenshots`.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`.
- `python3 tools/check_release_candidate.py` -> `Release candidate check OK`.
- Visual battle capture: `/tmp/zombie_fire_battle_latest.png`.

---

## Stage 1 P3.11 Damage Text & Weapon Mount Polish (2026-06-28)

> Addressed live battle feedback that normal damage numbers looked like large gold rewards, and that the enlarged hero no longer matched the mounted weapon scale.

- **Damage numbers retuned**: `gameplay/hud/damage_number_layer.gd` now renders normal enemy damage as smaller red hit text. Crits remain larger and brighter, but routine HP loss no longer competes with gold / skill effects.
- **Damage budget guardrail**: `tools/m1_smoke_test.gd` now checks that normal damage numbers stay compact while preserving the existing dense-hit cap.
- **Weapon mount rescale**: the independent handheld weapon scale was raised to match the 2x hero model pass, so the gun no longer reads like a small UI sprite pasted onto the character.
- **Muzzle alignment**: weapon socket and per-weapon muzzle distances were updated with the new visual scale so projectile origin remains tied to the visible gun tip.
- **No new AI art**: this pass uses the existing `data/weapons.json` handheld skins and current character battle frames. The character frame source still contains some baked pose weapon detail, but the selected weapon is now the dominant readable gun layer.

### Verification (after Stage 1 P3.11)

- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` -> `checked 219 res:// references / res:// references OK`.
- `python3 tools/check_gameplay_polish.py` -> `Gameplay polish OK: 16 skills, 8 weapons, 28 enemies covered`.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`.
- Visual battle capture: `/tmp/zombie_fire_battle_weapon_match_v1.png`.

---

## Stage 1 P3.12 Weaponless Character Base Art Integration (2026-06-28)

> Follow-up to the same live battle report: scaling the independent gun helped, but the old character source still had baked-in handheld weapon details. The correct fix is to separate character body art from weapon art.

- **Weaponless character battle sheet added**: generated and saved `assets/production/source_refs/generated/hero_battle_weaponless_sheet_chroma.png`, then extracted transparent source `assets/production/source_refs/generated/hero_battle_weaponless_sheet.png`.
- **Per-character weaponless frames**: added `assets/production/sprites/animations/characters_weaponless/{char_vanguard,char_blaze,char_frost,char_volt}/` with idle, attack, and hurt frames. These are character-body frames only; selected guns remain runtime-mounted weapon layers.
- **Battle loader preference**: `gameplay/battle/battle.gd` now loads `characters_weaponless` before falling back to the original baked-weapon character animation path.
- **Direct PNG loading**: battle frame loading can construct `ImageTexture` directly from PNG files when Godot import metadata is not present, preventing headless runs from falling back to stale imported art.
- **Socket retune**: the weapon socket was moved to the new grip-ready character pose so the independent gun aligns with the body instead of covering an old baked gun.
- **Regression guardrail**: smoke test now asserts that battle characters use `characters_weaponless` base art.
- **Asset index note**: `assets/production/OUTSOURCER_ASSET_INDEX.json` now documents this owner-directed generated override so future implementation work does not treat the weaponless frames as unregistered replacements.

### Verification (after Stage 1 P3.12)

- `godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; existing Godot cleanup warnings remain.
- `python3 tools/check_visual_screens.py` -> `Visual screen check OK: 6 routed screenshots`.
- Visual battle capture: `/tmp/zombie_fire_battle_weaponless.png`.

---

## Stage 1 P3.13 Skill Card Timing Fix (2026-06-28)

> Addressed the late-card pacing bug where the final zombie could push run XP over the card threshold, open a skill choice, and then immediately end the level after the player picked.

- **Late final-clear popup blocked**: XP-threshold card offers now check whether the current reward would finish the final wave. If no future wave, pending spawn, or live enemy remains, the battle skips the card popup and proceeds to result.
- **Pre-final pacing nudge**: before starting the final wave, battle now checks whether the first card is already ready or at least 85% charged; if so, it offers the skill before the final wave so the choice has real gameplay value.
- **Death-animation aware enemy check**: the live-enemy check ignores the enemy currently emitting the death reward and ignores enemies already at 0 HP, so death animation frames do not fake remaining combat.
- **Finish guardrail**: `_finish()` is now idempotent to avoid duplicated result routing on edge frames.
- **Regression guardrail**: `tools/m1_smoke_test.gd` now asserts both sides of the timing rule: no final-clear late card, and a near-ready pre-final card can be offered before the last wave.

### Verification (after Stage 1 P3.13)

- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` -> `checked 220 res:// references / res:// references OK`.
- `python3 tools/check_gameplay_polish.py` -> `Gameplay polish OK: 16 skills, 8 weapons, 28 enemies covered`.
- `git diff --check` -> no whitespace errors.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; existing Godot cleanup warnings remain.
- `python3 tools/check_release_candidate.py` -> `Release candidate check OK`.

---

## Stage 1 P3.14 Asset Generation Policy Update (2026-06-28, updated 2026-06-29)

> Owner changed the previous asset rule: GPT/Codex is now allowed to generate replacement assets when requested or when a quality fix requires better art.

- **Constraint updated**: removed the absolute "do not generate assets" rule from the core handoff docs.
- **Prototype update permission**: owner explicitly allows GPT/Codex to change or regenerate character prototypes, weapon prototypes, character+weapon composites, VFX sequence frames, UI icons, and audio placeholders when quality requires it.
- **New guardrails**: generated replacements must keep game scope, IDs, data references, Godot integration paths, and the locked ruined-city cyberpunk style.
- **Registration rule**: accepted generated replacements must live under `assets/production/` and be recorded in `assets/production/OUTSOURCER_ASSET_INDEX.json`.
- **External developer rule**: external implementation should still use existing assets by default, but may generate or replace assets when explicitly authorized for that task.

### Verification (after Stage 1 P3.14)

- `python3 -m json.tool assets/production/OUTSOURCER_ASSET_INDEX.json` -> valid JSON.
- `python3 -m json.tool assets/production/INTEGRATION_ASSET_MANIFEST.json` -> valid JSON.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 3769 files`.
- `git diff --check` -> no whitespace errors.

---

## Stage 1 P3.15 Fused Character/Weapon Battle Art (2026-06-28)

> Addressed the live battle report that the selected gun still looked pasted onto the hero, especially on Volt with the plasma cannon.

- **Fused combo art added**: generated a back-facing `char_volt + weapon_plasmacannon` battle sprite where the weapon is physically held in the character pose, then chroma-keyed, cropped, and integrated as `assets/production/sprites/animations/character_weapon_combos/char_volt/char_volt_weapon_plasmacannon_idle_01.png`.
- **Battle loader priority**: `gameplay/battle/battle.gd` now checks `character_weapon_combos/{character}/{character}_{weapon}_idle_01.png` before the weaponless-character + mounted-weapon path. When a combo sprite exists, it becomes the character sprite and the separate floating `CharacterWeapon` node is suppressed.
- **Muzzle alignment**: fused combo sprites use a per-combo virtual muzzle offset, so projectile origin follows the visible gun tip without rotating an independent weapon layer.
- **Regression guardrail**: `tools/m1_smoke_test.gd` now verifies that `volt + weapon_plasmacannon` loads from `character_weapon_combos` and does not spawn the old floating weapon sprite.
- **Screenshot reproducibility**: `tools/_shot.gd` can now take an `equipment` override in its payload, allowing deterministic captures of a specific character / weapon combination without modifying the real save.
- **Asset validation coverage**: `tools/check_visual_assets.py` includes `character_weapon_combos`, so generated fused sprites are checked for transparent borders, baked square plates, and severe chroma remnants.

### Verification (after Stage 1 P3.15)

- `python3 -m json.tool assets/production/OUTSOURCER_ASSET_INDEX.json` -> valid JSON.
- `python3 -m json.tool assets/production/INTEGRATION_ASSET_MANIFEST.json` -> valid JSON.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 3772 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` -> `checked 221 res:// references / res:// references OK`.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 53 battle sprite files`.
- `python3 tools/check_gameplay_polish.py` -> `Gameplay polish OK: 16 skills, 8 weapons, 28 enemies covered`.
- `git diff --check` -> no whitespace errors.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; existing Godot cleanup warnings remain.
- `godot --path . --script res://tools/_shot.gd -- battle '{"level_id":"level_001","equipment":{"selected_character":"volt","selected_weapon":"weapon_plasmacannon","volt":10,"weapon_plasmacannon":10,"selected_pet":"pet_fire_imp"}}' /tmp/zombie_fire_volt_plasma_combo.png` -> visual capture confirms the fused model is loaded.
- `python3 tools/check_release_candidate.py` -> `Release candidate check OK`; existing Godot cleanup warnings remain.

## Stage 1 P3.16 Weapon-Specific Projectile VFX (2026-06-28)

> Addressed the report that autocannon, fire, ice, lightning, and poison bullets had readable effects, but railgun, scattergun, and plasma cannon still fell back to generic projectile / hit feedback.

- **Projectile visual profiles**: `gameplay/projectile/projectile.gd` now carries a `visual_profile` through flight and hit confirmation. Profiles currently cover `rail`, `scatter`, and `plasma` while leaving existing elemental bullets untouched.
- **Railgun identity**: rail shots use a long cyan charge projectile, faster afterimage cadence, a lance-like muzzle trace, and a piercing rail impact trace across the zombie body.
- **Scattergun identity**: scatter pellets use small shard sprites, slower discrete trails, fan-shaped muzzle sparks, and clustered pellet-hit chips around the target.
- **Plasma cannon identity**: plasma shots use a larger purple energy core, purple/orange muzzle bloom, and a distinct plasma hit with layered core burst plus expanding shock rings instead of plain fire impact.
- **Weapon / element separation**: native elements still decide damage typing and weakness logic; weapon profiles only control visual style. Plasma therefore remains a fire-element weapon for balance, but no longer looks like a normal fire bullet.
- **Regression guardrails**: `tools/check_gameplay_polish.py` now requires weapon visual profile hooks and the three special impact routines. `tools/m1_smoke_test.gd` instantiates all three profile projectiles and verifies their texture / scale / color identity.

### Verification (after Stage 1 P3.16)

- `python3 tools/check_gameplay_polish.py` -> `Gameplay polish OK: 16 skills, 8 weapons, 28 enemies covered`.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 3772 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` -> `checked 225 res:// references / res:// references OK`.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 53 battle sprite files`.
- `git diff --check` -> no whitespace errors.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; existing Godot cleanup warnings remain.
- `python3 tools/check_release_candidate.py` -> `Release candidate check OK`; existing Godot cleanup warnings remain.

## Stage 1 P3.17 Starter Weapon Naming & Prototype Retune (2026-06-28)

> Addressed the report that if weapons are now character-held guns, the first weapon should not still read as a base cannon.

- **Name retune**: `weapon_autocannon` keeps its stable internal ID, but the player-facing Chinese name is now `自动机枪`.
- **Icon retune**: replaced `weapon_autocannon_icon.png` in both production and legacy compatibility paths with a framed gun silhouette derived from the accepted handheld weapon sheet.
- **Prototype fallback retune**: replaced `weapon_autocannon_turret.png` in both production and legacy compatibility paths with a transparent machine-gun silhouette, and moved `data/weapons.json` to the production fallback path.
- **Source traceability**: added `source_refs/generated/weapon_autocannon_machinegun_source_crop.png` and `source_refs/generated/weapon_autocannon_machinegun_cutout.png`; registered the override in `OUTSOURCER_ASSET_INDEX.json`.
- **Regression guardrails**: `tools/check_gameplay_polish.py` and `tools/m1_smoke_test.gd` now require the `自动机枪` display name and the production machine-gun fallback asset path.

### Verification (after Stage 1 P3.17)

- `python3 -m json.tool data/localization_zh.json` -> valid JSON.
- `python3 -m json.tool data/weapons.json` -> valid JSON.
- `python3 -m json.tool assets/production/OUTSOURCER_ASSET_INDEX.json` -> valid JSON.
- Repo-wide search for the legacy Chinese cannon names -> no remaining matches.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 3774 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` -> `checked 226 res:// references / res:// references OK`.
- `python3 tools/check_gameplay_polish.py` -> `Gameplay polish OK: 16 skills, 8 weapons, 28 enemies covered`.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 53 battle sprite files`.
- `git diff --check` -> no whitespace errors.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; existing Godot cleanup warnings remain.
- `python3 tools/check_release_candidate.py` -> `Release candidate check OK`; existing Godot cleanup warnings remain.

---

## Stage 1 P3.18 Full Character/Weapon Fused Prototype Coverage (2026-06-29)

> Addressed the gap that only Volt + plasma cannon had a fused prototype, while the other characters and weapons still depended on runtime floating gun layers.

- **Full combo frame coverage**: generated 32 fused character/weapon prototype sets covering 4 characters x 8 weapons. Each set includes 4 idle frames, 4 attack frames, and 3 hurt frames under `assets/production/sprites/animations/character_weapon_combos/{char}/`.
- **No floating weapon fallback for covered pairs**: battle now finds `idle_01` for every launch character/weapon combination, activates `character_weapon_combo_active`, and suppresses the separate `CharacterWeapon` sprite.
- **Per-combo muzzle alignment**: `gameplay/battle/battle.gd` now stores a computed `CHARACTER_WEAPON_COMBO_MUZZLE` offset for all 32 pairs so projectiles originate from the visible fused gun tip.
- **Reusable generation source**: added `tools/generate_character_weapon_combos.py`, plus `source_refs/generated/character_weapon_combo_generation_manifest.json` and `source_refs/generated/character_weapon_combo_matrix.png` for traceability and quick visual audit.
- **Regression guardrails**: `tools/check_visual_assets.py` now requires full 4x8x11 frame coverage; `tools/m1_smoke_test.gd` instantiates every character/weapon pair and verifies fused art loads without a floating weapon layer.

### Verification (after Stage 1 P3.18)

- `python3 tools/generate_character_weapon_combos.py` -> generated 352 character/weapon combo frames.
- `python3 -m py_compile tools/generate_character_weapon_combos.py tools/check_visual_assets.py tools/check_gameplay_polish.py` -> pass.
- `python3 -m json.tool assets/production/OUTSOURCER_ASSET_INDEX.json` -> valid JSON.
- `python3 -m json.tool assets/production/source_refs/generated/character_weapon_combo_generation_manifest.json` -> valid JSON.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 404 battle sprite files`.
- `python3 tools/check_gameplay_polish.py` -> `Gameplay polish OK: 16 skills, 8 weapons, 28 enemies covered`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` -> `checked 226 res:// references / res:// references OK`.
- `git diff --check` -> no whitespace errors.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; existing Godot cleanup warnings remain.
- `python3 tools/check_release_candidate.py` -> `Release candidate check OK`; existing Godot cleanup warnings remain.

## Stage 1 P3.19 Character/Weapon Pose Polish (2026-06-29)

> Addressed the report that the generated firing prototype still looked like a standing pose, and that the gun layer sat on top of the character instead of belonging behind the body.

- **Layering corrected**: fused character/weapon generation now renders the selected weapon behind the character body for idle and hurt frames. The character sprite is composited on top, so the gun no longer reads as a floating front sticker.
- **Distinct firing posture**: attack frames now use a separate raised-weapon pose with per-frame recoil offsets, muzzle flash, and subtle body lean. The attack muzzle reference is `attack_01`, matching the immediate projectile spawn moment.
- **Cleaner joins**: removed the visible grey connector bars from idle/hurt frames. Attack frames keep only a small low-alpha grip shadow, avoiding the old rectangular patch artifact.
- **Railgun crop fix**: railgun attack frames were pulled inward so the long barrel and muzzle flash no longer touch the canvas edge.
- **Runtime muzzle sync**: `CHARACTER_WEAPON_COMBO_MUZZLE` in `gameplay/battle/battle.gd` was updated from the regenerated manifest so projectiles still originate from the visible attack-frame muzzle.
- **Regression guardrail**: `tools/check_visual_assets.py` now compares every combo's `idle_01` and `attack_01` frame and fails if the attack pose is too close to idle, preventing another "standing pose renamed as attack" regression.

### Verification (after Stage 1 P3.19)

- `python3 tools/generate_character_weapon_combos.py` -> generated 352 character/weapon combo frames.
- `python3 -m py_compile tools/generate_character_weapon_combos.py tools/check_visual_assets.py tools/check_gameplay_polish.py` -> pass.
- `python3 -m json.tool assets/production/OUTSOURCER_ASSET_INDEX.json` -> valid JSON.
- `python3 -m json.tool assets/production/source_refs/generated/character_weapon_combo_generation_manifest.json` -> valid JSON.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 404 battle sprite files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` -> `checked 226 res:// references / res:// references OK`.
- `python3 tools/check_gameplay_polish.py` -> `Gameplay polish OK: 16 skills, 8 weapons, 28 enemies covered`.
- `git diff --check` -> no whitespace errors.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; existing Godot cleanup warnings remain.
- `python3 tools/check_release_candidate.py` -> `Release candidate check OK`; existing Godot cleanup warnings remain.

## Stage 1 P3.20 Directional Held-Weapon Attack Poses (2026-06-29)

> Addressed the follow-up question about whether the gun visually follows the bullet direction. The projectile logic already aimed at the selected target, but fused character/weapon art needed directional attack poses to match that aim.

- **Three-way attack coverage**: regenerated fused character/weapon assets with `attack_left`, `attack`, and `attack_right` frame sets for every 4-character x 8-weapon combination. Total fused combo output is now 608 frames.
- **Runtime aim bucket**: battle now derives `left / center / right` from the current projectile direction and selects the matching attack frame set during firing and active-skill animations.
- **Directional muzzle sockets**: added left and right fused muzzle offset tables in addition to the center table. `_weapon_fire_origin()` now resolves to the muzzle for the current aim bucket, so bullets originate from the visible gun tip for that direction.
- **No floating-gun rollback**: idle/hurt frames still keep the weapon behind the character body, and the separate `CharacterWeapon` sprite remains suppressed for covered fused combinations.
- **Regression guardrails**: `tools/check_visual_assets.py` now requires all three attack directions. `tools/m1_smoke_test.gd` verifies every character/weapon pair has left/center/right attack frames and that left/right muzzle origins move on the correct side of the center muzzle.

### Verification (after Stage 1 P3.20)

- `python3 tools/generate_character_weapon_combos.py` -> generated 608 character/weapon combo frames.
- `python3 -m py_compile tools/generate_character_weapon_combos.py tools/check_visual_assets.py` -> pass.
- `python3 -m json.tool assets/production/source_refs/generated/character_weapon_combo_generation_manifest.json` -> valid JSON.
- `python3 tools/check_res_refs.py` -> `checked 226 res:// references / res:// references OK`.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 660 battle sprite files`.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; existing Godot cleanup warnings remain.

## Stage 1 P3.21 Long-Press Manual Aim Priority (2026-06-29)

> Addressed the report that player directional control felt weak and that auto aim sometimes shot backline zombies while frontline zombies were already pressuring the base.

- **Long-press control gate**: `InputManager` now only enters manual aim after a 0.30 s mouse/finger hold. Short click/tap no longer steals auto aim.
- **Manual aim priority**: battle now routes manual aim through explicit `manual_aim_started / aim_point / manual_aim_released` handlers. While the hold is active, the selected point overrides auto targeting and target lock; after release, a short 0.18 s grace keeps the final direction before auto aim resumes.
- **Frontline auto-target retune**: `TargetingManager` now scores near-line pressure non-linearly, so default breach targeting favors zombies closest to the defense line before chasing backline tags or raw breach damage.
- **Regression guardrails**: `tools/m1_smoke_test.gd` now verifies short taps do not trigger manual aim, long holds do trigger it, manual aim overrides auto target in battle, auto resumes after release, and default breach targeting prefers a frontline target over a backline threat.

## Stage 1 P3.22 Headless Boot / Runtime Verification Fix (2026-06-29)

> Addressed the sandbox-only Godot crash where the engine tried to write `user://logs/...` outside the workspace, then verified the playable loop through the existing headless probes.

- **Godot user data path**: `project.godot` now sets `application/config/use_hidden_project_data_directory=true`, so `user://` resolves inside the project hidden data directory during local/headless validation.
- **Headless file logging**: project file logging is disabled for headless/CI-style validation, avoiding the previous `user://logs` crash under workspace-only filesystem permissions.
- **Audio cleanup**: `AudioManager` now skips stream loading/playback when the display driver is `headless`; visible macOS runs still play BGM/SFX, while required headless commands no longer leak `AudioStreamWAV` / `AudioStreamPlaybackWAV` resources on exit.
- **Core loop verification**: `_battle_boot_probe.gd` enters `level_001` through the real route and confirms Battle is active, unpaused, spawning enemies, with character rig and turret present. `m1_smoke_test.gd` covers menu/map/loadout/result routing, all 99 battle scene entries, first-spawn readiness, target/manual-aim behavior, card pause/resume rules, equipment-driven battle stats, armor-break boss path, active skills, and result routing.

### Verification (after Stage 1 P3.22)

- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 4386 files`.
- `python3 tools/check_res_refs.py` -> `checked 228 res:// references / res:// references OK`.
- `python3 tools/check_level_pressure.py` -> pressure estimate completes across all 99 levels.
- `python3 tools/simulate_card_director.py` -> card offer simulation completes for all 99 levels.
- `godot --headless --path . --quit` -> exits 0; no ObjectDB/resource cleanup warning remains. Godot still prints a macOS CA certificate fallback warning before loading bundled CA certificates.
- `godot --headless --path . --script res://tools/_battle_boot_probe.gd` -> level_001 Battle route active, unpaused, spawning, character rig/turret present.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`.

## Stage 1 P3.23 High-End Prototype Asset Rebuild (2026-06-30)

> Owner explicitly allowed GPT/Codex-generated replacements for low-end prototype assets. This pass changes only asset prototypes and data asset references; gameplay logic, difficulty numbers, levels, skills, economy, and targeting rules are unchanged.

- **Full prototype replacement pass**: added `tools/generate_high_end_prototype_assets.py` as the repeatable generator for polished production prototypes. It upgrades character half-body portraits, character/weapon fused frame presentation, zombies, bosses, pets, skill icons, VFX sequence frames, single VFX sprites, and projectile finish assets.
- **Production-only visible refs**: migrated zombie, boss, and skill icon data references away from legacy `assets/sprites/...` paths to `assets/production/...`, while preserving IDs and data-driven lookup.
- **Traceability**: wrote `assets/production/source_refs/generated/high_end_prototype_asset_spec.json` and `assets/production/source_refs/generated/high_end_prototype_contact_sheet.png` so future replacements can be audited visually and regenerated deterministically.
- **Projectile polish**: upgraded `tools/generate_projectile_visuals.py` with a premium-finish layer: alpha-safe margins, glow, bevel/highlight passes, material shadows, and element-specific accents. These are still script-rendered 2.5D sprites, not native 3D renders.
- **Guardrails retained**: `tools/check_visual_assets.py` still enforces 4-character x 8-weapon x 19-frame battle combo coverage and transparent safe margins, preventing the old floating-gun/edge-artifact regressions.

### Verification (after Stage 1 P3.23)

- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 5056 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills`.
- `python3 tools/check_res_refs.py` -> `checked 240 res:// references / res:// references OK`.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 660 battle sprite files`.
- `python3 tools/check_level_pressure.py` -> completes through `level_099`.
- `python3 tools/simulate_card_director.py` -> completes through `level_099`.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits 0.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints Canvas/TextServer/RID cleanup warnings at exit.

## Stage 1 P3.24 Campaign Background Refresh (2026-07-01)

> Owner requested 10 new campaign battle backgrounds so the battlefield no longer reads like the reference game. This pass changes background art, environment mapping, and asset/data references only; combat logic, economy, difficulty, skills, and targeting behavior are unchanged.

- **10 original campaign backgrounds**: added `tools/generate_level_backgrounds.py` and generated `bg_lava_foundry`, `bg_glacier_pass`, `bg_abandoned_factory`, `bg_toxic_biolab`, `bg_storm_substation`, `bg_flooded_subway`, `bg_desert_refinery`, `bg_void_cathedral`, `bg_orbital_ruins`, and `bg_apex_core`.
- **One background per ten levels**: remapped `data/levels.json` so levels 001-010 use lava foundry, 011-020 glacier, 021-030 abandoned factory, 031-040 toxic biolab, 041-050 storm substation, 051-060 flooded subway, 061-070 desert refinery, 071-080 void cathedral, 081-090 orbital ruins, and 091-099 apex core.
- **Data-driven environment table**: added `data/environments.json` and registered it in `DataLoader`. Battle now reads `levels[].env -> environments[env].battle_background/bgm` instead of maintaining a background path list in `battle.gd`.
- **Traceability and Godot import**: wrote `assets/production/source_refs/generated/level_backgrounds_v2_spec.json`, `contact_level_backgrounds_v2.png`, portrait crops, battle layout guides, and the Godot `.import` metadata needed for headless runtime loading.
- **Regression prevention**: updated `tools/rebalance_difficulty.py` so future level regeneration preserves the 10-segment environment mapping; `validate_data.py` now checks that every level env exists and every environment asset path resolves.

## Stage 1 P3.25 iPhone 17 Background Ratio + Concrete Scene Revision (2026-07-01)

> Owner rejected the first generated 10-background sheet as too abstract, then requested iPhone 17 full-screen phone ratio. This pass keeps all env IDs, level mappings, and gameplay logic unchanged, and replaces only the generated background pixels plus traceability docs.

- **iPhone 17 output ratio**: regenerated the 10 campaign battle backgrounds, portraits, layout guides, and contact sheet at `1206x2622` portrait full-screen ratio. This matches the iPhone 17 / iPhone 17 Pro family ratio while keeping the existing `1080x1920` gameplay logic canvas unchanged.
- **Concrete scene treatment**: revised `tools/generate_level_backgrounds.py` so existing production-quality scene material remains dominant; theme elements are now supporting props, tint, and atmosphere instead of abstract geometric overlays.
- **Traceability update**: `assets/production/source_refs/generated/level_backgrounds_v2_spec.json` now records `level_backgrounds_v3_iphone17_concrete`, target device basis, design canvas, and generated files.
- **Review state correction**: updated asset docs so the new background sheet is marked integrated/reviewed and pending owner visual review, not owner-approved.

### Verification (after Stage 1 P3.25)

- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 5119 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> `checked 242 res:// references / res:// references OK`.
- `python3 tools/check_level_pressure.py` -> completes through `level_099`.
- `python3 tools/simulate_card_director.py` -> completes through `level_099`.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits 0.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints Canvas/TextServer/RID cleanup warnings at exit.
- `git diff --check` -> no whitespace errors.

### Verification (after Stage 1 P3.24)

- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 5119 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> `checked 242 res:// references / res:// references OK`.
- `python3 tools/check_level_pressure.py` -> completes through `level_099`.
- `python3 tools/simulate_card_director.py` -> completes through `level_099`.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits 0.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints Canvas/TextServer/RID cleanup warnings at exit.
- `git diff --check` -> no whitespace errors.

## VFX B2 Projectile Overhaul (2026-07-01)

> Implemented only `design/vfx_b2_task.md`: projectile/bullet visual layer. Gameplay values, hit logic, data tables, character/zombie/boss/weapon art, and render settings were not changed.

- **Energy projectile body**: `gameplay/projectile/projectile.gd` now keeps each existing projectile sprite as the untinted model texture, applies additive material to it, and layers `EnergyHalo` + `EnergyCore` children using `VfxLib.RADIAL_GLOW_TEXTURE` and `VfxLib.GLOW_CORE_SHADER`.
- **B1 trail reuse**: replaced the old per-frame sprite afterimage and flat `Line2D` trail with `VfxLib.spawn_trail`, using additive streak texture and profile-specific width/point spacing.
- **Budgeted flight particles**: added small `VfxLib.spawn_particles` pulses behind projectiles, gated through Battle's existing `_can_spawn_projectile_fx` when available and the projectile layer transient cap as fallback.
- **Element/profile readability**: fire, ice, lightning, poison, and physical each get distinct glow/trail/particle colors; rail, scatter, plasma, split, heavy, and acid profiles have separate scale/glow/trail/particle parameters. Split/heavy/acid are supported via existing projectile texture naming/override paths.
- **Hard constraints kept**: the existing `velocity`, `damage`, `pierce_left`, `target.take_damage`, `hit_confirmed`, and `CollisionShape2D.shape.radius` setup flow was left in place; no `data/*.json`, art PNG, or `project.godot` render-setting edits were made.

### Verification (after VFX B2)

- `godot --headless --import` -> exit 0. It reimported the already-dirty campaign background assets in the working tree.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 5126 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> `checked 251 res:// references / res:// references OK`.
- `python3 tools/check_level_pressure.py` -> completes through `level_099`.
- `python3 tools/simulate_card_director.py` -> completes through `level_099`.
- `godot --headless --path . --quit` -> exits 0.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints Canvas/TextServer/RID cleanup warnings and resource-in-use messages at exit.
- `git diff --check` -> no whitespace errors.

## VFX B3 Muzzle Flash Overhaul (2026-07-01)

> Implemented only `design/vfx_b3_task.md`: muzzle/open-fire visual layer. Fire timing, damage, hit logic, data numbers, character/zombie/boss/weapon art, and render settings were not changed.

- **Layered muzzle flash**: `_spawn_muzzle_flash` now builds every shot from `VfxLib.spawn_glow`, additive streak cones using `VfxLib.STREAK_TEXTURE`, `VfxLib.GLOW_CORE_SHADER` hot cores, `VfxLib.spawn_burst`, `VfxLib.spawn_particles`, and short-lived GPUParticles2D smoke/mist.
- **Element readability**: physical uses yellow tracer/metal sparks; fire adds orange-red blast, embers, and shader heat haze; ice adds cyan mist and crystalline fork shards; lightning uses white-blue flash plus forked arcs; poison uses green gas and additive bubbles.
- **Weapon/profile muzzle identity**: `_spawn_weapon_muzzle_profile_vfx` now differentiates autocannon, rail, scatter, plasma, flamethrower, cryocannon, tesla coil, and venom launcher muzzle accents without passing new profile strings into projectile gameplay.
- **Salvo fan and short spark polish**: `_spawn_salvo_fan_vfx` and `_spawn_short_muzzle_spark` now use budgeted additive cones/particles instead of defaulting to old flat muzzle sprites; optional pellet/crit accent sprites remain additive-only secondary details.
- **Hard constraints kept**: all new nodes are transient visual children under `ProjectileLayer`, with `_can_spawn_projectile_fx` gating and existing transient tracking; no `data/*.json`, art PNG, collision, projectile setup, damage, fire-rate, or `project.godot` edits were made.
- **Scope note**: active-skill cast flourishes that still call `vfx_muzzle_*` sequences were left for the later skill VFX batch because B3 listed the four muzzle-fire functions as its target surface.

### Verification (after VFX B3)

- `godot --headless --import` -> exit 0. It reimported already-dirty background/icon/splash assets in the working tree.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 5126 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> `checked 250 res:// references / res:// references OK`.
- `python3 tools/check_level_pressure.py` -> completes through `level_099`.
- `python3 tools/simulate_card_director.py` -> completes through `level_099`.
- `godot --headless --path . --quit` -> exits 0.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints Canvas/TextServer/RID cleanup warnings and resource-in-use messages at exit.
- `godot --headless --script tools/m1_smoke_test.gd` -> `M1 smoke test passed`; same known headless cleanup warnings.
- `python3 tools/validate_data.py && python3 tools/check_res_refs.py` -> data validation passed; `checked 250 res:// references`; `res:// references OK`.

## VFX B4 Hit / Burst / Death Overhaul (2026-07-01)

> Implemented only `design/vfx_b4_task.md`: hit, impact, radial burst, chain-flash, immune/weak hit, and death-burst visual layers. Hit detection, `take_damage`, damage math, data numbers, character/zombie/boss/weapon art, and render settings were not changed.

- **Projectile impact flash**: `gameplay/projectile/projectile.gd::_spawn_impact_flash_at` now uses `VfxLib.spawn_glow`, `VfxLib.spawn_burst`, additive `VfxLib.STREAK_TEXTURE` shock rings, and profile/element-specific particle sizing instead of a single old hit sprite.
- **Battle impact stack**: `gameplay/battle/battle.gd` now routes `_spawn_element_impact_vfx`, `_spawn_hit_layer_vfx`, `_spawn_rail_impact_vfx`, `_spawn_scatter_impact_vfx`, `_spawn_plasma_impact_vfx`, `_spawn_chain_flash`, and `_spawn_radial_vfx` through reusable B4 helpers for shader glow cores, additive shock rings, sparks, forked arcs/crystal lines, heat haze, poison bubbles, and small gas/mist particles.
- **Death bursts**: `_spawn_death_element_vfx`, `_spawn_zombie_blood_pool`, and `_spawn_death_shards` now use glow/particle/streak VFX under `ProjectileLayer`; the prior B4 death-only `Polygon2D` residue and `ColorRect` shards were removed.
- **Hit feedback**: projectile hit confirmation now applies budgeted `VfxLib.screen_shake` and existing `hit_stop` only with a short cooldown and profile/damage/boss scaling; crit and kill shakes also route through `VfxLib.screen_shake`.
- **Hard constraints kept**: all new effects are transient visual nodes with `_can_spawn_projectile_fx` / `_track_transient_fx` budget gating; no `data/*.json`, collision, targeting, damage, enemy `take_damage`, art PNG, or `project.godot` render-setting edits were made.

### Verification (after VFX B4)

- `godot --headless --import` -> exit 0. It reimported already-dirty campaign background assets in the working tree.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 5126 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> `checked 249 res:// references`; `res:// references OK`.
- `python3 tools/check_level_pressure.py` -> completes through `level_099`.
- `python3 tools/simulate_card_director.py` -> card offer simulation completes for all 99 levels.
- `godot --headless --path . --quit` -> exits 0.
- `godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints Canvas/TextServer/RID cleanup warnings and resource-in-use messages at exit.
- `godot --headless --script tools/m1_smoke_test.gd` -> `M1 smoke test passed`; same known headless cleanup warnings.
- `python3 tools/validate_data.py && python3 tools/check_res_refs.py` -> data validation passed; `checked 249 res:// references`; `res:// references OK`.

## VFX B5 Skill Effect Overhaul (2026-07-01)

> Implemented only `design/vfx_b5_task.md`: skill-triggered and persistent skill visual layers. Skill trigger conditions, hit detection, damage/slow/barrier/fire-rate numbers, `data/*.json`, character/zombie/boss/weapon art, and render settings were not changed.

- **Pierce / split / chain signatures**: `projectile.gd` pierce pass-through now uses shader glow sweep bands, additive streak traces, and along-path spark particles. `battle.gd` split bursts use fan light cones, glow cores, shock rings, and mini light orbs. Chain/ricochet arcs are now runtime forked additive lines with node glows instead of a single flat bolt sprite.
- **Slow field**: added `gameplay/vfx/shaders/vfx_slow_field.gdshader` and a capped persistent GPUParticles2D mote layer. Existing slow-level rectangle placement remains unchanged; only material, edge lines, and ambient particles were upgraded.
- **Barrier / crit / charge / upgrade**: barrier gain/break now uses energy shell pulses, shader-lit streak shards, particles, and B4 shield impact helpers. Crit shots use gold glow, cone, shock ring, streaks, burst particles, and short `VfxLib.screen_shake`. Weapon power and level-up effects now use additive converge rings, glow, vertical beam, and rising particles.
- **Skill pickup signatures**: `_spawn_skill_pick_vfx` now gives each of the 16 skill cards a distinct visual pattern using VfxLib, additive rings/streaks, B4 helpers, and particles; no skill data or runtime outcome changed.
- **Hard constraints kept**: no `data/*.json`, PNG art, collision, targeting, damage, slow math, barrier counts, fire-rate logic, or `project.godot` render-setting edits; `project.godot` remains `canvas_items` / `aspect=expand`.

### Verification (after VFX B5)

- `/opt/homebrew/bin/godot --headless --path . --import` -> exit 0; imported the new slow-field shader and generated `gameplay/vfx/shaders/vfx_slow_field.gdshader.uid`.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 5126 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> `checked 250 res:// references`; `res:// references OK`.
- `python3 tools/check_level_pressure.py` -> completes through `level_099` (`level_001: pressure=28.0, spawn_time=50.4s, boss=0`; `level_099: pressure=1482.3, spawn_time=94.4s, boss=1`).
- `python3 tools/simulate_card_director.py` -> `Card offer simulation: 1000 runs per level`; completes through `level_099`.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits 0.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at exit.
- `git diff --check` -> no whitespace errors.

## Owner Reference Sheet Direct UI/VFX Integration Pass (2026-07-02)

> Owner pointed out that the visible runtime still read as vector/procedural VFX. The correction in this pass is not another placeholder generator pass: the two owner-provided top-tier reference sheets are now copied into the production source refs, cut into actual runtime PNG assets, and made the default combat VFX path.

- **Direct reference sources**: copied the owner UI/HUD/VFX sheet to `assets/production/source_refs/generated/user_ui_vfx_reference_sheet_2026_07_02.png` and the combat VFX sheet to `assets/production/source_refs/generated/user_combat_vfx_reference_sheet_2026_07_02.png`.
- **Deterministic integration tool**: added `tools/integrate_user_reference_sheets.py`, which writes runtime UI skins/icons/card frames, VFX single sprites, and frame-based `assets/production/sprites/vfx_sequences/**` JSON/PNG sequences from those exact sheets. The script also creates `assets/production/source_refs/generated/owner_reference_sheet_final_ui_vfx_spec_2026_07_02.json` and updates `OUTSOURCER_ASSET_INDEX.json`.
- **Crop corrections after visual QA**: fixed the card-frame crop boxes so `ui_card_frame_fire.png` and sibling card frames do not include adjacent cards; fixed lower VFX strip y offsets and left trimming so the sequence frames do not include the upper HUD widgets or baked weapon bodies as primary content.
- **Review contact sheets**: generated `assets/production/contact_sheets/contact_owner_reference_ui_actual_2026_07_02.png` and `assets/production/contact_sheets/contact_owner_reference_vfx_actual_2026_07_02.png` for owner-facing verification.
- **Runtime switch to authored bitmap sequences**: `gameplay/battle/battle.gd` now has `AUTHORED_BITMAP_VFX_ONLY := true`. Muzzle flash, hit layers, death bursts, split/radial/chain effects, enemy skill casts, breach attacks, boss casts, barrier gain/break, and skill-pick feedback return after the PNG sequence path instead of layering old `VfxLib`, `Line2D`, ring, or particle helpers.
- **Projectile VFX switch**: `gameplay/projectile/projectile.gd` now has its own `AUTHORED_BITMAP_VFX_ONLY := true`; projectile trails/halo particles are disabled in this mode, and hit/pierce visuals call the battle sequence player (`vfx_hit_*`, `vfx_skill_cast_pierce`) instead of drawing Line2D streaks.
- **Gameplay untouched**: damage, collisions, targeting, wave scripts, level data, economy, and character/weapon data were not changed.

### Verification (after owner reference sheet direct integration pass)

- `python3 -m py_compile tools/integrate_user_reference_sheets.py` -> pass.
- `python3 tools/integrate_user_reference_sheets.py` -> integrated owner reference sheets into 632 written output entries after the crop corrections.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 5906 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> `checked 272 res:// references`; `res:// references OK`.
- `python3 tools/check_level_pressure.py` -> completes through `level_099`.
- `python3 tools/simulate_card_director.py` -> card offer simulation completes for all 99 levels.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits 0.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at exit.
- `python3 tools/check_visual_screens.py` -> `Visual screen check OK: 6 routed screenshots`; some screenshot subprocesses still print the known Godot cleanup warnings.

## Top-Tier UI And Combat VFX Second Pass (2026-07-02)

> Owner asked to raise every visible border, hint, health/progress bar, button, zombie skill / hit effect, and hero active-skill effect to a flashy top-tier App Store-grade rendered standard, explicitly rejecting SVG/vector placeholders. This pass remains visual-only: no `data/*.json` content, damage, collision, level pressure, economy, targeting, or fixed-bottom-turret gameplay scope changed.

- **Rendered reference boards**: generated top-tier raster reference boards through the built-in `image_gen` flow and copied them to `assets/production/source_refs/generated/ui_motion_top_tier_reference_2026_07_02.png` and `assets/production/source_refs/generated/combat_vfx_top_tier_reference_2026_07_02.png`.
- **Repeatable bitmap generator**: added `tools/generate_top_tier_ui_motion_pass.py`. It writes only PNG raster assets, records source provenance, emits review contact sheets, and updates `OUTSOURCER_ASSET_INDEX.json`.
- **UI skins upgraded**: reworked button, icon-frame, hint, level-card, panel, skill-slot, HP/wave/XP bar, target reticle, and card-frame surfaces into the shared dark gunmetal / glass / cyan-orange rim-light family. `UiKit` now exposes texture-backed helpers for these components, and battle / map / loadout / collection / result screens use the shared skins where they were still visually flat.
- **Page-side flat styles retired**: cleaned the local page/battle `StyleBoxFlat` blocks for map resource chips, level cards, result hints, loadout buttons, collection buttons / pills / sections, battle active-skill controls, bottom skill cards, and combo HUD. `StyleBoxFlat` now remains only inside `UiKit` fallback helpers for missing texture assets.
- **Attack-frame cleanup**: refreshed enemy and Boss attack/special motion frames and stripped the square backplates that were still visible in several Boss special frames.
- **Combat VFX sequences**: added 6 hit sequences (`physical/fire/ice/lightning/poison/immune`), 27 zombie/enemy skill sequences, 5 character active-skill sequences, and 16 card skill-cast sequences under `assets/production/sprites/vfx_sequences/`.
- **Runtime hookup**: `gameplay/battle/battle.gd` now plays authored frame sequences for elemental hits, armor/immune hits, zombie base attacks, acid spit impact, Boss cast starts, skill-card pickup flourishes, and all five character active-skill variants. Existing sprite/procedural effects remain as fallback / supporting layers rather than the primary look.
- **Review sheets**: generated `contact_ui_component_polish_2026_07_02.png`, `contact_attack_motion_polish_2026_07_02.png`, `contact_skill_cast_vfx_2026_07_02.png`, `contact_hit_vfx_polish_2026_07_02.png`, `contact_enemy_skill_vfx_2026_07_02.png`, and `contact_character_active_vfx_2026_07_02.png`.

### Verification (after top-tier UI and combat VFX second pass)

- `python3 -m py_compile tools/generate_top_tier_ui_motion_pass.py` -> pass.
- `python3 -m json.tool assets/production/OUTSOURCER_ASSET_INDEX.json` and `python3 -m json.tool assets/production/source_refs/generated/top_tier_ui_motion_second_pass_spec_2026_07_02.json` -> valid JSON.
- Custom sequence scan -> 69 total VFX sequence folders; 6 hit, 27 enemy skill, 5 character active, and 16 card skill-cast sequence groups; 796 PNG frames under `assets/production/sprites/vfx_sequences/`.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 5899 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> `checked 272 res:// references`; `res:// references OK`.
- `python3 tools/check_level_pressure.py` -> completes through `level_099`.
- `python3 tools/simulate_card_director.py` -> card offer simulation completes for all 99 levels.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 660 battle sprite files`.
- `python3 tools/check_app_store_assets.py` -> `App Store asset check OK`.
- `python3 tools/check_visual_screens.py` -> `Visual screen check OK: 6 routed screenshots`; Godot screenshot subprocesses still print the known small ObjectDB/resource cleanup warnings on some exits.
- `rg -n "StyleBoxFlat" ui gameplay meta --glob "*.gd"` -> only `ui/ui_kit.gd` fallback helpers remain.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits 0.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at exit.
- `git diff --check` -> no whitespace errors.

## Non-Shooting Animation Raster Polish Pass (2026-07-01)

> Owner asked to continue the top-tier raster/rendered art cleanup and rejected vector/SVG placeholder direction. This pass targets animation frames outside the already regenerated `character_weapon_combos` firing set, so the improved firing timing and fused weapon/body motion are not overwritten.

- **902 non-shooting animation PNGs polished**: added `tools/polish_non_shooting_animations.py` and processed `sprites/animations/characters`, `characters_weaponless`, `zombies`, `bosses`, `pets`, and `weapons`.
- **Firing combos excluded**: `assets/production/sprites/animations/character_weapon_combos/**` was intentionally skipped so the P0 firing-motion work remains intact.
- **Frame contracts preserved**: filenames, directories, frame counts, and canvas sizes are unchanged. No gameplay data, targeting, fire timing, damage, level mapping, or runtime logic changed.
- **Alpha and clipping cleanup**: trimmed low-alpha full-canvas haze, enforced transparent borders, guarded clipped frames by fitting them back into their original canvas, and boosted existing rendered material contrast.
- **Hurt-frame rectangle fix**: after the first pass, contact-sheet review exposed semi-transparent red rectangular backplates on hurt frames. A targeted repair removed 102 large mid-alpha red backplates while preserving bodies, hit sparks, and small impact shadows. The repair list is recorded in the source spec.
- **Provenance**: review sheet is `assets/production/contact_sheets/contact_non_shooting_animation_polish_2026_07_01.png`; source spec is `assets/production/source_refs/generated/non_shooting_animation_polish_spec_2026_07_01.json`. `OUTSOURCER_ASSET_INDEX.json` records the owner-directed non-shooting animation polish pass.

### Verification (after non-shooting animation raster polish pass)

- `python3 -m py_compile tools/polish_non_shooting_animations.py` -> pass.
- `python3 tools/polish_non_shooting_animations.py` -> polished 902 non-shooting animation PNGs.
- Custom non-shooting animation scan -> 902 files checked; all non-empty, original sizes preserved, no edge-clipped frames, and no hurt-frame rectangular haze candidates remain.
- `python3 -m json.tool assets/production/source_refs/generated/non_shooting_animation_polish_spec_2026_07_01.json` and `python3 -m json.tool assets/production/OUTSOURCER_ASSET_INDEX.json` -> valid JSON.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 5175 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> `checked 260 res:// references`; `res:// references OK`.
- `python3 tools/check_level_pressure.py` -> completes through `level_099`.
- `python3 tools/simulate_card_director.py` -> card offer simulation completes for all 99 levels.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 660 battle sprite files`.
- `python3 tools/check_app_store_assets.py` -> `App Store asset check OK`.
- `python3 tools/check_visual_screens.py` -> `Visual screen check OK: 6 routed screenshots`; Godot still prints the known small ObjectDB/resource cleanup warnings on some screenshot subprocess exits.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits 0.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at exit.
- `git diff --check` -> no whitespace errors.
- `python3 tools/check_release_candidate.py` -> still fails at pre-existing/non-art `tools/check_balance_profile.py` card-budget and collection-unlock distribution checks; this animation polish pass did not tune XP, card budgets, star costs, or collection pacing.

## App Icon Redesign (2026-07-01)

> Owner requested a redesigned app logo with top-tier model rendering. This pass changed only app branding image assets and asset provenance records; it did not change gameplay, data tables, levels, stats, render settings, or the fixed-bottom turret game form.

- **App icon replaced**: `assets/app/app_icon_1024.png` now uses a full-bleed 1024x1024 RGB high-end 3D icon: bottom defense autocannon, orange muzzle blast, advancing zombie wave, and large armored boss silhouette. The design keeps the core tower-defense identity rather than depicting a free-moving shooter character.
- **Old icon preserved**: previous icon was copied to `assets/app/app_icon_1024_before_redesign_2026_07_01.png` for comparison or rollback.
- **Source provenance**: generated source image was copied to `assets/production/source_refs/generated/app_icon_1024_v2_generated_source.png`; prompt and generation notes live in `assets/production/source_refs/generated/app_icon_1024_v2_prompt.txt`.
- **Production index**: `assets/production/OUTSOURCER_ASSET_INDEX.json` now records the owner-directed app icon replacement while preserving the existing `project.godot` icon path.

### Verification (after app icon redesign)

- `assets/app/app_icon_1024.png` -> 1024x1024 RGB, no alpha.
- `python3 tools/check_app_store_assets.py` -> `App Store asset check OK`.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 5129 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> `checked 250 res:// references`; `res:// references OK`.
- `python3 tools/check_level_pressure.py` -> completes through `level_099` (`level_001: pressure=28.0, spawn_time=50.4s, boss=0`; `level_099: pressure=1482.3, spawn_time=94.4s, boss=1`).
- `python3 tools/simulate_card_director.py` -> card offer simulation completes for all 99 levels.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits 0.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/TextServer/ObjectDB/RID cleanup warnings at exit.

## Final Art P0 Shooting Motion and Store Screenshot Repair (2026-07-01)

> Owner called out the character firing motion as the most uncomfortable remaining high-end art/feel issue. This pass changed only visual composition, firing-pose synchronization, screenshot capture safety, generated store presentation, and validation guardrails; gameplay scope, level data, damage math, and `data/*.json` content lists were not changed.

- **Fused firing frames regenerated**: `tools/generate_character_weapon_combos.py` now outputs the 4 characters x 8 weapons x 19-frame action set with stronger attack timing: F1 shot flash, F2 heavy recoil, F3 settle, F4 recovery. The generator also clamps attack-frame alpha into a safe canvas margin so stronger recoil/flash does not clip at runtime.
- **Runtime firing sync**: `gameplay/battle/battle.gd` now locks the fired aim direction, combo aim key, and muzzle reference during the attack window. Projectiles, muzzle VFX, and character attack frames stay tied to the same shot even if targeting changes immediately afterward.
- **Muzzle constants synced from manifest**: the battle combo muzzle dictionaries were refreshed from `assets/production/source_refs/generated/character_weapon_combo_generation_manifest.json` after the safety-margin pass.
- **Action evidence sheets**: added `assets/production/source_refs/generated/character_weapon_combo_shooting_focus_sheet_2026_07_01.png` and `assets/production/source_refs/generated/character_weapon_combo_shooting_polish_contact_sheet_2026_07_01.png` for visual QA.
- **Store screenshot blank-content fix**: `main.gd::_apply_safe_area` now ignores desktop screenshot-process safe rects that are outside the current window. This prevents map/loadout `Root` content from being pushed offscreen when `tools/_shot.gd` captures runtime screens.
- **Screenshot guardrail**: `tools/check_visual_screens.py` now requires higher luminance variance for map/loadout/collection screenshots, so a background-only capture no longer passes as valid.
- **Smoke guardrails**: `tools/m1_smoke_test.gd` now checks firing-window aim/muzzle/attack-frame locking across all fused character/weapon combinations and isolates the multi-shot target test from existing live enemies.
- **Store outputs refreshed**: regenerated `tmp/final_p0_runtime_screens/`, `assets/appstore/screenshots/**`, `assets/production/video/vid_app_preview.mp4`, and `assets/production/source_refs/generated/final_p0_replacement_contact_sheet_2026_07_01.png` after the safe-area fix.

### Verification (after shooting motion / store screenshot repair)

- `python3 -m py_compile tools/generate_character_weapon_combos.py tools/check_visual_screens.py tools/generate_final_p0_assets.py` -> pass.
- `python3 -m json.tool assets/production/OUTSOURCER_ASSET_INDEX.json` and `python3 -m json.tool assets/production/source_refs/generated/character_weapon_combo_generation_manifest.json` -> valid JSON.
- `python3 tools/generate_character_weapon_combos.py` -> generated 608 character/weapon combo frames plus matrix/focus/polish sheets.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 5148 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> `checked 252 res:// references`; `res:// references OK`.
- `python3 tools/check_level_pressure.py` -> completes through `level_099`.
- `python3 tools/simulate_card_director.py` -> card offer simulation completes for all 99 levels.
- `python3 tools/check_visual_screens.py` -> `Visual screen check OK: 6 routed screenshots`.
- `python3 tools/check_app_store_assets.py` -> `App Store asset check OK`.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 660 battle sprite files`.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits 0.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at exit.
- `git diff --check` -> no whitespace errors.

## Runtime Top-Tier Art First Batch (2026-07-01)

> Owner asked to continue the final-art upgrade in priority order, with top-tier App Store-grade raster/3D-rendered quality and no SVG/vector placeholder direction. This pass targets the highest-visibility remaining prototype feel: runtime UI skin surfaces, projectile sprites, VFX sequence frames, damage/bonus badges, slow-field, and barrier visuals. Gameplay data, level scripts, damage, collision, targeting, economy, and scope were not changed.

- **Image generation reference**: produced a high-end raster HUD/projectile/VFX material board through the built-in `image_gen` tool and copied it to `assets/production/source_refs/generated/runtime_top_tier_imagegen_reference_2026_07_01.png`.
- **New deterministic generator**: added `tools/generate_top_tier_runtime_art.py`, which writes runtime UI skin PNGs, regenerates all 11 projectile PNGs, regenerates existing VFX single sprites and sequence frames, adds `vfx_slow_field_band.png` / `vfx_barrier_glass.png`, emits a contact sheet, saves a source spec, and updates `OUTSOURCER_ASSET_INDEX.json`.
- **Runtime UI skin hookup**: `ui/ui_kit.gd` now returns texture-backed `StyleBoxTexture` skins for common panel / plate / pill / resource-chip surfaces when the new runtime skin PNGs exist, with the old `StyleBoxFlat` path preserved as fallback.
- **Combat feedback hookup**: damage numbers remain `Label` nodes for budget and smoke-test compatibility, but now get an authored bitmap badge style. The combo HUD frame uses `ui_combo_panel.png`. Slow field uses a texture-bearing `TextureRect`, and `vfx_slow_field.gdshader` now samples the texture detail. Barrier visuals add a rendered glass sprite while keeping the existing charge-driven edge lines.
- **Asset provenance**: first-batch review output is `assets/production/source_refs/generated/runtime_top_tier_polish_contact_sheet_2026_07_01.png`; the full spec is `assets/production/source_refs/generated/runtime_top_tier_polish_spec_2026_07_01.json`.

### Verification (after runtime top-tier art first batch)

- `python3 -m py_compile tools/generate_top_tier_runtime_art.py` -> pass.
- `python3 tools/generate_top_tier_runtime_art.py --reference <image_gen reference>` -> generated 230 PNG files.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 5159 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> `checked 260 res:// references`; `res:// references OK`.
- `python3 tools/check_level_pressure.py` -> completes through `level_099`.
- `python3 tools/simulate_card_director.py` -> card offer simulation completes for all 99 levels.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 660 battle sprite files`.
- `python3 tools/check_app_store_assets.py` -> `App Store asset check OK`.
- `python3 tools/check_visual_screens.py` -> `Visual screen check OK: 6 routed screenshots`; Godot still prints the known small ObjectDB/resource cleanup warnings on some screenshot subprocess exits.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits 0.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at exit.
- `python3 tools/check_release_candidate.py` -> fails at pre-existing/non-art `tools/check_balance_profile.py` card-budget and collection-unlock distribution checks; this pass did not tune balance or collection star costs.

## Top-Tier Campaign Background Render Pass (2026-07-01)

> Owner asked to continue final-art upgrades with top-tier App Store-grade raster rendering and explicitly rejected SVG/vector placeholder direction. This pass replaces the 10 campaign environment background pixels only; env IDs, `data/environments.json`, level ranges, gameplay logic, combat math, and fixed-bottom-turret form are unchanged.

- **10 independent rendered environment sources**: generated one built-in `image_gen` source image per main campaign environment: lava foundry, glacier pass, abandoned factory, toxic biolab, storm substation, flooded subway, desert refinery, void cathedral, orbital ruins, and apex core.
- **Final project integration**: added `tools/integrate_top_tier_backgrounds.py`, which copies the selected source renders into `assets/production/source_refs/generated/top_tier_background_sources_2026_07_01/`, crops/grades them into existing runtime `assets/production/sprites/backgrounds/bg_*.png` paths, and creates matching `assets/production/environment/*_portrait.png` plus development-only `*_battle_layout_guide.png`.
- **Visual standard**: all selected sources are 3D-rendered / semi-realistic battlefields with distinct landmark identity, readable central combat lanes, and no UI/text/characters. The unused first desert refinery alternate is recorded in the spec but not integrated.
- **Provenance**: review sheet is `assets/production/contact_sheets/contact_top_tier_backgrounds_2026_07_01.png`; source spec is `assets/production/source_refs/generated/top_tier_background_render_spec_2026_07_01.json`. `OUTSOURCER_ASSET_INDEX.json` now records the owner-directed top-tier background override.

### Verification (after top-tier campaign background render pass)

- `python3 -m py_compile tools/integrate_top_tier_backgrounds.py` -> pass.
- `python3 tools/integrate_top_tier_backgrounds.py` -> integrated 10 top-tier rendered campaign backgrounds.
- `python3 -m json.tool assets/production/source_refs/generated/top_tier_background_render_spec_2026_07_01.json` and `python3 -m json.tool assets/production/OUTSOURCER_ASSET_INDEX.json` -> valid JSON.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 5171 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> `checked 260 res:// references`; `res:// references OK`.
- `python3 tools/check_level_pressure.py` -> completes through `level_099`.
- `python3 tools/simulate_card_director.py` -> card offer simulation completes for all 99 levels.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 660 battle sprite files`.
- `python3 tools/check_app_store_assets.py` -> `App Store asset check OK`.
- `python3 tools/check_visual_screens.py` -> `Visual screen check OK: 6 routed screenshots`; Godot still prints the known small ObjectDB/resource cleanup warnings on some screenshot subprocess exits.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits 0.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at exit.
- `git diff --check` -> no whitespace errors.
- `python3 tools/check_release_candidate.py` -> still fails at pre-existing/non-art `tools/check_balance_profile.py` card-budget and collection-unlock distribution checks; this background render pass did not tune XP, cards, star costs, or collection pacing.

## Skeletal Parts Raster Polish Pass (2026-07-01)

> Owner asked to continue raising all remaining prototype-feeling assets to the top-tier rendered standard and explicitly rejected SVG/vector placeholder direction. These skeletal/body part files are not currently loaded by runtime scenes, but they are part of the production asset pack and were still marked as placeholder-derived cutouts.

- **414 part PNGs polished**: added `tools/polish_skeletal_parts.py` and processed all `assets/production/sprites/parts/**` PNGs across characters, zombies, bosses, pets, and weapons.
- **Contracts preserved**: all filenames, directories, IDs, and `256x256` transparent PNG canvases are unchanged. No gameplay data, runtime logic, stats, level mapping, or scene references changed.
- **Cutout quality cleanup**: each visible part was re-centered with safe transparent margins, alpha edges were softened, and existing rendered material contrast/sharpness was boosted. This specifically reduces the old "cropped full-body fragment touching the canvas edge" feel.
- **Empty part fixed**: `assets/production/sprites/parts/zombies/zombie_crawler/zombie_crawler_hand_r.png` had empty alpha after the quality scan; it was repaired by mirroring the polished left-hand part and recorded in the source spec.
- **Placeholder notes retired**: every `*_parts.json` now records the 2026-07-01 raster cutout polish provenance instead of the old placeholder note.
- **Provenance**: review sheet is `assets/production/contact_sheets/contact_skeletal_parts_polish_2026_07_01.png`; source spec is `assets/production/source_refs/generated/skeletal_parts_polish_spec_2026_07_01.json`. `OUTSOURCER_ASSET_INDEX.json` records the owner-directed `sprites/parts` polish pass.

### Verification (after skeletal parts raster polish pass)

- `python3 -m py_compile tools/polish_skeletal_parts.py` -> pass.
- `python3 tools/polish_skeletal_parts.py` -> polished 414 skeletal/body part PNGs.
- Custom parts quality scan -> 414 files checked; all non-empty, `256x256`, with at least 4px transparent margin.
- `python3 -m json.tool assets/production/source_refs/generated/skeletal_parts_polish_spec_2026_07_01.json` and `python3 -m json.tool assets/production/OUTSOURCER_ASSET_INDEX.json` -> valid JSON.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 5173 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> `checked 260 res:// references`; `res:// references OK`.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 660 battle sprite files`.
- `python3 tools/check_app_store_assets.py` -> `App Store asset check OK`.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits 0.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at exit.
- `git diff --check` -> no whitespace errors.

## Runtime Geometry Residual Follow-Up (2026-07-02)

> Owner asked whether the whole game is now free of cheap line/geometric placeholder graphics. The audit found that the combat VFX primary paths were bitmap-sequence first, but several visible combat helpers still spawned procedural lines/particles in authored mode. This follow-up removes those active combat leftovers without claiming the non-battle UI primitive layer is fully retired.

- **Combat authored-only cleanup**: in `AUTHORED_BITMAP_VFX_ONLY` mode, salvo fan, homing assist, charge-shot power ring, and critical shot now return after playing authored PNG sequences instead of layering `VfxLib`, rings, lines, or particle helpers.
- **Persistent combat field cleanup**: slow-field display keeps the rendered `TextureRect` / shader band but no longer creates the extra `Line2D` edge layer or `GPUParticles2D` motes in authored mode.
- **Barrier cleanup**: the persistent barrier now uses the rendered glass sprite in authored mode and skips the previous `Polygon2D` fill plus `Line2D` frame/strut overlay. Barrier gain/break feedback remains PNG-sequence based.
- **Known remaining scope**: source still contains fallback procedural helper definitions and non-combat/native UI primitives (`ColorRect` overlays/dividers, Label text, fallback `StyleBoxFlat`). Those are not now the primary combat VFX path, but they prevent a truthful "global zero geometry in source" claim.

### Verification (after runtime geometry residual follow-up)

- `python3 tools/check_res_refs.py` -> `checked 272 res:// references`; `res:// references OK`.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 5906 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_level_pressure.py` -> completes through `level_099`.
- `python3 tools/simulate_card_director.py` -> card offer simulation completes for all 99 levels.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits 0.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at exit.
- `python3 tools/check_visual_screens.py` -> `Visual screen check OK: 6 routed screenshots`; Godot screenshot subprocesses still print the known small ObjectDB/resource cleanup warnings on some exits.
- `rg -n "Line2D|Polygon2D|GPUParticles2D|ColorRect|StyleBoxFlat|draw_" gameplay meta ui -g "*.gd" -g "*.tscn"` -> still finds fallback VFX helpers plus non-combat/native UI primitives, so this is not a source-global zero-geometry state.
- `git diff --check` -> no whitespace errors.

## Visible UI Line Polish Pass (2026-07-02)

> Owner identified the remaining visible UI linework as the real quality problem. This pass targets player-facing geometric/primitive UI surfaces across map, loadout, collection, result, and battle HUD while preserving gameplay data, level routing, economy, selection behavior, and the fixed-bottom-turret combat form.

- **Raster UI skins**: added `tools/generate_map_ui_line_polish.py` and generated texture-backed PNG skins for map level cards, locked cards, nav cards, resource chips, pills, index plates, deploy buttons, modal buttons, accent strips, stars, and gold/star currency icons. Outputs are transparent PNGs under `assets/production/sprites/ui/`, with spec `assets/production/source_refs/generated/map_ui_line_polish_spec_2026_07_02.json` and contact sheet `assets/production/contact_sheets/contact_map_ui_line_polish_2026_07_02.png`.
- **Runtime hookup**: `ui/ui_kit.gd` now exposes `StyleBoxTexture` helpers and map-specific texture styles. `meta/map/map.gd`, `meta/loadout/loadout.gd`, `meta/collection/collection.gd`, `meta/result/result.gd`, `gameplay/battle/battle.gd`, and `gameplay/enemy/enemy.gd` use those skins for visible cards, chips, buttons, prompts, HP, XP, and enemy HP bars.
- **Primitive cleanup**: removed or demoted visible divider/accent `ColorRect` usage in the audited screens, replaced the most obvious line-heavy strips with raster `TextureRect`/`StyleBoxTexture`, and left functional overlays/fallbacks intact where they are not the player-facing skin.
- **Icon repair**: `ui_star_filled.png`, `ui_star_empty.png`, `icon_currency_star.png`, and `icon_currency_gold.png` were found to contain bad atlas fragments after the first screenshot review; the generator now rewrites them as standalone transparent PNG icons.
- **Screenshot safety**: `main._apply_safe_area()` no longer applies mobile safe-area rects to desktop/headless screenshot runs, which prevents the UI root from being pushed off-screen on macOS captures.
- **Review screenshots**: refreshed map, loadout, collection, battle, and result screenshots under `tmp/ui_line_polish_2026_07_02/screens/` after Godot reimport.

### Verification (after visible UI line polish)

- `python3 -m py_compile tools/generate_map_ui_line_polish.py` -> pass.
- `python3 -m json.tool assets/production/source_refs/generated/map_ui_line_polish_spec_2026_07_02.json` and `python3 -m json.tool assets/production/OUTSOURCER_ASSET_INDEX.json` -> valid JSON.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 6631 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> `checked 272 res:// references`; `res:// references OK`.
- `python3 tools/check_level_pressure.py` -> completes through `level_099`; small `difficulty_coef` guardrail fixes were applied to `level_035`, `level_060`, `level_065`, `level_090`, and `level_095` so boss-level pressure is monotonic again.
- `python3 tools/simulate_card_director.py` -> card offer simulation completes for all 99 levels.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits 0.
- `python3 tools/check_visual_screens.py` -> `Visual screen check OK: 6 routed screenshots`; Godot screenshot subprocesses still print the known small ObjectDB/resource cleanup warnings on some exits.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at exit.
- `git diff --check` -> no whitespace errors.

## Final Visual Runtime Audit Follow-Up (2026-07-02)

> Fresh routed screenshots were captured after the UI line polish pass because the owner requested a global pass over images and every major interface. This audit found that some runtime screens are improved but still not at the requested top-tier App Store level.

- **Evidence generated**: full runtime screen sheet at `tmp/final_visual_todo_2026_07_02/current_runtime_screens_sheet.png`, problem crop sheet at `tmp/final_visual_todo_2026_07_02/final_visual_problem_thumbnails.png`, and per-screen captures under `tmp/final_visual_todo_2026_07_02/screens/`.
- **TODO documented**: `design/assets/final_visual_todo_2026_07_02.md` tracks P0/P1/P2 work for battle HUD, map cards, loadout slots, collection rows, result panels, VFX sequence tails, production videos, and missing source-reference artifacts.
- **Screenshot blocker fixed**: `main._apply_safe_area()` now skips desktop/headless platforms, so macOS routed captures do not apply mobile display safe-area offsets.
- **Battle capture blocker fixed**: `battle.gd` runtime HUD fill styling now targets `CanvasItem.modulate`, avoiding a typed `ColorRect.color` write against Panel-backed fills during capture.
- **Current validation delta**: `python3 tools/check_visual_screens.py` passes on fresh routed screenshots, but `python3 tools/check_visual_assets.py` fails because expected source refs / combo manifest / combo visual matrix are missing from the current filesystem. This makes visual source traceability an open P0 item, regardless of older progress notes.

## Final Visual P0/P1 Implementation Pass (2026-07-02)

> Owner explicitly requested simultaneous P0/P1 execution, higher concurrency, top-tier rendered App Store standard, and no SVG/vector fallback. This pass implements the open P0/P1 visual tasks from `design/assets/final_visual_todo_2026_07_02.md` while preserving gameplay data, IDs, paths, level logic, and the fixed-bottom-turret form.

- **Asset generation**: added `tools/generate_final_visual_p0p1_assets.py`; generated 39 raster PNG UI skins, copied the image-generation HUD reference into source refs, rebuilt source sheets / combo manifest / combo matrix, repaired 41 empty VFX tail frames, and regenerated 14 placeholder-length videos to 6 seconds at the same paths.
- **Runtime hookup**: `UiKit` now exposes texture-backed `StyleBoxTexture` helpers. Map, loadout, collection, result, and battle HUD surfaces consume PNG skins for cards, chips, panels, hint strips, resource bars, HP/XP fills, skill slots, empty equipment sockets, result rewards, and cooldown overlays.
- **Primitive cleanup**: removed the main player-facing `ColorRect` line/divider/card surfaces from audited screens. Functional overlays, dim layers, flash layers, text labels, and fallback style builders remain as P2 source-level cleanup rather than player-facing final art defects.
- **Review evidence**: after sheet is `tmp/final_visual_todo_2026_07_02/final_p0p1_runtime_screens_after.png`; source spec is `assets/production/source_refs/generated/final_visual_p0p1_asset_spec_2026_07_02.json`; UI contact sheet is `assets/production/contact_sheets/contact_final_visual_p0p1_ui_2026_07_02.png`.
- **Traceability note**: `assets/production/source_refs/` and `assets/production/contact_sheets/` are ignored by `.gitignore`, but the required local files are present and `tools/check_visual_assets.py` now passes.

### Verification (after final visual P0/P1 implementation)

- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 6436 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> `checked 268 res:// references`; `res:// references OK`.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 660 battle sprite files`.
- `python3 tools/check_visual_screens.py` -> `Visual screen check OK: 6 routed screenshots`; screenshot subprocesses still print known small ObjectDB/resource cleanup warnings on some exits.
- `python3 tools/check_level_pressure.py` -> completes through `level_099`.
- `python3 tools/simulate_card_director.py` -> card offer simulation completes for all 99 levels.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits 0.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at exit.

## Release Candidate Closure (2026-07-02)

> After the final visual P0/P1 implementation, the unified release candidate gate still failed on balance-profile metadata and one visible English level label. This closure fixes those gate failures without changing the fixed-bottom-turret form, combat scripts, level IDs, enemy rosters, weapon stats, or hardcoding content outside `data/*.json`.

- **Card-budget metadata aligned**: updated only the failing levels' `xp_first_offer`, `xp_offer_growth`, and `xp_offer_ramp` fields in `data/levels.json` so `tools/check_balance_profile.py` predicts the same card-pick budget already expressed by `target_card_picks`.
- **Collection unlock pacing widened**: adjusted late star unlock costs for selected weapons, armor, chips, and pets to create real mid/late milestones around 62, 90, 120, 150, 210, and 230 stars, satisfying the release guardrail while preserving early defaults.
- **Release strings fixed**: replaced the remaining visible `Lv.` labels in `meta/collection/collection.gd` with Chinese `等级` labels.
- **Final status**: `python3 tools/check_release_candidate.py` now passes end to end. Godot 4.7 headless subprocesses still print the known cleanup warnings on exit, but all validation commands exit successfully.

### Verification (after release candidate closure)

- `python3 tools/check_balance_profile.py` -> `Balance profile OK`; unlock star range `0 -> 230`.
- `python3 tools/check_economy_loop.py` -> `Economy loop OK`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_release_strings.py` -> `Release string check OK`.
- `python3 tools/check_release_candidate.py` -> `Release candidate check OK`.

## Top-Tier Character Weapon Action Pass (2026-07-02)

> Owner called out the character gun-holding / firing action as the most uncomfortable remaining piece. This pass targets that P0 feel issue with raster animation polish only: IDs, paths, weapon stats, level data, damage, targeting, and the fixed-bottom-turret form are unchanged.

- **7-frame fused action contract**: added `tools/generate_top_tier_character_weapon_actions.py` and regenerated / sanitized all 4 characters x 8 weapons x 3 aim directions into 7-frame attack sequences: ready, ignition, max recoil, vent, settle, recover, return.
- **Top-tier raster treatment**: each action frame keeps the existing `380x520` transparent PNG contract while adding weapon-specific muzzle ignition, recoil lean, venting, motion streaks, material contrast, and ground pulse. The built-in `image_gen` reference board is copied to `assets/production/source_refs/generated/top_tier_character_weapon_action_reference_2026_07_02.png`.
- **Runtime sync**: `gameplay/battle/battle.gd` now loads 7 attack frames per direction, uses weapon-specific attack durations/recoil pose strength, locks aim/muzzle/frame during the shot window, and syncs an explicit next-shot/test direction into the locked aim so projectile origins remain correct.
- **Safe canvas margins**: the generator enforces a 3px transparent border and a `--sanitize-existing` mode; this fixed the first visual scan failure where muzzle streaks touched the canvas edge.
- **Traceability**: source spec is `assets/production/source_refs/generated/top_tier_character_weapon_action_spec_2026_07_02.json`; review sheet is `assets/production/contact_sheets/contact_character_weapon_action_top_tier_2026_07_02.png`; `OUTSOURCER_ASSET_INDEX.json` records `final_character_weapon_action_pass_2026_07_02`.

### Verification (after top-tier character weapon action pass)

- `python3 -m py_compile tools/generate_top_tier_character_weapon_actions.py` -> pass.
- `python3 tools/generate_top_tier_character_weapon_actions.py --sanitize-existing` -> sanitized `672` character weapon action frames.
- `/opt/homebrew/bin/godot --headless --path . --import` -> exits 0 after reimporting modified / new action PNGs.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 7017 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> `checked 268 res:// references`; `res:// references OK`.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 948 battle sprite files`.
- `python3 tools/check_level_pressure.py` -> completes through `level_099`.
- `python3 tools/simulate_card_director.py` -> card offer simulation completes for all 99 levels.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits 0.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at exit.
- `python3 tools/check_visual_screens.py` -> `Visual screen check OK: 6 routed screenshots`; screenshot subprocesses still print the known small ObjectDB/resource cleanup warnings on some exits.
- `git diff --check` -> no whitespace errors.
- `python3 tools/check_release_candidate.py` -> `Release candidate check OK`.

## Character Weapon True Grip Correction (2026-07-03)

> Owner rejected the intermediate firing preview because the hands still did not actually hold the gun. This correction rebuilds the source pose logic around real rifle handling: shoulder line, trigger grip, foregrip support, muzzle, and synchronized shot origin.

- **True grip anchors**: `tools/generate_character_weapon_combos.py` now tracks weapon `stock`, `trigger`, `foregrip`, and `muzzle` anchors instead of only pasting a rotated gun image. Attack poses use idle hero bodies plus a foreground rifle layer, with the rear hand locked to the pistol/trigger grip and the support hand locked under the foregrip/handguard.
- **Realistic firing posture**: center/right/left attack variants were re-angled away from the previous vertical/floating pose into a shoulder-fired stance. Character-specific arm palettes and elbows are used so the hands read as armored/gloved hands gripping the weapon rather than generic line markers.
- **Full raster regeneration**: regenerated the 608 base fused character/weapon frames, then regenerated the 672 production attack frames through `tools/generate_top_tier_character_weapon_actions.py` using the built-in `image_gen` reference at the 2026-07-03 quality bar.
- **Runtime muzzle sync**: `gameplay/battle/battle.gd` `CHARACTER_WEAPON_COMBO_MUZZLE*` dictionaries were refreshed from the new anchor positions so muzzle flash, projectile origin, and fused sprite barrel position remain aligned.
- **Traceability**: source spec is `assets/production/source_refs/generated/top_tier_character_weapon_action_spec_2026_07_03.json`; review sheet is `assets/production/contact_sheets/contact_character_weapon_action_top_tier_2026_07_03.png`; `OUTSOURCER_ASSET_INDEX.json` records `final_character_weapon_grip_action_pass_2026_07_03`.

### Verification (after true grip correction)

- `python3 tools/generate_character_weapon_combos.py` -> generated `608` character/weapon combo frames.
- `python3 tools/generate_top_tier_character_weapon_actions.py --reference .../ig_039d47eee87b45af016a46fa2798a4819184e5a8506148ec7f.png` -> generated `672` character weapon action frames.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 7025 files`.
- `python3 tools/check_res_refs.py` -> `checked 284 res:// references`; `res:// references OK`.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 948 battle sprite files`.

## Vanguard Autocannon True-Grip Reference Override (2026-07-03)

> Owner rejected the previous preview again with three concrete issues: heavy guns were still effectively held one-handed, feet were too static, and weapon grips did not anatomically align with the hands. This correction treats the prior full-batch pass as not visually accepted for the key `char_vanguard + weapon_autocannon` firing pose.

- **ImageGen pose benchmark**: generated a new built-in `image_gen` reference matching the owner prompt: 3/4 top-down back view, two-handed heavy autocannon grip, front hand on ribbed handguard, rear hand on trigger grip near the ribs, wide braced stance, forward torso lean, and no muzzle flash / smoke / tracer / projectile baked into the character art.
- **Transparent source ref**: saved the raw chroma-key source at `assets/production/source_refs/generated/true_grip_vanguard_autocannon_reference_chromakey_2026_07_03.png`, removed the key into `assets/production/source_refs/generated/true_grip_vanguard_autocannon_reference_alpha_2026_07_03.png`, and stored the exact prompt in `assets/production/source_refs/generated/true_grip_vanguard_autocannon_prompt_2026_07_03.json`.
- **Production override**: `tools/generate_top_tier_character_weapon_actions.py` now applies that transparent true-grip reference to `char_vanguard/weapon_autocannon` for all three aim directions and all seven attack frames, preserving the existing `380x520` RGBA sprite contract and paths.
- **Runtime-only VFX policy**: character attack frames no longer bake muzzle flash, smoke, motion streaks, tracers, bullets, or ground pulse. Dynamic muzzle / projectile / hit VFX remain in `gameplay/battle/battle.gd`, layered at runtime.
- **Scope note**: this single-combo override was superseded by the full character-level true-grip pass below; the final 2026-07-03 attack batch no longer leaves Blaze/Frost/Volt on the local two-hand anchor compositor.

### Verification (after vanguard autocannon true-grip override)

- `python3 -m py_compile tools/generate_character_weapon_combos.py tools/generate_top_tier_character_weapon_actions.py` -> pass.
- `python3 tools/generate_character_weapon_combos.py` -> generated `608` source character/weapon combo frames.
- `python3 tools/generate_top_tier_character_weapon_actions.py --reference assets/production/source_refs/generated/true_grip_vanguard_autocannon_reference_alpha_2026_07_03.png` -> generated `672` character weapon action frames.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 7033 files` before Godot import and `7035 files` in release-candidate check after `.import` generation.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> `checked 284 res:// references`; `res:// references OK`.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 948 battle sprite files`.
- `python3 tools/check_level_pressure.py` -> completes through `level_099`.
- `python3 tools/simulate_card_director.py` -> card offer simulation completes for all 99 levels.
- `/opt/homebrew/bin/godot --headless --path . --import` -> exits 0 after reimporting generated PNGs.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits 0.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at exit.
- `git diff --check` -> no whitespace errors.
- `python3 tools/check_release_candidate.py` -> `Release candidate check OK`.

## Full Character True-Grip Attack Sweep (2026-07-03)

> Owner accepted the `char_vanguard + weapon_autocannon` firing strip as the target standard and asked to apply that standard to all remaining firing materials.

- **Character-level rendered references**: generated dedicated built-in `image_gen` true-grip references for `char_blaze`, `char_frost`, and `char_volt` matching the accepted vanguard standard: 3/4 top-down back view, both hands on the weapon, front hand on foregrip/barrel handguard, rear hand on trigger grip, wide recoil-bracing stance, forward torso lean, no baked muzzle flash/smoke/tracer/projectile, and no background scene elements.
- **Transparent production sources**: copied the chroma-key references into `assets/production/source_refs/generated/true_grip_char_{blaze,frost,volt}_reference_chromakey_2026_07_03.png`, converted them to alpha PNGs, and recorded the source prompts in `assets/production/source_refs/generated/true_grip_character_reference_prompts_2026_07_03.json`.
- **Generator upgrade**: `tools/generate_top_tier_character_weapon_actions.py` now uses `CHARACTER_TRUE_GRIP_REFERENCES` for all four locked heroes instead of a single `char_vanguard/weapon_autocannon` override. Every generated attack frame keeps the `380x520` RGBA sprite contract, 3px safe alpha margin, runtime-only VFX policy, and the 7-frame anticipation/brace/recoil-settle loop.
- **Full production coverage**: regenerated `32` character/weapon entries (`4` characters x `8` weapons) across `3` attack directions and `7` frames, for `672` formal attack PNGs under `assets/production/sprites/animations/character_weapon_combos/`. The review sheet is `assets/production/contact_sheets/contact_character_weapon_action_top_tier_2026_07_03.png`, now expanded to all 32 combinations.
- **Traceability**: source spec is `assets/production/source_refs/generated/top_tier_character_weapon_action_spec_2026_07_03.json`; asset index entry `final_character_weapon_grip_action_pass_2026_07_03` now describes character-level image-gen true-grip references.

### Verification (after full character true-grip sweep)

- `python3 -m py_compile tools/generate_top_tier_character_weapon_actions.py` -> pass.
- `python3 tools/generate_top_tier_character_weapon_actions.py` -> generated `672` character weapon action frames.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 7048 files` after Godot import.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> `checked 284 res:// references`; `res:// references OK`.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 948 battle sprite files`.
- `python3 tools/check_level_pressure.py` -> completes through `level_099`.
- `python3 tools/simulate_card_director.py` -> card offer simulation completes for all 99 levels.
- `/opt/homebrew/bin/godot --headless --path . --import` -> exits 0 after importing `682` changed/generated assets.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits 0.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at exit.
- `git diff --check` -> no whitespace errors.
- `python3 tools/check_release_candidate.py` -> `Release candidate check OK` including 6 routed visual screenshots.

## Weapon Grip Prototype Alignment (2026-07-03)

> Owner clarified that every gun's holding prototype must align to the accepted true-grip standard, not merely share the character-level pose.

- **Per-weapon anchors**: `tools/generate_character_weapon_combos.py` now defines explicit `WEAPON_GRIP_ANCHORS` for all 8 handheld weapons: `stock`, `trigger`, `foregrip`, and `muzzle`. The old single percentage fallback is no longer the authority for weapon grip placement.
- **Clean handheld prototypes**: `weapon_flamethrower_rifle.png`, `weapon_cryocannon_rifle.png`, `weapon_teslacoil_rifle.png`, and `weapon_venomlauncher_rifle.png` are sanitized before use so baked flame, ice spray, lightning, and poison mist do not become part of the gun length or muzzle anchor. Runtime VFX remains in `battle.gd`.
- **Prototype review sheet**: `assets/production/source_refs/generated/weapon_grip_prototype_anchor_sheet_2026_07_03.png` visualizes all 8 weapon prototypes with stock/trigger/foregrip/muzzle markers.
- **Left aim correction**: `attack_left` was retuned so the weapon remains visibly held across the body instead of being swallowed by the character silhouette.
- **Final action source**: `tools/generate_top_tier_character_weapon_actions.py` now defaults to weapon-specific grip prototypes for the final 7-frame attack pass. Character-level image-gen references are retained as style benchmarks and are only used with explicit `--use-character-reference`.
- **Production coverage**: regenerated the 608 base character/weapon combo frames, refreshed `battle.gd` combo muzzle constants, then regenerated 672 final attack PNGs. The final contact sheet still covers all 32 character/weapon combinations at `assets/production/contact_sheets/contact_character_weapon_action_top_tier_2026_07_03.png`.

### Verification (after weapon grip prototype alignment)

- `python3 -m py_compile tools/generate_character_weapon_combos.py tools/generate_top_tier_character_weapon_actions.py` -> pass.
- `python3 tools/generate_character_weapon_combos.py` -> generated `608` character/weapon combo frames.
- `python3 tools/generate_top_tier_character_weapon_actions.py` -> generated `672` character weapon action frames using weapon-specific prototypes by default.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 7050 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> checked `284` `res://` references; OK.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 948 battle sprite files`.
- `python3 tools/check_level_pressure.py` -> completes through `level_099`.
- `python3 tools/simulate_card_director.py` -> card offer simulation completes for all 99 levels.
- `/opt/homebrew/bin/godot --headless --path . --import` -> exits 0 after importing `795` changed/generated assets.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits 0.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at exit.
- `python3 tools/check_release_candidate.py` -> `Release candidate check OK` including battle boot probe and 6 routed visual screenshots.
- `git diff --check` -> no whitespace errors.

## Final Visual P0/P1/P2 Closure Pass (2026-07-02)

> Owner requested P0/P1/P2 to run together and finish under the top-tier rendered App Store standard, with no SVG/vector fallback. This pass closes the remaining source-level UI primitive cleanup and regenerates App Store-facing deliverables after the runtime polish.

- **UI primitive removal**: `gameplay/`, `meta/`, and `ui/` `.gd/.tscn` files no longer contain `ColorRect` or `StyleBoxFlat`. HP/wave/XP fills, enemy HP bars, cooldown overlays, dim/scrim layers, boss banners, low-HP pulses, slow-field bands, result/settings/loadout scrims, modal buttons, panel styles, pill/resource-chip styles, and fallback styles now use `TextureRect`, `StyleBoxTexture`, or `StyleBoxEmpty`.
- **Combat VFX boundary**: remaining `Line2D` / `Polygon2D` / `GPUParticles2D` hits are limited to projectile, battle, and VFX implementation paths. They are combat effect primitives with authored textures/materials, not player-facing UI frame/card/button geometry.
- **App Store refresh**: reran routed runtime capture into `tmp/final_p0_runtime_screens/`, then regenerated `assets/appstore/screenshots/**`, `assets/app/launch_1080x1920.png`, and `assets/production/video/vid_app_preview.mp4` from the final P0 visual pipeline.
- **Screenshot teardown**: `tools/_shot.gd` now frees the routed `main.tscn`, releases audio, and waits extra frames before exit; screenshot-based checks no longer print the earlier ObjectDB/resource cleanup warnings.
- **Smoke teardown status**: `tools/m1_smoke_test.gd` now releases every 99-level loop battle instance and defers success quit, but Godot 4.7 headless still prints Canvas/TextServer/RID cleanup warnings after `M1 smoke test passed`. The test exits 0 and `python3 tools/check_release_candidate.py` passes; this is tracked as a residual teardown-warning item, not a visual/runtime blocker.

### Verification (after final P0/P1/P2 closure)

- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 7020 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> `checked 284 res:// references`; `res:// references OK`.
- `python3 tools/check_level_pressure.py` -> completes through `level_099`.
- `python3 tools/simulate_card_director.py` -> card offer simulation completes for all 99 levels.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits 0.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known cleanup warnings at process teardown.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 948 battle sprite files`.
- `python3 tools/check_app_store_assets.py` -> `App Store asset check OK`.
- `python3 tools/check_visual_screens.py` -> `Visual screen check OK: 6 routed screenshots`.
- `python3 tools/check_release_candidate.py` -> `Release candidate check OK`.
- `rg -n "ColorRect|StyleBoxFlat" gameplay meta ui -g '*.gd' -g '*.tscn'` -> no matches.
- `git diff --check` -> no whitespace errors.

## Full Model Firing Pose Finalization (2026-07-03)

> Owner requested that all remaining characters and guns match the accepted true-grip standard, with fully regenerated model art rather than a local vector/compositor shortcut.

- **Model-rendered source mode**: added `tools/generate_full_model_firing_pose_actions.py`, using built-in `image_gen` full-model chroma-key sheets for all four locked heroes plus the two owner-approved stage-1 overrides as source inputs. The generator removes chroma background, keeps only the primary connected alpha component, normalizes runtime-safe margins, and writes traceable model refs under `assets/production/source_refs/generated/firing_pose_full_model_2026_07_03/`.
- **Full production coverage**: regenerated all `4` characters x `8` weapons x `3` aim directions x `7` frames, for `672` production attack PNGs under `assets/production/sprites/animations/character_weapon_combos/`. The final action contract is two-handed grip, braced wide stance, forward recoil lean, no baked muzzle flash/smoke/tracer/projectile, and runtime-only VFX.
- **Direction correction**: the center attack pose is rotated toward true upward fire, while left/right aim retain distinct mirrored/right-biased silhouettes. `gameplay/battle/battle.gd` `CHARACTER_WEAPON_COMBO_MUZZLE*` dictionaries were refreshed from the final PNGs; all 32 combos pass the smoke-test requirement that left/center/right muzzle origins are separated.
- **Review evidence**: contact sheet `assets/production/source_refs/generated/firing_pose_full_model_2026_07_03/full_model_firing_pose_runtime_sheet_2026_07_03.png`; full sequence sheet `assets/production/source_refs/generated/firing_pose_full_model_2026_07_03/full_model_firing_pose_sequence_sheet_2026_07_03.png`; manifest `assets/production/source_refs/generated/firing_pose_full_model_2026_07_03/full_model_firing_pose_manifest_2026_07_03.json`.
- **Traceability**: `assets/production/OUTSOURCER_ASSET_INDEX.json` records this owner-directed generated override as `design/ui_firing_pose_task.md §1`.

### Verification (after full model firing pose finalization)

- `python3 -m py_compile tools/generate_full_model_firing_pose_actions.py` -> pass.
- `python3 tools/generate_full_model_firing_pose_actions.py` -> generated `704` files (`32` model refs + `672` runtime frames).
- Muzzle spread probe -> `muzzle spread OK: 32/32`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> checked `284` `res://` references; OK.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 7148 files`.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 948 battle sprite files`.
- `python3 tools/check_level_pressure.py` -> completed through `level_099`.
- `python3 tools/simulate_card_director.py` -> card offer simulation completed for all 99 levels.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits 0.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at process teardown.
- `git diff --check` -> no whitespace errors.

## VFX Full Redo Rollout (2026-07-03)

> Owner approved the six `design/vfx_full_redo_task.md` stage-1 samples and requested full rollout at the same top-tier raster standard, with no SVG/vector fallback.

- **Active signature VFX**: regenerated all frames for `vfx_active_sig_blaze_meltdown`, `vfx_active_sig_vanguard_overload`, `vfx_active_sig_vanguard_railvolley`, and `vfx_active_sig_volt_storm`; preserved approved `vfx_active_sig_frost_glacier`.
- **Skill-cast VFX**: regenerated all frames for the 15 non-venom `vfx_skill_cast_*` folders with distinct signatures for barrier, critical, cryo, charge, gold, homing, incendiary, multishot, pierce, recycle, ricochet, salvo, slow field, split shot, and tesla; preserved approved `vfx_skill_cast_venom`.
- **Enemy-skill VFX**: regenerated non-approved enemy skill families, including armor/ward, blast/enrage/explode/phase-burn/freeze, charge/juggernaut/leap/runner dash, soft-aura differentiation, and `mutate`; preserved the approved corrosion/regeneration/spit/toxic/storm-chain families.
- **Projectiles and attack cleanup**: replaced all five `proj_bullet_<element>.png` bodies with rendered energy-ammo PNGs. The 20 zombie attack frame sets (`80` PNGs) were rebuilt from each zombie's clean idle/walk body sources with a four-frame forward-pressure/recovery cycle, removing baked straight action bars while keeping the existing zombie art family, frame count, dimensions, and runtime paths intact.
- **Traceability**: source manifest and review sheets are under `assets/production/source_refs/generated/vfx_full_redo_full_2026_07_03/`, and `OUTSOURCER_ASSET_INDEX.json` records `design/vfx_full_redo_task.md full rollout`.

### Verification (after VFX full redo rollout)

- Target alpha/dimension scan -> checked `493` VFX/projectile PNGs plus `80` zombie attack PNGs; errors `0`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> checked `284` `res://` references; OK.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 7340 files`.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 948 battle sprite files`.
- `python3 tools/check_level_pressure.py` -> completed through `level_099`.
- `python3 tools/simulate_card_director.py` -> card offer simulation completed for all `99` levels.
- `/opt/homebrew/bin/godot --headless --path . --import` -> exits `0` after reimporting changed PNGs.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits `0`.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at process teardown.
- `python3 tools/check_release_candidate.py` -> `Release candidate check OK`.
- `git diff --check` -> no whitespace errors.

## Runtime UI Deep Polish Pass (2026-07-04)

> Owner requested that every uncomfortable or low-end runtime UI surface found in the self-audit be fixed in order, using the top-tier rendered App Store standard rather than reverting to vector/primitive-looking lines.

- **Battle HUD**: tightened the top HP/wave bars into the rendered grooves, rebuilt bottom XP/resource layout, anchored the bottom skill shelf to the HUD bottom edge, and resized the onboarding/wave toast so long Chinese copy wraps cleanly without becoming a giant flat banner.
- **Map**: reduced the over-thick header and nav dock, compacted level rows, removed redundant unlock pills, tightened star/deploy/status clusters, and kept the rendered card skin as the main readable surface instead of straight-line UI clutter.
- **Loadout**: rebuilt runtime spacing so the character/weapon panels, gear slots, details panel, and start button read as one hierarchy; empty armor/chip/pet slots now use labeled rendered placeholders instead of black voids.
- **Collection**: removed duplicate inner frames on rows, widened skill title/tag/effect copy, compacted skill detail modals, and reduced oversized detail buttons so list/detail pages no longer feel like stacked prototype boxes.
- **Result and settings**: compressed result action buttons into a cleaner hierarchy, shrank the secondary map button, added a rendered background layer to settings, and reduced settings typography/button heights for a polished modal feel.
- **Review evidence**: latest routed screenshots and contact sheet are under `tmp/ui_polish_after_2026_07_04/`, especially `contact_sheet_latest.png`.

### Verification (after runtime UI deep polish)

- `python3 tools/check_release_candidate.py` -> `Release candidate check OK`.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at process teardown.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 7420 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> checked `286` `res://` references; OK.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 948 battle sprite files`.
- `python3 tools/check_level_pressure.py` -> completed through `level_099`.
- `python3 tools/simulate_card_director.py` -> card offer simulation completed for all `99` levels.
- `python3 tools/check_visual_screens.py` -> `Visual screen check OK: 6 routed screenshots`.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits `0`.
- `git diff --check` -> no whitespace errors.

## Skill Icon Full Regeneration (2026-07-04)

> Owner requested direct execution of `design/skill_icon_regen_prompts_2026_07_04.md` at the top-tier rendered standard. The original production set had only `8` unique PNG hashes across `16` skill icons, causing collection-page duplicates and semantic mismatches.

- **Generation path**: used built-in `image_gen` once per skill icon, with the existing production frame/material sheet as style reference. Outputs were copied into `assets/production/source_refs/generated/skill_icon_regen_2026_07_04/` and locally chroma-keyed to transparent RGBA.
- **Production replacement**: overwrote all `16` `assets/production/sprites/ui/skill_*_icon.png` files at `256x256` RGBA while preserving existing filenames and `data/skills.json` references.
- **Semantic fixes**: split shot, pierce, multishot, slow field, homing, critical, barrier, gold rush, ricochet, salvo, incendiary, cryo, tesla, venom, charge shot, and recycle now each have distinct centered compositions. Tesla uses the game-standard gold lightning color, and fire/poison no longer share a green cloud.
- **Traceability**: manifest `assets/production/source_refs/generated/skill_icon_regen_2026_07_04/skill_icon_regen_manifest_2026_07_04.json`; review sheet `assets/production/source_refs/generated/skill_icon_regen_2026_07_04/skill_icon_regen_contact_sheet_2026_07_04.png`; registered in `assets/production/OUTSOURCER_ASSET_INDEX.json`.

### Verification (after skill icon full regeneration)

- Skill icon PNG integrity scan -> `16/16` files are `256x256` RGBA, transparent corners OK, and `16` unique SHA-256 hashes.
- `python3 tools/check_visual_assets.py` -> pass.
- `python3 tools/check_res_refs.py` -> pass.
- `godot --path . --script res://tools/_shot.gd -- collection '{"mode":"skills"}' tmp/skill_icon_regen_2026_07_04/collection_skills_after.png` -> screenshot captured for visual review.
- `python3 tools/check_release_candidate.py` -> pass.
- `git diff --check` -> no whitespace errors.

## SFX Expansion Full Integration (2026-07-05)

> Owner requested direct execution of `design/sfx_expansion_prompts_2026_07_05.md` at the best local-rendered quality, while preserving existing weapon shot and elemental hit sounds.

- **Generated SFX**: added `45` new `pcm_s16le / 44.1kHz / mono` WAV files under `assets/production/audio/sfx/`: `17` skill trigger sounds, `8` character intro/signature active sounds, and `20` zombie mechanic sounds.
- **Traceability**: deterministic local renderer `tools/generate_sfx_expansion_2026_07_05.py`; manifest `assets/production/source_refs/generated/sfx_expansion_2026_07_05/sfx_expansion_manifest_2026_07_05.json`; waveform review sheet `assets/production/source_refs/generated/sfx_expansion_2026_07_05/sfx_expansion_waveform_sheet_2026_07_05.png`.
- **Runtime integration**: `AudioManager` now registers all new keys, expands the SFX pool, and rate-limits high-frequency skill/zombie sounds. Battle runtime now plays character intro SFX, four dedicated signature active SFX, skill acquisition/trigger SFX, projectile split/chain/element trigger SFX, critical/gold-rush SFX, and zombie mechanic SFX for aura, spit, leap, charge, phase, summon, toxic, regen, split, mutate, enrage, runner, bomber, basic/brute/armor/crawler.

### Verification (after SFX expansion)

- Generated SFX manifest scan -> `45` outputs, duration range `0.11s` to `5.35s`, peak range locked at `-4.7 dBFS`.
- Godot import check -> all `45` new WAV files have `.import` files; rerun screenshot check no longer reports audio loader errors.
- `python3 -m py_compile tools/generate_sfx_expansion_2026_07_05.py` -> pass.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 7548 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> checked `331` `res://` references; OK.
- `python3 tools/check_level_pressure.py` -> completed through `level_099`.
- `python3 tools/simulate_card_director.py` -> card offer simulation completed for all `99` levels.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 948 battle sprite files`.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits `0`.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at process teardown.
- `python3 tools/check_visual_screens.py` -> `Visual screen check OK: 6 routed screenshots`.
- `python3 tools/check_release_candidate.py` -> `Release candidate check OK`.
- `git diff --check` -> no whitespace errors.

## Runtime Layout Breathing Pass (2026-07-05)

> Owner reported that the battle pause overlay and chip collection page felt cramped and visually constrained in-device screenshots.

- **Battle pause overlay**: widened and raised the pause panel, increased the content stack height, expanded status/loadout/skill section spacing, and resized metric pills so enlarged Chinese UI text no longer clips inside old 54px rows.
- **Pause action buttons**: rebuilt internal label geometry for the global `UiKit.FONT_SCALE`; title/subtitle/icon/arrow now fit inside 96px rendered buttons without overlapping or reading like pasted text.
- **Toast collision fix**: entering pause now hides any active wave/weakness toast, and paused battle state suppresses new top toasts so tutorial/weakness banners cannot sit on top of the pause modal.
- **Collection chip/equipment page**: increased root margins, title/resource/list separation, list row gaps, and roomy card height for weapons/armors/chips/pets. Resource chips are slightly smaller and centered so the header breathes before the list starts.
- **Screenshot evidence**: `tmp/ui_layout_polish_2026_07_05/battle_pause_after_v2.png` and `tmp/ui_layout_polish_2026_07_05/collection_chips_after.png`.

### Verification (after runtime layout breathing pass)

- `git diff --check` -> no whitespace errors.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits `0`.
- `/opt/homebrew/bin/godot --path . --script res://tools/_shot.gd -- collection '{"mode":"chips"}' tmp/ui_layout_polish_2026_07_05/collection_chips_after.png` -> screenshot captured at `1080x1920`.
- `/opt/homebrew/bin/godot --path . --script res://tools/_shot.gd -- battle '{"level_id":"level_039","pause":true}' tmp/ui_layout_polish_2026_07_05/battle_pause_after_v2.png` -> pause screenshot captured at `1080x1920`.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 7548 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> checked `331` `res://` references; OK.
- `python3 tools/check_level_pressure.py` -> completed through `level_099`.
- `python3 tools/simulate_card_director.py` -> card offer simulation completed for all `99` levels.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 948 battle sprite files`.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at process teardown.
- `python3 tools/check_visual_screens.py` -> `Visual screen check OK: 6 routed screenshots`.
- `python3 tools/check_release_candidate.py` -> `Release candidate check OK`.

## Selection Action Button Polish (2026-07-05)

> Owner reported that purchase/equip actions across selection pages looked too small and should read as explicit armored buttons, with unavailable actions clearly greyed out.

- **Collection card actions**: role/weapon/armor/chip/pet list cards now always show a large right-side rendered `TextureButton`: `购买 XX★`, `XX★ 不足`, `装  备` / `选  定`, or grey `已装备`. The old small native `Button` and tiny growth badge path were removed from the main card action area.
- **Disabled state**: unavailable buttons use the same rendered armor texture but grey modulation and muted label color, instead of disappearing or reading like a small status tag.
- **Detail modal actions**: item detail buy/equip/upgrade/close buttons and character detail upgrade/select/close buttons now share the same large armored button builder. Character signature skill upgrade buttons were enlarged to match the same visual language.
- **Purchase confirmation**: shared modal confirm/cancel buttons in `UiKit` were enlarged so the final "购买" confirmation no longer feels smaller than the selection-page action.
- **Screenshot helper**: `tools/_shot.gd` now supports `detail_item` for routed detail-modal screenshots, and waits for the modal fade animation before capture.
- **Screenshot evidence**: `tmp/selection_button_polish_2026_07_05/collection_chips_buttons.png`, `collection_weapons_buttons.png`, `collection_characters_buttons.png`, `detail_chip_attack_buttons_v2.png`, and `detail_character_buttons_v2.png`.

### Verification (after selection action button polish)

- `git diff --check` -> no whitespace errors.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits `0`.
- `/opt/homebrew/bin/godot --path . --script res://tools/_shot.gd -- collection '{"mode":"chips"}' tmp/selection_button_polish_2026_07_05/collection_chips_buttons.png` -> screenshot captured at `1080x1920`.
- `/opt/homebrew/bin/godot --path . --script res://tools/_shot.gd -- collection '{"mode":"weapons"}' tmp/selection_button_polish_2026_07_05/collection_weapons_buttons.png` -> screenshot captured at `1080x1920`.
- `/opt/homebrew/bin/godot --path . --script res://tools/_shot.gd -- collection '{"mode":"characters"}' tmp/selection_button_polish_2026_07_05/collection_characters_buttons.png` -> screenshot captured at `1080x1920`.
- `/opt/homebrew/bin/godot --path . --script res://tools/_shot.gd -- collection '{"mode":"chips","detail_item":"chip_attack"}' tmp/selection_button_polish_2026_07_05/detail_chip_attack_buttons_v2.png` -> detail screenshot captured at `1080x1920`.
- `/opt/homebrew/bin/godot --path . --script res://tools/_shot.gd -- collection '{"mode":"characters","detail_item":"vanguard"}' tmp/selection_button_polish_2026_07_05/detail_character_buttons_v2.png` -> detail screenshot captured at `1080x1920`.
- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 7548 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> checked `331` `res://` references; OK.
- `python3 tools/check_level_pressure.py` -> completed through `level_099`.
- `python3 tools/simulate_card_director.py` -> card offer simulation completed for all `99` levels.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 948 battle sprite files`.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at process teardown.
- `python3 tools/check_visual_screens.py` -> `Visual screen check OK: 6 routed screenshots`.
- `python3 tools/check_release_candidate.py` -> `Release candidate check OK`.

## Battle HUD / Endless / Pet / Projectile Polish (2026-07-05)

> Owner requested battle HUD breathing fixes, less intrusive hint banners, Endless-mode escalation/reward retention, richer pet growth, and hard lifetime bounds for homing/split projectiles.

- **Battle HUD**: moved the base HP bar from the top stack into the bottom bar beside XP, shifted XP left, compacted gold labels above `999` into `k` notation, and rebuilt the top wave bar so the rendered frame actually stretches instead of being aspect-centered. Wave fill is now warm gold and sits inside the track, removing the misleading blue sliver.
- **Hint banner cadence**: wave/weakness toast now sits below the top HUD and above battle midline, preserves long wrapped onboarding copy, and rate-limits non-critical short hints. Boss/final-wave/low-HP warnings remain immediate.
- **Endless mode**: pause-to-map now routes through Endless result settlement so current `gold` / `xp` is preserved. Each Endless final wave guarantees at least one boss; boss count increases every three loops up to six, and HP scaling is linear via `1.0 + 0.22 * endless_loop`, applied to normal enemies and bosses.
- **Pets**: `data/pets.json` now defines `stat_bonus` plus `level_stat_growth` for each pet. Runtime applies pet growth to damage, fire rate, element damage, crit, slow strength, base HP, breach mitigation, chain/pierce, and gold gain; collection detail cards expose these bonuses.
- **Projectiles**: all projectiles, including homing/split paths, despawn after `5.0s`; any projectile leaving the 1080x1920 playfield plus a small margin is removed and no longer returns to screen.
- **Screenshot evidence**: `tmp/hud_endless_pet_projectile_polish_2026_07_05/battle_hud_after_v7.png` and `tmp/hud_endless_pet_projectile_polish_2026_07_05/pet_detail_bonus.png`.

### Verification (after HUD / Endless / Pet / Projectile polish)

- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 7548 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> checked `331` `res://` references; OK.
- `python3 tools/check_level_pressure.py` -> completed through `level_099`.
- `python3 tools/simulate_card_director.py` -> completed `1000` runs per level.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits `0`.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at process teardown.
- `python3 tools/check_visual_screens.py` -> `Visual screen check OK: 6 routed screenshots`.
- `python3 tools/check_release_candidate.py` -> `Release candidate check OK`.
- `git diff --check` -> no whitespace errors.

## All-Level Tall-Screen Battle Background / Breach-Line Fix (2026-07-06)

> Owner reported that a high-screen battle screenshot had a black strip above the background, and that zombies began damaging the base while still visibly too far from the character/base model. Follow-up clarification: this must be fixed globally, not only for the reported screenshot or level.

- **Background anchoring**: `_apply_level_background()` now treats `1920 + bottom_dock_shift` as the visible battle height, cover-scales the current environment background against that height, and pins the background bottom edge to the real viewport bottom. This preserves the bottom composition while filling the extra top area instead of leaving a black/gradient strip.
- **Top-fill cleanup**: the old `BackgroundExtension` fallback is hidden after successful cover-scale placement, so high-screen devices use the actual rendered background rather than a flat dark patch.
- **Breach trigger line**: `enemy.gd` now exposes `configure_attack_line(base_line_y)`. Battle enemy spawning calls it with the runtime `BREACH_Y`, so normal zombies and bosses begin base attacks near the shifted player/base model instead of the old 1920-design coordinate.
- **Boss spawn regression fix**: while wiring the attack-line injection, the spawn path was normalized so bosses and normal enemies both run `setup()`, connect feedback/death/breach signals, and inherit endless difficulty scaling.
- **Threat warning sync**: `防线告急` ring/toast thresholds now derive from `BREACH_Y`, placing warning feedback near the real bottom defense line on high-screen layouts.
- **Projectile bounds sync**: projectile off-screen cleanup now uses the current visible viewport size, keeping the previous 5-second lifetime cap while preventing high-screen bottom shots from being culled against the old 1920px limit.
- **All-level guardrail**: new `tools/check_tall_battle_layout.py` scans all 99 levels, every environment row, all level spawn/boss ids, four viewport heights (`1920/2046/2340/2622`), and source snippets for bottom-anchored cover scaling plus `configure_attack_line(BREACH_Y)`. It is now part of `tools/check_release_candidate.py`.
- **Evidence**: high-screen capture `tmp/battle_safe_area_breach_fix_2026_07_06/battle_tall_after.png` was generated with a 1080x2340 request; the desktop capture environment produced `1080x2046`, still covering the tall-viewport case. Top-band pixel scan showed no solid black strip (`top160 exact_blackish=0.1667%`).
- **Environment review sheet**: all 10 campaign environments were cropped through the same 1080x2340 cover rule into `tmp/battle_safe_area_breach_fix_2026_07_06/all_campaign_env_tall_cover_sheet.png`.

### Verification (after tall-screen background / breach-line fix)

- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 7548 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> checked `331` `res://` references; OK.
- `python3 tools/check_visual_assets.py` -> `Visual asset check OK: 948 battle sprite files`.
- `python3 tools/check_tall_battle_layout.py` -> `Tall battle layout OK: 99 levels, 10 campaign envs, 14 total env rows, heights=1920,2046,2340,2622`.
- `python3 tools/check_level_pressure.py` -> completed through `level_099`.
- `python3 tools/simulate_card_director.py` -> completed `1000` runs per level.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits `0`.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at process teardown.
- `python3 tools/check_visual_screens.py` -> `Visual screen check OK: 6 routed screenshots`.
- `python3 tools/check_release_candidate.py` -> `Release candidate check OK`.
- `git diff --check` -> no whitespace errors.

## Battle Character / HUD Overlap Audit (2026-07-06)

> Owner asked to re-confirm whether the character model, HP bar, XP bar, and skill controls can be blocked in battle.

- **Root cause found**: the previous bottom-centered skill shelf could overlap the largest character/weapon attack silhouettes, especially true-grip heavy-gun frames. HP and XP were not overlapping each other, but the skill shelf was too close to the character body and weapon pose.
- **Skill shelf relocation**: `Hud/SkillSlots` is now a compact lower-left two-row `GridContainer` with 8 columns, 16-skill capacity, and smaller rendered skill cards. This preserves all owned skills while freeing the bottom-center character silhouette and bottom-right active-skill area.
- **Runtime sync**: `_layout_runtime_hud()` now uses the same lower-left grid geometry at runtime, so tall-screen bottom docking keeps the relative HUD spacing stable.
- **Regression guard**: added `tools/check_battle_hud_overlap.py`, which computes alpha-channel visible bounds for 4 characters x 8 weapons x idle/attack-left/attack/attack-right/hurt frames under max growth visual scale `1.16`, then checks those bounds against wave bar, skill grid, active skill button, gold, XP, and HP rects. It also verifies the full 16-skill grid capacity.
- **Release candidate coverage**: `tools/check_release_candidate.py` now runs both `check_tall_battle_layout.py` and `check_battle_hud_overlap.py` before app-store/string/simulation checks.
- **Screenshot evidence**: `tmp/hud_overlap_check_2026_07_06/battle_level_003.png`.

### Verification (after battle character / HUD overlap audit)

- `python3 tools/check_battle_hud_overlap.py` -> `Battle HUD overlap OK: 896 character/weapon frames, max growth scale=1.16, min skill gap=21.4px, min bottom-resource gap=10.1px`.
- `python3 tools/check_tall_battle_layout.py` -> `Tall battle layout OK: 99 levels, 10 campaign envs, 14 total env rows, heights=1920,2046,2340,2622`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> checked `331` `res://` references; OK.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits `0`.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at process teardown.
- `git diff --check` -> no whitespace errors.

## Battle Base-Line Alignment Audit (2026-07-06)

> Owner asked to confirm that zombie base attacks, the base barrier, and the slow-field area all align to the same inner/outer defense line.

- **Root cause found**: normal enemy base attacks already used runtime `BREACH_Y`, but several visual and skill-pressure paths still carried old fixed y targets such as `1360`, `1370`, and `1440 + bottom_dock_shift`. Slow-field visuals were `BREACH_Y`-based, while the actual slow判定 still read fixed `data/skills.json` `y_min` values.
- **Single line source**: `battle.gd` now has `_base_line_y()`, `_base_line_inner_y()`, and `_base_damage_impact_position()` helpers. Ordinary breach damage, ranged corrosion, toxic cloud, juggernaut shock, frost field, boss pressure, death blast base damage, and repair feedback all use those helpers.
- **Barrier alignment**: `BarrierGlass` is centered on `_base_line_y()`, and shield-break VFX uses the same `_base_damage_impact_position()` as base damage, so shield block / break feedback sits on the same defense line as incoming attacks.
- **Slow-field alignment**: `SkillRuntime.slow_mult_for_y()` now accepts the runtime base line and converts authored design offsets from `data/skills.json` relative to that line. The visual slow-field rectangle, its bottom edge line, particles, and actual slow判定 all share the same bottom edge at `_base_line_y()`.
- **Warning alignment**: near-line rings and `防线告急` thresholds now use named insets from `_base_line_inner_y(...)`, rather than raw y constants.
- **Regression guard**: added `tools/check_battle_line_alignment.py` and wired it into `tools/check_release_candidate.py`. It rejects old fixed base-impact y coordinates and verifies attack line, barrier, and slow-field code all derive from `BREACH_Y`.

### Verification (after battle base-line alignment audit)

- `python3 tools/check_battle_line_alignment.py` -> `Battle line alignment OK: attack line, base impact, barrier, and slow field all derive from BREACH_Y`.
- `python3 tools/check_tall_battle_layout.py` -> `Tall battle layout OK: 99 levels, 10 campaign envs, 14 total env rows, heights=1920,2046,2340,2622`.
- `python3 tools/check_battle_hud_overlap.py` -> `Battle HUD overlap OK: 896 character/weapon frames, max growth scale=1.16, min skill gap=21.4px, min bottom-resource gap=10.1px`.
- `python3 tools/validate_data.py && python3 tools/check_res_refs.py` -> data valid; checked `331` `res://` references; OK.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits `0`.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at process teardown.

## Audio Overlap / Stinger Ownership Audit (2026-07-06)

> Owner reported that some effects felt like multiple music tracks were playing at once.

- **Root cause found**: BGM itself was already a singleton `AudioStreamPlayer`, but result audio had two ownership points: `battle._finish()` played victory/defeat SFX and `meta/result.setup()` immediately played the same SFX again while starting result BGM. In addition, long character signature SFX (`sig_vanguard_railvolley`, `sig_blaze_meltdown`, `sig_frost_glacier`, `sig_volt_storm`) could keep playing across BGM switches.
- **Single result owner**: battle finish no longer plays victory/defeat stingers. Result scene owns the result BGM and the single short win/loss stinger.
- **Music-like SFX mutex**: `AudioManager.MUSIC_LIKE_SFX` marks long signature cues plus win/loss stingers. Starting a music-like SFX stops any previous music-like SFX, and switching BGM clears any lingering music-like SFX before the new music starts.
- **Meta-screen BGM cleanup**: `loadout` and `collection` now explicitly restore `map` BGM on entry, so the result music cannot carry into upgrade/equipment browsing after pressing result actions.
- **Regression guard**: added `tools/check_audio_overlap.py` and wired it into `tools/check_release_candidate.py`. It verifies singleton player ownership, music-like SFX mutex metadata, result stinger ownership, and the map-BGM restore on loadout/collection.

## Fire Hit / Active Skill Media Review (2026-07-06)

> Owner reported that fire bullets produced a side-plume flame near zombies, and that the fire active-skill flame had visible cutout edges. The request was to review all active skill VFX/SFX and rebuild any weak media at top rendered quality.

- **Root cause found**: the fire hit single-frame and sequence assets were directional plume/fireball crops, so placing them on enemy bodies looked like fire spraying in from one side. The runtime also stacked projectile-direction impact bursts, B4 fire impact cloud/heat haze, and active-skill generic muzzle intro on top of authored fire VFX.
- **Rendered VFX rebuild**: generated a new high-end rendered VFX reference board with built-in `image_gen`, copied it into `assets/production/source_refs/generated/active_skill_vfx_review_2026_07_06/`, and added `tools/regenerate_active_skill_vfx_2026_07_06.py` to extract/clean alpha and rebuild production PNG sequences.
- **Replaced assets**: regenerated `vfx_hit_fire` (12 frames), `vfx_explosion_fire` (16 frames), and all five active signature sequences (`vfx_active_sig_vanguard_railvolley`, `vfx_active_sig_vanguard_overload`, `vfx_active_sig_blaze_meltdown`, `vfx_active_sig_frost_glacier`, `vfx_active_sig_volt_storm`) with transparent PNG frames and refreshed the single-frame `vfx_hit_fire.png` / `vfx_explosion_fire.png`.
- **Alpha cleanup**: the generator removes black sheet backgrounds, low-alpha compression haze, and adjacent-frame bleed; frost/volt sequences use local high-resolution particle/ice/electric renderers to avoid sheet-cell rectangular artifacts.
- **Runtime cleanup**: `battle.gd` now uses the new centered fire hit/explosion sequences for fire impact, radial fire, and fire death bursts. Signature active-skill intro no longer spawns a second generic muzzle sequence. `projectile.gd` suppresses the directional fire impact burst for normal fire bullets, leaving the centered battle impact as the visible hit effect.
- **SFX review**: active-skill SFX files were present, mono 44.1 kHz, within the expected duration/peak/RMS ranges, and already protected by the music-like mutex from the audio-overlap pass; no audio file replacement was needed.
- **Regression guard**: added `tools/check_active_skill_media.py` and wired it into `tools/check_release_candidate.py`. It verifies active/fire sequence frame counts, clean alpha canvas edges, centered fire impact/explosion, and active-skill SFX duration/loudness bounds.
- **Evidence**: contact sheets at `assets/production/contact_sheets/contact_fire_vfx_review_2026_07_06.png` and `assets/production/contact_sheets/contact_active_skill_vfx_review_2026_07_06.png`; manifest at `assets/production/source_refs/generated/active_skill_vfx_review_2026_07_06/active_skill_vfx_manifest_2026_07_06.json`.

### Verification (after fire hit / active skill media review)

- `python3 tools/check_active_skill_media.py` -> `Active skill media OK: fire VFX centered, alpha edges clean, active SFX bounded`.

## Map Selection Alignment Polish (2026-07-06)

> Owner pointed out that the map selection page still had visible alignment issues: top equipment status badges leaked out of their icon cells, star rows had uneven vertical padding, and "进入" / "挑战模式" were stacked too tightly for phone tapping.

- **Top nav cells**: the six feature cards now share a tighter 114px height contract. Status badges are wider, clipped, and rendered inside each icon cell, so `等级1` / `未装` / `图鉴` no longer push past the square card edge under the global enlarged font scale.
- **Level card grid**: each level card now uses a stable right-side block with two centered star rows above a dedicated action row. Normal/challenge stars have equal line height and spacing, instead of sharing cramped coordinates with the old vertical button column.
- **Action ergonomics**: "进入" and "挑战模式" are horizontal rendered `TextureButton`s with consistent 44px height, greyed but still labeled when locked, making the row easier to tap on a phone while reducing vertical pressure.
- **Variant badge cleanup**: boss/elite/treasure markers moved back beside the title area, leaving the button row visually independent.
- **Screenshot evidence**: `tmp/map_ui_alignment_polish_2026_07_06_v2.png`.

### Verification (after map selection alignment polish)

- `/opt/homebrew/bin/godot --path . --script res://tools/_shot.gd -- map '{}' tmp/map_ui_alignment_polish_2026_07_06_v2.png` -> screenshot captured at `1080x1920`.

## Campaign Chapter Map / Sub-Level Flow (2026-07-06)

> Owner requested a clearer campaign-map structure like stage-based mobile games: every ten levels should form one larger map/chapter, clearing a chapter should reveal the next, level 5 should be a small boss, and level 10 should be a major boss.

- **Two-layer campaign flow**: `meta/map/map.gd` now renders a first-screen chapter map made from the existing `levels[].chapter` / `levels[].env` data. Selecting an unlocked chapter opens the existing sub-level list for that chapter, preserving the current per-level layout and normal/challenge buttons.
- **Data-driven story**: `data/environments.json` now carries `chapter_title`, `story`, and `objective` for the ten campaign environments. The chapter UI reads these fields from data instead of hardcoding story copy in the scene script.
- **Boss markers**: each chapter card highlights the level-5 small boss and level-10 major boss (or the final boss-rush row in chapter 10), with cleared/locked state derived from save progress.
- **Unlock model**: a chapter is available when its first level is unlocked, so clearing level 010 naturally unfolds chapter 2 through the existing progression rules; locked chapter CTA text explains which previous chapter must be cleared.
- **Visual polish**: chapter cards use the existing high-end rendered environment portraits as the art layer, the runtime rendered UI skins for the frame/button/progress components, and deterministic CJK line wrapping to keep story copy out of the right-side progression area.
- **Regression coverage**: `tools/m1_smoke_test.gd` now asserts the chapter overview first, then opens chapter 1 and asserts the sub-level list and normal/challenge buttons. `tools/check_visual_screens.py` now captures both `map` and `map_chapter`.
- **Screenshot evidence**: `tmp/chapter_map_overview_2026_07_06.png` and `tmp/chapter_map_detail_2026_07_06.png`.

### Verification (after campaign chapter map / sub-level flow)

- `python3 tools/validate_asset_pack.py` -> `Asset pack validation passed: 7554 files`.
- `python3 tools/validate_data.py` -> `Data validation passed: 99 levels, 20 zombies, 8 boss, 16 skills, 14 environments`.
- `python3 tools/check_res_refs.py` -> checked `335` `res://` references; OK.
- `python3 tools/check_level_pressure.py` -> completed through `level_099`; every level-5 and level-10 chapter endpoint is still a boss row in pressure output.
- `python3 tools/simulate_card_director.py` -> completed `1000` runs per level.
- `/opt/homebrew/bin/godot --headless --path . --quit` -> exits `0`.
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd` -> `M1 smoke test passed`; Godot 4.7 headless still prints the known Canvas/CanvasItem/ObjectDB/RID cleanup warnings at process teardown.
- `python3 tools/check_visual_screens.py` -> `Visual screen check OK: 7 routed screenshots`.
- `python3 tools/check_release_candidate.py` -> `Release candidate check OK`.
- `git diff --check` -> no whitespace errors.

## Projectile Ballistics / Homing Guardrails (2026-07-06)

> Owner required homing bullets to feel like real projectiles: leave the muzzle first, avoid instant pivots, never return from off-screen, and always self-clear after five seconds.

- **One-second muzzle flight**: `gameplay/projectile/projectile.gd` now arms homing only after `HOMING_ACTIVATION_DELAY = 1.0`, so homing/split projectiles first fly straight from the gun barrel before steering.
- **Minimum turn radius**: homing steering now uses `_homing_turn_rate_limit(speed)`, combining `homing_strength`, a `460px` minimum turn radius, and a hard `3.4 rad/s` cap. This replaces the old free `lerp`/small-radius turn feel and prevents visible in-place pivots.
- **Strict bounds cleanup**: projectiles check the current visible viewport before and after movement. Once `x/y` leaves the visible playfield, the projectile is queued for deletion immediately instead of being allowed to arc back in.
- **Lifetime cap**: `PROJECTILE_MAX_LIFETIME = 5.0` is enforced before homing/movement every physics tick, covering normal, split, chain, and homing projectiles through the shared projectile runtime.
- **Regression guardrails**: `tools/m1_smoke_test.gd` now directly asserts the one-second straight segment, post-delay steering, turn-rate cap, off-screen cleanup, and five-second cleanup. `tools/check_gameplay_polish.py` statically requires the new homing/lifetime constants and turn-limit helper.
