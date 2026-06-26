# App Store QA Checklist

## Device Matrix

- iPhone small screen
- iPhone standard screen
- iPhone Pro Max screen
- iPad compatibility mode if enabled

## Required Manual Pass

- Fresh install opens menu without crash.
- Sound toggle works.
- Privacy/support panels open.
- Reset save requires two taps.
- Levels 1-10 can be unlocked sequentially.
- Representative levels 1, 5, 10, 20, 50, 75, 95, and 99 can reach win or loss result.
- Result next-level button works.
- Retry works.
- Return to map works.
- Save persists after app restart.
- Double tap target lock works on touch.
- Tab / strategy button cycles target priority on desktop.
- Skill cards open detail on long press.
- Character, weapon, armor, chip, and pet collection pages open and selection persists.
- No text overlaps at 1080x1920.
- No visible M1/prototype/test wording in release UI.
- No visible debug overlay or debug shortcut instructions.
- 30-minute continuous play has no crash.

## Release Blockers

- Any crash.
- Any missing asset.
- Any unresponsive required button.
- Any placeholder metadata, privacy URL, or support URL.
- Any App Store screenshot that shows debug/prototype text.
