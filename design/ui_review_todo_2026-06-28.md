# UI Review Todo · 2026-06-28

> Source: manual review of routed 1080x1920 screenshots for menu, map, loadout, collection, battle, and result after Stage 1 P3.8. Goal is not another layout-only patch; the next UI pass should make the screens feel like one mature online mobile game.

## Snapshot Findings

| Screen | Current state | Main issue |
| --- | --- | --- |
| Menu | Background and title are readable. | CTA buttons still use plain saturated blue and feel disconnected from the later dark-metal/gold/cyan palette. |
| Map | Icon-forward top navigation is better; level list is functional. | Level cards are still too blue, too repetitive, and action text/stars compete for attention. Scrollbar overlaps the card edge visually. |
| Loadout | Best current screen: clear hero/weapon/equipment/summary hierarchy. | Empty vertical space is high; top-left back button and bottom CTA still look like old blue prototype components. |
| Collection | Text is readable and click flow is consistent. | Rows still look like old blue slabs with a large unused right-side block; item cards do not yet feel premium. |
| Battle | Combat field is clean and not overly blocked. | HP/wave HUD is too close to the top and uses thin bar labels; left strategy/pause controls are large; active skill button is text-first instead of icon-first. |
| Result | Structure is clear and much better than before. | Button hierarchy still uses the old blue/green/grey palette and could be tightened into a single premium action stack. |

## P0 · Visual System Unification

- [ ] Build shared button styles in `UiKit` for `primary_gold`, `primary_cyan`, `secondary_dark`, `danger_dark`, and `disabled`, then replace remaining saturated-blue prototype buttons on Menu, Loadout, Result, and Pause.
- [ ] Standardize screen headers: title frame, subtitle, divider line, and top-left back action should share one component. Menu can stay more heroic, but Map/Loadout/Collection/Result should use the same measured header language.
- [ ] Reduce default bright blue cards. Use dark translucent metal panels as the base, with blue only as secondary accent and gold/orange for selected/deploy-ready states.
- [ ] Define fixed spacing tokens for 1080x1920: outer margin, section gap, card gap, icon frame size, row height, and bottom safe-action zone. Apply them across Map, Loadout, Collection, Result.

## P1 · Screen-Specific Polish

- [ ] Menu: replace the two plain rectangular buttons with premium stacked CTA plates; add small icon badges inside the buttons instead of text-only commands.
- [ ] Map: rebuild level rows into darker campaign cards with a left number plate, middle level name/status chips, and a single right-side deploy/locked affordance. Stars should become a compact rating strip, not a competing action cluster.
- [ ] Map: move the scrollbar outside the level-card visual rail or make it a thin cyber track; it should not appear pasted over card borders.
- [ ] Loadout: keep the current three-section structure, but remove the large dead vertical gap between summary and CTA. The summary should sit closer to equipment, and the CTA should own a dedicated bottom action band.
- [ ] Loadout: restyle the back button and battle CTA using the new shared button palette; current blue button is the main remaining prototype signal on this screen.
- [ ] Collection: replace blue slab rows with compact item cards: icon frame left, title/level/tags center, equipped/locked/upgrade state right. Remove the large empty right-side blue filler block.
- [ ] Collection detail modals: make attribute/passive/active sections use framed cards with icons and color-coded section headers; avoid long raw text blocks.
- [ ] Battle HUD: rebuild top HUD into a compact status deck: HP as a strong red capsule, wave as a smaller progress rail, labels outside the bar rather than overlaid on thin fills.
- [ ] Battle HUD: shrink pause and strategy controls; make strategy an icon-first chip with a short label so the left side does not dominate the battlefield.
- [ ] Battle active skill: make the active skill button icon-first with cooldown overlay/radial and a small two-line label. Keep it bottom-right but visually align with the bottom HUD rail.
- [ ] Result: convert the action buttons into a clear premium hierarchy: next level as main gold/cyan CTA, replay/strengthen as secondary, return map as dark tertiary.

## P2 · Interaction Consistency

- [ ] All item-list interactions should follow the same rule: tap opens detail; equip/upgrade actions live in detail or in a clearly marked action chip. No screen should mix direct equip and detail-first behavior.
- [ ] Long-press explanations should be visually consistent for skill cards, equipment, and battle HUD skill slots.
- [ ] Use icons for repeated concepts: battle power, weakness, gold, XP, equipped, locked, upgrade available. Text should explain specifics, not carry every state alone.
- [ ] Add pressed/hover/down states to Map cards, Loadout equipment frames, Collection rows, and Result buttons so desktop and mobile feedback match.

## P2 · Automated Visual Guardrails

- [ ] Extend `tools/check_visual_screens.py` with per-screen safe zones: top HUD, bottom CTA, scroll area, and battle lane should reject obvious overlap.
- [ ] Add a simple color-dominance check that fails if a screen is mostly saturated blue panels outside allowed components.
- [ ] Add image-centering checks for repeated icon frames where the selected art should sit inside a known rect: Loadout hero/weapon/equipment, Map nav tiles, Collection row icons.
- [ ] Save the UI review screenshot set under a stable artifact directory when running review mode, so future passes can compare visual diffs instead of relying on temporary folders.

## Acceptance Bar For Next UI Pass

- Menu, Map, Loadout, Collection, Battle, and Result must look like the same product family at a glance.
- No large bright-blue prototype slabs remain except where intentionally used as a secondary accent.
- Every repeated card/icon/control must have stable dimensions and centered content.
- Battle HUD must preserve battlefield visibility and make HP, wave, XP, active skill, and selected skills readable without competing with zombies.
- Collection and detail pages must feel like structured equipment/character management, not raw lists of text.
