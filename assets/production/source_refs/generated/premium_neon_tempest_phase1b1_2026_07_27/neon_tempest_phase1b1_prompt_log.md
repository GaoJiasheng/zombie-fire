# Neon Tempest Phase 1B-1 prompt and acceptance log

Date: 2026-07-27

## Runtime rule

The same button texture must never be stretched across unrelated aspect ratios.
Six independently generated structural families are used: short, compact,
standard, long, ultra-long and the special 17:1 HUD ribbon. Each complete model
is uniformly scaled and centered inside its exact runtime dimensions. Small ratio
differences become transparent inset, never horizontal stretch, frame cropping,
or repeated ornaments.

## Shared prompt

> Premium mobile game UI asset, Neon Tempest theme matching an approved AAA
> post-apocalyptic sci-fi tower defense: black titanium composite, layered
> gunmetal bevels, electric cyan edge light, restrained ultraviolet and magenta
> conductive accents, tiny luminous circuit seams, precision-machined corners,
> high contrast readable silhouette at phone scale. Flat pure chroma green
> #00FF00 background only, no environment, no lightning outside the object, no
> cast shadow beyond the object, no text, no letters, no numbers, no symbols, no
> icons, no watermark. Exactly two separate button plates centered vertically
> with generous green space between them: TOP is primary with brighter
> cyan-to-violet energized core and a small central diamond power node integrated
> into the frame; BOTTOM is secondary with darker graphite center, subtle
> cyan-violet rails, same premium construction. The two plates must be separate
> complete native models, not a stretched copy. Front orthographic view,
> pixel-crisp symmetrical game UI sprite, complete frame fully visible with large
> safe central label area.

Family suffixes:

- Short: purpose-built compact geometry, large armored end caps, one center chassis.
- Standard: about 5:1, two internal rail segments.
- Long: about 6.8:1, reinforced span and three internal rail segments.
- Ultra-long: low-profile command strip and four internal rail segments.
- HUD ribbon: purpose-built 17:1 low-profile frame for the 980×58 control.

## Rejected pass

`rejected_neon_button_short_source_v1_too_long.png` was rejected as a short
back/action control because its silhouette remained too long. The same geometry
is valid as the independently named `compact` family for 3.0–4.35 ratios. The
short family was regenerated as separate primary and secondary single-button
models. The first runtime contact sheet that repeated center modules was also
rejected because visible repeated diamonds read like copied tiles; current
runtime assets contain no repeated or spliced frame segments.

## Acceptance checks

- Complete outer corners and end caps are visible.
- Primary and secondary are separately rendered states, not brightness filters.
- Center label areas contain no baked text or icons.
- Exact-size runtime images match their control dimensions.
- Runtime uses keep-aspect drawing and never `STRETCH_SCALE`.
- Chroma removal leaves transparent outer pixels and no material green fringe.
