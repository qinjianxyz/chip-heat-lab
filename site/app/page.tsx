import Link from "next/link";
import { Heatmap } from "../components/Heatmap";
import { loadSnapshots } from "../lib/snapshots";

export default function HomePage() {
  const snapshots = loadSnapshots();
  const heroSnapshot = snapshots[0]?.snapshot;
  const byName = new Map(snapshots.map((item) => [item.name, item.snapshot]));
  const clustered = byName.get("inference_clustered");
  const spread = byName.get("inference_spread");
  const layoutDrop =
    clustered && spread ? clustered.peak_c - spread.peak_c : undefined;

  return (
    <>
      <section className="hero">
        <div>
          <p className="eyebrow">Engineering simulation for chip design</p>
          <h1>Chip Heat Lab</h1>
          <p className="lead">
            A clean-room OSS hackathon demo where a Rust CLI solves one
            simplified early-design thermal intuition model for a stylized AI
            accelerator floorplan.
          </p>
          <div className="actions">
            <Link className="button primary" href="/replay">Open Replay</Link>
            <Link className="button" href="/model">Read Model</Link>
            <Link className="button" href="/non-claims">Claim Boundaries</Link>
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

      <section className="section value-loop">
        <div>
          <p className="eyebrow">End-to-end value proof</p>
          <h2>Answer one design question</h2>
          <p>
            For a KV-cache-heavy workload, does spreading SRAM reduce the
            hotspot before changing the cooling budget? The demo computes both
            floorplans with the same Rust model and reports the peak-temperature
            delta.
          </p>
        </div>
        <div className="grid">
          <div className="card metric-card">
            <strong>{clustered ? clustered.peak_c.toFixed(1) : "--"}</strong>
            <span>clustered SRAM peak C</span>
          </div>
          <div className="card metric-card">
            <strong>{spread ? spread.peak_c.toFixed(1) : "--"}</strong>
            <span>spread SRAM peak C</span>
          </div>
          <div className="card metric-card">
            <strong>{layoutDrop !== undefined ? layoutDrop.toFixed(1) : "--"}</strong>
            <span>delta C in this simplified model</span>
          </div>
        </div>
      </section>

      <section className="section">
        <h2>Hackathon Placeholders</h2>
        <div className="grid">
          <div className="card">
            <h3>Demo Video</h3>
            <p>Placeholder: add the 90-second recording after app packaging.</p>
          </div>
          <div className="card">
            <h3>App Download</h3>
            <p>Placeholder: add the signed macOS app archive after Xcode export.</p>
          </div>
          <div className="card">
            <h3>GitHub / Submission</h3>
            <p>Submit this repo as the source package and link the replay page for judges.</p>
          </div>
        </div>
      </section>
    </>
  );
}
