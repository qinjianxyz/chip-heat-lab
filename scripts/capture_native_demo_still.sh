#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-${ROOT}/dist/visual-proof/native-app.png}"
BUNDLE_LOG="/tmp/chip-heat-lab-native-bundle.log"
APP_LOG="/tmp/chip-heat-lab-native-app.log"

cd "${ROOT}"
mkdir -p "$(dirname "${OUT}")"

bash scripts/bundle_macos_app.sh >"${BUNDLE_LOG}" 2>&1
pkill -x "ChipHeatLab" >/dev/null 2>&1 || true
pkill -f "ChipHeatLab.app/Contents/MacOS/ChipHeatLab" >/dev/null 2>&1 || true
sleep 0.5
open -n dist/ChipHeatLab.app

cleanup() {
  osascript -e 'tell application id "xyz.qinjian.chipheatlab" to quit' >/dev/null 2>&1 || true
}
if [[ "${CHIP_HEAT_LAB_CAPTURE_KEEP_OPEN:-0}" != "1" ]]; then
  trap cleanup EXIT
fi

for _ in {1..80}; do
  if osascript -e 'tell application "System Events" to exists process "ChipHeatLab"' 2>/dev/null | grep -q true; then
    break
  fi
  sleep 0.5
done

WINDOW_BOUNDS=""
for _ in {1..120}; do
  WINDOW_BOUNDS="$(
    osascript <<'OSA' 2>/dev/null || true
tell application id "xyz.qinjian.chipheatlab" to activate
tell application "System Events"
  if exists process "ChipHeatLab" then
    tell process "ChipHeatLab"
      if (count of windows) > 0 then
        set winPos to position of window 1
        set winSize to size of window 1
        set x to item 1 of winPos as integer
        set y to item 2 of winPos as integer
        set w to item 1 of winSize as integer
        set h to item 2 of winSize as integer
        return (x as text) & "," & (y as text) & "," & (w as text) & "," & (h as text)
      end if
    end tell
  end if
end tell
OSA
  )"
  if [[ "${WINDOW_BOUNDS}" =~ ^-?[0-9]+,-?[0-9]+,[0-9]+,[0-9]+$ ]]; then
    break
  fi
  sleep 0.5
done

if [[ ! "${WINDOW_BOUNDS}" =~ ^-?[0-9]+,-?[0-9]+,[0-9]+,[0-9]+$ ]]; then
  echo "could not find a ChipHeatLab window to capture" >&2
  ps -ax -o pid=,comm=,args= | grep "[C]hipHeatLab" >&2 || true
  osascript <<'OSA' >&2 || true
tell application "System Events"
  if exists process "ChipHeatLab" then
    tell process "ChipHeatLab"
      return "windows=" & (count of windows as text) & ", frontmost=" & (frontmost as text)
    end tell
  else
    return "process missing"
  end if
end tell
OSA
  tail -80 "${APP_LOG}" >&2 || true
  exit 1
fi

sleep "${CHIP_HEAT_LAB_CAPTURE_SETTLE_SECONDS:-6}"
osascript -e 'tell application id "xyz.qinjian.chipheatlab" to activate' >/dev/null 2>&1 || true

screencapture -x -R "${WINDOW_BOUNDS}" "${OUT}"

python3 - "${OUT}" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
size = path.stat().st_size if path.exists() else 0
if size < 100_000:
    raise SystemExit(f"native screenshot looks too small: {size} bytes")
print(f"{path} {size} bytes")
PY
