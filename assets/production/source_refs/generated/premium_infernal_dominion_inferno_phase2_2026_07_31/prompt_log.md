# Infernal Dominion / Inferno Apocalypse · Step 1 Prototype Prompt Log

- Date: 2026-07-31
- Mode: OpenAI built-in `imagegen`, new-generation with local accepted references
- Scope: visual prototypes only; no runtime sprites, prices, entitlements, or combat values are implemented by these images
- Reference rule: accepted Neon Tempest / Thunder Apocalypse images constrain identity, composition, and quality only. They are not edit targets and their neon styling must not be copied.

## 1. Four-hero outfit contact sheet

Reference: `../premium_neon_tempest_phase1a_2026_07_27/neon_tempest_hero_outfit_contact_sheet_v1.png`

Prompt:

> Create a strict 2×2 full-body contact sheet for the four locked Zombie Fire heroes. Steel Vanguard is a broad mature heavy gunner in practical charcoal heat armor, insulated shoulders, copper coolant tubes and a dark-red furnace core. Blaze Striker is a young lean fire specialist in a lightweight heat suit with a compact molten chest core, forearm conduits and ember cloth tails. Frost Maiden is an aloof mature silver-haired woman in layered silver-gray cryogenic insulation integrated with black-red thermal protection; preserve ice-blue functional lights. Arc Maiden is a young athletic electro woman in light insulated carbon armor, a red-gold frame and clearly visible purple-blue conductive channels. Use grounded AAA industrial sci-fi realism, charred black, oxblood, molten orange, copper and small off-white ceramic details. Keep every head, hand, tail and foot visible with generous padding. No weapons, text, logo, demons, horns, generic lava armor, identity drift, or effects hiding anatomy.

Output: `infernal_dominion_hero_outfit_contact_sheet_v1.png`

## 2. Eight free-weapon coating board

Reference: `../premium_neon_tempest_phase1a2_2026_07_27/neon_tempest_free_weapon_coatings_v2.png`

Prompt:

> Create a precise 2×4 contact sheet of exactly eight complete side-profile weapons: rotary autocannon, tank-fed flamethrower, insulated cryocannon, coil-ring tesla rifle, toxic-reservoir venom launcher, long linear railgun, broad twin-barrel scattergun, and large plasma-chamber cannon. Share a charred-black shell, oxblood accents, heat-bloomed copper and restrained molten seams while preserving each weapon's functional color: physical brass, fire orange, ice cyan, lightning blue-violet, poison acid green, rail white-cyan, scatter gold, plasma magenta. Every class must keep a different, instantly readable silhouette. Show full stock and muzzle. No labels, text, logos, flat-red recolor, fantasy weapons, duplicated rifles, or fire hiding silhouettes.

Output: `infernal_dominion_free_weapon_coatings_v1.png`

## 3. Inferno equipment selection board

Reference: `../premium_neon_tempest_phase1a2_2026_07_27/thunder_apocalypse_locked_equipment_set_v1.png`

Prompt:

> Create an exact 2×3 premium armory board. The top row contains three mechanically distinct Infernal Plasma Projector candidates: A, a compact twin-cell projector around a central ignition ring and short ceramic nozzle; B, a long axial siege projector with one transparent plasma chamber, articulated fins and narrow magnetic nozzle; C, an asymmetric industrial projector with underslung tank, offset copper exchanger, rotating ignition halo and wide vented muzzle. The bottom row contains Molten Regenerator Armor with layered charred plates and circulation tubes, a square Stellar Combustion Core with a captive star under thick glass, and an elegant mechanical Ember Phoenix with swept metal wings and molten edges. All six subjects are fully visible. Use grounded AAA industrial sci-fi, not fantasy. No text, horns, skulls, biological bird, cropped wings/barrels, free-flamethrower recolor, or Thunder geometry copy.

Output: `inferno_apocalypse_equipment_selection_board_v1.png`

## 4. UI, logo, world, and material board

Reference: `../premium_neon_tempest_phase1a_2026_07_27/neon_tempest_ui_world_style_board_v1.png`

Prompt:

> Create a coherent 2×2 Infernal Dominion style board. Top-left: one readable ZOMBIE FIRE forged-metal title crest and compact flame-shield emblem. Top-right: a dark representative game panel with portrait frame, weapon card, resource capsule, circular skill slots, and independently modeled short, standard and long blank buttons; button centers stay dark and molten light stays on rims. Bottom-left: a tall ruined-road battlefield and fixed bottom base made from charred blast walls, insulated furnaces, copper conduits and narrow molten channels while the central lane remains dark. Bottom-right: production material/color samples for carbonized steel, heat-bloomed copper, oxblood ceramic, furnace glass, off-white insulation, embers and a small badge. Use premium functional AAA industrial sci-fi. No text except ZOMBIE FIRE, no stretched controls, bright neon rainbow, overexposed copy regions, fantasy skulls, giant flame veil, crop, or watermark.

Output: `infernal_dominion_ui_world_style_board_v1.png`

## 5. Vertical battle composite

References: accepted Neon battle composite plus outputs 1 and 3 above.

Prompt:

> Create a polished tall 9:19.5 battle composite. A fully visible Blaze Striker stands above the fixed bottom base, naturally holding Candidate B, the long axial Infernal Plasma Projector, with both hands. A mechanical Ember Phoenix flies beside him. Distinct zombies descend from the top on a dark central road framed by restrained furnace architecture. A narrow layered white-hot plasma stream begins exactly at the muzzle and ends exactly on a priority enemy. One nearby zombie has body-attached persistent ember fissures; another has a contained maximum-combustion halo; a defeated target sends one generation of short propagation trails only to nearby enemies. Include clean nonverbal HUD shapes with safe margins. Keep hero, grip, muzzle, phoenix and enemies readable. No broad flamethrower cone, disconnected or chest-origin beam, crop, duplicated enemies, red-on-red loss, fake text, or full-screen bloom.

Output: `infernal_dominion_battle_composite_v1.png`

## 6. Ten-panel VFX storyboard

References: accepted Thunder storyboard plus outputs 3 and 5 above.

Prompt:

> Create exactly ten panels in a clean 2×5 grid on the same dark ruined-road crop: (1) compact muzzle pre-ignition ring; (2) narrow stable off-white/orange plasma stream; (3) directional torso hit crown; (4) readable full zombie with body-attached persistent burn; (5) maximum combustion with contained halo, brighter fissures and five heat nodes; (6) compact centered combustion burst; (7) defeated target sending one generation of two short curved ember trails to two nearby zombies; (8) mechanical Ember Phoenix diagonal flyby with a controlled feather trail; (9) fixed base absorbing an impact and emitting a shield-shaped thermal counter pulse; (10) full-level hero/projector awakening with star-core ring, heat-fin flare and phoenix-wing motif while direction remains readable. Every effect stays inside its panel and attaches to its source/target. No text, lightning, generic repeated explosions, detached particles, wrong-way trails, opaque smoke, fantasy magic circles, crop, or watermark.

Output: `inferno_apocalypse_vfx_storyboard_v1.png`

## 7. Runtime masters and deterministic derivatives

- Mode: OpenAI built-in `imagegen` for accepted raster masters, followed by transparent-background cleanup and deterministic Python derivatives through `tools/build_infernal_runtime_assets.py`.
- Front-facing alpha masters: `char_{vanguard,blaze,frost,volt}_infernal_alpha.png`. These remain presentation sources for portraits and shop / collection surfaces; they are not battle poses.
- Equipment masters: `weapon_apocalypse_inferno_master.png`, `armor_apocalypse_molten_master.png`, `chip_apocalypse_stellar_master.png`, `pet_apocalypse_phoenix_master.png`.
- Theme firing master: `infernal_character_fire_signature_master.png`; runtime derivatives are restrained dark-copper mechanical wings with molten-orange seams and a white-hot muzzle core, not a yellow-green holy-light aura.
- Deterministic output manifest: `infernal_runtime_manifest_v1.json` (168 runtime files). Contact sheet: `infernal_runtime_contact_sheet_v1.png`.

## 8. Rear-view battle correction and true-grip contract

Owner review correctly identified that the firing model must face away from the viewer in a fixed-bottom vertical defense game. The earlier front-facing triptychs remain presentation-only. Four new four-panel green-screen sheets were generated with the exact locked hero identities and the exact long axial Infernal Plasma Projector:

- `char_vanguard_infernal_battle_back_sheet_chroma.png` → `char_vanguard_infernal_battle_back_sheet.png`
- `char_blaze_infernal_battle_back_sheet_chroma.png` → `char_blaze_infernal_battle_back_sheet.png`
- `char_frost_infernal_battle_back_sheet_chroma.png` → `char_frost_infernal_battle_back_sheet.png`
- `char_volt_infernal_battle_back_sheet_chroma.png` → `char_volt_infernal_battle_back_sheet.png`

Shared prompt contract:

> Create one strict four-panel full-body sprite sheet for the named locked Zombie Fire hero, viewed from behind / rear three-quarter in every panel on a uniform chroma-green background. Panel 1 is weaponless rear idle for ordinary theme combat. Panels 2–4 show the same hero physically carrying the exact long axial Infernal Plasma Projector and aiming up-left, straight upward, and up-right. Both hands must contact the weapon, the stock must brace into the shoulder, and the visible muzzle must stay clear. Preserve the hero's identity, Infernal Dominion outfit materials, complete head / hands / feet / barrel and generous transparent-safe padding. No front view, face toward camera, floating gun, weapon crossing the torso incorrectly, fire obscuring the grip, text, crop, or watermark.

Runtime exports:

- `assets/production/sprites/premium/infernal_dominion/true_grip/char_<hero>_apocalypse_attack[_left|_right].png`
- `inferno_true_grip_contact_sheet_v1.png`
- `infernal_battle_rear_fire_{left,center_isolated,right}.png`

Acceptance rule: battle uses only these rear masters. Front-facing masters may appear in the store, collection and loadout, but must never resolve through `presentation.true_grip`.

## 9. Step 4 authored combat VFX, audio and semantic direction

- Date: 2026-08-01
- Mode: OpenAI built-in `imagegen` using the accepted ten-panel storyboard as the visual reference, then chroma cleanup and deterministic frame/audio derivation through `tools/build_inferno_step4_assets.py`.
- Source master: `inferno_apocalypse_step4_vfx_master_chroma.png`; clean alpha master: `inferno_apocalypse_step4_vfx_master.png`.

Prompt:

> Using the attached accepted Inferno Apocalypse storyboard as the quality and material reference, create one strict 3×2 production VFX source sheet on a perfectly uniform chroma-green background. Each cell contains exactly one fully contained effect with generous clear padding: body-attached persistent burn shaped as a readable standing zombie silhouette; compact white-hot combustion burst with a dark-red pressure ring; one-generation X-shaped death-spread tendrils with four short molten endpoints; mechanical Ember Phoenix flying diagonally upper-right with head clearly leading and molten tail behind; fixed-base thermal counter shaped as an upward-facing semicircular armored fire wave; and full-level awakening as symmetrical mechanical phoenix wings plus a narrow upward central plasma lance. Grounded AAA industrial sci-fi, charred metal, copper, orange-red plasma, white-hot cores, restrained sparks, no text, no UI, no characters except the abstract burn silhouette, no lightning, no fantasy magic circles, no full opaque smoke, no cropped wings/flames/tendrils, no duplicated neighboring cells and no watermark.

Deterministic runtime outputs:

- `vfx_status_inferno_burn`: 6 frames, body-attached persistent state.
- `vfx_apocalypse_inferno_combustion`: 8 frames, true impact-centered burst.
- `vfx_apocalypse_inferno_spread`: 7 frames, single-generation death spread.
- `vfx_apocalypse_inferno_phoenix`: 8 frames, explicit source-forward angle `-45°`; runtime rotates it onto the pet-to-target vector.
- `vfx_apocalypse_inferno_counter`: 8 frames, upward base-counter wave.
- `vfx_apocalypse_inferno_awakening`: 8 frames, behind-hero max-level silhouette.
- Five deterministic SFX: ignition, combustion, phoenix, counter and awakening. Haptics are runtime events with per-effect cooldowns; no continuous vibration loop exists.
- Runtime manifest: `inferno_apocalypse_step4_runtime_manifest.json`; source-frame contact sheet: `inferno_apocalypse_step4_runtime_contact_sheet.png`.
- Runtime acceptance screenshots: `inferno_step4_{burn,combustion_center,combustion_left,combustion_right,combustion_boss,combustion_reduced,spread,phoenix,counter,awakening}.png`.

Acceptance contract: central, left edge, right edge, Boss, horde and reduced-effects routes invoke the real combat functions. Effects remain centered on their gameplay event; edge cases reduce scale rather than moving the event. Phoenix head and tail direction are data-audited against live travel. Reduced effects retain direction, hit center, burn state and counter danger information while removing secondary density.

## 10. App Store button material replacement V2

- Date: 2026-08-10
- Mode: OpenAI built-in `imagegen`, separate primary and secondary chroma-key masters; transparent cleanup with the ImageGen chroma-key helper; deterministic native-size three-slice composition through `tools/build_infernal_runtime_assets.py --buttons-only`.
- Replaces: the former procedural polygon / outline / dot / center-rail button family.
- Runtime contract: rendered end armor remains intact, only a quiet central text lane extends; primary and secondary are independent physical-material renders; no full-bitmap stretching and no geometry fallback.

Primary prompt:

> Create one production-ready transparent-source master for a premium vertical mobile game UI button. Use case: stylized-concept, final shipped UI asset. Theme: Infernal Dominion — blackened forged steel, heat-tempered dark copper, restrained molten-orange furnace energy. Object: one ultra-finished, wide horizontal PRIMARY action-button bezel, front orthographic view, perfectly centered and symmetrical, approximately 5:1 aspect ratio. Design heavy dimensional forged end caps, subtle layered metal bevels, realistic charred steel and copper material wear, tiny recessed ember channels, and a calm nearly-black central text-safe well with excellent white/gold text readability. The entire button must be visible with generous empty padding. No text, letters, numbers, icons, watermark, dot nodes, decorative rail lines, wireframe, flat polygon outlines, geometric-diagram look, loose parts, perspective, cast shadow or neon cyberpunk. Use a perfectly flat solid #00FF00 chroma-key background and do not use green on the button.

Secondary prompt:

> Create one production-ready transparent-source master for a premium vertical mobile game UI button. Use case: stylized-concept, final shipped UI asset. Theme: Infernal Dominion — blackened forged steel, subdued heat-tempered copper and extremely restrained dying ember light. Object: one ultra-finished, wide horizontal SECONDARY navigation/action-button bezel, front orthographic view, perfectly centered and symmetrical, approximately 5:1 aspect ratio. Use dimensional forged end caps with a quieter silhouette, realistic dark gunmetal and antique copper, subtle layered bevels and soot wear, and a calm nearly-black central text-safe well. Keep it visibly dimmer and less saturated than the primary. The entire button must be visible with generous padding. No text, letters, numbers, icons, watermark, dot nodes, decorative rail lines, wireframe, flat polygon outlines, geometric-diagram look, loose parts, perspective, cast shadow or neon cyberpunk. Use a perfectly flat solid #00FF00 chroma-key background and do not use green on the button.

Sources and derivatives:

- `infernal_dominion_button_{primary,secondary}_chroma_v2.png`
- `infernal_dominion_button_{primary,secondary}_transparent_v2.png`
- `infernal_dominion_button_runtime_manifest_v2.json` — 72 native-size assets, 36 sizes × 2 semantic tiers.
- `infernal_dominion_button_runtime_contact_sheet_v2.png`
