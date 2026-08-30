# Neon Tempest button rework · Phase 1 generation and review log

Date: 2026-08-30
Mode: built-in image generation, followed by deterministic review-only size/state derivation
Runtime status: no runtime texture, `.import`, `themes.json`, scene, script, or gameplay file changed

## References and roles

- Existing Neon Tempest runtime contact sheet: material identity reference and negative reference for segmented side grilles, top calibration ticks, repeated modules, diamonds, and luminous center fill.
- Infernal Dominion button contact sheet: structural reference for a continuous sculpted frame and restrained center only; fire/copper materials were not copied.
- Polar Aurora button contact sheet: structural reference for a continuous frame and quiet label bed only; ice/silver materials were not copied.

## Primary generation prompt

> Use case: stylized-concept
>
> Asset type: production game UI button source master for a vertical mobile tower-defense game
>
> Input images: Image 1 is the existing Neon Tempest button family whose cyan-to-violet material identity must be preserved but whose segmented side bars, top tick marks, bright center fill, diamonds and repeated ornaments are explicitly rejected; Images 2 and 3 are structural references only for the clean continuous-frame construction and restrained dark center, not for their fire or ice materials.
>
> Primary request: create one premium Neon Tempest PRIMARY button plate as a single isolated transparent PNG asset, front orthographic view, approximately 5:1 wide. The entire outer frame is one continuous sculpted piece of deep black-blue titanium. A single continuous recessed conduit/circuit channel follows the full perimeter without breaks, carrying restrained electric cyan glow on the left that transitions smoothly to ultraviolet and purple on the right. The metal outer outline is solid, continuous and physically substantial. The center is a quiet deep blue-black label bed with only extremely faint low-contrast circuit texture, no bright glossy gradient; center luminance must be no brighter than the Infernal Dominion center so white copy remains highly readable. Glow is confined to the recessed perimeter channel and does not bloom into the text area.
>
> Style/medium: polished AAA mobile game UI sprite, hard-surface sculpted metal, precise manufacturing, crisp at 44 px tall, symmetrical and deliberately simple at phone scale.
>
> Composition/framing: exactly one complete horizontal button, centered with generous transparent padding, all corners and edges fully visible, large uninterrupted central label-safe zone.
>
> Lighting/mood: restrained edge emission, dark calm center, premium cyberpunk storm identity.
>
> Color palette: deep navy-black and gunmetal; controlled cyan to violet perimeter glow only.
>
> Materials/textures: continuous machined titanium bezel, one inset luminous conduit, subtle micro-circuit grain inside the center.
>
> Constraints: genuinely transparent background; no text, letters, numbers, icons or symbols; no green chroma; no cast shadow; no exterior lightning; no glow behind the object; no disconnected components; no separate side pods; no center jewel; no repeated modular decorations; no aspect-ratio mockup or UI screen.
>
> Avoid: segmented black grille bars, dashed-frame reading, calibration ticks, ruler marks, top-edge notches, repeated rail segments, dot arrays, screws, diamonds, bright cyan/magenta center fill, glassy candy surface, excessive bloom, fire, ice, gold, orange, white background, watermark.

## Secondary generation prompt

> Create one Neon Tempest SECONDARY button plate that is unmistakably the same continuous sculpted family as the accepted primary. Keep the same single-piece deep black-blue titanium silhouette, continuous solid outer outline, continuous recessed perimeter conduit and large uninterrupted label-safe center. Reduce energy and hierarchy: the cyan-to-violet perimeter conduit should be restrained, with a darker graphite-blue center and even fainter circuit grain. The center must remain darker than the Infernal Dominion center and suitable for white or pale-blue text. Output one complete front-orthographic button on genuine alpha transparency. No text, symbols, segmented grille bars, dashed border, calibration ticks, top notches, dots, screws, diamonds, center jewel, bright center fill, bloom, cast shadow, or watermark.

## Ultra and disabled prompts

Ultra requested the same geometry with a slightly richer perimeter current and narrow inner-rim reflection while keeping the center dark. Disabled requested the same geometry with a dormant, desaturated 15–20% residual conduit reflection. Both prompts explicitly required a true RGBA PNG with alpha-zero pixels outside the button and prohibited a checkerboard or opaque matte.

Both AI outputs were rejected because the generator baked a checkerboard into RGB instead of returning alpha. They are retained as:

- `rejected_neon_tempest_button_ultra_v1_baked_checkerboard.png`
- `rejected_neon_tempest_button_ultra_v2_baked_checkerboard.png`
- `rejected_neon_tempest_button_disabled_v1_baked_checkerboard.png`

The review-only ultra and disabled states are therefore deterministic, reversible grades of the accepted alpha primary/secondary masters. They are not runtime assets.

## Review derivation and acceptance

- Actual repository matrix: 36 native sizes, from 154×44 through 980×100.
- Review matrix: primary, secondary, ultra, and disabled at every native size; 144 PNGs total.
- Assembly: preserve authored end caps and stretch one undecorated center slice only. No repeated/tiled modules and no unrelated aspect-ratio stretching.
- Smallest-height review: 154×44, 172×44, 268×48, 166×58, and 980×58 checked at 100% native pixels.
- 154×44 retains one clean continuous outer metal frame and one continuous conduit. No separated side grille, dashed border, or calibration-tick reading remains.
- The 286×112 central text-safe-zone luma is 20.37 mean / 23.12 p95 for candidate primary, versus 33.09 / 43.47 for Infernal Dominion primary and 41.79 / 64.71 for the old Neon Tempest primary.
- White Chinese/English review copy remains legible in every inspected size. Review copy is contact-sheet-only and is not baked into the candidate textures.

## Phase 2 gate

Do not copy `staging_native/` into the runtime theme directory, change `themes.json`, generate `.import` files, run bulk Godot import/screenshots, or commit this work until the mainline `b2-complete` tag exists.
