# iPhone App Store Owner TODO

Everything that can be completed and validated locally is owned by the repository checks. The following items require the App Store owner, Apple account, public hosting, or physical devices.

## App Store Connect Setup

- [x] Host `docs/public/privacy.html` and `docs/public/support.html` on public HTTPS URLs through GitHub Pages.
- [x] Enter `https://blog.gavingao.cn/zombie-fire/privacy.html` and `https://blog.gavingao.cn/zombie-fire/support.html` in App Store Connect.
- [x] Complete the app name, subtitle, description, keywords, category, age-rating questionnaire, review notes, public/review contact details, and no-login declaration.
- [x] Publish App Privacy as `Data Not Collected`, consistent with the offline build and the public privacy policy.
- [x] Upload five iPhone 6.7-inch screenshots and five iPhone 6.5-inch screenshots; App Store Connect reports all ten assets complete.
- [ ] Confirm the uploaded iPhone 6.7-inch App Preview after Apple video processing reaches complete.
- [x] Confirm Apple Developer team, distribution certificate, provisioning, and App Store Connect API-key access on the release Mac through the signed Build 33 upload.

## Owner Legal And Commerce Decisions

- [ ] Select the App Store price (free or a paid tier) and sales territories. No price or availability schedule is currently configured.
- [ ] Declare the EU Digital Services Act trader/non-trader status. This is a legal owner declaration and must not be inferred by the build pipeline.
- [ ] Confirm all required agreements are active and, if a paid tier is selected, complete tax and banking information.

## Physical iPhone Sign-Off

- [ ] Test one small supported iPhone, one standard iPhone, and one Pro Max-class iPhone in portrait orientation.
- [ ] Verify fresh install, save migration, background/resume, relaunch persistence, and reset/backup/restore.
- [ ] Play levels 1, 5, 10, 20, 50, 75, 95, and 99 plus one challenge run and at least three Endless loops.
- [ ] Verify touch targets, safe areas, long-press skill details, double-tap lock, 2X/5X progression gates, reduced effects, haptics, and all three volume controls.
- [ ] Run 30 minutes continuously and sign off frame pacing, heat, battery use, memory, speaker/headphone mix, text legibility, color readability, firing poses, and VFX clarity.

## Final Release Action

- [x] Run `tools/ship_testflight.sh` for `1.0.0 (33)` and receive a successful upload result from App Store Connect.
- [x] Confirm Build 33 processing reaches `VALID / APP_STORE_ELIGIBLE` and associate it with App Store version `1.0.0`.
- [ ] After physical-device, legal, commerce, and processed-build checks are signed off, submit version `1.0.0` for App Review.
