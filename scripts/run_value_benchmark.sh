#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CARGO_BIN="${CARGO:-${HOME}/.cargo/bin/cargo}"
if [[ ! -x "${CARGO_BIN}" ]]; then
  CARGO_BIN="cargo"
fi

RESULTS="${ROOT}/benchmarks/value_loop/results.json"
SITE_RESULTS="${ROOT}/site/public/benchmarks/value_loop/results.json"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "$(dirname "${RESULTS}")" "$(dirname "${SITE_RESULTS}")"

write_input() {
  local name="$1"
  local phase="$2"
  local cooling="$3"
  local floorplan="$4"
  cat > "${TMP_DIR}/${name}.json" <<JSON
{
  "scenario_name": "value_loop_${name}",
  "ambient_c": 35.0,
  "conductivity": 0.62,
  "controls": {
    "workload_phase": "${phase}",
    "power_scale": 1.0,
    "cooling_preset": "${cooling}",
    "floorplan_mode": "${floorplan}"
  }
}
JSON
}

run_case() {
  local name="$1"
  "${CARGO_BIN}" run --quiet -p chip_heat_cli -- --input "${TMP_DIR}/${name}.json" > "${TMP_DIR}/${name}.out.json"
}

cd "${ROOT}"

write_input kv_clustered_sram inference_kv airflow clustered_sram
write_input kv_spread_sram inference_kv airflow spread_sram
write_input training_airflow training_matmul airflow clustered_sram
write_input training_aggressive_cooling training_matmul aggressive clustered_sram

run_case kv_clustered_sram
run_case kv_spread_sram
run_case training_airflow
run_case training_aggressive_cooling

# Python is used only as JSON aggregation glue: the Rust CLI above remains the
# only simulation authority and every metric below is copied or derived from its
# SimulationResult outputs.
python3 - "${TMP_DIR}" "${RESULTS}" "${SITE_RESULTS}" <<'PY'
import json
import math
import shutil
import sys
from pathlib import Path

tmp_dir = Path(sys.argv[1])
results_path = Path(sys.argv[2])
site_results_path = Path(sys.argv[3])

case_order = [
    "kv_clustered_sram",
    "kv_spread_sram",
    "training_airflow",
    "training_aggressive_cooling",
]


def load_case(name: str) -> dict:
    raw = json.loads((tmp_dir / f"{name}.out.json").read_text(encoding="utf-8"))
    return {
        "scenario_name": raw["scenario_name"],
        "controls": raw["controls"],
        "peak_c": raw["peak_c"],
        "peak_cell": raw["peak_cell"],
        "hotspot_centroid": raw["hotspot_centroid"],
        "sram_max_c": raw["per_block_max"]["SRAM / KV Cache"],
        "residual": raw["residual"],
        "iterations": raw["iterations"],
        "warnings": raw["warnings"],
    }


def centroid_shift(a: dict, b: dict) -> dict:
    dx = b["hotspot_centroid"]["x"] - a["hotspot_centroid"]["x"]
    dy = b["hotspot_centroid"]["y"] - a["hotspot_centroid"]["y"]
    return {
        "dx_cells": round(dx, 3),
        "dy_cells": round(dy, 3),
        "distance_cells": round(math.hypot(dx, dy), 3),
    }


def peak_cell_shift(a: dict, b: dict) -> dict:
    return {
        "dx_cells": b["peak_cell"]["x"] - a["peak_cell"]["x"],
        "dy_cells": b["peak_cell"]["y"] - a["peak_cell"]["y"],
    }


cases = {name: load_case(name) for name in case_order}
kv_clustered = cases["kv_clustered_sram"]
kv_spread = cases["kv_spread_sram"]
training_airflow = cases["training_airflow"]
training_aggressive = cases["training_aggressive_cooling"]

layout_reduction = round(kv_clustered["peak_c"] - kv_spread["peak_c"], 3)
cooling_reduction = round(training_airflow["peak_c"] - training_aggressive["peak_c"], 3)

max_residual = max(case["residual"] for case in cases.values())
max_iterations = max(case["iterations"] for case in cases.values())
warnings = {name: case["warnings"] for name, case in cases.items() if case["warnings"]}

results = {
    "schema_version": "chip_heat_lab.value_loop.v1",
    "generated_by": "scripts/run_value_benchmark.sh",
    "model_authority": "chip_heat_cli Rust CLI SimulationResult JSON",
    "design_question": "For a KV-cache-heavy workload, does spreading SRAM change hotspot/peak behavior before spending cooling budget?",
    "cases": cases,
    "comparisons": {
        "kv_sram_floorplan_intervention": {
            "baseline": "kv_clustered_sram",
            "intervention": "kv_spread_sram",
            "peak_reduction_c": layout_reduction,
            "sram_max_reduction_c": round(kv_clustered["sram_max_c"] - kv_spread["sram_max_c"], 3),
            "centroid_shift": centroid_shift(kv_clustered, kv_spread),
            "peak_cell_shift": peak_cell_shift(kv_clustered, kv_spread),
            "pass": layout_reduction > 0.1,
            "pass_condition": "spread SRAM lowers KV workload peak by more than 0.1 C in the simplified model",
        },
        "training_cooling_intervention": {
            "baseline": "training_airflow",
            "intervention": "training_aggressive_cooling",
            "peak_reduction_c": cooling_reduction,
            "centroid_shift": centroid_shift(training_airflow, training_aggressive),
            "peak_cell_shift": peak_cell_shift(training_airflow, training_aggressive),
            "pass": cooling_reduction > 0.1,
            "pass_condition": "aggressive cooling lowers training workload peak by more than 0.1 C in the simplified model",
        },
    },
    "quality_gates": {
        "max_residual": max_residual,
        "max_iterations": max_iterations,
        "no_warnings": not warnings,
        "pass": max_residual < 1e-6 and max_iterations < 20000 and not warnings,
        "warnings_by_case": warnings,
    },
    "non_claim": "Usefulness proof for this simplified early-design thermal intuition demo; not physical validation.",
}

all_pass = (
    results["comparisons"]["kv_sram_floorplan_intervention"]["pass"]
    and results["comparisons"]["training_cooling_intervention"]["pass"]
    and results["quality_gates"]["pass"]
)
results["pass"] = all_pass

results_path.write_text(json.dumps(results, indent=2, sort_keys=True) + "\n", encoding="utf-8")
site_results_path.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(results_path, site_results_path)

summary = results["comparisons"]["kv_sram_floorplan_intervention"]
cooling = results["comparisons"]["training_cooling_intervention"]
print("value benchmark summary")
print(f"kv_clustered_sram_peak_c={kv_clustered['peak_c']:.3f}")
print(f"kv_spread_sram_peak_c={kv_spread['peak_c']:.3f}")
print(f"kv_peak_reduction_c={summary['peak_reduction_c']:.3f}")
print(f"kv_centroid_shift_cells={summary['centroid_shift']['dx_cells']:.3f},{summary['centroid_shift']['dy_cells']:.3f}")
print(f"training_airflow_peak_c={training_airflow['peak_c']:.3f}")
print(f"training_aggressive_peak_c={training_aggressive['peak_c']:.3f}")
print(f"cooling_peak_reduction_c={cooling['peak_reduction_c']:.3f}")
print(f"max_residual={max_residual:.3e}")
print(f"max_iterations={max_iterations}")
print(f"pass={all_pass}")

if not all_pass:
    raise SystemExit(1)
PY
