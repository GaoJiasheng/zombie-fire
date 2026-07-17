# App Store QA Checklist

## Device Matrix

- iPhone small screen
- iPhone standard screen
- iPhone Pro Max screen

## Required Manual Pass

- Fresh install opens menu without crash.
- Music, effects, and interface volume controls work independently.
- Reduced-effects and haptics toggles work and persist.
- Privacy/support panels open.
- Reset save requires two taps.
- Levels 1-10 can be unlocked sequentially.
- Representative levels 1, 5, 10, 20, 50, 75, 95, and 99 can reach win or loss result.
- Result next-level button works.
- Result battle report expands/collapses and its totals match an observed short battle.
- Retry works.
- Return to map works.
- Save persists after app restart.
- Double tap target lock works on touch.
- Strategy button cycles target priority on touch.
- Skill cards open detail on long press.
- The first two card offers contain a loadout-relevant core option and are not occupied by pure economy cards.
- Every chapter challenge entry displays its fixed modifier and counter hint before battle.
- Representative armored, immune, summoning, and multi-phase bosses show a readable weakness/counter cue and repeat it after a failed result.
- Character, weapon, armor, chip, and pet collection pages open and selection persists.
- No text overlaps on small, standard, or Pro Max iPhone viewports.
- Glow Sans SC / 未来荧黑 remains readable on a physical iPhone; map rows, settings copy, card descriptions, collection lists, and all four character details show no clipping or fallback glyphs.
- Speed control is hidden below level 30, offers only 2X at level 30, and adds 5X at level 50.
- A 5X late-wave stress pass does not leak enemies, projectiles, audio players, or VFX nodes.
- Backgrounding and resuming preserves the latest progress and restores audio correctly.
- No visible M1/prototype/test wording in release UI.
- No visible debug overlay or debug shortcut instructions.
- 30-minute continuous play has no crash.

## Release Blockers

- Any crash.
- Any missing asset.
- Any unresponsive required button.
- Any placeholder metadata, privacy URL, or support URL.
- Any App Store screenshot that shows debug/prototype text.
