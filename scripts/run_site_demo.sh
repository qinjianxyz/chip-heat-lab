#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

if [[ ! -d site/node_modules ]]; then
  npm --prefix site install --silent
fi

echo "Starting Chip Heat Lab site on http://localhost:4177"
exec npm --prefix site run dev -- --port 4177
