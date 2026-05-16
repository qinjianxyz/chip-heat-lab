#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT}/dist/demo-video"
OUT="${OUT_DIR}/chip-heat-lab-demo-draft.mp4"

cd "${ROOT}"

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg is required to render the draft video." >&2
  exit 1
fi

required=(
  "dist/demo-capture/01-native-balanced.png"
  "dist/demo-capture/02-native-kv.png"
  "dist/demo-video/03-kv-clustered.png"
  "dist/demo-video/04-kv-spread.png"
  "dist/demo-video/05-cooling.png"
  "dist/demo-video/01-home.png"
  "dist/demo-video/02-balanced.png"
)

missing=0
for image in "${required[@]}"; do
  if [[ ! -f "${image}" ]]; then
    echo "missing required still: ${image}" >&2
    missing=1
  fi
done
if [[ "${missing}" -ne 0 ]]; then
  echo "Capture the native app and site stills first; see docs/demo-script.md." >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

images=(
  "${ROOT}/dist/demo-capture/01-native-balanced.png"
  "${ROOT}/dist/demo-capture/02-native-kv.png"
  "${ROOT}/dist/demo-video/03-kv-clustered.png"
  "${ROOT}/dist/demo-video/04-kv-spread.png"
  "${ROOT}/dist/demo-video/05-cooling.png"
  "${ROOT}/dist/demo-video/01-home.png"
  "${ROOT}/dist/demo-video/02-balanced.png"
)
durations=(10 13 13 13 11 16 14)

: >"${TMP}/segments.txt"
for idx in "${!images[@]}"; do
  segment="${TMP}/segment-${idx}.mp4"
  ffmpeg -hide_banner -loglevel error -y \
    -loop 1 -t "${durations[$idx]}" -i "${images[$idx]}" \
    -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=30" \
    -pix_fmt yuv420p -movflags +faststart "${segment}"
  printf "file '%s'\n" "${segment}" >>"${TMP}/segments.txt"
done

ffmpeg -hide_banner -loglevel error -y \
  -f concat -safe 0 -i "${TMP}/segments.txt" \
  -c copy -movflags +faststart "${OUT}"

python3 - "${OUT}" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

path = Path(sys.argv[1])
payload = subprocess.check_output(
    [
        "ffprobe",
        "-v",
        "error",
        "-show_entries",
        "format=duration,size",
        "-of",
        "json",
        str(path),
    ],
    text=True,
)
data = json.loads(payload)["format"]
duration = float(data["duration"])
size = int(data["size"])
if duration < 89 or duration > 92:
    raise SystemExit(f"unexpected draft duration: {duration:.3f}s")
if size < 100_000:
    raise SystemExit(f"draft video looks too small: {size} bytes")
print(f"wrote {path} duration={duration:.1f}s bytes={size}")
PY
