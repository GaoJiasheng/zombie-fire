# Production Asset Pack Status

> This is the release-candidate production asset pack.
> Runtime visuals and animations have completed the current automated and screenshot acceptance matrix. Audio is integrated and mechanically validated, but still requires final monitored speaker/headphone mastering approval.

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
- Runtime SFX WAVs and priority/overlap behavior: complete; final monitored mastering remains.
- Runtime BGM loops/stingers and dynamic ducking: complete; final monitored mastering remains.
- Unit animation PNG frames: complete for the current release roster.
- VFX sequence PNG frames: complete for the current release combat contract.
- Flow reference PNGs: complete.
- Environment portrait/layout guide PNGs: complete.
- Legacy/reference MP4 videos: retained outside the runtime package.
- Machine-readable outsourcer index: `OUTSOURCER_ASSET_INDEX.json`.
- Placeholder skeletal part PNGs and part manifests: complete.
- Licensed production Glow Sans SC / 未来荧黑 font: complete.
- Runtime-captured 22-second App Store preview: complete.

## replace_later

- Final hand-cut skeletal body parts for characters, zombies, bosses, pets, and turrets.
- Final mastered BGM and SFX.
- Optional future narrative video/CG files; they are not part of the current release scope.

## Important

External development can proceed with this pack. Final production polish should replace the `replace_later` items without changing IDs, file naming, or gameplay scope.

GPT/Codex may generate replacement assets when the owner requests a quality upgrade. External implementation should continue to use this pack by default unless replacement generation is explicitly authorized.

If a needed asset appears missing, run:

```bash
python3 tools/validate_asset_pack.py
```

Then request clarification before generating substitutes. Any accepted generated replacement must keep IDs/data references stable, be placed under `assets/production/`, and be registered in `OUTSOURCER_ASSET_INDEX.json`.
