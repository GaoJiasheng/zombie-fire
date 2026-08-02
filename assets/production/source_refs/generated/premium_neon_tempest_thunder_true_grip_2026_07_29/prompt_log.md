# Thunder Apocalypse true-grip hero integration

Date: 2026-07-29
Generator: OpenAI built-in image generation, precise object edit workflow

## Runtime intent

- Four locked heroes retain their established anatomy, hair, silhouette and role identity.
- The exact approved triple-coil Thunder Apocalypse cannon is held with two physically connected hands.
- Rear hand stays on the trigger / pistol grip; forward hand visibly supports the foregrip / barrel shroud.
- Stock or rear power block is braced into the shoulder; feet are wider than shoulder width and the torso leans into recoil.
- Camera remains the established three-quarter top-down rear battle view.
- Neon Tempest garment structure, graphite armor, cyan / violet conduit seams and prismatic material panels are baked into the static model.
- Animated rainbow flow, electrical arcs, muzzle light, recoil impulse and projectile effects are not baked into the bitmap and remain runtime VFX.
- No muzzle flash, smoke, tracer, projectile, lightning bolt, ground circle, UI, frame, text or scenery is present in the character master.
- Flat chroma-green background was requested for deterministic alpha extraction.

## Source generations

### Right-aim default-outfit grip proofs

- `char_vanguard_default_chroma.png`
- `char_blaze_default_chroma.png`
- `char_frost_default_chroma.png`
- `char_volt_default_chroma.png`

Prompt role: edit each accepted hero reference together with
`weapon_apocalypse_thunder_handheld.png`; replace the old or missing weapon
with the exact triple-coil cannon, correct both hand contacts and establish a
wide recoil-ready stance without changing the hero identity.

### Right-aim Neon Tempest masters

- `char_vanguard_neon_chroma.png`
- `char_blaze_neon_chroma.png`
- `char_frost_neon_chroma.png`
- `char_volt_neon_chroma.png`

Prompt role: preserve the approved true-grip anatomy and exact cannon, then
replace only the costume with the corresponding accepted Neon Tempest outfit.
The suit receives premium static conduits and material accents but no free-air
electricity or firing effect.

### Center-aim Neon Tempest masters

- `char_vanguard_neon_center_chroma.png`
- `char_blaze_neon_center_chroma.png`
- `char_frost_neon_center_chroma.png`
- `char_volt_neon_center_chroma.png`

Prompt role: rotate the complete hero-and-cannon action to aim straight toward
the top-center of the battlefield. Preserve a full-body rear view, both hand
contacts, shoulder brace, wide feet and the exact costume/cannon design.

## Derived files

`*_alpha.png` files are chroma-keyed archival masters. Runtime 380×520
left/center/right sprites are built by
`tools/build_apocalypse_true_grip_runtime.py`. Left aim is a deterministic
mirror of the approved right-aim action so geometry, scale and muzzle distance
remain perfectly paired.

## Blaze raised side-aim revision (2026-08-02)

- Source: `char_blaze_neon_raised_right_chroma_v2.png`
- Alpha master: `char_blaze_neon_raised_right_alpha_v2.png`
- Tool: OpenAI built-in image generation, precise-object-edit workflow; local
  chroma-key removal with soft matte and despill.
- Runtime scope: replaces only
  `char_blaze_apocalypse_attack_left.png` and
  `char_blaze_apocalypse_attack_right.png`; the accepted centre-aim sprite is
  rebuilt from its original source and remains byte-identical.
- Direction contract: the complete Thunder Apocalypse cannon is raised into a
  portrait-battlefield diagonal, with its neon barrel axis at least 40 degrees
  above horizontal. Both hands remain connected to the grip/foregrip, the rear
  three-quarter identity and full-body stance remain intact, and the left pose
  is an exact mirror of the reviewed right pose.

Final prompt: preserve the exact Neon Tempest Blaze Striker identity, costume,
body proportions, rear camera and Thunder Apocalypse cannon; rebuild only the
upper-body firing mechanics so the cannon points diagonally toward the upper
right, with naturally articulated shoulders, elbows, wrists, torso, head and
sight line. Keep a complete hair-to-boots silhouette with safe padding on a flat
green background. Do not add aura, wings, muzzle flash, projectile, smoke,
scenery, text or any baked effect.
