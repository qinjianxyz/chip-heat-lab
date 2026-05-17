import { ReplayExplorer } from "../../components/ReplayExplorer";
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
      <ReplayExplorer snapshots={snapshots} initialName={requested} />
    </section>
  );
}
