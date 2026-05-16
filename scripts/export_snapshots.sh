#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CARGO_BIN="${CARGO:-${HOME}/.cargo/bin/cargo}"
if [[ ! -x "${CARGO_BIN}" ]]; then
  CARGO_BIN="cargo"
fi

mkdir -p "${ROOT}/snapshots" "${ROOT}/site/public/snapshots"

run_snapshot() {
  local name="$1"
  local phase="$2"
  local power="$3"
  local cooling="$4"
  local floorplan="$5"
  local input
  input="$(mktemp)"
  cat > "${input}" <<JSON
{
  "scenario_name": "flagship_ai_accelerator_${name}",
  "ambient_c": 35.0,
  "conductivity": 0.62,
  "controls": {
    "workload_phase": "${phase}",
    "power_scale": ${power},
    "cooling_preset": "${cooling}",
    "floorplan_mode": "${floorplan}"
  }
}
JSON
  "${CARGO_BIN}" run --quiet -p chip_heat_cli -- --input "${input}" > "${ROOT}/snapshots/${name}.json"
  cp "${ROOT}/snapshots/${name}.json" "${ROOT}/site/public/snapshots/${name}.json"
  rm -f "${input}"
}

cd "${ROOT}"
run_snapshot balanced balanced 1.0 airflow clustered_sram
run_snapshot training training_matmul 1.0 airflow clustered_sram
run_snapshot inference_clustered inference_kv 1.0 airflow clustered_sram
run_snapshot inference_spread inference_kv 1.0 airflow spread_sram
run_snapshot aggressive_cooling training_matmul 1.0 aggressive clustered_sram

echo "exported snapshots to snapshots/ and site/public/snapshots/"
