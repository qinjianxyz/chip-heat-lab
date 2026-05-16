#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CARGO_BIN="${CARGO:-${HOME}/.cargo/bin/cargo}"
if [[ ! -x "${CARGO_BIN}" ]]; then
  CARGO_BIN="cargo"
fi

cd "${ROOT}"

echo "== rust tests =="
"${CARGO_BIN}" test --quiet

echo "== flagship cli =="
"${CARGO_BIN}" run --quiet -p chip_heat_cli -- --input scenarios/flagship.json >/tmp/chip-heat-lab-flagship.json
python3 - <<'PY'
import json
data=json.load(open('/tmp/chip-heat-lab-flagship.json'))
assert data['grid_size'] == 96
assert data['temperature_grid']
assert data['peak_c'] > data['ambient_c']
print(f"peak_c={data['peak_c']} peak_cell={data['peak_cell']}")
PY

echo "== cli stdin =="
"${CARGO_BIN}" run --quiet -p chip_heat_cli < scenarios/flagship.json >/tmp/chip-heat-lab-stdin.json
python3 - <<'PY'
import json
data=json.load(open('/tmp/chip-heat-lab-stdin.json'))
assert data['grid_size'] == 96
print(f"stdin_peak_c={data['peak_c']}")
PY

echo "== kb index =="
python3 scripts/generate_kb_index.py

echo "== snapshots =="
bash scripts/export_snapshots.sh

echo "== value benchmark =="
bash scripts/run_value_benchmark.sh

echo "== transient value benchmark =="
bash scripts/run_transient_value_benchmark.sh

echo "== macos resources =="
bash scripts/prepare_macos_resources.sh

if command -v swift >/dev/null 2>&1; then
  echo "== swift build =="
  (cd apps/macos/ChipHeatLab && swift build -q)
else
  echo "== swift build skipped: swift unavailable =="
fi

echo "== non-claim lint =="
python3 scripts/lint_nonclaims.py

if [[ -f site/package.json ]]; then
  if [[ -d site/node_modules ]]; then
    echo "== site build =="
    npm --prefix site run build --silent
  else
    echo "== site build skipped: site/node_modules missing =="
  fi
fi

echo "verify ok"
