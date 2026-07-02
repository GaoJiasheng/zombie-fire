# Final Art Quality Audit · 2026-07-01

Scope: screen every local asset group against the new owner bar: high-end 3D rendered / App Store-grade / final-art quality.

This is a quality audit, not a missing-file audit. `validate_asset_pack.py` can pass while the art is still prototype-grade.

## Quality Bar

An asset is considered final-grade only if it meets all relevant points:

- Reads as authored premium mobile-game art, not SVG/procedural placeholder.
- Matches the locked 2.5D cartoon-realistic / cyberpunk ruined-city direction.
- Has strong small-size readability on a 1080x1920 vertical mobile screen.
- Uses stable element colors and the same lighting/material language.
- Is integrated through production paths, with no visible legacy `assets/sprites` fallback.
- For store-facing assets: looks good standalone without needing gameplay context.

## Evidence Snapshot

- Production PNG count checked: 2441 under `assets/production`, plus 3 under `assets/app`, plus 18 app-store screenshot PNGs.
- Production visual asset count by key group:
  - `sprites/characters`: 12
  - `sprites/zombies`: 60
  - `sprites/bosses`: 24
  - `sprites/pets`: 18
  - `sprites/weapons`: 24
  - `sprites/equipment`: 14
  - `sprites/ui`: 68
  - `sprites/vfx`: 24
  - `sprites/projectiles`: 11
  - `sprites/backgrounds`: 16
  - `environment`: 32
  - `sprites/parts`: 414
  - `sprites/animations`: 1510
  - `sprites/vfx_sequences`: 186
- Data asset refs are clean: all asset refs in `data/*.json` point to `assets/production`, with no legacy `res://assets/sprites/...` data refs.
- Runtime code/scene refs still include 28 legacy `res://assets/sprites/...` refs.
- `tools/check_visual_assets.py` passes: transparent cutout and combo-frame technical checks are OK.
- App Store screenshot drafts and launch image are visually below the new bar.
- All 15 production videos are 1080x1920, 2.0s, 48-frame placeholder-style clips.
- Audio is still placeholder-like for final production: BGM loops are mono WAV, mostly 16s; SFX are short mono WAVs.

Temporary evidence sheets generated during audit:

- `tmp/art_audit/current_runtime_screens_sheet.png`
- `tmp/art_audit/appstore_ios67_sheet.png`
- `tmp/art_audit/legacy_runtime_refs_sheet.png`
- `tmp/art_audit/video_frame_sheet.png`
- `tmp/art_audit/parts_sample_sheet.png`

## Verdict

The project is no longer missing broad content, and many unit/icon assets are acceptable as high-end prototypes. It is not yet consistent with the new requirement that all assets be App Store final-art quality.

The main gap is not the roster art. The main gap is that the project still mixes high-end prototype art with flat UI assets, procedural runtime effects, legacy runtime paths, placeholder store screenshots, placeholder videos, and cropped skeletal parts.

## P0 Replacement Update · 2026-07-01

After owner review of the "must redo only" thumbnail sheet, a P0 replacement pass was completed for the asset-facing items below:

- `assets/app/launch_1080x1920.png` was replaced with high-end rendered launch key art matching the new app icon direction.
- `assets/appstore/screenshots/**` drafts were regenerated for `ios_65`, `ios_67`, and `ipad_129` using the refreshed runtime screenshots and a premium App Store composition.
- `assets/production/video/vid_app_preview.mp4` was replaced with an 18-second 1080x1920 rendered preview draft.
- Flat UI kit assets under `assets/production/sprites/ui/` were replaced with a darker metal HUD family: buttons, panel, bars, icons, card frames, card utility icons, tags, stars, skill slots, and target strategy badges.
- After review, the primary/secondary action buttons were corrected again so both use one shared bevel, border, glow, and lighting model; `meta/result/result.gd` no longer tints result action buttons into separate visual styles.
- The reviewed P0 batch was then raised again with a generated top-tier HUD material reference: visible UI image assets now share a single dark gunmetal/glass 3D render language with cyan/orange rim lighting, bevel depth, controlled glow, and embossed icon symbols instead of flat vector shapes.
- `assets/production/sprites/vfx/vfx_target_lock.png` was replaced for the visible lock-ring path.
- Runtime `res://assets/sprites/...` visible refs were migrated to `res://assets/production/sprites/...`; `rg "res://assets/sprites/" meta gameplay ui core project.godot` now returns no matches.
- Desktop/runtime screenshot capture for map/loadout was fixed after finding `DisplayServer.get_display_safe_area()` could return global display coordinates in the screenshot process and push non-battle UI roots offscreen; screenshots and App Store composites were regenerated with visible UI content.
- Source prompt/spec/contact sheet were stored under `assets/production/source_refs/generated/`, and the replacements were registered in `assets/production/OUTSOURCER_ASSET_INDEX.json`.

Current evidence:

- `assets/production/source_refs/generated/final_p0_replacement_contact_sheet_2026_07_01.png`
- `assets/production/source_refs/generated/final_p0_hud_reference_source_2026_07_01.png`
- `assets/production/source_refs/generated/final_p0_hud_reference_prompt_2026_07_01.txt`
- `assets/production/source_refs/generated/character_weapon_combo_shooting_focus_sheet_2026_07_01.png`
- `assets/production/source_refs/generated/character_weapon_combo_shooting_polish_contact_sheet_2026_07_01.png`
- `tmp/final_p0_runtime_screens/`
- `tmp/final_p0_runtime_screens/result_button_unified.png`
- `tools/generate_final_p0_assets.py`
- `tools/generate_character_weapon_combos.py`
- `tools/check_visual_screens.py`

Remaining P0-adjacent risk: the runtime screens still contain code-generated surfaces and primitives (`StyleBoxFlat`, `ColorRect`, raw labels, some procedural VFX). The new image assets improve the visible build, but a deeper UI-code skin pass is still needed before calling every runtime panel and effect fully final.

## P0 · Must Redo Before Calling Art Final

### Store / Brand Assets

| Asset group | Evidence | Reason |
|---|---|---|
| `assets/app/launch_1080x1920.png` | Still shows the old small turret-card mark with large empty dark field. | Does not match the new high-end app icon or final brand bar. |
| `assets/appstore/screenshots/**/*.png` | Existing screenshot drafts show tiny content, old prototype panels, large dead space, and old icon/card visuals. | Not credible App Store screenshots; must be regenerated from final UI/art. |
| `assets/production/video/vid_app_preview.mp4` | 2.0s placeholder clip; representative frame is not gameplay preview quality. | Not store-grade App Preview. Needs 15-30s gameplay capture or authored preview. |

### Runtime Legacy References

There are 28 runtime refs to legacy `res://assets/sprites/...` paths:

- `meta/menu/menu.tscn`: `bg_city_ruins`, primary/secondary buttons.
- `meta/map/map.tscn` and `meta/map/map.gd`: legacy background and buttons.
- `meta/loadout/loadout.tscn`: legacy background and primary button.
- `meta/collection/collection.tscn` and `.gd`: legacy background and buttons.
- `meta/result/result.tscn`: legacy background and buttons.
- `gameplay/battle/battle.tscn`: legacy HP/wave bars, pause, currency icons, buttons.
- `gameplay/battle/battle.gd`: legacy buttons and `vfx_target_lock`.
- `gameplay/hud/gold_fly.gd`: legacy gold icon.
- `gameplay/hud/off_screen_indicator.gd`: legacy `vfx_target_lock`.
- `gameplay/turret/turret.gd`: legacy fallback `weapon_autocannon_turret`.

Even when the files are byte-identical to production copies, final integration should not route through legacy fallback paths. The final build should resolve visible art from `assets/production` only, or the legacy path should be formally treated as compatibility-only and not referenced by scenes/scripts.

### UI Asset Kit

| Asset group | Evidence | Reason |
|---|---|---|
| `assets/production/sprites/ui/ui_button_*.png` | Flat blue/grey rounded bars. | Prototype UI, not high-end rendered cyberpunk HUD. |
| `assets/production/sprites/ui/ui_*bar.png` | Thin flat progress tracks. | Functional, not premium final HUD. |
| `assets/production/sprites/ui/icon_currency_*`, `icon_pause`, `icon_settings`, `icon_lock`, `icon_warning`, element icons | Simple flat/vector shapes. | Contradicts the "no SVG/vector-looking final art" bar. |
| `assets/production/sprites/ui/ui_card_*`, tag icons, target strategy icons | Line-art/symbol-led prototype visuals. | Needs final asset-backed UI family with material depth and stronger icon language. |

### Code-Generated UI Surfaces

The actual screens still rely heavily on `StyleBoxFlat`, `ColorRect`, raw `Label`, and code-built panels:

- `ui/ui_kit.gd`
- `meta/map/map.gd`
- `meta/loadout/loadout.gd/.tscn`
- `meta/collection/collection.gd/.tscn`
- `meta/result/result.gd/.tscn`
- `gameplay/battle/battle.gd/.tscn`

This is acceptable for layout iteration. It is not final-art quality. Final pass should keep layout logic but add a premium texture/nine-slice skin layer, image-backed panels, icon-led controls, and authored motion.

### Runtime Procedural Effects Still Visible

The VFX system was improved, but runtime still uses many procedural primitives:

- `Line2D` trails/arcs/rings in `gameplay/projectile/projectile.gd`, `gameplay/battle/battle.gd`, and `gameplay/vfx/vfx_lib.gd`.
- `ColorRect` flashes, bars, overlays, warning fills, and pulse blocks.
- `Polygon2D` barrier fill and shards.
- Raw `Label` damage numbers and floating status text.

For final art, these should be replaced or masked by authored texture sequences, sprite trails, edge-vignette damage overlays, premium number styling, and compact icon badges.

## P1 · High Priority Final-Art Upgrade

### Projectiles

`assets/production/sprites/projectiles/*.png` are better than the original flat placeholders, but still read as script-rendered icon projectiles rather than top-tier 3D rendered ammo. Upgrade to authored 3D projectile/trail sets per weapon and element.

Affected:

- `proj_bullet_physical`
- `proj_bullet_fire`
- `proj_bullet_ice`
- `proj_bullet_lightning`
- `proj_bullet_poison`
- `proj_heavy_charge`
- `proj_acid_spit`
- `proj_split_mini`
- `proj_rail_slug`
- `proj_scatter_pellet`
- `proj_plasma_orb`

### VFX Single Sprites and Sequences

The current VFX is usable as prototype gameplay feedback. It is not consistently final:

- `assets/production/sprites/vfx/*.png`
- `assets/production/sprites/vfx_sequences/**`

Problem patterns:

- Some assets remain simple symbols or geometric bursts.
- Runtime often uses single-frame sprite tweening rather than sequence playback.
- Many major events reuse generic hit/muzzle/phase assets instead of unique authored effects.

Upgrade target: weapon-specific muzzle sequences, per-zombie attack VFX, active-skill cinematic sequences, final death/splatter/debris sprites, slow-field/barrier authored sprite systems.

### Backgrounds and Environment Portraits

The campaign backgrounds are readable, but the current set has too much shared road-layout/tint-variant DNA. For final art, each environment should have a distinct landmark and material identity.

Affected:

- `assets/production/sprites/backgrounds/bg_*.png`
- `assets/production/environment/*_portrait.png`
- `assets/production/environment/*_battle_layout_guide.png` is development-only and should not be user-visible.

### Skeletal Parts

`assets/production/sprites/parts/**` look like crop-derived body parts. They are useful for prototype animation and pass technical checks, but they are not final hand-cut parts.

Upgrade target:

- Clean hand-cut alpha edges.
- Consistent pivots.
- No awkward half-limbs or cropped body slabs.
- Dedicated final parts for every visible character, enemy, boss, pet, and weapon if the final animation system still uses parts.

### Character / Weapon Combo Frames

`assets/production/sprites/animations/character_weapon_combos/**` are one of the better current systems, but the matrix shows many near-identical poses and small pose deltas. They need a visual QA pass before final:

- Check hand grip and weapon scale for all 4 x 8 combinations.
- Regenerate weak combinations instead of accepting a matrix-wide batch.
- Add stronger skill-cast, recoil, hit-reaction, victory/defeat, and idle personality states.

Update 2026-07-01: the owner-called-out firing discomfort has been addressed for the current fused combo set. `tools/generate_character_weapon_combos.py` now regenerates all 608 combo frames with a stronger F1 shot flash, F2 recoil, F3 settle, and F4 recovery rhythm; `gameplay/battle/battle.gd` locks the firing aim/muzzle/attack-frame set during the attack window so projectiles and character pose stay synchronized. Evidence sheets:

- `assets/production/source_refs/generated/character_weapon_combo_shooting_focus_sheet_2026_07_01.png`
- `assets/production/source_refs/generated/character_weapon_combo_shooting_polish_contact_sheet_2026_07_01.png`

Remaining final-art scope for this group is no longer the basic shooting/recoil read, but additional personality states: skill-cast, hit-reaction, victory/defeat, and per-weapon live-play feel checks on device.

### Videos

All 15 videos are currently 2-second placeholder-style clips:

- `assets/production/video/vid_app_preview.mp4`
- `assets/production/video/vid_intro_opening.mp4`
- `assets/production/video/vid_chapter_*.mp4`
- `assets/production/video/vid_boss_intro_*.mp4`
- `assets/production/video/vid_ending.mp4`

Final target:

- Boss intros: distinct entrance animation, camera move, hit pose, no placeholder UI strip.
- Chapter clips: if kept, use real cinematic transitions or cut them from scope.
- App preview: actual 15-30s gameplay capture or edited final trailer.

### Audio

Not part of "3D render", but part of "all assets final":

- BGM is mono WAV and mostly 16s.
- SFX is short mono placeholder audio.

Final target: mastered loops, balanced loudness, stronger weapon identity, stronger boss/skill/reward sounds.

## P2 · Lower Priority / Keep as Internal Only

These should not be judged by final-art standards as long as they never ship visibly:

- `assets/production/contact_sheets/**`
- `assets/production/source_refs/**`
- `assets/production/environment/*_battle_layout_guide.png`
- `tmp/art_audit/**`
- Old `assets/m1_visual/**` sample sheets and prototypes.

If any of these appear in runtime or store screenshots, treat that as a P0 integration bug.

## Areas Currently Closest to Final

These are not guaranteed final, but they are closest to the desired direction:

- `assets/app/app_icon_1024.png`: newly redesigned, high-end app icon direction.
- `assets/production/sprites/characters/*_prototype/icon/portrait`: good enough as high-end prototype; still needs final pose/animation QA.
- `assets/production/sprites/zombies/*_prototype/icon/portrait`: coherent and readable; final pass should focus on animation and silhouette variants.
- `assets/production/sprites/bosses/*_prototype/icon/portrait`: strong direction, but boss-specific animation/VFX is not final.
- `assets/production/sprites/pets/*`: good icon/prototype direction; needs animation/support VFX pass.
- `assets/production/sprites/ui/skill_*_icon.png` and `sig_*_icon.png`: materially better than generic UI icons and can be retained longer, though final polish may still adjust framing.

## Recommended Replacement Order

1. Brand/store pack: regenerate launch image, all App Store screenshots, and app preview using the new icon/art direction.
2. UI final skin: replace flat UI PNGs, migrate all runtime refs away from `assets/sprites`, add premium image-backed panels and HUD.
3. Combat VFX final pass: replace procedural rings/lines/rectangles/labels with authored sequences, particles, number styles, and event badges.
4. Projectiles/trails: regenerate projectile sprites as real 3D-rendered ammo plus animated trails.
5. Background final pass: remake chapter backgrounds with distinct landmarks while preserving battle readability.
6. Animation/parts pass: hand-cut or regenerate skeletal parts, then QA character/weapon combos and enemy/Boss animations.
7. Video/audio finalization: create real App Preview, boss intros, mastered BGM/SFX.

## Practical Next Chunk

The original P0 practical chunk has been completed for asset files and runtime reference migration. The next most efficient chunk is the deeper code-level skin pass:

1. Replace remaining `StyleBoxFlat` / `ColorRect` panel construction with texture-backed skins or shared UI components where it affects visible polish.
2. Replace remaining raw damage/status label styling with authored number/badge treatment.
3. Continue P1 work on projectiles, VFX sequences, backgrounds, skeletal parts, and animation QA.

Update 2026-07-01 runtime first batch: UI/projectile/VFX items above now have a first texture-backed upgrade pass. `tools/generate_top_tier_runtime_art.py` uses a built-in `image_gen` high-end material reference plus local raster generation to write runtime skin PNGs, all 11 projectile sprites, VFX singles/sequences, slow-field and barrier bitmaps, a spec, and a contact sheet:

- `assets/production/source_refs/generated/runtime_top_tier_imagegen_reference_2026_07_01.png`
- `assets/production/source_refs/generated/runtime_top_tier_polish_spec_2026_07_01.json`
- `assets/production/source_refs/generated/runtime_top_tier_polish_contact_sheet_2026_07_01.png`

Runtime hookups now cover common `UiKit` panel/pill/resource-chip styleboxes, damage number badges, combo frame, slow-field texture sampling, and rendered barrier glass. Remaining final-art work is no longer "all UI/projectiles/VFX are untouched"; it is the second-layer cleanup of local page-specific `StyleBoxFlat` / `ColorRect` / Line2D procedural pieces plus the larger P1 groups: backgrounds, skeletal parts, non-shooting animation states, videos, and audio.

Update 2026-07-01 background render pass: the "Backgrounds / Environment Plates" P1 item has a top-tier replacement pass integrated for the 10 main campaign environments. Built-in `image_gen` was used to generate distinct 3D-rendered vertical battlefield source images, then `tools/integrate_top_tier_backgrounds.py` cropped/graded them into the existing runtime background, portrait, and layout-guide paths without changing `data/environments.json` references.

- `assets/production/contact_sheets/contact_top_tier_backgrounds_2026_07_01.png`
- `assets/production/source_refs/generated/top_tier_background_render_spec_2026_07_01.json`
- `assets/production/source_refs/generated/top_tier_background_sources_2026_07_01/`

Remaining final-art concern for backgrounds is now owner visual review and possible screenshot/trailer refresh alignment, not SVG/vector placeholder quality.

Update 2026-07-01 skeletal parts polish pass: the `assets/production/sprites/parts/**` placeholder-derived cutout concern has a raster cleanup pass integrated. All 414 PNGs remain 256x256 transparent production parts, but visible pixels were re-centered with safe margins, alpha edges were softened, rendered material contrast was boosted, and the empty `zombie_crawler_hand_r.png` part was repaired from the polished left-hand mirror.

- `assets/production/contact_sheets/contact_skeletal_parts_polish_2026_07_01.png`
- `assets/production/source_refs/generated/skeletal_parts_polish_spec_2026_07_01.json`
- `tools/polish_skeletal_parts.py`

Remaining final-art concern for parts is now true hand-authored rigging/retopology if the project later ships a bone-driven animation system. For the current raster asset pack and runtime pipeline, these are no longer raw placeholder cutouts.

Update 2026-07-01 non-shooting animation polish pass: the animation QA item has a raster cleanup pass integrated for the non-fused animation sets. `tools/polish_non_shooting_animations.py` processed 902 PNGs under `sprites/animations/characters`, `characters_weaponless`, `zombies`, `bosses`, `pets`, and `weapons`, while explicitly excluding `character_weapon_combos` so the firing-motion pass was preserved.

- `assets/production/contact_sheets/contact_non_shooting_animation_polish_2026_07_01.png`
- `assets/production/source_refs/generated/non_shooting_animation_polish_spec_2026_07_01.json`
- `tools/polish_non_shooting_animations.py`

The main visible cleanup was removing low-alpha full-canvas haze and 102 semi-transparent red rectangular hurt-frame backplates. Remaining animation final-art work is no longer basic cutout/rectangle cleanup; it is true authored animation direction, stronger state variety, and runtime animation tuning where needed.
