#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-public}"
PORT="${PORT:-4177}"
PUBLIC_URL="${CHIP_HEAT_LAB_PUBLIC_URL:-https://chip-heat-lab.vercel.app}"
PID_FILE="${ROOT}/dist/recording-session/site.pid"
LOG_FILE="${ROOT}/dist/recording-session/site.log"

cd "${ROOT}"
mkdir -p "$(dirname "${PID_FILE}")"

case "${MODE}" in
  public)
    BASE_URL="${PUBLIC_URL}"
    ;;
  local)
    BASE_URL="http://127.0.0.1:${PORT}"

    if [[ ! -d site/node_modules ]]; then
      npm --prefix site install --silent
    fi

    if [[ " ${NODE_OPTIONS:-} " != *" --localstorage-file="* ]]; then
      export NODE_OPTIONS="${NODE_OPTIONS:+${NODE_OPTIONS} }--localstorage-file=/tmp/chip-heat-lab-node-localstorage"
    fi

    if [[ -f "${PID_FILE}" ]] && kill -0 "$(cat "${PID_FILE}")" >/dev/null 2>&1; then
      echo "Site server already running at ${BASE_URL}"
    else
      rm -rf site/.next 2>/dev/null || true
      nohup npm --prefix site run dev -- --port "${PORT}" >"${LOG_FILE}" 2>&1 </dev/null &
      echo "$!" >"${PID_FILE}"
    fi
    ;;
  *)
    echo "usage: $0 [public|local]" >&2
    exit 1
    ;;
esac

if [[ "${MODE}" == "local" ]]; then
  for _ in {1..60}; do
    if curl -fsS "${BASE_URL}" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
fi

if ! curl -fsS "${BASE_URL}" >/dev/null; then
  echo "Could not start site at ${BASE_URL}" >&2
  tail -80 "${LOG_FILE}" >&2 || true
  exit 1
fi

bash scripts/bundle_macos_app.sh >/tmp/chip-heat-lab-recording-bundle.log 2>&1

open "${BASE_URL}/"
open "${BASE_URL}/replay?snapshot=inference_spread"
open "${BASE_URL}/knowledge"
open -n dist/ChipHeatLab.app

cat <<TEXT
Recording session ready.

Site:      ${BASE_URL}/
Replay:    ${BASE_URL}/replay?snapshot=inference_spread
Knowledge: ${BASE_URL}/knowledge
Native:    ${ROOT}/dist/ChipHeatLab.app

Use docs/demo-recording-runbook.md for the click path.
Stop local mode or quit the native app with: bash scripts/stop_recording_session.sh
TEXT
