#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

bash scripts/prepare_macos_resources.sh
cd apps/macos/ChipHeatLab

echo "Launching native SwiftUI demo with bundled Rust CLI..."
exec swift run ChipHeatLab
