# M1 Visual Sample Prompts

## Global Style Board v1

Saved output:

- `assets/m1_visual/contact_sheets/contact_battle_mock_v1.png`

Prompt:

```text
Use case: stylized-concept
Asset type: M1 global visual style board for a vertical mobile tower-defense shooter game.
Primary request: Create a single polished concept style board showing the unified visual direction for the game Zombie Fire. This is not a marketing poster; it is an art-direction board for production consistency.
Scene/backdrop: A vertical 9:16 post-apocalyptic ruined city battlefield at dusk, readable top spawn area and bottom defense line, smoke and debris but not too dark.
Subject: Include the core M1 sample set in one composition: a steel-grey veteran artillery commander named Vanguard near the bottom defense turret; a rapid-fire autocannon turret facing upward; three ordinary zombies (basic shambler, lean runner, bulky brute) approaching from above; one huge armored boss silhouette/titan in the upper background; three UI skill cards along one side showing split shot, pierce, and slow field; small HUD elements for health bar, target lock reticle, warning marker, and element icons.
Style/medium: Stylized semi-realistic 2.5D mobile game art, looks like a clean 3D render used as 2D sprites; bold readable silhouettes; polished but still production-concept friendly.
Composition/framing: Vertical 1080x1920-style layout, 3/4 top-down side view, all characters facing generally upward/downward along the battlefield axis. Keep gameplay readability clear.
Lighting/mood: Soft global illumination, key light from upper-right, subtle rim light, tense but vivid post-apocalyptic mood.
Color palette: Dark blue-grey ruined city, warning orange UI accents #FF7A3D, steel-white physical element #D9DEE5, fire orange-red #FF5722, ice blue #46C6FF, lightning purple-yellow #C77DFF/#FFE14D, poison green #8BE04E, zombie sickly green #7E9B6E.
Materials/textures: Light grime, rust, worn metal, clean game UI edges, no excessive horror gore.
Text: No readable text, no logos, no watermark.
Constraints: Must look like one coherent game; consistent perspective, lighting, outline language, and UI material. Characters and UI must not overlap incoherently. Avoid photorealism, anime, pixel art, flat vector art, chibi style, dark unreadable background, heavy gore, tiny illegible characters, text labels.
```

Review notes:

- Direction is usable as a first style anchor.
- Keep the same dark blue-grey city base and warning-orange UI language.
- Pull individual sprites slightly more toward mobile 2.5D readability: stronger silhouettes, cleaner shapes, less painterly detail.
- Keep backgrounds readable and avoid heavy atmosphere around gameplay units.

## Accepted Unit / Turret Samples

Saved outputs:

- `assets/m1_visual/samples/char_vanguard_prototype.png`
- `assets/m1_visual/samples/zombie_shambler_prototype.png`
- `assets/m1_visual/samples/zombie_runner_prototype.png`
- `assets/m1_visual/samples/zombie_brute_prototype.png`
- `assets/m1_visual/samples/boss_tank_titan_prototype.png`
- `assets/m1_visual/samples/weapon_autocannon_turret.png`
- `assets/m1_visual/contact_sheets/contact_units_samples_v2.png`
- `assets/m1_visual/contact_sheets/contact_m1_samples_overview_v1.png`

Rejected / replace-later references:

- `assets/m1_visual/samples/rejected/char_vanguard_prototype_v1_too_realistic.png`
- `assets/m1_visual/samples/rejected/zombie_shambler_prototype_v1_too_realistic.png`
- `assets/m1_visual/samples/rejected/zombie_runner_prototype_v1_too_realistic_chroma.png`

Generation notes:

- Chroma-key source color: `#ff00ff`.
- Background removal used:

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

Review notes:

- `char_vanguard` v2 is accepted as the character/mechanical armor anchor.
- `zombie_runner` and `zombie_brute` are the best references for enemy readability.
- `zombie_shambler` v2 is accepted, but future common zombies should stay slightly simpler.
- `boss_tank_titan` is accepted as the first Boss scale/armor reference.
- `weapon_autocannon_turret` is accepted as the starter turret reference.

## UI Card Sample v1

Saved output:

- `assets/m1_visual/contact_sheets/contact_skill_cards_v1.png`

Review notes:

- Card frame material and warning-orange edge language are usable.
- Individual skill icons should be generated separately. The card mockup is not accepted as final icon art.
- Avoid human target silhouettes in `skill_pierce_icon`; use abstract enemies/plates/projectile trails instead.
- `skill_slow_field_icon` should show a defensive base-line slow zone more clearly.

## Background / Skill Icons / VFX Samples

Saved outputs:

- `assets/m1_visual/samples/bg_city_ruins.png`
- `assets/m1_visual/samples/skill_split_shot_icon.png`
- `assets/m1_visual/samples/skill_pierce_icon.png`
- `assets/m1_visual/samples/skill_slow_field_icon.png`
- `assets/m1_visual/contact_sheets/contact_skill_icons_v1.png`
- `assets/m1_visual/contact_sheets/contact_targeting_vfx_v1.png`

Review notes:

- `bg_city_ruins` is accepted for M1 because the central play area is readable and the bottom defense line is clear. Future backgrounds should be pushed slightly less realistic and more stylized.
- The three skill icons are accepted as M1 icon-language anchors. Their baked frames are acceptable for samples, but production icons should likely separate icon content from UI frames.
- `vfx_target_lock` and `vfx_threat_warning` are accepted as clarity anchors.
- `vfx_hit_immune` is accepted as direction, but should become a smaller impact/particle effect in-engine.

## M1 Playable Missing Assets Batch v1

Saved outputs:

- `assets/m1_visual/samples/zombie_bomber_prototype.png`
- `assets/m1_visual/samples/zombie_screamer_prototype.png`
- `assets/m1_visual/samples/skill_multishot_icon.png`
- `assets/m1_visual/samples/proj_bullet_physical.png`
- `assets/m1_visual/samples/proj_split_mini.png`
- `assets/m1_visual/samples/vfx_hit_physical.png`
- `assets/m1_visual/samples/vfx_crit.png`
- `assets/m1_visual/samples/vfx_death_dissolve.png`
- `assets/m1_visual/samples/vfx_gold_pickup.png`
- `assets/m1_visual/contact_sheets/contact_m1_enemies_v1.png`
- `assets/m1_visual/contact_sheets/contact_m1_playable_missing_v1.png`

Review notes:

- `zombie_bomber` and `zombie_screamer` complete the M1 five-enemy set.
- `zombie_screamer` is a little intense; future support enemies should reduce mouth/face detail while keeping the orange sonic read.
- `skill_multishot_icon` is accepted and visually distinct from `skill_split_shot_icon`.
- `proj_bullet_physical` and `proj_split_mini` are transparent 256x256 prototype sprites cut from the same generated projectile sheet.
- Basic VFX sprites were extracted from a concept sheet with brightness-derived alpha. They are acceptable for M1 placeholders, but `vfx_death_dissolve` likely needs brighter particles in-engine.

## M1 Character Batch v1

Saved outputs:

- `assets/m1_visual/samples/char_blaze_prototype.png`
- `assets/m1_visual/samples/char_frost_prototype.png`
- `assets/m1_visual/samples/char_volt_prototype.png`
- `assets/m1_visual/contact_sheets/contact_characters.png`

Prompt pattern:

```text
Reference image role: `char_vanguard_prototype.png` is the style anchor for armor material, proportions, mobile-game polish, lighting, and rendering language.
Create a single full-body prototype sprite for [char_id], a [fire / ice / lightning] hero character for a vertical mobile tower-defense shooter named Zombie Fire.
Style: stylized semi-realistic 2.5D mobile game character art, clean 3D-rendered 2D sprite look, strong readable silhouette, polished but suitable for production prototype.
Pose/framing: full body, standing combat-ready, 3/4 top-down side view, facing slightly toward upper-right, centered with generous padding, no crop, feet visible.
Lighting/color: main key light from upper-right, dark steel/charcoal armor, element accents using the locked palette.
Background for removal: perfectly flat solid #ff00ff chroma-key background only. No floor plane, shadows, gradients, texture, reflections, or environment.
Constraints: no readable text, logo, watermark, gore, photorealistic portrait, anime, chibi, pixel art, or fantasy robe/staff silhouette.
```

Review notes:

- Character batch v1 was rejected for roster diversity. `char_blaze`, `char_frost`, and `char_volt` matched Vanguard's armor/rendering language but read too much like three more armored men.
- V1 files are kept under `assets/m1_visual/samples/rejected/` with `too_bulky_male_roster` names.

## M1 Character Archetype Rework v2

Saved outputs:

- `assets/m1_visual/samples/char_blaze_prototype_v2.png`
- `assets/m1_visual/samples/char_frost_prototype_v2.png`
- `assets/m1_visual/samples/char_volt_prototype_v2.png`
- `assets/m1_visual/contact_sheets/contact_characters.png`

Canonical replacements:

- `assets/m1_visual/samples/char_blaze_prototype.png`
- `assets/m1_visual/samples/char_frost_prototype.png`
- `assets/m1_visual/samples/char_volt_prototype.png`

Rejected outputs:

- `assets/m1_visual/samples/rejected/char_blaze_prototype_v1_too_bulky_male_roster.png`
- `assets/m1_visual/samples/rejected/char_frost_prototype_v1_too_bulky_male_roster.png`
- `assets/m1_visual/samples/rejected/char_volt_prototype_v1_too_bulky_male_roster.png`
- `assets/m1_visual/samples/rejected/char_volt_prototype_v2_initially_rejected_then_selected_2240.png`
- `assets/m1_visual/samples/rejected/char_volt_prototype_v2_not_selected_user_prefers_2240.png`

Prompt pattern:

```text
Create one full-body game sprite for [char_id] in Zombie Fire style: stylized semi-realistic 2.5D mobile hero art, clean 3D-rendered 2D sprite, upper-right key light, strong readable silhouette.
Subject: [locked archetype], with element-colored accents from the art bible. Preserve the team role and body-shape contrast: Vanguard=brawny strongman, Blaze=young adult fire engineer, Frost=tall aloof mature female cryo specialist, Volt=electro girl.
Pose: full body, combat-ready, 3/4 top-down side view, facing slightly upper-right, centered, no crop, feet visible.
Background: perfectly flat solid #ff00ff chroma-key background only; no floor, no shadow, no gradient, no texture.
Avoid: text, logo, watermark, gore, photorealism, anime, chibi, pixel art, fantasy robe, bulky same-body armored roster, underage look, sexualized outfit.
```

Review notes:

- Character archetype rework v2 is accepted for M1.
- `contact_characters.png` now clearly reads as brawny strongman / young fire guy / aloof cryo woman / electro girl.
- User selected the 22:40 generated Volt candidate as the final electro girl. The later 22:42 Volt candidate is kept as `char_volt_prototype_v2_not_selected_user_prefers_2240`.

## M1 Zombies T1/T2 Batch v1

Saved outputs:

- `assets/m1_visual/samples/zombie_spitter_prototype.png`
- `assets/m1_visual/samples/zombie_crawler_prototype.png`
- `assets/m1_visual/samples/zombie_armored_prototype.png`
- `assets/m1_visual/samples/zombie_shielder_prototype.png`
- `assets/m1_visual/samples/zombie_hopper_prototype.png`
- `assets/m1_visual/contact_sheets/contact_zombies_t1_t2.png`

Prompt pattern:

```text
Reference image role: `contact_m1_enemies_v1.png` is the style anchor for zombie body rendering, sickly green skin, torn clothing, perspective, lighting, and mobile-game readability.
Create a single full-body prototype sprite for [zombie_id], a [mechanic role] ordinary zombie for a vertical mobile tower-defense shooter named Zombie Fire.
Style: stylized semi-realistic 2.5D mobile game enemy art, clean 3D-rendered 2D sprite look, readable silhouette, same style as the existing shambler/runner/brute/bomber/screamer sheet.
Pose/framing: full body, 3/4 top-down side view, facing slightly downward/forward toward the player lane, centered with generous padding, no crop.
Lighting/color: main key light from upper-right, sickly green skin, muted torn clothing, mechanic accent color only where needed for readability.
Background for removal: perfectly flat solid #ff00ff chroma-key background only. No floor plane, shadows, gradients, texture, reflections, or environment.
Constraints: no readable text, logo, watermark, heavy gore, photorealism, anime, chibi, or pixel art.
```

Review notes:

- T1/T2 zombie batch is accepted for M1 prototype consistency.
- `zombie_spitter` clearly reads as ranged poison pressure.
- `zombie_crawler` has a strong low-profile silhouette and will not be confused with runner.
- `zombie_armored` reads as durable armor without becoming a Boss, but its wound detail should be reduced in final production.
- `zombie_shielder` is distinct from armored because the protection is concentrated in the front shield.
- `zombie_hopper` reads as leap pressure and remains ordinary-zombie scale.

## M1 Zombies T3/T4 Batch v1

Saved outputs:

- `assets/m1_visual/samples/zombie_juggernaut_prototype.png`
- `assets/m1_visual/samples/zombie_phantom_prototype.png`
- `assets/m1_visual/samples/zombie_necromancer_prototype.png`
- `assets/m1_visual/samples/zombie_toxic_prototype.png`
- `assets/m1_visual/samples/zombie_charger_prototype.png`
- `assets/m1_visual/samples/zombie_regenerator_prototype.png`
- `assets/m1_visual/samples/zombie_splitter_prototype.png`
- `assets/m1_visual/samples/zombie_warden_prototype.png`
- `assets/m1_visual/samples/zombie_mutant_prototype.png`
- `assets/m1_visual/samples/zombie_berserker_prototype.png`
- `assets/m1_visual/contact_sheets/contact_zombies_t3_t4.png`

Prompt pattern:

```text
Create one full-body prototype sprite for [zombie_id], matching the existing Zombie Fire zombie style: stylized semi-realistic 2.5D mobile enemy art, sickly green skin, torn clothing, clean 3D-rendered sprite look, readable silhouette.
Subject: advanced ordinary zombie with one clear mechanic read, such as knockback-resistant heavy, evasive phasing, summon/support signal, area contamination, shoulder-rush burst, regeneration, split-on-death, control/support, mutation pressure, or melee frenzy.
Pose: full body, 3/4 top-down side view, facing slightly downward/forward, centered with generous padding, no crop, feet visible.
Lighting: upper-right key light, subtle rim light, locked element/accent colors only where needed for readability.
Background: perfectly flat solid #ff00ff chroma-key background only, no floor, no shadow, no gradient, no texture.
Avoid: text, logo, watermark, heavy gore, photorealism, anime, chibi, pixel art.
```

Generation notes:

- `zombie_phantom`, `zombie_warden`, `zombie_mutant`, and `zombie_berserker` each needed one retry after a generation failure.
- The retry strategy was to shorten the prompt and keep only subject, pose, lighting, background, and avoid-list.

Review notes:

- T3/T4 zombie batch is accepted for M1 prototype consistency.
- Mechanic reads are clear: juggernaut=heavy pressure, phantom=evasion, necromancer=summon/support, toxic=area contamination, charger=burst charge, regenerator=self-heal, splitter=split-on-death, warden=control/support, mutant=asymmetric mutation, berserker=melee frenzy.
- Caveat for production: several advanced ordinary zombies read close to elite/Boss tier. Reduce gore/detail noise and control scale/FX so Bosses remain clearly above them.

## M1 Boss Batch v1

Saved outputs:

- `assets/m1_visual/samples/boss_inferno_maw_prototype.png`
- `assets/m1_visual/samples/boss_frost_warden_prototype.png`
- `assets/m1_visual/samples/boss_storm_caller_prototype.png`
- `assets/m1_visual/samples/boss_plague_mother_prototype.png`
- `assets/m1_visual/samples/boss_void_phantom_prototype.png`
- `assets/m1_visual/samples/boss_necrotitan_prototype.png`
- `assets/m1_visual/samples/boss_apex_overlord_prototype.png`
- `assets/m1_visual/contact_sheets/contact_bosses.png`

Prompt pattern:

```text
Reference image role: current Zombie Fire Boss prototypes are the Boss scale/style anchors.
Create one full-body Boss prototype sprite for [boss_id], a [element/immunity/mechanic] Boss for a vertical mobile tower-defense shooter.
Subject: huge stylized zombie Boss with one clear mechanic silhouette, one dominant element identity, and one readable weakness hint.
Style: stylized semi-realistic 2.5D mobile game enemy art, clean 3D-rendered 2D sprite, bold silhouette, high readability, polished, not photorealistic horror.
Pose/framing: full body, 3/4 top-down side view, facing slightly downward/forward, centered with generous padding, no crop, feet visible.
Lighting/color: key light from upper-right, subtle rim light, locked element colors only.
Background: perfectly flat solid #ff00ff chroma-key background only, no floor, no shadow, no gradient, no texture.
Avoid: text, logo, watermark, heavy gore, photorealism, anime, chibi, pixel art.
```

Review notes:

- Boss batch is accepted for M1 prototype consistency.
- Mechanic reads are clear: tank titan=physical-immune armored tank, inferno maw=fire furnace, frost warden=ice control, storm caller=lightning summoner, plague mother=poison spawner, void phantom=element-immune phantom, necrotitan=regeneration/raise-dead titan, apex overlord=final multi-phase Boss.
- Caveat for production: Storm Caller, Void Phantom, and Apex Overlord should split aura/electrical/void effects into separate VFX layers. Plague Mother and Necrotitan should reduce gore/detail density slightly for mobile readability.

## M1 Skill Icons Batch v1

Saved outputs:

- `assets/m1_visual/contact_sheets/contact_signature_skill_icons_v1.png`
- `assets/m1_visual/contact_sheets/contact_generic_skill_icons_v1.png`
- `assets/m1_visual/contact_sheets/contact_skills.png`
- `assets/m1_visual/samples/sig_vanguard_railvolley_icon.png`
- `assets/m1_visual/samples/sig_vanguard_overload_icon.png`
- `assets/m1_visual/samples/sig_blaze_napalm_icon.png`
- `assets/m1_visual/samples/sig_blaze_meltdown_icon.png`
- `assets/m1_visual/samples/sig_frost_glacier_icon.png`
- `assets/m1_visual/samples/sig_frost_shatter_icon.png`
- `assets/m1_visual/samples/sig_volt_chain_icon.png`
- `assets/m1_visual/samples/sig_volt_storm_icon.png`
- `assets/m1_visual/samples/skill_ricochet_icon.png`
- `assets/m1_visual/samples/skill_homing_icon.png`
- `assets/m1_visual/samples/skill_salvo_icon.png`
- `assets/m1_visual/samples/skill_critical_icon.png`
- `assets/m1_visual/samples/skill_charge_shot_icon.png`
- `assets/m1_visual/samples/skill_incendiary_icon.png`
- `assets/m1_visual/samples/skill_cryo_icon.png`
- `assets/m1_visual/samples/skill_tesla_icon.png`
- `assets/m1_visual/samples/skill_venom_icon.png`
- `assets/m1_visual/samples/skill_barrier_icon.png`
- `assets/m1_visual/samples/skill_gold_rush_icon.png`
- `assets/m1_visual/samples/skill_recycle_icon.png`

Generation notes:

- Signature skills were generated as one 4x2 sheet, then cropped into 512x512 single icons.
- Generic skills were generated as one 4x3 sheet, then cropped into 512x512 single icons.

Review notes:

- Skill icon batch is accepted for M1.
- Element colors and gameplay functions are readable at contact-sheet size.
- Final production should separate reusable UI frame layers from icon content instead of baking every frame into every icon.

## M1 Weapon Batch v1

Saved outputs:

- `assets/m1_visual/contact_sheets/contact_weapon_icons_v1.png`
- `assets/m1_visual/contact_sheets/contact_weapon_turrets_v1_chroma.png`
- `assets/m1_visual/contact_sheets/contact_weapons_v1.png`
- `assets/m1_visual/samples/weapon_autocannon_icon.png`
- `assets/m1_visual/samples/weapon_railgun_icon.png`
- `assets/m1_visual/samples/weapon_scattergun_icon.png`
- `assets/m1_visual/samples/weapon_flamethrower_icon.png`
- `assets/m1_visual/samples/weapon_cryocannon_icon.png`
- `assets/m1_visual/samples/weapon_teslacoil_icon.png`
- `assets/m1_visual/samples/weapon_venomlauncher_icon.png`
- `assets/m1_visual/samples/weapon_plasmacannon_icon.png`
- `assets/m1_visual/samples/weapon_railgun_turret.png`
- `assets/m1_visual/samples/weapon_scattergun_turret.png`
- `assets/m1_visual/samples/weapon_flamethrower_turret.png`
- `assets/m1_visual/samples/weapon_cryocannon_turret.png`
- `assets/m1_visual/samples/weapon_teslacoil_turret.png`
- `assets/m1_visual/samples/weapon_venomlauncher_turret.png`
- `assets/m1_visual/samples/weapon_plasmacannon_turret.png`

Generation notes:

- Weapon icons were generated as one 4x2 sheet, then cropped to 512x512 icons.
- Weapon turrets were generated as one 4x2 chroma-key sheet, then cropped and background-removed into individual transparent turret prototypes.
- `weapon_autocannon_icon.png` was derived from the accepted autocannon turret so every weapon has both icon and turret assets.

Review notes:

- Weapon batch is accepted for M1.
- Icon/turret pairings are readable across railgun, scattergun, flamethrower, cryocannon, teslacoil, venomlauncher, and plasmacannon.
- Final production may refine autocannon icon framing and split turret bases/barrels for rigging.

## M1 Equipment / Pets / Projectile / VFX / Background / UI Batch v1

Saved outputs:

- `assets/m1_visual/contact_sheets/contact_equipment_icons_v1.png`
- `assets/m1_visual/contact_sheets/contact_pets_v1.png`
- `assets/m1_visual/contact_sheets/contact_weapons_equipment.png`
- `assets/m1_visual/contact_sheets/contact_vfx.png`
- `assets/m1_visual/contact_sheets/contact_backgrounds.png`
- `assets/m1_visual/contact_sheets/contact_ui.png`
- `assets/m1_visual/contact_sheets/contact_battle_mock.png`

Generation notes:

- Armor and chip icons were generated as one 4x4 sheet, then cropped into individual 512x512 icons.
- Pet prototypes were generated as one 3x2 chroma-key sheet, background-removed into transparent prototype sprites, then used to derive portraits and icons.
- Projectile and VFX prototypes were programmatically drawn as transparent PNGs to keep hit centers, alpha, and future frame slicing stable.
- Backgrounds were generated as five 16:9 scene prototypes: subway, military, biolab, main menu, and level map.
- UI assets were programmatically drawn so frame sizes, bar states, cooldown overlays, and icon language remain reusable in implementation.

Review notes:

- Equipment and pet batch is accepted for M1.
- Projectile and VFX batch is accepted for M1; final production can replace single-frame VFX with sequence frames without changing element language.
- Background batch is accepted for M1; combat backgrounds keep central lanes open while menu/map backgrounds leave UI space.
- UI batch is accepted for M1 prototype use; final UI implementation should rebuild these as layered components where practical.
