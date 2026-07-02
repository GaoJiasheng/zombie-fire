# Final Visual Todo - 2026-07-02

This audit is based on fresh Godot runtime captures, not stale prototype sheets.

Evidence:
- Runtime screen sheet: `../../tmp/final_visual_todo_2026_07_02/current_runtime_screens_sheet.png`
- Problem crop sheet: `../../tmp/final_visual_todo_2026_07_02/final_visual_problem_thumbnails.png`
- Individual captures: `../../tmp/final_visual_todo_2026_07_02/screens/`
- After P0/P1 implementation sheet: `../../tmp/final_visual_todo_2026_07_02/final_p0p1_runtime_screens_after.png`

Audit unblock fixes already made:
- `main.gd`: desktop/headless captures no longer apply mobile safe-area offsets.
- `gameplay/battle/battle.gd`: HUD fill styling now targets `CanvasItem.modulate`, so Panel-backed fills do not crash.

## P0/P1 Implementation Status - 2026-07-02

P0 and P1 are now implemented for the player-facing surfaces listed below.

- Generated 39 raster UI skins via `tools/generate_final_visual_p0p1_assets.py`; outputs are PNG / `StyleBoxTexture` assets, not SVG/vector.
- Added missing visual traceability files under `assets/production/source_refs/` and `assets/production/contact_sheets/`, including character/weapon combo manifest and matrix.
- Repaired 41 fully transparent VFX tail frames by replacing them with fading bitmap residue, so sequence endings no longer create blank-frame dead air.
- Replaced 14 two-second production videos with six-second MP4s at the same paths.
- Rewired map, loadout, collection, result, and battle HUD surfaces to consume PNG skins for cards, chips, reward panels, hint strips, icon frames, skill slots, health/XP fills, and cooldown overlays.
- P2 source-level UI primitive cleanup is now implemented: runtime UI overlays/fallbacks use texture-backed or empty style resources, and `ColorRect` / `StyleBoxFlat` are no longer present in `gameplay/`, `meta/`, or `ui/` `.gd/.tscn` files.

## P0 - Must Fix Before Final Visual Signoff

1. Battle HUD still exposes flat primitive UI. **Status: fixed in P0/P1 pass.**
   - Evidence: `screens/09_battle.png`, problem sheet cards `P0 战斗顶部 HUD`, `P0 战斗底部 HUD`.
   - Files: `gameplay/battle/battle.tscn`, `gameplay/battle/battle.gd`, `ui/ui_kit.gd`.
   - Issue: top HP/wave bars, bottom XP/resource/skill region, cooldown/overlay layers still read as flat bars and simple rectangular states.
   - Target: texture-backed HUD frames, rendered fill caps, consistent metal/glass material language, no visible raw ColorRect/StyleBoxFlat surface in the main battle HUD.

2. Battle tutorial/attention text reads like a debug overlay. **Status: fixed in P0/P1 pass.**
   - Evidence: `screens/09_battle.png`, problem sheet card `P0 战斗提示文字`.
   - Files: `gameplay/battle/battle.tscn`, `gameplay/battle/battle.gd`.
   - Issue: large plain text floats over the playfield and fights the rendered battlefield.
   - Target: compact cinematic callout or texture-backed mission hint that does not cover the combat read.

3. Map level cards still look line-heavy and prototype-like. **Status: fixed in P0/P1 pass.**
   - Evidence: `screens/01_map.png`, problem sheet card `P0 地图关卡卡片`.
   - Files: `meta/map/map.gd`, `assets/production/sprites/ui/ui_map_level_card_skin*.png`.
   - Issue: list rows rely on straight borders, flat chips, and many small labels; the composition is functional but not App Store final.
   - Target: authored campaign-card layout with stronger rendered frame, clearer star/weakness hierarchy, and less exposed linework.

4. Visual source traceability is broken. **Status: fixed in P0/P1 pass.**
   - Evidence: `python3 tools/check_visual_assets.py` fails.
   - Missing paths: `assets/production/source_refs/hero_battle_pose_sheet.png`, `assets/production/source_refs/handheld_weapon_sheet.png`, `assets/production/source_refs/generated/character_weapon_combo_generation_manifest.json`, `assets/production/source_refs/generated/character_weapon_combo_matrix.png`.
   - Issue: `OUTSOURCER_ASSET_INDEX.json` references generated/source/contact-sheet outputs that are not present in the current filesystem.
   - Target: restore or regenerate source refs/contact sheets/manifests, then make `tools/check_visual_assets.py` pass.

## P1 - High-Impact Polish

1. Map top resource chips and navigation tabs are too engineering-like. **Status: fixed in P0/P1 pass.**
   - Evidence: `screens/01_map.png`, problem sheet card `P1 地图顶部资源/Tab`.
   - Files: `meta/map/map.gd`, `ui/ui_kit.gd`.
   - Target: one cohesive rendered nav/resource dock, not separate flat chips and tab boxes.

2. Loadout empty slots and summary area are still prototype UI. **Status: fixed in P0/P1 pass.**
   - Evidence: `screens/02_loadout.png`, problem sheet card `P1 出战空槽区域`.
   - Files: `meta/loadout/loadout.gd`, `meta/loadout/loadout.tscn`.
   - Target: premium equipment sockets with rendered empty/locked states; remove bare plus-sign slots and plain dividers.

3. Collection pages feel like database lists. **Status: improved in P0/P1 pass.**
   - Evidence: `screens/04_collection_weapons.png`, `screens/08_collection_skills.png`, problem sheet cards `P1 武器图鉴列表`, `P1 技能图鉴列表`.
   - Files: `meta/collection/collection.gd`.
   - Target: category-specific gallery/card presentations that let the rendered asset lead; keep dense details secondary.

4. Result screens are usable but not final-grade. **Status: fixed in P0/P1 pass.**
   - Evidence: `screens/10_result_victory.png`, `screens/11_result_defeat.png`, problem sheet cards `P1 胜利结算`, `P1 失败结算`.
   - Files: `meta/result/result.tscn`, `meta/result/result.gd`.
   - Target: unify reward cards, CTA buttons, star row, and hint strip under one rendered panel system.

5. VFX sequence terminal frames need review. **Status: fixed in P0/P1 pass.**
   - Evidence: scan found 41 fully transparent PNG frames under `assets/production/sprites/vfx_sequences/**`.
   - Issue: transparent terminal frames may be intentional timing pads, but they must not create visible animation dead air.
   - Target: verify in motion; trim, replace, or document intentional holds.

6. Production videos are mostly placeholder-length. **Status: fixed in P0/P1 pass.**
   - Evidence: 14 of 15 files under `assets/production/video/` are exactly 2 seconds; only `vid_app_preview.mp4` is 18 seconds.
   - Target: regenerate real final clips or explicitly remove them from final deliverable scope.

## P2 - Internal Cleanup / Lower Priority

1. Primitive drawing code remains in non-final or functional layers. **Status: UI primitive cleanup complete.**
   - Evidence: `rg -n "ColorRect|StyleBoxFlat" gameplay meta ui -g '*.gd' -g '*.tscn'` returns no matches.
   - Remaining scan hits for `Line2D|Polygon2D|GPUParticles2D` are confined to projectile, battle, and VFX implementation paths. They are texture/material-backed combat effects, not UI card/frame/overlay skins.
   - Follow-up: `tools/m1_smoke_test.gd` exits 0 but Godot 4.7 headless still prints Canvas/TextServer/RID cleanup warnings during process teardown. Screenshot helper teardown is fixed.

2. App Store screenshots should be recaptured after P0/P1 visual work. **Status: complete.**
   - Evidence: refreshed captures under `tmp/final_p0_runtime_screens/`, regenerated `assets/appstore/screenshots/**`, and rebuilt `assets/production/video/vid_app_preview.mp4`.
   - Verification: `python3 tools/check_app_store_assets.py`, `python3 tools/check_visual_screens.py`, and `python3 tools/check_release_candidate.py` pass.
