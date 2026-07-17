# App Store Submission Runbook

## Repository Checks

Run this before creating a release build:

```bash
python3 tools/check_release_candidate.py
```

The script validates assets, data, references, balance profile, App Store screenshot drafts, release strings, Godot startup, and the smoke flow.

## External Values To Replace

Before exporting, edit `export_presets.cfg`:

- `application/app_store_team_id`
- `application/provisioning_profile_uuid_release`
- `application/provisioning_profile_specifier_release`
- `application/bundle_identifier`
- `codesign/identity`

Use the published GitHub Pages URLs:

- Privacy policy: `https://blog.gavingao.cn/zombie-fire/privacy.html`
- Support page: `https://blog.gavingao.cn/zombie-fire/support.html`

## Store Assets

Draft screenshot sets are in:

- `assets/appstore/screenshots/ios_67/`
- `assets/appstore/screenshots/ios_65/`

The current release is iPhone-only. Do not upload the legacy iPad draft directory. Use physical-device captures instead if final review prefers true captured device output.

## Manual QA Gate

Before upload, complete `design/app_store_qa_checklist.md` on physical devices. At minimum, test:

- levels `1`, `5`, `10`, `20`, `50`, `75`, `95`, and `99`
- fresh install
- save persistence after relaunch
- independent volume, quality, reduced-effects, and haptics controls
- privacy/support panels
- collection equipment changes
- battle win/loss/retry/result flow
- speed unlocks: hidden below level 30, 2X from level 30, 5X from level 50
- background/resume save behavior
- 30-minute continuous play

## App Store Connect Notes

- The current build is offline.
- It does not collect personal data.
- It does not include ads, analytics, account login, in-app purchases, push notifications, or third-party tracking.
- Use the review notes in `docs/app_store_metadata_zh.md`.
