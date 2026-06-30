# Minimax Final Instructions

> Short hard-rule instruction set for outsourced implementation.

## Mission

Verify and polish the expanded Zombie Fire build in `/Users/gavin/work/zombie-fire`.

Do not redesign the game. Do not replace existing systems.

## Must Read

1. `CODEX_MINIMAX_HANDOFF.md`
2. `design/m1_todo.md`
3. `design/current_release_scope.md`
4. `design/assets/full_asset_pack_status.md`
5. `assets/production/OUTSOURCER_ASSET_INDEX.json`

## Asset Rule

The existing asset pack remains the default source of truth, but GPT/Codex is now allowed to generate replacement assets when visual quality requires it or the owner requests it.

Use only:

- `assets/production/audio/`
- `assets/production/sprites/animations/`
- `assets/production/sprites/parts/`
- `assets/production/sprites/ui/`
- `assets/production/sprites/vfx/`
- `assets/production/sprites/vfx_sequences/`
- `assets/production/sprites/backgrounds/`
- `assets/production/environment/`
- `assets/production/flow/`
- `assets/production/video/`
- `assets/production/fonts/`

Generated replacement assets are allowed under these rules:

- Keep the same game scope, IDs, data references, and Godot integration paths.
- Match the locked cyberpunk / ruined-city visual language.
- Store source prompts or source references under `assets/production/source_refs/generated/`.
- Place integrated assets under the existing `assets/production/` subtree.
- Update `assets/production/OUTSOURCER_ASSET_INDEX.json` when a generated replacement becomes part of the build.

If an asset seems missing, run:

```bash
python3 tools/validate_asset_pack.py
```

If validation passes, prefer existing assets unless a quality replacement is being made deliberately. If validation fails, report the exact missing path before continuing.

## Gameplay Rule

This is not a free-moving shooter.

Keep:

- vertical 1080x1920 layout
- fixed bottom turret
- enemies entering from top and pushing toward base line
- auto fire + manual aim
- right-click/manual target lock
- data-driven levels, enemies, skills, and equipment
- current expanded release scope only

## Current Scope

The repository now contains the expanded scope:

- 99 campaign levels
- 4 characters
- 8 weapons
- armor/chip/pet equipment
- 20 zombies
- 8 bosses
- 16 skills
- collection UI and star-gated unlocks
- equipment effects in battle

Treat new work as verification, tuning, bug fixing, and polish unless explicitly asked to expand again.

## Next Work

Implement in this order:

1. Run the validation commands below.
2. Playtest levels 1, 5, 10, 20, 50, and 99.
3. Check character/weapon/armor/chip/pet selection from map and loadout.
4. Verify skill card icon, text, and long-press/right-click detail.
5. Tune pacing only if a level is clearly unwinnable or trivial.

## Boss Warning

Physical-immunity bosses rely on armor-break/element matchup rules. If a boss becomes unwinnable, do not leave it that way.

Acceptable M1 fixes:

- implement armor-break so physical damage works after a condition, or
- soften M1 immunity while keeping final design notes intact.

## Data Rule

Do not hardcode content lists in gameplay code when JSON exists.

Use:

- `data/levels.json`
- `data/zombies.json`
- `data/bosses.json`
- `data/skills.json`
- `data/weapons.json`
- `data/armors.json`
- `data/chips.json`
- `data/pets.json`

If data changes, keep schema and validation aligned.

## Validation

Before reporting completion, run:

```bash
python3 tools/validate_asset_pack.py
python3 tools/validate_data.py
python3 tools/check_res_refs.py
python3 tools/check_level_pressure.py
python3 tools/simulate_card_director.py
godot --headless --path . --quit
godot --headless --path . --script res://tools/m1_smoke_test.gd
```

If Godot is available, run/open the project and manually verify:

- menu opens
- map shows scrollable 99-level campaign
- collection pages open and equipment can be selected
- loadout starts battle
- enemies spawn
- turret fires
- selected equipment changes battle stats
- selected pet appears or contributes its configured support behavior
- enemies die
- enemies can breach
- card popup appears
- card selection resumes battle
- win/loss result appears

## Required Report Format

```text
Completed:
- ...

Changed files:
- ...

Verification:
- python3 tools/validate_asset_pack.py: pass/fail
- python3 tools/validate_data.py: pass/fail
- Godot run: pass/fail/not available
- Manual playtest: levels tested

Risks / blockers:
- ...
```
