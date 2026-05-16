#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

if [[ ! -d site/node_modules ]]; then
  npm --prefix site install --silent
fi

# Node 25 can expose global localStorage during Next dev. Some runtimes provide
# it without a storage file, which makes localStorage.getItem unavailable and
# crashes server rendering. Supplying a temp storage file keeps local review
# deterministic while remaining harmless on Node 24 in CI.
if [[ " ${NODE_OPTIONS:-} " != *" --localstorage-file="* ]]; then
  export NODE_OPTIONS="${NODE_OPTIONS:+${NODE_OPTIONS} }--localstorage-file=/tmp/chip-heat-lab-node-localstorage"
fi

echo "Starting Chip Heat Lab site on http://localhost:4177"
exec npm --prefix site run dev -- --port 4177
