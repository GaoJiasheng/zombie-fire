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

Use the final public URLs for:

- Privacy policy: host `docs/public/privacy.html`.
- Support page: host `docs/public/support.html`.

## Store Assets

Draft screenshot sets are in:

- `assets/appstore/screenshots/ios_67/`
- `assets/appstore/screenshots/ios_65/`
- `assets/appstore/screenshots/ipad_129/`

Use real device screenshots instead if final review prefers true captured device output.

## Manual QA Gate

Before upload, complete `design/app_store_qa_checklist.md` on physical devices. At minimum, test:

- levels `1`, `5`, `10`, `20`, `50`, `75`, `95`, and `99`
- fresh install
- save persistence after relaunch
- sound/quality toggles
- privacy/support panels
- collection equipment changes
- battle win/loss/retry/result flow
- 30-minute continuous play

## App Store Connect Notes

- The current build is offline.
- It does not collect personal data.
- It does not include ads, analytics, account login, in-app purchases, push notifications, or third-party tracking.
- Use the review notes in `docs/app_store_metadata_zh.md`.
