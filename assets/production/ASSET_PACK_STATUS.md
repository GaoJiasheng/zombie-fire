# Production Asset Pack Status

> This is the handoff-ready prototype production asset pack.
> Visuals are copied/derived from accepted M1 visual prototypes. Audio is generated as procedural placeholder material for integration and timing.

## Complete For External Development

- Character prototype/portrait/icon PNGs: complete.
- Zombie prototype/portrait/icon PNGs: complete.
- Boss prototype/portrait/icon PNGs: complete.
- Weapon icon/turret PNGs: complete.
- Armor/chip icon PNGs: complete.
- Pet prototype/portrait/icon PNGs: complete.
- Projectile PNGs: complete.
- Single-frame VFX PNGs: complete.
- Background PNGs: complete.
- UI/icon PNGs: complete.
- P0/P1 SFX placeholder WAVs: complete.
- BGM placeholder WAV loops/stingers: complete.
- Unit animation placeholder PNG frames: complete.
- VFX sequence placeholder PNG frames: complete.
- Flow reference PNGs: complete.
- Environment portrait/layout guide PNGs: complete.
- Placeholder MP4 videos: complete.
- Machine-readable outsourcer index: `OUTSOURCER_ASSET_INDEX.json`.
- Placeholder skeletal part PNGs and part manifests: complete.
- Production fallback font: complete.

## replace_later

- Final hand-cut skeletal body parts for characters, zombies, bosses, pets, and turrets.
- Final mastered BGM and SFX.
- Final polished video/CG files.
- Final App Store preview video.

## Important

External development can proceed with this pack. Final production polish should replace the `replace_later` items without changing IDs, file naming, or gameplay scope.

GPT/Codex may generate replacement assets when the owner requests a quality upgrade. External implementation should continue to use this pack by default unless replacement generation is explicitly authorized.

If a needed asset appears missing, run:

```bash
python3 tools/validate_asset_pack.py
```

Then request clarification before generating substitutes. Any accepted generated replacement must keep IDs/data references stable, be placed under `assets/production/`, and be registered in `OUTSOURCER_ASSET_INDEX.json`.
