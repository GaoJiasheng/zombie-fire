# AGENTS.md — Zombie Fire

Project context for any AI coding agent (Codex CLI, codex-plugin-cc, etc.) working in this repo.
Authoritative detail lives in `CODEX_MINIMAX_HANDOFF.md` and `MINIMAX_FINAL_INSTRUCTIONS.md` — this file is the short entry point.

## What this is

Vertical (1080×1920) Godot 4 + GDScript roguelite tower-defense / auto-shooter inspired by《向僵尸开炮》,
improved around: clear targeting, controlled randomness, fair early fun, and transparent progression.
The current Build 38 is single-player with no IAP, ads, or stamina. The owner has explicitly approved a future
non-consumable premium-theme and strong-equipment initiative; its scope and safeguards are locked in
`design/21_premium_themes_and_apocalypse_arsenal_plan.md`. Phase 1 is Neon Tempest plus the complete Thunder
Apocalypse set; its inventory is `design/22_neon_tempest_thunder_phase1_inventory.md`. The owner selected
Infernal Dominion plus Inferno Apocalypse as Phase 2 on 2026-07-31; its frozen inventory is
`design/25_infernal_dominion_inferno_phase2_inventory.md`. The implemented third series is Polar Aurora plus
Absolute Zero Apocalypse; its frozen inventory is `design/26_polar_aurora_absolute_zero_phase3_inventory.md`.
On 2026-08-01 the owner reopened a new fourth, post-campaign flowing black-gold direction: Gilded Eclipse plus
Golden Law Apocalypse. Its eleven-board Step 0 / Step 1A detailed prototype pack is frozen in
`design/27_gilded_eclipse_golden_law_phase4_proposal.md`; no runtime theme, product, entitlement, data row or
balance change exists until the owner authorizes the next production step.
Targets iOS + macOS first; Web/Windows/Android kept portable.

Fixed bottom turret. Enemies push down from the top toward the base line. Auto fire + manual aim + manual lock.

## Golden rules (do not violate without explicit owner approval)

1. Do NOT expand scope. Current scope is the expanded build (99 levels, 4 characters, 8 weapons, armor/chip/pet, 20 zombies, 8 bosses, 16 skills, collection + star-gated unlocks). Treat new work as verify / tune / bugfix / polish unless told otherwise.
2. Keep the core form: Godot 4 + GDScript, 1080×1920 vertical, stretch `canvas_items` aspect `expand`, fixed bottom turret defense. `expand` is required for tall iPhones so the battlefield fills the display without black bars. Never turn it into a free-moving top-down shooter.
3. Data-driven. Content lives in `data/*.json` — never hardcode content lists in gameplay code when JSON exists. Keep `design/data/schema.md` and `design/data/naming_convention.md` aligned with any data/naming change.
4. Assets: prefer the existing pack under `assets/production/`. Generated replacements are allowed only when quality requires or the owner asks; keep IDs/data refs/paths, match the locked visual style, store source prompts under `assets/production/source_refs/generated/`, and register in `assets/production/OUTSOURCER_ASSET_INDEX.json`. If an asset seems missing: report the exact path/ID and stop.
5. Never leave a level unwinnable. Physical-immunity bosses need an armor-break/weakness path (M1 boss = `boss_tank_titan`, M1 weapon = physical `weapon_autocannon`).
6. Hero roster is locked: `char_vanguard` brawny strongman · `char_blaze` young fire guy · `char_frost` aloof mature cryo woman · `char_volt` electro girl. Do not drift back to four bulky armored men.
7. Do NOT silently rewrite design docs to match a bad implementation. If implementation reveals a design problem, document the tradeoff first.
8. After meaningful progress, update `design/m1_todo.md` and `design/m1_implementation_progress.md`.
9. Premium work is an explicit owner-approved exception to the old no-IAP direction. Three series are implemented; the fourth black-gold series has only a detailed non-runtime prototype pack. Do not infer that it is selectable, purchasable or balanced, do not infer that Apple commerce is already implemented, do not add ads/subscriptions/paid currencies, and do not expand beyond the current gate in `design/21_premium_themes_and_apocalypse_arsenal_plan.md` and the series inventories / proposal.

## Read first (in order)

1. `CODEX_MINIMAX_HANDOFF.md`
2. `design/m1_todo.md`
3. `design/m1_implementation_progress.md`
4. `design/current_release_scope.md`
5. `design/21_premium_themes_and_apocalypse_arsenal_plan.md` when working on monetization, themes, StoreKit, or premium equipment
6. `design/22_neon_tempest_thunder_phase1_inventory.md` when working on the current premium Phase 1
7. `design/25_infernal_dominion_inferno_phase2_inventory.md` when working on premium Phase 2
8. `design/26_polar_aurora_absolute_zero_phase3_inventory.md` when working on premium Phase 3 or final-catalog regression
9. `design/27_gilded_eclipse_golden_law_phase4_proposal.md` when working on the proposed fourth series
10. `design/README.md`
11. `design/13_tech_architecture.md`
12. `design/01_core_gameplay.md`
13. `design/data/naming_convention.md`
14. `design/data/schema.md`
15. `design/assets/full_asset_pack_status.md` · `assets/production/OUTSOURCER_ASSET_INDEX.json`

## Validation — must pass before reporting done

```bash
python3 tools/validate_asset_pack.py
python3 tools/validate_data.py
python3 tools/check_res_refs.py
python3 tools/check_level_pressure.py
python3 tools/simulate_card_director.py
godot --headless --path . --quit
godot --headless --path . --script res://tools/m1_smoke_test.gd
```

Also verify `res://` references resolve (no missing files). Godot IS installed at `/opt/homebrew/bin/godot`.

## Safety

- This repo is the source of truth and already contains substantial work. Prefer additive, reversible edits.
- Ask before anything destructive or hard to reverse (mass delete, history rewrite, asset regeneration that overwrites accepted assets).
- Report outcomes faithfully: if validation fails or a playtest is pending, say so with the command output.

## Report format (when finishing a chunk)

```
Completed: …
Changed files: …
Verification: <each validation command> pass/fail/not-available; levels playtested
Risks / blockers: …
```
