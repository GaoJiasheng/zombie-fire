# Neon Tempest Phase 1 Commerce Runtime Asset Log

Created: 2026-07-29
Owner direction: complete the purchasable Neon Tempest / Thunder Apocalypse product with production-ready weapon, armor, chip, pet, combat presentation, and a local purchase flow before StoreKit integration.

## Shared reference and constraints

- Visual reference: `../premium_neon_tempest_phase1a2_2026_07_27/thunder_apocalypse_locked_equipment_set_v1.png`
- Preserve the locked hard-surface post-apocalyptic silhouette, cyan/violet electrical emission, dark gunmetal, orange micro-accents, and premium phone-readable contrast.
- Produce one isolated item per image, orthographic three-quarter game-asset presentation, fully visible with generous crop-safe margin.
- No text, logo, border, UI card, character, scenery, ground plane, or unrelated props.
- Source background: flat chroma green for deterministic local alpha extraction.

## Generated masters

1. `weapon_apocalypse_thunder_master_chroma.png`
   - A compact shortened triple-coil apocalypse arc cannon matching the locked equipment sheet; dominant forward barrel, three luminous Tesla chambers, reinforced grip and rear power block, premium cyan/violet discharge.
2. `armor_apocalypse_conductor_master_chroma.png`
   - A headless conductor torso armor with broad readable shoulder silhouette, central violet reactor, cyan conductive seams, blackened steel plates and restrained orange hardware.
3. `chip_apocalypse_superconductive_master_chroma.png`
   - A square superconductive core module with layered armored frame, triangular violet/cyan energy chamber, readable at small equipment-icon scale.
4. `pet_apocalypse_tempest_master_chroma.png`
   - A floating spherical storm terminal with blue reactor eye, three curved armored vanes, violet lower thruster and contained electrical emission.

The corresponding `*_master.png` files are the locally alpha-extracted masters. Runtime icons and independent weapon/pet layers are deterministic derivatives built by `tools/build_apocalypse_runtime_assets.py`.

## Character/weapon runtime contract

`weapon_apocalypse_thunder` always mounts the true independent Thunder cannon over weaponless hero poses in both default and Neon Tempest themes, so the purchased product can never visually fall back to an old weapon. No redundant fused character/weapon frame matrix is shipped; this saves roughly 21.3 MiB of source PNG payload while keeping the same accepted runtime image.

## Acceptance notes

- Runtime weapon direction is horizontally flipped from the concept master so the muzzle obeys the battle coordinate convention.
- The weapon, pet, armor and chip remain independent item assets and retain stable IDs.
- Full-set overload reuses the owner-approved Storm Caller column/impact production VFX with an edge-safe placement band; no premium effect may be clipped by the portrait viewport.
- Store screenshots, owned-state screenshots, dense-combat screenshots and English/tall-safe-area UI audits are kept under `tmp/neon_commerce_2026_07_29/` and are intentionally not production assets.
