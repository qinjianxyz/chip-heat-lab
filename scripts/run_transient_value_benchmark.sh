#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CARGO_BIN="${CARGO:-${HOME}/.cargo/bin/cargo}"
if [[ ! -x "${CARGO_BIN}" ]]; then
  CARGO_BIN="cargo"
fi

RESULTS="${ROOT}/benchmarks/transient_value_loop/results.json"
SITE_RESULTS="${ROOT}/site/public/benchmarks/transient_value_loop/results.json"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "$(dirname "${RESULTS}")" "$(dirname "${SITE_RESULTS}")"

write_trace() {
  local name="$1"
  local cooling="$2"
  local floorplan="$3"
  local segments_json="$4"
  cat >"${TMP_DIR}/${name}.json" <<JSON
{
  "scenario_name": "transient_value_${name}",
  "ambient_c": 35.0,
  "conductivity": 0.62,
  "cooling_preset": "${cooling}",
  "floorplan_mode": "${floorplan}",
  "thermal_capacitance": 0.45,
  "time_step_s": 0.05,
  "risk_threshold_c": 70.0,
  "sample_interval_s": 1.0,
  "segments": ${segments_json}
}
JSON
}

BASE_TRACE='[
  {"label":"prefill_burst","workload_phase":"training_matmul","duration_s":8.0,"power_scale":1.35},
  {"label":"kv_decode","workload_phase":"inference_kv","duration_s":26.0,"power_scale":1.05},
  {"label":"io_flush","workload_phase":"io_burst","duration_s":4.0,"power_scale":1.10},
  {"label":"kv_decode_tail","workload_phase":"inference_kv","duration_s":16.0,"power_scale":0.95}
]'

STAGGERED_TRACE='[
  {"label":"prefill_burst_a","workload_phase":"training_matmul","duration_s":4.0,"power_scale":1.08},
  {"label":"kv_decode_a","workload_phase":"inference_kv","duration_s":13.0,"power_scale":0.98},
  {"label":"prefill_burst_b","workload_phase":"training_matmul","duration_s":4.0,"power_scale":1.08},
  {"label":"kv_decode_b","workload_phase":"inference_kv","duration_s":17.0,"power_scale":0.98},
  {"label":"io_flush","workload_phase":"io_burst","duration_s":4.0,"power_scale":1.00},
  {"label":"kv_decode_tail","workload_phase":"inference_kv","duration_s":12.0,"power_scale":0.90}
]'

run_case() {
  local name="$1"
  "${CARGO_BIN}" run --quiet -p chip_heat_cli -- --transient --input "${TMP_DIR}/${name}.json" >"${TMP_DIR}/${name}.out.json"
}

cd "${ROOT}"

write_trace baseline_clustered airflow clustered_sram "${BASE_TRACE}"
write_trace spread_sram airflow spread_sram "${BASE_TRACE}"
write_trace aggressive_cooling aggressive clustered_sram "${BASE_TRACE}"
write_trace staggered_workload airflow clustered_sram "${STAGGERED_TRACE}"

run_case baseline_clustered
run_case spread_sram
run_case aggressive_cooling
run_case staggered_workload

# Python only aggregates JSON emitted by the Rust transient solver path.
python3 - "${TMP_DIR}" "${RESULTS}" "${SITE_RESULTS}" <<'PY'
import json
import shutil
import sys
from pathlib import Path

tmp_dir = Path(sys.argv[1])
results_path = Path(sys.argv[2])
site_results_path = Path(sys.argv[3])
case_order = ["baseline_clustered", "spread_sram", "aggressive_cooling", "staggered_workload"]


def load_case(name: str) -> dict:
    raw = json.loads((tmp_dir / f"{name}.out.json").read_text(encoding="utf-8"))
    metrics = raw["metrics"]
    return {
        "scenario_name": raw["scenario_name"],
        "cooling_preset": raw["cooling_preset"],
        "floorplan_mode": raw["floorplan_mode"],
        "risk_threshold_c": raw["risk_threshold_c"],
        "segments": raw["segments"],
        "frame_count": len(raw["frames"]),
        "metrics": {
            "max_peak_c": metrics["max_peak_c"],
            "final_peak_c": metrics["final_peak_c"],
            "peak_time_s": metrics["peak_time_s"],
            "time_above_threshold_s": metrics["time_above_threshold_s"],
            "thermal_dose_c_s": metrics["thermal_dose_c_s"],
            "max_gradient_c_per_cell": metrics["max_gradient_c_per_cell"],
            "hotspot_path_distance_cells": metrics["hotspot_path_distance_cells"],
            "per_segment_peak_c": metrics["per_segment_peak_c"],
        },
        "warnings": raw["warnings"],
    }


def improvement(base: dict, other: dict) -> dict:
    b = base["metrics"]
    o = other["metrics"]
    return {
        "peak_reduction_c": round(b["max_peak_c"] - o["max_peak_c"], 3),
        "time_above_threshold_reduction_s": round(
            b["time_above_threshold_s"] - o["time_above_threshold_s"], 3
        ),
        "thermal_dose_reduction_c_s": round(b["thermal_dose_c_s"] - o["thermal_dose_c_s"], 3),
        "gradient_reduction_c_per_cell": round(
            b["max_gradient_c_per_cell"] - o["max_gradient_c_per_cell"], 3
        ),
    }


cases = {name: load_case(name) for name in case_order}
baseline = cases["baseline_clustered"]
comparisons = {
    "spread_sram_floorplan": improvement(baseline, cases["spread_sram"]),
    "aggressive_cooling": improvement(baseline, cases["aggressive_cooling"]),
    "staggered_workload": improvement(baseline, cases["staggered_workload"]),
}

ranked = sorted(
    (
        {
            "intervention": name,
            "peak_reduction_c": values["peak_reduction_c"],
            "thermal_dose_reduction_c_s": values["thermal_dose_reduction_c_s"],
            "time_above_threshold_reduction_s": values["time_above_threshold_reduction_s"],
        }
        for name, values in comparisons.items()
    ),
    key=lambda item: (
        item["thermal_dose_reduction_c_s"],
        item["time_above_threshold_reduction_s"],
        item["peak_reduction_c"],
    ),
    reverse=True,
)

warnings = {name: case["warnings"] for name, case in cases.items() if case["warnings"]}
pass_gate = (
    baseline["metrics"]["time_above_threshold_s"] > 0.0
    and comparisons["spread_sram_floorplan"]["thermal_dose_reduction_c_s"] > 0.1
    and comparisons["aggressive_cooling"]["peak_reduction_c"] > comparisons["spread_sram_floorplan"]["peak_reduction_c"]
    and comparisons["staggered_workload"]["thermal_dose_reduction_c_s"] > 0.1
    and not warnings
)

results = {
    "schema_version": "chip_heat_lab.transient_value_loop.v1",
    "generated_by": "scripts/run_transient_value_benchmark.sh",
    "model_authority": "chip_heat_cli Rust CLI TransientSimulationResult JSON",
    "design_question": "For a bursty AI accelerator workload trace, which intervention lowers thermal risk: spreading SRAM, stronger cooling, or workload staggering?",
    "cases": cases,
    "comparisons": comparisons,
    "ranked_interventions": ranked,
    "quality_gates": {
        "baseline_has_time_above_threshold": baseline["metrics"]["time_above_threshold_s"] > 0.0,
        "no_warnings": not warnings,
        "warnings_by_case": warnings,
        "pass": pass_gate,
    },
    "non_claim": "Transient risk ranking for this simplified early-design demo only; not physical validation.",
    "pass": pass_gate,
}

results_path.write_text(json.dumps(results, indent=2, sort_keys=True) + "\n", encoding="utf-8")
site_results_path.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(results_path, site_results_path)

base = baseline["metrics"]
print("transient value benchmark summary")
print(f"baseline_max_peak_c={base['max_peak_c']:.3f}")
print(f"baseline_time_above_threshold_s={base['time_above_threshold_s']:.3f}")
print(f"baseline_thermal_dose_c_s={base['thermal_dose_c_s']:.3f}")
for name, values in comparisons.items():
    print(f"{name}_peak_reduction_c={values['peak_reduction_c']:.3f}")
    print(f"{name}_dose_reduction_c_s={values['thermal_dose_reduction_c_s']:.3f}")
print(f"top_intervention={ranked[0]['intervention']}")
print(f"pass={pass_gate}")

if not pass_gate:
    raise SystemExit(1)
PY
