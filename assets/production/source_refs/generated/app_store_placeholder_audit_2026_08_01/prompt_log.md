# App Store Runtime Placeholder Audit · Rendered Master Log

- Date: 2026-08-01
- Tool: built-in `image_gen`
- Scope: replace the final generic runtime VFX that still read as procedural geometry after reviewing all 101 sequence peak frames.
- Runtime rule: preserve sequence IDs and event timing; rendered art may not change damage, collision, target selection, level pressure or economy.

## Enemy enrage master

- Files: `enemy_enrage_chroma_v1.png`, `enemy_enrage_transparent_v1.png`
- Final prompt: Create one isolated premium mobile-game enemy ENRAGE aura, viewed from a top-down three-quarter combat camera. A brutal molten red-orange pressure corona wraps tightly around one zombie-sized actor: fractured volcanic energy shell, asymmetric hooked flame claws rising around the shoulders, dense white-hot core sparks, embers, smoke wisps, layered heat refraction and a grounded circular pressure burst. Keep the actor center readable and open enough for a zombie silhouette. This is a centered body-attached state effect, not a projectile and not a directional flamethrower. Rich dimensional raster rendering, forged metal and molten mineral detail, AAA dark industrial zombie-defense style. Entire effect inside the central 70 percent with generous empty border and no edge contact. Flat pure #00FF00 chroma-key background. No character, no UI, no text, no icon frame, no simple starburst, no thin vector circles, no ruler-straight lines, no diagram, no repeated copies.
- Integration: twelve-frame body-safe pulse; static fallback uses its peak; green spill is neutralized without turning the effect into a sideways fire jet.

## Level-up ascension master

- Files: `levelup_ascension_chroma_v1.png`, `levelup_ascension_transparent_v1.png`
- Final prompt: Create one isolated premium mobile-game LEVEL UP ascension effect for a rear-view hero in a vertical zombie-defense battlefield. A coherent champagne-gold and cyan energy column rises from a luminous ground crown, with layered volumetric light, a spiraling gold ribbon, cyan plasma arcs, white-hot sparks, engraved energy fragments and a decisive crown-shaped flare at the top. Keep a readable open actor center so the hero remains visible while the energy surrounds the body. The whole event must read as one upward cause-and-effect column, not two disconnected bursts. Deep cinematic raster rendering, dimensional glow, restrained bloom, dark industrial sci-fi quality. Entire effect inside the central 70 percent with generous transparent safety border. Flat pure #FF00FF chroma-key background. No character, no UI, no text, no flat magic circle, no simple vector rays, no diagram, no cropped particles, no repeated copies.
- Integration: twelve-frame rise / peak / release; static fallback uses the peak; the former hard-edge exception has been removed and all frames pass normal alpha-margin validation.

## Acceptance

- `app_store_vfx_replacements_contact_sheet.png` shows both peak frames on a neutral dark field.
- `app_store_vfx_replacements_manifest.json` records every frame, fallback and verification asset hash.
- Real Godot captures place Enrage on a stationary brute and Level Up around the 1.50x hero so anchoring, layer order and open-center readability are reviewed at phone scale.
