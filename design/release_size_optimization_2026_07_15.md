# Release Size Optimization Audit (2026-07-15)

## Scope

Reduce repository churn and the iPhone/TestFlight payload without deleting production source art, lowering texture quality, changing animation timing, or changing gameplay behavior.

## Baseline

| Item | Before |
| --- | ---: |
| Signed App Store IPA | 706.3 MiB |
| Godot PCK | 678.2 MiB |
| `.git` object database | 13.49 GiB packed + 987.73 MiB loose |
| `tmp/` working artifacts | 1.8 GiB |
| `build/` generated artifacts | 1.7 GiB before this audit |
| Tracked files under `tmp/` | 1,098 files / 1,222.4 MiB |

The PCK was dominated by lossless runtime animation textures (324.4 MiB) and authored VFX sequences (186.6 MiB). Those live frames are intentionally preserved.

## Safe Package Exclusions

- `assets/production/sprites/parts/**`: 414 authoring cutouts used by local polish/generation tools, with no runtime references under `core/`, `gameplay/`, `meta/`, `ui/`, `data/`, `main.gd`, or `main.tscn`.
- 307 generated VFX tail-cache PNGs across 58 sequence folders. Their sequence JSON manifests do not list them, and `SequenceVfx` loads only the listed frame paths.
- Production PNGs and tracked `.png.import` metadata remain in the repository. No accepted art was deleted or recompressed.

`tools/release_export_rules.py` derives the VFX exclusions from the manifests. `tools/sync_release_export_excludes.py` synchronizes the ignored local `export_presets.cfg`; the release script runs it before the full candidate gate. If a tail frame is added to a runtime manifest, it is automatically restored to the next package.

## Result

| Item | Before | After | Saved |
| --- | ---: | ---: | ---: |
| Signed App Store IPA | 706.3 MiB | 613.2 MiB | 93.1 MiB / 13.2% |
| Godot PCK | 678.2 MiB | 584.9 MiB | 93.3 MiB / 13.8% |
| PCK entries | 7,319 | 5,831 | 1,488 |

The signed probe stayed at version `1.0.0` build `29` and was not uploaded. Package validation confirmed all runtime VFX manifest frames, import caches, iPhone-only keys, portrait/fullscreen settings, and byte-identical embedded/source PCK content.

## Repository Decision

`tmp/` is now ignored to prevent future QA captures from growing the tracked tree. Existing tracked `tmp/` history and the 13.49 GiB Git pack are not rewritten in this pass because the worktree contains active uncommitted art and gameplay changes. Shrinking historical Git storage requires a coordinated Git LFS/history migration and force push; it is intentionally separated from the no-risk release optimization.

After the current work is committed and backed up, the safe maintenance follow-up is:

1. Remove existing `tmp/` files from Git tracking while keeping any required local review evidence outside the repository.
2. Migrate historical PNG/MP4/WAV/TTF blobs to Git LFS on a maintenance branch.
3. Re-clone after the coordinated force push; local `git gc` alone cannot remove the currently reachable binary history.
