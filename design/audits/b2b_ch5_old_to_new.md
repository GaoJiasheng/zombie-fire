# B2b Chapter 5 old → new

Authoritative fixture: Tier B, card policy v2.1, seeds `1103,2207,3301,4409,5519,6637,7741,8851,9973,11027`.
Runtime evidence: `design/audits/b2b_final_ch5_tier_b_10_v21.json`.

| Level | difficulty_coef | W4/W5 hp_coef | W4/W5 bodies | offer floor | median progress | median base | wins |
|---:|---:|---:|---:|---|---:|---:|---:|
| 041 | 2.33→1.6951 | 1/1→1/1 | 41/28→41/28 | — | 44.78% | 100.00% | 10/10 |
| 042 | 2.0005→5.3308 | 1/1→1/1 | 50/28→50/28 | compatible_crowd | 56.46% | 100.00% | 10/10 |
| 043 | 2.381→5.8 | 1/1→1/1 | 50/29→50/29 | compatible_crowd | 55.08% | 100.00% | 10/10 |
| 044 | 1.8092→4.9364 | 1/1→1/0.65 | 52/29→52/29 | compatible_crowd | 54.68% | 100.00% | 10/10 |
| 045 | 2.4265→3.5056 | 1/1→0.5/0.7 | 50/24→50/20 | single_target | 69.98% | 100.00% | 10/10 |
| 046 | 3.31→4.8 | 1/1→0.55/1 | 52/29→52/16 | compatible_crowd | 56.18% | 100.00% | 10/10 |
| 047 | 2.7691→14.0 | 1/1→1/1 | 52/30→52/30 | compatible_crowd | 61.84% | 100.00% | 10/10 |
| 048 | 2.796→8.0 | 1/1→1.1/1.4 | 56/30→38/54 | compatible_crowd | 91.81% | 100.00% | 10/10 |
| 049 | 2.825→6.3 | 1/1→1.2/2 | 42/29→48/40 | compatible_crowd | 93.97% | 100.00% | 10/10 |
| 050 | 2.6201→5.7843 | 1/1→6.2/6.04 | 64/34→32/9 | compatible_crowd | 94.10% | 83.84% | 10/10 |

Level 050 freezes the Plague Mother family at `fixed_hp=450000`, `bd_coef=1.5`, poison resistance `50%`.
The second Mother keeps `spawn_delay=1.0`, which becomes an effective ≈11s stagger behind the authored support queue.
Its final W4 uses 15 spitters for bounded base damage and one trailing shambler for progress; minimum base ratio is 9.67% in the combined Chapter 5 sweep and median Boss phase is 55.37s.
