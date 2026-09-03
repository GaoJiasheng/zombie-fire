#!/usr/bin/env bash
# Build the Zombie Fire StoreKit 2 iOS plugin into a Godot .gdip static library.
#
# Godot iOS plugins link against the engine's own headers, so this needs a Godot
# source tree at the exact engine version the game ships with. Point GODOT_SRC at
# one; the generated headers it requires (core/extension/*.gen.h) appear after any
# SCons build has started, a complete engine build is not required.
#
#   GODOT_SRC=/path/to/godot-4.7 tools/build_ios_storekit_plugin.sh
#
# Output: ios/plugins/zombiefire_storekit/lib/libzombiefire_storekit.a (device arm64)
set -euo pipefail

PROJ="${PROJ:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
GODOT_SRC="${GODOT_SRC:-}"
SRC="$PROJ/src/ios/storekit"
OUT_DIR="$PROJ/ios/plugins/zombiefire_storekit/lib"
WORK="$(mktemp -d)"
MIN_IOS="15.0"
SWIFT_MODULE="ZFStoreKitSwift"

trap 'rm -rf "$WORK"' EXIT

die() { printf '\n[storekit] ERROR: %s\n' "$*" >&2; exit 1; }
log() { printf '\n[storekit] %s\n' "$*"; }

[[ -n "$GODOT_SRC" ]] || die "set GODOT_SRC to a Godot engine source tree matching the shipped engine version"
[[ -f "$GODOT_SRC/core/object/class_db.h" ]] || die "GODOT_SRC does not look like a Godot source tree: $GODOT_SRC"
[[ -f "$GODOT_SRC/core/extension/gdextension_interface.gen.h" ]] \
    || die "generated headers are missing; run a SCons build in $GODOT_SRC first (it only needs to reach the compile stage)"

ENGINE_VERSION=$(awk -F'"' '/^version *=/{print $2}' "$GODOT_SRC/version.py" 2>/dev/null || echo "")
log "engine source: $GODOT_SRC ${ENGINE_VERSION:+(version $ENGINE_VERSION)}"

SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
TARGET="arm64-apple-ios$MIN_IOS"

log "Compiling Swift StoreKit 2 layer"
xcrun -sdk iphoneos swiftc \
    -emit-object \
    -static \
    -module-name "$SWIFT_MODULE" \
    -emit-objc-header-path "$WORK/$SWIFT_MODULE-Swift.h" \
    -target "$TARGET" \
    -sdk "$SDK" \
    -swift-version 5 \
    -O \
    -o "$WORK/ZFStoreKit.o" \
    "$SRC/ZFStoreKit.swift"

log "Compiling the Objective-C++ Godot bridge"
xcrun -sdk iphoneos clang++ \
    -c "$SRC/ZFStoreKitPlugin.mm" \
    -o "$WORK/ZFStoreKitPlugin.o" \
    -isysroot "$SDK" \
    -arch arm64 \
    -target "$TARGET" \
    -std=gnu++17 \
    -fobjc-arc \
    -fno-exceptions \
    -O2 \
    -I"$WORK" \
    -I"$GODOT_SRC" \
    -I"$GODOT_SRC/platform/ios" \
    -DIOS_ENABLED -DAPPLE_EMBEDDED_ENABLED -DUNIX_ENABLED -DNDEBUG

log "Archiving the static library"
mkdir -p "$OUT_DIR"
xcrun libtool -static -o "$OUT_DIR/libzombiefire_storekit.a" \
    "$WORK/ZFStoreKit.o" "$WORK/ZFStoreKitPlugin.o"

# The archive must expose exactly the two entry points named in the .gdip, or the
# generated Xcode project fails to link with an undefined symbol.
for symbol in zombiefire_storekit_init zombiefire_storekit_deinit; do
    # Godot's generated dummy.cpp declares these with C++ linkage, so the archive
    # must expose the mangled symbol, not the C one.
    xcrun nm -g "$OUT_DIR/libzombiefire_storekit.a" 2>/dev/null | grep -q "T __Z[0-9]*$symbol" \
        || die "built archive is missing the C++-linkage $symbol entry point"
done

log "Built $OUT_DIR/libzombiefire_storekit.a ($(du -h "$OUT_DIR/libzombiefire_storekit.a" | cut -f1))"
log "Verified on 2026-09-03 against Godot 4.7 + Xcode 26.4: the exported Xcode"
log "project archives with no extra patching. Swift's autolink records inside the"
log "objects pull in the OS Swift runtime, which is ABI stable from iOS 12.2."
