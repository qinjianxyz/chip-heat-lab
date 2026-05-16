#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CARGO_BIN="${CARGO:-${HOME}/.cargo/bin/cargo}"
if [[ ! -x "${CARGO_BIN}" ]]; then
  CARGO_BIN="cargo"
fi

cd "${ROOT}"
bash scripts/prepare_macos_resources.sh
(cd apps/macos/ChipHeatLab && swift build -c release -q)

APP="${ROOT}/dist/ChipHeatLab.app"
rm -rf "${APP}"
mkdir -p "${APP}/Contents/MacOS" "${APP}/Contents/Resources/bin" "${APP}/Contents/Resources/scenarios"

cp apps/macos/ChipHeatLab/.build/release/ChipHeatLab "${APP}/Contents/MacOS/ChipHeatLab"
cp target/release/chip_heat_cli "${APP}/Contents/Resources/bin/chip_heat_cli"
cp scenarios/flagship.json "${APP}/Contents/Resources/scenarios/flagship.json"
cp kb_index.json "${APP}/Contents/Resources/kb_index.json"
chmod +x "${APP}/Contents/MacOS/ChipHeatLab" "${APP}/Contents/Resources/bin/chip_heat_cli"

cat > "${APP}/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>ChipHeatLab</string>
  <key>CFBundleIdentifier</key>
  <string>xyz.qinjian.chipheatlab</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Chip Heat Lab</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "Created ${APP}"
echo "Open it with: open dist/ChipHeatLab.app"
