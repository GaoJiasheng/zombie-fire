# P0 global consistency + warzone map — Phase 1 review

**Status: PHASE 1 READY FOR OWNER REVIEW; runtime untouched; `b2-complete` tag absent.**

## Proposed decisions

| Item | Current inconsistency | Proposed final rule / value |
|---|---|---|
| Store name | Page shell says `终焉军械库`, while runtime fallbacks still say `精品军械库`; series can replace the page title dynamically | Global destination/page title: `终焉军械库` / `Apocalypse Arsenal`. Keep `霓虹/炼狱/极地/鎏金军械库` only as series/catalog labels, not the global page title. |
| Store empty state | `精品军械库尚未解密` / `Premium Arsenal Encrypted` | `终焉军械库尚未解密` / `Apocalypse Arsenal Encrypted`. |
| Button hierarchy | Main-menu actions are equal size; default chrome mixes copper and cyan | Global semantic rule: **action/confirm/primary CTA = copper-gold**; **navigation/back/settings/catalog entry = steel-cyan**. Start becomes 760×132 with a restrained low-amplitude glow; Settings and Arsenal remain 600×100 secondary controls. |
| Upgrade copy | Character/equipment hints use `下级` / `Next Lv.` | `下一级` / `Next Level` everywhere, including compound hints. |
| Empty quick slot | Map quick row uses red `未装` status text | No text badge. Use a dim empty-slot ghost plus a steel-cyan `+`, matching the loadout language. |

Owner copy approval is required before Phase 2 edits. Recommended exact replacement families:

- `精品军械库` → `终焉军械库`; `Premium Arsenal` → `Apocalypse Arsenal` where the string denotes the global destination.
- `精品军械库尚未解密` → `终焉军械库尚未解密`; `Premium Arsenal Encrypted` → `Apocalypse Arsenal Encrypted`.
- `下级` → `下一级`; `Next Lv.` → `Next Level` in the base label and every composed collection/gameplay hint.
- Do not rewrite `premium_sets.json` series titles; those remain catalog identity labels.

## Visual proposal and assets

- [Main-menu before/after contact sheet](./main_menu_before_after_contact_sheet.png): Start is one size larger and copper-gold; Settings/Arsenal are steel-cyan navigation controls. The glow shown is the intended peak state, not a runtime animation.
- [Warzone-map before/after contact sheet](./warzone_map_before_after_contact_sheet.png): independent Endless Horde card, compact one-line zone summaries, ten-segment progress rail, star counter, icon boss milestones, and ghost-plus quick slots.
- [Ten-zone thumbnail sheet](./warzone_thumbnail_10_contact_sheet.png): uniform crop and theme-color rail for all ten existing environments.
- [Boss badge 48/64 px review](./boss_badges_48_64px_review.png): minor and major threat levels remain distinct at native phone scale.
- [Asset validation JSON](./phase1_asset_validation.json): dimensions, color modes, hashes, and phase-only status.

Source candidates live under `assets/production/source_refs/generated/premium_global_ui_map_consistency_phase1_2026_08_30/`. Generated/source-reference files are intentionally ignored by the normal Git add path and would require explicit-file handling later.

## Phase 2 implementation boundaries

After the mainline creates `b2-complete`, Phase 2 may explicitly integrate approved textures/layout/copy and then produce real screenshots. The menu breathing effect and any animated Endless Horde loop require runtime behavior; this art lane will not modify `.gd` without a fresh, explicit authorization that supersedes the current red line.

Required final checks after integration:

1. Confirm no frontline fixed-fps Godot probe is running before batch import/screenshots.
2. Run the requested visual, App Store, contrast, UI-polish, localization, and release-string checks.
3. Capture three themes × six screens at 1080×1920 and build the final contact sheet.
4. Verify return/navigation controls are steel-cyan and action/confirm CTAs copper-gold on every captured screen.
5. Commit by explicit file list only; never stage balance data, campaign evidence, or `tools/`.

## Blocker outside Tasks 4–5

Task 6 refers to “the table, items 9–17”, but that table is not present in the supplied brief or discoverable as a uniquely matching project list. No Task 6 proposal was invented. Owner must provide or point to the exact 9–17 list before that work can be scoped into independent review/commit units.
