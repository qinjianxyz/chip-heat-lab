#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CARGO_BIN="${CARGO:-${HOME}/.cargo/bin/cargo}"
if [[ ! -x "${CARGO_BIN}" ]]; then
  CARGO_BIN="cargo"
fi

RESULTS="${ROOT}/benchmarks/power_delivery_proxy/results.json"
SITE_RESULTS="${ROOT}/site/public/benchmarks/power_delivery_proxy/results.json"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "$(dirname "${RESULTS}")" "$(dirname "${SITE_RESULTS}")"

write_case() {
  local name="$1"
  local workload="$2"
  local floorplan="$3"
  local bump_preset="$4"
  cat >"${TMP_DIR}/${name}.json" <<JSON
{
  "scenario_name": "power_delivery_${name}",
  "controls": {
    "workload_phase": "${workload}",
    "power_scale": 1.0,
    "cooling_preset": "airflow",
    "floorplan_mode": "${floorplan}"
  },
  "bump_preset": "${bump_preset}",
  "sheet_conductance": 0.26,
  "bump_conductance": 1.45,
  "droop_scale_mv": 0.05
}
JSON
}

run_case() {
  local name="$1"
  "${CARGO_BIN}" run --quiet -p chip_heat_cli -- --power-proxy --input "${TMP_DIR}/${name}.json" >"${TMP_DIR}/${name}.out.json"
}

cd "${ROOT}"

write_case kv_clustered_sparse inference_kv clustered_sram sparse
write_case kv_clustered_nominal inference_kv clustered_sram nominal
write_case kv_clustered_dense inference_kv clustered_sram dense
write_case kv_spread_nominal inference_kv spread_sram nominal
write_case training_nominal training_matmul clustered_sram nominal

run_case kv_clustered_sparse
run_case kv_clustered_nominal
run_case kv_clustered_dense
run_case kv_spread_nominal
run_case training_nominal

# Python only aggregates JSON emitted by the Rust power proxy path.
python3 - "${TMP_DIR}" "${RESULTS}" "${SITE_RESULTS}" <<'PY'
import json
import shutil
import sys
from pathlib import Path

tmp_dir = Path(sys.argv[1])
results_path = Path(sys.argv[2])
site_results_path = Path(sys.argv[3])
case_order = [
    "kv_clustered_sparse",
    "kv_clustered_nominal",
    "kv_clustered_dense",
    "kv_spread_nominal",
    "training_nominal",
]
expected_warning = "power_delivery_proxy_uses_idealized_bumps_and_demo_units"


def load_case(name: str) -> dict:
    raw = json.loads((tmp_dir / f"{name}.out.json").read_text(encoding="utf-8"))
    return {
        "scenario_name": raw["scenario_name"],
        "workload_phase": raw["controls"]["workload_phase"],
        "floorplan_mode": raw["controls"]["floorplan_mode"],
        "bump_preset": raw["bump_preset"],
        "bump_count": len(raw["bumps"]),
        "worst_droop_mv": raw["worst_droop_mv"],
        "worst_cell": raw["worst_cell"],
        "thermal_peak_cell": raw["thermal_peak_cell"],
        "thermal_peak_c": raw["thermal_peak_c"],
        "hotspot_distance_cells": raw["hotspot_distance_cells"],
        "overlap_score": raw["overlap_score"],
        "residual": raw["residual"],
        "iterations": raw["iterations"],
        "warnings": raw["warnings"],
        "per_block_worst_droop_mv": raw["per_block_worst_droop_mv"],
    }


def reduction(base: dict, other: dict) -> float:
    return round(base["worst_droop_mv"] - other["worst_droop_mv"], 3)


cases = {name: load_case(name) for name in case_order}
clustered_nominal = cases["kv_clustered_nominal"]
comparisons = {
    "sparse_to_nominal_bumps": {
        "droop_reduction_mv": reduction(cases["kv_clustered_sparse"], clustered_nominal),
        "bump_count_delta": cases["kv_clustered_nominal"]["bump_count"] - cases["kv_clustered_sparse"]["bump_count"],
    },
    "nominal_to_dense_bumps": {
        "droop_reduction_mv": reduction(clustered_nominal, cases["kv_clustered_dense"]),
        "bump_count_delta": cases["kv_clustered_dense"]["bump_count"] - cases["kv_clustered_nominal"]["bump_count"],
    },
    "clustered_to_spread_sram": {
        "droop_reduction_mv": reduction(clustered_nominal, cases["kv_spread_nominal"]),
        "hotspot_distance_delta_cells": round(
            clustered_nominal["hotspot_distance_cells"] - cases["kv_spread_nominal"]["hotspot_distance_cells"],
            3,
        ),
    },
}

unexpected_warnings = {
    name: case["warnings"]
    for name, case in cases.items()
    if [warning for warning in case["warnings"] if warning != expected_warning]
}

pass_gate = (
    cases["kv_clustered_sparse"]["worst_droop_mv"] > clustered_nominal["worst_droop_mv"]
    > cases["kv_clustered_dense"]["worst_droop_mv"]
    and comparisons["clustered_to_spread_sram"]["droop_reduction_mv"] > 1.0
    and clustered_nominal["overlap_score"] > 0.75
    and cases["kv_clustered_dense"]["residual"] < 1.0e-6
    and not unexpected_warnings
)

results = {
    "schema_version": "chip_heat_lab.power_delivery_proxy.v1",
    "generated_by": "scripts/run_power_delivery_benchmark.sh",
    "model_authority": "chip_heat_cli Rust CLI PowerDeliveryProxyResult JSON",
    "design_question": "For the same AI accelerator floorplan and power map, do bump density and SRAM placement change the simplified power-delivery stress proxy?",
    "cases": cases,
    "comparisons": comparisons,
    "quality_gates": {
        "sparse_nominal_dense_ordered": cases["kv_clustered_sparse"]["worst_droop_mv"]
        > clustered_nominal["worst_droop_mv"]
        > cases["kv_clustered_dense"]["worst_droop_mv"],
        "spread_sram_reduces_nominal_droop": comparisons["clustered_to_spread_sram"]["droop_reduction_mv"] > 1.0,
        "thermal_and_droop_hotspots_overlap": clustered_nominal["overlap_score"] > 0.75,
        "residual_bound": cases["kv_clustered_dense"]["residual"] < 1.0e-6,
        "unexpected_warnings_by_case": unexpected_warnings,
        "pass": pass_gate,
    },
    "non_claim": "Power-delivery proxy ranking for this simplified early-design demo only; not a physical PDN model.",
    "pass": pass_gate,
}

results_path.write_text(json.dumps(results, indent=2, sort_keys=True) + "\n", encoding="utf-8")
site_results_path.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(results_path, site_results_path)

print("power delivery proxy benchmark summary")
print(f"kv_clustered_sparse_worst_droop_mv={cases['kv_clustered_sparse']['worst_droop_mv']:.3f}")
print(f"kv_clustered_nominal_worst_droop_mv={clustered_nominal['worst_droop_mv']:.3f}")
print(f"kv_clustered_dense_worst_droop_mv={cases['kv_clustered_dense']['worst_droop_mv']:.3f}")
print(f"kv_spread_nominal_worst_droop_mv={cases['kv_spread_nominal']['worst_droop_mv']:.3f}")
print(f"nominal_to_dense_reduction_mv={comparisons['nominal_to_dense_bumps']['droop_reduction_mv']:.3f}")
print(f"clustered_to_spread_sram_reduction_mv={comparisons['clustered_to_spread_sram']['droop_reduction_mv']:.3f}")
print(f"thermal_droop_overlap_score={clustered_nominal['overlap_score']:.3f}")
print(f"pass={pass_gate}")

if not pass_gate:
    raise SystemExit(1)
PY
