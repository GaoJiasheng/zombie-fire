#!/usr/bin/env bash
# Validate, build, sign, inspect, and upload the current release candidate to TestFlight.
# Requires ~/.appstoreconnect/private_keys/AuthKey_<KEYID>.p8.
set -euo pipefail

PROJ="${PROJ:-/Users/gavin/work/zombie-fire}"
PRESET="iOS Release Candidate"
TEAM="D33974QQTD"
KEY="AMDBKB83K9"
ISS="3659a31c-d035-4195-842f-d269268a59c3"
KEYP="$HOME/.appstoreconnect/private_keys/AuthKey_$KEY.p8"
GODOT_BIN="${GODOT_BIN:-/opt/homebrew/bin/godot}"
FINAL_IPA="$PROJ/build/ios/ZombieFire.ipa"
DESKTOP_IPA="$HOME/Desktop/ZombieFire.ipa"

log() { printf '\n[release] %s\n' "$*"; }
die() { printf '\n[release] ERROR: %s\n' "$*" >&2; exit 1; }

set_ios_build_number() {
    local new_build=$1
    local expected_build=$2
    local allow_already_set=${3:-0}
    python3 - "$new_build" "$expected_build" "$allow_already_set" "$PROJ/export_presets.cfg" <<'PY'
from pathlib import Path
import os
import re
import sys
import tempfile

new_build, expected_build, allow_already_set, raw_path = sys.argv[1:]
path = Path(raw_path)
text = path.read_text(encoding="utf-8")
start = text.find("[preset.0.options]")
end = text.find("[preset.1]", start)
if start < 0 or end < 0:
    raise SystemExit("could not isolate preset.0.options")
section = text[start:end]
match = re.search(r'^application/version="([0-9]+)"$', section, re.MULTILINE)
if match is None:
    raise SystemExit("could not read the iOS build number")
if allow_already_set == "1" and match.group(1) == new_build:
    raise SystemExit(0)
if match.group(1) != expected_build:
    raise SystemExit(f"iOS build number changed concurrently: expected {expected_build}, got {match.group(1)}")
updated = section[:match.start(1)] + new_build + section[match.end(1):]
mode = path.stat().st_mode
with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=path.parent, delete=False) as handle:
    temporary = Path(handle.name)
    handle.write(text[:start] + updated + text[end:])
os.chmod(temporary, mode)
temporary.replace(path)
PY
}

for command in python3 xcodebuild xcrun codesign; do
    command -v "$command" >/dev/null 2>&1 || die "missing required command: $command"
done
[[ -x "$GODOT_BIN" ]] || die "Godot executable not found: $GODOT_BIN"
[[ -r "$KEYP" ]] || die "App Store Connect API key not readable: $KEYP"
[[ -d "$PROJ" ]] || die "project directory not found: $PROJ"

WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/ZombieFire.release.XXXXXX")
ARCHIVE_PATH="$WORK_DIR/ZombieFire.xcarchive"
IPA_DIR="$WORK_DIR/ipa"
EXPORT_OPTIONS="$WORK_DIR/ExportOptions.plist"
KEEP_VERSION=0
BUILD_STARTED=0
VERSION_CHANGED=0
CUR=""
NEW=""

cleanup() {
    local status=$?
    trap - EXIT
    if [[ "$KEEP_VERSION" -ne 1 ]]; then
        if [[ "$VERSION_CHANGED" -eq 1 ]]; then
            if set_ios_build_number "$CUR" "$NEW" 1; then
                printf '\n[release] Restored the original iOS build number.\n' >&2
            else
                printf '\n[release] ERROR: could not safely restore the iOS build number.\n' >&2
                status=1
            fi
        fi
        if [[ "$BUILD_STARTED" -eq 1 ]]; then
            rm -f "$FINAL_IPA"
        fi
    fi
    rm -rf "$WORK_DIR"
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT TERM HUP

AUTH=(
    -allowProvisioningUpdates
    -authenticationKeyPath "$KEYP"
    -authenticationKeyID "$KEY"
    -authenticationKeyIssuerID "$ISS"
)

run_godot_logged() {
    local log_path=$1
    shift
    if ! "$@" 2>&1 | tee "$log_path"; then
        die "Godot command failed: $*"
    fi
    python3 tools/check_godot_log.py "$log_path"
}

remove_unused_ios_permission_descriptions() {
    local plist="build/ios/ZombieFire/ZombieFire-Info.plist"
    local plist_buddy="/usr/libexec/PlistBuddy"
    local key
    [[ -f "$plist" ]] || die "generated iOS Info.plist not found: $plist"
    [[ -x "$plist_buddy" ]] || die "PlistBuddy is not available"
    for key in NSCameraUsageDescription NSMicrophoneUsageDescription NSPhotoLibraryUsageDescription; do
        if "$plist_buddy" -c "Print :$key" "$plist" >/dev/null 2>&1; then
            "$plist_buddy" -c "Delete :$key" "$plist"
        fi
        if "$plist_buddy" -c "Print :$key" "$plist" >/dev/null 2>&1; then
            die "unused permission description remains in generated Info.plist: $key"
        fi
    done
}

cd "$PROJ"

log "Synchronizing release-only asset exclusions"
python3 tools/sync_release_export_excludes.py --write

log "Running the complete release-candidate gate before changing the build number"
python3 tools/check_release_candidate.py

CUR=$(awk '/^\[preset.0.options\]/{f=1} f&&/^application\/version=/{gsub(/[^0-9]/,"");print;exit}' export_presets.cfg)
SHORT_VERSION=$(awk -F'"' '/^\[preset.0.options\]/{f=1} f&&/^application\/short_version=/{print $2;exit}' export_presets.cfg)
[[ "$CUR" =~ ^[0-9]+$ ]] || die "could not read the iOS build number"
[[ -n "$SHORT_VERSION" ]] || die "could not read the iOS short version"
NEW=$((CUR + 1))
VERSION_CHANGED=1
set_ios_build_number "$NEW" "$CUR"
log "iOS build number $CUR -> $NEW"

log "Importing Godot resources"
run_godot_logged "$WORK_DIR/godot_import.log" \
    "$GODOT_BIN" --headless --path "$PROJ" --import

log "Exporting the iOS Xcode project"
rm -rf build/ios
mkdir -p build/ios
BUILD_STARTED=1
run_godot_logged "$WORK_DIR/godot_export.log" \
    "$GODOT_BIN" --headless --path "$PROJ" --export-release "$PRESET" "$FINAL_IPA"

[[ -d build/ios/ZombieFire.xcodeproj ]] || die "Godot did not generate the Xcode project"
[[ -s build/ios/ZombieFire.pck ]] || die "Godot did not generate a non-empty PCK"
log "Removing unused iOS permission descriptions"
remove_unused_ios_permission_descriptions
python3 tools/check_release_package.py \
    --pck build/ios/ZombieFire.pck \
    --xcode-project build/ios/ZombieFire.xcodeproj

log "Smoke-testing the exported PCK"
run_godot_logged "$WORK_DIR/pck_battle_boot.log" \
    "$GODOT_BIN" --headless --main-pack build/ios/ZombieFire.pck \
    --script "$PROJ/tools/_battle_boot_probe.gd"
run_godot_logged "$WORK_DIR/pck_m1_smoke.log" \
    "$GODOT_BIN" --headless --main-pack build/ios/ZombieFire.pck \
    --script "$PROJ/tools/m1_smoke_test.gd"

PBX="build/ios/ZombieFire.xcodeproj/project.pbxproj"
[[ -f "$PBX" ]] || die "Xcode project file is missing"
sed -i '' \
    -e 's|CODE_SIGN_IDENTITY = "[^"]*";|CODE_SIGN_IDENTITY = "Apple Development";|g' \
    -e 's|CODE_SIGN_STYLE = "Manual";|CODE_SIGN_STYLE = "Automatic";|g' \
    -e 's|CODE_SIGN_STYLE = Manual;|CODE_SIGN_STYLE = Automatic;|g' \
    "$PBX"
grep -Eq 'CODE_SIGN_STYLE = "?Automatic"?;' "$PBX" || die "could not enable automatic signing"
if grep -Eq 'CODE_SIGN_STYLE = "?Manual"?;' "$PBX"; then
    die "manual signing remains in the generated Xcode project"
fi

log "Archiving the Release build"
if ! xcodebuild -project build/ios/ZombieFire.xcodeproj -scheme ZombieFire -configuration Release \
    -destination "generic/platform=iOS" -archivePath "$ARCHIVE_PATH" \
    archive "${AUTH[@]}" 2>&1 | tee "$WORK_DIR/xcode_archive.log"; then
    die "xcodebuild archive failed"
fi
grep -q 'ARCHIVE SUCCEEDED' "$WORK_DIR/xcode_archive.log" || die "xcodebuild did not report archive success"

shopt -s nullglob
ARCHIVE_APPS=("$ARCHIVE_PATH"/Products/Applications/*.app)
shopt -u nullglob
[[ "${#ARCHIVE_APPS[@]}" -eq 1 ]] || die "archive must contain exactly one app"
codesign --verify --deep --strict "${ARCHIVE_APPS[0]}"

cat > "$EXPORT_OPTIONS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>teamID</key><string>$TEAM</string>
  <key>signingStyle</key><string>automatic</string>
  <key>destination</key><string>export</string>
  <key>manageAppVersionAndBuildNumber</key><false/>
  <key>uploadSymbols</key><true/>
</dict></plist>
PLIST

log "Exporting the App Store IPA"
mkdir -p "$IPA_DIR"
if ! xcodebuild -exportArchive -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" -exportPath "$IPA_DIR" \
    "${AUTH[@]}" 2>&1 | tee "$WORK_DIR/xcode_export_ipa.log"; then
    die "xcodebuild IPA export failed"
fi
grep -q 'EXPORT SUCCEEDED' "$WORK_DIR/xcode_export_ipa.log" || die "xcodebuild did not report IPA export success"

shopt -s nullglob
EXPORTED_IPAS=("$IPA_DIR"/*.ipa)
shopt -u nullglob
[[ "${#EXPORTED_IPAS[@]}" -eq 1 ]] || die "export must produce exactly one IPA"
cp "${EXPORTED_IPAS[0]}" "$FINAL_IPA"
python3 tools/check_release_package.py \
    --ipa "$FINAL_IPA" \
    --source-pck build/ios/ZombieFire.pck \
    --expected-build "$NEW" \
    --expected-short-version "$SHORT_VERSION"

log "Uploading the audited IPA to TestFlight"
if ! xcrun altool --upload-app -f "$FINAL_IPA" -t ios --apiKey "$KEY" --apiIssuer "$ISS" \
    2>&1 | tee "$WORK_DIR/altool_upload.log"; then
    die "TestFlight upload failed"
fi
grep -q 'UPLOAD SUCCEEDED with no errors' "$WORK_DIR/altool_upload.log" \
    || die "upload command exited cleanly without the App Store success marker"

KEEP_VERSION=1
mkdir -p "$HOME/Desktop"
if cp "$FINAL_IPA" "$DESKTOP_IPA.tmp" && mv "$DESKTOP_IPA.tmp" "$DESKTOP_IPA"; then
    log "Copied the uploaded IPA to $DESKTOP_IPA"
else
    rm -f "$DESKTOP_IPA.tmp"
    printf '\n[release] WARNING: upload succeeded, but the Desktop IPA copy failed.\n' >&2
fi
printf '\n[release] Build %s uploaded to TestFlight successfully.\n' "$NEW"
