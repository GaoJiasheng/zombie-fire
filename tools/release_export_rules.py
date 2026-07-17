#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROD = ROOT / "assets/production"
VFX_SEQUENCE_ROOT = PROD / "sprites/vfx_sequences"

# Keep source and authoring assets in the repository, but never ship them in the
# runtime PCK. The VFX tail rules below are derived from each runtime manifest so
# a frame becomes shippable automatically as soon as the manifest references it.
STATIC_RELEASE_EXCLUDES = frozenset(
    {
        ".git/*",
        ".godot/*",
        "tmp/*",
        "build/*",
        "docs/*",
        "design/*",
        "tools/*",
        "scratchpad/*",
        "assets/m1_visual/*",
        "assets/sprites/*",
        "assets/appstore/*",
        "assets/app/app_icon_1024_before_redesign_2026_07_01.png*",
        "assets/production/environment/*",
        "assets/production/video/*",
        "assets/production/flow/*",
        "assets/production/source_refs/*",
        "assets/production/contact_sheets/*",
        "assets/production/sprites/parts/*",
        "extension_api.json",
        "*.md",
        "*.markdown",
    }
)


class ReleaseExportRuleError(RuntimeError):
    pass


def _load_sequence_manifest(directory: Path) -> dict:
    manifest_path = directory / f"{directory.name}_sequence.json"
    if not manifest_path.is_file():
        raise ReleaseExportRuleError(f"missing VFX sequence manifest: {manifest_path.relative_to(ROOT)}")
    try:
        parsed = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ReleaseExportRuleError(f"invalid VFX sequence manifest: {manifest_path.relative_to(ROOT)}: {exc}") from exc
    if not isinstance(parsed, dict) or parsed.get("id") != directory.name:
        raise ReleaseExportRuleError(f"invalid VFX sequence id: {manifest_path.relative_to(ROOT)}")
    frames = parsed.get("frames")
    if not isinstance(frames, list) or not frames or not all(isinstance(item, str) for item in frames):
        raise ReleaseExportRuleError(f"invalid VFX frame list: {manifest_path.relative_to(ROOT)}")
    return parsed


def runtime_vfx_frame_paths() -> tuple[str, ...]:
    paths: list[str] = []
    for directory in sorted(path for path in VFX_SEQUENCE_ROOT.iterdir() if path.is_dir()):
        manifest = _load_sequence_manifest(directory)
        for relative in manifest["frames"]:
            source = PROD / relative
            if not source.is_file():
                raise ReleaseExportRuleError(f"runtime VFX frame is missing: {source.relative_to(ROOT)}")
            paths.append(source.relative_to(ROOT).as_posix())
    return tuple(paths)


def generated_vfx_tail_paths() -> tuple[str, ...]:
    tails: list[str] = []
    for directory in sorted(path for path in VFX_SEQUENCE_ROOT.iterdir() if path.is_dir()):
        manifest = _load_sequence_manifest(directory)
        listed = {Path(item).name for item in manifest["frames"]}
        actual = sorted(directory.glob("*.png"))
        unlisted = [path for path in actual if path.name not in listed]
        if not unlisted:
            continue

        frame_pattern = re.compile(rf"^{re.escape(directory.name)}_(\d+)$")
        listed_numbers = sorted(
            int(match.group(1))
            for name in listed
            if (match := frame_pattern.fullmatch(Path(name).stem)) is not None
        )
        tail_numbers = sorted(
            int(match.group(1))
            for path in unlisted
            if (match := frame_pattern.fullmatch(path.stem)) is not None
        )
        actual_numbers = sorted(
            int(match.group(1))
            for path in actual
            if (match := frame_pattern.fullmatch(path.stem)) is not None
        )
        expected_listed = list(range(1, max(listed_numbers, default=0) + 1))
        expected_tail = list(range(max(listed_numbers, default=0) + 1, max(actual_numbers, default=0) + 1))
        if (
            len(listed_numbers) != len(listed)
            or len(tail_numbers) != len(unlisted)
            or listed_numbers != expected_listed
            or tail_numbers != expected_tail
        ):
            raise ReleaseExportRuleError(
                f"refusing to exclude non-tail VFX frames: {directory.relative_to(ROOT)}"
            )
        tails.extend(path.relative_to(ROOT).as_posix() for path in unlisted)
    return tuple(tails)


def generated_vfx_tail_excludes() -> tuple[str, ...]:
    # The suffix wildcard covers both the PNG and its tracked .png.import file.
    return tuple(f"{path}*" for path in generated_vfx_tail_paths())


def required_release_excludes() -> frozenset[str]:
    return STATIC_RELEASE_EXCLUDES | frozenset(generated_vfx_tail_excludes())


def is_generated_vfx_tail_exclude(pattern: str) -> bool:
    prefix = "assets/production/sprites/vfx_sequences/"
    return pattern.startswith(prefix) and pattern.endswith(".png*")
