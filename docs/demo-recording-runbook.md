# Demo Recording Runbook

This is the human-recorded final demo script. Use it instead of the automated
fallback video when recording the hackathon submission.

## Recording Setup

Run:

```bash
cd /Users/qinjianxyz/chip-heat-lab-public-stage
bash scripts/prepare_recording_session.sh
```

This opens:

- Web cockpit: <https://chip-heat-lab.vercel.app/>
- Web replay: <https://chip-heat-lab.vercel.app/replay?snapshot=inference_spread>
- Knowledge page: <https://chip-heat-lab.vercel.app/knowledge>
- Native app: `dist/ChipHeatLab.app`

For a local web recording instead of the deployed site, run:

```bash
bash scripts/prepare_recording_session.sh local
```

After recording:

```bash
bash scripts/stop_recording_session.sh
```

## Recommended Take: Web First, Native Second

Use this if you want the pitch to be legible in one minute. The website explains
the decision; the macOS app proves the interactive native demo.

### 0-7s: What We Built

Show: web homepage, top design-review cockpit.

Voice:

> Chip Heat Lab is a simplified early-design thermal intuition demo for one
> stylized accelerator floorplan. We built one end-to-end design-review workflow
> around that floorplan.

Point at:

- `constraint gate: pass`
- `Baseline risk fails 3 checks`
- `Spread SRAM`

### 7-20s: Why It Is Useful

Show: left verdict and right constraint cards.

Voice:

> Hardware teams do not just need a pretty heatmap. They need to know what
> failed, which intervention passed, what it cost, and which assumptions bound
> the result. Here the clustered SRAM baseline fails simplified steady thermal,
> transient dose, and power-delivery droop checks.

Point at:

- `71.1 -> 68.2 C`
- `13.5 -> 4.3 C-s`
- `67.5 -> 50.1 mV`
- Ranked interventions.

### 20-34s: How It Works

Show: web heatmap and review inputs.

Voice:

> Rust owns the computation. It maps block power onto a 96 by 96 grid, solves a
> simplified thermal model, runs a transient workload trace, evaluates a bounded
> power-delivery proxy, and exports benchmark JSON. The browser only replays
> those Rust artifacts.

Do not say:

- production approval
- manufacturing-approved result
- airflow/package analysis
- production chip-design tool

### 34-48s: Native App Demo

Switch to: native macOS app.

Voice:

> The flagship app is native SwiftUI, but the simulation boundary is still Rust
> through JSON. I can switch floorplan or workload and the field and review
> metrics update from the backend.

Click path:

1. Click `Clustered SRAM`.
2. Click `Spread SRAM`.
3. Click `Training`.
4. Click `KV Inference`.

Say while clicking:

> The useful moment is that floorplan and workload move the hotspot, but the
> review panel keeps the decision framed as an engineering tradeoff.

### 48-56s: GBrain

Switch to: Knowledge page.

Voice:

> GBrain is not just a logo here. The repo has an importable markdown knowledge
> base for assumptions, references, explanations, and non-claims. The app and
> site consume the generated KB index so the explanation is inspectable.

Point at:

- `Design Review Workflow`
- `Power Delivery Proxy`
- non-claims / assumptions.

### 56-60s: GStack + Close

Show: README or `docs/gstack/`.

Voice:

> GStack kept the build narrow and shippable: scope lock, engineering review,
> design review, QA, ship checklist, and retro are committed. Anvil Sim is the
> flagship; Chip Heat Lab is the new public clean-room electronics slice we
> built for this hackathon.

Close:

> One design, three checks, ranked interventions, native demo, web replay, and
> explicit assumptions.

## Alternative Take: Native First

Use this if you want the video to feel more like a product demo before proving
the repo and process.

### 0-8s

Show: native app.

Voice:

> This is Chip Heat Lab: a native macOS design-review cockpit for one stylized
> accelerator thermal question and one bounded power-delivery proxy, backed by a
> Rust simulation CLI.

### 8-28s

Click:

1. `Clustered SRAM`
2. `Spread SRAM`
3. `Training`
4. `KV Inference`

Voice:

> We are asking a realistic early-design question: before spending cooling or
> package budget, can a floorplan intervention reduce a KV-cache hotspot and
> keep the simplified power-delivery proxy inside bounds?

### 28-45s

Switch to: website cockpit.

Voice:

> The web page summarizes the result as a design review. The clustered baseline
> fails three simplified checks. Rust ranks candidate interventions and chooses
> spread SRAM as the lowest-cost passing fix in this model.

### 45-60s

Switch to: Replay, Knowledge, README or `docs/gstack/`.

Voice:

> The replay is exported Rust JSON, the knowledge base is GBrain-ready, and the
> GStack artifacts show the scope, review, QA, ship, and retro discipline. We
> are not claiming production validation. We are showing a useful, honest,
> inspectable workflow for early chip-design simulation.

## 30-Second Cutdown

Use this if the submission form has a very short video limit.

Voice:

> Chip Heat Lab is a simplified early-design thermal intuition demo for one
> stylized accelerator floorplan. Rust evaluates that floorplan with steady
> thermal, transient dose, and a bounded power-delivery proxy. The baseline clustered
> SRAM design fails three simplified checks; the ranked review recommends
> spread SRAM as the lowest-cost passing intervention. The macOS app is the
> interactive demo, the website replays exported Rust JSON, GBrain makes
> assumptions and non-claims inspectable, and GStack documents the scope,
> engineering review, QA, and ship process. It is not production validation; it
> is one honest, end-to-end early-design workflow.

## Shot Checklist

- Homepage first viewport shows the design-review cockpit.
- The viewer sees the three failed baseline checks.
- The viewer sees the recommended intervention: `Spread SRAM`.
- The viewer sees at least one native app toggle.
- The viewer sees Replay or Knowledge so the Rust/GBrain story is concrete.
- The viewer sees GStack artifacts or hears that they are committed.
- The voiceover says "simplified" and avoids production-approval claims.

## Best One-Minute Voiceover

> Chip Heat Lab is a simplified early-design thermal intuition demo for one
> stylized accelerator floorplan. We built one end-to-end design-review workflow
> around that floorplan.
>
> The value is not just drawing a heatmap. A hardware team wants to know what
> failed, which intervention passed, what it cost, and which assumptions bound
> the result. Here the clustered SRAM baseline fails simplified steady thermal,
> transient dose, and power-delivery droop checks.
>
> Rust owns the computation: a 96 by 96 thermal grid, a transient workload
> trace, a bounded power-delivery proxy, and a ranked intervention benchmark.
> The website replays exported Rust JSON, and the native macOS app runs the
> same backend through JSON.
>
> GBrain is the assumption system: markdown knowledge pages for model
> assumptions, citations, explanations, and non-claims. GStack is the build
> discipline: scope lock, engineering review, design review, QA, ship checklist,
> and retro are committed.
>
> This is not production validation. It is the smallest honest wedge: one
> design, three checks, ranked interventions, native demo, web replay, and
> explicit assumptions. Anvil Sim is the flagship; Chip Heat Lab is the new
> public clean-room electronics slice: benchmarks, explicit limits, and a
> roadmap to richer geometry, more solvers, validation ladders, evidence packs,
> and real hardware-flow integrations.
