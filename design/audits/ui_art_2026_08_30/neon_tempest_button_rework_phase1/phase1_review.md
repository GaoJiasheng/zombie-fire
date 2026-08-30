# Neon Tempest UI art rework · Phase 1 review

Status: candidate direction ready for Owner review; runtime integration blocked by the `b2-complete` tag gate.

## Button result

- Replaced the old visual proposal's segmented side grilles, calibration ticks, repeated modules, diamonds, and luminous center with a single continuous dark-metal bezel and one continuous cyan-to-violet recessed conduit.
- Reduced the center to a deep blue-black label bed with faint circuit grain. At 286×112, the candidate primary central text-safe-zone mean luminance is 20.37/255, below Infernal Dominion primary at 33.09/255.
- Generated review-only coverage for all 36 native runtime sizes and four review states (primary, secondary, ultra, disabled), 144 exact-size PNGs.
- Inspected all sizes on the full native-size sheet and separately inspected the 44–58 px-height group. The 154×44 edge remains continuous and readable as one sculpted frame.

## Same-root-cause sweep

The runtime directory `assets/production/sprites/themes/neon_tempest/ui/` contains only the 36 primary and 36 secondary button textures. There are no Neon Tempest-specific panel, card, or progress-bar raster textures to repair.

Panels, cards, tags, and other surfaces are currently shared UI constructions colored through `tag_palette` / `surface_modulate`; changing their geometry or adding new state-specific routing would require runtime code or scene changes, which are outside this lane. No such change was made.

## Three-theme parity review

The candidate reads as a distinct Neon Tempest family beside Infernal Dominion and Polar Aurora:

- Neon Tempest: black-blue titanium plus continuous cyan→violet conduit.
- Infernal Dominion: forged obsidian/copper with ember seams and heavier end armor.
- Polar Aurora: silver ice-metal with cold blue center and crystalline facets.

All three now use a coherent continuous-frame structure and a calm central label zone without collapsing into the same material identity.

## Owner-visible limitations / aesthetic follow-ups

1. Runtime currently exposes primary and secondary texture filenames only. Disabled reuses secondary plus modulation; an independently routed disabled texture cannot be shipped without prohibited `.gd` work. The disabled candidate is review-only.
2. There is no separately routed `ultra` texture family in the current theme interface. Ultra remains a review hierarchy option unless Owner later authorizes routing work in another code-owning lane.
3. Compact tall controls such as 170×84 necessarily devote more area to end caps and have less text width. The candidate is clean at native scale, but localized long labels still need runtime screenshot validation in Phase 2.
4. The cyan-left / violet-right gradient is intentionally directional. Mirrored layouts will not reverse that energy flow; no change is proposed without an explicit art-direction request.

## Phase 1 artifacts

- `assets/production/source_refs/generated/premium_neon_tempest_button_rework_2026_08_30/`
- `neon_tempest_all_native_sizes_100pct_review.png`
- `neon_tempest_small_44_58px_100pct_review.png`
- `neon_tempest_button_before_after_native_contact_sheet.png`
- `three_theme_button_parity_native_contact_sheet.png`
- `button_center_luminance_metrics.json`

## Deferred until `b2-complete`

- Runtime texture replacement and old-source archival migration.
- Any necessary `themes.json` pointer adjustment (current `button_root` should remain unchanged).
- Godot import and `.import` review.
- Three themes × loadout/store/settings × Chinese/English 1080×1920 screenshots.
- `check_visual_assets`, `check_app_store_assets`, `check_contrast`, and `check_app_store_ui_polish` final green verification against the integrated runtime.
- Explicit-file chained commits.
