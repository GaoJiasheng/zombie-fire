# UI / art Phase 2 repair summary

**Status: owned scope passed; two cross-lane items deferred.** Runtime assets and owned UI paths are integrated. Real-device and theme screenshot matrices are green; the Chinese store runtime title and unstable `battle_combo_*` test criterion remain outside this lane's file ownership.

| Item | Change | Final value / evidence |
|---|---|---|
| Neon buttons | Replaced all primary/secondary native rasters with the approved continuous graphite frame and cyan→violet recessed conductor; archived prior runtime PNGs under `source_refs/rejected_` | 36 sizes × 2 runtime semantics; 154×44 and 166×58 remain continuous at 100% |
| Neon free weapon fairness | Added the missing B1 family and routed `weapons.asset_root` | 8 weapons × icon/handheld/turret = 24; dimensions and alpha masks 24/24 identical to the canonical theme family |
| Theme title localization | Added Neon EN/ZH title assets and Chinese assets for Infernal, Polar and Gilded; menu resolves language-specific keys | 5 new 1040×340 RGBA runtime logos; exact text is locally typeset (`尸潮防线` / `ZOMBIE FIRE`) |
| Settings accessibility row | Width calculation now counts visible controls only | Two visible switches receive the two-column width instead of hidden-third-button width |
| Collection safe area | Horizontal gutter derives from safe-area-adjusted width and active card ruler | Character and catalog cards stay inside both ordinary and tall-device left/right safe bounds |
| Locked character copy | Replaced the repeated generic lock sentence with signature-skill teasers | Blaze: Meltdown; Frost: Glacier; Volt: Storm Chain; Vanguard fallback: Steel Rain |
| Upgrade copy | Changed owned runtime hints from `下级` to `下一级`; English term is `Next Level` | Base term plus compound pet/weapon/armor/chip/character hints covered |
| Multishot localization | Added exact Lv.4/Lv.5 effect strings | `3 Projectiles · Damage 8% · Spread 6°`; `4 Projectiles · Damage 2% · Spread 9°` |
| Main menu hierarchy | Start uses the 780×148 primary family; Arsenal/Settings remain 600×120 secondary steel-cyan controls | Action = primary; navigation/catalog = secondary |
| Map quick slots | Empty gear uses the existing dim socket ghost with a cyan plus; removed red `未装` badge | Armor/chip/pet/weapon empty-state language matches loadout |
| Warzone map | Rebuilt overview cards as content-driven two-column layouts; added 10 environment thumbnails, one-line summary, segmented progress, star counter and icon boss milestones | Removed locale-specific story/objective heights and the clipped absolute-position boss pair |
| Challenge buttons | Expanded the usable label area and set a compact authored dual-column font | Challenge label no longer clips its own container |
| Endless Horde | Replaced the divider-like strip with an independent animated card, best-loop badge and action CTA | 4 × 980×184 motion frames |
| Global typography | Raised the sole global scale only after the map refactor | `FONT_SCALE: 1.4 → 1.5`; smoke expectation updated from 30 to 32 for a 20px authored label |

## Owner copy list

- Global destination English alias: `精品军械库` now translates as `Apocalypse Arsenal`; empty state translates as `Apocalypse Arsenal Encrypted`.
- Runtime Chinese store page title still requires `meta/store/store.gd`, which is outside this lane's ownership. No store runtime file was touched.
- New map copy: `循环尸潮 · 金币结算 · 挑战最高轮数`, `最高 %d 轮`, `迎战`, `击破战区首领，推进防线`.
- One-line warzone summaries: `重启熔炉，切断尸潮路线`; `重启桥塔，封锁冰原通道`; `夺回工厂，恢复重弹补给`; `关闭生化泄漏源`; `重启主变压器`; `夺回地下换乘枢纽`; `夺回炼油区能源节点`; `封印圣堂裂隙`; `关闭轨道感染信号`; `攻入核心，终结尸潮信号`.
- New locked-character teasers are listed in the table above.

## Boundary-held items

- `battle_combo_*` instability is a screenshot-test criterion change in `tools/check_visual_screens.py`; that file is outside the allowed path set, so product art was deliberately not altered to chase the nondeterministic pixel value.
- The Chinese store runtime fallback remains untouched because `meta/store/` belongs to another lane. English localization is already unified within this lane's authorized data file.

## Verification snapshot

- Pass: visual assets (1092 sprites), App Store assets, contrast, App Store UI polish, localization, release strings, asset-pack validation (12055 files), data validation, `res://` reference validation, level-pressure validation and card-director simulation.
- Pass: `device_language_matrix_manifest.json` — 36/36 screens, 0 runtime audit issues and 0 image-analysis issues across 1080×1920 / 1320×2868 / 750×1334, Chinese and English, six owned routes.
- Pass: `theme_six_screen_manifest.json` — 24/24 screens, 0 issues across Neon Tempest / Infernal Dominion / Polar Aurora / Gilded Eclipse and six owned routes.
- Contact sheets: `four_theme_six_screen_contact_sheet.png` and `three_device_bilingual_six_screen_contact_sheet.png`.
- Smoke reaches an unrelated existing Frost signature balance assertion after the updated 1.5× typography assertion passes.
