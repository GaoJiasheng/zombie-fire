# App Store Readiness

## Current Verdict

Repository-side iPhone release-candidate work is complete; owner-controlled App Store submission work remains.

The current repository build has the local app, asset, metadata, and validation pieces expected for a release-candidate pass. It still cannot be called submitted or App Store ready until signing, public URLs, real-device QA, and App Store Connect setup are completed.

## Done In Project

- Complete menu -> map -> loadout -> battle -> result flow.
- 99 playable campaign levels.
- Save progression, level unlocks, stars, gold, equipment selection, pets, and weapon upgrades.
- Weapon upgrade affects combat damage and fire rate instead of only changing UI text.
- First-clear reward is only granted on first clear.
- BGM/SFX wiring.
- Skill cards with icon, text, tags, and details.
- Enemy animation, HP bars, combat VFX, reward float text.
- Settings with independent music/effects/interface volume, reduced-effects mode, haptics toggle, quality mode, and reset-save confirmation.
- Redesigned high-end 1024 app icon at `assets/app/app_icon_1024.png`, with previous candidate backed up in `assets/app/app_icon_1024_before_redesign_2026_07_01.png`.
- Candidate launch image at `assets/app/launch_1080x1920.png`.
- Static privacy/support page drafts in `docs/public/`.
- App Store metadata in `docs/app_store_metadata_zh.md`.
- iPhone screenshot sets in `assets/appstore/screenshots/` (the current release is iPhone-only).
- iOS privacy manifest draft at `ios/PrivacyInfo.xcprivacy`.
- iPhone-only Godot iOS export preset in `export_presets.cfg`; generated Xcode projects are checked for `TARGETED_DEVICE_FAMILY=1`.
- Owner-selected Glow Sans SC / 未来荧黑 Normal Medium global UI font, with the official SIL OFL 1.1 notice and provenance forced into the release PCK.
- Release validation tools for data, assets, balance, animation motion, 5X battle stress, App Store assets, package contents, and release strings.

## Blocking Before App Store Submission

- Real iOS device playtest and performance profiling.
- Final owner approval of the refreshed current-build iPhone screenshots.
- Public privacy policy URL and support URL.
- Apple Developer signing/export setup.
- App Store Connect metadata, age rating, review notes, and build upload.
- At least one physical-iPhone QA pass for representative early, mid, late, Boss, challenge, and Endless levels.

## Product Quality Gaps

- Balance: automated pressure, campaign-duration, skill, and 5X stress checks pass; final feel still needs physical-device playtesting.
- UI polish: routed tall-screen and safe-area screenshots pass; final acceptance depends on real-device touch comfort.
- Audio mix: independent buses, concurrency limits, and loop checks pass; speaker/headphone loudness still needs real-device tuning.
- Brand: redesigned app icon now passes technical checks and better reflects the turret-vs-horde core fantasy; final taste approval remains a human sign-off item.
- Accessibility: reduced-effects and haptics controls are implemented; color-only communication and text legibility still need a human device pass.

## Recommended Release Bar

Before calling it App Store ready:

- Representative manual pass for levels 1, 5, 10, 20, 50, 75, and 99.
- No crashes in 30-minute continuous play.
- Stable 60 FPS target on at least one real iPhone.
- App icon, screenshots, privacy/support pages, and App Store Connect metadata finalized.
- At least 3 people complete levels 1-10 without instruction.
- QA checklist in `design/app_store_qa_checklist.md` is complete.
