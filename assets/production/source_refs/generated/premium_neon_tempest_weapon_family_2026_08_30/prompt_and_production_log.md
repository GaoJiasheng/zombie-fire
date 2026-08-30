# Neon Tempest free weapon family — prompt and production log

Date: 2026-08-30

## Generation prompt

Create one production material-and-finish reference board for the free Neon Tempest weapon skin family in a premium vertical sci-fi tower-defense game. Use the approved Neon Tempest coating board and representative accepted runtime weapon art as references. Show a coherent material language only: deep graphite-black and blue-black armored metal, continuous recessed luminous conductor channels, cyan-to-electric-violet gradient energy, sparse violet capacitor nodes, restrained cool rim glow, fine circuit etching, matte center surfaces, and crisp beveled metal edges. The skin must read as a free theme-wide coating, clearly premium but visually quieter than an Apocalypse/ultimate weapon. Preserve local value separation and icon legibility at 44–96 px.

Background: flat neutral dark studio slate, easy to isolate. No text, letters, numerals, logos, UI frames, segmented rails, tick marks, dotted or dashed borders, orange/gold/fire, photorealistic scene, characters, hands, perspective distortion, center bloom, clipped objects, new weapon silhouettes, or shape redesign. Center every sample with generous padding; clean high-resolution game-production concept sheet.

## Runtime derivation

- Material master: `neon_tempest_weapon_material_master_v1.png`.
- Geometry source: the accepted Polar Aurora free-theme runtime set, because it already shares the exact canonical icon/handheld/turret silhouettes and alpha masks used by all paid themes.
- Transformation: deterministic per-pixel material remap only. Alpha, canvas size, object placement, and silhouette are byte-for-byte preserved. Low-saturation surfaces become matte blue-black graphite; authored highlight/accent regions become an x-axis cyan-to-violet conductor gradient; the center-value range stays dark for small-icon readability.
- Output inventory: 8 weapon IDs × icon/handheld/turret = 24 runtime textures.
- Prohibited changes: no silhouette edits, muzzle-length edits, attachment additions, crop changes, semantic stat markings, text, logos, or Apocalypse-tier ornamentation.
