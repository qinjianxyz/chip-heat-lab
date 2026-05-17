#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="${ROOT}/dist/recording-session/site.pid"

if [[ -f "${PID_FILE}" ]]; then
  PID="$(cat "${PID_FILE}")"
  if kill -0 "${PID}" >/dev/null 2>&1; then
    kill "${PID}" >/dev/null 2>&1 || true
    wait "${PID}" >/dev/null 2>&1 || true
    echo "Stopped Chip Heat Lab recording site server (${PID})."
  fi
  rm -f "${PID_FILE}"
else
  echo "No Chip Heat Lab recording site server PID file found."
fi

osascript -e 'tell application id "xyz.qinjian.chipheatlab" to quit' >/dev/null 2>&1 || true
