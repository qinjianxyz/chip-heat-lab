import Link from "next/link";
import { Heatmap } from "../components/Heatmap";
import { loadPowerBenchmark } from "../lib/powerBenchmark";
import { loadSnapshots } from "../lib/snapshots";
import { loadTransientBenchmark } from "../lib/transientBenchmark";
import { loadValueBenchmark } from "../lib/valueBenchmark";

export default function HomePage() {
  const snapshots = loadSnapshots();
  const heroSnapshot = snapshots[0]?.snapshot;
  const benchmark = loadValueBenchmark();
  const transient = loadTransientBenchmark();
  const power = loadPowerBenchmark();
  const kv = benchmark?.comparisons.kv_sram_floorplan_intervention;
  const cooling = benchmark?.comparisons.training_cooling_intervention;
  const transientBaseline = transient?.cases.baseline_clustered.metrics;
  const topIntervention = transient?.ranked_interventions[0];
  const powerBaseline = power?.cases.kv_clustered_nominal;
  const powerDense = power?.cases.kv_clustered_dense;
  const powerSpread = power?.cases.kv_spread_nominal;

  return (
    <>
      <section className="hero">
        <div>
          <p className="eyebrow">Engineering simulation for chip design</p>
          <h1>Chip Heat Lab</h1>
          <p className="lead">
            A clean-room OSS hackathon demo where a Rust CLI solves one
            simplified early-design thermal workflow and one power-delivery
            proxy for a stylized AI accelerator floorplan, then ranks design
            interventions from exported benchmark JSON.
          </p>
          <div className="actions">
            <Link className="button primary" href="/replay">Open Replay</Link>
            <Link className="button" href="#transient-review">Transient Review</Link>
            <Link className="button" href="#power-proxy">Power Proxy</Link>
            <Link className="button" href="/model">Read Model</Link>
            <Link className="button" href="/knowledge">Knowledge Base</Link>
            <Link className="button" href="/non-claims">Claim Boundaries</Link>
            <a className="button" href="https://github.com/qinjianxyz/chip-heat-lab">GitHub</a>
          </div>
        </div>
        <div className="demo-shell">
          <div className="demo-head">
            <span>Rust snapshot replay</span>
            <span>{heroSnapshot ? `${heroSnapshot.peak_c.toFixed(1)} C peak` : "export snapshots"}</span>
          </div>
          {heroSnapshot ? <Heatmap snapshot={heroSnapshot} /> : <div className="section">Run `bash scripts/export_snapshots.sh`.</div>}
        </div>
      </section>

      <section className="section">
        <h2>One Flagship Loop</h2>
        <div className="grid">
          <div className="card">
            <h3>Workload</h3>
            <p>Switch workload phase to move the dominant heat source.</p>
          </div>
          <div className="card">
            <h3>Layout</h3>
            <p>Compare clustered SRAM with split SRAM and watch the field change.</p>
          </div>
          <div className="card">
            <h3>Cooling</h3>
            <p>Increase the cooling preset and show a lower peak in the same model.</p>
          </div>
        </div>
      </section>

      <section className="section value-loop" id="transient-review">
        <div>
          <p className="eyebrow">Value Benchmark</p>
          <h2>Answer one layout question</h2>
          <p>
            {benchmark?.design_question ?? "Run `bash scripts/run_value_benchmark.sh` to generate the value-loop benchmark."}
          </p>
          <p>
            The site reads exported benchmark JSON from the Rust CLI path; it
            does not compute solver outputs in the browser.
          </p>
        </div>
        <div className="grid">
          <div className="card metric-card">
            <strong>{benchmark ? benchmark.cases.kv_clustered_sram.peak_c.toFixed(1) : "--"}</strong>
            <span>KV clustered SRAM peak C</span>
          </div>
          <div className="card metric-card">
            <strong>{benchmark ? benchmark.cases.kv_spread_sram.peak_c.toFixed(1) : "--"}</strong>
            <span>KV spread SRAM peak C</span>
          </div>
          <div className="card metric-card">
            <strong>{kv ? kv.peak_reduction_c.toFixed(1) : "--"}</strong>
            <span>peak reduction C in this simplified model</span>
          </div>
          <div className="card metric-card">
            <strong>{kv ? kv.centroid_shift.distance_cells.toFixed(1) : "--"}</strong>
            <span>centroid shift in grid cells</span>
          </div>
          <div className="card metric-card">
            <strong>{cooling ? cooling.peak_reduction_c.toFixed(1) : "--"}</strong>
            <span>training cooling reduction C</span>
          </div>
          <div className="card metric-card">
            <strong>{benchmark?.pass ? "pass" : "--"}</strong>
            <span>benchmark gate</span>
          </div>
        </div>
      </section>

      <section className="section value-loop">
        <div>
          <p className="eyebrow">Transient Review</p>
          <h2>Rank design interventions</h2>
          <p>
            {transient?.design_question ?? "Run `bash scripts/run_transient_value_benchmark.sh` to generate the transient benchmark."}
          </p>
          <p>
            The transient path keeps heat from prior phases, then ranks layout,
            cooling, and workload-scheduling changes by peak, thermal dose, and
            time over the demo threshold.
          </p>
        </div>
        <div className="grid">
          <div className="card metric-card">
            <strong>{transientBaseline ? transientBaseline.max_peak_c.toFixed(1) : "--"}</strong>
            <span>baseline max peak C</span>
          </div>
          <div className="card metric-card">
            <strong>{transientBaseline ? transientBaseline.time_above_threshold_s.toFixed(1) : "--"}</strong>
            <span>seconds over threshold</span>
          </div>
          <div className="card metric-card">
            <strong>{transientBaseline ? transientBaseline.thermal_dose_c_s.toFixed(1) : "--"}</strong>
            <span>thermal dose C-s</span>
          </div>
          <div className="card metric-card">
            <strong>{topIntervention ? topIntervention.intervention.replaceAll("_", " ") : "--"}</strong>
            <span>top ranked intervention</span>
          </div>
          <div className="card metric-card">
            <strong>{topIntervention ? topIntervention.peak_reduction_c.toFixed(1) : "--"}</strong>
            <span>top peak reduction C</span>
          </div>
          <div className="card metric-card">
            <strong>{transient?.pass ? "pass" : "--"}</strong>
            <span>transient gate</span>
          </div>
        </div>
        {transient ? (
          <div className="rank-table" aria-label="Transient intervention ranking">
            {transient.ranked_interventions.map((item, index) => (
              <div className="rank-row" key={item.intervention}>
                <span>{index + 1}</span>
                <strong>{item.intervention.replaceAll("_", " ")}</strong>
                <em>{item.peak_reduction_c.toFixed(1)} C peak</em>
                <em>{item.thermal_dose_reduction_c_s.toFixed(1)} C-s dose</em>
              </div>
            ))}
          </div>
        ) : null}
      </section>

      <section className="section value-loop" id="power-proxy">
        <div>
          <p className="eyebrow">Power Delivery Proxy</p>
          <h2>Add one adjacent hardware check</h2>
          <p>
            {power?.design_question ?? "Run `bash scripts/run_power_delivery_benchmark.sh` to generate the power-delivery proxy benchmark."}
          </p>
          <p>
            This proxy reuses the same floorplan and block-power map to compare
            idealized bump density and SRAM placement, then reports whether
            droop and thermal hotspots overlap in the simplified model.
          </p>
        </div>
        <div className="grid">
          <div className="card metric-card">
            <strong>{powerBaseline ? powerBaseline.worst_droop_mv.toFixed(1) : "--"}</strong>
            <span>nominal KV worst droop mV</span>
          </div>
          <div className="card metric-card">
            <strong>{powerDense ? powerDense.worst_droop_mv.toFixed(1) : "--"}</strong>
            <span>dense-bump worst droop mV</span>
          </div>
          <div className="card metric-card">
            <strong>{power ? power.comparisons.nominal_to_dense_bumps.droop_reduction_mv.toFixed(1) : "--"}</strong>
            <span>dense-bump reduction mV</span>
          </div>
          <div className="card metric-card">
            <strong>{powerSpread ? powerSpread.worst_droop_mv.toFixed(1) : "--"}</strong>
            <span>spread SRAM worst droop mV</span>
          </div>
          <div className="card metric-card">
            <strong>{powerBaseline ? powerBaseline.overlap_score.toFixed(2) : "--"}</strong>
            <span>thermal/droop overlap score</span>
          </div>
          <div className="card metric-card">
            <strong>{power?.pass ? "pass" : "--"}</strong>
            <span>power proxy gate</span>
          </div>
        </div>
        {power ? (
          <div className="rank-table" aria-label="Power delivery proxy cases">
            {["kv_clustered_sparse", "kv_clustered_nominal", "kv_clustered_dense", "kv_spread_nominal"].map((name, index) => {
              const item = power.cases[name];
              return (
                <div className="rank-row" key={name}>
                  <span>{index + 1}</span>
                  <strong>{name.replaceAll("_", " ")}</strong>
                  <em>{item.worst_droop_mv.toFixed(1)} mV worst</em>
                  <em>{item.bump_count} bumps</em>
                </div>
              );
            })}
          </div>
        ) : null}
      </section>

      <section className="section">
        <p className="eyebrow">GBrain / GStack</p>
        <h2>Inspectable Build System</h2>
        <div className="grid">
          <div className="card">
            <h3>GBrain KB</h3>
            <p>
              The app and site read generated KB JSON from markdown assumptions,
              references, demo explanations, and claim boundaries.
            </p>
            <p><Link href="/knowledge">Browse the knowledge base</Link></p>
          </div>
          <div className="card">
            <h3>GStack Artifacts</h3>
            <p>
              Scope lock, engineering review, design review, QA, ship checklist,
              and retro live in the repo so the build process is inspectable.
            </p>
          </div>
          <div className="card">
            <h3>Quiet Proof</h3>
            <p>
              Rust tests, value benchmarks, site build, and headless visual smoke
              checks are designed to prove the demo without relying on a manual
              recording as the only evidence.
            </p>
          </div>
        </div>
      </section>

      <section className="section">
        <h2>Submission Surfaces</h2>
        <div className="grid">
          <div className="card">
            <h3>Demo Video</h3>
            <p>Pending the final 90-second recording from the native app.</p>
          </div>
          <div className="card">
            <h3>App Download</h3>
            <p>
              Download the unsigned macOS preview archive from the{" "}
              <a href="https://github.com/qinjianxyz/chip-heat-lab/releases/tag/v0.1.0-hackathon-preview">GitHub prerelease</a>,
              with checksum and manifest included.
            </p>
          </div>
          <div className="card">
            <h3>GitHub / Submission</h3>
            <p>
              Source, docs, CI, replay snapshots, and the value benchmark live in
              the <a href="https://github.com/qinjianxyz/chip-heat-lab">public GitHub repo</a>.
            </p>
          </div>
        </div>
      </section>
    </>
  );
}
