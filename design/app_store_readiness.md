# App Store Readiness

## Current Verdict

Repository release-candidate ready; external App Store submission work remains.

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
- Help/settings overlay with sound toggle and reset-save confirmation.
- Candidate 1024 app icon at `assets/app/app_icon_1024.png`.
- Candidate launch image at `assets/app/launch_1080x1920.png`.
- Static privacy/support page drafts in `docs/public/`.
- App Store metadata in `docs/app_store_metadata_zh.md`.
- iPhone/iPad screenshot draft sets in `assets/appstore/screenshots/`.
- iOS privacy manifest draft at `ios/PrivacyInfo.xcprivacy`.
- Godot iOS/macOS export preset draft in `export_presets.cfg`.
- Release validation tools for data, assets, balance, App Store assets, and release strings.

## Blocking Before App Store Submission

- Real iOS device playtest and performance profiling.
- True device screenshots if generated screenshot drafts are not accepted for final submission.
- Public privacy policy URL and support URL.
- Apple Developer signing/export setup.
- App Store Connect metadata, age rating, review notes, and build upload.
- At least one full visible QA pass for representative early, mid, late, and Boss levels.

## Product Quality Gaps

- Balance: automated pressure and skill checks pass, but human tuning on real devices is still needed.
- UI polish: map/loadout/result are serviceable; final acceptance depends on real-device screenshots and touch comfort.
- Audio mix: all major sounds are wired, but relative loudness needs real-device tuning.
- Brand: current app icon passes technical checks, but final art taste remains a human approval item.
- Accessibility: no explicit text scaling, color-blind pass, or haptic settings yet.

## Recommended Release Bar

Before calling it App Store ready:

- Representative manual pass for levels 1, 5, 10, 20, 50, 75, and 99.
- No crashes in 30-minute continuous play.
- Stable 60 FPS target on at least one real iPhone.
- App icon, screenshots, privacy/support pages, and App Store Connect metadata finalized.
- At least 3 people complete levels 1-10 without instruction.
- QA checklist in `design/app_store_qa_checklist.md` is complete.
