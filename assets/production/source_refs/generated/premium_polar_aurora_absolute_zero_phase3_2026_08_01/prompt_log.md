# Polar Aurora / Absolute Zero Phase 3 Prompt Log

Created: 2026-08-01

These files are owner-directed production masters generated for the third and final premium series. Runtime extraction is deterministic through `tools/build_polar_runtime_assets.py` and `tools/build_absolute_zero_vfx_assets.py`.

## Locked visual grammar

- Premium vertical mobile zombie-defense game, realistic 2.5D painted render.
- Matte silver, polar cyan, deep ocean blue and restrained aurora violet.
- Frosted ceramic, transparent crystal and machined metal; never generic fantasy robes.
- Preserve the four locked identities: brawny Vanguard, young Blaze, mature aloof Frost, agile Volt.
- Rear-view battle camera. Complete heads, feet, hands and barrels. Rear hand on trigger, front hand supporting the fore-end, stock seated at shoulder.
- Character firing signature must be a symmetric cyan/violet aurora-ice wing mounted behind the hero with a clean center void.
- No text, watermark, UI, logo, stray weapon, front view, extra limbs or cropped silhouettes in runtime masters.

## Generated masters

1. `polar_aurora_hero_outfit_contact_sheet_v1.png`
   - Four full-body identity-preserving Polar Aurora outfits on one review board.
2. `absolute_zero_equipment_selection_board_v1.png`
   - Three weapon silhouettes plus locked armor, chip and pet direction; the central long cryogenic accelerator was selected.
3. `polar_aurora_ui_world_style_board_v1.png`
   - Native short / medium / long controls, panels, HUD, base treatment and title language without stretched controls.
4. `char_*_polar_absolute_zero_battle_back_sheet_chroma.png`
   - One rear-view sheet per hero with idle and left / center / right true-grip firing poses on chroma.
5. `absolute_zero_vfx_master_chroma.png`
   - Six-cell effect master: Brittle, Shatter, one-generation crystal wave, Aurora field, base counter and max-level awakening.
6. `polar_aurora_character_fire_signature_master_chroma.png`
   - Back-mounted symmetric aurora-ice firing wing with negative space for the hero.

## Rejected-risk corrections baked into production

- No weaponless character plus foreground gun sticker: premium battle uses fused true-grip art.
- No front-facing character in the battlefield: every premium direction master is explicit rear view.
- No forward-mounted firing wing: the effect is below the fused actor z-order.
- No arbitrary projectile heading: the crystal wave declares a source heading and rotates to the real target vector.
- No recursive screen-clearing chain: crystal wave generation is fixed at one.
- No brightness-first UI: glow is restrained so bilingual copy remains primary.

## 2026-08-11 rendered button replacement (V2)

The owner rejected the original runtime buttons because their polygon outlines,
diamond nodes and rails read as unrendered geometric placeholders. The built-in
ImageGen path produced two independent wide chroma masters from the locked Polar
Aurora style board; `remove_chroma_key.py` converted them to reviewed alpha
masters, and `tools/build_polar_runtime_assets.py --buttons-only` preserves the
authored end armor while resizing only a calm center lane.

### Primary master prompt

Create one production-ready premium mobile-game primary button master: exactly
one very wide, symmetric, orthographic frame with deeply rendered cryogenic
silver/titanium armor, machined bevels, translucent ice-crystal inlays, restrained
polar-cyan and aurora-violet energy, a dark ocean-navy uninterrupted text well,
and flat pure `#00FF00` chroma. No text, icon, wireframe geometry, procedural
outline, dots, rail markers, watermark, perspective, extra controls or shadow.

### Secondary master prompt

Create one production-ready premium mobile-game secondary button master: exactly
one very wide, symmetric, orthographic frame with quiet dark polar gunmetal,
frosted titanium end armor, small dark crystal inlays, faint cyan/violet material
reflections and a nearly black uninterrupted text well on flat pure `#00FF00`
chroma. No text, icon, central crest, wireframe geometry, procedural outline,
dots, rail markers, watermark, perspective, extra controls or shadow.

### V2 outputs

- `polar_aurora_button_primary_chroma_v2.png`
- `polar_aurora_button_secondary_chroma_v2.png`
- `polar_aurora_button_primary_transparent_v2.png`
- `polar_aurora_button_secondary_transparent_v2.png`
- `polar_aurora_button_runtime_manifest_v2.json`
- `polar_aurora_button_runtime_contact_sheet_v2.png`
