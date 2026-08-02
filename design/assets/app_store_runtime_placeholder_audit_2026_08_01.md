# App Store Runtime Placeholder Audit · 2026-08-01

## Release bar

Every image visible in the shipping runtime must read as finished raster art at 1080×1920 / tall-iPhone scale. Simple line / circle / triangle constructions may remain only when they are semantic overlays whose geometry is the information itself, such as target locks, threat boundaries, real projectile trajectories and area limits. They may not substitute for a skill, hit, state, character, weapon, zombie, Boss, button, panel, logo or environmental illustration.

## Coverage

- Rebuilt a labeled peak-frame matrix for all `101` referenced runtime VFX sequences; the gate currently reads `850` non-empty referenced frames.
- Rebuilt a five-sheet matrix for all `102` unique base runtime UI rasters (native-size button duplicates excluded) and inspected the active icon / surface family at original alpha resolution.
- Rechecked active hero / weapon / zombie / Boss / pet, environment, HUD, card, collection, store, theme and native-button assets through the existing asset, reference, animation, gameplay-polish and routed-screen gates.
- Rechecked all five visible menu treatments: Default, Neon Tempest, Infernal Dominion, Polar Aurora and Gilded Eclipse.
- Kept legacy `_prototype.png` filenames because IDs and references are frozen. Those paths now contain accepted rendered runtime art; the suffix is not evidence that a placeholder is still displayed.

## Findings and replacements

| Runtime ID / surface | Finding | Final treatment |
|---|---|---|
| `vfx_status_golden_law_judgment` | Thin diagram-like status seal | Dedicated forged sovereign crest, liquid-gold body aura and open target center |
| `vfx_apocalypse_golden_law_falcon` | Simple directional mark / triangle language | Independent mechanical falcon dive master, explicit top-to-bottom beak direction |
| `vfx_apocalypse_golden_law_counter` | Straight upward geometry | Independent mirror-black aegis and rising liquid-gold counter plume |
| `vfx_apocalypse_golden_law_awakening` | Circle / line mantle | Independent black-sun sovereign mantle, open rear-layer hero channel |
| `vfx_enemy_skill_enrage` | Generic centered starburst | Molten claw corona, placed behind the enemy so the zombie remains readable |
| `vfx_levelup_glow` | Generic disconnected glow bursts | One coherent gold-cyan ascension column with an actor-safe center |
| Character passive detail icon | Hard-coded `◆` fallback was visible on every hero passive row | Uses each hero's finished elemental badge; an invalid dynamic path now falls back to the rendered talent-point icon |
| Infernal menu title | Style-board border and neighbouring panel entered the enlarged crop | Rebuilt from the isolated title region and retained the theme's dark-key material |
| Polar menu title | Lower crest and board divider entered the enlarged crop | Rebuilt from the isolated upper wordmark only |
| All theme menu titles | Effective title pixels were too small | Tight-alpha presentation inside the enlarged `1040×560` title envelope; no geometric stretching |
| 14 core HUD icons | Gold / star / XP / element / system symbols were flat geometry inside one repeated gray tile | Independent deeply rendered machined-metal currency, elemental and system objects on transparent 256×256 guard bands |
| 13 tactical/card icons | Pin / reroll / skip / tag / targeting / star symbols repeated the same flat tile language | Independent rendered tactical objects with distinct silhouettes for projectile, control, economy, breach, elite, low-HP and nearest semantics |
| 5 HUD surfaces | Pill, plate, damage badge, combo and level card were unrelated fragments cropped from a concept sheet | Five native-ratio smoked-glass/gunmetal frames; corners remain undistorted and only quiet center spans extend |
| Neon button borders | Cyan/magenta border bloom competed with copy | Geometry retained; border luminance, saturation and partial-alpha bloom reduced only inside Neon button rasters |

## Intentionally retained semantic geometry

- Manual target lock, off-screen threat indicator and area boundary: player-facing targeting information.
- Textured `Line2D` projectile / penetration / chain traces: they follow real runtime source-to-destination vectors and are not static skill illustrations.
- Slow-field perimeter: communicates the true gameplay area; the field interior, runes and particles remain raster / shader-authored.
- TextureButton nine-patch / native-size layout logic: layout behavior only; visible surfaces are raster assets.
- Cooldown sweep / target-lock reticle / map scroll accent: live state and targeting geometry, not an illustration substitute.

These are accepted only while they remain attached to their gameplay vector or area. `check_combat_vfx_semantics.py` locks movement direction, alpha guard bands, unique silhouettes and the six rendered-master source paths so a future rebuild cannot silently fall back to procedural placeholder art.

## Non-runtime boundary

The existing `replace_later` list still names final hand-cut skeletal parts and final audio mastering. The current battle uses raster animation frames rather than those optional skeletal parts, so no unfinished skeletal cutout is visible in the release runtime. Optional narrative CG outside the current release scope is likewise not presented as a shipping screen.

## Evidence

- Peak-frame sheets: `assets/production/contact_sheets/vfx_placeholder_audit_2026_08_01/`
- UI raster sheets: `assets/production/contact_sheets/ui_placeholder_audit_2026_08_01/`
- UI rendered masters, prompt log and 32-output manifest: `assets/production/source_refs/generated/app_store_ui_placeholder_replacements_2026_08_01/`
- Generic rendered masters and contact sheet: `assets/production/source_refs/generated/app_store_placeholder_audit_2026_08_01/`
- Golden Law masters and contact sheet: `assets/production/source_refs/generated/premium_black_gold_golden_law_phase4_2026_08_01/`
- Real menu / combat captures: retained outside the product pack in the Codex visual artifact directory for this task.
