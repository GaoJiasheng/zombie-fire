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

- Asset pack: passed, 1917 files.
- Data: passed, 5 levels, 5 zombies, 1 boss, 4 skills.

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
- 6 backgrounds.
- UI/icon suite.
- 10 contact sheets copied to `assets/production/contact_sheets/`.
- Unit animation placeholder frame sets:
  - characters
  - zombies
  - bosses
  - pets
  - weapon turret recoil
- VFX sequence placeholder frames.
- Flow reference screens.
- Environment portrait crops and battle layout guides.
- Placeholder MP4 videos.
- `OUTSOURCER_ASSET_INDEX.json`.
- Placeholder skeletal body part PNGs and part manifests.
- Production fallback font file.

### Audio

- 9 BGM placeholder WAVs.
- 43 SFX placeholder WAVs.

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
- Final polished video/CG files.
- Final App Store preview video.
- Final custom brand font, if desired. Current `font_main.ttf` is already available as a production fallback.

The current pack is enough for Godot outsourcing to integrate the whole game without waiting for art/audio.
