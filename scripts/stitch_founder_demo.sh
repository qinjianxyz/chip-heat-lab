#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-90}"
OUT_DIR="${ROOT}/dist/demo-video"
OUT="${OUT_DIR}/chip-heat-lab-founder-demo-${MODE}s.mp4"

CLIP1="${2:-${CHIP_HEAT_LAB_DEMO1:-}}"
CLIP2="${3:-${CHIP_HEAT_LAB_DEMO2:-}}"
CLIP3="${4:-${CHIP_HEAT_LAB_DEMO3:-}}"

for tool in ffmpeg ffprobe; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    echo "${tool} is required." >&2
    exit 1
  fi
done

if [[ -z "${CLIP1}" || -z "${CLIP2}" || -z "${CLIP3}" ]]; then
  cat >&2 <<'TEXT'
usage: scripts/stitch_founder_demo.sh [60|90|120|raw] <browser.mov> <native.mov> <knowledge.mov>

You can also set CHIP_HEAT_LAB_DEMO1, CHIP_HEAT_LAB_DEMO2, and
CHIP_HEAT_LAB_DEMO3 for local recording sessions.
TEXT
  exit 1
fi

for clip in "${CLIP1}" "${CLIP2}" "${CLIP3}"; do
  if [[ ! -f "${clip}" ]]; then
    echo "missing source clip: ${clip}" >&2
    exit 1
  fi
done

segments=()
case "${MODE}" in
  60)
    segments=(
      "${CLIP1}|0|16|browser value review"
      "${CLIP2}|0|14|native workload and floorplan controls"
      "${CLIP2}|18|8|native IO burst heat path"
      "${CLIP2}|30|6|native ranked review panel"
      "${CLIP3}|0|10|GBrain knowledge base"
      "${CLIP1}|22|4|GStack process cards"
    )
    ;;
  90)
    segments=(
      "${CLIP1}|0|22|browser value review"
      "${CLIP2}|0|16|native workload and floorplan controls"
      "${CLIP2}|18|10|native IO burst heat path"
      "${CLIP2}|30|12|native ranked review panel"
      "${CLIP2}|40|8|native assumptions and non-claims"
      "${CLIP3}|0|14.341|GBrain knowledge base"
      "${CLIP1}|22|6|GStack process cards"
    )
    ;;
  120|full|raw|95)
    if [[ "${MODE}" == "120" ]]; then
      OUT="${OUT_DIR}/chip-heat-lab-founder-demo-120s.mp4"
    else
      MODE="raw"
      OUT="${OUT_DIR}/chip-heat-lab-founder-demo-raw.mp4"
    fi
    segments=(
      "${CLIP1}|0|27.449|full browser clip"
      "${CLIP2}|0|53.740187|full native app clip"
      "${CLIP3}|0|14.341666|full knowledge clip"
    )
    ;;
  *)
    echo "usage: $0 [60|90|120|raw]" >&2
    exit 1
    ;;
esac

mkdir -p "${OUT_DIR}"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

: >"${TMP}/segments.txt"

for idx in "${!segments[@]}"; do
  IFS="|" read -r clip start duration label <<<"${segments[$idx]}"
  segment="${TMP}/segment-${idx}.mp4"
  echo "segment $((idx + 1)): ${label} (${clip}, start=${start}s, duration=${duration}s)"
  ffmpeg -hide_banner -loglevel error -y \
    -ss "${start}" -i "${clip}" \
    -t "${duration}" \
    -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=30" \
    -an -pix_fmt yuv420p -movflags +faststart "${segment}"
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
    ["ffprobe", "-v", "error", "-show_entries", "format=duration,size", "-of", "json", str(path)],
    text=True,
)
data = json.loads(payload)["format"]
duration = float(data["duration"])
size = int(data["size"])
if size < 500_000:
    raise SystemExit(f"stitched video looks too small: {size} bytes")
print(f"wrote {path} duration={duration:.1f}s bytes={size}")
PY
