# Neon Tempest runtime generation log · 2026-07-28

## Mode

- Generator: built-in `image_gen` skill/tool.
- Model controls: built-in mode; no CLI/API/model override was requested or used.
- Transparency workflow: flat `#00FF00` chroma background, then the skill-provided
  `remove_chroma_key.py` helper with soft matte, spill cleanup, one-pixel contraction,
  and a small edge feather.
- Runtime frame normalization: connected-component extraction of each complete subject,
  common per-character scale, `380×520` transparent canvas, centered X, shared foot line.
- Safety gate: all 44 character frames and four aura frames were checked for non-empty
  alpha and for contact with any output edge. Fixed-grid splitting was rejected after it
  was found to crop the Vanguard hurt pose; the final files use subject-outline extraction.

## Source and runtime outputs

- Static hero source:
  `neon_tempest_runtime_hero_sheet_v1.png`
- Animation sources:
  - `animation_sheets/char_vanguard_runtime_animation_sheet_v1.png`
  - `animation_sheets/char_blaze_runtime_animation_sheet_v1.png`
  - `animation_sheets/char_frost_runtime_animation_sheet_v1.png`
  - `animation_sheets/char_volt_runtime_animation_sheet_v1.png`
- Firing-aura source:
  `neon_tempest_character_fire_aura_sheet_v1.png`
- Final hero portraits:
  `assets/production/sprites/themes/neon_tempest/characters/*.png`
- Final modular battle frames:
  `assets/production/sprites/themes/neon_tempest/characters/animations/<hero>/*.png`
- Final firing aura:
  `assets/production/sprites/themes/neon_tempest/vfx/vfx_neon_tempest_fire_aura_01..04.png`

## Prompt set

### Four-character portrait source

Create a production-ready 2×2 full-body character cutout sheet derived faithfully from
the four approved Neon Tempest outfit concepts, in locked order: Steel Vanguard, Blaze
Striker, Frost Maiden, Arc Maiden. Preserve the four roster identities, make every body
complete and uncropped with generous safe margin, use premium AAA mobile-game raster
materials and readable cyan/violet/magenta emissive clothing details, no weapons baked
into the bodies, and a perfectly flat `#00FF00` background. No labels, UI, logos, or
watermark.

### Shared animation structure

For each locked hero identity, create a production-ready 4-column × 3-row runtime
animation sheet. The approved Neon Tempest portrait is the outfit/identity reference;
the existing weaponless sheet is the rear three-quarter game-camera and footprint
reference. Do not bake a handheld weapon into any frame.

Grid order:

1. Row 1: idle neutral, inhale/shoulder rise, weight shift, return.
2. Row 2: firing anticipation toward the independent gun socket, recoil impulse,
   maximum braced recoil, controlled recovery.
3. Row 3: sharp hit flinch, weight knocked back, recovery, empty fourth cell.

Every occupied cell must contain one complete uncropped character including head, hands,
feet, hair/coat/suit modules, with at least 12% safe margin. Keep identity, anatomy,
materials, scale, lighting, and camera consistent while making motion deltas readable.
No weapon, bullets, muzzle flash, rays, action lines, text, grid, UI, logo, or watermark.
Use a perfectly flat `#00FF00` background.

Hero-specific identity locks:

- Vanguard: mature muscular male; black composite heavy armor; cyan conduits; violet
  secondary circuitry; never a thin cyber-ninja.
- Blaze: young athletic male; high-mobility short tactical jacket and light armor;
  purple-black body; cyan/magenta piping; orange-red only as a fire-role accent.
- Frost: mature aloof athletic woman; silver-black long-line suit and split coat;
  ice-blue plus aurora violet; preserve coat-tail inertia and frost identity.
- Volt: athletic electro woman; deep blue-black high-mobility suit; cyan/magenta
  circuitry; asymmetric attached energy modules; attached coils allowed, no handheld
  weapon.

### Character firing aura

Create a production-ready 2×2 four-frame Neon Tempest firing-aura sheet matching the
approved Storm Caller lightning column's white-hot plasma core, layered cyan glow, fine
violet edge energy, luminous volume, and premium raster finish. The effect appears
around and behind the hero on every shot and must keep the center open.

Frame order:

1. Compact asymmetric shoulder crescent charge with a few short curved ribbons.
2. Two elegant swept plasma wings/ribbons igniting toward the upward firing direction.
3. Strongest recoil peak: asymmetric cyan/magenta plasma ribbons beside the torso,
   shoulder-to-weapon transfer flare, and a few glowing shards.
4. Curved broken streaks, ion sparks, and fading motes.

This is an energy mantle/plasma wing, not a rune or cage. Absolutely no grid, mesh, net,
spiderweb, wireframe, straight cross-hatching, character, weapon, projectile, floor, UI,
text, border, logo, or watermark. Keep at least 15% safe margin and use a perfectly flat
`#00FF00` background.
