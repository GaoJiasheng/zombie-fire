# Global UI / Warzone Map — Phase 1 source log

Date: 2026-08-30
Scope: generation and review only; no runtime texture, scene, localization, data, or code integration.

## A. Warzone thumbnail family

The ten 420×144 candidates are deterministic crops from the ten existing battle-background assets referenced by `data/environments.json`. Each crop uses the same horizon/subject framing, a 12 px continuous left accent rail, and a restrained right-side readability veil. No new world art or gameplay information was invented.

Accent sequence: lava `#FF9B42`; glacier `#66D9FF`; factory `#A8B7C7`; toxic `#83E86C`; storm `#B878FF`; flooded `#40C7C8`; desert `#E7B04A`; void `#A56BFF`; orbital `#5EA7FF`; apex `#FF655E`.

Prohibited: text, progress values, boss labels, segmented/dashed frames, newly painted landmarks, theme-specific button chrome, or changes to the underlying runtime backgrounds.

## B. Endless Horde card background

References:

- `assets/m1_visual/contact_sheets/contact_zombies_t1_t2.png` for established enemy silhouettes and proportions.
- `tmp/final_polish_audit_2026_07_27/02_map.png` for map palette, value range, and overlay legibility.

Generation brief: wide 3:1 independent-card background; dense zombie wave advancing down a ruined urban avenue; layered distant swarm, readable midground silhouettes, and cropped foreground shadows; subtle motion streaks and ash; dark blue-black/gunmetal base with restrained cyan rim light and sparse copper embers; calm dark center-right reserved for title, record, and CTA overlays; painterly premium game-UI finish rather than photorealism.

Prohibited: words, letters, numbers, logos, watermarks, badges, buttons, borders, segmented rails, tick marks, dashed lines, checkerboards, bright white center, rainbow neon, large portrait faces, gore, or muzzle flashes.

Accepted source: `endless_horde_card_background_candidate_v1.png` (2172×724 RGB). Four 980×184 review frames apply only small vertical offsets and ±4% brightness variation to demonstrate a low-amplitude looping treatment; actual animation hookup remains a Phase 2 implementation decision.

## C. Minor / major boss badges

References are the same zombie contact sheet and map screenshot. The source board requested exactly two isolated emblems on pure chroma green:

- Minor boss: compact gunmetal shield, amber/copper hazard language, single crownless upper spike, restrained cyan rim.
- Major boss: heavier black-steel shield, crimson inlay, copper-gold three-prong crown, stronger threat silhouette.

Shared requirements: continuous sculpted contour, hard-surface metal, symmetric centered silhouette, readable at 48–64 px, consistent perspective/material family.

Prohibited: text, letters, numbers, logos, ribbons, rectangular buttons, segmented rails, tick marks, dashed outlines, scenery, extra objects, gore, white/checkerboard backgrounds.

The first chroma key left low-value green noise and was rejected during review. The accepted RGBA candidates use a tightened green-dominance key and were checked against both black and white backgrounds before the 48/64 px sheet was produced.

## Acceptance snapshot

- 10/10 thumbnails: exact 420×144.
- 4/4 Endless Horde motion-review frames: exact 980×184.
- Both boss badges: RGBA with transparent exterior; visually distinct at 48 px.
- Menu/map before and after proposal screens: exact 1080×1920.
- Runtime integration: intentionally not performed; `b2-complete` gate is still absent.
