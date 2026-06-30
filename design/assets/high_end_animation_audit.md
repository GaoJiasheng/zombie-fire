# High-End Animation Audit

> Scope: prototype/simple/vector-looking visuals that should be replaced or upgraded before the game reads like a polished mobile title.
> Date: 2026-06-30.

## Validation snapshot

- `python3 tools/validate_asset_pack.py` passes.
- `python3 tools/validate_data.py` passes.
- `python3 tools/check_res_refs.py` passes.
- This means the issue is not missing files. The issue is visible quality: prototype sprites, old asset paths, runtime vector drawing, single-frame sprite tweens, and UI panels that still look like technical placeholders.

## 2026-06-30 prototype replacement status

- Completed a production prototype rebuild through `tools/generate_high_end_prototype_assets.py`.
- Generated/replaced polished runtime-facing prototypes for characters, character/weapon fused frames, zombies, bosses, pets, skill icons, VFX sequence frames, single VFX sprites, and projectile finish sprites.
- Migrated zombie, boss, and skill icon references to `assets/production/` while preserving IDs and data-driven lookup.
- Trace files: `assets/production/source_refs/generated/high_end_prototype_asset_spec.json`, `assets/production/source_refs/generated/high_end_prototype_contact_sheet.png`, and `assets/production/source_refs/generated/projectile_3d_projectile_sheet.png`.
- Remaining quality caveat: projectile assets are improved 2.5D script-rendered sprites. They pass current asset checks, but they are not true authored/native 3D renders. The next visual-only pass should replace them with dedicated 3D-rendered projectile sheets and animated trail atlases.

## P0: player-visible simple/vector effects

| Area | Current evidence | Why it looks cheap | Upgrade target |
| --- | --- | --- | --- |
| Projectile trail | `gameplay/projectile/projectile.gd` creates `Line2D` trails in `_spawn_trail_streak` and `_spawn_pierce_trace`. | The trail reads as a drawn line, especially rail/pierce traces. | Replace with weapon-specific animated trail sprites: rail beam core + bloom, scatter pellet streaks, plasma distortion, elemental afterimages. |
| Muzzle profile FX | `gameplay/battle/battle.gd` uses `_spawn_weapon_trace`, `_spawn_attack_ring`, `_spawn_short_muzzle_spark` for rail/scatter/plasma. | Weapon identities still depend on rings and lines rather than authored muzzle animation. | Add per-weapon muzzle sequences: machine gun flash, flame jet, cryo burst, tesla fork, venom spray, rail charge/beam, scatter cone, plasma pulse. |
| Skill pick FX | `gameplay/battle/battle.gd::_spawn_skill_pick_vfx` uses one `Sprite2D` from `vfx/*.png`, scales and fades it. | Skill acquisition looks like a static badge pop. | Replace with short skill-acquired sequence: icon rise, frame flare, element particles, slot absorb animation. |
| Active skill intro | `_active_skill_cast_intro` shows a toast + screen flash + one VFX sequence at weapon origin. | The cast lacks staged animation and screen choreography. | Each of four character active skills needs a dedicated 1.2-2.5s effect sequence: cast pose, charge, projectile/field travel, impact waves, lingering aftermath. |
| Active skill world hit | Vanguard/Blaze/Frost/Volt active skills mostly schedule repeated hit callbacks with reused muzzle/hit VFX. | Damage happens, but spectacle is generic. | Dedicated skill systems: barrage lanes, fire rupture pulses, 5s glacier field with frozen enemies, storm chain arcs with ground scorch. |
| Slow field | `battle.gd::_spawn_slow_field_visual` uses a `ColorRect` rectangle. | It reads as a translucent block, not a field. | Replace with animated frost/energy floor band, edge particles, distortion, and per-enemy slow overlays. |
| Barrier | `battle.gd::_spawn_barrier_visual` uses `Polygon2D` fill + `Line2D` edges; break uses polygon shards. | It reads as vector geometry, not glass/energy armor. | Replace with animated shield sprites/particles: shield shimmer, hit ripple, authored glass cracks, break shard sequence. |
| Zombie/base attack telegraph | `_spawn_attack_ring`, `_spawn_attack_telegraph`, `_spawn_breach_attack_vfx` use rings, labels, and single sprites. | The attack language is still debug-like. | Per-zombie attack VFX pack: claw swipe, heavy slam, acid spit, toxic fog, leap impact, charge dust, summon portal, frost/storm/boss effects. |
| Enemy entry / threat warning | `_spawn_enemy_entry_vfx` and near-line warning use rings and simple warning sprites. | Spawn and danger reads as UI overlay, not in-world effect. | Add spawn smoke/portal/ground crack sequences and compact icon badges instead of floating text. |
| Death blood / gore | `_spawn_zombie_blood_pool` uses `Polygon2D` pools and droplets. | Green blood is procedural flat polygons. | Replace with 2-3s animated splatter decals: poison ooze, burn ash, frozen shards, electro scorch, physical flesh/metal debris. |
| Death shards | `_spawn_death_shards` uses `ColorRect` rectangles. | It is visibly rectangular debris. | Replace with authored shard particle sprites per element. |
| Low HP pulse / screen flash | `_spawn_low_hp_pulse` and `_show_screen_flash` use `ColorRect`. | Full-screen red block can obscure gameplay. | Replace with edge vignette texture, damage lens pulse, and short warning HUD animation. |
| Character/pet aura | `_spawn_character_aura`, `_spawn_pet_aura`, `_make_ring_line` use `Line2D` rings. | Looks like vector targeting circles. | Replace with animated aura sprites per element/level, subtle enough not to clutter. |
| Damage numbers | `gameplay/hud/damage_number_layer.gd` uses raw `Label` popups. | Functional but not premium; status damage still feels noisy. | Use stylized number sprites or a controlled text shader style: small red normal damage, bigger gold crit, compact weak-hit badge. |
| Floating texts | `_spawn_float_text`, `_spawn_loadout_badge`, `_spawn_attack_telegraph`, threat labels in `enemy.gd`. | Bare text floats over the battlefield and creates clutter. | Replace most with icon badges, compact event banners, and only keep readable text for rare warnings. |

## P0: prototypes still referenced by gameplay data

| Type | Current references | Upgrade target |
| --- | --- | --- |
| Characters | `assets/production/sprites/characters/char_*_prototype.png`; battle uses generated combo frames but collection/list/prototype refs still exist. | Keep portraits/icons, but replace prototype source with polished half-body/list art and battle-pose source sheets. |
| Zombies | All 20 data rows point to `zombie_*_prototype.png`; first five still use old `res://assets/sprites/zombies/...` paths. | Move all data refs to production paths and replace with polished animated source silhouettes. |
| Bosses | All 8 data rows point to `boss_*_prototype.png`; `boss_tank_titan` still uses old `res://assets/sprites/bosses/...` path. | Replace with production boss battle sheets plus distinct cast/attack/hurt/death sequences. |
| Pets | `data/pets.json` uses `pet_*_prototype.png` for all six pets. | Add idle/follow/attack/support sequence frames; replace prototype sprites. |
| Legacy skill icons | `skill_split_shot`, `skill_pierce`, `skill_multishot`, `skill_slow_field` still reference old `res://assets/sprites/ui/...`. | Move to `assets/production/sprites/ui` and restyle all 16 skill icons as one icon family. |
| Legacy UI and projectile files | `assets/sprites/` still contains old UI, projectile, vfx, starter weapon, starter character, starter boss, and early zombies. | Keep only if deliberately used as compatibility fallback; otherwise migrate refs and remove from visible runtime. |

## P1: existing frame assets that need quality review

| Area | Current state | Upgrade target |
| --- | --- | --- |
| Character + weapon combos | `assets/production/sprites/animations/character_weapon_combos/{char}` has 152 frames per character, covering 4 chars x 8 weapons with idle/attack-left/attack/attack-right/hurt. | Visually inspect and regenerate any combo where gun/body perspective, hand grip, muzzle, or layering looks fused poorly. This is the user's main visible concern. |
| Character animation source | `assets/production/sprites/animations/characters/{char}` has only 11 frames per character. | Replace with richer states: idle, aim-left/center/right, fire, skill-cast, hurt, victory/defeat. |
| Zombie animation source | Each zombie has 23 frames across idle/walk/attack/special/hurt/death. | Quality check for "moving sticker" feel; regenerate high-priority common zombies first with stronger walk/attack silhouettes. |
| Boss animation source | Each boss has 29 frames. | Add boss-specific intro, charge, skill, stagger, armor-break, death. |
| VFX sequences | `assets/production/sprites/vfx_sequences` has 21 sequence dirs, usually 6-16 frames. | Useful base exists, but many runtime calls still use single `sprites/vfx/*.png`; route combat to sequence playback and upgrade low-impact sequences. |
| Projectiles | `assets/production/sprites/projectiles` has 11 single projectile PNGs. | Replace with compact 3D-style projectile + glow + animated trail set per weapon/ammo. |
| Audio | Asset status marks BGM/SFX as placeholders. | Not visual, but high-end animation must be paired with stronger cast, hit, boss, UI, and reward sounds. |

## P1: UI still generated as code panels

| Scene | Evidence | Upgrade target |
| --- | --- | --- |
| Global UI kit | `ui/ui_kit.gd` builds most panels with `StyleBoxFlat`. | Fine for layout, but needs a premium skin layer: shared nine-slice panels, corner accents, hover/press motion, text-safe containers. |
| Map | `meta/map/map.gd` creates nav cards, level cards, pills, dividers, and resource tooltips in code. | Keep structure, replace with image-backed cards and icon-led resource chips; reduce saturated flat blue. |
| Loadout | `meta/loadout/loadout.tscn/.gd` uses many `Label`, `ColorRect`, `PanelContainer` elements. | Layout is acceptable; add asset-backed frames, centered image masks, clearer summary card, and consistent return-stack behavior. |
| Collection | `meta/collection/collection.gd` builds list cards and details through code panels and labels. | Replace double-frame cards with a single premium item row; compact close icon; wrap long text. |
| Result | `meta/result/result.tscn` is mostly StyleBoxFlat panels and text buttons. | Needs reward animation: star reveal, coin/xp count-up, result badge, button icon styling. |
| Pause | `gameplay/battle/battle.tscn` + generated cards in `battle.gd` still include text-heavy build summary. | Must fully pause game and become a clean modal: compact icons, loadout summary, no English/internal IDs. |
| Skill card chooser | `battle.tscn` card panel + `_build_skill_card` are code-generated panels. | Needs premium skill card motion, icon focus, readable wrapped text, and complete pause of all gameplay systems. |

## P2: non-player-facing or lower-priority simple assets

| Area | Current state | Note |
| --- | --- | --- |
| Contact sheets | `assets/production/contact_sheets/*` and `contact_battle_mock.png`. | Keep as audit/reference; not runtime unless accidentally referenced. |
| Battle layout guides | `assets/production/environment/*_battle_layout_guide.png`. | Good for development, should not appear in runtime UI. |
| Low-color UI PNGs | Many UI icons/frames have 2-7 colors. | This is not automatically wrong, but the visible flat blue/card-frame family should be replaced where it reads like prototype UI. |
| Placeholder videos | `assets/production/video/*.mp4` marked placeholder. | Only relevant if app flow uses videos/CG. |

## Replacement order

1. Replace all runtime vector combat effects: projectile trails, pierce traces, attack rings, barrier, slow field, blood/death shards.
2. Regenerate and integrate four active skill cinematic sequences.
3. Regenerate projectiles/trails/impact sets for all weapon profiles and ammo elements.
4. Quality-pass character+weapon combo frames; regenerate bad combinations instead of layering guns at runtime.
5. Move old `assets/sprites` gameplay refs to production paths and retire visible prototype paths.
6. Upgrade map/loadout/collection/result/pause/skill-card UI skins with one shared premium palette and image-backed frames.
7. Pair visual upgrades with SFX timing so animations feel intentional instead of silent overlays.
