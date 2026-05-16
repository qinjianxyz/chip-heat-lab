import fs from "node:fs";
import path from "node:path";

export type ValueBenchmark = {
  schema_version: string;
  design_question: string;
  model_authority: string;
  pass: boolean;
  non_claim: string;
  cases: Record<string, {
    peak_c: number;
    peak_cell: { x: number; y: number };
    hotspot_centroid: { x: number; y: number };
    residual: number;
    iterations: number;
    warnings: string[];
  }>;
  comparisons: {
    kv_sram_floorplan_intervention: {
      peak_reduction_c: number;
      sram_max_reduction_c: number;
      centroid_shift: {
        dx_cells: number;
        dy_cells: number;
        distance_cells: number;
      };
      pass: boolean;
      pass_condition: string;
    };
    training_cooling_intervention: {
      peak_reduction_c: number;
      pass: boolean;
      pass_condition: string;
    };
  };
  quality_gates: {
    max_residual: number;
    max_iterations: number;
    no_warnings: boolean;
    pass: boolean;
  };
};

export function loadValueBenchmark(): ValueBenchmark | null {
  const file = path.join(process.cwd(), "public", "benchmarks", "value_loop", "results.json");
  if (!fs.existsSync(file)) {
    return null;
  }
  return JSON.parse(fs.readFileSync(file, "utf8")) as ValueBenchmark;
}
