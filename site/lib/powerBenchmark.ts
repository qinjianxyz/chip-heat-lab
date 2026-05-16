import fs from "node:fs";
import path from "node:path";

type PowerCase = {
  workload_phase: string;
  floorplan_mode: string;
  bump_preset: string;
  bump_count: number;
  worst_droop_mv: number;
  hotspot_distance_cells: number;
  overlap_score: number;
  residual: number;
  iterations: number;
};

export type PowerBenchmark = {
  schema_version: string;
  design_question: string;
  model_authority: string;
  pass: boolean;
  non_claim: string;
  cases: Record<string, PowerCase>;
  comparisons: {
    sparse_to_nominal_bumps: {
      droop_reduction_mv: number;
      bump_count_delta: number;
    };
    nominal_to_dense_bumps: {
      droop_reduction_mv: number;
      bump_count_delta: number;
    };
    clustered_to_spread_sram: {
      droop_reduction_mv: number;
      hotspot_distance_delta_cells: number;
    };
  };
};

export function loadPowerBenchmark(): PowerBenchmark | null {
  const file = path.join(process.cwd(), "public", "benchmarks", "power_delivery_proxy", "results.json");
  if (!fs.existsSync(file)) {
    return null;
  }
  return JSON.parse(fs.readFileSync(file, "utf8")) as PowerBenchmark;
}
