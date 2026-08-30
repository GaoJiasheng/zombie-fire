# Paid-theme title ornaments — prompt and production log

Date: 2026-08-30

## Shared production contract

Each theme is generated as one textless 1040×340 horizontal ornament. Preserve the accepted theme material language and a continuous sculptural silhouette, remove all baked English typography, and leave a clean low-detail dark center for deterministic typesetting. Keep the full ornament visible with at least 24 px padding. Use a uniform pure chroma-green `#00FF00` background for deterministic removal (the Infernal first pass returned a checkerboard and was isolated by connected-background masking).

Prohibited in every prompt: text, letters, numerals, pseudo-writing, runes, glyphs, logos, watermarks, segmented rails, tick marks, dotted/dashed borders, repeated fence-like bars, clipped glow, characters, weapons, scenery, or bright center bloom.

## Theme material prompts

- **Neon Tempest:** deep graphite metal, one uninterrupted recessed conductor channel, cyan-to-electric-violet perimeter glow, sparse violet capacitor nodes, subtle circuit etching, deep blue-black center.
- **Infernal Dominion:** blackened forged metal, symmetrical flaming-skull crest, ember-orange continuous edge light, restrained red glow, dark center plate.
- **Polar Aurora:** sculpted ice and steel, crystalline crown, frosted dark metal, continuous cyan-to-violet aurora edge, dark blue-black center.
- **Gilded Eclipse:** flowing black-gold silhouette, eclipse crown, obsidian metal, restrained antique-gold edge light, elegant law-like geometry without readable glyphs, near-black center.

## Exact typography

The model output contains no text. Runtime titles are composed locally with the licensed project font so spelling is deterministic:

- Simplified Chinese: `尸潮防线`
- English: `ZOMBIE FIRE`

Neon Tempest receives both language variants. Infernal Dominion, Polar Aurora, and Gilded Eclipse retain their accepted English assets and receive new Chinese variants. All runtime outputs are 1040×340 RGBA.
