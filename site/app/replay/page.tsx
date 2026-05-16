import Link from "next/link";
import { Heatmap } from "../../components/Heatmap";
import { loadSnapshots } from "../../lib/snapshots";
import { loadValueBenchmark } from "../../lib/valueBenchmark";

type ReplayPageProps = {
  searchParams?: Promise<{
    snapshot?: string | string[];
  }>;
};

function firstParam(value: string | string[] | undefined) {
  return Array.isArray(value) ? value[0] : value;
}

export default async function ReplayPage({ searchParams }: ReplayPageProps) {
  const snapshots = loadSnapshots();
  const params = searchParams ? await searchParams : {};
  const requested = firstParam(params.snapshot);
  const selected =
    snapshots.find(({ name }) => name === requested) ??
    snapshots.find(({ name }) => name === "balanced") ??
    snapshots[0];
  const benchmark = loadValueBenchmark();
  const kv = benchmark?.comparisons.kv_sram_floorplan_intervention;

  return (
    <section className="doc-layout">
      <h1>Replay</h1>
      <p>
        This page reads JSON snapshots exported by the Rust CLI. It does not run
        a second solver in the browser.
      </p>
      {benchmark ? (
        <div className="card benchmark-strip">
          <strong>Value benchmark:</strong>{" "}
          spread SRAM lowers the KV workload peak by {kv?.peak_reduction_c.toFixed(3)} C
          and moves the hotspot centroid {kv?.centroid_shift.distance_cells.toFixed(3)} grid cells
          in this simplified model.
        </div>
      ) : null}
      {selected ? (
        <div className="replay-grid">
          <div className="snapshot-list">
            {snapshots.map(({ name, snapshot }) => (
              <Link
                key={name}
                className={selected.name === name ? "selected" : ""}
                href={`/replay?snapshot=${name}`}
              >
                <strong>{name}</strong>
                <br />
                <span>
                  {snapshot.controls.workload_phase} · {snapshot.controls.cooling_preset} ·{" "}
                  {snapshot.controls.floorplan_mode}
                </span>
              </Link>
            ))}
          </div>
          <div className="demo-shell">
            <div className="demo-head">
              <span>{selected.name}</span>
              <span>exported Rust JSON</span>
            </div>
            <Heatmap snapshot={selected.snapshot} />
            <div className="snapshot-meta">
              <div className="metric"><strong>{selected.snapshot.peak_c.toFixed(1)}</strong><span>peak C</span></div>
              <div className="metric"><strong>{selected.snapshot.peak_cell.x},{selected.snapshot.peak_cell.y}</strong><span>peak cell</span></div>
              <div className="metric"><strong>{selected.snapshot.iterations}</strong><span>iterations</span></div>
            </div>
          </div>
        </div>
      ) : (
        <div className="card">
          <p>Run `bash scripts/export_snapshots.sh` to create replay snapshots.</p>
        </div>
      )}
    </section>
  );
}
