#!/usr/bin/env bash
# 一键把当前项目打包并自动上传到 TestFlight。
# 流程：构建号+1 → 重导入纹理 → Godot 导出 iOS 工程 → 改自动签名
#        → xcodebuild 归档 → 导出 App Store IPA → altool 上传。
# 依赖：~/.appstoreconnect/private_keys/AuthKey_<KEYID>.p8 已就位。
# 用法：bash tools/ship_testflight.sh
set -uo pipefail

PROJ="/Users/gavin/work/zombie-fire"
PRESET="iOS Release Candidate"
TEAM="D33974QQTD"
KEY="AMDBKB83K9"
ISS="3659a31c-d035-4195-842f-d269268a59c3"
KEYP="$HOME/.appstoreconnect/private_keys/AuthKey_$KEY.p8"
# 用 API 密钥认证归档/导出，这样后台运行也能自动建发布证书（否则会报 "No Accounts"）。
AUTH=(-allowProvisioningUpdates -authenticationKeyPath "$KEYP" -authenticationKeyID "$KEY" -authenticationKeyIssuerID "$ISS")
cd "$PROJ"

log(){ printf '\n\033[1;36m▶ %s\033[0m\n' "$*"; }
die(){ printf '\n\033[1;31m✗ %s\033[0m\n' "$*"; exit 1; }

# 1) 构建号 +1（只动 iOS preset.0；App Store Connect 不收重复构建号）
CUR=$(awk '/^\[preset.0.options\]/{f=1} f&&/^application\/version=/{gsub(/[^0-9]/,"");print;exit}' export_presets.cfg)
[ -n "$CUR" ] || die "读不到 iOS 构建号"
NEW=$((CUR+1))
awk -v n="$NEW" '
  /^\[preset.0.options\]/{f=1}
  /^\[preset.1/{f=0}
  { if(f && $0 ~ /^application\/version=/) print "application/version=\"" n "\""; else print }
' export_presets.cfg > export_presets.cfg.tmp && mv export_presets.cfg.tmp export_presets.cfg
log "构建号 $CUR → $NEW"

# 2) 重导入（纹理/资源若有改动）
log "重新导入资源…"
godot --headless --import >/tmp/ship_import.log 2>&1 || true

# 3) Godot 导出 iOS 工程（Godot 自带 archive 必失败，无视；只要 xcodeproj 生成即可）
log "Godot 导出 iOS 工程…"
rm -rf build/ios; mkdir -p build/ios
godot --headless --export-release "$PRESET" build/ios/ZombieFire.ipa >/tmp/ship_export.log 2>&1 || true
[ -d build/ios/ZombieFire.xcodeproj ] || { tail -20 /tmp/ship_export.log; die "工程未生成"; }

# 4) 改自动签名（每次重导出会还原成手动）
PBX="build/ios/ZombieFire.xcodeproj/project.pbxproj"
sed -i '' \
  -e 's|CODE_SIGN_IDENTITY = "Apple Development: Gavin Gao (KT793R445X)";|CODE_SIGN_IDENTITY = "Apple Development";|g' \
  -e 's|CODE_SIGN_STYLE = "Manual";|CODE_SIGN_STYLE = "Automatic";|g' \
  "$PBX"

# 5) 归档
log "xcodebuild 归档（几分钟）…"
rm -rf /tmp/ZombieFire.xcarchive
xcodebuild -project build/ios/ZombieFire.xcodeproj -scheme ZombieFire -configuration Release \
  -destination "generic/platform=iOS" -archivePath /tmp/ZombieFire.xcarchive \
  archive "${AUTH[@]}" >/tmp/ship_archive.log 2>&1
grep -q "ARCHIVE SUCCEEDED" /tmp/ship_archive.log || { tail -25 /tmp/ship_archive.log; die "归档失败"; }

# 6) 导出 App Store IPA
log "导出 App Store IPA…"
cat > /tmp/ExportOptions.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>teamID</key><string>$TEAM</string>
  <key>signingStyle</key><string>automatic</string>
  <key>destination</key><string>export</string>
  <key>uploadSymbols</key><true/>
</dict></plist>
PLIST
rm -rf /tmp/ZombieFire_ipa
xcodebuild -exportArchive -archivePath /tmp/ZombieFire.xcarchive \
  -exportOptionsPlist /tmp/ExportOptions.plist -exportPath /tmp/ZombieFire_ipa \
  "${AUTH[@]}" >/tmp/ship_exportipa.log 2>&1
grep -q "EXPORT SUCCEEDED" /tmp/ship_exportipa.log || { tail -25 /tmp/ship_exportipa.log; die "导出 IPA 失败"; }
cp /tmp/ZombieFire_ipa/ZombieFire.ipa build/ios/ZombieFire.ipa
cp /tmp/ZombieFire_ipa/ZombieFire.ipa "$HOME/Desktop/ZombieFire.ipa"

# 7) 上传 TestFlight
log "上传到 TestFlight（669MB，视网速几分钟）…"
xcrun altool --upload-app -f build/ios/ZombieFire.ipa -t ios --apiKey "$KEY" --apiIssuer "$ISS" \
  || die "上传失败（看上面的报错）"

printf '\n\033[1;32m✅ 构建号 %s 已上传 TestFlight，等处理完手机即可更新。\033[0m\n' "$NEW"
