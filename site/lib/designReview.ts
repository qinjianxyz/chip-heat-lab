import fs from "node:fs";
import path from "node:path";

export type DesignCandidate = {
  intervention: string;
  label: string;
  pass: boolean;
  steady_peak_c: number;
  transient_max_peak_c: number;
  time_above_threshold_s: number;
  thermal_dose_c_s: number;
  max_gradient_c_per_cell: number;
  hotspot_path_distance_cells: number;
  worst_droop_mv: number;
  thermal_pdn_distance_cells: number;
  overlap_score: number;
  risk_utilization: {
    steady_peak: number;
    thermal_dose: number;
    worst_droop: number;
    overlap: number;
  };
  cost_score: number;
  constraint_violations: string[];
  rank_score: number;
  reason: string;
};

export type DesignReview = {
  schema_version: string;
  design_question: string;
  model_authority: string;
  pass: boolean;
  non_claim: string;
  baseline: DesignCandidate;
  ranked_candidates: DesignCandidate[];
  recommended_intervention: string;
  recommended_label: string;
  pareto_frontier: string[];
  constraints: {
    peak_limit_c: number;
    droop_limit_mv: number;
    thermal_dose_limit_c_s: number;
    overlap_limit: number;
  };
  quality_gates: {
    baseline_fails_constraints: boolean;
    recommended_is_spread_sram: boolean;
    recommended_passes_constraints: boolean;
    recommended_improves_all_primary_metrics: boolean;
    pass: boolean;
  };
};

export type ConstraintRow = {
  id: string;
  label: string;
  limit: number;
  unit: string;
  baseline: number;
  recommended: number;
  baselinePass: boolean;
  recommendedPass: boolean;
};

export function getRecommendedCandidate(review: DesignReview): DesignCandidate {
  return (
    review.ranked_candidates.find(
      (candidate) => candidate.intervention === review.recommended_intervention
    ) ?? review.ranked_candidates[0]
  );
}

export function getConstraintRows(review: DesignReview): ConstraintRow[] {
  const baseline = review.baseline;
  const recommended = getRecommendedCandidate(review);
  const rows = [
    {
      id: "steady_peak",
      label: "Steady KV peak",
      limit: review.constraints.peak_limit_c,
      unit: "C",
      baseline: baseline.steady_peak_c,
      recommended: recommended.steady_peak_c,
    },
    {
      id: "thermal_dose",
      label: "Transient dose",
      limit: review.constraints.thermal_dose_limit_c_s,
      unit: "C-s",
      baseline: baseline.thermal_dose_c_s,
      recommended: recommended.thermal_dose_c_s,
    },
    {
      id: "worst_droop",
      label: "Worst IR drop",
      limit: review.constraints.droop_limit_mv,
      unit: "mV",
      baseline: baseline.worst_droop_mv,
      recommended: recommended.worst_droop_mv,
    },
    {
      id: "overlap",
      label: "Thermal / PDN overlap",
      limit: review.constraints.overlap_limit,
      unit: "score",
      baseline: baseline.overlap_score,
      recommended: recommended.overlap_score,
    },
  ];

  return rows.map((row) => ({
    ...row,
    baselinePass: row.baseline <= row.limit,
    recommendedPass: row.recommended <= row.limit,
  }));
}

export function formatViolation(violation: string): string {
  return violation.replaceAll("_", " ");
}

export function formatMetric(value: number, unit: string): string {
  const digits = unit === "score" ? 2 : 1;
  return `${value.toFixed(digits)} ${unit}`;
}

export function loadDesignReview(): DesignReview | null {
  const file = path.join(process.cwd(), "public", "benchmarks", "design_review", "results.json");
  if (!fs.existsSync(file)) {
    return null;
  }
  return JSON.parse(fs.readFileSync(file, "utf8")) as DesignReview;
}
