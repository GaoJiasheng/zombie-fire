# Zombie Fire

Godot 4 vertical shooter / tower-defense roguelite.

## Run

```bash
godot --path .
```

Main flow:

```text
menu -> map -> loadout -> battle -> result
```

## Current Build

- 99 playable campaign levels.
- 4 selectable characters, 8 weapons, armor/chip/pet equipment, and star-gated unlocks.
- 20 zombie types, 8 bosses, and 16 skill cards.
- Fixed bottom autocannon with auto-fire, mouse/touch aim, right-click lock.
- Target strategy switching via `Tab` or the in-battle strategy button.
- Skill cards render icon, level, short text, tags, and long-press/right-click details.
- Enemy walk/hurt/death animation, HP bars, hit VFX, muzzle flash, reward float text.
- Global BGM/SFX through `AudioManager`; menu has sound toggle.
- Save progression: level unlocks, stars, gold, weapon upgrades, equipment selection.
- Menu help, privacy/support, reset, backup/restore, sound and quality controls.

## Validation

```bash
python3 tools/validate_asset_pack.py
python3 tools/validate_data.py
python3 tools/check_res_refs.py
python3 tools/check_level_pressure.py
python3 tools/check_balance_profile.py
python3 tools/check_app_store_assets.py
python3 tools/check_release_strings.py
python3 tools/simulate_card_director.py
godot --headless --path . --quit
godot --headless --path . --script res://tools/m1_smoke_test.gd
```

One-shot release candidate gate:

```bash
python3 tools/check_release_candidate.py
```

Expected:

- Asset pack validation passes.
- Data validation reports 99 levels, 20 zombies, 8 bosses, 16 skills.
- `res://` reference scan has no missing paths.
- Level pressure checker exits cleanly.
- Balance profile checker exits cleanly.
- App Store asset checker exits cleanly.
- Release string checker exits cleanly.
- Card director simulation prints per-level offer distribution.
- Smoke test prints `M1 smoke test passed`.

Godot headless may print resource cleanup warnings on exit even when exit code is `0`.

## Acceptance Notes

See `design/app_prototype_acceptance.md` for the current feature checklist and manual QA focus.

See `docs/app_store_submission_runbook.md` for App Store submission steps and external signing/public URL requirements.
