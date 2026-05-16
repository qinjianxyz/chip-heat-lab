#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CARGO_BIN="${CARGO:-${HOME}/.cargo/bin/cargo}"
if [[ ! -x "${CARGO_BIN}" ]]; then
  CARGO_BIN="cargo"
fi

cd "${ROOT}"
"${CARGO_BIN}" build --quiet --release -p chip_heat_cli
mkdir -p apps/macos/ChipHeatLab/Resources/bin apps/macos/ChipHeatLab/Resources/scenarios
cp target/release/chip_heat_cli apps/macos/ChipHeatLab/Resources/bin/chip_heat_cli
cp scenarios/flagship.json apps/macos/ChipHeatLab/Resources/scenarios/flagship.json
python3 scripts/generate_kb_index.py >/tmp/chip-heat-kb-index.log
echo "prepared macOS resources"
echo "apps/macos/ChipHeatLab/Resources/bin/chip_heat_cli"
echo "apps/macos/ChipHeatLab/Resources/kb_index.json"
