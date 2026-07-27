# Combat VFX Semantic Audit — 2026-07-26

## Outcome

Pass after two repair-and-recapture loops.

The acceptance gate now checks both bitmap safety and gameplay meaning. A frame is not accepted merely because it is transparent and uncropped: its source, visible direction, travel path, target/area center and impact must agree with the mechanic shown on screen.

## Permanent acceptance layers

1. **Sequence integrity** — exactly one manifest per sequence, valid ID/FPS, existing referenced frames, stable dimensions, non-empty output and real frame-to-frame variation.
2. **Canvas safety** — at least 7.5% transparent clearance unless an explicitly documented graphic-band exception applies.
3. **Atlas-crop rejection** — straight alpha boundaries characteristic of a pre-cropped reference-sheet cell fail even if somebody later adds transparent padding around that cell.
4. **Direction contract** — authored source-forward angles rotate onto actual movement, projectile velocity or target vectors. Directional media may not receive random spin.
5. **Cause-and-effect continuity** — cast origin, travel path and impact/area center must form a readable chain.
6. **Mechanic identity** — actions with different gameplay meaning cannot collapse to one identical silhouette.
7. **Runtime proof** — source checks are followed by real Godot captures at standard and tall-phone viewports; imported-cache output, HUD hierarchy and safe areas are reviewed from the rendered frame.

The machine-readable source of truth is `design/assets/combat_vfx_semantic_contracts.json`; enforcement is `tools/check_combat_vfx_semantics.py`, now included in the Release Candidate gate.

## Full automated scope

| Area | Accepted scope |
| --- | ---: |
| VFX sequence directories | 83 |
| Referenced non-empty VFX frames | 710 |
| Directional enemy sequence contracts | 5 |
| Directional projectile textures | 11 |
| Boss base-attack profiles | 8 |
| Character active skills | 4 |
| Card skill casts | 16 |
| Character/weapon attack animation sequences | 96 |
| `res://` references | 349 |
| Runtime full-interface screenshot routes | 71 |

## Findings and repairs

### 1. Direction contradicted movement

`runner_dash`, `charge` and `phase_shift` were authored facing screen-right while enemies advance toward the bottom base. `leap_strike` was authored on a 45-degree diagonal. Runtime now maps each known source-forward angle onto the actual travel vector. `ranged_spit` was added to the same contract when its replacement became a directional venom wedge.

The regression test requires exact screen-down rotation for all five sequences and verifies that radial/non-directional VFX remain unaffected.

### 2. Six effects were pre-cropped before padding

The rejected sequences were:

- `vfx_enemy_skill_corrosion`
- `vfx_enemy_skill_ranged_spit`
- `vfx_enemy_skill_toxic_cloud`
- `vfx_enemy_skill_regen`
- `vfx_skill_cast_venom`
- `vfx_death_dissolve`

Their old mid-frames contained long straight alpha edges from the original sheet cell. The repair derives them from already accepted premium production sequences and contains the source without cropping. IDs, paths, frame counts, FPS and gameplay references are unchanged.

### 3. Two projectile images were visually below the production bar

`proj_acid_spit.png` and `proj_split_mini.png` were flat primitive silhouettes and also failed the projectile-margin contract. They now use premium production projectile derivatives, preserve the expected +X source-forward direction and continue to rotate from actual flight velocity at runtime.

### 4. First safe repair made poison actions indistinguishable

The first pass removed cropping but made corrosion, ranged spit and toxic cloud read as the same green burst. Runtime review rejected that result.

The final vocabulary is:

- **Corrosion** — compact radial impact burst.
- **Ranged spit** — narrow directional venom launch.
- **Toxic cloud** — grounded persistent area burst.
- **Regeneration** — vertical healing column.

`enemy_poison_actions` is now a permanent visual-distinctness group in the semantic contract.

### 5. Godot initially rendered stale imported textures

The first post-repair screenshot still exposed the old rectangular poison image and old projectile despite the source PNGs passing. The editor import cache was force-refreshed, then all affected routes were captured again. The final captures contain no old rectangular plate.

## Runtime review evidence

Focused re-capture:

- 11 screenshots at `1080×1920`
- 1 screenshot at `1080×2348`
- direction: runner dash, charge, leap and Void Phantom phase shift
- crop/identity: toxic cloud, ranged spit, corrosion, regeneration and venom cast
- projectile flight: acid spit and split-mini
- HUD/safe-area review at peak frames

Evidence:

- `tmp/combat_vfx_semantic_audit_2026_07_26/runtime_contact_sheet.png`
- `assets/production/contact_sheets/contact_combat_vfx_semantic_repair_2026_07_26.png`
- `assets/production/source_refs/generated/combat_vfx_semantic_repair_2026_07_26/manifest.json`

The unaffected boss attacks, boss mechanics, character actives, weapon paths, hit states, death states and card casts remain covered by the 83-route specialty matrix from the same production baseline. The complete 71-route interface matrix was also regenerated by the final Release Candidate run.

## Verification

All passed:

- `python3 tools/validate_asset_pack.py`
- `python3 tools/validate_data.py`
- `python3 tools/check_res_refs.py`
- `python3 tools/check_level_pressure.py`
- `python3 tools/simulate_card_director.py`
- `python3 tools/check_visual_assets.py`
- `python3 tools/check_combat_vfx_safe_margins.py`
- `python3 tools/check_combat_vfx_semantics.py`
- `python3 tools/check_attack_animation_motion.py`
- `/opt/homebrew/bin/godot --headless --path . --quit`
- `/opt/homebrew/bin/godot --headless --path . --script res://tools/m1_smoke_test.gd`
- `python3 tools/check_release_candidate.py` — 36 checks, including 71 routed screenshots

## Remaining device-only boundary

This audit proves source assets, imported desktop runtime, standard/tall layout and deterministic gameplay presentation. It does not replace a final physical-iPhone check for OLED brightness, thermal throttling, touch obstruction or perceived effect density during a long play session; that remains in the Owner device checklist.
