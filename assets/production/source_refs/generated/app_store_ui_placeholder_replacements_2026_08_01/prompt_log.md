# App Store UI placeholder replacement prompt log

Date: 2026-08-01

Purpose: replace the remaining flat procedural/cropped-reference runtime UI assets discovered during the final App Store visual audit. Runtime IDs and dimensions remain stable.

## Core HUD icon atlas

Generated as a strict 5×3 extraction atlas, then regenerated against pure `#00FF00` chroma for deterministic transparent isolation. The prompt requested, in order: gold currency, mission star, XP core, fire, frost, lightning, physical impact, poison, lock, pause, reroll, settings, talent seal, warning and map pin. Every icon was required to be a deeply rendered orthographic physical object with gunmetal, restrained cyan/orange reflections, phone-readable silhouette, no tile or text.

Source: `core_hud_icons_chroma.png`

## Tactical icon atlas

Generated as a strict 5×3 pure-chroma extraction atlas. The prompt requested, in order: map pin, reroll, skip, projectile tag, control tag, combined element tag, economy tag, breach priority, elite priority, low-HP priority, nearest priority, filled star, empty star, information and upgrade. Runtime uses the first thirteen outputs; the final two remain outside runtime.

Source: `tactical_icons_chroma.png`

## Native HUD surfaces

Generated as five separately modelled native-length dark gunmetal/smoked-glass frames on pure chroma: level card, combo panel, status pill, item plate and damage badge. The builder preserves rendered corners and extends only each quiet center span, replacing the former unrelated source-sheet fragments.

Source: `hud_surfaces_chroma.png`

## Runtime extraction rules

- `tools/build_app_store_ui_replacements.py`
- 18 px icon guard band at 256×256.
- No baked button/tile background on semantic icons.
- Chroma fringe and atlas specks are removed without suppressing the poison subject.
- Native surfaces preserve corner scale; only calm center spans may extend.
- `tools/check_app_store_ui_polish.py` enforces sources, counts, dimensions, alpha margins, color depth and chroma-edge limits.
