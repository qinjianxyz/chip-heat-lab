#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v gbrain >/dev/null 2>&1; then
  echo "gbrain CLI not found; install or configure GBrain before importing." >&2
  exit 2
fi

gbrain import "${ROOT}/kb" --source chip-heat-lab
