# B2b Fixture Regeneration and 061–099 Repair List

Status: recorded only; no Stage 061–099 tuning is included in this checkpoint.

## Fixture regeneration

- Old comparison source: `ccdf9db4:design/audits/campaign_progression_fixture_builds.json` (fixture before the B2a 061–099 enemy-count rebuild).
- New source: `design/audits/campaign_progression_fixture_builds.json`, regenerated from the current 99-stage data with `audit_campaign_frontline.py --write`.
- A second regeneration produced zero diff (idempotent).
- Changed progression builds: 71/99 overall; 39/39 in Stages 061–099.
- Same-seed runtime rows changed versus the B2a acceptance evidence: 117/117.
- Full 99-stage slot/level/resource comparison: `design/audits/b2b_fixture_build_old_to_new.csv`.

The drift is expected coupling: rebuilt waves change kill rewards, which changes later purchases and upgrade allocation. It is not evidence that B2a data should be retuned before Chapters 1–5 are rebuilt.

## Tier-B three-seed scan (new fixture)

Seeds: 1103 / 2207 / 3301. Target-band misses and losses enter the B2b final repair list; passing stages remain frozen.

| Stage | Target | Median progress | Median base | Worst base | Wins | Median duration | Boss phase | Result | Reason |
|---:|---|---:|---:|---:|---:|---:|---:|---|---|
| 061 | light_pressure | 46.02% | 100.00% | 100.00% | 3/3 | 100.77s | 0.00s | repair | progress 46.02 < 52.00 |
| 062 | light_pressure | 86.82% | 99.09% | 98.99% | 3/3 | 111.53s | 0.00s | repair | progress 86.82 > 78.00; base 99.09 < 100.00 |
| 063 | light_pressure | 63.33% | 100.00% | 100.00% | 3/3 | 110.18s | 0.00s | pass | in target band |
| 064 | light_pressure | 65.99% | 100.00% | 100.00% | 3/3 | 130.22s | 0.00s | pass | in target band |
| 065 | pressure | 95.42% | 73.35% | 49.42% | 3/3 | 145.62s | 61.92s | pass | in target band |
| 066 | pressure | 100.00% | 43.24% | 0.00% | 2/3 | 185.65s | 0.00s | repair | wins 2/3; progress 100.00 > 98.00 |
| 067 | pressure | 100.00% | 0.00% | 0.00% | 1/3 | 145.67s | 0.00s | repair | wins 1/3; progress 100.00 > 98.00; base 0.00 < 35.00 |
| 068 | pressure | 94.63% | 83.87% | 67.00% | 3/3 | 215.70s | 0.00s | pass | in target band |
| 069 | pressure | 71.46% | 91.07% | 87.68% | 3/3 | 140.98s | 0.00s | repair | progress 71.46 < 80.00 |
| 070 | high | 100.00% | 59.11% | 59.04% | 3/3 | 127.12s | 61.35s | pass | in target band |
| 071 | light_pressure | 51.76% | 100.00% | 100.00% | 3/3 | 110.65s | 0.00s | repair | progress 51.76 < 52.00 |
| 072 | light_pressure | 72.21% | 100.00% | 100.00% | 3/3 | 82.75s | 0.00s | pass | in target band |
| 073 | light_pressure | 53.25% | 100.00% | 100.00% | 3/3 | 101.22s | 0.00s | pass | in target band |
| 074 | pressure | 80.87% | 99.82% | 76.24% | 3/3 | 163.48s | 0.00s | repair | base 99.82 > 95.00 |
| 075 | high | 96.19% | 72.92% | 67.10% | 3/3 | 180.42s | 75.10s | repair | progress 96.19 < 100.00; base 72.92 > 65.00 |
| 076 | pressure | 60.72% | 98.83% | 97.57% | 3/3 | 134.33s | 0.00s | repair | progress 60.72 < 80.00; base 98.83 > 95.00 |
| 077 | pressure | 64.94% | 97.33% | 90.40% | 3/3 | 139.37s | 0.00s | repair | progress 64.94 < 80.00; base 97.33 > 95.00 |
| 078 | pressure | 77.99% | 92.96% | 87.68% | 3/3 | 172.32s | 0.00s | repair | progress 77.99 < 80.00 |
| 079 | pressure | 87.79% | 91.46% | 81.97% | 3/3 | 125.02s | 0.00s | pass | in target band |
| 080 | high | 96.42% | 95.80% | 48.39% | 3/3 | 135.78s | 63.43s | repair | progress 96.42 < 100.00; base 95.80 > 65.00 |
| 081 | light_pressure | 60.38% | 100.00% | 100.00% | 3/3 | 98.43s | 0.00s | pass | in target band |
| 082 | light_pressure | 61.86% | 100.00% | 100.00% | 3/3 | 126.23s | 0.00s | pass | in target band |
| 083 | pressure | 100.00% | 91.60% | 90.35% | 3/3 | 147.22s | 0.00s | repair | progress 100.00 > 98.00 |
| 084 | pressure | 74.14% | 98.47% | 77.52% | 3/3 | 126.10s | 0.00s | repair | progress 74.14 < 80.00; base 98.47 > 95.00 |
| 085 | high | 100.00% | 80.00% | 71.62% | 3/3 | 193.35s | 76.87s | repair | base 80.00 > 65.00 |
| 086 | pressure | 74.41% | 99.37% | 93.37% | 3/3 | 147.88s | 0.00s | repair | progress 74.41 < 80.00; base 99.37 > 95.00 |
| 087 | pressure | 75.37% | 90.95% | 89.52% | 3/3 | 127.53s | 0.00s | repair | progress 75.37 < 80.00 |
| 088 | pressure | 76.78% | 96.32% | 96.12% | 3/3 | 112.85s | 0.00s | repair | progress 76.78 < 80.00; base 96.32 > 95.00 |
| 089 | pressure | 34.63% | 100.00% | 100.00% | 3/3 | 91.42s | 0.00s | repair | progress 34.63 < 80.00; base 100.00 > 95.00 |
| 090 | high | 100.00% | 94.49% | 87.38% | 3/3 | 104.02s | 79.35s | repair | base 94.49 > 65.00 |
| 091 | light_pressure | 62.46% | 100.00% | 100.00% | 3/3 | 107.75s | 0.00s | pass | in target band |
| 092 | pressure | 84.09% | 97.17% | 84.06% | 3/3 | 135.97s | 0.00s | repair | base 97.17 > 95.00 |
| 093 | pressure | 95.13% | 92.91% | 91.48% | 3/3 | 160.73s | 0.00s | pass | in target band |
| 094 | pressure | 99.35% | 90.66% | 68.36% | 3/3 | 132.23s | 0.00s | repair | progress 99.35 > 98.00 |
| 095 | high | 100.00% | 95.61% | 93.25% | 3/3 | 131.52s | 89.67s | repair | base 95.61 > 65.00 |
| 096 | pressure | 100.00% | 61.99% | 53.45% | 3/3 | 174.57s | 0.00s | repair | progress 100.00 > 98.00 |
| 097 | pressure | 86.02% | 94.29% | 78.23% | 3/3 | 119.38s | 0.00s | pass | in target band |
| 098 | pressure | 99.49% | 98.20% | 96.37% | 3/3 | 151.47s | 0.00s | repair | progress 99.49 > 98.00; base 98.20 > 95.00 |
| 099 | high | 79.03% | 99.26% | 95.57% | 3/3 | 204.98s | 147.65s | repair | progress 79.03 < 100.00; base 99.26 > 65.00 |

## B2b final repair list

26 stages currently miss their frozen band or clearability contract: 061, 062, 066, 067, 069, 071, 074, 075, 076, 077, 078, 080, 083, 084, 085, 086, 087, 088, 089, 090, 092, 094, 095, 096, 098, 099.

Stages 066 and 067 contain same-seed losses and therefore take priority after Chapters 1–5 regenerate the fixture again. No repair is made at this checkpoint.

## Blade-stage base-margin recheck

This table uses the minimum runtime base ratio among the same three seeds, so old and new evidence are directly comparable.

| Stage | B2a minimum base | New-fixture minimum base | Delta | Note |
|---:|---:|---:|---:|---|
| 068 | 78.37% | 67.00% | -11.37pp | recorded |
| 080 | 32.84% | 48.39% | +15.54pp | recorded |
| 085 | 34.05% | 71.62% | +37.57pp | recorded |
| 095 | 17.67% | 93.25% | +75.59pp | recorded |
| 099 | 45.79% | 95.57% | +49.78pp | recorded |
