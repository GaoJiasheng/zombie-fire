# M1 Visual Asset Progress

> Purpose: resumable checkpoint for M1 visual production.
> Update this file after each generated asset or small batch.

## Current Batch

Batch: `m1_projectiles_vfx_backgrounds_ui`

Goal: Complete remaining projectile, VFX, background, and UI prototypes, then build final contact sheets.

## Resume Rules

1. Check this file first.
2. Check `design/assets/m1_visual_asset_todo.md` for global status.
3. Generated final assets live under `assets/m1_visual/samples/`.
4. Contact sheets live under `assets/m1_visual/contact_sheets/`.
5. Prompts and review notes live under `assets/m1_visual/prompts/`.
6. Chroma-key source files are kept beside final PNGs as `*_chroma.png`.
7. Rejected attempts live under `assets/m1_visual/samples/rejected/`.
8. When context is compacted, continue from the first unchecked item in `Next Items`.

## Locked Style Anchors

- `assets/m1_visual/contact_sheets/contact_m1_samples_overview_v1.png`
- `assets/m1_visual/contact_sheets/contact_units_samples_v2.png`
- `assets/m1_visual/samples/bg_city_ruins.png`
- `assets/m1_visual/contact_sheets/contact_skill_icons_v1.png`
- `assets/m1_visual/contact_sheets/contact_targeting_vfx_v1.png`

## Completed In Current Batch

- [x] `weapon_autocannon_turret.png`
- [x] `weapon_railgun`
- [x] `weapon_scattergun`
- [x] `weapon_flamethrower`
- [x] `weapon_cryocannon`
- [x] `weapon_teslacoil`
- [x] `weapon_venomlauncher`
- [x] `weapon_plasmacannon`
- [x] armor icons
- [x] chip icons
- [x] pet prototypes
- [x] `contact_weapons_equipment.png`
- [x] projectile prototypes
- [x] VFX prototypes
- [x] `contact_vfx.png`
- [x] background prototypes
- [x] UI/icon suite
- [x] `contact_backgrounds.png`
- [x] `contact_ui.png`
- [x] `contact_battle_mock.png`

## Next Items

1. M1 visual asset pack is complete.
2. Next phase can move from prototype assets into implementation/production refinement.

## Completed Batch History

- [x] `m1_playable_missing_assets`
- [x] `m1_characters_zombies_t1_t2`
- [x] `m1_zombies_t3_t4`
- [x] `m1_character_archetype_rework`
- [x] `m1_bosses`
- [x] `m1_skill_icons`

## Latest Review

- Weapon icons/turrets accepted for M1 and reflected by `contact_weapons_v1.png`. Weapon identity is clear; final production may refine autocannon icon framing.
- Armor/chip/pet batch accepted for M1 and reflected by `contact_weapons_equipment.png`. Pet silhouettes are intentionally smaller/supportive so they do not compete with heroes or Bosses.
- Projectile and VFX batch accepted for M1 and reflected by `contact_vfx.png`. VFX are transparent, programmatic prototypes to keep hit centers, element colors, and future frame slicing stable.
- Background and UI batches accepted for M1 and reflected by `contact_backgrounds.png`, `contact_ui.png`, and `contact_battle_mock.png`. UI is programmatic so sizes and states remain reusable in implementation.
- Final asset existence scan checked 105 required files from the remaining equipment/projectile/VFX/background/UI scope and found 0 missing files.
- Skill icon batch accepted for M1 and reflected by `contact_skills.png`. Icons are readable by element/function; final production should separate icon content from shared UI frames.
- Boss batch accepted for M1 and reflected by `contact_bosses.png`. Apex hierarchy is clear; Storm/Void/Apex aura-heavy assets should be split into body + VFX layers in final production.
- `boss_apex_overlord`: accepted for M1. Final-boss tier and phase-core identity are clear; avoid adding more aura noise in final production.
- `boss_necrotitan`: accepted for M1 as regeneration/raise-dead titan. It is visually dense; contact-sheet review must keep Apex clearly above it.
- `boss_void_phantom`: accepted for M1. Void overlord identity and physical-only weak point are readable; final production should split aura/phantom edges into separate layers.
- `boss_plague_mother`: accepted for M1. Poison mother/spawner identity is clear; final production should reduce spike and rot detail density.
- `boss_storm_caller`: accepted for M1. Lightning summoner identity is clear; final production should split electrical arcs into VFX layers.
- `boss_frost_warden`: accepted for M1. Ice armor, freezing control identity, and fire-weak core are readable.
- `boss_inferno_maw`: accepted for M1. Furnace maw, fire immunity identity, and ice-weak hint are readable at Boss scale.
- Character archetype rework accepted. `contact_characters.png` now locks the roster as brawny Vanguard / young Blaze / aloof Frost / electro girl Volt.
- User-selected final roster uses the 22:40 generated Volt candidate, previously over-filtered as too pin-up. Keep it as the canonical `char_volt_prototype.png`.
- `char_blaze`, `char_frost`, and `char_volt` canonical prototype files have been replaced with v2; v1 bulky-male versions are kept under `assets/m1_visual/samples/rejected/`.
- Character batch v1 failed roster diversity: Blaze/Frost/Volt were too close to Vanguard and made the four heroes read as four armored men.
- Revised hero archetype lock: `char_vanguard`=brawny strongman, `char_blaze`=pretty-boy fire engineer, `char_frost`=aloof mature cryo woman, `char_volt`=petite energetic electro girl.
- Previous batch `m1_zombies_t3_t4` is complete and reflected in `design/assets/m1_visual_asset_todo.md`.
- T3/T4 zombie batch accepted for M1 prototype consistency and reflected by `contact_zombies_t3_t4.png`.
- T3/T4 caveat: advanced ordinary zombies have strong elite/Boss energy; final production should reduce gore noise and control scale/FX so Bosses remain clearly higher tier.
- T3/T4 front half accepted so far: juggernaut=knockback-resistant heavy, phantom=evasive phasing, necromancer=summon/support signal, toxic=area contamination, charger=shoulder-rush burst.
- T3/T4 caveat: `zombie_charger` and `zombie_juggernaut` should remain numerically ordinary enemies so they do not blur into Boss territory; reduce red wound detail on charger in final production.
- Previous batch `m1_characters_zombies_t1_t2` is complete and reflected in `design/assets/m1_visual_asset_todo.md`.
- T1/T2 zombie batch accepted for M1. New mechanic reads: spitter=ranged poison, crawler=low profile, armored=durable armor, shielder=front block, hopper=leap pressure.
- T1/T2 caveat: `zombie_armored` has slightly too much red wound detail; reduce gore/detail in final production pass.
- Previous batch `m1_playable_missing_assets` is complete and reflected in `design/assets/m1_visual_asset_todo.md`.
- `zombie_bomber`: accepted for M1. Red core reads clearly as burst threat.
- `zombie_screamer`: accepted for M1. It is a little intense, but the support-threat silhouette is clear.
- `skill_multishot_icon`: accepted. Distinct from split shot.
- `proj_bullet_physical` and `proj_split_mini`: accepted as transparent 256x256 projectile prototypes.
- Basic VFX: accepted for prototype. `vfx_death_dissolve` may need higher alpha/brightness in-engine.

## Notes

- Keep enemies in the accepted v2 mobile-game style, not realistic horror.
- For enemy sprites, use `#ff00ff` chroma key and remove background with:

```bash
python3 /Users/gavin/.codex/skills/.system/imagegen/scripts/remove_chroma_key.py \
  --input <source_chroma.png> \
  --out <final.png> \
  --auto-key border \
  --soft-matte \
  --transparent-threshold 18 \
  --opaque-threshold 210 \
  --despill
```
