import Link from "next/link";
import { Heatmap } from "../components/Heatmap";
import { loadSnapshots } from "../lib/snapshots";

export default function HomePage() {
  const snapshots = loadSnapshots();
  const heroSnapshot = snapshots[0]?.snapshot;

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
