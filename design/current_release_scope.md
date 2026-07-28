# Current Release Scope

## Included In Current Build

- 99-level playable campaign with scrollable map.
- Four selectable characters.
- Eight upgradeable weapons.
- Armor, chip, and pet collection/equipment systems.
- 20 zombie types and 8 bosses.
- 16 in-run skill cards with icon/text/tag/detail presentation.
- Loadout-aware opening card offers that establish a damage/control/survival identity without adding cards.
- Accurate first-battle control coaching for automatic fire, hold-and-drag manual aim, and double-tap target lock.
- Ten data-driven chapter challenge variants with pre-entry pressure and counter guidance.
- Context-preserving campaign and collection navigation that returns players to the current chapter, current level, or previous browsing position.
- Expandable post-battle report with real damage, defense, control, active-skill, and failure-coaching metrics, plus environment-matched result backgrounds and a compact hero outcome moment.
- Runtime audio hierarchy that briefly ducks music under Boss entry, hero signatures, breach warnings, and result stingers without altering source masters.
- Local progression: level unlocks, stars, gold, XP, weapon upgrades, star-gated collection unlocks.
- Equipment-driven combat stats: character, weapon, armor, chip, and pet effects all apply in battle.
- Settings: separate music/effects/interface volume controls, quality mode, reduced-effects and haptics controls, save reset with confirmation, save backup/restore.
- Menu privacy/support panels.
- iPhone-only Godot/Xcode/TestFlight release pipeline.
- Candidate app icon, launch image, current iPhone screenshot sets, metadata drafts.
- Runtime-captured 22-second iPhone App Preview plus ordered, duplicate-checked 6.5/6.7-inch screenshots.
- Public GitHub Pages privacy policy and support pages on the HTTPS-enforced `blog.gavingao.cn/zombie-fire` site.
- Global runtime UI font is the owner-selected Glow Sans SC / 未来荧黑 Normal Medium v0.93 official binary, with SIL OFL 1.1 notice, provenance, hash gate, and 55-route visual regression coverage.
- Repository-owned work is distributed under Apache License 2.0 via root `LICENSE` and `NOTICE`; third-party components and assets retain their own recorded licenses and provenance.

## Not Included In Current Build

These are intentionally deferred to future versions and should not be treated as incomplete work for the current build:

- iPad-specific layout, screenshots, and release support.
- Final device-specific performance profiling and memory tuning.
- Live ops, analytics, cloud save, IAP, and remote config.
- Store releases for platforms other than iPhone.

## Owner-Approved Next Release Initiative

This is approved future work, not functionality present in Build 38:

- Keep the app free and the existing free campaign/economy intact.
- Add four permanent US$1.99 visual themes.
- Add four permanent US$6.99 Apocalypse Arsenal sets; each includes its matching theme, while owners of that theme see a separate approximately US$4.99 arsenal-upgrade product.
- Premium gear starts at level 1, upgrades with ordinary gold, never consumes stars, and targets 1.52x–1.58x the real maximum output of the matching strongest free build at full level.
- Phase 1 is limited to Neon Tempest plus the complete Thunder Apocalypse weapon/armor/chip/pet set.
- StoreKit, premium assets, premium data and App Store IAP records have not been implemented yet.

The authoritative product and acceptance plan is `design/21_premium_themes_and_apocalypse_arsenal_plan.md`.
The authoritative current-state inventory and Phase 1 work breakdown is `design/22_neon_tempest_thunder_phase1_inventory.md`.

## External Release Dependencies

These cannot be completed inside the repository alone:

- Apple Developer and App Store Connect account access.
- App Store Connect metadata entry.
- Final physical-iPhone QA, audio mix, haptics, thermal and performance sign-off.
