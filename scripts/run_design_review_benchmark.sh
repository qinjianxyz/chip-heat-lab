#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CARGO_BIN="${CARGO:-${HOME}/.cargo/bin/cargo}"
if [[ ! -x "${CARGO_BIN}" ]]; then
  CARGO_BIN="cargo"
fi

RESULTS="${ROOT}/benchmarks/design_review/results.json"
SITE_RESULTS="${ROOT}/site/public/benchmarks/design_review/results.json"
TMP_RESULT_A="$(mktemp)"
TMP_RESULT_B="$(mktemp)"
trap 'rm -f "${TMP_RESULT_A}" "${TMP_RESULT_B}"' EXIT

mkdir -p "$(dirname "${RESULTS}")" "$(dirname "${SITE_RESULTS}")"

cd "${ROOT}"

"${CARGO_BIN}" run --quiet -p chip_heat_cli -- --design-review >"${TMP_RESULT_A}"
"${CARGO_BIN}" run --quiet -p chip_heat_cli -- --design-review >"${TMP_RESULT_B}"

# Python validates JSON emitted by the Rust design-review mode and copies it for the site.
python3 - "${TMP_RESULT_A}" "${TMP_RESULT_B}" "${RESULTS}" "${SITE_RESULTS}" <<'PY'
import json
import shutil
import sys
from pathlib import Path

tmp_result_a = Path(sys.argv[1])
tmp_result_b = Path(sys.argv[2])
results_path = Path(sys.argv[3])
site_results_path = Path(sys.argv[4])


def canonical(data):
    return json.dumps(data, sort_keys=True, separators=(",", ":"))


def require(condition, message):
    if not condition:
        raise SystemExit(message)


def expected_violations(candidate, constraints):
    violations = []
    if candidate["steady_peak_c"] > constraints["peak_limit_c"]:
        violations.append("steady_kv_peak_above_limit")
    if candidate["thermal_dose_c_s"] > constraints["thermal_dose_limit_c_s"]:
        violations.append("transient_thermal_dose_above_limit")
    if candidate["worst_droop_mv"] > constraints["droop_limit_mv"]:
        violations.append("power_delivery_droop_above_limit")
    if candidate["overlap_score"] > constraints["overlap_limit"]:
        violations.append("thermal_droop_overlap_above_limit")
    return violations


def assert_candidate_consistency(candidate, constraints):
    expected = expected_violations(candidate, constraints)
    require(
        candidate["constraint_violations"] == expected,
        f"{candidate['intervention']} violations mismatch: expected {expected}, got {candidate['constraint_violations']}",
    )
    require(
        candidate["pass"] is (expected == []),
        f"{candidate['intervention']} pass flag does not match constraint violations",
    )


review = json.loads(tmp_result_a.read_text(encoding="utf-8"))
repeat = json.loads(tmp_result_b.read_text(encoding="utf-8"))
require(canonical(review) == canonical(repeat), "design review CLI output is not deterministic across repeated runs")

ranked = review["ranked_candidates"]
baseline = review["baseline"]
recommended = ranked[0]
constraints = review["constraints"]
expected_interventions = {
    "spread_sram",
    "spread_sram_dense_bumps",
    "spread_sram_dense_bumps_staggered",
    "staggered_workload",
    "aggressive_cooling",
    "dense_power_bumps",
}
interventions = {item["intervention"] for item in ranked}
require(interventions == expected_interventions, f"unexpected intervention set: {sorted(interventions)}")
require(len(ranked) == len(expected_interventions), "ranked candidate list contains duplicates")

sorted_ranked = sorted(ranked, key=lambda item: (item["rank_score"], item["cost_score"], item["label"]))
require(
    [item["intervention"] for item in ranked] == [item["intervention"] for item in sorted_ranked],
    "ranked candidates are not monotonic by rank_score, cost_score, label",
)

assert_candidate_consistency(baseline, constraints)
for candidate in ranked:
    assert_candidate_consistency(candidate, constraints)

passing = [item for item in ranked if item["pass"]]
require(passing, "expected at least one passing intervention")
lowest_cost_passing = min(passing, key=lambda item: (item["cost_score"], item["rank_score"], item["label"]))
require(
    lowest_cost_passing["intervention"] == review["recommended_intervention"],
    f"recommended intervention is not the lowest-cost passing candidate: {lowest_cost_passing['intervention']}",
)
require(
    recommended["intervention"] == review["recommended_intervention"],
    "first ranked candidate does not match recommended_intervention",
)

steady_peak_reduction_c = round(baseline["steady_peak_c"] - recommended["steady_peak_c"], 3)
thermal_dose_reduction_c_s = round(baseline["thermal_dose_c_s"] - recommended["thermal_dose_c_s"], 3)
worst_droop_reduction_mv = round(baseline["worst_droop_mv"] - recommended["worst_droop_mv"], 3)
pass_gate = (
    review["recommended_intervention"] == "spread_sram"
    and review["recommended_label"] == "Spread SRAM"
    and review["pass"] is True
    and baseline["pass"] is False
    and baseline["constraint_violations"]
    == [
        "steady_kv_peak_above_limit",
        "transient_thermal_dose_above_limit",
        "power_delivery_droop_above_limit",
    ]
    and "power_delivery_droop_above_limit" in baseline["constraint_violations"]
    and recommended["pass"] is True
    and recommended["constraint_violations"] == []
    and recommended["steady_peak_c"] < baseline["steady_peak_c"]
    and recommended["thermal_dose_c_s"] < baseline["thermal_dose_c_s"]
    and recommended["worst_droop_mv"] < baseline["worst_droop_mv"]
)

review["schema_version"] = "chip_heat_lab.design_review.v1"
review["generated_by"] = "scripts/run_design_review_benchmark.sh"
review["model_authority"] = "chip_heat_cli Rust CLI DesignReviewResult JSON"
review["non_claim"] = (
    "Early-design ranking for this clean-room demo only; not final verification, "
    "not manufacturing validation, not standards compliance, not package airflow analysis, "
    "and not a physical PDN model."
)
review["quality_gates"] = {
    "candidate_count": len(ranked),
    "deterministic_cli_output": True,
    "all_candidate_constraints_recomputed": True,
    "baseline_fails_constraints": baseline["pass"] is False,
    "baseline_fails_all_primary_constraints": baseline["constraint_violations"]
    == [
        "steady_kv_peak_above_limit",
        "transient_thermal_dose_above_limit",
        "power_delivery_droop_above_limit",
    ],
    "ranked_candidates_sorted_by_score": True,
    "lowest_cost_passing_intervention": lowest_cost_passing["intervention"],
    "recommended_is_spread_sram": review["recommended_intervention"] == "spread_sram",
    "recommended_passes_constraints": recommended["pass"] is True,
    "recommended_improves_all_primary_metrics": (
        recommended["steady_peak_c"] < baseline["steady_peak_c"]
        and recommended["thermal_dose_c_s"] < baseline["thermal_dose_c_s"]
        and recommended["worst_droop_mv"] < baseline["worst_droop_mv"]
    ),
    "pass": pass_gate,
}
review["benchmark_summary"] = {
    "baseline_intervention": baseline["intervention"],
    "recommended_intervention": review["recommended_intervention"],
    "passing_candidate_count": len(passing),
    "steady_peak_reduction_c": steady_peak_reduction_c,
    "thermal_dose_reduction_c_s": thermal_dose_reduction_c_s,
    "worst_droop_reduction_mv": worst_droop_reduction_mv,
    "baseline_max_gradient_c_per_cell": baseline["max_gradient_c_per_cell"],
    "recommended_max_gradient_c_per_cell": recommended["max_gradient_c_per_cell"],
    "baseline_hotspot_path_distance_cells": baseline["hotspot_path_distance_cells"],
    "recommended_hotspot_path_distance_cells": recommended["hotspot_path_distance_cells"],
    "baseline_thermal_pdn_distance_cells": baseline["thermal_pdn_distance_cells"],
    "recommended_thermal_pdn_distance_cells": recommended["thermal_pdn_distance_cells"],
}
review["pass"] = pass_gate

results_path.write_text(json.dumps(review, indent=2, sort_keys=True) + "\n", encoding="utf-8")
site_results_path.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(results_path, site_results_path)
require(results_path.read_bytes() == site_results_path.read_bytes(), "site design-review artifact differs from benchmark artifact")

print("design review benchmark summary")
print(f"baseline_steady_peak_c={baseline['steady_peak_c']:.3f}")
print(f"baseline_thermal_dose_c_s={baseline['thermal_dose_c_s']:.3f}")
print(f"baseline_worst_droop_mv={baseline['worst_droop_mv']:.3f}")
print(f"recommended={review['recommended_intervention']}")
print(f"recommended_steady_peak_c={recommended['steady_peak_c']:.3f}")
print(f"recommended_thermal_dose_c_s={recommended['thermal_dose_c_s']:.3f}")
print(f"recommended_worst_droop_mv={recommended['worst_droop_mv']:.3f}")
print(f"steady_peak_reduction_c={steady_peak_reduction_c:.3f}")
print(f"thermal_dose_reduction_c_s={thermal_dose_reduction_c_s:.3f}")
print(f"worst_droop_reduction_mv={worst_droop_reduction_mv:.3f}")
print(f"lowest_cost_passing={lowest_cost_passing['intervention']}")
print(f"passing_candidates={sum(1 for item in ranked if item['pass'])}")
print(f"pass={pass_gate}")

if not pass_gate:
    raise SystemExit(1)
PY
