# iPhone App Store Owner TODO

Everything that can be completed and validated locally is owned by the repository checks. The following items require the App Store owner, Apple account, public hosting, or physical devices.

## Required Before Upload

- [x] Host `docs/public/privacy.html` and `docs/public/support.html` on public HTTPS URLs through GitHub Pages.
- [ ] Enter `https://blog.gavingao.cn/zombie-fire/privacy.html` and `https://blog.gavingao.cn/zombie-fire/support.html` in App Store Connect.
- [ ] Complete App Store Connect metadata, category, age-rating questionnaire, app-privacy answers, review notes, and contact details using `docs/app_store_metadata_zh.md` as the draft.
- [ ] Confirm the final app name, subtitle, icon, five iPhone 6.7-inch screenshots, five iPhone 6.5-inch screenshots, and App Preview candidate.
- [ ] Confirm Apple Developer team, distribution certificate, provisioning, and App Store Connect API-key access on the release Mac.

## Physical iPhone Sign-Off

- [ ] Test one small supported iPhone, one standard iPhone, and one Pro Max-class iPhone in portrait orientation.
- [ ] Verify fresh install, save migration, background/resume, relaunch persistence, and reset/backup/restore.
- [ ] Play levels 1, 5, 10, 20, 50, 75, 95, and 99 plus one challenge run and at least three Endless loops.
- [ ] Verify touch targets, safe areas, long-press skill details, double-tap lock, 2X/5X progression gates, reduced effects, haptics, and all three volume controls.
- [ ] Run 30 minutes continuously and sign off frame pacing, heat, battery use, memory, speaker/headphone mix, text legibility, color readability, firing poses, and VFX clarity.

## Final Release Action

- [ ] After the checks above are signed off, run `tools/ship_testflight.sh` and confirm App Store Connect reports the uploaded build as processed.
