# Codex CLI / Minimax Handoff · Zombie Fire M1

> Workspace: `/Users/gavin/work/zombie-fire`
> Goal: continue playable M1 implementation without drifting from the established design, asset style, or current code structure.

## 0. Read First

Before editing, read these files in order:

1. `design/m1_todo.md`
2. `design/m1_implementation_progress.md`
3. `design/README.md`
4. `design/13_tech_architecture.md`
5. `design/01_core_gameplay.md`
6. `design/assets/visual_style_lock.md`
7. `design/assets/m1_visual_asset_todo.md`
8. `design/data/naming_convention.md`
9. `design/data/schema.md`

The current design is not a generic zombie shooter. It is a vertical 1080x1920 Godot 4 roguelite tower-defense/autoshooter inspired by `向僵尸开炮`, improved around clear targeting, controlled randomness, fair early fun, and no monetization pressure.

## 1. Current Truth

The project now has a real Godot skeleton at repo root:

- `project.godot`
- `main.tscn`
- `main.gd`
- `core/`
- `gameplay/`
- `meta/`
- `data/`
- `assets/sprites/`
- `tools/validate_data.py`

Implemented already:

- Git repo initialized.
- Godot 4 project configured for 1080x1920 vertical layout.
- Scene route: `menu -> map -> loadout -> battle -> result`.
- M1 data tables:
  - `data/elements.json`
  - `data/economy.json`
  - `data/characters.json`
  - `data/weapons.json`
  - `data/zombies.json`
  - `data/bosses.json`
  - `data/skills.json`
  - `data/levels.json`
  - `data/localization_zh.json`
- Runtime data loader, save manager, input manager.
- Battle loop skeleton:
  - wave loading from `levels.json`
  - enemy spawn and downward movement
  - breach damage
  - fixed bottom turret
  - auto fire
  - mouse aim
  - projectile collision and damage
  - enemy death rewards
  - victory/defeat and 1-3 star result
  - save/load progress
- Targeting:
  - `TargetingManager`
  - automatic scoring
  - right-click lock
  - lock indicator
- Card/skill first pass:
  - run XP threshold
  - three-choice popup
  - weighted `CardDirector`
  - `skill_split_shot`
  - `skill_pierce`
  - `skill_multishot`
  - `skill_slow_field`

Validation currently passes:

```bash
python3 tools/validate_data.py
```

Expected output:

```text
Data validation passed: 5 levels, 5 zombies, 1 boss, 4 skills
```

Godot executable was not available in PATH during the previous pass, so editor/runtime playtest is still pending.

## 2. Hard Constraints

Do not change these without explicit user approval:

- Engine: Godot 4 + GDScript.
- Logical resolution: 1080x1920 vertical.
- Stretch mode: `canvas_items`, aspect `keep`.
- M1 scope: 5 playable levels only.
- M1 playable character: `vanguard` only.
- M1 weapon: `weapon_autocannon` only.
- M1 enemies:
  - `zombie_shambler`
  - `zombie_runner`
  - `zombie_brute`
  - `zombie_bomber`
  - `zombie_screamer`
- M1 boss:
  - `boss_tank_titan`
- M1 skills:
  - `skill_split_shot`
  - `skill_pierce`
  - `skill_multishot`
  - `skill_slow_field`
- Data-driven content in `data/*.json`; avoid hardcoding content lists in gameplay code when data already exists.
- Preserve asset naming from `design/data/naming_convention.md`.
- Do not regenerate or replace visual assets unless explicitly asked.
- Do not generate any sounds, animations, icons, flow references, environments, effects, or videos. Use `assets/production/` only.
- Do not turn the game into a generic top-down shooter. The turret remains fixed at the bottom; enemies push down from the top to the base line.

## 3. Visual/Design Anchors

Use the production asset pack first:

- `assets/production/OUTSOURCER_ASSET_INDEX.json`
- `assets/production/ASSET_PACK_STATUS.md`
- `design/assets/full_asset_pack_status.md`
- `tools/validate_asset_pack.py`

The external implementation must not create or source new assets. If an asset seems missing, report the exact missing path/ID and stop.

Visual style is locked in:

- `design/assets/visual_style_lock.md`
- `assets/m1_visual/M1_ASSET_PROGRESS.md`
- `assets/m1_visual/contact_sheets/contact_battle_mock.png`
- `assets/m1_visual/contact_sheets/contact_characters.png`
- `assets/m1_visual/contact_sheets/contact_zombies_t1_t2.png`
- `assets/m1_visual/contact_sheets/contact_bosses.png`
- `assets/m1_visual/contact_sheets/contact_skills.png`
- `assets/m1_visual/contact_sheets/contact_weapons_equipment.png`
- `assets/m1_visual/contact_sheets/contact_ui.png`
- `assets/m1_visual/contact_sheets/contact_vfx.png`
- `assets/m1_visual/contact_sheets/contact_backgrounds.png`

The four hero roster is locked as:

- `char_vanguard`: brawny strongman
- `char_blaze`: young fire guy
- `char_frost`: aloof mature cryo woman
- `char_volt`: electro girl

Do not accidentally drift back to four bulky armored men.

## 4. Immediate Next Tasks

Continue from `design/m1_implementation_progress.md`.

Recommended next implementation order:

1. Add usable HUD bars and pause overlay.
   - Replace plain labels with visual base HP, wave progress, run XP.
   - Add pause button/keyboard cancel behavior.
   - Preserve battle readability; no giant decorative panels.

2. Add one reroll charge to the card popup.
   - M1 rule: each run has 1 reroll.
   - Reroll should re-offer three cards.
   - Avoid economy cards in M1 unless already part of current skill pool.

3. Add Lv3 qualitative upgrade feedback.
   - Minimum viable version: when a skill reaches level 3, show visible stronger effect.
   - Good candidates:
     - `skill_split_shot`: bigger split fan / more split bullets.
     - `skill_multishot`: wider and brighter shot fan.
     - `skill_slow_field`: visible slow zone near defense line.

4. Add threat markers and targeting debug overlay.
   - Threat marker for `breach`, `fast`, `burst`, `support`, `elite`, `boss`.
   - Debug overlay can be toggled; show target score or chosen target reason.

5. Open in Godot and fix actual runtime/editor errors.
   - If Godot CLI exists, run the project.
   - If not, keep static validation and document playtest pending.

## 5. Acceptance Criteria For This Chunk

After the next chunk, these should remain true:

```bash
python3 tools/validate_data.py
```

passes.

Also run a `res://` reference check similar to:

```bash
python3 - <<'PY'
from pathlib import Path
import re
root=Path('.').resolve()
missing=[]
for path in list(root.rglob('*.gd'))+list(root.rglob('*.tscn'))+list(root.rglob('project.godot')):
    text=path.read_text(errors='ignore')
    for ref in sorted(set(re.findall(r'res://[^\\\"\\)\\]\\s]+', text))):
        if '%' in ref:
            continue
        if not (root/ref.removeprefix('res://')).exists():
            missing.append((path.relative_to(root), ref))
print('missing', len(missing))
for item in missing:
    print(item[0], item[1])
PY
```

Expected: `missing 0`.

If Godot is available, also run/open the project and verify:

- menu opens
- map shows 5 levels
- loadout enters battle
- turret fires
- enemies spawn and move downward
- enemies can be killed
- enemies can breach and reduce base HP
- card popup appears after enough XP
- choosing a card resumes battle
- result screen appears on win/loss

## 6. Known Risk Areas

These are likely to need correction:

- `.tscn` syntax and Godot resource IDs may need editor-generated cleanup.
- `Area2D` collision signal behavior may need adjustment after real Godot run.
- Current HUD is mostly labels; it needs real UI assets from `assets/sprites/ui/`.
- Card popup pauses the tree; ensure HUD remains interactive while paused.
- The current target lock receives screen-space mouse position. In simple canvas setup this probably works, but if camera/viewport transforms are added, convert to world coordinates.
- The current boss has `immune: ["physical"]`, but `weapon_autocannon` is physical. For M1 this may make level 5 impossible unless armor-break/weakness/temporary nonphysical damage is implemented. Do not leave level 5 unwinnable.
- `project.godot` autoload paths should be validated inside the Godot editor.

## 7. Drift Correction Rules

If uncertain, prefer these corrections:

- If implementation expands scope, cut back to M1 only.
- If code hardcodes content that exists in JSON, move it back to data-driven logic.
- If visuals are replaced with generic placeholders, restore accepted assets under `assets/sprites/` or `assets/m1_visual/samples/`.
- If the game becomes free-moving/player-character based, restore fixed bottom turret defense.
- If target logic feels random, restore priority:
  1. manual lock
  2. breach threat
  3. elite/Boss
  4. strategy bonus
  5. nearest/low HP fallback
- If card randomness becomes pure random, restore `CardDirector` weighting using level `card_bias` and skill tags.
- If level 5 becomes impossible because of physical immunity, either:
  - implement armor-break so physical can damage after a condition, or
  - adjust M1 boss immunity behavior while keeping the design note that hard immunity is a later Boss mechanic.

## 8. Files To Update After Work

Always update these after meaningful progress:

- `design/m1_todo.md`
- `design/m1_implementation_progress.md`

If data schema or naming changes, also update:

- `design/data/schema.md`
- `design/data/naming_convention.md`

Do not silently change design documents to match a bad implementation. If implementation reveals a design problem, document the tradeoff first.

## 9. Suggested Prompt For Codex CLI / Minimax

Use this as the prompt:

```text
You are continuing the Zombie Fire M1 playable prototype in /Users/gavin/work/zombie-fire.

First read CODEX_MINIMAX_HANDOFF.md completely, then read the files listed in its "Read First" section.

Continue M1 implementation from design/m1_implementation_progress.md.

Do not expand scope beyond M1. Do not regenerate assets. Preserve Godot 4 + GDScript, 1080x1920 vertical layout, fixed bottom turret, data-driven JSON content, and the accepted visual style.

Implement the next coherent chunk:
1. HUD bars and pause overlay.
2. One reroll charge in the card popup.
3. Lv3 qualitative upgrade feedback.
4. Threat markers and targeting debug overlay if time allows.

After edits, run:
python3 tools/validate_data.py

Also check res:// references for missing files.

Update design/m1_todo.md and design/m1_implementation_progress.md with exact progress and remaining items.

If Godot is available, run/open the project and fix runtime/editor errors. If not, state that runtime playtest is pending.
```
