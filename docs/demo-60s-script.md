# 60-Second Demo Script

Use this when recording the final hackathon video. The goal is to sell one
end-to-end hardware workflow, not every control.

## 0-8s: Promise

Open <https://chip-heat-lab.vercel.app>.

Voice:
"Chip Heat Lab is a simplified early-design thermal intuition demo for one
stylized accelerator floorplan. It turns one floorplan question into a
design-review decision."

Show:
- Design review cockpit.
- Baseline risk: fails 3 checks.
- Recommended fix: Spread SRAM.

## 8-22s: Why It Is Useful

Voice:
"The question is practical: what failed, what intervention passed, and what did
it cost? Rust computes steady thermal peak, transient thermal dose, and a
bounded power-delivery droop proxy, then ranks candidate interventions."

Show:
- `71.1 -> 68.2 C`
- `13.5 -> 4.3 C-s`
- `67.5 -> 50.1 mV`
- Ranked intervention list.

## 22-38s: Native App

Open `dist/ChipHeatLab.app`.

Voice:
"The native macOS app runs the same Rust CLI through JSON. It opens on the
recommended KV-cache spread-SRAM case."

Click:
- Floorplan: switch to `Clustered SRAM`.
- Floorplan: switch back to `Spread SRAM`.
- Workload: briefly click `Training` or `IO Burst`, then return to `KV
  Inference`.

Say:
"This is the interactive demo path: a hardware engineer can see how workload
and placement move the field while the design-review panel keeps the ranked
decision visible."

## 38-50s: Proof System

Return to the website.

Click:
- `Replay`
- `Knowledge`

Voice:
"The browser replays exported Rust artifacts; it does not run a second solver.
The knowledge base is GBrain-ready, so assumptions, citations, and non-claims
are inspectable."

## 50-60s: GStack + Future

Show README or docs/gstack.

Voice:
"GStack kept the project narrow: scope lock, engineering review, QA, ship, and
retro are committed. Anvil Sim is the flagship; Chip Heat Lab is the new public
clean-room electronics slice: benchmarks, explicit limits, and a roadmap to
deeper solvers."

Close:
"One design, three checks, ranked interventions, native demo, web replay, and
explicit assumptions."
