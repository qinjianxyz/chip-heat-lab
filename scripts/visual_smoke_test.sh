#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${PORT:-4187}"
BASE_URL="http://127.0.0.1:${PORT}"
OUT_DIR="${ROOT}/dist/visual-proof"
LOG_DIR="$(mktemp -d)"

cleanup() {
  if [[ -n "${SERVER_PID:-}" ]]; then
    kill "${SERVER_PID}" >/dev/null 2>&1 || true
    wait "${SERVER_PID}" >/dev/null 2>&1 || true
  fi
  rm -rf "${LOG_DIR}"
}
trap cleanup EXIT

cd "${ROOT}"

if [[ ! -d site/node_modules ]]; then
  npm --prefix site install --silent
fi

if [[ " ${NODE_OPTIONS:-} " != *" --localstorage-file="* ]]; then
  export NODE_OPTIONS="${NODE_OPTIONS:+${NODE_OPTIONS} }--localstorage-file=/tmp/chip-heat-lab-node-localstorage"
fi

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"

npm --prefix site run dev -- --port "${PORT}" >"${LOG_DIR}/next.log" 2>&1 &
SERVER_PID=$!

for _ in {1..60}; do
  if curl -fsS "${BASE_URL}" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

curl -fsS "${BASE_URL}" >/dev/null

check_page() {
  local path="$1"
  shift
  local html="${LOG_DIR}/page.html"
  curl -fsS "${BASE_URL}${path}" >"${html}"
  for needle in "$@"; do
    if ! grep -q "${needle}" "${html}"; then
      echo "visual smoke failed: ${path} is missing '${needle}'" >&2
      echo "Next log:" >&2
      tail -80 "${LOG_DIR}/next.log" >&2 || true
      return 1
    fi
  done
}

check_page "/" "Transient Review" "Value Benchmark" "Inspectable Build System"
check_page "/knowledge" "Knowledge Base" "Transient Value Loop" "GBrain-ready knowledge system"
check_page "/replay?snapshot=inference_spread" "inference_spread" "Replay"

find_chrome() {
  if [[ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]]; then
    echo "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    return 0
  fi
  if command -v google-chrome >/dev/null 2>&1; then
    command -v google-chrome
    return 0
  fi
  if command -v chromium >/dev/null 2>&1; then
    command -v chromium
    return 0
  fi
  return 1
}

if CHROME="$(find_chrome)"; then
  "${CHROME}" --headless=new --disable-gpu --hide-scrollbars --window-size=1440,1200 \
    --screenshot="${OUT_DIR}/home.png" "${BASE_URL}/" >/dev/null 2>&1
  "${CHROME}" --headless=new --disable-gpu --hide-scrollbars --window-size=1440,1200 \
    --screenshot="${OUT_DIR}/knowledge.png" "${BASE_URL}/knowledge" >/dev/null 2>&1
  "${CHROME}" --headless=new --disable-gpu --hide-scrollbars --window-size=1440,1200 \
    --screenshot="${OUT_DIR}/replay-inference-spread.png" "${BASE_URL}/replay?snapshot=inference_spread" >/dev/null 2>&1

  python3 - "${OUT_DIR}" <<'PY'
import sys
from pathlib import Path

out_dir = Path(sys.argv[1])
for image in sorted(out_dir.glob("*.png")):
    size = image.stat().st_size
    if size < 10_000:
        raise SystemExit(f"{image} looks too small to be a real screenshot: {size} bytes")
    print(f"{image.relative_to(out_dir.parent.parent)} {size} bytes")
PY
else
  echo "Chrome/Chromium not found; HTML route checks passed, screenshots skipped."
fi

echo "visual smoke passed"
