#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VIDEO="${ROOT}/dist/demo-video/chip-heat-lab-demo-draft.mp4"
VOICEOVER="${ROOT}/docs/demo-voiceover.txt"
OUT="${ROOT}/dist/demo-video/chip-heat-lab-demo-narrated-fallback.mp4"

cd "${ROOT}"

for tool in ffmpeg ffprobe say; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    echo "${tool} is required to render the narrated fallback video." >&2
    exit 1
  fi
done

if [[ ! -f "${VIDEO}" ]]; then
  bash scripts/render_demo_video_draft.sh
fi
if [[ ! -f "${VOICEOVER}" ]]; then
  echo "missing voiceover script: ${VOICEOVER}" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

AUDIO_AIFF="${TMP}/voiceover.aiff"
AUDIO_M4A="${TMP}/voiceover.m4a"

say -r 240 -f "${VOICEOVER}" -o "${AUDIO_AIFF}"
ffmpeg -hide_banner -loglevel error -y -i "${AUDIO_AIFF}" -c:a aac -b:a 160k "${AUDIO_M4A}"

ffmpeg -hide_banner -loglevel error -y \
  -i "${VIDEO}" -i "${AUDIO_M4A}" \
  -map 0:v:0 -map 1:a:0 \
  -c:v copy -c:a aac -b:a 160k \
  -shortest -movflags +faststart "${OUT}"

python3 - "${VIDEO}" "${AUDIO_M4A}" "${OUT}" <<'PY'
import json
import subprocess
import sys
from pathlib import Path


def media_duration(path: Path) -> float:
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
    return float(json.loads(payload)["format"]["duration"])


video = Path(sys.argv[1])
audio = Path(sys.argv[2])
out = Path(sys.argv[3])
video_duration = media_duration(video)
audio_duration = media_duration(audio)
out_duration = media_duration(out)
size = out.stat().st_size

if video_duration < 89 or video_duration > 92:
    raise SystemExit(f"unexpected storyboard duration: {video_duration:.3f}s")
if audio_duration < 70:
    raise SystemExit(f"voiceover is too short for review: {audio_duration:.3f}s")
if audio_duration > 90:
    raise SystemExit(f"voiceover exceeds the 90s storyboard: {audio_duration:.3f}s")
if out_duration < 70 or out_duration > 92:
    raise SystemExit(f"unexpected narrated video duration: {out_duration:.3f}s")
if size < 500_000:
    raise SystemExit(f"narrated video looks too small: {size} bytes")

print(
    f"wrote {out} "
    f"video={video_duration:.1f}s audio={audio_duration:.1f}s "
    f"output={out_duration:.1f}s bytes={size}"
)
PY
