import Link from "next/link";
import { Heatmap } from "../components/Heatmap";
import {
  formatMetric,
  formatViolation,
  getConstraintRows,
  getRecommendedCandidate,
  loadDesignReview,
} from "../lib/designReview";
import { loadPowerBenchmark } from "../lib/powerBenchmark";
import { loadSnapshots } from "../lib/snapshots";
import { loadTransientBenchmark } from "../lib/transientBenchmark";
import { loadValueBenchmark } from "../lib/valueBenchmark";

export default function HomePage() {
  const snapshots = loadSnapshots();
  const heroSnapshot = snapshots[0]?.snapshot;
  const designReview = loadDesignReview();
  const benchmark = loadValueBenchmark();
  const transient = loadTransientBenchmark();
  const power = loadPowerBenchmark();
  const baseline = designReview?.baseline;
  const recommended = designReview ? getRecommendedCandidate(designReview) : undefined;
  const reviewConstraints = designReview ? getConstraintRows(designReview) : [];
  const rankedCandidates = designReview?.ranked_candidates.slice(0, 4) ?? [];
  const passingCandidates = designReview?.ranked_candidates.filter((item) => item.pass).length;
  const kv = benchmark?.comparisons.kv_sram_floorplan_intervention;
  const cooling = benchmark?.comparisons.training_cooling_intervention;
  const transientBaseline = transient?.cases.baseline_clustered.metrics;
  const topIntervention = transient?.ranked_interventions[0];
  const powerBaseline = power?.cases.kv_clustered_nominal;
  const powerDense = power?.cases.kv_clustered_dense;
  const powerSpread = power?.cases.kv_spread_nominal;
  const metricValue = (value: number | undefined, digits = 1, suffix = "") =>
    typeof value === "number" ? `${value.toFixed(digits)}${suffix}` : "--";
  const reviewInputLayers = [
    {
      label: "Die floorplan",
      metric: "6 blocks",
      detail: recommended ? `recommended: ${recommended.label}` : "stylized AI accelerator blocks",
      variant: "floorplan",
    },
    {
      label: "PDN mesh + bumps",
      metric: powerBaseline ? `${powerBaseline.bump_count} bumps` : "export JSON",
      detail: baseline ? `${baseline.worst_droop_mv.toFixed(1)} mV baseline droop` : "power-delivery proxy input",
      variant: "pdn",
    },
    {
      label: "Steady thermal field",
      metric:
        baseline && recommended
          ? `${baseline.steady_peak_c.toFixed(1)} -> ${recommended.steady_peak_c.toFixed(1)} C`
          : "thermal solve",
      detail: "2D finite-difference heat equation",
      variant: "thermal",
    },
    {
      label: "Transient workload trace",
      metric: baseline ? `${baseline.thermal_dose_c_s.toFixed(1)} C-s` : "phase trace",
      detail: "prefill / KV-cache / IO phases",
      variant: "trace",
    },
    {
      label: "Proof + non-claims",
      metric: designReview ? `${designReview.ranked_candidates.length} candidates` : "GBrain / GStack",
      detail: "KB citations, QA, ship checklist",
      variant: "proof",
    },
  ];

  return (
    <>
      <section className="hero">
        <div className="hero-copy">
          <p className="eyebrow">Engineering simulation for chip design</p>
          <h1>Chip Heat Lab</h1>
          <p className="lead">
            A clean-room design-review cockpit for one stylized AI accelerator:
            Rust runs thermal, transient, and power-delivery checks, then ranks
            layout and delivery interventions against explicit demo constraints.
          </p>
          <div className="hero-status-strip" aria-label="Proof cues">
            <span>Rust solver JSON</span>
            <span>GBrain assumption KB</span>
            <span>GStack QA artifacts</span>
          </div>
          {designReview ? (
            <div className="decision-panel">
              <div>
                <span>Design review verdict</span>
                <strong>{designReview.recommended_label}</strong>
                <p>
                  Baseline clustered SRAM fails{" "}
                  {baseline?.constraint_violations.length ?? 0} demo constraints;
                  the selected intervention is the lowest-cost passing candidate
                  in the exported Rust benchmark.
                </p>
              </div>
              <div className="mini-metric-grid">
                <div>
                  <strong>{baseline ? baseline.steady_peak_c.toFixed(1) : "--"}</strong>
                  <span>baseline peak C</span>
                </div>
                <div>
                  <strong>{recommended ? recommended.steady_peak_c.toFixed(1) : "--"}</strong>
                  <span>recommended peak C</span>
                </div>
                <div>
                  <strong>{baseline ? baseline.worst_droop_mv.toFixed(1) : "--"}</strong>
                  <span>baseline droop mV</span>
                </div>
                <div>
                  <strong>{recommended ? recommended.worst_droop_mv.toFixed(1) : "--"}</strong>
                  <span>recommended droop mV</span>
                </div>
              </div>
              {recommended ? (
                <div className="physics-metric-grid">
                  <div>
                    <strong>{metricValue(recommended.max_gradient_c_per_cell)}</strong>
                    <span>max thermal gradient C/cell</span>
                  </div>
                  <div>
                    <strong>{metricValue(recommended.hotspot_path_distance_cells)}</strong>
                    <span>hotspot path cells</span>
                  </div>
                  <div>
                    <strong>{metricValue(recommended.thermal_pdn_distance_cells)}</strong>
                    <span>thermal-PDN distance cells</span>
                  </div>
                  <div>
                    <strong>{metricValue(recommended.risk_utilization?.worst_droop, 2, "x")}</strong>
                    <span>droop limit utilization</span>
                  </div>
                </div>
              ) : null}
            </div>
          ) : null}
          <div className="actions">
            <Link className="button primary" href="#design-review">Design Review</Link>
            <Link className="button" href="/replay">Open Replay</Link>
            <Link className="button" href="/knowledge">Knowledge Base</Link>
            <a className="button" href="https://github.com/qinjianxyz/chip-heat-lab">GitHub</a>
          </div>
        </div>
        <div className="cockpit">
          <div className="cockpit-head">
            <div>
              <strong>Design review cockpit</strong>
              <small>thermal + transient + power-delivery proxy</small>
            </div>
            <span>{designReview?.pass ? "constraint gate: pass" : "run benchmark"}</span>
          </div>
          <div className="cockpit-body">
            <div className="cockpit-visual-stack">
              <div className="demo-shell compact-heatmap">
                <div className="demo-head">
                  <span>Rust snapshot replay</span>
                  <span>{heroSnapshot ? `${heroSnapshot.peak_c.toFixed(1)} C peak` : "export snapshots"}</span>
                </div>
                {heroSnapshot ? <Heatmap snapshot={heroSnapshot} /> : <div className="section">Run `bash scripts/export_snapshots.sh`.</div>}
              </div>
              <div className="model-stack-panel" aria-label="Review input stack">
                <div className="model-stack-title">
                  <strong>Review input stack</strong>
                  <span>rendered from benchmark outputs, not browser simulation</span>
                </div>
                <div className="model-layer-grid">
                  {reviewInputLayers.map((layer) => (
                    <div className="model-layer" key={layer.label}>
                      <i className={`layer-visual ${layer.variant}`} aria-hidden="true" />
                      <span>{layer.label}</span>
                      <strong>{layer.metric}</strong>
                      <em>{layer.detail}</em>
                    </div>
                  ))}
                </div>
              </div>
            </div>
            {designReview ? (
              <div className="cockpit-review">
                <div className="review-card failed">
                  <span>Baseline risk</span>
                  <strong>
                    {baseline?.pass
                      ? "passes"
                      : `fails ${baseline?.constraint_violations.length ?? 0} checks`}
                  </strong>
                  <p>
                    {baseline?.constraint_violations.map(formatViolation).join(", ")}
                  </p>
                </div>
                <div className="constraint-ledger" aria-label="Design review constraints">
                  {reviewConstraints.map((row) => (
                    <div className="constraint-row" key={row.id}>
                      <span>{row.label}</span>
                      <strong>
                        {formatMetric(row.baseline, row.unit)}{" -> "}
                        {formatMetric(row.recommended, row.unit)}
                      </strong>
                      <em>limit {formatMetric(row.limit, row.unit)}</em>
                      <b className={row.recommendedPass ? "gate-pass" : "gate-fail"}>
                        {row.recommendedPass ? "pass" : "fail"}
                      </b>
                    </div>
                  ))}
                </div>
                <div className="rank-mini" aria-label="Ranked interventions">
                  {rankedCandidates.map((item, index) => (
                    <div className={item.pass ? "rank-mini-row pass-row" : "rank-mini-row fail-row"} key={item.intervention}>
                      <span>{index + 1}</span>
                      <strong>{item.label}</strong>
                      <em>{metricValue(item.risk_utilization?.worst_droop, 2, "x")} droop · cost {item.cost_score.toFixed(1)}</em>
                    </div>
                  ))}
                </div>
                <div className="proof-rail" aria-label="Knowledge and process proof">
                  <span>GBrain cites assumptions and non-claims</span>
                  <span>GStack scope / QA / ship docs committed</span>
                  <span>Browser renders benchmark JSON only</span>
                </div>
              </div>
            ) : null}
          </div>
        </div>
      </section>

      <section className="section value-loop" id="design-review">
        <div>
          <p className="eyebrow">Flagship Workflow</p>
          <h2>Run a design review, not just a heatmap</h2>
          <p>
            {designReview?.design_question ?? "Run `bash scripts/run_design_review_benchmark.sh` to generate the design review benchmark."}
          </p>
          <p>
            The result is exported from the Rust CLI as benchmark JSON. The
            browser renders the decision artifact; it does not run a second
            solver.
          </p>
        </div>
        <div className="grid">
          <div className="card metric-card">
            <strong>{baseline ? baseline.thermal_dose_c_s.toFixed(1) : "--"}</strong>
            <span>baseline thermal dose C-s</span>
          </div>
          <div className="card metric-card">
            <strong>{recommended ? recommended.thermal_dose_c_s.toFixed(1) : "--"}</strong>
            <span>recommended thermal dose C-s</span>
          </div>
          <div className="card metric-card">
            <strong>{passingCandidates ?? "--"}</strong>
            <span>passing interventions</span>
          </div>
        </div>
        {designReview ? (
          <div className="rank-table" aria-label="Design review intervention ranking">
            {designReview.ranked_candidates.map((item, index) => (
              <div className={item.pass ? "rank-row pass-row" : "rank-row fail-row"} key={item.intervention}>
                <span>{index + 1}</span>
                <strong>{item.label}</strong>
                <em>{item.steady_peak_c.toFixed(1)} C peak</em>
                <em>{item.worst_droop_mv.toFixed(1)} mV droop</em>
              </div>
            ))}
          </div>
        ) : null}
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
            <p>
              Review the narrated fallback video from the{" "}
              <a href="https://github.com/qinjianxyz/chip-heat-lab/releases/download/v0.1.0-hackathon-preview/chip-heat-lab-demo-narrated-fallback.mp4">GitHub prerelease</a>.
              Founder approval is still required before treating it as the
              submission video.
            </p>
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
