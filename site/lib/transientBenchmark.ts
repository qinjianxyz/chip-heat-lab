import fs from "node:fs";
import path from "node:path";

type Metrics = {
  max_peak_c: number;
  final_peak_c: number;
  peak_time_s: number;
  time_above_threshold_s: number;
  thermal_dose_c_s: number;
  max_gradient_c_per_cell: number;
  hotspot_path_distance_cells: number;
};

export type TransientBenchmark = {
  schema_version: string;
  design_question: string;
  model_authority: string;
  pass: boolean;
  non_claim: string;
  cases: Record<string, {
    cooling_preset: string;
    floorplan_mode: string;
    risk_threshold_c: number;
    frame_count: number;
    metrics: Metrics;
    warnings: string[];
  }>;
  comparisons: Record<string, {
    peak_reduction_c: number;
    time_above_threshold_reduction_s: number;
    thermal_dose_reduction_c_s: number;
    gradient_reduction_c_per_cell: number;
  }>;
  ranked_interventions: Array<{
    intervention: string;
    peak_reduction_c: number;
    thermal_dose_reduction_c_s: number;
    time_above_threshold_reduction_s: number;
  }>;
  quality_gates: {
    baseline_has_time_above_threshold: boolean;
    no_warnings: boolean;
    pass: boolean;
  };
};

export function loadTransientBenchmark(): TransientBenchmark | null {
  const file = path.join(process.cwd(), "public", "benchmarks", "transient_value_loop", "results.json");
  if (!fs.existsSync(file)) {
    return null;
  }
  return JSON.parse(fs.readFileSync(file, "utf8")) as TransientBenchmark;
}
