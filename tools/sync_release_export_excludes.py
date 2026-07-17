#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import re
import tempfile
from pathlib import Path

from release_export_rules import (
    ROOT,
    ReleaseExportRuleError,
    generated_vfx_tail_paths,
    is_generated_vfx_tail_exclude,
    required_release_excludes,
)

PRESET_PATH = ROOT / "export_presets.cfg"


class SyncError(RuntimeError):
    pass


def ios_preset_bounds(text: str) -> tuple[int, int]:
    start = text.find("[preset.0]")
    end = text.find("[preset.0.options]", start)
    if start < 0 or end < 0:
        raise SyncError("could not isolate the iOS preset in export_presets.cfg")
    return start, end


def synchronized_text(text: str) -> tuple[str, int, int]:
    start, end = ios_preset_bounds(text)
    section = text[start:end]
    match = re.search(r'^exclude_filter="([^"]*)"$', section, re.MULTILINE)
    if match is None:
        raise SyncError("iOS preset has no single-line exclude_filter")
    current = [item.strip() for item in match.group(1).split(",") if item.strip()]
    retained = [item for item in current if not is_generated_vfx_tail_exclude(item)]
    required = required_release_excludes()
    merged = list(dict.fromkeys(retained))
    merged.extend(sorted(required - set(merged)))
    replacement = ",".join(merged)
    updated_section = section[: match.start(1)] + replacement + section[match.end(1) :]
    return text[:start] + updated_section + text[end:], len(required), len(generated_vfx_tail_paths())


def write_atomic(path: Path, text: str) -> None:
    mode = path.stat().st_mode
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=path.parent, delete=False) as handle:
        temporary = Path(handle.name)
        handle.write(text)
    os.chmod(temporary, mode)
    temporary.replace(path)


def main() -> int:
    parser = argparse.ArgumentParser(description="Synchronize safe iOS release-only asset exclusions")
    parser.add_argument("--write", action="store_true", help="update export_presets.cfg instead of checking it")
    args = parser.parse_args()
    try:
        original = PRESET_PATH.read_text(encoding="utf-8")
        updated, required_count, tail_count = synchronized_text(original)
        if updated != original:
            if not args.write:
                raise SyncError("iOS release excludes are stale; run tools/sync_release_export_excludes.py --write")
            write_atomic(PRESET_PATH, updated)
            action = "updated"
        else:
            action = "already synchronized"
        tail_bytes = sum((ROOT / path).stat().st_size for path in generated_vfx_tail_paths())
        print(
            f"iOS release excludes {action}: {required_count} rules, {tail_count} unused VFX tail frames, "
            f"{tail_bytes / 1024 / 1024:.1f} MiB source kept outside the package"
        )
    except (OSError, ReleaseExportRuleError, SyncError) as exc:
        print(f"Release export exclude sync failed: {exc}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
