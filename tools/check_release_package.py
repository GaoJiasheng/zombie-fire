#!/usr/bin/env python3
from __future__ import annotations

import argparse
import fnmatch
import plistlib
import re
import struct
import sys
import zipfile
from dataclasses import dataclass
from pathlib import Path

try:
    from release_export_rules import required_release_excludes, runtime_vfx_frame_paths
except ModuleNotFoundError:  # Supports importing this checker as tools.check_release_package.
    from tools.release_export_rules import required_release_excludes, runtime_vfx_frame_paths

ROOT = Path(__file__).resolve().parents[1]
PRESET_PATH = ROOT / "export_presets.cfg"
EXPECTED_BUNDLE_ID = "com.gaojiasheng.zombiefire"

REQUIRED_EXCLUDES = required_release_excludes()
FORBIDDEN_PACK_PATTERNS = tuple(item for item in REQUIRED_EXCLUDES if not item.startswith(".godot/"))
FORBIDDEN_PACK_SUFFIXES = (
    ".ai",
    ".aseprite",
    ".blend",
    ".kra",
    ".markdown",
    ".md",
    ".psb",
    ".psd",
    ".py",
    ".sh",
    ".sketch",
    ".xcf",
)
MAX_PCK_BYTES = 1400 * 1024 * 1024
MAX_IPA_BYTES = 1600 * 1024 * 1024
MAX_PACK_FILES = 20_000
REQUIRED_FONT_PACKAGE_PATHS = {
    "assets/production/fonts/OFL-GlowSans.txt",
    "assets/production/fonts/font_main.provenance.json",
    "assets/production/fonts/font_main.ttf.import",
}


class PackageCheckError(RuntimeError):
    pass


@dataclass(frozen=True)
class PckEntry:
    path: str
    offset: int
    size: int
    flags: int


def preset_section(text: str, section: str) -> str:
    match = re.search(
        rf"^\[{re.escape(section)}\]\s*$\n(?P<body>.*?)(?=^\[|\Z)",
        text,
        re.MULTILINE | re.DOTALL,
    )
    if not match:
        raise PackageCheckError(f"missing [{section}] in export_presets.cfg")
    return match.group("body")


def preset_value(body: str, key: str) -> str:
    match = re.search(rf"^{re.escape(key)}=(.*)$", body, re.MULTILINE)
    if not match:
        raise PackageCheckError(f"missing {key} in iOS export preset")
    return match.group(1).strip().strip('"')


def check_preset() -> tuple[str, str]:
    text = PRESET_PATH.read_text(encoding="utf-8")
    preset = preset_section(text, "preset.0")
    options = preset_section(text, "preset.0.options")
    if preset_value(preset, "name") != "iOS Release Candidate":
        raise PackageCheckError("preset.0 is not the iOS Release Candidate")
    if preset_value(preset, "platform") != "iOS":
        raise PackageCheckError("preset.0 is not an iOS preset")
    if preset_value(preset, "export_filter") != "all_resources":
        raise PackageCheckError("iOS preset must use export_filter=all_resources")

    excludes = {item.strip() for item in preset_value(preset, "exclude_filter").split(",") if item.strip()}
    missing = sorted(REQUIRED_EXCLUDES - excludes)
    if missing:
        raise PackageCheckError(f"iOS preset is missing required excludes: {', '.join(missing)}")
    if preset_value(options, "application/export_project_only") != "true":
        raise PackageCheckError("iOS preset must export the Xcode project only; archive/export is owned by the release script")
    if preset_value(options, "application/targeted_device_family") != "0":
        raise PackageCheckError("iOS preset must target iPhone only (targeted_device_family=0)")

    bundle_id = preset_value(options, "application/bundle_identifier")
    build = preset_value(options, "application/version")
    short_version = preset_value(options, "application/short_version")
    if bundle_id != EXPECTED_BUNDLE_ID:
        raise PackageCheckError(f"unexpected bundle identifier: {bundle_id}")
    if not build.isdigit() or int(build) < 1:
        raise PackageCheckError(f"invalid iOS build number: {build}")
    if not re.fullmatch(r"\d+(?:\.\d+){1,2}", short_version):
        raise PackageCheckError(f"invalid iOS short version: {short_version}")
    print(f"iOS export preset passed: build={build}, version={short_version}, excludes={len(excludes)}")
    return build, short_version


def check_xcode_project(path: Path) -> None:
    pbxproj = path / "project.pbxproj" if path.suffix == ".xcodeproj" else path
    if not pbxproj.is_file():
        raise PackageCheckError(f"Xcode project file not found: {pbxproj}")
    text = pbxproj.read_text(encoding="utf-8")
    families = re.findall(r'TARGETED_DEVICE_FAMILY\s*=\s*"?([^";]+)"?;', text)
    if not families:
        raise PackageCheckError("Xcode project has no TARGETED_DEVICE_FAMILY setting")
    normalized = {value.strip() for value in families}
    if normalized != {"1"}:
        raise PackageCheckError(
            f"Xcode project must target iPhone only (TARGETED_DEVICE_FAMILY=1); found {sorted(normalized)}"
        )
    print(f"Xcode iPhone target passed: {len(families)} build configurations use TARGETED_DEVICE_FAMILY=1")


def read_u32(handle) -> int:
    raw = handle.read(4)
    if len(raw) != 4:
        raise PackageCheckError("truncated PCK directory")
    return struct.unpack("<I", raw)[0]


def read_u64(handle) -> int:
    raw = handle.read(8)
    if len(raw) != 8:
        raise PackageCheckError("truncated PCK directory")
    return struct.unpack("<Q", raw)[0]


def read_pck(path: Path) -> tuple[int, list[PckEntry]]:
    if not path.is_file():
        raise PackageCheckError(f"PCK not found: {path}")
    file_size = path.stat().st_size
    with path.open("rb") as handle:
        if handle.read(4) != b"GDPC":
            raise PackageCheckError(f"invalid PCK magic: {path}")
        pack_format = read_u32(handle)
        _engine_version = (read_u32(handle), read_u32(handle), read_u32(handle))
        _pack_flags = read_u32(handle)
        file_base = read_u64(handle)
        directory_offset = read_u64(handle)
        if pack_format != 4:
            raise PackageCheckError(f"unsupported PCK format {pack_format}; expected Godot 4 format")
        if directory_offset >= file_size:
            raise PackageCheckError("PCK directory offset is outside the file")
        handle.seek(directory_offset)
        file_count = read_u32(handle)
        if file_count < 1 or file_count > MAX_PACK_FILES:
            raise PackageCheckError(f"abnormal PCK file count: {file_count}")
        entries: list[PckEntry] = []
        seen: set[str] = set()
        for _ in range(file_count):
            path_length = read_u32(handle)
            if path_length < 1 or path_length > 16_384:
                raise PackageCheckError(f"abnormal PCK path length: {path_length}")
            padded_length = (path_length + 3) & ~3
            raw_path = handle.read(padded_length)[:path_length].rstrip(b"\0")
            try:
                entry_path = raw_path.decode("utf-8")
            except UnicodeDecodeError as exc:
                raise PackageCheckError("PCK contains a non-UTF-8 path") from exc
            offset = read_u64(handle)
            size = read_u64(handle)
            if len(handle.read(16)) != 16:
                raise PackageCheckError("truncated PCK checksum")
            flags = read_u32(handle)
            if entry_path in seen:
                raise PackageCheckError(f"duplicate PCK entry: {entry_path}")
            if file_base + offset + size > directory_offset:
                raise PackageCheckError(f"PCK entry points outside the data area: {entry_path}")
            seen.add(entry_path)
            entries.append(PckEntry(entry_path, offset, size, flags))
    return file_base, entries


def entry_bytes(pck: Path, file_base: int, entry: PckEntry, limit: int = 2 * 1024 * 1024) -> bytes:
    if entry.size > limit:
        raise PackageCheckError(f"metadata entry is unexpectedly large: {entry.path} ({entry.size} bytes)")
    with pck.open("rb") as handle:
        handle.seek(file_base + entry.offset)
        data = handle.read(entry.size)
    if len(data) != entry.size:
        raise PackageCheckError(f"truncated PCK entry: {entry.path}")
    return data.rstrip(b"\0")


def check_pck(path: Path) -> int:
    size = path.stat().st_size if path.exists() else 0
    if size > MAX_PCK_BYTES:
        raise PackageCheckError(
            f"PCK is abnormally large: {size / 1024 / 1024:.1f} MiB > {MAX_PCK_BYTES / 1024 / 1024:.0f} MiB"
        )
    file_base, entries = read_pck(path)
    forbidden = sorted(
        entry.path
        for entry in entries
        if any(fnmatch.fnmatchcase(entry.path, pattern) for pattern in FORBIDDEN_PACK_PATTERNS)
        or entry.path.lower().endswith(FORBIDDEN_PACK_SUFFIXES)
    )
    if forbidden:
        sample = ", ".join(forbidden[:12])
        suffix = f" (+{len(forbidden) - 12} more)" if len(forbidden) > 12 else ""
        raise PackageCheckError(f"PCK contains release-excluded paths: {sample}{suffix}")

    entry_by_path = {entry.path: entry for entry in entries}
    missing_font_files = sorted(REQUIRED_FONT_PACKAGE_PATHS - entry_by_path.keys())
    if missing_font_files:
        raise PackageCheckError(
            "PCK is missing the licensed runtime font notice/provenance: " + ", ".join(missing_font_files)
        )
    required_vfx_metadata = {f"{frame}.import" for frame in runtime_vfx_frame_paths()}
    missing_vfx_metadata = sorted(required_vfx_metadata - entry_by_path.keys())
    if missing_vfx_metadata:
        sample = ", ".join(missing_vfx_metadata[:10])
        suffix = f" (+{len(missing_vfx_metadata) - 10} more)" if len(missing_vfx_metadata) > 10 else ""
        raise PackageCheckError(f"PCK is missing runtime VFX frames: {sample}{suffix}")
    imported = {entry.path for entry in entries if entry.path.startswith(".godot/imported/")}
    referenced_imports: set[str] = set()
    import_ref_re = re.compile(rb'res://(\.godot/imported/[^"\s]+)')
    for entry in entries:
        if not entry.path.endswith((".import", ".remap")):
            continue
        for match in import_ref_re.findall(entry_bytes(path, file_base, entry)):
            referenced_imports.add(match.decode("utf-8"))
    missing_imports = sorted(referenced_imports - entry_by_path.keys())
    orphan_imports = sorted(imported - referenced_imports)
    if missing_imports:
        raise PackageCheckError(f"PCK import metadata references missing cache files: {', '.join(missing_imports[:10])}")
    if orphan_imports:
        sample = ", ".join(orphan_imports[:10])
        suffix = f" (+{len(orphan_imports) - 10} more)" if len(orphan_imports) > 10 else ""
        raise PackageCheckError(f"PCK contains orphaned import cache files: {sample}{suffix}")
    print(
        f"PCK validation passed: {len(entries)} files, {len(imported)} imported resources, "
        f"{size / 1024 / 1024:.1f} MiB"
    )
    return size


def check_ipa(
    path: Path,
    expected_build: str,
    expected_short_version: str,
    source_pck: Path | None,
) -> None:
    if not path.is_file():
        raise PackageCheckError(f"IPA not found: {path}")
    ipa_size = path.stat().st_size
    if ipa_size > MAX_IPA_BYTES:
        raise PackageCheckError(
            f"IPA is abnormally large: {ipa_size / 1024 / 1024:.1f} MiB > {MAX_IPA_BYTES / 1024 / 1024:.0f} MiB"
        )
    if ipa_size < 10 * 1024 * 1024:
        raise PackageCheckError(f"IPA is suspiciously small: {ipa_size / 1024 / 1024:.1f} MiB")

    with zipfile.ZipFile(path) as archive:
        corrupt = archive.testzip()
        if corrupt:
            raise PackageCheckError(f"IPA ZIP integrity failure at: {corrupt}")
        names = archive.namelist()
        if any(name.startswith("/") or ".." in Path(name).parts for name in names):
            raise PackageCheckError("IPA contains an unsafe archive path")
        info_names = [name for name in names if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", name)]
        if len(info_names) != 1:
            raise PackageCheckError(f"IPA must contain exactly one app Info.plist; found {len(info_names)}")
        app_root = info_names[0].removesuffix("Info.plist")
        required = {
            f"{app_root}Info.plist",
            f"{app_root}ZombieFire",
            f"{app_root}ZombieFire.pck",
            f"{app_root}embedded.mobileprovision",
            f"{app_root}_CodeSignature/CodeResources",
            f"{app_root}PrivacyInfo.xcprivacy",
        }
        missing = sorted(required - set(names))
        if missing:
            raise PackageCheckError(f"IPA is missing required payload files: {', '.join(missing)}")
        info = plistlib.loads(archive.read(info_names[0]))
        checks = {
            "CFBundleIdentifier": EXPECTED_BUNDLE_ID,
            "CFBundleVersion": expected_build,
            "CFBundleShortVersionString": expected_short_version,
        }
        for key, expected in checks.items():
            actual = str(info.get(key, ""))
            if actual != expected:
                raise PackageCheckError(f"IPA {key} mismatch: expected {expected}, got {actual or '<missing>'}")
        if info.get("CFBundlePackageType") != "APPL":
            raise PackageCheckError("IPA does not identify its payload as an application")
        if info.get("MinimumOSVersion") != "14.0":
            raise PackageCheckError(f"unexpected IPA minimum iOS version: {info.get('MinimumOSVersion', '<missing>')}")
        if info.get("UIDeviceFamily") != [1]:
            raise PackageCheckError(f"IPA must target iPhone only; UIDeviceFamily={info.get('UIDeviceFamily', '<missing>')}")
        if info.get("UIRequiresFullScreen") is not True:
            raise PackageCheckError("IPA must require full-screen presentation")
        orientations = info.get("UISupportedInterfaceOrientations")
        if orientations != ["UIInterfaceOrientationPortrait"]:
            raise PackageCheckError(f"IPA must be portrait-only; orientations={orientations}")

        minimum_sizes = {
            f"{app_root}ZombieFire": 1024 * 1024,
            f"{app_root}ZombieFire.pck": 1024 * 1024,
            f"{app_root}embedded.mobileprovision": 1024,
            f"{app_root}_CodeSignature/CodeResources": 1024,
            f"{app_root}PrivacyInfo.xcprivacy": 100,
        }
        for name, minimum in minimum_sizes.items():
            actual_size = archive.getinfo(name).file_size
            if actual_size < minimum:
                raise PackageCheckError(f"IPA payload file is suspiciously small: {name} ({actual_size} bytes)")
        pck_info = archive.getinfo(f"{app_root}ZombieFire.pck")
        if pck_info.file_size > MAX_PCK_BYTES:
            raise PackageCheckError(f"IPA contains an abnormally large PCK: {pck_info.file_size / 1024 / 1024:.1f} MiB")
        if source_pck is not None:
            if not source_pck.is_file():
                raise PackageCheckError(f"source PCK not found: {source_pck}")
            if pck_info.file_size != source_pck.stat().st_size:
                raise PackageCheckError("IPA PCK size does not match the audited Godot export PCK")
    print(
        f"IPA validation passed: build={expected_build}, version={expected_short_version}, "
        f"{ipa_size / 1024 / 1024:.1f} MiB"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Zombie Fire's iOS release preset and package artifacts.")
    parser.add_argument("--preset-only", action="store_true")
    parser.add_argument("--pck", type=Path)
    parser.add_argument("--ipa", type=Path)
    parser.add_argument("--xcode-project", type=Path)
    parser.add_argument("--expected-build")
    parser.add_argument("--expected-short-version")
    parser.add_argument("--source-pck", type=Path)
    args = parser.parse_args()
    try:
        preset_build, preset_short_version = check_preset()
        if args.pck:
            check_pck(args.pck)
        if args.xcode_project:
            check_xcode_project(args.xcode_project)
        if args.ipa:
            check_ipa(
                args.ipa,
                args.expected_build or preset_build,
                args.expected_short_version or preset_short_version,
                args.source_pck,
            )
        if args.preset_only and (args.pck or args.ipa or args.xcode_project):
            raise PackageCheckError("--preset-only cannot be combined with artifact checks")
    except (OSError, PackageCheckError, plistlib.InvalidFileException, zipfile.BadZipFile) as exc:
        print(f"Release package validation failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
