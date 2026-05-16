import fs from "node:fs";
import path from "node:path";

export type Snapshot = {
  scenario_name: string;
  grid_size: number;
  ambient_c: number;
  controls: {
    workload_phase: string;
    power_scale: number;
    cooling_preset: string;
    floorplan_mode: string;
  };
  temperature_grid: number[][];
  peak_c: number;
  peak_cell: { x: number; y: number };
  hotspot_centroid: { x: number; y: number };
  per_block_max: Record<string, number>;
  residual: number;
  iterations: number;
  warnings: string[];
};

export function snapshotDir() {
  return path.join(process.cwd(), "public", "snapshots");
}

export function listSnapshots() {
  const dir = snapshotDir();
  if (!fs.existsSync(dir)) {
    return [];
  }
  return fs
    .readdirSync(dir)
    .filter((file) => file.endsWith(".json"))
    .sort()
    .map((file) => file.replace(/\.json$/, ""));
}

export function loadSnapshot(name: string): Snapshot {
  const file = path.join(snapshotDir(), `${name}.json`);
  return JSON.parse(fs.readFileSync(file, "utf8")) as Snapshot;
}

export function loadSnapshots() {
  return listSnapshots().map((name) => ({ name, snapshot: loadSnapshot(name) }));
}
