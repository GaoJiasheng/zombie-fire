# Full Asset Pack Status

> Scope: handoff-ready full-app prototype asset pack.
> Root: `assets/production/`

## Status

`assets/production/` is complete for outsourcing and integration.

Validation:

```bash
python3 tools/validate_asset_pack.py
python3 tools/validate_data.py
```

Current validation result:

- Asset pack: passed, 9,223 files.
- Data: passed, 99 levels, 20 zombies, 8 bosses, 16 skills, 14 environment rows, 10 challenge rules.

## Delivered

### Visuals

- 4 characters:
  - prototype
  - portrait
  - icon
- 20 zombies:
  - prototype
  - portrait
  - icon
- 8 Bosses:
  - prototype
  - portrait
  - icon
- 8 weapons:
  - icon
  - turret
- 6 armor icons.
- 8 chip icons.
- 6 pets:
  - prototype
  - portrait
  - icon
- 8 projectile assets.
- 21 single-frame VFX assets.
- 16 backgrounds: the original menu/map/legacy backgrounds plus 10 campaign battle backgrounds, one per ten-level segment. The campaign set is integrated for tall iPhone portrait layouts and covered by the routed screenshot matrix.
- UI/icon suite.
- 10 contact sheets copied to `assets/production/contact_sheets/`.
- Release-candidate unit animation frame sets:
  - characters
  - zombies
  - bosses
  - pets
  - weapon turret recoil
- Release-candidate VFX sequence frames.
- Flow reference screens.
- Environment portrait crops and battle layout guides.
- Legacy/reference MP4 videos excluded from the current runtime package.
- `OUTSOURCER_ASSET_INDEX.json`.
- Placeholder skeletal body part PNGs and part manifests.
- Production Glow Sans SC / 未来荧黑 Normal Medium font, official OFL notice, and source/hash provenance.

### Ordinary Zombie Model Redesign (2026-07-26)

- Eight mechanic-ambiguous ordinary zombie families were rebuilt at the owner's request: Bomber, Spitter, Juggernaut, Necromancer, Charger, Regenerator, Splitter and Warden.
- Existing IDs and integration paths are preserved. Each family includes prototype, portrait, icon and complete idle / walk / attack / special / hurt / death runtime actions.
- Generation sources, transparent masters, prompts, pre-change prototypes and review sheets are retained under `assets/production/source_refs/generated/zombie_model_redo_2026_07_26/`.
- `assets/production/contact_sheets/contact_zombie_model_redo_2026_07_26.png` is the roster-scale acceptance sheet; after the roster-wide eight-frame attack polish, the permanent silhouette checker covers all 20 ordinary zombies and all 264 animation frames belonging to the eight redesigned families.

### Audio

- 9 integrated BGM WAVs with runtime crossfade/ducking; final monitored mastering remains an Owner sign-off item.
- Integrated weapon, impact, zombie, Boss, skill, UI and result SFX with automated overlap and signal-quality gates.
- The current ten chapters intentionally reuse four battle identities; chapter-specific late-campaign music remains a future audio-production batch rather than an unreviewed last-minute source replacement.

## Contact Sheets

- `assets/production/contact_sheets/contact_characters.png`
- `assets/production/contact_sheets/contact_zombies_t1_t2.png`
- `assets/production/contact_sheets/contact_zombies_t3_t4.png`
- `assets/production/contact_sheets/contact_bosses.png`
- `assets/production/contact_sheets/contact_skills.png`
- `assets/production/contact_sheets/contact_weapons_equipment.png`
- `assets/production/contact_sheets/contact_ui.png`
- `assets/production/contact_sheets/contact_vfx.png`
- `assets/production/contact_sheets/contact_backgrounds.png`
- `assets/production/contact_sheets/contact_level_backgrounds_v2.png`
- `assets/production/contact_sheets/contact_battle_mock.png`

## Asset Replacement Rule

The existing production asset pack remains the integration baseline.

GPT/Codex is allowed to generate replacement assets and prototype revisions when the owner requests a visual upgrade or when a quality issue cannot be solved by layout/code polish alone. This includes character poses, weapon models, character+weapon composites, VFX sequence frames, UI icons, and audio placeholders.

Minimax / external developers should use the production pack by default, but may generate or replace assets when the owner explicitly authorizes it for that task.

They should use:

- Sounds: `assets/production/audio/`
- Animations: `assets/production/sprites/animations/`
- Skeletal/body parts: `assets/production/sprites/parts/`
- Icons/UI: `assets/production/sprites/ui/`
- Flow references: `assets/production/flow/`
- Environments: `assets/production/environment/` and `assets/production/sprites/backgrounds/`
- Effects: `assets/production/sprites/vfx/` and `assets/production/sprites/vfx_sequences/`
- Videos: `assets/production/video/`
- Machine-readable index: `assets/production/OUTSOURCER_ASSET_INDEX.json`

Generated replacements must keep existing IDs and data references where possible, live under `assets/production/`, and be recorded in `assets/production/OUTSOURCER_ASSET_INDEX.json`.

If they believe an asset is missing, they should report the exact missing ID/path before generating a substitute.

## replace_later

These are intentionally not final-polish assets yet:

- Final hand-cut skeletal body parts for dynamic units.
- Final mastered BGM/SFX.
- Optional future narrative video/CG files outside the current release scope.
- The current App Store preview is a completed 22-second capture of real runtime gameplay.
- Runtime `font_main.ttf` now contains the owner-selected official Glow Sans SC / 未来荧黑 Normal Medium v0.93 binary. `fonts/OFL-GlowSans.txt` and `fonts/font_main.provenance.json` record the SIL OFL 1.1 grant, source release, exact byte size, and SHA-256; the release gate and exported-PCK audit require these files.

The current pack is enough for Godot outsourcing to integrate the whole game without waiting for art/audio.
